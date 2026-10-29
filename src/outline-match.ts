import type { Execution, TestStatus } from "./schema.js";
import { testKey } from "./schema.js";
import type { ParsedScenarioResult } from "./ingest.js";

/**
 * Matching of cucumber report elements to stored scenarios, including the
 * examples of a Scenario Outline ("Plan du scénario").
 *
 * A stored outline is named with its placeholders (`Lockout <n>`) whereas
 * cucumber-js names each example with the values substituted (`Lockout 3`).
 * Each example is therefore resolved to its outline, and all examples of one
 * outline are folded into ONE execution of the stored scenario.
 *
 * Aggregation rule (design choice): the outline fails if any example fails;
 * otherwise it is pending if any example is pending; otherwise it passes. The
 * per-example detail (name + status of each non-passing example, and the
 * counts) is kept in the execution `note`, since the Execution model has one
 * status per scenario.
 */

/** Minimal view of a stored (or disk-indexed) scenario needed for matching. */
export interface KnownScenario {
  feature: string;
  name: string;
  tags: string[];
}

/** How a report element was attached to a stored scenario. */
export type MatchHow = "exact" | "outline-name" | "outline-tags" | "none";

export interface ElementMatch {
  result: ParsedScenarioResult;
  /** Stored scenario it resolves to (feature, name), or null when unmatched. */
  target: { feature: string; name: string } | null;
  how: MatchHow;
}

const PARAM_RE = /<[^<>\s][^<>]*>/;

/** Escape a string for literal use inside a RegExp. */
function escapeRe(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/** True when a scenario name contains at least one `<param>` placeholder. */
export function isOutlineName(name: string): boolean {
  return PARAM_RE.test(name);
}

/**
 * Build a regex matching the names of an outline's examples: literal text is
 * kept (whitespace-tolerant), each `<param>` becomes a lazy wildcard.
 *
 * @param name outline name with placeholders, e.g. "Lockout <n>"
 * @returns anchored RegExp, e.g. /^Lockout (.+?)$/
 */
export function outlineNameRegex(name: string): RegExp {
  const parts = name.trim().split(/(<[^<>\s][^<>]*>)/g);
  const body = parts
    .map((p) => (PARAM_RE.test(p) && p.startsWith("<") ? "(.*?)" : escapeRe(p).replace(/\s+/g, "\\s+")))
    .join("");
  return new RegExp(`^${body}$`, "s");
}

/** Number of literal (non-placeholder) characters: higher = more specific outline. */
function literalLength(name: string): number {
  return name.replace(/<[^<>\s][^<>]*>/g, "").trim().length;
}

/** Normalised, sorted tag signature used by the tag fallback. */
function tagSignature(tags: string[]): string {
  return [...new Set(tags.map((t) => t.replace(/^@/, "")))].sort().join(",");
}

/**
 * Resolve every report element to a stored scenario.
 * Order: (1) exact (feature, name); (2) outline of the same feature whose
 * name pattern matches (most specific pattern wins; a tie falls through);
 * (3) fallback: the single outline of the same feature carrying exactly the
 * same tag set (@US/@AC/...) as the element.
 *
 * @param results parsed report elements
 * @param known stored scenarios (or disk-indexed ones when none are stored)
 * @returns one ElementMatch per result, in input order
 */
export function matchElements(results: ParsedScenarioResult[], known: KnownScenario[]): ElementMatch[] {
  const exact = new Set(known.map((k) => testKey(k)));
  const outlinesByFeature = new Map<string, { k: KnownScenario; re: RegExp }[]>();
  for (const k of known) {
    if (!isOutlineName(k.name)) continue;
    const list = outlinesByFeature.get(k.feature) ?? [];
    list.push({ k, re: outlineNameRegex(k.name) });
    outlinesByFeature.set(k.feature, list);
  }

  return results.map((result): ElementMatch => {
    if (exact.has(testKey(result))) {
      return { result, target: { feature: result.feature, name: result.name }, how: "exact" };
    }
    const outlines = outlinesByFeature.get(result.feature) ?? [];
    const hits = outlines.filter((o) => o.re.test(result.name));
    if (hits.length > 0) {
      const best = Math.max(...hits.map((h) => literalLength(h.k.name)));
      const top = hits.filter((h) => literalLength(h.k.name) === best);
      if (top.length === 1) {
        return { result, target: { feature: top[0].k.feature, name: top[0].k.name }, how: "outline-name" };
      }
    }
    const sig = tagSignature(result.tags);
    if (sig) {
      const sameTags = outlines.filter((o) => tagSignature(o.k.tags) === sig);
      if (sameTags.length === 1) {
        const k = sameTags[0].k;
        return { result, target: { feature: k.feature, name: k.name }, how: "outline-tags" };
      }
    }
    return { result, target: null, how: "none" };
  });
}

/** Fold example statuses: any fail -> fail, else any pending -> pending, else pass. */
export function aggregateStatus(statuses: TestStatus[]): TestStatus {
  if (statuses.includes("fail")) return "fail";
  if (statuses.includes("pending") || statuses.length === 0) return "pending";
  return "pass";
}

/**
 * Build the executions to record: one per stored scenario (examples of an
 * outline, or repeated runs of the same name, are aggregated); unmatched
 * elements keep their own (feature, name) as before.
 *
 * @param matches output of matchElements
 * @param base fields stamped on every execution (ranAt, runId, source)
 * @returns executions in first-seen order
 */
export function buildExecutions(
  matches: ElementMatch[],
  base: Pick<Execution, "ranAt" | "runId" | "source">,
): Execution[] {
  const groups = new Map<string, { feature: string; name: string; items: ParsedScenarioResult[] }>();
  matches.forEach((m) => {
    const t = m.target ?? { feature: m.result.feature, name: m.result.name };
    // Unmatched elements are never merged with each other beyond identical names.
    const key = m.target ? testKey(t) : `${testKey(t)}#unmatched`;
    const g = groups.get(key) ?? { ...t, items: [] };
    g.items.push(m.result);
    groups.set(key, g);
  });
  return [...groups.values()].map((g) => {
    const status = aggregateStatus(g.items.map((x) => x.status));
    let note: string | undefined;
    if (g.items.length > 1) {
      const c = (s: TestStatus) => g.items.filter((x) => x.status === s).length;
      const bad = g.items.filter((x) => x.status !== "pass").map((x) => `${x.name} [${x.status}]`);
      note = `${g.items.length} examples: ${c("pass")} pass, ${c("fail")} fail, ${c("pending")} pending`;
      if (bad.length) note += `; not passing: ${bad.slice(0, 20).join(" | ")}${bad.length > 20 ? " | ..." : ""}`;
    }
    return { feature: g.feature, name: g.name, status, ...base, ...(note ? { note } : {}) };
  });
}
