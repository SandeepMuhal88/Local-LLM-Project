from fastapi import FastAPI
from pydantic import BaseModel

from sentence_transformers import SentenceTransformer
import chromadb
from llama_cpp import Llama

# ================= INIT =================
app = FastAPI()

DB_PATH = r"A:\Programming-Language-\Local-LLM-PRoject\Programing\Testing-code\backend\Rag\db"
MODEL_PATH = r"A:\Programming-Language-\Local-LLM-PRoject\Programing\Testing-code\llama.cpp\models\phi-3-mini.gguf"

embed_model = SentenceTransformer("all-MiniLM-L6-v2")
llm = Llama(model_path=MODEL_PATH, n_threads=8, n_ctx=2048)

client = chromadb.PersistentClient(path=DB_PATH)
collection = client.get_collection("my_data")

# ================= REQUEST MODEL =================
class QueryRequest(BaseModel):
    question: str

# ================= API =================
@app.post("/ask")
def ask_question(req: QueryRequest):
    query = req.question

    # ---- Embedding ----
    query_embedding = embed_model.encode([query]).tolist()[0]

    # ---- Retrieval ----
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=3
    )

    docs = results["documents"][0]
    context = "\n\n".join(docs) if docs else ""

    # ---- Prompt ----
    prompt = f"""
Answer using the context below. If not found, say "I don't know".

Context:
{context}

Question: {query}
"""

    # ---- LLM ----
    response = llm.create_chat_completion(
        messages=[{"role": "user", "content": prompt}],
        max_tokens=200,
        temperature=0.3
    )

    answer = response["choices"][0]["message"]["content"]

    return {
        "question": query,
        "answer": answer
    }