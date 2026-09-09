# Kali-Lite — Guide d'installation

**Kali-Lite** est une famille d'Animas IA locales conçues par Kalicorp pour fonctionner via **Ollama** sur Linux et macOS.

Deux variantes sont actuellement proposées :

| Variante | Modèle de base | Vision | Usage principal |
|---|---|:---:|---|
| **Kali-Lite** | Qwen3 8B | ❌ | chat, code, assistance système |
| **Kali-Lite v2** | Qwen3.5 9B | ✅ | vision, chat, code |

L'inférence est locale une fois le runtime, le modèle et les composants nécessaires installés.

Kali-Lite n'ajoute aucune télémétrie ni mécanisme de tracking utilisateur.

> Les modèles, Ollama, Homebrew et les autres composants tiers restent soumis à leurs propres licences, politiques et comportements techniques.

---

## Principe d'installation

La méthode recommandée est volontairement simple :

```text
Télécharger
    ↓
Vérifier SHA-256
    ↓
Lire le script
    ↓
Tester avec --dry-run
    ↓
Exécuter
```

Évite d'exécuter directement un script distant avec une commande du type :

```bash
curl ... | bash
```

Télécharger le fichier avant son exécution permet de l'inspecter et de vérifier son empreinte.

---

# Installation rapide

## Kali-Lite — sans vision

### Linux

```bash
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/auto-install-kali-lite-v1-novision.sh
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/SHA256SUMS

sha256sum --check SHA256SUMS --ignore-missing

less auto-install-kali-lite-v1-novision.sh

bash auto-install-kali-lite-v1-novision.sh --dry-run
sudo bash auto-install-kali-lite-v1-novision.sh
```

### macOS

```bash
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/auto-install-kali-lite-v1-novision.sh
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/SHA256SUMS

grep ' auto-install-kali-lite-v1-novision.sh$' SHA256SUMS | shasum -a 256 -c -

less auto-install-kali-lite-v1-novision.sh

bash auto-install-kali-lite-v1-novision.sh --dry-run
bash auto-install-kali-lite-v1-novision.sh
```

---

## Kali-Lite v2 — avec vision

### Linux

```bash
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/auto-install-kali-lite-v2-vision.sh
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/SHA256SUMS

sha256sum --check SHA256SUMS --ignore-missing

less auto-install-kali-lite-v2-vision.sh

bash auto-install-kali-lite-v2-vision.sh --dry-run
sudo bash auto-install-kali-lite-v2-vision.sh
```

### macOS

```bash
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/auto-install-kali-lite-v2-vision.sh
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/SHA256SUMS

grep ' auto-install-kali-lite-v2-vision.sh$' SHA256SUMS | shasum -a 256 -c -

less auto-install-kali-lite-v2-vision.sh

bash auto-install-kali-lite-v2-vision.sh --dry-run
bash auto-install-kali-lite-v2-vision.sh
```

---

## `install.sh`

Le dépôt fournit également :

```text
install.sh
```

Il s'agit d'un installateur de commodité pour **Kali-Lite V1 / Qwen3 8B sans vision**.

### Linux

```bash
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/install.sh
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/SHA256SUMS

sha256sum --check SHA256SUMS --ignore-missing

less install.sh

bash install.sh --dry-run
sudo bash install.sh
```

### macOS

```bash
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/install.sh
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/SHA256SUMS

grep ' install.sh$' SHA256SUMS | shasum -a 256 -c -

less install.sh

bash install.sh --dry-run
bash install.sh
```

---

# Prérequis

## Linux

Environnement ciblé :

- Kali Linux ;
- Debian ;
- Ubuntu ;
- Arch Linux.

Prérequis principaux :

- Bash ;
- `curl` ;
- `awk` ;
- accès root pour l'installation système ;
- espace disque suffisant pour Ollama et les modèles.

### GPU

Un GPU NVIDIA compatible peut accélérer fortement l'inférence.

Vérification :

```bash
nvidia-smi
```

L'absence de `nvidia-smi` ne provoque pas automatiquement l'arrêt de Kali-Lite.

Selon l'environnement et les capacités supportées par Ollama, une exécution CPU ou via un autre accélérateur peut rester possible.

### Mémoire indicative

Pour Kali-Lite V1 :

- environ **8 Go de VRAM** pour la cible GPU ;
- **16 Go de RAM système** conseillés.

Pour Kali-Lite v2 :

- environ **10 Go de mémoire GPU disponible** ;
- **32 Go de RAM système** recommandés.

Ces valeurs sont indicatives.

La consommation réelle dépend notamment :

- du runtime ;
- de la quantification ;
- de la taille du contexte ;
- du système ;
- des autres applications actives.

---

## macOS

Environnement ciblé :

- macOS 11 ou plus récent ;
- Intel ou Apple Silicon ;
- Homebrew déjà installé.

L'installation ne doit **pas être lancée avec `sudo`**.

Homebrew refuse normalement une exécution en root.

Si Homebrew n'est pas encore installé, consulter :

[https://brew.sh](https://brew.sh)

Selon l'environnement, les outils de développement Apple peuvent également être nécessaires :

```bash
xcode-select --install
```

### Apple Silicon

Les Mac Apple Silicon utilisent une mémoire unifiée.

La notion de VRAM dédiée ne correspond donc pas exactement au fonctionnement d'un GPU NVIDIA classique.

---

# Que fait l'installateur ?

Les installateurs effectuent essentiellement six opérations.

## 1. Vérification de l'environnement

Le script détecte :

- Linux ou macOS ;
- l'utilisateur réel ;
- son répertoire personnel ;
- son shell ;
- la présence éventuelle d'un GPU ou accélérateur détectable.

---

## 2. Installation ou détection d'Ollama

Si Ollama est déjà disponible, il est conservé.

Sinon :

### Linux

L'installateur officiel Ollama est téléchargé depuis :

```text
https://ollama.com/install.sh
```

Il est d'abord enregistré dans un fichier temporaire avant d'être exécuté.

L'installateur tiers n'est pas actuellement figé par une empreinte SHA-256 publiée par Kali-Lite.

Le script le signale explicitement.

### macOS

Ollama est installé via Homebrew :

```bash
brew install ollama
```

---

## 3. Démarrage d'Ollama

### Linux

Le script privilégie le service `systemd` lorsqu'il existe.

Sinon, il peut démarrer :

```bash
ollama serve
```

en arrière-plan.

Lors d'un démarrage manuel, le PID est capturé et vérifié avant que le démarrage soit considéré comme réussi.

### macOS

Le script tente en priorité :

```bash
brew services start ollama
```

et peut utiliser un démarrage manuel si nécessaire.

L'API locale est ensuite vérifiée sur :

```text
http://127.0.0.1:11434
```

Le script attend jusqu'à environ 30 secondes avant de considérer le démarrage comme échoué. 

---

## 4. Téléchargement du modèle de base

### Kali-Lite

```bash
ollama pull qwen3:8b
```

### Kali-Lite v2

```bash
ollama pull qwen3.5:9b
```

Le téléchargement nécessite évidemment un accès réseau.

Une fois le modèle présent localement, l'inférence standard ne nécessite pas de service d'inférence Kalicorp.

---

## 5. Création de l'Anima Kali-Lite

L'installateur crée ensuite un Modelfile local puis construit un modèle Ollama personnalisé.

### Kali-Lite

```text
qwen3:8b
   +
doctrine Kali-Lite
   +
configuration
   ↓
kali-lite:latest
```

### Kali-Lite v2

```text
qwen3.5:9b
   +
doctrine Kali-Lite
   +
configuration Vision
   ↓
kali-lite-v2:latest
```

Kali-Lite n'est donc pas présentée comme un modèle entièrement entraîné par Kalicorp.

Elle est une **composition documentée autour d'un modèle de base tiers**.

---

## 6. Installation d'un alias shell

### Kali-Lite

```bash
alias kali-lite='ollama run --think=false kali-lite'
```

### Kali-Lite v2

```bash
alias kali-lite-v2='ollama run --think=false kali-lite-v2'
```

L'alias est ajouté dans le fichier de configuration du shell de l'utilisateur.

Selon l'environnement :

```text
~/.bashrc
```

ou :

```text
~/.zshrc
```

Les installateurs sauvegardent et nettoient les anciens blocs Kali-Lite avant d'injecter la configuration actuelle.  

---

# Fichiers créés

## Kali-Lite V1

| Élément | Linux | macOS |
|---|---|---|
| Modelfile | `/etc/kalicorp/Modelfile.kali-lite` | `~/.kalicorp/Modelfile.kali-lite` |
| Modèle Ollama | `kali-lite:latest` | `kali-lite:latest` |
| Alias | `kali-lite` | `kali-lite` |
| Log fallback Ollama | `/var/log/kalicorp/ollama.log` | `~/Library/Logs/kalicorp/ollama.log` |
| PID fallback Ollama | `/var/run/kalicorp-ollama.pid` | `~/Library/kalicorp/ollama.pid` |

## Kali-Lite v2

| Élément | Linux | macOS |
|---|---|---|
| Modelfile | `/etc/kalicorp/Modelfile.kali-lite-v2` | `~/.kalicorp/Modelfile.kali-lite-v2` |
| Modèle Ollama | `kali-lite-v2:latest` | `kali-lite-v2:latest` |
| Alias | `kali-lite-v2` | `kali-lite-v2` |
| Log fallback Ollama | `/var/log/kalicorp/ollama.log` | `~/Library/Logs/kalicorp/ollama.log` |
| PID fallback Ollama | `/var/run/kalicorp-ollama.pid` | `~/Library/kalicorp/ollama.pid` |

Les logs et le daemon Ollama peuvent être partagés entre plusieurs modèles.

---

# `--dry-run`

Avant une installation réelle, il est recommandé de lancer :

```bash
bash <script> --dry-run
```

Exemple :

```bash
bash auto-install-kali-lite-v1-novision.sh --dry-run
```

Le `--dry-run` affiche :

- le système détecté ;
- l'utilisateur ciblé ;
- le modèle qui serait téléchargé ;
- les chemins qui seraient utilisés ;
- l'alias qui serait ajouté ;
- la stratégie prévue pour Ollama.

Le mode `--dry-run` est conçu pour ne modifier ni le HOME utilisateur ni le répertoire temporaire.

---

# Utilisation

Après installation, recharge le shell :

```bash
source ~/.bashrc
```

ou :

```bash
source ~/.zshrc
```

## Kali-Lite

```bash
kali-lite
```

ou directement :

```bash
ollama run kali-lite
```

## Kali-Lite v2

```bash
kali-lite-v2
```

ou directement :

```bash
ollama run kali-lite-v2
```

---

# Vérifier l'installation

## Modèles Ollama

```bash
ollama list
```

Tu dois retrouver selon la variante :

```text
kali-lite:latest
```

ou :

```text
kali-lite-v2:latest
```

ainsi que le modèle de base correspondant.

---

## API locale Ollama

```bash
curl http://127.0.0.1:11434/api/tags
```

---

## Version d'Ollama

```bash
ollama --version
```

---

# Personnalisation du Modelfile

Le comportement de Kali-Lite est principalement défini par son Modelfile et son harnais d'exécution.

## Kali-Lite V1

### Linux

```bash
sudo nano /etc/kalicorp/Modelfile.kali-lite
```

### macOS

```bash
nano ~/.kalicorp/Modelfile.kali-lite
```

Après modification :

### Linux

```bash
ollama create kali-lite -f /etc/kalicorp/Modelfile.kali-lite
```

### macOS

```bash
ollama create kali-lite -f ~/.kalicorp/Modelfile.kali-lite
```

---

## Kali-Lite v2

### Linux

```bash
sudo nano /etc/kalicorp/Modelfile.kali-lite-v2
```

### macOS

```bash
nano ~/.kalicorp/Modelfile.kali-lite-v2
```

Après modification :

### Linux

```bash
ollama create kali-lite-v2 -f /etc/kalicorp/Modelfile.kali-lite-v2
```

### macOS

```bash
ollama create kali-lite-v2 -f ~/.kalicorp/Modelfile.kali-lite-v2
```

---

# Outils et permissions

Kali-Lite distingue quatre états différents :

```text
Comprendre une action
        ≠
Avoir l'outil
        ≠
Avoir la permission
        ≠
Avoir exécuté l'action
```

L'installation d'Ollama seule ne donne pas automatiquement à Kali-Lite :

- un terminal ;
- un accès Internet ;
- des permissions root ;
- une API ;
- un accès aux fichiers ;
- un accès à d'autres machines.

Ces capacités dépendent du **harnais d'exécution** choisi par l'opérateur.

Une action ne doit être présentée comme exécutée que lorsqu'une preuve d'exécution réelle est disponible.

---

# Dépannage

## Ollama ne démarre pas

### Linux avec systemd

```bash
sudo systemctl status ollama
```

Logs systemd :

```bash
sudo journalctl -u ollama -n 50
```

Redémarrage :

```bash
sudo systemctl restart ollama
```

### macOS

Vérifier les services :

```bash
brew services list | grep ollama
```

Redémarrer :

```bash
brew services restart ollama
```

---

## Vérifier manuellement l'API

```bash
curl http://127.0.0.1:11434/api/tags
```

---

## Manque d'espace disque

```bash
df -h
```

Les modèles nécessitent plusieurs gigaoctets de stockage libre.

---

## GPU NVIDIA non détecté

```bash
nvidia-smi
```

Si cette commande n'existe pas ou échoue, vérifier :

- le pilote NVIDIA ;
- l'accès au périphérique ;
- la configuration système.

L'absence de GPU NVIDIA ne signifie pas automatiquement que Kali-Lite est inutilisable : Ollama peut fonctionner dans d'autres modes selon la plateforme.

---

## Permission denied sous Linux

L'installation normale écrit notamment dans :

```text
/etc/kalicorp
```

et peut utiliser :

```text
/var/log/kalicorp
```

Elle doit donc être lancée en root :

```bash
sudo bash auto-install-kali-lite-v1-novision.sh
```

ou :

```bash
sudo bash auto-install-kali-lite-v2-vision.sh
```

Ne remplace pas cette procédure par un `curl | bash`.

---

## Homebrew absent sur macOS

L'installateur Kali-Lite **n'installe pas automatiquement Homebrew**.

Installe et vérifie Homebrew séparément depuis son projet officiel :

[https://brew.sh](https://brew.sh)

Puis :

```bash
brew --version
```

et relance Kali-Lite.

---

# Désinstallation

Les installateurs possèdent désormais leur propre mode `--uninstall`.

## Kali-Lite V1 — Linux

```bash
sudo bash auto-install-kali-lite-v1-novision.sh --uninstall
```

ou avec l'installateur de commodité :

```bash
sudo bash install.sh --uninstall
```

## Kali-Lite V1 — macOS

```bash
bash auto-install-kali-lite-v1-novision.sh --uninstall
```

ou :

```bash
bash install.sh --uninstall
```

## Kali-Lite v2 — Linux

```bash
sudo bash auto-install-kali-lite-v2-vision.sh --uninstall
```

## Kali-Lite v2 — macOS

```bash
bash auto-install-kali-lite-v2-vision.sh --uninstall
```

Une confirmation interactive est demandée avant suppression.

La désinstallation supprime les éléments propres à la variante concernée :

- alias Kali-Lite ;
- tag du modèle Kali-Lite ;
- Modelfile correspondant.

**Ollama est volontairement conservé**, ainsi que les autres modèles éventuellement installés sur la machine. 

Pour V2, le daemon, les logs Ollama et les autres modèles sont également explicitement conservés. 

---

# Architecture

## Kali-Lite V1

```text
┌──────────────────────────────┐
│ Utilisateur                  │
│ $ kali-lite                  │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Ollama local                 │
│ 127.0.0.1:11434              │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ kali-lite:latest             │
│ doctrine + configuration     │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ qwen3:8b                     │
│ modèle de base               │
└──────────────────────────────┘
```

## Kali-Lite v2

```text
┌──────────────────────────────┐
│ Utilisateur                  │
│ $ kali-lite-v2               │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Ollama local                 │
│ 127.0.0.1:11434              │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ kali-lite-v2:latest          │
│ doctrine + Vision            │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ qwen3.5:9b                   │
│ modèle de base multimodal    │
└──────────────────────────────┘
```

Il n'y a **aucune dépendance à Claude Code dans l'installation standard actuelle**.

Il n'y a pas non plus de variable :

```text
ANTHROPIC_API_KEY
```

ou :

```text
ANTHROPIC_BASE_URL
```

nécessaire au fonctionnement standard de Kali-Lite.

---

# Réseau et confidentialité

L'installation nécessite un accès réseau pour récupérer selon le cas :

- les scripts du dépôt ;
- Ollama ;
- le modèle Qwen ;
- les composants fournis par Homebrew ;
- les mises à jour volontairement demandées.

Une fois le modèle disponible localement, l'inférence standard via Ollama s'effectue sur la machine.

Kali-Lite n'ajoute pas de mécanisme de télémétrie ou de tracking vers Kalicorp.

Cela ne constitue pas une garantie que toutes les dépendances tierces sont exemptes de toute communication réseau.

Pour un environnement sensible, l'opérateur peut notamment :

- inspecter les scripts ;
- figer les versions ;
- conserver localement les artefacts ;
- contrôler les flux réseau ;
- auditer les dépendances.

Voir également [`SECURITY.md`](SECURITY.md).

---

# Sécurité

Avant toute installation :

```text
1. Télécharger
2. Vérifier SHA-256
3. Lire
4. Dry-run
5. Exécuter
```

Les empreintes officielles des installateurs sont publiées dans :

[`SHA256SUMS`](SHA256SUMS)

Ne copie pas de :

- clé API ;
- mot de passe ;
- token ;
- secret ;

dans un prompt, un Modelfile ou un fichier versionné.

Pour signaler une vulnérabilité :

**security@kalicorp.fr**

Voir [`SECURITY.md`](SECURITY.md).

---

# Mise à jour

Pour mettre à jour Kali-Lite, récupère à nouveau :

1. le script ;
2. `SHA256SUMS`.

Puis recommence la procédure de vérification.

Ne réutilise pas une ancienne empreinte SHA-256 avec un script plus récent.

Toute modification d'un installateur modifie son empreinte.

---

# Support et contribution

- **Bugs et demandes** : utiliser les Issues GitHub du dépôt.
- **Sécurité** : `security@kalicorp.fr`
- **Personnalisation** : consulter le Modelfile et [`MODEL-CARD.md`](MODEL-CARD.md).
- **Architecture** : consulter [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).
- **Principes du projet** : consulter [`docs/WHY-KALI-LITE.md`](docs/WHY-KALI-LITE.md).

---

# Licence

Le code et les éléments couverts par la licence du dépôt sont distribués sous :

**GNU General Public License v2.0 only (`GPL-2.0-only`)**

Voir [`LICENSE`](LICENSE).

Les modèles de base et dépendances tierces restent soumis à leurs propres licences.

Copyright © 2026 Kalicorp.

---

**Kalicorp — Le Sanctuaire numérique européen**
