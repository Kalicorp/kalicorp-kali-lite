#!/usr/bin/env bash
# Diagnostic de prérequis uniquement ; aucune installation ni modification.
set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  cat <<'HELP'
Usage: bash scripts/check-wsl2.sh [--help]
Exécuter à l'intérieur d'Ubuntu/WSL2, pas dans PowerShell.
Vérifie WSL2, Ollama, GPU, RAM, disque et API Ollama locale.
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
echo 'INFO — Aucun test Internet ; le diagnostic ne prouve pas un air-gap.'
# Ne pas afficher les chemins de montage ni identifiants de l'utilisateur.
if command -v free >/dev/null 2>&1; then
  ram_info="$(free -k | awk '$1 == "Mem:" && NF >= 7 {printf "RAM — total : %.1f Gio ; disponible : %.1f Gio", $2/1048576, $7/1048576}' || true)"
  if [[ -n "$ram_info" ]]; then
    printf '%s\n' "$ram_info"
  else
    echo 'RAM — mesure indisponible.'
  fi
else
  echo 'RAM — commande free indisponible.'
fi
if command -v df >/dev/null 2>&1; then
  disk_info="$(df -Pk . | awk 'NR == 2 {printf "Disque — disponible : %.1f Gio", $4/1048576}' || true)"
  if [[ -n "$disk_info" ]]; then
    printf '%s\n' "$disk_info"
  else
    echo 'Disque — mesure indisponible.'
  fi
else
  echo 'Disque — commande df indisponible.'
fi
if [[ -e /dev/dxg ]]; then
  echo 'GPU — /dev/dxg présent (ne garantit pas une inférence accélérée).'
else
  echo 'GPU — /dev/dxg absent ; vérifier la configuration Windows et WSL.'
fi
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
if command -v curl >/dev/null 2>&1; then
  if curl -fsS --noproxy '*' --connect-timeout 1 --max-time 2 -o /dev/null \
    http://127.0.0.1:11434/api/version; then
    echo 'OK — API Ollama locale sur 127.0.0.1:11434 accessible.'
  else
    echo 'ATTENTION — API Ollama locale indisponible ou non démarrée.'
  fi
else
  echo 'INFO — curl absent ; API Ollama locale non vérifiée.'
fi
echo 'Diagnostic uniquement : une vérification de bout en bout reste nécessaire.'
