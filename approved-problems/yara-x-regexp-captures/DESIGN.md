# DESIGN.md — yara-x-regexp-captures

## 1. Title

Add capture groups to regexp patterns and expose them in conditions

Verb-led, 8 words, names the subsystem (regexp patterns + condition accessors).

## 2. Shape classification

- Shape: **O-Composite-add** (new capability spanning regexp parser, regexp bytecode compiler,
  Pike VM, match storage, scanner verification, rule parser/AST, IR, static typing, WASM emission
  and runtime). Cite `SHAPES.md § Pattern 12`.
- Pass-rate target: **<= 40% cap (sprint)**; design target **1/10**, the corpus mode.
- Best agent: Orion (long-horizon); Nova expected to thrash on the backward-direction trap.
- Dominant verdict expected: MISSED_REQUIREMENT (backward verification / wide coordinates).

## 3. Public API surface (rule-language surface, not Rust API)

Everything the tests assert is written in the YARA rule language, which is a runtime string.
No new Rust symbol is required by the tests, so `test.patch` compiles on base and fails at runtime.

- `( ... )` inside a regexp pattern — a capturing group.
- `(?: ... )` inside a regexp pattern — a non-capturing group (already accepted, now explicitly
  excluded from numbering).
- `@a[i][g]` — offset of capture group `g` in the `i`-th match of pattern `$a`.
- `!a[i][g]` — length of capture group `g` in the `i`-th match of pattern `$a`.
- `g = 0` — the whole match, so `@a[i][0] == @a[i]` and `!a[i][0] == !a[i]`.
- `undefined` — the value of both accessors when the group did not participate, when `g` exceeds
  the number of groups in the pattern, or when the pattern is not a regexp.

## 4. Canonical output form

- **Group numbering:** groups are numbered from 1 in the order their opening parenthesis appears,
  left to right; a nested group gets a higher number than the group that encloses it.
  `(?:...)` does not consume a number.
- **Alternation:** leftmost-first, matching the priority order the engine already uses for
  greediness. `(a)|(b)` on `b` leaves group 1 undefined and group 2 defined.
- **Repetition:** a group inside a repetition reports the last iteration that matched.
- **Coordinates:** offsets are absolute offsets into the scanned data and lengths are byte counts,
  in the same coordinate system as `@a` and `!a`. For a `wide` pattern the reported length counts
  the interleaved zero bytes, so a group spanning two characters has length 4.
- **Empty group:** a group that matched the empty string has a defined offset and length 0.
- **Zero matches:** `@a[i][g]` with `i` beyond the number of matches is undefined, as today.

## 5. Blind-spot pre-empts (from `DESCRIPTION.md` sentence bank)

- Result ordering / numbering: "numbered from one in the order their opening parenthesis appears".
- Falsy-on-invalid: "undefined when the group did not participate".
- Adjacent-vs-all: "a group inside a repetition reports the last iteration that matched".
- Parallel API: `!a[i][g]` stated with the same semantics as `@a[i][g]`.
- Codebase-inferable requirements: exactly **1** (that `@a[i]` and `@a[i][0]` agree, which the
  existing accessor already fixes).

## 6. Description draft

See `meta.md`. Plain prose, no headers, ASCII, <= 500 words hard cap.

## 7. File footprint (sketched against real source)

| Action | Path | Raw delta | Meaningful (x0.65) |
| --- | --- | --- | --- |
| MODIFY | `lib/src/re/hir.rs` | +45 | 29 |
| MODIFY | `lib/src/re/thompson/instr.rs` | +85 | 55 |
| MODIFY | `lib/src/re/thompson/compiler.rs` | +130 | 85 |
| MODIFY | `lib/src/re/thompson/pikevm.rs` | +210 | 137 |
| MODIFY | `lib/src/re/mod.rs` | +45 | 29 |
| MODIFY | `lib/src/scanner/matches.rs` | +45 | 29 |
| MODIFY | `lib/src/scanner/context.rs` | +65 | 42 |
| MODIFY | `parser/src/ast/mod.rs` | +55 | 36 |
| MODIFY | `parser/src/parser.rs` (grammar) | +45 | 29 |
| MODIFY | `lib/src/compiler/ir/mod.rs` | +85 | 55 |
| MODIFY | `lib/src/compiler/emit.rs` | +65 | 42 |
| MODIFY | `lib/src/wasm/mod.rs` | +65 | 42 |
| MODIFY | `lib/src/compiler/mod.rs` (fast-path eligibility) | +35 | 23 |

TOTAL: ~975 raw / ~633 meaningful across 13 files in 2 crates. Clears the >= 450 human-effective
design floor with margin; gate on `effective_loc_check.py` before submit.

## 8. Solution outline — pure-function helpers

- `Hir::capture_count()` -> `usize` — number of capturing groups (numbering source of truth).
- `Hir::capture_slots()` -> `usize` — `2 * (capture_count + 1)`, the slot vector length.
- `Instr::SaveStart(slot)` / `Instr::SaveEnd(slot)` — new bytecode instructions, emitted around
  the body of every `HirKind::Capture`, with start and end swapped when compiling the backward
  code so that a backward run records the same span.
- `Thread { ip, rep_count, slots }` — the Pike VM thread now carries a slot vector; slots are
  copied on split, and the first thread to reach an instruction keeps its slots (priority).
- `slots_to_ranges(slots, direction, base, wide) -> Vec<Option<Range<usize>>>` — converts VM slot
  positions into absolute data ranges, undoing the backward direction and the wide doubling.
- `Match::captures` — `Option<Box<[Option<Range<usize>>]>>` stored per match.
- `pattern_capture_offset(pattern_id, match_index, group)` / `pattern_capture_length(...)` — WASM
  builtins returning `Option<i64>`, mapping to YARA `undefined`.
- Fast-path eligibility: `pattern_has_captures()` forces verification through the Pike VM.

## 9. Test file outline

Path: `lib/tests/captures_<hex>.rs` (new file, conventional location, random hex suffix, no banned
marker). Plus a small parser-level file `parser/tests/capidx_<hex>.rs` for the grammar.

Block 1 — imports (only `yara_x` public API).
Block 2 — builders: `rule_with(pattern, condition)` one-liners.
Block 3 — assertion helpers: `matches(rule, data)`, `not_matches(rule, data)`.
Block 4 — buckets:
- numbering (nested, non-capturing, alternation) — 12
- group 0 agreement with `@a`/`!a` — 6
- undefined cases (out-of-range group, non-participating, non-regexp pattern) — 10
- repetition last-iteration — 6
- backward verification (atom in the middle / at the end) — 10
- wide + nocase coordinates — 10
- empty group, anchors, classes — 8
- multiple matches, `#a` interaction, `for` loops over `@a[i][g]` — 10
- grammar / static errors — 8

Target ~80 tests. 5-axis coverage checked.

## 10. Forced signatures

No new Rust API is asserted by the tests, so there is no signature coin-flip (the fake-difficulty
anti-pattern is structurally avoided). The only pinned surface is the rule-language grammar.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt sentence | Catching test |
| --- | --- | --- | --- | --- |
| 1 | Backward verification records mirrored spans | yara-x verifies a match by running the VM backward from the atom; a natural implementation records slot positions in the backward coordinate system and reports reversed or negative spans. The failing assertion is an offset value, which points at the accessor, not at the direction. | "offsets are absolute offsets into the scanned data" | `capture_offset_when_atom_is_in_the_middle` |
| 2 | Wide coordinates | `wide` patterns run the VM over a de-interleaved view; slot positions must be doubled. Only wide tests fail, so the symptom looks like a modifier bug. | "for a wide pattern the reported length counts the interleaved zero bytes" | `wide_group_length_counts_zero_bytes` |
| 3 | Thread priority on dedup | the VM keeps at most one thread per instruction; keeping the LAST arrival instead of the FIRST silently changes which alternative's captures survive. Greediness still looks right because the overall match is unchanged. | "leftmost-first" | `alternation_prefers_leftmost` |
| 4 | Fast-path bypass | patterns simple enough for the fast matcher never reach the Pike VM, so their captures are silently absent. | "every regexp pattern with a capturing group reports captures" | `plain_literal_group_still_captures` |
| 5 | Repetition last-iteration | naive slot handling keeps the first iteration. | "reports the last iteration that matched" | `repeated_group_reports_last_iteration` |

Traps 1, 2 and 4 are interdependent through one chokepoint (the slot-to-range conversion), so a
local fix to one regresses another; trap 3 lives in the epsilon closure and trap 5 in the compiler.

## 12. Tier + category

- Tier: Olympus. Sub-rank target: Good/Excellent.
- Category: feature-request (net-new rule-language surface).

## 13. Predicted pass rate

10% - 25%. Levers stacked: one interdependent kernel (slot-to-range conversion) driving every
accessor; exact-output correctness against an external oracle (Python `re` / Rust `regex` for
group semantics, fuzzed); five interdependent + misdirecting traps including two
"obvious code is wrong" edges; six-file minimum span, ~633 effective LOC.

## 14. Quality gate checklist

- [x] Repo understanding 5/5 (pipeline: tokenizer -> parser/CST -> AST -> IR -> WASM -> scanner;
      subsystems: parser, compiler, re engine, modules, scanner, wasm; entanglement zones:
      `re/thompson`, `compiler/emit.rs`, `scanner/context.rs`; tests via `lib/tests/*.rs`;
      template `lib/tests/mod.rs`)
- [x] Exclusivity: `gh pr list --state all --search "capture group|capturing|backreference|
      submatch|regexp group"` = 0 hits; all 5 non-default branches diffed, none touch `lib/src/re/`
- [x] Dedup: the one local yara-x problem (`Aprroved/yara-x-aggregate-expressions`) is the
      condition-loop subsystem; this is the regexp engine. No capture/submatch problem anywhere in
      `problems/`, `rejected/`, `Aprroved/`
- [x] Repo quota: 1 of 6 used
- [x] Corpus hardness recipe: one kernel (the slot-to-range conversion) drives every accessor;
      five traps, all reproduced during implementation and all killed by the mutation battery
- [x] LOC gate: `human-effective` 472 over the 16 non-test source files (1119 counting the
      goldenfile churn the change forces)
- [x] Flakiness: five runs of each mode, identical every time
- [x] Every new test fails on base (86 of 86); both patches apply in either order
- [ ] FP check — needs the agent batch first

## Why this is not a duplicate

Closest siblings: `Aprroved/yara-x-aggregate-expressions` (same repo, but the condition loop and
IR/WASM emission of aggregates, nothing in `lib/src/re/`) and `Aprroved/logos-lexer-assertions`
(a lexer generator gaining look-around assertions — a different engine, a different construct, and
no submatch reporting). No local problem touches capture groups, submatches or Pike VM thread
state.

Predicted iteration cycles: 3.

## Post-implementation notes

The trap matrix in section 11 survived contact with the code, with one correction: trap 4 is not
one fast path but three. A pattern only reaches the regexp engine if it escapes the exact-atom
short circuit in the scanner, the `LiteralWithMask` sub-pattern, and the alternation-of-literals
path, and each of the three silently reports no groups at all. `/a(bc)d/` took the
`LiteralWithMask` route and reported nothing while `/x(ab)+y/` worked immediately.

Named groups were added after the first pass. They are resolved to numbers at compile time, so
the runtime only ever deals with numbers, and a name the pattern does not define is a compile
error rather than an undefined value.
