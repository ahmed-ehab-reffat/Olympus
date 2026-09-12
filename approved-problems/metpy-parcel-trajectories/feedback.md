# feedback.md — metpy-parcel-trajectories

## Summary

Tier Olympus, category feature-request. Target repo `Unidata/MetPy` (1433 stars, BSD-3-Clause,
Python, last commit 2026-08-04, 53 open PRs but only 8 branches). Base commit
`a4d55f42f361595745821d173a1deb55ba356f86`.

The task adds a Lagrangian trajectory subsystem: `metpy.calc.parcel_trajectory` integrates
parcels through gridded winds with a fourth order Runge-Kutta step on a sphere, and
`sample_trajectory`, `trajectory_length`, `trajectory_density`, `trajectory_crossings`,
`trajectory_spread` and `extend_trajectory` read the result. The 4-D field sampler that every
stage uses is exposed in the sibling package as `metpy.interpolate.interpolate_to_track`.

## Pick-time gates

| Gate | Result |
| --- | --- |
| Metadata | BSD-3-Clause spdx, primary language Python, 1433 stars |
| Activity | commits within the week, 36.9k source LOC |
| Churn | 8 branches, all short lived; no branch or PR touches `calc` trajectories |
| Exclusivity | `gh pr list -R Unidata/MetPy --state all --search` over trajectory, back trajectory, parcel-path, advect, streamline, advection: zero hits on trajectory integration; `gh issue list` likewise (issue #662 is circulation, #2925 is sounding diagnostics) |
| Defined behaviour | the metric-term formulation and RK4 are textbook; every rule is stated in meta.md |
| Dedup | closest local siblings are `python-control-multirate` (sample-rate algebra), `stonesoup-multiple-model` (state estimation) and the shelved `orb-geofence-visits` (consumes trajectories, does not compute them) |
| Flakiness | vanilla suite identical across runs, no timing or RNG in the new tests |
| Env quality | bare `pytest` on the vanilla tree: 1633 passed / 8 skipped offline in `olympus-base-python`, 4.9 min |

## Numbers

- solution: 906 raw / **462 human-effective** across 5 files (2 new modules, 2 package
  exports, 1 docs listing)
- tests: **154**, all failing on base, all passing with the solution
- base mode: 1624 passed / 8 skipped, no regressions with the solution applied
- both patch orders apply cleanly and both unapply cleanly

## Environment notes

Three things had to be provisioned before the vanilla suite came green offline, each of which
would otherwise have read as a broken repo:

- `setuptools_scm` needs a git checkout, and the platform tree has none, so the Dockerfile
  sets `SETUPTOOLS_SCM_PRETEND_VERSION`.
- `tests/plots` downloads Natural Earth shapefiles through cartopy on first use. Running the
  repo's own `ci/download_cartopy_maps.py` at build time and pointing `CARTOPY_DATA_DIR` at
  the result fixes 168 failures at once. Without it the first failure cascades: cartopy raises
  a `DownloadWarning`, `filterwarnings = error` turns it into a failure, the figure is never
  closed, and every later plot test dies on "More than 20 figures have been opened".
- `tests/remote/test_aws.py` replays VCR cassettes but one test opens a remote netCDF through
  libcurl, which VCR cannot intercept. `needs_aws` skips the whole module when boto3 is
  absent, so boto3 is left out of the install.

`TEST_DATA_DIR` is set to the in-tree `staticdata`, which is what makes pooch work offline.

## Difficulty design

Fifteen mutations, every one killed by the suite:

| Mutation | Meaning | Tests killed |
| --- | --- | --- |
| M1 | zonal rate without the cosine of latitude | 28 |
| M2 | the four stages all sample the field at the step start time | 6 |
| M3 | vertical interpolation linear in pressure | 8 |
| M4 | coordinate axes assumed to ascend | 33 |
| M5 | longitudes not matched into the field's range | 7 |
| M6 | no seam column for a global longitude grid | 4 |
| M7 | a projected grid read as if it were longitude and latitude | 3 |
| M8 | positions outside the field clamped instead of ending the run | 20 |
| M9 | conserved surface level found once per step, not per stage | 2 |
| M10 | a sample exactly on the level counted as a crossing twice | 3 |
| M11 | residence time binned to the lower grid point, not the nearest | 2 |
| M12 | ensemble centre taken as the plain mean of the angles | 4 |
| M13 | Euler step instead of Runge-Kutta | 19 |
| M14 | path length measured on a flat earth | 1 |
| M15 | a kept level surviving after the parcel left the grid | 1 |

M1, M2, M4, M8 and M13 interact: each one changes the positions the others are evaluated at,
so a local repair of one still fails the tests that belong to the others.

## FP check

Every sentence of `meta.md` maps to at least one test and every test maps back to a sentence.
Three claims survived the first mutation round unbroken and were closed rather than dropped:

- "found afresh at every stage" was unenforceable while every fixture had a wind that did not
  vary with height. A fixture where the wind varies with pressure and the surface slopes in
  longitude separates the two readings, checked against `solve_ivp` on the exact reduced ODE.
- "counting a sample exactly on the level as above it" could not be tested because the
  crossing fixtures used 5 Pa/s, which drives the parcel out of the vertical range in one
  step, so those tests were passing on all-missing values. The fixtures now use 0.5 Pa/s and
  the parcel stays in the domain.
- "that sample and every later one are missing" was only checked on the horizontal position of
  a moving parcel; a parcel keeping its level kept a finite level after it left the grid. A
  test now covers it.

## Review findings

**Test Fairness round 1: FAIL, 16 of 105 unfair.** Two distinct causes, both fixed.

Thirteen of the sixteen were the same defect: `expect_error` asserted a lowercase fragment of
the `ValueError` message (`grid`, `start points`, `method`, `combined` and so on) while
`meta.md` only ever promised the exception. MetPy's own wording varies, and for at least one
case the natural repo phrasing ("Cannot specify both") would have failed the hidden assertion.
The helper now asserts the exception type alone; no message text is pinned anywhere.

The other three were genuinely unstated policies that the tests were right to want, so the
description gained them rather than the tests losing them: `trajectory_length` is missing
wherever the parcel is, a sample beyond the coverage of the density template adds nothing, and
neither does a sample whose weight is not a finite number.

The reviewer's five coverage suggestions were all added, and one of them found a real hole:
`meta.md` promised a `ValueError` for an unknown method but only `interpolate_to_track`
validated it, so `sample_trajectory(..., method='cubic')` silently interpolated linearly.
Method checking now lives in one helper both entry points call. The other four cover the
keyword-only contract, a conserved surface without a vertical coordinate, a non-monotonic
surface profile proving the first bracketing pair is taken, and an extension that keeps
conserving its surface. One test was renamed to match what it asserts
(`a_sample_on_the_level_does_not_cross_twice`).

All fifteen mutations are still killed after the rewrite, so nothing was traded away for
fairness.

**Test Fairness round 2: FAIL, 1 of 110 unfair.** `step_may_be_a_quantity` accepted a pint
hour where `meta.md` named no accepted step types. The sentence now says `step` is either a
timedelta or a quantity of time, which is the behaviour the reference always had. Round 2's
three coverage suggestions were added as well: the keyword-only contract on the other five
functions, a track read across the seam of a global grid, and a series that passes through the
level exactly (below, on, above and the reverse) to show one correctly directed crossing rather
than two.

**Test Fairness round 3: no unfair tests, five coverage suggestions.** All five were added:
descending longitude and descending time coordinates, a parcel started exactly on the pole
(the earlier pole test could have passed through an ordinary grid exit), an unbounded density
weight, and a sample below a layered template. The third one found the last real gap:
`interpolate_to_track` only compared longitude against latitude, so a `time` or `vertical`
array of the wrong length reached numpy instead of being rejected. Every quantity along a
track is now checked against the same shape, and `meta.md` says so.

One of the new fixtures was mine to fix rather than the code's: reversing the time coordinate
with `times=TIMES[::-1]` rebuilt the field's values against the new first stamp, so it was a
different field, not the same field on a descending axis. Reversing the finished DataArray with
`isel(time=slice(None, None, -1))` is the fixture that actually tests the axis direction.

**Test Fairness: the seam crossing needed a clause, not a deletion.** The antimeridian crossing
test I added the round before pinned that the two straddling samples are unwrapped to the short
arc before interpolating; interpolating the reported values directly puts the crossing on the
other side of the planet, and the description named neither. Unlike the degenerate surface
below, this behaviour is worth having: a crossing reported half a world away from where it
happened is simply wrong. So the sentence gained the shorter way round and the test stayed.
The rule of thumb that separates the two cases: state it when one reading is defensible and the
other is a bug, delete it when both readings are defensible.

**Test Fairness: the degenerate conserved surface was mine, and it was unanswerable.** The
round-13 coverage suggestion asked for a conserved surface with no bracketing pair at the
initial position, and I built one by making the profile constant and equal to the conserved
value at every level. That premise cannot be met honestly: the conserved value is read at the
start point, so it is always attainable there unless the profile is flat, and a flat profile is
a zero over zero root that the description says nothing about. My rule needs a strict sign
change on one side and therefore terminated, but retaining the level or taking an endpoint is
just as defensible. The test is deleted rather than patched, and the case it was reaching for is
already covered by the sloped surface that runs out of range as the parcel moves. A suggestion
that cannot be satisfied without inventing policy is a signal to decline it, not to invent the
policy.

Both of that round's suggestions were added and both already held. The haversine form is
naturally seam safe, since it takes the sine of the half difference, so a length across the
antimeridian equals the same run in the middle of the grid. Crossing positions wrap because the
span between samples is itself wrapped before interpolation.

**Test Fairness, three coverage suggestions after that.** All three were behaviour the
reference already had. A crossing level given in Pa against a series in hPa converts before
comparing, and nearest sampling stops at the edge of a field narrower than the trajectory
instead of snapping to it. The third asked for a projected density template, which is a test I
had deleted by accident: it went out with the three dimensional density cut even though the
projected case is two dimensional and still required, since the description says a projected
grid is read through its projection and density bins to the nearest grid point. Cutting a
requirement is a deliberate act and it has to be done with a scalpel; the projected test is
back, and it is the composition of two stated rules rather than a rule of its own.

**Test Fairness after the repair: 1 of 149 unfair, and it was my own new rule contradicting
itself.** The rewritten density paragraph promised that a parcel contributes its own elapsed
time, but the implementation still credited the step the parcel attempted and failed, so a
parcel that reached three samples was billed for three intervals instead of two. The reviewer
read the sentence, computed what it implies, and was right. A step now counts only where the
parcel reached both of its samples, and the sentence says so outright. Worth noting that this
came in with the fix for the batch: rewriting a rule under solvability pressure is exactly when
the prose and the code drift apart, and the panel caught it one round later.

The round's coverage suggestion was added as well, a conserved surface with no bracketing pair
anywhere, which keeps step zero and blanks the rest like every other immediate termination.

**Batch 1: 0 of 6, and the cause was five ambiguities, not one trap.** No test failed in all
six runs, which rules out a single undiscoverable requirement; instead five separate readings
each cost several runs, and every run tripped a different subset. The best run failed 5 of 152.
That is the many-small-pins shape, and the repair is to settle each reading in the description
rather than to soften the task.

Step zero was the biggest: `meta.md` said both "step zero is the start point" and "that sample
and every later one are missing", so a parcel that cannot take its first step at all was either
reported at its start or blanked entirely. Four runs chose blanking, which cost them three
tests each. The description now says step zero is always reported and termination only blanks
what follows.

Density counting was next. My rule gave a three hour parcel four hours of residence time
because every sample contributed, including the last. One agent read it that way, another read
the natural way, and the totals differ by a whole step. The rule is now the natural one, each
step contributing from the sample it starts from, and the description says a parcel contributes
its own elapsed time.

The `weights` type was never stated and the tests passed a DataArray wrapping a pint quantity,
which five runs could not consume. `meta.md` now names it as a quantity along the trajectory
such as a `sample_trajectory` result, the reference accepts a DataArray, a bare quantity or a
plain array, and the tests exercise two of those forms.

Two runs died on `RuntimeWarning: All-NaN slice` and `Mean of empty slice`, because the repo
promotes warnings to errors and a parcel set that has entirely terminated is a legitimate
all-missing reduction. That is a trap about numpy hygiene, not about trajectories, so the test
module now ignores RuntimeWarning.

The conserved-surface scan said "from its start", which is ambiguous on a descending pressure
axis; it now says the order the coordinate stores them.

Finally the three dimensional density requirement was cut outright. It broke three of six runs,
it is the least central thing in a trajectory package, and removing it removes a whole rule
from the contract rather than making it easier to guess.

**Solution Quality round 2 was stale.** The panel that came back reporting the two edge cases
had run against the 143-test artifact, before the fixes; both were already in the patch when it
was shown (`stamps.min()` / `stamps.max()` at `trajectory.py:224`, `.ravel()` at
`track.py:967`), and `meta.md` had already gained the sentences that state them. A re-run is
what settles it, so this round was spent making sure a fresh look finds nothing of that class.

Two things a reviewer would trip on were tightened even though both were correct. The track
sampler took its reference time as `stamps[0]`, which is arbitrary and cancels out of every
offset, but reads exactly like the first-versus-earliest bug that was just fixed a few lines
away; it is `stamps.min()` now. The conserved-surface closure was defined by rebinding a name
that starts as `None`, which works and lints clean but is the kind of cleverness that costs a
point on a skim; it is a `functools.partial` of `_surface_level` now.

The whole contract was then walked clause by clause against the code, and every stated rule has
an implementing line: the chronological default, track flattening, wrapping on all three
reporting functions, log pressure for fields and for the surface inversion, descending axes,
the periodic seam, the projection lookup, pole termination, nearest on every axis, one shared
method check, and keyword-only markers on every optional argument.

**Test Fairness round 12: no unfair tests, two coverage suggestions.** Both cover the
non-pressure vertical, which until now had only one test. A conserved surface on a height
coordinate is placed by linear interpolation, not logarithmic, and the fixture makes the two
readings differ by hundreds of metres; it also starts on a level whose first bracketing pair is
the second one scanned, so the scan rule is exercised on heights as well. A vertical velocity on
a height coordinate is a speed, checked in m/s and again in km/h to show the conversion is to
the coordinate's units per second rather than to anything pressure-specific. The log-pressure
mutation gained a kill from the pair, which is the point: the rule is conditional on the
coordinate, and a test that only ever sees pressure cannot tell a conditional apart from an
unconditional one.

**Test Fairness round 11: no unfair tests, three coverage suggestions.** All three added and
all three already held. A `start_time` outside the field's own times keeps step zero and then
terminates, which is the same rule as a start outside the grid. A two dimensional track whose
longitude, latitude, times and levels all share that shape flattens all four in the same order.
The third was the one worth having: a longitude coordinate that is both descending AND globally
complete, crossed at its seam. Nothing had exercised those two rules together, since the seam
tests were all ascending and the descending tests were all regional; the padded seam column has
to be appended at the descending end and the modulo mapping keyed off the smaller end for that
to work. It does, and the three seam and axis mutations all gained kills from it.

**Test Fairness round 10: no unfair tests, two coverage suggestions.** The first was added as
asked: a trajectory that stays entirely valid while the field being sampled runs out from under
it, so only the samples past the field's edge go missing.

The second asked for a moving parcel on a non-monotonic conserved surface to keep scanning
"from the parcel's current/start branch rather than switching to another root". That is a
different rule from the one in the description, which says the scan starts at the vertical
coordinate's own start and takes the first bracketing pair, so the test pins what the
description says instead. The fixture builds a profile with three roots at every position the
parcel visits and checks the level against the closed form of the lowest one, which a
branch-following or nearest-root solver would not produce. Implementing branch memory would
have meant changing the contract to satisfy an advisory note; the test is the right place to
settle it.

**Solution Quality round 1: PASS, 2 of 3 on both axes, two real defects named.** Both were
fixed rather than left as passing-grade blemishes.

The default `start_time` took `stamps[0]` and `stamps[-1]`, which is the first and last stored
value, not the earliest and latest time. On a descending time coordinate, which the task
explicitly supports, a forward run would have started at the END of the field and terminated
on its first step. It now takes the minimum and the maximum, and the description says earliest
and latest. This was hiding behind my own test: the descending-time case passed an explicit
`start_time`, which is what a fixture does when the author half-noticed an ambiguity and routed
around it instead of resolving it.

`interpolate_to_track` checked that every quantity along a track had the same shape but never
flattened, so two matching two-dimensional arrays died inside xarray on a dims mismatch rather
than producing the promised single `track` dimension. The inputs are ravelled now and the
description says a track of more than one dimension is flattened.

**Test Fairness round 9: FAIL, 1 of 142 unfair.** The crossing metadata test I added in round
8 asserted the storage dtype `datetime64[ns]`, and nanosecond precision is nowhere in the
description; another datetime unit carries the same meaning. The assertion now checks that the
dtype is a datetime kind at all. Adding a test to satisfy a coverage suggestion is exactly when
this slips in: the suggestion asked about metadata, and metadata is where representation and
contract are easiest to confuse.

Round 9's three suggestions were added: a track read directly on descending projected axes
rather than through integration, `sample_trajectory` over a Dataset mixing a steady 2-D field
with a time dependent layered one, and the shape of the spread result when no parcel is left.
The last needed a description clause first, because asserting that spread is in metres along a
`step` dimension was itself unstated; `trajectory_length` said metres and `trajectory_spread`
never did.

**Test Fairness round 8: FAIL, 3 of 137 unfair, and the reviewer was right.** The three
conserved-surface tests pinned the level the solver returns as an interpolation in the
logarithm of pressure, while `meta.md` attached log pressure only to interpolating the fields.
That is a separate decision, and the repo's own `interpolate_to_isosurface` decides it the
other way: `src/metpy/interpolate/grid.py:347` interpolates the returned coordinate linearly.
An implementer following the neighbour would have failed three exact-value tests for a reason
the description never gave.

The reference is not wrong to use log pressure here, and it is not free to change: the surface
sampler reads theta in log pressure, so inverting in anything else means
`sample_trajectory(traj, theta)` no longer returns the conserved value and
`conserved_surface_is_followed` breaks. The two have to agree. So the description now says the
bracketing levels are interpolated the same way the fields themselves are. Sibling precedent
beat my silence, exactly as `repo-sibling-precedent-is-a-fairness-standard` says it does.

Round 8's three coverage suggestions were added too, and one of them needed another sentence
rather than another test: asserting the units of a crossing position was itself unstated, so
`meta.md` now says crossings report longitude and latitude the way the trajectory does.

**Test Fairness round 7: no unfair tests, two coverage suggestions.** Both added and both
already held. The conserved surface is now exercised with a field that warms with time, so the
level the parcel sits on moves even though the parcel does not, and the wind varies with that
level: the horizontal path therefore depends on solving the surface at each stage's own TIME,
not only its own position, and the whole path is checked against `solve_ivp` on the reduced
system. The projected grid is exercised with both of its axes reversed. Neither test could pass
on a step-start solve or an ascending-only axis search, which is what the mutations confirm
(M9 1 to 2 kills, M4 22 to 26).

**Test Fairness round 6: no unfair tests, six coverage suggestions.** Five were behaviour the
reference already had: a `datetime.timedelta` step, a start beyond 180 matched into a regional
grid without making that grid cyclic, nearest sampling still refusing to reach outside the
field, a vertical velocity that varies in time being read at every stage like the horizontal
winds, and a projected density template. The sixth found a genuine inconsistency: parcel
positions and crossing positions were wrapped into [-180, 180) but the ensemble centre was not,
so two parcels straddling the antimeridian reported a centre of +180 while everything else in
the module reported -180. The centre is wrapped now and the description states the rule once,
for every longitude the module reports, instead of only for the trajectory variables.

**Test Fairness round 5: no unfair tests, three coverage suggestions.** All three added and
all three already held. A plateau of samples sitting exactly on the level still yields one
crossing in each direction, which is what the exact-as-above rule is for. Nearest sampling
snaps every coordinate, not only the horizontal ones; the fixture deliberately picks 880 hPa
and a two hour offset, both of which round to the same grid point whether closeness is measured
in pressure or in its logarithm, so the test does not quietly pin a reading the description
never gives. Negative counts are rejected by `parcel_trajectory` and, through it,
`extend_trajectory`.

**Description Quality round 1: FAIL, four comments.** Three were straight cuts: the
motivational opening sentence went, "the winds are DataArrays MetPy can parse" became "assume
parsed MetPy xarray inputs", and the ensemble centre is now "the spherical mean of the samples
still running" with the unit-vector definition kept as a short gloss rather than the whole
phrasing. The fourth asked for the Runge-Kutta rule to be softened to "a standard RK4
implementation is fine". That one was compressed, not softened: the stage-by-stage narration is
gone, but the scheme is still named, because the suite pins it. `solve_ivp` comparisons at 1e-8,
the stored-times test at 1e-9 and the within-step sampling test all fail on a lower order
scheme, and the Euler mutation kills 16 tests. Naming classical fourth order Runge-Kutta fixes
the stage times uniquely, so the trap stays discoverable while the prose loses 55 words. If the
check flags it again the contest is that sentence, with those tests as the evidence.

**Test Fairness round 4: no unfair tests, four coverage suggestions.** All four added. Three
covered behaviour the reference already had (an extension with a count below one, a position
that lands exactly on the far meridian and is reported as -180, and components whose grids
match in shape but not in coordinate values). The fourth was a genuine hole in the integration
path: the suite had uniform advection on a projected grid and nonuniform sampling on one, but
never Runge-Kutta stages reading a wind that varies across a projected grid. That test now
integrates through a wind linear in the grid's own x and compares against `solve_ivp` on the
same reduced system, with the projection evaluated inside the right hand side; it doubled the
kills for the ignored-projection mutation.

## Attempt history

1. Screened seven repos on metadata and churn; MetPy won on 8 branches and a clean exclusivity
   search. pyroomacoustics was dropped because issue #442 opened a live RT60 workstream two
   days before the base commit and the ISM core is a C++ extension.
2. Built the sampler and the integrator, checked the path against `solve_ivp` at 1e-14.
3. Split the sampler into `metpy.interpolate.track` and exposed `interpolate_to_track`, which
   is where it belongs and gives the task a second package.
4. Added the conserved-surface mode, residence time, crossings, spread and extension after the
   LOC check showed the integrator alone lands near 300 effective lines.
5. Ran the mutation battery, fixed the two weak fixtures and one unenforceable claim it found.
6. Test Fairness round 1: unpinned every error message, stated the three missing policies,
   added the five suggested tests, and fixed the unvalidated `method` argument they exposed.
7. Test Fairness round 2: stated the accepted step types and added the three suggested tests.
8. Test Fairness round 3 (advisory only, no unfair tests): added the five suggested coverage
   areas and closed the validation gap the third one exposed.
9. Test Fairness round 4 (advisory only): added the four suggested tests, including
   Runge-Kutta stages through a spatially varying projected wind.
10. Description Quality round 1: cut the preamble, shortened the input sentence, compressed the
    Runge-Kutta paragraph and renamed the ensemble centre, 891 words down to 816.
11. Test Fairness round 5 (advisory only): plateaus on a crossing level, nearest snapping on
    time and vertical, and negative counts for both entry points.
12. Test Fairness round 6 (advisory only): six more cases, one of which made the ensemble
    centre wrap its longitude like every other reported position.
13. Test Fairness round 7 (advisory only): a conserved surface that varies in time and a
    projected grid with both axes descending.
14. Test Fairness round 8: stated the surface inversion metric and the crossing position units,
    and added density after termination, crossing metadata and a mixed Dataset track.
15. Test Fairness round 9: unpinned the datetime precision, stated the spread units and
    dimension, and added three more cases.
16. Solution Quality round 1: made the default start time chronological and flattened
    multidimensional tracks, with a test for each.
17. Test Fairness round 10 (advisory only): sampling a field narrower than the trajectory, and
    a moving parcel on a three-root conserved surface holding the first bracketing pair.
18. Test Fairness round 11 (advisory only): a start time outside the field, a two dimensional
    track with every auxiliary array, and a descending global grid crossed at its seam.
19. Test Fairness round 12 (advisory only): a conserved surface and a vertical velocity, both
    on a height coordinate.
20. Solution Quality re-run: confirmed the two cited defects were already fixed, tightened two
    readability traps near them, and audited every contract clause against the code.
21. Batch 1 came back 0 of 6. Diagnosed five ambiguities from the run artifacts, settled each
    in the description, cut the three dimensional density requirement, and let the test module
    tolerate all-missing reductions.
22. Test Fairness: the new density rule counted the step the parcel failed to finish, against
    its own elapsed-time wording. Only completed steps count now.
23. Test Fairness (advisory only): restored the projected density test dropped with the three
    dimensional cut, plus a unit-converted crossing level and nearest sampling at the edge of
    a narrower field.
24. Test Fairness: deleted the degenerate flat-surface test I had added, and covered the
    antimeridian for both trajectory length and crossing positions.
25. Test Fairness: stated that a crossing between two samples straddling the seam interpolates
    the shorter way round.
