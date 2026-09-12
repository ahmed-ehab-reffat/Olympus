# eval-results.md — datafixerupper-ordered-alternatives

No platform agent runs yet (Nova/Orion/Vega/Castor) — this submission has completed authoring and
local validation but has not been run through the platform evaluation pipeline.

## Local validation summary (iteration 1, this pass)

| Check | Result |
|---|---|
| Base suite on clean BASE_COMMIT (no patches) | 46 (CodecTests) + 6 (RoundtripTest) pass, 0 failures |
| test.patch alone, base mode | 46 + 6 pass, 0 failures |
| test.patch alone, new mode | build-failure fallback fires correctly (API not yet defined), exit 1 |
| test.patch + solution.patch, base mode | 46 + 6 pass, 0 failures |
| test.patch + solution.patch, new mode | 43/43 pass, 0 failures |
| Reverse order (solution.patch then test.patch) | base 46+6 pass, new 43/43 pass |
| Flakiness (3x full suite rerun) | identical results all 3 runs, 0 flakes |
| Mutation 1 — decode short-circuits on first partial instead of scanning for later success | 8/43 tests fail (expected) |
| Mutation 2 — decode keeps latest partial instead of earliest | 4/43 tests fail (expected) |
| Mutation 3 — error message keeps only the last attempt instead of aggregating all | 10/43 tests fail (expected) |
| Mutation 4 — MapCodec encode uses the last codec instead of the first | 1/43 tests fail (expected) |
| Mutation 5 — construction skips the duplicate-codec-identity check | 2/43 tests fail (expected) |
| Restoration after each mutation | `diff -r` against pristine copy clean every time |
| LOC (Counter 1, auto-block gauge) | raw 333, blank 48, comment 6 -> 279 |
| LOC (Counter 2, human-effective, via `.claude/hooks/effective_loc_check.py`) | 211 (clears current sprint's 200 floor; thinner margin than the 250-300 design target) |
| Files touched | 5 (2 modified: Codec.java, MapCodec.java; 3 new: OrderedAlternativesCodec.java, OrderedAlternativesMapCodec.java, OrderedAlternativesSupport.java) |
| Test count | 43 new `@Test` methods, 1 new file |
| test.sh executable bit | confirmed `new file mode 100755` in test.patch |
| Patch encoding | both patches confirmed ASCII text (not UTF-16) |
| meta.md Commit field vs BASE_COMMIT.txt | byte-identical match confirmed |
| Docker validation | NOT run (no local Docker on this workstation) — owed to the platform run |

## Local validation summary (iteration 3, after platform automated pre-submit review fixes)

| Check | Result |
|---|---|
| Base suite on clean BASE_COMMIT (no patches) | 46 (CodecTests) + 6 (RoundtripTest) pass, 0 failures |
| Dockerfile RUN sequence against pure BASE_COMMIT (no patches, no `test` task) | `compileJava`+`compileTestJava` succeed, exit 0 |
| test.patch alone, base mode | 46 + 6 pass, 0 failures |
| test.patch alone, new mode | build-failure fallback fires correctly (API not yet defined), exit 1 |
| test.patch + solution.patch, base mode | 46 + 6 pass, 0 failures |
| test.patch + solution.patch, new mode | 39/39 pass, 0 failures |
| Reverse order (solution.patch then test.patch) | base 46+6 pass, new 39/39 pass |
| Flakiness (3x full suite rerun) | identical results all 3 runs, 0 flakes |
| Mutation T1 — decode short-circuits on first partial instead of scanning for later success | 7/39 tests fail (expected) |
| Mutation T2 — decode keeps latest partial instead of earliest | 4/39 tests fail (expected) |
| Mutation T3 — error message keeps only the last attempt instead of aggregating all | 10/39 tests fail (expected) |
| Mutation T4 — MapCodec encode uses the last codec instead of the first | 1/39 tests fail (expected) |
| Mutation T5 — construction skips the duplicate-codec-identity check | 2/39 tests fail (expected) |
| Mutation T6 (new) — construction skips the duplicate-label-name check | 2/39 tests fail (expected) |
| Mutation T7 (new) — `orderedAlternativesLabeled` skips the null-label check | 1/39 tests fail (expected) |
| Restoration after each mutation | `diff -r` against pristine copy clean every time |
| Package-private visibility compiles cleanly | confirmed; `Codec.java`/`MapCodec.java` factories still return `Codec<A>`/`MapCodec<A>` (interface types), never the concrete impl class |
| LOC (Counter 1, auto-block gauge) | raw 307, blank/comment stripped -> ~232 (braces kept) |
| LOC (Counter 2, human-effective, via `.claude/hooks/effective_loc_check.py`) | 201 (clears current sprint's 200 floor; thin margin) |
| Files touched | 5 (2 modified: Codec.java, MapCodec.java; 3 new: OrderedAlternativesCodec.java, OrderedAlternativesMapCodec.java, OrderedAlternativesSupport.java) |
| Test count | 39 new `@Test` methods, 1 new file |
| test.sh executable bit | confirmed `new file mode 100755` in test.patch |
| Patch encoding | both patches confirmed ASCII text (not UTF-16) |
| build.gradle leakage in either patch | zero (confirmed via grep) |
| meta.md Commit field vs BASE_COMMIT.txt | byte-identical match confirmed |
| Docker image build/run validation | NOT run (no local Docker on this workstation) — the RUN-sequence commands themselves were validated for real against a clean BASE_COMMIT checkout; full image build/run still owed to the platform run |

## Local validation summary (iteration 4, LOC-margin pass: generic variance widening + blank-label check)

| Check | Result |
|---|---|
| Base suite on clean BASE_COMMIT (no patches) | 46 (CodecTests) + 6 (RoundtripTest) pass, 0 failures |
| test.patch alone, base mode | 46 + 6 pass, 0 failures |
| test.patch alone, new mode | build-failure fallback fires correctly (API not yet defined), exit 1 |
| test.patch + solution.patch, base mode | 46 + 6 pass, 0 failures |
| test.patch + solution.patch, new mode | 41/41 pass, 0 failures |
| Reverse order (solution.patch then test.patch) | base 46+6 pass, new 41/41 pass |
| Flakiness (3x full suite rerun) | identical results all 3 runs, 0 flakes |
| Mutation T1 — decode short-circuits on first partial instead of scanning for later success | 7/41 tests fail (expected) |
| Mutation T2 — decode keeps latest partial instead of earliest | 4/41 tests fail (expected) |
| Mutation T3 — error message keeps only the last attempt instead of aggregating all | 10/41 tests fail (expected) |
| Mutation T4 — MapCodec encode uses the last codec instead of the first | 1/41 tests fail (expected) |
| Mutation T5 — construction skips the duplicate-codec-identity check | 2/41 tests fail (expected) |
| Mutation T6 — construction skips the duplicate-label-name check | 2/41 tests fail (expected) |
| Mutation T7 — `orderedAlternativesLabeled` skips the explicit null-label check | 0/41 fail; NPE still fires from a downstream `.isBlank()` call on the null label, so this specific check is not independently discriminating (defense-in-depth for a clearer error site, not one of DESIGN.md's 4 named traps — noted honestly, not overclaimed) |
| Mutation T8 (new) — construction skips the blank-label check | 2/41 tests fail (expected) |
| Restoration after every mutation | `diff -r` / file `diff` against pristine copies clean every time |
| Generic variance widening (`Codec<? extends A>` per element) | compiles cleanly on both impl classes and both static-factory call sites; decode-side capture-safe with zero casts, encode-side uses one `@SuppressWarnings("unchecked")` helper matching the existing repo's own `DispatchedMapCodec.encodeValue` pattern |
| Package-private visibility still compiles cleanly | confirmed; `Codec.java`/`MapCodec.java` factories still return `Codec<A>`/`MapCodec<A>` (interface types) |
| LOC (Counter 1, auto-block gauge) | raw 334, blank 44, comment 6 -> 284 |
| LOC (Counter 2, human-effective, via `.claude/hooks/effective_loc_check.py`) | 216 (up from 201; clears the 200 floor with real margin; both sanctioned directions applied, no padding) |
| Files touched | 5 (2 modified: Codec.java, MapCodec.java; 3 new: OrderedAlternativesCodec.java, OrderedAlternativesMapCodec.java, OrderedAlternativesSupport.java) |
| Test count | 41 new `@Test` methods, 1 new file |
| test.sh executable bit | confirmed `new file mode 100755` in test.patch |
| Patch encoding | both patches confirmed ASCII text (not UTF-16) |
| build.gradle leakage in either patch | zero (confirmed via grep) |
| meta.md Commit field vs BASE_COMMIT.txt | byte-identical match confirmed |
| meta.md word count | 342 words (body), well under the 500-word hard cap |

No per-agent table yet since no platform runs have occurred. This section will be filled in with
agent name / evaluator / verdict / message count / files touched / LOC / failed test names / failure
reason / one-line approach note after the first platform batch.

## Batch 8 (2026-09-04) - 10x Nova, suite at 150 tests

| Agent | Verdict | new | base | Files | Failed test names | Failure reason / approach |
| --- | --- | --- | --- | --- | --- | --- |
| Nova_Nova_1 | FAIL_MISSED_REQUIREMENT | 149/150 | 52/52 | 5 | mapCodecEncodeIncompatibleNarrowCandidateIsThatCandidatesFailureWithPersistentBuilder | Covariance: an incompatible narrow candidate is not reported as that candidate's own failure when the caller supplies a persistent builder |
| Nova_Nova_2 | PASS_LEGITIMATE | 150/150 | 52/52 | 5 | - | OrderedAlternatives + OrderedCodec + OrderedMapCodec; reflective TrackingBuilder proxy over the supplied builder with a parallel DataResult state |
| Nova_Nova_3 | FAIL_MISSED_REQUIREMENT | 147/150 | 52/52 | 4 | mapCodecEncodeOutrightFailureIsNormalizedWhenCandidateReturnsAReplacementBuilder, mapCodecLabeledVariantEncodeLabelsReturnedBuilderWhenCandidateReturnsAReplacementBuilder, mapCodecEncodeIdentifiesCandidateOnReturnedBuilderWhenCandidateReturnsAReplacementBuilder | Replacement-builder axis: neither qualifies nor stabilises the builder the candidate returns |
| Nova_Nova_4 | FAIL_MISSED_REQUIREMENT | 145/150 | 52/52 | 5 | the three replacement-builder tests, plus mapCodecEncodeIncompatibleNarrowCandidateIsThatCandidatesFailureWithPersistentBuilder and mapCodecEncodeOutrightFailureNormalizesTheReturnedBuilderWhenBuilderDoesNotMutateInPlace | Replacement-builder axis plus covariance plus non-mutating builders |
| Nova_Nova_5 | FAIL_MISSED_REQUIREMENT | 148/150 | 52/52 | 5 | mapCodecEncodeReportsTheSameNestedFailureWhicheverBuilderKindTheCallerSupplies, mapCodecEncodeIncompatibleNarrowCandidateIsThatCandidatesFailureWithPersistentBuilder | Message depends on the caller's builder kind; covariance |
| Nova_Nova_6 | FAIL_MISSED_REQUIREMENT | 147/150 | 52/52 | 5 | the three replacement-builder tests | Replacement-builder axis |
| Nova_Nova_7 | FAIL_MISSED_REQUIREMENT | 147/150 | 52/52 | 5 | two replacement-builder tests, plus the persistent-builder covariance test | Replacement-builder axis plus covariance |
| Nova_Nova_8 | PASS_LEGITIMATE | 150/150 | 52/52 | 4 | - | OrderedAlternativesCodec + OrderedAlternativesMapCodec in the root package |
| Nova_Nova_9 | FAIL_MISSED_REQUIREMENT | 143/150 | 52/52 | 5 | 7 tests, spanning nested-outer identification, both replacement-builder families (supplied and returned), and position/label qualification of MapCodec encode errors | Candidate qualification on the MapCodec encode path largely absent |
| Nova_Nova_10 | FAIL_MISSED_REQUIREMENT | 147/150 | 52/52 | 5 | two replacement-builder tests, plus the persistent-builder covariance test | Replacement-builder axis plus covariance |

Pass rate 2/10 = 20%, inside the <= 50% ceiling and at the hard edge. FP panel adjudicated both passes
GENUINE (two solo dissents, both on the builder-internal-key-rejection path, both overruled as
out-of-contract and builder-specific).

Discriminator kill counts across the eight failures:

| Test | Kills |
| --- | --- |
| mapCodecEncodeIdentifiesCandidateOnReturnedBuilderWhenCandidateReturnsAReplacementBuilder | 6 |
| mapCodecLabeledVariantEncodeLabelsReturnedBuilderWhenCandidateReturnsAReplacementBuilder | 6 |
| mapCodecEncodeIncompatibleNarrowCandidateIsThatCandidatesFailureWithPersistentBuilder | 5 |
| mapCodecEncodeOutrightFailureIsNormalizedWhenCandidateReturnsAReplacementBuilder | 3 |
| mapCodecEncodeIdentifiesOuterCandidateWhenThatCandidateIsItselfAnOrderedAlternativesMapCodec | 1 |
| mapCodecEncodeErrorIdentifiesAttemptedCandidateByPosition | 1 |
| mapCodecLabeledVariantEncodeErrorUsesLabelInsteadOfPosition | 1 |
| mapCodecLabeledVariantEncodeLabelsSuppliedBuilderWhenCandidateReturnsAReplacementBuilder | 1 |
| mapCodecEncodeIdentifiesCandidateOnSuppliedBuilderWhenCandidateReturnsAReplacementBuilder | 1 |
| mapCodecEncodeReportsTheSameNestedFailureWhicheverBuilderKindTheCallerSupplies | 1 |
| mapCodecEncodeOutrightFailureNormalizesTheReturnedBuilderWhenBuilderDoesNotMutateInPlace | 1 |

Every failure dies on the MapCodec encode builder-propagation axis or on runtime covariance. No
failure comes from decode, lifecycle folding, validation, keys, rendering or equality - those are
solved by everyone, which is why the suite needs them for fairness but they carry no difficulty.

## Batch 8 differential harness (2026-09-05, Iteration 56)

Both PASSING solutions were rebuilt locally from agent-runs/8 and re-run against every test change
before it shipped.

| Candidate test change | Nova_Nova_2 | Nova_Nova_8 | Shipped |
| --- | --- | --- | --- |
| 9 new coverage tests (remainder, non-empty prefix, partial-path qualification, third builder kind, labeled duplicate keys) | 159/159 pass | 159/159 pass | YES |
| Reviewer-suggested JsonOps numeric-key regression, add(T,T) | FAIL | FAIL | NO |
| Reviewer-suggested JsonOps numeric-key regression, add(T,DataResult) | FAIL | FAIL | NO |
| Reviewer-suggested JsonOps numeric-key regression, add(DataResult,DataResult) | FAIL | FAIL | NO |

Shipping the three regression cases would have taken the batch from 2/10 to 0/10 (unsolvable-reject).
The reference now implements the behavior; the suite does not demand it.

## Iteration 67 (2026-09-06) - Path C executed: surrogate removed, suite 182 -> 173

| Check | Result |
|---|---|
| Base suite, clean BASE_COMMIT + both patches | 52/52 pass, 0 failures (3x identical) |
| New suite, clean BASE_COMMIT + both patches | 173/173 pass, 0 failures (3x identical) |
| F2P: clean checkout + test.patch ONLY | exit 1, 173 named failing testcases; base 52/52 pass |
| Flakiness (3x new, 3x base) | identical every run, 0 flakes |
| MUT-A - drop `.mapError(describe)` on the returned builder | 11/173 fail (expected) |
| MUT-B - drop the StableWhenNoPartial normalization wrapper | 9/173 fail (expected) |
| MUT-C - MapCodec encode uses the last candidate instead of the first | 4/173 fail (expected) |
| MUT-D - decode short-circuits on the first partial | 7/173 fail (expected) |
| MUT-E - decode keeps the latest partial instead of the earliest | 1/173 fail (expected) |
| Restoration after every mutation | `diff` against pristine copy clean; "pristine-clean" confirmed |
| S1 #1 probe (AbstractStringBuilder over JavaOps, numeric key) | OLD `Error['Not a string: 1']` unqualified -> NEW `Error['Alternative 0: Not a string: 1']`, Stable. Finding REAL, FIXED |
| S1 #2 probe (JsonOps.COMPRESSED, numeric key) | Does not reproduce: `getStringValue` accepts numbers when `compressed`, so no mirror mismatch exists |
| S1 #2 probe (JsonOps.COMPRESSED, boolean key - mismatch DOES occur) | OLD and NEW both Experimental and both correct; `mergeToList` into COMPRESSED empty pins Experimental even with no `setLifecycle` call |
| LOC (Counter 2, human-effective) | 270 (was 347); raw 419; 5 files. Inside the 250-300 design band, above the 200 floor |
| Test count | 173 `@Test` methods (was 182); 9 removed, 0 added |
| meta.md word count | 477 (was 496), ASCII, no em-dashes |
| test.sh executable bit | `new file mode 100755` confirmed in test.patch |
| Patch encoding | both ASCII text |
| Banned markers (`shipd` / `datacurve`) | none |
| Comments added by solution.patch | none beyond the repo's own copyright headers |

### Differential harness vs the batch-8 passers (rebuilt from agent-runs/8)

| Passer | Fails at iteration 66 (of 182) | Fails now (of 173) |
| --- | --- | --- |
| Nova_Nova_2 | 7 | 5 |
| Nova_Nova_8 | 5 | 3 |

Failure breakdown, both passers: 2 lifecycle-decorator (`deprecated(7)`, `withLifecycle`) and, for
Nova_2, 3 supplied-builder-negative; Nova_8 fails 1 of the latter. Every one is now description-covered
- the lifecycle-decorator requirement was written into meta.md this round precisely because it was the
last one that was not.

Margin improved this round rather than tightening. Both passers still fail, so on that FIXED population
the rate reads 0/10; that population solved a substantially older description, and per L35 a
description delta is not measurable this way. Re-eval is unavailable (meta.md changed), so the next
batch is full price and is the real number.
