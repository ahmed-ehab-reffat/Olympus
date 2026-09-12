# LEVELS - geo-polygonize

Difficulty changelog. Same schema as every problem's `LEVELS.md`; see
`/CALIBRATION_STRATEGY.md`. Target: **1-4 solves / 10** (pass rate <=40%, >=1 solve).

## History

| Level | Change (the lever) | New tests | Ref soln: files / eff LOC | Local estimate | Platform | Verdict |
|---|---|---|---|---|---|---|
| L1 | `Polygonize` reference reconstruction task | (see test.patch) | (see solution.patch) | - | - | **abandoned** |

## Status: ABANDONED

Locally complete and gate-verified, but **killed on the platform by the
plagiarism / similarity check** - the operation was too close to existing archived
submissions. This is what prompted the pivot to `noodles-md` (a niche
genomics-format task far less likely to collide). See `SUMMARY.md`, `ERRORS.md`,
and `noodles-md/SUMMARY.md` ("Why this re-target").

Not being iterated. Kept for reference and as the cautionary case behind the
"similarity is the top risk" rule.
