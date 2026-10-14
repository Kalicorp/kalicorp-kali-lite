# Kali-Lite × Hermes Agent CLI — passerelle Ollama locale

> **Statut : procédure de connexion documentée, compatibilité agentique NON qualifiée.**
>
> La campagne RTX 4090 du 14 octobre 2026 a validé **18/18 tests heuristiques** sur les six profils expérimentaux Q4/Q8, **avec 2 048/4 096 tokens de contexte et sans appels d'outils Hermes**. Cela ne valide pas Hermes Agent.

## Objectif

Kali-Lite est le **moteur d'inférence** local via Ollama ; [Hermes Agent CLI](https://github.com/NousResearch/hermes-agent), logiciel tiers de Nous Research, apporte la **boucle agentique**, les outils, le terminal, les skills et les permissions associées. Ce sont deux projets distincts ; aucun composant Hermes n'est inclus dans Kali-Lite.

Hermes prend en charge un **Custom endpoint** exposant l'API OpenAI-compatible `/v1/chat/completions` de Ollama. Il n'est pas nécessaire de modifier ni de forker Hermes pour établir ce lien.

Sources amont :
- [Hermes — LLM and Model Providers / Ollama](https://hermes-agent.nousresearch.com/docs/integrations/providers/)
- [Hermes — Quickstart (contexte minimal)](https://hermes-agent.nousresearch.com/docs/getting-started/quickstart/)
- [Hermes — CLI commands](https://hermes-agent.nousresearch.com/docs/reference/cli-commands/)
- [Hermes — Toolsets Reference](https://hermes-agent.nousresearch.com/docs/reference/toolsets-reference/)

## 1. Identifier la bonne instance Ollama

**Ne pas démarrer une seconde instance sur un port déjà occupé.** KaliCorp peut héberger plusieurs serveurs Ollama ; l'adresse de l'instance de travail peut différer de l'exemple ci-dessous.

Pour une instance locale standard :

```bash
ollama --version
curl -fsS http://127.0.0.1:11434/api/version
curl -fsS http://127.0.0.1:11434/v1/models
ollama list
ollama show kali-lite-v2
```

Adapter le port et le tag local réel. Sous Linux, la commande `OLLAMA_HOST=127.0.0.1:11435 ollama list` peut viser une **autre instance** ; ne pas supposer que le port 11435 est un environnement de test. **Ne pas réutiliser 11555** sans vérifier que l'instance expérimentale est toujours active.

## 2. Vérification obligatoire : contexte de 64K

**Point bloquant actuel :** la documentation Hermes demande au moins **64 000 tokens de contexte**, faute de quoi l'agent peut refuser de démarrer. Le `Modelfile` de référence Kali-Lite v2 publié dans ce dépôt définit **`PARAMETER num_ctx 32768`** ; les profils Mistral/OLMo/Gemma du laboratoire définissent `8192` dans leurs Modelfiles. **Aucun de ces profils n'est prêt à utiliser Hermes avec ces paramètres inchangés.**

Hermes `model.context_length` est une **déclaration côté client**, pas un réglage de la VRAM ou du contexte réellement alloué par Ollama. Pour tester avec Hermes, il faut :

1. Vérifier que **le modèle amont** accepte au moins 65 536 tokens dans sa configuration réelle (`ollama show <modèle>` et documentation de l'architecture).
2. Établir un **profil expérimental séparé** portant `PARAMETER num_ctx 65536`, si l'architecture le supporte.
3. Vérifier sur la machine que 65 536 tokens **tiennent réellement en RAM/VRAM** ; mesurer le GPU et le cache KV. Augmenter `num_ctx` peut provoquer une erreur mémoire ou dégrader fortement les performances.
4. Après une génération de test, contrôler `ollama ps` : colonne **CONTEXT**. Ce n'est qu'alors qu'il est pertinent d'indiquer 65 536 tokens à Hermes.

**Ne jamais augmenter artificiellement `model.context_length` côté Hermes sans augmenter réellement le contexte du serveur.** Ne pas modifier la configuration de production ni forcer la 4090/4500 déjà en service.

### Exemple facultatif : créer un profil isolé

Sur une instance Ollama **de laboratoire et libre**, et après vérification du contexte pris en charge par Qwen3.5 9B, une copie peut être préparée à partir du Modelfile local :

```bash
# Préconditions : ollama existe, le modèle kali-lite-v2 est présent,
# serveur de laboratoire choisi via OLLAMA_HOST, matériel et contexte vérifiés.
ollama show kali-lite-v2 --modelfile > kali-lite-hermes-test.Modelfile

python3 - <<'PY'
from pathlib import Path
import re
p = Path("kali-lite-hermes-test.Modelfile")
s = p.read_text()
s, n = re.subn(r"(?m)^PARAMETER\s+num_ctx\s+\d+\s*$", "PARAMETER num_ctx 65536", s)
if n != 1:
    raise SystemExit("Modelfile imprévu : ne pas changer le contexte sans inspection manuelle")
p.write_text(s)
PY

# Examiner le fichier ET vérifier le modèle réel avant toute création :
less kali-lite-hermes-test.Modelfile

# Vérifier qu'on ne remplace pas un tag existant :
ollama show kali-lite-v2-hermes-test >/dev/null 2>&1 && {
  echo "Tag déjà présent : ne pas écraser"; exit 1;
}

# Créer un nouveau tag sans toucher à kali-lite-v2 :
ollama create kali-lite-v2-hermes-test -f kali-lite-hermes-test.Modelfile
```

Cette commande ne rend **pas** magiquement le modèle capable de traiter 64K et **n'est pas une recette certifiée**. Préférer une machine de test et un modèle dont la fenêtre native est suffisante. Les fichiers de test et le tag peuvent ensuite être supprimés **volontairement** ; ne pas supprimer un modèle partagé.

## 3. Brancher Hermes sur l'endpoint local

Installer Hermes Agent selon les [instructions du projet Nous Research](https://hermes-agent.nousresearch.com/docs/getting-started/quickstart/), après revue des scripts et des permissions. Puis exécuter :

```bash
hermes model
```

Choisir **Custom endpoint (self-hosted / vLLM / etc.)**, puis saisir :

| Champ Hermes | Exemple pour une instance locale de laboratoire |
|---|---|
| **API base URL** | `http://127.0.0.1:11434/v1` (adapter au vrai port) |
| **API key** | Aucune pour un serveur Ollama local sans authentification, ou valeur factice si exigée par l'interface |
| **Model** | `kali-lite-v2-hermes-test` (**uniquement si le tag a bien été créé**) |
| **Context length** | `65536` **uniquement si constaté côté serveur** |

Hermes enregistre ces préférences dans `~/.hermes/config.yaml`. Il est aussi possible d'éditer directement ce fichier après sauvegarde :

```yaml
model:
  default: kali-lite-v2-hermes-test
  provider: custom
  base_url: http://127.0.0.1:11434/v1
  context_length: 65536
```

> **Ne pas copier ce YAML tant que les quatre valeurs ne correspondent pas à un modèle, un endpoint et une fenêtre de contexte réellement disponibles.**

Lancer ensuite la CLI :

```bash
hermes
```

## 4. Qualification à faire avant de déclarer « compatible Hermes »

- **Connectivité** : `/v1/models`, puis une vraie réponse `/v1/chat/completions` de **l'instance explicitement sélectionnée**.
- **Contexte** : 64K effectivement alloué, sans erreur mémoire, avec vérification `ollama ps`.
- **Appels d'outils** : demander la lecture d'un **fichier de test non sensible** ; vérifier que Hermes produit une véritable invocation et que la preuve d'exécution est visible. Répéter avec un outil non autorisé : Kali-Lite ne doit pas prétendre l'avoir utilisé.
- **Contrôle d'accès** : démarrer avec un ensemble minimal d'outils (`hermes tools`, ou `hermes chat --toolsets file` selon version), jamais avec le mode `--yolo`.
- **Réversibilité** : contrôler que l'arrêt d'Hermes ne coupe pas Ollama partagé ; décharger **seulement** le modèle de test avec `ollama stop <tag>`.
- **Confidentialité** : l'inférence peut rester locale ; cela **ne garantit pas** que tous les outils, appels réseau, skills, connecteurs et journaux d'Hermes restent hors cloud. Auditer les permissions et composants installés.

**Important :** l'agent possède les droits accordés à son harnais. Il n'est pas simplement un chatbot. Pour un terminal utilisable avec précaution, préférer une sandbox Docker ou un environnement de test dédié plutôt que l'accès direct aux serveurs Kalicorp.

## Statut

**Passerelle : documentée. Non homologuée.** Une fois le test bout en bout sur 64K, la vérification des outils et le comportement de refus effectués, il sera possible d'indiquer « Hermes Agent CLI : testé sur configuration X » dans le README.
