# feedback.md — beartype-door-hint-algebra

## Summary

Olympus, feature-request. `beartype.door` publishes a partial order over type
hints (`is_subhint`) but nothing that combines them. This adds the lattice:
canonical form, join, meet, difference, disjointness, and a sequential coverage
analysis over an ordered sequence of hints. One kernel (union reduction plus a
meet dispatcher) drives eleven wrapper subclasses and four public entry points,
so a fix confined to one surface regresses another.

Status: built, validated, not yet run against agents.

## Pick

Repo chosen by autonomous discovery under the standing "brand-new repo, brand-new
hard feature" preference. Candidates screened and dropped:

- TinyDB secondary indexes: closed PRs #607/#611 publish B-tree index diffs.
  Exclusivity-dead.
- pandera schema algebra: the vanilla test tree imports dask, modin, pyspark and
  polars, so an offline default test command cannot pass. Environment-dead.
- osmnx turn-penalty expansion, MetPy: both download data during tests.
- construct: last commit 2025-04-22, over the twelve-month activity floor.
- eyecite: 266 stars, under the 500 floor.

beartype passes every gate: MIT, 3481 stars, pushed the day of the base commit,
zero mandatory dependencies, and a vanilla suite that runs offline in 22 seconds.
No prior problem in `Instructions/Aprroved/`, `problems/` or `rejected/` targets
beartype or any runtime type-checking library.

Exclusivity: `gh pr list -R beartype/beartype --state all --search` over
simplify, normalize, intersection, lattice, union and TypeHint, plus the matching
issue searches, returns nothing implementing or requesting hint simplification,
meets or disjointness. Issue #133, the origin of DOOR, requested `is_subhint`,
which shipped long ago; the maintainer welcomed further DOOR work there rather
than declining it.

## Why this is not a duplicate

Closest approved siblings are `surrealkv-merge-operator` (a merge operator
threaded through an existing storage kernel) and `pysmt-bit-blasting` (a
transformation over an existing formula engine). Both transform values; this
transforms *type hints*, extending a published partial order into a lattice, and
its difficulty lives in canonicalisation and structural meets rather than in an
encoding.

## Assumptions and decisions logged during the run

1. **Order is not part of the contract.** The first draft specified
   first-appearance order for union members and literal arguments. DOOR caches
   wrapper instances order-insensitively (a union and its permutation share one
   wrapper), so member order is not observable through the public API and
   assertions on it flip with test execution order. Both the spec and the tests
   now treat union members and literal arguments as unordered. Verified against
   eight randomized-order seeds.
2. **The meet resolves structurally before falling back to the subhint
   relation.** DOOR's `is_subhint` reports `Annotated[str, m] <= Annotated[int, m]`,
   so a subhint-first resolution inherited that hole and returned a non-empty
   meet for two disjoint annotated hints. Each wrapper family now owns its
   answer and defers to the subhint relation only for incommensurable branches.
3. **The difference handles literal members before the subhint test**, for the
   same reason: DOOR reports `Literal[1, 2] <= Literal[1] | str`, which would
   swallow the surviving argument.
4. **A bare `tuple` is excluded from the unsubscripted-origin rule**, since
   subscripting `tuple` by one child denotes a one-item tuple rather than a
   variable-length one. Stated in meta.md.
5. **Base mode deselects one test.** `beartype_test/a90_func/a50_external/test_poetry.py::test_poetry`
   installs this package from a remote index. The base image ships poetry, so
   that test runs rather than skips and fails under `--network none`. It is the
   only test excluded, and it is excluded for that reason alone.
6. **A canonical form without an order cannot name a representative.** Dropping the ordering guarantee (decision 1) also forbids pinning which of two equal members survives. One test still did; it now asserts the result is a single member semantically equal to `list[int]`, whatever its spelling.
7. **Scope grew twice to clear the LOC floor**, both times with orthogonal
   algorithms rather than breadth: the difference operator (290 -> 429
   human-effective) and the coverage analysis with its overlap and removability
   passes (429 -> 472).

## Difficulty design

Corpus levers stacked: one interdependent kernel driving eleven subclasses; an
external oracle (`is_bearable` runtime acceptance) fuzzed to zero mismatches over
2704 hint pairs; misdirecting traps whose failing assertion names a union member
list rather than the rule that produced it; two "the obvious code is wrong"
edges (a meet must take the narrower of the two origins; a coverage arm matches
the residual, not the covered hint); a bespoke surface no PEP defines; and an
eleven-file span.

Traps confirmed by mutation, with the tests that catch them, are tabulated in
`eval-results.md`. Thirteen of fifteen mutations are caught; the two that are not
are provably semantics-preserving and are not claimed in meta.md.

## Attempt history

| Round | What changed | Result |
| --- | --- | --- |
| 1 | Reference implementation across 9 files | vanilla suite green, smoke behaviour correct |
| 2 | Differential fuzz round 1 | `Any` elided by dedup; annotated meets inheriting a DOOR hole. Fixed by testing `Any` before dedup and by resolving structurally before the subhint fallback |
| 3 | Fuzz rounds 2-3 | unsubscripted-class meets and cross-family meets. Fixed with the effectively-unsubscripted rule and a commensurable-wrapper guard |
| 4 | Fuzz round 4 | canonical form not minimal for piecewise-absorbed literals. Added literal-argument absorption |
| 5 | Structural review | simplification compared children by DOOR equality, so nested reductions were skipped. Fixed with identity comparison; a callable-specific simplification preserves `...` and `[]` |
| 6 | Scope expansion | difference operator, then coverage analysis, to clear the effective-LOC floor with orthogonal depth |
| 7 | Test suite, 165 tests | 9 failures, all from unobservable ordering and from identity assertions defeated by wrapper caching. Spec and tests rewritten to be order-free |
| 8 | Mutation probes | 13 of 15 mutations caught; origin-narrowing coverage strengthened after a probe slipped past |
| 9 | Docker | base image ships poetry, so its network test ran and failed offline. Deselected in base mode |
| 29 | Batch 3 de-trap | 0 of 10 again. The literal-collision tests added in round 28 were missed by all ten runs: they demanded DOOR's `==` semantics where PEP 586 makes `Literal[1]` and `Literal[True]` distinct, and the prompt pinned neither, so they were dropped. The FP-mandated sequence-versus-tuple meets failed in seven runs because the child-contribution rule read as "narrower origin receives the children"; reworded to name the direction, with the closing fallback sentence naming that pair. Replay projects 1 of 10, 218 -> 215 |
| 28 | Coverage suggestions, round 9 | `cover_hint` now rejects a non-iterable covering argument with `BeartypeDoorException` instead of leaking a bare `TypeError`, stated in meta and still walking the source once. Added literal collisions under Python equality (`True` == `1`) for simplify, meet and difference, asserting the collapse rather than the surviving representative, since typing interns equal unions and the representative is not stable. Added an early-exhaustion case proving every later hint is still consumed and reported for the overlap and removability passes, 213 -> 218 |
| 27 | FP report, round 2 | third false-positive escape, again a rule PAIR rather than a rule: `cover_hint(Any, (int, Any))` must give `removable == (0,)`, since omitting the trailing `Any` turns an exhausted residual into a live `Any`. The passer returned `(0, 1)` by comparing its exhaustion sentinel as equal to `Any`. The reference was already correct; added both the exhausted and the unexhausted catch-all case, and verified a mutation conflating the sentinel with a hint residual kills five tests, 211 -> 213 |
| 26 | Problem/test quality | the wrapper-identity assertion added in round 25 was flagged as over-specification, correctly: the prompt promises a wrapper back and identity for the canonical HINT, not identity of the wrapper instance. Relaxed to an isinstance check plus `simplify().hint is wrapper.hint`, which still fails a rebuild-every-time implementation, verified against a non-canonical input where the wrapped hint does change |
| 25 | Coverage suggestions, round 8 | canonicality is now asserted by identity as well as structure: a meet or difference result fed back through `simplify_hint` returns that same object, which follows from a canonical result being a canonical input. Added the wrapper-level counterpart, where `simplify()` on a canonical wrapper returns the wrapper itself and the same wrapped hint through the public `hint` property, 210 -> 211 |
| 24 | Coverage suggestions, round 7 | added method-versus-function agreement on empty results, compared without wrapping, since `TypeHint(None)` is the valid `NoneType` wrapper and would silently absorb a wrong `None`; added a counting iterable asserting `cover_hint` calls `__iter__` once and reads exactly one item per arm, turning the walked-once guarantee into a direct assertion rather than an inference from generator behaviour, 208 -> 210 |
| 23 | Test Fairness, round 4 | flagged `test_simplify_union_drops_equal_member` on the premise that `TypeHint(list[Any]) != TypeHint(list[int])`, so the wrapper-equality assertion pinned the `list[int]` representative. That premise is false: the wrappers ARE equal (mutual subhint through the `Any` child, verified), the assertion passed for either spelling, and the reference itself returns `list[Any]`, the spelling the report says the test rejects. Contestable, but the assertion was redundant given the structural origin/args check, so it was removed rather than defended. Added the suggested generic-representative matrix over `list`, `list[Any]` and `list[int]` for both simplify and join, 206 -> 208 |
| 22 | Coverage suggestions, round 6 | reflected operators now honour the contract meta already stated: `int \| wrapper`, `int & wrapper` and `int - wrapper` raised `TypeError` while the forward forms raised `BeartypeDoorException`, so `__ror__`, `__rand__` and `__rsub__` were added to validate the left operand. Strengthened the vacuous empty-tuple meet assertion, since `get_args(None)` is also `()` and a `None` result would have passed it. Added equal and later-position-differing multi-entry Annotated metadata meets, 203 -> 206 |
| 21 | Test Fairness, round 3 | the metadata-robustness test added for the Auto Review was itself flagged unfair, since the prompt defined only equal versus differing metadata and the repo is inconsistent (`_is_equal` compares unguarded, `_is_subhint_branch` suppresses). Resolved by stating the rule rather than dropping the test, so prompt, tests and reference now agree: metadata that raises rather than answer counts as differing. Added the two advisory cases, a child nested through Annotated/Callable/list/union at once and a generator whose later element is not a hint, 201 -> 203 |
| 20 | Auto Review + FP report | Auto Review found a real defect in the reference: the annotated meet compared metadata with a bare `!=`, so metadata whose `__eq__` raises propagated out of `meet`, `is_disjoint` and coverage, unlike the repo's own subhint path which suppresses. Fixed with the same `suppress(Exception)` convention, uncomparable metadata now counting as differing and therefore disjoint, and pinned by `test_meet_annotated_uncomparable_metadata_is_none`. The FP adjudicator broke the single passing agent with two probes the suite missed (annotated-meets-literal dispatch, and a sequence-like generic against a variadic tuple); both are now tested in both operand orders. Rewrote the P6 sentence that prescribed children-first rebuilding. Added the advisory difference-over-annotated/callable/tuple case, 194 -> 201 |
| 19 | Description Quality | 5 over-specification/redundancy comments, all accepted: dropped operand-canonicalization steps from the join and difference sentences, the meet dispatch-order phrase, the at-least-one-survivor invariant, and the never-partly-narrowed rationale. Each was verified non-load-bearing first: canonicalizing an operand is confluent with canonicalizing the result, and the meet precedence is still carried by the closing "a pair matching none of these" sentence. 825 -> 790 words, no test or reference change |
| 18 | Coverage suggestions, round 5 | the generator coverage case now also pins `overlapping` and `removable`, which catches an implementation that consumes the iterable for the sequential pass without retaining the arms for the all-pairs and omission analyses; added `Any` disjointness in both directions and the empty-result semantics of the `&` and `-` operators, 192 -> 194 |
| 17 | Coverage suggestions, round 4 | pinned the `cover_hint` iterable boundary (an ordered iterable walked once, so a generator serves as well as a tuple) and tested it, which also discriminates an implementation iterating the argument twice; added canonical-identity cases for a PEP 604 union, a nested generic and a union-valued child, 187 -> 191 |
| 16 | Test Fairness, round 2 | 1 of 185 flagged unfair: the bare-`tuple` exception said only that the reconstruction does not apply, never where such a pair lands, so pinning `None` was unstated. Meta now says the pair falls through to the subhint rule; the test asserts both outcomes of that fallback (`Sequence[int]` disjoint, `tuple[int, ...]` narrowed). Added method-versus-function parity and container-level `is_disjoint` parity from the advisory notes, 185 -> 187 |
| 15 | Coverage suggestions, round 3 | added PEP 604 spelling coverage (simplify, join, meet and difference mixing `\|` with `typing.Union`), non-hint rejection in the second operand position of all four binary functions, and same-origin effectively-unsubscripted meets (`list[Any]`, bare `list`, both operand orders), 176 -> 185. A non-sequence `hints` argument to `cover_hint` was left untested: iterating it raises a plain `TypeError`, which the description does not promise, so pinning it would be a hidden requirement |
| 14 | Coverage suggestions, round 2 | added non-hint rejection for all six procedural entry points (both `cover_hint` arguments included), a residual-canonicality case, and a same-origin differing-child-count meet (`Mapping[str, int]` against `Iterable[str]`). Meta extended to state that the functions reject non-hints, 173 -> 176 |
| 13 | Test Fairness | 1 of 173 flagged unfair: `test_simplify_union_drops_equal_member` pinned `list[Any]` as the survivor of two DOOR-equal members, a tie-break the spec deliberately leaves open once union members carry no order. Relaxed to accept either representative while still rejecting an undeduplicated union. Mutation kills held at 13 of 15 |
| 12 | Coverage suggestions | added wrapper-return-type and empty-result assertions, operator error paths, the public `HintCoverage` type check, and a six-arm coverage case exercising three unreachable, five removable and four overlap pairs in ascending order. Meta extended to cover operators and `HintCoverage` importability, 168 -> 173 |
| 11 | Description precheck | `HintCoverage` field container types were unstated (tests compare tuples) and `simplify()` never said it returns a wrapper. Both pinned in meta; added the two missing negative tests for `join` and `is_disjoint` on unwrapped hints plus a field-type test, 165 -> 168 |
| 10 | Platform precheck | test.patch rejected: an empty new `__init__.py` produces a diff entry with no `--- /dev/null` / `+++ b/<path>` headers, which the validator requires even though `git apply` accepts it. Gave the file a module docstring and regenerated. The description checks in the same run graded this test patch against the previous Task6 submission's prompt_toolkit description, not this meta.md |

## Open risk to check before submitting

`Olympus/Instructions/SATURATED-REPOS.md` does not list beartype under either
GLOBAL-SATURATED or OUR-CAP-REACHED, and no local folder targets it. Its
presumed-saturated law still applies by analogy, though: beartype is a leading
library for one Python tooling category (runtime type checking), the profile that
killed cattrs at 1047 stars and prompt_toolkit at 10.5k. Only the platform "Learn
more" page reports the global submission count, and it is visible at submit time.
Check that count for beartype before spending an agent batch. Mitigating factors:
3481 stars, under the 5k presumed-saturated threshold, and DOOR is a niche
sub-API within the package rather than the decorator every author reaches for.

## Batch 1 outcome and the de-trap

0 of 12 passed, which fails the solvability floor. The failures were not
scattered: 39 of 62 sat in two clusters, and the best run (Orion) was two tests
away, both in one cluster. Diagnosis and fixes are tabulated in
`eval-results.md`; the short version is that one cluster was fair but
undiscoverable wording and the other was a genuine hole in the description that
implied an impossible hint (`str[bool]`). Both were fixed in meta.md alone.

The two clusters were deliberately NOT enumerated by example in the prose: the
identity rule is stated as a rule, so an implementation still has to notice that
its own union rebuild violates it.

**Watch the next batch for the opposite failure.** Six runs failed only cluster A
and cluster B tests. If every run now clears both, the rate lands near 50%, over
the 40% ceiling. The prepared hardening lever, should that happen, is to extend
the identity rule to the other combinators: when a join, meet or difference
returns one of the two hints it was given, the caller's own object comes back.
That reuses the existing kernel, needs about fifteen lines in the procedural
layer, and re-tightens the several meet and difference assertions currently
relaxed to structural comparison because of DOOR's wrapper cache.

## Next step

Re-run a batch against the clarified description. Expect 1-4 of 12; the risk has
flipped from the solvability floor to the 40% ceiling, so read the new rate
before touching anything else, and apply the prepared hardening lever above only
if it lands over the cap.

## Batch 3 and the offline close

Batch 3 landed 0 of 10 again. Rather than spend a fourth batch, the most
complete run was replayed locally and driven to a full pass with five edits that
each quote the meta.md sentence they follow, which is the evidence the problem is
solvable from the description alone. That passing run then became the
false-positive oracle: 11,729 probes over every stated behaviour, plus the
differential fuzz, now agree with the reference everywhere.

Two reference bugs surfaced in the process, both around PEP 593 annotated hints
meeting literals. The second was really a description bug: "the arguments the
subtrahend accepts" reads as runtime acceptance, but DOOR reports no literal to
be a subhint of an annotated hint, so absorbing on acceptance broke the join's
own defining property. Both the union rule and the difference rule now name the
subhint relation instead of accepting, which is the relation the package already
publishes and the only one an implementer can consult.

## Next step

The artifacts are self-consistent and a real agent solution passes them, so the
solvability floor is no longer the open risk; the 40% ceiling is. Read the rate
before touching anything else, and apply the prepared identity hardening lever
from the previous section only if it lands over the cap.


## Batch 4: solvable

0 of 15, but nine runs missed by one to four tests out of 237, each on a
different assertion. Diagnosis by local replay of all 15 patches: the deaths
were concentrated in object-identity and reflected-operator assertions, which
are API surface rather than lattice behaviour. Removing those two families took
the replayed rate to 1 of 15 with every algebra trap intact, and the passer is an
unmodified agent solution that diverges from the reference on none of the 11,729
probes.

## Next step

Solvability is settled by an unmodified agent patch, and the false-positive
surface is clean against that same patch. The open risk is the ceiling: 7 percent
is comfortably inside the band, so nothing further should be relaxed.
