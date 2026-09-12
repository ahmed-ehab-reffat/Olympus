# Levels — Excelize structural reference adjustment

Target calibration band: 1–5 solves in 10 completed platform runs. The current
Long-horizon record additionally requires the median successful solution to
touch at least two production files, contain at least 20 platform-reported
agent messages, and reach 200 strict effective production LOC.

## History

| Level | Behavioral lever | Tests | Reference scope | Solver evidence | Calibration | Verdict |
|---|---|---:|---|---|---:|---|
| L1 | Keep comments/VML, manual breaks, and classic protected ranges coherent through all four row/column edits | 12 | 1 production file, +348/-3 lines | no cold solver yet | 0/10 | exact-version local gates pass; uncalibrated |

## Current immutable level

- Repository pin: `40f8be41a7aecf250fae03b7d79478a22a4e75a9`
- `meta.md`: `745f5d75524980aad1094d27e49ac0939226592b79bc0b6b425f2fbc5677587d`
- `test.patch`: `619b5d4276e0ade214fc2c3539d4b81eed8624ea7defc265906b11861700dc4f`
- `solution.patch`: `0683b4099bc6c91a2625da2d35b75dc561b8d512905d555673b1e8314b4b3b7c`
- `Dockerfile`: `bc744ed1078ad721d86ca847c003e5f490880ddf075e9b8b4132ce0e45b03da6`
- Calibration status: **0/10**.

The package passes the immutable environment, gap, fairness, and false-positive
gates. Eleven repository-grounded incorrect implementations are rejected; a
materially different singleton-serialization implementation passes. These are
verification results, not solver calibration.

The next allowed calibration step is the strategy's local pre-filter with one
or two cold frontier solvers. If that does not establish a dud, start a fresh
ten-run platform batch bound to the hashes above and evaluate it in batches of
two. Any submission-artifact edit abandons that batch and returns the revised
version to 0/10.

## Long-horizon risk

The reference implementation is substantial but naturally fits in the existing
`adjust.go`. Because successful-solver medians—not reference layout—control the
two-file and effective-LOC gates, L1 has a material one-file risk that local
solver evidence must measure. Do not split the implementation or prescribe a
private file layout merely to influence that metric.
