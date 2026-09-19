# eval-results.md — planetiler-custommap-schema-composition

No agent batch has been run yet. The solver-visible surface (meta.md, Dockerfile, repo + base
commit) was still being settled through R1, per the re-eval sequencing rule: freeze the description
before batch 1, then iterate tests and solution against re-eval at ~30% of batch price.

| Batch | Agent | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|
| (none yet) | | | | | | | | |

## Local validation history

| Date | Check | Result |
|---|---|---|
| 2026-09-14 | Clean room, base + test.patch | base 431 pass / new 62 fail |
| 2026-09-14 | Clean room, + solution.patch | base 431 / new 62 pass, 3x identical |
| 2026-09-14 | FP mutation battery (26 single-point mutations) | all detected |
| 2026-09-14 | Docker (olympus-base-jvm, --network none) | base 431/0, new 62 fail, then 62/0 with solution |
| 2026-09-16 | R1 clean room, base + test.patch | base 431 pass / new 70 fail |
| 2026-09-16 | R1 clean room, + solution.patch | base 431 / new 70 pass, 3x identical both modes |
| 2026-09-16 | R1 discrimination: new tests vs PRE-revision solution | 6 fail, one per fixed solution bug |
| 2026-09-16 | R1b fairness audit (independent trace of every assertion) | 5 unpinned assertions removed, 1 kept and pinned in meta.md |
| 2026-09-16 | R1b clean room, base + test.patch | base 431 pass / new 71 fail |
| 2026-09-16 | R1b clean room, + solution.patch | base 431 / new 71 pass, 3x identical both modes |
| 2026-09-16 | R1b Docker (olympus-base-jvm, --network none) as ROOT | base 431/0, new 71 fail; + solution 431/0 and 71/0 |
| 2026-09-16 | R1b Docker as uid 1000 (first attempt) | FAILED: /app perms, git dubious-ownership, root-owned target/ |
| 2026-09-16 | R1b Docker as uid 1000 (Dockerfile fixed) | base 431/0, new 71 fail; + solution 431/0 and 71/0 |
| 2026-09-16 | R2 clean room, base + test.patch | base 431 pass / new 74 fail |
| 2026-09-16 | R2 clean room, + solution.patch | base 431 / new 74 pass, 3x identical both modes |
| 2026-09-16 | R2 Docker (olympus-base-jvm, --network none) as ROOT | base 431/0, new 74 fail; + solution 431/0 and 74/0 |
| 2026-09-16 | R2 Docker as uid 1000 | identical: base 431/0, new 74 fail; + solution 431/0 and 74/0 |
| 2026-09-16 | R2 spotless:check (repo formatter) | exit 0 |
| 2026-09-16 | R3 clean room, base + test.patch | base 431 pass / new 77 fail |
| 2026-09-16 | R3 clean room, + solution.patch | base 431 / new 77 pass, 3x identical both modes |
| 2026-09-16 | R3 spotless:check | exit 0 |
| 2026-09-16 | R3 discrimination: revert ONLY SchemaValidator, keep rest of solution | 3 validator tests fail, incl. the reviewer's exact error "base.yml,overlay.yml does not exist" |
| 2026-09-16 | R3 Docker (olympus-base-jvm, --network none) as ROOT | base 431/0, new 77 fail; + solution 431/0 and 77/0 |
| 2026-09-16 | R3 Docker as uid 1000 | identical: base 431/0, new 77 fail; + solution 431/0 and 77/0 |
| 2026-09-17 | R4 clean room, base + test.patch | base 431 pass / new 80 fail |
| 2026-09-17 | R4 clean room, + solution.patch | base 431 / new 80 pass, 3x identical both modes |
| 2026-09-17 | R4 discrimination: R3 validator String branch restored | standalone bundled-schema test fails (validation throws, result null) |
| 2026-09-17 | R4 spotless:check | exit 0 |
| 2026-09-17 | R4 Docker as root and as uid 1000 (--network none) | identical: base 431/0, new 80 fail; + solution 431/0 and 80/0 |
| 2026-09-17 | R5 clean room, base + test.patch | base 431 pass / new 81 fail |
| 2026-09-17 | R5 clean room, + solution.patch | base 431 / new 81 pass, 3x identical both modes |
| 2026-09-17 | R5 discrimination: old Ref.of resolver restored | new test fails, expected Power but was Shadow |
| 2026-09-17 | R5 Docker as root and as uid 1000 (--network none) | identical: base 431/0, new 81 fail; + solution 431/0 and 81/0; no leftover cwd file |
| 2026-09-17 | R6 clean room, base + test.patch | base 431 pass / new 83 fail |
| 2026-09-17 | R6 clean room, + solution.patch | base 431 / new 83 pass, 3x identical both modes |
| 2026-09-17 | R6 mutant: watch discovery only for last listed root | only the new multi-root watch test fails |
| 2026-09-17 | R6 test.sh write-failure checks | unwritable dir exit 1, read-only file exit 1, normal run exit 0 |
| 2026-09-17 | R6 Docker as root and as uid 1000 (--network none) | identical: base 431/0, new 83 fail; + solution 431/0 and 83/0 |

## Batch 1 - 2026-09-17 (8 x Nova, R6 artifacts)

| Run | Verdict | New tests | Approach | Counterfactual (agent patch + static files(Path) shim, R6 tests) |
|---|---|---|---|---|
| Nova #8 | FAIL_TEST_MISMATCH | 0/83 (compile) | `files()` instance accessor (record component) | counterfactual w/ shim: 82/83, misses same-file remove |
| Nova #7 | FAIL_INTEGRATION_ERROR | 0/83 (compile) | `files` record component | counterfactual: 83/83 PASS |
| Nova #6 | FAIL_INTEGRATION_ERROR | 0/83 (compile) | `files` record component | counterfactual: 81/83, same-file remove + absolute string extends |
| Nova #5 | FAIL_INTEGRATION_ERROR | 0/83 (compile) | `files` record component; `load(List<?>)` | counterfactual: 81/83, missing list entry threw IllegalArgumentException + same-file remove |
| Nova #4 | FAIL_INTEGRATION_ERROR | 0/83 (verifier Maven) | `files()` accessor; ran core `mvn install` without -Pflatten, poisoning /opt/m2 | counterfactual: 82/83, standalone bundled examples in validator |
| Nova #3 | FAIL_INTEGRATION_ERROR | 0/83 (compile) | `files()` accessor; `load(Collection<String>)` + `load(List<Path>)` | counterfactual: 82/83, same-file remove |
| Nova #2 | FAIL_INTEGRATION_ERROR | 0/83 (compile) | `files` record component | counterfactual: 80/83, same-file remove + absolute string extends + standalone bundled examples |
| Nova #1 | FAIL_INTEGRATION_ERROR | 0/83 (compile) | `files` record component | counterfactual: 83/83 PASS |

Measured pass rate: 0/8, and it measured nothing: every run lost all 83 tests to one test-compile
error (or, in #4, a verifier Maven failure the agent caused), so no behavior was graded.

Counterfactual pass rate with the signature ambiguity removed: 2/8 = 25%.

Kill counts in the counterfactual: `remove_of_layer_added_by_the_same_file_is_an_error` 5,
`string_loaded_schema_with_absolute_extends_composes` 2, `validator_resolves_examples_of_a_standalone_bundled_schema` 2,
`load_list_with_a_missing_entry_names_it` 1. Every failer misses by 1-3 tests.

| Date | Check | Result |
|---|---|---|
| 2026-09-17 | R7 clean room, base + test.patch | base 431 pass / new 83 fail |
| 2026-09-17 | R7 clean room, + solution.patch | base 431 / new 83 pass, 3x identical both modes |
| 2026-09-17 | R7 harness vs agent-poisoned /opt/m2 (r6 image, uid 1000, agent's exact install) | old test.sh: 1 synthetic case, exit 1; new: base 431/0, new 83/0 with solution |
| 2026-09-17 | R7 Docker as root and as uid 1000 (--network none) | identical: base 431/0, new 83 fail; + solution 431/0 and 83/0 |

## Batch 2 - 2026-09-18 (10 x Nova, R7 artifacts) - ACCEPTED at 3/10

| Run | Verdict | New tests failed | Human-eff LOC | Note |
|---|---|---|---|---|
| rd78ak5h | PASS_LEGITIMATE | 0/83 | 499 | static files/load, own tests; FP genuine (one judge dissent: directory named power.yml, overruled) |
| rd7evswb | FAIL_MISSED_REQUIREMENT | 1/83 | - | same-file add-then-remove accepted (live map check); sole failure |
| rd7fxt4h | PASS_LEGITIMATE | 0/83 | 454 | FP genuine, no dissent |
| rd70p6bc | FAIL_MISSED_REQUIREMENT | 2/83 | - | same-file removal + rejected remove:false with other fields |
| rd75wbrt | FAIL_MISSED_REQUIREMENT | 1/83 | - | same-file add-then-remove accepted; sole failure |
| rd78hnxn | FAIL_MISSED_REQUIREMENT | 1/83 | - | same-file add-then-remove accepted; sole failure |
| rd73pngb | FAIL_MISSED_REQUIREMENT | 2/83 | - | same-file removal + standalone bundled examples resolved on disk |
| rd746wb2 | FAIL_MISSED_REQUIREMENT | 2/83 | - | same-file removal + standalone bundled examples resolved on disk |
| rd7b32vn | PASS_LEGITIMATE | 0/83 | 495 | FP genuine (one judge dissent: absolute /samples/ examples path, overruled) |
| rd7es6yf | FAIL_MISSED_REQUIREMENT | 2/83 | - | same-file removal + standalone bundled examples resolved on disk |

All 10 runs distinct (fingerprinted by run ID, patch hash, prompt tokens); none re-listed from batch 1.
Every run passed 431/431 base. Kill table: `remove_of_layer_added_by_the_same_file_is_an_error` 7,
`validator_resolves_examples_of_a_standalone_bundled_schema` 3, `remove_false_behaves_like_override` 1;
80 of 83 tests killed nothing. Every evaluator: `description_clear: true`, difficulty "challenging".
Passers 68-112 messages (per Auto Review); prompt tokens 5.3M-11.8M across the batch.
