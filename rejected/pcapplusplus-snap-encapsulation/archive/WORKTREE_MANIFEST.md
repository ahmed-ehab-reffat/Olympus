# PcapPlusPlus SNAP scratch-workspace disposition

Five SNAP checkouts shared `Work/pcapplusplus-third-problem-audit/` with the
later accepted TLS checkout. All were based at
`8ac4366c4184f096973ef4a0ca084559935828d0` and were ordinary clones rather
than registered worktrees.

| Checkout | Dirty entries | Recovery patch |
|---|---:|---|
| `final-exact` | 8 | `prototype-recovery/final-exact.patch` |
| `probe-complete` | 5 | `prototype-recovery/probe-complete.patch` |
| `probe-minimal` | 5 | `prototype-recovery/probe-minimal.patch` |
| `test-author` | 10 | `prototype-recovery/test-author.patch` |
| `test-only` | 3 | `prototype-recovery/test-only.patch` |

Each recovery patch passed forward application against the clean pin and
reverse application against the corresponding checkout. The final solution
portion also reverse-applied exactly from the canonical live `solution.patch`;
historical test layouts differed and are therefore retained explicitly rather
than inferred from the final package.

The whole shared namespace was moved to
`~/.Trash/Olympus-pcapplusplus-tls-cleanup-20260808/` after both the TLS and
SNAP recovery archives were verified. Restore any state by applying its patch
to a clean checkout at the recorded pin.
