#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  test-no-secret-leak.sh -- Anti-fuite de secrets dans les installers
#  Kalicorp · Kali-Lite V2 | GPL-2.0 | Le Sanctuaire | 2026
# ═══════════════════════════════════════════════════════════════

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0; WARN=0

ok()      { echo -e "${GREEN}[OK]${NC} $*"; PASS=$((PASS+1)); }
fail_test(){ echo -e "${RED}[FAIL]${NC} $*"; FAIL=$((FAIL+1)); }
warn_test(){ echo -e "${YELLOW}[WARN]${NC} $*"; WARN=$((WARN+1)); }

SCRIPTS=(
  "install.sh"
  "auto-install-kali-lite-v1-novision.sh"
  "auto-install-kali-lite-v2-vision.sh"
)

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo -e "\n${BOLD}=== Test anti-fuite de secrets ===\n"

for script in "${SCRIPTS[@]}"; do
  filepath="${BASE_DIR}/${script}"
  [[ ! -f "$filepath" ]] && { warn_test "Script absent : $script (ignore)"; continue; }

  echo "--- ${BOLD}$script${NC} ---"

  # Test 1: Pas de clé API en dur avec valeur non vide
  if grep -n 'ANTHROPIC_API_KEY\s*=\s*["\x27][^"\x27]\{5,\}' "$filepath" >/dev/null 2>&1; then
    fail_test "Clé ANTHROPIC_API_KEY en dur avec valeur détectée (ligne $(grep -n 'ANTHROPIC_API_KEY\s*=\s*["\x27][^"\x27]\{5,\}' "$filepath" | head -1 | cut -d: -f1))"
  else
    ok "Aucune clé ANTHROPIC_API_KEY en dur avec valeur non vide"
  fi

  # Test 2: Pas d'echo/print de variables sensibles
  if grep -nE 'echo.*\$ANTHROPIC_API_KEY|printenv\s+ANTHROPIC_API_KEY' "$filepath" >/dev/null 2>&1; then
    fail_test "Exposition directe de ANTHROPIC_API_KEY via echo/printenv détectée"
  else
    ok "Aucune exposition directe de clé API dans les sorties"
  fi

  # Test 3: PERSO_FOUND utilisé comme garde-fou
  if grep -q 'PERSO_FOUND' "$filepath"; then
    ok "Garde-fou PERSO_FOUND présent (détection config perso)"
  else
    warn_test "Pas de garde-fou PERSO_FOUND dans $script"
  fi

  # Test 4: safe_download/safe_download_exec utilisé au lieu de curl|sh pipe
  if grep -q 'safe_download\|safe_download_exec' "$filepath"; then
    ok "Téléchargement sécurisé (safe_download) présent"
  else
    warn_test "Pas de pattern safe_download dans $script -- vérifier les téléchargements externes"
  fi

  # Test 5: Pas de pipe vers bash pour scripts distants
  if grep -nE 'curl.*\|\s*bash|wget.*\|\s*sh' "$filepath" >/dev/null 2>&1; then
    fail_test "Pipe dangereux curl|bash ou wget|sh détecté (ligne $(grep -nE 'curl.*\|\s*bash|wget.*\|\s*sh' "$filepath" | head -1 | cut -d: -f1))"
  else
    ok "Aucun pipe dangereux curl|bash / wget|sh"
  fi

  # Test 6: Pas de secrets dans les commentaires
  if grep -nE '#.*sk-[a-zA-Z0-9]{20,}|#.*ANTHROPIC_.*=.*[a-zA-Z0-9]' "$filepath" >/dev/null 2>&1; then
    fail_test "Secret potentiel dans un commentaire détecté (ligne $(grep -nE '#.*sk-[a-zA-Z0-9]{20,}' "$filepath" | head -1 | cut -d: -f1))"
  else
    ok "Aucun secret apparent dans les commentaires"
  fi

  echo ""
done

# Test 7 : gitleaks-expurgated.json -- aucun NON-COMPROMIS non résolu
if [[ -f "${BASE_DIR}/gitleaks-expurgated.json" ]]; then
  unresolved=$(grep -c '"NON-COMPROMIS"' "${BASE_DIR}/gitleaks-expurgated.json" || true)
  if [[ "$unresolved" -eq 0 ]]; then
    ok "Aucune vulnérabilité NON-COMPROMIS restante dans le rapport gitleaks"
  else
    warn_test "$unresolved entrée(s) NON-COMPROMIS encore présentes (historique git -- rotation nécessaire)"
  fi
else
  warn_test "gitleaks-expurgated.json absent -- scan non execute récemment"
fi

# Resume
echo -e "\n${BOLD}=== RESUME ===${NC}"
echo -e "${GREEN}$PASS passe(s)${NC}  ${RED}$FAIL echoue(s)${NC}  ${YELLOW}$WARN avertissement(s)\n"

if [[ $FAIL -gt 0 ]]; then
  echo "RESULT: FAIL -- Des fuites de secrets potentielles detectees."
  exit 1
else
  echo "RESULT: PASS -- Aucune fuite critique detectee."
  exit 0
fi
