# DESIGN — amaranth-instance-models

## 1. Title

Meta title: "Let the simulator give behavior to instances of external modules".

## 2. Repo + gates

- Repo: `amaranth-lang/amaranth` (BSD-2-Clause, 2056 stars, Python, hardware description language
  and toolchain, 28k LOC in `amaranth/`). Last commit on the default branch 2026-07-16.
- BASE_COMMIT: `fe524a11936222b2dd08751c68c66ef4b6d0bd22`.
- Gate 1 BEHAVIORAL-F2P-GAP: PASS, reproduced on base. A design containing
  `Instance("MY_PRIM", i_A=..., o_Y=...)` simulates without error and every output port of that
  instance silently stays at 0 forever; there is no way to attach behavior to it. Probe on base
  printed `o = 0` after setting the input.
- Gate 2 SATURATION: PASS. No spec and no reference implementation to port. cocotb and Verilator
  attack the same problem from a completely different architecture (foreign-language cosimulation);
  nothing defines what this should look like inside Amaranth's own simulator.
- Gate 3 UNIFORM-WRAP: PASS. Four non-collapsing decisions (see § 5): the process-vs-testbench
  scheduling class, the per-instance binding and its precedence rules, driving through the design's
  settling loop, and keeping unmodeled instances byte-identical to today.
- Gate 4 LOC-CEILING: target >= 450 human-effective; the feature multiplies over
  {bind by type, bind by path} x {combinational, clocked, chained, clock-driving models} x
  {read ports, drive ports, reject foreign ports} plus discovery, precedence and reset.
- Gate 5 COLD-NOT-LIVE: PASS. `amaranth/sim/` has 5 commits since 2025-01-01, all minor
  (async-generator cleanup, `Period` plumbing). No maintainer workstream here.
- Gate 6 REPRODUCE-ON-BASE: done (probe above, run through the public `Simulator` API).
- Gate 7 DEDUP: no amaranth simulator pick and no "attach behavior to a black box" pick in
  `problems/`, `rejected/`, `Aprroved/`, `Olympus/approved-problems/`. Our one prior amaranth
  submission is `amaranth-stream-width-converter`, which touches `amaranth/lib/stream.py` only and
  shares no file with this one.
- Gate 7b EXCLUSIVITY: canonical org resolved (`amaranth-lang/amaranth`, no redirect). PR search
  across all states for `Instance simulation`, `simulation model`, `black box simulation`: no PR
  touches this. No RFC in `amaranth-lang/rfcs` covers it.
- Gate 8 DEFINED-BEHAVIOR: PASS and maintainer-desired. Issue
  [#392](https://github.com/amaranth-lang/amaranth/issues/392) "Simulations with Instances" is OPEN
  since 2020-05-28; whitequark: "Yep, this is planned with the next round of simulator
  improvements... but I'm not sure what the API would look like." Planned, unclaimed for six years,
  and explicitly not designed, so the semantics below are invented here and pinned by the
  description.
- Gate 9 NO-FLAKY-REPO: the suite is pure Python with no timing, network or ordering dependence;
  `pytest tests/` is deterministic. Re-run 3x before submit.
- Gate 10 REPO-QUOTA: 1 prior submission for this repo (5 left), 2056 stars, niche EDA domain.
- Env Quality: pure Python, dependencies are `pyvcd` and `jschon` only.

## 3. Shape

O-Composite-add: a new capability added to an existing subsystem (the simulator) that has to be
threaded through the public API, the engine, the scheduling loop and the value-access contexts. The
whole feature is observable through `Simulator.add_instance_model` plus ordinary simulation, so the
hidden tests never need to touch an internal symbol.

## 4. Behaviors (the contract; each maps to tests)

R1. `Simulator.add_instance_model(constructor, *, type=None, path=None)` attaches a *model* to
    instances of external modules. Exactly one of `type` and `path` must be given, otherwise
    `ValueError`. `type` matches every instance with that type name; `path` matches the single
    instance at that dotted hierarchical path. If nothing matches, `NameError`.
R2. The constructor is an `async` function taking `(ctx, instance)`. It is called once per matching
    instance, each with its own handle, when the model is added and again on `Simulator.reset()`.
R3. The handle exposes `type`, `path`, `parameters`, `attributes`, `inputs` and `outputs`. `inputs`
    and `outputs` map port names (without the `i_`/`o_` prefix) to the values connected to them in
    the design; `io_` ports are not exposed.
R4. A model runs as a part of the design, like a process: what it drives is applied inside the same
    settling loop as the rest of the design, so a model's output is visible to the design, and to
    other models, in the same delta cycle.
R5. `ctx.get` is available in a model (it is not in an ordinary process) and returns the value an
    expression has in the current delta cycle. `ctx.set` may only assign to the instance's own
    output ports; assigning to anything else raises `DriverConflict`.
R6. An instance with no model keeps behaving exactly as before: its outputs hold 0.
R7. A `path` binding takes precedence over a `type` binding for the same instance. Two `type`
    bindings for one type, or two `path` bindings for one path, raise `DriverConflict`.
R8. Models are background: `run()` does not wait for them.
R9. Adding a model to a running simulation raises `RuntimeError`.
R10. A model may drive a signal that is used as a clock, and domains clocked by it advance.

## 5. Trap matrix (arsenal mapping)

| # | Trap | Class | Mechanism | Misdirection |
|---|------|-------|-----------|--------------|
| T1 | Models must be design processes, not testbenches | S1/S3 | the model needs `ctx.get`, and the only existing context that has `get` is `TestbenchContext`; reusing it puts the model in `_testbenches`, so it runs only after the design has converged and steps the design on every `set` | a wrong scheduling class shows up as values that are one delta or one clock edge stale in a chained or clocked test, never as an error |
| T2 | Chained models must converge in one settle | S2 composition | model A drives comb logic that feeds model B; only wiring both into the delta loop with proper wakeups converges | B reads A's previous value |
| T3 | Everything the simulator already does must keep working | S4 machinery-riding | model-driven signals must trace to VCD, survive `reset()`, work at any hierarchy depth, with several instances of one type, and when the driven signal is a clock | failures land in unrelated features, not in the model API |
| T4 | Ports are arbitrary values | A4 | an output port may be connected to a slice or a concatenation, not a bare signal; driving it must write through | wrong bits change |
| T5 | Binding precedence and conflicts | S2 | path beats type; duplicates of the same kind conflict; a no-match binding is an error | natural code is "first match wins" and silently binds twice |
| T6 | Unmodeled instances unchanged | S3 baseline | existing tests simulate designs containing instances | base tests fail, not new ones |
| T7 | Replace means suppress, not override | S3 baseline / S4 | a replaced submodule's own logic must stop running: its internal sync state must not advance and a memory inside it must not update. The natural shortcut, letting the model write over the outputs while the RTL keeps running, produces the right output value and the wrong state | the model's output looks correct; only the submodule's internals or a memory read reveal the error |
| T8 | Models are simulation-only | S3 baseline through a shared chokepoint | attaching a model must not change what `rtlil.convert` emits. An implementation that replaces a submodule by rewriting the fragment tree, the obvious approach, changes the design itself | conversion output differs, which no test of the model API would point at |
| T9 | Settling with feedback | S2 composition | a model whose output returns to its own input through combinational logic, and two models in one loop, must both reach a fixpoint. Testbench-scheduled models, or models evaluated once per time step, hang or read stale values | the failure is a wrong settled value or a hang, not an API error |

CONTRACT-STATED / FIX-HIDDEN check: R1-R10 state the observable contract without naming
`_processes`, `_testbenches`, `AsyncProcess`, `ProcessContext`, `step_design` or where the binding
is resolved. Stating "visible in the same delta cycle" does not reveal that the only existing
context with `get` is the wrong scheduling class.

## 6. Files (planned footprint)

| File | Change |
|------|--------|
| `amaranth/sim/_instance.py` | new: instance discovery over the prepared design, the handle exposed to models, binding records and precedence |
| `amaranth/sim/_async.py` | new context for models: `get` allowed, `set` restricted to the instance's outputs |
| `amaranth/sim/core.py` | `Simulator.add_instance_model` with validation and docs |
| `amaranth/sim/pysim.py` | engine binding: resolve models to instances, register them into the design's process set, reset |
| `amaranth/sim/_base.py` | engine interface method |

## 7. Tests (outline, hidden file `tests/test_sim_instance_<hash>.py`)

Blocks: (a) helpers building designs with instances; (b) combinational models by type, several
instances of one type, parameters and hierarchy paths; (c) clocked models driven by `ctx.tick()`;
(d) chained models settling in one delta; (e) a model driving a clock signal; (f) `ctx.get` and the
`DriverConflict` on foreign writes; (g) binding precedence and duplicate/no-match errors; (h)
unmodeled instances still hold 0; (i) `reset()` re-runs models; (j) ports connected to slices and
concatenations; (k) VCD output contains model-driven signals.

## 8. Solvability

The reference implementation proves it. Everything the tests touch is public
(`Simulator.add_instance_model`, the handle attributes, ordinary `ctx` methods), so no internal
signature can be guessed wrong in a way that zeroes a run; Python also has no compile-wipe hazard.

## 9. Decisions taken during implementation

- The instance-model core alone measured 191 human-effective LOC, so the second axis from the same
  issue was built: models that replace a whole submodule (`add_submodule_model`), which requires
  suppressing the replaced subtree's processes and releasing its combinationally driven signals.
  That took the total to ~305 human-effective across 7 files.
- `ctx.changed()` rejects anything that is not a bare signal, so a model of an instance whose port
  is connected to an expression could not react to it. The model context builds a new
  `ValueChangedTrigger` for those; pysim wakes on every underlying signal and samples the value.
  Four sites in `_PyTriggerState` had to learn the new kind.
- Suppressing a submodule's processes is not enough on its own: its outputs stay flagged
  `is_comb`, and `eval_assign` then refuses the model's writes. The fragment compiler records the
  comb-driven signal slots per fragment so the flag can be cleared for a replaced subtree.
- Binding precedence is resolved by rebuilding the whole model process set on every add, so the
  outcome does not depend on the order models were added in. Superseded coroutines are closed.
- `io_` ports are deliberately out of scope: modeling them needs IO-net state that pysim does not
  have. They are excluded from the handle and the description says so.
- Final footprint: 7 files, 505 raw / ~305 human-effective LOC, 53 new tests.

## 10. Validation

F2P 53/53 fail on base; 53/53 pass with the solution; base suite 1126 pass unchanged; both patch
orders clean; 3x deterministic in both modes; whole matrix re-run in the built image offline
(`--network none`) as a non-root user. Details in `eval-results.md`.

`tests/test_examples.py` and `tests/test_lib_fifo.py::FIFOFormalCase` are excluded from base mode:
they shell out to Yosys and SymbiYosys, which the base image does not carry, and they fail
identically with and without the solution.
