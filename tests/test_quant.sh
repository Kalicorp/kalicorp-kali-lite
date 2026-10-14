#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

bash -n scripts/kali-lite-quant.sh
bash -n scripts/check-wsl2.sh
bash -n tests/test_quant.sh

temp="$(mktemp -d)"
trap 'rm -rf -- "$temp"' EXIT
cat > "$temp/ollama" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$MOCK_LOG"
case "$1" in
  show) [[ "${MOCK_SHOW_FAIL:-0}" != "1" ]] ;;
  create)
    [[ "$3" == "-f" ]] || exit 3
    awk '/^FROM / {print; exit}' "$4" >> "$MOCK_LOG"
    ;;
  *) exit 4 ;;
esac
MOCK
chmod 700 "$temp/ollama"
export MOCK_LOG="$temp/trace"
export PATH="$temp:$PATH"

for variant in mistral-7b olmo3-7b gemma4-e2b; do
  for quant in q4 q8; do
    case "$variant:$quant" in
      mistral-7b:q4) expected="mistral:7b-instruct-v0.3-q4_K_M" ;;
      mistral-7b:q8) expected="mistral:7b-instruct-v0.3-q8_0" ;;
      olmo3-7b:q4) expected="olmo-3:7b-instruct-q4_K_M" ;;
      olmo3-7b:q8) expected="olmo-3:7b-instruct-q8_0" ;;
      gemma4-e2b:q4) expected="gemma4:e2b-it-q4_K_M" ;;
      gemma4-e2b:q8) expected="gemma4:e2b-it-q8_0" ;;
    esac

    : > "$MOCK_LOG"
    result="$(bash scripts/kali-lite-quant.sh --dry-run "$variant" "$quant")"
    [[ "$result" == *"$expected"* ]]
    [[ ! -s "$MOCK_LOG" ]] || { echo 'Dry-run a utilisé Ollama' >&2; exit 1; }
    : > "$MOCK_LOG"
    bash scripts/kali-lite-quant.sh --create "$variant" "$quant" >/dev/null
    [[ "$(cat "$MOCK_LOG")" == "$(printf 'show\ncreate\nFROM %s' "$expected")" ]] || {
      echo "Modelfile temporaire invalide : $variant/$quant" >&2
      cat "$MOCK_LOG" >&2
      exit 1
    }
    : > "$MOCK_LOG"
    if MOCK_SHOW_FAIL=1 bash scripts/kali-lite-quant.sh --create "$variant" "$quant" >/dev/null 2>&1; then
      echo 'Création acceptée sans modèle amont' >&2
      exit 1
    fi
    [[ "$(cat "$MOCK_LOG")" == "show" ]] || exit 1
  done
done

if bash scripts/kali-lite-quant.sh --create '../secret' q4 >/dev/null 2>&1; then
  echo 'Chemin arbitraire accepté' >&2
  exit 1
fi
if bash scripts/kali-lite-quant.sh --create mistral-7b xyz >/dev/null 2>&1; then
  echo 'Quantification arbitraire acceptée' >&2
  exit 1
fi
bash scripts/check-wsl2.sh --help | grep -q -- '--help'
echo 'OK : 6 quantifications, dry-run, contrôle amont, garde-fous WSL2.'
