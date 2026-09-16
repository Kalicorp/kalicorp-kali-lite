# Licensing and provenance notice

The Kali-Lite project combines independently licensed components.

## Kalicorp-authored material

Kalicorp-authored code, documentation, prompts and configuration in the main `Kalicorp/kalicorp-kali-lite` repository are distributed under the license stated by that repository: **GPL-2.0-only**, unless a file states otherwise.

## Upstream base models

- `Qwen/Qwen3-8B` — Apache-2.0 upstream model repository.
- `Qwen/Qwen3.5-9B` — Apache-2.0 upstream model repository.

The upstream model authors retain their rights and attribution. Kali-Lite does not claim that Kalicorp trained these foundation-model weights from scratch.

## Weight redistribution

This Hugging Face preparation directory does **not** by itself authorize uploading an arbitrary local GGUF or other model file. Before redistributing weights, verify:

1. the exact upstream source;
2. the quantizer/converter and quantization method;
3. the artifact SHA-256;
4. the upstream license and notices;
5. that no private data, credentials or unrelated model artifacts are embedded.

When provenance is uncertain, publish configuration only and let users obtain the base model from its official source.
