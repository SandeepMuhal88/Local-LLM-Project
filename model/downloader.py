from huggingface_hub import hf_hub_download

file_path = hf_hub_download(
    repo_id="lmstudio-community/Phi-3-mini-4k-instruct-GGUF",
    filename="Phi-3-mini-4k-instruct-Q4_K_M.gguf",
    local_dir="models"
)

print("Downloaded:", file_path)