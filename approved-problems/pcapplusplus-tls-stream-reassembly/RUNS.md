# Saved solver run index

Raw trajectories are archived as `agent-runs1.zip` and `agent-runs2.zip` under
`archive/pcapplusplus-tls-stream-reassembly/`. Each bundle contains five Nova
runs. Detailed discriminator interpretation remains in `DESIGN.md`; immutable
batch identities remain in `LEVELS.md`.

## First batch

| Run | Original outcome | Final-package replay |
|---|---|---|
| `Nova_Nova_1` | missed requirement after an apparent focused pass | 12/14; exact-limit split prefix and split oversized body |
| `Nova_Nova_2` | legitimate on its original version | 13/14; oversized inner rejection reporting |
| `Nova_Nova_3` | verifier/API mismatch on its original version | 12/14; exact-limit split prefix and inner rejection reporting |
| `Nova_Nova_4` | legitimate on its original version | 12/14; completion timestamp and split rejection accounting |
| `Nova_Nova_5` | legitimate on its original version | 13/14; split oversized body framing |

## Second batch

All five baselines passed. All five focused targets failed to compile because
the solvers independently returned raw integer wire types from three getters.
After mechanically normalizing only those return types to the now-published
Packet++ SSL categories, every implementation compiled and reached 13/14. Runs
1 and 4 then failed only configured/malformed bounds; runs 2, 3, and 5 failed
only missing-data recovery.

The second batch was abandoned at 0/5 when the public description and tests
changed. Neither batch counts toward the accepted final revision.
