# RMK portable configuration snapshot run index

## Outcome

Canonical version 56 was accepted on 2026-08-05. The acceptance is
user-confirmed. It does not turn the unmeasured version-56 package into a local
10-run calibration result, and it does not retroactively supply the exact-
version false-positive audit that the operator instructed us to skip.

Accepted identities:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `bba03fcbb15d7f2194834a0e3e62e86f06db43d473c6c976faa65fb51116f63b` |
| `test.patch` | `21f7cbaea27cee217f6a940e7628b9f0447f3e5ba9381bfcf46256c5ac59cae0` |
| `solution.patch` | `7f443935c8abecf9d695704d58f13128874679236e455c6a70ac7b7f05a2e7dd` |
| `solution_approach.md` | `bf40d0c673cff40bc2fa99fb730127ee4610ad5748f3378c2e7daf69e6cc31ee` |
| `Dockerfile` | `843abae0f216afdeee6bda1d0f53e02f1ed68231202df7fb96bec5bebd1d7be0` |

## Raw batches

| Batch | Historical role or measured result |
|---|---|
| `agent-runs1` | Four infrastructure-invalid locked-Cargo trajectories; implementation evidence only |
| `agent-runs2` | Four version-16 trajectories; three legitimate passes and one empty-macro WASM failure before version-17 replay |
| `agent-runs3` | Four legitimate passes that established a roughly 588-line production median and motivated extent hardening |
| `agent-runs4` | Four legitimate passes that motivated complete staged write-failure coverage |
| `agent-runs5` | Four legitimate passes that motivated sparse whole-device baseline restore |
| `agent-runs6` | Four legitimate version-23 passes that exposed whole-stage rewrite convergence |
| `agent-runs7` | Version 26: 0/5, all five failures caused by harness overconstraint |
| `agent-runs8` | Version 31: 4/5 |
| `agent-runs9` | Version 36: 8/10; version-37 non-bulk export coverage reduced the replay to 6/10 |
| `agent-runs10` | Version 38: reported 5/10; one failure was a harness fault, giving 6/10 after repair |
| `agent-runs11` | Version 40: 5/5 |
| `agent-runs12` | Version 43: 3/10 |
| `agent-runs13` | Version 45: 3/10, or 2/10 after the version-46 false positive was closed |
| `agent-runs14` | Duplicate delivery of the version-49 batch represented by `agent-runs15`; not a second measurement |
| `agent-runs15` | Version 49: 9/10 |

Versions 51 through 56 were abandoned or accepted without a new solver batch.
The detailed version mapping, representative implementations, fairness repairs,
and discriminator decisions remain in `DESIGN.md`, `LEVELS.md`, and
`HANDOFF.md`.

The 806 readable raw files, all available source ZIPs, and estimate records are
archived at
`archive/rmk-portable-configuration-snapshot/agent-runs.tar.gz`; their exact
inventory is `agent-runs-files.txt`. The `agent-runs14` and `agent-runs15`
extracted payloads are substantively identical after excluding `.DS_Store`,
although their original ZIP bytes differ and are both retained.

## Final verification

Exact version 56 passed:

- 83/83 pre-existing Rynk tests on arm64 and amd64;
- 41/41 focused snapshot tests on arm64 and amd64;
- alloc-without-`std` and Node/WASM subprocess checks;
- arbitrary UID/GID 42424 execution with networking disabled; and
- patch application, executable-mode, shell-syntax, JUnit-identity, and
  wrapper startup-classification checks.

The exact-version false-positive audit and a fresh solver calibration batch
were skipped at the user's direction. Platform acceptance is recorded as the
outcome; no local result is invented to fill those intentionally absent gates.
