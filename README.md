# Kali-Lite — Le modèle frugal souverain de Kalicorp

**Deux versions téléchargeables • Cross-platform • Ultra-frugales • 100 % local**

![Kali-Lite](https://github.com/balduregates1/kalicorp-hardening/blob/main/assets/kali-lite-banner.png)

**Kali-Lite** est le modèle IA local made in Kalicorp : souverain, frugal et conçu pour tourner sur du matériel modeste tout en respectant RGPD / AI Act.

### Les deux versions disponibles

| Version              | Moteur              | VRAM requise | Vision | Cas d’usage principal                  | Taille modèle |
|----------------------|---------------------|--------------|--------|----------------------------------------|---------------|
| **Kali-Lite**        | Qwen3 8B            | **~8 Go**    | Non    | Chat rapide, code, assistance système  | ~5,2 Go      |
| **Kali-Lite v2**     | Qwen3.5 9B          | **~10 Go**   | Oui    | Analyse d’images + tout le reste       | ~6,8 Go      |

### Pourquoi Kali-Lite ?
- 100 % **local** → aucune donnée ne quitte ta machine
- Identité Kalicorp gravée (Anima du Sanctuaire)
- Compatible **Claude Code v2+** en local (proxy Anthropic)
- Installation en une ligne sur Linux **et** macOS
- Frugalité extrême : tourne même sur un laptop 8 Go VRAM

### Installation ultra-simple (1 commande)


# Kali-Lite (8 Go VRAM - sans vision)
curl -fsSL https://raw.githubusercontent.com/balduregates1/kalicorp-hardening/main/auto-install-kali-lite-v1-novision.sh | bash

# Kali-Lite v2 (10 Go VRAM - avec vision)
curl -fsSL https://raw.githubusercontent.com/balduregates1/kalicorp-hardening/main/auto-install-kali-lite-v2-vision.sh | bash
Temps moyen : 15-20 minutes (le temps de télécharger le modèle via Ollama)
Après installation
Bashkali-lite          # lance directement l’interface Claude Code souverain
ollama run kali-lite     # ou en mode chat pur
Matériel testé et validé

Minimal : 8 Go VRAM + 16 Go RAM
Recommandé : 10 Go+ VRAM + 32 Go RAM
Testé sur : RTX 3080 8 Go, RTX 4070, Apple Silicon M1/M2/M3, Kali Linux, Ubuntu, macOS 11+

Licence & philosophie

Licence : GPL-2.0 (redistribution libre)
Pas de télémetry, pas de cloud, pas de backdoor
Conçu pour les makers, TPE, collectivités et passionnés de souveraineté numérique

Kalicorp — Le Sanctuaire numérique européen
2026 • app.kalicorp.fr • GitHub
