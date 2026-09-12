# RMK portable configuration snapshot archive

The RMK portable configuration snapshot problem was accepted on 2026-08-05.
Acceptance is user-confirmed platform outcome. Canonical submission artifacts
and compact design records remain in
`problems/rmk-portable-configuration-snapshot/`; this directory holds bulky
run evidence and cleanup records removed from the active problem folder.

## Contents

| Artifact | Contents | SHA-256 |
|---|---|---|
| `agent-runs.tar.gz` | 806 readable files from `agent-runs1` through `agent-runs15`, their available source ZIPs, and `estimate_trajectories` | `a24dbe5e752ed6690a24cb947fb1beeedbc2aae783a74e3f18b1f5b8e2f23f21` |
| `agent-runs-files.txt` | Exact file-member list for `agent-runs.tar.gz` | `ee03cec9b6a9058faaec8a6b4a33abfe56ada8ca7ac8af1c40cf63c9f9c7c6d7` |
| `verification-evidence.tar.gz` | 43 unique temporary logs, XML reports, historical patches, and the fairness mutation script | `9e75f2c51422c5fbfcef50946f0eca1c5249d64e996313d43225bd8d88e40edf` |
| `verification-evidence-files.txt` | Exact member list for `verification-evidence.tar.gz` | `069e4917af205d34c2c983142ecc15d2c5d02011e4bce6cf76f48fc783e02cd2` |
| `cleanup-inventory.tsv` | Exact pre-cleanup size, revision, dirty-count, and kind inventory for 47 generated directories and checkouts | `85cc7ab7e82478186003c579c98a4c29cd6dac8b34cbee758c349e9fd38e7656` |
| `docker-images.tsv` | All 72 removed `olympus-rmk-snapshot:*` tags, including their four shared image IDs | `27937020ba8fb4ab4da5bc1eb403e4ba444bc5ac77b17821caa9543b0a805d10` |
| `WORKTREE_MANIFEST.md` | Checkout disposition and reconstruction instructions | recorded in this archive |

Both compressed archives passed `gzip -t`. Their listed file members were
sorted and compared byte-for-byte with independently generated source member
lists before cleanup. Apple `.DS_Store` metadata was deliberately excluded.
The `agent-runs14` and `agent-runs15` extracted trees differ only in that
metadata; both original ZIPs remain in the raw archive because their container
bytes are not identical.

## Cleanup disposition

The 72 recorded `olympus-rmk-snapshot:*` Docker tags and their four shared
image IDs were removed after the inventory was written. A post-cleanup Docker
query returned no matching tags.

Generated registered child worktrees were removed with `git worktree remove
--force`; they are reconstructible from the accepted pin and archived patches.
The raw run folders, standalone temporary checkouts, small verification files,
and the owning workspace checkout were moved to the recoverable macOS Trash
namespace
`/Users/andrewemad/.Trash/Olympus-rmk-snapshot-cleanup-20260805` rather than
permanently erased. That recovery tree measured 12 GiB immediately after the
move. The live problem directory and `/private/tmp` no longer contain the
inventoried RMK snapshot trees.

## Canonical accepted artifacts

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `bba03fcbb15d7f2194834a0e3e62e86f06db43d473c6c976faa65fb51116f63b` |
| `test.patch` | `21f7cbaea27cee217f6a940e7628b9f0447f3e5ba9381bfcf46256c5ac59cae0` |
| `solution.patch` | `7f443935c8abecf9d695704d58f13128874679236e455c6a70ac7b7f05a2e7dd` |
| `solution_approach.md` | `bf40d0c673cff40bc2fa99fb730127ee4610ad5748f3378c2e7daf69e6cc31ee` |
| `Dockerfile` | `843abae0f216afdeee6bda1d0f53e02f1ed68231202df7fb96bec5bebd1d7be0` |

The accepted base revision is
`c94426a68779e61cecc4380e21e9079e0ef0c2ae`.

## Restore

From the Olympus workspace root:

```sh
tar -xzf archive/rmk-portable-configuration-snapshot/agent-runs.tar.gz \
  -C problems/rmk-portable-configuration-snapshot
```

Temporary verification evidence can be inspected without extraction using
`tar -tzf`, or restored into a dedicated scratch directory. The compact run
interpretation remains in `RUNS.md`, `LEVELS.md`, and `DESIGN.md`; raw restore
is unnecessary for ordinary review.
