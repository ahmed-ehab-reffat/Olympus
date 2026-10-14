# asdf-conversion-free-lazy-tree - eval results

No platform batch yet.

## Local validation (SLICE, 2026-09-26)

Image `factory-asdf-conversion-free-lazy-tree` built from a fresh clone at BASE (with .git) in
~65 s (base image cached). Clean room: `git apply test.patch`, run, `git apply solution.patch`, run;
`--network none`.

| uid | tree | mode | rc | cases | failed | skipped |
|---|---|---|---|---|---|---|
| 1000 | base + test.patch | base | 0 | 2196 | 0 | 2 |
| 1000 | base + test.patch | new | 1 | 11 | 11 | 0 |
| 1000 | + solution.patch | base | 0 | 2196 | 0 | 2 |
| 1000 | + solution.patch | new | 0 | 11 | 0 | 0 |
| 0 | base + test.patch | base | 0 | 2196 | 0 | 3 |
| 0 | base + test.patch | new | 1 | 11 | 11 | 0 |
| 0 | + solution.patch | base | 0 | 2196 | 0 | 3 |
| 0 | + solution.patch | new | 0 | 11 | 0 | 0 |
| 4242 | base + test.patch | base | 0 | 2196 | 0 | 2 |
| 4242 | base + test.patch | new | 1 | 11 | 11 | 0 |
| 4242 | + solution.patch | base | 0 | 2196 | 0 | 2 |
| 4242 | + solution.patch | new | 0 | 11 | 0 | 0 |

(skipped = 2 xfail, plus one root-only permission skip in `test_api.py` when running as root.)

- Both patch orders apply and reverse-apply cleanly; test.sh is `new file mode 100755`.
- JUnit: no `::` in ids, no duplicate ids (2196 base, 11 new).
- LOC hook: human-effective 367, raw 443, padding-floor 300, 6 files.
- Repo lint (ruff 0.16.0 check + format, codespell, flynt) clean on every changed file.
- Mutant M1 (search/info convert outside the tree): killed by 3 tests
  (`test_filter_only_sees_nodes_the_key_accepts`, `test_edit_made_through_a_search_result_is_written`,
  `test_alias_reached_through_search_stays_one_object`).
- Flakiness 3x: not run in the slice (owed in FINISH). Local base suite ran 5 times identical
  (2194 passed / 2 xfailed).

## Local validation (review-feedback round, 2026-09-29)

Image `asdf-lazy-val` from a fresh clone at BASE; `--network none`.

| uid | base mode (sol) | new on base | new with sol |
|---|---|---|---|
| 1000 | 2196 / 0 failed / 2 skipped | 13/13 fail | 13/13 pass |
| 0 | 2196 / 0 failed / 3 skipped | 13/13 fail | 13/13 pass |
| 4242 | 2196 / 0 failed / 2 skipped | 13/13 fail | 13/13 pass |

- Mutant old `_is_ndarray` (TaggedDict only): killed by `test_write_keeps_list_form_arrays_and_honours_storage` only.
- Mutant `has_private_blocks` always False: killed by `test_block_no_array_refers_to_converts_untouched_nodes` only.
- New tests 5x identical. LOC hook human-effective 371 (padding-floor 301).

## Local validation (round 2, 2026-09-29)

| uid | base mode (sol) | new on base | new with sol |
|---|---|---|---|
| 1000 | 2196 / 0 failed / 2 skipped | 20/20 fail | 20/20 pass |
| 0 | 2196 / 0 failed / 3 skipped | 20/20 fail | 20/20 pass |
| 4242 | 2196 / 0 failed / 2 skipped | 20/20 fail | 20/20 pass |

- Mutants: version gate restored, conversion under the write-time manager, raw pass-through of tags the written version lacks: each killed by `test_write_to_another_standard_version_keeps_untouched_nodes` only. Multi-type via types[0]: killed by `test_info_converts_nodes_whose_object_is_needed` only.
- New tests 5x identical. LOC hook human-effective 383.

## Local validation (round 3, 2026-09-29)

Clean room uid 1000/0/4242: base mode 2196 unchanged, new 22/22 fail on base, 22/22 pass with the solution. New tests 5x identical. Mutants (manager-only read context, unresolved string type -> conversion, tuple not a container) each killed by exactly its targeted test. human-effective 401.

## Local validation (round 4, 2026-09-29)

Clean room uid 1000/0/4242: base mode 2196 unchanged, new 25/25 fail on base, 25/25 pass with the solution. New tests 5x identical. Mutants (history deepcopy restored, history shared without a copy, TaggedString returned before extension bookkeeping) each killed by its targeted test. human-effective 412.

## Batch 1 (2026-09-30): 0/11 (10 Nova + 1 Vega)

Saved in `agent-runs/1/`. New-test failures per run (32 new tests). Two Nova runs also broke the base suite.

| Run | Base | Failed | Failed tests (short) | Note |
|---|---|---|---|---|
| Vega #1 | ok | 2 | both private-block tests | implements the rule (`_has_unreferenced_blocks`) and converts, but writes the converted node with its READ tag (thing-1.0.0); tests used re-tag 1.1 as the only conversion witness |
| Nova #7 | ok | 3 | alias via search, update renumbering (buffer too small), container triggers | |
| Nova #3 | ok | 7 | chained filter order, search-result edit, container triggers, iteration, schema_info triggers, import path resolved, Keeper | |
| Nova #5 | FAIL | 9 | array info, update renumbering, container triggers, unknown tag, version x2, schema_info, import path, Keeper | |
| Nova #4 | ok | 10 | search order / filter / value, alias, list-form, container + schema triggers | |
| Nova #8 | ok | 11 | array info, type search, update renumber, private-block update, triggers, version x2, history, block arrays | |
| Nova #2 | ok | 11 | | |
| Nova #1 | FAIL | 11 | | |
| Nova #10 | ok | 13 | | |
| Nova #6 | FAIL | 17 | | |
| Nova #9 | ok | 18 | | |

Kill counts (top): container triggers 9, import path resolved 8, update renumbering 7, untouched ndarray info 7, schema_info triggers 7, alias / iteration / search edit / version 6 each, private block 5.

Replay cut analysis: the only single-family cut that yields a pass is the private-block pair (Vega). Nova #7 needs 3 families cut.

Round 14 (test-only, re-eval eligible): the private-block tests now witness conversion with the Thing converter call log (plain file: no call and thing-1.0.0 kept; converter-owned block: converter called), no tag demand in the private case. Plus unknown-tag search (`search(key="^z$")` same as reference) and the widget extension recorded in history (Auto Review T4 + advisory). Local replay of all 11 saved patches on the new suite: Vega 32/32, every other run unchanged or fewer failures, none newly failing. Expected re-eval: 1/11.

## Batch 7 (2026-10-04): 0 genuine / 16 (re-eval of batch 6's 10 Nova + 5 fresh Nova + 1 fresh Vega)

Saved in `agent-runs/7/`. Suite = round 22 (27 tests). The user meant to skip the re-eval but it ran with the fresh runs.

| Run | Verdict | Failed | Failed tests (short) |
|---|---|---|---|
| Vega #1 (fresh) | PASS, then FP | 0 | FP panel: write converts untouched multi-type nodes (`len(converter.types) != 1` in `_walker`), history always preserved (`_preserve_unconverted=True`) even with blocks |
| Nova #6 re-eval | fail | 1 | Keeper converted-container write |
| Nova #2 (fresh) | fail | 1 | container triggers |
| Nova #4 re-eval | fail | 2 | container triggers, alias |
| Nova #2 re-eval | fail | 2 | superclass type_, alias |
| Nova #5 (fresh) | fail | 3 | container triggers, value criterion, Keeper |
| Nova #1 re-eval | fail | 3 | container triggers, Keeper, alias |
| Nova #3 (fresh) | fail | 3 | superclass type_, Keeper, alias |
| Nova #4 (fresh) | fail | 4 | container triggers, search-result render, shared block, alias |
| Nova #10 re-eval | fail | 4 | superclass type_, container triggers, import path, alias |
| Nova #7 re-eval | fail | 4 | container triggers, schema_info, Keeper, alias |
| Nova #1 (fresh) | fail | 6 | info, container triggers, unknown tag, import path x2, update with blocks |
| Nova #8 re-eval | fail | 6 | info rendering, container triggers, import path x2, update with blocks, alias |
| Nova #5 re-eval | fail | 9 | info / schema_info / search rendering stop at the tagged root |
| Nova #9 re-eval | fail | 10 | search semantics broadly |
| Nova #3 re-eval | fail | 10 | info, triggers, history, import path, alias |

Round 23 (test-only): replay of all 16 patches on the 28-test suite. Vega #1 now fails exactly the two FP tests. The history-with-blocks case also newly fails 9 Nova runs (every one: `assert 5 in []`, history kept unconverted in a block file), and Nova #3 re-eval also fails the multi-type test. Closest runs after the change: Nova #6 re-eval 1 fail (Keeper), Nova #4 re-eval 2, Nova #2 fresh 2. Old Vega (batches 1-3) fails 4 (block-file family).

## Batch 8 (2026-10-09, new models): Nova 0/8, Orion 1/4 in the 18:01 batch (2/5 counting the 18:26 run)

Saved in `agent-runs/8/`. Suite = round 23 (28 tests). Sequence length from the trajectory's own `sequence_length`.

| Run | Verdict | Failed | Failed tests (short) | seq len |
|---|---|---|---|---|
| Nova #1 | fail | 2 | history with blocks, alias | 1,685,025 |
| Nova #2 | fail | 15 | write path broadly (copy converts everything) | 848,600 |
| Nova #3 | fail | 4 | history, search render/replace, update with blocks, alias | 739,770 |
| Nova #4 | fail | 2 | history (deepcopy converts), alias | 876,314 |
| Nova #5 | fail | 1 | history (converts history on write) | 722,882 |
| Nova #6 | fail | 1 | history (exempted from block conversion) | 742,833 |
| Nova #7 | fail | 4 | container triggers, unknown tag, history, Keeper | 894,350 |
| Nova #8 | fail | 4 | container triggers, history, schema_info, update with blocks | 921,388 |
| Orion #1 (18:01) | fail | 1 | container triggers (Pair tuple -> plain tuple on write) | 114,078 |
| Orion #2 (18:01) | fail (did not complete on platform) | 0 locally | junit 28/28, no eval verdict | 109,591 |
| Orion #3 (18:01) | fail | 1 | unknown tags converted in info | 122,687 |
| Orion #4 (18:01) | PASS | 0 | | 126,694 |
| Orion #1 (18:26) | PASS | 0 | | 113,954 |

Nova avg sequence length 928,895 (min 722,882), gate > 256k. History-with-blocks (round 23) fails 7/8 Nova and is the only failure for Nova #5 and #6.

Probe battery (`worktrees/_asdf_tools/probes/battery.py`, 19 cells not pinned by tests: open-time vs write-time blocks both ways, search repr of to_info nodes, str type_ on class, slicing / len / values iteration, double write, multi-type key search and history extensions, replace then write): all 5 Orion runs, Nova #5/#6 and the batch-7 Vega match the reference on every cell. No FP gap found in the passers, and no fair test-only lever either.

## Batch 9 (2026-10-10): 2 more Orion, both PASS -> Orion 4/7 (too easy)

| Run | Verdict | seq len |
|---|---|---|
| Orion #2 | PASS 28/28 | 120,309 |
| Orion #1 | PASS 28/28 | 461,345 |

Both match the reference on both probe sets (51 cells, 0 diffs). Probe `probes/validate.py`: all four Orion passers validate a lazy file without converting untouched nodes; the reference's `validate()` converts them and crashes on a bad node (meta never mentions validation, so no FP; reference gap only).

Round 24 lever replay (`probes/tests_version.py`, the cut version-migration rule adapted to no-block files): reference 3/3; every saved run (8 Nova, 7 Orion) passes the plain keep-tags cell and fails both "tag missing from the target version" cells (upgrade, downgrade). Upper bound only (L35): the rule was unstated when these runs solved.

## Round 25 replay (2026-10-10)

The 15 saved runs from batches 8 and 9 were replayed against the changed tests (external storage for embedded arrays; converter-selected tag when blocks force conversion). 14 of 15 pass; Nova #7 fails, as it did before. In the extension-removal probe, all 15 keep the original tag. The changes close Auto Review gaps and do not move the pass rate.

## Batch 10 (2026-10-10, round 25 meta + tests): Nova 0/8, Orion 3/4 (too easy), Nova avg sequence 951,787

| Run | Verdict | New tests | Failed tests | Sequence |
|---|---|---|---|---|
| Nova #1 | FAIL_MISSED_REQUIREMENT | 30/31 | history_entries | 1,154,616 |
| Nova #2 | FAIL_WRONG_LOGIC | 11/31 | 20 (search/write core) | 1,080,291 |
| Nova #3 | FAIL_MISSED_REQUIREMENT | 26/31 | search_by_type, info_and_search_convert, import_path, history, every_alias | 878,772 |
| Nova #4 | FAIL_WRONG_LOGIC | 25/31 | chained_search, edit_via_result, info_and_search_convert, iteration_and_search_nodes, history, every_alias | 984,112 |
| Nova #5 | FAIL_MISSED_REQUIREMENT | 29/31 | edit_via_result, every_alias | 736,824 |
| Nova #6 | FAIL_WRONG_LOGIC | 30/31 | every_alias | 1,314,618 |
| Nova #7 | FAIL_WRONG_LOGIC | 28/31 | search_results_render, update_with_blocks, every_alias | 743,456 |
| Nova #8 | FAIL_MISSED_REQUIREMENT | 27/31 | version upgrade+downgrade, history, every_alias | 721,606 |
| Orion #1 | PASS | 31/31 | | 129,302 |
| Orion #2 | PASS | 31/31 | | 125,550 |
| Orion #3 | PASS | 31/31 | | 115,655 |
| Orion #4 | FAIL_MISSED_REQUIREMENT | 30/31 | unknown_tags (converts unknown tags in info, AsdfConversionWarning) | 110,891 |

- The restored version rule killed no Orion (4/4 pass both version cases). Nova #8 died on it.
- `every_alias` killed 6/8 Nova and `history` 5/8.

Differential probes (`probes/battery{,2,3,4,5}.py`, `validate.py`, `r25.py`, `recursive2.py`; outputs in `probes/out/b10/`), run on the reference vs Orion 1-4:
- battery 1-4 plus 25 new cells (list index/slice, dict get/values, chains, value/filter, type_ by string, blocks, inline threshold, versions with arrays, coins, widgets, history, replace): **no divergence**. The only exception is Orion #3 labelling lazy list items `[0]` where base prints `0`. That matches eager mode, so testing it would penalise a fix, and it is not a lever.
- Extension removal after open (`r25.py`): all 4 Orion crash. A test would make Orion 0/4 and nothing would split, so it is not used.
- **Shared plain containers (YAML aliases) after a plain index access** (`battery5.py`): Orion #1-#3 write duplicate copies on write_to and update, also for deep cycles. Base (without the bad node) keeps the sharing in every cell, and so do the reference and Orion #4. In batches 8/9, 6 of 7 Orion runs kept the sharing. Every Nova run loses it.

Round 26 replay (new test `test_shared_containers_stay_shared_after_they_are_accessed`): reference 32/32; base 32/32 fail; Orion #1-#3 fail only the new test; Orion #4 passes it and still fails unknown_tags; every Nova run still fails. Re-eval prediction: Nova 0/8, Orion 0/4.

## Round 27 replay (2026-10-10, scope cut for the requirement-count gate, 25 tests)

| Saved run | Result on round-27 suite |
|---|---|
| reference | 25/25 |
| base | 0/25 |
| Nova (b8 x8, b10 x8) | all fail (each loses alias sharing, plus history / every_alias / others) |
| Orion b8 #1, b9 #1 | PASS |
| Orion b8 #2, #4, #5 | fail info_and_search_convert (asdf_library children hidden; #5 Pair tuple) |
| Orion b8 #3, b10 #4 | fail unknown_tags |
| Orion b9 #2 | fail shared_containers + info_and_search_convert |
| Orion b10 #1-#3 | fail shared_containers |

Orion 2/11 = 18%, an upper-bound estimate because the runs solved under different metas.

## Batch 11 (2026-10-11, round 27 meta + r29 reference, 25 tests): Nova 0/8, Orion 0/8, Vega 0/4, Nova avg sequence 902,459

| Run | Verdict | New tests | Failed tests | Sequence |
|---|---|---|---|---|
| Nova #1 | FAIL_WRONG_LOGIC | 19/25 | edit_via_result, iteration_and_search_nodes, history, block_shared, every_alias, shared_containers | 743,270 |
| Nova #2 | FAIL_WRONG_LOGIC | 22/25 | info_and_search_convert, schema_info_converts, shared_containers | 828,512 |
| Nova #3 | FAIL_WRONG_LOGIC | 20/25 | history, update_with_blocks, block_shared, every_alias, shared_containers | 981,551 |
| Nova #4 | FAIL_WRONG_LOGIC | 21/25 | info_and_search_convert, schema_info_converts, every_alias, shared_containers | 1,111,331 |
| Nova #5 | FAIL_WRONG_LOGIC | 22/25 | update_with_blocks, block_shared, shared_containers | 878,816 |
| Nova #6 | FAIL_WRONG_LOGIC | 18/25 | chained_search, edit_via_result, iteration_and_search_nodes, history, update_with_blocks, block_shared, shared_containers | 766,922 |
| Nova #7 | FAIL_WRONG_LOGIC | 20/25 | chained_search, edit_via_result, iteration_and_search_nodes, history, shared_containers | 742,093 |
| Nova #8 | FAIL_WRONG_LOGIC | 23/25 | every_alias, shared_containers | 1,167,178 |
| Orion #1 | FAIL_REGRESSION | 23/25 | info_and_search_convert (Software schema title appended), shared_containers | 115,801 |
| Orion #2 | FAIL_REGRESSION | 24/25 | shared_containers | 119,740 |
| Orion #3 | FAIL_MISSED_REQUIREMENT | 23/25 | unknown_tags (warning), shared_containers | 104,794 |
| Orion #4 | FAIL_REGRESSION | 22/25 | info_and_search_convert, converted_container_objects, shared_containers | 130,158 |
| Orion #5 | FAIL_MISSED_REQUIREMENT | 24/25 | unknown_tags (warning only) | 139,504 |
| Orion #6 | FAIL_REGRESSION | 22/25 | info_and_search_convert, unknown_tags, shared_containers | 148,777 |
| Orion #7 | FAIL_REGRESSION | 24/25 | shared_containers | 110,144 |
| Orion #8 | FAIL_MISSED_REQUIREMENT | 23/25 | info_and_search_convert, unknown_tags | 117,169 |
| Vega #1 | FAIL_TEST_MISMATCH | 24/25 | unknown_tags (warning only) | 188,747 |
| Vega #2 | FAIL_TEST_MISMATCH | 24/25 | unknown_tags (warning only) | 204,003 |
| Vega #3 | FAIL_REGRESSION | 23/25 | unknown_tags, shared_containers | 187,398 |
| Vega #4 | FAIL_TEST_MISMATCH | 24/25 | unknown_tags (warning only) | 150,305 |

- `unknown_tags` died on the first `info()` call: the agents' lazy info still converts an unknown-tag node, base emits `AsdfConversionWarning`, and pytest's `filterwarnings = error` turns it into a failure. The three Vega graders called it a verifier problem (agentBlameUnfair, "as they are now" includes the base warning). The Orion graders called it a missed requirement. Same failure as b8 #3 and b10 #4.
- `shared_containers` killed 6/8 Orion, all 8 Nova and Vega #3; graders class it as a regression of the existing alias invariant (fair).

### Round 30 replay (warning-agnostic unknown_tags + multi-type info/key-search check)

| Saved run | Result |
|---|---|
| reference | 25/25 |
| base | 0/25 |
| Nova #1-#8 | all fail, same tests as live |
| Orion #5 | PASS |
| Orion #1-#4, #6, #7 | fail shared_containers (+ info_and_search_convert on #1, #4, #6) |
| Orion #8 | fail info_and_search_convert (asdf_library line) |
| Vega #2, #4 | PASS |
| Vega #1 | fail multiple_type_converters (info() raises the bad coin's ValueError) |
| Vega #3 | fail multiple_type_converters + shared_containers |

Re-eval prediction: Nova 0/8, Orion 1/8 (12.5%), Vega 2/4.
Probes (`probes/out/b11/`) on Orion #5, #8 and Vega #1, #2, #4 against the reference: all other divergences fall in cut rules (multi-type naming, ndarray class naming, external storage, list-form threshold, `[0]` labels, validate()).

### Re-eval of batch 11 on round 30 (2026-10-11): Orion 1/8, Vega 2/4, Orion/Vega gate PASSED

Matches the replay exactly. The platform check "at least 4 runs on Orion or 4 runs on Vega, solved >0% and <=25%" passed on Orion 1/8 even though Vega read 2/4: one qualifying agent is enough.

## Batch 12 = accepted pool (2026-10-11): re-grade of batch 11 on round 30. Nova 0/8, Orion 1/8, Vega 2/4; ACCEPTED

Saved in `agent-runs/12/` (Orion runs renumbered: b12 Orion #1 = b11 Orion #5). Per-test kills over 20 runs
(Nova/Orion/Vega): shared_containers 15 (8/6/1), info_and_search_convert 6 (2/4/0), history 4, block_shared 4,
every_alias 4 (Nova only), edit_via_result 3, iteration_and_search_nodes 3, update_with_blocks 3, schema_info 2,
chained_search 2 (Nova only), multiple_type_converters 2 (Vega only), converted_container_objects 1 (Orion).
Killed nothing: 13 of 25. Nova sequence length avg 902,459 (742k-1.17M); Orion 105k-149k; Vega 150k-204k.
FP panel: Orion #1, Vega #1 and Vega #2 genuine (adjudicators high confidence; one Orion judge dissent on an
unimported string type path that fails the reference too).
