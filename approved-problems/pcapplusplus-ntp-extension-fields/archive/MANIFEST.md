# PcapPlusPlus NTP extension fields archive

The platform accepted this problem on 2026-08-06. Acceptance is a
user-confirmed platform outcome. Canonical submission artifacts and compact
design records remain in `problems/pcapplusplus-ntp-extension-fields/`; this
directory preserves bulky solver evidence, preliminary candidate records, and
small prototype recovery patches outside the active package.

## Raw solver evidence

- Archive: `agent-runs.zip`
- Runs: five Nova run directories
- Members: 45
- Compressed size: 4,328,032 bytes
- SHA-256:
  `ee4bfa466075f2bb515529f31381ee9e8a773793392df80a7dd599b8be6f52d6`
- Integrity: `unzip -t` reports no errors.

The compact interpretation remains in the live problem's `RUNS.md`,
`LEVELS.md`, and `DESIGN.md`. Inspect members without extraction with
`unzip -l archive/pcapplusplus-ntp-extension-fields/agent-runs.zip`.

## Preliminary candidate records

`candidate-records/` contains the screening `DESIGN.md` and `PLAN.md` moved
from `candidates/pcapplusplus-ntp-extension-fields/`. Their content hashes are
unchanged:

| Artifact | SHA-256 |
|---|---|
| `candidate-records/DESIGN.md` | `41a6342369047716aaafabd90d095a9edaeb01a536a9721e1ece0eb218e1bd35` |
| `candidate-records/PLAN.md` | `3ee7c79fcb2fee4945e15f6d6f52b7bae56872484ed67c50198d73ba0c7a93a2` |

## Prototype recovery

The disposable audit namespace held three distinct dirty probes and a
historical staging checkout. Their tracked changes are preserved as patches;
generated build trees and clean checkouts are reconstructible and are not
archived.

| Artifact | Base commit | SHA-256 |
|---|---|---|
| `prototype-recovery/mutation-audit.patch` | `84c418f09164682326746a407ea45a4c9b093e80` | `db9603261ab7c6906ebeee3a20ab8177cc48a2592751ef72270dfd9f00d18891` |
| `prototype-recovery/probe-alternate.patch` | `8ac4366c4184f096973ef4a0ca084559935828d0` | `c58c5af25b3310d04cb9fec68e85551a0cd47d5ea0d19345e661bb9fa65e944f` |
| `prototype-recovery/probe-minimal.patch` | `01a969f6bae66128f136fb7ce3067e26a227b071` | `fb6dbba06daad3b8928793d5c6996d27dbce22991970103f62ec8efb0a8a3394` |
| `prototype-recovery/problem-staging.patch` | `8ac4366c4184f096973ef4a0ca084559935828d0` | `fcd22c98b7225d09a100e649a74ab1021ba20fb50a8642e6c31968e50decd035` |

Each patch passed a reverse-application check against its source checkout before
cleanup. Apply a patch to a clean checkout of its recorded base to reconstruct
that tracked state.

## Canonical accepted artifacts

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `2f59b5167fd5d78f69733f1a79870e5e3eebd648f109293efbc740931239f640` |
| `test.patch` | `1e02096c742a2bba1fab1f3c7e259bd6859faf0a1d3bc7c01f4695e1443154ac` |
| `solution.patch` | `9ef741035f3910e2530b1e525525d44b7de213c625bf7d496d90393ff86024b3` |
| `solution_approach.md` | `b2caba5e720823798c2d8d070a3b598fa0eb20b30864cd0d1cdd6e5a67b1d50e` |
| `Dockerfile` | `e8298b6159f5505bb9293bfc47d3c957f6a74d8ffdc4cc93c40f3b5c2f0cded2` |

Acceptance freezes these identities. Closeout changes only compact
status/history records and evidence placement, not submission artifacts.

## Cleanup disposition

See `WORKTREE_MANIFEST.md` for the 2.7 GB audit namespace and
`docker-images.tsv` for the six retired Docker tags. Disposable Apple metadata
was excluded. The audit namespace was moved to recoverable macOS Trash only
after the prototype patches and raw solver ZIP passed integrity checks.
