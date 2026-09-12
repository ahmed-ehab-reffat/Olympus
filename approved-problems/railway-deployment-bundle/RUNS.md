# Railway deployment bundle run index

## Outcome

Canonical version 33 was accepted on 2026-07-29. The acceptance is
user-confirmed; this record does not invent an additional solve-rate result
beyond the historical batches documented in `LEVELS.md` and `DESIGN.md`.

Accepted identities:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `6674edbce3495a8d3dfba725ba769b0fa8a633cc94054f55bee2b4049799f8cd` |
| `test.patch` | `850fa6491c50eb0e021a03340108eaf250706c323f5c1af3f4a8ca6580617851` |
| `solution.patch` | `52cfd1502465ef484db613a95d0d41430a7a28da4ade565bac40d45108e7ac14` |
| `solution_approach.md` | `cd54d38e8ce2f6c5256de0a595e90940d35124a7115601ee8a857761f84b14bc` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

## Raw batches

The historical working directories were:

- `agent-runs`
- `agent-runs2`
- `agent-runs3`
- `agent-runs4`
- `agent-runs5`
- `agent-runs6`
- `agent-runs7`
- `agent-runs8`
- `agent-runs9`
- `agent-runs10`
- `agent-runs11`

Their version mapping, pass rates, representative implementations, recurring
failure families, and revision decisions remain in `LEVELS.md` and
`DESIGN.md`. The readable raw evidence is archived at
`archive/railway-deployment-bundle/agent-runs.tar.gz`; its exact 304-member
inventory is `agent-runs-files.txt`.

An additional 112 older files existed only as macOS iCloud placeholders.
Their backing cloud objects no longer existed when cleanup was performed, so
they could not be included as recoverable bytes. The placeholders remain at
their relative paths under
`archive/railway-deployment-bundle/unavailable-run-placeholders/`, and their
metadata is indexed in `unavailable-cloud-placeholders.tsv`.

## Final verification

Version 33 passed:

- 474/474 pre-existing Linux tests;
- 24/24 focused Linux deployment-plan tests;
- 24/24 cargo-fallback focused tests; and
- the intentional test-only diagnostic lane with one classified failure and
  zero skips.

The accepted package also cleared patch-order, patch-reversal,
false-positive, harness-integrity, and implementation-fairness checks recorded
in `DESIGN.md` and `FALSE_POSITIVE_AUDIT.md`.
