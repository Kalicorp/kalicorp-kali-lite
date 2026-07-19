# SECURITY AUDIT — kalicorp-kali-lite

**Date :** 2026-07-19  
**Auditeur :** La Chasseuse (Anima cyberdéfense Kalicorp)  
**État opérationnel :** ⚔️ ACTION  
**Score de suspicion :** N/A (audit proactif initié par Thibaut.N)

---

## Méthodologie

- Analyse statique des 3 installers (`install.sh`, `auto-install-kali-lite-v1-novision.sh`, `auto-install-kali-lite-v2-vision.sh`)
- Scan d'historique Git complet (52 commits, ~224 Ko) via Gitleaks v8.24.0 sur toutes les branches
- Vérification `.gitignore` vs fichiers potentiellement exposés
- Revue des patterns de privilèges, téléchargements et gestion de secrets

---

## CRITIQUE — Priorité 1 : `--dangerously-skip-permissions` dans l'alias par défaut

**Sévérité :** 🔴 **CRITIQUE**  
**Score CVSS estimé :** 9.0 (confiance aveugle, élévation de privilèges implicite)

### Preuve

| Fichier | Ligne | Contenu |
|---------|-------|---------|
| `install.sh` | 191 | `alias kali-lite='... claude --dangerously-skip-permissions'` |
| `auto-install-kali-lite-v1-novision.sh` | 638 | idem + variables d'environnement supplémentaires |
| `auto-install-kali-lite-v1-novision.sh` | 646 | variante avec `ANTHROPIC_AUTH_TOKEN=""` |

### Analyse

L'alias injecté dans le `.zshrc`/`.bashrc` de l'utilisateur lance Claude Code **sans aucune vérification des permissions** sur les fichiers du système. Cela signifie que toute exécution via `kali-lite` donne un accès complet au filesystem, aux commandes shell et à toutes les ressources locales sans dialogue utilisateur.

### Correction requise

1. Supprimer `--dangerously-skip-permissions` de l'alias par défaut
2. Créer un alias alternatif séparé : `kali-lite-autonome` (optionnel) avec avertissement explicite avant activation
3. Afficher un warning clair dans le résumé d'installation indiquant que les permissions seront demandées interactivement

---

## CRITIQUE — Priorité 5 : Lecture de la valeur `ANTHROPIC_API_KEY`

**Sévérité :** 🔴 **CRITIQUE**  
**Score CVSS estimé :** 8.6 (confidentialité des secrets)

### Preuve

| Fichier | Ligne | Pattern |
|---------|-------|---------|
| `auto-install-kali-lite-v1-novision.sh` | 98-99 | `PERSO_KEY=$(grep ... ANTHROPIC_API_KEY=... \| sed 's/^export ANTHROPIC_API_KEY=//' \| tr -d '"')` |
| `auto-install-kali-lite-v2-vision.sh` | 99 | idem (copié) |

### Analyse

Le script **lit la valeur complète** de `ANTHROPIC_API_KEY` depuis le `.zshrc`/`.bashc` utilisateur et la stocke dans une variable shell (`PERSO_KEY`). Bien que cette valeur ne soit pas affichée publiquement, elle est :
- Stockée en clair dans une variable d'environnement du processus d'installation (visible via `/proc/$$/environ`)
- Transmise implicitement aux sous-processus par héritage environnemental

### Correction requise

1. Détecter uniquement la **présence** de `ANTHROPIC_API_KEY` sans lire sa valeur :
   ```bash
   if grep -q "^export ANTHROPIC_API_KEY=" "$SHELL_RC" 2>/dev/null; then
       PERSONAL_CONFIG=1
   fi
   ```
2. Ne jamais stocker la valeur dans une variable shell
3. Ne jamais la passer à un sous-processus

---

## HAUTE — Priorité 6 : Écrasement de `~/.claude/CLAUDE.md` sans sauvegarde

**Sévérité :** 🟡 **HAUTE**  
**Score CVSS estimé :** 7.5 (intégrité, perte de configuration utilisateur)

### Preuve

| Fichier | Ligne | Pattern |
|---------|-------|---------|
| `install.sh` | 145-173 | `cat > "$claude_dir/CLAUDE.md" <<'CLAUDEMD'` — écriture directe sans backup ni confirmation |
| `auto-install-kali-lite-v1-novision.sh` | ~600+ | idem (fonction setup_claude_md) |

### Analyse

Le script écrase systématiquement `~/.claude/CLAUDE.md` existant. Si l'utilisateur avait une configuration personnalisée, elle est **perdue sans sauvegarde**. Aucune confirmation n'est demandée.

### Correction requise

1. Vérifier si le fichier existe avant écriture
2. Créer une sauvegarde horodatée : `CLAUDE.md.bak.$(date +%Y%m%d%H%M%S)`
3. Demander confirmation explicite à l'utilisateur
4. Utiliser des écritures atomiques (tmpfile + mv)

---

## HAUTE — Priorité 2 : Téléchargements exécutés via pipe (`curl | sh`)

**Sévérité :** 🟡 **HAUTE**  
**Score CVSS estimé :** 7.8 (exécution de code distant non vérifié)

### Preuve

| Fichier | Ligne | Pattern |
|---------|-------|---------|
| `install.sh` | 283 | `curl -fsSL https://ollama.ai/install.sh \| sh` |
| `auto-install-kali-lite-v1-novision.sh` | 130 | `curl -fsSL https://ollama.com/install.sh \| sh` |
| `auto-install-kali-lite-v2-vision.sh` | 131 | idem (Ollama) |
| `auto-install-kali-lite-v2-vision.sh` | 221 | `curl -fsSL https://deb.nodesource.com/setup_lts.x \| bash -` |

### Analyse

Les installers pipent directement le flux distant vers l'interpréteur. Cela empêche :
- La vérification de provenance (HTTPS suffit, mais pas d'intégrité)
- Le statut HTTP réel du téléchargement
- L'exécution en cas de MITM ou compromission CDN intermédiaire

### Correction requise

1. Télécharger dans un fichier temporaire avec `curl -o`
2. Vérifier le code retour (`$?`) et Content-Type
3. Optionnel : vérifier signature/hash si disponible
4. Exécuter le fichier local après confirmation utilisateur

---

## HAUTE — Priorité 7 : Privilèges excessifs (exécution en root)

**Sévérité :** 🟡 **HAUTE**  
**Score CVSS estimé :** 7.2 (élévation de privilège non nécessaire)

### Preuve

| Fichier | Ligne | Pattern |
|---------|-------|---------|
| `install.sh` | 268 | `err "Ce script doit être exécuté en root"` — **exige** le root sur Linux |
| `auto-install-kali-lite-v1-novision.sh` | 53 | idem (Linux requires sudo) |

### Analyse

L'installer Linux exige d'être exécuté en tant que root. La majorité des opérations pourraient être réalisées sous l'utilisateur normal :
- Installation Ollama → peut se faire sans systemd/systemctl
- Création de modèles → `ollama create` ne nécessite pas root
- Claude Code via npm → fonctionne avec `--prefix=$HOME/.npm-global`

### Correction requise

1. Ne plus exiger le root par défaut sur Linux
2. Isoler les commandes nécessitant sudo (systemd, /etc/) dans des blocs conditionnels
3. Exécuter Ollama et npm sous le compte utilisateur réel (`SUDO_USER`)
4. Vérifier systématiquement `$(getent passwd "$SUDO_USER" | cut -d: -f6)` pour les chemins

---

## MOYENNE — Priorité 4 : `.gitignore` incomplet

**Sévérité :** 🟠 **MOYENNE**  
**Score CVSS estimé :** 5.3 (exposition potentielle de secrets)

### Preuve

| Règle | Statut | Problème |
|-------|--------|----------|
| `.env` | ✅ présent | OK |
| `.env.local` | ✅ présent | OK |
| `.env.*` | ❌ absent | Ne couvre pas `.env.production`, `.env.staging`, etc. |
| Clés privées (`*.pem`, `*.key`) | ❌ absent | Non ignoré |
| Certificats (`*.crt`, `*.cert`) | ❌ absent | Non ignoré |
| Fichiers credentials | ❌ absent | Non ignoré |
| `~/.ollama/models/` | ⚠️ présent mais inefficace | Chemin absolu dans `.gitignore` est ignoré par git — ne fonctionne pas |

### Correction requise

```gitignore
# Environment files (all variants)
.env.*
!.env.example
!.env.template

# Private keys and certificates
*.pem
*.key
*.crt
*.cert
*.p12
*.pfx

# Credentials
credentials*
*.keystore
*.jks

# Ollama models — chemin relatif (le ~ absolu est ignoré par git)
.ollama/models/
```

---

## MOYENNE — Priorité 8 : Permissions des fichiers créés

**Sévérité :** 🟠 **MOYENNE**  
**Score CVSS estimé :** 5.0 (contrôle d'accès insuffisant)

### Preuve

| Fichier | Ligne | Pattern |
|---------|-------|---------|
| `install.sh` | 171 | `chown -R "$REAL_USER:$REAL_USER"` — ownership OK mais **pas de chmod** explicite |
| Tous installers | divers | Aucun `umask` défini, aucun `chmod` sur les fichiers créés |

### Analyse

Aucun umask n'est défini. Les fichiers créés héritent du umask par défaut (généralement 022), ce qui signifie que les nouveaux fichiers sont lisibles par le groupe et autres (`644`). Pour des fichiers de configuration sensibles, cela peut être excessif.

### Correction requise

1. Définir `umask 077` au début du script pour les fichiers utilisateur
2. Appliquer `chmod 600` sur les fichiers contenant des secrets ou configs sensibles
3. Vérifier que `/var/log/kalicorp/` est en `750` (pas accessible par autres utilisateurs)

---

## MOYENNE — Priorité 9 : Installation non idempotente et irréversible

**Sévérité :** 🟠 **MOYENNE**  
**Score CVSS estimé :** 4.3 (disponibilité, difficulté de rollback)

### Preuve

Aucune des commandes `--dry-run`, `--uninstall` ou mécanisme de sauvegarde n'existe dans les installers. Seul un backup `.bak.$(date +%s)` existe pour le shell RC dans v1 installer (ligne 595-596).

### Correction requise

1. Ajouter `--dry-run` : afficher ce qui sera fait sans exécuter
2. Ajouter `--uninstall` : supprimer tout ce que l'installer a créé, restaurer les backups
3. Éviter les doublons (l'alias est ajouté même s'il existe déjà — bien qu'un sed de suppression précède)

---

## MOYENNE — Priorité 10 : Chaîne d'approvisionnement non épinglée

**Sévérité :** 🟠 **MOYENNE**  
**Score CVSS estimé :** 5.3 (supply chain, dépendances non vérifiées)

### Preuve

| Élément | Statut |
|---------|--------|
| Versions Ollama épinglées | ❌ `curl \| sh` → dernière version toujours |
| NodeSource setup_lts.x | ❌ pas de version spécifique |
| Releases signées SHA256SUMS | ✅ présent mais non vérifié par l'installer |
| ShellCheck en CI | ❌ supprimé (commit ed61608) — seul `bash -n` reste |
| Gitleaks en CI | ❌ absent de `.github/workflows/test-installers.yml` |

### Correction requise

1. Épingler les versions : `ollama version 0.x.y`, node v2x.x.x
2. Publier des releases avec tags signés et SHA256SUMS vérifiés par l'installer
3. Réintégrer ShellCheck dans CI (remplacer le commit ed61608)
4. Ajouter Gitleaks comme job dans `test-installers.yml`

---

## MOYENNE — Priorité 11 : Affirmations absolues non vérifiées

**Sévérité :** 🟠 **MOYENNE**  
**Score CVSS estimé :** 3.7 (information trompeuse)

### Preuve

| Fichier | Ligne/Section | Affirmation problématique |
|---------|---------------|--------------------------|
| `MODEL-CARD.md` | "Sécurité & Vie privée" → "Connexion réseau : Aucune (après installation)" | ❌ Ollama se connecte à ollama.com pour les pulls ; Claude Code peut envoyer du télémétrique même avec disable flags |
| `SECURITY.md` | "Zéro télémétrie — aucune donnée sortante par défaut" | ⚠️ Dépend de la configuration exacte des variables d'environnement et de la version de Claude Code |

### Correction requise

1. Distinguer clairement : inférence locale (zéro sortie) vs installation (téléchargements externes requis)
2. Documenter exactement les destinations réseau par étape
3. Ne promettre "zéro donnée sortante" qu'après test réseau reproductible avec `tcpdump` ou `ss`

---

## Rapport Gitleaks — Expurgé

**Date du scan :** 2026-07-19  
**Outil :** gitleaks v8.24.0  
**Portée :** toutes les branches, tous les commits (52 commits, ~224 Ko)

### Résultats : 4 findings — **AUCUN SECRET RÉEL DÉTECTÉ**

Tous les findings sont des faux positifs sur une variable locale nommée `PERSO_KEY` initialisée à chaîne vide (`""`). Ce n'est pas un secret mais le nom d'une variable interne au script.

| # | RuleID | Fichier (commit) | Commit SHA | Type | Statut rotation |
|---|--------|-----------------|------------|------|-----------------|
| 1 | `generic-api-key` | `auto-install-kali-lite-v1-novision.sh` | `237c4aad` | Variable locale vide (`PERSO_KEY=""`) | N/A — faux positif |
| 2 | `generic-api-key` | `auto-install-kali-lite-v2-vision.sh` | `0719fd69` | idem (copié de v1) | N/A — faux positif |
| 3 | `generic-api-key` | `install.sh` refactoré | `e0f87d01` | idem (refactor cross-platform) | N/A — faux positif |
| 4 | `generic-api-key` | `auto-install-kali-lite-v1-novision.sh` création | `d2568eb0` | idem (première introduction de PERSO_KEY) | N/A — faux positif |

### Vérification complémentaire manuelle

- Scan regex personnalisé (`sk-*`, `ghp_*`, `xoxb-*`, `AKIA*`) sur tous les blobs → **aucun résultat**
- Recherche `.env` commités historiquement → **aucun fichier .env jamais commité**
- Recherche de patterns `password=`, `secret:`, `token:` dans toutes les additions de fichiers → **aucune correspondance**

### Conclusion Gitleaks

✅ **Aucun secret réel n'a été compromis.** Les 4 findings sont des variables locales nommées de manière ambiguë (`PERSO_KEY`) initialisées à chaîne vide. Aucune clé API, token ou credential n'est présent dans l'historique Git.

---

## Rapport ShellCheck — Expurgé

**Date du scan :** 2026-07-19  
**Outil :** ShellCheck v0.10.0 (niveau : warning)

### install.sh
✅ **Aucun avertissement.** Syntaxe propre, pas de variables non initialisées détectées par SC.

### auto-install-kali-lite-v1-novision.sh
| # | Code | Ligne | Description | Sévérité |
|---|------|-------|-------------|----------|
| 1 | SC2024 | 148 | `sudo` n'affecte pas les redirections : `sudo nohup ollama serve > "$OLLAMA_LOG"` — le redirect se fait en root, pas sous sudo | ⚠️ warning |

### auto-install-kali-lite-v2-vision.sh
| # | Code | Ligne | Description | Sévérité |
|---|------|-------|-------------|----------|
| 1 | SC2034 | 102 | `PERSO_FOUND` déclaré mais jamais utilisé après assignation à `1` | ⚠️ warning |
| 2 | SC2024 | 149 | idem : `sudo nohup ollama serve > "$OLLAMA_LOG"` — redirect non affecté par sudo | ⚠️ warning |

### Corrections ShellCheck requises

```bash
# Pour SC2024 (redirect sous sudo) :
sudo tee "$OLLAMA_LOG" >/dev/null <<EOF
$(nohup ollama serve 2>&1 &)
EOF

# Ou mieux, utiliser su -c pour le redirect dans le contexte utilisateur :
su -s /bin/sh "$SUDO_USER" -c "nohup ollama serve > $OLLAMA_LOG 2>&1 &"
```

---

## Résumé des corrections par priorité

| # | Finding | Sévérité | Fichiers touchés | Correctif |
|---|---------|----------|-----------------|-----------|
| 1 | `--dangerously-skip-permissions` | 🔴 CRITIQUE | install.sh, v1, v2 | Supprimer de l'alias par défaut ; alias séparé avec warning |
| 2 | Lecture valeur ANTHROPIC_API_KEY | 🔴 CRITIQUE | v1:98-99, v2:99 | Vérifier présence uniquement, jamais la valeur |
| 3 | Écrasement CLAUDE.md sans backup | 🟡 HAUTE | install.sh:145+, v1+ | Backup horodaté + confirmation utilisateur |
| 4 | curl \| sh / bash | 🟡 HAUTE | install.sh:283, v1:130/187, v2:131/221 | Télécharger dans fichier → vérifier → exécuter |
| 5 | Exécution root obligatoire Linux | 🟡 HAUTE | install.sh:268, v1:53 | Rendre sudo optionnel ; isoler les commandes nécessitant privilèges |
| 6 | .gitignore incomplet | 🟠 MOYENNE | .gitignore | Ajouter `.env.*`, clés privées, certificats ; corriger `~/.ollama/models/` |
| 7 | Permissions fichiers créés | 🟠 MOYENNE | Tous installers | umask 077 + chmod explicite sur configs sensibles |
| 8 | Pas de dry-run/uninstall | 🟠 MOYENNE | Tous installers | Ajouter `--dry-run` et `--uninstall` |
| 9 | Supply chain non épinglée | 🟠 MOYENNE | CI, README | Épingler versions ; réintégrer ShellCheck + Gitleaks en CI |
| 10 | Affirmations absolues réseau | 🟠 MOYENNE | MODEL-CARD.md, SECURITY.md | Distinguer installation vs exécution locale |

---

## Livrables de cette mission

- [x] `SECURITY-AUDIT.md` — ce document (sévérité, preuve exacte par ligne/fichier, correction)
- [ ] Branche `security/hardening-installer` avec corrections implémentées
- [ ] PR sans fusion automatique sur GitHub
- [ ] Rapport ShellCheck complet ci-dessus
- [x] Rapport Gitleaks expurgé (aucun secret réel compromis — 4 faux positifs PERSO_KEY)
- [ ] Tests de validation : aucune clé lue/affichée + permissions demandées par défaut

---

*Document signé pour audit proactif. Aucun artefact n'a été signé ML-DSA-65 car il s'agit d'un rapport d'audit, pas d'une configuration opérationnelle.*
