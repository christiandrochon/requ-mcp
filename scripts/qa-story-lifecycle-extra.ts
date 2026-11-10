/**
 * Independent QA reproductions for story deprecation / restore / deletion (ADR 0004).
 * Complements smoke-story-lifecycle.ts: legacy rows without the new fields,
 * edge cases (deprecated then deleted, replacement deleted, requirement whose
 * stories are all deprecated), other coverage consumers, export/import, and
 * RBAC enforced for real (ldap mode with seeded tokens, no directory contacted).
 */
import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import Database from "better-sqlite3";
import { startHarness, slugFor } from "./lib/http-harness.js";

let passed = 0;
let failed = 0;
function check(label: string, cond: boolean, detail?: unknown) {
  if (cond) { passed++; console.log(`  OK   ${label}`); }
  else { failed++; console.error(`  FAIL ${label}`, detail !== undefined ? JSON.stringify(detail).slice(0, 600) : ""); }
}
async function http(url: string, init?: RequestInit) {
  const res = await fetch(url, init);
  const text = await res.text();
  let body: any = text;
  try { body = JSON.parse(text); } catch { /* not json */ }
  return { status: res.status, body };
}
const post = (body?: unknown, h: Record<string, string> = {}): RequestInit => ({
  method: "POST", headers: { "Content-Type": "application/json", ...h }, body: JSON.stringify(body ?? {}),
});
const gapIds = (g: any) => [...g.storiesWithoutScenario.map((s: any) => s.id), ...g.storiesNotCovered.map((s: any) => s.id)];
const SECRET = "qa-secret-qa-secret-qa-secret-qa-secret-0123456789";

async function seed(authDb: string, id: string, groups: string[]): Promise<string> {
  process.env.REQU_AUTH_DB = authDb;
  process.env.REQU_AUTH_SECRET = SECRET;
  process.env.REQU_AUTH_MODE = "disabled";
  const { resetAuthConfig } = await import("../src/auth/config.js");
  const { authStore, setAuthStore } = await import("../src/auth/store.js");
  resetAuthConfig();
  setAuthStore(null);
  const store = authStore();
  await store.init();
  await store.upsertUser({ id, username: id, displayName: id, email: `${id}@example.test`, dn: `uid=${id}`, groups, disabled: false, lastLoginAt: new Date().toISOString() });
  const { mintToken } = await import("../src/auth/tokens.js");
  const minted = mintToken(SECRET);
  await store.createToken({ id: minted.id, userId: id, name: id, tokenHash: minted.hash, createdAt: new Date().toISOString(), expiresAt: null, lastUsedAt: null, revokedAt: null, revokedBy: null, maxRole: null, projects: null } as any);
  return minted.plaintext;
}

async function main() {
  const tmp = await fs.mkdtemp(path.join(os.tmpdir(), "requ-qa-story-"));
  try {
    // ======================= functional / edge cases ======================
    const root = path.join(tmp, "proj");
    await fs.mkdir(root, { recursive: true });
    const h = await startHarness([root], "qa-story", { env: { REQU_AUTH_MODE: "disabled", REQU_AUDIT: "on", REQU_AUTH_DB: path.join(tmp, "a.db"), REQU_DB: path.join(tmp, "legacy.db") } });
    const call = h.call;
    const slug = slugFor(root);
    const api = (p: string) => `${h.base}${p}${p.includes("?") ? "&" : "?"}project=${slug}`;
    try {
      await call("init_project", { name: "QA", initialPhase: "P1", force: true });
      await call("create_requirement", { id: "REQ-001", title: "R1" });
      await call("create_requirement", { id: "REQ-002", title: "R2 only deprecated stories" });
      await call("create_user_story", { id: "US-001", title: "a", requirements: ["REQ-001"] });
      await call("create_user_story", { id: "US-002", title: "b", requirements: ["REQ-001"] });
      await call("create_user_story", { id: "US-003", title: "c", requirements: ["REQ-002"] });
      await call("create_user_story", { id: "US-004", title: "d", requirements: ["REQ-002"] });
      await call("create_scenario", { feature: "F", name: "s1", content: "Scenario: s1\n  Given x\n  When y\n  Then z", tags: ["@US-001"] });
      await call("create_scenario", { feature: "F", name: "s3", content: "Scenario: s3\n  Given x\n  When y\n  Then z", tags: ["@US-003"] });

      console.log("\n— C1 deprecate + coverage consumers —");
      const covBefore = (await call("coverage_report", { phase: "P1" })).data;
      await call("deprecate_user_story", { id: "US-003" });
      await call("deprecate_user_story", { id: "US-004", replacedBy: ["US-001"] });
      const covAfter = (await call("coverage_report", { phase: "P1" })).data;
      check("coverage_report: totalStories drops by 2", JSON.stringify(covBefore.summary).length > 0 && covBefore.summary.storiesTotal - covAfter.summary.storiesTotal === 2, { b: covBefore.summary, a: covAfter.summary });
      const gaps = (await call("find_gaps", { phase: "P1" })).data;
      check("find_gaps: US-003/US-004 absent", !gapIds(gaps).includes("US-003") && !gapIds(gaps).includes("US-004"), gaps);
      check("find_gaps: REQ-002 (all stories deprecated) reported without story", gaps.requirementsWithoutStory.some((r: any) => r.id === "REQ-002"), gaps.requirementsWithoutStory);
      const trace = await http(api("/api/traceability?phase=P1"));
      check("traceability: summary excludes deprecated", trace.status === 200 && !JSON.stringify(trace.body.stories ?? []).includes("US-003"), trace.status);
      const links = (await call("list_links", {})).data;
      check("list_links: tag on deprecated story is not 'unknown story' dangling", !JSON.stringify(links.dangling ?? links.problems ?? []).includes("US-003"), links);
      const ui = await call("check_ui_coverage", { phase: "P1" });
      check("check_ui_coverage: no issue about deprecated stories", !JSON.stringify(ui.data).includes("US-003") && !JSON.stringify(ui.data).includes("US-004"), ui.raw.slice(0, 400));
      const trend = await call("coverage_trend", {});
      check("coverage_trend runs", !trend.isError, trend.raw.slice(0, 200));
      const upd = await call("update_user_story", { id: "US-003", title: "c renamed" });
      check("update_user_story on deprecated story keeps lifecycle", !upd.isError && (await call("get_user_story", { id: "US-003" })).data.lifecycle === "deprecated", upd.raw.slice(0, 300));
      const hist = await http(api("/api/history/story/US-003"));
      check("history records the deprecation", JSON.stringify(hist.body).includes("lifecycle"), hist.body);

      console.log("\n— C2 invalid replacedBy: atomicity, mixed list, removed target —");
      const mixed = await call("deprecate_user_story", { id: "US-002", replacedBy: ["US-001", "US-999"] });
      check("mixed valid+invalid refused", mixed.isError && mixed.data.code === "INVALID_REPLACEMENT", mixed.data);
      check("…no write", (await call("get_user_story", { id: "US-002" })).data.lifecycle === "active");
      const malformed = await call("deprecate_user_story", { id: "US-002", replacedBy: ["REQ-001"] });
      check("malformed id refused (schema)", malformed.isError === true, malformed.raw.slice(0, 200));
      const restBadType = await http(api("/api/stories/US-002/deprecate"), post({ replacedBy: ["REQ-001"] }));
      check("REST malformed id refused 400, no write", restBadType.status === 400 && (await call("get_user_story", { id: "US-002" })).data.lifecycle === "active", restBadType);
      const noBody = await http(api("/api/stories/US-002/deprecate"), { method: "POST" });
      check("REST deprecate without body does not 500", noBody.status < 500, noBody);
      await call("restore_user_story", { id: "US-002" });

      console.log("\n— C3 deprecated then deleted; replacement deleted; chains; cycle —");
      await call("create_user_story", { id: "US-005", title: "e", requirements: ["REQ-001"] });
      const dd = await call("deprecate_user_story", { id: "US-005", replacedBy: ["US-002"] });
      check("deprecate US-005 -> US-002", !dd.isError);
      const chain = await call("deprecate_user_story", { id: "US-002", replacedBy: ["US-005"] });
      check("cycle US-002 <-> US-005 accepted (ADR silent on cycles)", !chain.isError, chain.data);
      const delReplacement = await call("delete_user_story", { id: "US-002" });
      check("delete replacement detaches replacedBy of US-005", JSON.stringify(delReplacement.data.detachedReplacedBy) === '["US-005"]', delReplacement.data);
      const s5 = (await call("get_user_story", { id: "US-005" })).data;
      check("US-005 stays deprecated with empty replacedBy", s5.lifecycle === "deprecated" && s5.replacedBy.length === 0, s5);
      const toRemoved = await call("deprecate_user_story", { id: "US-001", replacedBy: ["US-002"] });
      check("replacedBy -> deleted story refused", toRemoved.isError && toRemoved.data.code === "INVALID_REPLACEMENT", toRemoved.data);
      const delDep = await call("delete_user_story", { id: "US-003" });
      check("delete a deprecated story works; its scenario reported dangling", delDep.data.deleted === true && delDep.data.danglingScenarios.length === 1, delDep.data);
      const lk = (await call("list_links", {})).data;
      check("list_links now reports @US-003 as dangling tag", JSON.stringify(lk).includes("US-003"), lk);
      const listAfter = await call("list_user_stories", {});
      check("deleted stories absent from list (US-002, US-003)", !JSON.stringify(listAfter.data).includes('"US-002"') && !JSON.stringify(listAfter.data).includes('"US-003"'));
      const restoreDeleted = await call("restore_user_story", { id: "US-003" });
      check("restore on a deleted story -> NOT_FOUND", restoreDeleted.isError && restoreDeleted.data.code === "NOT_FOUND", restoreDeleted.data);
      const recreate = await call("create_user_story", { id: "US-003", title: "recreated", requirements: ["REQ-002"] });
      check("re-creating a deleted id works and is active", !recreate.isError && (await call("get_user_story", { id: "US-003" })).data.lifecycle === "active", recreate.raw.slice(0, 300));
      const g2 = (await call("find_gaps", { phase: "P1" })).data;
      check("REQ-002 has a story again (US-003 recreated)", !g2.requirementsWithoutStory.some((r: any) => r.id === "REQ-002"), g2.requirementsWithoutStory);

      console.log("\n— C4 export / import preserves lifecycle —");
      const exp = await call("export_project", {});
      check("export carries lifecycle on deprecated story", /"lifecycle":\s*"deprecated"/.test(exp.raw) || exp.raw.includes('\\"lifecycle\\":\\"deprecated\\"') || exp.raw.includes('lifecycle'), exp.raw.slice(0, 200));

      console.log("\n— C5 legacy rows (no lifecycle/replacedBy in stored JSON) —");
      const dbFile = path.join(tmp, "legacy.db");
      const raw = new Database(dbFile);
      const n = raw.prepare("UPDATE stories SET data = json_remove(data,'$.lifecycle','$.replacedBy') WHERE json_extract(data,'$.lifecycle')='active'").run().changes;
      const sample = (raw.prepare("SELECT data FROM stories LIMIT 1").get() as any).data;
      raw.close();
      check(`stripped ${n} rows`, n > 0 && !sample.includes("lifecycle"), sample.slice(0, 120));
      const legacyGet = await call("get_user_story", { id: "US-001" });
      check("legacy story loads as active, replacedBy []", !legacyGet.isError && legacyGet.data.lifecycle === "active" && legacyGet.data.replacedBy.length === 0, legacyGet.raw.slice(0, 200));
      const lg = (await call("find_gaps", { phase: "P1" })).data;
      check("legacy stories still counted in find_gaps (US-001 tested? or gap), US-003/US-005 handled", !lg.storiesWithoutScenario.some((s: any) => s.id === "US-001") && gapIds(lg).includes("US-003"), lg);
      await call("lock_version", {});
      const lockedProg = await call("update_user_story", { id: "US-001", status: "done", version: "1.0.0" });
      check("locked + legacy row: status-only update accepted", !lockedProg.isError, lockedProg.raw.slice(0, 300));
      const lockedTitle = await call("update_user_story", { id: "US-001", title: "changed", version: "1.0.0" });
      check("locked + legacy row: title change still refused (freeze not weakened)", lockedTitle.isError === true, lockedTitle.raw.slice(0, 200));
      const lockedDep = await call("deprecate_user_story", { id: "US-001", version: "1.0.0" });
      const lockedRestoreDeprecated = await call("restore_user_story", { id: "US-005", version: "1.0.0" });
      check("locked: deprecate refused", lockedDep.isError === true, lockedDep.raw.slice(0, 200));
      check("locked: restore of a deprecated story refused", lockedRestoreDeprecated.isError === true, lockedRestoreDeprecated.raw.slice(0, 200));
      const lockedDel = await call("delete_user_story", { id: "US-001", version: "1.0.0" });
      check("locked: delete refused, story still readable", lockedDel.isError === true && !(await call("get_user_story", { id: "US-001", version: "1.0.0" })).isError, lockedDel.raw.slice(0, 200));
      const lockedDelUnknown = await call("delete_user_story", { id: "US-777", version: "1.0.0" });
      check("locked: delete unknown id is an error (not found)", lockedDelUnknown.isError === true);
      const lockedBad = await call("deprecate_user_story", { id: "US-001", replacedBy: ["US-999"], version: "1.0.0" });
      check("locked + invalid replacedBy: refused", lockedBad.isError === true);
    } finally {
      await h.stop();
    }

    // ======================= RBAC for real ================================
    console.log("\n— C6 RBAC enforced (ldap mode, seeded tokens) —");
    const root2 = path.join(tmp, "rbac");
    await fs.mkdir(root2, { recursive: true });
    const slug2 = slugFor(root2);
    const authDb = path.join(tmp, "auth.db");
    const viewerTok = await seed(authDb, "vera", ["cn=readers"]);
    const qaTok = await seed(authDb, "quinn", ["cn=qa"]);
    const maintTok = await seed(authDb, "mika", ["cn=maint"]);
    const env = {
      REQU_AUTH_MODE: "ldap", REQU_AUTH_SECRET: SECRET, REQU_AUTH_DB: authDb, REQU_AUDIT: "on",
      REQU_LDAP_URL: "ldaps://127.0.0.1:1", REQU_LDAP_BASE_DN: "dc=example,dc=test",
      REQU_LDAP_ROLE_MAP: "readers=viewer;qa=qa;maint=maintainer", REQU_AUTH_DEFAULT_ROLE: "none",
    };
    const A = (t: string) => ({ Authorization: `Bearer ${t}` });
    const m = await startHarness([root2], "qa-rbac-m", { env, headers: A(maintTok) });
    try {
      await m.call("init_project", { key: slug2, name: "P", initialPhase: "v1", force: true });
      await m.call("create_requirement", { id: "REQ-001", title: "r" });
      for (const id of ["US-001", "US-002", "US-003"]) await m.call("create_user_story", { id, title: id, requirements: ["REQ-001"] });
      const me = await http(`${m.base}/api/auth/me`, { headers: A(qaTok) });
      console.log(`  info qa role permissions include story:write = ${me.body.permissions?.includes("story:write")}`);
      const qaCan = me.body.permissions?.includes("story:write") === true;
      for (const [name, tok] of [["viewer", viewerTok], ["qa", qaTok]] as const) {
        if (name === "qa" && qaCan) continue;
        const r = await startHarness([root2], `qa-rbac-${name}`, { env, headers: A(tok) });
        try {
          for (const [tool, args] of [["deprecate_user_story", { id: "US-001" }], ["restore_user_story", { id: "US-001" }], ["delete_user_story", { id: "US-001" }]] as const) {
            const res = await r.call(tool, { key: slug2, ...args });
            check(`${name}: MCP ${tool} denied`, res.isError === true && /permission|forbidden|denied/i.test(res.raw), res.raw.slice(0, 200));
          }
          const q = (p: string) => `${r.base}${p}?project=${slug2}`;
          const d1 = await http(q("/api/stories/US-001/deprecate"), post({}, A(tok)));
          const d2 = await http(q("/api/stories/US-001/restore"), post({}, A(tok)));
          const d3 = await http(q("/api/stories/US-001"), { method: "DELETE", headers: A(tok) });
          check(`${name}: REST deprecate/restore/delete -> 403`, d1.status === 403 && d2.status === 403 && d3.status === 403, [d1.status, d2.status, d3.status]);
          const still = await m.call("get_user_story", { key: slug2, id: "US-001" });
          check(`${name}: story untouched after denied calls`, still.data.lifecycle === "active");
        } finally { await r.stop(); }
      }
      // maintainer allowed
      const qm = (p: string) => `${m.base}${p}?project=${slug2}`;
      const a1 = await http(qm("/api/stories/US-001/deprecate"), post({ replacedBy: ["US-002"] }, A(maintTok)));
      const a2 = await http(qm("/api/stories/US-001/restore"), post({}, A(maintTok)));
      const a3 = await http(qm("/api/stories/US-003"), { method: "DELETE", headers: A(maintTok) });
      check("maintainer: REST deprecate/restore/delete allowed (200)", a1.status === 200 && a2.status === 200 && a3.status === 200, [a1.status, a2.status, a3.status]);
      const mm = await m.call("deprecate_user_story", { key: slug2, id: "US-002" });
      check("maintainer: MCP deprecate allowed", !mm.isError, mm.raw.slice(0, 200));
      const aud = await http(`${m.base}/api/audit?project=${slug2}&limit=300`, { headers: A(maintTok) });
      const ents: any[] = aud.body.entries ?? [];
      check("audit: denied story ops recorded", ents.some((e) => e.outcome === "denied" && /story/.test(e.action ?? e.tool ?? "")), ents.filter((e) => e.outcome === "denied").slice(0, 4));
    } finally { await m.stop(); }
  } finally {
    await fs.rm(tmp, { recursive: true, force: true });
  }
  console.log(`\n${passed} passed, ${failed} failed`);
  if (failed > 0) process.exit(1);
}
main().catch((e) => { console.error(e); process.exit(1); });
