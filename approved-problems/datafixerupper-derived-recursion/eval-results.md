# eval-results.md — datafixerupper-derived-recursion

## Batch 1 (2026-09-10) - 1/10

| Run | Result | Failed tests |
|---|---|---|
| Nova_Nova_7 | PASS 79/79 | - |
| Nova_Nova_1, 3, 5, 8, 9, 10 | 77/79 | the two unregistered-name tests |
| Nova_Nova_2 | 77/79 | both recursive DataFix tests |
| Nova_Nova_4 | 76/79 | the two unregistered-name tests + `the_flag_survives_a_later_plain_registration` |
| Nova_Nova_6 | 75/79 | the two unregistered-name tests + both DataFix tests |

Message counts 61-91. The band rests almost entirely on the unknown-name edge: 8 of 9 failures hit
it, 6 failed only it.

### Replay of the same ten patches against the post-review 83-test suite

Unchanged at **1/10**; Nova_Nova_7 still passes and the four new ordinary-Sum tests killed nobody.
Separately measured: adding the cross-group DataFix regression test the reviewer suggested takes
Nova_Nova_7 to 84 tests / 1 failure, i.e. the batch to 0/10, so that test was not shipped.

Re-measured on the final 87-test suite: still **1/10** (the twin-type fix test kills Nova_2, 6, 9,
all already failing). On the 86-test suite: also **1/10** (Nova_Nova_7 passes; the retained-reference
test kills Nova_1, 2, 6, 9, all already failing; the cross-group transparency test kills nobody).
Earlier re-measure on the 84-test suite: also **1/10**. The eager-reference regression test
kills Nova_1, 2, 6 and 9 (all already failing), Nova_Nova_7 still passes.

## Local validation (2026-09-11, post-Auto-Review round 6)

| Check | Result |
|---|---|
| base mode, base commit + test.patch | 52 tests, 0 failures |
| new mode, base commit + test.patch | 87 testcases, 87 failures (compile failure: `recursiveTypeNames()`, `recursionGroups()` not found) |
| base mode, + solution.patch | 52 tests, 0 failures |
| new mode, + solution.patch | 87 tests, 0 failures |
| patch order test-then-solution | clean |
| patch order solution-then-test | clean |
| reverse apply, both patches | clean |
| flakiness, base x5 | identical (52/0 every run) |
| flakiness, new x5 | identical (87/0 every run; re-verified x3 in Docker after the round-6 named-wrapper fix) |
| effective LOC (hook, Counter 2) | 389 human-effective / 582 raw across 6 files |
| FP: per-branch mutation (both modes) | 18 mutations, 18 killed, 0 survived |
| FP: feature-stub run | 57 of 68 red; 11 green are negative/baseline cases, each accounted for |
| trap-proof, wrapper arms dropped from both `TemplateStructure` walkers | 6 killed, all of them the new `Hook`/`Named` tests |
| trap-proof, re-registration appends instead of replacing in place | 1 killed (`re_registration_keeps_the_original_position`) |
| trap-proof, re-registration keeps the old template | 2 killed (adds `re_registration_replaces_the_template`) |
| trap-proof, uninhabited report restricted to group members | 2 killed (both new propagation tests) |
| trap-proof, every recursive type collapsed into one group | 11 killed, incl. the replacement family test |
| S2 fix proof: cross-group DataFix through `DataFixer.update` | nested tags rewritten at every depth (was unchanged before the fix) |
| trap-proof, `id` gated on a collecting flag instead of on `structure` | 1 killed (`a_reference_assembled_during_registration_still_builds`) |
| trap-proof, `DSL.named` wrapper dropped from `resolved` | 1 killed (`a_fix_targeting_one_recursive_type_leaves_its_twin_alone`) |
| trap-proof, external delegation overrides stripped | 1 killed (`a_required_reference_to_another_group_behaves_as_the_built_type`) |
| supplier evaluation count (counting supplier) | 1 (was 2) |
| S1 fix proof: `Suppliers.memoize` registration | recursion derived, references correct, decode succeeds (threw `UnsupportedOperationException` before) |
| FP: assertion-flip | 10 flips, 10 detected, one test each |
| Docker build (pristine base tree) | success |
| Docker run, `--network none` | base 52/0 and 87/87 without solution; base 52/0 and new 87/0 with it |
| Docker in-container determinism x3 | identical both modes |
| JUnit XML well-formedness | all four files parse, >1 testcase each |

## Per-agent table

| Agent | Evaluator | Verdict | Messages | Files | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|
| (pending) | | | | | | | | |
