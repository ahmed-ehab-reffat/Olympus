# techan-costbasis - eval results

## Oracle / local validation (dev container: public.ecr.aws/d3j8x8q7/olympus-base-go)

| Check | Result |
| ----- | ------ |
| Shipped FIFO vs INDEPENDENT naive FIFO (20k random sequences) | 0 mismatches (exact) |
| FIFO/LIFO/HIFO/LOFO agree on gross realized when flat (20k) | 0 mismatches (exact, method-independent) |
| RealizedPnL == GrossRealizedPnL - Commissions (20k) | 0 failures |
| Split(2) preserves CostBasis (5k) | 0 failures |
| Average / wash-sale / DRIP (exact-input unit tests) | pass |
| Reference solution vs test.patch (59 tests) | 59/59 pass |
| Vanilla env-quality (`go test ./...` unpatched) | clean |

Note: techan's big.Decimal is float64-backed (division lossy: (52/5)*5 < 52). Division-free core is exact; division features are fair by specification (exact formula/order pinned in meta) and tested with clean inputs.

## Validation matrix (Docker, --network none, --user 1000:1000)

| State | test.sh base | test.sh new |
| ----- | ------------ | ----------- |
| BASE + test.patch | PASS (exit 0, 217 testcases) | FAIL (exit 1, 59 synth) |
| BASE + test.patch + solution.patch | PASS (exit 0, 217 testcases) | PASS (exit 0, 59) |

F2P: 59 identical (classname, name) node ids across base-fail / solution-pass (XML-parser verified). P2P: 217 existing techan tests run in base mode both states (costbasis excluded from base to avoid the tag-only build-constraint error).

## Effective LOC

human-effective 448 (>= 430 floor with margin), raw 767, 10 files. Note: padding-floor 65 (the statistics/portfolio getters amortize); the distinct-logic core (matching + flip/short/wash/corporate/average/specific) carries the count.

## Difficulty calibration

Engineering-surface core (stateful, order-dependent) - not a trained named algorithm. ~15 documented exact surfaces compound. Full standalone naive-agent benchmark not rebuilt due to session budget (3rd feature after 2 derivative rejects); calibration argued from surface count + order-dependence. Solvability floor met (reference passes all 59).

## Platform empirical runs (Nova/Orion/Vega)

Test count now 93. F2P: 93 fail on base, 93 pass with solution.

### Confirmed dominant killer: TestWashSaleMultipleLosses
Most Nova failed this one test. Trap = N-fold wash accumulation: one replacement buy must consume TWO prior losses (most-recent-first, up to the 10-share qty), disallow 150, and blend UNIFORMLY into one lot at 40+150/10=55. Agents implement the single-loss case (simpler wash tests pass) and miss the loop + running total + uniform blend. Recorded in HARDENING.md A13 + law index (N-FOLD-ACCUMULATION). Fair: fully derivable from the documented rule; keep it.

### Batch #1 - 6x Nova (33% pass, but 2 fails were unfair -> round-15 fairness fix + 2 real traps)
All 6 preserved 217 baseline. Failures were ALL wash-sale (partial-then-later + TaxSummary gross basis) - the fake/ambiguous difficulty removed in round 15.

| # | Verdict | Msgs | LOC | Failed tests | Failure reason |
| - | ------- | ---- | --- | ------------ | -------------- |
| 1 | FAIL_AMBIGUOUS_TASK | 57 | 905 | WashSalePartialThenLater, WashSaleTaxSummary | "each loss washed once" read event-level; TaxSummary gross unstated (unfair) |
| 2 | PASS_LEGITIMATE | 40 | 919 | - | - |
| 3 | FAIL_AMBIGUOUS_TASK | 45 | 857 | WashSalePartialThenLater, WashSaleTaxSummary | same ambiguity (unfair) |
| 4 | PASS_LEGITIMATE | 49 | 856 | - | - |
| 5 | FAIL_WRONG_LOGIC | 42 | 871 | WashSaleTaxSummary | reduced original close's CostBasisClosed (500 vs 600) |
| 6 | FAIL_MISSED_REQUIREMENT | 36 | 936 | WashSaleTaxSummary | same TaxSummary gross-basis miss |

Post-round-15: ambiguity documented (2 traps become fair); difficulty carried by 2 new documented interdependent+misdirecting traps (WashSaleAdjustsMethodSelection, WashOnlyOnLongOpen). Re-run batch to re-measure. If >40% pass, add another documented wash x corporate trap; if a new unfair/ambiguous flag appears, reword.
