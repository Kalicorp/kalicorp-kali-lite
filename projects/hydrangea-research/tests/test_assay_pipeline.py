"""Data gate tests never use invented pharmacological activities."""
import csv
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
import assay_pipeline as ap


def write_assays(path, labels=("active", "inactive")):
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=ap.FIELDS)
        writer.writeheader()
        for i, label in enumerate(labels):
            writer.writerow({
                "compound_id": "TEST_" + str(i), "smiles": "CCO",
                "label": label, "label_rule": "Synthetic test only",
                "target_id": "TEST_TARGET", "assay_id": "ASSAY_" + str(i),
                "endpoint": "IC50", "value": "10.0", "unit": "uM",
                "source_url": "https://example.org/test"
            })


class AssayGateTests(unittest.TestCase):
    def test_pos_only_is_blocked(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "test.csv"
            write_assays(path, ["active"] * 60)
            report = ap.audit(ap.read_assays(path))
            self.assertEqual(report["training_gate"], "BLOCKED")
            self.assertTrue(any("négatifs" in issue for issue in report["issues"]))

    def test_small_balanced_dataset_is_blocked(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "test.csv"
            write_assays(path)
            self.assertEqual(ap.main(["audit", "--input", str(path),
                                      "--out", str(Path(tmp) / "out")]), 0)
            self.assertEqual(ap.main(["train", "--input", str(path),
                                      "--out", str(Path(tmp) / "out2")]), 2)

    def test_missing_provenance_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "test.csv"
            write_assays(path)
            raw = path.read_text()
            path.write_text(raw.replace("https://example.org/test", ""), encoding="utf-8")
            with self.assertRaises(ap.AssayError):
                ap.read_assays(path)

    def test_mixed_targets_blocked(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "test.csv"
            write_assays(path, ["active"] * 30 + ["inactive"] * 30)
            raw = path.read_text()
            path.write_text(raw.replace("TEST_TARGET", "ALT_TARGET", 1), encoding="utf-8")
            report = ap.audit(ap.read_assays(path))
            self.assertEqual(report["training_gate"], "BLOCKED")
            self.assertTrue(any("Mélange" in issue for issue in report["issues"]))


if __name__ == "__main__":
    unittest.main()
