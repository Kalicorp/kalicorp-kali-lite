#!/usr/bin/env python3
"""Compare les copies des Modelfiles sans exécuter Ollama."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent


def embedded(path: str) -> bytes:
    content = (ROOT / path).read_bytes()
    marker = b"<<'MODELFILE_EOF'\n"
    if content.count(marker) != 1:
        raise AssertionError(f"{path}: bloc heredoc manquant ou dupliqué")
    return content.split(marker, 1)[1].split(b"\nMODELFILE_EOF", 1)[0] + b"\n"


def equal(name: str, a: bytes, b: bytes) -> None:
    if a != b:
        raise AssertionError(f"DRIFT {name}: Modelfiles différents")
    print(f"PASS {name}")


def main() -> None:
    v1 = embedded("auto-install-kali-lite-v1-novision.sh")
    v2 = embedded("auto-install-kali-lite-v2-vision.sh")
    equal("install.sh / V1", embedded("install.sh"), v1)
    equal("V1 / HF 8B", v1, (ROOT / "huggingface/kali-lite-8b/Modelfile").read_bytes())
    equal("V2 / racine", v2, (ROOT / "Modelfile").read_bytes())
    equal("V2 / HF Vision", v2, (ROOT / "huggingface/kali-lite-vision-9b/Modelfile").read_bytes())
    print("PASS : copies synchronisées (pas de test d'inférence)")


if __name__ == "__main__":
    try:
        main()
    except (OSError, AssertionError) as exc:
        print(f"FAIL {exc}", file=sys.stderr)
        sys.exit(1)
