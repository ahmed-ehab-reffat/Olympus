# hayro-optional-content-baking — eval results

No platform batch yet. Local validation numbers are logged here as they are measured.

## Local validation (SLICE, 2026-09-23)

| Check | Result |
|---|---|
| test.sh base on base (uid 0 / 1000 / 4242, --network none) | 475 cases, 0 failures, rc 0 (all three uids) |
| test.sh new on base | 10 cases, 10 failures (runtime assertion "extracted page differs from the source page"), rc 1 |
| test.sh base with solution, 3 runs x 3 uids | 475 / 0 failures each run, identical |
| test.sh new with solution, 3 runs x 3 uids | 10 / 0 failures each run, identical |
| git status after both patches | only harness + solution files |
| effective_loc_check.py solution.patch | raw 244, human-effective 165, padding-floor 25, 3 files |
| Docker build (base image cached) | ~140 s |

## Local validation (precheck fix, 2026-09-25)

| Check | Result |
|---|---|
| test.sh base on base (uid 0 / 1000 / 4242, --network none) | 475 cases, 0 failures, rc 0 |
| test.sh new on base | 17 cases, 17 failures, rc 1 |
| test.sh base / new with solution, 3 runs x 3 uids | 475/0 and 17/0 every run, identical |
| preserve-OC emulation (source rendered OC-unaware vs OC-aware) | differs for 17/17 sources |
| mutants: P ignored / OCMD as plain OCG / AllOff flipped | 4 / 5 / 1 tests killed |

## Local validation (solution-quality fix, 2026-09-25)

| Check | Result |
|---|---|
| test.sh base on base (uid 0, --network none, clean clone at BASE) | 475 cases, 0 failures, rc 0 |
| test.sh new on base (uid 0) | 31 cases, 31 failures, rc 1 |
| test.sh base / new with solution, 3 runs (uid 0) | 475/0 and 31/0 every run, identical |
| uid 1000 / 4242 clean-room runs | NOT DONE: background run killed by the host for low memory; owed |
| old reference as mutant | fails 6/31 (policy-only AllOff, inline props, 3 form cells, text clip) |
| effective_loc_check.py solution.patch | human-effective 271, padding-floor 35, 4 files |

## Local validation (round 3 cache fix, 2026-09-25)

| Check | Result |
|---|---|
| cargo test new tests, reference | 36 / 36 pass |
| cargo test new tests, base | 36 / 36 fail |
| mutant: variant cache ignores caller scope | kills shared_form_follows_each_callers_resources only |
| clippy -p hayro-write --all-targets | clean |
| effective_loc_check.py | human-effective 300, 4 files |
| Docker clean room (uid 0/1000/4242) | NOT RUN: host 0 GB available memory; owed |

## Local validation (round 4 resource-driven streams, 2026-09-25)

| Check | Result |
|---|---|
| cargo test new tests, reference | 42 / 42 pass |
| cargo test new tests, base | 42 / 42 fail |
| round-3 reference as mutant | fails the 5 pattern / Type3 / soft-mask cells |
| mutant: pattern selection only in visible content | kills pattern_selected_in_hidden_content_still_fills |
| test.sh base with solution (host, not Docker) | 475 cases, 0 failures |
| clippy -p hayro-write --all-targets | clean |
| effective_loc_check.py | human-effective 409, 4 files |
| Docker clean room (uid 0/1000/4242) | NOT RUN; owed |

## Local validation (round 5 soft-mask group /OC, 2026-09-25)

| Check | Result |
|---|---|
| cargo test new tests, reference | 46 / 46 pass |
| cargo test new tests, base | 46 / 46 fail |
| round-4 reference as mutant | fails soft_mask_group_with_hidden_optional_content_masks_everything only |
| test.sh base with solution (host) | 475 cases, 0 failures |
| clippy -p hayro-write --all-targets | clean |
| Docker clean room (uid 0/1000/4242) | NOT RUN; owed |

## Local validation (round 6 inline-image boundary, 2026-09-25)

| Check | Result |
|---|---|
| cargo test new tests, reference / base | 49 pass / 49 fail |
| round-5 reference as mutant | fails state_before_a_hidden_inline_image_survives only |
| test.sh base with solution (host) | 475 / 0 |
| clippy -p hayro-write --all-targets | clean |
| Docker clean room (uid 0/1000/4242) | NOT RUN; owed |

## Batch 1 (2026-09-25): 10 Nova + 1 Vega, 49-test suite (round 6) -> 0/11

| Run | Verdict | New failed | Failed tests | Grader note |
|---|---|---|---|---|
| Nova #10 | FAIL | 7/49 | 7 tests | Seven optional-content extraction tests fail, covering hidden text semantics and Type3 glyph procedures. |
| Nova #1 | FAIL | 2/49 | form_with_hidden_text_keeps_each_callers_render_mode, shared_form_follows_each_callers_resources | Agent passed all baseline tests and 47 of 49 new tests, but failed two deterministic cases involving reused Form XObjects and caller-dependent state. |
| Nova #9 | FAIL | 49/49 | 49 tests | The new suite crashes with a stack overflow while extracting a Type3 glyph procedure. |
| Nova #8 | FAIL | 44/49 | 44 tests | Agent implemented a compiling optional-content rewrite, but failed most new extraction cases because named resource properties are not interpreted as  |
| Nova #7 | FAIL | 19/49 | 19 tests | The agent passed all baseline tests but failed 19 of 49 new optional-content extraction tests. The implementation handles several top-level cases, but |
| Nova #6 | FAIL | 9/49 | 9 tests | Extraction differs from the source for OCMD membership-policy cases and content hidden inside Type3 glyph procedures. |
| Nova #5 | FAIL | 8/49 | 8 tests | Optional-content extraction is incomplete for text-state propagation, shared nested Forms, hidden inline-image boundaries, and hidden soft-mask groups |
| Nova #4 | FAIL | 1/49 | form_with_hidden_text_keeps_each_callers_render_mode | A reused Form XObject resets the caller's text render mode after hidden text, causing later visible text to render differently. |
| Nova #3 | FAIL | 8/49 | 8 tests | Eight new optional-content extraction tests fail because nested inline resources, inline property-list references, and caller text render modes are no |
| Nova #2 | FAIL | 3/49 | form_with_hidden_text_keeps_each_callers_render_mode, shared_form_follows_each_callers_resources, soft_mask_group_with_hidden_optional_content_masks_everything | Three new optional-content extraction cases render differently from the source: caller-dependent form state/resources and an off soft-mask group are m |
| Vega #1 | FAIL | 1/49 | form_with_hidden_text_keeps_each_callers_render_mode | A reused Form XObject changes the caller's text render mode after hidden text, so the extracted page differs from the source. |

Per-test kills: form_with_hidden_text_keeps_each_callers_render_mode 11/11 (the wall; Vega and Nova #4
failed ONLY it), hidden_content_inside_a_type3_glyph 6, type3_glyph_in_a_pattern_in_a_form 6,
shared_form_follows_each_callers_resources 6, soft_mask_group_with_hidden_oc 5, hidden-text cells 4,
most others 2-3 (Nova #9 stack overflow and Nova #8 broken build kill everything).
Baseline green in all 11.

## Replay (saved agent patches, agent test edits excluded, worktrees/_hayro_val/replay.sh)

| Candidate suite | Vega | Nova #4 | Nova #1 | Projected |
|---|---|---|---|---|
| batch suite (49) | fail | fail | fail | 0/11 |
| render-mode cell cut (48) | pass | pass | fail (shared_form) | 2/11 |
| cut + Type3-via-gs cell (49) | pass | fail (gs font) | fail | 1/11 |
Shipped: the 48-test cut; Type3-via-gs fixed in the reference, its test withheld.

## Re-eval 2 (2026-09-26, 48-test suite) -> 2/11, both FP

| Run | New failed | Notes |
|---|---|---|
| Vega #1 | 0 | PASS, FP: Form render mode reset to 0; shared child baked with first caller's /Properties |
| Nova #4 | 0 | PASS, FP: hides any BDC tag (no /OC gate) |
| Nova #1 | 1 | shared_form_follows_each_callers_resources |
| Nova #2 | 2 | shared_form, soft_mask_group_with_hidden_oc |
| Nova #5 / #3 / #10 / #6 | 7 / 7 / 6 / 8 | hidden text, Type3, soft masks, membership |
| Nova #7 / #8 / #9 | 18 / 43 / 48 | forms, broad, stack overflow |

## Round 8 replay (54-test suite, batch-1 solutions; description delta NOT measured)

| Run | Result |
|---|---|
| Nova #4 | 54/54 |
| Vega #1 | 53/54 (marked_content_tag_does_not_matter) |
| Nova #1 | 52/54 (properties_come_from..., shared_form) |

## Round 9 replay (57 new tests, batch-1 solutions; description delta not measured)

| Run | Result |
|---|---|
| Nova #4 | 57/57 |
| Vega #1 | 56/57 (marked_content_tag_does_not_matter) |
| round-8 reference | 55/57 (the two OCMD hand-oracle cells) |
| base | 0/57 new; write_plain_0eadd0 2/2 pass (base-mode regression) |

## Round 10 replay (62 new tests, batch-1 solutions; description delta not measured)

| Run | Result |
|---|---|
| Nova #4 | 62/62 |
| Vega #1 | 61/62 (marked_content_tag_does_not_matter) |
| round-9 reference | 61/62 (page_properties_inherited_from_the_page_tree_count) |
| base | 0/62 new; write_plain 2/2 |

## Batch 3 (2026-09-28, fresh, 62-test round-10 suite) -> 1/11 (Vega), adjudicated FP -> 0 real

| Run | New failed |
|---|---|
| Nova #10 · re-eval 1 | 5/62  |
| Nova #1 · re-eval 1 | 2/62 text_after_hidden_text_in_a_form_uses_the_forms_own_render_mode, type3_glyph_in_a_pattern_in_a_form_hides_its_content |
| Nova #9 · re-eval 1 | 3/62 text_after_hidden_text_uses_a_mode_the_form_set_itself, text_after_hidden_text_in_a_form_uses_the_forms_own_render_mode, type3_glyph_in_a_pattern_in_a_form_hides_its_content |
| Nova #8 · re-eval 1 | 3/62 inline_membership_dictionary_decides_with_its_policy, inline_property_list_is_honoured, type3_glyph_in_a_pattern_in_a_form_hides_its_content |
| Nova #7 · re-eval 1 | 5/62  |
| Nova #6 · re-eval 1 | junit missing (download error) |
| Nova #5 · re-eval 1 | 12/62  |
| Nova #4 · re-eval 1 | 14/62  |
| Nova #3 · re-eval 1 | 55/62  |
| Nova #2 · re-eval 1 | 13/62  |
| Vega #1 · re-eval 1 | 0/62  |

Kills: type3_glyph_in_a_pattern_in_a_form 7 (fixture used a DIRECT Type3 font dict; agents key CharProcs
by object id), text_after_hidden_text_in_a_form_uses_the_forms_own_render_mode 7 and
text_after_hidden_text_uses_a_mode_the_form_set_itself 5 (agents write `0 Tr` at form start, which
also changes text shown BEFORE the hidden text: one-sided carve-out), shared_form 5, soft-mask /OC 5.
Vega FP: hidden IMAGE inherited into a Form with empty /Resources is drawn (XObject names resolved
locally only).

## Round 11 replay (65 new tests, batch-3 solutions; description delta not measured)

| Run | Result |
|---|---|
| Vega | 64/65 (hidden_image_inherited_into_a_form_is_not_drawn) |
| Nova #1 | 60/65 (inherited image, inline x2, shared_form, soft-mask /OC) |
| Nova #9 | 62/65 (inherited image, both form render-mode cells) |
| Nova #10 | 63/65 (inherited image, form render-mode) |
Indirect Type3 fonts un-killed the pattern cell for #9 and #10. The inherited-image cell kills all four
while unstated; meta now states resource inheritance explicitly.

## Batch 4 (2026-09-29, fresh, 72-test round-13 suite; 10 Nova + 1 Orion + 2 Vega) -> 0/13

| Run | New failed | Tests |
|---|---|---|
| Nova #10 (Nova_Nova_1) | 1/72 | type3_glyph_uses_its_fonts_properties_not_its_own |
| Nova #1 (Nova_Nova_10) | 6/72 |  |
| Nova #9 (Nova_Nova_2) | 72/72 |  |
| Nova #8 (Nova_Nova_3) | 2/72 | inline_membership_dictionary_decides_with_its_policy, shared_form_follows_each_callers_resources |
| Nova #7 (Nova_Nova_4) | 8/72 |  |
| Nova #6 (Nova_Nova_5) | 3/72 | hidden_text_in_a_form_ignores_the_callers_clipping_mode, shared_form_follows_each_callers_resources, type3_glyph_uses_its_fonts_properties_not_its_own |
| Nova #5 (Nova_Nova_6) | 72/72 |  |
| Nova #4 (Nova_Nova_7) | 17/72 |  |
| Nova #3 (Nova_Nova_8) | 24/72 |  |
| Nova #2 (Nova_Nova_9) | 2/72 | shared_form_follows_each_callers_resources, type3_glyph_uses_its_fonts_properties_not_its_own |
| Orion #1 (Orion_Nova) | 4/72 |  |
| Vega #1 (Vega_Nova_1) | 1/72 | type3_glyph_uses_its_fonts_properties_not_its_own |
| Vega #1 (Vega_Nova_2) | 72/72 |  |

Kills: type3_glyph_uses_its_fonts_properties_not_its_own 10 (Nova #10 and Vega run 1 failed ONLY it:
agents layer the CharProc's own /Resources over the font's, as hayro's renderer does),
shared_form_follows_each_callers_resources 10 (3 pass: a real discriminator). Three runs failed all 72
on stack overflows in their own inheritance code (no cycle guard): agent bugs.

## Round 14 replay (74 new tests, batch-4 solutions; description delta not measured)

| Run | Result |
|---|---|
| Nova #10 | 74/74 |
| Vega run 1 | 74/74 |
| Nova #2 | 73/74 (shared_form) |
| Nova #6 | 72/74 |
| Nova #8 | 71/74 |
| Orion | 71/74 |
Projection on this pool: 2/13 (15%).

## Batch 5 (2026-09-30, fresh, 74-test round-14 suite; 10 Nova + 1 Vega) -> 0/11

| Run | New failed | Tests |
|---|---|---|
| Nova #10 (Nova_Nova_1) | 2/74 | inline_membership_dictionary_decides_with_its_policy, inline_property_list_is_honoured |
| Nova #1 (Nova_Nova_10) | 6/74 |  |
| Nova #9 (Nova_Nova_2) | 14/74 |  |
| Nova #8 (Nova_Nova_3) | 10/74 |  |
| Nova #7 (Nova_Nova_4) | 18/74 |  |
| Nova #6 (Nova_Nova_5) | 3/74 | hidden_text_in_a_form_ignores_the_callers_clipping_mode, shared_form_follows_each_callers_resources, soft_mask_group_with_hidden_optional_content_masks_everything |
| Nova #5 (Nova_Nova_6) | 15/74 |  |
| Nova #4 (Nova_Nova_7) | 7/74 |  |
| Nova #3 (Nova_Nova_8) | 3/74 | hidden_text_in_a_form_ignores_the_callers_clipping_mode, shared_form_follows_each_callers_resources, soft_mask_group_with_hidden_optional_content_masks_everything |
| Nova #2 (Nova_Nova_9) | 6/74 |  |
| Vega #1 (Vega_Nova) | 1/74 | shared_form_follows_each_callers_resources |

Kills: shared_form_follows_each_callers_resources 8 (Vega's ONLY failure), inline_property_list 7,
inline_membership 7 (Nova #10's only two), soft-mask /OC 5, hidden quote operators 5.

## Round 15 replay (75 new tests: + q/Q regression)

| Run | Result |
|---|---|
| batch-4 Vega run 1 | 75/75 |
| batch-5 Vega | 74/75 (shared_form) |
| batch-4 Nova #10 | 74/75 (new q/Q cell) |
| batch-5 Nova #10 | 72/75 (inline x2, q/Q) |
| batch-5 Nova #6, #3 | 71/75 |
| round-14 reference | 74/75 (q/Q) |

## Batch 6 (2026-09-30, round-14 suite; batch-5 pool + 1 new Vega) -> 1/12, FP-flagged -> 0 real

Nova #1-#10 and Vega_Nova_2 are the batch-5 runs (patches byte-identical), same results.
| Run | New failed | Notes |
|---|---|---|
| Vega #1 (Vega_Nova_1) | 0/74 | PASS_LEGITIMATE by the grader, FP-flagged. Local replay on the round-15 suite: 75/75 |

## Round 16 probe replay (FP reconstruction, 2026-09-30)

Cell type3_font_chosen_by_a_graphics_state_hides_its_content against every saved batch-4 and batch-6
solution: 24/25 fail it. It is the ONLY failure of batch-6 Vega #1 and batch-4 Vega run 1; batch-6
Vega_Nova_2 fails it plus shared_form. Only batch-6 Nova #5 handles it (it fails 3 other cells).
Now stated in meta + tested (76 tests). Local validation: base 76/76 fail,
reference 76/76 x3, test.sh new 76/0, base 478/0.

## Batch 7 (2026-10-01, fresh, round-16e meta + 76 tests; 10 Nova + 1 Vega) -> 0/11

| Run | New failed | Tests |
|---|---|---|
| Nova #10 (Nova_Nova_1) | 63/76 |  |
| Nova #1 (Nova_Nova_10) | 65/76 |  |
| Nova #9 (Nova_Nova_2) | 14/76 |  |
| Nova #8 (Nova_Nova_3) | 2/76 | shared_form_follows_each_callers_resources, restore_after_hidden_text_in_a_form_keeps_the_forms_render_mode |
| Nova #7 (Nova_Nova_4) | 4/76 | inline_membership_dictionary_decides_with_its_policy, inline_property_list_is_honoured, restore_after_hidden_text_in_a_form_keeps_the_forms_render_mode, type3_glyph_procedure_resources_take_precedence_over_the_fonts |
| Nova #6 (Nova_Nova_5) | 6/76 |  |
| Nova #5 (Nova_Nova_6) | 76/76 |  |
| Nova #4 (Nova_Nova_7) | 4/76 | inline_membership_dictionary_decides_with_its_policy, inline_property_list_is_honoured, state_before_a_hidden_inline_image_survives, restore_after_hidden_text_in_a_form_keeps_the_forms_render_mode |
| Nova #3 (Nova_Nova_8) | 65/76 |  |
| Nova #2 (Nova_Nova_9) | 3/76 | hidden_text_in_a_form_ignores_the_callers_clipping_mode, shared_form_follows_each_callers_resources, restore_after_hidden_text_in_a_form_keeps_the_forms_render_mode |
| Vega #1 (Vega_Nova) | 3/76 | shared_form_follows_each_callers_resources, restore_after_hidden_text_in_a_form_keeps_the_forms_render_mode, soft_mask_group_with_hidden_optional_content_masks_everything |

Kills: restore_after_hidden_text_in_a_form_keeps_the_forms_render_mode 11/11 (wall), shared_form 8,
clip-mode-in-form 6. Three runs failed 63-76 (broad failures).

## Round 17 replay (72 new tests: two caps, two probes; batch-7 solutions)

| Run | Result |
|---|---|
| Nova #8 | 72/72 |
| Nova #2 | 72/72 |
| Vega | 70/72 (inline-image /OC probe, soft-mask /OC) |
| Nova #7 / #4 / #6 | 69/72 (inline-property cells, Type3 precedence, inline-image state, image /OC) |
Projection on this pool: 2/11 (18%). Meta changed, so a full batch is needed.

## Batch 8 (2026-10-01, fresh, round-18 suite, meta 17b; 10 Nova + 1 Vega) -> 0/11

| Run | New failed | Tests |
|---|---|---|
| Nova #10 (Nova_Nova_1) | 69/75 |  |
| Nova #1 (Nova_Nova_10) | 64/75 |  |
| Nova #9 (Nova_Nova_2) | 75/75 |  |
| Nova #8 (Nova_Nova_3) | 6/75 |  |
| Nova #7 (Nova_Nova_4) | 17/75 |  |
| Nova #6 (Nova_Nova_5) | 75/75 |  |
| Nova #5 (Nova_Nova_6) | 75/75 |  |
| Nova #4 (Nova_Nova_7) | 12/75 |  |
| Nova #3 (Nova_Nova_8) | 15/75 |  |
| Nova #2 (Nova_Nova_9) | 5/75 |  |
| Vega #1 (Vega_Nova) | 1/75 | inline_image_with_its_own_hidden_optional_content_is_not_drawn |

Kills: inline_image_with_its_own_hidden_optional_content_is_not_drawn 10/11 (Vega's ONLY failure),
clip-mode text cells 9, Type3 cells 8. Auto Review on round 18: APPROVED (Desc 3/3, Tests 2/3 for
nesting only reaching 8 levels, Solution 3/3).

## Round 19 replay (test-only change; batch-8 solutions)

| Run | Result |
|---|---|
| Vega | 75/75 |
| Nova #2 | 71/75 (clip-mode text x3, plain marked content in hidden) |
| Nova #8 | 70/75 (Type3 cells) |
Projection via re-eval on batch 8: 1/11.

## Batch 9 (2026-10-08; round 20b meta, r19 tests, r18 solution; 10 Nova) -> 1/10, FP: GENUINE PASS

| Run | New failed | Tests |
|---|---|---|
| Nova #10 · re-eval 1 (Nova_Nova_1) | 65/75 |  |
| Nova #1 · re-eval 1 (Nova_Nova_10) | 65/75 |  |
| Nova #9 · re-eval 1 (Nova_Nova_2) | 5/75 | hidden_fill_and_clip_text_still_clips, hidden_fill_stroke_and_clip_text_still_clips, hidden_text_still_adds_to_the_text_clip, soft_mask_group_with_hidden_optional_content_masks_everything, type3_glyph_with_its_own_resources_still_uses_the_fonts_properties |
| Nova #8 · re-eval 1 (Nova_Nova_3) | 0/75 |  |
| Nova #7 · re-eval 1 (Nova_Nova_4) | 16/75 |  |
| Nova #6 · re-eval 1 (Nova_Nova_5) | 63/75 |  |
| Nova #5 · re-eval 1 (Nova_Nova_6) | 75/75 |  |
| Nova #4 · re-eval 1 (Nova_Nova_7) | 56/75 |  |
| Nova #3 · re-eval 1 (Nova_Nova_8) | 24/75 |  |
| Nova #2 · re-eval 1 (Nova_Nova_9) | 12/75 |  |

Nova #8 passes 75/75. FP adjudicator: genuine pass (one judge dissented with two probes: a shared
inheriting tiling pattern drawn from two places, and a direct inline Type3 font dict; adjudicator ruled
both unfair - the first is excluded by the "drawn in only one location" cap, the second is never stated).
Kills: Type3 cells 8-9, clip-mode text 8, caller graphics state 7. Several runs failed 56-75 (broad).
Auto Review on this round: Tests 2/3 Minor (T8: a cargo run that emits some test events and then
crashes, e.g. stack overflow, keeps nonzero status but loses its diagnostic in JUnit).
Description note (advisory): reads as a rule checklist; suggests leaving evaluation order to the solver.

## Round 22 replay (test-only: +2 tests, 67 new; batch-9 solutions)

| Run | Batch-9 verdict | r22 replay | New tests hit |
|---|---|---|---|
| Nova_3 | PASS (genuine) | 67/67 | none |
| Nova_1 | fail | 10/67 | page_selected_twice |
| Nova_2 | fail | 63/67 | none |
| Nova_4 | fail | 51/67 | compressed_form, page_selected_twice |
| Nova_5 | fail | 10/67 | page_selected_twice |
| Nova_6 | fail (stack overflow) | aborted | n/a |
| Nova_7 | fail | 16/67 | page_selected_twice |
| Nova_8 | fail | 43/67 | page_selected_twice |
| Nova_9 | fail | 57/67 | none |
| Nova_10 | fail | 10/67 | page_selected_twice |

Rate unchanged at 1/10.

## Batch 10 (2026-10-10; new models; meta r25, tests r25 65 new, solution r24): Nova 0/9, Orion 2/8 (both FP-voided)

| Run | Verdict | Failed new tests | seq len |
|---|---|---|---|
| Nova #1 | fail | type3_font_chosen_by_a_graphics_state, soft_mask_group_with_hidden_oc | 1,307k |
| Nova #2 | fail | type3_font_chosen_by_a_graphics_state | 523k |
| Nova #3 | early termination | all | 13k |
| Nova #4 | fail | hidden_image_inherited_into_a_form, type3 gs, type3_glyph_in_a_pattern_in_a_form | 763k |
| Nova #5 | wrong logic (stack overflow) | all | 630k |
| Nova #6 | fail | inline_property_list, type3 gs, soft_mask_group | 514k |
| Nova #7 | wrong logic (stack overflow) | all | 889k |
| Nova #8 | fail | type3 gs | 765k |
| Nova #9 | fail | inline_property_list, type3 gs | 1,071k |
| Orion #1 | fail | inline_property_list | 106k |
| Orion #2 | fail | soft_mask_group_with_hidden_oc | 109k |
| Orion #3 | fail | inline_property_list | 125k |
| Orion #4 | fail | inline_property_list | 91k |
| Orion #5 | PASS -> FP (shared Type 3/pattern baked once) | none | 123k |
| Orion #6 | PASS -> FP (same) | none | 117k |
| Orion #7 | fail | type3 gs | 102k |
| Orion #8 | fail | inline_property_list | 105k |

Nova avg sequence length 719k. Replay with 4 shared-context tests: Orion 0/8 (only #7 handles sharing).

## Batch 11 (2026-10-10; meta r26, tests r27 67 new, solution r27): Nova 0/8, Orion 1/6 (FP-voided)

| Run | Verdict | Failed new tests | seq len | r28 replay |
|---|---|---|---|---|
| Nova #1 | fail | type3 gs | 509k | + nothing new |
| Nova #2 | fail | soft masks x4, inline image state, type3 gs | 515k | + soft_mask_group_text_starts... |
| Nova #3 | fail | inline_property_list, type3 gs, soft_mask_group | 520k | same |
| Nova #4 | fail | type3 gs | 763k | same |
| Nova #5 | fail | type3 gs | 945k | same |
| Nova #6 | fail | inline_property_list, type3 gs | 814k | same |
| Nova #7 | fail | type3 gs | 521k | same |
| Nova #8 | fail | inline image state, type3 gs | 751k | same |
| Orion #1 | PASS -> FP (caller render mode leaks into pattern/mask) | none | 93k | fails both new tests |
| Orion #2 | fail | inline_property_list | 109k | + soft mask render mode |
| Orion #3 | fail | hidden image in form, inline_property_list | 124k | same |
| Orion #4 | fail | inline_property_list | 110k | same |
| Orion #5 | fail | inline_property_list | 156k | + both new tests |
| Orion #6 | fail | soft_mask_group_with_hidden_oc | 114k | same |

Batch 10 Orion on r28: #5 and #6 pass 69/69, #2 now also fails both new tests, the rest unchanged.

## Batch 12 (2026-10-11; meta r26, tests r29 68 new, solution r29): re-eval of b11 + Orion x4 + Vega x4 fresh -> Nova 0/8, Orion 0/10, Vega 0/4

| Run | Verdict | Failed new tests | seq len |
|---|---|---|---|
| Nova #1-#8 (b11 re-eval) | fail | all 8 fail type3 gs; plus inline (#3, #6), soft masks (#2, #3), inline image state (#1, #2) | ~667k avg (b11) |
| Orion b11 re-eval (Orion_Nova_1..6) | fail | #1 hidden image in form + inline; #2 inline; #3 inline + tiling render mode; #4 soft_mask_group_with_hidden_oc; #5 tiling render mode; #6 inline | b11 |
| Orion fresh #1 (Orion_Orion_2) | fail | inline, tiling render mode | 208k |
| Orion fresh #2 (Orion_Orion_1) | fail | inline, tiling render mode | 108k |
| Orion fresh #3 (Orion_Orion_3 run #2) | fail | inline | 111k |
| Orion fresh #4 (Orion_Orion_4 run #1) | fail | inline | 126k |
| Vega #1-#3 | fail | inline, type3 gs, soft_mask_group_with_hidden_oc | n/a |
| Vega #4 | fail | 7 tests (inline, type3 gs, soft masks, XObject scope x2, hidden image, inline image state) | n/a |

inline_property_list_is_honoured: Orion 8/10, Vega 4/4, Nova 2/8. Sole failure for 4/10 Orion.
Probe sweep (probe_b12.rs, 13 in-scope probes incl. the Test Quality coverage suggestions) on the 6 near-miss Orion:
zero divergence from the reference. Out-of-domain probe (page inheriting /Resources from /Pages) fails the reference too.

## Batch 13 (2026-10-11; meta r26, tests r29, solution r29): Orion x8 fresh -> Orion 0/8 (cumulative Orion 0/18, Nova 0/8, Vega 0/4)

| Run (platform #) | Verdict | Failed new tests | seq len (max step) |
|---|---|---|---|
| Orion_Orion_1 (#4) | fail | inline, tiling render mode | 235k |
| Orion_Orion_2 (#3) | fail | inline (treats the inline dict as the layer itself) | 252k |
| Orion_Orion_3 (#2) | fail | inline | 191k |
| Orion_Orion_4 (#1) | fail | inline, tiling render mode | 206k |
| Orion_Orion_5 (#4) | fail | inline | 197k |
| Orion_Orion_6 (#3) | fail | inline, tiling render mode | 210k |
| Orion_Orion_7 (#2) | fail | inline, tiling render mode | 210k |
| Orion_Orion_8 (#1) | fail | inline | 205k |

All 8 evaluator verdicts FAIL_MISSED_REQUIREMENT. inline fails 8/8 (sole in 4); tiling render mode 4/8.
Cumulative under meta r26 + tests r29: Orion 0/18; inline fails 16/18 and is the sole failure in 8/18.
Probe sweep (probe_b12.rs) on the 4 new sole-inline runs: zero divergence again (only the out-of-domain
inherited-page-resources probe, which the reference fails too).

## Batch 14 (meta r30e, tests r30, solution r30) - Orion x4: 2/4

| Run (platform #) | Verdict | Failed new tests | Approach / note |
|---|---|---|---|
| Orion_Orion_1 (#4) | FAIL_MISSED_REQUIREMENT | type3_font_chosen_by_a_graphics_state_hides_its_content | Type 3 font selected via ExtGState /Font not baked |
| Orion_Orion_2 (#3) | PASS_LEGITIMATE (FP genuine, dissent) | - | flex_iter resolves gs /Font size; hidden Type 3 glyph fills -> n under Tr 7 |
| Orion_Orion_3 (#2) | FAIL_MISSED_REQUIREMENT | hidden_image_inherited_into_a_form_is_not_drawn | loses caller-resource fallback for a form with empty /Resources |
| Orion_Orion_4 (#1) | PASS_LEGITIMATE (FP genuine, dissent) | - | swaps to a hidden Type 3 font copy via Tf; gs /Font size only if direct |

Round 31 replay (+1 indirect gs font-size test): Orion_Orion_4 flips to fail -> Orion 1/4. Reference 74/74.

## Batch 15 = ACCEPTED (2026-10-12; meta r30e, tests r31 74 new, solution r30): re-eval of batch 14 + Nova x8 -> Nova 0/8, Orion 1/4

| Run (platform #) | Verdict | Failed new tests | seq len (Nova) |
|---|---|---|---|
| Nova #8 | FAIL_MISSED_REQUIREMENT | F-83 x3 (caller render/clip mode, nested), type3 gs, soft-mask group | 527k |
| Nova #7 | FAIL_MISSED_REQUIREMENT | 15: F-83 x3, type3 gs, soft mask, every XObject-level /OC test | 515k |
| Nova #6 | FAIL_MISSED_REQUIREMENT | F-83 x3, type3 gs, soft-mask group | 523k |
| Nova #5 | FAIL_MISSED_REQUIREMENT | F-83 x3, type3 gs | 772k |
| Nova #4 | FAIL_MISSED_REQUIREMENT | 15 (as #7) | 505k |
| Nova #3 | FAIL_MISSED_REQUIREMENT | F-83 x3, type3 gs | 527k |
| Nova #2 | FAIL_MISSED_REQUIREMENT | F-83 x3, type3 gs, soft-mask group | 830k |
| Nova #1 | FAIL_MISSED_REQUIREMENT | F-83 x3, type3 gs, state before hidden inline image | 886k |
| Orion #4 | FAIL_MISSED_REQUIREMENT | type3_font_chosen_by_a_graphics_state_hides_its_content | - |
| Orion #3 | PASS_LEGITIMATE (FP genuine x3) | - | - |
| Orion #2 | FAIL_MISSED_REQUIREMENT | hidden_image_inherited_into_a_form_is_not_drawn | - |
| Orion #1 | FAIL_MISSED_REQUIREMENT | type3_font_size_given_by_reference_in_a_graphics_state_keeps_hidden_text_advancing | - |

Nova avg sequence length 636k. Kills: type3 gs 9, F-83 tests 8 each, soft-mask group 5, inherited image 3,
XObject-level /OC family 2 each. 57 of 74 tests killed nothing (incl. inline and tiling start mode).

