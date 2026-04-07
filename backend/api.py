from fastapi import FastAPI
from fastapi.responses import StreamingResponse
import json

@app.post("/ask-stream")
def ask_stream(req: QueryRequest):

    query = req.question

    # ---- Retrieval ----
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