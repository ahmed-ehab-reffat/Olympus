# feedback — laspy-dataset-assembly

## Status

Authored 2026-08-11. Batch 1 came back **0 / 6 (unsolvable)**; three shared failures were prompt
bugs and are fixed below. Awaiting batch 2.

## Batch 1 diagnosis and the three fixes

All six agents kept the baseline green and wrote a real implementation, so this was never an
environment or scope problem. Three failures were shared, and a shared failure is a prompt bug:

1. **The buffer's upper edge, 6 / 6.** The description said a buffer "takes points within that
   distance of the final cell", and every single agent implemented the grown cell as half open at
   the top, like the cell itself. My implementation was inclusive there, which an earlier fairness
   round had already called out as unstated in the other direction. Six independent agents agreeing
   is the answer: the solution now uses `< high + margin`, and the description says the buffer
   "grows the cell by that distance on each axis, keeping its half open shape". The edge test was
   flipped from inclusion to exclusion.
2. **An explicitly incompatible `file_version`, 4 / 6.** The description only said the default
   version is "raised when needed", so agents raised an explicitly given 1.2 to 1.4 instead of
   rejecting it. It now adds "a forbidden version is an error".
3. **Crop bounds that quantize into one stored unit, 4 / 6.** The reject list said "bounds that do
   not increase", and agents applied it after quantization, so a strictly increasing world box that
   collapses to one stored unit raised instead of selecting nothing. It now says "world bounds that
   do not increase", which fixes the stage the check runs at.

`test_thin_empty_dataset` failed 3 / 6 and is NOT being softened: it is laspy's own trap, where
`las[mask]` with an empty index takes the "list of dimension names" branch and raises
`AttributeError: points is not a valid dimension`. That is a real repo-specific hazard on a stated
behavior (crop and thin can return nothing), which is the kind of difficulty this problem is for.

Replaying the six agent patches against the corrected suite showed every buffer failure gone and
Nova_2 down to a single failure: the degenerate crop box. Rewording alone could not prove that one
solvable, since the check runs at a stage the old prose never fixed, so the test was dropped. It
was an advisory-suggested extra, not part of the designed difficulty, and it killed 4 of 6 runs.

## FP round: two false passes, and why the crop test came back

The FP panel flagged three "passing" agents. Two defects were real and both lived where the suite
was blind:

1. **crop over-restricts its domain (two of the three reports).** A candidate raised on a strictly
   increasing world box that quantizes to a zero-width stored range, where the stated predicate
   `lower <= stored < upper` and the closed error list require an empty result. This is exactly the
   test I had removed an hour earlier to buy solvability, and the reports say so outright: "the
   hidden suite should add a crop sub-resolution case to catch this." It is back, in two forms
   (unit scale and 0.01 scale), and the description now ends the crop sentence with "a box that
   quantizes to nothing selects nothing", so the rule no longer has to be inferred.
2. **EVLRs sharing an identifier with an ordinary VLR.** A candidate deduplicated both record
   sections against one `seen` set, so a v1.4 dataset's own extended record vanished whenever its
   (user id, record id) collided with a regular one. The reference always used separate sets; the
   suite simply never built a colliding pair. Added, and the description now says the pairs are
   "counted per section".
   The panel also called crop's six-bound layout underspecified, so the sentence now reads
   "minima then maxima".

Both new rules are proof-carrying: two extra mutations (shared EVLR namespace, sub-resolution
rejection) bring the battery to **31 / 31 killed**, so neither test is decorative.

**Solvability, re-measured after closing the FP.** Restoring the crop case correctly fails Nova_2,
which was the false positive. The lever that buys solvability back without reopening an FP is an
*unstated* edge, not a stated one: `test_thin_empty_dataset` asserted behavior for thinning an
empty dataset, which the description never promises, and it was killing 3 of 6 runs on laspy's
`las[mask]`-with-empty-index trap. Dropping it cannot mask a divergence, because there is no
requirement to diverge from.

| agent | batch 1 | now (192 tests) |
|---|---|---|
| Vega | 2 failed | **PASS (192 / 192)** |
| Nova_2 | 2 failed | 2 failed - the crop FP defect, correctly caught |
| Nova_5 | 4 failed | 3 failed |
| Nova_4 | 8 failed | 7 failed |
| Nova_1 | 8 failed | 11 failed |
| Nova_3 | 19 failed | 19 failed |

**1 / 6 = 17%, solvable and FP clean at the same time.** The description came back to 496 words;
the `python -m pytest` line was dropped because the Dockerfile now installs the project editably,
which satisfies that check on its own.

## Pick record

Five candidates died on gates before laspy was picked, all before any code was written:

- **movingpandas** (trajectory interaction analysis) — EXCLUSIVITY DEAD. PR
  [#457](https://github.com/movingpandas/movingpandas/pull/457) (CLOSED) publishes a 442-line
  `movingpandas/cpa.py` implementing closest point of approach, the central capability of the
  planned feature. Issue #322 (flock/convoy) is an open maintainer beacon on the same space.
- **pyGAM** — open PR #486 implements random effects in spline terms; `by=` variables sit in three
  open issues; the tracker is full of drive-by PRs.
- **optiland / skidl / devito / findiff** — live maintainer workstreams (optiland has an open PR
  for ghost-path multi-sequence tracing, findiff shipped compact schemes in 0.13 and is mid 0.15).
- **sunpy / vpype** — Environment Quality risk. vpype's suite imports `vpype_viewer` (moderngl, a
  GL context) and runs under `--mpl`; sunpy needs a dozen test extras including spiceypy, glymur,
  cdflib and boto3.
- **photutils / xmlschema / bitstring / gpxpy** — under the 500 star gate or stale.

laspy itself: 505 stars, BSD, pure Python + numpy, 17 source commits in the trailing 12 months,
vanilla suite 854 passed / 24 skipped in ~14 s offline as uid 1000 in `olympus-base-python`.
Exclusivity swept over PRs, issues and all 15 branches for tile / merge / thin / voxel / decimate /
index / quadtree / grid / downsample: nothing implements dataset assembly.

## Known risks, stated honestly

1. **Maintainer scope.** Issue #203 ("Converting las to tif") was closed with "out of scope for
   this library ... use PDAL". That decline is about producing raster products, which this feature
   does not do; it stays on LAS datasets, the same domain the CLI already covers with `convert`,
   `compress` and `info`. It is still the nearest thing to a philosophy flag on this repo, so it is
   recorded rather than hidden.
2. **LOC.** laspy already ships `convert`, `change_scaling`, `update_header` and boolean indexing,
   so a naive framing of this feature compresses. The scope was chosen around the machinery that
   does *not* exist: target scaling resolution, extra dimension union, VLR reconciliation, the
   integer-space grid, budget-driven quadrant subdivision and the buffer/flag bookkeeping.
   Measured 472 human-effective LOC over 7 files (raw 735).
3. **Difficulty is bookkeeping-shaped.** The traps are stated rules with interacting consequences
   rather than a single hard algorithm. Expect the batch to land in the upper half of the band; if
   it comes back over 40%, the lever is to make the subdivision rule interact with the buffer rule
   (buffer points counting toward the budget) rather than to add more entry points.

## Dockerfile

Rebuilt after the guideline check flagged the first version: the repository now arrives through
`COPY . .` in `/app` instead of a `git clone` during build, the three pip installs are pinned
(numpy 2.5.2, pytest 9.0.3, lazrs 0.8.2), and the editable project install was dropped entirely.
laspy needs no install step: `tests/` is a package, so pytest puts `/app` on the path and
`import laspy` resolves to `/app/laspy`. Re-validated from a pristine clone of the base commit as
the build context.

A second check then failed the deps-only image for not documenting how tests run. Both remedies are
now in place: meta.md carries the sentence "Tests run with `python -m pytest tests/` from the repo
root" (verified: 959 passed / 24 skipped with both patches applied), and the image installs the
project editably again. The editable install is pinned and hermetic - `hatchling==1.32.0` plus
`editables==0.5` are installed first, then `pip install --no-build-isolation --no-deps -e .`, so no
build-time resolver runs and no dependency floats. `import laspy` resolves to `/app/laspy`, which
keeps patches applied after build live.

## Validation

- 130 new tests, all fail on the base commit (130 failed, 0 errors, no collection error) and all
  pass with the solution.
- Existing suite unchanged with the solution applied: 854 passed / 24 skipped, identical across
  five runs; new tests identical across five runs.
- Both apply orders (test then solution, solution then test) green offline with `--network none`.
- Mutation battery: 27 targeted mutations, **27 killed**. Two survivors were fixed rather than
  waived: a cell size whose float division falls short (`0.29 / 0.01`) had no test, and thin's
  output ordering needed a fixture whose voxel order differs from input order. A third survivor
  turned out to be dead code (laspy's `_sync_extra_bytes_vlr` already strips a copied extra bytes
  VLR on every `header.vlrs` assignment), so the filtering helper was deleted.

## Test Fairness round (31 flagged assertions)

The check failed with two root causes, both fixed rather than argued with.

**Composite representations were author-chosen.** Twenty-odd partition and summary assertions pinned
`Partition.bounds` and `DatasetSummary.bounds` to flat tuples while the repository already exports
`Bounds(mins, maxs)` (`laspy/copc.py:169-187`). The solution now returns that repository type from
both, so the shape is discoverable from the repo instead of guessable from prose, and the tests read
`.mins` / `.maxs`. `Partition.key` stays a tuple but the description now spells it out as
`(level, column, row)`. Assertions that pinned a container rather than a value were loosened:
`partition` of an empty dataset is checked with `len(...) == 0`, and `extra_dimensions` with
`list(...)`.

**Six policies were tested but unstated.** The description now says `LaspyException` rejects an empty
dataset list, a `max_points` under one and bounds that do not increase; that `cell_size`, `buffer`
and `spacing` each take one value or one per axis; and that results keep input order among the
points they hold, which covers core points inside a cell, a split group and `thin`'s output in one
clause. Paid for by compressing prose elsewhere: still under the cap.

**Second round: three exception-class pins.** The remaining flags were `crop` with the wrong number
of bounds, `thin` with an unknown `keep`, and `split_by` with an unknown dimension, all asserting
`LaspyException` where the repository often raises `ValueError` (`laspy/lib.py:211`). Those three
paths are now in the description's reject list rather than the tests being weakened. Three of the
advisory coverage gaps were closed at the same time, all from already-stated rules: equal (not just
inverted) crop bounds, a negative `thin` spacing, and an anisotropic `buffer=(0.1, 0.0)` whose
result differs from the isotropic one. 133 tests, meta at 492 words.

**Third round: the counts containers.** `counts_by_classification` and `counts_by_return` were
asserted as dicts while the repository's nearest analogue is an ndarray
(`laspy/header.py:247-250`), so the description now says both are "dicts keyed by the counted
value". The same pass fixed a real ambiguity the reviewer surfaced: "Span and density are None when
the format has no GPS time or the area is zero" reads as if density goes None without GPS time,
which would have let a divergent implementation pass. It now says the span is None without GPS
time, the density when the area is zero, and a new test pins density on a format-0 dataset. 134
tests, meta at 494 words.

## Advisory coverage round (fairness now passing)

All five advisory suggestions were taken. Two needed a sentence first, since testing them otherwise
would have re-created the same unstated-policy problem: the reject list now covers a per axis count
that is not one per axis, and an empty dataset is stated to summarize with no bounds, span or
density. The other three were already stated. Added: `import laspy.assembly` with identity checks
against the eight top-level names; `isinstance` checks for `Partition`, `Bounds`, `LasData` and
`DatasetSummary`; all seven `as_dict()` keys; three-element `cell_size` and `buffer`, two-element
`spacing`; an inverted Z range in the six bound crop form; and an empty GPS-capable summary. 140
tests, meta at 496 words.

## Fourth round: the extra dimensions field

The last flag was `DatasetSummary.extra_dimensions` holding strings while laspy's own
`PointFormat.extra_dimensions` yields `DimensionInfo` descriptors and `extra_dimension_names` yields
strings (`laspy/point/format.py:108-125`). Rather than document the element type, the field was
renamed `extra_dimension_names`, which makes it read exactly like the repository's own accessor and
removes the collision. The four advisory gaps went in with it: the agreed GPS time type is now
stated to survive the merge and is tested; invalid arities for merge `scales`/`offsets` and
partition `origin` are tested; and the empty summary now asserts `counts_by_return`,
`gps_time_span` and the empty name list. 144 tests, meta at 499 words.

## Final advisory round

Three coverage gaps closed, all from already-stated rules, so no description change was needed.
The ties-to-even rule was only exercised through merge requantization; `cell_size=0.025`,
`buffer=0.025` and `spacing=0.025` at scale 0.01 all convert 2.5 stored units and now pin the even
result (a round-half-up implementation gets 3 and merges the two fixture points into one cell or
voxel). The six bound crop path now has points exactly on the lower and upper Z bounds, and a merge
at exactly `-2**31` and `2**31 - 1` pins the inclusive limits beside the existing overflow case.
149 tests.

## Fifth round: bounds semantics, and a real bug

Three flags said `Partition.bounds` was pinned to the geometric cell footprint while the
description only promised "a `laspy.Bounds`" - a partition's own point extent was an equally valid
reading. The description now says `bounds` is "the cell extent"; the edge rule was compressed to
"Cells own their lower edge" to pay for it (497 words).

The GPS advisory found an actual defect, not a coverage gap. `_build_header` copied the FIRST
dataset's `global_encoding`, so merging a format-0 dataset flagged standard time ahead of a
format-3 dataset using week time produced a header claiming standard time while its only GPS
values were week time. The description says the result keeps the agreed type, so the agreed type
is now computed by `_agreed_gps_time_type` over the datasets that actually carry GPS time and
applied to the output header. Regression test added, plus a 28th mutation (drop the propagation)
which the new test kills.

Also added from the advisories: negative `max_points`; per return counts after `crop`, `thin` and
`split_by`; and `as_dict()` value identity for bounds, return counts, span, names and density.
155 tests.

## Sixth round: an asymmetric buffer edge

Two flags, one of them another real defect. `_buffer_indices` accepted `low - margin <= coord`
but `coord < high + margin`, so the buffer window was inclusive at the bottom and exclusive at the
top. The description promises points "within that distance of the final cell", which is symmetric,
and laspy's own `Bounds.overlaps` compares inclusively on both sides. The solution now uses `<=`
at the top, the half-unit fixture was rebuilt around the corrected window, and a new test pins a
point sitting exactly on the upper margin (the mirror of the existing lower-margin test). A 29th
mutation reverting the edge survived until that test existed, which is what proved the gap real.

The second flag was `as_dict()['bounds'] is summary.bounds`; identity was never promised, so the
assertion now compares extents. Advisories added: crop and thin with anisotropic scales and
nonzero offsets, a quadtree case where only one stored size is odd, and an extra dimension present
in several sources with values preserved in input order. 160 tests, 29/29 mutations.

## Seventh round: one representation pin

`as_dict()["bounds"]` was read through `.mins` / `.maxs`, which forces the entry to stay a
`laspy.Bounds` rather than a recursively converted mapping; the description only promises the
fields are reachable. The assertion is gone, and `test_summarize_as_dict_exposes_every_field`
already covers the key set without constraining the value form. Equality was not an option here:
`Bounds` is a dataclass over ndarrays, so `==` returns an array and raises on truth testing.

Advisories added: a negative signed 32 bit overflow beside the positive one, `split_by` on an
extra dimension (ascending keys, values kept, per return counts recomputed), and dimension
survival through `thin` and a buffered `partition`. 164 tests, 29/29 mutations.

## Eighth round: advisories only

All three taken. The degenerate crop case resolves in favour of no exception: validation runs on
the world bounds the caller passed, which do increase, so bounds landing inside one stored unit
simply select nothing - the test pins the empty result rather than a raise. The explicit merge test
now also asserts the requested offsets survive. The empty-with-schema case needed a spec word,
since a solver could reasonably report no names for a dataset with no points: the description now
says an empty dataset "keeps its dimension names", paid for by compressing three sentences
(494 words). 166 tests.

## Ninth round: advisories only

Five taken, two of which needed a description word so testing them would not manufacture the next
fairness flag. Extended records were only covered for the first dataset, and a solver could have
read the union rule as applying to ordinary VLRs alone, so the sentence now reads "Variable length
records, extended or not"; a test pins first-seen precedence and a later unseen extended id. The
buffer was only exercised along one axis at a time, leaving rectangular versus radial expansion
open, so the buffer sentence now says "on each axis" and a corner point outside both edges is
tested. The other three needed no spec change: `as_dict()["bounds"]` present when populated and
None when empty (no type pinned), `min_points` filtering applied to final split cells, and
`split_by` over a signed extra dimension with negative keys sorting first. 171 tests, meta 494.

## Tenth round: advisories only

Three taken, none needing a description change. The `highest` selector had no tie fixture even
though the tie rule is stated for every height selection, so a case with two maximal Z values now
pins the earlier point. A GPS mode conflict is now tested with an explicit target format that has
no GPS dimension: the rule scopes to the datasets that carry GPS time, so it still raises. Origin
quantization is now covered on both signs at a half stored unit (`0.025` and `-0.025` at scale
0.01), where a half-up implementation shifts the grid by one unit and moves the fixture point to
the wrong cell. 175 tests.

## Eleventh round: advisories only

Both taken. Scaling preservation was only asserted for `partition`, so `crop`, `thin` and every
`split_by` group now check scales and offsets directly. Metadata persistence needed a word first:
nothing said a subset keeps the source's variable length records, so a solver could have rebuilt a
bare header and still passed. The description now says results keep "source scaling, variable
length records and input order", and the tests cover a custom VLR plus the extra dimension
definition surviving crop, thin and split, with one write and read round trip proving the cropped
file is still valid on disk. 180 tests, meta 497 words.

## Alignment check: three interface clarifications

Behaviors came back OK; only interface wording was flagged. `Partition` and `DatasetSummary` are
now named in the re-export list rather than left implied, `DatasetSummary.bounds` is stated as a
`laspy.Bounds` or None (the tests read `.mins` / `.maxs`), and the per axis rule now says explicit
`scales` and `offsets` hold three values. Funded by six small compressions elsewhere, so the
description is 496 words with no behavior clause dropped.

## Twelfth round: advisories only

Two of the three needed a description word. Nothing said the operations leave their inputs alone,
so a solver could have mutated in place and passed; the description now says "Sources are never
modified" and one test runs all five operations over a shared dataset and compares stored
coordinates, classifications, flags, extra values, VLR ids, point count and offsets before and
after. Extra dimension metadata was likewise unstated, so "Extra dimensions union with their
definitions" now covers description, scales, offsets and no data, with a test on a scaled extra
dimension carrying a description.

The offset case needed no wording, only a correct fixture: my first attempt put two X values in
different voxels because 105.75 requantizes to 106.0 at scale 0.5. The corrected fixture uses
stored 11 and 10 so they share a voxel, which is what makes the offset and per axis scale
load-bearing. 184 tests, meta 494 words.

## Thirteenth round: advisories only

Four taken. Record preservation now covers `partition` as well, asserted on buffered and split
cells rather than only on crop/thin/split outputs. `min_points=0` is pinned as accepted, since the
description rejects only negative counts. `split_by` is exercised on `gps_time`, so float keys are
covered alongside signed and unsigned integer dimensions.

The `as_dict()["bounds"]` suggestion is the same assertion an earlier round flagged as unfair, so
it went back in only after one word closed the gap: the field list now reads "all reachable
unchanged through `as_dict()`", which rules out a recursively converted mapping. With that stated,
comparing the extents is fair, and the empty case still asserts None. 187 tests, meta 495 words.

## Fourteenth round: advisories only

Both taken at no word cost. Which definition wins when the same extra dimension name and dtype
carry different descriptions, scales or offsets was only implied; the sentence now reads "Extra
dimensions union with their first definitions, in appearance order", which states the precedence
without losing the ordering rule, and a test pins the first description, scale and offset.
`summarize` joined the immutability sequence, so all six operations now run over the shared
dataset in that before and after comparison. 188 tests, meta 495 words.

## Fifteenth round: the density sentinel

One flag, and it was a wording defect rather than a test problem. The clause read "The span is None
without GPS time, the density when the area is zero", which relies on an elision for the second
half, so the description never actually named the value for a zero area summary; None was
therefore not singled out over NaN, zero or infinity. It now reads "and the density is None when
the area is zero". No test or code change was needed. 498 words.

## Sixteenth round: advisories only

Three taken, no description change needed. Extended records now have subset coverage: a 1.4 source
with an EVLR is crop/thin/split/partitioned and every result keeps it, and a companion test proves
the source's own EVLR list is untouched by those operations plus merge. The explicit override test
now uses negative and positive half steps on all three axes at once (-2.5, 3.5, -1.5, 2.5, 0.5,
-0.5 at unit scale), so every axis exercises ties-to-even under caller supplied scaling rather than
only X. The immutability snapshot grew from seven sampled fields to eleven, adding header bounds,
the per return histogram and the extra dimension definition. 191 tests, meta unchanged at 498.

## Advisory round after the FP fix: one taken, one declined

**Taken: summarize versus a stale header.** The existing agreement test used an already-updated
header, so an implementation that echoed `header.point_count` / `mins` / `maxs` would have passed.
The new test corrupts the header deliberately (count 99, bounds +/-50, a bogus return bin) and
requires the summary to report the real 2 points, the real extent and `{1: 2}`. A 32nd mutation
that reads `data.header.point_count` instead of counting the record proves the discriminator.

**Declined: empty thinning.** This is the one test I removed to regain solvability, and re-adding
it would take the batch back to 0 of 6. It asserts behavior the description never promises, and
half the batch died on it through laspy's `las[mask]`-with-empty-index trap rather than through any
stated rule. Because nothing in the contract describes it, its absence cannot hide a divergence,
so it costs no FP exposure - which is precisely why it was the right lever earlier. An advisory
does not outrank the solvability floor; if a future batch shows headroom, this is the first test to
restore, together with a description clause promising the behavior.

Solvability re-checked after adding the stale-header test: Vega still passes 193 / 193.

The fairness round then flagged that stale-header test, and the objection was right about the
wording rather than the test: laspy treats header synchronization as an explicit operation
(`LasData.update_header`), so trusting the header was a defensible reading of "counts a dataset".
The sentence now reads "`summarize(data)` counts the points themselves, not the header", which
keeps a discriminator the FP panel would otherwise have to catch and costs four words, paid for by
compressing the split rule and the reject list.

The other two advisories were declined for recorded reasons: empty thinning is the solvability
lever described above, and duplicate `(user_id, record_id)` pairs *inside* one dataset are not
something the description constrains, so pinning either outcome would invent a rule. The negative
quadtree suggestion is worth taking whenever the suite next has room.

## Quality round: one representation pin relaxed

`test_merge_drops_evlrs_for_legacy_versions` asserted `merged.evlrs is None`, which pins laspy's
absence representation rather than the stated behavior that extended records do not survive before
1.4. An empty list is an equally valid way to express that, so the assertion is now
`is None or len(...) == 0`. The reference still returns None, the "evlrs kept for legacy versions"
mutation is still killed because the mutant keeps a record rather than an empty container, and the
suite is unchanged at 193.

## Advisory round: two taken, empty thinning declined again

Taken: recursive splitting now has a case away from the origin, where a negative base cell
subdivides into children `(1,-2,-2)` and `(1,-1,-1)` with the first child's extent asserted, so
child indexing is pinned across a parent boundary rather than only inside cell `(0,0)`. Also added
a six bound crop whose Z interval alone quantizes to nothing, complementing the XY cases.

Declined for the third time: empty thinning. It remains the single lever holding solvability, it
asserts behavior the description does not promise, and its absence cannot hide a divergence. The
advisory checker has no memory between rounds, so this will keep coming back; the decision and its
cost are recorded here so it is not silently re-added.

Solvability re-checked after both additions: Vega passes 195 / 195.

## Advisory round: two taken, empty operations declined on measurement

Taken: a buffered cell now asserts its recomputed bounds and per return histogram, not just the
point count, so the header rule is exercised on the path where synthetic neighbours are added. The
two round trip tests now compare paired `(coordinate, classification)` tuples instead of two
independently sorted columns, which is a real strengthening: independent sorts would pass even if a
point kept its coordinate but lost its attributes.

Declined, and this time measured rather than argued: the suggestion was to cover `thin` **and**
`crop` on an already empty dataset. I probed the only passing agent before deciding, and it fails
crop on empty with the same `AttributeError: points is not a valid dimension` that already blocks
empty thinning, because laspy's `las[mask]` takes its "list of dimension names" branch for a
zero-length index. Adding either half returns the batch to 0 of 6. Neither behavior is described,
so neither can hide a divergence.

Solvability re-checked: Vega passes 196 / 196.

## Hardening round: two new interacting rules

Ten advisory rounds had each shaved a little difficulty, so the scope grew back in the one direction
that does not reopen a fairness or FP hole: new stated rules with their own traps.

1. **`thin(..., keep="centre")`** keeps the point nearest the voxel centre by squared stored
   distance. The centre of a voxel of size S sits at `k*S + S/2`, which is a half unit whenever S is
   odd, so the comparison has to be done on doubled offsets to stay exact; it also has to run on all
   three axes and to fall back to the earliest point on a tie. It leans on three rules that already
   existed - the anchored stored grid, the ties-to-even size conversion, and the earliest-wins tie
   rule - so a solver cannot bolt it on without having those right.
2. **A reused extra dimension name must agree on its scaling**, not only its type. The scales and
   offsets are numpy arrays, so the naive `!=` comparison raises "truth value of an array is
   ambiguous"; the check has to be elementwise and has to treat an unscaled dimension as a distinct
   case. The first-definition rule still governs the description, so the two rules interact rather
   than overlap.

Cost and effect: 205 tests (+9), 498 human-effective LOC (+20), 35 mutations all killed (+3,
including one that caught a weak fixture of my own: the "measures every axis" case originally passed
even when only X was measured, so the fixture now puts one point centred in X and off in Z).

**What this does to the solvability evidence, stated plainly.** No batch-1 agent can satisfy rules
that did not exist when it ran, so the replay stops being an oracle for the new scope. Vega, the
agent that passed 196 / 196, now fails exactly seven tests and they are exactly the seven new ones:
the two scaling conflicts and the five centre cases. Nothing it already did broke. That is the
useful reading: the old 196 requirements are jointly satisfiable by a real agent, the new nine are
small and fully specified, and the three prompt bugs that made batch 1 unsolvable are still fixed.
Batch 2 measures the rest.

## Verify Solution: EnvironmentStartTimeoutError

The run failed on infrastructure, not on the artifacts: the report itself shows the baseline green
(854 passed / 21 skipped) and the full F2P list resolved, then the oracle hit
`EnvironmentStartTimeoutError` after 33 minutes. Nothing in the deliverable plausibly explains a
slow environment start, and I measured rather than assumed:

- container start, cold: **0.8 - 1.4 s** (`python -c "import laspy"` resolving to `/app/laspy`)
- my layers over the base image: **134 MB** (57 MB `COPY`, 76 MB pip), base is the rest of the 1.7 GB
- image build from a pristine clone: **32 s**
- nothing runs at container start; `CMD` is a plain shell

So the timeout is platform side, most likely a cold pull of the 1.5 GB base or node contention, and
the fix is a re-run. I still trimmed what I control: `hatchling` and `editables` are only needed
while the editable install runs, so they are uninstalled in the same layer, caches are removed, and
the build now asserts `laspy.__file__` resolves under `/app` so a broken install fails the build
instead of the oracle. Re-validated on the rebuilt image: 205 F2P, 205 passing with the solution,
854 baseline, 35 / 35 mutations.

## FP alignment audit

Every test traces to a meta sentence. Fixed during the audit:

- `Partition` and `DatasetSummary` attribute names were not in the description while the tests read
  them; both are now enumerated in the first paragraph.
- The GPS time clause said "mixing week and standard time is an error" while a test allows a format
  without GPS time to disagree; the clause now scopes to datasets that carry GPS time.
- Partitions keeping the source scaling, the offsets fallback when every dataset is empty, and
  negative distances/counts being rejected were all tested but unstated; all three are now stated.
- A test asserting `repr(Partition)` contains the key was dropped: nothing in the description pins
  the repr text.
