#!/usr/bin/env bash
# Simulation du diagnostic WSL2 sans service, GPU ni accès réseau réel.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
sandbox="$(mktemp -d)"
trap 'rm -rf -- "$sandbox"' EXIT
mkdir -p "$sandbox/bin"

cat > "$sandbox/bin/uname" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${TEST_KERNEL:-6.6.87.2-microsoft-standard-WSL2}"
EOF
cat > "$sandbox/bin/ollama" <<'EOF'
#!/usr/bin/env bash
echo 'ollama version 0.40.4'
EOF
cat > "$sandbox/bin/free" <<'EOF'
#!/usr/bin/env bash
echo '              total        used        free      shared  buff/cache   available'
echo 'Mem:       16777216    10000000     6000000           0      777216     7000000'
EOF
cat > "$sandbox/bin/df" <<'EOF'
#!/usr/bin/env bash
echo 'Filesystem 1024-blocks Used Available Capacity Mounted on'
echo '/dev/mock 100000000 20000000 80000000 20% /private/user/path'
EOF
cat > "$sandbox/bin/nvidia-smi" <<'EOF'
#!/usr/bin/env bash
echo 'Test NVIDIA, 8192 MiB'
EOF
cat > "$sandbox/bin/curl" <<'EOF'
#!/usr/bin/env bash
[[ " $* " == *'127.0.0.1:11434/api/version'* ]] || exit 7
[[ " $* " == *'--noproxy'* ]] || exit 7
exit 0
EOF
chmod +x "$sandbox/bin/"*

PATH="$sandbox/bin:$PATH" bash "$ROOT/scripts/check-wsl2.sh" > "$sandbox/result.txt"
grep -q 'OK — Noyau WSL2' "$sandbox/result.txt"
grep -q 'RAM — total' "$sandbox/result.txt"
grep -q 'Disque — disponible' "$sandbox/result.txt"
grep -q 'API Ollama locale' "$sandbox/result.txt"
! grep -q '/private/user/path' "$sandbox/result.txt"
! grep -q 'air-gap actif' "$sandbox/result.txt"

if TEST_KERNEL='6.6.0-generic' PATH="$sandbox/bin:$PATH" \
  bash "$ROOT/scripts/check-wsl2.sh" > /dev/null 2>&1; then
  echo 'FAIL : Linux normal accepté comme WSL2' >&2
  exit 1
fi
if TEST_KERNEL='4.4.0-Microsoft' PATH="$sandbox/bin:$PATH" \
  bash "$ROOT/scripts/check-wsl2.sh" > /dev/null 2>&1; then
  echo 'FAIL : WSL1 accepté comme WSL2' >&2
  exit 1
fi
bash "$ROOT/scripts/check-wsl2.sh" --help >/dev/null
echo 'PASS : diagnostic WSL2 simulé, sans réseau externe'
