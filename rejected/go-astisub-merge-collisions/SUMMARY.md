# SUMMARY - go-astisub collision-safe merge

**Status: archived on 2026-08-01 as too easy for Olympus.**

| Field | Value |
|---|---|
| Repository | `asticode/go-astisub` |
| Repository URL | `https://github.com/asticode/go-astisub` |
| Base commit | `52190f1d606f35190d40e86ecb02c31902f30272` |
| Production language | Go |
| License | MIT |
| Task type | bug fix |
| Task | Preserve named definition meaning across colliding subtitle merges |
| Platform state | closed; pre-T4 evidence was 4/4 solves; no active batch |

The canonical patches apply cleanly in either required sequence from the pinned
commit. Base preserves all 90 legacy tests and fails all seven focused entities;
the reference passes both modes, the complete suite, race, and vet. The Docker
image builds successfully. The revised exact-version mutation audit checks only
observable behavior and left no survivor in the attempted set. The added T4
region-allocation discriminator is passed unchanged by all four saved successful
agent patches, confirming that it fixes coverage without increasing difficulty.

Artifact hashes and the full audit record are in `DESIGN.md`. Raw solver
evidence is preserved in `archive/go-astisub-merge-collisions/agent-runs.tar.gz`.
The package must not receive more calibration runs or artificial hardening; a
future go-astisub task must be materially different.
