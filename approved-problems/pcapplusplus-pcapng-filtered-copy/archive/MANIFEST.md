# PcapPlusPlus section-aware PCAPNG filtered-copy archive

The platform accepted the exact L6 problem on 2026-08-01. Canonical submission
and compact design records remain in
`problems/pcapplusplus-pcapng-filtered-copy/`; this directory preserves bulky
solver evidence and preliminary screening records outside the active package.

## Raw solver evidence

- Archive: `agent-runs.tar.gz`
- Preserved roots: `estimate_trajectories`, `agent-runs1`, `agent-runs2`,
  `agent-runs3`, and `agent-runs4`
- File members: 161
- Exclusion: one disposable `.DS_Store` file
- Compressed size: 8,370,728 bytes
- SHA-256:
  `52ef73b17f831c9575c8801e8754fad10c0f4a8a5cfe582e83606305742fba2c`
- Ordered member-list SHA-256:
  `46fd929509be70276bb9444e4509bef4c9c70221a37affb1f90ef7aa3f811e37`

The archive passed `gzip -t`. A disposable full extraction was compared with
all five readable source roots using recursive byte comparisons; all 161 files
matched. The four uploaded ZIP bundles were also checked member by member
against the readable run directories. Every ZIP member matched; the only extra
readable file was `.DS_Store`, so the ZIPs are redundant rather than unique
evidence.

Restore the raw evidence from the Olympus workspace root with:

```sh
tar -xzf archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz \
  -C problems/pcapplusplus-pcapng-filtered-copy
```

The raw directories may remain as ignored local working copies until disk
cleanup is desired. `RUNS.md` is the compact navigation and interpretation
record; a clean clone needs only this archive for full recovery.

## Preliminary candidate record

`candidate-records/` contains the nine screening and promotion documents moved
from `candidates/pcapplusplus-pcapng-filtered-copy/`. Their content hashes are
unchanged. They preserve the initial 178-line size-risk assessment and the plan
that authorized an unpadded solver experiment without leaving an accepted
problem in the active candidate namespace.

## Canonical accepted artifacts

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `d527f61ce418cd97a765c3b2705961db1b76b6e6beddeae1f358ef114392630e` |
| `test.patch` | `00d7213a423facc6ca47b43d2ba5eb2f5365e303eac9e1a45ae002c26d54cfe8` |
| `solution.patch` | `1f228c09ddab23d64d57791964c8f33008565560cc84fc56e686b4cf3ab514bf` |
| `solution_approach.md` | `c00e34a724b0e84f362ed59bacb31150e9f26c6c020c1f9bd52fc79921a3d87b` |
| `Dockerfile` | `70e8b8f853700ac56afb0738fec87c972782041f57336fc442668a8b55bca7ff` |

Acceptance freezes these identities. Closeout changes only status/history
records and evidence placement, not submission artifacts.

## Cleanup result

After archive and member checks passed, the four redundant uploaded ZIP bundles
and the generated root-level `scopecopy` executable were moved to macOS Trash.
They remain recoverable until the user empties Trash; `agent-runs.tar.gz` is the
durable raw-evidence path afterward. The readable raw directories remain as
ignored local working copies and can be removed separately when no longer
needed.
