/**
 * Smoke tests for multilingual Gherkin support: indexConductor (feature scan)
 * and validateGherkin must honour `# language: xx` (French here), keep English
 * as the default, and index a real French feature copied from Lyra.
 * No server needed: calls the modules directly.
 */
import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { indexConductor } from "../src/conductor.js";
import { validateGherkin } from "../src/gherkin.js";

let passed = 0;
let failed = 0;
function check(label: string, cond: boolean, detail?: unknown) {
  if (cond) {
    passed++;
    console.log(`  ✓ ${label}`);
  } else {
    failed++;
    console.error(`  ✗ ${label}`, detail !== undefined ? JSON.stringify(detail) : "");
  }
}

/** Write feature files into a temp conductor project and index it. */
async function indexFiles(files: Record<string, string>) {
  const tmp = await fs.mkdtemp(path.join(os.tmpdir(), "requ-smoke-i18n-"));
  await fs.mkdir(path.join(tmp, "features"), { recursive: true });
  for (const [name, text] of Object.entries(files)) await fs.writeFile(path.join(tmp, "features", name), text);
  return indexConductor(tmp);
}

const FR = `# language: fr
@api @REQ-9
Fonctionnalité: Connexion

  Contexte:
    Soit un utilisateur inscrit

  @US-001
  Scénario: Connexion réussie
    Quand je me connecte
    Alors je suis connecté

  @US-002
  Scenario: Mot de passe erroné
    Quand je me connecte avec un mauvais mot de passe
    Alors je vois une erreur

  @US-003
  Plan du scénario: Verrouillage après <n> échecs
    Quand j'échoue <n> fois
    Alors le compte est verrouillé

    Exemples:
      | n |
      | 3 |
      | 5 |
`;

const EN = `Feature: Auth

  Background:
    Given a registered user

  @US-010
  Scenario: Login ok
    When I log in

  @US-011
  Scenario Outline: Lockout <n>
    When I fail <n> times

    Examples:
      | n |
      | 3 |
`;

async function main() {
  console.log("French inline feature");
  const fr = (await indexFiles({ "fr.feature": FR })).scenarios;
  check("3 scenarios", fr.length === 3, fr.map((s) => s.name));
  check("feature name", fr.every((s) => s.feature === "Connexion"), fr.map((s) => s.feature));
  check("names", fr[0]?.name === "Connexion réussie" && fr[2]?.name.startsWith("Verrouillage"), fr.map((s) => s.name));
  check("story tags", JSON.stringify(fr.map((s) => s.stories)) === '[["US-001"],["US-002"],["US-003"]]', fr.map((s) => s.stories));
  check("feature-level tags inherited", fr.every((s) => s.tags.includes("@api") || s.tags.includes("api")), fr.map((s) => s.tags));
  check("Contexte captured as background", fr.every((s) => s.background.includes("Contexte:")), fr[0]?.background);
  check("outline content keeps Exemples", fr[2]?.content.includes("Exemples:") === true, fr[2]?.content);

  console.log("English regression");
  const en = (await indexFiles({ "en.feature": EN })).scenarios;
  check("2 scenarios", en.length === 2, en.map((s) => s.name));
  check("English stories", JSON.stringify(en.map((s) => s.stories)) === '[["US-010"],["US-011"]]', en.map((s) => s.stories));
  check("English background", en[0]?.background.includes("Background:") === true);

  console.log("Unknown language falls back to English");
  const unk = (await indexFiles({ "x.feature": "# language: xx-nope\n" + EN })).scenarios;
  check("2 scenarios", unk.length === 2, unk.length);

  console.log("Real Lyra fixture (US-101.feature)");
  const dir = path.join(path.dirname(fileURLToPath(import.meta.url)), "fixtures", "features-fr");
  const real = await fs.readFile(path.join(dir, "US-101.feature"), "utf8");
  const lyra = (await indexFiles({ "US-101.feature": real })).scenarios;
  check("4 scenarios", lyra.length === 4, lyra.map((s) => s.name));
  check("all linked to US-101", lyra.every((s) => s.stories.length === 1 && s.stories[0] === "US-101"), lyra.map((s) => s.stories));
  check("AC tags present", ["@AC-3", "@AC-4", "@AC-7", "@AC-6"].every((t, i) => lyra[i]?.tags.some((x) => x.replace(/^@/, "") === t.slice(1))), lyra.map((s) => s.tags));

  console.log("validateGherkin");
  const frScenario = validateGherkin("# language: fr\nScénario: x\n  Soit un truc\n  Alors un autre");
  check("French scenario snippet with header ok", frScenario.ok, frScenario);
  const frInferred = validateGherkin("Scénario: x\n  Soit un truc");
  check("French scenario snippet without header ok", frInferred.ok, frInferred);
  const frOutline = validateGherkin("Plan du Scénario: x <n>\n  Soit <n>\n\n  Exemples:\n    | n |\n    | 1 |");
  check("French outline ok", frOutline.ok, frOutline);
  const enOk = validateGherkin("Scenario: x\n  Given a thing");
  check("English scenario ok", enOk.ok, enOk);
  const bad = validateGherkin("Scénario: x\n  Soit un truc\nScénario: y\n  Soit autre");
  check("two French scenarios rejected", !bad.ok, bad);
  const fullFr = validateGherkin(`# language: fr\nFonctionnalité: F\n\n  Scénario: a\n    Soit b\n`);
  check("full French feature document ok", fullFr.ok, fullFr);

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
