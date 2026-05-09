#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  install-kali-lite-v1.sh
#  Kalicorp · Nœud MSI Field — Autoinstaller
#  GPL-2.0 | Kalicorp | Le Sanctuaire | 2026
#
#  Stack : Ollama · qwen3:8b · Modelfile Kali-Lite · Claude Code
#  Machine cible : MSI Panther · Kali Linux · RTX 3080 Laptop 8Go
#
#  Usage :
#    chmod +x install-kali-lite-v1.sh
#    sudo ./install-kali-lite-v1.sh
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
echo "  ║   Stack : Ollama · qwen3:8b · Claude Code        ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ═══════════════════════════════════════════════════════════════
# PRÉREQUIS
# ═══════════════════════════════════════════════════════════════
section "0/6 — Prérequis"

[[ $EUID -ne 0 ]] && err "Lancer avec sudo : sudo ./install-kali-lite-v1.sh"
command -v curl &>/dev/null || err "curl requis : apt install curl"

REAL_USER="${SUDO_USER:-${USER:-root}}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6 2>/dev/null || echo "$HOME")
SHELL_RC="${REAL_HOME}/.bashrc"
[[ "$SHELL" == *zsh* ]] && SHELL_RC="${REAL_HOME}/.zshrc"

info "Utilisateur : $REAL_USER ($REAL_HOME)"
info "Shell RC    : $SHELL_RC"

# Détection GPU NVIDIA
if nvidia-smi &>/dev/null; then
    GPU=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null)
    ok "GPU : $GPU"
else
    warn "nvidia-smi KO — GPU CUDA non détecté (Ollama tournera en CPU)"
fi

# Détection config Claude Code perso existante
PERSO_KEY=""
PERSO_FOUND=0
if [[ -f "$SHELL_RC" ]]; then
    PERSO_KEY=$(grep -E "^export ANTHROPIC_API_KEY=" "$SHELL_RC" 2>/dev/null \
        | grep -v '=ollama' | head -1 \
        | sed 's/^export ANTHROPIC_API_KEY=//' | tr -d '"' || true)
fi
if [[ -n "$PERSO_KEY" ]]; then
    PERSO_FOUND=1
    warn "Config Claude Code personnelle détectée — sera préservée"
else
    ok "Aucune config Claude Code personnelle — installation propre"
fi

# ═══════════════════════════════════════════════════════════════
# 1. OLLAMA
# ═══════════════════════════════════════════════════════════════
section "1/6 — Ollama"

if command -v ollama &>/dev/null; then
    ok "Ollama présent : $(ollama --version 2>/dev/null)"
else
    info "Installation Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh || err "Installation Ollama échouée"
    ok "Ollama installé"
fi

# ═══════════════════════════════════════════════════════════════
# 2. DAEMON OLLAMA
# ═══════════════════════════════════════════════════════════════
section "2/6 — Daemon Ollama"

OLLAMA_LOG="/var/log/kalicorp/ollama.log"
OLLAMA_PID="/var/run/kalicorp-ollama.pid"
mkdir -p /var/log/kalicorp

if command -v systemctl &>/dev/null && systemctl list-unit-files ollama.service &>/dev/null 2>&1; then
    systemctl enable ollama 2>/dev/null || warn "Activation systemd échouée"
    systemctl start  ollama 2>/dev/null || warn "Démarrage systemd échoué"
    sleep 2
    if systemctl is-active --quiet ollama; then
        ok "Ollama actif via systemd (persistant au reboot)"
    else
        warn "Systemd inactif — démarrage manuel..."
        nohup ollama serve > "$OLLAMA_LOG" 2>&1 &
        echo $! > "$OLLAMA_PID"
        ok "Daemon lancé (PID: $!, log: $OLLAMA_LOG)"
        sleep 3
    fi
else
    if pgrep -x ollama &>/dev/null; then
        ok "Daemon Ollama déjà actif (PID: $(pgrep -x ollama))"
    else
        info "Démarrage manuel du daemon..."
        nohup ollama serve > "$OLLAMA_LOG" 2>&1 &
        echo $! > "$OLLAMA_PID"
        ok "Daemon lancé (PID: $!, log: $OLLAMA_LOG)"
        sleep 3
    fi
fi

info "Attente API Ollama (http://localhost:11434)..."
for i in {1..20}; do
    curl -sf http://localhost:11434/api/tags &>/dev/null && { ok "API disponible (${i}s)"; break; }
    sleep 1
    [[ $i -eq 20 ]] && warn "API non disponible après 20s — vérifier /var/log/ollama.log"
done

# ═══════════════════════════════════════════════════════════════
# 3. MODÈLE DE BASE : qwen3:8b
# ═══════════════════════════════════════════════════════════════
section "3/6 — Modèle qwen3:8b (~5.2 Go)"

if ollama list 2>/dev/null | grep -q "^qwen3.*8b"; then
    ok "qwen3:8b déjà présent"
else
    info "Téléchargement qwen3:8b (peut prendre plusieurs minutes)..."
    ollama pull qwen3:8b || err "Échec du téléchargement de qwen3:8b"
    ok "qwen3:8b téléchargé"
fi

# ═══════════════════════════════════════════════════════════════
# 4. MODELFILE KALI-LITE
# ═══════════════════════════════════════════════════════════════
section "4/6 — Modelfile Kali-Lite"

mkdir -p /etc/kalicorp

cat > /etc/kalicorp/Modelfile.kali-lite <<'MODELFILE_EOF'
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

ok "Modelfile écrit dans /etc/kalicorp/Modelfile.kali-lite"

# ═══════════════════════════════════════════════════════════════
# 5. CRÉATION DU MODÈLE kali-lite
# ═══════════════════════════════════════════════════════════════
section "5/6 — Création modèle kali-lite:latest"

if ollama list 2>/dev/null | grep -q "^kali-lite"; then
    warn "kali-lite déjà présent — recréation..."
    ollama rm kali-lite 2>/dev/null || true
fi

ollama create kali-lite -f /etc/kalicorp/Modelfile.kali-lite \
    || err "Création du modèle kali-lite échouée"
ok "kali-lite:latest créé"

# Ping rapide
info "Ping kali-lite..."
RESP=$(curl -sf http://localhost:11434/api/chat --max-time 30 \
    -d '{"model":"kali-lite:latest","messages":[{"role":"user","content":"ping"}],"stream":false}' \
    2>/dev/null || echo "")
if echo "$RESP" | grep -qi "content\|pong\|kali"; then
    ok "kali-lite répond"
else
    warn "Pas de réponse au ping (modèle peut être encore en chargement)"
fi

# ═══════════════════════════════════════════════════════════════
# 6. CLAUDE CODE + ALIAS
# ═══════════════════════════════════════════════════════════════
section "6/6 — Claude Code & alias"

# ── Installation Claude Code (npm) ──
if command -v claude &>/dev/null; then
    CLAUDE_VER=$(claude --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo "?")
    ok "Claude Code présent : v${CLAUDE_VER}"
else
    if ! command -v npm &>/dev/null; then
        info "npm absent — installation Node.js LTS..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
        apt-get install -y nodejs
    fi
    info "Installation Claude Code (version figée 2.1.138)..."
    npm install -g @anthropic-ai/claude-code@2.1.138 || err "Installation Claude Code échouée"
    CLAUDE_VER=$(claude --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo "?")
    ok "Claude Code v${CLAUDE_VER} installé"
fi

# Désactiver télémétrie / auto-update
claude config set --global telemetry   false 2>/dev/null || true
claude config set --global autoUpdates false 2>/dev/null || true
npm config set save-exact true         2>/dev/null || true
ok "Télémétrie off · Auto-update off"

# ── Nettoyage anciens blocs Kalicorp dans $SHELL_RC ──
if [[ -f "$SHELL_RC" ]]; then
    cp "$SHELL_RC" "${SHELL_RC}.bak.$(date +%s)"
    ok "Backup $SHELL_RC créé"

    # Supprimer exports Kalicorp orphelins
    sed -i '/^export ANTHROPIC_BASE_URL=.*localhost/d'  "$SHELL_RC" 2>/dev/null || true
    sed -i '/^export ANTHROPIC_BASE_URL=.*ollama/d'     "$SHELL_RC" 2>/dev/null || true
    sed -i '/^export ANTHROPIC_API_KEY=ollama$/d'        "$SHELL_RC" 2>/dev/null || true

    # Supprimer anciens blocs Kalicorp (robuste via python3)
    if grep -q "# ── Kalicorp" "$SHELL_RC" 2>/dev/null; then
        warn "Ancien bloc Kalicorp détecté — suppression..."
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
print("[+] Ancien bloc supprimé")
PYEOF
    fi
fi

# ── Injection alias — structure validée MSI Panther (Claude Code 2.1.138) ──
# Alias écrit directement sans variables intermédiaires pour éviter
# tout problème de guillemets imbriqués ou d'expansion non voulue.

if [[ $PERSO_FOUND -eq 1 ]]; then
    # Config perso détectée : on ne vide pas ANTHROPIC_AUTH_TOKEN
    cat >> "$SHELL_RC" <<'ALIASES'

# ── Kalicorp — Kali-Lite V1 · Alias isolés, zero tracking ──
# Config Claude Code personnelle détectée et préservée
export CLAUDE_TELEMETRY=false
alias kali-lite='ANTHROPIC_BASE_URL=http://localhost:11434 ANTHROPIC_API_KEY=ollama ANTHROPIC_MODEL=kali-lite:latest CLAUDE_CODE_DISABLE_TELEMETRY=1 DISABLE_AUTOUPDATER=1 DO_NOT_TRACK=1 claude --dangerously-skip-permissions'
# ── Fin Kalicorp ──
ALIASES
else
    # Installation propre : on vide ANTHROPIC_AUTH_TOKEN pour éviter conflit login
    cat >> "$SHELL_RC" <<'ALIASES'

# ── Kalicorp — Kali-Lite V1 · Alias isolés, zero tracking ──
# Installation propre — aucune config Claude Code personnelle
export CLAUDE_TELEMETRY=false
alias kali-lite='ANTHROPIC_AUTH_TOKEN="" ANTHROPIC_BASE_URL=http://localhost:11434 ANTHROPIC_API_KEY=ollama ANTHROPIC_MODEL=kali-lite:latest CLAUDE_CODE_DISABLE_TELEMETRY=1 DISABLE_AUTOUPDATER=1 DO_NOT_TRACK=1 claude --dangerously-skip-permissions'
# ── Fin Kalicorp ──
ALIASES
fi

chown "$REAL_USER:$REAL_USER" "$SHELL_RC" 2>/dev/null || true
ok "Alias kali-lite injecté dans $SHELL_RC"

# ═══════════════════════════════════════════════════════════════
# RÉSUMÉ FINAL
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}  ╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}  ║       Kali-Lite V1 — Installation OK ✓          ║${NC}"
echo -e "${BOLD}  ╚══════════════════════════════════════════════════╝${NC}"
echo ""

GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "N/A (CPU mode)")
OLLAMA_VER=$(ollama --version 2>/dev/null || echo "N/A")
CLAUDE_VER_F=$(claude --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo "N/A")
KALI_STATUS=$(ollama list 2>/dev/null | grep "^kali-lite" | awk '{print $1}' || echo "NON TROUVÉ")
API_STATUS=$(curl -sf http://localhost:11434/api/tags &>/dev/null && echo "ACTIF ✓" || echo "INACTIF ✗")

echo -e "  GPU       : $GPU_INFO"
echo -e "  Ollama    : $OLLAMA_VER · API $API_STATUS"
echo -e "  Claude    : v${CLAUDE_VER_F}"
echo -e "  Modèle    : ${KALI_STATUS}"
echo -e "  Modelfile : /etc/kalicorp/Modelfile.kali-lite"
echo -e "  Log       : /var/log/kalicorp/ollama.log"
echo -e "  PID       : /var/run/kalicorp-ollama.pid"
echo -e "  Shell     : $SHELL_RC"
echo ""
echo -e "  ${CYAN}Relancer le shell puis :${NC}"
echo -e "  ${BOLD}source $SHELL_RC${NC}"
echo -e "  ${BOLD}kali-lite${NC}"
echo ""
echo -e "  Ou chat direct Ollama :"
echo -e "  ${BOLD}ollama run kali-lite${NC}"
echo ""

[[ $PERSO_FOUND -eq 1 ]] && warn "Config Claude Code perso préservée — 'claude' continue sur ton API key"
