# feedback.md — taplo-dom-structural-edit

## Strategic summary

Adds `insert_entry`, `remove_entry`, `insert_array_value`, `remove_array_value` to
`taplo::dom::rewrite::Rewrite`. The existing `Rewrite` type only supports renaming an
existing key in place via a text-splice `Patch::RenameKeys`; this submission extends the
same patch-list/text-splice machinery with structural insert/remove operations for table
entries and inline array elements, while preserving all formatting and comments outside the
edited region.

The core difficulty is that taplo's CST is FLAT at the root level (`TABLE_HEADER` /
`TABLE_ARRAY_HEADER` / `ENTRY` are direct siblings of `ROOT`, not nested per table), so a
table's own `Node` API (`entries()`, `syntax()`) does not carry the file-order position
needed to correctly insert a new entry after a table's own existing entries and before its
own nested table declarations. The correct insertion anchor must be derived by walking
ROOT-level CST siblings. Full design rationale, F-id trap mapping, and the capability
cross-product matrix are in `DESIGN.md`.

Deviations from `DESIGN.md` found during implementation (both are simplifications toward
the SIMPLER, still-fair, already-documented contract, not undocumented complexity):

- The plan's `splice_into_bracketed` helper originally imagined inserting "before a trailing
  whitespace token" to keep spacing pretty. Probing the actual CST showed inline-table/array
  entries ABSORB their own trailing whitespace up to the next `,`/`}`/`]` (the parser's
  `whitelisted!` trivia-absorption), so there is no separate whitespace sibling to detect.
  Kept the simpler "insert directly before the closing bracket/brace" rule, which matches the
  meta's stated contract ("separated by `, `... regardless of existing spacing") exactly.
- Adding the 4 new `dom::error::Error` variants broke an EXHAUSTIVE match in
  `taplo-lsp/src/diagnostics.rs` (a downstream consumer of the public error enum). Fixed by
  adding the new variants to that match's existing no-op arm (`taplo-lsp` never produces
  these errors itself; `dom.validate()` cannot raise them). This makes the submission
  genuinely 3 files instead of the design's 2, which only strengthens the cross-package
  case.

## Iteration history

### Iteration 1 (initial authoring, 2026-08-23)

- Implemented `dom/rewrite.rs`, `dom/error.rs`, `taplo-lsp/src/diagnostics.rs` per DESIGN.md.
- Wrote 36 new tests in `crates/taplo/src/tests/rewrite_structural_afe591.rs` covering all
  DESIGN.md §9 buckets (root/header table insert with the 3 anchor cases, inline table/array
  insert and remove including the last-element comma-direction discriminator and the
  sole-remaining-element edge, duplicate-key/pseudo-table/not-found/out-of-bounds errors,
  and a chained-patch bucket covering both a clean multi-patch application and a genuine
  overlap rejection).
- Local validation: `cargo build --workspace` clean (only a pre-existing, unrelated
  `dead_code` warning in `formatter/mod.rs`); `cargo test -p taplo --lib` 140/140 green
  (104 pre-existing + 36 new); FP mutation sweep run against all 5 claimed traps (see
  eval-results.md) — all 5 confirmed to actually kill the relevant test(s) when mutated.
- No platform runs yet — Docker validation and Nova/Orion/Vega batches are owed to the
  platform (no local Docker on this workstation).

## Env Description (draft, paste into Shipd UI at submit)

Extending a lossless-formatting DOM patch API in a Rust `rowan`-based CST library. The
environment teaches: (1) that a DOM node's own `.syntax()` position is not sufficient to
derive a correct edit anchor when the underlying CST is flatter than the DOM tree it
represents, and (2) that comma/separator bookkeeping in a bracketed list is
position-dependent (last element vs. interior element), not a single uniform rule. A
successful trajectory reads `dom/rewrite.rs` and `dom/node.rs` before touching code, derives
the ROOT-sibling-scan anchor algorithm from `from_syntax.rs`'s flat-root traversal rather
than trusting `Table::entries()` ordering, and writes the last-element comma case as its own
branch. A failing trajectory inserts at `table.syntax().text_range().end()` unconditionally
(wrong position once the table has its own nested sub-tables) and/or strips the same-side
comma regardless of position (leaving a trailing comma before `}`/`]`, i.e. invalid TOML,
when the removed element was last).
