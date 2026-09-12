# Calibration levels - failure-atomic pipeline output

**Status: ABANDONED ON 2026-07-23 FOR ENVIRONMENT UNSUITABILITY.**

## Final level

The implemented level is the approved design in `DESIGN.md`: atomic publication
across directory, custom-JSON, 3TZ, and 3DTILES outputs, with overwrite parity,
same-input/output support, temporary ownership, nested missing parents, and
rollback error precedence.

Local evidence is complete: all 39 focused specs fail at the base commit and
pass with the solution, and all 869 upstream specs pass before and after under
the pinned Node 22 dependency graph. The expanded level adds target-finalizer,
entry-type replacement, single-stage temp validation, nested temp-base, and
post-finalizer destination-setup boundaries.

## Calibration status

Platform review found over-strict success comparisons and focused cases that
also passed without the solution. Those findings are resolved locally: JSON is
now compared semantically on success, related success and rollback scenarios
share one spec, every focused spec rejects the base commit, and default temp
checks use an isolated `TMPDIR` instead of diffing a shared OS temp directory.
The new trajectory's environment block is also resolved by installing local
`tsx` and the complete locked development toolchain.

Ten solver runs produced four legitimate passes, five near-complete
error-contract misses, and one external bootstrap failure. The compact matrix is
in `RUNS.md`; raw evidence is archived. No further level should be calibrated
unless a new upstream revision commits its dependency lock and passes a
pristine offline-image preflight.
