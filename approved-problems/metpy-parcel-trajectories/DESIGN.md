# DESIGN.md — metpy-parcel-trajectories

## 1. Title

Add Lagrangian parcel trajectories to the calculation package

## 2. Shape classification

- Shape: O-Algorithm-correctness — a single interdependent numeric kernel with cross-package
  wiring, per `SHAPES.md § Pattern 12`
- Pass rate: design to the corpus mode of about 1 in 10; the live cap is 40 percent
- Best agent: mixed
- Dominant verdict: MISSED_REQUIREMENT and wrong logic (metric terms, stage times, log
  pressure, termination)

## 3. Public API surface

In `metpy.calc`:

- `parcel_trajectory(u, v, start, step, count, *, w=None, surface=None, start_time=None)`
  -> `xarray.Dataset` over `trajectory` and `step` with `longitude`, `latitude` and, on a
  layered wind field, `vertical`
- `sample_trajectory(trajectory, field, *, method='linear')` -> DataArray, or Dataset when a
  Dataset is given
- `trajectory_length(trajectory)` -> DataArray of cumulative great circle metres
- `trajectory_density(trajectory, template, *, weights=None)` -> DataArray of seconds on the
  template's grid, three dimensional when the template has a vertical coordinate
- `trajectory_crossings(trajectory, series, level)` -> Dataset of `time`, `longitude`,
  `latitude` and `direction` over `trajectory` and `crossing`
- `trajectory_spread(trajectory)` -> Dataset of `longitude`, `latitude` and `spread` over
  `step`
- `extend_trajectory(trajectory, u, v, count, *, w=None, surface=None)` -> Dataset

In `metpy.interpolate`:

- `interpolate_to_track(data, longitude, latitude, *, time=None, vertical=None,
  method='linear')` -> DataArray or Dataset over a single `track` dimension

`ValueError` for a count below one, a zero step, components that do not share a grid, a start
point of the wrong width, a missing `start_time` for a steady field, a vertical velocity or
conserved surface without a vertical coordinate, both of those together, a track missing the
times or levels its data needs, mismatched track shapes, an unknown method, and a layered
field sampled along a trajectory that has no vertical.

## 4. Canonical output form

- `trajectory` follows the order of the start points; `step` runs 0..count; `time` is a
  coordinate along `step` and decreases for a backward run.
- `longitude` is degrees east wrapped into [-180, 180), `latitude` degrees north, `vertical`
  in the wind field's vertical units.
- Termination fills the terminating sample and every later one with NaN; earlier samples
  stand. Every reader is NaN wherever the position is.
- Grid lookup matches longitude modulo 360 against the field's own range; a longitude
  coordinate covering the globe is continuous across the seam.
- Vertical interpolation is linear in log pressure for an isobaric coordinate, linear
  otherwise. Coordinates may ascend or descend.
- The sphere is `metpy.constants.earth_avg_radius` for both the metric terms and every
  distance.
- Crossings take a sample exactly on the level as being above it, and pad the `crossing`
  dimension to the largest number of crossings.

## 5. Blind-spot pre-empts

- Result ordering: "in the order the start points were given" and "step zero is the start
  point".
- Iteration termination: "that sample and every later one are missing while earlier samples
  stand".
- Falsy on invalid: "nothing is extrapolated".
- Compound order: the four Runge-Kutta stages are spelled out with their own times.
- Dedup/first occurrence: "scanning the vertical coordinate from its start for the first pair
  of levels that brackets it".
- Codebase-inferable requirements: 1 (reading a projected grid through `pyproj`, which
  `calc/cross_sections.py` already does).

## 6. Description

`meta.md`, 889 words, ten paragraphs, none over 150 words, ASCII.

## 7. File footprint

| Action | Path | Raw | Human-effective |
| --- | --- | --- | --- |
| NEW | src/metpy/calc/trajectory.py | 608 | 258 |
| NEW | src/metpy/interpolate/track.py | 286 | 189 |
| MODIFY | src/metpy/calc/__init__.py | 2 | 2 |
| MODIFY | src/metpy/interpolate/__init__.py | 2 | 2 |
| MODIFY | docs/_templates/overrides/metpy.calc.rst | 11 | 0 |

Total 908 raw / 462 human-effective across 5 files.

## 8. Solution outline

- `_horizontal_grid(field)` — longitude and latitude onto the field's own axes, through the
  projection when the grid is projected, extending a global longitude axis by a seam column.
- `_axis_weights(coord, values, log)` — bracketing index and weight on one axis, ascending or
  descending, in the log of the coordinate when asked, with an outside mask.
- `_FieldSampler` — transposes a field into time, vertical, y, x and interpolates over the
  axes it has; `method='nearest'` rounds the weights.
- `_nearest_index(coord, values)` — closest point on an axis, for the residence time grid.
- `_rates(u, v, w, lat)` — metric terms, NaN at a pole.
- `_rk4_step(...)` — the four stages, each sampling at its own time and position.
- `_surface_level(sampler, target, ...)` — the level where a conserved field takes a value.
- `_matching_grid`, `_step_seconds`, `_wrap_longitude`, `_start_points`, `_trajectory_step`,
  `_check_method` (shared by `sample_trajectory` and `interpolate_to_track`).

## 9. Test file

`tests/calc/test_trajectory_e16964.py`, 154 tests: builders for geographic, layered,
projected, descending, global and steady fields; assertion helpers; then groups for result
shape, metric terms, Runge-Kutta, interpolation, termination, three dimensional runs,
conserved surfaces, sampling, length, residence time, crossings, spread, extension, the track
interpolator and the validation errors. Two groups check the path against
`scipy.integrate.solve_ivp` at 1e-12 on fields the grid represents exactly.

## 10. Forced signatures

`w`, `surface`, `start_time`, `method` and `weights` are keyword only; `step` accepts a
timedelta or a quantity of time; `start` accepts one point or a sequence. All pinned in
meta.md.

## 11. Trap matrix

| # | Trap | Why agents hit it | Test |
| --- | --- | --- | --- |
| 1 | the zonal metric term needs the cosine of latitude at each stage | the obvious code divides by the radius alone | `zonal_step_uses_the_cosine_of_latitude` |
| 2 | stages two and three read the field at the midpoint time | agents reuse the step-start field | `time_varying_wind_is_sampled_within_the_step` |
| 3 | isobaric interpolation is in log pressure | linear in pressure looks right | `speed_between_levels_is_interpolated_in_log_pressure` |
| 4 | descending latitude and pressure axes | `searchsorted` assumes ascending | `descending_pressure_grid_gives_the_same_path` |
| 5 | leaving the field NaN-fills the rest | agents stop the loop or clamp | `leaving_the_grid_gives_missing_values` |
| 6 | a global longitude axis is periodic | the seam falls outside the range | `global_grid_is_continuous_across_the_seam` |
| 7 | a projected grid is read through its projection | agents index it by longitude | `projected_grid_is_read_through_its_projection` |
| 8 | a conserved surface is relocated at every stage | agents locate once per step | `conserved_parcel_reads_the_wind_at_each_stage` |

Traps 1, 2, 4, 5 and 7 share the stage evaluation, so a local repair of one leaves the others
failing. Fifteen mutations, all killed; the table is in feedback.md.

## 12. Tier and category

Olympus, feature-request.

## 13. Predicted pass rate

10 to 25 percent. Levers stacked: one interdependent kernel feeding every stage and every
reader, an external oracle (`solve_ivp` at 1e-12, plus closed-form metric-term answers), eight
interdependent traps including two where the obvious code is wrong, a two-package span, and
every signature pinned.

## 14. Quality gate

All items confirmed in feedback.md: repo understanding, exclusivity searches, corpus scaffolds
(`pvlib-loss-attribution` and `python-control-multirate` read side by side), LOC floor,
canonical form, test coverage, trap matrix, category, flakiness, environment.

## Why this is not a duplicate

`python-control-multirate` is sample-rate algebra on transfer functions;
`stonesoup-multiple-model` estimates state from measurements; the shelved
`orb-geofence-visits` consumes trajectories rather than computing them. No approved problem
integrates a parcel through a gridded field or touches MetPy.

Predicted iteration cycles: 2
