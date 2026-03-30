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

## 🔜 Next Phase

### Phase-2: Retrieval-Augmented Generation (RAG)

* Embeddings (MiniLM / BGE)
* Vector DB (FAISS / ChromaDB)
* Context-aware responses
* Personal knowledge memory

---

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
