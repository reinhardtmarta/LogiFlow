import sqlite3
import datetime
import bcrypt  # IMPORTANTE: Para segurança de senhas
import pandas as pd

class LogiflowDB:
    def __init__(self, db_name="logiflow_final.db"):
        self.db_name = db_name
        self._setup_db()

    def _get_conn(self):
        return sqlite3.connect(self.db_name)

    def _setup_db(self):
        conn = self._get_conn()
        cursor = conn.cursor()
        # Criar tabelas com a estrutura correta
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
        conn.commit()
        conn.close()

    # --- AUTH (COM SEGURANÇA) ---
    def register_user(self, name, email, password, phone, address, is_seller):
        conn = self._get_conn()
        cursor = conn.cursor()
        try:
            # Transformamos a senha em um "hash" (nunca salvamos a senha real)
            salt = bcrypt.gensalt()
            hashed_pw = bcrypt.hashpw(password.encode('utf-8'), salt)
            
            cursor.execute("INSERT INTO users (name, email, password, phone, address, is_seller) VALUES (?,?,?,?,?,?)",
                           (name, email, hashed_pw.decode('utf-8'), phone, address, is_seller))
            conn.commit()
            return True
        except sqlite3.IntegrityError:
            return False
        finally:
            conn.close()

    def login_user(self, email, password):
        conn = self._get_conn()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE email = ?", (email,))
        row = cursor.fetchone()
        conn.close()

        if row:
            user_id, name, stored_hash, phone, address, is_seller = row[0], row[1], row[2], row[3], row[4], row[5]
            # Verificamos se a senha digitada bate com o hash salvo
            if bcrypt.checkpw(password.encode('utf-8'), stored_hash.encode('utf-8')):
                return pd.DataFrame([{
                    'user_id': user_id, 'name': name, 'email': email, 
                    'phone': phone, 'address': address, 'is_seller': is_seller
                }])
        return pd.DataFrame()

    # --- PRODUTOS ---
    def register_product(self, user_id, name, qty, price, expiry, condition, is_producer, address):
        conn = self._get_conn()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO products (user_id, name, qty, price, expiry_date, condition, is_producer, address) VALUES (?,?,?,?,?,?,?,?)",
                       (user_id, name, qty, price, expiry, condition, is_producer, address))
        conn.commit()
        conn.close()

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

    def get_impact_metrics(self, user_id):
        conn = self._get_conn()
        df = pd.read_sql_query("SELECT SUM(waste_prevented_kg) as total_kg FROM products WHERE user_id = ?", conn, params=(user_id,))
        conn.close()
        return df['total_kg'].iloc[0] if not df.empty and df['total_kg'].iloc[0] is not None else 0.0
