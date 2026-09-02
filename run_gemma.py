from llama_cpp import Llama

# O caminho deve ser o nome do arquivo que o 'hf' baixou
llm = Llama(
    model_path="./gemini-3.5-flash-lite",
    n_ctx=2048, 
    n_threads=4
)

print("Hello How can I help?!")
response = llm("Explique o conceito de arquitetura esférica:", max_tokens=150)
print(response['choices'][0]['text'])
