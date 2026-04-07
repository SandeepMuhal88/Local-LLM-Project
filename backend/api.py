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

embed_model = SentenceTransformer("all-MiniLM-L6-v2")
llm = Llama(model_path=MODEL_PATH, n_threads=8, n_ctx=2048)

client = chromadb.PersistentClient(path=DB_PATH)
collection = client.get_collection("my_data")

# ================= REQUEST =================
class QueryRequest(BaseModel):
    question: str

# ================= STREAM API =================
@app.post("/ask-stream")
def ask_stream(req: QueryRequest):

    query = req.question

    query_embedding = embed_model.encode([query]).tolist()[0]
    results = collection.query(query_embeddings=[query_embedding], n_results=3)

    docs = results["documents"][0]
    context = "\n\n".join(docs) if docs else ""

    prompt = f"""
Answer using context:

{context}

Question: {query}
"""

    def generate():
        stream = llm.create_chat_completion(
            messages=[{"role": "user", "content": prompt}],
            max_tokens=200,
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