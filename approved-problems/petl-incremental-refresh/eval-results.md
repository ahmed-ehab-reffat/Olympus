# eval-results.md — petl-incremental-refresh

## Local validation

| check | result |
| --- | --- |
| vanilla suite in base image (offline, unpatched repo) | 537 passed, 18 skipped, 2.9 s |
| base mode on base | PASS (555 cases, 0 failures) |
| new mode on base | FAIL (134 cases, 134 individual failures, 0 collection errors) |
| base mode with solution | PASS (555 cases, 0 failures) |
| new mode with solution | PASS (134 cases) |
| Environment Quality proxy (`python -m pytest` in the solution image) | 671 passed, 18 skipped |
| patches apply in both orders, unapply cleanly | PASS |
| flakiness, base 5x and new 5x inside the image | identical every run (3x again after the review round) |
| effective LOC (Counter 2, hook `human-effective`) | 518 across 7 files (727 raw) |
| differential fuzz vs from-scratch evaluation | 1200 random expressions x random append steps, 0 mismatches (400 re-run after the select change) |
| mutation / trap proof | 29 divergent implementations, 29 killed (one further mutant proved equivalent and was dropped) |
| FP audit | round 14: a passing agent was flagged and the missing discriminator was added (shared node into both sides of a cat) |
| Test Fairness | round 3: 3 of 97 flagged on checkpoint representation, closed in the description; round 7 re-run flagged an assertion already removed in round 6 (stale patch); round 11 flagged two discard assertions, both fixed |

## Mutation table

| mutant | killed by |
| --- | --- |
| M1 set-difference deltas instead of multiset | cut_keeps_rows_that_become_equal, distinct_reports_nothing_for_a_repeat, added_counts_duplicates |
| M2 row cache ignores the occurrence index | select_visits_each_duplicate_row |
| M3 row-wise nodes re-apply their callable | select_does_not_revisit_rows_on_refresh (+5) |
| M4 feed re-reads from the start | refresh_reads_only_the_new_rows |
| M5 aggregate recomputes every group | aggregate_leaves_untouched_groups_alone, a_resumed_aggregate_keeps_its_groups |
| M6 aggregate output in insertion order | aggregate_places_a_new_group_by_key |
| M7 join ignores a right-side change | join_takes_in_a_new_right_row, leftjoin_retracts_the_filled_row_when_a_match_arrives |
| M8 join blocks in discovery order | leftjoin_matches_a_from_scratch_evaluation |
| M9 pre-order node numbering | 76 tests |
| M10 a shared table becomes two nodes | plan_shared_feed_is_one_node |
| M11 no rollback of a failed refresh | a_failing_refresh_is_retried_by_the_next_one |
| M12 emitted counts additions only | aggregate_replaces_the_row_of_a_changed_group, emitted_of_the_last_node_matches_the_reported_rows |
| M13 iteration recomputes on the fly | appended_rows_are_invisible_until_refresh, a_failing_refresh_leaves_the_output_alone |
| M14 resume re-reads the feed | resuming_does_not_apply_the_callables_again (+2) |
| M15 resume drops the callable cache | resuming_does_not_apply_the_callables_again |
| M16 resume accepts any plan | resuming_against_another_plan_is_refused |
| M17 constructor wrappers left in the plan | distinct_reports_nothing_for_a_repeat |
| M18 removed never reported | head_window_drops_the_row_it_pushes_out (+4) |
| M19 removed scanned newest first | removed_follows_the_previous_output_with_duplicates |
| M20 plan children joined without a space | plan_join_walks_left_before_right (+3) |
| M21 emitted drops the idle nodes | refresh_without_new_rows_reports_nothing (+5) |
| M22 rollback restores only the feeds | a_failure_rolls_every_node_back |
| M23 checkpoint keeps rows as tuples | a_checkpoint_holds_plain_state_for_every_node |
| M24 checkpoint scatters node state | a_checkpoint_survives_a_json_round_trip (+8, through resume) |
| M25 deltas report the latest copies | added_takes_the_earliest_occurrence_of_a_repeated_row |
| M26 feed ignores discards | a_discarded_row_leaves_the_output (+9) |
| M27 pipeline node only takes gains | an_outer_pipeline_takes_in_what_the_inner_one_lost (+3) |
| M28 cached copies are never retired | a_copy_added_after_a_discard_is_worked_out_again |
| M30 copies collapse to the last result | a_shared_node_on_both_sides_of_a_cat_keeps_each_copy_apart, ..._keeps_growing |

Third suggestion round, all three taken (97 -> 100): the checkpoint test now finds the mapping that
holds every node id, rather than only that the id occurs somewhere; the assertion deliberately pins
neither the level that mapping sits at nor the shape of a node's state, because the description
promises neither (Description Quality ruled the first over-specification, Test Quality the second); a feed-only test walks five append and refresh cycles
and pins `rows_read` after each, idle refreshes included; and a checkpoint taken before a failing
refresh is asserted equal to the one taken after it, and different after the successful retry, which
catches state leaking out of a node's caches rather than only out of its output.

M8 survived one run in three once the suite grew: that mutant reads a `set` of join keys, and
Python randomizes string hashing per process, so it is only sometimes wrong. The join key-order
test now feeds four keys in a non-sorted order and three consecutive mutation runs kill all 23.
The reference itself never depends on set order - every keyed node emits through `sorted`.

## Alignment review round (AI check: problem and tests aligned, two interface warnings)

Both warnings were real hidden requirements and were fixed in the description, not in the tests:
the plan line joins child ids with a comma AND a space, and `emitted` carries an entry for every
node on every refresh, zero included. Mutants M20 and M21 now guard those two sentences. The three
coverage suggestions were taken as written: `removed` ordering with duplicates (M19 guards it), the
physical read count of a feed reached by two branches, and a checkpoint carried across a pipeline
holding cat, distinct, head, addfield, convert and leftjoin at once. 91 tests -> 94.

Second suggestion round, all three taken (94 -> 97): the checkpoint is now asserted structurally
(every plan node id appears as a key, every nested value is a list, mapping, string, number,
boolean or None) instead of only through a JSON round trip; a refresh now fails at the top of a
five node plan after two feeds, a join and an aggregate have already moved, and the retry pins the
emission count of every one of them; and `rows_from` is checked at 0, at the end of the feed and
repeatedly, with its exact `rows_read` increments. Mutants M22 (rollback restores only the feeds)
and M23 (checkpoint keeps rows as tuples) guard the first two.

M11 survived the first pass: the failed refresh left the feed node advanced, and every assertion at
the time only looked at the output, which the exception had not reached. The retry test now pins the
next refresh's `emitted` and `rows_read`, which is what the meta sentence actually promises.

## Agent runs

### Batch 1 (Nova x4, against the 109-test version)

| agent | verdict | new tests | failed tests | LOC | approach |
| --- | --- | --- | --- | --- | --- |
| Nova 1 | FAIL_MISSED_REQUIREMENT | 108/109 | added_takes_the_earliest_occurrence_of_a_repeated_row | 1067 added | one `petl/incremental.py` plus hooks in basics/dedup/joins/reductions |
| Nova 2 | FAIL_MISSED_REQUIREMENT | 106/109 | same, plus a_failing_refresh_is_retried_by_the_next_one and a_failing_aggregation_rolls_its_groups_back | 1079 added | same shape |
| Nova 3 | FAIL_MISSED_REQUIREMENT | 108/109 | same one | 1159 added | same shape |
| Nova 4 | FAIL_MISSED_REQUIREMENT | 108/109 | same one | 1304 added | same shape |

0 of 4 passed, but the batch says the opposite of what the rate suggests: three of four solvers
built the whole engine (plan, deltas, callables, rollback, checkpoint, resume, every transform) and
died on ONE assertion, and all four died on the SAME one, choosing the same alternative reading of
the duplicate-order rule. The evaluator called the description clear and the tests deterministic in
all four runs, so this was not an unfair trap, it was an arbitrary convention doing all the work.

Two conclusions, both acted on:
- The ordering rule had to stop being the discriminator. Round 9 had already rewritten it to be
  mechanical, which converts these four into passes and would have put the rate near 100%.
- The engine itself is not hard for Nova. Round 10 therefore added two surfaces the batch shows
  none of them had to build: rows leaving a feed (`discard`), and a pipeline standing where a feed
  does, which is the only way an inner output can shrink under an outer plan.
