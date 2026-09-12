# DESIGN.md - skrf-transient-simulation

## 1. Title

Add transient waveform simulation for networks and circuits.

Verb-led, names the subsystem (`skrf.transient`, driving `Network` and `Circuit`).

## 2. Shape classification

- Shape: **O-Composite-add** (a new capability spanning a new module, the `Network` public API, the
  `Circuit` solver and the package exports) with an **O-Algorithm-correctness** core (the frequency
  to time transform and the loop solve are where the answers go silently wrong).
- Pass rate target: `<= 40%` (sprint cap), designed for the hard edge. Predicted 10 to 25 percent.
- Best agent: Orion (long horizon, commits to one architecture and threads it).
- Dominant verdict expected: MISSED_REQUIREMENT / wrong numeric answer.

## 3. Public API surface

- `skrf.Source` - abstract source, `sample(t) -> ndarray`.
- `skrf.StepSource(amplitude=1.0, delay=0.0, rise_time=0.0)`.
- `skrf.PulseSource(amplitude=1.0, delay=0.0, width=0.0, rise_time=0.0)`.
- `skrf.BitSource(bits, bit_rate, amplitude=1.0, delay=0.0, rise_time=0.0)`.
- `skrf.ArraySource(v)`.
- `skrf.TransientResult` - `t`, `v`, `i`, `a`, `b`, `z`, `node_voltages`, `nports`, `dt`,
  `settled_value(port)`, `threshold_time(port, level)`, `propagation_delay(port, fraction=0.5)`,
  `rise_time(port, low=0.1, high=0.9)`, `overshoot(port)`, `impedance_profile(port)`,
  `eye(port, bit_rate, delay=0.0)`.
- `skrf.Eye` - `traces`, `offsets`, `threshold`, `nui`, `height`, `open_columns`, `width`.
- `Network.transient(sources, z_source=None, z_load=None, loads=None, window=None)`.
- `Circuit.transient(sources, window=None)`.

## 4. Canonical output form

- Time grid: `dt = 1 / (2 * f_max)`, `npoints = 2 * (nfreq - 1)`, record `= 1 / df`, starts at 0.
- Grid preparation: extrapolate to 0 Hz and to a uniform step (the repo's `extrapolate_to_dc`
  interpolates an off-grid start); a linear sweep and two points are required.
- Waves: `a = vs / (2 * sqrt(z))` at a driven port, 0 elsewhere; `v = (a + b) * sqrt(z)`;
  `i = (a - b) / sqrt(z)`, positive into the port.
- Convolution is linear (zero padded, truncated), never circular.
- `threshold_time` interpolates linearly between the straddling samples, returns nan when unreached.
- `overshoot` is in volts, measured in the direction the record settled in.
- `impedance_profile` returns `+inf` where the reflection is total.
- Eye: threshold is the mean of the folded samples, the centre column is at half the column count
  rounded down, upper traces are those above the threshold there, `width` is the total open time.
- Errors are `ValueError` except a non dict `sources` or a non `Source` value, which are `TypeError`,
  and a non linear sweep, which is `NotImplementedError`.

## 5. Blind-spot pre-empts

- Iteration termination: "a reflection travels back through the network any number of times".
- Result ordering: circuit ports follow `port_indexes`.
- Falsy on invalid: `threshold_time` is nan when the level is never reached.
- Default ordering / defaults: source and load impedances default to the port reference impedance.
- Codebase-inferable requirements: 1 (the repo's own `extrapolate_to_dc` is the natural tool).

## 6. Description draft

See `meta.md` (549 words, ASCII, no headers; over the 500 cap by the fairness contract, see feedback.md).

## 7. File footprint

| Action | Path | Raw delta | Human effective |
| ------ | ---- | --------- | --------------- |
| NEW    | skrf/transient.py | 596 | 343 |
| MODIFY | skrf/network.py   | 45  | 6   |
| MODIFY | skrf/circuit.py   | 33  | 4   |
| MODIFY | skrf/__init__.py  | 10  | 9   |

TOTAL: 684 raw / 362 human-effective across 4 files. Clears the 2026-07 sprint floor
(>= 250 effective, >= 2 files) with margin; raw clears the 500 "Good" target.

## 8. Solution outline

Pure-function helpers, one per described behaviour:

- `_ramp(t, delay, rise_time)` - the single transition primitive every source is built from.
- `_uniform_dc_network(ntwk)` - grid validation, DC anchoring, uniform step.
- `_impulse_matrix(ntwk, window)` - windowing, `irfft` with `n = 2 (K)`, causal time vector.
- `_convolve(h, a)` - linear convolution per port pair.
- `_waves_from_sources`, `_port_impedances`, `_as_real_impedances`, `_check_sources`.
- `_reflection_of_loads`, `_close_the_loop` - `(I - S G)^-1 S`, the all orders re-reflection.
- `_result_from_waves` - voltages and currents from the wave records.
- `_circuit_node_voltages` - intersection voltages, mirroring `Circuit.voltages`.
- `_eye`, `_impedance_profile`.

## 9. Test file outline

`skrf/tests/test_transient_4a5a1a.py`, 4 blocks: imports, eight inline network builders (delay line,
series/shunt impedance, attenuator, thru, one port, splitter), one driver helper, then 132 granular
tests grouped by bucket (grid 5, physics 12, waves and currents 6, impedances 8, superposition 3,
grid preparation 5, errors 8, sources 24, measurements 12, network loads 9, impedance profile 6,
eye 13, circuit 14, exports 6). Every fixture is constructed inline; no binary files.

## 10. Forced signatures

Every new name, argument order and default is pinned in `meta.md`, and the error classes are pinned
too, so no agent has to guess a signature (the fake-difficulty anti-pattern).

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt in meta | Catching test |
| - | ---- | ----------------- | ---------------- | ------------- |
| 1 | Circular instead of linear convolution | `ifft(S * fft(a))` is the obvious one liner, and it is exactly right for a periodic input, so simple checks pass. A step held for the whole record then shows no delay at all. | "the response is a linear convolution, so anything arriving past the end of the record is dropped rather than wrapped to the start" | `test_a_step_held_for_the_whole_record_still_shows_the_delay`, `test_delay_line_output_is_quiet_before_the_delay` |
| 2 | Reusing `impulse_response` | It exists, it looks like the right helper, and it `fftshift`s the result (centred, not causal) and windows by default. Delays then come out shifted by half a record. | the grid rules state the record starts at 0 and no window is applied by default | the whole delay family |
| 3 | Not renormalizing to the source and load impedances | The obvious code convolves the network as given; it is only wrong when an impedance differs from `z0`. | "the network is renormalized to those impedances, so such a termination does not reflect" | `test_source_and_load_impedances_combine`, `test_impedance_profile_recovers_the_load_behind_a_mismatched_source` |
| 4 | Treating a `loads` termination as a one shot reflection | Solving `b = S a` once and adding `G b` gives the first bounce and nothing after it. | "whose reflection travels back through the network any number of times" | `test_a_network_load_re_reflects_more_than_once` (three exact bounce levels) |
| 5 | Skipping the DC and uniform grid preparation | A measured network rarely starts at DC; using its own grid silently rescales the time axis. | the grid paragraph | `test_a_network_that_does_not_start_at_dc_is_extrapolated` |

Traps 1 and 2 are interdependent: the natural fix for 2 (drop `fftshift`) does not fix 1, and a
solver that reuses `impulse_response` inherits both. Trap 3 interacts with 4, because closing the
loop has to happen in the renormalized reference.

## 12. Tier and category

- Tier: Olympus. Category: **feature-request** (net new module and public API).

## 13. Predicted pass rate

10 to 25 percent. The physics is standard, so the knowing part is free; the doing part (grid
preparation, causal transform, linear convolution, renormalization, loop closure, circuit node
mapping) is where the silent wrong answers live. Every discriminator is an exact analytic value.

## 14. Quality gate

- [x] Repo understanding (5/5): Frequency / Network / Circuit / media / calibration; entanglement in
      `network.py`, `circuit.py`, `io`; pytest under `skrf/tests`; template `skrf/tests/test_network.py`.
- [x] Existing PR check: `gh pr list -R scikit-rf/scikit-rf --state all --search "<transient|time
      domain simulation|convolution|waveform|eye diagram|channel simulation>"` and the matching issue
      searches return nothing that implements this. (The noise wave PRs 596/597/401 are a different
      capability and are deliberately not touched.)
- [x] Corpus recipe: one interdependent kernel (the impulse matrix) driving five surfaces; analytic
      external oracle (delay lines, dividers, attenuators, bounce diagrams) matched exactly; five
      interdependent and misdirecting traps; every signature pinned.
- [x] Canonical form spelled out; <= 1 codebase-inferable requirement.
- [x] LOC: 373 effective / 695 raw / 4 files.
- [x] Flakiness: no RNG, no clock, no network, no ordering dependence.
- [x] Not pattern-followable: nothing in the repo does time-domain simulation.

## Why this is not a duplicate

Closest local work is `problems/pdfcpu-text-extraction` and `Instructions/Aprroved/techan-costbasis`
(both unrelated domains), and inside the RF domain nothing has been authored here at all. The repo
has never been used in this workspace. The nearest scikit-rf capability is `impulse_response` /
`step_response` / `time_gate`, which transform a network's own response for gating; this task drives
the network with arbitrary sources through terminations and a circuit, which none of them do.

Predicted iteration cycles: 2.
