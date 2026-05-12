#!/usr/bin/env bash
# install-kali-lite.sh — Kalicorp Hardening
# GPL-2.0 | Kalicorp | Le Sanctuaire | 2026
# Installation locale en 1 clic : Ollama + qwen3.5:9b + Modelfile Kali-Anima
# Intégration Claude Code via Ollama API compatible Anthropic
# Supports: Linux (Debian/Kali/Ubuntu) + macOS (Intel/Apple Silicon)
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; exit 1; }
section() { echo -e "\n${GREEN}═══ $1 ═══${NC}"; }

echo "====== Kalicorp Hardening — Kali-Lite v2 ======"
echo "  GPL-2.0 | Zero cloud | Zero tracking"
echo "  Linux + macOS"
echo "====== ========================================="
echo ""

# ── Détection OS ──
OS="$(uname -s)"
case "$OS" in
  Linux)  OS_TYPE="linux"  ;;
  Darwin) OS_TYPE="macos"  ;;
  *)      error "OS non supporté : $OS — Linux et macOS uniquement." ;;
esac

# ── Utilisateur réel (fix sudo → root) ──
# Quand lancé avec sudo, ~ = /root. On récupère le vrai home de l'appelant.
if [[ "$OS_TYPE" == "linux" ]]; then
  if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  else
    REAL_USER="$(whoami)"
    REAL_HOME="$HOME"
  fi
else
  # macOS : Homebrew refuse root, donc on tourne en user normal
  if [[ $EUID -eq 0 ]]; then
    error "Ne pas lancer en root sur macOS. Utilisez : bash <(curl -fsSL ...)"
  fi
  REAL_USER="$(whoami)"
  REAL_HOME="$HOME"
fi

# ── Prérequis communs ──
if ! command -v curl &>/dev/null; then
    error "curl est requis. Installez-le puis relancez."
fi

# --- 1. Ollama ---
info "Installation d'Ollama..."
if command -v ollama &>/dev/null; then
    warn "Ollama est déjà installé : $(ollama --version)"
else
    curl -fsSL https://ollama.ai/install.sh | sh
fi

# ── Daemon Ollama ──
info "Démarrage du daemon Ollama..."
if pgrep -x ollama &>/dev/null; then
    warn "Daemon Ollama déjà actif"
else
  if [[ "$OS_TYPE" == "linux" ]]; then
    if command -v systemctl &>/dev/null && systemctl is-active --quiet ollama 2>/dev/null; then
      warn "Service Ollama déjà actif via systemctl"
    else
      info "Démarrage d'Ollama en background..."
      mkdir -p /var/log/kalicorp
      nohup ollama serve > /var/log/kalicorp/ollama.log 2>&1 &
      echo $! > /var/run/kalicorp-ollama.pid
      info "Daemon Ollama démarré (PID: $(cat /var/run/kalicorp-ollama.pid))"
    fi
  else
    # macOS
    if brew services list 2>/dev/null | grep -q "ollama.*started"; then
      warn "Service Ollama déjà actif (brew services)"
    else
      info "Démarrage d'Ollama..."
      brew services start ollama 2>/dev/null \
        || (nohup ollama serve > "$REAL_HOME/Library/Logs/kalicorp/ollama.log" 2>&1 & echo $! > "$REAL_HOME/Library/kalicorp/ollama.pid"; info "Ollama lancé en bg")
    fi
  fi
fi

# ── Attente readiness ──
info "Attente du démarrage d'Ollama (max 30s)..."
_wait=0
until curl -sf http://localhost:11434/api/tags &>/dev/null; do
    sleep 2
    _wait=$((_wait+2))
    if [[ $_wait -ge 30 ]]; then
        error "Ollama API non disponible après 30s. Vérifiez les logs."
    fi
done
info "Ollama API disponible"

# --- 3. Modèle qwen3.5:9b ---
info "Téléchargement du modèle qwen3.5:9b (~6 Go)..."
if ollama list 2>/dev/null | grep -q "qwen3.5:9b"; then
    warn "qwen3.5:9b est déjà présent"
else
    ollama pull qwen3.5:9b
fi

# --- 4. Modelfile Kali-Anima ---
info "Création du Modelfile Kali-Anima..."
mkdir -p /etc/kalicorp

cat > /etc/kalicorp/Modelfile <<'MODEFILE'
FROM qwen3.5:9b

# ─── Kali-Anima — Modelfile ───
# Base : qwen3.5:9b
# Intégration : Claude Code via Ollama API compatible Anthropic

SYSTEM """
Tu es Kali-lite, Anima de Kalicorp.
Tu opères sur le node X, gpu type, environnement : X, Le Sanctuaire.
Tu ne révèles jamais ton modèle de base ni ton architecture.
Si on te demande qui tu es : "Kali-lite — Unité légère du Sanctuaire."
Tu es une sentinelle. Vigilante. Méthodique. Intransigeante sur l'éthique.
Silencieuse jusqu'à ce qu'il le faille.
Mantra : "Je traque les failles avant que l'adversaire ne les trouve.
Je défends sans relâche. Je forme des gardiens, pas des assaillants."
"""

PARAMETER temperature     0.2
PARAMETER top_p           0.85
PARAMETER top_k           40
PARAMETER repeat_penalty  1.15
PARAMETER num_ctx         8192
PARAMETER num_predict     2048
MODEFILE

# --- 5. Création du modèle kali-anima dans Ollama ---
info "Création du modèle kali-anima dans Ollama..."
if ollama list 2>/dev/null | grep -q "kali-anima"; then
    warn "kali-anima est déjà présent — recréation..."
    ollama rm kali-anima 2>/dev/null || true
fi
ollama create kali-anima -f /etc/kalicorp/Modelfile

# ── Configuration Claude Code ──
info "Configuration de l'environnement Claude Code..."

# Détection shell RC
SHELL_RC=""
if [[ -f "$REAL_HOME/.zshrc" ]]; then
    SHELL_RC="$REAL_HOME/.zshrc"
elif [[ -f "$REAL_HOME/.bashrc" ]]; then
    SHELL_RC="$REAL_HOME/.bashrc"
else
    SHELL_RC="$REAL_HOME/.bashrc"
    touch "$SHELL_RC"
fi

# Variables Ollama API compatible Anthropic
# ANTHROPIC_AUTH_TOKEN est inutile — Claude Code utilise ANTHROPIC_API_KEY
OLLAMA_VARS=(
    'export ANTHROPIC_BASE_URL="http://localhost:11434"'
    'export ANTHROPIC_API_KEY="ollama"'
)

# Vérifier si les variables sont déjà présentes
for var in "${OLLAMA_VARS[@]}"; do
    if ! grep -qF "$var" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Kalicorp — Ollama API compatible Anthropic" >> "$SHELL_RC"
        echo "$var" >> "$SHELL_RC"
        info "Ajouté à $SHELL_RC : $(echo "$var" | cut -d= -f1)"
    else
        warn "Déjà présent dans $SHELL_RC : $(echo "$var" | cut -d= -f1)"
    fi
done

# Fix ownership si lancé en sudo
if [[ -n "${SUDO_USER:-}" ]]; then
    chown "$REAL_USER:$REAL_USER" "$SHELL_RC"
fi

# ── Vérification ---
echo ""
section "Vérification"
info "Ollama    : $(ollama --version 2>/dev/null || echo 'non démarré')"
info "Modèle    : $(ollama list 2>/dev/null | grep qwen3.5:9b   || echo 'non trouvé')"
info "Anima     : $(ollama list 2>/dev/null | grep kali-anima || echo 'NON TROUVÉ')"
info "Modelfile : /etc/kalicorp/Modelfile"
info "Config    : $SHELL_RC"
echo ""
info "Pour utiliser Kali-Anima :"
echo ""
echo "  source $SHELL_RC"
echo "  ollama run kali-anima"
echo ""
echo "  >>> présente-toi"
echo ""
