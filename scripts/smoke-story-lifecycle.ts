/**
 * Smoke test for deprecating, restoring and deleting user stories (ADR 0004),
 * over MCP and REST.
 *
 * A deprecated story is kept and readable but drops out of find_gaps and the
 * coverage counts; it can be restored. Deleting a story tombstones it in the
 * draft version only: a locked version refuses the delete and keeps the story.
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

const post = (body?: unknown): RequestInit => ({
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body ?? {}),
});

async function main() {
  console.log("\n— permissions —");
  for (const t of ["deprecate_user_story", "restore_user_story", "delete_user_story", "update_user_story"]) {
    check(`${t} needs story:write`, permissionForTool(t, "spec") === "story:write");
  }
  check("DELETE /api/stories/:id needs story:write", permissionForRoute("DELETE", "/api/stories/US-001") === "story:write");
  check("POST /api/stories/:id/deprecate needs story:write", permissionForRoute("POST", "/api/stories/US-001/deprecate") === "story:write");
  check("POST /api/stories/:id/restore needs story:write", permissionForRoute("POST", "/api/stories/US-001/restore") === "story:write");

  const tmp = await fs.mkdtemp(path.join(os.tmpdir(), "requ-story-"));
  const root = path.join(tmp, "proj");
  await fs.mkdir(root, { recursive: true });
  const h = await startHarness([root], "smoke-story", {
    env: {
      REQU_AUTH_MODE: "disabled",
      REQU_AUDIT: "on",
      REQU_AUTH_DB: path.join(tmp, "auth.db"),
      ...(process.env.REQU_DELETE_PG_URL ? { REQU_PG_URL: process.env.REQU_DELETE_PG_URL } : {}),
    },
  });
  const call = h.call;
  const slug = slugFor(root);
  const api = (p: string) => `${h.base}${p}${p.includes("?") ? "&" : "?"}project=${slug}`;
  const gapIds = (g: any) => [
    ...g.storiesWithoutScenario.map((s: any) => s.id),
    ...g.storiesNotCovered.map((s: any) => s.id),
  ];

  try {
    const init = await call("init_project", { name: "Stories", initialPhase: "P1", force: true });
    if (init.isError) throw new Error(`init_project failed: ${init.raw}`);
    await call("create_requirement", { id: "REQ-001", title: "Guests can book" });
    for (const [id, title] of [["US-001", "Old booking"], ["US-002", "New booking"], ["US-003", "Cancel"], ["US-004", "Export"]]) {
      await call("create_user_story", { id, title, requirements: ["REQ-001"] });
    }
    await call("create_or_update_screen", { id: "SCR-BOOK", name: "Booking", html: "<div>book</div>", stories: [{ id: "US-003" }] });
    await call("create_scenario", { feature: "Booking", name: "Cancel a slot", content: "Scenario: Cancel a slot\n  Given a booking\n  When I cancel\n  Then it is gone", tags: ["@US-003"] });

    console.log("\n— find_gaps before —");
    const before = await call("find_gaps", { phase: "P1" });
    check("all four stories are gaps initially (US-003 has a pending scenario)",
      ["US-001", "US-002", "US-003", "US-004"].every((id) => gapIds(before.data).includes(id)), before.data);

    console.log("\n— deprecate_user_story —");
    const bad = await call("deprecate_user_story", { id: "US-001", replacedBy: ["US-999"] });
    check("unknown replacement is refused", bad.isError === true && bad.data.code === "INVALID_REPLACEMENT", bad.data);
    const self = await call("deprecate_user_story", { id: "US-001", replacedBy: ["US-001"] });
    check("self replacement is refused", self.isError === true && self.data.code === "INVALID_REPLACEMENT", self.data);
    check("…and nothing was written", (await call("get_user_story", { id: "US-001" })).data.lifecycle === "active");
    check("unknown story → NOT_FOUND", (await call("deprecate_user_story", { id: "US-777" })).data.code === "NOT_FOUND");

    await call("update_user_story", { id: "US-001", status: "in_progress" });
    const dep = await call("deprecate_user_story", { id: "US-001", replacedBy: ["US-002", "US-002"] });
    check("deprecation succeeds with a valid replacedBy (deduplicated)",
      !dep.isError && dep.data.lifecycle === "deprecated" && JSON.stringify(dep.data.replacedBy) === '["US-002"]', dep.data);
    check("workflow status is untouched", dep.data.status === "in_progress", dep.data);
    const noRepl = await call("deprecate_user_story", { id: "US-004" });
    check("replacedBy is optional", !noRepl.isError && noRepl.data.replacedBy.length === 0, noRepl.data);

    const after = await call("find_gaps", { phase: "P1" });
    check("deprecated stories are absent from find_gaps",
      !gapIds(after.data).includes("US-001") && !gapIds(after.data).includes("US-004"), after.data);
    check("active stories are still gaps", gapIds(after.data).includes("US-002") && gapIds(after.data).includes("US-003"), after.data);
    const rest = await http(api("/api/coverage/gaps?phase=P1"));
    check("REST /api/coverage/gaps agrees", rest.status === 200 && !gapIds(rest.body).includes("US-001"), rest);

    const all = await call("list_user_stories", {});
    check("list_user_stories keeps deprecated ones by default", ((all.data.stories ?? all.data) as any[]).length === 4, all.data);
    const act = await call("list_user_stories", { lifecycle: "active" });
    check("lifecycle=active hides them", ((act.data.stories ?? act.data) as any[]).map((s: any) => s.id).join() === "US-002,US-003", act.data);
    const onlyDep = await call("list_user_stories", { lifecycle: "deprecated" });
    check("lifecycle=deprecated lists only them", ((onlyDep.data.stories ?? onlyDep.data) as any[]).map((s: any) => s.id).join() === "US-001,US-004", onlyDep.data);
    check("get_user_story still reads a deprecated story", (await call("get_user_story", { id: "US-001" })).data.replacedBy[0] === "US-002");
    const restList = await http(api("/api/stories?lifecycle=deprecated"));
    check("REST list filter works", restList.body.length === 2, restList.body);
    const summary = await http(api("/api/summary"));
    check("summary counts active stories and reports the deprecated ones",
      summary.body.stories === 2 && summary.body.storiesDeprecated === 2, { s: summary.body.stories, d: summary.body.storiesDeprecated });

    console.log("\n— restore_user_story —");
    const res = await call("restore_user_story", { id: "US-004" });
    check("restore clears lifecycle and replacedBy", res.data.lifecycle === "active" && res.data.replacedBy.length === 0, res.data);
    check("a restored story is a gap again", gapIds((await call("find_gaps", { phase: "P1" })).data).includes("US-004"));
    check("restore on an active story is a no-op", !(await call("restore_user_story", { id: "US-004" })).isError);

    console.log("\n— REST deprecate / restore —");
    const restBad = await http(api("/api/stories/US-004/deprecate"), post({ replacedBy: ["US-404"] }));
    check("REST: invalid replacement → 400", restBad.status === 400 && restBad.body.code === "INVALID_REPLACEMENT", restBad);
    const restBad2 = await http(api("/api/stories/US-004/deprecate"), post({ replacedBy: "US-002" }));
    check("REST: non-array replacedBy → 400", restBad2.status === 400, restBad2);
    const restDep = await http(api("/api/stories/US-004/deprecate"), post({ replacedBy: ["US-002"] }));
    check("REST: deprecate → 200", restDep.status === 200 && restDep.body.lifecycle === "deprecated", restDep);
    check("REST: deprecate unknown → 404", (await http(api("/api/stories/US-404/deprecate"), post())).status === 404);
    const restRes = await http(api("/api/stories/US-004/restore"), post());
    check("REST: restore → 200", restRes.status === 200 && restRes.body.lifecycle === "active", restRes);

    console.log("\n— delete_user_story (draft) —");
    await call("deprecate_user_story", { id: "US-001", replacedBy: ["US-003"] });
    const del = await call("delete_user_story", { id: "US-003" });
    check("delete succeeds", !del.isError && del.data.deleted === true, del.data);
    check("it detaches the screen link", JSON.stringify(del.data.detachedScreens) === '["SCR-BOOK"]', del.data);
    check("it drops replacedBy references to it", JSON.stringify(del.data.detachedReplacedBy) === '["US-001"]', del.data);
    check("it reports the now-dangling scenario", del.data.danglingScenarios.length === 1, del.data);
    check("get_user_story no longer finds it", (await call("get_user_story", { id: "US-003" })).isError === true);
    check("the screen is kept without the link", (await call("get_screen", { id: "SCR-BOOK" })).data.stories?.length === 0);
    check("deleting again → not found", (await call("delete_user_story", { id: "US-003" })).isError === true);
    check("REST: delete unknown → 404", (await http(api("/api/stories/US-003"), { method: "DELETE" })).status === 404);

    console.log("\n— audit and history —");
    const audit = await http(api("/api/audit?limit=200"));
    const entries: any[] = audit.body.entries ?? [];
    const e = entries.find((x) => x.action === "delete_user_story" && x.outcome === "ok");
    check("audit: delete_user_story recorded with story:write", !!e && e.permission === "story:write", entries.map((x) => x.action).slice(0, 12));
    check("audit: deprecate_user_story recorded", entries.some((x) => x.action === "deprecate_user_story" && x.outcome === "ok"));
    const hist = await http(api("/api/history/story/US-003"));
    check("history: story shows as deleted", hist.body.changes?.[0]?.action === "deleted", hist.body.changes?.[0]);
    const hist1 = await http(api("/api/history/story/US-001"));
    check("history: the replacedBy detach is recorded on US-001",
      (hist1.body.changes ?? []).some((c: any) => c.changes?.some((f: any) => f.field === "replacedBy")), hist1.body.changes);

    console.log("\n— locked version —");
    await call("lock_version", {});
    check("MCP: delete on a locked version is refused",
      (await call("delete_user_story", { id: "US-002", version: "1.0.0" })).isError === true);
    const restLocked = await http(api("/api/stories/US-002"), { method: "DELETE" });
    check("REST: delete on a locked version → 409 VERSION_LOCKED", restLocked.status === 409 && restLocked.body.code === "VERSION_LOCKED", restLocked);
    const restLockedDep = await http(api("/api/stories/US-002/deprecate"), post());
    check("REST: deprecate on a locked version → 409 VERSION_LOCKED", restLockedDep.status === 409 && restLockedDep.body.code === "VERSION_LOCKED", restLockedDep);
    check("MCP: deprecate on a locked version is refused",
      (await call("deprecate_user_story", { id: "US-002", version: "1.0.0" })).isError === true);
    check("US-002 is still active there", (await call("get_user_story", { id: "US-002", version: "1.0.0" })).data.lifecycle === "active");
    const prog = await call("update_user_story", { id: "US-002", status: "done", version: "1.0.0" });
    check("progress (status) on a locked story still works for pre-existing rows", !prog.isError, prog.data);

    console.log("\n— draft vs locked baseline —");
    await call("create_version", { bump: "minor" });
    const d2 = await call("delete_user_story", { id: "US-002" });
    check("next draft: delete succeeds", !d2.isError && d2.data.deleted === true, d2.data);
    check("next draft: story absent", (await call("get_user_story", { id: "US-002", version: "1.1.0" })).isError === true);
    const base = await call("get_user_story", { id: "US-002", version: "1.0.0" });
    check("locked version still has it", !base.isError && base.data.id === "US-002", base.data);
    const diff = await call("diff_versions", { from: "1.0.0", to: "1.1.0", entity: "stories" });
    check("diff_versions reports it removed", JSON.stringify(diff.data).includes("US-002"), diff.data);
    const dep2 = await call("deprecate_user_story", { id: "US-004" });
    check("next draft: deprecate succeeds", !dep2.isError && dep2.data.lifecycle === "deprecated", dep2.data);
    check("…and the locked version keeps US-004 active", (await call("get_user_story", { id: "US-004", version: "1.0.0" })).data.lifecycle === "active");
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
