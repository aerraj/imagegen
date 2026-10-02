# imagegen

Local text-to-image generation on Apple Silicon with ComfyUI and Z-Image Turbo. Tested on an M5 Mac with 16 GB unified memory at 1024 × 1024.

## Start

Install [Homebrew](https://brew.sh/) if needed. Then run:

```sh
git clone https://github.com/aerraj/imagegen.git
cd imagegen
./setup.sh
./start-comfyui.command
```

`setup.sh` installs ComfyUI and downloads the three model weights (about 20.7 GB total). It verifies each download. When ComfyUI starts, open [127.0.0.1:8188](http://127.0.0.1:8188/) in a browser, open **Workflows → Z-Image Turbo Ferrari**, and click **Run**. The default prompt makes a red Ferrari. Edit the positive prompt to make something else. Images appear in `~/AI/ComfyUI/output/`. Press **Control-C** in Terminal to stop.

## Flow and maths

1. **Qwen3 4B text encoder** (`qwen_3_4b.safetensors`) turns the prompt into conditioning vectors: `c = E(prompt)`.
2. **Z-Image Turbo BF16** (`z_image_turbo_bf16.safetensors`) starts from random latent noise `z₀ ~ N(0, I)`. Its flow model predicts a velocity `vθ(z, t, c)`. The sampler follows that field across eight steps, schematically `zₖ₊₁ ≈ zₖ + Δtₖ vθ(zₖ, tₖ, c)`. The workflow uses AuraFlow sampling, `res_multistep`, and CFG 1.
3. **Autoencoder decoder** (`ae.safetensors`) turns the final latent into pixels: `image = D(z_final)`.

The workflow saves a 1024 × 1024 PNG. Models stay in `~/AI/ComfyUI/models/`; no weights are stored in this repository.
