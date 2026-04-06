import os
from sentence_transformers import SentenceTransformer
import chromadb

# ================= CONFIG =================
DATA_PATH = r"A:\Programming-Language-\Local-LLM-PRoject\Programing\Testing-code\backend\Rag\data.txt"
DB_PATH = r"A:\Programming-Language-\Local-LLM-PRoject\Programing\Testing-code\backend\Rag\db"
COLLECTION_NAME = "my_data"

# ================ LOAD MODEL ================
model = SentenceTransformer("all-MiniLM-L6-v2")

# ================ READ FILE =================
with open(DATA_PATH, "r", encoding="utf-8") as f:
    text = f.read()

# ================ CHUNKING ==================
chunks = [c.strip() for c in text.split("\n\n") if c.strip()]

print(f"📄 Total chunks: {len(chunks)}")

# ================ EMBEDDINGS ================
embeddings = model.encode(chunks).tolist()

# ================ DB CLIENT =================
client = chromadb.PersistentClient(path=DB_PATH)

# Create / Load collection
collection = client.get_or_create_collection(name=COLLECTION_NAME)

# Optional: clear old data (for fresh ingest)
# collection.delete(where={})

# ================ STORE DATA ===============
collection.add(
    documents=chunks,
    embeddings=embeddings,
    ids=[str(i) for i in range(len(chunks))]
)

print("✅ Data stored successfully in ChromaDB")