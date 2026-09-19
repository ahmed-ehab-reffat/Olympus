# eval-results.md - featurevisor-minimal-rebucketing

## Batch 1 (2026-09-18) — 11 runs (8 Nova, 1 Orion, 2 Vega) — 2/11 exact pass (18%)

Graded against the R3 test.patch (31 new tests). "Replay" = the same saved patch re-graded locally
against the R4 test.patch (34 new tests) in `fv-slice:base` (`worktrees/_tools/fvreplay.sh`).

| Run | Graded (R3) | Replay (R4) | Failed tests (R3) | Why |
|---|---|---|---|---|
| Orion_Nova | **31/31 PASS** | **34/34** | — | — |
| Vega_Nova_1 | **31/31 PASS** | **34/34** | — | — |
| Nova_Nova_1 | 30/31 | 33/34 | `__proto__` | `{}` record swallows the key |
| Nova_Nova_5 | 30/31 | 33/34 | `__proto__` | same |
| Nova_Nova_6 | 30/31 | 33/34 | `__proto__` | same |
| Nova_Nova_7 | 30/31 | 33/34 | `__proto__` | same |
| Nova_Nova_2 | 29/31 | 33/34 | `__proto__`, formatter | per-change formatter signature (representation, now accepted) |
| Nova_Nova_4 | 28/31 | 33/34 | `__proto__`, print, formatter | newline-joined formatter string (representation, now accepted) |
| Nova_Nova_3 | 27/31 | 31/34 | removed-variations refill, grouped slots, `__proto__`, formatter | reused `getUpdatedAvailableRangesAfterFilling`, drops later free ranges |
| Nova_Nova_8 | 27/31 | 32/34 | removed-variations refill, grouped slots, print, formatter | same multi-range drop |
| Vega_Nova_2 | 28/31 | 32/34 | removed-variations refill, grouped slots, formatter | same multi-range drop |

Kill counts, R4 replay: `__proto__` 7 (sole failure in 6), multi-range free-space drop 3. Formatter
and print representation failures: 7 at R3, **0 at R4** (Auto Review T5 fix).
All 11 runs passed the 1050-test base suite.

## Batch 2 (2026-09-19) — re-eval of batch 1 against the R4 test.patch — 2/11, ACCEPTED

Same 11 solutions (patch hashes identical; the two Vega labels swapped between folders).

| Run | New | Failed tests |
|---|---|---|
| Orion_Nova | **34/34 PASS** | — |
| Vega_Nova_2 (batch-1 Vega_1) | **34/34 PASS** | — |
| Nova_Nova_1, 2, 4, 5, 6, 7 | 33/34 | `__proto__` |
| Nova_Nova_3 | 31/34 | removed-variations refill, grouped slots, `__proto__` |
| Nova_Nova_8 | 32/34 | removed-variations refill, grouped slots |
| Vega_Nova_1 (batch-1 Vega_2) | 32/34 | removed-variations refill, grouped slots |

All 11 passed the 1050-test base suite. Prompt tokens per run 2.9M to 9.1M (Orion highest).

