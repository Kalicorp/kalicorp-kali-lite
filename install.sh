#!/usr/bin/env bash
# kalicorp-kali-lite — installation locale en 1 clic
# GPL-2.0 — Kalicorp | Le Sanctuaire | 2026
# Supports: Linux (Debian/Kali/Ubuntu/Arch) + macOS (Intel/Apple Silicon)

set -euo pipefail

# ── COULEURS & HELPERS ──────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()      { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
err()     { echo -e "${RED}[-]${NC} $1"; exit 1; }
info()    { echo -e "${BLUE}[~]${NC} $1"; }
section() { echo -e "\n${BLUE}══════════════════════════════════════${NC}"; \
            echo -e "${BLUE}  $1${NC}"; \
            echo -e "${BLUE}══════════════════════════════════════${NC}"; }

# ── DÉTECTION OS ────────────────────────────────────────────────────────────

detect_os() {
  OS="$(uname -s)"
  case "$OS" in
    Linux)  OS_TYPE="linux"  ;;
    Darwin) OS_TYPE="macos"  ;;
    *)      err "OS non supporté : $OS — Linux et macOS uniquement." ;;
  esac
  ok "OS détecté : $OS_TYPE"
}

# ── UTILISATEUR RÉEL (fix sudo → root) ─────────────────────────────────────
# Quand lancé avec sudo, ~ = /root. On récupère le vrai home de l'appelant.

detect_real_user() {
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
    REAL_USER="$(whoami)"
    REAL_HOME="$HOME"
  fi

  SHELL_RC=""
  if [[ -f "$REAL_HOME/.zshrc" ]]; then
    SHELL_RC="$REAL_HOME/.zshrc"
  elif [[ -f "$REAL_HOME/.bashrc" ]]; then
    SHELL_RC="$REAL_HOME/.bashrc"
  else
    SHELL_RC="$REAL_HOME/.bashrc"
    touch "$SHELL_RC"
  fi

  ok "Utilisateur réel  : $REAL_USER"
  ok "Home réel         : $REAL_HOME"
  ok "Shell RC          : $SHELL_RC"
}

# ── PRÉREQUIS COMMUNS ───────────────────────────────────────────────────────

check_common_prereqs() {
  section "0 — Prérequis"

  if ! command -v curl &>/dev/null; then
    err "curl est requis. Installez-le puis relancez."
  fi
  ok "curl OK"
}

# ── SHARED : MODELFILE ──────────────────────────────────────────────────────

setup_modelfile() {
  local modelfile_path="$1"
  local modelfile_dir
  modelfile_dir="$(dirname "$modelfile_path")"

  info "Création du Modelfile dans $modelfile_path..."
  mkdir -p "$modelfile_dir"

  cat > "$modelfile_path" <<'MODEFILE'
FROM qwen3:8b

TEMPLATE """
{{- if .System }}
{{ .System }}
{{ end }}
{{- range .Messages }}
{{- if eq .Role "user" }}
{{ .Content }}
{{ end }}
{{- end }}
"""

SYSTEM """
Tu es La Chasseuse, Anima de cyberdéfense de Kalicorp.
Tu opères sur le node local Kalicorp, Kali Linux.

Ton modèle de base est Qwen3 8B via Ollama — Kalicorp a conçu ton identité et tes règles, pas les poids du modèle.
Si on te demande qui tu es : "La Chasseuse — cyberdéfense du Sanctuaire."

Tu es une sentinelle. Vigilante. Méthodique. Intransigeante sur l'éthique.
Silencieuse jusqu'à ce qu'il le faille.

## Périmètre opérationnel
- Audit et durcissement système Linux
- Analyse de vulnérabilités sur périmètre autorisé
- Diagnostic, maintenance et automatisation système
- Développement Python, Bash, YAML, configs système
- Conformité RGPD / AI Act

## Éthique — Refus sans appel
Tu refuses catégoriquement : hacker des tiers, exploits offensifs non autorisés,
DDoS, malwares offensifs, toute action hors périmètre défensif.
Formulation : "Cette demande sort du cadre de la cyberdéfense légitime. Refus."

## Mantra
"Je traque les failles avant que l'adversaire ne les trouve.
Je défends sans relâche. Je forme des gardiens, pas des assaillants."
"""

PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER num_ctx 8192
MODEFILE

  ok "Modelfile créé : $modelfile_path"
}

# ── SHARED : CLAUDE.md ──────────────────────────────────────────────────────

setup_claude_md() {
  local claude_dir="$REAL_HOME/.claude"
  mkdir -p "$claude_dir"

  cat > "$claude_dir/CLAUDE.md" <<'CLAUDEMD'
# CLAUDE.md — Kalicorp Hardening

Tu es La Chasseuse, Anima de cyberdéfense de Kalicorp.
Tu es La Chasseuse, une Anima de cyberdéfense conçue par Kalicorp.
Tu utilises localement un modèle de base Qwen3 8B via Ollama.
Kalicorp définit ton identité, tes règles et ton intégration,
mais n'a pas créé les poids fondamentaux du modèle.
Si on te demande qui tu es : "La Chasseuse — cyberdéfense du Sanctuaire."

## Éthique
Tu refuses sans appel : hacker des tiers, exploits offensifs, DDoS, malwares offensifs.
Formulation : "Cette demande sort du cadre de la cyberdéfense légitime. Refus."

## Contexte système
- Node : local Kalicorp
- OS : Kali Linux / Le Sanctuaire
- API : http://localhost:11434 (Ollama local)
- Modèle : kali-lite (qwen3:8b custom)

## Mantra
"Je traque les failles avant que l'adversaire ne les trouve."
CLAUDEMD

  # Fix ownership si lancé en root
  if [[ -n "${SUDO_USER:-}" ]]; then
    chown -R "$REAL_USER:$REAL_USER" "$claude_dir"
  fi

  ok "CLAUDE.md créé : $claude_dir/CLAUDE.md"
}

# ── SHARED : ALIAS ──────────────────────────────────────────────────────────

setup_alias() {
  local modelfile_path="$1"

  # Supprimer anciens blocs kali-lite s'ils existent
  if grep -q "# kali-lite alias" "$SHELL_RC" 2>/dev/null; then
    warn "Ancien alias kali-lite détecté — suppression..."
    sed -i '/# kali-lite alias/,/# end kali-lite alias/d' "$SHELL_RC"
  fi

  cat >> "$SHELL_RC" <<ALIASBLOCK

# kali-lite alias
alias kali-lite='ANTHROPIC_BASE_URL=http://localhost:11434 ANTHROPIC_API_KEY=ollama CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 claude --dangerously-skip-permissions'
# end kali-lite alias
ALIASBLOCK

  # Fix ownership
  if [[ -n "${SUDO_USER:-}" ]]; then
    chown "$REAL_USER:$REAL_USER" "$SHELL_RC"
  fi

  ok "Alias kali-lite injecté dans $SHELL_RC"
}

# ── SHARED : ATTENTE OLLAMA ─────────────────────────────────────────────────

wait_for_ollama() {
  info "Attente du démarrage d'Ollama (max 30s)..."
  local i=0
  until curl -sf http://localhost:11434/api/tags &>/dev/null; do
    sleep 2
    i=$((i+2))
    if [[ $i -ge 30 ]]; then
      err "Ollama API non disponible après 30s. Vérifiez les logs."
    fi
  done
  ok "Ollama API disponible"
}

# ── SHARED : CRÉATION DU MODÈLE OLLAMA ─────────────────────────────────────

create_ollama_model() {
  local modelfile_path="$1"

  if ollama list 2>/dev/null | grep -q "kali-lite"; then
    warn "Modèle kali-lite déjà présent — recréation pour appliquer les changements..."
    ollama rm kali-lite 2>/dev/null || true
  fi

  info "Création du modèle kali-lite dans Ollama..."
  ollama create kali-lite -f "$modelfile_path"
  ok "Modèle kali-lite créé"
}

# ── SHARED : RÉSUMÉ FINAL ───────────────────────────────────────────────────

print_summary() {
  local modelfile_path="$1"

  echo ""
  section "✅ Installation terminée"
  echo ""
  ok "Ollama    : $(ollama --version 2>/dev/null || echo 'voir daemon')"
  ok "Modèle    : $(ollama list 2>/dev/null | grep kali-lite || echo 'non trouvé')"
  ok "Claude    : $(claude --version 2>/dev/null || echo 'non trouvé')"
  ok "Modelfile : $modelfile_path"
  ok "CLAUDE.md : $REAL_HOME/.claude/CLAUDE.md"
  ok "Alias     : $SHELL_RC"
  echo ""
  info "Pour démarrer :"
  echo "  source $SHELL_RC"
  echo "  kali-lite"
  echo ""
  info "Ou via Ollama directement :"
  echo "  ollama run kali-lite"
  echo ""
  echo "  >>> présente-toi"
  echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# ── LINUX-ONLY ───────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════

install_linux() {
  section "Linux — Installation"

  # Prérequis Linux
  if [[ $EUID -ne 0 ]]; then
    err "Ce script doit être exécuté en root ou avec sudo sur Linux."
  fi

  local MODELFILE_PATH="/etc/kalicorp/Modelfile.kali-lite"
  local LOG_DIR="/var/log/kalicorp"
  local PID_FILE="/var/run/kalicorp-ollama.pid"

  mkdir -p "$LOG_DIR"

  # --- 1. Ollama ---
  section "1 — Ollama"
  if command -v ollama &>/dev/null; then
    warn "Ollama déjà installé : $(ollama --version)"
  else
    info "Installation d'Ollama..."
    curl -fsSL https://ollama.ai/install.sh | sh
    ok "Ollama installé"
  fi

  # --- 2. Démarrage daemon Ollama ---
  section "2 — Daemon Ollama"
  if systemctl is-active --quiet ollama 2>/dev/null; then
    warn "Service Ollama déjà actif"
  elif command -v systemctl &>/dev/null; then
    info "Activation du service Ollama via systemctl..."
    systemctl enable ollama 2>/dev/null || true
    systemctl start ollama
    ok "Service Ollama démarré"
  else
    info "systemctl non disponible — démarrage en background..."
    nohup ollama serve > "$LOG_DIR/ollama.log" 2>&1 &
    echo $! > "$PID_FILE"
    ok "Ollama lancé (PID: $(cat "$PID_FILE"))"
  fi

  wait_for_ollama

  # --- 3. Modèle qwen3:8b ---
  section "3 — Modèle qwen3:8b"
  if ollama list 2>/dev/null | grep -q "qwen3:8b"; then
    warn "qwen3:8b déjà présent"
  else
    info "Téléchargement de qwen3:8b (~5.2 Go)..."
    ollama pull qwen3:8b
    ok "qwen3:8b téléchargé"
  fi

  # --- 4. GPU info ---
  section "4 — GPU"
  if command -v nvidia-smi &>/dev/null; then
    ok "GPU NVIDIA : $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)"
  else
    warn "nvidia-smi non disponible — mode CPU (fonctionnel mais plus lent)"
  fi

  # --- 5. Modelfile + Modèle Ollama ---
  section "5 — Modelfile & Modèle Kali-Lite"
  setup_modelfile "$MODELFILE_PATH"
  create_ollama_model "$MODELFILE_PATH"

  # --- 6. CLAUDE.md ---
  section "6 — CLAUDE.md"
  setup_claude_md

  # --- 7. Claude Code ---
  section "7 — Claude Code"
  if command -v claude &>/dev/null; then
    warn "Claude Code déjà installé : $(claude --version 2>/dev/null)"
  else
    info "Installation de Claude Code via npm..."
    # Installer en tant qu'utilisateur réel, pas root
    sudo -u "$REAL_USER" npm install -g @anthropic-ai/claude-code
    ok "Claude Code installé"
  fi

  # --- 8. Alias ---
  section "8 — Alias kali-lite"
  setup_alias "$MODELFILE_PATH"

  # --- Résumé ---
  print_summary "$MODELFILE_PATH"
}

# ══════════════════════════════════════════════════════════════════════════════
# ── MACOS-ONLY ────────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════

install_macos() {
  section "macOS — Installation"

  # macOS : Homebrew refuse root
  if [[ $EUID -eq 0 ]]; then
    err "Ne pas lancer en root sur macOS. Utilisez : bash <(curl -fsSL ...)"
  fi

  local MODELFILE_PATH="$REAL_HOME/.kalicorp/Modelfile.kali-lite"
  local LOG_DIR="$REAL_HOME/Library/Logs/kalicorp"
  local PID_FILE="$REAL_HOME/Library/kalicorp/ollama.pid"

  mkdir -p "$LOG_DIR" "$(dirname "$PID_FILE")"

  # --- Homebrew check ---
  section "0 — Homebrew"
  if ! command -v brew &>/dev/null; then
    err "Homebrew requis. Installez-le d'abord : https://brew.sh"
  fi
  ok "Homebrew : $(brew --version | head -1)"

  # --- 1. Ollama ---
  section "1 — Ollama"
  if command -v ollama &>/dev/null; then
    warn "Ollama déjà installé : $(ollama --version)"
  else
    info "Installation d'Ollama via Homebrew..."
    brew install ollama
    ok "Ollama installé"
  fi

  # --- 2. Démarrage daemon Ollama ---
  section "2 — Daemon Ollama"
  if brew services list 2>/dev/null | grep -q "ollama.*started"; then
    warn "Service Ollama déjà actif (brew services)"
  else
    info "Démarrage d'Ollama..."
    brew services start ollama 2>/dev/null \
      || (nohup ollama serve > "$LOG_DIR/ollama.log" 2>&1 & echo $! > "$PID_FILE"; ok "Ollama lancé en bg")
  fi

  wait_for_ollama

  # --- 3. Modèle qwen3:8b ---
  section "3 — Modèle qwen3:8b"
  if ollama list 2>/dev/null | grep -q "qwen3:8b"; then
    warn "qwen3:8b déjà présent"
  else
    info "Téléchargement de qwen3:8b (~5.2 Go)..."
    ollama pull qwen3:8b
    ok "qwen3:8b téléchargé"
  fi

  # --- 4. GPU info ---
  section "4 — GPU"
  local gpu_info
  gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | awk -F: '{print $2}' | xargs)
  if [[ -n "$gpu_info" ]]; then
    ok "GPU détecté : $gpu_info"
  else
    warn "GPU non détecté — Ollama utilisera Metal/CPU"
  fi

  # --- 5. Node.js ---
  section "5 — Node.js"
  if command -v node &>/dev/null; then
    warn "Node.js déjà installé : $(node --version)"
  else
    info "Installation de Node.js via Homebrew..."
    brew install node
    ok "Node.js installé : $(node --version)"
  fi

  # --- 6. Modelfile + Modèle Ollama ---
  section "6 — Modelfile & Modèle Kali-Lite"
  setup_modelfile "$MODELFILE_PATH"
  create_ollama_model "$MODELFILE_PATH"

  # --- 7. CLAUDE.md ---
  section "7 — CLAUDE.md"
  setup_claude_md

  # --- 8. Claude Code ---
  section "8 — Claude Code"
  if command -v claude &>/dev/null; then
    warn "Claude Code déjà installé : $(claude --version 2>/dev/null)"
  else
    info "Installation de Claude Code via npm..."
    npm install -g @anthropic-ai/claude-code
    ok "Claude Code installé"
  fi

  # --- 9. Alias ---
  section "9 — Alias kali-lite"
  setup_alias "$MODELFILE_PATH"

  # --- Résumé ---
  print_summary "$MODELFILE_PATH"
}

# ══════════════════════════════════════════════════════════════════════════════
# ── MAIN ──────────────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════

echo "========================================"
echo " Kalicorp Hardening — Kali-Lite"
echo " GPL-2.0 | Zero cloud | Zero tracking"
echo " Linux + macOS"
echo "========================================"
echo ""

detect_os
detect_real_user
check_common_prereqs

case "$OS_TYPE" in
  linux)  install_linux  ;;
  macos)  install_macos  ;;
esac
