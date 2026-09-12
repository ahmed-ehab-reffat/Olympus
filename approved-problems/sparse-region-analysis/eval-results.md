# eval-results — sparse-region-analysis

No agent batch has been run yet. This file records the local validation that stands in for it
until the platform runs Nova/Orion/Vega.

## Local gates

| Gate | Result |
| --- | --- |
| Vanilla repo suite, offline, in the image | 6090 passed / 14 skipped, 0 failed, ~90s with `-n 4` |
| Repo suite with solution applied | 6090 passed, 0 failed, unchanged |
| New tests on base (test.patch only) | 263 failed, 0 passed (`AttributeError: module 'sparse' has no attribute 'regions'`) |
| New tests with solution | 263 passed |
| Patch order solution then test | applies clean, 263 passed |
| Patch order test then solution | applies clean, 263 passed |
| Differential fuzz vs dense oracle | 0 mismatches over 9 shapes x every connectivity x every wrap combination x 12 densities x 13 routines |
| Mutation battery | 24 probes, 23 killed; the 1 survivor proven behaviour preserving by a differential sweep of 29014 cases with byte identical output |
| False positive check | independent description-only implementation passes 259/259 non-scale tests |
| Flakiness, base mode | 3 runs in the image, byte identical: 6090 passed / 14 skipped / 66 xfailed / 11 xpassed |
| Flakiness, new mode | identical 263 passed every run |

## Per-agent table

| Agent | Evaluator | Verdict | Messages | Files | LOC | Failed tests | Approach note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| (pending) | | | | | | | |

## Note on the base mode exclusion

`test_reductions_float16` (in `test_coo.py` and `test_compressed.py`) is marked xfail by the
repo and draws unseeded random data, so it flips between xfail and xpass from run to run. It
never fails, so the suite is green either way, but the counts moved (95/62, 97/60, 94/63 over
three runs). `test.sh` deselects that one family in base mode, with the reason written next to
the command, and the report is then identical across runs. Nothing else in the suite moves.


## Batch 1 — Nova x5 (platform)

| Run | Baseline | New tests | Verdict | Note |
| --- | --- | --- | --- | --- |
| Nova 1 | pass | pass | PASS | legitimate implementation, `sparse/regions/__init__.py` |
| Nova 2 | pass | pass | PASS | legitimate, single `sparse/regions.py` |
| Nova 3 | pass | pass | PASS | legitimate, single `sparse/regions.py` |
| Nova 4 | pass | 62 failed | FAIL_TEST_MISMATCH | returned SPARSE summary arrays |
| Nova 5 | pass | 62 failed | FAIL_TEST_MISMATCH | returned SPARSE summary arrays |

**3/5 = 60% pass, over the 40% cap, and both failures were unfair.** Both evaluators recorded
`description_clear: False` and `was_mentioned_in_description: False`. The failing assertion is
`RuntimeError: Cannot convert a sparse array to dense automatically`, raised from
`assert_array_equal` on `region_counts` and every other summary.

Root cause: the description said "returned arrays are sparse and shaped alike", which reads as
a rule about EVERY return. It was meant for the results shaped like the input. The per-region
summaries are numpy arrays, and nothing said so.

Fixes applied for batch 2:

1. **Fairness.** The output contract is split: "Results shaped like the input are sparse; the
   per-region summaries are numpy arrays."
2. **Difficulty.** `merge_within` added, plus a stated cell-count scale. See feedback.md.

Measurements taken from the batch artefacts rather than assumed:

- the three passing solutions run 300k cells through every routine in 10-15s, so a
  cell-count scale test does NOT discriminate; that lever was measured and dropped.
- replaying all three against the new suite: 18 failures each, all in `merge_within`.
