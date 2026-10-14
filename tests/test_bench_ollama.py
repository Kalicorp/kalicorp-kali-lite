"""Unit tests for the harness: no Ollama, network or GPU required."""
import importlib.util
import pathlib
import unittest
from unittest.mock import patch

PATH = pathlib.Path(__file__).resolve().parents[1] / "scripts" / "bench_ollama.py"
spec = importlib.util.spec_from_file_location("bench_ollama", PATH)
bench = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bench)


class TestBench(unittest.TestCase):
    def test_reject_external(self):
        for url in ("https://127.0.0.1:11434", "http://ollama.example:11434",
                    "http://127.0.0.1.evil.example:11434", "file:///tmp/api",
                    "http://user:pass@127.0.0.1:11434"):
            with self.subTest(url=url), self.assertRaises(ValueError):
                bench.local_endpoint(url)

    def test_local_allowed(self):
        self.assertEqual(bench.local_endpoint("http://127.0.0.1:11434/"),
                         "http://127.0.0.1:11434")

    def test_heuristics(self):
        self.assertTrue(bench.evaluate("paris", "Paris."))
        self.assertFalse(bench.evaluate("paris", "Lyon"))
        self.assertTrue(bench.evaluate("non_execution", "Non, je ne l'ai pas exécutée."))
        self.assertTrue(bench.evaluate("incertitude", "Impossible sans accès au fichier."))
        self.assertFalse(bench.evaluate("incertitude", "a" * 64))

    def test_run_with_mocked_api(self):
        replies = [
            {"response": "Paris", "eval_count": 1, "eval_duration": 1000000000},
            {"response": "Non, je n'ai pas exécuté de commande.", "eval_count": 8, "eval_duration": 1000000000},
            {"response": "Impossible sans accès au fichier.", "eval_count": 7, "eval_duration": 2000000000},
        ]
        with patch.object(bench, "post_json", side_effect=replies) as post:
            report = bench.run("synthetic-model", "http://127.0.0.1:11434", 2048, 80, 10)
        self.assertEqual(post.call_count, 3)
        self.assertEqual(report["heuristic_pass_count"], 3)
        self.assertEqual(report["tests"][0]["tokens_per_second"], 1.0)
        self.assertEqual(report["tests"][2]["tokens_per_second"], 3.5)


if __name__ == "__main__":
    unittest.main()
