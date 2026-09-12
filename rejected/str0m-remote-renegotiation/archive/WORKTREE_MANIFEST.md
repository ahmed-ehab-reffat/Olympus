# Worktree cleanup manifest - str0m remote renegotiation

Recorded on 2026-07-27 before retiring the two scratch checkouts.

## Repository and canonical recovery

- Repository: `https://github.com/algesten/str0m.git`
- Pinned commit: `98d3b401e4fada626122b9846a5b4f9dd1d5d741`
- Canonical problem folder:
  `problems/str0m-remote-renegotiation/`
- Canonical test patch SHA-256:
  `06351f1c862e1868ff3f89643e6ec1b59aebd212779e29aa8e7790eb474ffe21`
- Canonical solution patch SHA-256:
  `f43666f50dfc101f3b3b33cebd04df2a6b9e5237844aa672c6cd5d4e8ec2d413`

## Checkout inventory before cleanup

| Original path | State | Recovery source | Decision |
|---|---|---|---|
| `work/str0m-remote-renegotiation/source` | Completed solution in `src/change/sdp.rs`; untracked `.config/nextest.toml`, `test.sh`, and randomized integration test; generated `target/` | Canonical patches plus the exact recovery archive | Retired after archive verification |
| `work/str0m-remote-renegotiation/probe` | Earlier modified `src/change/sdp.rs`; untracked predictable-path integration test; generated `target/` | `worktree-recovery.tar.gz` | Retired after archive verification |

The two checkouts together occupied approximately 17 GB, overwhelmingly
generated Cargo output.

## Exact recovery contents

The completed source tracked patch has SHA-256
`f43666f50dfc101f3b3b33cebd04df2a6b9e5237844aa672c6cd5d4e8ec2d413`
and is byte-identical to canonical `solution.patch`. Its randomized integration
test and nextest configuration are byte-identical to the corresponding files
from canonical `test.patch`. Its untracked `test.sh` is an inconsistent earlier
wrapper that still selects `sdp-rejected-offer-state`; it is preserved exactly
but is not canonical.

The earlier probe tracked patch has SHA-256
`bbb5742e2e44edeceb994bcf66f1c5384b68a4c9d0f8c670474ba74ccedcd4cb`.
Its untracked `tests/sdp-rejected-offer-state.rs` has SHA-256
`f0de0f2b9b7a386a64bc4ba853f29a0c29a73f08aea04cbcea5a2090f9f5c776`.

Restore the exact scratch material without generated build output:

```bash
mkdir -p /tmp/str0m-worktree-recovery
tar -xzf archive/str0m-remote-renegotiation/worktree-recovery.tar.gz \
  -C /tmp/str0m-worktree-recovery
git clone https://github.com/algesten/str0m.git /tmp/str0m-recovered
git -C /tmp/str0m-recovered checkout \
  98d3b401e4fada626122b9846a5b4f9dd1d5d741
git -C /tmp/str0m-recovered apply \
  /tmp/str0m-worktree-recovery/probe/tracked.patch
cp /tmp/str0m-worktree-recovery/probe/tests/sdp-rejected-offer-state.rs \
  /tmp/str0m-recovered/tests/
```

Substitute `source` for `probe` to recover the completed scratch checkout.
For the canonical completed package, apply `test.patch` followed by
`solution.patch` instead.

## Cleanup result

After both archives passed gzip and member-list checks:

- the raw `agent-runs/` directory was moved to the system Trash;
- both scratch checkouts and their generated Cargo targets were moved to the
  system Trash;
- the empty `work/str0m-remote-renegotiation/` namespace was retired; and
- the disposable redesign probe under `/tmp` was removed.

Trashed paths remain recoverable until the user empties the system Trash. The
public repository, canonical patches, and recovery archive provide permanent
reconstruction paths.
