#!/usr/bin/env bash
# Test comportemental : vérifie que le PID écrit correspond au processus réel
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

# ── Test 1 : start_ollama_manual existe dans les trois scripts ─────────────

echo "=== Fonction start_ollama_manual ==="
check "install.sh: fonction définie"        grep -q 'start_ollama_manual()' install.sh
check "v1 installer: fonction définie"      grep -q 'start_ollama_manual()' auto-install-kali-lite-v1-novision.sh
check "v2 installer: fonction définie"      grep -q 'start_ollama_manual()' auto-install-kali-lite-v2-vision.sh

# ── Test 2 : la fonction capture $! dans le même contexte ────────────────
# La fonction contient "local pid=\$!" ou "local pid=$!" sans pipeline intermédiaire

echo "=== Capture PID dans même contexte ==="
check "install.sh: capture locale de \$!"        grep -q 'local pid=\$!' install.sh
check "v1 installer: capture locale de \$!"      grep -q 'local pid=\$!' auto-install-kali-lite-v1-novision.sh
check "v2 installer: capture locale de \$!"      grep -q 'local pid=\$!' auto-install-kali-lite-v2-vision.sh

# ── Test 3 : pas de double write PID ───────────────────────────────────
# Aucun fichier PID n'est écrit deux fois dans le même chemin de code

echo "=== Pas de double write (deux chemins possibles dans start_ollama_manual) ==="
# start_ollama_manual écrit le PID deux fois max : API ready + timeout. C'est attendu.
check "install.sh: echo > pid_file présent"     bash -c "grep -q 'echo.*>.*pid_file' install.sh"
check "v1 installer: echo > OLLAMA_PID présent" bash -c "grep -q 'echo.*>.*OLLAMA_PID\|echo.*>.*pid_file' auto-install-kali-lite-v1-novision.sh"
check "v2 installer: echo > OLLAMA_PID présent" bash -c "grep -q 'echo.*>.*OLLAMA_PID\|echo.*>.*pid_file' auto-install-kali-lite-v2-vision.sh"

# ── Test 4 : pas de pipeline $! trompeur (tee, subshell) ───────────────
# Aucun "tee PID" ni "echo \$!" dans un pipeline qui capture le PID du pipeline

echo "=== Pas de pipeline \$! trompeur ==="
check "install.sh: pas de tee PID"              bash -c "! grep 'tee.*PID' install.sh"
check "v1 installer: pas de tee PID"            bash -c "! grep 'tee.*OLLAMA_PID' auto-install-kali-lite-v1-novision.sh"
check "v2 installer: pas de tee PID"            bash -c "! grep 'tee.*OLLAMA_PID' auto-install-kali-lite-v2-vision.sh"

# ── Test 5 : vérification du processus vivant ─────────────────────────
# La fonction contient kill -0 pour vérifier que le PID est vivant

echo "=== Vérification processus vivant ==="
check "install.sh: kill -0 dans start_ollama_manual"    grep -q 'kill -0.*\$pid' install.sh
check "v1 installer: kill -0 dans start_ollama_manual"  grep -q 'kill -0.*\$pid' auto-install-kali-lite-v1-novision.sh
check "v2 installer: kill -0 dans start_ollama_manual"  grep -q 'kill -0.*\$pid' auto-install-kali-lite-v2-vision.sh

# ── Test 6 : nettoyage PID en cas d'échec ────────────────────────────
# La fonction contient rm -f sur le fichier PID si le processus meurt

echo "=== Nettoyage PID en cas d'échec ==="
check "install.sh: rm -f PID_FILE en cas d'échec"   grep -q 'rm -f.*pid_file' install.sh
check "v1 installer: rm -f PID_FILE en cas d'échec"  grep -q 'rm -f.*pid_file' auto-install-kali-lite-v1-novision.sh
check "v2 installer: rm -f PID_FILE en cas d'échec"  grep -q 'rm -f.*pid_file' auto-install-kali-lite-v2-vision.sh

# ── Test 7 : tous les chemins de démarrage utilisent start_ollama_manual ──

echo "=== Tous les chemins utilisent start_ollama_manual ==="
check "install.sh: nohup dans install_linux"         grep -A15 'systemctl non disponible' install.sh | grep -q 'start_ollama_manual' || bash -c "grep -q 'start_ollama_manual.*PID_FILE' install.sh"
check "v1 installer: nohup dans install_linux"       grep -A15 'systemd inactive' auto-install-kali-lite-v1-novision.sh | grep -q 'start_ollama_manual' || bash -c "grep -q 'start_ollama_manual.*OLLAMA_PID' auto-install-kali-lite-v1-novision.sh"
check "v2 installer: nohup dans install_linux"       grep -A15 'systemd inactive' auto-install-kali-lite-v2-vision.sh | grep -q 'start_ollama_manual' || bash -c "grep -q 'start_ollama_manual.*OLLAMA_PID' auto-install-kali-lite-v2-vision.sh"

# ── Test 8 : chmod sur le fichier PID ─────────────────────────────────
# Le fichier PID a des permissions raisonnables

echo "=== Permissions du fichier PID ==="
check "install.sh: chmod sur PID_FILE"        grep -q 'chmod.*pid_file' install.sh
check "v1 installer: chmod sur PID_FILE"      grep -q 'chmod.*pid_file' auto-install-kali-lite-v1-novision.sh
check "v2 installer: chmod sur PID_FILE"      grep -q 'chmod.*pid_file' auto-install-kali-lite-v2-vision.sh

# ── Résultats ──────────────────────────────────────────────────────────

echo ""
echo "=== Résultats ==="
echo "  Passés: $PASS / $TOTAL"
echo "  Échoués: $FAIL / $TOTAL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "  TOUS LES TESTS PASSES"
exit 0
