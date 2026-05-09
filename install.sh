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
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[-]${NC} $1"; exit 1; }
section() { echo -e "\n${BLUE}[»]${NC} $1\n"; }
note()    { echo -e "${CYAN}[i]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║     Kalicorp Hardening — Installation v2.2      ║"
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
# Détection d'une config Claude Code personnelle existante
# On sauvegarde ANTHROPIC_API_KEY si elle existe déjà dans .bashrc
# pour ne pas écraser un setup perso
# ─────────────────────────────────────────────
section "Détection d'une configuration Claude Code existante..."

BASHRC_FILE="${REAL_HOME}/.bashrc"
EXISTING_API_KEY=""
PERSO_CONFIG_FOUND=0

if [[ -f "$BASHRC_FILE" ]]; then
    # Chercher un export global ANTHROPIC_API_KEY qui ne soit pas "ollama"
    # (= config perso réelle, pas une ancienne injection Kalicorp)
    EXISTING_API_KEY=$(grep -E "^export ANTHROPIC_API_KEY=" "$BASHRC_FILE" 2>/dev/null \
        | grep -v '=ollama' | head -1 \
        | sed 's/^export ANTHROPIC_API_KEY=//' | tr -d '"' || true)
fi

if [[ -n "$EXISTING_API_KEY" ]]; then
    PERSO_CONFIG_FOUND=1
    warn "Configuration Claude Code personnelle détectée !"
    note "ANTHROPIC_API_KEY existante trouvée (non modifiée)"
    note "Les alias Kalicorp seront isolés — votre config perso reste intacte"
else
    info "Aucune config Claude Code personnelle détectée — installation propre"
fi

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
section "3/6 — Modèle qwen3.5:9b (~6.6 Go, contexte 256K, multimodal)..."

MODEL_NAME="qwen3.5:9b"

if ollama list 2>/dev/null | grep -q "^qwen3\.5.*9b"; then
    warn "${MODEL_NAME} est déjà présent"
else
    info "Téléchargement du modèle ${MODEL_NAME}..."
    ollama pull "${MODEL_NAME}" || error "Échec du téléchargement de ${MODEL_NAME}"
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

if ollama list 2>/dev/null | grep -q "^kali-anima"; then
    warn "kali-anima déjà présent — recréation..."
    ollama rm kali-anima 2>/dev/null || true
fi

ollama create kali-anima -f /etc/kalicorp/Modelfile || error "Échec de la création du modèle kali-anima"
info "Modèle kali-anima créé avec succès ✓"

# ─────────────────────────────────────────────
# 6. Configuration Claude Code — ALIAS ISOLÉS
# ─────────────────────────────────────────────
# Stratégie :
#   - On ne touche JAMAIS aux exports globaux ANTHROPIC_API_KEY existants (config perso)
#   - On ne touche JAMAIS à ANTHROPIC_BASE_URL si elle pointe hors localhost
#   - Les variables Kalicorp vivent UNIQUEMENT dans les alias (env inline)
#   - Suppression ciblée des anciens exports Kalicorp (valeur = "ollama" ou "localhost")
#   - Suppression robuste des anciens blocs Kalicorp via Python (pas de sed multiline fragile)
# ─────────────────────────────────────────────
section "6/6 — Configuration Claude Code (alias isolés, zero tracking)..."

# ── Backup .bashrc avant toute modification ──
cp "$BASHRC_FILE" "${BASHRC_FILE}.bak.$(date +%s)"
info "Backup .bashrc créé ✓"

# ── Nettoyer UNIQUEMENT les exports globaux injectés par Kalicorp v2.0/v2.1 ──
# On identifie les exports Kalicorp à leur valeur (ollama, localhost, vide)
# On ne supprime PAS les exports dont la valeur est une vraie clé API
info "Nettoyage ciblé des anciens exports Kalicorp..."

sed -i '/^export ANTHROPIC_BASE_URL=.*localhost/d'  "$BASHRC_FILE" 2>/dev/null || true
sed -i '/^export ANTHROPIC_BASE_URL=.*ollama/d'     "$BASHRC_FILE" 2>/dev/null || true
sed -i '/^export ANTHROPIC_API_KEY=ollama$/d'        "$BASHRC_FILE" 2>/dev/null || true
sed -i '/^export ANTHROPIC_AUTH_TOKEN=""$/d'         "$BASHRC_FILE" 2>/dev/null || true
sed -i '/^export ANTHROPIC_AUTH_TOKEN=$/d'           "$BASHRC_FILE" 2>/dev/null || true

# Variables de télémétrie (sans impact sur config perso)
for var in "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" \
           "CLAUDE_CODE_DISABLE_TELEMETRY" \
           "DISABLE_TELEMETRY" \
           "DO_NOT_TRACK" \
           "DISABLE_ERROR_REPORTING" \
           "DISABLE_AUTOUPDATER"; do
    sed -i "/^export ${var}=/d" "$BASHRC_FILE" 2>/dev/null || true
done

# ── Nettoyer /etc/environment ──
info "Nettoyage /etc/environment..."
for var in "ANTHROPIC_BASE_URL" "ANTHROPIC_API_KEY" "ANTHROPIC_AUTH_TOKEN" \
           "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" "CLAUDE_CODE_DISABLE_TELEMETRY" \
           "DISABLE_TELEMETRY" "DO_NOT_TRACK" "DISABLE_ERROR_REPORTING" "DISABLE_AUTOUPDATER"; do
    sed -i "/^${var}=/d" /etc/environment 2>/dev/null || true
done

# ── Supprimer les anciens blocs Kalicorp (v2.0 et v2.1) ──
# Suppression robuste via Python — pas de sed multiline fragile
if grep -q "# ── Kalicorp —" "$BASHRC_FILE" 2>/dev/null; then
    warn "Ancien bloc Kalicorp détecté — suppression robuste..."
    python3 - "$BASHRC_FILE" <<'PYEOF'
import sys, re
path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()
# Supprime les blocs Kalicorp : de "# ── Kalicorp —" jusqu'à "# ── Fin Kalicorp ──" inclus
# Compatibilité v2.0 (sans marqueur fin) et v2.1/v2.2 (avec marqueur fin)
cleaned = re.sub(
    r'\n# ── Kalicorp —.*?(?:# ── Fin Kalicorp ──\n?|(?=\n[^#\n]))',
    '',
    content,
    flags=re.DOTALL
)
# Fallback : supprimer aussi les lignes alias kali-* orphelines
cleaned = re.sub(r'\nalias kali-\w+=.*\n', '\n', cleaned)
with open(path, 'w') as f:
    f.write(cleaned)
print("[+] Ancien bloc Kalicorp supprimé")
PYEOF
fi

# ── Construction de l'alias selon la présence d'une config perso ──
# Si config perso : on ne force PAS ANTHROPIC_AUTH_TOKEN= (évite d'écraser un token valide)
# Si pas de config perso : on vide ANTHROPIC_AUTH_TOKEN pour éviter les conflits
if [[ $PERSO_CONFIG_FOUND -eq 1 ]]; then
    ALIAS_ENV="ANTHROPIC_BASE_URL=http://localhost:11434/v1 ANTHROPIC_API_KEY=ollama"
    CONFIG_NOTE="# Config Claude Code personnelle détectée et préservée — alias isolés"
else
    ALIAS_ENV="ANTHROPIC_BASE_URL=http://localhost:11434/v1 ANTHROPIC_API_KEY=ollama ANTHROPIC_AUTH_TOKEN="
    CONFIG_NOTE="# Installation propre — aucune config Claude Code personnelle"
fi

# Variables communes de télémétrie + modèle
ALIAS_TELEMETRY="CLAUDE_CODE_DISABLE_TELEMETRY=1 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 DISABLE_AUTOUPDATER=1 DO_NOT_TRACK=1 ANTHROPIC_MODEL=kali-anima:latest"

# ── Injection du nouveau bloc ──
cat >> "$BASHRC_FILE" <<ALIASES

# ── Kalicorp — Claude Code via Ollama (alias isolés, zero tracking) v2.2 ──
${CONFIG_NOTE}
# kali-anima : modèle local Ollama (kali-anima:latest, base qwen3.5:9b, 256K ctx)
alias kali-anima='env ${ALIAS_ENV} ${ALIAS_TELEMETRY} claude'
# ── Fin Kalicorp ──
ALIASES

info "Alias kali-anima injecté dans $BASHRC_FILE ✓"
info "Aucune variable globale injectée — zéro conflit ✓"

# Fixer les permissions
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
ANIMA_STATUS=$(ollama list 2>/dev/null | grep "^kali-anima" | awk '{print $1}' || echo "NON TROUVÉ")
DAEMON_STATUS=$(pgrep -x ollama &>/dev/null && echo "ACTIF ✓" || echo "INACTIF ✗")
API_STATUS=$(curl -sf http://localhost:11434/api/tags &>/dev/null && echo "DISPONIBLE ✓" || echo "INDISPONIBLE ✗")

ENV_REMAINING=$(grep -cE "^(ANTHROPIC|KALICORP)" /etc/environment 2>/dev/null || echo "0")
if [[ "$ENV_REMAINING" -eq 0 ]]; then
    ENV_CLEAN="PROPRE ✓"
else
    ENV_CLEAN="⚠ ${ENV_REMAINING} variable(s) restante(s) — vérifier manuellement"
fi

PERSO_STATUS="Non détectée"
[[ $PERSO_CONFIG_FOUND -eq 1 ]] && PERSO_STATUS="Détectée et PRÉSERVÉE ✓"

echo ""
info "Ollama           : $OLLAMA_VER"
info "Daemon           : $DAEMON_STATUS"
info "API              : $API_STATUS"
info "Modèle base      : ${MODEL_STATUS:-NON TROUVÉ}"
info "Kali-Anima       : ${ANIMA_STATUS:-NON TROUVÉ}"
info "/etc/environment : $ENV_CLEAN"
info "Config perso     : $PERSO_STATUS"
info "Alias injectés   : kali-anima"
info "Config shell     : $BASHRC_FILE"
info "Backup           : ${BASHRC_FILE}.bak.*"
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

if [[ $PERSO_CONFIG_FOUND -eq 1 ]]; then
    warn "Config Claude Code personnelle préservée :"
    note "  'claude' normal continue d'utiliser votre ANTHROPIC_API_KEY globale"
    note "  'kali-anima' pointe sur Ollama local via env inline (isolé)"
    note "  Les deux coexistent sans aucun conflit"
    echo ""
fi

warn "ANTHROPIC_AUTH_TOKEN est vidé dans l'alias (si pas de config perso)"
warn "pour éviter les conflits avec les autres alias Kalicorp (kali-code, etc.)"
echo ""
