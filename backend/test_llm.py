from llama_cpp import Llama

llm = Llama(
    model_path="../llama.cpp/models/phi-3-mini.gguf",
    n_threads=8,
    n_ctx=2048
)

response = llm.create_chat_completion(
    messages=[
        {"role": "user", "content": "Explain machine learning like I am 5 years old"}
    ],
    max_tokens=200,
    temperature=0.7
)

print(response["choices"][0]["message"]["content"])