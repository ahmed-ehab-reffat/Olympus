# DESIGN.md — beartype-door-hint-algebra

## 1. Title

Add hint simplification and meets to the DOOR API

Repo: https://github.com/beartype/beartype (MIT, 3481 stars, pushed 2026-08-06, Python).
Base commit: `687adb0356327668d9cf1a6993b9b66c5cb4d635`.

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (PLAYBOOK Pattern 12) — a new operation whose difficulty is
  subtle semantic correctness on an existing engine, spanning that engine's whole class hierarchy.
- Pass-rate target: <= 40% cap, designed for the corpus mode of ~1/10.
- Best agent: Mixed.
- Dominant verdict: MISSED_REQUIREMENT (an unimplemented rule of the lattice) and
  INTEGRATION_ERROR (a rule implemented on one wrapper subclass but not the sibling that shares
  the kernel).

`beartype.door` already exposes a *partial order* on type hints (`is_subhint`). It exposes no
*lattice*: no canonical form, no greatest lower bound, no disjointness test. The whole feature is
one kernel (union normalisation + a meet dispatcher) driving eleven wrapper subclasses, which is
corpus hardness lever 1.

## 3. Public API surface

New methods on `beartype.door.TypeHint`:

- `simplify() -> TypeHint` — canonical form of this hint.
- `join(other: TypeHint) -> TypeHint` — least upper bound (canonical union), also `|`.
- `meet(other: TypeHint) -> Optional[TypeHint]` — greatest lower bound, `None` when disjoint, also `&`.
- `difference(other: TypeHint) -> Optional[TypeHint]` — relative complement, `None` when empty, also `-`.
- `is_disjoint(other: TypeHint) -> bool` — `True` only when `meet()` is `None`.

New functions and class in `beartype.door` (raw hints in, raw hints out, mirroring `is_subhint`):

- `simplify_hint(hint) -> hint`
- `join_hints(hint1, hint2) -> hint`
- `meet_hints(hint1, hint2) -> Optional[hint]`
- `difference_hints(hint1, hint2) -> Optional[hint]`
- `is_disjoint(hint1, hint2) -> bool`
- `cover_hint(hint, hints) -> HintCoverage`
- `HintCoverage.residual` / `.matched` / `.unreachable` / `.overlapping` / `.removable` / `.is_exhaustive`

Errors: `beartype.roar.BeartypeDoorException` (already public) is raised by the existing
`die_unless_typehint` guard when a non-wrapper is passed to a method.

## 4. Canonical output form

- Union member order and literal argument order: **unspecified**. DOOR caches wrapper instances
  order-insensitively, so order is not observable through the public API; asserting it would be
  order-flaky (confirmed empirically, then removed from both spec and tests).
- Literal fusion: all `Literal` members fuse into one `Literal`, arguments deduplicated.
- Literal-argument absorption: the fused literal loses every argument another member accepts and
  disappears when none survives.
- Dedup: DOOR-equal members collapse to one.
- Absorption: a member that is a subhint of a **different surviving** member is dropped; at least
  one member always survives.
- `Any` in a union: the whole union simplifies to `Any`.
- Single surviving member: the union collapses to that member (no 1-member union).
- Unchanged hints: a hint already in canonical form is returned **unchanged** (identity).
- Rebuilt hints: the origin class subscripted by the new children (PEP 585 form), `Literal[...]`
  for literals, `Annotated[metahint, *metadata]` for annotated hints, and the repo's own
  `make_hint_pep484604_union` for unions.
- Disjoint meet: Python `None` (never a `NoneType` hint, which stays `type(None)`).

## 5. Blind-spot pre-empts

- Result ordering: stated as absent, so no test can pin an unobservable order.
- Adjacent-vs-all: absorption compares each member against every other member, not neighbours.
- Dedup strategy: equal members collapse to one, stated.
- Compound order preservation: elementwise meets keep child position (tuples, callables).
- Falsy-on-invalid: disjointness returns `None`, not an exception.
- Rule resolution: the meet rule precedence list is stated in order.

At most one codebase-inferable requirement (that the repo's own union factory exists; the spec
does not require its use).

## 6. Description draft

See meta.md (dense prose, 684 words, within the approved corpus band of 297-834).

## 7. File footprint

| Action | Path | Raw delta | Reason |
| --- | --- | --- | --- |
| NEW | `beartype/door/_cls/util/doorlattice.py` | +150 | union normalisation kernel (flatten, dedup, fuse, absorb, build) |
| MODIFY | `beartype/door/_cls/doorsuper.py` | +230 | public `simplify`/`join`/`meet`/`is_disjoint` + `_simplify`/`_meet_branch`/`_make_hint` defaults |
| MODIFY | `beartype/door/_cls/pep/doorpep484604.py` | +60 | union simplification + meet distribution |
| MODIFY | `beartype/door/_cls/pep/doorpep586.py` | +65 | literal fusion, literal-vs-literal and literal-vs-class meets |
| MODIFY | `beartype/door/_cls/pep/doorpep593.py` | +55 | annotated metadata rules |
| MODIFY | `beartype/door/_cls/pep/pep484/doorpep484any.py` | +25 | `Any` identity/absorbing rules |
| MODIFY | `beartype/door/_cls/pep/pep484585/doorpep484585subscripted.py` | +55 | origin narrowing + elementwise meet |
| MODIFY | `beartype/door/_cls/pep/pep484585/doorpep484585tuple.py` | +85 | fixed/variadic tuple meets |
| MODIFY | `beartype/door/_cls/pep/pep484585/doorpep484585callable.py` | +85 | callable param-shape meets and rebuild |
| NEW | `beartype/door/_cls/doorcover.py` | +146 | sequential coverage, overlap and removability analysis |
| MODIFY | `beartype/door/_func/doorfunc.py` | +241 | six procedural wrappers |
| MODIFY | `beartype/door/__init__.py` | +8 | exports |

SHIPPED: 1771 raw / **472 human-effective** across 11 files (>= 450 design floor, 400 auto-block).

## 8. Solution outline — pure-function helpers

`doorlattice.py`:

- `reduce_hint_wrappers_union(wrappers) -> tuple` — flatten, `Any`, dedup, fuse, thin, absorb.
- `flatten_hint_wrappers(wrappers) -> list` — inline nested unions.
- `fuse_hint_wrappers_literal(wrappers) -> list` — fuse `Literal` members into one.
- `absorb_hint_args_literal(wrappers) -> list` — drop literal arguments another member accepts.
- `absorb_hint_wrappers(wrappers) -> list` — drop members subsumed by a different survivor.
- `make_hint_wrappers_union(wrappers)` — build the union wrapper, collapsing a lone member.
- `subtract_hint_wrappers(wrapper, other)` — the difference kernel.

`doorsuper.py`:

- `simplify()`, `join(other)`, `meet(other)`, `difference(other)`, `is_disjoint(other)` public
  methods plus the `|`, `&` and `-` operators.
- `_simplify_wrapper() -> TypeHint` — default: rebuild from simplified children, identity-preserving.
- `_meet_simplified(other)` — resolution order: `Any`, union distribution, family rule, subhint.
- `_meet_branch(branch) -> Optional[TypeHint]` — default: the subhint relation; each family owns
  its own answer so no family inherits a hole in that relation.
- `_make_hint(args) -> Hint` — default: `self._origin[args]`, subclass-overridden.

No fixpoint loop: one reduction pass reaches the canonical form, since fusion and absorption
commute. Recursion is depth-first over `_args_wrapped_tuple` (children before parents).

## 9. Test file outline

Path: `beartype_test/a00_unit/a30_api/door/a80_algebra/test_door_hintalgebra_<hex>.py`
(random hex suffix; no banned markers).

Block 1 — imports (stdlib `typing`, `collections.abc`, `beartype.door`).
Block 2 — builder helpers: `_args(hint)`, `_union_args(hint)`, `_origin(hint)`, small class
hierarchy (`Animal`/`Dog`/`Puppy`, `Vehicle`).
Block 3 — assertion helpers: `_assert_hint(actual, expected)` (DOOR equality + structural args),
`_assert_disjoint(a, b)`.
Block 4 — buckets:

- simplify: unions, nested unions, dedup, literal fusion, absorption, `Any`, collapse, identity,
  recursion into children, annotated, idempotence.
- join: least-upper-bound behaviour, order, absorbing.
- meet: `Any`, subhint shortcut, union distribution, literals, subscripted origin narrowing,
  tuples (fixed/variadic/empty), callables (param shapes), annotated metadata, disjointness.
- invariants: `meet(a,b) <= a` and `<= b`, `a <= join(a,b)`, symmetry of `is_disjoint`, and a
  runtime oracle: `is_bearable(obj, meet)` iff `is_bearable(obj, a) and is_bearable(obj, b)` over
  a fixed corpus of objects.
- edge cases: empty tuple hint, unsubscripted vs subscripted, `None`/`NoneType`, NewType,
  single-member union input, disjoint-everything unions.

Target: 90-120 granular `def test_*` functions, no `pytest.mark.parametrize` (bracketed node ids
score as missing F2P nodes).

## 10. Forced signatures

- `meet` returns `Optional[TypeHint]`; `meet_hints` returns `Optional[Hint]`. Pinned in meta so no
  agent has to guess (avoids the fake-difficulty signature coin-flip).
- `simplify_hint`/`join_hints` take and return raw hints, like `is_subhint`.
- `is_disjoint` exists both as a method (one argument) and a function (two arguments).

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt in meta | Test |
| --- | --- | --- | --- | --- |
| 1 | A fused literal loses only the arguments another member accepts | Naive code either keeps the whole literal or drops it whole | stated | `test_simplify_union_literal_arguments_absorbed_by_member` (2 kills) |
| 2 | Simplification must compare children by identity, not by DOOR equality (equality is the mutual subhint relation, under which a hint equals its own canonical form) | The obvious "did anything change?" test silently skips every nested reduction | canonical form of children is stated | `test_simplify_list_child_union` and siblings (5 kills) |
| 3 | Meet of two subscripted hints takes the NARROWER origin | Obvious code keeps the left origin | "the narrower of their two origins" | `test_meet_subscripted_narrows_origin` and siblings (3 kills) |
| 4 | Meet distributes over unions and must re-simplify + drop disjoint pairs | Agents return a union of raw pairwise meets including duplicates | "the union of the surviving meets in canonical form" | `test_meet_union_distributes_and_simplifies` |
| 5 | Literal vs class meet keeps only literals whose type is a subhint | Agents return the whole literal or the class | stated | `test_meet_literal_and_type_filters_literals` |
| 6 | Callable/tuple shape rebuild (`...`, `[]`, fixed vs variadic) | Rebuilding a Callable from wrapped args is fiddly; naive code emits `Callable[[Any], R]` for `...` | stated per shape | `test_meet_callable_ellipsis_params`, `test_meet_tuple_fixed_and_variadic` |
| 7 | Identity: an already-canonical hint is returned unchanged | Rebuild-always implementations return a new object | stated | `test_simplify_class_unchanged` and siblings |
| 8 | Coverage matches each hint against the RESIDUAL, not the covered hint | The obvious loop meets every arm with the subject | stated | `test_cover_matched_against_residual_only` (4 kills), `test_cover_unreachable_repeated_hint` (13 kills for an un-narrowed residual) |
| 9 | Difference removes whole members only, narrowing literals argument-wise | Agents narrow overlapping members or drop them | stated | `test_difference_superhint_unchanged`, `test_difference_literal_by_type` (6 and 3 kills) |

Traps 1/2/4 share the normalisation kernel, and 3/6 share the rebuild path, so a local fix to one
surface regresses another (interdependent). The failing assertion for 1 and 4 is a union member
list, which does not name the ordering rule that caused it (misdirecting).

## 12. Tier + category

- Tier: Olympus. Sub-rank: Good/Excellent.
- Category: feature-request (net-new public API).

## 13. Predicted pass rate

10-25%. Levers stacked: one interdependent kernel (1), a runtime oracle via `is_bearable` fuzzed
to zero mismatches (2), misdirecting traps (3), "obvious code is wrong" edges — origin narrowing,
mutual absorption (4), a bespoke non-spec surface: no PEP defines hint meets (5), and an
11-file span (6).

## 14. Quality gate

- [x] Repo understanding: architecture (a decorator + a checker + DOOR + util layers), subsystems
      (`beartype._check`, `beartype._decor`, `beartype.door`, `beartype.vale`, `beartype._util`),
      entanglement zones (`door/_cls`, `_check/convert/_reduce`, `_util/hint/pep`), pytest with
      `beartype_test/`, template test `beartype_test/a00_unit/a30_api/door/a00_type/test_door_typehint.py`.
- [x] Existing PR/issue check: `gh pr list -R beartype/beartype --state all --search "simplify|normalize|intersection|lattice|union|TypeHint"` and the matching issue searches. No PR or issue
      implements or requests hint simplification, meets, or disjointness. Issue #133 (the origin of
      DOOR) requests `is_subhint`, which already shipped. No maintainer decline.
- [x] Closest approved problems opened: `techan-costbasis` (dense enumerated meta over one engine)
      and `surrealkv-merge-operator` (invented operator threaded through an existing kernel).
- [x] Corpus recipe: kernel + oracle + >= 3 interdependent misdirecting traps + pinned signatures.
- [x] Canonical output form spelled out.
- [x] Not pattern-followable: no existing DOOR operation returns a rebuilt hint.
- [x] Offline, deterministic, zero-dependency test environment (421 base tests, 22s).

### Why this is not a duplicate

Closest approved siblings: `surrealkv-merge-operator` (a merge operator over an existing storage
kernel) and `pysmt-bit-blasting` (a transformation over an existing formula engine). Both operate
on values; this operates on *type hints* and extends a published partial order into a lattice. No
problem in `Instructions/Aprroved/`, `problems/`, or `rejected/` targets beartype or any runtime
type-checking library, and none targets hint canonicalisation.

Predicted iteration cycles: 2.
