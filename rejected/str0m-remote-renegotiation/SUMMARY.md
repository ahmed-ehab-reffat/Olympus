# Summary - failure-atomic remote SDP offers

Status: archived on 2026-07-27 after the immutable package calibrated at ten
legitimate solves in ten runs. The canonical artifacts remain locally verified
historical evidence, not a submission candidate.

| Field | Value |
|---|---|
| Repository | `algesten/str0m` |
| Base commit | `98d3b401e4fada626122b9846a5b4f9dd1d5d741` |
| Production language | Rust |
| Task type | bug fix |
| Public task | `meta.md` |
| Test patch | 3 files, 6 new tests in randomized integration target `sdp-rejected-offer-state_83efa2`, 31-test base mode |
| Solution patch | 1 production file, 155 insertions and 47 deletions |

## Behavior

Rejected remote offers are preflighted before ICE, fingerprint, DTLS, SCTP,
session, media, stream, or event state is changed. The existing change-ID
invalidation remains before preflight, so a remote offer still invalidates an
outstanding local pending offer.

## Local verification

| State | Check | Result |
|---|---|---|
| Pinned base + new test file | Six-test suite | Six failures, zero passes |
| Completed solution | `test.sh base` | 31 passed |
| Completed solution | `test.sh new` | 6 passed |
| Completed solution | Full offline `rust-crypto` suite | 638 library tests, all integrations, 56 doctests passed; 2 doctests ignored |
| Completed solution | Formatting and clippy | Passed |

Both solved-state harness modes emitted well-formed JUnit XML. Patch-only and
test-plus-solution gates are reproducible through `verify/gates.sh`, but have
not been certified inside the required image because Docker cannot currently
start it.

## Calibration and archive decision

All ten Nova runs passed legitimately. Each solver used the same
validation-before-commit seam in `src/change/sdp.rs`; no near-pass, broad
failure, or incorrect survivor exposed a fair additional discriminator. Solver
production logic outside in-file tests changed only 97–147 lines and remained
centered in one production file.

The package therefore fails the one-to-four-solves calibration band and the
multi-file long-horizon depth expectation. More offer fixtures would duplicate
existing failure families rather than harden the architecture. The problem is
closed and must receive no more runs.

Raw trajectories and dirty-worktree recovery are preserved under
`archive/str0m-remote-renegotiation/`. The canonical problem folder remains as
the compact design, package, and verification record.
