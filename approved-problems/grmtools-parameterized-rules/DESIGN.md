# DESIGN.md — grmtools-parameterized-rules

## 1. Title

Add parameterised rules to the Yacc grammar reader

## 2. Shape classification

- Shape: O-Composite-add (a new capability spanning the grammar reader, the AST, a new expansion pass, and everything downstream that consumes the expanded grammar).
- Pass-rate target: the sprint cap is 40%; designed toward the corpus mode of 1/10.
- Best agent: Vega or Orion (long-horizon, multi-file).
- Dominant verdict expected: MISSED_REQUIREMENT (ordering, type substitution, token arguments) and INTEGRATION_ERROR (orphaned production slots).

## 3. Public API surface

- `ast::Rule.params: Vec<(String, Span)>` — the parameters of a parameterised rule, in written order; empty for an ordinary rule.
- `GrammarAST::add_rule_with_params((String, Span), Vec<(String, Span)>, Option<String>)`.
- `GrammarAST::add_rule` keeps its signature and delegates with no parameters.
- New `YaccGrammarErrorKind` variants: `IncompleteMacroCall`, `DuplicateMacroParameter(String)`, `UnknownMacroRef(String)`, `MacroArityMismatch(String, usize, usize)`, `MacroWithoutArguments(String)`, `UnexpectedMacroArguments(String)`, `MacroTokenArgumentType(String)`, `MacroStartRule(String)`, `MacroExpansionLimit`.
- No new method on `YaccGrammar`: expansion happens before it is built, so `rules_len`, `rule_name_str`, `rule_idx`, `actiontype`, `action`, `prod`, `prod_precedence` and `pp_prod` all describe the expanded grammar.

## 4. Canonical output form

- Instantiated rule name: the parameterised rule's name, `<`, the argument names separated by `,` with no spaces, `>`. A token argument is written between single quotes there, so `Sep<E,','>`.
- Argument names are themselves already expanded, so a nested call reads `Group<Opt<E>>`.
- Ordering: arguments before the call that needs them; instantiated rules appended after every rule written in the file, in the order each distinct name was first required.
- Deduplication: one rule per distinct instantiated name, so a rule that uses itself with its own arguments reuses the rule being built.
- Type substitution: whole-identifier occurrences only, replaced by the argument rule's declared type.
- Empty input: a grammar with no parameters and no calls is left untouched.
- Limit: more than 128 instantiations is `MacroExpansionLimit`.

## 5. Blind-spot pre-empts

- iteration termination: "A rule may use itself with the arguments it already has, which reuses the rule being built rather than starting another."
- result ordering: "the new rules follow every rule the file writes, ordered by when each name was first needed".
- dedup: "Each distinct set of arguments yields one rule."
- rule resolution: "Inside the body every use of a parameter becomes the argument it was given."

## 6. Description draft

See `meta.md` (about 400 words, under the 500-word hard cap; every clause is mapped to a test in `feedback.md`).

## 7. File footprint

| Action | Path | Raw delta | Human-effective |
| --- | --- | --- | --- |
| NEW | cfgrammar/src/lib/yacc/expand.rs | +530 | 364 |
| MODIFY | cfgrammar/src/lib/yacc/parser.rs | +146 | 112 |
| MODIFY | cfgrammar/src/lib/yacc/ast.rs | +26 | 18 |
| MODIFY | cfgrammar/src/lib/yacc/mod.rs | +1 | 1 |

TOTAL: 793 raw / 561 human-effective across 4 files, clearing the 430 design floor.

## 8. Solution outline

- `parse_rule_params` reads a parameter list that must follow a rule name with no intervening whitespace, rejecting duplicates.
- `parse_call_args` reads an argument list recursively, accepting names, nested calls and quoted tokens, and renders the canonical instantiated name. It is reused by the production body, by `%start` and by `%expect-unused`.
- `expand::expand_params` is the kernel. It collects the parameterised rules, resolves the `%start` call first, then walks every ordinary production. `Expander::resolve` recurses into arguments, memoises the instantiated name before expanding the body (the termination condition), substitutes parameters in symbols and in the declared type, and appends the new rule.
- `ast.rules` and `ast.prods` are then rebuilt so the parameterised rules disappear and no production is orphaned.
- `complete_and_validate` runs the expansion before its existing checks; `warnings` reports a parameterised rule nothing instantiated as an unused rule.

Helpers, one per described behaviour: `parse_call` and `Call::render` (canonical naming), `Call::substitute` (parameter substitution inside a nested call), `call_open` and `quoted_token` (quote-aware scanning), `mentions_ident` (the token-argument-in-a-type check), `substitute_idents` (whole-identifier type substitution), `Expander::token_arg` and `Expander::symbol_for` (token versus rule arguments), `Expander::actiont_of` (the type of an argument, whether written or instantiated).

## 9. Test file outline

- `cfgrammar/tests/params_d799b2.rs` (105 tests): builder helpers `grmtools` / `original` / `ok` / `error`, assertion helpers `rules` / `types` / `prods` / `actions` / `warnings`, then tests grouped by instantiation, ordering, recursion, type substitution, token arguments, entry points, errors and warnings.
- `lrlex/tests/params_parse_d799b2.rs` (23 tests): a runtime lexer plus state table, asserting real parse trees, conflict counts and error recovery through instantiated rules.

Both are separate cargo test targets, so base mode (`cargo test --workspace --lib --bins`) runs exactly the repository's own tests.

## 10. Forced bounds

None. The feature is entirely inside cfgrammar's own types; the integration test needs `lrtable` as an `lrlex` dev-dependency, which ships in test.patch.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt sentence | Catching test |
| --- | --- | --- | --- | --- |
| 1 | memoise before recursing | the natural recursive expansion of `List<T>: List<T> ',' T` never returns | "reuses the rule being built rather than starting another" | `recursion_makes_one_rule_only` |
| 2 | expand arguments first | outside-in expansion leaves an unexpanded call in the body | "Arguments are built before the call that uses them" | `arguments_are_instantiated_before_the_call_that_uses_them` |
| 3 | instantiation order is observable as rule indices | nothing in the failing assertion mentions ordering | "the new rules follow every rule the file writes" | `instantiation_order_follows_first_use` |
| 4 | whole-identifier type substitution | a naive replace corrupts `TMap<T,T2>` | "each whole-word occurrence of a parameter" | `a_type_naming_a_parameter_inside_a_longer_word_is_untouched` |
| 5 | a token argument must become a token symbol | otherwise the grammar reports an unknown rule far from the call | "a parameter given a token stands for that token" | `a_token_argument_becomes_a_token_in_the_body` |
| 6 | rebuilding the production list | orphaned productions panic inside an unrelated `unwrap` | implied by "is not a rule of the resulting grammar" | every test that builds a grammar |
| 7 | entry points other than a production | only walking productions drops the grammar's only instantiation | "and also in `%start` and in `%expect-unused`" | `a_call_only_in_the_start_declaration_is_still_instantiated` |

## 12. Tier and category

Olympus, enhancement. The change is written into the existing yacc reader, table builder and warning path rather than adding a standalone subsystem, so the platform's category check reads it as an enhancement; recorded here after that check rejected feature-request.

## 13. Predicted pass rate

Predicted 10-30% before any batch. Measured: 0 of 9 as submitted to the batch, and 5 of 9 (56%) after the idiom-fighting span tests were removed. See eval-results.md.

## 14. Quality gate

- Repo understanding: five crates, their boundaries, the entanglement between the grammar reader and the LR table builder, the test framework and a template test file all established before any code.
- Existing PR check: `gh pr list -R softdevteam/grmtools --state all --search "macro|repetition|ebnf|parameterized|optional"` and the equivalent issue searches return no hit that touches this capability; `gh api repos/softdevteam/grmtools/branches` shows only `master`, `staging`, `trying`, `gh-pages`.
- Closest approved problems opened as scaffolding: `iwe-anchored-links` (a resolution kernel feeding several unrelated surfaces) and `ezno-enum-declarations` (a pinned, exactly-specified language feature).
- Corpus recipe: one interdependent kernel (`Expander::resolve`) drives grammar structure, Rust types, the LR table and error recovery; every new error variant and the canonical name form are pinned in meta.md; the feature is not a portable spec.
- LOC, files, tests, apply orders, flakiness, offline container: all recorded in `feedback.md`.

## Why this is not a duplicate

Closest local work: `Aprroved/starlark-go-format-spec` and `Aprroved/customasm-for-directive` both add a directive to a language, but neither touches grammar generation. No problem in `problems/`, `rejected/`, `Aprroved/` or `Olympus/` targets grmtools or any parser generator. The differentiator is that the new code is a grammar-to-grammar expansion whose output is consumed by an LR table builder, not a runtime evaluator.

Predicted iteration cycles: 2.
