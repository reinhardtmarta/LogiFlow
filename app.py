import streamlit as st
import pandas as pd
import datetime
import random
import requests
import json

# ==============================================================================
# 1. DATA ENGINE (Simulando o Mundo Real e o Banco Local)
# ==============================================================================

class LogiflowEngine:
    def __init__(self):
        # Simulando o Banco de Dados Local (Vendedores cadastrados)
        if 'local_inventory' not in st.session_state:
            st.session_state.local_inventory = pd.DataFrame(columns=[
                'product', 'store', 'price', 'location', 'is_producer', 'expiry'
            ])
        
        # Simulando o "Mundo Global" (Dados que o Agente busca na Web/Google)
        self.global_mock_data = [
            {"product": "Organic Milk", "price": 4.50, "source": "Amazon", "location": "Global Warehouse"},
            {"product": "Fresh Avocado", "price": 2.00, "source": "Walmart", "location": "Global Warehouse"},
            {"product": "Greek Yogurt", "price": 3.50, "source": "Target", "location": "Global Warehouse"},
            {"product": "Sourdough Bread", "price": 5.00, "source": "Local Bakery Online", "location": "Global Warehouse"},
            {"product": "Canned Beans", "price": 1.20, "source": "Amazon", "location": "Global Warehouse"}
        ]

    def search_hybrid(self, query):
        """O coração do projeto: A busca inteligente que une Local + Global."""
        query = query.lower()
        
        # 1. Busca no Inventário Local (Vendedores da plataforma)
        local_results = st.session_state.local_inventory[
            st.session_state.local_inventory['product'].str.lower().str.contains(query)
        ].copy()

        # 2. Busca no Mundo Global (Simulando o Agente pesquisando na Web)
        global_results = []
        for item in self.global_mock_data:
            if query in item['product'].lower():
                global_results.append(item)
        
        return local_results, global_results

    def register_seller_item(self, product, qty, price, loc, addr, is_prod):
        """Registra um item para que ele apareça na busca local."""
        new_item = {
            "product": product,
            "store": "Minha Loja Local", # Em um app real, viria do perfil do vendedor
            "price": price,
            "location": loc,
            "address": addr,
            "is_producer": is_prod,
            "expiry": (datetime.date.today() + datetime.timedelta(days=10)).isoformat()
        }
        st.session_state.local_inventory = pd.concat([st.session_state.local_inventory, pd.DataFrame([new_item])], ignore_index=True)
        return True

# ==============================================================================
# 2. INTERFACE (O Dashboard do Usuário e do Vendedor)
# ==============================================================================

def main():
    engine = LogiflowEngine()

    st.set_page_config(page_title="Logiflow Bridge", layout="wide")
    
    # Sidebar de Navegação
    st.sidebar.title("🌿 Logiflow")
    mode = st.sidebar.radio("Acesse como:", ["🛒 Consumidor (User)", "🏪 Vendedor (Seller)"])

    if mode == "🛒 Consumidor (User)":
        render_user_view(engine)
    else:
        render_seller_view(engine)

def render_user_view(engine):
    st.title("🔍 Logiflow Search Bridge")
    st.write("Encontre produtos locais ou explore opções globais.")

    query = st.text_input("O que você está procurando?", placeholder="Ex: Milk, Avocado...")

    if query:
        local_df, global_list = engine.search_hybrid(query)

        # --- SEÇÃO 1: RESULTADOS LOCAIS (Ouro do Projeto) ---
        if not local_df.empty:
            st.subheader("📍 Disponível na sua região (Local)")
            for _, row in local_df.iterrows():
                with st.container():
                    col1, col2 = st.columns([3, 1])
                    with col1:
                        badge = "🌿 PRODUTOR LOCAL" if row['is_producer'] else "🏪 Loja Parceira"
                        st.markdown(f"**{row['product']}** ({badge})")
                        st.caption(f"📍 {row['location']} | {row['address']}")
                    with col2:
                        st.write(f"**${row['price']:.2f}**")
                        if st.button("Ver Detalhes", key=f"btn_{row['product']}"):
                            st.info(f"Abrindo chat com {row['store']}...")
                    st.divider()

        # --- SEÇÃO 2: RESULTADOS GLOBAIS (A Ponte para o Mundo) ---
        if global_list:
            st.subheader("🌐 Encontrado na Web (Global)")
            st.caption("Não encontramos localmente, mas o Logiflow encontrou estas opções online:")
            for item in global_list:
                col1, col2 = st.columns([3, 1])
                with col1:
                    st.markdown(f"**{item['product']}**")
                    st.caption(f"Fonte: {item['source']} | {item['location']}")
                with col2:
                    st.write(f"${item['price']:.2f}")
                    st.link_button("Ver no Site", "https://www.google.com/shopping")
                st.divider()
        
        if local_df.empty and not global_list:
            st.error("Nenhum item encontrado localmente ou na web.")

def render_seller_view(engine):
    st.title("🏪 Seller Dashboard")
    st.write("Cadastre seus produtos para aparecer no mapa local.")

    with st.expander("➕ Cadastrar Novo Produto", expanded=True):
        with st.form("seller_form"):
            name = st.text_input("Nome do Produto")
            price = st.number_input("Preço ($)", min_value=0.0, step=0.5)
            qty = st.number_input("Quantidade", min_value=1)
            loc = st.text_input("Nome da Loja/Fazenda")
            addr = st.text_input("Endereço de Entrega")
            is_prod = st.checkbox("Sou um Produtor Local")
            
            submit = st.form_submit_button("Publicar no Logiflow")
            
            if submit:
                if name and loc:
                    engine.register_item_simplified(name, qty, price, loc, addr, is_prod)
                    st.success(f"✅ {name} agora está visível para os clientes!")
                else:
                    st.error("Preencha o nome e a localização.")

    # Adicionando uma função de ajuda para o register_item no engine
    # (Para evitar erro de chamada, vamos adicionar direto aqui no código de exemplo)

# --- Ajuste de correção para o método de registro ---
def register_item_helper(engine, name, qty, price, loc, addr, is_prod):
    # Esta função é uma versão simplificada para o protótipo
    new_item = {
        "product": name, "store": "Minha Loja", "price": price, 
        "quantity": qty, "location": loc, "address": addr, 
        "is_producer": is_prod, "expiry_date": (datetime.date.today() + datetime.timedelta(days=10)).isoformat()
    }
    st.session_state.local_inventory = pd.concat([st.session_state.local_inventory, pd.DataFrame([new_item])], ignore_index=True)
    return True

# Substituindo a chamada original para garantir que funcione
def register_item_simplified(engine, name, qty, price, loc, addr, is_prod):
    # Simulação de registro direto no dataframe da sessão
    new_item = {
        "product": name, "store": "Minha Loja", "price": price, 
        "quantity": qty, "location": loc, "address": addr, 
        "is_producer": is_prod, "expiry_date": (datetime.date.today() + datetime.timedelta(days=10)).isoformat()
    }
    st.session_state.local_inventory = pd.concat([st.session_state.local_inventory, pd.DataFrame([new_item])], ignore_index=True)
    return True, "Sucesso"

# Sobrescrevendo o método do engine para o protótipo
LogiflowEngine.register_item = lambda self, data: register_item_simplified(self, data['name'], data['qty'], data['price'], data['loc'], data['addr'], data['is_prod'])

if __name__ == "__main__":
    main()
