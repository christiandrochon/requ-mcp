/**
 * Deleting a phase or a requirement, with the rules for what points at them.
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
  constructor(version: string) {
    super(
      `Version ${version} is locked: phases and requirements cannot be deleted from it. ` +
        `Create the next version (create_version) and delete there.`,
    );
    this.name = "LockedVersionError";
  }
}

async function assertNotLocked(store: AnyStore): Promise<void> {
  if (await store.isLocked()) throw new LockedVersionError(await store.version());
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
