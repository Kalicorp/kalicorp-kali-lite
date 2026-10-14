# Quantifications expérimentales — laboratoire Kali-Lite

**Recettes reproductibles de tags Ollama, pas de quantification réalisée par Kalicorp.** Les poids amont restent chez leurs éditeurs/distributeurs. Le script crée un Modelfile temporaire à partir de la doctrine existante sans modifier les scripts d'installation officiels.

| Variante | Profil | Tag exact Ollama amont | Taille affichée par Ollama (indicative) |
|---|---|---|---|
| Mistral 7B v0.3 | Q4_K_M | `mistral:7b-instruct-v0.3-q4_K_M` | ~4,4 Go |
| Mistral 7B v0.3 | Q8_0 | `mistral:7b-instruct-v0.3-q8_0` | ~7,7 Go |
| OLMo 3 7B Instruct | Q4_K_M | `olmo-3:7b-instruct-q4_K_M` | ~4,5 Go |
| OLMo 3 7B Instruct | Q8_0 | `olmo-3:7b-instruct-q8_0` | ~7,8 Go |
| Gemma 4 E2B | Q4_K_M | `gemma4:e2b-it-q4_K_M` | ~4,6 Go |
| Gemma 4 E2B | Q8_0 | `gemma4:e2b-it-q8_0` | taille variable selon digest, à vérifier localement |

La taille d'artefact **n'est pas** la VRAM totale nécessaire : compter aussi le cache KV, le contexte, le runtime et, le cas échéant, la vision.

## Utilisation

```bash
bash scripts/kali-lite-quant.sh --list
bash scripts/kali-lite-quant.sh --dry-run gemma4-e2b q4
# Action volontaire et explicite :
ollama pull gemma4:e2b-it-q4_K_M
bash scripts/kali-lite-quant.sh --create gemma4-e2b q4
ollama run kali-lite-gemma4-e2b-q4
```

Pour Q8 : utiliser `q8` et télécharger **d'abord** le tag exact annoncé par `--dry-run`. Le script n'effectue jamais de pull, ne lance pas `sudo`, n'altère pas les Modelfiles du dépôt et refuse les profils inconnus.

**Ne pas confondre** une variante Q4/Q8 créée avec un fine-tuning de ses poids, une validation qualité, un benchmark GPU ou une provenance auditée. Les deux quantifications doivent être mesurées sur le même matériel avant promotion.

## Vérifications

```bash
bash tests/test_quant.sh  # tests avec Ollama simulé, sans GPU ni réseau
ollama show kali-lite-gemma4-e2b-q4 --modelfile
ollama ps
```

Pour mesurer l'écart, figer le nombre de tokens de contexte, les prompts, la version d'Ollama et le pilote. Recueillir latence, tokens/s, VRAM réelle, cohérence française, hallucinations d'outils et réponse aux refus. Pour nettoyer un tag expérimental uniquement : `ollama rm kali-lite-gemma4-e2b-q4`.

Sources : [Mistral — tags Ollama](https://ollama.com/library/mistral/tags), [OLMo 3 — tags Ollama](https://ollama.com/library/olmo-3/tags), [Gemma 4 — tags Ollama](https://ollama.com/library/gemma4/tags).
