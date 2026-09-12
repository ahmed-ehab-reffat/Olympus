# RUNS - moov-io/ach ApplyCorrections

Compact calibration and review index for the accepted problem. Raw run bundles are stored in `../../archive/moov-ach/actual_trajectories.tar.gz`; its checksum and restore command are in the adjacent archive manifest.

All recorded runs passed the baseline suite. Counts below are the feature-suite result for the level the agent saw.

| Run | Level | Feature result | Recorded verdict | Decisive observation |
|---:|---|---:|---|---|
| 1 | L1 | 27/27 | pass | The initial atomic apply/control task fit a standard stage-validate-commit solution. |
| 2 | L1 | 27/27 | pass | Independently confirmed L1 was too easy. |
| 3 | L2 | 43/43 | pass | Composite as-sent matching and atomicity were absorbed into the same staging architecture. |
| 4 | L2 | 43/43 | pass | Confirmed L2 remained too easy. |
| 5 | L3 | 74/74 | pass | Refusal output and offsets fit an ordered forward-mutation pipeline; the agent also added IAT support proactively. |
| 6 | L3 | 74/74 | pass | Confirmed L3 remained too easy. |
| 7 | L4 | 110/120 | fail | Stale offset validation, narrow rebalancing, and IAT service-class handling. |
| 8 | L4 | 107/120 | fail | Offset feasibility was stricter than the contract; transaction and IAT service-class errors remained. |
| 9 | L4 | 105/120 | fail | Offset feasibility dominated, with transaction validation, refused numbering, and IAT undo defects. |
| 10 | L4 | 118/120 | fail | Only the two directional IAT service-class cases failed. |
| 11 | L4 | 110/120 | fail | Valid direction changes were refused and IAT service class stayed mixed. |
| 12 | L4 | 100/120 | fail | Broad misses across concrete validation, offsets, rollback, Refused, and Undo. |
| 13 | L4a | 120/120 initially; 123/125 under L4b | false-positive pass | A custom corrected-data parser accepted incomplete C03/C06/C07 data. The corrected fair suite rejects it in exactly two tests. |
| 14 | L4a | 118/120 | fail | Multi-file Refused output retained duplicate source batch numbers. |

## Calibration progression

- L1 through L3 produced six straight legitimate solves and established the common forward architecture to defeat.
- L4 crossed executable inverse history, bounded IAT targets, and concrete batch validation. Runs 7-12 all failed, proving a hard ceiling.
- L4a clarified directional service-class reconstruction without changing behavior.
- Panel review invalidated run 13's apparent pass and identified missing incomplete-composite coverage plus a reference output-service-class bug.
- L4b added five fair regressions, fixed the reference, passed 125/125 feature tests and 1534/1534 baseline tests, killed all 41 mutations, and was accepted on 2026-07-23.

## Why the raw bundles remain valuable

The raw logs preserve candidate patches, JUnit reports, evaluator summaries, and complete trajectories. Use them when investigating a future false positive or comparing a new discriminator with an observed solver architecture; use this file for ordinary navigation.
