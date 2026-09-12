# Candidate summary - Afero copy-on-write namespace mutations

Status: **rejected as previously implemented; archived 2026-08-15**.

Repository: `spf13/afero`.

Pin: `768f1fb0e5535b77d90e44c531aacd652aabd96a`.

Production language: Go.

Task type: enhancement.

Preliminary rating: **8/10**.

The seed would make `CopyOnWriteFs` support logical removal, recursive removal,
and rename across base-only, layer-only, and merged entries without mutating the
base. The substantive boundaries are exact whiteouts, opaque subtree
recreation, complete merged-tree relocation, destination replacement, staged
failure behavior, path identity, and state carried through repeated renames.

Eligibility and ownership are positive. The repository is public, active,
Apache-2.0, Go-primary, has 6,687 stars, a small root dependency graph, and a
real core suite. Exact all-state searches found no issue, PR, branch, historical
implementation, release item, or Discussion owning whiteouts or base-backed
namespace mutation.

The trajectory gate compared compact wazero and umoci filesystem records and
inspected archived PcapPlusPlus raw pass, near-pass, and broad-failure evidence.
It produced a discriminator ledger in `DESIGN.md`; no test or prototype was
started first.

Pristine Phase A passed in the approved image with networking disabled and
UID/GID 20002. Both image-copy and read-only-checkout layouts passed the root
build, compile-only discovery, and all 176 JUnit cases with one skip.

Independent complete prototypes resolve the size risk. Eager logical-tree
materialization changes two production files at 433 strict effective additions;
lazy base-path redirection changes two at 503. Both pass the same memory- and
OS-backed behavioral suite, deterministic failure rollback, and the complete
187-case offline JUnit lane.

Cross-layer symlink relocation was removed from scope because Afero's optional
interfaces do not define a portable target representation across independent
`BasePathFs` roots. The remaining regular-file/directory task is promoted; the
stable problem record reports passing exact environment, gap, fairness, and
false-positive gates. No solver run or calibration batch exists.

The user subsequently reported that someone else had already implemented the
task. That external outcome overrides the earlier local novelty verdict. The
exact task is terminal at 0/10 calibration and must not be resubmitted,
reworded, or cosmetically hardened.
