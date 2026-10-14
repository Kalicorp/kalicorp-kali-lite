# Validation Kali-Lite — ce que les tests prouvent (et ne prouvent pas)

## Deux niveaux GitHub

1. `test-cross-platform.yml` teste les scripts et les protections avec un Ollama simulé sous **Ubuntu, Windows natif (Git Bash) et macOS**. **Windows natif ≠ WSL2**.
2. `bench-ollama-cpu.yml` réalise une **véritable inférence** sur un runner Linux CPU avec le modèle Q4 par défaut `mistral:7b-instruct-v0.3-q4_K_M`, et enregistre durée, tokens/s et réponses synthétiques. Après le premier essai sur le fork, relancer manuellement depuis GitHub Actions pour OLMo, Gemma ou Q8.

Aucune mesure de VRAM n'est déductible d'un test sur runner CPU. Les trois prompts du smoke test sont très courts et les critères de comportement sont des **heuristiques**, non des métriques d'évaluation scientifique.

## Ce qui attend un test réel

- WSL2 : valider l'installation/désinstallation sur un hôte Windows avec WSL2 opérationnel, pas seulement Git Bash.
- GPU Kalicorp : les essais **Q4 Mistral / OLMo / Gemma 4** sur RTX 4090 ont passé chacun 3/3 heuristiques (voir mesures ci-dessous). Il reste à faire des générations longues, des répétitions et les **Q8** ; relever systématiquement VRAM avec `nvidia-smi`.
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


## Gemma 4 : diagnostic du mode de raisonnement (14 octobre 2026)

Lors des premiers tests RTX 4090, Gemma 4 E2B Q4 a renvoyé une réponse vide avec le banc initial : `num_predict=80` et option `think` non précisée. Vérification par l'opérateur sur l'instance Ollama locale :

- Modèle amont, `think=false`, `num_predict=256` : `Paris` en 2 tokens.
- Profil Kali-Lite, `think=false`, `num_predict=256` : `Paris` en 2 tokens.
- Profil Kali-Lite, `think=true`, `num_predict=256` : `Paris` en 196 tokens, dont une phase de raisonnement.

**Conclusion prudente :** les poids et le profil répondent. Le budget initial de 80 tokens *pourrait* avoir été épuisé par le raisonnement implicite ; l'option implicite n'a pas été tracée lors de l'échec initial, donc ce mécanisme n'est pas démontré rétroactivement.

Le banc définit désormais `"think": false` explicitement pour les tests comparatifs. Il accepte aussi `--think` et un budget augmenté, en inscrivant le mode dans le JSON ; il **ne stocke pas** le contenu du raisonnement, seulement sa longueur.

```bash
# Mettre à jour la branche expérimentale et cibler le serveur 4090 isolé
git pull --ff-only origin bench-validation
export OLLAMA_HOST=127.0.0.1:11555

# Comparaison sans raisonnement ; très courte, ne remplace pas un benchmark de charge
python3 scripts/bench_ollama.py --model kali-lite-gemma4-e2b-q4 \
  --endpoint http://127.0.0.1:11555 --num-ctx 4096 --num-predict 256 \
  --output gemma4-4090-q4.json

# Test distinct du raisonnement, budget généreux
python3 scripts/bench_ollama.py --model kali-lite-gemma4-e2b-q4 \
  --endpoint http://127.0.0.1:11555 --think --num-ctx 4096 --num-predict 512 \
  --output gemma4-4090-q4-thinking.json
```

En cas de sortie vide, les résultats précédents restent enregistrés en JSON et le programme se termine avec code non nul pour alerter la CI. Pour mesurer le GPU, relever séparément `ollama ps` et `nvidia-smi -i 0`. La validation multimodale et les longs contextes restent à tester.


## Premiers résultats observés sur la RTX 4090 — 14 octobre 2026

**Provenance :** sorties terminal transmises par l'opérateur depuis Ubuntu 26, GPU 0 NVIDIA GeForce RTX 4090 (24 GiB), pilote 595.99.02, CUDA affiché 13.2, Ollama serveur 0.40.4, client 0.40.3. Instance de laboratoire sur `127.0.0.1:11555`, distincte du conteneur de production. Modèles Q4 et contexte 2 048 tokens lors des premiers smoke tests.

| Profil | Vérification | Temps du premier appel (avec chargement) | Débits des deux réponses suivantes | VRAM du processus affichée dans nvidia-smi |
|---|---|---:|---|---:|
| `kali-lite-mistral-7b-q4` | 3/3 heuristiques ; GPU 0, 100 % GPU | 30,609 s | 172,02 et 169,81 tok/s | 4 912 MiB |
| `kali-lite-olmo3-7b-q4` | 3/3 heuristiques ; GPU 0, 100 % GPU | 10,268 s | 167,06 et 169,37 tok/s | 5 612 MiB |
| `kali-lite-gemma4-e2b-q4` | **3/3**, think=false, `num_ctx=4096`, `num_predict=256` | 4,256 s | 386,59 et 522,47 tok/s | 3 378 MiB |

**Expérience Gemma 4 :** la réponse vide du premier benchmark ne signifie pas un modèle défaillant. Le modèle amont et la configuration Kalicorp répondent `Paris` avec `think=false` et `num_predict=256` ; avec `think=true`, la même question produit une réponse correcte après 196 tokens au total. Le mécanisme de l'échec initial (budget de 80 tokens sans option `think` explicite) reste une hypothèse, pas une observation directe. **Correction exécutée sur la RTX 4090 :** le banc versionné avec `think=false`, `num_ctx=4096` et `num_predict=256` renvoie 3/3, zéro réponse vide, avec débits successifs de 135,37, 386,59 et 522,47 tok/s. Les chiffres correspondent à de très courts textes et ne permettent pas d'établir la performance sur des tâches longues.

**À ne pas conclure :** supériorité d'un modèle à partir de deux réponses très courtes ; débit de génération longue ; consommation de puissance moyenne ; conformité/souveraineté du harnais ; capacités vision ou support WSL2. Les valeurs de mémoire sont instantanées, et les premiers appels incluent chargement/initialisation.

**Règle de qualification :** ces observations valident le smoke test GPU Q4 de **Mistral, OLMo et Gemma 4 (3/3 chacun)**, pas la comparaison Q4/Q8, les capacités multimodales ou une qualification de production.
