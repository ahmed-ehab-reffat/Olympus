# eval-results.md — makerjs-box-joinery

## Agent runs

No agent batch has been run yet. Table to be filled per run.

| Batch | Agent | Evaluator | Verdict | Messages | Files | LOC | Failed tests | Failure reason | Approach note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| - | - | - | - | - | - | - | - | - | - |

## Local validation

Docker, `--network none`, `--user 1000:1000`, image built from a `git archive` of BASE_COMMIT.

| State | Mode | Cases | Failures | Exit |
| --- | --- | --- | --- | --- |
| base + test.patch | base | 124 | 0 | 0 |
| base + test.patch | new | 193 | 193 | 193 |
| + solution.patch | base | 124 | 0 | 0 |
| + solution.patch | new | 193 | 0 | 0 |

Apply order: test-then-solution and solution-then-test both apply cleanly; both unapply cleanly.

## Flakiness

72 runs total of both modes across the build-out and each revision, including 3 per state on the final artifacts, all identical.

| Run | base cases/failures | new cases/failures |
| --- | --- | --- |
| 1 | 124 / 0 | 193 / 0 |
| 2 | 124 / 0 | 193 / 0 |
| 3 | 124 / 0 | 193 / 0 |

No timing, RNG, ordering, network, clock or filesystem-time dependence in either the repo baseline
or the new tests.

## Mutation battery

`Task51/mutate.py` — 26 mutations, one per stated rule. **26 killed, 0 survivors.** Baseline
restored to 0 failures afterwards.

| Mutation | Tests killed |
| --- | --- |
| even finger count allowed | 4 |
| minimum of three fingers dropped | 2 |
| tie rounds down instead of up | 4 |
| kerf shifted toward the tab | 11 |
| kerf applied to the outer boundary | 11 |
| fingers laid at the nominal width | 2 |
| polarity of the first finger flipped | 33 |
| slots not sunk in the profile | 7 |
| complement shifts by half a kerf | 6 |
| negative kerf accepted everywhere | 5 |
| mates answers false on empty instead of rejecting | 2 |
| divider accepted at the far wall | 2 |
| rectangle options validated only when an edge is jointed | 2 |
| rectangle accepts a negative kerf without a jointed edge | 1 |
| mates ignores polarity | 1 |
| mates ignores the boundaries | 2 |
| mates ignores the kerf | 4 |
| mortises cut at the panel slots | 7 |
| mortises widened by the kerf | 2 |
| report counts slots as tabs | 4 |
| doubly slotted corner not notched | 1 |
| corner kept when a slot ate it | 2 |
| outline walked clockwise | 5 |
| side faces tabbed on their vertical edges | 2 |
| divider panel starts with a tab | 2 |
| divider pockets ignore the position | 4 |

Retired mutation: "zero length paths emitted" survived with 0 kills, which proved the zero-length
guard was dead code after corner resolution deduped structurally. The guard was deleted rather than
given a test.

## Size

| Metric | Value |
| --- | --- |
| human-effective LOC | 486 |
| raw added LOC | 712 |
| files changed | 5 (3 new sources, 2 tsconfig registrations) |
| new tests | 193 |
| base tests | 124 |
| meta.md | 491 words / 3127 bytes |
