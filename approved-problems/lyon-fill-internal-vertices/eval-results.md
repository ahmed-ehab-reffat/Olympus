# eval-results.md — lyon-fill-internal-vertices

No agent runs yet. Local validation only.

## Per-agent results

| Batch | Run | Agent | Evaluator | Verdict | Messages | Files | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Nova 1 | FP panel | PASS (genuine) | — | — | — | — | single-pass buffering + topological simplification | 
| 1 | Nova 2 | FP panel | **FALSE POSITIVE** | — | — | — | — | two-phase removal + break on first failure; leaves (-13,15), (30,30) |
| 1 | Nova 3 | FP panel | PASS (genuine) | — | — | — | — | position-bit edge keying, equivalent on manifold meshes |
| 1 | Nova 4 | FP panel | **FALSE POSITIVE** | — | — | — | — | fan fallback on non-convex cavity GROWS area ~0.3% |
| 1 | Nova 5 | FP panel | **FALSE POSITIVE** | — | — | — | — | one-ring remesh bails on complex links; leaves (20,25),(20,20),(60,40) |
| 1 | Nova 6 | FP panel | PASS (genuine) | — | — | — | — | judge dissent on a 1e-23 probe ruled unfair by adjudicator |
| 1 | Nova 7-10 | wrapper | FAIL | — | — | — | — | chained overlaps / self-overlapping outline / preservation |

## Batch summary

| Batch | Date | Agents | Pass | Rate | Band | Notes |
|---|---|---|---|---|---|---|
| 1 | 2026-08-06 | 10x Nova | 6 raw / **3 genuine** | 60% raw / **30% genuine** | over cap raw; under cap genuine | FP panel voided Nova 2, 4, 5 |
| 2 | 2026-08-06 | 10x Nova | 4 raw / **0 genuine** | 40% raw / **0% genuine** | Auto Review: no difficulty finding | FP panel voided ALL FOUR; each failed a DIFFERENT probe |

## Local validation (2026-08-06)

| Check | Result |
|---|---|
| base, test.patch only (no solution) | 185 pass, 0 fail |
| new, test.patch only (no solution) | 45 cases, 45 failures; emitted names EXACTLY equal the solution-run names (f2p set resolves) |
| base, both patches | 185 pass, 0 fail, no regressions |
| new, both patches | 45 pass, 0 fail |
| doc tests | 7 pass |
| reverse apply order | both apply, base + new pass |
| `git apply -R` both patches | clean, tree pristine |
| flakiness, base + new, 3x | identical md5 digest, 226 cases, 3/3 |
| repo baseline determinism, 4x pre-change | identical |
| Counter-2 LOC | 431 raw / 353 counter1 / **260 human-effective**, 4 files |
| dead code | 0 warnings |
| Docker | **NOT VERIFIED — no local Docker. Owed to the platform run.** |

## Reference-behavior table (what the solution produces)

Both sweep orientations, `NonZero`, option on. Area preserved in every row; coverage checked on a
3600-point lattice with zero mismatches.

| Fixture | base | eliminated | area |
|---|---|---|---|
| two overlapping squares | 10v/10t | 8v/6t | 2800 |
| self-overlapping outline (issue #871 shape) | 9v/10t | 6v/4t | 9600 |
| three overlapping squares | 18v/22t | 12v/10t | 3550 |
| contained subpath, same winding | 8v/10t | 4v/2t | 10000 |
| squares sharing an edge | 6v/4t | 4v/2t | 3200 |
| hole inside a depth-2 overlap | 14v/16t | 12v/12t | 16000 |
| hole cut by an overlap seam | 14v/16t | 8v/8t | 14800 |
| six overlapping circles | 246v/416t | 74v/72t | 5079.32 |
| donut (opposite winding) | 8v/8t | unchanged | 8400 |
| pentagram | 10v/8t | unchanged | 1796.112 |
| single square | 4v/2t | unchanged | 1600 |

## Round R1 - platform review response

| Verdict | Result |
|---|---|
| Description review | `request_changes`, 4 trims - ALL taken; meta 348 -> 292 words |
| Verify Solution | FAIL on `cargo-test.compilation` not in p2p/f2p - FIXED via per-test-name fallback in test.sh |
| Test Fairness | FAIL, 4 of 28 unfair - 1 deleted, 3 weakened off exact index-buffer equality |
| Coverage suggestions | all 3 taken; suite 28 -> 30 tests |

## Round R2 - Auto Review response

Auto Review: Revision Requested. Description 3/3 clean, Solution & Code 3/3 clean, Tests 2/3.

| Finding | Result |
|---|---|
| T4 EvenOdd boundary exceptions (Medium) | FIXED - `the_even_odd_rule_keeps_hole_and_reflex_corners` over pentagram + donut + overlapping donut |
| T4 intersection-generated attributes (Medium) | FIXED - `attributes_survive_on_intersection_generated_vertices`; measured (40,20) attr 56 and (20,40) attr 57 as generated-and-surviving |
| Coverage: cascading removal | MEASURED IMPOSSIBLE (14/14 fixtures, `initially_removable == actually_removed`); meta reworded to stop implying it |
| Self-caught | removed a vacuously-true assertion introduced in the new attribute test |

Suite 30 -> 32 tests. Solution unchanged, so LOC stays at 260 human-effective.

## Round R3 - Auto Review response

Tests 1/3 (Weak) on one High finding: the custom `FillGeometryBuilder` VertexId contract was untested.

| Item | Result |
|---|---|
| High: builder-returned VertexId remapping | FIXED - `SparseIdBuilder` returns non-contiguous ids (1000, 1007, ...); new test asserts triangles use exactly the issued ids |
| Trap-proof mutation A (plan ids) | caught, wide collateral |
| Trap-proof mutation B (contiguous ordinals - the reviewer's scenario) | **caught by exactly 1 test, the new one: 34 passed / 1 failed** |
| Coverage: builder error path | ADDED - error propagates and `abort_geometry` fires |
| Coverage: incremental `FillTessellator::builder` | ADDED - matches `tessellate_path` output exactly |
| Description signature WARNING | FIXED - builder method documented as taking a boolean |

Suite 32 -> 35. Solution unchanged, LOC stays 260 human-effective.

## Round R5 - Test Fairness

FAIL, 6 of 45 unfair: all were preconditions on the DISABLED mesh. Fixed by STATING the current
behavior in meta.md (one new sentence + widening "non-zero" to "either fill rule"), not by deleting
the assertions. Two tests deleted in the first attempt were restored. 39 -> 41 tests.

## Round R6 - batch 2 FP response

All 4 batch-2 passes were FPs, but UNCORRELATED (each failed a different probe). Added 4 tests
targeting Nova 1/2/3 + the Auto Review degenerate Medium; deliberately declined the Nova 4
epsilon-scale kink probe as flaky/unfair. Predicted batch 3 ~1/10. 41 -> 45 tests.

## Reminders for the first batch

- Save every passing agent diff to `agent-runs/<batch>-<run>.patch` while the run view is open,
  plus the 1-2 most instructive failures.
- Watch whether T2 (triangle handedness under the Horizontal sweep) shows up as
  under-simplification rather than a wrong region. That is the predicted misdirection and the one
  trap already measured rather than guessed.
- Watch whether T4 (event-queue restore between the two sweeps) shows up only on self-intersecting
  input, which is what `repeated_tessellation_is_stable` and the circle fixtures target.
- FP check is mandatory before submit: confirm every passing agent actually met every requirement,
  not merely passed the tests.
