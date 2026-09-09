#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Kali-Lite — tests de structure et invariants du dépôt
# Kalicorp | Le Sanctuaire | 2026

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PASS=0
FAIL=0
TOTAL=0

check() {
  local desc="$1"
  shift

  TOTAL=$((TOTAL + 1))

  if "$@" >/dev/null 2>&1; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $desc"
  fi
}

check_absent() {
  local desc="$1"
  local pattern="$2"
  local file="$3"

  TOTAL=$((TOTAL + 1))

  if ! grep -q -- "$pattern" "$file"; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $desc"
  fi
}

verify_sha256sums() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum --check SHA256SUMS >/dev/null
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 --check SHA256SUMS >/dev/null
  else
    echo "Aucun outil SHA-256 disponible" >&2
    return 1
  fi
}

echo "=== Structure du dépôt ==="

check "README.md existe"             test -f README.md
check "INSTALLATION.md existe"       test -f INSTALLATION.md
check "MODEL-CARD.md existe"         test -f MODEL-CARD.md
check "SECURITY.md existe"           test -f SECURITY.md
check "SECURITY-AUDIT.md existe"     test -f SECURITY-AUDIT.md
check "REFACTOR_BRIEF.md existe"     test -f REFACTOR_BRIEF.md
check "CODE_OF_CONDUCT.md existe"    test -f CODE_OF_CONDUCT.md
check "LICENSE existe"               test -f LICENSE
check "SHA256SUMS existe"            test -f SHA256SUMS
check ".gitignore existe"            test -f .gitignore
check "Modelfile existe"             test -f Modelfile

check "install.sh existe" \
  test -f install.sh

check "installateur V1 existe" \
  test -f auto-install-kali-lite-v1-novision.sh

check "installateur V2 existe" \
  test -f auto-install-kali-lite-v2-vision.sh

check "CONTRIBUTING existe" \
  test -f .github/CONTRIBUTING.md

check "ISSUE_TEMPLATE existe" \
  test -d .github/ISSUE_TEMPLATE

check "workflow CI existe" \
  test -f .github/workflows/test-installers.yml

check "banner existe" \
  test -f assets/kali-lite-banner.png

check "visuel overview existe" \
  test -f assets/kali-lite-overview.webp

check "documentation architecture existe" \
  test -f docs/ARCHITECTURE.md

check "documentation WHY-KALI-LITE existe" \
  test -f docs/WHY-KALI-LITE.md

check "template Anima existe" \
  test -f templates/anima.template.md


echo ""
echo "=== Shebangs ==="

check "install.sh shebang" \
  bash -c "head -1 install.sh | grep -q '^#!/usr/bin/env bash$'"

check "V1 shebang" \
  bash -c "head -1 auto-install-kali-lite-v1-novision.sh | grep -q '^#!/usr/bin/env bash$'"

check "V2 shebang" \
  bash -c "head -1 auto-install-kali-lite-v2-vision.sh | grep -q '^#!/usr/bin/env bash$'"


echo ""
echo "=== Syntaxe Bash ==="

check "install.sh syntaxe" \
  bash -n install.sh

check "V1 syntaxe" \
  bash -n auto-install-kali-lite-v1-novision.sh

check "V2 syntaxe" \
  bash -n auto-install-kali-lite-v2-vision.sh


echo ""
echo "=== install.sh ==="

check "install.sh: GPL-2.0-only" \
  grep -q 'GPL-2.0-only' install.sh

check "install.sh: detect_os" \
  grep -q 'detect_os' install.sh

check "install.sh: install_linux" \
  grep -q 'install_linux' install.sh

check "install.sh: install_macos" \
  grep -q 'install_macos' install.sh

check "install.sh: setup_modelfile" \
  grep -q 'setup_modelfile' install.sh

check "install.sh: setup_alias" \
  grep -q 'setup_alias' install.sh

check "install.sh: start_ollama_manual" \
  grep -q 'start_ollama_manual' install.sh

check "install.sh: vérification API Ollama" \
  grep -q 'wait_for_ollama_api' install.sh

check "install.sh: safe_download" \
  grep -q 'safe_download' install.sh

check "install.sh: qwen3:8b" \
  grep -q 'qwen3:8b' install.sh

check "install.sh: --dry-run" \
  grep -q -- '--dry-run' install.sh

check "install.sh: --uninstall" \
  grep -q -- '--uninstall' install.sh

check "install.sh: set -euo pipefail" \
  grep -q 'set -euo pipefail' install.sh

check_absent "install.sh: aucun Claude Code" \
  'claude-code' install.sh

check_absent "install.sh: aucune variable Anthropic" \
  'ANTHROPIC_' install.sh

check_absent "install.sh: aucun NodeSource" \
  'nodesource' install.sh

check_absent "install.sh: aucun dangerously-skip-permissions" \
  'dangerously-skip-permissions' install.sh

check_absent "install.sh: aucun eval" \
  'eval ' install.sh


echo ""
echo "=== Installateur V1 ==="

V1="auto-install-kali-lite-v1-novision.sh"

check "V1: GPL-2.0-only" \
  grep -q 'GPL-2.0-only' "$V1"

check "V1: qwen3:8b" \
  grep -q 'qwen3:8b' "$V1"

check "V1: Ollama" \
  grep -q 'ollama' "$V1"

check "V1: Modelfile" \
  grep -q 'Modelfile' "$V1"

check "V1: kali-lite" \
  grep -q 'kali-lite' "$V1"

check "V1: start_ollama_manual" \
  grep -q 'start_ollama_manual' "$V1"

check "V1: vérification API Ollama" \
  grep -q 'wait_for_ollama_api' "$V1"

check "V1: safe_download" \
  grep -q 'safe_download' "$V1"

check "V1: --dry-run" \
  grep -q -- '--dry-run' "$V1"

check "V1: --uninstall" \
  grep -q -- '--uninstall' "$V1"

check "V1: set -euo pipefail" \
  grep -q 'set -euo pipefail' "$V1"

check_absent "V1: aucun Claude Code" \
  'claude-code' "$V1"

check_absent "V1: aucune variable Anthropic" \
  'ANTHROPIC_' "$V1"

check_absent "V1: aucun NodeSource" \
  'nodesource' "$V1"

check_absent "V1: aucun dangerously-skip-permissions" \
  'dangerously-skip-permissions' "$V1"

check_absent "V1: aucun eval" \
  'eval ' "$V1"


echo ""
echo "=== Installateur V2 ==="

V2="auto-install-kali-lite-v2-vision.sh"

check "V2: GPL-2.0-only" \
  grep -q 'GPL-2.0-only' "$V2"

check "V2: qwen3.5:9b" \
  grep -q 'qwen3.5:9b' "$V2"

check "V2: Ollama" \
  grep -q 'ollama' "$V2"

check "V2: Modelfile" \
  grep -q 'Modelfile' "$V2"

check "V2: kali-lite-v2" \
  grep -q 'kali-lite-v2' "$V2"

check "V2: start_ollama_manual" \
  grep -q 'start_ollama_manual' "$V2"

check "V2: vérification API Ollama" \
  grep -q 'wait_for_ollama_api' "$V2"

check "V2: safe_download" \
  grep -q 'safe_download' "$V2"

check "V2: --dry-run" \
  grep -q -- '--dry-run' "$V2"

check "V2: --uninstall" \
  grep -q -- '--uninstall' "$V2"

check "V2: set -euo pipefail" \
  grep -q 'set -euo pipefail' "$V2"

check_absent "V2: aucun Claude Code" \
  'claude-code' "$V2"

check_absent "V2: aucune variable Anthropic" \
  'ANTHROPIC_' "$V2"

check_absent "V2: aucun NodeSource" \
  'nodesource' "$V2"

check_absent "V2: aucun dangerously-skip-permissions" \
  'dangerously-skip-permissions' "$V2"

check_absent "V2: aucun eval" \
  'eval ' "$V2"


echo ""
echo "=== Fidélité PID ==="

check "install.sh: capture \$!" \
  grep -q 'local pid=\$!' install.sh

check "V1: capture \$!" \
  grep -q 'local pid=\$!' "$V1"

check "V2: capture \$!" \
  grep -q 'local pid=\$!' "$V2"

check "install.sh: kill -0" \
  grep -q 'kill -0.*\$pid' install.sh

check "V1: kill -0" \
  grep -q 'kill -0.*\$pid' "$V1"

check "V2: kill -0" \
  grep -q 'kill -0.*\$pid' "$V2"


echo ""
echo "=== README ==="

check "README: badges shields.io" \
  grep -q 'img.shields.io' README.md

check "README: GPL-2.0-only" \
  grep -q 'GPL-2.0-only' README.md

check "README: V1 Qwen3 8B" \
  grep -q 'Qwen3 8B' README.md

check "README: V2 Qwen3.5 9B" \
  grep -q 'Qwen3.5 9B' README.md

check "README: vision" \
  grep -qi 'vision' README.md

check "README: banner" \
  grep -q 'kali-lite-banner.png' README.md

check "README: overview" \
  grep -q 'kali-lite-overview.webp' README.md

check "README: SECURITY.md" \
  grep -q 'SECURITY.md' README.md

check "README: SHA256SUMS" \
  grep -q 'SHA256SUMS' README.md

check_absent "README: pas de promesse 'Zero cloud'" \
  'Zero cloud' README.md


echo ""
echo "=== Modelfile ==="

check "Modelfile: FROM" \
  grep -q '^FROM ' Modelfile

check "Modelfile: SYSTEM" \
  grep -q '^SYSTEM ' Modelfile

check "Modelfile: qwen3.5:9b" \
  grep -q 'qwen3.5:9b' Modelfile

check "Modelfile: num_ctx" \
  grep -q 'PARAMETER num_ctx' Modelfile

check "Modelfile: preuve avant affirmation" \
  grep -q "preuve à l'affirmation" Modelfile

check "Modelfile: ne prétend pas avoir exécuté" \
  grep -q "exécuté une commande" Modelfile

# Important :
# Le Modelfile ne doit PAS obligatoirement contenir "MCP".
# Les outils appartiennent au harnais d'exécution et peuvent être absents.


echo ""
echo "=== Documentation ==="

check "MODEL-CARD: quatre couches" \
  grep -q 'quatre couches' MODEL-CARD.md

check "MODEL-CARD: pas de télémétrie ajoutée" \
  grep -q "n'ajoute aucune télémétrie" MODEL-CARD.md

check "SECURITY: permissions opérateur" \
  grep -q "Permissions sous contrôle de l'opérateur" SECURITY.md

check "CONTRIBUTING: preuve avant affirmation" \
  grep -q 'Preuve avant affirmation' .github/CONTRIBUTING.md

check "CODE_OF_CONDUCT: preuve avant affirmation" \
  grep -q 'preuve avant affirmation' CODE_OF_CONDUCT.md

check "REFACTOR_BRIEF: dry-run" \
  grep -q -- '--dry-run' REFACTOR_BRIEF.md


echo ""
echo "=== SHA-256 ==="

check "SHA256SUMS: V1 référencé" \
  grep -q 'auto-install-kali-lite-v1-novision.sh' SHA256SUMS

check "SHA256SUMS: V2 référencé" \
  grep -q 'auto-install-kali-lite-v2-vision.sh' SHA256SUMS

check "SHA256SUMS: install.sh référencé" \
  grep -q ' install.sh$' SHA256SUMS

check "SHA256SUMS correspond aux scripts publiés" \
  verify_sha256sums


echo ""
echo "=== Résultats ==="

echo "  Passés  : $PASS / $TOTAL"
echo "  Échoués : $FAIL / $TOTAL"

if [[ "$FAIL" -gt 0 ]]; then
  echo ""
  echo "  RESULTAT: FAIL"
  exit 1
fi

echo ""
echo "  RESULTAT: PASS — TOUS LES TESTS DE STRUCTURE SONT PASSES"
exit 0
