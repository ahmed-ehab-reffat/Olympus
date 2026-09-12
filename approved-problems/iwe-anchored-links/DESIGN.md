# DESIGN.md — iwe-anchored-links

## 1. Title

Resolve heading anchors in markdown link targets

## 2. Shape classification

- Shape: **O-Composite-add** (a new addressing dimension threaded through parser -> model -> graph -> projection -> writer -> refactor operations).
- Pass rate target: <= 40% cap, designed for the corpus mode of ~1/10.
- Best agent: Vega / Orion.
- Dominant verdict: MISSED_REQUIREMENT (anchor maintenance during refactors), INTEGRATION_ERROR (partial inclusion wiring).

## 3. Public API surface

Everything below is reachable from existing entry points; new names are marked NEW.

- `Reference.anchor: Option<String>` (NEW field on the existing struct) - the fragment of a link target, without `#`.
- `Key::from_rel_link_url(url, relative_to)` - unchanged, still yields the document key.
- `Key::anchor_from_link_url(url) -> Option<String>` (NEW) - the fragment part of a link url.
- `Graph::anchor_slug(key, node_id) -> Option<String>` (NEW) - the slug assigned to a section node.
- `Graph::resolve_anchor(key, anchor) -> Option<NodeId>` (NEW) - the section node an anchor addresses.
- `Graph::anchor_slugs(key) -> Vec<(NodeId, String)>` (NEW) - document order.
- `Graph::dangling_anchors() -> Vec<(Key, String)>` (NEW) - inbound anchors that resolve to nothing, sorted.
- `GraphContext::collect_anchored(key, anchor) -> Option<Tree>` (NEW) - the anchored section subtree.
- `operations::extract` / `operations::rename` / `operations::inline` - unchanged signatures, extended behavior.
- CLI: `iwe retrieve <key>#<anchor>` and `iwe export`/`iwe tree` accept anchored targets.

## 4. Canonical output form

- Slug: heading plain text, lowercased, every run of characters that is not a letter or a digit replaced by one `-`, leading and trailing `-` removed. Empty result becomes `section`.
- Duplicate slugs inside one document: first occurrence keeps the bare slug, later ones get `-2`, `-3`, ... in document order.
- The document title (the first header) participates in slug numbering.
- Resolution is exact string match against the computed slug, case sensitive after slugging (slugs are already lowercase).
- A fragment matching no slug is dangling: the document-level edge is unchanged, section behavior is a no-op.
- Anchors round-trip through normalization unchanged (`note#slug` in, `note#slug` out).
- `dangling_anchors` is sorted by key then anchor, deduplicated.

## 5. Blind-spot pre-empts

- Result ordering: "reported in document order" for slugs, "sorted by document key then anchor" for dangling anchors.
- Adjacent-vs-all: slug numbering counts every earlier heading in the document, not only siblings.
- Unstated inverse: an anchored link that is not alone on a line stays a plain reference (no inclusion).
- Preservation: document-level graph edges are unchanged by anchors, so every existing query keeps its result.

## 6. Description draft

See `meta.md` (<= 500 words, prose).

## 7. File footprint

| Action | Path | Raw delta | Reason |
| --- | --- | --- | --- |
| MODIFY | crates/liwe/src/model.rs | +35 | fragment split helper, slug function |
| MODIFY | crates/liwe/src/model/reference.rs | +10 | anchor field |
| MODIFY | crates/liwe/src/model/inline.rs | +30 | carry the fragment through inline links |
| MODIFY | crates/liwe/src/markdown/reader.rs | +20 | parse fragment into references |
| MODIFY | crates/liwe/src/graph/builder.rs | +30 | store anchors on graph references |
| MODIFY | crates/liwe/src/graph/graph_node.rs | +25 | anchor accessor on reference nodes |
| MODIFY | crates/liwe/src/graph/index.rs | +40 | per document slug index + inbound anchors |
| MODIFY | crates/liwe/src/graph.rs | +120 | slug computation, resolution kernel, collect_anchored, dangling report |
| MODIFY | crates/liwe/src/graph/squash_iter.rs | +40 | anchored inclusion expansion |
| MODIFY | crates/liwe/src/model/tree.rs | +40 | anchored squash target |
| MODIFY | crates/liwe/src/model/node_iter.rs | +20 | write the fragment back |
| MODIFY | crates/liwe/src/operations/extract.rs | +90 | retarget inbound anchors |
| MODIFY | crates/liwe/src/operations/inline.rs | +60 | retarget anchors on inline |
| MODIFY | crates/liwe/src/operations/util.rs | +30 | shared retarget helper |
| MODIFY | crates/iwe/src/... | +40 | anchored retrieve/export targets |

TOTAL sketch: ~630 raw across 15 files. Target human-effective >= 450.

## 8. Solution outline

Helpers, one per described behavior:

- `slugify(text) -> String` - requirement: slug rules.
- `assign_slugs(headings) -> Vec<String>` - requirement: duplicate numbering.
- `Graph::resolve_anchor(key, anchor)` - requirement: resolution.
- `NodePointer::to_anchor(key, anchor)` - requirement: partial inclusion (shared kernel used by squash, tree, export, retrieve).
- `retarget_anchor(reference, moved_slugs, new_key)` - requirement: refactor maintenance.
- `Graph::dangling_anchors()` - requirement: dangling reporting.

The resolution kernel is the single chokepoint: squash expansion, tree projection, retrieval and the refactor rewriters all call it, so a wrong slug rule shows up in four unrelated surfaces.

## 9. Test file outline

Path: `crates/liwe/tests/anchored_links_<hash>.rs` (declared from `crates/liwe/tests/main.rs`).

Blocks: imports -> workspace builders (`from_indoc` states) -> assertion helpers (`assert_str_eq` on rendered markdown) -> tests grouped by requirement:

- slug rules (punctuation, unicode, empty heading, digits, case)
- duplicate numbering (including title participation)
- resolution (hit, miss, nested headings, cross-document)
- partial inclusion (level adjustment, subtree, dangling fallback, inline vs block link)
- retrieval and export
- extract maintenance (anchor at target, anchor inside subtree, anchor elsewhere)
- inline maintenance (slug collision after merge)
- round trip / normalization
- preservation (existing edges, queries, whole-document inclusion untouched)

## 10. Forced bounds

None beyond existing traits; `Reference` gains a field, so every construction site must be updated (compile-visible, listed in meta).

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt | Test |
| --- | --- | --- | --- | --- |
| 1 | Slug numbering is document-wide and counts the title | agents number per parent section | stated in meta | duplicate numbering tests |
| 2 | Anchored inclusion must adjust header levels from the anchored section, not the document root | reuse of the whole-document path | stated | partial inclusion tests |
| 3 | Extract keeps anchors that point inside the moved subtree and drops the one pointing at its root | agents drop all or keep all | stated | extract maintenance tests |
| 4 | Inline re-slugs anchors when the destination already has the same heading text | invisible unless collisions are considered | stated | inline collision test |
| 5 | Document-level edges must not change | agents replace the edge with a section edge and break existing queries | stated | preservation tests |

## 12. Tier + category

Tier Olympus. Category: feature-request.

## 13. Predicted pass rate

10-25%. Levers stacked: one interdependent kernel (resolution) driving four surfaces, exact output, three interdependent and misdirecting traps, an obvious-code-is-wrong edge (slug numbering scope), long-horizon span across 6 subsystems.

## 14. Quality gate

- Repo understanding: parser -> model -> graph arena -> projection -> writer, tests in `crates/*/tests`, template `crates/liwe/tests/links_test.rs`.
- Exclusivity: `gh issue/pr list -R iwe-org/iwe --search anchor|fragment|heading|section|transclusion|embed|block` - only fragment normalization fixes (PR #284, #301), no section resolution.
- Env: vanilla `cargo test --workspace` green offline, ~1300 tests, 12s.
- Not a duplicate: no geometry/markdown-graph problem in the corpus; closest siblings are enmime-preserving-edits (different repo and capability) and chroma-lexer-regions (different repo and capability).
- Predicted iteration cycles: 2.
