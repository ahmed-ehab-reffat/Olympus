# eval-results — pyamg-aggressive-coarsening

## Batch 1 — Nova x4, 2026-08-08 (artifact at 213 tests)

| batch | agent | verdict | new tests | files | raw LOC | failed tests | failure reason | approach |
|---|---|---|---|---|---|---|---|---|
| 1 | Nova_Nova_1 | fail | 208/213 | 5 | +691 | `the_solver_accepts_sparsification`, `sparsification_leaves_the_finest_operator_alone`, `the_coarse_operator_is_sparsified_exactly_once`, `every_galerkin_operator_is_sparsified_once`, `a_vector_holding_a_zero_is_refused` | rejects `sparsify=('lump', {...})`; refuses a zero in `B` only when a row actually drops something | same five files as the reference |
| 1 | Nova_Nova_2 | fail | 206/213 | 5 | +788 | the five above, plus `no_aggressive_levels_is_plain_ruge_stuben`, `strong_lumping_falls_back_when_the_share_is_zero` | same two, plus `aggressive_levels=0` read as unlimited and a signed strong-lumping share | same five files |
| 1 | Nova_Nova_3 | fail | 205/213 | 5 | +692 | the seven above, plus `a_row_whose_kept_entries_cancel_is_left_alone` | same, plus truncation drops the row instead of leaving it alone when the kept entries cancel | same five files |
| 1 | Nova_Nova_4 | fail | 204/213 | 5 | +788 | the eight above, minus `no_aggressive_levels`, plus `lumping_changes_a_row_the_passes_could_not_finish` and `lumping_divides_by_the_widened_diagonal` | same, plus multipass lumping recorded neighbours unsettled at the end rather than when the row settled | same five files |

Baseline 269 passed, 1 skipped in all four. No agent touched the tests. Every failure was
deterministic, nothing flaky and nothing environmental. Pass rate 0/4.

## Shared-failure analysis

| test | agents failing | root cause | verdict |
|---|---|---|---|
| `the_solver_accepts_sparsification` | 4/4 | `sparsify=('lump', {...})` rejected | spec gap |
| `sparsification_leaves_the_finest_operator_alone` | 4/4 | same | spec gap |
| `the_coarse_operator_is_sparsified_exactly_once` | 4/4 | same | spec gap |
| `every_galerkin_operator_is_sparsified_once` | 4/4 | same | spec gap |
| `a_vector_holding_a_zero_is_refused` | 4/4 | "refused unless nothing is lumped" read as "only when a row drops something" | spec gap |
| `strong_lumping_falls_back_when_the_share_is_zero` | 3/4 | "magnitudes weighed the same way" read as the magnitude of the weighted entry | spec gap |
| `no_aggressive_levels_is_plain_ruge_stuben` | 2/4 | `aggressive_levels=0` read as falsy, so unlimited | spec gap |
| `a_row_whose_kept_entries_cancel_is_left_alone` | 2/4 | stated plainly in meta.md | fair trap, kept |
| `lumping_changes_a_row_the_passes_could_not_finish` | 1/4 | timing of "could not use" | fair trap, kept |
| `lumping_divides_by_the_widened_diagonal` | 1/4 | stated plainly | fair trap, kept |

Four causes account for every 4/4 and 3/4 failure and all four are description problems, not
difficulty. The tuple form alone accounts for four of the five universal failures. All four are
clarified in meta.md; the solution and the tests are unchanged.

Runs are stale: meta.md changed and the artifact moved from 213 to 215 tests after the batch was
taken, so batch 2 must be rerun from scratch.

## Batch 2 — Nova x4 + Orion x2, 2026-08-08 (artifact at 228 tests)

| agent | verdict | new tests | failed tests |
|---|---|---|---|
| Orion_Nova_1 | fail | 226/228 | `a_two_dimensional_vector_is_refused`, `a_column_shaped_vector_is_refused` |
| Orion_Nova_2 | fail | 226/228 | the same two |
| Nova_Nova_1 | fail | 222/228 | the two above, plus the five solver-sparsification tests |
| Nova_Nova_4 | fail | 221/228 | the same seven |
| Nova_Nova_2 | fail | 218/228 | those, plus multipass lumping and complex lumping |
| Nova_Nova_3 | fail | 218/228 | the same ten |

Both Orion runs failed **only** the two `B`-shape tests added in round 22. Every other one of the 228
passed. The four clarifications from batch 1 worked: not one of the 4/4 failures from that batch
recurred.

### The two tests were mine and they were wrong

`B` had been tightened in round 22 to reject anything that is not one-dimensional. Orion wrote
`if B.size != n or B.ndim > 2 or (B.ndim == 2 and 1 not in B.shape): raise` and then reshaped, whose
error message is "B must hold one entry per point" - almost the wording of the description itself,
"a vector `B` holding one entry per point". A row or column shaped array does hold one entry per
point. Six of six agents took that reading. The requirement was unfair, and it was the only thing
between this problem and solvability.

Both tests are deleted and the reference is back to the lenient `ravel`, which is what it was before
round 22 and what every agent wrote. Wrong total length is still refused and still tested.

### Measured effect

Every agent patch was replayed against the corrected suite, one fresh container each:

| agent | replayed |
|---|---|
| Orion_Nova_1 | **233/233 pass** |
| Orion_Nova_2 | **233/233 pass** |
| Nova_Nova_1 | 221/226 |
| Nova_Nova_4 | 221/226 |
| Nova_Nova_2 | 218/226 |
| Nova_Nova_3 | 218/226 |

**2 of 6 pass, 33%.** Solvable, and inside the 40% cap. The remaining Nova failures are the solver
sparsification wiring and the lumping arithmetic, which Orion implemented correctly, so they are
difficulty rather than specification.

## Local pre-batch measurements

| check | result |
|---|---|
| new tests | 233 |
| new tests failing on base | 233 of 233 (0 collection errors) |
| new tests passing with the solution | 233 of 233 |
| base suite | 269 passed, 1 skipped, before and after the solution |
| solution effective LOC | 456 human-effective, 5 files |
| determinism | new 3x identical, base 3x identical |
| mutation battery | 7 mutations, 7 killed (one only after two fixtures were added) |

## Predicted difficulty

Target 1 of 10. Traps that survive the clarification, ranked by how many tests each mutation killed:

1. the finished row scaled once after the passes rather than per pass (11)
2. the long-range graph built by squaring the strength pattern (5)
3. sparsification that drops without lumping (3)
4. truncation that does not restore the row sum (2)
5. a Jacobi sweep that also rewrites the coarse rows (2)
6. a long-range path whose first hop lands on a coarse point (2)

The misdirection is that a wrong long-range graph or a wrong pass order does not fail loudly. It
produces a plausible hierarchy that still converges, and only the pinned prolongator entries and the
splitting show it.

Batch 1 confirms the shape: the nearest agent was five failures away and four of those five were one
unstated calling convention. Truncation cancellation, multipass lumping timing and the widened
diagonal were each missed by only one or two agents, which is the calibration wanted.
