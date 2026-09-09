# Architecture de personnalisation — Kali-Lite

Kali-Lite sépare volontairement quatre responsabilités afin d'éviter qu'un modèle, une identité, une spécialité et un harnais technique soient enfermés dans une seule configuration difficile à comprendre ou à maintenir.

```text
Modèle de base
      ↓
Doctrine Kali-Lite
      ↓
Spécialité optionnelle
      ↓
Harnais d'exécution
```

Cette séparation permet de faire évoluer ou remplacer une couche sans devoir reconstruire l'ensemble du système.

---

## 1. Modèle de base

Le modèle fournit les capacités générales de génération.

Selon la variante utilisée, cela peut notamment inclure :

- conversation ;
- code ;
- raisonnement ;
- vision ;
- génération structurée ;
- capacité à produire des appels d'outils lorsque le modèle et le runtime le permettent.

Critères de choix :

- mémoire disponible ;
- VRAM disponible ;
- vitesse attendue ;
- licence ;
- langue ;
- qualité générale ;
- capacité de vision ;
- qualité des appels d'outils ;
- compatibilité avec le runtime ;
- taille du contexte ;
- quantification disponible.

Le modèle de base est considéré comme une **brique remplaçable**.

Changer de modèle ne doit pas obliger à réécrire toute l'identité ou la doctrine de l'Anima.

---

## 2. Doctrine Kali-Lite

La doctrine définit les invariants communs aux Animas Kali-Lite.

Elle vise notamment à :

- ne pas simuler un résultat ;
- ne pas prétendre avoir exécuté une action sans preuve ;
- annoncer les limites matérielles ou contextuelles ;
- distinguer observation, hypothèse, proposition et action ;
- protéger la confidentialité locale ;
- préserver la maîtrise de l'opérateur ;
- demander une validation lorsque le contexte ou l'action l'exige ;
- signaler lorsqu'un outil ou une permission manque ;
- orienter vers une autre ressource lorsque la tâche dépasse raisonnablement les capacités disponibles.

Un principe central est :

```text
Comprendre une action
        ≠
Avoir l'outil
        ≠
Avoir la permission
        ≠
Avoir exécuté l'action
```

Cette couche doit rester :

- courte ;
- compréhensible ;
- testable ;
- relativement stable.

Elle ne doit pas dépendre d'un outil particulier.

---

## 3. Spécialité

La spécialité décrit le domaine de travail de l'Anima.

Exemples :

- développement ;
- pédagogie ;
- vision ;
- cyberdéfense ;
- accessibilité ;
- documentation ;
- assistance système ;
- domaine métier défini par l'opérateur.

Elle peut contenir :

- vocabulaire ;
- méthodes ;
- références ;
- critères de qualité ;
- limites métier ;
- formats de réponse préférés ;
- procédures d'escalade.

Une spécialité ne transforme pas automatiquement le modèle en expert certifié du domaine.

Elle ne doit jamais contourner les invariants définis par la doctrine.

---

## 4. Harnais d'exécution

Le harnais relie l'Anima au monde réel.

Il peut fournir :

- runtime d'inférence ;
- outils ;
- terminal ;
- APIs ;
- mémoire ;
- fichiers ;
- interfaces métier ;
- orchestration ;
- réseau ;
- stockage externe.

Exemples de composants possibles :

- Ollama ;
- vLLM ;
- MCP ;
- Hermes ;
- OpenCLI ;
- terminal local ;
- scripts locaux ;
- interface métier ;
- fichier `anima.md` ;
- journal de projet ;
- mémoire locale ;
- base documentaire ;
- base vectorielle.

Ces composants sont des exemples et ne sont pas tous nécessaires au fonctionnement de Kali-Lite.

### Disponibilité ≠ autorisation

La présence d'un outil dans le harnais ne signifie pas que l'Anima est automatiquement autorisée à l'utiliser.

Les permissions restent définies par :

- l'opérateur ;
- le système d'exploitation ;
- le harnais ;
- les droits du processus ;
- les politiques de sécurité ;
- les confirmations éventuellement requises.

Le harnais est notamment responsable de :

- l'exécution réelle des outils ;
- la remontée des résultats ;
- la preuve d'exécution ;
- les permissions ;
- la persistance ;
- la mémoire externe ;
- la suppression des données ;
- l'accès réseau lorsqu'il existe.

---

## Ordre de composition recommandé

Une Anima peut être construite selon l'ordre suivant :

```text
Doctrine Kali-Lite
        +
Identité définie par l'utilisateur
        +
Spécialité
        +
Contrat d'outils du harnais
        +
Contexte de session
```

Cette composition permet de conserver une distinction claire entre :

```text
ce que l'Anima est
ce qu'elle sait
ce qu'elle peut utiliser
ce qu'elle est autorisée à faire
ce qu'elle a réellement fait
```

---

## Contrat d'outils

Lorsqu'un outil est connecté, le harnais devrait pouvoir préciser :

- son nom ;
- son rôle ;
- les arguments qu'il accepte ;
- les permissions nécessaires ;
- les actions nécessitant une confirmation ;
- les erreurs possibles ;
- la forme de la preuve de réussite.

Une réponse textuelle générée par le modèle ne constitue pas, à elle seule, une preuve d'exécution.

---

## Règle de continuité

Une Anima ne doit pas prétendre se souvenir si aucun mécanisme externe ne lui fournit la mémoire correspondante.

La continuité peut être assurée par exemple avec :

- un fichier local ;
- un journal de projet ;
- un historique ;
- une base documentaire ;
- une base vectorielle ;
- un stockage contrôlé par l'opérateur.

Cette mémoire reste **externe aux poids du modèle**.

Lorsqu'une mémoire existe, l'opérateur devrait pouvoir déterminer :

- ce qui est conservé ;
- où cela est conservé ;
- pendant combien de temps ;
- qui peut le lire ;
- comment le corriger ;
- comment le supprimer.

---

## Remplaçabilité

Une architecture Kali-Lite doit éviter, lorsque cela est raisonnablement possible, qu'une seule dépendance devienne indispensable à toutes les autres couches.

Exemples :

```text
Qwen
  peut être remplacé par un autre modèle compatible

Ollama
  peut être remplacé par un autre runtime

MCP / OpenCLI / scripts
  peuvent être remplacés par un autre harnais

anima.md
  peut être remplacé par un autre mécanisme de continuité
```

L'objectif n'est pas de prétendre qu'aucune dépendance n'existe.

L'objectif est de rendre les dépendances :

- visibles ;
- documentées ;
- compréhensibles ;
- remplaçables lorsque cela est raisonnablement possible.

---

## Premier démarrage

Le gabarit :

[`templates/anima.template.md`](../templates/anima.template.md)

est conçu pour permettre une personnalisation rapide.

Les champs inconnus peuvent rester vides.

L'Anima doit alors les considérer comme **non définis**, plutôt que les inventer.

Le premier échange devrait rechercher uniquement les informations nécessaires pour commencer à travailler correctement.

---

## Principe directeur

Une Anima Kali-Lite n'est pas souveraine uniquement parce que son modèle fonctionne localement.

La maîtrise dépend également de :

```text
l'infrastructure
+
les données
+
les outils
+
les permissions
+
la mémoire
+
la capacité à remplacer les composants
```

Et la règle opérationnelle reste :

> **preuve avant affirmation.**

---

**Kalicorp — Le Sanctuaire numérique européen**  
Copyright © 2026 Kalicorp
