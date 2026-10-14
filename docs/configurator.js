/* Kali-Lite | générateur local de commandes, sans requête réseau ni télémétrie. GPL-2.0-only */
(function (root) {
  "use strict";

  const REPO = "https://github.com/Kalicorp/kalicorp-kali-lite.git";
  const MODELS = Object.freeze({
    "qwen3-8b": {
      label: "Kali-Lite · Qwen3 8B",
      type: "stable",
      vision: false,
      base: "qwen3:8b",
      tag: "kali-lite",
      script: "auto-install-kali-lite-v1-novision.sh",
      note: "Version de référence · installation Linux/macOS documentée"
    },
    "qwen35-9b": {
      label: "Kali-Lite v2 · Qwen3.5 9B",
      type: "stable",
      vision: true,
      base: "qwen3.5:9b",
      tag: "kali-lite-v2",
      script: "auto-install-kali-lite-v2-vision.sh",
      note: "Version Vision de référence · installation Linux/macOS documentée"
    },
    "mistral-7b": {
      label: "Kali-Lite · Mistral 7B",
      type: "experimental",
      vision: false,
      source: { q4: "mistral:7b-instruct-v0.3-q4_K_M", q8: "mistral:7b-instruct-v0.3-q8_0" }
    },
    "olmo3-7b": {
      label: "Kali-Lite · OLMo 3 7B",
      type: "experimental",
      vision: false,
      source: { q4: "olmo-3:7b-instruct-q4_K_M", q8: "olmo-3:7b-instruct-q8_0" }
    },
    "gemma4-e2b": {
      label: "Kali-Lite · Gemma 4 E2B",
      type: "experimental",
      vision: true,
      source: { q4: "gemma4:e2b-it-q4_K_M", q8: "gemma4:e2b-it-q8_0" }
    }
  });

  const PLATFORMS = Object.freeze({
    linux: "Linux · Ubuntu / Debian / Kali / Arch",
    mac: "macOS · Intel / Apple Silicon",
    wsl: "Windows · Ubuntu sous WSL2 (pilote)"
  });

  function commandSteps(selection) {
    const modelId = selection.model;
    const osId = selection.os;
    const quant = selection.quant || "q4";
    const model = MODELS[modelId];

    if (!model || !Object.hasOwn(PLATFORMS, osId)) {
      throw new RangeError("Sélection de modèle ou de système inconnue.");
    }
    if (model.type === "experimental" && quant !== "q4" && quant !== "q8") {
      throw new RangeError("Quantification inconnue (Q4 ou Q8).");
    }

    const windows = osId === "wsl";
    const mac = osId === "mac";
    const folder = model.type === "stable" ? "kali-lite" : "kali-lite-lab";
    const branch = model.type === "stable" ? "main" : "projet-x";
    const targetFolder = '"$HOME/' + folder + '"';
    const checkout =
      "git clone --depth 1 --branch " + branch + " " + REPO + " " + targetFolder + " &&\n" +
      "cd " + targetFolder;
    const steps = [];

    if (windows) {
      steps.push({
        title: "1 · Préparer Windows",
        shell: "PowerShell administrateur",
        code: "wsl --install -d Ubuntu\nwsl --update\nwsl --list --verbose",
        help: "Redémarrer Windows si demandé. Vérifier que la distribution Ubuntu est bien en version 2 ; la suite s'exécute exclusivement dans Ubuntu WSL2."
      });
    }

    if (model.type === "stable") {
      const hashCheck = mac
        ? "shasum -a 256 -c SHA256SUMS"
        : "sha256sum --check SHA256SUMS";
      steps.push({
        title: (windows ? "2" : "1") + " · Télécharger, vérifier et prévisualiser",
        shell: windows ? "Ubuntu (WSL2)" : mac ? "Terminal macOS" : "Terminal Linux",
        code: checkout + " &&\n" +
          hashCheck + " &&\n" +
          "bash " + model.script + " --dry-run",
        help: "Les empreintes sont celles du dépôt stable main. Lire l'intégralité de " + model.script + " et vérifier le rapport --dry-run avant l'étape suivante."
      });

      steps.push({
        title: (windows ? "3" : "2") + " · Installer après validation humaine",
        shell: windows ? "Ubuntu (WSL2) · pilote" : mac ? "Terminal macOS" : "Terminal Linux",
        code: "cd " + targetFolder + " &&\n" +
          (mac ? "bash " : "sudo bash ") + model.script + " &&\n" +
          "ollama run " + model.tag,
        help: (windows
          ? "ATTENTION : installateur Linux sous WSL2 non homologué sur machine Windows. Tester sur environnement non critique et vérifier les droits, ports et daemon Ollama."
          : mac
            ? "Ne pas utiliser sudo sous macOS. Homebrew doit être disponible ; le script l'utilise pour Ollama."
            : "L'installation Linux écrit dans des chemins système : sudo est demandé par l'installateur stable.")
      });
    } else {
      const source = model.source[quant];
      const tag = "kali-lite-" + modelId + "-" + quant;

      steps.push({
        title: (windows ? "2" : "1") + " · Préparer le laboratoire",
        shell: windows ? "Ubuntu (WSL2)" : mac ? "Terminal macOS" : "Terminal Linux",
        code: checkout + " &&\n" +
          (windows ? "bash scripts/check-wsl2.sh &&\n" : "") +
          "ollama --version &&\n" +
          "bash scripts/kali-lite-quant.sh --dry-run " + modelId + " " + quant,
        help: "Ollama doit être déjà installé et accessible localement. Vérifier les commandes et les licences avant téléchargement. Les modèles expérimentaux n'écrasent pas les tags Kali-Lite stables."
      });
      steps.push({
        title: (windows ? "3" : "2") + " · Télécharger explicitement et créer le profil",
        shell: windows ? "Ubuntu (WSL2) · pilote" : mac ? "Terminal macOS" : "Terminal Linux",
        code: "cd " + targetFolder + " &&\n" +
          "ollama pull " + source + " &&\n" +
          "bash scripts/kali-lite-quant.sh --create " + modelId + " " + quant + " &&\n" +
          "ollama run " + tag,
        help: "Le téléchargement est explicite ; pas de sudo, ni de modification des modèles de production. Utiliser un daemon Ollama local que vous contrôlez."
      });
    }
    const status = windows ? "Pilote non validé matériellement" : model.type === "stable" ? "Parcours documenté" : "Laboratoire expérimental";
    const note = windows
      ? "Windows natif n'est pas pris en charge par les scripts Bash. Cette recette suppose Ubuntu WSL2 et un Ollama Linux installé dans WSL2 (voir docs/WINDOWS-WSL2.md). Les essais Windows via GitHub Actions ne prouvent pas la compatibilité WSL2 réelle."
      : model.type === "stable"
        ? "Modèle de référence. Téléchargement depuis le dépôt main, vérification SHA-256 puis installation volontaire."
        : "Modèle expérimental Q4/Q8 testé par smoke test sur RTX 4090 Ubuntu. Ollama doit être installé et démarré. Pas de garantie de performance en production ni de certification pour toutes les machines.";
    return {
      title: model.label,
      status,
      note,
      vision: model.vision,
      branch,
      quant: model.type === "stable" ? null : quant,
      steps
    };
  }

  root.KaliConfigurator = Object.freeze({ MODELS, PLATFORMS, commandSteps });
})(typeof window !== "undefined" ? window : globalThis);
