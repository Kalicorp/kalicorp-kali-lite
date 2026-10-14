#!/usr/bin/env bash
# Diagnostic de prérequis uniquement ; aucune installation ni modification.
set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  cat <<'HELP'
Usage: bash scripts/check-wsl2.sh [--help]
Exécuter à l'intérieur d'Ubuntu/WSL2, pas dans PowerShell.
Vérifie le noyau WSL2, la présence d'Ollama et la visibilité NVIDIA.
N'installe pas de composants et n'envoie pas de données.
HELP
  exit 0
fi
if [[ "$#" -ne 0 ]]; then
  echo 'Argument non reconnu. Utiliser --help.' >&2
  exit 2
fi

kernel="$(uname -r)"
if [[ "$kernel" != *microsoft* && "$kernel" != *Microsoft* && "$kernel" != *WSL* ]]; then
  printf 'INCONNU/NON-WSL : noyau %s ; lancer sous Ubuntu/WSL2.\n' "$kernel" >&2
  exit 2
fi
if [[ "$kernel" != *WSL2* && "$kernel" != *wsl2* ]]; then
  printf 'NON VALIDÉ : noyau %s. Vérifier depuis PowerShell : wsl -l -v\n' "$kernel" >&2
  exit 2
fi
echo 'OK — Noyau WSL2 détecté.'
if command -v ollama >/dev/null 2>&1; then
  echo 'OK — Commande Ollama disponible.'
  ollama --version || echo 'ATTENTION — Ollama présent mais non fonctionnel.'
else
  echo 'ATTENTION — Ollama absent du PATH WSL2 ; installation manuelle requise.'
fi
if command -v nvidia-smi >/dev/null 2>&1; then
  echo 'GPU — nvidia-smi détecté : vérifier ci-dessous.'
  nvidia-smi --query-gpu=name,memory.total --format=csv,noheader || echo 'ATTENTION — GPU non accessible.'
else
  echo 'GPU — nvidia-smi absent ; inférence CPU possible selon RAM, NVIDIA à diagnostiquer.'
fi
echo 'Diagnostic uniquement : une vérification de bout en bout reste nécessaire.'
