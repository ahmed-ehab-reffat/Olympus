# eval-results.md — quint-temporal-properties

## Local verification

| check | result |
|---|---|
| vanilla suite (no patches, host) | 658 passing / 2 failing in 5s; both failures `test/runtime/rust/repl.test.ts` |
| repo suite with solution (host, rust excluded) | 631 passing / 0 failing |
| new tests with solution (host) | 128 passing / 0 failing |
| new tests on base (host) | 0 passing / 128 failing |
| effective LOC | 540 human-effective, 754 raw, 6 files |
| meta.md | 409 words, ASCII, no em dashes |
| patches | ASCII, LF; `test.sh` at mode 100755 |

## F2P

Every one of the 128 new tests fails on base and passes with the solution. Two of them passed on
base in the first draft, because they only asserted behavior that already worked (a plain invariant
and the two fairness operators staying rejected); both now also assert the new behavior they sit
next to, so the set is 128/128.

Mocha's xunit reporter writes the suite header as `failures="0" errors="N"` and puts a `<failure>`
element inside every failing `<testcase>`. The per-test nodes are named and carry the failure, which
is what per-test classification reads.

## Mutation proof

Each row is the natural-but-wrong implementation of one requirement, applied on its own to the
reference solution. Counts are failing tests out of 128.

| mutation | kills |
|---|---|
| state identity by reference instead of by value | 26 |
| `next` reuses the current-state build | 21 |
| `always` checks only the position it was asked about | 13 |
| `mustChange` compares the observed value by reference | 11 |
| a property given by name is not unfolded | 9 |
| an open prefix decides like a cycle | 7 |
| an error in a temporal operand becomes false | 7 |
| `mustChange` keeps the step it rejected | 4 |
| a position with no successor counts as false | 4 |
| lasso detection compares trace metadata too | 3 |
| `enabled` leaves the action it tried behind | 5 |
| the cycle keeps the repeated state twice | 2 |
| the cycle is entered at position zero | 2 |
| `orKeep` stutters without rolling back | 3 |
| `enabled` reports an error as unavailable | 3 |
| a next-state definition is cached like a current-state one | 1 |
| connectives evaluate every operand | 1 |
| an error in the observed value keeps the rejected writes | 2 |
| `enabled` keeps writes made before an error | 2 |
| `orKeep` keeps writes made before an error | 2 |
| `mustChange` keeps writes made before an action error | 2 |
| `leadsTo` looks for the effect regardless of the cause | 1 |
| an open prefix gets one shared default instead of three values | 10 |
| (retired) loading a state without clearing cached values | 0 |

## Docker matrix

Image built from the base tree plus the submitted Dockerfile. Every cell runs offline
(`--network none`) as uid 1000. Numbers are the JUnit XML the platform reads.

| cell | testcases | failures |
|---|---|---|
| base tree + test.patch, base mode | 631 | 0 |
| base tree + test.patch, new mode | 128 | 128 |
| test.patch then solution.patch, base mode | 631 | 0 |
| test.patch then solution.patch, new mode | 128 | 0 |
| solution.patch then test.patch, base mode | 631 | 0 |
| solution.patch then test.patch, new mode | 128 | 0 |
| determinism, 3x new | 128 | 0 (identical each run) |
| determinism, 3x base | 631 | 0 (identical each run) |

## Agent runs

Batch 2, nine runs (Nova and Orion solvers, Nova eval): **1 pass, 8 fail, 11%**.

| run | solver | verdict | msgs | LOC | failed on |
|---|---|---|---|---|---|
| 1 | Nova | FAIL_MISUNDERSTOOD_TASK | 100 | 605 | `next` treated as run-only, 26 tests |
| 2 | Orion | **PASS_LEGITIMATE** | 127 | 714 | - |
| 3 | Orion | FAIL_MISSED_REQUIREMENT | 146 | 830 | `next` run-only, plus eager `leadsTo`, 27 tests |
| 4 | Nova | FAIL_MISSED_REQUIREMENT | 125 | 533 | `next` only during trace replay, plus boolean open prefixes, 27 tests |
| 5 | Nova | FAIL_MISSED_REQUIREMENT | 162 | 637 | filtered `#actionTaken` instead of `mbt::actionTaken`, 3 tests |
| 6 | Nova | FAIL_MISSED_REQUIREMENT | 149 | 562 | open prefixes as ordinary booleans, 2 tests |
| 7 | Nova | FAIL_MISSED_REQUIREMENT | 128 | 592 | invented a `--temporal` flag, left the property per-state, 80 tests |
| 8 | Nova | FAIL_MISSED_REQUIREMENT | 95 | 576 | next-state reuse of current-state memos, 2 tests |
| 9 | Nova | FAIL_MISSED_REQUIREMENT | 112 | 476 | open-run uncertainty collapsed to booleans, 3 tests |

Solvability is proven by run 2. The pass rate is 11%, at the hard end of the band. Every failure is a
designed trap firing: three runs on `next` as a run-only operator, three on collapsing open-prefix
uncertainty into booleans, one on the metadata key names, one on next-state memo reuse, one on wiring
a new flag instead of the existing property argument.

Batch 1, three Nova solver/eval runs, 0/3 (superseded: two of the three were the backend ambiguity,
fixed before batch 2).

| run | verdict | msgs | LOC | note |
|---|---|---|---|---|
| 1 | FAIL_TEST_MISMATCH | 120 | 712 | implemented in the Rust backend; evaluator flagged the task as backend-ambiguous |
| 2 | FAIL_MISSED_REQUIREMENT | 95 | 565 | TypeScript, 111/112; failed only the open-prefix negation case |
| 3 | FAIL_WRONG_FILE | 121 | 813 | implemented in the Rust backend |

Runs 1 and 3 were caused by the description not naming which of the two simulator backends to
change, with `cli.ts` defaulting simulation to `rust`. The description now names the TypeScript
runtime. Run 2 is the difficulty datapoint: fair, `difficulty: challenging`, one test short.

Solvability is unproven at 0/3 and needs a fresh batch against the corrected description.
