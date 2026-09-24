ACCEPTED 2026-09-21 at 5/12 (Nova 4/10, Orion 1/2), on a FP-clean re-eval of batch 3. Finalized.

# libspatialindex-tpr-temporal-knn - feedback

Status: ACCEPTED. The accepted artifact is the round-6 state: 73 tests, meta.md 490 words, no
backward-compatibility sentence. Round 7 below (a legacy-page test plus one meta sentence) was written
locally but never uploaded; it was reverted before archiving so this folder matches what was accepted.

## Platform precheck (human, 2026-09-20): PASSED
Verbatim: "Passed - the rest of the funnel is unlocked. Pass: the flagged corpus candidates are distinct,
their union does not cover the task, upstream still contains the TPR-tree stubs, and the feature aligns
directly with the repository's documented TPR-tree and nearest-neighbor goals." No quality or description
warnings were raised, so nothing was declined. Requirement 0 picker check was already done ("eligible -
license not recognized"); the MIT evidence is below and unchanged.

## Licence evidence (Requirement 0 done by the human; picker says "eligible - license not recognized")
- COPYING at base 494d966f is MIT since 1.8.0; it opens with a history note about the pre-1.8.0 LGPL
  releases, which is why GitHub reports NOASSERTION.
- 95/96 src+include files carry the MIT header; src/tools/rand48.cc carries a permissive Birgmeier
  notice; vendored test/gtest is BSD-3. No GPL text anywhere.
- Precedent: pandapower, grmtools and laspy were approved at NOASSERTION.
- Rule for this problem: no code copied from vendored gtest or rand48 into the solution (none is).

## Slice contents
- Lane (hunt 2026-09-19-G RANK 1): TPR-tree `nearestNeighborQuery` (both overloads) and `selfJoinQuery`,
  which throw "not implemented yet" at base (TPRTree.cc:349/:361, since the 2007 import). C API
  `Index_TPNearestNeighbors_id/_obj` was already wired and starts answering.
- Reference: new interval kernel `MovingRegion::getMinimumDistanceInTime` (piecewise-affine gaps,
  breakpoints, per-piece quadratic vertex, instant = single evaluation), common-instant kernel
  `MovingRegion::intersectsRegionAtSameInstant` (affine half-line intersection), query normalisation for
  MovingRegion/MovingPoint/TimeRegion/TimePoint (Moving* checked first), horizon guard identical to range
  queries, time-aware default `NNComparator` (data entries through the IData overload), RTree-style
  best-first kNN (ties at the k-th, max_dist, return value), pairwise node self-join reporting each pair once.
- 4 files, 302 raw / **214 human-effective** (hook). Under the 250 target: FINISH plan in DESIGN.md section 7
  (TPR range queries for every time shape and instants, where `pointLocationQuery` throws at base; MVR
  historical kNN + join held as a breadth-only reserve). Hook also reports padding-floor 44: the kNN loop
  mirrors RTree's, so FINISH depth must be new logic, not more loop.
- Tests: `test/gtest/TPRTreeTemporal_48145d.cpp`, own executable `tprtree_temporal_test`; 11 tests.
- test.sh runs each gtest case in its own process (a crash fails one case, not the file), merges JUnit,
  writes a failing case with the build log when the build fails.

## FINISH scope (2026-09-20)
- Executed DESIGN.md section 7 plan (a). The TPR range queries now go through the same normalisation as
  the kNN, so `intersectsWithQuery`, `containsWhatQuery` and `pointLocationQuery` take a moving region, a
  moving point, a time region or a time point and a single instant; containment moved to a new exact
  kernel `MovingRegion::containsRegionAtEveryInstant` (endpoint evaluation is exact because each bound is
  affine in time); `pointLocationQuery` stopped wrapping its argument in a static `Region` and answers;
  `insertData` and `deleteData` take velocity bounds through `getVelocityBounds`, so a stationary entry
  may be given as a time region or a time point; the C API builds its time-parameterised query region so
  that a start equal to the end is accepted.
- Declined reserve (b), MVR-tree historical kNN and join. It is a second index type solved by reusing the
  TPR loop plus two rules the repo's own `MVRTree::rangeQuery` already shows (a visited-id set and an
  interval liveness test), so it would be breadth, not coupling: HARDENING on breadth dilution, L58
  (machinery beside a kernel is LOC and FP insurance, never band), L61 (a breadth-only program can kill
  every run through a pre-existing bug outside the feature) and the TOO-EASY scope-lever rule (a bolted-on
  second feature doubles the collision surface without differentiating the core). The floor did not need
  it. Reasoning recorded here instead of asking, as the unattended run requires.
- 5 files, 360 raw / **259 human-effective** (hook), padding-floor 113. Above the 200 floor and the 250
  target; the hook's 275 design target is not met and was not chased with a second subsystem.
- Tests: 30 in `test/gtest/TPRTreeTemporal_48145d.cpp`, all failing on base, none of them calling a symbol
  the solution adds (so the target still compiles on base and each case fails on its own).
- meta.md rewritten for the full scope: 443 body words, ASCII, no headers. Every tested behaviour has a
  sentence and every sentence has a test (L53 both directions). `internalNodesQuery` is left throwing and
  is not claimed: the description says "its three range queries", which is the repo's own `rangeQuery`
  family.

## Batch 4 = re-eval of batch 3 (2026-09-21): 5/12, FP clean, ACCEPTED

Fingerprinted: all 12 runs carry byte-identical source hunks to batch 3, so this is one 12-run population,
not 24. The FP panel adjudicated all five passes genuine; every judge-c dissent (unversioned page format on
the four Nova passers, id-only deletion on Orion) was over-ruled as outside the prompt. Auto Review
approved 3/2/3 with one Medium coverage note (`TimedBox` not passed to nearest-neighbour or self-join).

Finalize carried F-47 and F-48 (new), L82-L84 and Pattern 101 into `failure-patterns.md`, the three skills
and the Instructions files.

## Batch 3 (10x Nova + 2x Orion, 2026-09-21): 5/12 = 42%, and the FP panel found the lever

| Agent | Pass | Rate |
|---|---|---|
| Nova | 4/10 | 40% |
| Orion | 1/2 | 50% |
| Total | 5/12 | 42% |

The expiry wall is doing real work now: the seven failures are spread across genuine answer
mismatches - deep stopping scenes, self-join over every query shape, single-instant C API, entry
reference times, point location.

**The decisive evidence came from the graders, not the rate.** One run (Nova 6) passed all 73 tests
and all 27 baseline tests, and the EVALUATOR still failed it: "Node::storeToByteArray now writes an
additional entry end-time double, while Node::loadFromByteArray always reads that extra field and
does not inspect a format/version flag ... The reference implementation preserves compatibility with
a PersistentEntryEndTimes flag." The FP panel then raised the same probe against four more passers,
upheld it once (Nova 4, voided as a false positive) and over-ruled it three times as "unstated in the
prompt". A panel splitting three ways on one probe is the definition of an ambiguous description, and
the FP doctrine says to fix the ambiguity rather than pick a side.

## Round 7 (2026-09-21): state backward compatibility, and it is the first real lever in four rounds

meta.md gains one sentence: "An index written by an earlier release of the library still loads, and
nothing stored in it stops." That is behaviour, not mechanism - it names no flag, no format and no
file. 498 words, inside the cap.

`AnIndexFromAnEarlierReleaseStillLoads` builds a legacy leaf page by hand in the pre-change layout
(node type without the flag, no per-entry end time), overwrites the root page of a real tree with it,
reloads through the public `loadTPRTree`, and asserts the entry is found where it would be if it
never stopped and NOT where it would be had it stopped. The fixture is written from scratch in the
BASE layout, so it does not depend on whatever new layout a candidate chooses - only on its ability
to recognise an old page.

**Measured against the batch-3 runs that had a clean suite:**

| Run | 73 tests | + legacy-page test |
|---|---|---|
| Nova 2, 4, 6, 7, 8 | pass | **fail** |
| Orion 2 | pass | pass |

Five of six die. That is the first lever in four rounds of searching to kill anything, and it is the
one the platform's own evaluator and FP panel pointed at. Projected band: 1/12 = 8% on this exact
population. The live number will be higher, because a batch that READS the new sentence will build a
version flag (L35) - which is the point: the rate should land between 8% and 42%.

Mutant `P2_no_page_version_flag` reproduces the agents' actual implementation (always write the end
time, always read it, no flag) and kills exactly that one test, 1 of 74.

**Not acted on:** the Orion dissent that `deleteData` removes by id alone rather than by shape. The
adjudicator ruled it over-flagging - the prompt constrains delete-shape typing and validation only,
it sources the shape-guided contract from `docs/overview.rst`, and it surfaces only under incorrect
API usage. Adding a test for it would be a gate on unstated behaviour, the same defect that failed
Test Quality in round 3.

## Round 6 (2026-09-21): four-kind closure on mutations - fixed, and it kills nobody

Solution Quality FAIL: `insertData`/`deleteData` accepted any `ITimeShape`/`IEvolvingShape`, not just
the four kinds, so a user-defined timed shape was inserted successfully. The finding is correct and
it is a direct consequence of MY round-5 meta.md broadening ("whether the shape is a query or is
handed to `insertData` or `deleteData`") - I widened the contract and left the implementation behind.

Fixed by deleting `getVelocityBounds` entirely and routing both mutation paths through the same
normaliser the queries use, renamed `getQueryRegion` -> `getShapeRegion` since it is no longer
query-only. Acceptance and exception behaviour are now identical across every entry point by
construction rather than by duplicated checks, and `insertData`/`deleteData` each lost ~10 lines of
hand-rolled MBR/VBR copying.

Tests added for the finding and for all four advisory cells: a `TimedBox` in the test file (a
`Region` that also implements `ITimeShape`, i.e. exactly the reviewer's shape) rejected on insert,
delete and query; untimed `Region`/`Point` rejected on both mutation paths; reversed `MovingPoint`
/`MovingRegion` construction; 3-D moving shapes rejected on insert and delete; and
`pointLocationQuery` at both horizon boundaries.

**All five passers still pass.** Their own shape normalisers already close over the four kinds and
already validate the point-location horizon, so this was a gap in the reference alone. Replay stays
5/10.

### Lever search, four rounds, zero kills

| Round | What was tried | Kills among passers |
|---|---|---|
| 1 | 57-cell differential probe | 0 of 7 |
| 1 | 16 coverage tests (both review follow-ups + all six advisories + a rigid-box axis) | 0 of 7 |
| 5 | 4 expiry composition cells (two knees, boundary knees, nearest across knees, second deep scene) | 0 of 5 |
| 6 | 2 four-kind closure tests + 4 advisory cells | 0 of 5 |

The entry-expiry wall did real work - it took the fair rate from 70% to 50%, and the five failing
runs fail on genuine answer mismatches in containment-with-stops, growing boxes and deep-tree range.
But every search for a discriminator among the PASSING population has come back empty, in two
different agent populations built under two different prompts.

### Why stronger agents are the wrong answer

Orion and Vega are stronger than Nova, so appending them raises a 50% rate. L65's "append Orion" case
applies when near-misses fail STATED sentences; here the near-misses were failing an UNSTATED
assertion of mine, and once it was removed they pass outright. Vega is locked until Gold rank anyway.

## Batch 2 (10x Nova, 2026-09-21): 0/10 - but the blocker was MY assertion, not the feature

| Run | Failed | Sole failure? |
|---|---|---|
| Nova 2, 5, 7, 9, 10 | 1 | yes - `DeepTreeWithStoppedEntriesMatchesExhaustiveSearch` |
| Nova 4 | 4 | no |
| Nova 1, 8 | 8 | no |
| Nova 3 | 11 | no |
| Nova 6 | 13 | no |

`DeepTreeWithStoppedEntriesMatchesExhaustiveSearch` failed in ALL ten runs, and **nine of those ten
failed on `ASSERT_TRUE(scene.tree->isIndexValid())`, not on a wrong answer**. Classified across the
whole batch: 40 answer mismatches and 9 `isIndexValid` failures, the latter all in that one test.

**That assertion was unfair and I should not have written it.** `isIndexValid()` recomputes each node
bound its own way and demands EXACT equality with the stored one. Once entry expiry forces node
bounds to stay sound for a stopping child, any sound-but-different bookkeeping - widening low/high
instead of relaxing velocities, for instance - fails the equality check while every query answer is
correct. meta.md says nothing about it. It pins a representation, not a behaviour (L8).

The proof is in the replay: with the assertion removed, the five near-misses pass the very oracle
comparisons in that same test that the ASSERT had been aborting before they ran. Their node bounds
were sound all along; only their bookkeeping differed from mine.

Removed all seven `ASSERT_TRUE(isIndexValid())` calls from the suite. The repo's own base tests still
call it, and they stay green because their entries are unbounded, so nothing expires and the
validator change is an identity.

## Round 5 (2026-09-21): Auto Review revision + the fair band is 50%

### Auto Review findings, all fixed

- **High, `deleteData` accepts a reversed interval and moves current time backward.** Real bug. A
  reversed `TimePoint`/`TimeRegion` reached `m_currentTime = pivI->getUpperBound()` and, on a one-leaf
  tree, `Leaf::findLeaf` matches by id, so the delete succeeded. Guard added before any state change.
- **Medium, `insertData` same class.** Guard added before the current-time check.
- **Medium, no k == 0 test.** This is the test the previous round's Test Quality FAIL called unfair
  because the prompt never defined k = 0. Both reviewers are right, so the fix is to make it stated
  rather than to pick a side: meta.md now says "A k of 0 visits nothing", and
  `ZeroNeighboursVisitsNothing` is back, covering both overloads.
- meta.md also now scopes the rejection rules explicitly: shape kind, reversed interval and wrong
  dimensions are rejected "whether the shape is a query or is handed to `insertData` or
  `deleteData`", while the current-time and horizon rules stay query-only (which is accurate - insert
  has its own current-time rule and the horizon does not apply to it). That closes the ambiguity two
  separate reviewers flagged from opposite directions. 490 words, under the 500 cap.

### The fair band, measured

Replay of all ten batch-2 solutions against the revised suite (tests-only delta for these agents, so
it predicts a re-eval exactly):

| Suite | Pass rate |
|---|---|
| 65 tests as batch 2 ran them | 0/10 |
| 71 tests, `isIndexValid` assertions removed | **5/10 = 50%** |

None of the five passers fails the two new description-delta tests either, so the mutation-validation
and k = 0 requirements are already satisfied by their own shape-normalisation helpers.

### Four composition cells added, zero kills

`SelfJoinPairsWithTwoDifferentStopTimes` (two knees inside one query interval, the meeting window in
the middle piece), `AnEntryStoppingAtAnIntervalBoundary` (stop exactly at tmin, at tmax and at an
instant), `NearestAcrossTwoStopInstants`, and a second deep stopping scene with a different seed and
a moving query box. All four pass on all five passers. This is the third independent search that has
come back empty - 57 probes in round 1, 16 tests in round 1, 4 cells now.

### Where that leaves the pick

The expiry wall is real: it took the fair rate from 70% to 50% and the four failing runs fail on
genuine answer mismatches (containment with stops, growing boxes, deep-tree range). But 50% is still
over the ceiling, and the passing population is again behaviourally identical to the reference on
everything that can be fairly tested.

Stronger agents are the wrong lever here. Orion and Vega are stronger than Nova, so appending them
raises the rate; L65's "append Orion" case applies when near-misses fail STATED sentences, and here
the near-misses were failing an UNSTATED assertion of mine. Vega is locked until Gold rank in any
case.

## Round 4 (2026-09-20): the legacy-compat shortcut from round 3 was wrong - fixed properly

Round 3's storage-compatibility fix was a header-level flag: a tree whose header lacked the new
format word was marked `LegacyEntries` and then both read AND written in the old layout, with
`insertData` forcing an unbounded end. The reviewer caught the consequence, and they are right: after
`loadTPRTree` on a pre-change tree, a NEW insert with a finite interval silently lost its end of
motion, so an explicitly promised behaviour failed for a valid insert-then-query sequence. A
compatibility mode that changes the semantics of new data is not compatibility.

**Fix: the layout moved from the header to the page.** The node type word, which base wrote and then
deliberately skipped on load ("skip the node type information, it is not needed"), now carries a
`PersistentEntryEndTimes` flag beside `PersistentIndex` / `PersistentLeaf`. `storeToByteArray` always
writes the flag and the end times; `loadFromByteArray` reads the word and only consumes end times
when the page says it has them, giving an unbounded end otherwise; `readNode` masks the flag off
before choosing the node kind. The header format word and the `LegacyEntries` insert special case are
gone, and `insertData` unconditionally stores the supplied end time.

This is strictly better than what round 3 shipped and than what the earlier review asked for:
- every page is self-describing, so an old page and a new page can coexist in one tree, which a
  single header flag cannot express;
- a legacy tree migrates as its nodes are rewritten, with no migration pass and no downtime;
- no new entry ever loses its end of motion, whatever the tree was created by.

The header version word was removed rather than kept alongside, because with per-page versioning it
would be written and read but never consulted - a dead field is worse than no field.

**Coverage.** `AReloadedTreeKeepsEachEntrysEndOfMotion` now also inserts a finite-duration entry
AFTER the reopen and asserts it holds its position, which is the reviewer's exact scenario. Mutant
`P1_relax_only_in_branches` (4 of 65) and `E1`/`E2`/`E4` all kill it.

The legacy READ path itself stays untestable through the public API: only the pre-change library can
produce a legacy page. `P2_pages_not_self_describing` (reader ignores the flag) reds 62 of 65 new
tests and 2 base tests, which proves the field is load-bearing for page integrity but is a corruption
mutant rather than a targeted discriminator. Recorded as defensive code, not as band.

**Advisories.** The C API degenerate-interval matrix was already complete - all five `Index_TP*`
functions plus `Index_InsertTPData` and `Index_DeleteTPData` are exercised with a start equal to the
end. Wrong-dimension cases were added for `intersectsWithQuery` (region and point shapes) and
`pointLocationQuery`, so validation is now pinned on every query surface rather than only nearest,
self-join and containment.

**State:** 65 tests, 358 human-effective LOC across 8 files, 18 mutants all killed, clean room green
3x in all four configurations.

## Round 3 (2026-09-20): Test Quality FAIL + two Solution Quality FAILs closed, meta.md untouched

### Test Quality: 1 of 63 unfair - `ZeroNeighboursVisitsNothing` DROPPED

The reviewer is right and the refutation battery is sound: the prompt says the search "stops after
k" but never defines k = 0, and the sibling `src/rtree/RTree.cc:609-617` guards on
`count >= k && distance > knearest`, so for k = 0 it can still visit zero-distance ties. That is a
grounded alternative reading, which makes the test a gate on unstated behaviour.

Dropped the test, kept the `if (k == 0) return 0.0;` guard in the reference. This costs nothing:
round 1's replay measured the guard present in ALL 7 batch-1 passers, so the test killed nobody. It
is L76 exactly - keep the reference fix, ship no test. Stating k = 0 in meta.md was the alternative
and was rejected: it would add a requirement measured at 0 kills while spending words and reopening
the description.

Also took the advisory on `ComparatorSeesIndexEntriesAsShapesAndLeavesAsData`: `EXPECT_EQ(12u,
dataCalls)` became `EXPECT_GE(..., 12u)`. Every correct implementation must score all twelve leaves
(the comparator's shape overload returns 0, so nothing can be pruned), but an implementation that
evaluates an entry twice is not wrong. The assertion still kills M6, which produces 0 data calls.

### Solution Quality high 1: stopped entries pruned when inserted at the same current time - FIXED

A real bug in the reference, and the reviewer's repro is exact. `boundExpiringChildren()` was called
only inside the rebuild branch and the non-containment branch of `Node::insertEntry`. An expiring
entry whose moving prefix is already inside the current node MBR takes neither branch, so the node
keeps a non-zero velocity bound and the entry is pruned away after it stops. Fixed by calling
`boundExpiringChildren()` once after the whole conditional, so every path relaxes.

Regression added as the reviewer specified: `AStoppingEntryStaysFoundBesideAnIdenticalMover` inserts
an unbounded mover and an identical mover ending at t = 1, both at t = 0, and asserts the second is
still found at its held position at t = 2 and t = 5. Mutant `P1_relax_only_in_branches` restores the
old placement and dies on that test plus the deep-tree and C API ones (3 of 65).

### Solution Quality high 2: unversioned page format corrupts existing indexes - FIXED

Also correct. The patch widened each child record by a double, and `loadTPRTree` had no way to tell
an old page from a new one, so a pre-change on-disk index would consume the old identifier as the
new end-time field.

Fixed with an explicit persisted format version. `TPRTree::storeHeader` now writes a `m_pageFormat`
word; `loadHeader` reads it when the stored header is long enough and otherwise records
`LegacyEntries`, which is what every pre-change header is. `Node::entryTimeFields()` returns 1 or 2
from that flag, and `getByteArraySize`, `storeToByteArray` and `loadFromByteArray` all follow it, so
a legacy index is both read AND written in its own layout and its entries keep the unbounded end
time the old loader gave them. `insertData` stores an unbounded end on a legacy index for the same
reason. New indexes are created at `EntryEndTimes`.

`AReloadedTreeKeepsEachEntrysEndOfMotion` closes the tree, reopens it through `loadTPRTree` and
re-runs the queries; mutant `P2_header_has_no_format` (loader always assumes legacy) dies on exactly
that test and nothing else.

### State after round 3

Suite 63 -> 65 (one unfair test dropped, three added: the same-time pruning regression, the reload
round-trip, and `MovingRegionEntriesCanBeDeleted` for the advisory mutation-shape cell). Solution
342 -> **369 human-effective LOC across 7 files**. Clean room green in all four configurations, 3x
identical. The one comment added to the solution (`// m_pageFormat` in the header-size block) matches
the repo's own convention, where every field in that block carries the same trailing comment.

The remaining advisory - reversed-interval and wrong-dimension cases for `insertData`/`deleteData` -
was declined. The prompt sentence begins "A query shape", so it does not cover mutations; the
reviewer says so themselves ("clarify that scope in the prompt first"). Testing it would be a gate
on unstated behaviour, which is the same defect that just failed Test Quality.

## Hardening round 2 (2026-09-20): the entry-expiry wall (description delta, full-price batch)

Round 1 proved no tests-only lever existed, so this round spends a description delta. One sentence
changed in meta.md; everything else about the contract is unchanged.

> An entry moves from the start time of the shape it was inserted with **until that shape's end
> time, and holds the position it reached from then on; an entry inserted with a shape whose
> interval has no end never stops.**

**Why this axis and not more geometry.** The 57-probe differential showed the passers are identical
to the reference on every derivable-geometry cell (L58: a fully stated kernel is transcribed). The
one thing all seven convergent solutions skip is the repo's own machinery: each writes a private
`makeMovingRegion` plus private predicates over EXTRAPOLATED coordinates, and never touches the
tree's stored state. The expiry rule is stated behaviourally, it agrees with the repo's own
documented model (`MovingRegion::getLow`/`getHigh` are commented "assumes that the region is not
moving before and after start and end time"), and it cannot be satisfied by any amount of geometry
reasoning because the information does not survive the node page.

**Why it is hard, in seven layers.** The base tree throws the entry's end time away twice:
`insertData` overwrites it with infinity, and `Node::loadFromByteArray` hard-codes infinity while
`storeToByteArray` never writes it (the author's own commented-out lines are still there). So an
implementation must (1) keep the shape's end on the stored entry, (2) widen the node page format to
persist it, (3) clamp position AND rate in every predicate, (4) keep node bounds sound now that a
child can stop under a still-moving parent, (5) split containment at the stop instants because
endpoint evaluation is no longer sufficient, (6) split the common-instant window solver, and (7)
split the minimum-distance solver. Layers 5 to 7 are the misdirecting ones: point evaluation keeps
looking right while the SOLVERS silently work on the wrong piece, and layer 4 shows up only as a
silently missing id on a deep tree.

**Fairness.** Contract-stated and fix-hidden: the sentence says what an entry does, not that page
format, node bounds or piecewise solvers are involved. It agrees with the repo's own docs rather
than contradicting them (L19). The repo's own 27 tests still pass untouched, because the repo's own
insert helper already uses an open-ended interval - so this is additive for existing usage, not a
silent redefinition.

**Measured trap decomposition (16 mutants, each the natural wrong implementation of one layer):**

| Mutant | Wrong implementation | Kills |
|---|---|---|
| E1 | entry stored with an infinite end, as base does | 6 |
| E2 | end time not written to / read from the node page | 6 |
| E3 | predicates read raw extrapolated coordinates | 6 |
| E4 | node velocity bounds not relaxed for stopping children | 3 |
| E5 | containment evaluated at the interval endpoints only | 1 |
| E6 | common-instant window solved over one piece | 1 |
| E7 | minimum distance solved over one piece | 1 |

E1, E2 and E3 share a kill set because they are the same axis at three layers; E4 to E7 are
distinct. E7 initially killed nothing, which exposed a real coverage hole - the single-piece solver
only goes wrong when the interval midpoint lands past the stop while the true minimum lies before
it - so `NearestFindsTheClosestApproachBeforeAnEntryStops` was written for exactly that geometry.

**Cost accounting.** Solution 251 -> 342 human-effective LOC, 5 -> 7 files (`Node.cc` and `Node.h`
are new to the patch). Suite 56 -> 63 tests. Six existing fixtures had to be re-derived because
they inserted entries with a finite interval; the C API fixtures now insert with an open end, which
is what the repo's own helper already did.

**Risk going into batch 2.** Unmeasurable before the batch: a description delta changes what agents
BUILD, so the replay harness cannot price it (L35) and there is no re-eval button. The three batch-1
walls killed 3 of 10 on their own; if the expiry wall kills most of the remaining seven the batch
could undershoot. If it reads 0%, the graded relaxation to try first is dropping the node-bound
layer (E4, the deep-tree-only one) rather than the expiry rule itself.

## Batch 1 (10x Nova, 2026-09-20): 7/10 = 70% pass - TOO-EASY

| Run | Verdict | New-test failures |
|---|---|---|
| Nova 1 | fail | 5 - distance kernel evaluates endpoints and strict interior vertices but never the breakpoints themselves |
| Nova 2 | fail | 2 - containment accepted any subinterval instead of every instant |
| Nova 5 | fail | 4 - the common-instant window was reset per dimension instead of intersected across them, and a plain untimed `Point` was accepted by `pointLocationQuery` |
| Nova 3, 4, 6, 7, 8, 9, 10 | pass | 0 |

Every evaluator called the task "challenging", the description clear and the tests deterministic;
no run was flagged for cheating or environment trouble. The rate, not the artifact, is the defect.

## Hardening round 1 (2026-09-20): no fair lever found, two independent measurements

Diagnosis from the Stage-2 table: "everyone passes, few or no failures" plus the L58 row (a kernel
the contract states step by step gets transcribed). Both were tested directly rather than assumed.

**Measurement A - 16 new tests, replayed on the saved solutions: 0 new kills.**
A replay harness (pristine base at BASE_COMMIT + each run's `src/`+`include/` patch + the candidate
`test.patch`, in the clean-room image) reproduces batch 1 exactly, so for a tests-only delta it
predicts a re-eval (L40). I wrote 16 candidate tests covering every gap Auto Review and the test
fairness report named, plus an F-10 cross-product axis of my own:

- the two Auto Review follow-ups (`containsWhatQuery` with `TimePoint`/`MovingPoint`; `k == 0`)
- all six advisory "not discriminating" suggestions (C API single-instant breadth on the object and
  count paths, self-join rejection of untimed shapes, the validation matrix on the remaining range
  and self-join entry points, the horizon matrix, comparator parity with `max_dist`, ties and order)
- a genuinely unfilled axis: every fixture in the suite used a RIGID box (`vlo == vhi`), so nothing
  tested an entry or query whose low and high corners move at different velocities. Added growing
  boxes to intersection, containment, nearest, self-join and a 70-entry deep tree.
- far-future queries deep inside the horizon, `k` greater than the entry count, an entry flush with
  the query edge, `pointLocationQuery` following a moving query point.

Result: **7/10 before, 7/10 after.** The 16 tests killed nobody who was not already failing (Nova 2
picked up 4 more failures it did not need). Suite grew 40 -> 56 with zero band bought.

**Measurement B - 57-probe differential harness: 0 divergences among the 7 passers.**
Since new tests bought nothing, I probed for divergence directly instead of guessing more tests. A
standalone probe program exercises 57 cells of the stated contract - nearest `k`/`max_dist`
boundaries and distance values on tricky geometry, entry motion past its insertion shape's own end,
the range and point-location grids, self-join over all four query shapes plus instants, touching,
identical and single-entry cases, the whole validation matrix, mutation acceptance, and the C API -
and prints a canonical line per cell. Run against all 10 saved solutions and the reference:

- **2 of 57 cells diverge at all**, and both belong to already-failing runs (Nova 5 accepting a
  plain `Point` in `pointLocationQuery`; Nova 1's distance value near the horizon edge).
- **0 of 57 cells diverge between the reference and any of the 7 passers.**

The passers are behaviourally identical to the reference across the entire probed contract. There is
no stated-but-untested behaviour left to test, which is what "no fair lever" means measured rather
than asserted.

**Why, structurally.** Every passer converges on the same architecture: a private
`makeMovingRegion()` that normalises all four shapes into one `MovingRegion`, then self-contained
`boxesMeet` / `boxContains` / `minimumDistance` predicates over extrapolated coordinates, bypassing
the repo's own `MovingRegion` machinery. All seven independently derived the piecewise-linear
breakpoint distance, the across-dimension common-instant intersection and endpoint-sufficient
containment - and all seven already had the `k == 0` guard and the `max_dist > 0.0` test that Auto
Review flagged as missing in MY reference.

**Death class.** `TOO-EASY.md` row 32 (new value kind in a generic evaluator) and row 30
(spec-knowable predicate domain). This is their computational-geometry twin: interval box geometry
is DERIVABLE, so to be fair the description must state the predicates, and once stated a competent
agent re-derives the same kernels. customasm-exact-fractional-values died the same way with the same
evidence shape (35 probes x 16 solutions, zero divergence outside the stated formula) at 8/8 then
7/8; cfn-guard-cidr-operator at 5/10 then 6/10.

**What is NOT available as a fix.** Tests-only levers are exhausted by the two measurements above.
A description-delta second mechanism would cost a full-price batch with no re-eval, and nothing in
this lane qualifies: the MVR-tree reserve is the same derivable geometry (DESIGN.md section 7
already declined it), and the C API is plumbing. Re-rolling for batch variance would be paying
against mechanism-level evidence that explains why the rate is high.

## Solution-quality review FAIL, closed 2026-09-20 (R2) - no meta.md change

Pre-batch solution-quality review returned FAIL (Comprehensiveness 1/3, Code Quality 3/3) with two high
issues, plus a test-fairness coverage report flagging two prompt-stated requirements as untested and six
as not discriminating. Both high issues were real contract gaps. Fixed in the reference; meta.md, the
Dockerfile and the base commit were NOT touched, so the solver-visible surface is still frozen.

Issue 1 - negative max_dist suppressed every result. `nearestNeighborQuery` broke on
`if (max_dist && pFirst.m_minDist > max_dist)`, so `max_dist = -1` made the root entry at distance 0
trip the cap and the query returned 0 having visited nothing. The description says the cap applies only
"when `max_dist` is greater than 0", so a non-positive cap must mean unbounded. Now
`if (max_dist > 0.0 && ...)`.

Issue 2 - single-instant moving shapes were only worked around in the C query wrappers. The slice built
its degenerate query region by constructing a MovingRegion over [0, 1] and calling `setBounds`, because
`MovingRegion::initialize` and `MovingPoint::initialize` reject `m_endTime <= m_startTime`. That left a
native caller unable to build `MovingRegion(..., 5.0, 5.0, dim)` at all, left `MovingRegion::operator=`
asserting a strictly positive interval, and left `Index_InsertTPData` / `Index_DeleteTPData` - which
construct those types directly, outside the wrapper - refusing an instant. The description promises the
instant for query shapes, for `insertData` / `deleteData` shapes and for the time-parameterised C calls.
Fixed at the source: both constructors now reject only a reversed interval, `operator=` asserts
`<=`, and the two exception messages changed from "degenerate" to "reversed". The `NewTPQueryRegion`
wrapper and the [0, 1]-then-assign normalisation are gone (`src/capi/sidx_api.cc` is back to base,
untouched), and `getQueryRegion` now constructs each shape with its own bounds and validates the
interval once up front through `Tools::IInterval`.

Coverage: 10 new tests (30 -> 40), no description change needed because every one of them tests a
sentence that was already there.
- `NearestVisitsEntriesInAscendingDistanceOrder` - visitation order, unsorted, with a tie at the k-th
  (the untested "ascending order" requirement; every other nearest test sorted the ids).
- `ANonPositiveMaximumDistanceDoesNotRestrictTheSearch` - max_dist -1 and 0 both unbounded (issue 1).
- `ComparatorSeesIndexEntriesAsShapesAndLeavesAsData` - counting comparator on a deep tree, asserts the
  IShape overload is used at least once and the IData overload exactly once per data entry.
- `MovingShapesCanAskAboutASingleInstant` - MovingRegion and MovingPoint query shapes built directly
  with start == end (issue 2).
- `MovingPointEntriesCanBeInsertedAndDeleted` - MovingPoint as an insert and a delete shape, inserted at
  an instant.
- `SelfJoinReportsEachPairAsTwoDataEntries` - visitor asserting `data.size() == 2` exactly (the shared
  `sidx_test::IdVisitor` only asserts `>= 2`).
- `SelfJoinAcceptsAMovingPointQuery` - MovingPoint as a self-join query shape.
- `SelfJoinCountsBoundaryContactOnly` - a pair whose only common instant is boundary contact at the end
  of the interval, and the same pair with the interval cut short.
- `CApiReturnsTheNearestMovingObjectsAsItems` - `Index_TPNearestNeighbors_obj` end to end, validating
  `IndexItem_GetID` (the prompt names the call; only `_id` was exercised).
- `CApiAcceptsASingleInstantForObjectsAndMutations` - equal start and end through
  `Index_InsertTPData`, `Index_TPNearestNeighbors_obj` and `Index_DeleteTPData`.

Declined from the coverage suggestions: nothing on the list was skipped, but `Index_InsertTPData` was
left constructing its shape outside its own try block (a pre-existing base bug that lets a C++ exception
cross the `extern "C"` boundary for a reversed interval). Fixing it is out of scope for this feature and
the description says nothing about which RTError an invalid time maps to, so testing it would be a
hidden requirement.

LOC moved 259 -> 250 human-effective (the removed workarounds), still over the 200 floor. Mutation
battery grew 16 -> 20; M15 was repurposed from the deleted C wrapper to the constructor relaxation, M16
was retargeted at the new `IInterval` guard, and M17 (max_dist truthiness), M18 (results emitted in
reverse), M19 (pairs reported twice) and M20 (touching is not a meeting) are new.

## Scope-lock gates (run before any code, 2026-09-19)
- Gate 1 behavioural F2P: base throws IllegalStateException for every call; no in-repo primitive gives an
  interval minimum distance (only `getCenterDistanceInTime`, an integral of centre distance) or a
  three-shape common instant. PASS.
- Gate 5 cold: tprtree capability untouched since 2007 apart from lint/override sweeps; repo activity is
  RTree (#303 NaN, #277/#279 open, both RTree-only). PASS.
- Gate 6 reproduce on base: clean room, 11/11 new tests fail on base with the "not implemented" throw. PASS.
- Gate 7b exclusivity (canonical org libspatialindex/libspatialindex, no move): PR search in all states for
  nearest / TPRTree / TPR / selfJoin / self join / not implemented / moving / kNN / MVRTree / temporal /
  time parameterized / nearestNeighbor. Diffs read for #279, #277, #266, #38, #208, #248: none touches TPR
  kNN or join. PASS.
- Gate 8 defined behaviour / philosophy: no decline; #247 maintainer: "That index type needs more attention
  and proper testing"; #276 maintainer wants the comparator data overload supported. PASS.
- SIX-CHECK: literal (0), namespace (0), philosophy (no refusal), closed-implemented (0), base..HEAD (base
  IS main HEAD 494d966f, re-checked), capability probe (throws). Clean.
- Sibling/port check: ~30 vendored TPRTree.cc copies on GitHub all throw; no getMinimumDistanceInTime
  anywhere; Boost.Geometry has no TPR; the only "TPR-Tree" repos are a 0-star toy and a ctypes wrapper.
- Local dedup: no spatial-index or moving-object kNN pick in problems/, rejected/, approved-problems/.
- Risks recorded, not gates: (1) MAGNET - the two throws are visible to any author scanning src/tprtree,
  and TP-kNN is textbook-adjacent (Tao/Papadias). Only the precheck can see a rival. (2) LOC 214 at the slice.

## Trap reproduction (mutation battery, superseded by the R2 table in eval-results.md)
| Mutant | Natural wrong implementation | New tests failed |
|---|---|---|
| M1 | default comparator left velocity blind (`query.getMinimumDistance`) | 7 |
| M2 | kernel evaluates endpoints + breakpoints, no quadratic vertex | 2 (same-instant, deep tree) |
| M3 | per-dimension minima summed | 2 (same-instant, deep tree) |
| M4 | index entries ranked with the static distance, leaves time-aware | 1 (deep tree, silent wrong ids) |
| M5 | self-join checks the three overlaps at independent instants | 1 (self-join window) |
| M6 | leaf data sent to the comparator's shape overload (RTree copy) | 1 (custom comparator) |
| M7 | TimeRegion dispatched before MovingRegion | 1 (moving query box) |
| M8 | entries extrapolated from time 0 instead of their insertion time | 3 |
| M9 | containment read at the interval start only | 2 |
| M10 | range queries narrowed with the inherited static `Region` predicates | 8 (+2 base tests) |
| M11 | a moving point query normalised with zero velocity | 4 |
| M12 | entries still required to implement `IEvolvingShape` | 1 |
| M13 | `pointLocationQuery` still wrapping its point in a static `Region` | 2 |
| M14 | horizon guard dropped from the rewired range path | 1 |
| M15 | C API query region built through the constructor, which refuses an instant | 1 |
| M16 | reversed interval clamped instead of rejected | 2 |

16 of 16 die and all 16 kill sets are distinct, so every stated rule has a test that reacts to it
alone. M9 to M16 were re-run at FINISH against BOTH modes (L33); M10 is the one that also reds the
repo's own suite, which is the baseline-preservation axis showing up where it should. These numbers
measure what the suite detects, not what agents get wrong (L15).

## Environment findings
- CMake reconfigure as a non-root user fails on the root-built tree (`configure_file: Operation not
  permitted`, CTestTargets.cmake) whenever any CMakeLists.txt is touched (an agent adding a source file,
  or a `git checkout` of src/). test.sh now takes ownership of the prebuilt build tree (copy with modes and
  timestamps, same path, so the CMake cache stays valid) and falls back to a private build dir. Verified:
  the mutation battery (8 rebuilds after a `git checkout -- src include`) ran green on the build side.
- `git apply` inside the container needs `git -c safe.directory=/app` (root-owned /app, uid 1000).
- Release build (the repo default) so the TPR asserts (#247) are compiled out.

## Decisions taken without a human (unattended run)
- Kernel placed on `MovingRegion` as two public methods, but tests never call them, so the new test
  target compiles on base and every case fails individually rather than as one compile error.
- Instant queries come from TimePoint/TimeRegion (MovingRegion/MovingPoint constructors refuse a
  degenerate interval; a moving instant needs `setBounds(t, t)`). Stated generally ("a start equal to the
  end asks about that single instant"), FINISH adds the moving-instant cell.
- max_dist boundary cell (entry exactly at max_dist) deferred to FINISH on binary-exact geometry (L75).
- Self-join pair order inside a pair not pinned; tests normalise pairs and count them.

## Attempt history
- 2026-09-19 SLICE: design + gates + reference spike (214 eff) + 11 tests + Docker clean room; base 27/27,
  new 11/11 fail on base, 11/11 pass with the solution, 3x identical each; 8/8 mutants killed.
- 2026-09-20 FINISH: precheck PASSED with no warnings. Range-query family built out (259 eff, 5 files),
  suite grown to 30 tests, meta.md rewritten for the full scope. Cold `docker build --no-cache` 122 s.
  Clean room: base 27/27 pass in both trees, new 30/30 fail on base and 30/30 pass with the solution,
  3x identical in all four configurations. 16/16 mutants killed with 16 distinct kill sets, each run
  against base mode too. Assertion-flip: 5 flipped expectations fail exactly their own 5 tests.
  SIX-CHECK and the canonical-org PR-DIFF exclusivity check re-run immediately before the final patch
  generation and still clean; base 494d966f is still the upstream `main` head, so there is no
  base..HEAD window at all.
- One correctness fix during FINISH: the test-side overlap oracle computed its ambiguity margin from
  the width of the feasible time window, which is 0 by construction for an instant query, so every
  instant fixture tripped its own guard. The instant case now measures the margin as the smallest
  absolute pairwise gap at that instant. Reference untouched.

## Tooling for FINISH
- Working clone with the reference applied (unstaged src/include) and the tests staged:
  `worktrees/libspatialindex`. Regenerate patches + a clean-room clone: `worktrees/libspatialindex-tools/gen.sh`.
- Mutation battery: `worktrees/libspatialindex-tools/mutate.py` + `mutrun.sh` (mount a dir at /out holding
  solution.patch, mutate.py, mutrun.sh; run the image as uid 1000 with HOME=/tmp).
- Image tag `factory-libspatialindex-tpr-temporal-knn` was removed again at the end of the FINISH run;
  rebuild is ~2 min from `worktrees/libspatialindex-cleanroom` (regenerate it with `gen.sh`).
- Mutation battery for both modes: `worktrees/libspatialindex-tools/mutrun2.sh` plus `mutate.py`
  (20 mutants after R2). Mount a directory holding `solution.patch`, `mutate.py` and `mutrun2.sh` at /out and run
  the image as uid 1000 with `HOME=/tmp`; it prints one line per mutant with new-mode and base-mode
  counts and asserts that each replacement actually landed.

## Open risks going into the first batch
- Band is unmeasured. The kernels are fully stated and will be transcribed (L58), so the band has to
  come from the integration seams: the velocity-blind default comparator, index-entry pruning with the
  static distance, the comparator overload split, the dispatch order, the inherited static predicates on
  the range path and the every-instant containment quantifier. If the batch reads over 40%, the first
  lever is tests-only (more off-diagonal cells in the DESIGN section 11b matrix), which keeps re-eval
  eligibility.
- The two throws in `src/tprtree` are visible to anyone scanning the repo, so the lane stays a magnet.
  The precheck cleared it on 2026-09-20; it is worth re-reading the dedupe verdict if the first batch is
  delayed.
