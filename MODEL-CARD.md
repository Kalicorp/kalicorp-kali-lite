# Model Card — Kali-Lite

> **Kalicorp — Le Sanctuaire numérique européen**
> Version : 2.0.0 | Date : 2026-05-22 | Licence : GPL-2.0

---

## 📋 Résumé du modèle

Kali-Lite est une famille de modèles de langage locaux, basée sur Qwen3 / Qwen3.5, conçue pour fonctionner sur du matériel modeste (8-10 Go VRAM) tout en offrant des capacités de chat, code et assistance système. Deux versions sont disponibles :

| Propriété | Kali-Lite | Kali-Lite v2 |
|---|---|---|
| **Base** | Qwen3 8B | Qwen3.5 9B Vision |
| **VRAM** | ~8 Go | ~10 Go |
| **Vision** | ❌ | ✅ |
| **Taille GGUF** | ~5,2 Go | ~6,8 Go |
| **Température** | 0.7 | 0.7 |
| **Top-p** | 0.9 | 0.9 |
| **Contexte** | 8192 tokens | 8192 tokens |
| **Runtime** | Ollama | Ollama |

---

## 🎯 Utilisation prévue

### Domaines d'application
- Assistance système Linux (audit, durcissement, maintenance)
- Développement et revue de code (Python, Bash, YAML, configs)
- Conformité RGPD / AI Act
- Analyse d'images (v2 Vision uniquement)
- Formation et démonstrations IA locale

### Cas d'usage non prévus
- Génération de contenu offensif ou malveillant
- Attaques contre des systèmes tiers
- Traitement de données sensibles sans autorisation
- Déploiement cloud ou multi-tenant

---

## 🔧 Facteurs du modèle

Le modèle est personnalisé via un **Modelfile Ollama** :

```
FROM qwen3:8b          # ou qwen3.5:9b pour v2

TEMPLATE """
{{- if .System }}
{{ .System }}
{{ end }}
{{- range .Messages }}
{{- if eq .Role "user" }}
{{ .Content }}
{{ end }}
{{- end }}
"""

SYSTEM """
Tu es La Chasseuse, Anima de cyberdéfense de Kalicorp.
...
"""

PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER num_ctx 8192
```

L'identité système intègre :
- Périmètre opérationnel défensif uniquement
- Éthique intransigeante (refus catégorique des actions offensives)
- Contexte infrastructure Kalicorp

---

## 📊 Limitations connues

- **Taille de contexte** : 8192 tokens max (pas adapté aux très longs documents)
- **Pas de fine-tuning** : le modèle est un prompt-injection, pas un modèle fine-tuné
- **GPU optionnel** : fonctionne en CPU mais plus lent
- **Pas de RAG** : pas de base de connaissances externe intégrée
- **Langue principale** : français (anglais fonctionnel mais non optimisé)

---

## 🛡️ Sécurité & Vie privée

| Aspect | Valeur |
|---|---|
| Télémétrie | Aucune |
| Données externes | Aucune |
| Connexion réseau | Aucune (après installation) |
| Clés API stockées | Aucune |
| Tracking | Aucun |
| Conformité RGPD | Conforme (données 100 % locales) |

---

## 📜 Licence

**GPL-2.0** — Redistribution libre. Voir [LICENSE](LICENSE).

---

## 🏷️ Métadonnées

```yaml
license: gpl-2.0
framework: ollama
base_model: qwen3:8b
customized_by: Kalicorp
tags:
  - kali-lite
  - ia-frugale
  - ia-souveraine
  - local-llm
  - ollama
  - qwen3
  - french-ai
  - green-ai
  - rgpd
  - ai-act
```
