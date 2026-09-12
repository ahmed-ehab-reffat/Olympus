# h5py VDS reconstruction and relocation archive

The platform accepted this problem on 2026-08-10. Acceptance is a
user-confirmed platform outcome. Canonical submission artifacts and compact
design/history records remain in `problems/h5py-vds-copy-relocation/`; this
directory preserves the uploaded raw solver bundles and preliminary candidate
records.

## Raw solver evidence

| Archive | Historical version | Members | SHA-256 |
|---|---|---:|---|
| `agent-runs1.zip` | initial copy-relocation calibration | 45 | `ce2d39bb77a14c5b1100fea6751cb41e57a338e8eef27cfa58fe2bf7cb98f989` |
| `agent-runs3.zip` | review-corrected copy-only calibration | 90 | `8d4138a6fd86299c1c0f6538d9f6005b8bd34f80a096703eb1efb42de94c9fa7` |

Both archives pass `unzip -t`. Their readable directory mirrors remain in the
live problem folder, so acceptance closeout did not delete solver evidence.
The compact interpretation is in the live `RUNS.md` and `DESIGN.md` records.

Restore a bundle from the Olympus workspace root with, for example:

```sh
unzip archive/h5py-vds-copy-relocation/agent-runs3.zip \
  -d problems/h5py-vds-copy-relocation
```

## Preliminary candidate records

| Artifact | SHA-256 |
|---|---|
| `candidate-records/DESIGN.md` | `17d83f5ca3dbf3c2adb2fd01f4e26ab9f24352546b36f06a781edcef6ff7a9af` |
| `candidate-records/PLAN.md` | `8c9a0147c392ec14a85dfad29be928e5a4674736e93d6386cb042293f9b99f84` |
| `candidate-records/SUMMARY.md` | `102d0a0fe999bec0cba0c0f3b5dc7a1401f6f15a435a3ec0be5e0806e0e6763b` |
| `candidate-records/UPSTREAM_AUDIT.md` | `f39a794c7e5589f06b5c40fe8d475d8664530db079a97183b8f924fa97aeffca` |

These files moved from the active candidate namespace without content changes.

## Canonical accepted artifacts

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `34e302790597695901fe26db04bf210aed995e5ac972f5f0462a733722e5af72` |
| `test.patch` | `aa79f055fceafbce32c9cd8b42965da64247b4ccd4346c1e852d237c0a5783cf` |
| `solution.patch` | `3e23b41bc59915c3da584cb261d4bfd60cebe7597832c53416e54830c0afa4f0` |
| `Dockerfile` | `c16323de8d648c33ca71130a59b978bb81de1ecdead2f6ea04620a077e4c5af7` |
| `solution_approach.md` | `0f6843030e18769865bb48eb188cb5d5fc42b2e9fea23525f1d365110782e2f0` |

Acceptance freezes these identities. Closeout changes only status/history
records and evidence placement.
