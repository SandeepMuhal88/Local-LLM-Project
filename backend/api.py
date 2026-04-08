from fastapi import FastAPI, UploadFile
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from sentence_transformers import SentenceTransformer
import chromadb
from llama_cpp import Llama

# ================= INIT =================
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allow all (dev mode)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)



DB_PATH = r"A:\Programming-Language-\Local-LLM-PRoject\Programing\Testing-code\backend\Rag\db"
MODEL_PATH = r"A:\Programming-Language-\Local-LLM-PRoject\Programing\Testing-code\llama.cpp\models\phi-3-mini.gguf"

# embed_model = SentenceTransformer("all-MiniLM-L6-v2")  # This Online Model and its not working Offline 


embed_model = SentenceTransformer(
    r"A:\Programming-Language-\Local-LLM-PRoject\Programing\Testing-code\models\all-MiniLM-L6-v2"
)
llm = Llama(model_path=MODEL_PATH, n_threads=8, n_ctx=2048)

client = chromadb.PersistentClient(path=DB_PATH)
collection = client.get_collection("my_data")

# ================= REQUEST =================
class QueryRequest(BaseModel):
    question: str

# ================= STREAM API =================
@app.post("/ask-stream")
def ask_stream(req: QueryRequest):

    query = req.question.strip()

    # ================= 1. GREETING HANDLER =================
    greetings = ["hi", "hello", "hey", "hii"]

    if query.lower() in greetings:
        def generate():
            yield "Hello 👋 I am NoNet AI. How can I help you?"
        return StreamingResponse(generate(), media_type="text/plain")

    # ================= 2. EMBEDDING =================
    query_embedding = embed_model.encode([query]).tolist()[0]

    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=3
    )

    docs = results["documents"][0]
    distances = results["distances"][0]  # VERY IMPORTANT

    # ================= 3. RELEVANCE CHECK =================
    THRESHOLD = 0.6   # tune this (0.4–0.8)

    if distances[0] > THRESHOLD:
        context = ""   # irrelevant → ignore RAG
    else:
        context = "\n\n".join(docs)

    # ================= 4. SMART PROMPT =================
    prompt = f"""
You are NoNet AI, a helpful assistant.

Rules:
- If context is provided → use it
- If context is empty → answer normally
- Do not force context

Context:
{context}

Question:
{query}

Answer:
"""

    # ================= 5. STREAM RESPONSE =================
    def generate():
        stream = llm.create_chat_completion(
            messages=[{"role": "user", "content": prompt}],
            max_tokens=200,
            temperature=0.4,
            stream=True
        )

        for chunk in stream:
            token = chunk["choices"][0]["delta"].get("content", "")
            yield token

    return StreamingResponse(generate(), media_type="text/plain")

# ================= FILE UPLOAD =================
@app.post("/upload")
async def upload_file(file: UploadFile):

    content = await file.read()
    text = content.decode("utf-8")

    chunks = [c for c in text.split("\n\n") if c.strip()]
    embeddings = embed_model.encode(chunks).tolist()

    collection.add(
        documents=chunks,
        embeddings=embeddings,
        ids=[str(i) for i in range(len(chunks))]
    )

    return {"status": "uploaded"}