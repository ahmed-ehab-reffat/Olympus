# eval-results.md — vivisect-noret-propagation

## Batch 1 (round-5 submission, pre round-6 fixes)

8x Nova, all against the round-5 solution/test state (before the round-6 meta.md reword and the
multi-hop test). **0/8 passed.** Full findings and the fairness diagnosis are in `feedback.md`'s
round-6 entry; table below is the raw per-run breakdown.

| Run | Verdict | Files | Failed test (first genuine failure) | Failure reason |
|---|---|---|---|---|
| Nova 1 | FAIL | 4 | `test_leaf_vs_propagated_derivation_is_recorded` | direct call to a pre-declared no-return target classified `propagated` instead of `leaf` |
| Nova 2 | FAIL | 4 | `test_leaf_vs_propagated_derivation_is_recorded` (+4 more) | same derivation bug, plus a baseline regression (`analyzePointer` segfault) and unfixed cycle/leaf traps |
| Nova 3 | FAIL (wrapper-killed, 30min) | 2 | n/a — process killed | no result produced; static review only, not counted as a real data point |
| Nova 4 | FAIL | 4 | `test_leaf_vs_propagated_derivation_is_recorded` | same derivation bug, otherwise 14/15 passed |
| Nova 5 | FAIL | 5 | `test_leaf_vs_propagated_derivation_is_recorded` (+4 more) | same derivation bug, plus unfixed cycle/leaf/memory-indirect traps |
| Nova 6 | FAIL | 4 | `test_leaf_vs_propagated_derivation_is_recorded` (+1 more) | same derivation bug, plus memory-indirect target not dereferenced |
| Nova 7 | FAIL | 4 | `test_call_site_marked_noflow_still_has_an_xref_to_its_real_target` | `_cb_noflow` xref-preservation fix never applied (the only run NOT hit by the derivation bug) |
| Nova 8 | FAIL (wrapper-killed, 30min) | 3 | n/a — process killed | no result produced; static review found the same `_cb_noflow` gap as run 7 |

**Diagnosis:** 5 of 6 non-timed-out runs failed on the identical test for the identical reason —
strong evidence of a description ambiguity (see `feedback.md` round 6), not 5 independent agent
mistakes. Fixed via a meta.md reword, no code or test-intent change. Not yet re-run against a fresh
batch; the round-6 local revalidation below confirms the fix is mechanically sound (solution passes,
base fails) but does not by itself prove the new wording reads unambiguously to a fresh agent — that
needs an actual re-run.

| Batch | Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|---|
| 1 (x8) | Nova | Nova | 0/8 pass | — | 2-5 | — | see table above | see table above | see table above |
| 2 (x6) | Nova | Nova | 1/4 valid pass (2 env-blocked) | — | 4 | 500-540 | see table below | see table below | see table below |
| 3 (x2, post round-8/9 scope expansion) | Nova | Nova | 1/1 valid pass (1 env-blocked) | — | 3 | — | n/a | n/a | see below |
| 4 (x10 Nova + x1 Orion, post round-10 conditional-branch trap) | Nova/Orion | Nova | 0/11 | — | 2-3 | — | see table below | see table below | see table below |

## Batch 2 (post round-7 fixes: meta.md reword + multi-hop test + vtrace exclusion)

6x Nova. 2 of the 6 (runs 1 and 3) were killed by the platform's 30-minute wrapper wall-clock
budget before producing any real result -- **not a fairness or test-setup issue**: both were
launched within the same minute (18:01) as each other, while the other 4 runs (2, 4 at ~17:55-17:58
and 5, 6 at ~05:38-05:41) each completed the identical combined 276+16-test suite in 1.5-2 minutes.
Same `test.sh`, same suite, wildly different wall time only for the two concurrent launches --
classic platform-side resource contention during that window, not a property of the test suite or
solution. Treated as a transient blocker to re-run, not something to fix in the deliverable.

| Run | Verdict | Files | Result | Reason |
|---|---|---|---|---|
| Nova 1 | ENV-BLOCKED | 4 | wrapper killed at 30min, no real result | resource contention (see above); solution patch itself looked substantive per the evaluator's static read |
| Nova 2 | FAIL | 4 | 4/16 new tests fail | `_derive()` returns no-return when a function's call graph has no leaves at all, bypassing terminal-call target verification entirely -- marks an ordinary call, a 2-function cycle, and an unrelated cycle no-return. Exactly the cycle/leaf-graph trap this problem targets |
| Nova 3 | ENV-BLOCKED | 4 | wrapper killed at 30min, no real result | same resource contention as run 1 (concurrent launch) |
| Nova 4 | FAIL | 4 | 7/16 new tests fail | did not preserve call-site xrefs when codeflow marks a call no-fall (`setNoReturnCall` deletes/recreates the location, dropping xrefs) -- exactly the `_cb_noflow` xref-preservation trap this problem targets |
| Nova 5 | **PASS** | 4 | 16/16 new + 276/276 base | legitimate solution: verifies resolved direct/indirect/memory-indirect targets, fixed-point propagation with no self-justifying cycles, `propagateNoReturn()`, leaf/propagated metadata, xref preservation. Evaluator confirmed no cheating/hardcoding |
| Nova 6 | FAIL | 4 | 4/16 new tests fail | treats any post-call no-fall filler/terminal instruction as proof of no-return without requiring the preceding call's target itself be proven no-return -- same cycle/leaf-graph trap family as run 2, different implementation shape |

**Diagnosis:** the two real failure modes (runs 2+6 vs run 4) are each hitting a DIFFERENT one of
the two deliberately-designed traps (cycle/leaf-graph vs xref-preservation), not the same
description-ambiguity bug batch 1 hit. 1/4 valid-run pass rate (25%) is within the Olympus ≤40%
ceiling and close to the ~10% target band; the round-6/7 fixes (meta.md reword + multi-hop test +
vtrace exclusion) appear to have resolved the 0% blocker without collapsing into too-easy. Two
advisory-only Coverage Suggestions from the platform (late direct-callee status change; mixed
resolved+unresolved-indirect terminal paths) were noted but not acted on -- they don't affect the
check result and the existing trap set is already producing genuine, non-environment failures.

## Batch 3 (post round-8/9: LOC-floor scope expansion + interface-shape meta.md fixes)

2x Nova against the round-9 state. Run 1 env-blocked (same 30-min wrapper-timeout class seen in
batch 2, unrelated to the fix). Run 2 **PASS_LEGITIMATE**: evaluator confirmed no cheating, only
implementation files changed (`vivisect/__init__.py`, `vivisect/analysis/generic/noret.py`,
`vivisect/base.py`), and explicitly noted the description "precisely specifies the no-return proof
rules, propagation semantics, metadata, and public APIs" with the 28 (now) focused tests exercising
every stated behavior deterministically. This is the first real-agent confirmation that the
round-8/9 expanded scope (tail-calls, multi-target dispatch, auto-propagation, evidence, preview) is
both solvable and unambiguous, not just mechanically self-consistent. 1 valid data point is not a
batch; a full 10+ run batch is still needed for a real pass-rate read, but the signal (clear
description, legitimate pass, no environment issue on the non-blocked run) is positive.

Also acted on the 4 advisory Coverage Suggestions from the "Problem and tests are aligned" review
(preview evidence values, conditional branch exclusion, multi-leaf evidence completeness, full
idempotence state) -- see `feedback.md`'s round-10 entry for the construction details and the real
`buildFunctionGraph` quirk (register-indirect-call fallthrough aliasing onto adjacent bytes) found
and worked around while building the multi-leaf evidence test. 16 -> 28 tests; solution.patch
unchanged.

## Batch 4 (post round-10: conditional-branch trap added, 0/11)

10x Nova + 1x Orion against the 28-test round-10 state. **0/11, no environment blockers.**

| Run | Verdict | New-test tally | Dominant failure cause |
|---|---|---|---|
| Nova 1 | FAIL | 23/28 | bare `IF_NOFALL` treated as proof (ordinary call, both cycles, memory-indirect); stale evidence on direct declare |
| Nova 2 | FAIL | 17/28 | same `IF_NOFALL` false-positive family; excludes `BR_PROC` xrefs for tail jumps; derivation timing wrong |
| Nova 3 | FAIL | 21/28 | did not preserve the no-fall call site's xref (`_cb_noflow` trap) |
| Nova 4 | FAIL | 23/28 | same `IF_NOFALL` false-positive family; stale evidence on direct declare |
| Nova 5 | FAIL | 21/28 | same `IF_NOFALL` false-positive family; drops `BR_PROC` xrefs for tail-jump resolution |
| Nova 6 | FAIL | **27/28** | conditional branch to a proven no-return target accepted as evidence (round-10 trap) -- ONLY failure |
| Nova 7 | FAIL | 26/28 | conditional-branch trap + `BR_DEREF` (memory-indirect) not dereferenced |
| Nova 8 | FAIL | 23/28 | bare `IF_NOFALL` treated as proof; stale evidence on direct declare |
| Nova 9 | FAIL | 25/28 | `BR_DEREF` not dereferenced; drops `BR_PROC` xrefs for tail-jump resolution |
| Nova 10 | FAIL | ~18/28 | `IF_NOFALL` false-positive family; indirect target resolved-but-flagged-unresolved bug; xref loss |
| Orion Nova | FAIL | 20/28 | drops `BR_DEREF` xrefs entirely; no re-parse fallback for direct/tail-jump targets after codeflow suppresses fallthrough; xref loss |

**Diagnosis (full fairness-analysis-before-touching-anything run, per the mandatory discipline for
any 0/N result):** six largely-independent failure causes, not one repeated reason -- this is the
diverse-cause signal (genuinely hard, fair spec), not the same-cause-every-time signal (ambiguous
spec) the "reword, don't harden/soften" rule watches for. Every cited cause traces to an explicit
meta.md sentence; several agents invented unwarranted heuristics (e.g. treating `BR_PROC` as
call-only, excluding it from tail-jump resolution) that meta.md's "exactly as much evidence as a
call" language directly contradicts. 0/11 is not statistically alarming at a true rate near the
~10% Olympus target, and two runs are near-misses (27/28, 26/28) rather than wholesale failures.
Batch 3 (round 9, one fewer trap axis) had a confirmed real pass. No softening applied; see
`feedback.md`'s round-11 entry for the full reasoning. A fresh 10+ batch against the round-11 state
is still recommended before drawing a firmer pass-rate conclusion.

## Local pre-submit validation (not a platform run)

Clean-room: fresh clone at `BASE_COMMIT`, patches applied via `git apply` (never against the
working tree). Round-5 revalidation used a genuinely fresh venv (`/tmp/viv-final-r5-venv`)
replicating the Dockerfile's exact install steps.

- Patch apply: both orders (test-then-solution, solution-then-test) — clean, re-verified after the
  round-5 test rewrites (`git apply --check` + `git apply`, both succeed with no fuzz)
- Patch unapply: both patches `git apply -R` in reverse order, `git status --short` empty afterward
  (only the untracked `vivisect.egg-info/` from the editable install remains, not patch-related) —
  clean
- base mode, test.patch only (no solution): 303 tests, 0 errors, 0 failures, 25 skipped, exit 0 (the
  new test file is present but excluded from base's discovery — it must not fail base merely because
  the solution has not landed yet)
- new mode, test.patch only (no solution): all 15 tests fail or error for the right reason — 8
  failures + 7 errors, **0 unexpectedly passing** (confirmed by parsing the JUnit XML for testcases
  with no failure/error/skipped child), exit 1. Round 5 fixed the two tests that previously
  self-healed via codeflow's own recursive descent and passed on base without the solution
  (`NoReturnKnownLibraryApiTest` and `test_all_terminal_paths_call_different_proven_noreturn_targets`
  — both rewritten to reach their no-return target through a register-indirect call instead of a
  direct one)
- new mode, both patches: 15/15 passed, exit 0 (verified via `test.sh` CLI invocation, not just raw
  `unittest`, in a freshly `pip install --no-deps -e .`'d clean-room clone)
- base mode, both patches: 303 tests, 0 errors, 0 failures, 25 skipped, exit 0 (no regressions across
  the full non-GUI suite, including every integration point this fix touches: the emulator's main
  loop, its ARM override, the emucode watcher, and codeflow's `_cb_noflow`)
- `pytest --collect-only -q` (bare invocation, not `run_tests_6180ce.py`): 188 tests collected, 0
  collection errors, confirming the round-5 `pyproject.toml` `addopts` fix for the PyQt6 Environment
  Quality FAIL
- Flakiness: 3x new + 3x base on the final round-5 state, identical pass/fail counts and identical
  exit codes every run (base mode: 303/303, 0/0, 25 skipped, all three runs; new mode: 15/15, all
  three runs)
- Mutation check on `NoFlowXrefPreservationTest`: reverting just the `_cb_noflow` xref-restore fix
  makes it fail (0 xrefs found instead of 1)
- Mutation check on `PropagateNoReturnIsolationTest`: confirmed directly against the live
  implementation that the sentinel is invoked 0 times by the correct `propagateNoReturn`, before
  writing the test — a solution that shortcuts to `analyze()` would invoke it and fail this test
- Robustness check on `run_tests_6180ce.py`'s round-5 dependency-free JUnit writer: verified all
  three code paths independently — normal run (real per-test JUnit XML), base mode (real XML, 303
  testcases), suite-collection exception via a monkey-patched loader (synthetic failing-testcase XML
  with the real traceback embedded, exit 1) — no external XML dependency in any path now

**Round 6 (post batch-1 analysis)** — re-ran the full clean-room cycle after the meta.md derivation
reword and the new multi-hop test:

- Patch apply: fresh clone at `BASE_COMMIT`, test.patch then solution.patch, both `git apply --check`
  clean, both `git apply` clean, no fuzz
- new mode, test.patch only (no solution): 16 tests, 9 failures + 7 errors, **0 unexpectedly
  passing** (parsed the JUnit XML directly), exit 1 — includes the new
  `test_multi_hop_indirect_chain_returns_every_newly_marked_caller_in_one_call`, confirmed failing at
  its first assertion (`AssertionError: True is not false`) for the expected reason: the base bug
  marks the unresolved-indirect-call function no-return unconditionally
- new mode, both patches: 16/16 passed, exit 0 (via `test.sh` CLI in a freshly
  `pip install --no-deps -e .`'d clean-room clone)
- base mode, both patches, and test.patch-only: 303/303 pass, 0 errors/failures, 25 skipped, exit 0
  in both clones — no regression from the meta.md/test-only changes
- Patch unapply: both patches `git apply -R` in reverse order, `git status --short` empty (only the
  untracked `vivisect.egg-info/` from the editable install remains)
- Flakiness: 3x new mode on the final round-6 state, identical 16/0/0/exit-0 every run
- Counter-1 effective LOC unchanged at 187 — round 6 touched only `meta.md` and the test file, no
  solution files
- meta.md re-checked: 356 words (body only), ASCII-clean, no em-dashes, well under the 500 hard cap

**Round 7 (platform Verify Flakiness FAIL)** — `vtrace.tests.testbasic.VtraceBasicExecTest`'s
`test_vtrace_getregisters` and `test_vtrace_setregisters` flagged non-deterministic across 6 runs
per state, in both the with-patch and with-solution states (pre-existing, unrelated to this fix --
`vtrace` is untouched by `solution.patch`). Excluded both exact test IDs from base mode discovery in
`run_tests_6180ce.py`. Re-validated:

- base suite count: 303 -> 301 (exactly the two excluded; confirmed via direct suite introspection,
  not just the XML count)
- fresh clean-room clone, both patches apply/unapply cleanly, `git status --short` empty after
  unapply (only the untracked `vivisect.egg-info/` remains)
- new mode, test.patch only: 16 tests, 0 unexpectedly passing, exit 1
- new mode, both patches: 16/16 pass, exit 0 (via `test.sh` CLI)
- base mode, both patches and test.patch-only: 301/301 pass, 0 errors/failures, 25 skipped, exit 0
- 3x flakiness recheck on both `new` and `base` modes: identical counts and exit codes every run
  (new: 16/0/0 x3; base: 301/0/0/25-skipped x3)
- Counter-1 effective LOC unchanged at 187 (round 7 touched only `run_tests_6180ce.py`, no solution
  files)

**Round 8 (LOC floor gap)** — running `.claude/hooks/effective_loc_check.py` (Counter-2,
human-calibrated) for the first time found `human-effective` = 124, well under the 275 target and
the ~200 hard floor, despite Counter-1 reading 187. Added 6 orthogonal pieces of real scope (see
`feedback.md`'s round-8 entry for the full list): tail-call fix, jump-table/multi-target dispatch
generalization, `addNoReturnVa` auto-propagation, evidence recording (`getNoReturnEvidence`),
`previewNoReturnImpact`/`simulatePropagation` dry-run, and cross-package CLI/report/vivbin
integration (untested by design, matching the CLAUDE.md-endorsed lever). 10 new tests (16 -> 26), 5
new meta.md paragraphs (488 words, under the 500 cap). Re-validated in a fresh clean-room clone:

- new mode, test.patch only: 26 tests, 0 unexpectedly passing, exit 1
- new mode, both patches: 26/26 pass, exit 0 (via `test.sh` CLI)
- base mode, both patches and test.patch-only: 301/301 pass, 0 errors/failures, 25 skipped, exit 0
- patches apply/unapply cleanly in both directions, `git status --short` empty after unapply
- 3x flakiness recheck on both `new` and `base` modes: identical counts every run (new: 26/0/0 x3;
  base: 301/0/0/25-skipped x3)
- every new byte-level test construction verified against the live implementation before being
  written (register-indirect jump/dispatch + manual `addXref`, matching this file's own existing
  convention, since a direct jmp/call to an existing mapped address gets pulled into the caller's
  own function graph by `buildFunctionGraph` regardless of function boundaries — confirmed
  empirically)

**This round changed tested behavior, not just test/meta wording — the batch-1 (0/8) and batch-2
(1/4 valid, 2 env-blocked) agent runs no longer represent the current problem scope and must be
treated as stale. A fresh agent batch is required before this is submit-ready.**

## LOC

Counter 1 (raw − blank − comment-only, the platform auto-block measure): 187 through round 7,
across 8 source files. Counter 2 (`human-effective`, the binding human-calibrated measure, run via
`.claude/hooks/effective_loc_check.py`): **281** as of round 8, across 12 source files — up from 124
at the start of round 8 (Counter-1's 187 had been masking a genuine floor violation the whole time,
since Counter-2 strips docstring blocks entirely and this problem's source carried a lot of them).
Clears the 275 design target with margin. Six orthogonal additions reached it (tail-call fix,
multi-target dispatch, auto-propagation, evidence recording, preview/simulate, and CLI/report/vivbin
cross-package integration) — see `feedback.md`'s round-8 entry for the verification log on each.

## Batch 5 (agent-runs/9, round 35: post round-32/33/34 MSP430/xref/timing fixes)

6x Nova + 1x Orion against the 56-test round-34 state. **0/7 pass**, no unfair-test or environment
blockers found by the evaluator on any run.

| Run | Verdict | New-test tally (fail/56) | Dominant failure cause |
|---|---|---|---|
| Nova_Nova_1 | FAIL | 4 | MSP430 bare-return false positive; conditional-branch truncated-fallthrough false positive; tail-jump leaf + reanalysis pair |
| Nova_Nova_2 | FAIL | 8 | leaf/propagated mislabeling; MSP430; tail-jump reanalysis; local-jump-absorbed false positive; regex-on-import miss |
| Nova_Nova_3 | FAIL | 11 | widest spread -- leaf/propagated, MSP430, xref preservation, multi-hop chain, both plain-function known-API tests, tail-jump reanalysis |
| Nova_Nova_4 | FAIL | 2 | near-miss -- only MSP430 + one ordinary-call-before-terminal-call control-flow gap |
| Nova_Nova_5 | FAIL | 8 | MSP430; xref preservation; both preview tests; tail-jump leaf + reanalysis pair; ordinary-call-before-terminal gap |
| Nova_Nova_6 | FAIL | 3 | near-miss -- MSP430 + tail-jump leaf + reanalysis pair only |
| Orion_Nova | FAIL | 16 | widest spread of the batch -- hits nearly every trap category at least once |

**MSP430 bare-return trap: 7/7 (100%).** No agent in this batch caught it, regardless of how well
everything else was implemented -- it is now the single dominant wall. Full diagnosis and the
discoverability-vs-fairness read in `feedback.md` round 35. Second-place wall:
`test_tail_jump_target_resolved_after_caller_examined_propagates_on_reanalysis` at 6/7 (86%),
consistent with round 27's read of the same test as a real, fair, hard-to-fully-implement symmetry.

Running total: 33 real-platform runs across all batches, 0 full passes. Two most recent batches
(round 27's agent-runs/8, and this one) both show a near-miss floor (4/51 and 2/56 respectively)
rather than every agent failing double digits, which favors "hard but solvable, needs more
attempts" over "genuinely unsolvable" -- but the streak length itself is now a real risk against
the Olympus 0%-reject floor. See `feedback.md` round 35 for the full per-test frequency breakdown
and the recommendation to the user.

## Batch 6 (agent-runs/10, round 57: post rounds 36-56, suite grown 56 -> 101, 0/5)

Five Nova runs, no Orion this time. Baseline 134/134 in all five (see the base-collection note
below), deterministic, zero environment or verifier failures. Every evaluator independently
recorded `description_clear: true`, `tests_deterministic: true`, difficulty "challenging", and
`was_mentioned_in_description: true` on every failure.

| Agent | Verdict | Failed (of 101) | On the old 56 | On the 45 added since batch 5 | Notes |
| --- | --- | --- | --- | --- | --- |
| Nova_Nova_1 | FAIL | 27 | 8 | 19 | widest spread; mnemonic allowlist in noret.py instead of decoder flags |
| Nova_Nova_2 | FAIL | 20 | **1** | 19 | near-miss on the pre-round-36 surface: only the noflow xref test |
| Nova_Nova_3 | FAIL | 23 | 9 | 14 | post-sync proven set -> leaf/propagated mislabeling |
| Nova_Nova_4 | FAIL | 23 | 10 | 13 | compacted; thunk-by-name treated as a direct API match |
| Nova_Nova_5 | FAIL | 21 | 9 | 12 | 49.5M tokens, compacted; decoders left untouched entirely |

**The decisive split is the last two columns.** 29 of the 41 distinct failing tests are among the 45
added during rounds 36-56. Nova_2 failed exactly one test of the batch-5 (56-test) suite and 19 of
the new ones -- against the artifact as it stood at batch 5 that run was a single assertion from a
pass. The hardening rounds, each individually defensible, cumulatively took the problem from
"solvable on a good run" to 0%.

**No agent edited any `envi/archs/*/disasm.py`.** All five read those files (every trajectory
references them) and all five still chose a mnemonic allowlist in the generic layer. Only one of the
20 architecture tests asserted a decoder flag directly, so the tests never forced the decoder-flag
architecture -- the arch failures are per-arch misses in hand-rolled mnemonic lists, not a
discoverability wall.

**Base-collection discrepancy (benign).** The platform collects **134** base tests; local and local
Docker both collect **159**. The 25 extra are sample-binary-dependent modules (testelf, testpe,
testgolang, testvivisect, ...) that only collect when a downloaded test-file cache is present in the
environment. Deterministic and zero-failure both ways, so not a blocker -- but it means the "Docker
base 159/0/0" line in earlier rounds overstated what the platform actually exercises.

### Orion is the WORST agent on this problem, not the strongest

Correcting a claim made earlier in round 57: it is not true that every run has been Nova. **Six Orion
runs have been spent across batches 2, 3, 4 and 5, and Orion lost to Nova in every batch where both
ran:**

| Batch | Suite | Nova failure counts | Orion failure counts |
| --- | --- | --- | --- |
| 2 | 28 | 1, 2, 3, 5, 5, 5, 7, 7, 11, 18 | 8 |
| 3 | 49 | 5, 7, 8, 9, 10, 13, 15 | **19** (worse than every Nova) |
| 4 | 51 | 4, 5, 8, 9, 14 | 12, 12, **17** |
| 5 | 56 | 2, 3, 4, 8, 8, 11 | **16** (worse than every Nova) |

Orion is 0/6 and its best run is worse than Nova's median in three of the four batches. This matches
its documented profile -- decisive commit-and-implement, does not pivot when it picks the wrong
architecture -- against a problem that requires re-deriving across eight interacting clusters. **At
24 tokens/run versus Nova's 4, Orion is the wrong place to spend on this artifact.**

Running total: **72 real-platform runs, 2 full passes**, both in batches 1-2 when the suite was 16
and 26 tests. **0 for the last 50 consecutive runs.**

---

## Batch 11 (2026-09-06) -- 6 runs, **0 passes**. Round-79 artifact, 135 tests.

Confirmed to be the CURRENT suite: all five round-78/79 additions are present in the runs' JUnit
(`test_propagation_after_deleting_a_derived_function_still_runs`,
`test_a_local_cycle_beside_a_trap_is_not_proven_by_that_trap`,
`test_a_published_name_match_survives_a_rename_and_a_later_lost_proof`,
`test_preview_predicts_a_caller_through_an_ordinary_previewed_memory_slot`,
`test_a_declaration_drawn_over_a_derived_proof_survives_that_proof_being_undercut`).

| Run | Verdict | Failed / 135 | Failing classes | Baseline | Notes |
| --- | --- | --- | --- | --- | --- |
| Nova #1 | FAIL_MISSED_REQUIREMENT | 47 | 21 | pass | thunk name used as evidence |
| Nova #2 | FAIL_MISSED_REQUIREMENT | 60 | 25 | pass | `_is_trap_or_halt` on mnemonic spelling, no decoder flags |
| Nova #3 | FAIL_MISSED_REQUIREMENT | 44 | 20 | pass | hard-coded mnemonic list; stale codeblocks |
| Nova #4 | FAIL_MISSED_REQUIREMENT | 42 | 20 | pass | best run of the batch |
| Nova #5 | FAIL_MISSED_REQUIREMENT | 43 | 18 | **FAIL** | 2 baseline storage-count regressions |
| Orion #1 | FAIL_MISSED_REQUIREMENT | 44 | 22 | **FAIL** | 2 baseline storage-count regressions |

Every evaluator: `description_clear: True`, `tests_deterministic: True`, `blocker_detected: False`,
`agent_blame_unfair: False`, `difficulty: challenging`, `was_mentioned_in_description: True`. So this
is not a fairness or artifact-quality failure. Auto Review scored the same artifact **3/3 / 3/3 /
3/3, Approved**. It is purely a solvability failure.

### There is no over-strict axis to drop

- 77 distinct tests failed by at least one run. **16 failed by all six**, and they are spread over
  NINE different classes -- conditional-call evidence exclusion, late-proven fallthrough
  re-derivation, newly-marked accounting, derivation labels, evidence recording, multi-hop indirect,
  event replay, retraction (5 tests), tail calls (2), and the never-decoded fallthrough.
- Every run fails in **18-25 of the ~43 test classes**. The best run fails 42 tests across 20
  classes.
- `StaleDerivationRetractionTest` is the single biggest sink (6-13 per run), but deleting the whole
  retraction axis still leaves the BEST run failing ~33 tests across 17 other classes.
- Only **13 classes / 18 tests** were solved by all six: the basic terminal-proof mechanic
  (`LocalBranchCycle`, `PartiallyProvenTransferBesideATrap`, memory slots, thunk deferral,
  `PropagateNoReturnIsolation`) plus both round-79 additions.

**The failure is diffuse, which means the problem is over-SCOPED, not over-strict.** No test
relaxation reaches a pass, and a tests-only relaxation is the only lever that keeps Re-eval
eligibility. Deleting the ~42 tests it would take to flip the best run would strip a third of the
suite while meta.md still described all of it -- the described-but-untested gap that Tests scored
1/3 for two rounds running.

### Running total

**78 real-platform runs, 2 passes, both in batches 1-2 when the suite was 16 and 26 tests. 0 for the
last 56 consecutive runs.**

The batch-5 note in this file already recorded the mechanism: "The hardening rounds, each
individually defensible, cumulatively took the problem from 'solvable on a good run' to 0%." Batch 11
confirms it at 135 tests, and rounds 73-79 added five more tests on top of that while fixing real
review findings. Every individual round was correct. The cumulative artifact is unsolvable.

### One agent-side pattern worth carrying forward

Two of six runs (Nova #5, Orion #1) regressed the BASELINE by initialising `NoReturnApisVa` and
`NoReturnApisRegex` in the workspace constructor, which changes vivisect's own storage event counts
(42 vs 40, 43 vs 41). The reference avoids it by never writing those keys until something is actually
published -- `getMeta(key, {})` defaults everywhere instead. A solver that reaches for constructor
initialisation trips an existing test that has nothing to do with no-return. Fair (existing tests
must keep passing) but a real and repeatable trap.

## Batch 12 -- 5x Nova, 0/5. Artifact as of round 88 (82 tests).

| Run | Baseline | New tests | Verdict | Failed |
|---|---|---|---|---|
| Nova #1 | pass | fail | FAIL_MISSED_REQUIREMENT | 22 / 82 |
| Nova #2 | pass | fail | FAIL_MISSED_REQUIREMENT | 22 / 82 |
| Nova #3 | pass | fail | FAIL_MISSED_REQUIREMENT | 38 / 82 |
| Nova #4 | pass | fail | FAIL_MISSED_REQUIREMENT | 32 / 82 |
| Nova #5 | pass | fail | FAIL_MISSED_REQUIREMENT | 31 / 82 |

Every baseline passed. No run came close: the best was 60 of 82.

### Approach: all five converged on the same architecture, and it is not the reference's

Every agent touched 4-5 files and **not one opened a decoder**. The footprint was identical across
runs: `vivisect/analysis/generic/noret.py`, `vivisect/__init__.py`, `vivisect/base.py`, sometimes
`envi/codeflow.py`, plus their own test file. Zero occurrences of `IF_TRAP` in any of the five
patches.

Instead all five wrote a **mnemonic list inside the analysis**: `_TRAP_MNEMS = {'hlt', 'ud2',
'int3', 'trap', 'int1', ...}`, `_HALT_MNEMS`, `_CONDITIONAL_TRAP_MNEMS`. Three of them wrote a
comment to themselves saying not to use IF_NOFALL for it. So they read the trap clause correctly,
understood exactly what it forbade, and solved it the only way the codebase suggests when you do not
think to add a decoder fact. Those lists are all x86 spellings.

### The 15 tests that failed in all five runs, by bucket

- **Name-based declaration (4):** registered-after-the-function-exists, registered-after-the-import-
  exists, renamed-onto-a-declared-name, thunk-named-for-a-declared-api. Added rounds 82/86/87 in
  response to Solution Quality findings.
- **Multi-destination / every-destination proof (3):** call to two proven destinations, dispatch to
  two proven cases, all-terminal-paths-call-different-targets. Added round 84.
- **Architecture (3):** arm permanently-undefined, predicated pc load, predicated stack pc load.
  Rounds 82/85.
- **Local dispatch ownership (2):** all-local-trap cases, local case beside a proven outgoing one.
  Added round 89 -- and batch 12 predates it, so these two were already failing before that work.
- **Lifecycle (2):** addNoReturnVa propagating immediately, and returning every newly marked caller.
- **Wall 2 (1):** call-then-ret becomes no-return once the target is declared afterward.

The core walk is NOT the wall. Most trap, path, cycle, memory-eligibility and idempotence tests
passed in every run: `test_bare_trap_instruction_is_independently_derived_noreturn` failed in only
one run of five, so four of five agents did build the intrinsic sweep -- wall 1's hint is working.
`LocalBranchCycleTest`'s cycle tests passed 5/5. What agents cannot complete is the accumulated
lifecycle and declaration surface around the walk.

### Running total

**83 real-platform runs, 2 passes, both in batches 1-2 when the suite was 16 and 26 tests. 0 for the
last 61 consecutive runs**, across two scope-down attempts (round 80's 135->38 cut, then rounds
81-90 rebuilding to 83).

## Batch 13 -- 6x Nova + 1x Orion, 0/7. Artifact as of round 92 (46 tests).

| Run | Baseline | New tests | Verdict | Failed |
|---|---|---|---|---|
| Nova #1 | pass | fail | FAIL_MISSED_REQUIREMENT | 10 / 46 |
| Nova #2 | pass | fail | FAIL_MISSED_REQUIREMENT | 7 / 46 |
| Nova #3 | pass | fail | FAIL_MISSED_REQUIREMENT | **3 / 46** |
| Nova #4 | pass | fail | FAIL_MISSED_REQUIREMENT | 10 / 46 |
| Nova #5 | pass | fail | FAIL_MISSED_REQUIREMENT | 7 / 46 |
| Nova #6 | pass | fail | FAIL_MISSED_REQUIREMENT | 13 / 46 |
| Orion #1 | pass | fail | FAIL_MISSED_REQUIREMENT | 7 / 46 |

**The cut worked.** Best run went from 22 failures of 82 (batch 12) to **3 of 46**. 28 of the 46 tests
passed in every single run. Only one test failed in all seven.

### And it exposed what has actually been wrong for thirteen batches

Three runs (Nova #2, Nova #5, Orion #1) failed the **identical seven tests**. That is the textbook
unfairness signal, and the cause is one unstated requirement:

**Six of those seven fixtures resolve their call target only through a recorded xref.** They are all
built as `mov rax, target ; call rax` (or `jmp rax`) plus an explicit
`vw.addXref(callVa, target, REF_CODE, BR_PROC)` -- deliberately, so codeflow cannot descend into the
target while decoding the caller. The test comments say so outright: "reached only through a
register-indirect call, resolved later via addXref".

meta.md never said a site xref counts as resolution. It said only "every destination it resolves to"
and "An unresolved call or jump settles nothing". Every agent read "resolves" as what the INSTRUCTION
gives, which for `call rax` is nothing, and concluded the call settles nothing. Their propagation
loops are otherwise correct -- all three build a real fixed point over `vw.getFunctions()`, and two of
them call `getXrefsFrom` elsewhere in the patch. They simply were never told that the xref is where
the target lives.

**The seventh, failed by 7 of 7, is worse: meta.md contradicted it.** The test proves a caller through
an import slot that is itself the declared address. meta.md said a memory-indirect call "resolves
through its slot to the target actually stored there" -- and an import slot has nothing meaningful
stored in it. An agent following that sentence dereferences and gets garbage.

Both are now stated:

- "A destination the instruction alone does not name is still resolved when the workspace has recorded
  a code reference from that site to it."
- "...to the target actually stored there, unless the slot itself is a declared no-return address,
  which is then the destination."

### What this reframes

The two passes ever recorded were in batches 1-2, when the suite was 16 and 26 tests. Every batch
since has been read as a difficulty problem and answered by cutting scope. Batch 13's shared failure
pattern says a large part of it was a **fairness** problem the whole time: an enforced requirement
that no sentence stated, sitting under six of the seven tests the strongest runs still failed. Round
92's cut is what made it visible -- with 82 tests the signal was buried in 22 unrelated failures.

### Running total

**90 real-platform runs, 2 passes, 0 for the last 68.** Batch 13 is the first one whose failures
point at a specific, fixable cause rather than at accumulated volume.

## Batch 14 -- 10x Nova, 1/10 PASS. Artifact as of round 98 (52 tests).

**The solvability gate is cleared for the first time since batch 2.** Nova #6 passed all 52; the other
nine failed 1, 1, 1, 2, 2, 2, 3, 4 and 7 tests. 45 of 52 passed in every run and no test failed in all
ten. Rounds 95-98 did what the batch-13 analysis predicted.

| Run | Failed | Run | Failed |
|---|---|---|---|
| Nova #4 | 1 | Nova #2 | 4 |
| Nova #7 | 1 | Nova #9 | 7 |
| Nova #8 | 1 | Nova #6 | **0 (PASS)** |
| Nova #3, #5, #10 | 2 | | |

### What holds the band

Two tests carry it, both added in rounds 97-98:

- `test_a_predicated_register_branch_resolves_through_a_recorded_reference` -- 7 of 10
- `test_a_computed_transfer_does_not_resolve_to_its_own_operand` -- 6 of 10

**Without those two the batch is 5/10 = 50%**, at the ceiling and out of band. They are the difference
between a Good-band submission and a too-easy one, so they stay. Note the second was predicted to be
"free in solvability terms" because it passes trivially on base flags; six of ten runs failed it
anyway, which is worth remembering the next time a negative test is called free.

Everything else is a long tail: the trap-classification tests (`bare_trap` 2, `int1` 3,
`trap_behind_a_call` 3) and the two current-instruction tests (1 each).

### The false-positive flag, and why it is right

Nova #6's pass was adjudicated a false positive: it classifies traps by a hardcoded mnemonic list
('trap','int1','int3','ud2','udf','undefined','illegal','invalid','bkpt','brk','halt','hlt') that
contains `ud2` but not its siblings `ud0` (0F FF) and `ud1` (0F B9). The repo's own opcode table puts
all three in INS_INVALIDOP; the reference gives that whole class IF_TRAP, so it proves a ud0-only or
ud1-only function no-return and the candidate does not.

I checked this rather than taking it: my first probe said even the reference could not decode ud0, and
I nearly contested on that basis. The probe was wrong -- I fed it two bytes and both encodings need a
ModRM byte. With `0f ff c0` and `0f b9 c0` both decode fine, both carry IF_NOFALL|IF_TRAP in the
reference, and both prove their function no-return. The panel is correct and the discriminator was
genuinely missing.

### Running total

**100 real-platform runs, 3 passes.** The last one is batch 14's, at 10%, in band -- and it is exactly
the pass this round's FP fix is designed to invalidate.

## Batch 15 -- 0/10, no artifacts

Reported 0/10. No per-run solution patches were saved, so there is no residual table for it and no
way to read WHY the ten failed. Batch 14's ten saved solutions remain the only population the local
replay can grade, and round 102's cut was decided against those.

Method note for future rounds: the replay is only an oracle while the run view is open. A batch whose
patches were not pulled contributes a rate and nothing else.

### Replay of batch 14 against the round-102 (52-test) suite

| run | failures | remaining tests |
|---|---|---|
| Nova #4 | 0 | **PASS** |
| Nova #3 | 1 | computed_transfer |
| Nova #5 | 1 | computed_transfer |
| Nova #10 | 1 | computed_transfer |
| Nova #6 | 1 | other_undefined_encodings |
| Nova #1 | 2 | computed_transfer, trap_behind_a_call |
| Nova #7 | 2 | other_undefined_encodings, int1_debug_trap |
| Nova #8 | 2 | trap_behind_a_call, other_undefined_encodings |
| Nova #2 | 3 | computed_transfer, bare_trap, int1_debug_trap |
| Nova #9 | 6 | computed_transfer, trap_behind_a_call, instruction_past_entry, judged_on_bytes_now, bare_trap, int1_debug_trap |

`computed_transfer` is in six of the ten and is the sole failure in three. It has replaced the
predicated-branch test as the rate-setting discriminator.

### Running total

**110 real-platform runs, 3 passes** (batch 14's pass is the one the round-100 FP fix invalidates).

## Batch 15 re-eval -- 1/10, and the artifacts DID land

Correction to the note above: the run view carried the re-eval's ten solutions after all, and they
are now saved under `agent-runs/15/` (`Nova_Nova_1..10`, each with `solution-patch.patch`,
`junit-new.xml`, `eval-result.json`, `trajectory.json`). Run ids are `re-eval 1` of the batch-14
population, so batch 14 and batch 15 are the same ten solutions graded twice -- which is why the
round-102 cut moved the reported rate from 0/10 to 1/10 on the same sample.

Replaying those saved patches through the shipped `test.sh` reproduces the platform exactly:
**1/10, Nova #4 passing, and the same residual table round 102 projected.** The replay harness is
therefore validated end to end, not just believed.

### Round 103 replay against the 53-test suite

| run | failures | remaining tests |
|---|---|---|
| Nova #4 | 0 | **PASS** |
| Nova #3 | 1 | computed_transfer |
| Nova #5 | 1 | computed_transfer |
| Nova #10 | 1 | computed_transfer |
| Nova #6 | 1 | other_undefined_encodings |
| Nova #7 | 2 | int1_debug_trap, other_undefined_encodings |
| Nova #8 | 2 | trap_behind_a_call, other_undefined_encodings |
| Nova #1 | 3 | computed_transfer, **mixed_dispatch_fixed_point**, trap_behind_a_call |
| Nova #2 | 3 | computed_transfer, int1_debug_trap, bare_trap |
| Nova #9 | 6 | computed_transfer, instruction_past_entry, judged_on_bytes_now, int1_debug_trap, trap_behind_a_call, bare_trap |

The one test added this round costs Nova #1 only, which already had two failures. The rate is
unchanged.

### Cost of every regression the review asked for, measured on the same ten

| demanded regression | runs it fails | verdict |
|---|---|---|
| mixed dispatch, one call reaches the fixed point (S1 defect 1) | 1 | **ADDED** |
| conditional call, target declared AFTER disassembly | 3 (incl. #4) | lethal |
| conditional call, target declared BEFORE disassembly | 10 | lethal |
| ARM computed PC write resolved by a recorded xref | 10 | lethal |
| Thumb computed PC write resolved by a recorded xref | 10 | lethal |
| register jump whose destination is recorded with BR_PROC | 10 | lethal |
| trap behind an unresolved call (`call rax; ud2`) | 10 | lethal |
| trap behind a conditional trap (`into; ud2`) | 10 | lethal |
| changed instruction boundaries re-decoded from the entry | 10 | lethal |
| `cmovz ...; ud2` predicated data op (S1 defect 2) | 10 | lethal |
| ARM `movne ...; bkpt` predicated data op (S1 defect 2) | 10 | lethal |

Nine of the eleven fail in all ten runs. Every one of them fails Nova #4, so any single addition
other than the first turns 1/10 into 0/10 on the graded population.

### Running total

**110 real-platform runs, 3 passes** (batch 15 is a re-grade of batch 14, not 10 new runs).

## Batch 16 -- the re-eval of the round-103 artifact, 1/10

Batch 16's ten `solution-patch.patch` files are **byte-identical** to batch 15's, run for run: it is
the second re-eval, not a new population. It reports **1/10** with Nova #4 passing and the exact
residual table round 103 predicted, so the re-eval did what it was paid for and the local harness is
confirmed against the platform a second time.

**Total distinct solutions ever graded on this problem: 110 runs, 3 passes.** Batches 14, 15 and 16
are one population of ten.

## ⚠️ CORRECTION -- the round-103 cost table was measured wrong

Round 103's "9 of 11 demanded regressions fail 10/10" is **WRONG**. The candidate tests were written
in a scratch module where each test's `propagateNoReturn()` call sat inside a `print(...)`, and the
measurement script stripped print lines to quiet the output. That deleted the propagation call from
eight of the eleven tests, so they failed for the trivial reason that nothing ever propagated.

Re-measured with real test methods against the same ten solutions:

| candidate regression | runs failing (of 10) | round-103 claim |
|---|---|---|
| predicated trap keeps its fallthrough (S2 defect) | **0** | not measured |
| x86 `cmovz ...; ud2` predicated data op | **0** | 10 (bogus) |
| register jump resolved by a BR_PROC reference | **1** | 10 (bogus) |
| mixed dispatch, one call reaches the fixed point | 1 | 1 (correct) |
| conditional call, target declared AFTER disassembly | 3 | 3 (correct) |
| trap behind an unresolved call (`call rax; ud2`) | **4** | 10 (bogus) |
| ARM `mvn pc, #imm` complemented immediate (S1 defect) | **6** | not measured |
| ARM `movne ...; bkpt` predicated data op | **6** | 10 (bogus) |
| conditional call, target declared BEFORE disassembly | 10 | 10 (correct) |
| ARM computed transfer resolved by a recorded xref | 10 | 10 (correct) |
| Thumb computed transfer resolved by a recorded xref | 10 | 10 (bogus, but same answer) |
| trap behind a conditional trap (`into; ud2`) | 10 | 10 (correct, and round 101 measured it independently) |
| changed instruction boundaries / newly reachable code | 10 | 10 (correct) |

Five of the thirteen cost two runs or fewer. **Four of the round-103 declines were affordable and
should have shipped.** The method lesson is narrow and mechanical: measure with the test file the
platform will run, never with a scratch copy, and never post-process the source of a test you are
about to trust.

## Round 104 replay -- the 60-test suite against the same ten

| run | failures | the ones that matter |
|---|---|---|
| Nova #6 | 3 | recorded_reference, newly_reachable, other_undefined_encodings |
| Nova #3 | 4 | recorded_reference, newly_reachable, computed operand x2 |
| Nova #4 | 4 | recorded_reference, newly_reachable, **br_proc_jump**, **unresolved_call** |
| Nova #5 | 4 | same as #3 |
| Nova #7 | 4 | recorded_reference, newly_reachable, int1, other_undefined_encodings |
| Nova #10 | 4 | same as #3 |
| Nova #8 | 5 | + trap_behind_a_call, unresolved_call |
| Nova #2 | 6 | + int1, bare_trap |
| Nova #1 | 7 | + mixed_dispatch, trap_behind_a_call, unresolved_call |
| Nova #9 | 10 | the widest miss, as in every batch |

**0/10 on this population.** Two tests are in all ten residuals and are the whole reason:
`a_computed_transfer_settles_its_path_through_a_recorded_reference` and
`code_reachable_only_after_a_terminal_is_replaced_is_decoded`.

Both of those now have a meta.md sentence that did not exist when these ten solutions were written
(the computed-write clause and the newly-reachable clause). Per L35 the replay measures a TEST delta
and cannot measure a DESCRIPTION delta, so this 0/10 **overstates** the difficulty a fresh batch
faces. The measurement that matters now is a Vega batch, not this number.

## Round 105 -- Solution Quality FAIL: `str pc, [...]` read as a proven transfer

One High finding, and it is a genuine soundness bug in the reference, reproduced exactly as the
reviewer described it before touching anything:

```
str pc, [pc, #0] ; bx lr          (arm, slot at 0x2008 declared via addNoReturnVa)
pre-fix : iflags=0x30009 (NOFALL|BRANCH), branches=[(0x2008, BR_DEREF), (None, 0)]
          addNoReturnVa(0x2008) -> {0x2000}     fVa marked no-return   WRONG
post-fix: iflags=0x30000 (no transfer flags),  branches=[(0x2004, BR_FALL)]
          addNoReturnVa(0x2008) -> set()        fVa return-capable     right
```

Two independent causes, both fixed, and the new test is pinned by BOTH (revert either half alone and
it is the only failure):

1. **base decoder**, `p_load_imm_off` and `p_load_reg_off`: `if Rd == REG_PC: iflags |= IF_BRANCH`
   with no check of the L bit, so the store form of every `ldr/str` into pc claimed to branch. Now
   gated on `pubwl & 1`.
2. **my generic pc-write predicate**: it read the first operand as the destination, but a store's
   first operand is the SOURCE. Fixed in the mechanism the repo already has for this -- `no_update_Rd`
   now also lists the store opcodes, which is exactly what that tuple means. One edit fixes the ARM
   and Thumb predicates together, since both consult it.

Verified across the space afterwards: every store form of pc (`str/strb` imm, reg and scaled offset,
`stm`, `push {pc}`) carries no transfer flag and only a BR_FALL edge, while every genuine write into
pc keeps its flags (`ldr pc` NOFALL|BRANCH, `ldm r0,{pc}` NOFALL|BRANCH, `mov pc,r1` NOFALL|BRANCH,
`mov pc,lr` NOFALL|RET, `add/mvn pc` NOFALL|BRANCH).

### Cost of the new regression on the saved ten

**10 of 10.** All ten consume the base decoder's mis-flag and none of them opened a decoder, so this
lands on the same population that was already 0/10 after round 104 -- marginal cost zero on this
sample, and the requirement is now stated in meta.md rather than inferred.

| run | failures /61 |
|---|---|
| Nova #6 | 4 |
| Nova #3, #4, #5, #7, #10 | 5 |
| Nova #8 | 6 |
| Nova #2 | 7 |
| Nova #1 | 8 |
| Nova #9 | 11 |

## Round 106 -- Solution Quality FAIL again (Comprehensiveness 1/3, Code Quality 3/3), Test Quality PASS

**Test Quality is now PASS: all 61 test methods fair, 20 of 20 prompt requirements pinned.** That is
the first clean Tests verdict this artifact has had, and it means the round-104 coverage work landed.

The Solution finding is real and reproduced before any edit, using the reviewer's own fixture:

```
0x1000: ret ; nop ; ud2           (amd64, unseeded)
  makeFunction + propagate -> set(), one recorded block of size 1 (stops at the ret)
  getFunction(0x1002) is None -- nothing ever claimed the trap
overwrite the first two bytes with eb 00  ->  jmp 0x1002
pre-fix : propagateNoReturn() -> set()      fVa return-capable   WRONG
post-fix: propagateNoReturn() -> {0x1000}   fVa no-return        right
```

`_crossesOut` decided ownership only by `vw.getFunction(target) == fva`, and `getFunction` reads the
recorded block graph -- the exact artefact this pass exists to stop trusting. An address behind what
used to be a return has no block, so the jump read as an unproven outgoing tail call and the trap was
never walked.

Fixed: an unclaimed target (`getFunction` is None) that the instruction ITSELF names is fva's own
code. A target another function owns still needs proof. **The dereferenced case keeps the old
default**, because a `jmp [slot]` names nothing and its current pointee is runtime state (the PLT/IAT
thunk idiom), so an unclaimed pointee is no evidence of ownership. That deref branch is unpinned by
any test -- a declared beyond-contract conservatism, justified in the docstring.

### Cost on the saved ten

**10 of 10** for `test_a_branch_into_code_no_block_ever_claimed_is_still_this_function`, for the same
reason all ten already fail `code_reachable_only_after_a_terminal_is_replaced_is_decoded`: every one
of them builds its instruction universe from `getLocations(LOC_OP)` and cannot see undecoded bytes at
all. Marginal cost zero on a population that was already 0/10.

| run | failures /62 |
|---|---|
| Nova #6 | 5 |
| Nova #3, #4, #5, #7, #10 | 6 |
| Nova #8 | 7 |
| Nova #2 | 8 |
| Nova #1 | 9 |
| Nova #9 | 12 |

## Batch 17 (agent-runs/17) -- 10x Nova + 1x Vega, 0/11. Round-106 artifact, 62 tests.

**The tightest batch this artifact has ever produced, and the first one whose dominant wall is a
fairness defect I can point at.** Every baseline passed (134/134, all eleven). No environment
blockers, no wrapper timeouts.

| Run | Failed / 62 | Run | Failed / 62 |
|---|---|---|---|
| Nova #9 | **2** | Nova #3 | 5 |
| Nova #10 | 3 | Nova #4 | 6 |
| Nova #5 | 3 | Nova #1 | 7 |
| Vega | 3 | Nova #6 | 9 |
| Nova #2 | 4 | Nova #8 | 9 |
| Nova #7 | 4 | | |

Only **15 distinct tests** failed at all. 47 of 62 passed in every single run. Compare batch 11 (77
distinct failures, best run 42) and batch 12 (best run 22): the round-92 cut and rounds 95-106 have
taken this from diffuse to a short, named residual.

### One test failed 11 of 11, and it was not solvable from where the agents were working

`test_a_store_of_the_program_counter_is_not_a_transfer`. Every one of the eleven failed on its FIRST
assertion -- `assertIsNotNone(loc, "control continues past a store...")` -- not on the no-return
claim underneath it.

Measured on base, no solution applied at all:

```
str pc,[pc,#0]   iflags=0x30009  NOFALL=True BRANCH=True
ldr pc,[pc,#0]   iflags=0x30009  NOFALL=True BRANCH=True
```

The IF_NOFALL is in the BASE ARM decoder, so codeflow stops at the store and the `bx lr` behind it is
never decoded. No amount of work in `vivisect/analysis/generic/noret.py` makes an undecoded
instruction appear -- that assertion required repairing `envi/archs/arm/disasm.py`, and meta.md never
says the decoder mis-flags stores.

**Not one of the eleven opened `envi/` at all.** All eleven touched the same three files:
`vivisect/analysis/generic/noret.py`, `vivisect/base.py`, `vivisect/__init__.py`. Vega included. This
is the fourth batch to show that pattern (batch 12 recorded it first).

### The fix, and what it costs

Trimmed the three decoder-dependent assertions (`getLocation`, `L_LTYPE`, `parseOpcode(...).mnem`).
Kept the `addNoReturnVa(slotVa) == set()` claim and `assertReturns`, which a solver CAN satisfy from
the analysis layer by recognising that a store's first operand is its source.

Measured, not assumed:

- Reference still 62/62 with the trimmed test.
- **Both halves of the round-105 fix stay individually mutation-pinned.** Revert the decoder L-bit
  gate alone -> trimmed store_pc is the only failure. Revert the `no_update_Rd` half alone -> trimmed
  store_pc is the only failure. The round-105 property survives the trim exactly.
- The test still **fails 6 of 11** agents. It remains a real discriminator; it just stops being a
  universal decoder-gated wall.

So: pure fairness gain, zero coverage loss, and `test.patch` is the only file touched -- **re-eval
eligible**.

### Replay after the fix: still 0/11, and now every residual is a stated requirement

| run | failures | remaining |
|---|---|---|
| Nova #9 | **1** | sw_interrupt |
| Nova #5 | 2 | predicated_trap, sw_interrupt |
| Nova #10 | 2 | branch_into_code, code_reachable |
| Vega | 2 | trap_behind_computed, sw_interrupt |
| Nova #2 | 4 | branch_into_code, store_pc, code_reachable, uninit_slot |
| Nova #7 | 4 | branch_into_code, recorded_reference, store_pc, code_reachable |
| Nova #3 | 5 | + dispatch_two_cases, local_case |
| Nova #1, #4 | 6 | the computed-transfer family |
| Nova #6, #8 | 9 | widest miss, as in every batch |

Remaining frequency: `branch_into_code` 7, `code_reachable` 7, `store_pc` 6, `recorded_reference` 5,
`complemented_imm` 4, `own_operand` 4, `sw_interrupt` 4, then a tail of 1-3.

**Every route to a pass now runs through removing a requirement meta.md states.** Single drops: only
`sw_interrupt` reaches 1/11 (unlocks Nova #9). The one pair that gets there without it is
`branch_into_code` + `code_reachable` together (unlocks Nova #10). Both routes land at 1/11 = 9%, in
band.

`sw_interrupt` is fair on every reading -- meta.md states both clauses it tests, and 7 of 11 runs
solve it. Dropping a stated, majority-solved requirement to manufacture a pass is an FP risk, not a
fix. Held pending the user's call.

### Running total

**121 real-platform runs, 3 passes.** But the near-miss floor is now 1 failure, against 42 in batch 11
and 22 in batch 12.

## Round 108 replay -- the 61-test suite against batch 17's eleven

| run | failures | remaining |
|---|---|---|
| Nova #9 | **0** | **PASS** |
| Nova #5 | 1 | predicated_trap |
| Vega | 1 | trap_behind_computed |
| Nova #10 | 2 | branch_into_code, code_reachable |
| Nova #2 | 4 | branch_into_code, store_pc, code_reachable, uninit_slot |
| Nova #7 | 4 | branch_into_code, recorded_reference, store_pc, code_reachable |
| Nova #3 | 5 | + dispatch_two_cases, local_case |
| Nova #1, #4 | 6 | the computed-transfer family |
| Nova #8 | 8 | wide |
| Nova #6 | 9 | widest |

**1/11 = 9%**, in band. Two more runs sit one test away, so the near-miss floor is intact rather than
the suite having gone soft: `branch_into_code` (7) and `code_reachable` (7) still carry the rate.

Rate-setting residual after the cut: branch_into_code 7, code_reachable 7, store_pc 6,
recorded_reference 5, complemented_imm 4, own_operand 4, dispatch_two_cases 3, then a tail of 1-2.

## Batch 18 -- re-eval of batch 17's eleven against the 61-test round-108 suite

Solution patches byte-identical to batch 17, run for run. Reported **1/11** (Nova #9 PASS_LEGITIMATE)
with exactly the residual round 108 projected -- the local harness matches the platform a third time.

**Nova #9's pass was then adjudicated a FALSE POSITIVE and the adjudication is correct** (see
feedback.md round 109). Read this batch as **0/11 with one false positive**.

## Round 109 replay -- the 62-test suite (FP discriminator added) against the same eleven

| run | failures | remaining |
|---|---|---|
| Nova #9 | 1 | **new pc-store probe only** |
| Vega | 1 | trap_behind_computed (10 of 11 solve this -- implementation miss, not a wall) |
| Nova #5 | 2 | predicated_trap, pc-store probe |
| Nova #10 | 3 | branch_into_code, code_reachable, pc-store probe |
| Nova #2 | 5 | + store_pc, uninit_slot |
| Nova #7 | 5 | + recorded_reference |
| Nova #3 | 6 | + dispatch_two_cases, local_case |
| Nova #1, #4 | 7 | the computed-transfer family |
| Nova #8 | 9 | wide |
| Nova #6 | 10 | widest |

**0/11.** Correct rather than regressive: the only passer was the FP.

New rate-setting residual: **pc-store probe 10**, branch_into_code 7, code_reachable 7, store_pc 6,
recorded_reference 5, complemented_imm 4, own_operand 4, dispatch_two_cases 3, tail of 1-2.

No cheap cut buys a pass here any more -- removing the undecoded-bytes axis still leaves the probe
blocking #9 and #10. The population is exhausted.

### Running total

**132 real-platform runs, 2 genuine passes** (batches 1-2, at 16 and 26 tests). Batch 14's and batch
18's passes were both adjudicated false positives.

## Batch 19 -- 10x Nova + 3x Vega, 0/13. Round-110 artifact (62 tests, meta.md `8609dfab`).

First fully fresh population against the current description. All 13 baselines green (0/134). No
environment blockers. **No test failed by all 13, and 38 of 62 passed in every run.**

| Run | Failed / 62 | Run | Failed / 62 |
|---|---|---|---|
| Vega #3 | **2** | Nova #3, #9 | 6 |
| Nova #2, Vega #1 | 3 | Nova #7, #8 | 8 |
| Nova #5 | 4 | Nova #1 | 9 |
| Nova #10, #6, Vega #2 | 5 | Nova #4 | 21 |

### Frequency

| n/13 | test |
|---|---|
| 12 | `a_trap_behind_a_store_of_the_program_counter_settles_the_function` (round-109 FP discriminator) |
| 9 | `a_branch_into_code_no_block_ever_claimed_is_still_this_function` |
| 9 | `code_reachable_only_after_a_terminal_is_replaced_is_decoded` |
| 9 | `a_computed_transfer_settles_its_path_through_a_recorded_reference` |
| 8 | `a_store_of_the_program_counter_is_not_a_transfer` |
| 5 | uninitialized-slot, other-undefined-encodings |
| 4 | computed own-operand, computed complemented-immediate |
| 1-3 | a tail of 15 more |

24 distinct failing tests of 62.

### The decisive measurement: no single axis cut reaches solvability

| cut | tests removed | passes |
|---|---|---|
| pc-store axis (the FP discriminator) | 2 | **0/13** |
| undecoded-bytes axis | 4 | **0/13** |
| computed-transfer axis | 4 | **0/13** |
| pc-store + undecoded-bytes | 6 | **1/13** |
| pc-store + computed-transfer | 6 | 0/13 |
| undecoded-bytes + computed-transfer | 8 | 0/13 |
| all three | 10 | **2/13** |

**This is over-SCOPED, not over-strict, and now it is measured rather than argued.** The near-miss
tests differ per run -- Vega #3 misses `trap_behind_computed` + `local_case`, Vega #1 misses only the
store probe, Nova #2 misses `recorded_reference` + store probe + uninit-slot. Every agent solves a
different ~90% and drops a different ~10%. That is a conjunction of roughly six independent
capabilities, each individually fair and majority-solved, whose product is zero.

Note the coupling: the only two-axis cut that works includes the pc-store axis, which IS the round-109
false-positive discriminator. Removing it re-opens the FP that sank Nova #9 unless meta.md's store
clause goes with it.

### Vega read

Three Vega runs: 2, 3 and 5 failures -- the best run of the batch and two mid-pack. `trap_behind_computed`
was missed by Vega #3 and by batch 17's Vega, but NOT by Vega #1 or #2, so it is not a systematic Vega
blind spot. Vega is modestly better than Nova here (median 3 vs 6) but at 8x the token cost.

### Running total

**145 real-platform runs, 2 genuine passes**, both from batches 1-2 when the suite was 16 and 26
tests. **0 genuine in the last 79 runs**, across four scope-down attempts (round 80's 135->38, the
81-90 rebuild, round 92's cut, rounds 95-98).

## Round 111 replay -- the 56-test two-axis cut against batch 19's thirteen

| run | failures | run | failures |
|---|---|---|---|
| **Vega #1** | **0 (PASS)** | Nova #6, #9 | 3 |
| Vega #2 | 1 | Nova #7, #8 | 4 |
| Nova #2, #3, #5, #10, Vega #3 | 2 | Nova #1 | 5 |
| | | Nova #4 | 15 |

**1/13 = 7.7%**, in band at the hard edge. Six runs sit at 0-2.

Rate-setters after the cut: `a_computed_transfer_settles_its_path_through_a_recorded_reference` 9,
`memory_indirect_call_through_an_uninitialized_slot_resolves_to_nothing` 5,
`the_other_undefined_instruction_encodings_are_traps_too` 5, the two computed-operand negatives 4 each.

Vega #1's pass is FP-safe by construction: all 16 meta.md sentences are pinned by surviving tests, so
there is no described requirement it can meet only by coincidence (round 111 trace).

### Running total

**145 real-platform runs, 2 genuine passes on the platform.** The 1/13 above is a local replay of the
batch-19 population against the cut suite, not a platform batch -- it steers, a fresh batch confirms.

## Round 112 replay -- the 58-test suite (store fix + tests restored) against batch 19

| run | failures | run | failures |
|---|---|---|---|
| Vega #1 | 1 (trap-behind-store only) | Nova #3, #5, #9 | 4 |
| Vega #3 | 2 | Nova #6 | 5 |
| Nova #2, #10, Vega #2 | 3 | Nova #7, #8 | 6 |
| | | Nova #1 | 7 |
| | | Nova #4 | 17 |

**0/13.** Vega #1, round 111's passer, fails only the reviewer's own scenario -- it shares the defect
the Solution Quality review caught in the reference. Round 111's 1/13 should be read as 0/13 with one
pass carrying that bug.

This replay predates round 112's meta.md extension of the store clause, which the L35 caveat says the
harness cannot measure. A fresh batch is the only valid read of the current artifact.

### Running total

**145 real-platform runs, 2 genuine passes** (batches 1-2, 16 and 26 tests). Every apparent pass since
-- batch 14 Nova #6 (FP), batch 18 Nova #9 (FP), round 111 Vega #1 (replay) -- mis-handled ARM stores
of the program counter or its undefined-encoding sibling.

## Batch 20 -- 10x Nova + 1x Vega, 0/11. Round-112 artifact (58 tests, meta.md `8a7f8082`).

Fresh population. All baselines green (0/134). Every evaluator: `description_clear` True, fair, no
blocker, difficulty "challenging", no failure flagged not-in-description.

| Run | Failed / 58 | Run | Failed / 58 |
|---|---|---|---|
| Nova #10 | **1** (store-trap only) | Nova #8 | 5 |
| Nova #3, Vega | 2 | Nova #4, #6 | 6 |
| Nova #1, #5 | 3 | Nova #7, #9 | 7 |
| Nova #2 | 4 | | |

Frequency: **store-trap 10/11**, dispatch-two-cases 8, store-returns 5, direct-jump-proven 4,
undefined-encodings 4, predicated-register-branch 4, uninit-slot 3, recorded-reference 3, tail of 1-2.
Only 11 distinct failing tests; the computed-transfer family fell from 9 to 3.

### The store-trap wall is a description defect, measured

- **All 11 patches are store-aware** (`_is_store_mnem`, `_STORE_MNEM_PREFIXES`, `_is_pc_store`, ...);
  batch 19 was ~4 of 13. The round-112 wording did its job.
- On base the `bkpt` behind `str pc` is **never a recorded location** -- codeflow stops at the
  mis-flagged store and records only 0x2000. Same with Nova #10's patch applied.
- 9 of 11 agents walk `getLocations`; the reference walks `parseOpcode` only.
- Giving each failing agent the reference's decoder behaviour (trap recorded naturally): the
  store-trap test flips to pass for **6 of 10** failers (Nova #10, #5, #6, #8, #9, Vega). As graded,
  1 of 11 passed it; given the location, 7 of 11.
- Batch 19 cross-check: with the decoder behaving, 9 of 13 pass it -- including agents with no store
  logic at all, because a correctly decoded store simply falls through. The blocker is the
  unrecorded trap, not the store classification.

Full 58-test upper bound for batch 20 with the trap location available: **1/11** (Nova #10), Vega at 1
(recorded-reference). So the defect, once repaired, is worth about one run on this population.

## Batch 21 -- 10x Nova, platform 1/10 (Nova #8), adjudicated FALSE POSITIVE. Round-113 artifact.

Fresh population against meta.md `9b51a344`. All baselines green. Failures per run: Nova #8 **0**,
#6 1 (undefined-encodings), #9 1 (store-trap), #1 3, #5 4, #7 4, #3 5, #4 7, #10 7, #2 8.
Store-trap 8/10 (batch 20: 10/11) -- the round-113 clause helped modestly.

**Nova #8's pass is a false positive, and the panel is right.** Its `_pc_registers` hardcodes register
15 as the program counter on every architecture. On amd64, r15 is a general register, so
`mov r15,5 ; hlt` is misread as a transfer and the halt is never reached. Nova #6 has the same
hardcode. Read batch 21 as **0/10 with one FP**.

### The demanded regressions, built as real tests and measured on 21 fresh runs (batches 20+21)

Reference passes all seven (65/65). Encodings checked by decoding them first.

| test | demand | fails | base disassembly records the successor? |
|---|---|---|---|
| d1 `mov r15` then `hlt` must prove | FP panel | 3/21 | n/a (no successor issue) |
| d4 predicated `bl`, declared after | Auto Review #1 (variant) | 2/21 | yes |
| d7 `bkptne; bkpt` must prove | Auto Review #3 | 6/21 | yes |
| d6 `into; ud2` must prove | Auto Review #3 | 15/21 | **no** |
| d2 predicated `bl`, declared before, returns | Auto Review #1 | 19/21 | **no** |
| d3 same, fallthrough recorded as LOC_OP | Auto Review #1 | 19/21 | **no** |
| d5 `into; ret`, ret recorded as LOC_OP | Auto Review #2 | 20/21 | **no** |

The split is exact: every cheap test is solvable in the walker; every lethal one needs a successor that
base disassembly drops (base `into` is IF_NOFALL; base codeflow drops a conditional call's fallthrough
once its target is no-return). Same class as the store-trap wall.

**Nova #8's candidate-only failures are exactly d1, d2, d3, d5 -- four, matching Judge #2's "four
candidate-only required-behavior failures".** The FP panel independently treats the disassembly-
dependent behaviors as prompt-required, which rules out contesting them as T5-undiscoverable.

| candidate test set | passers | best run |
|---|---|---|
| d1 only | 0/21 | 1 |
| d1+d4+d7 (walker-layer answers) | 0/21 | 1 |
| + d6 | 0/21 | 1 |
| + d2 | 0/21 | 2 |
| + d3+d5 (as demanded) | 0/21 | 3 |
| everything demanded | 0/21 | 4 |

### Running total

**166 real-platform runs, 2 genuine passes** (batches 1-2, at 16 and 26 tests). Every apparent pass
since has been adjudicated a false positive or carried a defect a reviewer caught.
