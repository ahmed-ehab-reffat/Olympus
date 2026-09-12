# Solver runs — kapture dependency-closed dataset subset

Status: platform accepted and archived 2026-08-19. Fresh exact-v8 calibration
remained 0/10 at closeout; acceptance is the user-confirmed external result.

## Immutable v8

Fresh calibration is 0/10. The expected result is 2–4 successful solvers out
of ten.

The five unhinted `agent-runs2` solutions targeted v7 and all legitimately
passed 181 base tests/five skips plus 13/13 focused nodes. Their complete
patches were reviewed before v8 design. Runs 1, 3, and 4 copy the old output and
delete whole standard roots; run 2 deletes whole recognizable feature
collections; run 5 removes path-level managed entries.

Before artifact changes, v8 compatibility was forecast at 1/5. Exact replay
observed:

| Runs | Base | V8 focused | Decisive result |
|---|---:|---:|---|
| 1, 3, 4 | 181 passed, 5 skipped | 12/13 | lose unrelated record/feature sidecars with whole-root cleanup |
| 2 | 181 passed, 5 skipped | 12/13 | loses unrelated sidecar within a managed feature collection |
| 5 | 181 passed, 5 skipped | 13/13 | path-selective old-managed cleanup preserves nested unrelated files |

Observed compatible replay is therefore 1/5, matching the forecast. It is
architecture evidence, not fresh calibration.

## Earlier evidence

The ten `agent-runs1` patches targeted the pre-v7 contract. V7 compatibility
was forecast and observed at 0/10 because they lacked reverse image selectors
and transactional materialization. Those runs remain trajectory evidence but
cannot count toward v8.
