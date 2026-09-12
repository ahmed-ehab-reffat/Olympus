# DESIGN.md — pandapower-reliability-assessment

## 1. Title

Add reliability assessment of supply interruptions

Repo: `e2nIEE/pandapower` (BSD-3, 1233 stars, Python, 132k LOC, last commit 2026-08-06).
Base commit: `af68dbc0f5af548b6ac7099112160acde0927ed6` (branch `master`, version 3.5.4).

## 2. Shape classification

- Shape: **O-Algorithm-correctness** — a new capability whose correctness rests on two
  different topological cuts of the same network and on which loads count as interrupted,
  not on a breadth of independent cases.
- Pass rate target: <= 40% sprint cap, designed for 1-3 of 10.
- Best agent: Orion (long-horizon, commits to one architecture).
- Dominant expected verdict: MISSED_REQUIREMENT (wrong interruption frequency) and
  WRONG_LOGIC (one cut used for both zones).

## 3. Public API surface

Every name below is asserted by the tests and named in `meta.md`.

- `pandapower.reliability.calc_reliability(net, switching_time_h=1.0, remote_switching_time_h=0.05)`
  — runs the assessment and writes the four result tables.
- `net.res_reliability_bus` — per supplied in-service bus:
  `interruption_rate_1_per_year`, `outage_duration_h_per_year`, `average_interruption_time_h`.
- `net.res_reliability_load` — the same three columns per in-service load at a supplied bus,
  plus `energy_not_supplied_mwh_per_year`.
- `net.res_reliability` — one row, columns `saifi_1_per_year`, `saidi_h_per_year`, `caidi_h`,
  `asai`, `ens_mwh_per_year`, `aens_mwh_per_year`, `ecost_eur_per_year`.
- `net.res_reliability_element` — one row per event with `et`, `element`, `kind`,
  `rate_1_per_year` and its share of SAIFI, SAIDI and ENS, sorted by descending SAIDI share.
- `pandapower.topology.protection_zones(net)` — `pd.Series` indexed by in-service bus,
  ascending, value the zone number.
- `pandapower.topology.isolated_buses(net, element, et="l")` — sorted array of the buses inside
  the isolated part of that element.
- `pandapower.topology.isolating_switches(net, element, et="l")` — sorted array of the switches
  that have to be opened to isolate it.
- `pandapower.topology.restorable_buses(net, element, et="l")` — sorted array of the buses that
  reach an external grid once the isolated part is gone, ignoring the transfer limit.

Input parameters are optional columns, following the `max_loading_percent` precedent:
`net.line["failure_rate_per_km_per_year"]`, `net.line["repair_time_h"]`,
`net.line["maintenance_rate_per_year"]`, `net.line["maintenance_time_h"]`; the same four on
`net.trafo` and `net.bus` except that the bus and trafo failure rate is
`failure_rate_per_year`; `net.load["customers"]`, `net.load["interruption_cost_eur_per_mwh"]`,
`net.switch["remote_controlled"]` and the existing `net.ext_grid["max_p_mw"]` as the transfer
limit.

## 4. Canonical output form

- `protection_zones`: zones numbered from 0 in ascending order of their smallest bus.
- `isolated_buses`, `isolating_switches`: sorted ascending, `int64`, duplicate-free.
- Result tables indexed ascending; buses that are out of service or not supplied in the given
  switching state, and loads at such buses, do not appear at all.
- `average_interruption_time_h` is `nan` where the interruption rate is zero.
- With no customers at all the four customer weighted indices are `nan`; `ens_mwh_per_year`
  is still defined.
- A net without any failure data yields all-zero rate and duration columns, not an empty table.

## 5. Blind-spot pre-empts

- Frequency versus duration: "a load that is reconnected still counts as interrupted".
- Two different cuts: the breaker cut and the switch cut are described in separate sentences
  with their own reachability rule.
- Incidence semantics: "a switch sits between a bus and the element it connects, and cutting
  it removes that connection only".
- Planned outages: stated as a separate rule with its own frequency treatment.
- Iteration termination is not an issue here; instead the ordering of the returned arrays and
  the zone numbering are pinned.

One codebase-inferable requirement: that a bus-bus switch is cut as a whole (it connects two
buses, so there is no other reading) is left to the reader.

## 6. Description draft

See `meta.md`.

## 7. File footprint

| Action | Path | Raw delta | Reason |
| --- | --- | --- | --- |
| NEW | `pandapower/reliability/__init__.py` | +5 | package export |
| NEW | `pandapower/topology/incidence.py` | +249 | bus/element incidence graph and the four cuts |
| NEW | `pandapower/reliability/run_reliability.py` | +297 | events, durations, accumulation, results |
| MODIFY | `pandapower/topology/graph_searches.py` | +104 | the four public topology queries |
| MODIFY | `pandapower/create/network_create.py` | +1 | a new net carries the result tables |
| MODIFY | `pandapower/network_structure.py` | +30 | the four result tables |
| MODIFY | `pandapower/auxiliary.py` | +6 | net attribute annotations |
| MODIFY | `pandapower/results.py` | +8 | reliability results are cleared with the rest |
| MODIFY | `pandapower/__init__.py` | +1 | package import |
| MODIFY | `pandapower/network_schema/*.py` | +90 | declare the new optional columns |

Actual: **558 human-effective / 812 raw across 14 files**, padding floor 348. The design grew two
behaviours during the build, both because the first draft measured 351 human-effective: the
per part transfer limit on restoration and the `res_reliability_element` contribution table. See
`feedback.md`.

## 8. Solution outline

`topology/incidence.py`

- `SwitchIncidence`: a node per in-service bus and per in-service line, transformer,
  three-winding transformer and impedance; an edge per connection carrying the switches on it.
- `components(cut, exclude)` — union-find over the edges a cut leaves, a cut being a predicate
  over an edge's switches. Four of them: `_cut_switched` (the isolated part), `_cut_breakers`
  (the protection zone), `_cut_open` (the present switching state) and `_cut_nothing` with the
  isolated part excluded (what can be picked up again).
- `part`, `border_switches`, `buses`, `supply_nodes`, `reconnectable_parts`, `reconnectable`.

`reliability/run_reliability.py`

- `_collect_events` — one row per (element type, index) with rate and time, skipping missing,
  non positive and out-of-service entries; a line's rate is scaled by its length.
- `_bus_demand` / `_bus_capacity` / `_reconnectable` — the per part transfer limit.
- `_fault_durations` — the three-way classification per bus; `_maintenance_durations` — the
  two-way one.
- `_bus_results` / `_load_results` / `_system_indices` — the IEEE 1366 aggregation.
- `_weights_per_bus` / `_element_results` — the per event contribution table.
- `calc_reliability` — the event loop and writing the four tables.

`graph_searches.py` gains the four public wrappers over `SwitchIncidence`.

## 9. Test file outline

Path: `pandapower/test/reliability/test_reliability_<hex>.py`, four blocks
(imports / network builders / assertion helpers / tests). Buckets:

1. protection zones: radial feeder with one breaker, several breakers, no breaker, bus-bus
   breaker, open switch acting as a zone boundary, meshed network, out-of-service elements.
2. isolated part: line with switches at both ends, at one end, none, bus-bus switches,
   transformer, bus events, the returned switch set.
3. fault durations: load inside the isolated part, load restored through the tripped breaker,
   load restored through a tie switch, load with no restoration path, load outside the zone.
4. frequency: a restored load still counts, a load outside the zone does not.
5. remote control: the isolating switches all remote, one of them manual.
6. planned outages: no breaker trip, restorable loads not interrupted at all.
7. system indices: hand-computed SAIFI/SAIDI/CAIDI/ASAI/ENS/AENS on a small feeder, the
   customer-free net, the data-free net.
8. plumbing: result tables survive `to_json`/`from_json`, `reset_results` clears them, an old
   net without the tables gets them from `convert_format`, missing columns raise.

## 10. Forced signatures

`calc_reliability(net, switching_time_h=..., remote_switching_time_h=...)` and the three
topology functions take `(net, element, et)`. Result tables are `pd.DataFrame`.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt in meta | Catching test |
| --- | --- | --- | --- | --- |
| 1 | The breaker cut and the switch cut are two different partitions of the same network; a single helper reused for both either over-trips or under-isolates | one traversal looks like it can serve both | two separate sentences, each with its own rule | zone tests versus isolated-part tests on the same net |
| 2 | A load that is reconnected after the switching time still counts once in the interruption rate | the natural loop accumulates duration and derives the rate from it | "counts as interrupted even though it is reconnected" | SAIFI on the tie-switch feeder |
| 3 | A bus-element switch cuts one incidence, not the element; the isolated part therefore reaches past the far end of a line with a switch on one side only | `create_nxgraph` drops the whole edge | the incidence sentence | one-sided switch isolation |
| 4 | Restoration is connectivity after removing the isolated part with every switch allowed to close, not connectivity in the base graph | `unsupplied_buses` is right there | "any switch may be closed" | tie-switch restoration |
| 5 | Planned outages do not trip a breaker and do not interrupt a load that can be transferred | the fault path is already written | the planned-outage sentence | maintenance frequency tests |
| 6 | The switching time is the remote one only if every isolating switch is remote controlled | the switch set is easy to approximate by the section border buses | "every switch that has to be opened" | mixed remote/manual test |
| 7 | The transfer limit is a property of a whole part, not of a bus | per bus connectivity is what the restoration check already produces | "the `p_mw` of the in service loads in it" | the limit tests |

## 12. Tier + category

Tier: Olympus. Category: feature-request.

## 13. Predicted pass rate

10-25%. Six traps, of which 1/3 and 2/5 are interdependent pairs: fixing the cut used for the
isolated part changes which loads are restorable, which changes the frequency; and the planned
outage rule shares the restoration machinery with the fault rule but counts differently.

## 14. Quality gate

- [x] Repo understanding: element tables / switch semantics / topology graph / results
      lifecycle / convert_format.
- [x] Exclusivity: canonical org `e2nIEE/pandapower`, PR and issue search over reliability,
      SAIFI, SAIDI, interruption, outage, restoration, sectionalizer returns nothing; the
      33 branches contain no reliability work (harmonics is taken and was dropped as a pick).
- [x] Maintainer philosophy: no declined reliability request exists.
- [x] Cold code: the capability is absent entirely.
- [x] Repo quota: zero of our submissions, 1233 stars, not on the saturated list.
- [x] Dedup: nothing in `Aprroved/`, `problems/`, `rejected/` or the task folders touches power
      systems or outage statistics.
- [x] Environment: 241 tests in `pandapower/test/topology` and `pandapower/test/api` pass
      offline in the image as uid 1000, identical across three runs.
- [x] Twenty mutation probes, nineteen with a non-empty kill set.
- [x] FP self-audit closed three gaps: column order, the contribution tie-break and the
      undocumented `UserWarning`.

Built and validated 2026-08-06. 69 new tests, 241 base cases, all four validation cells green.
