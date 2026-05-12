import streamlit as st
import pandas as pd
import datetime
import sqlite3
import random

# ==============================================================================
# 1. DATABASE ENGINE (The Source of Truth)
# ==============================================================================

class LogiflowDB:
    def __init__(self, db_name="logiflow_final.db"):
        self.db_name = db_name
        self._setup_db()

    def _get_conn(self):
        return sqlite3.connect(self.db_name)

    def _setup_db(self):
        conn = self._get_conn()
        cursor = conn.cursor()
        # Users Table
        cursor.execute('''CREATE TABLE IF NOT EXISTS users (
                            user_id INTEGER PRIMARY KEY AUTOINCREMENT,
                            name TEXT, email TEXT, phone TEXT, address TEXT, is_seller BOOLEAN)''')
        # Products Table
        cursor.execute('''CREATE TABLE IF NOT EXISTS products (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            user_id INTEGER, name TEXT, qty INTEGER, price REAL, 
                            expiry DATE, condition TEXT, is_producer BOOLEAN, address TEXT,
                            FOREIGN KEY(user_id) REFERENCES users(user_id))''')
        # Chat Table
        cursor.execute('''CREATE TABLE IF NOT EXISTS messages (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            sender_id INTEGER, receiver_id INTEGER, message TEXT, timestamp TIMESTAMP)''')
        # Block Table
        cursor.execute('''CREATE TABLE IF NOT EXISTS blocks (
                            blocker_id INTEGER, blocked_id INTEGER,
                            PRIMARY KEY(blocker_id, blocked_id))''')
        
        # SEED DATA: Only if table is empty
        cursor.execute("SELECT COUNT(*) FROM users")
        if cursor.fetchone()[0] == 0:
            self._seed_data(cursor)
        
        conn.commit()
        conn.close()

    def _seed_data(self, cursor):
        # Seed Users (Sellers and Consumers)
        users = [
            ("Green Valley Farm", "contact@greenvalley.com", "555-0101", "123 Rural Road", 1),
            ("City Corner Market", "info@citymarket.com", "555-0202", "45 Main St", 1),
            ("John Doe (Consumer)", "john@email.com", "555-9999", "789 Oak Ave", 0)
        ]
        cursor.executemany("INSERT INTO users (name, email, phone, address, is_seller) VALUES (?,?,?,?,?)", users)

        # Seed Products
        today = datetime.date.today()
        products = [
            # User 1 (Farmer)
            (1, "Organic Milk", 50, 3.50, (today + datetime.timedelta(days=15)).isoformat(), "Fresh", 1, "Farm Gate"),
            (1, "Fresh Avocado", 5, 2.00, (today + datetime.timedelta(days=1)).isoformat(), "Ripe", 1, "Farm Gate"), # Near expiry
            # User 2 (Market)
            (2, "Sourdough Bread", 12, 5.00, (today + datetime.timedelta(days=3)).isoformat(), "Bakery", 0, "City Center"),
            (2, "Canned Beans", 100, 1.20, (today + datetime.timedelta(days=365)).isoformat(), "Pantry", 0, "City Center")
        ]
        for p in products:
            cursor.execute("INSERT INTO products (user_id, name, qty, price, expiry_date, condition, is_producer, address) VALUES (?,?,?,?,?,?,?,?)", p)
        cursor.commit()

    def search_products(self, query):
        conn = self._get_conn()
        sql = """SELECT p.*, u.name as seller_name, u.phone as seller_phone, u.user_id as seller_id 
                 FROM products p JOIN users u ON p.user_id = u.user_id WHERE p.name LIKE ?"""
        df = pd.read_sql_query(sql, conn, params=(f"%{query}%",))
        conn.close()
        return df

    def get_user_products(self, user_id):
        conn = self._get_conn()
        df = pd.read_sql_query("SELECT * FROM products WHERE user_id = ?", conn, params=(user_id,))
        conn.close()
        return df

    def register_product(self, user_id, name, qty, price, expiry, condition, is_producer, address):
        conn = self._get_conn()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO products (user_id, name, qty, price, expiry_date, condition, is_producer, address) VALUES (?,?,?,?,?,?,?,?)",
                       (user_id, name, qty, price, expiry, condition, is_producer, address))
        conn.commit()
        conn.close()

    def get_ai_proposals(self, user_id):
        conn = self._get_conn()
        cursor = conn.cursor()
        cursor.execute("SELECT id, name, expiry_date, qty FROM products WHERE user_id = ?", (user_id,))
        rows = cursor.fetchall()
        conn.close()
        
        proposals = []
        today = datetime.date.today()
        for r in rows:
            exp = datetime.datetime.strptime(r[3], '%Y-%m-%d').date()
            if (exp - today).days < 3:
                proposals.append({"id": r[0], "name": r[1], "type": "DISCOUNT", "reason": "Expiring soon!"})
            if r[3] < 10:
                proposals.append({"id": r[0], "type": "RESTOCK", "name": r[1], "reason": "Low stock!"})
        return proposals

    def apply_discount(self, product_id):
        conn = self._get_conn()
        cursor = conn.cursor()
        cursor.execute("UPDATE products SET price = price * 0.5 WHERE id = ?", (product_id,))
        conn.commit()
        conn.close()

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
# 2. UI ENGINE (The Interface)
# ==============================================================================

class LogiflowUI:
    def __init__(self):
        self.db = LogiflowDB()
        # Mocking a logged-in user for the demo
        self.current_user_id = 1 
        self.current_role = "seller"

    def run(self):
        st.set_page_config(page_title="Logiflow Bridge", layout="wide")
        st.sidebar.title("🌿 Logiflow AI")
        
        mode = st.sidebar.radio("Switch View:", ["🛒 Consumer Mode", "🏪 Seller Dashboard"])

        if mode == "🛒 Consumer Mode":
            self.render_consumer()
        else:
            self.render_seller()

    def render_consumer(self):
        st.title("Consumer Marketplace")
        query = st.text_input("Search for products (e.g. Milk, Avocado)...")

        if query:
            results = self.db.search_products(query)
            if results.empty:
                st.warning("No local products found. Checking global web results...")
                st.info("🌐 [Simulated Web Result] Organic Milk - $12.00 (Amazon)")
            else:
                st.subheader("📍 Found Nearby")
                for _, row in results.iterrows():
                    with st.container():
                        is_donation = row['price'] <= 0 or (pd.to_datetime(row['expiry_date']).date() - datetime.date.today()).days < 2
                        
                        col1, col2 = st.columns([3, 1])
                        with col1:
                            st.markdown(f"### {row['name']}")
                            st.write(f"**{row['seller_name']}** | 📍 {row['address']}")
                            if is_donation:
                                st.error("🎁 STATUS: AVAILABLE FOR DONATION / FREE")
                            else:
                                st.write(f"Price: ${row['price']:.2f}")
                        
                        with col2:
                            if st.button("💬 Chat", key=f"chat_{row['id']}"):
                                st.session_state.chat_target = row['user_id']
                                st.session_state.chat_partner_name = row['seller_name']
                                st.rerun()
                        st.divider()

        # Chat Window
        if 'chat_target' in st.session_state:
            st.write("---")
            st.subheader(f"💬 Chat with {st.session_state.chat_partner_name}")
            
            chat_container = st.container(height=300)
            with chat_container:
                msgs = self.db.get_messages(self.current_user_id, st.session_state.chat_target)
                for m in msgs:
                    role = "You" if m[0] == self.current_user_id else "Seller"
                    st.write(f"**{role}:** {m[1]}")

            with st.form("msg_form", clear_on_submit=True):
                msg_text = st.text_input("Type message...")
                if st.form_submit_button("Send"):
                    self.db.send_msg(self.current_user_id, st.session_state.chat_target, msg_text)
                    st.rerun()
            
            if st.button("Close Chat"):
                del st.session_state.chat_target
                st.rerun()

    def render_seller(self):
        st.title("🏪 Seller Dashboard")
        
        # 1. AI PROPOSALS
        st.subheader("🤖 AI Co-Pilot Suggestions")
        proposals = self.db.run_ai_analysis()
        if not proposals:
            st.success("Everything looks good! No urgent actions.")
        else:
            for i, p in enumerate(proposals):
                col1, col2 = st.columns([3, 1])
                col1.warning(f"**{p['name']}**: {p['reason']}")
                if col2.button("Approve", key=f"prop_{i}"):
                    if p['type'] == 'DISCOUNT':
                        self.db.execute_query_direct(f"UPDATE inventory SET discount_pct = 0.5 WHERE id = {p['item_id']}") # Simplified
                        # In real code, use the method
                        conn = self.db._get_conn()
                        conn.execute("UPDATE inventory SET price = price * 0.5 WHERE id = ?", (p['item_id'],))
                        conn.commit()
                        conn.close()
                    st.rerun()

        st.write("---")

        # 2. INVENTORY MANAGEMENT
        tab1, tab2 = st.tabs(["📦 My Inventory", "➕ Add Product"])
        
        with tab1:
            df = self.db.get_products_by_user(self.current_user_id)
            st.dataframe(df, use_container_width=True)

        with tab2:
            with st.form("add_form"):
                name = st.text_input("Product Name")
                qty = st.number_input("Quantity", min_value=1)
                price = st.number_input("Price", min_value=0.0)
                exp = st.date_input("Expiry Date")
                loc = st.text_input("Store Name")
                addr = st.text_input("Address")
                is_prod = st.checkbox("Local Producer?")
                if st.form_submit_button("Publish"):
                    self.db.register_item_direct(self.current_user_id, name, qty, price, exp.isoformat(), "Fresh", is_prod, addr)
                    st.success("Published!")
                    st.rerun()

    # Helper for the demo to avoid complexity in the main loop
    def register_item_direct(self, user_id, name, qty, price, exp, cond, is_prod, addr):
        conn = self.db._get_conn()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO products (name, is_perishable, is_producer) VALUES (?,?,?)", (name, True, is_prod))
        p_id = cursor.lastrowid
        cursor.execute("INSERT INTO inventory (user_id, name, qty, price, expiry_date, condition, is_producer, address) VALUES (?,?,?,?,?,?,?,?)",
                       (user_id, name, qty, price, exp, cond, is_prod, addr))
        conn.commit()
        conn.close()

# Patching the engine for the demo
LogiflowEngine.get_products_by_user = lambda self, uid: pd.read_sql_query("SELECT name, qty, price, expiry_date, condition FROM inventory WHERE user_id = ?", self._get_conn(), params=(uid,))

# ==============================================================================
# 4. MAIN EXECUTION
# ==============================================================================

if __name__ == "__main__":
    app = LogiflowUI(LogiflowEngine())
    app.render()
