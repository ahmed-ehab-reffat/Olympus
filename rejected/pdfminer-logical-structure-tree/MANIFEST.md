# pdfminer.six logical structure tree rejection archive

Status: **rejected and archived on 2026-08-20**.

Failure reason: **overlap**.

The user supplied only the rejection category, not the overlapping external
task or implementation. This closeout preserves that wording without inventing
provenance. The external rejection supersedes the local novelty screen and the
passing technical package. The exact logical-structure-tree task is closed and
must not be resubmitted unchanged. Any later pdfminer.six proposal must concern
a materially different subsystem and begin with a fresh design and ownership
gate.

## Frozen problem evidence

`problem-records/` is the byte-identical locally validated package and its
design, environment, gap, fairness, false-positive, run, error, summary, and
upstream-audit records. The four submission artifacts retain these SHA-256
identities:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `3eaebbc7e19f7c480801976df1c10f8292467585db64b39601b878d8a0e96830` |
| `test.patch` | `f564861ad943a2fe8fc90d008a82410149898123b3e0171f551c7e61bc4a8bba` |
| `solution.patch` | `faac3cf4e34bb7520682068062a6bf1147f909555f14b061bff5e77627e26c33` |
| `Dockerfile` | `071e55993cff79f283ab05b931c752491a0a72d4dce45aa41d5bea11c1397499` |

`problem-records/ARTIFACTS.sha256` is the compact artifact manifest and
`problem-records/RECORDS.sha256` covers every preserved problem record. Local
validation ended at 249/249 pristine base tests, 14/14 reference focused tests,
263/263 combined tests, and zero survivors in the attempted final mutation
set. No solver calibration was run; terminal calibration remains 0/10.

## Candidate and authoring recovery

`candidate-records/` preserves the preliminary dossier without content change.
Its checksum is recorded in `candidate-records/RECORDS.sha256`.

`authoring-recovery/` preserves the Phase-A prototype harness and eight complete
binary Git recovery patches: the reference prototype and seven mutation trees.
Every patch was applied to a fresh local clone of
`https://github.com/pdfminer/pdfminer.six.git` at
`a18de2a9c479b4c847538500017b449ddaec177e`, and all eight changed files in each
reconstruction matched its source worktree byte-for-byte. The recovery files
are covered by `authoring-recovery/RECOVERY.sha256`.

## Cleanup scope

The read-only helper named by the cleanup protocol was unavailable because
`scripts/inventory.py` does not exist in this checkout. Equivalent explicit
inspection found no task container, raw solver bundle, `.tmp-results` match, or
matching `/tmp` path. `cleanup-inventory.tsv` records the resolved filesystem
inventory, and `docker-resources.tsv` records the two task-tagged, container-free
images selected for removal. The shared Olympus Python base image, unrelated
workspace state, Docker images, volumes, networks, and build cache are excluded.

Cleanup completed after checksum, patch-application, and byte-parity
verification. The active problem and candidate copies and the approximately
855 MiB authoring tree were moved to
`/Users/andrewemad/.Trash/Olympus-pdfminer-logical-structure-tree-20260820/`,
so that filesystem removal is recoverable until Trash is emptied. Both
task-tagged images were untagged and their unshared immutable image records were
deleted. The images can be reconstructed from the archived Dockerfiles,
repository URL, and exact pin. `cleanup-inventory-post.tsv` records the final
absence checks.
