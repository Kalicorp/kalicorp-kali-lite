# Kali-Lite V1 — Installation Guide

Cross-platform installer for **Kali-Lite**, a sovereign, local-first AI assistant powered by Qwen 8B via Ollama.

## Quick Start

### Linux (Kali, Debian, Ubuntu, Arch)
```bash
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/install.sh
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/SHA256SUMS
sha256sum --check SHA256SUMS --ignore-missing
bash install.sh --dry-run
sudo bash install.sh
```

### macOS (Intel / Apple Silicon)
```bash
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/install.sh
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/SHA256SUMS
grep ' install.sh$' SHA256SUMS | shasum -a 256 -c -
bash install.sh --dry-run
bash install.sh
```

**Note:** macOS does **not** require `sudo` — Homebrew refuses to run as root.

---

## Prerequisites

### Linux

- **OS** : Kali Linux, Debian, Ubuntu, or Arch
- **Root/sudo** : Required for system-wide installation
- **Dependencies** : `curl` (pre-installed on most)
- **RAM** : 8–10 GB recommended (8 GB possible with constraints)
- **GPU** : Optional (NVIDIA with CUDA for acceleration; CPU mode works)

**Installation time** : ~15–20 minutes (most time spent downloading qwen3:8b model)

### macOS

- **OS** : macOS 11.0+ (Intel or Apple Silicon)
- **Homebrew** : Must be pre-installed ([install here](https://brew.sh))
- **Xcode Command Line Tools** : Required
  ```bash
  xcode-select --install
  ```
- **Dependencies** : `curl` (included in macOS), Node.js, Ollama via Homebrew
- **RAM** : 10+ GB for Apple Silicon; Intel Macs should have 12+ GB
- **GPU** : Apple Silicon / AMD / Intel iGPU detected automatically

**Installation time** : ~20–25 minutes

---

## What Gets Installed

### All Platforms

1. **Ollama** — Local LLM runtime
   - Linux: installateur officiel téléchargé dans un fichier temporaire avant exécution
   - macOS: Homebrew package + optional `brew services`

2. **qwen3:8b** — Base model (~5.2 GB download)
   - Quantized 8B parameter model
   - Fine-tuned system prompt for Kali-Lite identity

3. **Kali-Lite Custom Model** — Ollama custom model
   - Built from qwen3:8b + custom SYSTEM prompt + TEMPLATE
   - Injected identity, infrastructure context, operational scope
   - Located at : `/etc/kalicorp/Modelfile.kali-lite` (Linux) or `~/.kalicorp/Modelfile.kali-lite` (macOS)


5. **Shell Alias** — Quick access
   ```bash
   alias kali-lite='ollama run kali-lite'
   ```
   Injected into `~/.bashrc` or `~/.zshrc`

### Paths

| Artifact | Linux | macOS |
|---|---|---|
| Modelfile | `/etc/kalicorp/Modelfile.kali-lite` | `~/.kalicorp/Modelfile.kali-lite` |
| Ollama logs | `/var/log/kalicorp/ollama.log` | `~/Library/Logs/kalicorp/ollama.log` |
| Ollama PID | `/var/run/kalicorp-ollama.pid` | `~/Library/kalicorp/ollama.pid` |
| Shell RC | `~/.bashrc` or `~/.zshrc` | `~/.zshrc` (preferred) or `~/.bashrc` |

---

## Usage

### After Installation

1. **Reload your shell**
   ```bash
   source ~/.bashrc    # or ~/.zshrc
   ```

2. **Start Kali-Lite**
   ```bash
   kali-lite
   ```
   This launches the kali-lite model via Ollama locally.

2. **Ollama directement**
   ```bash
   ollama run kali-lite
   ```

### Typical Workflow

```bash
$ kali-lite
> Qui es-tu ?
Kali-Lite, Anima Kalicorp, nœud MSI Field.

> Comment configurer un reverse proxy avec nginx ?
[responds with local sovereign context, no cloud extraction]
```

---

## Troubleshooting

### Common Issues

#### 1. "Ollama API not available after 20s"

**Linux**
```bash
sudo systemctl status ollama
sudo journalctl -u ollama -n 50
```

**macOS**
```bash
brew services list | grep ollama
tail -f ~/Library/Logs/kalicorp/ollama.log
```

**Solution** : If Ollama fails to start:
- Check disk space: `df -h`
- Restart manually:
  ```bash
  # Linux
  sudo systemctl restart ollama

  # macOS
  brew services restart ollama
  # or
  pkill ollama && sleep 2 && ollama serve > ~/Library/Logs/kalicorp/ollama.log 2>&1 &
  ```

```

#### 3. "Permission denied" on Linux

The installer requires `sudo`. Did you run with `sudo`?

```bash
sudo bash <(curl -fsSL ...)
```

#### 4. macOS: "Homebrew is not installed"

Install Homebrew first:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 5. GPU not detected

- **Linux (NVIDIA)** : Ensure NVIDIA drivers and CUDA toolkit are installed
  ```bash
  nvidia-smi
  ```
- **macOS (Apple Silicon)** : Automatic; no action needed. Ollama uses Metal acceleration by default.
- **Fallback** : Both platforms will run in CPU mode if GPU is unavailable (slower but works)

---

## Updating the Modelfile

The Kali-Lite system prompt and behavior are defined in the **Modelfile**. To customize:

### 1. Edit the Modelfile

**Linux** :
```bash
sudo nano /etc/kalicorp/Modelfile.kali-lite
```

**macOS** :
```bash
nano ~/.kalicorp/Modelfile.kali-lite
```

### 2. Modify the SYSTEM section

Example — change the interlocutor:
```
SYSTEM """
Tu es Kali-Lite, Anima Kalicorp. ...
- Interlocuteur principal : Alice Dupont (instead of Thibaut)
...
"""
```

### 3. Rebuild the model

```bash
ollama create kali-lite -f /etc/kalicorp/Modelfile.kali-lite  # Linux
# or
ollama create kali-lite -f ~/.kalicorp/Modelfile.kali-lite   # macOS
```

### 4. Test

```bash
ollama run kali-lite
```

---

## Maintaining Kali-Lite

### Check Status

```bash
# Ollama daemon
ollama list

/* Model status */

# API health
curl http://localhost:11434/api/tags
```

### Uninstall (Linux only)

```bash
sudo systemctl stop ollama
sudo systemctl disable ollama
sudo apt-get remove ollama
sudo rm -rf /etc/kalicorp /var/log/kalicorp
ollama rm kali-lite
```

---

## Architecture

```
┌─────────────────────────────────────┐
│   User Shell (bash/zsh)             │
│   $ kali-lite                       │
└────────────────┬────────────────────┘
                 │
                 ▼
        ┌────────────────────┐
        │  Claude Code CLI   │ (v2.1.138)
        │  (npm global)      │
        └────────────┬───────┘
                     │
        ┌────────────▼─────────────────┐
        │  ANTHROPIC_BASE_URL=         │
        │  http://localhost:11434      │
        │  ANTHROPIC_API_KEY=ollama    │
        └────────────┬─────────────────┘
                     │
        ┌────────────▼──────────────────┐
        │    Ollama API Server          │
        │    (localhost:11434)          │
        └────────────┬──────────────────┘
                     │
        ┌────────────▼──────────────────┐
        │  kali-lite:latest             │
        │  (Custom Ollama model)        │
        │  FROM qwen3:8b                │
        │  + Custom SYSTEM + TEMPLATE   │
        └────────────┬──────────────────┘
                     │
        ┌────────────▼──────────────────┐
        │    qwen3:8b                   │
        │    (Base LLM, 5.2 GB)         │
        └────────────────────────────────┘
```

**Key Principle** : l’inférence est locale. L’installation nécessite un accès
réseau pour télécharger Ollama, les dépendances choisies et les poids du
modèle. Kali-Lite n’ajoute aucune télémétrie, mais les dépendances conservent
leurs propres politiques et doivent être auditées séparément.

---

## Support & Contributing

- **Issues** : Report bugs on GitHub
- **Custom Models** : Edit Modelfile and rebuild
- **Feedback** : Direct to Thibaut Neihouser (Kalicorp)

---

## License

GPL-2.0 — See LICENSE in repo.

---

## Changelog

### v1.0.0 (2026-05-09)
- Initial release
- Cross-platform support (Linux/macOS)
- Modelfile with Kali-Lite identity
- Claude Code integration
- Fully local (zero cloud)
