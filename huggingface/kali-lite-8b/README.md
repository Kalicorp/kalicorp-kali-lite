---
language:
- fr
- en
license: other
license_name: Mixed - GPL-2.0-only Kalicorp artifacts / Apache-2.0 upstream model
tags:
- qwen3
- ollama
- local
- sovereign-ai
- french
- kalicorp
pipeline_tag: text-generation
base_model:
- Qwen/Qwen3-8B
---

# Kali-Lite 8B

**Local, frugal and inspectable Anima configuration by Kalicorp.**

Kali-Lite 8B is **not a foundation model trained from scratch by Kalicorp**. It combines the upstream `Qwen/Qwen3-8B` model with a Kalicorp system doctrine, Ollama configuration and an execution harness designed for local operation.

## Provenance

| Property | Value |
|---|---|
| Upstream base model | `Qwen/Qwen3-8B` |
| Kalicorp customization | System prompt, doctrine, Modelfile, harness |
| Primary runtime | Ollama |
| Vision | No |
| Configured context | 16,384 tokens |
| Typical local artifact size | about 5.2 GB depending on quantization/runtime |

The upstream Qwen3-8B repository is Apache-2.0 licensed. Kalicorp-authored repository material follows the licensing terms of the Kali-Lite project. See the licensing notice before redistributing weights.

## Design principles

Kali-Lite is configured to:

- distinguish facts, hypotheses, proposed actions and observed results;
- never claim that a command/tool was executed without evidence from the harness;
- avoid inventing system state;
- keep the operator in control of privileged or destructive actions;
- perform inference locally when deployed with a local Ollama runtime;
- add no Kalicorp telemetry to local inference.

## Ollama Modelfile

The exact release configuration is provided in `Modelfile`.

```bash
ollama pull qwen3:8b
ollama create kali-lite -f Modelfile
ollama run kali-lite
```

## What is and is not included

This release package documents the Kalicorp configuration. A Hugging Face repository may be published without redistributing upstream weights. If weights/GGUF files are later added, their exact provenance, quantization and checksum must be documented.

## Limitations

Kali-Lite inherits the limitations of its base model and runtime. Small local models can produce plausible but incorrect information, lose constraints in long contexts and make tool-use mistakes. A configured context length is not a guarantee that all information in that context will be used correctly.

Local inference is not automatic compliance with GDPR, the EU AI Act, ANSSI guidance or any certification framework.

## Project

Source and security documentation: `Kalicorp/kalicorp-kali-lite` on GitHub.

**Kalicorp — Le Sanctuaire numérique européen**
