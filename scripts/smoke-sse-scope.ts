/**
 * Regression suite for the dashboard's live-update stream (GET /events).
 *
 * Bug: after picking another baseline in the version selector (or switching
 * project), the browser kept the event stream it opened at boot, still scoped
 * to the old version/project. Every 5 s tick then carried a summary whose list
 * fingerprints differed from the one on screen, so the dashboard re-fetched the
 * requirement list, coverage, trend and gaps on every tick: the Requirements
 * table and the Overview cards were torn down and rebuilt ("the page keeps
 * refreshing").
 *
 * The dashboard is vanilla JS run by Alpine, so this suite loads the real
 * src/public/app.js in a Node VM with minimal browser stubs, points its fetches
 * at a real server, and feeds it the summaries the real /events stream sends.
 * Invariant checked: the stream is always scoped exactly like the panels'
 * reads, and an unchanged project produces no re-fetch on a tick.
 */
import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import vm from "node:vm";
import { repoRoot, slugFor, startHarness } from "./lib/http-harness.js";

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

/** A stand-in EventSource: records its URL; the suite delivers messages itself. */
class FakeEventSource {
  static all: FakeEventSource[] = [];
  static openCount() { return FakeEventSource.all.filter((e) => !e.closed).length; }
  url: string;
  closed = false;
  onmessage: ((e: { data: string }) => void) | null = null;
  onerror: (() => void) | null = null;
  constructor(url: string) {
    this.url = url;
    FakeEventSource.all.push(this);
  }
  close() { this.closed = true; }
}

/** Instantiate the dashboard component from the real app.js, wired to `base`. */
async function loadComponent(base: string): Promise<any> {
  const src = await fs.readFile(path.join(repoRoot, "src", "public", "app.js"), "utf8");
  let onInit: (() => void) | null = null;
  let factory: (() => any) | null = null;
  const absolute = (u: string) => (/^https?:/.test(u) ? u : base + u);
  const window: any = {
    fetch: (u: string, init?: RequestInit) => fetch(absolute(u), init),
    addEventListener: () => {},
    location: { pathname: "/", search: "", origin: base, href: base + "/" },
    matchMedia: () => ({ matches: false }),
  };
  const sandbox: any = {
    window,
    document: {
      addEventListener: (ev: string, cb: () => void) => { if (ev === "alpine:init") onInit = cb; },
      querySelector: () => null,
      querySelectorAll: () => [],
      getElementById: () => null,
    },
    Alpine: { data: (_name: string, f: () => any) => { factory = f; } },
    EventSource: FakeEventSource,
    location: window.location,
    history: { state: null, pushState() {}, replaceState() {} },
    URLSearchParams,
    console,
    setTimeout,
    clearTimeout,
    requestAnimationFrame: (f: () => void) => setTimeout(f, 0),
  };
  vm.runInNewContext(src, sandbox, { filename: "app.js" });
  if (!onInit) throw new Error("app.js did not register an alpine:init handler");
  (onInit as () => void)();
  if (!factory) throw new Error("app.js did not register requApp");
  const comp = (factory as () => any)();
  // Alpine magics the code paths below touch.
  comp.$watch = () => {};
  comp.$nextTick = (f: () => void) => { if (f) f(); };
  comp.$refs = {};
  return comp;
}

/** The first summary the real server sends on an /events URL. */
async function firstEvent(base: string, url: string): Promise<string> {
  const ac = new AbortController();
  const res = await fetch(base + url, { signal: ac.signal });
  if (!res.ok || !res.body) throw new Error(`${url} → HTTP ${res.status}`);
  const reader = res.body.getReader();
  const dec = new TextDecoder();
  let buf = "";
  try {
    for (;;) {
      const { value, done } = await reader.read();
      if (done) throw new Error("stream ended before the first event");
      buf += dec.decode(value, { stream: true });
      const m = /^data: (.*)$/m.exec(buf);
      if (m) return m[1];
    }
  } finally {
    ac.abort();
  }
}

const RELOADERS = [
  "loadRequirements", "loadStories", "loadComponents", "loadPhases", "loadVcsRefs",
  "loadAdrs", "loadCoverage", "loadTrend", "loadGaps", "loadSummary",
];

/** Replace the list loaders with counters; returns the tally. */
function countReloads(comp: any): Record<string, number> {
  const calls: Record<string, number> = {};
  for (const name of RELOADERS) {
    calls[name] = 0;
    comp[name] = async () => { calls[name]++; };
  }
  return calls;
}

/** Deliver `ticks` real stream ticks to the component's open stream. */
async function tick(base: string, comp: any, ticks: number) {
  const es: FakeEventSource = comp._sse;
  for (let i = 0; i < ticks; i++) {
    const data = await firstEvent(base, es.url);
    es.onmessage?.({ data });
    await new Promise((r) => setTimeout(r, 0));
  }
}

async function seed(root: string) {
  await fs.mkdir(path.join(root, "features"), { recursive: true });
  await fs.writeFile(path.join(root, "features", "placeholder.feature"), "Feature: Placeholder\n");
}

async function main() {
  const rootA = await fs.mkdtemp(path.join(os.tmpdir(), "requ-sse-a-"));
  const rootB = await fs.mkdtemp(path.join(os.tmpdir(), "requ-sse-b-"));
  const rootC = await fs.mkdtemp(path.join(os.tmpdir(), "requ-sse-c-"));
  await seed(rootA);
  await seed(rootB);
  await seed(rootC);
  const h = await startHarness([rootA, rootB, rootC], "smoke-sse-scope");
  const keyA = slugFor(rootA);
  const keyB = slugFor(rootB);
  const keyC = slugFor(rootC);

  try {
    // Project A: 1.0.0 locked (current), 1.1.0 an open draft that differs from it.
    await h.callOn(keyA, "init_project", { name: "SSE A", conductorPath: ".", initialPhase: "P1" });
    for (let i = 1; i <= 3; i++) {
      await h.callOn(keyA, "create_requirement", { id: `REQ-00${i}`, title: `Requirement ${i}`, phase: "P1" });
    }
    await h.callOn(keyA, "lock_version", {});
    await h.callOn(keyA, "create_version", {});
    await h.callOn(keyA, "create_requirement", { id: "REQ-100", title: "Only in the draft", phase: "P1" });
    // Project B: two versions too, so a stale ?version= from A would resolve here.
    await h.callOn(keyB, "init_project", { name: "SSE B", conductorPath: ".", initialPhase: "P1" });
    await h.callOn(keyB, "create_requirement", { id: "REQ-001", title: "B requirement", phase: "P1" });
    await h.callOn(keyB, "lock_version", {});
    await h.callOn(keyB, "create_version", {});

    // --- Boot on project A, current baseline ---------------------------------
    const comp = await loadComponent(h.base);
    await comp.loadProjects();
    comp.activeProject = comp.projects.find((p: any) => p.slug === keyA);
    await comp.loadVersions();
    await comp.loadSummary();
    comp.setupSSE();
    check("boot: stream scoped like the panels", comp._sse.url === comp.apiUrl("/events"),
      { stream: comp._sse.url, reads: comp.apiUrl("/events") });

    // --- Requirements view + Overview, after picking the draft baseline ------
    comp.tab = "requirements";
    await comp.switchVersion("1.1.0");
    check("switchVersion: stream re-scoped to the picked baseline",
      comp._sse.url === comp.apiUrl("/events") && comp._sse.url.includes("version=1.1.0"),
      { stream: comp._sse.url, reads: comp.apiUrl("/events") });
    check("switchVersion: exactly one stream left open", FakeEventSource.openCount() === 1,
      FakeEventSource.openCount());

    let calls = countReloads(comp);
    await tick(h.base, comp, 3);
    check("requirements view: no requirement re-fetch on unchanged ticks", calls.loadRequirements === 0, calls);
    check("requirements view: no stories re-fetch on unchanged ticks", calls.loadStories === 0, calls);

    comp.tab = "overview";
    calls = countReloads(comp);
    await tick(h.base, comp, 3);
    check("dashboard: no coverage/trend/gaps re-fetch on unchanged ticks",
      calls.loadCoverage + calls.loadTrend + calls.loadGaps === 0, calls);

    // A real change still reaches the open tab (the live update keeps working).
    await h.callOn(keyA, "create_requirement", { id: "REQ-101", title: "Added live", phase: "P1" });
    calls = countReloads(comp);
    await tick(h.base, comp, 1);
    check("a real change on the viewed baseline still re-fetches the list", calls.loadRequirements === 1, calls);

    // --- Switching project re-scopes the stream to the new project -----------
    // switchProject loads real data; restore real loaders on a fresh component.
    comp._sse.close();
    const comp2 = await loadComponent(h.base);
    await comp2.loadProjects();
    comp2.activeProject = comp2.projects.find((p: any) => p.slug === keyA);
    await comp2.loadVersions();
    await comp2.switchVersion("1.1.0");
    comp2.setupSSE();
    await comp2.switchProject(keyB);
    check("switchProject: stream scoped like the panels", comp2._sse.url === comp2.apiUrl("/events"),
      { stream: comp2._sse.url, reads: comp2.apiUrl("/events") });
    check("switchProject: exactly one stream left open", FakeEventSource.openCount() === 1,
      FakeEventSource.openCount());
    calls = countReloads(comp2);
    await tick(h.base, comp2, 2);
    // loadSummary is left out of the tally: it is not a list re-fetch, and the
    // per-tick summary re-read is not what the user saw as "refreshing"; the
    // lists and coverage panels are.
    check("switchProject: no re-fetch on unchanged ticks",
      Object.values(calls).reduce((a, b) => a + b, 0) - calls.loadSummary === 0, calls);

    // --- The version list grows while the page is open -----------------------
    // Booted with a single version, the stream carries no ?version=; once a
    // second baseline exists every read is pinned, so the stream must follow.
    await h.callOn(keyC, "init_project", { name: "SSE C", conductorPath: ".", initialPhase: "P1" });
    await h.callOn(keyC, "create_requirement", { id: "REQ-001", title: "C requirement", phase: "P1" });
    comp2._sse.close();
    const comp3 = await loadComponent(h.base);
    await comp3.loadProjects();
    comp3.activeProject = comp3.projects.find((p: any) => p.slug === keyC);
    await comp3.loadVersions();
    await comp3.loadSummary();
    comp3.setupSSE();
    await h.callOn(keyC, "lock_version", {});
    await h.callOn(keyC, "create_version", {});
    await h.callOn(keyC, "create_requirement", { id: "REQ-002", title: "Draft only", phase: "P1" });
    await comp3.loadVersions();
    calls = countReloads(comp3);
    await tick(h.base, comp3, 3);
    check("version list grew: stream follows the pinned reads", comp3._sse.url === comp3.apiUrl("/events"),
      { stream: comp3._sse.url, reads: comp3.apiUrl("/events") });
    check("version list grew: no re-fetch on unchanged ticks", calls.loadRequirements + calls.loadCoverage === 0, calls);
  } finally {
    await h.stop();
    await fs.rm(rootC, { recursive: true, force: true });
    await fs.rm(rootA, { recursive: true, force: true });
    await fs.rm(rootB, { recursive: true, force: true });
  }

  console.log(`\n${passed} passed, ${failed} failed`);
  if (failed > 0) process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
