# 3d-tiles-atomic-output archive manifest

Archived on 2026-07-23 after explicit abandonment of the candidate.

Environment rehabilitation evidence was added on 2026-08-06 after a local
upstream-style dependency fix passed the required image and complete offline
harness. The candidate remains archived because that fix is not present in an
upstream-accessible revision.

## Environment rehabilitation archive

The authoritative rehabilitation artifacts are:

| Artifact | Purpose | SHA-256 |
|---|---|---|
| `environment-rehab.bundle` | Complete Git history containing branch `olympus-environment-rehab` and commit `1e919dbe48181d63b082007f6b448bfa41746ed4` | `d1e4d66ffd3e1b0a3de53693f6cd1ae93c8b040f0450d954dcbca66458f00506` |
| `environment-rehab.patch` | Directly applicable mail patch for upstream head `4ca692eb16a9c7db21ec99e2aacc32645ce92f28` | `e406d96079e09ee5aa0a73b70c07b1ec43e0f5fac550835a2dfd79263036bc1c` |
| `environment-rehab.Dockerfile` | Proven simple lock-consuming Olympus preflight image | `2f5c3601e83c9b33a13562a92c00dc8bc4b89ed11087e5f3462b678dd17ba0fc` |

The bundle is approximately 5.2 MB and records a complete SHA-1 Git history.
`git bundle verify` passed. A restore test cloned the bundle, explicitly checked
out `olympus-environment-rehab`, reproduced commit
`1e919dbe48181d63b082007f6b448bfa41746ed4`, and reproduced the recorded
manifest and lock hashes. The mail patch also passed `git apply --check`
against an untouched `4ca692e` checkout.

Restore the rehabilitation branch from the Olympus root with:

```bash
git clone archive/3d-tiles-atomic-output/environment-rehab.bundle \
  Work/3d-tiles-tools-environment-rehab-restored
git -C Work/3d-tiles-tools-environment-rehab-restored checkout \
  olympus-environment-rehab
```

Alternatively, apply only the environment change to a clean upstream clone:

```bash
git -C /path/to/3d-tiles-tools checkout \
  4ca692eb16a9c7db21ec99e2aacc32645ce92f28
git -C /path/to/3d-tiles-tools am \
  /path/to/Olympus/archive/3d-tiles-atomic-output/environment-rehab.patch
```

The preflight image built from the rehabilitated tree with base digest
`sha256:a2ac69f318e782a6b20fd29ceefe27ef31cd4d6fddbcab18eac57aa8ba0c5c90`.
With runtime networking disabled, 870 upstream specs, TypeScript compilation,
both post-build copy steps, ESLint, and Prettier passed. The exported image
identity was
`sha256:bddeeacf82680e1bf61ebd4d91b29e60ec3030c4b99c864441d47b8496053a92`.

### Periodic recheck condition

Reconsider the repository only when the official default branch contains a
recognized JavaScript lockfile and declares every tool invoked by its scripts.
Freeze that newer upstream commit and repeat the pristine lock-consuming image
and offline harness preflight. The local bundle and patch are evidence and a
proposed upstream repair; they are not permission to substitute a private
revision for the official repository.

## Raw agent trajectories

- Archive: `agent-runs.tar.gz`
- Original path: `problems/3d-tiles-atomic-output/agent-runs/`
- Contents: 10 run directories and 80 files, plus directory entries
- Original disk usage: approximately 8.5 MB
- Compressed size: approximately 1.2 MB
- SHA-256: `47702773975afd2ddb4e678b05e229cce2347e7a222267e8cbbeeb1c8bf410d0`
- Integrity check: `gzip -t archive/3d-tiles-atomic-output/agent-runs.tar.gz`

Restore from the Olympus root with:

```bash
tar -xzf archive/3d-tiles-atomic-output/agent-runs.tar.gz \
  -C problems/3d-tiles-atomic-output
```

The compact run history remains in
`problems/3d-tiles-atomic-output/RUNS.md`.

## Retired probe test snapshot

- Archive: `probe-test-snapshot.patch`
- Original path: `work/3d-tiles-atomic-output/probe/`
- SHA-256: `ac1793af45ac9184ded1707691a68a5a496db830bed343641e07bc74d95bd953`
- Base commit: `8c4ef2fc77a464d3da42fbfdefb8d4b675c263ff`
- Integrity check: `git apply --check` passed against the untouched base.

The probe contains the three files from an earlier `test.patch`. It differs
from the final canonical suite by one assertion requiring an invalid temporary
base error to contain the exact phrase `not a directory`. Review rejected that
message assertion as implementation-specific, so it is preserved only as
historical evidence.

Restore into an untouched clone with:

```bash
git apply archive/3d-tiles-atomic-output/probe-test-snapshot.patch
```

## Canonical artifacts retained

The problem folder retains the final `meta.md`, `test.patch`, `solution.patch`,
`Dockerfile`, canonical dependency lock, design records, environment
postmortem, and verification helpers. Their hashes and terminal status are
recorded in `problems/3d-tiles-atomic-output/SUMMARY.md`.
