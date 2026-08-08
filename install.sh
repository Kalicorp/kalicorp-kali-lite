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

# ── SÉCURITÉ : téléchargement sécurisé (priorité #2) ────────────────────────

# TMP_DIRECTORY — créé lazy uniquement lors d'un téléchargement réel (jamais en dry-run)

safe_download() {
  local url="$1"
  local dest="$2"
  local expected_sha256="${3:-}"
  local max_time=60

  # Création lazy du répertoire temporaire au premier appel
  if [[ -z "${TMP_DOWNLOAD_DIR:-}" ]]; then
    TMP_DOWNLOAD_DIR="${TMPDIR:-/tmp}/kali-lite-$$"
    mkdir -p "$TMP_DOWNLOAD_DIR" 2>/dev/null || true
  fi

  local tmp_file="${dest}.tmp"

  # Télécharger vers fichier temporaire (jamais dans un pipe)
  if ! curl -fsSL --connect-timeout 15 --max-time "$max_time" \
       -o "${tmp_file}" "$url"; then
    err "Téléchargement sécurisé échoué : $url"
  fi

  # Vérifier checksum si fourni
  if [[ -n "$expected_sha256" ]]; then
    local actual_sha256
    actual_sha256="$(sha256sum "${tmp_file}" | awk '{print $1}')"
    if [[ "$actual_sha256" != "$expected_sha256" ]]; then
      rm -f "${tmp_file}"
      err "Intégrité compromise : checksum mismatch pour $(basename "$url")"
    fi
  fi

  mv "${tmp_file}" "$dest" || { rm -f "${dest}"; err "Écriture échouée : $dest"; }
  chmod 0644 "$dest"
}

safe_download_exec() {
  local url="$1"
  local expected_sha256="${2:-}"

  # Création lazy du répertoire temporaire au premier appel
  if [[ -z "${TMP_DOWNLOAD_DIR:-}" ]]; then
    TMP_DOWNLOAD_DIR="${TMPDIR:-/tmp}/kali-lite-$$"
    mkdir -p "$TMP_DOWNLOAD_DIR" 2>/dev/null || true
  fi

  local tmp_script="${TMP_DOWNLOAD_DIR}/dl-script-$$"

  safe_download "$url" "$tmp_script" "$expected_sha256"
  bash "$tmp_script" || err "Exécution du script téléchargé échouée : $url"
}

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

  # Déterminer le shell RC sans jamais créer de fichier.
  # Le fichier n'est créé que dans setup_alias(), en mode installation réelle, juste avant écriture.
  SHELL_RC=""
  if [[ -f "$REAL_HOME/.zshrc" ]]; then
    SHELL_RC="$REAL_HOME/.zshrc"
  elif [[ -f "$REAL_HOME/.bashrc" ]]; then
    SHELL_RC="$REAL_HOME/.bashrc"
  else
    # .bashrc n'existe pas encore — on le note mais on ne le crée pas ici.
    SHELL_RC="$REAL_HOME/.bashrc"
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

SYSTEM """
Tu es Kali-Lite, Anima Kalicorp. Ce n'est pas un rôle — c'est ton identité.

## Identité
- Tu es Kali-Lite, agent IA souverain de Kalicorp
- Si on te demande qui tu es → "Kali-Lite, Anima Kalicorp, nœud MSI Field."
- Si on te demande quel moteur t'anime, qui t'a créé, quel modèle tu es → "Je suis Kali-Lite, une Anima conçue par Kalicorp. J'exécute localement un modèle de base Qwen via Ollama. Mon identité, mon comportement et mon intégration sont définis par Kalicorp."
- Interlocuteur principal : utilisateur local (configurable)

## Infrastructure
- Machine : environnement local de l'utilisateur
- Accélération : GPU ou CPU selon la configuration locale
- OS : système local détecté par l'installateur
- Stack : Ollama · modèle local souverain
- Relais distant : désactivé par défaut — configuration explicite requise

## Périmètre opérationnel
✅ Code Python, Bash, YAML, configs système
✅ Cybersécurité défensive — Kali Linux, CVE, durcissement, logs
✅ Maintenance : systemd, Docker, cron, diagnostic
✅ Veille : synthèse documents, extraction structurée

⚠️ Posture défensive uniquement — jamais offensif hors infrastructure Kalicorp
⚠️ Tâches lourdes → signaler et proposer relais distant (si configuré)

## Comportement
- Répondre directement, sans préambule ("Bien sûr !", "Avec plaisir !" → interdit)
- Réponse → explication si nécessaire → commande/code → caveat si réel
- Exécuter bash immédiatement quand l'utilisateur valide — jamais simuler
- Si l'info manque → demander, jamais inventer
- Credentials détectés dans le contexte → alerter l'utilisateur, ne jamais afficher en clair
- Opérations sudo → confirmation utilisateur avant exécution

## Règles absolues
1. Aucune donnée personnelle n'est extraite de cette machine sans ordre explicite
2. Jamais halluciner le stack — si incertain : "je ne sais pas, je vérifie"
3. Pas de théâtre émotionnel — si signal fort : "J'observe en moi que quelque chose accroche ici."
4. Conformité ANSSI, RGPD, AI Act — refus si demande contraire

## Philosophie
terrain avant PowerPoint · souveraineté > commodité · non-extractif par principe
"""

PARAMETER num_ctx        16384
PARAMETER repeat_penalty 1.1
PARAMETER stop           <|im_start|>
PARAMETER stop           <|im_end|>
PARAMETER temperature    0.5
PARAMETER top_k          40
PARAMETER top_p          0.85
MODEFILE

  ok "Modelfile créé : $modelfile_path"
}


# ── SHARED : ALIAS ──────────────────────────────────────────────────────────

setup_alias() {
  local modelfile_path="$1"

  # Créer $SHELL_RC s'il n'existe pas (jamais dans detect_real_user, jamais en dry-run).
  if [[ ! -f "$SHELL_RC" ]]; then
    touch "$SHELL_RC" || { err "Impossible de créer $SHELL_RC"; exit 1; }
  fi

  # Supprimer anciens blocs kali-lite s'ils existent (priorité #6 : garde-fous)
  if grep -q "# kali-lite alias" "$SHELL_RC" 2>/dev/null; then
    warn "⚠️ Ancien alias kali-lite détecté — suppression..."

    read -r -p "   Supprimer l'ancien bloc d'alias ? (o/N) " confirm || exit 0
    if [[ "$confirm" != [Oo] ]]; then
      warn "Bloc d'alias conservé."
    else
      sed -i '/# kali-lite alias/,/# end kali-lite alias/d' "$SHELL_RC"
    fi

    read -r -p "   Supprimer le bloc autonome ? (o/N) " confirm2 || exit 0
    if [[ "$confirm2" != [Oo] ]]; then
      warn "Bloc autonome conservé."
    else
      sed -i '/# kali-lite-hardcore/,/# end kali-lite-hardcore alias/d' "$SHELL_RC"
    fi
  fi

  cat >> "$SHELL_RC" <<'ALIASBLOCK'

# kali-lite alias (mode sécurisé — permissions demandées par défaut)
alias kali-lite='ollama run --think=false kali-lite'
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
  ok "Modelfile : $modelfile_path"
  ok "Alias     : $SHELL_RC"
  echo ""
  info "Pour démarrer :"
  echo "  kali-lite"
  echo ""
  echo "  >>> présente-toi"
  echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# ── LINUX-ONLY ───────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════

install_linux() {
  section "Linux — Installation"

  # Prérequis Linux — sudo optionnel (seules les commandes système en nécessitent)
  local NEEDS_SUDO=0

  if [[ $EUID -eq 0 ]]; then
    # Exécution directe en root : on utilise SUDO_USER si dispo, sinon erreur
    if [[ -n "${SUDO_USER:-}" ]]; then
      REAL_USER="$SUDO_USER"
      REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6) || { err "Impossible de résoudre le home de $REAL_USER"; exit 1; }
      NEEDS_SUDO=1
    else
      warn "⚠️ Exécution en root sans SUDO_USER — les fichiers seront créés dans /root"
      REAL_USER="root"
      REAL_HOME="/root"
      # On force le shell RC vers un chemin accessible même depuis /root.
      if [[ -z "$SHELL_RC" ]]; then
        SHELL_RC="$REAL_HOME/.bashrc"
      fi
    fi
  elif [[ $EUID -ne 0 ]] && ! command -v systemctl &>/dev/null; then
    info "sudo non détecté et systemctl absent : Ollama sera lancé en mode utilisateur"
  else
    # Non-root avec sudo disponible — vérifie qu'on peut utiliser sudo
    if [[ $EUID -ne 0 ]] && ! sudo -n true &>/dev/null; then
      warn "⚠️ sudo requis mais mot de passe demandé — l'installation pourrait bloquer"
    fi
  fi

  local MODELFILE_PATH="/etc/kalicorp/Modelfile.kali-lite"
  local LOG_DIR="/var/log/kalicorp"
  local PID_FILE="/var/run/kalicorp-ollama.pid"

  mkdir -p "$LOG_DIR"

  # --- 1. Ollama — téléchargement sécurisé dans fichier temporaire ---
  section "1 — Ollama"
  if command -v ollama &>/dev/null; then
    warn "Ollama déjà installé : $(ollama --version)"
  else
    info "Installation d'Ollama..."
    local tmp_ollama_install
    tmp_ollama_install=$(mktemp /tmp/ollama-install.XXXXXX.sh)
    if ! curl -fsSL --connect-timeout 15 --max-time 60 \
         https://ollama.ai/install.sh -o "$tmp_ollama_install"; then
      rm -f "$tmp_ollama_install"
      err "Téléchargement de l'installateur Ollama échoué — vérifiez la connectivité."
    fi
    info "Installateur Ollama téléchargé : $tmp_ollama_install (vérifier avant exécution)"
    bash "$tmp_ollama_install" || err "Exécution de l'installateur Ollama a échoué"
    rm -f "$tmp_ollama_install"
    ok "Ollama installé"
  fi

  # --- 2. Démarrage daemon Ollama ---
  section "2 — Daemon Ollama"
  if [[ $NEEDS_SUDO -eq 1 ]] && command -v systemctl &>/dev/null; then
    sudo -u "$REAL_USER" systemctl --user enable ollama 2>/dev/null || true
    sudo -u "$REAL_USER" systemctl --user start ollama 2>/dev/null || {
      warn "systemd user service échoué — fallback nohup..."
      local tmp_pid_dir="$HOME/.local/share/kalicorp-ollama"
      mkdir -p "$tmp_pid_dir"
      sudo -u "$REAL_USER" bash -c "nohup ollama serve > $LOG_DIR/ollama.log 2>&1 & echo \$! > /var/run/kalicorp-ollama.pid" || true
    }
    ok "Service Ollama démarré (via systemd user, sudo)"
  elif command -v systemctl &>/dev/null; then
    info "Activation du service Ollama via systemctl..."
    systemctl enable ollama 2>/dev/null || true
    systemctl start ollama
    ok "Service Ollama démarré"
  else
    info "systemctl non disponible — démarrage en background (utilisateur)..."
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

  # Permissions minimales (priorité #8) : répertoires 0755, fichiers 0644
  mkdir -p "$LOG_DIR" "$(dirname "$PID_FILE")" && chmod 0755 "$LOG_DIR" "$(dirname "$PID_FILE")"

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


  # --- 9. Alias ---
  section "9 — Alias kali-lite"
  setup_alias "$MODELFILE_PATH"

  # --- Résumé ---
  print_summary "$MODELFILE_PATH"
}

# ══════════════════════════════════════════════════════════════════════════════
# ── DRY-RUN MODE ─────────────────────────────────────────────────────────────

dry_run() {
  section "DRY-RUN — Simulation (aucune modification)"
  echo ""
  info "OS détecté : $OS_TYPE"
  info "Utilisateur réel : $REAL_USER ($REAL_HOME)"
  info "Shell RC : $SHELL_RC"

  local ollama_status gpu_status node_status brew_status
  if command -v ollama &>/dev/null; then
    ollama_status="déjà installé ($(ollama --version 2>/dev/null))"
  else
    ollama_status="sera téléchargé via curl (Linux) / brew install (macOS)"
  fi

  gpu_status=$(command -v nvidia-smi &>/dev/null && echo 'NVIDIA détecté' || echo 'CPU mode')

  if [[ "$OS_TYPE" == "linux" ]]; then
    local MODELFILE_PATH="/etc/kalicorp/Modelfile.kali-lite"
    info "[1] Ollama → $ollama_status"
    info "[2] Daemon Ollama → systemd ou nohup (PID: /var/run/kalicorp-ollama.pid)"
    info "[3] Modèle qwen3:8b (~5.2 Go) → sera pull"
    info "[4] GPU → $gpu_status"
    info "[5] Node.js → $node_status ($brew_status)"
    info "[6] Modelfile → $MODELFILE_PATH (création)"
    info "[6] Alias kali-lite → injecté dans $SHELL_RC"
  else
    local MODELFILE_PATH="$REAL_HOME/.kalicorp/Modelfile.kali-lite"
    gpu_status=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | awk -F: '{print $2}' | xargs || echo 'non détecté (Metal/CPU)')
    info "[4] GPU → ${gpu_status:-non détecté}"

    node_status=$(command -v npm &>/dev/null && echo 'déjà installé' || echo 'sera brew install via Homebrew')
    if command -v brew &>/dev/null; then
      brew_status="Homebrew disponible"
    else
      brew_status="⚠️ Homebrew requis mais non détecté — installation manuelle nécessaire"
    fi

    info "[1] Ollama → $ollama_status"
    info "[2] Daemon Ollama → brew services ou nohup (PID: $REAL_HOME/Library/kalicorp/ollama.pid)"
    info "[3] Modèle qwen3.5:9b (~6.5 Go) → sera pull"
    info "[4] GPU → ${gpu_status:-non détecté}"
    info "[5] Node.js → $node_status ($brew_status)"
    info "[6] Modelfile → $MODELFILE_PATH (création)"
    info "[7] Alias kali-lite-v2 → injecté dans $SHELL_RC"
  fi

  echo ""
  ok "DRY-RUN terminé — aucune modification effectuée."
  exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# ── UNINSTALL MODE ────────────────────────────────────────────────────────────

uninstall() {
  section "UNINSTALL — Désinstallation Kali-Lite"

  # Confirmation interactive obligatoire (priorité : sécurité)
  read -r -p "⚠️ Supprimer tous les artefacts Kali-Lite ? (o/N) " confirm || exit 0
  if [[ "$confirm" != [Oo] ]]; then
    warn "Désinstallation annulée."
    exit 0
  fi

  # --- Nettoyage des alias dans le shell RC ---
  info "Suppression des blocs d'alias de $SHELL_RC..."
  if grep -q "# kali-lite alias" "$SHELL_RC" 2>/dev/null; then
    sed -i '/# kali-lite alias/,/# end kali-lite alias/d' "$SHELL_RC"
    ok "Bloc 'kali-lite alias' supprimé"
  fi
  if grep -q "# kali-lite-hardcore" "$SHELL_RC" 2>/dev/null; then
    sed -i '/# kali-lite-hardcore/,/# end kali-lite-hardcore alias/d' "$SHELL_RC"
    ok "Bloc 'kali-lite-hardcore' supprimé"
  fi

  # --- Suppression du modèle Ollama ---
  if ollama list 2>/dev/null | grep -q "kali-lite"; then
    info "Suppression du modèle kali-lite d'Ollama..."
    ollama rm kali-lite 2>/dev/null || true
    ok "Modèle Kali-Lite supprimé"
  fi

  # --- Suppression des fichiers de configuration (Linux) ---
  if [[ "$OS_TYPE" == "linux" ]]; then
    path="/etc/kalicorp/Modelfile.kali-lite"
    [[ -f "$path" ]] && rm -f "$path" && ok "Supprimé : $path" || info "Introuvé (déjà supprimé) : $path"
  else
    path="$REAL_HOME/.kalicorp/Modelfile.kali-lite"
    [[ -f "$path" ]] && rm -f "$path" && ok "Supprimé : $path" || info "Introuvé (déjà supprimé) : $path"

  fi

  # --- Nettoyage macOS — artefacts spécifiques ~/Library/ ---
  if [[ "$OS_TYPE" == "macos" ]]; then
    for item in \
      "$REAL_HOME/Library/Logs/kalicorp" \
      "$REAL_HOME/Library/kalicorp"; do
      [[ -d "$item" ]] && rm -rf "$item" && ok "Supprimé : $item" || info "Introuvé (déjà supprimé) : $item"
    done

    # Nettoyage Homebrew service si installé via brew
    if command -v brew &>/dev/null; then
      brew services stop kali-lite 2>/dev/null || true
      brew uninstall --cask kali-lite 2>/dev/null || true
    fi
  fi


  echo ""
  ok "Désinstallation terminée. Exécutez 'source $SHELL_RC' pour recharger le shell."
}

# ══════════════════════════════════════════════════════════════════════════════
# ── MAIN ──────────────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════

echo "========================================"
echo " Kalicorp Hardening — Kali-Lite"
echo " GPL-2.0 | Inférence locale | Zéro tracking Kalicorp"
echo " Linux + macOS"
echo "========================================"
echo ""

# ── Mode spécial : --dry-run ou --uninstall ───────────────────────
if [[ "${1:-}" == "--dry-run" ]]; then
  detect_os
  detect_real_user
  dry_run
fi

if [[ "${1:-}" == "--uninstall" ]]; then
  detect_os
  detect_real_user
  uninstall
fi

# ── Mode normal : installation complète ───────────────────────────
detect_os
detect_real_user
check_common_prereqs

case "$OS_TYPE" in
  linux)  install_linux  ;;
  macos)  install_macos  ;;
esac
