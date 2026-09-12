# pyparsing parse enumeration — Olympus submission

Repository: <https://github.com/pyparsing/pyparsing> (Python, MIT, 2.5k stars, pushed 2026-07-19)
Base commit: `d3388aaf5c60d1069b7294a743ccd0e7c87a1d1d`

## Why this pick

Hunted against `HARDENING.md` (arsenal + CONTRACT-STATED/FIX-HIDDEN), `TOO-EASY.md` (death-class
taxonomy) and `PICK-FILTER.md` (10 gates). Killed on the way in:

- **moka** (invented eviction tier) — repo issue #591 "several unit tests are flaky due to
  `thread::sleep`" = Gate 9 NO-FLAKY-REPO reject.
- **amaranth** (stream arbiter/router) — the approved `amaranth-stream-width-converter` already ships
  Arbiter/Demux/Fork/Join, so the whole stream-primitive family is taken (dedup).
- **PoloDB** — vendors RocksDB (C++ FFI), offline env-quality risk.
- **omegaconf** (Union types) — already implemented upstream across ~8 merged PRs (exclusivity dead).
- **pyparsing error recovery** (first idea in this repo) — killed on LOC-CEILING + uniform-wrap:
  `SkipTo` + `MatchFirst` + a parse action reproduce most of it in five lines, so the golden compresses.
- **ytt / egg / s2-style toolkits** — recallable-standard or no genuine missing core.

What survived: pyparsing has no way to see more than one parse of an ambiguous grammar, and the
capability cannot be composed from what exists (`scan_string` gives one parse per *start location*,
never two at the same location). It is a genuinely missing core rather than an extension of present
machinery, and it forces per-class work in the sequence, alternation, repetition, optional, lookahead,
wrapper and recursion paths.

## Difficulty design (see DESIGN.md §6 for the full matrix)

Lead trap is S3 (baseline preservation through the shared parse chokepoint: every enumerated parse must
travel the `preParse` -> `postParse` -> results-name -> parse-action path that `_parseNoCache` owns, and
the tempting generalisation of `_parse`/packrat regresses the 2025-test baseline). Stacked with S1
(recursion marker leaked when a generator is abandoned -> parses silently vanish in a *later* call),
P2 over-eagerness (buffering every parse before yielding breaks the laziness contract), S2 (the four
documented ordering rules compose into exactly one correct total order) and an architecture-forcing
wall (`parse_all` must report a whole-input parse that `parse_string` itself cannot find, which kills
any "wrap `parse_string` and perturb it" implementation).

### Trap reproduction (mutation proof, 14 natural-but-wrong choices)

Each mutation was applied to the reference and the new suite re-run; clean reference = 122/122 pass.

| Mutation (the natural wrong choice) | new tests failed |
|---|---|
| buffer all parses before yielding (no laziness) | 3 |
| a rejected parse ends enumeration instead of being skipped | 4 |
| skip `postParse` per parse (wrapper fidelity) | 43 |
| repetition yields fewest repetitions first | 25 |
| sequence varies its first element fastest | 13 |
| `Or` in operand order instead of longest-first | 5 |
| `MatchFirst` alternatives reversed | 15 |
| no recursion guard (left recursion) | 2 |
| recursion marker never released | 6 |
| `parse_all` not honoured | 8 |
| wrappers yield a single parse | 21 |
| `Each` yields a single parse | 1 |
| repetition sorted globally by count (FP candidate) | 49 |
| error stop `-` ignored, backtracks instead (FP candidate) | 1 |

No mutation survives, and no trap is discharged by a single fix: the ordering, laziness, pruning,
recursion-state and wrapper walls are each caught by a different group of tests.

## Validation

- 4-cell + reverse-apply, all in Docker, `--network none`, `--user 1000:1000`:
  BASE/base 2025 pass · BASE/new 122/122 FAIL (F2P clean, zero vacuous passes) ·
  SOL/base 2025 pass (zero regressions) · SOL/new 122 pass · solution-applied-first 122 pass.
- Flakiness gate: 3x both modes in the container, identical results every run; repo baseline also 3x
  identical before any change (2025 passed / 27 skipped).
- LOC: `human-effective 451`, raw 667, 3 files (clears the 430 design target and the 400 auto-block).
- meta.md: 486 words, ASCII, no em dashes, no code fences, backticks only on new API names.
- Comment convention: pyparsing docstrings every public method, so the new methods carry concise
  docstrings; only two inline comments added (a non-obvious invariant) plus the `# enumeration.py`
  module header the repo uses on every module. Test bodies carry no comments.

## FP check (both directions)

Every meta sentence maps to at least one discriminating test, and every test traces to a sentence.
Two gaps were found and fixed while doing it:

1. `stop_on` and bounded repetition were tested but only inferable from the repo -> added the clause
   "one still honors its bounds and its stop sentinel" (one generic clause, not an enumeration).
2. Tab expansion and ignored-expression handling were tested but unstated -> covered by "over the same
   tab-expanded input `parse_string` uses" plus the existing start-location clause (see round 1 below).

One test was **removed** as over-prescriptive: it asserted the parse-action start locations
`[0, 3]` for inner matches, which pins how often an implementation recomputes inner parses rather than
any documented behaviour. A correct implementation that recomputes would have failed it.

## Description-Quality review round 1 (platform AI check, `error.txt`)

Verdict `request_changes` on one HIGH plus two optional suggestions. Applied:

- **HIGH (fixed):** deleted "Ordinary parsing is unchanged." — a generic don't-regress statement. The
  base suite still enforces it and `test_parse_string_still_works_after_an_enumeration` stands on the
  universal no-regression default rather than a meta sentence.
- **MEDIUM (fixed by folding, not deleting):** the standalone sentence "Whitespace, ignored expressions
  and tabs are handled as `parse_string` does." is gone; tab handling moved into the yield-shape sentence
  ("over the same tab-expanded input `parse_string` uses") so
  `test_tabs_are_expanded_as_in_parse_string` keeps a documented anchor. Deleting outright would have
  left a tested behaviour undocumented, which is the more expensive failure (Test Fairness).
- **LOW (kept deliberately):** "although `Or` examines its alternatives to order them" stays. It is not
  an implementation note but a scope limit on the laziness contract: `^` has to materialise its
  alternatives to order them by match length, so the absolute reading ("no action ever runs before its
  parse is yielded") would be false of any correct implementation, including the reference. Removing it
  would make the spec wrong rather than shorter.

meta.md is now 493 words, still ASCII, no other content changed; patches and tests are unaffected.

## Review round 2 (`error.txt`: quality check + description check)

**Problem-and-tests quality — WARNING, three coverage suggestions, all three added** (per the standing
rule that a named coverage gap gets a test, not an argument):

1. `test_action_raising_parse_exception_discards_only_that_parse` — a parse action (not just a
   condition) raising a non-fatal `ParseException` removes its own parse and enumeration continues.
2. `test_start_is_reported_after_leading_ignored_expressions` — start reflects a skipped leading
   comment, not only whitespace.
3. `test_each_with_a_repeated_member_yields_the_ordinary_parse` — the `Each` repeated-operand path.

Suite was 81 tests after this round; all three fail on base, and the mutation matrix picked up two extra
discriminators (rejected-parse-ends-enumeration 1 -> 2, wrappers-single-parse 12 -> 13).

**Description quality — second `request_changes`, one HIGH. Applied:**

- **HIGH (fixed):** deleted "Any other expression yields the parse ordinary parsing produces." The
  per-class rules already cover every form that can be ambiguous, and an unambiguous expression having
  one parse is the base parser's own behaviour.
- **MEDIUM (fixed):** dropped "; the third yields strings." and the `NotAny` restatement. `NotAny`'s
  "no parse" condition is its standard semantics, so the lookahead sentence now stops at the zero-token
  rule; `test_not_any_*` rest on that plus the library's own contract.
- **LOW (fixed by relocation, not deletion):** the `Or` examination clause moved out of the laziness
  sentence and onto the `Or` ordering rule, where it reads as part of the ordering contract. It cannot
  simply be deleted: `^` has to look at its alternatives before it can order them by length, so an
  unqualified "no action runs before its parse is yielded" would be false of any correct implementation.
- **MEDIUM (kept deliberately):** the `parse_all` consequence clause ("a parse covering the whole input
  is reported even where the greedy parse `parse_string` settles on stops short"). It is not decoration:
  it is the only statement that tells a solver enumeration must look past the greedy path, and it is the
  anchor for `test_parse_all_finds_a_parse_that_parse_string_does_not`, the architecture-forcing wall.
  Deleting it would leave that test undocumented.

meta.md is now 468 words.

## Review round 3 (`error.txt`)

Description check flagged 2 HIGH + 3 MEDIUM; **all five applied**, because this round every one is a
genuine entailment of a rule that stays in the meta, and three of them also help difficulty by
de-enumerating instances (HARDENING Rule 7 - agents do not expand general to instances reliably):

- **HIGH:** dropped the wrapper instance list (`Group` nests / `Suppress` drops / `Combine` adjacency /
  results names). "Wrappers transform each parse exactly as they transform an ordinary one" entails all
  four, and the five wrapper tests now hang off the general rule instead of a checklist.
- **HIGH:** dropped "the first parse yielded is the one `parse_string` returns" - entailed by
  "most-preferred first, preference being the order the ordinary parser tries things".
- **MEDIUM:** dropped "one still honors its bounds and its stop sentinel" (added in round 1). The
  reviewer's own argument is the fairness argument: a repetition ignoring `stop_on` produces something
  the ordinary parser never would, which the preference principle already forbids.
- **MEDIUM:** dropped the `parse_all` consequence clause I defended in round 2. Re-checked the
  entailment: the first paragraph already says the methods "walk them all", so all-parses-then-filter
  follows, and `test_parse_all_finds_a_parse_that_parse_string_does_not` stays anchored. Removing it
  also stops spotlighting the architecture wall (giveaway audit).
- **MEDIUM:** dropped the determinism claim; it is a universal default and the flakiness gate enforces it.

meta.md is now 396 words. The three advisory coverage suggestions were also added (they do not affect the
check result, but a named gap gets a test):

1. Zero-width progress + parity, covering both methods and both expression kinds the suggestion named:
   `test_scan_of_a_zero_width_expression_matches_scan_string` (`FollowedBy`),
   `test_scan_of_a_string_end_expression_terminates_like_scan_string` (`StringEnd`) and
   `test_transforms_of_a_zero_width_expression_match_transform_string`. Each asserts equality with the
   existing `scan_string` / `transform_string` output, so a zero-width expression must make forward
   progress rather than stall or report a zero-length match.
2. `test_packrat_does_not_change_how_often_actions_run` - action counts identical with packrat on/off.
3. `test_scan_unique_keeps_the_same_tokens_found_at_other_locations` - pins the dedup scope when the same
   tokens recur at a different location.

Suite is 86 tests; all fail on base, mutation matrix unchanged (every mutation still caught), flakiness
3x identical, base suite still 2025 pass.

## Test Fairness round 1 (`error.txt`) - FAIL, 3 of 86 unfair, now resolved

All three flagged tests were the state/reuse trio, and the cause is direct ping-pong between the two
AI checks: the Description check made me delete "Ordinary parsing is unchanged." (round 1, HIGH) and the
determinism claim (round 3, MEDIUM), and Test Fairness then flagged the tests those sentences anchored.
Fairness is the hard gate (FAIL, not a suggestion), so it wins. Resolution per flagged test:

- `test_recursion_state_is_released_after_a_partial_enumeration` - **KEPT and anchored.** This is the S1
  discriminator (the marker-leak mutation fails exactly this test and nothing else), so deleting it would
  remove the strongest trap's only witness. Added one specific sentence: "An enumeration that is
  abandoned, or stopped early by `max_parses`, leaves nothing behind, so the same expression enumerates
  again in full." That states the contract without revealing where the state lives or how to release it.
- `test_parse_string_still_works_after_an_enumeration` - **DELETED.** Redundant: base mode runs the whole
  2025-test suite against the patched tree, so a solution that corrupts ordinary parsing already fails.
- `test_repeated_enumerations_return_the_same_parses` - **DELETED.** Redundant: the flakiness gate runs
  the suite three times, and determinism is a universal default.

Deleting is safe here because no platform batch has run yet, so no F2P node ids are being tracked.

The round's three advisory coverage suggestions were also added: two parse actions running in declaration
order per parse; `ParseException` / `ParseFatalException` behaviour for `enumerate_scan` and
`enumerate_transforms` (not just `enumerate_parses`); and packrat-on/off parity for scan and transforms.

Suite is 90 tests, all failing on base. The new tests strengthened three mutations
(rejected-parse-ends-enumeration 2 -> 4, skip-postParse 24 -> 29, wrappers-single-parse 13 -> 16).

## Coverage round (`error.txt`, advisory only) - all three added

1. `test_scan_reports_start_after_ignored_expressions_at_each_location` - `enumerate_scan` reports
   `start` after leading whitespace and comments at every scanned location, not just the first.
2. `test_scan_after_an_abandoned_scan_yields_every_parse` and
   `test_transforms_after_an_abandoned_enumeration_yield_every_result` - abandoning a scan or transform
   iterator early leaves no residual recursion / dedup / limit state; both anchored by the
   leaves-nothing-behind sentence added in the fairness round, which covers all three enumerators.
3. `test_parse_all_reaches_the_end_over_ignored_trailing_text` - `parse_all` judges end-reaching parses
   after the same ignore handling ordinary parsing uses (trailing comment skipped).

Suite is 94 tests. The two abandonment tests also widened the S1 witness: the recursion-marker-leak
mutation now fails 2 tests instead of 1, and `parse_all`-not-honoured 3 -> 4, wrappers-single-parse
16 -> 17.

## Coverage round 2 (`error.txt`, advisory) - one suggestion found a REAL bug

**`max_parses=0` was inconsistent in the reference.** `enumerate_scan` guards its loop condition and
yielded nothing, but `enumerate_parses` and `enumerate_transforms` checked the limit only *after*
yielding, so both handed back one parse for `max_parses=0`. Fixed with an up-front guard in both drivers
(`if max_parses is not None and max_parses <= 0: return`), which also keeps the laziness contract: the
guard returns before `_enumerate` is touched, so no parse action runs at all. The post-yield check stays,
because moving it before the yield would compute the next parse - and run its actions - before stopping.

Tests added for both suggestions:

1. `test_zero_max_parses_yields_nothing_and_runs_no_actions` - all three enumerators yield nothing at
   `max_parses=0` and the parse action is never called.
2. `test_fatal_condition_propagates_from_every_enumerator` - `add_condition(..., fatal=True)` propagates
   `ParseFatalException` out of parse, scan and transform enumeration, as a fatal action does.

Suite is 96 tests; solution.patch regenerated (human-effective 408 -> 412, raw 607). Full re-validation
green: 4-cell + reverse-apply, flakiness 3x, and all 12 mutations still caught (four of them by more
tests than before).

## Coverage round 3 (`error.txt`, advisory) - one suggestion exposed a spec ambiguity

1. `test_yielded_items_match_the_shape_of_the_exported_alias` - the yielded item is a 3-tuple of
   (`ParseResults`, int, int) from both `enumerate_parses` and `enumerate_scan`, not merely a name that
   exists. Deliberately asserts the RUNTIME shape rather than `typing.get_args(EnumeratedParse)`: pinning
   the alias's spelling would reject a solver who writes it as a `NamedTuple`, which the description
   permits.
2. `test_transforms_max_parses_counts_the_results_it_yields` - built a grammar where two parses collapse
   to one transformed string and a third gives another, so `max_parses=2` discriminates: counting yielded
   strings gives `['X', 'Yb']`, counting raw parses examined would give `['X']`.

The second suggestion found a genuine gap in the description, not just in the tests: "`max_parses` stops
the enumeration after that many parses" does not say whether "parses" means results yielded or parses
examined, and for `enumerate_transforms` those differ once deduplication drops one. Reworded to "stops
the enumeration once that many results have been yielded", which settles it for all three enumerators.

Suite is 98 tests, meta 420 words; re-validated green (4-cell, flakiness 3x).

## Coverage round 4 (`error.txt`, advisory) - both added

1. Parse-action `(s, loc, toks)` conventions, one test per enumerator:
   - `test_actions_receive_the_tab_expanded_string_and_match_locations` - with a tab and an ignored
     comment in the input, every action call sees the tab-expanded string and a location that points at
     the match in that string. Asserted as SETS of strings and locations, not as an ordered call list:
     the multiplicity depends on how often an implementation recomputes an inner match, which the
     description does not fix. (An earlier ordered version of this test was removed for exactly that
     reason during the FP check; the set form keeps the behaviour without pinning the internals.)
   - `test_scan_actions_see_the_same_string_and_locations_as_scan_string` and
     `test_transform_actions_see_the_same_string_as_transform_string` - use the existing APIs as the
     oracle, which also pins the `transform_string` tab convention (transforms keep tabs, the other two
     expand them).
2. `test_enumerated_parse_alias_can_be_imported_directly` - `from pyparsing import EnumeratedParse`
   works and the name is in `pp.__all__`. The import sits inside the test body on purpose: at module
   level it would turn the base run into a collection error instead of 102 named test failures.

Suite is 102 tests; re-validated green (4-cell, flakiness 3x).

## Coverage round 5 (`error.txt`, advisory) - both added

1. `test_skip_to_passes_over_targets_inside_ignored_text` - a comma hidden inside a `#` comment is not a
   candidate target, while the two real commas after it are, nearest first. Note for anyone editing this
   test: `SkipTo.ignore` returns `None` in pyparsing (unlike `ParserElement.ignore`), so it has to be
   called as a statement, never chained.
2. `test_mutually_recursive_grammar_terminates_and_resets` - `A -> Group(B) | atom`,
   `B -> Group(A + '!') | atom`. Enumeration terminates (the cut fires when the cycle re-enters `A` at
   the same location) and yields the same two parses again after a `max_parses=1` run and after an
   abandoned iterator.

The mutual-recursion case strengthened both recursion mutations: marker-never-released now fails 3 tests
(was 2) and no-recursion-guard 2 (was 1), so the S1 witness no longer rests on a single direct-recursion
test. Suite is 104 tests; re-validated green (4-cell, flakiness 3x).

## Test Fairness round 2 (`error.txt`) - FAIL, 2 of 104, fixed in the SPEC not the tests

Both flags were real ambiguities in my wording, so the discriminators stayed and the meta was tightened:

- `test_or_orders_across_operands_not_within_them`: the meta said `Or` "orders THEM by decreasing end
  location", where "them" reads as the alternatives. An alternative with parses at several end locations
  has no single end location, so the rule was undefined for exactly the case the test pins. Reworded to
  "orders all their parses together by decreasing end location, breaking ties by operand order".
- `test_each_enumerates_the_orderings_that_match`: the meta never said in what order the matching
  orderings come out. Added "taking its earliest-listed operand first at each step", which is the rule
  the reference implements and the one a solver derives from `Each`'s own left-to-right scan.

Novel semantics have to be stated (HARDENING 3b: de-enumerate INSTANCES, never the defining rule), so
this is the correct direction even though the description check prefers fewer words. meta.md 420 -> 431.

The round's three advisory suggestions were added as well:

1. `test_parse_all_keeps_every_parse_that_reaches_the_end` and `test_parse_all_survivors_can_be_deduplicated`
   - real ambiguity under `parse_all` (two distinct parses both reach the end), with `max_parses` and
   `unique` applied to the surviving set rather than to a single survivor.
2. `test_scan_overlap_of_a_zero_width_expression_matches_scan_string` - `overlap=True` on `FollowedBy`
   and `StringEnd`, asserted against `scan_string` as the oracle so the one-character advance and the
   termination behaviour match the existing API exactly.
3. `test_recursive_grammar_behaves_the_same_under_packrat` - a recursive grammar enumerates identically
   with memoisation on, and still resets after a `max_parses`-limited run.

Suite is 108 tests; re-validated green (4-cell, flakiness 3x).

## Coverage round 6 (`error.txt`, advisory) - all three added

1. `test_scan_overlap_restarts_from_the_first_parse_location` - a location with three parses, checked
   both ways: without `overlap` scanning resumes at the FIRST parse's end (so the later, shorter parses
   at that location do not move the cursor), with `overlap` it resumes one character on and the whole
   parse set repeats from each position.
2. `test_unique_counts_only_the_results_it_yields` and `test_scan_unique_continues_past_skipped_duplicates`
   - a grammar whose first two raw parses are duplicates and whose third is distinct, so `unique` has to
   skip past duplicates and keep going, and `max_parses` counts yielded unique results (4 raw parses ->
   2 unique -> `max_parses=2` still yields both).
3. `test_actions_on_recursive_nodes_run_once_for_each_yielded_parse` and
   `test_a_rejecting_action_on_a_recursive_node_leaves_the_other_parses` - actions on a recursive
   grammar: once per yielded parse (counted on the enumerated expression, not on an inner node, so the
   assertion does not pin how often an implementation recomputes inner matches), and an action raising
   `ParseException` inside the recursive node leaves the remaining parse while the recursion guard still
   resets afterwards.

Suite is 113 tests; re-validated green (4-cell, flakiness 3x).

## Solution Quality round 1 (`error.txt`) - FAIL, two real defects, both fixed in the SOLUTION

Both findings were correct code defects, not test or wording problems, so the reference changed:

1. **`Or` ran parse actions while ordering.** `Or._enumerate_impl` materialised every parse of every
   alternative through `_enumerate` (which finalises, so user actions ran) and only then sorted, so
   actions fired for parses nobody consumed and `max_parses` could not prevent them. Rewritten as the
   two-pass shape `Or.parseImpl` itself uses: an ordering pass with `do_actions=False` (no user actions)
   builds the plan, then `_enumerate_planned` finalises only the parse being yielded, caching each
   alternative's already-drawn parses so none is finalised twice. Measured: a two-alternative `^` with
   `max_parses=1` now runs 1 action (was 2), and full enumeration still runs exactly 2 in plan order.
   Ordering is unchanged (longest-first, operand-order ties, across-operand interleaving all still pass).
2. **`Located` was missing from the wrapper set.** It has a custom `parseImpl`, so it inherited the
   single-parse default and committed to its child's first parse. Added `Located._enumerate_impl`, which
   enumerates the child and rebuilds the `locn_start` / `value` / `locn_end` result per parse, including
   the results-name list form.

Meta: the laziness sentence now also states that ordering `^` "examines its alternatives in a pass that
runs no actions at all" - a testable contract, and the anchor for the new `Or` test. That is the honest
form: an absolute "nothing runs before its parse is yielded" is unachievable for `^`, because the
alternatives have to be examined before they can be ordered by length.

New tests: `test_or_orders_its_alternatives_without_running_actions`,
`test_located_enumerates_every_parse_of_its_expression`, `test_located_reports_the_span_of_each_parse`.

Side effects: human-effective LOC 412 -> **443** (clears the 430 target), suite 116 tests, and the
mutation matrix got sharper across the board (skip-postParse 32 -> 42, wrappers-single-parse 17 -> 20,
marker-leak 3 -> 5, parse_all 5 -> 8). Full re-validation green: 4-cell + reverse-apply, flakiness 3x.

## First solver run (Orion, eval Nova) - FAIL_TEST_MISMATCH blamed on the environment, fixed

Run: 163 agent messages, 3 files, 1133 solution LOC, baseline 2025 pass, **115 of 116 new tests pass**.
The evaluator marked the single failure as an environment bug (`agentBlameUnfair: true`, confidence
high): "Hidden verifier should document or revise its special-case treatment of a zero-width repetition
following consuming repetitions."

It was right, and the bug was mine. `_MultipleMatch._enumerate_impl` counted a zero-width body match as
a repetition **only when it was the first one of a `OneOrMore`** (`if not reps and min_reps`) and silently
dropped it after any consuming repetition. The meta says, without qualification, that "a body match that
consumes nothing counts as one repetition and then ends it", so the solver implemented the uniform rule -
the spec's rule - and my verifier rejected it. This is the FP class the mandatory check exists for: the
agent met the stated requirement, so the ENVIRONMENT was wrong.

Fixed in the solution, not the description: the branch is now `if reps + 1 >= min_reps`, so a zero-width
body match counts as one repetition and ends the repetition wherever it occurs. Consequences, all
consistent with the stated greedy ordering (more repetitions before fewer):

- `Group(Opt('a'))[1, ...]` on `'a'` -> `[[['a'], []], [['a']], [[]]]` (was `[[['a']], [[]]]`)
- `Group(Opt('a'))[...]` on `'a'` -> the same three plus the zero-repetition parse `[]`

`test_repetition_of_a_possibly_empty_expression_terminates` was updated to the uniform expectation and a
`ZeroOrMore` twin (`test_zero_or_more_of_a_possibly_empty_expression_terminates`) added, so the rule is
now pinned at both minimums and the special case cannot come back unnoticed. Expressions whose body
cannot match empty are unaffected (`word()[1, ...]` output unchanged), and the whole 2025-test baseline
is still green.

Difficulty note: one Orion run reaching 115/116 with a fair reading is NOT a difficulty verdict - per the
AGENT-MIX law Orion is the decisive long-horizon solver and reads far stronger than the standard mix
(gms: 80% all-Orion vs 20% mixed). The 163-message, 1133-LOC trajectory confirms the long-horizon shape.
A Nova-heavy batch is still required before judging the band.

## Synthesis round (`error.txt`): P6 prescriptiveness + S1 wrapper gap - both fixed

**P6 (High, description quality).** The meta prescribed the mechanism: "a `Forward` is not re-entered at
a location where it is already being matched". That names the reference's cycle-detection strategy, when
the requirement is only that enumeration terminates. Sentence cut to "Enumeration must terminate on a
recursive grammar." - the cleanup half was already covered by the earlier leaves-nothing-behind sentence,
so nothing became undocumented.

Cutting it forced a matching TEST change, which is the real point: `test_left_recursive_grammar_terminates`
and `test_mutually_recursive_grammar_terminates_and_resets` pinned exact parse lists that only my
cycle-cut strategy produces. A solver using a different legal termination strategy (seed growing, depth
bounding) terminates too and yields MORE parses, and would have failed a test whose requirement it met -
the same FP shape as the zero-width-repetition bug in the previous round. Both now assert what the
de-prescribed rule actually promises: the enumeration completes, the base-case parse is among the
results, and repeating it after a `max_parses` cut or an abandoned iterator gives the identical list.
Verified the traps survive: no-recursion-guard still fails 2 tests (RecursionError), marker-leak 6
(was 5). The exact-list S1 witness lives on in the right-recursive
`test_recursion_state_is_released_after_a_partial_enumeration`, where every strategy agrees.

**S1 (High, `core.py`).** `AtStringStart` and `AtLineStart` have custom `parseImpl`s, so they fell to the
single-parse default and committed to their contained expression's preferred parse, contrary to the
wrappers rule. Both now validate the position first and then delegate to `_enumerate_contained`, so an
ambiguous contained expression keeps all its parses. New tests
`test_positional_wrappers_enumerate_every_contained_parse` and
`test_positional_wrappers_still_refuse_the_wrong_position` pin both halves.

Suite 119 tests, human-effective LOC 451, meta 447 words; re-validated green (4-cell + reverse-apply,
flakiness 3x, base suite 2025).

## Coverage round 7 (`error.txt`, advisory) - both added

1. `test_scan_overlap_restarts_correctly_with_ignored_text` - `overlap=True` over `"abc # note\nde"`
   with comments ignored. Overlap genuinely bites here (`ab` at 0, `bc` at 1) and the comment is skipped
   before the next match at 11, so the restart arithmetic is exercised with skipping active; the
   non-overlap run of the same input is asserted alongside it.
2. `test_parse_all_spans_leading_and_trailing_ignored_text` - one end-to-end `parse_all=True` case with a
   leading comment and a trailing comment: `start` is reported at 8 (after the leading comment), and the
   trailing comment does not stop the parse from counting as end-reaching. Cross-checked against
   `parse_string(parse_all=True)` on the same input.

Suite is 121 tests; re-validated green (4-cell, flakiness 3x).

## FP CHECK round 1 - FALSE POSITIVE confirmed, both holes closed

The adjudicator flagged a passing agent that did not meet the prompt. Per the FP rule the fault is the
ENVIRONMENT, not the agent, and both holes were in my tests + wording, not in the reference (verified: the
reference already behaves correctly on both probes).

**Hole 1 - repetition ordering (decisive).** The candidate sorted `_MultipleMatch` parses by a global
`(-repetition_count, preference)` key, so for a body whose preferred alternative is longer -
`(Word(exact=2) | Word(exact=1))[1, ...]` on `'abcd'` - its first parse was `['a','b','c','d']` while
`parse_string` gives `['ab','cd']`, breaking the central first-equals-ordinary-parser invariant. My suite
only used unambiguous whitespace-separated bodies, so nothing discriminated. Worse, my own wording
invited the reading: "more repetitions come before fewer" IS a count sort. Reworded to "it takes the
body's parses in their own order and extends as far as it can before falling back to fewer repetitions",
and added `test_repetition_follows_its_body_preference_not_the_repetition_count`, which pins
first-equals-`parse_string` plus the full 11-parse order for that ambiguous body.

**Hole 2 - error stop (`-`).** The reference propagates the `And._ErrorStop` commitment
(`ParseSyntaxException`) out of all three enumerators, matching ordinary parsing, but I had deliberately
left `-` undocumented and untested at design time, so a candidate that silently backtracked instead
passed. Added one meta clause ("as does the commitment an error stop (`-`) makes, so a following element
that cannot match raises instead of backtracking") and
`test_error_stop_commits_in_every_enumerator`, covering the matching input plus the raising case in
parses, scan and transforms.

**Both holes are now mutation-proven.** Two FP-candidate implementations were added to the harness and
both die: `repetition-count-sort` fails 49 tests, `no-error-stop` fails 1. Clean reference 123/123.

Suite 123 tests, meta 486 words; solution.patch unchanged this round (the reference was already correct).
Re-validated green: 4-cell + reverse-apply, flakiness 3x, base suite 2025.

## Self-audit: `test_enumerated_parse_alias_can_be_imported_directly` relaxed

Reviewed on request. Solvable trivially, but one of its two assertions was NOT fair:
`assertIn("EnumeratedParse", pp.__all__)`. The meta says only "Export the name `EnumeratedParse` for that
triple". A solver who adds `from .enumeration import EnumeratedParse` to `__init__.py` satisfies every
stated requirement - the direct import works and `pp.EnumeratedParse` resolves - yet pyparsing's `__all__`
is a hand-maintained list the prompt never mentions, and it only affects `import *`. So that assertion
could fail an otherwise fully correct solution on unstated plumbing: the same defect shape the FP round
punished, inverted (over-pinning instead of under-pinning).

Replaced with `assertIs(EnumeratedParse, pp.EnumeratedParse)`, which still checks the export surface
without pinning `__all__`, and folded away the redundant `test_enumerated_parse_alias_is_exported`
(hasattr only) that the fairness report had already called partly redundant. Suite 123 -> 122 tests; no
discriminating power lost (no mutation ever failed on either assertion).

## FP audit of the passing Nova run (local, adversarial) - GENUINE PASS

Audited `Task2/Nova_Nova` (123/123 new, 2025/2025 baseline, `PASS_LEGITIMATE`) independently rather than
trusting the verdict. Method: applied its `solution-patch.patch` (source only) and the reference to two
clean worktrees at base and diffed behaviour.

- **76-probe targeted battery: 0 divergences.** Includes the two holes that sank the previous FP
  candidate (repetition body-preference ordering, error-stop commitment across all three enumerators),
  plus `Located` / `AtStringStart` / `AtLineStart` / `Dict` / `Combine` / `PrecededBy`, laziness counts,
  `Or` action-free ordering, empty-body repetition at both minimums, right/left/mutual recursion with
  reset, packrat parity, `max_parses=0`, `unique` with names, transforms dedup-vs-limit, `parse_all` over
  ignored text, scan overlap with ignores.
- **Differential fuzz, 600 random grammars over 3 seeds: 0 divergences** on plain / `parse_all` /
  `unique` / `max_parses=2` / scan digests (589 compared, 11 skipped where either side hit the
  known base-pyparsing empty-body `parse_string` hang or a recursion bound).
- **Ambient-state audit.** The one existing line it edits is in `_parseNoCache`: parse actions are also
  gated on a new class-level `ParserElement._enumeration_structural_depth`. That is the leak shape I
  test for, so I checked it directly: the counter is incremented inside a `try` whose `finally` restores
  it and there is **no `yield` inside that block**, so an abandoned generator cannot strand it. Probed
  anyway - ordinary `parse_string` still runs its actions after an abandoned enumeration and after a
  fatal-exception enumeration. No leak.
- **Only divergence found anywhere** is the number of times an INNER expression's action runs when the
  same sub-match appears in several parses (ref 2, Nova 3), because Nova re-evaluates a candidate per
  parse while the reference caches. That multiplicity is deliberately unpinned: it is exactly why
  `test_actions_see_the_start_location_of_their_own_match` was deleted during the FP check and why
  `test_actions_receive_the_tab_expanded_string_and_match_locations` asserts SETS. Nova's design is legal
  under the contract - arguably cleaner than the reference, since its deferred `evaluate()` thunks close
  the residual `Or` prefix-finalisation corner the reference still has.

Verdict: **not a false positive.** The agent met the stated contract; no test or wording change is
warranted from this run.

## Open item before submit

The local imitator probe (PROMPTS.md Query 13) has NOT been run — this session did not spawn solver
agents. The 10-run Nova/Orion batch remains the only difficulty oracle; predicted band 10-30%, with the
recursion-marker and laziness walls as the expected biters and the wrapper/ordering walls as the volume.
