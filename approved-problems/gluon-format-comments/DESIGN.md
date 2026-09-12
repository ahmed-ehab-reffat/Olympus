# DESIGN.md — gluon-format-comments

## 1. Title

Preserve and place source comments in the gluon formatter

Verb: Preserve (enhancement — the formatter exists and currently loses/moves comments).

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (SHAPES.md § Pattern 12) — an existing subsystem produces
  observably wrong output on a whole class of inputs; the fix is a new load-bearing model
  (comment classification + attachment + break propagation) threaded through every printing site.
- Pass rate target: <= 40% ceiling (sprint), designing for the hard edge (~10-25%).
- Best agent: mixed; Orion-style decisive implementers should do better than Nova here because
  the work is one coherent model applied at many sites.
- Dominant verdict predicted: MISSED_REQUIREMENT (a comment class silently dropped) and
  REGRESSION (existing 52 formatter tests break when the comment model perturbs layout).
- Solver/our LOC ratio: expect ~1.0-1.3x.

## 3. Public API surface

The user-visible surface is the FORMATTER'S OUTPUT, not new Rust names. The contract is over
`gluon fmt` / `Thread::format_expr` behaviour. Internal names the solution will add (not asserted
directly by tests, listed for the footprint):

- `Comment` — a comment with its byte position and kind, yielded by the source iterator
- `CommentIter` — extended to yield positions rather than bare `&str`
- `CommentPlacement::{OwnLine, Trailing}` — classification of one comment against the preceding token
- `comments_between_with_pos(span)` — position-carrying iteration over a gap
- `trailing_comment(prev_end)` / `own_line_comments(span)` — the two emission primitives
- `contains_line_comment(doc)` / break propagation on the enclosing group

Tests assert only formatter output text, so the solution is free to name its internals differently.

## 4. Canonical output form (REQUIRED — tests assert exact text)

1. **Totality.** Every comment in the input appears exactly once in the output. No drops, no
   duplicates.
2. **Trailing comments.** A comment that begins on the same line as the code preceding it stays on
   that line, separated from the code by exactly one space.
3. **Own-line comments.** A comment that begins on a line with no preceding code on it stays on its
   own line, indented to the same column as the construct that follows it in the same block.
4. **Tail comments.** A comment that follows the last item of a bracketed construct (record, array,
   match arm list, block) but precedes the closing delimiter stays inside the construct, indented
   with the items.
5. **Line comments force breaks.** A construct that contains a `//` comment is always printed in
   its broken (multi-line) form. A `/* */` comment containing no newline does not force a break.
6. **Blank lines.** At most one blank line between items is preserved; runs of two or more collapse
   to one. A blank line is never introduced where the input had none.
7. **Idempotence.** Formatting already-formatted output leaves it byte-identical (the repo harness
   asserts this on every case).
8. **Doc comments.** `///` doc comments keep their existing behaviour (they are metadata, attached
   to the following binding) and are not reclassified as trailing.

## 5. Blind-spot pre-empts (DESCRIPTION.md sentence bank)

- pipeline-placement: state that placement is decided against the SOURCE position of each comment,
  not against the position it would occupy after re-layout.
- result-ordering: state totality explicitly ("exactly once") so the over-firing failure mode
  (duplicate emission from nested constructs sharing a gap boundary) is a stated violation.
- iteration-termination: state idempotence.
- adjacent-vs-all: state that a trailing comment attaches to the code it FOLLOWS, not the item that
  follows it, which is the classification boundary case.

Codebase-inferable requirements: 1 (the existing `///` doc-comment behaviour, visible in
`base/src/types/pretty_print.rs`). Within the <=1 budget.

## 6. Description draft (meta.md)

Target ~200 words. Body opens with the ask, states current behaviour second, then the canonical
rules as prose (not a numbered list). Draft lives in meta.md; the rules above map one-to-one to
sentences there.

## 7. File footprint (sketched against real source)

| Action | Path | Current LOC | Raw delta | Meaningful (x0.65) | Reason |
|---|---|---|---|---|---|
| MODIFY | `base/src/source.rs` | 427 | +95 | ~62 | position-carrying comment iteration; line-start lookup used for classification |
| MODIFY | `base/src/types/pretty_print.rs` | ~430 | +150 | ~98 | classification, the two emission primitives, break propagation, blank-line collapse |
| MODIFY | `format/src/pretty_print.rs` | 1176 | +230 | ~150 | tail-gap consumption per construct (record, array, match arms, block, app args, let bindings, if/else), trailing attachment at each site |
| MODIFY | `format/src/lib.rs` | 46 | +10 | ~7 | plumb the source into the printer where needed |

TOTAL: ~485 raw / ~317 meaningful across 4 modified files.

Floor check (2026-07 sprint): >= 200 meaningful, >= 2 files. Sketch clears with a buffer.

ORACLE-ABSORPTION audit (customasm law — count only line items the repo does NOT already do):
- position-carrying comments: NOT present. `CommentIter` yields `&str` only
  (`base/src/source.rs:345`) and cannot distinguish a blank line from a comment position. COUNTS.
- trailing/own-line classification: NOT present. `make_comments_doc` emits every `//` comment
  followed by `hardline`. COUNTS.
- break propagation for line comments: NOT present. COUNTS.
- tail-gap consumption: PARTIAL. `comments_after` exists and is called at exactly two sites
  (`Expr::Block`, one record path). Every other construct drops its tail gap. COUNTS (partially).
- blank-line handling: PRESENT (the `""` yield). Does not count.

Four of five line items are genuinely missing, which is the inverse of the customasm profile.

## 8. Solution outline — helpers

- `Comment { pos: BytePos, text: &str, kind: CommentKind }` — replaces the bare `&str` yield
- `classify(prev_token_end, comment_pos, source) -> CommentPlacement` — trailing iff no newline
  between `prev_token_end` and `comment_pos` (requirement 2)
- `own_line_comments(span) -> Doc` — requirement 3, current behaviour generalised
- `trailing_comment(prev_end) -> Doc` — requirement 2, emits `space + text` and marks the doc
- `tail_comments(last_item_end, closing_delim_start) -> Doc` — requirement 4
- `forces_break(doc) -> bool` — requirement 5, propagated to every enclosing `group()`
- `collapse_blank_lines(iter) -> iter` — requirement 6

No fixpoint loop applies. No recursion-through-references risk.

## 9. Test file outline

Path: `format/tests/comments_<hex>.rs` (random hex suffix per the banned-marker rule), reusing the
repo's own `test_format!` macro shape so idempotence is asserted on every case for free.

Block 1 — imports + `new_vm` / `format_expr` helpers copied from `format/tests/pretty_print.rs`
Block 2 — no builder helpers needed (inputs are source strings)
Block 3 — one assertion helper: `assert_formats(input, expected)` asserting once and twice
Block 4 — buckets:
- totality: comment after last record field, after last match arm, after last array element,
  before a closing delimiter, at end of file, between two let bindings
- trailing placement: after a record field, after a match arm, after a let binding, after an
  application argument, after a type binding
- own-line placement: before the first field, between arms, inside a nested block, at file start
- break forcing: a record that would fit on one line but carries a `//` comment; the same with a
  `/* */` comment (must NOT break)
- blank lines: one preserved, three collapsed to one, none introduced
- cross-product cells (see 11b)
- edge cases: empty comment `//`, comment containing `*/`, unicode in a comment, comment as the
  only content of a block, CRLF input

5-axis coverage: every canonical rule has >=1 test; the printer sites enumerated in §7 each have
>=1 test; edge cases listed above; the stated inverse (block comment does not force a break) is
covered.

## 10. Forced trait bounds / generics

`pretty::DocBuilder<'a, Arena<'a, A>, A>` carries the arena lifetime and the annotation type `A`;
any new emission helper must be generic over `A: Clone` exactly as the existing ones are. The break
propagation cannot be done by inspecting a built `Doc` cheaply (pretty's `Doc` is opaque enough that
matching on it is brittle), so the natural implementation threads a boolean alongside the doc — the
same shape `comments_count` already uses to return `(doc, count)`. This is the forced design
constraint and it is what makes the trap in §11 T1 reachable rather than accidental.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal class | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence | Test that catches it |
|---|---|---|---|---|---|---|---|---|
| 1 | A `//` comment emitted inside a group that later flattens swallows the rest of the line, producing output that no longer parses (or silently loses code) | F-6 | S4 machinery-riding | group flattening / layout interaction | #2 (both ride the emission chokepoint) | The natural implementation appends the comment text to the current doc and lets pretty decide layout; nothing in the failure names the comment logic — the visible symptom is a parse error on the SECOND format pass | requirement 5 states line comments force the broken form | record that fits in one line but carries a trailing `//` comment; asserted twice (idempotence) |
| 2 | Tail-gap comments double-emitted where two constructs share a boundary (last field of a record inside a match arm) | F-10 | S2 composition | totality / over-firing | #1 | Fixing the drop by consuming the tail gap at each construct means nested constructs consume the SAME gap twice; the failure is a duplicated comment, which reads as a printer bug two levels away | requirement 1 states each comment appears exactly once | nested cross-product cells in 11b |
| 3 | Trailing classification done against the OUTPUT line rather than the SOURCE line, so a comment that was trailing in a construct that gets broken migrates onto the wrong item | F-5 | A5 naive-dominant-reading | attachment source of truth | — | The obvious place to decide "same line" is while emitting, where the current line is known; the correct source of truth is the input span | §5 pipeline-placement sentence | comment after a long record field where the record must break |

All three sit on different axes (layout interaction / totality / attachment source), and #1-#2 are
interdependent through the single emission chokepoint.

## 11b. Capability cross-product matrix (F-10)

Axis 1 = comment placement in source: **own-line** vs **trailing**.
Axis 2 = site: **record field**, **match arm**, **application argument**, **block statement**,
**last item before a closing delimiter**.

| | record field | match arm | app argument | block stmt | last-before-delimiter |
|---|---|---|---|---|---|
| **own-line** | test | test | test (off-diagonal) | test | test |
| **trailing** | test | test | test (off-diagonal) | test | test (off-diagonal, the drop bug) |

Highest-value cells, all currently broken on base and all costing zero description words:
- trailing comment on the LAST record field (the measured drop)
- trailing comment on the LAST match arm (the measured escape-and-dedent)
- trailing comment on a match arm that is itself the value of a record field (nested; the
  double-emission cell for trap #2)

Scope audit: requirement 5 is scoped to "a construct that contains" a line comment — the enclosing
group and every group above it, not just the innermost. This is the F-11-shaped seam here (local vs
global scope of the break decision) and the nested cell above is the fixture that separates them.

Example audit (L21): the meta must state the rules without worked examples. An example showing one
site would be read as the rule's scope.

## 12. Tier + category

- Tier: Olympus (one tier).
- Category: **enhancement** — the formatter exists; this fixes and generalises its comment handling.
  Title verb "Preserve" matches.

## 13. Predicted Nova pass rate

10-25%. Reasoning: the model is statable in full (fair) but the implementation has three
independent failure surfaces, one of which (break propagation) only shows up on the second format
pass, and the repo's own 52 existing formatter tests are a live regression wall that punishes any
model that perturbs general layout. Risk of landing ABOVE the ceiling: an agent that implements
classification cleanly may get the rest for free — mitigated by the nested double-emission cell.
Risk of 0%: low; each rule is independently implementable, so partial credit is not the issue,
totality is.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (architecture, subsystems, entanglement zones, test framework at
      `format/tests/pretty_print.rs`, template cited)
- [x] Gate 1 behavioural f2p gap REPRODUCED on base through `gluon fmt`: trailing comment after a
      record field is DELETED; trailing comment on the last match arm is moved out of the match and
      dedented to column 0; `let x = 1 // c` moves the comment to its own line
- [x] Gate 5 cold-not-live: `format/src/pretty_print.rs` last behavioural change 2020-10-15;
      2026-07 commits are `cargo fmt` / Edition 2024 / `s/expr_2021/expr/g` churn only
- [x] Gate 7b exclusivity: no open PR touches `format/src/pretty_print.rs`; #977 touches only
      `format/Cargo.toml` + `format/src/lib.rs`; #897 "Format macro" is a string-formatting macro in
      `src/format_macro.rs`, unrelated
- [x] Gate 8 maintainer philosophy: PR #316 "feat: Vastly improve when comments are kept during
      formatting" (MERGED) shows the class is welcome; no decline, no open design debate
- [x] Repo quota 1/6 (gluon-match-guards in flight); not in SATURATED-REPOS.md
- [x] Self-collision: match-guards is a parser/check/core-translate capability about match
      semantics; this is a formatter output capability. Shared file: none in the solution footprint
- [x] TOO-EASY guard: not a uniform wrap (three interacting mechanisms), not a single-subsystem
      mechanical transform (base + format, and the break propagation is a layout-model change), does
      not depend on hiding anything (all rules stated), not a saturated-reference port (gluon's own
      layout rules), survives full specification
- [x] Traps name F-ids, sit on different axes, two are interdependent
- [x] 11b filled, off-diagonals have tests
- [x] Footprint sketched against real files, ~317 meaningful > 200 floor
- [ ] Baseline determinism: `cargo test -p gluon_format --test pretty_print` = 52 passed / 0 failed
      in 0.24s (1 run so far; 3x pending at build time)
- [ ] NOTE for test.sh: `cargo test -p gluon_format` in isolation FAILS TO COMPILE on base —
      `format/tests/std.rs` uses `#[tokio::main]` while format's dev-dependency enables only
      tokio's `macros` feature. This is a pre-existing baseline defect that only workspace feature
      unification hides. Base mode must scope to buildable targets and document the reason.

## Why this is not a duplicate

Closest approved: `pulldown-cmark-gfm-autolinks` (Rust, a parser-adjacent output-correctness
capability with a stated canonical form) and `calyx-unused-port-elimination` (whole-program
analysis). This differs from both in subsystem (a pretty-printer / layout engine), in trap category
(layout-flattening interaction rather than pipeline placement or fixpoint liveness), and in the
observation channel (exact formatted text, asserted twice for idempotence).

Predicted iteration cycles: 2.
