"""Compound ingestion safety tests: synthetic structures, never real IC50 claims."""
from pathlib import Path
import json
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
import compound_normalizer as cn


def demo(cid="DEMO_1", smiles="CCO"):
    return {
        "compound_id": cid, "name": "Synthetic test molecule",
        "smiles": smiles,
        "source_url": "https://example.org/demo-not-science",
        "source_record_id": "TEST_ENTRY",
    }


def write_input(folder, records):
    path = folder / "records.jsonl"
    path.write_text(
        "".join(json.dumps(x, ensure_ascii=False) + "\n" for x in records),
        encoding="utf-8",
    )
    return path


class StrictProvenanceTests(unittest.TestCase):
    def test_validated_input_is_not_called_verified(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = write_input(Path(tmp), [demo()])
            rows, digest = cn.load_manifest(source)
            self.assertEqual(len(rows), 1)
            self.assertEqual(len(digest), 64)
            self.assertEqual(cn.main(["validate", "--input", str(source)]), 0)

    def test_missing_provenance_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            row = demo()
            del row["source_record_id"]
            with self.assertRaises(cn.InputError):
                cn.load_manifest(write_input(Path(tmp), [row]))

    def test_duplicate_identifier_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(cn.InputError):
                cn.load_manifest(write_input(Path(tmp), [demo(), demo()]))

    def test_unverified_activity_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            row = demo()
            row["ic50_estimee"] = 15.2
            with self.assertRaises(cn.InputError):
                cn.load_manifest(write_input(Path(tmp), [row]))

    def test_bad_cid_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            row = demo()
            row["pubchem_cid"] = "a compound"
            with self.assertRaises(cn.InputError):
                cn.load_manifest(write_input(Path(tmp), [row]))

    def test_legacy_json_array_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "legacy.json"
            path.write_text(json.dumps([{"id": "AMP-001"}]), encoding="utf-8")
            with self.assertRaises(cn.InputError):
                cn.load_manifest(path)

    def test_invalid_formula_rejected_by_rdkit(self):
        try:
            import rdkit
        except ImportError:
            self.skipTest("RDKit optional dependency missing")
        with self.assertRaises(cn.InputError):
            cn.normalize([demo(smiles="C15H12O4N4")])

    def test_normalization_keeps_unverified_status_and_does_not_insert_ic50(self):
        try:
            import rdkit
        except ImportError:
            self.skipTest("RDKit optional dependency missing")
        with tempfile.TemporaryDirectory() as tmp:
            source = write_input(Path(tmp), [demo()])
            out = Path(tmp) / "result"
            self.assertEqual(
                cn.main(["normalize", "--input", str(source), "--out", str(out)]), 0
            )
            result = json.loads((out / "compounds.structure-only.json").read_text())
            self.assertEqual(result[0]["molecular_formula_computed"], "C2H6O")
            self.assertEqual(result[0]["activity_status"], "NOT_EVALUATED")
            self.assertEqual(
                result[0]["provenance"]["verification"], "NOT_INDEPENDENTLY_VERIFIED"
            )
            self.assertNotIn("ic50", str(result).lower())
            self.assertEqual(
                cn.main(["normalize", "--input", str(source), "--out", str(out)]), 2
            )


if __name__ == "__main__":
    unittest.main()
