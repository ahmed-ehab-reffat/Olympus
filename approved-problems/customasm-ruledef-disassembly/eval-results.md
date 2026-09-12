# eval-results.md — customasm-ruledef-disassembly

No agent runs. Design phase.

| Batch | Run | Agent | Verdict | Msgs | Files | LOC | Failed tests | Approach note |
|---|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — | — |

## Watch items for batch 1

- Does any passer build a general expression solver instead of the bounded invertible subset? That
  is the architecture-jump to watch for (HARDENING 3a.6).
- Do failures cluster on term-width (trap 1) or on stream desynchronization (trap 3)? Trap 3
  failures surface many instructions after the bad choice and are the misdirection this rests on.
- Solver median messages must be >= 40.

## Capture protocol

Save every passing diff to `agent-runs/<batch>-<run>.patch` plus the two most instructive failers.
