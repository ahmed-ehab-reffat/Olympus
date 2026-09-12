# DESIGN.md - ezdxf-attribute-sync

## 1. Title

Synchronize block reference attributes with their definitions

Verb-led, names the subsystem (block definitions and the ATTRIB entities of their references).

## 2. Shape classification

- Shape: **O-Composite-add** - a new capability spanning the block layout, the INSERT entity, the
  blocks section, the transformation machinery, the entity database and the DXF export.
- Pass rate target: <= 40% cap, design target 10-25%.
- Best agent: Orion / Vega (long horizon, many interacting behaviors).
- Dominant expected verdict: MISSED_REQUIREMENT (placement under transformation, idempotence,
  traversal scope) rather than REGRESSION.

## 3. Public API surface

All new surface hangs off existing classes, so the hidden tests import nothing new and fail at
runtime on base instead of failing to collect:

- `Insert.sync_attribs() -> AttribSyncReport`
- `BlockLayout.sync_attribs() -> AttribSyncReport`
- `BlockLayout.out_of_sync_references() -> list[Insert]`
- `BlockLayout.rename_attdef(old_tag, new_tag) -> AttribSyncReport`
- `BlockLayout.delete_attdef(tag) -> AttribSyncReport`
- `BlockLayout.reorder_attdefs(tags) -> AttribSyncReport`
- `BlocksSection.sync_attribs() -> AttribSyncReport`
- report fields: `references`, `added`, `removed`, `updated`, `changed`

Reused error types: `DXFKeyError`, `DXFValueError` (the conventions `Insert.delete_attrib` and the
blocks section already use).

## 4. Canonical output form

- A synchronized reference carries one ATTRIB per non-constant ATTDEF that has a tag, in the order
  of the definitions in the block layout.
- An existing ATTRIB keeps `text`, its handle, its owner and its XDATA; every other DXF attribute
  is the definition's, transformed by `Insert.matrix44()` - byte for byte what
  `Insert.add_auto_attribs()` produces for a newly created reference.
- Multiline definitions produce multiline ATTRIBs (`attribute_type` = 2, embedded MTEXT carrying
  the content); the content of a multiline ATTRIB or ATTDEF is its embedded MTEXT, never the
  first-line `text` field that `add_auto_attribs` settles for.
- Tags are compared case-folded wherever a tag is given, including the editing methods; the
  stored spelling is the definition's.
- `lock_position` is the ATTRIB's own and keeps `insert` and `align_point` (and the embedded
  MTEXT insert); a new ATTRIB inherits it from the definition.
- Removal: no matching definition, a constant definition, or a repeated tag after the first;
  a tag repeated among the DEFINITIONS also keeps only the first, otherwise the run never settles.
- Idempotence: a second run reports 0/0/0 and leaves the exported DXF byte identical.
- The content of a multiline ATTRIB is its embedded MTEXT, kept in full; `text` holds its first line.

## 5. Blind-spot pre-empts

- Sort/identity: attribute order is stated explicitly (definition order), so no undiscoverable
  ordering is pinned.
- The asymmetry "value is preserved, everything else is replaced" is stated in one sentence; the
  fix (recompute the target from the definition rather than patching the attribute) stays hidden.
- Traversal scope rides on "every reference of that block in the document", so no layout list and
  no algorithm is handed over.
- Codebase-inferable requirements: 1 (the `DXFKeyError` / `DXFValueError` convention).

## 6. Description draft

See meta.md: 697 words in 10 paragraphs, none over 150 words, no headers, backticks only on
new API names.

## 7. File footprint (measured)

| Action | Path | Raw | Human-effective |
| --- | --- | --- | --- |
| ADD | src/ezdxf/attsync.py | 475 | 346 |
| MODIFY | src/ezdxf/layouts/blocklayout.py | 80 | 23 |
| MODIFY | src/ezdxf/entities/insert.py | 17 | 4 |
| MODIFY | src/ezdxf/sections/blocks.py | 16 | 6 |
| TOTAL | 4 files | 588 | **379** |

Clears the 250 effective-LOC floor of the 2026-07 sprint rules.

## 8. Solution outline

- `_template(attdef, text, m)` - builds the target ATTRIB from the definition, embeds the MTEXT of
  a multiline definition and applies the reference transformation.
- `_state(attrib)` - comparable state of an ATTRIB (DXF attributes minus identity, plus the
  embedded MTEXT), the basis for change detection and for the dry run.
- `_apply(attrib, template)` - writes the target state onto an existing entity and reports whether
  anything changed.
- `_keep_location(template, attrib)` - the locked-position rule.
- `_sync_reference(...)` - the diff: match by case-folded tag, add, update, drop, reorder, count.
- `_block_references(block)` / `sync_document(doc)` - traversal over all layouts and all block
  definitions.
- `rename_attdef` / `delete_attdef` / `reorder_attdefs` - edit the definitions, then run the same
  synchronization.

No fixpoint loop needed: definitions are processed in order, one pass per reference.

## 9. Test file outline

`tests/test_04_dxf_high_level_structs/test_432_attribute_sync_64e0da.py`, 131 tests:

- membership, order, constant and untagged definitions (6)
- value, identity and XDATA preservation (4)
- properties and placement under translation, rotation, uniform and non-uniform scaling, a block
  base point, mirroring, extrusion and alignment (8)
- multiline definitions, defaults, content and conversions in both directions (7)
- removal, constant-state transitions, repeated tags on both sides, case folding (10)
- locked position, including the lock flag and a transformed reference (8)
- traversal, scope isolation, layout membership, undefined blocks, block flags (10)
- report counts, changed, idempotence including a byte-identical export (7)
- out-of-sync listing, one per kind of difference, plus discovery scope (13)
- rename, delete, reorder including case folded inputs and collisions, error cases,
  atomicity and idempotence after an edit (31)
- document-wide synchronization (4)
- document validity: entity database, audit, round trip (3)

The return container of `out_of_sync_references()` is deliberately not asserted: tests iterate the
result or wrap it in `list()`, so a tuple or generator passes.

## 10. Forced signatures

None beyond the method names listed in meta.md, all on existing classes.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Contract sentence | Test |
| --- | --- | --- | --- | --- |
| 1 | The attribute is placed by transforming the definition, not by copying its location | the obvious code copies `attdef.dxf.insert`; an agent's own smoke test uses an untransformed reference | "mapped into the block reference exactly as a reference newly created from that block would get it" | `test_attrib_placement_follows_rotation_and_scaling`, `..._mirroring`, `..._the_extrusion`, `test_aligned_definition_keeps_its_alignment` |
| 2 | Update in place, not delete and recreate | recreating is the shortest path and passes every value test | "stays the same entity, with its handle and its extended data" | `test_existing_attrib_stays_the_same_entity`, `test_extended_data_of_an_existing_attrib_survives` |
| 3 | Idempotence: the second run must change nothing and report nothing | an implementation that transforms the existing attribute again drifts its position every run; one that always rewrites reports changes forever | "Running it again afterwards changes nothing and reports nothing" | `test_second_sync_reports_no_change`, `test_second_sync_leaves_the_document_unchanged`, `test_document_sync_is_idempotent` |
| 4 | References inside other block definitions and in paper space | the natural traversal is `doc.modelspace().query("INSERT")` | "every reference of that block in the document" | `test_block_sync_covers_references_inside_block_definitions`, `test_block_sync_covers_modelspace_and_paperspace` |
| 5 | Multiline definitions need the embedded MTEXT path | copying the DXF attributes of a multiline definition yields `attribute_type` 4 (a definition) instead of 2 | "a definition holding multiline content included, which yields a multiline attribute carrying that text" | `test_multiline_definition_creates_a_multiline_attrib`, `test_multiline_attrib_carries_the_content_text` |
| 6 | Case-folded tag matching composed with rename and repetition | exact matching looks obviously right | "Tags are matched without regard to case and an attribute takes the spelling of its definition" | `test_tags_are_matched_without_regard_to_case`, `test_tags_differing_only_in_case_are_repetitions`, `test_rename_accepts_a_change_of_spelling` |
| 7 | Locked position overrides only the location | the rule composes with trap 1: the target still has to be computed, then partly overridden | "An attribute whose position is locked keeps its own insert point and align point" | `test_locked_attrib_keeps_its_location`, `test_locked_attrib_keeps_its_align_point`, `test_locked_attrib_follows_the_definition_otherwise` |
| 8 | The rename must win over a stale attribute already carrying the new tag | the order of rename and repetition removal decides the surviving value | "dropping another attribute that already carries it" | `test_rename_removes_an_attrib_that_already_carries_the_new_tag` |

Traps 1, 2, 3 and 7 are interdependent: the locked rule needs the computed target of trap 1, the
in-place update of trap 2 makes change detection necessary, and idempotence fails if any of them is
done by patching the existing entity instead of rebuilding its target state.

## 12. Tier and category

Olympus, feature request.

## 13. Predicted pass rate

15-30%. The semantics are recallable from CAD practice, so the difficulty lives in the integration:
the placement machinery, the identity-preserving update, the idempotence law, the traversal scope
and the multiline path.

## 14. Quality gate

- [x] Repo understanding: blocks section -> block layout -> INSERT -> linked ATTRIB entities; the
      transformation machinery is `Insert.matrix44()` and `Text.transform`.
- [x] Exclusivity: no PR or issue in `mozman/ezdxf` implements attribute synchronization.
- [x] Cold: zero commits on `insert.py`, `attrib.py` and `blocklayout.py` since 2025-01.
- [x] Base reproduces the gap: none of the methods exist, 67 of 67 new tests fail.
- [x] Effective LOC 281 >= 250 floor.
- [x] Vanilla suite green offline in the platform image, 3 runs identical.
- [x] Not pattern-followable: `add_auto_attribs` only adds attributes to a new reference and has no
      diff, no traversal, no change detection and no definition editing.

## 15. Hardening after batch 1 (2026-08-03)

Batch 1 landed 4 PASS / 5 = 80%. The forensics said the sync-only scope carries no difficulty:
the four passing patches still scored 113/113 on the suite as it stood, and five of six nasty
composition probes were byte-identical across all five implementations. Difficulty had to come from
SCOPE with doing-difficulty, not from more cases over the same behaviours.

Two axes added:

**A. `BlockLayout.attrib_placements()` - where the attributes land in the drawing.** A walk of the
block-reference graph from every layout, composing the transformation of each step, expanding
MINSERT grids into their elements, refusing to re-enter a block already on the path, and reporting
location, rotation and height as they end up in the drawing.

Trap-proof against the natural-but-wrong implementations, each producing a silent wrong answer:

| natural mistake | result | correct |
| --- | --- | --- |
| apply the current reference's own matrix to its attributes | (96, 6) | (98, 4) |
| treat a MINSERT grid as a single reference | 1 placement | 4 placements |
| reuse `chain_layouts_and_blocks()`, which the sync half of this feature uses | reports a block no layout reaches | none |

The third is the sharpest: the traversal the feature already uses elsewhere is the wrong one here,
so the reuse an agent naturally reaches for is a defect.

**B. Version-dependent multiline form.** A document older than R2018 cannot hold an embedded MTEXT
in an ATTRIB, so a multiline definition there yields a single line attribute carrying the first
line. The condition is one `dxfversion` test that the obvious code omits, and it composes with the
content rules already in the contract.

Result: 305 -> 379 human-effective LOC, 113 -> 125 tests, and all four batch-1 passers now fail 11
tests each.
