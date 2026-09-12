# RUNS - transactional 3D Tiles pipeline publication

Compact calibration index for the abandoned candidate. The raw bundles are
stored in `../../archive/3d-tiles-atomic-output/agent-runs.tar.gz`; hashes and
restore instructions are in the adjacent archive manifest.

All runs used the same task family. The recorded verdicts below come from each
run's evaluator result.

| Run | Verdict | Decisive observation |
|---:|---|---|
| 1 | external execution failure | The verifier could not start because local `tsx` was absent in the offline image. |
| 2 | missed requirement | Transactional behavior passed 26/30 cases; overwrite refusal leaked plain `Error` instead of `PipelineError`. |
| 3 | legitimate pass | Complete staged publication, rollback, overwrite, aliasing, and cleanup solution. |
| 4 | missed requirement | Same four overwrite-refusal error-type failures; all 869 baseline tests passed. |
| 5 | legitimate pass | Complete transactional publication and cleanup implementation. |
| 6 | legitimate pass | Complete directory, JSON, package, in-place, rollback, and cleanup implementation. |
| 7 | regression | Functional transaction behavior passed, but overwrite refusal regressed from `PipelineError` to plain `Error`. |
| 8 | missed requirement | Destination preservation passed; overwrite refusal exposed the wrong error class. |
| 9 | legitimate pass | Complete staged and rollback-aware solution across all tested publication forms. |
| 10 | missed requirement | Nearly complete solution with the same four overwrite-refusal error-type failures. |

## Calibration result

Four of the nine executed solver runs passed legitimately. Five independently
converged on the same near-complete architecture and missed only the visible
`PipelineError` contract. One additional run was blocked before tests by the
offline environment. This established that the task was solvable and that its
main discriminator had narrowed too heavily around one error-type boundary.

Later suite revisions spread the discriminators across finalizer failures,
entry-type collisions, temporary-base ownership, default temporary storage,
missing parents, destination setup, and rollback error precedence. Local
verification reached 39/39 focused tests and 869/869 baseline tests, but no
reliable platform image could be produced.

## Why calibration stopped

The pinned upstream revision has no committed dependency lock and omits two
tools invoked by its scripts. Repeated environment revisions then encountered
transient-lock warnings, manifest-mutation warnings, invalid Docker heredoc
forms, forbidden encoded payloads, an oversized build-log instruction, cached
image failures, and finally a 40-minute remote build timeout while fetching Git
attributes before the Dockerfile ran.

The task was explicitly abandoned on 2026-07-23. Do not launch more solver runs
unless the upstream revision has a committed lockfile, all offline tools are
declared, and a pristine minimal image build passes first.
