import ipywidgets as widgets
from IPython.display import display, HTML, clear_output
import datetime
import pandas as pd

class LogiflowUI:
    def __init__(self, engine):
        self.engine = engine
        self.setup_widgets()

    def setup_widgets(self):
        self.user_input = widgets.Text(placeholder='e.g. Milk', description='🔍 Search:')
        self.user_btn = widgets.Button(description='Find Nearby', button_style='info', icon='search')
        self.user_output = widgets.Output()

        self.s_prod = widgets.Text(description="Product:", placeholder="Organic Milk")
        self.s_qty = widgets.IntText(description="Qty:", value=10)
        self.s_price = widgets.FloatText(description="Price ($):", value=5.0)
        self.s_exp = widgets.DatePicker(description="Expiry:")
        self.s_loc = widgets.Text(description="Store:", placeholder="Corner Shop")
        self.s_addr = widgets.Text(description="Address:", placeholder="123 Main St")
        self.s_is_prod = widgets.Checkbox(description="Local Producer?", value=False)
        self.s_submit = widgets.Button(description='Submit to Logiflow', button_style='success', icon='cloud-upload')
        self.seller_output = widgets.Output()

        self.decision_header = widgets.HTML("<b>🤖 AI Decision Queue (Requires Authorization)</b>")
        self.decision_output = widgets.Output()
        self.impact_output = widgets.Output()

        self.user_btn.on_click(self.on_search)
        self.s_submit.on_click(self.on_seller_submit)

    def on_search(self, b):
        with self.user_output:
            clear_output()
            df = self.engine.search_items(self.user_input.value)
            if df.empty:
                print("⚠️ No local matches found.")
                return
            self.display_results(df)

    def display_results(self, df):
        html = "<div style='display: flex; flex-wrap: wrap; gap: 15px;'>"
        today = datetime.date.today()
        for _, row in df.iterrows():
            is_zero_waste = row['discount_pct'] > 0 or (pd.to_datetime(row['expiry_date']).date() - today).days < 3
            badge = "🌿 <b>LOCAL FARMER</b>" if row['is_producer'] else ""
            price_txt = "🎁 <b>FREE (DONATION)</b>" if is_zero_waste else f"${row['price']:.2f}"
            html += f"""
            <div style="border: 1px solid #ddd; padding: 15px; border-radius: 10px; width: 220px; background: white; font-family: sans-serif;">
                <div style="font-size: 11px; color: #27ae60;">{badge}</div>
                <div style="font-size: 16px; font-weight: bold;">{row['name']}</div>
                <div style="font-size: 14px; color: #e67e22;">{price_txt}</div>
                <div style="font-size: 12px; color: #7f8c8d; margin-top: 5px;">📍 {row['location']}</div>
                <div style="font-size: 10px; color: #bdc3c7;">{row['address']}</div>
                <div style="font-size: 10px; color: #e74c3c; font-weight: bold;">{'🔥 ZERO WASTE DEAL' if is_zero_waste else ''}</div>
            </div>"""
        html += "</div>"
        display(HTML(html))

    def on_seller_submit(self, b):
        with self.seller_output:
            clear_output()
            if not self.s_exp.value:
                print("❌ Error: Select expiry date.")
                return
            data = {
                "name": self.s_prod.value, "qty": self.s_qty.value, "price": self.s_price.value,
                "exp": self.s_exp.value, "loc": self.s_loc.value, "addr": self.s_addr.value,
                "last_upd": datetime.datetime.now(), "is_prod": self.s_is_prod.value
            }
            success, msg = self.engine.register_item(data)
            print(msg)
            self.refresh_all()

    def handle_proposal(self, idx):
        self.engine.authorize_action(idx)
        self.refresh_all()
        with self.seller_output:
            print("✨ Action Authorized!")

    def refresh_all(self):
        with self.decision_output:
            clear_output()
            proposals = self.engine.run_ai_analysis()
            if not proposals:
                display(HTML("<i>No pending AI suggestions.</i>"))
            else:
                for i, p in enumerate(proposals):
                    btn = widgets.Button(description=f"✅ Approve {p['name']}", button_style='warning', layout=widgets.Layout(width='180px'))
                    btn.on_click(lambda b, idx=i: self.handle_proposal(idx))
                    display(HTML(f"<b>{p['type']}: {p['name']} ({p['reason']})</b>"))
                    display(btn)
        
        with self.impact_output:
            clear_output()
            display(HTML("<div style='display: flex; justify-content: space-around; background: #f8f9fa; padding: 10px; border-radius: 10px; border: 1px solid #dee2e6;'>"))
            display(HTML("<div style='text-align: center;'><b>♻️ Waste Prevented</b><br>12</div>"))
            display(HTML("<div style='text-align: center;'><b>🤝 Donations</b><br>4</div>"))
            display(HTML("<div style='text-align: center;'><b>💰 Savings</b><br>$45.50</div>"))
            display(HTML("</div>"))

    def render(self):
        header = widgets.HTML("<div style='background:#2c3e50; padding:15px; border-radius:10px; text-align:center; color:white;'><h1>Logiflow: The Human-AI Bridge</h1></div>")
        seller_ui = widgets.VBox([
            widgets.HTML("<h3>🏪 Seller Dashboard</h3>"),
            self.s_prod, self.s_qty, self.s_price, self.s_exp, self.s_loc, self.s_addr, self.s_is_prod, self.s_submit,
            widgets.HTML("<hr>"), self.decision_header, self.decision_output, self.seller_output
        ], layout=widgets.Layout(width='450px', padding='10px', border='2px solid #3498db', border_radius='10px'))

        user_ui = widgets.VBox([
            widgets.HTML("<h3>🛒 User Search Portal</h3>"),
            widgets.HBox([self.user_input, self.user_btn]),
            self.user_output
        ], layout=widgets.Layout(width='550px', padding='10px', border='2px solid #2ecc71', border_radius='10px'))

        main_layout = widgets.VBox([header, widgets.HBox([seller_ui, user_ui], layout=widgets.Layout(justify_content='center', margin='20px 0')), self.impact_output])
        display(main_layout)
        self.refresh_all()
