"""Contract tests: no inference service, data download or private source required."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
import workflow as w


def source_file(folder: Path) -> Path:
    path = folder / "sources.jsonl"
    path.write_text(json.dumps({
        "source_id": "S1", "title": "Document fictif pour test de contrat",
        "url": "https://example.org/unit-test", "excerpt": "Donnée factice : aucun essai clinique."
    }, ensure_ascii=False) + "\n", encoding="utf-8")
    return path


class WorkflowTests(unittest.TestCase):
    def test_sources_and_hash(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = source_file(Path(tmp))
            rows = w.load_sources(path)
            self.assertEqual(rows[0]["source_id"], "S1")
            self.assertEqual(len(w.sha256_bytes(path.read_bytes())), 64)

    def test_source_duplicates_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = source_file(Path(tmp))
            path.write_text(path.read_text() * 2, encoding="utf-8")
            with self.assertRaises(w.WorkflowError):
                w.load_sources(path)

    def test_unknown_citation_rejected(self):
        draft = {"summary": "Test", "claims": [
            {"statement": "Un résultat fictif", "status": "DOCUMENTE", "source_ids": ["MADE_UP"]}
        ], "next_questions": [], "limitations": []}
        with self.assertRaises(w.WorkflowError):
            w.validate_draft(draft, {"S1"})

    def test_documented_claim_requires_citation(self):
        draft = {"summary": "Test", "claims": [
            {"statement": "Non sourcé", "status": "DOCUMENTE", "source_ids": []}
        ], "next_questions": [], "limitations": []}
        with self.assertRaises(w.WorkflowError):
            w.validate_draft(draft, {"S1"})

    def test_local_default_allowed_and_remote_blocked(self):
        self.assertTrue(w.check_endpoint("http://127.0.0.1:11434/v1", False)
                        .endswith("/chat/completions"))
        with self.assertRaises(w.WorkflowError):
            w.check_endpoint("https://api.example.org/v1", False)
        with self.assertRaises(w.WorkflowError):
            w.check_endpoint("http://api.example.org/v1", True)
        self.assertTrue(w.check_endpoint("https://api.example.org/v1", True)
                        .endswith("/chat/completions"))

    def test_offline_dry_run(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            src = source_file(folder)
            out = folder / "artifacts"
            rc = w.main(["run", "--sources", str(src), "--question", "Quelles lacunes ?",
                         "--dry-run", "--out", str(out)])
            self.assertEqual(rc, 0)
            self.assertEqual(json.loads((out / "manifest.json").read_text())["status"], "DRY_RUN")
            self.assertTrue((out / "prompt_preview.json").exists())
            self.assertFalse((out / "report.draft.json").exists())

    def test_mock_model_creates_review_required_report(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            src = source_file(folder)
            out = folder / "results"
            draft = {"summary": "Données insuffisantes",
                     "claims": [{"statement": "L'extrait est fictif", "status": "DOCUMENTE",
                                 "source_ids": ["S1"]}],
                     "next_questions": ["Chercher une publication réelle"],
                     "limitations": ["Aucune validation scientifique"]}
            with patch.object(w, "request_completion", return_value=json.dumps(draft)):
                rc = w.main(["run", "--sources", str(src), "--question", "Question de test",
                             "--model", "mock-model", "--out", str(out)])
            self.assertEqual(rc, 0)
            self.assertTrue((out / "HUMAN_REVIEW_REQUIRED.md").exists())
            self.assertEqual(json.loads((out / "report.draft.json").read_text()), draft)

    def test_invalid_model_response_never_published_as_report(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            src = source_file(folder)
            out = folder / "results"
            with patch.object(w, "request_completion", return_value='{"claims": []}'):
                rc = w.main(["run", "--sources", str(src), "--question", "test",
                             "--model", "mock", "--out", str(out)])
            self.assertEqual(rc, 2)
            self.assertFalse((out / "report.draft.json").exists())
            self.assertTrue((out / "rejected.json").exists())


if __name__ == "__main__":
    unittest.main()
