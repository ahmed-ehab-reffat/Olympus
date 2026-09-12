# eval-results.md - skrf-transient-simulation

No agent batch has been run yet. This file records the local evidence and will hold the per-agent
table once a batch lands.

## Per-agent results

| Batch | Agent | Evaluator | Verdict | Messages | Files | LOC | Failed tests | Failure reason | Approach |
| ----- | ----- | --------- | ------- | -------- | ----- | --- | ------------ | -------------- | -------- |
| - | - | - | not run yet | - | - | - | - | - | - |

## Local difficulty evidence (mutation battery)

Each row is a wrong-but-plausible implementation of the reference, run against the 211 hidden tests.

| # | Mutation | Tests killed | First tests to fail |
| - | -------- | ------------ | ------------------- |
| M1 | circular convolution instead of linear | 16 | delay_line_transmits_the_step_at_the_line_delay, delay_line_output_is_quiet_before_the_delay |
| M2 | centred impulse response (what `impulse_response` returns) | 19 | delay_line_transmits_the_step_at_the_line_delay, shorted_line_reflects_after_two_delays |
| M3 | no renormalization to the source and load impedances | 7 | source_impedance_changes_the_divider, load_impedance_changes_the_divider |
| M4 | a network load reflects only once | 3 | a_network_load_re_reflects_more_than_once |
| M5 | no DC anchoring / uniform grid preparation | 1 | a_delay_line_that_does_not_start_at_dc_keeps_its_delay |
| M6 | a window applied by default | 23 | delay_line_transmits_the_step_at_the_line_delay |
| M7 | threshold crossing without interpolation | 6 | threshold_time_interpolates_between_samples |
| M9 | eye threshold fixed at 0 V instead of the mean | 3 | eye_threshold_sits_between_the_levels |
| M10 | node voltage without the splitter transmission factor | 3 | a_three_way_junction_node_voltage_matches_its_ports |
| M11 | incident wave missing the factor two | 45 | matched_thru_splits_the_source_in_half |
| M12 | current sign flipped | 3 | current_flows_into_the_driven_port |
| M14 | impedance profile referenced to the first sample | 1 |
| M15 | no crossing required, reports the start instead of nan | 2 | impedance_profile_uses_the_settled_incident_wave |

13 of 13 mutations killed. Two further mutations (an unfloored `overshoot` and a
non-contiguous eye `width`) turned out to target code that could never be reached; that code was
deleted from the reference rather than shipped as dead defensive logic, so those mutations no longer
apply.

## Test coverage by bucket

| Bucket | Tests |
| ------ | ----- |
| time grid (step, start, length, record, uniformity) | 5 |
| physics against analytic values (thru, attenuator, series, shunt, delay, short, open, matched) | 12 |
| waves, voltages and currents | 6 |
| source and load impedances | 8 |
| superposition and multiport | 3 |
| grid preparation and rejection (DC, off-grid start, log sweep, single point, frequency dependent z0) | 6 |
| argument errors | 4 |
| sources (step, pulse, bits, array) | 24 |
| measurements (settled, threshold, delay, rise time, overshoot) | 12 |
| network terminations that re-reflect | 9 |
| impedance profile | 7 |
| eye statistics | 13 |
| circuit (ports, nodes, junction, superposition, rejection, cross check) | 14 |
| window | 2 |
| package exports and result types | 6 |
| impedance validation boundaries | 3 |
| result array shapes | 1 |
| frequency dependent load, circuit window, circuit argument parity | 4 |
| **total** | **211** |

## Suite behaviour

| Mode | Base tree | With solution |
| ---- | --------- | ------------- |
| `test.sh base` | 1701 passed, 52 skipped, 4 xfailed (1821 nodes) | same |
| `test.sh new` | 211 failed (211 named nodes) | 211 passed |

Three consecutive Docker runs of each mode gave identical counts.


## Batch 1 - platform agents, 2026-08-04 (artifacts in `agent-runs(12)/`)

| agent | verdict | new-test failures | blocking cause |
| --- | --- | --- | --- |
| Orion_Nova_1 | FAIL_MISSED_REQUIREMENT | 1 | eye both-levels validation |
| Nova_Nova_4 | FAIL_MISSED_REQUIREMENT | 2 | eye both-levels, settled_value port range (IndexError) |
| Nova_Nova_6 | FAIL_MISSED_REQUIREMENT | 2 | eye both-levels, impedance_profile undriven |
| Nova_Nova_5 | FAIL_MISSED_REQUIREMENT | 4 | port range x2, falling threshold_time, non-DC delay |
| Orion_Nova_2 | FAIL_WRONG_LOGIC | 4 | circuit intersection voltages x3, eye both-levels |
| Orion_Nova_3 | FAIL_REGRESSION | 4 | eye, non-DC delay, parameterised window x2; baseline lazy-import regressed |
| Nova_Nova_2 | FAIL_MISSED_REQUIREMENT | 6 | port range x2, impedance undriven, eye, non-DC delay, on-sample threshold |
| Nova_Nova_3 | FAIL_MISSED_REQUIREMENT | 6 | port range x2, circuit source order x3, non-DC delay |
| Nova_Nova_1 | FAIL_TEST_MISMATCH | 38 | settled_value implemented as a property, not a method |

**Pass rate 0 of 9 = unsolvable reject.** Baseline suite clean in 8 of 9 (Orion_Nova_3 regressed the
lazy-import contract). Five defects fixed in round 24; projected ceiling on a re-run is 3 of 9 (33%).


## Batch 1 REPLAYED against the fixed suite (local, agent patches from `agent-runs(12)/`)

| agent | new-test failures before | after | remaining blocker |
| --- | --- | --- | --- |
| Orion_Nova_1 | 1 | **0 - FULL PASS (210/210 new, 1920/1920 base)** | none |
| Nova_Nova_4 | 2 | 1 | settled_value port range (now documented) |
| Nova_Nova_6 | 2 | 1 | impedance_profile undriven (now documented) |
| Orion_Nova_2 | 4 | 3 | circuit intersection voltages |
| Orion_Nova_3 | 4 | 3 | DC extrapolation settles at 0.71 V, parameterised window x2 |
| Nova_Nova_5 | 4 | 4 | port range, falling threshold_time, DC extrapolation |
| Nova_Nova_2 | 6 | 5 | port range x2, impedance undriven, DC extrap, on-sample threshold |
| Nova_Nova_3 | 6 | 6 | port range x2, circuit source order x3, DC extrapolation |
| Nova_Nova_1 | 38 | 37 | settled_value as a property (signature now pinned in meta) |

**Measured pass rate 1 of 9 = 11%.** Solvable, verified on real agent output rather than projected.
Expected on a platform re-run: 3 of 9 (33%), since Nova_4 and Nova_6 are each blocked only by a
validation the description now states.
