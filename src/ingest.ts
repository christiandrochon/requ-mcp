import type { TestStatus } from "./schema.js";

/**
 * Parser for Conductor's run output — the cucumber-js JSON report
 * (`cucumber-js --format json`).
 *
 * Shape (abbreviated):
 *   [ { name: "<feature>", elements: [ { name: "<scenario>", type, steps: [ { result: { status } } ] } ] } ]
 *
 * Each scenario's overall status is derived from its steps.
 */

export interface ParsedScenarioResult {
  feature: string;
  name: string;
  status: TestStatus;
  /** Raw cucumber statuses seen, for debugging. */
  rawStatuses: string[];
  /** Element tags (e.g. "@US-100"), feature-level tags included by cucumber-js. */
  tags: string[];
  /** Cucumber element id (slug), when present. */
  id?: string;
  /** Line of the example/scenario in the .feature file, when present. */
  line?: number;
}

interface CucumberStep {
  result?: { status?: string };
}
interface CucumberElement {
  name?: string;
  type?: string;
  keyword?: string;
  id?: string;
  line?: number;
  tags?: { name?: string }[];
  steps?: CucumberStep[];
}
interface CucumberFeature {
  name?: string;
  uri?: string;
  elements?: CucumberElement[];
}

/*
 * Map the cucumber step statuses of one scenario to our pass/fail/pending.
 *
 * @param stepStatuses raw cucumber step statuses (passed, failed, skipped,
 *   pending, undefined, ambiguous, unknown values), case-insensitive.
 * @returns "fail" if any step failed or is ambiguous; "pass" if there is at
 *   least one step and all passed; otherwise "pending" (not proven yet).
 *
 * Why: an `undefined` step has no step definition, so the scenario was never
 * executed to the end: it has not failed, it is not run yet -> pending. An
 * `ambiguous` step (several matching definitions) is a defect of the test
 * suite itself that must be visible and fixed -> fail. A real `failed` step
 * always wins, even when `undefined` steps are also present.
 */
export function deriveStatus(stepStatuses: string[]): TestStatus {
  const s = stepStatuses.map((x) => x.toLowerCase());
  if (s.some((x) => x === "failed" || x === "ambiguous")) return "fail";
  if (s.length > 0 && s.every((x) => x === "passed")) return "pass";
  // undefined / skipped / pending / unknown, nothing failed -> not yet proven.
  return "pending";
}

/** Parse a cucumber-js JSON report into per-scenario results. */
export function parseCucumberJson(content: string): ParsedScenarioResult[] {
  let data: unknown;
  try {
    data = JSON.parse(content);
  } catch (err) {
    throw new Error(`Not valid JSON: ${(err as Error).message}`);
  }
  if (!Array.isArray(data)) {
    throw new Error("Expected a cucumber-js JSON report (top-level array of features).");
  }

  const results: ParsedScenarioResult[] = [];
  for (const feature of data as CucumberFeature[]) {
    const featureName = feature.name ?? feature.uri ?? "";
    for (const el of feature.elements ?? []) {
      // Skip backgrounds; only real scenarios carry a name worth linking.
      if (el.type && el.type !== "scenario") continue;
      const name = el.name?.trim();
      if (!name) continue;
      const rawStatuses = (el.steps ?? [])
        .map((st) => st.result?.status)
        .filter((x): x is string => typeof x === "string");
      results.push({
        feature: featureName,
        name,
        status: deriveStatus(rawStatuses),
        rawStatuses,
        tags: (el.tags ?? []).map((t) => t.name).filter((x): x is string => typeof x === "string"),
        id: el.id,
        line: el.line,
      });
    }
  }
  return results;
}
