# SUMMARY - h5py VDS reconstruction and relocation

**Status: accepted by the platform and archived on 2026-08-10.**

## Canonical artifacts

| Artifact | Current fact |
|---|---|
| `meta.md` | layout reconstruction/relocation plus copy integration; SHA-256 `34e302790597695901fe26db04bf210aed995e5ac972f5f0462a733722e5af72` |
| `test.patch` | 41 focused entities plus 138 selected regressions; SHA-256 `aa79f055fceafbce32c9cd8b42965da64247b4ccd4346c1e852d237c0a5783cf` |
| `solution.patch` | 2 production files, 249 local effective additions, public docs; SHA-256 `3e23b41bc59915c3da584cb261d4bfd60cebe7597832c53416e54830c0afa4f0` |
| `Dockerfile` | unchanged pinned editable build; SHA-256 `c16323de8d648c33ca71130a59b978bb81de1ecdead2f6ea04620a077e4c5af7` |

## Exact verification

| Gate | Result |
|---|---|
| Test-only | 138 base pass; all 41 focused entities fail/error |
| Solution-only | 138 base pass |
| Both patch orders | 138 base + 41 focused pass |
| Out-of-tree pytest | 41/41 |
| Complete pre-existing suite | 842 passed, 60 skipped, 3 subtests passed offline as `nobody` |
| Exception-taxonomy positive control | 41/41 with `RuntimeError` rejection paths |
| False-positive audit | 44/44 active mutants killed |
| Prior-solver replay | old best 29/41; no old patch implements the new layout surface |
| Rebuilt image | `sha256:f093210f23730cf9fc3c2f15606ceb30c20dc059308578521c9bce5898db8a4c` |

## Decision

The redesign is a coherent VDS round-trip feature rather than verifier padding:
callers can reconstruct, extend, reuse, and independently retarget a reopened
layout, while `Group.copy` consumes the same semantics atomically. The
reference changes `h5py/_hl/vds.py` and `h5py/_hl/group.py`; its 249-local
effective additions conservatively forecast about 227 under the prior platform
counter ratio.

The platform accepted this exact artifact on 2026-08-10. The four submission
files retain the hashes above. The earlier redesigned-version calibration state
remains historically 0/10 because no cold redesign solver was run; acceptance
is the user-confirmed outcome and no further calibration is required. Raw run
bundles and preliminary candidate records are preserved under
`archive/h5py-vds-copy-relocation/`.
