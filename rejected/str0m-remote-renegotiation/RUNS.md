# Solver runs - failure-atomic remote offers

Status: closed and archived on 2026-07-27 after the immutable L3 package
calibrated at 10 legitimate solves in 10 runs.

All runs used the artifact identifiers below, passed the 31 neighboring SDP
tests and all six challenge tests, and received `PASS_LEGITIMATE`. Every solver
implemented validation before mutation in `src/change/sdp.rs`; no near-pass or
broad failure exists for this version.

| Run | Verdict | Agent steps | Production logic changed | Files and approach |
|---|---|---:|---:|---|
| Nova 1 | legitimate pass | 76 | 133 lines | `src/change/sdp.rs`; complete ICE, fingerprint, SCTP, and media preflight |
| Nova 2 | legitimate pass | 54 | 107 lines | `src/change/sdp.rs` plus two existing tests; session preflight |
| Nova 3 | legitimate pass | 44 | 147 lines | `src/change/sdp.rs`; complete offer/session validation |
| Nova 4 | legitimate pass | 56 | 132 lines | `src/change/sdp.rs`; validation followed by infallible commit |
| Nova 5 | legitimate pass | 45 | 126 lines | `src/change/sdp.rs`; ICE/SCTP/media preflight |
| Nova 6 | legitimate pass | 50 | 113 lines | `src/change/sdp.rs`; remote-offer and session validation |
| Nova 7 | legitimate pass | 51 | 131 lines | `src/change/sdp.rs`; offer/session/SCTP preflight |
| Nova 8 | legitimate pass | 51 | 128 lines | `src/change/sdp.rs`; complete preflight with shared order errors |
| Nova 9 | legitimate pass | 54 | 134 lines | `src/change/sdp.rs`; remote-offer and media-layout validation |
| Nova 10 | legitimate pass | 55 | 97 lines | `src/change/sdp.rs`; minimal complete preflight found by step 19 |

“Production logic changed” counts additions and deletions before
`src/change/sdp.rs`'s test module, excluding the regression tests solvers added
inside that production file. The range is 97–147 lines, and every solution is
centered in one production file.

## Calibration verdict

The target acceptance band is one through four solves in ten runs. This version
reached the mandatory hard stop at its fifth consecutive solve and ultimately
finished 10/10. More offer-side fixtures cannot fairly reject the ten complete
solutions, so the problem is archived rather than hardened.

Raw evidence is preserved at:

- archive:
  `archive/str0m-remote-renegotiation/agent-runs.tar.gz`
- SHA-256:
  `0d8bde979aa4a54fc52483f7a03826baf87541cb8b2337b2a04ddfddaf7eff0c`
- restore:
  `tar -xzf archive/str0m-remote-renegotiation/agent-runs.tar.gz -C problems/str0m-remote-renegotiation`

## Immutable artifact identifiers

- `meta.md`:
  `c59f5a12c9b3bc42deeb015263cea59fce06c53236ff8370a8feb36a1c27431c`
- `test.patch`:
  `06351f1c862e1868ff3f89643e6ec1b59aebd212779e29aa8e7790eb474ffe21`
- `solution.patch`:
  `f43666f50dfc101f3b3b33cebd04df2a6b9e5237844aa672c6cd5d4e8ec2d413`
- `Dockerfile`:
  `69f599d152c11436e019a47bd50b08f36d7e09eee96fda5b6ca290db2c90973a`

These identifiers remain historical evidence only. Do not continue this batch
or mix any redesigned artifact into its results.
