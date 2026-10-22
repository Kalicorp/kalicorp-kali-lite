# Kalicorp — Hydrangea Research Workbench (prototype R&D v0.1)

**Atelier local branchable à une IA, pas traitement anticancéreux ni résultat
expérimental.** Le travail scientifique est séparé des réponses de modèle.

## Ce qui fonctionne

1. **Dossiers de sources** : import JSONL explicite, URL et identifiant uniques,
   limites de taille, empreinte SHA256 pour la traçabilité.
2. **IA interchangeable** : appel à une API locale compatible OpenAI
   (Ollama, vLLM, etc.) sans dépendance Python externe.
3. **Rapports contrôlés** : JSON normalisé, références vérifiées contre le
   dossier, statuts `DOCUMENTE` / `HYPOTHESE` / `INCONNU`,
   manifestes d'exécution et revue humaine obligatoire.
4. **Données d'essais** : contrôle CSV séparé ; refuse une baseline entraînée
   uniquement sur des molécules dites actives.
5. **Baseline ML optionnelle** : empreintes Morgan ECFP4 / Random Forest et
   séparation par squelette Murcko avec métriques hors entraînement.
   Ce résultat est EXPLORATOIRE, jamais une validation thérapeutique.
6. **Tests CI** : tests hors ligne sans secrets, sans modèle, sans données privées.

## Audit des fichiers historiques Kali-Lite (22 octobre 2026)

Les quatre pièces d'origine ont été récupérées, archivées sous
[`evidence/kali-lite-20261022/`](evidence/kali-lite-20261022/README.md)
et figées par SHA256.

**Conclusion contrôlée :** le JSON ne fournit aucune clé `bioactivité` ;
la règle des labels de `train_classifier.py` donne `[0, 0, 0]`,
ce qui explique un 100 % trivial pour l'arbre à feuille `label: 0`.
Les fonctions originelles d'extraction et d'entraînement échouent en test
isolé ; l'archive ne constitue **pas** un jeu de données scientifique.

Voir le [rapport de preuve exécutable](reports/HYDRANGEA_AUDIT_001_EVIDENCE.md).
Le pipeline actuel `workflow.py` est séparé de ces archives.

## Démarrage (Linux, depuis le dépôt)

```bash
cd projects/hydrangea-research
python3 -m unittest discover -s tests -v

# Fichier de démonstration : architecture uniquement, AUCUNE donnée biologique
python3 workflow.py validate --sources examples/sources.demo.jsonl

# Vérifier le prompt sans appeler le modèle (fonctionne hors ligne)
python3 workflow.py run \
  --sources examples/sources.demo.jsonl \
  --question "Quelles garanties le workflow propose-t-il ?" \
  --dry-run --out artifacts/demo
```

## Branche rapide par le terminal

Après avoir constitué un fichier réel `data/sources.jsonl` :

```bash
bash start.sh data/sources.jsonl
```

Le lanceur propose les modèles Ollama installés, demande le nom exact du
modèle et la question, puis écrit un dossier de revue horodaté. Il ne permet
pas de transfert à une API distante.

## Brancher une IA locale (aucun compte externe nécessaire)

Sur le serveur qui peut joindre Ollama :

```bash
export KALI_API_BASE="http://127.0.0.1:11434/v1"
export KALI_MODEL="qwen3:8b"  # remplacer par le vrai nom installé
# Si un serveur exige une clé, définir KALI_API_KEY dans l'environnement.
python3 workflow.py run \
  --sources data/sources.jsonl \
  --question "Quelles observations publiées et quelles incertitudes concernent les glycosides cyanogéniques d'Hydrangea ?" \
  --out artifacts/revue-001
```

Alternative vLLM : définir `KALI_API_BASE=http://127.0.0.1:8000/v1`
et `KALI_MODEL` sur le nom réellement servi. Un endpoint distant ne
fonctionne qu'avec `--allow-remote` ET HTTPS ; il peut transmettre les
extraits au prestataire. Aucune clé ne doit figurer dans Git ou les rapports.

**Attention Docker :** `127.0.0.1` doit viser la machine qui exécute le
script. Dans un conteneur, ce n'est pas automatiquement l'hôte. Faire tourner
le runner sur l'hôte au départ évite toute modification réseau de Kalicorp.

Si le modèle renvoie du texte plutôt que le JSON demandé ou invente une
référence, la réponse est rejetée et conservée dans `rejected.json` pour
diagnostic. Aucun fichier `report.draft.json` n'est alors créé.

## Format d'un dossier de sources

Créer `data/sources.jsonl` : **une ligne JSON par document ou extrait**,
avec des preuves réelles sélectionnées par un humain, par exemple :

```json
{"source_id":"DOC_001","title":"Titre de la publication consultée","url":"https://doi.org/DOI-REEL","excerpt":"Passage recopié et vérifié dans l'article réel."}
```

Cet exemple montre uniquement la **forme** attendue, sans citation scientifique
réelle. Remplacer impérativement les champs avant de lancer une étude.
La présence d'une URL ne prouve pas qu'elle contient réellement l'affirmation :
ouvrir et vérifier la publication avant toute diffusion.

Le workflow **ne récupère pas automatiquement les articles** et ne prétend pas
que les données InPACdb aient été chargées. Le format InPACdb doit être audité
depuis les fichiers bruts avant tout import. Ne pas traiter des valeurs fictives
d'IC50 ou des scores de docking comme des observations.

## Import des mesures expérimentales

Un fichier `data/assays.csv` doit avoir exactement au minimum cet en-tête :

```csv
compound_id,smiles,label,label_rule,target_id,assay_id,endpoint,value,unit,source_url
```

- `label` : `active` ou `inactive` selon une règle définie **à l'avance**.
- `label_rule` : règle de décision documentée (seuil, protocole, organisme).
- `target_id`, `assay_id`, `endpoint`, `value`, `unit` : mesures
  homogènes, sourcées, sans mélange de cibles biologiques.
- `source_url` : référence vérifiable de la mesure.

```bash
python3 assay_pipeline.py audit --input data/assays.csv --out artifacts/audit-001
# Seulement une fois les contrôles, doublons, labels et unités vérifiés :
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-ml.txt
python3 assay_pipeline.py train --input data/assays.csv --out artifacts/ml-001
```

Le gate impose au minimum 50 mesures distinctes, 10 par classe, une cible et
un endpoint/unité uniques, une règle de labellisation et au moins 5 groupes
moléculaires. Il vérifie les SMILES et refuse les doublons de structures.
Le split par scaffold diminue certains risques de fuite, mais **ne remplace
pas une validation externe indépendante, la reproductibilité des essais,
l'analyse des biais ni une validation préclinique**. Pas de docking opérationnel
ni de prédiction d'IC50 fournis dans cette version.

**Ne chargez jamais des fichiers `.joblib` inconnus :** ils peuvent exécuter
du code lors de la désérialisation. Les sorties `artifacts/` et données
`data/` sont ignorées par Git.

## Contrat de qualité

- **OBSERVÉ** : résultats instrumentaux ou expérimentaux originaux vérifiés.
- **DOCUMENTÉ** : affirmation reliée à une publication que le relecteur a ouverte.
- **HYPOTHÈSE** : proposition non démontrée, jamais présentée comme un fait.
- **INCONNU** : information absente ou insuffisante.
- **GÉNÉRÉ PAR IA** : brouillon, non validé, avec références à vérifier.

La revue humaine, la toxicologie et l'évaluation réglementaire sont
obligatoires avant toute décision scientifique ou communication publique.
Les composés cyanogéniques peuvent libérer du cyanure ; aucune ingestion,
extraction domestique ou expérimentation non encadrée n'est proposée.

## Séquence recommandée

`Sources vérifiées` → `Validation JSONL` → `IA locale` →
`Contrôle références` → `Rapport brouillon + manifeste SHA256` →
`Vérification humaine` → `Décision sur les prochains travaux`.

En parallèle, les données d'essais suivent une chaîne indépendante :
`CSV sourcé` → `Audit des classes et unités` → `RDKit` →
`Baseline ML facultative` → `Revue scientifique`.

Tout nouveau développement passe par une branche et une pull request.
Voir [AGENTS.md](AGENTS.md) pour connecter un agent et lui donner une mission.
