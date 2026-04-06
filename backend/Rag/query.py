# from langchain_huggingface import HuggingFaceEmbeddings
# from langchain_community.vectorstores import Chroma
# from llama_cpp import Llama
# import os

# MODEL_PATH = r"A:\Programming-Language-\Local-LLM-PRoject\Programing\Testing-code\llama.cpp\models\phi-3-mini.gguf"
# # Load vector DB
# embedding = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
# db = Chroma(persist_directory="rag/db", embedding_function=embedding)

# # Load LLM
# llm = Llama(
#     model_path=MODEL_PATH,
#     n_threads=8,
#     n_ctx=2048
# )

# query = input("Ask: ")

# # Retrieve relevant docs
# docs = db.similarity_search(query, k=2)

# context = "\n".join([doc.page_content for doc in docs])

# # Combine with prompt
# prompt = f"""
# Use the following context to answer:

# {context}

# Question: {query}
# """

# # Generate answer
# response = llm(
#     prompt,
#     max_tokens=200
# )

# print("\nAI Answer:\n", response["choices"][0]["text"])


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

try:
    collection = client.get_collection(COLLECTION_NAME)
except:
    print("❌ Collection not found. Run ingest.py first.")
    exit()

# ================ QUERY LOOP =================
while True:
    query = input("\nAsk (or 'exit'): ")

    if query.lower() == "exit":
        break

    # ---- Embed Query ----
    query_embedding = embed_model.encode([query]).tolist()[0]

    # ---- Search ----
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=TOP_K
    )

    docs = results["documents"][0]

    if not docs:
        print("⚠️ No relevant data found")
        continue

    # ---- Build Context ----
    context = "\n\n".join(docs)

    # ---- Prompt Engineering ----
    prompt = f"""
You are a helpful AI assistant.

Answer ONLY using the provided context.
If answer is not in context, say "I don't know".

Context:
{context}

Question: {query}

Answer:
"""

    # ---- Generate ----
    output = llm(
        prompt,
        max_tokens=200,
        temperature=0.3,
        top_p=0.9
    )

    answer = output["choices"][0]["text"].strip()

    print("\n🧠 AI Answer:\n", answer)