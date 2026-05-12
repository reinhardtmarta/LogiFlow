import streamlit as st
import pandas as pd
import datetime
import sqlite3

# ==============================================================================
# 1. DATABASE ENGINE (WITH AUTO-MIGRATION & PASSWORD SUPPORT)
# ==============================================================================

class LogiflowDB:
    def __init__(self, db_name="logiflow_hackathon.db"):
        self.db_name = db_name
        self._setup_db()

    def _get_conn(self):
        return sqlite3.connect(self.db_name, check_same_thread=False)

    def _setup_db(self):
        conn = self._get_conn()
        cursor = conn.cursor()
        
        # 1. Create Tables
        cursor.execute('''CREATE TABLE IF NOT EXISTS users (
                            user_id INTEGER PRIMARY KEY AUTOINCREMENT,
                            name TEXT, email TEXT UNIQUE, password TEXT, 
                            phone TEXT, address TEXT, is_seller BOOLEAN)''')
        
        cursor.execute('''CREATE TABLE IF NOT EXISTS products (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            user_id INTEGER, name TEXT, qty INTEGER, price REAL,
                            expiry_date DATE, condition TEXT, is_producer BOOLEAN, address TEXT,
                            waste_prevented_kg REAL DEFAULT 0.0,
                            FOREIGN KEY(user_id) REFERENCES users(user_id))''')
        
        cursor.execute('''CREATE TABLE IF NOT EXISTS messages (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            sender_id INTEGER, receiver_id INTEGER, message TEXT, timestamp TIMESTAMP)''')

        # 2. DATABASE MIGRATION (Fixes the "no such column: password" error)
        cursor.execute("PRAGMA table_info(users)")
        columns = [column[1] for column in cursor.fetchall()]
        if 'password' not in columns:
            cursor.execute("ALTER TABLE users ADD COLUMN password TEXT")

        # 3. Seed Data
        cursor.execute("SELECT COUNT(*) FROM users")
        if cursor.fetchone()[0] == 0:
            self._seed_data(cursor)

        conn.commit() 
        conn.close()

    def _seed_data(self, cursor):
        users = [
            ("Green Valley Farms", "farm@demo.com", "pass123", "555-0101", "123 Rural Road", 1),
            ("Urban Market", "market@demo.com", "pass123", "555-0202", "45 Main St", 1),
            ("Eco Consumer", "consumer@demo.com", "pass123", "555-9999", "789 Oak Ave", 0)
        ]
        cursor.executemany("INSERT INTO users (name, email, password, phone, address, is_seller) VALUES (?,?,?,?,?,?)", users)

        today = datetime.date.today()
        products = [
            (1, "Organic Milk", 50, 3.50, (today + datetime.timedelta(days=15)).isoformat(), "Fresh", 1, "Farm Gate", 0.0),
            (1, "Fresh Avocado", 5, 2.00, (today + datetime.timedelta(days=1)).isoformat(), "Ripe", 1, "Farm Gate", 1.2),
            (2, "Sourdough Bread", 12, 5.00, (today + datetime.timedelta(days=3)).isoformat(), "Bakery", 0, "City Center", 0.5)
        ]
        cursor.executemany("INSERT INTO products (user_id, name, qty, price, expiry_date, condition, is_producer, address, waste_prevented_kg) VALUES (?,?,?,?,?,?,?,?,?)", products)

    # --- AUTH ---
    def login_user(self, email, password):
        conn = self._get_conn()
        sql = "SELECT * FROM users WHERE email = ? AND password = ?"
        df = pd.read_sql_query(sql, conn, params=(email, password))
        conn.close()
        return df

    def register_user(self, name, email, password, phone, address, is_seller):
        conn = self._get_conn()
        cursor = conn.cursor()
        try:
            cursor.execute("INSERT INTO users (name, email, password, phone, address, is_seller) VALUES (?,?,?,?,?,?)",
                           (name, email, password, phone, address, is_seller))
            conn.commit()
            return True
        except sqlite3.IntegrityError:
            return False
        finally:
            conn.close()

    # --- PRODUCT & AI ---
    def search_products(self, query):
        conn = self._get_conn()
        sql = """SELECT p.*, u.name as seller_name, u.phone as seller_phone, u.user_id as seller_id
                 FROM products p JOIN users u ON p.user_id = u.user_id WHERE p.name LIKE ?"""
        df = pd.read_sql_query(sql, conn, params=(f"%{query}%",))
        conn.close()
        return df

    def get_user_products(self, user_id):
        conn = self._get_conn()
        df = pd.read_sql_query("SELECT name, qty, price, expiry_date, condition FROM products WHERE user_id = ?", conn, params=(user_id,))
        conn.close()
        return df

    def register_product(self, user_id, name, qty, price, expiry, condition, is_producer, address):
        conn = self._get_conn()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO products (user_id, name, qty, price, expiry_date, condition, is_producer, address) VALUES (?,?,?,?,?,?,?,?)",
                       (user_id, name, qty, price, expiry, condition, is_producer, address))
        conn.commit()
        conn.close()

    def get_impact_metrics(self, user_id):
        conn = self._get_conn()
        df = pd.read_sql_query("SELECT SUM(waste_prevented_kg) as total_kg FROM products WHERE user_id = ?", conn, params=(user_id,))
        conn.close()
        return df['total_kg'].iloc[0] if not df.empty and df['total_kg'].iloc[0] is not None else 0.0

    def get_gemma_insights(self, user_id):
        conn = self._get_conn()
        cursor = conn.cursor()
        cursor.execute("SELECT id, name, expiry_date, qty FROM products WHERE user_id = ?", (user_id,))
        rows = cursor.fetchall()
        conn.close()
        insights = []
        today = datetime.date.today()
        for r in rows:
            pid, name, expiry_str, qty = r[0], r[1], r[2], r[3]
            try:
                exp = datetime.datetime.strptime(expiry_str, '%Y-%m-%d').date()
                if (exp - today).days < 3:
                    insights.append({"id": pid, "name": name, "type": "DISCOUNT", "msg": "High waste risk! Suggest 40% discount."})
            except: pass
            if qty < 5:
                insights.append({"id": pid, "name": name, "type": "RESTOCK", "msg": "Low inventory detected. Reorder soon."})
        return insights

    def apply_discount(self, product_id):
        conn = self._get_conn()
        cursor = conn.cursor()
        cursor.execute("UPDATE products SET price = price * 0.6 WHERE id = ?", (product_id,))
        conn.commit()
        conn.close()

    # --- CHAT ---
    def send_message(self, sender_id, receiver_id, text):
        conn = self._get_conn()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO messages (sender_id, receiver_id, message, timestamp) VALUES (?,?,?,?)",
                       (sender_id, receiver_id, text, datetime.datetime.now()))
        conn.commit()
        conn.close()

    def get_messages(self, user_a, user_b):
        conn = self._get_conn()
        cursor = conn.cursor()
        cursor.execute("""SELECT sender_id, message, timestamp FROM messages
                          WHERE (sender_id = ? AND receiver_id = ?)
                          OR (sender_id = ? AND receiver_id = ?)
                          ORDER BY timestamp ASC""", (user_a, user_b, user_b, user_a))
        msgs = cursor.fetchall()
        conn.close()
        return msgs

# ==============================================================================
# 2. UI ENGINE
# ==============================================================================

class LogiflowUI:
    def __init__(self):  
        self.db = LogiflowDB()
        if 'user' not in st.session_state: st.session_state.user = None
        if 'chat_target' not in st.session_state: st.session_state.chat_target = None
        if 'chat_partner_name' not in st.session_state: st.session_state.chat_partner_name = None

    def run(self):
        st.set_page_config(page_title="Logiflow | AI Food Rescue", page_icon="🌿", layout="wide")
        
        if st.session_state.user:
            self.render_sidebar()
            if st.session_state.user['is_seller']:
                self.render_seller_dashboard()
            else:
                self.render_consumer_marketplace()
        else:
            self.render_auth()

    def render_sidebar(self):
        st.sidebar.title("🌿 Logiflow Bridge")
        st.sidebar.write(f"**User:** {st.session_state.user['name']}")
        st.sidebar.caption(f"Role: {'Seller' if st.session_state.user['is_seller'] else 'Consumer'}")
        if st.sidebar.button("Logout"):
            st.session_state.user = None
            st.session_state.chat_target = None
            st.rerun()

    def render_auth(self):
        st.title("🌿 Logiflow Bridge")
        st.subheader("AI-Driven Food Rescue Marketplace")
        
        tab1, tab2 = st.tabs(["🔑 Login", "📝 Register"])
        
        with tab1:
            email = st.text_input("Email Address", key="l_email")
            password = st.text_input("Password", type="password", key="l_pass")
            if st.button("Sign In"):
                user_df = self.db.login_user(email, password)
                if not user_df.empty:
                    st.session_state.user = user_df.iloc[0].to_dict()
                    st.success(f"Welcome back, {st.session_state.user['name']}!")
                    st.rerun()
                else:
                    st.error("Invalid email or password.")

        with tab2:
            with st.form("reg_form"):
                name = st.text_input("Full Name")
                email = st.text_input("Email")
                password = st.text_input("Create Password", type="password")
                phone = st.text_input("Phone Number")
                addr = st.text_input("Address")
                role = st.selectbox("I am a:", ["Consumer", "Seller/Producer"])
                if st.form_submit_button("Create Account"):
                    if name and email and password:
                        if self.db.register_user(name, email, password, phone, addr, role == "Seller/Producer"):
                            st.success("Account created! Please login.")
                        else:
                            st.error("Email already exists.")
                    else:
                        st.error("Please fill all fields.")

    def render_consumer_marketplace(self):
        st.title("🛒 Marketplace")
        st.info("Browse local products and rescue food before it goes to waste!")

        query = st.text_input("🔍 Search products...")
        results = self.db.search_products(query)

        if results.empty:
            st.info("No products found.")
        else:
            for _, row in results.iterrows():
                with st.container():
                    col1, col2 = st.columns([3, 1])
                    with col1:
                        try:
                            days_left = (pd.to_datetime(row['expiry_date']).date() - datetime.date.today()).days
                            is_rescue = days_left <= 2
                        except: is_rescue = False

                        if is_rescue:
                            st.error(f"🚨 RESCUE ITEM: {row['name']}")
                        else:
                            st.subheader(row['name'])
                        
                        st.write(f"📍 {row['address']} | 🏪 **{row['seller_name']}**")
                        st.write(f"**Price: ${row['price']:.2f}**")
                    
                    with col2:
                        if st.button("💬 Chat", key=f"chat_{row['id']}"):
                            st.session_state.chat_target = row['seller_id']
                            st.session_state.chat_partner_name = row['seller_name']
                            st.rerun()
                    st.divider()

        if st.session_state.chat_target:
            self.render_chat_window()

    def render_chat_window(self):
        st.write("---")
        st.subheader(f"💬 Chatting with {st.session_state.chat_partner_name}")
        container = st.container(height=300)
        with container:
            msgs = self.db.get_messages(st.session_state.user['user_id'], st.session_state.chat_target)
            for m in msgs:
                sender = "You" if m[0] == st.session_state.user['user_id'] else "Seller"
                st.write(f"**{sender}:** {m[1]}")
        
        with st.form("chat_form", clear_on_submit=True):
            msg_text = st.text_input("Message...")
            if st.form_submit_button("Send"):
                if msg_text:
                    self.db.send_message(st.session_state.user['user_id'], st.session_state.chat_target, msg_text)
                    st.rerun()
        if st.button("Close Chat"):
            st.session_state.chat_target = None
            st.rerun()

    def render_seller_dashboard(self):
        st.title("🏪 Seller Dashboard")
        user_id = st.session_state.user['user_id']

        m1, m2, m3 = st.columns(3)
        impact = self.db.get_impact_metrics(user_id)
        m1.metric("Active Products", len(self.db.get_user_products(user_id)))
        m2.metric("Waste Prevented", f"{impact} kg")
        m3.metric("AI Engine", "Gemma 4 Active")

        st.subheader("🤖 Gemma 4 Intelligence Insights")
        insights = self.db.get_gemma_insights(user_id)
        if not insights:
            st.success("Inventory is healthy.")
        else:
            for i, ins in enumerate(insights):
                col1, col2 = st.columns([4, 1])
                col1.warning(f"**{ins['name']}**: {ins['msg']}")
                if col2.button("Apply", key=f"ai_{i}"):
                    if ins['type'] == 'DISCOUNT':
                        self.db.apply_discount(ins['id'])
                        st.toast("Discount applied!")
                        st.rerun()

        tab1, tab2 = st.tabs(["📦 Inventory", "➕ Add Product"])
        with tab1:
            st.dataframe(self.db.get_user_products(user_id), use_container_width=True)
        with tab2:
            with st.form("new_prod"):
                name = st.text_input("Name")
                qty = st.number_input("Qty", min_value=1)
                price = st.number_input("Price", min_value=0.0)
                exp = st.date_input("Expiry")
                addr = st.text_input("Address")
                is_p = st.checkbox("Local Producer")
                if st.form_submit_button("Publish"):
                    self.db.register_product(user_id, name, qty, price, exp.isoformat(), "Fresh", is_p, addr)
                    st.success("Product live!")
                    st.rerun()

if __name__ == "__main__":
    app = LogiflowUI()
    app.run()
