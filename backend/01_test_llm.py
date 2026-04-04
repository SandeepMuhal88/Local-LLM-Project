from llama_cpp import Llama

llm = Llama(
    model_path="../llama.cpp/models/phi-3-mini.gguf",
    n_threads=8,
    n_ctx=2048
)

# Conversation memory
messages = []

print("AI Assistant Started (type 'exit' to stop)\n")

while True:
    user_input = input("You: ")

    if user_input.lower() == "exit":
        break

    # Add user message
    messages.append({"role": "user", "content": user_input})

    # Generate response
    response = llm.create_chat_completion(
        messages=messages,
        max_tokens=200,
        temperature=0.7
    )

    ai_output = response["choices"][0]["message"]["content"]

    # Print
    print("\nAI:", ai_output, "\n")

    # Save AI response
    messages.append({"role": "assistant", "content": ai_output})