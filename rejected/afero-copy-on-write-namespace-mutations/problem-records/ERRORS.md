# ERRORS - Afero copy-on-write namespace mutations

## Resolved design risk

Cross-layer symlink rename was removed from scope. Independent `BasePathFs`
roots translate link targets through different private roots, so the optional
interfaces do not expose one portable target representation. Hidden tests must
not prescribe access to wrapper internals.

## Resolved verifier risks

An initial mode oracle incorrectly assumed the lower directory mode after an
upper child had already materialized that directory. It was replaced by the
logical mode observed immediately before rename.

The first exact-gate source was a promisor clone missing a required object. The
run stopped before Docker or tests and was quarantined. A complete non-promisor
clone at the same pin passes `git fsck --full`; the exact gate restarted from
Phase A and passed.

A destination-opacity mutant initially failed to compile because it also made
a local variable unused. That result was discarded. The mutant was corrected
to retain the variable while forcing only the target predicate, then compiled
and failed behaviorally as intended.

No exact-version environment, coverage, fairness, or false-positive issue
remains open.

## Terminal external rejection

The user reported that someone else had already implemented the task. The
specific implementation or rejection record was not supplied locally, so no
missing provenance is inferred. This outcome supersedes the earlier novelty
audit and closes calibration at 0/10.
