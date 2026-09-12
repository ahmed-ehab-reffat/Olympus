# LEVELS - moov-io/ach: ApplyCorrections

Calibration record. Protocol lives in `../../CALIBRATION_STRATEGY.md`; the acceptance
band is **1 <= solves <= 4 out of 10**, targeting a true solve probability
p ~= 0.25.

## History

| Level | Lever moved | Tests | Ref soln: files / eff LOC | Local estimate | Platform | Verdict |
|---|---|---|---|---|---|---|
| L1 | Original contract: atomic apply, entry hash roll-up, service class re-derivation | 27 | 2 / ~131 | not run | **2 solves / 2 runs** (Nova) | **too easy** |
| L2 | D1 entry-level code legality, D2 as-sent matching through OriginalDFI, D3 cross-file atomicity | 43 | 2 / 162 | not run | **2 solves / 2 runs** (Nova) | **too easy** |
| L3 | P classified partition, G canonical refusal file, O incremental offset rebalancing | 74 | 2 / ~303 | not run | **2 solves / 2 runs** (Nova) | **too easy** |
| L4 | Maximum probe: C inverse undo/redo journal, H bounded IAT targets, V concrete-batch validation | 120 | 4 / ~559 | not run | **0 solves / 6 runs** (Nova 7-12) | **too hard** |
| L4a | E0: clarify directional service-class rebuilding; behavior unchanged | 120 | 4 / ~559 | 120/120, 1534/1534, 37/37 killed | Nova 13: 120/120; Nova 14: 118/120 | **1 apparent solve / 2** |
| L4b | Review revision: incomplete composite data, C06 forward coverage, output service classes | 125 | 4 / ~564 | 125/125, 1534/1534, 41/41 killed | not run | **current revision** |

## L1 - too easy, superseded

Two platform runs, both `PASS_LEGITIMATE`, 27/27 new tests and 1534/1534
baseline: runs 1 and 2 in `RUNS.md`. Per
`CALIBRATION_STRATEGY.md`, 2 solves in 2 runs is the harden-now branch (94% posterior
that true p > 0.4).

**Why it was too easy.** Both solvers independently wrote a stage-validate-commit
architecture: index the entries up front, stage the corrections against copies or
field snapshots, validate, commit, then recompute the controls by hand. Every rung
of the L1 shallow-implementation ladder sat *below* that architecture. The
`File.Create`-sums-stale-controls trap, the service-class-before-build trap and the
check-digit trap all punish solvers who mutate first and rebuild after; nobody who
stages and recomputes manually ever meets them. The eval recorded roughly 40 agent
steps each with no dead ends.

**Invariants both passing solutions shared**, which L2 targets:

| # | Invariant | Broken by |
|---|---|---|
| I1 | The match key is the trace number alone; `Addenda98.OriginalDFI` is never read | D2 |
| I2 | A notification's validity is decidable from the notification alone; the matched entry's state is never consulted | D1 |
| I3 | Corrections are independent field overwrites; intermediate entry state never matters | D2 |
| I4 | Commit is per call; there is no atomicity wider than one corrections file | D3 |

## L2 - too easy, superseded

Two more platform runs, both `PASS_LEGITIMATE`, 43/43 new tests
(runs 3 and 4 in `RUNS.md`). Four runs, four solves.

**Why it failed to discriminate.** Both solvers converged on the same recipe with no
dead ends: an upfront index keyed on the composite `(trace, as-sent RDFI)` (both wrote
a `correctionKey` helper), staged per-entry state validated with entry context (both
independently wrote a `transactionCodeRequiresZeroAmount` predicate), abort before
committing on any error, then a bottom-up recompute of the controls. Every L2 axis was
absorbed by that recipe as a small delta. **Stated rules that fit the
stage-validate-commit shape get transcribed, not tripped over.**

## L2 - the axes as designed

Three discriminators on independent axes, in three subsystems, each with a
different expected failure rate so outcomes spread rather than forming one wall.

| Axis | Rule | Expected failure rate |
|---|---|---|
| **D1** validation | A corrected transaction code the library requires to carry a zero dollar amount is refused when the matched entry holds a nonzero amount. Uses the repo's own `isPrenote` predicate; `ValidAmountForCodes` enforces it from every SEC batch's `Validate`, so a solver that misses it only fails at `batch.Create()` **after** mutating, breaking atomicity. | **high** - both observed passers and the L1 golden all miss it |
| **D2** matching | A notification names its entry by trace number **and** `OriginalDFI`, read as the entry stood when the call began. A later notification naming an as-sent routing number still matches after an earlier one corrected it; one naming the corrected routing matches nothing. | **medium** - free for stagers, fatal for in-place mutators and index-rebuilders |
| **D3** commit | `ApplyCorrections(corrections ...*File)`. One refusal anywhere means nothing from any file takes effect. | **low-medium** - many will get it; exists so partial credit spreads |

**Mutation evidence that L2 targets the observed passers:** the composite
`nova-as-written` (D1 check absent, OriginalDFI ignored, per-file commit loop) is
killed by **8 tests**. The full run is 20 mutations, **0 survivors**, none killed
by fewer than 2 tests.

**Deliberately excluded:** IAT targets (stated nowhere, tested nowhere - T5), the
reverse zero-amount rule (the repo gates it on `AllowZeroEntryAmount` and
SEC-specific cases, so there is no single right answer to state), and any change
to the refused-change-code rule.

| Run | Model | Result | Trajectory |
|---|---|---|---|
| - | - | not run | - |

## L3 - too easy, superseded

L3 targets all three structural gaps in the four successful solutions. Its purpose
is not to land directly in the 1-4/10 shipping band. It exists to find a failure
ceiling, after which the shipping level is interpolated between L2 and L3.

| Gap in the winning recipe | L3 axis |
|---|---|
| No output stage; the method only mutates and returns an error | **G**: construct a canonical refused-NOC file accepted by the repository's writer, reader, and validator |
| Fail-fast, unclassified validation | **P**: partition every notification and expose the first refusal reason as a dictionary code |
| Independent entries and one final control pass | **O**: make offset feasibility depend on earlier accepted changes, then rebalance preserved offsets before controls |

**P, partition and precedence.** The signature is
`ApplyCorrections(corrections ...*File) (*File, error)`. Every notification applies
or is refused and processing continues. The ordered classification is C65 for
unreadable data, C61 for an unknown DFI, C62 for a known DFI with no matching trace,
C62 for an offset target, C67 for a bad routing number, and C69 for a bad
transaction code or a direction change that empties an offset population. The
C61/C62 split requires a DFI lookup before the composite entry lookup.

**G, canonical generation.** Refusals are copied in processing order into one COR
batch per source file with refusals. Headers have one stated provenance, refused
addenda carry the classified and original fields, and controls are built. The result
must validate and survive the public writer/reader round trip.

**O, incremental offsets.** Existing entries named `OFFSET` cannot be correction
targets. A credit offset receives the non-offset debit total and a debit offset the
non-offset credit total. A proposed change that would make an existing offset zero
is refused against staged state containing every earlier accepted notification. The
same two direction changes in opposite orders therefore produce different accepted
entries. Offset entries and transaction codes are preserved, and offsets participate
in hashes, totals, service classes, and file controls.

**Local evidence.** The suite has 74 named entities. All fail at the base commit and
pass with the golden solution. The 32-mutation run has zero survivors and no weak or
synthetic kills. The `nova-l2-as-written` composite is killed by **24 tests**.

| Run | Model | Result | Trajectory |
|---|---|---|---|
| 5 | Nova | PASS_LEGITIMATE, 74/74 new and 1534/1534 baseline | raw bundle archived; see `RUNS.md` |
| 6 | Nova | PASS_LEGITIMATE, 74/74 new and 1534/1534 baseline | raw bundle archived; see `RUNS.md` |

**Why it failed to discriminate.** Both solvers absorbed P, G, and O into one
forward recipe: immutable DFI/trace lookup, ordered parse/classify, immediate
mutation with a one-entry offset rollback snapshot, refusal collection, final
rebalance/control rebuild, then refused-file construction. Nova 5 also implemented
IAT receiver targets proactively. Neither run encountered a sustained architectural
dead end. Additional refusal rows or offset cases would exercise the same recipe.

## L4 - maximum ceiling confirmed

L4 deliberately targeted a zero-solve ceiling. Nova 7-12 confirmed it with six
legitimate failures; all baseline suites passed. Its axes cross three
implementation shapes:

| Axis | Rule |
|---|---|
| **C** | Persist every accepted pre-state; after final receiver identity is known, generate executable reverse-order Undo. Applying Undo generates executable redo that reproduces the post-forward state. |
| **H** | Match and update ordinary and bounded IAT receiver targets through one typed pipeline, including Addenda15 and IAT controls. |
| **V** | Decide C05 legality per notification against the concrete staged target batch, rolling back target and controls on C69 instead of discovering invalidity at final rebuild. |

The axes interact in the hidden suite. Partial C-only, H-only, V-only, and pairwise
implementations all fail behavioral tests rather than only the new signature. The
L4 public contract was the 487-word ASCII `meta.md`, under the fixed 500-word
limit.

**Local evidence.** The suite has 120 named entities. All fail at the base commit
and pass with the golden solution, while all 1534 baseline entities pass before
and after it. The 37-mutation run has zero survivors and no weak or synthetic
kills. The `nova-5-as-written` and `nova-6-as-written` composites are killed by 44
and 24 tests. Dockerfile remains unchanged from L3.

The observed hidden totals were 110, 107, 105, 118, 110, and 100 out of 120. All
six failed the two IAT C05 service-class tests; five also failed the independent
offset family. Nova 10 failed nothing else. The shared error follows the phrase
"widens when needed but never narrows": every solver selected mixed rather than
the directional covering class after an IAT direction change.

Platform policy after local verification was:

- 0/2: desired ceiling found; stop and ease immediately.
- 1/2: failure and solvability both demonstrated; continue this fixed level under
  the normal protocol.
- 2/2: still too easy; read both trajectories and replace the absorbed axis rather
  than adding more cases.

## Interpolation down from L4

The six-run evidence supersedes the speculative V-first ladder:

1. **E0, applied:** clarify directional service-class reconstruction in the
   prompt, retain all 120 tests and all C+H+V+O behavior.
2. **E1, only if E0 remains at zero:** remove IAT C05 from H, retaining IAT routing,
   Addenda15, and their undo/redo interactions.
3. **E2:** remove V, retain C+reduced-H and undo/redo.
4. **E3:** remove reduced H, retain C and ordinary undo/redo.
5. **E4:** retain C but remove redo, keeping executable Undo.

E0's wording is 496 words including the title. Current-run behavioral
counterfactual: Nova 10 becomes a solve when only its two service-class failures
are corrected, while the other five remain blocked independently. See `PLAN.md`
section 14 for the probe protocol.

## L4a platform result and L4b correctness revision

Nova 13 passed all 120 hidden tests and Nova 14 passed 118, missing only refused
batch numbering. The user reports one pass in the full ten-agent working pool,
which is nominally in the target band. Panel review later showed the Nova 13 pass
was a hidden-suite false positive: its custom parser accepted incomplete
C03/C06/C07 data that `ParseCorrectedData` rejects, including a routing-only C03
which erased the target account.

L4b therefore does not ease or harden a discriminator. It adds five fair regression
entities: two incomplete-composite refusal tests, direct C06 forward coverage, and
covering-service-class tests for mixed-direction Refused and Undo batches. The
reference now rebuilds output service classes before `BatchCOR.Create`. The prompt
was rewritten in a more natural issue voice at 492 words without changing its
requirements. Its paragraphs are not hard-wrapped, and its refused-output contract
names the public fields and accessor asserted by the suite.

Raw calibration remains one apparent pass in ten, but that implementation fails
two L4b tests. Treat the corrected-suite solve count as unproven until another
platform probe; do not ease based solely on the review repair because the review's
difficulty assessment accepted the current scope.

**L4b local evidence.** All 125 named feature entities fail at the base commit and
pass with the reference, while all 1534 baseline entities pass before and after it.
The 41-mutation run has zero survivors, zero weak or synthetic kills, and a minimum
kill count of two. The unchanged Nova 13 patch fails exactly the two new incomplete-
composite tests.
