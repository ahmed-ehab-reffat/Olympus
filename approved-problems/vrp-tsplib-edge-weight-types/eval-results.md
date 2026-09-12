# eval-results.md — vrp-tsplib-edge-weight-types

## Batch 1 — 4x Nova, run against the round-3 artifact (before round-4's fixes)

Pass rate: 3/4 = 75% (**Too Easy**, exceeds the <=50%/<=40% ceiling). Ran BEFORE round 4's fixes
(CEIL_2D/ATT fractional-coordinate bug, the two relaxed error-message tests, the Clippy fix), so
this is not a read on the current artifact. A fresh batch is owed post-round-4.

| Run | Verdict | Workspace diff (lines) | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|
| Nova_Nova_1 | PASS_LEGITIMATE | 1608 | none | — | Full implementation of all 4 types + EXPLICIT layouts; 16/16 baseline, 19/19 new |
| Nova_Nova_2 | PASS_LEGITIMATE | 1633 | none | — | Same scope; trajectory shows transient Cargo file-lock waits from its own concurrent commands (self-inflicted, not an environment issue) |
| Nova_Nova_3 | FAIL_TEST_MISMATCH | 1586 | `cannot_read_explicit_without_edge_weight_format`, `cannot_read_explicit_without_display_data_type` | Correct behavior, different (more flexible) metadata-parsing loop discovers the missing key at a different point and produces a different error message than the one my test pinned. Evaluator: `agent_blame_unfair: true`, `blocker_type: verifier`, high confidence. **This is the concrete, real-agent evidence behind round 4 fix #5** (relaxed both tests to `assert_read_fails_past_type_check`). | 17/19 new tests passed; the 2 failures were solely the error-message pins now fixed |
| Nova_Nova_4 | PASS_LEGITIMATE | 1560 | none | — | Full implementation; also updated the same obsolete `can_read_meta_errors` assertion my own solution.patch required |

Environment note: Nova_Nova_3's trajectory also shows an unrelated `vrp-pragmatic` workspace-level
route-order assertion failure when the agent ran a broader `cargo test --workspace` on its own
initiative — explicitly NOT caused by this feature (my test.sh only ever runs `-p vrp-scientific
--lib`) and explicitly noted by the evaluator as not affecting the verdict. Not investigated
further: out of scope, pre-existing, not reproducible through the actual test.sh harness.

## Batch 3 — 4x Nova, run against the round-7 artifact (before this hardening round)

Pass rate: 3/4 = 75% (**Too Easy**, exceeds the 40% ceiling). Triggered `olympus-harden`.

| Run | Verdict | Failed tests (new) | Failure reason |
|---|---|---|---|
| Nova_Nova_1 | PASS_LEGITIMATE | none | Full implementation, 21/21 baseline, 19/19 new |
| Nova_Nova_2 | PASS_LEGITIMATE | none | Full implementation, 21/21 baseline, 19/19 new |
| Nova_Nova_3 | PASS_LEGITIMATE | none | Full implementation, 21/21 baseline, 19/19 new |
| Nova_Nova_4 | FAIL_MISSED_REQUIREMENT | all 19 (wrapper timeout) | Agent's own `read_values` loops forever on a truncated EDGE_WEIGHT_SECTION (doesn't check EOF via bytes-read), hit the 1785s wall-clock guard. Not a designed trap catch — an accidental hang bug in that run's own code. |

Diagnosis: 3 clean passes, zero near-misses across all 19 tests — no existing trap is catching
agents at all. See `feedback.md § Hardening round (2026-08-22)` for the full root-cause read and
the two levers added (F-10 cross-product on depot-position x asymmetry; orthogonal GEO
negative-coordinate trunc-vs-floor axis, trap-proofed).

## Batch 4 — 2x Nova, run against the round-8-hardened artifact

Pass rate: 2/2 = 100% (**Too Easy**, worse than batch 3's 75%). Both `PASS_LEGITIMATE`, both
21/21 baseline + 21/21 new. Both agents' `solution-patch.patch` independently wrote
`let degrees = coordinate.trunc();` verbatim, confirming the GEO negative-coordinate lever from
the prior round does not catch real agents (it was priced from a mutation, not agent evidence).

Second diagnosis found a real description/solution mismatch (`meta.md` said "one coordinate line
per customer" for `DISPLAY_DATA_SECTION`, implementation reads `dimension` lines including the
depot) and fixed it. Added one more test combining that corrected fact with a mid-range depot;
trap-proofed but the mutation it catches is already caught by a pre-existing test regardless of
depot position, so this is coverage/fairness reinforcement, not a confirmed new difficulty axis.
See `feedback.md § Batch 4` for the full honest accounting.

## Batch 5 — 6x Nova + 2x Orion, run against the batch-4 artifact

Pass rate: 6/8 = 75% (**Too Easy**). `Nova_Nova_1/2/3/4/6`, `Orion_Nova_1` PASS_LEGITIMATE.
`Nova_Nova_5` FAIL_MISSED_REQUIREMENT: its own `geo_coordinate_to_radians` used `.floor()` instead
of `.trunc()` for negative GEO coordinates -- the GEO-sign lever from the prior round, defeated
0/2 in batch 4, confirmed real here (1/8). `Orion_Nova_2` FAIL_INTEGRATION_ERROR: deleted the
pre-existing `read_customer_data` helper still called by the repo's own test file, breaking
compilation on both baseline and new -- a real baseline-preservation catch, unrelated to any trap
I built. All 6 passing patches independently converged on the same `id - 1` direct-location-
mapping architecture (confirmed via grep across each `solution-patch.patch`), closing off further
depot-position/asymmetry-style levers as ineffective by construction. This result triggered the
scope redesign in `feedback.md` (CLI location export for `DISPLAY_DATA_SECTION`).

## Local validation (see feedback.md for full detail per round)

| Check | Result |
|---|---|
| `cargo build -p vrp-scientific --lib` | clean, 0 warnings |
| `cargo build --workspace` | clean |
| `cargo clippy -p vrp-scientific --no-deps --all-features --tests --examples -- -D warnings` | clean (added round 4, after the platform caught a cast issue I'd missed) |
| `cargo test -p vrp-scientific --lib` (solution + test) | 38/38 pass |
| test.patch only, no solution (`new` mode) | 22/22 fail as expected (F2P confirmed) |
| test.patch only, no solution (`base` mode) | 16/16 pass (no regression) |
| solution.patch only, no test.patch, `cargo build --workspace` | clean (Docker image build state) |
| Both apply orders (test->solution, solution->test) | both apply cleanly |
| Reverse-apply (`git apply -R`) both patches | clean, byte-identical to base |
| Flakiness (2-3x per round, both modes, solution applied) | deterministic, identical every run |
| `effective_loc_check.py` | human-effective 280 (>= 275 target, 4 files) |
| Mutation test on Trap 1 (lead trap) | round 1: 3/23 caught (incomplete fairness fix found and corrected in round 3) -> round 3: 6/23 -> round 4 (after CEIL_2D/ATT unified onto the same placement path): 14/28 |
| Round 7: raw-index fix in `is_rounded_only_affects_euc_2d`, description trim (466->415 words), 3rd false GEO claim rejected | 40/40 pass, F2P confirmed both directions, clippy clean, both apply orders + reverse-apply clean, 3x flakiness deterministic, LOC unchanged 280 effective, terminology sweep clean |
| Hardening round: added `can_read_explicit_full_matrix_asymmetric_with_depot_in_the_middle` (F-10 lever) + `can_read_geo_with_southern_and_western_coordinates` (orthogonal trunc-vs-floor lever, trap-proofed: floor() mutation caught in isolation, 30.0 vs 45.0) | 42/42 pass, F2P confirmed both directions on fresh clone (21 new/modified fail on base, 21 unchanged pass on base), clippy clean, both apply orders + reverse-apply clean, 3x flakiness deterministic, LOC unchanged (human-effective 278, solution.patch untouched), terminology sweep clean |
| 2nd hardening round: fixed `meta.md` DISPLAY_DATA_SECTION "per customer" -> "per node" fairness bug; added `can_read_explicit_with_display_data_section_and_depot_in_the_middle` (coverage reinforcement, not a confirmed new axis) | 43/43 pass, F2P confirmed both directions on fresh clone (22 new/modified fail on base, 21 unchanged pass on base), clippy clean, both apply orders + reverse-apply clean, 3x flakiness deterministic, LOC unchanged (human-effective 278, solution.patch untouched), terminology sweep clean |
| Scope redesign: added cross-subsystem CLI location export (`TsplibLocations` trait, `get_tsplib_locations_serialized`, wired `vrp-cli`'s previously-`unimplemented!()` TSPLIB `LocationWriter`); new tests moved to dedicated integration binaries (`tests/locations_test.rs` in both crates) after catching a real base-mode-compilation-break risk from referencing a genuinely new symbol in the shared `--lib` test binary; also fixed a double-`--` bug in test.sh's cargo invocation that silently broke JSON output and produced 22 false failures | 27/27 new/modified tests fail on base (22 reader + 5 location-export), 21/21 unchanged baseline pass on base (confirmed base-mode compilation unaffected), all 27 pass with solution, 3x flakiness deterministic both modes, both apply orders + reverse-apply clean, clippy clean on both crates' lib targets (pre-existing unrelated vrp-cli bin-target lint confirmed present on base too, left untouched), LOC 278->313 effective, terminology sweep clean, meta.md word count 478/500 |

## Batch 11 (2026-08-31) -- 5/10 PASS = 50%, AT the ceiling

**Note (2026-08-31, after this section was first written): the platform raised the pass-rate
ceiling from 40% to 50%.** Batch 11 at exactly 50% is therefore APPROVABLE, not a too-easy
reject as originally recorded below. The single-trap diagnosis and the re-hardening still stand
-- 50% is the ceiling with zero margin, and payout scales with difficulty -- but the framing of
"over the ceiling" in the text that follows is stale.

| Agent | Verdict | New-mode failures |
|---|---|---|
| Nova_Nova_1 | FAIL_MISSED_REQUIREMENT | `can_get_tsplib_locations_via_cli_with_pure_json_stdout` |
| Nova_Nova_2 | PASS_LEGITIMATE | none |
| Nova_Nova_3 | FAIL_MISSED_REQUIREMENT | `can_get_tsplib_locations_via_cli_with_pure_json_stdout` |
| Nova_Nova_4 | PASS_LEGITIMATE | none |
| Nova_Nova_5 | PASS_LEGITIMATE | none |
| Nova_Nova_6 | PASS_LEGITIMATE | none |
| Nova_Nova_7 | FAIL_MISSED_REQUIREMENT | `can_get_tsplib_locations_via_cli_with_pure_json_stdout` |
| Nova_Nova_8 | PASS_LEGITIMATE | none |
| Orion_Nova_1 | FAIL_MISSED_REQUIREMENT | `can_get_tsplib_locations_via_cli_with_pure_json_stdout` |
| Orion_Nova_2 | FAIL_MISSED_REQUIREMENT | `can_get_tsplib_locations_via_cli_with_pure_json_stdout` |

Every evaluator marked `description_clear: true`, `tests_deterministic: true`,
`difficulty: challenging`, `agent_blame_unfair: false`. No verifier or environment blocker.
The problem is FAIR and SOLVABLE; it is simply TOO EASY now.

### Diagnosis: single-trap collapse

Cluster comparison across the last three batches, by failing test:

| Trap cluster | batch 9 (2/9 = 22%) | batch 10 (0/23, regression-driven) | batch 11 (5/10 = 50%) |
|---|---|---|---|
| stdout purity | 7/9 | 17/23 | 5/10 |
| display-data cluster (export + depot-in-middle + CLI flag) | 2/9 | 5/23 | **0/10** |
| GEO sign/precision | 1/9 | 5/23 | **0/10** |
| header ordering | 0/9 | 1/23 | **0/10** |

Batch 11 has exactly ONE surviving trap, and all five failures are the SAME test. That is the
textbook 1-trap ~50% outcome from the calibration model (1 trap ~50%, 2 independent ~25%,
3 stacked ~12%).

Root cause is self-inflicted and traceable: the fairness rounds that preceded batch 11
(DISPLAY_DATA_TYPE closed-set scoping, explicit header-ordering sentence, the GEO formula
restatement) each CONTRACT-STATED a trap in a way that also handed the fix. This is the
CONTRACT-STATED/FIX-HIDDEN axiom failing in the FIX-HIDDEN direction -- the disclosure was
required for fairness, but the replacement trap was never added alongside it.

### Response: re-harden on an axis that survives full disclosure

Added an ordering requirement that is fully stated yet not handed by the statement:
`get_tsplib_locations` (and the CLI JSON) must return triples in ascending NODE-NUMBER order,
while DISPLAY_DATA_SECTION lines may appear in any order. Tested at DIMENSION 12 with permuted
input lines, so sorting the zero-based id STRINGS lexicographically ("10" < "2") is wrong. The
reference already sorted numerically, so solution.patch is unchanged -- this round converts an
accidental, undocumented behavior into a stated, tested one.

This rides the SAME display/CLI-export machinery that carries the stdout trap (interdependent,
not bolted on), and it is misdirecting: the failure surfaces as a JSON array-order mismatch in
the CLI subprocess test, not as a parser error.

## Batch 12 (2026-09-02) -- 3/10 = 30%, ACCEPTED

| Agent | Verdict | New-mode failures |
|---|---|---|
| Nova_Nova_1 | PASS_LEGITIMATE | none |
| Nova_Nova_2 | FAIL_MISSED_REQUIREMENT | `can_get_tsplib_locations_via_cli_with_pure_json_stdout` |
| Nova_Nova_3 | PASS_LEGITIMATE | none |
| Nova_Nova_4 | FAIL_MISSED_REQUIREMENT | same |
| Nova_Nova_5 | FAIL_MISSED_REQUIREMENT | same |
| Nova_Nova_6 | FAIL_MISSED_REQUIREMENT | same |
| Nova_Nova_7 | FAIL_MISSED_REQUIREMENT | same |
| Nova_Nova_8 | PASS_LEGITIMATE | none |
| Nova_Nova_9 | FAIL_MISSED_REQUIREMENT | same |
| Nova_Nova_10 | FAIL_MISSED_REQUIREMENT | same |

All 10 evaluators: `description_clear: true`, `tests_deterministic: true`, `difficulty:
challenging`, `agent_blame_unfair: false`, `was_mentioned_in_description: true`. Every failing run
scored 34/35 with the stdout-purity test as its sole failure -- an L18 legitimate design wall (3
passes exist, near-misses got everything else, evaluators unanimous on clarity).

**Long-horizon (solver medians):** 7.5 files, 600 added LOC, 7.4M prompt tokens (range 5.3M-12.1M).
Clears the >=2 files / >=200 effective LOC floor with wide margin. Token spend did NOT predict
success: the three solves were not the three highest-spend runs.

**Per-test kills: 1 of 35 tests killed anything.**

| Test | Kills |
|---|---|
| `can_get_tsplib_locations_via_cli_with_pure_json_stdout` | 7/10 |
| every other test (34) | 0 |

**The ascending-node-order re-hardening killed ZERO.** Added in the final round after batch 11 read
50%, tested at DIMENSION 12 with permuted DISPLAY_DATA_SECTION ids so a lexicographic sort of the
zero-based id STRINGS puts "10" before "2". The differential harness over the five batch-11 passing
patches predicted 3/5 kills; the live batch killed 0/10. Both the dedicated test and the two CLI
order assertions killed nobody -- had ordering been the cause anywhere, the `--get-locations` flag
test (same assertion, file output, no stdout involvement) would also have failed, and it did not.
Recorded as law L35: a differential harness measures a TEST-suite delta and cannot measure a
DESCRIPTION delta, so its count is an upper bound whenever meta.md moved.

**The three reviewer coverage suggestions also killed zero** (NO_DISPLAY grammar rejection, missing
EDGE_WEIGHT_FORMAT, six TWOD_DISPLAY permutations). Still correct to take -- they closed real FP
holes and cleared the review round -- but on this problem they bought no difficulty, which bounds
L17/L22 rather than contradicting them.
