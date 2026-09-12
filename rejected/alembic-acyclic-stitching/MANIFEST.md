# Alembic acyclic revision stitching archive

Archived on 2026-08-15 after the user confirmed that Alembic was rejected.
That correction is the available external outcome record.

## Evidence boundary

The local workspace contains only the preliminary candidate dossier. It never
contained a promoted problem folder, prompt, hidden tests, reference patch,
Dockerfile, environment gate, solver run, or calibration batch for Alembic.
This archive therefore does not infer artifact identities, test counts,
implementation size, or a solve rate that were not recorded locally.

The preserved dossier reached the same conclusion: at pin `c116cbc0f39d`, it
classified acyclic revision stitching as released upstream behavior, including
`merge --splice`. Those records were moved without content changes. The
user-confirmed rejection closes the candidate without erasing the prior-art
audit or manufacturing missing provenance.

## Preserved candidate records

| Artifact | SHA-256 |
|---|---|
| `candidate-records/DESIGN.md` | `d12f9cb948a4e73f36f4b240689b1155e37389c35502d07a5761c536641e7474` |
| `candidate-records/PLAN.md` | `82932fd4cda9d97ce9f6686becefd01da69ca2055b6eda1809934080485b609a` |
| `candidate-records/SUMMARY.md` | `d08a66ae8a24413d3e2d18d0727dffc6d76cbb793221c2d664a8ca438f841212` |
| `candidate-records/UPSTREAM_AUDIT.md` | `92292a686acbd93f887ac4005be5ab05dbefc11b0185ac95be90d951936c431a` |

The active candidate namespace is now clear. Any future Alembic work requires
a materially different subsystem and a fresh ownership audit; this exact
stitching dossier should not be reopened or cosmetically resubmitted.
