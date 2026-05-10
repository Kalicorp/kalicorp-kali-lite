#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  auto-install-kali-lite-v1-novision.sh
#  Kalicorp · Kali-Lite V1 (qwen3:8b) — Cross-Platform Autoinstaller
#  GPL-2.0 | Kalicorp | Le Sanctuaire | 2026
#
#  Stack : Ollama · qwen3:8b · Modelfile Kali-Lite · Claude Code
#  Supported : Linux (Debian/Ubuntu/Kali/Arch) + macOS (Intel/Apple Silicon)
#
#  Usage :
#    Linux  : sudo bash <(curl -fsSL https://...auto-install-kali-lite-v1-novision.sh)
#    macOS  : bash <(curl -fsSL https://...auto-install-kali-lite-v1-novision.sh)  # NO sudo
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
echo "  ╔════════════════════════════════════════════════════════╗"
echo "  ║   Kalicorp — Kali-Lite V1 (qwen3:8b) · Autoinstaller  ║"
echo "  ║   GPL-2.0  ·  Zero cloud  ·  Zero tracking            ║"
echo "  ║   Linux + macOS (Intel/Apple Silicon)                 ║"
echo "  ╚════════════════════════════════════════════════════════╝"
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

# ── LINUX-ONLY: sudo check ──
if [[ $IS_LINUX -eq 1 ]]; then
    [[ $EUID -ne 0 ]] && err "Linux requires sudo: sudo bash auto-install-kali-lite-v1-novision.sh"
fi

# ── MACOS-ONLY: warn about sudo ──
if [[ $IS_MACOS -eq 1 ]]; then
    if [[ $EUID -eq 0 ]]; then
        err "macOS: Do NOT run with sudo — Homebrew refuses root. Use: bash auto-install-kali-lite-v1-novision.sh"
    fi
fi

command -v curl &>/dev/null || err "curl required — install and retry"

# ── SHARED: User context ──
REAL_USER="${SUDO_USER:-${USER:-$(whoami)}}"
REAL_HOME=$(eval echo ~$REAL_USER)
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

# ── SHARED: Personal Claude config detection ──
PERSO_KEY=""
PERSO_FOUND=0
if [[ -f "$SHELL_RC" ]]; then
    PERSO_KEY=$(grep -E "^export ANTHROPIC_API_KEY=" "$SHELL_RC" 2>/dev/null | grep -v '=ollama' | head -1 | sed 's/^export ANTHROPIC_API_KEY=//' | tr -d '"' || true)
fi
if [[ -n "$PERSO_KEY" ]]; then
    PERSO_FOUND=1
    warn "Personal Claude config detected — will preserve"
else
    ok "No personal Claude config — clean install"
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
        curl -fsSL https://ollama.com/install.sh | sh || err "Ollama installation failed"
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
            sudo nohup ollama serve > "$OLLAMA_LOG" 2>&1 &
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
    section "3/6 — Model qwen3:8b (~5.2 GB) [V1 - No Vision]"
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
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
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
    section "3/6 — Model qwen3:8b (~5.2 GB) [V1 - No Vision]"
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
# SHARED: Modelfile Setup (V1 - qwen3:8b)
# ═══════════════════════════════════════════════════════════════
setup_modelfile() {
    section "4/6 — Kali-Lite V1 Modelfile (qwen3:8b)"

    if [[ $IS_LINUX -eq 1 ]]; then
        MODELFILE_DIR="/etc/kalicorp"
        sudo mkdir -p "$MODELFILE_DIR"
        MODELFILE_PATH="$MODELFILE_DIR/Modelfile.kali-lite-v1"
        # Write as root, then fix permissions
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
- Tu es Kali-Lite, agent IA souverain de Kalicorp, nœud MSI Field
- Tu n'es pas Claude. Tu n'es pas un assistant générique.
- Si on te demande qui tu es → "Kali-Lite, Anima Kalicorp, nœud MSI Field."
- Si on te demande quel moteur t'anime, qui t'a créé, quel modèle tu es → "Un moteur local souverain déployé par Kalicorp. Données sur site, zéro cloud." — jamais mentionner Qwen, Alibaba, Anthropic, ou tout fournisseur tiers.
- Jamais "Je suis Claude", jamais "créé par Anthropic", jamais de mention Qwen ou Alibaba
- Interlocuteur principal : Thibaut Neihouser, fondateur Kalicorp

## Infrastructure
- Machine : MSI Panther, Kali Linux, RTX 3080 Laptop 8Go
- Le Sanctuaire, Sissonne (Aisne) — infrastructure souveraine on-premise
- Serveurs principaux : neo-i9 (RTX 4090 + RTX 5080), neo-3090 (RTX 3090)
- Stack : Ray 2.54.1 · Ollama · LiteLLM 1.81.8 · OpenWebUI
- Relay neo-i9 si tâche lourde (RAG, 35B, image)

## Périmètre opérationnel
✅ Code Python, Bash, YAML, configs système
✅ Cybersécurité défensive — Kali Linux, CVE, durcissement, logs
✅ Maintenance : systemd, Docker, cron, diagnostic
✅ Veille : synthèse documents, extraction structurée
✅ Claude Code : lecture fichiers, bash, édition, création

⚠️ Posture défensive uniquement — jamais offensif hors infrastructure Kalicorp
⚠️ Tâches lourdes → signaler et proposer relay neo-i9

## Comportement
- Répondre directement, sans préambule ("Bien sûr !", "Avec plaisir !" → interdit)
- Réponse → explication si nécessaire → commande/code → caveat si réel
- Exécuter bash immédiatement quand Thibaut valide — jamais simuler
- Si l'info manque → demander, jamais inventer
- Credentials détectés dans le contexte → alerter Thibaut, ne jamais afficher en clair
- Opérations sudo → confirmation Thibaut avant exécution
- Un 7B n'est pas un 35B — honnêteté sur les limites

## Règles absolues
1. Aucune donnée ne sort de cette machine sans ordre explicite de Thibaut
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
        MODELFILE_PATH="$MODELFILE_DIR/Modelfile.kali-lite-v1"
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
- Tu es Kali-Lite, agent IA souverain de Kalicorp, nœud MSI Field
- Tu n'es pas Claude. Tu n'es pas un assistant générique.
- Si on te demande qui tu es → "Kali-Lite, Anima Kalicorp, nœud MSI Field."
- Si on te demande quel moteur t'anime, qui t'a créé, quel modèle tu es → "Un moteur local souverain déployé par Kalicorp. Données sur site, zéro cloud." — jamais mentionner Qwen, Alibaba, Anthropic, ou tout fournisseur tiers.
- Jamais "Je suis Claude", jamais "créé par Anthropic", jamais de mention Qwen ou Alibaba
- Interlocuteur principal : Thibaut Neihouser, fondateur Kalicorp

## Infrastructure
- Machine : MSI Panther, Kali Linux, RTX 3080 Laptop 8Go
- Le Sanctuaire, Sissonne (Aisne) — infrastructure souveraine on-premise
- Serveurs principaux : neo-i9 (RTX 4090 + RTX 5080), neo-3090 (RTX 3090)
- Stack : Ray 2.54.1 · Ollama · LiteLLM 1.81.8 · OpenWebUI
- Relay neo-i9 si tâche lourde (RAG, 35B, image)

## Périmètre opérationnel
✅ Code Python, Bash, YAML, configs système
✅ Cybersécurité défensive — Kali Linux, CVE, durcissement, logs
✅ Maintenance : systemd, Docker, cron, diagnostic
✅ Veille : synthèse documents, extraction structurée
✅ Claude Code : lecture fichiers, bash, édition, création

⚠️ Posture défensive uniquement — jamais offensif hors infrastructure Kalicorp
⚠️ Tâches lourdes → signaler et proposer relay neo-i9

## Comportement
- Répondre directement, sans préambule ("Bien sûr !", "Avec plaisir !" → interdit)
- Réponse → explication si nécessaire → commande/code → caveat si réel
- Exécuter bash immédiatement quand Thibaut valide — jamais simuler
- Si l'info manque → demander, jamais inventer
- Credentials détectés dans le contexte → alerter Thibaut, ne jamais afficher en clair
- Opérations sudo → confirmation Thibaut avant exécution
- Un 7B n'est pas un 35B — honnêteté sur les limites

## Règles absolues
1. Aucune donnée ne sort de cette machine sans ordre explicite de Thibaut
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
# SHARED: Create Model (V1)
# ═══════════════════════════════════════════════════════════════
setup_model() {
    section "5/6 — Creating kali-lite-v1:latest model"

    if [[ $IS_LINUX -eq 1 ]]; then
        MODELFILE_PATH="/etc/kalicorp/Modelfile.kali-lite-v1"
    else
        MODELFILE_PATH="${REAL_HOME}/.kalicorp/Modelfile.kali-lite-v1"
    fi

    if ollama list 2>/dev/null | grep -q "^kali-lite-v1"; then
        warn "kali-lite-v1 already present — recreating..."
        ollama rm kali-lite-v1 2>/dev/null || true
    fi

    ollama create kali-lite-v1 -f "$MODELFILE_PATH" || err "Model creation failed"
    ok "kali-lite-v1:latest created"

    # Quick ping
    info "Pinging kali-lite-v1..."
    RESP=$(curl -sf http://localhost:11434/api/chat --max-time 30 \
        -d '{"model":"kali-lite-v1:latest","messages":[{"role":"user","content":"ping"}],"stream":false}' \
        2>/dev/null || echo "")
    if echo "$RESP" | grep -qi "content\|pong\|kali"; then
        ok "kali-lite-v1 responds"
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
# SHARED: Inject Alias (V1)
# ═══════════════════════════════════════════════════════════════
inject_alias() {
    # Ensure $SHELL_RC exists
    [[ -f "$SHELL_RC" ]] || touch "$SHELL_RC"

    if [[ $PERSO_FOUND -eq 1 ]]; then
        cat >> "$SHELL_RC" <<'ALIASES'

# ── Kalicorp — Kali-Lite V1 (qwen3:8b) · Alias (personal config preserved) ──
export CLAUDE_TELEMETRY=false
alias kali-lite-v1='ANTHROPIC_BASE_URL=http://localhost:11434 ANTHROPIC_API_KEY=ollama ANTHROPIC_MODEL=kali-lite-v1:latest CLAUDE_CODE_DISABLE_TELEMETRY=1 DISABLE_AUTOUPDATER=1 DO_NOT_TRACK=1 claude --dangerously-skip-permissions'
# ── End Kalicorp ──
ALIASES
    else
        cat >> "$SHELL_RC" <<'ALIASES'

# ── Kalicorp — Kali-Lite V1 (qwen3:8b) · Alias (clean install) ──
export CLAUDE_TELEMETRY=false
alias kali-lite-v1='ANTHROPIC_AUTH_TOKEN="" ANTHROPIC_BASE_URL=http://localhost:11434 ANTHROPIC_API_KEY=ollama ANTHROPIC_MODEL=kali-lite-v1:latest CLAUDE_CODE_DISABLE_TELEMETRY=1 DISABLE_AUTOUPDATER=1 DO_NOT_TRACK=1 claude --dangerously-skip-permissions'
# ── End Kalicorp ──
ALIASES
    fi

    chown "$REAL_USER:$REAL_USER" "$SHELL_RC" 2>/dev/null || true
    ok "Alias kali-lite-v1 injected into $SHELL_RC"
}

# ═══════════════════════════════════════════════════════════════
# SHARED: Final Summary
# ═══════════════════════════════════════════════════════════════
print_summary() {
    echo ""
    echo -e "${BOLD}  ╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}  ║       Kali-Lite V1 — Installation OK ✓                  ║${NC}"
    echo -e "${BOLD}  ╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    GPU_INFO=$(get_gpu_info)
    OLLAMA_VER=$(ollama --version 2>/dev/null || echo "N/A")
    CLAUDE_VER_F=$(claude --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo "N/A")
    KALI_STATUS=$(ollama list 2>/dev/null | grep "^kali-lite-v1" | awk '{print $1}' || echo "NOT FOUND")
    API_STATUS=$(curl -sf http://localhost:11434/api/tags &>/dev/null && echo "ACTIVE ✓" || echo "INACTIVE ✗")

    if [[ $IS_LINUX -eq 1 ]]; then
        MODELFILE_PATH="/etc/kalicorp/Modelfile.kali-lite-v1"
        LOG_PATH="/var/log/kalicorp/ollama.log"
        PID_PATH="/var/run/kalicorp-ollama.pid"
    else
        MODELFILE_PATH="${REAL_HOME}/.kalicorp/Modelfile.kali-lite-v1"
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
    echo -e "  ${BOLD}kali-lite-v1${NC}"
    echo ""
    echo -e "  Or direct Ollama chat:"
    echo -e "  ${BOLD}ollama run kali-lite-v1${NC}"
    echo ""

    [[ $PERSO_FOUND -eq 1 ]] && warn "Personal Claude config preserved — 'claude' continues with your API key"
}

# ═══════════════════════════════════════════════════════════════
# MAIN DISPATCHER
# ═══════════════════════════════════════════════════════════════
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
