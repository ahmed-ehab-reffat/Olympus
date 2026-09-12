# eval-results.md — taplo-dom-structural-edit

No platform agent runs yet (no platform access from this authoring session). This file
tracks the mandatory local FP-mutation sweep (skill Pre-Submit Checklist § FP prevention)
run against the 5 traps claimed in DESIGN.md §11, in place of a real per-agent table until
the first platform batch.

## Local FP-mutation sweep (per-branch mutation, run 2026-08-23)

Each row: one hand-mutation of `solution.patch`'s logic, re-run `./test.sh new` (locally:
`cargo test -p taplo --lib rewrite_structural_afe591::`), restored after.

| # | Mutation | Trap it should kill | Result |
|---|---|---|---|
| 1 | `regular_table_anchor`: stub to always return the ROOT-branch's initial `anchor = 0` (never scan siblings) | #1 anchor-derivation | 6 tests went red (`insert_header_table_*`, `insert_root_table_with_existing_entries`) — killed |
| 2 | `regular_table_anchor`: delete the `SyntaxKind::TABLE_HEADER \| SyntaxKind::TABLE_ARRAY_HEADER => break` arm (let the scan run past the next header) | #1 / #4 root-header parity | `insert_header_table_before_later_nested_table` and `insert_header_table_immediately_followed_by_another_header` went red — killed |
| 3 | `inline_member_removal_range`: delete the `preceding_comma_start` fallback branch entirely (only ever strip the following comma) | #2 comma-direction | `remove_inline_table_last_entry_strips_preceding_comma` and `remove_inline_array_last_value_strips_preceding_comma` went red; result also failed to reparse (dangling trailing comma) — killed |
| 4 | `entry_insertion`/`array_insertion`: remove the `TableKind::Pseudo` guard and the `find_entry_ancestor`-returns-`None` guard (let Pseudo/header-declared paths fall through) | #5 Pseudo consistency (both operations) | `insert_into_pseudo_table_errors` and `remove_from_pseudo_table_errors` both went red (panicked instead of erroring, since a Pseudo table's `.syntax()` is a bare `KEY` token with no bracketed close) — killed |
| 5 | `append_into_bracketed`/array counterpart: force `find_array_member` and the ENTRY-vs-INLINE_TABLE branch in `entry_removal_range` to always take the `line_removal_range` (root/header) path, never `inline_member_removal_range` | #3 cross-kind helper reuse | every `remove_inline_table_*` and `remove_inline_array_*` test went red or produced a malformed string — killed |

All 5 claimed traps confirmed to actually discriminate; none overclaimed. No trap needed to
be dropped or a test strengthened.

## Feature-stub run

Stubbed all 4 new `Rewrite` methods to return `Ok(self)` without queuing any patch (a no-op
"feature disabled" stand-in). Result: every test in `rewrite_structural_afe591` went red
except the *_errors tests that assert on inputs unrelated to the stubbed no-op path staying
an error (duplicate-key/pseudo/not-found/out-of-bounds checks still run before the no-op, so
those still correctly error) — expected and consistent with those being validation-only
assertions, not behavioral no-ops.

## Assertion-flip spot check

Flipped 6 `assert_eq!` expected strings (one per insert/remove bucket) to a deliberately
wrong string; all 6 failed as expected (none vacuously green). No `is_ok()`/`len() > 0`-style
weak assertions exist in the new suite to flip.

## Flakiness gate

`cargo test -p taplo --lib` run 3x after `solution.patch` applied: 140/140 green, identical
every run (no timing, no thread-count sensitivity, no HashMap-iteration-order dependence —
`Entries.all` is an insertion-ordered `Vec`, not iterated unordered). `cargo test -p taplo
--lib` run 3x on bare `$BASE_COMMIT` (test.patch applied, solution not applied): fails to
compile identically every run (missing `insert_entry` etc. on `Rewrite`), producing the
build-failure-fallback JUnit XML each time.

## Owed to the platform

- Docker build/run validation (no local Docker on this workstation; RUN command's cargo
  half verified statically against the `test.patch`-only tree instead, see feedback.md).
- Nova/Orion/Vega pass-rate batch (predicted 15-25% per DESIGN.md §13; unmeasured).
