# Run index - explicit local and external transitions

Status: accepted on 2026-07-26.

The raw solver material is archived in
`archive/statig-local-transitions/agent-runs.tar.gz`. The archive contains 39
run directories and 312 files across eight captured collections. Results below
describe each collection against its own immutable artifact version; they must
not be combined into one calibration rate after prompt or test changes.

| Collection | Runs | Baseline | Recorded result at that version | Decisive lesson |
|---|---:|---|---|---|
| `agent-runs` | 4 | 4/4 pass | 3 legitimate passes, 1 failure | Early suites admitted several private-origin implementations; one failed blocking hook order. |
| `agent-runs2` | 4 | 4/4 pass | 4 legitimate passes | Absolute depths and target-side rediscovery remained too easy under that version. |
| `agent-runs3` | 5 | 5/5 pass | 0 legitimate passes | Borrowed hierarchy mutation moved or over-widened the external boundary. |
| `agent-runs4` | 4 | 4/4 pass | 3 legitimate passes, 1 failure | A repeated superstate variant in an unrelated branch exposed discriminant-based subtree classification. |
| `agent-runs5` | 7 | 7/7 pass | 0 legitimate passes | Six near-passes lost the accepting handler after parent mutation; one exposed origin through a sixth public outcome. |
| `agent-runs6` | 3 | 3/3 pass | 0 legitimate passes | The remaining Orion runs reproduced the parent-mutation boundary failure. |
| `agent-runs7` | 6 | 6/6 pass | 0 legitimate passes | All six collapsed distinct hierarchy occurrences by matching superstate variants. |
| `agent-runs8` | 6 | 6/6 pass | 0 legitimate passes | All six implemented nearly the full task but failed the explicit accepting-handler ancestor-insertion boundary. |

## Final accepted artifact

- Base commit: `3780eecdbcf4326051c38676d592c6c2b4a3bab5`
- Prompt: 197 ASCII words
- Reference implementation: 349 changed production lines across six core files
- Focused suite: 46/46
- Baseline: 23 executable tests and 22 doctests
- Feature composition: blocking-only and async-only checks with default
  features disabled
- False-positive verifier: all 33 mutations caught
- Patch-state gates: all four passed in the network-disabled Rust 1.90 image
- Platform outcome: accepted, as confirmed by the user on 2026-07-26

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `b47d2a0aff86ecaff1acfaab4abae6a2bd8c34d91b7e1cafa94684c7cd5ea01c` |
| `test.patch` | `408ea040917b64feb0688ecb7ed92338d85a3c11748e16d38927c81b4e99f9d9` |
| `solution.patch` | `9fd3f07e7b1c202187f96e4d2fea0b968ea69e962faf0a5b0dfbedb7077f67bd` |
| `verify/mutations.sh` | `c56a6c0a02035a3fc2341ef10fcbe59b596812c1674442b5ffedaa3056ae6eb8` |
| `verify/README.md` | `63032585478b5bcb768188c21d0c960b9f8c93907f7652f680dab36a53e236c1` |

The detailed version history and fairness rationale remain in `LEVELS.md`,
`ERRORS.md`, and `DESIGN.md`. The worked false-positive narrative remains live
as `false_postive trials.md` because `AGENTS.md` uses it as the repository-wide
audit example; an acceptance-time snapshot is also preserved in
`archive/statig-local-transitions/retired-artifacts.tar.gz`.
