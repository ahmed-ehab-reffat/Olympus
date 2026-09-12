# feedback.md — grmtools-parameterized-rules

## Summary

- Repo: [softdevteam/grmtools](https://github.com/softdevteam/grmtools), Rust, dual Apache-2.0 / MIT, 576 stars, ~24k source LOC across five crates (cfgrammar, lrtable, lrpar, lrlex, nimbleparse), pure Rust with no system dependencies.
- BASE_COMMIT: `c1a9bd0f820285754e17fc002f1cb69667ee3055` (2026-08-01).
- Tier: Olympus. Category: enhancement. Shape: O-Composite-add.
- Feature: a Yacc rule may take parameters, and a production, `%start` or `%expect-unused` may call it with arguments; each distinct argument list becomes its own rule in the grammar the LR table is built from.
- Status: BATCH 1 RAN 0 of 9. See "Batch 1 diagnosis" at the end: the artifact cannot reach the band on this axis. Earlier: Test Fairness round 1 answered (FAIL, 26 of 73 unfair) rounds 2-5 coverage suggestions taken; the round-4 and round-5 fairness flags closed in meta.md; the round-6 and round-7 quality warnings cleared. No agent batch run yet.

## Host selection log

The user asked for a fresh Rust repo, so every repo already under `worktrees/`, `problems/`, `rejected/` or `Instructions/Aprroved/` was excluded. Candidates killed on hard gates:

| Candidate | Killed by |
| --- | --- |
| pubgrub-rs/pubgrub | MPL-2.0, not in the allowed licence list. |
| chaosprint/glicol | recency: last push 2025-04-06, 16 months with no source commit. |
| obeli-sk/obelisk | AGPL-3.0. |
| DSchroer/dslcad | LGPL-2.1. |
| ricosjp/truck | already used (truck-mass-properties, approved Mars) and its `truck-platform` tests need a GPU adapter, so the Environment Quality gate cannot go green. |
| It4innovations/hyperqueue | default feature builds HiGHS from source (cmake + C++), and the scheduler now runs an LP solve, so scheduling decisions are not obviously deterministic. |
| holo-routing/holo | `holo-yang` binds the libyang C library; every protocol is also an RFC, which is the documented-spec dead class. |
| googlefonts/fontations | live Google workstream in skrifa and klippa; the font capability class is already mined by fonttools-color-merge and allsorts-colrv1-variation. |
| LaurenzV/hayro, resvg | PDF/SVG rendering is snapshot-tested; resvg is also MPL-2.0. |
| brave/adblock-rust, cozo | MPL-2.0. |

grmtools cleared every hard gate: dual permissive licence, 576 stars, a source commit two days before the pick, a vanilla `cargo test --workspace` that is green offline in 2.6 seconds, and no system dependencies.

**Known residual risk, logged deliberately.** `Aprroved/iwe-anchored-links/feedback.md` screened grmtools out as "beacon-saturated: every natural gap has an open maintainer issue (EBNF/rule macros #562, lex definitions #417/#465, ambiguities #612)". That screening is about beaconed features, and rule macros are exactly issue #562. I picked it anyway because every other axis is clean and the alternatives all died on a hard gate, but the dedup risk is real: another author may have found #562 too. Mitigations checked: `gh pr list -R softdevteam/grmtools --state all --search macro|repetition|ebnf|parameterized` returns zero hits ever; the only branches are `master`, `staging`, `trying`, `gh-pages`; issue #562 has had no activity since 2025-05-08. Compare with #484/#191 (multiple start rules), which are warm right now (comments 2026-07-18/19 and open PR #649) and were rejected for that reason.

## Why this feature

- Capability gap reproduced on base: `YaccGrammar::new(YaccKind::Grmtools, "A -> u8: 'b' { 1 } 'c' { 2 };")` and every parameterised form fail at the yacc parser, so the base tree rejects the grammar outright. All 128 new tests fail on base.
- Exclusivity: no PR in any state has ever touched rule macros, repetition operators or parameterised rules; no non-default branch exists.
- Defined behaviour: ltratt on #562 ("I would like to see repetition operators, but ... there are some interesting edge cases that need to be handled (I think due to conflicts)"), plus LALRPOP and nearley as sibling templates. The Rust-type substitution rule is grmtools-specific and had to be invented, so it is pinned exactly in meta.md.
- Not a documented spec: the instantiated-rule naming, the ordering, the token-argument rule and the type-substitution rule are this toolkit's own semantics.

## Design decisions logged

- The expansion runs inside `GrammarAST::complete_and_validate`, before every existing check, so `YaccGrammar` construction, the LR table builder, error recovery and the unused-symbol analysis all see an ordinary grammar. That is what makes the feature cross-crate without touching lrtable or lrpar at all.
- A call is carried through the parser as a `Symbol::Rule` whose name is the call text (`Comma<Expr>`), not as a new `Symbol` variant. Adding a variant to a public non-`non_exhaustive` enum would have forced every match in four crates to change, which is compile-coupling rather than real difficulty.
- `ast.prods` is rebuilt from scratch after expansion, because `YaccGrammar` unwraps every production slot and panics if a rule's productions are orphaned. That rebuild is what makes the instantiation order observable as rule indices.
- Instantiation memoises the name *before* expanding the body, which is the only thing that makes `List<T>: T | List<T> ',' T;` terminate.
- The instantiation cap (128) is stated in the description because a growing argument (`F<T>: F<G<T>>`) has no other termination condition.
- The new tests are their own cargo test targets (`cfgrammar/tests/params_d799b2.rs`, `lrlex/tests/params_parse_d799b2.rs`), so base mode runs `cargo test --workspace --lib --bins`, which is exactly the repository's own set of tests. No `test.sh` trickery and no file moving. `lrlex` gains one dev-dependency on `lrtable` in test.patch so the integration test can build a state table.

## Traps

1. Memoise-before-recurse. A self-referential parameterised rule is the natural way to write a list, and the obvious recursive expansion never returns. The symptom is a hang, not a wrong value.
2. Argument-before-call ordering. Expanding `Group<Opt<E>>` outside-in produces a rule whose body still names an unexpanded call; the failing assertion is the *name* of a rule, not the ordering.
3. Rule ordering is observable. Instantiated rules must be appended after every written rule, in first-required order. Get it wrong and rule indices shift, so the parse-tree and conflict tests fail while nothing mentions ordering.
4. Whole-identifier type substitution. `Vec<Total<T>>` and `TMap<T,T2>` both contain `T` as a substring; a naive string replace corrupts them, and the failing assertion is a Rust type string.
5. Token arguments change the symbol kind. A parameter bound to a token has to become `Symbol::Token` in the body, otherwise the grammar reports an unknown rule reference far from the call site. It also has no declared type, which is only an error when the type actually names that parameter.
6. Production slots. Removing the parameterised rules without rebuilding `ast.prods` leaves orphaned productions and `YaccGrammar::new_from_ast_with_validity_info` panics on an unrelated `unwrap`.
7. Entry points other than a production. A call may also appear in `%start` and `%expect-unused`; an implementation that only walks productions silently drops the grammar's only instantiation.

Traps 1, 2 and 3 are interdependent: they all run through the same memo table, and the fix for the ordering trap changes when the memo entry is created.

## False-positive mapping (meta clause to test)

| meta clause | tests |
| --- | --- |
| parameters written straight after the name | `single_argument_rule_is_instantiated`, `parameterised_rules_work_without_types` |
| a production may call it with arguments | `instantiated_rule_replaces_the_call_site` |
| one and two parameters | `several_parameters_are_matched_by_position` |
| repeating a name in one declaration is an error | `a_repeated_parameter_name_is_an_error` |
| the same argument may serve more than one parameter | `a_parameter_may_be_passed_twice_to_one_rule` |
| spaces allowed inside the brackets | `whitespace_inside_an_argument_list_is_allowed`, `spaces_are_allowed_in_a_parameter_declaration` |
| argument is an ordinary rule | `single_argument_rule_is_instantiated` |
| argument is another call | `nested_call_names_the_inner_instantiation`, `a_deeply_nested_call_resolves` |
| argument is a token, quoted or `%token` | `a_quoted_token_may_be_an_argument`, `a_declared_token_may_be_an_argument_unquoted` |
| a call in `%start` | `the_start_rule_may_be_a_call`, `a_call_only_in_the_start_declaration_is_still_instantiated`, `a_call_in_the_start_declaration_parses` |
| a call in `%expect-unused` | `an_instantiated_rule_can_be_named_by_expect_unused`, `a_call_named_only_by_expect_unused_is_still_built` |
| one rule per distinct argument set | `two_calls_with_the_same_argument_share_one_rule`, `two_calls_with_different_arguments_make_two_rules`, `swapped_arguments_make_a_different_rule`, `a_parameterised_rule_used_twice_with_one_argument_is_one_language`, `sharing_one_instantiation_does_not_duplicate_the_conflict_count` |
| the instantiated name, commas with no spaces | `single_argument_rule_is_instantiated`, `several_parameters_are_matched_by_position`, `whitespace_inside_an_argument_list_is_allowed`, `the_instantiated_rule_names_the_arguments` |
| a token argument is single-quoted in the name | `a_quoted_token_may_be_an_argument`, `a_token_argument_parses`, `a_double_quoted_token_argument_is_named_with_single_quotes`, `a_declared_token_argument_is_single_quoted_in_the_name` |
| arguments built before the call | `arguments_are_instantiated_before_the_call_that_uses_them` |
| new rules follow every written rule | `instantiated_rules_follow_every_written_rule` |
| ordered by first need, including a need that arises while building | `instantiation_order_follows_first_use`, `a_rule_needed_while_building_another_comes_before_a_later_sibling`, `a_body_naming_a_concrete_instance_of_itself_builds_both` |
| an error points at the text that caused it | `an_unknown_parameterised_rule_error_points_at_the_call`, `an_arity_error_points_at_the_call`, `an_unknown_argument_error_points_at_the_call`, `a_token_in_a_type_error_points_at_the_call`, `a_duplicate_parameter_error_points_at_the_repeated_name`, `an_arguments_on_an_ordinary_rule_error_points_at_the_call`, `an_unclosed_list_error_points_at_the_bracket`, `a_bare_parameterised_name_error_points_at_the_name`, `a_prec_parameter_error_points_at_the_call`, `the_instantiation_limit_error_points_at_the_call_that_exceeded_it` |
| the parameterised rule is not a rule | `parameterised_rule_itself_is_not_a_rule` |
| a parameter becomes its argument | `instantiated_body_substitutes_the_parameter`, `a_parameter_may_be_passed_on_to_another_parameterised_rule`, `a_parameter_may_be_passed_twice_to_one_rule`, `a_parameter_forwarded_through_two_rules_parses` |
| a parameter given a token stands for that token | `a_token_argument_becomes_a_token_in_the_body`, `a_different_token_argument_makes_a_different_language` |
| actions carried over | `instantiated_rule_keeps_the_action`, `actions_are_copied_to_every_instantiation`, `an_action_naming_a_parameter_is_copied_unchanged`, `an_empty_production_inside_a_parameterised_rule_is_kept`, `an_empty_instantiated_production_parses` |
| `%prec` carried over | `a_production_precedence_declaration_is_copied`, `a_copied_prec_names_the_same_token` |
| a `%prec` naming a parameter takes that parameter's token | `a_prec_naming_a_parameter_takes_the_token_it_was_given`, `a_parameter_named_only_by_prec_is_not_a_token_of_the_grammar`, `a_prec_naming_a_parameter_drives_the_parse` |
| a `%prec` parameter given a rule is an error | `a_prec_naming_a_parameter_given_a_rule_is_an_error` |
| precedence from the last token of the built rule | `precedence_comes_from_the_last_token_of_the_instantiated_production`, `inferred_precedence_is_that_of_the_last_token`, `each_instantiation_takes_the_precedence_of_its_own_token`, `the_same_grammar_without_precedence_declarations_is_ambiguous` |
| whole-word type substitution | `parameter_is_substituted_in_the_type`, `every_parameter_is_substituted_in_a_type`, `nested_call_substitutes_the_nested_type`, `a_type_naming_something_longer_than_a_parameter_is_untouched`, `a_type_naming_a_parameter_inside_a_longer_word_is_untouched`, `a_parameter_behind_an_ampersand_is_substituted`, `a_parameter_qualifying_an_associated_type_is_substituted`, `a_type_naming_an_underscore_prefixed_parameter_is_untouched`, `a_type_naming_an_underscore_suffixed_parameter_is_untouched` |
| a token argument named in a type is an error | `a_token_argument_used_in_a_type_is_an_error`, `a_token_argument_not_named_in_a_type_is_allowed`, `a_token_argument_forwarded_into_a_type_is_an_error` |
| self-use reuses the rule being built | `recursion_with_the_same_arguments_terminates`, `recursion_makes_one_rule_only`, `mutual_recursion_terminates`, `recursion_through_a_parameterised_rule_parses_deeply` |
| more than 128 instantiations is an error | `arguments_which_keep_growing_are_an_error`, `one_hundred_and_twenty_eight_instantiations_are_allowed`, `one_hundred_and_twenty_nine_instantiations_are_an_error` |
| arguments given to a rule that takes none | `an_ordinary_rule_used_with_arguments_is_an_error` |
| arguments given to a name that is not a rule | `an_unknown_parameterised_rule_is_an_error` |
| the wrong number of arguments | `too_few_arguments_is_an_error`, `too_many_arguments_is_an_error` |
| a parameterised name used bare in a production or `%start` is an error | `a_parameterised_rule_used_without_arguments_is_an_error`, `a_bare_parameterised_name_as_the_start_rule_is_an_error` |
| a bare parameterised name in `%expect-unused` is not | `a_bare_parameterised_name_in_expect_unused_is_allowed` |
| an argument naming nothing | `an_unknown_argument_is_an_error` |
| an unclosed list | `an_unterminated_parameter_list_is_an_error`, `an_unterminated_parameter_declaration_is_an_error` |
| `%start` naming a parameterised rule bare | `a_bare_parameterised_name_as_the_start_rule_is_an_error` |
| a bad call in `%start` | `a_bad_call_in_the_start_declaration_is_an_error` |
| a bad call in `%expect-unused` | `a_bad_call_in_expect_unused_is_an_error` |
| a list must name something and may not end with a comma | `a_trailing_comma_in_an_argument_list_is_an_error`, `a_trailing_comma_in_a_parameter_list_is_an_error`, `an_empty_argument_list_is_an_error`, `an_empty_parameter_list_is_an_error`, `a_leading_comma_in_a_list_is_an_error`, `a_doubled_comma_in_a_list_is_an_error`, `a_malformed_list_in_the_start_declaration_is_an_error`, `a_malformed_list_in_expect_unused_is_an_error`, `a_malformed_separator_error_points_at_the_bracket` |
| one limit across every call source | `instances_from_every_call_source_share_one_limit`, `an_instance_wanted_by_three_sources_counts_once_towards_the_limit` |
| one rule per distinct argument set, whatever asked for it | `one_instantiation_serves_every_call_source` |
| a token argument survives forwarding | `a_forwarded_token_argument_keeps_its_name_and_kind`, `a_forwarded_token_argument_parses` |
| an uninstantiated rule is reported unused | `an_uninstantiated_parameterised_rule_warns`, `a_rule_reached_only_from_an_uninstantiated_rule_is_unused` |
| `%expect-unused` silences it | `expect_unused_silences_an_uninstantiated_parameterised_rule` |

No clause is unasserted, and every test traces back to a clause. The four tests that also guard against regressions (`a_grammar_without_parameters_is_unchanged`, `an_unparameterised_grammar_still_parses`, `an_instantiated_parameterised_rule_does_not_warn`, `expect_unused_silences_an_uninstantiated_parameterised_rule`) each carry a parameterised assertion as a canary, because without one they passed vacuously on base.

## Validation

| Check | Result |
| --- | --- |
| `human-effective` LOC (Counter 2) | 561 across 4 files (raw 793) |
| new tests | 128 (105 cfgrammar, 23 lrlex) |
| base tree + test.patch, base mode | PASS, 293 cases, 0 failures |
| base tree + test.patch, new mode | FAIL, 128 cases, 128 failures |
| solution applied, base mode | PASS, 293 cases |
| solution applied, new mode | PASS, 128 cases |
| both apply orders | clean apply and clean `git apply -R` |
| flakiness, 5 runs of each mode | identical every run |
| offline Docker, `--network none --user 1000:1000` | base 293 pass, new 128 pass |
| `cargo fmt --all -- --check` | clean |
| `cargo clippy --workspace --all-targets` | clean |

## Attempt history

- R0: picked grmtools after nine repos died on licence, recency, environment or dead-class gates; verified the vanilla suite green offline before writing any code.
- R0: first LOC measurement came in at 376 human-effective, under the floor. Added two orthogonal surfaces that are genuine behaviour rather than padding (token arguments with their type rule, and calls in `%start` and `%expect-unused`), which took it to 476.
- R0: first F2P run found four tests passing vacuously on base; each gained a parameterised assertion.
- R0: first `test.sh` only synthesised build-failure nodes when *no* target produced output, so a compile failure in the second target silently vanished. Rewritten to check each target separately.

## Round 1 — Test Fairness FAIL (26 of 73 unfair), answered

Two real defects, not wording quibbles.

1. **The implementation contradicted my own description.** meta.md says a token argument is written
   between single quotes in the generated name, but only *quoted* arguments were canonicalised: a
   `%token INT` argument stayed bare, so the grammar produced `List<INT>` where the description
   demands `List<'INT'>`. Fixed in `Expander::resolve`, which now canonicalises every argument the
   grammar treats as a token, whichever way it was written. Fourteen tests moved with it.
2. **Eleven tests pinned exact novel diagnostic strings** the description never states and the repo
   never establishes. Each is now a valid/invalid pair: a neighbouring grammar that differs only in
   the stated condition must build and yield named rules, and the offending grammar must be
   rejected. That keeps the discriminator and drops the wording pin. `an_unknown_argument_is_an_error`
   also moved even though the reviewer allowed its message, because the pair form is stronger.
3. **Warning order.** `warnings()` appended the uninstantiated-template warnings after the tokens,
   producing rule, token, rule. `unused_symbols()` emits all rules then all tokens, so the new
   warnings now join the rule group and the output follows the repository's own shape.

All four coverage suggestions were taken, and the fourth found a real gap: a call written only in
`%expect-unused` was never instantiated, so `Spare<E>` failed the existing expect-unused existence
check. `expand_params` now resolves those calls too, after the productions.

The valid halves of the new pairs each failed on base, but two other tests then passed vacuously
(`an_instantiated_rule_can_be_named_by_expect_unused` asserts an empty warning list, which base also
produces; `one_hundred_and_twenty_nine_instantiations_are_an_error` asserts rejection, which base also
does). Both gained a positive control. F2P is 79 of 79 again.

## Round 2 — coverage suggestions taken

All three areas now have tests; the implementation was already correct in each, so nothing changed
in `solution.patch`.

- **Actions containing parameter names.** `Group<T> -> Vec<T>: T { let T = 1; T + T2 }` must keep its
  action byte-for-byte, because the description says actions are carried over unchanged and only the
  declared *type* is substituted. This closes a real false-positive route: an implementation that ran
  the identifier substitution over action text as well passed every previous test. Proven by mutating
  the reference to do exactly that, which failed this test and only this test.
- **Unclosed declaration list.** `Group<T -> Vec<T>: ...` is now rejected as a pair alongside a valid
  control; the previous unclosed-list test only covered a call site.
- **Type word boundaries.** `&T` and `T::Assoc` substitute, `_T` and `T_` do not. Together with the
  existing `Total` and `TMap`/`T2` cases these pin the whole-identifier rule from both sides
  (punctuation is a boundary, an underscore is not).

Counts after this round: 85 tests, 85 of 85 fail on base, base 293 green in both apply orders,
5 runs of each mode identical, offline container green.

## Round 3 — coverage suggestions taken

- **Invalid calls in `%start` and `%expect-unused`.** Unknown name, ordinary rule given arguments and
  wrong arity are now rejected from all three call sources, each paired with a valid control.
  Probing this **did surface an asymmetry**: `expand_params` returned early when the grammar had no
  parameterised rules and no call in a production or `%start`, so a call written only in
  `%expect-unused` was never resolved and reported `Unknown reference to rule 'Nope<E>'` instead of
  the parameterised-rule error the other two sources give. The early-return guard now counts
  `%expect-unused` calls too. **Correction to what I said earlier: this is a diagnostic
  inconsistency, not a behavioural bug.** With no parameterised rules present such a call can never
  resolve, so the grammar was rejected either way; only the message differed. Mutating the fix away
  fails no test, which is the honest measure of it. It stays because the three call sources should
  not disagree, and a reviewer comparing them would flag the asymmetry.
- **Malformed list punctuation.** Trailing commas and empty lists are rejected in both argument and
  parameter position, so the parser is pinned beyond the missing-bracket case.
- **Limit across call sources.** One grammar needs 126 instances from productions, one from `%start`
  and one from `%expect-unused`; 128 builds and 129 is rejected, proving all three sources share the
  single counter.
- **Conflict sharing.** `sharing_one_instantiation_does_not_duplicate_the_conflict_count` compared
  only reduce/reduce counts, which were `0 == 0` and tested nothing. It now pins the full pair as
  `(1, 0)` for both the two-call and three-call grammars, which is the behaviour the name claims.

Counts after this round: 92 tests, 92 of 92 fail on base, 501 human-effective LOC, base 293 green in
both apply orders, 5 runs of each mode identical, offline container green.

## Round 4 — one fairness flag, closed in the description

The reviewer accepted 92 of 93 assertions and flagged one: rejecting a trailing comma in a parameter
*declaration* (`Pair<A,>`) pins a syntax choice the description never made. That is correct.
Accepting a Rust-style trailing comma and rejecting it are equally defensible, and grmtools has no
list syntax to settle it. The call-side twin is fair for a different reason the reviewer spotted:
`Pair<E,>` supplies one argument to a two-parameter rule, so arity rejects it either way.

I closed it in meta.md rather than deleting the test, because deleting leaves the ambiguity open for
the next implementation to resolve differently: "a list of either kind must name at least one thing
and may not end with a comma". One clause, covering both list positions, which also promotes the two
empty-list tests from arity-implied to directly stated.

Both coverage suggestions were taken and the implementation was already correct in each:

- **Cross-source deduplication.** One grammar wants `Group<E>` from `%start`, from a production and
  from `%expect-unused`; exactly one rule is emitted. The limit half is separate: 128 instances where
  one of them is wanted by all three sources builds, and 129 is rejected, so a triple request cannot
  be triple-counted.
- **Forwarded token arguments.** `Outer<','>` forwarding to `Inner<T>` keeps the single-quoted name at
  both levels and the terminal kind at the leaf, checked in the grammar and again end to end through
  the parser.

Counts after this round: 96 tests, 96 of 96 fail on base, 501 human-effective LOC, base 293 green in
both apply orders, 5 runs of each mode identical, offline container green.

## Round 5 — the flag my own round-4 clause caused

The reviewer flagged four tests that accept a repeated *argument* (`Pair<E,E>`), because "Repeating a
name in one list is an error" reads as covering argument lists too. That reading is fair, and my
round-4 sentence about lists "of either kind" made it worse. Root cause is mine, not the tests'.

Fixed where it belongs, in meta.md: "Repeating a name in one declaration is an error, though the same
argument may be given to more than one parameter." I also took the reviewer's structural advice and
stopped using `Pair<E,E>` as an incidental positive control in three unrelated tests, which now use
`Pair<E,F>`. `a_parameter_may_be_passed_twice_to_one_rule` remains the single focused test for the
duplicate-argument rule, and it is now directly prompt-stated.

The same round exposed a second wording gap. meta.md listed "a parameterised name used with no
arguments" among the errors while also saying `%expect-unused` may name a parameterised rule to
silence it. Both are true but of different places, so the clause now reads "used with no arguments in
a production or in `%start`", and a new test pins the contrast: bare `%expect-unused Spare` is
accepted and silences the warning, while bare `Spare` in a production is rejected.

All three remaining coverage suggestions were taken; the implementation was already correct in each:

- **Forwarded token type error.** A token argument forwarded through `Outer<T>` into `Inner<T>` whose
  declared type names `T` is rejected, with the rule-argument version as the control. Previously only
  the direct mismatch was covered.
- **Malformed lists at declaration sites.** Empty, trailing-comma and unclosed lists are now rejected
  in `%start` and `%expect-unused` as well as in productions, confirming the shared call parser is
  used everywhere.

Counts after this round: 100 tests, 100 of 100 fail on base, 501 human-effective LOC, base 293 green
in both apply orders, 5 runs of each mode identical, offline container green.

## Round 6 — quality warning (non-blocking), all three points fixed

The check passed with one WARNING: three assertions leaned on repository internals rather than
behaviour. All three are now behavioural, and no test in the suite depends on an internal name,
a diagnostic string, or internal accounting.

- **The synthetic start rule `^`.** `the_start_rule_may_be_a_call` asserted `start_rule_idx()` is
  named `^`, which is a grmtools internal never mentioned in the description. It now asserts what the
  description actually promises: the start production reduces to the instantiated rule, so
  `prod(start_prod())` is exactly `[Group<E>]`.
- **The warning text `"Unused rule"`.** `YaccGrammarWarningKind` has no public accessor, so the
  Display string was the only discriminator between a rule and a token warning. Replaced by a
  `warned_names` helper that reads each warning's span out of the grammar source, so the tests now
  assert *which symbol* is reported (`["Lonely", "Spare", "j"]`) rather than how the message is
  worded. That is strictly stronger: it pins the identity as well as the count, and it survives any
  rewording of the crate's diagnostics.
- **Exact total rule counts.** `1 + 1 + 128 + 128` silently encoded the synthetic start rule.
  The three limit tests now count only instantiated rules (names containing `<`) and assert 128,
  which is exactly the number the description caps.

On the sanity-check caveat: base mode runs `cargo test --workspace --lib --bins`, which is the
repository's entire own test set (grmtools has no `tests/` targets of its own, so nothing is
excluded and nothing extra is pulled in). It is green on the untouched base commit, in both apply
orders, and 3 further runs of each mode were identical.

Counts after this round: 100 tests unchanged, 100 of 100 fail on base, 501 human-effective LOC,
base 293 green, offline container green.

## Round 7 — quality warning (non-blocking), both points fixed

- **Exact conflict counts.** `sharing_one_instantiation_does_not_duplicate_the_conflict_count` pinned
  `(1, 0)`. Careful here: an earlier Test Fairness round rejected this test's *original* form, which
  compared only reduce/reduce counts and so asserted `0 == 0` and tested nothing. Dropping back to a
  bare equality would reintroduce exactly that. The test now asserts three things: the two-call
  grammar has at least one shift/reduce conflict, the three-call grammar has the identical pair, and
  a one-call control has none. That drops the hardcoded number while keeping the assertion
  non-vacuous in both directions.
- **Warning span order.** `warned_names` returned the warnings in emission order, which is a
  repository-internal ordering. The three symbols it reports are independent of one another, so the
  helper now sorts before comparing. Identity and completeness are still pinned (no missing and no
  extra warning); only the ordering coupling is gone.

The span extraction itself stays. It replaced a dependence on the diagnostic *wording* last round,
and it is the only public way to say which symbol a warning is about, since
`YaccGrammarWarningKind` has no accessor. Asserting the symbol is closer to the described behaviour
("reported as an unused rule") than asserting the message text would be.

Counts after this round: 100 tests unchanged, 100 of 100 fail on base, 501 human-effective LOC,
base 293 green in both apply orders, 3 runs of each mode identical, offline container green.

## Round 8 — hardening

The suite was fair but the difficulty was thin: every trap was local to the expander, and nothing a
solver got wrong could reach the LR machinery. Two changes, following the composition-depth rather
than trap-count doctrine.

**One scope lever (needs one new description sentence).** `%prec` may now name a parameter, taking
whatever token that parameter was bound to. This was rejected on base with "Token 'Op' used in %prec
has no precedence attached", so it is genuinely new. It adds a code path in the parser (a parameter
named by `%prec` must not be registered as a token of the grammar) and one in the expander
(substituting the precedence name, and rejecting a parameter bound to a rule). One meta sentence,
466 words total.

**Three composition traps that need no new description text at all.** Each combines rules that were
already stated and each fails an implementation that passes every isolated probe:

1. *Precedence per instantiation.* `Bin<Op>: E Op E` instantiated as `Bin<'+'>` and `Bin<'*'>` with
   `%left` on each. This composes token-kind substitution with "precedence comes from the last token
   of the rule that was built": get either wrong and the grammar has four unresolved shift/reduce
   conflicts, so the state table fails to build at all. The failing symptom is "your grammar is
   ambiguous", which points nowhere near the expander. A sibling test pins that the same grammar
   without the `%left` declarations really is ambiguous, so the zero-conflict assertion is not
   vacuous.
2. *Depth-first need order.* `S: A<E> B<F>` where `A<T>`'s body needs `C<T>`. "Arguments are built
   before the call that uses them" and "ordered by when each name was first needed" together fix the
   order as `A<E>, C<E>, B<F>` — `C<E>` is needed while `A<E>` is still being built, so it precedes
   the later sibling `B<F>`. A worklist implementation that defers body calls produces
   `A<E>, B<F>, C<E>`. Nothing in the failing assertion mentions a worklist.
3. *A body naming a concrete instance of itself.* `Wrap<T>: T Wrap<E> | T` instantiated as `Wrap<F>`
   forces the memo, the ordering rule and self-recursion to interact.

Mutation-proved, each restored afterwards:

| Mutation | Killed |
| --- | --- |
| token argument stays a rule symbol | 11 tests, including the precedence parse and conflict tests |
| `%prec` parameter not substituted | exactly 4, all in the new area |
| `%prec` parameter leaks in as a token | exactly 1, the spurious-token test |
| instantiated rules emitted sorted by name | 8 ordering and composition tests |

Counts after this round: 108 tests, 108 of 108 fail on base, 520 human-effective LOC across 4 files
(raw 735), base 293 green in both apply orders, 3 runs of each mode identical, offline container
green.

## Round 9 — one fairness flag, and a coverage suggestion that found two defects

**The flag was right, and the fix is the description.** `a_rule_needed_while_building_another_comes_before_a_later_sibling` pinned depth-first discovery (`A<E>, C<E>, B<F>`) against an equally reasonable sibling-queue reading (`A<E>, B<F>, C<E>`). Worse than merely unstated: an unstated 50/50 convention is the coin-flip anti-pattern, where a solver fails for guessing rather than for reasoning. So the ordering clause now says a rule needed while another is being built is needed at that moment, before whatever the file goes on to ask for. The trap survives as a real requirement instead of a guess.

**The coverage suggestion asked for error kinds and spans. I took the span half and declined the kind half, for a reason.** Asserting `YaccGrammarErrorKind::MacroArityMismatch` would force a solver to invent my exact enum variants, which is compile-coupling rather than behaviour, and earlier rounds had already rejected pinning message text for the same family of reasons. Spans are different: which source text an error points at is observable, wording-independent, and is the same public `Spanned` surface the warning tests already use.

Adding those assertions exposed two real defects, both now fixed in `solution.patch`:

- The duplicate-parameter error carried a zero-length span, so it pointed at nothing. It now spans the repeated name.
- Both unclosed-list errors did the same. They now point at the `<` that was never closed.

Every other error already pointed at the offending call, so the fix brings the two outliers into line rather than inventing a convention. Because "an error points at the text that caused it" is a breadth claim, all eleven error kinds now have a span test, not a representative sample.

Counts after this round: 118 tests, 118 of 118 fail on base, 528 human-effective LOC across 4 files
(raw 747), meta 489 words, base 293 green in both apply orders, 3 runs of each mode identical,
offline container green.

## Round 10 — the span claim was too vague, and it was also false

Eight span tests were flagged: "an error points at the text that caused it" does not choose between
the whole call, the offending argument, the name, or a zero-width location. Correct. The clause was
doing no work, so the tests were pinning an undocumented policy.

Rather than delete them I made the clause decide: an error points at the call it objects to, or where
there is no call, at the name, the repeated parameter, or the bracket opening a list it cannot read.
That is one sentence and it determines all ten cases.

Writing it down exposed that **my own implementation did not honour it.** Empty and trailing-comma
lists produced zero-width spans in every position, so the sentence would have been a false claim the
moment it was written. Both parameter and argument lists now report a list they cannot read at its
opening bracket, which also unifies them with the unclosed-list case rather than leaving three
different behaviours behind one sentence. This is the third round where writing the contract down
precisely, rather than the tests, is what found the defect.

The remaining coverage suggestion was conditional on documenting the policy, so it is now in:
malformed and semantically invalid calls in `%start` and `%expect-unused` have span assertions, not
only rejection assertions.

Counts after this round: 121 tests, 121 of 121 fail on base, 534 human-effective LOC across 4 files
(raw 756), meta 486 words, base 293 green in both apply orders, 3 runs of each mode identical,
offline container green.

## Round 11 — coverage suggestions, and a wrong-answer bug in the canonical name

All three areas are now covered. Two were already correct; the third was not.

- **`%prec` on a parameter given a `%token` name.** Works, and now tested against two declared tokens
  with different precedences.
- **Nested calls in directives.** `%start Outer<Inner<E>>` and the `%expect-unused` equivalent build
  inner-first and name and type correctly. Tested in both directives.
- **Token names holding a quote or backslash. This was a real bug.** Instantiated names are built by
  rendering arguments into a string and read back by re-parsing that string, and the rendering was
  not injective: a token whose name contains `'` produced a name the reader split wrongly. Concretely
  `Sep<"a'b",E>` was rejected with an arity error, because `Sep<'a'b',E>` re-parses as a single
  argument. This is a silent wrong answer on a legal grammar, not a diagnostic wrinkle.

  Fixed by escaping `\` and `'` when a token name is written into an instantiated name, unescaping
  when it is read back, and making both scanners honour the escape. `Sep<"a'b",E>` now builds as
  `Sep<'a\'b',E>` with two arguments. Mutating the escaping away fails exactly the two tests that
  target it and nothing else.

  The description needed no change: it already says a token argument is written between single quotes
  in the generated name, and an escape is how that stays readable. Names holding a comma or an angle
  bracket were already handled and now have a regression test, since those are the neighbours that
  made the quote case easy to miss.

Counts after this round: 127 tests, 127 of 127 fail on base, 561 human-effective LOC across 4 files
(raw 793), base 293 green in both apply orders, 3 runs of each mode identical, offline container
green.

## Round 12 — one test dropped, the behaviour kept

`a_token_argument_whose_name_holds_a_backslash_is_kept_whole` was flagged, and the flag is narrow and
correct: it pinned a visible multi-backslash encoding that the description never defines, on a token
form grmtools' own `parse_string` would not accept in other positions. The reviewer did not dispute
the implementation, only the assertion.

So the test is gone and the escaping stays. Escaping `\\` as well as `'` is what makes escape and
unescape inverse, which is required for the quote fix from the previous round to be sound; it is
internal to how an instantiated name is written and read back, and the description already covers the
visible contract ("a token argument is written between single quotes there"). Dropping the assertion
removes the unstated encoding without weakening the code.

The round-11 defect stays covered: mutating the escaping away still fails
`a_token_argument_whose_name_holds_a_quote_keeps_both_arguments`, which the same review rated fair on
the grounds that the existing quote grammar justifies it. Re-ran the mutation after the deletion to
confirm the discriminator survives alone.

Counts after this round: 126 tests, 126 of 126 fail on base, 561 human-effective LOC across 4 files
(raw 793), meta 486 words unchanged, base 293 green in both apply orders, 3 runs of each mode
identical, offline container green.

## Round 13 — the last serialization pin removed

The remaining flag was narrower than the previous one: the reviewer accepted that the token identity
stays `a'b` and the second argument stays `E`, and objected only to the assertion that the generated
name is spelled exactly `Sep<'a\'b',E>`. That spelling is my escape choice, not something the
description fixes, so the objection is right.

The test now finds the single instantiated rule by looking for the one name containing `<` instead of
naming it, and asserts its production is `'a'b' E`. No test anywhere pins the escaped spelling now
(checked by grep), and the escaping itself is untouched because it is what makes escape and unescape
inverse.

The discriminator survives without the spelling: with the escaping mutated away the grammar does not
build at all, because `Sep<'a'b',E>` re-parses as one argument and fails on arity, so `ok()` panics.
Re-ran the mutation to confirm it still fails exactly this test and nothing else. That is a better
test than the one it replaces: it asserts the behaviour that matters (both arguments survive a token
name containing a quote) and is indifferent to how the name is written down.

Counts after this round: 126 tests, 126 of 126 fail on base, 561 human-effective LOC across 4 files
(raw 793), meta 486 words unchanged, base 293 green in both apply orders, 3 runs of each mode
identical, offline container green.

## Round 14 — one suggestion taken, two declined with evidence

**Malformed separators: taken.** Leading and doubled commas in both list kinds are now rejected
explicitly, in three tests including the span. They were already handled, so nothing changed in
`solution.patch`; the meta already covers them ("a list of either kind must name at least one thing").

**Error kinds or message fragments: declined again, third time asked.** The concern is legitimate:
`rejected()` is satisfied by any error, so in principle a wrong-reason rejection could pass. But the
two available ways to close it are both worse than the gap. Naming `YaccGrammarErrorKind` variants
makes a solver guess my invented enum, which is compile coupling rather than behaviour and is the
fake-difficulty shape this problem has been pruned of twice. Message fragments were rejected outright
by an earlier Test Fairness round for this same suite. What the suite does instead is stronger than
either: every rejection test carries a valid control differing only in the fault, so the rejection is
attributable to the one changed token, and all eleven error kinds have a span assertion pinning where
the error lands. A wrong-reason rejection would have to also reproduce the right span on a grammar
that differs from a working one by exactly the intended fault.

**Missing argument-rule types: declined, because the state is unreachable.** Verified rather than
assumed. In `Grmtools` every rule declares a type, so `actiont` is always `Some`; an empty declaration
`E -> :` yields `Some("")` and substitutes to `Vec<>`, not `None`, and grmtools does not type-check
Rust types. In the `Original` kinds the type comes from `%actiontype`, which applies to every rule or
none, so a typed template cannot see an untyped argument. There is therefore no error semantics to
specify, and adding a description clause for a state no grammar can reach would be over-specification
with nothing to map it to.

Counts after this round: 129 tests, 129 of 129 fail on base, 561 human-effective LOC across 4 files
(raw 793), meta 486 words unchanged, base 293 green in both apply orders, 3 runs of each mode
identical, offline container green.

## Round 15 — category corrected, and three more suggestions taken

**Category: feature-request -> enhancement.** The platform check rejected feature-request and it is
right. Every line of `solution.patch` lands inside machinery grmtools already has: the yacc reader
gains a list to parse, `complete_and_validate` gains a pass, `warnings` gains a source, and the LR
table and error recovery consume the result unchanged. Nothing stands alone as a new subsystem. The
title verb reads like an addition, but the placement is what the category asks about. Corrected in
DESIGN.md and feedback.md.

**All three coverage suggestions taken; all three behaviours were already correct.**

- A quoted token holding `>` does not close the argument list, as a single argument and as the first
  of two. This is the companion of the comma and `<` cases and closes the delimiter set.
- Inferred precedence really does scan for the last *token*, not the last symbol: a production
  `'i' Op E` ending in a rule still takes `Op`'s precedence, checked with two instantiations whose
  tokens have different precedence so the assertion cannot pass by accident.
- Wrong arity and arguments-on-an-ordinary-rule in `%start` and `%expect-unused` now assert the call
  span, not just rejection, matching what the unknown-name case already did.

`solution.patch` is unchanged for the fourth round running.

Counts after this round: 133 tests, 133 of 133 fail on base, 561 human-effective LOC across 4 files
(raw 793), meta 486 words unchanged, base 293 green in both apply orders, 3 runs of each mode
identical, offline container green.

## Batch 1 diagnosis — 0 of 9, and no band exists on this axis

**What happened.** Nine platform runs, zero passes. Seven of the nine failed only on the
diagnostic-span family; Nova 2 failed on a single test out of 133. Orion additionally failed the
nested-ordering trap. Two runs produced no usable result (one never landed an implementation, one
produced no artifacts).

**Why the span family killed everything.** grmtools' own `mk_error(kind, off)` builds
`Span::new(off, off)`, a zero-length span. Every agent used it, because it is the repository idiom
for parser errors. My description required a covering span for malformed lists and duplicate
parameters, so the reference had to bypass `mk_error` for exactly those paths. The requirement was
stated, so it was arguably fair, but it fights the codebase's own convention on a detail orthogonal
to the feature, and it was the sole blocker for six agents. That is the unfair-biter shape: a rate
held down by something that has nothing to do with the capability being tested.

**Removing it does not save the pick.** I dropped the five idiom-fighting span tests and the clause
behind them, then replayed all seven agent patches against the trimmed 128-test suite:

| Agent | Result on the trimmed suite |
| --- | --- |
| Nova 2, 3, 4, 6, 8 | PASS |
| Nova 1 | 1 failure |
| Orion | 5 failures (nesting order) |

That is 5 of 9 = 56%, over the 40% cap. So the artifact sits between 0% with an unfair biter and 56%
without it. There is no wording that lands it in band.

**The functional axis is exhausted, and I measured it rather than guessing.** I replayed every agent
patch against 35 adversarial probes: deep interleaved nesting with shared subterms, recursion that
spawns a fresh instantiation, two argument sets each self-recursive, an argument declared after its
call site, a parameter shadowing a rule name, an argument whose own type mentions the parameter
letter, the same instantiation demanded from a production and `%start` and `%expect-unused`, the 128
limit reached by nesting, token arguments forwarded twice, empty productions inside recursion, and
three-parameter positional calls with repeats. Six of six working Nova runs matched the reference
byte for byte on every functional probe; Nova 4 diverged on nothing at all. Only Orion diverged, and
only on nesting order.

**Root cause is the pick, not the execution.** A grammar-to-grammar desugaring is a single-subsystem
mechanical transform: once the contract is stated fairly, Nova transcribes it. This is the death class
my own pick notes name, and I took the risk knowingly at selection time. Adding more traps on the same
axis is Pattern 17 futility, and the differential proves it: there is nothing left on this axis to
trap.

**Recommendation.** Shelve this feature and keep the host. grmtools itself cleared every hard gate and
is still exclusive, permissive, active and offline-green in 2.6 seconds. What the batch shows is that
difficulty has to live in DOING rather than transcribing, which means a feature inside the CPCT+ error
recovery engine or the LR table construction, not a pre-pass that hands an ordinary grammar to
machinery that already works.

## Post-batch state, and what is knowingly left open

Decision taken: keep the artifact, fix it, do not shelve and do not harden further.

What changed after the batch: the five idiom-fighting span tests are gone
(`a_malformed_list_error_points_at_the_bracket`, `an_unclosed_list_error_points_at_the_bracket`,
`a_malformed_separator_error_points_at_the_bracket`,
`a_malformed_list_in_a_directive_points_at_the_bracket`,
`a_duplicate_parameter_error_points_at_the_repeated_name`), and the description clause behind them now
reads "An error points at the call it objects to, or at the name where there is no call", which is the
part every agent got right because it follows the repository's own symbol-span convention. The
call-pointing span tests stay. `solution.patch` is untouched: the covering spans it produces for
brackets and repeated parameters are still there, simply no longer required by any test or clause.

Artifact state: 128 tests, 128 of 128 fail on base, base 293 green in both apply orders and after
reverse-apply, 3 runs of each mode identical, offline container green as uid 1000, 561
human-effective LOC across 4 files, meta 474 words.

Open and unresolved by choice: on the replayed batch this artifact sits at 5 of 9, about 56%, above
the 40% too-easy cap. The differential harness says there is nothing left to trap on the desugaring
axis, so a further round on the same feature is not expected to move that. Recorded here so the number
is not a surprise later.
