# Security Policy — Kali-Lite

## Supported Versions

| Version | Status | Notes |
|---|---|---|
| v2.x (Vision) | ✅ Actif | Dernière version majeure |
| v1.x (8B) | ✅ Actif | Maintenance courante |
| < 1.0 | ❌ Non supporté | Mises à jour de sécurité non garanties |

## Reporting a Vulnerability

Nous prenons les vulnérabilités au sérieux et encourageons la divulgation responsable.

### Comment signaler

- **Email** : security@kalicorp.fr
- **Sujet** : `[Kali-Lite] [SECURITY] <titre court>`
- **Contenu attendu** : description, étapes de reproduction, impact estimé, CVE associée si applicable

### Délais de réponse

| Étape | Délai maximal |
|---|---|
| Accusé de réception | 48h ouvrées |
| Évaluation initiale (triage) | 5 jours ouvrés |
| Correctif ou mitigation | Selon sévérité : <br>• Critique — 7 jours<br>• Haute — 14 jours<br>• Moyenne/Basse — 30 jours |

### Ce que nous demandons

- Ne pas exploiter la vulnérabilité divulguée
- Ne pas partager publiquement avant un correctif disponible
- Nous tenir informé de toute découverte complémentaire

### Ce que nous ne faisons pas

- Pas de bug bounty (projet open-source communautaire)
- Pas de NDA préalable pour le signalement initial

## Security Features

Kali-Lite est conçu avec les principes suivants :

1. **Zéro télémétrie** — aucune donnée sortante par défaut
2. **Exécution locale uniquement** — aucun cloud requis ni imposé
3. **Pas d'exécution de code distant automatique** — le script d'installation appelle des installateurs officiels (Ollama, NodeSource/Homebrew) mais ne télécharge jamais de binaire tiers inconnu
4. **Transparence du modèle** — provenance Qwen documentée dans MODEL-CARD.md

## Security Updates

Les correctifs sont publiés via les releases GitHub normales. Les utilisateurs sont invités à :

- Consulter les [releases](https://github.com/Kalicorp/kalicorp-kali-lite/releases) régulièrement
- Vérifier l'empreinte SHA-256 des scripts d'installation avant exécution (voir README.md)
- Auditer le code source — ce projet est open-source sous GPL-2.0

## Contact

Pour toute question de sécurité : **security@kalicorp.fr**

---

Kalicorp — Le Sanctuaire numérique européen | 2026
