import streamlit as st
import pandas as pd
import datetime
# IMPORTANTE: Importamos a classe centralizada
from logiflow.database import LogiflowDB 

class LogiflowUI:
    def __init__(self):  
        self.db = LogiflowDB() # Usa a versão segura
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

    # ... (mantenha render_sidebar, render_auth, render_consumer_marketplace iguais)

    def render_seller_dashboard(self):
        st.title("🏪 Seller Dashboard")
        user_id = st.session_state.user['user_id']

        # Métricas
        m1, m2, m3 = st.columns(3)
        impact = self.db.get_impact_metrics(user_id)
        m1.metric("Active Products", len(self.db.get_user_products(user_id)))
        m2.metric("Waste Prevented", f"{impact} kg")
        m3.metric("AI Engine", "Gemma 4 Active")

        # Aba de Inventário e Cadastro
        tab1, tab2 = st.tabs(["📦 Inventory", "➕ Add Product"])
        with tab1:
            st.dataframe(self.db.get_user_products(user_id), use_container_width=True)
        
        with tab2:
            with st.form("new_prod", clear_on_submit=True):
                name = st.text_input("Name")
                qty = st.number_input("Qty", min_value=0, step=1) # Validação mínima
                price = st.number_input("Price", min_value=0.0, step=0.5)
                exp = st.date_input("Expiry")
                addr = st.text_input("Address")
                is_p = st.checkbox("Local Producer")
                
                submit = st.form_submit_button("Publish")
                if submit:
                    # VALIDAÇÃO DE LÓGICA DE NEGÓCIO
                    if not name:
                        st.error("Name is required.")
                    elif qty <= 0:
                        st.error("Quantity must be greater than 0.")
                    elif price <= 0:
                        st.error("Price must be greater than 0.")
                    elif exp < datetime.date.today():
                        st.error("Expiry date cannot be in the past.")
                    else:
                        self.db.register_product(user_id, name, qty, price, exp.isoformat(), "Fresh", is_p, addr)
                        st.success("Product live!")
                        st.rerun()

if __name__ == "__main__":
    app = LogiflowUI()
    app.run()
