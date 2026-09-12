# eval-results.md — ezno-enum-declarations

## Batch 1 (2026-08-03, 3 runs, 149 tests)

| Batch | Agent | Verdict | Baseline | New | Failed | Failure reason | Approach note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Orion_Nova_1 | FAIL | pass (61) | 70/149 | 79 | member types rejected against the literal values they hold | nominal `enum_subtyping` hook, member intercepted on both sides |
| 1 | Orion_Nova_2 | FAIL | pass (61) | 72/149 | 77 | same, plus empty-enum number assignability and the reverse-entry key | custom `Type::EnumMember` variant |
| 1 | Orion_Nova_3 | FAIL | pass (61) | 73/149 | 76 | same, plus empty enums and const / declare / export syntax | member value stored, nominal subtyping both directions |

Pass rate 0/3. All three produced a substantial, compiling implementation and kept the baseline green,
so this is not an environment or capability failure.

### Diagnosis: one deterministic universal miss

76 of the failures are IDENTICAL across all three runs, and 74-78 of each run's failures carry the
same shape of message: `Expected <literal>, found E.<Member>`. Classified mechanically from the
JUnit and the test logs, exactly one test failed in all three runs for any other reason
(`exported_const_declaration_is_checked`).

The missing requirement: **a member type is assignable to the value it holds.** The description said
a member is "assignable to its own declaration and to `number` or `string`" and that a member of
another declaration never is. Every agent read that correctly, made member types nominal, and the
nominality then blocked `E.A satisfies 1` - an assertion that appears in roughly two thirds of the
suite, including as the base-failure canary. The reference passes only because it models a member as
an alias over its constant and intercepts subtyping on the BASE side only, leaving the subtype side
to the existing eager alias unwrap. Nothing in the description pointed at that asymmetry.

This is the textbook deterministic-universal-miss signal: every fair run missing the SAME described
requirement. Per the doctrine the fix is a fairness clarification, not an easing of difficulty.

### De-trap applied (description only, no test or solution change)

1. The member sentence now reads "assignable to the value it holds, to its own declaration and to
   `number` or `string`". The nominal half is untouched: a member of another declaration is still
   never assignable, which is the trap that carries the difficulty.
2. `A declaration can be exported.` names the second shared miss. `exported_const_declaration_is_checked`
   needs the `export const enum` parse route fixed, and nothing in the description had pointed at
   exports at all.

Both are surface-naming, not rule-changing: the reference solution and all 149 tests are byte
identical before and after. meta.md stayed at 496 words.

Expected effect: the 76 shared failures turn on the first clarification, leaving each agent with the
genuinely hard remainder (empty-enum and valueless-member assignability, const-enum erasure, ambient
declarations, merging, the printing rules). Re-batch to confirm; the target is at least one pass and
no more than 40%.

## Local validation (reference solution)

| Check | Result |
| --- | --- |
| `human-effective` LOC (Counter 2) | 491 across 16 files (raw 790) |
| new tests | 193 |
| base tree + test.patch, base mode | PASS, 61 cases, 0 failures, exit 0 |
| base tree + test.patch, new mode | FAIL, 193 cases, 193 failures, exit 1 |
| solution tree, base mode | PASS, 61 cases, 0 failures |
| solution tree, new mode | PASS, 193 cases, 0 failures |
| vanilla `cargo test --workspace` on base | green (no failures) |

## In the platform image (`olympus-base-rust`, `--network none --user 1000:1000`)

| Check | Result |
| --- | --- |
| image build from the base tree | ok (5.75 GB, `cargo fetch` + `cargo build --workspace --tests`) |
| test.patch applies, `test.sh` mode | 100755 |
| base tree + test.patch, base mode | exit 0, 61 cases, 0 failures |
| base tree + test.patch, new mode | exit 1, 193 cases, 193 failures |
| + solution.patch, base mode | exit 0, 61 cases, 0 failures |
| + solution.patch, new mode | exit 0, 193 cases, 0 failures |
| reverse order (solution then test) | both modes as above |
| 3 consecutive runs of each mode | identical every run (193/0 and 61/0) |
| `git apply -R` of both patches | clean |

## Round 2 - automated review feedback (2026-08-02)

Test Fairness came back FAIL, 3 of 89 unfair, plus one coverage warning and four coverage
suggestions. All of it is addressed:

| Flag | Fix |
| --- | --- |
| `member_type_annotation_accepts_the_matching_number` pinned an unstated direction (a raw number assigned to a member type) | tsc accepts `const a: E.B = 2` and rejects `const b: E.B = 1`, so the rule is real: meta.md now states "A number is assignable to a member's own type when it is that member's value" and a new test pins the rejecting side |
| `a_reverse_entry_cannot_be_written_to` pinned an unstated read-only descriptor on reverse entries | tsc rejects `M[1] = "X"`; meta.md now reads "Neither a member nor the entry it is reachable under can be written to" |
| `member_named_with_a_keyword_like_word` fought the visible parser's reserved-identifier policy | test deleted; it covered nothing about enums |
| coverage warning: the zero rule was only checked negatively | `first_member_without_initialiser_is_zero` now asserts `E.A satisfies 0` directly, and the old negative kept as `first_member_without_initialiser_is_not_one` |
| suggestion: declaration-type printing was never tested (the test with that name checked member printing) | renamed to `member_type_prints_as_its_qualified_name`, new `declaration_type_prints_as_its_name` forces a `Direction`-typed value into a diagnostic |
| suggestion: `%`, `>>`, `>>>` and a nested expression uncovered | `folds_remainder_and_right_shifts` and `folds_a_nested_unary_and_shift_expression` |
| suggestion: merged reverse-map collision | `a_later_declaration_owns_a_shared_reverse_entry` |
| suggestion: const-enum constants | `const_declaration_folds_constant_expressions` (reference, arithmetic and a string member) |

**The coverage suggestion found a real bug in the reference solution.** `-16 >>> 28` returned 0
instead of 15: casting a negative `f64` straight to `u32` saturates to zero in Rust, so the unsigned
shift has to go through `i32` first. Fixed in
`checker/src/synthesis/statements_and_declarations.rs`; nothing else in the suite exercised an
unsigned shift of a negative value.

## Round 3 - three further coverage suggestions (2026-08-02)

Advisory only, all three added. Each was checked against tsc first:

| Suggestion | Test | Oracle |
| --- | --- | --- |
| reverse-entry deletion | `a_reverse_entry_cannot_be_deleted` | tsc rejects `delete E[1]`; the description already covers it ("neither a member nor the entry it is reachable under can be ... removed") |
| const-enum forward reference | `const_declaration_member_referencing_a_later_member_errors` | tsc rejects `const enum E { A = B, B = 1 }` (TS2651); the description limits constants to members already declared |
| narrowing a string-valued member | `comparing_a_value_to_a_string_member_narrows_it` | narrowing is stated for any member, and the reference already handled it |

No further bugs surfaced: the three behaviours were already correct, unlike the `>>>` case in round 2.

## Round 4 - four further coverage suggestions (2026-08-02)

Advisory only, all four added, each checked against tsc first and each matching it:

| Suggestion | Test | Oracle |
| --- | --- | --- |
| ambient auto-initialisation boundary | `ambient_member_after_an_explicit_value_has_no_value` | tsc accepts `declare enum E { A = 1, B }` with no initialiser error and gives `B` no value |
| valueless member object shape | `a_valueless_member_has_no_reverse_entry` | the named member stays readable and annotatable as `E.A` while no entry appears for it |
| mixed-enum broad number assignment | `mixed_declaration_with_a_numeric_member_accepts_number` | tsc accepts a broad `number` for `enum M { P = 1, Q = "two" }` and rejects `"two"` |
| exponentiation | `folds_exponentiation` | tsc folds `2 ** 3` to `8` and keeps the member literal |

All four behaviours were already correct in the reference.

## Round 5 - ordering fairness plus two suggestions (2026-08-02)

Test Fairness: FAIL, 1 of 102. `duplicate_member_keeps_the_first_value` was the only test asserting
two diagnostics, and `expect_errors` zips them, so it pinned an order nothing states. Added
`expect_errors_in_any_order`, which keeps the count and the substrings but matches them in any
order, and moved that test onto it. Every other test asserts a single error, so ordering is now
unobservable anywhere in the suite.

Both coverage suggestions added, tsc checked first:

| Suggestion | Test | Oracle |
| --- | --- | --- |
| nonconstant string-valued references | `a_reference_to_a_string_member_carries_its_value` | tsc emits `E["B"] = "x"` for `enum E { A = "x", B = A }`, so a reference carries whatever the member holds; meta.md now says exactly that, instead of folding references in with the numeric expression forms |
| const-enum omitted member after a failed initialiser | `const_declaration_member_after_a_failed_one_needs_an_initialiser` | tsc gives both TS2474 and TS1061 for `const enum E { A = f(), B }`; the reference already gave both, and the new test asserts them order-insensitively |

## Round 6 - four further coverage suggestions (2026-08-02)

Advisory only, all four added, tsc checked first and matching in every case:

| Suggestion | Test | Oracle |
| --- | --- | --- |
| cross-enum string references | `a_qualified_reference_carries_a_string_member_of_another_declaration` | tsc emits `F["C"] = "x"` for `enum F { C = E.A }` over a string member of `E` |
| ordinary nonconstant recovery | `every_member_after_a_valueless_one_needs_an_initialiser` | tsc gives TS1061 for each of `B` and `C` in `enum G { A = f(), B, C, D = 5, X }`, then `D = 5` recovers and `X` is 6 |
| ambient reverse mapping | `ambient_numeric_member_is_reachable_by_its_value` | an ambient declaration still has a value, so `E[2]` gives `"B"`; only `const enum` has none |
| constant-expression edge semantics | `folds_thirty_two_bit_shift_semantics` | tsc folds `-1 >>> 0` to 4294967295 and `1 << 33` to 2, and keeps `1 / 0` a number |

The shift cases confirm the round-2 `>>>` fix from the other direction: the unsigned shift now coerces
through 32 bits in both the negative-operand and the large-shift-count case.

## Round 7 - three further coverage suggestions (2026-08-02)

Advisory only, tsc checked first:

| Suggestion | Test | Oracle |
| --- | --- | --- |
| duplicate effects after merging | `a_duplicate_in_a_later_declaration_leaves_the_value_alone` | the rejected duplicate changes nothing: `E.A` is still 1, `E[1]` is still `"A"`, and no entry appears for 2 |
| references to valueless members | `a_reference_to_a_valueless_member_has_no_value` | tsc gives TS1061 for `C` in `enum G { A = f(), B = A, C }`, so a reference to a valueless member is itself valueless |
| const-enum string indexing boundary | `const_declaration_member_that_was_not_declared` and `const_declaration_index_by_a_computed_string_errors` | tsc separates the two: TS2339 for `K["Missing"]` (allowed syntax, absent member) and TS2476 for `K["A" + ""]` (prohibited computed access) |

The ambient half of the second suggestion was deliberately left out. tsc has an ambient-only rule
(TS1066, "In ambient enum declarations member initializer must be constant expression") for
`declare enum H { A, B = A }` that this task never claims and the reference does not implement, so a
test there would pin behaviour the description does not state.

## Round 8 - four further coverage suggestions (2026-08-02)

| Suggestion | Test | Oracle |
| --- | --- | --- |
| ambient reverse-map absence | `an_ambient_valueless_member_has_no_reverse_entry` | an initialised ambient member keeps its entry, a valueless one contributes none |
| merged valueless assignability | `a_valueless_member_in_a_later_declaration_accepts_any_number` | tsc accepts `const m: M = 404` once a later declaration adds a call-initialised member |
| constant numeric edge values | `folds_division_by_zero` | tsc accepts `const i1: I = 1 / 0` and rejects `const i2: I = 5` for `enum I { A = 1 / 0, B = 0 / 0 }`, which pins the folded Infinity exactly rather than asserting a broad `number` |
| const-enum member immutability | `const_declaration_member_cannot_be_written_to`, `..._by_string_literal`, `..._cannot_be_deleted` | tsc gives TS2540 and TS2704, the same read-only rules as an ordinary declaration |

**The fourth suggestion found a second reference bug.** Writing or deleting through an ALLOWED
const-enum access (`E.A = 5`, `E["A"] = 5`, `delete E.A`) reported `'const' enums can only be used in
property or index access expressions` instead of the read-only diagnostic: the assignment and delete
paths synthesised the object of the access with the plain expression path, so the bare-value rule
fired on a legitimate access. `synthesise_access_target` is now used at all four access-object sites
(read, write, index-write, delete), which is what the const-enum rule always meant. Fixed in
`checker/src/synthesis/{expressions, assignments}.rs`; effective LOC moved 436 -> 442.

## Round 9 - three further coverage suggestions (2026-08-02)

| Suggestion | Test | Oracle |
| --- | --- | --- |
| string-member declaration assignment | `string_member_is_assignable_to_its_own_declaration` | tsc accepts `const e: E = E.A` for a string-valued member, the positive counterpart to the rejected raw string |
| const-enum deletion via string literal | `const_declaration_member_cannot_be_deleted_by_string_literal` | tsc gives TS2704 for `delete E["A"]` |
| NaN constant result | `folds_a_not_a_number_member` | tsc accepts `const n1: N = 0 / 0` and `const n3: N = 2` while rejecting `const n2: N = 5` for `enum N { A = 0 / 0, B = 2 }` |

**The third suggestion found a third reference bug.** Member-value membership compared with plain
`==`, so a `NaN`-valued member matched nothing and `const ok: E = 0 / 0` was wrongly rejected while
the declaration still counted as literal. `holds_number` now treats `NaN` as itself, which is both
what tsc does and what this repository's own `Constant::equals` already does for numbers. Fixed in
`checker/src/features/enums.rs`; effective LOC moved 442 -> 446. The new test fails in both
directions: drop the `NaN` member and `const bad: E = 5` stops erroring; mishandle `NaN` equality and
`const ok: E = 0 / 0` starts erroring.

## Round 10 - two further coverage suggestions (2026-08-02)

| Suggestion | Test | Oracle |
| --- | --- | --- |
| other nonconstant ordinary initialisers | `a_variable_initialiser_leaves_a_member_valueless`, `a_conditional_initialiser_leaves_a_member_valueless` | tsc gives TS1061 on the successor for both `enum E { A = v, B }` and `enum G { A = v ? 1 : 2, B }`, so a call is not the only nonconstant form |
| const-enum cross-declaration references | `const_declaration_folds_a_reference_to_another_declaration`, `..._to_another_const_declaration` | tsc accepts `const enum F { B = H.A + 1, C }` over an ordinary declaration and the const-to-const form, folding to 5, 6 and 6 |

Both behaviours were already correct in the reference. The first pair also pins that a valueless
member is decided by whether the initialiser folds, not by the syntactic form of the expression.

## Round 11 - four further coverage suggestions (2026-08-02)

| Suggestion | Tests | Oracle |
| --- | --- | --- |
| additional write forms | `a_member_cannot_be_added_to`, `a_member_cannot_be_incremented`, `a_member_cannot_be_written_to_by_string_literal` | tsc gives TS2540 for `E.A += 1`, `E.A++` and `E["A"] = 5` alike |
| ordinary string-literal member access | `member_is_reachable_by_a_string_literal` | `E["A"]` on an ordinary declaration gives the member, same as dot access |
| invalid constant-expression combinations | `arithmetic_over_a_string_member_leaves_no_value` | tsc reports only TS1061 on the successor for `enum S { A = "x", B = A + 1, C }`, so arithmetic over a string member is valueless rather than folded or separately diagnosed |
| narrowing alternatives | `comparing_a_value_to_a_zero_member_narrows_it`, `comparing_a_value_to_a_negative_member_narrows_it` | narrowing keeps the exact value for `0` and `-1`, the two places an implementation is most likely to lose it |

All four were already correct in the reference. The write-form tests are the ones that would have
caught the round-8 access-routing bug in its ordinary-declaration form, so they close that gap
permanently rather than only in the const-enum path.

## Round 12 - member-type assignability plus two suggestions (2026-08-02)

Test Fairness: FAIL, 1 of 132. `const_declaration_member_that_was_not_declared` pinned the receiver
text `on typeof E` for a CONST declaration, and the description says a const enum declares no value,
so nothing states how its receiver renders. The assertion is now just `No property 'Missing'`, with a
`E["A"] satisfies 4` co-assertion so it still fails on base. The ordinary-declaration tests keep the
`typeof E` receiver, which the description does state.

Both coverage suggestions added, and the first found a fourth reference bug:

| Suggestion | Tests | Oracle |
| --- | --- | --- |
| string literal to member type | `string_literal_is_not_assignable_to_a_string_member_type`, `string_is_not_assignable_to_a_string_member_type`, `number_is_assignable_to_a_numeric_member_type` | tsc rejects `const x: E.A = "one"` and a broad `string`, while accepting a broad `number` for a numeric member type |
| const string enum assignability | `const_declaration_string_member_is_assignable_to_its_declaration`, `a_string_is_not_assignable_to_a_const_declaration`, `a_string_variable_is_not_assignable_to_a_const_declaration` | a const string member reaches its own declaration, a bare matching string and a string variable do not |

**The bug:** member types were compared structurally after the enum-declaration interception, so a
bare string literal equal to a member's value was accepted for that member's type - the very
asymmetry the declaration rule exists to prevent, one level down. `member_accepts` now applies the
same rules to a single member (numbers by value including `NaN`, a broad `number` when the member
holds one, strings never, another member never). Fixed in `checker/src/features/enums.rs` and
`checker/src/types/subtyping.rs`; effective LOC moved 446 -> 477.

One test-authoring note: `declare let n: number` trips a pre-existing lexer quirk (`n` is read as a
bigint suffix) in some positions, so the new test uses `amount`.

## Round 13 - two further coverage suggestions (2026-08-02)

| Suggestion | Tests | Oracle |
| --- | --- | --- |
| narrowing branches | `a_value_narrowed_away_from_a_member_stays_assignable_to_its_declaration`, `a_value_narrowed_away_from_a_member_is_not_that_member` | tsc accepts `const other: E = e` inside `e !== E.A` |
| merged const / ambient declarations | `two_const_declarations_merge`, `two_ambient_declarations_merge` | tsc merges `const enum` with `const enum` and `declare enum` with `declare enum` exactly as ordinary ones |

**The first suggestion found a fifth reference bug.** A value narrowed AWAY from a member
(`if (e !== E.A)`) became `Not<E.A>` and stopped being assignable to its own declaration.
`enum_accepts` and `member_accepts` now fall back to what a narrowing came FROM when the narrowed
form does not answer, which is sound because narrowing only ever shrinks: a value that was an `E` is
still an `E`. The paired negative test pins that the fallback does not over-accept - inside
`e !== E.A` the value is still rejected for the member type `E.A`. Fixed in
`checker/src/features/enums.rs`; effective LOC moved 477 -> 480.

What the excluded branch NARROWS TO is deliberately not asserted: ezno represents it as the general
`Not<...>` intrinsic (it does the same for a plain `"a" | "b"` union), which is engine behaviour this
task does not claim. meta.md now says narrowing goes "to that value" so the sentence cannot be read
as promising member-level exclusion.

## Round 14 - Infinity and NaN member values (2026-08-02)

Test Fairness: FAIL, 3 of 142 - `folds_division_by_zero`, `folds_a_not_a_number_member` and
`folds_thirty_two_bit_shift_semantics`, on the grounds that TypeScript rejects enum constant
expressions evaluating to Infinity or NaN while the description does not state the divergence.

Checked against tsc 5.6.3. The rejection is a CONST-enum rule only:

| Source | tsc |
| --- | --- |
| `enum A { X = 1 / 0, Y = 0 / 0 }` | no diagnostic; `const a: A = 1 / 0` is accepted and `const a: A = 5` is rejected |
| `const enum B { X = 1 / 0 }` | TS2477, non-finite |
| `const enum C { Y = 0 / 0 }` | TS2478, disallowed NaN |

All three tests use ORDINARY declarations, so the assertions match tsc. What was missing is that
the description never said so, which is the fairness point that matters: meta.md now states
"Infinities and `NaN` are ordinary member values". `folds_thirty_two_bit_shift_semantics` also had
its `1 / 0` member removed so the shift assertions stand on their own, since the Infinity case is
already covered by its own test.

Deliberate scope boundary, recorded like the TS1066 ambient rule: the const-enum non-finite and NaN
rejections (TS2477 / TS2478) are NOT implemented and NOT claimed by the description. The reference
accepts them silently, which is self-consistent with what the description does say.

## Round 15 - three further coverage suggestions (2026-08-02)

| Suggestion | Tests | Oracle |
| --- | --- | --- |
| special-number reverse mappings | `reverse_entries_of_special_numbers` | tsc emits `E[E["A"] = Infinity] = "A"`, so infinities and NaN are reachable by their value like any other number |
| implicit continuation after special numbers | `counting_up_from_an_infinite_value_stays_infinite`, `counting_up_from_a_not_a_number_value_stays_not_a_number` | tsc gives `F[F["B"] = Infinity]` and `G[G["B"] = NaN]`, so counting continues rather than demanding an initialiser |
| merged-declaration initialiser references | `a_later_declaration_can_reference_an_earlier_member` | tsc folds both `M.A + 1` and the unqualified `A + 2` to 2 and 3 across merged declarations |

All three were already correct. The continuation pair pins the value through the reverse entry
rather than a weak `satisfies number`: both members hold the same special value, so the documented
later-owner rule makes `E[1 / 0]` resolve to `"B"` only if the implicit member really carried
Infinity (or NaN) forward.

## Round 16 - two further coverage suggestions (2026-08-02)

| Suggestion | Tests | Result |
| --- | --- | --- |
| valueless member type assignment | `a_valueless_member_type_holds_no_number` | already correct: `E` accepts any number while `E.A` accepts neither a literal nor a broad `number`, because that member holds none |
| non-numeric member-type rejection | `boolean_is_not_assignable_to_a_member_type`, `undefined_is_not_assignable_to_a_member_type` | already correct |

Third deliberate divergence from tsc, recorded like TS1066 and the const-enum non-finite rules:
tsc ACCEPTS `const y: E.A = 5` when `A` is computed, because an enum with a computed member is not a
literal enum in its model and `E.A` collapses to `E`. This task keeps member types nominal in every
case and the description says a number reaches a member's own type "when that member holds it", so a
valueless member's type accepts nothing numeric. The suggestion reads the description the same way.
The general framing sentence stays "the way TypeScript does"; the specific stated rules are the
contract where the two differ, and all three divergences are behaviours tsc models through a
type-collapse this task never claims.

## Round 17 - runner fix, description trim, two suggestions (2026-08-03)

**Test-patch sanity check (warning, fixed).** `run_new_suite` synthesised JUnit failures when the new
target produced no test cases but left `STATUS` at 0, so a build or feature-gate failure could report
failures in the XML while exiting successfully. It now sets `STATUS=1` alongside the synthesis. The
base-mode path already exited non-zero on a failing suite.

**Description quality (one HIGH, fixed).** The opening sentence described what the checker does today
and has been replaced with the ask itself: "Check `enum` declarations the way TypeScript does."
meta.md is now 470 words.

The four MEDIUM / LOW suggestions were deliberately NOT applied, because each one is load bearing for
a gate that outranks a style warning:

| Suggestion | Why it stays |
| --- | --- |
| drop the read-only and delete diagnostic strings | they are NOT pre-existing conventions. A previous Test Fairness run grepped for them and found none, and flagged `a_reverse_entry_cannot_be_written_to` as unfair precisely because the wording was unstated. Removing them re-breaks that gate |
| drop the printing sentence | same history: the `typeof E` receiver was flagged unfair while unstated, and three tests pin `E`, `E.A` and `typeof E` |
| drop "the `number` type itself goes wherever ..." | not redundant. The other sentences cover a number LITERAL; this one covers the broad `number` type, which four tests separate from the literal case |
| drop "A declaration can be exported" | added one round ago to de-trap a 3-of-3 universal miss on `exported_const_declaration_is_checked`. Solvability outranks a LOW style note |

**Coverage suggestions, both added and both already correct:**

| Suggestion | Test | Oracle |
| --- | --- | --- |
| const-enum numeric type relations | `const_declaration_accepts_numbers_like_an_ordinary_one` | tsc accepts a matching literal and a broad `number` for both `C` and `C.A`, and rejects a number no member holds |
| ambient member type annotation | `ambient_member_type_annotation` | tsc accepts `E.A` for itself and rejects `E.B`, so ambient declarations take part in nominal member typing |

## Round 18 - two further coverage suggestions (2026-08-03)

| Suggestion | Tests | Oracle |
| --- | --- | --- |
| const-enum nonconstant expression forms | `const_declaration_member_from_a_variable_errors`, `const_declaration_member_from_a_conditional_errors` | tsc gives TS2474 for `const enum E { A = v }` and `{ A = v ? 1 : 2 }`, so the const-expression rule covers every non-folding form, not just calls and forward references |
| read-only reverse-entry update forms | `a_reverse_entry_cannot_be_added_to`, `a_reverse_entry_cannot_be_incremented` | tsc rejects `E[1] += 1` and `E[1]++` as writes to a read-only index |

Both were already correct. On `E[1]++` tsc also emits a second diagnostic (TS2356, arithmetic operand
on a string-typed reverse entry); the tests pin only the read-only error, which is the rule this task
states, and not that extra check.

## Round 19 - four suggestions and an FP sweep (2026-08-03)

| Suggestion | Tests | Oracle |
| --- | --- | --- |
| cross-module exports | `an_imported_declaration_keeps_its_member_values`, `..._counted_up_values` | an imported declaration keeps its member values, so `const bad: Colour = 5` still errors across a module boundary. Only the TYPE side is asserted: value imports are broken for everything in this checker, not just enums (`export const v = 3` then `v satisfies 3` gives `found any` on the base tree) |
| additional rejected source types | `null_and_objects_are_not_assignable`, `..._to_a_member_type` | tsc rejects `null`, an object type and a function type for both `E` and `E.A` |
| readonly write syntax | `a_member_cannot_be_incremented_before_it_is_read`, `a_member_cannot_be_decremented`, `..._before_it_is_read`, `a_reverse_entry_cannot_be_decremented` | tsc gives the read-only error for `++E.A`, `E.A--`, `--E.A` and `E[1]--` |
| merged exported / ambient interactions | `two_exported_declarations_merge`, `an_ambient_declaration_merges_with_an_ordinary_one`, `a_const_declaration_does_not_merge_with_an_ordinary_one`, `an_ordinary_declaration_does_not_merge_with_a_const_one` | tsc merges exported with exported and ambient with ordinary, but gives TS2567 when `const` is mixed with an ordinary declaration |

**The fourth suggestion found a sixth reference bug.** Mixing `enum E` with `const enum E` merged
silently, producing a half-const declaration: one fragment claims a value, the other claims none.
tsc rejects it (TS2567) while still allowing ambient plus ordinary. Added
`TypeCheckError::EnumDeclarationKindMismatch` with the message now stated in meta.md, keyed only on
`is_constant` so the ambient combination keeps merging. Effective LOC moved 480 -> 491.

### False-positive sweep

Every sentence of meta.md was walked against the suite in both directions, and the wrong
implementations each rule exists to exclude were listed and matched to the test that kills them:

| Wrong implementation | Killed by |
| --- | --- |
| union of constants, no nominality | `member_of_another_declaration_is_not_assignable` |
| fully opaque members | `matching_number_literal_is_assignable`, every `E.A satisfies` |
| no value object | reverse-entry and member-access tests |
| const enum treated as ordinary | `const_declaration_has_no_reverse_entry`, `..._cannot_be_used_as_a_value` |
| no merging, or merging with a shared counter | `a_later_declaration_adds_members`, `..._counts_from_zero` |
| read-only enforced only for `=` on a dot access | the `+=`, `++`, `--`, prefix and index forms |
| reverse entries for string members | `string_member_has_no_reverse_entry` |
| `E.A` annotations resolving to an error type | `member_type_annotation_rejects_another_member` |
| members printed as their value | `member_type_prints_as_its_qualified_name` |
| right errors plus extra ones | every `expect_errors` pins an exact count and every `assert_clean` requires zero |

All eight invented diagnostic messages are both stated in meta.md and pinned by at least one test.

## Round 20 - three suggestions, two added (2026-08-03)

| Suggestion | Tests | Oracle |
| --- | --- | --- |
| invalid member references | `a_reference_to_a_member_that_does_not_exist_has_no_value`, `const_declaration_member_referencing_a_missing_member_errors` | tsc gives TS1061 on the successor and TS2474 for the const form, which is what the description's "anything else leaves it without a value" produces |
| ambient string members | `ambient_string_member_holds_its_value`, `..._has_no_reverse_entry`, `a_string_is_not_assignable_to_an_ambient_declaration` | an initialised ambient string member holds its value, reaches `string` and its own declaration, has no reverse entry, and a bare matching string is still rejected |

**Imported enum value object: not added, with evidence.** The value side of module imports does not
work in this checker for anything. `export const thing = 3` imported into another module reports
`thing not exported from ./lib.ts` and `thing satisfies 3` gives `found any` - on the base tree, with
no enum involved. Asserting `Colour.Red` through an import would therefore pin an unrelated
pre-existing gap rather than this feature. The type side IS covered, by the two round-19 tests.

One tsc difference recorded for the first suggestion: tsc ALSO reports "Property 'Missing' does not
exist" for `E.Missing`. This task never claims a diagnostic for a bad qualified reference; the
description puts it under "anything else", so the member is valueless and the successor takes the
initialiser error. Both tests assert exactly that.

## Round 21 - two tests audited against the description (2026-08-03)

Both were questioned directly and both were defective as written. The behaviours are right and worth
testing, so the description was fixed rather than the tests dropped.

**`empty_declaration_stands_for_numbers`** asserts a broad `number` reaches an EMPTY declaration.
Two description sentences disagreed: "any number when a member has no value or it is empty" allowed
it, while "The `number` type itself goes wherever the declaration or the member holds a number"
denied it, because an empty declaration holds none. An implementer could have read either. The
second sentence now reads "goes to a declaration holding a numeric member or holding none, and to a
member type holding a number", which matches tsc (`enum F {}` accepts a `number` variable) and no
longer contradicts the first. The test's variable was also renamed off `n`, which lexes as a bigint
suffix in some positions.

**`a_value_narrowed_away_from_a_member_stays_assignable_to_its_declaration`** asserts that a value
narrowed by `e !== E.A` is still assignable to `E`. The description only described the positive
branch ("narrows it to that value") and said nothing about what the other branch leaves behind. It
is a general type-system invariant, but it is NOT free here: the enum interception sits in front of
subtyping, so a natural implementation produces `Not<E.A>` and rejects it - which is exactly the bug
the reference had in round 13. Unstated plus not free is the unfair combination, so the narrowing
sentence now ends "and narrowing never loses the declaration type". Its paired negative test
(a narrowed value is still not the OTHER member) is unaffected and keeps the rule honest.

meta.md is 499 words. No test or solution change beyond the variable rename; all 172 still fail on
base and pass with the solution.

## Round 22 - three suggestions (2026-08-03)

| Suggestion | Tests | Oracle |
| --- | --- | --- |
| imported const enums | `an_imported_const_declaration_keeps_its_member_values` | an imported const declaration keeps its member values across the boundary, counted-up member included |
| invalid ordinary initialisers | `an_object_initialiser_leaves_a_member_valueless`, `a_logical_initialiser_leaves_a_member_valueless` | tsc gives TS1061 on the successor for `enum E { A = {}, B }` and `enum G { A = a \|\| b, B }` |
| const merge numbering | `two_const_declarations_count_from_zero_in_each` | tsc inlines `H.B` to 0 after `const enum H { A = 5 }` and `const enum H { B }`, the same restart as ordinary merges |

Two parts of the first suggestion could not be tested, for the reason already recorded in round 20:
accessing `Size.S` through the import and rejecting the imported declaration as a runtime value both
need the value side of imports, which does not work in this checker for anything (`export const thing
= 3` reports `thing not exported`). The type side is what the tests assert.

The bigint form named in the second suggestion is also untestable: `enum E { A = 1n }` fails to parse
on the base tree (`Expected ;, found n`), a pre-existing lexer gap unrelated to enums. An object
literal and a logical expression cover the same rule.

## Round 23 - three suggestions, two added (2026-08-03)

| Suggestion | Tests | Oracle |
| --- | --- | --- |
| read-only beyond ordinary and const | `an_ambient_member_cannot_be_written_to`, `an_exported_member_cannot_be_deleted` | tsc gives TS2540 and TS2704 through the ambient and exported modifiers too |
| duplicate handling in other kinds | `const_declaration_duplicate_member_keeps_the_first_value`, `ambient_duplicate_member_keeps_the_first_value` | tsc reports the duplicate in const and ambient declarations, and the first member keeps its value in both |

**Imported value-side behaviour: still not testable, now confirmed three ways.** Named imports fail
with and without the file extension (`thing not exported from ./lib.ts` and `... from ./lib` for a
plain `export const thing = 3`), and a namespace import (`import * as lib`) crashes the checker
before producing diagnostics. None of this involves enums. The import tests therefore stay on the
type side, which is where an imported declaration's member values are observable.

## Round 24 - four suggestions, three added (2026-08-03)

| Suggestion | Tests | Result |
| --- | --- | --- |
| cyclic constant references | `a_cyclic_reference_leaves_members_valueless`, `a_cyclic_reference_across_declarations_leaves_members_valueless` | no recursion, no panic, exit 0: `enum E { A = B, B = A, C }` leaves both valueless and only the successor takes the initialiser error, and the cross-declaration cycle `F.X = G.Y` / `G.Y = F.X` resolves to valueless on both sides |
| block scope boundary | `a_declaration_does_not_escape_its_block` | after the block the name is gone from both namespaces, matching tsc's "Cannot find name" |
| merged const restrictions | `merged_const_declarations_keep_their_restrictions` | after merging, string-literal member access still works and the bare value use is still rejected |

tsc additionally reports TS2651 and TS2450 for the cyclic cases. This task claims no diagnostic for a
reference that is not to an already-declared member; the description puts it under "anything else",
so the member is valueless and the successor takes the initialiser error, which is what the tests
assert.

**Imported enum value object: declined for the fourth time, on the evidence gathered in round 23** -
named imports fail with and without the extension and a namespace import crashes the checker, all on
a plain `export const thing = 3` with no enum involved. Nothing about that is specific to this
feature, and a test there would pin a broken unrelated path.

## Round 25 - one suggestion added (2026-08-03)

`string_member_is_assignable_to_its_own_member_type` completes the string member-type triangle:
`E.A` reaches `E.A` (clean), `E.B` does not, and a raw `"x"` does not. tsc agrees on all three.

The imported member and value surface was requested for a fifth time and is declined on the same
evidence: three import forms were probed in round 23 and every one fails or crashes on a plain
`export const thing = 3` with no enum present. Nothing further to gather.

## Round 26 - shift semantics dropped, two suggestions added (2026-08-03)

Test Fairness: FAIL, 1 of 185 - `folds_thirty_two_bit_shift_semantics`, which pinned
`-1 >>> 0 == 4294967295` and `1 << 33 == 2`. Verified against the repository: its own reusable
constant operator evaluator at `checker/src/features/operations/mathematical_bitwise.rs:71-83` uses
`checked_shl(..).unwrap_or(0)` and an ARITHMETIC `(lhs as i32).wrapping_shr(..)`, so reusing it -
the natural move for a solver - gives 0 and -1 for those two expressions. The repository actively
points away from the JavaScript answer and the description never singled these edges out.

Fix: the test is deleted and `folds_remainder_and_right_shifts` dropped its `-16 >>> 28` member,
which is the same class. What remains (`%`, `>>`, `<<` by a small count, `&`, `|`, `^`, `~`, unary,
parentheses, `**`, division by zero, NaN) evaluates identically under the repository's evaluator and
under JavaScript, so nothing left in the suite depends on which one a solver reuses. The reference
still folds these the TypeScript way; the contract simply no longer pins the two divergent edges.

| Suggestion | Tests | Oracle |
| --- | --- | --- |
| reverse-entry read-only after merging | `a_reverse_entry_from_a_later_declaration_cannot_be_written_to`, `..._cannot_be_deleted` | tsc rejects `E[2] = "X"` and `delete E[2]` for an entry contributed by the second declaration |
| narrowing with duplicate numeric values | `comparing_a_value_to_one_of_two_members_sharing_a_value_narrows_it` | narrowing against either member of a value-sharing pair keeps the shared value, while the later member still owns the reverse entry |

Imported const-enum value restrictions was the sixth request for the value side of imports and is
declined on the round-23 evidence.

## Round 27 - two suggestions added (2026-08-03)

| Suggestion | Tests | Oracle |
| --- | --- | --- |
| unsigned right shift | `folds_unsigned_right_shift` | `16 >>> 2` is 4 and `40 >>> 3` is 5 under tsc, under JavaScript AND under the repository's own evaluator, because the operands are not negative and the counts are under 32. That is the fair subset of `>>>`: round 26 removed only the negative-operand and over-32 cases, where the repository's `checked_shl` and arithmetic `wrapping_shr` diverge from JavaScript |
| merged ambient implicit members | `a_member_of_a_later_ambient_declaration_has_no_value` | tsc accepts `declare enum E { A = 1 }` then `declare enum E { B }` with no initialiser diagnostic, and `B` carries no value rather than continuing the earlier fragment's count |

Imported member access was the seventh request for the value side of imports; declined on the
round-23 evidence.

## Round 28 - three suggestions, all three added (2026-08-03)

| Suggestion | Test | Oracle |
| --- | --- | --- |
| broad number to a valueless non-empty enum | `a_declaration_with_a_valueless_member_accepts_the_number_type` | tsc accepts a `number` VARIABLE, not just a literal, for `enum E { A = f(), B = 2 }`, which is what the description's `number`-type sentence says |
| imported member annotation | `an_imported_member_type_can_be_named` | `Colour.Red` names the member type across the module boundary: `= 1` is clean and `= 2` is `Type 2 is not assignable to type Colour.Red` |
| const enum cyclic initialiser | `const_declaration_with_a_cyclic_reference_errors` | tsc reports one diagnostic for `const enum E { A = B, B = A }` and so does the reference: the first member fails to fold, the second resolves to the first's absent value |

**Part of the import suggestion is testable after all.** Seven earlier rounds asked for the value
side (`Colour.Red` as an expression, reverse entries through the import), which stays blocked by the
checker's broken value imports. This round asked additionally for an imported MEMBER ANNOTATION, and
that path works: member-type metadata does cross the boundary, discriminated by the rejecting case
rather than a clean one, so the test cannot pass by falling back to an error type. The value half is
still declined on the round-23 evidence.

## Round 29 - cascade pin removed, two suggestions added (2026-08-03)

Test Fairness: FAIL, 1 of 192 - `const_declaration_with_a_cyclic_reference_errors`, added one round
earlier from a suggestion. It pinned exactly one diagnostic for `const enum E { A = B, B = A }`. The
count is an artifact of how the reference folds (the first member fails, the second resolves to the
first's absent value); the per-member rule makes both non-constant, so another implementation could
report two. Nothing states a cycle-deduplication policy, so the test is deleted rather than the
policy invented. The non-constant rule stays covered by the call, forward-reference, variable,
conditional and missing-member cases, and the ordinary-enum cyclic tests still prove no recursion or
panic.

| Suggestion | Tests | Oracle |
| --- | --- | --- |
| ambient const enums | `ambient_const_declaration_index_access_errors`, `..._cannot_be_used_as_a_value`, `..._member_cannot_be_written_to`, `..._member_from_a_call_errors`, `an_ambient_const_declaration_does_not_merge_with_an_ordinary_one` | every const restriction survives the ambient modifier, and tsc agrees on all five |
| string narrowing preservation | `a_narrowed_string_value_stays_assignable_to_its_declaration` | a string member equality-narrowed value is still assignable to its declaration |

Imported value surface was the eighth request for the value side and is declined on the round-23
evidence. Its annotation half was added in round 28.

## Round 30 - initialiser checking stated (2026-08-03)

Test Fairness: FAIL, 2 of 197 - `a_reference_to_a_member_that_does_not_exist_has_no_value` and
`const_declaration_member_referencing_a_missing_member_errors`. Both pin an exact count around
`E.Missing` inside an initialiser, which forbids the repository's ordinary missing-property
diagnostic (`checker/src/features/variables.rs:177-186`). The reference never produces it because it
only FOLDS an initialiser, but nothing said so.

The fix is one sentence rather than two deletions, because the same gap reaches further than the two
flagged tests: `a_reference_to_a_later_member_is_not_constant` would take `Could not find variable
'B'`, and the object, logical and conditional initialisers would each take whatever their expression
check produces. meta.md now says:

> An initialiser is only read for its value, never checked as an ordinary expression.

That is a real part of the contract, not a patch for the count: it tells an implementer not to route
initialisers through normal expression synthesis, which is what makes the whole valueless family
behave consistently. Batch 1 confirms the ambiguity was live - the agents that synthesised the
expression reported exactly these extra diagnostics.

meta.md is 498 words. No test or solution change.

Both coverage suggestions are the value side of imports again, the ninth and tenth request, declined
on the round-23 evidence. Their annotation half is covered by `an_imported_member_type_can_be_named`.

## Round 31 - one suggestion added, two declined (2026-08-03)

**Constant-expression coercion boundaries: the fair half added.**
`folds_negative_operands_of_bitwise_operators` pins `-8 & 5`, `-1 | 0`, `-5 ^ 3`, `-3 << 2` and
`~(-1)` at 0, -1, -8, -12 and 0. tsc emits exactly those, and so does the repository's own evaluator,
because `(lhs as i32) op (rhs as i32)` IS the ToInt32 semantics for negative operands and
`checked_shl` only diverges once the COUNT reaches 32.

The other half of that suggestion - negative or large operands of `>>>` and large shift counts for
`<<` - is deliberately not added. Round 26 FAILED Test Fairness for pinning exactly those, because
`checked_shl(..).unwrap_or(0)` and the arithmetic `wrapping_shr` at
`checker/src/features/operations/mathematical_bitwise.rs:71-83` give 0 and -1 where JavaScript gives
2 and 4294967295. Re-adding them would restore a confirmed fairness failure, and a coverage
suggestion is advisory where fairness is a gate.

**Merge recovery after incompatible kinds: declined.** Which members survive a rejected
const-versus-ordinary merge is error-recovery behaviour the description does not state, and pinning
it is the same mistake as the cycle-count test that failed fairness in round 29. The stated part -
that the mismatch is diagnosed - is already covered three ways.

**Imported enum value side: declined**, eleventh request, on the round-23 evidence.

## Round 32 - two const forms added, cyclic and imports declined (2026-08-03)

`const_declaration_member_from_an_object_errors` and
`const_declaration_member_from_a_logical_expression_errors` bring the const-enum non-constant list
level with the ordinary-enum one. tsc gives TS2474 for both.

The cyclic case in the same suggestion is deliberately still absent. It was added in round 28 from a
suggestion and FAILED Test Fairness in round 29: `const enum E { A = B, B = A }` produces one
diagnostic in the reference because the second member resolves to the first's absent value, while the
per-member rule makes both non-constant, so the count pins an unstated deduplication policy. The
round-30 clarification about initialisers not being checked as expressions does not touch that
objection.

Imported value-side behaviour: twelfth request, declined on the round-23 evidence.

## Round 33 - merged ambient reverse entries added (2026-08-03)

`a_merged_ambient_member_has_a_reverse_entry` and
`a_member_merged_onto_an_ambient_declaration_has_a_reverse_entry` cover both orders: an ordinary
declaration extended by a `declare enum` fragment, and an ambient declaration extended by an ordinary
one. In both the numeric members from either fragment are reachable by their value. tsc accepts the
same lookups.

Imported runtime enum value: thirteenth request for the value side of imports, declined on the
round-23 evidence.

## Round 34 - the suppression rule gets its own test (2026-08-03)

`an_undeclared_identifier_initialiser_leaves_a_member_valueless` is the direct test for the sentence
added in round 30. `enum E { A = notDeclared, B }` produces exactly the initialiser error for `B` and
the failed `satisfies` for `A`, and no `Could not find variable` diagnostic. Until now the rule was
only exercised indirectly through `E.Missing` and forward references; this pins it on the plainest
case. It is a deliberate, stated divergence from tsc, which reports "Cannot find name".

The other two suggestions need the value side of imports. I re-probed rather than repeating the
answer, because round 28 showed part of an import suggestion CAN be testable: writing and deleting
through an imported member both report `Could not find variable 'Colour' in scope`, so the readonly
contract cannot be observed across a module boundary either. Fourteenth request for the value side;
declined.

## Batch 2 (2026-08-03, Orion run, 203 tests) and the de-pin that followed

| Batch | Agent | Verdict | Baseline | New | Failed | Cause |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | Orion #1 | FAIL_MISSED_REQUIREMENT | pass (61) | 190/203 | 13 | four clusters, three of them wording this task never fixed |

A huge move from batch 1 (0/3 at ~72/149): the round-30 clarification worked, and the agent now
implements essentially the whole feature. The 13 failures classify cleanly:

| Cluster | Tests | What the agent produced | Verdict |
| --- | --- | --- | --- |
| compound and update writes | 5 | `Cannot E.A Add 1` instead of the read-only message | MY PIN. The description gives the read-only message for a write, but never says every mutation syntax must report THAT message rather than an operation-specific one |
| reverse-entry write key | 5 | `Cannot assign to 'A'` where the tests wanted `'1'` | MY PIN. The description's one example uses a member name and never says a numeric entry reports its own key |
| negative narrowing | 1 | `Not<E.A>` rejected as `E` | FAIR - "narrowing never loses the declaration type" is stated |
| `export const enum` | 2 | `const declaration requires value` | dropped: a parser bug now missed by 4 of 4 agents |

Changes, tests only, no solution or description change:

1. The ten compound, update and reverse-entry write tests now use a new `expect_error_count` helper:
   they require the write to be REJECTED, and no longer pin wording the description does not fix per
   syntax. The plain `E.A = 2` form still pins the stated message.
2. `exported_const_declaration_is_checked` and `an_imported_const_declaration_keeps_its_member_values`
   deleted. Plain `export enum` stays covered five ways.
3. `++E.A` and `--E.A` deleted: on the base tree they are a PARSE error ("Invalid syntax on LHS of
   assignment"), so a count-only assertion cannot separate base from solution, and pinning wording
   there would just restore cluster 1. Six other mutation forms remain.
4. Every count-only test carries two canaries (`E[1] satisfies "A"` and `E.B satisfies 2`) so the base
   tree, which allows the write, lands on a different count. Verified: 0 of 199 pass on base.

**Replayed the agent's actual patch against the revised suite: 198 of 199 pass.** The single
remaining failure is the stated narrowing property. That is the differential-harness check - the
change was measured against the real solution rather than guessed.

## Round 35 - stronger write tests without re-pinning wording (2026-08-03)

**Read-only update diagnostics.** The suggestion asks to put the read-only substring back on the
compound and update tests. Re-adding it would undo the batch-2 fix directly: those exact ten
assertions are why the Orion run lost 10 tests, because it reports `Cannot E.A Add 1` for a compound
write, which the description does not forbid.

The concern behind the suggestion is real though - a count-only test could in principle be satisfied
by an unrelated error. So the tests now do something stronger than either version:
`expect_write_rejected(setup, write)` asserts the setup WITHOUT the write is completely clean, then
that adding the write contributes exactly one error. The single error is therefore attributable to
the write itself, with no wording pinned. The plain `E.A = 2` form still pins the stated message.

**Unsupported numeric-like initialiser.** `enum E { A = 1n, B }` is a PARSE error on this repository
with the solution applied as well (`Expected ;, found n`), so parsing never reaches the member and
the suggested consequence - the following member requiring an initialiser - cannot be observed. A
test there would pin a parser gap unrelated to enums. The same rule is covered by object, logical,
conditional, variable, undeclared identifier, call, missing member and forward reference.

**Imported enum value surface**: fifteenth request, declined on the round-23 evidence.

Solvability re-measured after the change: the batch-2 Orion patch scores 198 of 199 against the
revised suite, the same as before, so the strengthening cost nothing.

## Round 36 - the false positive the relaxation opened, closed (2026-08-03)

Relaxing the write tests to a count in round 35 opened a hole the reviewer's version would not have
had, and it is not the hole the reviewer named. A write can be rejected for TYPE reasons rather than
read-only ones:

| Write | An implementation that never made members read-only |
| --- | --- |
| `E[1] = "C"` | the entry holds `"A"`, so `"C"` is rejected as a type error - one error, test PASSES, false positive |
| `E.A += 1` | the result widens to `number`, which a nominal member property can reject - false positive |
| `E[1]++` | arithmetic on a string entry is a type error whatever the readonly policy - false positive |

Two fixes:

1. **Write the value the property already holds.** `E.A = 1`, `E["A"] = 1`, `E[1] = "A"`,
   `E[2] = "B"`, and the const / ambient variants likewise. A writable implementation accepts these
   silently, so the only thing that can produce an error is the read-only rule. Applied to the
   message-pinned tests too, where the risk was smaller but real.
2. **Deleted the six compound and update tests.** An update on a nominal or literal-typed property
   can always be rejected on type grounds, so no assertion over `+=`, `++` or `--` can separate a
   read-only implementation from a merely type-strict one. They are unfixable as discriminators
   rather than merely weak. The rule keeps four write forms and six delete forms, all of which a
   writable implementation would accept silently.

Suite is 193 tests. Re-measured after the change: 193 of 193 pass with the reference, 0 of 193 on
base, and the batch-2 Orion patch scores 192 of 193, still failing only the stated narrowing
property.

## Oracle conformance (tsc 5.6.3, `--noEmit --strict`)

Every pinned behaviour was derived by running the same source through `tsc` and through the built
`ezno check`. The probe files live outside the submission. Known remaining divergences, all of them
pre-existing ezno gaps that are NOT exercised by the new tests:

| Source | tsc | ezno | Note |
| --- | --- | --- | --- |
| `const n: 1 \| 2 = e` where `e: E` | accepts | rejects | reproduces with a plain `type Alias = 1 \| 2`, so it is the alias-to-union gap, not enums |
| `E.A as E` | accepts | rejects | ezno's cast path, unrelated to enums |
| `E[3]` where no member holds 3 | accepts (numeric index signature) | reports the missing entry | ezno has no index signature on the value; stated in the description |
| `keyof typeof E` | `"A" \| "B"` | unsupported | `keyof` over a value is unsupported in ezno generally |
| `E.A === E.B` | reports no overlap | no diagnostic | ezno has no comparison-overlap check |
