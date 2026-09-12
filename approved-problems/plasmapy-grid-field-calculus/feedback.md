# feedback.md — plasmapy-grid-field-calculus

## Summary

Olympus submission on PlasmaPy/PlasmaPy (BSD-3-Clause, 703 stars, Python), base commit
`02d1c194a5b054516167b24503abe27b4e77825d`. A `CartesianGrid` already defines a continuous field
through `volume_averaged_interpolator`, but nothing in the package works with that field. This
adds the calculus of it: gradients, divergence and curl at arbitrary points, exact integrals along
a polyline, through an axis-aligned rectangle, over the surface of a box and over a box or the
whole grid, deposition of amounts onto grid points as the transpose of interpolation, and
resampling onto another grid by cell averaging.

465 human-effective LOC across 3 files, 209 new tests, all 209 failing on base and all 209
passing with the solution. Vanilla suite 4845 passed / 30 skipped offline, green both before and after the
solution.

## Pick rationale

The standing preference is a repo never used locally. Nothing under `Aprroved/`, `rejected/`,
`_shelved/`, `problems/` or any `TaskN/problems/` touches PlasmaPy, and no problem in the corpus
touches plasma physics or grid-based field calculus.

Roughly sixty candidate repositories were screened on platform metadata first. What each one died
on is worth recording, because the metadata gates are far cheaper than the environment gate and
the environment gate is far cheaper than authoring:

| Repo | Verdict |
| --- | --- |
| seperman/deepdiff, Pyomo/pyomo, hgrecco/pint, OpenMDAO, madmom, pymodbus | NOASSERTION license |
| cvxpy, OpenTimelineIO, robotics-toolbox-python | primary language is C++ |
| unified-planning, galois, salabim | under 500 stars |
| pgmpy/pgmpy | **already ours**: `Task32/problems/pgmpy-influence-diagrams`. Also env-hostile: 20.7 min single-threaded and two test files fetch from HuggingFace |
| RDFLib/rdflib | **already ours**: `Task15/problems/rdflib-query-justification` |
| zarr-python | rectilinear chunk grids merged in PR #3802 |
| linebender/kurbo | path boolean operations exist as a separate published crate |
| optiland/optiland | `tests/gui` needs PySide6 and xvfb; open PR #703 covers multi-sequence and ghost tracing |
| sunpy/sunpy | most gaps live in affiliated packages (`sunkit-image`, `reproject`), so exclusivity is weak |
| qutip, PyBaMM | Cython or C++ build at install time, slow suites |
| PyPSA | domain adjacency with our approved pandapower submission |

**The dedup check paid for itself twice.** Both of my top two feature candidates, influence
diagrams on pgmpy and a query-justification layer on rdflib, turned out to be problems this
repository has already authored. Grepping `Task*/problems/` by repo name before any authoring is
the cheapest gate of all and I ran it late.

## Exclusivity

Canonical slug confirmed `PlasmaPy/PlasmaPy` (no redirect). PRs and issues searched in all states
for "interpolation", "trilinear", "divergence-free", "interpolator", "field line", "tracing",
"topology", "connectivity". No PR or issue implements calculus or integration over a grid. The PRs
that touch the grid interpolators are performance work (#1295 faster interpolation, #2226 and
#2911 parallelisation) and bug fixes (#1173, #2475).

**Branch enumeration mattered here.** `gh api repos/PlasmaPy/PlasmaPy/branches` lists a
`magnetic-topology` branch, and merged PR #1578 puts a 1090-line `magnetic_skeleton.py` on it.
That kills field-line tracing, separatrix surfaces and null-point topology on this repository even
though `gh pr list --state all` against `main` shows nothing. The feature was designed around it:
nothing here traces a field line.

Cold code confirmed by date rather than by issue state. `grids.py` and `nullpoint.py` have had no
substantive commit since 2025; every 2026 commit touching them is a pre-commit autoupdate, a ruff
rule sweep or a lock-file bump.

## Design decisions

- **One rule, many consequences.** The description states once that the grid defines a continuous
  field by multilinear interpolation and that every result is exact for that field. The tie rule
  at cell boundaries, the metre convention and the clipping convention are the only other stated
  absolutes. Nothing enumerates which cases are hard.
- **The integrals carry the difficulty, not the derivatives.** `nullpoint.py` already builds a
  trilinear approximation and its Jacobian, which is a fair in-repo precedent and makes the
  gradient half of the problem easier. There is no precedent anywhere in the repository for exact
  integration of the interpolant, for deposition or for cell-averaged resampling.
- **Coplanar conventions are shared, not per method.** Clipping to the grid, the tie rule and the
  not-a-number convention are stated once and apply to all twelve methods, which is what makes the
  traps interdependent: a wrong tie rule shows up as a wrong integral.
- **Scope grew once to clear the LOC floor.** The first cut (gradient, divergence, curl, line
  integral, circulation, surface flux, box and volume integrals) measured 366 human-effective.
  Added, in order: conservative resampling with a batched nodal-basis integration kernel (+47) and
  deposition as the transpose of interpolation (+47), plus the changelog entry the repository's
  own contributing guide requires. Both additions are orthogonal algorithms rather than
  more surface, and both are contract-required and tested. Final 465 after the formatting pass.

## Verification

- **Independent quadrature oracles, zero mismatches.** A globally multilinear field is reproduced
  exactly by the interpolant, so closed-form gradients, antiderivatives and line integrals are
  exact references. Every operation was checked against `scipy.integrate.quad`, `dblquad` and
  `tplquad` at 1e-13 before a single test was written.
- **Cross-quantity invariants.** Stokes' theorem on a rectangle, the divergence theorem on a box,
  conservation and the transpose identity for deposition, agreement between a 3x3x3 and an
  11x13x15 grid on the same multilinear field, and agreement between a grid in metres and the same
  grid in centimetres.
- **Mutation battery, 16 of 16 caught against a verified control of 209.** Tie rule, corner
  weight derivatives, Simpson against trapezoid, cell splitting, clipping, basis normalisation,
  the flux normal axis, nearest-neighbour deposition, node sampling in `remap`, transposed curl,
  unclipped box means, unscaled gradients, per-axis corner ordering, stored-unit axes, and two
  key-order variants.
  **Two corrections belong here.** First, the "12 of 12" reported before round four was false: the
  harness passed `--timeout=300` while `pytest-timeout` was absent, so pytest exited non-zero on
  every run and every mutation looked caught although no test ran. A control run now guards it.
  Second, at round eleven the battery reported 17 of 17 while one mutation enforced behaviour the
  prompt does not require; Test Fairness caught that, the battery could not. A battery answers
  whether tests discriminate, never whether the pinned behaviour is required.
- **Environment Quality.** The vanilla repository suite is 4845 passed / 30 skipped / 4 xfailed /
  1 xpassed offline as uid 1000, in 72 s, on the untouched tree. Eleven NIST stopping-power tests
  fetch a data file from the PlasmaPy data repository; the Dockerfile warms that file into the
  cache at build time and sets `HOME=/app` so it is found offline. `SETUPTOOLS_SCM_PRETEND_VERSION`
  is set because the platform tree has no `.git`.
- **Flakiness.** New tests were run three times after every change; the count was identical
  every run, 209 passed at the final count. Base mode identical across runs.
- **Both apply orders.** test then solution, and solution then test, both apply cleanly against
  the base commit. Base mode passes and new mode fails 209/209 before the solution; both pass
  after. JUnit XML carries 209 testcases in new mode and 4880 in base mode. `test.sh` is mode
  100755 in the patch.
- **Test Fairness round.** The platform check returned FAIL, 1 of 84 unfair: the transpose test
  fed `deposit` a plain `ndarray` of amounts, which the description only promises for positions.
  Fixed on the test side with a dimensionless `Quantity` rather than by widening the description.
  All six advisory coverage suggestions were then taken, taking the suite to 106 tests. A second
  round returned PASS with six further advisories, all taken, taking the suite to 117 and changing
  one description word so the flat-box average has a single reading. A third round returned PASS
  with four more, all taken, taking the suite to 127; one of them was a real portability defect in
  the test file rather than a coverage gap. Details and the reasoning
  about solvability risk are in `eval-results.md`.

## Easiness red team

- A shim cannot pass: the tests reach twelve methods, assert shapes, dtypes, units, error types
  and not-a-number conventions, and check four analytic invariants that only agree if the whole
  family describes one field.
- The traps are misdirecting rather than announced. Dropping the cell split in the line integral
  does not fail with a missing piece, it fails with a value that is close but outside tolerance.
  A nearest-neighbour deposit still conserves the total, so only the transpose identity catches
  it. A wrong tie rule surfaces as a wrong integral rather than as a wrong cell.
- The traps are interdependent because they live in one shared kernel: a local fix to the cell
  index changes the gradient, the line integral, the flux and the deposit at once.

## Attempt history

1. **Pick filtering (2026-08-09).** Roughly sixty repositories screened; the table above records
   what each died on. PlasmaPy selected after the vanilla suite came back green offline in 57 s.
2. **Design and implementation.** Kernels written against the contract, then verified against
   scipy quadrature. One defect found and fixed during verification: the first `box_integral` and
   `surface_flux` split the region cell by cell with meshgrids, which was replaced by the nodal
   basis contraction so that `remap` could reuse it.
3. **Scope pass.** `remap` and `deposit` added to clear the LOC floor with orthogonal logic.
4. **Mutation battery.** Twelve mutations run, all caught on the first battery.
5. **Test Fairness, sixteen rounds.** Full round-by-round table in `eval-results.md`. Rounds one
   to five each found a real defect in a test, the description or the harness. Rounds six, seven
   and nine found nothing. Rounds eight, ten and eleven each found a weakness in the discriminating
   power of a test rather than an uncovered behaviour.
6. **Three FAILs, all of them tests of mine, all the same shape:** pinning a model the description
   does not choose. Round twelve pinned per-axis reading of plain arrays on mixed-unit grids, which
   the repo convention the prompt defers to cannot express. Round fourteen pinned one of two
   plausible clipping models for a closed surface. Round one pinned plain-array `amounts`, a
   promise the prompt makes only for positions. All were fixed on the test side.
7. **Round thirteen is the only round that added a requirement.** Three input-validation cases were
   declined as unstated, then on reaffirmation implemented the fair way: one sentence added to the
   description, then tested. It closed a real hole and made two later advisories fair.
8. **Rounds fifteen and sixteen declined suggestions that repeated earlier failures**, three in
   total across the two rounds. Round sixteen also took one that merely resembled a failed case: a
   `remap` target with mixed axis units, which is settled by the repository's per-axis SI accessors
   rather than by the plain-array convention that sank round twelve. The checker
   A verdict backed by cited source lines outranks a later advisory.
9. **Ready for the first agent batch.** Base green, F2P 207/207, flakiness identical across runs,
   mutation battery 16/16 against a verified control of 209. The solution has not changed since it
   was first written; every finding across sixteen rounds landed in the tests or the prompt. No
   agent runs yet.
