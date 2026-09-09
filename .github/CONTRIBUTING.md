# Contribuer à Kali-Lite

Merci de votre intérêt pour **Kali-Lite**.

Kali-Lite est un projet open source porté par **Kalicorp**, centré sur l'IA locale, la frugalité, la maîtrise de l'infrastructure et la transparence opérationnelle.

Les contributions sont les bienvenues lorsqu'elles améliorent le projet sans masquer ses limites ni réduire le contrôle de l'opérateur.

---

## 📋 Principes du projet

Les contributions doivent respecter quelques principes simples.

### 1. Maîtrise par l'opérateur

Kali-Lite vise à permettre à l'utilisateur de comprendre et maîtriser :

- le modèle utilisé ;
- les dépendances ;
- les outils connectés ;
- les permissions ;
- les données ;
- l'environnement d'exécution.

Une nouvelle dépendance n'est pas interdite par principe, mais elle doit être :

- utile ;
- identifiable ;
- documentée ;
- justifiée ;
- aussi remplaçable que raisonnablement possible.

### 2. Pas de télémétrie ajoutée

Les contributions ne doivent pas ajouter de :

- tracking utilisateur ;
- analytics cachés ;
- télémétrie non documentée ;
- envoi automatique de conversations ou données vers Kalicorp ou un tiers.

Toute communication réseau nécessaire à une fonctionnalité doit être explicite et documentée.

### 3. Preuve avant affirmation

Kali-Lite distingue :

```text
Comprendre une action
        ≠
Avoir l'outil
        ≠
Avoir la permission
        ≠
Avoir exécuté l'action
```

Une contribution ne doit pas faire croire qu'une commande, un outil ou une action a été exécuté lorsqu'aucune preuve d'exécution n'est disponible.

### 4. Sécurité

Les contributions liées à la cybersécurité doivent rester dans un cadre défensif ou explicitement autorisé.

Sont notamment acceptés :

- diagnostic ;
- audit ;
- durcissement ;
- analyse de logs ;
- détection ;
- documentation de vulnérabilités ;
- tests sur des systèmes appartenant au contributeur ou explicitement autorisés.

Une contribution ne doit pas transformer Kali-Lite en outil destiné à l'attaque non autorisée de systèmes tiers.

### 5. Simplicité

Une amélioration doit rester aussi lisible que possible.

Préférer :

- une modification ciblée ;
- une dépendance justifiée ;
- un comportement observable ;
- des tests simples ;
- une documentation claire ;

plutôt qu'une architecture plus complexe sans bénéfice démontré.

---

## 🔧 Comment contribuer

### 1. Forker le dépôt

```bash
git clone https://github.com/<votre-username>/kalicorp-kali-lite.git
cd kalicorp-kali-lite
```

Ajoutez éventuellement le dépôt Kalicorp comme `upstream` :

```bash
git remote add upstream https://github.com/Kalicorp/kalicorp-kali-lite.git
```

### 2. Créer une branche dédiée

Exemples :

```bash
git checkout -b fix/<nom-court>
```

```bash
git checkout -b feat/<nom-court>
```

```bash
git checkout -b docs/<nom-court>
```

Évitez de mélanger plusieurs sujets indépendants dans la même Pull Request.

---

## ✅ Contributions bienvenues

Quelques exemples :

- corrections de bugs dans les installateurs ;
- amélioration du support Linux ou macOS ;
- préparation du support Windows / WSL2 ;
- amélioration du `--dry-run` ;
- amélioration du mode `--uninstall` ;
- tests supplémentaires ;
- corrections de documentation ;
- amélioration de la Model Card ;
- amélioration de la politique de sécurité ;
- amélioration de l'accessibilité ;
- traductions ;
- support de nouveaux modèles de base ;
- amélioration de la portabilité ;
- réduction de la consommation mémoire ;
- amélioration de la reproductibilité ;
- amélioration de la détection matériel ;
- mécanismes permettant de remplacer plus facilement une dépendance.

Les propositions importantes d'architecture peuvent être discutées dans une Issue avant développement.

---

## ⚠️ Changements nécessitant une justification claire

Certaines modifications ne sont pas interdites, mais nécessitent une explication détaillée dans la Pull Request.

Cela concerne notamment :

- ajout d'une dépendance réseau ;
- ajout d'une API externe ;
- ajout d'une dépendance cloud ;
- modification du modèle de base ;
- augmentation importante des besoins RAM ou VRAM ;
- ajout d'un outil disposant de permissions système ;
- modification du comportement de sécurité ;
- modification du système de téléchargement ou d'installation ;
- modification de la gestion des secrets ;
- changement du format de mémoire ou de persistance.

La Pull Request doit expliquer :

- pourquoi ce changement est nécessaire ;
- quelles données peuvent être concernées ;
- quelles permissions sont nécessaires ;
- quelles alternatives ont été envisagées ;
- comment revenir en arrière.

---

## ❌ Contributions non acceptées

Le projet n'acceptera pas volontairement :

- de télémétrie cachée ;
- de tracking utilisateur non consenti ;
- de collecte de conversations par défaut ;
- de secrets ou clés API intégrés dans le code ;
- de credentials présents dans un prompt ou un fichier versionné ;
- de mécanisme prétendant avoir exécuté une action sans preuve ;
- de contournement volontaire des permissions de l'opérateur ;
- de porte dérobée ;
- de téléchargement ou exécution distante dissimulée ;
- de fonctionnalité principalement destinée à compromettre des systèmes tiers sans autorisation ;
- d'affirmation trompeuse de conformité automatique au RGPD, à l'AI Act, à l'ANSSI ou à une norme ISO.

---

## 🧪 Tests

Avant d'ouvrir une Pull Request, vérifiez au minimum la syntaxe Bash lorsque vous modifiez un installateur :

```bash
bash -n install.sh
bash -n auto-install-kali-lite-v1-novision.sh
bash -n auto-install-kali-lite-v2-vision.sh
```

Pour les scripts concernés, utilisez également le mode `--dry-run` :

```bash
bash install.sh --dry-run
bash auto-install-kali-lite-v1-novision.sh --dry-run
bash auto-install-kali-lite-v2-vision.sh --dry-run
```

Lorsque les tests du dépôt sont disponibles dans votre environnement, exécutez également les scripts pertinents du dossier :

```text
tests/
```

Toute Pull Request qui modifie un installateur doit vérifier qu'un `--dry-run` ne crée pas d'effet de bord inattendu.

---

## 🔐 Modifications des installateurs

Une attention particulière est demandée pour :

```text
install.sh
auto-install-kali-lite-v1-novision.sh
auto-install-kali-lite-v2-vision.sh
```

Si un installateur est modifié :

1. vérifier sa syntaxe ;
2. tester son `--dry-run` ;
3. vérifier les chemins Linux et macOS concernés ;
4. vérifier qu'aucun secret n'a été ajouté ;
5. vérifier les téléchargements distants ;
6. mettre à jour la documentation si nécessaire ;
7. recalculer son empreinte SHA-256.

Le fichier :

```text
SHA256SUMS
```

doit correspondre exactement aux scripts publiés.

**Ne mettez à jour l'empreinte qu'après la dernière modification du script.**

---

## 📝 Pull Request

Une Pull Request doit idéalement rester limitée à un seul objectif.

Merci d'indiquer :

- le problème rencontré ;
- le changement proposé ;
- les fichiers modifiés ;
- les plateformes testées ;
- les tests exécutés ;
- les éventuelles limites connues ;
- les impacts sur la sécurité, le réseau ou les dépendances lorsqu'ils existent.

Exemple de description :

```markdown
## Problème

Le dry-run V1 annonçait un modèle différent de celui réellement installé.

## Modification

Correction de la sortie dry-run pour utiliser qwen3:8b.

## Tests

- bash -n : PASS
- --dry-run Linux : PASS
- aucune modification du HOME pendant le dry-run

## Impact

Documentation/comportement uniquement.
Aucune nouvelle dépendance.
```

---

## 📚 Documentation

Une modification du comportement doit être accompagnée de la mise à jour de la documentation pertinente.

Selon le changement, vérifiez notamment :

- `README.md`
- `INSTALLATION.md`
- `MODEL-CARD.md`
- `SECURITY.md`
- `docs/ARCHITECTURE.md`
- `docs/WHY-KALI-LITE.md`

Évitez les affirmations absolues difficiles à garantir.

Préférez par exemple :

```text
Kali-Lite n'ajoute aucune télémétrie.
```

à :

```text
Aucune communication réseau n'est possible.
```

De même, préférez décrire les limites matérielles et logicielles réelles plutôt que promettre une IA « sans limites ».

---

## 🐛 Signaler un bug

Utilisez les Issues du dépôt :

https://github.com/Kalicorp/kalicorp-kali-lite/issues

Le template :

```text
bug_report
```

est prévu pour les anomalies.

Merci d'indiquer si possible :

- version ou commit ;
- système d'exploitation ;
- matériel ;
- commande exécutée ;
- résultat attendu ;
- résultat obtenu ;
- logs utiles sans secret ni donnée personnelle inutile.

---

## 💡 Proposer une fonctionnalité

Utilisez également les Issues du dépôt avec le template :

```text
feature_request
```

Décrivez :

- le besoin ;
- le cas d'usage ;
- la solution proposée ;
- les alternatives éventuelles ;
- les nouvelles dépendances ou permissions nécessaires.

---

## 🔒 Signaler une vulnérabilité

Ne publiez pas de secret ou d'information sensible dans une Issue publique.

Consultez :

[`SECURITY.md`](../SECURITY.md)

ou contactez :

```text
security@kalicorp.fr
```

---

## ⚖️ Licence des contributions

En contribuant au dépôt, vous acceptez que votre contribution soit distribuée sous la licence applicable au projet :

**GNU General Public License v2.0 only (`GPL-2.0-only`)**

Voir :

[`LICENSE`](../LICENSE)

Les modèles et dépendances tierces restent soumis à leurs propres licences.

---

## 🤝 Code de conduite

Les échanges doivent respecter :

[`CODE_OF_CONDUCT.md`](../CODE_OF_CONDUCT.md)

Les désaccords techniques sont normaux.

Ils doivent rester centrés sur :

- les faits ;
- le code ;
- les tests ;
- les risques ;
- les compromis techniques.

---

**Kalicorp — Le Sanctuaire numérique européen**  
Copyright © 2026 Kalicorp
