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

# Load embedding model
embed_model = SentenceTransformer("all-MiniLM-L6-v2")

# Load DB
client = chromadb.Client()
collection = client.get_collection("my_data")

# Load LLM
llm = Llama(
    model_path="../llama.cpp/models/phi-3-mini.gguf",
    n_threads=8,
    n_ctx=2048
)

query = input("Ask: ")

# Convert query to embedding
query_embedding = embed_model.encode([query])[0]

# Search similar data
results = collection.query(
    query_embeddings=[query_embedding],
    n_results=2
)

context = "\n".join(results["documents"][0])

# Final prompt
prompt = f"""
Use this context to answer:

{context}

Question: {query}
"""

# Generate answer
output = llm(
    prompt,
    max_tokens=200
)

print("\nAI Answer:\n", output["choices"][0]["text"])