import sys
from logiflow.database import LogiflowDB
from logiflow.engine import LogiflowEngine
from logiflow.ui import LogiflowUI

def main():
    print("🚀 Initializing Logiflow...")
    engine = LogiflowEngine()
    
    # Se estiver no Kaggle/Jupyter, abre a UI. Se for terminal, roda simulação.
    if 'ipykernel' in sys.modules:
        ui = LogiflowUI(engine)
        ui.render()
    else:
        print("Running in CLI Mode (Headless)...")
        # Aqui você pode adicionar um loop de simulação para o terminal

if __name__ == "__main__":
    main()
