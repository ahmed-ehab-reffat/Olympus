# pyparsing-parse-enumeration — eval results

No platform runs yet. Local validation is complete and green (details in `feedback.md`).

## Local validation matrix

| Cell | Command | Result |
|---|---|---|
| BASE + base tests | `./test.sh --output_path X base` | 2025 passed, 27 skipped, 0 failed |
| BASE + new tests | `./test.sh --output_path X new` | 122 total, **122 failed, 0 passed** (F2P clean) |
| SOLUTION + base tests | `./test.sh --output_path X base` | 2025 passed, 27 skipped, 0 failed (no regressions) |
| SOLUTION + new tests | `./test.sh --output_path X new` | 122 passed |
| solution applied first, then test patch | `./test.sh --output_path X new` | 122 passed |

All cells run in the deliverable Dockerfile image with `--network none` and `--user 1000:1000`.

## Flakiness gate (mandatory)

| Run | new mode | base mode |
|---|---|---|
| 1 | 122 passed | 2025 passed, 27 skipped |
| 2 | 122 passed | 2025 passed, 27 skipped |
| 3 | 122 passed | 2025 passed, 27 skipped |

Repo baseline before any change was also run 3x: identical every time (2025 passed, 27 skipped).

## Size

| Metric | Value |
|---|---|
| human-effective LOC (Counter 2, hook) | 451 |
| platform auto-block LOC (Counter 1) | 532 |
| raw added | 667 |
| files touched (source) | 3 (`core.py`, `enumeration.py`, `__init__.py`) |
| new tests | 122 |

## Mutation / trap-proof summary

14 natural-but-wrong implementations were applied to the reference; every one is caught, by different
test groups (3, 4, 43, 25, 13, 5, 15, 2, 6, 8, 21, 1 failures, plus the two FP-candidate mutations at 49
and 1). Clean reference: 122/122 pass.
Full table in `feedback.md`.

## Agent runs

| Batch | Agent | Verdict | Msgs | Files | LOC | Failed tests | Approach note |
|-------|-------|---------|------|-------|-----|--------------|---------------|
| 1 | Orion (eval Nova) | FAIL_TEST_MISMATCH (env bug, `agentBlameUnfair`) | 163 | 3 | 1133 | `test_repetition_of_a_possibly_empty_expression_terminates` (1 of 116) | full three-API implementation, baseline 2025 pass; failed only on the verifier's zero-width-repetition special case, since fixed in the reference |

| 2 | Nova (eval Nova) | PASS_LEGITIMATE | - | 3 | 589 (source) | none (123/123) | deferred-finalization design: `_enumerate_impl` yields `(end, evaluate_thunk)` candidates, ordering pass gated by a class-level `_enumeration_structural_depth` flag |

Batch 1 is not a difficulty datapoint: the only failure was an environment bug, and a single Orion run
reads far above the standard mix (AGENT-MIX law).

Batch 2 (Nova, PASS) was FP-audited locally and is a **genuine pass** - see `feedback.md` for the
differential evidence. Two solvers have now produced correct implementations, so the live risk is the
too-easy band, not correctness. Re-batch Nova-heavy to get a rate.
