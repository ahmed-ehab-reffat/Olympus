# DESIGN.md — pydicom-multiframe-frames

Repo: https://github.com/pydicom/pydicom (MIT, 2193 stars, Python, active 2026-08-02)
BASE_COMMIT: 0e98c4aeecce7c3ae537e3fbe9133d3fbc005796

## 1. Title

Split and combine enhanced multi-frame instances by frame

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (new capability + subtle algorithmic correctness across a shared kernel)
- Definition (PLAYBOOK Pattern 12): new variant plus subtle algorithmic correctness; 6 files, ~530 LOC, ~62 tests, historical landing ~8%.
- Pass-rate target: **<=40% cap; design to the corpus mode 1/10.**
- Best agent: Mixed (Orion decisive on long-horizon)
- Dominant verdict: MISSED_REQUIREMENT (the globally-coupled promotion/demotion rule)

## 3. Public API surface

New module `pydicom.multiframe`, re-exported from `pydicom`.

- `frame_attributes(ds, index) -> Dataset` — effective functional-group attributes for one zero-based frame.
- `extract_frames(ds, indices) -> Dataset` — a new instance holding only the listed frames, in the listed order.
- `merge_frames(datasets) -> Dataset` — a new instance holding every frame of every input, in input order.
- `varying_attributes(ds) -> set[BaseTag]` — tags whose effective value is not the same for every frame.
- `MultiFrameError` — raised for an instance that is not enhanced multi-frame, a bad frame index, and incompatible inputs to `merge_frames`.

Semantics (one line each):
- A functional group macro is one element of an item of `SharedFunctionalGroupsSequence` or `PerFrameFunctionalGroupsSequence`.
- Per-frame macros take precedence over shared macros of the same tag.
- `frame_attributes` returns the macro items' contents flattened one level: shared first, per-frame second.

## 4. Canonical output form

- `frame_attributes` result: a `Dataset` whose elements are the elements found inside the macro items; shared applied first, per-frame applied second so a per-frame element with the same tag replaces the shared one. Nested sequences are copied whole. Element order is pydicom's usual tag order.
- `extract_frames` frame order: exactly the order given in `indices`; duplicates are an error; indices out of range are an error; an empty selection is an error.
- Promotion: a macro present, with an equal value, in every selected per-frame item moves into `SharedFunctionalGroupsSequence` and is removed from every per-frame item. Equality is DICOM value equality of the whole macro.
- Demotion (`merge_frames`): a macro shared in one input but absent or different in another is written into each of that input's per-frame items; only macros equal across every input stay shared.
- `DimensionIndexValues` (inside `FrameContentSequence`): each dimension is renumbered independently to 1..k, in order of first appearance across the result's frames.
- `PixelData`: rebuilt from the selected frames, in result order. Native data is concatenated; `BitsAllocated` of 1 is re-packed across frame boundaries. Encapsulated data is re-encapsulated with a new basic offset table, and `ExtendedOffsetTable`/`ExtendedOffsetTableLengths` are dropped.
- Identity: a new `SOPInstanceUID`; `file_meta.MediaStorageSOPInstanceUID` matches it; `SOPClassUID` and the transfer syntax are unchanged.
- Provenance: `SourceImageSequence` holds one item per source instance with `ReferencedSOPClassUID`, `ReferencedSOPInstanceUID` and `ReferencedFrameNumber` set to the 1-based source frame numbers used, in result order.
- Isolation: inputs are not modified and share no mutable object with the result.
- `varying_attributes` returns tags, not keywords; empty for a single-frame selection.

## 5. Blind-spot pre-empts

- Result list ordering: "in the order given" / "in input order".
- Iteration termination is not applicable; instead the global rule is stated once: "present with an equal value in every frame".
- Reference vs deep copy: "the input is left unchanged and shares no object with the result".
- Adjacent vs all-positions: "each dimension is renumbered independently".
- Unstated inverse: demotion is stated as the mirror of promotion in one clause.
- Codebase-inferable requirements: exactly 1 (that bit-packed frames must be re-packed; `pydicom.pixels.utils` already carries `get_packed_frame` and `concatenate_packed_frames` for it).

## 6. Description draft

See meta.md. Three paragraphs, <=200 words, plain prose, no headers.

## 7. File footprint

| Action | Path | Raw delta | Meaningful | Reason |
| --- | --- | --- | --- | --- |
| NEW | src/pydicom/multiframe/__init__.py | 45 | 30 | public surface, errors |
| NEW | src/pydicom/multiframe/_groups.py | 175 | 140 | macro model, merge, promotion, demotion, varying |
| NEW | src/pydicom/multiframe/_dimension.py | 80 | 65 | dimension index renumbering |
| NEW | src/pydicom/multiframe/_pixels.py | 175 | 140 | native + encapsulated frame bytes, reassembly |
| NEW | src/pydicom/multiframe/_instance.py | 230 | 190 | extract/merge drivers, identity, provenance, validation |
| MODIFY | src/pydicom/__init__.py | 3 | 3 | export |

TOTAL: ~708 raw / ~568 meaningful across 1 modified + 5 new files. Clears the 450 design floor with margin.

## 8. Solution outline — pure-function helpers

- `_macro_items(group_item) -> dict[BaseTag, DataElement]` — the macros of one functional-group item.
- `_macros_equal(a, b) -> bool` — DICOM value equality of two macro elements.
- `_effective_macros(ds, index) -> dict` — shared macros overridden by frame macros.
- `_common_macros(items) -> dict` — macros present and equal in every item (the promotion kernel).
- `_promote(shared_item, frame_items) -> None` — move common macros to shared, drop them from frames.
- `_demote(shared_item, frame_items, keep) -> None` — push non-common shared macros into every frame item.
- `_renumber_dimensions(frame_items) -> None` — per-dimension 1..k in order of first appearance.
- `_frame_length_pixels(ds) -> int`, `_native_frame(ds, index) -> bytes`, `_encapsulated_frame(ds, index) -> bytes`.
- `_rebuild_pixel_data(ds, frames) -> None`.
- `_new_identity(ds) -> None`, `_record_source(ds, sources) -> None`.
- `_check_compatible(datasets) -> None`.

`_common_macros` is the single interdependent kernel: `extract_frames` promotion, `merge_frames` demotion and `varying_attributes` all run through it, so a local fix to one surface regresses another.

## 9. Test file outline

Path: `tests/test_multiframe_<hash>.py`, single new file, 4 blocks.

Block 1 — imports (`pydicom`, `Dataset`, `Sequence`, tags). The `pydicom.multiframe` names are imported **inside each test body** so collection succeeds on base and every test fails individually (per-test F2P).
Block 2 — builders: `enhanced(n_frames, ...)`, `macro(tag, **kw)`, `frame_item(...)`, `encapsulated(...)`, `bitpacked(...)`.
Block 3 — assertion helpers: `assert_macro_in_shared`, `assert_frame_macro`, `assert_error`.
Block 4 — buckets:
- frame_attributes: shared only, per-frame only, per-frame overrides shared, nested sequence copied, bad index, single frame.
- extract order/selection: single, reordered, all, duplicate error, out of range error, empty error, non-multiframe error.
- promotion: constant macro promoted, varying macro stays per-frame, macro absent from one frame stays per-frame, already-shared stays shared, promotion after reorder.
- demotion/merge: differing shared macro demoted into every frame, equal shared macro stays shared, incompatible inputs error, provenance items per input.
- dimension index: renumber per dimension, order of first appearance, single dimension collapse, absent FrameContentSequence.
- pixel data: native multi-byte, native bit-packed crossing byte boundaries, encapsulated re-encapsulation, offset table dropped.
- identity/provenance: new SOPInstanceUID, file_meta sync, SOPClassUID unchanged, ReferencedFrameNumber values.
- isolation: source unchanged, no shared sequence/item objects.
- varying_attributes: varying tags found, constant tags absent, single frame empty.
- round trip: merge of two extracts reproduces the original frame attributes.

Target 60-90 tests.

## 10. Forced kwargs / typing

`indices` accepts any `Sequence[int]`; `merge_frames` accepts any `Sequence[Dataset]`. Return types are plain `Dataset`, so no typing trap. `MultiFrameError` subclasses `ValueError` so the exact class is not a guessing game and the meta names it.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt sentence in meta | Test |
| --- | --- | --- | --- | --- |
| 1 | Promotion is global over the whole selection | Natural code just subsets the per-frame sequence | "a macro that has the same value in every frame of the result is stored once, in the shared groups" | promotion bucket |
| 2 | Demotion is the mirror on merge | Agents keep both inputs' shared groups | same sentence, applied to merge | merge bucket |
| 3 | Dimension index renumbering per dimension | Agents copy the values or renumber globally | "each dimension is renumbered on its own" | dimension bucket |
| 4 | Bit-packed frames cross byte boundaries | Uniform byte slicing looks right | one codebase-inferable requirement | pixel bucket |
| 5 | file_meta identity is a second path | Agents set SOPInstanceUID only | "the file meta information agrees with it" | identity bucket |
| 6 | Input must share nothing | pydicom sequences are mutable and copied by reference | "leaves its inputs unchanged and shares nothing with them" | isolation bucket |

## 12. Tier + category

- Tier: Olympus
- Sub-rank: Good/Excellent target
- Category: feature-request (net-new public module)

## 13. Predicted Nova pass rate

10-25%. Levers stacked: one interdependent kernel (`_common_macros`) driving three surfaces; exact-output correctness; three interdependent+misdirecting traps; an "obvious code is wrong" edge (bit-packed slicing, and per-frame subsetting without promotion); a low-training domain (DICOM enhanced multi-frame functional groups); 6 files / ~568 meaningful LOC.

## 14. Quality gate

- [x] Repo understanding: dataset/sequence model, pixels + encaps machinery, data dictionary, test layout (`tests/`), template `tests/test_fileset.py`
- [x] Existing PR check: `gh pr list -R pydicom/pydicom --state all --search "functional group|multiframe|multi-frame|extract frames|frame subset|enhanced"` — no PR implements functional groups or frame subsetting; #1725 (closed) adds a lazy pixel `framereader.py`, disjoint core
- [x] Corpus recipe: single kernel, exact output, >=3 interdependent traps, signatures pinned, not a portable spec (the promotion/demotion policy is defined by this task)
- [x] LOC sketched against real files, above floor
- [x] <=1 codebase-inferable requirement
- [x] Not pattern-followable: no existing functional-group code anywhere in the repo

## Why this is not a duplicate

Closest approved: `mp4ff-progressive-writer` (rebuild a media container from fragments, inputs untouched) and `ezdxf-attribute-sync` (propagation contract). This differs in repo, domain and kernel: the load-bearing logic here is a *set-equality over macros across a frame selection* that both promotes and demotes, plus per-dimension index renumbering — neither sibling has an equality-over-a-selection kernel. `rejected/dicom-rs-palette-color` is a different repo, language and subsystem (palette colour lookup).

Predicted iteration cycles: 2
