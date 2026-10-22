# Hydrangea — ingestion déterministe sans données de santé

Le script `compound_normalizer.py` est un **correctif neuf** de la chaîne de
normalisation, distinct des fichiers historiques `extractor_simple.py` et
`train_classifier.py` archivés comme preuves. Ces originaux restent inchangés.

## Principes de sécurité scientifique

- Aucune revendication d'activité anticancéreuse ou de bénéfice thérapeutique.
- Aucune IC50, cible biologique, classe `active/inactive`, prédiction ni
  mesure absente ne sera inventée.
- Une source déclarée n'est **pas** une source indépendamment vérifiée.
  Le champ `provenance.verification` vaut `NOT_INDEPENDENTLY_VERIFIED`
  tant qu'un humain n'a pas vérifié structure, stéréochimie et publication.
- RDKit calcule des descripteurs **à partir d'un SMILES fourni** et ne
  prouve ni la bonne identité moléculaire ni une propriété biologique.
- **Ne jamais verser un dossier médical ou les données du père d'un utilisateur
  dans un dépôt GitHub public, des journaux CI ou un modèle distant.**

## Exécution locale

```bash
cd projects/hydrangea-research
python3 -m unittest discover -s tests -v
python3 compound_normalizer.py validate --input examples/compound.demo.jsonl

python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install "rdkit>=2024.9,<2027"

python3 compound_normalizer.py normalize \
  --input examples/compound.demo.jsonl \
  --out artifacts/compound-demo-001
```

Ce jeu comporte **uniquement deux petites molécules de démonstration non
anticancéreuses**. Il n'est pas destiné à entraîner un modèle.
Les sorties sont enregistrées dans un nouveau dossier et comprennent :

- `compounds.structure-only.json` : SMILES canonique isomérique, formule
  et masse calculées, identifiants et liens d'origine déclarés, mention explicite
  de la vérification manquante, **sans IC50**.
- `manifest.json` : empreinte SHA256 des octets en entrée, date UTC,
  nombre d'entrées et limites de validité.

Le répertoire `artifacts/` est ignoré par Git.

## Format pour un corpus authentique

Fichier `data/compounds.jsonl` avec **un JSON par ligne** :

```json
{"compound_id":"ID_SOURCE_001","name":"Nom chimique exact","smiles":"SMILES_VERIFIE_AVEC_PUBCHEM_ET_STEREOCHIMIE","source_url":"https://doi.org/DOI_VERIFIE","source_record_id":"REFERENCE_EXACTE"}
```

Le bloc est un **gabarit**, pas une structure prête à analyser. Lors de l'import,
les champs `compound_id`, `name`, `smiles`, `source_url` (HTTPS) et
`source_record_id` sont obligatoires ; `pubchem_cid` est facultatif et
déclaratif. Une formule moléculaire comme `C15H12O4N4` **n'est pas un SMILES**.
L'import échoue sur cette valeur et sur les doublons.

Les valeurs expérimentales et les témoins sont stockés **séparément** et
audités par `assay_pipeline.py` après revue humaine. Ne pas utiliser les
trois anciennes valeurs IC50 : 15,2 / 22,1 / 28,5 µM sont non sourcées.

## Contrat anti-boucle

Si une validation échoue, la commande affiche `BLOQUÉ` et rend le code 2.
L'agent doit enregistrer le message d'erreur, arrêter et ne pas proposer de
changer les valeurs pour obtenir artificiellement un « PASS ».
