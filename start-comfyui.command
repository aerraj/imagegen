#!/bin/zsh
set -euo pipefail

ai_dir=${AI_DIR:-$HOME/AI}
cd "$ai_dir/ComfyUI"
source .venv/bin/activate
exec python main.py --listen 127.0.0.1 --offline
