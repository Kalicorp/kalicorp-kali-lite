# Hydrangea Audit 001 — vérification directe des quatre pièces originales

**Date :** 22 octobre 2026  
**Statut :** AUDIT INFORMATIQUE EFFECTUÉ SUR FICHIERS REÇUS ; **VALIDATION SCIENTIFIQUE NON ACQUISE**.  
**Référence :** PR #23, audit initial de Kali-Lite, analyse indépendante Tina.

## 0. Provenance et intégrité

Quatre fichiers ont été transmis dans la conversation puis archivés **sans modifier leur contenu** sous `evidence/kali-lite-20261022/` (chemin relatif au projet `projects/hydrangea-research/`). L'identité du contenu a été vérifiée à la relecture depuis GitHub.

| Fichier reçu | Taille en octets | SHA256 des octets transmis |
|---|---:|---|
| `decision_tree_model.json` | 430 | `0b7c797c346aab65552cbe35189bb39cd0412653a8d770f39b5cd970ebf62aeb` |
| `extractor_simple.py` | 4 724 | `8da55a3195d8804964c4b4b5261cf5096d6446c4e641ad8ac7901220ec84bffe` |
| `inpacdb_clean.json` | 1 612 | `ecec5ab14741ea559bba58438e0c5e8c9f4f3bbb9965d18730b4bdcf3a56c3a3` |
| `train_classifier.py` | 4 547 | `d9a12948c9ade270e45d867f8516468ba5e4e04be09300872cafb59c8485220f` |

Ces empreintes **ne prouvent pas** que les fichiers sont dérivés de la base InPACdb ni qu'un entraînement antérieur a réussi ; elles prouvent l'identité des quatre pièces fournies.

## 1. Le « 100 % » s'explique par une cible absente

Dans `train_classifier.py`, l'étiquette est déterminée par :

```python
if composé.get("bioactivité", {}).get("type") == "anticancéreux":
    y.append(1)
else:
    y.append(0)
```

Le JSON **ne contient aucune clé `bioactivité`** pour AMP-001, AMP-002 et AMP-003.
L'application directe de cette logique produit `y = [0, 0, 0]`.

Le fichier `decision_tree_model.json` est un arbre à **une seule feuille de valeur `0`** avec un champ `accuracy: 1.0`.

- Si cet arbre prédit 0 pour les trois échantillons, ses trois prédictions concordent
  avec **les labels effectivement calculables à partir du CSV/JSON fourni**.
- Il atteint donc un **100 % trivial pour une classe constante** ; ce n'est
  **ni une reconnaissance de l'activité anticancéreuse, ni une évaluation de généralisation**.
- Ce constat **ne reconstitue pas le run historique** : le code qui a généré
  `decision_tree_model.json` et les logs de validation ne sont pas fournis.
- Notre première hypothèse « les trois labels seraient 1 » est **réfutée par les
  fichiers présents** : ce champ manque ; la règle de `train_classifier.py`
  les assigne à 0.

Le champ `ic50_estimee` figure comme feature du modèle JSON, alors que la
valeur IC50 n'est reliée à **aucune source primaire**. Le conserver comme
descripteur pour prédire une activité potentiellement dérivée de l'IC50 serait
une fuite d'information.

## 2. Exécution contrôlée des fonctions d'origine : erreurs effectivement reproduites

Les scripts `.py` passent la **compilation syntaxique**, mais les chemins
de traitement appelés échouent lors d'un test isolé, sans écriture.

| Code et méthode testés | Résultat effectivement reproduit |
|---|---|
| `SimpleCompoundExtractor.extract_composés()` | `NameError: name 'os' is not defined` |
| `SimpleCompoundExtractor._nettoyer_composé()` | `UnboundLocalError: cannot access local variable 'composés_copia' where it is not associated with a value` |
| `AnticancerClassifier._extract_features(liste_de_3)` | `AttributeError: 'list' object has no attribute 'get'` |
| `AnticancerClassifier.train(liste_de_3)` | `AttributeError: 'list' object has no attribute 'get'` |
| `AnticancerClassifier.extract_ecfp4('C')` | Tableau de **1 024 zéros** : placeholder, pas de fingerprint moléculaire |

### Origines précises des erreurs

- `extractor_simple.py` utilise `os.path.join` sans importer `os`.
  Il utilise aussi `datetime.now()` sans importer `datetime`.
- Dans `_nettoyer_composé`, `composés_copia["nom_scientifique"]` est référencé
  **pendant la création** du dictionnaire `composés_copia`.
- Le code appelle `self._estimer_poids_moleculaire(...)`, mais la fonction
  `_estimer_poids_moleculaire` est déclarée **hors de la classe** et
  n'est pas disponible sous `self`.
- `_estimer_poids_moleculaire` additionne les caractères atomiques une fois
  chacun et **ignore les indices** (`C15` est compté comme `C1`).
- Dans `train_classifier.py`, l'itération `for composé in composés`
  appelle `self._extract_features(composés)` avec **toute la liste** ;
  la méthode attend la liste puis appelle illégalement `composés.get(...)`.
- Même en corrigeant la faute de type, les features tentent d'inclure le
  texte du nom scientifique avec des valeurs numériques : traitement ML
  supplémentaire nécessaire avant passage à `StandardScaler`.
- `source_inpacdb` est forcé à `True` dans l'extracteur. Ce marqueur
  **n'est pas un test de provenance**.
- Le `train_test_split(test_size=0.2, stratify=y)` n'est pas une validation
  leave-one-out. Aucun module montré ne construit le fichier JSON à une
  feuille `decision_tree_model.json`.

## 3. Le fichier « nettoyé » n'est pas traçable à cet extracteur

Le JSON reçu a des clés `structure_moleculaire`, `longueur_formule`,
`poids_moleculaire_estime` et **pas** de clé `bioactivité`, ni
`nombre_atomes_estime`, ni `extraction_date` ni `source_fichier`.

Le script reçu, lui, cherche `mol` à la racine de chaque entrée brute,
reconstruit `bioactivité`, `ic50_estimee`, `longueur_chaine_smiles`,
`nombre_atomes_estime` et ajoute une date et un chemin source.

**Conclusion :** le JSON reçu n'est pas une sortie reproductible de ce
`extractor_simple.py` tel qu'il a été fourni. Une autre version,
un autre script ou une manipulation intermédiaire manque.

## 4. Les molécules existent ; ces entrées ne décrivent pas leurs structures

Les trois lignes mentionnent ces valeurs de champ `mol` (de fait des formules
chimiques, **pas** des SMILES) :

| Nom dans le JSON | `structure_moleculaire.mol` reçu | IC50 fournie | État |
|---|---|---:|---|
| Amygdaline | `C15H12O4N4` | 15,2 µM | Structure non conforme, IC50 non vérifiée |
| Prunasin | `C14H10O4N2` | 28,5 µM | Structure non conforme, IC50 non vérifiée |
| Dhurrin | `C14H10O4N2` | 22,1 µM | Structure non conforme, IC50 non vérifiée |

Références à utiliser **après contrôle explicite de l'isomérie** :
- Amygdaline : PubChem CID 656516, **C20H27NO11** (≈457,4 g/mol)
- Prunasine : CID 119033, **C14H17NO6** (≈295,29 g/mol)
- Dhurrine : CID 161355, **C14H17NO7** (≈311,29 g/mol)
- Laétrile, substance différente : CID 5484354, C14H15NO7 (≈309,27 g/mol)

Sources externes : https://pubchem.ncbi.nlm.nih.gov/compound/656516,
https://pubchem.ncbi.nlm.nih.gov/compound/119033,
https://pubchem.ncbi.nlm.nih.gov/compound/161355,
https://pubchem.ncbi.nlm.nih.gov/compound/5484354.

La base InPACdb originale et l'archive `.rar` n'ont **pas été reçues** :
aucune preuve primaire ne permet d'attribuer les valeurs 15,2 / 22,1 / 28,5
ou les cibles p53/BCL-2/EGFR à cette base. Le statut `source_inpacdb: true`
ne change pas ce constat.

## 5. Validation et décision

### Tests exécutés et observés
- Lecture exacte des fichiers transférés, JSON parseable et `.py`
  syntaxiquement compilables.
- Empreintes calculées depuis les octets reçus.
- Tests ciblés des fonctions d'extraction et d'entraînement sous Python,
  reproduisant les erreurs listées en section 2.
- Calcul des **étiquettes effectivement générées** depuis les 3 entrées :
  `[0,0,0]`.
- Confrontation avec l'arbre constant `label:0` et son score déclaré `1.0`.

### Pas encore réalisé
- Aucun accès à `inpacdb_sample.json` (données brutes).
- Aucun entraînement scientifique valide, fingerprint ECFP4 RDKit ni docking réel.
- Aucune vérification des publications originales liées aux IC50.
- Aucun test sur les vrais serveurs / GPU Kalicorp.
- Aucun contrôle de l'origine historique de l'arbre JSON.

### Décision
**Les quatre fichiers sont maintenant tracés et vérifiables, mais le « pipeline
complet entraîné, reproductible et 100 % précis » annoncé antérieurement
n'est pas démontré ; avec les fichiers reçus, les scripts échouent.**

Prochaine étape : arrêter toute utilisation de ces 3 entrées comme vérité
terrain et reconstituer proprement les données depuis des sources traçables.
Le workflow documentaire `workflow.py` de la PR #23 reste distinct,
opérationnel dans son périmètre de recherche et de génération de brouillons.
