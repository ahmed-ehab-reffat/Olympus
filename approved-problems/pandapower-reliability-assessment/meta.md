---
Title: Add reliability assessment of supply interruptions
Repository: https://github.com/e2nIEE/pandapower
Language: Python
Issue: reliability-assessment
Commit: af68dbc0f5af548b6ac7099112160acde0927ed6
---

# Add reliability assessment of supply interruptions

`calc_reliability(net, switching_time_h=1.0, remote_switching_time_h=0.05)` in a new `pandapower.reliability` module takes every line, transformer and bus out of service once. A line fails `failure_rate_per_km_per_year` times its `length_km` per year and is repaired in `repair_time_h`; transformers and buses use `failure_rate_per_year`. A missing or non positive rate means no event, a missing time is zero, and out of service elements never fail.

Reachability runs over buses and the elements between them, and a switch sits between a bus and the element it connects, or between two buses; cutting it removes that connection only. When an element fails, everything reachable without passing a closed circuit breaker (`type` "CB") or an open switch loses supply. It is then isolated at the switches on the border of the part reachable without passing any switch; the loads inside wait for the repair.

Every other bus that lost supply is back after `switching_time_h` if it reaches an external grid once the isolated part is gone and any switch may be closed, otherwise it waits for the repair; either way it counts as interrupted. The time is `remote_switching_time_h` when every switch that had to be opened is `remote_controlled`; a missing flag or column is manual.

A part is picked up only if the `p_mw` of its in service loads does not exceed the `max_p_mw` of the in service external grids in it, a missing limit meaning none.

`maintenance_rate_per_km_per_year` (`maintenance_rate_per_year` for transformers and buses) with `maintenance_time_h` describes planned outages, subject to the same rate and time rules, isolated before the element is switched out: no breaker operates, load that can be picked up elsewhere is not interrupted, and the rest waits out the maintenance time.

`net.res_reliability_bus` and `net.res_reliability_load` carry `interruption_rate_1_per_year`, `outage_duration_h_per_year` and `average_interruption_time_h`, their quotient and `nan` at rate zero, for every supplied in service bus and in service load on one. Loads add `energy_not_supplied_mwh_per_year`, the duration times `p_mw`, and `interruption_cost_eur_per_year`, that times `interruption_cost_eur_per_mwh`, missing being zero.

`net.res_reliability` holds one row: `saifi_1_per_year` and `saidi_h_per_year`, both weighted by the load `customers`, missing counting zero, `caidi_h` and `nan` without interruptions, `asai` against 8760 hours, `ens_mwh_per_year`, `aens_mwh_per_year` and `ecost_eur_per_year`; with no customers the five weighted ones are `nan`.

`net.res_reliability_element` gives every event its `et` and `element`, the type using the same codes as `net.switch.et` with "b" for a bus, its `kind` of "fault" or "maintenance", `rate_1_per_year` and how much of `saifi_1_per_year`, `saidi_h_per_year` and `ens_mwh_per_year` it causes, in columns of those three names, sorted by descending `saidi_h_per_year`, then `et`, `element` and `kind`. All four belong to a new network, survive `to_json`/`from_json` and are emptied by `reset_results(net, "rel")`. A network without an in service external grid raises `UserWarning`.

`pandapower.topology` gains `protection_zones(net)`, a `pandas` Series over the in service buses in ascending order, numbering the zones from zero by their smallest bus. `isolated_buses(net, element, et="l")`, `isolating_switches(net, element, et="l")` and `restorable_buses(net, element, et="l")` return `numpy` integer arrays, sorted ascending, of the isolated part, its border switches and the buses reaching a grid once it is gone with any switch closable, the last ignoring the transfer limit. `et` uses the codes of `net.switch.et` with "b" for a bus. `import pandapower` exposes `pandapower.reliability`.
