# gonum-plot-exact-glyph-layout - eval results

No platform batch yet.

## Local validation (SLICE, 2026-10-03)

Image `factory-gonum-plot-exact-glyph-layout` built from a fresh clone at BASE (2m48s with the base
image cached). All runs `--network none`.

| User | base, no solution | new, no solution | base, solution | new, solution |
|---|---|---|---|---|
| 1000:1000 | 274 tests, 0 failures, exit 0 | 11 tests, 11 failures, exit 1 | 274 / 0, exit 0 | 11 / 0, exit 0 |
| 0:0 | 274 / 0 | 11 / 11 | 274 / 0 | 11 / 0 |
| 4242:4242 | 274 / 0 | 11 / 11 | 274 / 0 | 11 / 0 |

Flakiness (uid 1000, solution applied): base x3 and new x3, identical test-ID sets, 0 failures each.

Solver-rounding probe (local, `go test -trimpath`, base skip list): four alternative correct layout
solvers (pairwise closed form, bisection, Newton with n+w read-out, Newton with m-w read-out) pass every
base-mode test once the 37 golden checks use `CheckPlotApprox(..., 0.1)`. With strict goldens they
failed TestRotation, TestLatex or TestBarChart.

LOC (hook, solution.patch): 167 human-effective, 262 raw, 3 files.

## Dockerfile fix re-validation (2026-10-13)

Build-time `go test -run '^$'` removed. Image rebuilt from a fresh clone at BASE, all runs `--network none`:
1000:1000, 0:0 and 4242:4242 each gave base 274/0 (with and without solution), new 11/11 without solution,
new 11/0 with solution. Identical to SLICE.
