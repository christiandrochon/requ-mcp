/**
 * Unit-style checks for the cucumber step status -> scenario status mapping
 * (deriveStatus) and for its use by parseCucumberJson. No server needed.
 */
import { deriveStatus, parseCucumberJson } from "../src/ingest.js";

let passed = 0;
let failed = 0;
/**
 * Record one assertion.
 * @param label description of the check
 * @param actual value obtained
 * @param expected value expected
 */
function eq(label: string, actual: unknown, expected: unknown) {
  if (actual === expected) { passed++; console.log(`  ✓ ${label}`); }
  else { failed++; console.error(`  ✗ ${label}: got ${String(actual)}, expected ${String(expected)}`); }
}

eq("all passed -> pass", deriveStatus(["passed", "passed"]), "pass");
eq("one failed -> fail", deriveStatus(["passed", "failed", "skipped"]), "fail");
eq("undefined without failed -> pending", deriveStatus(["passed", "undefined", "skipped"]), "pending");
eq("only undefined -> pending", deriveStatus(["undefined"]), "pending");
eq("failed + undefined -> fail", deriveStatus(["failed", "undefined"]), "fail");
eq("undefined before failed -> fail", deriveStatus(["undefined", "failed"]), "fail");
eq("skipped alone -> pending", deriveStatus(["skipped"]), "pending");
eq("pending alone -> pending", deriveStatus(["pending"]), "pending");
eq("passed + pending -> pending", deriveStatus(["passed", "pending"]), "pending");
eq("ambiguous -> fail (suite defect)", deriveStatus(["passed", "ambiguous"]), "fail");
eq("no steps -> pending", deriveStatus([]), "pending");
eq("case-insensitive", deriveStatus(["PASSED", "Undefined"]), "pending");

const report = JSON.stringify([{
  name: "F",
  elements: [
    { id: "a", type: "scenario", name: "undef", steps: [{ result: { status: "passed" } }, { result: { status: "undefined" } }] },
    { id: "b", type: "scenario", name: "mixed", steps: [{ result: { status: "failed" } }, { result: { status: "undefined" } }] },
  ],
}]);
const parsed = parseCucumberJson(report);
eq("report: undefined scenario -> pending", parsed.find((r) => r.name === "undef")?.status, "pending");
eq("report: failed+undefined scenario -> fail", parsed.find((r) => r.name === "mixed")?.status, "fail");

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
