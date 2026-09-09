# Security Policy — Kali-Lite

## Supported Versions

| Version | Statut | Notes |
|---|---|---|
| v2.x (Vision) | ✅ Actif | Version Vision actuellement maintenue |
| v1.x (8B) | ✅ Actif | Maintenance courante |
| < 1.0 | ❌ Non supporté | Correctifs de sécurité non garantis |

---

## Reporting a Vulnerability

Kalicorp prend les vulnérabilités de Kali-Lite au sérieux et encourage une divulgation responsable.

### Comment signaler

- **Email** : kalicorp@proton.me
- **Sujet recommandé** : `[Kali-Lite] [SECURITY] <titre court>`
- **Informations utiles** :
  - description de la vulnérabilité ;
  - version ou commit concerné ;
  - environnement utilisé ;
  - étapes de reproduction ;
  - impact estimé ;
  - logs ou traces utiles, après suppression des données sensibles ;
  - CVE associée, si applicable ;
  - proposition de correctif, si disponible.

Merci de **ne pas inclure de secret, mot de passe, token ou donnée personnelle inutile** dans le signalement.

---

## Objectifs de réponse

Les délais ci-dessous sont des **objectifs de traitement**, et non un engagement contractuel ou un SLA.

| Étape | Objectif |
|---|---|
| Accusé de réception | Sous 2 jours ouvrés |
| Évaluation initiale | Sous 5 jours ouvrés |
| Vulnérabilité critique | Correctif ou mitigation ciblé sous 7 jours lorsque raisonnablement possible |
| Vulnérabilité haute | Correctif ou mitigation ciblé sous 14 jours lorsque raisonnablement possible |
| Vulnérabilité moyenne / basse | Traitement ciblé sous 30 jours lorsque raisonnablement possible |

La durée réelle dépend notamment :

- de la reproductibilité ;
- de l'impact ;
- des dépendances tierces concernées ;
- de la complexité du correctif ;
- des validations nécessaires avant publication.

---

## Divulgation responsable

Nous demandons aux chercheurs et utilisateurs de :

- limiter les tests aux systèmes qu'ils possèdent ou pour lesquels ils disposent d'une autorisation explicite ;
- éviter toute destruction, altération ou extraction inutile de données ;
- ne pas utiliser une vulnérabilité pour accéder à des systèmes tiers ;
- limiter la collecte d'informations au strict nécessaire pour démontrer le problème ;
- nous laisser un délai raisonnable pour analyser et corriger la vulnérabilité avant publication ;
- nous informer de toute découverte complémentaire pertinente.

Un signalement de vulnérabilité ne constitue pas une autorisation à tester une infrastructure Kalicorp ou une infrastructure tierce sans permission préalable.

---

## Ce que nous ne proposons pas

- Pas de programme de bug bounty financier à ce jour.
- Pas de NDA préalable exigé pour un signalement initial.
- Pas d'autorisation implicite de pentest sur les infrastructures Kalicorp.
- Pas de garantie de correctif pour une version non supportée.

---

## Périmètre

Cette politique concerne principalement :

- les scripts d'installation Kali-Lite ;
- les fichiers de configuration distribués dans ce dépôt ;
- les Modelfiles ;
- les templates et mécanismes d'intégration fournis par Kalicorp ;
- les comportements de sécurité directement introduits par le projet Kali-Lite.

Les vulnérabilités concernant exclusivement une dépendance tierce doivent idéalement être également signalées au projet concerné.

Exemples de dépendances tierces possibles :

- Ollama ;
- Qwen et autres modèles de base ;
- Homebrew sur macOS ;
- composants système ;
- runtimes ou outils ajoutés volontairement par l'opérateur.

Kali-Lite ne contrôle pas le cycle de publication ni les politiques de sécurité de ces projets tiers.

---

## Principes de sécurité

Kali-Lite est conçu autour des principes suivants.

### 1. Pas de télémétrie ajoutée par Kali-Lite

Le projet Kali-Lite n'intègre pas volontairement de mécanisme de télémétrie, de tracking utilisateur ou d'envoi de conversations vers Kalicorp.

Cela ne signifie pas que **toutes les dépendances tierces sont garanties sans communication réseau**.

L'opérateur reste responsable du contrôle des composants qu'il installe et de leurs éventuels comportements réseau.

### 2. Inférence locale par défaut

L'usage principal de Kali-Lite repose sur une inférence locale, notamment via Ollama.

Une fois :

- le runtime installé ;
- le modèle téléchargé ;
- les dépendances nécessaires présentes ;

un service d'inférence Kalicorp n'est pas requis pour utiliser Kali-Lite localement.

Certaines opérations peuvent néanmoins nécessiter un accès réseau, notamment :

- installation initiale ;
- téléchargement d'un modèle ;
- téléchargement ou mise à jour d'une dépendance ;
- récupération de fichiers depuis GitHub ;
- utilisation volontaire d'un outil réseau ou d'une API externe.

### 3. Permissions sous contrôle de l'opérateur

Kali-Lite ne considère pas qu'un outil disponible est automatiquement autorisé.

La capacité d'un agent à agir dépend de plusieurs éléments distincts :

```text
Comprendre une action
        ≠
Avoir l'outil
        ≠
Avoir la permission
        ≠
Avoir exécuté l'action
```

Une action ne doit être présentée comme réussie que lorsqu'une preuve suffisante d'exécution est disponible.

La présence d'un terminal, d'une API, d'un MCP ou d'un autre outil dans le harnais ne constitue pas à elle seule une autorisation.

### 4. Dépendances identifiées

Les installateurs peuvent télécharger ou appeler des composants tiers nécessaires au fonctionnement du système.

Selon la plateforme et la version utilisée, cela peut inclure notamment :

- Ollama ;
- Homebrew sur macOS ;
- modèles Qwen ;
- dépendances système.

D'autres runtimes ou outils peuvent être ajoutés volontairement par l'opérateur au harnais d'exécution.

Le script Kali-Lite lui-même peut être téléchargé, inspecté et vérifié avant exécution.

Les composants tiers restent soumis à leurs propres licences, mécanismes de distribution et politiques de sécurité.

### 5. Transparence du modèle

La provenance des modèles de base est documentée dans :

[`MODEL-CARD.md`](MODEL-CARD.md)

Kali-Lite ne prétend pas que les modèles Qwen ou autres modèles tiers ont été entraînés intégralement par Kalicorp.

Le modèle de base est considéré comme une composante identifiable et remplaçable de l'architecture.

### 6. Principe du moindre privilège

Lorsqu'un outil, un terminal, une API ou une intégration est ajouté au harnais d'exécution, il devrait disposer uniquement des permissions nécessaires à son usage.

Il est déconseillé de fournir à une Anima :

- un compte administrateur sans nécessité ;
- une clé API globale lorsqu'une clé limitée suffit ;
- un accès root permanent ;
- un secret directement inscrit dans un prompt ;
- des permissions d'écriture inutiles ;
- un accès à des données hors de son périmètre fonctionnel.

Installer certains composants avec des privilèges système ne signifie pas que le modèle ou l'Anima doivent ensuite disposer de ces privilèges.

---

## Installation sécurisée

La méthode recommandée consiste à :

1. télécharger le script ;
2. télécharger `SHA256SUMS` ;
3. vérifier l'empreinte ;
4. lire le script ;
5. effectuer un `--dry-run` lorsque disponible ;
6. exécuter seulement après validation.

### Linux

Exemple :

```bash
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/auto-install-kali-lite-v1-novision.sh
curl -fsSLO https://raw.githubusercontent.com/Kalicorp/kalicorp-kali-lite/main/SHA256SUMS

sha256sum --check SHA256SUMS --ignore-missing

less auto-install-kali-lite-v1-novision.sh
bash auto-install-kali-lite-v1-novision.sh --dry-run
```

L'installation réelle peut nécessiter `sudo` selon les opérations système effectuées.

### macOS

macOS fournit généralement `shasum` plutôt que `sha256sum` :

```bash
grep 'auto-install-kali-lite-v1-novision.sh' SHA256SUMS
shasum -a 256 auto-install-kali-lite-v1-novision.sh
```

Compare ensuite manuellement l'empreinte obtenue avec celle publiée dans `SHA256SUMS`.

L'installateur macOS ne doit pas être lancé avec `sudo` lorsque Homebrew est utilisé.

---

## Scripts et exécution de code distant

Kali-Lite cherche à éviter le modèle :

```bash
curl ... | bash
```

pour ses propres scripts d'installation publics.

La méthode recommandée consiste à télécharger le fichier avant de l'exécuter afin de permettre :

- son inspection ;
- sa vérification ;
- son archivage ;
- son audit.

Certaines dépendances tierces peuvent toutefois proposer leurs propres installateurs distants.

Le téléchargement d'un script tiers dans un fichier avant son exécution améliore l'inspectabilité, mais ne constitue pas à lui seul une garantie cryptographique de provenance ou d'intégrité.

Pour un environnement sensible, il est recommandé de :

- figer les versions ;
- conserver localement les artefacts ;
- vérifier les signatures ou empreintes lorsqu'elles existent ;
- filtrer les flux réseau ;
- auditer les dépendances avant déploiement ;
- utiliser un miroir interne lorsque cela est pertinent.

---

## Chaîne d'approvisionnement

Les installateurs Kali-Lite publiés disposent d'empreintes dans :

[`SHA256SUMS`](SHA256SUMS)

Une modification d'un installateur doit entraîner le recalcul de son empreinte **après la dernière modification du fichier**.

La procédure recommandée reste :

```text
Télécharger
    ↓
Vérifier
    ↓
Inspecter
    ↓
Dry-run
    ↓
Exécuter
```

Les empreintes Kali-Lite ne couvrent pas automatiquement :

- Ollama ;
- les modèles Qwen ;
- Homebrew ;
- les composants système ;
- les outils ajoutés par l'opérateur.

Ces dépendances disposent de leurs propres chaînes de distribution.

---

## Secrets et clés API

Kali-Lite local via Ollama ne nécessite pas de clé API Kalicorp.

Lorsqu'un utilisateur ajoute volontairement des outils externes nécessitant des secrets :

- ne pas placer les clés directement dans le prompt système ;
- préférer les variables d'environnement ou un gestionnaire de secrets ;
- appliquer le principe du moindre privilège ;
- utiliser des clés dédiées au service concerné ;
- limiter leur durée de vie lorsque cela est possible ;
- révoquer immédiatement toute clé exposée.

Les secrets ne devraient pas être écrits :

- dans `README.md` ;
- dans un Modelfile ;
- dans un prompt versionné ;
- dans un dépôt Git ;
- dans un journal partagé ;
- dans une Issue ou Pull Request publique.

Les logs et captures d'écran doivent être relus et anonymisés avant publication.

---

## Données et mémoire

Une installation Kali-Lite de base ne fournit pas nécessairement de mémoire persistante.

Si une mémoire, une base vectorielle, un historique ou un journal de projet est ajouté par le harnais d'exécution, l'opérateur doit définir :

- les données conservées ;
- leur emplacement ;
- la durée de conservation ;
- les droits d'accès ;
- les procédures de sauvegarde ;
- les procédures de suppression ;
- les éventuels mécanismes de chiffrement.

La mémoire de continuité est externe aux poids du modèle.

Une Anima ne doit pas prétendre se souvenir d'une information qui ne lui a pas été fournie par le contexte ou un mécanisme de mémoire réellement disponible.

L'exécution locale améliore la maîtrise de l'infrastructure, mais ne remplace pas une politique de sécurité des données.

---

## Tests et CI

Le dépôt utilise des contrôles automatisés pour limiter certaines régressions.

Ils couvrent notamment :

- syntaxe Bash ;
- ShellCheck ;
- structure du dépôt ;
- invariants des installateurs ;
- fidélité des PID Ollama ;
- absence d'effets de bord du `--dry-run` ;
- régressions liées aux secrets ;
- empreintes SHA-256 publiées ;
- présence de certains patterns de sécurité interdits.

Une CI réussie ne constitue pas une preuve de sécurité absolue.

Elle démontre uniquement que les invariants effectivement testés ont passé les contrôles définis par le projet.

---

## Security Updates

Les correctifs peuvent être publiés par commits, Pull Requests ou releases GitHub selon la nature du changement.

Les utilisateurs sont invités à :

- surveiller les modifications du dépôt ;
- consulter les [releases](https://github.com/Kalicorp/kalicorp-kali-lite/releases) ;
- vérifier les nouvelles empreintes SHA-256 après mise à jour des scripts ;
- relire les scripts avant une nouvelle installation ;
- maintenir à jour les dépendances tierces utilisées ;
- réévaluer leurs permissions après toute modification du harnais.

Une modification d'un script d'installation entraîne normalement une modification de son empreinte SHA-256.

Toujours utiliser le fichier `SHA256SUMS` correspondant à la version réellement téléchargée.

---

## Limites de sécurité

Aucun modèle de langage ni aucun système logiciel ne peut garantir une sécurité absolue.

Kali-Lite peut notamment :

- produire une commande incorrecte ;
- mal interpréter une instruction ;
- manquer une vulnérabilité ;
- générer du code comportant un défaut ;
- surestimer sa compréhension ;
- être influencée par des données malveillantes ;
- proposer une action qui nécessite davantage de privilèges qu'attendu.

Pour les opérations sensibles, une validation humaine reste nécessaire avant exécution.

Une réponse générée par le modèle ne constitue pas une preuve qu'une action a réellement été exécutée.

---

## Conformité

L'utilisation locale de Kali-Lite peut faciliter certaines stratégies de confidentialité, de gouvernance des données ou de souveraineté numérique.

Elle ne garantit pas automatiquement la conformité :

- au RGPD ;
- à l'AI Act ;
- à une politique SSI ;
- à une norme ISO ;
- à une exigence contractuelle ou réglementaire.

La conformité dépend du système complet, de son usage, des données traitées et de l'organisation responsable.

---

## Licence

Le code et les éléments couverts par la licence de ce dépôt sont distribués sous :

**GNU General Public License v2.0 only (`GPL-2.0-only`)**

Voir [`LICENSE`](LICENSE).

Les dépendances et modèles tiers restent soumis à leurs propres licences.

---

## Contact

Pour toute question ou vulnérabilité concernant directement Kali-Lite :

**kalicorp@proton.me**

---

**Kalicorp — Le Sanctuaire numérique européen**  
Copyright © 2026 Kalicorp
