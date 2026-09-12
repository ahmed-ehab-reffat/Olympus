# DESIGN.md — pyamg-aggressive-coarsening

## 1. Title

Add aggressive coarsening and multipass interpolation to classical AMG

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (new variant plus a subtle algorithmic correctness kernel; PLAYBOOK § Pattern 12)
- Pass rate target: **1/10 (10%)**, hard cap 40%
- Best agent: mixed
- Dominant verdict: MISSED_REQUIREMENT / INTEGRATION_ERROR

## 3. Public API surface

In `pyamg.classical.split`:

- `aggressive_strength_of_connection(S, splitting, degree=2, paths=1)` -> `csr_array`
  Long-range strength between the coarse points of `splitting`: entry `(i, j)` is kept when at
  least `paths` distinct fine points lie on a strong path of length at most `degree` from `i` to `j`.
- `aggressive_coarsening(S, degree=2, paths=1, second_pass=False, method='RS')` -> `ndarray` of `intc`
  Two-stage splitting: standard Ruge-Stuben on `S`, then Ruge-Stuben on the long-range graph.

In `pyamg.classical.interpolate`:

- `interpolation_passes(A, C, splitting, theta=None, norm='min')` -> `ndarray` of `intc`
- `multipass_interpolation(A, C, splitting, theta=None, norm='min', trunc=None, improve=0, strict=False, lump=False, max_passes=None)` -> `csr_array`
- `truncate_interpolation(P, theta)` -> `csr_array`
- `jacobi_improve_interpolation(A, P, splitting, omega=4.0/3.0, degree=1, C=None)` -> `csr_array`

In the new module `pyamg.classical.sparsify`:

- `sparsify_coarse_operator(A, theta=0.1, lump='diagonal', symmetric=True, B=None, protect=None)` -> `csr_array`

In `pyamg.classical.classical`:

- `ruge_stuben_solver(..., CF=('aggressive', {...}), interpolation=('multipass', {...}), aggressive_levels=None, sparsify=None)`

Exports added to `pyamg.classical.__init__`.

## 4. Canonical output form

- `aggressive_strength_of_connection` returns an `n x n` `csr_array` with zero diagonal, `float64`
  data equal to the path count, sorted indices, and nonzeros only in rows and columns that are
  coarse in `splitting`.
- `aggressive_coarsening` returns length-`n` `intc`, `1` coarse and `0` fine, like `RS`.
- Prolongators are `csr_array`, shape `(n, nc)` with `nc = splitting.sum()`, coarse columns numbered
  by increasing row index, sorted indices, no explicit zeros.
- A coarse point's row is a single `1.0`. A fine point that reaches no coarse point after the passes
  keeps an empty row.
- `truncate_interpolation` keeps the largest-magnitude entries and rescales each row so its sum is
  unchanged; an all-zero row stays all zero.
- Empty input (`n = 0`) is returned unchanged rather than raising.

## 5. Blind-spot pre-empts

- Iteration termination: "repeats until a pass adds nothing".
- Rule resolution: "paths run through fine points only".
- Adjacent vs all positions: "distinct fine points", not distinct paths.
- Unstated inverse: what happens to a fine point that never reaches a coarse point.
- Compound order: scaling is applied once, to the finished row.

## 6. Description draft

See `meta.md` (795 words, plain prose, no headers).

## 7. File footprint

| Action | Path | Raw delta | Reason |
| --- | --- | --- | --- |
| MODIFY | `pyamg/classical/split.py` | +199 | long-range strength + two-stage coarsening |
| MODIFY | `pyamg/classical/interpolate.py` | +427 | passes, multipass, truncation, Jacobi improvement |
| NEW | `pyamg/classical/sparsify.py` | +160 | coarse-operator sparsification |
| MODIFY | `pyamg/classical/classical.py` | +36 | solver wiring |
| MODIFY | `pyamg/classical/__init__.py` | +13 | exports |

Measured: 835 raw / 436 human-effective across 5 files.

## 8. Solution outline (pure-function helpers)

- `_strong_neighbors(S)` -> CSR pattern with the diagonal removed <- "strong connection"
- `aggressive_strength_of_connection` <- long-range coupling rule
- `aggressive_coarsening` <- two-stage splitting
- `_pass_one_weights(A, C, splitting)` <- fine points next to coarse points
- `_substitute(row, donor_rows)` <- later passes redistribute onto earlier rows
- `_scale_rows(A, P, splitting)` <- one scaling of the finished row
- `truncate_interpolation` <- drop small entries, keep the row sum
- `jacobi_improve_interpolation` <- one weighted-Jacobi sweep on the fine rows

Fixpoint loop, verbatim shape:

```
while True:
    added = assign_next_pass(...)
    if not added:
        break
```

## 9. Test file outline

Path: `pyamg/classical/tests/test_aggressive_<hash>.py`

Block 1 imports; block 2 builders (1D/2D Poisson, hand-built CSR, anisotropic stencils);
block 3 assertion helpers (`assert_rows_sum_to`, `dense`); block 4 tests grouped by
long-range strength / two-stage coarsening / multipass passes / scaling / truncation /
Jacobi improvement / solver wiring / edge cases.

Shipped: 126 tests, every one failing on base (0 collection errors).

## 10. Forced signatures

Python keyword arguments are pinned in meta: `degree`, `paths`, `second_pass`, `theta`, `norm`,
`trunc`, `improve`, `omega`. Return types pinned (`csr_array`, `intc` array).

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt in meta | Test |
| --- | --- | --- | --- | --- |
| 1 | Long-range graph built as `S @ S` | squaring counts paths through coarse points and keeps the direct edge | "through fine points only" | `paths_through_a_coarse_point_do_not_count` |
| 2 | `paths=2` counted as two paths rather than two distinct fine points | wording | "distinct fine points" | `two_paths_through_one_fine_point_are_one` |
| 3 | Scaling applied per pass | the obvious recursive substitution rescales twice | "scaled once, after the passes" | `a_third_pass_row_keeps_its_row_sum` |
| 4 | Truncation without rescaling | looks harmless | "rescaled so the row sum is unchanged" | `truncation_preserves_the_row_sum` |
| 5 | Jacobi improvement applied to coarse rows | the obvious sweep touches every row | "coarse rows are left alone" | `improvement_leaves_coarse_rows_alone` |
| 6 | Aggressive coarsening leaves fine points with no coarse neighbour | direct/classical interpolation then yields empty rows | multipass is required | `aggressive_needs_multipass` |

## 12. Tier + category

Tier Olympus. Category: feature-request.

## 13. Predicted pass rate

10-25%. Six interdependent traps, all proved by mutation (see feedback.md), exact prolongator
values and splittings asserted.

## 14. Quality gate

Repo understanding 5/5; PR check run (see feedback.md); corpus recipe: one kernel (the pass
structure) driving strength, coarsening, interpolation and the solver; oracle is an independent
dense reference; signatures pinned.

## Why this is not a duplicate

Closest approved siblings are `scikit-fem-hanging-nodes` (constraint elimination on a mesh) and
`pysmt-bit-blasting`. Neither touches algebraic multigrid, coarse-grid selection, or prolongator
construction. No pyamg problem exists in any local folder.

Predicted iteration cycles: 2.
