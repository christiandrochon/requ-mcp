# 4. Story deprecation and removal

- **Status:** accepted
- **Date:** 2026-11-10

## Context

Requirements can be deprecated or deleted. Stories could not: they only had a
workflow `status` (draft / ready / in_progress / done) and no tool or route to
remove one. A project whose stories became obsolete kept counting them in
`find_gaps` and coverage, so the numbers could never reach "no gaps". Editing
the stored data by hand was the only way out.

Versions are copy-on-write: a locked version is immutable, changes happen in the
draft. The tombstone field `removed` already exists on every versioned entity.

## Decision

**Deprecation is a separate field, not a new `StoryStatus` value.** A story gets
`lifecycle: "active" | "deprecated"` (default `active`) and
`replacedBy: string[]` (default `[]`).

- It mirrors `RequirementStatus` (`active | deprecated`) in values and meaning,
  which is the closest existing precedent.
- It is orthogonal to the workflow status. Adding `deprecated` to `StoryStatus`
  would overwrite the progress a story had reached, so a restore could not
  bring it back; `lifecycle` keeps `status` intact.
- Data stored before the fields existed parses to the defaults. The freeze check
  on locked versions treats a missing `lifecycle` / `replacedBy` as the default
  (same mechanism as `removed`), so status updates on old locked rows are not
  mistaken for a specification change.

**Effect of deprecation.** The story stays readable (`get`, `list`, with a
`lifecycle` filter, default `all` so existing callers see no change) and the web
UI greys it with its replacement. It is excluded from `find_gaps`,
`buildReport` (hence coverage, trend, traceability summary) and the UI/screen
coverage check, and from the per-phase story counts. Scenarios tagged with it
are not reported as dangling tags. A requirement whose only story is deprecated
is reported as having no story: the replacement must trace to it.
`replacedBy` is optional but validated when given: each id must be an existing
story of the same version other than the story itself. A replacement that is
itself deprecated is accepted (chains are legitimate). Restoring clears
`replacedBy` and is a no-op on an active story.

**Deletion reuses the tombstone.** `delete_user_story` sets `removed` in the
working version, so the locked ancestor keeps the story and `diff_versions`
reports it removed. A locked version is refused before anything is written, with
the same `LockedVersionError` as `deletion.ts`. Unlike a requirement, a story is a
leaf of the trace chain, so references do not block the delete:
screen links and other stories' `replacedBy` entries are dropped (each as a
recorded write); scenarios tagged with the id are left alone, because the tag
lives in the feature file, and are listed in the response and shown as dangling
tags by traceability. Acceptance criteria belong to the story and go with it.

**Deprecate and restore are specification edits**, frozen on a locked version
(`lifecycle` and `replacedBy` are not in the freeze matrix's mutable list). To
obsolete a story of a locked baseline, create the next version and do it there.

**Permissions.** All three tools and the REST routes need `story:write`, the
permission of `update_user_story`. (`delete_requirement` needs
`requirement:write` because it edits a requirement; the story tools edit a story.)

## Consequences

- No migration. Old rows load as active.
- Version carry-over fingerprints include the new fields, so deprecating a story
  stops its earlier results carrying over; it is excluded from coverage anyway.
- The old-version/new-version deployment case: a pre-upgrade server reading
  rows that carry the new fields ignores them (zod object strips unknown keys),
  so a rollback hides deprecation but loses no data.
