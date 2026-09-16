# Hugging Face release package

This directory contains publication-ready material for the Kali-Lite family.

## Target repositories

- `Kalicorp/Kali-Lite-8B`
- `Kalicorp/Kali-Lite-Vision-9B`

Kali-Lite is documented as a **Kalicorp Anima configuration built on an upstream Qwen model**, not as a foundation model trained from scratch by Kalicorp.

| Variant | Upstream base | Kalicorp layer | Configured context |
|---|---|---|---:|
| Kali-Lite 8B | `Qwen/Qwen3-8B` | doctrine + system prompt + Ollama Modelfile + harness | 16,384 |
| Kali-Lite Vision 9B | `Qwen/Qwen3.5-9B` | doctrine + system prompt + Ollama Modelfile + harness | 32,768 |

Recommended first release: publish the model cards and configuration files first. Redistribute model/GGUF weights only after verifying the exact source artifact, checksum, quantization provenance and applicable upstream license.

See `LICENSE-NOTICE.md` before publication.
