#!/usr/bin/env bash
# Vérifie que --dry-run ne modifie pas HOME ni TMPDIR.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS=(
  "install.sh"
  "auto-install-kali-lite-v1-novision.sh"
  "auto-install-kali-lite-v2-vision.sh"
)

PASS=0
FAIL=0

for script in "${SCRIPTS[@]}"; do
  sandbox="$(mktemp -d)"
  fake_home="$sandbox/home"
  fake_tmp="$sandbox/tmp"
  mkdir -p "$fake_home" "$fake_tmp"
  before="$(find "$sandbox" -mindepth 1 -printf '%P %y\n' | sort)"

  if HOME="$fake_home" TMPDIR="$fake_tmp" \
      bash "$ROOT_DIR/$script" --dry-run >"$sandbox/output.log" 2>&1; then
    :
  else
    echo "FAIL: $script --dry-run retourne une erreur"
    sed -n '1,120p' "$sandbox/output.log"
    FAIL=$((FAIL + 1))
    rm -rf "$sandbox"
    continue
  fi

  rm -f "$sandbox/output.log"
  after="$(find "$sandbox" -mindepth 1 -printf '%P %y\n' | sort)"
  if [[ "$before" == "$after" ]]; then
    echo "PASS: $script --dry-run sans effet de bord"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $script --dry-run a modifié le sandbox"
    diff -u <(printf '%s\n' "$before") <(printf '%s\n' "$after") || true
    FAIL=$((FAIL + 1))
  fi
  rm -rf "$sandbox"
done

echo "Dry-run: $PASS passé(s), $FAIL échec(s)"
[[ "$FAIL" -eq 0 ]]
