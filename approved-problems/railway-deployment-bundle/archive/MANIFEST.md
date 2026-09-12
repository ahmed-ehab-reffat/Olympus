# Railway deployment bundle archive

The Railway verified-deployment-plan problem was accepted on 2026-07-29.
Canonical submission and compact design records remain in
`problems/railway-deployment-bundle/`; this directory holds bulky or retired
working evidence removed from the active problem folder.

## Contents

| Artifact | Contents | SHA-256 |
|---|---|---|
| `agent-runs.tar.gz` | 304 readable files from `agent-runs` through `agent-runs11` | `98b72b6066cc0889e47c375524797a8fb27a6d3b29f6a5c894170faba831361c` |
| `agent-runs-files.txt` | Exact member list for `agent-runs.tar.gz` | `0652deb7402bf5576252e20d94fbea92ada1a52f1f2f60165634587cb509ed34` |
| `unavailable-run-placeholders/` | The 112 unresolved trajectory placeholders, preserved at their relative paths | indexed below |
| `unavailable-cloud-placeholders.tsv` | Metadata for 112 older iCloud placeholders whose backing objects no longer exist | `95ddf942554ac8a907577dd2a69d52cdbe0ae571044776603112d352cb4e8fe8` |
| `retired-cloud-placeholders/` | Six superseded prototype placeholders retained without claiming recoverable bytes | indexed below |
| `retired-artifact-inventory.tsv` | Metadata for six superseded prototype placeholders whose backing objects no longer exist | `28063b071f8474d0371c151ecfb504277f1b5968d2b3bc55702a2cd84545e096` |
| `WORKTREE_MANIFEST.md` | Pinned-worktree disposition and reconstruction instructions | recorded in this archive |

The readable run archive was verified by listing it and comparing all 304
members with the source inventory before cleanup. The unavailable placeholders
could not be downloaded with `brctl`: macOS reported that their cloud objects
did not exist. The placeholder files themselves remain under the two
`*-placeholders/` directories, and their paths, logical sizes, timestamps, and
flags are indexed without claiming that their bytes are recoverable.

## Canonical accepted artifacts

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `6674edbce3495a8d3dfba725ba769b0fa8a633cc94054f55bee2b4049799f8cd` |
| `test.patch` | `850fa6491c50eb0e021a03340108eaf250706c323f5c1af3f4a8ca6580617851` |
| `solution.patch` | `52cfd1502465ef484db613a95d0d41430a7a28da4ade565bac40d45108e7ac14` |
| `solution_approach.md` | `cd54d38e8ce2f6c5256de0a595e90940d35124a7115601ee8a857761f84b14bc` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

## Restore

From the Olympus workspace root:

```sh
tar -xzf archive/railway-deployment-bundle/agent-runs.tar.gz \
  -C problems/railway-deployment-bundle
```

The compact trajectory interpretation remains in `RUNS.md`, `LEVELS.md`, and
`DESIGN.md`; restoring the raw archive is unnecessary for ordinary review.
