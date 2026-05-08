#!/usr/bin/env bash
# install-kali-lite.sh — Kalicorp Hardening
# GPL-2.0 | Kalicorp | Le Sanctuaire | 2026
# Installation locale en 1 clic : Ollama + qwen3.5:9b + Modelfile Kali-Anima
# Intégration Claude Code via Ollama API compatible Anthropic
# Télémétrie Claude Code désactivée (zero tracking)
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[-]${NC} $1"; exit 1; }
section() { echo -e "\n${BLUE}[»]${NC} $1\n"; }

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║     Kalicorp Hardening — Installation v2.0      ║"
echo "║  GPL-2.0  |  Zero cloud  |  Zero tracking       ║"
echo "║  Claude Code via Ollama API compatible Anthropic ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ─────────────────────────────────────────────
# Prérequis
# ─────────────────────────────────────────────
section "Vérification des prérequis..."

if [[ $EUID -ne 0 ]]; then
    error "Ce script doit être exécuté en root ou avec sudo"
fi

if ! command -v curl &>/dev/null; then
    error "curl est requis. Installez-le : apt install curl"
fi

# Détecter l'utilisateur réel (même si lancé via sudo)
REAL_USER="${SUDO_USER:-${USER:-root}}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6 2>/dev/null || echo "$HOME")
info "Utilisateur cible : $REAL_USER ($REAL_HOME)"

# ─────────────────────────────────────────────
# 1. Ollama
# ─────────────────────────────────────────────
section "1/6 — Installation d'Ollama..."

if command -v ollama &>/dev/null; then
    warn "Ollama est déjà installé : $(ollama --version 2>/dev/null || echo 'version inconnue')"
else
    info "Téléchargement et installation d'Ollama..."
    curl -fsSL https://ollama.ai/install.sh | sh
    info "Ollama installé avec succès"
fi

# ─────────────────────────────────────────────
# 2. Démarrage du daemon Ollama (systemd prioritaire)
# ─────────────────────────────────────────────
section "2/6 — Démarrage du daemon Ollama..."

if command -v systemctl &>/dev/null && systemctl list-unit-files ollama.service &>/dev/null 2>&1; then
    info "Service systemd Ollama détecté — activation au démarrage..."
    systemctl enable ollama 2>/dev/null || warn "Impossible d'activer ollama via systemd"
    systemctl start  ollama 2>/dev/null || warn "Impossible de démarrer ollama via systemd"
    sleep 2
    if systemctl is-active --quiet ollama; then
        info "Service Ollama actif (systemd) — persistant au reboot ✓"
    else
        warn "Systemd signale le service inactif — tentative manuelle..."
        nohup ollama serve > /var/log/ollama.log 2>&1 &
        sleep 3
    fi
else
    # Pas de systemd : démarrage manuel
    if pgrep -x ollama &>/dev/null; then
        warn "Daemon Ollama déjà actif (PID: $(pgrep -x ollama))"
    else
        info "Démarrage manuel du daemon Ollama..."
        nohup ollama serve > /var/log/ollama.log 2>&1 &
        sleep 3
        if pgrep -x ollama &>/dev/null; then
            info "Daemon Ollama démarré (PID: $(pgrep -x ollama))"
            warn "Sans systemd, Ollama ne redémarrera pas automatiquement au reboot"
        else
            warn "Daemon Ollama en cours de démarrage — vérifiez /var/log/ollama.log"
        fi
    fi
fi

# Attendre que l'API Ollama soit prête (max 20s)
info "Attente de l'API Ollama (http://localhost:11434)..."
API_READY=0
for i in {1..20}; do
    if curl -sf http://localhost:11434/api/tags &>/dev/null; then
        info "API Ollama disponible (${i}s)"
        API_READY=1
        break
    fi
    sleep 1
done
if [[ $API_READY -eq 0 ]]; then
    warn "API Ollama non disponible après 20s — vérifiez /var/log/ollama.log"
fi

# ─────────────────────────────────────────────
# 3. Modèle qwen3.5:9b
# ─────────────────────────────────────────────
section "3/6 — Modèle qwen3.5:9b (~6.6 Go)..."

MODEL_NAME="qwen3.5:9b"

if ollama list 2>/dev/null | grep -q "^qwen3\.5.*9b"; then
    warn "${MODEL_NAME} est déjà présent"
else
    info "Téléchargement du modèle ${MODEL_NAME} — environ 6.6 Go..."
    info "Cela peut prendre plusieurs minutes selon votre connexion..."
    ollama pull "${MODEL_NAME}" || error "Échec du téléchargement du modèle ${MODEL_NAME}"
    info "Modèle ${MODEL_NAME} téléchargé avec succès ✓"
fi

# ─────────────────────────────────────────────
# 4. Modelfile Kali-Anima
# ─────────────────────────────────────────────
section "4/6 — Création du Modelfile Kali-Anima..."

mkdir -p /etc/kalicorp

cat > /etc/kalicorp/Modelfile <<'MODEFILE'
FROM qwen3.5:9b

# ─── Kali-Anima — Modelfile ───
# Base : qwen3.5:9b (6.6 Go | 256K ctx | vision + tools + thinking)
# Intégration : Claude Code via Ollama API compatible Anthropic
# Kalicorp | Le Sanctuaire | 2026

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

info "Modelfile créé dans /etc/kalicorp/Modelfile ✓"

# ─────────────────────────────────────────────
# 5. Création du modèle kali-anima dans Ollama
# ─────────────────────────────────────────────
section "5/6 — Création du modèle kali-anima dans Ollama..."

if ollama list 2>/dev/null | grep -q "kali-anima"; then
    warn "kali-anima déjà présent — recréation (mise à jour)..."
    ollama rm kali-anima 2>/dev/null || true
fi

ollama create kali-anima -f /etc/kalicorp/Modelfile || error "Échec de la création du modèle kali-anima"
info "Modèle kali-anima créé avec succès ✓"

# ─────────────────────────────────────────────
# 6. Configuration Claude Code — zero tracking
# ─────────────────────────────────────────────
section "6/6 — Configuration Claude Code (zero tracking)..."

BASHRC_FILE="${REAL_HOME}/.bashrc"

# Variables à injecter (clé=valeur pour test de présence, ligne=valeur à écrire)
declare -a VAR_KEYS=(
    "ANTHROPIC_BASE_URL"
    "ANTHROPIC_AUTH_TOKEN"
    "ANTHROPIC_API_KEY"
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"
    "DISABLE_TELEMETRY"
    "DO_NOT_TRACK"
    "DISABLE_ERROR_REPORTING"
    "DISABLE_AUTOUPDATER"
)

declare -a VAR_LINES=(
    'export ANTHROPIC_BASE_URL="http://localhost:11434"'
    'export ANTHROPIC_AUTH_TOKEN="ollama"'
    'export ANTHROPIC_API_KEY="ollama"'
    'export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1'
    'export DISABLE_TELEMETRY=1'
    'export DO_NOT_TRACK=1'
    'export DISABLE_ERROR_REPORTING=1'
    'export DISABLE_AUTOUPDATER=1'
)

# Écrire le bloc dans .bashrc
echo "" >> "$BASHRC_FILE"
echo "# ── Kalicorp — Ollama API compatible Anthropic + Zero Tracking ──" >> "$BASHRC_FILE"

for i in "${!VAR_KEYS[@]}"; do
    key="${VAR_KEYS[$i]}"
    line="${VAR_LINES[$i]}"
    if grep -qF "$key" "$BASHRC_FILE" 2>/dev/null; then
        warn "Déjà présent dans $BASHRC_FILE : $key"
    else
        echo "$line" >> "$BASHRC_FILE"
        info "Ajouté dans .bashrc → $key"
    fi
done

# Injection dans /etc/environment (effet global, tous shells, tous utilisateurs)
info "Injection dans /etc/environment (effet global)..."

declare -a ENV_PAIRS=(
    'ANTHROPIC_BASE_URL="http://localhost:11434"'
    'ANTHROPIC_AUTH_TOKEN="ollama"'
    'ANTHROPIC_API_KEY="ollama"'
    'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1'
    'DISABLE_TELEMETRY=1'
    'DO_NOT_TRACK=1'
    'DISABLE_ERROR_REPORTING=1'
    'DISABLE_AUTOUPDATER=1'
)

for pair in "${ENV_PAIRS[@]}"; do
    key="${pair%%=*}"
    if grep -q "^${key}=" /etc/environment 2>/dev/null; then
        warn "Déjà dans /etc/environment : $key"
    else
        echo "$pair" >> /etc/environment
        info "/etc/environment ← $key"
    fi
done

# ─────────────────────────────────────────────
# Vérification finale
# ─────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║              Vérification finale                 ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

OLLAMA_VER=$(ollama --version 2>/dev/null || echo "NON TROUVÉ")
MODEL_STATUS=$(ollama list 2>/dev/null | grep "qwen3\.5" | head -1 || echo "NON TROUVÉ")
ANIMA_STATUS=$(ollama list 2>/dev/null | grep "kali-anima" | awk '{print $1}' || echo "NON TROUVÉ")
DAEMON_STATUS=$(pgrep -x ollama &>/dev/null && echo "ACTIF ✓" || echo "INACTIF ✗")
API_STATUS=$(curl -sf http://localhost:11434/api/tags &>/dev/null && echo "DISPONIBLE ✓" || echo "INDISPONIBLE ✗")

echo ""
info "Ollama         : $OLLAMA_VER"
info "Daemon         : $DAEMON_STATUS"
info "API            : $API_STATUS"
info "Modèle base    : ${MODEL_STATUS:-NON TROUVÉ}"
info "Kali-Anima     : ${ANIMA_STATUS:-NON TROUVÉ}"
info "Télémétrie     : DÉSACTIVÉE ✓"
info "  DISABLE_TELEMETRY=1"
info "  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
info "  DO_NOT_TRACK=1"
info "  DISABLE_ERROR_REPORTING=1"
info "  DISABLE_AUTOUPDATER=1"
echo ""
info "Modelfile      : /etc/kalicorp/Modelfile"
info "Config shell   : $BASHRC_FILE"
info "Config global  : /etc/environment"
echo ""

echo "╔══════════════════════════════════════════════════╗"
echo "║          Installation terminée ✓                 ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
info "Comment utiliser Kali-Anima :"
echo ""
echo "  # Option 1 — Chat direct Ollama"
echo "  ollama run kali-anima"
echo ""
echo "  # Option 2 — Claude Code (ouvrir un nouveau terminal ou :)"
echo "  source ~/.bashrc"
echo "  claude"
echo ""
echo "  >>> présente-toi"
echo ""
warn "Note : DISABLE_TELEMETRY désactive aussi la récupération des feature gates"
warn "distants (Statsig). Les fonctionnalités expérimentales utiliseront leurs"
warn "valeurs par défaut intégrées. Comportement normal en mode local/air-gapped."
echo ""
