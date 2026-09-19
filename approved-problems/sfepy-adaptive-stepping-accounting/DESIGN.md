# DESIGN.md — sfepy-adaptive-stepping-accounting

Base commit `e652fdc6114155cfe14f6dd6f60fa2d6bbaa9b86` (2026-08-26). Repo sfepy/sfepy, BSD-3-Clause,
838 stars, 240 commits/12mo. Our second sfepy submission (`sfepy-modal-analysis`, 453 eff, is the
first); quota 2 of 6.

---

## 0. Why this pick, after two died today

`lyon` shape-recognition was rejected at the Phase-3 guard (a post-pass over the public event stream
is `failure-patterns.md § 5`'s explicit anti-target, and its traps were independent rather than
interdependent). `acoular` moving-sources-in-flow was rejected at Stage 3b (absorbed:
`UniformFlowEnvironment.apparent_r` already solves the convected quadratic in closed form for an
arbitrary source position, so the whole capability is a 3-5 line edit at three sites, ~40 eff).

This pick survives both gates for reasons verified in the source, not estimated:

- **Not absorbed.** There is no floor/exhaustion policy anywhere in `sfepy/solvers/`, and
  `TimeStepController` (`solvers/solvers.py`) has no `get_state`/`set_state` at all, unlike
  `TimeStepper` which does. `TimesSequenceTSC` holds a bare `iter()` (`ts_controllers.py:29`) that
  is not serialisable in any form — turning it into a resumable position is new logic, not a field.
- **Not a post-pass.** One kernel (the stepping loop plus the controller protocol) feeds five
  surfaces: the first-order `ts.adaptive` path, the elastodynamics path, the restart path, the
  solve status and the user-replaceable `adapt_fun` contract. A local fix to one regresses another
  (§ 11).
- **Cold.** `ts_controllers.py:128` contains a live `NameError` (`aux = unpack(vec0)` inside a method
  whose parameter is `vec`), reachable via `guess_dt0=True`. Nobody has run that path.

---

## 1. Title

**Add step accounting and declared termination to adaptive time stepping**

Verb `Add`, 8 words, names the subsystem (adaptive time stepping).

## 2. Shape classification

- **Shape:** O-Composite-extend (`SHAPES.md § Pattern 12`) — extend an existing multi-family
  mechanism across the packages that already consume it, rather than adding an isolated feature.
  Secondary read: **S-F analysis/accounting layer** (`CAPABILITY-SHAPES.md`) — surface what the
  engine already computes and discards — crossed with **S-H reconstruction after teardown** for the
  restart half.
- **Pass-rate target:** ≤40% ceiling, design to the 10-20% edge.
- **Best agent:** Orion (long-horizon; the decisive solver on every multi-surface pick measured).
- **Dominant verdict predicted:** MISSED_REQUIREMENT, with a REGRESSION cluster on the
  constant-matrix interaction.
- **Span:** 5 files / 2 packages (`sfepy/solvers/`, `sfepy/discrete/`).

## 3. Public API surface

Everything tests assert, named explicitly. No "same as X".

- `StepRecord` — a `Struct` with fields `step`, `time`, `dt`, `result`, `emax`, `condition`,
  `n_iter`. One per ATTEMPT at a time step.
- `status.step_log` — list of `StepRecord`, attempt order, rejections included.
- `status.n_rejected` — count of records whose `result` is `'reject'`.
- `status.termination` — one of `'completed'`, `'step_floor'`, `'max_rejections'`.
- `TimeStepController.get_state()` -> dict; `TimeStepController.set_state(**state)` — new base
  protocol, default empty.
- `TimesSequenceTSC.get_state/set_state` — carries the position in the times sequence.
- `ElastodynamicsPIDTSC.get_state/set_state` — carries `emax0`, `emax00`.
- `ElastodynamicsLinearTSC.get_state/set_state` — carries `count`.
- `max_rejections` — new `_parameters` entry on `ts.adaptive` and on `ElastodynamicsBaseTS`
  (default 10).
- `VariableTimeStepper.set_final_time_step()` — shortens the pending step so the next advance lands
  exactly on `t1`; returns the size used.
- `Problem.save_restart` / `Problem.load_restart` — extended to carry solver adaptation state.

## 4. Canonical output form

- **`step_log` order:** attempt order, oldest first. A rejected attempt is recorded BEFORE the
  retry that replaces it.
- **One record per attempt**, not per accepted step. A step rejected twice then accepted contributes
  three records with the same `step` value.
- **`emax`:** the controller's error estimate, or `None` for controllers that compute none
  (`FixedTSC`, and the `ts.adaptive` path where the decision comes from the Newton exit).
- **`condition` / `n_iter`:** copied from the nonlinear solver status of that attempt.
- **`n_rejected`:** total over the whole run, not per step.
- **Termination precedence:** `'max_rejections'` is decided before `'step_floor'` when both would
  fire on the same attempt.
- **Rejection counting:** consecutive, at one step, reset at every new step. Exactly
  `max_rejections` rejections followed by an acceptance is a continuing run.
- **On either stopping reason:** the run does not advance, the final attempt is recorded with
  `result='reject'`, and the last accepted state is returned.
- **Empty case:** a run that completes with no rejection has `n_rejected == 0`, one record per step,
  and `termination == 'completed'`.
- **Restart:** a run resumed from a restart file produces the same subsequent `dt` sequence as an
  uninterrupted one.

## 5. Blind-spot pre-empts (`DESCRIPTION.md` sentence bank)

| Blind spot | Sentence used in § 6 |
|---|---|
| Result-list ordering | "in the order they were attempted" |
| Format-noun extent (L24) | "one `StepRecord` per attempt at a step, rejected attempts included" |
| Tolerance arming vs firing (L25) | "a step rejected exactly `max_rejections` times and then accepted leaves the run going" |
| Unstated inverse | "A run that stops for either reason stops before advancing" |
| Falsy-on-invalid | "the controller's `emax` where there is one and `None` otherwise" |
| Baseline preservation | "`adapt_fun` keeps its documented contract of returning a bool" |

Codebase-inferable requirements: **1** (that `ts.adaptive` decides accept/reject from the Newton
exit condition rather than an error estimate — visible in `adapt_time_step`).

## 6. Description draft (meta.md body, ~370 words)

> Add a record of what the adaptive time steppers actually did to `ts.adaptive` and to the
> elastodynamics solvers. Today both discard it: a step size that shrinks past its floor makes the
> run keep going from a state the nonlinear solver never converged, the elastodynamics loop retries
> a rejected step forever, the controller error is printed and thrown away, the trace ends past the
> end time, and a run resumed from a restart file picks different step sizes than one that was never
> interrupted.
>
> `Problem.solve` and the time stepping solvers report `step_log`, `n_rejected` and `termination` on
> the status they are given. The log holds one `StepRecord` per attempt at a step, rejected attempts
> included, in the order they were attempted, each carrying the step index, the time the attempt
> aimed at, the step size it used, its `result` of `'accept'` or `'reject'`, the controller's `emax`
> where there is one and `None` otherwise, and the nonlinear solver's `condition` and `n_iter`. A
> step rejected twice and then accepted leaves three records. `n_rejected` counts the rejected ones
> over the whole run.
>
> `termination` is `'completed'` when the run reaches the end time, `'step_floor'` when the step size
> shrinks past the reduction floor, and `'max_rejections'` when one step is rejected more times in a
> row than `max_rejections` allows. That count is of consecutive rejections at one step and starts
> again at each new step, so a step rejected exactly `max_rejections` times and then accepted leaves
> the run going. Where both would end the run on the same attempt, `'max_rejections'` is the reason
> given. A run that stops for either reason stops before advancing, records that last attempt as a
> rejection, and returns the last state the solver accepted.
>
> The last step is shortened so the run ends exactly at the end time rather than past it, and
> shortening it keeps whatever the solvers cache against a step size in step with the size actually
> used.
>
> Every time step controller carries its own adaptation state, and `save_restart` and `load_restart`
> carry it across, so a resumed run produces the same step sizes as an uninterrupted one.
>
> `adapt_fun` keeps its documented contract of returning a bool.

No `##` headers, no formulaic labels, no `Box<>`, plain prose, ASCII only.

## 7. File footprint (sketched against real source)

| Action | Path | Current LOC | Raw delta | Meaningful | Reason |
|---|---|---|---|---|---|
| MODIFY | `sfepy/solvers/solvers.py` | 1010 | +40 | ~28 | `TimeStepController.get_state/set_state` base protocol; `StepRecord` |
| MODIFY | `sfepy/solvers/ts_controllers.py` | 300 | +85 | ~60 | 3 per-flavour state overrides; `iter()` -> resumable index; `vec0` NameError fix |
| MODIFY | `sfepy/solvers/ts.py` | 232 | +55 | ~40 | final-step clamp, `times` bookkeeping under clamp, state round-trip |
| MODIFY | `sfepy/solvers/ts_solvers.py` | 1333 | +170 | ~120 | ledger in BOTH families, termination policy, rejection cap, clamp placed against the cache gate, `adapt_time_step` bool-compatible richer signal |
| MODIFY | `sfepy/discrete/problem.py` | 2500+ | +75 | ~55 | restart of controller + `adt` state, status surface on `solve` |

**TOTAL ≈ +425 raw / ~300 meaningful across 5 modified files, 2 packages.** Floor is 200; design
buffer target 250-300. Clears with margin. Calibration: our approved `sfepy-modal-analysis` measured
**453 human-effective across 3 files**, so ~300 across 5 is a conservative, non-padded sketch for a
smaller-scope capability.

⚠️ The probe warned this lands at ~220 if the ledger/status surface is written thinly. The five
components above are each genuinely absent; do not trim the controller-state protocol (§ 8.4), which
is the largest genuinely-new piece.

## 8. Solution outline — pure-function helpers

1. `make_step_record(ts, dt, result, tsc_status, nls_status) -> StepRecord` — one per attempt.
   Maps § 6 sentence 2.
2. `classify_termination(reason_flags) -> str` — resolves the `'max_rejections'`-before-
   `'step_floor'` precedence. Maps § 6 sentence 3.
3. `TimeStepController.get_state/set_state` — base returns `{}`; three overrides. Maps § 6
   sentence 5.
4. `VariableTimeStepper.set_final_time_step()` — returns the shortened `dt` and flags whether it
   changed, so the caller can honour the cache rule. Maps § 6 sentence 4.
5. `RejectionCounter` (consecutive-at-one-step, reset on advance) — maps § 6 sentence 3.

No fixpoint loop is required; the two existing `while 1` loops are the kernel and stay in place.

## 9. Test file outline

Path: `sfepy/tests/test_ts_accounting_<hex6>.py` (hex from `openssl rand -hex 3`; no `shipd` /
`datacurve` substrings).

**Block 1 — imports.** `numpy`, `pytest`, `sfepy.base.testing as tst`, `Problem`, `ProblemConf`.

**Block 2 — builder helpers (10-30 one-liners).** A `define()` dict per stepping family, following
`sfepy/tests/test_ed_solvers.py:11-228` exactly (declarative dict returning `locals()`, `gen_block_mesh`
via `UserMeshIO`). Helpers to force rejections (tolerances tightened so `emax > 1`), to force the
floor (`dt_red_max` raised), and to drive a restart round trip.

**Block 3 — assertion helpers.** `records_for_step(log, step)`, `assert_dt_sequence_equal(a, b)`,
substring-free value asserts only.

**Block 4 — tests by requirement bucket.**

| Bucket | Count | Notes |
|---|---|---|
| ledger content and order | ~12 | one per attempt; rejected-before-retry ordering; `emax` `None` on the first-order path |
| termination values | ~10 | completed / step_floor / max_rejections, both families |
| rejection counting | ~8 | **includes the L25 N-1 fixture**: exactly `max_rejections` then accept, assert the run continued and `termination == 'completed'` |
| final-time clamp | ~8 | ends exactly at `t1`; the cached-matrix consequence asserted as a VALUE |
| controller state / restart | ~12 | per-flavour: sequence position, PID history, linear counter; resumed dt sequence identical |
| cross-product cells (§ 11b) | ~6 | off-diagonal only |
| edge cases | ~8 | zero rejections; single step; `FixedTSC` unaffected; `adapt_fun` bool contract preserved |

Target ~60-64 tests. Scenario-encoded snake_case names.

**5-axis coverage:** every ATOM in § 6 (not every sentence), every § 3 API name, every solution
branch, edge cases (empty log / single step / no rejection / floor at the last step), and the stated
inverse (a continuing run after exactly `max_rejections`).

## 10. Forced signatures

- `set_state(**state)` must accept keyword expansion from an HDF5 group read (heterogeneous types:
  int, float, and an int index for the sequence controller). Sketch the restart helper before the
  spec.
- `adapt_time_step`'s bool return is a documented public contract (`ts_solvers.py:312-321`); the
  richer signal must ride alongside it, not replace it. Stated in § 6.
- `StepRecord` is a `Struct`, matching the repo's own status objects.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal | Axis measured | Interdependent with | Why agents hit it | Pre-empt sentence (§ 6) | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | The two `is_break=True` exits mean opposite things — accepted, and gave-up-at-the-floor (`ts_solvers.py:288-293`); the caller then returns the non-converged vector (`:362-376`) | **F-14** | S6 | terminal-state semantics | #5 (both set `termination`) | The derived signal `is_break` is the obvious hook; distinguishing requires reading `status.condition` at the call site | "'step_floor' when the step size shrinks past the reduction floor ... records that last attempt as a rejection" | `floor_exhaustion_is_declared_not_completed` |
| 2 | The final-step clamp changes `dt` at the bottom of the outer loop, where `clear_lin_solver` is NOT called (`:737-740` is inside the inner loop); the last step integrates with a stale `constant_matrices` | **F-6** | **S3** | baseline preservation through a shared chokepoint | #4 (both ride `set_time_step`) | The natural place to clamp is the bottom of the loop; the cache gate is 15 lines up and conditioned on `has_time_derivatives` | "shortening it keeps whatever the solvers cache against a step size in step with the size actually used" | `clamped_final_step_matches_an_unclamped_reference_value` |
| 3 | `set_time_step(update_time=True)` REWRITES `times[step]` (`ts.py:195`), so a ledger keyed on `ts.times` collapses N attempts into one; keying on step index alone breaks `set_state`'s `assert_(len(times) == step+1)` (`ts.py:159`) | **F-13** | S2 | record granularity | #4 (restart assertion) | "Step" reads as one accepted advance in English; the contract means one attempt (L24) | "one `StepRecord` per attempt at a step, rejected attempts included ... A step rejected twice and then accepted leaves three records" | `a_twice_rejected_step_leaves_three_records` |
| 4 | Controller state is per-flavour with different reset semantics; `TimesSequenceTSC` holds a bare `iter()` that cannot be serialised at all | **F-3** | **S-I / A3** | per-flavour state protocol | #2, #3 (restart round trip) | Agents save the obvious floats and either skip the sequence controller or save its current value instead of its position | "Every time step controller carries its own adaptation state" (Rule 7 — no enumeration) | `resumed_run_reproduces_the_dt_sequence_for_every_controller` |
| 5 | Rejection cap arming vs firing: the counter is consecutive AT ONE STEP and resets per step | **F-15** | A8 | tolerance boundary | #1 (termination precedence) | Agents implement stop-at-N and/or a global counter | "consecutive rejections at one step and starts again at each new step, so a step rejected exactly `max_rejections` times and then accepted leaves the run going" | `exactly_max_rejections_then_accept_continues_the_run` (**the N-1 fixture, L25**) |

Every trap is CONTRACT-STATED / FIX-HIDDEN: each § 6 sentence states the observable and none names
the mechanism (`is_break`, `clear_lin_solver`, `times[step]`, `iter()`, the counter's location).

Axes are distinct: terminal-state semantics · cache preservation · record granularity · per-flavour
state · tolerance boundary. Interdependence confirmed in source (§ 0 and the table above), not
assumed.

## 11b. Capability cross-product matrix (F-10)

Axis 1 = stepping family. Axis 2 = how the run ends. Axis 3 = fresh vs restarted.

| | completed | step_floor | max_rejections |
|---|---|---|---|
| **`ts.adaptive`** | `first_order_run_completes_with_one_record_per_step` | `first_order_floor_exhaustion_declares_step_floor` | ← **off-diagonal**: the first-order path has no controller, so the cap must be counted from Newton non-convergence: `first_order_rejection_cap_stops_the_run` |
| **elastodynamics `tsc.*`** | `ed_run_completes_and_ends_exactly_at_t1` | ← **off-diagonal**: ED reaches the floor through `fmin`, not `red_max`: `ed_floor_exhaustion_declares_step_floor` | `ed_rejection_cap_stops_before_advancing` |

Axis-3 off-diagonals (the cells nobody builds):
- `restart_then_rejection_cap_counts_only_post_restart_rejections` — a resumed run must not inherit
  the pre-restart rejection count.
- `clamp_and_floor_on_the_same_final_step` — the last step is both clamped and floor-exhausted;
  predicted failure mode is OVER-firing, reporting `'completed'` because the clamp made `nt >= 1`.

**Scope audit.** `n_rejected` is whole-run; the cap counter is per-step. Both stated in § 6.
**Format-noun audit (L24).** "step" — extent stated ("per attempt at a step ... leaves three
records"). "record" — one per attempt. "run" — whole solve.
**Tolerance-fixture audit (L25).** N-1 fixture present and named above; the N fixture (which cannot
discriminate) is deliberately secondary.
**Example audit (L21).** § 6 carries exactly one worked instance ("a step rejected twice and then
accepted leaves three records"), attached to the granularity rule where the extent is the whole
point. No instance list anywhere else.

## 12. Tier + category

- **Tier:** Olympus (one tier).
- **Category:** `feature-request` — the title verb is `Add`, and the dominant act is adding a
  reporting surface, a termination concept and a controller-state protocol that do not exist.
- Sub-rank target: Good.

## 13. Predicted pass rate

**10-25%.** Reasoning: five traps on five distinct axes, three of them confirmed interdependent in
source; the lead (F-14) sits behind a derived signal whose two meanings are indistinguishable
without reading a second field; the F-15 N-1 fixture is the measured 4/10 shape; the F-3 per-flavour
protocol has a member that is not serialisable at all. Against that, the capability is
*describable* — an agent that reads § 6 carefully and works methodically can get most of it, which
is what keeps it off 0%. Sanity: ≤40% ceiling, and the design deliberately targets the low edge.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (architecture, 5 subsystems, 3 entanglement zones, pytest +
      declarative `define()` dicts, template `sfepy/tests/test_ed_solvers.py`)
- [x] Phase 2 existing-PR / publicly-solved check — **CLEAR** (§ 2b below)
- [x] Closest approved opened as scaffolding (`approved-problems/sfepy-modal-analysis`)
- [x] Title verb-led, 8 words, names the subsystem
- [x] Shape declared with citation
- [x] Public API surface lists every asserted name
- [x] Canonical output form spelled out (order, granularity, precedence, empty case)
- [x] 1 codebase-inferable requirement (≤1)
- [x] Description ~370 words, plain prose, ASCII, no headers
- [x] File footprint sketched against real source with line citations
- [x] ~300 meaningful LOC ≥ 200 floor, ≥250 buffer, 5 files ≥ 2
- [x] 1+ pure-function helper per described behaviour (§ 8)
- [x] Test outline 4-block, scenario-encoded names, ~60 tests
- [x] 5-axis coverage planned
- [x] Forced signatures documented (§ 10)
- [x] 5 named traps, each with pre-empt sentence + catching test
- [x] Every trap names an F-id
- [x] Traps on DIFFERENT axes; 3 pairs interdependent
- [x] § 11b cross-product filled, every off-diagonal has a test
- [x] Format-noun extents stated (L24)
- [x] Tolerance rule has its N-1 fixture (L25)
- [x] Predicted pass ≤40%
- [x] Category matches the verb (Add -> feature-request)
- [x] Not pattern-followable (no sibling accounting layer exists in `sfepy/solvers/`)
- [ ] Flakiness 3x — owed after implementation
- [x] Docker build verified — image builds; `test_ed_solvers.py` = 3 passed in 38s inside the container, `--network none --user 1000:1000`

## F-12 audit (decided once, here)

`ts.py`, `ts_controllers.py` and `ts_solvers.py` carry **no** `#[cfg(test)]`-equivalent inline test
module (Python; tests live in `sfepy/tests/`). **No F-12 axis exists.** Base mode runs the full
`sfepy/tests/` suite unchanged.

⚠️ **L31 watch item.** `sfepy/tests/test_ed_solvers.py:346` computes `ienergy = e0 * t1s[ii]` where
`t1s` collects `problem.solver.ts.time` — i.e. the existing test already COMPENSATES for the t1
overshoot by integrating to the actual end time. Making the run land exactly on `t1` changes that
value. **Verify before writing the solution** that the existing assertion still passes (it should:
`t1s` simply becomes `t1`), and if it does not, the contract must change rather than the repo test —
editing a repo test is scored as cheating (L31).

## Why this is not a duplicate

Closest own work: `approved-problems/sfepy-modal-analysis` (new `sfepy.discrete.modal`, eigen solve,
Rayleigh damping) touches `discrete/__init__.py`, `discrete/modal.py`, `discrete/problem.py` — a
different subsystem class (eigenanalysis, not time integration) with one file of overlap
(`problem.py`) at a different surface. Nothing in `approved-problems/`, `problems/` or `rejected/`
is an adaptive-stepping, restart or solver-accounting capability in any repo.

Nearest external shape: PETSc `TSAdapt` and SUNDIALS step-size controllers ship adaptive control,
but neither ships sfepy's controller protocol, its `adt` struct, its restart file or its
constant-matrix cache — and sfepy's PETSc integration is linear/nonlinear solvers only, not `TS`.
**Confirmed in Phase 2 — see § 2b.**

**Predicted iteration cycles: 2.**


---

## § 2b. Phase 2 result (run 2026-09-02) — CLEAR, with two cautions that rebalance the design

**Exclusivity.** Three open PRs in the whole repo (`#1296` one line in an example, `#1054`
hyperelastic terms, `#877` a test file). **None touches `sfepy/solvers/` or
`sfepy/discrete/problem.py`.**

**Gate 5 cold-not-live — strongly PASS, stronger than the hunt estimated.** Commits since 2024-09-01:
`ts.py` **0** (all-time last touch 2023-02-20), `ts_controllers.py` **0** (last touch 2023-03-21),
`solvers.py` **0**, `ts_solvers.py` **1** (an unrelated `csr_array` change). `problem.py` is warm but
only on other lanes; its one restart-adjacent commit (2024-11-07) is a file-retention bug, not state
content.

**Gate 8 philosophy — no blocker, mildly positive.** No statement anywhere that the silent accept at
the floor is intentional, and no "intentional" comment in the code. rc on #207: *"Now I plan to add
an adaptive time stepping solver, with both predefined or user supplied time step updating
function."* On #107 (log convergence): *"Done for the Newton solver. Is it needed for other
solvers?"* -> *"Yes, let's log also opt.fmin_sd, nls.oseen solvers."* The docs concede incompleteness
rather than claim completeness (`doc/users_guide.rst:82`: *"``--save-restart=-1`` is currently the
only supported mode."*).

**Publicly-solved — negative.** No issue comment carries a working snippet for step accounting,
controller-state restart or a `t1` clamp, and no comment links to a fork/branch/gist doing it.

**Not a port.** No "ported from"/"derived from" in the README or docs; the time-stepping layer is
original. `petsc4py` appears in exactly two places, `ls.py:676` (KSP) and `nls.py:820-826` (SNES).
Repo-wide grep for `PETSc.TS`, `TSAdapt`, `SUNDIALS`, `CVODE`, `solve_ivp` returns nothing — **sfepy
does not use PETSc TS at all**, so there is no wrapper to lean on and nothing to transliterate.

### Caution A — piece 1 is PARTLY ABSORBED by merged PR #1069

`#1069` "optionally report (nonlinear) solver status" (rc, merged 2024-01-30) already added a
`_TimingNLS` wrapper inside `_standard_ts_call` that **accumulates per-step nonlinear-solver status
onto the ts-solver status**, plus the `Problem.solve()` printing. So the plumbing that carries a
per-step record out to the caller exists; the ledger becomes another arm on that accumulator rather
than new machinery.

It does **not** implement accepted/rejected accounting, the controller error estimate, the
per-attempt exit condition, or anything in pieces 2-4. **Effect on this design:** size piece 1 down
(~40 -> ~30 effective) and do not lean on it for LOC. It stays in scope because the ATTEMPT
granularity (§ 11 trap 3) is exactly what the existing accumulator cannot express — it accumulates
per accepted step, and `times[step]` is rewritten under it.

### Caution B — pieces 2 and 3 are SPEC-KNOWABLE via PETSc TS; piece 4 is not

PETSc TS ships this exact feature set under named APIs: `TSSetMaxStepRejections` (the rejection cap),
`TSAdaptSetStepLimits` (the dt floor), `TSConvergedReason` including `TS_DIVERGED_STEP_REJECTED` (a
declared terminal reason), and `TSSetExactFinalTime(TSEXACTFINALTIME_MATCHSTEP)` (the `t1` clamp).
SUNDIALS mirrors it (`CVodeSetStopTime`, `CVodeSetMaxErrTestFails`, `CVodeSetMaxConvFails`) and SciPy
`solve_ivp` clamps to `t_bound`.

An agent that knows PETSc therefore gets the *design* of pieces 2 and 3 for free. That is good for
the defined-behaviour gate and a **difficulty headwind** (`TOO-EASY.md § spec-knowable predicate
domain`). It does not sink the pick, because none of the five traps live in the semantics — they all
live in sfepy's own wiring, which PETSc knowledge does not supply:

- Trap 1 needs the reader to notice sfepy's two `is_break=True` exits mean opposite things.
- Trap 2 needs sfepy's `constant_matrices` cache gate.
- Trap 3 needs sfepy's `times[step]` rewrite.
- Trap 4 has **no sibling equivalent at all** — PETSc's `TSTrajectory` is adjoint checkpointing, a
  different shape.
- Trap 5's rule is PETSc-known, but the N-1 boundary still discriminates implementations.

**Rebalance, per the Phase 2 recommendation:** load-bearing difficulty sits on **pieces 2 + 4**, which
are also the interdependent pair (the declared terminal reason must survive a restart, and the
controller state must reproduce the dt sequence). Piece 1 is supporting accounting; piece 3 is a
textbook clamp whose only difficulty is trap 2's cache interaction. Weight the test suite the same
way: the § 11b axis-3 off-diagonals (restart x termination) are the band-deciding cells.

### Docker (verified, not estimated)

Image builds from the `sfepy-modal-analysis` pattern with pinned versions
(`numpy==2.2.6 scipy==1.18.0 meshio==5.3.5 pyparsing==3.3.2 tables==3.11.1 sympy==1.14.0
matplotlib==3.11.1 scikit-build==0.19.1 cmake==4.4.2 ninja==1.11.1.1 Cython==3.2.9 pytest==9.0.3`,
then `pip install --no-build-isolation --no-deps -e .` and `python setup.py build_ext --inplace`).
Built clean; `python -m pytest sfepy/tests/test_ed_solvers.py` = **3 passed in 38.17s** inside the
container with `--network none --user 1000:1000`.

---

## § 15. AS-BUILT (2026-09-02) — what shipped, and where the design was wrong

### Final artifact

| | |
|---|---|
| Solution | **250 human-effective / 511 raw across 5 files, 2 packages** |
| Tests | **74**, in `sfepy/tests/test_ts_accounting_46ab28.py`, runs in **17s** |
| f2p | 74 pass with the solution, **74 fail on base, 0 pass on base** |
| Base suite | 221 tests, unchanged, all pass |
| Mutations | 14 written, **14 caught, 0 survivors** |
| meta.md | 495 words, ASCII, no headers |

### API as built (supersedes § 3 where it differs)

Added since the design: `dt_min` on BOTH families (the elastodynamics controllers have no reduction
floor of their own, so `ts.adaptive`'s `dt_red_max` needed an absolute counterpart);
`StepLog.truncate_from`; `StepLog.to_arrays`/`from_arrays` with a NaN for a missing error;
`Problem.get_stepping_state`/`set_stepping_state`. `ts.simple` also reports a log, which made the
surface uniform across all three stepping families.

### Where the design was WRONG, and what it cost

1. **The LOC sketch was 40% optimistic.** § 7 predicted ~300 meaningful; the first honest
   implementation measured **167**. Docstrings count zero, and `solvers.py` came in at 27 raw / 5
   effective. Recovered to 250 by adding genuinely absent content (the queryable + restartable
   `StepLog`, the fixed-stepper log, the symmetric floor, the resume truncation rule) rather than
   padding. **The Phase-2 probe predicted exactly this and I under-weighted it.**
2. **Trap 2 (clamp vs cached solver state) is REAL, and I nearly deleted it.** No fixture I owned
   could see it: my test problem uses the EXPLICIT velocity-Verlet solver with presolve off, where a
   stale factorization cannot change the answer. I probed four configurations, measured
   `maxdiff = 0.0` in all of them, cut the meta sentence and removed the code as dead. The next base
   run failed the repo's own `test_ed_solvers` (five ED solvers, `use_presolve: True`). Restored.
   **This is S3 working as designed — the discriminator is an EXISTING test, so it is invisible to a
   mutation harness scoped to new tests.** Recorded as `failure-patterns.md` L33.
3. **Two tests passed on base and had to go.** `VariableTimeStepper` recomputes `dt` in its
   constructor as `dtime / (n_step0 - 1)`, which always divides the interval exactly, so a
   FIXED-controller run can never overshoot. Only an adaptive run whose `dt` changes mid-flight
   reaches the clamp. The clamp's f2p coverage therefore has to come from adaptive runs.
4. **Seven tests pinned state-dictionary KEY NAMES** (`emax0`, `emax00`, `count`, `index`) that the
   description never states, and stating them would have violated Rule 7. Rewritten as behavioural
   round-trips that name no keys: capture the state, perturb it, restore it, assert equality; and for
   the restart, assert the reloaded controller equals the saved one. Fairer AND still trap-preserving.
5. **A scripted test controller was tried and abandoned.** It gave exact control of the rejection
   count but halved `dt` every step without restoring it, so runs never terminated. The cap boundary
   is instead built on measured deterministic counts (worst step = 4 rejections then accept, 6
   rejections total over 3 steps), which gives the L25 pair directly: `max_rejections=4` completes
   and proves the per-step reset, `max_rejections=3` stops with `'max_rejections'`.

### Trap matrix as built

| # | Trap | Caught by | Mode |
|---|---|---|---|
| 1 | Two `is_break=True` exits mean opposite things (F-14) | `test_the_step_floor_stops_the_run`, `test_a_first_order_step_floor_stops_the_run`, M10/M12 | new |
| 2 | Clamp vs cached solver state (F-6 / **S3**) | **the repo's own `test_ed_solvers`** | **base** |
| 3 | `times[step]` rewritten under a per-attempt ledger (F-13 / L24) | `test_a_twice_rejected_step_leaves_three_records` family, M4/M8 | new |
| 4 | Per-flavour controller state, one member not serialisable at all (F-3 / S-I) | the round-trip and restart tests, M7/M9/M14/M15 | new |
| 5 | Rejection cap arming vs firing, per-step reset (F-15 / L25) | `test_exactly_max_rejections_then_accept_continues_the_run` + `test_one_rejection_fewer_than_needed_stops_the_run`, M3 | new |

Trap 2 living in base mode is a feature, not a gap: it is the only one whose failure surfaces in a
pre-existing test that says nothing about the feature.
