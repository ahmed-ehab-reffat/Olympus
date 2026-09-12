# RUNS - h5py VDS reconstruction and relocation

`agent-runs3/` belongs to the abandoned copy-only version. Its completed result
was 2/10, but both successful patches changed one production file and the
platform reported a 133-LOC successful median. Those runs are design evidence
only and cannot count toward the redesigned artifact.

Representative exact replays against the 41-entity redesign:

| Prior run | Old status | Redesigned score | Meaning |
|---|---|---:|---|
| Nova 8, `rd7cj570wajjs0n8kjwqyehqxd8c3v7z` | legitimate 24/24 pass | 29/41 | complete copy-only behavior; all 12 layout entities absent |
| Nova 10, `rd70edekgh5ff4skwf5wtjd9bh8c31a4` | legitimate 24/24 pass | 28/41 | creation-property omission plus all layout entities |
| Nova 6, `rd7d66gjt67tnkgy2wqpcdjedn8c3d52` | broadest 22/24 near-pass | 27/41 | two old misses plus all layout entities |

All ten old runs and raw trajectories were reviewed before redesign; the full
historical table remains in the trajectory bundle and DESIGN record. No cold
redesign solver was run. The platform accepted the exact redesigned artifact on
2026-08-10; the raw uploaded bundles are preserved under
`archive/h5py-vds-copy-relocation/` without reclassifying predecessor runs.
