# feedback.md - ezdxf-attribute-sync

## Summary

- Repo: [mozman/ezdxf](https://github.com/mozman/ezdxf), Python, MIT, 1385 stars.
- BASE_COMMIT: `b3eb37b942acb4c7e2d2487706e614aa29b7f9b2` (2026-07-21, the default branch head).
- Tier: Olympus. Category: feature request. Shape: O-Composite-add.
- Feature: bring the ATTRIB entities of block references back in step with the ATTDEF entities of
  their block definition, plus renaming, deleting and reordering definitions with propagation.
- Status: built and validated end to end in the platform image. One Orion run so far, voided by
  a prompt defect that is now fixed; re-batch pending.

## Pick gates

| Gate | Result |
| --- | --- |
| 1 behavioral F2P gap | nothing in ezdxf updates an existing reference after its definitions change; `add_auto_attribs` only fills a fresh reference and never removes, updates or reorders. 131 of 131 new tests fail on base |
| 2 saturation | not a port of a documented reference; the synchronization contract (what is preserved, what is replaced, idempotence, the report) is invented for this repo |
| 3 uniform wrap | 8 traps, of which 4 are interdependent (placement, in-place update, idempotence, locked position) |
| 4 LOC ceiling | measured 379 human-effective across 4 files, above the 250 floor |
| 5 cold not live | zero commits on `insert.py`, `attrib.py`, `blocklayout.py` since 2025-01, repo otherwise active (99 commits in 12 months) |
| 6 reproduce on base | `Insert.sync_attribs` and friends do not exist; verified in the platform image |
| 7 dedup | our two earlier ezdxf submissions are drawing-unit rescale and document edit history, both different subsystems; nothing in `problems/`, `rejected/`, `Aprroved/`, `Olympus/` touches block attributes |
| 7b exclusivity | `gh pr list -R mozman/ezdxf --state all` searched for attribute, attdef, sync, block reference attributes, update attributes: nothing implements it. Issue #218 is about the block flag, not about synchronization, and carries no maintainer refusal |
| 8 defined behavior | no maintainer statement against it; the feature mirrors what CAD applications do and stays inside the existing entity model |
| 9 no flaky repo | vanilla suite 7424 passed / 76 skipped / 0 failed, three consecutive runs identical, offline |
| 10 repo quota | 3rd submission of ours on this repo, under the 6 cap; niche CAD library, no platform over-use warning seen |

## Environment

Platform image `olympus-base-python`, offline (`--network none`), non-root (uid 1000):

| Check | Result |
| --- | --- |
| vanilla suite (base mode, no patches) | 7424 passed, 76 skipped, 1 xfailed |
| test.patch only, new mode | 131 tests, 131 failures, 0 errors (per-test F2P, no collection error) |
| test.patch only, base mode | 7424 passed, unchanged |
| both patches, new mode | 131 passed |
| both patches, base mode | 7424 passed, no regressions |
| apply order test -> solution | clean |
| apply order solution -> test | clean |
| determinism | 3 runs of each mode, identical counts |

The exported DXF carries a fresh GUID on every write, so the two tests that compare exports switch
on `ezdxf.options.write_fixed_meta_data_for_testing`, the repo's own facility for that, and restore
the previous value afterwards.

## False-positive check: meta clause to test mapping

Every clause of meta.md maps to at least one test, and every test maps back to a clause.

| meta.md clause | Test(s) |
| --- | --- |
| `Insert.sync_attribs()` brings one reference in step | `test_sync_adds_an_attrib_for_each_definition`, `test_added_attrib_carries_the_default_text`, `test_insert_sync_leaves_the_other_references_alone` |
| `BlockLayout.sync_attribs()` for every reference of that block in the document | `test_block_sync_covers_modelspace_and_paperspace`, `test_block_sync_covers_references_inside_block_definitions`, `test_block_sync_leaves_references_of_other_blocks_alone` |
| `BlocksSection.sync_attribs()` every reference in the document | `test_document_sync_covers_every_block`, `test_document_sync_covers_paperspace_and_nested_references`, `test_document_sync_aggregates_removals_and_updates` |
| report counts references worked on | `test_report_counts_added_attribs`, `test_report_counts_updated_attribs`, `test_reference_of_an_undefined_block_is_left_alone` |
| report counts added / removed / updated | `test_report_counts_added_attribs`, `test_report_counts_removed_attribs`, `test_report_counts_updated_attribs` |
| updated means changed or moved | `test_report_counts_updated_attribs`, `test_reorder_changes_the_order_of_the_attribs`, `test_report_counts_a_moved_attrib` |
| `changed` is true when any count is not zero | `test_report_changed_is_false_without_changes`, `test_report_counts_added_attribs`, `test_rename_reports_the_changed_attrib` |
| running it again changes nothing and reports nothing | `test_second_sync_reports_no_change`, `test_second_sync_leaves_the_document_unchanged`, `test_document_sync_is_idempotent`, `test_sync_after_a_rename_reports_nothing`, `test_sync_after_a_reorder_reports_nothing` |
| one attribute per non-constant definition with a tag, in definition order | `test_sync_adds_an_attrib_for_each_definition`, `test_attribs_follow_the_order_of_the_definitions`, `test_constant_definition_gets_no_attrib`, `test_attrib_of_a_constant_definition_is_removed`, `test_definition_without_tag_is_ignored` |
| an existing attribute keeps its content text | `test_content_text_of_an_existing_attrib_is_preserved`, `test_a_new_default_does_not_overwrite_an_edited_attrib` |
| in full when that content is multiline | `test_multiline_content_of_an_attrib_is_kept_in_full`, `test_multiline_attrib_carries_the_content_text` |
| it stays the same entity with its handle | `test_existing_attrib_stays_the_same_entity` |
| and its extended data | `test_extended_data_of_an_existing_attrib_survives` |
| everything else comes from the definition | `test_properties_of_an_existing_attrib_follow_the_definition`, `test_attrib_property_absent_in_the_definition_is_discarded` |
| mapped into the reference as a newly created reference would get it | `test_added_attrib_matches_a_newly_created_reference`, `test_attrib_placement_follows_rotation_and_scaling`, `test_attrib_placement_follows_non_uniform_scaling`, `test_attrib_placement_follows_a_block_base_point`, `test_attrib_placement_follows_mirroring`, `test_attrib_placement_follows_the_extrusion`, `test_aligned_definition_keeps_its_alignment` |
| a multiline definition yields a multiline attribute carrying that text | `test_multiline_definition_creates_a_multiline_attrib`, `test_multiline_attrib_carries_the_content_text`, `test_attrib_becomes_multiline_when_its_definition_does`, `test_attrib_becomes_single_line_when_its_definition_does` |
| whose single line text is the first line of it | `test_multiline_content_of_an_attrib_is_kept_in_full` |
| a new attribute takes the text of its definition, in full when that is multiline | `test_added_attrib_carries_the_default_text`, `test_added_multiline_attrib_carries_the_full_default`, `test_definition_turned_back_non_constant_recreates_the_attrib` |
| an attribute with no definition is removed | `test_attrib_without_a_definition_is_removed`, `test_definition_turned_constant_removes_the_attrib` |
| a repeated tag, among the definitions or on a reference, keeps the first | `test_first_attrib_of_a_repeated_tag_is_kept`, `test_first_of_two_definitions_with_the_same_tag_counts`, `test_definitions_differing_only_in_case_are_one_definition`, `test_duplicate_definition_tags_settle_after_one_sync` |
| tags are matched without regard to case wherever one is given | `test_tags_are_matched_without_regard_to_case`, `test_tags_differing_only_in_case_are_repetitions`, `test_delete_accepts_a_tag_in_another_case`, `test_reorder_accepts_tags_in_another_case`, `test_rename_accepts_a_source_tag_in_another_case` |
| an attribute takes the spelling of its definition | `test_attrib_takes_the_spelling_of_the_definition` |
| whether an attribute's position is locked is its own | `test_locked_attrib_stays_locked`, `test_location_of_an_unlocked_attrib_is_reset` |
| a locked attribute keeps insert point and align point | `test_locked_attrib_keeps_its_location`, `test_locked_attrib_keeps_its_align_point`, `test_locked_attrib_keeps_its_place_when_the_reference_is_transformed` |
| everything else about a locked attribute follows the definition | `test_locked_attrib_follows_the_definition_otherwise`, `test_added_attrib_takes_the_locked_flag_of_its_definition` |
| a reference of an undefined block is left alone and not counted | `test_reference_of_an_undefined_block_is_left_alone`, `test_document_sync_leaves_a_reference_of_an_undefined_block_alone` |
| a new attribute belongs to the document and to the layout of its reference | `test_added_attrib_is_stored_in_the_document`, `test_attrib_belongs_to_the_layout_of_its_reference`, `test_document_is_valid_after_sync`, `test_synced_attribs_survive_a_round_trip` |
| the block definition records non-constant definitions | `test_block_records_that_it_has_attribute_definitions`, `test_block_records_that_it_has_no_attribute_definitions`, `test_block_with_only_constant_definitions_records_no_attributes`, `test_block_flag_is_updated_without_any_reference` |
| `out_of_sync_references()` returns what a run would change | `test_out_of_sync_references_lists_the_affected_references`, `test_out_of_sync_references_is_empty_when_in_sync`, `test_out_of_sync_references_detects_a_stale_property`, `test_out_of_sync_references_detects_a_wrong_order`, `test_out_of_sync_references_detects_a_repeated_tag`, `test_out_of_sync_references_detects_an_unmatched_attrib`, `test_a_locked_attrib_in_its_own_place_is_in_sync`, `test_out_of_sync_references_covers_paperspace_and_nested_references`, `test_out_of_sync_references_ignores_foreign_and_undefined_references`, `test_out_of_sync_references_detects_stale_multiline_content`, `test_out_of_sync_references_detects_a_differing_tag_spelling`, `test_out_of_sync_references_accepts_an_edited_content` |
| and changes nothing itself | `test_out_of_sync_references_changes_nothing` |
| the three editing methods reach every reference and return the same report | `test_rename_reaches_every_reference`, `test_delete_reaches_every_reference`, `test_reorder_changes_the_order_of_the_attribs` |
| `rename_attdef()` renames and hands the content text over | `test_rename_transfers_the_value_of_the_attrib`, `test_rename_renames_the_definition`, `test_rename_reports_the_changed_attrib`, `test_rename_keeps_multiline_content_and_identity` |
| it drops another attribute that already carries the new tag | `test_rename_removes_an_attrib_that_already_carries_the_new_tag`, `test_rename_reports_the_dropped_attrib` |
| a different spelling of the same tag is allowed | `test_rename_accepts_a_change_of_spelling` |
| an undefined tag raises `DXFKeyError` | `test_rename_of_an_undefined_tag_raises_key_error` |
| an empty or already defined new tag raises `DXFValueError` | `test_rename_to_an_empty_tag_raises_value_error`, `test_rename_to_an_existing_tag_raises_value_error`, `test_rename_to_a_tag_differing_only_in_case_raises_value_error` |
| a rejected edit leaves the document as it was | `test_a_rejected_rename_changes_nothing`, `test_a_rejected_rename_of_an_unknown_tag_changes_nothing`, `test_a_rejected_delete_changes_nothing`, `test_a_rejected_reorder_changes_nothing` |
| `delete_attdef()` deletes definition and matching attributes | `test_delete_removes_definition_and_attribs`, `test_delete_of_a_constant_definition_leaves_attribs_alone` |
| it raises `DXFKeyError` for an undefined tag | `test_delete_of_an_undefined_tag_raises_key_error` |
| `reorder_attdefs()` rearranges definitions and attributes | `test_reorder_changes_the_order_of_the_definitions`, `test_reorder_changes_the_order_of_the_attribs`, `test_reorder_of_a_block_without_definitions_is_a_no_op` |
| the rest of the block content stays in place | `test_reorder_keeps_the_other_block_content_in_place` |
| a tag sequence that is not every definition exactly once raises `DXFValueError` | `test_reorder_with_a_missing_tag_raises_value_error`, `test_reorder_with_an_unknown_tag_raises_value_error`, `test_reorder_with_a_repeated_tag_raises_value_error`, `test_reorder_with_case_folded_duplicates_raises_value_error` |

No test asserts behavior that meta.md does not state: the three placement comparisons use effective
values (`dxf.get_default`) rather than stored ones, so an implementation that writes an explicit
default where the reference leaves it absent still passes.

## Coverage suggestions (2026-08-03)

All four were applied; the suite is 67 -> 72 tests and one of them found a real bug in the
reference solution.

- **Multiline updates - a reference bug.** The suggestion asked for genuinely multiline user
  content on resync. Reproduced: an attribute holding `first\Psecond` came back as `first`, because
  the preserved value was read from the single line `text` field, which ezdxf keeps at the first
  line of the embedded MTEXT. The reference now reads the embedded MTEXT as the content of a
  multiline attribute (`_content`), and meta.md states it: content is kept "in full when that
  content is multiline", its "single line text is the first line of it". Covered by
  `test_multiline_content_of_an_attrib_is_kept_in_full`.
- **Atomic reorder validation** and **rejected delete/rename atomicity**: the atomicity clause now
  covers both error kinds ("A rejected edit leaves the document as it was") and is asserted by
  serialization equality for a rejected rename, an unknown-tag rename, an unknown-tag delete and
  three rejected reorder sequences.
- **Duplicate reorder tags**: `reorder_attdefs(["A", "A"])` raises `DXFValueError`, asserted by
  `test_reorder_with_a_repeated_tag_raises_value_error`; the meta clause is now worded as "not the
  tags of all definitions each exactly once" instead of "not the complete set".

## Coverage suggestions, round two (2026-08-03)

All four applied, 72 -> 82 tests, and the third one found the second reference bug of the session.

- **A user-set position lock did not survive the run.** `lock_position` was taken from the
  definition like every other property, so a locked attribute was silently unlocked by the run that
  honoured its position, and the run after that moved it back - a straight violation of the stated
  idempotence law, in a scenario no earlier test combined. The lock is now the attribute's own,
  inherited from the definition only when the attribute is created; meta.md says "Whether an
  attribute's position is locked is its own". Covered by `test_locked_attrib_stays_locked`,
  `test_added_attrib_takes_the_locked_flag_of_its_definition` and
  `test_a_locked_attrib_in_its_own_place_is_in_sync`.
- **Only-constant block flag**: a block whose definitions are all constant now has its own test
  rather than relying on the no-definitions case.
- **Out-of-sync breadth**: separate tests for a stale property, a wrong order, a repeated tag and
  an unmatched attribute, plus the locked case above, which must NOT be listed.
- **Undefined references at aggregate scope**: `doc.blocks.sync_attribs()` leaves an INSERT of an
  undefined block untouched and out of the reference count, next to a valid reference.

## Coverage suggestions, round three (2026-08-03)

Both applied, 82 -> 84 tests, and the first one found the third reference bug.

- **A new attribute from a multiline definition kept only the first line.** The creation path fed
  the definition's single line `text` field into the new attribute, so a definition holding
  `first\Psecond` produced an attribute holding `first`. ezdxf's own `add_auto_attribs` truncates
  the same way, which makes this a good trap rather than a bad one: the tempting in-repo helper
  implements the wrong policy for this contract. The reference now reads the definition's embedded
  MTEXT (`_default_content`) and meta.md says a new attribute takes the text of its definition "in
  full when that is multiline". Covered by `test_added_multiline_attrib_carries_the_full_default`.
- **Document-wide nested coverage**: `test_document_sync_covers_paperspace_and_nested_references`
  drives `doc.blocks.sync_attribs()` over a modelspace, a paper space and a nested reference at
  once and checks the aggregate reference count.

## Coverage suggestions, round four (2026-08-03)

All three applied, 84 -> 87 tests. No new defect this round: each case was probed against the
reference first and already behaved correctly.

- **Insert-level scope isolation**: `test_insert_sync_leaves_the_other_references_alone` pins that
  `Insert.sync_attribs()` touches its own reference only and counts one reference.
- **Out-of-sync discovery scope**: two tests, one for finding stale references in paper space and
  inside another block definition, one for excluding references of other blocks and of undefined
  blocks.
- **Reorder non-ATTDEF stability**: `test_reorder_keeps_the_other_block_content_in_place` now
  builds a block with entities before, between and after the definitions and asserts their handles,
  their index positions and their liveness, instead of comparing the sequence of DXF type names.

## Coverage suggestions, round five (2026-08-03)

All three applied, 87 -> 92 tests. No defect: each case was probed against the reference first and
already behaved correctly.

- **Block transform edge cases**: fresh-reference equivalence with a non-zero block base point and
  with non-uniform x/y scaling, the two placement cases the earlier transform tests missed. The
  non-uniform test also asserts idempotence, because text cannot represent a non-uniform transform
  exactly and an implementation that re-transforms would drift.
- **Report details for collision edits**: `test_rename_reports_the_dropped_attrib` pins removed = 1
  and updated = 1 on the collision path.
- **Case-insensitive edit inputs**: yes, the rule is global. `delete_attdef("BETA")` and
  `reorder_attdefs(["beta", "ALPHA"])` work on definitions spelled `Beta` and `Alpha`, and meta.md
  now says tags are matched without regard to case "wherever one is given" instead of leaving the
  rule inside the synchronization paragraph.

## Coverage suggestions, round six (2026-08-03)

All three applied, 92 -> 98 tests. No defect: every transition was probed against the reference
first and already behaved correctly, idempotence included.

- **Multiline definition edits**: both directions. A single line attribute whose definition turns
  multiline becomes multiline and carries the user's value; a multiline attribute whose definition
  turns single line loses the embedded MTEXT and keeps its value. Both settle after one run.
- **Constant-state transitions**: turning a definition constant removes the attribute, drops the
  block flag and reports one removal; turning it back recreates the attribute with the definition's
  default (the earlier user edit is gone with the entity), sets the flag again and reports one
  addition, and the run after that is quiet.
- **Out-of-sync multiline and spelling**: a stale embedded MTEXT property and an attribute whose
  tag differs from its definition only in case are both reported by the non-mutating query.

No meta.md change was needed: every case maps to a clause that was already stated, which is the
first round where that held for all three.

## Coverage suggestions, round nine (2026-08-03)

Both applied, 105 -> 109 tests, no defect.

- **Case-insensitive validation collisions**: renaming `A` to `b` while `B` exists raises
  `DXFValueError`, and `reorder_attdefs(["A", "a"])` raises as well, both leaving the definitions
  untouched. The case rule holds on the validation side, not only on the lookup side.
- **Edit report idempotence**: synchronizing once more after a successful rename and after a
  successful reorder reports 0/0/0, which extends the no-op rerun guarantee to references the edit
  helpers touched.

## Coverage suggestions, round eight (2026-08-03)

All three applied, 102 -> 105 tests, no defect.

- **Move-only report semantics**: moving an unlocked attribute in space and syncing puts it back
  and counts one update.
- **Block flag without references**: a block with non-constant definitions and no reference at all
  still gets its flag, with references = 0 and changed False.
- **Locked placement under a later reference transformation**: after locking a custom insert and
  align point, rotating and scaling the reference leaves both points alone while height and
  rotation follow the transformed definition, and the next run is quiet. This is the sharpest
  locked-position case in the suite, because the naive reading (locked means the whole attribute
  is frozen) and the wrong reading (the transform wins over the lock) both fail it.

## Coverage suggestions, round ten (2026-08-03) - fourth reference bug, the worst one

Both applied, 109 -> 113 tests.

- **Duplicate ATTDEF tags churned forever.** Two definitions carrying the same tag (or tags
  differing only in case) made every run remove two attributes and add two back:
  `sync -> added 4`, then `added 2 / removed 2`, then `added 2 / removed 2`, without end, and
  `out_of_sync_references()` reported the reference every time. That is a permanent violation of
  the stated idempotence law, and it came from a contradiction in my own contract: the definition
  side yielded every tagged definition while the attribute side deduplicated by tag, so the second
  definition could never find the attribute the dedup pass had just removed. `_attdefs` now keeps
  the first definition per case-folded tag, which lines it up with the rule that already governed
  attributes on a reference and with `reorder_attdefs`. meta.md generalises the sentence: "where a
  tag turns up twice, among the definitions or on a reference, the first one counts". Guarded by
  `test_first_of_two_definitions_with_the_same_tag_counts`,
  `test_definitions_differing_only_in_case_are_one_definition` and
  `test_duplicate_definition_tags_settle_after_one_sync`.
- **Empty reorder**: `reorder_attdefs([])` on a block with no definitions was already a valid no-op
  under the "all definitions, each exactly once" contract; now pinned, document unchanged.

This is the fourth defect the coverage panel has found, and the second one that only shows up on
the second run. Both of those came from the idempotence law, which keeps earning its place in the
description.

## Fairness audit of the cycle rule (2026-08-03)

`test_placement_does_not_re_enter_a_block_on_the_path` was checked against its clause and the
clause was too loose. The wording said "a path is not FOLLOWED back into a block it already passed
through", which most naturally describes the recursion, so two readings were compliant:

| reading | placements |
| --- | --- |
| the re-entering reference is skipped altogether (what the test asserts) | 1 |
| the reference is placed, only the recursion stops | 3 |

Both were implemented and run to confirm the gap is real, not theoretical. The test was right; the
sentence was underspecified, the same defect class as the batch-1 `FAIL_TEST_MISMATCH`. meta.md now
reads "a reference leading back into a block the path already passed through is left out along with
everything under it", which admits one answer. No test or source change.

Every other placement clause was re-read for the same problem: tab order, more-than-one-way,
grid elements, unreachable blocks, drawing-measured rotation and height, and entity order are each
pinned by a sentence with a single reading.

## Coverage suggestions, round twelve (2026-08-03) - transform breadth

All three applied, 128 -> 131 tests, no defect.

- **Placement transform breadth**: one test carrying extrusion (0,0,-1), a mirrored and
  non-uniformly scaled nested reference (-1, 2, 3), two rotations and 3D offsets at both levels.
  The expected numbers were taken from ezdxf's own machinery as an independent oracle: exploding
  the top reference and then the nested one turns the attribute into a TEXT entity whose insert,
  rotation and height match the placement to six decimals. The literal values are asserted in the
  test rather than computed, so the test does not hand over an implementation route.
- **Reorder preservation**: the moved attribute keeps its identity, handle, embedded multiline
  content and XDATA, the counterpart of the rename preservation test.
- **Entity-order traversal**: three references of the target interleaved with a LINE and a CIRCLE
  inside one block, two attributes each, asserting all six placements in entity order.

## AI-shape check (2026-08-03)

Flagged: 2 paragraphs over 150 words of unbroken prose. Split at topic boundaries into 10
paragraphs, longest now 125 words; no em dashes, ASCII, and not a single clause reworded, so the
description-to-test mapping is untouched. Bullets were not used: the platform rubric asks for plain
prose without bulleted requirement lists.

## Coverage suggestions, round eleven (2026-08-03) - on the new axis

Both applied, 125 -> 128 tests, no defect.

- **Placement ordering across paper layouts**: two layouts created in one order and given the
  opposite tab order; placements follow tab order, not creation order.
- **Deep recursive paths**: a diamond where two sibling blocks both reach the target from a common
  host three levels down, plus a self-reference on that host. Both paths contribute and the cycle
  guard stops only the path it is on - an implementation with a global visited set would report one
  placement instead of two. A separate test covers one nested reference reached by two hosts, which
  is placed once per host while remaining a single entity. One meta sentence added for the
  more-than-one-way rule.

## Hardening round after batch 1 (2026-08-03)

Batch 1 at 80% was too easy, and the forensics ruled out more tests as a lever. Two capabilities
added, both with difficulty in DOING rather than in knowing the contract - detail in DESIGN.md 15.

- `BlockLayout.attrib_placements()`: where every attribute of every reference of the block ends up
  in the drawing, reached from the layouts through nested blocks and MINSERT grids, transformations
  composed along the way, paths never re-entering a block, unreachable blocks reporting nothing.
  Three natural-but-wrong implementations were written and all three give silent wrong answers.
- A multiline definition in a document older than R2018 yields a single line attribute carrying the
  first line, because the format cannot hold the embedded text there.

131 tests (was 113), 379 human-effective LOC (was 305), meta 697 words - the word cap was waived
for this round. All four batch-1 passing patches now fail 11 tests each, so the artifact is no
longer solved by what solved it before.

The description-quality checker will object to the new paragraph as it objected to the others; the
answer is the same, and now has batch evidence behind it: the sync-only description scored 80%.

## Batch 1 (2026-08-03) - one Orion run, FAIL_TEST_MISMATCH, prompt fixed

First agent run. Verdict FAIL_TEST_MISMATCH with an environment blocker of type `verifier`,
`agentBlameUnfair: true`, high confidence. The evaluator was right on both counts, and both are my
defects, not the agent's:

1. **The report was not stated as counts.** The sentence read "the block references worked on as
   `references`, the attributes as `added`, `removed` and `updated`". Lists of the affected
   entities are a legitimate reading of that, and the agent took it, so every `report.added == 4`
   style assertion failed - 27 of 109 tests, all of them report-shaped. The head of that sentence
   used to say "a report counting ..."; the word was lost in the description-quality trimming
   rounds, which is where the ambiguity entered. It now reads "a report of whole numbers:
   `references` counts ... `added`, `removed` and `updated` count attributes".
2. **"reports nothing" swallowed `references`.** A repeat run reports no changes but still counts
   the references it looked at, which is what `test_report_changed_is_false_without_changes`
   asserts. The prompt said "changes nothing and reports nothing", which reads as all four fields
   zero. It now says `references` counts the block references it worked on, "needed or not", and
   that a repeat run "reports no addition, removal or update".

No solution or test change: the reference already returns ints and already counts a reference that
needed nothing, and the tests already pinned both. The description was the broken instrument.
Paid for the extra words by cutting context from the opening sentence; the body is 492 words.

Lesson for the next trimming round: the description-quality check pushed for exactly this sentence
to be cut, and trimming it part-way is what broke it. A clause that a hidden test asserts is not
verbosity, and shortening it is not free.

## Description-quality review, third round (2026-08-03) - held, with evidence

The check repeated the same two high-priority asks (drop the method names, drop the report field
names) plus three medium ones (drop `out_of_sync_references()`, drop "reaches every reference and
returns the same report", drop the named exception classes). Its stated premise is that all of this
is "discoverable in the codebase" / "evident from the existing report type in code". That premise
is false and is now checked three times:

    git show <base>:src/ezdxf/entities/insert.py     | grep -c sync_attribs            -> 0
    git show <base>:src/ezdxf/layouts/blocklayout.py | grep -c ...rename_attdef...     -> 0
    git show <base>:src/ezdxf/sections/blocks.py     | grep -c ...sync_attribs...      -> 0
    git grep -c AttribSyncReport <base> -- src                                         -> no files

Nothing named in those clauses exists at the pinned commit. They are the feature.

The decisive evidence is the Test Fairness report on the same artifact, which reached the opposite
conclusion clause by clause and used exactly these sentences as the fairness grounds:

- 3 verdicts rest on the report-field clause, e.g. `test_report_counts_added_attribs`:
  "The prompt defines all three report fields and their meanings."
- 4 verdicts rest on the named exception classes, e.g.
  `test_rename_of_an_undefined_tag_raises_key_error`: "The prompt explicitly requires DXFKeyError
  for a tag that is not defined."
- 3 verdicts rest on the named entry points, e.g. `test_insert_sync_leaves_the_other_references_alone`:
  "The prompt says Insert.sync_attribs operates on one reference and reports references worked on."

Cutting those clauses would convert at least 10 currently-fair tests into hidden requirements and
turn the Test Fairness PASS back into a FAIL, which is the harder reject
(`FALSE_POSITIVES.md`: cutting a clause while a test still asserts it). It would also leave 109
hidden tests calling methods nobody can name, which is unsolvable rather than under-specified.

Held deliberately. The valid parts of rounds one and two were applied (the description went 484 ->
455 words before the coverage rounds added the clauses they required, and it sits at 496 now). If
a human reviewer wants the surface reduced, the one clean lever is deleting
`out_of_sync_references()` outright - one sentence, 13 tests, about 15 effective LOC - which
removes the capability instead of hiding it. That is a scope decision, not a wording one.

## Test Fairness review (2026-08-03) - FAIL fixed

The check returned FAIL, 2 of 98 unfair, and it was right. Two tests compared
`out_of_sync_references()` against the literal `[]`, which pins `list` as the return container.
meta.md only promises the references a synchronization would change, and the neighbouring
`BlockLayout.attdefs()` returns a generator typed `Iterable`, so a tuple or generator would be a
correct solution that fails those two assertions. Both now read
`assert list(block.out_of_sync_references()) == []`, which asserts emptiness without pinning a
container. The rest of the suite already iterated the result (`{e.dxf.handle for e in ...}` or a
list comprehension) and needed no change; a grep confirms no bare-equality comparison against the
returned collection remains.

Everything else in the report came back fair: 96 tests classified prompt-stated, repo-discoverable
or standard external semantics, with the placement, flag, ownership, audit and persistence
assertions all traced to source lines in the repository.

## Coverage suggestions, round seven (2026-08-03)

All four applied, 98 -> 102 tests, no defect found.

- **Preserved content after ordinary ATTDEF text edits**: changing a definition's default while the
  matching attribute carries a user edit keeps the edit and still updates the other fields.
- **Out-of-sync ignores allowed user content differences**: a reference is not flagged just because
  its attribute text differs from the definition default.
- **Case-insensitive edit source lookup**: `rename_attdef("alpha", "Gamma")` finds definition
  `Alpha`, which is the "wherever one is given" rule applied to the rename source.
- **Document-level report aggregation**: `doc.blocks.sync_attribs()` sums removals and updates
  across two block definitions, not only additions.

## Description-quality review (2026-08-03)

The automated "only necessary information" check raised five points. Two were correct and are
applied; the description went 484 -> 455 words, then to 496 with the clauses the coverage
suggestion rounds required:

- cut "References live in the modelspace, in paper space layouts and inside other block
  definitions" - redundant with "every reference of that block in the document", which the
  traversal tests now trace to;
- cut "so a synchronized document audits and writes out cleanly" - a consequence of the retained
  clause "belongs to the document and to the layout of its reference";
- the three method paragraphs were rewritten behavior first and the error rules folded into one
  sentence.

The three points marked high rest on a false premise: they call `sync_attribs`,
`out_of_sync_references`, `rename_attdef`, `delete_attdef` and `reorder_attdefs` "existing APIs"
whose behavior is "discoverable in the code". None of them exists at the base commit - verified
with `git show <base>:src/ezdxf/entities/insert.py | grep -c sync_attribs` = 0 and the same for
`blocklayout.py` = 0. They are the feature. Removing their names would leave the hidden tests
calling methods nobody can name, which is unsolvable rather than under-specified, and would turn
every assertion behind them into a hidden requirement, the mirror of the false-positive failure
(`FALSE_POSITIVES.md`: cutting a clause while a test still asserts it is the harder reject). The
report fields and the idempotence rule are in the same position: `report.added`, `.removed`,
`.updated`, `.references` and `.changed` are asserted by 8 tests, and "running it again changes
nothing and reports nothing" is the load-bearing law that separates a correct implementation from
one that rewrites unconditionally. The names and those two rules therefore stay.

## Validation

| Check | Result |
| --- | --- |
| human-effective LOC (Counter 2) | 379 across 4 files (raw 588) |
| new tests | 131, all failing on base, all passing with the solution |
| base mode | 7424 of the repository's own cases, green on both trees |
| offline, non-root, both apply orders, 3x determinism | all clean |
| patch encoding | ASCII, LF, `test.sh` mode 100755 |
| banned markers in test names | none |

## Assumptions logged

- Autonomous one-shot run, no pause at the design gate.
- Tests are pytest cases in the repository's own test tree and reach the feature through methods on
  existing classes, so they collect on base and fail on assertions rather than on imports.
- The report shape and the locked-position rule are invented for this feature, so both are stated
  in meta.md verbatim; everything else reuses ezdxf's own conventions and error types.

The second round of the same check repeated the API-name objection (now with the report fields,
the idempotence rule, the "as a newly created reference" comparison and
`out_of_sync_references()`); the answer above stands, and the base tree still contains none of
these names. The comparison clause is the only fair way to pin placement under rotation, scaling,
mirroring and extrusion without dictating the algorithm, and idempotence is what separates a
correct implementation from one that rewrites on every run.
