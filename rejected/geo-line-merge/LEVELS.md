# LEVELS - geo-line-merge

Difficulty changelog. Same schema as every problem's `LEVELS.md`; see
`/CALIBRATION_STRATEGY.md`. Target: **1-4 solves / 10** (pass rate <=40%, >=1 solve).

`LineMerge` for `georust/geo` (Rust, complex tier). Supersedes the earlier
`laspy` draft.

## History

| Level | Change (the lever) | New tests | Ref soln: files / eff LOC | Local estimate | Platform | Verdict |
|---|---|---|---|---|---|---|
| - | none yet - **design only** | - | - | - | - | not started |

## Status: DESIGN ONLY

No tests, solution, or Dockerfile yet (per `DESIGN.md`: "stop after the corrected
design"). Uniqueness / similarity / license / activity gates are resolved in the
design. First level lands once test.patch + solution.patch exist; then run the
local estimate (`estimate_trajectories/`) before any platform runs.
