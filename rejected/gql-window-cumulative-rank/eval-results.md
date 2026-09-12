# eval-results.md — gql-window-cumulative-rank

## Batch 1 (Nova x4, pre-harden, 14-test suite)

4/4 pass (100%) — over the 40% ceiling, too easy. Triggered `olympus-harden` (see `feedback.md`
Round 2).

| Agent | Verdict | Baseline | New tests | Approach note |
|---|---|---|---|---|
| Nova_1 | PASS | green | 14/14 | position-based tie run in `engine_window_functions.rs` only |
| Nova_2 | PASS | green | 14/14 | also touched `engine_ordering.rs` (independent NULL-key tweak) |
| Nova_3 | PASS | green | 14/14 | position-based tie run, `dense: bool` shared helper |
| Nova_4 | PASS | green | 14/14 | also touched `engine_ordering.rs`, `dense: bool` shared helper |

All 4 independently implemented multi-key tie comparison correctly (`left.len()==right.len() &&
zip().all(equals)`) despite it being untested at the time — the natural implementation compares
the whole key vector, not just the first key. Confirms this specific axis is not a discriminator
for competent agents (see harden round below).

## Round 2 differential harness (hardened 19-test suite vs the 4 real Batch-1 patches)

Applied each Batch-1 agent's actual `solution-patch.patch` on a fresh BASE_COMMIT checkout and ran
the hardened `test.sh new`. Real-patch evidence, not mutation:

| Agent | Result against 19-test hardened suite |
|---|---|
| Nova_1 | 19/19 pass |
| Nova_2 | 19/19 pass |
| Nova_3 | 19/19 pass |
| Nova_4 | 19/19 pass |

The 5 new tests (multi-expression ORDER BY ties, DESC ordering, partitioned cumulative aggregate,
RANK/DENSE_RANK argument-arity rejection) close real fairness/coverage gaps but move the measured
pass rate 0 points — confirmed by real-patch replay, not predicted. See `feedback.md` Round 2 for
the full diagnosis and the recommended next lever.

## Local validation record (not a platform agent run)

| Check | Result |
|---|---|
| `cargo build --workspace` (solution applied) | clean, 0 errors |
| `cargo test --workspace` (solution applied) | 14/14 new tests pass, 0 regressions in existing 14 unit tests (9 cli + 5 parser) |
| New tests on base (no solution) | 10/14 fail for the right reason (missing behavior / missing function), 4/14 correctly pass (regression guards for unchanged no-ORDER-BY behavior) |
| Base tests on base (no solution) | 14/14 pass, 0 regressions |
| Flakiness: new tests x5 | identical result every run |
| Flakiness: full workspace x3 (base) | identical result every run |
| Mutation: remove ORDER BY validation | breaks exactly `rank_requires_order_by_clause` + `dense_rank_requires_order_by_clause`, nothing else |
| Mutation: collapse DENSE_RANK onto RANK | breaks exactly `dense_rank_does_not_skip_after_a_tie_group`, nothing else |
| Fresh-clone end-to-end (patches apply -> build -> test.sh base -> test.sh new) | clean, exit 0 / exit 0, 14/14 |
| Patch encoding | both `solution.patch` and `test.patch` are ASCII text |
| test.sh executable bit | `new file mode 100755` confirmed in test.patch |
| Comment convention audit | `///` on public `gitql-core` API only; `//` sparse in `gitql-engine`; zero comments in `gitql-std` (matches each crate's own baseline) |

## Round 3 (PERCENT_RANK/CUME_DIST, local trap-proof only — no fresh batch yet)

| Check | Result |
|---|---|
| Reference solution, 23-test suite, 3x | 23/23 pass, identical every run |
| `test.sh base` before and after solution | 14/14 pass, 0 regressions, both times |
| `test.sh new` with no solution.patch | 23/23 fail |
| Trap-proof: `use_cumulative_frame = has_ordering` (drop the whole-partition exception) | catches via `percent_rank_and_cume_dist_use_partition_size` only (`["0","1","0.5","1"]` vs `["0","0.333...","0.333...","1"]`); the other 3 new PERCENT_RANK/CUME_DIST tests are symmetric/trivial cases that coincide under both dispatch paths and do not catch it |
| `human-effective` LOC | 197 (Round 2) -> 257 (Round 3) |
| meta.md word count | 223 (Round 2) -> 304 (Round 3), still under the 500 hard cap |

**Not yet done:** a fresh Nova/Orion/Vega batch against this Round-3 artifact. Everything above is
local trap-proof + differential-replay evidence (the 4 real Round-1 patches, which never
implemented PERCENT_RANK/CUME_DIST at all, predictably fail exactly those 4 new tests — expected,
not informative about whether a FRESH agent attempting the updated spec gets the dispatch right).
The empirical pass-rate claim is still open until that batch runs.

## Round 4 (Auto Review fixes: named-window resolution order, rustfmt, ROW_NUMBER coverage)

Auto Review on the Round-3 artifact: Description 3/3, Tests 2/3 (Medium T3/T4), Solution 1/3
(High S1 + High S2). No agent-run corpus attached (empty manifest, band 3 by default/low
confidence). All three fixed; see `feedback.md` Round 4 for detail.

| Check | Result |
|---|---|
| `cargo fmt --all -- --check` on the full patched workspace | exit 0 (was failing pre-fix on `count_distinct_groups_before`) |
| Named window with ORDER BY (`RANK() OVER w ... WINDOW w AS (ORDER BY salary)`) | now accepted and computes correctly (was a false parse rejection) |
| Named window without ORDER BY (`DENSE_RANK() OVER w ... WINDOW w AS (PARTITION BY department)`) | still correctly rejected |
| `ROW_NUMBER() OVER ()` full sequence assertion | added, paired with a solution-dependent second query per the valid-usage-first pattern |
| Reference solution, 26-test suite, 3x | 26/26 pass, identical every run |
| `test.sh new` with no solution.patch | 26/26 fail (one test initially false-passed at 25/26 — a trivial "any parse error" check that didn't discriminate DENSE_RANK-unrecognized from DENSE_RANK-missing-ORDER-BY; caught and fixed by the clean-room gate, not by inspection) |
| `test.sh base` before and after solution | 14/14, 0 regressions, both times |
| `human-effective` LOC | 257 (Round 3) -> 273 (Round 4) |

## Materialized batches (agent-runs/1, /2, /3) — against Round-3/4 artifact, pre-Round-5 Docker fix

| Batch | Agents | Result | Notes |
|---|---|---|---|
| 1 | 4x Nova | 4/4 pass | Analyzed in detail in Round 2 (differential harness source) |
| 2 | 2x Nova | 2/2 pass | `is_legitimate: true`, `cheating_detected: false` both |
| 3 | 2x Nova | 2/2 pass | `is_legitimate: true`, `cheating_detected: false`, `difficulty: "challenging"` both; wrapper reports "46 tests, 46 passed" / "42 tests, 42 passed" (workspace-wide count incl. baseline) |

**8/8 total, no failures observed yet.** Pass rate is still at/near 100% against the 40% ceiling.
None of these runs hit the Docker/PATH portability issue fixed in Round 5 (agent solve-time
sandbox apparently tolerates the dead `/root/.cargo/bin` PATH line differently than the platform's
stricter offline non-root client verification did — see `feedback.md` Round 5 for the root cause).

## Round 5 (Auto Review fixes: Docker/PATH portability blocker, PERCENT_RANK/CUME_DIST arg coverage)

| Check | Result |
|---|---|
| Root cause of T6/T1 blocker | `Instructions/DOCKER.md`'s 2026-07-30 correction: `olympus-base-rust` toolchain lives at `/opt/cargo`/`/opt/rustup`, not `/root/.cargo` (which doesn't exist in this image) |
| Dockerfile fix | added `chmod -R a+rwX /opt/cargo /opt/rustup /app` to the `RUN` line, matching DOCKER.md's build-verified working template |
| test.sh fix | removed the dead `export PATH="/root/.cargo/bin:$PATH"` line (image's own `PATH` already correct for every UID) |
| T4 fix | added `percent_rank_and_cume_dist_reject_arguments`, valid-usage-first pattern |
| Reference solution, 27-test suite, 3x | 27/27 pass, identical every run |
| `test.sh new` with no solution.patch | 27/27 fail |
| `test.sh base` before and after solution | 14/14, 0 regressions, both times |
| `cargo fmt --all -- --check` | clean |
| `solution.patch` | unchanged from Round 4 (only `test.patch`/`Dockerfile` touched this round) |
| Not locally verifiable | the actual `--network none --user <uid>` run this fix targets; owed to the platform |

## Batch 4 (agent-runs/4) — 9x Nova against the Round-5 artifact — first run past the Docker fix

Confirms the Round-5 Docker/PATH fix works: all 9 runs completed the harness, no environment
blocker. **7/9 pass (78%)** — still far above the 40% ceiling.

| Agent | Verdict | Baseline | New tests | Failure reason | Approach note |
|---|---|---|---|---|---|
| Nova_1 | PASS | green | 27/27 | — | correct PERCENT_RANK/CUME_DIST, correct named-window order |
| Nova_2 | PASS | green | 27/27 | — | correct PERCENT_RANK/CUME_DIST, correct named-window order |
| Nova_3 | PASS | green | 27/27 | — | correct PERCENT_RANK/CUME_DIST, correct named-window order |
| Nova_4 | PASS | green | 27/27 | — | correct PERCENT_RANK/CUME_DIST, correct named-window order |
| Nova_5 | PASS | green | 27/27 | — | correct PERCENT_RANK/CUME_DIST, correct named-window order |
| Nova_6 | FAIL | green | 25/27 | validates ORDER BY requirement before named-window resolution; rejects a valid named-window RANK/DENSE_RANK call | 2 failed tests, both named-window ORDER-BY-acceptance cases |
| Nova_7 | PASS | green | 27/27 | — | correct PERCENT_RANK/CUME_DIST, correct named-window order |
| Nova_8 | FAIL | green | 24/27 | same named-window early-validation bug as Nova_6, plus broke the pre-existing whole-partition aggregate broadcast (unforced regression) | 3 failed tests |
| Nova_9 | PASS | green | 27/27 | — | correct PERCENT_RANK/CUME_DIST, correct named-window order |

**Reading:** the named-window resolution-order trap (S1, fixed Round 4) is the only confirmed
discriminator, catching 2/9 (about 22%). PERCENT_RANK/CUME_DIST computation is now confirmed fully
convergent across all 5 passing agents checked in detail — same tie-aware `window_rank` reuse,
same `(rank-1)/(n-1)` formula with the n<=1 special case, same tie-grouped `count/n` for CUME_DIST
in every one. See `feedback.md` Round 6 / batch-4 section for full detail.

## Round 6 (coverage hardening: platform-suggested advisory tests, no solution change)

Platform review flagged the problem as too easy (matches the 78% batch-4 read) and listed 3
advisory Coverage Suggestions. Added all 3 as fair, deterministic tests (avoided asserting on the
engine's genuinely non-deterministic cross-window row order, a real `HashMap`-driven flakiness
property unrelated to this feature, documented in Round 1 and rediscovered here).

| Check | Result |
|---|---|
| New tests added | `percent_rank_and_cume_dist_reset_independently_per_partition`, `percent_rank_and_cume_dist_break_ties_with_a_second_order_by_expression`, `multiple_window_definitions_in_one_select_stay_attached_to_their_rows` |
| Float literals | hand-verified via standalone `rustc`: 1/6="0.16666666666666666", 4/6="0.6666666666666666", 1/5="0.2", 3/5="0.6", 4/5="0.8" |
| Test-body comment rule | initially added rationale comments in 2 new tests, removed per CLAUDE.md's zero-comments-in-test-bodies rule (repo convention already established in this file) |
| Reference solution, 30-test suite, 3x | 30/30 pass, identical every run |
| `test.sh new` with no solution.patch | 30/30 fail |
| `test.sh base` before and after solution | 14/14 (gitql-engine + gitql-parser --lib), 0 regressions, both times |
| `cargo fmt --all -- --check` | clean |
| `solution.patch` | unchanged from Round 4/5 — this round only touched `test.patch` |
| Predicted pass-rate impact | none (confirmed via differential check against the reference solution) — these are coverage/fairness closures, not new hardening levers |

**Open:** the 78% pass rate from batch 4 is not addressed by this round's changes and remains the
real blocker to clearing the 40% ceiling. A genuinely new, different-axis trap is needed; none has
been identified from evidence in hand yet. See `feedback.md`'s "Open items before submit".

## Round 7 (fairness fix: CUME_DIST/PERCENT_RANK wording under DESC, no solution change)

Probed the reference solution directly with `ORDER BY salary DESC` (a cross-product cell no prior
test exercised) and found meta.md's CUME_DIST sentence described absolute value comparison
("<=") while the actual (correct, standard-SQL) behavior is scan-order-relative, matching RANK.
The two disagree specifically under DESC. Fixed the wording, not the code.

| Check | Result |
|---|---|
| Probe result (solution applied, `ORDER BY salary DESC`) | `alice(90)->pr=0,cd=0.25`; `dave(60)->pr=1,cd=1` — scan-order-relative, NOT absolute "<=" |
| meta.md fix | reworded CUME_DIST sentence to order-sequence-relative language, added an explicit ASC/DESC-direction sentence tying both formulas to RANK's direction behavior |
| meta.md re-check | 341 words (body), ASCII-only, no unicode punctuation |
| New test | `percent_rank_and_cume_dist_follow_the_order_by_direction`, literals read directly off the probe |
| Reference solution, 31-test suite, 3x | 31/31 pass, identical every run |
| `test.sh new` with no solution.patch | 31/31 fail |
| `cargo fmt --all -- --check` | clean |
| `solution.patch` | unchanged — only `meta.md` and `test.patch` touched this round |

## Per-agent table (populate after first platform batch against the Round-7 artifact)

| Agent | Evaluator | Verdict | Msg count | Files touched | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — | — |
