# feedback.md — wirefilter-dynamic-operands

Repo: cloudflare/wirefilter (MIT, 1149 stars, last commit 2026-07-21, Rust, 19.8k LOC)
Base: `af1a1e960a8fdc44a1a154553470dfbb286afbe8`
Tier: Olympus. Shape: O-Composite-extend (existing language surface extended through parse,
type-check, compile and visitor stages).

## Attempt history

### R1 — pick + gates (2026-07-26)

Ran the 10 PICK-FILTER gates before authoring:

- F2P gap: probed on base, every target form is a parse error (`http.host == http.referer`,
  `port > backend_port`, `http.host contains http.referer`, `http.host in hosts`,
  `port & backend_port`, `headers[key] == http.host`). The right-hand side of every comparison is
  hard-wired to a compile-time literal (`RhsValue::lex_with`, `RhsValues`, `BytesExpr`, `i64`,
  `Regex`, `Wildcard`), and `FieldIndex` only holds a constant index or key.
- Exclusivity: canonical org confirmed (no redirect). PR search across all states for
  `field comparison`, `rhs field`, `dynamic`, `compare two fields`, `field reference`, `index`,
  `arithmetic` returns nothing touching the comparison-operand surface. Issue #62 (open) asks
  generically for fuller Cloudflare Rules syntax support.
- Dedup: no wirefilter and no filter-expression-operand pick in `problems/`, `rejected/`,
  `Aprroved/`, `Olympus/`.
- Saturation / derivative: the semantics here (positional pairing, symmetric missing-value rule,
  computed index rules, contains-set) are invented for this engine. There is no reference
  implementation to port and no external oracle involved.
- Cold: recent maintainer work is refactor and perf (PRs #162-#185), nothing on the operand
  surface.
- Flakiness: `cargo test --workspace` on base is green in under 2s with no timing, network,
  ordering or parallelism dependence.
- Env quality: `cargo check --workspace --all-targets` succeeds on the vanilla tree, all members
  included (`engine`, `ffi`, `wasm`, `fuzz/*`). Deps are light and `Cargo.lock` is committed.
- Repo quota: first submission against this repo, 1149 stars, niche.

### R2 — implementation

Built in four passes, measuring effective LOC after each:

1. Expression right operands for ordering / `bitwise_and` / `contains` / `in`, with the shape and
   missing-value rules. 203 human-effective LOC.
2. Computed index keys (`FieldIndex::Dynamic`), with a borrow-path and a consume-path resolver
   mirroring the existing `get_nested` / `extract_nested` split. 354.
3. Boolean operands (restructuring the `IsTrue` short-circuit) and whole array/map equality. 411.
4. `contains {...}` sets mixing literals and expressions. 503.

Two implementation notes worth keeping:

- Adding one `FieldIndex` variant produced five compile errors across `types.rs`,
  `index_expr.rs` and `scheme.rs`. This is the A1 invasive-threading cost a solver pays too.
- My own first cut had the visitor bug the problem now tests for: `FilterAst::uses` under-reported
  fields reached through a computed index until `IndexExpr::walk` was taught to descend into
  dynamic index expressions.

### R3 — F2P closure

First run of the new suite on base showed 3 tests passing (they only asserted behavior that
already worked: `static_index_forms_keep_working`, `bool_field_alone_still_tests_truth`,
`mapped_bool_array_still_tests_truth`). Added one new-behavior assertion to each so every test in
the file fails on base. Now every test in the file fails on base and passes with the solution.

### R4 — Description Quality precheck (request_changes: 1 HIGH, 3 MEDIUM, 1 LOW)

All five were removals of sentences the checker read as restating existing behavior. Applied the
HIGH and all three MEDIUMs verbatim: dropped the backward-compatibility sentence, the
`bitwise_and` "share a bit" clause, the `in` "equals one of the elements" tail, and "arrays of
booleans keep feeding `any` and `all`". Each is either existing literal-operator semantics visible
in the repo or implied by the result-shape rules that remain stated.

The LOW suggestion (drop "the expression in the brackets yields a single value rather than a mapped
one") was NOT dropped outright, because `contains_set_rejects_non_bytes_elements` asserts that
`http.host contains {hosts[*]}` does not parse, and nothing else in the description covers a mapped
expression in a value position. Test Fairness outranks description brevity here, so the clause moved
to the `contains` set sentence where the test actually needs it, and the redundant bracket wording
the checker objected to is gone. meta is now 411 words.

### R5 — Description Quality precheck round 2 (request_changes: 2 HIGH, 2 MEDIUM)

Both HIGH quotes are gone from the description:

- The operator enumeration ("work with the ordering operators, with `bitwise_and` and with
  `contains`") is deleted. It followed from the general rule anyway, and de-enumerating helps
  difficulty as well as brevity.
- The combined boolean/address sentence is deleted. The address half really is existing behavior
  (`strict_partial_cmp` already governs it for literal operands, so the base engine defines it).
  The boolean half is NOT: on base a boolean field short-circuits to a truth test and there are no
  boolean literals, so nothing in the repo says how `flag_a < flag_b` orders. It stays as five
  words, "Booleans order false below true", because `bool_operands_order_false_below_true` asserts
  it and no reader could derive it.

The two MEDIUMs (optional) were compressed rather than removed, for the same reason:

- The broadcast sentence now covers only the NEW direction (a mapped right operand against a single
  left value). The existing left-side broadcast recap the checker objected to is gone, but
  `mapped_right_operand_broadcasts_single_value` and `mapped_right_operand_over_map_values` need
  the direction that does not exist on base to be stated.
- "a mapped side that has no value produces no booleans" is folded into the missing-value sentence.
  It is existing behavior only for a missing mapped LEFT operand; for a mapped right operand and
  for both-sides-mapped it is this task's rule, and the plausible alternative (one boolean per
  element of the side that is present) would fail three tests. Leaving it unstated risks a fair
  looking but universal miss.

meta is now 381 words. Pattern to keep in mind for this repo: this checker treats any clause that
resembles existing semantics as noise, but half of these clauses only look existing because the
literal form of the same operator exists. Check each quote against what base actually accepts
before deleting it.

### R6 — coverage suggestions (advisory, both added)

- `missing_computed_array_index_field_has_no_value`: `hosts[idx]` with `idx` unset, in both operand
  positions, asserting equality false and inequality true. Mirrors the map-key case.
- `contains_set_accepts_function_call_elements`: a `contains {...}` element that is a function call,
  including a set mixing that call with a literal.

Both fail on base, so F2P still holds: 101 tests at that point, all failing on base and all passing
with the solution. Full Docker 4-cell re-run, all cells green, new mode deterministic across 3 runs.

### R7 — coverage suggestions round 2 (advisory, all three added)

- `mapped_operands_of_mismatched_element_types_are_rejected`: `any(hosts[*] == ports[*])` and the
  reverse do not parse, with `any(hosts[*] == other_hosts[*])` as the canary so the test cannot pass
  vacuously on base.
- `missing_indexed_collection_has_no_value`: the indexed collection itself is unset while the key or
  index is present, for both a map key and an array index, in both operand positions.
- `pattern_operators_accept_expression_left_sides`: `matches` and `wildcard` keep working when the
  LEFT side is a function call or a computed index, while the pattern on the right stays literal.
  This is the regression guard for the operand and set hooks added to the `contains` / pattern arm.

Writing the second test caught a mistake in my own expectation rather than in the implementation: I
first asserted that `http.host == hosts[idx]` matches when `hosts` is unset. The documented rule is
symmetric, so a missing right operand makes equality false and only the not-equal form true. The
assertion was corrected, not the engine.

Now 104 tests, 104/104 fail on base, 104/0 with the solution. Docker 4-cell re-run again after this
round.

### R8 — Solution Quality precheck: FAIL (comprehensiveness 1/3, code quality 2/3)

The finding was real and specific, not a false positive. `ComparisonExpr::lex_with_lhs` attempted the
boolean operand read for any type whose INNER type is Bool, and the pre-existing fallback then turned
an unmapped `Array(Bool)` / `Map(Bool)` left side into a truth test, so those collections could never
reach the whole-collection equality path that `hosts == other_hosts` uses. The description says whole
arrays and maps compare for equality without carving out booleans, so this was an inconsistency
against my own contract, and the reviewer's second point (semantics depending on which parser branch
fires first) followed from the same shape.

Fix, and it made the control flow simpler rather than more special-cased: `lex_bool_operand` became
`lex_ordering_operand(input, parser, expected)`, which reads an ordering operator plus an operand of a
given type and yields nothing unless the operator is one that type supports. It now runs once for
every type that has NO literal form (`Bool`, `Array(_)`, `Map(_)`), before the truth-test decision.
The separate Array/Map arm I had bolted into the operator match is deleted, so there is a single rule:
types without a literal form read an operand expression, types with one try an operand and then fall
back to the literal. Base behavior is untouched because a non-ordering operator (`&&` after a boolean
array, for instance) still yields nothing and falls through to the old branches.

Tests added for the gap and for the two advisory coverage items: whole `Array(Bool)` equality, whole
`Map(Bool)` equality, boolean-collection truth tests still working alongside the new comparison,
`matches`/`wildcard` rejecting every expression form on the right (function call, computed index,
plain field), and both whole-collection operands missing at once.

109 tests now, 109/109 fail on base, 109/0 with the solution, full Docker 4-cell re-run green and
deterministic. Effective LOC 494 after the simplification (was 503), still clear of the floor.

### R9 — Test/Problem Alignment precheck (WARNING, behaviors OK)

Behaviors came back OK. The one warning was worth acting on rather than waiving: "a computed index
cannot be combined with `[*]` in the same access" could be read as "in the same bracket", while
`dynamic_index_cannot_combine_with_map_each` rejects `nested[*][idx]` and `nested[outer_idx][*]`,
which mix them at different levels of one chain. Reworded to "a computed index and `[*]` cannot both
appear in one access chain, at any level of it". This is a rejection rule, so stating it precisely
costs no difficulty. meta 384 words, no test or patch change, so validation still stands.

## Trap inventory (what is expected to bite)

| Trap | Class | Why it bites |
| ---- | ----- | ------------ |
| Literal fast paths and serde shapes must survive | S3 | comparisons compile through per-op, per-type `Compare` specializations plus precompiled substring searchers and range sets; rerouting everything through one generic path regresses base tests |
| Four operand shapes, three compile paths | S5 | `IndexExpr::compile_with` picks One/Vec from the left side's map-each count only, so mapped-right and both-mapped need paths built from value expressions and a positional zip |
| Symmetric missing-value rule | S2 | the existing default only covers a missing left operand; the `!=` inversion has to apply when the right operand is the missing one |
| Whole-collection equality vs positional pairing | S2 | `hosts == other_hosts` and `all(hosts[*] == other_hosts[*])` disagree on unequal-length arrays |
| `uses` / visitor | machinery-riding | nothing in "compare two fields" points at the visitor |
| Parse-time typing and rejections | S6 | mismatched types, Map operands for `in`, expression patterns for `matches`, and computed index combined with `[*]` must be rejected at parse time |
| Invasive threading in Rust | A1 | one new enum variant plus a new AST variant family inside a 3.3k-line file |

## Open items

- Platform batch is the only difficulty oracle; no batch run yet.
- Serde output for the new AST variants is deliberately not asserted by tests, so an invented JSON
  shape is not pinned. Existing serde tests stay untouched and pass.
