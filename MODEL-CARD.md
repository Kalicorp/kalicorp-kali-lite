# Model Card — Kali-Lite

> **Kalicorp — Le Sanctuaire numérique européen**  
> Version documentaire : 2.1.0 | Mise à jour : 2026-07-21 | Licence : GPL-2.0

---

## Résumé

Kali-Lite est une famille d'Anima locales et frugales conçues pour fonctionner sur du matériel accessible, sans télémétrie et sans dépendance à un service cloud après installation.

Kali-Lite n'est pas un modèle entraîné intégralement par Kalicorp. La famille assemble un modèle de base compatible, une doctrine explicite, une spécialité optionnelle et un harnais d'exécution. Cette architecture rend le comportement lisible, personnalisable et remplaçable.

| Propriété | Kali-Lite | Kali-Lite v2 |
|---|---|---|
| **Base actuelle** | Qwen3 8B | Qwen3.5 9B Vision |
| **Mémoire vidéo indicative** | ~8 Go | ~10 Go |
| **Vision** | Non | Oui |
| **Taille indicative** | ~5,2 Go | ~6,8 Go |
| **Runtime principal** | Ollama | Ollama |
| **Usage dominant** | code, chat, système | vision, code, chat |
| **Contexte configuré** | selon le Modelfile livré | selon le Modelfile livré |

Les besoins réels varient selon la quantification, le système d'exploitation, le contexte chargé, le nombre d'outils et les autres applications ouvertes.

---

## Intention

Kali-Lite vise à fournir une continuité de travail lorsque l'accès réseau, un quota distant, une politique de fournisseur ou un coût d'usage empêche de poursuivre normalement un projet.

Elle est conçue pour :

- travailler localement avec les ressources réellement disponibles ;
- annoncer clairement ses limites ;
- distinguer faits, hypothèses, actions et résultats ;
- ne jamais simuler l'exécution d'un outil ;
- aider l'utilisateur à devenir plus autonome ;
- permettre une personnalisation rapide sans rendre le système opaque ;
- orienter vers une infrastructure plus puissante lorsque la tâche dépasse raisonnablement la machine locale.

---

## Architecture en quatre couches

### 1. Modèle de base

Le moteur de génération choisi selon le matériel, la licence, la langue et le besoin fonctionnel.

### 2. Doctrine Kali-Lite

Le socle commun : sobriété, honnêteté opérationnelle, respect de l'utilisateur, lisibilité, continuité et absence de télémétrie ajoutée par Kalicorp.

### 3. Spécialité

Une orientation facultative : développement, pédagogie, vision, cyberdéfense, accessibilité ou autre domaine défini par l'opérateur.

### 4. Harnais d'exécution

L'environnement qui relie l'Anima aux outils : Ollama,, Hermes, OpenCLI, vLLM, MCP ou une intégration locale équivalente.

Voir [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## Utilisations prévues

- assistance au développement et revue de code ;
- assistance système locale ;
- formation à l'IA locale et à ses contraintes physiques ;
- analyse d'images avec une variante compatible ;
- prototypage d'Anima personnalisées ;
- continuité de travail hors connexion ;
- traitements locaux lorsque la confidentialité ou la souveraineté l'exige.

## Utilisations non prévues

- attaques contre des systèmes tiers ;
- décisions médicales, juridiques ou financières sans validation humaine qualifiée ;
- traitement de données sans base légale, autorisation ou gouvernance adaptée ;
- promesse de conformité automatique par le seul fait d'une exécution locale ;
- remplacement d'une infrastructure plus puissante lorsque la tâche excède les capacités du poste.

---

## Personnalisation

Kali-Lite est personnalisée principalement par configuration et prompt système, pas par fine-tuning des poids du modèle.

Le gabarit [`templates/anima.template.md`](templates/anima.template.md) aide à renseigner :

- le nom et le rôle de l'Anima ;
- son périmètre ;
- ses limites ;
- ses outils ;
- son style d'interaction ;
- ses critères d'escalade ;
- les éléments de continuité conservés par le harnais.

Cette personnalisation ne garantit pas à elle seule un comportement parfait. Elle doit être testée avec des cas réels, des échecs connus et des limites matérielles représentatives.

---

## Continuité et apprentissage

Kali-Lite peut conserver une continuité si le harnais utilisé fournit une mémoire locale, un journal de projet, un fichier `anima.md` ou un mécanisme équivalent.

Cette continuité ne modifie pas automatiquement les poids du modèle. Elle correspond à une mémoire externe gouvernée par l'opérateur. Toute affirmation selon laquelle l'Anima « apprend » doit préciser ce qui est réellement conservé, où, par qui et avec quelle possibilité de suppression.

---

## Limites connues

- les performances dépendent fortement du matériel et de la quantification ;
- une exécution CPU peut être nettement plus lente ;
- les longs contextes augmentent la consommation de mémoire et la latence ;
- les petits modèles peuvent manquer des nuances, oublier des contraintes ou produire des erreurs plausibles ;
- la qualité des appels d'outils dépend du modèle, du template et du harnais ;
- le fonctionnement local ne rend pas automatiquement un usage conforme au RGPD ou à l'AI Act ;
- aucune mémoire durable n'existe sans composant externe prévu à cet effet ;
- aucune variante ne doit prétendre avoir exécuté une action sans preuve fournie par l'outil.

---

## Sécurité et vie privée

| Aspect | Position du projet |
|---|---|
| Télémétrie ajoutée par Kali-Lite | Aucune |
| Exécution principale | Locale |
| Données envoyées par Kalicorp | Aucune par défaut |
| Clés API requises | Aucune pour l'usage Ollama local |
| Connexion après installation | Non requise pour le modèle déjà installé |
| Conformité | Facilitée par le local, jamais garantie automatiquement |

Les installateurs peuvent télécharger Ollama, des dépendances ou les poids du modèle. L'utilisateur doit lire les scripts, vérifier les empreintes publiées et examiner les politiques des dépendances qu'il choisit.

---

## Gouvernance humaine

L'opérateur reste responsable :

- des données fournies ;
- des outils autorisés ;
- des actions exécutées ;
- des décisions prises à partir des réponses ;
- de la conservation ou suppression des mémoires ;
- de la conformité au contexte d'usage.

Kali-Lite doit pouvoir recommander une validation humaine ou une infrastructure différente lorsque son niveau de confiance, son contexte ou ses ressources sont insuffisants.

---

## Licence

**GPL-2.0** — voir [`LICENSE`](LICENSE).

## Métadonnées

```yaml
license: gpl-2.0
framework:
  - ollama
base_models:
  - qwen3:8b
  - qwen3.5:9b
customized_by: Kalicorp
architecture:
  - base-model
  - doctrine
  - specialty
  - execution-harness
tags:
  - kali-lite
  - ia-frugale
  - ia-souveraine
  - local-llm
  - ollama
  - autonomie
  - privacy
```
