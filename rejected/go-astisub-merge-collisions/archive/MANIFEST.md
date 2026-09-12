# go-astisub merge-collisions archive manifest

Archived on 2026-08-01 after four unhinted Nova runs all solved the immutable
pre-T4 package. The later T4 correction added the missing independent region-ID
allocation discriminator; all four saved solution patches passed it unchanged.

## Terminal decision

The task is a valid, behaviorally tested bug fix, but it is not viable for the
Olympus long-horizon lane. The observed solve rate was 4/4, median successful
agent activity was 14.5 messages, and median successful production size was 169
effective LOC. Both local reference architectures and all solver solutions use
straightforward namespace remapping. Review of the successful trajectories and
the T4 replay found no deeper public repository-backed invariant that would add
implementation difficulty rather than fixtures or private constraints.

The canonical package remains under `problems/go-astisub-merge-collisions/` as
a compact historical record. It is closed and must not receive more calibration
runs. Do not revive it through exact suffix spelling, pointer identity, malformed
graphs, unsupported format capabilities, or symmetric collision permutations.
A future go-astisub problem requires a materially different task and a fresh
design gate, false-positive audit, and 0/10 calibration batch.

## Raw solver evidence

- Archive: `agent-runs.tar.gz`
- Original path: `problems/go-astisub-merge-collisions/agent-runs/`
- Contents: 4 run directories and 32 evidence files
- Compressed size: approximately 164 KiB
- SHA-256: `82859302fbdce9bd1a9227e1b570afe93751d4c7f48685bdffadec1f24451a8a`
- Integrity check: `gzip -t archive/go-astisub-merge-collisions/agent-runs.tar.gz`

Restore from the Olympus root with:

```bash
tar -xzf archive/go-astisub-merge-collisions/agent-runs.tar.gz \
  -C problems/go-astisub-merge-collisions
```

The compact outcome and replay result remain in `LEVELS.md`, `RUNS.md`, and
`DESIGN.md`.

## Canonical artifact identifiers

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `43efe3271289d2c1fc60651871a2d219f1240187f43dbebcf8dd922a61d4ea13` |
| `test.patch` | `da8c93beaeb1320868da68488a2a7ff23e382abb00b58f5b312e7a9ecd65df90` |
| `solution.patch` | `c84f7cce962ee6285a03746496baf1ba2eb591100244dcec3d4f3e86c4528778` |
| `Dockerfile` | `4bf6e4f69f75c1a502f9bcdb294c6349f29028ac8473d38334c7fedd87f0e1dc` |

These artifacts are preserved for history, not as a submission-ready package.
