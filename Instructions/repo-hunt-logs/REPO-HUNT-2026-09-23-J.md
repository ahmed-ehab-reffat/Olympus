# REPO-HUNT 2026-09-23-J (hunter #23, CONSECUTIVE_MISSES=0)

Unattended olympus-factory hunt. CONSECUTIVE_MISSES=0, so no extra softening beyond the rules that are
already permanently softened in SKILL.md (2026-09-09-B). Standing rulings applied: AI root file =
ranking penalty; AI commits/trailers = lane-scoped (2b softened).

Method (hunt #22 hint): take the kill rows in `Instructions/SATURATED-REPOS.md` whose ONLY recorded
reason is a rule the 2026-09-09-B softening changed, cross them against the proven pool, re-verify
the unchanged hard rules (licence incl. vendored, activity, language share, quota, >=500 stars), then
lane audit + Stage 6 guard + fork-branch exclusivity scan. SATURATED-REPOS.md is NOT edited here;
stale rows are listed at the end for the human.

Requirement 0 (platform picker): OWED on any candidate (unattended run).

Excluded up front: every LEDGER repo (vrp, pict, BayesianOptimization, teavm, piscsi, pyOCD,
siliconcompiler, pyfakefs, libspatialindex, csbindgen, oxipng, messageformat, stremio-core,
openglobus), LaurenzV/hayro, UDST/urbansim, gkurt/tegaki, TNG/ArchUnit, Khan/genqlient,
capnproto/capnproto, everything adjudicated in the 09-23-C..I logs (incl. the 24 re-opens of hunt #22).

Scratch: `worktrees/_hunt/s_0923h23/`.

## Stage 0-bis x SATURATED-REPOS softened-only kill rows

Pool rebuilt from frontmatter (`s_0923h23/pool.txt`, 80 repos). Frontmatter misses the older
approvals, so the pool was widened by `ls approved-problems/ rejected/` name prefixes: that adds
turmoil, quint, deadpool, grmtools, pyparsing (2), rmk (2), scikit-bio, mpmath, OpenPNM (rejected,
too easy), vivisect (rejected, unsolvable-under-review).

Kill rows in SATURATED-REPOS.md (and the 09-20-D / 09-21 pool verdicts) whose ONLY recorded reason
is a rule 2026-09-09-B or the 2026-09-23 rulings changed, and that no log dated >= 09-10 re-judged
under those rules:

| Repo | Pool? | Recorded kill (where) | Softened rule that now applies |
|---|---|---|---|
| tokio-rs/turmoil | YES (turmoil-link-bandwidth, approved 17%) | "capability-consuming" (pool table; 09-21 pool line) | velocity = lane verdict |
| scikit-bio/scikit-bio | YES (feature-hierarchy) | `steps-re` competitor visit (09-01; 09-20-D) | one visit outside lane = note |
| pyparsing/pyparsing | YES (2 approved) | 13 open PRs + `action_required` CI (09-18) | Req 7 default-branch conclusion |
| informalsystems/quint -> quint-co/quint | YES (temporal-properties) | "company velocity" (09-11) + effects lane absorbed | velocity = lane verdict |
| rmk-rs/rmk | YES (2 approved, sibling ws) | "daily maintainer AI sweep over the engine" (B3-duodecies) | AI lane-scoped |
| mpmath/mpmath | YES (odefun-events) | competitor-visited (09-01-C) | 1 visit = note (if only 1) |
| deadpool-rs/deadpool | YES (keyed-pool) | thin domain + ChrisJr404 x1 (09-10) | competitor x1 = note (thin domain is structural) |
| softdevteam/grmtools | YES (parameterized-rules) | one lane (LR counterexamples) sibling-dead (09-04) | lane verdict, other lanes unaudited |
| PMEAL/OpenPNM | YES (rejected too-easy) | two lanes prior-art-dead, `binggao1230` x1 | 1 visit = note; other lanes |
| vivisect/vivisect | YES (rejected) | "our own work" (09-21) | subsystem-level self-collision only |
| potassco/clingo | no | `copilot-swe-agent` PRs (09-09-B) | AI lane-scoped |
| twpayne/go-geom | no | `binggao1230` x1 (09-09-B) | 1 visit = note |
| dyn4j/dyn4j | no | 0 open issues, "finished" (09-09-B) | zero-issue = penalty |
| scalesim-project/SCALE-Sim | no | "Running Copilot Code Review" on default (09-16-C) | AI lane-scoped (review bot = note) |
| LaihoE/demoparser | no | Copilot review + 2 accounts in ONE lane (09-16-C) | lane-scoped: other lanes |
| maroba/findiff | no | `claude` commit author (09-09-B) | AI lane-scoped |

Not re-opened (kill reason is a hard or unchanged rule): whitebox-tools, dyon (no CI at all, Req 7),
event-reduce (CI failing), pyRiemann (3-PR one-day burst), ezdxf / music21 / participle / jet (2+
signature accounts), openfga (magnet + exclusivity), mvdan/sh (8.9k famous, commit stream IS the gap
class), go-astits (reference toolchain), amaranth (RFC-gated Gate 8), techan (codex sweep IN the
indicator lane), cvxpy / dowhy / jMetal / ketcher / OpenMS (repo-wide AI sweeps, 70-250 trailers),
iced / rspirv / fonttools / sqlfluff / pulldown-cmark (spec-named capability space, unchanged rule).

(Session restart mid-hunt: the two screening subagents for groups P (pool re-opens) and S
(non-pool re-opens) were cut off and relaunched; partial stream files in `s_0923h23/gp`, `gs`.)

## tokio-rs/turmoil (pool, 1 approved sub) — lane audit (in progress)

**Mechanical (2026-09-23):** ★1262, MIT (single LICENSE), Rust 100%, CI `CI Build` green on `main`
(one Release-plz `failure` = publish job, not tests). Last push 2026-07-21; 1 commit in 90 days, but
the 12-month stream is real code (turmoil-net socket stack, turmoil-fs, simulated io_uring, TCP flow
control, in-flight faults). Quota 1/6 (`turmoil-link-bandwidth`, approved 17%, consumed `top.rs`
link capacity + `envelope.rs` + stats). Old kill "capability-consuming" = the mcches/marcbowes wave
of Apr-Jul 2026, which built NEW crates (net, fs, io_uring) and has stopped; under the softened
rule it is a lane verdict, and those lanes are dead (theirs), the core crate's time model is not.
No AI marks in 12 months (one `copilot/rebase` fork branch on sevki's fork = note). PR authors
(teskje, jgrund, tneely, atreyas, Benjscho, raskyamazon, LucioFranco, manifest, nickgian, tottoto)
= zero signature hits; all Amazon/Materialize-style genuine contributors. Open PRs: only #278
release bot. Maintainer philosophy #285 (mcches, 2026-08): "I don't see the turmoil crate as the
place to get fancy, rather it's more batteries included" (rejects a discrete-event scheduler
rewrite; fault-injection "hardship" is the README's stated purpose).

**Invented lane: per-host clocks (offset step, drift rate, freeze/resume).** Base has ONE clock
per sim: every host runtime is ticked by the same `tick` (`sim.rs:421-509`), `HostTimer`
(`host.rs:158-218`) derives `elapsed()` from the runtime Instant, and `sim_elapsed()` =
`start_offset + elapsed()`, `since_epoch()` = epoch + `sim_elapsed()`; turmoil-fs mtimes and
io_uring take `host.timer.since_epoch()` (`sim.rs:467-489`); crashed hosts are ticked to keep up
(`sim.rs:505-510`, #216). Nothing models skew/drift/pause (grep skew|drift|pause|freeze = 0; the
only mention is the `rt.rs` doc comment "Each runtime may have a different sense of now which
simulates clock skew"). Issues: #21 (2022, virtual time) only; no request, no PR. Fork-branch scan:
38 forks pushed after creation, branches listed; the only clock-adjacent branches are
nickgian:global-clock (= merged #216, crashed-host catch-up) and zakvdm:sim_elapsed (= merged
sim_elapsed API); tthebst:tim/msg-dup (message duplication, off-lane). CLEAN. turmoil absent from
the LabTesing deepswe list.

**Philosophy / removal records:** #207 (2025-01) reported ACCIDENTAL skew (crashed hosts' clocks froze);
#216 fixed it by ticking stopped hosts so `sim_elapsed()` can serve "as a form of global clock". No
maintainer statement against configurable skew; the fix pins a convention the lane must keep
(`sim_elapsed` = true simulation time). No CHANGELOG removal of any clock feature. #285 (Aug 2026):
mcches declines a discrete-event scheduler rewrite as "getting fancy"; a clock-fault knob is
"hardship", the README's stated purpose. Gate 8: acceptable, note the #285 tone.

**Sibling check:** madsim has no skew (code search empty). `osukhoroslov/anysystem` (DSLab Rust
simulator) has a per-node `clock_skew` offset in `node.rs`: a constant added to reads, no drift, no
pause, no async runtime. Nothing cribbable for the hard part here (tokio paused-runtime advancement,
HostTimer derivations, crash/bounce catch-up). Derivative risk MEDIUM (outsider-nameable "clock skew
nemesis" class of Jepsen/FoundationDB; no issue, no PR, no fork branch asks for it) -> mitigate by
phrasing on turmoil's own three clocks.

**Base measurements (HEAD 684acc1a = the approved sub's own BASE; nothing landed since):**
`cargo test -p turmoil` 3x: 96 + 30 + 5 (2 ignored) + 2 + 1 passed, 0 failed, identical all three
runs (~3 s). Target 1.4G, deleted.
**Probe (scratch test, removed): a sub-millisecond tick already makes turmoil's clocks disagree.**
`tick_duration(1500us)`, 10 steps: `sim.elapsed()=15ms`, host tokio `Instant` elapsed `=19ms`,
`turmoil::elapsed()=14.5ms`. tokio's paused timer wheel is millisecond-granular, so
`Rt::tick(d)`'s `sleep(d)` rounds each tick UP to the next ms. Any rate/drift feature that ticks a
host by `tick * rate` hits this wall: a 1 ms tick at +0.1% drift advances the host 2 ms per tick
(100% fast). The fix is whole-ms advancement with a carried remainder, kept consistent with
`HostTimer` (which today adds the unrounded `tick`). This is the misdirecting lead trap: the failing
assertion reads "host clock runs 2x fast", the cause is the tokio timer resolution in `rt.rs`.

**Lane thesis (RANK 1 candidate):** give each host its own clock. `Sim::set_clock_offset(host,
signed step)`, `Sim::set_clock_rate` / drift in ppm, `Sim::pause(host)` / `Sim::resume(host)`, and
introspection. Semantics to state: `sim_elapsed()` stays true simulation time on every host (#216
convention); tokio time and `turmoil::elapsed()` are the host's MONOTONIC clock (rate applies, offset
never moves it backward); `since_epoch()` is the host's WALL clock (rate + offset, may step backward,
so the Duration arithmetic needs a signed carry); turmoil-fs mtimes and io_uring `now` follow the
wall clock (already wired through `host.timer.since_epoch()`); a crashed host keeps ticking at its
own rate (the #216 path); a bounce keeps the host's clock (new runtime, old `HostTimer`); a paused
host's software does not run and nothing is delivered into it, then on resume its clocks jump by the
paused span in one step (timers due in the gap fire at once) while messages that arrived meanwhile
are handed over in send order.

**Missing machinery / eff-LOC sketch (decision points, not surfaces):** (1) per-host rate with a
whole-ms carry driving `Rt::tick` and `World::tick` consistently ~45; (2) `HostTimer` split into true
vs host-monotonic vs host-wall with a signed offset ~50; (3) step-loop pause handling (skip tick,
skip `deliver_messages`, stopped-vs-paused distinction for crash/bounce/is_host_running) ~40; (4)
resume jump through the tokio runtime + timer catch-up ~25; (5) crash/bounce interplay (crashed host
at its own rate, bounce keeps clock, pause of a crashed host) ~20; (6) public API on `Sim`/`Builder`
with `ToIpAddrs` selectors and error on unknown host, plus a `HostClock`-style snapshot ~60.
**~240 human-eff** across `sim.rs`, `rt.rs`, `host.rs`, `world.rs`, `builder.rs`, `lib.rs` -> the
150-250 band, so it needs the coupled second lever, which is (3)+(4) pause/resume (it shares the
tick kernel and the crash/bounce paths). Design to ~260-300 by keeping pause in scope.

**Stage 6 guard:**
1. Shared kernel feeding several surfaces: YES. The per-host tick (rate + ms carry) drives tokio
   timers, `turmoil::elapsed`, `since_epoch`, fs mtimes, io_uring `now`, crashed-host catch-up.
2. Interdependent: YES. Scaling `HostTimer::tick` also scales `sim_elapsed` (derived as
   `start_offset + elapsed()`), breaking the #216 global clock; scaling `Rt::tick` without the ms
   carry double-advances tokio (probe above) while `HostTimer` stays right, so `turmoil::elapsed`
   and tokio disagree; the offset applied to the monotonic path makes `elapsed` go backward; pause
   implemented as "treat like crashed" ticks the clock (#216 path) and loses the resume jump, while
   pause implemented as "skip everything" lets messages bypass the paused host's socket order.
3. Standalone file: NO (six files, the step loop and the runtime wrapper).
4. TOO-EASY guard #1 uniform wrap: no (three clocks with different rules, plus the tokio resolution
   wall). #2 single-subsystem fully-specified transform: it is the time subsystem, but the hidden
   wall (ms-granular paused timer wheel, `sim_elapsed` derivation) is not nameable in the prompt
   without giving the fix. PASSES.

F-10 cells: {offset, rate, pause} x {running, crashed, bounced, paused} x {client, host} x {tick a
whole ms, tick a fraction of a ms}. F-9: the #216 convention lives in `sim.rs` while the derivation
lives in `host.rs`. F-34-adjacent: `HostTimer::now` is reset per step.

**Verdict: VIABLE, RANK 1 provisional** (pending group P / S results). Risks: derivative MEDIUM
(famous fault class, mitigated by repo-model phrasing + F-10 table); #285 "not the place to get
fancy" tone; approved same-repo sub (network links) is a different subsystem but the dedup engine
sees "turmoil fault injection" twice; `Sim::step` tests must pin `tick_duration` and assert clock
values, not timing races; ★1262 fine; quota 2/6 after this.

**⚠️ Correction after the full PR history (not only the last 60): turmoil downgraded to CONDITIONAL
FALLBACK.**
- **Closed PR #22 "Allow pause/resume of hosts" (marcbowes, 2022-09)** publishes a diff (host.rs +12,
  lib.rs +17, sim.rs +4, world.rs +14) that skips a paused host in the step loop so its clock
  freezes ("the server thinks this test only takes 5ms, while the client thinks over a second").
  Our own `approved-problems/turmoil-link-bandwidth/feedback.md:204-207` recorded exactly this and
  DROPPED the per-host clock skew candidate at that time for it. Under the exclusivity HARD RULE a
  closed PR implementing the central capability kills it at any age. So PAUSE is out of the lane,
  and the skew/drift lane is arguable: #22 implements divergence-by-freeze on a 2022 architecture
  (no HostTimer, no Rt wrapper) and none of the rate/offset machinery, but it shares the file set
  and the "host clocks diverge" capability, which is the overlay a scope gate reads.
- **Closed PR #178 (sgbalogh, 2024-07)** publicly documents the millisecond resolution of
  `tokio::time::sleep` and proposed only a builder validation (unmerged). The wall is still in the
  code, but it is publicly explained, which weakens its misdirection.
- Without pause the lane is offset + drift (+ slew/adjtime-style gradual correction as the coupled
  lever, + sub-ms tick consistency): sketched ~200-240 eff. In the band that needs a coupled lever,
  with an exclusivity argument to win at the scope gate. NOT RANK 1 material on its own.

## Group P verdicts (pool re-opens, subagent) — 0 viable of 9

| Repo | Verdict | Reason under the softened rules |
|---|---|---|
| scikit-bio/scikit-bio | DEAD | 3 distinct signature accounts merged in the last 100 PRs (`steps-re` #2504, `youdie006` #2536, `latent-9` #2525) — over the 2-account threshold |
| pyparsing/pyparsing | DEAD | 4 signature accounts: `binggao1230` #639-642, `chuenchen309` #645-648 (4 in 3 days = burst), `dualfroz` #658, `youdie006` #657. CI itself green (the old action_required reason is moot) |
| mpmath/mpmath | DEAD | `binggao1230` x5 merged + `Sanjays2402` #1150 merged (2 accounts) + a merged `codex/` branch |
| rmk-rs/rmk | DEAD | maintainer agent stream (`codex/daily-review-*`, 25 AI marks/90d) still lands across storage, sleep, USB DFU, keymap/combo: repo-wide sweep, every lane hit; root CLAUDE.md |
| PMEAL/OpenPNM | DEAD | every algorithm class v3 lacks ships at tag v2.8.2 (IonicConduction, NernstPlanck, NonNewtonianStokesFlow, OrdinaryPercolation, MixedInvasionPercolation, Porosimetry, metrics); conductance under open PRs #2740/#2849/#2880; models/ is a formula registry |
| deadpool-rs/deadpool | DEAD | thin core already used by our keyed pool; every remaining lane is a long-open magnet (#359 max_lifetime, #245 min_size, #299 shrink, #167, #196, #166, #67) |
| softdevteam/grmtools | WEAK | clean (ratmice/ltratt only; real CI = softdev buildbot, green on HEAD 8ce095a) but no lane: lexer context declined (#449 "lrlex is, intentionally, fairly simplistic"), grammar analysis #290 has a published design gist + bison names it, `&mut` parse-param #404 ~130 eff and welcomed-queue, MF/Panic recoverers REMOVED (CHANGES.md:541), IELR = lalrpop sibling, codegen modules = maintainer's current #667/#611 |
| quint-co/quint | WEAK | `quint run` now defaults to the Rust backend (our TS-runtime class is legacy); effects absorbed; types = language carve-out; flattening tracker-bound (#1148 decision) and the #1175 repro does not reproduce on main; ITF/MBT has informal's own sibling tools; shrinking #1376 / coverage #1758 are long-open magnets |
| vivisect/vivisect | WEAK | maintainer AI crew (`hermes-crew-337`, `aragorn-1337`, org-internal) across ELF/aarch64/vtrace/VAMP; maintainer WIP PRs hold PDB #675, DWARF #619, CLR #673, codeflow #662, pointers #640, C structs #633; ARM symboliks = per-opcode port; test corpus needs network |

## Group S verdicts (non-pool re-opens, subagent) — 1 viable of 6

| Repo | Verdict | Reason |
|---|---|---|
| potassco/clingo | DEAD | real development on `wip-20` (a rewrite with no shared history with master, each prior art for the other); grounder internals live (GregoryGelfond #660/#663 + rkaminsk); ASP surface = carve-out; re2c/bison + 8 submodules. The copilot PRs were CI/docs (note only) |
| twpayne/go-geom | DEAD | `xy` is a JTS port (javadoc `<code>` tags, CGAlgorithms/LineIntersector/RadialComparator): port law on every algorithm lane; the rest is spec transcription or <150 eff |
| scalesim-project/SCALE-Sim | DEAD | Req 7: every test step `continue-on-error: true` (CI cannot fail), golden-CSV diffs only, unpinned deps, ★523, last code 2025-12, ~30 public dev branches on the likely lanes |
| LaihoE/demoparser | DEAD | Test workflow red on every run since 2026-08-18 (last green 2026-04-21); usercmd lane 5-account burst + `SAY-5` merged; oracle is one 60 MB demo + 18k-line golden file |
| maroba/findiff | DEAD | ★508; unpinned deps; maintainer one-day feature sweep + `claude/` branches; `binggao1230` open PR #112 IN the non-uniform-grid lane; lanes are named textbook FD methods (sympy, pystencils) |
| **dyn4j/dyn4j** | **VIABLE** | dossier below |

## dyn4j/dyn4j — ★538 — RANK 1

- **Mechanical (re-verified by me 2026-09-23):** BSD-3-Clause (single holder William Bittle, no
  vendored code or jars), Java 100% (4.7 MB), one dep (junit 4.13.1). Maven CI green on `master`;
  the `Maven CD` failures are the release job (not tests). Activity: 7 commits in 12 months, all on
  2026-07-18 (release 6.0.0 incl. the real code commit "Angular limit and reference frame changes").
  Requirement 3/6 PASS, but thin: one release burst in two years (ranking penalty; re-check the
  platform's active-maintenance precheck at Requirement 0 time). 0 open issues (penalty only).
  No AI marks, no root AI file, no PR authors since 2024 (none on the signature list), not in the
  LabTesing list, quota 0/6. SATURATED-REPOS.md:978 row "no test suite / finished" is STALE: the
  subagent ran 2385 JUnit tests from 194 classes, identical 3x, 1.7 s each (plain `javac --release
  11` + JUnitCore; the pom's `-Xdoclint -Werror` + a `<release>6</release>` execution needs JDK <= 11
  under Maven, so test.sh should drive javac/JUnit directly or the image carries JDK 11).
- **Maintainer history (Gate 8, Stage 2d):** #293 (2024-06, wnbittle) built the `Copyable` program
  for Body, Fixture, Shape, Joint, Force, Filter (6.0.0), explicitly a DEEP copy ("nothing on the
  copy references the original") via `copy()`, not native `clone` "for reasons, some philosophical".
  The world was never in scope; JNightRider's list stopped at bodies/joints. wnbittle: "native
  serialization support going very slow" = adjacent maintainer lane (Serializable, not copy), not
  shipped in 6.0.0. No removal record (RELEASE-NOTES searched for serializ/snapshot/clone/copy/no
  longer/removed). Discussion #300 ("Prediction") motivates stepping a copy.
- **Lane: `World.copy()` (the PhysicsWorld deep copy) whose future evolution is bit-identical.** The
  copy is independent of the original and stepping both yields identical transforms and velocities.
  **Reproduced on base by me (2x):** two identically built worlds are bit-identical after 90 steps
  (engine deterministic); the best composition of the 6.0.0 API (new `World`, `body.copy()` in order,
  `joint.copy(mapped1, mapped2)`) is equal at t0 and **diverges at step 1**.
- **Missing machinery (the algorithm the repo does not contain):** an identity-remapping structural
  copy of the whole simulation state: the `collisionData` LinkedHashMap keyed by
  `CollisionPair<CollisionItem>` with ContactConstraint/SolvableContact warm-start impulses; the
  default broadphase `DynamicAABBTree` topology + `leaves`/`updated` insertion order (private fields,
  `DynamicAABBTree.java:54-63`) and the separate `ccdBroadphase` tree (`AbstractPhysicsWorld.java:215`);
  ConstraintGraph node order; TimeStep `dt0`/`dtRatio`; the `time` accumulator, `updateRequired`,
  CCD data and at-rest state. `Sap` compares proxies by min-x, min-y, then falls back past equality
  (`AABBBroadphaseProxy.java:57-69`) and keeps a `HashMap` of proxies iterated at `Sap.java:164`, so
  identity hashes can reorder ties: the author must either scope Sap out explicitly or require
  structural (not re-insertion) copies and verify Sap determinism first.
- **Eff-LOC sketch (subagent, checked against the file map):** ~330 human-eff (range 280-420): tree
  copy with item remap ~60, Sap/AVLTree + BruteForce ~45, broadphase adapter/decorator plumbing ~20,
  collision-data remap ~35, ContactConstraint + SolvableContact ~45, ConstraintGraph ~40, TimeStep
  ~10, AbstractCollisionWorld + AbstractPhysicsWorld copy constructors ~90, API ~10, remap helper ~25.
  Four packages (world, collision/broadphase, dynamics/contact, dynamics). >250 -> PROCEEDS.
- **Stage 6 guard:** (1) one shared kernel, the body/fixture -> CollisionItem identity remap, feeds
  joints, contacts, both broadphase trees and the constraint graph: YES. (2) Interdependent: carrying
  impulses without pair order, or pair order without tree topology, still diverges; the failure
  reads as "position mismatch after k steps", which points away from the missing state
  (misdirecting): YES. (3) Standalone file: NO (private state in 4 packages). (4) Uniform wrap: no;
  single-subsystem transform: no. PASSES.
- **Exclusivity / fork scan (subagent):** forks active since creation: JNightRider, OrganizationUsername
  (master only, synced), victorlira (2 auto build branches), Ewan-Brown (javadoc). JNightRider's old
  `cloning` branch (body-level `Copier`, 2024) is deleted and was absorbed at body level by 6.0.0;
  nothing world-level. PR/issue search by class (world copy, snapshot, serialization, clone,
  rollback, determinism, save state, warm) = nothing in the world-copy class. CLEAN.
- **Sibling / port check:** Box2D, jbox2d, Chipmunk: no world clone. Rapier has a serde snapshot
  (different model, Rust). dyn4j-sandbox XML save/load covers bodies/joints only (no contact or
  warm-start state; name it out of scope). Not a textbook algorithm.
- **Derivative (2b):** outsider summary "add a deep World.copy() to dyn4j" is nameable, and it is the
  obvious next step after #293's Copyable program (MEDIUM magnet). No open issue asks for it (0 open
  issues). Mitigate with the repo-model contract (bit-identical continuation, warm-start and
  broadphase order, independence both ways, copy-of-copy, copy after removals, CopyException for a
  non-overriding subclass as in the 6.0.0 Body/Joint contract, explicit listener/userData policy).
- **F-10 cells for the author:** original unaffected vs a never-copied twin; copy after removals
  (tree shaped by removals); sleeping islands; CCD pairs; joints incl. unary joints; copy-of-copy;
  mutating the copy leaves the original alone; tied AABB mins (only if Sap is in scope).
- **Risks:** thin activity (one burst in two years, re-check at submit); ★538 (38 over the floor);
  thoroughness shape (field copying is enumerable; the bit-identity contract is what couples it);
  a lean reflective deep-cloner shortcut (JDK module encapsulation blocks reflection into java.util,
  partial defence; a passer that clones reflectively would also be under the LOC floor on its own
  diff); javadoc required on new public API (repo convention, zero LOC value); JDK 11 vs 21 toolchain.
- **Still owed:** Requirement 0 picker; Gate 5 dates at scope-lock; Gate 7b re-run at submit; Gate 8
  six-check; Docker on olympus-base-jvm (incl. the uid-1000 check); Sap determinism measurement.
  Clone kept at `worktrees/_hunt/s_0923h23/gs/dyn4j` (HEAD bcf942adaa9bfd32a1abd043cbc9021ab158d0ad,
  probe in `_b/probe/Probe.java`, jars in `_b/lib`).

## Ranking

1. **dyn4j/dyn4j** — World deep copy with bit-identical continuation (RANK 1, guard PASSES).
2. **tokio-rs/turmoil** — per-host clock offset + drift (no pause; closed PR #22 holds pause and the
   file set), ~200-240 eff, needs a coupled lever and an exclusivity argument. Conditional fallback.
3. Nothing else survived (grmtools / quint / vivisect WEAK, no lane).

## Stale SATURATED-REPOS.md rows for the human (not edited by the hunter)

- `:978` dyn4j "no test suite / finished" -> 2385 JUnit tests, green CI; 0 issues is a penalty only.
- pyparsing (09-18 note "13 PRs + action_required") -> now 4 signature accounts (dead for that).
- scikit-bio -> 3 signature accounts (steps-re, youdie006, latent-9), not a single visit.
- mpmath -> `binggao1230` x5 + `Sanjays2402`.
- quint row still says informalsystems/quint (canonical quint-co/quint); `quint run` defaults to Rust.
- vivisect -> record `hermes-crew-337` / `aragorn-1337` as the maintainer's own AI crew (not rivals).
- turmoil pool line ("capability-consuming") -> the wave built new crates and stopped (1 commit/90d);
  the clock lane is held back by closed PR #22 (pause), not by velocity.
- SCALE-Sim -> Req 7 (all test steps continue-on-error), not the Copilot review.
- demoparser -> Req 7 (Test red since 2026-08-18) + usercmd burst + SAY-5.
- findiff -> `binggao1230` in-lane PR #112.

## Budget spent

Proven pool x SATURATED softened-only rows (16 re-opens): turmoil by me (clone, 3x suite, probe,
full PR history), 9 pool repos (group P) and 6 non-pool repos (group S) by two subagents (relaunched
once after the session restart). No fresh GitHub sweep was needed. One build (turmoil, 1.4G,
deleted); dyn4j compiled with plain javac into a temp dir (deleted). Disk 12G free.

## Result: CANDIDATE — dyn4j/dyn4j (lane: World deep copy with bit-identical continuation)

FALLBACKS: tokio-rs/turmoil (per-host clock offset + drift, conditional on closed PR #22).
