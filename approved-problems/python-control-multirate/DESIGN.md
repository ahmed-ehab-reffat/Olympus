# DESIGN — Multirate (multiple sample time) discrete-time systems for python-control

## 1. Title

Add multirate interconnection and lifting for discrete-time systems

## 2. Target

- Repo: https://github.com/python-control/python-control
- License: BSD-3-Clause, 2059 stars, active (last commit 2026-07-28)
- Base commit: `75a658b6f731785dfdebedadcb06dad522ec63e3`
- Language: Python. Tier: Olympus. Category: feature-request.
- Repo quota: 1 prior submission (`python-control-analysis-points`, approved). 5 slots left.

## 3. Shape classification

O-Composite-add. A new modelling layer (periodically time-varying discrete systems)
that must be threaded through the existing timebase machinery (`iosys`), the
interconnection machinery (`nlsys.interconnect`), the block-diagram operators
(`bdalg`), and the discrete-time conversion module (`dtime`), while leaving every
single-rate code path byte-identical.

## 4. Gate record

| Gate | Result |
|---|---|
| 1 behavioral-f2p-gap | PASS. `interconnect` on systems with different `dt` raises `ValueError`. There is no way to build or simulate a multirate loop today. |
| 2 saturation | PASS. MATLAB has no general multirate interconnection; Simulink's rate-transition blocks are a GUI product, not a library API. Lifting is textbook but the integration is repo-specific. |
| 3 uniform-wrap | PASS. Five opposing mechanisms (base = GCD vs period = LCM, hold registers as states, feedthrough only at update instants, simultaneous update, preservation of the single-rate paths). |
| 4 loc-ceiling | PASS. Build-measured, see § 7. |
| 5 cold-not-live | PASS. `common_timebase` unchanged since 2021; `dtime.py` last touched for docs. No open timebase workstream. |
| 6 reproduce-on-base | PASS. `ct.interconnect([fast, slow], ...)` with `dt=0.1`/`dt=0.2` raises "Systems have incompatible timebases" on base. |
| 7 dedup | PASS. Nothing in `problems/`, `rejected/`, `Aprroved/` touches multirate/sampled-data. The prior python-control submission is about analysis points and loop transfer functions (signal tagging), a different feature class in a different subsystem. |
| 7b exclusivity | PASS. Canonical org `python-control/python-control`. `gh pr list --state all --search multirate` -> nothing. Issue search `multirate`/`timebase` -> nothing open on mixed rates. Branches: `0.8.x`, `0.9.x`, `main`, `stable` — none carry the feature. (PR #1148 "continuous delay systems" is a different capability and does not touch the discrete timebase path; the delay idea was dropped because of it.) |
| 8 defined-behavior | PASS. Multirate sampled-data semantics and lifting (the Kranc operator) are standard control theory. |
| 9 no-flaky-repo | PASS. Whole tree 3814 passed / 559 skipped, 0 failures under `control/`, deterministic across runs. Only `doc/test_sphinxdocs.py` fails, and it fails on the vanilla tree because the sphinx `generated/` stubs are a build product; base mode runs `control/tests` (same scoping as the approved sibling). |
| 10 repo-quota | PASS. 1 of 6. |

## 5. Public API surface

- `interconnect(...)` accepts discrete subsystems whose sample times are commensurate
  and returns a `MultirateSystem` whose `dt` is their greatest common divisor.
- `MultirateSystem(NonlinearIOSystem)` with `period`, `nphases`, `phase_system(k)`,
  `poles()`.
- `lift(sys, dt=None, name=None)` -> `StateSpace`: the lifted, time-invariant
  equivalent at the requested (longer) sample time.
- `series`, `parallel`, `feedback`, `negate`, `append` accept commensurate rates.

## 6. Semantics (the contract)

Base timebase `h` = greatest common divisor of the subsystem sample times.
Period `T` = least common multiple; `P = T / h` phases.

A subsystem with sample time `k*h` acts at base steps `m` with `m % k == 0`:
it reads its input, produces its output from that input and its current state,
and advances its state. At every other base step it holds the input it last read,
its state does not move, and its output does not move. Every subsystem computes
its output from the state it had before any state in the interconnection advanced,
so the result does not depend on the order in which the subsystems are listed.

Consequences that the tests pin:

- The interconnected system carries one extra state per input of every subsystem
  that is slower than the base rate (the held input), placed after that
  subsystem's own states.
- A slower subsystem has no direct feedthrough at the base steps where it does
  not act, so an algebraic loop through it exists only at the steps where every
  system in the loop acts.
- The base rate is the GCD, not the fastest subsystem's rate: rates `2h` and `3h`
  give a system at `h` on which neither subsystem acts every step.
- The single-rate paths are untouched: `interconnect` on equal sample times still
  returns a `LinearICSystem`, and `+`, `*`, `feedback` on two `StateSpace` objects
  with different sample times still raise.

## 7. File footprint (build-measured)

| File | raw / human-effective | Role |
|---|---|---|
| `control/nlsys.py` | 403 / 229 | `MultirateSystem`, per-phase models, `interconnect` dispatch, offsets, nesting |
| `control/dtime.py` | 100 / 44 | `lift` |
| `control/bdalg.py` | 75 / 59 | multirate operand in `series`/`parallel`/`feedback` |
| `control/iosys.py` | 66 / 25 | `commensurate_timebase` and its fraction helpers |
| total | 644 / **357** | clears the 250 sprint floor with margin |

Exports ride on the existing `__all__` lists, so `control/__init__.py` is untouched.
`series`/`parallel`/`feedback` on two ordinary systems with different sample times still
raise, because `timebase_test.py::test_composition` pins that for all three; only a
multirate operand routes through `interconnect`.

## 8. Trap matrix

| # | Trap | Class | Misdirection |
|---|---|---|---|
| 1 | Base rate is GCD, not the fastest rate | A8 boundary | Works for 1:2, silently wrong for 2:3 |
| 2 | The held quantity is the OUTPUT, one state per output | S4 machinery | Holding the input gives the right values at the action steps and wrong ones in between, with no error |
| 3 | Feedthrough must vanish at hold steps | S2 composition | Surfaces as a spurious algebraic-loop error |
| 4 | Outputs from pre-update state (simultaneous update) | S2 composition | Results depend on subsystem order |
| 5 | `common_timebase` must not be loosened | S3 baseline | Breaks `timebase_test.py::test_composition` on `series`/`parallel`/`feedback` |
| 6 | A nested multirate subsystem repeats after its PERIOD, not its sample time | S2 composition | A single-rate outer interconnection is still periodic |
| 7 | Lifted `D` is block lower triangular with the right power of `A` | A9 index arithmetic | Correct on the diagonal, wrong off it |

Trap 2 bit the reference implementation itself: the first build held the input, and the test
asserting that a sampled block's output is constant over its own sampling interval is what
caught it.

## 9. Predicted band

10-30% (Nova/Orion mix).
