# eval-results.md - tantivy-pipeline-aggregations

Per-agent results, one row per platform eval run. Updated after every batch.

## APPROVED by human reviewer (2026-06-26). Final batch: 11 runs, 1/10 fair PASS = ~10%.

Fingerprint at approval: sol=b097964a test=c95010ed meta=a567a59e docker=dd5e4b58 (the 59-test,
cargo-install-nextest build). Platform anchors: baseline 237 / new 59.

| # | Solver | Verdict | New | Msgs | Files | LOC | Failed (dominant) |
|---|--------|---------|-----|------|-------|-----|-------------------|
| 1 | Nova | FAIL_MISSED_REQUIREMENT | 58/59 | 126 | 7 | 1211 | per_bucket_under_metric_parent |
| 2 | Nova | FAIL_MISSED_REQUIREMENT | 52/59 | 139 | 6 | 1241 | {value:null} gaps + metric-parent |
| 3 | Nova | FAIL_MISSED_REQUIREMENT | 55/59 | 136 | 5 | 1115 | derivative-gap + metric-parent |
| 4 | Nova | FAIL_MISSED_REQUIREMENT | 56/59 | 110 | 6 | 1144 | derivative-gap-as-unknown-agg |
| 5 | Nova | FAIL_MISSED_REQUIREMENT | 54/59 | 158 | 6 | 1341 | derivative-gap + {value:null} + metric-parent |
| 6 | Nova | FAIL_MISSED_REQUIREMENT | 55/59 | 83  | 6 | 803  | derivative-gap + metric-parent |
| 7 | Nova | FAIL_MISSED_REQUIREMENT | 47/59 | 92  | 81 | 1807 | gaps + empty_from_req panic + metric-parent |
| 8 | Nova | FAIL_API_FAILURE (UNFAIR) | n/a | 122 | 6 | 1207 | Orion stream disconnect mid-validate (agent_blame_unfair=true) |
| 9 | Nova | PASS_LEGITIMATE | 59/59 | 119 | 7 | 996 | - |
| 10 | Nova | FAIL_MISSED_REQUIREMENT | 56/59 | 130 | 6 | 942 | bool short-circuit parse + metric-parent |
| 11 | Nova | FAIL_MISSED_REQUIREMENT | 18/59 | 92  | 59 | 1617 | finalization wiring + empty_from_req panic |

RESULT: 1 PASS / 10 FAIR runs = 10% (Run 8 excluded: agent_blame_unfair=true, blocker_detected=true,
an Orion API stream disconnect mid-validation -- zero difficulty signal). Solvability MET (1 >= 1).
Pass-rate in band (10%, <= ~2-3). All 9 fair fails are FAIL_MISSED_REQUIREMENT with description_clear=
true + tests_deterministic=true (no unfair/test-mismatch fails). Solver long-horizon medians (over the
single PASS, Run 9): messages 119 (>100), files 7 (>=3), LOC 996 (~400+) -- all cleared. The hardened
orthogonal edges did the work: 9/9 fair fails missed at least one of {metric-parent validation,
derivative-gap-treated-as-gap, {value:null}-omission} -- distinct mechanisms, scattered across agents
(the 0%-trap was avoided; each agent missed a different combination). Calibration landed dead-center.

## Platform eval Batch 2 (6 Nova runs) - 2026-06-21 - 5/6 PASS (too easy) -> hardened

Fingerprint at batch time: sol=7798c76c test=bd03508a meta=e5cc6618 (the 49-test de-trapped build).

| # | Solver | Eval | Verdict | Msgs | Files | LOC | Note |
|---|--------|------|---------|------|-------|-----|------|
| 1 | Nova | Nova  | PASS_LEGITIMATE        | 162 | 6 | 1155 | - |
| 2 | Nova | Nova  | PASS_LEGITIMATE        | 173 | 6 | 1237 | - |
| 3 | Nova | Orion | FAIL_MISSED_REQUIREMENT | 138 | 7 | 1256 | bucket_script_skips_gap_bucket ({value:0.0} not null) |
| 4 | Nova | Orion | PASS_LEGITIMATE        | 140 | 6 | 1061 | - |
| 5 | Nova | Orion | PASS_LEGITIMATE        | 163 | 6 | 1129 | - |
| 6 | Nova | -     | PASS (per user; not in file) | - | - | - | - |

RESULT: 5/6 = 83% PASS. Solvability MET (5 >= 1). Long-horizon SOLVER medians all MET: messages
~162 (>100), files 6 (>=3), LOC ~1142 (~400+). The ONLY failing gate is pass-rate (too easy). The
de-trapped moving_avg is now solved by all; only 1 agent slipped (bucket_script gap-skip). The 5
solvers built correct GENERAL engines, so fair-consistent behaviors don't differentiate them ->
hardening must add edges across DISTINCT mechanisms + chain-gap/empty-reduction cases a general impl
can still get wrong.

## Revision 3: harden 83% -> ~20-25% (user-chosen safer target) (2026-06-21)

Added 6 diverse compounding edges (solution.patch BYTE-UNCHANGED -- all handled by the existing engine;
+2 meta clauses, tested both ways):
- bucket_script_over_derivative_gap: a derivative's first-bucket gap propagates -> the script skips
  that bucket (chain-gap-propagation). meta: "a value another pipeline left missing is itself a gap".
- sibling_avg_bucket_over_derivative_gap: avg_bucket over a per-bucket pipeline whose first bucket is a
  gap -> the reduction skips it (=21, not (0+21)/2).
- cumulative_sum_over_derivative_gap: cumsum (ignores gap_policy, treats gap as 0) over a derivative ->
  [0, 21].
- moving_avg_window_three_skip_interior_gap: positional window=3 over [4,null,25] -> [4,4,14.5].
- bucket_selector_removing_all_then_sibling_empty: selector removes every bucket -> sibling reduces an
  empty set -> sum_bucket {value:0}, avg_bucket null. meta: "reducing an empty set yields zero for sum
  and null for the others".
- three_level_dependency_chain: cumsum -> bucket_script(cumsum) -> bucket_script(that) -> [9,59].
49 -> 55 tests; meta 372 -> 398 words; eff LOC 687; solution.patch sol=7798c76c (unchanged). Estimate
~20-40% (calibration ESTIMATE; re-probe to confirm/nudge -- the feature is easy for complete-engine
agents, so it may land high and need one more nudge).

## Platform eval Batch 1 (6 solver runs) - 2026-06-21 - 0/6 PASS

Fingerprint at batch time: sol=3278e9e3 test=e44494c4 meta=6512961f (the 46-test "buffer" build).

| # | Solver | Eval | Verdict | Score | Msgs | Files | LOC | Failed test(s) |
|---|--------|------|---------|-------|------|-------|-----|----------------|
| 1 | Orion | Orion | FAIL_MISSED_REQUIREMENT | 45/46 | 242 | 5 | 1415 | moving_avg_skip_window_over_gap |
| 2 | Orion | Orion | FAIL_MISSED_REQUIREMENT | 45/46 | 176 | 6 | 1580 | moving_avg_skip_window_over_gap |
| 3 | Nova  | Orion | FAIL_MISSED_REQUIREMENT | 45/46 | 148 | 7 | 1116 | moving_avg_skip_window_over_gap |
| 4 | Nova  | Orion | FAIL_REGRESSION         | base broke | 150 | 6 | 1119 | 22 baseline (over-eager pipeline validation on filter/keyed) + moving_avg |
| 5 | Nova  | Orion | FAIL_MISSED_REQUIREMENT | 44/46 | 106 | 6 | 1064 | moving_avg + serial_on_keyed_parent_errors |
| 6 | Nova  | Orion | FAIL_MISSED_REQUIREMENT | 45/46 | 132 | 7 | 1242 | moving_avg_skip_window_over_gap |

ALL FAIR: every run description_clear=true, tests_deterministic=true, agent_blame_unfair=false,
blocker_detected=false; zero unfair/compile/integration fails (the serde + 4-cell mechanics are sound).

DIAGNOSIS: a single DETERMINISTIC UNIVERSAL MISS on `moving_avg_skip_window_over_gap` (all 6) sitting on
an otherwise too-easy problem. 5/6 scored 45/46 (one edge from solving). Stripping moving_avg, ~4/6
would solve (only the regression run 4 and the keyed-error run 5 fail) => the feature is ~67% underneath
= a 0%-trap layered over a too-easy base. moving_avg's meta was 3-way ambiguous ("most recent window
VALUES" + "skip excludes a missing value"): agents split across (A) gap bucket emits nothing [5 agents],
(B) window over non-gap values [1 agent]; the intended model is a positional window with gaps excluded
from the average and the gap bucket still emitting. Per the difficulty-calibration rule (universal miss
= de-trap; then harden), and solvability being absolute, this REQUIRED a revision.

## Revision: de-trap moving_avg + scattered hardening (2026-06-21)

- DE-TRAP moving_avg (meta only): rewrote to "averages, for each bucket, the non-missing values among
  the `window` buckets that end at and include it BY POSITION, so a bucket still receives a value when
  its own value is missing as long as another bucket in that window has one." Kills models A and B;
  converts the universal miss into a still-fiddly scattered edge (off-by-one window, gap-bucket-emits).
- HARDEN (scattered, fair, documented edges the solution already supports):
  * bucket_selector removes buckets BEFORE a sibling pipeline reduces the parent (sibling sees survivors)
    -> new test bucket_selector_removes_before_sibling_reduction.
  * value-producing per-bucket pipelines run, then bucket_selector removes (cumsum reflects ALL buckets,
    then removal) -> new test cumulative_sum_computed_before_bucket_selector_removal. This also FIXES a
    latent non-determinism: independent per-bucket pipelines were ordered by hash-map iteration; the
    solution now stable-sorts bucket_selector last (compute.rs order_per_bucket). [solution change]
  * _count is never a gap (empty bucket = 0, a real value) vs a metric gap (null) -> new test
    derivative_over_count_gap_histogram.
  * kept the keyed-parent error (run 5 differentiator) + the inherent regression guard (run 4 broke the
    base suite by over-applying pipeline validation -> caught by `test.sh base`).
- 46 -> 49 F2P tests; solution.patch changed (determinism fix); meta 311 -> 372 words (API-heavy band).
- Estimated effect: ~67% -> ~10-20% (a calibration ESTIMATE; the next probe confirms/nudges).

## Local validation of the reviewer-feedback (59-test, nextest) build

Dev container (mounted source, cached deps): `cargo nextest run -p tantivy --test
agg_postfinalize_pipeline_checks` -> 59 passed / 0 failed on the solution; `cargo check -p tantivy --lib`
clean. Effective LOC 714 across 8 files. test.sh now uses cargo-nextest (native JUnit).

Authoritative non-root + offline 4-cell from fresh `git archive BASE` contexts (`--network none
--user 1000:1000`), images tantivy-v6-base / tantivy-v6-sol. BUILD-CHECK FIX: the platform build check
BLOCKED the prior curl-based nextest install as not-rebuild-safe; nextest is now installed via the
cargo package manager version-locked (`cargo install cargo-nextest --version 0.9.138 --locked --root
/usr/local`) -- no raw fetch; it resolves offline at run time (/usr/local/bin/cargo-nextest confirmed):

| Cell | State | Mode | Expected | Result |
|------|-------|------|----------|--------|
| 1 | base (test.patch only) | `test.sh base` | PASS (P2P regression) | PASS - 237 passed, 0 failed |
| 2 | base (test.patch only) | `test.sh new`  | FAIL (feature absent) | FAIL - 0 passed, 59 failed |
| 3 | solution (test+solution) | `test.sh base` | PASS (no regressions) | PASS - 237 passed, 0 failed |
| 4 | solution (test+solution) | `test.sh new`  | PASS (feature works)  | PASS - 59 passed, 0 failed |

F2P node-ids IDENTICAL across base/new and sol/new (59 nodes via nextest JUnit) -> non-empty +
complete. NOTE: test.sh passes `--no-fail-fast` so the base run records all 59 failing tests (nextest
defaults to fail-fast, which would cancel after the first failures and emit a partial JUnit). Verified
2026-06-21 (images tantivy-v6-base / tantivy-v6-sol, --network none --user 1000:1000).

Platform JUnit anchors to expect: baseline (P2P) 237 / new (F2P) 59.

Fingerprint: sol=b097964ad77c9b44a6553ae0dce6a16283bc44ae test=c95010edad9e02c77e4472c64ee820872adfc907 meta=a567a59efca61f0860e0fa41726fe0db707d3bf4 docker=dd5e4b580b5e1ddfe567fbd2566cc9f62860eed4 base=4be142923c2691bc74b506e9f4074fb36f2ed10c
Build: files=8 meta_words=432 | platform baseline=237 new=59 | 2026-06-21 (human-reviewer refinements applied)

Solver-median targets (read off PASSED runs only): messages > 100, files >= 3, LOC ~ 400+.
Pass-rate target ~10% (>= 1 solver, <= ~2-3 of 10). Batch-1 near-miss msgs were 106-242 -> solver-median
will clear >100 once solvable.
