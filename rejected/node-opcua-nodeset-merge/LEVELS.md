# Calibration levels

## Level 1 — deterministic selected-namespace NodeSet export

Status: `review revision 4 locally verified; 0/10 calibration`.

Revision 4 retains revision 3's wrapper-safe test attribution and adds distinct
cross-namespace subtype and package-root TypeScript API coverage. Revision 3
retained revision 2b's public behavior and random test path while
making all pristine feature failures attributable to the same eleven named
testcases that pass on reference. Revision 2b removed the redundant
legacy-output prompt sentence, used the
random hidden-test suffix `36c2ba`, and added direct RequiredModel metadata
coverage. No solver result from an earlier artifact version exists or carries
forward.

The public contract is in `meta.md`. The reference changes three production files
and reuses the existing NodeSet serializer, dependency calculator, and loader.
The current strict production diff is 131 additions and 53 deletions, so
long-horizon size remains an evidence risk rather than a passed
gate. No solver run has been performed or counted.

Before spending platform runs, follow `CALIBRATION_STRATEGY.md`: run the required
local frontier pre-filter against this exact immutable version, preserve every
trajectory, and then use one ten-run batch in pairs. Any artifact revision
abandons all results for that version and restarts environment, gap, fairness,
false-positive, and calibration state at `0/10`.
