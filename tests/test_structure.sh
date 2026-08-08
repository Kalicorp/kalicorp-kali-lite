#!/usr/bin/env bash
# Kali-Lite — tests de structure du repo
# GPL-2.0 — Kalicorp | Le Sanctuaire | 2026
set -euo pipefail

PASS=0
FAIL=0
TOTAL=0

check() {
  TOTAL=$((TOTAL + 1))
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $desc"
  fi
}

echo "=== Structure du repo ==="
check "README.md existe"          test -f README.md
check "MODEL-CARD.md existe"      test -f MODEL-CARD.md
check "CODE_OF_CONDUCT.md existe" test -f CODE_OF_CONDUCT.md
check "LICENSE existe"            test -f LICENSE
check ".gitignore existe"         test -f .gitignore
check "Modelfile existe"          test -f Modelfile
check "install.sh existe"         test -f install.sh
check "v1 installer existe"       test -f auto-install-kali-lite-v1-novision.sh
check "v2 installer existe"       test -f auto-install-kali-lite-v2-vision.sh
check "banner existe"             test -f assets/kali-lite-banner.png
check ".github/ISSUE_TEMPLATE existe" test -d .github/ISSUE_TEMPLATE
check ".github/CONTRIBUTING.md existe" test -f .github/CONTRIBUTING.md

echo ""
echo "=== Shebangs ==="
check "install.sh shebang"        bash -c "head -1 install.sh | grep -q '^#!/usr/bin/env bash'"
check "v1 shebang"                bash -c "head -1 auto-install-kali-lite-v1-novision.sh | grep -q '^#!/usr/bin/env bash'"
check "v2 shebang"                bash -c "head -1 auto-install-kali-lite-v2-vision.sh | grep -q '^#!/usr/bin/env bash'"

echo ""
echo "=== Syntaxe bash ==="
check "install.sh syntaxe"        bash -n install.sh
check "v1 syntaxe"                bash -n auto-install-kali-lite-v1-novision.sh
check "v2 syntaxe"                bash -n auto-install-kali-lite-v2-vision.sh

echo ""
echo "=== Contenu install.sh ==="
check "install.sh: detect_os"     grep -q 'detect_os' install.sh
check "install.sh: setup_modelfile" grep -q 'setup_modelfile' install.sh
check "install.sh: setup_alias"   grep -q 'setup_alias' install.sh
check "install.sh: setup_alias"   grep -q 'setup_alias' install.sh
check "install.sh: GPL"           grep -q 'GPL' install.sh
check "install.sh: Linux"         grep -q 'Linux' install.sh
check "install.sh: macOS/Darwin"  grep -q 'Darwin' install.sh

echo ""
echo "=== Contenu v1 installer ==="
check "v1: qwen3:8b"             grep -q 'qwen3:8b' auto-install-kali-lite-v1-novision.sh
check "v1: ollama"                grep -q 'ollama' auto-install-kali-lite-v1-novision.sh
check "v1: Modelfile"             grep -q 'Modelfile' auto-install-kali-lite-v1-novision.sh

check "v1: NO claude-code"        bash -c "! grep -q 'claude-code' auto-install-kali-lite-v1-novision.sh"check "v1: kali-lite alias"       grep -q 'kali-lite' auto-install-kali-lite-v1-novision.sh
check "v1: GPL"                   grep -q 'GPL' auto-install-kali-lite-v1-novision.sh

echo ""
echo "=== Contenu v2 installer ==="
check "v2: qwen3.5:9b"            grep -q 'qwen3.5:9b' auto-install-kali-lite-v2-vision.sh
check "v2: ollama"                grep -q 'ollama' auto-install-kali-lite-v2-vision.sh
check "v2: Modelfile"             grep -q 'Modelfile' auto-install-kali-lite-v2-vision.sh
check "v2: kali-lite alias"       grep -q 'kali-lite' auto-install-kali-lite-v2-vision.sh
check "v2: GPL"                   grep -q 'GPL' auto-install-kali-lite-v2-vision.sh
check "v2: no eval"               bash -c "! grep -q 'eval ' auto-install-kali-lite-v2-vision.sh"

echo ""
echo "=== README ==="
check "README: badges shields.io"  grep -q 'img.shields.io' README.md
check "README: install curl"       grep -q 'curl.*install' README.md
check "README: v2/vision"          grep -q 'v2\|vision' README.md
check "README: banner"             grep -q 'banner' README.md
check "README: GPL license ref"    grep -q 'GPL' README.md

echo ""
echo "=== Modelfile ==="
check "Modelfile: FROM"           grep -q '^FROM' Modelfile
check "Modelfile: SYSTEM"          grep -q '^SYSTEM' Modelfile
check "Modelfile: qwen3.5:9b"     grep -q 'qwen3.5:9b' Modelfile
check "Modelfile: Outils MCP"     grep -q 'MCP' Modelfile

echo ""
echo "=== Sécurité ==="
check "v1: no eval"               bash -c "! grep -q 'eval ' auto-install-kali-lite-v1-novision.sh"
check "v2: no eval"               bash -c "! grep -q 'eval ' auto-install-kali-lite-v2-vision.sh"
check "v1: set -euo pipefail"     grep -q 'set -euo pipefail' auto-install-kali-lite-v1-novision.sh
check "v2: set -euo pipefail"     grep -q 'set -euo pipefail' auto-install-kali-lite-v2-vision.sh

echo ""
echo "=== Résultats ==="
echo "  Passés: $PASS / $TOTAL"
echo "  Échoués: $FAIL / $TOTAL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "  TOUS LES TESTS PASSES"
exit 0
