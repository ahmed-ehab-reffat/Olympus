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
