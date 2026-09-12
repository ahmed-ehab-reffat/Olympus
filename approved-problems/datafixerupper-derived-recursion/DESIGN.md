# DESIGN.md — datafixerupper-derived-recursion

## 1. Title

**Derive schema type recursion from the type template graph**

Verb: Derive (feature-request family: adds a net-new derivation plus new public API). Names the
subsystem (`Schema` / type templates). 8 words.

## 2. Shape classification

- **Shape:** O-Algorithm-correctness (`SHAPES.md § Pattern 12`) — a new load-bearing derivation
  whose difficulty is subtle algorithmic correctness (cycle membership, a least fixed point, a
  dependency-ordered build), not breadth of API.
- **Pass rate target:** 15-30%, design centre ~20%. Sprint ceiling <=40%; 0% = reject.
- **Best agent:** Orion (decisive commit-and-implement suits a spec with many stated invariants).
  Mixed batch: Orion + Nova.
- **Dominant verdict:** MISSED_REQUIREMENT (the stated-but-easily-conflated rules), with
  REGRESSION second (per-group ids / build order break decode).
- **Solver/our LOC ratio:** expect ~1.0-1.3x (O-Algorithm shapes cluster near 1.0).

## 3. Public API surface

Every name a test will assert:

- `Schema.registerType(DSL.TypeReference type, Supplier<TypeTemplate> template)` — new 2-arg
  overload; registers without the recursion flag.
- `Schema.registerType(boolean recursive, DSL.TypeReference type, Supplier<TypeTemplate> template)`
  — existing signature; `recursive` now means "force recursive even if it lies on no cycle".
- `Schema.recursiveTypeNames() -> List<String>` — the recursive type names, registration order.
- `Schema.recursionGroups() -> List<List<String>>` — the recursion groups.
- `Schema.typeReferences(DSL.TypeReference type) -> List<String>` — the distinct registered types
  that type's template refers to, registration order.
- `UninhabitedRecursionException extends IllegalStateException` (package
  `com.mojang.datafixers.schemas`) — thrown from the `Schema` constructor.
- `UninhabitedRecursionException.types() -> List<String>` — every type with no value, registration
  order.

Existing behaviour the tests also read (already public, no change to signatures):
`Schema.getTypeRaw`, `Schema.getType`, `RecursivePoint.RecursivePointType.index()`,
`RecursivePoint.RecursivePointType.family()`, `RecursiveTypeFamily.size()`, `Type.codec()`,
`DataFixer.update`.

## 4. Canonical output form

- **Registration order** = the order of the FIRST `registerType` call for each name. Re-registering
  a name replaces its template and does not move it.
- **`recursiveTypeNames()`** — registration order.
- **`recursionGroups()`** — members within a group in registration order; groups ordered by their
  earliest-registered member.
- **`typeReferences()`** — distinct (each name at most once), registration order. NOT template
  traversal order: `TaggedChoice` stores its branches in a hash map, so traversal order is not
  stable and would break the flakiness gate.
- **Recursion index** — 0-based WITHIN each group, following registration order. Not a
  schema-global counter.
- **Group build order** — each group is built after every group it refers to.
- **Empty** — a schema with no recursive types builds; `recursiveTypeNames()` and
  `recursionGroups()` are empty.
- **`UninhabitedRecursionException.types()`** — registration order, every uninhabited type across
  the whole schema, in one exception.

## 5. Blind-spot pre-empts (`DESCRIPTION.md` sentence bank)

| Blind spot | Sentence in the description |
|---|---|
| Adjacent-vs-all / transitive scope | "A type that merely refers to a recursive type, without lying on a cycle itself, is not recursive." |
| Result-list ordering | "in registration order", stated once and then referenced for each accessor |
| Dedup | "the distinct registered types that type refers to" |
| Iteration termination | "a type has a value only if its template can produce one without resolving a reference to a type that has none" (a least fixed point, stated as a condition, not as an algorithm) |
| Rule-resolution / default ordering | "Within a group, recursion indices start at zero and follow registration order." |
| Pipeline placement | "Build each group after every group it refers to." |

Codebase-inferable requirements: **1** (that `registerType`'s existing 3-arg signature must keep
working — visible in the existing source). Everything else is stated.

## 6. Description draft

See `meta.md` (written in Step 5). Target 380-450 words, under the 500 hard cap. Precedent for a
long meta in this repo: the approved `datafixerupper-ordered-alternatives` is ~500 words.

Body shape: 5 short prose paragraphs — the ask / what is derived / grouping and family layout /
the rejection rule / the new API and canonical orders. No headers, no bullets, no code blocks.

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful (~0.7) | Reason |
|--------|------|-------------|-----------|-------------------|--------|
| MODIFY | `src/main/java/com/mojang/datafixers/schemas/Schema.java` | 157 | +170 | ~120 | registration order, structure hand-off, per-group family build, dependency-ordered build, cross-group and non-recursive resolution, three accessors, the 2-arg overload, empty-schema path |
| NEW | `src/main/java/com/mojang/datafixers/schemas/TemplateStructure.java` | — | +150 | ~105 | the reference marker template plus the single walk over every `TypeTemplate` kind that yields both the referenced markers and whether a template can produce a value |
| NEW | `src/main/java/com/mojang/datafixers/schemas/SchemaStructure.java` | — | +160 | ~110 | reference graph, mutual-reachability grouping, recursive set (cycle ∪ declared), per-group index assignment, group build order, the inhabitance fixed point |
| NEW | `src/main/java/com/mojang/datafixers/schemas/UninhabitedRecursionException.java` | — | +25 | ~15 | the thrown type and its `types()` accessor |

**TOTAL: ~505 raw / ~350 meaningful across 1 modified + 3 new files.**

Floor check (2026-07 sprint): >=200 meaningful (target 275-300), >=2 files, >=40 solver messages.
Design sits at ~350 meaningful across 4 files — a real buffer above the floor, so a fairness
revision can delete a requirement without dipping under.

Calibration note: the throwaway spike (recording pass + reachability + per-group families only,
no walker, no inhabitance, no diagnostics) measured **136 human-effective** on the hook. The
walker and the inhabitance fixed point are what carry this design over the floor, and they were
added as orthogonal DEPTH, not as breadth.

## 8. Solution outline — pure-function helpers

`TemplateStructure`:
- `record Reference(String name) implements TypeTemplate` — the marker substituted for a reference
  during collection. Every `TypeTemplate` method throws; it is never applied to a family.
- `static void collect(TypeTemplate template, Set<String> into)` — one traversal, accumulating
  marker names.
- `static boolean producesValue(TypeTemplate template, Predicate<String> referenceHasValue)` — the
  same traversal shape, answering whether a value exists. Per kind: `Sum` = either side;
  `Product` = both sides; `Tag`/`Named`/`Check`/`Hook` = its element; `List`/`CompoundList` =
  always (the empty collection); `TaggedChoice` = any branch; `Const`/`EmptyPart` = always;
  `RecursivePoint` = always (it is resolved by the family, not by this pass); `Reference` =
  `referenceHasValue`.

`SchemaStructure`:
- `references(String) -> List<String>`
- `groups() -> List<List<String>>`, `groupOf(String) -> int`, `indexInGroup(String) -> int`
- `isRecursive(String) -> boolean`
- `buildOrder() -> List<Integer>`
- `uninhabited() -> List<String>`

Fixed-point loop, stated verbatim because the description says "has a value only if":

```java
boolean changed = true;
while (changed) {
    changed = false;
    for (final String name : registrationOrder) {
        if (!inhabited.contains(name) && TemplateStructure.producesValue(templates.get(name), inhabited::contains)) {
            inhabited.add(name);
            changed = true;
        }
    }
}
```

`Schema`:
- `collectReferences()` — force each supplier once with the marker resolver active
- `buildTypes()` — groups in `buildOrder()`, one `RecursiveTypeFamily` per group, then the
  non-recursive types
- `id(String)` — marker while collecting; `DSL.id(indexInGroup)` inside the group being built;
  `DSL.constType(alreadyBuilt)` for another group; inline otherwise

## 9. Test file outline

Path: `src/test/java/com/mojang/datafixers/schemas/SchemaRecursionTests_<hex>.java`
(hex from `openssl rand -hex 3`; no `shipd` / `datacurve` substring anywhere).

Block 1 — imports (JUnit 4 `org.junit.Test`, `org.junit.Assert.*`, gson, `JsonOps`), matching
`CodecTests.java`.

Block 2 — builder helpers (~14 one-liners): `ref(name)`, `schema(consumer)` building an anonymous
`Schema` from a registration lambda, `field(name, ref)`, `optField(name, ref)`, `constField(name)`,
`parse(json)`, `raw(schema, name)`, `index(schema, name)`, `familySize(schema, name)`.

Block 3 — assertion helpers (3): `assertRecursive(schema, name, expectedIndex, expectedFamilySize)`,
`assertRoundTrips(schema, name, json)`, `assertParseFails(schema, name, json)`.

Block 4 — buckets:

| Bucket | Tests | Notes |
|---|---|---|
| derivation | 10 | self-loop; two-cycle; three-cycle; reaches-a-cycle-but-not-in-one; isolated; reference through a `TaggedChoice` branch; reference through a `List` element; forward reference; a name referenced twice yields one entry; unregistered reference still errors |
| declaration | 7 | declared + acyclic stays recursive and forms its own group; declared + cyclic behaves as derived; a type referring to a declared-acyclic type does not become recursive; the 2-arg overload; re-registration keeps the first position; flag set on the second registration |
| grouping | 8 | one group for a mutual pair, members in registration order; two disjoint groups; groups ordered by earliest member; a three-cycle is one group; a declared-acyclic singleton; `recursionGroups()` partitions `recursiveTypeNames()` |
| indices and families | 8 | indices 0-based per group; two groups both start at 0; `family().size()` equals group size; unrelated recursive types absent from a group member's unfolded form; index follows registration order not discovery order |
| build order | 6 | a group referring to a later-registered group builds; a chain of three groups; a non-recursive type referring to a recursive one; a recursive type referring to a non-recursive one that itself refers to a third group |
| inhabitance | 9 | required self-reference rejected; `types()` contents and order; two uninhabited types in one exception; optional escape accepts; list escape accepts; `TaggedChoice` with one escaping branch accepts; mutual pair inhabited only through the partner's escape accepts; required-both-ways pair rejected; an inhabited group next to an uninhabited one still names only the uninhabited |
| edge cases | 7 | no recursive types at all builds (was `NoSuchElementException`); empty schema; single non-recursive type; `typeReferences` of a type with no references; unicode type name; a group of one that is a self-loop |
| behavioural round-trip | 9 | deep alternating mutual recursion decodes and re-encodes; self-loop at depth; cross-group nesting; non-recursive wrapper around a recursive type; end-to-end `DataFixer.update` renaming a field at every depth of a derived mutual recursion (the migration base cannot even construct) |

Target ~64 tests. 5-axis check: every described atom (including the negative of each positive
claim), every public API name, every solution branch (every template kind in the walker, every
`id()` case, every fixed-point outcome), edge cases, stated inverses.

## 10. Forced trait bounds / generics / kwargs

- `Schema.registerTypes` / `registerEntities` / `registerBlockEntities` are `protected`-ish hooks
  a root schema MUST override (the default delegates to `parent`, which is null for a root). Test
  helpers must therefore build schemas through a base class that overrides all three. Documented
  here so the test outline does not discover it late.
- `DSL.TypeReference` is an interface with `typeName()`; tests use a `record Ref(String n)`.
- `RecursivePoint.RecursivePointType<A>` is generic; reading `index()` needs a wildcard cast. Not
  a solver-facing constraint — it is already public.
- `DSL.optionalFields(String, TypeTemplate)` takes a TEMPLATE, so a constant element must be
  wrapped: `DSL.constType(DSL.string())`. Measured while spiking (a `Type` does not coerce).

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal class | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|------|------|---------------|------------------|---------------------|-------------------|-------------------|---------------|
| 1 | Cycle MEMBERSHIP vs REACHABILITY — a type that reaches a cycle is marked recursive | F-17 proxy-metric drift | A-tier naive-dominant-reading | which nodes are recursive | #3, #4 | "reaches a cycle" is the cheaper graph question and reads as the same thing | "A type that merely refers to a recursive type, without lying on a cycle itself, is not recursive." | `reaches_cycle_is_not_recursive` |
| 2 | Mutual recursion with no self-reference | F-5 transitive reachability | S2 composition of documented rules | detection depth | #1 | a direct self-reference check passes the self-loop test and dies here | "A type is recursive when it lies on a cycle of those references" | `two_cycle_both_recursive` |
| 3 | Per-group 0-based indices, not a schema-global counter | F-6 ordering inversion | A-tier exact-fit index arithmetic | index space | #4 | a global counter is correct for every single-group schema and silently wrong for two | "Within a group, recursion indices start at zero and follow registration order." | `two_groups_both_start_at_zero` |
| 4 | Build order — a group referring to another must be built after it | F-9 cross-stage resolution drop | S3 baseline-preservation through a chokepoint | construction ordering | #1, #3 | registration order looks like a build order and works until a group refers forward | "Build each group after every group it refers to." | `group_referring_to_later_group_builds` |
| 5 | Inhabitance is a FIXED POINT, and only some constructs escape | F-22 joint fixed point | S2 composition of documented rules | value existence | #2 (shares the walk) | a one-pass check marks the mutual pair uninhabited because neither escapes on its own | "a type has a value only if its template can produce one without resolving a reference to a type that has none" | `mutual_pair_inhabited_through_partner` |
| 6 | Zero recursive types | edge case (unmeasured) | B-tier support | empty | — | `reduce(...).get()` on an empty stream | "A schema with no recursive types at all must still build." | `schema_without_cycles_builds` |

Every trap names an F-id. Axes differ. #1/#3/#4 form an interdependent chain: a wrong recursive
SET produces wrong GROUPS, which produce wrong INDICES and a wrong build ORDER, and the symptom
surfaces as a decode failure or an exception in family construction, far from the graph code that
caused it — misdirecting, per the calibration model.

## 11b. Capability cross-product matrix (F-10)

Axis 1 = how the type became recursive (derived from a cycle / forced by the flag).
Axis 2 = the shape of its group (a single type / several mutually recursive types).

| | single type | several types |
|---|---|---|
| **derived from a cycle** | `self_loop_single_group` | `two_cycle_single_group` |
| **forced by the flag** | `declared_acyclic_is_own_group` ← off-diagonal | `declared_member_of_cycle_groups_with_it` ← off-diagonal |

Second matrix — axis 1 = where the escape lives, axis 2 = group size:

| | escape in the type itself | escape only in a group partner |
|---|---|---|
| **single type** | `self_loop_with_optional_escape` | n/a |
| **several types** | `pair_each_with_own_escape` | `mutual_pair_inhabited_through_partner` ← off-diagonal, the F-22 cell |

Predicted failure mode in the off-diagonal cells: OVER-firing. A flag-forced acyclic type gets
folded into the group of whatever it references (wrong), and the mutual pair gets rejected as
uninhabited (wrong). Both are over-application of a rule that is correct in the diagonal cells.

**Scope audit.** Every metric the contract names, and its scope:
- "lies on a cycle" — the whole reference graph, not the direct references.
- "each can be reached from the other" — transitive, both directions.
- "registration order" — schema-wide, not per group.
- "recursion indices start at zero" — per GROUP.
- "without resolving a reference to a type that has none" — the whole schema's fixed point, not
  the group.

**Example audit (L21).** The description contains no worked example. Every rule is stated as a
rule, so no example can be mistaken for the rule's scope.

**Format-noun audit (L24).** Nouns naming units: "type", "group", "reference", "template". Extents
stated: a group is a set of registered type NAMES; a reference is to a registered type, not to a
template; "type" always means a registered schema type, never a `Type` instance.

**Tolerance-fixture audit (L25).** No tolerance rule in this contract. The nearest analogue is the
inhabitance fixed point, whose N-1 fixture is `mutual_pair_inhabited_through_partner` (asserting
the schema is ACCEPTED), paired with `required_both_ways_pair_rejected`.

**Unbounded-promise audit (L44/L45).** No sentence promises a bound on iterations, passes or chain
length. "Build each group after every group it refers to" is a partial order, not a count.

**Representation-pin sweep (L48/L49).** Assertions on returned values read them through helpers.
`recursiveTypeNames()` / `recursionGroups()` / `typeReferences()` / `types()` are asserted for
CONTENT and ORDER via `List` equality against a `List.of(...)`, which the description pins by
naming `List<String>` and the order. Recursion indices are read through
`RecursivePointType.index()`, an existing public accessor, never through `toString()`.

**Stated-noun list (L46).** Nouns meta.md names: schema, registered type, template, reference,
cycle, recursive type, recursion group, recursion index, recursion family, registration order,
value, `UninhabitedRecursionException`. Every fixture's subject is on this list.

**Sibling-API audit (F-20).** The feature adds a 2-arg `registerType` beside the existing 3-arg
one. The new rule (derivation) applies to BOTH, so there is no new-API-only rule to leak — the
3-arg form's `recursive` argument keeps its meaning as a forcing flag, and that is asserted in
both directions (`declared_acyclic_is_own_group`, `declared_false_cyclic_is_recursive`).

**Unobservable-interface audit (F-21).** No rule quantifies over the outcome of a caller-supplied
interface. `Supplier<TypeTemplate>` is caller-supplied but the contract quantifies over the
TEMPLATE it returns, which is fully readable.

**Wrapper-domain audit (F-23/L47).** No "a number or a callable" clause.

Predicted Wrong Logic: ~30%. That is the honest number for an O-Algorithm-correctness shape and it
is the intended difficulty, not an ambiguity signal — every rule that produces it is stated.

## 12. Tier + category decision

- **Tier:** Olympus (one tier).
- **Sub-rank:** Good — 4 files, ~350 meaningful LOC, ~64 tests, 7 public names, a genuinely new
  algorithm.
- **Category:** `feature-request`. The title verb is "Derive" and the body's first sentence is
  "Add derived recursion structure to `Schema`"; the change adds new public API (an overload,
  three accessors, an exception type) rather than only altering an existing one.

## 13. Predicted Nova pass rate

- **Predicted: 15-30%**, centre ~20%.
- Reasoning: six stated traps, of which three (#1, #3, #4) form an interdependent chain and one
  (#5) is a fixed point that a one-pass reading gets wrong. Against that, every rule is stated and
  each piece is individually standard, which keeps it solvable. The spike proves a complete
  implementation is ~350 meaningful LOC, well inside a single agent run.
- Sanity check: under the <=40% ceiling with margin; not near 0% because the description states
  every rule and the repo compiles in seconds.
- Budget note: run a MIXED batch (Orion + Nova). Freeze meta.md, Dockerfile and the base commit
  BEFORE the first batch so every later round can use Re-eval at ~30%.

## 14. Quality-gate checklist

- [x] Repo understanding: 5/5 (architecture, subsystems, entanglement zones, test framework, template file)
- [x] Existing PR check: 0 hits (commands + full issue bodies and comments read; see below)
- [x] Closest approved problem opened side-by-side (`approved-problems/datafixerupper-ordered-alternatives`)
- [x] Title verb-led, 8 words, names the subsystem
- [x] Shape declared with a SHAPES.md citation
- [x] Public API surface lists every name tests will assert
- [x] Canonical output form spelled out (order, dedup, index base, build order, empty, exception contents)
- [x] 1 codebase-inferable requirement (the 3-arg overload must keep working)
- [ ] Description draft word count — written in Step 5, budget 380-450, hard cap 500
- [x] No `##` headers / formulaic labels / `Box<>` / code-prose planned for meta.md
- [x] File footprint sketched against REAL source files
- [x] ~350 meaningful LOC across 4 files clears the >=200 / >=2 floor with buffer
- [x] Solution outline: a helper per described behaviour
- [x] Fixed-point loop included verbatim
- [x] Test outline: 4-block layout, scenario-encoded names
- [x] 5-axis coverage planned
- [x] Forced generics / overriding hooks documented
- [x] 6 named traps, each with an F-id, a pre-empt sentence and a catching test
- [x] Traps sit on different axes; #1/#3/#4 interdependent, #5 shares the walk with #2
- [x] § 11b cross-product matrices filled in; every off-diagonal cell has a test
- [x] Sibling-API audit done (F-20 unavailable here and why)
- [x] Unobservable-interface audit done (F-21 not applicable and why)
- [x] Wrapper-domain audit done (F-23 not applicable)
- [x] Representation-pin sweep done (L48/L49)
- [x] Unbounded-promise audit done (L44/L45)
- [x] Stated-noun list written (L46)
- [x] Format-noun extents stated (L24)
- [x] Tolerance N-1 fixture identified (L25)
- [x] Predicted Nova pass rate <=40%
- [x] Category matches the description verb
- [x] Not pattern-followable — there is no second derivation of this kind in the repo
- [x] Not in `RULES.md § Features already used`
- [x] Flakiness: no timing, no RNG, no network, no clock; the one hash-order hazard
      (`TaggedChoice` branch order) is designed out by specifying registration order for
      `typeReferences()` rather than traversal order

## Phase 2 evidence (existing-PR + publicly-solved check)

```
gh api repos/Mojang/DataFixerUpper -q .full_name          -> Mojang/DataFixerUpper (no redirect)
gh search prs "repo:Mojang/DataFixerUpper recursive"      -> 0
gh search prs "repo:Mojang/DataFixerUpper recursiveness"  -> 0
gh search prs "repo:Mojang/DataFixerUpper schema build"   -> 0
gh search prs "repo:Mojang/DataFixerUpper cycle"          -> 0
gh search prs "repo:Mojang/DataFixerUpper buildTypes"     -> 0
gh search prs "repo:Mojang/DataFixerUpper registerType"   -> 0
gh issue list --state open  (all 19 read, bodies + comments)
```

- **#45 "Type Building Assumes that you have recursive types"** (2020-02-14, OPEN, **0 comments**,
  no PR, no code snippet, no external link). Reports only the empty-recursive-types crash. It
  INFORMS that the crash is real; it does not bind the scope, and the capability here is far
  broader. `RULES.md`: an issue may inform, never bind.
- **#108 / PR #109** touch `PointFreeRule`, `RecursiveTypeFamily.hmap`, `Check`, `Sum`,
  `TaggedChoice`, `Either`, `DataResult` — rewrite-rule optimisation typings. A different central
  capability, and the footprints do not collide: this solution touches `Schema` plus three new
  files in `schemas/` and needs no change to `Check` or `RecursiveTypeFamily`.
- No open or closed issue asks for derived recursiveness, recursion groups, per-group families or
  an inhabitance check. No comment anywhere links an external implementation.
- Competitor profiling: every PR author is a Minecraft-ecosystem developer with a coherent
  single-domain footprint. Zero recorded signature accounts, zero AI-sweep marks in 12 months.

## Why this is not a duplicate

Closest of ours: `approved-problems/datafixerupper-ordered-alternatives` (same repo, accepted at
5/10). That one lives entirely in `com.mojang.serialization` — the codec DSL — and its capability
is a combinator over `Codec`/`MapCodec` results and lifecycles. This one lives in
`com.mojang.datafixers.schemas` and the type-template layer, touches no codec, and its capability
is a graph derivation over schema type templates. Different subsystem class, different algorithm,
no shared file. Second closest: `approved-problems/customasm-derived-bank-layout` shares the
"derive a quantity the caller used to declare" theme, but that is an assembler bank-placement fixed
point over emitted bytes in a different repo and language, with no overlapping machinery.

Derivative sentence the dedup engine would emit: *"derives which schema types are recursive by
analysing the type-template reference graph, groups them, and rejects recursion that cannot bottom
out."* It cannot be written without repo-internal nouns (schema type template, recursion group,
recursion family), which is the LOW-risk row of the Stage 2b table.

## Predicted iteration cycles: 2

One round to land the description against Test Fairness, one to calibrate the rate. The
solver-visible surface (meta.md, Dockerfile, base commit) is frozen before the first batch so
every later round can use Re-eval.
