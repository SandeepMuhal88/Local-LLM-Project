from huggingface_hub import hf_hub_download

file_path= hf_hub_download(
    repo_id="TheBloke/Phi-3-mini-4k-instruct-GGUF",
    filename="phi-3-mini-4k-instruct.Q4_K_M.gguf",
    local_dir="models",
    local_dir_use_symlinks=False
)

print(f"Model downloaded to: {file_path}")