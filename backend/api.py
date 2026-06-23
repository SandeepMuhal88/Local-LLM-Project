from fastapi import FastAPI, UploadFile
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from sentence_transformers import SentenceTransformer
import chromadb
from llama_cpp import Llama
import os
import uuid
import logging
from pathlib import Path
from starlette.concurrency import run_in_threadpool

# ============== Config & Logging ==============
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parent
DB_PATH = Path(os.getenv("RAG_DB_PATH", str(ROOT / "Rag" / "db")))
MODEL_PATH = Path(os.getenv("LLAMA_MODEL_PATH", str(ROOT.parent / "llama.cpp" / "models" / "phi-3-mini.gguf")))
EMBED_MODEL_PATH = Path(os.getenv("EMBED_MODEL_PATH", str(ROOT.parent / "models" / "all-MiniLM-L6-v2")))

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global resources will be initialized at startup
embed_model = None
llm = None
client = None
collection = None


@app.on_event("startup")
async def startup_event():
    global embed_model, llm, client, collection
    logger.info("Starting application and loading models")

    # Load embedding model in a thread to avoid blocking the event loop
    try:
        embed_model = await run_in_threadpool(SentenceTransformer, str(EMBED_MODEL_PATH))
        logger.info("Loaded embedding model from %s", EMBED_MODEL_PATH)
    except Exception as e:
        logger.exception("Failed to load embedding model: %s", e)
        raise

    # Load LLaMA model in threadpool
    def _load_llm():
        threads = max(1, (os.cpu_count() or 1) - 1)
        return Llama(model_path=str(MODEL_PATH), n_threads=threads, n_ctx=2048)

    try:
        llm = await run_in_threadpool(_load_llm)
        logger.info("Loaded LLaMA model from %s using %s threads", MODEL_PATH, max(1, (os.cpu_count() or 1) - 1))
    except Exception as e:
        logger.exception("Failed to load LLaMA model: %s", e)
        raise

    # Initialize chroma client and collection
    client = chromadb.PersistentClient(path=str(DB_PATH))
    try:
        collection = client.get_collection("my_data")
        logger.info("Opened collection 'my_data'")
    except Exception:
        collection = client.create_collection("my_data")
        logger.info("Created collection 'my_data'")


class QueryRequest(BaseModel):
    question: str


@app.post("/ask-stream")
async def ask_stream(req: QueryRequest):
    if embed_model is None or llm is None or collection is None:
        return StreamingResponse(iter(["Service not ready"]), media_type="text/plain")

    query = req.question.strip()
    greetings = {"hi", "hello", "hey", "hii"}
    if query.lower() in greetings:
        async def gen_greeting():
            yield "Hello 👋 I am NoNet AI. How can I help you?"
        return StreamingResponse(gen_greeting(), media_type="text/plain")

    # 2. EMBEDDING (run in threadpool)
    try:
        query_embedding = await run_in_threadpool(lambda: embed_model.encode([query]).tolist()[0])
    except Exception as e:
        logger.exception("Embedding failed: %s", e)
        return StreamingResponse(iter(["Embedding error"]), media_type="text/plain")

    # 3. QUERY DB
    try:
        results = await run_in_threadpool(collection.query, query_embeddings=[query_embedding], n_results=3)
        docs = results["documents"][0]
        distances = results["distances"][0]
    except Exception as e:
        logger.exception("Chroma query failed: %s", e)
        docs = []
        distances = [1.0]

    THRESHOLD = 0.6
    context = "" if (not distances or distances[0] > THRESHOLD) else "\n\n".join(docs)

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

    async def generate():
        try:
            stream = await run_in_threadpool(lambda: llm.create_chat_completion(messages=[{"role": "user", "content": prompt}], max_tokens=200, temperature=0.4, stream=True))
        except Exception as e:
            logger.exception("LLM call failed: %s", e)
            yield "LLM error"
            return

        iterator = iter(stream)
        while True:
            try:
                chunk = await run_in_threadpool(next, iterator)
            except StopIteration:
                break
            except Exception as e:
                logger.exception("Error iterating LLM stream: %s", e)
                break
            token = chunk["choices"][0]["delta"].get("content", "")
            if token:
                yield token

    return StreamingResponse(generate(), media_type="text/plain")


@app.post("/upload")
async def upload_file(file: UploadFile):
    if embed_model is None or collection is None:
        return {"status": "service not ready"}

    content = await file.read()
    try:
        text = content.decode("utf-8")
    except Exception:
        text = content.decode("utf-8", errors="ignore")

    chunks = [c for c in text.split("\n\n") if c.strip()]
    if not chunks:
        return {"status": "no content"}

    try:
        embeddings = await run_in_threadpool(lambda: embed_model.encode(chunks).tolist())
    except Exception as e:
        logger.exception("Embedding failed: %s", e)
        return {"status": "embedding error"}

    ids = [str(uuid.uuid4()) for _ in range(len(chunks))]
    try:
        await run_in_threadpool(collection.add, documents=chunks, embeddings=embeddings, ids=ids)
    except Exception as e:
        logger.exception("Chroma add failed: %s", e)
        return {"status": "db add error"}

    return {"status": "uploaded", "count": len(chunks)}