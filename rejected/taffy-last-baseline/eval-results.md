# eval-results — taffy last-baseline alignment

## Platform evals
None yet. Pending derivative check + (after hardening) Vega/Orion batch.

## Local validation (local cargo 1.97.1, taffy @ bb351fcc, 2026-07-21)

Docker avoided per user disk constraints; test.sh run locally (cargo2junit 0.1.15 installed).

| Check | Result |
|---|---|
| Baseline build (`cargo build`) | OK |
| Full existing suite + solution (`cargo test --lib --tests`) | 4421 + 105 + 43 pass, 0 fail (4 pre-existing ignored) |
| Golden discrimination test | first-baseline A.y=0/B.y=10 vs last-baseline A.y=10/B.y=0 (ordering flips) |
| Patches apply (test->solution) | OK |
| Patches apply (solution->test) | OK |
| Patches reverse (-R) | clean |
| BASE mode, base commit | exit 0 (PASS) |
| NEW mode, base commit (fail-on-base) | exit 101, 1 testcase / 1 failure (compile-error fallback) |
| BASE mode + solution | exit 0, 4573 testcases, 0 failures |
| NEW mode + solution | exit 0, 5 testcases, 0 failures |
| Flakiness new x3 | exit 0,0,0 |
| Flakiness base x3 | exit 0,0,0 |
| Docker image build | NOT RUN (disk) |

## New tests (5, black-box via public TaffyTree API, assert item positions)
- last_baseline_differs_from_first_for_wrapped_child (golden: ordering flips)
- first_baseline_aligns_on_first_line (B below A under baseline)
- last_baseline_aligns_on_last_line (A below B under last-baseline)
- leaves_agree_between_first_and_last_baseline (single-line: modes identical)
- single_participant_line_is_unchanged (<2 participants: no-op)

## Effective LOC
solution.patch approx-eff = 52 (added 58 - blank 1 - comment 5), flexbox-only.
Below the 250 long-horizon floor by design (probe). Grid + baseline-groups hardening
(DESIGN sec 9) lifts it >=250 for the committed Olympus submission.

## Notes
Difficulty is genuine (naive reuse of first-baseline gives no ordering flip = wrong), but this
batch validates plumbing + fail-on-base + determinism only. Pass-rate/difficulty is assessable
only after the full build + a real agent batch.
