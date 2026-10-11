/**
 * Smoke test for deleting phases and requirements, over MCP and REST.
 *
 * A deleted phase leaves its requirements, screens and ADRs unassigned rather
 * than taking them with it; a requirement a user story still traces to cannot
 * be deleted; both land in the audit log and the change history; and neither
 * can be deleted from a locked version.
 */
import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import { startHarness, slugFor } from "./lib/http-harness.js";
import { permissionForRoute, permissionForTool } from "../src/auth/rbac.js";

let passed = 0;
let failed = 0;
function check(label: string, cond: boolean, detail?: unknown) {
  if (cond) {
    passed++;
    console.log(`  ✓ ${label}`);
  } else {
    failed++;
    console.error(`  ✗ ${label}`, detail !== undefined ? JSON.stringify(detail) : "");
  }
}

async function http(url: string, init?: RequestInit): Promise<{ status: number; body: any }> {
  const res = await fetch(url, init);
  const text = await res.text();
  let body: any = text;
  try { body = JSON.parse(text); } catch { /* not json */ }
  return { status: res.status, body };
}

async function main() {
  console.log("\n— permissions —");
  check("DELETE /api/phases/:id needs phase:write", permissionForRoute("DELETE", "/api/phases/P1") === "phase:write");
  check("DELETE /api/requirements/:id needs requirement:write", permissionForRoute("DELETE", "/api/requirements/REQ-001") === "requirement:write");
  check("delete_phase needs phase:write", permissionForTool("delete_phase", "spec") === "phase:write");
  check("delete_requirement needs requirement:write", permissionForTool("delete_requirement", "spec") === "requirement:write");

  const tmp = await fs.mkdtemp(path.join(os.tmpdir(), "requ-delete-"));
  const root = path.join(tmp, "proj");
  await fs.mkdir(root, { recursive: true });
  const h = await startHarness([root], "smoke-delete", {
    env: {
      REQU_AUTH_MODE: "disabled",
      REQU_AUDIT: "on",
      REQU_AUTH_DB: path.join(tmp, "auth.db"),
      // Set REQU_DELETE_PG_URL to run the same checks against the Postgres store.
      ...(process.env.REQU_DELETE_PG_URL ? { REQU_PG_URL: process.env.REQU_DELETE_PG_URL } : {}),
    },
  });
  const call = h.call;
  const slug = slugFor(root);
  const api = (p: string) => `${h.base}${p}${p.includes("?") ? "&" : "?"}project=${slug}`;

  try {
    // Before init_project: refused cleanly, and the server must survive it.
    const early = await http(api("/api/phases/P1"), { method: "DELETE" });
    check("REST: delete before init → 503 NOT_INITIALIZED, not a crash", early.status === 503 && early.body.code === "NOT_INITIALIZED", early);
    check("…and the server is still up", (await http(`${h.base}/api/version`)).status === 200);

    const init = await call("init_project", { name: "Delete", initialPhase: "v1.0", force: true });
    if (init.isError) throw new Error(`init_project failed: ${init.raw}`);
    await call("create_phase", { id: "P2", name: "v1.1", activate: true });
    await call("create_phase", { id: "P3", name: "v1.2" });

    await call("create_requirement", { id: "REQ-001", title: "Guests can book", phase: "P2" });
    await call("create_requirement", { id: "REQ-002", title: "Guests can cancel", phase: "P2" });
    await call("create_requirement", { id: "REQ-003", title: "Staff see a calendar", phase: "P1" });
    await call("create_requirement", { id: "REQ-004", title: "Export to CSV", phase: "" });
    await call("create_user_story", { id: "US-001", title: "Book a slot", requirements: ["REQ-001"] });
    await call("create_adr", { title: "Use a calendar library", requirements: ["REQ-003", "REQ-004"], phase: "P2" });

    console.log("\n— delete_phase (MCP) —");
    const del = await call("delete_phase", { id: "P2" });
    check("delete_phase succeeds", !del.isError && del.data.deleted === true, del.data);
    check(
      "it reports the requirements it unassigned",
      JSON.stringify(del.data.unassigned?.requirements) === JSON.stringify(["REQ-001", "REQ-002"]),
      del.data.unassigned,
    );
    check("it reports the ADR it unassigned", del.data.unassigned?.adrs?.length === 1, del.data.unassigned);
    check("it clears the active phase", del.data.clearedActivePhase === true, del.data);

    const phases = await call("list_phases");
    check("the phase is gone", !phases.data.phases.some((p: any) => p.id === "P2"), phases.data);
    check("no active phase is left pointing at it", phases.data.activePhase === null, phases.data.activePhase);

    const reqs = await call("list_requirements");
    const byId = new Map<string, any>(((reqs.data.requirements ?? reqs.data) as any[]).map((r) => [r.id, r]));
    check("its requirements are kept", byId.has("REQ-001") && byId.has("REQ-002"), [...byId.keys()]);
    check("…and unassigned", !byId.get("REQ-001")?.phase && !byId.get("REQ-002")?.phase, byId.get("REQ-001"));
    check("other phases' requirements are untouched", byId.get("REQ-003")?.phase === "P1", byId.get("REQ-003"));

    const again = await call("delete_phase", { id: "P2" });
    check("deleting it again reports deleted:false", !again.isError && again.data.deleted === false, again.data);

    console.log("\n— delete_requirement (MCP) —");
    const blocked = await call("delete_requirement", { id: "REQ-001" });
    check("a requirement linked to a story is refused", blocked.isError === true, blocked.data);
    check("…with the REQUIREMENT_IN_USE code", blocked.data.code === "REQUIREMENT_IN_USE", blocked.data);
    check("…naming the linked story", JSON.stringify(blocked.data.linkedStories) === '["US-001"]', blocked.data);
    check("…and the requirement survives", !(await call("get_requirement", { id: "REQ-001" })).isError);

    const okDel = await call("delete_requirement", { id: "REQ-004" });
    check("an unlinked requirement is deleted", !okDel.isError && okDel.data.deleted === true, okDel.data);
    check("the ADR referencing it is detached", okDel.data.detachedAdrs?.length === 1, okDel.data);
    const adrs = await call("list_adrs");
    const adr = ((adrs.data.adrs ?? adrs.data) as any[])[0];
    check("the ADR keeps its other requirement", JSON.stringify(adr.requirements) === '["REQ-003"]', adr.requirements);
    check("get_requirement no longer finds it", (await call("get_requirement", { id: "REQ-004" })).isError === true);

    console.log("\n— REST —");
    const restBlocked = await http(api("/api/requirements/REQ-001"), { method: "DELETE" });
    check("REST: linked requirement → 409", restBlocked.status === 409, restBlocked);
    check("REST: 409 lists the stories", restBlocked.body.code === "REQUIREMENT_IN_USE" && restBlocked.body.linkedStories?.[0] === "US-001", restBlocked.body);

    const restReq = await http(api("/api/requirements/REQ-002"), { method: "DELETE" });
    check("REST: unlinked requirement → 200", restReq.status === 200 && restReq.body.deleted === true, restReq);
    const restMissing = await http(api("/api/requirements/REQ-002"), { method: "DELETE" });
    check("REST: deleting it again → 404", restMissing.status === 404, restMissing);

    await call("create_requirement", { id: "REQ-005", title: "Reminders", phase: "P3" });
    const restPhase = await http(api("/api/phases/P3"), { method: "DELETE" });
    check("REST: phase delete → 200", restPhase.status === 200 && restPhase.body.deleted === true, restPhase);
    check("REST: it unassigns REQ-005", JSON.stringify(restPhase.body.unassigned?.requirements) === '["REQ-005"]', restPhase.body);
    check("REST: unknown phase → 404", (await http(api("/api/phases/NOPE"), { method: "DELETE" })).status === 404);

    console.log("\n— audit and history —");
    const audit = await http(api("/api/audit?limit=200"));
    const entries: any[] = audit.body.entries ?? [];
    const delPhaseEntry = entries.find((e) => e.action === "delete_phase" && e.outcome === "ok");
    check("audit: delete_phase is recorded", !!delPhaseEntry, entries.map((e) => e.action).slice(0, 15));
    check("audit: …with phase:write", delPhaseEntry?.permission === "phase:write", delPhaseEntry);
    check("audit: the refused delete_requirement is recorded as an error",
      entries.some((e) => e.action === "delete_requirement" && e.outcome === "error"), entries.slice(0, 10));
    check("audit: the REST deletes are recorded",
      entries.some((e) => /^DELETE \/api\/requirements\//.test(e.action)) && entries.some((e) => /^DELETE \/api\/phases\//.test(e.action)),
      entries.map((e) => e.action).slice(0, 15));

    const phaseHist = await http(api("/api/history/phase/P2"));
    check("history: the phase shows as deleted", phaseHist.body.changes?.[0]?.action === "deleted", phaseHist.body.changes?.[0]);
    const reqHist = await http(api("/api/history/requirement/REQ-001"));
    const unassign = (reqHist.body.changes ?? []).find((c: any) => c.action === "updated" && c.changes?.some((f: any) => f.field === "phase"));
    check("history: the unassignment is recorded on the requirement", !!unassign, reqHist.body.changes);
    const reqDelHist = await http(api("/api/history/requirement/REQ-004"));
    check("history: the requirement shows as deleted", reqDelHist.body.changes?.[0]?.action === "deleted", reqDelHist.body.changes?.[0]);

    console.log("\n— locked version —");
    await call("create_phase", { id: "P4", name: "v2" });
    await call("lock_version", {});
    const lockedPhase = await call("delete_phase", { id: "P4" });
    check("MCP: delete_phase with no open draft is refused", lockedPhase.isError === true, lockedPhase.data);
    const lockedReq = await call("delete_requirement", { id: "REQ-003", version: "1.0.0" });
    check("MCP: delete_requirement on a locked version is refused", lockedReq.isError === true, lockedReq.data);
    const restLocked = await http(api("/api/phases/P4"), { method: "DELETE" });
    check("REST: delete on a locked version → 409", restLocked.status === 409 && restLocked.body.code === "VERSION_LOCKED", restLocked);
    check("the phase is still there", (await call("list_phases")).data.phases.some((p: any) => p.id === "P4"));

    await call("create_version", { bump: "minor" });
    const draftDel = await call("delete_phase", { id: "P4" });
    check("in the next draft the phase can be deleted", !draftDel.isError && draftDel.data.deleted === true, draftDel.data);
    const baseline = await call("list_phases", { version: "1.0.0" });
    check("…and the locked baseline still has it", baseline.data.phases.some((p: any) => p.id === "P4"), baseline.data.phases);
  } finally {
    await h.stop();
    await fs.rm(tmp, { recursive: true, force: true });
  }

  console.log(`\n${passed} passed, ${failed} failed`);
  if (failed > 0) process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
