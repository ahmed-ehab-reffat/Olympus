# eval-results — scikit-bio-feature-hierarchy

No agent batch has run yet. The table below is the local validation that stands in for it
until one does.

## Local verification

| Check | Command | Result |
|---|---|---|
| F2P, new tests on base | `./test.sh new` with test.patch only | 204 failed, 0 passed, 0 collection errors |
| new tests with solution | `./test.sh new` | 204 passed |
| base mode on base | `./test.sh base` with test.patch only | 887 passed, 28 skipped |
| base mode with solution | `./test.sh base` | 887 passed, 28 skipped |
| flakiness, new mode | three consecutive runs | identical JUnit node set, 0 failures |
| flakiness, base mode | three consecutive runs | identical JUnit node set, 0 failures |
| vanilla suite, bare pytest | `pytest skbio` without the sitecustomize | 57 failed, 3664 passed (numpy doctest formatting) |
| vanilla suite, submission image | `pytest skbio` in the built image, offline, uid 1000 | 3721 passed, 90 skipped, 0 failed in 25m |
| effective LOC | `effective_loc_check.py solution.patch` | 385 human-effective, 899 raw, 4 files |

## Mutation probes

One probe per designed trap, applied to a throwaway copy of the tree and reverted after each
run. A probe that kills no test is a trap that does not exist.

| Probe | Killed |
|---|---|
| transcription order: spans always ascending | 6 |
| phase taken from the lowest-coordinate interval | 5 |
| parts: `preceding % 3` instead of `(phase - preceding) % 3` | 8 |
| spans: own bounds even when the feature has children | 15 |
| merge: touching bounds left apart | 1 |
| extract: always clip from the low coordinate | 1 |
| utrs: five prime and three prime swapped | 5 |
| reverse: strand not flipped | 3 |
| sibling overlap counts touching bounds | 1 |
| parent span accepts the union of the parent bounds | 1 |
| partial: ends never swap on the minus strand | 2 |
| partial: any fuzzy bound counts, not only the outermost | 1 |
| reverse: openness not swapped | 1 |
| extract: clipped side stays closed | 1 |
| conversion: openness dropped | 1 |
| merged span: openness taken from any source bound | 3 |
| extract: openness of an untouched bound dropped | 1 |
| summary: coding length double counts | 1 |
| parents: only the first interval's Parent read | 1 |
| parents: duplicate parent names kept | 7 |
| reverse: unbounded model not rejected | 1 |
| check: rows in reverse feature order | 3 |
| derived: unnamed features described too | 1 |
| strand compared before normalising | 2 |
| strand disagreement not rejected | 1 |
| cycle check: only direct self-links caught | 2 |
| parents: duplicates inside one field kept | 8 |
| protein: wrong table used for genetic code 1 | 2 |
| extract: both sides open when either is clipped | 2 |
| extract: prior openness lost on the unclipped side | 2 |
| reverse: strand forced to minus | 2 |
| check: one row per offending parent | 1 |
| build: only the first bound of each interval kept | 2 |
| extract: an upper bound is required | 1 |
| strand: unknown tokens passed through | 3 |
| build: unnamed intervals pooled into one feature | 2 |
| spliced: the given sequence is ignored | 16 |
| phase taken from the first interval listed | 6 |
| describe: strand omitted | 1 |
| describe: an empty ID written anyway | 2 |
| extract: a merely touching feature is kept | 1 |
| extract: dropped parents still named | 2 |
| extract: surviving parents in coordinate order | 1 |
| cycles: only the first branch walked | 1 |

A probe that emits one `check()` row per offending parent also survived at first, for the same
reason in reverse: the fixture had only one offending parent, so per-feature and per-parent
rows were identical. A second parent breaking the same rule separates them.

A probe that sorted `check()` rows by feature type survived, which looked like a coverage hole
and was not: that fixture's types happen to sort into the same order as its coordinates.
Reversing the feature order instead kills three tests. A surviving mutant is a claim about the
mutant as much as about the suite.

Splicing does not kill the ordering probe, because reverse complementing the ascending join
gives the same string. That is by design: the ordering trap has to surface through the
coordinate mapping, the parts phases and the UTRs instead.

## Test Fairness

| Round | Verdict | Detail |
|---|---|---|
| 1 | FAIL, 13 of 134 unfair | `extract()` and `reverse()` return types unstated, tests read the private `_intervals` list, conversion non-mutation unstated |
| 2 | PASS | prompt names the return types and the non-mutation guarantee, tests use the public `query()`, seven coverage tests added |
| 3 | PASS | four further advisory suggestions taken, five more tests, 146 in total |
| 4 | PASS | five further suggestions taken, seven more tests, 153 in total; one exposed an ambiguous `sibling_overlap` wording, since fixed |
| 5 | PASS | three further suggestions taken, eight more tests, 161 in total |
| 6 | PASS | three further suggestions taken; one exposed a solution defect, `reverse()` dropping bound openness, since fixed; eight more tests, 169 in total |
| 7 | not re-run | `coding()` cut for the 870-word description ceiling, taking nine tests with it; 159 in total |
| 8 | PASS | three further suggestions taken; merging had never stated what it does to the openness it swallows, so the prompt now says; four more tests, 163 in total |
| 9 | FAIL, 50 of 175 unfair | every flag was one cause: the tests pinned tuple containers on the new composite values, which the prompt never specifies and `Interval.bounds` contradicts. Fixed by normalising containers in the tests, not by spending words on nine type declarations |
| 10 | PASS | two suggestions taken; both were prompt gaps, the `Parent` union across the intervals of one feature and `reverse()` on an unbounded model, now stated and tested; three more tests, 166 in total |
| 11 | PASS | three suggestions taken; cross-feature report ordering, derived records skipping unnamed features, and a minus-strand translation with both a phase and a remainder; three more tests, 169 in total |

## Solution Quality

| Round | Verdict | Detail |
|---|---|---|
| 1 | PASS, 2/3 and 2/3 | strand agreement compared before normalisation, so "+" and "." under one identifier were rejected; and the builder read `IntervalMetadata._intervals`. Both fixed, two tests and two probes added |

## Auto Review, batch 2 (10 runs, 2 passed = 20 percent)

Two independent Auto Review reports, both Revision Requested, both scoring Tests 3/3 and
Solution 3/3 and Description 2/3, and both asking for the same two things.

| Ask | Runs affected | Action |
|---|---|---|
| `cds_outside_exon` never said what happens when a `CDS` has no sibling exon; seven runs read the empty set as non-containment and reported the problem | 7 of 8 failures | the clause now ends "reported only where it has some", and a discriminating pair of tests pins both sides |
| the contract was ten dense prose paragraphs, hard to scan | presentation | regrouped into an opening paragraph and five bulleted sections: building, the feature, reading the sequence, `summary()`, `check()`, writing back out |

Other run misses named by the review were finite extraction from an unbounded model (3),
phase propagation across clipped or minus-strand spans (3), and treating unparented roots as
siblings (2). All three are already stated and already covered by tests, so they stay as
difficulty rather than becoming clarifications.

Pass rate is 2 of 10, inside the 40 percent ceiling and above the zero-pass floor, so the
three prompt defects that batch 1 exposed are confirmed fixed.

## Per-agent runs

### Batch 1 (4x Nova, artifacts in `agent-runs(15)/`) — 0 of 4 passed

| Agent | Evaluator | Verdict | New tests | Failed tests | Approach |
|---|---|---|---|---|---|
| Nova 1 | Nova | FAIL_MISSED_REQUIREMENT | 145/192 | phase family, check ordering, openness, reversal | own model, own interval class, recursive descendant spans |
| Nova 2 | Nova | FAIL_MISSED_REQUIREMENT | 162/192 | parents order, spans recursion, minus-strand splice, derived | close to the reference, recursive spans |
| Nova 3 | Nova | FAIL_MISSED_REQUIREMENT | 170/192 | `parents` ordered alphabetically | essentially the reference design |
| Nova 4 | Nova | FAIL_MISSED_REQUIREMENT | 161/192 | spans recursion, minus-strand splice, derived, phase conflict | recursive spans, transcription-order splice |

Baseline stayed green in all four (887 passed). No environment blocker: every evaluator
reported `blocker_type: none` and `agent_blame_unfair: false`.

### What the batch actually measured

Three failures were shared by 2 or more runs, which is the signature of a prompt defect
rather than difficulty.

| Cluster | Runs | Cause | Verdict |
|---|---|---|---|
| minus-strand `spliced` | 3/4 | the prompt said the spans are joined "in that order", meaning transcription order, and then reverse complemented. Doing both reverses twice. The reference joins ascending and then reverse complements | **prompt defect, mine** |
| `parents` ordering | 3/4 | "Listed features run by ..." did not name the attributes it governs, so agents ordered `parents` alphabetically to match the two identifier strings | **prompt defect, mine** |
| `spans` from descendants | 2/4 | "the bounds of its children" read as all descendants | **prompt defect, mine** |

All three are now stated: the spans are joined "by ascending coordinate"; the ordering rule
names "`roots`, `parents`, `children` and every other listing"; and spans come from the
"direct children".

### Solvability evidence

Nova 3 was replayed against the current suite and reaches 170/192. A seven-line adapter that
changes nothing but the order of `feature.parents` takes it to **192/192**, so the whole gap
in that run was the wording. With the ordering rule stated, that run is a pass, which puts the
task above the zero-pass floor.

Projecting the other three from their replays: Nova 2's nine failures all fall inside the
three fixed clusters, Nova 4 keeps two failures outside them (`phase_conflict` and report
ordering), and Nova 1 keeps most of its twenty-six. A second batch is needed to confirm, and
if it lands above the 40 percent ceiling the answer is more interdependent traps, never
restoring an ambiguity.

### Corners left undefined on purpose

Three inputs were probed and deliberately left untested, because the prompt does not define
them and a test would pin an author's choice rather than a requirement.

| Input | What the reference happens to do | Why no test |
|---|---|---|
| `Parent` with an empty component, `"m1,,m1"` | `ValueError`, the empty name is an unknown parent | stripping empty components is an equally reasonable reading |
| an interval with no `type` | `type` is `None` | the prompt never mentions a missing type |
| an explicit sequence shorter than the feature | ordinary slicing, so a short result | the prompt defines the missing-sequence error, not an undersized one |

Defining any of them costs prompt words the ceiling has no room for, and none of them carries
biological meaning. Leaving them undefined is safe: an implementation that raises where the
reference clamps fails no test either way.

### A standing conflict between two checks

The FP panel requires the deep-cycle case, because a recursive walk raises `RecursionError`
instead of the promised `ValueError` and passes undeservedly. Test Fairness flags the same case
as an unstated scale requirement. Reducing the fixture satisfies fairness and reopens the FP;
stating the depth expectation in the prompt satisfies both, and is what was done. If a later
review asks for the tests to shrink instead, it should be contested with this note, not
actioned.

### FP check — batch 3, two more flags, both closed

Both concern `phase_conflict`, and again the reference already answers correctly; the suite was
what let a wrong implementation through.

| Flag | Agent behaviour | Reference behaviour | Why the suite missed it |
|---|---|---|---|
| touching fragments that merge | keeps every absorbed fragment's stated phase and compares each against the single computed phase of the merged span, so `(0,4)@0` plus `(4,6)@2` is flagged | the stated phase of a bound that no longer exists after merging is simply not compared | `check()` was never called on a feature whose fragments merge |
| three or more spans | recomputes the expected phase from the previous span's length instead of all preceding lengths | `parts` accumulates, and `check()` compares against it | every `phase_conflict` fixture had at most two spans, where the two arithmetics agree |

Closed by three tests: the touching pair reporting nothing, a three-span feature whose stated
phases follow cumulatively reporting nothing, and the same feature with a wrong third phase
reporting exactly one `phase_conflict`. The two agent shapes reproduced as mutants kill 1 and
3 tests respectively; the second is caught only by the new three-span cases, which is the gap
itself.

### FP check — batch 2, two flags, both closed

The second batch produced passes, so the FP check finally ran. It flagged two, and the panel
confirmed both. Neither was a defect in the solution: the reference already answers correctly
in both cases. Both were holes in the suite, which let an agent pass without meeting a stated
requirement.

| Flag | Agent behaviour | Reference behaviour | Why the suite missed it |
|---|---|---|---|
| deep parent cycle | recursive cycle walk, so a 1100-feature ring raises `RecursionError`, which is not a `ValueError` | iterative stack, raises `ValueError` at any depth | every cycle fixture was two or three features deep |
| `extract()` phase across a dropped span | subtracts only the bases lost inside the surviving span, so a fully dropped earlier `CDS` span is never counted | per-part phases already carry the preceding spans, so the loss is counted | every extraction fixture clipped inside the first transcription span |

Closed by four tests: a 1100-feature cycle rejected with `ValueError`, a 1100-feature acyclic
chain still accepted, and a `CDS` whose earlier span is dropped entirely by the extraction on
both strands. Reproduced as mutants first: a recursive cycle walk and a phase loss taken from
the feature instead of the part. The first kills 1 test, the second kills 5.
