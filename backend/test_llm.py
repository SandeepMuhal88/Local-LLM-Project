from llama_cpp import Llama

# Load model
llm = Llama(
    model_path="../models/phi-3-mini.gguf",  # adjust path if needed
    n_threads=8,
    n_ctx=2048,
    verbose=True
)

# Prompt
prompt = "Explain machine learning in simple terms"

# Generate response
output = llm(
    prompt,
    max_tokens=200,
    temperature=0.7
)

# Print result
print("\nAI Response:\n")
print(output["choices"][0]["text"])