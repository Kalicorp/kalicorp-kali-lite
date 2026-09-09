# Refactor Brief — Kali-Lite Installers

> **Statut : refactor principal réalisé**
>
> Ce document décrit désormais l'architecture cible et les invariants de maintenance des installateurs Kali-Lite.
>
> Il ne doit pas être interprété comme une description de l'ancienne architecture Claude Code / Node.js.

---

## Contexte

Kali-Lite fournit actuellement plusieurs installateurs pour Linux et macOS :

```text
install.sh
auto-install-kali-lite-v1-novision.sh
auto-install-kali-lite-v2-vision.sh
```

Les objectifs du refactor étaient de :

- supporter Linux et macOS proprement ;
- réduire la duplication ;
- séparer logique commune et logique spécifique à chaque OS ;
- supprimer les dépendances inutiles ;
- améliorer la sécurité des téléchargements ;
- préserver le contrôle de l'opérateur ;
- fournir `--dry-run` et `--uninstall` ;
- rendre l'installation inspectable et reproductible.

---

# 1. Variantes actuelles

## Kali-Lite V1

Modèle de base :

```text
qwen3:8b
```

Caractéristiques principales :

- chat ;
- code ;
- assistance système ;
- pas de vision ;
- inférence locale via Ollama.

Installateurs :

```text
install.sh
auto-install-kali-lite-v1-novision.sh
```

`install.sh` est l'installateur de commodité pour cette variante.

---

## Kali-Lite V2

Modèle de base :

```text
qwen3.5:9b
```

Caractéristiques principales :

- chat ;
- code ;
- vision ;
- inférence locale via Ollama.

Installateur :

```text
auto-install-kali-lite-v2-vision.sh
```

---

# 2. Architecture de haut niveau

Chaque installateur suit le même principe général :

```text
Détection OS
    ↓
Résolution utilisateur réel
    ↓
Vérification prérequis
    ↓
Installation / détection Ollama
    ↓
Démarrage Ollama
    ↓
Vérification API locale
    ↓
Téléchargement modèle de base
    ↓
Création Modelfile
    ↓
Création modèle Kali-Lite
    ↓
Nettoyage ancien alias
    ↓
Injection nouvel alias
    ↓
Résumé final
```

Les responsabilités doivent rester clairement séparées entre :

```text
SHARED
LINUX-ONLY
MACOS-ONLY
```

---

# 3. Détection du système

Les installateurs détectent le système avec :

```bash
uname -s
```

Les plateformes prises en charge sont :

```text
Linux
Darwin
```

Tout autre OS doit provoquer un arrêt explicite.

Exemple conceptuel :

```bash
case "$OS" in
  Linux)
    ;;
  Darwin)
    ;;
  *)
    err "Unsupported OS"
    ;;
esac
```

---

# 4. Gestion des privilèges

## Linux

L'installation système actuelle nécessite root.

Exemple :

```bash
sudo bash install.sh
```

ou :

```bash
sudo bash auto-install-kali-lite-v1-novision.sh
```

Le mode :

```bash
--dry-run
```

ne doit pas nécessiter root.

---

## macOS

L'installation ne doit **pas** être exécutée avec `sudo`.

Exemple :

```bash
bash install.sh
```

Homebrew ne doit pas être exécuté en root.

---

# 5. Utilisateur réel

Lorsqu'un script Linux est lancé via `sudo`, l'utilisateur effectif est root mais les modifications de shell doivent viser l'utilisateur ayant lancé la commande.

Les installateurs doivent donc distinguer :

```text
EUID
REAL_USER
REAL_HOME
REAL_SHELL
SHELL_RC
```

Sous Linux, les informations utilisateur peuvent être obtenues notamment via :

```bash
getent passwd
```

Sous macOS :

```bash
dscl
```

Le script ne doit pas supposer que :

```text
$HOME
```

désigne automatiquement le HOME de l'utilisateur final lorsqu'il est exécuté avec `sudo`.

---

# 6. Ollama

Ollama constitue actuellement le runtime principal de Kali-Lite.

## Linux

Si Ollama est absent, son installateur officiel peut être téléchargé depuis :

```text
https://ollama.com/install.sh
```

Le contenu distant doit être :

1. téléchargé dans un fichier ;
2. contrôlé syntaxiquement lorsque pertinent ;
3. exécuté seulement ensuite.

Le projet évite volontairement le pattern :

```bash
curl ... | bash
```

pour ses propres procédures documentées.

---

## macOS

Ollama est installé via Homebrew :

```bash
brew install ollama
```

Homebrew doit déjà être présent.

Kali-Lite ne doit pas installer automatiquement Homebrew en exécutant un script distant à la place de l'utilisateur.

---

# 7. Téléchargements

Les téléchargements doivent privilégier :

```bash
curl -fsSL
```

avec HTTPS.

Lorsque possible, les téléchargements doivent :

- utiliser TLS ;
- avoir un timeout ;
- écrire dans un fichier temporaire privé ;
- vérifier le code retour ;
- vérifier une empreinte lorsque celle-ci est disponible ;
- supprimer les artefacts temporaires après utilisation.

Exemple de répertoire temporaire :

```bash
mktemp -d
```

avec permissions restrictives :

```bash
chmod 0700
```

---

# 8. Chaîne d'approvisionnement

Les installateurs Kali-Lite publiés possèdent des empreintes dans :

```text
SHA256SUMS
```

La procédure utilisateur recommandée reste :

```text
Télécharger
    ↓
Vérifier SHA-256
    ↓
Inspecter
    ↓
Dry-run
    ↓
Exécuter
```

Toute modification d'un installateur implique normalement une nouvelle empreinte SHA-256.

Le fichier `SHA256SUMS` doit être mis à jour **après la dernière modification du script**.

---

# 9. Démarrage Ollama

## Linux

La stratégie privilégiée est :

```text
systemd
    ↓ si indisponible
processus Ollama existant
    ↓ sinon
démarrage manuel
```

Lors d'un démarrage manuel :

```bash
nohup ollama serve ... &
pid=$!
```

Le PID doit être celui du processus réellement lancé.

Il doit être vérifié avec :

```bash
kill -0 "$pid"
```

avant d'être considéré comme valide.

---

## macOS

La stratégie privilégiée est :

```bash
brew services start ollama
```

En cas d'échec, un démarrage manuel contrôlé peut être utilisé.

---

# 10. Vérification API

Le script doit vérifier que l'API Ollama est réellement disponible :

```text
http://127.0.0.1:11434/api/tags
```

Une simple présence du processus ne suffit pas à prouver que le runtime est opérationnel.

Principe :

```text
Processus lancé
        ≠
API disponible
```

Le script doit attendre un temps limité puis échouer clairement si l'API reste indisponible.

---

# 11. Modèles de base

## V1

```bash
ollama pull qwen3:8b
```

## V2

```bash
ollama pull qwen3.5:9b
```

Le téléchargement ne doit être effectué que si le modèle nécessaire n'est pas déjà présent.

---

# 12. Modelfile

Les Modelfiles locaux sont générés dans :

## Linux

V1 :

```text
/etc/kalicorp/Modelfile.kali-lite
```

V2 :

```text
/etc/kalicorp/Modelfile.kali-lite-v2
```

## macOS

V1 :

```text
~/.kalicorp/Modelfile.kali-lite
```

V2 :

```text
~/.kalicorp/Modelfile.kali-lite-v2
```

---

# 13. Doctrine Kali-Lite

Le Modelfile doit conserver plusieurs invariants.

Notamment :

```text
Comprendre une action
        ≠
Avoir l'outil
        ≠
Avoir la permission
        ≠
Avoir exécuté l'action
```

Kali-Lite ne doit pas prétendre :

- avoir lu un fichier non lu ;
- avoir exécuté une commande non exécutée ;
- disposer d'un terminal sans l'avoir constaté ;
- disposer d'Internet sans l'avoir constaté ;
- posséder une permission qui n'a pas été accordée.

La doctrine reste indépendante du harnais technique.

---

# 14. Modèles Kali-Lite créés

## V1

```bash
ollama create kali-lite -f <Modelfile>
```

Résultat :

```text
kali-lite:latest
```

## V2

```bash
ollama create kali-lite-v2 -f <Modelfile>
```

Résultat :

```text
kali-lite-v2:latest
```

---

# 15. Alias shell

## V1

```bash
alias kali-lite='ollama run --think=false kali-lite'
```

## V2

```bash
alias kali-lite-v2='ollama run --think=false kali-lite-v2'
```

Les installateurs doivent :

1. détecter le shell réel ;
2. sauvegarder le fichier RC avant modification ;
3. retirer les anciens blocs Kali-Lite ;
4. éviter les doublons ;
5. injecter un seul bloc courant.

Fichiers possibles :

```text
~/.bashrc
~/.zshrc
```

---

# 16. Aucun Claude Code requis

L'architecture standard actuelle de Kali-Lite ne dépend plus de :

```text
Claude Code
Node.js
NodeSource
ANTHROPIC_API_KEY
ANTHROPIC_AUTH_TOKEN
ANTHROPIC_BASE_URL
```

Ces composants ne doivent pas être réintroduits dans les installateurs standards sans décision d'architecture explicite.

En particulier, aucun alias standard ne doit contenir :

```text
--dangerously-skip-permissions
```

---

# 17. Pas de secret dans les scripts

Les installateurs ne doivent pas :

- contenir de clé API ;
- lire inutilement la valeur d'une clé existante ;
- recopier un secret dans une variable ;
- inscrire un secret dans un Modelfile ;
- afficher un credential dans les logs ;
- injecter une clé dans le shell utilisateur.

Les intégrations externes nécessitant des secrets relèvent du harnais choisi par l'opérateur.

---

# 18. `--dry-run`

Chaque installateur doit proposer :

```bash
--dry-run
```

Le dry-run doit permettre de voir notamment :

- OS détecté ;
- utilisateur réel ;
- shell ;
- modèle concerné ;
- chemins utilisés ;
- stratégie Ollama ;
- alias prévu.

### Invariant

Un dry-run ne doit pas créer d'effet de bord.

Il ne doit notamment pas :

- installer de paquet ;
- télécharger de modèle ;
- modifier `/etc` ;
- modifier le HOME utilisateur ;
- lancer Ollama ;
- modifier le shell RC.

---

# 19. `--uninstall`

Chaque installateur doit proposer :

```bash
--uninstall
```

Une confirmation utilisateur doit être demandée.

La désinstallation doit supprimer uniquement les éléments propres à Kali-Lite.

Exemples :

```text
alias Kali-Lite
Modelfile Kali-Lite
tag Ollama kali-lite
tag Ollama kali-lite-v2
```

Elle ne doit pas supprimer arbitrairement :

```text
Ollama
les autres modèles
les données d'autres outils
les configurations partagées
```

Principe :

> **Désinstaller Kali-Lite ne doit pas casser l'environnement Ollama de l'utilisateur.**

---

# 20. Invariants de sécurité

Les installateurs doivent conserver au minimum les propriétés suivantes :

```text
set -euo pipefail
```

et :

- pas de `eval` pour exécuter des chaînes construites dynamiquement ;
- pas de `curl | bash` dans la procédure Kali-Lite recommandée ;
- fichiers temporaires privés ;
- PID réel capturé avec `$!` ;
- vérification du PID ;
- vérification de l'API Ollama ;
- sauvegarde du shell RC ;
- pas de secrets intégrés ;
- pas de permissions agentiques implicites ;
- pas de suppression globale d'Ollama lors du uninstall.

---

# 21. Tests

Les installateurs doivent au minimum passer :

```bash
bash -n install.sh
bash -n auto-install-kali-lite-v1-novision.sh
bash -n auto-install-kali-lite-v2-vision.sh
```

Les tests du dépôt couvrent notamment :

```text
tests/test_dry_run.sh
tests/test-no-secret-leak.sh
tests/test_pid_fidelity.sh
tests/test_structure.sh
```

Lorsqu'un installateur est modifié, les tests pertinents doivent être exécutés.

La CI doit également contrôler la syntaxe et les invariants essentiels.

---

# 22. CI GitHub

Le workflow principal est :

```text
.github/workflows/test-installers.yml
```

Il vérifie notamment :

- syntaxe Bash ;
- structure des installateurs ;
- présence des modèles attendus ;
- présence des fichiers essentiels ;
- ShellCheck ;
- dry-run ;
- régressions liées aux secrets.

Les tests CI ne remplacent pas un test réel sur Linux et macOS lorsque le comportement de plateforme est modifié.

---

# 23. Structure recommandée du code

La structure fonctionnelle doit rester proche de :

```text
helpers
    ↓
detect_os
    ↓
resolve_user_context
    ↓
download helpers
    ↓
GPU detection
    ↓
Ollama helpers
    ↓
install_linux / install_macos
    ↓
Modelfile
    ↓
model creation
    ↓
shell cleanup / alias
    ↓
summary
```

Une fonction doit avoir une responsabilité claire.

Éviter de recopier la même logique dans les branches Linux et macOS lorsqu'elle peut raisonnablement être factorisée.

---

# 24. Règles de modification

Toute Pull Request modifiant les installateurs doit vérifier :

1. syntaxe Bash ;
2. dry-run ;
3. absence de nouveaux secrets ;
4. comportement Linux ;
5. comportement macOS lorsque concerné ;
6. gestion des permissions ;
7. gestion des PID ;
8. effets du uninstall ;
9. documentation ;
10. nouvelle empreinte SHA-256.

Une modification qui change le comportement réel doit également être répercutée, selon le cas, dans :

```text
README.md
INSTALLATION.md
MODEL-CARD.md
SECURITY.md
SHA256SUMS
```

---

# 25. Ce que Kali-Lite ne cherche pas à garantir

Le refactor ne doit pas conduire à des affirmations absolues impossibles à soutenir.

Éviter :

```text
zero cloud
zero network
zero dependency
unlimited AI
automatic GDPR compliance
```

Préférer des formulations précises :

```text
inférence locale
pas de télémétrie ajoutée par Kali-Lite
pas de service d'inférence Kalicorp requis
pas de quota commercial d'inférence
dépendances documentées et remplaçables
```

---

# 26. Principe directeur

Les installateurs doivent rester cohérents avec la philosophie générale du projet :

> **Télécharger → vérifier → inspecter → simuler → exécuter.**

et :

> **preuve avant affirmation.**

La simplicité d'installation ne doit pas être obtenue au prix de la visibilité ou du contrôle de l'opérateur.

---

## État du refactor

### Réalisé

- [x] Linux + macOS
- [x] séparation des branches OS
- [x] fonctions partagées
- [x] suppression Claude Code
- [x] suppression Node.js / NodeSource
- [x] suppression des variables Anthropic
- [x] suppression de `--dangerously-skip-permissions`
- [x] téléchargement Ollama via fichier temporaire
- [x] `--dry-run`
- [x] `--uninstall`
- [x] conservation d'Ollama lors du uninstall
- [x] PID fidèle
- [x] vérification API
- [x] empreintes SHA-256
- [x] tests CI
- [x] documentation Linux / macOS

### À poursuivre

- [ ] support Windows / WSL2
- [ ] augmentation de la couverture des tests comportementaux
- [ ] amélioration de la reproductibilité des dépendances tierces
- [ ] support de modèles de base supplémentaires
- [ ] tests réels automatisés macOS lorsque raisonnablement possible

---

**Kalicorp — Le Sanctuaire numérique européen**  
Copyright © 2026 Kalicorp
