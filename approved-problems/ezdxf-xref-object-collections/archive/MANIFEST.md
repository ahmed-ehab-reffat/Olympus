# ezdxf XREF object collections archive

Status: **accepted and archived 2026-08-16; user-confirmed**.

Canonical submission artifacts and compact design, environment, run, gap,
fairness, and false-positive records remain under
`problems/ezdxf-xref-object-collections/`. This archive holds the raw solver
bundles, preliminary candidate records, and cleanup inventories.

## Canonical accepted artifacts

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `27b8bfcb2d3cf4c92d8fefb4e6bd16c4b1f5e2a777a64c383cf863f75ea5cafc` |
| `test.patch` | `35520d3dfd8392f911f6850f910d048226a601bb9c3964649c098dcc5685631e` |
| `solution.patch` | `42bb5c0434f2d130cc70872f24001d4b4ed3ddd8baa0347c6a2b324cca7e1aee` |
| `Dockerfile` | `08d4df4c43468592168153cc6e92b83a668bd4cb4ec6d1962831f088a5ad0309` |
| `solution_approach.md` | `6551c6fb5725ca4242d2eb5d994bd10ffa7dced42a0c9ab50681394556ae26d3` |

Immutable version 7 passes 36/36 focused tests and 7,842 complete base tests
with 97 skips and one expected failure. All 34 attempted incorrect mutants are
rejected. Acceptance does not change these frozen artifact identities.

## Raw solver evidence

| Archive | Historical version | File members | SHA-256 |
|---|---|---:|---|
| `agent-runs1.zip` | v2 | 64 | `92e545f406b498f46503055178e80e6a16091a4c037309c880c424c0bdcf4a41` |
| `agent-runs2.zip` | v3 | 40 | `a2596a2c8c7ef73d9d29b4a10e1cffcae2bc75f98f6cc25bab5c97fadcde4795` |
| `agent-runs3.zip` | v7 | 40 | `0c9b95dc823e0e0aa63151ce8183dd69a8cd3d60f9d94d33d0730a373a4d2e8a` |

All three ZIPs passed `unzip -t`. Each was extracted and recursively compared
with its readable source directory, excluding only `.DS_Store`; all files were
byte-identical. The duplicate readable directories were removed only after
those checks passed.

Restore a batch from the Olympus root with, for example:

```sh
mkdir -p problems/ezdxf-xref-object-collections/agent-runs3
unzip archive/ezdxf-xref-object-collections/agent-runs3.zip \
  -d problems/ezdxf-xref-object-collections/agent-runs3
```

## Preliminary candidate records

| Artifact | SHA-256 |
|---|---|
| `candidate-records/DESIGN.md` | `e35248a800860b0014e78e080db7f0eb2fcee34652f52944e6179b32d4f52571` |
| `candidate-records/phase-a.Dockerfile` | `89101907c633111a6c61357528a73b1ceb20aa5780a43a19ed630702721ada7e` |

These files moved from the active candidate namespace without content changes.

## Cleanup

Closeout removed the reconstructible ezdxf authoring worktree, duplicate raw-run
extractions, the ezdxf subtree and Dockerfile from the shared August 14 scratch
batch, the archive-verification extraction, and `.DS_Store` metadata in the
canonical problem folder. `WORKTREE_MANIFEST.md` and `cleanup-inventory.tsv`
record those exact targets.

No ezdxf-scoped container, image, volume, or network existed at closeout. The
earlier v7 audit image had already been deleted. Shared Olympus base images,
the shared scratch batch's other repositories, unrelated containers/images,
and unrelated build cache were left untouched.
