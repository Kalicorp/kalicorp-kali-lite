#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# auto-install-kali-lite-v2-vision.sh
# Kalicorp · Kali-Lite V2 (qwen3.5:9b + Vision) — Cross-Platform Autoinstaller
# GPL-2.0 | Kalicorp | Le Sanctuaire | 2026
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ── Couleurs ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

ok()    { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
err()   { echo -e "${RED}[✗]${NC} $*"; exit 1; }
info()  { echo -e "${CYAN}[→]${NC} $*"; }
section() { echo -e "\n${BLUE}${BOLD}[»] $*${NC}\n"; }

# ── Bannière ──────────────────────────────────────────────────
echo -e "${BOLD}"
echo " ╔════════════════════════════════════════════════════════════╗"
echo " ║     Kalicorp — Kali-Lite V2 (qwen3.5:9b + Vision)         ║"
echo " ║          GPL-2.0 · Zero cloud · Zero tracking             ║"
echo " ║               Linux + macOS (Intel/Apple Silicon)          ║"
echo " ╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ═══════════════════════════════════════════════════════════════
# SHARED: Detect OS
# ═══════════════════════════════════════════════════════════════
section "Detecting OS..."
OS=$(uname -s)
case "$OS" in
    Linux)  info "Detected Linux"; IS_LINUX=1; IS_MACOS=0 ;;
    Darwin) info "Detected macOS"; IS_LINUX=0; IS_MACOS=1 ;;
    *)      err "Unsupported OS: $OS (only Linux or macOS supported)" ;;
esac

# ═══════════════════════════════════════════════════════════════
# SHARED: Prerequisites
# ═══════════════════════════════════════════════════════════════
section "0/6 — Prerequisites"

if [[ $IS_LINUX -eq 1 ]]; then
    [[ $EUID -ne 0 ]] && err "Linux requires sudo: sudo bash auto-install-kali-lite-v2-vision.sh"
fi

if [[ $IS_MACOS -eq 1 ]]; then
    [[ $EUID -eq 0 ]] && err "macOS: Do NOT run with sudo. Use: bash auto-install-kali-lite-v2-vision.sh"
fi

command -v curl &>/dev/null || err "curl is required"

REAL_USER="${SUDO_USER:-${USER:-$(whoami)}}"
REAL_HOME=$(eval echo ~$REAL_USER)
info "User : $REAL_USER"
info "Home : $REAL_HOME"

# ═══════════════════════════════════════════════════════════════
# LINUX INSTALL FUNCTION
# ═══════════════════════════════════════════════════════════════
install_linux() {
    section "Linux Setup — Ollama + qwen3.5:9b (Vision)"

    section "1/6 — Ollama"
    if command -v ollama &>/dev/null; then
        ok "Ollama already installed"
    else
        info "Installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh || err "Ollama installation failed"
        ok "Ollama installed"
    fi

    section "3/6 — Model qwen3.5:9b (Vision)"
    if ollama list 2>/dev/null | grep -q "qwen3.5:9b"; then
        ok "qwen3.5:9b already present"
    else
        info "Downloading qwen3.5:9b (this may take several minutes)..."
        ollama pull qwen3.5:9b || err "Model download failed"
        ok "qwen3.5:9b downloaded"
    fi
}

# ═══════════════════════════════════════════════════════════════
# MACOS INSTALL FUNCTION
# ═══════════════════════════════════════════════════════════════
install_macos() {
    section "macOS Setup — Ollama + qwen3.5:9b (Vision)"

    if ! command -v brew &>/dev/null; then
        err "Homebrew not found. Please install it from https://brew.sh"
    fi
    ok "Homebrew detected"

    section "1/6 — Ollama"
    if command -v ollama &>/dev/null; then
        ok "Ollama already installed"
    else
        info "Installing Ollama via Homebrew..."
        brew install ollama || err "Ollama installation failed"
        ok "Ollama installed"
    fi

    section "3/6 — Model qwen3.5:9b (Vision)"
    if ollama list 2>/dev/null | grep -q "qwen3.5:9b"; then
        ok "qwen3.5:9b already present"
    else
        info "Downloading qwen3.5:9b..."
        ollama pull qwen3.5:9b || err "Model download failed"
        ok "qwen3.5:9b downloaded"
    fi
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════
if [[ $IS_LINUX -eq 1 ]]; then
    install_linux
else
    install_macos
fi

ok "Kali-Lite V2 (qwen3.5:9b + Vision) installation completed successfully!"
ok "You can now run:   ollama run qwen3.5:9b"
