# pyelftools external DWARF rejection archive

Status: **rejected and archived on 2026-08-20**.

Failure reason: **overlap**.

Open pyelftools issue #186 gives the exact GNU build-ID separate-DWARF lookup
and invites a pull request. Merged PR #596 added sibling `.gnu_debuglink`
support but explicitly excluded build-ID linking. This external ownership
supersedes the preliminary novelty screen and closes the proposed external
DWARF resolver task. Do not resubmit, paraphrase, broaden, or revive the same
build-ID/debug-root behavior. Reconsider pyelftools only through a materially
different subsystem after a fresh startup and ownership gate.

## Preserved evidence

`problem-records/` contains the final design, rejection summary, and upstream
audit. `candidate-records/` preserves the preliminary candidate design and its
escalation correction. Their `RECORDS.sha256` files bind every preserved
record. No `meta.md`, `test.patch`, `solution.patch`, Dockerfile, hidden test,
reference implementation, environment run, mutation, solver run, or
calibration batch ever existed for this task.

Repository reconstruction information:

- URL: `https://github.com/eliben/pyelftools.git`
- pin: `e5fa2a4f3e665d082cfc453fd0877f5516200926`
- production language: Python
- evaluated task type: enhancement

## Cleanup scope

The read-only helper named by the cleanup skill was unavailable because
`scripts/inventory.py` does not exist in this workspace. Equivalent explicit
inspection found no task-owned Docker container or image, `.tmp-results`
entry, system temporary path, or remaining authoring checkout.
`cleanup-inventory.tsv` records the resolved inventory and
`docker-resources.tsv` records the zero-resource Docker result.

The clean source checkout used for the read-only ownership audit had already
been moved through macOS Trash during the rejection closeout. That removal is
recoverable until Trash is emptied; the checkout is also exactly reproducible
from the URL and pin above. No dirty worktree or unique untracked authoring
material existed.

The active problem and candidate records were moved into this archive without
an active duplicate. `cleanup-inventory-post.tsv` records the final absence
checks. Shared Docker bases, images, volumes, networks, build cache, and all
unrelated workspace state were left untouched.
