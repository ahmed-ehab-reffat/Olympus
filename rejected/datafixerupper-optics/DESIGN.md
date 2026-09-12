# DESIGN.md — datafixerupper-product-focus

## 0. Phase 1 — repo understanding (gate: 5/5)

**Architecture (one paragraph).** DataFixerUpper is a bidirectional data-migration engine for versioned
save data. A `Type<A>` is a self-describing shape built from `TypeTemplate`s registered in a versioned
`Schema`: products (`Product`, `Pair`), sums (`Sum`, `Either`), tagged unions (`TaggedChoice`), lists
(`List`, `CompoundList`), plus `Named`, `Tag`, `Check`, `Hook`, `Const` and recursion points
(`RecursivePoint`, `RecursiveTypeFamily`). A `DataFix` expresses a migration by LOCATING a sub-part of a
type with an `OpticFinder`, which searches the type tree through `Type.findType` /
`findTypeInChildren` and yields a `TypedOptic` (a profunctor optic plus its source/target types); the
fix then rewrites that focus. `TypeRewriteRule` propagates rewrites structurally into a `RewriteResult`
carrying a `View` (a point-free function), which `PointFreeRule` later optimises. Separately,
`serialization/` holds the `Codec` DSL that reads and writes actual data through `DynamicOps`.

**Five subsystems + boundaries.**
1. `serialization/` — the Codec DSL (`Codec`, `MapCodec`, `DynamicOps`, `DataResult`). The only lane the
   maintainers touch (12 commits/24mo) and our approved pick's subsystem.
2. `datafixers/types/` (+ `templates/`, `families/`) — the type language and recursion machinery.
3. `datafixers/schemas/` — versioned type registries. Our in-flight pick's subsystem.
4. `datafixers/optics/` (+ `profunctors/`) — the profunctor optics library.
5. `datafixers/functions/` — the point-free algebra and its rewrite optimiser.
   (`datafixers/kinds/` supports all of them with the HKT encoding: `App`, `App2`, `K1`, `K2`,
   `Applicative`, `Traversable`.)

**Three high-entanglement zones.**
- `Type.findType` / `findTypeInChildren` — every `Type` subclass implements the search and each builds a
  `TypedOptic`; it couples `types/templates`, `optics/` and `TypedOptic` bound negotiation.
- `RewriteResult` / `View` / `TypeRewriteRule` — couples `types`, `functions` and `optics`.
- `RecursiveTypeFamily` / `RecursivePoint` — recursion threads through the other two.

**Test framework + location.** JUnit **4** (`junit-4.11.jar` is the only test jar in the base image);
tests live at `src/test/java/com/mojang/...`. Base has exactly two files, both under `serialization`:
`CodecTests.java` and `RoundtripTest.java` (52 tests total). **The datafixers engine has no tests at
base.**

**Formatting template.** `src/test/java/com/mojang/serialization/CodecTests.java` — 2-line MIT header,
`org.junit.Test`, static `assertEquals`/`assertTrue`, private static helpers at the top, `final` locals,
and **zero comments in test bodies**.

**Comment convention: NONE.** `optics/Lens.java`, `optics/Optics.java` and `TypedOptic.java` contain 2-3
comment lines each — exactly the MIT header. New code carries no doc comments and no inline comments.

## 0b. Phase 2 — existing-PR + publicly-solved check (CLEAN)

```
gh search prs   --repo Mojang/DataFixerUpper "product|pair|optic|traversal|findType|update all|both fields|only first|second field|compound list"
gh search issues --repo Mojang/DataFixerUpper  (same terms)
gh issue list -R Mojang/DataFixerUpper --state all --limit 60   (all 27 issues read)
```

- **No issue describes this gap.** The nearest hit, #108 "Several minor (performance) bugs, or oddities"
  (open, by `MotionlessTrain`), is entirely about `SortProj`/`SortInj` ordering in `PointFreeRule`,
  `Check.hmap` index checking, caching `RecursiveTypeFamily.everywhere`, and `DataResult` idioms. It does
  not mention product focusing. Its author says he intends a PR — a further reason `PointFreeRule` is
  off-limits, and independent confirmation that this lane is not what anyone is looking at.
- **No open PR touches the core files.** Full overlay of all 13 open PRs is in `feedback.md`.
  `Product.java`, `CompoundList.java`, the whole `optics/` package, `TypedOptic.java` and
  `OpticFinder.java` are untouched. (#109 touches `Sum.java` +2/-2, `TaggedChoice.java` +1/-1 and
  `Check.java` +1 — one-line plumbing, not core machinery.)
- **No refusal language anywhere in the tracker**, and no maintainer-published design for this.
- No external repo/crate implements "DFU's optic search focuses all product components" — the sentence
  cannot be written without DFU-internal nouns.

## 1. Title

**Extend the optic search to every matching component of a product**

Verb-led, 8 words, names the subsystem (the optic search). Category `enhancement` (first word `Extend`).

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (`SHAPES.md § Pattern 11-13`) — a new variant of an existing search
  plus a subtle correctness rule, with the difficulty in getting the composition right rather than in
  breadth.
- Pass-rate target: **10-25%**, ceiling 40% (sprint). Design to the low edge.
- Best agent: mixed (Orion decisive; the trap set punishes single-point fixes).
- Dominant verdict predicted: MISSED_REQUIREMENT (a fixed `Product` with an unfixed `CompoundList`, or a
  bound widened unconditionally).
- Solver/our LOC ratio: ~1.0-1.2x.

## 3. Public API surface

The capability is mostly a BEHAVIOUR change on existing public API, which is the fair shape (no signature
guessing). Exactly one new public name, pinned here:

- `com.mojang.datafixers.optics.PairTraversal<F, G, F2, G2, A, B>` — `implements Traversal<Pair<F, G>,
  Pair<F2, G2>, A, B>`; constructed by
  `Optics.pairTraversal(Optic<? super TraversalP.Mu, F, F2, A, B> left, Optic<? super TraversalP.Mu, G, G2, A, B> right)`.
  Visits the left focus then the right focus in one applicative pass.

Existing names the tests assert through (unchanged signatures):
- `DSL.and(Type<F>, Type<G>) -> Type<Pair<F, G>>`
- `DSL.compoundList(Type<K>, Type<V>) -> CompoundList.CompoundListType<K, V>`
- `DSL.list(Type<A>)`, `DSL.or(Type<F>, Type<G>)`, `DSL.named(String, Type<A>)`, `DSL.field(String, Type<A>)`
- `Type.finder() -> OpticFinder<A>`
- `Type.findType(Type<FT>, Type<FR>, TypeMatcher<FT, FR>, boolean) -> Either<TypedOptic<A, ?, FT, FR>, FieldNotFoundException>`
- `Typed.update(OpticFinder<FT>, Function<FT, FT>) -> Typed<?>`
- `Typed.getOptional(OpticFinder<FT>) -> Optional<FT>`
- `TypedOptic.bounds() -> Set<TypeToken<? extends K1>>`

## 4. Canonical output form

- **Visit order:** left component before right; for a compound list, key before value; for nested
  products, depth-first left-to-right, so `((a,b),(c,d))` visits a, b, c, d in that order.
- **Result shape:** a product's shape is preserved; updating both components returns a pair of the same
  arity, never a flattened or reordered structure.
- **One-sided match:** when only one component matches, the returned optic is exactly what base returns
  today, including its `bounds()` — a `Cartesian`-bounded lens, not a traversal.
- **No match:** unchanged — `Either.right(FieldNotFoundException)`.
- **Empty containers:** a compound list with no entries updates nothing and returns an equal value.
- **`recurse` flag:** honoured unchanged; merging applies at each level the search descends into.
- **Reading one value:** `get` / `getOptional` / `getOrDefault` / `getOrCreate` return the FIRST matching
  component in visit order, and must not throw.
- **Reading every value:** `getAll` / `getAllTyped` return every matching component in visit order.
- **Setting one value:** `set` sets EVERY matching component.

## 5. Blind-spot pre-empts (`DESCRIPTION.md` sentence bank)

- *Result ordering* — "updates apply to both, in left-to-right order".
- *Adjacent-vs-all* — "every matching component", not "the matching component".
- *Unstated inverse* — "when only one component matches, the search keeps the behaviour and the optic
  kind it has today".
- *Iteration termination* — nested products compose to all leaves.
- ≤1 codebase-inferable requirement: the visit order for `CompoundList` (key before value) is inferable
  from the existing field order, and is stated anyway.

## 6. Description draft (meta.md, ~215 words)

> Extend the optic search so a data fix reaches every matching component of a product type.
>
> When a fix looks for a type inside a structure, the search walks the type tree and returns an optic
> focused on what it found. For a list it focuses every element, and for a sum it focuses the match in
> whichever branch is inhabited. For a product it stops at the first component that matches, so a pair
> whose components both contain the searched type is rewritten only in the first one, and a compound list
> whose key and value types both match is rewritten only in the key.
>
> Make a product-shaped search focus all of its matching components. When both components of a pair
> match, an update applies to both, in left-to-right order, and the pair keeps its shape. The same holds
> for the key and the value of a compound list, key first. Nested products compose, so a pair of pairs
> reaches all four leaves. This holds both inside and outside recursive types.
>
> A focus that covers several components still has to serve the callers that expect a single value.
> Reading one value returns the first matching component in visit order rather than failing, reading all
> of them returns every match in that order, and setting one value sets every match. When only one
> component matches, the search keeps the behaviour and the optic kind it has today, so fixes that rely
> on a lens keep working.

~215 words, under the 500 hard cap. No `##` headers, no labels, backticks only on the one new public
name, ASCII only. The final paragraph is what forces the consumer layer, and it states WHAT is
observable without naming `upCast`, `bounds`, `Getter` or `TraversalP`.

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful (~0.65) | Reason |
|---|---|---|---|---|---|
| NEW | `optics/PairTraversal.java` | — | +120 | ~95 | the two-focus heterogeneous traversal (`wander`) |
| MODIFY | `types/templates/Product.java` | 258 | +110 | ~75 | merge branch + product-merge helper + bound negotiation |
| MODIFY | `types/templates/CompoundList.java` | 192 | +95 | ~65 | same for key/value, wrapped in the list traversal |
| MODIFY | `TypedOptic.java` | 269 | +55 | ~40 | merge constructor + bound widening only when both sides match |
| MODIFY | `optics/Optics.java` | 328 | +45 | ~30 | `pairTraversal` factory + `toTraversal` support |
| MODIFY | `types/Type.java` | 307 | +25 | ~18 | plumb the merged result through `findType` |
| **TOTAL** | **6 files, 3 packages** | | **+450** | **~320** | |

### ⚠️ SPIKE MEASUREMENT — the sketch above is WRONG (measured 2026-09-10, before writing any tests)

Per `feedback_spike_before_scoping` / `feedback_machinery_absorption_loc_check`, the largest new file was
implemented as a throwaway spike and compiled clean in the container:

`optics/PairTraversal.java` = **38 raw / ~26 meaningful**, against a sketched 120 raw / ~95 meaningful —
a **3.6x overshoot**. Cause is exactly the recorded absorption pattern: `Applicative.ap2`,
`Applicative.point`, `Wander` and the `Traversal` interface all already exist, so the two-focus traversal
is a thin call-through:

```java
final App<T, F2> first = leftWander.apply(pair.getFirst());
final App<T, G2> second = rightWander.apply(pair.getSecond());
return applicative.ap2(applicative.point(combine), first, second);
```

Re-estimating every row on the same basis (`Sum.mergeOptics` is ~45 raw for the DISPATCHING version and
is the correct sibling to measure against):

| Piece | sketched (meaningful) | **measured / re-estimated** |
|---|---|---|
| `optics/PairTraversal.java` | 95 | **26 (measured)** |
| `Product` merge | 75 | 30-40 |
| `CompoundList` merge | 65 | 30-40 |
| `TypedOptic` bounds | 40 | 15-25 |
| `Optics` factory | 30 | 8-12 |
| `Type` plumbing | 18 | ~10 |
| **TOTAL** | ~320 | **~120-165** |

**That is BELOW the 200 floor.** The pick as scoped in this document does not ship. Padding is banned.

Two further findings from the same spike, both of which REMOVE candidate levers:

- `Typed.getAll(TypedOptic)` and `Typed.getAllTyped(OpticFinder)` **already exist** (`Typed.java:168,173`).
  The read side is therefore broken by the SAME kernel — excellent free interdependence for the trap
  matrix, but zero additional LOC.
- `Product.all(rule, recurse, checkIndex)` **already merges both children**
  (`mergeViews(first.rewriteOrNop(rule), second.rewriteOrNop(rule))`), and `Product.one` picks exactly one
  by its documented contract. The `TypeRewriteRule` path is correct; only the optic-search path is
  asymmetric. This makes the contract MORE fair (the repo now shows the right behaviour on three
  independent axes: `ListTraversal`, `Sum.mergeOptics`, and `Product.all`) but supplies no second lever.

### RESOLUTION (spiked 2026-09-10) — the lever is the CONSUMER layer, and it is forced, not bolted on

The named candidate lever `OpticFinder.both` was spiked and is **UNIMPLEMENTABLE**, which is the
[[feedback_unimplementable_contract_clause]] class: `TypedOptic` is
`record TypedOptic(Set<TypeToken> bounds, List<Element> elements)` — a COMPOSITION CHAIN with no parallel
constructor. Merging two arbitrary optic paths over the same `S` cannot be expressed in profunctor optics
without structurally decomposing `S`, which is exactly why `Sum`/`TaggedChoice`/`Product` can merge (they
know the shape) and a general combinator cannot. Lever dropped.

**The real lever was found by probing the CONSUMERS of a multi-focus optic on base.** `ListTraversal` is
already multi-focus, so the downstream behaviour is measurable today:

```
LIST get      threw: IllegalArgumentException: Couldn't upcast
LIST getOptional threw: IllegalArgumentException: Couldn't upcast
LIST set      threw: IllegalArgumentException: Couldn't upcast
LIST getAllTyped -> 2          (works)
LIST update      -> [x!, y!]   (works)
PROD getAllTyped -> 1          (the same product bug, on the READ side)
```

Only `getAll`/`getAllTyped` and `update` accept a traversal-bounded optic. `get`, `getOptional`,
`getOrDefault`, `getOrCreate` and `set` demand a `Getter`/`Cartesian` proof and throw from
`TypedOptic.apply`'s `upCast(...).orElseThrow()`.

**Consequence: the moment `Product`/`CompoundList` start returning a traversal, every single-value
consumer breaks for those types.** So the capability is not "merge two optics" — it is *make multi-focus
optics work end-to-end*, which forces a stated decision at each consumer. That is genuine cross-stage
integration (F-9 in its measured form: one root cause breaks every capability at once), and the failure
surfaces as `Couldn't upcast` inside `TypedOptic`, a file the agent never edited — misdirecting.

**Re-estimate with the consumer layer included:**

| Piece | meaningful |
|---|---|
| `optics/PairTraversal.java` | 26 (measured) |
| `Product` merge | ~35 |
| `CompoundList` merge | ~35 |
| `TypedOptic` merge + bound negotiation | ~25 |
| `Optics` factory | ~10 |
| `Type.getSetType` / `findType` plumbing | ~30 |
| **`Typed` single-value consumers over multi-focus optics** | **60-80** |
| **consumer upcast path / Getter-compatible fallback** | **40-60** |
| **TOTAL** | **~260-300** |

Clears the 200 floor with buffer, and every added line is forced integration work rather than padding.

### Contract additions this forces (into § 4 and § 6)

- **Reading one value** (`get`, `getOptional`, `getOrDefault`, `getOrCreate`) returns the **first**
  matching component in visit order, and keeps working rather than throwing.
- **Setting one value** (`set`) sets **every** matching component.
- **`getAll`/`getAllTyped`** return every matching component in visit order (today a product returns 1).
- One-sided matches keep today's behaviour, optic kind and `bounds()` exactly.

## 8. Solution outline — pure-function helpers

- `PairTraversal.wander(Applicative<F,?>, FunctionType<A, App<F,B>>) -> FunctionType<Pair<F,G>, App<F, Pair<F2,G2>>>`
  ← description requirement "applies to both, left-to-right". Sequences with
  `applicative.ap2(applicative.point(Pair::of), left, right)`; the left effect is built first so the
  order is observable for effectful updates.
- `Optics.pairTraversal(left, right)` ← "both components".
- `Product.mergeOptics(TypedOptic<F,F2,A,B>, TypedOptic<G,G2,A,B>) -> TypedOptic<Pair<F,G>, Pair<F2,G2>, A, B>`
  ← "every matching component"; mirrors `Sum.mergeOptics` in role, not in construction.
- `CompoundList.mergeOptics(keyOptic, valueOptic)` ← "key and the value ... key first"; composes the
  pair traversal under `ListTraversal`.
- `TypedOptic.mergedBounds(Set, Set)` ← "keeps the optic kind it has today" (widen to `TraversalP.Mu`
  only on a genuine two-sided merge).

No fixpoint loop is needed; the recursion is the existing type-tree walk.

## 9. Test file outline

Path: `src/test/java/com/mojang/datafixers/ProductFocusTest_<hex>.java` (random hex suffix, no banned
markers). JUnit 4, `CodecTests.java` layout.

Block 1 — imports. Block 2 — builder helpers (`prod(a,b)`, `cList(k,v)`, `typed(type,value)`,
`upd(typed, finder, fn)`, ~12 one-liners). Block 3 — assertion helpers
(`assertUpdates(type, value, expected)`, `assertBounds(optic, token)`, `assertNotFound(type)`).
Block 4 — buckets:

- both-components product (both update, order, shape preserved) — 10
- compound list key+value (key first; empty list; many entries) — 9
- one-sided match preserves behaviour AND bounds (left-only, right-only, lens kind) — 8
- nested products (pair of pairs -> 4 leaves; product inside list; product inside sum branch) — 9
- interaction with `Named` / `Tag` / `Check` wrappers around a merged product — 6
- recursion (`recurse=true` and `false`) — 5
- edge cases (no match, empty, single, unicode string payload, deep nesting) — 7
- stated inverse (a type matching neither component is untouched) — 3
- **single-value consumers over a merged focus** (`get`/`getOptional`/`getOrDefault`/`getOrCreate` return
  the first component and do NOT throw; `set` sets both; `getAll`/`getAllTyped` return both, in order) — 12
- **consumer behaviour is unchanged for one-sided matches and for lists** (no regression in the
  already-multi-focus `ListTraversal` path) — 6

Target ~75 tests. **Decomposed per ATOM**: every positive claim has its negative twin (updates both /
does not update a non-matching sibling; widens the bound on a two-sided merge / does NOT widen on a
one-sided match).

## 10. Forced trait bounds / generics

Discovered test-first: `PairTraversal` must be `Traversal<Pair<F,G>, Pair<F2,G2>, A, B>` so that
`TypedOptic.upCast(TraversalP.Mu.TYPE_TOKEN)` succeeds, and the two child optics must share the SAME
focus types `A`/`B` — which is exactly the condition under which the merge is legal. `TypedOptic.compose`
unions bounds and `instanceOf` requires ALL bounds to be supertypes of the proof, so widening is
observable. These are pinned in §3/§4 so no agent has to guess a signature.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal class | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | Fix `Product` and miss `CompoundList` | F-10 | S2 composition of documented rules | container kind | #2 | the two sites look independent; `CompoundList` hides the pair behind a list traversal | "The same holds for the key and the value of a compound list, key first." | compound-list key+value bucket |
| 2 | Widen the bound unconditionally to `TraversalP` | F-3 | S3 baseline-preservation through a shared chokepoint | optic kind | #1, #3 | the merge path is the natural place to set the bound once | "the search keeps the behaviour and the optic kind it has today" | one-sided-match bounds bucket + the 52 base tests |
| 3 | Sequence the two foci in the wrong order, or with two applicative passes | F-6 | A-tier ordering inversion | visit order | #1 | `ap2(point(Pair::of), l, r)` vs building right first reads identically until the update is effectful | "in left-to-right order" | order bucket (effectful updater recording a trace) |
| 4 | Merged product inside a `Sum` branch or a `List` fails to compose | F-5 | S4 machinery-riding integration | composition depth | #2 | a Traversal-of-Traversal needs the bound union to stay consistent | "Nested products compose, so a pair of pairs reaches all four leaves." | nested bucket |
| 5 | **Merge the optic and leave the single-value consumers throwing `Couldn't upcast`** | **F-9** | S6 two-evaluators | consumer layer | #1, #2 | the exception is raised by `TypedOptic.apply`'s `upCast(...).orElseThrow()` — a file the agent never edits — so the failure surfaces far from the merge site they wrote | "Reading one value returns the first matching component in visit order rather than failing ... setting one value sets every match." | single-value-consumer bucket |

Every row names an F-id, the axes differ (container kind / optic kind / visit order / composition depth /
consumer layer), and rows 1-2, 2-3 and 1-5 are interdependent: setting the bound in the shared chokepoint to fix #2 changes
what #1's second site returns, and #3 lives inside the same `wander` that #4 composes. **#5 is the F-9 row and the cheapest source of
interdependence in the design: the single root cause (a product now yields a traversal) breaks `get`,
`getOptional`, `getOrDefault`, `getOrCreate` and `set` simultaneously, in a file the agent never touched.**

CONTRACT-STATED / FIX-HIDDEN verified for each: the sentences state WHAT is observable (both updated,
order, kind preserved, nesting composes) and none of them names `wander`, `ap2`, `TraversalP` or the
merge site.

## 11b. Capability cross-product matrix (F-10)

Axis 1 = container kind. Axis 2 = how many children match.

| | one child matches | **both children match** |
|---|---|---|
| **Product** | test: lens returned, bounds unchanged, only that side updates | test: both update, left-to-right, shape preserved |
| **CompoundList** | test: key-only match behaves as today | **off-diagonal** test: key AND value both update, key first |
| **Product nested in List** | test: unchanged | **off-diagonal** test: every element's both components update |
| **Product nested in Sum** | test: unchanged | **off-diagonal** test: inhabited branch's both components update |

Every off-diagonal cell has a test. Predicted failure mode is OVER-firing (the one-sided case widened to
a traversal, or a component visited twice through a nested merge), which is misdirecting.

Format-noun audit: "component" is stated to mean a direct child of the product, and "compound list"
key/value are named explicitly. Example audit: the description gives one example (pair of pairs) attached
to the general nesting rule; it is a consequence, not a scope limit, and is phrased as such.

## 12. Tier + category

- Tier: Olympus (one tier).
- Category: **enhancement** (title verb `Extend`; the behaviour exists and is being corrected/extended).

## 13. Predicted pass rate

**10-22%.** Reasoning: one obvious site (`Product`) that most agents will find from the description, plus
a second site (`CompoundList`) that is easy to miss, plus a bound-preservation rule, plus an ordering rule
only observable with an effectful updater, plus the consumer layer (#5) which an agent only discovers by
running the single-value accessors against a merged focus. The floor is protected
because the repo shows the correct pattern twice (`ListTraversal` and `Sum.mergeOptics`), so a careful
agent can succeed. Under the 40% ceiling with margin; not near 0% because the gap is stated plainly.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5
- [x] Phase 2 clean (searches pasted in § 0b)
- [x] Closest approved opened as scaffolding (`approved-problems/datafixerupper-ordered-alternatives`)
- [x] Title verb-led, 8 words, names the subsystem
- [x] Shape declared with citation
- [x] Public API surface lists every name tests assert; the one new name is fully pinned
- [x] Canonical form spelled out (order, shape, one-sided case, empty, recurse)
- [x] ≤1 codebase-inferable requirement
- [x] Description ~190 words, no headers, no labels, ASCII
- [x] File footprint: **~260-300 meaningful** after the consumer layer was spiked in; 8 files, 3 packages. `PairTraversal` measured at 26; the rest re-estimated against measured siblings
- [x] 1+ pure helper per description sentence
- [x] Test outline 4-block, scenario-encoded names, per-ATOM decomposition
- [x] Forced generics documented and pinned
- [x] 4 traps, each with F-id, differing axes, 2 interdependent pairs
- [x] § 11b cross-product filled; every off-diagonal cell has a test
- [x] Unbounded-promise audit: no promise about iteration counts or depth limits
- [x] Stated-noun list: product, component, pair, compound list, key, value, list, sum, branch, optic,
      lens, order, recursion — every fixture's subject is on it
- [x] Predicted pass ≤40%
- [x] Category matches the title verb
- [x] Not pattern-followable (the sibling `Sum.mergeOptics` dispatches; this must sequence)

## Why this is not a duplicate

Closest prior art in our own corpus is `approved-problems/datafixerupper-ordered-alternatives`
(`serialization/Codec` alternatives) and the in-flight `problems/datafixerupper-derived-recursion`
(`datafixers/schemas` construction). This pick is in `datafixers/optics` + `types/templates`, touches
neither file set, and its central capability is an optic-search semantics change rather than a codec or a
schema-construction change.

Predicted iteration cycles: 2 (after the LOC resolution in § 7 lands).


---

# ⛔ OUTCOME 2026-09-10 — IMPLEMENTED, MEASURED, AND SHELVED AT THE LOC FLOOR

The design above was implemented in full and works. It is shelved because the capability is
**88 human-effective LOC** against a 200 floor, and padding is banned.

## What was built and verified

All six files, compiling and behaving to contract, verified in Docker offline non-root:

```
PRODUCT  (x,y)   update all String -> (x!, y!)      (was (x!, y))
CMPDLIST [(k,v)] update all String -> [(k!, v!)]    (was [(k!, v)])
PROD getAllTyped -> 2                               (was 1)
PROD set         -> (Z, Z)                          (was IllegalArgumentException)
LIST get         -> x                               (was IllegalArgumentException)
LIST set         -> [Z, Z]                          (was IllegalArgumentException)
```

Base suite: **52/52, three runs identical**, no regressions. The working diff is kept as
`solution-partial.patch`.

## The measurement that killed it

```
raw added:         121   (target >= 320)
human-effective:    88   <- gate; floor 200, hook target 275
  Typed.java         29     TypedOptic.java   20     PairTraversal.java  25
  Product.java        6     CompoundList.java  6     Optics.java          2
```

## The lesson — DFU's optics lane is FRAMEWORK-MATURE, and every estimate overshot ~3x

| Stage | estimate | measured | ratio |
|---|---|---|---|
| initial sketch | ~320 | — | — |
| after spiking `PairTraversal` | ~120-165 | — | 2x down |
| after adding the consumer layer | ~260-300 | **88** | **3x over** |

Both re-estimates failed the same way: every piece turned out to be a thin call-through because the
machinery already exists. The consumer layer, predicted at 60-140, is **29 effective lines** — three
`if (TypedOptic.instanceOf(bounds, token))` guards reusing the existing `getAll` and `updateCap`. The
merge sites are **6 lines each**, because `Sum.mergeOptics`, `ListTraversal`, `Optics.toTraversal` and
`TypedOptic.compose` already do the work.

This is `PICK-FILTER` Gate 4's death class exactly: a surgical fix to mostly-correct code. It is also the
hunt skill's own warning about framework maturity — "the better the abstraction, the smaller your diff".

## Why this does not condemn the repo

Both DFU picks that DID work added machinery the repo **lacked entirely**:
`datafixerupper-ordered-alternatives` (a new codec type) and `datafixerupper-derived-recursion` (a
reference graph over type templates + cycle detection + a two-phase schema build, 275 eff). A DFU pick
must bring a NEW ALGORITHM, not ride the optic machinery. A third probe confirmed the lane's shape:
focusing a compound list's `Pair<K,V>` entry throws `No more children`, so an entry/indexed traversal is
NOT absorbed either — but it is the same shape (a case in `findTypeInChildren` plus existing optics) and
would collapse the same way.

**Verdict: the optic-search lane in DataFixerUpper cannot carry an Olympus submission. The repo remains
authorable for a pick that brings its own algorithm.**
