from llama_cpp import Llama

# O caminho deve ser o nome do arquivo que o 'hf' baixou
llm = Llama(
    model_path="./gemma-4-4b-it-Q4_K_M.gguf", 
    n_ctx=2048, 
    n_threads=4
)

print("Gemma 4 iniciado!")
response = llm("Explique o conceito de arquitetura esférica:", max_tokens=150)
print(response['choices'][0]['text'])
