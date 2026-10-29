import { Parser, AstBuilder, GherkinClassicTokenMatcher } from "@cucumber/gherkin";
import { IdGenerator } from "@cucumber/messages";
import { declaredLanguage, inferLanguage, keywordsFor, matchKeyword } from "./gherkin-lang.js";

/**
 * Gherkin syntax validation using the official @cucumber/gherkin parser.
 *
 * Stored scenario `content` is a single scenario block (no `Feature:` header), so
 * when it lacks one we wrap it in a synthetic `Feature:` before parsing and offset
 * reported line numbers back. A document that parses but contains anything other
 * than exactly one scenario/scenario-outline is rejected too.
 */

export interface GherkinError {
  message: string;
  line?: number;
  column?: number;
}

export interface GherkinValidation {
  ok: boolean;
  errors: GherkinError[];
}

/**
 * Synthetic wrapper header for a scenario-only snippet, in the snippet's language.
 * @param language dialect code ("en" by default)
 * @returns header text; its line count is the offset to subtract from error lines
 */
function wrapHeader(language: string): string {
  const kw = keywordsFor(language);
  const lang = kw.language === "en" ? "" : `# language: ${kw.language}\n`;
  return `${lang}${kw.feature[0]}: _validation_\n`;
}

interface ParserErrorLike {
  message?: string;
  location?: { line?: number; column?: number };
}

/**
 * Build a parser whose default dialect is `language` (a `# language:` header in
 * the source still overrides it, as in Gherkin itself).
 * @param language dialect code, "en" when omitted
 */
function newParser(language = "en"): Parser<unknown> {
  return new Parser(new AstBuilder(IdGenerator.incrementing()), new GherkinClassicTokenMatcher(language));
}

/** Validate a single scenario's gherkin content. Empty content is considered valid. */
export function validateGherkin(content: string): GherkinValidation {
  const trimmed = content.trim();
  if (trimmed === "") return { ok: true, errors: [] };

  // Wrap unless the content is already a full Feature document.
  // The language comes from `# language: xx` when present, else it is inferred
  // from the first scenario keyword; a full document starts with a Feature keyword.
  const language = keywordsFor(declaredLanguage(content) ?? inferLanguage(content)).language;
  const firstLine = content.split(/\r?\n/).map((l) => l.trim()).find((l) => l !== "" && !l.startsWith("#") && !l.startsWith("@")) ?? "";
  const startsWithFeature = matchKeyword(firstLine, keywordsFor(language).feature) !== null;
  const header = wrapHeader(language);
  const source = startsWithFeature ? content : header + content;
  const offset = startsWithFeature ? 0 : header.split("\n").length - 1;

  const errors: GherkinError[] = [];
  let scenarioCount = 0;
  try {
    const doc = newParser(language).parse(source) as { feature?: { children?: Array<{ scenario?: unknown }> } };
    const children = doc.feature?.children ?? [];
    scenarioCount = children.filter((c) => c.scenario).length;
  } catch (err) {
    const composite = err as { errors?: ParserErrorLike[] } & ParserErrorLike;
    const list: ParserErrorLike[] = composite.errors ?? [composite];
    for (const e of list) {
      const line = e.location?.line;
      errors.push({
        message: e.message ?? String(err),
        line: typeof line === "number" ? Math.max(1, line - offset) : undefined,
        column: e.location?.column,
      });
    }
  }

  if (errors.length === 0 && scenarioCount !== 1) {
    errors.push({
      message:
        scenarioCount === 0
          ? "No scenario found. Content must contain exactly one Scenario or Scenario Outline."
          : `Expected exactly one scenario, found ${scenarioCount}.`,
    });
  }

  return { ok: errors.length === 0, errors };
}
