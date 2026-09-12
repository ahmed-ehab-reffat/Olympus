# Known issues - failure-atomic remote offers

Status: terminal archive record, 2026-07-27.

## Decisive calibration failure

The immutable L3 package solved 10/10. Every result was `PASS_LEGITIMATE`, and
every implementation converged on complete offer preflight in
`src/change/sdp.rs`. The acceptance band requires one through four solves.

The successful production logic outside added in-file tests changed 97–147
lines and remained centered in one production file. This confirms both the
too-easy result and the pre-existing long-horizon scope concern.

There is no fair offer-side hardening survivor. Candidate, extension, stream,
fingerprint, event, ICE, media, and SNAP permutations are already absorbed by
the same correct validation-before-commit architecture.

## Historical environment issue

Before calibration, the local Docker daemon hung while starting the official
Rust 1.85 container, so the clean offline image gate was never certified.
Platform wrapper runs subsequently compiled and executed all 31 neighboring
tests and six challenge tests successfully, but that does not rescue the
calibration failure.

## Closure rule

Do not continue solver runs, add symmetric offer fixtures, or broaden this
package into `accept_answer`. A future str0m task must start from a materially
different repository-backed invariant with a fresh problem folder, trajectory
gate, false-positive audit, verification cycle, and 0/10 batch.

Raw runs and worktree recovery are recorded in
`archive/str0m-remote-renegotiation/`.
