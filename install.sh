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
echo "║     Kalicorp Hardening — Installation v2.1      ║"
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
# 2. Démarrage du daemon Ollama
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
    if pgrep -x ollama &>/dev/null; then
        warn "Daemon Ollama déjà actif (PID: $(pgrep -x ollama))"
    else
        info "Démarrage manuel du daemon Ollama..."
        nohup ollama serve > /var/log/ollama.log 2>&1 &
        sleep 3
    fi
fi

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
[[ $API_READY -eq 0 ]] && warn "API Ollama non disponible après 20s — vérifiez /var/log/ollama.log"

# ─────────────────────────────────────────────
# 3. Modèle qwen3.5:9b
# ─────────────────────────────────────────────
section "3/6 — Modèle qwen3.5:9b (~6.6 Go)..."

MODEL_NAME="qwen3.5:9b"

if ollama list 2>/dev/null | grep -q "^qwen3\.5.*9b"; then
    warn "${MODEL_NAME} est déjà présent"
else
    info "Téléchargement du modèle ${MODEL_NAME}..."
    ollama pull "${MODEL_NAME}" || error "Échec du téléchargement"
    info "Modèle ${MODEL_NAME} téléchargé ✓"
fi

# ─────────────────────────────────────────────
# 4. Modelfile Kali-Anima
# ─────────────────────────────────────────────
section "4/6 — Création du Modelfile Kali-Anima..."

mkdir -p /etc/kalicorp

cat > /etc/kalicorp/Modelfile <<'MODEFILE'
FROM qwen3.5:9b

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
PARAMETER think           false
MODEFILE

info "Modelfile créé dans /etc/kalicorp/Modelfile ✓"

# ─────────────────────────────────────────────
# 5. Création du modèle kali-anima
# ─────────────────────────────────────────────
section "5/6 — Création du modèle kali-anima dans Ollama..."

if ollama list 2>/dev/null | grep -q "kali-anima"; then
    warn "kali-anima déjà présent — recréation..."
    ollama rm kali-anima 2>/dev/null || true
fi

ollama create kali-anima -f /etc/kalicorp/Modelfile || error "Échec de la création du modèle"
info "Modèle kali-anima créé avec succès ✓"

# ─────────────────────────────────────────────
# 6. Configuration Claude Code — ALIAS PROPRES
# ─────────────────────────────────────────────
# IMPORTANT : on n'injecte PLUS de variables globales dans .bashrc ou /etc/environment
# Les variables Anthropic vivent UNIQUEMENT dans les alias pour éviter les conflits
# ─────────────────────────────────────────────
section "6/6 — Configuration Claude Code (alias propres, zero tracking)..."

BASHRC_FILE="${REAL_HOME}/.bashrc"

# ── Nettoyer les anciens exports globaux injectés par les versions précédentes ──
info "Nettoyage des anciens exports globaux (v2.0)..."
VARS_TO_CLEAN=(
    "ANTHROPIC_BASE_URL"
    "ANTHROPIC_AUTH_TOKEN"
    "ANTHROPIC_API_KEY"
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"
)

# Créer un backup avant modification
cp "$BASHRC_FILE" "${BASHRC_FILE}.bak.$(date +%s)"
info "Backup .bashrc créé ✓"

# Supprimer les lignes d'export global (pas les alias)
for var in "${VARS_TO_CLEAN[@]}"; do
    sed -i "/^export ${var}=/d" "$BASHRC_FILE" 2>/dev/null && \
        info "Supprimé de .bashrc : export ${var}" || true
done

# Nettoyer /etc/environment des variables Anthropic
info "Nettoyage /etc/environment..."
for var in "${VARS_TO_CLEAN[@]}"; do
    sed -i "/^${var}=/d" /etc/environment 2>/dev/null && \
        info "Supprimé de /etc/environment : ${var}" || true
done
# Variables restantes à nettoyer dans /etc/environment
for var in "DISABLE_TELEMETRY" "DO_NOT_TRACK" "DISABLE_ERROR_REPORTING" "DISABLE_AUTOUPDATER"; do
    sed -i "/^${var}=/d" /etc/environment 2>/dev/null || true
done

# ── Supprimer le bloc Kalicorp v2.0 existant s'il existe ──
if grep -q "Kalicorp — Ollama API compatible Anthropic" "$BASHRC_FILE" 2>/dev/null; then
    warn "Ancien bloc Kalicorp détecté — suppression..."
    # Supprimer le bloc entre le commentaire Kalicorp et la fin de la section
    sed -i '/# ── Kalicorp — Ollama API compatible Anthropic/,/^$/d' "$BASHRC_FILE" 2>/dev/null || true
fi

# ── Injecter le nouveau bloc avec alias propres ──
cat >> "$BASHRC_FILE" <<'ALIASES'

# ── Kalicorp — Claude Code via Ollama (alias isolés, zero tracking) ──
# kali-anima : modèle local Ollama (kali-anima:latest)
alias kali-anima='env ANTHROPIC_BASE_URL=http://localhost:11434/v1 ANTHROPIC_API_KEY=ollama ANTHROPIC_AUTH_TOKEN="" ANTHROPIC_MODEL=kali-anima:latest CLAUDE_CODE_DISABLE_TELEMETRY=1 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 DISABLE_AUTOUPDATER=1 DO_NOT_TRACK=1 claude'

ALIASES

info "Alias kali-anima injecté dans $BASHRC_FILE ✓"
info "Aucune variable globale injectée — zéro conflit ✓"

# Fixer les permissions du .bashrc
chown "$REAL_USER:$REAL_USER" "$BASHRC_FILE" 2>/dev/null || true

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
ENV_CLEAN=$(grep -c "ANTHROPIC" /etc/environment 2>/dev/null && echo "⚠ Variables restantes" || echo "PROPRE ✓")

echo ""
info "Ollama         : $OLLAMA_VER"
info "Daemon         : $DAEMON_STATUS"
info "API            : $API_STATUS"
info "Modèle base    : ${MODEL_STATUS:-NON TROUVÉ}"
info "Kali-Anima     : ${ANIMA_STATUS:-NON TROUVÉ}"
info "/etc/environment : $ENV_CLEAN"
info "Alias injectés : kali-anima"
info "Config shell   : $BASHRC_FILE"
echo ""

echo "╔══════════════════════════════════════════════════╗"
echo "║          Installation terminée ✓                 ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
info "Comment utiliser Kali-Anima :"
echo ""
echo "  # Option 1 — Chat direct Ollama (sans Claude Code)"
echo "  ollama run kali-anima"
echo ""
echo "  # Option 2 — Claude Code via alias isolé"
echo "  source ~/.bashrc"
echo "  kali-anima"
echo ""
echo "  >>> présente-toi"
echo ""
warn "Note : ANTHROPIC_AUTH_TOKEN est vidé dans l'alias pour éviter les conflits"
warn "avec les autres alias Kalicorp (kali-code, kali-devcore, etc.)"
echo ""
