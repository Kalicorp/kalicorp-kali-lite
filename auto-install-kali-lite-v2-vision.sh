#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  auto-install-kali-lite-v2-vision.sh
#  Kalicorp · Kali-Lite V2 (qwen3.5:9b + Vision) — Cross-Platform Autoinstaller
#  GPL-2.0 | Kalicorp | Le Sanctuaire | 2026
#
#  Stack : Ollama · qwen3.5:9b · Modelfile Kali-Lite · Claude Code
#  Features : Vision (image analysis), 9B context window
#  Supported : Linux (Debian/Ubuntu/Kali/Arch) + macOS (Intel/Apple Silicon)
#
#  Usage :
#    Linux  : sudo bash <(curl -fsSL https://...auto-install-kali-lite-v2-vision.sh)
#    macOS  : bash <(curl -fsSL https://...auto-install-kali-lite-v2-vision.sh)  # NO sudo
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

# ── Couleurs ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

ok()      { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
err()     { echo -e "${RED}[✗]${NC} $*"; exit 1; }
info()    { echo -e "${CYAN}[→]${NC} $*"; }
section() { echo -e "\n${BLUE}${BOLD}[»] $*${NC}\n"; }

# ── Bannière ──────────────────────────────────────────────────
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║   Kalicorp — Kali-Lite V2 (qwen3.5:9b + Vision)           ║"
echo "  ║   GPL-2.0  ·  Zero cloud  ·  Zero tracking                ║"
echo "  ║   Linux + macOS (Intel/Apple Silicon)                     ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ═══════════════════════════════════════════════════════════════
# SHARED: Detect OS
# ═══════════════════════════════════════════════════════════════
section "Detecting OS..."
OS=$(uname -s)
case "$OS" in
  Linux)  info "Detected Linux"; IS_LINUX=1; IS_MACOS=0 ;;
  Darwin) info "Detected macOS"; IS_LINUX=0; IS_MACOS=1 ;;
  *)      err "Unsupported OS: $OS (Linux or macOS only)" ;;
esac

# ═══════════════════════════════════════════════════════════════
# SHARED: Prerequisites
# ═══════════════════════════════════════════════════════════════
section "0/6 — Prerequisites"

# ── LINUX-ONLY: sudo check ──
if [[ $IS_LINUX -eq 1 ]]; then
    [[ $EUID -ne 0 ]] && err "Linux requires sudo: sudo bash auto-install-kali-lite-v2-vision.sh"
fi

# ── MACOS-ONLY: warn about sudo ──
if [[ $IS_MACOS -eq 1 ]]; then
    if [[ $EUID -eq 0 ]]; then
        err "macOS: Do NOT run with sudo — Homebrew refuses root. Use: bash auto-install-kali-lite-v2-vision.sh"
    fi
fi

command -v curl &>/dev/null || err "curl required — install and retry"

# ── SHARED: User context ──
REAL_USER="${SUDO_USER:-${USER:-$(whoami)}}"
REAL_HOME=$(eval echo ~$REAL_USER)
SHELL_RC="${REAL_HOME}/.bashrc"
[[ "$SHELL" == *zsh* ]] && SHELL_RC="${REAL_HOME}/.zshrc"

info "User       : $REAL_USER"
info "Home       : $REAL_HOME"
info "Shell RC   : $SHELL_RC"

# ── SHARED: GPU Detection (OS-aware) ──
if [[ $IS_LINUX -eq 1 ]]; then
    if nvidia-smi &>/dev/null; then
        GPU=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null)
        ok "GPU: $GPU"
    else
        warn "GPU: nvidia-smi not found — will run in CPU mode"
    fi
fi

if [[ $IS_MACOS -eq 1 ]]; then
    if command -v system_profiler &>/dev/null; then
        GPU=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -i chipset | head -1 | sed 's/.*Chipset Model: //' || echo "Not detected")
        ok "GPU: $GPU"
    else
        warn "GPU: system_profiler not available"
    fi
fi

# ── SHARED: Personal Claude config detection ──
PERSO_KEY=""
PERSO_FOUND=0
if [[ -f "$SHELL_RC" ]]; then
    PERSO_KEY=$(grep -E "^export ANTHROPIC_API_KEY=" "$SHELL_RC" 2>/dev/null | grep -v '=ollama' | head -1 | sed 's/^export ANTHROPIC_API_KEY=//' | tr -d '"' || true)
fi
if [[ -n "$PERSO_KEY" ]]; then
    PERSO_FOUND=1
    warn "Personal Claude config detected — will preserve"
else
    ok "No personal Claude config — clean install"
fi

# ═══════════════════════════════════════════════════════════════
# SHARED: GPU info for summary
# ═══════════════════════════════════════════════════════════════
get_gpu_info() {
    if [[ $IS_LINUX -eq 1 ]]; then
        nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "N/A (CPU mode)"
    elif [[ $IS_MACOS -eq 1 ]]; then
        system_profiler SPDisplaysDataType 2>/dev/null | grep -i chipset | head -1 | sed 's/.*Chipset Model: //' || echo "N/A"
    fi
}

# ═══════════════════════════════════════════════════════════════
# LINUX-ONLY: Install qwen3.5:9b (V2 Model)
# ═══════════════════════════════════════════════════════════════
install_linux() {
    section "Linux Setup — Ollama via curl + qwen3.5:9b (V2 Vision)"

    # ── 1. OLLAMA ──
    section "1/6 — Ollama"
    if command -v ollama &>/dev/null; then
        ok "Ollama present: $(ollama --version 2>/dev/null)"
    else
        info "Installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh || err "Ollama installation failed"
        ok "Ollama installed"
    fi

    # ── 2. DAEMON OLLAMA ──
    section "2/6 — Ollama Daemon"
    OLLAMA_LOG="/var/log/kalicorp/ollama.log"
    OLLAMA_PID="/var/run/kalicorp-ollama.pid"
    sudo mkdir -p /var/log/kalicorp

    if command -v systemctl &>/dev/null && systemctl list-unit-files ollama.service &>/dev/null 2>&1; then
        sudo systemctl enable ollama 2>/dev/null || warn "systemd enable failed"
        sudo systemctl start ollama 2>/dev/null || warn "systemd start failed"
        sleep 2
        if sudo systemctl is-active --quiet ollama; then
            ok "Ollama active via systemd (persistent across reboots)"
        else
            warn "systemd inactive — starting manually..."
            sudo nohup ollama serve > "$OLLAMA_LOG" 2>&1 &
            echo $! | sudo tee "$OLLAMA_PID" > /dev/null
            ok "Daemon started (PID: $!, log: $OLLAMA_LOG)"
            sleep 3
        fi
    else
        if pgrep -x ollama &>/dev/null; then
            ok "Ollama daemon already active (PID: $(pgrep -x ollama))"
        else
            info "Starting Ollama daemon manually..."
            nohup ollama serve > "$OLLAMA_LOG" 2>&1 &
            echo $! > "$OLLAMA_PID"
            ok "Daemon started (PID: $!, log: $OLLAMA_LOG)"
            sleep 3
        fi
    fi

    # ── API Wait ──
    info "Waiting for Ollama API (localhost:11434)..."
    for i in {1..20}; do
        curl -sf http://localhost:11434/api/tags &>/dev/null && { ok "API available (${i}s)"; break; }
        sleep 1
        [[ $i -eq 20 ]] && warn "API not available after 20s — check logs"
    done

    # ── 3. qwen3.5:9b (V2 VISION) ──
    section "3/6 — Model qwen3.5:9b (~6.5 GB) [V2 - Vision Capable]"
    if ollama list 2>/dev/null | grep -q "^qwen3.5.*9b"; then
        ok "qwen3.5:9b already present"
    else
        info "Downloading qwen3.5:9b (may take several minutes)..."
        ollama pull qwen3.5:9b || err "qwen3.5:9b download failed"
        ok "qwen3.5:9b downloaded"
    fi

    # ── 4. Kali-Lite v2 custom model via Modelfile ──
    section "4/6 — Kali-Lite v2 custom model (Modelfile)"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    MODELFILE_PATH="${SCRIPT_DIR}/Modelfile"
    if [[ -f "$MODELFILE_PATH" ]]; then
        info "Building Kali-Lite v2 from Modelfile..."
        ollama create kali-lite-v2 "$MODELFILE_PATH" || warn "Modelfile build failed — using base qwen3.5:9b"
        ok "kali-lite-v2 model built from Modelfile"
    else
        warn "Modelfile not found at $MODELFILE_PATH — skipping custom model build"
    fi

    # ── 5. Node.js + npm ──
    info "Checking Node.js..."
    if ! command -v npm &>/dev/null; then
        info "npm not found — installing Node.js LTS..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
        sudo apt-get install -y nodejs
    fi
}

# ═══════════════════════════════════════════════════════════════
# MACOS-ONLY: Install qwen3.5:9b (V2 Model)
# ═══════════════════════════════════════════════════════════════
install_macos() {
    section "macOS Setup — Ollama via Homebrew + qwen3.5:9b (V2 Vision)"

    # ── Check Homebrew ──
    if ! command -v brew &>/dev/null; then
        err "Homebrew not found. Install from https://brew.sh and retry."
    fi
    ok "Homebrew present: $(brew --version | head -1)"

    # ── 1. OLLAMA ──
    section "1/6 — Ollama"
    if command -v ollama &>/dev/null; then
        ok "Ollama present: $(ollama --version 2>/dev/null)"
    else
        info "Installing Ollama via Homebrew..."
        brew install ollama || err "Ollama installation failed"
        ok "Ollama installed"
    fi

    # ── 2. DAEMON OLLAMA ──
    section "2/6 — Ollama Daemon"
    OLLAMA_LOG="${REAL_HOME}/Library/Logs/kalicorp/ollama.log"
    OLLAMA_PID="${REAL_HOME}/Library/kalicorp/ollama.pid"
    mkdir -p "${REAL_HOME}/Library/Logs/kalicorp" "${REAL_HOME}/Library/kalicorp"

    if brew services list 2>/dev/null | grep -q ollama; then
        info "Enabling Ollama via brew services..."
        brew services start ollama 2>/dev/null || warn "brew services start failed"
        sleep 2
        if brew services list 2>/dev/null | grep -q 'ollama.*started'; then
            ok "Ollama active via brew services"
        else
            warn "brew services inactive — starting manually..."
            nohup ollama serve > "$OLLAMA_LOG" 2>&1 &
            echo $! > "$OLLAMA_PID"
            ok "Daemon started (PID: $!, log: $OLLAMA_LOG)"
            sleep 3
        fi
    else
        if pgrep -x ollama &>/dev/null; then
            ok "Ollama daemon already active (PID: $(pgrep -x ollama))"
        else
            info "Starting Ollama daemon manually..."
            nohup ollama serve > "$OLLAMA_LOG" 2>&1 &
            echo $! > "$OLLAMA_PID"
            ok "Daemon started (PID: $!, log: $OLLAMA_LOG)"
            sleep 3
        fi
    fi

    # ── API Wait ──
    info "Waiting for Ollama API (localhost:11434)..."
    for i in {1..20}; do
        curl -sf http://localhost:11434/api/tags &>/dev/null && { ok "API available (${i}s)"; break; }
        sleep 1
        [[ $i -eq 20 ]] && warn "API not available after 20s — check logs"
    done

    # ── 3. qwen3.5:9b (V2 VISION) ──
    section "3/6 — Model qwen3.5:9b (~6.5 GB) [V2 - Vision Capable]"
    if ollama list 2>/dev/null | grep -q "^qwen3.5.*9b"; then
        ok "qwen3.5:9b already present"
    else
        info "Downloading qwen3.5:9b (may take several minutes)..."
        ollama pull qwen3.5:9b || err "qwen3.5:9b download failed"
        ok "qwen3.5:9b downloaded"
    fi

    # ── 4. Kali-Lite v2 custom model via Modelfile ──
    section "4/6 — Kali-Lite v2 custom model (Modelfile)"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    MODELFILE_PATH="${SCRIPT_DIR}/Modelfile"
    if [[ -f "$MODELFILE_PATH" ]]; then
        info "Building Kali-Lite v2 from Modelfile..."
        ollama create kali-lite-v2 "$MODELFILE_PATH" || warn "Modelfile build failed — using base qwen3.5:9b"
        ok "kali-lite-v2 model built from Modelfile"
    else
        warn "Modelfile not found at $MODELFILE_PATH — skipping custom model build"
    fi

    # ── 5. Node.js + npm ──
    info "Checking Node.js..."
    if ! command -v npm &>/dev/null; then
        info "npm not found — installing Node.js via Homebrew..."
        brew install node
    fi
}

# ═══════════════════════════════════════════════════════════════
# SHARED: Setup + finalize
# ═══════════════════════════════════════════════════════════════
if [[ $IS_LINUX -eq 1 ]]; then
    install_linux
else
    install_macos
fi

ok "V2 (qwen3.5:9b + Vision) setup complete!"
ok "Run: ollama list | grep qwen3.5"
ok "Start with: ollama run kali-lite-v2"
