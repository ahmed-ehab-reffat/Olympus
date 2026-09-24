# REPO-HUNT 2026-09-20-D

Unattended `olympus-factory` hunt worker. `CONSECUTIVE_MISSES=0`, so the standard (un-softened)
2026-09-09-B gates were applied; no relaxation was needed or taken. Scratch:
`worktrees/_hunt/o_0920d/`.

Predecessor state carried in: hunter #8 was launched yesterday evening with the same hint and was
killed by the API usage limit, but it had already written `worktrees/_hunt/n_0920d/` (awesome-list
scrapes, `deadlist_v16.txt`, a 1,294-row filtered pool in `aw_pass.txt` split into three buckets, a
45-query instrument/lab sweep `rsweep.jsonl` and a 62-topic embedded/industrial sweep
`tsweep.jsonl`, plus a screening `BRIEF.md`). **None of that had been triaged.** This session
triaged all of it rather than re-fetching, which is where most of the value came from.

---

## Budget spent

| Stage | Spend | Outcome |
|---|---|---|
| Stage 0-bis proven pool | ~2 min (mechanical diff only) | EXHAUSTED, confirmed for the fifth session running |
| Cached star-band index | 0 | Not touched (hint: budget zero) |
| Triage of hunter #8's two pre-fetched sweeps (107 queries/topics, 1,234 rows) | ~10 min | 130 survivors, all junk — axis is a bust, see below |
| Fresh sweep 1: 92 unused physical/industrial topics | ~25 min | 195 rows -> **14 survivors, 0 real** |
| Fresh sweep 2: 59 unused business/clinical/finance domain queries | ~30 min | 1,009 rows -> 178 survivors, 0 real |
| Three parallel screening agents over 1,201 pre-profiled repos | ~45 min | see the verdicts section |

---

## Stage 0-bis — proven-repo pool (CONFIRMED EXHAUSTED, 5th session)

Ran the `LESSON B` mechanical diff (pool repos with <=2 subs that are not mentioned in
`SATURATED-REPOS.md`):

```
UN-MINED: earwig/mwparserfromhell · fonttools/fonttools · gfx-rs/rspirv · icedland/iced ·
kivikakk/comrak · libspatialindex/libspatialindex · mpmath/mpmath · onthegomap/planetiler ·
pulldown-cmark/pulldown-cmark · pyparsing/pyparsing · pytest-dev/pyfakefs ·
quickwit-oss/tantivy · scikit-bio/scikit-bio · siliconcompiler/siliconcompiler ·
sqlfluff/sqlfluff · Textualize/textual · tokio-rs/turmoil · vivisect/vivisect ·
featurevisor/featurevisor
```

Every row is either (a) a repo this loop has just claimed or shipped (pyfakefs, libspatialindex,
siliconcompiler, featurevisor x2, mwparserfromhell, planetiler), or (b) already killed in an
earlier log for a reason that has not changed (comrak scope-gate, tantivy 16k stars + maintainer
collision, scikit-bio `steps-re`, mpmath competitor-visited, iced/rspirv/sqlfluff/pulldown-cmark
spec-named, Textualize famous, fonttools 5,256 stars + OpenType is the capability space).
**The "UN-MINED" signal now reports only our own in-flight work.** The pool is not a source any
more; it should be budgeted at zero until a new repo enters it via an approval.

---

## Two fresh sweeps, and the measured reason both failed

The hint said the unscreened ground that pays is *instrument/laboratory control and embedded debug,
filtered on open-PR count first*. Hunter #8 had already fetched exactly that ground
(`rsweep.jsonl`: SCPI, GPIB, lock-in amplifier, spectrum analyzer, waveform generator, motion
controller, instrument driver, laboratory automation, data acquisition, ladder logic, structured
text, function block, netlist, place-and-route, bitstream, instruction set simulator, trace
decoder, coverage database, ... 45 queries / 860 rows; `tsweep.jsonl`: jtag, swd, openocd,
semihosting, bootloader, rtos, device-tree, logic-analyzer, ethercat, canopen, j1939, obd2, uds,
isotp, lin-bus, autosar, misra, iec61850, dlms, profinet, a2l, dbc, ... 62 topics / 374 rows).

Triaged against `deadlist_v16` + licence + language + activity + an AI/list/noise filter:
**130 survivors out of 1,234 rows, and not one is authorable.** The whole instrument/embedded-debug
band is either

- **plain C** (`j123b567/scpi-parser`, `lxi-tools/lxi-tools`, `fossasia/pslab-*`, openocd-family) —
  a hard platform-picker reject since 2026-09-19;
- **GPL/LGPL** (`eez-open/studio` GPL-3.0);
- **hardware-bound firmware** (Arduino CAN libraries, ESP32 toolkits, `dbus-serialbattery`); or
- **already taken/dead** (pyOCD claimed this session, probe-rs, amaranth, glasgow, cocotb, edalize,
  nextpnr, KiKit all killed in `REPO-HUNT-2026-09-20-B/-C`).

⭐ **Finding 1 (new, and it should change the next hunt's plan): the hint's thesis is false, and the
reason is structural.** "Calm repos with few PRs in instrument/lab control and embedded debug" is a
real description of that band — but the calm repos there are *small C firmware projects*, and the
band's Python/C++ members are exactly the nine repos the marker-split re-screen already burned.
The PR-count-first filter the hint proposed cannot rescue it, because the binding constraint is
language and hardware, not queue depth.

### Fresh sweep 1 — 92 unused physical/industrial topics (`o_0920d/topics_e.txt`)

Topics chosen to be disjoint from the 771 already in `used_topics.txt`: geodesy, photogrammetry,
radiometry, colorimetry, chromatography, cytometry, tomography, dosimetry, pharmacokinetics,
bioreactor, metallurgy, welding, injection-molding, tolerance-analysis, gearbox, vibration-analysis,
modal-analysis, room-acoustics, ambisonics, beamforming, sonar, radar, adsb, airspace,
flight-planning, aerodynamics, propulsion, orbital-mechanics, attitude-control, ephemeris,
leap-second, load-flow, protection-relay, power-quality, transformer-model, cable-sizing,
lighting-design, thermal-comfort, refrigeration, pump-curve, valve-sizing, pipe-network,
open-channel, sediment-transport, groundwater, crop-model, snow, avalanche, wildfire, air-quality,
dispersion-model, life-cycle-assessment, ...

**195 rows total; 14 survive the mechanical filter; 0 are real.** Every survivor is either a
keyword collision (`gookit/goutil` on `casting`, `gogearbox/gearbox` on `gearbox`,
`dropbox/rust-brotli` on `compressor`, `catdad/canvas-confetti` on `snow`) or an ML paper drop.

⭐ **Finding 2 (new): the >=500-star floor empties the niche-engineering topic space outright.**
These are not colonised topics — they are topics where GitHub simply has no 500-star library.
92 topics returned 195 repos in total (2.1 per topic, against 6.0 for the business queries below and
~40 for a populated topic). Do not spend another sweep on physical/industrial domain vocabulary; the
population is not there, and the negative result is now measured rather than assumed.

### Fresh sweep 2 — 59 unused business / clinical / finance domain queries (`o_0920d/fqueries.txt`)

Rationale: `featurevisor` (two approvals) shows the corpus can win on a *business-logic* engine, and
the `agents/` dossier set shows ~25 niches already swept, none of them in insurance, tax, payroll,
billing, clinical decision support, entity resolution, master data, scheduling or consent.
Queries: "rules as code", microsimulation, actuarial, underwriting, "double-entry", "general
ledger", "tax calculation", payroll, "billing engine", "rating engine", "pricing engine",
"bill of materials", "production planning", "capacity planning", "shift scheduling", timetabling,
"clinical decision", "drug interaction", "medical coding", "claims processing", "eligibility
rules", "benefit calculation", pension, "yield curve", "credit scoring", "entity resolution",
"record linkage", "master data", "data lineage", "schema evolution", "change data capture",
"reconciliation engine", "survey logic", "form engine", "decision table", "business rules",
"approval workflow", "document assembly", "policy evaluation", "consent management", ...

**1,009 rows; 178 survive; 0 authorable.** The band is cloud-native platforms
(kubescape, kyverno, meshery, external-secrets, capsule), vendor SDKs (googleapis x4, AWS x3),
AI tooling, cookie-consent widgets and Kubernetes operators. The two that looked like engines both
die on record:

- **`moj-analytical-services/splink`** (Python, MIT, ★2415, entity resolution / record linkage) —
  the single best-shaped hit of either sweep: Fellegi-Sunter model, blocking-rule analysis, EM
  training, term-frequency adjustment, clustering, and SQL generation across DuckDB/Spark/Athena/
  Postgres/SQLite (a real F-30/F-31 twin-implementation seam). **Already killed** in
  `REPO-HUNT-2026-09-12` as a published-method library (the JOSS class), and the sibling check
  confirms it: `recordlinkage`, `dedupe` and `zingg` all ship Fellegi-Sunter.
- **`apache/incubator-kie`** (Drools/OptaPlanner/jBPM) — DMN/BPMN are named standards, and the repo
  is an umbrella of three engines.

⭐ **Finding 3 (new): the business/clinical/finance query band is populated but is not a library
band.** 6.0 repos per query (3x the topic sweeps) yet zero engines: at >=500 stars this domain is
applications and platforms, because the actual rule engines in it are proprietary. This axis is
now spent and should not be re-run either.

---

## The three parallel screening passes (the only productive line)

Rather than fetch more, three screening agents were run against pre-profiled pools using hunter #8's
`BRIEF.md` verbatim (mechanical gates, kill-on-sight list, absorption + sibling-library + previous-
major checks, effective-LOC sketch), with the taken/reserved list and the burned classes appended:

| Agent | Pool | Size | Provenance |
|---|---|---|---|
| A | `o_0920d/b12.txt` | 317 | hunter #8's calm (low open-PR) slice of the awesome-list pool |
| B | `n_0920d/bucket3.txt` | 514 | the remainder of the awesome-list pool |
| C | `o_0920d/engresid.txt` | 370 | **the genuinely unmined pool** — hunter #4's `i_size/eng_active.txt` (large, active, engine-shaped repos, disk >5 MB) minus `deadlist_v16` |

⭐ **Finding 4 (method): `worktrees/_hunt/i_size/` was never triaged and is the best residual in the
workspace.** Hunter #4 built it (a `created:`-year + `size:>5000` sweep with per-repo language,
licence, commit-count and recent-commit-subject profiling), was killed by the rate limit, and
hunter #5 only took the 63-row `short1.txt` shortlist out of it. `eng_active.txt` holds 386
profiled rows, 370 of which survive the dead list and **had never been surfaced in any hunt log**.
`unshown_big.tsv` (677 rows) is a second, larger untriaged slice of the same fetch.

### Verdicts — all three fail, and two fail on a gate the screening agent did not run

| Repo | Agent's lane | My verdict |
|---|---|---|
| **rune-rs/rune** ★2326, Apache-2.0/MIT, Rust | or-patterns (`a \| b => ...`) in `match`/`if let`/`while let`, issue #783, sketched 250-360 eff across `ast/pat.rs`, `hir/lowering2.rs`, `compile/v2/assemble.rs` | ⛔ **REJECT, named death class, already MEASURED.** This is `TOO-EASY.md`'s **Famous-language-feature lane** carve-out verbatim (a language implementation + a user-visible pattern-matching surface feature), and the taxonomy's own evidence table already prices this exact pick: row *"Rune or-patterns + ranges + @-bindings — adjacent 0.78"*. Our own `rejected/gluon-match-alternatives` is or-patterns in another small scripting language and came back `duplicate` 0.92 after the author deliberately dropped the issue to dodge the narrower class; `rejected/gluon-match-guards` and `rejected/koto-nested-bindings` (`Blocker`, 52.8% against an ACCEPTED task) are the same family. `CLAUDE.md:276` also lists `rune-const-pattern` as already shelved-derivative, so the repo itself is a recorded magnet. The clean SIX-CHECK the agent reported is exactly what the taxonomy says this class always shows. |
| **ChunelFeng/CGraph** ★2303, MIT, C++ | async-ness not propagated through nested `GCondition`/`GCluster`/`GRegion` into `GElementManager::checkSerializable()`, so `GPipeline::makeSerial()` zeroes the thread pool and starves an async node; sketched 135-205 eff + an optimizer lever | ⛔ **REJECT on Requirement 7 (verified directly).** The lane itself is good — repo-internal nouns, a real shared kernel with two call sites, misdirecting failure mode, zero open PRs, MIT verified. It dies on the baseline. **No workflow runs a test suite:** `cmake4ubuntu.yml` / `cmake4mac.yml` / `cmake4win.yml` run `cmake -B build` then `cmake --build` and stop; `pip4*.yml` build and `twine check` wheels; `codeql-analysis.yml` is a scanner. No alternate CI in the tree either (`MODULE.bazel`/`WORKSPACE`/`xmake.lua` exist, nothing runs `bazel test`). Worse, there is **nothing to run**: `test/Functional/test-functional-0*.cpp` are `main()` programs that `std::cout` a message when a count is wrong and `return 0` regardless (`test-functional-01.cpp` loops `runTimes = 500000` and prints `"g_test_node_cnt is not right"` on failure), and `CGraph-run-functional-tests.sh` just executes every binary in `build/test/Functional/` ignoring exit codes. There is no assertion framework, no JUnit reporter, and a base mode built on it could never go red. Repo NOT blocklisted — if it ever adds gtest/Catch2 and a CI test job, this lane is worth re-opening. |
| **dylibso/chicory** ★1136, Apache-2.0, Java | interpreter/AOT-fallback `Instance` state consistency (issue #1030, imported memory) coupled to `Instance` copy/clone (issue #945); sketched 230-350 eff across 5-6 files | ⛔ **REJECT — dormant default branch, plus the LOC lever is the bolted-on kind.** Measured: **0 commits on `main` since 2026-06-01**, last real code commit `Compiler: auto-size dispatch chunks` on **2026-05-06** (2026-05-28 is a blog edit), **3 merged PRs since 2026-05-01 against 191 in the trailing 12 months** — i.e. the whole year's activity ran Sep 2025 to Apr 2026 and then stopped. All 19 open branches are dependabot branches. Consequences: (a) the platform's active-maintenance precheck is a live risk; (b) the "CI green" reading is stale — `ci.yaml` triggers only on `push` to `main`, so the test workflow has not run since May and the only green rows on `main` are the scheduled `Zig Testsuite` / `Nightly Fuzz` / `Scheduled` jobs; (c) the CI test job is declared `continue-on-error: true` with a matrix cell excluded as *"Flaky, re-enable when the bug on the JVM is fixed"*, so a red suite does not fail the build — a bad baseline-health signal for base mode. Independently, the lane is the union of TWO open tracker issues where the agent itself says the core (#1030) may be a single missed field copy under 100 LOC and #945 is what carries it over the floor: that is `TOO-EASY.md`'s **Scope-lever-doubles-the-collision-surface** row (orb-ring-role-preservation, dedupe `derivative` 0.70) and the set-level-union shape that killed `oxipng-apng-frame-optimization`. Also note the test build path checks out `WebAssembly/testsuite` and `WebAssembly/wasi-testsuite` from GitHub at CI time, so an offline image must vendor both corpora. **Best lead of the session; re-open only if the repo resumes landing code.** |

⭐ **Finding 5 (method, and it cost two of the three picks): the screening brief's gate order lets a
repo pass on gates that do not bind.** Both A and C reported "CI verdict: green" from
`gh run list --branch main`, and in both cases the green rows came from workflows that never run a
test (CGraph: configure+build and wheel-build; chicory: scheduled fuzz/spec jobs while the actual
test workflow has not been triggered in four months). **Requirement 7 must be checked by READING
the workflow that is claimed to run the tests, and by confirming a run of THAT workflow on the
default branch inside the activity window** — a conclusion histogram is not evidence. Add to the
brief: after `gh run list`, `gh api .../contents/.github/workflows/<the test one>` and grep for the
command that invokes the suite, then confirm that workflow's name appears in the run list.

### Other rows the agents killed, worth keeping

- **`tdewolff/minify`** (Go, MIT, ★4140) — strong shared-kernel shape (`minify.Number()`/`Decimal()`
  feeding six surfaces), but `css/css.go:1469-1577` carries a **complete commented-out draft** of the
  unit-conversion lane sitting in mainline. Dead code in the default branch is worse than an open PR
  for exclusivity. Other minify lanes unvetted; repo not blocklisted.
- **`RoaringBitmap/roaring-rs`** — exclusivity: open PRs #366 and #361 both edit
  `bitmap/store/{bitmap_store,interval_store}.rs` and #363 is the maintainer fixing an off-by-one in
  the run container, i.e. the container-internals lane.
- **`refactorfirst/RefactorFirst`** — kill-on-sight: `AGENTS.md` + `CLAUDE.md` + a `plans/` directory
  of AI-authored implementation plans.
- **`greyblake/whatlang-rs`** — triviality: both candidate gaps (#142 multi-candidate, #136
  mixed-script) are plumbing over `RawOutcome.scores` / `RawScriptInfo.counters`, which the engine
  already computes and sorts.
- **`gittuf/gittuf`** — numbered `GAP-N` design-doc process + roadmap issue #232.
- **`pb33f/libopenapi`** — `AGENTS.md` at root combined with a maintainer PR stream (#622, #623,
  #611, #602) across exactly `index/`, `what-changed/`, `bundler/`.
- **`amazon-ion/ion-java`** — 20+ open `ion11` issues = incremental maintainer rollout in the only
  rich lane.
- **`sunng87/pgwire`** — issue #221 is a checkbox roadmap over the client-API surface.
- **`aff3ct/aff3ct`** (C++, ★600, FEC simulation chains with its own Task/Socket/Factory model) —
  **not killed, not cleared**: genuinely obscure domain and a real internal model, but the tracker is
  user-support questions about textbook codecs and the build is submodule-heavy (MIPP, streampu, cli,
  date) so the vendored-licence surface is unread. **The one row in this session worth a fresh audit.**
- **`plotters-rs/plotters`** — dormant feature queue (#259, #176, #111, #116) over the core lanes.

### Repos I audited myself, outside the agents

- **`hanruihua/ir-sim`** ★1129 MIT (our own proven pool, 1/6 quota, `ir-sim-scenario-events` accepted
  1/11 on 2026-09-19). `SATURATED-REPOS.md § B3-undecies` lists *"Untouched lanes: planners, sensors
  (fmcw), maps/fog, behaviors"*. ⛔ **That note is now STALE — the maintainer shipped every one of
  them in the 90 days since.** Commit stream: `feat(behavior): add sfm group behavior with social
  groups (#369)` 2026-09-12, `feat(behavior): add orca group behavior for diff robots (#333)`
  2026-06-30, `feat(map): add fog-of-map overlay revealed by lidar or robot FOV (#337)` 2026-07-01,
  `perf(sensors): speed up 2D lidar ray casting (#353)`, `perf: speed up lidar with dynamic obstacles
  (#332)`, `perf(step): vectorize RVO and batch per-step geometry (#366)`, plus compound geometry
  (#350), ROS-style messages (#355), headless mode (#362), per-env RNG (#365), internal/external step
  modes (#354), custom config section (#359). Competitor-CLEAN (38/43 PRs are `hanruihua`, no
  signature account), CI green, 0 open issues — and capability-consumed on every named lane. **Do not
  spend a second pick here; update the B3-undecies row.**
- **`moj-analytical-services/splink`** — see sweep 2 above; already dead in `REPO-HUNT-2026-09-12`.
- **`googlefonts/fontmake`** ★888 and the UFO font toolchain (`ufo2ft` 176, `glyphsLib` 202,
  `fontParts` 152, `defcon` 70, `afdko` NOASSERTION + PostScript-primary) — the only 500+ star member
  is `fontmake`, which is a thin orchestrator over the sub-500 packages that hold the real logic.
  That is the **author-controlled sibling package** absorption class (quimb/momepy). Dead.
- **`arx-deidentifier/arx`, `faucetsdn/faucet`, `inducer/loopy`, `BaseXdb/basex`, `cvanaret/Uno`,
  `NGT`, `frawk`** and the rest of `i_size/short1.txt` — already screened in
  `REPO-HUNT-2026-09-20` (hunter #5); arx is Req 6 + Req 7 dead (1 commit/12mo, pmd + CodeQL only).

---

## Verdict

**NO-CANDIDATE.** Three independent screening passes over 1,201 pre-profiled repos, two fresh sweeps
over 151 unused topics/queries, and the triage of 1,234 pre-fetched rows produced three finalists,
and all three fail a hard gate: one is a named death class with a measured dedupe score, one has no
test-running CI and no assertion-based suite to build a base mode on, and one has a dormant default
branch with a stale CI reading and a bolted-on LOC lever.

---

## Requirement 0

**OWED.** The platform repository picker cannot be checked from this session. The human must try
selecting the RANK 1 in the picker at the precheck touchpoint, and record any refusal in
`SATURATED-REPOS.md § A0`.

---

## Disk discipline

No builds of any kind were run: no `cargo`, `go build`, `make`, `cmake`, `pip install`, `npm
install` or `docker build`. Root `/` stayed at 14 G free throughout (86% used) against the 8 G
floor. All clones were `--depth 50` into `worktrees/_hunt/o_0920d/`.

---

## Scratch left for the next hunt

- `worktrees/_hunt/o_0920d/tri.py` — dead-list + licence + language + activity + noise triage filter
  (reads the `{slug,stars,lang,lic,pushed,oi,desc}` jsonl shape both sweep scripts emit)
- `worktrees/_hunt/o_0920d/esweep.jsonl` + `topics_e.txt` — the 92 physical/industrial topics, spent
- `worktrees/_hunt/o_0920d/fsweep2.jsonl` + `fqueries.txt` — the 59 business-domain queries, spent
- `worktrees/_hunt/o_0920d/engresid.txt` — the 370-row unmined big-engine pool (agent C's ground)
- `worktrees/_hunt/o_0920d/b12.txt` — the 317-row calm awesome-list slice (agent A's ground)
- `worktrees/_hunt/i_size/unshown_big.tsv` — **677 further rows from the same fetch, still untriaged**
- `worktrees/_hunt/o_0920d/sigcheck.sh` — one-shot signature-account grep for a repo's PR authors

---

## What the next hunt should change

**Do NOT re-run any of these — each is now measured, not guessed:**

1. The **instrument / laboratory-control / embedded-debug band** (the hint's own thesis). 1,234 rows
   across 107 queries and topics, 130 survivors, zero authorable. The band is C-primary, GPL,
   hardware-bound, or already burned by the 09-20-B/-C marker-split re-screen. The PR-count-first
   filter the hint proposed cannot rescue it: the binding constraint is language and hardware.
2. **Physical / industrial engineering topic vocabulary** (92 fresh topics, sweep 1). 2.1 repos per
   topic. The >=500-star floor simply empties this space.
3. **Business / clinical / finance domain queries** (59 fresh queries, sweep 2). 6.0 repos per query
   but zero libraries — at >=500 stars this domain is applications, platforms and vendor SDKs,
   because the real rule engines in it are proprietary.
4. The **proven-repo pool** — fifth consecutive exhausted session; its only "un-mined" rows are our
   own claimed and shipped repos. Budget zero until an approval adds a new repo to it.
5. The **cached star-band index** — untouched here, still recorded as exhausted on three axes.

**Where the remaining ground actually is, in priority order:**

1. ⭐ **`worktrees/_hunt/i_size/` is the best residual in the workspace and is still only half
   triaged.** Hunter #4 built it (a `created:`-year + `size:>5000` sweep with per-repo language,
   licence, commit-count and recent-commit-subject profiling), was killed by the rate limit, and
   hunter #5 only consumed its 63-row `short1.txt` shortlist. This session gave agent C the 370-row
   `eng_active.txt` residual, which is where the session's best lead (chicory) came from.
   **`unshown_big.tsv` still holds 672 un-dead-listed rows nobody has read** — it is creation-year
   sorted so the head is mirrors and OpenStack, but it has never been sorted by language or stars.
   Re-sort it and screen the Java/C++/Go tail.
2. **Fix the Requirement-7 check in the screening brief before the next agent sweep** (Finding 5
   above). Two of this session's three finalists were reported "CI green" off a run histogram whose
   green rows came from workflows that never run a test. Require: read the workflow file, quote the
   command that invokes the suite, and confirm that workflow's NAME appears in the default-branch run
   list inside the activity window.
3. **Add a dormancy probe to the brief.** `gh api "repos/$R/commits?since=<90d>&per_page=100" -q
   'length'` plus merged-PR counts at two horizons. Chicory reads healthy on stars, licence, issue
   count and scheduled-workflow greens, and has **0 commits on `main` in 3.5 months**. One call.
4. **`aff3ct/aff3ct`** is the one row this session surfaced and could not close: C++, ~600 stars, an
   obscure FEC/channel-coding domain with its own Task/Socket/Factory model. Owed: the vendored
   licence scan across its submodules (MIPP, streampu, cli, date) and a lane that is not a textbook
   codec.
5. **Java and C++ are under-mined relative to the corpus** (9 of the last ~15 approvals are Python,
   Go or Rust), and the recorded signature accounts skew Python/Go — so competitor pressure is lower
   there. Source them by a language + stars + disk-size sweep rather than by topic, since the topic
   vocabulary is what is exhausted, not the repo population.
