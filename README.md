<div align="center">

# Kali-Lite

![Kali-Lite Banner](assets/kali-lite-banner.png)

**IA locale, frugale et maîtrisable — Ollama • Linux • macOS**

[![Ollama](https://img.shields.io/badge/Ollama-Local-%2312B7F5?style=for-the-badge&logo=ollama)](https://ollama.com)
[![VRAM](https://img.shields.io/badge/VRAM-8--10%20Go-%2322c55e?style=for-the-badge)](#)
[![License: GPL-2.0-only](https://img.shields.io/badge/License-GPL--2.0--only-%23f37726?style=for-the-badge)](LICENSE)
[![Platforms](https://img.shields.io/badge/Platforms-Linux%20%7C%20macOS-%236366f1?style=for-the-badge)](#)
[![Sovereign](https://img.shields.io/badge/Souverainet%C3%A9-Ma%C3%AEtrisable-%23EA580C?style=for-the-badge)](https://site.kalicorp.fr)

</div>

---

## 🇫🇷 IA frugale & souveraine

**Kali-Lite** est une famille d'**Animas IA locales conçues par Kalicorp** pour fonctionner sur du matériel accessible, sans dépendre d'un service d'inférence cloud Kalicorp.

L'inférence s'effectue localement via **Ollama** une fois le runtime et le modèle installés.  
**Kali-Lite n'ajoute aucune télémétrie ni mécanisme de tracking.**

Le projet ne cherche pas à masquer les limites physiques de l'IA locale. Si une machine chauffe, ralentit ou manque de mémoire, cette contrainte fait partie du système réel : CPU, GPU, RAM, VRAM et stockage restent sous le contrôle de l'opérateur.

Kali-Lite privilégie donc une approche simple :

> **le modèle travaille pour l'utilisateur, sur une infrastructure que l'utilisateur maîtrise.**

La famille repose sur quatre couches séparables :

1. **modèle de base** ;
2. **doctrine Kali-Lite** ;
3. **spécialité éventuelle** ;
4. **harnais d'exécution**.

Cette séparation permet d'adapter une Anima, de remplacer certaines briques ou de faire évoluer le modèle de base sans devoir reconstruire toute l'architecture.

### Versions disponibles

| Version | Modèle de base | VRAM indicative | Vision | Cas d'usage | Taille indicative |
|---|---|---:|:---:|---|---:|
| **Kali-Lite** | Qwen3 8B | ~8 Go | ❌ | Chat, code, assistance système | ~5,2 Go |
| **Kali-Lite v2** | Qwen3.5 9B Vision | ~10 Go | ✅ | Images, chat, code | ~6,8 Go |

> Les besoins réels dépendent notamment de la quantification, du contexte utilisé, du runtime et de la mémoire disponible.

---

## ⚡ Installation

### Principe recommandé

Ne lance pas directement un script récupéré sur Internet.

Télécharge-le, vérifie son empreinte SHA-256, lis-le, puis exécute-le.

### Kali-Lite — sans vision

#### Linux

```bash
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/auto-install-kali-lite-v1-novision.sh
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/SHA256SUMS

sha256sum --check SHA256SUMS --ignore-missing

less auto-install-kali-lite-v1-novision.sh

bash auto-install-kali-lite-v1-novision.sh --dry-run
sudo bash auto-install-kali-lite-v1-novision.sh
```

#### macOS

```bash
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/auto-install-kali-lite-v1-novision.sh
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/SHA256SUMS

grep 'auto-install-kali-lite-v1-novision.sh' SHA256SUMS
shasum -a 256 auto-install-kali-lite-v1-novision.sh

less auto-install-kali-lite-v1-novision.sh

bash auto-install-kali-lite-v1-novision.sh --dry-run
bash auto-install-kali-lite-v1-novision.sh
```

Compare l'empreinte affichée par `shasum -a 256` avec celle publiée dans `SHA256SUMS`.

### Kali-Lite v2 — avec vision

#### Linux

```bash
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/auto-install-kali-lite-v2-vision.sh
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/SHA256SUMS

sha256sum --check SHA256SUMS --ignore-missing

less auto-install-kali-lite-v2-vision.sh

bash auto-install-kali-lite-v2-vision.sh --dry-run
sudo bash auto-install-kali-lite-v2-vision.sh
```

#### macOS

```bash
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/auto-install-kali-lite-v2-vision.sh
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/SHA256SUMS

grep 'auto-install-kali-lite-v2-vision.sh' SHA256SUMS
shasum -a 256 auto-install-kali-lite-v2-vision.sh

less auto-install-kali-lite-v2-vision.sh

bash auto-install-kali-lite-v2-vision.sh --dry-run
bash auto-install-kali-lite-v2-vision.sh
```

> **Temps d'installation indicatif :** 15 à 20 minutes, principalement selon la connexion utilisée pour télécharger le modèle.

Après installation :

```bash
kali-lite
```

ou, selon la variante :

```bash
ollama run kali-lite-v2
```

---

## 🛡️ Pourquoi Kali-Lite ?

- **Inférence locale** — les échanges avec le modèle sont traités localement lorsque Kali-Lite est utilisé avec Ollama local.
- **Pas de compte Kalicorp obligatoire** — aucune API Kalicorp n'est nécessaire pour faire fonctionner l'inférence locale.
- **Pas de quota commercial d'inférence** — les limites sont celles de ta machine, de ton runtime et du modèle utilisé.
- **Pas de télémétrie ajoutée par Kali-Lite** — le projet n'intègre pas de mécanisme de tracking utilisateur.
- **Architecture remplaçable** — modèle de base, doctrine et harnais sont distingués pour limiter l'enfermement technique.
- **Code et scripts inspectables** — les installateurs sont publics et leurs empreintes sont publiées.
- **Linux et macOS** — prise en charge des principaux environnements locaux ciblés par le projet.
- **Frugalité** — Kali-Lite vise des machines très éloignées des infrastructures IA de datacenter.
- **Maîtrise des données** — l'approche locale peut faciliter certaines stratégies de gouvernance, de confidentialité et de souveraineté.

### RGPD et AI Act

Un déploiement local peut réduire certains transferts de données et faciliter la maîtrise de l'infrastructure.

Il ne rend cependant **pas automatiquement une organisation conforme** au RGPD, à l'AI Act ou à toute autre réglementation.

La conformité dépend notamment :

- des usages ;
- des données traitées ;
- des responsabilités de l'opérateur ;
- des mesures techniques et organisationnelles ;
- de la gouvernance mise en place.

---

## 🖥️ Matériel testé

| Configuration | Statut |
|---|:---:|
| RTX 3080 8 Go | ✅ |
| RTX 4070 | ✅ |
| Apple Silicon M1 / M2 / M3 | ✅ |
| Kali Linux / Ubuntu | ✅ |
| macOS 11+ | ✅ |

### Ressources indicatives

**Kali-Lite**

- GPU NVIDIA : environ **8 Go de VRAM**
- RAM système : **16 Go minimum conseillé**

**Kali-Lite v2**

- GPU : environ **10 Go de mémoire disponible**
- RAM système : **32 Go recommandé**

Sur Apple Silicon, la mémoire est unifiée : la notion de VRAM dédiée ne s'applique donc pas exactement comme sur un GPU NVIDIA.

---

## 📦 Cas d'usage

- assistance système Linux ;
- développement et analyse de code ;
- documentation technique ;
- audit et durcissement défensif ;
- analyse d'images avec Kali-Lite v2 ;
- formation à l'IA locale ;
- démonstration d'architectures souveraines ;
- expérimentation par des particuliers, associations, TPE, PME et collectivités.

---

## 🚫 Ce que Kali-Lite n'est pas

- ❌ un service d'inférence cloud Kalicorp ;
- ❌ une promesse d'IA sans limite physique ;
- ❌ un système automatiquement conforme au RGPD ou à l'AI Act ;
- ❌ un modèle entièrement entraîné par Kalicorp ;
- ❌ un outil conçu spécifiquement pour l'attaque offensive ;
- ❌ une garantie d'absence de réseau de toutes les dépendances tierces.

Kali-Lite utilise notamment des composants et modèles tiers tels qu'Ollama et Qwen.  
Le projet cherche à les assembler de façon **locale, inspectable et remplaçable**, plutôt qu'à prétendre qu'ils n'existent pas.

---

## 🧩 Architecture

Kali-Lite distingue volontairement quatre couches :

```text
┌──────────────────────────┐
│      Modèle de base      │
│        Qwen / autre      │
├──────────────────────────┤
│    Doctrine Kali-Lite    │
├──────────────────────────┤
│       Spécialité         │
│       optionnelle        │
├──────────────────────────┤
│  Harnais d'exécution     │
│ Ollama / outils / système│
└──────────────────────────┘
```

Cette architecture permet de faire évoluer une couche sans rendre tout le système dépendant d'un fournisseur unique.

**Kali-Lite n'est donc pas seulement un poids de modèle : c'est une composition documentée et reproductible.**

---

## 🔐 Sécurité

Les installateurs publics peuvent être contrôlés avant exécution.

Les empreintes SHA-256 actuellement publiées sont disponibles dans :

[`SHA256SUMS`](SHA256SUMS)

Pour signaler une vulnérabilité ou consulter la politique de divulgation responsable :

[`SECURITY.md`](SECURITY.md)

---

## 📚 Documentation

| Fichier | Description |
|---|---|
| [INSTALLATION.md](INSTALLATION.md) | Guide d'installation détaillé |
| [REFACTOR_BRIEF.md](REFACTOR_BRIEF.md) | Architecture des scripts d'installation |
| [MODEL-CARD.md](MODEL-CARD.md) | Modèles de base, usages prévus et limites |
| [docs/WHY-KALI-LITE.md](docs/WHY-KALI-LITE.md) | Intention et principes de conception |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Architecture en quatre couches |
| [templates/anima.template.md](templates/anima.template.md) | Gabarit de personnalisation d'une Anima |
| [SECURITY.md](SECURITY.md) | Sécurité et divulgation responsable |
| [SHA256SUMS](SHA256SUMS) | Empreintes SHA-256 des installateurs |
| [LICENSE](LICENSE) | GNU GPL v2 — GPL-2.0-only |

---

## 🗺️ Roadmap 2026

- [x] Kali-Lite — Qwen3 8B
- [x] Kali-Lite v2 — modèle Vision
- [x] GitHub Actions — tests automatisés des installateurs
- [x] Organisation GitHub Kalicorp
- [ ] Support Windows / WSL2
- [ ] Quantifications supplémentaires
- [ ] Élargissement des modèles de base interchangeables
- [ ] Documentation de personnalisation avancée des Animas

---

## ⚖️ Licence

Kali-Lite est distribué sous **GNU General Public License v2.0 only (`GPL-2.0-only`)**.

Voir [`LICENSE`](LICENSE).

Copyright © 2026 Kalicorp.

---

<div align="center">

### Kalicorp

**Le Sanctuaire numérique européen**

IA locale • souveraineté • frugalité • maîtrise de l'infrastructure

[site.kalicorp.fr](https://site.kalicorp.fr)

</div>
