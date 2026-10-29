/**
 * Smoke tests for Scenario Outline example matching on cucumber-js import:
 * the examples of an outline ("Lockout 3") must attach to the stored outline
 * ("Lockout <n>"), be aggregated into one execution, and count in coverage.
 * Covers French and English, then the real Lyra report (298 elements) against
 * the real Lyra features. No server needed: calls the modules directly.
 */
import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { indexConductor } from "../src/conductor.js";
import { parseCucumberJson } from "../src/ingest.js";
import { matchElements, buildExecutions, outlineNameRegex } from "../src/outline-match.js";
import { testKey } from "../src/schema.js";

let passed = 0;
let failed = 0;
function check(label: string, cond: boolean, detail?: unknown) {
  if (cond) { passed++; console.log(`  ✓ ${label}`); }
  else { failed++; console.error(`  ✗ ${label}`, detail !== undefined ? JSON.stringify(detail) : ""); }
}

/** Index feature files written to a temp conductor project. */
async function indexFiles(files: Record<string, string>) {
  const tmp = await fs.mkdtemp(path.join(os.tmpdir(), "requ-smoke-outline-"));
  await fs.mkdir(path.join(tmp, "features"), { recursive: true });
  for (const [n, t] of Object.entries(files)) await fs.writeFile(path.join(tmp, "features", n), t);
  return indexConductor(tmp);
}

/** Build a minimal cucumber-js report. */
function report(feature: string, tags: string[], els: [string, string][]) {
  return JSON.stringify([{
    name: feature,
    elements: els.map(([name, st], i) => ({
      id: `e${i}`, line: i + 1, type: "scenario", name,
      tags: tags.map((t) => ({ name: t })),
      steps: [{ result: { status: st } }],
    })),
  }]);
}

/** Import a report against an index; returns executions and match info. */
function run(index: Awaited<ReturnType<typeof indexFiles>>, content: string) {
  const results = parseCucumberJson(content);
  const matches = matchElements(results, index.scenarios);
  const execs = buildExecutions(matches, { ranAt: new Date().toISOString(), source: "cucumber-json" });
  const linked = new Set(index.scenarios.filter((s) => s.stories.length > 0).map((s) => testKey(s)));
  return { results, matches, execs, linked };
}

const FR = `# language: fr
Fonctionnalité: Auth
  @US-003 @AC-1
  Plan du scénario: Verrouillage après <n> échecs (graine <g>)
    Quand j'échoue <n> fois
    Exemples:
      | n | g |
      | 3 | a |
      | 5 | b |

  @US-004
  Scénario: Simple
    Quand je fais
`;
const EN = `Feature: Auth
  @US-010
  Scenario Outline: Lockout <n>
    When I fail <n> times
    Examples:
      | n |
      | 3 |
      | 5 |
`;

async function main() {
  console.log("regex");
  check("param -> wildcard, literal escaped", outlineNameRegex("A (x) <n>.").test("A (x) 12.") && !outlineNameRegex("A (x) <n>.").test("A (x) 12!"));

  console.log("French outline");
  let r = run(await indexFiles({ "fr.feature": FR }), report("Auth", ["@US-003", "@AC-1"], [
    ["Verrouillage après 3 échecs (graine a)", "passed"], ["Verrouillage après 5 échecs (graine b)", "failed"], ]));
  check("all elements matched", r.matches.every((m) => m.target), r.matches.map((m) => m.how));
  check("one execution, fail if any example fails", r.execs.length === 1 && r.execs[0].status === "fail", r.execs);
  check("execution under the stored name", r.execs[0].name.includes("<n>") && r.linked.has(testKey(r.execs[0])), r.execs[0]);
  check("note keeps per-example detail", /2 examples: 1 pass, 1 fail/.test(r.execs[0].note ?? "") && r.execs[0].note!.includes("graine b"), r.execs[0].note);

  console.log("English outline, all pass + plain scenario unchanged");
  r = run(await indexFiles({ "en.feature": EN }), report("Auth", ["@US-010"], [["Lockout 3", "passed"], ["Lockout 5", "passed"]]));
  check("pass, 1 execution", r.execs.length === 1 && r.execs[0].status === "pass" && r.execs[0].name === "Lockout <n>", r.execs);
  r = run(await indexFiles({ "fr.feature": FR }), report("Auth", [], [["Simple", "passed"]]));
  check("plain exact match, no note", r.execs.length === 1 && r.matches[0].how === "exact" && r.execs[0].note === undefined, r.execs);

  console.log("Tag fallback (renamed example titles)");
  r = run(await indexFiles({ "en.feature": EN }), report("Auth", ["@US-010"], [["Totally different 1", "passed"]]));
  check("matched by tags", r.matches[0].how === "outline-tags" && !!r.matches[0].target, r.matches[0]);

  console.log("Unmatched element stays separate");
  r = run(await indexFiles({ "en.feature": EN }), report("Auth", [], [["Unknown", "passed"]]));
  check("no target", r.matches[0].target === null && r.execs.length === 1 && !r.linked.has(testKey(r.execs[0])));

  console.log("Real Lyra report");
  const dir = path.join(path.dirname(fileURLToPath(import.meta.url)), "fixtures", "lyra-api");
  const index = await indexConductor(dir);
  const lyra = run(index, await fs.readFile(path.join(dir, "cucumber-report.json"), "utf8"));
  const unmatched = lyra.matches.filter((m) => !m.target);
  const toStory = lyra.matches.filter((m) => m.target && lyra.linked.has(testKey(m.target)));
  console.log(`  elements=${lyra.results.length} matched=${lyra.matches.length - unmatched.length} toStory=${toStory.length} executions=${lyra.execs.length}`);
  check("298 elements", lyra.results.length === 298, lyra.results.length);
  check("0 unmatched", unmatched.length === 0, unmatched.map((m) => `${m.result.feature}::${m.result.name}`).slice(0, 5));
  check("298 linked to a story", toStory.length === 298, toStory.length);
  check("every execution is a stored scenario", lyra.execs.every((e) => index.scenarios.some((s) => testKey(s) === testKey(e))));

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed ? 1 : 0);
}
main().catch((e) => { console.error(e); process.exit(1); });
