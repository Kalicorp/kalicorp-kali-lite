#!/usr/bin/env bash
# Sélection explicite de quantifications Ollama amont, sans pull ni sudo implicite.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT

usage() {
  cat <<'HELP'
Usage:
  bash scripts/kali-lite-quant.sh --list
  bash scripts/kali-lite-quant.sh --dry-run mistral-7b|olmo3-7b|gemma4-e2b q4|q8
  bash scripts/kali-lite-quant.sh --create  mistral-7b|olmo3-7b|gemma4-e2b q4|q8

Aucun téléchargement implicite. Le modèle amont exact doit être déjà présent.
Les nouveaux tags Kali-Lite sont distincts des modèles stables.
HELP
}

resolve() {
  case "$variant:$quant" in
    mistral-7b:q4) base="mistral:7b-instruct"; source="mistral:7b-instruct-v0.3-q4_K_M" ;;
    mistral-7b:q8) base="mistral:7b-instruct"; source="mistral:7b-instruct-v0.3-q8_0" ;;
    olmo3-7b:q4) base="olmo-3:7b-instruct"; source="olmo-3:7b-instruct-q4_K_M" ;;
    olmo3-7b:q8) base="olmo-3:7b-instruct"; source="olmo-3:7b-instruct-q8_0" ;;
    gemma4-e2b:q4) base="gemma4:e2b"; source="gemma4:e2b-it-q4_K_M" ;;
    gemma4-e2b:q8) base="gemma4:e2b"; source="gemma4:e2b-it-q8_0" ;;
    *) printf 'Profil ou quantification inconnus : %s / %s\n' "$variant" "$quant" >&2; exit 2 ;;
  esac
  tag="kali-lite-${variant}-${quant}"
  modelfile="$ROOT/variants/$variant/Modelfile"
  if [[ ! -f "$modelfile" ]] || ! grep -Fxq "FROM $base" "$modelfile"; then
    printf 'Modelfile manquant ou base amont inattendue : %s\n' "$modelfile" >&2
    exit 1
  fi
}

if [[ "$#" -eq 1 && "$1" == "--list" ]]; then
  printf '%-12s %-14s %s\n' 'PROFIL' 'QUANTIFICATION' 'MODÈLE SOURCE'
  for variant in mistral-7b olmo3-7b gemma4-e2b; do
    for quant in q4 q8; do
      resolve
      printf '%-12s %-14s %s\n' "$variant" "$quant" "$source"
    done
  done
  exit 0
fi

if [[ "$#" -ne 3 ]] || [[ "$1" != "--dry-run" && "$1" != "--create" ]]; then
  usage >&2
  exit 2
fi

action="$1"; variant="$2"; quant="$3"
resolve

if [[ "$action" == "--dry-run" ]]; then
  printf 'DRY-RUN — aucune écriture ni commande Ollama exécutée.\n'
  printf 'Source locale requise : %s\n' "$source"
  printf 'Profil : %s\nTag : %s\n' "$modelfile" "$tag"
  printf 'Pour télécharger explicitement : ollama pull %s\n' "$source"
  exit 0
fi

if ! command -v ollama >/dev/null 2>&1; then
  echo 'Ollama introuvable.' >&2
  exit 1
fi
if ! ollama show "$source" >/dev/null 2>&1; then
  printf 'Source absente. Téléchargement manuel : ollama pull %s\n' "$source" >&2
  exit 1
fi

# La substitution ne modifie jamais le Modelfile suivi par Git.
# Le temporaire est privé (mktemp), supprimé dans tous les cas.
tmp="$(mktemp "${TMPDIR:-/tmp}/kali-lite-quant.XXXXXXXX")"
trap 'rm -f -- "$tmp"' EXIT
awk -v original="FROM $base" -v replacement="FROM $source" '
  $0 == original { print replacement; next }
  { print }
' "$modelfile" > "$tmp"

if ! grep -Fxq "FROM $source" "$tmp"; then
  echo 'Échec de vérification de la source temporaire.' >&2
  exit 1
fi
ollama create "$tag" -f "$tmp"
printf 'Profil créé : %s\nUtilisation : ollama run %s\n' "$tag" "$tag"
