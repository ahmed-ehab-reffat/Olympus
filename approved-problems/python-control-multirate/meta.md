---
Repository: https://github.com/python-control/python-control
Issue: N/A
Commit: 75a658b6f731785dfdebedadcb06dad522ec63e3
Language: Python
Title: Add multirate interconnection and lifting for discrete-time systems
---

# Add multirate interconnection and lifting for discrete-time systems

Add multirate support to `interconnect`, which today refuses subsystems whose sample times differ.

Add `commensurate_timebase(dtlist)`, taking sample times or systems carrying them, returning their greatest common divisor, the integer ratio of each to it, and their least common multiple. An empty list, or a timebase unspecified or not finite and positive, is incompatible, and ratios further than 1e-9 relative from every fraction with denominator at most 1000 are incommensurate. Raise `ValueError` for these, and for every other rejection described here.

`interconnect` should take discrete subsystems with commensurate sample times, returning a new `MultirateSystem` at the base timebase, whose `period` is that least common multiple and `nphases` counts the base steps in it. A subsystem whose sample time is `k` base steps acts every `k`th step: it reads its input, produces its output from that and the state it holds, then advances it. At any other step neither its state nor its output moves. Every output comes from the state before any advanced, so listed order does not matter. A subsystem with unspecified timebase acts at every base step. A nonacting subsystem has no direct feedthrough, so a loop through it is algebraic only where every system in it acts.

Each subsystem not acting every step carries one extra state per output, after its own states, named for the output with `_hold` appended, starting at zero.

A new `offsets` argument gives the first base step each subsystem acts at, one per system, from zero and below its ratio, only when sample times differ.

A continuous subsystem sees signals constant over a base step, so it joins as its zero order hold equivalent there, and must be linear. Where that puts every subsystem on the same base step, return the usual single rate result. Discrete subsystems may be nonlinear, and a multirate one repeats after its own period, not its sample time, so a multirate subsystem makes the result multirate over that period even where every sample time is equal. It keeps its own base and period, so where the outer base is finer than its own it advances one of its own steps only once every several outer steps.

`phase_system(k)` gives the model in force at base step `k`, counted round the period, negative steps included and a step that is not exactly a whole number rejected, with no tolerance for one that is merely close. `poles` are the eigenvalues of the product of the phase state matrices taken over one period, `dcgain` is the steady state under a constant unit input at each step, indexed by step, output, input, and `linearize` returns the model at the step holding its time, so a time inside a step gives that step rather than an error. `poles`, `dcgain`, `lift` and negation need every subsystem linear.

Add `lift(sys, dt=None, name=None)`, taking a state space, transfer function or multirate system and returning the time invariant `StateSpace` whose input and output stack the inputs applied and outputs produced over one longer interval, earliest first, keeping its states. `dt` must be a positive integer multiple of the sample time of `sys`, and of its period when multirate; it defaults to that period, else the sample time. A system of any other kind, a `dt` that is not such a multiple, and a `dt` that is not a finite number are all rejections.

Keep existing single rate behavior unchanged: `interconnect` on equal sample times still builds a `LinearICSystem` unless one of the subsystems is itself multirate, and `*`, `+`, `series`, `parallel` and `feedback` still refuse two systems with different sample times, though all five take a multirate operand, including against a plain gain, and return a `MultirateSystem` keeping its period, with `*` and `+` agreeing with `series` and `parallel`.
