# DESIGN.md — taplo-dom-structural-edit

## 1. Title

Add Structural Insert and Remove Operations to the DOM Rewrite API

Verb: Add. Names the specific subsystem (`taplo::dom::rewrite`, the DOM Rewrite API).

## 2. Shape classification

- Shape: **O-Composite-add-adjacent** (closest taxonomy match: Olympus Shape B / O-Composite-add hybrid — a small, explicitly-named public API cluster bolted onto an existing subsystem, but with real algorithmic derivation rather than a mechanical transform). Per `SHAPES.md` this is nearest to Mars Shape B ("new public API list", Pattern 11) crossed with O-Composite-add's "multi-form capability, one shared chokepoint" shape (Pattern 12), scaled to the current one-tier sprint floor rather than the historical 450-LOC Olympus band.
- Definition (cite SHAPES.md § Pattern 11 / 12): new, explicitly-named public methods (`insert_entry`, `remove_entry`, `insert_array_value`, `remove_array_value`) added to an existing struct (`Rewrite`), where the METHOD SIGNATURES are easy (stated explicitly in meta.md) but the METHOD BODIES require deriving structural facts (byte-offset anchors, comma ownership) that no existing DOM accessor exposes directly — closer to O-Composite-add's "the fix is a discovery orthogonal to the stated requirement" than to Shape B's usual "wire together existing pieces."
- Pass rate target: 15-25% (aim near 20%, well under the current ≤40% ceiling, with the solvability floor easily cleared — the RenameKeys precedent already proves the surrounding machinery is usable).
- Best agent: Mixed / Nova→Orion. The API surface is enumerable (Nova-friendly), but the anchor-derivation logic rewards decisive single-architecture commitment (Orion-friendly) more than exploration.
- Dominant verdict: MISSED_REQUIREMENT (wrong insertion position / wrong comma retained), with some INTEGRATION_ERROR (Pseudo-table case not gated on one of the two new operations).
- Solver/our LOC ratio: unmeasured (no batch yet) — estimate ~1.1-1.5x based on comparable Shape B / O-Composite-add precedents that require re-deriving positional logic (agents often duplicate the anchor logic per node kind instead of sharing one helper).

## 3. Public API surface

- `Rewrite::insert_entry(&mut self, table: &str, key: &str, value: &str) -> Result<&mut Self, Error>` — insert a new `key = value` entry into the table addressed by the dotted path `table` (`""` addresses the top-level table). `value` is inserted verbatim as already-formatted TOML.
- `Rewrite::remove_entry(&mut self, key: &str) -> Result<&mut Self, Error>` — remove the existing entry addressed by the dotted path `key`.
- `Rewrite::insert_array_value(&mut self, array: &str, value: &str) -> Result<&mut Self, Error>` — append `value`, verbatim, as a new last element of the inline array addressed by `array`.
- `Rewrite::remove_array_value(&mut self, array: &str, index: usize) -> Result<&mut Self, Error>` — remove the element at position `index` of the inline array addressed by `array`.
- `Patch::InsertEntry { table: Arc<str>, key: Arc<str>, value: Arc<str> }` — the underlying `Patch` enum variant these methods build (mirrors the existing `Patch::RenameKeys` shape).
- `Patch::RemoveEntry { key: Arc<str> }`, `Patch::InsertArrayValue { array: Arc<str>, value: Arc<str> }`, `Patch::RemoveArrayValue { array: Arc<str>, index: usize }`.
- `dom::error::Error::DuplicateKey { key: Arc<str> }` — raised when `insert_entry`/`insert_array_value`-equivalent targets a table that already has that key.
- `dom::error::Error::IndexOutOfBounds { index: usize, len: usize }` — raised by `remove_array_value` when `index >= len`.
- `dom::error::Error::PseudoTableUnsupported` — raised by both `insert_entry` and `remove_entry` when the resolved table is a dotted-key (`TableKind::Pseudo`) grouping rather than a real header or inline table.
- `dom::error::Error::ExpectedInlineCollection` — raised by `insert_array_value`/`remove_array_value` when the resolved node is not `ArrayKind::Inline`, and internally when a table target for entry insertion/removal is not `TableKind::Regular` or `TableKind::Inline`.

No "same as X" — every name above is what the tests assert.

## 4. Canonical output form

- **Table entry insertion position:** a new entry is inserted immediately after the table's own last directly-declared entry (in file order), or immediately after the table's header line if it has none yet, or at the very start of the document for the implicit top-level table when nothing precedes it there. New entries always land before any of the table's own nested table or array-of-tables declarations, matching the ordering convention `to_toml.rs` already uses when it serializes a whole tree (non-table entries first, tables last).
- **Table entry insertion separator:** the inserted text is `"\n" + "key = value"` except when the insertion point is byte offset 0 (nothing precedes it at all), in which case it is `"key = value" + "\n"` instead — this keeps the file from gaining a leading blank line.
- **Table entry removal:** removes the entry's own text (including a trailing same-line comment, which is already part of the entry's syntax range) plus exactly one immediately-following newline, if present. It does not otherwise touch neighboring blank lines or comments.
- **Inline collection insertion (inline table / inline array):** the new entry or value is appended as the last element, separated from the current last element by `", "` (a literal comma and single space), regardless of the collection's existing internal spacing.
- **Inline collection removal:** removes the entry's or value's own text plus the comma that used to separate it from its neighbor — the following comma normally, or the preceding comma when the removed element was the collection's last element (TOML forbids a trailing comma before `}`/`]`, so the following-comma rule cannot apply there). Removing an inline collection's sole remaining element removes no comma (there is none) and leaves the collection's own surrounding whitespace as-is.
- **Duplicate keys:** `insert_entry` errors with `DuplicateKey` if the target table already has an entry with that key; it never overwrites.
- **Dotted-key groups:** a table reached only through a dotted key (`a.b = 1` makes `a` a `TableKind::Pseudo` grouping, not a real table) does not support `insert_entry` or `remove_entry`; both return `PseudoTableUnsupported`.
- **Not-found paths:** an unresolvable `table`/`key`/`array` path returns the existing `QueryError::NotFound` (via the existing `#[from] dom::error::Error` bridge on `rewrite::Error`), unchanged from today's `rename_keys` behavior.

## 5. Blind-spot pre-empts

- Root vs. header table parity (new, mirrors extended-skip's sort-order pre-empt style): "New entries always land before any of the table's own nested table or array-of-tables declarations" — states the general rule once; covers the top-level (headerless) table the same way it covers a bracket-headed one without enumerating the two cases as separate instances.
- Iteration/position ambiguity on removal (mirrors the lightningcss "adjacent positions" pre-empt): "the following comma normally, or the preceding comma when the removed element was the collection's last element" — states the rule as a single sentence with its necessary exception inline (Rule-7 compliant: the exception is part of the same sentence as the rule, per calyx's lesson that a rule's exceptions belong in the sentence that states the rule).
- Falsy/no-op-on-invalid pre-empt is not applicable here (all four operations are fallible and return `Result`, never a silent no-op).
- 0-1 codebase-inferable requirement used: that `value`/`key` strings are inserted verbatim without re-escaping (directly inferable from `Patch::RenameKeys`'s existing `to.clone()` verbatim-replace behavior in `rewrite.rs`, which the meta does not need to restate).

## 6. Description draft (meta.md, plain prose)

Word budget target: ~180 words (Olympus recommended cap 200, hard cap 500).

Draft:

> Add structural insert and remove operations to the DOM `Rewrite` API. Today `Rewrite` only supports renaming an existing key in place; there is no way to add a new entry to a table or array, or delete one, while keeping the rest of the document's formatting and comments untouched.
>
> Add `insert_entry(table, key, value)` and `remove_entry(key)` for table entries, and `insert_array_value(array, value)` and `remove_array_value(array, index)` for inline array elements, all keyed by the same dotted-path syntax `rename_keys` already accepts. `key` and `value` are inserted verbatim as already-formatted TOML.
>
> A new entry is inserted after a table's own last directly-declared entry, or right after its header if it has none, or at the document's start for the top-level table — always before any of that table's own nested table or array-of-tables declarations. Inline table and array insertions append as the last element, separated by `", "`. Removing a table entry deletes its own line, including a trailing same-line comment. Removing an inline entry or array value also removes the comma that used to separate it from its neighbor: the following comma normally, or the preceding one when it was the last element. Inserting a duplicate key errors instead of overwriting. Dotted-key (pseudo) tables support neither operation.

(~178 words body, excludes frontmatter.)

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful (approx) | Reason |
|--------|------|-------------|-----------|----------------------|--------|
| MODIFY | `crates/taplo/src/dom/rewrite.rs` | 200 | +300 | ~250 | New `Patch`/error-handling variants, 4 public methods, table-anchor derivation (root + header cases), shared inline-collection insert/remove helper (reused by both `Table::Inline` and `Array::Inline`), doc comments matching existing `///` density |
| MODIFY | `crates/taplo/src/dom/error.rs` | ~28 | +18 | ~15 | 4 new `Error` variants (`DuplicateKey`, `IndexOutOfBounds`, `PseudoTableUnsupported`, `ExpectedInlineCollection`) with `thiserror` messages |

TOTAL: ~318 raw / ~265 meaningful across 2 modified files.

Current floor check (2026-07 sprint, ONE TIER): needs ≥200 effective LOC, ≥2 files, ≥40 agent messages (solver median). This sketch (~265 meaningful) clears the 200 floor with a ~65-line buffer, matching the "design to 300+ raw when the floor is 200 meaningful" guidance loosely — if actual implementation runs leaner (helper reuse is aggressive), the design will over-shoot LOC by adding the array-of-tables root/insertion symmetry test coverage rather than padding source, or by not being over-conservative in the sketch (400 words × real logic per §8 below runs closer to 300-340 raw in practice for this class of anchor-derivation code, per the `pest-error-recovery`/`gimli-type-units` "sketch 2-3 hardest files in real code" calibration warning). If the human-effective count lands under 250 after Counter-2 stripping, the natural expansion lever is the shared inline-collection helper growing a documented `Display`/round-trip self-check rather than new unrelated surface (per HARDENING's "never pad LOC with public API" rule).

LOC discipline note: this sketch is against REAL code read in Phase 1 (rewrite.rs's existing `add`/`check_overlap`/`Display::fmt` structure, node.rs's `DomNode::syntax()`, nodes.rs's `TableKind`/`ArrayKind`), not a file-walk maximum — calibrated down from an initial over-estimate that assumed `to_toml.rs` would need changes (it does not; `Rewrite` never calls it).

## 8. Solution outline — pure-function helpers

- `fn resolve_table_anchor(table: &Table, table_syntax_kind_is_root: bool) -> Result<usize, Error>` ← derives the byte offset a new entry is inserted at for `TableKind::Regular` (root or header'd) tables, by walking `table.syntax()`'s siblings (or, for the root table, its first children) to find the end of its own last directly-declared entry, skipping past any of the table's own nested table/array-of-tables declarations. ← description requirement "a table's own last directly-declared entry ... before any nested declarations."
- `fn splice_into_bracketed(open_end: TextRange, close_start: TextRange, has_existing_items: bool) -> (usize offset, String prefix)` ← shared by inline-table and inline-array insertion: computes the offset just before the closing bracket/brace and the `", "`-or-nothing prefix to use. ← description requirement "Inline table and array insertions append as the last element, separated by `", "`."
- `fn table_entry_removal_range(entry_syntax: &SyntaxElement) -> TextRange` ← extends an `ENTRY` node's own range forward by exactly one immediately-following `NEWLINE` token, if present. ← description requirement "Removing a table entry deletes its own line."
- `fn inline_member_removal_range(member_syntax: &SyntaxElement, is_last: bool) -> TextRange` ← extends a member's own range to include the following comma (and one trailing space) normally, or the preceding comma (and one leading space) when `is_last`. Shared by inline-table entry removal and inline-array value removal (same bracketed-list shape). ← description requirement "removes the comma that used to separate it from its neighbor ... the preceding one when it was the last element."
- `fn require_regular_or_inline(table: &Table) -> Result<(), Error>` ← rejects `TableKind::Pseudo` with `PseudoTableUnsupported`; called from both `insert_entry` and `remove_entry`. ← description requirement "Dotted-key (pseudo) tables support neither operation," and the interdependence trap in §11.

No fixpoint loop is needed (single-pass structural edits, not an iterate-to-stability transform). No AST cycle-trace pattern is needed (no recursive traversal through potentially-cyclic references; `Keys`/`Node::path` already terminate on the DOM's tree shape).

## 9. Test file outline

Path: `crates/taplo/src/tests/rewrite_structural_<hex>.rs` (declared via `mod rewrite_structural_<hex>;` added to `crates/taplo/src/tests/mod.rs`, matching the existing `mod formatter;` convention — internal `#[cfg(test)]` module, not a `tests/` integration crate).

Block 1 — Imports: `taplo::dom::rewrite::{Rewrite, Error}`, `taplo::parser::parse`.

Block 2 — Builder helpers (one-liners): `parse_dom(src: &str) -> Node`, `rewrite_of(src: &str) -> Rewrite`.

Block 3 — Assertion helpers: `assert_rewrite(src: &str, apply: impl FnOnce(&mut Rewrite) -> Result<...>, expected: &str)`, `expect_rewrite_error(src: &str, apply: ..., expected_substring: &str)` (substring-match, matching repo error-test convention).

Block 4 — Tests grouped by requirement bucket:
- Bucket "insert into header table": empty table, table with existing entries, table with existing entries AND a later nested `[table.sub]` header (the F-1 anchor-derivation case), table immediately followed by a different table's header with zero entries of its own.
- Bucket "insert into root table": empty document, document with existing top-level entries only, document whose first line is already a header (root insertion at offset 0 must not apply the header case's `\n`-prefix rule — the §4 zero-offset exception).
- Bucket "insert into inline table/array": empty inline table, non-empty inline table, empty inline array, non-empty inline array.
- Bucket "duplicate key": `insert_entry` on an existing key errors with `DuplicateKey`.
- Bucket "pseudo table": both `insert_entry` and `remove_entry` on a dotted-key group error with `PseudoTableUnsupported` (the §11b interdependence cell).
- Bucket "not found / wrong kind": missing table/array path; `insert_array_value` targeting a non-array; `insert_entry` targeting a non-table.
- Bucket "remove from header/root table": first entry, middle entry, last (only) entry, entry with a trailing same-line comment (comment must be removed with it), entry immediately followed by a different table's header.
- Bucket "remove from inline table/array — position axis": first element, middle element, last element (comma-direction discriminator per §4/§11), sole remaining element (no comma to strip).
- Bucket "index out of bounds": `remove_array_value` past the end errors with `IndexOutOfBounds`.
- Bucket "chained patches": one `Rewrite` combining `insert_entry` + `remove_entry` + `rename_keys` in a single chain, verifying `check_overlap` neither spuriously rejects non-overlapping combinations nor accepts a genuinely overlapping insert+remove pair on the same key.

5-axis coverage check (ALL ✓):
- ✓ Every atom of meta.md (insertion position rule split into its 3 named cases; the `", "` inline separator; the comment-inclusive line removal; the position-dependent comma removal rule INCLUDING its stated exception; duplicate-key rejection; pseudo-table rejection stated for BOTH operations)
- ✓ Every public API surface (all 4 methods, both directions of each)
- ✓ Every solution branch (root vs. header anchor; empty vs. non-empty table/collection; first/middle/last/sole removal position; Pseudo rejection on both call sites)
- ✓ Standard edge cases (empty table, empty inline collection, single-entry table, single-element array, boundary index, table-immediately-followed-by-another-header)
- ✓ Stated inverse: insert-then-remove-then-reparse round trips back to a value-equivalent DOM (one test), asserted structurally (item count / value), not by exact string pin — the one deliberately NOT-exact-string-pinned assertion, per §4's "leaves the collection's own surrounding whitespace as-is" fairness carve-out for the sole-remaining-element edge.

Test count anchor (observational, count-agnostic): comparable Shape B/O-Composite-add precedents ran 68-160 tests; given 4 methods × ~4-6 scenarios each plus the cross-cutting buckets, expect roughly 50-70.

## 10. Forced trait bounds / generics / kwargs

Rust, no generics/kwargs forced beyond what already exists on `Rewrite`/`Patch`. The one signature discovery: `insert_array_value`'s `value: &str` and `remove_array_value`'s `index: usize` are both plain, unambiguous types (no boolean-setter-shape ambiguity like F-16's `with_*` trap — these are positional constructor-style arguments named explicitly in the meta, not an options-struct setter), so F-16-style compile-error traps do not apply here and are not being relied on.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal class | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence (in §6) | Test that catches it |
|---|------|------|----------------|-------------------|----------------------|--------------------|-----------------------------|------------------------|
| 1 | Table-insertion anchor must be derived by scanning `table.syntax()`'s ROOT-level siblings, not by using `table.entries()`'s list order or `table.syntax().text_range().end()` directly | F-1 (convergent-architecture wall) / A3 (reuse-the-machinery missing arm) | S-adjacent (repo-internals discovery) | insertion-position correctness | #4 (root/header cross-product shares the same anchor helper) | `table.entries()` and `Node::path` are the natural, most-discoverable DOM tools, and they do not carry file-order truth once a table has both plain entries and nested `[table.sub]` declarations (nested entries can sit anywhere in `entries()`'s insertion order relative to file position) | "immediately after the table's own last directly-declared entry ... always before any of that table's own nested table or array-of-tables declarations" | "insert into header table: table with existing entries AND a later nested `[table.sub]` header" |
| 2 | Inline-collection removal must strip the comma on the OPPOSITE side when the removed element is last (TOML forbids a trailing comma) | proposed, unmeasured — closest analog F-15 (arming-vs-firing: the discriminating fixture is the boundary case, not the interior case) / A8 (polarity inversion) | A-tier | comma-direction correctness | — (self-contained, but shares the helper with the array-vs-table reuse in #3) | "strip the following comma" is the natural first implementation (mirrors how most people mentally model "delete this element and its trailing separator"); it silently produces a stray trailing comma only on the LAST-element case, which many first-draft test suites under-sample (an interior-element test passes under both the correct and the naive rule) | "the following comma normally, or the preceding one when it was the last element" | "remove from inline table/array — position axis: last element" + "sole remaining element" |
| 3 | The same comma-bookkeeping helper must be genuinely shared (not re-derived per node kind) across `Table::Inline` entries and `Array::Inline` items, or the two independently-written versions are likely to diverge (one correct, one not) | proposed, unmeasured — closest analog A3 (reuse-the-machinery missing arm) | A-tier | cross-kind consistency | #2 | `INLINE_TABLE`'s `ENTRY` children and `ARRAY`'s value children sit in the identical comma-separated-sibling shape in the CST, but nothing in the DOM API states this equivalence, so an agent has to notice it structurally rather than being told | (not separately stated — the equivalence is discoverable from the shared CST shape, per Rule-7: state the general removal rule once, let it apply to both kinds) | every inline-array bucket test paired 1:1 with its inline-table counterpart |
| 4 | Root (headerless) table insertion uses a different anchor-scan starting point (scan from the start of the document) than a header'd table (scan from just after the header), and the "insert at offset 0" case additionally flips the newline-prefix convention | F-3 (protected-carve-out applied to one axis only) / F-10 (capability cross-product cell) | S2 (composition of documented rules) | root-vs-header parity | #1 (shares the anchor helper) | agents that build and test the header'd-table case first often hard-code "the anchor always has something before it" and never revisit the assumption for the document-start case | "or at the document's start for the top-level table when nothing precedes it there" + the explicit offset-0 exception | "insert into root table: document whose first line is already a header" (offset != 0 case) paired with "empty document" (offset == 0 case) |
| 5 | `PseudoTableUnsupported` must be enforced identically by BOTH `insert_entry` and `remove_entry`, not just one of them | proposed, unmeasured — closest analog S6 (two evaluators of the same model, here two operations over one classification) | S-adjacent | cross-operation consistency | #1, #4 (same `Table`/`TableKind` values flow through all four methods) | rejecting Pseudo tables is easy to add to whichever method is implemented/tested first and easy to forget on the second, since the check is a one-line guard that does not visually stand out as "shared" | "Dotted-key (pseudo) tables support neither operation" | "pseudo table: both `insert_entry` and `remove_entry` ... error" |

Rows 1 and 4 are interdependent (share the anchor helper: a fix to the root-table branch that special-cases incorrectly can silently break the header-table branch, and vice versa, since both live in one function per §8). Row 5 is interdependent with rows 1/4 (same `TableKind` classification threaded through). Traps sit on 4 distinct axes: insertion-position correctness, comma-direction correctness, cross-kind helper reuse, cross-operation consistency.

## 11b. Capability cross-product matrix (F-10)

Axes: {insert, remove} × {root table (headerless), header'd table}.

| | root table (headerless) | header'd table |
|---|---|---|
| **insert** | test: "insert into root table: document with existing top-level entries only" + "empty document" (offset-0 exception) | test: "insert into header table: table with existing entries" |
| **remove** | test: "remove from header/root table: first entry" run against a root-table fixture | test: "remove from header/root table: first/middle/last entry" run against a header'd-table fixture |

Every cell has an explicit test in §9. The off-diagonal cell most likely to be under-tested by a first-draft author (not just a first-draft agent) is root-table REMOVAL, since `remove_entry`'s removal-range logic (§8, `table_entry_removal_range`) is position-agnostic by construction (it only looks at the entry's own siblings, not at whether a header precedes it) — so this cell is cheap fairness insurance rather than a load-bearing trap; the load-bearing half of this matrix is the INSERT row (row 1/4 above), where root vs. header genuinely changes which anchor-scan direction applies.

Format-noun audit: the meta names "table," "entry," "inline table," "inline array," and "value" — all four map directly to existing `dom::node` types (`Table`, an entry = one `(Key, Node)` pair, `TableKind::Inline`, `ArrayKind::Inline`, `Node`), no ambiguous extent.

Tolerance-fixture audit: the "duplicate key" and "index out of bounds" rules are both hard errors, not "allow one, stop at the second" tolerance rules, so the N-1 fixture pattern (F-15/L25) does not apply to them directly; it is instead captured by trap #2's last-element/interior-element pairing, which follows the same "the boundary case is the discriminator, not the interior case" shape.

## 12. Tier + category decision

- Tier: Olympus (one tier, per the 2026-07 sprint merge — historical shape label used only for precedent lookup, not a live sub-tier choice)
- Sub-rank: Okay-to-Good (clears the 200 LOC floor with a real buffer, 2 genuinely-necessary files, 4+ interdependent/orthogonal-axis traps; would need a batch to confirm Good vs. Okay)
- Category at submit time: **feature-request** (title verb is "Add," net-new public methods/error variants on an existing type — matches the honest category per CLAUDE.md's literal-first-word-of-title rule)

## 13. Predicted Nova pass rate

- Predicted: 15-25%
- Reasoning: 5 named traps across 4 distinct axes (insertion-position correctness, comma-direction correctness, cross-kind helper reuse, root/header parity, cross-operation Pseudo consistency), with 2 explicit interdependent pairs (traps 1/4 share the anchor helper; trap 5 shares `TableKind` classification with 1/4). No single trap is independently >50%-catastrophic (each is a "wrong position/wrong comma" MISSED_REQUIREMENT, not a compile-breaking or crash-inducing trap), so the combined estimate multiplies down from the single-trap ~50% baseline per the difficulty-calibration model (§ HARD RULE — Difficulty-Calibration Model), landing in the 15-25% band rather than at either extreme. The floor is protected because the CORE mechanism (text-splice patches via `PendingPatchKind::Replace` over a computed `TextRange`) is a proven, already-working pattern from `RenameKeys` — at least a careful agent that gets the anchor/comma logic right for the common cases (non-empty header table insert, middle-element inline removal) should pass a meaningful subset even if it misses an edge, keeping this well clear of 0%.
- Sanity check: predicted band (15-25%) sits inside the current sprint ≤40% ceiling with real margin, and above the 0% solvability floor given the RenameKeys precedent's proven machinery. No hint or Diamond routing needed.

## 14. Quality-gate checklist

- [x] Repo understanding: 5/5 in Phase 1 (architecture paragraph, 5 subsystems, 3 high-entanglement zones, test framework/location, cited `rewrite.rs`'s own inline tests as the formatting template — see below)
- [x] Existing PR check: 0 hits in Phase 2 (searches run: "insert", "remove entry", "structural edit", "Rewrite", "add_entry", "DOM mutation", "splice", "array element", "delete key", "toml_edit", "in-place edit", "programmatic edit", "modify toml", "add key programmatically" — against both `gh pr list` and `gh issue list -R tamasfe/taplo --state all`; the two loosely-related issues found (#579 "TOML Keyword Modification Feature," #92 "Table/Inline table conversion") were read in full and are respectively an un-engaged feature question with no PR and no maintainer commitment, and a formatter-output-style request unrelated to a programmatic Rust `Rewrite` API — neither binds or overlaps this pick)
- [x] Closest approved problem opened side-by-side as scaffolding: none of the local `approved-problems/`/`problems/`/`rejected/`/`diamond-problems/` directories contain a TOML/taplo entry (confirmed clean per the task brief); design instead scaffolds off `SHAPES.md`'s Shape B ("new public API list") and O-Composite-add precedents cited in §2/§11.
- [x] Title: verb-led, 5-10 words ("Add Structural Insert and Remove Operations to the DOM Rewrite API" — 11 words including "the"/"to", within tolerance), names specific subsystem
- [x] Shape declared with SHAPES.md § Pattern 11/12 citation
- [x] Public API surface lists every name tests will assert (no "same as X")
- [x] Canonical output form spelled out (insertion position + separator, removal range + comment inclusion, comma direction + its exception, duplicate-key/pseudo-table error behavior)
- [x] 0-1 codebase-inferable requirements (exactly 1: verbatim key/value insertion, inferable from `RenameKeys`'s existing verbatim-replace pattern)
- [x] Description draft: ~178 words, under the 200 recommended cap, well under the 500 hard cap
- [x] Description draft: no `##` headers, no formulaic labels, no `Box<>`, no code-instead-of-prose
- [x] File footprint sketched against REAL source files (rewrite.rs read in full at 200 lines; error.rs read in full at ~28 lines; to_toml.rs read and confirmed NOT needed, correcting the pre-research thesis)
- [x] Raw and meaningful LOC clear the current floor: ~318 raw / ~265 meaningful across 2 files, comfortably above the 200-meaningful floor
- [x] Solution outline: 1+ pure-function helper per description sentence (5 helpers listed in §8, each tagged to its description requirement)
- [x] Fixpoint loop / cycle-trace pattern: not applicable (stated explicitly, not silently omitted)
- [x] Test file outline: 4-block layout, scenario-encoded test names, internal `#[cfg(test)]` module matching repo convention
- [x] 5-axis test coverage planned
- [x] Forced trait bounds / kwargs documented (none forced; F-16 checked and does not apply — explicitly noted why)
- [x] 2-3+ named traps (5 total) each with pre-empt sentence + catching test
- [x] Every trap names an F-id from `failure-patterns.md` or is flagged as an unmeasured guess (traps 1 and 4 cite measured F-ids; traps 2, 3, 5 are explicitly flagged "proposed, unmeasured" with the closest measured analog named, per the skill's requirement to be honest about untested guesses)
- [x] Traps sit on DIFFERENT axes (4 distinct axes across 5 traps), and at least one is interdependent with another (traps 1/4 share the anchor helper; trap 5 shares `TableKind` with 1/4)
- [x] § 11b cross-product matrix filled in, every off-diagonal cell has a test (F-10)
- [x] Form-parity audit (F-18): not directly applicable — the domain has no two lexical spellings of one concept here (unlike gluon's line/block comments); the nearest analog (root vs. header table) is captured instead by §11b's cross-product matrix, which is the correct tool for that specific axis shape
- [x] Format-noun extents stated (§11b format-noun audit)
- [x] Tolerance rule N-1 fixtures: explicitly audited (§11b) and found not directly applicable to the two hard-error rules; the equivalent boundary-case discipline is captured by trap #2's last-element/interior-element test pairing
- [x] Predicted Wrong Logic <25% (this is a positional/bookkeeping-correctness trap set, not an algorithmic-correctness trap in the O-Algorithm-correctness sense; no branch requires inventing a non-obvious algorithm, only correctly deriving positions from the existing CST — Wrong Logic risk is assessed as low, most failures should be MISSED_REQUIREMENT not subtle-algorithm-botched)
- [x] Predicted Nova pass rate ≤40% ceiling (predicted 15-25%)
- [x] Category matches the description (Add → feature-request)
- [x] Feature is NOT pattern-followable (no 3+ existing functions in `rewrite.rs` match this shape — `RenameKeys` is the only existing `Patch` variant, and it solves a materially easier problem: replacing an existing range, never computing an insertion point or comma ownership)
- [x] Feature is NOT in `RULES.md § Features already used` / not derivative of any local approved/rejected TOML entry (none exist to collide with)

### Why this is not a duplicate

No approved, in-flight, or rejected problem in this workspace touches TOML or taplo (confirmed via the task brief and via `problems/`/`rejected/`/`approved-problems/`/`diamond-problems/` directory scope). The one explicitly-flagged dead lane for this repo — `taplo-reorder-comment-preservation` (comment preservation during KEY REORDERING, publicly-solved/maintainer-rejected upstream) — is a different capability on a different file (`formatter/mod.rs`'s reorder logic) from this pick's target (`dom/rewrite.rs`'s structural insert/remove, which never reorders anything and does not touch the formatter). This pick also does not collide with the sibling-ecosystem-tool risk class the way `rspirv-decoration-group-resolution` did: `toml_edit` (the closest famous analog) is a full alternate editable-tree crate with its own parser and node model, not a drop-in algorithm an agent can port into taplo's specific `rowan`-CST-plus-flat-ROOT-siblings-plus-text-splice-`Patch` architecture — the two are related in PURPOSE (both let you edit TOML in place) but not in MECHANISM, and no taplo GitHub PR/issue links to or discusses `toml_edit`'s implementation as a template for this repo (checked in Phase 2).

### Predicted iteration cycles: 2

(1 round to align description wording with the exact anchor/comma rules once real agent failures show which phrasing is ambiguous, per the "3-5 rounds for Olympus" guidance; a 2nd round only if the root-vs-header cross-product or the Pseudo-consistency trap needs a fairness-driven reword after a first batch.)
