---
language:
- fr
- en
license: other
license_name: mixed-gpl-2.0-only-apache-2.0
tags:
- qwen3.5
- vision
- multimodal
- ollama
- local
- sovereign-ai
- kalicorp
pipeline_tag: image-text-to-text
base_model:
- Qwen/Qwen3.5-9B
---

# Kali-Lite Vision 9B

**Local multimodal Anima configuration by Kalicorp.**

Kali-Lite Vision 9B is **not a foundation model trained from scratch by Kalicorp**. It combines the upstream `Qwen/Qwen3.5-9B` model with a Kalicorp system doctrine, Ollama configuration and local execution harness.

## Provenance

| Property | Value |
|---|---|
| Upstream base model | `Qwen/Qwen3.5-9B` |
| Kalicorp customization | System prompt, doctrine, Modelfile, harness |
| Primary runtime | Ollama |
| Vision | Yes |
| Configured context | 32,768 tokens |
| Typical local artifact size | about 6.8 GB depending on quantization/runtime |

The upstream Qwen3.5-9B repository is Apache-2.0 licensed. Kalicorp-authored repository material follows the licensing terms of the Kali-Lite project. See the licensing notice before redistributing weights.

## Design principles

The configuration favors evidence over assertion, explicit limits, local control and clear separation between reasoning and actual tool execution.

## Ollama Modelfile

```bash
ollama pull qwen3.5:9b
ollama create kali-lite-v2 -f Modelfile
ollama run kali-lite-v2
```

The exact release configuration is provided in `Modelfile`.

## What is and is not included

This release package can be published as configuration and documentation without copying upstream weights. If a GGUF/model artifact is later added, document its exact source, quantization method and SHA-256.

## Limitations

Multimodal output is probabilistic and can be wrong. Tool availability depends on the execution harness and permissions. A 32k configured context does not guarantee reliable use of every token. Local execution does not automatically establish GDPR, EU AI Act, ANSSI or ISO compliance.

## Project

Source and security documentation: `Kalicorp/kalicorp-kali-lite` on GitHub.

**Kalicorp — Le Sanctuaire numérique européen**
