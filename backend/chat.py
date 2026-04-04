from llama_cpp import Llama

# load the model

llm=Llama(
    model_path="../llama.cpp/models/phi-3-mini.gguf",
    n_threads=8,
    n_ctx=2048
)

# Conversation memory
messages = []

print("🤖 Local AI Assistant Started (type 'exit' to stop)\n")

while True:
    user_input = input("You: ")

    # Exit condition
    if user_input.lower() == "exit":
        print("Exiting...")
        break

    # Add user message
    messages.append({
        "role": "user",
        "content": user_input
    })

    # Generate AI response
    response = llm.create_chat_completion(
        messages=messages,
        max_tokens=200,
        temperature=0.7
    )

    ai_output = response["choices"][0]["message"]["content"]

    # Print AI response
    print("\nAI:", ai_output, "\n")

    # Save AI response
    messages.append({
        "role": "assistant",
        "content": ai_output
    })