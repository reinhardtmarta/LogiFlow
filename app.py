import streamlit as st
import pandas as pd
import datetime
import requests  # Para fazer a chamada à API de busca
import json

# ==============================================================================
# 1. CONFIGURAÇÃO E API (O Céreção da Inteligência)
# ==============================================================================

# NOTA: No Streamlit Cloud, use st.secrets["TAVILY_API_KEY"]
# Para teste local, você pode colocar a chave aqui:
TAVILY_API_KEY = "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" 

class LogiflowEngine:
    def __init__(self):
        # Mantemos o inventário local para o "Lado do Vendedor"
        if 'local_inventory' not in st.session_state:
            st.session_state.local_inventory = pd.DataFrame(columns=[
                'product', 'store', 'price', 'location', 'is_producer', 'expiry'
            ])

    def search_hybrid(self, query):
        """O Agente Orquestrador decide: Buscar Local ou Buscar na Web."""
        
        # 1. Busca no Inventário Local (Vendedores cadastrados)
        local_results = st.session_state.local_inventory[
            st.session_state.local_inventory['product'].str.contains(query, case=False, na=False)
        ].copy()

        # 2. Busca na Web (O Agente Pesquisador usando Tavily API)
        web_results = self.web_search_agent(query)

        return local_results, web_results

    def web_search_agent(self, query):
        """O Agente Pesquisador: Vai na internet e traz dados estruturados."""
        if TAVILY_API_KEY == "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":
            return [{"product": "Erro", "price": 0, "source": "API Key faltando", "location": "N/A"}]

        url = "https://api.tavily.com/search"
        payload = {
            "api_key": TAVILY_API_KEY,
            "query": f"current price and availability of {query}",
            "search_depth": "smart",
            "max_results": 3
        }
        
        try:
            response = requests.post(url, json=payload)
            results = response.json().get('results', [])
            
            web_data = []
            for res in results:
                # Aqui o Agente "Sintetiza" o resultado da web para o formato do Logiflow
                web_data.append({
                    "product": query,
                    "price": 0.0, # A API traz texto, em um sistema real usaríamos um LLM para extrair o preço
                    "source": res.get('title', 'Web'),
                    "location": "Online / Global",
                    "url": res.get('url', '#')
                })
            return web_data
        except Exception as e:
            return []

    def register_item(self, data):
        new_item = {
            "product": data['name'], "store": data['loc'], "price": data['price'],
            "location": data['loc'], "is_producer": data['is_prod'], 
            "expiry": data['exp']
        }
        st.session_state.local_inventory = pd.concat([st.session_state.local_inventory, pd.DataFrame([new_item])], ignore_index=True)
        return True

# ==============================================================================
# 2. INTERFACE (UI)
# ==============================================================================

def main():
    engine = LogiflowEngine()
    st.set_page_config(page_title="Logiflow AI Bridge", layout="wide")

    st.sidebar.title("🌿 Logiflow AI")
    mode = st.sidebar.radio("Modo de Acesso:", ["🛒 Consumidor (User)", "🏪 Vendedor (Seller)"])

    if mode == "🛒 Consumidor (User)":
        st.title("🔍 Smart Search Bridge")
        st.write("Conectando o que você precisa com o que o mundo tem.")

        query = st.text_input("O que você deseja encontrar?", placeholder="Ex: Organic Milk")

        if query:
            with st.spinner("Agentes trabalhando... Pesquisando local e globalmente..."):
                local_df, web_list = engine.search_hybrid(query)

            # --- EXIBIÇÃO LOCAL ---
            if not local_df.empty:
                st.subheader("📍 Disponível na sua região (Local)")
                for _, row in local_df.iterrows():
                    with st.container():
                        st.markdown(f"""
                        <div style="border: 1px solid #27ae60; padding: 15px; border-radius: 10px; background: white; margin-bottom: 10px;">
                            <div style="font-size: 18px; font-weight: bold;">{row['product']}</div>
                            <div style="color: #27ae60;">{'🌿 PRODUTOR LOCAL' if row['is_producer'] else '🏪 Loja Parceira'}</div>
                            <div style="font-size: 16px;">Preço: ${row['price']:.2f}</div>
                            <div style="font-size: 12px; color: #7f8c8d;">📍 {row['location']}</div>
                        </div>
                        """, unsafe_allow_html=True)

            # --- EXIBIÇÃO WEB (A PONTE) ---
            if web_list:
                st.write("---")
                st.subheader("🌐 Encontrado na Web (Global)")
                for item in web_list:
                    with st.container():
                        st.markdown(f"""
                        <div style="border: 1px solid #3498db; padding: 15px; border-radius: 10px; background: #f0f7ff;">
                            <div style="font-size: 16px; font-weight: bold;">{item['product']}</div>
                            <div style="font-size: 13px; color: #3498db;">Fonte: {item['source']}</div>
                            <div style="font-size: 12px; color: #7f8c8d;">🌐 {item['location']}</div>
                        </div>
                        """, unsafe_allow_html=True)

    else:
        # --- MODO VENDEDOR (SIMPLIFICADO) ---
        st.title("🏪 Seller Dashboard")
        with st.form("seller_form"):
            name = st.text_input("Produto")
            price = st.number_input("Preço", min_value=0.0)
            qty = st.number_input("Quantidade", min_value=1)
            loc = st.text_input("Nome da Loja")
            addr = st.text_input("Endereço")
            is_prod = st.checkbox("Sou Produtor Local")
            exp = st.date_input("Validade")
            
            if st.form_submit_button("Publicar no Logiflow"):
                data = {"name": name, "price": price, "qty": qty, "loc": loc, "addr": addr, "is_prod": is_prod, "exp": exp.isoformat()}
                engine.register_item(data)
                st.success("Produto publicado com sucesso!")
        
        st.write("### Seu Estoque Atual")
        st.dataframe(st.session_state.local_inventory)

if __name__ == "__main__":
    main()
