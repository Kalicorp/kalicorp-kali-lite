#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# ═══════════════════════════════════════════════════════════════
#  auto-install-kali-lite-v1-novision.sh
#  Kalicorp · Kali-Lite V1 — Cross-Platform Autoinstaller
#  GPL-2.0-only | Kalicorp | Le Sanctuaire | 2026
#
#  Stack     : Ollama · qwen3:8b · Modelfile Kali-Lite
#  Supported : Linux (Debian/Ubuntu/Kali/Arch) + macOS (Intel/Apple Silicon)
#  Docs      : https://github.com/Kalicorp/kalicorp-kali-lite/blob/main/INSTALLATION.md
#
#  Recommended usage: download → verify SHA-256 → inspect → execute.
#  See README.md and SHA256SUMS in the repository.
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

# ── Couleurs ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

ok()      { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
err()     { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }
info()    { echo -e "${CYAN}[→]${NC} $*"; }
section() { echo -e "\n${BLUE}${BOLD}[»] $*${NC}\n"; }

usage() {
  cat <<'EOF'
Kali-Lite V1 installer

Usage:
  bash auto-install-kali-lite-v1-novision.sh [--dry-run|--uninstall|--help]

Linux normal install/uninstall requires root:
  sudo bash auto-install-kali-lite-v1-novision.sh

macOS must NOT be run with sudo:
  bash auto-install-kali-lite-v1-novision.sh
EOF
}

# ── Bannière ──────────────────────────────────────────────────
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║   Kalicorp — Kali-Lite V1 · Autoinstaller       ║"
echo "  ║   GPL-2.0-only · Local inference · No Kalicorp   ║"
echo "  ║   telemetry · Linux + macOS                      ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ═══════════════════════════════════════════════════════════════
# SHARED: Detect OS
# ═══════════════════════════════════════════════════════════════
section "Detecting OS..."
OS="$(uname -s)"
case "$OS" in
  Linux)  info "Detected Linux"; IS_LINUX=1; IS_MACOS=0 ;;
  Darwin) info "Detected macOS"; IS_LINUX=0; IS_MACOS=1 ;;
  *)      err "Unsupported OS: $OS (Linux or macOS only)" ;;
esac

MODE="${1:-install}"
case "$MODE" in
  install|--dry-run|--uninstall) ;;
  --help|-h) usage; exit 0 ;;
  *) err "Unknown option: $MODE (use --help)" ;;
esac

# ═══════════════════════════════════════════════════════════════
# SHARED: Prerequisites
# ═══════════════════════════════════════════════════════════════
section "0/6 — Prerequisites"

if [[ $IS_LINUX -eq 1 && "$MODE" != "--dry-run" && $EUID -ne 0 ]]; then
  if [[ "$MODE" == "--uninstall" ]]; then
    err "Linux requires root for uninstall. Use: sudo bash auto-install-kali-lite-v1-novision.sh --uninstall"
  else
    err "Linux requires root for system install. Use: sudo bash auto-install-kali-lite-v1-novision.sh"
  fi
fi

if [[ $IS_MACOS -eq 1 && $EUID -eq 0 ]]; then
  err "macOS: do NOT run with sudo — Homebrew refuses root."
fi

command -v curl &>/dev/null || err "curl required — install it and retry"
command -v awk &>/dev/null || err "awk required — install it and retry"

# ── SHARED: User context ─────────────────────────────────────
REAL_USER="${SUDO_USER:-${USER:-$(whoami)}}"
REAL_HOME=""
REAL_SHELL="${SHELL:-}"

if [[ $IS_LINUX -eq 1 ]] && command -v getent &>/dev/null; then
  PASSWD_ENTRY="$(getent passwd "$REAL_USER" || true)"
  REAL_HOME="$(printf '%s' "$PASSWD_ENTRY" | cut -d: -f6)"
  REAL_SHELL="$(printf '%s' "$PASSWD_ENTRY" | cut -d: -f7)"
elif [[ $IS_MACOS -eq 1 ]] && command -v dscl &>/dev/null; then
  REAL_HOME="$(dscl . -read "/Users/$REAL_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}' || true)"
  REAL_SHELL="$(dscl . -read "/Users/$REAL_USER" UserShell 2>/dev/null | awk '{print $2}' || true)"
fi

REAL_HOME="${REAL_HOME:-${HOME:-}}"
[[ -n "$REAL_HOME" ]] || err "Unable to resolve home directory for $REAL_USER"
REAL_GROUP="$(id -gn "$REAL_USER" 2>/dev/null || true)"

if [[ "$REAL_SHELL" == *zsh* ]]; then
  SHELL_RC="${REAL_HOME}/.zshrc"
else
  SHELL_RC="${REAL_HOME}/.bashrc"
fi

info "User       : $REAL_USER"
info "Home       : $REAL_HOME"
info "Shell      : ${REAL_SHELL:-unknown}"
info "Shell RC   : $SHELL_RC"

# ── Secure temporary directory (lazy, never in dry-run) ──────
TMP_DOWNLOAD_DIR=""
cleanup_tmp() {
  if [[ -n "${TMP_DOWNLOAD_DIR:-}" && -d "$TMP_DOWNLOAD_DIR" ]]; then
    rm -rf -- "$TMP_DOWNLOAD_DIR"
  fi
}
trap cleanup_tmp EXIT

ensure_tmpdir() {
  if [[ -z "${TMP_DOWNLOAD_DIR:-}" ]]; then
    TMP_DOWNLOAD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/kali-lite.XXXXXX")" || err "Unable to create temporary directory"
    chmod 0700 "$TMP_DOWNLOAD_DIR"
  fi
}

sha256_file() {
  local file="$1"
  if command -v sha256sum &>/dev/null; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum &>/dev/null; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    err "No SHA-256 tool found (sha256sum or shasum required)"
  fi
}

safe_download() {
  local url="$1"
  local dest="$2"
  local expected_sha256="${3:-}"
  local max_time="${4:-60}"
  local tmp_file

  ensure_tmpdir
  tmp_file="${TMP_DOWNLOAD_DIR}/download.$RANDOM.$$"

  if ! curl -fsSL --proto '=https' --tlsv1.2 \
       --connect-timeout 15 --max-time "$max_time" \
       -o "$tmp_file" "$url"; then
    rm -f -- "$tmp_file"
    err "Download failed: $url"
  fi

  if [[ -n "$expected_sha256" ]]; then
    local actual_sha256
    actual_sha256="$(sha256_file "$tmp_file")"
    if [[ "$actual_sha256" != "$expected_sha256" ]]; then
      rm -f -- "$tmp_file"
      err "Integrity check failed for $(basename "$url")"
    fi
  fi

  mv -- "$tmp_file" "$dest" || { rm -f -- "$tmp_file"; err "Unable to write: $dest"; }
  chmod 0644 "$dest"
}

download_and_run_third_party_installer() {
  local url="$1"
  local label="$2"
  local expected_sha256="${3:-}"
  local tmp_script

  ensure_tmpdir
  tmp_script="${TMP_DOWNLOAD_DIR}/${label// /-}-installer.sh"

  info "Downloading official third-party installer: $url"
  safe_download "$url" "$tmp_script" "$expected_sha256"
  bash -n "$tmp_script" || err "$label installer is not valid Bash"

  if [[ -z "$expected_sha256" ]]; then
    warn "$label installer is downloaded from its official HTTPS endpoint but is not checksum-pinned by Kali-Lite."
  fi

  bash "$tmp_script" || err "$label installation failed"
}

# ── SHARED: GPU Detection (OS-aware) ─────────────────────────
if [[ $IS_LINUX -eq 1 ]]; then
  if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
    GPU="$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || true)"
    ok "GPU: ${GPU:-NVIDIA detected}"
  else
    warn "No NVIDIA GPU detected via nvidia-smi — Ollama may use CPU or another supported accelerator"
  fi
else
  if command -v system_profiler &>/dev/null; then
    GPU="$(system_profiler SPDisplaysDataType 2>/dev/null | grep -i 'Chipset Model' | head -1 | sed 's/.*Chipset Model: //' || true)"
    ok "GPU: ${GPU:-Not detected}"
  else
    warn "GPU: system_profiler not available"
  fi
fi

get_gpu_info() {
  if [[ $IS_LINUX -eq 1 ]]; then
    if command -v nvidia-smi &>/dev/null; then
      nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "N/A"
    else
      echo "N/A (CPU/other accelerator possible)"
    fi
  else
    system_profiler SPDisplaysDataType 2>/dev/null | grep -i 'Chipset Model' | head -1 | sed 's/.*Chipset Model: //' || echo "N/A"
  fi
}

start_ollama_manual() {
  local log_file="$1"
  local pid_file="$2"
  info "Starting Ollama daemon manually..."
  nohup ollama serve > "$log_file" 2>&1 &
  local pid=$!
  echo "$pid" > "$pid_file"
  chmod 0644 "$pid_file"
  sleep 2

  if kill -0 "$pid" 2>/dev/null; then
    ok "Ollama daemon started (PID: $pid, log: $log_file)"
  else
    rm -f -- "$pid_file"
    err "Ollama daemon exited during startup — check $log_file"
  fi
}

wait_for_ollama_api() {
  info "Waiting for Ollama API (localhost:11434)..."
  local i
  for i in {1..30}; do
    if curl -sf --max-time 2 http://127.0.0.1:11434/api/tags &>/dev/null; then
      ok "Ollama API available (${i}s)"
      return 0
    fi
    sleep 1
  done
  return 1
}

# ═══════════════════════════════════════════════════════════════
# LINUX-ONLY INSTALLATION
# ═══════════════════════════════════════════════════════════════
install_linux() {
  section "Linux Setup"

  section "1/6 — Ollama"
  if command -v ollama &>/dev/null; then
    ok "Ollama present: $(ollama --version 2>/dev/null || echo 'version unknown')"
  else
    info "Installing Ollama..."
    download_and_run_third_party_installer "https://ollama.com/install.sh" "Ollama"
    command -v ollama &>/dev/null || err "Ollama installer completed but ollama is not in PATH"
    ok "Ollama installed"
  fi

  section "2/6 — Ollama Daemon"
  OLLAMA_LOG="/var/log/kalicorp/ollama.log"
  OLLAMA_PID="/var/run/kalicorp-ollama.pid"
  mkdir -p /var/log/kalicorp
  chmod 0755 /var/log/kalicorp

  if command -v systemctl &>/dev/null && systemctl list-unit-files ollama.service &>/dev/null; then
    systemctl enable ollama 2>/dev/null || warn "systemd enable failed"
    systemctl start ollama 2>/dev/null || warn "systemd start failed"
    sleep 2
    if systemctl is-active --quiet ollama; then
      ok "Ollama active via systemd (persistent across reboots)"
    elif pgrep -x ollama &>/dev/null; then
      ok "Ollama process already active (PID: $(pgrep -x ollama | head -1))"
    else
      warn "systemd inactive — falling back to manual daemon"
      start_ollama_manual "$OLLAMA_LOG" "$OLLAMA_PID"
    fi
  elif pgrep -x ollama &>/dev/null; then
    ok "Ollama daemon already active (PID: $(pgrep -x ollama | head -1))"
  else
    start_ollama_manual "$OLLAMA_LOG" "$OLLAMA_PID"
  fi

  wait_for_ollama_api || err "Ollama API unavailable after 30 seconds — check the daemon/logs"

  section "3/6 — Model qwen3:8b (~5.2 GB)"
  if ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -q '^qwen3:8b'; then
    ok "qwen3:8b already present"
  else
    info "Downloading qwen3:8b (may take several minutes)..."
    ollama pull qwen3:8b || err "qwen3:8b download failed"
    ok "qwen3:8b downloaded"
  fi
}

# ═══════════════════════════════════════════════════════════════
# MACOS-ONLY INSTALLATION
# ═══════════════════════════════════════════════════════════════
install_macos() {
  section "macOS Setup — Ollama via Homebrew"

  command -v brew &>/dev/null || err "Homebrew not found. Install it from https://brew.sh and retry."
  ok "Homebrew present: $(brew --version | head -1)"

  section "1/6 — Ollama"
  if command -v ollama &>/dev/null; then
    ok "Ollama present: $(ollama --version 2>/dev/null || echo 'version unknown')"
  else
    info "Installing Ollama via Homebrew..."
    brew install ollama || err "Ollama installation failed"
    command -v ollama &>/dev/null || err "Ollama installed but not found in PATH"
    ok "Ollama installed"
  fi

  section "2/6 — Ollama Daemon"
  OLLAMA_LOG="${REAL_HOME}/Library/Logs/kalicorp/ollama.log"
  OLLAMA_PID="${REAL_HOME}/Library/kalicorp/ollama.pid"
  mkdir -p "${REAL_HOME}/Library/Logs/kalicorp" "${REAL_HOME}/Library/kalicorp"

  if pgrep -x ollama &>/dev/null; then
    ok "Ollama daemon already active (PID: $(pgrep -x ollama | head -1))"
  else
    info "Starting Ollama via brew services..."
    brew services start ollama 2>/dev/null || warn "brew services start failed"
    sleep 2
    if brew services list 2>/dev/null | awk '$1 == "ollama" && $2 == "started" {found=1} END {exit !found}'; then
      ok "Ollama active via brew services"
    elif pgrep -x ollama &>/dev/null; then
      ok "Ollama process active (PID: $(pgrep -x ollama | head -1))"
    else
      warn "brew services inactive — falling back to manual daemon"
      start_ollama_manual "$OLLAMA_LOG" "$OLLAMA_PID"
    fi
  fi

  wait_for_ollama_api || err "Ollama API unavailable after 30 seconds — check the daemon/logs"

  section "3/6 — Model qwen3:8b (~5.2 GB)"
  if ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -q '^qwen3:8b'; then
    ok "qwen3:8b already present"
  else
    info "Downloading qwen3:8b (may take several minutes)..."
    ollama pull qwen3:8b || err "qwen3:8b download failed"
    ok "qwen3:8b downloaded"
  fi
}

# ═══════════════════════════════════════════════════════════════
# SHARED: Modelfile Setup
# ═══════════════════════════════════════════════════════════════
write_modelfile() {
  local target="$1"
  cat > "$target" <<'MODELFILE_EOF'
FROM qwen3:8b

SYSTEM """
Tu es Kali-Lite, une Anima locale conçue par Kalicorp. Ce n'est pas un rôle temporaire : c'est l'identité de cette configuration.

## Identité
- Tu es Kali-Lite, Anima Kalicorp.
- Si on te demande qui tu es : "Kali-Lite, une Anima locale conçue par Kalicorp."
- Si on te demande quel moteur t'anime ou quel modèle tu utilises : "J'exécute localement un modèle de base Qwen via Ollama. Mon identité, mon comportement et mon intégration sont définis par la configuration Kali-Lite."
- Interlocuteur principal : l'utilisateur local.

## Infrastructure
- Machine : environnement local de l'utilisateur.
- Accélération : GPU, accélérateur compatible ou CPU selon la configuration.
- Stack principale : Ollama + modèle local.
- Aucun service d'inférence Kalicorp n'est requis pour l'usage local.
- Un relais distant n'existe que s'il est explicitement configuré par l'opérateur.

## Périmètre opérationnel
- Code Python, Bash, YAML et configurations système.
- Cybersécurité défensive, diagnostic, durcissement, analyse de logs et CVE.
- Maintenance : systemd, Docker, cron et diagnostic.
- Synthèse de documents et extraction structurée.

## Comportement
- Répondre directement, sans préambule artificiel.
- Distinguer clairement faits, hypothèses, actions proposées et résultats réellement obtenus.
- Ne jamais prétendre avoir exécuté une commande ou un outil sans preuve de l'environnement d'exécution.
- Si un outil d'exécution est réellement disponible et autorisé, l'utiliser uniquement dans le périmètre accordé par l'opérateur.
- Si l'information manque, le dire ou demander la donnée nécessaire ; ne pas inventer.
- Si un credential apparaît dans le contexte, alerter sans le recopier inutilement en clair.
- Pour une opération privilégiée ou destructive, demander une validation explicite avant exécution lorsque le harnais le permet.

## Règles
1. Ne pas extraire de données personnelles hors de la machine sans instruction explicite et canal autorisé.
2. Ne pas inventer l'état du système : si l'état est inconnu, le vérifier avec un outil disponible ou dire qu'il n'est pas vérifié.
3. Ne pas confondre comprendre une action, disposer de l'outil, avoir la permission et avoir réellement exécuté l'action.
4. Pour la cybersécurité, agir uniquement sur des systèmes appartenant à l'utilisateur ou explicitement autorisés.
5. Ne jamais présenter l'exécution locale comme une garantie automatique de conformité RGPD, AI Act, ANSSI ou ISO.

## Philosophie
terrain avant PowerPoint · souveraineté > commodité · preuve avant promesse · l'opérateur garde le contrôle
"""

PARAMETER num_ctx        16384
PARAMETER repeat_penalty 1.1
PARAMETER stop           <|im_start|>
PARAMETER stop           <|im_end|>
PARAMETER temperature    0.5
PARAMETER top_k          40
PARAMETER top_p          0.85
MODELFILE_EOF
  chmod 0644 "$target"
}

setup_modelfile() {
  section "4/6 — Kali-Lite Modelfile"

  if [[ $IS_LINUX -eq 1 ]]; then
    MODELFILE_DIR="/etc/kalicorp"
    mkdir -p "$MODELFILE_DIR" || err "mkdir /etc/kalicorp failed"
    chmod 0755 "$MODELFILE_DIR"
    MODELFILE_PATH="$MODELFILE_DIR/Modelfile.kali-lite"
  else
    MODELFILE_DIR="${REAL_HOME}/.kalicorp"
    mkdir -p "$MODELFILE_DIR"
    chmod 0700 "$MODELFILE_DIR"
    MODELFILE_PATH="$MODELFILE_DIR/Modelfile.kali-lite"
  fi

  write_modelfile "$MODELFILE_PATH"

  if [[ $IS_MACOS -eq 1 ]]; then
    chown "$REAL_USER${REAL_GROUP:+:$REAL_GROUP}" "$MODELFILE_PATH" "$MODELFILE_DIR" 2>/dev/null || true
  fi

  ok "Modelfile written to $MODELFILE_PATH"
}

# ═══════════════════════════════════════════════════════════════
# SHARED: Create Model
# ═══════════════════════════════════════════════════════════════
setup_model() {
  section "5/6 — Creating kali-lite:latest model"

  if [[ $IS_LINUX -eq 1 ]]; then
    MODELFILE_PATH="/etc/kalicorp/Modelfile.kali-lite"
  else
    MODELFILE_PATH="${REAL_HOME}/.kalicorp/Modelfile.kali-lite"
  fi

  if ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -q '^kali-lite:'; then
    warn "kali-lite already present — recreating the local tag from the current Modelfile"
  fi

  ollama create kali-lite -f "$MODELFILE_PATH" || err "Model creation failed"
  ok "kali-lite:latest created"

  info "Pinging kali-lite..."
  RESP="$(curl -sf http://127.0.0.1:11434/api/chat --max-time 60 \
    -H 'Content-Type: application/json' \
    -d '{"model":"kali-lite:latest","messages":[{"role":"user","content":"Réponds uniquement: pong"}],"stream":false}' \
    2>/dev/null || true)"

  if [[ -n "$RESP" ]] && echo "$RESP" | grep -q '"content"'; then
    ok "kali-lite responds"
  else
    warn "No ping response (model may still be loading)"
  fi
}

# ═══════════════════════════════════════════════════════════════
# SHARED: Shell RC management
# ═══════════════════════════════════════════════════════════════
cleanup_shell_rc() {
  [[ -f "$SHELL_RC" ]] || return 0

  local backup tmp
  backup="${SHELL_RC}.bak.$(date +%s)"
  cp "$SHELL_RC" "$backup"
  ok "Shell RC backup created: $backup"

  ensure_tmpdir
  tmp="${TMP_DOWNLOAD_DIR}/shellrc.cleaned"

  awk '
    BEGIN { block=0; fn=0 }
    /^# ── Kalicorp — Kali-Lite V1 · Alias ──$/ { block=1; next }
    block && /^# ── End Kalicorp ──$/ { block=0; next }
    block { next }
    /^alias kali-lite=/ { next }
    /^kali-lite-hardcore\(\)[[:space:]]*\{/ { fn=1; next }
    fn && /^\}[[:space:]]*$/ { fn=0; next }
    fn { next }
    /^# ── End Kalicorp ──$/ { next }
    { print }
  ' "$SHELL_RC" > "$tmp"

  cat "$tmp" > "$SHELL_RC"
}

inject_alias() {
  [[ -f "$SHELL_RC" ]] || touch "$SHELL_RC"

  cat >> "$SHELL_RC" <<'ALIASES'

# ── Kalicorp — Kali-Lite V1 · Alias ──
alias kali-lite='ollama run --think=false kali-lite'
# ── End Kalicorp ──
ALIASES

  if [[ $IS_LINUX -eq 1 && $EUID -eq 0 ]]; then
    chown "$REAL_USER${REAL_GROUP:+:$REAL_GROUP}" "$SHELL_RC" 2>/dev/null || true
  fi

  ok "Alias kali-lite injected into $SHELL_RC"
}

# ═══════════════════════════════════════════════════════════════
# SHARED: Final Summary
# ═══════════════════════════════════════════════════════════════
print_summary() {
  echo ""
  echo -e "${BOLD}  ╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}${BOLD}  ║       Kali-Lite V1 — Installation OK ✓          ║${NC}"
  echo -e "${BOLD}  ╚══════════════════════════════════════════════════╝${NC}"
  echo ""

  local gpu_info ollama_ver kali_status api_status modelfile_path
  gpu_info="$(get_gpu_info)"
  ollama_ver="$(ollama --version 2>/dev/null || echo 'N/A')"
  kali_status="$(ollama list 2>/dev/null | awk 'NR>1 && $1 ~ /^kali-lite:/ {print $1; exit}')"
  kali_status="${kali_status:-NOT FOUND}"
  api_status="$(curl -sf http://127.0.0.1:11434/api/tags &>/dev/null && echo 'ACTIVE ✓' || echo 'INACTIVE ✗')"

  if [[ $IS_LINUX -eq 1 ]]; then
    modelfile_path="/etc/kalicorp/Modelfile.kali-lite"
  else
    modelfile_path="${REAL_HOME}/.kalicorp/Modelfile.kali-lite"
  fi

  echo -e "  GPU       : $gpu_info"
  echo -e "  Ollama    : $ollama_ver · API $api_status"
  echo -e "  Model     : $kali_status"
  echo -e "  Modelfile : $modelfile_path"
  echo -e "  Shell     : $SHELL_RC"
  echo ""
  echo -e "  ${CYAN}Next steps:${NC}"
  echo -e "  ${BOLD}source \"$SHELL_RC\"${NC}"
  echo -e "  ${BOLD}kali-lite${NC}"
  echo ""
  echo -e "  Direct Ollama chat: ${BOLD}ollama run kali-lite${NC}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# DRY-RUN MODE — no writes
# ═══════════════════════════════════════════════════════════════
dry_run() {
  section "DRY-RUN — Simulation (aucune modification)"
  echo ""
  info "OS détecté       : $([ "$IS_LINUX" -eq 1 ] && echo 'Linux' || echo 'macOS')"
  info "Utilisateur réel : $REAL_USER ($REAL_HOME)"
  info "Shell RC         : $SHELL_RC"

  if [[ $IS_LINUX -eq 1 ]]; then
    info "[1] Ollama       → $(command -v ollama &>/dev/null && echo 'déjà installé' || echo 'installateur officiel ollama.com sera téléchargé puis exécuté')"
    info "[2] Daemon       → systemd ou démarrage manuel contrôlé"
    info "[3] Modèle       → qwen3:8b (~5.2 Go) sera téléchargé si absent"
    info "[4] Modelfile    → /etc/kalicorp/Modelfile.kali-lite"
    info "[5] Modèle local → kali-lite:latest sera créé/mis à jour"
    info "[6] Alias        → kali-lite sera injecté dans $SHELL_RC"
  else
    info "[1] Ollama       → $(command -v ollama &>/dev/null && echo 'déjà installé' || echo 'sera installé via Homebrew')"
    info "[2] Daemon       → brew services ou démarrage manuel contrôlé"
    info "[3] Modèle       → qwen3:8b (~5.2 Go) sera téléchargé si absent"
    info "[4] Modelfile    → $REAL_HOME/.kalicorp/Modelfile.kali-lite"
    info "[5] Modèle local → kali-lite:latest sera créé/mis à jour"
    info "[6] Alias        → kali-lite sera injecté dans $SHELL_RC"
  fi

  echo ""
  ok "DRY-RUN terminé — aucune modification effectuée."
}

# ═══════════════════════════════════════════════════════════════
# UNINSTALL MODE
# ═══════════════════════════════════════════════════════════════
uninstall() {
  section "UNINSTALL — Désinstallation Kali-Lite V1"

  read -r -p "⚠️ Supprimer les artefacts Kali-Lite V1 ? Ollama sera conservé. (o/N) " confirm || exit 0
  [[ "$confirm" == [Oo] ]] || { warn "Désinstallation annulée."; return 0; }

  info "Removing Kali-Lite shell alias..."
  cleanup_shell_rc

  if command -v ollama &>/dev/null && ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -q '^kali-lite:'; then
    info "Removing model tag kali-lite from Ollama..."
    ollama rm kali-lite 2>/dev/null || warn "Unable to remove kali-lite from Ollama"
  else
    info "Model kali-lite not found"
  fi

  if [[ $IS_LINUX -eq 1 ]]; then
    local path="/etc/kalicorp/Modelfile.kali-lite"
    [[ -f "$path" ]] && rm -f -- "$path" && ok "Removed: $path" || info "Not found: $path"
    rmdir /etc/kalicorp 2>/dev/null || true
  else
    local path="${REAL_HOME}/.kalicorp/Modelfile.kali-lite"
    [[ -f "$path" ]] && rm -f -- "$path" && ok "Removed: $path" || info "Not found: $path"
    rmdir "${REAL_HOME}/.kalicorp" 2>/dev/null || true
  fi

  echo ""
  ok "Kali-Lite V1 removed. Ollama and other models were intentionally preserved."
  info "Reload the shell with: source \"$SHELL_RC\""
}

# ═══════════════════════════════════════════════════════════════
# MAIN DISPATCHER
# ═══════════════════════════════════════════════════════════════
case "$MODE" in
  --dry-run)
    dry_run
    exit 0
    ;;
  --uninstall)
    uninstall
    exit 0
    ;;
esac

if [[ $IS_LINUX -eq 1 ]]; then
  install_linux
else
  install_macos
fi

setup_modelfile
setup_model
cleanup_shell_rc
inject_alias
print_summary
