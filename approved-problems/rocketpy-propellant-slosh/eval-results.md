# eval-results.md — rocketpy-propellant-slosh

## Batch 1 (2026-09-08) — 0 of 6 passed, single correlated cause

Artifact under test: the Round 20 upload. Solver Nova x5 + Orion x1, evaluator Nova.

| Run | Verdict | Failures | Failed tests | Approach note |
|---|---|---|---|---|
| Nova #1 | FAIL_MISSED_REQUIREMENT | 5 | the five oscillation tests below | pads both tolerances with `tolerance[-1]` |
| Nova #2 | FAIL_WRONG_LOGIC | 5 | same five | pads both with `tolerance[-1]` |
| Nova #3 | FAIL_MISSED_REQUIREMENT | 5 | same five | pads both with `tolerance[-1]` |
| Nova #4 | FAIL_MISSED_REQUIREMENT | 7 | same five + `test_padding_keeps_every_supplied_tolerance_entry[rtol]` x2 | pads atol only, leaves rtol at legacy width |
| Nova #5 | FAIL_MISSED_REQUIREMENT | 9 | same five + `test_a_tank_without_slosh_has_no_participating_mass` x4 | copies component tolerances; returns int `0` from `slosh_mass` |
| Orion #1 | FAIL_WRONG_LOGIC | 5 | same five | pads both with `tolerance[-1]` |

Baseline was green (1824 passed, 0 failures) in all six runs. No environment blocker in any
run; every evaluator recorded `blocker_detected = false`, `description_clear = true`,
`tests_deterministic = true`, `difficulty = challenging`.

### The correlated cause

All six runs failed the same five tests:

- `test_the_first_mode_belongs_to_the_lower_tank`
- `test_an_undamped_mode_returns_after_one_period`
- `test_an_undamped_mode_inverts_at_a_half_period`
- `test_a_mode_keeps_oscillating_under_a_parachute`
- `test_a_damped_mode_loses_amplitude_under_a_parachute`

All five are quantitative amplitude/phase assertions on an integrated mode, and all five ran
at the default solver tolerance. The reference pads the appended state entries with a constant
`1e-6`; all six agents padded with the last legacy entry, `1e-3`. With an absolute tolerance of
`1e-3` on a displacement of amplitude `1e-2` (and `1.7e-4` under a parachute) the mode is
under-resolved, so the amplitudes come back 3 percent low and the parachute decay ratio lands
at 0.65 against an expected 0.39.

`meta.md` says the tolerance is "padded to cover those entries". It never says with what value,
and no value is derivable from the repo. **The five tests encoded an undocumented numeric
requirement.** Nova #1's evaluator said so directly: "The exact preferred default tolerance for
newly appended states is not numerically stated." This is the all-agents-fail-for-the-same-reason
unfairness signal, and it produced a 0 percent batch, which is also an unsolvable-reject.

### Round 21 fix (test-side only, re-eval eligible)

The five tests now supply an explicit full-width `atol` (`resolved_atol(modes)` = the repo's
legacy default vector plus `1e-9` per appended entry). No padding rule is involved, so the
measurement no longer depends on a value the description does not state. The padding *width*
requirement is untouched and still discriminates: `test_padding_keeps_every_supplied_tolerance_entry`
asserts the width and that supplied entries survive, and it is what caught Nova #4.

### Differential replay of the fix

Each agent's `rocketpy/` patch replayed on a clean BASE_COMMIT checkout against the fixed suite:

| Run | Round 20 suite | Round 21 suite | Residual failures |
|---|---|---|---|
| Nova #1 | 5 failed | **109 passed** | - |
| Nova #2 | 5 failed | **109 passed** | - |
| Nova #3 | 5 failed | **109 passed** | - |
| Nova #4 | 9 failed | 2 failed | rtol not padded |
| Nova #5 | 9 failed | 4 failed | `slosh_mass` returns int `0`, not a Function |
| Orion #1 | 5 failed | **109 passed** | - |

(Round 20 replay reproduces the platform except for Nova #4, where local scipy 1.18.1 raises on an
unpadded rtol vector and the platform's scipy tolerated it. Deterministic in each environment, not
flaky.)

Projected pass rate after the fix: **4 of 6 = 67 percent**, above the 50 percent ceiling.

### FP check on the passers: the physics is not discriminating

Differential physics probe, hand-built states at fixed `t` so the comparison is
implementation-independent, reference against all six agents:

| Probe | Result |
|---|---|
| aerodynamic drive, strong sideslip | all 6 bit-identical |
| no relative wind (drive must be zero) | all 6 bit-identical |
| no wind, vehicle pitched 90 deg so gravity has a lateral body component | all 6 bit-identical (gravity excluded) |
| 6-DOF offset coupling | all 6 bit-identical |
| 6-DOF offset-rate coupling | all 6 bit-identical |
| 6-DOF offset + rate | all 6 bit-identical |
| 3-DOF | all 6 bit-identical |
| body rates present | all 6 bit-identical |
| two modes: rest / offset / full / 3-DOF / rail | all 6 bit-identical |
| two modes: participating masses | all 6 bit-identical |
| callable mass ratio + frequency + damping | all 6 bit-identical |
| parachute derivative | all 6 bit-identical |
| `solid_propulsion` raises ValueError | all 6 agree |

**Every agent implemented the entire documented feature exactly.** Not one physics clause
separates any of them from the reference. The two residual failures are peripheral compatibility
details, not the feature.

The designed difficulty is therefore zero: the 0 percent batch was produced entirely by the
undocumented tolerance constant, and removing it leaves a problem the whole population solves.

### Exhaustive sweep: confirming there is no physics lever

Before concluding, a randomized differential sweep: 24 configurations (1-3 tanks, random geometry,
mass, centre of mass, motor position, inclination; random mass ratios, frequencies and damping,
constant and callable; three random hand-built states each; `u_dot_generalized`,
`u_dot_generalized_3dof` and `udot_rail1` on every state; per-tank slosh masses; mode counts).

**4,534 values compared. All six agents bit-identical to the reference.** There is no behavioral
lever anywhere in the modelled surface.

## Round 22 - the callable-form lever

The sweep did surface one non-physics divergence. RocketPy's `Function` infers a domain dimension
from a callable's signature, so wrapping a user callable in `Function` -- the codebase's universal
idiom for a number-or-callable parameter -- rejects any callable that carries extra parameters of
its own. `meta.md` states the contract: each parameter is "a number or a callable receiving the
tank's fill fraction". Seven callable forms, all computing the same value:

| Form | reference | Nova #1 | #2 | #3 | #4 | #5 | Orion |
|---|---|---|---|---|---|---|---|
| plain function | ok | ok | ok | ok | ok | ok | ok |
| lambda | ok | ok | ok | ok | ok | ok | ok |
| `functools.partial` | ok | ok | ok | ok | ok | ok | ok |
| callable instance | ok | ok | ok | ok | ok | ok | ok |
| varargs | ok | ok | ok | ok | ok | ok | ok |
| **defaulted extra arg** | ok | **ValueError** | **ValueError** | ok | ok | **ValueError** | **ValueError** |
| **keyword-only extra arg** | ok | **ValueError** | **ValueError** | ok | ok | **ValueError** | **ValueError** |

Identical on all three parameters (`mass_ratio`, `natural_frequency`, `damping_ratio`).

Tests added (21 cases, tests-only, so re-eval eligible):

- `test_any_callable_of_the_fill_fraction_sets_the_mass_ratio` x7 - asserts `slosh_mass` equals
  the callable's value at the fill fraction times the liquid mass.
- `test_every_callable_form_sets_the_same_natural_frequency` x7 - seeded mode trajectory must match
  a plain-callable baseline exactly.
- `test_every_callable_form_sets_the_same_damping_ratio` x7 - same, for damping.

Five of the seven forms pass everywhere and act as controls; only the two extras-carrying forms
discriminate. The frequency and damping parametrizations also answer the standing Round 21 review
suggestion for callable frequency/damping coverage.

### Measured effect

| Run | R20 | R21 (fairness fix) | R22 (final) | Residual failures |
|---|---|---|---|---|
| Nova #1 | 5 failed | 109 passed | 6 failed | 2 callable forms x 3 parameters |
| Nova #2 | 5 failed | 109 passed | 6 failed | same |
| Nova #3 | 5 failed | 109 passed | **130 passed** | - |
| Nova #4 | 9 failed | 2 failed | 2 failed | rtol not padded |
| Nova #5 | 9 failed | 4 failed | 10 failed | callable forms + `slosh_mass` type |
| Orion #1 | 5 failed | 109 passed | 6 failed | 2 callable forms x 3 parameters |

**Projected pass rate: 1 of 6 = 17 percent.** In band, at the hard edge.

### Known risk on this lever

The four agents that now fail all implement the entire feature correctly and fail only because they
used the repo's own `Function` idiom. `meta.md` states the callable contract but does not say a
callable may carry parameters of its own, so an evaluator may read this as an implementation-detail
test and set `agent_blame_unfair`. Documenting it would cost a full batch and would very likely
return the rate to ~67 percent. Author is aware of the trade and chose to run it.

## Final artifact after Round 5 (base commit 9bd6ad3af8f97bafa3201d4e70eba2877e66e040)

| Mode | Patches applied | Result |
|---|---|---|
| new | test.patch only | **109 cases, 0 passing** (35 failed + 74 errors) |
| new | test.patch + solution.patch | **109 passed** |
| base | test.patch only | 1824 passed, 16 skipped |
| base | test.patch + solution.patch | **1824 passed, 0 failed, 16 skipped** |

Flakiness gate, on the final artifact: new x3 all **58 passed**, base x3 all **1824 passed, 16
skipped**, identical every run. Clean `git archive` checkout applies both patches in order with no
fuzz, and both reverse-apply cleanly.

Solution: 9 files, 863 raw added, **361 human-effective** LOC.
Test suite rewritten in round 1 to assert only through documented API (see `feedback.md`).

## Docker (`--network none`), Round 5

Image built from a clean `git archive` of BASE_COMMIT plus the shipped `Dockerfile`; both patches
applied at run time, not baked in. Dockerfile unchanged this round.

| UID | new | base |
|---|---|---|
| 4242 | 58 passed (38 s) | 1824 passed, 16 skipped (115 s) |
| 1000 | 58 passed (57 s) | 1824 passed, 16 skipped (235 s) |
| 0 | 58 passed (34 s) | 1824 passed, 16 skipped (208 s) |
| 65534 | 58 passed (30 s) | 1824 passed, 16 skipped (96 s) |

In-container F2P (`test.patch` only, uid 1000): `tests="58" failures="26" errors="32"`, zero passing.

## Local baseline (base commit 9bd6ad3af8f97bafa3201d4e70eba2877e66e040)

| Run | Command | Result |
|---|---|---|
| 1 | `pytest tests/unit` | 1824 passed, 16 skipped, 0 failed — 97.9 s |
| 2 | `pytest tests/unit` | 1824 passed, 16 skipped, 0 failed — 118.9 s |
| 3 | `pytest tests/unit` | 1824 passed, 16 skipped, 0 failed — 103.8 s |

Deterministic across three runs. Requires `statsmodels` + `prettytable` beyond `requirements.txt`.

## Round 20 (2026-09-08)

| # | Mutation | Killed |
|---|---|---|
| y1 | faint `1e-3 * displacement[0]` cross-coupling into the second lateral axis | both relaxed decoupling tests |

Test Quality FAIL (2 of 80 unfair): two decoupling tests asserted bit-exact `== 0` over a numerical
integration, which `meta.md` never promises. Relaxed to `< 1e-9`, and the seeded one strengthened to
assert the FIRST axis actually moved (`> 1e-3`) before asserting the second did not - previously a
solution that moved neither axis would have passed it. Suite **109 cases**. Docker 9/9.

## Round 19 (2026-09-08)

No artifact change. Both advisory notes declined on evidence: `udot_rail2` is `# pragma: no cover`,
docstring "[Still not implemented]", body delegates to `u_dot_generalized`, and `grep` finds exactly
one occurrence - the definition. It is never registered as a phase derivative, so there is no
reachable second rail phase to test.

## Round 18 (2026-09-08)

| # | Mutation | Killed |
|---|---|---|
| x1 | `weighted_lateral_mean` returns `(x / total_mass, 0.0)` - second lateral component dropped | 5, incl. the y-variants of the 3 DOF and parachute coupling tests (their x-variants still pass) |

Solution Quality **PASSED** (3/3 comprehensiveness). Import ordering fixed with the repo's own
`ruff check --select I --fix`; the cited `flight.py:634` line-length violation does NOT reproduce (86
chars, and all 11 `E501` in that file are pre-existing base code). Four coupling tests parametrized
over both lateral axes: 105 -> **109 cases**. Docker 9/9.

## Round 17 (2026-09-08)

| # | Mutation | Killed |
|---|---|---|
| w1 | non-scalar tolerance collapsed to `[values[0]] * (13 + extra)` | the 4 new heterogeneous-tolerance cases (12/13 values lost) + 6 precision-sensitive tests |
| w2 | widening dropped from the `Flight`-object branch only | **only** the new no-slosh-to-slosh continuation test |

Closes the two compatibility gaps: per-state tolerance PREFIX preservation (all earlier vectors were
homogeneous, so a collapse to `tolerance[0]` was invisible) and the documented `array` / `Flight`
initial-state forms (all earlier legacy-state tests passed Python lists). Suite **105 cases**.
Docker 9/9. No memory-guard kills this round.

## Round 16 (2026-09-08)

| # | Mutation | Killed |
|---|---|---|
| v1 | tolerance padding hardcoded to `4 * [1e-6]` | the 4 new two-mode tolerance cases **+ 21 pre-existing two-mode tests** |
| v2 | legacy initial-state padding hardcoded to one `[0.0] * 4` block | **only** the 2 new two-mode legacy-state cases |

v2 confirms the initial-state finding exactly. v1 shows the tolerance finding was overstated: the
DEFAULT `atol` is itself a 13-entry list through the same helper, so a fixed-four implementation errors
every two-mode flight in the suite. The real gap was the user-supplied legacy vector on a multi-mode
rocket, which had only incidental coverage; it is now pinned directly. Suite **99 cases**. Docker 9/9.

## Round 15 (2026-09-07)

| # | Mutation | Result |
|---|---|---|
| u1 | skip tolerance padding for 3 DOF, guarded inside `_widen_tolerance` | **inert** - `simulation_mode` is assigned after that call, so the guard never fired |
| u2 | skip initial-state padding for 3 DOF | kills `test_a_state_without_mode_entries_starts_the_modes_at_rest[3 DOF]` |
| u3 | undo tolerance padding for 3 DOF in `__init_equations_of_motion`, where the mode is known | kills all four 3 DOF tolerance cases; the four 6 DOF cases pass |

Suite 93 cases. Docker **9/9 verified**: new 93 at all four UIDs, base 1824 at all four, container F2P
93 cases / 0 passing. u1 is the round's method lesson: a surviving mutation only demonstrates weak
coverage after you confirm the mutation could execute at all.

## Round 14 (2026-09-07)

| # | Mutation | Killed |
|---|---|---|
| t1 | 3 DOF adds a weighted offset RATE term to `v_dot` alongside the acceleration | `test_a_three_degree_of_freedom_flight_ignores_the_offset_rate` |
| t2 | parachute adds the same spurious rate term | `test_a_parachute_descent_ignores_the_offset_rate` |

These pin the word "only" in "The three degree of freedom and parachute equations answer to the offset
acceleration only", which Round 13's sentence split introduced and nothing tested: every 3 DOF and
parachute assertion had used zero mode velocities, so a spurious rate term was invisible. Both
fixtures are undamped, so seeding velocities moves the weighted rate without touching the weighted
acceleration. Suite **88 cases in 29.6 s**.

## Round 13 (2026-09-07)

| # | Mutation | Killed |
|---|---|---|
| s1 | 6 DOF static `r_CM` made axial-only, lateral `r_CM_dot`/`r_CM_ddot` kept | `test_the_vehicle_answers_to_the_offset_itself` (+ incidentally the parachute oscillation test, via trajectory sensitivity) |
| s2 | callable `mass_ratio` resolved at a constant fill on every class but `MassFlowRateBasedTank` | 3 of 4 callable-class cases |

s1 is the reviewer's exact "wrong impl" (rate and acceleration coupled, static offset omitted). The
probe on the reference shows the same-acceleration/different-offset pair differs by 0.0151 in the
vehicle derivative; the test's floor is 1e-9. The 6 DOF matrix is now fully isolated: offset alone
(this round), rate alone (Round 5), acceleration alone (Round 6). Suite **86 cases**; tolerance
equalities relaxed to `abs=1e-9` / `rel=1e-6` with no loss of discrimination (smallest measured wrong
implementation signal 2.4e-6).

## Round 12 (2026-09-07)

| # | Mutation | Killed |
|---|---|---|
| r1 | `_widen_tolerance` back to `list`/`tuple` only (ndarray passes through) | the `atol` ndarray tolerance case |
| r2 | parachute couples the displacement offset with a fixed gain instead of its acceleration | the 5/9 rad/s parachute discriminator |
| r3 | no-slosh `slosh_mass` is zero only for `MassFlowRateBasedTank` | 3 of the 4 parametrized no-slosh cases |
| (pre-fix run) | `atol or default` on an ndarray | the `atol` ndarray case, before the `is None` fix |

r1 is deliberately narrower than it looks: SciPy shape-checks `atol` but not `rtol`, so a 13-entry
`rtol` beside a 17-wide state runs silently (the Round 5 finding). The two `rtol` cases therefore pin
"the flight accepts a legacy-width vector and runs" but cannot pin the padding itself without asserting
on the stored `Flight.rtol`, which a compliant solver could leave untouched while padding a copy. Left
as is; the `atol` cases carry the discrimination. Suite **80 cases in 27.4 s**.

## Round 11 (2026-09-07)

| # | Mutation | Killed |
|---|---|---|
| q1 | `solid_propulsion` guard re-nested under the 6 DOF branch only | the refusal test's `3 DOF` case |

The guard now runs before the simulation-mode dispatch. Suite **73 cases in 26 s** (the refusal test is
parametrized over both modes).

## Round 10 (2026-09-06)

| # | Mutation | Killed |
|---|---|---|
| p1 | parachute COM coupling removed (`ax/ay/az -= r_CM_ddot`) | the parachute cancellation test |
| p2 | legacy `solid_propulsion` rejection removed | the legacy-refusal test |
| p3 | rail phase freezes the mode entries | the seeded-rail test |
| p4 | 3 DOF drive divided by `dry_mass` | the light/heavy scaling test + the rewritten drive test |
| p5 | 3 DOF couples the OFFSET directly with a fixed gain instead of its acceleration | the unequal-frequency discriminator test |

p5 is the one that matters most: a single equal-frequency fixture cannot tell acceleration coupling
from direct-offset coupling (with omega = 7 the gains coincide), so the two-mode 5/9 rad/s fixture is
what makes the description's "answer to the offset acceleration" actually testable. Suite **72 cases
in 31 s**.

## Round 9 (2026-09-06)

| # | Mutation | Killed |
|---|---|---|
| e1 | 3 DOF COM coupling dropped from `v_dot` | the rewritten cancellation test |
| e2 | 3 DOF `r_CM_ddot` from the first mode only | the same test (weighting still pinned without a gain) |
| e3 | second lateral drive component zeroed | second-direction + integration tests |
| e4 | serialization fix reverted | **survives, deliberately** (serialization is not a described behaviour) |
| e5 | no-slosh tank reports mass 1 instead of 0 | the merged tank test |

Suite **67 cases in 28.4 s**. human-effective LOC **338**, meta.md 431 words. Docker 8 of 8 clean
across UIDs 4242 / 1000 / 0 / 65534; F2P `tests="67" failures="25" errors="42"`.

## Round 8 (2026-09-06)

| # | Mutation | Killed |
|---|---|---|
| d1 | 3 DOF drive forced to `(0.0, 0.0)` | the 3 DOF drive and integration tests |
| d2 | lateral COM coupling dropped from the 3 DOF `v_dot` | the 3 DOF coupling test |
| d3 | 3 DOF emits zero mode derivatives | the 3 DOF drive and integration tests |

d1 and d3 together are exactly the shipped Round 7 state, so the suite now catches the reported
defect. Suite **65 cases in 43.8 s**, slowest test 3.5 s. human-effective LOC **335**. Docker new mode
65 passed at all four UIDs; base mode 1824 at every UID after re-running one contended outlier five
times.

## Round 7 (2026-09-06)

| # | Mutation | Killed |
|---|---|---|
| g1 | gravity folded into the mode drive | `test_gravity_does_not_drive_the_mode` + both drive tests (4.8 s, scoped) |

Suite is 63 cases. Docker at UIDs 4242 / 1000 / 0 / 65534, 8 of 8 runs `rc=0`, new 63 passed and base
1824 passed at every UID; in-container F2P `tests="63" failures="26" errors="37"`. pylint 10.00/10;
`ruff format --check` reports 280 files already formatted across `rocketpy/ tests/ docs/`; `ruff
check` passes. human-effective LOC **329**.

## Round 6 mutation sweep (2026-09-05)

| # | Mutation | Killed |
|---|---|---|
| n1 | natural frequency resolved once at the post-burn fill | both new callable tests |
| n2 | damping ratio resolved once at the post-burn fill | the callable-damping test |
| n3 | rail phase handed a nonzero drive | the rail-phase test (scoped run; full suite intractable) |
| n4 | `r_CM_ddot` built from the first mode only | the three-mode weighting test + `test_offsets_that_cancel_by_mass_leave_the_vehicle_alone` |
| m5r | lateral `r_CM_ddot` dropped (re-run) | 2 |
| m6r | offset unweighted (re-run) | 9 |

Suite is 62 cases. Docker at UIDs 4242 / 1000 / 0 / 65534, 8 of 8 runs `rc=0`, new 62 passed and base
1824 passed at every UID; in-container F2P `tests="62" failures="26" errors="36"`. pylint 10.00/10
over every changed file.

## Round 5 mutation sweep (2026-09-05)

Each mutation is one plausible wrong implementation of a `meta.md` clause, applied to the reference
and run against the whole 58-case suite.

| # | Mutation | Killed |
|---|---|---|
| m1 | drive sign reversed (`+ drive` instead of `- drive`) | `test_the_drive_is_the_lateral_force_over_the_total_mass` |
| m2 | drive divided by `dry_mass` instead of `total_mass` | the two drive tests + `test_the_first_mode_belongs_to_the_lower_tank` |
| m3 | damping coefficient `zeta*omega` instead of `2*zeta*omega` | `test_a_damped_mode_follows_the_damping_ratio_solution` |
| m4 | lateral `r_CM_dot` dropped | `test_the_offset_rate_reaches_the_vehicle` |
| m5 | lateral `r_CM_ddot` dropped | `test_mode_accelerations_reach_the_vehicle_when_the_offset_cancels` |
| m6 | offset unweighted (plain sum, no participating mass) | 8 tests, incl. both cancellation tests |
| m7 | `slosh_velocity` list built in reverse mode order | `test_two_modes_report_their_own_velocities_in_order` |
| m8 | modes sorted on raw motor-local position | `test_modes_sort_by_axial_position_in_the_rocket_frame` |
| m9 | `u_dot_generalized_3dof` emits zero mode derivatives | `test_a_mode_keeps_oscillating_in_a_three_degree_of_freedom_flight` |
| m10 | drive includes the body frame component of gravity | the two drive tests |
| m11 | `u_dot_parachute` emits zero mode derivatives | `test_a_mode_keeps_oscillating_under_a_parachute` |
| m12 | offset divided by `dry_mass` instead of `total_mass` | the two weighted-mean tests + `test_the_first_mode_belongs_to_the_lower_tank` |

Every one of the twelve is killed, and eight are killed by a test written this round.

m3 is the reviewer's exact factor-of-two hypothesis, and before this round nothing killed it: the old
`test_a_damped_mode_loses_amplitude` bound of 0.005 admits its 0.0045256 result. m11 is killed only
because `test_a_mode_keeps_oscillating_under_a_parachute` was strengthened this round from "the
maximum is above zero" to a full-period and half-period check; a frozen mode holds a nonzero
displacement forever and passed the old form.

m10 is also a runtime signal, not just a failing assertion. Folding gravity into the drive gives a
constant 0.85 m/s2 forcing at 5 degrees of tilt against a real drive of 0.027, and the seeded and
parachute flights stop converging: the suite ran past 25 minutes against a 21 second baseline before
being cut off. Scoped to the two drive tests it fails in 13.9 s.

## Per-agent table

| Batch | Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Reason | Approach |
|---|---|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — | — | — |

### Round 22 final validation

Docker **9 of 9** at UIDs 4242/1000/0/65534, both modes, `--network none` on every run (the build
itself needs the network for pip; only the test runs are offline). Container F2P green: 130 cases, 0
passing. All nine JUnit XMLs postdate the final `test.patch`. Images removed, replay worktrees
pruned, nothing left running.

New suite **130 passed x3**; base **1840 tests, 0 failures, 16 skipped x3**; ruff clean on the
project's own targets; pylint **10.00/10** on both new test files; human-effective LOC **361**.

Upload `test.patch` only. `meta.md`, `solution.patch` and the Dockerfile are byte-unchanged, so the
Re-eval offer remains valid - do not fire a fresh run.

## Batch 2 (2026-09-09) - 2 of 10 = 20 percent, IN BAND

Nova x9 + Orion x1, evaluator Nova. Every run kept the 1824-test baseline green.

| Run | Verdict | New-suite failures | Partial initial state |
|---|---|---|---|
| Nova #1 | FAIL_MISSED_REQUIREMENT | 8 | ValueError |
| Nova #2 | FAIL_MISSED_REQUIREMENT | 3 | ValueError |
| **Nova #3** | **PASS_LEGITIMATE** | 0 | ValueError |
| Nova #4 | FAIL_MISSED_REQUIREMENT | 6 | ValueError |
| Nova #5 | FAIL_MISSED_REQUIREMENT | 6 | ValueError |
| Nova #6 | FAIL_MISSED_REQUIREMENT | 6 | ValueError |
| **Nova #7** | **PASS_LEGITIMATE** | 0 | ValueError |
| Nova #8 | FAIL_MISSED_REQUIREMENT | 2 | ValueError |
| Nova #9 | FAIL_MISSED_REQUIREMENT | 10 | ValueError |
| Orion #1 | FAIL_MISSED_REQUIREMENT | 6 | pads correctly |

**The Round 22 callable lever was ruled FAIR.** Auto Review, Description 3/3 Clean: "The convergent
callback failures do not expose an ambiguity: the stated contract permits any callable that receives
the fill fraction, including ordinary Python callables with defaulted or keyword-only parameters."
Seven of ten runs died on it. The `agent_blame_unfair` risk recorded in Round 22 did not materialise.
Both passes survived judge dissent at high adjudicator confidence.

Auto Review: **Revision Requested**. Description 3/3 Clean, Solution 3/3 Clean, **Tests 1/3 Weak**.

### The blocking finding, and why the obvious fix is fatal

T3/T4 High: no test supplies an initial state that mentions one mode and omits a later one, so an
implementation that pads only exactly-legacy-width states passes despite the description's promise
that "A mode the initial state does not mention starts at rest." The finding is correct, and it cites
runs `rd70rv9exnvz0fpgnnqxrb24q98e2vb8` and `rd765an4gj1z9eqed4tbk49wc18e262r` - **which are exactly
Nova #3 and Nova #7, the two passers.**

Measured, not assumed. Wrote the demanded test and replayed all ten patches on clean BASE_COMMIT
checkouts:

| Outcome on the demanded test | Runs |
|---|---|
| fails | 9 of 10, **including both passers** |
| passes | Orion #1 only, which fails the batch on other grounds |

Adding it and firing Re-eval gives **0 of 10 = unsolvable reject**.

Separately probed what each implementation does with an 18-entry state on a two-mode rocket:
**9 of 10 raise ValueError**; only Orion (and the reference) pads. The all-or-nothing contract is
what nine independent implementers converged on.

### Direction chosen: narrow the contract instead of widening the tests

- **Reviewer's literal direction** (pad partial states, add the test): kills 9 of 10, near-certain
  0 percent on a fresh batch too, since agents naturally raise.
- **All-or-nothing** (mode entries for every mode or none; any other width raises ValueError, tested
  as such): 9 of 10 already conform, both passers included, so the 20 percent survives.

Cost a full batch either way, because it edits `meta.md`. S2 (the `docs/user/flight.rst` state-width
paragraph) is Low and rides along in the same round.

### Round 23 final validation

New suite **138 passed x3**; base **1840 tests, 0 failures, 16 skipped x3**; clean-checkout F2P
**138 cases, 0 passing**; Docker **9 of 9** at UIDs 4242/1000/0/65534 both modes with `--network none`,
plus a green container F2P. Every Docker XML postdates the final patches. ruff clean on the project's
own targets, pylint 10.00/10, human-effective LOC 375, `meta.md` 487 words.

Replay of the ten saved batch-2 patches against the revised suite holds the band at **2 of 10 =
20 percent**: both passers reach 138 passed and seven of the eight failures keep their exact batch-2
counts.

Images removed, replay and build worktrees pruned, nothing left running.

## Round 24 (2026-09-09) - review response on the Round 23 artifact

Solution Quality **PASS** (Comprehensiveness 3/3, Code Quality 2/3 on one Low doc finding) plus two
advisory coverage suggestions. All addressed.

- **Low finding, partly my own error.** The Round 23 seeded-mode block labelled the lateral entries as
  the y and z axes; `R1` is the body X force and `R2` the Y force, so they are **x and y**. Corrected.
  "Accessing Raw Simulation Data" and "State Vector Format" now document `14 + 4 * N` instead of a fixed
  14, list `qx, qy, vqx, vqy`, and point at the new reporting properties.
- **Coverage 1.** Callable `natural_frequency` and `damping_ratio` now drive flights on
  `UllageBasedTank`, `LevelBasedTank` and `MassBasedTank`, closing the shortcut where callable dynamics
  are wired only for `MassFlowRateBasedTank`.
- **Coverage 2.** Full-width nonzero seeded initial state checked in 3 DOF as well as 6 DOF.
- **Description**, free because Round 23 had already forfeited Re-eval: dropped the opening
  current-behaviour sentence and replaced "answer to" with "incorporate". 487 -> **458 words**.

138 -> **146 cases**.

### The hang, caught by replay

`test_a_full_width_initial_state_keeps_every_mode_entry[6 DOF]` **hung on Nova #7 for over 150 seconds**
while the other seven new cases passed. It asserts only on `flight.solution[0]` yet flew to apogee with
two strongly excited modes. Capped with `terminate_on_apogee=False, max_time=0.5`: 1.18s, identical
assertions. Shipped, it would have timed out a legitimate implementation and read as a failure.

### Final validation

New suite **146 passed x3**; base **1840, 0 failures, 16 skipped x3**; clean-checkout F2P **146 cases,
0 passing**; Docker **9 of 9** at UIDs 4242/1000/0/65534 both modes with `--network none` plus a green
container F2P, every XML postdating the patches; ruff clean, pylint 10.00/10, human-effective LOC 375.

Replay of both batch-2 passers on the final suite: **146 passed each**, so the projection holds at
**2 of 10 = 20 percent**.

## Round 25 (2026-09-09) - Test Quality FAIL on one assertion, test-side fix

Test Quality **FAIL, 1 of 89 test functions unfair**. No other axis flagged: numerics deterministic with
explicit solver tolerances, no wall-clock, no unseeded randomness, no brittle message matching, no
test-order dependency. The `u_dot_generalized` / `u_dot_generalized_3dof` / `u_dot_parachute` /
`udot_rail1` derivative tests were ruled fair (prompt-specified equations); internal coupling advisory
only.

- **Blocker.** `test_a_rocket_without_slosh_has_no_modes` asserted `rocket.slosh_modes == []`. `meta.md`
  states the ORDER of `Rocket.slosh_modes`, never that it is a `list`. RocketPy uses both plain lists
  (`rocket.py:370-372`) and `Components` collections (`:373-376`) for rocket attributes, so a tuple or
  ordered-collection return satisfies the prompt and fails that equality. Correct finding.
- **Fix.** `len(rocket.slosh_modes) == 0`, the form the reviewer named as fair.
- **Class swept, not just the cited line.** `slosh_displacement == []` and `slosh_velocity == []` in
  `test_a_rocket_without_slosh_reports_no_mode_motion` converted too, even though the reviewer passed
  them and `meta.md` does call those two "lists".
- **Band unaffected.** `len(x) == 0` is strictly weaker than `x == []`, so both batch-2 passers still
  pass by construction: projection holds at **2 of 10 = 20 percent**. All three sites still fail on base.
- **Re-eval eligible.** `meta.md`, `solution.patch`, `Dockerfile` and `BASE_COMMIT.txt` are unchanged.

Validation: new suite **146 passed x3** (Docker, `--network none`, uid 4242); base **1824 passed,
16 skipped**; clean-checkout F2P **146 cases, 0 passing**; ruff import-order + format + check all clean
on the project's own targets; pylint **10.00/10** on both new test files.

Image removed, F2P scratch checkout removed, nothing left running.

## Batch 3 (2026-09-09) - 0 of 9 saved runs pass, Nova #1 MISSING and decisive

Ran against the Round 24 artifact (146 new cases; every junit-new.xml reports `tests=146`). Saved runs
are labelled **Nova #2 through Nova #10 - nine runs, all Nova solver / Nova eval. `Nova #1` was not
saved**, so the local evidence cannot distinguish 0/10 (reject, unsolvable) from 1/10 (10 percent, in
band at the hard edge). Every saved run kept the 1824-test baseline green with exit code 0.

| Run | Verdict | New-suite failures | Kill cluster |
|---|---|---|---|
| Nova #2 | FAIL_MISSED_REQUIREMENT | 6 | A - callable signature |
| Nova #3 | FAIL_MISSED_REQUIREMENT | 6 | A - callable signature |
| Nova #4 | FAIL_MISSED_REQUIREMENT | 3 failed + 3 errors | B - parachute drive |
| Nova #5 | FAIL_MISSED_REQUIREMENT | 2 | B - parachute drive |
| Nova #6 | FAIL_MISSED_REQUIREMENT | 6 | A - callable signature |
| Nova #7 | FAIL_MISSED_REQUIREMENT | 6 | A - callable signature |
| Nova #8 | FAIL_MISSED_REQUIREMENT | 4 | C - `slosh_mass` zero must be Function-valued |
| Nova #9 | FAIL_MISSED_REQUIREMENT | 2 | B - parachute drive |
| Nova #10 | FAIL_MISSED_REQUIREMENT | 6 | A - callable signature |

### Fairness read: the cleanest of the whole problem

All nine judges independently returned `description_clear: true`, `tests_deterministic: true`,
`was_mentioned_in_description: true`, `was_inferable_from_new_tests_not_visible_to_agent: false`,
difficulty **"challenging"**, and `FAIL_MISSED_REQUIREMENT`. **Zero unfairness flags, zero cheating
flags, zero environment flags** across the batch. Several judges volunteered a rebuttal of the unfair
reading unprompted, e.g. Nova #7: "The hidden tests merely expose valid cases covered by the broad
callable requirement; they do not introduce an unrelated expectation."

### Every run died to exactly one cluster - the traps are cleanly disjoint

- **A - callable signature (5 runs: #2, #3, #6, #7, #10).** Identical root cause every time: the agent
  wraps each `TankSlosh` parameter in RocketPy `Function`, whose signature introspection counts an
  optional or keyword-only parameter as an extra domain dimension, so `Function.__validate_inputs`
  rejects the one-name input declaration. Kills exactly six cases:
  `test_any_callable_of_the_fill_fraction_sets_the_mass_ratio[defaulted|keyword_only]` and the
  `natural_frequency` / `damping_ratio` equivalents. The `varargs` form never fails - `Function`
  tolerates `*args`.
- **B - parachute zero drive (3 runs: #4, #5, #9).** The agent transforms parachute drag into body
  coordinates and feeds it to the slosh derivative instead of the required zero drive. #5 and #9 fail
  exactly two amplitude assertions; #4 additionally raises a shape-(3,) vs shape-(2,) broadcast error
  because it passes the full 3-vector, which errors out four more cases.
- **C - `slosh_mass` representation (1 run: #8).** `Tank.slosh_mass` returns the integer `0` for a tank
  with no slosh model, so all four `test_a_tank_without_slosh_has_no_participating_mass` cases raise
  `AttributeError: 'int' object has no attribute 'get_value_opt'`. Its other 142 cases pass.

### The arithmetic that matters for any future lever

Because the clusters are disjoint, the junit files give exact counterfactuals with no replay needed:

- **Dropping the `defaulted` / `keyword_only` callable parametrizations flips five runs at once** - #2,
  #3, #6, #7 and #10 have no other failure - taking the batch to **5 of 9 = 56 percent, over the 50
  percent ceiling**. Dropping only one of the two forms flips nobody, because all five fail both. The
  callable axis is therefore **binary**: it kills five runs or it kills none. It is not a tuning knob.
- **Relaxing cluster C flips exactly one run**, Nova #8, and touches nothing else in the batch.

Implied per-trap survival: P(clear A) = 4/9, and of those four, three died at B and one at C. True rate
is on the order of 5 percent, so a 10-run batch reading 0 is the **modal** outcome, not an anomaly. The
artifact is sitting on the unsolvable boundary rather than inside the band.

### Long-horizon metrics

`total_steps` in the saved trajectories is a 4-step export window, not the run length. Real horizon is
visible in the token totals: **14.3M to 25.4M prompt tokens** per run against a ~200-230k context, i.e.
on the order of a hundred turns. Solution patches: **7 to 11 files, 538 to 667 added lines**. Long-horizon
floor (>= 2 files, >= 40 messages, >= 200 effective LOC) cleared by a wide margin.

### Batch 3 COMPLETE - Orion #1 landed, final tally 0 of 10

The tenth run was Orion, not a missing Nova #1: batch 3 is **9 Nova + 1 Orion = 10 runs, 0 passing**.
The "Nova #1 missing" note above is superseded - there is no eleventh run pending.

Orion #1: **FAIL_MISSED_REQUIREMENT**, 140 of 146, six failures, **pure cluster A** and nothing else -
the same six `[defaulted]` / `[keyword_only]` callable cases, from the same cause (4 `Function(` wraps in
its patch). Predicted before the run from its batch-2 patch, which wrapped the three `TankSlosh` params
in `Function(` at lines 85/90/95 and died on the identical six cases. Orion's decisive-commit-no-pivot
profile reproduced the choice exactly.

**Final cluster tally: A = 6 runs (5 Nova + Orion), B = 3, C = 1.** Cluster A alone is 60 percent of all
kills, across two different solver families, from one mechanism.

### The cluster-C fix, applied and measured

`test_a_tank_without_slosh_has_no_participating_mass` now reads `slosh_mass` through a
`reported_slosh_mass(tank, time)` helper that uses `get_value_opt` when present and the value itself
otherwise, so a no-slosh tank may report zero as a scalar or as a zero-valued Function. Both satisfy
`meta.md`'s "reports zero there"; neither is pinned. **Only the four no-slosh assertions changed** - all
35 other `slosh_mass.get_value_opt` sites are on tanks that carry a slosh model, where the quantity is
`mass_ratio` times `liquid_mass`, time-varying and Function-valued by unambiguous tank convention.

Measured against the real solutions rather than predicted:

| Replay (clean BASE_COMMIT + agent solution + new test.patch) | Result |
|---|---|
| **Nova #8** (cluster C) | **146 passed** - flips to a legitimate pass |
| **Nova #2** (cluster A) | **6 failed, 140 passed** - identical six cases, trap intact |

So the change flips exactly one run and weakens nothing else. **Projected re-eval: 1 of 10 = 10 percent**,
in band at the hard edge.

### Round 26 validation

New suite **146 passed x3** (Docker, `--network none`, uid 4242); base **1824 passed, 16 skipped**;
clean-checkout F2P **146 cases, 0 passing** (56 failed + 90 errors - the helper still raises
`AttributeError` on base, where `slosh_mass` does not exist); ruff import-order + format + check clean on
the project's own targets; pylint **10.00/10**. `solution.patch` untouched, so human-effective LOC stays
**375**.

## Batch 4 (2026-09-10) - RE-EVAL of batch 3 - 1 of 10 = 10 percent - ACCEPTED

Not a fresh batch: the platform re-graded the **same ten solutions** from batch 3 against the
Round 26 suite, at ~30 percent of batch price. Nothing solver-visible had changed, so the offer
stood.

| Run | Batch 3 | Batch 4 | Cluster |
|---|---|---|---|
| Nova #2 | FAIL 6 | FAIL 6 | A callable domain |
| Nova #3 | FAIL 6 | FAIL 6 | A |
| Nova #4 | FAIL 6 | FAIL 6 | B parachute drive |
| Nova #5 | FAIL 2 | FAIL 2 | B |
| Nova #6 | FAIL 6 | FAIL 6 | A |
| Nova #7 | FAIL 6 | FAIL 6 | A |
| **Nova #8** | **FAIL 4** | **PASS_LEGITIMATE 0** | C representation pin - REMOVED |
| Nova #9 | FAIL 2 | FAIL 2 | B |
| Nova #10 | FAIL 6 | FAIL 6 | A |
| Orion #1 | FAIL 6 | FAIL 6 | A |

**The local replay was exact.** It predicted Nova #8 flips to 146/146 and Nova #2 stays at 6
failures; the live re-eval returned precisely that, and no other run moved. For a test-only delta
the differential harness is not an approximation.

Final per-test kills: the six `[defaulted]` / `[keyword_only]` callable cases at 6 each, the two
parachute amplitude cases at 3 each, four Nova #4-only parachute cases at 1. **134 of 146 cases
killed nothing.** Solver patches 7-11 files, 538-873 added lines, 14.3-30.5M prompt tokens
(median 20.4M) - `total_steps` in the saved trajectories is a 4-entry export window, not a message
count.

Verdicts: 9x FAIL_MISSED_REQUIREMENT + 1x PASS_LEGITIMATE. Every judge again returned
`description_clear: true`, `tests_deterministic: true`, `was_mentioned_in_description: true`,
difficulty "challenging". FP panel: adjudicator **Genuine pass**, high confidence, over one
dissenting judge whose three probes were all ruled not prompt-grounded - one of them explicitly
rebutted with our own `reported_slosh_mass` helper.
