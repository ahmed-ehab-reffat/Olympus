# DESIGN.md — mpmath-odefun-events

## 1. Title

Add event detection and backward integration to odefun

Verb-led, names the subsystem (`odefun`, the arbitrary-precision ODE solver in
`mpmath/calculus/odes.py`).

## 2. Shape classification

- Shape: **O-Composite-add** with an O-Algorithm-correctness core (PLAYBOOK § Pattern 12).
  A new capability spans the solver core (Taylor stepper), a new solution object,
  the public package namespace and a second public entry point (`odebvp`), while the
  hard part is a correctness kernel (where a crossing is located, which branch a point
  belongs to, what state a restart uses).
- Pass rate target: **<= 40% (sprint cap)**; designed for the hard edge, predicted 1-2 of 10.
- Best agent: Vega / Orion (multi-file, one coherent object rewrite).
- Dominant verdict expected: MISSED_REQUIREMENT (branch/ordering semantics) and
  INTEGRATION_ERROR (analysis methods that ignore the segment structure).

## 3. Public API surface

- `mpmath.ODEEvent(g, direction=0, terminal=False, reset=None, switch=None)` — condition watched while integrating.
- `ODEEvent.direction` — -1, 0 or 1; validated.
- `ODEEvent.terminal` — `False`, `True` or a positive whole number; validated.
- `ODEEvent.reset(x, y)` — replacement state at a crossing.
- `ODEEvent.switch(x, y)` — replacement derivative function after a crossing.
- `odefun(F, x0, y0, tol, degree, method, verbose, events=None, maxevents=None)` — returns the solution object.
- `sol(x)` — value at any `x` on either side of `x0`.
- `sol.diff(x, n=1)` — n-th derivative of the local expansion.
- `sol.taylor(x, n)` — coefficients of the local expansion.
- `sol.integral(a, b, f=None)` — componentwise integral, or the integral of `f(x, y(x))`.
- `sol.crossings(level, a, b, index=0)` — every point where a component equals a level.
- `sol.roots(g, a, b)` — every point where a function of the solution vanishes.
- `sol.extrema(a, b, index=0)` — interior stationary points of a component.
- `sol.maximum(a, b, index=0)` / `sol.minimum(a, b, index=0)` — `(x, value)` pairs.
- `sol.events` — one record list per event; entries are `(x, state)`.
- `sol.domain` — `(left, right)` endpoints, `-inf`/`inf` where open.
- `odebvp(F, x0, y0, x1, y1, guess=None, stop=None, tol=None, degree=None, verbose=False)` — two point problem by shooting.

## 4. Canonical output form

- Event records: sorted by ascending `x`, one list per event in the order given.
- Recorded state: the value approached from the starting point, before `reset`.
- `sol(x)` and `sol.diff(x)` at a crossing: the same pre-reset branch.
- `crossings` / `roots` / `extrema`: ascending `x`; ranges are closed for `crossings`
  and `roots`, open for `extrema`.
- `maximum` / `minimum`: `(x, value)`, endpoints included.
- `integral`: reversed limits negate, equal limits give zero.
- `taylor`: one list per component, a single list in scalar mode, coefficient k is
  the k-th derivative over k factorial.
- `domain`: `(-inf, inf)` until a terminal event bounds a side.
- Direction sense: always with respect to increasing `x`, independent of the
  direction of integration.
- Errors: `ValueError` for a bad direction, a bad terminal count, a non-positive
  `maxevents`, a complex event value, a negative derivative order, an empty range,
  an unknown component index, mismatched boundary conditions, and any evaluation or
  search past a stop.

## 5. Blind-spot pre-empts

- Result ordering: "sorted by ascending `x`" (event records, crossings, extrema).
- Adjacent-vs-all: "returns every `x` in the closed range" (forces subdivision of a
  step rather than one bracket per step).
- Rule resolution: "the sense always refers to increasing `x`, whichever way the
  solution is being extended".
- Iteration termination: "a zero at the point a step starts from ... is not a crossing".
- Falsy-on-invalid: `ValueError` cases enumerated per argument.
- Parallel API: `sol.integral(a, b)` and `sol.integral(a, b, f)` given the same
  sign and empty-range rules.

## 6. Description draft

See `meta.md` (755 words, 8 body paragraphs, all under 150 words, ASCII only).

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful | Reason |
| --- | --- | --- | --- | --- | --- |
| NEW | mpmath/calculus/odesolution.py | — | +422 | 373 | `ODEEvent` and the solution object: two-sided segment cache, event scan, resets, switches, analysis methods |
| MODIFY | mpmath/calculus/odes.py | 285 | +99 | 39 | signed Taylor step, tail-based radius, `odefun` wiring, `odebvp` |
| MODIFY | mpmath/\_\_init\_\_.py | 214 | +3 | 2 | export `ODEEvent` and `odebvp` |

TOTAL: 528 raw / 418 human-effective across 1 new + 2 modified files
(`python3 .claude/hooks/effective_loc_check.py solution.patch`). Clears the 400
platform auto-block; below the 430 hook target, which is recorded in `feedback.md`.

## 8. Solution outline — helpers

- `ode_taylor(..., direction)` — the existing stepper, now signed; the radius is
  taken over the whole tail of each series so a vanishing top coefficient cannot
  make a step arbitrarily long.
- `ODESolution._step(d)` — extend one direction by one segment, locate the first
  wanted crossing, truncate the segment there, record, apply `switch`/`reset`.
- `ODESolution._crossing(ev, d, ser, xa, width)` — scan a step at the resolution of
  the series, skip a zero at the entry, locate the root with `findroot`.
- `ODESolution._wanted(ev, d, before)` — direction filter expressed against increasing `x`.
- `ODESolution._series(x, upward)` — branch selection and segment lookup, extending on demand.
- `ODESolution._trim(...)` / `_defect(...)` — shorten a step until the series satisfies the ODE.
- `ODESolution._derivative(s, n)` — polynomial derivative used by `diff` and `_defect`.
- `ODESolution._grid(a, b)` / `_scan(f, a, b)` — sampled search shared by `crossings`, `roots`, `extrema`.
- `ODESolution._piece(a, b)` — exact polynomial antiderivative over one segment.
- `odebvp.shoot` / `endpoint` — residual of the shooting problem, at `x1` or at a stopping event.

Fixpoint loops: `_trim` halves a step until the defect is met; `_scan`/`_series`
extend until the requested range is covered.

## 9. Test file outline

Path: `mpmath/tests/test_ode_da6e5c.py` (unpredictable suffix, no banned markers).

Block 1 imports · Block 2 builders (`exponential`, `circular`, `bouncing`,
`oscillator`, `projectile`, closed-form `bounce_times`) · Block 3 assertion helpers
(`assert_close`, `assert_vector` with a digit budget) · Block 4 tests grouped by
bucket: backward integration (8), event basics (10), direction (6), terminal (7),
reset (7), switch (7), maxevents (5), diff (8), taylor (6), integral (11),
crossings/roots/extrema/optimum (20), terminal-stop rule for the other methods (1),
validation (4), odebvp (12).

Total 122 tests, all deterministic, no parametrize, no network, no timing.

Oracles: closed-form solutions evaluated by mpmath itself (`exp`, `sin`, `cos`,
`log`, `lambertw`, the geometric bounce series), compared at 15-25 digits.

## 10. Forced argument shapes

- The event function, `reset` and `switch` all receive the same argument form as
  `F` (scalar for a scalar problem, list otherwise); pinned in the description
  because a statically shaped test cannot discover it.
- `sol.taylor` returns a list per component but a single list in scalar mode.
- `terminal` accepts a bool or a positive whole number; `mpf('1.5')` must be rejected.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt sentence | Test |
| --- | --- | --- | --- | --- |
| 1 | Value at a crossing must come from the pre-event branch | The natural cache lookup takes the segment starting at the boundary, which is the post-reset one | "it is also what `sol(x)` and `sol.diff(x)` return exactly at that point" | `test_value_at_a_reset_point_is_the_state_before_the_reset` |
| 2 | A zero at the point a step starts from is not a crossing, but a later crossing in the same step is | A reset that lands exactly on the event surface either retriggers forever or hides the next crossing | "A zero at the point a step starts from ... is not a crossing" | `test_reset_that_lands_on_the_surface_does_not_retrigger`, `test_bounce_times_follow_the_closed_form` |
| 3 | Direction is measured against increasing `x` even when integrating backward | The obvious implementation compares the two ends in integration order | "That sense always refers to increasing `x`" | `test_direction_refers_to_increasing_x_when_going_backward` |
| 4 | Every crossing in a range must be found, not one per step | One bracket per step is the obvious scan and silently loses closely spaced roots | "returns every `x` in the closed range" | `test_crossings_find_closely_spaced_roots` |
| 5 | A functional integral must be split at the segments | A single quadrature over a range containing a reset integrates across a jump | "integrates `f(x, y(x))`" with the reset semantics stated | `test_integral_of_a_function_across_a_reset` |
| 6 | Counters are per direction | One shared counter is simpler and passes every single-sided test | "counted separately in each direction" | `test_terminal_counts_are_kept_per_direction`, `test_maxevents_is_counted_separately_in_each_direction` |

Traps 1, 2 and 6 are interdependent: fixing the cache lookup for trap 1 changes
which segment a restart writes into, and the restart is what trap 2 depends on.
Trap 3 only shows up once backward integration works, so it is invisible until the
first requirement is done.

## 12. Tier + category

- Tier: Olympus
- Sub-rank: Olympus-Good (three orthogonal surfaces, 122 tests, 414 effective LOC)
- Category: feature-request (new public type, new entry point, new keyword arguments)

## 13. Predicted pass rate

- Predicted: 10% - 25%.
- Reasoning: six interdependent traps, exact-oracle assertions at 15-25 digits that
  reject any approximate event location, and a long-horizon surface (three files,
  119 tests). The Taylor machinery is bespoke to this repo, so the solver cannot be
  pattern-matched from training data on `scipy.integrate.solve_ivp`, whose event API
  it superficially resembles but whose semantics differ here (per-direction counters,
  pre-reset records, closed ranges).
- Solvability: the reference implementation is 414 effective LOC of ordinary Python
  and every requirement is stated, so at least one agent should pass.

## 14. Quality gate

- [x] Repo understanding: architecture, subsystems, entanglement zones, test framework, template test file
- [x] Existing PR/issue check: `gh pr list -R mpmath/mpmath --state all --search "odefun|event|backward|ode"` gives no hit; issues #71 (closed, asks for the precise solver that exists today) and #228 (open, an unrelated stall on a specific system) do not cover events or backward integration
- [x] Closest approved problems opened side by side (`pandapower-reliability-assessment`, `python-control-multirate`)
- [x] One interdependent kernel (the two-sided segment cache) driving call, diff, taylor, integral, crossings, extrema, events and the BVP
- [x] External oracle: closed-form solutions at 15-25 digits, checked against mpmath's own `exp`, `sin`, `cos`, `log`, `lambertw`
- [x] >= 3 interdependent and misdirecting traps, including "the obvious code is wrong" (segment lookup at a boundary)
- [x] Every new signature pinned in `meta.md`
- [x] Not a famous portable spec: the semantics differ from `solve_ivp` on purpose and the solver is bespoke
- [x] Description: 696 words, plain prose, ASCII, no headers, backticks only on new API names
- [x] Test coverage: every described behavior, every public name, every branch, edge cases
- [x] Flakiness: no timing, no randomness, no network, no ordering assumptions
- [x] Repo quota: first submission against mpmath

Why this is not a duplicate: the closest approved work is `python-control-multirate`
(sampling-rate composition in a control library) and `pandapower-reliability-assessment`
(a new analysis layer over a network model). Both add an analysis layer to a numeric
library, but neither touches ODE integration, event location or arbitrary-precision
series machinery, and no approved problem uses mpmath.

Predicted iteration cycles: 2
