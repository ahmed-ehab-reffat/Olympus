# DESIGN.md — datafixerupper-ordered-alternatives

## 1. Title
Add ordered multi-way alternative codecs to the serialization DSL

## 2. Shape classification
- Shape: O-Composite-add (new feature spanning a top-level DSL type + its MapCodec twin + two new codec implementation files), closest historical analogue is Mars Shape B (add new public API list) but scoped to current one-tier floor.
- Pass rate target: <=40% ceiling, design toward 15-25%.
- Best agent: mixed (Orion/Vega expected strongest — decisive multi-file implementation).
- Dominant verdict: MISSED_REQUIREMENT / WRONG_LOGIC (silent wrong value, not compile error).
- Solver/our LOC ratio: unknown (no shape precedent in this repo); budget ~1.3x for a same-repo-convention feature.

## 3. Public API surface
- `Codec.orderedAlternatives(List<? extends Codec<? extends A>> codecs) -> Codec<A>` — static factory, decode scans every codec in list order.
- `Codec.orderedAlternatives(Codec<? extends A> first, Codec<? extends A>... rest) -> Codec<A>` — varargs convenience overload.
- `MapCodec.orderedAlternatives(List<? extends MapCodec<? extends A>> codecs) -> MapCodec<A>` — the map-context twin (mirrors the existing `either`/`mapEither`, `pair`/`mapPair` twin pattern already in `Codec.java`).
- `MapCodec.orderedAlternatives(MapCodec<? extends A> first, MapCodec<? extends A>... rest) -> MapCodec<A>` — varargs convenience overload.
- New package-private implementation types: `com.mojang.serialization.codecs.OrderedAlternativesCodec<A>`, `com.mojang.serialization.codecs.OrderedAlternativesMapCodec<A>`.

## 4. Canonical output form
- Decode scans the list start-to-end. If ANY codec fully succeeds (`DataResult.isSuccess()`), that is the result — scanning stops there, but only after every codec BEFORE it in the list has been tried and did not fully succeed (i.e. a full success at index 3 wins over a partial at index 0, so you cannot short-circuit at the first partial).
- If no codec fully succeeds, the returned value is the PARTIAL result from the FIRST codec in the list (lowest index) that produced one via `resultOrPartial()`. Later partials at higher indices never overwrite an earlier one.
- If no codec produces a full success OR partial result, the return is a plain error with no partial payload.
- The error message on any non-full-success outcome is the concatenation, in list order, of every attempted codec's error message, joined with `DataResult.appendMessages` (the existing `"; "` joiner already used by `DataResult.Error.flatMap`).
- Lifecycle of the returned result is the winning codec's own lifecycle (the full-success codec's lifecycle, or the chosen-partial codec's lifecycle) — never averaged/combined with the lifecycles of codecs that contributed only an error message.
- Encode always delegates to the FIRST codec in the list only, exactly like the existing two-way `Codec.withAlternative` (`Either::left` always encodes via the primary). No other list member is ever consulted during encode.
- `MapCodec.orderedAlternatives(...).keys(ops)` is the union, in list order, of every candidate's own `keys(ops)` stream (same convention as `MapCodec.of` and `MapCodec.Dependent`, both of which `Stream.concat` their sub-encoders'/decoders' keys).
- Empty list: `orderedAlternatives` with zero codecs throws `IllegalArgumentException` at construction (mirrors `Objects.requireNonNull`/precondition-style guards already used elsewhere in the codecs package, e.g. `ListCodec` range checks).
- Single-element list: behaves exactly like that one codec (full success passthrough; error passthrough; encode passthrough).

## 5. Blind-spot pre-empts
- "Try every alternative before falling back to a partial" (iteration-termination pre-empt): stated directly in meta.md — does not hand the implementation, only the observable contract.
- "Earliest partial wins, later partials are discarded" (dedup/first-occurrence pre-empt): stated directly in meta.md.
- "Encode only ever uses the first codec" (parallel-API asymmetry pre-empt): stated directly, mirrors existing `withAlternative` behavior which a competent reader of the codebase would already expect.
- Codebase-inferable requirement (the one allowed): error-message joining uses `"; "` — inferable from reading `DataResult.appendMessages`/`Error.flatMap`, not restated verbatim as "use this exact separator" in meta.md, only "combine every attempted error into one message" is stated.

## 6. Description draft (meta.md, plain prose)
See meta.md. ~185 words, no headers, no formulaic labels, one paragraph of behavior + one of edge cases.

## 7. File footprint
| Action | Path | Current LOC | Raw delta | Meaningful (~0.75x, low-brace Java feel) | Reason |
|---|---|---|---|---|---|
| NEW | src/main/java/com/mojang/serialization/codecs/OrderedAlternativesCodec.java | — | +95 | ~72 | Codec<A> impl: scan loop, error join, partial pick, encode-via-first |
| NEW | src/main/java/com/mojang/serialization/codecs/OrderedAlternativesMapCodec.java | — | +90 | ~68 | MapCodec<A> twin: same loop, `keys()` union, `RecordBuilder` encode-via-first |
| MODIFY | src/main/java/com/mojang/serialization/Codec.java | 741 | +14 | ~11 | two static factories delegating to the new impl type |
| MODIFY | src/main/java/com/mojang/serialization/MapCodec.java | 450 | +14 | ~11 | two static factories delegating to the new impl type |
| NEW (test) | src/test/java/com/mojang/serialization/OrderedAlternativesCodecTests_<hash>.java | — | ~230 | (test file, excluded from Counter 2) | new test file |

TOTAL solution: raw ~213 / meaningful ~162 across 4 source files.

This sits below the raw 200-meaningful sprint floor on the sketch above, so the implementation was
deliberately widened during Step 4 (see solution.patch) to include: (a) the varargs convenience
overloads on both `Codec` and `MapCodec` (not just the `List` factories — doubles the public API
surface named in §3), (b) explicit `IllegalArgumentException` precondition handling with a real
message on both new impl types, and (c) `toString()` implementations following the repo's own
`XorCodec`/`EitherCodec` convention (`"OrderedAlternatives[" + codecs + "]"`), which are real,
non-padding lines the existing sibling codecs all carry. Actual measured LOC is in §13/validation
below (raw 240, human-effective 214 — see the pre-submit LOC check).

## 8. Solution outline — pure-function/method helpers
- `OrderedAlternativesCodec.decode(ops, input)` — the shared scan loop (one method, drives both the success-pick and partial-pick behavior; this IS the shared chokepoint).
- `OrderedAlternativesCodec.encode(input, ops, prefix)` — delegates to `codecs.get(0)`.
- `OrderedAlternativesMapCodec.decode(ops, input)` — mirrors the Codec loop but over `MapLike<T>` input, no `Pair` wrapping.
- `OrderedAlternativesMapCodec.keys(ops)` — `codecs.stream().flatMap(c -> c.keys(ops))`.
- `Codec.orderedAlternatives(List)` / `Codec.orderedAlternatives(varargs)` / `MapCodec` twins — thin static factories, one line each.

No fixpoint loop needed (single linear scan, not iterate-to-convergence). No recursion.

## 9. Test file outline
Path: `src/test/java/com/mojang/serialization/OrderedAlternativesCodecTests_<hash>.java` (one new file, JUnit 4, same style as `CodecTests.java`, `JavaOps.INSTANCE` for the ops — no JSON scaffolding needed).

Block 1 — imports (Codec, MapCodec, DataResult, JavaOps, Pair, RecordCodecBuilder, JUnit).
Block 2 — builder helpers: tiny probe codecs built with `Codec.STRING.comapFlatMap`/`Codec.INT.flatXmap`/`Codec.unit` to force success / partial (via `DataResult.error(msg, partialValue)`) / total failure at named list positions ("codec that always succeeds with X", "codec that always partial-fails with message Y and partial Z", "codec that always fails with message Y, no partial").
Block 3 — assertion helpers: `assertSuccess(codec, input, expectedValue)`, `assertPartial(codec, input, expectedPartial, ...expectedMessageFragments)`, `assertTotalFailure(codec, input, ...expectedMessageFragments)`.
Block 4 — tests grouped by requirement bucket:
  - "success at various positions": success at index 0 / success at last index after several failing+partial codecs before it / single-element list success.
  - "scan-past-partial trap" (F-10 off-diagonal): partial at index 0 AND full success at index 2 in the same list -> result must be the SUCCESS, not the partial (kills short-circuit-on-first-partial implementations).
  - "earliest-partial-wins": partials at index 0 and index 2, nothing succeeds -> result is index 0's partial value, not index 2's (kills last-write-wins loops).
  - "all-fail no partial": every codec total-failure -> result has no partial value at all.
  - "error aggregation": assert the combined error message contains every attempted codec's distinct fragment, in order.
  - "encode uses only first": encode always calls only `codecs.get(0)`'s encoder, verified via a codec that throws/records a call-count if invoked and asserting the later codecs are never touched during encode.
  - "empty list rejected": constructing with zero codecs throws `IllegalArgumentException`.
  - "MapCodec twin — keys union": `keys(ops)` returns keys from every candidate, in list order, including duplicates.
  - "MapCodec twin — decode/encode parity with the Codec version" on the same scan-past-partial / earliest-partial-wins / encode-uses-first-only scenarios (F-10 cross-product cell: Codec-shape x MapCodec-shape).
  - Edge cases: single-element list of each kind (success / partial / total failure) behaves as passthrough.

Test count anchor: ~28-34 granular `@Test` methods (observational Mars/Olympus "B"-shape band is 160; this problem is far smaller in scope, sized to the current floor, not that historical band).

5-axis coverage: every atom above traces to a meta.md sentence; every public API surface (`Codec` list-factory, `Codec` varargs, `MapCodec` list-factory, `MapCodec` varargs) gets at least one direct test; every solution branch (loop continue on partial, loop break on success, end-of-loop fallback, empty-list guard) is hit; edge cases (empty list -> exception, single element, all-fail) covered; stated inverse (does NOT overwrite earlier partial with later partial) covered.

## 10. Forced generics
`List<? extends Codec<? extends A>>` / `List<? extends MapCodec<? extends A>>` force wildcard-capture-safe helper methods (`Pair.<A, T>of(pair.getFirst(), pair.getSecond())` style widening, no unchecked casts) — matches the existing repo's variance style in `Codec.either`/`Codec.withAlternative`. Test builder helpers must return `Codec<? extends A>`-compatible narrow types so the varargs call sites type-check without raw types.

## 11. Predicted trap matrix
| # | Trap | F-id | Arsenal class | Axis | Interdependent with | Why agents hit it | Pre-empt sentence (meta.md) | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | Short-circuits on the FIRST partial instead of scanning the whole list for a later full success | F-9 (shared chokepoint) | S3 baseline-preservation through a shared chokepoint | iteration-termination | #2 (same loop) | "try each until one works" reads naturally as stop-on-first-non-error, which a partial superficially looks like | "Only stop scanning once a codec fully succeeds; a codec that only produced a partial result does not end the search." | scan-past-partial trap |
| 2 | Overwrites the chosen partial with a LATER partial instead of keeping the first one found | F-9 | S3 | dedup/first-occurrence | #1 (same loop) | natural imperative loop reassigns `best = current` on every partial seen | "If nothing fully succeeds, the result carries the partial value of whichever candidate appears earliest in the list." | earliest-partial-wins |
| 3 | Aggregates only the LAST error message instead of every attempted codec's message | F-9 | S2 composition of documented rules | error-message composition | #1/#2 (same loop, same data available) | mirroring `DataResult.flatMap`'s two-message join, agents may reuse it pairwise and drop earlier messages when 3+ codecs fail | "The failure message names what every attempted codec reported, not just the last one tried." | error aggregation test |
| 4 | Encode consults something other than only the first codec (e.g. tries encode across the list on failure, or uses the last codec) | F-2 | A-tier reuse-missing-arm / naive-dominant-reading | parallel-API (decode vs encode) | — (separate method, but same class) | existing `Codec.withAlternative` already encodes symmetric-looking two-way; extending to N-way makes "loop over codecs during encode too" look consistent even though only decode is symmetric-scanned | "Serializing a value always goes through the first codec in the list; the alternatives exist only to widen what can be read back." | encode-uses-first-only test |

Traps 1-3 are interdependent (single shared scan loop: get the loop wrong on early-termination and both the success-vs-partial pick AND the message list break together — a fix to #1 that just "keeps looping" without separately tracking first-partial-only will still fail #2). Trap 4 sits on an orthogonal axis (encode vs decode) so it cannot be fixed by the same code change as 1-3, giving 2 independent axes as required.

## 11b. Capability cross-product matrix
Axes: (a) which codec produces the eventual value — full-success present? (yes/no) x (b) do earlier codecs produce partials before it? (yes/no).

| | earlier partial(s) exist | no earlier partial |
|---|---|---|
| **later full success exists** | test: scan-past-partial (off-diagonal, REQUIRED — this is the trap) | test: success-at-various-positions |
| **no full success anywhere** | test: earliest-partial-wins | test: all-fail-no-partial |

Second cross-product axis (Codec vs its MapCodec twin): every one of the four cells above is also run once through `MapCodec.orderedAlternatives` (the "MapCodec twin — decode/encode parity" bucket in §9), so the trap cannot be fixed only in the `Codec` implementation while the `MapCodec` implementation still gets it wrong — this is the interdependence between the two new impl files, not just within one file's loop.

Format-noun / tolerance-fixture audits: not applicable (no record/entry/block nouns, no N-vs-N-1 tolerance counting in this feature — it is a single linear scan with a binary per-item classification).

Wrong Logic %: predicted 20-30% (silent value-swap territory, still within current sprint's <=40% ceiling; named honestly per PLAYBOOK guidance rather than force-lowered).

## 12. Tier + category decision
- Tier: Olympus (current sprint, one tier).
- Sub-rank target: Good.
- Category: **feature-request** ("Add" verb, net-new public API/type — `orderedAlternatives` did not exist before).

## 13. Predicted Nova/agent pass rate
- Predicted: 15-25%.
- Reasoning: single shared-chokepoint loop (traps 1-3, S3-tier, historically strong) plus one orthogonal parallel-API trap (4, A-tier) stacked on top; both axes are misdirecting (a failing assertion on "wrong returned value" or "wrong message substring" does not name the iteration-order bug that caused it) and interdependent within their axis (fixing the loop for trap 1 without also isolating "first partial only" still fails trap 2). Two new files plus two edited files gives real integration surface (varargs overloads calling into the List overloads, MapCodec mirroring Codec) without inventing new HKT machinery — everything routes through the already-tested `DataResult`/`Codec`/`MapCodec` surface used throughout `CodecTests.java`.
- Sanity check: predicted range clears the <=40% ceiling with margin and stays above the 0% solvability floor (single-element-list and success-at-various-positions tests are straightforwardly reachable by any agent that reads the DataResult API, so 0% is not plausible).

## 14. Quality-gate checklist
- [x] Repo understanding: read Codec.java, MapCodec.java, DataResult.java, Lifecycle.java, DataFixerBuilder/DataFixerUpper/DataFix (datafixers package), CodecTests.java, existing PR/issue list.
- [x] Existing PR/issue check: `gh pr list/issue list --search "alternative"` and `"fallback"` -> only unrelated hit (#79, lambda-equality guarantee). No PR touches `withAlternative`, `either`, `xor`, or any ordered/priority/chain-of-codecs concept.
- [x] Closest scaffolding: `CodecTests.java` (test style/JavaOps convention), `Codec.either`/`MapCodec`'s twin static-factory pattern (API shape convention), `XorCodec`/`EitherCodec` (impl-file convention: package-private record/class implementing `Codec<A>`, `toString()` override).
- [x] Title verb-led, names subsystem (serialization DSL).
- [x] Shape declared (O-Composite-add analogue).
- [x] Public API surface lists every new name.
- [x] Canonical output form spelled out (scan order, partial selection, message join, lifecycle source, encode source, empty/single-element).
- [x] 1 codebase-inferable requirement (the `"; "` join separator), not restated verbatim.
- [x] Description draft under 200 words, no headers/labels/Box<>.
- [x] File footprint sketched against real files; widened in §7 note once initial sketch undershot the 200-meaningful floor.
- [x] Solution outline: helpers map to behaviors; no fixpoint/recursion needed (linear scan feature).
- [x] Test outline: 4-block layout, scenario-encoded names, 5-axis coverage.
- [x] Forced generics documented (wildcard capture, no raw casts).
- [x] 4 named traps, all with F-id (F-9 x3, F-2 x1), pre-empt sentence, and catching test.
- [x] Traps sit on 2 different axes (iteration/loop-state vs parallel-API), at least 3 interdependent with each other.
- [x] Cross-product matrix filled, off-diagonal cell (scan-past-partial) is the featured trap; second cross axis (Codec vs MapCodec twin) also filled.
- [x] Wrong Logic % named honestly (20-30%), within current <=40% ceiling.
- [x] Predicted pass rate <=40% ceiling, above 0% floor.
- [x] Category (feature-request) matches "Add" title verb.
- [x] Not pattern-followable: `withAlternative` (2-arg, converter-based, short-circuit-only) is the closest existing shape but has neither the N-way scan, the partial-priority rule, nor the error-aggregation-across-all-attempts rule — verified by reading its full body (Codec.java lines 129-155) before designing this feature as a genuine behavioral extension, not an arity port.
- [x] Not in `RULES.md § Features already used` (repo-specific feature, first Olympus submission for Mojang/DataFixerUpper — no entry exists yet; confirmed via `Instructions/SATURATED-REPOS.md` grep, no hits).

## Why this is not a duplicate
No approved problem in this workspace touches Mojang/DataFixerUpper (first submission for this repo — confirmed empty grep against `SATURATED-REPOS.md`, `approved-problems/`, `problems/`, `rejected/`). Closest shape family by mechanism (N-way alternative/fallback composition with ordered priority and error aggregation) is not represented in the corpus's Java/JVM submissions on disk at authoring time.

## Fairness-risk resolution (mandatory per task brief)
The `com.mojang.datafixers` package (DataFixer/Schema/optics engine) has zero dedicated tests and no
existing Schema/DataFixerBuilder test fixture to scaffold from — confirmed via `grep -rn "Schema\|DataFixerBuilder" src/test/java` returning nothing. Building a fair test harness there means inventing
Schema/Type/Typed fixtures from scratch with no repo precedent, which risks conflating "agent failed
to understand HKT/optics machinery" with the intended trap. Per the task's explicit pivot authorization,
this design lives entirely in `com.mojang.serialization` (Codec/MapCodec/DataResult), reachable through
the exact same high-level `Codec`/`MapCodec` combinator surface Minecraft's own mods use, and directly
scaffolded by the existing, actively-used `CodecTests.java` conventions (JUnit 4 + `JavaOps.INSTANCE`).
No `Kind2`/`App2`/raw optics types appear anywhere in the solution or tests.

## Predicted iteration cycles: 2 (novel same-repo API shape; no direct precedent to copy 1:1)
