# Refactor Brief — Cross-Platform Kali-Lite Installer

## Contexte
Le script `install.sh` actuel est Linux-only (Debian/Kali). Nous refactorisons pour supporter **Linux + macOS** en single entry point avec fonctions séparées.

## Specifications

### 1. Architecture de haut niveau
- **Script principal** : `install.sh` avec détecteur d'OS au démarrage
- **Fonctions séparées** : `install_linux()` et `install_macos()` — self-contained, pas d'appels croisés
- **Logic partagée** : Modelfile, alias injection, shell RC cleanup — factorisées dans `setup_modelfile()`, `setup_alias()`, `cleanup_shell_rc()`
- **No WSL2** pour l'instant — Phase 2 si besoin

### 2. Flux d'exécution

```
main()
├─ Detect OS (uname -s)
├─ Verify EUID=0 (sudo)
├─ Verify curl
├─ Common setup (REAL_USER, REAL_HOME, SHELL_RC)
└─ Dispatch:
    ├─ Linux → install_linux()
    ├─ Darwin → install_macos()
    └─ * → err()

install_linux()
├─ Sections 0-6 (logic inchangé)
└─ Appelle shared functions (setup_modelfile, setup_alias, etc)

install_macos()
├─ Équivalent macOS (Homebrew, zshrc, system_profiler)
└─ Appelle shared functions (idem)
```

### 3. Linux — Inchangé

Garder la structure actuelle (sections 0/6 — Prérequis, Ollama, Daemon, qwen3:8b, Modelfile, Model Creation, Claude Code + Alias).

**Décalages macOS uniquement :**
- `nvidia-smi` → `system_profiler SPDisplaysDataType` pour GPU detection
- Aucun `systemctl` → `brew services` + `launchctl` pour daemon management
- Package managers : `apt` → `brew`

### 4. macOS Specifics

| Aspect | macOS Implementation |
|---|---|
| **Ollama** | `brew install ollama` — daemon via `brew services start ollama` ou `ollama serve` en bg |
| **Node.js** | `brew install node` — no NodeSource, simpler |
| **Shell RC default** | `~/.zshrc` (Apple Silicon default). Fallback `~/.bashrc` if zsh not in $SHELL |
| **GPU detect** | `system_profiler SPDisplaysDataType` → parse GPU name (Apple Silicon / AMD / Intel iGPU) |
| **Log paths** | `~/Library/Logs/kalicorp/` instead of `/var/log/kalicorp/` |
| **PID paths** | `~/Library/kalicorp/ollama.pid` instead of `/var/run/kalicorp-ollama.pid` |
| **Daemon start** | `brew services` if available, else `nohup ollama serve > ~/Library/Logs/kalicorp/ollama.log 2>&1 &` |

### 5. Shared Functions (Factorisées)

```bash
# Couleurs, helpers (ok, warn, err, info, section)
# GPU detection → separate function for Linux vs macOS
# Modelfile generation → identical, shared
# Alias injection → identical logic, shared
# Shell RC cleanup → identical, shared
# Final summary → adapted for paths, shared core
```

### 6. Constraints

- ✅ **Modèles et Modelfile** — identiques Linux/macOS
- ✅ **Alias `kali-lite`** — identiques (env vars, `--dangerously-skip-permissions`)
- ✅ **Telemetry off** — Claude config identical
- ✅ **PERSO_FOUND logic** — identical, cross-platform
- ⚠️ **Error handling** — adapt messages (no systemd on macOS, use brew services)
- ⚠️ **Paths** — `/var/log/kalicorp/` on Linux → `~/Library/Logs/kalicorp/` on macOS

### 7. Deliverables

1. **Single `install.sh`** with OS dispatch
2. **Minimal duplication** — shared functions only once
3. **Clear section comments** : `# ── SHARED ──`, `# ── LINUX-ONLY ──`, `# ── MACOS-ONLY ──`
4. **Usage unchanged** :
   ```bash
   curl -fsSL https://raw.githubusercontent.com/balduregates1/kalicorp-hardening/main/install.sh | sudo bash
   ```

---

**Task for Kali-Lite** :
1. Refactor `install.sh` to above spec
2. Preserve all current Linux logic (sections 0-6)
3. Implement `install_macos()` parallel to Linux version
4. Factor shared code (Modelfile, alias, cleanup, summary)
5. Update header comment to reflect Linux/macOS support
6. Test structure on paper — no execution needed, just code review-ready
