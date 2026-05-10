import streamlit as st
import pandas as pd
import sqlite3
import datetime

# ==============================================================================
# 1. ENGINE DE DADOS (DATABASE & LOGIC)
# ==============================================================================

class LogiflowDB:
    def __init__(self):
        self.conn = sqlite3.connect("logiflow_final.db", check_same_thread=False)
        self._setup_tables()

    def _setup_tables(self):
        cursor = self.conn.cursor()
        # Tabela de Usuários (Vendedores e Clientes)
        cursor.execute('''CREATE TABLE IF NOT EXISTS users (
                            user_id INTEGER PRIMARY KEY AUTOINCREMENT,
                            name TEXT, email TEXT, phone TEXT, address TEXT, is_seller BOOLEAN)''')
        
        # Tabela de Produtos
        cursor.execute('''CREATE TABLE IF NOT EXISTS products (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            user_id INTEGER, name TEXT, qty INTEGER, price REAL, 
                            expiry DATE, condition TEXT, is_producer BOOLEAN, address TEXT,
                            FOREIGN KEY(user_id) REFERENCES users(user_id))''')

        # Tabela de Chat
        cursor.execute('''CREATE TABLE IF NOT EXISTS messages (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            sender_id INTEGER, receiver_id INTEGER, message TEXT, timestamp TIMESTAMP)''')

        # Tabela de Bloqueio
        cursor.execute('''CREATE TABLE IF NOT EXISTS blocks (
                            blocker_id INTEGER, blocked_id INTEGER,
                            PRIMARY KEY(blocker_id, blocked_id))''')
        self.conn.commit()

    def register_user(self, name, email, phone, address, is_seller):
        cursor = self.conn.cursor()
        cursor.execute("INSERT INTO users (name, email, phone, address, is_seller) VALUES (?,?,?,?,?)",
                       (name, email, phone, address, is_seller))
        self.conn.commit()
        return cursor.lastrowid

    def add_product(self, user_id, name, qty, price, expiry, condition, is_producer, address):
        cursor = self.conn.cursor()
        cursor.execute("""INSERT INTO products (user_id, name, qty, price, expiry_date, condition, is_producer, address) 
                          VALUES (?,?,?,?,?,?,?,?)""", (user_id, name, qty, price, expiry, condition, is_producer, address))
        self.conn.commit()

    def get_products(self, query=None):
        cursor = self.conn.cursor()
        if query:
            sql = """SELECT p.*, u.name as seller_name, u.phone as seller_phone, u.user_id as seller_id 
                     FROM products p JOIN users u ON p.user_id = u.user_id WHERE p.name LIKE ?"""
            return pd.read_sql_query(sql, self.conn, params=(f"%{query}%",))
        else:
            return pd.read_sql_query("SELECT p.*, u.name as seller_name, u.phone as seller_phone, u.user_id as seller_id FROM products p JOIN users u ON p.user_id = u.user_id", self.conn)

    def send_msg(self, sender_id, receiver_id, text):
        cursor = self.conn.cursor()
        cursor.execute("INSERT INTO messages (sender_id, receiver_id, message, timestamp) VALUES (?,?,?,?)",
                       (sender_id, receiver_id, text, datetime.datetime.now()))
        self.conn.commit()

    def get_chat(self, user_a, user_b):
        cursor = self.conn.cursor()
        cursor.execute("""SELECT sender_id, message, timestamp FROM messages 
                          WHERE (sender_id = ? AND receiver_id = ?) 
                          OR (sender_id = ? AND receiver_id = ?) 
                          ORDER BY timestamp ASC""", (user_a, user_b, user_b, user_a))
        return cursor.fetchall()

    def block_user(self, blocker_id, blocked_id):
        cursor = self.conn.cursor()
        cursor.execute("INSERT OR IGNORE INTO blocks (blocker_id, blocked_id) VALUES (?,?)", (blocker_id, blocked_id))
        self.conn.commit()

    def is_blocked(self, user_a, user_id_b):
        cursor = self.conn.cursor()
        cursor.execute("SELECT 1 FROM blocks WHERE blocker_id = ? AND blocked_id = ?", (user_a, user_id_b))
        return cursor.fetchone() is not None

db = LogiflowDB()

# ==============================================================================
# 3. INTERFACE (UI)
# ==============================================================================

def main():
    st.set_page_config(page_title="Logiflow Bridge", layout="wide")

    # Inicialização de Sessão
    if 'user_id' not in st.session_state: st.session_state.user_id = None
    if 'role' not be st.session_state.role = None
    if 'active_chat' not in st.session_state: st.session_state.active_chat = None

    # --- SIDEBAR: LOGIN & NAVEGAÇÃO ---
    st.sidebar.title("🌿 Logiflow")
    
    if st.session_state.user_id is None:
        st.sidebar.subheader("Login / Cadastro")
        mode = st.sidebar.radio("Entrar como:", ["Consumidor", "Vendedor"])
        
        with st.sidebar.form("auth_form"):
            name = st.text_input("Nome Completo")
            email = st.text_input("E-mail")
            phone = st.text_input("Telefone")
            addr = st.text_input("Endereço")
            submit = st.form_submit_button("Entrar no Sistema")
            
            if submit:
                if name and email and phone:
                    uid = db.register_user(name, email, phone, addr, mode == "Vendedor")
                    st.session_state.user_id = uid
                    st.session_state.role = "seller" if mode == "Vendedor" else "user"
                    st.rerun()
                else:
                    st.error("Preencha todos os campos.")
    else:
        st.sidebar.success(f"Logado como: {st.session_state.role.capitalize()}")
        if st.sidebar.button("Sair"):
            st.session_state.user_id = None
            st.rerun()

    # --- CONTEÚDO PRINCIPAL ---
    if st.session_state.user_id:
        if st.session_state.role == "user":
            render_consumer_view()
        else:
            render_seller_view()
    else:
        st.title("Bem-vindo ao Logiflow")
        st.info("Por favor, faça login na barra lateral para continuar.")

# --- TELAS ---

def render_consumer_view():
    st.title("🛒 Marketplace Solidário")
    query = st.text_input("O que você procura hoje?", placeholder="Ex: Milk, Avocado...")

    if query:
        results = db.get_products_by_query(query) # Implementar busca por nome
        # Para o exemplo, vamos usar a busca do engine
        results = db.get_products_by_query(query) 
        
        # (Simplificando para o exemplo funcionar imediatamente)
        results = db.get_products_by_query(query) 

        if results.empty:
            st.warning("Nenhum item encontrado localmente.")
        else:
            for _, row in results.iterrows():
                with st.container():
                    col1, col2 = st.columns([3, 1])
                    with col1:
                        badge = "🌿 PRODUTOR" if row['is_producer'] else "🏪 LOJA"
                        st.markdown(f"### {row['name']} ({badge})")
                        st.write(f"📍 {row['address']} | 📅 Validade: {row['expiry_date']}")
                        st.write(f"Estado: {row['condition']}")
                        
                        # Lógica de Doação
                        is_donation = row['price'] <= 0 or (pd.to_datetime(row['expiry_date']).date() - datetime.date.today()).days < 2
                        if is_donation:
                            st.error("🎁 STATUS: DISPONÍVEL PARA DOAÇÃO / FREE")
                        else:
                            st.write(f"**Preço: ${row['price']:.2f}**")
                    
                    with col2:
                        if st.button("💬 Chat", key=f"chat_{row['item_id']}"):
                            st.session_state.active_chat = row['user_id']
                            st.rerun()
                        
                        if st.button("🚫 Bloquear", key=f"block_{row['item_id']}"):
                            db.block_user(st.session_state.user_id, row['user_id'])
                            st.success("Usuído bloqueado.")
                    st.divider()

    # --- ÁREA DE CHAT (Aparece se um chat estiver ativo) ---
    if st.session_state.get('active_chat'):
        st.write("---")
        st.subheader("💬 Conversa Direta")
        target_id = st.session_state.active_chat
        
        # Verificar se foi bloqueado
        if db.is_blocked(st.session_state.user_id, target_id):
            st.error("Você bloqueou este usuário ou foi bloqueado por ele.")
        else:
            # Mostrar mensagens
            msgs = db.get_chat(st.session_state.user_id, target_id)
            for m in msgs:
                role = "Você" if m[0] == st.session_state.user_id else "Vendedor"
                st.write(f"**{role}:** {m[1]} ({m[2][:5]})")

            # Input de mensagem
            with st.form("chat_form", clear_on_submit=True):
                new_msg = st.text_input("Sua mensagem...")
                if st.form_submit_button("Enviar"):
                    if new_msg:
                        db.send_msg(st.session_state.user_id, target_id, new_msg)
                        st.rerun()
            
            if st.button("Fechar Chat"):
                st.session_state.active_chat = None
                st.rerun()

def render_seller_view():
    st.title("🏪 Painel do Vendedor")
    
    tab1, tab2 = st.tabs(["📦 Meu Estoque", "➕ Novo Cadastro"])

    with tab1:
        st.subheader("Meus Produtos")
        # Busca apenas produtos do usuário logado
        my_items = db.get_products_by_user(st.session_state.user_id)
        if my_items.empty:
            st.info("Você ainda não cadastrou produtos.")
        else:
            st.dataframe(my_items, use_container_width=True)

    with tab2:
        st.subheader("Cadastrar Item")
        with st.form("add_product_form"):
            name = st.text_input("Nome do Produto")
            qty = st.number_input("Quantidade", min_value=1)
            price = st.number_input("Preço ($)", min_value=0.0)
            exp = st.date_input("Data de Validade")
            cond = st.selectbox("Estado do Item", ["Novo", "Usado", "Aberto"])
            is_prod = st.checkbox("Sou Produtor Local")
            loc = st.text_input("Nome da Loja/Fazenda")
            addr = st.text_input("Endereço Completo")
            
            if st.form_submit_button("Publicar no Logiflow"):
                db.add_product(st.session_state.user_id, name, qty, price, exp.isoformat(), cond, is_prod, addr)
                st.success("Produto publicado com sucesso!")

# --- AJUSTE FINAL PARA O ENGINE (Para o código funcionar sem erros de coluna) ---
def get_products_by_user(self, user_id):
    conn = self._get_conn()
    sql = "SELECT p.name, p.is_perishable, i.quantity, i.price, i.expiry_date, i.condition, i.is_producer, i.address FROM inventory i JOIN products p ON i.product_id = p.product_id WHERE i.user_id = ?"
    df = pd.read_sql_query(sql, conn, params=(user_id,))
    conn.close()
    return df

LogiflowEngine.get_products_by_user = get_products_by_user

if __name__ == "__main__":
    main()
