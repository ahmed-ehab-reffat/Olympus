# SQLSync observed-sync-state archive

Archived: 2026-08-07

Disposition: accepted problem; canonical version 37 remains under
`problems/sqlsync-observed-sync-state/`.

## Retained active artifacts

The active problem directory keeps the canonical submission package and the
compact evidence needed to understand or reproduce it:

- `meta.md`, `test.patch`, `solution.patch`, `Dockerfile`, and
  `solution_approach.md`;
- `SUMMARY.md`, `LEVELS.md`, `ERRORS.md`, `DESIGN.md`, `RUNS.md`,
  `UPSTREAM_AUDIT.md`, and `PROTOTYPE.md`; and
- `verify/`.

`PROTOTYPE.md` and `UPSTREAM_AUDIT.md` remain active because they are small,
durable records of the cross-layer feasibility work and repository-ownership
screen. No second bounded SQLSync problem was found in the acceptance-time
follow-on audit.

## Cold archive contents

| Artifact | Purpose | SHA-256 |
|---|---|---|
| `agent-runs.tar.gz` | All 11 expanded trajectory batches, excluding Finder metadata | `97dc07473750f49ebfa94ccf4d6cf5969cac57744d7b08bc90f463395fc4322f` |
| `agent-runs-files.txt` | Complete tar member list; 616 regular files | `d3ca6cfbb32be936eed9c1d3d0a39369430f6390634033279305714470f50a10` |
| `retired-authoring.tar.gz` | Accepted-version `PLAN.md` and agent `handoff.md` | `7b8030853b47de33170d9f359b447b74c9721efbaff621490f2b21a6e9e5a8a7` |
| `retired-authoring-files.txt` | Retired-authoring member list | `138783c332e93e05c2882939005519fd2c1a44f28703101b52f3e49e517247c6` |
| `cleanup-inventory.tsv` | Pre-cleanup paths, sizes, duplicate ZIP hashes, and dispositions | `8b9aaa42f83337f8e39a64644ce3480e770f036ede7380e592b0292b338ac585` |
| `removed-active-files.txt` | Exact 637-file removal list plus the empty candidate-directory record | `6038985fdb1c81bc95f2c4de6e1cb80b0e646cbd4f062640d34dbf1adde11e74` |
| `docker-images.tsv` | SQLSync-specific Docker tags and immutable image IDs before removal | `e1dd2838ab8ffca2a64b2fece208410181d97c68efbc3057e3e6e87ae5a62df4` |
| `docker-containers.tsv` | Disposable no-mount SQLSync cache container that held the final old image tag | `ff058664c7f3c96523003972b9ee855b8911f72638b023ad3ed31339dd5ea203` |
| `WORKTREE_MANIFEST.md` | Source/worktree and reconstruction record | recorded alongside this manifest |
| `SHA256SUMS` | Checksums for every other archive file | self-excluded |

The archive was expanded into a temporary directory and every regular-file
SHA-256 was compared with the active source. Counts were 616 source files, 616
archive files, and 616 listed files. `gzip -t` passed for both compressed
archives. Each legacy `agent-runs5.zip` through `agent-runs11.zip` was separately
expanded and found content-identical to its corresponding active directory.

## Cleanup disposition

After archive verification, these active working copies were moved to the
recoverable macOS Trash location
`~/.Trash/Olympus-sqlsync-cleanup-20260807/`:

- expanded `agent-runs1` through `agent-runs11`;
- duplicate `agent-runs5.zip` through `agent-runs11.zip`;
- `PLAN.md` and `handoff.md`; and
- `.DS_Store` metadata and the empty candidate placeholder.

All Docker tags beginning `olympus-sqlsync-observed-base:` were inventoried in
`docker-images.tsv` before removal. The final shared image was held by a
three-day-old, no-mount container whose sole command was `tail -f /dev/null`;
its immutable details were recorded in `docker-containers.tsv` before the
container was stopped and removed. These are caches only; the Dockerfile,
source commit, package locks, and canonical patches remain sufficient to
rebuild the environment.

## Recovery

Restore raw evidence with:

```sh
tar -xzf archive/sqlsync-observed-sync-state/agent-runs.tar.gz \
  -C problems/sqlsync-observed-sync-state
```

Restore the retired authoring records with:

```sh
tar -xzf archive/sqlsync-observed-sync-state/retired-authoring.tar.gz \
  -C problems/sqlsync-observed-sync-state
```

The Trash copy is a second, temporary recovery path until the Trash is emptied.
