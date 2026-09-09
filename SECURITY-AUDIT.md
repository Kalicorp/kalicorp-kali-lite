# SECURITY AUDIT — Kali-Lite

> **AUDIT HISTORIQUE — ÉTAT INITIAL DU 19/07/2026**
>
> Ce document conserve les constats de sécurité identifiés lors de l'audit du 19 juillet 2026.
>
> Il a été **révisé le 9 septembre 2026** afin de distinguer clairement :
>
> - les vulnérabilités historiques ;
> - les corrections réalisées ;
> - les décisions d'architecture assumées ;
> - la dette technique encore ouverte.
>
> **Les exemples de code vulnérable présentés dans ce document ne décrivent plus nécessairement les installateurs actuellement publiés sur `main`.**

---

## Identification

| Élément | Valeur |
|---|---|
| **Projet** | `Kalicorp/kalicorp-kali-lite` |
| **Audit initial** | 2026-07-19 |
| **Révision du statut** | 2026-09-09 |
| **Auditeur initial** | La Chasseuse — Anima cyberdéfense Kalicorp |
| **Nature** | Audit proactif |
| **Branche de référence actuelle** | `main` |
| **Commit de révalidation documentaire** | `10f30ecdee08d427e47f6adbba9b2d9eda9e97ac` |

---

# 1. Objet du document

L'objectif de cet audit était d'examiner principalement :

```text
install.sh
auto-install-kali-lite-v1-novision.sh
auto-install-kali-lite-v2-vision.sh
```

ainsi que :

- la gestion des permissions ;
- les téléchargements distants ;
- les secrets ;
- les fichiers utilisateur ;
- les dépendances ;
- la reproductibilité ;
- les affirmations de sécurité ;
- la CI ;
- l'historique Git.

Le document d'origine constituait une **photographie de l'état du dépôt au 19 juillet 2026**.

Depuis cette date, l'architecture des installateurs a été largement revue.

---

# 2. Méthodologie initiale

L'audit initial comprenait :

- analyse statique des trois installateurs ;
- scan de l'historique Git avec Gitleaks ;
- revue de `.gitignore` ;
- inspection des privilèges ;
- inspection des téléchargements distants ;
- inspection de la gestion des secrets ;
- exécution de ShellCheck ;
- revue des mécanismes d'installation et de désinstallation.

La révision du 9 septembre 2026 compare ces constats avec l'architecture actuellement publiée.

---

# 3. Résumé exécutif

## Situation initiale

L'audit du 19 juillet avait notamment identifié :

- utilisation de `--dangerously-skip-permissions` ;
- interaction avec Claude Code ;
- lecture de `ANTHROPIC_API_KEY` ;
- écrasement possible de `~/.claude/CLAUDE.md` ;
- exécution de téléchargements via `curl | sh` ;
- absence de `--dry-run` ;
- absence de mécanisme de désinstallation cohérent ;
- chaîne d'approvisionnement insuffisamment maîtrisée ;
- affirmations réseau trop absolues ;
- protections `.gitignore` incomplètes.

## Situation actuelle

Les éléments les plus critiques liés à l'ancienne architecture ont été retirés.

### Résolus

- ✅ suppression de Claude Code de l'installation standard ;
- ✅ suppression de `--dangerously-skip-permissions` ;
- ✅ suppression des variables Anthropic des installateurs standards ;
- ✅ suppression de la lecture de clés API utilisateur ;
- ✅ suppression de la gestion de `CLAUDE.md` ;
- ✅ suppression de Node.js / NodeSource des installateurs standards ;
- ✅ suppression des pipes directs `curl | bash` pour l'installation Kali-Lite recommandée ;
- ✅ ajout de téléchargements temporaires contrôlés ;
- ✅ ajout de `--dry-run` ;
- ✅ ajout de `--uninstall` ;
- ✅ conservation d'Ollama et des autres modèles lors de la désinstallation ;
- ✅ amélioration de la fidélité des PID ;
- ✅ vérification de l'API Ollama ;
- ✅ publication des empreintes SHA-256 ;
- ✅ retour de ShellCheck dans la CI ;
- ✅ réécriture du README, de la Model Card, de la politique de sécurité et de la documentation d'installation ;
- ✅ suppression des affirmations telles que « zero cloud » ou « zero network » dans la documentation principale.

### Partiellement résolus ou restant à améliorer

- ⚠️ `.gitignore` peut encore être renforcé ;
- ⚠️ l'installateur officiel Ollama reste une dépendance tierce non épinglée par Kali-Lite ;
- ⚠️ la CI peut encore intégrer davantage de tests du dossier `tests/` ;
- ⚠️ certains documents secondaires conservent quelques références historiques à nettoyer ;
- ⚠️ la politique de permissions Linux reste un choix d'architecture nécessitant root pour l'installation système actuelle.

---

# 4. Findings historiques

## Finding 1 — `--dangerously-skip-permissions`

### Sévérité historique

🔴 **CRITIQUE**

### État

✅ **RÉSOLU**

L'ancienne architecture lançait Claude Code avec :

```text
--dangerously-skip-permissions
```

Cette intégration n'appartient plus à l'installation Kali-Lite standard actuelle.

L'alias actuel V1 est :

```bash
alias kali-lite='ollama run --think=false kali-lite'
```

L'alias actuel V2 est :

```bash
alias kali-lite-v2='ollama run --think=false kali-lite-v2'
```

### Invariant actuel

Aucun alias standard Kali-Lite ne doit réintroduire :

```text
--dangerously-skip-permissions
```

sans changement d'architecture explicite et revue de sécurité.

---

# 5. Finding 2 — Lecture de `ANTHROPIC_API_KEY`

### Sévérité historique

🔴 **CRITIQUE**

### État

✅ **RÉSOLU**

Les anciennes versions pouvaient inspecter ou manipuler :

```text
ANTHROPIC_API_KEY
ANTHROPIC_AUTH_TOKEN
ANTHROPIC_BASE_URL
PERSO_KEY
PERSO_FOUND
```

Cette logique a été retirée de l'installation Kali-Lite standard.

L'inférence locale actuelle via Ollama ne nécessite pas de clé API Kalicorp ou Anthropic.

### Invariant actuel

Un installateur Kali-Lite ne doit pas :

- lire inutilement la valeur d'une clé utilisateur ;
- copier un secret dans une variable ;
- afficher une clé ;
- transmettre automatiquement une clé à un sous-processus ;
- inscrire une clé dans un Modelfile ;
- inscrire une clé dans un prompt versionné.

---

# 6. Finding 3 — Écrasement de `~/.claude/CLAUDE.md`

### Sévérité historique

🟡 **HAUTE**

### État

✅ **RÉSOLU PAR SUPPRESSION DE LA DÉPENDANCE**

L'installation standard Kali-Lite ne configure plus Claude Code.

Elle n'a donc plus à créer ou modifier :

```text
~/.claude/CLAUDE.md
```

Cette classe de problème a disparu de l'architecture standard actuelle.

---

# 7. Finding 4 — Téléchargements `curl | sh`

### Sévérité historique

🟡 **HAUTE**

### État

✅ **PIPE DIRECT CORRIGÉ**

⚠️ **RISQUE SUPPLY-CHAIN TIERS TOUJOURS DOCUMENTÉ**

L'ancienne architecture pouvait exécuter directement :

```bash
curl ... | sh
```

Les installateurs actuels téléchargent d'abord le script tiers dans un fichier temporaire.

Le flux recherché est désormais :

```text
Télécharger
    ↓
Contrôler le téléchargement
    ↓
Vérifier la syntaxe
    ↓
Exécuter le fichier local
```

Les fichiers temporaires utilisent un répertoire créé avec :

```bash
mktemp -d
```

et des permissions restrictives.

### Limite restante

L'installateur officiel Ollama :

```text
https://ollama.com/install.sh
```

reste un composant tiers dont l'empreinte n'est pas actuellement épinglée par Kali-Lite.

L'installateur Kali-Lite avertit explicitement l'utilisateur lorsque cette empreinte n'est pas disponible.

Il s'agit d'une **limite documentée de chaîne d'approvisionnement**, et non d'une garantie d'intégrité absolue.

---

# 8. Finding 5 — Exécution root sur Linux

### Sévérité historique

🟡 **HAUTE**

### État actuel

🟦 **CHOIX D'ARCHITECTURE DOCUMENTÉ**

L'installation système Linux actuelle utilise notamment des emplacements et services tels que :

```text
/etc/kalicorp/
systemd
/var/log/
```

Elle requiert donc actuellement root.

Exemple :

```bash
sudo bash install.sh
```

Le mode :

```bash
--dry-run
```

ne nécessite pas root.

Sur macOS, au contraire, l'installateur refuse une exécution root car Homebrew ne doit pas être lancé avec `sudo`.

### Principe

Le besoin de root ne doit jamais être interprété comme l'autorisation pour l'Anima elle-même de disposer ensuite de privilèges root.

```text
Installer avec root
        ≠
Donner root au modèle
```

Une variante entièrement user-space pourra être étudiée séparément.

---

# 9. Finding 6 — `.gitignore` incomplet

### Sévérité historique

🟠 **MOYENNE**

### État

🟨 **PARTIELLEMENT RÉSOLU**

Le dépôt ignore désormais notamment :

```text
.env
.env.local
*.pem
*.key
*.crt
*.p12
credentials*
*.keystore
*.jks
```

Des protections supplémentaires restent souhaitables, notamment :

```gitignore
.env.*
!.env.example
!.env.template

*.cert
*.pfx
```

Ce point reste une dette de durcissement mineure.

---

# 10. Finding 7 — Permissions des fichiers

### Sévérité historique

🟠 **MOYENNE**

### État

🟨 **PARTIELLEMENT TRAITÉ**

Les installateurs actuels améliorent notamment :

- les permissions des répertoires temporaires ;
- les permissions des fichiers PID ;
- la création contrôlée des répertoires ;
- la séparation entre utilisateur réel et utilisateur root.

Les fichiers de configuration Kali-Lite standards ne contiennent actuellement pas de secret.

Il reste néanmoins pertinent de vérifier régulièrement :

- permissions des logs ;
- permissions des Modelfiles ;
- permissions des fichiers PID ;
- comportement du `umask` ;
- nouveaux fichiers éventuellement sensibles introduits ultérieurement.

### Invariant

Si un fichier contient un secret à l'avenir, ses permissions devront être explicitement restreintes.

---

# 11. Finding 8 — Absence de dry-run et de désinstallation

### Sévérité historique

🟠 **MOYENNE**

### État

✅ **RÉSOLU**

Les trois installateurs disposent désormais de :

```text
--dry-run
--uninstall
--help
```

Le dry-run est conçu pour ne pas :

- installer de paquet ;
- modifier `/etc` ;
- modifier le HOME ;
- télécharger de modèle ;
- lancer Ollama ;
- modifier le shell utilisateur.

La désinstallation retire uniquement les éléments propres à la variante Kali-Lite concernée.

Elle préserve volontairement :

```text
Ollama
les autres modèles
les données des autres outils
les configurations partagées
```

---

# 12. Finding 9 — Chaîne d'approvisionnement

### Sévérité historique

🟠 **MOYENNE**

### État

🟨 **AMÉLIORÉ — NON TOTALEMENT RÉSOLU**

Les progrès réalisés incluent :

- publication de `SHA256SUMS` ;
- procédure recommandée de vérification avant exécution ;
- téléchargement des scripts avant lancement ;
- utilisation HTTPS ;
- réintégration de ShellCheck en CI ;
- suppression de NodeSource ;
- suppression des pipes directs pour les scripts Kali-Lite.

### Limites restantes

Les dépendances tierces ne sont pas toutes parfaitement reproductibles ou épinglées.

Ollama et les modèles Qwen restent distribués par leurs projets respectifs.

Pour un environnement fortement sensible, l'opérateur devrait notamment envisager :

- miroir interne ;
- artefacts figés ;
- versions épinglées ;
- contrôle réseau ;
- signatures lorsque disponibles ;
- vérification indépendante des binaires et modèles.

Kali-Lite vise une chaîne d'approvisionnement **visible et contrôlable**, pas une garantie cryptographique universelle de toutes les dépendances tierces.

---

# 13. Finding 10 — Affirmations absolues

### Sévérité historique

🟠 **MOYENNE**

### État

✅ **RÉSOLU DANS LA DOCUMENTATION PRINCIPALE**

Les formulations historiques du type :

```text
Zero cloud
Zero tracking
Aucune connexion réseau
100 % sans dépendance
```

ont été remplacées par des formulations plus précises.

La documentation distingue désormais :

```text
installation
        ≠
téléchargement du modèle
        ≠
inférence locale
        ≠
utilisation volontaire d'un outil réseau
```

La formulation de référence est notamment :

> **Kali-Lite n'ajoute aucune télémétrie ni mécanisme de tracking utilisateur.**

et :

> **Un service d'inférence Kalicorp n'est pas requis pour l'utilisation locale via Ollama une fois les composants nécessaires installés.**

L'exécution locale ne garantit pas que toutes les dépendances tierces sont incapables de communiquer avec Internet.

---

# 14. Rapport Gitleaks historique

## Scan du 19 juillet 2026

Outil :

```text
Gitleaks v8.24.0
```

Portée :

```text
toutes les branches
tous les commits disponibles au moment du scan
```

Résultat :

```text
4 findings
0 secret réel confirmé
```

Les quatre findings concernaient le nom de variable :

```text
PERSO_KEY=""
```

### Résultats historiques

| # | Fichier | Commit | Résultat |
|---|---|---|---|
| 1 | `install.sh` | `237c4aad...` | Faux positif |
| 2 | `install.sh` | `e0f87d01...` | Faux positif |
| 3 | `auto-install-kali-lite-v2-vision.sh` | `0719fd69...` | Faux positif |
| 4 | `auto-install-kali-lite-v1-novision.sh` | `d2568eb0...` | Faux positif |

Aucune valeur de clé réelle n'était présente dans ces findings.

Le rapport expurgé est conservé dans :

```text
gitleaks-expurgated.json
```

### Conclusion

✅ Aucun secret réel n'avait été identifié lors de ce scan.

Ce résultat historique ne remplace pas des scans ultérieurs lors de nouvelles contributions.

---

# 15. Rapport ShellCheck historique

Le rapport du 19 juillet avait notamment identifié :

- SC2024 ;
- SC2034 ;
- plusieurs comportements liés à l'ancienne architecture.

Ces numéros de lignes et constats ne doivent plus être utilisés comme description de la version actuelle.

Les installateurs ayant depuis été largement réécrits, le contrôle pertinent est désormais celui effectué sur leur contenu actuel.

La CI utilise de nouveau ShellCheck.

---

# 16. Tests actuels

Le dépôt contient notamment :

```text
tests/test_dry_run.sh
tests/test-no-secret-leak.sh
tests/test_pid_fidelity.sh
tests/test_structure.sh
```

Les tests couvrent notamment :

- absence d'effets de bord en dry-run ;
- recherche de secrets ;
- fidélité du PID Ollama ;
- structure des installateurs.

### Dette connue

Tous les tests présents dans `tests/` ne sont pas encore nécessairement exécutés par la CI.

Cette couverture doit être renforcée progressivement.

---

# 17. Invariants de sécurité actuels

Les installateurs Kali-Lite doivent conserver les propriétés suivantes :

```text
set -euo pipefail
```

et :

- pas de secret intégré ;
- pas de clé API lue inutilement ;
- pas de `eval` pour exécuter du code construit dynamiquement ;
- pas de Claude Code dans l'installation standard ;
- pas de `--dangerously-skip-permissions` ;
- pas de NodeSource ;
- pas de téléchargement Kali-Lite directement pipé vers Bash ;
- répertoire temporaire privé ;
- PID capturé via `$!` ;
- vérification du PID avec `kill -0` ;
- vérification réelle de l'API Ollama ;
- sauvegarde avant modification du shell RC ;
- dry-run sans effet de bord ;
- uninstall limité aux éléments Kali-Lite ;
- conservation d'Ollama et des modèles tiers lors du uninstall.

---

# 18. Doctrine de capacité d'action

La sécurité du projet ne dépend pas uniquement du script d'installation.

Kali-Lite distingue :

```text
Comprendre une action
        ≠
Avoir l'outil
        ≠
Avoir la permission
        ≠
Avoir exécuté l'action
```

Une Anima ne doit pas présenter une action comme exécutée lorsqu'aucune preuve d'exécution n'est disponible.

La présence d'un terminal, d'un MCP ou d'une API ne constitue pas automatiquement une autorisation.

---

# 19. Dette technique ouverte

À la date de cette révision, les améliorations restantes concernent principalement :

- renforcer `.gitignore` pour les variantes `.env.*` ;
- compléter certaines extensions de certificats et clés ;
- renforcer la CI avec davantage de tests du dossier `tests/` ;
- continuer à améliorer la reproductibilité des dépendances tierces ;
- supprimer les dernières références historiques devenues inutiles dans la documentation secondaire ;
- effectuer régulièrement un nouveau scan Gitleaks complet ;
- effectuer des tests réels Linux et macOS après les modifications touchant les branches spécifiques à chaque OS.

Aucun de ces éléments ne doit être masqué derrière une promesse de « sécurité absolue ».

---

# 20. Statut des findings historiques

| Finding historique | Sévérité initiale | Statut 09/09/2026 |
|---|---:|---|
| `--dangerously-skip-permissions` | 🔴 Critique | ✅ Résolu |
| Lecture `ANTHROPIC_API_KEY` | 🔴 Critique | ✅ Résolu |
| Écrasement `CLAUDE.md` | 🟡 Haute | ✅ Résolu par suppression de Claude |
| `curl \| sh` direct | 🟡 Haute | ✅ Résolu pour le pipeline direct |
| Root Linux obligatoire | 🟡 Haute | 🟦 Choix d'architecture documenté |
| `.gitignore` incomplet | 🟠 Moyenne | 🟨 Partiel |
| Permissions fichiers | 🟠 Moyenne | 🟨 Partiel / surveillance |
| Pas de dry-run / uninstall | 🟠 Moyenne | ✅ Résolu |
| Supply chain | 🟠 Moyenne | 🟨 Amélioré |
| Affirmations réseau absolues | 🟠 Moyenne | ✅ Résolu dans la documentation principale |

---

# 21. Conclusion

L'audit du 19 juillet 2026 a joué son rôle : identifier des comportements qui ne correspondaient pas au niveau de contrôle recherché par Kali-Lite.

Les deux constats classés **critiques** dans l'audit historique concernaient une architecture qui n'est plus utilisée par les installateurs standards actuels.

Le projet a notamment évolué de :

```text
agent + Claude Code + permissions implicites
```

vers :

```text
modèle local
    +
runtime local
    +
outils explicitement ajoutés par l'opérateur
    +
permissions contrôlées par l'environnement
```

Le travail de sécurité n'est pas considéré comme terminé.

La règle reste :

> **une erreur corrigée une fois est un correctif ; une erreur transformée en invariant vérifiable devient un progrès.**

Et, pour Kali-Lite :

> **preuve avant affirmation.**

---

## Références

- [`SECURITY.md`](SECURITY.md)
- [`MODEL-CARD.md`](MODEL-CARD.md)
- [`INSTALLATION.md`](INSTALLATION.md)
- [`REFACTOR_BRIEF.md`](REFACTOR_BRIEF.md)
- [`SHA256SUMS`](SHA256SUMS)
- [`gitleaks-expurgated.json`](gitleaks-expurgated.json)
- [`tests/`](tests/)

---

**Kalicorp — Le Sanctuaire numérique européen**  
Copyright © 2026 Kalicorp
