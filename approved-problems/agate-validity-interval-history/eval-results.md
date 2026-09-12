# eval-results — agate-validity-interval-history

## Batch 1 (6 runs, meta.md before the round-8 fix)

0 of 6 passed. Every run cleared the 396 baseline tests and no run was flagged for ambiguity: all
six evaluators returned `description_clear: true`, `tests_deterministic: true`,
`difficulty: challenging`.

| agent | verdict | new failed / 249 | failing classes | root causes |
|---|---|---|---|---|
| Nova_Nova_1 | fail | 15 | TestCoverage 14, TestIntervalValueValidation 1 | `Coverage()` defaults only |
| Vega_Nova | fail | 15 | TestCoverage 14, TestIntervalValueValidation 1 | `Coverage()` defaults only |
| Nova_Nova_5 | fail | 8 | TestJoinHistory 7, TestToHistory 1 | outer-join order, duplicate instant, KeyError not ValueError |
| Nova_Nova_2 | fail | 21 | TestCoverage 14, TestJoinHistory 5, TestToHistory 1, TestIntervalValueValidation 1 | `Coverage()` defaults, outer-join order, duplicate instant |
| Nova_Nova_4 | fail | 22 | TestCoverage 14, TestJoinHistory 6, TestToHistory 1, TestIntervalValueValidation 1 | `Coverage()` defaults, outer-join order, missing DataTypeError import |
| Nova_Nova_3 | fail | 24 | TestCoverage 14, TestJoinHistory 6, TestCoalesceHistory 1, TestSplitHistory 1, TestClipHistory 1, TestIntervalValueValidation 1 | `Coverage()` defaults, outer-join order, source column order |

Two causes dominate and both were description defects, not difficulty.

1. **`Coverage()` had no default column names in 5 of 6 runs**, costing 15 tests each at
   construction with `TypeError`, before any interval logic ran. meta.md stated the defaults in the
   shared-conventions paragraph but then wrote the aggregation as
   `Coverage(start_column_name, end_column_name)`, which reads as two required arguments.
2. **`inner=False` remainder ordering was wrong in 5 of 6 runs**, costing 5 to 7 tests each. Every
   one sorted the whole result by interval start. The sentence said the leftovers "follow the rows
   it paired with, in time order", which reads as a rule about the whole output.

### Replay after the fix

Both Coverage-only patches were replayed on the base commit against the unchanged test suite with
a single edit: default arguments added to their own `Coverage.__init__`. Nothing else in either
agent's code was touched.

| agent | new tests |
|---|---|
| Nova_Nova_1 + Coverage defaults | 249 passed |
| Vega_Nova + Coverage defaults | 249 passed |

Projected rate after the round-8 meta fix: **2 of 6, 33 percent**. Solvable, under the 40 percent
ceiling, and the surviving discriminators still separate the field: the `to_history`
duplicate-instant rule (3 runs), source column order for the in-place transforms (1 run), and
`ValueError` rather than `KeyError` on a missing right-hand column (1 run).

## Batch 2 (10 runs, meta.md after the round-8 fix)

3 of 10 passed, 30 percent, inside the 40 percent ceiling. All ten cleared the 396 baseline tests
and every failure sat inside the feature. Five runs reached 236 to 238 of 239. Reviewer reading:
difficulty, not unfairness. Recurring misses were flatten precedence reversed (2 runs), overlap
ordering and join validation, duplicate-instant precedence, open-ended split tails, and one run
returning raw list rows from `_fork`.

## Local runs

| run | mode | result | notes |
|---|---|---|---|
| base commit + test.patch, container, uid 1000, no network | new | 249 failed / 249 | every JUnit node fails individually |
| base commit + both patches (test first), container | new | 249 passed | |
| base commit + both patches (test first), container | base | 396 passed | |
| base commit + both patches (solution first), container | new | 249 passed, 3 runs identical | |
| base commit + both patches (solution first), container | base | 396 passed, 3 runs identical | |
| vanilla repo, container | base | 396 passed | Environment Quality proxy |
| local venv | full tree | 643 passed | 249 new plus 394 existing |

## Mutation battery

48 mutations of the reference, 48 killed, 0 survivors. One mutation per stated rule.

| area | mutations | survivors |
|---|---|---|
| history kernel (open ends, subtraction, overlap, grouping, validation) | 10 | 0 |
| to_history (dedupe, collapse, close on null, ordering) | 5 | 0 |
| coalesce_history | 2 | 0 |
| flatten_history | 2 | 0 |
| history_at | 2 | 0 |
| join_history including inner=False | 9 | 0 |
| history_gaps / history_overlaps | 3 | 0 |
| history_spans | 2 | 0 |
| split_history / clip_history | 4 | 0 |
| history_events | 2 | 0 |
| Coverage | 2 | 0 |

Two mutations initially survived and both were artifact bugs, not test gaps: a dead `later_end`
helper (removed) and unsorted `history_overlaps` output (sorted, plus a four-interval test).
