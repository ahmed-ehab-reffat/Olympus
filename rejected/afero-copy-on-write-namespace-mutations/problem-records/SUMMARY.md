# SUMMARY - Afero copy-on-write namespace mutations

Status: **rejected as previously implemented; archived 2026-08-15; calibration closed at 0/10**.

Repository: `spf13/afero`.

Pin: `768f1fb0e5535b77d90e44c531aacd652aabd96a`.

Production language: Go.

Task type: enhancement.

The task completes namespace mutation in `CopyOnWriteFs` for regular files and
directories: exact removal hiding, opaque subtree recreation, merged-tree
rename, destination replacement, state relocation through repeated renames,
path normalization, and failure-safe public views while the base stays
unchanged.

Eligibility, ownership, local-history, trajectory, and pristine environment
gates pass. Two complete architectures pass the same memory/OS-backed probe and
complete offline suite: eager materialization at 433 strict effective
production additions and lazy base-path redirection at 503.

The final exact evaluator passes offline as UID/GID 10001. Pristine fails all
7 focused tests behaviorally; both complete architectures pass 176/176
pre-existing cases with one skip and 7/7 focused cases. Gap and fairness audits
pass. Ten isolated actionable mutants are killed; two full-suite survivors are
recorded as observationally equivalent private-state choices rather than false
positives.

Cross-layer symlink relocation, durable reconstruction from the layer, and
concurrent namespace mutations are explicitly outside scope. No solver run or
calibration result exists. Before the external rejection, the next planned
stage was the calibration strategy's local frontier pre-filter.

The user subsequently reported that someone else had already implemented the
task. That external disposition overrides the otherwise passing local package.
The implementation identity was not supplied, so the archive preserves the
earlier ownership search without inventing provenance. This exact task is
terminal: do not calibrate, submit, reword, or cosmetically harden it.
