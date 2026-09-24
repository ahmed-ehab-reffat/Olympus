# teavm-method-summaries - eval results

## Batch 1 (accepted, 2026-09-24): 4/10, all Nova

| Run | Verdict | New failed | Failed tests | Prompt tokens | Approach note |
|---|---|---|---|---|---|
| Nova 1 | FAIL | 1/26 | neverNullHoldsThroughMutualRecursion | 11.1M | never-null starts false, promote-only |
| Nova 2 | FAIL | 4/26 | withoutSummaries..., aCallInOneBranch..., fieldReadsSurvive..., aReturnGuarded... | 18.0M | initClass invalidates on null path; -2 sentinel into alias analysis |
| Nova 3 | FAIL | 3/26 | neverNullHolds..., aCallInOneBranch..., fieldReadsSurvive... | 12.0M | empty never-null set, add on proof; -2 sentinel |
| Nova 4 | FAIL | 1/26 | neverNullHoldsThroughMutualRecursion | 9.5M | computeNullness starts false |
| Nova 5 | PASS | 0/26 | - | 20.4M | optimistic map |
| Nova 6 | FAIL | 1/26 | withoutSummariesEveryPassBehavesAsBefore | 13.4M | initClass invalidatesAll when summaries null |
| Nova 7 | FAIL | 1/26 | neverNullHoldsThroughMutualRecursion | 10.4M | calculateNullness starts false |
| Nova 8 | PASS | 0/26 | - | 18.0M | neverReturnsNull = true seed |
| Nova 9 | PASS | 0/26 | - | 12.9M | optimistic, known flag |
| Nova 10 | PASS | 0/26 | - | 13.9M | seed = isReference(result type) |

All runs: base 213/0, 9 source files (the reference's set) + 1-4 own test files, +604..837 raw added lines.

## Local validation log

2026-09-23 (SLICE, local only, no platform batch)
| Check | Result |
|---|---|
| Docker cold build (v3, --no-cache, this HDD) | 474 s, EXIT 0 |
| Clean room uid 0:0 / 1000:1000 / 4242:4242, --network none | base (no sol) 213/0; new (no sol) 1 synthetic compile_test_sources failure; base (sol) 213/0; new (sol) 14/0 |
| Flakiness (root, with solution) | base 3x 213/0, new 3x 14/0, identical testcase ID lists |
| uid 1000 offline gradle compile in image | BUILD SUCCESSFUL |
| Mutants (20, host javac harness, new + base modes) | 17 killed, 3 survive (M16 invokedynamic-as-known, M17 virtual-unknown-skipped, M20 null-summaries RFRE initClass) |
| effective_loc_check.py | human-effective 291, raw 403, 9 files |
| Dockerfile v4 (COPY --chown, dirs/root-owned chmod) cold build | 431 s, EXIT 0 (v4 replaces the bind-mount v3 after the precheck Dockerfile-guidelines FAIL) |
| Clean room v4, 0:0 / 1000:1000 / 4242:4242 / 4242:0, --network none | base (no sol) 213/0; new (no sol) 1 synthetic failure; base (sol) 213/0; new (sol) 14/0 |
| Flakiness v4 (root, with solution) | base 3x, new 3x, identical testcase ID lists |
| Round 2 (2026-09-24) clean room, 4 uids, --network none | base 213/0 with and without solution; new 0/21 without (per-test fallback ids = with-solution ids), 21/21 with |
| Round 2 mutants (host) | undo absent-declaration fix, LIM unwired, M17, M20, SPECIAL without superclass lookup: each killed by exactly its new test |
| Round 2 flakiness (root) | base 3x, new 3x, identical ID lists |
| Round 3 (2026-09-24) clean room, 4 uids | base 213/0 with and without solution; new 0/24 without (ids identical), 24/24 with; root 3x+3x identical |
| Round 3 mutants (host) | SIMPLE unwired, eager unwired (TeaVM end-to-end test), RFRE null-as-empty, initClass null-as-empty in method, absent-declaration fix undone: all killed by their target test |
| Auto Review r1 fixes (2026-09-24) clean room, 4 uids | base 213/0 with and without solution; new 0/26 without (ids identical), 26/26 with; root 3x+3x identical |
| Auto Review r1 mutants | indy ignored, arrays excluded, summaries only for Main, SIMPLE unwired: all killed |
