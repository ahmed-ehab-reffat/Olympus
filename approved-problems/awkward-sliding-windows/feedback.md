# feedback.md - awkward-sliding-windows

Tier: Olympus. Category: feature_request. Status: batch 1 ran 0/10 on a description bug, now fixed;
batch 2 ran 1/10, so the problem is solvable and in band. Auto Review requested revision for one real
bug in the reference (padded windows over strings), fixed here.

## Pick

Repo: scikit-hep/awkward, BSD-3-Clause, 973 stars, active (commits daily through 2026-08), pure
Python surface. Base commit `cd90c720495366ea8b53be722c0624cb07004c97` (2026-07-27).

Gates run at pick time:

- License: BSD-3-Clause read off the LICENSE file, in the allowed list.
- Stars / activity: 973 / commits in the last week. Niche scientific library (ragged arrays for
  particle physics), the opposite of the author-obvious profile that saturates.
- Fresh host: `awkward` appears in none of `Aprroved/`, `problems/`, `rejected/`, `worktrees/`,
  `Olympus/problems/` or `Task*/problems/`. No ragged-array, sliding-window or rolling-window
  problem in the local corpus either.
- Not saturated: not in `SATURATED-REPOS.md`.
- Environment quality: the vanilla suite runs offline in `olympus-base-python` in 53s,
  4608 passed / 176 skipped / 0 failed, as uid 1000 with `--network none`.
- Exclusivity: `gh pr list` / `gh issue list -R scikit-hep/awkward --state all --search` over
  window, rolling, sliding, stride, chunked, segment, moving average, consecutive, adjacent,
  overlapping, pairwise, neighbour, n-grams: **zero** hits for this capability. All 30+ branches
  enumerated with `gh api repos/scikit-hep/awkward/branches` and compared against main; none touches
  a windowing capability.
- Behavioral f2p gap: `ak.windows` and `ak.unwindows` do not exist, and overlapping nested windows
  cannot be composed out of the existing surface (jagged slicing cannot produce an extra dimension
  of overlapping runs, and `ak.unflatten` needs disjoint counts).

### Base commit choice, and why it is not HEAD

`awkward` depends on a pinned binary wheel, `awkward_cpp==55`, and the repo's Python layer runs ahead
of the published kernels: at HEAD, 30 of the repo's own tests fail offline with `KeyError` on kernels
added by PR #4232 and #4256 in late July, which exist only in the (submodule-dependent, therefore
unbuildable here) `awkward-cpp` source tree. `cd90c720` is the last commit before that divergence and
its suite is fully green against the published wheel. The same constraint shapes the solution: no new
C++ kernel is possible, so all index arithmetic goes through `nplike`, which is also the reason the
typetracer path works at all.

### Candidates dropped before this one

| Candidate | Killed by |
| --- | --- |
| `ak.cumsum` / `ak.cumprod` on the same repo | EXCLUSIVITY. PR #1786 "feat: add `cumsum` and `cumprod`" (closed) publishes the diff, and issue #2676 "ak.cumsum" is open. Hard scope-gate reject; found before any authoring. |
| calyxir/calyx | 573 MB repo with a pinned 1.90 toolchain, proptest in the baseline, 173 open issues to beacon-check, and the pass framework is 30k LOC of unfamiliar FSM machinery. Iteration cost too high for the session. |
| Pyomo/pyomo | BSD-3 and unmined, but ~500k LOC with a multi-minute suite and `pyomo.common.download` tests that reach the network. |
| errata-ai/vale, crate-ci/typos | over the presumed-saturation star line / feature space is dictionary policy with beaconed issues. |
| zkat/miette, google/gnostic | fail the 12-month source-activity gate. |
| hannobraun/fornjot | 0BSD is not in the literal allowed license list. |
| scikit-hep/awkward at HEAD | see above: the vanilla suite is red offline against the published `awkward_cpp`. |

## Feature

Two operations sharing one window model. `ak.windows` replaces every list at an axis with the list of
its sliding windows; `ak.unwindows` lays those windows back over one another. Both thread through all
thirteen layout classes, both type-level rules (fixed-size windows, fixed-size window dimension), the
parameter-placement rule, the option-preservation rule and the typetracer backend.

Why it is not a duplicate: the nearest corpus problems are `risinglight-window-frames` and
`turso-window-functions` (SQL window frames over rows, an optimizer/executor feature) and
`similar-three-way-merge` (sequence diffing). Neither touches ragged-array structure, layout
recursion or an inverse round-trip law. No local problem uses awkward or any ragged-array library.

## Difficulty design

The geometry is short to state and has six combinations (two alignments times three incomplete
modes) whose arithmetic differs in every one; the integration is thirteen layout classes plus a
second backend. Traps, all mutation-proven (`DESIGN.md` section 11):

1. Right alignment anchors the grid at the end of the list, so the window set is derived from ends,
   not starts, and the cut-off window is the first one.
2. Right aligned padding goes at the front.
3. `"keep"` counts every window holding an element, not every window that fits.
4. `"drop"` and `"pad"` results are fixed-size lists; only `"keep"` is variable length.
5. A fixed-size input keeps a fixed-size window dimension.
6. List parameters move inward to the windows, and the new dimension carries none.
7. Missing lists must be carried through the option index, not projected away.
8. `ListArray` starts can be out of order, so the content cannot be read flat.
9. The typetracer backend needs its own branch, and a `to_list`-and-rebuild shortcut dies there
   because `ak.to_list` of a typetracer array raises.
10. The inverse must skip what the previous window already reached, restart that overlap at every
    list, and hand the windows' parameters to the rebuilt lists.

These are interdependent rather than stacked: fixing the alignment changes the counts, the counts
change the offsets, and the offsets decide which of the two type-level rules applies.

## Validation

| Check | Result |
| --- | --- |
| Vanilla suite, base commit, offline, uid 1000 | 4608 passed / 176 skipped |
| New tests on base + test.patch | 223 failed (every one fails; no vacuous pass) |
| New tests with solution.patch | 223 passed |
| Base suite with solution.patch | 4608 passed / 176 skipped, no regressions |
| Apply order test then solution, and solution then test | both apply clean |
| Determinism | base and new mode 5 runs each, identical every time |
| Batch 1 (Nova x10) | 0/10, all MISSED_REQUIREMENT, 161-175 of 181 passing; three tests failed 10/10 on one ambiguous clause |
| Batch 2 | 1/10 passed legitimately; failures at 169-191 of 192, all baseline-green, both clusters rated subtle but fair |
| Solvability after the fix | Nova #3's own code passes 181/181 and 4608 baseline with the three edits the corrected clause dictates |
| Solvability at 214 tests | the same agent tree passes 214/214 and 4608 baseline, satisfying every post-batch-2 requirement unaided |
| Solvability at 221 tests | that tree passes 221/221 and 4608 baseline after a fourth clause-dictated edit, `max(window_length - skip, 0)` |
| Solvability at 223 tests | unchanged, the same tree passes 223/223 |
| Independent oracle (model written from the prose alone) | 3205 random ragged cases, 0 mismatches; plus regular-input, structural-validity and typetracer-form batteries, 0 problems |
| Mutations | 19 run, 18 killed, 1 retired as arithmetically equivalent |
| human-effective LOC | 584 across 20 files |
| meta.md | 728 words, ASCII, no headers (hints by direction, conventions stated for alignment) |

## False-positive mapping

Every clause of `meta.md`, in order, with the tests that pin it. No clause is unasserted, and every
test traces back to a clause.

| meta.md clause | Tests |
| --- | --- |
| the two signatures, their defaults, and `highlevel` / `behavior` / `attrs` working as they do throughout the library, interception included | left_drop_windows_of_each_list, unwindows_lays_overlapping_windows_over_one_another, highlevel_false_gives_a_content, unwindows_highlevel_false_gives_a_content, low_level_output_ignores_behavior_and_attrs, unwindows_low_level_output_ignores_behavior_and_attrs, attrs_travel_with_the_result, behavior_travels_with_the_result, unwindows_attrs_travel_with_the_result, unwindows_behavior_travels_with_the_result, windows_takes_an_explicit_behavior_and_attrs, unwindows_takes_an_explicit_behavior_and_attrs, windows_dispatch_is_offered_the_array, unwindows_dispatch_is_offered_the_array, anything_to_layout_recognizes_is_accepted |
| a window is `size` adjacent elements | size_one_makes_every_element_a_window, size_equal_to_the_list_length_gives_one_window, left_drop_windows_of_each_list |
| consecutive windows begin `stride` apart | stride_two_starts_every_other_element, stride_wider_than_size_leaves_elements_out, stride_wider_than_the_list_gives_one_window, fixed_size_lists_with_stride |
| both are integers of at least one, numpy's own included; not an integer is a `TypeError` | a_fractional_size_is_a_type_error, a_fractional_stride_is_a_type_error, unwindows_fractional_stride_is_a_type_error, a_string_size_is_a_type_error, a_missing_size_is_a_type_error, a_string_stride_is_a_type_error, unwindows_string_stride_is_a_type_error, unwindows_missing_stride_is_a_type_error, a_boolean_size_is_a_type_error, a_boolean_stride_is_a_type_error, unwindows_boolean_stride_is_a_type_error, a_numpy_integer_size_is_accepted, a_numpy_integer_stride_is_accepted, unwindows_takes_a_numpy_integer_stride |
| a smaller one is a `ValueError` | size_below_one_is_a_value_error, negative_size_is_a_value_error, stride_below_one_is_a_value_error, negative_stride_is_a_value_error, unwindows_stride_below_one_is_a_value_error, unwindows_negative_stride_is_a_value_error |
| a value outside the named choices is a `ValueError` | an_unknown_incomplete_choice_is_a_value_error, an_unknown_align_choice_is_a_value_error, a_missing_incomplete_choice_is_a_value_error, a_missing_align_choice_is_a_value_error, a_numeric_incomplete_choice_is_a_value_error, a_numeric_align_choice_is_a_value_error |
| `axis` counts as elsewhere, negative included (including named axes and its own validation) | default_axis_windows_the_innermost_lists, axis_one_windows_the_outer_lists, axis_two_windows_the_inner_lists, negative_axis_two_is_the_same_as_axis_one, unwindows_default_axis_is_the_dimension_holding_the_windows, unwindows_at_axis_one, unwindows_negative_axis_two_is_the_innermost_window_dimension, unwindows_negative_axis_three_is_the_same_as_axis_one, named_axis_ak_windows, negative_named_axis_ak_windows, named_axis_ak_unwindows, negative_named_axis_ak_unwindows, unwindows_recovers_a_named_array |
| a depth the array does not have is an `AxisError` | an_axis_the_union_branches_disagree_about_is_an_axis_error, an_axis_past_the_shallowest_union_branch_is_an_axis_error, unwindows_an_axis_the_union_branches_disagree_about_is_an_axis_error, axis_beyond_the_depth_is_an_axis_error, axis_two_beyond_the_depth_is_an_axis_error, unwindows_axis_beyond_the_depth_is_an_axis_error, an_axis_too_far_below_the_depth_is_an_axis_error, unwindows_an_axis_too_far_below_the_depth_is_an_axis_error |
| at the outermost depth the array itself is windowed | axis_zero_windows_the_array_itself, a_flat_array_is_windowed_by_default, axis_zero_of_lists_keeps_the_lists_whole, axis_zero_with_keep_and_right_align, axis_zero_result_has_one_more_dimension, unwindows_at_axis_zero, unwindows_at_axis_zero_removes_a_dimension |
| one more dimension; each list becomes the list of its windows | left_drop_windows_of_each_list, dropped_windows_are_fixed_size_lists, the_number_of_windows_follows_the_stride, window_lengths_are_visible_through_num |
| ordered by where they begin | windows_come_in_the_order_they_begin, right_aligned_windows_come_in_the_order_they_begin |
| everything outside `axis` is left alone | dimensions_outside_axis_are_left_alone, axis_two_windows_the_inner_lists |
| `align="left"` lays them out from the start | left_drop_windows_of_each_list, keep_cuts_windows_off_at_the_end_of_the_list, pad_fills_the_end_of_a_cut_window |
| `align="right"` lays them out from the end | right_aligned_dropped_windows_end_at_the_last_element, right_aligned_windows_with_stride_three, right_aligned_keep_with_stride_two, both_alignments_give_the_same_number_of_windows |
| `"drop"` keeps only windows entirely inside | left_drop_windows_of_each_list, size_above_every_length_gives_no_windows, stride_wider_than_size_leaves_elements_out |
| `"keep"` keeps those holding an element, cut off | keep_cuts_windows_off_at_the_end_of_the_list, keep_of_a_list_shorter_than_size, keep_with_stride_two, keep_with_stride_wider_than_size, keep_and_drop_agree_when_size_is_one, right_aligned_keep_cuts_the_first_windows_off |
| `"pad"` fills to `size`, at the end left / the front right | pad_fills_the_end_of_a_cut_window, pad_with_stride_two, pad_of_a_list_shorter_than_size, pad_and_keep_produce_the_same_number_of_windows, right_aligned_pad_fills_the_front, right_aligned_pad_of_a_short_list, missing_values_inside_a_list_survive_padding, padded_windows_can_be_filled |
| a list shorter than `size` gives none under `"drop"` | size_above_every_length_gives_no_windows, fixed_size_lists_shorter_than_size_give_an_empty_dimension |
| an empty list gives none under all three | empty_list_gives_no_windows_when_dropping, keep_gives_an_empty_list_no_windows, pad_gives_an_empty_list_no_windows, an_empty_array_of_lists_has_no_windows, an_empty_array_of_lists_keeps_its_window_dimension, an_empty_array_of_windows_rebuilds_nothing |
| windows of exactly `size` are fixed size lists | dropped_windows_are_fixed_size_lists, padded_windows_are_fixed_size_and_optional, right_aligned_padded_windows_are_fixed_size_and_optional, fixed_size_lists_hold_the_expected_windows |
| cut off windows are variable length | kept_windows_are_variable_length_lists, fixed_size_lists_with_keep_have_variable_windows |
| the window dimension is fixed size when the input was | fixed_size_lists_give_a_fixed_size_window_dimension, fixed_size_lists_with_pad, fixed_size_lists_shorter_than_size_give_an_empty_dimension |
| list parameters, a string tag included, belong to the windows; a bytestring behaves like a string | a_parameter_moves_from_the_lists_to_the_windows, string_lists_are_windowed_into_strings, windowing_an_array_of_strings_keeps_whole_strings |
| the window dimension carries no parameters, and windows made at the outermost depth carry none either | the_window_dimension_carries_no_parameters, windows_at_the_outermost_depth_give_the_windows_no_parameters, windows_at_the_outermost_depth_of_a_parameterized_array |
| `axis` names the windows dimension; result has one fewer | unwindows_removes_a_dimension, unwindows_at_axis_one, unwindows_default_axis_is_the_dimension_holding_the_windows |
| window `j` sits `j` strides along, taking only what the one before did not reach; a gap a wide stride leaves is not filled | unwindows_lays_overlapping_windows_over_one_another, unwindows_with_a_stride_that_leaves_no_overlap, unwindows_with_a_stride_of_two, a_window_that_reaches_no_further_contributes_nothing, unwindows_of_dropped_windows_loses_what_no_window_covered, unwindows_of_padded_windows_keeps_the_padding_as_values, unwindows_of_an_empty_list_of_windows, unwindows_with_a_stride_that_leaves_no_overlap, unwindows_leaves_gaps_unfilled, a_later_window_does_not_overwrite_what_is_already_there, only_the_unreached_tail_of_each_window_contributes, a_later_window_longer_than_the_first_contributes_all_it_reaches, a_later_longer_window_after_a_single_element_window, windows_of_growing_length_are_placed_by_stride_alone, a_later_longer_window_with_a_wider_stride, unwindowing_a_right_aligned_pass_places_windows_by_stride |
| it returns the lists `ak.windows` was given | unwindows_recovers_the_lists_it_was_given, unwindows_recovers_nested_lists, unwindows_recovers_lists_reached_through_a_mask, unwindows_recovers_strings, unwindows_of_fixed_size_windows, windows_and_unwindows_agree_on_a_right_aligned_pass_only_by_length |
| the windows' parameters become the rebuilt lists' | unwindows_gives_the_windows_parameters_to_the_lists, unwindows_recovers_strings |
| anything but lists inside `axis` is a `ValueError` | unwindows_without_lists_inside_axis_is_a_value_error, unwindows_a_union_branch_without_lists_is_a_value_error, unwindows_a_masked_array_without_lists_is_a_value_error |
| a missing list has no windows and stays missing, either way | unwindows_bit_masked_windows_recover_their_lists, unwindows_of_bit_masked_windows_is_structurally_sound, a_missing_list_stays_missing, a_missing_list_keeps_its_option_type, a_missing_list_stays_missing_when_keeping, a_missing_list_stays_missing_when_padding, byte_masked_lists_stay_missing, bit_masked_lists_stay_missing, unwindows_a_missing_list_of_windows_stays_missing, unwindows_byte_masked_windows_stay_missing |
| neither operation changes the array it was given | the_input_is_left_alone, unwindows_leaves_its_input_alone |
| lists reached through an index, mask, union or record | lists_reached_through_an_index, unmasked_lists_are_windowed, a_union_of_list_types, lists_of_records, a_record_of_lists_is_windowed_field_by_field, lists_whose_starts_are_out_of_order, lists_whose_starts_are_out_of_order_with_keep_and_right_align, unwindows_windows_reached_through_an_index, unwindows_a_union_of_windows, unwindows_a_record_of_windows |
| typetracer arrays, with nothing about the data read | typetracer_drop_matches_the_concrete_form, typetracer_keep_matches_the_concrete_form, typetracer_pad_matches_the_concrete_form, typetracer_right_align_matches_the_concrete_form, typetracer_optional_lists_match_the_concrete_form, typetracer_nested_axis_matches_the_concrete_form, typetracer_axis_zero_matches_the_concrete_form, typetracer_records_match_the_concrete_form, typetracer_lengths_are_unknown, unwindows_typetracer_matches_the_concrete_form, unwindows_typetracer_of_optional_windows, unwindows_typetracer_at_axis_zero, typetracer_windows_never_looks_at_the_values, typetracer_unwindows_never_looks_at_the_values, typetracer_windows_never_looks_at_the_values_at_a_nested_axis, typetracer_unwindows_never_looks_at_the_values_at_a_nested_axis, typetracer_of_an_empty_array_matches_the_concrete_form, unwindows_typetracer_of_an_empty_array_matches_the_concrete_form |

Two gaps were found by building this table and were closed on both sides at once:

- The tests pinned `TypeError` for a fractional `size` or `stride` while the description only named
  `ValueError`. The description now names both kinds.
- Three tests assert that the result is a sound layout (validity, packing, buffer round-trip) and one
  asserts the input is untouched. Soundness is what the repo's own tests assert for any result
  (`validity_error` in 8 files, `to_packed` in 12, `to_buffers` in 20); the untouched-input claim is
  now a clause in the description.

Also fixed while writing the tests: the description claimed a list shorter than `size` yields exactly
one window under `"keep"` and `"pad"`. It yields one per stride step that holds an element, which is
more than one whenever the list is longer than `stride`. The sentence was wrong, not the code, and it
was cut back to what the general rule already implies.

## Iteration history

1. Feature designed against the prose contract; implementation written kernel-free because
   `awkward_cpp` is a pinned wheel.
2. Independent oracle written from the prose and fuzzed: 132 apparent mismatches, all of them arrays
   with no list dimension at all (`[None]`, `[None, None]`), where `axis=-1` resolves to the
   outermost depth. Oracle corrected, 0 mismatches over 3205 cases.
3. Effective LOC measured at 345, under the 430 design floor. Scope extended with the inverse
   operation, which is orthogonal logic (placement and overlap rather than geometry) and carries the
   round-trip law: 566.
4. 131 tests written from the clause list; 4 failures on the first run, 3 of them my own hand
   arithmetic and 1 a genuine over-claim in the description (see above).
5. Mutation battery: 18 mutations, 17 killed, 1 equivalent retired.
6. Coverage suggestions from the Test Fairness check taken in full, 131 -> 137 tests: explicit
   `behavior=` and `attrs=` overrides for both operations (not only inheritance from the input), the
   inverse's own input-immutability check, its behavior-propagation counterpart, and two
   `typetracer_with_report` checks that assert neither operation reads a buffer outside its input and
   that the structure is consulted, rather than checking output forms alone. The touch assertions are
   written as a subset, not an equality, so a lazier but still correct implementation is not failed.
7. Test Fairness returned FAIL on 2 of 141 assertions, both mine: the typetracer touch tests
   asserted `"node0" in report.shape_touched`, an internal access path that no clause requires and
   that a correct implementation need not produce. Removed; the public type assertion and the
   data-touch bound stay. Coverage suggestions taken: non-integer `size`/`stride` now covers strings
   and None, and the inverse's `ValueError` is exercised through a union branch and a mask, 137 ->
   144 tests. The suggestion to demand `len(report.data_touched) == 0` was declined and the
   description reworded instead: the repository reports a data dependency for buffers it will
   consume, so zero touches is not something a correct implementation can deliver, and "nothing about
   the data may be read" promised more than that. The clause now reads "the data is unknown, so no
   value may be looked at".
8. Second coverage round, all four suggestions taken, 144 -> 156 tests. The weak touch whitelists
   became the assertion the clause actually makes: rearranging whole lists at `axis=0` cannot need
   the values, so the leaf buffer's key (read off the form, not hard-coded) must be absent from
   `report.data_touched`. Plus negative and out-of-range axes for the inverse, fractional axes on
   both operations (the repository raises `ValueError` here, not `TypeError`), numpy integer scalars
   accepted, and booleans rejected in line with `is_integer`.
9. Third fairness round, FAIL on 3 of 156, 156 -> 161 tests. The stride-gap flag was correct and was
   a description gap, not a test bug: nothing said what happens to positions no window reaches. The
   clause is now in `meta.md` (a wide stride leaves a gap that nothing fills), the flagged test stays,
   and a second gap case was added. The two fractional-axis flags cited `regularize_axis` raising
   `TypeError`; measurement says otherwise, since `ak.num`, `ak.local_index` and `ak.pad_none` all
   raise `ValueError` for `axis=1.5` (`_named_axis_to_positional_axis` rejects a float first, so
   `regularize_axis` is never reached). Rather than defend a contested class for validation that is
   not part of this contract, both tests were deleted. Advisory suggestions taken: None and numeric
   values for both choice arguments, and a negative `stride` for both operations. `meta.md` is now
   522 words, over the 500 guide, with the cap raised to 600 for this submission.
10. Fourth round: the check passed, and all three advisory suggestions were taken, 161 -> 170 tests.
    Length-zero arrays with a known form for both operations including typetracer parity; the
    no-value-read assertion repeated at a nested axis, where windowing at `axis=1` of a three-deep
    array and rebuilding at `axis=1` of a four-deep array both leave the leaf buffer untouched; and
    `behavior`/`attrs` passed with `highlevel=False`, which returns a `Content` with the values
    unaffected.
11. Solution Quality PASS at 2/3 + 2/3, three points raised. Two were real: named axes were dropped
    wholesale instead of adjusted (now `_add_named_axis` / `_remove_named_axis`, as in `ak.singletons`
    and `ak.firsts`), and `merge_windows` took a `parameters` argument it never used, which made the
    `axis=0` path read as if it discarded them (argument removed; the behaviour was already correct).
    The redundant `_touch_data` on the typetracer path also went: `_carry` declares the same
    dependency, and the touch reports are identical without it. The third point, `_windows_axis0`
    passing `None` for window parameters, is correct as written, because at the outermost depth there
    is no list node to take parameters from and copying the array's own would make windows of strings
    into strings. That is now a clause in `meta.md`, two tests, and a mutation that dies.
12. Problem-and-tests quality: two warnings. The private-internals one had a clean fix, since
    `awkward.typetracer` re-exports `unknown_length` in its own `__all__`; the test uses that now and
    no `ak._`-prefixed module appears in the suite at all. The other flagged idioms are the
    repository's own (`str(array.type)` in 51 of its test files, `layout.form ==` in 13,
    `typetracer_with_report` public) and they carry the fixed-size-versus-variable contract, so they
    stay. The alignment warning was fair: `meta.md` now says a boolean does not count as an integer
    for `size` or `stride`, which is what `is_integer` enforces and what three tests pin.
13. Fifth round: both advisory suggestions taken, 173 -> 181 tests. Named axes are now covered the
    way `tests/test_2596_named_axis.py` covers `ak.singletons` and `ak.firsts`, positional against
    by-name with the negative-index pair, and the maps come out identical to those neighbours. The
    dispatch tests use the `types.SimpleNamespace` sentinel from `tests/test_4107_operations_batch.py`
    and assert both the interception and that the array was offered to `__awkward_function__`.
14. Batch 1 came back 0/10, which is a reject, and the cause was mine. The clause "the dimension
    holding the windows is itself fixed size when every list it came from had the same length" was
    implemented literally by all ten agents, which makes the output type depend on the data and breaks
    typetracer parity by construction; my reference had tied regularity to the input dimension's kind
    instead. Three tests failed in all ten runs on exactly that. The clause now says what the
    reference does. Two smaller causes: the named-axis map was never specified, so agents dropped or
    mis-shifted names (Nova #3 called `_remove_named_axis` with `axis + 1`), now stated; and eleven of
    my typetracer tests compared `layout.form` exactly, failing agents whose concrete and traced paths
    differed only in `ListArray` versus `ListOffsetArray`, now compared as `type.content`. Solvability
    is no longer a prediction: Nova #3's own implementation passes 181/181 and the full baseline after
    the three edits the corrected description dictates, so the best agent was three prompt-stated
    details from green. The geometry, option, parameter, error and empty-array traps were left alone;
    those failures were real misses, including a length-zero crash and one agent copying the string
    parameter onto the windows, which is a planted mutation.
15. One more unfair assertion found by re-reading the batch rather than the checker:
    `an_empty_array_of_lists_keeps_its_window_types` pinned the whole type of a keep-mode result on an
    empty array, `0 * var * var * int64`. The outer dimension is determined by the corrected clause,
    but the inner one is not: with zero windows, "windows that all hold exactly `size` elements are
    fixed size lists" is vacuously true and "cut off ones are variable length" has no instances, so
    `var` and `2` are both defensible. The batch shows both readings taken (Nova #3 `0 * var * 2`,
    Nova #6 `0 * 0 * 2`). Renamed to `..._keeps_its_window_dimension` and now asserting only what the
    prose fixes: no windows, and a variable window-holding dimension. The keep-mode variable-length
    rule stays pinned by the two non-empty tests. The drop-mode sibling keeps its full pin, because
    there both readings give the same fixed size. Effect on the best run: 6 failures becomes 5, all
    five prompt-determined.
16. Sixth round: FAIL on 1 of 181 and one advisory worth more than the FAIL.
    `a_union_keeps_its_union_type` pinned the rendered type as `2 * union[...]`, which the prompt never
    requires: it says the operations work through a union, not that the result keeps that
    representation, so a normalising implementation would be failed for nothing. Deleted; the values
    tests carry the union contract. The advisory exposed a real hole: every overlap fixture used
    matching values, so nothing distinguished "each window contributes what the one before did not
    reach" from an implementation that overwrites the overlap or rejects a disagreement. Two tests now
    use a later window that disagrees (`[[[1, 2], [9, 3]]]` -> `[1, 2, 3]`), which is the inverse's
    central clause and was previously unpinned. 182 tests.
17. Seventh round: the check passed, and one advisory ("mixed-depth unions and axes") found a real bug
    in the reference rather than a gap in the tests. On a union whose branches have different list
    depths, `maybe_posaxis` returns None, so the old code recursed with the negative axis and each
    branch resolved it against its own depth; the shallower branch got windowed at its outermost depth,
    its length changed, and the union came out invalid (`index[i] >= len(content[tags[i]])`, branch
    lengths `[0, 1]` under length 2). It surfaced as an `IndexError` from `to_list`. Sibling ops dodge
    this only because their axis-0 paths preserve length. Both operations now raise `AxisError` for an
    axis the branches disagree about, and the soundness battery covers unions, which is what should
    have caught it. 182 -> 192 tests, 573 human-effective LOC.
18. The FP panel confirmed a functional false positive, which is the one verdict that invalidates a
    submission outright, and it was a coverage hole of mine. The candidate's inverse inferred alignment
    from the window lengths (`first_start = lengths[0] - window_size` when the first window was
    shorter), so it dropped elements: `[[[1], [2, 3, 4]]]` came back as `[[1, 3, 4]]`. The rule is
    stated unconditionally and `ak.unwindows` has no `align` argument, so nothing licenses the
    inference; the suite missed it because every unequal-window fixture put the longest window first,
    leaving that branch dead. Five discriminators added off that shape, including the decisive one:
    unwindowing a RIGHT aligned keep pass must produce the stride merge
    (`[[1, 1, 2, 2, 3, 4], [5, 5, 6]]`), not the recovered original, since round-trip is promised only
    for a left aligned pass. Trap-proven with a mutation that derives each window's reach from the
    longest window instead of the preceding one: it fails exactly those five. Advisories also taken:
    axis-type rejection on both operations, asserted as `(TypeError, ValueError)` so it does not pin a
    class an earlier fairness round objected to, and per-mode typetracer no-value-read checks for keep,
    pad and right alignment. 205 tests.
19. Auto Review after batch 2: revision requested for one High finding, and it was a real bug in my
    reference. `incomplete="pad"` could not window a string or bytestring: the pad path option-wrapped
    the character content and then built a `RegularArray` still tagged `__array__: "string"`, which the
    constructor rejects outright. Worth noting the library agrees a string cannot hold missing
    characters, since `ak.pad_none` refuses the same combination, so the fix is not to force the tag
    through but to give it up: padding now drops the string or bytestring tag and the characters drop
    theirs with it, leaving a fixed size list of optional bytes. Stated in `meta.md`, and six tests now
    cover strings and bytestrings across all three modes plus the soundness battery. The Medium
    typetracer finding was already fixed in the previous round (the review saw 192 tests, the suite is
    now 211), and the Medium verbosity finding is fixed by cutting the opening motivation clause, which
    paid for the new padding sentence. Batch 2 also settles solvability from the platform's side: 1 of
    10 passed legitimately, with both failure clusters rated subtle but fair.
20. Eighth round, two symmetry gaps closed, 211 -> 214 tests: the inverse now has the unknown-axis-name
    rejection that only `ak.windows` had, and the mask coverage is even, since `ak.unwindows` had only
    ever been round-tripped through a byte mask while `ak.windows` covered both. Bit-masked round trip
    plus a bit-masked soundness pass over all three modes.
21. Solvability re-checked after the suite grew to 214, since the padded-string rule, the union axis
    guard and the placement discriminators all landed after batch 2. Batch 2's passing patch is not in
    the local artifacts, so the check ran against batch 1's best run once more: with only the three
    clause-dictated edits it now passes 214/214 and the 4608-test baseline. It meets all three new
    requirements unaided, including the padded-string rule, which it had already implemented the way the
    Auto Review asked of the reference. Independent agent code satisfying rules written without sight of
    it is stronger evidence than the earlier check, and it stands alongside batch 2's 1 of 10.
22. Ninth round, 214 -> 221 tests. The axis-scalar suggestion was routine. The reach suggestion was not:
    it asked which reading of "did not reach" the contract takes, and pinning it cost me the local
    solvability replay. The fixed batch-1 tree fails the three new tests, not because it uses cumulative
    reach but because it derives the rebuilt length from the last window's placement and truncates, so
    `[[[1, 2, 3], [4]]]` loses an element the first window contributed. Monotonic inputs agree, which is
    how it passed 214. I kept the tests, since that is a real defect class that went undetected, and moved
    the rule out of the gap sentence where it had been scoped: every element some window contributes is in
    the rebuilt list, and no later window takes one back. Solvability now leans on batch 2's 1 of 10; if
    the next batch returns 0, these three tests and that clause are the newest and narrowest thing to cut.
23. Solvability at 221 settled rather than left open. The agent tree's failure was an off-by-one, not a
    disagreement about the rule: its carry logic already emits the right elements, but its length
    accumulator adds `window_length - skip`, which goes negative when a window is shorter than the
    overlap the one before it covered, so the rebuilt list loses an element that was already contributed.
    One `max(..., 0)` fixes it, which is precisely what the clause demands, and with that fourth edit the
    tree passes 221/221 plus the 4608 baseline. The reach tests therefore stay: they cost a correct
    implementation nothing, and without them a negative contribution count deletes data on any
    non-monotonic input while every monotonic input hides it. The platform's batch-2 notes list "allowing
    negative contribution counts" among the observed failures, so the defect was already live and unseen.
24. Asked whether to add hints for solvability: not applicable at this tier, since hints were removed for
    Olympus in April 2026 and only Diamond keeps a hinted-run pipeline. The description is the only
    equivalent lever, and the remaining budget went to the weakest link in the mapping rather than to a
    general softening: two tests demanded an `AxisError` for an axis a union's branches disagree about,
    while the only clause covering them said "a depth the array does not have", which is a stretch when
    each branch does have a depth and they merely differ. That case is now named explicitly, paid for by
    cutting "and, to take them back," from the opening. 594 words, and no trap was weakened.
25. Hints added to the description by direction. The tier has no hint field, so they are a closing
    paragraph in `meta.md`: the result's type never depends on the data and an empty array types the same
    way; a window reaching no further contributes nothing, never less than nothing, so the rebuilt list
    never loses an element it already held; the named axes that survive keep the dimensions they
    described. Each maps to a cluster the batches failed on, and each is a principle rather than a
    recipe, so no helper, file or algorithm is named. I did cut the draft's opening, "Three things are
    easy to get wrong", since spotlighting which requirements are hard is measured to erode pass rate
    badly (a comparable sentence moved one problem from about 40% to 60%); the same three facts are now
    stated plainly. `meta.md` is 665 words, past the 600 set earlier, which is what the hints cost.
26. Tenth round, 221 -> 224 tests. The typetracer-through-wrappers suggestion needed the fixture worked
    out: a two-deep record field fails the no-touch claim legitimately, since there the merged elements are
    the values, so the test uses a three-deep field where whole lists move and the leaf stays untouched;
    and the first union fixture collapsed to a plain list type, because concatenating same-typed arrays
    merges, so it is now a number branch beside a record branch with both leaves asserted untouched. The
    parameter suggestion was a direct probe of the padding fix and it holds: a custom `tag` survives on
    padded windows while `__array__` is dropped, which is worth pinning because the fix removes a parameter
    by name and could have taken the rest with it. Solvability unchanged, the agent tree passes 224/224.
27. Alignment check warned that four tested things rested on Awkward convention instead of the
    description: `__awkward_function__` interception, `behavior`/`attrs` propagation with overrides and
    their absence at low level, numpy integers and named axis strings for `size`/`stride`/`axis`, and
    bytestrings under padding. Each of those tests came from an earlier round's coverage request, so they
    stay and the description now covers them in three sentences. The codebase-inferable count drops from
    one to zero, which removes the last hidden-requirement risk in the mapping. `meta.md` is 728 words,
    the cost of hints plus this alignment.
28. Eleventh round, FAIL on 1 of 224, correctly. `unwindows_at_the_outermost_depth_keeps_the_windows_parameters`
    demanded the rebuilt result carry the windows' `tag` after `axis=0`, but at that depth there is no rebuilt
    list node to hold list parameters, so the implementation lands them on the element content and no clause
    fixes that. It also contradicts my own forward-direction sentence, which says windows made at the outermost
    depth carry none: I cannot decline the transfer for one operation and silently require it for the other.
    Test deleted, behaviour left alone, and `DESIGN.md` now records the placement as an unasserted structural
    choice so it does not get re-pinned. The clause itself stays covered at an ordinary axis. 223 tests, and the
    agent tree still passes 223/223.
