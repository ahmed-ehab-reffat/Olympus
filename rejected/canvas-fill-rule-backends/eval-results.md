# eval-results.md — canvas-fill-rule-backends

No agent batch run yet. Platform agents (Nova/Orion/Vega/Castor) cannot be run from this
workstation; this table is filled after the first platform batch.

| Batch | Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — | — | — |

## Capture protocol reminder (HARDENING § 3e)
At every batch, save each PASSING agent's diff to `agent-runs/<batch>-<run>.patch` plus the 1-2
most instructive failers, while the run view is open. The differential harness, trap-proof, FP
verification and leanest-passer LOC all require the actual patches.
