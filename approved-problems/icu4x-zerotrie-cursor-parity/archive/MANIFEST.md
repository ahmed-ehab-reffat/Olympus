# ICU4X ZeroTrie cursor parity archive

Status: **accepted and archived 2026-08-17; user-confirmed platform success**.

The canonical accepted package and compact design records remain under
`problems/icu4x-zerotrie-cursor-parity/`. This archive contains raw solver
bundles, task-scoped recovery material, verification diagnostics, and the
cleanup inventory.

## Canonical accepted artifacts

Repository: `unicode-org/icu4x`

Pinned commit: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `4ee0a417a12d6e2dc89d3a74225b625699a631367b99ed95daf03f82c61f195d` |
| `test.patch` | `1f434f99cc7735f9b1fa3bd0a665868626a98e1a9d085b80cca0e93accff27db` |
| `solution.patch` | `8c57616dca3cd605da4ae12fd408ed378e8190c594f525904f862ac720326b04` |
| `Dockerfile` | `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb` |
| `ENVIRONMENT_REPLAYS.sha256` | `64091afc6de600a35fc8b0245b0b7659b3f726ca5e4d463fff7753fde792d75d` |

Acceptance does not change these frozen identities. The accepted Level 17
reference passes 60/60 existing and 16/16 focused tests. No fresh Level 17
solver batch was run; the 0/10 fresh-calibration count and 1-3/10 forecast in
the compact records remain historical rather than acceptance criteria.

## Preserved evidence

- `agent-runs1.zip` through `agent-runs11.zip` are the eleven raw calibration
  bundles. Every ZIP passed `unzip -t`; independent extraction and recursive
  comparison, excluding Finder metadata, proved byte parity with all 664
  readable source files. `agent-runs-hashes.tsv` records each bundle hash and
  file count.
- `verification-diagnostics.tar.gz` preserves 134 members from small report,
  result, fallback-JUnit, and exploratory directories.
- `verification-files.tar.gz` preserves 51 task-scoped top-level logs, patches,
  XML reports, and other verification files exactly as found.
  `temporary-files-inventory.tsv` records their source paths, sizes, hashes,
  and disposition.
- `recovery-patches/` contains 47 binary Git patches from dirty temporary
  checkouts. `recovery-untracked/` contains 17 gzip-verified archives of their
  untracked files. `recovery-index.tsv` maps all 48 dirty/untracked roots to
  the retained recovery material.
- `cleanup-inventory.tsv` records all 155 task-scoped temporary roots, their
  sizes, available Git heads, dirty/untracked counts, and disposition. They
  totaled 83,160,012 KiB before removal.
- `removed-active-files.tsv` records the eleven moved ZIPs, all duplicate
  extracted-run files, Finder metadata, and the empty candidate placeholder.
- `docker-resources.tsv` records that no task-owned container or image existed
  at closeout.

The cleanup skill's referenced `scripts/inventory.py` helper was not present in
this workspace. The equivalent inventory was therefore performed manually and
recorded in the tab-separated inventories above before any deletion.

The generated inventory files had these pre-closeout identities:

| Artifact | SHA-256 |
|---|---|
| `agent-runs-hashes.tsv` | `f12b877c94d782900bddcaf6dabd50d0a80ecfa9cc565a73f847d25ed2e94205` |
| `cleanup-inventory.tsv` | `d94691f1da974b1efa1c66859463df3771131a37f961b2dd9078a7bc75c6257f` |
| `recovery-index.tsv` | `65b2475546f02ac5baf1b4bb582ca37698263a35e7cde0f72b734bab756897bc` |
| `removed-active-files.tsv` | `5b884ea23eb8df7b4ecd044795ca27401aac75dee42a4c5f182632b471778046` |
| `docker-resources.tsv` | `0a262ff19e6dd102db2e17f25d18e18d5e3ca5599a6173d51c22d327378b6a00` |
| `verification-diagnostics.tar.gz` | `2db2e3bf7399147ea07cd1cb653d16a811af89d2fc5d390dde8ccc03684ec479` |
| `temporary-files-inventory.tsv` | `72fb8c6f8cf43fd0b8d1aa34fdfe8298cf41ddc88d7f9b71bef4a3e329fe6b53` |
| `verification-files.tar.gz` | `d98b06e2ea52be687c62d8f83ca7a4740da24d000a1a7cba537135e7eb13e351` |

## Cleanup disposition and recovery

The duplicate expanded run directories, 155 temporary checkout/build/report
roots, 51 top-level temporary verification files, root Finder metadata, and
empty candidate placeholder were removed only after the checks above.
Reproducible caches and byte-identical duplicates were permanently deleted;
they are not recoverable from Trash. The source checkouts can be reconstructed
from the recorded repository pins and accepted patches. Unique raw runs, small
diagnostics, dirty diffs, untracked files, and top-level verification files
remain recoverable from this archive.

Restore a raw batch from the Olympus root with, for example:

```sh
mkdir -p problems/icu4x-zerotrie-cursor-parity/agent-runs11
unzip archive/icu4x-zerotrie-cursor-parity/agent-runs11.zip \
  -d problems/icu4x-zerotrie-cursor-parity/agent-runs11
```

No shared Docker base, build cache, workspace, unrelated temporary path,
volume, or network was removed.
