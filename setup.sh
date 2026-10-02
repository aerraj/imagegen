#!/bin/zsh
set -euo pipefail

repo_dir=${0:A:h}
ai_dir=${AI_DIR:-$HOME/AI}
comfy_dir="$ai_dir/ComfyUI"
comfy_ref=fa98a189b4271c76f66210e15f81790b555eb610

if ! command -v brew >/dev/null 2>&1; then
  echo "Install Homebrew from https://brew.sh/ and rerun this script." >&2
  exit 1
fi

brew install git python@3.12
mkdir -p "$ai_dir"

if [[ ! -d "$comfy_dir/.git" ]]; then
  git clone https://github.com/Comfy-Org/ComfyUI.git "$comfy_dir"
  git -C "$comfy_dir" checkout --detach "$comfy_ref"
else
  echo "Using existing ComfyUI checkout at $comfy_dir"
fi

if [[ ! -x "$comfy_dir/.venv/bin/python" ]]; then
  "$(brew --prefix python@3.12)/bin/python3.12" -m venv "$comfy_dir/.venv"
fi

"$comfy_dir/.venv/bin/python" -m pip install --upgrade pip setuptools wheel
"$comfy_dir/.venv/bin/python" -m pip install 'torch==2.14.1' 'torchvision==0.29.1' 'torchaudio==2.11.0'
"$comfy_dir/.venv/bin/python" -m pip install -r "$comfy_dir/requirements.txt"

workflow_dir="$comfy_dir/user/default/workflows"
mkdir -p "$workflow_dir"
for workflow in "$repo_dir"/workflows/*.json; do
  target="$workflow_dir/${workflow:t}"
  if [[ ! -e "$target" ]]; then
    cp "$workflow" "$target"
  else
    echo "Kept existing workflow: $target"
  fi
done

launcher="$ai_dir/start-comfyui.command"
if [[ ! -e "$launcher" ]]; then
  cp "$repo_dir/start-comfyui.command" "$launcher"
  chmod +x "$launcher"
else
  echo "Kept existing launcher: $launcher"
fi

"$comfy_dir/.venv/bin/python" - <<'PY'
import torch
print("PyTorch:", torch.__version__)
print("MPS available:", torch.backends.mps.is_available())
if not torch.backends.mps.is_available():
    raise SystemExit("MPS is unavailable on this installation")
print("MPS tensor:", torch.ones(1, device="mps"))
PY

"$repo_dir/scripts/download-models.sh"
echo "Ready. Run: $repo_dir/start-comfyui.command"
