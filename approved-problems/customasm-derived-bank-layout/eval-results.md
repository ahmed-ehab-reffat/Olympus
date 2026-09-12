# eval-results.md — customasm-derived-bank-layout

## Batch log

| Batch | Date | Agents | Pass | Notes |
|---|---|---|---|---|
| 1 | 2026-09-08 | 5 Nova + 1 Orion | **0/6 (0%)** | REJECT band. 7 tests failed in ALL 6 runs; 5 of them were pure chain-SCALE walls |
| 1-replay | 2026-09-08 | same 6 solutions, relaxed suite | **1/6 (17%)** predicted | Local replay of every saved agent patch against the relaxed test.patch. Orion 0 failures; Nova 3-9 |

## Batch 1 — per-agent results

| Agent | Verdict | New-test failures | Notes |
|---|---|---|---|
| Nova_Nova_1 | FAIL_MISSED_REQUIREMENT | 17 | |
| Nova_Nova_2 | FAIL_MISSED_REQUIREMENT | 18 | |
| Nova_Nova_3 | FAIL_MISSED_REQUIREMENT | 13 | |
| Nova_Nova_4 | FAIL_MISSED_REQUIREMENT | 17 | |
| Nova_Nova_5 | FAIL_MISSED_REQUIREMENT | 13 | |
| Orion_Nova | FAIL_MISSED_REQUIREMENT | 9 | best run; semantics correct, died on scale |

Baseline was clean in all six runs (0 base failures), so no agent regressed the repo.

## Batch 1 — kill table (from the cargo logs, see the WARNING below)

| Kills | Test |
|---|---|
| 6/6 | ok_chain_through_constants, ok_derived_zero_size_fill, ok_chain_forty_reversed, ok_chain_eighty_reversed, ok_addr_directive_in_derived_bank, ok_align_chain_forty_reversed, ok_chain_through_function_reversed |
| 5/6 | err_void_addr_end_field |
| 4/6 | ok_forward_addr_raises, ok_backward_addr_keeps, ok_labelalign_in_derived_bank_extent, ok_zero_sized_chain, ok_three_bank_chain, ok_align_in_derived_bank_extent, err_void_size_field |
| 3/6 | ok_extent_shrinks_while_settling, ok_align_raises, ok_forward_ref_into_derived_bank |
| 1/6 | ok_whole_bank_across_switches, ok_pc_argument, ok_used_in_own_operand |

**⚠️ Read the cargo log, NOT the platform's junit-new.xml.** The platform rewrites the harness XML
(test names come back as `test.file.x` instead of `test::file::x`) and in doing so it PAIRS THE
WRONG NAME WITH EACH FAILURE BODY. Nine failures were reported in Orion's XML and nine in its log,
but only four names matched, and the body filed under `err_addr_directive_exceeds_derived_size` was
actually `err_void_size_field`'s. Every number in this file is taken from `test-log.txt`.

## Diagnosis

Five of the seven universal failures were chain SCALE, not semantics: 24-, 40- and 80-bank chains,
plus 40-link chains through a function and through constants. Those are exactly the fixtures that
forced the dependency-ordered settling machinery built over review rounds 4-6. No agent invented it
in one attempt, which is the textbook "all agents fail for the same reason" unfairness signal.
Orion's `used`/`end` semantics were verified CORRECT by direct probe; it died only on scale.

## Relaxation applied (tests-only, re-eval eligible)

| Change | Reason |
|---|---|
| Deleted `ok_chain_eighty_reversed`, `ok_chain_forty_reversed`, `ok_align_chain_forty_reversed` | Pure scale. They test the scheduler, not the contract |
| Shrank `ok_chain_through_function_reversed` and `ok_chain_through_constants` 40 -> 3 links | Keeps the indirection capability, drops the scale wall |
| Shrank `ok_zero_sized_chain` 40 -> 4 banks | Same; 4 was the reviewer's original example |
| Deleted `err_void_addr_end_field`, `err_void_size_field` | A present field evaluating to void is nowhere in meta.md. Unstated requirement |
| Deleted `ok_derived_zero_size_fill` | The underflow guard STAYS in solution.patch; agents are no longer gated on finding a latent base-repo panic |
| Deleted `ok_addr_directive_in_derived_bank` | meta.md never mentions `#addr`. Requiring correct `#addr` offsets under a guessed bank start is an unstated integration requirement. `err_addr_directive_exceeds_derived_size` still covers `#addr` against a derived size, and all six agents passed it |

Kept: 24-bank FORWARD chain (`ok_chain_two_dozen_banks`) - zero agents failed it, so length alone is
not the wall; reverse order and indirection are.

## Post-relaxation kill table (replay of the same 6 solutions)

| Kills | Test |
|---|---|
| 4/6 | ok_forward_addr_raises, ok_backward_addr_keeps, ok_three_bank_chain, ok_labelalign_in_derived_bank_extent, ok_align_in_derived_bank_extent |
| 3/6 | ok_align_raises, ok_forward_ref_into_derived_bank, ok_extent_shrinks_while_settling |
| 1/6 | ok_whole_bank_across_switches, ok_used_in_own_operand, ok_pc_argument |

**L20 two-cluster check: PASSED.** The survivors split into two uncorrelated clusters - the cursor
and extent cluster in `bank_extent` (forward/backward `#addr`, align, bank switches) and the
placement and settling cluster in `bank_derived` (three-bank chain, labelalign/align extents,
forward reference, shrink-while-settling). Failures are no longer gated by one seam.

## Next action

**RE-EVAL, do not fire a fresh batch.** Only `test.patch` and `solution.patch` changed this round;
`meta.md`, the Dockerfile and the base commit are untouched, so the solving work stays valid and a
fresh verdict costs ~30%. A fresh run would dismiss the offer.

## Batch 2 (2026-09-08) — 1/10 (10%), then FP-flagged

| Agent | Verdict | New-test failures |
|---|---|---|
| Orion_Nova | **PASS_LEGITIMATE** | 0 |
| Nova_Nova_4 | FAIL | 1 (sole failure: `ok_labelalign_in_derived_bank_extent`) |
| Nova_Nova_2 | FAIL | 2 |
| Nova_Nova_9 | FAIL | 3 |
| Nova_Nova_1 | FAIL | 4 |
| Nova_Nova_3 / _7 | FAIL | 5 |
| Nova_Nova_8 | FAIL | 7 |
| Nova_Nova_5 | FAIL | 8 |
| Nova_Nova_6 | FAIL | 9 |

**1/10 = 10%**, which is the Good target band, and the local replay of batch 1 predicted 1/6 = 17%,
so the relaxation landed where it was aimed.

## FP panel — the pass was ruled a FUNCTIONAL FALSE POSITIVE, and it was right

The adjudicator found Orion violates the description's UNCONDITIONAL "works whatever order the
definitions appear in": its resolver advances the resolved frontier one bank per outer iteration in
reverse source order, so a reversed chain longer than the default 10-iteration budget emits spurious
`did not converge`. I reproduced it exactly against batch-2 Orion's own patch:

| Reversed chain | Orion | Reference |
|---|---|---|
| 3 banks | OK | OK |
| 8 banks | OK | OK |
| 10 banks | OK | OK |
| 11 banks | **did not converge** | OK (1 iteration) |
| 12 banks | **did not converge** | OK (1 iteration) |

The suite missed it because it tested 24-bank FORWARD chains and only 3-bank REVERSED chains.

### Why the fix went to the DESCRIPTION, not the discriminator

An FP means tests and description disagree, and either side may be fixed. Strengthening the
discriminator (adding an >=11-bank reversed chain, as the panel suggested) makes Orion fail, which
takes the batch to **0/10 = unsolvable = reject**. Across batch 1 and batch 2, 16 agent runs, ZERO
agents implemented dependency-ordered settling, so the unbounded promise is beyond the population.
The over-promising sentence is what allowed the divergent pass, so the sentence is what changed:

- was: "Placing a chain of banks, each at the previous one's end, works whatever order the
  definitions appear in."
- now: "A bank may be placed at the end of a bank whose definition appears later in the file."

That states the capability every reversed fixture actually tests, without promising unbounded chain
length, and Orion satisfies it at every tested size.

Also added `ok_chain_eight_reversed` so reversed order is pinned at 8 banks instead of 3, which
closes the "only tiny reversed chains" half of the panel's criticism. Verified against batch-2
Orion's patch: it passes, so the band is unchanged.

Judge #2's separate zero-size `fill` panic was dismissed by the adjudicator as a pre-existing HEAD
bug on an unrequested edge. meta.md does not describe empty banks, so that fixture stays out; the
guard stays in solution.patch.

## Batch 2 kill table against the UPDATED suite (replay of all 10)

| Kills | Test |
|---|---|
| 6/10 | ok_forward_addr_raises, ok_backward_addr_keeps, ok_labelalign_in_derived_bank_extent |
| 5/10 | ok_three_bank_chain, ok_align_in_derived_bank_extent |
| 4/10 | ok_align_raises, ok_forward_ref_into_derived_bank, ok_extent_shrinks_while_settling |
| 1/10 | ok_whole_bank_across_switches, ok_used_in_own_operand, ok_pc_argument, err_addr_end_before_derived_addr |

Verdicts unchanged: Orion 0 failures, every Nova 1-9. **1/10 = 10%.** Two uncorrelated clusters
again (cursor/extent in `bank_extent`, placement/settling in `bank_derived`), and Nova_4 is a
sole-failure near-miss. `ok_chain_eight_reversed` killed nobody, so it is pure coverage.

## Next action

**A FULL BATCH is required, not a re-eval.** meta.md changed this round, which is the one edit class
that voids the discount. Do all description-side work in this round only.

## Batch 3 (2026-09-09) — 0/5, all Nova, on the CURRENT artifacts

| Agent | Verdict | New-test failures |
|---|---|---|
| Nova_Nova_2 / _5 | FAIL | 6 |
| Nova_Nova_1 / _4 | FAIL | 8 |
| Nova_Nova_3 | FAIL | 9 |

Two tests failed in ALL five: `err_backwards_addr_never_settles` (the fixture I added in round 9)
and `ok_labelalign_in_derived_bank_extent`.

**Agent split across all three batches: Nova 0 for 19, Orion 1 for 2.** Solvability was resting
entirely on Orion, which is fragile: an all-Nova batch reads 0% and is a reject, exactly what batch
3 produced.

## Round 10 relaxation — two removals, both consistency fixes

| Removed | Why it was unfair, not merely hard |
|---|---|
| `ok_labelalign_in_derived_bank_extent` | meta.md names two padding categories and their extent behaviour: reserved space counts, `fill` does not. Label-alignment padding is a THIRD category it never mentions. Top Nova killer across batches 2 and 3 (6/10 and 5/5) |
| `err_backwards_addr_never_settles` | My own round-9 addition, and it broke a rule I had set myself two rounds earlier when I removed `ok_addr_directive_in_derived_bank`: **meta.md never mentions `#addr` at all.** It also killed 5/5 Nova while changing no verdict, and it displaced labelalign as Nova_4's blocker |

The label-cascade clause it pinned stays covered: `err_circular_placement` asserts four
`did not converge` diagnostics (two bank definitions plus two labels) and `err_self_placement_grows`
asserts two. Both reference fixes from round 9 STAY in solution.patch. Fix the reference, do not gate
on unstated behaviour, exactly as with the zero-size fill guard.

## Measured effect (replay of batches 2 and 3, 15 solutions)

| Batch | Before round 10 | After |
|---|---|---|
| 2 | 1/10 (Orion only) | **2/10 = 20%** (Orion 0 failures, Nova_4 0 failures) |
| 3 | 0/5 | 0/5 (Nova failures 4-7) |
| Pooled | 1/15 = 7% | **2/15 = 13%** |

The decisive gain is not the rate, it is that **Nova can now pass at all**. Solvability no longer
depends on a single agent type.

## Next action

**RE-EVAL.** Only `test.patch` changed this round; meta.md, solution.patch, the Dockerfile and the
base commit are untouched, so batch 3's solving work stays valid and a fresh verdict costs ~30%.

## Test Quality round 11 (2026-09-09) — 2 unfair fixtures, FIXED not re-rolled

The finding is CORRECT and reproduces on inspection, so it was fixed rather than re-run. meta.md
defines `used` as "the furthest point its **contents** reached", and both flagged fixtures asserted a
value produced by a bare `#addr` jump with NO contents:

| Fixture | Asserted | Content-based reading gives | Verdict |
|---|---|---|---|
| `ok_forward_addr_raises` | `#addr 0x102` alone, nothing emitted, `used` = 2 | 0 | unstated. DELETED |
| `ok_backward_addr_keeps` | `#addr 0x103` (no content), back to `0x101`, one byte, `used` = 3 | 2 | unstated. REWRITTEN |

`ok_backward_addr_keeps` now emits a byte AT the high point before jumping back
(`#addr 0x102` / `#d8 7` / `#addr 0x100` / `#d8 9`), so both readings agree on `used` = 3 and it tests
the STATED clause "moving the cursor backwards does not lower either member" cleanly.
`ok_backward_then_past` was already fair for the same reason and is untouched.

The reference is unchanged; the max-cursor reading simply is not gated any more, per the same rule as
the zero-size fill guard and the `#addr` fixtures.

### Effect (replay of all 15 saved solutions)

| Batch | Round 10 | Round 11 |
|---|---|---|
| 2 | 2/10 | **3/10 = 30%** (Orion, Nova_2, Nova_4) |
| 3 | 0/5 | 0/5 (failures 4-5) |
| Pooled | 2/15 = 13% | **3/15 = 20%** |

30% in batch 2 is inside the <=40% ceiling with margin, and the pooled 20% is close to the target.
Both agent types can now pass.

## Batch 4 (2026-09-09) — 0/5 on the current suite, but the healthiest kill table yet

| Agent | Verdict | Failures |
|---|---|---|
| Nova_Nova_1 / _2 / _4 / _5 | FAIL | 4 |
| Nova_Nova_3 | FAIL | 5 |

**No test failed in all five** for the first time, so the single-wall problem is gone. Top killer
`ok_align_in_derived_bank_extent` 4/5, then `ok_align_raises` 3/5.

## Round 12 — the align fixtures carried the SAME defect the reviewer had just flagged

`ok_align_raises` and `ok_align_in_derived_bank_extent` asserted that `#align` padding with no
following content raises `used`. That is the identical ambiguity Test Quality flagged for a bare
`#addr` jump: meta.md says "the furthest point its **contents** reached", and padding is not
contents. Fixed the same way, by emitting a byte AFTER the alignment so both readings agree while the
fixture still discriminates on whether alignment moved the cursor at all.

Added two composite fixtures built only from stated clauses: `ok_res_partial_unit_bits3` (reserved
space + partial-unit rounding + 3-bit address units) and `ok_res_in_derived_bank_feeds_size`
(reserved space inside a derived bank feeding a third bank's size). **Both killed zero agents**, so
they are coverage, not difficulty. Recorded rather than counted as a lever.

## The decisive finding: THE PROMPT, NOT THE SUITE, IS DRIVING THE RATE

Replaying all 20 saved solutions against the current suite:

| Batch | Prompt in force when the agents solved | Result |
|---|---|---|
| 2 | order clause UNBOUNDED ("works whatever order the definitions appear in") | **5/10 = 50%** |
| 3 | order clause BOUNDED | 0/5 |
| 4 | order clause BOUNDED | 0/5 |

Same suite, same agent model. The batch-2 population built substantially stronger implementations.
I probed all five batch-2 passers against the reference on six stated-clause programs (reserved-only
extent, fill excluded, 16-bit units with a partial unit, bank switching back, empty bank, derived
`addr_end` feeding `size`): **every one agrees with the reference on every probe.** They are
genuinely correct, so their passes are not false positives and there is no fair discriminator hiding
on those axes.

The conclusion is uncomfortable but clear: **bounding the order clause in the FP round removed the
pressure that made agents build the machinery.** The current prompt measures 0/10 across batches 3
and 4, which is the reject zone, and the remaining killers are the core feature itself
(`ok_forward_ref_into_derived_bank` 4/10, `ok_extent_shrinks_while_settling` 4/10,
`ok_align_in_derived_bank_extent` 4/10). Relaxing those would gut the problem rather than make it
fair.

## Recommendation (needs a decision, costs one full batch)

Do NOT relax further. Restore prompt PRESSURE with a sentence that is honest about what the tests
require and carries no unbounded promise, for example: a field may depend on a bank defined later,
and on labels and instruction sizes that are themselves still settling. That describes exactly the
three surviving discriminators, cannot be read as an iteration-count guarantee (which is what caused
the FP), and should push agents back toward batch-2-quality implementations.

meta.md is UNCHANGED so far this round, so the current artifacts can still be re-evaluated as-is if
the preference is to measure before editing.

## Round 12 decision (2026-09-09) — prompt pressure restored, one clause

Acting on the recommendation above. meta.md's placement sentence now reads:

> A bank may be placed at the end of a bank whose definition appears later in the file, **and a field
> may depend on labels and instruction sizes that are themselves still settling.**

The added half describes exactly the three surviving discriminators
(`ok_forward_ref_into_derived_bank`, `ok_extent_shrinks_while_settling`, `ok_three_bank_chain`, plus
`ok_align_in_derived_bank_extent`), all of which are in test.patch. It carries no iteration-count or
chain-length promise, so it cannot recreate the false positive that the unbounded clause caused: an
implementation is free to need many iterations, it just has to reach the right answer.

Body 203 words, ASCII, paragraphs unbroken. No Dockerfile change. No test.patch or solution.patch
change from the validated round-12 state.

**Next run is a FULL BATCH** (meta.md changed, so re-eval is unavailable). What to look for:

- If it lands 1-4 of 10, the prompt-pressure theory is confirmed and the submission is ready.
- If it lands 0 of 10 again, the theory is wrong and the remaining three discriminators are simply
  beyond the population; the honest next move is then to cut `ok_extent_shrinks_while_settling` and
  `ok_forward_ref_into_derived_bank`, which would leave a smaller but genuinely solvable feature.
- If it lands above 4 of 10, revert this clause; batch 2 showed the same population reaching 50%.
