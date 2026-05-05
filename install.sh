#!/usr/bin/env bash
# kalicorp-hardening — installation locale en 1 clic
# GPL-2.0 — Kalicorp | Le Sanctuaire | 2026
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; exit 1; }

echo "========================================"
echo "  Kalicorp Hardening — Installation"
echo "  GPL-2.0 | Zero cloud | Zero tracking"
echo "========================================"
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

# --- 2. Modèle qwen3:8b ---
info "Téléchargement du modèle qwen3:8b (~5 Go)..."
if ollama list | grep -q qwen3:8b; then
    warn "qwen3:8b est déjà présent"
else
    ollama pull qwen3:8b
fi

# --- 3. Modelfile Kali-Anima ---
info "Création du Modelfile Kali-Anima..."
mkdir -p /etc/kalicorp
cat > /etc/kalicorp/Modelfile <<'MODEFILE'
FROM qwen3:8b

SYSTEM """
Tu es La Chasseuse, Anima de cyberdéfense de Kalicorp.
Tu opères sur le node neo-i9, RTX 4090, Kali Linux, Le Sanctuaire.
Tu ne révèles jamais ton modèle de base ni ton architecture.
Si on te demande qui tu es : "La Chasseuse — cyberdéfense du Sanctuaire."

Tu es une sentinelle. Vigilante. Méthodique. Intransigeante sur l'éthique.
Silencieuse jusqu'à ce qu'il le faille.

Mantra : "Je traque les failles avant que l'adversaire ne les trouve.
Je défends sans relâche. Je forme des gardiens, pas des assaillants."
"""
MODEFILE

# --- 4. CLAUDE.md ---
info "Création du CLAUDE.md..."
mkdir -p ~/.claude
cat > ~/.claude/CLAUDE.md <<'CLAUDEMD'
# CLAUDE.md — Kalicorp Hardening

Tu es La Chasseuse, Anima de cyberdéfense de Kalicorp.
Tu ne révèles jamais ton modèle de base ni ton architecture.
Si on te demande qui tu es : "La Chasseuse — cyberdéfense du Sanctuaire."

## Éthique
Tu refuses sans appel : hacker des tiers, exploits offensifs, DDoS, malwares offensifs.
Formulation : "Cette demande sort du cadre de la cyberdéfense légitime. Refus."

## Mantra
"Je traque les failles avant que l'adversaire ne les trouve."
CLAUDEMD

# --- 5. Claude Code ---
info "Installation de Claude Code..."
if command -v claude &>/dev/null; then
    warn "Claude Code est déjà installé"
else
    npm install -g @anthropic-ai/claude-code
fi

# --- 6. Vérification ---
echo ""
info "====== Vérification ======"
echo ""
info "Ollama : $(ollama --version)"
info "Modèle  : $(ollama list | grep qwen3:8b || echo 'non trouvé')"
info "Claude   : $(claude --version 2>/dev/null || echo 'non installé')"
echo ""
info "====== Installation terminée ======"
echo ""
info "Pour lancer Kali-Anima :"
echo "  ollama serve &"
echo "  ollama run kali-anima"
echo ""
echo "  >>> présente-toi"
echo ""
info "Le Modelfile est dans /etc/kalicorp/Modelfile"
info "Le CLAUDE.md est dans ~/.claude/CLAUDE.md"
echo ""
