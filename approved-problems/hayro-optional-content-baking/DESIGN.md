# DESIGN.md — hayro-optional-content-baking

Repo LaurenzV/hayro (canonical, not moved), base `6dcda45859b7e9cc8488fb6cd011795ba0cca86b`
(main HEAD 2026-09-21). Rust, MIT OR Apache-2.0, 771 stars. Promoted fallback of hunt
2026-09-23-I (vrp died at slice as machinery-absorbed).

## Phase 1 — repo understanding

**Architecture.** hayro is a PDF stack in a Rust workspace. `hayro-syntax` parses the file
(xref, objects, streams + filters, the page tree, resources with page-tree inheritance, and a
content-stream tokenizer `UntypedIter`/`TypedIter`). `hayro-interpret` walks content streams with
a graphics-state machine and drives a `Device` (paths, glyphs, images, clips, transparency
groups); it owns optional-content evaluation (`ocg.rs`: default-config inactive set, OCMD
policies, a visibility stack fed by `BDC`/`BMC`/`EMC` and by XObject `/OC`). `hayro` renders a
page to a pixmap through vello_cpu; `hayro-svg` is a second device. `hayro-write` (711 LOC, only
depends on `hayro-syntax` + `pdf-writer`) extracts pages as a new page or as a Form XObject into a
`pdf_writer::Chunk`, copying every referenced object through a generic ref walker
(`write_dependencies` + `WriteDirect`/`WriteIndirect` in `primitive.rs`) that strips a fixed set of
document-global keys (`/OC`, `/StructParent`, `/Metadata`, ...).

**Subsystems.** (1) hayro-syntax object model + filters; (2) content tokenizer; (3) interpreter
state machine + OC visibility; (4) renderers (hayro/vello, hayro-svg); (5) hayro-write extraction
(page/XObject writers, resource flattening, dependency copier). Plus codec crates (jbig2, jpx,
ccitt, cmap, postscript/fonts).

**Entanglement zones.** (a) Resources inheritance (page tree parent chain, forms inheriting page
resources) used by interpreter and writer; (b) content streams consumed by interpreter, svg, and
copied raw by the writer; (c) the dependency copier, which is context-free and object-identity
deduplicated (`ref_map`, `visited_objects`), so any per-use rewrite of a shared object collides
with it.

**Tests.** `hayro-tests` crate, single test target `tests` (`tests/mod.rs` declares modules
`render`, `load`, `svg`, `write`). Render/svg/write tests compare against snapshot PNGs that are
NOT checked in (generated locally / via `sync.py` downloads), so they cannot run in a clean room.
Offline-safe: `load::*` (checked-in `pdfs/load`), the four non-snapshot write tests, and every
crate's unit/doc tests. Template for the new file: `hayro-tests/tests/write.rs`
(`write_xobject_does_not_synthesize_group` style: build, extract, re-read, assert).

## Phase 2 — existing PR / publicly-solved check (and scope-lock gates)

Canonical: `gh api repos/LaurenzV/hayro -q .full_name` = `LaurenzV/hayro`.
PR/issue searches, all states: "optional content", "OCG", "OCProperties", "hayro-write",
"extract", "layer", "visibility", "marked content", "BDC", "content stream rewrite", "hidden".
Hits and diffs read:
- #1279 (0xbe7a, CLOSED) "Preserve `/OC` entries": diff = `primitive.rs +1/-2` (stop stripping
  `/OC`) + a test. Maintainer: hayro-write returns chunks, cannot write `/OCProperties`, which is
  why document-global keys are stripped. Author closed it ("I'll be forking hayro-write"). Not the
  lane: preserving `/OC` is the opposite of baking.
- #1280 copy `Annots`, #1281 override `/Rotate` (both 0xbe7a, closed) — off lane.
- #1013/#1020/#321/#359 (maintainer, merged) — interpreter OC support; the evaluator the lane's
  oracle uses. #967, #1049, #1059, #1333 — marked content to Device / text extraction; off lane.
- #519 "Support forms in hayro-write" (AcroForm), off lane.
Fork-branch exclusivity scan (76 forks, every branch compared to `main`, filter hayro-write|ocg):
0xbe7a `write-preserve-oc` / `write-copy-annots` / `write-page-dict-hook` (the three closed PRs);
glyphst `glyphst/main` + `codex/*` (hayro-write = lazy-read error propagation, +interpret
`ocg/resolve.rs`, no content rewriting); cristim `feat/ocg-visibility-overrides` (interpret only);
five `vb` branches (Cargo.toml bump); SAY-5 (signature account in `sig_accounts.txt`) forked
2026-06-18, fork now deleted, no PRs = note only. Not in `adx-labtesing-deepswe-forks.txt`.
Upstream side branches `hayro-v0.7.1`, `v`, `vello`: no hayro-write/ocg changes.
Cross-repo code search: `open-redact-pdf` (8 stars, Apache) strips hidden `BDC /OC ... EMC` runs
wholesale from top-level page streams (drops the state operators too, no forms, no XObject `/OC`)
— the naive half of the idea, public; iText 5 `OCGRemover` (AGPL, Java) same family. pdf_oxide /
xberg declare an `OcgPolicy::StripHidden` option with no implementation. Risk: MEDIUM crib of the
naive core; the render-preserving baking (state, text advance, clip, XObject `/OC`, forms) is not
public anywhere found. SIX-CHECK 4 (closed-as-implemented): none. SIX-CHECK 5: base = HEAD.
SIX-CHECK 6: reproduced (below).

Gates: 1/6 reproduced on base (extracted page draws the OFF layer; render differs from the
source). 5 cold: hayro-write last touched 2026-07-12 (#1282), nobody builds the capability. 7b
clean (above). 8 defined: PDF 32000 §8.11 + hayro's own interpreter define default-config
visibility; the maintainer's #1279 constraint (no document-global state in extracted chunks) is
satisfied by baking. Stars 771, licence MIT/Apache (NOTICE: pdf.js/PDFBox adaptations Apache,
vendored cmaps CC0/BSD, test fonts OFL — all permissive), Rust 95.8%, quota 0/6, not in
SATURATED-REPOS, no dedup hit in problems/ rejected/ approved-problems/.

## Phase 3 — candidates (all in the one lane the hunt handed over)

| Candidate | One-line behaviour | Verdict |
|---|---|---|
| A. Preserve `/OC` + write `/OCProperties` | keep OC live in the output | Dead: maintainer declined (#1279), chunk API cannot own catalog state |
| B. Strip hidden `BDC..EMC` runs | delete hidden sections wholesale | Dead: naive, public (open-redact-pdf), wrong (drops state), single-subsystem transform |
| C. **Bake default visibility, render-preserving** | extracted page/XObject draws exactly what the source shows by default; hidden content paints nothing but its state effects survive; XObject-level `/OC`; recursion into content the page draws | **PICK** |
| D. C + prune hidden-only resources | resources only hidden content uses are not written | FINISH lever (couples rewriter with the resource flattener) |
| E. C + per-use specialization of shared forms | a form whose baked content depends on inherited state (render mode, inherited `/Properties`) gets one baked copy per distinct use | FINISH lever (collides with the copier's object-identity dedup) |

Step A (TOO-EASY guard): #1 not a uniform wrap (four different hidden-op treatments + a
visibility stack + XObject membership + recursion); #2 single crate but the walls are
graphics-state semantics, the text-advance/render-mode interaction and the dependency copier's
dedup (hidden-integration walls, not a spec transcription) — BORDERLINE, recorded; #3 contract is
one universal sentence ("draws exactly what the source shows"), traps survive stating it; #4 not
a memorized port (iText/qpdf do not do render-preserving baking); #5 yes. Absorption: the only
reusable machinery is the config half of `hayro-interpret/src/ocg.rs` (~70 lines, `pub(crate)`,
another crate, stack API tied to the interpreter); the rewriter, the hidden-op policy, the
XObject check, recursion and dedup handling do not exist anywhere in the repo.

Step B: lead S2 (composition of documented rules: "paints nothing" x "graphics state still
applies" x text advance), S4 machinery-riding (the copier and resource inheritance), A7
determination channels (visibility decided by marked content AND by XObject `/OC`).
CONTRACT-STATED/FIX-HIDDEN: the contract is "the extracted page draws exactly what the source
page shows under its default configuration, in a viewer that ignores optional content"; the
fixes (keep state ops, `n` for paints, invisible render mode with restore, depth-correct EMC
pairing) are discoveries, not sentences.

## Phase 4

### 1. Title
Bake default optional-content visibility into hayro-write extraction

### 2. Shape
O-Composite-extend (an existing extraction pipeline must now evaluate document state it
previously dropped and rewrite content it copied raw). Target <=40%, design for ~15-25%.
Best agent: Orion/Vega (long-horizon). Dominant verdict predicted MISSED_REQUIREMENT.

### 3. Public API surface
No new public API. `hayro_write::extract` (and the `#[doc(hidden)]`
`extract_pages_to_pdf` / `extract_pages_as_xobject_to_pdf` test helpers) change behaviour.
Tests assert through those three names only (L72: no new call shapes to guess).

### 4. Canonical output form
Asserted as rendering equality (hayro render of the extracted PDF vs hayro render of the source
page, same settings, exact pixels) plus structural facts: a page with nothing hidden keeps its
decoded content stream byte-identical; hidden XObjects are not drawn.

### 5. Blind-spot pre-empts
"graphics state still applies" (state ops inside hidden sections); "text still advances"; the
general rule only, no enumeration (Rule 7). Default configuration = `/D`: `BaseState`, `ON`,
`OFF`, membership dictionaries with `P` policies (hayro's interpreter semantics; `VE` not used).

### 6. Description draft (slice)
See meta.md (draft). ~180 words.

### 7. File footprint (slice measured after build; FINISH sketch)
| Action | Path | Slice | FINISH add |
|---|---|---|---|
| NEW | hayro-write/src/optional_content.rs | config + rewriter | form/pattern/Type3 recursion, per-use specialization, hidden-only resource pruning |
| MODIFY | hayro-write/src/lib.rs | context field + bake page stream in both writers | copier hook for content-bearing streams, variant refs |
| MODIFY | hayro-syntax/src/content/mod.rs | `UntypedIter::offset()` | — |
| MODIFY | hayro-write/src/primitive.rs | — | rewritten stream data + filter/`DecodeParms` handling |

### 8. Solution outline
`OcConfig::new(pdf)` (inactive set from `/OCProperties /D`), `OcConfig::hides(ref, dict)`
(OCG membership or OCMD policy), `bake(data, resources, config) -> Option<Vec<u8>>` (None when
nothing is hidden, so visible content stays byte-identical), visibility stack over
`BDC`/`BMC`/`EMC`, render-mode stack over `q`/`Q`/`Tr`, per-op policy in hidden sections:
path paints -> `n`, text shows -> `3 Tr` + op + restore, `Do`/`sh`/inline image -> dropped,
everything else kept; visible `Do` of an XObject whose own `/OC` is hidden -> dropped.

### 9. Test file outline
`hayro-tests/tests/write_oc_0eadd0.rs`: raw-PDF builder (objects -> xref), render helper,
`assert_extracts_as_shown` (page mode + XObject mode vs source render). Buckets: default
config forms, hidden paint/state, text advance, nesting, XObject `/OC`, untouched content.

### 10. Forced bounds
None (no new signatures).

### 11. Trap matrix
| # | Trap | F-id | Class | Axis | Interdep. | Catching test |
|---|---|---|---|---|---|---|
| 1 | Hidden section deleted wholesale drops `cm`/colour/`gs`/`W n` that later visible content relies on | F-1 (convergent "strip the run" architecture) / F-7 | S2 | graphics state | #2, #3 share the per-op policy | hidden_state_still_applies_* |
| 2 | Hidden text removed or restored to render mode 0 | new (F-1 family) | S2 x A4 | text state | #1 (Tr inside hidden kept), #5 (forms inherit Tr) | hidden_text_keeps_advance, restores_stroke_mode, render_mode_after_q |
| 3 | Paint dropped without ending the path: hidden subpath leaks into the next visible fill | new | A9-ish | path state | #1 | hidden_fill_does_not_leak_its_path |
| 4 | EMC pairing counts only OC sections | F-7 nesting | A7 | marked-content stack | #1 | nested_plain_marked_content_inside_hidden |
| 5 | Visibility decided by XObject `/OC` (not marked content) | F-9-ish (second determination channel) | A7 | channel | #6 | xobject_with_hidden_oc_is_not_drawn, ocmd policies |
| 6 | (FINISH) hidden content inside forms the page draws; forms inheriting render mode / Properties; per-use copies vs `ref_map` dedup | F-10 / S4 | S4 | recursion x dedup | #2, #5 | form_* cells |
| 7 | (FINISH) untouched-content guard: re-serializing every op changes a stream with nothing hidden | P2 over-eagerness | S3 | preservation | #1 | page_without_hidden_content_is_copied_verbatim |

### 11b. Cross-product (FINISH)
{page stream, form stream} x {marked-content hidden, XObject-`/OC` hidden} x
{render mode inherited 0, inherited non-zero}; {hidden text} x {q/Q around a Tr change};
{shared form} x {drawn visible, drawn inside hidden}.

### 12. Tier/category
Olympus; feature-request ("Bake ...": new capability of extraction).

### 13. Predicted pass
15-30% after FINISH (traps 1-3 are derivable from the universal sentence by careful agents;
6 and the untouched guard carry the band). Slice alone would read high.

### 14. Checklist
Phase 1 5/5; PR check clean (above); no new API; ASCII meta; comments none (hayro-write carries
sparse `//` comments in bodies and `///` on pub items only — new code adds none); F-12: no inline
test modules in hayro-write; base mode scoped (snapshot suites excluded, reason kept out of
test.sh).

## Phase 5 — self-audit
Hidden requirement risk: the text rule (render mode restore) must be implied by "draws exactly
what the source shows" — it is, since the source render draws later visible text in its own
mode. hayro-specific quirks avoided in fixtures: `W f` (hayro never applies a clip set with a
painting operator other than `n`), `VE` expressions (hayro ignores them), Type3 glyphs under
`Tr 3`. Oracle is hayro's own interpreter (OC-aware), so "shows" is concrete and in-repo.

Predicted iteration cycles: 2-3.
