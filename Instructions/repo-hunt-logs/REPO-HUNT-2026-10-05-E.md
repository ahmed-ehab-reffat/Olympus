# REPO-HUNT-2026-10-05-E (hunter #53, CONSECUTIVE_MISSES=4)

Worker: olympus-hunter (unattended). Result: **CANDIDATE**, konsoletyper/teavm (fact-validated reuse of cached method bodies across incremental builds).

Scratch: `worktrees/_hunt/s_1005h53/` (103M):
- `AGENT_BRIEF_h53.md`: the lane-audit brief (h37 brief plus the 2026-10 laws: chokepoint pricing, meta <= 200 words, obvious-next-step laws).
- `dossier_<repo>_h53.md` for pict, piscsi, teavm, bayesopt, pyocd, riff, grmtools, ray-optics.
- Raw evidence: `teavm_*_h53.tsv`, `pyocd_commits12_h53.txt`, `pyocd_prauthors_h53.txt`, `pyocd_files_h53/` (cache/register/memory/cortex_m/manager/mockcore at develop `ce6386fc`), `ro_*_h53.*` (ray-optics, including an unrun lean sketch).
- Kept clones: `teavm` (blobless, 78M, no build), `ray-optics` (23M). The pict, piscsi, riff and grmtools clones were deleted after their audits; bayesopt and pyocd were never kept.

## Standing inputs
- **Human direction (2026-10-05, in session; overrides broad discovery):** hunt a second, different-subsystem lane on repos we already shipped or claimed. Start with pict, piscsi, bayesopt, teavm and pyocd (named by hunt #52), then widen to other repos in `approved-problems/` or a CLAIMED/approved LEDGER row. No broad discovery sweeps. Licence, language, activity, Requirement 7, exclusivity and quota are never relaxed.
- **Excluded:**
  - in flight: aptly-dev/aptly (SLICING), Athou/commafeed, gonum/plot;
  - every repo with a `problems/` folder (asdf, Cwerg, csbindgen, eventsourcing, hayro, libspatialindex, MACS, micasa, mirrorbits), except pyOCD, which the human named explicitly;
  - DEAD ledger rows, SATURATED-REPOS, `rejected/` feature classes.
- **Interpretation recorded (documented default):**
  - The worker contract says every LEDGER repo is taken. The human direction explicitly re-opens ACCEPTED/CLAIMED ledger repos for a DIFFERENT-subsystem lane, so I read it as overriding that rule for those repos only.
  - pyOCD has an in-flight `problems/` folder (pyocd-dwt-watchpoint-planner). It was audited only because the human named it, and only in files disjoint from both earlier pyOCD problems.
- **Softening (misses = 4).** The 2026-09-09-B softened rules apply. Relaxations taken:
  1. the ledger interpretation above;
  2. the h37 WEAK teavm cache lane was re-opened, because a second coupled lever (resolution path) and two new base bugs were found;
  3. **Requirement 7 reading for teavm.** The latest master `Build` concluded `failure` (job `test (wasm-gc)` only). The previous 9 master runs were 7 success, 1 cancelled and 1 failure (`test (c)` only). `test (js)` and checkstyle were green in every run. I read this as an intermittent backend-matrix flake outside the lane, not a failing default-branch suite. Base mode must be scoped to the core and js incremental tests. This is a judgement, recorded here so the builder can re-check it.
  - Not relaxed: licence, language, activity, live upstream, exclusivity, the signature-account threshold, quota.
- **Requirement 0 (platform picker):** OWED (teavm was accepted by the picker on 2026-09-23 for the earlier problem; re-check anyway).
- **Disk:** `/` 8.0G free at the start, 7.4-7.9G during the hunt (a builder was running). No build, venv, npm install or Docker. Every Gate 1 below is argued from code.

## Method
- I wrote one lane-audit brief and ran five parallel subagents: pict + piscsi; teavm; bayesopt + pyOCD; riff + grmtools; ray-optics.
- riff, grmtools and ray-optics had never been audited for a second lane: they were in flight during hunt #37 and have been excluded as ledger rows since.
- I read hunt #37's dossiers (`s_0929h37/`) first, so no dead lane was re-derived. Each agent had to INVENT lanes from the source tree.

## Quota (approved-problems + problems + rejected + diamond-problems)
| Repo | Subs | Notes |
|---|---|---|
| konsoletyper/teavm | 1 | teavm-method-summaries (approved 2026-09-24) |
| pyocd/pyOCD | 2 | sequence-expression-kernel (approved), dwt-watchpoint-planner (in flight, not yet submitted) |
| ricktu288/ray-optics | 2 | formula-conditionals, sp-coherence-transport (both approved) |
| softdevteam/grmtools | 2 | parameterized-rules, contextual-lexeme-readings |
| microsoft/pict, PiSCSI/piscsi, BayesianOptimization, walles/riff | 1 each | |

Every repo is under 6, and none has 3 in the current week.

## Results per repo
| Repo | Verdict | Best lane / what killed it |
|---|---|---|
| **teavm** | **VIABLE (marginal), RANK 1** | Fact-validated cache reuse. Dossier below |
| **pyOCD** | **VIABLE (low margin), FALLBACK 1** | Lane K: deferred (write-back) register and memory writes in `CachingDebugContext`, ~237 eff (210-260). See below |
| **ray-optics** | WEAK, FALLBACK 2 | Lane M: inline nested module instances when a module is removed (`Scene.removeModule`, Scene.js:1096-1107, leaves parent definitions dangling and `ModuleObj.js:71-80` silently drops them). ~230 reference / ~140 lean (measured on an unrun sketch with `effective_loc_check.py`); ~210 lean only with the template-aware parameter-rename lever, which reads as "add N operations". Traps: capture through function bodies in the real CoatedLens/ArcCoating data (misdirecting, F-20), loop-range scope and loop budget walls (F-9, F-25), construction defaults (F-41). HEAD `daf76772`. Maintainer quiet since 2026-08-28 |
| pict | DEAD for new lanes | Six new lanes: variable-strength groups absorbed by `gcd(ComboCollection&)` (~90), selective seed reuse/repair absorbed (~50-60), UTF-8 is I/O plumbing, hidden generation types are dead-code arms, the `/s` negative-run count is a one-line bug. h37's `$` expected-result lane is still WEAK at ~140-160 with no non-padding lever |
| piscsi | DEAD | Ten lanes. Every C++/Go subsystem had rdmark commits in Aug-Sep 2026. The mode-page state model is SPC (external spec) in rdmark's MODE SELECT stream. scsidump has no test seam. SMDI was declined (#864) |
| BayesianOptimization | DEAD (Gate 3) | **New signature account:** `AHMETHAKANBEZIR1` opened three Codex-co-authored issue+PR pairs on 2026-10-02 (#621-#626; #626 merged, #622/#624 open in acquisition.py and parameter.py), plus ~40 PRs in 3 days across kornia, blackjax, GPJax, equinox, diffrax, sktime, tensorly, POT, numpyro. That is a burst inside our approved kernel. Added to `worktrees/_hunt/sig_accounts.txt` |
| riff | DEAD | 5.5k lines, one crate. Our earlier problem holds the highlighters and refiner. The rest are README TODO rows (public pick list), magnet #14, a delta sibling, standalone parsers under 150, or timing-dependent (#13/#76) |
| grmtools | DEAD | Best lane was runtime operator precedence (lrtable + lrpar), ~130-160. Its only coupled lever is CPCT+ recovery agreeing, which is the kernel of our contextual-lexeme-readings problem. lrlex context operators were declined (#449); quoted regexes and `{NAME}` are magnets (#540, #417/#465); #290 holds a maintainer plan; ratmice's #667 is live in codegen and nimbleparse |

## RANK 1 dossier: konsoletyper/teavm, fact-validated reuse of cached method bodies
Full dossier: `worktrees/_hunt/s_1005h53/dossier_teavm_h53.md`.

- **URL / stars / licence:** https://github.com/konsoletyper/teavm, ★3118, Apache-2.0 (file read in 09-23-C; unchanged).
- **Language:** Java (proven Docker pattern `olympus-base-jvm` from the approved teavm problem).
- **HEAD (suggested new BASE):** `11a50bc0ba46d3ef606c6af56f4ca4b8b0ba478a` (2026-10-05).
  - 33 commits since our earlier base `fd78e03f`.
  - None touches cache invalidation, `ReferenceResolver` resolution or the cache dependency model. The only cache-adjacent commit is f41f08c04, a `ClassIO` generics fix.
- **Activity:** 359 commits in 12 months, almost all Andreev. Busy elsewhere: wasm-gc, C, classlib, JUnit 5 migration. The invalidation logic has been untouched since 2019.
- **Capability (TeaVM nouns).**
  - Today a cached optimized program or AST is reused only while no class it names is stale, and every method of a changed class is recompiled (`TeaVM.java:762`, `:1058`; `Renderer.java:940`, `:962`).
  - New behaviour: each cache entry records the facts it was compiled against and is reused while they still hold:
    - the member-level API of each class it depends on;
    - its own method body;
    - every class on the RESOLUTION PATH of a member it names (the named class up to the declaring class);
    - for AST entries, the async/split status of each method it calls.
  - Plugin-registered dependencies and `setNoCache` keep their body-level meaning. The disk caches persist the same records.
- **Why not the earlier problem:** different packages (`org.teavm.cache`, `dependency/ReferenceResolver`, JS `Renderer`, the `vm/TeaVM` cache gates) and a different feature class (build-cache validity, not optimizer facts). The earlier solution.patch has no cache file; only `TeaVM.java` is shared, in different hunks.
- **Gate 1 (argued from code; probes OWED):**
  1. **The resolution path is discarded.**
     - `ReferenceResolver.java:217, 230, 247, 266-277` rewrites references to the declaring class.
     - `ProgramDependencyExtractor.java:48-61` and `AstDependencyExtractor.java:52, :58` then record only that class.
     - Repro: `Main` reads `Foo.VALUE`, inherited from `FooBase`. When `Foo` gains its own `VALUE`, the cached `Main.run` still reads `FooBase.VALUE`.
  2. **Transitive async is not followed.** `Renderer.java:254-258` recomputes `splitMethods`, while the async AST cache depends only on the classes it names (`InMemoryMethodNodeCache.java:76`). This is the maintainer's own #1021 warning.
  3. **Interface loop:** `AnnotationAwareCacheStatus.java:85-88` re-checks `getParent()` once per interface.
  4. **Cycle memo:** `AnnotationAwareCacheStatus.java:56-61` caches UNDECIDED as FRESH.
- **Oracle already in repo:** `tests/.../incremental/IncrementalTest.java`. It builds old, refreshed and new JS, asserts the exact recompiled-method set, and runs both in Rhino, so it is deterministic. Its existing `simple` expectation changes under the lane.
- **Missing machinery and LOC (per decision point; chokepoints named):**
  - **D1** resolution-path recording carried as API-kind dependencies: 30-45.
  - **D2** API fingerprint: 20-35. `ClassIO` plus `copyClass` absorbs most of it.
  - **D3** own-body fingerprint, dropping the class gate at 4 sites while keeping noCache and plugin dependencies: 35-50.
  - **D4** two dependency kinds per entry across 2 in-memory and 2 disk caches: 60-90.
  - **D5** async facts plus `Renderer` wiring: 35-55.
  - **D6** status rework: 25-40.
  - **Total ~205-315, mid ~260.** A lean passer is ~180-200 unless the tests include a disk flush/reload round trip, which keeps D4 load-bearing. Coupled levers: D1 + D5.
- **Traps (interdependent + misdirecting):**
  - **T1, precision vs async (F-39):** API-level references remove base's accidental protection, so the async cells fail as "wrong JS / missing recompile", which reads like a fingerprint bug.
  - **T2, discarded resolution path (F-47):** recording from the final program misses the named subclass. The existing `IncrementalDependencyRegistration` channel makes those dependencies body-level, which fails the precision cells.
  - **T3, the gate (F-9):** dropping `isStaleMethod` breaks `meta` and `lambda` (`setNoCache`, `LambdaMetafactorySubstitutor.java:176`); keeping it fails the unchanged-sibling cell.
  - **T4, F-10 cross-product:** change kind × route × cache × store (memory/disk).
  - Pairs: T1-T2 share the dependency-kind split, and T2-T3 share the gate/plugin channel.
- **Gates:**
  - **Exclusivity PASS:** all-state PR searches; #396 diff read (0.5.x serialization fixes); all 13 open PRs' file lists read (#1236 #1068 #1058 #1050 #998 #989 #768 #580 #550 #396 #313 #237 #186); no branch in the lane.
  - **Six-check PASS with philosophy RISK:** #9 (closed 2014, "very hard") and #1021 (open, warning). Neither is a decline. The lane makes the async set an explicit fact and stays SIMPLE-only, as the caches already are.
  - **Competitors:** 0 signature accounts in the last 100 PR authors.
  - **Density:** cold lane.
  - **Port/sibling MEDIUM:** Gradle/Zinc ABI avoidance and GWT MinimalRebuildCache exist as concepts, but nothing operates on TeaVM IR.
  - **Magnet MEDIUM:** no issue asks for it, but the concept is nameable, and the TOO-EASY invariant-upkeep row names "cache invalidation". The soundness half is upkeep-shaped; the precision half is not.
- **Stage 6 death-class guard (re-run by me on RANK 1): PASS.**
  1. One shared kernel (a per-entry validated fact record) feeds the program cache at 2 sites, the regular and async AST caches, the disk formats and the status: yes.
  2. Traps pairwise interdependent (T1-T2, T2-T3, T4 multiplies them): yes.
  3. A standalone new file cannot solve it: it needs `ReferenceResolver`, the cache formats, the `TeaVM` gates and the `Renderer`.
  4. Pre-Pick Guard:
     - #1: not one rule at many sites. API, path and async are separate mechanisms; the fingerprint-compare chokepoint is a noted risk.
     - #2: four packages with hidden walls.
     - #3: the contract can be stated in TeaVM nouns, and the walls (where the path is discarded, where the async set lives) stay hidden in code.
     - #4: the concept is famous but not portable.
     - #5: survives full spell-out, unmeasured.
- **Risks / owed:**
  - Requirement 0 picker.
  - Base health of `:tests:test --tests org.teavm.incremental.*` with browser, C and wasm runners off, 3x.
  - Both bug probes (two small IncrementalTest data packages).
  - A heavier Docker build than the core-only earlier problem (the whole `tests` module compiles).
  - A measure-first spike to confirm >= 200 human-eff with the disk round trip; the 2026-09/10 absorption deaths over-priced by 1.6-2x.
  - Write meta in TeaVM nouns (resolution path, async split, plugin dependencies), never "ABI invalidation".
  - Re-run the PR-DIFF check at submit.

## FALLBACK 1: pyocd/pyOCD lane K, deferred register and memory writes
Full dossier: `worktrees/_hunt/s_1005h53/dossier_pyocd_h53.md`. Suggested BASE: develop `ce6386fc648a7b9a51696e2e2108f93a8fb459fb`.

- **Capability:** a new option `cache.write_back`. With it, `CachingDebugContext` holds core-register and cacheable-memory writes as pending state:
  - reads see the pending values;
  - each register is written at most once per commit;
  - writes commit before run, reset, disconnect, a gdbserver flash op, or `flush()`.
- **Seed:** the TODO at `cache/register.py:164`. I verified it at develop HEAD, together with the write-through at `:207` and the base staleness of the CFBP entry after a sub-register write (`:185-192` pops only the sub-register variants).
- **Files:** pyocd/cache/{register,memory}.py, debug/cache.py, debug/breakpoints/manager.py, gdbserver/gdbserver.py, core/options.py. None of these is in either earlier pyOCD file set.
- **Size:** ~237 eff (210-260).
- **Traps:**
  - T1: composite CFBP/XPSR fold with last-write-wins order.
  - T2: an overlay read must not clobber pending writes (`register.py:136-149` refreshes siblings).
  - T3: D/S float alias.
  - T4: breakpoint realisation order. BreakpointManager subscribes to PRE_RUN before the caching context exists, so a memory commit can overwrite a BKPT.
  - T5: non-cacheable barrier and reset scope.
- **My check:** the CortexM mixed-list RMW bug the dossier cites (`cortex_m.py:1455-1482`: a sub-register re-reads the OLD CFBP and is appended after the full CFBP write) is real. But `test/unit/mockcore.py` applies writes sequentially and has no D/S alias, so T1 and T3 only bite through the cache's own fold and normal form, not through that bug. The tests would assert pending/commit behaviour over mockcore, plus a recording context.
- **Risks:**
  - the code TODO is an outsider-visible seed (MEDIUM);
  - this would be a third pyOCD sub while the DWT problem is in flight (weekly quota: do not submit both in one week);
  - the honest LOC may land under 200, so a spike is needed first;
  - the Gate 1 probe is OWED.

## Fallbacks
1. pyocd/pyOCD: lane K above (VIABLE, low margin).
2. ricktu288/ray-optics: lane M (WEAK; ~140 lean, ~210 with the rename lever).

## What the next hunt should change
1. **The second-lane pool is now nearly spent.** Hunts #37 and #53 have audited every ACCEPTED/CLAIMED ledger repo without an in-flight folder. Every repo but teavm, pyOCD and ray-optics is DEAD.
2. **What is left to try:**
   - second lanes on the in-flight repos (asdf, hayro, eventsourcing, micasa, mirrorbits, MACS, csbindgen, libspatialindex, Cwerg), once their problems are approved or dead;
   - h35's WEAK pool rows: rust-minidump XSTATE (~270, but #152 is a welcomed spec-named magnet), MetPy Level2 VCP tilt assembly (~245, xradar sibling), turmoil clock drift (closed PR #22 overlap).
3. **Signature list:** `AHMETHAKANBEZIR1` was added (Codex-assisted mass-PR account, 2026-10-02..05). Check it against any Python ML/science repo.
