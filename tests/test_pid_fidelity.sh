#!/usr/bin/env bash
# Tests statiques des invariants PID pour start_ollama_manual
# - Vérification des motifs dans le code source (grep)
# - Les tests comportementaux (exécution avec faux ollama) sont reportés au prochain cycle
#   — voir ticket : validation runtime à effectuer sur RyzenM demain
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

# ═══════════════════════════════════════════════════════════════════════════════
# Tests statiques : la fonction start_ollama_manual existe dans les trois scripts
# ═══════════════════════════════════════════════════════════════════════════════

echo "=== Fonction start_ollama_manual ==="
check "install.sh: fonction définie"        grep -q 'start_ollama_manual()' install.sh
check "v1 installer: fonction définie"      grep -q 'start_ollama_manual()' auto-install-kali-lite-v1-novision.sh
check "v2 installer: fonction définie"      grep -q 'start_ollama_manual()' auto-install-kali-lite-v2-vision.sh

# ═══════════════════════════════════════════════════════════════════════════════
# Capture PID dans le même contexte (nohup … & ; local pid=$!)
# ═══════════════════════════════════════════════════════════════════════════════

echo "=== Capture PID dans même contexte ==="
check "install.sh: capture locale de \$!"        grep -q 'local pid=\$!' install.sh
check "v1 installer: capture locale de \$!"      grep -q 'local pid=\$!' auto-install-kali-lite-v1-novision.sh
check "v2 installer: capture locale de \$!"      grep -q 'local pid=\$!' auto-install-kali-lite-v2-vision.sh

# ═══════════════════════════════════════════════════════════════════════════════
# Pas de double write PID dans le même chemin de code
# ═══════════════════════════════════════════════════════════════════════════════

echo "=== Pas de double write ==="
check "install.sh: echo > pid_file présent"     bash -c "grep -q 'echo.*>.*pid_file' install.sh"
check "v1 installer: echo > OLLAMA_PID présent" bash -c "grep -q 'echo.*>.*OLLAMA_PID\|echo.*>.*pid_file' auto-install-kali-lite-v1-novision.sh"
check "v2 installer: echo > OLLAMA_PID présent" bash -c "grep -q 'echo.*>.*OLLAMA_PID\|echo.*>.*pid_file' auto-install-kali-lite-v2-vision.sh"

# ═══════════════════════════════════════════════════════════════════════════════
# Pas de pipeline \$! trompeur (tee, subshell)
# ═══════════════════════════════════════════════════════════════════════════════

echo "=== Pas de pipeline \$! trompeur ==="
check "install.sh: pas de tee PID"              bash -c "! grep 'tee.*PID' install.sh"
check "v1 installer: pas de tee PID"            bash -c "! grep 'tee.*OLLAMA_PID' auto-install-kali-lite-v1-novision.sh"
check "v2 installer: pas de tee PID"            bash -c "! grep 'tee.*OLLAMA_PID' auto-install-kali-lite-v2-vision.sh"

# ═══════════════════════════════════════════════════════════════════════════════
# Vérification du processus vivant (kill -0)
# ═══════════════════════════════════════════════════════════════════════════════

echo "=== Vérification processus vivant ==="
check "install.sh: kill -0 dans start_ollama_manual"    grep -q 'kill -0.*\$pid' install.sh
check "v1 installer: kill -0 dans start_ollama_manual"  grep -q 'kill -0.*\$pid' auto-install-kali-lite-v1-novision.sh
check "v2 installer: kill -0 dans start_ollama_manual"  grep -q 'kill -0.*\$pid' auto-install-kali-lite-v2-vision.sh

# ═══════════════════════════════════════════════════════════════════════════════
# Nettoyage PID en cas d'échec (rm -f)
# ═══════════════════════════════════════════════════════════════════════════════

echo "=== Nettoyage PID en cas d'échec ==="
check "install.sh: rm -f PID_FILE en cas d'échec"   grep -q 'rm -f.*pid_file' install.sh
check "v1 installer: rm -f PID_FILE en cas d'échec"  grep -q 'rm -f.*pid_file' auto-install-kali-lite-v1-novision.sh
check "v2 installer: rm -f PID_FILE en cas d'échec"  grep -q 'rm -f.*pid_file' auto-install-kali-lite-v2-vision.sh

# ═══════════════════════════════════════════════════════════════════════════════
# Tous les chemins de démarrage utilisent start_ollama_manual
# ═══════════════════════════════════════════════════════════════════════════════

echo "=== Tous les chemins utilisent start_ollama_manual ==="
check "install.sh: nohup dans install_linux"         grep -A15 'systemctl non disponible' install.sh | grep -q 'start_ollama_manual' || bash -c "grep -q 'start_ollama_manual.*PID_FILE' install.sh"
check "v1 installer: nohup dans install_linux"       grep -A15 'systemd inactive' auto-install-kali-lite-v1-novision.sh | grep -q 'start_ollama_manual' || bash -c "grep -q 'start_ollama_manual.*OLLAMA_PID' auto-install-kali-lite-v1-novision.sh"
check "v2 installer: nohup dans install_linux"       grep -A15 'systemd inactive' auto-install-kali-lite-v2-vision.sh | grep -q 'start_ollama_manual' || bash -c "grep -q 'start_ollama_manual.*OLLAMA_PID' auto-install-kali-lite-v2-vision.sh"

# ═══════════════════════════════════════════════════════════════════════════════
# Permissions du fichier PID (chmod)
# ═══════════════════════════════════════════════════════════════════════════════

echo "=== Permissions du fichier PID ==="
check "install.sh: chmod sur PID_FILE"        grep -q 'chmod.*pid_file' install.sh
check "v1 installer: chmod sur PID_FILE"      grep -q 'chmod.*pid_file' auto-install-kali-lite-v1-novision.sh
check "v2 installer: chmod sur PID_FILE"      grep -q 'chmod.*pid_file' auto-install-kali-lite-v2-vision.sh

# ═══════════════════════════════════════════════════════════════════════════════
# Résultats finaux
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo "=== Résultats ==="
echo "  Passés: $PASS / $TOTAL"
echo "  Échoués: $FAIL / $TOTAL"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "  CERTAINS TESTS ONT ECHOUÉ"
  exit 1
fi
echo "  TOUS LES TESTS PASSES"
exit 0
