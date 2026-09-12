# feedback — taffy last-baseline alignment

## Summary
Minimal derivative probe for `AlignItems::LAST_BASELINE` (last-baseline flex alignment) in
DioxusLabs/taffy. Flexbox-only slice (~52 eff LOC), fully validated locally. Built to run the
platform derivative check before committing to the full (grid + baseline-groups) build.

## Pick provenance (pivot trail)
1. scriggo range-iterators -> DERIVATIVE (prior author owns scriggo's Go-language space).
2. taffy visibility:collapse -> cleared derivative but TOO EASY (naive ~120-line solution is
   spec-correct; fails the >=250 passing-LOC floor). Quarantined to rejected/.
3. taffy last-baseline -> genuinely hard (naive reuse of first-baseline is observably wrong),
   irreducible breadth, cold/exclusive. Current pick.

## Attempt history
| # | Date | Stage | Result |
|---|---|---|---|
| 0 | 2026-07-21 | Flexbox probe built + locally validated | Ready for derivative check |

## Open decisions
- Awaiting platform derivative verdict.
- If NON-derivative: harden to full Olympus (grid last-baseline + separate first/last baseline
  groups, DESIGN sec 9) to clear >=250 eff LOC, then Vega/Orion batch targeting <=40% pass.
- If DERIVATIVE: quarantine + pick a different taffy cold gap (block auto-margins is a smaller
  backup) or another shortlist repo.

## Local validation (see eval-results.md)
Local cargo 1.97.1 (Docker avoided per user disk constraints). Patches apply both orders + -R;
base passes (4573 tests, no regressions); new fails-on-base (compile-error fallback) and passes
with solution (5 tests); deterministic 3x/3x. Docker image build NOT run (disk); Dockerfile is
the canonical Rust cargo2junit pattern.

## Key learnings
- Empirically verifying difficulty BEFORE committing caught visibility:collapse as too-easy
  (naive approach spec-correct). Applied the same check here: confirmed last-baseline's naive
  approach is observably WRONG (ordering does not flip) -> real difficulty.
- Baselines are not on the public `Layout`; last-baseline is observable only via item positions,
  and only through a nested wrap container (leaf first==last). The golden tree makes it testable.
- Adding `AlignItemsKeyword::LastBaseline` breaks ~6 exhaustive matches + 3 LayoutOutput literals;
  the compiler enumerates them. `last_baselines` defaults to NONE in the constructor, so only the
  flex return site needs to set it (minimal ripple, no existing-test breakage this time).
- `--cfg taffy_probe_lb` gate keeps base mode compiling the new test file to empty on the base
  commit; new mode activates it -> clean fail-on-base via compile error.
