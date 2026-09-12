# Design review feedback

Reviewed: 2026-07-23

Verdict: resolved by rejecting the candidate at the design gate. Do not create
`meta.md`, challenge tests, patches, a Dockerfile, or calibration runs for this
task unless a later design review explicitly reopens it.

## Re-review resolution

- The prototype is now measured at 100 raw additions, 85 nonblank/non-comment
  additions, and 72 strict effective implementation lines after excluding the
  public method docstring. That is materially below the active 150–200-line
  authoring target as well as the more conservative long-horizon criterion in
  the local calibration record.
- The design correctly declines padding and unrelated scope. The obvious larger
  expansions—atomic multi-instance replacement, UID swaps, orphan recovery, or
  PRIVATE reconstruction—would change the task identity.
- The rollback oracle now anchors its exact temporary directory through an
  unrelated publicly staged `FileInstance.path`; it no longer relies on a
  process-wide temporary-directory census or private stage keys.
- The source/probe status and exact regression command are now stated accurately.
  Re-review reran that command and all 153 FileSet tests passed.

The feature remains useful and technically coherent, so retain this folder as
repository research. Its measured scope makes it unsuitable for the current
task rather than incorrect as a pydicom design.

## Resolved findings

### 1. Reconcile the measured solution with the scope target

The design calls the production-size gate satisfied after measuring 100 added
and 6 removed raw lines in `src/pydicom/fileset.py`. Raw additions are an upper
bound on effective implementation lines, so this does not establish the stated
150–200 effective-line target. Documentation and tests do not count toward that
target.

Record an effective-line count for the prototype and check the current platform
submission criterion. If the task is materially below the active bar, either add
one natural, maintainer-shaped interaction that strengthens the same replacement
capability and both discriminators, or reject the candidate. Do not pad the
implementation or add an unrelated checklist feature. Update the requirement,
test, and mutation ledgers if the public scope changes.

### 2. Define a deterministic public temporary-file oracle

The rollback plan says tests may inventory the temporary directory containing
`FileInstance.path`, but a failed `replace()` returns no replacement instance
from which that directory can be discovered. Inventorying the process-wide OS
temporary directory is not deterministic and may observe unrelated activity;
reading the private stage dictionary would violate the behavior-only rule.

Specify a public setup that provides a stable staging-directory anchor before
the failing call, such as an independently staged public instance whose `path`
is exposed. The before/after inventory must be confined to that exact directory
and must not assert UUID names or private keys. Otherwise drop the temporary-file
inventory assertion and prove rollback through the other public state oracles.

### 3. Correct the prototype evidence wording

The audit section says both worktrees are clean while the prototype section
correctly depends on a modified probe worktree. Distinguish the clean pinned
`source` worktree from the intentionally modified disposable `probe`, record the
exact prototype diff, and state the reproducible test command. During this
review, `PYTHONPATH=src .venv/bin/python -B -m pytest tests/test_fileset.py -q
-p no:cacheprovider` passed all 153 tests.

## Evidence already accepted

The ownership/private-record precedence, pre-mutation snapshot, list/tree
exchange, same-UID behavior, both publication modes, and copy isolation fit the
existing `FileSet` architecture. The prototype diff also preserves all 153
upstream FileSet tests under the explicit source-path command above. This review
does not modify the prototype implementation.
