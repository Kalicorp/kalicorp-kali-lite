# Archives brutes Kali-Lite — 22 octobre 2026

**Attention : fichiers conservés exclusivement pour audit informatique.**

Ces quatre fichiers ont été envoyés directement dans une conversation
ChatGPT après l'audit `HYDRANGEA AUDIT 001`. Ils ont été archivés
à l'identique ; leur contenu publié sur cette branche a été relu et
comparé caractère par caractère aux pièces jointes transmises.

- `decision_tree_model.json` : arbre dégénéré à une feuille, accuracy déclarée.
- `extractor_simple.py` : ancien extracteur comportant des erreurs d'exécution.
- `inpacdb_clean.json` : 3 entrées locales aux cibles/IC50 **non sourcées**.
- `train_classifier.py` : ancien classifieur inexécutable sur ces entrées.

**Ce ne sont PAS des résultats biomédicaux validés, un dataset InPACdb
officiel, une implantation ML reproductible, ni des données d'entraînement
pour le laboratoire. Ne PAS réutiliser ces fichiers comme vérités terrain.**

Voir :
- [Audit factuel fondé sur les quatre pièces](../../reports/HYDRANGEA_AUDIT_001_EVIDENCE.md)
- [Revue indépendante du rapport de l'agent](../../reports/HYDRANGEA_AUDIT_001_REVIEW.md)

Les empreintes SHA256 sont conservées dans le rapport et protégées par
`tests/test_legacy_evidence.py`. Le répertoire `data/` de l'atelier
reste séparé et ignoré par Git : aucune importation automatique de ces
archives dans le workflow.
