from llama_cpp import Llama
import sqlite3

class LogiFlowAI:
    def __init__(self, model_path):
      
        self.llm = Llama(model_path=model_path, n_ctx=2048)

    def query_inventory(self, user_prompt):
        # Lógica para converter linguagem natural em ação de inventário
        system_prompt = "Você é o assistente LogiFlow. Converta o pedido em uma sugestão logística."
        response = self.llm(f"System: {system_prompt}\nUser: {user_prompt}", max_tokens=100)
        return response['choices'][0]['text']


