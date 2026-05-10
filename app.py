import streamlit as st
import pandas as pd
import datetime
import random
import sqlite3
import requests
import os

# ==============================================================================
# 1. CONFIGURAÇÃO DE SEGURANÇA (API KEYS)
# ==============================================================================

def get_api_key():
    """Busca a chave no Streamlit Secrets ou no ambiente local."""
    if "TAVILY_API_KEY" in st.secrets:
        return st.secrets["TAVILY_API_KEY"]
    return os.getenv("TAVILY_API_KEY", "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")

TAVILY_API_KEY = get_api_key()

# ==============================================================================
# 2. MOTOR DE DADOS (DATABASE & ENGINE)
# ==============================================================================

class LogiflowEngine:
    def __init__(self, db_name="logiflow_final.db"):
        self.db_name = db_name
        self._setup_db()
        self.proposals = []

    def _get_conn(self):
        return sqlite3.connect(self.db_name)

    def _setup_db(self):
        conn = self._get_conn()
        cursor = conn.cursor()
        cursor.execute("CREATE TABLE IF NOT EXISTS products")
        cursor.execute("CREATE TABLE IF NOT EXISTS inventory")
        
        cursor.execute('''CREATE TABLE products (
                            product_id INTEGER PRIMARY KEY,
                            name TEXT,
                            is_perishable BOOLEAN,
                            is_producer BOOLEAN)''')

        cursor.execute('''CREATE TABLE inventory (
                            item_id INTEGER PRIMARY KEY,
                            product_id INTEGER,
                            quantity INTEGER,
                            location TEXT,
                            expiry_date DATE,
                            price REAL,
                            last_updated TIMESTAMP,
                            discount_pct REAL,
                            address TEXT,
                            FOREIGN KEY(product_id) REFERENCES products(product_id))''')

        products = [
            (1, "Organic Milk", 1, 0),
            (2, "Fresh Avocado", 1, 1),
            (3, "Greek Yogurt", 1, 0),
            (4, "Sourdough Bread", 1, 1),
            (5, "Canned Beans", 0, 0)
        ]
        cursor.executemany("INSERT INTO products VALUES (?,?,?,?)", products)
        conn.commit()
        conn.close()
        self.seed_initial_inventory()

    def seed_initial_inventory(self):
        conn = self._get_conn()
        cursor = conn.cursor()
        today = datetime.date.today()
        inventory = [
            (1, 1, 20, "Main St Shop", (today + datetime.timedelta(days=10)).isoformat(), 4.50, today.isoformat(), 0.0, "123 Market Ave"),
            (2, 2, 15, "Green Corner", (today + datetime.timedelta(days=1)).isoformat(), 2.0, today.isoformat(), 0.0, "45 Farm Road")
        ]
        cursor.executemany("INSERT INTO inventory VALUES (?,?,?,?,?,?,?,?,?)", inventory)
        conn.commit()
        conn.close()

    def search_hybrid(self, query):
        """Busca Local + Busca na Web (Agente Pesquisador)."""
        # 1. Busca Local
        conn = self._get_conn()
        sql = "SELECT i.item_id, p.name, i.quantity, i.location, i.expiry_date, i.price, i.discount_pct, p.is_producer, i.address FROM inventory i JOIN products p ON i.product_id = p.product_id WHERE p.name LIKE ?"
        local_df = pd.read_sql_query(sql, conn, params=(f"%{query}%",))
        conn.close()

        # 2. Busca Web (Tavily API)
        web_results = []
        if TAVILY_API_KEY != "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":
            try:
                url = "https://api.tavily.com/search"
                payload = {"api_key": TAVILY_API_KEY, "query": f"availability and price of {query}", "search_depth": "smart", "max_results": 3}
                response = requests.post(url, json=payload)
                for res in response.json().get('results', []):
                    web_results.append({
                        "name": query, "price": 0.0, "source": res.get('title', 'Web'),
                        "location": "Global Web", "is_producer": False, "address": res.get('url', '#')
                    })
            except:
                pass 
        
        return local_df, web_results

    def run_ai_analysis(self):
        conn = self._get_conn()
        df = pd.read_sql_query("SELECT i.item_id, p.product, i.expiry_date, i.quantity, i.price FROM inventory i JOIN products p ON i.product_id = p.product_id", conn)
        conn.close()
        self.proposals = []
        today = datetime.date.today()
        for _, row in df.iterrows():
            expiry = pd.to_datetime(row['expiry_date']).date()
            days_to_exp = (expiry - today).days
            if 0 <= days_to_exp < 3 and row['price'] > 0:
                self.proposals.append({'type': 'DISCOUNT', 'item_id': row['item_id'], 'product': row['product'], 'reason': f"Expiring in {days_to_exp} days", 'action_val': 0.50})
            elif row['quantity'] < 10:
                self.proposals.append({'type': 'RESTOCK', 'item_id': row['item_id'], 'product': row['product'], 'reason': "Stock critically low", 'action_val': None})
        return self.proposals

    def authorize_action(self, idx):
        prop = self.proposals.pop(idx)
        conn = self._get_conn()
        cursor = conn.cursor()
        if prop['type'] == 'DISCOUNT':
            cursor.execute("UPDATE inventory SET discount_pct = ? WHERE item_id = ?", (prop['action_val'], prop['item_id']))
        elif prop['type'] == 'RESTOCK':
            cursor.execute("UPDATE inventory SET quantity = quantity + 50 WHERE item_id = ?", (prop['item_id'],))
        conn.commit()
        conn.close()
        return True

    def register_item(self, data):
        conn = self._get_conn()
        cursor = conn.cursor()
        cursor.execute("SELECT product_id FROM products WHERE name = ?", (data['name'],))
        res = cursor.fetchone()
        if not res: return False, "Product not in registry."
        pid = res[0]
        cursor.execute("INSERT INTO inventory (product_id, quantity, location, expiry_date, price, last_updated, discount_pct, address) VALUES (?,?,?,?,?,?,?,?)",
                       (pid, data['qty'], data['loc'], data['exp'], data['price'], data['last_upd'], 0.0, data['addr']))
        conn.commit()
        conn.close()
        return True, "Success!"

# ==============================================================================
# 3. INTERFACE (UI)
# ==============================================================================

class LogiflowUI:
    def __init__(self, engine):
        self.engine = engine
        self.setup_widgets()

    def setup_widgets(self):
        # User
        self.user_input = st.text_input("🔍 Search Products", placeholder="e.g. Milk")
        self.user_output = st.container()

        # Seller
        st.sidebar.header("🏪 Seller Dashboard")
        self.s_prod = st.sidebar.text_input("Product Name")
        self.s_qty = st.sidebar.number_input("Quantity", min_value=1)
        self.s_price = st.sidebar.number_input("Price ($)", min_value=0.0)
        self.s_exp = st.sidebar.date_input("Expiry Date")
        self.s_loc = st.sidebar.text_input("Store Name")
        self.s_addr = st.sidebar.text_input("Address")
        self.s_is_prod = st.sidebar.checkbox("Local Producer?")
        self.s_submit = st.sidebar.button("🚀 Register Item")
        
        self.decision_output = st.sidebar.container()
        self.impact_output = st.sidebar.container()

    def render_user_view(self, query):
        if query:
            local_df, web_list = self.engine.search_hybrid(query)
            
            if not local_df.empty:
                st.subheader("📍 Available Locally")
                for _, row in local_df.iterrows():
                    is_zero_waste = row['discount_pct'] > 0 or (pd.to_datetime(row['expiry_date']).date() - datetime.date.today()).days < 3
                    badge = "🌿 LOCAL" if row['is_producer'] else "🏪 STORE"
                    st.markdown(f"""
                    <div style="border:1px solid #ddd; padding:10px; border-radius:10px; margin-bottom:10px;">
                        <b>{row['name']}</b> ({badge})<br>
                        Price: {'FREE' if is_zero_waste else f'${row['price']:.2f}'}<br>
                        <small>{row['location']} | {row['address']}</small>
                    </div>
                    """, unsafe_allow_html=True)

            if web_list:
                st.subheader("🌐 Found Online (Global)")
                for item in web_list:
                    st.info(f"**{item['product']}** - {item['source']} ({item['location']})")

    def render_seller_view(self):
        st.subheader("📦 Inventory Management")
        # Mostrar estoque atual
        conn = self.engine._get_conn()
        df = pd.read_sql_query("SELECT p.name, i.quantity, i.price, i.expiry_date FROM inventory i JOIN products p ON i.product_id = p.product_id", conn)
        conn.close()
        st.dataframe(df, use_container_width=True)

        st.write("---")
        st.subheader("🤖 AI Co-Pilot Suggestions")
        proposals = self.engine.run_ai_analysis()
        if not proposals:
            st.write("No urgent actions needed.")
        else:
            for i, p in enumerate(proposals):
                col1, col2 = st.columns([3, 1])
                col1.warning(f"{p['name']}: {p['reason']}")
                if col2.button("Approve", key=f"app_{i}"):
                    self.engine.authorize_action(i)
                    st.rerun()

        # Registro de novo item
        st.write("---")
        st.subheader("➕ New Entry")
        if st.button("Register New Item (Use Sidebar Form)"):
            pass # O formulário já está na sidebar

# ==============================================================================
# 4. MAIN APP
# ==============================================================================

def main():
    st.set_page_config(page_title="Logiflow Bridge", layout="wide")
    engine = LogiflowEngine()

    st.sidebar.title("🌿 Logiflow")
    mode = st.sidebar.radio("Mode:", ["🛒 Consumer", "🏪 Seller"])

    if mode == "🛒 Consumer":
        st.title("Consumer Search Portal")
        query = st.text_input("What are you looking for?")
        if query:
            engine.search_hybrid(query) # Chamada interna para o render
            # Para simplificar o fluxo no Stream_app, vamos usar o engine diretamente no render
            local_df, web_list = engine.search_hybrid(query)
            
            if not local_df.empty:
                st.subheader("📍 Local Results")
                for _, row in local_df.iterrows():
                    is_zw = row['discount_pct'] > 0 or (pd.to_datetime(row['expiry_date']).date() - datetime.date.today()).days < 3
                    st.write(f"✅ **{row['name']}** - ${row['price']:.2f} ({row['location']}) {'🔥 ZERO WASTE' if is_zw else ''}")
            
            if web_list:
                st.subheader("🌐 Global Results")
                for item in web_list:
                    st.write(f"🌐 {item['product']} via {item['source']}")

    else:
        # Modo Vendedor
        st.title("Seller Dashboard")
        
        # Sidebar Registration
        if st.sidebar.button("🚀 Submit New Item"):
            # Pegando dados dos widgets da sidebar
            data = {
                "name": st.session_state.get('s_prod_val', "Milk"), # Exemplo simplificado
                "qty": 10, "price": 5.0, "loc": "Store A", "addr": "Street 1", "is_prod": True, "exp": "2025-01-01"
            }
            # Para o protótipo, vamos usar os valores reais dos widgets:
            # (Nota: Em um app real, usaríamos o form do streamlit)
            pass 
            st.sidebar.text_input()

        # Mostrar Sugestões da IA
        st.subheader("🤖 AI Co-Pilot Suggestions")
        proposals = engine.run_ai_analysis()
        if not proposals:
            st.success("All stock is healthy!")
        else:
            for i, p in enumerate(proposals):
                col1, col2 = st.columns([3, 1])
                col1.warning(f"{p['name']}: {p['reason']}")
                if col2.button("Approve", key=f"btn_{i}"):
                    engine.authorize_action(i)
                    st.rerun()

        st.write("---")
        st.subheader("📦 Current Inventory")
        conn = engine._get_conn()
        df = pd.read_sql_query("SELECT p.name, i.quantity, i.price, i.expiry_date FROM inventory i JOIN products p ON i.product_id = p.product_id", conn)
        conn.close()
        st.dataframe(df, use_container_width=True)

if __name__ == "__main__":
    main()
