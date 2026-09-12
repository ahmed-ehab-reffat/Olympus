# eval-results.md — plasmapy-grid-field-calculus

Base commit `02d1c194a5b054516167b24503abe27b4e77825d`. Image built from
`public.ecr.aws/d3j8x8q7/olympus-base-python:latest`.

## Local validation (pre-batch)

| Check | Result |
| --- | --- |
| Vanilla suite, offline, uid 1000, untouched tree | 4845 passed / 30 skipped / 4 xfailed / 1 xpassed in 72 s |
| Base mode after solution | 4845 passed / 30 skipped, no regressions |
| New mode on base | 209 failed / 209 |
| New mode with solution | 209 passed / 209 |
| Apply order: test then solution | both patches apply clean; base green, new 209 failed, then 209 passed |
| Apply order: solution then test | both patches apply clean; new 209 passed, base green |
| JUnit XML testcases | 209 in new mode, 4880 in base mode |
| `test.sh` mode in patch | `new file mode 100755` |
| Flakiness, new mode x3 every round | identical every run; 209 passed x3 at the final count |
| Flakiness, base mode x3 | 4845 passed / 30 skipped every run, identical |
| Human-effective LOC | 465 across 3 files (972 raw) |
| Banned test-name markers | none |
| Patch encoding | ASCII, LF |

## Mutation battery

**The first three rounds of this file reported "16 of 16 caught, no survivors, against a control run of 209 passed.
passed `--timeout=300` to pytest, `pytest-timeout` is not installed, and an unrecognised argument
makes pytest exit non-zero before collecting anything. Every run therefore looked like a failure
and every mutation looked caught, while in fact not one test had run. The bug was found in the
fourth fairness round, when the reviewer's piecewise-cell suggestion prompted a direct probe of
the cell-splitting mutation, which turned out to survive all 127 tests.

The harness now begins with a **control run**: the unmutated suite must pass with the exact flags
the mutations use, and the battery aborts if it does not. That guard is what the original harness
lacked.

The honest first result was **11 of 13 caught, two survivors**:

- `segment not split at cell boundaries` **survived**. Every integral fixture used the globally
  multilinear field, for which the interpolant is a single global cubic along any line, so
  Simpson over the whole segment is exact whether or not it is split. The headline trap in
  DESIGN.md was not being tested at all.
- `basis integral uses the midpoint rule` **survived**, but this is an equivalent mutant, not a
  gap: for a linear basis function the midpoint and trapezoid forms are algebraically identical.
  It was removed from the battery rather than chased.

Adding the rough-data integration tests killed the real survivor. Every mutation below was then
applied to the reference solution, the 151 new tests run, and the source restored.

| # | Mutation | Verdict |
| --- | --- | --- |
| 1 | Cell tie rule flipped to the lower cell | CAUGHT |
| 2 | Corner weight derivative sign dropped | CAUGHT |
| 3 | Simpson replaced by the trapezoid rule | CAUGHT |
| 4 | Segment not split at cell boundaries | CAUGHT |
| 5 | Segment not clipped to the grid | CAUGHT |
| 6 | Basis integral missing the cell width | CAUGHT |
| 7 | Flux integrating over the normal axis instead of sampling it | CAUGHT |
| 8 | Deposit using nearest-neighbour weights | CAUGHT |
| 9 | `remap` sampling the node instead of averaging its cell | CAUGHT |
| 10 | Curl components transposed | CAUGHT |
| 11 | Box mean divided by the unclipped volume | CAUGHT |
| 12 | Gradient not scaled by the cell size | CAUGHT |

16 of 16 caught, no survivors, against a control run of 209 passed.
now caught by exactly the two rough-data path tests, which is the evidence that they carry the
trap.

## Test Fairness history

Twelve rounds were run. The suite grew from 84 to 209 tests; `solution.patch` never changed.

| Round | Verdict | Tests | What it found |
| --- | --- | --- | --- |
| 1 | FAIL 1/84 | 84 -> 106 | `deposit` fed plain `ndarray` amounts, a promise the prompt makes only for positions. Fixed on the test side. |
| 2 | PASS | 106 -> 117 | "not-a-number when there is none" had two readings for a flat box. Description tightened to "wherever that overlap has no volume". |
| 3 | PASS | 117 -> 127 | The line-integral reference used `np.trapezoid`, a NumPy 2 API, while the repo allows `numpy>=1.26`. Replaced with an exact closed form. |
| 4 | PASS | 127 -> 139 | **Two defects.** The mutation harness had been reporting false positives since round one, and the headline cell-splitting trap was untested. |
| 5 | PASS | 139 -> 145 | "share one unit" had two readings. Description now names the strict one. |
| 6 | PASS | 145 -> 151 | Nothing new. |
| 7 | PASS | 151 -> 157 | Nothing new. |
| 8 | PASS | 157 -> 163 | Narrow real gap: a key-order swap confined to `gradient`'s scalar multi-quantity return was undetected. |
| 9 | PASS | 163 -> 168 | Nothing new. |
| 10 | PASS | 168 -> 174 | Real weakness: centimetre tests compared two calls to the same method, so a shared scale error cancelled. |
| 11 | PASS | 174 -> 191 | Two real weaknesses (per-axis corner ordering, per-axis scaling) **and six unfair tests introduced by me**. |
| 12 | FAIL 6/192 | 191 -> 186 | Those six tests removed. See below. |

### The round-twelve failure

Round eleven suggested testing mixed axis length units, conditionally: "if `CartesianGrid` supports
different but convertible units per axis". A mixed grid does construct, and per-axis
`si_scale_factors` exist, so six tests were added pinning per-axis interpretation of plain
`ndarray` coordinates.

That was wrong. The description says a plain array is read in grid-axis units "as the existing
interpolators already read it", and the existing interpolator uses a single `self.unit`
(`grids.py:1003-1007`), which raises when the three axes differ (`grids.py:371-381`). The repo
convention the prompt defers to cannot express mixed axis units at all, so a solver following it
would fail those six tests.

The precondition checked was that the fixture **constructs**; the precondition that mattered was
whether the **referenced convention extends to it**. The six tests were removed. The six
mixed-unit tests that pass `Quantity` positions were kept: they exercise the grid's internal
per-axis SI handling, which is required because results must come back in metres, and all six were
rated fair.

### The round-fourteen failure

Two `net_flux` tests pinned what "only the part on the grid counts" means for a closed surface.
The reference integrates the overlap portions of the original six faces; an equally plausible
reading takes the outward flux through the boundary of the clipped overlap box, which adds new
faces where the box is cut. The description does not choose, and the repository has no net-flux
convention to settle it.

The tests were removed rather than the description extended, because every other `net_flux` test
uses a box wholly inside the grid, so the core behaviour stays covered and the description does
not grow further. `net_flux` over a box that reaches past the grid is now deliberately
unspecified and untested.

The warning sign was in the authoring notes: three attempts were needed to write those assertions,
and the note recorded at the time was that "a clipped box does not satisfy the divergence
theorem". That was the ambiguity showing itself. A behaviour that takes several attempts to state,
with no sentence fixing it, should be documented or left untested.

### What the mutation battery cannot do

At round eleven the battery reported **17 of 17 caught**, and one of those mutations was
"one shared axis scale factor instead of per-axis" - a change that only differs from correct
behaviour on mixed-unit grids, which the contract does not cover. The battery was green while
certifying a requirement the prompt does not make.

A battery answers "do the tests detect this change". It cannot answer "should this change be
detectable". The two checks are complementary and neither substitutes for the other. That mutation
was dropped when the six tests were removed; the battery now carries 16.

## Test to description mapping

Every assertion traces to a sentence in `meta.md`. Two description sentences were tightened across
these rounds, both fairness-floor clarifications of existing rules rather than new scope: the
flat-box average ("wherever that overlap has no volume") and the vector component units ("units
that are merely convertible to one another ... are not the same unit").

Advisories were declined only where they would pin behaviour the description does not fix.

**Round twelve** proposed pinning which error wins when a grid is both non-uniform and carries a
bad key. The prompt states both errors and never their ordering, so the test would force a guess.
Declined; the suggestion was itself conditional ("if exception precedence matters").

**Round thirteen** proposed three input-validation cases: zero requested quantities, malformed
coordinate shapes, and non-length coordinate units. All three were probed and all three raise
`ValueError` in the reference (`UnitConversionError` subclasses it), but none was fixed by the
description, so they were declined on the first pass. On reaffirmation they were implemented the
fair way instead: one sentence was added to the description, stated as a general rule rather than
an instance list, and the sixteen tests then pin documented behaviour. This is the only round that
**added a requirement** rather than clarifying one, and it closed a real hole, since an agent could
previously skip input validation entirely and pass. That sentence also made two of round
fourteen's advisories fair which would otherwise have been declined.

**The alignment check** (a separate reviewer from Test Fairness) returned a WARNING, not a
failure: the three-keys and same-unit rule was worded generically but sat inside the divergence and
curl paragraph, while `circulation`, `surface_flux` and `net_flux` take `keys` in later paragraphs
without restating it. The tests enforce the rule for all five. It was fixed rather than ignored,
because three of the four failures in this history came from a rule that read unambiguously to the
author and admitted a second reading to someone else. The rule now states explicitly that it
applies wherever a method takes a `keys` argument. `meta.md` is not part of either patch, so the
change cost no revalidation.

**Round sixteen** proposed three, two of which repeated earlier failures: a clipped `net_flux`
case (round fourteen) and mixed-unit plain `ndarray` inputs (round twelve, already re-declined in
round fifteen). Both declined.

The third asked for a `remap` **target** whose three axes carry different units, which looks like
the second but is not. The round-twelve failure was about how a bare coordinate array is
interpreted, which the description routes through the repository's single-`self.unit` interpolator
convention. A remap target's axes come from a grid object, and the repository's own per-axis SI
accessors settle them, so no competing reading exists. Probed before writing anything: units are
preserved per axis and an interior node matches a direct `box_mean` whose half-widths are 0.167,
0.1875 and 0.15 metres, three different values, so per-axis spacing is genuinely exercised rather
than incidentally passing. Taken.

Declining all three because two were repeats would have been as wrong as accepting all three; the
surface wording of a suggestion does not decide it.

**Round fifteen** proposed testing per-axis interpretation of plain arrays on mixed-unit grids.
Those are the six tests round twelve failed the submission for, verbatim. Declined: when an
advisory contradicts a prior FAIL on the same code path, the FAIL is the stronger signal, because
it is a verdict backed by cited source lines rather than a suggestion.

## Test to description mapping

Every assertion traces to a sentence in `meta.md`. Two description sentences were tightened across
these rounds, both fairness-floor clarifications of existing rules rather than new scope: the
flat-box average ("wherever that overlap has no volume") and the vector component units ("units
that are merely convertible to one another ... are not the same unit").

Four advisories were **declined**, all for the same reason: they would pin behaviour the
description does not fix.

Round twelve suggested pinning which error wins when a grid is both
non-uniform and carries a bad key. The prompt states both errors but never their ordering, so a
test would require solvers to guess an unstated convention, which is the exact failure mode round
twelve flagged. The suggestion was itself conditional ("if exception precedence matters").

Round thirteen suggested three more: behaviour for zero requested quantities, for coordinate
arrays not shaped `(3,)` or `(n, 3)`, and for coordinate quantities carrying non-length units. All
three were probed against the reference, and all three raise `ValueError` there
(`UnitConversionError` subclasses it), so tests would have passed. They were still declined,
because in each case a different correct implementation need not raise:

| Case | A correct implementation that does not raise |
| --- | --- |
| zero quantities | returning an empty tuple is equally defensible |
| malformed shape | `pos.reshape(-1, 3)` accepts a `(6,)` array as two points |
| non-length units | `.si.value` instead of `.to(u.m)` gives no error on out-of-contract input |

The description could be extended to cover them, but that is scope creep for malformed input on a
prompt already at the fairness floor. Known rough edge, left deliberately: a call with zero
quantity names surfaces `np.stack`'s own "need at least one array to stack" rather than a
purpose-written message. It is out of contract and untested.

## Agent runs

No batch has been run yet.

| Agent | Evaluator | Verdict | Messages | Files | LOC | Failed tests | Approach note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — | — | — |
