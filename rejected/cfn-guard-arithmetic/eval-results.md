# cfn-guard-arithmetic — eval results

Fingerprint (update per batch): sol=<sha> test=<sha> meta=<sha> docker=<sha> base=57bbdbf

## Local pre-eval (not a platform batch)
| Check | Result |
|---|---|
| Build | clean |
| New on solution | 19/19 PASS |
| New on base (f2p) | 0/19 PASS (19 failures via ./test.sh new) |
| Base regression | 287 cases / 0 failures |
| Flakiness (base 6x / new 3x) | deterministic |
| Effective LOC (Counter-1) | 278 |

## Platform batches
(pending — Nova/Orion/Vega mix; target <=40% pass, >=1 solve. Record per-run: agent, verdict, msgs/LOC/files, failed test names, one-line approach note. Save passing diffs to agent-runs/.)
