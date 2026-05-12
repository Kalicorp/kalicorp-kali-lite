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
echo "  ╔════════════════════════════════════════════════════════════╗"
echo "  ║   Kalicorp — Kali-Lite V2 (qwen3.5:9b + Vision)           ║"
echo "  ║   GPL-2.0  ·  Zero cloud  ·  Zero tracking                ║"
echo "  ║   Linux + macOS (Intel/Apple Silicon)                     ║"
echo "  ╚════════════════════════════════════════════════════════════╝"
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
    if nvidia-smi &>/dev/null; then\n        GPU=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null)
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
# LINUX-ONLY: Install qwen3.5:9b (V2 Model)\n# ═══════════════════════════════════════════════════════════════
install_linux() {\n    section "Linux Setup — Ollama via curl + qwen3.5:9b (V2 Vision)"\n\n    # ── 1. OLLAMA ──\n    section "1/6 — Ollama"\n    if command -v ollama &>/dev/null; then\n        ok "Ollama present: $(ollama --version 2>/dev/null)"\n    else\n        info "Installing Ollama..."\n        curl -fsSL https://ollama.com/install.sh | sh || err "Ollama installation failed"\n        ok "Ollama installed"\n    fi\n\n    # ── 2. DAEMON OLLAMA ──\n    section "2/6 — Ollama Daemon"\n    OLLAMA_LOG=\"/var/log/kalicorp/ollama.log"\n    OLLAMA_PID=\"/var/run/kalicorp-ollama.pid"\n    sudo mkdir -p /var/log/kalicorp\n\n    if command -v systemctl &>/dev/null && systemctl list-unit-files ollama.service &>/dev/null 2>&1; then\n        sudo systemctl enable ollama 2>/dev/null || warn "systemd enable failed"\n        sudo systemctl start ollama 2>/dev/null || warn "systemd start failed"\n        sleep 2\n        if sudo systemctl is-active --quiet ollama; then\n            ok "Ollama active via systemd (persistent across reboots)"\n        else\n            warn "systemd inactive — starting manually..."\n            sudo nohup ollama serve > "$OLLAMA_LOG" 2>&1 &\n            echo $! | sudo tee "$OLLAMA_PID" > /dev/null\n            ok "Daemon started (PID: $!, log: $OLLAMA_LOG)"\n            sleep 3\n        fi\n    else\n        if pgrep -x ollama &>/dev/null; then\n            ok "Ollama daemon already active (PID: $(pgrep -x ollama))"\n        else\n            info "Starting Ollama daemon manually..."\n            nohup ollama serve > "$OLLAMA_LOG" 2>&1 &\n            echo $! > "$OLLAMA_PID"\n            ok "Daemon started (PID: $!, log: $OLLAMA_LOG)"\n            sleep 3\n        fi\n    fi\n\n    # ── API Wait ──\n    info "Waiting for Ollama API (localhost:11434)..."\n    for i in {1..20}; do\n        curl -sf http://localhost:11434/api/tags &>/dev/null && { ok "API available (${i}s)"; break; }\n        sleep 1\n        [[ $i -eq 20 ]] && warn "API not available after 20s — check logs"\n    done\n\n    # ── 3. qwen3.5:9b (V2 VISION) ──\n    section "3/6 — Model qwen3.5:9b (~6.5 GB) [V2 - Vision Capable]"\n    if ollama list 2>/dev/null | grep -q "^qwen3.5.*9b"; then\n        ok "qwen3.5:9b already present"\n    else\n        info "Downloading qwen3.5:9b (may take several minutes)..."\n        ollama pull qwen3.5:9b || err "qwen3.5:9b download failed"\n        ok "qwen3.5:9b downloaded"\n    fi\n\n    # ── 4. Node.js + npm ──\n    info "Checking Node.js..."\n    if ! command -v npm &>/dev/null; then\n        info "npm not found — installing Node.js LTS..."\n        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -\n        sudo apt-get install -y nodejs\n    fi\n}\n\n# ═══════════════════════════════════════════════════════════════\n# MACOS-ONLY: Install qwen3.5:9b (V2 Model)\n# ═══════════════════════════════════════════════════════════════\ninstall_macos() {\n    section "macOS Setup — Ollama via Homebrew + qwen3.5:9b (V2 Vision)"\n\n    # ── Check Homebrew ──\n    if ! command -v brew &>/dev/null; then\n        err "Homebrew not found. Install from https://brew.sh and retry."\n    fi\n    ok "Homebrew present: $(brew --version | head -1)"\n\n    # ── 1. OLLAMA ──\n    section "1/6 — Ollama"\n    if command -v ollama &>/dev/null; then\n        ok "Ollama present: $(ollama --version 2>/dev/null)"\n    else\n        info "Installing Ollama via Homebrew..."\n        brew install ollama || err "Ollama installation failed"\n        ok "Ollama installed"\n    fi\n\n    # ── 2. DAEMON OLLAMA ──\n    section "2/6 — Ollama Daemon"\n    OLLAMA_LOG=\"${REAL_HOME}/Library/Logs/kalicorp/ollama.log"\n    OLLAMA_PID=\"${REAL_HOME}/Library/kalicorp/ollama.pid"\n    mkdir -p "${REAL_HOME}/Library/Logs/kalicorp" "${REAL_HOME}/Library/kalicorp"\n\n    if brew services list 2>/dev/null | grep -q ollama; then\n        info "Enabling Ollama via brew services..."\n        brew services start ollama 2>/dev/null || warn "brew services start failed"\n        sleep 2\n        if brew services list 2>/dev/null | grep -q 'ollama.*started'; then\n            ok "Ollama active via brew services"\n        else\n            warn "brew services inactive — starting manually..."\n            nohup ollama serve > "$OLLAMA_LOG" 2>&1 &\n            echo $! > "$OLLAMA_PID"\n            ok "Daemon started (PID: $!, log: $OLLAMA_LOG)"\n            sleep 3\n        fi\n    else\n        if pgrep -x ollama &>/dev/null; then\n            ok "Ollama daemon already active (PID: $(pgrep -x ollama))"\n        else\n            info "Starting Ollama daemon manually..."\n            nohup ollama serve > "$OLLAMA_LOG" 2>&1 &\n            echo $! > "$OLLAMA_PID"\n            ok "Daemon started (PID: $!, log: $OLLAMA_LOG)"\n            sleep 3\n        fi\n    fi\n\n    # ── API Wait ──\n    info "Waiting for Ollama API (localhost:11434)..."\n    for i in {1..20}; do\n        curl -sf http://localhost:11434/api/tags &>/dev/null && { ok "API available (${i}s)"; break; }\n        sleep 1\n        [[ $i -eq 20 ]] && warn "API not available after 20s — check logs"\n    done\n\n    # ── 3. qwen3.5:9b (V2 VISION) ──\n    section "3/6 — Model qwen3.5:9b (~6.5 GB) [V2 - Vision Capable]"\n    if ollama list 2>/dev/null | grep -q "^qwen3.5.*9b"; then\n        ok "qwen3.5:9b already present"\n    else\n        info "Downloading qwen3.5:9b (may take several minutes)..."\n        ollama pull qwen3.5:9b || err "qwen3.5:9b download failed"\n        ok "qwen3.5:9b downloaded"\n    fi\n\n    # ── 4. Node.js + npm ──\n    info "Checking Node.js..."\n    if ! command -v npm &>/dev/null; then\n        info "npm not found — installing Node.js via Homebrew..."\n        brew install node\n    fi\n}\n\n# ═══════════════════════════════════════════════════════════════\n# SHARED: Setup + finalize\n# ═══════════════════════════════════════════════════════════════\nif [[ $IS_LINUX -eq 1 ]]; then\n    install_linux\nelse\n    install_macos\nfi\n\nok "V2 (qwen3.5:9b + Vision) setup complete!"\nok "Run: ollama list | grep qwen3.5"\nok "Start with: ollama run qwen3.5:9b\"\n