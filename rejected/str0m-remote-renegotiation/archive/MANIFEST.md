# str0m remote renegotiation archive manifest

Archived on 2026-07-27 after the immutable L3 package calibrated at ten
legitimate solves in ten runs.

## Terminal decision

The task is a valid, well-tested bug fix, but it is not a viable Olympus
long-horizon problem. All ten Nova runs passed the 31 neighboring SDP tests and
all six challenge tests. Every evaluator verdict was `PASS_LEGITIMATE`.

All successful implementations converged on the same repository-native
validation-before-commit change in `src/change/sdp.rs`. Excluding additions in
that file's test module, the ten solver patches changed 97–147 production lines.
No near-pass, broad failure, or incorrect survivor provided a fair new
discriminator. Adding more offer fixtures would repeat the existing ICE,
fingerprint, media, event, candidate, extension, or SNAP failure families.

The canonical package remains under
`problems/str0m-remote-renegotiation/` as a compact historical record. It is
closed, must not receive more calibration runs, and should not be revived by
adding symmetric hidden-test cases. A future str0m problem requires a materially
different repository-backed task and a new design, audit, and 0/10 batch.

## Raw solver evidence

- Archive: `agent-runs.tar.gz`
- Original path:
  `problems/str0m-remote-renegotiation/agent-runs/`
- Contents: 10 run directories and 80 evidence files
- Original disk usage: approximately 4.5 MB
- Compressed size: approximately 940 KB
- SHA-256:
  `0d8bde979aa4a54fc52483f7a03826baf87541cb8b2337b2a04ddfddaf7eff0c`
- Integrity check:
  `gzip -t archive/str0m-remote-renegotiation/agent-runs.tar.gz`

Restore from the Olympus root with:

```bash
tar -xzf archive/str0m-remote-renegotiation/agent-runs.tar.gz \
  -C problems/str0m-remote-renegotiation
```

The compact outcome and per-run matrix remain in
`problems/str0m-remote-renegotiation/RUNS.md`.

## Dirty worktree recovery

- Archive: `worktree-recovery.tar.gz`
- SHA-256:
  `bd75563c0b18e519e559df3a60b445b61faf677aa63fde7c98dbc6a13f5aef08`
- Compressed size: approximately 12 KB
- Pinned commit:
  `98d3b401e4fada626122b9846a5b4f9dd1d5d741`

The recovery archive contains exact tracked patches, status snapshots, and
untracked source files for the completed `source` checkout and the earlier
`probe` checkout. The completed source diff is byte-identical to canonical
`solution.patch`. Its untracked wrapper still names the earlier predictable test
target, so the canonical `test.patch` remains authoritative. The probe contains
an older, distinct feasibility implementation and predictable-path regression
test and is retained only as historical design evidence.

See `WORKTREE_MANIFEST.md` for hashes, restore commands, and cleanup details.

## Canonical artifact identifiers

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `c59f5a12c9b3bc42deeb015263cea59fce06c53236ff8370a8feb36a1c27431c` |
| `test.patch` | `06351f1c862e1868ff3f89643e6ec1b59aebd212779e29aa8e7790eb474ffe21` |
| `solution.patch` | `f43666f50dfc101f3b3b33cebd04df2a6b9e5237844aa672c6cd5d4e8ec2d413` |
| `Dockerfile` | `69f599d152c11436e019a47bd50b08f36d7e09eee96fda5b6ca290db2c90973a` |

These artifacts are preserved for history, not as a submission-ready package.
The calibration failure is terminal even though the base/reference gates were
locally reproducible.
