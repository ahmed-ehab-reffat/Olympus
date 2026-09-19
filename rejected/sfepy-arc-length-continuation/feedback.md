# feedback.md - sfepy-arc-length-continuation

## Status

**REJECTED at scope gate 2026-09-17: publicly-solved (JAX-FEM `jax_fem/solver.py:595`, 7/15 cases). Corpus overlap 1.9%.** Base
`307e51ecf3b57fc364104630e62ae1fa8ed88c55`. Do not write the EBC/LCBC load cells, rollback cells or
path queries until the scope verdict is clean.

Platform picker: eligible, BSD-3, but warns "already used in 25 submissions by 6 other contributors".
Derivative risk is the live risk; the precheck is the only instrument that can see it.

## Why this pick

Hunt log: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-17.md`. Zero source/issue/PR hits for
arc-length / continuation / limit point; `ts.simple` reproduced jumping branches at the analytic fold
lambda = 2 on base.

## Core slice

- `ts.arc_length` (`ArcLengthSolver`) in `sfepy/solvers/ts_solvers.py`: predictor with the stated
  direction rule, corrector with the arc-length constraint and root rule, ds cut / growth, exact landing
  on `t1`, `t_min`/`t_max`, `max_steps`, `status.path` / `limit_points` / `termination`.
- `VariableTimeStepper.set_time` / `advance_to` in `sfepy/solvers/ts.py`.
- 205 human-effective, 2 files. 15 tests on the analytic 1D fold T^3 - 3T = lambda.

## Validation record (core slice, Docker `sfepy-hunt:head` at base, uid 1000, `--network none`)

| Check | Result |
|---|---|
| test.patch applies, test.sh mode 100755 | yes |
| New tests on base | 15 of 15 fail as test failures (no collection crash), JUnit written |
| solution.patch applies, hunks landed | `ArcLengthSolver` and `advance_to` present |
| New tests with solution, 3x | 15/15 pass every run (~21 s) |
| Base suite with solution, 3x | 221/221 pass every run (~5.7 min) |
| Encoding / comments | ASCII patches, zero added comments |
| meta.md | 403 body words, ASCII, frontmatter present |

## Owed after a clean precheck

EBC-driven and LCBC (balloon) load cells, rollback-after-rejection cells, growth cells, F-10 table,
LOC to 275+, full Docker rebuild from the Dockerfile, flakiness re-run.

## Attempt history

| Round | What changed | Result |
|---|---|---|
| R0 | core slice + meta.md + Dockerfile (approved sfepy image recipe) | precheck owed |
