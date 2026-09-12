# Salsa persisted accumulator outputs

Status: **rejected as previously implemented; archived 2026-08-15**

Repository: `salsa-rs/salsa`

Pinned commit: `81496d19d42c9d6f4bab876d1f2ac9941ec8992f`

Production language: Rust

Task type: enhancement

The task extends Salsa's opt-in persistent query cache to its typed
side-channel accumulator outputs. It spans accumulator macro options,
generated default and custom codecs, erased value storage, query-revision
serialization, transitive caller/callee reachability, and restored cache access
without query execution. Ordinary accumulators retain their existing no-serde
boundary, and non-persisted producer behavior and serialized byte layout remain
outside the new contract.

No prior Salsa problem trajectory exists locally. The startup gate instead
reviewed the exact upstream TODO/history and representative persistence and
reachability trajectories from Calyx, SQLSync, and RMK. The resulting
discriminator ledger is recorded in `DESIGN.md`.

The reference changes 11 production/manifest files with 235 additions and 28
deletions. The additive hidden patch creates one real nextest node whose
temporary consumer exercises default and custom codecs, two accumulator types,
duplicates, an unused persisted type, an ordinary non-serde type, direct
restoration, and transitive restoration. The transitive case runs first to
prevent prior global type registration from masking an invalid restored-child
implementation.

Exact verification is complete:

- pristine Phase A: formatting, normal and persistence clippy, 290/290
  persistence/default tests, 19/19 macros-only tests, and doctests pass;
- evaluator composition: pristine base 7/7 and focused 0/1; reference base 7/7
  and focused 1/1 with matching real JUnit testcase identity;
- complete reference: 291/291 persistence/default tests including the focused
  node, 19/19 macros-only tests, both clippy lanes, formatting, and doctests;
- seven isolated plausible mutants each pass the existing 7/7 lane and fail the
  focused consumer at the intended map, reachability, restored-child, codec,
  opt-in, multiplicity, or type-separation boundary; and
- environment, gap, fairness, and false-positive verdicts are all `pass` for
  the frozen hashes.

The user reported that the idea was rejected because it had been implemented
before. That external disposition overrides the otherwise passing local
package. Calibration stopped at 0/10. The artifacts are retained only as
rejection evidence; do not submit, reword, or harden this persisted-accumulator
task. Reconsider Salsa only through a materially different subsystem after a
fresh prior-implementation audit.
