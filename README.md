<div align="center">

![Kali-Lite — une IA locale par Kalicorp](assets/kali-lite-banner.png)

# Kali-Lite

### Une IA locale, gratuite et sous votre contrôle.

**Choisissez votre moteur. Gardez la maîtrise de votre ordinateur, de vos données et de votre contexte.**

[![Local](https://img.shields.io/badge/Inférence-Locale-25bea7?style=flat-square)](https://ollama.com)
[![Licence](https://img.shields.io/badge/Licence-GPL--2.0--only-eaa46b?style=flat-square)](LICENSE)
[![Linux / macOS](https://img.shields.io/badge/Linux%20%7C%20macOS-Parcours%20documentés-425e76?style=flat-square)](#installation)
[![RTX 4090](https://img.shields.io/badge/RTX%204090-18%2F18%20tests%20GPU-377657?style=flat-square)](docs/BENCHMARKS.md)
[![Windows](https://img.shields.io/badge/Windows%20WSL2-Pilote%20à%20valider-746247?style=flat-square)](docs/WINDOWS-WSL2.md)

**[🚀 Installer](#installation)** · **[🧭 Choisir un modèle](#choisir-son-modele)** · **[🖥️ GPU testé](#materiel-teste)** · **[🪟 Windows / WSL2](docs/WINDOWS-WSL2.md)** · **[📚 Documentation](#documentation)**

</div>

> **En bref :** Kali-Lite n'est pas un modèle entraîné de zéro par Kalicorp. C'est une **famille de configurations locales** : modèles de base interchangeables, doctrine Kalicorp, spécialités et outils, sous le contrôle de l'utilisateur. L'inférence locale ne nécessite ni compte Kalicorp ni abonnement d'inférence.

---

<a id="choisir-son-modele"></a>

## 🧭 1. Quel Kali-Lite choisir ?

**Vous débutez ?** Commencez par **Qwen3 8B**, le profil texte de référence. Pour analyser des images, choisissez **Qwen3.5 9B Vision**. Les autres profils sont des variantes expérimentales.

| Votre besoin | Modèle / profil | Statut | Ressources / remarques |
|---|---|---|---|
| 💬 **Discuter, coder, travailler en local** | **Kali-Lite — Qwen3 8B** | 🟢 Référence | ~8 Go de VRAM cible ; 16 Go de RAM conseillés |
| 👁️ **Comprendre aussi des images** | **Kali-Lite v2 — Qwen3.5 9B** | 🟢 Référence Vision | ~10 Go de mémoire GPU indicative ; 32 Go de RAM recommandés |
| 🧪 **Essayer un autre moteur** | Mistral 7B | Laboratoire Q4 / Q8 | [Mesures GPU](docs/BENCHMARKS.md) |
| 🧪 **Essayer un modèle ouvert alternatif** | OLMo 3 7B | Laboratoire Q4 / Q8 | [Mesures GPU](docs/BENCHMARKS.md) |
| 🧪 **Tester une variante légère** | Gemma 4 E2B | Laboratoire Q4 / Q8 | Vision à qualifier séparément |

Les tailles de téléchargement sont indicatives : **Qwen3 8B ~5,2 Go**, **Qwen3.5 9B ~6,8 Go**. La mémoire réellement nécessaire varie avec la quantification, le contexte, le système et les tâches. Un GPU n'est pas obligatoire, mais une inférence CPU peut être lente.

**Systèmes :** Linux et macOS disposent de parcours documentés. Sous **Windows, seul Ubuntu via WSL2 est proposé en phase pilote**, sans validation matérielle réelle revendiquée.

**[🧭 Configurateur moteur × OS × quantification](docs/CONFIGURATEUR.md)** · **[📋 Toutes les commandes par modèle](#recettes-par-modele)**

---

<a id="installation"></a>

## ⚡ 2. Installation rapide — Linux / Qwen3 8B

**Étape 1 — Télécharger, vérifier et prévisualiser.** Copier ces commandes dans un terminal Linux :

```bash
git clone --depth 1 --branch main https://github.com/Kalicorp/kalicorp-kali-lite.git "$HOME/kali-lite"
cd "$HOME/kali-lite"
sha256sum --check SHA256SUMS
less auto-install-kali-lite-v1-novision.sh
bash auto-install-kali-lite-v1-novision.sh --dry-run
```

**Étape 2 — Installer uniquement après avoir vérifié le script et le résultat du dry-run :**

```bash
sudo bash auto-install-kali-lite-v1-novision.sh
ollama run kali-lite
```

> Les installateurs peuvent télécharger Ollama et plusieurs Go de modèles, et modifier le système. **Aucun `curl | bash` direct n'est recommandé.** Les empreintes `SHA256SUMS` vérifient la cohérence des fichiers téléchargés, **pas** l'authenticité d'un dépôt compromis.

**Vous utilisez macOS, Qwen Vision, Mistral, OLMo ou Gemma ?** Ouvrez uniquement le menu correspondant dans les [recettes ci-dessous](#recettes-par-modele), ou consultez le [guide complet](INSTALLATION.md). Sur macOS, les installateurs stables ne doivent pas être lancés avec `sudo`.

**Vous utilisez Windows ?** [Parcours Ubuntu / WSL2 (pilote)](docs/WINDOWS-WSL2.md) · [Formulaire de retour d'essai](.github/ISSUE_TEMPLATE/wsl2_test_report.md).

---

## ✅ 3. GPU validé en laboratoire : NVIDIA RTX 4090 (24 Go)

**Le 14 octobre 2026**, sur une machine Ubuntu avec RTX 4090 et Ollama local, Kalicorp a exécuté les variantes **Mistral 7B, OLMo 3 7B et Gemma 4 E2B**, chacune en **Q4 et Q8**.

| Mesure | Résultat observé |
|---|---|
| GPU | **NVIDIA GeForce RTX 4090 — 24 Go** |
| Profils exécutés | **6** (3 moteurs × 2 quantifications) |
| Tests courts / heuristiques | **18 réussis sur 18** (3 par profil) |
| Ollama serveur | **0.40.4**, instance de laboratoire |
| Système / date | Ubuntu 26 · **14 octobre 2026** |

**✅ Validation :** inférence GPU effectivement exécutée sur la RTX 4090 pour ces six profils. **⚠️ Limites :** ce n'est pas une certification de performances, de production, de Vision ou de compatibilité Windows. Les VRAM et débits détaillés figurent dans la documentation.

**[📊 Voir les mesures RTX 4090 et les limites](docs/BENCHMARKS.md)** · **[🖥️ Voir tout le matériel référencé](#materiel-teste)**

<details>
<summary><strong>Voir les tests Q4 et Q8 et leurs limites</strong></summary>

| Variante | Test RTX 4090 | VRAM de processus observée |
|---|:---:|---:|
| Mistral 7B Q4 | 3/3 | 4 912 MiB |
| Mistral 7B Q8 | 3/3 | 8 282 MiB |
| OLMo 3 7B Q4 | 3/3 | 5 612 MiB |
| OLMo 3 7B Q8 | 3/3 | 9 580 MiB |
| Gemma 4 E2B Q4 | 3/3 | 3 378 MiB |
| Gemma 4 E2B Q8 | 3/3 | 4 122 MiB |

Les premiers Q4 Mistral/OLMo ont été testés avec `num_ctx=2048`, les Q8 avec `4096`. Les tâches étaient courtes. Le premier débit Gemma Q8 (~0,2 tok/s) reste à investiguer.

**[Méthode, métriques et limites de qualification →](docs/BENCHMARKS.md)**

</details>

---

<a id="recettes-par-modele"></a>

## 📋 4. Toutes les commandes — ouvrez seulement votre modèle

Les versions de référence utilisent les installateurs depuis `main`. Les profils **Mistral, OLMo et Gemma** restent en laboratoire, avec recettes sur `projet-x` et téléchargement explicite. Les menus suivants évitent de mélanger Linux, macOS et Windows.

<details>
<summary><strong>🟢 Kali-Lite Qwen3 8B — version stable (Linux / macOS)</strong></summary>

**Linux** — vérification SHA-256, simulation, puis installation volontaire :

```bash
git clone --depth 1 --branch main https://github.com/Kalicorp/kalicorp-kali-lite.git "$HOME/kali-lite-qwen"
cd "$HOME/kali-lite-qwen"
sha256sum --check SHA256SUMS
bash auto-install-kali-lite-v1-novision.sh --dry-run
```

**Si le rapport est conforme et après lecture du script, exécuter séparément :**

```bash
cd "$HOME/kali-lite-qwen"
sudo bash auto-install-kali-lite-v1-novision.sh
ollama run kali-lite
```

**macOS** — Homebrew requis, ne pas utiliser `sudo` :

```bash
git clone --depth 1 --branch main https://github.com/Kalicorp/kalicorp-kali-lite.git "$HOME/kali-lite-qwen"
cd "$HOME/kali-lite-qwen"
shasum -a 256 -c SHA256SUMS
bash auto-install-kali-lite-v1-novision.sh --dry-run
```

**Si le rapport est conforme et après lecture du script, exécuter séparément :**

```bash
cd "$HOME/kali-lite-qwen"
bash auto-install-kali-lite-v1-novision.sh
ollama run kali-lite
```

</details>

<details>
<summary><strong>🟢 Kali-Lite Vision Qwen3.5 9B — version stable (Linux / macOS)</strong></summary>

**Linux** :

```bash
git clone --depth 1 --branch main https://github.com/Kalicorp/kalicorp-kali-lite.git "$HOME/kali-lite-vision"
cd "$HOME/kali-lite-vision"
sha256sum --check SHA256SUMS
bash auto-install-kali-lite-v2-vision.sh --dry-run
```

**Si le rapport est conforme et après lecture du script, exécuter séparément :**

```bash
cd "$HOME/kali-lite-vision"
sudo bash auto-install-kali-lite-v2-vision.sh
ollama run kali-lite-v2
```

**macOS** — Homebrew requis, sans `sudo` :

```bash
git clone --depth 1 --branch main https://github.com/Kalicorp/kalicorp-kali-lite.git "$HOME/kali-lite-vision"
cd "$HOME/kali-lite-vision"
shasum -a 256 -c SHA256SUMS
bash auto-install-kali-lite-v2-vision.sh --dry-run
```

**Si le rapport est conforme et après lecture du script, exécuter séparément :**

```bash
cd "$HOME/kali-lite-vision"
bash auto-install-kali-lite-v2-vision.sh
ollama run kali-lite-v2
```

</details>

<details>
<summary><strong>🧪 Kali-Lite Mistral 7B — expérimental (Q4 / Q8)</strong></summary>

**Linux ou macOS :** Ollama doit être installé et démarré localement. Aucun `sudo` dans les recettes expérimentales.

```bash
git clone --depth 1 --branch projet-x https://github.com/Kalicorp/kalicorp-kali-lite.git "$HOME/kali-lite-mistral"
cd "$HOME/kali-lite-mistral"
```

**Q4_K_M**, plus léger :

```bash
bash scripts/kali-lite-quant.sh --dry-run mistral-7b q4
```

**Après validation de la simulation, télécharger et créer explicitement :**

```bash
ollama pull mistral:7b-instruct-v0.3-q4_K_M
bash scripts/kali-lite-quant.sh --create mistral-7b q4
ollama run kali-lite-mistral-7b-q4
```

**Q8_0**, plus gourmand en RAM et VRAM :

```bash
bash scripts/kali-lite-quant.sh --dry-run mistral-7b q8
```

**Après validation de la simulation, télécharger et créer explicitement :**

```bash
ollama pull mistral:7b-instruct-v0.3-q8_0
bash scripts/kali-lite-quant.sh --create mistral-7b q8
ollama run kali-lite-mistral-7b-q8
```

</details>

<details>
<summary><strong>🧪 Kali-Lite OLMo 3 7B — expérimental (Q4 / Q8)</strong></summary>

**Linux ou macOS :** Ollama doit être installé et démarré localement.

```bash
git clone --depth 1 --branch projet-x https://github.com/Kalicorp/kalicorp-kali-lite.git "$HOME/kali-lite-olmo"
cd "$HOME/kali-lite-olmo"
```

**Q4_K_M** :

```bash
bash scripts/kali-lite-quant.sh --dry-run olmo3-7b q4
```

**Après validation de la simulation, télécharger et créer explicitement :**

```bash
ollama pull olmo-3:7b-instruct-q4_K_M
bash scripts/kali-lite-quant.sh --create olmo3-7b q4
ollama run kali-lite-olmo3-7b-q4
```

**Q8_0** :

```bash
bash scripts/kali-lite-quant.sh --dry-run olmo3-7b q8
```

**Après validation de la simulation, télécharger et créer explicitement :**

```bash
ollama pull olmo-3:7b-instruct-q8_0
bash scripts/kali-lite-quant.sh --create olmo3-7b q8
ollama run kali-lite-olmo3-7b-q8
```

</details>

<details>
<summary><strong>🧪 Kali-Lite Gemma 4 E2B — expérimental, Vision (Q4 / Q8)</strong></summary>

**Linux ou macOS :** Ollama doit être installé et démarré localement. La vision de cette variante reste à qualifier.

```bash
git clone --depth 1 --branch projet-x https://github.com/Kalicorp/kalicorp-kali-lite.git "$HOME/kali-lite-gemma"
cd "$HOME/kali-lite-gemma"
```

**Q4_K_M** :

```bash
bash scripts/kali-lite-quant.sh --dry-run gemma4-e2b q4
```

**Après validation de la simulation, télécharger et créer explicitement :**

```bash
ollama pull gemma4:e2b-it-q4_K_M
bash scripts/kali-lite-quant.sh --create gemma4-e2b q4
ollama run kali-lite-gemma4-e2b-q4
```

**Q8_0** :

```bash
bash scripts/kali-lite-quant.sh --dry-run gemma4-e2b q8
```

**Après validation de la simulation, télécharger et créer explicitement :**

```bash
ollama pull gemma4:e2b-it-q8_0
bash scripts/kali-lite-quant.sh --create gemma4-e2b q8
ollama run kali-lite-gemma4-e2b-q8
```

</details>

<details>
<summary><strong>🔌 Hermes Agent CLI — utiliser Kali-Lite comme moteur Ollama (pilote)</strong></summary>

Hermes Agent CLI accepte l'API OpenAI-compatible d'Ollama. Pour le connecter à un **modèle Kali-Lite effectivement installé** sur l'instance locale choisie :

```bash
curl -fsS http://127.0.0.1:11434/v1/models
hermes model
```

Dans Hermes, sélectionner **Custom endpoint**, renseigner `http://127.0.0.1:11434/v1` (adapter au port réel) puis le nom exact du modèle.

**⚠️ Prérequis bloquant :** Hermes demande **au moins 64 000 tokens de contexte**. Les Modelfiles Kali-Lite actuellement publiés utilisent généralement 8K/32K, et ne sont **pas qualifiés** tels quels. Ne pas modifier la production et ne pas déclarer 64K côté Hermes sans les avoir effectivement configurés et mesurés dans Ollama.

[**Guide complet Kali-Lite × Hermes Agent CLI →**](docs/HERMES-AGENT.md) · [Documentation officielle Hermes](https://hermes-agent.nousresearch.com/docs/integrations/providers/)

</details>

<details>
<summary><strong>🪟 Windows — Ubuntu sous WSL2 (pilote non validé)</strong></summary>

Il n'existe **pas d'installateur Windows natif** dans ce dépôt. Pour tester sur un environnement Windows non critique :

**PowerShell administrateur** :

```powershell
wsl --install -d Ubuntu
wsl --update
wsl --list --verbose
```

Puis, après redémarrage éventuel et vérification de WSL2, ouvrir le terminal **Ubuntu sous WSL2**. Suivre le [guide d'installation WSL2](docs/WINDOWS-WSL2.md) et le [modèle de rapport pour les testeurs Windows](.github/ISSUE_TEMPLATE/wsl2_test_report.md), installer un Ollama Linux dans WSL2 selon les recommandations officielles et utiliser l'un des parcours Linux ci-dessus seulement après `--dry-run`. **Aucune qualification WSL2 CPU/GPU n'est encore revendiquée.**

</details>

> **Avant exécution :** les recettes peuvent télécharger plusieurs Go et modifier la machine. Vérifier la provenance, la RAM/VRAM disponible, la licence amont et chaque commande. `SHA256SUMS` n'est pas une signature d'éditeur.

---

## 🇫🇷 IA frugale & souveraine

**Kali-Lite** est une famille d'**Animas IA locales conçues par Kalicorp** pour fonctionner sur du matériel accessible, sans dépendre d'un service d'inférence cloud Kalicorp.

L'inférence s'effectue localement via **Ollama** une fois le runtime et le modèle installés.  
**Kali-Lite n'ajoute aucune télémétrie ni mécanisme de tracking utilisateur.**

Le projet ne cherche pas à masquer les limites physiques de l'IA locale. Si une machine chauffe, ralentit ou manque de mémoire, cette contrainte fait partie du système réel : CPU, GPU, RAM, VRAM et stockage restent sous le contrôle de l'opérateur.

Kali-Lite privilégie donc une approche simple :

> **Le modèle travaille pour l'utilisateur, sur une infrastructure que l'utilisateur maîtrise.**

La famille repose sur quatre couches séparables :

1. **modèle de base** ;
2. **doctrine Kali-Lite** ;
3. **spécialité optionnelle** ;
4. **harnais d'exécution**.

Cette séparation permet d'adapter une Anima, de remplacer certaines briques ou de faire évoluer le modèle de base sans devoir reconstruire toute l'architecture.

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

<p align="center">
  <img
    src="assets/kali-lite-overview.webp"
    alt="Kali-Lite — IA locale, frugale et visuelle par Kalicorp"
    width="100%"
  >
</p>

<p align="center">
  <em>Visuel de présentation — les spécifications techniques de référence sont celles de ce README et de la Model Card.</em>
</p>

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

<a id="materiel-teste"></a>

## 🖥️ Matériel testé

**RTX 4090 : validation GPU documentée dans le laboratoire Kali-Lite.** Les anciens matériels ci-dessous figuraient déjà dans les retours du projet, mais leur protocole détaillé n'est pas publié à ce stade.

| Configuration | État des informations disponibles |
|---|---|
| **NVIDIA GeForce RTX 4090 — 24 Go** | ✅ **Tests GPU réalisés le 14/10/2026 :** Mistral 7B, OLMo 3 7B et Gemma 4 E2B en Q4/Q8 — **18/18 heuristiques** réussies. [Mesures et limites](docs/BENCHMARKS.md) |
| RTX 3080 8 Go | Signalée comme testée historiquement ; version du modèle et protocole à préciser |
| RTX 4070 | Signalée comme testée historiquement ; détails à compléter |
| Apple Silicon M1 / M2 / M3 | Environnements mentionnés comme testés ; configurations à documenter |
| Kali Linux / Ubuntu | Parcours Linux documenté |
| macOS 11+ | Parcours macOS documenté |

> **Ce qui est validé sur RTX 4090 :** des générations GPU courtes sur les **six variantes expérimentales**. **Non validé par ces mesures :** le fonctionnement WSL2, l'ensemble des configurations Qwen, la Vision sur images, la génération longue et la comparaison de performances à paramètres identiques.

### Ressources indicatives

**Kali-Lite**

- GPU NVIDIA : environ **8 Go de VRAM** ;
- RAM système : **16 Go minimum conseillé**.

**Kali-Lite v2**

- GPU : environ **10 Go de mémoire disponible** ;
- RAM système : **32 Go recommandé**.

Sur Apple Silicon, la mémoire est unifiée : la notion de VRAM dédiée ne s'applique donc pas exactement comme sur un GPU NVIDIA.

Une exécution CPU reste possible selon le modèle et la mémoire disponible, mais sera généralement plus lente.

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

Kali-Lite utilise notamment des composants et modèles tiers tels qu'**Ollama** et **Qwen**.

Le projet cherche à les assembler de façon **locale, inspectable et remplaçable**, plutôt qu'à prétendre qu'aucune dépendance n'existe.

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

### Raisonnement et capacité d'action

La capacité d'un modèle à comprendre une tâche et sa capacité à réellement agir sont deux choses différentes :

```text
Comprendre une action
        ≠
Avoir l'outil
        ≠
Avoir la permission
        ≠
Avoir exécuté l'action
```

Kali-Lite est conçue pour distinguer ces états et ne pas présenter une action comme exécutée lorsqu'aucune preuve d'exécution n'est disponible.

---

## 🔐 Sécurité

Les installateurs publics peuvent être contrôlés avant exécution.

Les empreintes SHA-256 actuellement publiées sont disponibles dans :

[`SHA256SUMS`](SHA256SUMS)

Pour signaler une vulnérabilité ou consulter la politique de divulgation responsable :

[`SECURITY.md`](SECURITY.md)

Quelques principes :

- télécharger avant d'exécuter ;
- vérifier l'empreinte SHA-256 ;
- lire le script ;
- utiliser `--dry-run` lorsque disponible ;
- appliquer le principe du moindre privilège ;
- ne jamais placer de secret ou de clé API directement dans un prompt ou un fichier versionné.

---

<a id="documentation"></a>

## 📚 Documentation

| Fichier | Description |
|---|---|
| [INSTALLATION.md](INSTALLATION.md) | Guide d'installation détaillé |
| [REFACTOR_BRIEF.md](REFACTOR_BRIEF.md) | Architecture des scripts d'installation |
| [MODEL-CARD.md](MODEL-CARD.md) | Modèles de base, usages prévus et limites |
| [docs/WHY-KALI-LITE.md](docs/WHY-KALI-LITE.md) | Intention et principes de conception |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Architecture en quatre couches |
| [templates/anima.template.md](templates/anima.template.md) | Gabarit de personnalisation d'une Anima |
| [docs/ANIMA-ADVANCED.md](docs/ANIMA-ADVANCED.md) | Identité, spécialités, mémoire et contrats d'outils |
| [docs/VARIANTS-LAB.md](docs/VARIANTS-LAB.md) | Profils Mistral / OLMo / Gemma (expérimental) |
| [docs/QUANTIZATIONS.md](docs/QUANTIZATIONS.md) | Presets Q4/Q8, tests et limites |
| [docs/WINDOWS-WSL2.md](docs/WINDOWS-WSL2.md) | Parcours Windows/WSL2 (pilote non validé sur matériel) |
| [docs/CONFIGURATEUR.md](docs/CONFIGURATEUR.md) | Page d'installation interactive locale et publication statique |
| [docs/HERMES-AGENT.md](docs/HERMES-AGENT.md) | Connexion Ollama vers Hermes Agent CLI, exigences de contexte 64K et tests d'outils |
| [docs/BENCHMARKS.md](docs/BENCHMARKS.md) | Tests multi-OS, inférence CPU GitHub et mesures GPU RTX 4090 |
| [SECURITY.md](SECURITY.md) | Sécurité et divulgation responsable |
| [SHA256SUMS](SHA256SUMS) | Empreintes SHA-256 des installateurs |
| [LICENSE](LICENSE) | GNU GPL v2 — GPL-2.0-only |

---

<a id="roadmap"></a>

## 🗺️ Roadmap 2026

- [x] Kali-Lite — Qwen3 8B
- [x] Kali-Lite v2 — modèle Vision
- [x] GitHub Actions — tests automatisés des installateurs
- [x] Organisation GitHub Kalicorp
- [x] Documentation de sécurité et Model Card
- [x] Installation Linux / macOS avec vérification SHA-256
- [ ] Support Windows / WSL2 — guide et diagnostic disponibles ; **validation réelle Windows/WSL2 CPU/GPU en attente**
- [x] Quantifications supplémentaires — recettes **Q4_K_M / Q8_0** des trois profils ; **six smoke tests réels RTX 4090, 3/3 chacun (18/18 heuristiques)**. Performances longues et comparaison contrôlée à faire.
- [x] Élargissement des modèles de base interchangeables — Mistral 7B, OLMo 3 7B, Gemma 4 E2B en **laboratoire**
- [x] Documentation de personnalisation avancée des Animas — guide, contrat d'outils et cas de validation

### Dernière étape avant clôture complète

- [ ] Tester Windows 10/11 + Ubuntu WSL2 sur machine réelle (CPU, puis GPU si disponible), installation, redémarrage et désinstallation.
- [x] Compléter le smoke test corrigé de **Gemma 4 Q4** : 3/3 heuristiques, `think=false`, 4 096 tokens de contexte, fichier JSON obtenu.
- [x] Exécuter les **trois profils Q8_0** sur RTX 4090 : Mistral, OLMo 3 et Gemma 4, 3/3 heuristiques chacun, déchargement après chaque test.
- [ ] Comparer équitablement **Q4 / Q8** sur la RTX 4090 avec les mêmes paramètres de contexte et les mêmes prompts longs, répétitions, latence, VRAM, tokens/s et fidélité à la doctrine (les six smoke tests GPU sont acquis).
- [ ] Investiguer l'anomalie de débit du **premier appel Gemma Q8** : 0,2 tok/s avec 13,184 s de temps mural.
- [ ] Promouvoir les variantes en production **uniquement après** revue humaine des résultats, licences et sécurité.

> Les cases cochées attestent de livrables **logiciels ou documentaires** ; elles ne constituent pas une homologation matérielle ou réglementaire.

---

## ⚖️ Licence

Kali-Lite est distribué sous **GNU General Public License v2.0 only (`GPL-2.0-only`)**.

Voir [`LICENSE`](LICENSE).

Les modèles de base et dépendances tierces restent soumis à leurs propres licences.

Copyright © 2026 Kalicorp.

---

<div align="center">

### Kalicorp

**Le Sanctuaire numérique européen**

IA locale • souveraineté • frugalité • maîtrise de l'infrastructure

[site.kalicorp.fr](https://site.kalicorp.fr) · Contact : [kalicorp@proton.me](mailto:kalicorp@proton.me)

</div>
