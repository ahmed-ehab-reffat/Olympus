# DESIGN.md — rocketpy-propellant-slosh

## 1. Title

Add lateral propellant slosh to the six degree of freedom flight model

Verb: **Add** -> Category `feature-request`. Names the subsystem (the 6-DOF flight model) and the
capability (lateral propellant slosh). 10 words.

## 2. Shape classification

- **Shape:** O-Composite-add (new capability spanning motors + rocket + simulation), with a strong
  S-A "second mode over shared machinery" component (opt-in; default path must stay bit-identical).
- **Capability shape (CAPABILITY-SHAPES.md):** **S-B missing domain effect** (the largest and
  safest approved cluster) crossed with **S-A**. The domain model omits a real phenomenon; adding it
  threads through every existing consumer of the mass-property model.
- **Pass-rate target:** 10-25%. Ceiling is 50%; design to the hard edge.
- **Best agent:** Orion (decisive multi-file implementation) mixed with Nova.
- **Dominant predicted verdict:** MISSED_REQUIREMENT, then REGRESSION (baseline preservation).

## 3. Public API surface

- `TankSlosh(mass_ratio, natural_frequency, damping_ratio)` — per-tank lateral slosh model. Each
  argument is a number or a callable of the tank fill fraction.
- `TankSlosh.mass_ratio` / `.natural_frequency` / `.damping_ratio` — as supplied.
- `Tank(..., slosh=None)` — new keyword on every concrete tank class
  (`MassFlowRateBasedTank`, `UllageBasedTank`, `LevelBasedTank`, `MassBasedTank`).
- `Tank.slosh` — the `TankSlosh` or `None`.
- `Tank.slosh_mass` — `Function` of time: `mass_ratio(fill) * liquid_mass`.
- `LiquidMotor.slosh_modes` / `HybridMotor.slosh_modes` — list of modes with axial positions in the
  motor frame.
- `Rocket.slosh_modes` — list of modes with axial position relative to the centre of dry mass.
- `Flight.slosh_displacement` — list of `Function`s, one per mode, of lateral displacement magnitude.
- `Flight.slosh_velocity` — list of `Function`s, one per mode.
- `Flight.lateral_center_of_mass_offset` — `Function` of time, the body-frame lateral offset the
  slosh masses impose on the vehicle centre of mass.

## 4. Canonical output form

- **Mode ordering:** `Rocket.slosh_modes` is ordered by the axial position of the tank the mode
  belongs to, measured in the rocket frame, ascending. Ties broken by the order tanks were added.
- **State layout:** the flight state vector keeps its existing 13 entries and appends, per mode in
  the order above, four entries `[sx, sy, sx_dot, sy_dot]`.
- **Units:** displacements in metres, velocities in metres per second, frequency in radians per
  second, damping ratio dimensionless, `mass_ratio` a fraction of the liquid mass.
- **Zero case:** a rocket with no `TankSlosh` anywhere has no extra state entries and must produce
  results identical to the current model.
- **Empty tank:** when the liquid mass is zero the mode's participating mass is zero, it applies no
  force, and its displacement is held at zero rather than being integrated.
- **Sign convention:** `sx` and `sy` are measured in the body frame along the same axes as the
  existing body-frame angular velocity components.

## 5. Blind-spot pre-empts

- Unstated inverse: state that the lateral offset is the participating-mass-weighted mean, and that
  it is zero when every mode is centred.
- Iteration termination: none (no fixpoint here).
- Result-list ordering: the mode-ordering sentence above (agents default to insertion order).
- Parallel API: the four concrete tank classes all take `slosh`; say so once rather than listing.
- Falsy-on-invalid: `mass_ratio` of zero behaves exactly like `slosh=None`.
- **Codebase-inferable count: 1** (that the body frame axes match the existing angular-velocity
  components). Everything else is stated.

## 6. Description draft (meta.md)

Target 200-260 words, hard cap 500. Body opens with the ask:

> Add lateral propellant slosh to the flight model. RocketPy treats the fluid in a tank as rigid: a
> tank reports its centre of mass as a height on the tank axis, so the vehicle centre of mass is
> always on the body centreline and liquid can never move sideways. [...]

Then: the mechanical model (a damped lateral oscillator per tank, its three parameters, the
driving term), the coupling (participating-mass-weighted lateral offset), the ordering and state
layout, the zero/empty cases, and the preservation requirement.

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Effective |
|---|---|---|---|---|
| NEW | `rocketpy/motors/slosh.py` | — | +200 | ~110 |
| MODIFY | `rocketpy/motors/tank.py` | 1838 | +90 | ~50 |
| MODIFY | `rocketpy/motors/motor.py` | 2124 | +70 | ~40 |
| MODIFY | `rocketpy/motors/liquid_motor.py` | 537 | +45 | ~25 |
| MODIFY | `rocketpy/rocket/rocket.py` | 2580 | +130 | ~75 |
| MODIFY | `rocketpy/simulation/flight.py` | 4626 | +260 | ~150 |
| MODIFY | `rocketpy/__init__.py` | — | +2 | ~2 |

TOTAL: ~797 raw / **~452 effective** across 6 modified + 1 new file.

Floor check: >= 200 effective and >= 2 files. Clears with a wide buffer. RocketPy's numpydoc
convention means a high raw-to-effective ratio, so the raw target is deliberately ~800.

## 8. Solution outline — pure-function helpers

- `TankSlosh.evaluate_at(fill_fraction)` -> `(mass_ratio, omega, zeta)` — resolves callables.
- `Tank.slosh_mass` — `Function` of time.
- `_slosh_mode_positions(motor)` — axial position per mode in the motor frame.
- `Rocket._collect_slosh_modes()` — ordered modes with rocket-frame positions.
- `_slosh_lateral_offset(modes, masses, states, total_mass)` -> `Vector` — the participating-mass
  weighted lateral offset. **This is the identity the tests pin exactly.**
- `_slosh_lateral_offset_rate(...)` -> `Vector` — its time derivative from the mode velocities.
- `_slosh_mode_derivative(omega, zeta, s, s_dot, drive)` -> `(s_dot, s_ddot)` — the per-mode ODE.
- `Flight._slosh_state_slice(index)` — locates a mode's four entries.

No fixpoint loop. No recursion.

## 9. Test file outline

Two new files, random hex suffix per the naming rule:

- `tests/unit/motors/test_tank_slosh_<hex>.py` — the tank/motor/rocket-side API.
- `tests/unit/simulation/test_flight_slosh_<hex>.py` — the flight coupling.

Block layout: imports -> builder helpers reusing `tests/fixtures/motor/tanks_fixtures.py` and
`tests/fixtures/rockets/` -> assertion helpers -> granular tests.

Buckets and the atoms each covers:

- **Model resolution:** constant and callable parameters; `mass_ratio=0` equals `slosh=None`;
  participating mass tracks liquid mass; empty tank gives zero participating mass.
- **Mode collection and ordering:** single tank; two tanks ordered by axial position; tie broken by
  insertion order; a tank without slosh contributes no mode.
- **State layout:** four entries appended per mode; length identity; a no-slosh rocket appends none.
- **Dynamics (analytic limits, no external oracle needed):** undamped free oscillation holds its
  amplitude and its period equals `2*pi/omega`; critical damping does not overshoot; a mode released
  at zero displacement with no lateral drive never moves.
- **Coupling identity:** `lateral_center_of_mass_offset` equals the weighted mean, exactly.
- **Axis separation:** a pure body-x excitation leaves `sy` at zero, and the mirrored case.
- **Cross-product cell (F-10):** two tanks with different frequencies, excited on the y axis.
- **Phase pass-through:** a flight with slosh that leaves the rail, coasts and descends under
  parachute completes without shape errors and keeps the extra entries consistent.
- **Baseline preservation:** a rocket built without slosh reproduces the reference trajectory
  exactly.

Target ~70-95 tests.

## 10. Forced signatures

- `TankSlosh.__init__` keyword names and order are pinned in meta.md so no agent has to guess.
- `Tank.__init__` gains `slosh=None` as a keyword-only argument on all four concrete classes; stated.
- `Flight` outputs are lists indexed by mode; stated, so no return-shape coin flip.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | Mass properties are time-indexed, so a state-dependent lateral CM cannot be expressed where agents naturally put it | **F-1** | S4 | where the state-dependent quantity is computed | #2 | `Tank.center_of_mass` is `@funcify_method` and `Rocket.get_inertia_tensor_at_time(t)` takes only `t`; `u_dot_generalized` pins `r_CM = Vector([0, 0, r_CM_t])` (`flight.py:2508-2513`). Patching the tank looks right and cannot work | states the offset is a property of the flight state, never of time alone | coupling identity + free-oscillation |
| 2 | `r_CM_dot` and `r_CM_ddot` keep their axial-only form | new (guess) | S4 | conservation of the model's own invariants | #1 | the natural edit adds lateral terms to `r_CM` and stops; the derivative vectors are three lines below and look like bookkeeping | states the offset "and its rate" enter the equations | undamped amplitude-hold test |
| 3 | Two-tank, single-axis composition | **F-10** | S2 | multiplicity x polarity | — | agents implement one mode and one axis and generalise by symmetry | ordering + weighted-mean sentences | the off-diagonal cell |
| 4 | Extended state not propagated by the other five derivative functions | **F-14**-adjacent | S5 | dual-path consistency | #1 | only `u_dot_generalized` looks like "the" ODE; rail, 3-DOF and parachute phases each unpack 13 entries | states slosh persists across every flight phase | phase pass-through test |
| 5 | Default path perturbed | — | **S3** | baseline preservation | #1, #4 | the natural refactor makes `r_CM` construction unconditional | states the no-slosh result is unchanged | 1824-test base suite |

Every trap is contract-stated and fix-hidden: the meta says what the model does and what the outputs
are, never which vectors in `u_dot_generalized` acquire terms.

## 11b. Capability cross-product matrix (F-10)

| | body-x excitation | body-y excitation |
|---|---|---|
| **one tank** | test: single mode, x only, `sy` stays zero | test: single mode, y only, `sx` stays zero |
| **two tanks** | test: two modes, differing frequencies, x | **off-diagonal:** two modes, differing frequencies, y, weighted offset checked against the identity |

Predicted failure mode of the composition cell: over-firing — the offset is summed without dividing
by the total mass, or the second mode's participating mass is taken from the first tank.

## 12. Tier + category

- Tier: Olympus. Sub-rank target: Good.
- Category: **feature-request** (title verb "Add", net-new public type `TankSlosh`).

## 13. Predicted pass rate

**10-25%.** Five traps, three of them interdependent through the same chokepoint, plus a large
baseline-preservation surface (1824 tests). The main uncertainty is upward: the mechanical model is
textbook, so an agent that finds the right chokepoint quickly may clear it. The F-1 wall is what
holds the rate down, and it is structural rather than stated.

## 14. Quality gates

- [x] Repo understanding 5/5 (architecture, subsystems, entanglement zones, pytest + fixtures,
      template file `tests/unit/motors/test_tank.py`)
- [x] Phase 2 clean: `slosh`/`sloshing`/`aeroelastic` return zero code hits, zero issues, zero PRs,
      on `master` and on `develop`. Neighbouring lanes checked and avoided: staging is
      exclusivity-dead (open PR #1155), fin flutter is absorbed (`utilities.py`).
- [x] Gate 5: `tank.py` 3 and `liquid_motor.py` 0 commits in 12 months on `develop`
- [x] Gate 9: baseline deterministic 3/3, 1824 passed / 0 failed / 16 skipped, ~110 s
- [x] Competitor profiling clean
- [x] Effective LOC sketch clears the floor with buffer (~452 vs 200)
- [x] Traps on different axes, three interdependent
- [x] Cross-product matrix filled, off-diagonal has a test
- [ ] Owed: Dockerfile offline build + `--network none` run; FP mutation sweep; clause-coverage sweep

## Why this is not a duplicate

Nearest prior art in our own corpus is `acoular-reflecting-panels` (a propagation-model domain effect
threaded through a steering vector) and `sfepy-adaptive-stepping-accounting` (an accounting layer over
a solver). This shares the S-B shape with the first but nothing else: different repo, different
domain, and the difficulty here is a **state-vector extension against a time-indexed mass model**,
which neither of those touches. RocketPy has no prior submission in any directory.

## Predicted iteration cycles: 2
