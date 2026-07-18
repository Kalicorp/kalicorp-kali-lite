<div align="center">

# Kali-Lite

![Kali-Lite Banner](assets/kali-lite-banner.png)

**Modèles IA frugaux souverains — 100 % local • Ollama • Cross-platform**

[![Ollama](https://img.shields.io/badge/Ollama-qwen3:8b-%2312B7F5?style=for-the-badge&logo=ollama)](https://ollama.com)
[![VRAM](https://img.shields.io/badge/VRAM-8--10%20Go-%2322c55e?style=for-the-badge)](#)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-%23f37726?style=for-the-badge)](LICENSE)
[![Platforms](https://img.shields.io/badge/Platforms-Linux%20%7C%20macOS-%236366f1?style=for-the-badge)](#)
[![Sovereign](https://img.shields.io/badge/Souverain-%23EA580C?style=for-the-badge)](https://app.kalicorp.fr)

</div>

---

## 🇫🇷 IA Frugale & Souveraine

**Kali-Lite** est la famille de modèles IA de **Kalicorp** : conçue pour tourner sur du matériel modeste, 100 % local, sans télémétrie, sans cloud, sans compromis sur la souveraineté des données.

Deux versions selon tes besoins :

| Version | Moteur | VRAM | Vision | Cas d'usage | Taille |
|---|---|---|---|---|---|
| **Kali-Lite** | Qwen3 8B | ~8 Go | ❌ | Chat rapide, code, assistance système | ~5,2 Go |
| **Kali-Lite v2** | Qwen3.5 9B Vision | ~10 Go | ✅ | Analyse d'images + chat + code | ~6,8 Go |

---

## ⚡ Installation

### Méthode recommandée — vérification avant exécution

Télécharge le script, vérifie son empreinte SHA-256 publiée dans ce dépôt, lis-le, puis exécute-le localement.

```bash
# 1. Télécharger
curl -fsSL -o install.sh https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/auto-install-kali-lite-v1-novision.sh

# 2. Vérifier l'empreinte (comparer avec SHA-256 publié dans ce dépôt)
sha256sum install.sh

# 3. Lire le script avant exécution
less install.sh

# 4. Exécuter localement
bash install.sh   # macOS — sans sudo
sudo bash install.sh  # Linux — nécessite root
```

### Méthode rapide (pipe) — pour usage répété et confiance établie

> **Note** : Cette méthode télécharge et exécute un script distant en une commande. Elle appelle les installateurs officiels d'Ollama et, selon le système, de NodeSource ou Homebrew. Utilise-la uniquement si tu as déjà vérifié l'intégrité du script.

### Kali-Lite (8 Go VRAM — sans vision)

```bash
curl -fsSL https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/auto-install-kali-lite-v1-novision.sh | bash
```

### Kali-Lite v2 (10 Go VRAM — avec vision)

```bash
curl -fsSL https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/auto-install-kali-lite-v2-vision.sh | bash
```

> **Temps moyen** : 15-20 min (téléchargement du modèle inclus)
> **Après installation** : `kali-lite` ou `ollama run kali-lite-v2`

---

## 🛡️ Pourquoi Kali-Lite ?

- **100 % local** — aucune donnée ne quitte ta machine
- **Identité Kalicorp** — Anima du Sanctuaire intégrée
- **Compatible Claude Code v2+** en local (proxy Anthropic)
- **Cross-platform** — Linux (Kali/Debian/Ubuntu/Arch) + macOS (Intel/Apple Silicon)
- **Frugalité extrême** — tourne sur laptop 8 Go VRAM
- **RGPD & AI Act** — conçu pour faciliter un déploiement local et la maîtrise des données. La conformité complète dépend du contexte d'utilisation, de la gouvernance et des obligations applicables à l'opérateur.

---

## 🖥️ Matériel testé & validé

| Configuration | Statut |
|---|---|
| RTX 3080 8 Go | ✅ |
| RTX 4070 | ✅ |
| Apple Silicon M1/M2/M3 | ✅ |
| Kali Linux / Ubuntu | ✅ |
| macOS 11+ | ✅ |

**Minimal** : 8 Go VRAM + 16 Go RAM
**Recommandé** : 10 Go+ VRAM + 32 Go RAM

---

## 📦 Cas d'usage

- Assistance système Linux souveraine
- Audit & durcissement de sécurité
- Analyse de code & développement
- Analyse d'images (v2 Vision uniquement)
- Formation & démonstrations IA locale
- Collectivités & TPE soucieuses de la souveraineté

---

## 🚫 Ce que Kali-Lite n'est PAS

- ❌ Pas un modèle cloud (OpenAI, Google, etc.)
- ❌ Pas un outil d'attaque offensive
- ❌ Pas de télémétrie ni de tracking
- ❌ Pas de dépendance externe après installation

---

## 📚 Documentation

| Fichier | Description |
|---|---|
| [INSTALLATION.md](INSTALLATION.md) | Guide d'installation détaillé |
| [REFACTOR_BRIEF.md](REFACTOR_BRIEF.md) | Architecture du script d'installation |
| [MODEL-CARD.md](MODEL-CARD.md) | Fiche technique du modèle (Hugging Face style) |
| [SECURITY.md](SECURITY.md) | Politique de sécurité et divulgation responsable |
| [SHA256SUMS](SHA256SUMS) | Empreintes SHA-256 des scripts d'installation |
| [LICENSE](LICENSE) | GPL-2.0 |

---

## 🗺️ Roadmap 2026

- [x] Release v2.0 — dual version (8B + 9B Vision)
- [x] GitHub Actions — tests automatisés des installers
- [ ] Support Windows (WSL2 natif)
- [ ] Quantisations GGUF supplémentaires (Q4_K_M, Q5_K_M)
- [x] Organisation GitHub Kalicorp

---

<div align="center">

**Kalicorp — Le Sanctuaire numérique européen**
2026 • [app.kalicorp.fr](https://app.kalicorp.fr)

</div>
