# Design review feedback

Reviewed: 2026-07-23

**Historical verdict: resolved and approved on re-review. The design proceeded
through implementation and calibration, but the candidate was later abandoned
for environment unsuitability. This file no longer authorizes a next phase.**

## Re-review resolution

- Missing destination parents are now handled from the nearest pre-existing
  directory ancestor. Creation is deferred until publication, ownership is
  recorded per directory, and failed publication removes only invocation-created
  empty directories. T9 covers nested success and deterministic late-failure
  residue.
- The implementation-coupled filesystem monkeypatch cases were removed. T9 and
  T10 now use black-box filesystem states, and backup-restoration mechanics are
  no longer presented as an untestable normative hidden-test clause.
- The double-failure state is explicitly outside the public atomicity guarantee.
  A failed restoration retains the sole original in the publish workspace for
  operator recovery, so cleanup cannot silently destroy it.

The revised clause/test ledger is symmetric and the 194-line estimate fits the
active 150–200-line authoring target. The existing Linux lifecycle repeat remains
a mandatory later gate; a nondeterministic cleanup result reopens this review.

## Resolved findings

### 1. Preserve support for missing destination parents

The proposed publish workspace is created with `mkdtemp` directly in the logical
destination's parent. That parent may not exist. The current directory and
package targets create missing parent directories, so an output such as
`/existing/new/nested/out.3tz` currently works but the proposed transaction
would fail before the pipeline starts.

Revise the path/state design to cover a destination with one or more absent
ancestors while keeping final staging on the destination filesystem. Identify
which ancestor owns the workspace, when missing destination parents are created,
which of those paths are invocation-owned, and how they are removed after a
processing or publication failure. Add a behavioral case for a nested absent
parent to the clause/test ledger; its nearest pre-existing ancestor must have no
residue after failure.

### 2. Make the publication-failure oracle implementation-independent

T9 and T10 say the fault is selected by the public destination, but the design
does not identify a deterministic public action that produces a failure between
backup and publication or during cleanup. Monkeypatching a particular Node
filesystem function would constrain a correct solver to `renameSync`,
`fs.promises.rename`, or another private implementation choice. Path-based
selection alone does not remove that coupling.

Specify a reproducible black-box filesystem setup that triggers each failure
through `executePipeline`, independent of the filesystem API and call sequence a
solution uses. If no such setup exists, remove or narrow the combined-fault test
and its normative clause rather than testing a private implementation. Keep the
ordinary rollback guarantee covered through observable destination state.

### 3. Reconcile restoration failure with the public guarantee

H2 says every failure restores an existing destination exactly, while the state
machine allows restoration itself to fail and retain the only copy inside the
private workspace. In that state the destination is not restored, and deleting
the workspace would lose the original.

State the precise externally observable guarantee for restoration failure and
the cleanup ownership of the retained backup. The problem description and tests
must not promise stronger behavior than the implementation can provide.

## Evidence already accepted

The logical mapping for directory, custom-JSON, 3TZ, and 3DTILES output is
otherwise coherent. Directory seeding preserves the existing merge semantics,
same-input/output staging is architecturally sound, and the late GLB failure is
a useful real-backend feasibility probe. Repeat that probe in the supported
offline Linux image at the gate already recorded in the design.
