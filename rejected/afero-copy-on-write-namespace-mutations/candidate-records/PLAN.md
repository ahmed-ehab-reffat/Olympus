# Candidate plan - Afero copy-on-write namespace mutations

Status: `closed after prior-implementation rejection; archived 2026-08-15`.

Repository: `spf13/afero` at
`768f1fb0e5535b77d90e44c531aacd652aabd96a`.

Primary and proposed production language: Go.

Task type: enhancement.

## Seed

Make `CopyOnWriteFs` support ordinary logical `Remove`, `RemoveAll`, and
`Rename` behavior for base-only, layer-only, and merged entries while keeping
the base immutable. The complete behavior includes exact whiteouts, opaque
subtree recreation, merged-directory relocation, destination replacement,
failure-safe publication, and path identity for regular files/directories.

## Gate sequence

1. **Trajectory-informed design gate - complete.** The closest compact local
   records and archived PcapPlusPlus raw pass, near-pass, and broad failure were
   inspected. Evidence and the discriminator ledger are in `DESIGN.md`.
2. **Eligibility and ownership - preliminarily complete.** Current GitHub,
   source, all-branch history, issue/PR, release, and Discussion checks are in
   `UPSTREAM_AUDIT.md`. No exact implementation or owner was found.
3. **Environment Phase A - complete.** The untouched frozen checkout built from
   the approved general Olympus base. Root build, compile-only, and complete
   tests passed offline as UID/GID 20002 in both image-copy and read-only exact
   checkout layouts; the full JUnit lane reported 176 cases, zero failures or
   errors, and one skip.
4. **Independent complete prototypes - complete.** Eager materialization is
   433 strict effective production additions; lazy redirect journaling is 503.
   Both pass the shared memory/OS/failure probe and complete 187-case offline
   JUnit lane.
5. **Promotion decision - pass.** The architectures do not converge and do not
   require a marker encoding. Cross-layer symlink relocation was removed after
   the optional interfaces proved insufficiently portable.
6. **Submission authoring - complete.** The stable problem record and four
   submission artifacts were created from the recorded contract. Exact
   environment, gap, fairness, and false-positive gates pass for version 3.

## Stop conditions

- Phase A cannot build and run the untouched root suite offline as a non-root
  UID.
- An upstream issue, PR, branch, fork, or release implements or declines the
  same namespace behavior.
- Correct behavior requires exposing or prescribing a private whiteout filename
  or storage encoding.
- Backends cannot support one fair behavioral contract through the existing
  Afero interfaces.
- More than one independent complete prototype converges materially below the
  current long-horizon size criterion.
- The apparent depth reduces to filename variants of one exact tombstone check.

The user-reported prior implementation closes the task. Do not calibrate,
submit, reword, or harden this exact proposal. Reconsider Afero only through a
materially different subsystem after a fresh ownership audit.
