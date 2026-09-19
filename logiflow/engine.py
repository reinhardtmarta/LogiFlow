import sqlite3
import pandas as pd
import datetime

class LogiflowEngine:
    def __init__(self, db_name="logiflow_final.db"):
        self.db_name = db_name
        self.proposals = []
        self.audit_log = []

    def _get_conn(self):
        return sqlite3.connect(self.db_name)

    def log_event(self, action, details):
        self.audit_log.append({
            "timestamp": datetime.datetime.now().isoformat(),
            "action": action,
            "details": details
        })

    def run_ai_analysis(self):
        conn = self._get_conn()
        query = "SELECT i.item_id, p.name, i.expiry_date, i.quantity, i.price FROM inventory i JOIN products p ON i.product_id = p.product_id"
        df = pd.read_sql_query(query, conn)
        conn.close()
        
        self.proposals = []
        today = datetime.date.today()
        for _, row in df.iterrows():
            expiry = pd.to_datetime(row['expiry_date']).date()
            days_to_exp = (expiry - today).days
            if 0 <= days_to_exp < 3 and row['price'] > 0:
                self.proposals.append({'type': 'DISCOUNT', 'item_id': row['item_id'], 'name': row['name'], 'reason': f"Expiring in {days_to_exp} days", 'action_val': 0.50})
            elif row['quantity'] < 10:
                self.proposals.append({'type': 'RESTOCK', 'item_id': row['item_id'], 'name': row['name'], 'reason': "Stock critically low", 'action_val': None})
        return self.proposals

    def authorize_action(self, proposal_index):
        prop = self.proposals.pop(proposal_index)
        conn = self._get_conn()
        cursor = conn.cursor()
        if prop['type'] == 'DISCOUNT':
            cursor.execute("UPDATE inventory SET discount_pct = ? WHERE item_id = ?", (prop['action_val'], prop['item_id']))
        elif prop['type'] == 'RESTOCK':
            cursor.execute("UPDATE inventory SET quantity = quantity + 50 WHERE item_id = ?", (prop['item_id'],))
        conn.commit()
        conn.close()
        self.log_event("AI_AUTHORIZATION", f"Authorized {prop['type']} for {prop['name']}")
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
        self.log_event("SELLER_REGISTRATION", f"Registered {data['name']} at {data['addr']}")
        return True, "Broadcasted to Global Maps!"

    def search_items(self, query):
        conn = self._get_conn()
        sql = "SELECT i.item_id, p.name, i.quantity, i.location, i.expiry_date, i.price, i.discount_pct, p.is_producer, i.address FROM inventory i JOIN products p ON i.product_id = p.product_id WHERE p.name LIKE ?"
        df = pd.read_sql_query(sql, conn, params=(f"%{query}%",))
        conn.close()
        self.log_event("USER_SEARCH", f"Query: {query}")
        return df
