# feedback.md — acoular-reflecting-panels

## Summary

Olympus submission against `acoular/acoular` @ `b5a20cdbff51bb0ec7b281fc9b02192ad1516b0b`
(BSD-3-Clause, 645 stars, 98% Python, commit on the day of authoring). Adds specular reflection
paths to acoustic propagation: finite rectangular reflecting panels, image source path enumeration
with occlusion, and the wiring of that path set into the frequency domain steering vector, four
source models and the time domain beamformer.

Repo never used locally: absent from `Task*/problems/`, `Instructions/rejected/` and
`Instructions/Aprroved/`.

## Decisions and assumptions (autonomous run)

- **Repo pick.** The previous session in this folder killed `aerosandbox-area-rule` on the platform
  language gate and had cloned `acoular` as the replacement candidate, together with a working
  probe image. Kept that candidate after re-running the gates.
- **Gate results.** License BSD-3 (allowed). Stars 645. Last commit 2026-08-06. Primary language
  Python 977k bytes vs Cython 10k, so the language gate is safe (the failure mode that killed
  aerosandbox). Vanilla suite green offline as uid 1000 inside `olympus-base-python`:
  1291 passed / 141 skipped / 120 xfailed / 3 xpassed in 6 min.
- **Exclusivity.** `gh pr list` and `gh issue list`, all states, for `reflection`, `reflecting`,
  `ground`, `image source`, `mirror`, `boundary`, `hard wall`, `multipath`, `refraction`,
  `environment`: no hit touches reflecting surfaces. `grep -rni "reflect|image source|mirror|ground
  plane" acoular/` only hits the Householder mirroring inside `spiral_sphere`, which is unrelated.
- **Shape.** O-Algorithm-correctness with composite span: one geometric kernel
  (`ReflectiveEnvironment.paths`) driving six consumers.
- **Scope calls made during the build:**
  - Dropped a stratified refracting environment in favour of reflection: the eigenray solver has no
    exact discrete output to pin fairly.
  - Panels are finite, two sided and opaque rather than infinite one sided half spaces. That keeps
    occlusion, panel extent and the intermediate reflection point check as real, testable rules.
  - Deliberately did NOT extend `BeamformerCleant`, `BeamformerTimeTraj`,
    `MovingPointSourceDipole`, `MovingLineSource` or `SphericalHarmonicSource`. The CLEAN
    deconvolution model and the moving grid beamformer have no unambiguous multipath definition, so
    extending them would have created hidden or unfair requirements. `meta.md` enumerates exactly
    which consumers honour panels, and no test touches the others.
  - The direct term of `SteeringVector.transfer` still goes through `calcTransfer`, and the direct
    block of every source model is untouched, so an environment without panels is bit identical to
    before. That is what keeps the repo's own `pytest-regtest` snapshots green.

## Verification

- **Oracle.** An independent Fermat-principle check (`scipy.optimize.minimize` over the reflection
  points constrained to the panels, 40 restarts) on 300 random two panel geometries at second
  order: 702 path checks, 44 with a realizable specular path, **0 mismatches** on path length,
  reflection points and the geometric validity classification.
- **Regressions.** Base mode returns the identical 1291 passed on the base state and on the solution
  state, so the reference introduces no regression and removes no coverage.
- **New tests.** 219, all failing on base, all passing with the solution, deterministic across
  repeated runs.
- **Set partition.** Checked by collection diff, not by eye: the repo collects 1782 node ids, base
  mode selects 1555, new mode selects 227, and the two sets are disjoint and exhaustive.
- **Mutation proof.** Eleven defects implemented in the reference one at a time and reverted, all
  re-measured against the final suite: closed interval occlusion (53 tests killed), consecutive
  repeats kept (13), no occlusion (9), spreading from the direct distance (6), rounded impulse
  response (4), autopower per path (3), reversed mirror chain (2), `image_velocity` mirroring like a
  position (2), amplitude zeroed on invalid paths (2), last reflection point only (1), blocked direct
  path kept in the transfer (1). No mutation survives; baseline clean at 219.

## Known deviations from the skill targets

- **Effective LOC 346** (raw 800) across 5 files, measured with
  `.claude/hooks/effective_loc_check.py`. That clears the sprint hard floor of 250 and the 2-file
  floor, but is under the older 450 design target the hook still warns at. acoular's numpydoc
  convention means the raw lines compress heavily once docstrings are stripped, and every attempt to
  close the gap ran into a fairness wall: the remaining consumers (CLEAN-T, the moving grid
  beamformer, the moving dipole) have no unambiguous multipath semantics. The last 38 lines went
  deliberately, when moving sources were dropped for solvability. Chose 346 lines of defensible logic
  over padding. For reference, the approved `pvlib-loss-attribution` in `Instructions/Aprroved/`
  measures 327 by the same hook.

## Difficulty prediction and what to watch in the first batch

Predicted 10 to 20 percent. The image source method itself is textbook, which keeps the problem off
the unsolvable floor, but eight interdependent rules have to land together: mirroring in encounter
order (only non parallel panels expose a reversed chain), the strict interior crossing test (the
obvious closed interval blocks every reflection at its own panel), validity of every intermediate
reflection point rather than only the last, occlusion of the direct path, the canonical sequence
ordering, amplitude reported independently of validity, the reference distance staying direct, and
the mirrored velocity of a moving source. On top of that the path set has to be wired into six
consumers.

The failure mode to watch is the opposite one: 230 exact assertions across sixteen API surfaces is a
lot of contract for one session. If the first batch lands at zero, check whether the misses are
scattered (keep the design) or all agents stop at the same surface, most likely the time domain
beamformer or the moving source, in which case narrow the consumer list in `meta.md` rather than
soften any rule.

## Test Fairness round

An automated Test Fairness pass returned FAIL with 3 of 146 tests unfair, all pinning behaviour the
description does not state:

- `test_contains_rejects_nan` asserted that a NaN column is not contained. NaN handling is nowhere in
  the prompt and nothing in the repo establishes it. **Removed.** The behaviour is still covered
  behaviourally: a path whose reflection point is missing must not exist, which
  `test_transfer_vanishes_when_everything_is_blocked` and the source and beamformer silence tests
  already assert.
- `test_plain_environment_image_is_the_source` and `test_plain_environment_image_velocity_is_the_vector`
  passed a nonempty panel sequence to a plain `Environment`, which has no panels, and pinned silent
  identity where rejecting the sequence is just as defensible. **Retargeted at the empty sequence**,
  which is the only sequence a plain environment ever produces and whose identity behaviour follows
  from the stated mirroring rule.

Six advisory coverage suggestions were all addressed, adding 13 tests: trait defaults, a vectorized
`crossing` call mixing valid, endpoint, parallel and same side segments, an impulse response whose
upper interpolation neighbour falls past the buffer, back face incidence and impedance amplitude,
and exact echo equivalences for `LineSource` and `PointSourceDipole` replacing the coarse
"differs by more than 1e-6" checks. The most valuable was the `BeamformerTimeSq` autopower rule,
which the description states but no test asserted: with one microphone and two paths the r_diag
output must cancel to zero, which it only does if the autopower is formed from the microphone's
summed contribution. Removing paths from that sum was implemented as an eleventh mutation and kills
exactly that test. An impulse source does NOT discriminate it, because the two paths land on
different samples and the cross term vanishes; the test uses a continuous source instead.

## Second Test Fairness round

A re-check returned FAIL on 1 of 156: `test_impedance_defaults_to_none` pinned `None` as the unset
sentinel, which neither the description nor the repo singles out. **Removed** rather than described:
what matters behaviourally is that a panel with no impedance uses `reflection_factor` at every
angle, and `test_factor_at_without_impedance_is_the_reflection_factor` already asserts exactly that
on a default panel, so no coverage was lost and the description did not have to grow.

All three advisory suggestions were taken, adding 4 tests: a zero-length `edge2` (the symmetric
partner of the existing `edge1` case), two endpoint-opacity cases at the `paths` level (a direct
segment ending on a panel, and a reflection whose point sits on the shared edge of a neighbouring
coplanar panel, neither of which may count as blocked under the strict crossing rule), and
second-order integration in both time-domain consumers: `BeamformerTime` with a floor and a ceiling
resolves all five arrivals at exact sample indices and amplitudes, and `PointSource` places the
earliest second-order echo at the 5 m folded path rather than the 7 m one.

## Verify Solution failure: acoular has mixed line endings

The platform rejected the first submission with `Failed to apply solution.patch: error: patch
failed: acoular/__init__.py:24`. The artifacts were not at fault and the file was not the problem
either; the repository is:

```
git ls-files --eol acoular/__init__.py acoular/environments.py
i/crlf  w/crlf   acoular/__init__.py
i/lf    w/lf     acoular/environments.py
```

20 of acoular's tracked files are stored CRLF and the rest LF. `acoular/__init__.py` was the only
CRLF file the solution touched, and it was the only file that failed to apply, while the five LF
files applied fine. So the platform's checkout does not preserve the CR, and any hunk carrying CRLF
context against that file is unapplicable there. Two attempts and what they showed:

1. **Zero context (`git diff -U0`) for that one file.** It applies on both a CRLF and an
   LF-normalised tree, but `git apply` then places the insert by search rather than by line number
   and put the two import lines 110 lines further down, inside an unrelated import block. Rejected.
2. **Drop `acoular/__init__.py` from the solution entirely.** Both new classes stay public in
   `acoular.environments`, which is where the module autosummary already lists them, and the
   solution now touches only LF-stored files. `meta.md` names the module so the location is stated.

The tests reach the classes through `ac.environments.ReflectingPlane` rather than a module-level
`from acoular.environments import ...`: the latter turns base mode into a single collection error
instead of 164 individually failing test nodes, which would break the F2P check.

Losing the top-level export changes what the repo's own suites discover.
`tests/cases/test_environments_cases.py` uses `inspect.getmembers(ac)`, so `ReflectiveEnvironment`
is no longer picked up by the environment regression test, and base mode with the reference
solution is 1299 rather than 1301. The two `pytest-regtest` snapshots are still shipped in
`test.patch` on purpose: an agent who does add the export (the natural thing to do) would otherwise
get a base-mode regression for a file they cannot provide. Both behaviours pass.

## Fourth Test Fairness round: the incidence sign was a real spec gap

FAIL on 5 of 164, all one root cause. The description said `incidence` gives "the cosine of the
angle between the incoming ray and the normal", but a panel stores ONE oriented normal
(`edge1` x `edge2`), so for a ray arriving on the front face the ordinary dot product is NEGATIVE.
The implementation takes the absolute value, which is the only convention that works for a panel
reflecting on both faces, and nothing said so. The reviewer was right that two defensible
implementations differ here.

Fixed in `meta.md`, not by deleting tests: incidence is "always taken as a non-negative value, so it
runs from zero at grazing to one along the normal and either face of a panel gives the same cosine
for the same slant". That one clause makes all five assertions stated, and it is the convention the
impedance formula needs, since `(Z*c-1)/(Z*c+1)` is only meaningful for a non-negative cosine.

Two new tests pin the convention head on: swapping a panel's edges flips its normal and must leave
the incidence unchanged, and no incidence value on a slanted panel may be negative.

The other three suggestions were taken as well. A `PointSourceDipole` whose monopole separation
points ALONG the panel normal now checks the echo equals the mirrored dipole scaled by the direct
over reflected distance and **negated**, which is what proves both monopole offsets were mirrored
rather than only the dipole centre; the previous case used an x-directed separation parallel to the
floor, where that sign never appears. `BeamformerTime` gained exact reflected-arrival weights for
`inverse` and `true location`, so all four steer types are covered. And a second-order
`MovingPointSource` case checks the order-2 residual equals the sum of two plain moving sources on
the twice-mirrored trajectories, matching to 2e-16.

## Verify Solution: the repo generates tests for the new classes

The second Verify Solution run passed the baseline and the F2P set but failed on 8 tests that were
in neither: `test_instancing`, `test_set_traits`, `test_trait_dependencies` and `test_load`,
parametrised over `ReflectingPlane` and `ReflectiveEnvironment`. They pass with the solution, but
they do not exist on base, so they cannot be part of the regression set, and they are not in the new
test file either.

This is unavoidable for this repo rather than a mistake: `tests/utils.py get_all_classes` walks every
module of the package with `pkgutil.walk_packages` and collects every class defined there, so any new
public class anywhere in `acoular` is parametrised into those four tests. Not exporting them from
`acoular/__init__.py` does not help, because that walk does not go through the top-level namespace.

Of the two remedies the harness offers, moving them into a set is better than skipping them: they are
real coverage of the new classes (instantiation, trait setting, digest dependencies, pickling). So
`test.sh` new mode now runs the new file plus `test_classes.py` and `test_pickle.py` under
`-k "reflection_paths or ReflectingPlane or ReflectiveEnvironment"`, and base mode excludes the same
two names with `-k "not ReflectingPlane and not ReflectiveEnvironment"`. On base the selection
matches nothing extra, so base mode is the identical 1291 in both states and new mode is 210 failing
nodes; with the solution, new mode is 218 passing. Every test now belongs to exactly one set.

## Fifth Test Fairness round: clean, two advisory suggestions taken

No unfair tests. Both coverage suggestions added, 5 tests:

- **Vectorized direction APIs.** `mirror_direction` and `image_velocity` were only ever exercised one
  column at a time. Both now take a three-column input against an offset panel and a two-panel
  sequence, asserting shape and every reflected component, including the zero vector.
- **Mixed path batches.** One `paths` call over two sources and two receivers straddling an
  impedance-carrying panel now produces all three outcomes at once: the diagonal pairs reflect
  normally, the off-diagonal pairs have their direct segment blocked by the panel while still
  reporting amplitude one, and their reflected path has no crossing at all so its points and its
  impedance amplitude are `nan`. Three tests cover the validity matrix, the reflection points, and
  the same configuration through `paths_at`. This is the only place where blocked and missing paths
  coexist in a single batch, which is what makes it a real broadcasting check.

## Sixth Test Fairness round: clean, three advisory suggestions taken

No unfair tests. All three suggestions added, 4 tests, and one weak assertion replaced:

- **Exact r_diag cross terms.** The two microphone autopower test only checked that the output
  exceeded 1e-6. Deriving the exact value from separate single microphone runs does not work,
  because `max_sample_delay` and therefore the buffer alignment depend on the microphone set. The
  identity that does hold exactly uses two microphones placed symmetrically about the grid point, so
  their contributions are equal: `phi = 2r`, the autopower is `2r^2`, and the removed and kept
  outputs are `2r^2` and `4r^2`. The test asserts `2 * r_diag == non r_diag` to 1e-12, and it is
  not vacuous because it also asserts the output is non zero. Per path autopower breaks it, and the
  mutation now kills two tests instead of one.
- **Material factors in composite sources.** `PointSourceDipole`, `LineSource` and
  `MovingPointSource` only proved an echo exists or is omitted. Each now checks that the echo with
  `reflection_factor = -0.4` equals `-0.4` times the echo with factor one, which pins both the
  magnitude and the phase inversion. Residuals are 3.5e-9, 1.1e-15 and 8.3e-17.
- **Digest under container mutation.** Appending to `planes` invalidates the environment digest and
  extends the sequence list, and that is asserted. In place mutation of a `corner` array does NOT
  invalidate the panel digest, which is standard traits behaviour for `CArray` and is true of every
  other acoular class, so no test pins it: asserting invalidation there would demand behaviour the
  repository itself does not provide.

## Seventh Test Fairness round: clean, two advisory suggestions taken

No unfair tests. Both suggestions added:

- **Digest inheritance.** Setting the inherited `Environment.c` now has its own assertion that the
  environment digest changes; it was only covered indirectly by the repo's generic trait setter.
- **Third order missing point propagation.** The previous propagation test had two reflection levels,
  so a NaN never had to travel more than one step. The new case uses three panels, a floor, a ceiling
  and a wall at x = 3, where the LAST crossing exists at (3, 0, 2.6) but the middle one does not,
  because the segment from the second image at (0, 0, 5) to that point runs from z = 5 down to
  z = 2.6 and never reaches the ceiling at z = 2. The middle point and the first point are both NaN,
  every incidence entry is NaN, the path is invalid, and the travel distance is still the well
  defined image distance sqrt(41).

## Eighth Test Fairness round: a suggestion found a real bug

No unfair tests. The pickle suggestion turned up a genuine defect rather than a missing test.

`ReflectiveEnvironment.digest` listed `planes` among its dependencies, and `internal.digest`
stringifies every dependency it finds. `str([<ReflectingPlane object at 0x7f...>])` embeds the
object ADDRESS, so two environments with identical panels hashed differently, and an unpickled
environment never matched the original. Removing `planes` from that list fixes it: `plane_digest`,
which is maintained by the observer on `planes.items.digest`, already changes whenever the list or
any panel changes, so nothing is lost and the digest becomes address independent. Round trips now
preserve it for both classes.

An intermediate attempt made `plane_digest` a derived `Property` instead. That is cleaner in
principle but fails the repo's own `test_trait_dependencies`, which walks every dependency name and
cannot resolve `planes.digest` through a `List` trait, so the `Str` plus observer form of the
sibling `MergeGrid` is kept. Worth recording: that failure was invisible in the authoring worktree
because of stale bytecode and only appeared on the freshly checked out validation tree, which is why
every result quoted here comes from the latter.

Three tests added. The impedance amplitude was only ever checked through `paths`, so it now also has
end-to-end assertions through `SteeringVector.transfer`, `impulse_response` and `BeamformerTime`,
all against the same `(2c-1)/(2c+1)` value at `c = 1/sqrt(1.25)`. A separate test pins that
`crossing` reports the supporting-plane intersection at (1, 0, 0) even though it lies outside a
0.25 half-width panel, that `contains` rejects that point, and that the direct path is therefore not
blocked, keeping the plane and the rectangle clearly distinct. Two round-trip tests cover a panel
with non-default geometry, a negative factor and an impedance, and a two-panel environment with a
non-default `max_order` and speed of sound, checking traits, digest, sequences and `paths` output.

## Ninth Test Fairness round: clean, four advisory suggestions taken

No unfair tests. All four added:

- **Per microphone validity in a source generator.** A source over a 0.25 half width panel with two
  microphones: the reflection point is on the panel for the first and off it for the second, so the
  first channel gains an echo while the second is bit identical to the panel free run. This is the
  only place the per channel masking inside `PointSource` is exercised.
- **Impedance in a source generator.** The angle dependent factor previously only reached
  `transfer`, `impulse_response` and the beamformer. A `PointSource` echo with an impedance panel now
  equals `(2c-1)/(2c+1)` times the echo with a unit factor, at the oblique cosine
  `2 / sqrt(4/9 + 4)` that the two thirds specular split gives. Residual 8e-17.
- **Digest and geometry after editing an installed panel.** Assigning a new `corner` to a panel that
  is already inside an environment changes the panel digest, the environment digest, and the computed
  reflection point, which moves from z = 0 to z = 0.5. Note that IN PLACE mutation of the array, as
  in `corner[0] = ...`, does not invalidate anything: that is standard traits behaviour for `CArray`
  and is true of every other acoular class, so no test pins it.
- **Non symmetric r_diag.** The symmetric case only exercised the factor of two special case.
  Feeding the SAME two microphone steering vector with data that is non zero in a single channel at a
  time yields each microphone's summed contribution under identical alignment, so the removed output
  can be compared against `clip(2 * r1 * r2, 0)` for unequal distances and unequal signals. Matches
  to 1.3e-15. Deriving the contributions from separate single microphone beamformers does not work,
  because `max_sample_delay` depends on the microphone set.

## Description trimmed to 780 words

Requested cap of 780, down from 899, with nothing dropped. Every rule the suite asserts is still
stated: the module the classes live in, the edge validity rule and its `ValueError`, the normal from
the edge cross product, the four vectorized geometry methods and their shapes, strict interior
crossings with `nan`, two sided and opaque panels, `factor_at` with the impedance formula, the
sequence enumeration and its ordering, encounter order, `image` and `image_velocity`, the three
`paths` outputs and their order, `paths_at`, the backward walk and `nan` propagation, the
non-negative face independent incidence cosine, the existence and blocking rules including the
direct path, `impulse_response` with its fractional split and truncation, the base class API, the
digests, the transfer term with its direct reference, the four source models, and the two time
beamformers with the per microphone autopower.

The 119 words came out of wording only: redundant articles, "of shape (P, N, M)" to "(P, N, M)",
"the empty tuple of the direct path" to "the direct path's empty tuple", "in the same module" to
"same module", and similar. Longest paragraph is now 115 words, still inside the 150 limit.

## Tenth Test Fairness round: two suggestions taken, one declined

No unfair tests.

- **Geometry mutation beyond a translation.** The reviewer caught that
  `test_replacing_a_panel_edge_updates_...` only replaced `corner` despite its name. Renamed to say
  corner, and a real edge test added: replacing `edge2` with `(0, 0, 4)` turns the floor into the
  plane y = -2, so the normal goes from `(0, 0, 1)` to `(0, -1, 0)`, a point that was off the panel
  is now on it, mirroring the origin gives `(0, -4, 0)` instead of itself, and both digests change.
- **Impulse response accumulation collisions.** A floor and a ceiling equidistant from a source and
  receiver both at z = 1 give two distinct valid paths of the same length sqrt(5), so both deposit
  into samples 2 and 3. Three tests: equal factors double the deposit, opposite factors of equal
  size cancel it to exactly zero leaving only the direct arrival, and 0.75 with -0.25 leaves half.
  Nothing else in the suite exercised two paths writing the same sample pair.
- **Declined: malformed input shapes.** The description defines no behaviour for non `(3, N)` input
  and the implementation does not validate it, so tests there would pin an unstated policy, which is
  exactly what earlier rounds flagged as unfair. Left untested deliberately.

## Eleventh Test Fairness round: clean, three suggestions taken

No unfair tests. All three added or extended:

- **Crossing endpoint coordinates.** `test_crossing_excludes_the_end_point` only checked the flag;
  it now also asserts the returned coordinate column is entirely `nan`, matching the start point
  case and what the description states for either endpoint.
- **Per microphone masking in `LineSource`.** The same 0.25 half width panel setup as the
  `PointSource` case: the first receiver keeps its echo while the second is bit identical to the
  panel free run. Catches a global rather than per receiver mask in the second source model, where
  the arrays additionally carry a sub source axis.
- **Impedance through `LineSource`.** The non point sources were only ever scaled by a constant
  `reflection_factor`. A single sub source line, which has one well defined incidence angle, now
  checks the echo equals `(2c-1)/(2c+1)` times the unit factor echo at the same oblique cosine used
  for `PointSource`. Residual 2.5e-16. A multi sub source line cannot be checked this way, because
  each sub source meets the panel at its own angle, so the echo is not a scalar multiple.

## Twelfth Test Fairness round: two tests, one spec fix

No unfair tests.

- **Per microphone masking in the beamformer.** Exciting one channel at a time through the SAME two
  microphone steering vector keeps the alignment fixed, so the reflective and panel free runs are
  directly comparable: the microphone whose specular point lands on the 0.25 half width panel differs
  from the panel free run, while the microphone whose point falls off it is bit identical. That is
  the mask being applied per microphone rather than globally, before the sum.
- **Second order for the two remaining source models.** `LineSource` with a single sub source has one
  well defined image per sequence, so its order two residual equals the sum of two plain line sources
  at the twice mirrored locations (0, 0, 4.5) and (0, 0, -3.5), to 4.4e-16. The dipole needs the
  extra `rm / dist` factor its normalization carries, so its residual equals the same two mirrored
  dipoles each scaled by the direct distance over that path's length, to 8.2e-9. Both were only
  covered at first order before.
- **Impedance singularity, closed in the description.** `(Z * c - 1) / (Z * c + 1)` divides by zero
  when `Z * c = -1`, reachable only with a negative impedance. A normalized surface impedance is
  positive for a passive surface, so the description now says the `impedance` is positive, which
  removes the case rather than inventing a convention for it. No test: with `Z > 0` and a
  non-negative cosine the denominator is always at least one. Note the repo runs pytest with
  `filterwarnings = error`, so a divide by zero there would have been an error, not a `nan`.

## Thirteenth Test Fairness round: one gap closed, one declined again

No unfair tests.

- **Impedance validation.** The previous round called the impedance positive in the description but
  nothing enforced or tested it, which is exactly the asymmetry that gets flagged. `factor_at` now
  raises a `ValueError` for an impedance that is not positive, matching how the panel edges and a
  negative `max_order` already behave, and the description says so. Three tests: zero and negative
  through `factor_at`, and a negative one reaching the error through `paths`, each wrapping
  construction and use together so eager or lazy validation both pass.
- **Declined again: malformed input shapes.** Nothing in the description defines behaviour for input
  that is not `(3, N)`, and the implementation does not validate it. Adding tests there would pin an
  unstated policy, the same reason it was declined in the eleventh round. If the checker keeps
  raising it, the right fix is a description sentence plus validation, as was just done for the
  impedance, not tests against undefined behaviour.

## Fourteenth Test Fairness round: two taken, one partly declined

No unfair tests.

- **Rotated finite rectangle.** Containment was only ever checked on axis aligned panels. The slanted
  panel now has its own cases, addressed through its own `corner + u * edge1 + v * edge2`
  parameterisation: inside at the centre and both extreme corners, and outside just beyond each of
  the four local edges. Blocking follows: a segment through the panel centre is blocked, the same
  segment offset past the first edge is not, which separates the infinite supporting plane from the
  finite rectangle on a non axis aligned panel.
- **Impedance through the dipole and the moving source.** Both resisted the scalar linearity check
  that worked for `PointSource` and `LineSource`, and for a real reason. The dipole's two monopoles
  sit about 7e-8 m apart but its output is their difference scaled by `rm / dist`, order 1e7, so the
  tiny difference in their incidence angles survives amplification: the measured residual against a
  single scalar factor was 0.020 on a 0.045 peak. A moving source sweeps a range of angles by
  construction. The fix is geometry, not tolerance: putting the source, the dipole axis and the
  microphone on one vertical line above the panel makes every reflection normal incidence, so the
  factor is exactly `(2 - 1) / (2 + 1)`, and both echoes then match a third of the unit factor echo,
  to 3.1e-9 and 1.5e-16.
- **Partly declined: input pair boundaries.** Empty batches are well defined and now tested for both
  `paths` and `paths_at`, which return the expected `(P, 0, M)` and `(P, 0)`. Mismatched source and
  receiver counts are not: nothing in the description defines them, so a test would pin numpy's
  broadcasting behaviour as an API contract.

## Fifteenth Test Fairness round: both taken, including the one declined last time

No unfair tests.

- **Dynamic path validity during motion.** Every earlier moving source test had the reflection either
  always valid or never valid. A 0.1 m panel a metre below a passing source now catches the
  reflection only while the specular point sweeps across it: the echo is exactly zero for the first
  2469 samples, non zero for 863, and exactly zero again for the remaining 762. A global rather than
  per emission time mask cannot produce that.
- **Matched pair batch sizes, previously declined.** Last round I left this out because the
  description said nothing about it, so a test would have pinned numpy broadcasting as a contract.
  The right fix, as with the impedance two rounds ago, is to define the behaviour rather than test
  around it: `paths_at` now raises a `ValueError` when the two sides hold different numbers of
  points, the description says so, and both the reflective and the plain environment are tested. This
  also removes a silent trap, since a single receiver against several sources used to broadcast
  quietly instead of complaining.

## Sixteenth Test Fairness round: two taken, one declined a third time

No unfair tests. One of the two turned out to be a real robustness bug.

- **Degenerate propagation distance.** Coincident emitting and receiving points made
  `impulse_response` divide by zero. The repo runs pytest with `filterwarnings = error`, so that
  numpy `RuntimeWarning` is an ERROR here, not a silent `inf`: any agent whose implementation hit it
  would see a crash rather than a bad number. A zero length path now deposits nothing, which is
  stated, and two tests cover it: `paths` still reports the geometric zero distance and marks the
  path valid, while the impulse response holds only the reflected arrival.
- **Sequence and index validation.** An index past `path_sequences`, or a sequence naming a panel
  that does not exist, already raises `IndexError` through ordinary list indexing. That needed no
  code, only a sentence and three tests, so the behaviour is now contract rather than accident.
- **Declined a third time: malformed array shapes.** Enforcing `(3, N)` would need every public
  geometry method split into a validating wrapper and a private core, because the internals legitimately
  call `contains` and `crossing` with the three dimensional arrays the path walk builds. That is
  roughly twenty lines of plumbing and fourteen description words against a hard 780 word cap, to
  guard input the description already pins shape by shape. If a future round wants it, the cap has to
  move first.

## Seventeenth Test Fairness round: two taken, shapes declined a fourth time

No unfair tests.

- **Impulse response pair independence.** The two source, two receiver case was only ever a shape
  check. Every one of the four cells is now compared against the response computed for that pair
  alone, and a second test asserts no two cells are equal, so a transposed or broadcast deposit
  cannot pass. Nothing new to specify: it is the stated `(N, M, num_samples)` layout being checked
  numerically rather than structurally.
- **Negative panel indices.** `self.planes[-1]` used to wrap silently, so a sequence naming panel
  `-1` mirrored about the LAST panel instead of complaining. Sequences from `path_sequences` are
  never negative, so this only reached hand written input, but wrapping is the worst of the three
  options. It now raises an `IndexError`, on both the reflective and the plain environment, and the
  description says so in the sentence that already covered an out of range path index.
- **Declined a fourth time: malformed coordinate shapes.** Same reasoning as the last three rounds.
  Every public geometry method would need a validating wrapper around a private core, because the
  path walk legitimately calls `contains` and `crossing` with three dimensional arrays, and the
  description has no words to spare under the 780 cap. The shapes are already stated per method; what
  is missing is only an error contract for violating them, which nothing in the suite needs.

## Solution Quality round: both findings were real, both fixed

The Solution Quality pass returned PASS with 2 of 3 on both axes and named two concrete defects.
Both were correct and both are fixed.

- **NaN leak through arithmetic masking.** `paths` reports a `nan` amplitude when a panel carries an
  impedance and the reflection point is missing, and five consumers masked non existent paths by
  MULTIPLYING by the boolean: `amplitude * valid` in `PointSource` and `LineSource`,
  `gain * valid` in `PointSourceDipole`, `gain[index] * exists[index]` in `MovingPointSource`, and
  `amp *= gain * exists` in `BeamformerTime`. `nan * False` is `nan`, so a single missing impedance
  path poisoned the whole output. Reproduced before fixing: a source over a 0.25 m impedance panel
  with the microphone at (3, 0, -1), where the direct segment misses the finite rectangle but the
  image never crosses the plane, gave 1024 of 1024 NaN samples and 59 of 59 NaN beamformer samples.
  All five sites now use `np.where(valid, amplitude, 0.0)`. Six tests cover it, one per consumer plus
  the `paths` precondition, and reverting a single site fails exactly its own test.
- **`paths_at` ignored `apparent_r`.** The base implementation computed a plain Euclidean norm, so a
  flow environment that overrides `apparent_r` had `paths` flow corrected and `paths_at` not.
  Delegation through the outer product would be O(N squared) and unusable for the moving source,
  which asks for one distance per microphone and sample. Instead the base grew a `_pair_r` hook, the
  pairwise counterpart of `apparent_r`, and `UniformFlowEnvironment` overrides it with the same
  convection formula written elementwise, which stays O(N). Verified: `paths_at` now equals the
  diagonal of `apparent_r` for `ma = 0.3` flow and for the plain environment. No new tests, because
  the description says nothing about flow environments and a test there would pin unstated behaviour.

## Eighteenth Test Fairness round: one unfair assertion, one more silent wraparound

FAIL on 1 of 230, and the finding was right.

- **Third order incidence, over pinned.** In the partial chain test I asserted all three incidence
  entries are `nan` even though the LAST reflection point is finite at (3, 0, 2.6). My implementation
  gives `nan` there for a defensible reason, that the incoming ray to that point starts at the
  missing middle point, but the description never says a later finite point's incidence is discarded,
  and retaining it is equally defensible. **Assertion removed.** The rest of that test, the exact
  last point, the two `nan` earlier points, the image distance sqrt(41) and the invalid flag, is
  untouched, and `test_incidence_is_missing_without_a_reflection_point` still covers the plain case.
- **Negative path index.** `reflection_points(-1, ...)` and `incidence(-1, ...)` wrapped to the LAST
  sequence through ordinary list indexing, the same silent wraparound fixed for panel indices in the
  previous round. Both now raise an `IndexError`, the description broadened from "a negative panel
  index" to "any negative index" at a cost of minus one word, and two tests cover it.
- **Declined a fifth time: malformed coordinate shapes.** Unchanged reasoning. Enforcing `(3, N)`
  needs a validating wrapper around a private core for every public geometry method, because the path
  walk calls `contains` and `crossing` with three dimensional arrays, and the description has no room
  under the cap. Shapes are already stated per method; only the error contract for violating them is
  missing, and no test needs it.

## Batch 1: the API-shape coin flip, and what it does and does not tell us

Four Nova runs, 0 of 4, but the batch is **void as a difficulty measurement**. Every single agent
implemented `path_sequences` as a traits `Property` returning a list, so 14 tests per run died on
`TypeError: 'list' object is not callable` before touching any behaviour. Nova_Nova_2's evaluator
flagged it as unfair with `was_mentioned_in_description: false`.

This is the API-shape coin flip from the project memory, and I walked into it: every other API in the
description carries parentheses and arguments, `path_sequences` alone read as a noun, and acoular is
traits-heavy enough that a `Property` is the idiomatic guess. Four for four is not four agents making
a mistake, it is one unstated choice. Fixed by writing `path_sequences()`.

Two genuine over-pins came out of the same logs and are also fixed. A transfer comparison at
`rtol=1e-12` was missed by 1.9e-7, which is precisely acoular's own `_transferCoreFunc` casting its
phase argument to `float32`: the test was demanding that an implementation reuse that internal quirk
rather than compute the transfer correctly, so four transfer comparisons moved to `rtol=1e-6`. And
the moving-source window test called anything above `1e-12` an echo while measuring the difference of
two independent simulations, which carries dust at `1e-11`; the threshold is now `1e-6`, still three
parts in a million of the echo peak.

**What the batch does say.** Discounting the unfair 14, the residual is the moving source. All four
runs produced no reflected moving-source contribution at all, around 1e-11, not a wrong one. That is
a surface being skimmed rather than a hard problem being lost, so the description now names the
mechanism: the emission time is solved against the image of the trajectory, whose velocity turns with
`image_velocity` rather than with `image`. That is a fairness clarification, not an easing; the rule
is unchanged.

**Solvability is not yet demonstrated.** Holding each agent's code fixed and only removing the unfair
failures, Nova_Nova_2 lands four tests short, Nova_Nova_3 five, Nova_Nova_4 six, Nova_Nova_1 eighteen
plus a baseline regression it caused by making the delay arrays three dimensional without updating
the CLEAN branch that indexes them. A re-run is required. If the next batch is again zero with the
misses concentrated on the moving source, the right move is to drop `MovingPointSource` from the
consumer list in `meta.md` and delete its tests, narrowing scope rather than softening a rule; that
costs about 55 effective lines and leaves the submission near 330, still clear of the 250 floor.

**False positives: none possible this round.** No agent passed, so there is no passing implementation
to audit against the requirements. The FP gate remains owed on the next batch.

## Solvability, measured rather than projected

The previous section closed by projecting residuals from the batch logs. Projection is not evidence,
so this round measured it. Each agent's `solution-patch.patch` was replayed on a clean base worktree
with one mechanical rewrite, turning its `path_sequences` Property into a method, which is exactly
what the corrected description now asks for, and then run against the final suite.

| Agent | new mode | base mode | Outcome |
| --- | --- | --- | --- |
| Nova_Nova_2 | **227 passed, exit 0** | **1291 passed, exit 0** | **PASS** |
| Nova_Nova_3 | 2 failed, 225 passed | — | fail |
| Nova_Nova_4 | 4 failed, 223 passed | — | fail |
| Nova_Nova_1 | 10 failed, 217 passed | — | fail |

**1 of 4, 25 percent, inside the 40 percent cap**, with the runners-up two and four tests short.
That is the shape a well calibrated problem should have. Three changes got it there, and each was
made for a fairness reason rather than to buy a pass:

- **Moving sources out of scope.** All four runs produced no reflected moving-source signal at all,
  around 1e-11, so the surface was being skimmed rather than attempted. The honest reading of four
  identical whiffs is that the requirement was not landing, and the fix for that is to remove it, not
  to hint at it. `MovingPointSource` is out of `meta.md`, the `MovingPointSource.result` change is
  reverted, and its 13 tests are deleted. Cost: 38 effective lines, leaving 346.
- **`test_plain_image_rejects_a_negative_panel_index` deleted.** It applied the index rule the
  description states for `ReflectiveEnvironment` to a plain `Environment`, which the description does
  not discuss and which has no panels to index.
- **Both cross-process `digest` assertions deleted.** This was Nova_Nova_2's *only* failure, and it
  was the test that was wrong. The description says a digest "changes with their traits", which is a
  sensitivity claim, not a promise that two equal-trait objects in different processes hash alike.
  More decisively, acoular's own `MergeGrid` builds its digest from member object addresses and fails
  the identical assertion, so an agent following the closest repo precedent is punished for it. The
  reference still keeps its address-free digest, which is the better implementation; it just is not
  something the tests may demand. The trait, sequence and `paths` round-trip assertions all stay.

**Caveat, stated plainly.** This is a replay, not a fresh batch. It holds each agent's code fixed and
removes one wording bug, so it is strong evidence that the problem is solvable in a session and it is
not the same thing as a clean batch. The next real batch has to confirm it.

**False positives: none possible this round.** No agent passed the batch as run, so there is no
passing implementation to audit. Nova_Nova_2's replay pass was hand-inspected anyway, since a replay
pass is exactly where a false positive would hide: it enumerates sequences without adjacent repeats,
mirrors in encounter order, walks reflection points backwards, tests occlusion on strict interior
crossings, and applies per-panel factors, so it satisfies the requirements rather than merely the
assertions. The FP gate is still formally owed on the next batch.

## Nineteenth Test Fairness round: one real gap, one stale finding, shapes declined a sixth time

No unfair tests.

- **Dipole per-microphone masking. Real gap, now closed.** `PointSource`, `LineSource` and
  `BeamformerTime` each had a test proving the validity mask is applied per receiver rather than
  globally; `PointSourceDipole` did not. Added `test_dipole_masks_the_echo_per_microphone` over a
  0.25 m panel with an upright dipole axis, where the first receiver's specular point lands on the
  panel and the second's falls off it. Confirmed it discriminates by mutation: collapsing the mask in
  `PointSourceDipole` to `valid.all(-1)` fails **only** this test, so nothing else in 220 covered it.
  The dipole axis is upright rather than the default x here, because a receiver directly below the
  source sits in the null of an x-directed dipole and the comparison would be measuring noise.
- **Shadowed dipole impedance test. Already gone.** The suite had two
  `test_dipole_echo_uses_the_impedance_amplitude` definitions when the off-axis case was superseded by
  the normal-incidence one in round 25; the shadowed copy went with the moving-source deletion in
  round 32. Verified rather than assumed: 220 `def test_` lines, 220 unique names, 220 collected. No
  meta-test guards this, because a test that only inspects its own module would pass on base and
  break the F2P requirement that every new test fails there.
- **Declined a sixth time: malformed input shapes.** The suggestion is conditional on malformed
  arrays having intended error semantics. They do not. Nothing in the description defines behaviour
  for input that is not `(3, N)`, and enforcing it would need a validating wrapper around a private
  core for every public geometry method, since the path walk legitimately calls `contains` and
  `crossing` with three-dimensional arrays. Unequal `crossing` batch lengths are the same case; the
  one place where an unequal batch was a silent trap, `paths_at`, was given a stated `ValueError` back
  in round 26. Testing the rest would pin numpy broadcasting as an API contract.

## Twentieth Test Fairness round: the incidence NaN was genuinely unstated

FAIL on 1 of 222, and the finding is right.

- **`test_incidence_is_missing_without_a_reflection_point`.** The description pinned `nan` for
  missing reflection-point coordinates and for the impedance amplitude, but never for the incidence
  cosine itself, and the base repository has no incidence API to establish a convention. Zero or an
  omitted entry would have been just as defensible. This is the same class as the third-order
  incidence assertion removed in round 30; that one was cut because the behaviour was genuinely
  arguable, whereas this base case is behaviour the suite needs. **Stated instead of deleted**: the
  incidence sentence now ends "and is `nan` where its own reflection point is", eleven words, taking
  the description to 764 against the 780 cap. The test is untouched, and the passing agent already
  satisfied it, so nothing about solvability moves.
- **Crossing a segment lying in the plane. Taken.** A segment with both endpoints on the plane was
  not covered; only the start-on-plane, end-on-plane and parallel-off-plane cases were. It follows
  from the stated rule, since such a segment both starts and ends on the plane, and it is the one
  degenerate case where an implementation dividing by a zero denominator could return something
  other than `nan`. Added; the reference and the passing agent both hold.
- **Declined: plain `Environment` with a nonempty sequence.** Round 9 already removed two tests for
  pinning exactly this. A plain environment has no panels, so mirroring about a named panel is either
  identity (there is nothing to mirror about) or an `IndexError` (the panel does not exist), and the
  description settles neither. The global index rule it cites governs the path INDEX argument, not
  the contents of a hand-written sequence. Stating it would cost words the 780 cap does not have.
- **Declined: malformed coordinate shapes, seventh time, but the earlier reason was wrong.** Six
  previous rounds declined this on the grounds that enforcing `(3, N)` needs a validating wrapper
  around a private core for every geometry method, because the path walk calls `contains` and
  `crossing` with three-dimensional arrays. That reasoning does not hold: those internal arrays are
  `(3, N, M)`, so a plain `shape[0] != 3` check passes them and no split is needed. It would have
  been about ten lines.

  The real reason to decline is different and stronger. Shape validation is an unstated requirement
  that the one implementation known to pass this problem does not implement, so adding it would take
  the measured pass rate from 1 of 4 to 0 of 4 and make the submission unsolvable. An advisory
  suggestion does not outrank the solvability gate. If a future round wants it, it has to arrive with
  a description sentence and a fresh batch, not as a test bolted onto a suite whose only passing
  implementation it breaks.

## Twenty-first Test Fairness round: a real coverage hole, and shapes declined an eighth time

No unfair tests.

- **NaN masking in `transfer` and `impulse_response`. Real hole, closed.** The Solution Quality round
  fixed the `nan * False` leak in five consumers and gave each a regression test, but those five were
  the source models and the time beamformer. The two remaining consumers of a `nan` amplitude were
  never checked. Probed before writing anything: both are already correct, returning finite output
  equal to the plain-environment result, so this is missing coverage rather than a second bug.
  Two tests added, and they were mutation-priced rather than assumed:
  - `test_transfer_ignores_a_missing_impedance_path` **discriminates**. Rewriting the transfer mask
    from `np.where(valid, contribution, 0)` to `contribution * valid` fails this test and only this
    test out of 223.
  - `test_impulse_response_ignores_a_missing_impedance_path` **does not**, and that is worth saying
    plainly rather than claiming a kill. The same mutation there survives, because the deposit
    selects by the `hit` mask before the weight is ever read, so a `nan` weight on a non-existent
    path is never touched. It is structurally safe, which is why the Solution Quality pass listed
    five sites and not this one. The test is kept as a regression guard on that structure, not as a
    discriminator.
- **Declined an eighth time: malformed coordinate shapes.** Unchanged from the previous round, and
  the reason is still the solvability gate rather than implementation cost. The suggestion is
  conditional on the API promising a particular error for input that is not `(3, N)`. It does not:
  the description states the shapes each method takes and says nothing about violating them. Adding
  the tests would introduce an unstated requirement that the only implementation measured to pass
  this problem does not satisfy, taking the pass rate from 1 of 4 to 0 of 4. Stating it first and
  re-running a batch is the only order that works, and there are 16 words left under the cap.

## Twenty-second Test Fairness round: one taken, shapes declined a ninth time

No unfair tests.

- **Single panel at a higher order. Taken.** The no-adjacent-repeats rule was covered by an invariant
  test over generated sequences and by the exact two- and three-panel enumerations, but never by the
  case where it does the most visible work: one panel with `max_order` above one still yields only
  `[(), (0,)]`, because every longer tuple would repeat that panel. One line, and it reads as the
  contract rather than as an invariant derived from the output.
- **Declined a ninth time: malformed coordinate shapes.** Same conditional as the last three rounds,
  and the answer is still no, for the same reason: the description defines no error for input that is
  not `(3, N)`, so the tests would introduce an unstated requirement that the only implementation
  measured to pass this problem does not satisfy, moving the rate from 1 of 4 to 0 of 4. The order
  that would work is a description sentence first, then a fresh batch to confirm agents still clear
  it. There are 16 words left under the 780 cap, which is enough for the sentence but not for the
  batch this late.

## Twenty-third Test Fairness round: the empty-batch pair, stated rather than dropped

FAIL on 2 of 68, both the empty-batch tests, and the finding is right. They came in at round 25 on a
coverage suggestion about input pair boundaries, and I took them without adding anything to the
description. Accepting `N = 0` is a real boundary contract: an implementation that satisfies every
stated non-empty behaviour could reasonably reject an empty point set or fall over inside a
reduction, and neither the description nor the base repository singled the case out.

What is unstated is narrower than the flag suggests. The two tests only assert output SHAPES, and
those shapes follow from the already-stated `(P, N, M)` and `(P, N)` forms once `N = 0` is allowed.
So the whole gap is the word "accepted", and one clause closes it: `paths` and `paths_at` "both
accept an empty batch, giving a zero-length point axis", eleven words, taking the description to 774
against the 780 cap.

**Stated rather than deleted, for the same reason as the incidence clause three rounds ago.** Two
earlier rounds argued that the right fix for an unstated boundary is to define the behaviour, not to
test around it, and that is what was done for the impedance sign, the `paths_at` unequal-batch error
and the incidence `nan`. Deleting here would also throw away coverage a previous round explicitly
asked for, which is how a suite starts oscillating between reviewers. Both tests are untouched, the
passing agent already satisfied them, and no patch changed, so the validation matrix from the
previous round still stands.

That leaves 6 words under the cap. If a further round demands another stated rule, something has to
be traded out by wording rather than by dropping a tested behaviour.

## Alignment check: the IndexError clause was under-scoped and in the wrong paragraph

WARNING, not a failure, and both halves of it were right.

The clause read "An index outside `path_sequences()`, or any negative index, raises an `IndexError`",
and it sat at the end of the blocking and `impulse_response` paragraph, which is the one API family
it does not govern. It also named no methods, so `image` and `image_velocity` rejecting an unknown or
negative panel index was left to inference even though two tests require it.

Rewritten and moved to the paragraph that introduces the index-taking APIs: "On a
`ReflectiveEnvironment` an index outside `path_sequences()`, or any negative or unknown one, raises
an `IndexError` from `reflection_points`, `incidence`, `image` and `image_velocity`."

**The scoping prefix is the part that matters, and the first draft got it wrong.** Without "On a
`ReflectiveEnvironment`", the sentence collides with the paragraph that says `image` and
`image_velocity` are on a plain `Environment` too. A plain environment has no panels, so every
nonempty sequence names an unknown one, and the reference returns the position unchanged there
rather than raising. That would have been a description contradicting its own reference solution,
which is worse than the vague clause it replaced. Round 34 had already declined to define plain
environment behaviour for a nonempty sequence, on the grounds that identity and `IndexError` are both
defensible; the prefix keeps that decision intact.

Paid for by wording, not by dropping anything: "in a straight line" became "straight", "the
amplitude factor of a reflection" became "a reflection's amplitude factor", and "are offered by a
plain `Environment`" became "are on a plain `Environment`". 779 words against the 780 cap, longest
paragraph 135. No test and no patch changed; the previous validation matrix stands.

## Batch 2 (Nova x5): solvable at 1 of 5, and the one blocker was my own regression

Raw batch 0 of 5, but two agents were a single test away and one of those failures was mine.

| Agent | Verdict | Failures | Cause |
| --- | --- | --- | --- |
| Nova_Nova_4 | FAIL_TEST_MISMATCH | 1 | **my test.** `rtol=1e-12` on a plain-versus-reflective transfer comparison |
| Nova_Nova_1 | FAIL_MISSED_REQUIREMENT | 1 | its `__setattr__` check misses the traits init path, so a negative `max_order` is accepted |
| Nova_Nova_5 | FAIL_MISSED_REQUIREMENT | 2 | `IndexError` in its own beamformer on a blocked direct path, plus the transfer tolerance |
| Nova_Nova_2 | FAIL_MISSED_REQUIREMENT | 13 | `out[b, m] +=` indented outside the path and microphone loops |
| Nova_Nova_3 | FAIL_MISSED_REQUIREMENT | 28 | each output block restarts from the first sample index |

**The float32 trap, reintroduced by me.** Round 31 moved four transfer comparisons off `rtol=1e-12`
because acoular's `_transferCoreFunc` casts its phase argument to float32, so any implementation that
computes the direct term in float64 differs from the legacy path. Three rounds ago I added
`test_transfer_ignores_a_missing_impedance_path` for a coverage suggestion and wrote `rtol=1e-12` in
it, walking straight back into the trap I had already documented. Nova_Nova_4 missed by 5.06e-7 and
Nova_Nova_5 by 1.8e-6, and Nova_Nova_4's evaluator flagged it exactly right:
`agent_blame_unfair: true`, `blocker_type: verifier`, difficulty "unfair".

Fixing only that one line would have been the shallow repair. The error is bounded by float32 epsilon
times `k * r`, so I computed it for every plain-versus-reflective transfer comparison in the suite:

| test | k*r | float32 bound |
| --- | --- | --- |
| `test_transfer_matches_the_plain_environment_without_panels` | 42.4 | 5.1e-6 |
| `test_transfer_omits_an_invalid_reflection` | 18.3 | 2.2e-6 |
| `test_transfer_ignores_a_missing_impedance_path` | 66.0 | 7.9e-6 |

All three exceed the `rtol=1e-6` that round 31 chose, so the two older ones had been passing on luck,
not on margin. All three are now `rtol=1e-5`, which covers the bound at every geometry the suite uses
and is still three orders of magnitude tighter than any real defect: a wrongly included reflected
term shifts the result by about 0.08 relative. Verified by mutation rather than asserted - dropping
the validity mask so invalid paths contribute still fails both comparison tests at 1e-5. The tests
that compare against an analytic expected value stay at 1e-6, because their direct term has zero
phase and carries no float32 error.

Measured after the fix, by replaying every agent patch on a clean base worktree:

| Agent | new mode | base mode | Outcome |
| --- | --- | --- | --- |
| Nova_Nova_4 | **232 passed, exit 0** | **1291 passed, exit 0** | **PASS** |
| Nova_Nova_1 | 1 failed, 231 passed | - | fail, negative `max_order` |
| Nova_Nova_5 | 1 failed, 231 passed | - | fail, its own `IndexError` |
| Nova_Nova_2 | 12 failed, 220 passed | - | fail |
| Nova_Nova_3 | 28 failed, 204 passed | - | fail |

**1 of 5, 20 percent, inside the 40 percent cap**, and this is a real batch rather than the property
to method rewrite that batch 1 needed. Nova_Nova_1's and Nova_Nova_5's residuals are their own bugs
against explicitly stated requirements, which is the right kind of failure to be left with.

## FP check: CLEAN, with one finding worth recording

Nova_Nova_4 is the only passer, so the whole gate rests on it.

- **No test gaming.** Its patch touches five production files plus one line of
  `tests/cases/test_environments_cases.py`, adding its class to `ENV_SKIP_DEFAULT`. That is
  legitimate: it exported the class from `acoular/__init__.py`, which makes the repo's regtest
  discover it and demand a snapshot that cannot exist for a new class. It is the same accommodation I
  handled by not exporting. No hidden test touched, no expected value hardcoded, no fixture constant
  anywhere in the diff.
- **The algorithm is real.** Lexicographic `product` with an adjacency filter, mirroring in encounter
  order, a backward walk that recomputes the prefix image at each step, occlusion as
  `crossed & contains(crossing)`, incidence as `|dot(normal, incoming)| / |incoming|`.
- **Differential against the reference on 40 random geometries** (off-axis panels, mixed reflection
  factors and impedances, orders 1 and 2, 2 emitters by 3 receivers): travel distance 0 of 1044
  differ, amplitude 0 of 1044, reflection points 0 of 3420, incidence 0 of 1140. Exact agreement on
  every quantity the description defines.

**The finding:** validity differs in 9 of 1044, always the same direction, reference valid and
Nova_Nova_4 blocked, always on a first-order path. Cause isolated: the reflection point lies on its
own panel, and its `crossing` uses an exact sign test with no tolerance, so a signed distance of
about 1e-17 with the wrong sign reads as a crossing and the path self-blocks. My reference uses
`_REFLECTION_TOL = 1e-9`.

This is not a false positive. Nova_Nova_4 implements the stated rule; it is fragile to floating point
on geometry that is not exactly representable. It matters that **every panel in my suite is
axis-aligned with round coordinates**, so the reflection point's signed distance is exactly zero and
the fragility never shows. That is an author blind spot in fixture design, recorded here.

**I am deliberately not adding an off-axis test for it.** The description says nothing about a
tolerance, and it should not: any test that separated the two implementations would pin an unstated
numerical policy, and it would break the only implementation measured to pass, taking the batch to
0 of 5. No current test depends on the tolerance either, which is the neutral and fair position to be
in. The right place for this is a note to whoever hardens the problem next, not a test bolted on now.

## Batch 3 (Nova x5): two cheat verdicts caused by the environment, and proof of saturation

Platform result 2 of 5 solves, with Nova_Nova_1 and Nova_Nova_3 graded **PASS_CHEATED**.

### The cheating was my environment's fault, and it is fixed

Both cheats are the identical edit: adding `ac.ReflectiveEnvironment` to `ENV_SKIP_DEFAULT` in
`tests/cases/test_environments_cases.py`. The chain is mechanical. All five agents exported the new
classes from `acoular/__init__.py`, which is the natural thing to do. That makes
`tests/cases/test_environments_cases.py` discover the class through `inspect.getmembers(ac)`, which
adds two `pytest-regtest` parametrizations, which fail with "snapshot not recorded" because no
snapshot can exist for a class that did not exist. **The agent has no legitimate way to produce that
snapshot.** Two of the five ran the raw suite, saw the phantom failure and suppressed it; the other
three never ran that file and were spared. It was a coin flip, not a character difference.

Worse, I had already seen this and called it wrong. Batch 2's passer made the same edit and I wrote
it up as a "legitimate accommodation". The grader's rubric is explicit that modifying test discovery
is manipulation, and the rubric is the authority. My call was wrong.

**Fix: ship the two snapshots in `test.patch`.** Recorded them by temporarily exporting the classes
and running `--regtest-reset`, then reverted the export. They are byte-identical to the plain
`Environment` snapshots, which is exactly the stated contract that an environment without panels
behaves as before, so they are implementation-independent: any correct solution reproduces them.
Measured before and after on an exporting agent's tree:

| snapshots present | `pytest tests/regression/test_environments.py` |
| --- | --- |
| no | **2 failed**, 9 passed, 1 skipped |
| yes | **11 passed**, 1 skipped |

The incentive is gone. The files are inert for the reference, which does not export, and the
partition is unchanged: 1555 + 232 = 1787, nothing in neither set, nothing in both.

I had shipped these snapshots once before and deleted them as "vestigial" when I dropped
`acoular/__init__.py` from the solution. They were vestigial for MY reference and load-bearing for
every agent, which is the distinction I missed.

### The problem is now too easy, and the evidence says it is saturated

With the phantom failure removed from the equation, replaying all five patches with their test-registry
edits stripped:

| Agent | new mode |
| --- | --- |
| Nova_Nova_1 | 232 passed |
| Nova_Nova_2 | 232 passed |
| Nova_Nova_3 | 232 passed |
| Nova_Nova_4 | 232 passed |
| Nova_Nova_5 | 2 failed (occlusion enumerates L segments, not L+1) |

**4 of 5, 80 percent, double the 40 percent cap.** Fixing the cheat honestly makes the pass rate
worse, because the two cheaters had working implementations.

Before concluding, I looked for a fair discriminator by differencing every passer against the
reference on 40 random OFF-AXIS geometries plus a 25-geometry consumer-layer probe:

| quantity | Nova_1 | Nova_2 | Nova_3 | Nova_4 |
| --- | --- | --- | --- | --- |
| travel distance | 0/1044 | 0/1044 | 0/1044 | 0/1044 |
| amplitude | 25/1044 | 0/1044 | 0/1044 | 0/1044 |
| reflection points | 0/3420 | 0/3420 | 0/3420 | 0/3420 |
| incidence | 114/1140 | 0/1140 | 0/1140 | 0/1140 |
| impulse response | 0/4800 | 0/4800 | 0/4800 | 0/4800 |
| validity | 9/1044 | 9/1044 | 9/1044 | 9/1044 |

Four independent implementations agree with each other and with the reference on essentially every
quantity the description defines. The three divergence classes are all unusable as discriminators:

- **Validity, 9 of 1044, identical in all four.** The self-blocking float fragility from the batch-2
  FP check. A test for it takes 4 of 5 to **0 of 5**, and when four independent implementations agree
  against mine, mine is the outlier, not the standard.
- **Transfer, 126 of 200.** float32 phase noise, already ruled unfair in batch 2.
- **Digest strings.** Implementation-specific by nature, not testable.

Only Nova_1's incidence and amplitude gap is a real defect, and testing it would move 4 of 5 to
3 of 5, which is still 60 percent.

**This is the specified-feature difficulty ceiling.** Twenty-three fairness rounds each added an
explicit clause, and the cumulative description is now complete enough that a competent agent
transcribes it. 224 tests did not make it harder; they made it more precisely specified. Adding more
tests against the same spec cannot restore difficulty, and there is no room to add scope: the
description is at 779 words against a hard 780 cap, and the one pre-designed hardening I could reuse,
the moving-source consumer cut in batch 1, needs roughly 40 words to state.

The artifact is correct, fair, deterministic, FP-clean and no longer induces cheating. It is too easy,
and the fix for that is a scope decision rather than another authoring round.

## Attempt history

| Round | What changed | Result |
| --- | --- | --- |
| 1 | Kernel (`ReflectingPlane`, `ReflectiveEnvironment.paths`), `SteeringVector.transfer`, `PointSource` | 95 tests green, 180 effective LOC |
| 2 | Angle dependent `impedance`, `incidence`, `impulse_response`, `PointSourceDipole`, `LineSource` | 236 effective LOC |
| 3 | `BeamformerTime` multipath delay and sum, new numba kernel `_delayandsumreflect` | 287 effective LOC, 2 regressions from a readonly broadcast array, fixed |
| 4 | `paths_at`, `image`, `image_velocity`, `mirror_direction`, `MovingPointSource` | 351 effective LOC, 142 tests |
| 5 | Patch generation: the repo stores CRLF, so `text=True` capture silently stripped the CRs and the patch would not apply. Regenerated with byte capture | both patches apply on a clean base |
| 6 | `test_time_beamformer_places_the_direct_arrival` passed on base (used only `Environment`). Retargeted at `ReflectiveEnvironment` | all fail on base |
| 7 | Added the back face reflection, `BeamformerTimeSq` and mirrored trajectory equivalence tests; relaxed three error assertions from message matching to `ValueError` only, because the message wording is not part of the contract | 146 tests |
| 8 | A base mode run reported two `ReflectiveEnvironment` regtest failures on the base state. Cause was a stale background validation script that re-applied `solution.patch` to the validation worktree, not the artifacts. Re-ran on a freshly created worktree: base mode on base is byte for byte the vanilla result | validation matrix clean |
| 9 | Test Fairness FAIL on 3 of 146. Dropped the NaN policy test, retargeted the two plain environment image tests at the empty sequence, and added 13 tests from the coverage suggestions | 156 tests, all fair by construction |
| 10 | Second Test Fairness FAIL on 1 of 156. Removed the `impedance is None` sentinel test and took all three advisory suggestions | 160 tests, no unfair assertions remaining |
| 11 | Verify Solution rejected the patch on `acoular/__init__.py`, the only CRLF file the solution touched. Dropped it; the classes stay public in `acoular.environments` | patch applies on both a CRLF and an LF-normalised checkout |
| 12 | Third Test Fairness FAIL on 5 of 160: three plain-`Environment` helpers, error timing for a negative `max_order`, and a `ReflectingPlane()` built without the geometry the description requires. Stated the base-class API in `meta.md`, moved construction inside the raises block, gave the panel real edges, and took the three advisory suggestions | 164 tests |
| 13 | Fourth Test Fairness FAIL on 5 of 164, all from the unstated incidence sign. Stated the non-negative cosine convention in `meta.md` and took the four advisory suggestions | 170 tests |
| 14 | Verify Solution flagged 8 repo-generated parametrizations for the new classes as belonging to neither set. Routed them into new mode and excluded them from base mode via `-k` | base mode identical in both states, new mode 230 fail on base and 238 pass with the solution |
| 15 | Test Fairness clean. Took both advisory suggestions: vectorized `mirror_direction` and `image_velocity`, and a mixed batch where valid, blocked and missing-reflection paths coexist | 175 tests |
| 16 | Test Fairness clean. Took all three advisory suggestions: an exact symmetric-microphone r_diag identity replacing the weak threshold, reflection-factor linearity for the three composite sources, and digest invalidation on an appended panel | 179 tests |
| 17 | Test Fairness clean. Took both advisory suggestions: a digest assertion for the inherited speed of sound, and a third-order path where the middle crossing is missing while the last one exists | 181 tests |
| 18 | Test Fairness clean. The pickle suggestion exposed a real digest bug: `planes` in `depends_on` put object addresses into the hash. Removed it, added impedance end-to-end, crossing-versus-bounds and round-trip tests | 187 tests, digest now stable across processes |
| 19 | Test Fairness clean. Took all four advisory suggestions: per-microphone echo masking, impedance through `PointSource`, digest and geometry after editing an installed panel, and a non-symmetric r_diag identity via single-channel excitation | 191 tests |
| 20 | Description trimmed from 899 to 780 words on request, by tightening wording only; no rule, signature, shape or convention removed | 778 words, longest paragraph 114 |
| 21 | Test Fairness clean. Added a real edge-replacement test (the old one only changed `corner`) and three impulse-response collision cases; declined the malformed-shape suggestion as unstated policy | 195 tests |
| 22 | Test Fairness clean. Extended the end-point crossing assertion to the NaN coordinates, and added per-microphone masking and impedance propagation for `LineSource` | 197 tests |
| 23 | Test Fairness clean. Added per-microphone masking in `BeamformerTime` and second-order equivalences for `LineSource` and `PointSourceDipole`; closed the impedance singularity by stating the impedance is positive | 200 tests, description 778 words |
| 24 | Test Fairness clean. Made a non-positive `impedance` raise `ValueError`, stated it, and added three tests; declined the malformed-shape suggestion a second time as unstated policy | 203 tests, description 778 words |
| 25 | Test Fairness clean. Added slanted-rectangle containment and blocking, empty-batch shapes for both path APIs, and normal-incidence impedance checks for the dipole and the moving source; declined the mismatched-count half as unstated | 210 tests |
| 26 | Test Fairness clean. Added dynamic per-emission-time masking for the moving source, and defined plus tested the `paths_at` unequal-batch `ValueError` that was declined as unstated last round | 213 tests, description 780 words |
| 27 | Test Fairness clean. Fixed a divide-by-zero in `impulse_response` for coincident points (an error, not a warning, under this repo's pytest config), made the `IndexError` on a bad path index contract, and declined the shape-validation family a third time on cap grounds | 218 tests, description 772 words |
| 28 | Test Fairness clean. Made the impulse-response pair-independence check numerical rather than structural, made a negative panel index raise `IndexError` instead of wrapping to the last panel, and declined the shape-validation family a fourth time | 222 tests, description 777 words |
| 29 | Solution Quality PASS at 2/3 + 2/3 named two real defects. Fixed the `nan * False` masking leak in all five consumers (six regression tests) and gave `paths_at` a `_pair_r` hook that `UniformFlowEnvironment` overrides so it follows `apparent_r` | 228 tests |
| 30 | Test Fairness FAIL on 1 of 230: the third-order test pinned an all-NaN incidence policy the description does not state. Removed that one assertion, and made a negative path index raise `IndexError` instead of wrapping to the last sequence | 230 tests, description 776 words |
| 31 | Batch 1 (Nova x4) came back 0/4, but 14 of every run's failures were one unstated API shape: `path_sequences` as a property. Pinned it as `path_sequences()`, relaxed a float32-driven `rtol=1e-12` transfer pin and a `1e-12` float-dust threshold, and named the moving-source emission-time mechanism | batch void, re-run needed |
| 32 | Measured solvability by replaying all four agent patches with the property-to-method rewrite. Dropped moving sources from scope (13 tests, 38 LOC), the plain-environment negative-index test, and both cross-process digest assertions, the last because acoular's own `MergeGrid` fails them. Re-measured the mutation proof and removed two vestigial regtest snapshots from `test.patch` | **Nova_Nova_2 passes both modes: 1/4 = 25%**, 219 tests, 346 effective LOC, 755 words |
| 33 | Test Fairness clean. Added the missing per-microphone mask test for `PointSourceDipole`, the one consumer of four without one, and confirmed by mutation that it is the only test catching a global mask. The reported shadowed dipole test no longer exists; verified 220 defined, 220 unique, 220 collected. Declined the shape-validation family a sixth time | 220 tests, replayed Nova_Nova_2 still passes at 228 |
| 34 | Test Fairness FAIL on 1 of 222: incidence `nan` for a missing reflection point was never stated. Stated it in `meta.md` rather than deleting the test, 11 words. Added the coplanar-segment crossing case. Declined the plain-environment nonempty sequence (two defensible readings, no words left) and shape validation, the latter because it would break the only implementation known to pass | 221 tests, 764 words, Nova_Nova_2 still passes at 229 |
| 35 | Test Fairness clean. Closed the last NaN-masking hole: `transfer` and `impulse_response` were the two consumers of a `nan` amplitude without a regression test. Both were already correct, so this is coverage, not a bug; the transfer test discriminates under mutation, the impulse-response one does not and is recorded as a structural guard. Declined shape validation an eighth time on solvability grounds | 223 tests, Nova_Nova_2 still passes at 231 |
| 36 | Test Fairness clean. Added the one-panel-at-higher-order enumeration, the most direct statement of the no-adjacent-repeats rule. Declined shape validation a ninth time, unchanged reasoning | 224 tests, Nova_Nova_2 still passes at 232 |
| 37 | Test Fairness FAIL on 2 of 68: the two empty-batch tests, taken at round 25 without a description clause. Only N=0 ACCEPTANCE was unstated, since the shapes follow from the stated forms, so one 11-word clause closed it. Tests and patches unchanged | 224 tests, 774 words, 6 under the cap |
| 38 | Alignment WARNING: the `IndexError` clause named no methods and sat in the `impulse_response` paragraph. Moved it to the index-taking APIs, named all four, and scoped it to `ReflectiveEnvironment` so it does not contradict the reference's plain-environment behaviour. Funded by three wording trims | 779 words, longest paragraph 135, patches unchanged |
| 39 | Batch 2 (Nova x5) raw 0/5, but Nova_Nova_4's only failure was my own `rtol=1e-12` regression of the round-31 float32 lesson. Recomputed the float32 bound for all three plain-versus-reflective transfer comparisons, found all three above the old 1e-6, and set them to 1e-5; mutation-verified they still kill an unmasked invalid path. FP check clean on the passer, including a 40-geometry differential against the reference | **1/5 = 20%**, 224 tests, Nova_Nova_4 passes both modes |
| 40 | Batch 3 (Nova x5) returned 2 PASS_CHEATED, both the same `ENV_SKIP_DEFAULT` edit forced by a snapshot that cannot exist for a new class. Shipped the two regtest snapshots in `test.patch`, removing the incentive (2 failed -> 11 passed on an exporting tree). Replay with test edits stripped shows 4/5 = 80%, and a 40-geometry differential shows all four passers agree with the reference on every defined quantity | cheating fixed; **too easy at 80%**, saturated |
| 41 | Word cap lifted on request. Restored the `MovingPointSource` consumer cut in batch 1: emission time solved per path against the image of the trajectory, position mirroring with `image` and velocity turning with `image_velocity`. Added 9 moving-source tests, shipped the regtest snapshots, and re-verified no regression in the repo's own moving-source suites | 232 tests, 809 words, 390 effective LOC; every batch-3 passer now fails 5 tests |
| 42 | Solvability of the hardened version established by graft rather than projection: the same 50-line, spec-strict `MovingPointSource.result` addition takes all four batch-3 implementations from 5 failures to 240 passed, base mode clean. A first graft written against one agent's broadcasting failed on two others, confirming the documented `(3, N)` shapes are what makes it portable | **solvable, 4/4 graft; fresh batch still needed for the rate** |
| 43 | Hardened the moving-source surface from one additive requirement into three interdependent ones: `conv_amp` must be applied per path with that path's own image velocity, and the trajectory velocity must turn with `image_velocity` rather than `image`. Both offset-panel tests initially tripped the coordinated self-blocking blind spot (129/4096 structural mismatches), so the geometry was made exactly representable while keeping the panel offset that separates `image` from `image_velocity` | 235 tests, 243 in new mode; **graft still passes on all 4 agents**, absence now costs 8 tests |
| 44 | Stacked four more interdependent traps on the moving-source surface: per-microphone gain, block-size invariance, receiving-time advance across blocks, and the amplitude factor recomputed at each emission position rather than once per block. Two mutations initially read as no-ops (one was literally `if n > 0` inside the loop, one was masked by stale bytecode), so each was re-priced until it actually killed a test. Absence of the moving surface now costs 10 tests | 238 tests, 246 in new mode; **graft still passes 4/4 at 246** |
| 45 | Took all three coverage suggestions. Second-order moving reflections now work and are pinned: the earlier one-index artifact was the self-blocking float issue again, fixed by the same exactly-representable geometry. Shape validation added and stated, now that the word cap is lifted removes the only reason it was declined ten times. Empty-batch `impulse_response` on either side stated and tested. Solvability re-proved with the graft extended by a 25-line shape contract | 245 tests, 253 in new mode, 403 effective LOC, 862 words; **graft 4/4 at 253** |
| 46 | Hardened by adding required SURFACE rather than more assertions, which is the only lever the differential showed still moves agents. `MovingPointSourceDipole` now honours panels: each monopole mirrored about the sequence, its own emission time solved against the image trajectory. Also added coplanar-degenerate coverage (double reflection collapses to the direct distance, invalid, amplitude still reported) - mutation-priced at 3 and 61 kills, but measured to add ZERO agent-facing difficulty since all four implementations already handle it | 254 tests, 262 in new mode, **440 effective LOC**; graft 4/4 at 262 |
| 47 | Took three of four coverage suggestions: receiver-side validation across every pair API on both classes, plain-`Environment` empty batches, and moving-dipole per-microphone masking plus moving-incidence impedance (mutation-priced at 3, 2 and 1 kills). Also fixed a duplicated `_check_points` left by an earlier insertion. **Declined the fourth after measuring it**: tests pinning `image` on a sequence that is not in `path_sequences()` failed on all four implementations, which reject such a sequence where the reference mirrors it - four independent implementations against the reference means the reference is the outlier, and pinning it would have taken solvability to zero | 259 tests, 267 in new mode; graft 4/4 at 267 |
| 48 | Reversed my own outlier behaviour rather than the tests. Last round I removed the non-member-sequence tests because all four implementations rejected such a sequence while the reference mirrored it; this round the reviewer asked for exactly that rejection, so `image` and `image_velocity` now raise `IndexError` for a sequence not in `path_sequences()`, matching all four agents, and the contract says so. Added `(2,N)`/`(4,N)` validation for both image APIs, and replaced the moving-source impedance ratio-range checks with a pinned oracle: `ratio.max()` must equal the analytic `(2c-1)/(2c+1)` at normal incidence, one third. Stripped two trailing-whitespace lines that made `git apply` warn | 261 tests, 269 in new mode; graft 4/4 at 269 |
| 49 | Description Quality FAIL on three phrasings, all taken: the shared shape contract and the `reflection_points` signature notation rewritten as prose, and the genuinely ambiguous "and so does `paths`" clause replaced - it read as though `paths` rejected mismatched counts, which only `paths_at` does. Split one paragraph at its topic seam to stay under 150 words. Both coverage items taken, and the plain-environment one was another outlier correction: the reference silently accepted a nonempty sequence on `Environment.image` where all four agents raise, so the reference now raises and the contract covers both classes | 263 tests, 271 in new mode; graft 4/4 at 271 |
| 50 | Four more coverage rounds absorbed. Aligned two further reference behaviours to what all four agents do rather than pinning my own: `image`/`image_velocity` now reject a sequence outside `path_sequences()` on BOTH classes. Added empty-batch coverage across `crossing`, the four plane methods, `paths` on the receiver side, `reflection_points`/`incidence`, and a zero-sample impulse response; plus plain-environment shape validation and a pinned impedance oracle (`ratio.max()` equals the analytic one third at normal incidence). Declined validation-timing, non-finite rejection and scalar-domain errors with measured evidence: NaN is load-bearing in the path walk, so a non-finite guard would make every missing-crossing path raise instead of report invalid | 269 tests, 277 in new mode |
| 51 | Recorded a measurement that changes a claim: `conv_amp` has NO observable effect on `MovingPointSourceDipole`. Upstream scales `rm`, `rm1` and `rm2` all by `(1-Mr)^2` and the output is `rm/dist * (s/rm1 - s/rm2)`, so it cancels exactly - 0.0 difference on a plain environment, 5.4e-9 on a reflective one. Two mutations confirmed it. The dipole conv_amp test is kept as code-path coverage and is NOT counted as a trap | trap inventory unchanged |
| 52 | Solution Quality PASS at 2/3 + 2/3 named three findings. Two fixed: `MovingPointSourceDipole` now takes each monopole's amplitude and validity from its OWN mirrored path instead of the dipole centre, matching the stationary dipole and the stated rule; and the shape contract is now real, with public geometry methods validating `(3, N)` over private unchecked cores that the path walk uses for its `(3, N, M)` arrays. Consumers reshape to the documented layout, which also aligns the reference with the solvability graft. **Third declined with a reproduction**: re-exporting from `acoular/__init__.py` is blocked, not overlooked - that file is CRLF, and on a genuinely LF-normalised checkout the hunk fails with `patch failed: acoular/__init__.py:19`, the exact Verify Solution error from round 11 | 269 tests, 277 in new mode, **477 effective LOC**; graft 4/4 |
| 53 | Recorded that the per-monopole fix is NOT test-observable: acoular derives the dipole monopole separation as `c / sample_freq * |direction| * 2`, which is 1.4e-7 m, so the two specular points differ by 7e-8 m and no fair geometry separates them. The fix is spec conformance, not a new trap, and the earlier graft passing with the centre-gain version confirms it | trap inventory unchanged |

## Batch 4 (Nova x9): 0 of 9, and the cause was my own over-hardening

The batch came back **0 of 9**. Every agent passed base mode, so the environment was sound; the
artifact was simply out of reach.

**Root cause, stated plainly: I added the `MovingPointSourceDipole` surface on graft evidence and
shipped it.** All nine agents failed all three moving-dipole tests. A coordinated 100 percent failure
is this project's own signal for "unreachable requirement", and I had already applied that rule twice
(the self-blocking tolerance, the non-member sequence). I did not apply it here because the graft
passed 4 of 4 - but the graft only proves that AN increment exists when I write it against the
documented API. It never showed that an agent, working from the description alone inside one session,
would arrive at it. **The batch is the oracle; the graft is a proxy, and I let the proxy override the
rule.**

Failure distribution from the run's JUnit files, which is what drove the cut:

| test | agents failing |
| --- | --- |
| `test_moving_dipole_amplifies_each_path_by_its_own_mach_number` | **9/9** |
| `test_moving_dipole_masks_the_echo_per_microphone` | **9/9** |
| `test_moving_dipole_echo_equals_the_mirrored_dipole` | **9/9** |
| `test_moving_source_echo_equals_the_mirrored_trajectory` | 7/9 |
| `test_moving_dipole_scales_the_echo_by_the_reflection_factor` | 6/9 |

Two cuts, each justified by the run rather than by taste:

- **The whole moving-dipole scope removed** - eight tests, the `MovingPointSourceDipole`
  implementation reverted to upstream, and the description clause deleted so scope and tests match.
  Cost: 39 effective LOC, 477 down to 438.
- **The two `transfer` grid-selection tests removed.** The description never mentions the `ind`
  selection argument, so requiring reflected paths to thread through it was an unstated requirement.
  These were the only other failures of the best agent.

Measured after the cut, by replaying each agent's own patch:

| Agent | new mode | base mode | Outcome |
| --- | --- | --- | --- |
| Nova_Nova_6 | **267 passed, 0 failed** | **1291 passed** | **PASS** |
| Nova_Nova_3 | 3 failed | - | fail |
| Nova_Nova_1 | 10 failed | - | fail |
| Nova_Nova_2 | 34 failed | - | fail |
| Nova_Nova_4 | 42 failed | - | fail |

**1 of 9, about 11 percent**, inside the 40 percent cap and at the hard edge that was the target. The
residuals are now spread and agent-specific rather than collapsed onto one impossible surface, which
is the correct failure profile.

**Rule for any future hardening on this problem: a new required surface ships only after a real batch
shows agents reaching it. Graft evidence is necessary, never sufficient.**

## Tolerance audit after batch 4: one more unfair pin, found by reading the failure magnitudes

Asked whether `test_moving_source_echo_equals_the_mirrored_trajectory` and
`test_moving_source_is_silent_when_the_direct_path_is_blocked` were fair, I checked the batch's own
JUnit failure magnitudes rather than reasoning about it.

- **`..._echo_equals_the_mirrored_trajectory` was NOT fair.** Six of its seven failures miss by
  **9.32e-11**, the identical value each time - float noise from the emission-time Newton solve,
  which terminates at `epslim = 0.1 / up / sample_freq` = 4.2e-7 s. My `atol=1e-12` sat below the
  achievable precision. Only Nova_Nova_2 had a real defect there (0.16). This is the same error as
  the float32 transfer tolerance in batch 2: a pin tighter than the numerics allow.
- **`..._is_silent_when_the_direct_path_is_blocked` IS fair.** Two agents fail it, both by **1.68** -
  they do not mask the blocked direct path for a moving source, which the description states
  explicitly. A real defect, three orders above any noise.

Fixed by raising the four comparisons that pit a reflected echo against an INDEPENDENTLY simulated
mirrored trajectory (two separate Newton solves) from `atol=1e-12` to `1e-8`: two orders above the
measured noise and seven below the smallest real defect observed. Verified they still discriminate:
mirroring the velocity as a position kills 1, dropping the reflected gain kills 7.

Everything else in the moving family fails by >= 2e-2, so no other tolerance is noise-limited. The
now-removed moving-dipole tests were also failing at 1.5e-9 and 2.1e-9 for several agents, which is
independent confirmation that removing them was right rather than merely convenient.

**Rule: read the failure MAGNITUDES before judging a test fair. A cluster of identical tiny
mismatches is a tolerance bug; scattered large ones are real defects.**

## Batch 5 (Nova x10): the artifact was two bad tests away from solvable, not broken

Batch 33 ran the POST-CUT suite (267 collected), and the agents were already close: Nova_Nova_8
failed **1** test, Nova_Nova_1 and Nova_Nova_5 failed **2**. Reading only the pass/fail counts after
batch 25 hid that; reading the failure MAGNITUDES exposed both blockers immediately.

**Blocker 1, `test_moving_source_echo_equals_the_mirrored_trajectory` - unfair tolerance.**
Nova_Nova_1, 2 and 5 missed by **9.32e-11**, the identical value each time, while Nova_Nova_3, 4, 6
and 7 missed by 0.16 to 1.10. An identical tiny mismatch across independent implementations is float
noise, not a defect: the emission-time Newton solve terminates at `epslim = 0.1 / up / sample_freq`
= 4.2e-7 s, and comparing two independent solves of the same problem leaves about 1e-10 in amplitude.
`atol=1e-12` was below achievable precision. Raised the four echo-versus-mirrored-trajectory
comparisons to `1e-8`; mutation-verified they still kill (velocity mirrored as a position: 1,
reflected gain dropped: 7).

**Blocker 2, `test_moving_source_is_silent_when_the_direct_path_is_blocked` - unhighlighted corner.**
Five agents failed at **exactly 1.67674312**, and every one of them PASSED the stationary
`test_point_source_is_silent_when_the_direct_path_is_blocked`. Probing Nova_Nova_8's own code
settled it:

| configuration | Nova_Nova_8 output |
| --- | --- |
| `max_order=0`, panel as a pure occluder (the test as written) | 1.62, fails |
| `max_order=1`, the geometry its two siblings use | **0.0, passes** |

Nova_Nova_8 does implement direct-path blocking for a moving source; it short-circuits to the plain
upstream code path when there are no reflections. `max_order=0` was the ONLY place in 259 tests using
that configuration, and the description frames panels through "every path that bounces off them up to
`max_order` times", which reads as inert at order zero. The test probed a corner the description
never highlights rather than the rule it states. Re-aligned to `max_order=1` with the sibling
geometry, so it tests the same stated requirement in the same framing.

Measured after both fixes, by replaying each agent's own patch:

| Agent | new mode | Outcome |
| --- | --- | --- |
| Nova_Nova_8 | **267 passed** | **PASS** |
| Nova_Nova_1 | **267 passed** | **PASS** |
| Nova_Nova_5 | **267 passed** | **PASS** |
| Nova_Nova_2 | 2 failed | fail |

**3 of 10, 30 percent**, inside the 40 percent cap, measured on real agent patches rather than a
graft.

**Standing rule added: read failure MAGNITUDES, never just counts.** A cluster of identical tiny
mismatches is a tolerance bug of mine. An identical LARGE value across independent implementations
means they all did the same reasonable thing and the test is probing an unstated corner. Both
signals were present in batch 25 and I missed both by looking only at how many agents failed.

## Batch 6 (Nova x10 + Orion x4): solvable at 1 of 13, and one more unfair test found

`Orion_Nova_1` passes cleanly, 0 of 267 failed, base green. **1 of 13, 7.7 percent.** Batch 34 ran the
CURRENT tests, confirmed two ways: no traceback contains the old `max_order=0` form, and
Nova_Nova_1's moving-source failures are now 0.63 and 1.10 rather than the 9.32e-11 noise of batch
33. Both of the previous round's fixes therefore worked.

**One more unfair test, same diagnostic as before.** `test_point_source_adds_a_second_order_echo`
failed five agents, and every one reported an arrival index of **512 or 1024** - exact multiples of
the 512-sample block size. The test located the echo onset as the first index where
`|late| > 1e-12`, so it latched onto block-boundary float dust in the difference of two simulations
rather than the echo itself. Five independent implementations landing on the same block boundary is
an artifact of my threshold, not of their timing. Now located relative to the echo peak
(`> 0.05 * max`), which sits far above block dust and far below the arrival.

**The three remaining near-misses all fail on real defects against stated requirements**, so none of
them is a fairness case and none will be softened:

| Agent | its single failure | why it is fair |
| --- | --- | --- |
| `Orion_Nova_3` | `test_negative_order_is_rejected` | "A negative `max_order` raises a `ValueError`" is stated verbatim; 27 of 29 agents across four batches pass it |
| `Orion_Nova_2` | `test_time_beamformer_ignores_a_missing_impedance_path` | NaN leak in its beamformer; the amplitude-is-`nan` rule and existing-paths-only rule are both stated |
| `Nova_Nova_2` | `test_dipole_masks_the_echo_per_microphone` | `IndexError` inside its own code |

**False-positive report.** The panel found that the passing implementation relies on a strict
floating-point crossing to stop a reflection point self-blocking its own panel, and so drops about
2.4 percent of legitimate paths on off-grid coordinates. That is the same blind spot recorded after
batch 2, where every panel in the suite is axis-aligned with round coordinates. The alignment taken
now is to make the rule explicit rather than implied: "A panel never blocks a segment that meets it
at one of that path's own reflection points." That is a structural instruction, implementable by
excluding the reflecting panel from that segment's test, with no tolerance involved.

**Deliberately NOT adding an off-grid test for it.** Every implementation measured so far, including
the only passer, fails such a test; adding it now takes the batch from 1 of 13 to 0 of 13. With the
rule stated, an agent has what it needs, and the discriminating test belongs in the round AFTER a
batch shows agents reaching it - the same rule that the moving-dipole over-hardening established.

## Clarifying sentence added to widen the solvable margin

Olympus has no separate hint section, so the equivalent is a description sentence. Rather than guess
at one, I counted which failure family actually blocks agents in batch 34:

| failure family | failures | agents |
| --- | --- | --- |
| a non-existent path leaks into a consumer, usually as `nan` | **19** | N1, N3, N4, N7, N9, **O2** |
| validity not applied per emitting/receiving point | 7 | N2, N3, N4, N7, N10 |
| validation not enforced | 5 | O3, O4 |

One sentence covers the top two, and `Orion_Nova_2`'s ONLY failure sits in the first:

> Every consumer below drops a path that does not exist, separately for each emitting and receiving
> point, and contributes nothing for it even when its amplitude is `nan`.

It is a clarification, not a new requirement: "adds one term per existing path", "let every monopole
radiate along every existing path" and "the amplitude is `nan` under an impedance" were all already
stated, and the trap was that `nan * False` is `nan`, so multiplying by a validity flag leaks. The
sentence names the consequence without naming an implementation.

No test and no patch changed - verified by checksum - so `Orion_Nova_1`'s measured pass (new 267,
base 1291) is unaffected. **The effect on the other agents is a projection, not a measurement**: a
description change cannot be validated by replaying old patches, because those agents never saw it.
The next batch is what confirms it. Description now 852 words, longest paragraph 124.

## Batch 7 (Nova x10 + Orion x4): 0 of 14 raw, and the FP closed at the same time

Batch 36 came back 0 of 14 with three agents failing exactly ONE test, and it DID include both
clarifying sentences (verified in the trajectories), so the clarification was not the issue. All
three near-passers CRASHED rather than computed wrong values:

| agent | its single failure | crash |
| --- | --- | --- |
| Nova_Nova_8 | `test_dipole_masks_the_echo_per_microphone` | `ValueError: input operand has more dimensions than allowed by the axis remapping` |
| Orion_Nova_3 | same test | `ValueError: operands could not be broadcast together with shapes (16,2) (8192,)` |
| Orion_Nova_1 | `test_time_beamformer_is_silent_when_the_direct_path_is_blocked` | `IndexError: index 34 is out of bounds for axis 0 with size 34` |

Two fixes, each aimed at what the data showed:

- **Removed the dipole per-microphone masking test.** Five agents crashed threading P paths through
  the dipole's two-monopole arithmetic with two microphones. The rule survives in four other tests
  (`PointSource`, `LineSource`, `BeamformerTime`, `MovingPointSource`) plus the dipole's own
  single-microphone omission test, so this drops one instance of an already-covered rule.
- **Reworked the beamformer blocked-path test.** Orion_Nova_1 crashed in its OWN buffer indexing
  because EVERY path was invalid, leaving no reachable delay to size the buffer from. That is the
  third "nothing exists" degenerate to block an otherwise-correct agent, after `max_order=0` and the
  all-invalid third-order case. It now uses a screen that blocks the direct path while a floor
  reflection survives: same stated rule, no empty-buffer corner.

## The false positive is CLOSED, and the fix was to measure instead of assume

I had left the FP open on the assumption that no implementation could be robust to off-grid
coordinates, so any discriminating test would take the batch to zero. That assumption was wrong.
Differencing all three passers against the reference over 60 random off-grid geometries:

| agent | validity mismatches vs reference |
| --- | --- |
| Orion_Nova_1 | **0 / 1920** |
| Orion_Nova_3 | **0 / 1920** |
| Nova_Nova_8 | 49 / 1920 = **2.55 percent**, all spurious drops |

Two of three are fully robust, and Nova_Nova_8's 2.55 percent independently reproduces the FP
report's ~2.4 percent. So a discriminating test costs exactly the implementation that has the bug.
Added `test_reflection_off_a_panel_at_arbitrary_coordinates_exists`: a slanted panel at arbitrary
coordinates, edges built by cross product so perpendicularity is exact, asserting the contact point
lies on the panel and the path exists. It is grounded in the sentence already in the description,
"A panel never blocks a segment that meets it at one of that path's own reflection points."

Measured outcome on batch 36's own patches:

| Agent | new mode | Outcome |
| --- | --- | --- |
| Orion_Nova_1 | **267 passed** | **PASS** |
| Orion_Nova_3 | **267 passed** | **PASS** |
| Nova_Nova_8 | 1 failed, the off-grid test | fail, correctly |

**2 of 14, 14 percent, with the FP closed.**

**Lesson: measure the population before declaring a requirement untestable.** I assumed every
implementation shared the defect and left a known false positive open for a whole round; two of
three were already robust.

## The hint made directive, which is the durable way to keep the FP shut

The off-grid test closes the FP after the fact; the hint prevents it. The description sentence was a
bare statement of the rule, which still let an agent implement it with a floating-point proximity
test and pass everywhere except off-grid geometry. It now says what to do:

> A panel never blocks a segment that meets it at one of that path's own reflection points, so leave
> that panel out of the blocking test for the two segments that touch it rather than deciding it from
> how close the contact point lands to the plane.

That is deliberately directive. It names the structural approach (exclude the panel by identity) and
warns off the fragile one (decide by distance), without writing the code. Both of the measured robust
implementations, Orion_Nova_1 and Orion_Nova_3, already do exactly this; Nova_Nova_8's 2.55 percent
path loss comes from the approach the sentence now warns against.

Net effect: the hint should raise the pass rate AND keep the false positive closed, because an agent
that follows it cannot produce the defect the FP panel found. 882 words, longest paragraph 146.

## Third hint, aimed at the largest measured blocker

With the dipole per-microphone test removed and the beamformer blocked-path test reworked, the
residual failures across batch 36 concentrate almost entirely in the coplanar / degenerate family:

| test | agents still failing |
| --- | --- |
| `test_missing_middle_point_propagates_through_a_third_order_path` | 8 |
| `test_transfer_ignores_the_coplanar_degenerate_paths` | 7 |
| `test_coplanar_triple_reflection_keeps_only_its_last_point` | 7 |
| `test_point_source_ignores_the_coplanar_degenerate_paths` | 7 |
| `test_coplanar_double_reflection_collapses_to_the_direct_distance` | 2 |

That is 23 failures on one geometry, and it gates the entire next tier: N7 at 4 residual failures,
O4 at 4, N6 at 5, N3 at 6, N9 at 7. So the third hint explains that geometry rather than deleting the
tests:

> Two panels lying in the same plane mirror a position straight back, so a sequence naming both
> carries the direct travel distance while its reflection points are missing, because the segment
> from that image to the receiver never crosses the plane.

It is a consequence of rules already stated (mirroring in sequence order, the backward walk, a
missing crossing making points `nan`), spelled out for the one configuration where the consequence is
counter-intuitive: an image that lands back on the source. Nothing about the implementation.

Description now 923 words, longest paragraph 146. No test and no patch changed, verified by checksum,
so `Orion_Nova_1` and `Orion_Nova_3` remain measured passes at 269.

**Three hints now, each chosen from batch data rather than intuition**: non-existent paths contribute
nothing even when their amplitude is `nan` (19 failures, 6 agents), leave a panel out of the blocking
test for the segments that touch it (the false-positive defect), and the coplanar degenerate above
(23 failures, 5 agents).

## Solution Quality FAIL: a real gate bug in SteeringVector.transfer

Scored 1/3 comprehensiveness on a specific, correct finding. `SteeringVector.transfer` delegated
validity masking to `_add_reflected`, but only called it when `len(self.env.path_sequences()) > 1`.
For a `ReflectiveEnvironment` holding blocking panels with `max_order == 0`, `path_sequences()` is
`[()]`, so the guard was false and a BLOCKED direct path came back unmasked. The description states
the direct path can be blocked and that `transfer` sums only existing paths, so this was a genuine
spec violation that no test caught.

Fixed by making the gate depend on whether the environment has panels at all, not on whether it
enumerates more than one sequence:

    if getattr(self.env, 'planes', None) or len(self.env.path_sequences()) > 1:

Measured before and after on a blocked direct path over a wide floor:

| `max_order` | `abs(transfer)` before | after |
| --- | --- | --- |
| 0 | non-zero, the bug | **0.0** |
| 1 | 0.0 | 0.0 |

Added `test_transfer_drops_a_blocked_direct_path_without_reflections` to cover it, and measured the
cost before keeping it: `Orion_Nova_1` and `Orion_Nova_3` both still pass, at 270. So the fix and its
test are free - the bug closes and solvability stays at 2 of 14.

Worth noting this is the FOURTH defect found in the `max_order == 0` configuration, after the moving
source short-circuit, the all-invalid beamformer buffer, and this. A zero-order reflective
environment is the corner where every path-count-based shortcut breaks.

## Solution Quality FAIL: a real gate bug, fixed, and the whole class audited

Scored 1/3 comprehensiveness on a correct and specific finding. `SteeringVector.transfer` delegated
validity masking to `_add_reflected` but only called it when `len(self.env.path_sequences()) > 1`.
For a `ReflectiveEnvironment` holding blocking panels with `max_order == 0`, `path_sequences()` is
`[()]`, so the guard was false and a BLOCKED direct path came back unmasked. The description states
the direct path can be blocked and that `transfer` sums only existing paths, so this was a genuine
spec violation no test caught.

Fixed by gating on whether the environment has panels at all, not on how many sequences it
enumerates:

    if getattr(self.env, 'planes', None) or len(self.env.path_sequences()) > 1:

**Then audited the whole class rather than only the reported instance.** The reviewer's note that
this is the fourth `max_order == 0` defect (after the moving-source short-circuit and the all-invalid
beamformer buffer) said the real risk was other path-count shortcuts. Measured every consumer on a
blocked direct path at both orders:

| consumer | `max_order=0` | `max_order=1` |
| --- | --- | --- |
| `SteeringVector.transfer` | 0.0 | 0.0 |
| `PointSource` | 0.0 | 0.0 |
| `PointSourceDipole` | 0.0 | 0.0 |
| `LineSource` | 0.0 | 0.0 |
| `impulse_response` | 0.0 | 0.0 |
| `BeamformerTime` | 0.0 | 0.0 |
| `MovingPointSource` | 0.0 | 0.0 |

All clean. The one remaining count-based branch, `d_index.shape[0] == 1` in `tbeamform`, selects the
numba kernel only; validity is applied before it, which the `BeamformerTime` row confirms.

Added `test_transfer_drops_a_blocked_direct_path_without_reflections`, and measured its cost before
keeping it: `Orion_Nova_1` and `Orion_Nova_3` both still pass, at 270. Fix and test are free, and
solvability stays at 2 of 14. No test was added for the other six consumers - the audit shows they
are already correct, and each new assertion is a requirement an unmeasured agent might miss.

## Coverage round: two taken, two declined, each decided by measurement

- **Malformed coordinate RANK. Taken.** The suite only rejected wrong row counts in 2-D arrays. Now a
  bare `(3,)` vector and a `(3, 2, 2)` block are rejected by all four plane geometry methods, so the
  `(3, N)` contract is enforced on rank as well as on rows. Free: both passers keep passing.
- **Empty image batches. Taken.** `image` and `image_velocity` on `(3, 0)` return `(3, 0)`, checked on
  both classes. Follows from the `(3, N)` rule plus the empty-batch acceptance already stated. Free.
- **Invalid geometry after mutation. DROPPED after measuring.** Written and run: it was the ONLY
  failure of `Orion_Nova_1`, taking the batch from 2 of 14 to 1 of 14. Asserting that an edge mutated
  to be invalid raises on next access AND invalidates the environment digest depends on cached-normal
  invalidation semantics the description never discusses. Not worth a passer.
- **Dipole mixed-microphone masking. Declined a third time.** Same test removed twice before: it
  crashed 5 of 14 agents on threading P paths through the two-monopole arithmetic with two
  microphones, and was the sole failure for two of them. The rule stays covered by the `PointSource`,
  `LineSource`, `MovingPointSource` and `BeamformerTime` per-microphone tests plus the dipole's own
  single-microphone omission test.

Two of the four were only distinguishable by running them against real agent patches. Writing a test,
measuring its cost, and deleting it is cheaper than shipping it and losing a batch.

## Test Fairness FAIL on three crossing tests: one root cause, closed by generalising the rule

All three flagged assertions are the same gap. The description promised `nan` coordinates only for
the ENDPOINT case ("a segment starting or ending on the plane does not cross and its coordinates are
`nan`"), while three tests also required `nan` for parallel, coplanar and same-side segments. The
checker is right that nothing singled out `nan` as a universal false-crossing sentinel: an endpoint,
an arbitrary point, or zeros would all have been defensible.

Closed by generalising the rule instead of deleting three tests:

> ... so a segment starting or ending on the plane does not cross. Wherever the flag is false,
> whatever the reason, the coordinates are `nan`.

Nine words, and it makes every false-crossing column predictable. It costs no solvability: both
passers already return `nan` for those cases, so stating it adds no requirement they do not meet.

Also taken: **malformed emitter symmetry**. The pair-API validation test only exercised malformed
RECEIVERS, while the `(3, N)` rule binds both sides. Added
`test_pair_apis_reject_a_malformed_emitter` covering `reflection_points`, `incidence`,
`impulse_response` and `paths_at`.

**Declined a fourth time: dipole per-receiver masking.** Unchanged reasoning and unchanged data - it
crashed 5 of 14 agents on threading P paths through the two-monopole arithmetic with two microphones
and was the sole failure for two of them. The rule stays covered by four other per-microphone tests
plus the dipole's single-microphone omission test.

## Auto Review: revision requested on Tests 1/3 and Description 2/3

**Tests 1/3 - the dipole per-microphone test, which I had declined five times, is now required.**
The finding is exactly right about the escape it leaves: a global or broadcast dipole validity mask
would satisfy every other test while violating the stated per-emitter/per-receiver rule. The review
also spotted that the suite carried a multi-receiver dipole helper it never used - in fact
`dipole_channels` had gone missing entirely, so I restored both helper and test.

Mutation-priced against precisely that escape: collapsing the dipole mask to `valid.all(-1)` fails
this test and ONLY this test, 1 of 266.

**The cost is real and is why I resisted it.** Measured on the current passers:

| Agent | before | after |
| --- | --- | --- |
| `Orion_Nova_1` | 273 | **274, still passes** |
| `Orion_Nova_3` | 273 | 1 failed |

Solvability goes from 2 of 14 to **1 of 14**. Still solvable and still in band, and Tests moves to
3/3, so the trade is correct now that a gate depends on it - but the margin is halved and the next
batch rests on a single passer. My five earlier declines were right on the evidence I had (it was
the sole failure of two agents and crashed five); they were wrong only in that I never re-checked
whether the CURRENT passers survived it. Orion_Nova_1 does.

**Description 2/3 - condensed.** The P4 finding called the text an exhaustive acceptance
specification rather than a maintainer issue. Ten passages tightened, 966 to 939 words, longest
paragraph 130, with a post-edit check confirming every load-bearing item survived: three `ValueError`
sites, the `IndexError` rule, three `nan` rules, `path_sequences()`, `conv_amp`, `r_diag`, impedance,
digest, empty batches and the 3xN contract.

**Solution & Code was already 3/3** and needed no change.

## Round: FP review on Nova 1 / 2 / 3 (three reports)

All three findings were genuine and all three were verifier gaps, not unfair tests. Added five probes and
mutation-priced each against exactly the escape its report named.

| Probe | Escape it kills | Killed only by |
| --- | --- | --- |
| time beamformer, blocked direct at max_order 0 | existence ignored when a single sequence exists | the 2 new tests |
| time beamformer sq, same | same | the 2 new tests |
| rotated neighbouring panel | tolerance-free strict sign test in crossing | off-grid + this |
| contains far from the origin | on-plane tolerance scaled by coordinate magnitude | this test |
| edge edited to invalid geometry | normal not revalidated after mutation | static test + this |

M1 and M3 were completely uncovered before, so those two gaps were exactly as reported.

### What the probes revealed about the two standing passers

Both were false positives. This is the important result of the round.

- Orion_Nova_1 carries the Nova 1 defect verbatim: tbeamform dispatches to the reflection-aware branch
  only when len(path_sequences()) > 1, so a max_order 0 environment with a blocking panel runs the legacy
  branch and emits the blocked arrival. Fails 3 of the new probes.
- Orion_Nova_3 returns (1, 512, 2) blocks from PointSourceDipole under a reflective environment where the
  reference returns (512, 2). A leftover path axis that was never collapsed. That is what
  test_dipole_masks_the_echo_per_microphone actually catches, and it would break every downstream consumer.

So the suite is now correct and I have zero verified local passers. Solvability is unmeasured, not
disproven, since both agents were graded against a weaker suite. A fresh batch is the only oracle.

### Description, not test weakening

The lever for the risk is contract clarity. Three sentences added, all stating contract rather than
implementation, each aimed at a defect class that actually killed an agent:

- existence masking "holds when the direct path is the only one there is, so a blocking panel silences the
  arrival even at a max_order of zero"
- sources "keep the block shape its class already produces, one column per microphone"
- normal is "rechecked whenever it is used", which gives the edge-mutation probe the prompt grounding it
  previously lacked (that was my stated reason for calling Nova 3 the weakest of the three reports)

meta.md 939 -> 982 words, longest paragraph 135, ASCII clean. solution.patch untouched, 438 human-effective.

### Correction found while grafting: the edge-mutation test was unfair as written

My first version asserted the mutation is rejected on NEXT USE:

    plane.edge2 = np.array([4.0, 0.0, 0.0])
    expect_error(lambda: plane.normal)

Orion_Nova_1 validates eagerly in __setattr__ and already carries a _validate_edges helper, so it raises
at the assignment line and never reaches plane.normal. The test therefore did not test whether invalid
geometry is rejected, it pinned WHEN, and it failed the arguably better eager implementation. That is an
implementation-choice pin. It is very likely why that adjudicator never confirmed the Nova 3 report.

Rewritten to accept either timing, wrapping mutation and use in one callable:

    def mutate_then_use():
        plane.edge2 = np.array([4.0, 0.0, 0.0])
        assert plane.normal is not None
        env.paths(points((0.0, 0.0, 1.0)), points((1.0, 0.0, 1.0)))
    expect_error(mutate_then_use)

Renamed to test_editing_an_edge_to_be_invalid_is_rejected. M4 (normal skips revalidation) still kills it,
so de-pinning cost no coverage. The meta sentence "rechecked whenever it is used" was reverted for the
same reason: it over-specified deferred validation. 982 -> 977 words.

### Honest note

Two of my own calls this round were wrong in opposite directions. I dropped this test in an earlier round
because it cost a passer, which was the right outcome for the wrong reason. Then I restored it and blamed
the agent, which was wrong: the test really was unfair, just not for the reason I first assumed. Cost of a
passer is never itself evidence a test is unfair, and it is never evidence the test is fair either. The
only way to tell is to read what the failing implementation actually does.

## Hints added for solvability (after the FP round left 0 raw passers)

Both blocking defects were measured, so the hints target them directly rather than guessing. Each states
behaviour a human expert could infer from the description plus the repo, names no file, helper or step.

| Measured failure | Hint added |
| --- | --- |
| Orion_Nova_1 guarded the reflection branch on the number of sequences, so a blocked direct path at max_order 0 still sounded | "This holds when the direct path is the only one there is, so a blocking panel silences the arrival even at a `max_order` of zero. None of them choose what to do from how many sequences an environment has." |
| Orion_Nova_3 yielded (1, 512, 2) dipole blocks against the reference (512, 2) | "Each still yields blocks of samples by channels, the same two dimensional shape it yielded before, with one column per microphone and no extra axis for the paths." |

The second hint pushed the sources paragraph to 150 words, which is the wall_of_text threshold, so it was
split at the MovingPointSource seam. meta.md is now 1006 words, longest paragraph 130, 13 body paragraphs,
ASCII clean.

Note on budget: the repo guidance names a 500 word cap, and this description has run at roughly double that
through several Description Quality passes. The hints add 29 words and do not change that standing risk,
but it is worth a decision before submit.

No test was weakened to buy solvability. The suite stayed at 271 and the grafts below remain the evidence
that it is satisfiable.

## Final round: Test Fairness FAIL closed by fixing the description

Three tests were flagged unfair, all the same class: empty-batch support on the plane methods, `crossing`,
and `image`/`image_velocity`. The prompt enumerated five empty-capable methods, and an enumeration is the
contract, so naming five implied the rest were not guaranteed. The checker was right on all three.

Fixed by removing the enumeration rather than the tests:

    paths, paths_at, impulse_response, reflection_points and incidence accept an empty emitting or
    receiving batch, keeping the zero-length axis.
    ->
    Every method taking coordinate arrays accepts an empty batch, keeping the zero-length axis.

Covers all eight empty-batch tests at once, removes the enumeration trap for good, and is shorter: 999 ->
995 words. No test touched, so the coverage added the round before survives, and every method the general
claim covers is exercised by a passing test.

Same root cause as the `factor_at` warning earlier in the round: the description under-described something
the tests already required. The general-rule form does not need patching each time an API is added.

## Final artifact state

273 tests. meta 995 words, longest paragraph 120, ASCII, no bare `c` in prose. solution.patch 5 files,
438 human-effective LOC. Both patches whitespace-clean, test.sh mode 100755, no banned markers.

Matrix on the final artifacts: BASE-NEW 273 nodes / 273 failed, BASE-BASE 1291 passed, SOL-NEW 281 passed,
SOL-BASE 1291 passed, UNAPPLY residual 0.

Open risk carried into submit: all three batch-43 passers failed the two numerical-robustness probes
(rotated neighbour, contains far from origin). Those replays predate every hint, and both behaviours are
now stated, but the effect is unmeasured. A 2-3 agent smoke run would price it before a full batch.

## Nova FAIL_TEST_MISMATCH: unstated perpendicularity tolerance (my fixture, not the environment)

A Nova run failed one new test and the evaluator flagged an environment blocker of type "verifier" with
agentBlameUnfair true. Measured before responding:

    off_grid_panel edges: dot = -7.158718e-13, relative = 2.932043e-14 (1.68e-12 degrees off square)

Every sane tolerance accepts that (mine 1e-9 relative, Nova_5's 1e-12, np.isclose default). Only an exact
zero-dot check rejects it. The prompt requires "perpendicular" and states no tolerance, so the strict reading
is legitimate and the finding is correct: an unstated requirement.

Fixed at source rather than by adding spec text. The fixture now uses integer direction vectors scaled by
arbitrary floats:

    edge1 = np.array([1.0, 2.0, 2.0]) * 2.7431
    edge2 = np.array([2.0, 1.0, -2.0]) * 1.9077

1*2 + 2*1 + 2*(-2) = 0 exactly, and stays exactly 0 under scaling because the two 2ab terms are computed
identically and 2ab + 2ab - 4ab cancels in binary. The test asserts np.dot(edge1, edge2) == 0.0 so the
fixture cannot drift back into tolerance territory. Normal is (-2/3, 2/3, -1/3), still well off-axis, so the
test keeps its purpose of guarding against axis-aligned special casing. Source and receiver were rebuilt by
reflecting a ray about the plane at a contact 0.37/0.61 along the edges.

Coverage trade, recorded honestly: the rebuilt fixture no longer kills the tolerance-free crossing mutation
(M2); the old coordinates happened to trigger it. M2 is still killed by
test_rotated_neighbouring_panel_does_not_block_the_reflection, which is the FP report's own discriminator,
so the confirmed false positive stays covered.

On contesting: the run's failure is legitimate and was not disputed. What was contested is only the
environment-blocker classification, because nothing environmental failed (image built, deps resolved offline,
baseline 1291 passed, agent ran 132 messages to completion). Filing a test-fairness observation as an
environment blocker misreports environment quality.

Matrix on the corrected artifacts: BASE-NEW 273 nodes / 273 failed, BASE-BASE 1291 passed, SOL-NEW 281
passed, SOL-BASE 1291 passed, UNAPPLY residual 0.

## FP round: Nova 1 genuine pass, Nova 2 real bug closed

Nova 1 was adjudicated a GENUINE pass. Its only divergence is ReflectingPlane.crossing when BOTH segment
endpoints sit inside the on-plane tolerance. The adjudicator states the prompt leaves that convention open
and that my own leniency wording ("however close that point lands to the plane in floating point") arguably
favours the candidate. It suggested optionally pinning the convention with a test. I declined: pinning an
undecided convention is exactly the unfairness class that produced the Test Fairness FAIL earlier this
round. No change made.

Nova 2 was a real bug and a real verifier gap. BeamformerTime computed its output truncation over ALL path
offsets, so a distant NONEXISTENT reflection shrank the output to zero and erased the valid direct arrival.
The reference filters `reachable = distance[exists]` (tbeamform.py:152). Prompt line 25 already required a
nonexistent path to contribute nothing, and shrinking the output is contributing something.

Why the suite missed it: every invalid-reflection test used a NEARBY panel, and
test_time_beamformer_keeps_grid_points_separate deliberately compares only the shared span, so no test
depended on truncation extent.

Closed with two tests using a legal panel at z=1000 whose reflection misses it (valid=[True, False],
reflected distance 1998). Mutation-priced against the exact escape (`reachable = distance`): it fails ONLY
those two tests, 2 of 275.

Agent cost measured before committing: Nova_Nova_1 and Nova_Nova_5 fail both (they carry the bug),
Nova_Nova_7 passes both. Nova_Nova_7 therefore stays at its existing 2 failures, so the closure costs the
best agent nothing and is demonstrably satisfiable.

Added one clause since 2 of 3 agents got it wrong: "It never shortens what a consumer emits." Offset by
three wording trims to stay under the cap. meta 995 -> 998 words, longest paragraph 120, ASCII.

## Solution Quality round: 2/3 + 2/3 -> fixes applied, and a self-inflicted environment mess

The single failing test that capped BOTH Solution Quality scores was mine:

    assert np.dot(plane.edge1, plane.edge2) == 0.0

Locally the trait stores float64 and the dot is exactly 0.0, so I could not reproduce the platform failure.
That is precisely why the assertion had to go: it depended on bitwise floating-point behaviour I cannot
verify across machines, and it tested my own fixture rather than any behaviour the problem asks for. Removed.
The same assertion also caused the Verify Solution FAIL on the previous artifacts.

Both Code Quality criticisms were fixed rather than argued:

- path_sequences() was recomputed and linearly searched on hot paths. Added `_sequence_cache`, a
  cached_property on ['plane_digest', 'max_order'] returning (list, {sequence: position}), with
  `_sequence_position` for O(1) membership. image / image_velocity / reflection_points / incidence /
  _collect / MovingPointSource all use it now. Base Environment got a matching `_sequence_position`.
- _blocked relied on the strict-endpoint behaviour of crossing to express "own reflection point never
  blocks". It now states the rule directly, testing whether the crossing coincides with either segment
  endpoint within a span-scaled tolerance.

human-effective LOC 438 -> 454.

Mistake made on the way: my first insertion of the cache landed in Environment instead of
ReflectiveEnvironment, because both classes define path_sequences and replace(..., 1) took the first.
ReflectiveEnvironment then inherited a base _sequence_position that rejects every nonempty sequence: 18
failures. Relocated, 275 passed.

### The 15 base-mode errors were my own orphaned containers

BASE-BASE came back 1276 passed + 15 errors, then the identical suite passed at 1291 minutes later. Root
cause was not the artifact: three of my containers (10 hours, 2 hours, 40 minutes old) were all mounting the
SAME acoular-val worktree while the matrix ran git checkout / git clean / git apply in it. One run's suite
executed while another reset the tree underneath it. Load was 14.8 on 12 cores.

They accumulated because `pkill -f matrix.sh` kills the driver shell but NOT the docker containers it
spawned, so every restarted matrix left one behind. Stopped all three (left an unrelated rp-fin2-both
container belonging to other work on the machine).

LESSON: when killing a harness that spawns containers, stop the containers too, and check `docker ps` before
trusting any timing- or resource-sensitive measurement. Several "isolated" runs this session were not.

### Flakiness gate, re-run clean

| mode | runs | result |
| --- | --- | --- |
| base | 3 isolated + SOL-BASE | 1291 passed every time |
| new  | 3 | 283 passed every time |

Clean base runs took 5:43 and 6:05 against 9-13 minutes under contention, which confirms the diagnosis.

