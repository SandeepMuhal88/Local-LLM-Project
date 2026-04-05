from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from llama_cpp import Llama

# Load vector DB
embedding = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
db = Chroma(persist_directory="rag/db", embedding_function=embedding)

# Load LLM
llm = Llama(
    model_path="../llama.cpp/models/phi-3-mini.gguf",
    n_threads=8,
    n_ctx=2048
)

query = input("Ask: ")

# Retrieve relevant docs
docs = db.similarity_search(query, k=2)

context = "\n".join([doc.page_content for doc in docs])

# Combine with prompt
prompt = f"""
Use the following context to answer:

{context}

Question: {query}
"""

# Generate answer
response = llm(
    prompt,
    max_tokens=200
)

print("\nAI Answer:\n", response["choices"][0]["text"])