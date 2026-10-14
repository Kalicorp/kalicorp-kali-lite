# Configurateur d'installation Kali-Lite

Le configurateur est une **page HTML statique et autonome côté navigateur** (`docs/index.html` + `docs/configurator.js`), sans framework, bibliothèque externe, compte, API ou télémétrie. Les sélections sont calculées dans le navigateur : **aucune commande n'est lancée depuis la page**.

## Mode local (immédiat)

Dans un terminal avec Git et Python 3 :

```bash
git clone --depth 1 --branch projet-x https://github.com/Kalicorp/kalicorp-kali-lite.git kali-lite
cd kali-lite
python3 -m http.server 8765 --bind 127.0.0.1 --directory docs
```

Ouvrir ensuite **http://127.0.0.1:8765** sur la même machine. Pour arrêter le serveur : `Ctrl+C`. Le fichier `docs/index.html` peut aussi s'ouvrir directement depuis le disque avec `docs/configurator.js` à côté, sans lancer Python. Les liens vers le dépôt et la documentation nécessitent Internet, mais la génération des commandes n'en a pas besoin.

## Publication Web sans infrastructure applicative

La page est compatible avec **GitHub Pages** en publiant le dossier `docs/` de la branche `projet-x`. La configuration Pages dépend de l'administrateur du dépôt : cela **n'est pas automatiquement activé par cette PR**.

Après activation et déploiement, l'URL conventionnelle attendue est `https://kalicorp.github.io/kalicorp-kali-lite/` (à **vérifier réellement** avant de diffuser). Pour ne pas dépendre de GitHub Pages, Kalicorp peut aussi servir le contenu de `docs/` depuis son propre site web avec un serveur HTTP statique.

**Limite GitHub README :** GitHub neutralise JavaScript dans les fichiers Markdown ; un sélecteur interactif ne peut pas s'exécuter directement dans `README.md`. Le README fournit donc une entrée claire et renvoie à la page.

## Parcours générés

| Moteur | Source | Parcours |
|---|---|---|
| Qwen3 8B | Branche stable `main` | Installateur Kali-Lite V1 ; vérification SHA-256 ; `--dry-run` |
| Qwen3.5 9B Vision | Branche stable `main` | Installateur Kali-Lite V2 ; vérification SHA-256 ; `--dry-run` |
| Mistral 7B | Branche expérimentale `projet-x` | Ollama Q4_K_M ou Q8_0 ; `--dry-run`, pull explicite, création d'un tag séparé |
| OLMo 3 7B | Branche expérimentale `projet-x` | Idem |
| Gemma 4 E2B | Branche expérimentale `projet-x` | Idem ; capacités Vision à qualifier séparément |

Les trois systèmes proposés sont Linux, macOS et Windows via Ubuntu **WSL2** (pilote). Un parcours Windows produit **deux zones de commandes distinctes**, PowerShell administrateur pour la préparation et Bash dans Ubuntu pour l'installation : ne pas coller du Bash dans PowerShell.

### Cas Windows / WSL2

L'Ollama Linux de la distribution WSL doit être installé et démarré séparément. Voir la [documentation officielle](https://ollama.com/download/linux) et `docs/WINDOWS-WSL2.md`. **Aucun support Windows natif et aucune validation WSL2 réelle ne sont revendiqués.** Les scripts Linux Qwen utilisés sous WSL2 restent exploratoires.

### Cas macOS

Pour les deux installateurs stables Qwen, Homebrew est requis (voir [brew.sh](https://brew.sh)) ; les scripts s'exécutent sans `sudo`. Pour les profils expérimentaux, **Ollama doit être déjà installé et joignable en local**.

### Transparence et sécurité

- Les branches `main` et `projet-x` ne sont **pas** des références figées (hash SHA de commit) ; la procédure nécessite un contrôle humain avant exécution.
- **Authenticité du SHA-256 :** `SHA256SUMS` est un inventaire d'empreintes, pas une signature cryptographique d'éditeur ; il détecte une divergence entre fichiers téléchargés et empreintes du même dépôt mais ne garantit pas l'origine d'un dépôt compromis.
- La page ne présente jamais une commande `curl | bash`, un `sudo` macOS, ni un téléchargement silencieux de modèles expérimentaux.
- Les installateurs peuvent modifier le système local et télécharger des dépendances lorsqu'on les exécute volontairement.
- La page ne mesure pas la RAM disponible et **ne garantit donc pas** qu'un modèle Q8 pourra être chargé intégralement dans un GPU donné.

## Tests

```bash
node tests/test_configurator.cjs
```

Le test valide **30 combinaisons** (5 moteurs × 3 systèmes × 2 positions de quantification, la quantification étant ignorée pour les profils Qwen). La CI GitHub Actions vérifie la génération sans faire de téléchargement ou installation réelle. La compatibilité graphique finale reste à revoir sur navigateurs et petits écrans avant promotion.
