# pict-engine-negative-values - eval results

No platform batch yet. Local validation numbers are logged below as they are measured.

## Local validation - SLICE (2026-09-23)

Image `factory-pict-engine-negative-values` built from a pristine clone at base (no patch in the
context), Dockerfile with `COPY --chown=1000:1000` + targeted `find ... chmod` (coordinator rule),
cold build ~10 s. test.patch then solution.patch applied inside the container, `--network none`.

| uid | base on base | new on base | base with solution | new with solution |
|---|---|---|---|---|
| 1000 | 588/588 pass | 28/28 fail | 588/588 pass (x3 identical) | 28/28 pass (x3 identical) |
| 0 | 588/588 pass | 28/28 fail | 588/588 pass | 28/28 pass |
| 4242 | 588/588 pass | 28/28 fail | 588/588 pass | 28/28 pass |

- New-on-base failure reasons: API tests `undefined symbol: PictSetNegativeValue`; CLI tests fail
  the stated properties (missing child negatives, seeds) or the pict exit code (two-valued seeds
  assert on base).
- JUnit ids unique, no `::` (588 base, 28 new).
- Effective LOC (hook): 252 human-effective, 419 raw, 13 files.
- Mutants: no partner rows (naive CLI port) -> 9/28 fail; one partner row per child -> 1/28 fail
  (only the wide CLI model; FINISH adds API cells).

## Local validation - R2 after Auto Review (2026-09-24)

Clean room `worktrees/_pict_cr` (fresh clone at base with .git, image from the submission
Dockerfile, both patches applied in the container, `--network none`). Build 51 s.

| uid | base on base | new on base | base with solution (x3) | new with solution (x3) |
|---|---|---|---|---|
| 1000 | 588/588 pass | 33/33 fail | 588/588 pass, identical | 33/33 pass, identical |
| 0 | 588/588 pass | 33/33 fail | 588/588 pass, identical | 33/33 pass, identical |
| 4242 | 588/588 pass | 33/33 fail | 588/588 pass, identical | 33/33 pass, identical |

- New tests (5): public-header client, lifecycle leak client, two model-tree exclusion tests, one CLI
  constraint test. Two existing marking tests widened.
- Mutants: old PictDeleteModel -> lifecycle fails (80 live allocations); old pictapi.h with stale
  lib -> header fails, ctypes marking test passes; user exclusions dropped from child models in the
  negative phase -> only the new API tree test + new CLI test fail; user exclusions dropped from the
  negative phase everywhere -> flat, tree and CLI exclusion tests fail.
- Effective LOC (hook): 257 human-effective, 13 files.

## Local validation - R3 (2026-09-24, tests only)

Same clean room, image pict-cr:r2, `--network none --memory 2g`, one uid at a time (an earlier
three-uid background run was reaped for low host memory).

| uid | base on base | new on base | base with solution (x3) | new with solution (x3) |
|---|---|---|---|---|
| 1000 | 588/588 pass | 37/37 fail | 588/588 pass, identical | 37/37 pass, identical |
| 0 | 588/588 pass | 37/37 fail | 588/588 pass, identical | 37/37 pass, identical |
| 4242 | 588/588 pass | 37/37 fail | 588/588 pass, identical | 37/37 pass, identical |

- CLI tests no longer load libpict.so; checked against a base-built pict binary, all 7 fail on base
  through CLI behaviour (missing negatives / coverage), not on import.
- Pairwise-join mutant (models with children and their params capped at order 2): fails the new
  API order-3 test and the new CLI order-3 test.

## Local validation - R4 (2026-09-24)

Clean room as R3 (`--memory 2g`, one uid at a time). uid 1000, 0, 4242: base 588/588 pass with and
without the solution; new 39/39 fail without, 39/39 pass with, 3 identical runs each. Lifecycle
mutants (PictDeleteModel no-op + PictDeleteTask frees tree; root-only params; params deferred to
the task) all fail the lifecycle test. 253 human-effective.

## Local validation - R5 (2026-09-24)

Clean room as R3/R4. uid 1000, 0, 4242: base 588/588 pass with and without the solution; new 40/40
fail without, 40/40 pass with, 3 identical runs each. Mutants: pict.def entries removed -> export
test fails; already-negative check moved after the count -> marking + header tests fail.

## Batch 1 (platform, 2026-09-25) - 0/11 (10 Nova, 1 Vega) - UNSOLVABLE as measured

Artifacts in agent-runs/1/. Median 162 requests per run (floor 40).

| run | verdict | new pass | base fails | clusters failed | touched cli/ |
|---|---|---|---|---|---|
| Nova #10 (dir 1) | MISSED_REQ | 28/40 | 0 | #44 partner rows (API 5 + CLI 7) | yes (gcdmodel only) |
| Nova #1 (dir 10) | MISSED_REQ | 21/40 | 0 | #44 + sequence/link crash (7) | no |
| Nova #9 (dir 2) | REGRESSION | 29/40 | 95 (abort 134) | crash 4 + CLI crash 7 | yes |
| Nova #8 (dir 3) | REGRESSION | 25/40 | 104 | crash 7 + CLI crash 7 | yes |
| Nova #7 (dir 4) | REGRESSION | 29/40 | 44 (seeding) | seeds gcd assert + crash (9), CLI seeds 2 | yes |
| Nova #6 (dir 5) | MISSED_REQ | 21/40 | 0 | #44 + crash 7 | yes |
| Nova #5 (dir 6) | MISSED_REQ | 14/40 | 0 | sequence assert on every child test (19) + CLI #44 | no |
| Nova #4 (dir 7) | WRONG_LOGIC | 13/40 | 5 | positive coverage from negative rows + #44 + crash | no |
| Nova #3 (dir 8) | REGRESSION | 12/40 | 8 | positive coverage + #44 + crash | yes |
| Nova #2 (dir 9) | REGRESSION | 36/40 | 9 (func001 IsPositive, abort) | ONLY the 4 cross-model user-exclusion tests | yes |
| Vega #1 | MISSED_REQ | 17/40 | 0 | positive coverage filled by negative rows + #44 + CLI | yes |

Per-test kills (top): CLI seeded 10, CLI two-valued 10, other 5 CLI #44 tests 9 each, excluded_tree x2 9,
stateful repeat 9, lifecycle 8 (all crashes, none a real leak), nested generation error 7.

Clusters:
- #44 partner rows (the designed core trap): 8/11 fail it on the CLI, 6/11 on the API. Only dir 2 (Nova #9)
  and dir 7 (Nova #7, CLI) got through.
- Sequence collision / stale exclusion links (designed traps 3+4): 8/11 crash somewhere. dir 6 crashes on
  EVERY child-model test, i.e. the masking exclusions across children alone trigger it; not only the
  R2 cross-model user-exclusion sentence.
- Base regressions: 6/11 (asserts, exit 134, in the repo's own perl suite). dir 4 never touched cli/ and
  still broke 5, so engine edits alone can regress the CLI.
- Positive coverage filled by negative rows (Vega, dirs 7, 8): a misread of a clearly stated sentence.

No run is one test-only lever from passing: the nearest (dir 2) fails the 4 cross-model user-exclusion
tests AND 9 base tests; dir 1 fails only the core #44 cluster. Re-eval cannot produce a pass without
dropping the core requirement.

## R6 cut - replay of batch-1 patches + clean room (2026-09-25)

Replay (worktrees/_pict_replay/replay.sh: base clone + agent solution-patch minus tests + new
test.patch, build, run new mode). New suite = 33 API tests, no CLI, exclusions in one model per tree.

| run | new pass (R6 suite) | api-only base check |
|---|---|---|
| dir 9 (Nova #2) | 33/33 | 0 ERROR -> COUNTERFACTUAL PASS |
| dir 2 (Nova #9) | 33/33 | 5 ERROR (engine regression) -> fail |
| dir 1 (Nova #10) | 28/33 | #44 cluster |
| dirs 3,4,5,10 | 25-27/33 | crashes / seeds / #44 |
| dirs 6,7,8, Vega | 14-16/33 | sequence crash on all child tests / positive-coverage misread |

Counterfactual 1/11 (~9%): solvable, at the hard edge.

Finding during the cut: base's C API ALREADY aborts (compareExclusionTerms sequence assert) on a
tree with user exclusions in two different child models, no negatives involved (per-model
parameter numbering). The first R6 fixture (exclusions in inner + middle + branch) silently required
fixing that pre-existing bug; it now puts user exclusions in one model per tree. The masking
exclusions the feature itself creates across child models still hit the collision (inherent trap).

Clean room (pict-cr:r2, --network none --memory 2g), uid 1000 / 0 / 4242: base 588/588 pass with and
without the solution; new 33/33 fail without, 33/33 pass with, 3 identical runs each.

## R7 (2026-09-25, test.patch only)

New ordinary-model column-mapping test. Clean room uid 1000/0/4242: base 588/588 with and without the
solution; new 34/34 fail without, 34/34 pass with, x3. Batch-1 patches dirs 9, 2, 1 pass the new test,
so the R6 replay estimate (1/11) stands.

## Batch 2 (platform, 2026-09-25, R7 artifact) - 0/11 (10 Nova, 1 Vega)

| run | verdict | new pass | base fails | requests |
|---|---|---|---|---|
| Nova #10 (dir 1) | MISSED_REQ | 27/34 | 0 | 168 |
| Nova #1 (dir 10) | MISSED_REQ | 7/34 | 0 | 138 |
| Nova #9 (dir 2) | REGRESSION | 21/34 | 34 | 173 |
| Nova #8 (dir 3) | REGRESSION | 29/34 | 5 | 111 |
| Nova #7 (dir 4) | MISSED_REQ | 33/34 | 0 | 120 |
| Nova #6 (dir 5) | UNVERIFIED_ASSUMPTION | 2/34 | 5 | 111 |
| Nova #5 (dir 6) | MISSED_REQ | 16/34 | 5 | 69 |
| Nova #4 (dir 7) | WRONG_LOGIC | 15/34 | 0 | 100 |
| Nova #3 (dir 8) | REGRESSION | 3/34 | 5 | 149 |
| Nova #2 (dir 9) | REGRESSION | 17/34 | 10 | 108 |
| Vega #1 | REGRESSION | 29/34 | 5 | 74 |

Top kills: the #44 child-negative cluster (5 tests) 10/11 each.

Nova #7 (dir 4) failed ONLY test_deleting_model_trees_releases_every_parameter, and not on a leak: the
client aborted in generation (Parameter::PickValue bestValueCount > 0). Replayed locally and narrowed:
the trigger is the lifecycle fixture's exclusion (L1=0, L2=1) written in R6. L1 has two values and 1 is
negative, so L1=0 is its only non-negative value and the exclusion leaves L2=1 with no non-negative
partner (a degenerate derived-exclusion case). The reference copes; the agent's generator asserts.
Tested nowhere else and not stated in meta -> an accidental wall inside a deletion test. Fixed the
fixture to (L1=1 negative, L2=2); the agent's library then generates the lifecycle tree cleanly.

R8 (test.patch only): lifecycle fixture exclusion fixed; Tree.fetch now asserts every cell of every row is
a value of its column's parameter (Auto Review Medium: negative rows padded with undefined values).
Replay of batch-2 patches on R8: Nova #7 (dir 4) 34/34 with 0 base failures -> 1/11 (~9%); dir 1 27/34,
Vega 29/34, dir 3 29/34, rest <= 22/34. Clean room 1000/0/4242: base 588/588 with and without the
solution; new 34/34 fail without, 34/34 pass with, x3.

## Re-eval of batch 2 on R8 (platform, 2026-09-26) - 1/11, FP-flagged

agent-runs/3: Nova #7 (dir 4) PASS_LEGITIMATE 34/34, base clean; everyone else as in batch 2.
FP check: FALSE POSITIVE (adjudicator, high confidence). Nova #7's PictGenerate never returns on a flat
order-2 model a(3, neg 0), b(4), c(2, neg 0) with exclusion (a=1, c=1); reference returns PICT_SUCCESS.
Class: a "starved" value - c=1 is c's only non-negative value, so a=1 has no row without a negative.
Same class as the lifecycle fixture that aborted Nova #7 in batch 2.

Starvation probe over all 22 saved solutions (worktrees/_pict_replay/starve_all.sh):
batch 1: 7 succeed, 4 abort (incl. dir 9 = the R6 counterfactual passer);
batch 2: 6 succeed, 1 GENERATION_ERROR, 1 hangs (Nova #7), 3 abort. Reference: success.
Every solution that passed the full suite fails the starved model -> a starvation test makes the
measured rate 0/22.

## R10 (2026-09-26, test.patch)

test_child_models_combine_as_whole_rows over the 22 saved solutions: PASS b1 dirs 4, 7, 8, 9, Vega and
b2 dirs 4, 9; the rest fail (partner rows / generation error / crash). Both prior full-suite passers keep
passing. Clean room uid 1000/0/4242: base 588/588 with and without; new 35/35 fail without, 35/35 pass
with, x3.

## Batch 3 (fresh on R9 meta) re-evaluated on R10 tests (platform, 2026-09-28) - 2/10, both FP-flagged

agent-runs/4 (dir Nova_Nova_7 is an empty duplicate of Nova #5). PASS: Nova #6 (dir 6), Nova #4 (dir 8),
both 35/35 base clean. Nova #10 (dir 2) 35/35 new but 5 base aborts (cons020/021/400/401, real201: exit 134
where base expects 5) - the same 5-test regression shows up in many runs of batches 2 and 3.
Median requests ~140.

FP flags (adjudicator high confidence, both): PickValue bestValueCount > 0 abort when exclusions constrain
the non-negative filler of a row carrying a negative value.
- FP1: P0(3), P1(2, neg 1), P2(3, neg 2), exclusion (P1=0, P0=2, P2=2): the negative pair (P2=2, P0=2)
  cannot be completed at all (degenerate).
- FP2: P0(3), P1(3, neg 0), P2(3, neg 1), exclusions (P1=1, P2=0), (P0=2, P2=2): every combination is
  completable; an ordinary model.
Probe: all FOUR solutions that ever passed the full suite (b1 dir 9, b2 dir 4, b4 dirs 6, 8) crash or
hang on FP2; reference succeeds.
Seeded fuzz (40 flat models each, worktrees/_pict_replay/fuzz.py): exclusions only among parameters WITHOUT
negative values -> all four passers 0/40 bad; unrestricted exclusions -> 9-14/40 bad. Reference 0 bad (one
fuzz seed produced a duplicate exclusion, rejected by base PictAddExclusion - harness artefact).

## R11 (2026-09-28) - plain-exclusion contract, 34 tests

Replay (worktrees/_pict_replay/replay_sel.sh): all four historical full-suite passers 34/34 (b1 dir 9,
b2 dir 4, b4 dirs 6, 8). Batch 3: Nova #6, #4 pass; Nova #10 34/34 new but its 5 base aborts remain;
others 7-28/34 -> batch-3 counterfactual 2/10. Clean room uid 1000 and 0: base 588/588 with and without
the solution; new 34/34 fail without, 34/34 pass with, x3.

## Batch 4 (fresh on R11, platform, 2026-09-28) - 0/11 (10 Nova, 1 Vega)

agent-runs/5. Median requests ~118.
| run | verdict | new pass | base fails | note |
|---|---|---|---|---|
| Nova #10, #9, #8, #5, #4, #1 (dirs 1, 2, 3, 6, 7, 10) | MISSED_REQ / WRONG_LOGIC | 17/34 | 0 | single-pass generation with pair masks: negative rows fill positive coverage (stated clearly in meta) |
| Nova #7 (dir 4) | MISSED_REQ | 28/34 | 0 | #44 child-negative cluster |
| Nova #6 (dir 5) | REGRESSION | 31/34 | 34 | repeat-generation tests + bug015 aborts |
| Nova #3 (dir 8) | SYNTAX_ERROR | 0/34 | 587 | build broken |
| Nova #2 (dir 9) | MISSED_REQ | 4/34 | 0 | |
| Vega #1 | MISSED_REQ | 33/34 | 0 | ONLY test_child_models_combine_as_whole_rows: negative child row (L1=2,L2=0) not paired with every valid sibling row |

The single-pass misread hit 7/11 this batch vs 3-5 in batches 1-3 (same sentence) -> batch variance, not a
description change. Batch 3 on the same artifact re-evaluated 2/10.

## R12 (2026-09-28, test.patch)

assert_whole_groups added to the mixed-parent tests. Replay: b1 dir 9, b2 dir 4, b4 dirs 6, 8 -> 34/34;
b5 Vega 33/34 (whole-row test only); b5 Nova #6 31/34. Clean room uid 1000/0/4242: base 588/588 with and
without the solution; new 34/34 fail without, 34/34 pass with, x3.
