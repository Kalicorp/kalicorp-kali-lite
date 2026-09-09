# Model Card — Kali-Lite

> **Kalicorp — Le Sanctuaire numérique européen**  
> Version documentaire : 2.2.0 | Mise à jour : 2026-09-09 | Licence : GPL-2.0-only

---

## Résumé

**Kali-Lite** est une famille d'Animas IA locales et frugales conçues par **Kalicorp** pour fonctionner sur du matériel accessible et permettre à l'opérateur de conserver la maîtrise de son environnement d'inférence.

Kali-Lite n'est pas un modèle entraîné intégralement par Kalicorp.

La famille assemble quatre couches distinctes :

1. un **modèle de base** ;
2. une **doctrine Kali-Lite** ;
3. une **spécialité optionnelle** ;
4. un **harnais d'exécution**.

Cette architecture vise à rendre le système lisible, personnalisable et remplaçable sans imposer la dépendance à un service d'inférence Kalicorp.

**Kali-Lite n'ajoute aucune télémétrie ni mécanisme de tracking utilisateur.**

Lorsque Kali-Lite est utilisée avec Ollama local, l'inférence peut fonctionner sans service cloud Kalicorp une fois les composants nécessaires et le modèle installés.

| Propriété | Kali-Lite | Kali-Lite v2 |
|---|---|---|
| **Base actuelle** | Qwen3 8B | Qwen3.5 9B Vision |
| **Mémoire vidéo indicative** | ~8 Go | ~10 Go |
| **Vision** | Non | Oui |
| **Taille indicative** | ~5,2 Go | ~6,8 Go |
| **Runtime principal** | Ollama | Ollama |
| **Usage dominant** | code, chat, système | vision, code, chat |
| **Contexte configuré** | selon le Modelfile livré | selon le Modelfile livré |

Les besoins réels dépendent notamment de la quantification, du système d'exploitation, de la taille du contexte, du runtime, des outils connectés et des autres applications présentes sur la machine.

Les valeurs de mémoire et de taille indiquées ici sont donc des **ordres de grandeur**, pas des garanties universelles.

---

## Intention

Kali-Lite vise à fournir une capacité de travail locale lorsqu'un accès réseau, un quota distant, un coût d'usage, une politique fournisseur ou une exigence de maîtrise des données rend une solution cloud inadaptée.

Elle est conçue pour :

- travailler localement avec les ressources réellement disponibles ;
- rendre visibles les contraintes matérielles plutôt que les masquer ;
- annoncer clairement ses limites ;
- distinguer faits, hypothèses, actions demandées et résultats obtenus ;
- ne jamais prétendre avoir exécuté un outil sans preuve d'exécution ;
- aider l'utilisateur à conserver la maîtrise de ses données et de son environnement ;
- permettre une personnalisation rapide sans rendre le système opaque ;
- faciliter le remplacement d'une brique technique lorsque cela est pertinent ;
- orienter vers une infrastructure plus puissante lorsque la tâche dépasse raisonnablement les capacités de la machine locale.

Kali-Lite ne promet pas une IA « sans limites ».

Ses limites sont celles du **modèle**, du **runtime**, du **matériel**, du **contexte disponible** et des **outils réellement autorisés** par l'opérateur.

---

## Architecture en quatre couches

### 1. Modèle de base

Le moteur de génération est choisi selon le matériel, la licence, les langues supportées, la capacité recherchée et les besoins fonctionnels.

Les modèles actuellement utilisés ne sont pas entraînés intégralement par Kalicorp.

Le modèle de base est considéré comme une **brique remplaçable** de l'architecture.

### 2. Doctrine Kali-Lite

La doctrine définit les principes communs de comportement de l'Anima :

- sobriété ;
- honnêteté opérationnelle ;
- respect de l'utilisateur ;
- explicitation des limites ;
- distinction entre intention et action réellement exécutée ;
- continuité de travail ;
- maîtrise par l'opérateur ;
- absence de télémétrie ajoutée par Kali-Lite.

### 3. Spécialité

Une spécialité peut être ajoutée sans modifier l'ensemble de l'architecture.

Exemples :

- développement ;
- pédagogie ;
- vision ;
- cyberdéfense ;
- accessibilité ;
- documentation ;
- assistance système ;
- domaine métier défini par l'opérateur.

La spécialité reste une couche de configuration et ne transforme pas automatiquement le modèle de base en expert certifié du domaine concerné.

### 4. Harnais d'exécution

Le harnais relie l'Anima au système réel et éventuellement à ses outils.

Il peut s'appuyer, selon le déploiement, sur des composants tels que :

- Ollama ;
- vLLM ;
- MCP ;
- OpenCLI ;
- Hermes ;
- un terminal local ;
- une interface métier ;
- une mémoire externe ;
- une intégration locale équivalente.

La présence d'un outil dans le harnais ne signifie pas automatiquement que l'Anima dispose de l'autorisation de l'utiliser.

Les permissions restent définies par l'opérateur et par l'environnement d'exécution.

Voir [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## Utilisations prévues

Kali-Lite peut notamment être utilisée pour :

- assistance au développement ;
- analyse et revue de code ;
- assistance système locale ;
- documentation technique ;
- formation à l'IA locale ;
- expérimentation avec des modèles frugaux ;
- analyse d'images avec une variante compatible ;
- prototypage d'Animas personnalisées ;
- continuité de travail hors connexion ;
- traitement local de données ;
- démonstration d'architectures IA maîtrisables ;
- usages où la confidentialité ou la souveraineté de l'infrastructure est recherchée.

---

## Utilisations non prévues

Kali-Lite n'est pas conçue pour :

- mener des attaques contre des systèmes tiers ;
- remplacer un professionnel qualifié pour une décision médicale, juridique ou financière ;
- traiter des données sans base légale, autorisation ou gouvernance adaptée ;
- garantir automatiquement la conformité au RGPD ou à l'AI Act ;
- présenter une sortie probabiliste comme une vérité certaine ;
- prétendre qu'une action a été exécutée lorsqu'aucune preuve outil n'est disponible ;
- remplacer artificiellement une infrastructure plus adaptée lorsque la tâche excède clairement les capacités du poste local.

---

## Personnalisation

Kali-Lite est principalement personnalisée par **configuration**, **prompt système**, **outils** et **harnais d'exécution**, plutôt que par fine-tuning systématique des poids du modèle.

Le gabarit [`templates/anima.template.md`](templates/anima.template.md) permet notamment de définir :

- le nom de l'Anima ;
- son rôle ;
- son périmètre ;
- ses limites ;
- ses outils ;
- ses permissions ;
- son style d'interaction ;
- ses critères d'escalade ;
- les informations de continuité conservées par le harnais.

Cette personnalisation ne garantit pas à elle seule un comportement parfait.

Toute Anima destinée à un usage réel devrait être testée sur :

- des cas nominaux ;
- des cas ambigus ;
- des échecs connus ;
- des entrées contradictoires ;
- des situations où un outil est indisponible ;
- des limites matérielles représentatives du déploiement réel.

---

## Continuité et mémoire

Kali-Lite peut conserver une continuité lorsque le harnais utilisé fournit un mécanisme externe adapté, par exemple :

- mémoire locale ;
- journal de projet ;
- base documentaire ;
- fichier `anima.md` ;
- historique conversationnel ;
- base vectorielle locale ;
- mécanisme équivalent contrôlé par l'opérateur.

Cette continuité **ne modifie pas automatiquement les poids du modèle**.

Il s'agit d'une mémoire ou d'un contexte externe au modèle, gouverné par l'environnement d'exécution.

Toute affirmation selon laquelle une Anima « apprend » devrait donc préciser :

- ce qui est réellement conservé ;
- où l'information est stockée ;
- pendant combien de temps ;
- qui peut y accéder ;
- comment elle peut être modifiée ;
- comment elle peut être supprimée.

---

## Outils et capacité d'action

La capacité de raisonnement d'un modèle et sa capacité d'action sont deux propriétés différentes.

Une Anima peut comprendre correctement une tâche tout en étant incapable de l'exécuter si :

- l'outil nécessaire n'est pas installé ;
- l'outil n'est pas connecté ;
- les permissions sont insuffisantes ;
- le réseau est indisponible ;
- l'environnement d'exécution interdit l'action ;
- une dépendance externe refuse la requête.

Kali-Lite doit distinguer explicitement :

```text
Comprendre une action
        ≠
Avoir l'outil
        ≠
Avoir la permission
        ≠
Avoir réellement exécuté l'action
```

Une action ne doit être présentée comme réussie que lorsqu'une preuve suffisante de son exécution est disponible.

---

## Limites connues

- les performances dépendent fortement du matériel ;
- la quantification influence la mémoire utilisée et la qualité des réponses ;
- une exécution CPU peut être nettement plus lente qu'une exécution accélérée ;
- les longs contextes augmentent la consommation mémoire et la latence ;
- un contexte très long ne garantit pas que toutes les informations seront utilisées correctement ;
- les petits modèles peuvent manquer certaines nuances ;
- ils peuvent oublier des contraintes ;
- ils peuvent produire des informations plausibles mais incorrectes ;
- les performances d'appel d'outils dépendent fortement du modèle, du template et du harnais ;
- la vision dépend des capacités réelles du modèle multimodal utilisé ;
- aucune mémoire durable n'existe sans composant prévu à cet effet ;
- le fonctionnement local ne rend pas automatiquement un usage conforme au RGPD ou à l'AI Act ;
- l'exécution locale ne garantit pas à elle seule l'absence de toute communication réseau des dépendances tierces ;
- aucune variante ne doit prétendre avoir exécuté une action sans preuve fournie par son environnement.

---

## Sécurité et vie privée

| Aspect | Position du projet |
|---|---|
| **Télémétrie ajoutée par Kali-Lite** | Aucune |
| **Tracking utilisateur ajouté par Kali-Lite** | Aucun |
| **Mode d'inférence principal** | Local |
| **Données envoyées à Kalicorp pour l'inférence locale** | Aucune par défaut |
| **Compte Kalicorp requis** | Non pour l'usage Ollama local |
| **Clé API Kalicorp requise** | Non pour l'usage Ollama local |
| **Connexion permanente requise** | Non pour l'inférence avec un modèle déjà installé |
| **Composants tiers** | Oui |
| **Conformité automatique** | Non |

Kali-Lite utilise des composants tiers, notamment des runtimes et modèles qui possèdent leurs propres licences, politiques et comportements techniques.

Les installateurs peuvent nécessiter un accès réseau pour télécharger :

- Ollama ;
- des dépendances système ;
- des modèles ;
- des fichiers du dépôt ;
- d'autres composants explicitement utilisés par le processus d'installation.

L'utilisateur est encouragé à :

1. télécharger les scripts ;
2. vérifier leurs empreintes ;
3. les lire avant exécution ;
4. examiner les dépendances utilisées ;
5. contrôler les communications réseau lorsque le contexte l'exige.

Voir [`SECURITY.md`](SECURITY.md) et [`SHA256SUMS`](SHA256SUMS).

---

## Dépendances et souveraineté

Kali-Lite ne prétend pas supprimer toutes les dépendances logicielles.

Elle s'appuie notamment sur des projets tiers tels que **Qwen** et **Ollama**.

L'objectif est différent : rendre ces dépendances aussi **visibles, locales et remplaçables que raisonnablement possible**.

La souveraineté recherchée par le projet concerne notamment la capacité de l'opérateur à maîtriser :

- l'infrastructure ;
- le stockage ;
- les modèles utilisés ;
- les outils connectés ;
- les permissions ;
- les données ;
- les mises à jour ;
- le remplacement des composants.

Kali-Lite vise donc à **réduire l'enfermement technique**, et non à prétendre qu'aucune dépendance n'existe.

---

## Gouvernance humaine

L'opérateur reste responsable :

- des données fournies à l'Anima ;
- des modèles déployés ;
- des outils autorisés ;
- des permissions accordées ;
- des actions réellement exécutées ;
- des décisions prises à partir des réponses ;
- de la conservation des données ;
- de la suppression des mémoires ;
- des obligations réglementaires applicables à son contexte.

Kali-Lite doit pouvoir recommander :

- une vérification humaine ;
- un autre outil ;
- un modèle plus adapté ;
- une infrastructure plus puissante ;
- ou l'arrêt de l'action,

lorsque son niveau de confiance, son contexte, ses permissions ou ses ressources sont insuffisants.

---

## Reproductibilité

Kali-Lite cherche à rendre son assemblage compréhensible et reproductible.

Les éléments importants du système sont documentés dans le dépôt :

- scripts d'installation ;
- configuration ;
- Modelfile ;
- documentation d'architecture ;
- Model Card ;
- politique de sécurité ;
- empreintes SHA-256 ;
- templates de personnalisation.

Un résultat produit par un LLM n'est toutefois pas nécessairement déterministe.

Deux exécutions utilisant le même modèle et le même prompt peuvent produire des réponses différentes selon les paramètres d'échantillonnage, la version du runtime, le contexte et le matériel.

---

## Licence

Le code et les éléments du projet couverts par la licence du dépôt sont distribués sous :

**GNU General Public License v2.0 only (`GPL-2.0-only`)**

Voir [`LICENSE`](LICENSE).

Les modèles de base et composants tiers restent soumis à leurs **propres licences**.

---

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

inference:
  default: local
  cloud_required: false

telemetry_added_by_kali_lite: false

tags:
  - kali-lite
  - ia-frugale
  - ia-souveraine
  - local-llm
  - ollama
  - autonomie
  - privacy
  - local-ai
  - sovereign-ai
```

---

## Projet

**Kali-Lite — Kalicorp**

Le Sanctuaire numérique européen.

[site.kalicorp.fr](https://site.kalicorp.fr)
