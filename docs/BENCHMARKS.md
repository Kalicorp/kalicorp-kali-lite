# Validation Kali-Lite — ce que les tests prouvent (et ne prouvent pas)

## Deux niveaux GitHub

1. `test-cross-platform.yml` teste les scripts et les protections avec un Ollama simulé sous **Ubuntu, Windows natif (Git Bash) et macOS**. **Windows natif ≠ WSL2**.
2. `bench-ollama-cpu.yml` réalise une **véritable inférence** sur un runner Linux CPU avec le modèle Q4 par défaut `mistral:7b-instruct-v0.3-q4_K_M`, et enregistre durée, tokens/s et réponses synthétiques. Après le premier essai sur le fork, relancer manuellement depuis GitHub Actions pour OLMo, Gemma ou Q8.

Aucune mesure de VRAM n'est déductible d'un test sur runner CPU. Les trois prompts du smoke test sont très courts et les critères de comportement sont des **heuristiques**, non des métriques d'évaluation scientifique.

## Ce qui attend un test réel

- WSL2 : valider l'installation/désinstallation sur un hôte Windows avec WSL2 opérationnel, pas seulement Git Bash.
- GPU Kalicorp : choisir un GPU libre, bloquer la fréquence/contexte/quantification et relever VRAM avec `nvidia-smi` ; mesurer le même jeu de prompts sur tous les modèles, avec répétitions et moyennes.
- Vision : jeu d'images de test libre de droits pour Gemma 4, résultats interprétés humainement.
- Confidentialité : tests réseau du harnais complet dans un environnement contrôlé (pas uniquement dans le modèle).

## Sécurité des runners

Le workflow CPU tourne sur une VM GitHub publique éphémère, sans accès aux serveurs ou secrets Kalicorp, avec `contents: read` et `persist-credentials: false`. Il télécharge volontairement l'installateur officiel Ollama et le modèle indiqué. Le hash SHA256 du script d'installation est journalisé, **mais n'est pas épinglé à une version fixe** : ce test n'atteste donc pas à lui seul de la chaîne d'approvisionnement.

Le workflow ne doit traiter **que des prompts synthétiques** ; ne pas introduire de données clients ou personnelles. Aucune tâche coûteuse GPU n'est activée.

## Utilisation

Dans le dépôt GitHub et la branche portant le workflow, ouvrir **Actions → Real Ollama CPU smoke benchmark → Run workflow**. Sélectionner un modèle et une quantification. Le rapport JSON est joint aux artifacts de l'exécution pendant sept jours.

Test local si Ollama est déjà présent :
```bash
bash scripts/kali-lite-quant.sh --dry-run mistral-7b q4
# après téléchargement volontaire et création du profil :
python3 scripts/bench_ollama.py --model kali-lite-mistral-7b-q4 --output bench.json
```
