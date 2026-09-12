# feedback — scikit-bio-feature-hierarchy

## Status

Authored, locally validated, one 4x Nova batch run. The batch came back 0 of 4, and the
diagnosis is that three of the shared failures were defects in my description, not difficulty.
All three are fixed. Nova 3 is proven to become a pass under the corrected wording, so the
task is solvable; a second batch is owed to place the rate.

## Attempt history

### Round 1 (2026-08-07) — authoring

Picked `scikit-bio/scikit-bio` after screening twelve candidate Python repos. Three of the
first shortlist died on local dedup alone (`textx`, `trimesh` and `deepdiff` each already
have a pick in `problems/` or `rejected/`), and `robotics-toolbox-python` died on the
language gate because GitHub reports its primary language as C++.

Feature invented from the architecture, not from an issue: the GFF3 reader parses `ID` and
`Parent` into the interval metadata dict and then nothing in the library uses them.

Built in three passes because the first two landed under the LOC floor:

| Pass | Scope | human-effective |
|---|---|---|
| 1 | hierarchy, spans, coordinates, splicing, protein, summary | 215 |
| 2 | + parts, codon, residue, check, to_interval_metadata, extract | 361 |
| 3 | + coding report, reverse, partial, sequence-backed models | 412 |

Then `at()` was cut (402) because it cost more prompt words per line of real logic than
anything else, and the description was the binding constraint.

### Round 2 (2026-08-07) — Test Fairness

Automated Test Fairness returned FAIL, 13 of 134 unfair. Every flag traced to the tests
pinning something the prompt did not say: the return type of `extract()` and `reverse()`,
the private `_intervals` container those tests read, and non-mutation in
`to_interval_metadata()`. Fixed by aligning both sides, not by cutting scope: the prompt now
names `IntervalMetadata` as the return of all three, states the non-mutation guarantee and
the phase that `reverse()` carries, and rejects a start below zero. The tests moved to the
public `query()`. The four coverage suggestions were taken too, adding seven tests for a
total of 141.

### Round 3 (2026-08-07) — Test Fairness clean

The re-run passed with four advisory coverage suggestions, all taken: other interval-metadata
carriers, unnamed-feature conversion, an explicit sequence beating the remembered one, and an
empty coding report. Five more tests, 146 in total. No prompt or solution change was needed.

### Round 4 (2026-08-07) — Test Fairness clean, one prompt defect found

Five more advisory suggestions, all taken. One of them was worth more than coverage: the
`sibling_overlap` clause said bounds "meeting" those of a sibling, which can be read as
overlapping or as merely touching, and the feature already joins touching bounds elsewhere.
The prompt now says "sharing a position" and a test pins that touching siblings are not
reported. Seven more tests, 153 in total, and two more mutation probes to prove the two new
check rules discriminate.

### Round 5 (2026-08-07) — Test Fairness clean

Three more suggestions, all taken: the remaining strand and end combinations of `partial`,
derived UTRs on a minus-strand transcript, and an extraction clipping the transcription-first
span of a multi-span `CDS` on both strands. Probing the two `partial` clauses afterwards
showed the outermost-bound filter was still unpinned, so two more tests cover a fuzzy inner
bound. Eight more tests, 161 in total. No prompt or solution change was needed.

### Round 6 (2026-08-07) — a solution defect, not a test gap

The reverse-fuzzy suggestion turned up a real bug: `reverse()` mirrored coordinates and
strands but dropped the openness of every bound, so a feature that was partial at its 5' end
came back complete. `to_interval_metadata()` dropped it too. Fixed by carrying openness
through all three conversions, with `reverse()` swapping the two ends of a span along with its
coordinates and `extract()` opening the side of a bound it clips. That last rule links the
subsystem up nicely: a `CDS` truncated by an extraction is now partial, and so exempt from the
`codon_length` check. Eight more tests, 169 in total, and the full battery is now sixteen
mutation probes with no survivors.

### Round 7 (2026-08-07) — description ceiling

A hard ceiling of 870 words landed on the description, which stood at 933 after every
compression pass I could make without losing a stated behavior. Prose alone could not close
the gap, so a member had to go, cut from the prompt, the solution and the tests together.
`coding()` was the choice: 51 prompt words for 21 effective lines, the worst ratio in the
feature, and the least coupled to the traps. The description is now 852 words and effective
LOC 383. 159 tests.

### Round 8 (2026-08-07) — Test Fairness clean

Three more suggestions, all taken. The first found a genuine hole in the prompt rather than in
the tests: the building rules said overlapping and touching bounds are joined but never said
what becomes of the openness at the ends a join swallows. The prompt now says a joined span is
open only where the bounds at its own two ends are, and two tests pin it. The other two cover
an extraction that leaves an already open bound alone and a carrier with no annotations. Four
more tests, 163 in total, and two more mutation probes, still no survivors.

### Round 9 (2026-08-07) — container types, not values

Test Fairness came back FAIL with 50 flags, all one cause: the suite compared the new
composite values against tuples, and nothing says they are tuples. Worse, the nearest
precedent says the opposite, since `Interval.bounds` is a list. With the description already
at its ceiling there was no room to declare nine container types, so the tests gave up the
container instead: `pairs()` and `regions()` normalise any sequence of spans to a list of
tuples, and pair-valued returns go through `tuple()`. Every value, order and count is still
pinned exactly. The prompt gained three words, the order inside a `parts` entry, which
normalising cannot recover. All sixteen mutation probes still die.

### Round 10 (2026-08-07) — two open questions in the prompt

Both suggestions were prompt gaps rather than test gaps. A feature built from several
intervals could take the union of their `Parent` lists or only the first one's, and `reverse()`
on an `IntervalMetadata(None)` could reject or improvise. The code already did the sensible
thing in both cases; the prompt just never said so. It does now, paid for by trimming thirteen
words elsewhere to stay under the ceiling, and three tests plus three mutation probes pin it.
166 tests, 861 words, twenty-one probes with no survivors.

### Round 11 (2026-08-07) — the last report and translation gaps

Three suggestions, all taken and all already stated in the prompt: a `check()` report whose
rows cross more than one feature, `derived=True` leaving the features without an identifier
alone, and a minus-strand translation carrying a leading phase and a trailing remainder at
once. Three tests, 169 in total. Worth recording: the first probe I wrote for the report
ordering survived, and the cause was the probe, not the suite. It sorted the rows by feature
type on a fixture whose types happen to sort the same way as its coordinates. Reversing the
feature order kills three tests.

### Round 12 (2026-08-07) — Solution Quality found a real bug

Both scores came back 2 of 3 for one defect and one smell, and the defect was real. `_build`
collected the strand strings as written and rejected an identifier whose intervals carried
"+" and "." as disagreeing, even though the prompt makes everything but "-" the plus strand.
The set is now built from the normalised value, so they agree, and a genuine "+" against "-"
still raises. The smell was the builder reading `IntervalMetadata._intervals`; it now uses the
public `query()`, which the tests had already moved to in round 9. Two tests, two probes, 171
in total. Effective LOC 385.

### Round 13 (2026-08-07) — one word, two jobs

Re-reading `test_parents_are_listed_by_coordinate_and_named_in_order`, the one test where a
parent's coordinate order and its alphabetical order disagree, the prompt said "ascending" for
both the feature listing and the two identifier strings. Feature listings are ordered by
coordinate here, so a solver could reasonably have serialised the parents in that order and
failed two of the three assertions. The strings now say "in alphabetical order"; "ascending"
survives only where it means coordinates. Word-neutral to within two words, no code change.

### Round 14 (2026-08-07) — first batch, 0 of 4, three prompt defects

The batch found what my own review had not. Three failures repeated across runs, and a shared
failure is a prompt bug, not a hard problem.

The worst one was mine outright: the description said `spliced()` "joins the spans in that
order", meaning transcription order, "and reverse complements the result on the minus strand".
Three of four agents implemented exactly that and got a doubly reversed sequence, because the
reference joins ascending and then reverse complements. The prompt described an algorithm that
does not work. It now says "by ascending coordinate".

The second was the ordering rule not naming what it governs, so `parents` came back
alphabetical to match the two identifier strings beside it. It now names `roots`, `parents`
and `children`. The third was "the bounds of its children" read as all descendants; it now
says "direct children".

Solvability is measured, not assumed. Nova 3 replays at 170 of 192, and a seven-line adapter
that reorders `feature.parents` and nothing else takes it to 171. That run is a pass under the
corrected prompt.

The FP check cannot run on batch 1: it inspects passing agents and there were none. Batch 2
produced passes and is written up in eval-results.

### Round 15 (2026-08-07) — three coverage suggestions

A three-node `Parent` cycle, a `Parent` field naming the same identifier twice, and exact
proteins for genetic codes 1 and 2 instead of only asserting the two differ. All three are
already stated, so no prompt change. The genetic-code one earned its keep: a probe that swaps
in the wrong table whenever code 1 is asked for survives the old inequality assertion and dies
against the exact strings. 177 tests, thirty-two probes, no survivors.

### Round 16 (2026-08-07) — one-sided clipping and the other strand

Two suggestions, both stated already. Clipping was only ever tested with both sides cut or
neither, so a probe that opens both ends whenever either is clipped survived; the new
lower-only and upper-only cases kill it, and a third case proves the far side keeps openness
it already had rather than gaining it. The reverse strand flip was only asserted plus to minus
and inferred the other way through splicing; it is now asserted directly.

### Round 17 (2026-08-07) — and a fixture that could not tell two answers apart

Three suggestions: a child whose several parents each break a rule, one original interval that
already carries several bounds mixed with another of the same identifier, and `extract()` on a
model with no upper bound. All stated, so no prompt change.

The first one caught me writing a fixture that could not discriminate. With a single offending
parent, one row per feature and one row per offending parent look identical, so the probe that
switched the problem set to a list survived. Two parents breaking the same rule separate them,
and the probe dies. Same lesson as the type-sorted probe two rounds ago: when a probe lives,
suspect the fixture before the code. 181 tests, thirty-five probes, no survivors.

### Round 18 (2026-08-07) — the literal reading of three rules

An arbitrary strand token rather than only "." or a missing one, an unnamed interval that
already carries several bounds, and an explicitly given sequence of a different type deciding
what `spliced()` returns. All three are the literal reading of rules already in the prompt, so
nothing changed there. 185 tests, thirty-eight probes, no survivors.

### Round 19 (2026-08-07) — one suggestion had a fair half and two did not

The merged-bound phase question splits in two. Which interval supplies the phase after a join
is stated, so both strands are now tested: the lowest-starting interval leads on the plus
strand and the highest-ending one on the minus. What `phase_conflict` should say about a
stated phase whose bound no longer exists after merging is not stated, and is left alone.

Malformed `Parent` components, a missing `type` and an undersized explicit sequence were all
probed and left untested on purpose. The reference raises, returns `None` and slices short
respectively, but the prompt defines none of it, so a test would pin my choice rather than a
requirement. They are recorded in eval-results with what the reference does, so the next reader
does not have to re-derive it. 187 tests, thirty-nine probes, no survivors.

### Round 20 (2026-08-07) — what the round trip could not see

Two suggestions, both stated, both worth taking. The converted metadata had only ever been
checked through a round trip and through single keys, and a round trip cannot notice a missing
`strand`, because rebuilding the model from metadata that lacks one puts the plus strand back.
An exact dictionary for an unnamed feature, a named root and a named child now pins it, and the
probe that drops `strand` dies only against that test.

The other pins the half-open edge of `extract()`: a feature ending exactly at the region start,
or starting exactly at its end, is not reaching into it. 189 tests, forty-two probes, no survivors.

### Round 21 (2026-08-07) — a branch the cycle walk never took

Extraction with several parents, a cycle hidden behind a second branch, and derived conversion
leaving every source interval byte-identical. The cycle fixture needed rebuilding: my first
version gave every node one child, so a probe that walks only the first branch survived it.
Giving one node two children, with the cycle behind the second, kills the probe. 192 tests,
forty-five probes, no survivors.

### Round 22 (2026-08-08) — the FP check finally ran, and found two holes

Batch 2 passed some agents, so the check could run. Two flags, both confirmed by the panel,
and neither was a bug in my solution: a deep parent cycle and an extraction that drops a whole
coding span both already work in the reference. What was wrong was my suite, which never went
deeper than a three-feature cycle and never clipped outside the first transcription span, so an
agent could pass while violating the prompt.

Four tests close them, and I reproduced both agent shapes as mutants first so the tests are
known to discriminate: a recursive cycle walk dies on the 1100-feature ring, and a phase loss
read off the feature instead of the part dies on five extraction tests. 196 tests,
forty-seven probes, no survivors.

### Round 23 (2026-08-08) — Auto Review, and the one sentence seven agents read the other way

Batch 2 came back 2 of 10, in band, so the task is solvable and the batch-1 fixes held. Two
Auto Review reports asked for the same two revisions.

The substantive one: `cds_outside_exon` said a `CDS` bound "inside none of the exons beside
it", which never settled what happens when there are no exons beside it at all. Seven of the
eight failures read the empty set as non-containment and reported the problem. The reference
skips the check. The clause now ends "reported only where it has some", and two tests pin both
sides, one `CDS` with no exon sibling left alone next to a canary that does trip
`codon_length`, and one with an exon sibling correctly reported. The mutant that returns False
on an empty exon set, which is exactly what those seven wrote, now kills eleven tests.

The other was presentation: ten dense paragraphs became an opening paragraph and five bulleted
sections. No behavioural clause was dropped, and it still fits the word ceiling.

### Round 24 (2026-08-08) — derived intervals had no stated openness

Three suggestions. The first was a real gap: the openness rule said every interval written
keeps its bound's openness, but a derived intron or UTR is computed, not copied off a bound, so
the rule never reached it. The clause now reads "written off a bound keeps its openness,
derived ones closed", paid for by trimming six words elsewhere, and a test pins it. The other
two are free: `protein()` falling back on an RNA-backed model with a non-default genetic code,
and an unbounded model still rejecting a negative start and an empty range. 201 tests,
fifty-one probes, no survivors.

### Round 25 (2026-08-08) — the two description checks want opposite things

Description Quality failed the description for the very sections Auto Review had asked for:
the labels read as generated spec rather than engineer prose, and the motivational opening
delays the actionable requirement. Our own house rule agrees with Description Quality, since it
bans headers and formulaic labels outright.

Resolved by satisfying both. The bullets stay, so the contract is still scannable, which was
Auto Review's actual complaint; the three labels are gone, each bulleted group now hanging off
a sentence that carries real content. The opening motivation is cut, so the first sentence is
the task. "answers to" became "Support `len(model)`, ...", and "one row each, a feature's own
sorted by name" became "one row per problem, ordered by feature and then problem name". All
five comments addressed, no behavioural clause touched, and the word count fell from 869 to
840.

### Round 26 (2026-08-08) — the fairness check and the FP panel want opposite things

Test Fairness flagged the two 1100-feature graph tests as imposing an unstated stack-safety
scale that would reject a reasonable recursive implementation. That is exactly the
implementation the FP panel confirmed as a false positive two rounds ago: a recursive walk
raises `RecursionError`, not the `ValueError` the prompt promises, and the panel called the
resulting pass functionally undeserved.

Only one resolution satisfies both. Shrinking the fixture below the recursion limit, the
checker's other suggestion, reopens the FP the panel already confirmed. Stating the requirement
closes both: the `Parent` bullet now ends "raises `ValueError`, however long the chain of
parents", seven words, and the depth expectation is no longer hidden. No test or code change;
846 words.

### Round 27 (2026-08-08) — two more phase_conflict holes

Both flags landed on `check()`'s `phase_conflict`, both were coverage gaps rather than defects,
and both had the same root cause in the suite: every fixture was too small to separate a right
answer from a wrong one. `check()` had never been run on a feature whose fragments merge, and
no `phase_conflict` fixture had more than two spans, where phase from the previous span and
phase from all preceding spans give the same number.

Three tests close them, with the negative counterpart included so the sound cases cannot pass
vacuously. Both agent shapes were reproduced as mutants first: keeping absorbed fragment phases
kills one test, and taking the phase from the previous span alone kills three, of which only
the new three-span pair could ever have caught it. 204 tests, fifty-three probes, no
survivors.

## Validation

- new tests on base: 204 failed, 0 passed, no collection error
- new tests with the solution: 204 passed
- base mode: 887 passed, 28 skipped, before and after the solution
- both patch orders apply cleanly (test then solution)
- three consecutive runs of each mode give identical JUnit output
- fifty-three mutation probes, one per designed rule, all killed, no survivors
- FP walk found five orphaned prompt clauses, all closed with tests

## Open risks

1. **Description length.** 848 body words, above the largest approved submission at 789.
   Driven by the number of distinct described behaviors. Two members were cut to get here.
2. **Doctest baseline.** A bare `pytest` on the vanilla repo fails 57 doctests on numpy
   formatting. The Dockerfile provisions the two settings the repo's own runner sets, which
   makes the whole suite green. If the environment check installs its own dependencies it
   would see the 57 failures again.
3. **Pass rate unknown.** The traps are proven live by mutation, but only a real batch can
   say whether the rate lands under the 40 percent cap.
