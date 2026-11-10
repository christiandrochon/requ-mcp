/**
 * Deprecating and restoring a user story.
 *
 * A deprecated story is kept and readable (list/get, greyed in the UI) but no
 * longer counts in gaps or coverage, and may point to the stories that replace
 * it. Shared by the MCP tools and the REST routes so both validate identically.
 * Like every specification edit it only applies to a writable (draft) version:
 * the stores refuse the write on a locked one.
 */
import { assertNotLocked } from "./deletion.js";
import type { UserStory } from "./schema.js";
import type { SqliteStore } from "./sqlite-store.js";
import type { PostgresStore } from "./postgres-store.js";

type AnyStore = SqliteStore | PostgresStore;

/** The request cannot be honoured as stated (unknown story, bad replacement). */
export class StoryLifecycleError extends Error {
  constructor(message: string, readonly code: "NOT_FOUND" | "INVALID_REPLACEMENT") {
    super(message);
    this.name = "StoryLifecycleError";
  }
}

/**
 * Mark a story deprecated, optionally recording which stories replace it.
 * Calling it again on a deprecated story rewrites `replacedBy` (idempotent).
 * Each replacement must be a well-formed id of an existing, non-removed story in
 * this version, and must not be the story itself. Workflow `status` is untouched.
 *
 * @param store store of the working version
 * @param id story to deprecate
 * @param replacedBy ids of the replacing stories (deduplicated); may be empty
 * @returns the stored story
 * @throws StoryLifecycleError NOT_FOUND / INVALID_REPLACEMENT; LockedVersionError on a locked version
 */
export async function deprecateStory(store: AnyStore, id: string, replacedBy: string[] = []): Promise<UserStory> {
  const story = await store.getStory(id);
  if (!story) throw new StoryLifecycleError(`Story ${id} not found.`, "NOT_FOUND");
  await assertNotLocked(store, "deprecated");
  const ids = [...new Set(replacedBy)];
  const bad: string[] = [];
  for (const r of ids) {
    if (r === id || !/^US-\d+$/.test(r) || !(await store.getStory(r))) bad.push(r);
  }
  if (bad.length) {
    throw new StoryLifecycleError(
      `Invalid replacement(s): ${bad.join(", ")}. A replacement must be another existing story of this version.`,
      "INVALID_REPLACEMENT",
    );
  }
  const next: UserStory = { ...story, lifecycle: "deprecated", replacedBy: ids, updatedAt: new Date().toISOString() };
  await store.writeStory(next);
  return next;
}

/**
 * Bring a deprecated story back: lifecycle `active`, `replacedBy` cleared. The
 * workflow status it had is preserved. No-op on a story that is already active.
 *
 * @param store store of the working version
 * @param id story to restore
 * @returns the stored story
 * @throws StoryLifecycleError NOT_FOUND
 */
export async function restoreStory(store: AnyStore, id: string): Promise<UserStory> {
  const story = await store.getStory(id);
  if (!story) throw new StoryLifecycleError(`Story ${id} not found.`, "NOT_FOUND");
  if (story.lifecycle !== "deprecated") return story;
  await assertNotLocked(store, "restored");
  const next: UserStory = { ...story, lifecycle: "active", replacedBy: [], updatedAt: new Date().toISOString() };
  await store.writeStory(next);
  return next;
}
