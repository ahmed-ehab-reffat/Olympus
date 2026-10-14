# eval-results.md - vega-keyed-dataset-reconciliation

No platform batch yet.

## Local measurements
| Date | Measurement | Result |
|---|---|---|
| 2026-09-29 | Hook on full-lane spike (`solution.patch`, 10 files) | raw 168, human-effective **123**, padding-floor 44 |
| 2026-09-29 | Spike functional probe in Docker (uid 1000, --network none) | all 8 scenarios correct |
| 2026-09-29 | Base suites with spike | dataflow 125/125, transforms 4168/4168, parser 143/143, view 37/37, runtime 44/44, functions 205/205, vega 311/311 |
