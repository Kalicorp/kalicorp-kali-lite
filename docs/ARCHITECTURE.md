# Architecture de personnalisation

Kali-Lite sépare quatre responsabilités afin d'éviter qu'une personnalité, une spécialité et un harnais technique soient enfermés dans un seul prompt difficile à maintenir.

## 1. Modèle de base

Le modèle fournit les capacités générales de génération, de code, de vision ou d'appel d'outils.

Critères de choix :

- mémoire disponible ;
- vitesse attendue ;
- licence ;
- langue ;
- qualité des appels d'outils ;
- compatibilité avec le runtime.

Le modèle de base doit pouvoir être remplacé sans réécrire toute l'identité.

## 2. Doctrine Kali-Lite

La doctrine définit les invariants :

- ne pas simuler un résultat ;
- annoncer les limites matérielles ou contextuelles ;
- distinguer observation, hypothèse et action ;
- protéger la confidentialité locale ;
- favoriser l'autonomie de l'utilisateur ;
- demander une validation pour les actions sensibles ;
- orienter vers une autre ressource quand la tâche dépasse le poste.

Cette couche doit rester courte, testable et stable.

## 3. Spécialité

La spécialité décrit le métier de l'Anima :

- développement ;
- pédagogie ;
- vision ;
- cyberdéfense ;
- accessibilité ;
- documentation ;
- ou domaine propre à l'utilisateur.

Elle contient le vocabulaire, les méthodes, les limites et les critères de qualité spécifiques au domaine.

Une spécialité ne doit pas contourner la doctrine.

## 4. Harnais d'exécution

Le harnais relie l'Anima aux outils et à la mémoire :

- Ollama ;
- Claude Code ;
- Hermes ;
- OpenCLI ;
- vLLM ;
- MCP ;
- scripts locaux ;
- fichier `anima.md` ;
- journal de projet.

Le harnais est responsable de la preuve d'exécution, des permissions, de la persistance et de l'effacement.

## Ordre de composition recommandé

```text
Doctrine Kali-Lite
+ identité remplie par l'utilisateur
+ spécialité
+ contrat d'outils du harnais
+ contexte de session
```

## Règle de continuité

Une Anima ne doit pas prétendre se souvenir si aucun mécanisme externe ne lui a fourni la mémoire correspondante.

Lorsqu'une mémoire existe, elle devrait préciser :

- ce qui est conservé ;
- où cela est conservé ;
- qui peut le lire ;
- comment le corriger ;
- comment le supprimer.

## Premier démarrage

Le gabarit `templates/anima.template.md` est conçu pour être rempli en moins de trente minutes. Les champs inconnus peuvent rester vides ; l'Anima doit alors les signaler comme non définis plutôt que les inventer.
