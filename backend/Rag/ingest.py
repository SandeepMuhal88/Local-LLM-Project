# 


from sentence_transformers import SentenceTransformer
import chromadb

# Load embedding model
model = SentenceTransformer("all-MiniLM-L6-v2")

# Read file
with open("rag/data.txt", "r", encoding="utf-8") as f:
    text = f.read()

# Split into chunks
chunks = text.split("\n\n")

# Create embeddings
embeddings = model.encode(chunks)

# Create DB
client = chromadb.Client()
collection = client.create_collection("my_data")

# Store data
for i, chunk in enumerate(chunks):
    collection.add(
        documents=[chunk],
        embeddings=[embeddings[i]],
        ids=[str(i)]
    )

print("✅ Data stored in vector DB")