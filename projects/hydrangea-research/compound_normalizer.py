#!/usr/bin/env python3
"""Research-grade input gating for compound identity; NOT an anticancer predictor.

JSONL in -> provenance-preserving structural descriptors out.
Source URLs are *declarations*, not automatically authenticated publications.
No network calls, automatic biological labels or fabricated measurements.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import sys
from urllib.parse import urlparse

REQUIRED = ("compound_id", "name", "smiles", "source_url", "source_record_id")
FORBIDDEN = {
    "ic50", "ic50_estimee", "bioactivité", "bioactivity", "activity", "label",
    "cibles_cancéreuses", "targets", "response", "potency", "efficacy",
}
ID_PATTERN = re.compile(r"^[A-Za-z0-9_.-]{1,100}$")


class InputError(Exception):
    pass


def load_manifest(path: Path) -> tuple[list[dict], str]:
    if not path.is_file():
        raise InputError(f"Fichier manquant : {path}")
    raw_bytes = path.read_bytes()
    if len(raw_bytes) > 10_000_000:
        raise InputError("Fichier supérieur à 10 Mo")
    try:
        text = raw_bytes.decode("utf-8-sig")
    except UnicodeError as exc:
        raise InputError("JSONL doit être UTF-8") from exc
    rows, ids = [], set()
    for lineno, line in enumerate(text.splitlines(), 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            raise InputError(f"Ligne {lineno}: JSON invalide") from exc
        if not isinstance(row, dict):
            raise InputError(f"Ligne {lineno}: objet JSON requis")
        bad = FORBIDDEN.intersection(row.keys())
        if bad:
            raise InputError(f"Ligne {lineno}: champ biomédical non sourcé interdit : {sorted(bad)}")
        for key in REQUIRED:
            if not isinstance(row.get(key), str) or not row[key].strip():
                raise InputError(f"Ligne {lineno}: champ obligatoire {key}")
            if len(row[key]) > 10_000:
                raise InputError(f"Ligne {lineno}: champ excessivement long : {key}")
        cid = row["compound_id"]
        if not ID_PATTERN.fullmatch(cid) or cid in ids:
            raise InputError(f"Ligne {lineno}: identifiant invalide/doublon")
        ids.add(cid)
        u = urlparse(row["source_url"])
        if u.scheme != "https" or not u.hostname or u.username or u.password:
            raise InputError(f"Ligne {lineno}: source_url HTTPS sans identifiant requise")
        if "pubchem_cid" in row and (
            type(row["pubchem_cid"]) is not int or row["pubchem_cid"] <= 0
        ):
            raise InputError(f"Ligne {lineno}: pubchem_cid entier positif attendu")
        rows.append(row)
    if not rows:
        raise InputError("Aucune entrée; résultat vide interdit")
    return rows, hashlib.sha256(raw_bytes).hexdigest()


def normalize(rows: list[dict]) -> list[dict]:
    try:
        from rdkit import Chem, rdBase
        from rdkit.Chem import Descriptors, rdMolDescriptors
    except ImportError as exc:
        raise InputError("RDKit absent : installer l'option de validation chimique") from exc
    out, seen_smiles = [], set()
    for row in rows:
        source_id = row["compound_id"]
        mol = Chem.MolFromSmiles(row["smiles"])
        if mol is None:
            raise InputError(f"{source_id}: SMILES invalide (formule brute != SMILES)")
        canonical = Chem.MolToSmiles(mol, isomericSmiles=True)
        if canonical in seen_smiles:
            raise InputError(f"{source_id}: même structure qu'une autre ligne (doublon)")
        seen_smiles.add(canonical)
        out.append({
            "compound_id": source_id,
            "declared_name": row["name"].strip(),
            "canonical_isomeric_smiles": canonical,
            "molecular_formula_computed": rdMolDescriptors.CalcMolFormula(mol),
            "molecular_weight_computed": round(float(Descriptors.MolWt(mol)), 4),
            "pubchem_cid_declared": row.get("pubchem_cid"),
            "provenance": {
                "source_url_declared": row["source_url"],
                "source_record_id_declared": row["source_record_id"],
                "verification": "NOT_INDEPENDENTLY_VERIFIED",
            },
            "activity_status": "NOT_EVALUATED",
            "rdkit_version": rdBase.rdkitVersion,
        })
    return out


def write_outputs(path: Path, source: Path, digest: str, records: list[dict]) -> None:
    if path.exists() and any(path.iterdir()):
        raise InputError("Sortie non vide : choisir un nouveau dossier afin de conserver les runs")
    path.mkdir(parents=True, exist_ok=True)
    manifest = {
        "status": "STRUCTURES_COMPUTED_NOT_SCIENTIFICALLY_VERIFIED",
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "input_file": source.name, "input_sha256": digest,
        "compound_count": len(records),
        "limitations": [
            "Structure calculée à partir du SMILES fourni, identité non vérifiée dans PubChem",
            "Références déclaratives non vérifiées automatiquement",
            "Aucune IC50, bioactivité, indication clinique ou efficacité anticancéreuse",
            "Validation humaine de la provenance et de la stéréochimie requise",
        ],
    }
    (path / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (path / "compounds.structure-only.json").write_text(
        json.dumps(records, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Contrôle strict des structures et de la provenance")
    parser.add_argument("command", choices=("validate", "normalize"))
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--out", default="artifacts/structures-001", type=Path)
    args = parser.parse_args(argv)
    try:
        rows, digest = load_manifest(args.input)
        if args.command == "validate":
            print(f"JSONL OK : {len(rows)} entrées ; SHA256 {digest}")
            print("La structure chimique et la provenance restent NON VÉRIFIÉES")
            return 0
        compounds = normalize(rows)
        write_outputs(args.out, args.input, digest, compounds)
        print(f"{len(compounds)} structures calculées, activité NON ÉVALUÉE : {args.out}")
        return 0
    except (InputError, OSError) as exc:
        print(f"BLOQUÉ : {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
