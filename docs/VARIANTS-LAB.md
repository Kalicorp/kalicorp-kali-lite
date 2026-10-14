# Laboratoire multi-modèles Kali-Lite — projet-x

> **Expérimental / non publié.** Ces profils sont des configurations Ollama ; ils ne représentent ni un entraînement, ni un fine-tuning, ni une redistribution des poids. La branche officielle `Kalicorp/main` reste inchangée.

## Objectif

Comparer des bases interchangeables sous une doctrine Kalicorp stable, sans toucher aux installateurs V1/V2, à leurs empreintes SHA-256 ou aux modèles déjà déployés. Ce dépôt `balduregates1/kalicorp-kali-lite` est le fork de laboratoire.

| Profil | Modèle amont exact | Tag Kali-Lite local | Capacités à tester | Taille du téléchargement (indicative) |
|---|---|---|---|---|
| `mistral-7b` | `mistral:7b-instruct` (v0.3) | `kali-lite-mistral-7b` | Chat / français / outils suivant runtime | ~4,4 Go |
| `olmo3-7b` | `olmo-3:7b-instruct` | `kali-lite-olmo3-7b` | Transparence / respect consignes / anglais-français | ~4,5 Go |
| `gemma4-e2b` | `gemma4:e2b` | `kali-lite-gemma4-e2b` | Edge / vision / latence | ~4,6 à 7,5 Go selon quantification et tag |

**OLMo 9B :** aucun modèle officiel OLMo 9B n'a été identifié pendant cette reconnaissance. Ce profil utilise explicitement **OLMo 3 7B Instruct**, pas un 9B fictif. Ce choix peut évoluer si un modèle 9B officiel est confirmé ultérieurement.

**Gemma E2B :** "E2B" désigne des paramètres effectifs, **pas** une occupation de VRAM de 2 Go. La VRAM réelle dépend de la quantification, du contexte, du cache KV, du runtime et des données image. Les trois Modelfiles démarrent avec un `num_ctx 8192` conservateur, distinct du maximum théorique annoncé pour les modèles.

## Commandes — prévisualiser sans effet de bord

```bash
bash scripts/kali-lite-variant.sh --list
bash scripts/kali-lite-variant.sh --dry-run mistral-7b
bash scripts/kali-lite-variant.sh --dry-run olmo3-7b
bash scripts/kali-lite-variant.sh --dry-run gemma4-e2b
bash tests/test_variants.sh
```

## Installation explicite, locale et réversible

Choisir un seul modèle pour commencer. **Le pull est volontairement une action séparée** :

```bash
ollama pull gemma4:e2b
bash scripts/kali-lite-variant.sh --create gemma4-e2b
ollama run kali-lite-gemma4-e2b
```

Remplacer `gemma4:e2b` / `gemma4-e2b` par `mistral:7b-instruct` / `mistral-7b`, ou `olmo-3:7b-instruct` / `olmo3-7b`. `--create` refuse de s'exécuter si Ollama est absent ou si le modèle amont n'est pas déjà disponible localement. Le script ne télécharge rien, ne lance pas de `sudo`, ne modifie pas le réseau et n'écrase pas les tags `kali-lite` et `kali-lite-v2`.

Pour nettoyer uniquement un **tag expérimental**, l'opérateur peut faire `ollama rm kali-lite-gemma4-e2b` (ou le tag concerné). Ne pas supprimer les modèles amont partagés sans vérification.

## Règles de validation avant toute publication

1. Vérifier la version réelle d'Ollama et le support de l'architecture (particulièrement Gemma 4).
2. Vérifier le fichier `FROM` et le Modelfile rendu par `ollama show <tag> --modelfile`.
3. Mesurer VRAM, temps avant premier token, tokens/s, exactitude en français, stabilité à 8K ; comparer sur la **même machine** et la **même quantification** si possible.
4. Exécuter un jeu de tests d'intégrité : refus d'inventer une action, distinction OBSERVÉ / HYPOTHÈSE, transparence des outils, maîtrise de l'opérateur.
5. Tester vision seulement pour Gemma 4 E2B ; ne jamais présumer que Mistral ou OLMo 3 acceptent une image.
6. Tester l'absence de télémétrie et les chemins de données dans le **harnais** ; un modèle local ne suffit pas à prouver l'air-gap ou la conformité.
7. Conserver les licences et notices amont si publication/redistribution. Les Modelfiles seuls ne sont pas des weights.

## Sources amont et licences

- [Mistral 7B Instruct v0.3 — Ollama](https://ollama.com/library/mistral:7b-instruct) — Apache-2.0.
- [OLMo 3 7B Instruct — Ollama](https://ollama.com/library/olmo-3:7b-instruct) — Apache-2.0.
- [Gemma 4 E2B — Ollama](https://ollama.com/library/gemma4:e2b) ; [Gemma 4 — annonce Google](https://blog.google/innovation-and-ai/technology/developers-tools/gemma-4/) — Apache-2.0.

**Statut :** profils ajoutés et tests statiques prévus ; aucune mesure GPU réelle et aucune publication Hugging Face dans ce chantier.
