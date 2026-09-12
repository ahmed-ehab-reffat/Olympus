# feedback — sparse-region-analysis

## Summary

Olympus submission on [pydata/sparse](https://github.com/pydata/sparse) at
`99b89dfcf9bc7d34ec81e2add5556d74229607c1`. Adds a `sparse.regions` namespace: connected
region labelling for N-d sparse arrays plus the analysis and morphology routines that ride on
the same neighbourhood model.

- 515 human-effective LOC across 5 files (3 new, 2 modified)
- 263 new tests, all failing on base, all passing with the solution
- Vanilla repo suite: 6090 passed offline, unchanged by the solution

## Why this pick

The repo has no connectivity machinery at all, and the answer cannot be composed out of what
it ships: `sparse` has arithmetic, reductions, indexing and `sort`, none of which relate cells
to their neighbours. The description states shapes far larger than memory, which rules out the
one shortcut a solver would otherwise take (densify and call `scipy.ndimage`).

## Design decisions worth recording

- **The namespace stays out of `sparse.__all__`.** `sparse/numba_backend/tests/test_namespace.py`
  asserts `set(sparse.__all__) == <array API set>` exactly, so exporting the new names there
  would break an existing test. `sparse.regions` is reached as an attribute instead, which
  also reads like `scipy.ndimage` beside `scipy`.
- **Fill value zero is required.** With a non-zero fill value nearly every position of a
  sparse array is a cell, so the region view is meaningless. The repo already ships
  `check_zero_fill_value` for exactly this class of operation, so the rule has precedent and
  the error message is the repo's own.
- **Stored zeros are not cells.** A COO may carry explicit zeros, so cell detection filters on
  the data, not on `coords`. This is the cheapest trap in the set and the most defensible: the
  description says a cell is a position whose value is not zero.
- **Three separate tie rules** (smallest first index for a window, smallest region number for a
  contested position, first position in row major order for a maximum). Each is stated, each
  needs a symmetric input to show, and none of them can be inferred from the others.

## Iteration history

1. Scoped the feature at 7 routines. Hook measured 279 human-effective, well under the floor.
2. Added `region_maxima`, `region_centroids`, `filter_regions` and the `equal_values` option
   for `label`: 338.
3. Added `grow_labels` (level by level multi source expansion with a tie rule): 385.
4. Added `border_distance` (peeling, plus the degenerate fully wrapped case): 417.
5. Added `region_perimeters`: 433. Stopped there; every addition is a distinct behaviour with
   its own logic, not breadth over one pattern.

Eight of my own test expectations were wrong on the first run and were corrected against the
brute force oracle, not against the implementation. Two of them (the diamond versus square
shape of a two step dilation, and which axis of the seam fixture wraps) were genuine
misreadings on my part, which is a fair signal that the same points will catch solvers.

## Validation

See `DESIGN.md` section 11. In short: differential fuzz against an independent dense oracle
with zero mismatches, a 24 probe mutation battery with 23 direct kills (the one survivor is
behaviour preserving and their combination is killed), a false positive check where a second
implementation written from `meta.md` alone passes 99 of 99 non-scale tests, and both patch
application orders verified.

## Known deviation

`meta.md` is 493 words. The 500 word cap is respected but the recommended 200 word band is
not: the contract names 13 entry points and their return shapes, and trimming further would
delete a described-and-tested behaviour. Precedent for the overage is in
`DESCRIPTION.md` (241 word `pest-unused-rule-elim`) and the 309 word approved
`dasel-aggregation-functions`.

## Test fairness pass (post-build)

An automated fairness review flagged 15 tests. Both classes were real and are fixed:

- **Fourteen negative tests matched on error message text** that neither the description nor a
  repo convention fixes. The `match=` regexes are gone; each negative test now asserts the
  exception class only and is anchored by a valid call of the same argument in the same test,
  so it still cannot pass on base and cannot be satisfied by a blanket raise. The two tests
  matching `zero fill value` stay, because that string comes from the repo's own
  `check_zero_fill_value`.
- **The huge-shape test read `.data` off the returned array**, which pins a storage
  representation the description does not promise (a DOK carries a dict there). It now asserts
  `nnz` and `sum()`, both public and neither of which densifies.

The three advisory coverage suggestions were taken as well: validation on a non-`label`
routine (`dilate` connectivity, `region_perimeters` wrap), `filter_regions(min_count=0)`, and
huge-shape coverage for `region_perimeters` and `region_adjacency`. 101 tests became 104.

## Coverage pass (post-fairness)

A second advisory review suggested four coverage areas; all four were taken, 104 tests became
114. One of them needed a description change first: `region_maxima` shape and cell agreement
was only stated inside the `region_sums` sentence, so asserting it for `region_maxima` would
have pinned an unstated requirement. The clause now reads as a rule about any routine that
takes both `x` and a labelling, and the two new tests sit on stated ground. The other three
(validation on more label-consuming routines including negative and all-zero labellings,
GCXS and DOK inputs beyond `label`, and huge-shape coverage for `erode`, `region_maxima`,
`region_centroids` and `filter_regions`) only exercise behaviour the description already
carried.

## Second coverage pass

A third advisory round asked for validation consistency across every labelling consumer,
non-zero fill rejection on the routines that take `x`, non-integral count rejection, and empty
outputs for the remaining summaries. All four were taken, 114 tests became 131, written as
explicit tests rather than parametrised ones so every behaviour keeps its own F2P node.

The count typing suggestion needed a description change again: the contract said only that a
negative count raises, so pinning `iterations=1.5` would have been an unstated requirement. It
now reads "a count that is not a non-negative integer", which matches how `connectivity` was
already specified as an integer. meta.md is 497 words.

## Third coverage pass

Five more advisory suggestions, all taken, 131 tests became 137. None needed a description
change; each probes behaviour already stated, and all five passed against the reference on the
first run, so they confirm rather than fix:

- a region holding only negative values (no zero-initialised maximum) with the row major tie
  rule checked there too
- `region_sums` promotion for `int8` and `uint8`, beside the existing boolean and float32 cases
- perimeters at a connectivity above the one the labelling was built at, where the diagonal
  neighbour is a cell of a *different* region; the counts are 7 and 7, not 8 and 8, which is
  the discriminator that the membership test spans the whole labelling
- `border_distance` at connectivity 2 through a diagonal hole, where the distance at `(2, 2)`
  drops from 2 to 1
- a scalar `wrap=1`, the twin of the existing per-axis dtype check

## Second fairness pass

A fairness review flagged nine tests that unpack `filter_regions` as
`(filtered_labels, survivor_count)`. The finding is right: `label` says it returns the region
count and `grow_labels` says it leaves the count alone, but the `filter_regions` sentence said
only that it drops and renumbers, so the second return value was an unstated API choice. The
sentence now ends "and reports how many survive", which puts the tuple on stated ground; the
tests are unchanged. Word budget was recovered by tightening four other clauses, so meta.md is
496 words.

The three advisory suggestions from the same round were taken as well, 137 tests became 146:
connectivity and wrap validation on `region_bounds`, `region_centroids`, `region_adjacency`,
`grow_labels` and `border_distance`; mixed per-axis wrap for `dilate` and `erode`; and
`equal_values` over float and boolean values.

## Fourth coverage pass

146 tests became 157. Two of the three suggestions were taken in full:

- the remaining labelling validation combinations (non-zero fill on `region_bounds`,
  `region_centroids`, `filter_regions` and `grow_labels`; gapped or non-integer labellings on
  the four routines that lacked them)
- a wrapped centroid whose window start is tied, which is the only case that separates the
  stated smallest-start rule from an arbitrary tied start: the region holding columns 0 and 2
  of a wrapped length-4 axis has centroid 1.0 from start 0, and 3.0 from the equally short
  window starting at 2
- an axis of length zero, which carries no cells and therefore no regions, checked through
  `label`, `region_counts`, `region_bounds`, `dilate`, `border_distance`, `grow_labels` and
  `filter_regions`

**Zero-rank input was deliberately left out.** The description never contemplates a scalar
array, and the observed rejection is not the one the suggestion has in mind: for
`sparse.COO.from_numpy(np.array(5))` the fill value is 5, so the zero fill check fires before
the rank check ever runs. A test written against that input would assert the right exception
for the wrong reason, and the honest version (`sparse.zeros(())`, which does reach the rank
check) would pin behaviour on a shape no sentence in the description covers. Adding it would
mean spending words from a 496 word budget on a case no solver can be expected to infer.

## Fifth coverage pass, and a solution change

157 tests became 167, and this round changed the solution rather than only the tests.

**Rank zero.** I skipped this last round because the rejection could not be tested honestly.
Re-examining it, the reason was a real inconsistency: `label`, `dilate`, `erode` and
`border_distance` rejected a scalar array through the connectivity range, but the routines
that take only a labelling never looked at the rank, so an integer `sparse.zeros(())` would
have slipped through them. The rank guard now lives in one helper called from
`normalize_connectivity`, `cells_of` and `label_cells`, so every entry point refuses an array
with no axes for the same reason. meta.md gained "An array with no axes is rejected." and lost
seven words elsewhere to stay inside the cap at 497.

**Wrapped array with a hole.** `border_distance` raises only when erosion removes nothing, not
whenever every axis wraps, and the new test pins the difference: a fully wrapped 3x3 with one
hole measures to `[[2,1,2],[1,0,1],[2,1,2]]`.

**Option validation** now covers every option on every routine that takes one: `dilate` wrap,
`erode` connectivity and wrap, `border_distance` wrap, `grow_labels` wrap,
`region_perimeters` connectivity, `region_adjacency` wrap.

The differential fuzz was re-run after the solution change (0 mismatches), the effective LOC
moved from 433 to 437, and every other gate was re-run from scratch.

## Sixth coverage pass

167 tests became 175, no description or solution change needed; both suggestions asked for
assertions on rules already stated and already implemented.

- the no-axis rejection is now asserted on every remaining entry point: `erode`,
  `region_sums`, `region_maxima`, `region_centroids`, `region_perimeters`,
  `region_adjacency` and `filter_regions`, which together with the earlier round covers all
  thirteen
- every array-returning routine now has its container and background asserted, not just its
  values: `label` and `dilate` are sparse arrays, `erode` carries a False fill, and
  `border_distance`, `grow_labels` and `filter_regions` carry a zero fill with an integer
  dtype and the input shape

## Second fairness pass, and a rebuilt harness

The fairness review flagged one assertion: `border_distance` was required to return an
integer-kind dtype. That is right and it is now removed. `label`, `grow_labels` and
`filter_regions` may keep their integer dtype assertions because the description requires a
labelling to hold integers; `border_distance` returns step counts with no stated dtype, so a
float array holding exact integral distances would have satisfied the contract and failed the
test. The exact distance values are asserted elsewhere, so nothing about the semantics is lost.

While validating that change the machine's `/tmp` was cleared, taking the virtualenv, the
brute-force oracle, the fuzz driver, the mutation battery and the false-positive
implementation with it. Rather than report numbers I could no longer reproduce, the whole
verification chain was rebuilt inside the Docker image and re-run from scratch:

- the mutation battery was rewritten with 21 probes instead of the original 16. The first run
  reported 21 of 21 killed, which was wrong: `--network none` had blocked the `pytest-timeout`
  install, so `--timeout=300` was an unrecognised argument and every probe was dying on a
  harness error rather than on a test. With the flag removed the real result is 19 killed and
  2 survivors.
- both survivors (the zero step being included in the neighbour set, and numbering components
  by root rather than by first appearance) were then put through a differential sweep of
  29014 cases covering every routine, rank, connectivity and wrap combination. Both produce
  byte identical output to the reference, so they are null mutations rather than gaps in the
  tests: the union-find already returns the smallest member as the root, and a self-step is
  filtered everywhere it could matter.
- the false-positive implementation was rewritten from meta.md and passes 173 of 173 non-scale
  tests.

The differential fuzz against the dense oracle was not re-run, because the solution has not
changed since the run that reported zero mismatches; only the test file has.

## A real bug, found by a coverage suggestion

The short-wrapped-axis suggestion found a genuine defect in the reference solution, not a
missing test. On a wrapped axis of length two the `+1` and `-1` steps of a cell land on the
SAME position, and `region_perimeters` counted that one neighbouring position twice: a single
cell on a wrapped `(2,)` array reported perimeter 2 where the stated pair count is 1.

- **Fix.** `region_perimeters` now counts off-array steps directly and deduplicates the
  in-array targets per cell before counting, so two steps reaching one position are one pair.
  No other routine is affected: `dilate` already takes a set of positions, `erode` and
  `border_distance` intersect over steps so a repeat is idempotent, `region_adjacency`
  deduplicates its pairs, and `grow_labels` keeps the smallest claim per position.
- **Description.** The rule is now stated: perimeters count "distinct pairs". One word, and
  meta.md sits at 498.
- **Root cause of the miss.** `region_perimeters` was added during the LOC round and was never
  wired into the differential fuzz, and no fixture had an axis shorter than three. The rebuilt
  fuzz now covers every public routine and includes shapes with axes of length 1 and 2: it
  reports 455 mismatches against the pre-fix solution and 0 after it.
- **Battery.** A new probe removes the deduplication and is killed; the probe for counting the
  array edge was re-anchored onto the rewritten code and is still killed. 22 probes, 20 kills,
  the same two null-mutation survivors.

The other two suggestions were taken as written: unsorted and duplicate COO coordinates
(including duplicates that cancel to zero, which is then not a cell), and DOK or GCXS
labellings through bounds, centroids, perimeters, adjacency, growth and filtering.

## Seventh coverage pass

189 tests became 207. Nothing needed a description or solution change.

- **Validation matrix completed.** Every routine that takes `connectivity` now has both a
  range and a type check, and every routine that takes `wrap` now has both a wrong-length and
  a non-boolean check, so no rule is sampled on one routine and assumed on the rest. Written
  as explicit tests rather than the suggested parametrised form, because a parametrised node
  does not give each behaviour its own name in the F2P report.
- **Support comparison is semantic.** Three cases where the raw stored coordinates of `x` and
  the labelling differ while their cells agree: a stored zero in `x` only, the same for
  `region_maxima`, and a stored zero in the labelling only. All are accepted and produce the
  ordinary answers, which is what "agree on which positions are cells" means once a stored
  zero is not a cell.

One assertion of mine was wrong on the first run again (dilating BLOCK at connectivity 1 fills
the whole 3x3, `nnz` 9 not 8); corrected against the observed value.

## Eighth coverage pass, and a conflict between the two review streams

207 tests became 216.

**The border-distance dtype.** The coverage check asked for the integer dtype assertion that
the fairness check had made me delete two rounds earlier. The two streams disagreed because
the contract was incomplete, so the contract was completed rather than one reviewer ignored:
`border_distance` now "holds the integer steps", the assertion is back, and it rests on a
stated rule. The word was paid for by shortening the no-dense clause to "no routine may
densify", which leaves meta.md at 496, two words below where it started this round.

**Two-input formats.** `region_maxima` now has a GCXS value array and a DOK labelling.

**Label validity.** Six more combinations, so every label-consuming routine now rejects a
non-zero fill and at least one structural invalidity of its own. The full cross product of
four invalidity classes over nine routines was NOT written: the validation lives in a single
helper, a mutation probe that disables it is killed, and thirty-six near-identical tests would
be the repetitive breadth the LOC counter discounts and a reviewer reads as padding. The
suggestion's own remedy, a parametrised test, is unavailable here because a parametrised node
does not carry its behaviour's name into the F2P report.

## Ninth coverage pass

216 tests became 219. Both suggestions were symmetry gaps in the suite rather than gaps in the
behaviour, and both passed against the reference on the first run:

- `region_maxima` with a stored zero in the labelling only, the mirror of the `region_sums`
  case, so both value routines are shown to compare cells rather than stored coordinates
- `erode` on a positive-shape array with no cells, at one and three rounds and at
  connectivity 2, which keeps the empty case off the zero-length-axis test that was carrying
  it by proxy

Nothing in the description or the solution changed. meta.md stays at 496 words.

## Tenth coverage pass

219 tests became 224. All three suggestions named a plausible failure mode, all three were
probed before a test was written, and all three found the reference already correct:

- **A wrapped axis of length zero.** The modulo-by-zero worry is real in principle; in
  practice an axis of length zero leaves no cells, so the stepping code runs on empty
  coordinate arrays. Probed under `-W error::RuntimeWarning` to be sure nothing was being
  swallowed, then covered for `label`, `region_bounds`, `region_centroids`, `dilate`, `erode`
  and `border_distance`.
- **A growth tie across the seam.** Two seeds on a wrapped length-4 axis leave position 3
  equidistant from both, reached from region 1 only by wrapping. The result is `[1,1,2,1]`
  against `[1,1,2,2]` unwrapped, so the test separates the tie rule from the seam rather than
  covering each alone.
- **Diagonal off-end perimeters.** A corner cell at connectivity 2 has five distinct positions
  beyond the array and three empty neighbours inside it, so its perimeter is 8 against 4 at
  connectivity 1, and a solid 3x3 comes to 32. Distinct off-end steps reach distinct positions,
  so they are counted separately, which is the opposite of the deduplication a short wrapped
  axis needs.

Nothing in the description or the solution changed. meta.md stays at 496 words.

## Quality-check pass: error wording

The quality check warned that thirteen tests matched the substring "zero fill value", which the
description does not mandate. It offered two remedies: relax the tests, or document the exact
wording in the description. The tests are relaxed.

Documenting the wording was the wrong remedy here. Naming an error string in the prompt makes
the contract prescriptive about a message rather than behavioural, and it would spend words
from a 496 word budget on something no solver should have to reproduce character for character.
The earlier fairness pass had rated these same matches acceptable because the string comes from
the repository's own `check_zero_fill_value` helper, so the two reviewers disagreed; relaxing
satisfies both, since neither requires the match to exist.

Each of those tests now asserts only the exception class, and the ten that had no positive
control gained one, so a blanket raise still cannot satisfy them and they still fail on base for
the right reason.

The fill value assertions were kept. `label` is specified to hold "the region number of every
cell and zero elsewhere", `grow_labels` and `filter_regions` return labellings by the same rule,
and `dilate` and `erode` are specified to return a boolean array "true at every position within
`iterations` neighbour steps", which leaves false as the only reading elsewhere. These are
consequences of the stated contract rather than implementation details, and the fairness pass
classified them the same way.

## Alignment pass: the grow_labels return

The alignment check flagged that `grow_labels` was described as leaving "the count alone"
without saying it returns one, while the tests unpack `(grown_labels, count)`. Same class as
the `filter_regions` finding an earlier fairness pass raised, and fixed the same way: the
sentence now ends "returns the widened labelling with the count unchanged", which states both
halves of the return. Three other clauses were tightened to pay for it, so meta.md is 496
words, where it started the round.

No test or solution changed, so only the checks that read the description were re-run: the
false-positive implementation still passes 222 of 222 non-scale tests, and the suite still
passes 224. The description now names a return value for every routine that has one.

## Eleventh coverage pass, and a correction to an earlier claim

224 tests became 229, and one of the new tests killed a mutant I had previously reported as
harmless.

- **Support mismatch in the other direction.** The existing fixtures gave `x` fewer cells than
  the labelling; `region_sums` and `region_maxima` now also reject a value array carrying an
  extra cell, so the equality is tested both ways.
- **Renumbering an externally supplied labelling.** A caller may pass a valid labelling whose
  numbers are not in first cell order, such as `[2, 2, 0, 1]`. Filtering it renumbers by first
  cell, so the survivors come back as `[1, 1, 0, 2]`, and dropping the single cell region
  leaves `[1, 1, 0, 0]`. The same fixture pins two neighbouring rules that are easy to confuse:
  `region_counts` indexes by region NUMBER and returns `[1, 2]`, while `grow_labels` keeps the
  numbers it was given and returns `[2, 2, 1, 1]`.

**The correction.** P15, the probe that numbers components by union-find root instead of by
first cell, was reported in an earlier round as a null mutation on the strength of a 29014 case
differential sweep. That was wrong, and the sweep is why: every labelling in it came from
`label`, where the union-find root IS the smallest member, so the two rules coincide by
construction. `filter_regions` on a caller supplied out-of-order labelling is the case that
separates them, and the sweep never produced one. With the new test present P15 is killed, so
the battery is 23 probes, 22 kills, and the single remaining survivor (the self step in the
neighbour set) was re-checked against the sweep and is still byte identical.

The lesson is worth keeping: a differential sweep only proves equivalence over the inputs it
actually generates, and a sweep whose fixtures all come from one constructor cannot see rules
that only diverge on hand built input.

## Third fairness pass: structured output shapes and storage counts

Five findings, in two families, both real.

**Four were the same gap.** `region_maxima`, `region_bounds`, `region_centroids` and
`region_adjacency` return structured results whose CONTENT the description pinned but whose
SHAPE it never did, so a solver could satisfy every stated rule with per-region records or
separate start and length arrays and still fail. The description now names the shape of each:
a `(count, rank)` position array for maxima, a `(count, rank, 2)` array of first index and
length for bounds, a `(count, rank)` array for centroids, and a `(k, 2)` array for adjacency.
Nine other clauses were tightened to pay for it, so meta.md came DOWN from 496 to 493 words.
This is my own recorded lesson about documenting the return shape of every entry point, and I
had applied it to `label`, `grow_labels` and `filter_regions` but not to the four routines that
return plain arrays.

**The fifth was a genuine disagreement between two passes.** Thirty-four assertions used
`.nnz`, which counts STORED entries. The first fairness pass read that as fair, calling it a
check on canonical representation; this pass points out that the repository deliberately
permits non-canonical arrays (`prune=False` is the COO default, and `test_coo.py` keeps an
unpruned stored-zero array as a valid, semantically equal object). The second reading is the
right one: nothing in the description forbids an implementation from storing a fill value, so
an equivalent result could fail. All thirty-four now go through a `live()` helper that counts
effective non-fill entries, which is storage independent. Verified directly: an input stored
with `nnz` 3 but only two effective non-zeros reports `live` 2 both before and after labelling.

The huge-shape assertions still hold, because comparing a sparse array against its own fill
value stays sparse and never densifies.

## Batch 1 response: an unfair spec bug and a too-easy verdict

The first Nova batch came back 3/5 pass with both failures unfair, so both axes needed work.

**The unfair half.** Nova 4 and Nova 5 returned sparse arrays from the per-region summaries
and lost 62 tests each to `Cannot convert a sparse array to dense automatically`. They were
right and I was wrong: "returned arrays are sparse and shaped alike" states a rule about every
return, and the summaries are numpy. The sentence now reads "Results shaped like the input are
sparse; the per-region summaries are numpy arrays." Nothing about the tests changed, because
the tests were always asserting the intended contract.

**The too-easy half.** Eleven rounds of fairness clarification had turned the description into
a complete recipe, which is exactly the failure mode my own notes call the specified-feature
ceiling: every ambiguity I closed also removed a trap.

My first hardening idea was scale. I built a 300k cell fixture and MEASURED the three passing
solutions against it before writing a single test: they complete every routine in 10 to 15
seconds against my 1 second, so a cell-count test would have added runtime and no difficulty.
Dropped.

What went in instead is `merge_within(labels, distance, ...)`, which joins regions whose cells
lie within `distance` steps of each other, transitively, and renumbers by the same first-cell
rule. It earns its place because the naive readings are wrong or hopeless: dilating each region
separately and testing pairs is quadratic in the region count, and the natural single-pass
version has a parity bug, since expanding a front by one step every round reaches distance
`d`, `d-2`, `d-4` and so on, so a gap of 2 under a distance of 3 is invisible unless every
round is checked. That mutation (P25) is in the battery and is killed by two tests.

**A trap I thought I had, and did not.** I expected the front to need every (position, region)
pair rather than one region per position, and wrote a probe for it. The probe survived. Rather
than call it a test gap I ran the mutant against the dense oracle over the whole sweep: zero
mismatches. It is an equivalent mutant, because a region close enough to shadow another
region's front is close enough to merge with it anyway. The probe was removed rather than
left in as a false trap.

Effective LOC rose from 452 to 515. The pass rate for batch 2 is not something I can predict
from here; the batch is the only oracle.

## Coverage pass after batch 1

247 tests became 257, all four suggestions taken.

- **The stated cell-count scale is now tested.** Two cases build 200000 cells in a
  `(100000, 100000, 100000)` shape as 100000 separated two-cell regions, and every number is
  derivable from the fixture: 100000 regions of two cells, sums 200000, perimeters 1000000
  (ten exposed sides per domino), dilation 1200000 (twelve positions per domino, none of them
  shared because the spacing exceeds the reach), every border distance 1, and no merging at
  distance 1. This does not add difficulty, which I measured before adding it, but it does
  enforce a clause that was previously stated and unchecked, and it fails any implementation
  that densifies or goes quadratic.
- **`merge_within` validation parity**: non-zero fill, floating and negative labellings,
  non-boolean wrap in both forms, and connectivity below one or non-integer.
- **`merge_within` at huge shape**, added to the existing three-cell integration test.
- **`merge_within` output dtype**, alongside the sparse type, zero fill and shape it already had.

Suite runtime with the scale cases is 3.1 seconds for the reference; the three batch-1
solutions took 10 to 15 seconds per routine at this size, so a correct but slower solution
still finishes comfortably.

## Coverage pass: the summary type contract

257 tests became 263. The first suggestion is the one this submission most needed, because it
asserts the exact clause whose absence cost two runs in batch 1. `region_counts`,
`region_sums`, both `region_maxima` outputs, `region_bounds`, `region_centroids`,
`region_perimeters` and `region_adjacency` are now each asserted to be a `numpy.ndarray` and
NOT a `sparse.SparseArray`. Until now the suite only constrained their values, shapes and
dtypes, which a sparse result can satisfy right up to the point where `assert_array_equal`
refuses to densify it. The contract sentence and the tests that enforce it now line up.

`merge_within` also gained the GCXS and DOK integration checks every other labelling consumer
already had.

## Quality pass: runner robustness

The quality check raised two robustness points on `test.sh` and the scale tests.

**The xdist dependency was a real portability bug.** Base mode ran `pytest ... -n 4`
unconditionally, so the runner would have died with an unrecognised argument in any image
without pytest-xdist, even though nothing about the submission needs parallelism. The flag is
now taken only when the plugin imports:

    PARALLEL=""
    if python -c "import xdist" >/dev/null 2>&1; then
      PARALLEL="-n 4"
    fi

Verified both ways in the image: with the plugin, 6090 passed in 87s; with the plugin
uninstalled, the same 6090 passed in 153s. The Dockerfile still installs it, so the shipped
environment keeps the fast path, but the script no longer depends on it.

**The scale tests were measured rather than trimmed.** Peak RSS for the whole new suite is
430 MB and it finishes in 4.4 seconds, so the largest intermediate (1.2M dilated positions) is
not a memory risk worth trading a stated requirement for. The description commits to cells
reaching the hundreds of thousands, and dropping to a smaller fixture would leave that clause
unchecked again. Recorded here so a reviewer can see the number instead of the worry.
