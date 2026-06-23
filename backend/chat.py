from llama_cpp import Llama
from pathlib import Path
import os
import sys


def _load_llm():
    model_path = os.getenv("LLAMA_MODEL_PATH") or str(Path(__file__).resolve().parent.parent / "llama.cpp" / "models" / "phi-3-mini.gguf")
    threads = max(1, (os.cpu_count() or 1) - 1)
    return Llama(model_path=model_path, n_threads=threads, n_ctx=2048)


def repl():
    llm = None
    try:
        llm = _load_llm()
    except Exception as e:
        print("Failed to load model:", e)
        sys.exit(1)

    messages = []
    print("🤖 Local AI Assistant Started (type 'exit' to stop)\n")

    try:
        while True:
            user_input = input("You: ").strip()
            if not user_input:
                continue
            if user_input.lower() == "exit":
                print("Exiting...")
                break

            messages.append({"role": "user", "content": user_input})

            response = llm.create_chat_completion(messages=messages, max_tokens=200, temperature=0.7)
            ai_output = response["choices"][0]["message"]["content"]

            print("\nAI:", ai_output, "\n")
            messages.append({"role": "assistant", "content": ai_output})
    except KeyboardInterrupt:
        print("\nInterrupted. Exiting...")


if __name__ == "__main__":
    repl()