#!/usr/bin/env bash
# Laboratoire Kali-Lite : aucun téléchargement ni élévation de privilèges implicite.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT

usage() {
  cat <<'HELP'
Usage:
  bash scripts/kali-lite-variant.sh --list
  bash scripts/kali-lite-variant.sh --dry-run mistral-7b|olmo3-7b|gemma4-e2b
  bash scripts/kali-lite-variant.sh --create  mistral-7b|olmo3-7b|gemma4-e2b

--dry-run  Affiche les opérations sans lancer Ollama ou télécharger quoi que ce soit.
--create   Utilise un modèle amont DÉJÀ présent localement ; aucun pull implicite.
HELP
}

if [[ "$#" -eq 1 && "$1" == "--list" ]]; then
  printf '%-15s %-24s %s\n' 'PROFIL' 'BASE OLLAMA' 'TAG LOCAL'
  printf '%-15s %-24s %s\n' 'mistral-7b' 'mistral:7b-instruct' 'kali-lite-mistral-7b'
  printf '%-15s %-24s %s\n' 'olmo3-7b' 'olmo-3:7b-instruct' 'kali-lite-olmo3-7b'
  printf '%-15s %-24s %s\n' 'gemma4-e2b' 'gemma4:e2b' 'kali-lite-gemma4-e2b'
  exit 0
fi

if [[ "$#" -ne 2 ]]; then
  usage >&2
  exit 2
fi

action="$1"
variant="$2"
if [[ "$action" != "--dry-run" && "$action" != "--create" ]]; then
  usage >&2
  exit 2
fi

case "$variant" in
  mistral-7b) upstream="mistral:7b-instruct"; tag="kali-lite-mistral-7b" ;;
  olmo3-7b) upstream="olmo-3:7b-instruct"; tag="kali-lite-olmo3-7b" ;;
  gemma4-e2b) upstream="gemma4:e2b"; tag="kali-lite-gemma4-e2b" ;;
  *) printf 'Profil inconnu : %s\n' "$variant" >&2; usage >&2; exit 2 ;;
esac

modelfile="$ROOT/variants/$variant/Modelfile"
if [[ ! -f "$modelfile" ]]; then
  printf 'Modelfile manquant : %s\n' "$modelfile" >&2
  exit 1
fi

# Ne jamais déployer un profil pointant vers un autre modèle que le profil déclaré.
if ! grep -Fxq "FROM $upstream" "$modelfile"; then
  printf 'Base inattendue dans %s (attendu : %s)\n' "$modelfile" "$upstream" >&2
  exit 1
fi

if [[ "$action" == "--dry-run" ]]; then
  printf 'MODE DRY-RUN — aucune action réelle.\n'
  printf 'Modèle amont requis : %s\n' "$upstream"
  printf 'Tag local : %s\n' "$tag"
  printf 'Modelfile : %s\n' "$modelfile"
  printf 'Commandes manuelles :\n  ollama pull %s\n  ollama create %s -f %s\n' "$upstream" "$tag" "$modelfile"
  exit 0
fi

if ! command -v ollama >/dev/null 2>&1; then
  printf "Ollama introuvable. Installe-le séparément puis réessaie.\n" >&2
  exit 1
fi
if ! ollama show "$upstream" >/dev/null 2>&1; then
  printf 'Modèle amont absent : %s\nInstalle-le explicitement : ollama pull %s\n' "$upstream" "$upstream" >&2
  exit 1
fi

ollama create "$tag" -f "$modelfile"
printf 'Profil créé localement : %s\nLancement facultatif : ollama run %s\n' "$tag" "$tag"
