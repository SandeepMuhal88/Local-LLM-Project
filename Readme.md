# 🧠 Local LLM Project — Phase 1 (Core Inference Setup)

## 📌 Overview

This project is the foundation of an **Offline Personal AI Assistant** that runs fully on local hardware (no internet required).

In **Phase-1**, we successfully built and executed a **local Large Language Model (LLM) inference engine** using `llama.cpp` and a quantized GGUF model.

---

## 🎯 Objective (Phase-1)

* Run an LLM **locally on CPU**
* Understand **LLM inference pipeline**
* Execute prompts and generate responses
* Build the **core AI engine** for future phases (RAG, Agent, Voice, etc.)

---

## 🏗️ Architecture (Phase-1)

```
User Prompt → llama.cpp Runtime → GGUF Model → Token Generation → Output
```

---

## ⚙️ Tech Stack

### 🔹 Core Runtime

* `llama.cpp` (C++ based LLM inference engine)

### 🔹 Model

* `Phi-3 Mini (GGUF, Q4 quantized)`

### 🔹 Build Tools

* CMake
* MSVC (Visual Studio Build Tools)
* Git

### 🔹 System

* Windows 11 (x64)
* CPU-based inference (AVX2 enabled)

---

## 📁 Project Structure

```
llama.cpp/
 ├── build/
 │    └── bin/Release/
 │         ├── main.exe
 │         ├── llama-cli.exe
 │         └── quantize.exe
 ├── models/
 │    └── phi-3-mini.gguf
 └── ...
```

---

## 🚀 Setup & Execution

### 1. Clone Repository

```bash
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
```

---

### 2. Build Project

```bash
cmake -B build
cmake --build build --config Release
```

---

### 3. Add Model

* Download GGUF model (e.g., Phi-3 Mini)
* Place inside:

```
llama.cpp/models/
```

---

### 4. Run Local LLM

```bash
build\bin\Release\main.exe -m models\phi-3-mini.gguf -p "Explain AI in simple terms" -t 8
```

---

## 🧠 What Happens Internally

1. Model is loaded into RAM
2. Input prompt is tokenized
3. Transformer forward pass executes
4. Next-token probabilities generated
5. Tokens sampled iteratively
6. Final response is produced

This process is called **Auto-Regressive Inference**

---

## ⚡ Key Learnings

* Difference between **LLM runtime vs model**
* How **quantization (Q4)** enables edge deployment
* Understanding **token generation loop**
* Building **AI systems without APIs**
* Debugging **CMake + build environment**

---

## ⚠️ Challenges Faced

* CMake not recognized (PATH issue)
* Build environment setup (MSVC)
* Understanding correct output directories
* Distinguishing `.cpp` vs `.exe`

---

## ✅ Outcome

✔ Successfully built local LLM engine
✔ Ran inference without internet
✔ Generated responses from local model
✔ Established base for advanced AI system

---


# 🚀 NoNet AI — Local AI Assistant (Fully Offline + RAG + Mobile App)

## 📌 Overview

**NoNet AI** is a fully local AI assistant system that runs **without internet APIs**.
It combines:

* 🧠 Local LLM (Phi-3 via llama.cpp)
* 📚 RAG (Retrieval-Augmented Generation)
* ⚡ FastAPI backend
* 📱 Flutter mobile app

The system is designed to provide a **ChatGPT-like experience locally**, with support for:

* Streaming responses
* Voice input (optional)
* Custom knowledge (RAG)
* Mobile UI

---

## 🏗️ System Architecture

```
Flutter App (UI)
        ↓
FastAPI Backend
        ↓
RAG System (ChromaDB + Embeddings)
        ↓
LLM (Phi-3 via llama.cpp)
        ↓
Response (Streaming)
```

---

## ⚙️ Tech Stack

### 🔹 Backend

* Python
* FastAPI
* llama-cpp-python
* Sentence Transformers
* ChromaDB

### 🔹 Frontend

* Flutter (Dart)
* HTTP streaming
* Material UI

### 🔹 AI Stack

* Model: Phi-3 Mini (GGUF)
* Embedding: all-MiniLM-L6-v2
* Vector DB: ChromaDB

---

## 🧠 Features

### ✅ Local LLM

* Runs completely offline
* No API dependency
* Uses quantized GGUF model

### ✅ RAG (Knowledge System)

* Custom data ingestion
* Semantic search via embeddings
* Context-aware responses

### ✅ Chat System

* Multi-turn conversation
* Context memory (short-term)

### ✅ Streaming Responses

* Token-by-token output (ChatGPT-like)

### ✅ Mobile App (Flutter)

* Chat UI
* Streaming messages
* Dark theme
* Auto-scroll

### ✅ Voice Input (Optional)

* Speech-to-text integration

---

## 📁 Project Structure

```
project/
 ├── llama.cpp/
 ├── models/
 │    └── phi-3-mini.gguf
 │
 ├── backend/
 │    ├── api.py
 │    └── Rag/
 │         ├── ingest.py
 │         ├── query.py
 │         ├── rag_chat.py
 │         └── db/
 │
 ├── ai_assistant_app/
 │    └── lib/
 │         ├── main.dart
 │         ├── models/
 │         ├── services/
 │         └── screens/
```

---

## 🔥 Setup Instructions

---

### 1️⃣ Clone Repository

```bash
git clone <your-repo>
cd project
```

---

### 2️⃣ Setup Backend

#### Create Virtual Environment

```bash
python -m venv .venv
.\.venv\Scripts\activate
```

#### Install Dependencies

```bash
pip install fastapi uvicorn llama-cpp-python sentence-transformers chromadb
```

---

### 3️⃣ Run Backend

```bash
uvicorn api:app --reload
```

Open:

```
http://127.0.0.1:8000/docs
```

---

### 4️⃣ Setup Flutter App

```bash
cd ai_assistant_app
flutter pub get
flutter run
```

---

## ⚠️ Important Configuration

### 🔹 Base URL (Flutter)

```dart
http://127.0.0.1:8000
```

> ❌ Do NOT use `10.0.2.2` for desktop
> ✅ Use `127.0.0.1` for Windows

---

## 🧠 RAG Workflow

```
Text → Chunk → Embedding → Vector DB
User Query → Embedding → Similarity Search → Context
Context + Query → LLM → Answer
```

---

## 🔧 Key Learnings

### 1. Local AI Stack

* LLM inference via llama.cpp
* GGUF model optimization

### 2. RAG Pipeline

* Embeddings + vector search
* Context grounding

### 3. Backend Engineering

* FastAPI
* Streaming responses
* CORS handling

### 4. Frontend Integration

* Flutter HTTP streaming
* Real-time UI updates

---

## 🐛 Issues Faced & Fixes

| Issue                     | Fix                                 |
| ------------------------- | ----------------------------------- |
| cmake not found           | Installed + added to PATH           |
| Model not loading         | Correct GGUF placement              |
| HuggingFace errors        | Used correct repo / manual download |
| llama_cpp not found       | Installed in venv                   |
| ChromaDB collection error | Used PersistentClient               |
| No response in app        | Fixed API URL                       |
| 405 OPTIONS error         | Enabled CORS                        |
| FilePicker crash          | Used `FilePicker.platform`          |

---

## 🚀 Future Improvements

* 🔥 Chat history persistence (SQLite)
* 🔥 Sidebar (like ChatGPT)
* 🔥 Voice output (TTS)
* 🔥 Model optimization for mobile
* 🔥 Offline mobile LLM
* 🔥 Multi-file RAG (PDF, DOCX)

---

## 🎯 Goal

Build a **fully local AI assistant** that:

* Works without internet
* Uses personal knowledge
* Runs on personal hardware
* Can be deployed on mobile

---

## 🧠 Author

Built as part of a **Local LLM Project**
Focused on learning:

* AI systems
* Backend engineering
* Mobile integration
* RAG pipelines

---

## ⭐ Final Result

```
✔ Local ChatGPT-like App
✔ Fully Offline AI
✔ Custom Knowledge System
✔ Mobile UI + Backend Integration
```

---

🔥 **NoNet AI = Your Personal Local Intelligence System**



## 🌟 Vision

To build a **fully offline, privacy-first, multimodal AI assistant** capable of:

* Reasoning
* Memory (RAG)
* Tool usage (Agent)
* Voice interaction
* Mobile deployment

---

## 📌 Author

**Sandeep Muhal**
B.Tech CSE | AI Systems Builder

---

## ⭐ Note

This is not just a project —
This is a **Local AI System Engineering Journey**.
