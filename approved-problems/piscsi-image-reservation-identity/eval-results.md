# eval-results — piscsi-image-reservation-identity

No platform batch yet. Local validation numbers are logged below as they are measured.

| Batch | Agent | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach |
|---|---|---|---|---|---|---|---|---|

## Local validation — core slice, 2026-09-21

| Check | Result |
|---|---|
| Cold `docker build --no-cache` (platform order, pristine clone) | 4m59s (RUN 264s, export 24s) |
| base mode, no solution, uid 1000 / root | 316 pass / 0 fail, both |
| new mode, no solution | 14 of 14 fail, both uids |
| base mode, with solution | 316 / 0, both uids |
| new mode, with solution | 14 / 0, both uids |
| Baseline determinism (probe image, uid 1000) | 3 identical runs |
| human-effective LOC (hook) | 23 (slice only; floor 200 owed at FINISH) |

## Local validation — round 3 (27 tests), 2026-09-23

| Check | Result |
|---|---|
| Cold `docker build` (platform order, pristine clone) | 12m28s |
| base mode, no solution, uid 0 / 1000 | 316 pass / 0 fail, both |
| new mode, no solution | 27 of 27 fail, both uids |
| base mode, with solution, 3 runs | 316 / 0 each, both uids |
| new mode, with solution, 3 runs | 27 / 0 each, both uids |
| human-effective LOC (hook) | 54 (floor 200 still owed) |

## Local validation — round 4 (35 tests), 2026-09-23

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 | 316 pass / 0 fail, both |
| new mode, no solution | 35 of 35 fail, both uids |
| base mode, with solution, 3 runs | 316 / 0 each, both uids |
| new mode, with solution, 3 runs | 35 / 0 each, both uids |
| human-effective LOC (hook) | 92 (floor 200 still owed) |

## Local validation — round 5 (sharing + holder report, 52 tests), 2026-09-23

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 316 pass / 0 fail, all three |
| new mode, no solution | compile fallback, 1 failing case, all three |
| base mode, with solution, 3 runs | 316 / 0 each, all three uids |
| new mode, with solution, 3 runs | 52 / 0 each, all three uids |
| Counter 1 / hook human-effective | 216 / 168 |

## Local validation — round 6 (unprotect + holder messages, 53 tests), 2026-09-23

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 316 pass / 0 fail, all three |
| new mode, no solution | compile fallback, 1 failing case, all three |
| base mode, with solution, 3 runs | 316 / 0 each, all three uids |
| new mode, with solution, 3 runs | 53 / 0 each, all three uids |
| Counter 1 / hook human-effective | 217 / 169 |

## Local validation — round 7 (named fallback, 54 tests), 2026-09-24

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 316 pass / 0 fail, all three |
| new mode, no solution | 54 named failures (same ids as the solution run), all three |
| base mode, with solution, 3 runs | 316 / 0 each, all three uids |
| new mode, with solution, 3 runs | 54 / 0 each, all three uids |

## Local validation — round 8 (dup ids, read-only disks, 57 tests), 2026-09-24

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 316 pass / 0 fail, all three |
| new mode, no solution | 57 named failures (same ids as the solution run), all three |
| base mode, with solution, 3 runs | 316 / 0 each, all three uids |
| new mode, with solution, 3 runs | 57 / 0 each, all three uids |
| Counter 1 / hook human-effective | 227 / 175 |

## Local validation — round 9 (real creates, LUN holders, 58 tests), 2026-09-24

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 316 pass / 0 fail, all three |
| new mode, no solution | 58 named failures (same ids as the solution run), all three |
| base mode, with solution, 3 runs | 316 / 0 each, all three uids |
| new mode, with solution, 3 runs | 58 / 0 each, all three uids |
| Counter 1 / hook human-effective | 228 / 176 |

## Local validation — round 10 (nopasswd create, external link, same-ID LUNs, 61 tests), 2026-09-24

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 316 pass / 0 fail, all three |
| new mode, no solution | 61 named failures (same ids as the solution run), all three |
| base mode, with solution, 3 runs | 316 / 0 each, all three uids |
| new mode, with solution, 3 runs | 61 / 0 each, all three uids |

## Local validation — round 11 (cwd precedence, batch holder message, ValidateFile back in base, 62 tests), 2026-09-24

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 317 pass / 0 fail, all three |
| new mode, no solution | 62 named failures (same ids as the solution run), all three |
| base mode, with solution, 3 runs | 317 / 0 each, all three uids |
| new mode, with solution, 3 runs | 62 / 0 each, all three uids |

## Local validation — round 12 (per-holder identity with held descriptor, cwd device holders, 64 tests), 2026-09-24

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 317 pass / 0 fail, all three |
| new mode, no solution | 64 named failures (same ids as the solution run), all three |
| base mode, with solution, 3 runs | 317 / 0 each, all three uids |
| new mode, with solution, 3 runs | 64 / 0 each, all three uids |
| Counter 1 / hook human-effective | 279 / 210 |

## Local validation — round 13 (`..` after folder links, 65 tests), 2026-09-24

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 317 pass / 0 fail, all three |
| new mode, no solution | 65 named failures (same ids as the solution run), all three |
| base mode, with solution, 3 runs | 317 / 0 each, all three uids |
| new mode, with solution, 3 runs | 65 / 0 each, all three uids |
| Counter 1 / hook human-effective | 281 / 212 |

## Batch 1 — 10 x Nova, 2026-09-24: 1/10 pass (Nova #9)

Auto Review: Description 3/3, Tests 2/3, Solution 1/3 (revision requested). Adjudicator: the one pass is genuine (judge-c flagged a stale private filename after a refused insert as FP; adjudicated inert, not prompt-observable).

| Batch | Agent | Verdict | Files | +lines | Failed tests | Note |
|---|---|---|---|---|---|---|
| 1 | Nova #10 | FAIL | 10 | +396 | cd_roms_share_one_image_under_any_name, detaching_one_reader_keeps_the_others_holding, ejecting_one_reader_keeps_the_others_holding, one_command_may_attach_several_cd_roms_to_one_image, one_command_with_a_cd_rom_and_a_disk_on_one_image_attaches_nothing, image_file_information_lists_the_holders, scsictl_device_list_names_the_devices_sharing_an_image, refusals_name_every_conflicting_holder, holders_are_ordered_by_id_and_then_lun, image_file_information_reports_the_lun_of_each_holder, devices_sharing_an_image_from_the_working_directory_report_each_other, hold_stays_with_the_file_after_its_name_is_reused | The agent passed all baseline tests but failed 12 of 65 new image-reservation tests. The main implementation errors are incorrect reader classification before i |
| 1 | Nova #9 | PASS | 9 | +487 | - | Agent passed all baseline and new tests with a legitimate implementation. |
| 1 | Nova #8 | FAIL | 9 | +401 | insert_with_dot_segment_is_refused_while_attached, writer_is_refused_while_a_cd_rom_holds_the_image | The agent implemented most of the reservation feature, but two new tests fail because a refused insert leaves the removable device with a medium still loaded. |
| 1 | Nova #7 | FAIL | 9 | +389 | image_commands_accept_both_name_forms_in_every_position, one_command_with_a_cd_rom_and_a_disk_on_one_image_attaches_nothing, create_resolves_names_and_refuses_names_outside_the_image_folder, refusals_name_every_conflicting_holder, unprotect_of_a_held_image_is_refused_until_it_is_released, create_works_for_a_user_without_a_passwd_entry | The agent implemented most of the feature and preserved the baseline suite, but six new tests fail because path normalization, multi-device holder identity, and |
| 1 | Nova #6 | FAIL | 10 | +348 | create_works_for_a_user_without_a_passwd_entry, hold_stays_with_the_file_after_its_name_is_reused | The agent passed all baseline tests but failed 2 of 65 new tests: passwd-less image creation and preserving a reservation when a held filename is reused. |
| 1 | Nova #5 | FAIL | 9 | +371 | delete_with_dot_segment_succeeds_when_not_attached, delete_with_absolute_name_succeeds_after_detach, create_works_for_a_user_without_a_passwd_entry, devices_sharing_an_image_from_the_working_directory_report_each_other, hold_stays_with_the_file_after_its_name_is_reused | The agent implemented most of the feature and preserved all baseline behavior, but 5 of 65 new tests fail due to reservation identity/state handling and several |
| 1 | Nova #4 | FAIL | 11 | +417 | insert_with_dot_segment_is_refused_while_attached, image_commands_accept_both_name_forms_in_every_position, writer_is_refused_while_a_cd_rom_holds_the_image, create_resolves_names_and_refuses_names_outside_the_image_folder, refusals_name_every_conflicting_holder, unprotect_of_a_held_image_is_refused_until_it_is_released, create_works_for_a_user_without_a_passwd_entry, devices_sharing_an_image_from_the_working_directory_report_each_other | Agent passed all baseline tests but failed 8 of 65 new image-reservation tests. |
| 1 | Nova #3 | FAIL | 14 | +578 | create_works_for_a_user_without_a_passwd_entry | Agent passed all baseline tests and 64 of 65 new tests, but missed the passwd-less user ownership requirement. |
| 1 | Nova #2 | FAIL | 10 | +363 | one_command_with_a_cd_rom_and_a_disk_on_one_image_attaches_nothing, hold_stays_with_the_file_after_its_name_is_reused | Baseline tests passed, but two new image-reservation tests failed due to incorrect dry-run holder bookkeeping and pathname reuse handling. |
| 1 | Nova #1 | FAIL | 12 | +411 | image_commands_refuse_names_outside_the_image_folder, links_inside_the_image_folder_stay_usable, create_resolves_names_and_refuses_names_outside_the_image_folder, create_works_for_a_user_without_a_passwd_entry, hold_stays_with_the_file_after_its_name_is_reused, dot_dot_after_a_folder_link_is_resolved_through_the_link | The agent passed all baseline tests but failed 6 of 65 new tests due to explicit path-resolution, rename/reuse identity, and missing-passwd ownership requiremen |

Kill counts: no-passwd create 6, rename/name reuse 5, batch conflict message 3, refusal messages 3, working-directory device holders 3, create name resolution 3, refused-insert cleanup 2, reader-after-open 1 run (12 tests).

## Local validation — after batch 1 (device reporting by retained identity, 66 tests), 2026-09-24

| Check | Result |
|---|---|
| Replay of the 10 batch-1 agent patches vs the new test.patch | 0/10 (all fail `device_list_follows_the_held_file_after_its_name_is_reused`); reference 66/66 |
| base mode, no solution, uid 0 / 1000 / 4242 | 317 pass / 0 fail, all three |
| new mode, no solution | 66 named failures (same ids as the solution run), all three |
| base / new mode, with solution, 3 runs | 317 / 0 and 66 / 0 each, all three uids |
| Counter 1 / hook human-effective | 294 / 221 |

## Batch 2 — 10 x Nova, 2026-09-25: 3/10 pass — ACCEPTED (Auto Review Approved 3/3/3)

| Batch | Agent | Verdict | Files | +lines | Prompt tokens | Failed tests | Note |
|---|---|---|---|---|---|---|---|
| 2 | Nova #10 | PASS | 9 | +354 | 23468562 | - | Agent passed all baseline and new tests with a legitimate implementation. |
| 2 | Nova #9 | PASS | 13 | +499 | 15496528 | - | Agent passed all baseline and new tests with a legitimate implementation. |
| 2 | Nova #8 | FAIL | 12 | +557 | 18707710 | hold_stays_with_the_file_after_its_name_is_reused, device_list_follows_the_held_file_after_its_name_is_reused | The agent passed all 317 baseline tests and 64 of 66 new tests, but failed the explicit rename-and-name-reuse reservation behavior. |
| 2 | Nova #7 | FAIL | 9 | +354 | 16471493 | delete_with_dot_segment_succeeds_when_not_attached, delete_with_dot_segment_succeeds_after_detach, delete_with_dot_segment_succeeds_after_eject, delete_with_absolute_name_succeeds_after_detach, rename_with_parent_segment_succeeds_after_detach, copy_with_absolute_names_succeeds_when_not_attached, links_inside_the_image_folder_stay_usable, image_commands_accept_both_name_forms_in_every_position, detaching_one_reader_keeps_the_others_holding, create_resolves_names_and_refuses_names_outside_the_image_folder, refusals_name_every_conflicting_holder, unprotect_of_a_held_image_is_refused_until_it_is_released, image_that_links_to_a_file_outside_the_folder_can_be_used, create_works_for_a_user_without_a_passwd_entry | The agent passed all baseline tests but failed 14 of 66 new image-reservation tests because image-command path normalization and missing-destination h |
| 2 | Nova #6 | FAIL | 10 | +416 | 31165610 | links_inside_the_image_folder_stay_usable, image_that_links_to_a_file_outside_the_folder_can_be_used | Agent passed all baseline tests but failed two new tests because image commands reject a symlink inside the image folder when its target is outside th |
| 2 | Nova #5 | FAIL | 9 | +387 | 19092486 | one_command_with_a_cd_rom_and_a_disk_on_one_image_attaches_nothing, create_works_for_a_user_without_a_passwd_entry | The agent delivered a substantial implementation that preserved all baseline behavior, but it failed 2 of 66 new tests for two explicitly required edg |
| 2 | Nova #4 | PASS | 12 | +575 | 38785375 | - | Agent passed all baseline and new tests with a legitimate implementation of identity-aware image reservations. |
| 2 | Nova #3 | FAIL | 9 | +497 | 19326511 | create_works_for_a_user_without_a_passwd_entry, hold_stays_with_the_file_after_its_name_is_reused, device_list_follows_the_held_file_after_its_name_is_reused | The agent implemented most of the reservation feature and passed all baseline tests, but failed three explicit new requirements: preserving identity a |
| 2 | Nova #2 | FAIL | 10 | +373 | 22613735 | one_command_with_a_cd_rom_and_a_disk_on_one_image_attaches_nothing | The agent implemented nearly all of the reservation feature: all baseline tests and 65 of 66 new tests pass. The remaining atomic multi-device attach  |
| 2 | Nova #1 | FAIL | 12 | +483 | 15536693 | image_commands_refuse_names_outside_the_image_folder, links_inside_the_image_folder_stay_usable, one_command_with_a_cd_rom_and_a_disk_on_one_image_attaches_nothing, create_resolves_names_and_refuses_names_outside_the_image_folder, hold_stays_with_the_file_after_its_name_is_reused, dot_dot_after_a_folder_link_is_resolved_through_the_link | The agent implemented most of the feature, but six new image-reservation tests fail because path normalization, dry-run holder identity, and name-reus |

Cause map across both batches (see failure-patterns.md): F-59 name-reuse identity 5+3, F-39 passwd-less create 6+3, F-58 dry-run -1:0 staging 2+3, F-60 final-link containment 2+3, F-61 refused-insert cleanup 2+0, F-10 cwd x reporting 3+0. 37 of 66 tests never killed in either batch.
