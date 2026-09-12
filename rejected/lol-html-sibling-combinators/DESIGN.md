# DESIGN.md — lol-html-sibling-combinators

## 1. Title

Add sibling combinator and selector list support to the matcher

Repo: `cloudflare/lol-html` (BSD-3-Clause, 2043 stars, last commit 2026-07-29).
BASE_COMMIT `608cc4a66b7ab4fcbe1bbdeb25df8f265572b11c`.

## 2. Shape classification

- Shape: **O-Composite-add** — a new capability threaded through parser, AST, compiler,
  instruction format, matching stack and VM execution.
- Pass rate target: <= 40% ceiling (2026-07 sprint). Design intent is the hard edge, 10-25%.
- Best agent: mixed; Orion expected to be the load-bearing solver (AGENT-MIX law).
- Dominant verdict predicted: MISSED_REQUIREMENT, with a REGRESSION tail from the repo's own
  W3C conformance fixtures.
- Span: 8 files across 1 crate but 5 distinct pipeline stages of the selector subsystem.

## 3. Public API surface

Nothing is added to the public Rust API. The surface that changes is the **selector language**
accepted by `Selector::from_str` / the `element!` macro:

- `a + b` — adjacent sibling combinator, previously `SelectorError::UnsupportedCombinator('+')`
- `a ~ b` — general sibling combinator, previously `SelectorError::UnsupportedCombinator('~')`
- `:is(x, y, ...)` — selector list, previously `SelectorError::UnsupportedPseudoClassOrElement`
- `:where(x, y, ...)` — same semantics as `:is()` here (lol-html models no specificity)
- combinators inside `:is()` / `:where()` — still `UnsupportedPseudoClassOrElement`
- everything else the matcher rejects today keeps its current error

## 4. Canonical output form

Matching is reported through `MatchInfo`; the observable form in tests is the ordered list of
matched elements in document order. Rules spelled out in meta.md:

- Sibling set: elements sharing a parent element; top-level elements are siblings of each other.
- `+`: the immediately preceding **element** sibling. Text/comments do not separate elements.
- `~`: any preceding element sibling.
- Scope: never crosses a parent boundary in either direction (not into a following element's
  subtree, not out of the enclosing element, never between an element and its own descendants).
- Content-less elements (void elements, self-closing foreign elements) are ordinary siblings,
  both as the left operand and as an element standing between two others.
- `:is()`/`:where()`: match when **any** alternative matches. Each alternative is a compound
  selector.
- An element matching several alternatives matches once.

## 5. Blind-spot pre-empts

Applied from the sentence bank:

- *Adjacent vs all-positions* — "`a + b` matches an element matching `b` whose immediately
  preceding element sibling matches `a`" plus "`a ~ b` ... any preceding element sibling".
- *Compound order preservation / composition* — final paragraph states that selector lists
  compose on either side of any combinator and that sibling combinators chain and mix with
  child/descendant.
- *Falsy-on-invalid* — "every construct the matcher rejects today keeps being rejected".

Codebase-inferable requirements: **1** (that `ChildCounter`-style per-parent state is the
repo's existing idiom for sibling-position information). Everything else is stated.

## 6. Description draft

See `meta.md` (345 words, ASCII, no headers, no formulaic labels). Opens with the ask
(`Add the sibling combinators ... to the CSS selector matcher ...`) per
`DESCRIPTION.md § HARD RULE - The FIRST SENTENCE of the body`.

## 7. File footprint (measured, not sketched)

| Action | Path | Raw delta | Reason |
|---|---|---|---|
| MODIFY | `src/selectors_vm/parser.rs` | +34/-9 | accept `+`/`~`; validate `:is()`/`:where()` alternatives; opt into `parse_is_and_where` |
| MODIFY | `src/selectors_vm/ast.rs` | +72/-11 | two new branch vectors on `AstNode`; `AlternationExpr` on `Predicate`; routing in `add_selector` |
| MODIFY | `src/selectors_vm/compiler.rs` | +99/-19 | recursive predicate compilation; alternation to a full-expression closure |
| MODIFY | `src/selectors_vm/program.rs` | +24/-6 | third expression phase on `Instruction`; two new `ExecutionBranch` ranges |
| MODIFY | `src/selectors_vm/stack.rs` | +64/-0 | `SiblingScope`, per-item and root scope, arm/take/read |
| MODIFY | `src/selectors_vm/mod.rs` | +141/-9 | sibling jump execution, bailout pointer, arming at every terminal site |
| MODIFY | `src/selectors_vm/match_info.rs` | +6/-0 | `Default` for `DenseHashSet` |
| MODIFY | `src/selectors_vm/error.rs` | +2/-1 | mark the now-unreachable `UnsupportedCombinator` unused, matching the repo's own `EmptyNegation` precedent |
| MODIFY | `src/selectors_vm/tests.rs` | +4/-2 | existing in-source tests follow the signature change |

TOTAL: **raw 415, counter1 351, human-effective 292** across 9 files.
Floor is 200 effective / 2 files — cleared with buffer.

Measured with the Counter-2 stripper in `.claude/skills/olympus-harden/SKILL.md § Stage 5`.

## 8. Solution outline — helpers

- `SiblingScope::take_adjacent()` — removes the arms spent by the next element
- `SiblingScope::arm(adjacent, later)` — records arms, deduplicated
- `Stack::take_adjacent_sibling_jumps()` / `later_sibling_jumps()` / `arm_sibling_jumps()` —
  route to the current parent's scope or the root scope
- `SelectorMatchingVm::arm_sibling_jumps(ctx)` — flushes arms collected during execution
- `try_exec_sibling_jumps_without_attrs` / `exec_sibling_jumps_with_attrs` — run armed sets,
  with a `SiblingJumpPtr` recovery point spanning both the adjacent and later lists
- `ExprSet::into_matcher()` — folds a compiled compound predicate into one closure
- `Compiler::compile_exprs()` — recursive, so alternations nest

No fixpoint loop applies. No recursion through references.

## 9. Test file outline

`tests/selector_relations_fc54ff.rs`, 66 `#[test]` functions, behavioural through the public
`rewrite_str` / `element!` / `Selector` API only.

Helpers: `matched_ids`, `marked`, `ids`, `selector_error`, `assert_parses`.

Buckets: adjacent basics (12) - general sibling (9) - scope and nesting (5) - combinator
composition (6) - sibling with existing predicates (5) - foreign/void elements (3) -
`:is()`/`:where()` basics (8) - negation composition (3) - `:is()` as a combinator operand (4)
- cross-product cells (5) - parse and error surface (6).

5-axis coverage: every meta sentence has >= 1 test; every new selector form is exercised;
every new branch (adjacent vs later, fast path vs attribute path, root vs nested scope,
negated vs plain alternation) has a test; edge cases (empty result, single alternative,
element matching several alternatives, 200-element chunked input) present; the stated inverse
(what must NOT match) is tested for every positive rule.

## 10. Forced trait bounds

`CompiledFullExpr = Box<dyn Fn(&SelectorState, &LocalName, &AttributeMatcher) -> bool + Send>`.
The `Send` bound is forced by `SelectorMatchingVm<E: ElementData + Send>`; the three-argument
shape is forced because a `:is()` alternative may mix a tag-name condition and an attribute
condition, which the existing two-phase split cannot express.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Meta sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | Arms must be flushed at **every** terminal site and sibling sets resumed after **every** attribute bailout recovery point | F-9 | S5 dual-path | pipeline path (fast vs attribute) | #2, #4 (all ride the same execution chain) | The VM has one obvious terminal path and two more reachable only when the selector needs attributes; a tag-name-only selector works while a class-based one silently does not | "Make all four work" + all matching rules | `adjacent_matches_only_the_immediately_following_sibling` and 28-35 others |
| 2 | Arms belong to the **parent's** scope, recorded before the element is pushed; a root scope must exist for top-level elements | F-1 | S3 | state ownership | #1 | The VM's only propagation mechanism runs downward through the stack (`jumps`, `hereditary_jumps` on the element's own item); sideways propagation has no home, and top-level elements have no stack item at all | "elements at the top level of a document are siblings of one another"; "never crosses a parent boundary" | `later_does_not_reach_into_its_own_subtree`, `root_level_*` |
| 3 | Content-less elements arm and spend sibling state even though they never enter the stack | F-10 | S4 | element kind | #1 | `with_content` correctly gates child and descendant jumps, so reusing that gate for sibling arms looks right; void elements are exactly the motivating use case | "Elements that carry no content of their own ... take part in sibling relationships exactly like any other element" | `adjacent_arms_from_a_void_element*`, `adjacent_is_spent_by_an_intervening_void_element`, `later_arms_from_a_void_element` |
| 4 | A `:is()` alternative may mix tag-name and attribute conditions, so an alternation cannot be split across the existing two matching phases | F-9 | S6 two evaluators | evaluation phase | #1 | Every existing condition sorts cleanly into one of two lists; an alternation is the first that cannot, and the naive split silently mis-answers | ":is(...) ... match an element when any one alternative matches it" | `is_mixes_tag_name_and_attribute_alternatives` and 13 others |
| 5 | Negation applies to the alternation as a whole, not per alternative | F-10 | S2 composition | logical polarity | — | Pure composition of two separately documented rules; De Morgan is easy to get backwards and no sentence names the combination | composition of the `:is()` rule and the existing `:not()` behaviour | `negated_is_excludes_every_alternative`, `negated_is_with_tag_name_alternatives`, `negated_is_on_the_left_of_a_sibling_combinator` |

Every trap was **reproduced** before the tests were finalised — see § 11c.

CONTRACT-STATED / FIX-HIDDEN check: each row's meta sentence states the observable contract and
none of them names a storage location, an execution site, or an evaluation phase.

## 11b. Capability cross-product matrix (F-10)

Axis 1 (polarity): `+` adjacent vs `~` later.
Axis 2 (multiplicity/kind): ordinary element vs content-less element.
Axis 3 (context): root scope vs nested scope vs inside a child/descendant chain.
Axis 4 (operand): plain compound vs `:is()` list vs negated `:is()` list.

| | `+` | `~` |
|---|---|---|
| **ordinary element** | `adjacent_matches_only_the_immediately_following_sibling` | `later_matches_every_following_sibling` |
| **content-less element (arms)** | `adjacent_arms_from_a_void_element` (off-diagonal) | `later_arms_from_a_void_element` (off-diagonal) |
| **content-less element (spends)** | `adjacent_is_spent_by_an_intervening_void_element` (off-diagonal) | `later_matches_across_a_void_element` (off-diagonal) |
| **root scope** | `root_level_adjacent_matches_without_an_enclosing_element` | `root_level_siblings_match_without_an_enclosing_element` |
| **inside child chain** | `sibling_inside_a_child_combinator_context` | `sibling_inside_a_descendant_combinator_context` |
| **`:is()` operand** | `is_on_the_left_of_an_adjacent_combinator`, `is_mixing_tag_and_attribute_alternatives_on_the_left_of_a_combinator` | `is_on_the_right_of_a_later_combinator` |
| **negated `:is()` operand** | `negated_is_on_the_left_of_a_sibling_combinator` (off-diagonal) | — |

Predicted composition failure mode: over-firing (matching inside a subtree, or matching after a
blocking element), not a missing feature — which is what makes it misdirecting.

## 11c. Trap reproduction (measured, not predicted)

Eight natural-but-wrong implementations were written on top of the reference and run against
the suite. Harness restores from a pristine copy between mutations and asserts each edit
applied, so a silent no-op cannot read as "kills nothing".

| Mutation | New-suite kills | Also breaks the repo's existing conformance fixtures |
|---|---|---|
| M1 arm onto the element's own scope instead of the parent's | 3 | **yes (2 of 3 fixture suites)** |
| M2 arm only for elements with content (reuse the `with_content` gate) | 5 | no |
| M3 adjacent arms not spent by a non-matching element | 13 | **yes (2 of 3)** |
| M4 arm only on the attribute-free fast path | 36 | no |
| M5 sibling jumps not resumed after an attribute bailout | 29 | no |
| M6 negation distributed over the alternatives (De Morgan slip) | 3 | no |
| M7 `:is()` not treated as needing attributes | 14 | no |
| M8 no root sibling scope | 33 | no |

M2 and M6 have **sole detectors** — no other test in the suite catches them. Those are the
near-miss deciders (L16).

## 11d. Baseline-preservation property (S3)

The repo ships the W3C css3-modsel conformance corpus in `tests/data/selector_matching` and
`tests/data/element_content_replacement`, and its harness **skips** cases whose selector does not
parse. Supporting `+`, `~`, `:is()` and `:where()` activates **468 previously-skipped cases per
suite** (ignored count drops 6876 -> 6408, twice over). The reference passes all of them.

Consequences: an agent gets a large independent oracle for free, which is good for fairness; and
a wrong implementation can fail an **existing** repo test whose failure is reported as a W3C
fixture output mismatch, which points away from the code the agent just wrote. M1 and M3 both do
exactly this.

## 12. Tier + category

- Tier: Olympus (single tier since 2026-07).
- Category at submit: **feature-request** (net-new selector syntax support).

## 13. Predicted pass rate

Predicted **10-30%**.

Reasoning: the core wiring traps (M4/M5/M8, 29-36 kills each) are discoverable by any agent that
tests its own work, so they set a floor rather than a ceiling. The band is decided by the
low-kill, sole-detector traps: void-element participation (M2) and negated-alternation polarity
(M6), plus the parent-scope ownership question (M1). An agent that writes the obvious
implementation and smoke-tests `.a + p` and `.a ~ p` on flat, well-formed HTML passes its own
probes and fails these — the P3 self-test-shadow shape.

Risk of landing too easy: `+` and `~` are famous CSS semantics, so nothing about *what* to build
is hard. Risk of landing too hard: none identified; the reference is 292 effective LOC and the
repo's own `ChildCounter` shows the parent-scoped-state idiom.

## 14. Quality-gate checklist

- [x] Repo understanding: 5/5 (architecture, 5 subsystems, entanglement zones, test framework,
      template test file cited)
- [x] Existing PR check: 0 hits. `gh pr list -R cloudflare/lol-html --state all --search` over
      sibling / combinator / adjacent / selector support / nth-child / previous element. Issue
      #67 "Adjacent Sibling Combinator" is OPEN with **zero comments and no PR** — it confirms
      the feature class is wanted and binds nothing; scope was invented here.
- [x] Canonical org resolved: `cloudflare/lol-html` (no redirect, not a mirror)
- [x] Closest approved opened side-by-side: `lyon-arcs-join` (Rust, Dockerfile + test.sh model)
- [x] Title verb-led, 10 words, names the subsystem
- [x] Shape declared
- [x] Public surface enumerated (§ 3)
- [x] Canonical form spelled out (§ 4)
- [x] <= 1 codebase-inferable requirement
- [x] meta.md 345 words, hard cap 500, ASCII, no headers, no labels, no code-prose
- [x] File footprint measured against real source
- [x] human-effective 292 >= 200 floor; 9 files >= 2
- [x] Helpers extracted, 1+ per described behaviour
- [x] 4-block test layout, scenario-encoded names, no comments in test bodies
- [x] 5-axis coverage
- [x] Forced bounds documented (§ 10)
- [x] 5 named traps, each with F-id, meta sentence and catching test
- [x] Traps on different axes; #1, #2, #3, #4 interdependent through the execution chain
- [x] § 11b cross-product filled; every off-diagonal cell has a test
- [x] Every trap reproduced and measured (§ 11c)
- [x] Predicted pass rate <= 40% ceiling
- [x] Category honest (feature-request)
- [x] Not pattern-followable: no existing combinator has sideways scope; the alternation is the
      first predicate form that cannot be split across the two existing matching phases
- [x] Flakiness: base 3x and new 3x identical in clean room, and in the container
- [x] Docker: offline, `--network none`, `--user 1000:1000`, both modes green

## Why this is not a duplicate

Closest approved siblings: `lyon-arcs-join` (Rust, but F-8 named-algorithm override in a
geometry tessellator) and `pulldown-cmark-gfm-autolinks` (Rust streaming parser, F-1 wall in an
inline parser). This one shares neither the repo, the trap family, nor the subsystem: the lead
mechanism here is a dual-path/stage-boundary flush (S5/F-9) in a compiled selector VM, and the
band decider is a composition cell (F-10). No prior submission in `approved-problems/`,
`problems/`, `rejected/` or `diamond-problems/` touches lol-html or CSS selector matching.

Predicted iteration cycles: 2.
