import { z } from "zod";
import {
  OpenAPIRegistry,
  OpenApiGeneratorV31,
  extendZodWithOpenApi,
} from "@asteasolutions/zod-to-openapi";
import { Scenario, UserStory } from "./schema.js";

/**
 * OpenAPI 3.1 contract for the scenario REST API. Component schemas are derived
 * from the same zod models used at runtime (via zod-to-openapi) so the spec can't
 * drift from validation. This document is the contract shared with the tool that
 * runs the scenarios (Conductor).
 */

extendZodWithOpenApi(z);

const ScenarioSummary = z
  .object({
    id: z.string(),
    feature: z.string(),
    name: z.string(),
    tags: z.array(z.string()),
    storyIds: z.array(z.string()),
    requirementIds: z.array(z.string()),
    valid: z.boolean(),
    hasContent: z.boolean(),
    hasBackground: z.boolean(),
    status: z.enum(["pass", "fail", "pending"]).optional(),
    content: z.string().optional(),
    background: z.string().optional(),
  })
  .openapi("ScenarioSummary");

const ScenarioListResponse = z
  .object({
    total: z.number().int(),
    scenarios: z.array(ScenarioSummary),
  })
  .openapi("ScenarioListResponse");

const GherkinValidation = z
  .object({
    ok: z.boolean(),
    errors: z.array(
      z.object({
        message: z.string(),
        line: z.number().int().optional(),
        column: z.number().int().optional(),
      }),
    ),
  })
  .openapi("GherkinValidation");

const TagCount = z.object({ tag: z.string(), count: z.number().int() }).openapi("TagCount");

const ErrorResponse = z.object({ error: z.string() }).openapi("ErrorResponse");

export function buildOpenApiDocument(version = "0.0.0"): object {
  const registry = new OpenAPIRegistry();
  const ScenarioSchema = registry.register("Scenario", Scenario.openapi("Scenario"));
  registry.register("ScenarioSummary", ScenarioSummary);
  registry.register("ScenarioListResponse", ScenarioListResponse);
  registry.register("GherkinValidation", GherkinValidation);
  registry.register("TagCount", TagCount);
  registry.register("ErrorResponse", ErrorResponse);

  const projectParams = {
    project: z.string().optional().openapi({ description: "Project slug (required when >1 project loaded)." }),
    key: z.string().optional().openapi({ description: "Project key (alternative to slug)." }),
  };

  registry.registerPath({
    method: "get",
    path: "/api/scenarios",
    summary: "List/filter scenarios",
    description:
      "Query scenarios by story, requirement, phase, and tags (cucumber tag expressions). " +
      "Filters combine with AND.",
    request: {
      query: z.object({
        ...projectParams,
        story: z.string().optional().openapi({ description: "Story id or comma-separated ids (match any).", example: "US-007" }),
        requirement: z.string().optional().openapi({ description: "Requirement id or comma-separated ids; resolved via its stories.", example: "REQ-001" }),
        phase: z.string().optional().openapi({ description: "Phase id; restricts to in-scope scenarios and annotates per-phase status.", example: "P1" }),
        mode: z.enum(["cumulative", "strict"]).optional().openapi({ description: "Phase resolution mode (default cumulative)." }),
        tags: z.string().optional().openapi({ description: "Cucumber tag expression.", example: "@smoke and not @wip" }),
        feature: z.string().optional().openapi({ description: "Exact feature name." }),
        q: z.string().optional().openapi({ description: "Case-insensitive substring over name/feature/content." }),
        valid: z.enum(["true", "false"]).optional().openapi({ description: "Filter by gherkin validity." }),
        content: z.enum(["true", "false"]).optional().openapi({ description: "Include full gherkin content inline." }),
        limit: z.coerce.number().int().optional(),
        offset: z.coerce.number().int().optional(),
      }),
    },
    responses: {
      200: { description: "Matching scenarios", content: { "application/json": { schema: ScenarioListResponse } } },
      400: { description: "Invalid query (e.g. malformed tag expression)", content: { "application/json": { schema: ErrorResponse } } },
    },
  });

  registry.registerPath({
    method: "get",
    path: "/api/scenarios/{id}",
    summary: "Get one scenario by testKey",
    request: {
      params: z.object({ id: z.string().openapi({ description: "testKey (feature::name), URL-encoded." }) }),
      query: z.object({ ...projectParams }),
    },
    responses: {
      200: { description: "The scenario", content: { "application/json": { schema: ScenarioSchema } } },
      404: { description: "Not found", content: { "application/json": { schema: ErrorResponse } } },
    },
  });

  registry.registerPath({
    method: "get",
    path: "/api/stories/{id}/scenarios",
    summary: "List a story's scenarios (with content)",
    request: {
      params: z.object({ id: z.string().openapi({ example: "US-007" }) }),
      query: z.object({ ...projectParams }),
    },
    responses: {
      200: { description: "Scenarios linked to the story", content: { "application/json": { schema: z.array(ScenarioSummary) } } },
    },
  });

  registry.registerPath({
    method: "get",
    path: "/api/tags",
    summary: "Distinct tags with counts",
    request: { query: z.object({ ...projectParams }) },
    responses: {
      200: { description: "Tags across stored scenarios", content: { "application/json": { schema: z.array(TagCount) } } },
    },
  });

  // --- Story lifecycle (ADR 0004): deprecate / restore / delete, draft version only ---
  const StorySchema = registry.register("UserStory", UserStory.openapi("UserStory"));
  const storyParams = {
    params: z.object({ id: z.string().openapi({ example: "US-007" }) }),
    query: z.object({ ...projectParams }),
  };
  const err = (description: string) => ({ description, content: { "application/json": { schema: ErrorResponse } } });

  registry.registerPath({
    method: "get",
    path: "/api/stories",
    summary: "List stories",
    description: "`lifecycle=active|deprecated` narrows the list; absent or `all` returns every story.",
    request: { query: z.object({ ...projectParams, lifecycle: z.enum(["active", "deprecated", "all"]).optional() }) },
    responses: { 200: { description: "Stories", content: { "application/json": { schema: z.array(StorySchema) } } } },
  });

  registry.registerPath({
    method: "post",
    path: "/api/stories/{id}/deprecate",
    summary: "Deprecate a story",
    description:
      "Keeps the story but excludes it from gaps and coverage. `replacedBy` (optional) must list existing other stories. Working (draft) version only.",
    request: {
      ...storyParams,
      body: { content: { "application/json": { schema: z.object({ replacedBy: z.array(z.string()).optional() }) } } },
    },
    responses: {
      200: { description: "The deprecated story", content: { "application/json": { schema: StorySchema } } },
      400: err("Invalid replacedBy (INVALID_REPLACEMENT)"),
      404: err("Unknown story"),
      409: err("Version is locked (VERSION_LOCKED)"),
    },
  });

  registry.registerPath({
    method: "post",
    path: "/api/stories/{id}/restore",
    summary: "Restore a deprecated story",
    request: storyParams,
    responses: {
      200: { description: "The active story", content: { "application/json": { schema: StorySchema } } },
      404: err("Unknown story"),
      409: err("Version is locked (VERSION_LOCKED)"),
    },
  });

  registry.registerPath({
    method: "delete",
    path: "/api/stories/{id}",
    summary: "Delete a story from the draft version",
    description:
      "Tombstones the story in the working version (a locked version keeps it). Screen links and other stories' replacedBy references are dropped; tagged scenarios are kept and reported as dangling.",
    request: storyParams,
    responses: {
      200: {
        description: "What was deleted and unlinked",
        content: {
          "application/json": {
            schema: z.object({
              deleted: z.boolean(),
              id: z.string(),
              detachedScreens: z.array(z.string()),
              detachedReplacedBy: z.array(z.string()),
              danglingScenarios: z.array(z.string()),
            }),
          },
        },
      },
      404: err("Unknown story"),
      409: err("Version is locked (VERSION_LOCKED)"),
    },
  });

  const generator = new OpenApiGeneratorV31(registry.definitions);
  return generator.generateDocument({
    openapi: "3.1.0",
    info: { title: "requ scenario API", version, description: "Fetch and filter cucumber scenarios owned by requ." },
    servers: [{ url: "/" }],
  });
}
