/**
 * Deleting a phase, a requirement or a user story, with the rules for what points at them.
 *
 * Shared by the MCP tools and the REST routes so both refuse and cascade the
 * same way. Every write goes through the store it is handed — callers pass the
 * recording store, so each unassignment lands in the change history alongside
 * the delete itself.
 */
import type { SqliteStore } from "./sqlite-store.js";
import type { PostgresStore } from "./postgres-store.js";

type AnyStore = SqliteStore | PostgresStore;

/** A delete refused because something still depends on the target. */
export class InUseError extends Error {
  constructor(
    message: string,
    readonly code: string,
    readonly linked: Record<string, string[]>,
  ) {
    super(message);
    this.name = "InUseError";
  }
}

/** A delete aimed at a locked version. Raised before anything is written, so a
 *  cascade never half-applies. */
export class LockedVersionError extends Error {
  constructor(version: string, action = "deleted") {
    super(
      `Version ${version} is locked: phases, requirements and user stories cannot be ${action} in it. ` +
        `Create the next version (create_version) and make the change there.`,
    );
    this.name = "LockedVersionError";
  }
}

/** Refuse a specification edit on a locked version (shared with story-lifecycle). */
export async function assertNotLocked(store: AnyStore, action = "deleted"): Promise<void> {
  if (await store.isLocked()) throw new LockedVersionError(await store.version(), action);
}

export interface PhaseDeletion {
  deleted: boolean;
  id: string;
  /** What used to sit on the phase and now has none. */
  unassigned: { requirements: string[]; screens: string[]; adrs: string[] };
  /** True when the phase was the project's active phase and no longer is. */
  clearedActivePhase: boolean;
}

/**
 * Delete a phase, moving everything assigned to it back to unassigned. The
 * requirements, screens and ADRs themselves are kept. Recorded executions keep
 * their phase id: they are a record of what ran, and coverage already reports
 * an unknown phase as unassigned.
 */
export async function deletePhase(store: AnyStore, id: string): Promise<PhaseDeletion> {
  const result: PhaseDeletion = {
    deleted: false,
    id,
    unassigned: { requirements: [], screens: [], adrs: [] },
    clearedActivePhase: false,
  };
  if (!(await store.getPhase(id))) return result;
  await assertNotLocked(store);

  const stamp = new Date().toISOString();
  for (const r of await store.listRequirements()) {
    if (r.phase !== id) continue;
    await store.writeRequirement({ ...r, phase: undefined, updatedAt: stamp });
    result.unassigned.requirements.push(r.id);
  }
  for (const s of await store.listScreens()) {
    if (s.phase !== id) continue;
    await store.writeScreen({ ...s, phase: undefined, updatedAt: stamp });
    result.unassigned.screens.push(s.id);
  }
  for (const a of await store.listAdrs()) {
    if (a.phase !== id) continue;
    await store.writeAdr({ ...a, phase: undefined, updatedAt: stamp });
    result.unassigned.adrs.push(a.id);
  }

  result.deleted = await store.deletePhase(id);

  // The active phase is a project-wide pointer; only drop it when the phase is
  // gone from the version the project is working on, not from some other draft.
  const cfg = await store.readConfig();
  const working = cfg.currentVersion ?? cfg.draftVersion;
  if (cfg.activePhase === id && (!working || working === (await store.version()))) {
    await store.writeConfig({ ...cfg, activePhase: undefined });
    result.clearedActivePhase = true;
  }
  return result;
}

export interface RequirementDeletion {
  deleted: boolean;
  id: string;
  /** ADRs that referenced the requirement and no longer do. */
  detachedAdrs: string[];
}

/**
 * Delete a requirement, refusing while any user story is linked to it: a story
 * must trace to at least one requirement, and silently orphaning one would
 * lose that traceability. ADR references are dropped, not blocking.
 */
export async function deleteRequirement(store: AnyStore, id: string): Promise<RequirementDeletion> {
  const result: RequirementDeletion = { deleted: false, id, detachedAdrs: [] };
  if (!(await store.getRequirement(id))) return result;

  const linked = (await store.listStories()).filter((s) => s.requirements.includes(id)).map((s) => s.id);
  if (linked.length) {
    throw new InUseError(
      `Requirement ${id} is linked to ${linked.length} user stor${linked.length === 1 ? "y" : "ies"} ` +
        `(${linked.join(", ")}). Unlink or re-point those stories first.`,
      "REQUIREMENT_IN_USE",
      { linkedStories: linked },
    );
  }
  await assertNotLocked(store);

  const stamp = new Date().toISOString();
  for (const a of await store.listAdrs()) {
    if (!a.requirements.includes(id)) continue;
    await store.writeAdr({ ...a, requirements: a.requirements.filter((r) => r !== id), updatedAt: stamp });
    result.detachedAdrs.push(a.id);
  }

  result.deleted = await store.deleteRequirement(id);
  return result;
}

export interface StoryDeletion {
  deleted: boolean;
  id: string;
  /** Screens that linked the story and no longer do (the screens are kept). */
  detachedScreens: string[];
  /** Deprecated stories whose `replacedBy` pointed at the story and no longer do. */
  detachedReplacedBy: string[];
  /** Scenarios still tagged with the story id. They are kept: the tag lives in
   *  the feature file, so it now shows up as a dangling tag in traceability. */
  danglingScenarios: string[];
}

/**
 * Delete a user story from the working (draft) version: the row becomes a
 * tombstone, so a locked ancestor version still holds it and `diff_versions`
 * reports it as removed. Refused on a locked version, before anything is written.
 *
 * What pointed at the story: screen links are dropped (screens kept);
 * `replacedBy` references on other stories are dropped; scenarios tagged with
 * the id are left untouched and reported as dangling; acceptance criteria go
 * with the story. Not blocked by those references: unlike a requirement, a story
 * is a leaf of the trace chain. Every write goes through the recording store, so
 * each unlink lands in the change history next to the delete.
 *
 * @param store the (recording) store of the working version
 * @param id story id, e.g. "US-012"
 * @returns what was deleted and what was unlinked; `deleted:false` if unknown
 * @throws LockedVersionError when the version is locked
 */
export async function deleteStory(store: AnyStore, id: string): Promise<StoryDeletion> {
  const result: StoryDeletion = { deleted: false, id, detachedScreens: [], detachedReplacedBy: [], danglingScenarios: [] };
  if (!(await store.getStory(id))) return result;
  await assertNotLocked(store);

  const stamp = new Date().toISOString();
  for (const sc of await store.listScreens()) {
    if (!sc.stories.some((l) => l.id === id)) continue;
    const storyVersions = { ...sc.storyVersions };
    delete storyVersions[id];
    await store.writeScreen({ ...sc, stories: sc.stories.filter((l) => l.id !== id), storyVersions, updatedAt: stamp });
    result.detachedScreens.push(sc.id);
  }
  for (const s of await store.listStories()) {
    if (s.id === id || !s.replacedBy.includes(id)) continue;
    await store.writeStory({ ...s, replacedBy: s.replacedBy.filter((r) => r !== id), updatedAt: stamp });
    result.detachedReplacedBy.push(s.id);
  }
  for (const sc of await store.listScenarios()) {
    if (sc.stories.includes(id)) result.danglingScenarios.push(sc.testKey);
  }

  result.deleted = await store.deleteStory(id);
  return result;
}
