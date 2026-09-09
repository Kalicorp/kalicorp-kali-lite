#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Kali-Lite — tests statiques des invariants PID Ollama
# Kalicorp | Le Sanctuaire | 2026

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCRIPTS=(
  "install.sh"
  "auto-install-kali-lite-v1-novision.sh"
  "auto-install-kali-lite-v2-vision.sh"
)

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

  if ! grep -Eq -- "$pattern" "$file"; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $desc"
  fi
}

check_count() {
  local desc="$1"
  local expected="$2"
  local pattern="$3"
  local file="$4"
  local count

  TOTAL=$((TOTAL + 1))

  count="$(grep -Ec -- "$pattern" "$file" || true)"

  if [[ "$count" -eq "$expected" ]]; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $desc (attendu=$expected obtenu=$count)"
  fi
}

check_pid_order() {
  local file="$1"
  local nohup_line
  local capture_line
  local write_line
  local kill_line

  nohup_line="$(
    grep -nE 'nohup[[:space:]]+ollama[[:space:]]+serve' "$file" |
      head -1 |
      cut -d: -f1
  )"

  capture_line="$(
    grep -nF 'local pid=$!' "$file" |
      head -1 |
      cut -d: -f1
  )"

  write_line="$(
    grep -nF 'echo "$pid" > "$pid_file"' "$file" |
      head -1 |
      cut -d: -f1
  )"

  kill_line="$(
    grep -nF 'kill -0 "$pid"' "$file" |
      head -1 |
      cut -d: -f1
  )"

  [[ -n "$nohup_line" ]]
  [[ -n "$capture_line" ]]
  [[ -n "$write_line" ]]
  [[ -n "$kill_line" ]]

  (( nohup_line < capture_line ))
  (( capture_line < write_line ))
  (( write_line < kill_line ))
}

echo "=== Syntaxe des tests et installateurs ==="

check "test_pid_fidelity.sh syntaxe" \
  bash -n tests/test_pid_fidelity.sh

for script in "${SCRIPTS[@]}"; do
  check "$script: syntaxe Bash" \
    bash -n "$script"
done


echo ""
echo "=== Fonction start_ollama_manual ==="

for script in "${SCRIPTS[@]}"; do
  check "$script: fonction start_ollama_manual définie" \
    grep -q '^start_ollama_manual()' "$script"

  check "$script: paramètre log_file" \
    grep -q 'local log_file="\$1"' "$script"

  check "$script: paramètre pid_file" \
    grep -q 'local pid_file="\$2"' "$script"
done


echo ""
echo "=== Lancement Ollama centralisé ==="

for script in "${SCRIPTS[@]}"; do
  check_count \
    "$script: un seul nohup ollama serve" \
    1 \
    'nohup[[:space:]]+ollama[[:space:]]+serve' \
    "$script"

  check "$script: redirection vers log_file" \
    grep -q 'nohup ollama serve > "\$log_file" 2>&1 &' "$script"

  check_absent \
    "$script: aucun lancement Ollama via pipeline" \
    'ollama[[:space:]]+serve.*\|.*&' \
    "$script"

  check_absent \
    "$script: aucun nohup via subshell command substitution" \
    '\$\(.*nohup[[:space:]]+ollama[[:space:]]+serve' \
    "$script"
done


echo ""
echo "=== Capture fidèle de \$! ==="

for script in "${SCRIPTS[@]}"; do
  check_count \
    "$script: une capture locale de \$!" \
    1 \
    'local pid=\$!' \
    "$script"

  check "$script: PID écrit dans pid_file" \
    grep -Fq 'echo "$pid" > "$pid_file"' "$script"

  check_absent \
    "$script: PID non reconstruit avec pgrep" \
    'pid=.*pgrep|PID=.*pgrep' \
    "$script"

  check_absent \
    "$script: PID non reconstruit avec pidof" \
    'pid=.*pidof|PID=.*pidof' \
    "$script"
done


echo ""
echo "=== Ordre de capture PID ==="

for script in "${SCRIPTS[@]}"; do
  check "$script: nohup → \$! → pid_file → kill -0" \
    check_pid_order "$script"
done


echo ""
echo "=== Vérification du processus ==="

for script in "${SCRIPTS[@]}"; do
  check "$script: kill -0 vérifie le PID capturé" \
    grep -q 'kill -0 "\$pid"' "$script"

  check_absent \
    "$script: aucun kill -0 sur PID reconstruit" \
    'kill -0.*pgrep|kill -0.*pidof' \
    "$script"
done


echo ""
echo "=== Nettoyage en cas d'échec ==="

for script in "${SCRIPTS[@]}"; do
  check "$script: suppression du pid_file sur échec" \
    grep -q 'rm -f -- "\$pid_file"' "$script"
done


echo ""
echo "=== Permissions du fichier PID ==="

for script in "${SCRIPTS[@]}"; do
  check "$script: chmod explicite du pid_file" \
    grep -Eq 'chmod[[:space:]]+0?644[[:space:]]+"\$pid_file"' "$script"
done


echo ""
echo "=== Vérification API Ollama ==="

for script in "${SCRIPTS[@]}"; do
  check "$script: fonction wait_for_ollama_api" \
    grep -q '^wait_for_ollama_api()' "$script"

  check "$script: endpoint local Ollama" \
    grep -q '127\.0\.0\.1:11434/api/tags' "$script"

  check "$script: échec si API indisponible" \
    grep -q 'wait_for_ollama_api.*||.*err' "$script"
done


echo ""
echo "=== Absence des anciens patterns PID fragiles ==="

for script in "${SCRIPTS[@]}"; do
  check_absent \
    "$script: aucun tee utilisé pour écrire le PID" \
    'tee.*pid|tee.*PID' \
    "$script"

  check_absent \
    "$script: aucun \$! dans une substitution de commande" \
    '\$\(.*\$!' \
    "$script"

  check_absent \
    "$script: aucun PID écrit depuis pgrep" \
    'pgrep.*>[[:space:]]*.*pid|pgrep.*>[[:space:]]*.*PID' \
    "$script"

  check_absent \
    "$script: aucun PID écrit depuis pidof" \
    'pidof.*>[[:space:]]*.*pid|pidof.*>[[:space:]]*.*PID' \
    "$script"
done


echo ""
echo "=== Résultats ==="

echo "  Passés  : $PASS / $TOTAL"
echo "  Échoués : $FAIL / $TOTAL"

if [[ "$FAIL" -gt 0 ]]; then
  echo ""
  echo "  RESULTAT: FAIL — INVARIANT PID NON RESPECTE"
  exit 1
fi

echo ""
echo "  RESULTAT: PASS — FIDELITE PID VALIDEE"
exit 0
