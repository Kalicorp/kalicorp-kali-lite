# Windows / WSL2 — installation pilote Kali-Lite

**Statut : documentation + diagnostic disponibles, validation matérielle Windows en attente.** Aucun test Windows/WSL2 réel n'est revendiqué par la CI Linux.

## Principe

Kali-Lite s'exécute sous **Ubuntu dans WSL2** avec Ollama Linux. Ne pas confondre l'Ollama Windows natif, un daemon Ollama dans WSL et un daemon exposé depuis l'hôte Windows : choisir **une seule** option à la fois pour éviter les problèmes de port, de permissions et de confidentialité.

Dans PowerShell administrateur, après vérification de la politique informatique locale :

```powershell
wsl --install -d Ubuntu
wsl --update
wsl --list --verbose
```

Si la distribution indique la version 1 : `wsl --set-version Ubuntu 2` (sauvegarder les données avant migration). Redémarrer Windows si demandé. Les commandes peuvent différer selon Windows 10/11 et restrictions d'entreprise.

Dans le terminal **Ubuntu WSL2** :

```bash
uname -r
bash scripts/check-wsl2.sh
```

Le diagnostic ne télécharge rien et ne modifie pas le réseau. Il vérifie WSL2, le CLI Ollama, la visibilité NVIDIA, la RAM, le disque et l'API Ollama **locale sur 127.0.0.1**. Il ne démontre ni l'absence d'Internet, ni l'accélération GPU effective.

## Campagne communautaire Windows / WSL2

Sur la branche pilote `projet-x`, récupérer les scripts avant de les inspecter :

```bash
git clone --depth 1 --branch projet-x https://github.com/Kalicorp/kalicorp-kali-lite.git
cd kalicorp-kali-lite
bash scripts/check-wsl2.sh
```

Ce diagnostic est non destructif et n'installe aucun modèle. Pour aller plus loin, suivre la procédure du README : vérifier `SHA256SUMS`, lire les scripts et utiliser `--dry-run` avant toute installation réelle. **Pas de `curl | bash`.**

Les retours de test réussis et échoués sont bienvenus : partager version Windows, sortie de `wsl -l -v`, CPU/GPU, RAM, disque, version Ollama dans **Ubuntu WSL2**, variante et résultat réel (y compris après un redémarrage).

[**Consulter le gabarit de retour WSL2 sur la branche pilote**](https://github.com/Kalicorp/kalicorp-kali-lite/blob/projet-x/.github/ISSUE_TEMPLATE/wsl2_test_report.md). Tant que ce gabarit n'est pas fusionné sur la branche par défaut, il faut en copier les rubriques dans un [nouveau ticket GitHub](https://github.com/Kalicorp/kalicorp-kali-lite/issues/new) ou dans son retour de test ; GitHub ne le propose pas encore automatiquement.

Masquer avant publication les noms d'utilisateurs et de machines, chemins personnels, IP, tokens et données privées. Relire les captures et les journaux avant de les partager.

## Ollama

Installer Ollama Linux depuis sa source officielle **après** examen de son installateur et de la politique de sécurité. Les installateurs Kalicorp Linux attendent un environnement compatible et peuvent demander les privilèges root. Commencer par `--dry-run` sans `sudo`. Ensuite choisir V1, V2 ou les variantes expérimentales en suivant leur guide. Les scripts V1/V2 n'ont pas encore été certifiés sous WSL2.

Pour une variante expérimentale, avec Ollama installé sous WSL2 :

```bash
bash scripts/kali-lite-variant.sh --list
bash scripts/kali-lite-variant.sh --dry-run gemma4-e2b
# Confirmation et téléchargement manuels :
ollama pull gemma4:e2b
bash scripts/kali-lite-variant.sh --create gemma4-e2b
ollama run kali-lite-gemma4-e2b
```

## GPU et limites

- Pour NVIDIA, installer le **pilote Windows adapté à WSL2 sur l'hôte**. Ne pas installer automatiquement un pilote Linux NVIDIA classique dans WSL.
- Vérifier `nvidia-smi` sous WSL et surveiller l'occupation VRAM dans Ollama. Certains équipements ou pilotes imposent CPU ou offload partiel.
- L'inférence CPU exige davantage de RAM et peut être lente ; Gemma 4 E2B n'est pas nécessairement un modèle « 2 Go ».
- Stocker les fichiers de modèle et les données privées sur un emplacement contrôlé et vérifier les ACL Windows/WSL.
- WSL2 ne démontre pas un environnement air-gap. Contrôler le réseau Windows, le pare-feu, DNS, télémétrie des dépendances et ports Ollama.

## Recette d'acceptation avant de cocher « Support WSL2 »

1. Vérifier Ubuntu sous WSL2 (pas WSL1), puis `bash scripts/check-wsl2.sh`.
2. Exécuter les tests sans effet de bord et les commandes `--dry-run`.
3. Tester au moins un modèle texte en CPU, puis un modèle en GPU si la configuration le permet.
4. Relever versions Windows, WSL2, Ollama, pilote, VRAM, RAM, stockage et résultat de `ollama run`.
5. Valider installations, redémarrages, gestion des droits, journalisation, puis désinstallation dans un environnement de test.
6. Mettre à jour le tableau « Matériel testé » du README seulement avec des mesures observées.

Aucun script Kali-Lite ne modifie PowerShell, le registre Windows ou le pilote NVIDIA.
