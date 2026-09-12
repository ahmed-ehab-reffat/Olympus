# eval-results — calyx-unused-port-elimination

## Batches

No agent batch has been run. This file is created up front per the workflow rule and
will hold one table per batch.

Fingerprint to record with the first batch (git blob SHA of each deliverable):

```
sol=$(git hash-object solution.patch)
test=$(git hash-object test.patch)
meta=$(git hash-object meta.md)
docker=$(git hash-object Dockerfile)
base=$(cat BASE_COMMIT.txt)
```

| Batch | Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|---|
| B1 2026-07-24 | Nova x2 | Nova | PASS_LEGITIMATE x2 | ~670-770 LOC | 3 | ~700 | none | too easy (100%) - syntactic liveness sufficed | full fixpoint, syntactic read-counting |

## Local evidence (no agents)

| Check | Result |
|---|---|
| new tests, solution applied | 29/29 pass, 3 runs identical |
| new tests, base only | 29/29 fail, `Unknown pass: dead-port-elimination` |
| base suite, solution applied | 254/254 pass, 3 runs identical |
| base suite, base only | 254/254 pass |
| docker offline, both modes | green |
| solution effective LOC | 451 human-effective, 613 auto-block counter |
| files touched | 7 across calyx-frontend, calyx-ir, calyx-opt |

## Mutation coverage (which rule each test group discriminates)

| Rule | Tests failing when the rule is disabled |
|---|---|
| control-program reads | while cond, if cond, invoke output binding, static control, cascade x2 |
| guard operand reads | guard read, comparison guard |
| fixpoint | cascade stops at live read, continuous assignment read |
| interface ports | interface ports survive on unused component |
| `@fixed_signature` | keeps every port, keeps unused ref cells |
| entrypoint preserved | entrypoint signature untouched |

## Watch items for the first batch

- Median message count on PASSED runs only; floor is 40 for the current sprint rule.
- Whether failures cluster on one test (fairness gap) or spread (genuine difficulty).
- Capture every passing agent's diff into `agent-runs/<batch>-<run>.patch` before the run
  view closes; the differential harness and the FP check both need them.
- FP check: for each passing agent, confirm it really implements the whole-program rule
  rather than a per-component approximation that happens to satisfy these programs.

## Batch B1 (2026-07-24) - PRE-HARDENING, too easy

2/2 Nova PASS_LEGITIMATE. Both wrote full-fixpoint solutions using SYNTACTIC liveness
("read anywhere = live"). 100% pass = too easy. Diagnosis + fix in feedback.md Round 5.

## Post-hardening state (transitive liveness, UNMEASURED)

- 76 new tests (round 14: 4 constant-rewrite tests made form-agnostic per Test Fairness FAIL; +fixed_signature-vs-constant coverage), all pass with solution / all fail on base (round 6 added 5 edge cases).
- Soundness: dead-port-elimination then well-formed over corpus = 334 clean / 0 malformed.
- FP mutation matrix (see feedback.md): M1 syntactic=under-removal 3 fails; M2 over-aggressive=21;
  M3/M4 comb-mark gaps=1/2. Opposing interdependent traps confirmed.
- Difficulty at new hardness NOT yet measured - needs fresh Nova/Orion batch.

## Batch B2 (agent-runs2, 8 Nova + 3 Orion): 0/11 -> eased
- Global blindspot: multi-level transitive cascade. ref-chain test 11/11 (UNFAIR - contradicts meta 'never mentions' rule), constant-output-cascade 8/11.
- Removed both. Replayed agent solutions vs reduced suite: 3/11 pass (Orion_1, Nova_1, Nova_4) = ~27%. Verified, not inferred.
- Suite now 74 tests.

## Batch B3 (agent-runs3, 8 Nova + 1 Orion): 0/9 -> eased to 3/9
- Blocker shifted to invoke_output_binding_to_a_removed_caller_port_is_dropped (8/9). Structure = multiple independent hard integration points.
- Removed invoke-output-caller + report_lists_sorted (peripheral). Replay of all 9 solutions vs final 72-test suite: 3/9 pass (Nova_3, Nova_4, Nova_7) ~33%. Verified.
- Suite now 72 tests.
