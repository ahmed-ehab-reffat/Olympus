# cfn-guard-cidr-operator — eval results

Fingerprint (update per batch): sol=<sha> test=<sha> meta=<sha> docker=<sha> base=57bbdbf

## Local pre-eval
| Check | Result |
|---|---|
| Build | clean |
| New on solution | 34/34 PASS |
| New on base (f2p) | 0/34 (19 failures via ./test.sh new) |
| Base regression | 287 cases / 0 failures |
| Flakiness (base 5x / new 3x) | deterministic |
| Effective LOC (Counter1) | 356 |

## Platform batches
Batch 1 (arith-era not applicable). CIDR batch 1: 5/10 Nova (too easy). Added covered_by must-derive lever + coverage tests -> re-batch pending. (target <=40% — Nova/Orion/Vega, target <=40% pass, >=1 solve. Record per-run + save passing diffs to agent-runs/.)
