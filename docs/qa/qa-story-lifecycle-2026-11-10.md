# QA report: story deprecation, restore and deletion (ADR 0004)

- Date: 2026-11-10
- Branch: `feat/story-deprecation-removal`, commits `aedb7e7`, `10e7274`, `065afc4` on top of `998d2d5`
- Artifact: `dist/` rebuilt at 10:39, newer than the sources (10:36); working tree clean before this report.
- Engine: SQLite (harness over HTTP, `dist/index.js`) and a throwaway Postgres 16 (`qa-pg-throwaway`, port 55439, removed afterwards; `requ-mcp-pg` and `requ-mcp-http` were not touched).
- Oracle: the eight acceptance criteria of the request and ADR 0004 (as the stated design intent). No other spec was available.

## Global verdict: PASS (with minor observations, no blocking defect)

No defect was observed in the executed scope. This is not a claim that the feature is defect-free: see "Not verified".

## Evidence executed

| Run | Command | Result |
|---|---|---|
| Dev smoke, SQLite | `npm run smoke:story` | 56 passed, 0 failed (`.logs-local/smoke-story.log`) |
| Dev smoke, SQLite | `npm run smoke:delete` | exit 0 (`.logs-local/smoke-delete.log`) |
| Dev smoke, SQLite | `npm run smoke:versions` | exit 0 (`.logs-local/smoke-versions.log`) |
| Dev smoke, Postgres | `REQU_DELETE_PG_URL=postgres://…:55439/qa npm run smoke:story` | 56 passed, 0 failed; the DB held 19 tables and 7 story rows, so Postgres was really used (`.logs-local/smoke-story-pg.log`) |
| QA reproductions, SQLite | `npx tsx scripts/qa-story-lifecycle-extra.ts` | 49 passed, 0 failed (`.logs-local/qa-extra.log`) |

`smoke:delete` on Postgres was started against the same database the story smoke had already initialised; it failed at "delete before init -> 503" because the DB was no longer empty (status 200). This is a contamination of my own run, not a product defect; it is recorded as NOT RUN on Postgres, not as PASS.

Full suites were not run (machine constraint).

## Criteria

### 1. Deprecate with valid replacedBy: out of find_gaps and coverage, still readable. PASS
- `smoke-story-lifecycle.ts`: find_gaps without US-001/US-004 after deprecation, REST `/api/coverage/gaps` agrees, `get_user_story` and `list_user_stories` (`lifecycle` filter, default `all`) still return it, `workflow status` untouched.
- QA C1: `coverage_report` `storiesTotal` 4 -> 2, `storiesTested` 2 -> 1, `requirementsWithStory` 2 -> 1 after deprecating two stories; traceability, `list_links`, `check_ui_coverage`, `coverage_trend` run without reporting the deprecated stories. Code: `coverage.ts:498` (buildReport filter, also used by findGaps and buildTraceability), `coverage.ts:276`, `screen-coverage.ts:187`.
- Requirement whose stories are all deprecated: reported in `requirementsWithoutStory` (matches ADR).
- `update_user_story` on a deprecated story keeps `lifecycle`; history records the `lifecycle` change.
- Condition "in a draft version": not deprecated stories in locked versions are covered by criterion 5.

### 2. Invalid replacedBy refused without write. PASS
- Unknown id, self, mixed valid+invalid list: `INVALID_REPLACEMENT`, story still `active` (smoke + QA C2). Malformed id (`REQ-001`): refused by the MCP schema, 400 on REST, no write. Replacement pointing to a deleted story: refused. REST without body: no 5xx.
- Code: validation happens before the single `writeStory` (`story-lifecycle.ts`).

### 3. Restore makes the story counted again. PASS
- smoke: US-004 gap again after `restore_user_story`; `replacedBy` cleared, workflow status kept (US-001 `in_progress` preserved through deprecation); restore on an active story is a no-op. REST restore 200.

### 4. Delete in draft: absent in draft, present in locked version; audit, history; references. PASS
- smoke (SQLite and Postgres): after `create_version`, delete in 1.1.0 -> absent there, `get_user_story version=1.0.0` still returns it, `diff_versions` reports it removed.
- Audit entry `delete_user_story` / `story:write` / ok; history of US-003 `deleted`; history of US-001 records the `replacedBy` detach.
- ADR rules observed: screen link dropped and screen kept; other stories' `replacedBy` dropped (QA C3: US-005 stays deprecated with empty `replacedBy` after its replacement is deleted); tagged scenario kept, listed in `danglingScenarios`, and `list_links` then reports the dangling `@US-003` tag.
- Deprecated then deleted: works. Restore on a deleted story: `NOT_FOUND`. Re-creating a deleted id: works and is active; a requirement regains a story.

### 5. Deprecate / delete on a locked version refused. PASS
- MCP and REST: delete and deprecate -> `VERSION_LOCKED` 409 (smoke). QA C5: restore of a deprecated story on a locked version refused, delete refused with the story still readable, deprecate with invalid `replacedBy` refused, delete of an unknown id is an error.

### 6. Non-regression on legacy data. PASS (SQLite only)
- QA C5: `lifecycle` and `replacedBy` removed from the stored JSON of 2 rows with SQL `json_remove`; the stories load as `active` / `[]`, remain counted in find_gaps. After `lock_version`, `update_user_story` status-only on a legacy row succeeds, while a title change is still refused (freeze not weakened). The smoke also checks status-only on a locked pre-existing row.
- Not exercised on Postgres (the raw row edit was written for SQLite). Code path is shared (`UserStory.parse` defaults, `DEFAULTED_FIELDS` in `versioning.ts`).

### 7. RBAC on the three tools and routes. PASS
- Mapping: `rbac.ts` lines 34-36 and 139-140 (`story:write`); smoke asserts it.
- Enforced for real (QA C6, auth mode `ldap`, seeded tokens): a `viewer` and a `qa` principal (no `story:write`, checked through `/api/auth/me`) get denied on the three MCP tools and a 403 on the three REST routes; the story stays untouched; a `maintainer` succeeds on all three, and the denied calls are present in the audit log.

### 8. Code review, edge cases, sqlite/postgres consistency. PASS with observations
- Both stores implement `deleteStory`/`writeStory`/`getStory` identically (`sqlite-store.ts:482-497`, `postgres-store.ts:614-629`), and all new logic is store-agnostic. Story smoke passes on both.
- Requirement with all stories deprecated, replacement deleted afterwards, replacement later deprecated (chain), deprecated then deleted: exercised, behaved as documented.

## Observations (not defects against the stated criteria)

1. Cycles in `replacedBy` are accepted (US-002 -> US-005 -> US-002). The ADR accepts chains and is silent on cycles. Consumers that walk `replacedBy` could loop. Recommendation: decide the rule (reject or document).
2. `deleteStory` (`deletion.ts`) applies the screen and `replacedBy` unlinks one write at a time before the final tombstone, with no transaction; a failure midway leaves a partial cascade. Same pattern as the existing requirement deletion; low probability, recorded in history.
3. `GET /api/stories?lifecycle=<other value>` silently returns all stories (web-api.ts:1389), whereas the MCP schema rejects unknown values. Cosmetic inconsistency.
4. `restore_user_story` on an active story of a locked version returns success (no-op) rather than refusing. Harmless.
5. Weak assertion in my own script: the export check C4 is satisfied by the presence of the word `lifecycle` and does not prove deprecated state survives `import_project`.

## Not verified / residual risk

- Web UI (greyed rendering, filter, buttons in `app.js` and `index.html`): not exercised; no browser was run. Only the REST/MCP behaviour behind it was tested.
- Export then import round trip of `lifecycle`/`replacedBy`: not proven (observation 5).
- Legacy rows on Postgres, and `smoke:delete` / `smoke:versions` on Postgres: not run.
- `openapi/scenarios.yaml` and `src/openapi.ts` contain the new routes (grep only); schema accuracy not validated.
- Concurrency (two writers deprecating/deleting at once): not tested.
- Production data and containers untouched, so behaviour on the real database remains unobserved.

## Tests written

- `scripts/qa-story-lifecycle-extra.ts` (49 assertions, run with `npx tsx scripts/qa-story-lifecycle-extra.ts`).
