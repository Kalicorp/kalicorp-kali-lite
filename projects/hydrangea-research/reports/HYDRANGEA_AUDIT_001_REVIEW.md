# Hydrangea Audit 001 — revue indépendante du compte rendu Kali-Lite

**Date de revue :** 22 octobre 2026  
**État :** NON VALIDÉ — audit documentaire partiel du compte rendu, sans accès aux fichiers scientifiques originaux.  
**Référence :** Kalicorp/kalicorp-kali-lite PR #23, tickets #24 à #27.  
**Source examinée :** texte intégral fourni à Tina sous la pièce jointe `Texte collé(20261022-060139).txt`.  
**SHA256 de cette pièce jointe, et d'elle seule :** `3f1f2e74816bbb92b28e45650972b536c0e11449fca6ec8a8f4f8ca9a01b609e`.  
**Taille de la pièce jointe :** 17 522 octets. Cette empreinte ne prouve pas l'intégrité des fichiers d'origine dans le volume MCP.

> **Attention :** cette note évalue les **affirmations d'un rapport d'agent**. Les fichiers
> `inpacdb_clean.json`, `decision_tree_model.json`, `train_classifier.py`,
> `extractor_simple.py` et le rapport original `HYDRANGEA_AUDIT_001.md`
> ne sont pas présents aux chemins indiqués dans la branche de cette PR.
> Aucun contrôle d'octets ni exécution des scripts d'origine n'a été possible.

## 1. Identités chimiques : rectifications documentées

| Substance | PubChem CID | Formule | Masse molaire indicative | État |
|---|---:|---|---:|---|
| **(R)-Amygdaline** | **656516** | **C20H27NO11** | **457,4 g/mol** | Donnée de référence PubChem |
| **(R)-Prunasine** | **119033** | **C14H17NO6** | **295,29 g/mol** | Donnée de référence PubChem |
| **Dhurrine** | **161355** | **C14H17NO7** | **311,29 g/mol** | Donnée de référence PubChem |
| **Laétrile** | **5484354** | **C14H15NO7** | **309,27 g/mol** | Substance distincte, souvent confondue avec l'amygdaline |

Sources officielles :
- https://pubchem.ncbi.nlm.nih.gov/compound/656516
- https://pubchem.ncbi.nlm.nih.gov/compound/119033
- https://pubchem.ncbi.nlm.nih.gov/compound/161355
- https://pubchem.ncbi.nlm.nih.gov/compound/5484354

**Rectification critique :** le rapport reçu attribue à l'amygdaline le CID 5484354,
la formule C14H15NO7, la masse 309,27 g/mol et un SMILES qui correspond au **laétrile**.
Les « corrections CID appliquées » rapportées par Kali-Lite n'apparaissent **pas**
dans le texte livré. Pour l'amygdaline, il manque un fragment glucosidique
entier, pas seulement une imprécision de masse.

**À ne pas mélanger :** formule brute, SMILES (sensible à la stéréochimie),
structure PDB/SDF et identifiant PubChem sont des objets distincts. Les
formules déclarées `C15H12O4N4` / `C14H10O4N2` dans le rapport
ne sont pas des SMILES exploitables. Il reste à constater ces valeurs dans
les fichiers source originaux.

## 2. IC50 : classement interdit en l'état

| Composé | IC50 annoncée | Source primaire et protocole | Statut |
|---|---:|---|---|
| Amygdaline | 15,2 µM | Non fournis | **NON VÉRIFIÉE** |
| Dhurrine | 22,1 µM | Non fournis | **NON VÉRIFIÉE** |
| Prunasine | 28,5 µM | Non fournis | **NON VÉRIFIÉE** |

- Une IC50 n'a de sens que par rapport à une méthode, un essai, une cible,
  un système biologique, une publication et ses conditions expérimentales.
- Les listes « p53 », « BCL-2 », « EGFR » du rapport ne prouvent pas
  une liaison, une inhibition ou une activité mesurée pour ces molécules.
- Le champ `source_inpacdb: true` est une **déclaration dans un jeu local**,
  et ne prouve pas qu'une entrée est présente dans les fichiers InPACdb.
- Les valeurs 15,2 / 22,1 / 28,5 **ne doivent pas être importées**
  comme observations ou utilisées comme vérités terrain.
- L'hypothèse « proviennent probablement du RAR InPACdb » n'a pas de preuve
  dans le rapport.
- Les affirmations sur le nombre d'articles PubMed et l'absence dans
  ChEMBL ne sont pas vérifiées : un 404 d'API ne prouve pas qu'un composé
  n'est pas indexé (PubChem associe un ChEMBL ID à la prunasine, par exemple).

Documentation : https://pmc.ncbi.nlm.nih.gov/articles/PMC2823384/
(étudier la licence des données avant reprise, et non seulement l'article).

## 3. Modèle et statistiques : incohérences explicites

Le compte rendu fournit un extrait de `decision_tree_model.json` :

```json
{
  "tree": {"leaf": true, "label": 0},
  "accuracy": 1.0,
  "features_names": ["poids_moleculaire", "longueur_formule", "oxygene", "azote", "soufre", "nb_cibles", "ic50"]
}
```

- **Contradiction conditionnelle** : le rapport affirme aussi que les trois
  labels sont `1`. Si cet arbre à feuille unique prédit `0` partout
  et est évalué sur ces trois labels `1`, son accuracy est **0 %**, pas 100 %.
  Il faut des prédictions, des vraies étiquettes et des logs pour trancher.
- **LOOCV ≠ `train_test_split(test_size=0.2)`**. Avec trois échantillons,
  un split 20 % réserve un élément, mais il n'effectue pas automatiquement
  trois plis d'évaluation leave-one-out.
- **Le leave-one-out ne garantit jamais 100 %**. Il peut être évalué sur 3 plis,
  mais n'en garantit pas le résultat.
- **Jeu mono-classe** : impossible de démontrer une discrimination
  active/inactive sans contre-exemples.
- **Fuite potentielle** : `ic50` figure parmi les features. Si le label
  découle de la bioactivité/IC50, l'évaluation n'est pas indépendante.
- **RandomForest vs arbre JSON** : le rapport évoque des scripts scikit-learn
  (`RandomForestClassifier` et `StandardScaler`) mais le JSON présenté
  contient une seule feuille. Aucune relation démontrée entre ces artefacts.
- **Features aléatoires** : l'emploi de `random.randint()` sans seed est
  **rapporté**, non confirmé par lecture du code source original ; il
  nécessite inspection du script et des étapes de sauvegarde.
- **Incohérence interne sur la masse** : le rapport juxtapose une fonction
  retournant 43,02 pour tous et des bornes 270,23 à 312,27 ; provenance de
  ces nombres et version exécutée inconnues.

Références méthodologiques :
- https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.LeaveOneOut.html
- https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.train_test_split.html

## 4. Contrôles de traçabilité effectués

- **OBSERVÉ** : texte du compte rendu transmis en pièce jointe dans
  la conversation, empreinte SHA256 calculée sur ce **fichier transmis**.
- **OBSERVÉ** : la version transmise du rapport contient les contradictions
  ci-dessus et **n'inclut pas le code intégral** de `train_classifier.py`
  ou les trois fichiers JSON complets.
- **OBSERVÉ sur GitHub (au moment de cette revue)** : les 4 chemins
  `projects/hydrangea-anticancer/...` attendus n'existent pas dans
  la branche `feat/hydrangea-research-workflow-20261022`.
- **DOCUMENTÉ** : les identifiants/formules/masses PubChem ci-dessus.
- **INCONNU** : octets du véritable volume MCP, chemins physiques réels,
  empreintes des 4 fichiers originaux, commande et journaux du modèle,
  licence/format des données brutes, présence de ces 3 composés dans
  l'archive originale.
- **BLOQUANT** : aucune référence primaire pour les 3 IC50, aucune
  validation d'un jeu d'essais négatifs, aucune preuve indépendante de
  la précision annoncée.

## 5. Définition de « audit terminé »

**Ne pas marquer la mission complète** tant que ces points ne sont pas réunis :

- [ ] Copier/exporter effectivement le rapport original et le code original
      dans un canal commun vérifiable, sans altérer les artefacts sources.
- [ ] Obtenir les 3 JSON/scripts *complets* avec empreintes calculées sur les
      octets transmis, et les valeurs de labels/predictions fold par fold.
- [ ] Remplacer la référence d'amygdaline/laétrile, vérifier les SMILES
      stéréochimiques avec une source reconnue et une validation RDKit.
- [ ] Vérifier l'archive InPACdb originale, provenance des champs et droits.
- [ ] Rechercher les publications primaires relatives aux valeurs IC50 ;
      autrement les marquer `NON VÉRIFIÉES` sans entraînement.
- [ ] Avant tout ML : obtenir une cohorte structurée, contrôles négatifs,
      protocole commun et révision scientifique humaine.

**Décision actuelle :** code d'atelier documentaire utilisable sous contrôle ;
pipeline de découverte anticancéreuse **non validé** ; ne pas lancer de conception
de protéine ni communiquer une efficacité supposée sur la base de ces chiffres.
