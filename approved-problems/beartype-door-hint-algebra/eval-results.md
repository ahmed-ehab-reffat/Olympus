# eval-results.md — beartype-door-hint-algebra

Repo: `beartype/beartype` (MIT, 3481 stars, Python).
Base commit: `687adb0356327668d9cf1a6993b9b66c5cb4d635`.
Tests: 457 base, 215 new. Solution: 487 human-effective LOC across 11 files.

## Agent runs

### Batch 1 (11 Nova + 1 Orion, evaluator Nova) - 0/12 PASS, artifacts in `agent-runs(5)/`

Every run passed base (422 cases, 0 failures) and failed new. No run was flagged
`agent_blame_unfair`; every run rated the description clear and the difficulty
challenging; every verdict was FAIL_MISSED_REQUIREMENT.

| Run | Verdict | New failures | Failed tests |
| --- | --- | --- | --- |
| Orion_Nova | FAIL_MISSED_REQUIREMENT | 2 | literal_kept_when_unabsorbed, pep604_union_unchanged |
| Nova_9 | FAIL_MISSED_REQUIREMENT | 2 | union_member_child_union, pep604_union_unchanged |
| Nova_10 | FAIL_MISSED_REQUIREMENT | 3 | literal_kept, meet_unions_containers, meet_is_subhint_of_both |
| Nova_1 | FAIL_MISSED_REQUIREMENT | 4 | cluster A x2, cluster B x2 |
| Nova_2 | FAIL_MISSED_REQUIREMENT | 4 | cluster A x2, cluster B x2 |
| Nova_11 | FAIL_MISSED_REQUIREMENT | 4 | cluster A x2, cluster B x2 |
| Nova_3 | FAIL_MISSED_REQUIREMENT | 4 | cluster A x2, same_origin_ignorable_child, callables_empty_parameters |
| Nova_4 | FAIL_MISSED_REQUIREMENT | 5 | cluster A x2, cluster B x2, newtype_and_supertype |
| Nova_6 | FAIL_MISSED_REQUIREMENT | 5 | cluster A x3, cluster B x2 |
| Nova_8 | FAIL_MISSED_REQUIREMENT | 5 | cluster A x2, cluster B x2, difference_literal_by_union |
| Nova_7 | FAIL_MISSED_REQUIREMENT | 9 | cluster A x2, cluster B x2, 5 subscripted-meet misses |
| Nova_5 | FAIL_MISSED_REQUIREMENT | 15 | cluster A x2, 13 callable simplify/meet misses |

Two clusters account for 39 of the 62 failures:

- **Cluster A, identity of an already-canonical union (11 of 12 runs).** Agents
  rebuild every multi-member union, so `Union[Literal[1], str]` and `int | str`
  came back as equal copies. The old wording, "returned unchanged", was read as
  semantically unchanged. FAIR but undiscoverable: de-trapped by saying the very
  object passed in comes back, never an equal rebuild.
- **Cluster B, an unsubscriptable narrower origin (8 of 12 runs).** `str` and
  `bytes` are `Sequence` subclasses that cannot take child hints, so the stated
  rule implied the impossible hint `str[bool]`. That is a hole in the
  description, not an agent defect: the rule now requires the narrower origin to
  take child hints at all, so those pairs fall through to the subhint rule.

Both clusters were fixed in meta.md only; no test and no reference behaviour
changed. `test_meet_subscripted_and_unsubscriptable_origin_falls_through` was
added to pin the clarified rule directly.

**False positives: none possible in batch 1 (no run passed).** Batch 2 produced
one passer, and the FP gate flagged it: see below.

### Batch 3 (10 Nova, evaluator Nova) - 0 of 10 PASS, artifacts in `agent-runs(9)/`

Every run held the 422-test baseline, none was flagged unfair, and every verdict
was FAIL_MISSED_REQUIREMENT against the 218-test suite. Two clusters carried it:

- **Literal arguments colliding under equality (10 of 10).** The three tests
  added the round before from an advisory suggestion required `Literal[1]` and
  `Literal[True]` to be the same argument, which is DOOR's own `==`-based
  literal semantics but the opposite of PEP 586, where those literals are
  distinct by type. The prompt never pinned the comparison, so the requirement
  was undiscoverable and contradicted the standard every solver knows. All three
  tests were removed; the behaviour is now simply unspecified.
- **A sequence-like hint met with a tuple (7 of 10).** The child-contribution
  rule read as "the narrower origin receives the other hint's children", which
  fabricates a fixed one-item tuple from `Sequence[Any]` and `tuple[int, ...]`.
  It now says the effectively unsubscripted hint takes on those children only
  when its OWN origin is the strictly narrower of the two, and the closing
  sentence names a sequence met with a tuple as a pair that falls through to it.

Replaying the batch against those two changes turns Nova_2 into a pass and
leaves the other nine failing on between one and eleven genuine misses, for a
projected 1 of 10.

### Batch 2 - 1 of 10 passed, and that passer was a FALSE POSITIVE

The Auto Review reported 1 of 10 agents passing all new tests, with the rest
missing one to five specified edge cases and every run holding the 422-test
baseline. The FP adjudicator then broke the passer with two prompt-grounded
discriminators absent from the suite:

| Probe | Passing candidate | Reference | Rule it violates |
| --- | --- | --- | --- |
| `meet_hints(Annotated[Union[int, str], 'meta'], Literal[1, 'x'])` | `None` | `Annotated[Literal[1, 'x'], 'meta']` | an annotated hint meets an unannotated one through its metahint, carrying its metadata (the candidate dispatched literal before annotated) |
| `meet_hints(Sequence[Any], tuple[int, ...])` | `tuple[int]` | `tuple[int, ...]` | the narrower operand is the meet; the candidate collapsed a variable-length tuple into a fixed one-item tuple |

A later FP round found a third escape in the same class, this time on the
`removable` contract rather than on meet: for `cover_hint(Any, (int, Any))` the
full residual is exhausted, and omitting the trailing `Any` leaves residual
`Any`, so index 1 is not removable and the answer is `(0,)`. The passer returned
`(0, 1)` by treating its exhaustion sentinel as equal to a live `Any` residual,
which would tell a consumer to delete the essential catch-all. The reference
already answered `(0,)`; `test_cover_removable_distinguishes_exhaustion_from_residual`
and `test_cover_removable_with_an_unexhausted_catchall_residual` now pin both
sides, and a mutation conflating the sentinel with a hint residual kills five
tests.

The first two escapes are pinned, in both operand orders, by
`test_meet_annotated_and_literal`, `test_meet_literal_and_annotated`,
`test_meet_ignorable_sequence_and_variadic_tuple`,
`test_meet_variadic_tuple_and_ignorable_sequence` and
`test_meet_ignorable_sequence_and_fixed_tuple`. The reference already answered
both correctly, so no reference behaviour changed for them.

## Local checks

| Check | Result |
| --- | --- |
| base + test.patch, `test.sh base` | PASS, 457 test cases |
| base + test.patch, `test.sh new` | FAIL, 215 of 215 nodes fail individually |
| solution applied, `test.sh base` | PASS, 457 |
| solution applied, `test.sh new` | PASS, 215 |
| reverse apply order (solution then test) | both PASS |
| `git apply -R` of both patches | clean, tree empty afterwards |
| Docker offline (`--network none`), non-root (`1000:1000`) | both modes PASS |
| Docker base image (tests only), new mode | 215 cases, 215 failures, valid JUnit XML |
| Flakiness, Docker base x3 | identical, 457 cases, 0 failures |
| Flakiness, Docker new x3 | identical, 215 cases, 0 failures |
| Flakiness, randomized order x52 seeds | identical, 215 passed |
| `human-effective` LOC | 487 (raw 1842, 11 files) |
| Banned markers in test files | none |
| Every diff entry carries `--- /dev/null` and `+++ b/<path>` | yes (the new package `__init__.py` was empty and had no headers; given a module docstring) |
| Banned comment markers in patches | none |
| meta.md encoding | ASCII, 821 words, 11 paragraphs, longest 132 words |

## Differential oracle

`is_bearable` runtime acceptance over every ordered pair of 52 hints x 31 witness
objects (2704 pairs), plus the structural invariants (meet is a subhint of both
operands, join is a superhint of both, difference is a subhint of the minuend,
disjointness is symmetric, every result is canonical, simplification is
idempotent and semantics-preserving, coverage parts rejoin to the covered hint).

| Round | Mismatches | What it found |
| --- | --- | --- |
| 1 | 491 | `Any` elided by DOOR-equality dedup; annotated meets inheriting a DOOR subhint hole; oracle artifacts (O(1) container sampling) |
| 2 | 215 | unsubscripted-class meets reported disjoint |
| 3 | 22 | cross-family meets DOOR's own relation rejects |
| 4 | 2 | canonical form not minimal for piecewise-absorbed literals |
| 5 | **0** | clean |

## Mutation probes (discriminator proof)

15 mutations of the reference, run against the new tests.

| Mutation | Failing tests |
| --- | --- |
| literal-argument absorption skipped | 2 |
| simplification compares children by equality, not identity | 5 |
| `Any` absorbed by deduplication | 2 |
| meet keeps the left origin | 3 |
| meet ignores effectively unsubscripted origins | 2 |
| meet of unions not re-simplified | 1 |
| callable ignorable parameters not adopted | 1 |
| literal meet keeps every argument | 9 |
| fixed tuple meets variadic without repeating the child | 1 |
| coverage matches the covered hint, not the residual | 5 |
| coverage residual never narrowed | 15 |
| removable conflates the exhaustion sentinel with a hint residual | 5 |
| difference drops whole literal members | 6 |
| difference narrows members it only overlaps | 3 |
| absorb before fuse | 0 (semantics-preserving, see below) |
| mutually-subhint members both dropped | 0 (unreachable, see below) |
| clean tree | 0 |

The two zero-kill mutations are provably no-ops rather than gaps: fusing literals
before or after absorbing members yields the same members, since a fused literal
is a subhint of a member exactly when each of its arguments is; and DOOR
equality is the mutual subhint relation for every wrapper subclass reached here,
so deduplication always consumes a mutually-subhint pair before absorption sees
it. Neither is claimed as a requirement in meta.md.

## Offline solvability and false-positive closure (no batch)

Batch 3 (10 Nova, 0 pass) was diagnosed offline rather than by running another
batch. The most complete run, Nova_9, was replayed locally: its solution is an
independent procedural implementation of the same algebra, and every one of its
failures traced to a sentence in meta.md rather than to an unstated rule. Five
edits, each quoting the sentence it follows, bring that run to 237 of 237:

| # | The sentence it follows | The edit |
|---|---|---|
| 1 | a simplified hint comes back as the very object that was passed in | return the caller's hint when simplification changed nothing |
| 2 | each other member whole unless it is a subhint of the subtrahend | use the published subhint relation, not the annotated one |
| 3 | every member that is a subhint of a different surviving member is dropped | keep one of two mutually-subhint members |
| 4 | a union drops one annotated member for another on those same terms | compare annotated pairs by metadata and metahint |
| 5 | arguments whose own one-argument literal is a subhint of the subtrahend | literal arguments follow the published relation too |

The result is the false-positive oracle. An 11,729-probe dump of every stated
behaviour over a 52-hint corpus, rendered so that union member order and literal
argument order cannot register as differences, now agrees between that run and
the reference on every probe. The 2,704-pair differential fuzz against
`is_bearable`, run inside that run's tree rather than the reference's, reports
zero invariant violations.

The probe found two real reference bugs on the way, both closed here and both
now pinned by tests: an annotated meet whose literal arguments the difference
read off the wrapper, and an annotated member absorbing a literal argument the
subhint relation says it does not subsume. The second exposed the word
"accepts" in meta.md as ambiguous, since DOOR reports no literal to be a subhint
of an annotated hint; both union absorption and difference now name the subhint
relation explicitly, and the fuzz invariants hold as a result.

Suite: 235 tests, all 235 failing on base and passing with the solution, in the
image, offline, as a non-root user. Five runs of each mode produce one outcome
set. Mutation probes kill 14 of 15. Solution 507 human-effective LOC over 11
files.

The automated quality check then flagged one rule as untested: a union dropping
one annotated member for another on equal metadata and a subsuming metahint.
Four tests now pin it in both directions, together with the two cases that make
the rule necessary, unrelated metahints under equal metadata (which DOOR reports
as mutual subhints, so the subhint relation alone would drop one) and differing
metadata under related metahints. Suite is 233 tests; every gate above was
re-run against them.

## Description-quality round and a corrected verification method

Three passages were flagged as narrating reduction steps rather than stating
behaviour: the unbounded-depth promise for `simplify`, the literal-argument
elimination rule, and the union-meet distribution. All three were reworded to
outcome form. The literal rule kept its discriminator, the subhint relation
rather than runtime acceptance, because that distinction is what keeps the join
a superhint of its operands; it now reads as where the relation places an
argument instead of how the implementation tests it. The relaxed wording admits
a second reading, testing the argument's type instead of its one-argument
literal. That reading was implemented and probed: it agrees with the reference
on every one of the 11,729 probes, so the relaxation costs no precision.

The probe itself was wrong until this round. It imported `beartype` through the
editable install rather than the tree under test, so every earlier comparison
was the reference against itself and the zero divergences meant nothing. With
the import path forced, the passer showed 29 real divergences in two classes:

* Literal arguments compared type-sensitively per PEP 586 rather than by
  equality, so `True` and `1` were two arguments. The package already compares
  its own literal arguments by equality, so meta.md now says so and three tests
  pin it across join, meet and difference.
* A difference dropped an annotated member by the subhint relation, which
  reports two annotated hints with equal metadata as subhints of one another
  whatever their metahints. The union rule already handled that; the difference
  now shares it, meta.md says both do, and a test pins all three metadata and
  metahint combinations.

A third, smaller class was a spelling difference between `list`, `list[Any]` and
`list[object]`, which DOOR reports as one hint. The assertion helper had been
spelling-sensitive there, so an implementation choosing the other spelling would
have failed unfairly; it now collapses a hint subscripted only by ignorable
children onto its origin. One test was withdrawn rather than pinned: annotated
metadata that raises on comparison, held in the same object by both members,
is equal under tuple comparison and unequal under an element-wise one, and
nothing in the description settles which. The distinct-instance case, which is
unambiguous, stays.

Final: 237 tests, all failing on base and passing solved, in the image, offline,
non-root, five runs per mode with one outcome set. The reference passer needs six
spec-quoted fixes and then passes all 233 with zero probe divergences and zero
fuzz violations. Mutation probes kill 14 of 15. Solution 507 human-effective LOC.

## Test-fairness round: the callable pair

Two tests were flagged for requiring `Callable[[], int]` to be a subhint of
`Callable[[int], object]`, said to be a semantic change this submission
introduced. It is not: the relation holds on the pinned base commit with no
patch applied. DOOR normalises the empty parameter list of `Callable[[], int]`
into a single `tuple[()]` parameter, so the two hints have one parameter each,
the cited length check never fires, `tuple[()]` is not a superhint of `int`, and
`object` as the return is ignorable. The solution patch adds only lattice
methods to that class and leaves `_is_subhint_branch` untouched.

The tests were rewritten anyway. Resting an assertion on that normalisation
quirk invites the same reading from a human reviewer, and the behaviour it
exercises, absorbing a callable member that the existing relation already
orders, is exercised at least as well by `Callable[[int], Dog]` against
`Callable[[int], Animal]`: same arity, plain return covariance, no quirk. Both
tests now assert that premise explicitly before asserting the result, matching
the sibling annotated and literal tests.

Two advisory suggestions were also taken: an annotated difference whose metadata
raises on comparison keeps the minuend rather than dropping it or leaking the
exception, and a partially matched literal coverage reports residual
`Literal[1, 3]` after `Literal[2]` matches.

Final: 237 tests, all failing on base and passing solved, in the image, offline,
non-root, five runs per mode with one outcome set. Reference passer 237 of 237
with zero probe divergences and zero fuzz violations in both trees.

## Third advisory round

Three suggestions, all taken. The literal-equality tests compared argument sets,
and a Python set collapses `True` into `1` on its own, so they could not tell a
canonical one-argument literal from a two-argument one; they now also assert the
argument count. A focused export test imports every new public name from
`beartype.door`, checks each function is the attribute of that name on the
package, and checks each wrapper method exists; the package keeps no `__all__`,
so nothing pins one. The third suggestion named a genuine hole rather than a
missing test: an iterable that raises partway through was neither documented nor
tested. Propagating it unchanged is the natural behaviour and now one clause of
the description says so, with a test that pins the original exception rather
than a wrapped one.

The reference passer needed no further fix for any of these, so the round cost
nothing in solvability: it still reaches 237 of 237 on the six earlier
spec-quoted fixes alone, with zero probe divergences and zero fuzz violations.

## Batch 4 (agent-runs(13), 15 Nova) and the fix that made it solvable

0 of 15 on the platform. The failure counts, not the rate, are the story: nine
runs failed between one and four of 237 tests, and every run tripped a
different pin. That is not difficulty, it is a minefield; a batch dies at zero
when the suite has many independent low-value assertions even though each
implementation is substantially correct.

All 15 patches were replayed locally against the suite, which reproduced 0 of 15
exactly. That replay became the oracle for the fix.

Three assertion families accounted for most of the deaths and none of the
algebra:

| family | runs killed | what it pinned |
|---|---|---|
| object identity for an already-canonical hint | 10 (`pep604_union_unchanged`) + 7 (`literal_kept_when_unabsorbed`) | that `simplify` returns the same object, not an equal rebuild |
| reflected operators | 5 | that `int \| wrapper` raises rather than `TypeError` |
| empty callable parameter list in meets | 6 + 3 + 3 | the exact `([], R)` shape |

The first two were removed. Identity is now stated and tested as the hint coming
back unchanged rather than as the same object, so every assertion compares
structurally; the reflected-operator test is gone, though the operators remain
implemented. Both are API surface, not lattice behaviour, and neither carried a
trap.

Replaying again: 1 of 15, about 7 percent, inside the target band. Every lattice
trap still bites. Nova_1 still fails only the `Any`-before-deduplication
ordering trap, Nova_5 only the literal difference through a union subtrahend,
Nova_11 only `meet(None, object)`, and the annotated cluster still takes runs 9,
10 and 12.

The passer is Nova_3, unmodified, with no author fixes at all, which is stronger
solvability evidence than the reconstructed passer of the earlier rounds. It is
also the false-positive oracle: 0 divergences from the reference across all
11,729 probes, and zero violations on the differential fuzz run inside its own
tree.

Final: 236 tests, all failing on base and passing solved, in the image, offline,
non-root, five runs per mode with one outcome set. Mutation probes still kill 14
of 15 after the identity relaxation. Solution unchanged at 507 human-effective LOC.

## False-positive adjudication of the passing run (Nova_Nova)

Not a false positive. The run passes 236 of 236 and diverges from the reference
on 6 of 11,729 probes, all one class: which spelling survives when `1` and
`True` fuse into a single literal argument. The reference keeps `1`, that run
keeps `True`.

The stated rule is that the two are one argument rather than two, and that is
what the tests require: the surviving literal carries exactly one argument, and
the argument set equals `{1}`, which a Python set cannot distinguish from
`{True}`. That run fuses them. It met the requirement.

Which spelling represents the fused argument is not stated, and it cannot be
without contradicting the rest of the description: the natural rule would be
whichever argument is met first, but union members and literal arguments are
explicitly unordered, so first is undefined for a union. The reference itself
returns `Literal[1]` or `Literal[True]` depending only on operand order.

The choice is observable, which is worth recording rather than hiding. beartype
accepts an `int` `1` against `Literal[1]` but not against `Literal[True]`, while
`Literal[True, 2]` accepts it again, so its single-argument literal check is
type-aware where its multi-argument one compares by equality. DOOR's own subhint
relation calls the two mutually subhints regardless. That inconsistency is the
package's, inherited by any implementation that follows the stated rule. The
description now says either spelling serves, turning a silent ambiguity into a
stated one, as it already does for member and argument order.
