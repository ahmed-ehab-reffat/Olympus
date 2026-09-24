# teavm-method-summaries - feedback

STATUS: ✅ ACCEPTED 2026-09-24 at 4/10 (batch 1, 10 Nova). Finalized; see failure-patterns.md F-53..F-55, L94-L96.

Repo: konsoletyper/teavm (Java, Apache-2.0, 3115 stars). Base fd78e03fca45fc76d5454f2940a3b200b221959f (master HEAD 2026-09-15).
Lane (hunt 2026-09-23-C): whole-program method summaries (never-null return + written-field sets incl.
class-initializer effects) consumed by the per-method optimizer (nullness consumers, RepeatedFieldReadElimination).

## Status (keep current - a cut run must leave readable state)
- 2026-09-23 04:42 SLICE started, base saved.
- Gates run (see DESIGN.md Phase 2): PICK-FILTER 1/5/6/7b/8, SIX-CHECK, canonical-org PR-DIFF: all clean.
- Gate 1 repro on base (scratch JUnit, deleted afterwards):
  REPRO-1 RepeatedFieldReadElimination reuses `field Other.counter` across `initClass Config` whose
  `<clinit>` writes Other.counter -> `@b := @a` (a real base soundness bug; the feature's class-init channel fixes it).
  REPRO-2 `nullCheck` of an invoke whose callee only returns `new Object` is kept (the capability is absent).
- DESIGN.md written. Reference slice built: MethodSummaries kernel + nullness overload + RNCE/CCE/LIM wiring +
  RFRE (straight-line + frontier path, initClass) + default context method + TeaVM wiring.
- Host (gradle, JDK 21): :core:test 227/0 with the reference (213 base + 14 new).
- test.sh is Gradle-free (javac + JUnitCore XML runner, jars from /opt/testlibs). Host: base 213/0, new 14/0.
- Hook: human-effective 291 over 9 files (MethodSummaries 220).
- Patches generated 05:08. Dockerfile 05:09. Docker clean room: IN PROGRESS (see below).
- RESUMED (second builder session): patches re-checked, byte-identical to the worktree index; design
  re-read, no defect found. Docker store had been reset, olympus-base-jvm re-pulled (10 min). Hook re-run:
  human-effective 291, raw 403, 9 files. Image build started detached from the pristine clone
  (worktrees/teavm-cleanroom at BASE, no patch applied: platform order).
- RESUMED (third builder session, 07:49): patches re-verified identical to worktrees/teavm-mut
  (BASE + test.patch + solution.patch). Image build relaunched detached (setsid nohup) from the pristine
  clone, log worktrees/_teavm_build3.log; gradle stage 7m 7s; image factory-teavm-method-summaries built, total 1388 s on this HDD (chmod -R copy-up ~830 s).
- Mutants (host, javac harness, worktrees/_teavm_tools/mutate.py, 20 mutants, each asserted to land,
  restore verified against solution.patch): 17 killed, 3 survive.
  Killed in new mode: M01-M15, M18 (M01 2 tests, M04 4, M09 3, M18 2, rest 1 each). M19 (abstract
  getMethodSummaries) killed in base mode (test-source implementers stop compiling).
  Survivors, owed to FINISH coverage (all traceable to meta.md sentences):
    M16 invokedynamic treated as a known call (no fixture has an invokedynamic; meta says only
        "a method without a body ... is unknown", so FINISH either adds a sentence or a cell).
    M17 VIRTUAL target whose implementation is unknown skipped instead of making the call unknown
        ("so may every method that calls it"; add a virtual-dispatch-to-native cell).
    M20 RFRE with null summaries invalidating everything at initClass ("With null summaries every
        pass behaves as it does today"; add a null-summaries RFRE initClass cell).
  No mutant turns a base-mode test red except M19: base suite is not a discriminator for this slice.
- Docker clean room (image v1, `--network none`, fresh container per uid, script
  worktrees/_teavm_tools/cr2.sh asserts toplevel=/app, HEAD=BASE, empty status before, and that the
  hunks landed): as 0:0, 1000:1000 and unmapped 4242:4242 identical. Before solution: base 213/0,
  new = 1 synthetic compile_test_sources failure (MethodSummaries missing, log embedded). With solution:
  base 213/0, new 14/0. No `::` in any test ID.
- Flakiness: root container, base 3x 213/0 and new 3x 14/0 with the solution, identical testcase ID
  lists (md5 equal); base-without-solution 213/0 in all 3 uid containers.
- Hygiene: hook human-effective 291 (padding-floor 67 note), 9 files; only added comments are the
  repo's Apache license header; test.sh 100755; no shipd/datacurve; meta.md ASCII; no grading-phase
  words in test.sh.
- Dockerfile v1 cold build took 1388 s here (chmod -R /app copied up the COPY layer, ~830 s on this
  HDD), over the L62 600 s bar. Rewrote as ONE `RUN --mount=type=bind` layer (cp -a + gradle + chmod of
  only this layer's files, base gradle-cache files filtered by find -perm). Rebuild timing below.
- Dockerfile v2 (bind-mount single layer): cold build 456 s here (gradle 5m 15s incl. downloads), clean
  room + 3x flakiness re-run on it, identical to v1 results above.
- Found by running gradle as uid 1000 in the image: `Could not set file mode 700 on
  /opt/gradle-cache/daemon/9.7.1` (root-owned registry dir; gradle chmods it, only the owner may).
  Agents running as non-root could not build with Gradle. Fix: the build layer now ends with
  `rm -rf /opt/gradle-cache/daemon/9.7.1`; verified uid 1000 `gradlew --offline :core:compileJava
  :core:compileTestJava` BUILD SUCCESSFUL in 38 s. Dockerfile v3 cold rebuild + final clean room below.
- Dockerfile v3 (final, in this folder): cold `--no-cache` build 474 s here (gradle 5m 26s), under
  the L62 600 s bar. Final clean room on v3: identical to the results above for 0:0 / 1000:1000 /
  4242:4242; root base 3x and new 3x identical ID lists; uid 1000 offline gradle BUILD SUCCESSFUL.
- SLICE-READY 2026-09-23 ~09:00. Cleanup: image factory-teavm-method-summaries removed, host gradle
  output removed from worktrees/teavm (clones kept: teavm = worked tree with both patches staged,
  teavm-cleanroom = pristine BASE, teavm-mut = BASE + patches for mutate.py). Tooling in
  worktrees/_teavm_tools (cr2.sh clean room, mutate.py, Dockerfile.v1 for reference).
- FINISH owes: M16/M17/M20 survivor cells (above), DESIGN section 15 deferred scope (program-cache
  dependencies, @NoSideEffects), raise human-effective with depth (padding-floor note), SIX-CHECK +
  exclusivity re-run before final patch generation.

- 2026-09-23 PRECHECK "Dockerfile guidelines" FAILED: bind mount + cp is not a COPY and needs BuildKit.
  Dockerfile v4: `COPY --chown=1000:1000 . .`, then in the gradle RUN chmod only directories and root-owned
  build outputs (`find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +`). Tried and dropped: full
  `chmod -R a+rwX /app` (816 s cold, over L62) and chown-only (uid 4242 could not apply test.patch).
  v4 cold `--no-cache` 431 s. Clean room on v4 (--network none) as 0:0, 1000:1000, 4242:4242, 4242:0:
  base (no sol) 213/0, new (no sol) 1 synthetic compile_test_sources failure, base (sol) 213/0,
  new (sol) 14/0, git status empty before. Root 3x base + 3x new, identical ID lists. uid 1000 in-place
  edit + offline gradle compileJava/compileTestJava OK. Image removed afterwards.

- 2026-09-24 PRECHECK round 2: Verify Solution FAIL (new mode without the solution wrote one synthetic
  `teavm-core-new.compile_test_sources` failure, an id in neither p2p nor f2p) and Solution Quality FAIL
  (Comprehensiveness 1/3: a VIRTUAL call whose class is absent from the set got an empty target list, so
  it read never-null and write-free, and callers inherited that).
  Fixes: (1) test.sh new-mode compile failure now emits one failing testcase per @Test method, FQN
  classname, log in the first; the no-solution id set equals the with-solution set (21/21, diffed in the
  clean room). (2) MethodSummaries.virtualTargets returns null (unknown) when `classes.resolve(method)`
  finds no declaration; an abstract declaration with no concrete implementation still gives an empty set.
  (3) 7 new tests from the coverage suggestions, each traced to a meta.md sentence, each killing exactly
  its mutant: absent virtual class/method + caller (undo-fix), native override makes VIRTUAL unknown (old
  M17 survivor), SPECIAL superclass lookup, two-argument nullness unchanged, default getMethodSummaries()
  null, LoopInvariantMotion hoists a nullCheck of a never-null call (LIM unwired), null summaries keep
  today's RFRE/RNCE/CCE output incl. initClass reuse (old M20 survivor). Not added: TeaVM lifecycle
  wiring (no core-level TeaVM build harness; would need classlib + a backend), invokedynamic (M16, meta
  does not state it). meta.md unchanged.
  Clean room (cached image, Dockerfile unchanged) 0:0 / 1000:1000 / 4242:4242 / 4242:0: base 213/0 with and
  without solution, new 0/21 without, 21/21 with. Root 3x base + 3x new identical ID lists. human-effective 293.

- 2026-09-24 PRECHECK round 3: Solution Quality FAIL (Comprehensiveness 1/3): `SIMPLE` (TeaVM's DEFAULT
  level) runs the lazy pipeline, which never built summaries, so RedundantNullCheckElimination got null.
  Fix: TeaVM.build resets `methodSummaries` per build and the lazy branch builds them from the reachable
  class view it already hands to analyzeBeforeOptimizations. meta.md sentence reworded (solver-visible,
  still pre-batch): "At every optimization level, `TeaVM` builds the summaries once per build, before it
  optimizes any method, and passes them to every method it optimizes." ("after inlining" dropped: SIMPLE
  does not inline.) Body 402 words.
  New tests (21 -> 24): `everyOptimizationLevelHandsSummariesToTheMethodsItOptimizes` runs a REAL
  `TeaVM.build` per TeaVMOptimizationLevel with a stub TeaVMTarget (emit captures Main.main's optimized
  listing): a nullCheck of a two-implementation virtual call (no devirtualization/inlining possible) must be
  gone. Base keeps it at all 3 levels (probed); killed by SIMPLE-unwired AND eager-unwired mutants. Plus
  initClass Missing/Plain through a containing method, and RFRE forgetting everything on an unknown call /
  unknown initializer (both from the coverage suggestions, each kills its mutant). Gotcha: a bare
  `new ClassHolder("java.lang.Object")` defaults its parent to java.lang.Object and dependency analysis
  loops forever; setParent(null).
  Clean room 0:0 / 1000:1000 / 4242:4242 / 4242:0: base 213/0 with and without solution, new 0/24 without
  (id set identical to with-solution), 24/24 with; root 3x+3x identical ID lists. human-effective 298.

- 2026-09-24 AUTO REVIEW round 1: Description 3/3, Solution 3/3, Tests 1/3 (two High coverage gaps:
  once-per-build not observable; invokedynamic untested; Medium: array returns untested).
  meta.md (solver-visible, still pre-batch, body 413 words): (a) "an `invokedynamic` instruction counts as a
  call to an unknown method" added to the unknown-body sentence, since "calls" alone was arguable; (b) "once
  per build" DROPPED from the TeaVM sentence: counting MethodSummaries.build needs a bytecode agent in the
  harness and would fail an agent that builds through its own overload; nothing outside can observe it.
  Tests 24 -> 26: array-returning methods (SPECIAL + VIRTUAL + a nullable control), invokedynamic helper
  (writes unknown, propagates to a caller, RFRE forgets everything across it). The TeaVM end-to-end test now
  also checks a second method in another class (`Other.probe`, null-checking a virtual array-returning call);
  the stub target's inlining filter keeps Other un-inlined so its own program survives at ADVANCED/FULL.
  Mutants killed: indy ignored, arrays excluded (2 tests), summaries only for Main's class, SIMPLE unwired.
  Clean room 4 uids: base 213/0 with and without solution, new 0/26 without (ids identical), 26/26 with;
  root 3x+3x identical. human-effective 298.

## Decisions taken unattended (conservative choices)
- Test harness: Gradle-free javac harness (DOCKER.md recommendation) so grading does not depend on
  Gradle/node offline; the image still warms Gradle (`:core:testClasses :core:checkstyleMain`) for agents.
- Virtual dispatch rule stated over the linked class set (non-abstract subtypes, resolveImplementation),
  not over per-call-site points-to types (post-inlining variable indices no longer match dependency info).
- Program-cache dependencies and @NoSideEffects deferred to FINISH (DESIGN section 15).
- Sibling-library scope risk (R8 MethodOptimizationInfo, GWT TypeTightener, Soot side effects) recorded,
  MEDIUM; the platform precheck is the judge. meta.md phrased on TeaVM's own model.
- Maintainer's #1250 comment ("not interested in PRs") is general, not a decline of this capability.

## Batch 1 (accepted) - 2026-09-24
4/10 PASS (Nova #5, #8, #9, #10). Kills: neverNullHoldsThroughMutualRecursion 4 (F-53: pessimistic
fixed point; #1/#4/#7 at 25/26 sole failure, #3), withoutSummariesEveryPassBehavesAsBefore 2 (F-54:
initClass invalidation on the no-summaries path; #6 sole), fieldReadsSurvive.../aCallInOneBranch... 2
each (F-55: -2 all-instances sentinel into AliasAnalysis.affectsEverything; #2, #3),
aReturnGuardedByANullTestNeverReturnsNull 1 (#2, noise). 21/26 killed nothing, including all 11
gate-requested tests. Every run touched exactly the reference's 9 source files; base 213/0 in all 10.
Auto Review at acceptance: Approved, Description 3/3, Tests 2/3, Solution 2/3. Open Mediums: direct
InvokeDynamicInstruction not invalidating RFRE in summary mode (pre-existing, demoted from High), no
unanchored recursive-cycle test, stale XML if XmlRunner dies before writing.

