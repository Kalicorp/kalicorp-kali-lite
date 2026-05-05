# kalicorp-hardening model anima : kali-lite v1

Anima Kalicorp — installation locale en 1 clic.

Assistant IA souverain, zéro cloud, zéro dépendance externe.

## Architecture

- **Moteur** : qwen3:8b via Ollama
- **Interface** : Claude Code v2+ — proxy Ollama local
- **Identité** : gravée dans un Modelfile + CLAUDE.md
- **Données** : sur site uniquement — aucune extraction

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/balduregates1/kalicorp-hardening/main/install.sh | sh
```

~20 min. 8 Go VRAM minimum.

## Configurations

| Config | GPU VRAM | RAM | CPU | OS |
|---|---|---|---|---|
| Minimale | 8 Go | 16 Go | 6 cœurs | Ubuntu 22.04+ |
| Recommandée | 8 Go+ | 32 Go | 8 cœurs+ | Kali / Debian |
| Testée | 8 Go RTX 3080 | 64 Go | i7-10750H 6c/12t | Kali Linux 6.19 |

## Ce qu'elle fait bien

- Chat direct instantané — < 2s par réponse
- Bash guide — diagnostic, audit, maintenance système
- Code Python, Bash, YAML, configs système
- WebFetch — récupération et analyse de pages web
- Mémoire persistante entre sessions via CLAUDE.md

## Compensations cloud

Kalicorp DevCore 35B réalise 92% des tâches en autonomie.
Inference Kalicorp Le Sanctuaire — DL580 Gen9 4x Xeon E7-8867 V4 72 cœurs / 144 threads.
Infrastructure : 512 Go RAM + multi GPU — souverain on-premise.

## Licence

GPL-2.0 — redistribution autorisée.

## Cadre

conçu pour faciliter la conformité RGPD / AI Act
---

Kalicorp | Le Sanctuaire, Sissonne | 2026 | app.kalicorp.fr
