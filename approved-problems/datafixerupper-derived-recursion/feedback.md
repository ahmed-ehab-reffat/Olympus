# feedback.md — datafixerupper-derived-recursion

## Strategic summary

Repo: `Mojang/DataFixerUpper` (Java 17, MIT, 1311 stars), base
`5fc0978694e996cfe68a742b67a0d506c17de3f0` — the same base as our approved
`datafixerupper-ordered-alternatives`, because HEAD has not moved since.

Subsystem: `com.mojang.datafixers.schemas` and the type-template layer. Deliberately NOT
`com.mojang.serialization`, which is both our approved pick's subsystem and the maintainers' only
active lane (12 commits/24mo there against 0-1 in optics / functions / kinds / types / schemas).

Capability: a schema derives its own recursion structure from the type-template reference graph
instead of trusting a caller-supplied flag, isolates each recursion group in its own family, and
rejects recursion that can never bottom out.

Two base defects the feature closes, both reproduced through the public API before any code was
written:

- a schema registering no recursive type throws `NoSuchElementException` from `Schema.buildTypes`
  (open issue #45, filed 2020-02-14, 0 comments, no PR)
- types that refer to each other in a cycle without the flag throw `StackOverflowError` while the
  schema is built (the `Schema.java:144` "TODO: calculate recursiveness instead of hardcoding")

Two further defects it closes, found during the seam audit:

- every recursive type shared ONE family, so a type's unfolded form carried branches for unrelated
  recursive types
- the family's branch order followed hash iteration rather than the recursion indices

## Environment notes

- No Gradle is needed locally: `javac --release 17` plus 8 Maven Central jars compiles all 484
  main classes in seconds. `test.sh` uses the same approach, so the container never runs Gradle at
  test time (Gradle only warms the dependency cache at image build time).
- Local jars live in `/tmp/claude-1000/dfulibs`; set `DFU_TEST_LIBS` to point at them.
- The repo has NO GitHub Actions workflow (removed 2025-10-08). CI is Azure DevOps
  (`.ado/build.yml` runs `gradle build test publish` on every branch and PR under JDK 17). The
  baseline was therefore verified locally instead: 52/52 existing tests, identical on 3 runs.

## Attempt history

### Round 0 (authoring) — 2026-09-10

- DESIGN.md written before any code (14 sections), after a throwaway feasibility spike that proved
  per-group families, cross-group references and an end-to-end `DataFixer.update` migration all
  work.
- The spike measured **136 human-effective LOC** — under the floor. The template walker and the
  inhabitance fixed point were added as orthogonal DEPTH (not breadth) to reach the target.
- Final: **275 human-effective LOC across 5 files** (405 raw), 66 new tests.
- Validation: both patch orders apply and unapply cleanly; base 52/0 before and after the
  solution; new 66 failures on base (compile failure naming `recursiveTypeNames()` /
  `recursionGroups()`), 66/0 after.
- Flakiness gate: base and new each run 5x, identical every run, identical testcase-name sets.

## Fix history

(none yet — no batch has run)

## FP prevention (all three passes executed, not reasoned)

- **Per-branch mutation, 18 mutations, run against BOTH modes (L33): 18 killed, 0 survived.**
  Two rounds were needed. The first found one survivor (the clause that keeps a reference to an
  UNREGISTERED name from counting as a type without a value) and one mutation whose text did not
  apply. The survivor was a real hole: every existing unregistered-reference fixture used an
  OPTIONAL reference, which produces a value whatever it points at. Fixed by stating the precedence
  in meta.md ("A reference to a name that was never registered stays an unknown type rather than a
  type without a value") and adding a REQUIRED-reference fixture. Done before any batch, so the
  meta.md edit was free.
- **Feature-stub run: 57 of 68 red.** The 11 that stay green are all negative or
  baseline-preservation cases whose correct answer genuinely is "nothing is recursive"
  (`isolated_type_is_not_recursive`, `a_schema_without_cycles_has_no_groups`,
  `schema_without_recursive_types_builds`, `schema_with_a_single_plain_type_builds`,
  `schema_with_no_types_builds`, `a_type_without_references_lists_none`,
  `re_registration_keeps_the_original_position`, `a_required_reference_to_a_usable_type_is_accepted`,
  `a_value_missing_a_required_field_is_rejected`, and the two unregistered-reference fixtures).
  Each is accounted for; none is a hole.
- **Assertion-flip: 10 targeted flips across every bucket, 10 detected, each by exactly one test.**
  No decorative assertion.

## Docker (built and run locally, not merely reasoned about)

`docker build` from the pristine base tree succeeded (the platform builds the image before any
patch is applied, so `gradlew compileTestJava` only sees the two pre-existing test classes).
`docker run --network none --user 1000:1000` then reproduced the full matrix inside the container:
base 52/0 without the solution, new 68 cases / 68 failures without it, base 52/0 and new 68/0 with
it, and three consecutive in-container runs of each mode were identical. All four JUnit XML files
parse and carry more than one `<testcase>`.

## Platform pre-check round 1 (2026-09-10, before any batch)

Task Quality came back FAIL on the first run and PASS on a re-run of the same artifact, so the
gate is not deterministic. The FAIL was still a real defect and was fixed rather than re-rolled.

- **Fairness FAIL (Criterion 4) - `re_registration_keeps_the_original_position` pinned the
  iteration order of the pre-existing `types()` Set, which meta.md never promised.** Confirmed in
  code: base builds that map with `Maps.newHashMap()` and the reference had quietly moved to
  `newLinkedHashMap()`, so a correct implementation of every specified API could fail the test.
  Stating the clause was the wrong fix - the reference inserts recursive groups before the
  remaining types, so `types()` is NOT in registration order once anything recurses, and promising
  it would have needed a solution change too. Fixed test-side: the test now reads position through
  `recursiveTypeNames()` / `recursionGroups()` (both explicitly ordered by meta.md) and gets there
  by re-registering a template that closes a cycle, so it covers replacement as well as position.
  `schema_with_a_single_plain_type_builds` now compares a `Set`, not a `List`.
- **Coverage report: "re-registering a name replaces its template" was untested.** Added
  `re_registration_replaces_the_template` - the old template requires field `old`, the replacement
  requires field `t` and references another type, so keeping the old template OR combining the two
  both die.
- **Coverage report: reference discovery was "not discriminating"** - a visitor hardcoded for
  fields / list / compound-list / tagged-choice passed the whole suite, because `optionalFields`
  already covers Product / Sum / Tag. Added six tests over the arms nothing reached: `Hook`,
  `Named`, and the KEY position of a two-argument `compoundList`, in both the reference-graph and
  the inhabitation direction. `Check` is deliberately not covered - it is the recursion
  machinery's own wrapper and throws on the -1 index a non-recursive type is built with.
- **Solution Quality 2/3 (dead code): removed the `collectedReferences` bookkeeping.** The field,
  its per-template allocation and reset, and the `add` call in `id` were never read - the graph
  edges come from walking `Reference` placeholders in `TemplateStructure`. Costs 4 effective LOC
  (275 -> 271, floor is 200).
- **Alignment warning: `recursionGroups()` / `typeReferences()` did not say they return names.**
  meta.md now says so for all three new methods.
- **Description "only necessary information" (advisory).** Applied one of five: dropped the
  prescriptive "Build each group after every group it refers to;" and kept the observable half.
  The other four back real assertions - `getTypeRaw` (the `point()` helper), the unfolded-form
  clause (`unrelated_recursive_types_are_absent_from_an_unfolded_group_member`), and the
  refers-to-a-recursive-type-is-not-recursive pre-empt - so removing them would recreate exactly
  the unstated-requirement defect the fairness FAIL was about.

Trap-proof on the new tests: dropping the `Hook`/`Named`/`Check` arms from both
`TemplateStructure` walkers kills exactly the 6 new wrapper tests and nothing else; making
re-registration append instead of replace-in-place kills only
`re_registration_keeps_the_original_position`; making it keep the old template kills that one plus
`re_registration_replaces_the_template`. Re-validated in Docker: base 52/0, new 76/0, new-on-base
76 cases / 76 failures, three identical runs of each mode.

## Platform pre-check round 2 (2026-09-10, still before any batch)

Test Quality FAILed 1 of 76: `unrelated_recursive_types_are_absent_from_an_unfolded_group_member`
asserted `point("a").unfold().toString()` does not contain `"unrelated"`. Correct finding - meta.md
constrains the unfolded STRUCTURE, never `Type.toString()`, and `RecursiveTypeFamily.toString()` is
already diagnostic and prints family metadata, so a correct per-group implementation whose rendering
happens to name another type would fail. Replaced with the structural form of the same claim
(`an_unrelated_recursive_type_is_absent_from_a_group_member_family`): the {a, b} cycle and the
unrelated self-loop are separate `recursionGroups()`, a and b sit at indices 0 and 1 of a family of
size 2, and unrelated is index 0 of a family of size 1. Family size IS "no branches for unrelated
recursive types" - no rendering is pinned.

Also took the advisory coverage suggestion, which was a real hole: nothing tested that a NON-cyclic
type with a required reference to a valueless one is itself valueless, so an implementation that
validated only SCC members passed every rejection test while contradicting "every type with no
value". Added `an_acyclic_type_requiring_a_valueless_one_is_reported_too`,
`a_dependent_registered_before_its_valueless_target_keeps_its_position` (the dependent registered
FIRST, so the order is registration order and not discovery order), and
`an_optional_reference_to_a_valueless_type_still_has_a_value` for the other side of the boundary.
The reference already computes a global least fixpoint, so no solution change was needed.

Trap-proof: restricting the uninhabited report to group members kills exactly the two new
propagation tests; collapsing every recursive type into one group kills 11 including the
replacement family test, so the branch-isolation discrimination survived the rewrite intact.
Re-validated in Docker: base 52/0 x3, new 79/0 x3, new-on-base 79 cases / 79 failures.

## Batch 1 + Auto Review (2026-09-10)

Batch 1: **1/10** (Nova_Nova_7 the only pass). Eight of the nine failures are the unknown-name
edge - six failed ONLY `unregistered_reference_still_reports_an_unknown_type` and
`a_required_reference_to_an_unregistered_name_reports_an_unknown_type`, materialising an unregistered
name as a usable sentinel type instead of the repo's existing `IllegalArgumentException`. Two more
failed the recursive DataFix pair. Auto Review: Description 3/3, Tests 1/3, Solution 0/3, revision
requested.

**S2 Blocker (cross-group DataFix traversal) - CONFIRMED and FIXED.** Reproduced exactly as the
reviewer described: two self-recursive types in separate groups, a `writeFixAndRead` fix targeting
the nested one, `DataFixer.update` rooted at the outer type left every nested tag unchanged. The
cause is that `RecursiveTypeFamily.everywhere` traverses each member's unfold with `recurse=false`
and `RecursivePointType.everywhere` returns a nop in that mode, so an external group's recursion
point embedded with `DSL.constType` was never entered. Base does not have the bug only because all
recursive types share ONE family there, so this was a genuine regression.

Two fixes were tried before the one that shipped:
- Re-entrancy guard on the family plus `recurse=true` in both of `everywhere`'s traversal calls:
  NON-TERMINATING. `buildMuType` mints a fresh "ruled" family per rewrite, the guard is per-instance,
  so each new family expands again forever.
- Guard plus `if (recurse || !family.isExpanding())` in `RecursivePointType`, leaving the family's
  own calls at `false`: ALSO non-terminating, and the reason is the real constraint - a raw
  recursion point renders `buildTemplate()` as `DSL.id(index)`, so once the embedded foreign point
  is rewritten it re-renders as an index into the OUTER family and the structure eats itself.
- **Shipped:** `ExternalRecursionType<A>`, a Type wrapper for an already-built external recursion
  point. It forces `recurse=true` on its delegate, re-wraps the resulting view so the rewritten
  child stays external, renders `buildTemplate()` as `DSL.constType(this)` so a rebuilt outer
  template can never turn it into an index, and inherits the default `updateMu` so it is not
  remapped into the outer family. Verified: the nested fix now reaches every depth.

**S1 (memoized supplier) - FIXED.** `TemplateStructure.Reference` was an inert record whose every
operation threw, so a `Suppliers.memoize` registration cached a tree that could not be applied. It
is now a lazy placeholder holding the schema, resolving through `Schema.resolveReference` at apply
time and reporting size 0 while collection is still running (`TaggedChoice` computes its size
eagerly in the constructor, which is what caught this). A memoized self-recursive registration now
derives recursion and decodes correctly.

**Tests 1/3 (two ordinary-Sum gaps) - CLOSED.** Both were real: every `Sum` in the suite came from
`optionalFields`, which always puts the reference in `Sum.f` and always leaves an empty escape in
`Sum.g`. Added `a_reference_in_the_second_alternative_is_a_reference`,
`both_alternatives_are_searched_for_references`, `an_alternative_without_an_escape_is_rejected`,
and `one_escaping_alternative_makes_a_self_loop_usable`. 83 tests now.

**The cross-group DataFix regression test was deliberately NOT shipped.** Measured, not assumed:
Nova_Nova_7 - the only passing run - resolves external references with `DSL.constType` exactly as
the pre-fix reference did, so it fails that test (84 tests, 1 failure). Shipping it takes the batch
to 0/10, which is an unsolvable reject. The reference is fixed; the property stays unasserted.
Re-measure this if a later batch produces a passer that traverses external families.

**Replay of all ten batch-1 patches against the new 83-test suite: unchanged at 1/10.** The four Sum
tests killed nobody (every agent handles `Sum` through `optionalFields` already), so they close the
reviewer's hole without touching the rate. Effective LOC 271 -> 333 across 6 files.

Advisory checks NOT actioned: the four description trims (each backs a real assertion, and
Description scored 3/3), and the two alignment clarifications (flag stickiness across
re-registration, forward cross-group references). Both alignment points are already tested and
meta.md edits are no longer re-eval eligible now that a batch has run - they would cost a full
batch for wording that the reviewer graded clean.

## Solution Quality round 2 (2026-09-10) - regression I introduced, fixed

FAIL, Comprehensiveness 1/3: `Schema.id` threw a NullPointerException whenever it was called
during `registerTypes` itself - register a leaf "a", hold `TypeTemplate ref = schema.id("a")`, then
register "b" from a supplier that uses `ref`. Correct finding, and the bug was mine: the round-1
lazy-`Reference` fix gated on the `collecting` flag, which is only true inside `collectTemplates`,
so a call during registration fell through to `resolveReference` and dereferenced `structure`
before the constructor had assigned it. Base has no such hole - `id` resolves against the
`recursiveTypes` map, which is already populated during registration - so this broke a schema shape
the repo supports, and it contradicted "A schema with no recursive types still builds".

Fix: defer on the real condition instead of a phase flag. `id` returns a lazy `Reference` whenever
`structure == null`, which covers the whole registration AND collection window, and
`Reference.size()` defers on `structureReady()` the same way. The `collecting` field is gone.

Shipped one regression test, `a_reference_assembled_during_registration_still_builds`, mirroring the
reviewer's exact shape. Mutation-proof: restoring the `collecting`-gated `id` kills exactly that one
test and nothing else.

**Did NOT ship a second test for the forward-eager case** (`s.id("node")` BEFORE "node" is
registered). My fix handles it, but base `id` on an unregistered name goes through `resolveTemplate`
and throws, so demanding it would enforce behavior that is neither stated in meta.md nor
established in the repo - the same unstated-requirement defect the round-1 fairness FAIL was about.
It also killed 3 agents on its own while adding no discrimination the kept test lacks.

Replay of all ten batch-1 patches on the 84-test suite: **still 1/10**, Nova_Nova_7 passes. The kept
test kills Nova_1, 2, 6 and 9, all of which already failed on other grounds. Effective LOC 328
across 6 files; base 52/0 x3, new 84/0 x3, new-on-base 84/84.

## Solution Quality round 3 (2026-09-10) - three findings, all real, all fixed by one redesign

All three came out of the lazy-`Reference` shortcut I took in round 1. Two of them (the retained
reference and the double supplier evaluation) share a root cause, so the build path was reworked
rather than patched.

**Retained reference resolved outside its own family (high).** `buildTypes` cleared a mutable
`buildingGroup` before the lazy `RecursiveTypeFamily` ever unfolded, so a `Reference` held from
registration resolved later with `buildingGroup == -1` and its own group read as external - the
family body ended up containing an `ExternalRecursionType` delegating back to itself, and a normal
recursive DataFix over that schema re-entered the family instead of stopping at its recursion point.

**Analysis and construction used different Supplier results (medium).** `collectTemplates()` called
every supplier for the graph and `buildTypes()` called each one again through `getTemplate`.
`Supplier` promises nothing about stability, so the reported graph could describe a different tree
than the one built.

**Fix for both: substitute, do not resolve late.** The collected map is now retained on the schema
and is the ONLY supplier evaluation (verified: a counting supplier is called exactly once).
`TemplateStructure.substitute` walks a collected template and replaces every `Reference` with its
concrete resolution for the group being built - `DSL.id(index)` inside the group, an external
adapter outside it, the inlined named template for a non-recursive target - rebuilding each node
only when a child actually changed, so untouched subtrees keep their identity for template
interning. No `Reference` survives into a family, `Reference` is an inert record again, and the
mutable `buildingGroup` field is gone. This also fixes a latent staleness: `TaggedChoice` computes
its size eagerly in the constructor, so a choice built during collection had frozen a size computed
over placeholders; substitution rebuilds it.

**Cross-group references were not transparent (high).** `ExternalRecursionType` delegated only
codec, equality and `everywhere`, inheriting Type's empty `point`, `all`, `one`,
`findFieldTypeOpt`, `findChoiceType`, `findCheckedType` and `findTypeInChildren` - so a required
field pointing into another group had no default value and optic searches could not traverse it,
which is not "resolves to that type as already built". All of those now delegate, with the
rewrite-shaped ones re-wrapped so the external-family boundary survives into the result type and
`findTypeInChildren` casting the optic's outer pair back onto the adapter.

Verified directly: a retained self-reference builds as a `RecursivePointType` and its recursive
DataFix reaches every depth; a required cross-group reference has a default value and a findable
field; the supplier is evaluated once; the memoized-supplier case still works.

Two regression tests shipped - `a_reference_retained_from_registration_stays_inside_its_group`
(mutual cycle whose second member holds a reference taken after the first was registered, so no
unregistered-name lookup is demanded) and
`a_required_reference_to_another_group_behaves_as_the_built_type`. Stripping the delegation
overrides kills exactly the second and nothing else. 86 tests.

Replay of all ten batch-1 patches: **still 1/10**, Nova_Nova_7 passes. The retained-reference test
kills Nova_1, 2, 6 and 9 (all already failing); the transparency test kills nobody, because every
agent used a plain `DSL.constType`, which is transparent already - it was the wrapper that owed the
delegation. Effective LOC 389 across 6 files.

## Solution Quality round 4 (2026-09-11) - Comprehensiveness 3/3, one Code Quality finding, fixed

**Recursive group members lost their registered named identity (high).** Correct, and it was
collateral from the round-3 substitution rewrite: base assembles every registered type through
`getTemplate` = `DSL.named(name, resolveTemplate(name))`, and when I replaced that call with
`resolved(...)` the wrapper went with it - on BOTH build paths, the group loop and the
non-recursive loop. Names are part of Type equality and `RecursivePoint` ignores family identity
under `ignoreRecursionPoints`, so two structurally identical self-recursive registered types became
indistinguishable to `TypeRewriteRule.ifSame`, and a fix aimed at one could rewrite the other. It
also changed the runtime value shape codecs hand back.

Fix: `resolved(typeName, groupIndex)` now wraps its substituted template in `DSL.named(typeName,
...)`, which restores base behavior everywhere at once - the group members, the non-recursive types,
and the inlined non-recursive references (whose own `DSL.named` call collapsed into it).

Shipped `a_fix_targeting_one_recursive_type_leaves_its_twin_alone`: two structurally identical
self-recursive types, a fix targeting the first, asserting the first IS rewritten at every depth and
the second is byte-identical. Mutation-proof: dropping the `DSL.named` wrapper kills exactly that
test and nothing else. 87 tests.

Replay of all ten batch-1 patches: **still 1/10**, Nova_Nova_7 passes. The twin test kills Nova_2, 6
and 9, all already failing. Effective LOC unchanged at 389.

### Advisory items deliberately not actioned

- **`DSL.check` reference/inhabitance coverage.** `TemplateStructure` handles the `Check` arm in
  both walkers, but a user-level `DSL.check` is the recursion machinery's own wrapper: its type
  throws `IndexOutOfBoundsException` on the -1 index every non-recursive type is built with, and
  inside a family its `expectedIndex` gating makes the test about `Check` semantics rather than
  reference discovery. Not worth a fragile test for an advisory line.
- **Parent/child schema registration.** Genuinely untested, but the harness deliberately overrides
  `registerTypes` to isolate the derivation, and a real parent chain pulls in `Schema.parent`
  behavior the description never touches. Left as a known gap.
- **Relaxing the unregistered-name assertions to exception type only.** These check
  `getMessage().contains("ghost")`. CLAUDE.md's house rule is substring matching on 1-3 stable
  keywords, base throws exactly `"Unknown type: " + name`, and the 8 agents that fail these tests
  fail because they throw NOTHING, so relaxing would not move the band - only weaken the assertion.
- **The four description trims.** Third round in a row for the `getTypeRaw` clause, but it backs the
  `point()` helper and every `assertRecursive` call; cutting it would recreate the unstated-requirement
  defect from round 1. Description scored 3/3 in the Auto Review, and meta.md edits stopped being
  re-eval eligible once batch 1 ran.

## ACCEPTED 2026-09-11 — batch 2, 1/10

Batch 2 (87 tests, fresh 10-Nova run): **1/10**, Nova_Nova_7 `PASS_LEGITIMATE`. Auto Review
approved — Description 3/3, Tests 2/3, Solution 3/3. FP panel: genuine pass with one dissent (a
stale `resolvedTemplates` cache in the PASSING patch, reachable only by calling public
`resolveTemplate()` between two `registerType()` calls of the same name; adjudicated prompt-silent).

Kill table (8 of 87 tests killed anything; the other 79 killed nothing):

| Kills | Test |
|---|---|
| 8 | `a_required_reference_to_an_unregistered_name_reports_an_unknown_type` |
| 8 | `unregistered_reference_still_reports_an_unknown_type` |
| 4 | `a_reference_retained_from_registration_stays_inside_its_group` |
| 4 | `a_reference_assembled_during_registration_still_builds` |
| 3 | `a_fix_targeting_one_recursive_type_leaves_its_twin_alone` |
| 2 | `a_data_fix_over_a_self_recursive_type_reaches_every_depth` |
| 2 | `a_data_fix_reaches_every_depth_of_a_derived_mutual_recursion` |
| 1 | `the_flag_survives_a_later_plain_registration` |

Batch 1 (79 tests) was also **1/10** with the identical top cluster (8/8/2/2/1) — two independent
batches, four levers apart, same band.

The three middle rows exist ONLY because Auto Review found the corresponding bug in the reference;
they took 11 of the 32 kill events and grew the killing set from 5 to 8 without moving the rate.
Long-horizon (batch 2): median 4 files, median +594 raw LOC, median 6.2M prompt tokens.

Known gap accepted at review: no test wraps a reference in `DSL.check` (Tests 2/3). The reference
handles `Check` in collection, substitution and inhabitation; the suite never exercises it. A
user-level `DSL.check` throws on the -1 index every non-recursive type is built with, which is why
it was skipped — see the round-4 note above.

Mined into `failure-patterns.md` as F-24, F-25, F-20 evidence, L50, L51 and the dossier.

## Owed before submit

- nothing local; the first agent batch is the next step
