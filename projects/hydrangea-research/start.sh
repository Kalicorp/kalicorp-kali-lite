#!/usr/bin/env bash
# Interactive, local-only front door to the research workflow.
set -euo pipefail
cd "$(dirname "$0")"

SOURCES="${1:-data/sources.jsonl}"
QUESTION="${2:-}"
if [[ ! -f "$SOURCES" ]]; then
  echo "Aucune source à : $SOURCES" >&2
  echo "Créer data/sources.jsonl à partir de sources réelles et vérifiées." >&2
  echo "Pour une simulation seulement : bash start.sh examples/sources.demo.jsonl" >&2
  exit 2
fi

python3 workflow.py validate --sources "$SOURCES"

if [[ -z "${KALI_MODEL:-}" ]]; then
  if command -v ollama >/dev/null 2>&1; then
    echo
    echo "Modèles locaux Ollama détectables :"
    ollama list || true
  fi
  read -r -p "Nom exact du modèle local (KALI_MODEL) : " KALI_MODEL
  export KALI_MODEL
fi
if [[ -z "$KALI_MODEL" ]]; then
  echo "Aucun modèle sélectionné. Arrêt." >&2
  exit 2
fi

if [[ -z "$QUESTION" ]]; then
  read -r -p "Question à étudier : " QUESTION
fi
if [[ -z "$QUESTION" ]]; then
  echo "Question vide. Arrêt." >&2
  exit 2
fi

export KALI_API_BASE="${KALI_API_BASE:-http://127.0.0.1:11434/v1}"
echo
echo "Modèle : $KALI_MODEL"
echo "API : $KALI_API_BASE"
echo "Aucun transfert distant autorisé par ce lanceur."
OUT="artifacts/run-$(date -u +%Y%m%dT%H%M%SZ)"
python3 workflow.py run --sources "$SOURCES" --question "$QUESTION" \
  --out "$OUT"
echo "Dossier de revue : $OUT"
