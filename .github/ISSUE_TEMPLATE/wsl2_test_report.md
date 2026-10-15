---
name: Test Windows / WSL2
about: Retour de test pilote Kali-Lite sous Ubuntu WSL2, succès ou échec
title: '[WSL2 TEST] '
assignees: ''
---

## Résultat
- [ ] Succès
- [ ] Échec
- [ ] Partiel

## Environnement (sans identifiants personnels)
- Windows (10/11, version) :
- `wsl -l -v` (masquer les noms personnels) :
- Distribution Ubuntu / version :
- RAM totale (Go) :
- Disque disponible (Go) :
- GPU / VRAM ou CPU seulement :
- Pilote GPU Windows (si pertinent) :
- Ollama **Linux sous WSL2** / version :
- Variante Kali-Lite :
- Contexte configuré (si connu) :
- Branche / commit testé (facultatif) :

## Étapes réalisées
- [ ] `bash scripts/check-wsl2.sh`
- [ ] `sha256sum --check SHA256SUMS`
- [ ] Installation simulée avec `--dry-run`
- [ ] Installation réelle sur environnement non critique
- [ ] Réponse obtenue avec `ollama run kali-lite` ou `ollama run kali-lite-v2`
- [ ] Redémarrage Windows et nouveau test
- [ ] Désinstallation (facultatif)

## Résultat observé
Commandes réellement exécutées, génération réussie ou message d'erreur, latence si mesurée, étapes pour reproduire. Les échecs sont aussi des retours utiles.

## Capture / extrait de terminal
**Masquer avant publication** : nom d'utilisateur, chemin personnel, IP, nom de machine, clé, token, fichiers clients ou données confidentielles. Ne pas publier de logs bruts non relus.

## Observations
Remarques et suggestions éventuelles.

> Pilote : Windows via **Ubuntu WSL2**, pas d'installation Windows native. Aucune qualification CPU/GPU revendiquée à ce stade.
