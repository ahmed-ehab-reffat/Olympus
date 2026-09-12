# eval-results — neva-array-bypass-generalization

No platform agent batch has run yet. This file records the local validation evidence and will hold the per-agent table once a batch runs.

## Fingerprint

Recompute with `git hash-object <file>` before trusting any batch below.

| file | sha |
|---|---|
| (fill at batch time) | |

## Local validation (2026-07-27)

Toolchain: go1.26.5, repo at BASE_COMMIT 939996ba4611ca6798026852cdb3b617a8bce84f.

Clean-room: fresh clone at BASE_COMMIT, patches applied from the submission folder.

| check | result |
|---|---|
| `test.sh base` with test.patch only, no solution | 615 testcases, 0 failures |
| `test.sh new` with test.patch only, no solution | 10 testcases, **10 failures** (every new test fails on base) |
| `test.sh new` with solution, 3 consecutive runs | 10 testcases, 0 failures, identical each run |
| `test.sh base` with solution | 615 testcases, 0 failures (no regressions) |
| patches apply and reverse in either order | clean |
| JUnit XML on a deliberately broken build | XML still written, 1 case, 1 failure carrying the compiler error |
| Docker `--network none --user 1000:1000`, base | 615 testcases, 0 failures |
| Docker, new with solution | 10 / 0 failures |
| Docker, new without solution | 10 / 10 failures |

Base mode runs 128 packages: all of `internal/`, `pkg/` and every e2e package that has tests. Two e2e packages are excluded with the reason inline in test.sh: `interface_with_imports` and `cli/build_with_ir_target` download a neva dependency over the network, which is unavailable during the run. Local and container base runs now agree at 615.

## Base failure modes per new test (why each is a real f2p)

| test | base symptom |
|---|---|
| array_bypass_portless_port | runtime panic `fan_in: array port not found by name: data` |
| array_bypass_outport | runtime panic `fan_out: port 'data' is not array` |
| array_bypass_self_ports | program hangs (connections emitted on a bad path), 60s timeout |
| array_bypass_chained | compile error, chained bypass rejected |
| array_bypass_fan_out | compile error, `Array-bypass requires [*] on both sides` |
| array_bypass_single_slot | runtime panic `fan_out: port 'data' is not array` |
| array_bypass_three_slots | hangs, 60s timeout |
| array_bypass_shared_component | hangs, 60s timeout |
| array_bypass_nested_levels | hangs, 60s timeout |
| compiler_error_array_bypass_unanchored | base compiles it and panics at runtime instead of reporting a compile error |

Three distinct base symptoms (panic, hang, compile-reject) means no single mechanical fix clears them.

## Flakiness gate

- New tests: 3 identical runs, no timing assertions, no unseeded randomness, no network. Every program's output is a single deterministic value produced by an `Add` that must receive both inputs, so message ordering cannot change the result.
- One earlier draft used `e2e.WithTimeout(20s)` on three cases and flaked under parallel cold-cache load. Removed, and `test.sh` now runs packages serially with `-p 1`. Recorded so it is not reintroduced.
- Repo baseline: `./internal/...`, `./pkg/...` and 126 e2e packages, identical results across runs.

## Re-validation after the round-1 check fixes (2026-07-27)

Test files renamed and directories re-hashed, meta.md rewritten, stray artifacts removed from test.patch. Full clean-room run repeated:

| check | result |
|---|---|
| base, no solution | 615 / 0 failures |
| new, no solution | 10 cases, 10 failures |
| new, with solution, 3 runs | 10 / 0 each, identical |
| base, with solution | 615 / 0 failures |

## Already-implemented check against main HEAD

Built the CLI from `origin/main` at `a0a5c5fe` and ran each case program:

| case | main HEAD behavior |
|---|---|
| outport direction | `panic: fan_out: port 'data' is not array` |
| self-port pass-through | hangs |
| chained bypass | `Array-bypass requires [*] on both sides of a single connection` |
| fan-out over bypass | same compile rejection |
| portless bypass | `panic: fan_in: array port not found by name: data` |

## Round 2 (12 tests, injected-dependency wall added)

| check | result |
|---|---|
| base, no solution | 615 / 0 failures |
| new, no solution | 12 cases, **12 failures** |
| new, with solution, 3 runs | 12 / 0 each, identical |
| base, with solution | 615 / 0 failures |

Solution: 293 human-effective LOC (458 raw, 367 under the platform counter) across 3 files.

## Round 3 (15 tests, array-port barrier added)

| check | result |
|---|---|
| base, no solution | 615 / 0 failures |
| new, no solution | 15 cases, **15 failures** |
| new, with solution, 3 runs | 15 / 0 each, identical |
| base, with solution | 615 / 0 failures |

Solution: 317 human-effective LOC (522 raw, 408 under the platform counter) across 6 files in 4 subsystems (analyzer, desugarer, IR generation, runtime + stdlib).

## Round 4 (16 tests, Auto Review response)

| check | result |
|---|---|
| base, no solution | 615 / 0 failures |
| new, no solution | 16 cases, **16 failures** |
| new, with solution, 3 runs | 16 / 0 each, identical |
| base, with solution | 615 / 0 failures |

Solution: 320 human-effective LOC (526 raw, 412 under the platform counter) across 6 files in 4 subsystems.

FP check: PASS, 0 false positives across the panel. The passing solver used a different architecture (WaitAll composed over `lists.FromArray`, analyzer delegating to the normal connection path) and was correctly adjudicated genuine, which is evidence the contract does not over-constrain implementations. Tests assert no `WaitAll` payload shape, so that divergence stays fair.

## Round 5 (18 tests, fairness coverage suggestions)

Two of the three Test Fairness coverage suggestions taken; the third declined.

| check | result |
|---|---|
| base, no solution | 615 / 0 failures |
| new, no solution | 18 cases, 18 failures |
| new, with solution, 3 runs | 18 / 0 each, identical |
| base, with solution | 615 / 0 failures |

Added `array_bypass_receiver_anchored_fan_out` (node array outport fanning out to two component self outports, so receiver-side width inference and per-slot fan-out are exercised in one connection; base rejects it with `Array-bypass requires [*] on both sides`) and `wait_all_single_slot` (arity-1 barrier, guards against assuming a minimum width of two; base fails with `entity not found: WaitAll`). Both deterministic across 3 runs.

Declined: pinning a diagnostic fragment on the unanchored error. HARDENING 3d records that no error-message substring is stably fair, the fairness panel itself rated the location-only assertion "well-targeted and non-brittle", and the FP panel confirmed a passing solver used a different architecture, so wording is exactly the kind of thing a correct solution may legitimately vary.

Solution unchanged at 320 human-effective LOC (526 raw, 412 platform counter) across 6 files.

## Round 6 (19 tests, one-shot WaitAll gap closed)

| check | result |
|---|---|
| base, no solution | 615 / 0 failures |
| new, no solution | 19 cases, 19 failures |
| new, with solution, 3 runs | 19 / 0 each, identical |
| base, with solution | 615 / 0 failures |

New mutation in the trap-proof table:

| # | Wrong implementation | Killed by | Symptom |
|---|---|---|---|
| V12 | one-shot WaitAll: emits once, then exits | 1 of 19 (`wait_all_two_rounds`), 3 of 3 runs | deadlock, 60s timeout, since the round counter never reaches two |

Solution unchanged at 320 human-effective LOC (526 raw, 412 platform counter) across 6 files.

## Round 7 (19 tests, both fairness FAILs addressed)

| check | result |
|---|---|
| base, no solution | 615 / 0 failures |
| new, no solution | 19 cases, 19 failures |
| new, with solution, 3 runs | 19 / 0 each, identical |
| base, with solution | 615 / 0 failures |

Solution: 282 human-effective LOC (465 raw, 365 platform counter) across 6 files. The drop from 320 is the removal of `injectedArrayPortName` plus its `scope` threading, dead once the DI test's port names were aligned with the documented interface-compatibility rule.

## Round 8 (21 tests, slot-identity wall)

| check | result |
|---|---|
| base, no solution | 615 / 0 failures |
| new, no solution | 21 cases, 21 failures |
| new, with solution, 3 runs | 21 / 0 each, identical |
| base, with solution | 615 / 0 failures |

Added `array_bypass_slot_identity` and `array_bypass_slot_identity_outport`. Both assert `26\n` from a `Sub` fed by slot 0 and slot 1, so a permuted slot map prints `-26` and a collapsed one hangs.

| # | Wrong implementation | Killed |
|---|---|---|
| V10 | every bypass receiver slot registered as slot 0 | 13 of 21 (was 2 of 15) |
| V13 | receiver slots 0 and 1 swapped | 4 of 21, incl. both new cases |
| V14 | sender slots 0 and 1 swapped | 5 of 21, incl. both new cases |

Solution unchanged at 282 human-effective LOC (465 raw, 365 platform counter); this round is tests only, so meta.md and both source patches are untouched apart from the test.patch regeneration.

## BATCH (2026-08-01) — ACCEPTED at 2/10 = 20%

| run | solver | verdict | new-test failures |
|---|---|---|---|
| Nova #1 | Nova | FAIL_MISSED_REQUIREMENT | 10 |
| Nova #2 | Nova | FAIL_MISSED_REQUIREMENT | 10 |
| Nova #3 | Nova | FAIL_MISSED_REQUIREMENT | 10 |
| Nova #4 | Nova | FAIL_MISSED_REQUIREMENT | **1** (receiver_anchored_fan_out) |
| Nova #5 | Nova | FAIL_MISSED_REQUIREMENT | 10 |
| Nova #6 | Nova | FAIL_WRONG_LOGIC | 10 |
| Nova #7 | Nova | FAIL_MISSED_REQUIREMENT | 10 |
| Nova #8 | Nova | **PASS_LEGITIMATE** | 0 |
| Nova #9 | Nova | FAIL_MISSED_REQUIREMENT | **1** (receiver_anchored_fan_out) |
| Orion #1 | Orion | **PASS_LEGITIMATE** | 0 |

Baseline 607/607 in every run. Agent split: Orion 1/1, Nova 1/9 (11%).

**Per-test kill counts (of 10 runs).** 11 of 21 tests killed nothing.

| kills | test |
|---|---|
| 8 | array_bypass_receiver_anchored_fan_out |
| 6 | chained, fan_out, into_barrier, into_barrier_three, nested_levels, outport, portless_port, single_slot, slot_identity |
| 0 | fan_out_multi_slot, injected_dependency, self_ports, shared_component, slot_identity_outport, three_slots, compiler_error_array_bypass_unanchored, wait_all_barrier, wait_all_distinct_slots, wait_all_single_slot, wait_all_two_rounds |

**Cluster A (6 runs, identical 10-test block).** Resolution dropped at the analyzer/irgen
boundary. Evaluator on Nova #1, verbatim: *"analyzeArrayBypassConnection obtains resolvedSender
and resolvedReceiver but analyzeConnection returns the original conn"*. Symptoms: 7 panics inside
unrelated stdlib runtime funcs, 3 sixty-second deadlocks with empty stdout and stderr.
Catalogued as `failure-patterns.md` **F-9**.

**Cluster B (2 runs at 20/21) — the band decider.** `receiver_anchored_fan_out` composes two
stated axes (which side is anchored x one-vs-many receivers). Both agents implemented each axis
correctly in isolation and printed `20\n20\n` instead of `20\n`. Without this single test the
batch reads 4/10 = 40%, at the ceiling. Catalogued as **F-10**.

**Fairness/FP.** Every evaluator recorded `description_clear: true`, `tests_deterministic: true`,
`difficulty: challenging`. The two near-miss justifications both recorded
`was_mentioned_in_description: true` and `was_inferable_from_codebase_excluding_tests: true`.

**Long horizon.** Passing patches 610-693 added lines across 15-19 files; failures 520-783 across
14-16 files; 5.9-14M prompt tokens per run.

**What the batch says about the hardening rounds.** The WaitAll barrier (rounds 3 and 6, three
rounds of work) killed zero agents. The round-8 slot-identity tests killed 6 but always
co-occurring with cluster A, so zero independent kills. Neither changed an outcome; the decisive
test came from a Test Fairness coverage suggestion in round 5.
