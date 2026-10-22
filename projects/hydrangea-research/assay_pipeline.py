#!/usr/bin/env python3
"""Optional molecular ML gate. Refuses to fit on a positives-only dataset."""
from __future__ import annotations

import argparse
from collections import Counter
import csv
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import sys
from urllib.parse import urlparse

FIELDS = ("compound_id", "smiles", "label", "label_rule", "target_id",
          "assay_id", "endpoint", "value", "unit", "source_url")


class AssayError(Exception):
    pass


def read_assays(path: Path) -> list[dict]:
    if not path.is_file():
        raise AssayError("Fichier expérimental introuvable")
    with path.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames or any(field not in reader.fieldnames for field in FIELDS):
            raise AssayError("Colonnes manquantes : " + ", ".join(FIELDS))
        rows = []
        for i, row in enumerate(reader, 2):
            if any(not (row.get(field) or "").strip() for field in FIELDS):
                raise AssayError(f"Ligne {i} : valeur ou justification manquante")
            row = {k: row[k].strip() for k in FIELDS}
            if row["label"] not in ("active", "inactive"):
                raise AssayError(f"Ligne {i} : label doit être active/inactive")
            u = urlparse(row["source_url"])
            if u.scheme not in ("https", "http") or not u.netloc:
                raise AssayError(f"Ligne {i} : source_url invalide")
            try:
                value = float(row["value"])
                if not (0 <= value < float("inf")):
                    raise ValueError()
            except ValueError:
                raise AssayError(f"Ligne {i} : mesure numérique non négative requise")
            rows.append(row)
    if not rows:
        raise AssayError("Aucune mesure : entraînement interdit")
    return rows


def audit(rows: list[dict]) -> dict:
    groups = {(r["target_id"], r["endpoint"], r["unit"]) for r in rows}
    labels = Counter(r["label"] for r in rows)
    ids = [r["compound_id"] for r in rows]
    issues = []
    if len(groups) != 1:
        issues.append("Mélange de cibles, endpoints ou unités : constituer un jeu homogène")
    if len(ids) != len(set(ids)):
        issues.append("compound_id dupliqués : agréger les mesures selon un protocole documenté")
    if len(rows) < 50:
        issues.append("Moins de 50 observations : baseline exploratoire désactivée")
    if min(labels.get("active", 0), labels.get("inactive", 0)) < 10:
        issues.append("Minimum 10 observations par classe requis (positifs ET négatifs)")
    if any(len(r["label_rule"]) < 10 for r in rows):
        issues.append("Justification du label trop courte, préciser la règle et les seuils")
    return {"rows": len(rows), "label_counts": dict(labels),
            "target_endpoint_units": [list(g) for g in sorted(groups)],
            "training_gate": "PASS" if not issues else "BLOCKED",
            "issues": issues, "notes": [
                "Les labels et mesures sont déclarés par le fournisseur du CSV, pas vérifiés par ce script",
                "Une étape de contrôle chimique RDKit et de fuite de structure est nécessaire",
                "Aucun résultat de ce pipeline n'est une preuve d'efficacité clinique"]}


def train(rows: list[dict], output: Path) -> dict:
    summary = audit(rows)
    if summary["training_gate"] != "PASS":
        raise AssayError("Entraînement bloqué : " + " ; ".join(summary["issues"]))
    try:
        import joblib
        import numpy as np
        import sklearn
        from rdkit import Chem, rdBase
        from rdkit.Chem import rdFingerprintGenerator
        from rdkit.Chem.Scaffolds import MurckoScaffold
        from sklearn.ensemble import RandomForestClassifier
        from sklearn.metrics import balanced_accuracy_score, confusion_matrix, roc_auc_score
        from sklearn.model_selection import GroupShuffleSplit
    except ImportError as exc:
        raise AssayError("Dépendances ML absentes : pip install -r requirements-ml.txt") from exc

    X, y, scaffolds = [], [], []
    seen = set()
    morgan = rdFingerprintGenerator.GetMorganGenerator(radius=2, fpSize=2048)
    for i, row in enumerate(rows, 2):
        mol = Chem.MolFromSmiles(row["smiles"])
        if mol is None:
            raise AssayError(f"Ligne {i} : SMILES non reconnu par RDKit")
        canonical = Chem.MolToSmiles(mol, isomericSmiles=True)
        if canonical in seen:
            raise AssayError(f"Ligne {i} : molécule identique répétée (risque de fuite)")
        seen.add(canonical)
        scaffold = MurckoScaffold.MurckoScaffoldSmiles(mol=mol)
        # Acyclic molecules have no Murcko scaffold. Unique fallback, not scaffold similarity.
        scaffolds.append(scaffold or "ACYCLIC:" + canonical)
        X.append(list(morgan.GetFingerprint(mol)))
        y.append(1 if row["label"] == "active" else 0)

    if len(set(scaffolds)) < 5:
        raise AssayError("Moins de 5 groupes de structures distincts : évaluation bloquée")
    splitter = GroupShuffleSplit(n_splits=1, test_size=0.25, random_state=42)
    X_array, y_array = np.asarray(X, dtype=np.uint8), np.asarray(y)
    train_idx, test_idx = next(splitter.split(X_array, y_array, groups=scaffolds))
    if len(set(y_array[train_idx])) != 2 or len(set(y_array[test_idx])) != 2:
        raise AssayError("Split par squelette mono-classe : métriques trompeuses, arrêt")
    model = RandomForestClassifier(n_estimators=300, random_state=42,
                                   class_weight="balanced", n_jobs=-1)
    model.fit(X_array[train_idx], y_array[train_idx])
    pred = model.predict(X_array[test_idx])
    probabilities = model.predict_proba(X_array[test_idx])[:, 1]
    metrics = {
        "status": "EXPLORATORY_NON_CLINICAL", "n_train": len(train_idx),
        "n_test": len(test_idx), "n_scaffold_groups": len(set(scaffolds)),
        "split": "GroupShuffleSplit by Murcko scaffold, seed=42, 25% holdout",
        "balanced_accuracy": float(balanced_accuracy_score(y_array[test_idx], pred)),
        "roc_auc": float(roc_auc_score(y_array[test_idx], probabilities)),
        "confusion_matrix_labels_0_inactive_1_active":
            confusion_matrix(y_array[test_idx], pred, labels=[0, 1]).tolist(),
        "rdkit_version": rdBase.rdkitVersion, "sklearn_version": sklearn.__version__,
        "warning": "Prédiction exploratoire, non validée prospectivement et non clinique"
    }
    output.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, output / "model.joblib")
    return metrics


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Audit de mesures et baseline exploratoire RDKit")
    parser.add_argument("command", choices=("audit", "train"))
    parser.add_argument("--input", required=True)
    parser.add_argument("--out", default="artifacts/hydrangea-ml")
    args = parser.parse_args(argv)
    path, output = Path(args.input), Path(args.out)
    try:
        rows = read_assays(path)
        report = audit(rows)
        report["dataset_sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
        report["created_utc"] = datetime.now(timezone.utc).isoformat()
        if args.command == "train":
            metrics = train(rows, output)
            report["metrics"] = metrics
            report["training_status"] = "COMPLETED_NOT_VALIDATED"
        output.mkdir(parents=True, exist_ok=True)
        (output / "assay_audit.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Audit : {report['training_gate']} ; {report['rows']} lignes")
        if report["issues"]:
            print("Blocages : " + " ; ".join(report["issues"]))
            return 2 if args.command == "train" else 0
        return 0
    except AssayError as exc:
        print(f"ERREUR : {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
