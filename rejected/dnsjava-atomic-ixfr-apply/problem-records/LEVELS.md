# Calibration levels

## Level 1 - atomic IXFR application

Status: `rejected as previously implemented; calibration closed at 0/10`.

The public contract is frozen in `meta.md`. The feature lane has seventeen
named tests, the selected base lane has 121 existing tests, and the complete
reference tree has 1,756 tests. Exact environment, gap, fairness, and
false-positive gates pass. No solver run has been performed or counted.

The reference changes one production file with 119 additions. Independent
correct trials changed the same production file with approximately 110-114
additions, so architecture convergence and the two-file/200-effective-line
long-horizon thresholds are material risks to measure honestly.

The task was rejected before calibration because the feature had already been
implemented. Do not start local frontier or platform runs for this level. A
future dnsjava task must be materially different and begin with a fresh design
and ownership gate.
