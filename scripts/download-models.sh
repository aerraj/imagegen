#!/bin/zsh
set -euo pipefail

ai_dir=${AI_DIR:-$HOME/AI}
models_dir="$ai_dir/ComfyUI/models"

download_one() {
  local relpath="$1" url="$2" expected_size="$3" expected_sha="$4"
  local target="$models_dir/$relpath"
  mkdir -p "${target:h}"

  if [[ -f "$target" ]]; then
    local current_size
    current_size=$(stat -f %z "$target")
    if (( current_size > expected_size )); then
      echo "File is larger than expected: $target" >&2
      return 1
    fi
    if (( current_size == expected_size )); then
      local current_sha
      current_sha=$(shasum -a 256 "$target" | awk '{print $1}')
      if [[ "$current_sha" == "$expected_sha" ]]; then
        echo "Already verified: $target"
        return
      fi
      echo "Existing file has the wrong checksum: $target" >&2
      return 1
    fi
  fi

  echo "Downloading $relpath"
  curl --http1.1 --location --fail --retry 10 --retry-all-errors \
    --continue-at - --output "$target" "$url"

  [[ $(stat -f %z "$target") == "$expected_size" ]] || {
    echo "Incomplete download: $target" >&2
    return 1
  }
  local actual_sha
  actual_sha=$(shasum -a 256 "$target" | awk '{print $1}')
  [[ "$actual_sha" == "$expected_sha" ]] || {
    echo "Checksum mismatch: $target" >&2
    return 1
  }
  echo "Verified: $target"
}

download_one text_encoders/qwen_3_4b.safetensors \
  'https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors' \
  8044982048 6c671498573ac2f7a5501502ccce8d2b08ea6ca2f661c458e708f36b36edfc5a
download_one diffusion_models/z_image_turbo_bf16.safetensors \
  'https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors' \
  12309866400 2407613050b809ffdff18a4ac99af83ea6b95443ecebdf80e064a79c825574a6
download_one vae/ae.safetensors \
  'https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors' \
  335304388 afc8e28272cd15db3919bacdb6918ce9c1ed22e96cb12c4d5ed0fba823529e38
