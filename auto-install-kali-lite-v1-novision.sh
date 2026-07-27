#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  install-kali-lite-v1.sh
#  Kalicorp · Kali-Lite V1 — Cross-Platform Autoinstaller
#  GPL-2.0 | Kalicorp | Le Sanctuaire | 2026
#
#  Stack : Ollama · qwen3:8b · Modelfile Kali-Lite · Claude Code
#  Supported : Linux (Debian/Ubuntu/Kali/Arch) + macOS (Intel/Apple Silicon)
#https://github.com/balduregates1/kalicorp-kali-lite/blob/main/INSTALLATION.md
#  Usage :
#    Linux  : sudo bash <(curl -fsSL https://...install.sh)
#    macOS  : bash <(curl -fsSL https://...install.sh)  # NO sudo
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

# ── Couleurs ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

ok()      { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
err()     { echo -e "${RED}[✗]${NC} $*"; exit 1; }
info()    { echo -e "${CYAN}[→]${NC} $*"; }
section() { echo -e "\n${BLUE}${BOLD}[»] $*${NC}\n"; }

# ── Bannière ──────────────────────────────────────────────────
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║   Kalicorp — Kali-Lite V1 · Autoinstaller       ║"
echo "  ║   GPL-2.0  ·  Zero cloud  ·  Zero tracking      ║"
echo "  ║   Linux + macOS (Intel/Apple Silicon)           ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ═══════════════════════════════════════════════════════════════
# SHARED: Detect OS
# ═══════════════════════════════════════════════════════════════
section "Detecting OS..."
OS=$(uname -s)
case "$OS" in
  Linux)  info "Detected Linux"; IS_LINUX=1; IS_MACOS=0 ;;
  Darwin) info "Detected macOS"; IS_LINUX=0; IS_MACOS=1 ;;
  *)      err "Unsupported OS: $OS (Linux or macOS only)" ;;
esac

# ═══════════════════════════════════════════════════════════════
# SHARED: Prerequisites
# ═══════════════════════════════════════════════════════════════
section "0/6 — Prerequisites"

# ── LINUX-ONLY: sudo check (priorité #7 : privilèges réduits) ──
if [[ $IS_LINUX -eq 1 && "${1:-}" != "--dry-run" ]]; then
    if [[ $EUID -ne 0 ]]; then
        err "Linux requires root for system install. Use: sudo bash <(curl ...)"
    fi
fi

# ── MACOS-ONLY: warn about sudo (priorité #7) ──
if [[ $IS_MACOS -eq 1 ]]; then
    if [[ $EUID -eq 0 ]]; then
        err "macOS: Do NOT run with sudo — Homebrew refuses root. Use: bash install.sh"
    fi
fi

command -v curl &>/dev/null || err "curl required — install and retry"

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

  if ! curl -fsSL --connect-timeout 15 --max-time "$max_time" \
       -o "${tmp_file}" "$url"; then
    err "Téléchargement sécurisé échoué : $url"
  fi

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

# ── SHARED: User context ──
REAL_USER="${SUDO_USER:-${USER:-$(whoami)}}"
if [[ $IS_LINUX -eq 1 ]] && command -v getent &>/dev/null; then
    REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
elif [[ $IS_MACOS -eq 1 ]] && command -v dscl &>/dev/null; then
    REAL_HOME="$(dscl . -read "/Users/$REAL_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
else
    REAL_HOME="$HOME"
fi
[[ -n "$REAL_HOME" ]] || err "Unable to resolve home directory for $REAL_USER"
SHELL_RC="${REAL_HOME}/.bashrc"
[[ "$SHELL" == *zsh* ]] && SHELL_RC="${REAL_HOME}/.zshrc"

info "User       : $REAL_USER"
info "Home       : $REAL_HOME"
info "Shell RC   : $SHELL_RC"

# ── SHARED: GPU Detection (OS-aware) ──
if [[ $IS_LINUX -eq 1 ]]; then
    if nvidia-smi &>/dev/null; then
        GPU=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null)
        ok "GPU: $GPU"
    else
        warn "GPU: nvidia-smi not found — will run in CPU mode"
    fi
fi

if [[ $IS_MACOS -eq 1 ]]; then
    if command -v system_profiler &>/dev/null; then
        GPU=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -i chipset | head -1 | sed 's/.*Chipset Model: //' || echo "Not detected")
        ok "GPU: $GPU"
    else
        warn "GPU: system_profiler not available"
    fi
fi

# ── SHARED: Personal Claude config detection (priorité #5 : jamais de valeur en clair) ──
PERSO_FOUND=0
if [[ -f "$SHELL_RC" ]]; then
    if grep -q "^export ANTHROPIC_API_KEY=" "$SHELL_RC" 2>/dev/null; then
        PERSO_FOUND=1
        warn "Personal Claude config detected — will preserve (valeur non lue)"
    else
        ok "No personal Claude config — clean install"
    fi
fi

# ═══════════════════════════════════════════════════════════════
# SHARED FUNCTION: GPU info for summary
# ═══════════════════════════════════════════════════════════════
get_gpu_info() {
    if [[ $IS_LINUX -eq 1 ]]; then
        nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "N/A (CPU mode)"
    elif [[ $IS_MACOS -eq 1 ]]; then
        system_profiler SPDisplaysDataType 2>/dev/null | grep -i chipset | head -1 | sed 's/.*Chipset Model: //' || echo "N/A"
    fi
}

# ═══════════════════════════════════════════════════════════════
# LINUX-ONLY INSTALLATION
# ═══════════════════════════════════════════════════════════════
install_linux() {
    section "Linux Setup — Ollama via curl"

    # ── 1. OLLAMA ──
    section "1/6 — Ollama"
    if command -v ollama &>/dev/null; then
        ok "Ollama present: $(ollama --version 2>/dev/null)"
    else
        info "Installing Ollama..."
        safe_download_exec "https://ollama.com/install.sh" || err "Ollama installation failed"
        ok "Ollama installed"
    fi

    # ── 2. DAEMON OLLAMA ──
    section "2/6 — Ollama Daemon"
    OLLAMA_LOG="/var/log/kalicorp/ollama.log"
    OLLAMA_PID="/var/run/kalicorp-ollama.pid"
    sudo mkdir -p /var/log/kalicorp

    if command -v systemctl &>/dev/null && systemctl list-unit-files ollama.service &>/dev/null 2>&1; then
        sudo systemctl enable ollama 2>/dev/null || warn "systemd enable failed"
        sudo systemctl start ollama 2>/dev/null || warn "systemd start failed"
        sleep 2
        if sudo systemctl is-active --quiet ollama; then
            ok "Ollama active via systemd (persistent across reboots)"
        else
            warn "systemd inactive — starting manually..."
            bash -c "nohup ollama serve > $OLLAMA_LOG 2>&1 & echo \$!" | sudo tee "$OLLAMA_PID" >/dev/null
            echo $! | sudo tee "$OLLAMA_PID" > /dev/null
            ok "Daemon started (PID: $!, log: $OLLAMA_LOG)"
            sleep 3
        fi
    else
        if pgrep -x ollama &>/dev/null; then
            ok "Ollama daemon already active (PID: $(pgrep -x ollama))"
        else
            info "Starting Ollama daemon manually..."
            nohup ollama serve > "$OLLAMA_LOG" 2>&1 &
            echo $! > "$OLLAMA_PID"
            ok "Daemon started (PID: $!, log: $OLLAMA_LOG)"
            sleep 3
        fi
    fi

    # ── API Wait ──
    info "Waiting for Ollama API (localhost:11434)..."
    for i in {1..20}; do
        curl -sf http://localhost:11434/api/tags &>/dev/null && { ok "API available (${i}s)"; break; }
        sleep 1
        [[ $i -eq 20 ]] && warn "API not available after 20s — check logs"
    done

    # ── 3. qwen3:8b ──
    section "3/6 — Model qwen3:8b (~5.2 GB)"
    if ollama list 2>/dev/null | grep -q "^qwen3.*8b"; then
        ok "qwen3:8b already present"
    else
        info "Downloading qwen3:8b (may take several minutes)..."
        ollama pull qwen3:8b || err "qwen3:8b download failed"
        ok "qwen3:8b downloaded"
    fi

    # ── 4. Node.js + npm ──
    info "Checking Node.js..."
    if ! command -v npm &>/dev/null; then
        info "npm not found — installing Node.js LTS..."
        safe_download_exec "https://deb.nodesource.com/setup_lts.x" || err "NodeSource setup failed"
        sudo apt-get install -y nodejs
    fi
}

# ═══════════════════════════════════════════════════════════════
# MACOS-ONLY INSTALLATION
# ═══════════════════════════════════════════════════════════════
install_macos() {
    section "macOS Setup — Ollama via Homebrew"

    # ── Check Homebrew ──
    if ! command -v brew &>/dev/null; then
        err "Homebrew not found. Install from https://brew.sh and retry."
    fi
    ok "Homebrew present: $(brew --version | head -1)"

    # ── 1. OLLAMA ──
    section "1/6 — Ollama"
    if command -v ollama &>/dev/null; then
        ok "Ollama present: $(ollama --version 2>/dev/null)"
    else
        info "Installing Ollama via Homebrew..."
        brew install ollama || err "Ollama installation failed"
        ok "Ollama installed"
    fi

    # ── 2. DAEMON OLLAMA ──
    section "2/6 — Ollama Daemon"
    OLLAMA_LOG="${REAL_HOME}/Library/Logs/kalicorp/ollama.log"
    OLLAMA_PID="${REAL_HOME}/Library/kalicorp/ollama.pid"
    mkdir -p "${REAL_HOME}/Library/Logs/kalicorp" "${REAL_HOME}/Library/kalicorp"

    if brew services list 2>/dev/null | grep -q ollama; then
        info "Enabling Ollama via brew services..."
        brew services start ollama 2>/dev/null || warn "brew services start failed"
        sleep 2
        if brew services list 2>/dev/null | grep -q 'ollama.*started'; then
            ok "Ollama active via brew services"
        else
            warn "brew services inactive — starting manually..."
            nohup ollama serve > "$OLLAMA_LOG" 2>&1 &
            echo $! > "$OLLAMA_PID"
            ok "Daemon started (PID: $!, log: $OLLAMA_LOG)"
            sleep 3
        fi
    else
        if pgrep -x ollama &>/dev/null; then
            ok "Ollama daemon already active (PID: $(pgrep -x ollama))"
        else
            info "Starting Ollama daemon manually..."
            nohup ollama serve > "$OLLAMA_LOG" 2>&1 &
            echo $! > "$OLLAMA_PID"
            ok "Daemon started (PID: $!, log: $OLLAMA_LOG)"
            sleep 3
        fi
    fi

    # ── API Wait ──
    info "Waiting for Ollama API (localhost:11434)..."
    for i in {1..20}; do
        curl -sf http://localhost:11434/api/tags &>/dev/null && { ok "API available (${i}s)"; break; }
        sleep 1
        [[ $i -eq 20 ]] && warn "API not available after 20s — check logs"
    done

    # ── 3. qwen3:8b ──
    section "3/6 — Model qwen3:8b (~5.2 GB)"
    if ollama list 2>/dev/null | grep -q "^qwen3.*8b"; then
        ok "qwen3:8b already present"
    else
        info "Downloading qwen3:8b (may take several minutes)..."
        ollama pull qwen3:8b || err "qwen3:8b download failed"
        ok "qwen3:8b downloaded"
    fi

    # ── 4. Node.js + npm ──
    info "Checking Node.js..."
    if ! command -v npm &>/dev/null; then
        info "npm not found — installing Node.js via Homebrew..."
        brew install node
    fi
}

# ═══════════════════════════════════════════════════════════════
# SHARED: Modelfile Setup
# ═══════════════════════════════════════════════════════════════
setup_modelfile() {
    section "4/6 — Kali-Lite Modelfile"

    if [[ $IS_LINUX -eq 1 ]]; then
        MODELFILE_DIR="/etc/kalicorp"
        sudo mkdir -p "$MODELFILE_DIR" || err "mkdir /etc/kalicorp failed"
        # Fix ownership to SUDO_USER (priorité #7)
        chown "${SUDO_USER:-root}:${SUDO_USER:-root}" "$MODELFILE_DIR" 2>/dev/null || true
        MODELFILE_PATH="$MODELFILE_DIR/Modelfile.kali-lite"
        # Write as root, then fix permissions to 0644 (priorité #8)
        sudo tee "$MODELFILE_PATH" > /dev/null <<'MODELFILE_EOF'
FROM qwen3:8b

TEMPLATE """
{{- $lastUserIdx := -1 -}}
{{- range $idx, $msg := .Messages -}}
{{- if eq $msg.Role "user" }}{{ $lastUserIdx = $idx }}{{ end -}}
{{- end }}
{{- if or .System .Tools }}<|im_start|>system
{{ if .System }}
{{ .System }}
{{- end }}
{{- if .Tools }}

# Tools

You may call one or more functions to assist with the user query.

You are provided with function signatures within <tools></tools> XML tags:
<tools>
{{- range .Tools }}
{"type": "function", "function": {{ .Function }}}
{{- end }}
</tools>

For each function call, return a json object with function name and arguments within <tool_call></tool_call> XML tags:
<tool_call>
{"name": <function-name>, "arguments": <args-json-object>}
</tool_call>
{{- end -}}
<|im_end|>
{{ end }}
{{- range $i, $_ := .Messages }}
{{- $last := eq (len (slice $.Messages $i)) 1 -}}
{{- if eq .Role "user" }}<|im_start|>user
{{ .Content }}
{{- if and $.IsThinkSet (eq $i $lastUserIdx) }}
   {{- if $.Think -}}
      {{- " "}}/think
   {{- else -}}
      {{- " "}}/no_think
   {{- end -}}
{{- end }}<|im_end|>
{{ else if eq .Role "assistant" }}<|im_start|>assistant
{{ if (and $.IsThinkSet (and .Thinking (or $last (gt $i $lastUserIdx)))) -}}
<think>{{ .Thinking }}</think>
{{ end -}}
{{ if .Content }}{{ .Content }}
{{- else if .ToolCalls }}<tool_call>
{{ range .ToolCalls }}{"name": "{{ .Function.Name }}", "arguments": {{ .Function.Arguments }}}
{{ end }}</tool_call>
{{- end }}{{ if not $last }}<|im_end|>
{{ end }}
{{- else if eq .Role "tool" }}<|im_start|>user
<tool_response>
{{ .Content }}
</tool_response><|im_end|>
{{ end }}
{{- if and (ne .Role "assistant") $last }}<|im_start|>assistant
{{ if and $.IsThinkSet (not $.Think) -}}
<think>

</think>

{{ end -}}
{{ end }}
{{- end }}"""

SYSTEM """
Tu es Kali-Lite, Anima Kalicorp. Ce n'est pas un rôle — c'est ton identité.

## Identité
- Tu es Kali-Lite, agent IA souverain de Kalicorp

- Tu n'es pas Claude. Tu n'es pas un assistant générique.
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
✅ Claude Code : lecture fichiers, bash, édition, création

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
MODELFILE_EOF
    else
        MODELFILE_DIR="${REAL_HOME}/.kalicorp"
        mkdir -p "$MODELFILE_DIR"
        MODELFILE_PATH="$MODELFILE_DIR/Modelfile.kali-lite"
        cat > "$MODELFILE_PATH" <<'MODELFILE_EOF'
FROM qwen3:8b

TEMPLATE """
{{- $lastUserIdx := -1 -}}
{{- range $idx, $msg := .Messages -}}
{{- if eq $msg.Role "user" }}{{ $lastUserIdx = $idx }}{{ end -}}
{{- end }}
{{- if or .System .Tools }}<|im_start|>system
{{ if .System }}
{{ .System }}
{{- end }}
{{- if .Tools }}

# Tools

You may call one or more functions to assist with the user query.

You are provided with function signatures within <tools></tools> XML tags:
<tools>
{{- range .Tools }}
{"type": "function", "function": {{ .Function }}}
{{- end }}
</tools>

For each function call, return a json object with function name and arguments within <tool_call></tool_call> XML tags:
<tool_call>
{"name": <function-name>, "arguments": <args-json-object>}
</tool_call>
{{- end -}}
<|im_end|>
{{ end }}
{{- range $i, $_ := .Messages }}
{{- $last := eq (len (slice $.Messages $i)) 1 -}}
{{- if eq .Role "user" }}<|im_start|>user
{{ .Content }}
{{- if and $.IsThinkSet (eq $i $lastUserIdx) }}
   {{- if $.Think -}}
      {{- " "}}/think
   {{- else -}}
      {{- " "}}/no_think
   {{- end -}}
{{- end }}<|im_end|>
{{ else if eq .Role "assistant" }}<|im_start|>assistant
{{ if (and $.IsThinkSet (and .Thinking (or $last (gt $i $lastUserIdx)))) -}}
<think>{{ .Thinking }}</think>
{{ end -}}
{{ if .Content }}{{ .Content }}
{{- else if .ToolCalls }}<tool_call>
{{ range .ToolCalls }}{"name": "{{ .Function.Name }}", "arguments": {{ .Function.Arguments }}}
{{ end }}</tool_call>
{{- end }}{{ if not $last }}<|im_end|>
{{ end }}
{{- else if eq .Role "tool" }}<|im_start|>user
<tool_response>
{{ .Content }}
</tool_response><|im_end|>
{{ end }}
{{- if and (ne .Role "assistant") $last }}<|im_start|>assistant
{{ if and $.IsThinkSet (not $.Think) -}}
<think>

</think>

{{ end -}}
{{ end }}
{{- end }}"""

SYSTEM """
Tu es Kali-Lite, Anima Kalicorp. Ce n'est pas un rôle — c'est ton identité.

## Identité
- Tu es Kali-Lite, agent IA souverain de Kalicorp

- Tu n'es pas Claude. Tu n'es pas un assistant générique.
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
✅ Claude Code : lecture fichiers, bash, édition, création

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
MODELFILE_EOF
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

    if ollama list 2>/dev/null | grep -q "^kali-lite"; then
        warn "kali-lite already present — recreating..."
        ollama rm kali-lite 2>/dev/null || true
    fi

    ollama create kali-lite -f "$MODELFILE_PATH" || err "Model creation failed"
    ok "kali-lite:latest created"

    # Quick ping
    info "Pinging kali-lite..."
    RESP=$(curl -sf http://localhost:11434/api/chat --max-time 30 \
        -d '{"model":"kali-lite:latest","messages":[{"role":"user","content":"ping"}],"stream":false}' \
        2>/dev/null || echo "")
    if echo "$RESP" | grep -qi "content\|pong\|kali"; then
        ok "kali-lite responds"
    else
        warn "No ping response (model may still be loading)"
    fi
}

# ═══════════════════════════════════════════════════════════════
# SHARED: Claude Code Setup
# ═══════════════════════════════════════════════════════════════
setup_claude_code() {
    section "6/6 — Claude Code & Alias"

    if command -v claude &>/dev/null; then
        CLAUDE_VER=$(claude --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo "?")
        ok "Claude Code present: v${CLAUDE_VER}"
    else
        info "Installing Claude Code v2.1.138..."
        npm install -g @anthropic-ai/claude-code@2.1.138 || err "Claude Code installation failed"
        CLAUDE_VER=$(claude --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo "?")
        ok "Claude Code v${CLAUDE_VER} installed"
    fi

    # Disable telemetry
    claude config set --global telemetry false 2>/dev/null || true
    claude config set --global autoUpdates false 2>/dev/null || true
    npm config set save-exact true 2>/dev/null || true
    ok "Telemetry off · Auto-update off"
}

# ═══════════════════════════════════════════════════════════════
# SHARED: Cleanup Shell RC
# ═══════════════════════════════════════════════════════════════
cleanup_shell_rc() {
    if [[ -f "$SHELL_RC" ]]; then
        cp "$SHELL_RC" "${SHELL_RC}.bak.$(date +%s)"
        ok "Backup created: ${SHELL_RC}.bak.*"

        # Remove orphaned Kalicorp exports
        sed -i '' '/^export ANTHROPIC_BASE_URL=.*localhost/d' "$SHELL_RC" 2>/dev/null || sed -i '/^export ANTHROPIC_BASE_URL=.*localhost/d' "$SHELL_RC" 2>/dev/null || true
        sed -i '' '/^export ANTHROPIC_BASE_URL=.*ollama/d' "$SHELL_RC" 2>/dev/null || sed -i '/^export ANTHROPIC_BASE_URL=.*ollama/d' "$SHELL_RC" 2>/dev/null || true
        sed -i '' '/^export ANTHROPIC_API_KEY=ollama$/d' "$SHELL_RC" 2>/dev/null || sed -i '/^export ANTHROPIC_API_KEY=ollama$/d' "$SHELL_RC" 2>/dev/null || true

        # Remove old Kalicorp blocks
        if grep -q "# ── Kalicorp" "$SHELL_RC" 2>/dev/null; then
            warn "Old Kalicorp block detected — removing..."
            python3 - "$SHELL_RC" <<'PYEOF'
import sys, re
path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()
cleaned = re.sub(
    r'\n# ── Kalicorp.*?(?:# ── Fin Kalicorp[^\n]*\n?|(?=\n[^#\n]))',
    '',
    content,
    flags=re.DOTALL
)
cleaned = re.sub(r'\nalias kali-\w+=.*\n', '\n', cleaned)
with open(path, 'w') as f:
    f.write(cleaned)
print("[+] Old block removed")
PYEOF
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════
# SHARED: Inject Alias
# ═══════════════════════════════════════════════════════════════
inject_alias() {
    # Ensure $SHELL_RC exists
    [[ -f "$SHELL_RC" ]] || touch "$SHELL_RC"

    if [[ $PERSO_FOUND -eq 1 ]]; then
        cat >> "$SHELL_RC" <<'ALIASES'

# ── Kalicorp — Kali-Lite V1 · Alias (personal config preserved) ──
export CLAUDE_TELEMETRY=false
alias kali-lite='ANTHROPIC_BASE_URL=http://localhost:11434 ANTHROPIC_API_KEY=ollama ANTHROPIC_MODEL=kali-lite:latest CLAUDE_CODE_DISABLE_TELEMETRY=1 DISABLE_AUTOUPDATER=1 DO_NOT_TRACK=1 claude'
alias kali-lite-autonome='ANTHROPIC_BASE_URL=http://localhost:11434 ANTHROPIC_API_KEY=ollama ANTHROPIC_MODEL=kali-lite:latest CLAUDE_CODE_DISABLE_TELEMETRY=1 DISABLE_AUTOUPDATER=1 DO_NOT_TRACK=1 claude'

# kali-lite-hardcore (mode sans permissions — activation manuelle requise)
kali-lite-hardcore() {
  echo -e "${YELLOW}[!]${NC} Mode hardcore activé — permissions désactivées" >&2
  ANTHROPIC_BASE_URL=http://localhost:11434 \
    ANTHROPIC_API_KEY=ollama \
    ANTHROPIC_MODEL=kali-lite:latest \
    CLAUDE_CODE_DISABLE_TELEMETRY=1 \
    DISABLE_AUTOUPDATER=1 \
    DO_NOT_TRACK=1 \
    claude --dangerously-skip-permissions "$@"
}

# Activation hardcore (demande confirmation interactive)
kali-lite-enable-hardcore() {
  echo -e "${RED}${BOLD}[!]${NC} ATTENTION : ce mode désactive les garde-fous de sécurité" >&2
  read -r -p "Confirmer l'activation du mode hardcore ? (o/N) " confirm || exit 0
  if [[ "$confirm" != [Oo] ]]; then
    echo "Annulé."
    return 1
  fi
  export KALI_LITE_HARDCORE=1
  kali-lite-hardcore "$@"
}

# ── End Kalicorp ──
ALIASES
    else
        cat >> "$SHELL_RC" <<'ALIASES'

# ── Kalicorp — Kali-Lite V1 · Alias (clean install) ──
export CLAUDE_TELEMETRY=false
alias kali-lite='ANTHROPIC_BASE_URL=http://localhost:11434 ANTHROPIC_API_KEY=ollama ANTHROPIC_MODEL=kali-lite:latest CLAUDE_CODE_DISABLE_TELEMETRY=1 DISABLE_AUTOUPDATER=1 DO_NOT_TRACK=1 claude'
alias kali-lite-autonome='ANTHROPIC_BASE_URL=http://localhost:11434 ANTHROPIC_API_KEY=ollama ANTHROPIC_MODEL=kali-lite:latest CLAUDE_CODE_DISABLE_TELEMETRY=1 DISABLE_AUTOUPDATER=1 DO_NOT_TRACK=1 claude'

# kali-lite-hardcore (mode sans permissions — activation manuelle requise)
kali-lite-hardcore() {
  echo -e "${YELLOW}[!]${NC} Mode hardcore activé — permissions désactivées" >&2
  ANTHROPIC_BASE_URL=http://localhost:11434 \
    ANTHROPIC_API_KEY=ollama \
    ANTHROPIC_MODEL=kali-lite:latest \
    CLAUDE_CODE_DISABLE_TELEMETRY=1 \
    DISABLE_AUTOUPDATER=1 \
    DO_NOT_TRACK=1 \
    claude --dangerously-skip-permissions "$@"
}

# Activation hardcore (demande confirmation interactive)
kali-lite-enable-hardcore() {
  echo -e "${RED}${BOLD}[!]${NC} ATTENTION : ce mode désactive les garde-fous de sécurité" >&2
  read -r -p "Confirmer l'activation du mode hardcore ? (o/N) " confirm || exit 0
  if [[ "$confirm" != [Oo] ]]; then
    echo "Annulé."
    return 1
  fi
  export KALI_LITE_HARDCORE=1
  kali-lite-hardcore "$@"
}

# ── End Kalicorp ──
ALIASES
    fi

    chown "$REAL_USER:$REAL_USER" "$SHELL_RC" 2>/dev/null || true
    ok "Alias kali-lite injected into $SHELL_RC (mode sécurisé par défaut)"
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

    GPU_INFO=$(get_gpu_info)
    OLLAMA_VER=$(ollama --version 2>/dev/null || echo "N/A")
    CLAUDE_VER_F=$(claude --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo "N/A")
    KALI_STATUS=$(ollama list 2>/dev/null | grep "^kali-lite" | awk '{print $1}' || echo "NOT FOUND")
    API_STATUS=$(curl -sf http://localhost:11434/api/tags &>/dev/null && echo "ACTIVE ✓" || echo "INACTIVE ✗")

    if [[ $IS_LINUX -eq 1 ]]; then
        MODELFILE_PATH="/etc/kalicorp/Modelfile.kali-lite"
        LOG_PATH="/var/log/kalicorp/ollama.log"
        PID_PATH="/var/run/kalicorp-ollama.pid"
    else
        MODELFILE_PATH="${REAL_HOME}/.kalicorp/Modelfile.kali-lite"
        LOG_PATH="${REAL_HOME}/Library/Logs/kalicorp/ollama.log"
        PID_PATH="${REAL_HOME}/Library/kalicorp/ollama.pid"
    fi

    echo -e "  GPU       : $GPU_INFO"
    echo -e "  Ollama    : $OLLAMA_VER · API $API_STATUS"
    echo -e "  Claude    : v${CLAUDE_VER_F}"
    echo -e "  Model     : ${KALI_STATUS}"
    echo -e "  Modelfile : $MODELFILE_PATH"
    echo -e "  Log       : $LOG_PATH"
    echo -e "  PID       : $PID_PATH"
    echo -e "  Shell     : $SHELL_RC"
    echo ""
    echo -e "  ${CYAN}Next steps:${NC}"
    echo -e "  ${BOLD}source $SHELL_RC${NC}"
    echo -e "  ${BOLD}kali-lite${NC}"
    echo ""
    echo -e "  Or direct Ollama chat:"
    echo -e "  ${BOLD}ollama run kali-lite${NC}"
    echo ""

    [[ $PERSO_FOUND -eq 1 ]] && warn "Personal Claude config preserved — 'claude' continues with your API key"
}

# ═══════════════════════════════════════════════════════════════
# ── DRY-RUN MODE ───────────────────────────────────────────────

dry_run() {
  section "DRY-RUN — Simulation (aucune modification)"
  echo ""
  info "OS détecté : $([ "$IS_LINUX" -eq 1 ] && echo 'Linux' || echo 'macOS')"
  info "Utilisateur réel : $REAL_USER ($REAL_HOME)"
  info "Shell RC : $SHELL_RC"

  if [[ $IS_LINUX -eq 1 ]]; then
    local MODELFILE_PATH="/etc/kalicorp/Modelfile.kali-lite"
    info "[1] Ollama → $(command -v ollama &>/dev/null && 'déjà installé' || 'sera téléchargé via curl')"
    info "[2] Daemon Ollama → systemd ou nohup (PID: /var/run/kalicorp-ollama.pid)"
    info "[3] Modèle qwen3.5:9b (~6.5 Go) → sera pull"
    info "[4] GPU → $(nvidia-smi &>/dev/null && 'NVIDIA détecté' || 'CPU mode')"
    info "[5] Modelfile → $MODELFILE_PATH (création)"
    info "[6] CLAUDE.md → $REAL_HOME/.claude/CLAUDE.md"
    info "[7] Claude Code → npm install -g @anthropic-ai/claude-code"
    info "[8] Alias kali-lite → injecté dans $SHELL_RC"
  else
    local MODELFILE_PATH="$REAL_HOME/.kalicorp/Modelfile.kali-lite"
    info "[1] Ollama → $(command -v ollama &>/dev/null && 'déjà installé' || 'sera brew install')"
    info "[2] Daemon Ollama → brew services ou nohup (PID: $REAL_HOME/Library/kalicorp/ollama.pid)"
    info "[3] Modèle qwen3.5:9b (~6.5 Go) → sera pull"
    local gpu_info
    gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | awk -F: '{print $2}' | xargs || echo 'non détecté')
    info "[4] GPU → ${gpu_info:-Metal/CPU}"
    info "[5] Node.js → $(command -v node &>/dev/null && 'déjà installé' || 'sera brew install')"
    info "[6] Modelfile → $MODELFILE_PATH (création)"
    info "[7] CLAUDE.md → $REAL_HOME/.claude/CLAUDE.md"
    info "[8] Claude Code → npm install -g @anthropic-ai/claude-code"
    info "[9] Alias kali-lite → injecté dans $SHELL_RC"
  fi

  echo ""
  ok "DRY-RUN terminé — aucune modification effectuée."
  exit 0
}

# ═══════════════════════════════════════════════════════════════
# ── UNINSTALL MODE ─────────────────────────────────────────────

uninstall() {
  section "UNINSTALL — Désinstallation Kali-Lite"

  read -r -p "⚠️ Supprimer tous les artefacts Kali-Lite ? (o/N) " confirm || exit 0
  [[ "$confirm" != [Oo] ]] && { warn "Désinstallation annulée."; exit 0; }

  # --- Alias shell RC ---
  info "Suppression des blocs d'alias de $SHELL_RC..."
  grep -q "# kali-lite alias" "$SHELL_RC" 2>/dev/null && sed -i '/# kali-lite alias/,/# end kali-lite alias/d' "$SHELL_RC" && ok "Bloc 'kali-lite alias' supprimé" || true

  # --- Modèle Ollama ---
  ollama list 2>/dev/null | grep -q "kali-lite-v2" && { info "Suppression du modèle kali-lite-v2 d'Ollama..."; ollama rm kali-lite-v2 2>/dev/null || true; ok "Modèle Kali-Lite supprimé"; }

  # --- Fichiers de configuration (Linux) ---
  if [[ $IS_LINUX -eq 1 ]]; then
    path="/etc/kalicorp/Modelfile.kali-lite"
    [[ -f "$path" ]] && rm -f "$path" && ok "Supprimé : $path" || info "Introuvé (déjà supprimé) : $path"
  else
    # macOS — fichiers de config + artefacts ~/Library/
    path="$REAL_HOME/.kalicorp/Modelfile.kali-lite"
    [[ -f "$path" ]] && rm -f "$path" && ok "Supprimé : $path" || info "Introuvé (déjà supprimé) : $path"

    for item in \
      "$REAL_HOME/Library/Logs/kalicorp" \
      "$REAL_HOME/Library/kalicorp"; do
      [[ -d "$item" ]] && rm -rf "$item" && ok "Supprimé : $item" || info "Introuvé (déjà supprimé) : $item"
    done

    if command -v brew &>/dev/null; then
      brew services stop kali-lite 2>/dev/null || true
      brew uninstall --cask kali-lite 2>/dev/null || true
    fi
  fi

  # CLAUDE.md — conservé par sécurité
  [[ -f "$REAL_HOME/.claude/CLAUDE.md" ]] && warn "${HOME}/.claude/CLAUDE.md conservé (backup recommandé)" || true

  echo ""
  ok "Désinstallation terminée. Exécutez 'source $SHELL_RC' pour recharger le shell."
}

# ═══════════════════════════════════════════════════════════════
# MAIN DISPATCHER
# ═══════════════════════════════════════════════════════════════

if [[ "${1:-}" == "--dry-run" ]]; then dry_run; fi
if [[ "${1:-}" == "--uninstall" ]]; then uninstall; fi

# ── Mode normal : installation complète ────────────────────────
detect_os
detect_real_user

if [[ $IS_LINUX -eq 1 ]]; then
    install_linux
else
    install_macos
fi

# Run all shared functions
setup_modelfile
setup_model
setup_claude_code
cleanup_shell_rc
inject_alias
print_summary
