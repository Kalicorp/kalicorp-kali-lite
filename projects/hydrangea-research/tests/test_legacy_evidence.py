"""Immutable evidence integrity and negative controls (stdlib only).

Archived Kali-Lite files are deliberately NON-SCIENTIFIC test fixtures.
Never load an archived pickle/model or train on the three claimed IC50 values.
"""
from pathlib import Path
import hashlib
import json
import unittest

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / "evidence" / "kali-lite-20261022"

EXPECTED = {
    "decision_tree_model.json": "0b7c797c346aab65552cbe35189bb39cd0412653a8d770f39b5cd970ebf62aeb",
    "extractor_simple.py": "8da55a3195d8804964c4b4b5261cf5096d6446c4e641ad8ac7901220ec84bffe",
    "inpacdb_clean.json": "ecec5ab14741ea559bba58438e0c5e8c9f4f3bbb9965d18730b4bdcf3a56c3a3",
    "train_classifier.py": "d9a12948c9ade270e45d867f8516468ba5e4e04be09300872cafb59c8485220f",
}


class LegacyEvidenceTests(unittest.TestCase):
    def test_original_evidence_unchanged(self):
        for name, expected_hash in EXPECTED.items():
            with self.subTest(file=name):
                self.assertEqual(
                    hashlib.sha256((ARCHIVE / name).read_bytes()).hexdigest(),
                    expected_hash,
                )

    def test_missing_bioactivity_produces_only_zero_labels(self):
        rows = json.loads((ARCHIVE / "inpacdb_clean.json").read_text(encoding="utf-8"))
        labels = [1 if row.get("bioactivité", {}).get("type") == "anticancéreux"
                  else 0 for row in rows]
        self.assertEqual(len(rows), 3)
        self.assertEqual(labels, [0, 0, 0])
        # This is not a valid activity classifier. It is a degenerate example.
        tree = json.loads((ARCHIVE / "decision_tree_model.json").read_text())
        self.assertEqual(tree["tree"], {"leaf": True, "label": 0})
        self.assertEqual(tree["accuracy"], 1.0)

    def test_unusable_molecular_identifiers(self):
        rows = json.loads((ARCHIVE / "inpacdb_clean.json").read_text())
        self.assertEqual(
            rows[1]["structure_moleculaire"]["mol"],
            rows[2]["structure_moleculaire"]["mol"],
        )
        self.assertTrue(all("bioactivité" not in row for row in rows))
        self.assertTrue(all("structure_moleculaire" in row for row in rows))

    def test_source_provenance_not_established(self):
        code = (ARCHIVE / "extractor_simple.py").read_text(encoding="utf-8")
        self.assertIn('"source_inpacdb": True', code)
        self.assertIn("random.randint", code)

    def test_legacy_train_contains_unfixed_errors(self):
        code = (ARCHIVE / "train_classifier.py").read_text(encoding="utf-8")
        self.assertIn("self._extract_features(composés)", code)
        self.assertIn("composés.get(", code)
        self.assertIn("return np.zeros(1024)", code)


if __name__ == "__main__":
    unittest.main()
