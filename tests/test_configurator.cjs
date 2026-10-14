/* Tests offline du générateur Kali-Lite. Node.js >= 18, dépendances standard uniquement. */
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = path.resolve(__dirname, "..");
const source = fs.readFileSync(path.join(root, "docs", "configurator.js"), "utf8");
const sandbox = {};
vm.runInNewContext(source, sandbox, { filename: "docs/configurator.js" });
const { MODELS, PLATFORMS, commandSteps } = sandbox.KaliConfigurator;
let checked = 0;

assert.equal(Object.keys(MODELS).length, 5);
assert.equal(Object.keys(PLATFORMS).length, 3);
const docs = fs.readFileSync(path.join(root, "docs", "index.html"), "utf8");
assert.match(docs, /<select name="model" id="model"/);
assert.match(docs, /<select name="os" id="os"/);
assert.match(docs, /<select name="quant" id="quant"/);
assert.match(docs, /src="\.\/configurator\.js"/);
assert.doesNotMatch(source, /\bfetch\s*\(|XMLHttpRequest|sendBeacon|localStorage/);
assert.doesNotMatch(docs, /<script[^>]+src="https?:\/\//);

for (const model of Object.keys(MODELS)) {
  for (const os of Object.keys(PLATFORMS)) {
    for (const quant of ["q4", "q8"]) {
      const r = commandSteps({ model, os, quant });
      assert.equal(r.steps.length, os === "wsl" ? 3 : 2, model + "/" + os);
      assert.ok(r.steps.every(s => s.title && s.shell && s.code && s.help));
      assert.equal(r.branch, MODELS[model].type === "stable" ? "main" : "projet-x");
      assert.ok(r.steps.some(s => s.code.includes("git clone --depth 1 --branch " + r.branch)));
      const all = r.steps.map(s => s.code).join("\n");
      assert.doesNotMatch(all, /curl\s+.*\|\s*(?:sudo\s+)?bash/i, "pas de curl | bash");
      assert.doesNotMatch(all, /git\s+reset\s+--hard|rm\s+-rf|ollama\s+rm|docker\s+stop/i);
      if (os === "mac") {
        assert.doesNotMatch(all, /sudo bash/);
      }
      if (os === "wsl") {
        assert.match(r.steps[0].shell, /PowerShell/);
        assert.match(r.steps[0].code, /wsl --install -d Ubuntu/);
        assert.match(r.steps[1].shell, /WSL2/);
        assert.match(r.note, /pas pris en charge/);
      }
      if (MODELS[model].type === "stable") {
        assert.match(all, /SHA256SUMS/);
        assert.match(all, /--dry-run/);
        assert.match(all, /auto-install-kali-lite-v[12]/);
        if (os === "mac") assert.match(all, /shasum -a 256 -c/);
        else assert.match(all, /sha256sum --check/);
        assert.equal(r.quant, null);
        assert.doesNotMatch(all, /kali-lite-quant.sh/);
      } else {
        const expectedSource = MODELS[model].source[quant];
        const expectedTag = "kali-lite-" + model + "-" + quant;
        assert.ok(all.includes("ollama pull " + expectedSource));
        assert.ok(all.includes("scripts/kali-lite-quant.sh --dry-run " + model + " " + quant));
        assert.ok(all.includes("scripts/kali-lite-quant.sh --create " + model + " " + quant));
        assert.ok(all.includes("ollama run " + expectedTag));
        assert.doesNotMatch(all, /sudo/);
        if (os === "wsl") assert.match(all, /check-wsl2\.sh/);
      }
      checked++;
    }
  }
}
assert.throws(() => commandSteps({ model: "bad", os: "linux" }), /inconnue/);
assert.throws(() => commandSteps({ model: "gemma4-e2b", os: "bad" }), /inconnue/);
assert.throws(() => commandSteps({ model: "gemma4-e2b", os: "linux", quant: "q16" }), /Quantification/);
console.log("PASS : " + checked + " combinaisons moteur/système/quantification, sécurité et source statique.");
