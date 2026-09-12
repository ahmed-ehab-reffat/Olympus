---
Repository: https://github.com/iwe-org/iwe
Language: Rust
Issue: none (original feature request)
Commit: 7d861a62c6d4a10237ba2a153005dd9122362b4e
Title: Resolve heading anchors in markdown link targets
---

# Resolve heading anchors in markdown link targets

A link url fragment is dropped today: `[label](note#section)` only reaches the document. Make a fragment address a header there and keep those addresses correct across refactors. A url that is only a fragment names no document.

Every header answers to an anchor slug built from its plain text: lowercased, every run of characters that is neither a letter nor a digit replaced by one dash, leading and trailing dashes removed. A header with no letter and no digit answers to `section`. The second header with a slug already taken gets `-2`, the third `-3`, counted over the whole document in order, the title included. A list item is not a header. Percent escapes in a fragment are decoded once, when the link is read, an empty fragment carries no anchor, and a lookup matches the slug exactly as given. A fragment no header answers to is dangling. An anchored link is still an edge to its document.

A link alone on a line that carries a fragment includes only the addressed header and everything under it, nested under the link's position; a dangling one stays a link, and a fragment inside a paragraph is never expanded. Wiki links carry fragments the same way. Where reference text is normalized, an anchored link takes the header's text, a dangling one the document title.

Extracting a section retargets links: one addressing the extracted header becomes a link to the new document with no fragment, one addressing a header carried away points at the new document under the slug it answers to there. Headers left behind renumber and the links addressing them follow. Inlining moves headers into the host, so links addressing them point at the host under their new slugs, unless the inlined document is kept. Renaming a document keeps the fragment.

Add `operations::rename_header(graph, key, header_id, text)` returning `Result<Changes, OperationError>`. It replaces a header's text, keeps every inbound anchored link pointing at it, and renumbers the neighbours it collides with. Blank text, a node that is not a header of that document, and an unknown document are errors.

Add on `Graph`: `anchors(key) -> Vec<AnchoredHeader>` in document order, with `AnchoredHeader { id: NodeId, slug: String, text: String }`; `resolve_anchor(key, anchor) -> Option<NodeId>`; `anchor_text(key, anchor) -> Option<String>`; `anchor_of(id: NodeId) -> Option<String>`; `anchored_markdown(key, anchor) -> Option<String>` (that section alone, its header at top level); `anchor_backlinks(key, anchor) -> Vec<Key>` (documents linking to it, sorted, each once); `anchored_refs_in(key) -> Vec<(Key, String)>` (every anchored link, in document order); and `dangling_anchors() -> Vec<DanglingAnchor>` with `DanglingAnchor { source_key: Key, target_key: Key, anchor: String }` for every anchored link whose target exists but answers to no such header, deduplicated and sorted by source, target, then anchor. Block level and inline links both count. Every lookup above yields nothing when no header answers. `iwe stats` reports them under Broken Anchors.
