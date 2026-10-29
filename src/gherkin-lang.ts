import { dialects } from "@cucumber/gherkin";

/**
 * Gherkin language support shared by the lightweight feature scanner
 * (conductor.ts) and the syntax validator (gherkin.ts). Keywords come from the
 * dialects shipped with @cucumber/gherkin, never from a hard-coded list.
 */

export const DEFAULT_LANGUAGE = "en";

export interface LanguageKeywords {
  /** Dialect code actually used (falls back to "en" when unknown). */
  language: string;
  feature: readonly string[];
  background: readonly string[];
  /** Scenario + Scenario Outline keywords (Example/Scenario/Plan du scénario...). */
  scenario: readonly string[];
  scenarioOutline: readonly string[];
}

/**
 * Read the `# language: xx` header (only valid among the leading blank/comment/tag
 * lines, as in Gherkin itself). Returns the code as written, or null when absent.
 * @param content raw feature text
 */
export function declaredLanguage(content: string): string | null {
  for (const raw of content.split(/\r?\n/)) {
    const line = raw.trim();
    if (line === "") continue;
    const m = line.match(/^#\s*language\s*:\s*([a-zA-Z-]+)\s*$/);
    if (m) return m[1];
    if (!line.startsWith("#")) return null;
  }
  return null;
}

/**
 * Keywords for a dialect code; unknown or missing codes fall back to English.
 * @param language dialect code such as "fr" (case-sensitive, as in Gherkin)
 * @param lenient also accept the English keywords (used by the indexer, which
 *   must not drop a "Scenario:" typed inside a French file; the validator stays strict)
 */
export function keywordsFor(language: string | null | undefined, lenient = false): LanguageKeywords {
  const code = language && dialects[language] ? language : DEFAULT_LANGUAGE;
  const d = dialects[code];
  const en = dialects[DEFAULT_LANGUAGE];
  const merge = (a: readonly string[], b: readonly string[]) => (lenient && code !== DEFAULT_LANGUAGE ? [...a, ...b] : [...a]);
  return {
    language: code,
    feature: merge(d.feature, en.feature),
    background: merge(d.background, en.background),
    scenario: merge([...d.scenario, ...d.scenarioOutline], [...en.scenario, ...en.scenarioOutline]),
    scenarioOutline: merge(d.scenarioOutline, en.scenarioOutline),
  };
}

/** Lower-case and strip diacritics so "Scenario" matches "Scénario". */
function fold(text: string): string {
  return text.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}

/**
 * If `line` starts with one of `keywords` followed by a colon, return the text
 * after the colon (trimmed, possibly empty); otherwise null. Matching ignores
 * case and accents ("Plan du Scénario" = "plan du scenario"); longest keyword
 * wins so that overlapping keywords cannot truncate each other.
 * @param exact when true, compare case- and accent-sensitively (as Gherkin does)
 * @param line trimmed source line
 * @param keywords dialect keywords (without the colon)
 */
export function matchKeyword(line: string, keywords: readonly string[], exact = false): string | null {
  const sorted = [...keywords].sort((a, b) => b.length - a.length);
  for (const k of sorted) {
    const head = line.slice(0, k.length);
    if (head.length !== k.length || (exact ? head !== k : fold(head) !== fold(k))) continue;
    const rest = line.slice(k.length).trimStart();
    if (rest.startsWith(":")) return rest.slice(1).trim();
  }
  return null;
}

/**
 * Find the dialect of a scenario-only snippet that carries no `# language:`
 * header, by looking at its first keyword line. English wins when it matches.
 * @param content scenario text (tags/comments allowed before the keyword)
 */
export function inferLanguage(content: string): string {
  for (const raw of content.split(/\r?\n/)) {
    const line = raw.trim();
    if (line === "" || line.startsWith("#") || line.startsWith("@")) continue;
    if (matchKeyword(line, keywordsFor(DEFAULT_LANGUAGE).scenario, true) !== null) return DEFAULT_LANGUAGE;
    for (const code of Object.keys(dialects)) {
      if (matchKeyword(line, keywordsFor(code).scenario, true) !== null) return code;
    }
    break;
  }
  return DEFAULT_LANGUAGE;
}
