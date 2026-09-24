# REPO-HUNT 2026-09-23-C

Unattended `olympus-factory` hunt worker (hunter #15). `CONSECUTIVE_MISSES=3`, so the softened
2026-09-09-B rules apply and the star/issue windows stay widened (recorded under Relaxations).
Scratch: `worktrees/_hunt/s_0923h15/`. Carry-forward scratch reused, nothing re-fetched:
`worktrees/_hunt/s_0923h14/` (probe14, seen14), `s_0923h13/`, `r_0923h12/`.

**Task (orchestrator):** re-screen the repos that earlier hunts killed ONLY on AI trailers in the
90-day commit stream, under the corrected standing rule: AI trailers are LANE-SCOPED (SKILL.md 2b,
Softened 2026-09-09-B). An agent commit kills a lane only when it closes the correctness gap class
IN the intended lane; an AI commit elsewhere is a NOTE; a repo-wide multi-subsystem agent sweep that
has already hit the lane still kills it. A root AGENTS.md / CLAUDE.md is a ranking penalty. No new
star/size/year sweeps. Excluded: openglobus, stremio-core, vermin, gauge, u-root, AeroSandbox;
piscsi is HANDOFF.

**RESULT: CANDIDATE - konsoletyper/teavm** (whole-program method summaries for the per-method IR
optimizer). Reopened by the lane-scoped AI rule: its 7 AI commits sit in wasm-gc and classlib, not in
the optimizer. Requirement 0 (platform picker) is OWED to the human.

## Relaxations (CONSECUTIVE_MISSES=3)

- Softened 2026-09-09-B rules throughout.
- Star window: no upper filter; 5000+ is a ranking penalty only.
- Zero-issue trackers: ranking penalty only.
- Root AI file: ranking penalty (user ruling 2026-09-23).
- AI trailers in the commit stream: lane-scoped (user correction 2026-09-23), not a whole-stream kill.

## Stage 0-bis proven pool

Unchanged since hunt #14 (EXHAUSTED; the only new pool repos are siliconcompiler, libspatialindex
and csbindgen, all CLAIMED in the LEDGER). Not re-screened.

## Re-screen set

Commit-stream-only AI kills gathered from `s_0923h14/probe14_*.tsv`, hunt #14's extra probes,
`s_0923h13/probe13_*.tsv`, `r_0923h12/probe_*.tsv` and the hunt #11 log (09-21-B).

Method: `s_0923h15/ailanes15.sh` pulls every AI-marked commit in the 90-day default-branch stream
(probe14's fixed regex, plus commits whose author login is an agent) and histograms the directories
the first 15 of them touch. Output per repo: `ail_<owner>_<repo>.txt` (date, author, subject) and
`dirs_<owner>_<repo>.txt`. Each verdict below reads the SUBJECTS and overlays them on the lanes the
repo could offer, as the rule asks.

### Lane-scoped verdicts

| Repo | AI commits (90d) | Where they land | Lane-scoped verdict |
|---|---|---|---|
| konsoletyper/teavm (Java 3115) | 7 | wasm-gc backend (5), classlib (2) | **REOPENED.** The IR optimizer / analysis lane (`core/.../model/optimization`, `model/analysis`) has 2 commits in 12 months and no AI commit. Root AGENTS.md + CLAUDE.md + `.claude/` = ranking penalty. Taken to Stage 3 below |
| SeaOfNodes/Simple (Java 915) | 3 | docs/typo PRs by `symious` | AI is a NOTE. Dead at Stage 2c instead: cliffclick's own 30-day stream sweeps every lane (reg-alloc, GCM, parser, lattice, x86/arm encodings, a cross-chapter fuzzer), and each "feature" is his next chapter |
| Khan/genqlient (Go 1322) | 1 | `chore(deps)` yaml swap | AI is a NOTE. Ranks low: 5 human code commits in 10 months, and the tracker is ~60 long-open feature requests (#64 field merging, #93, #152, #164 with 12 comments, #260 with 14) - every tracker lane is a magnet |
| johnfercher/maroto (Go 2758) | 1 | "add basic config for agents" | AI is a NOTE. Dead on the dormancy magnet: 12 open feature PRs blanket the lanes (RTL shaping, repeat header on page break, text rotation, character break-line, multi-style text, heatmap, doc processor) |
| vincentlaucsb/csv-parser (C++ 1129) | 3 | `codex/*` branches: CI speed, nanobind pin, JSON leading zeros (#323) | The JSON/type-inference lane is being closed by Codex; parser lane is a NOTE. Ranks low: CSV is a named format (RFC 4180), 2 open issues |
| emdgroup/baybe (Py 511) | 6 | serialization validation, a type hint, a CI SHA comment | Serialization lane touched; others NOTE. Ranks low: a three-maintainer team pushing 371 commits in 90 days, and a 1.35 GB repo |
| capnproto/capnproto (C++ 13188) | 5 | `kj/async` executor (3), compiler memcpy guard, pkg-config | Async lane touched; schema compiler / JSON codec lanes NOTE. Ranks low: 13k stars and a famous wire format (kill-list row 3) |
| jlblancoc/nanoflann (C++ 2689) | 3 | concurrent tree build (perf), CMake | Stays DEAD: the tree-build lane is the kernel, and the kd-tree is textbook with sibling libraries |
| PDAL/PDAL (C++ 1413) | 1 | Copilot Windows test fix | AI is a NOTE. Dead on Docker cost instead: GDAL/PROJ/GeoTIFF/libxml2 system stack and a full PDAL compile, well past the 600 s environment start (L62) |
| eunomia-bpf/bpftime (C++ 1576) | 1 | Copilot docs fix | AI is a NOTE. Dead on Docker cost: LLVM JIT + libbpf submodules |
| wemake-services/wemake-python-styleguide (Py 2909) | 3 | agent skill files, ruff bump | AI is a NOTE. Dead at Stage 3b: a rule catalogue, every lane is "add violation N" (triviality auto-RED) |
| OpenFeign/querydsl (Java 654) | 1 | ksp-codegen autodetect | AI is a NOTE. Ranks low: SQL/JPA serializer lanes (Python-notes avoid list applies), 3 open issues |
| ParkMyCar/compact_str (Rust 872) | 6 | pyo3/schemars/valuable features | Dead on no seam (a string type, no engine) |
| SylarLong/iztro (TS 4177) | 3 | security alert, README | AI is a NOTE. Checked below |
| preactjs/preact-render-to-string (JS 727) | 1 | `codex/preserve-client-stream-content` | The streaming lane is closed by Codex; the rest of the repo is ~2k lines (LOC ceiling). Ranks low |
| making/yavi (Java 855) | 9 | `url()` host/port checks, Enum DSL bound, build | AI is IN the constraint lane (the feature lane of a constraint catalogue). Stays DEAD |
| rust-diplomat/diplomat (Rust 914) | 11 | the .NET backend (10), nanobind caster (1) | .NET lane dead; C/C++/JS/Kotlin/Dart lanes NOTE. Ranks low: snapshot-pinned generated text, and "FFI binding generator emits X" is the feature class of our approved csbindgen pick (self-collision) |
| uber/causalml (Py 6006) | 18 | causal trees, ATE SE, uplift forest, deprecations, docs | Stays DEAD: a repo-wide maintainer sweep through the estimator lanes |
| reactive/data-client (TS) | 23 | internal agent tooling, website, deps, one react test | Library lanes NOTE. Checked below |
| MOLAorg/mola, MRPT/mrpt (C++) | 35 / 54 | MRPT-3 port across every module, TSDF, nav, math, hwdrivers coverage passes | Stay DEAD: repo-wide multi-subsystem sweeps |
| markuplint/markuplint (TS) | 38 | vscode, rules (`attr-order`), html-spec, CLI | Stays DEAD: repo-wide, and the rules lane is hit |
| samchon/typia (TS) | 50 | typia core, native, utils, llm, tags | Stays DEAD: repo-wide |
| maplibre/maplibre-tile-spec | 60 | `rust/mlt-core` codec, synthetics, docs | Stays DEAD: the core codec lane is the sweep |
| cooklang/cookcli (Rust) | 76 | web, server, build | Stays DEAD: repo-wide |
| lichtblick-suite/lichtblick (TS) | 46 | agent docs, HydratedSourcePool | DEAD on licence regardless: MPL-2.0 (Foxglove Studio fork) |
| roblox-ts/roblox-ts (TS 1305) | 3 | TSTransformer: for-of over LuaTuple, `$range` step emission; runtime lib | The transformer statement lane is being closed by the agent, and every other transformer lane is a TS language-surface feature (carve-out). Stays DEAD |
| rerun-io/egui_tiles (Rust) | 12 | simplification, tile ids, drag-drop, layout pass, a11y | Stays DEAD: repo-wide in a small repo (the hunt #11 verdict was already lane-scoped) |
| pubkey/broadcast-channel (JS) | 1 | leader election (#1416) | Stays DEAD: the only real code commit in six months is that one (Requirement 6 risk), and it is in the leader-election lane |
| iShape-Rust/iOverlay | 1 | - | Dead on Requirement 1 (210 stars) |
| gosub-io/gosub-engine (Rust 3684) | 0 | (hunt #12's `ai=2` was the bare-`cursor` false positive) | Dead on Stage 2c: 725 solo commits in 90 days, and the lanes are HTML/CSS spec rows |

Also checked, from the rows marked "below":
- **SylarLong/iztro:** the maintainer's own 2026-09-03 burst is five surgical horoscope-correctness
  fixes (day divider, early rat hour, nominal age, palace-name disambiguation, star brightness), so
  the correctness class in the core lane is being swept by hand; the lanes are lookup tables of a
  traditional ruleset, and new development has moved to hosted `iztro-*-v3` models. Ranks low.
- **reactive/data-client:** the normalizr/endpoint schema lane was a maintainer feature wave in
  March-May 2026 (Lazy schema, Scalar schema, maxEntityDepth, shared Collection keys,
  Collection.move), 20-24 commits in 12 months. Capability-consuming in the lane that would carry a
  pick. Ranks low.
- The heavy repos from hunts #12/#13 (graphql-mesh 31, cryptominisat, tinyexr, imodels,
  json-schema-to-typescript, TypeGPU, vega-lite) were re-read with the same script; see the table
  addendum at the end of this log.

**Net of the re-screen: one repo reopens with a real lane (TeaVM). Everything else is dead or
ranks low for a reason other than the AI marks.** The rule change moved roughly a third of the
AI-only kills to "AI is a note", but most of those then fail a different gate.

---

## konsoletyper/teavm - RANK 1

- **URL / stars:** https://github.com/konsoletyper/teavm - 3115 stars
- **Language:** Java (pure; the `core` module needs only a JDK; the `tests` module runs compiled
  output in Node or a C compiler, which this lane does not need)
- **Domain:** AOT compiler, JVM bytecode to JS / Wasm GC / C, with its own SSA IR, a points-to
  "dependency" analysis, an IR optimizer, an AST decompiler and a per-method optimized-program cache
- **Open issues:** 191 total incl. PRs (15 open PRs, mostly classlib/JSO; none in the optimizer)
- **License:** Apache-2.0, LICENSE + NOTICE read. Vendored code: Apache Harmony (Apache-2.0), Joda /
  ThreeTen (BSD-3, Stephen Colebourne headers). No GPL/LGPL/MPL/EPL header anywhere in the tree, one
  jar (`samples/gradle/wrapper`). Unicode, Inc. text appears only inside Harmony regex headers.
- **Last commit:** 2026-09-15; 90-day stream is konsoletyper's own classlib / wasm-gc / C-backend
  bug-fix wave plus outside PRs.
- **CI (Requirement 7):** `ci.yml` job `test` runs `./gradlew ... test` on a c/js/wasm-gc matrix
  (Node + C compiler); `master` runs: 09-15 success, 09-14 success, 09-13 failure x2, 09-13 success,
  09-11 success/failure. Latest default-branch conclusion is success; the intermittent red is in the
  backend matrix, not in `:core:test`.
- **Root AI files:** `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json` (maintainer commit "Allow
  Claude to run any gradle command"). Ranking penalty per the 2026-09-23 ruling.
- **AI commits (lane-scoped):** 7 in 90 days, all in wasm-gc codegen/type inference and classlib.
  None in `model/optimization`, `model/analysis`, `cache`, `dependency`. NOTE, not a kill.
- **PR-author profiling:** recent outside PR authors are domain users (gdx-teavm, neo4j,
  domino-ui/GWT, plantuml, jMonkeyEngine). One eval-engineer account (`egnaro9`, one classlib
  calendar PR) and one burst reporter (`thesupersupersigma`, six JS-reflection issues + one PR on
  2026-08-14) - both outside the optimizer lane: NOTE under the softened rule. The issue tracker is
  being worked by AI-assisted bug reporters (wasm-gc, JS reflection, one ScalarReplacement crash
  #1248), so the surgical-correctness gap class is being mined; this lane is a capability, not a bug.
- **Self-collision / dedup:** no `teavm` hit in SATURATED-REPOS, TOO-EASY, approved-problems,
  problems, rejected. Quota 0/6.
- **Build + determinism (measured):** shallow clone at `fd78e03f` (2026-09-15). `./gradlew :core:test`
  on local JDK 21 (Gradle 9.7.1 wrapper): BUILD SUCCESSFUL, **213 tests, 0 failures, 0 errors, three
  runs identical** (`--rerun-tasks` for runs 2-3). Cold build 6m09s including the Gradle download.
  ⚠️ Docker note: the `core` build applies the node-gradle plugin and runs `npm install` of esbuild,
  typescript and uglify-js (it left `core/node_modules`), besides Maven Central + the Gradle plugin
  portal and a foojay toolchain resolver. All of it must be warmed at image build (G-JVM1). Build
  output, `core/.gradle` and `core/node_modules` removed after the measurement; clone kept (70M).

### Lanes (Stage 2c) and the chosen one

12-month heat by subsystem: `model/optimization` 2 (plus one wasm-gc coroutine commit), `model/analysis`
7 (reflection/classlib driven), `ast` 5, `cache` 3, `debugging` 0, `parsing` 10, `dependency` 8,
JS `rendering` 8. The maintainer's program is classlib + wasm-gc + the C backend on MSVC.

Rejected lanes, with the reason:
- Loop inversion: `LoopInversionImpl` exists and is commented out of the pipeline, and issue #25
  (2014, open) asks for exactly it. Magnet plus an existing implementation.
- New textbook passes (SCCP, array scalar replacement, bounds-check elimination): a new pass is a new
  file plus one line in `TeaVM.getOptimizations()` (Stage 6 guard #3), `BoundCheckInsertion` already
  elides dominated checks, and array SRA is a missing arm of `ScalarReplacement`.
- Nullness through casts / instanceof only: real gap, but under 150 eff alone.
- ScalarReplacement crash #1248 / wasm-gc AGGRESSIVE #1257: live bugs the maintainer will take.
- String-switch reconstruction in the AST decompiler: every Java decompiler ships it (sibling rule),
  and the tests would pin exact JS text.
- JSO / reflection lanes: warm, and tested only through a JS runtime.

**Chosen lane: whole-program METHOD SUMMARIES consumed by the per-method optimizer.** TeaVM optimizes
each method in isolation (`TeaVM.optimizeMethod`), so every call is opaque:
`NullnessInformationBuilder` only records the receiver of an `InvokeInstruction` as non-null after the
call and never knows anything about the RESULT, and `RepeatedFieldReadElimination` sets
`invalidatesAll` on every invocation (pinned by the existing `invocationInvalidates` fixture). The
capability computes, once per build after inlining, two facts per reachable method - "never returns
null" and "the set of fields / static state it may write, including through class initializers it
can trigger" - and feeds them to the nullness kernel (and through it to
`RedundantNullCheckElimination`, `ConstantConditionElimination` and `LoopInvariantMotion`) and to
`RepeatedFieldReadElimination`, and records the extra dependencies in the per-method program cache.
Gate 1 on base is visible in code and in the existing fixtures (an invoke result is never non-null;
an invocation always invalidates every field); the builder owes the runnable repro.

**TRAP SEAMS:**

| Pattern | Present | Evidence |
|---|---|---|
| F-22 fixed point over several kinds | yes | recursion and mutual recursion through the call graph; the two facts settle in OPPOSITE directions (never-null starts optimistic and demotes, the write set starts empty and grows), so one shared SCC walk carries two lattices |
| F-27 polarity copied from the sibling | yes | copying the nullness fact's optimistic start onto the effect fact (or the reverse) is exactly the dual-combinator mistake |
| F-3 second-axis carve-out | yes | a `VIRTUAL` invoke must meet over every reachable override from the dependency analysis, not the static target; an override in a subclass the call site never names changes the answer |
| F-14 declared-vs-derived terminal state | yes | native, abstract-without-implementation, `@JSBody`/generated and async methods have no analysable body: "unknown" must poison the whole SCC it sits in |
| F-9 cross-stage resolution | yes | a static call or static field access can run a `<clinit>` (`ClassInitInsertion`, `ClassInitializerInfo.isDynamicInitializer`), whose writes belong to the caller's effect set; the nullness fact does not care, the effect fact does |
| F-47 discarded state | likely | `ProgramDependencyExtractor` records only classes the optimized program names; a caller optimized on the strength of an override's body must be invalidated when that override's class changes (`programCache.get(ref, cacheStatus)`) |
| F-12 / F-48 existing entry points | yes | `MethodOptimizationContext` is implemented anonymously by `ScalarReplacementTest` and `RepeatedFieldReadEliminationTest`; `NullnessInformation.build(program, descriptor)` is called by five consumers and the nullness test. New inputs must not break either (default method / overload) |
| F-10 cross-product | yes | {static, special, virtual} invocation x {never-null, effect} x {plain, recursive, unknown-in-SCC} cells |

**Missing machinery (LOC carry), sketched against the chokepoints:** the summary kernel with an SCC or
worklist fixpoint over two lattices (~100-120 eff); reachable-override resolution and unknown
poisoning through the dependency analysis (~40-60); the class-initializer effect rule (~40-60);
nullness builder consumption with an overload that keeps the old entry point (~30-40);
`RepeatedFieldReadElimination` consumption (~30-40); context default method plus pipeline wiring,
gated to ADVANCED/FULL (~25-35); cache dependency recording (~20-30). **~285-395 human-eff across 6-8
files in 5 packages** (`vm`, `model/analysis`, `model/optimization`, `cache`, plus the new kernel).
Above 250, so it proceeds under the 2026-09-09-B sketch rule.

**Tests the lane can use offline:** the `core` fixture harness (`ListingParseUtils` IR text,
`NullnessAnalysisTest`'s per-variable `// NOT_NULL` / `// NULLABLE` directives, the
`RepeatedFieldReadElimination` original/expected pairs) plus a small `ClassHolder` set built in the
test for multi-method cases. The dead but present `org.teavm.model.Interpreter` is available as a
semantic oracle for "optimized program behaves like the original". No Node, no browser.

### Stage 3b / 2b

- Absorption: nothing in `core` computes a per-method fact for callers (`grep -rniE
  "nonnull|returnsnull|nullable"` finds only `Optional.ofNullable` and the debug-info writer).
  `ClassInference` tracks class sets, not nullness. The capability is new machinery, not a missing
  arm of one dispatch.
- Port / previous-major: TeaVM is not a port; no older summary machinery found.
- **Sibling libraries (MEDIUM risk, recorded, not a kill):** `gh search code` finds R8's
  `MethodOptimizationInfo.neverReturnsNull` and `SideEffectAnalysis` in Soot, Tai-e and error-prone.
  The generic worklist is textbook; the difficulty sits in TeaVM's own model (dependency-analysis
  override sets, class-initializer effects, the per-method cache, two opposite lattices in one walk),
  none of which those libraries have in a liftable form. The sfepy death was a liftable formula; this
  is not, but the precheck scope gate is the judge. Phrase meta.md on TeaVM's model.
- Magnet / PR-DIFF: canonical org `konsoletyper/teavm`. PR and issue searches for nullness, null
  check, interprocedural, non-null, nullability, return null, escape analysis, method summary, side
  effect, pure method, purity, field read, RepeatedFieldReadElimination, cache invalidation,
  incremental: **no PR or issue asks for or implements this** (only #1248 ScalarReplacement crash and
  #25 loop inversion touch the optimizer). All 15 open PRs enumerated with full file lists: none touches
  `model/optimization`, `model/analysis` or `vm/TeaVM.java`; the only `cache` hit is #396 (2019, stale),
  6 lines in `cache/AstIO.java` for the AST cache, which this lane does not use.
- Maintainer-welcomed lanes (2d): none found; no removal record for this capability.

### Stage 6 death-class guard on RANK 1

1. **One shared kernel, several surfaces?** Yes. One summary table feeds the nullness kernel (three
   optimizer consumers behind it), `RepeatedFieldReadElimination`, and the program cache's dependency
   record. Teaching one consumer to look into callee bodies on its own duplicates the kernel and
   diverges on recursion and unknown bodies.
2. **Interdependent traps?** Yes. The two facts share one SCC walk but move in opposite lattice
   directions; unknown bodies must poison through the SCCs and through override sets; the
   class-initializer rule belongs to one fact only. Fixing recursion with the wrong start value, or
   copying the nullness rules onto effects, breaks the other fact's cells.
3. **Standalone new file with minimal wiring?** No. The kernel is new, but it is useless without
   changing the nullness builder, the field-read eliminator, the optimization context, the build
   pipeline and the cache: five packages.
4. **TOO-EASY Pre-Pick Guard 1-5:** not membership/validation, not a mechanical text transform (the
   contract is analysis facts plus semantics preservation), not misdirection-only, not a uniform wrap
   (two facts, opposite lattices, three invocation kinds), not a saturated port. Guard #2 passes
   because the lane crosses five packages and its output is not a pinned text transform.

**Guard verdict: PASS.** Recorded caveat (TOO-EASY hot/cold inversion): this is an optimization-quality
capability; its F2P cells are analysis facts and optimized IR, and wrong-results cells are P2P
soundness guards. The smoke batch is the oracle for whether that is hard enough.

**Risks:** root AGENTS.md/CLAUDE.md and a maintainer who drives Claude (penalty); an AI-assisted bug
reporter population mining the wasm-gc and JS-reflection correctness class (outside this lane);
sibling-library scope-gate risk (above); optimization-quality capability (smoke batch owed); Docker
image must pre-warm Gradle, Maven Central, the Gradle plugin portal, a Node download and three npm
packages; CI shows intermittent backend-matrix failures on `master` (09-11, 09-13) that `:core:test`
does not run.

---

## Addendum: heavy AI-sweep repos from hunts #12/#13, re-read under the lane rule

| Repo | AI commits | Where | Verdict |
|---|---|---|---|
| ardatan/graphql-mesh | 31 | loaders (OpenAPI `queryStringOptions`), CI, renovate | Loader lane touched; GraphQL-gateway domain is famous; ranks low |
| msoos/cryptominisat | 113 | `src/` solver core (occsimp, BVE) | Stays DEAD: the solver lane is the sweep |
| syoyo/tinyexr | 160 | `tools/texpipe` (a KTX2/ASTC tool) | Sweep sits in the tool, but the core lanes are OpenEXR format rows (named spec); ranks low |
| csinva/imodels | 148 | models, deps, docs | Stays DEAD: repo-wide |
| bcherny/json-schema-to-typescript | 138 | `claude[bot]` authors `src/` ($ref composition, intersections) | Stays DEAD: the agent IS the committer, in the core lane |
| software-mansion/TypeGPU | 5 | shader generator, GL backend | Stays DEAD: in the shader-generator lane |
| vega/vega-lite | 9 | compile/scale, selection | Stays DEAD: in the compiler lanes |

## Fallbacks (both rank well below TeaVM; neither was taken to Stage 3)

- **Khan/genqlient** (Go 1322, MIT): the AI mark is a deps chore. Only an INVENTED codegen lane is
  admissible, because every tracker lane is a long-open magnet (#64, #93, #152, #164, #260). Dormant
  maintainer (5 human code commits in 10 months), snapshot-golden tests.
- **capnproto/capnproto** (C++ 13188, MIT): the AI marks sit in `kj/async` and one compiler guard.
  The schema-compiler and JSON-codec lanes are notes, but 13k stars and a famous wire format put it
  in the kill-list penalty row; a full C++ build fits the base image without system deps.

## Requirement 0

OWED for konsoletyper/teavm. The human checks the picker at the precheck touchpoint.

## Disk

One shallow clone (`worktrees/teavm`, 70M after cleanup). One scoped build (`:core:test`), whose
`build/`, `.gradle/` and `core/node_modules` were removed after the measurement. The Gradle home
`~/.gradle` grew to 1.2G (distribution + dependency cache), outside `worktrees/`; left in place for
the builder. `df -h /`: 15G free before, 14G after.

## What the next hunt should change

1. **The lane-scoped rule reopened ~1/3 of the commit-stream kills but only ONE repo survived the other
   gates.** Most AI-only kills were agent sweeps that are genuinely repo-wide (typia, mrpt, mola,
   markuplint, cookcli, maplibre-tile-spec, causalml, imodels, cryptominisat, json-schema-to-ts), and
   most of the "AI is a note" repos fail something else (catalogue, dormancy magnet, Docker cost,
   licence, language-surface carve-out). Do not re-screen the rows in this log.
2. If TeaVM dies at the picker or the precheck, the next best use of this workspace's cached index is
   the ~146 engine-shaped rows of `s_0923h14/eng_pool.txt` that hunt #14 never probed (it probed 24 of
   170). They are root-file-only or unprobed, not AI-stream kills.
3. `ailanes15.sh` is the lane-scoped reader: run it right after `probe14.sh` on any row with ai>0,
   and read subjects before killing.

## Scratch

`worktrees/_hunt/s_0923h15/`: `ailanes15.sh`, `ail_*.txt` and `dirs_*.txt` per repo, `mech15.tsv`,
`teavm_tree.txt`, `teavm_core_test{1,2,3}.log`, `run{1,2,3}.log`.
