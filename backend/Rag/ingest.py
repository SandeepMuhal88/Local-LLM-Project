from langchain.document_loaders import TextLoader
from langchain.text_splitter import CharacterTextSplitter
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.vectorstores import Chroma

# Load file
loader = TextLoader("rag/data/notes.txt")
documents = loader.load()

# Split text
text_splitter = CharacterTextSplitter(chunk_size=200, chunk_overlap=20)
docs = text_splitter.split_documents(documents)

# Create embeddings
embedding = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")

# Store in vector DB
db = Chroma.from_documents(docs, embedding, persist_directory="rag/db")

db.persist()

print("✅ Data embedded and stored")