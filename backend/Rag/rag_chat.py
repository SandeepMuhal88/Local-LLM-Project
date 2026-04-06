from sentence_transformers import SentenceTransformer
import chromadb
from llama_cpp import Llama

# ================= CONFIG =================
DB_PATH = r"A:\Programming-Language-\Local-LLM-PRoject\Programing\Testing-code\backend\Rag\db"
COLLECTION_NAME = "my_data"
MODEL_PATH = r"A:\Programming-Language-\Local-LLM-PRoject\Programing\Testing-code\llama.cpp\models\phi-3-mini.gguf"

TOP_K = 3

# ================ LOAD MODELS ================
embed_model = SentenceTransformer("all-MiniLM-L6-v2")

llm = Llama(
    model_path=MODEL_PATH,
    n_threads=8,
    n_ctx=2048
)

# ================ LOAD DB ====================
client = chromadb.PersistentClient(path=DB_PATH)
collection = client.get_collection(COLLECTION_NAME)

# ================ MEMORY =====================
chat_history = []

print("🤖 RAG Assistant Started (type 'exit' to stop)\n")

# ================ CHAT LOOP ==================
while True:
    query = input("You: ")

    if query.lower() == "exit":
        break

    # ---- Save user input ----
    chat_history.append({"role": "user", "content": query})

    # ---- Embed Query ----
    query_embedding = embed_model.encode([query]).tolist()[0]

    # ---- Retrieve Context ----
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=TOP_K
    )

    docs = results["documents"][0]

    context = "\n\n".join(docs) if docs else ""

    # ---- Build Chat History String ----
    history_text = ""
    for msg in chat_history[-6:]:  # limit memory (last 6 messages)
        role = msg["role"]
        content = msg["content"]
        history_text += f"{role.upper()}: {content}\n"

    # ---- Prompt Engineering ----
    prompt = f"""
You are a helpful AI assistant.

Use the conversation history AND context to answer.

If answer is not in context, say "I don't know".

-----------------------
Conversation History:
{history_text}

-----------------------
Context:
{context}

-----------------------
User Question:
{query}

Answer:
"""

    # ---- Generate Response ----
    response = llm.create_chat_completion(
        messages=[
            {"role": "user", "content": prompt}
        ],
        max_tokens=200,
        temperature=0.3
    )

    answer = response["choices"][0]["message"]["content"].strip()

    print("\n🧠 AI:", answer, "\n")

    # ---- Save AI response ----
    chat_history.append({"role": "assistant", "content": answer})