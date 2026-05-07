#!/usr/bin/env bash
# install-kali-lite.sh — Kalicorp Hardening
# GPL-2.0 | Kalicorp | Le Sanctuaire | 2026
# Installation locale en 1 clic : Ollama + qwen3.5:9b + Modelfile Kali-Anima
# Intégration Claude Code via Ollama API compatible Anthropic
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; exit 1; }

echo "====== Kalicorp Hardening — Installation ======"
echo "  GPL-2.0 | Zero cloud | Zero tracking"
echo "  Claude Code via Ollama API compatible Anthropic"
echo "====== ========================================="
echo ""

# --- Prérequis ---
if [[ $EUID -ne 0 ]]; then
    error "Ce script doit être exécuté en root ou avec sudo"
fi

if ! command -v curl &>/dev/null; then
    error "curl est requis. Installez-le : apt install curl"
fi

# --- 1. Ollama ---
info "Installation d'Ollama..."
if command -v ollama &>/dev/null; then
    warn "Ollama est déjà installé : $(ollama --version)"
else
    curl -fsSL https://ollama.ai/install.sh | sh
fi

# --- 2. Démarrage du daemon Ollama ---
info "Démarrage du daemon Ollama..."
if ! pgrep -x ollama &>/dev/null; then
    ollama serve > /var/log/ollama.log 2>&1 &
    sleep 3
    if pgrep -x ollama &>/dev/null; then
        info "Daemon Ollama démarré"
    else
        warn "Daemon Ollama en cours de démarrage (vérifiez /var/log/ollama.log)"
    fi
else
    warn "Daemon Ollama déjà actif"
fi

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

# --- 6. Configuration Claude Code ---
info "Configuration de l'environnement Claude Code..."
ENV_FILE="$HOME/.bashrc"

# Variables Ollama API compatible Anthropic
OLLAMA_VARS=(
    'export ANTHROPIC_BASE_URL="http://localhost:11434"'
    'export ANTHROPIC_AUTH_TOKEN="ollama"'
    'export ANTHROPIC_API_KEY=""'
)

# Vérifier si les variables sont déjà présentes
for var in "${OLLAMA_VARS[@]}"; do
    if ! grep -qF "$var" "$ENV_FILE" 2>/dev/null; then
        echo "" >> "$ENV_FILE"
        echo "# Kalicorp — Ollama API compatible Anthropic" >> "$ENV_FILE"
        echo "$var" >> "$ENV_FILE"
        info "Ajouté à $ENV_FILE : $(echo "$var" | cut -d= -f1)"
    else
        warn "Déjà présent dans $ENV_FILE : $(echo "$var" | cut -d= -f1)"
    fi
done

# --- 7. Vérification ---
echo ""
info "====== Vérification ======"
echo ""
info "Ollama  : $(ollama --version 2>/dev/null || echo 'non démarré')"
info "Modèle  : $(ollama list 2>/dev/null | grep qwen3.5:9b   || echo 'non trouvé')"
info "Anima   : $(ollama list 2>/dev/null | grep kali-anima || echo 'NON TROUVÉ')"
echo ""
info "====== Installation terminée ======"
echo ""
info "Pour utiliser Kali-Anima :"
echo ""
echo "  # Option 1 — Ligne de commande"
echo "  export ANTHROPIC_BASE_URL=http://localhost:11434"
echo "  export ANTHROPIC_AUTH_TOKEN=ollama"
echo "  export ANTHROPIC_API_KEY="
echo "  ollama run kali-anima"
echo ""
echo "  # Option 2 — Claude Code"
echo "  source ~/.bashrc"
echo "  claude"
echo ""
echo "  >>> présente-toi"
echo ""
info "Le Modelfile est dans /etc/kalicorp/Modelfile"
info "Les variables d'environnement sont dans ~/.bashrc"
echo ""
