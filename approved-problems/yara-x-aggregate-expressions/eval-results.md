# eval-results.md — yara-x-aggregate-expressions

## Local validation (host, not yet in the image)

| Check | Command | Result |
|---|---|---|
| Env quality, vanilla base | `cargo test --workspace` on BASE_COMMIT | 21 result groups, 0 failures |
| Env quality, workspace build | `cargo test --workspace --no-run` | builds every member |
| F2P probe on base | `yara_x::compile("rule t { condition: for count i in (0..4) : ( i > 1 ) > 1 }")` | `error[E001]: syntax error` |
| Base suite with solution | `./test.sh --output_path base.xml base` | 364 tests, 0 failures, exit 0 |
| New suite with solution | `./test.sh --output_path new.xml new` | 81 tests, 0 failures, exit 0 |
| Patches apply on base | `git apply --check` both, on a fresh BASE_COMMIT checkout | clean |

## 4-cell (host, fresh checkout at BASE_COMMIT)

| Cell | Result |
|---|---|
| BASE + base mode | 364 tests, 0 failures, exit 0 |
| BASE + new mode (test.patch only) | 81 tests, **81 failures**, exit 101 |
| SOLUTION + base mode | 364 tests, 0 failures, exit 0 |
| SOLUTION + new mode | 81 tests, 0 failures, exit 0 |

Every one of the 81 tests is fail-to-pass. See the platform Verify Solution round below for why
the three former regression guards had to be converted.

| Extra check | Command | Result |
|---|---|---|
| Effective LOC | `.claude/hooks/effective_loc_check.py solution.patch` | human-effective 762 (floor 430) |
| Patch encoding | `file solution.patch test.patch` | ASCII text, LF |
| test.sh mode | `grep "new file mode 100755" test.patch` | present |
| meta.md | `wc -w`, `file` | 264 words, ASCII |

## Per-file effective LOC (hook)

Measured after hardening round 2; `git diff --stat` reports 1100 insertions and 154 deletions
across the same 11 files in 2 crates. The hook's total is 713 human-effective.

## Regressions caught and fixed during implementation

| Symptom | Root cause | Fix |
|---|---|---|
| `compiler::ir::tests::ir` goldenfile `5.ir`, every hash changed | `Expr`'s `Hash` uses `discriminant`; a new variant shifted `Lookup` | move `ForAgg` to the end of the enum |
| `compiler::tests::test_errors` goldenfile `errors/89.out` | extracting the comparison chain relabelled its expected-token description | restore the original `Some("expression")` |
| every aggregate reported `E001: syntax error` when compared | `for_expr` won the boolean-term alternation and left the comparison behind | route aggregates through the comparison chain and add them to `term` |

## Flakiness

Both modes run 3x with identical results: new = 81/0 three times, base = 364/0 three times. No
timing, network, ordering or parallelism dependence in the blast radius, and the new tests run with
`--test-threads=1`.

## AI pre-check round 1 (2026-07-28)

Three checks, all WARNING, all addressed:

| Check | Finding | Fix |
|---|---|---|
| Tests cover required behavior | no test for the stated integer overflow wrapping | added `integer_results_wrap_on_overflow` |
| Tests cover required behavior | `NEW_TEST_NAMES` in test.sh omitted `wrong_number_of_loop_variables` | list now holds all 26 names |
| Description contains only necessary information (HIGH) | the "existing `for`/`of` keep working" paragraph is an obvious default | removed; the two regression tests stay as baseline guards |
| Description contains only necessary information (MEDIUM x2, LOW x2) | usage enumeration, iterable-binding examples, the `for any` analogy, the `+` reference | all trimmed; every rule they carried is still stated |
| Problem and tests are aligned | tests pinned the error substrings "wrong type" and "assignment mismatch", which the description does not state | rejection tests now assert only that compilation fails, per the no-substring-pins rule |

Relaxing the two rejection tests would have made them pass vacuously on base, where the aggregate
is a syntax error and compilation fails for the wrong reason. Each of them now opens with a valid
aggregate as a canary, so both still fail on base. F2P went from 22/25 to 23/26.

## AI pre-check round 2 (2026-07-28)

| Check | Finding | Fix |
|---|---|---|
| Tests cover required behavior | no negative test for a non-boolean `count` body, which the description demanded | the description was wrong, not the tests: see below |
| Description contains only necessary information (HIGH) | "The iterables are the ones the `for` family already accepts, and they bind loop variables the same way," restates existing `for` semantics | removed; the loop-variable rejection rule kept as its own sentence so `wrong_number_of_loop_variables` stays documented |
| Description contains only necessary information (MEDIUM x2) | "An aggregate produces a number rather than a truth value", and the `math.min`/`math.max`/`math.count` examples | both removed; the naming rule itself is kept |
| Description contains only necessary information (MEDIUM) | the `for sum i in (0..3) : ( i * 2 )` example | KEPT on purpose, see below |

**The `count` body claim was false.** Probing base showed `for any i in (1..3) : ( i )` and
`for any i in (1..3) : ( "abc" )` both compile: yara-x applies YARA truthiness to loop bodies and
does not require a boolean. The description's "`count` takes a boolean body" promised a rejection
that neither the reference nor the repo's own `for` performs, which is an FP waiting to happen.
Making `count` stricter than `for any` in the same engine would contradict the repo's own
semantics, so the description was corrected instead, and a test now pins the real behavior.

**The syntax example was kept** against the MEDIUM suggestion. The construct is invented, so the
exact spelling is the rule itself rather than a restatement of something discoverable in the
codebase; removing the only concrete form would leave solvers guessing at where the operation word
goes.

## Coverage advisories (3, all added)

| Advisory | Test | Verified behavior |
|---|---|---|
| count body type errors | `count_body_judged_like_any_loop_body` | `for count i in (0..3) : ( i ) == 3` — 0 is falsy, 1..3 truthy; a malformed body is still rejected |
| truly empty iteration | `empty_iteration_per_operation` | a runtime-empty range `(1..#z)` where `#z` is 0: count and sum are 0, min and max are undefined |
| contextual rule names | `rules_can_be_named_after_an_aggregate` | extended from `sum`/`min` to all four of `count`, `sum`, `min`, `max` |

The empty-iteration test needed a runtime-empty iterable, not a literal one: yara-x rejects an
inverted literal range at compile time with `E011`, so `(1..#z)` over a pattern with no matches is
the only way to reach a zero-iteration loop. That is a genuinely different path from the existing
"every body is undefined" test.

## Coverage advisories round 3 (2026-07-28, all added)

Every behavior was probed against the reference before a test was written, so none of these
encode a guess.

| Advisory | Test | Verified behavior |
|---|---|---|
| contextual operation names in local positions | `operation_names_work_as_local_identifiers` | the four words work as loop variables and as `with` declarations, including the awkward `for min max in (2..4) : ( max )` and `for max min in (2..4) : ( min )` |
| count body truthiness beyond booleans | `count_body_judged_like_any_loop_body` (extended) | `"abc"` counts, `""` does not, `1.5` counts, `0.0` does not |
| loop variable lifetime | `loop_variables_do_not_outlive_the_aggregate` | referring to the loop variable after the aggregate is rejected, in a conjunction and in arithmetic |

Fairness of each:
- The contextual-name test is covered by "The names of the four operations are only meaningful in
  that one position", which is what makes the local positions work; the reference recognizes the
  words two tokens after `for` and reserves nothing.
- The truthiness test is covered by "judged the same way a loop body is judged today". Probed on
  base first: `for any i in (1..3) : ( "abc" )` compiles there, so this is the engine's existing
  rule, not a new one, and any solution reusing the existing boolean-body lowering gets it free.
- The lifetime test rests on the aggregate being written like the quantified `for` plus the
  engine's own loop scoping, which is the single codebase-inferable requirement this problem
  allows itself. The natural implementation pushes and pops a symbol table exactly as
  `for_in_expr_from_ast` does, so it is a consequence rather than a hidden trap.

Neither new test pins an error message. Both open with a valid aggregate as a canary, because
`assert_rejected` alone would pass vacuously on base, where compilation fails for the wrong reason.
Confirmed on a fresh BASE checkout: the only three tests that pass there are the intended
pass-to-pass guards.

## Coverage advisories round 4 (2026-07-28, all added)

Every case probed against the reference before writing the test.

| Advisory | Test | Verified behavior |
|---|---|---|
| undefined float aggregates | `float_body_with_no_contributions` | with `math.mean(0, 0)` as an always-undefined float body: `sum` is a defined `0.0`, `min` and `max` have no value, `count` is 0 |
| undefined-value propagation | `undefined_aggregate_propagates_through_arithmetic` | an empty `min`/`max` makes a surrounding `+ 1`, `* 2`, `+ 1.0` and `* 2.0` undefined, in both the integer and the float form; the sibling `sum` case stays defined and equals 1 |
| float collection integration | `float_iterables` | `sum`/`min`/`max`/`count` over a float tuple `(1.5, 2.5, 0.5)` and over `test_proto2.array_float` |

Notes:
- `== 0.0` alone does not pin the float-ness of an empty float `sum`, because the engine coerces
  across integer and float in a comparison and `== 0` matches too. The test therefore also asserts
  `... + 0.5 == 0.5`, which only holds if the accumulator really is a float.
- The propagation test is the one the advisory asked for specifically: `not defined for min ...`
  only proves the aggregate itself is undefined, while wrapping it in arithmetic proves the
  undefined value travels outward the way any other undefined operand does.
- Fairness: all three rest on sentences already in the description, namely that an aggregate over a
  float body is a float, that `min` and `max` have no value when nothing contributes, and that the
  iterables are the ones written like the quantified `for`. Undefined propagation through
  arithmetic is the engine's own pre-existing rule, not a new one.

## Coverage advisories round 5 (2026-07-28, both added)

| Advisory | Test | Verified behavior |
|---|---|---|
| signed overflow boundary | `integer_results_wrap_on_overflow` (extended) | two iterations of `0 - 0x4000000000000000 - 0x4000000000000000`, each exactly `i64::MIN`, sum to 0; three iterations of `-(2^63-1)` land on `-(2^63-1) + 2`; `min` over the same body stays at the operand |
| partially undefined float bodies | `float_body_partially_undefined` | `math.mean(0, i) + i` over `(0..3)`: the `i = 0` iteration is undefined and skipped, the rest give 66.0, 67.0 and 68.0, so `sum` is 201.0, `min` is 66.0, `max` is 68.0 and `count` of `> 66.5` is 2 |

Notes:
- The underflow values were probed before being written into a test. The first shape tried,
  two iterations of `-(2^63-1)` compared against 2, was wrong arithmetic and did not match; the
  three assertions above are the ones the engine actually produces.
- The float body was chosen so every contributing value is an exact integer in binary floating
  point. A body like `math.mean(0, 5)` would have produced 65.2, which is not exactly
  representable, and an equality assertion on it would have been a latent flake rather than a
  test.
- `+ 0.5 == 201.5` is asserted alongside `== 201.0` for the same reason as the earlier float
  test: comparison alone coerces across integer and float, so only the arithmetic pins the type.
- Fairness: "Integer results wrap around on overflow" covers both directions of wrapping, and
  "An iteration whose body has no value contributes nothing" plus the float typing rule cover the
  partially undefined case. No new description sentence was needed.

## Coverage advisories round 6 (2026-07-28, both added)

| Advisory | Test | Verified behavior |
|---|---|---|
| empty collection iterables | `empty_collection_iterables` | `pe.sections` and `elf.sections` are genuinely empty arrays and `pe.version_info` an empty map when the scanned data is neither a PE nor an ELF: `count` and `sum` are 0, `min` and `max` have no value |
| diagnostic quality | `rejections_point_at_the_offending_part` | a non-numeric body and an arity mismatch are both rejected with a diagnostic whose caret lands inside the offending fragment, and neither is a syntax error |

Notes:
- `test_proto2` has no empty array or map; every collection it exposes is populated. Rather than
  add a fixture field to a module (that would put test-serving data into solution.patch), the
  empty collections come from the `pe` and `elf` modules over data that is neither format. That
  is a third no-contribution path, independent of the empty-range and all-undefined-body ones
  already covered.
- The diagnostic test does not pin any wording or error code. It computes the expected column
  from the source itself and asserts the reported caret falls inside the offending fragment, and
  separately that the report is not a syntax error. That is precisely the failure mode the
  advisory names, an error arising from an unrelated parse failure instead of from the body or
  the binding, and it needs no canary: on base both rules ARE syntax errors, so the test fails
  there.
- Fairness: the span assertion is a range rather than an exact column, so any diagnostic pointing
  anywhere within the offending fragment passes. The natural implementation reuses the existing
  `check_type` and `AssignmentMismatch` builders, both of which already take the span the sibling
  `for .. in` path hands them, so a correct solution gets this for free.

## AI pre-check round 7 (2026-07-28) - a reversal

`Tests focus on behavior` came back WARNING on `rejections_point_at_the_offending_part`, the test
added one round earlier in response to the `diagnostic quality` advisory. The objection is fair:
it parsed the report layout (`--> line:1:`) to recover a column, which couples the suite to
diagnostic rendering rather than to the feature, and the description says nothing about report
format.

The reviewer offered three ways out: relax it, document the format as a test assumption, or drop
it. Dropped, along with its three helpers. Two routes were considered and rejected first:

- Matching the public `CompileError` variant (`WrongType`, `AssignmentMismatch`) is structured
  rather than format-coupled, but it trades a formatting pin for an error-kind pin, which the
  hardening rules warn against just as strongly.
- Keeping only the "not a syntax error" half is still a string check on report text.

Nothing was lost. `body_must_be_numeric` and `wrong_number_of_loop_variables` already prove the
same behavior the description states, that these forms do not compile, and each opens with a
valid aggregate as a canary so neither passes vacuously on base. Test count 36 -> 35, base
failures 33 -> 32, and the pass-on-base set is unchanged.

Standing rule for later rounds: an advisory is advisory, a scored check is not. When a coverage
suggestion and a scored check disagree, the scored check wins and the reversal gets recorded here
rather than quietly re-litigated.

## Coverage advisories round 8 (2026-07-28, all added)

| Advisory | Test | Verified behavior |
|---|---|---|
| contextual-operation grammar rejection | `operation_words_outside_the_aggregate_form` | `for sum of them`, `for count of them`, `sum of them`, `min of them` and `for sum in (1..3)` are all rejected, so the contextual parsing accepts only `for <operation> <variables> in <iterable> : (...)` |
| additional invalid body types | `body_must_be_numeric` (extended) | struct, integer array, float array and map bodies join the existing bool and string cases |
| duplicate loop bindings | `duplicate_loop_bindings_shadow_like_the_quantified_for` | a repeated binding shadows rather than being rejected, matching the existing `for` |

The duplicate-binding advisory asked for the intended behavior to be settled before testing it.
Probed first: base `for any x, x in test_proto2.map_string_int64 : ( x > 0 )` compiles and matches,
so the engine already shadows, and the second binding wins. Rejecting duplicates only in the
aggregate would make it stricter than the construct the description ties it to, which is the
"no traps contradicting the repo's own semantics" rule. The test therefore asserts an EQUIVALENCE
rather than an invented rule: `for sum x, x in m : ( x )` equals `for sum k, v in m : ( v )`, and
likewise for `min` and `count`, with the base `for any` form asserted alongside as the reference.
That needs no new description sentence, because the expectation is derived from the repo's own
construct.

The rejection cases in the grammar test are wording-free `is_err` checks, and the test opens with a
valid aggregate as a canary so it still fails on base, where every one of these forms is a plain
syntax error.

Fairness of the other two: "The names of the four operations are only meaningful in that one
position" is exactly what makes the misplaced forms fall back to ordinary identifiers and be
rejected, and "a body that is neither does not compile" already covers every non-numeric family.

## Coverage advisories round 9 (2026-07-28, all added)

| Advisory | Test | Verified behavior |
|---|---|---|
| dynamic empty/reversed ranges | `runtime_reversed_range` | with a runtime lower bound above the upper bound, `count` and `sum` are 0 and `min`/`max` have no value |
| mixed defined/undefined float count identity | `float_zero_contributes_but_undefined_does_not` | an exact 0.0 contributes to `sum`, `min` and `max` and makes them defined, while an undefined iteration is skipped; `count` still sees the zero as false |
| compile-time aggregate result types | `result_type_in_integer_only_contexts` | an integer aggregate is accepted where only an integer is, a float aggregate is rejected there |

Notes:
- The reversed range reuses the repo's own idiom for the case, an outer `for any i in (1..1)`
  wrapping an inner `(i + 1..i)`, because the compiler rejects a literal reversed range outright.
  The same test asserts that the quantified `for all` over that range is still false, which is the
  behavior the repo already documents at `lib/src/tests/mod.rs`, so the aggregate rules are pinned
  next to the reference rather than in isolation.
- The float-zero test uses `math.mean(0, i) - math.mean(0, i)`, undefined at `i = 0` and exactly
  0.0 afterwards. It is the direct discriminator between "has no value" and "is zero": `min` here
  is DEFINED and equals 0.0, whereas `min` over an always-undefined body has no value. An
  implementation that treated a contributed 0.0 as "nothing contributed" would pass every earlier
  test and fail this one.
- The result-type test replaces an indirect check. Asserting `3 != 3.5` only shows the value is
  not 3.5; feeding the aggregate to `uint8(..)` and to a match index, both of which accept an
  integer and nothing else, makes the compiler itself decide, and the float form is rejected. The
  rejections are wording-free `is_err` checks.

Fairness: all three follow from sentences already present. No-contribution identities cover the
reversed range, "an iteration whose body has no value contributes nothing" is exactly what the
zero-versus-undefined test pins, and "an aggregate over an integer body is an integer and over a
float body is a float" is what the integer-only contexts exercise.

## Coverage advisories round 10 (2026-07-28, both addressed)

| Advisory | Where | Change |
|---|---|---|
| known module aggregate values | `array_iterable`, `map_iterable` | weak nonemptiness and ordering assertions replaced with exact ones |
| empty map extrema | `empty_collection_iterables` | the empty map now checks `sum` and the extrema, not only `count` |

Exact fixture values confirmed by probing before asserting: `test_proto2.array_int64` holds 3
elements with min 1, max 100 and sum 111; `test_proto2.map_string_int64` holds a single entry whose
value is 1. The old assertions (`count >= 1`, `min <= max`) would have been satisfied by an
implementation returning plausible but wrong extrema, which is exactly what the advisory pointed at.

`test_proto2.array_float` was deliberately NOT given exact-value assertions. Its elements are not
round numbers, and none of the candidate equalities probed matched, so pinning one would mean
guessing at a float literal that may not be exactly representable. That is the same flake this
suite avoided earlier when it rejected a `65.2` assertion. Its relational checks stay.

The empty map has no numeric-valued fixture anywhere in the modules, so the extrema are exercised
with a constant body over `pe.version_info`, which is empty when the scanned data is not a PE. The
iterable being empty is what the test is about, and a constant body reaches the no-contribution
path just as a value-dependent one would, while keeping the assertion independent of the map's
value type.

Fairness: both are stronger assertions of behavior the description already states, and neither
needs a new sentence.

## Platform Verify Solution round (2026-07-28) - FAIL, fixed

Verdict FAIL, `before_f2p_unexpectedly_passing`. Baseline was clean (364/364) and all 40 new tests
passed with the solution, but three of them also passed WITHOUT it:

  - `of_expressions_still_work`
  - `quantified_for_still_works`
  - `rules_can_be_named_after_an_aggregate`

Those were the deliberate pass-to-pass regression guards, carried since the first round and
documented here as intentional. The platform rule is stricter than I assumed: EVERY test in the
new suite must fail, error or skip without solution.patch, with no exception for baseline guards.
A test that passes on base does not require the solution, and the wrapper treats that as the
suite not actually testing anything.

Fixed by giving each one an aggregate assertion, so it still guards the baseline behavior it was
written for but now also depends on the feature:

| Test | Added |
|---|---|
| `of_expressions_still_work` | `for count i in (1..3) : ( 1 of them ) == 3` alongside the existing `of` assertions, which also puts an `of` expression inside an aggregate body |
| `quantified_for_still_works` | a conjunction pairing `for any i in (0..3) : ( i == 2 )` with `for count i in (0..3) : ( i == 2 ) == 1`, so the quantifier and the aggregate are asserted to agree |
| `rules_can_be_named_after_an_aggregate` | the final rule's condition now ends with `for sum count in (1..3) : ( count ) == 6`, where the loop variable shadows a rule named `count` |

None of the original assertions were removed, so the regression coverage is intact; each test just
gained a dependency on the feature. Result: 40 of 40 fail on base, none unexpectedly passing.

LESSON for later problems in this workspace: do not ship baseline-preservation tests as standalone
pass-to-pass nodes inside the new suite. Fold the baseline assertion into a test that also
exercises the new feature, so it is fail-to-pass while still catching the regression.

## Hardening round 1 (2026-07-28)

Platform batch: every Nova run passed. Full diagnosis and the fix are in feedback.md. Summary: the
original traps were all discoverable by running `cargo test`, so the lever had to change what must
be built. Three compositions were found broken in the reference itself and are now the lead trap,
covered by `aggregate_in_another_loops_header`. One new description sentence, two implementation
insights (frame reserved before the iterable, quantifier evaluated before the loop variables),
zero regressions.

## Coverage advisories round 11 (2026-07-28, both added)

| Advisory | Test | Verified behavior |
|---|---|---|
| constant reversed ranges | `constant_reversed_range_is_rejected` | `(2..1)` written with literals is rejected at compile time for all four aggregates, and for the quantified `for` too |
| float map aggregation | `float_map_iterable` | `sum`, `min`, `max` and `count` over `map_string_float` and `map_int64_float` |

Notes:
- The pair now spans the repository's own compile-time versus runtime split: a literal reversed
  range never compiles, while a range whose bounds are only reversed at run time is legal and
  yields the no-contribution identities, which `runtime_reversed_range` already covers. The
  rejection test asserts the quantified `for any i in (2..1)` is refused the same way, so the
  aggregate is pinned against the existing behavior rather than against an invented rule.
- The rejection assertions are wording-free and the test opens with a valid aggregate as a canary,
  since on base every one of these forms fails as a syntax error and would otherwise pass
  vacuously.
- `map_string_float` holds a single entry whose value is exactly 1.0, so `sum`, `min` and `max` are
  pinned by literal, plus `+ 0.5 == 1.5` to pin the float type. `map_int64_float` holds one entry
  whose value is NOT a round number; rather than guess at a literal that may not be exactly
  representable, it is pinned structurally: with one entry, `sum` equals `min` and `min` equals
  `max`. Exact, and immune to the float-literal flake this suite has avoided twice already.

Fairness: both follow from rules already stated. Maps binding a key and a value comes from the
iterables being the ones the `for` family accepts, the float result type is stated directly, and
range validation is pre-existing engine behavior the aggregate simply inherits.

## Coverage advisories round 12 (2026-07-28, one added in full, one added in part)

| Advisory | Test | Outcome |
|---|---|---|
| undefined loop headers | `undefined_loop_header` | added in full |
| floating-point extrema edge cases (NaN) | `nan_body_is_a_value_not_a_missing_one` | added only the part that is fair to pin |

**Undefined loop headers.** An undefined range bound yields no iterations, so `count` and `sum` are
0 and the extrema have no value, which matches the quantified form being false for the same bound.
An undefined quantifier leaves the whole loop undefined, and the test covers the case where that
quantifier is itself an undefined aggregate, which composes with the frame-lifetime wall added in
the hardening round.

**NaN, and what was deliberately NOT pinned.** The advisory was conditional, "if YARA-X has a
deliberate min/max/sum policy for NaN". It does not. A grep for NaN handling across the compiler,
the type system and the math module finds one incidental `is_nan` inside `serial_correlation` and
nothing else, and the description states no policy either.

NaN IS reachable, `0.0 \ 0.0` produces one. But which value the extrema settle on when a NaN meets
a number is route-dependent: a `<`-based select keeps the accumulator, Rust's `f64::min` returns
the non-NaN operand, and a sort-based implementation could do either. Pinning any of those would
fail a correct solution on a tie-break the description never states, which is the route-dependent
value gamble this workspace treats as do-not-test.

What IS fair to pin is the distinction the description does make: an iteration whose body has NO
value contributes nothing. A NaN is a value. So the test asserts only that a NaN body contributes,
leaving `sum`, `min` and `max` defined and the sum not equal to zero, and contrasts it with a body
that genuinely has no value. Every reasonable implementation agrees on that; none of the ordering
is touched.

## Hardening round 2 (2026-07-28)

Added aggregates over pattern sets (`for sum of them : ( # )`), a fifth lowering. Full rationale in
feedback.md. Headline: probing found no remaining live bug to convert into a wall, so the lever was
new machinery. The buried half is `for_of_depth`, which feeds the fast-scan safety decision; get it
wrong and the scanner returns wrong matches only in fast-scan mode, with the entire repo suite
green. 613 -> 713 effective LOC, 45 -> 46 tests, zero regressions.

## Coverage advisories round 13 (2026-07-28, 2 added + 1 real bug found)

| Advisory | Outcome |
|---|---|
| all-unmatched pattern sets | `pattern_set_with_nothing_matching` |
| string/boolean collection count | `count_over_non_numeric_collections` |
| parser/AST tooling integration | found and fixed a real bug in `yr deps`, see feedback.md |

The unmatched-pattern-set test turned out to draw a sharp line the rest of the suite did not: a
match count `#` is always a value, zero for a pattern that never matched, so every iteration
contributes and `min`/`max` are DEFINED and 0. A match offset `@` has NO value for the same
pattern, so nothing contributes and `min`/`max` are undefined. Both are asserted side by side over
the identical pattern set, which pins the "no value" versus "zero" distinction on the pattern-set
path specifically.

The non-numeric collection test confirms loop-body truthiness is the engine's own rule on module
arrays too: `array_string` holds 3 elements, all truthy; `array_bool` holds 2, of which 1 is true
and 1 is false, asserted both ways so the count is pinned from both directions.

Fairness: both rest on sentences already present, the no-contribution identities and `count` being
judged the way a loop body is judged today. The `deps` fix is a correctness repair to the feature's
own integration, not a new behavior, so it needs no description sentence.

## Coverage advisories round 14 (2026-07-28, both added)

| Advisory | Test | Verified behavior |
|---|---|---|
| pattern-set body variables | `pattern_set_body_variables` | `!` (match length) and a bare `$` (did the current pattern match), completing the set alongside the `#` and `@` already covered |
| iterable type validation | `iterable_type_validation` | a mixed expression tuple and a non-iterable expression are both rejected |

Notes:
- `!` and `@` behave alike in one respect worth having pinned: both have no value for a pattern
  that never matched, so `$z` contributes nothing and `sum` of the lengths is 8 rather than a
  value involving it. A bare `$` is a boolean, so it flows through `count` truthiness, asserted
  from both directions (2 matched, 1 not).
- The tuple rules were checked against the quantified form FIRST. `for any x in (1, "abc")` and
  `for any x in (1, 2.5)` are already rejected on base with `E003`, and a scalar or struct iterable
  with `E002`. The aggregate inherits all four. The test asserts the quantified form alongside the
  aggregate for each case, so the rule is pinned as inherited rather than invented here, which is
  the same technique used for duplicate loop bindings.
- Note the homogeneity requirement is strict about integer versus float: `(1, 2.5)` is rejected
  too, not merely string-versus-number.

Fairness: the pattern-set forms follow from the body seeing each pattern the way the quantified
`of` form does, which the description states. The iterable rules are pre-existing engine behavior
that the aggregate does not change, and the test demonstrates exactly that by asserting both forms
together. The rejection assertions are wording-free and the test opens with a valid aggregate as a
canary.

## Coverage advisories round 15 (2026-07-28, all three addressed)

| Advisory | Test | Verified behavior |
|---|---|---|
| named pattern subsets | `named_pattern_subsets_for_every_operation` | `count`, `min` and `max` over `($a, $b)`, `($a, $z)` and `($a*)`, joining the `sum` cases already present |
| undefined nested bounds | `undefined_aggregate_as_a_loop_bound` | a `min` or `max` aggregate that has no value, used as a range bound, gives the outer loop no iterations |
| non-empty external module collections | `structured_collection_iterables` | numeric aggregation over the non-empty structured array `test_proto2.array_struct` and the map `map_string_struct` |

Notes:
- The subset test needs one rule per case. A rule that declares `$a`, `$b` and `$z` but whose
  condition only names two of them fails to compile with `E022 unused pattern`, so each assertion
  declares exactly the patterns it uses. `($a, $z)` is the interesting pair: `max` is 1 and `min`
  is 0, which shows the never-matching pattern still contributes its zero count.
- The bound test is the specific shape the description's sentence about aggregates in bounds
  implies, and it is distinct from the generic undefined bound already covered: here the undefined
  value is produced BY an aggregate rather than by a division. The quantified form over the same
  bound is asserted alongside as the reference.
- For the third advisory I did NOT add a PE or ELF fixture. Constructing a valid binary inline
  would be a large blob of magic bytes, and shipping one as a file would make the oracle a hidden
  fixture, which this workspace treats as unfair. `test_proto2.array_struct` is a non-empty
  structured collection with numeric fields and exercises exactly the property the advisory is
  after, aggregation over structured collection elements rather than over their identities, with
  no fixture at all. The empty-state PE and ELF cases stay as they are.

Fairness: all three rest on rules already stated, the four operations working over a pattern set,
the no-contribution identities, and iterables being the ones the quantified form accepts.

## AI pre-check round 16 (2026-07-28) - description trim + 1 advisory

`Problem description contains only necessary information` returned request_changes with one HIGH
and three optional suggestions. All four applied, 281 -> 235 words.

| Priority | Removed | What now keeps the behavior fair |
|---|---|---|
| HIGH | "An aggregate whose loop variables do not match what its iterable binds does not compile." | `wrong_number_of_loop_variables` now asserts the quantified counterpart for every case |
| MEDIUM | "and the body sees each pattern in turn the same way the quantified `of` form does" | the retained example `for sum of them : ( # )` still shows the body using pattern context |
| MEDIUM | the preface "An aggregate is an expression, so" | the concrete allowance about quantifiers and bounds is kept verbatim |
| LOW | "judged the same way a loop body is judged today" | `count_body_judged_like_any_loop_body` now asserts the quantified form accepts the same non-boolean bodies |

The two removals that carried a tested rule were only safe because the rule is genuinely inherited,
and that was checked before trimming rather than assumed. On base, `for any k, v in (1..3)`,
`for any x in <map>` and `for any k, v in <array>` are all rejected with `E005`, and
`for any i in (1..3) : ( i )`, `( "abc" )` and `( 1.5 )` all compile and are truthy while `( "" )`
is falsy. Both tests now assert those quantified forms alongside the aggregate ones, so what used
to be a description sentence is now demonstrated in the suite as inherited engine behavior. This is
the same technique already used for duplicate loop bindings and iterable typing.

Coverage advisory, added to `pattern_set_with_nothing_matching`: `for count of them : ( @ ) == 0`
over an all-unmatched set, plus the `!` and `#` forms. `@` and `!` have no value so `count` judges
them false; `#` has the value 0, which is falsy, so it also counts zero. Three different routes to
the same answer, which is exactly what makes the assertion worth having.

## Hardening round 3 (2026-07-28)

Added the `avg` operation. Rationale and the two buried traps are in feedback.md. Headline: `avg`
breaks the result-type rule (always float, unlike the other four) and the empty identity rule (no
value, not 0), and its arithmetic hides two route-dependent mistakes that pass every other test,
dividing by iterations instead of contributions, and accumulating in floating point instead of the
body's type so the integer total no longer wraps. 724 -> 740 effective LOC, 53 -> 58 tests, zero
regressions.

## Hardening round 4 (2026-07-28) - a real bug in the reference, mutation-proven

Probing for another live wall paid off, and the wall was mine. The fast-scan guard that round 2
claimed as the buried half of the pattern-set lowering was never actually implemented; only
`for_of_depth` was. Differential run on data where a pattern matches twice:
`for sum of them : ( # ) == 3` matches in normal mode and does not match in fast-scan mode.

Fixed by replicating the guard, and covered by `pattern_set_aggregate_agrees_in_fast_scan_mode`,
which scans the same compiled rules with both scanners and asserts they agree.

The first version of that test passed against the BROKEN build, because it used the file's `DATA`
where each pattern matches once. Switching to data with a repeated match made the mutation die.
Full account in feedback.md; the lesson is that a trap test is worth nothing until the mutation
kills it.

## AI pre-check round 17 (2026-07-28) - description trim

request_changes with one HIGH and three optional suggestions. All four applied, 262 -> 219 words.

| Priority | Removed | Why it is safe |
|---|---|---|
| HIGH | the "a condition can already ask whether some, all, or a given number..." preface | pure background on existing behavior; the sentence was rewritten so the remaining gap statement stands on its own |
| MEDIUM | the example `for sum i in (0..3) : ( i * 2 )` | see below |
| MEDIUM | "or with a named subset in place of `them`" | `named_pattern_subsets_for_every_operation` now asserts the quantified `for any of ($a, $b)`, `for all of ($a, $b)` and `for any of ($a*)` alongside the aggregate forms |
| LOW | "that answer those questions:" | filler |

The syntax example was KEPT in round 2 on the argument that the construct is invented, so its exact
spelling is the rule itself rather than something discoverable. That argument no longer holds,
because the description now carries a second concrete form, `for sum of them : ( # )`, which fixes
the operation's position after `for` just as well. With the placement anchored there, "written like
the quantified `for` but with the operation where the quantifier goes" determines the `in` form
exactly, so the example was removed this time. Recorded because the same suggestion was declined
earlier and the reason it is now accepted is a change in the surrounding text, not a change of mind.

Named subsets were checked on base before the clause was dropped: `for any of ($a, $b)`,
`for all of ($a, $b)`, `for any of ($a*)` and `1 of ($a, $b)` all compile and match there, so the
aggregate inherits subset support rather than introducing it, and the test now demonstrates that
directly. An `avg` subset case was added at the same time so all five operations are covered.

## Test Fairness round 18 (2026-07-28) - FAIL on one test, fixed at the root

Verdict FAIL, 1 of 59 unfair: `avg_accumulates_in_the_body_type`. The checker is right and the
flag is accepted rather than argued.

The description said "Integer results wrap around on overflow", and `avg`'s result is explicitly a
float, so that sentence never covered `avg`'s INTERMEDIATE accumulation. Summing in i64 and then
converting, or converting each contribution and summing in f64, were both defensible readings, and
the test pinned one of them. That is the route-dependent value gamble this workspace refuses
elsewhere: the NaN advisory in round 12 was declined for exactly this reason, and then a trap of
the same shape was built two rounds later without noticing.

Fixed by stating the rule instead of deleting the test, since the behavior is worth pinning and
only the contract was missing. One word changed:

    before: ... and `avg` is the total divided by the number of iterations that contributed.
    after:  ... and `avg` divides that same wrapped total by the number of iterations that
            contributed.

"that same wrapped total" ties `avg`'s numerator to the integer total the previous clause already
says wraps. The requirement is now contract-stated while the fix stays hidden, because nothing in
the sentence says where the conversion to float belongs. meta.md 219 -> 220 words.

The description section of the same report was STALE: it repeated the four suggestions from round
17 verbatim, quoting text that had already been removed. Verified by grepping each quoted string
against the current meta.md, all four absent. No action taken on that half.

## Coverage advisories round 18 (both added)

| Advisory | Where | Verified behavior |
|---|---|---|
| `avg` as a non-reserved identifier | `operation_names_work_as_local_identifiers`, `rules_can_be_named_after_an_aggregate` | `avg` works as an aggregate loop variable, a quantified loop variable and a `with` local, and as a rule name; includes `for avg avg in (1..3) : ( avg )`, where the word is both the operation and the variable |
| invalid `avg` body types | `body_must_be_numeric` | `avg` rejects boolean, string, comparison, struct and array bodies exactly as `sum`, `min` and `max` do |

## FP review round 19 (2026-07-28) - a passing agent was NOT a real solve

The false-positive panel flagged a candidate that passed all 59 hidden tests and the 364 baseline
tests while carrying a real stack-frame corruption bug. Per the FP rule the datapoint is the
environment, so the fault is mine: the TESTS were missing a discriminator, not the description.

The candidate lowered iterable expressions before allocating the outer loop's frame, so an
aggregate sitting inside an expression TUPLE overlapped the outer loop's slots:

    for sum x in ((for sum i in (1..2) : ( i )), 5) : ( x )    candidate 6, correct 8
    for sum x in ((for sum i in (1..2) : ( i ))) : ( x )       candidate 6, correct 3

Why 59 tests missed it: aggregates were exercised in range bounds, in quantifier position and in
loop bodies, and all of those are evaluated ONCE before the outer loop starts or nested strictly
inside it. A tuple item is different, it is evaluated on every iteration of the loop that owns the
tuple, so it runs while that loop is midway through its own bookkeeping. That per-iteration
position was the one hole in the matrix.

My reference was already correct on all ten of the adjudicator's discriminators, including the
variants where a QUANTIFIED loop owns the tuple, because the round 1 fix reserves the aggregate's
frame before its iterable is built. Verified rather than assumed before writing anything.

New test `aggregate_as_expression_tuple_item` covers the aggregate-owned and quantified-owned tuple
forms, single and multi item, aggregate in first and last position, and a plain constant tuple as
the control. Mutation-proven: moving the frame reservation back to after the iterable is built,
which reproduces the candidate's defect exactly, makes it FAIL, and restoring the fix makes it
pass. It also killed `aggregate_in_another_loops_header` as a side effect, so the discriminator is
not narrowly tuned to one expression.

## Coverage advisory round 19 (added)

`avg_over_a_partially_undefined_float_body`: a float body undefined at `i = 0` and 65.5 and 66.0
afterwards, giving a fractional mean of 65.75 with a divisor of 2 rather than 3. The previous
`avg` tests covered float accumulation and the contribution divisor separately; this one pins both
in a single assertion, plus a float tuple whose mean is 2.5.

## Coverage advisories round 20 (2026-07-28, both added)

| Advisory | Where | Verified behavior |
|---|---|---|
| empty pattern-set avg | `pattern_set_with_nothing_matching` | over a set where nothing matches, `avg` of `@` and of `!` have no value, while `avg` of `#` is a defined 0.0 |
| empty collection avg | `empty_collection_iterables` | `avg` over the empty `pe.sections` and `elf.sections` arrays and over the empty `pe.version_info` map has no value, with both an integer and a float body |

Both were folded into the tests that already own those situations rather than added as new nodes,
since they extend an existing matrix by one operation rather than opening a new axis.

The pattern-set case carries the sharper assertion of the two. `avg` groups with the extrema in
having no value when nothing contributes, so over the same pattern set it splits three ways
depending on the body: `@` and `!` have no value for an unmatched pattern so `avg` is undefined,
while `#` is a defined zero that DOES contribute, so `avg` is 0.0 and defined. Asserting the
undefined and the defined-zero halves side by side is what makes it discriminating rather than a
restatement of "avg of nothing is undefined".

Fairness: both follow from two sentences already in the description, that `min`, `max` and `avg`
have no value when nothing contributes, and that the five operations also aggregate over a set of
patterns. No new sentence was needed.

## Coverage advisories round 21 (2026-07-28, both added)

| Advisory | Test | Verified behavior |
|---|---|---|
| aggregate types in loop headers | `float_aggregate_rejected_in_loop_headers` | a float aggregate is refused as a quantifier, as either range bound, and as an `of` quantifier |
| operation coverage across header slots | `every_operation_in_every_header_slot` | all four integer operations in all three header roles |

Notes:
- The float rejection is checked for both ways an aggregate becomes a float: `avg`, which is always
  one, and `sum`/`max` over a float body. Those are different routes to the same type and an
  implementation could plausibly get one right and the other wrong, since `avg` carries the type
  as a property of the operation while the others take it from the body.
- The `of` quantifier is included because it is a fourth header position the earlier tests reached
  only with an integer aggregate.
- The matrix test fills 4 operations x 3 slots plus a case where the two bounds are supplied by
  different operations. Values are chosen so each assertion has a distinct expected result rather
  than repeating one number, which is what makes filling the matrix worth the nodes.

Fairness: both rest on sentences already present, that an aggregate may appear in the quantifier or
in the bounds of another loop, and that `avg` is always a float while the others follow the body.
The integer-only nature of those header positions is pre-existing engine behavior, already
demonstrated elsewhere in the suite by the `uint8` and match-index cases. Rejections are
wording-free and the test opens with a valid aggregate as a canary.

## Coverage advisories round 22 (2026-07-28, both added)

| Advisory | Test | Verified behavior |
|---|---|---|
| partially undefined pattern-set avg | `pattern_set_avg_counts_only_contributing_patterns` | over a set where two of three patterns match, `avg` of `@` and of `!` divides by 2 |
| undefined nested body result | `undefined_nested_aggregate_is_skipped_as_a_body` | an inner aggregate that has no value for some iterations is skipped by the outer one |

Notes:
- The pattern-set test is the sharpest divisor check in the suite because it makes the SAME set
  produce two different divisors depending on the body. `@` and `!` have no value for the pattern
  that never matched, so the divisor is 2 and the mean of the offsets is exactly 2.0. `#` has a
  value for all three, including the zero, so the divisor is 3 and the mean drops below 1. A
  single wrong divisor rule cannot satisfy both halves.
- That second half is asserted with `< 1.0` and `> 0.5` rather than an exact literal. The true
  value is two thirds, which is not exactly representable, and pinning `0.6666666666666666` would
  be the same float-literal flake this suite has now avoided four times. The bounds still
  discriminate: a divisor of 2 would give exactly 1.0, which fails `< 1.0`.
- The nested test covers all five operations as the outer one and uses an inner range `(1..i)`
  that is empty at `i = 0`, so the undefined-ness comes from a real empty loop rather than a
  division by zero. It also asserts the all-undefined case, where the outer `min` has no value
  while the outer `sum` is still 0.

Fairness: both follow from the existing sentences, that an iteration whose body has no value
contributes nothing, that `avg` divides by the number of iterations that contributed, and that the
operations aggregate over pattern sets. No new sentence was needed.

## Auto Review round 23 (2026-07-28)

Revision Requested by all three passes. Description 3/3 each time; Tests 2/3, 3/3 and 1/3; Solution
0/3 in all three on the same finding. Both blocking issues were real and are fixed; detail in
feedback.md.

- S1 `Expr::type_value()` disagreed with `ForAgg::ty()` for integer-body `avg`. Not just latent:
  `with m = for avg i in (1..4) : ( i ) : ( m == 2.5 )` panicked the compiler with a WebAssembly
  validation error. Fixed at the source by deriving the branch from `ForAgg::ty()`.
- T4 the `yr deps` integration was fixed in round 13 but untestable where I first looked. A
  `cli/tests/` integration test does get `CARGO_BIN_EXE_yr`, so it is now covered by three tests,
  run from `test.sh` new mode and prebuilt in the Dockerfile.

Agent-run data from the review, worth keeping: 3 of 10 passed, failures clustered on parser
precedence for unparenthesized aggregates (2 runs), `count` body truthiness and accumulator typing
(4 runs), nested loop-frame allocation in expression tuples (1 run, 64/65), and returning 0.0 for
an empty average (1 run, 62/65). All four are traps this suite was built around, and the reviews
classified them as fair rather than ambiguous. Passing patches ran 1127 and 1360 lines.

## Coverage advisories round 24 (2026-07-28, one added, one declined)

**Negative constant loop headers: ADDED** as `negative_constant_loop_headers_are_rejected`.
A negative constant bound and a negative constant quantifier are rejected, asserted for the
aggregate and the quantified form side by side so the rule is pinned as inherited rather than
invented. Two extra facts fell out of probing and are now pinned with it: an aggregate is never a
compile-time constant, so a negative value produced BY an aggregate is not caught by that check
and is simply a runtime value, and negative values inside a body are unaffected.

**Compiler diagnostics: DECLINED**, and this is a repeat of a settled question rather than a new
call. The same advisory arrived in round 6, was implemented as
`rejections_point_at_the_offending_part`, and was then removed in round 7 when the scored
`Tests focus on behavior` check flagged it as coupling the suite to diagnostic formatting. The
standing rule recorded then still applies: an advisory is advisory, a scored check is not.

Both halves of the request conflict with a ruling this submission has already taken:

- "point at the operation or body span" is what round 7 rejected. Recovering a column means parsing
  the report layout.
- "mention the expected numeric/integer type" is a substring pin on diagnostic wording, which the
  Test Fairness check has separately praised this suite for avoiding.

The structured middle ground, matching on the public `CompileError` variant, was considered in
round 7 and rejected then for trading a formatting pin for an error-kind pin; that reasoning has
not changed. The concern behind the advisory, that severely degraded diagnostics would pass, is
real but is not reachable without one of those two couplings, so it is left uncovered on purpose
and recorded here rather than silently dropped.

## Coverage advisories round 25 (2026-07-28, both added)

| Advisory | Test | Verified behavior |
|---|---|---|
| dependency references inside aggregate subexpressions | `dependencies_inside_every_aggregate_child_are_found`, `module_used_inside_an_aggregate_is_reported` | a rule referenced from the body, a range bound, a quantifier or a tuple item is reported by `yr deps` in every case, and a module used inside an aggregate or a pattern-set aggregate likewise |
| public parser/AST traversal | `parser/tests/dfs_agg_685dcf.rs`, 5 tests | the AST walk reaches the body, both range bounds, every tuple item, an aggregate nested in another loop's header, and the body of a pattern-set aggregate |

The first advisory was right that the earlier CLI test proved less than it looked like: `helper`
sat OUTSIDE the aggregate, so it only showed the walk reached the surrounding condition. The new
version puts the reference in each of the four aggregate child positions in turn and asserts the
exact reported dependency list for each.

The second is now a direct traversal contract rather than an indirect one. `yara_x_parser::ast::dfs`
is public, so a new integration test at `parser/tests/dfs_agg_685dcf.rs` drives `DFSIter` over a
parsed condition and collects the identifiers it reaches. Distinct identifier names per position
make each assertion name the child that went missing.

Mutation-proven: dropping the range-bound arm from the aggregate's DFS makes
`walk_reaches_both_bounds_of_an_aggregate` fail while the other four still pass, so each test is
tied to the child it claims to cover. A first attempt at that mutation made both match arms
diverge and simply failed to compile, which proves nothing; the second attempt removed only the
range traversal and produced a genuine kill.

`test.sh` new mode now runs three test binaries, the library suite plus the CLI and parser
integration tests, and propagates the first non-zero exit. The Dockerfile prebuilds the CLI tests;
the parser tests build from the same workspace.

## FP review round 26 (2026-07-28)

Two FP panels, opposite verdicts, same probe: `with sum = 2 : ( for (sum) i in (1..3) : ( i > 1 ) )`.
One adjudicated false positive (medium confidence), the other genuine pass (high confidence), and
both cited the same reason for their uncertainty, that the description does not say whether a
parenthesized operation name in the quantifier slot is the operation. That is a description defect
regardless of which verdict is right, so it was fixed there: the scoping sentence now says the names
are only meaningful written directly after `for` and are ordinary identifiers anywhere else.

Pinned by `parenthesized_operation_name_is_an_ordinary_quantifier` for all five names, with a
non-operation variable as the control. My reference already behaved correctly, matching base.

The candidate's defect could not be reproduced locally, because it lived in `cst2ast` name matching
while this reference disambiguates in the token stream. Discrimination rests on the adjudicator's
own reproduction against the candidate using the exact asserted expression; see feedback.md.

Also in this round: the working tree was lost mid-session to an external disk reclaim and restored
by re-cloning and applying both patches clean. Deliverables were never at risk.

## AI pre-check round 27 (2026-07-28) - 3 of 4 applied, 1 declined

request_changes with one HIGH and three optional suggestions. 239 -> 215 words.

**HIGH, applied but by REPLACEMENT rather than deletion.** The suggestion was to drop "An aggregate
may appear in the quantifier or in the bounds of another loop", on the grounds that "once you
introduce these as expressions" the placement follows from the grammar. The premise was not true of
the current text: the sentence calling them expressions had itself been removed in round 17 as a
tautological preface, so the description no longer said it anywhere. Deleting the placement rule on
its own would have left the header positions completely unstated, and that rule is the contract for
the frame-lifetime trap from hardening round 1, plus four tests
(`aggregate_in_another_loops_header`, `every_operation_in_every_header_slot`,
`float_aggregate_rejected_in_loop_headers`, `undefined_aggregate_as_a_loop_bound`).

So the enumeration was replaced by the general rule the suggestion assumes: "An aggregate is an
expression that yields a number, usable wherever a number is." That removes what was objected to,
keeps the contract, and is in fact broader, since it also covers the expression-tuple position the
old enumeration never mentioned but that the round 19 FP panel already reasoned about from exactly
this reading.

**Two typing MEDIUMs applied.** The mirror rule ("integer body is an integer and float body is a
float") and "a body that is neither does not compile" are both default type inference on top of
"take a numeric body", which stays. Trimmed to "`avg` is always a float, whatever its body", which
is the part no inference gives you.

**The overflow MEDIUM declined.** The suggestion was to drop "Integer results wrap around on
overflow" and keep only the `avg` clause. That clause reads "and `avg` divides that same wrapped
total", so removing the antecedent would leave "that same wrapped total" pointing at nothing. That
exact sentence is the round 18 fix for a Test Fairness FAIL, where
`avg_accumulates_in_the_body_type` was ruled unfair precisely because the intermediate accumulation
was unstated. Applying this suggestion would re-open a scored-check failure to satisfy an optional
one, so it is declined on the standing rule from round 7: an advisory is advisory, a scored check is
not.

## AI pre-check round 28 (2026-07-28) - loosened two coupled assertions, and nearly broke F2P doing it

`Tests focus on behavior` came back WARNING on the two tests added in round 25: the parser DFS test
pinned a visitation ORDER (lower bound then upper bound) and the CLI deps tests pinned output
FORMAT, including the `mod: math` token and the duplicate dependency lines. Same class as the round
7 ruling, and a scored check outranks the advisory that asked for them, so both were loosened.

- The DFS tests now use one `assert_reaches` helper that checks each expected identifier is present
  somewhere in the walk, with no ordering.
- The CLI tests now count how many times a name appears in the reported tree instead of comparing
  the whole sanitized line vector, so neither the tree glyphs nor the `mod:` label matter.

**Loosening one of them silently destroyed its F2P and the harness caught it.** After the change,
`aggregate_loop_variable_is_not_a_dependency` PASSED on base: the rule source fails to compile
there, so only `rule i` is reported, and `mentions("i") == 1` was satisfied by the wreckage rather
than by correct behavior. The old exact-vector assertion had been holding that up incidentally,
because it also required `agg_test` to be present.

Fixed by asserting the aggregate rule is reported first, in that test and in the two others whose
counts could be satisfied the same way, then re-verifying: 78 of 78 fail on base again, and the
deps mutation (removing the `ForAgg` arm from the walker) is still killed.

The lesson is narrow and worth keeping: relaxing an assertion can remove a precondition you were
not aware you depended on. When a scored check forces a test to be loosened, re-run the base-mode
F2P check and the mutation, not just the passing run.

## Test Fairness round 29 (2026-07-28) - FAIL on one assertion, removed

Verdict FAIL, 1 of 79 logical assertions unfair. The checker split
`negative_constant_loop_headers_are_rejected` into two entries and rated the inherited-validation
half fair (repo-discoverable) while flagging exactly one line:

    assert_true("for (for min j in (1..2) : ( 0 - j )) i in (1..3) : ( i > 0 )");

The flag is correct and is accepted without argument. That line asserted a negative value produced
by a constant-LOOKING aggregate is not treated as a compile-time constant, so it survives the
non-negative check and behaves as an ordinary runtime value. Nothing requires that. The description
says nothing about constant folding, and `non_negative_integer_from_ast` only describes what happens
once a value has already been classified constant; it does not say a numeric aggregate cannot be
folded. An implementation that folded `for min j in (1..2) : ( 0 - j )` to -1 and then rejected it as
a negative constant quantifier would be equally defensible, so the assertion pinned an optimization
choice rather than a behavior.

Removed rather than documented. Stating "an aggregate is not a compile-time constant" would be a
prescriptive implementation note with no user-visible consequence, and the description-quality check
has been trimming exactly that kind of sentence for the last several rounds. This is the same class
already declined for NaN ordering in round 12: route-dependent and unspecified, so do not test it.

The rest of the test is untouched and still carries its canary, the paired aggregate/quantified
rejections for negative bounds and a negative constant quantifier, and the negative-body cases.
Re-verified after removal: 78 of 78 still fail on base, base mode 364/0, flakiness 3x identical.

Standing count of fairness outcomes across the submission: 2 assertions flagged unfair in total,
one fixed by stating the missing rule (round 18, avg accumulation) and one removed because no
statable rule existed (this round).

## Coverage advisories round 30 (2026-07-28, one added, one declined again)

**Parser/AST source spans: ADDED**, three tests in `parser/tests/dfs_agg_685dcf.rs`. The aggregate's
public `span()` is asserted to cover the source from the operation word through the closing
parenthesis, for the `in` form, the pattern-set form, and a nested pair where the outer and inner
spans must each be complete. This is a span through the public AST API, not a rendered report, so it
does not re-open the round 7 formatting-coupling ruling.

Mutation-proven: shortening the span in `cst2ast` so it stops before the closing parenthesis fails
all three, and the five traversal tests keep passing, so the new tests are tied to span integrity
specifically.

**Compile diagnostics: DECLINED for the third time**, now with the missing piece checked rather than
assumed. Rounds 6, 24 and this one have all asked for assertions that an invalid body or a
misplaced float aggregate reports the error AT the body or result expression. Round 7's scored check
already removed the version that parsed the rendered report. Before declining again I looked for a
structured route: `CompileError` exposes no public accessor for its location. `CodeLoc` and
`Label::span()` exist in `lib/src/compiler/report.rs` but are not reachable from a `CompileError` a
caller holds, and the `impl CompileError` block has no public location method. So the only remaining
routes are still parsing the rendered text or pinning an error kind, both already ruled out. The gap
is real and stays uncovered on purpose.

## A missing-test hole the F2P check caught

Adding the span tests to a third crate exposed a flaw in `test.sh` that had been latent since the
parser test file was introduced. The fallback that synthesizes failures only fired when NO test
lines were parsed at all. On base the library and CLI binaries do produce lines, while the parser
binary fails to COMPILE, because the test file names `Expr::ForAgg`. Its 8 cases were therefore
absent from the report rather than failing: the base run showed 73 of 81.

The synth is now per-name. Every entry of `NEW_TEST_NAMES` with no parsed result is reported as a
failure, so one crate failing to build can no longer silently drop its cases. Base run went from 73
to 81 of 81 failing. This is the go-junit-report lesson in a new place: guard the synthesis on the
expected test NAMES, never on whether the output looked empty.

## Test Fairness round 31 (2026-07-28) - FAIL on the three span tests, rewritten not removed

Verdict FAIL, 3 of 81 unfair: the span tests added one round earlier. The finding is correct and is
accepted. Their helper filtered the DFS on `Expr::ForAgg`, a public AST variant this reference
introduces. The description never says how the aggregate is represented, the pinned repository has
no such symbol, and existing loops are split between `Expr::ForIn` and `Expr::ForOf`. An
implementation that extended or reused those nodes would satisfy every user-visible requirement and
still fail to COMPILE these tests, which is the worst shape a test can have: it rejects a correct
solution for a design choice nobody asked for.

Worth noting the checker drew the line precisely. The five traversal tests in the same file were
rated fair, because they collect `Expr::Ident` and never name the new variant. Only the span helper
was coupled.

Rewritten rather than deleted, because the whole-construct span convention itself IS discoverable at
`cst2ast.rs` and is worth pinning. `Expr` implements `WithSpan`, so the helper now walks every
expression, takes each one's span, and asserts that SOME node spans exactly the aggregate's source
text. That holds whichever node carries the construct, so it says nothing about representation. The
patch contains zero occurrences of `ForAgg` in test code.

Mutation-proven again after the rewrite: shortening the span in `cst2ast` so it stops before the
closing parenthesis still fails all three, and the five traversal tests still pass.

Standing count of fairness outcomes: 5 assertions flagged across the submission, one fixed by
stating the missing rule (round 18), one removed with no statable rule (round 29), three rewritten
to drop an implementation coupling (this round).

## Alignment round 32 (2026-07-28) - a scored check overruling an optional trim

`Problem and tests are aligned` returned WARNING: the description exemplified pattern-set
aggregation only as `for sum of them : ( # )`, while tests also use named subsets `($a, $b)` and
wildcards `($a*)`. The checker called it strongly implied by "written like the quantified `for`"
but not stated.

This is the clause that round 17 removed, on a MEDIUM suggestion from the description-quality check
that named subsets were inferable from existing `of` semantics. Both checks are scored, so the
standing advisory-versus-scored rule does not settle it. What does settle it: the round 17 item was
optional (MEDIUM) and speculative, while this is a live finding about a real gap between the
description and 8 assertions. A concrete alignment complaint outranks an optional brevity
preference, so the coverage is restored.

Restored in a more general form than it was removed in, which should also survive the trimmer:

    before round 17: ... written `for sum of them : ( # )` or with a named subset in place of `them`.
    now:             ... written `for sum of them : ( # )` or over any pattern set the quantified
                     form accepts.

The old wording enumerated one alternative form and still left wildcards implicit. The new wording
states the inheritance itself, which is exactly the reasoning the alignment checker used, and covers
`them`, named lists and wildcards without listing any of them. 215 -> 224 words.

The test-side mitigation from round 17 stays: `named_pattern_subsets_for_every_operation` asserts
`for any of ($a, $b)`, `for all of ($a, $b)` and `for any of ($a*)` alongside the aggregate forms, so
the inheritance is demonstrated in the suite as well as stated in the description.

## Agent batches

### Batch 1 (2026-07-30, 2x Orion + 4x Nova) - 0 of 6, UNSOLVABLE

| Run | Solver | Verdict | Msgs | Files | LOC | Failed | Dominant cause |
|---|---|---|---|---|---|---|---|
| 1 | Orion | FAIL_MISSED_REQUIREMENT | 215 | 14 | 1563 | 11/81 | frame collision + count truthiness + deps scoping |
| 2 | Orion | FAIL_MISSED_REQUIREMENT | 216 | 15 | 1185 | 6/81 | frame collision ONLY |
| 3 | Nova | FAIL_MISSED_REQUIREMENT | 178 | 12 | 799 | 6/81 | composability: tuple items + loop headers |
| 4 | Nova | FAIL_MISSED_REQUIREMENT | 134 | 11 | 1433 | 11/81 | composability + count + avg inference + deps |
| 5 | Nova | FAIL_MISSED_REQUIREMENT | 131 | 13 | 763 | 10/81 | frame collision (6) + count truthiness (4) |
| 6 | Nova | FAIL_MISSED_REQUIREMENT | 152 | 13 | 843 | 6/81 | composability: tuple items + loop headers |

Every run preserved all 364 baseline tests, and every run produced a substantial implementation
(763 to 1563 LOC, 131 to 216 messages). Nobody was close to failing for effort.

**One cluster killed all six.** Aggregates evaluated while another loop is mid-flight, in that
loop's quantifier, its range bounds, or a tuple item it iterates. Runs 2, 3 and 6 failed ONLY that
cluster and were otherwise complete, at 75 of 81. Two distinct root causes appeared for it: Orion
runs reproduced the exact frame-lifetime collision this submission was hardened around in round 1
(iterable lowered before the enclosing frame is reserved), while Nova runs failed earlier, at the
parser, by adding aggregates as a separate alternative rather than at the term/comparison layer.

Secondary clusters, none of which killed a run on their own: `count` emitting its body raw instead
of through the boolean-coercion path (runs 1, 4, 5), and the CLI dependency walker not scoping
aggregate loop variables (runs 1, 4).

**Diagnosis: the description under-signposted the composability requirement.** Every evaluator
rated the description clear and the tests fair, and all six said the requirement was inferable from
"usable wherever a number is". Six independent runs missing the same thing is the counter-evidence.
The workspace rule is that when a specific approach is genuinely required, the prompt has to say so;
here the approach is required and the sentence only implied it.

**Fix applied:** the composability sentence now names the positions and states the obligation.

    An aggregate is an expression that yields a number, usable wherever a number is. That includes
    places another loop evaluates while it is running, such as its quantifier, its range bounds, or
    an item of the tuple it iterates, and an aggregate sitting in one of those must leave the loop
    around it working.

This is contract-stated and fix-hidden. It says the enclosing loop must still work; it does not say
the frame has to be reserved before the iterable is built, nor that the quantifier must be evaluated
before the loop variables are set up, which are the two insights the reference needs. 224 -> 264
words. No test changed.

**Expected effect and the trade being made.** Runs 2, 3 and 6 failed only this cluster, so the
likely next batch lands near 3 of 6, which is over the 40 percent ceiling. That is accepted
deliberately: 0 percent is an automatic reject and solvability is the hard floor, while a too-easy
reading is recoverable by adding a NEW discriminator. Re-hardening by restoring an under-signposted
requirement would just re-create the unfairness. If the next batch reads above 40 percent, the
lever is a fresh trap, not this one.
