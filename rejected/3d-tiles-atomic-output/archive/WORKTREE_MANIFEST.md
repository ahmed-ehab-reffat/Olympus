# Worktree cleanup manifest - 3d-tiles-atomic-output

Recorded on 2026-07-23 before cleanup of the abandoned candidate's scratch
checkouts.

## Repository and canonical recovery

- Repository: `https://github.com/CesiumGS/3d-tiles-tools.git`
- Pinned commit: `8c4ef2fc77a464d3da42fbfdefb8d4b675c263ff`
- Canonical problem folder: `problems/3d-tiles-atomic-output/`
- Canonical test patch SHA-256:
  `e482e67f2bbc965c4b080ab2efc3da3f1971af8a452184fa53f2a04a6d1876e9`
- Canonical solution patch SHA-256:
  `fbaae9fc80c827d16003d45e9c7e53ad0739099b5b019a1f165456142887a1a4`

Both canonical patches and the archived probe snapshot pass
`git apply --check` against the pinned clean checkout.

## Checkout inventory before cleanup

| Original path | Role | State | Approximate size | Recovery source | Decision |
|---|---|---|---:|---|---|
| `work/3d-tiles-atomic-output/source` | primary verification clone | detached; solution file plus three test files | 23 MB | canonical test and solution patches; exact file comparison passed | remove |
| `work/3d-tiles-atomic-output/solution` | linked reference worktree | detached; one modified file | 19 MB | production diff is byte-identical to `solution.patch` | remove |
| `work/3d-tiles-atomic-output/probe` | linked earlier-suite probe | detached; three intent-to-add files | 423 MB | `probe-test-snapshot.patch`; exact recovery check passed | remove |
| `/private/tmp/3d-tiles-pristine.8I67XR` | linked pristine verifier | detached and clean | 10 MB | public repository plus pinned commit | remove |
| `work/3d-tiles-atomic-output/tmp` | empty task scratch directory | no independent repository | 4 KB | none required | remove |

The large probe size is generated dependency storage. Its only unique source
state is the retired exact-message assertion captured in the archive patch.

## Additional temporary material

Twenty-six task-prefixed paths under `/private/tmp` occupied approximately
1.0 GB. They consist of extracted build contexts, installed dependency graphs,
JUnit reports, generated locks, upstream search responses, and local
comparison patches. All are reproducible from the pinned repository, canonical
artifacts, or raw trajectory archive and may be removed.

## Recovery commands

Recreate the final solved checkout from the Olympus root:

```bash
git clone https://github.com/CesiumGS/3d-tiles-tools.git \
  work/3d-tiles-atomic-output/recovered
git -C work/3d-tiles-atomic-output/recovered checkout \
  8c4ef2fc77a464d3da42fbfdefb8d4b675c263ff
git -C work/3d-tiles-atomic-output/recovered apply \
  ../../../problems/3d-tiles-atomic-output/test.patch
git -C work/3d-tiles-atomic-output/recovered apply \
  ../../../problems/3d-tiles-atomic-output/solution.patch
```

## Completion record

Completed on 2026-07-23.

- Removed linked worktrees:
  `work/3d-tiles-atomic-output/probe`,
  `work/3d-tiles-atomic-output/solution`, and
  `/private/tmp/3d-tiles-pristine.8I67XR`.
- Moved the primary `work/3d-tiles-atomic-output/` namespace to the system
  Trash after its source and test state was matched to the canonical patches.
- Moved the archived raw `agent-runs/` source directory and its `.DS_Store` to
  the system Trash.
- Moved all remaining `/private/tmp/3d-tiles-*` and
  `/private/tmp/3dtiles-*` paths to the system Trash; no matching task path
  remains under `/private/tmp`.
- The linked worktrees removed through Git are recoverable from the public
  repository and the artifacts listed above. Trashed paths remain recoverable
  until the user empties the system Trash.
- No Rust problem path was moved, removed, staged, or committed.

## 2026-08-06 environment rehabilitation checkout

The later environment-only investigation created
`Work/3d-tiles-tools-environment-rehab/`. Its branch
`olympus-environment-rehab` is clean at
`1e919dbe48181d63b082007f6b448bfa41746ed4`. The checkout is retained only as
a convenience for periodic upstream comparisons. Its unique commit is now
recoverable from `environment-rehab.bundle`, the directly applicable change is
also preserved as `environment-rehab.patch`, and its untracked preflight
Dockerfile was moved into this archive as `environment-rehab.Dockerfile`.

The archive is authoritative. The convenience checkout may be removed later
without losing source state after rerunning the bundle restore check recorded
in `MANIFEST.md`.
