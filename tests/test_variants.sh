#!/usr/bin/env bash
# Tests locaux sans réseau, sans Ollama et sans GPU.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
bash -n scripts/kali-lite-variant.sh
bash -n tests/test_variants.sh

assert_profile() {
  local slug="$1" upstream="$2" tag="$3"
  local file="variants/$slug/Modelfile"
  [[ -f "$file" ]] || { echo "Manquant : $file" >&2; exit 1; }
  grep -Fxq "FROM $upstream" "$file"
  grep -Fq 'PARAMETER num_ctx 8192' "$file"
  grep -Fq 'Ne prétends jamais avoir lu un fichier' "$file"
  if grep -Eqi '^PARAMETER[[:space:]]+stop' "$file"; then
    echo "Tokens stop spécifiques à l'amont interdits : $file" >&2
    exit 1
  fi
  bash scripts/kali-lite-variant.sh --list | grep -Fq "$tag"
  bash scripts/kali-lite-variant.sh --dry-run "$slug" | grep -Fq "ollama pull $upstream"
}

assert_profile mistral-7b mistral:7b-instruct kali-lite-mistral-7b
assert_profile olmo3-7b olmo-3:7b-instruct kali-lite-olmo3-7b
assert_profile gemma4-e2b gemma4:e2b kali-lite-gemma4-e2b

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/ollama" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MOCK_LOG"
if [[ "${MOCK_FAIL_SHOW:-0}" == "1" && "$1" == "show" ]]; then exit 1; fi
MOCK
chmod +x "$tmp/ollama"
export MOCK_LOG="$tmp/actions.log"
export PATH="$tmp:$PATH"

for slug in mistral-7b olmo3-7b gemma4-e2b; do
  : > "$MOCK_LOG"
  bash scripts/kali-lite-variant.sh --dry-run "$slug" >/dev/null
  [[ ! -s "$MOCK_LOG" ]] || { echo "Side effect en dry-run" >&2; exit 1; }

  bash scripts/kali-lite-variant.sh --create "$slug" >/dev/null
  [[ "$(wc -l < "$MOCK_LOG")" -eq 2 ]] || { echo "Commandes Ollama inattendues" >&2; exit 1; }
  grep -q '^show ' "$MOCK_LOG"
  grep -q '^create ' "$MOCK_LOG"
  ! grep -q '^pull ' "$MOCK_LOG" || { echo "Téléchargement implicite" >&2; exit 1; }

  : > "$MOCK_LOG"
  if MOCK_FAIL_SHOW=1 bash scripts/kali-lite-variant.sh --create "$slug" > /dev/null 2>&1; then
    echo "La création aurait dû échouer si la base est absente" >&2; exit 1
  fi
  [[ "$(wc -l < "$MOCK_LOG")" -eq 1 ]] || { echo "Création malgré base absente" >&2; exit 1; }
done

if bash scripts/kali-lite-variant.sh --dry-run '../intrusion' > /dev/null 2>&1; then
  echo "Profil arbitraire accepté" >&2
  exit 1
fi
echo "OK — profils cohérents, dry-run sans effet, pas de pull implicite."
