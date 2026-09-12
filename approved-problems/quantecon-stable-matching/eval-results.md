# eval-results.md — quantecon-stable-matching

Base commit `13b436b8a43aa53313f6523509bd3f7a35d9dfd2` on QuantEcon/QuantEcon.py.

## Platform agent runs

No batch has been run yet.

| Agent | Evaluator | Verdict | Messages | Files | LOC | Failed tests | Failure reason | Approach |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| _pending_ | | | | | | | | |

## Local validation

| Check | Command | Result |
| --- | --- | --- |
| Environment Quality (vanilla tree, offline, uid 1000, no `.git`) | `python -m pytest` | 598 passed in 5m29s |
| F2P (test.patch only, on base) | `./test.sh --output_path ... new` | 303 tests, 303 failures, 0 errors |
| New tests with the solution | `./test.sh ... new` | 303 passed |
| Base suite with the solution, apply order test then solution | `./test.sh ... base` | 598 passed, 0 regressions |
| Base suite with the solution, apply order solution then test | `./test.sh ... base` | 598 passed, twice |
| New mode determinism | 3 consecutive runs | 303 passed each time, identical |
| Base mode determinism | 3 runs across both apply orders | 598 passed each time, identical |
| Patch hygiene | `git apply -R` both patches | both unapply cleanly |
| Effective LOC | `.claude/hooks/effective_loc_check.py solution.patch` | human-effective 674, raw 1334, 7 files |
| Encoding | `file solution.patch test.patch` | ASCII text, LF |
| `test.sh` mode | `grep "new file mode" test.patch` | 100755 |
| Banned markers | `grep -rE "shipd\|datacurve"` | none |
| Line length | new sources over 79 columns | none |

## Independent oracle cross-check

A brute force reference written from the definitions in the description, independent of the
solution.

| Model | Random markets | What was compared |
| --- | --- | --- |
| Two sided | 600 | blocking pairs and stability on the deferred acceptance result and on four random matchings each, the entire stable set with capacities one and with random capacities, proposer optimality, respondent optimality, join and meet closure over the whole stable set |
| One sided | 400 | the entire stable set, and blocking pairs plus stability on every matching of the market. A second brute force reference now also runs inside the test suite itself, on four one sided markets |
| Exchange | 300 | the top trading cycles allocation against the unique strict core allocation, brute forced over every permutation and every coalition |
| Serial dictatorship | 400 | against a direct transcription of the choosing rule |

Zero disagreements.

## Mutation battery

34 of 34 killed. The first battery of 22 left four survivors and four discriminating fixtures
were added for them; the last six mutations were added with the coverage advisory tests.

| Mutation | Killed by |
| --- | --- |
| mutual acceptability ignored | `test_deferred_acceptance_needs_mutual_acceptability` and 4 others |
| respondent uses its best partner instead of its least preferred | `test_blocking_pairs_displace_the_least_preferred_partner` (added) |
| a free place does not block | `test_blocking_pairs_free_place_always_blocks` |
| current partner not skipped | `test_blocking_pairs_empty_for_a_stable_matching` |
| capacity check dropped from `is_stable` | `test_is_stable_false_over_capacity_without_a_blocking_pair` |
| acceptability check dropped from `is_stable` | `test_is_stable_false_for_an_unacceptable_pair` |
| an unacceptable partner fills a place | `test_blocking_pairs_unacceptable_partner_fills_no_place` (added) |
| an unacceptable partner binds the proposer | `test_blocking_pairs_unacceptable_partner_frees_the_proposer` |
| rows returned in discovery order | `test_stable_matchings_sorted_when_the_optimal_is_not_first_found` (added) |
| blocking pairs not sorted | `test_blocking_pairs_sorted_lexicographically` |
| pessimal partner excluded from the search | `test_stable_matchings_three_by_three` |
| join and meet swapped | `test_matching_join_of_the_two_optimal_matchings` |
| unmatched counts as best | `test_matching_join_treats_unmatched_as_worst` |
| roommate acceptability ignored | `test_stable_roommate_matchings_one_sided_acceptability` |
| roommate returns one matching | `test_stable_roommate_matchings_four_agents` |
| roommate pair order reversed | `test_roommate_blocking_pairs_smaller_index_first` |
| roommate symmetry check dropped | `test_roommate_blocking_pairs_rejects_an_asymmetric_matching` |
| a retired house stays in the market | `test_top_trading_cycles_a_retired_agent_takes_its_house_away` (added) |
| cycle members keep their own house | `test_top_trading_cycles_single_cycle` |
| choosing order ignored | `test_serial_dictatorship_follows_the_order` |
| `respondent_optimal` ignores capacities | `test_respondent_optimal_with_caps` |
| `deferred_acceptance` ignores capacities | `test_deferred_acceptance_caps_fills_places` |
| `caps` length check dropped | `test_blocking_pairs_caps_wrong_length` and 3 others (added) |
| `caps` positivity check dropped | `test_is_stable_caps_must_be_positive` and 3 others (added) |
| repeated preference check dropped | `test_deferred_acceptance_rejects_a_repeated_respondent_entry` and 4 others (added) |
| matching range check dropped | `test_matching_meet_rejects_an_out_of_range_entry` and 5 others (added) |
| endowment range check dropped | `test_top_trading_cycles_rejects_an_out_of_range_endowment` (added) |
| choosing order range check dropped | `test_serial_dictatorship_rejects_an_out_of_range_order` (added) |
| retirement not repeated to a fixed point | `test_top_trading_cycles_retirement_cascades_downwards` (added) |
| preference range check dropped | `test_deferred_acceptance_rejects_out_of_range_proposer_entry` and 6 others (added) |
| self listing check dropped | `test_roommate_blocking_pairs_rejects_self_reference` and 2 others (added) |
| matching result not an integer array | `test_deferred_acceptance_returns_a_one_dimensional_integer_array` and 3 others (added) |
| enumeration result not an integer array | `test_stable_matchings_returns_a_t_by_m_integer_array` and 3 others (added) |
| allocation result not an integer array | `test_top_trading_cycles_returns_a_one_dimensional_integer_array` and 1 other (added) |

## False positive check

Every public return was wrapped so that arrays come back as `int32` and truth values as
`np.bool_`, both permitted by the description and neither promised by it. All 275 tests still
pass, so nothing in the suite pins a dtype, a container type or Python bool identity. Two tests
were relaxed during this walk: fourteen `is True` and `is False` identity assertions became
truthiness assertions, and a test that asserted the proposer optimal matching is the first row
now asserts membership instead.

## Coverage advisories (all five addressed)

The AI check returned five advisory coverage suggestions and one WARNING. Each advisory was first
traced to a sentence already in the description, so that taking it added a test rather than a
requirement; the two places where the description was thinner than the implementation were
corrected instead of being tested around.

| Advisory | Response |
| --- | --- |
| invalid `caps` on the four entry points other than `deferred_acceptance` | 8 tests added. The description already states the `caps` contract once, for every routine that takes it. |
| duplicate preferences on respondent, roommate and house rows | 5 tests added. The description already covers every preference list with one sentence. |
| join and meet validation symmetry | 10 tests added, covering wrong length, out of range and below `-1` in both argument positions of both routines. |
| permutation bounds for `endowment` and `order`, including negatives | 4 tests added. |
| roommate matching bounds for `roommate_blocking_pairs` and `is_roommate_stable` | 6 tests added. The one sided sentence only described the shape, so it was tightened to state the same length and range rule the two sided sentence already carried. |

**WARNING fixed.** The last paragraph attached the `endowment` constraint to
`serial_dictatorship`, which has no `endowment` parameter. The constraint now sits in the
`top_trading_cycles` sentence and the `serial_dictatorship` sentence keeps only the `order` rule.
No test changed as a result; the behaviour was always correct and already covered.

## Second round of coverage advisories (all three addressed)

| Advisory | Response |
| --- | --- |
| cascading top trading cycles retirement | 3 tests added. The description already says retirement repeats "until no more can be retired". One fixture cascades in increasing index order, one in decreasing order so a single forward pass is not enough, and one leaves a real cycle to run once the cascade finishes. A mutation that caps the retirement loop at one pass is now killed. |
| malformed preferences across every API | 12 tests added, covering out of range and repeated preference entries through `respondent_optimal`, `blocking_pairs`, `is_stable`, both join/meet preference inputs and `is_roommate_stable`. For join and meet the "side" is only known from the lists themselves, so the observable out of range case is a negative index, and that is what is tested. |
| roommate enumeration uniqueness | 1 test added, asserting 16 distinct rows on a four block market, matching the existing two sided uniqueness test. |

## Third round of coverage advisories (all three addressed)

| Advisory | Response |
| --- | --- |
| `is_stable` matching validation | 3 tests added for wrong length, an out of range entry and an entry below `-1`. The rule was stated only inside the `blocking_pairs` paragraph, so the sentence was widened to name both routines rather than testing a rule the prompt attached elsewhere. |
| self referential roommate preferences on the other two entry points | 2 tests added, through `roommate_blocking_pairs` and `is_roommate_stable`. The no self listing rule was already stated for the one sided market as a whole. A mutation dropping the check is now killed. |
| respondent optimal on an incomplete and unbalanced market | 5 tests added on `prop=[[0], [0, 1], [1, 0]]`, `resp=[[2, 1, 0], [1, 2]]`: three proposers, two respondents, one incomplete list, two stable matchings, and a proposer that has a mutually acceptable partner yet is unmatched in both. Pure coverage, no requirement added. |

## Fourth round of coverage advisories (two taken, one declined)

| Advisory | Response |
| --- | --- |
| top level integration | 2 tests added: `quantecon.matching` is present straight after `import quantecon as qe`, and all twelve entry points are callable attributes of it. The export set is asserted by containment, not equality, so an implementation that also exposes helpers still passes. |
| array-like inputs | 10 tests added: preferences as a two dimensional array, as a ragged list of one dimensional arrays and as an empty two dimensional array; matchings, capacities, choosing orders and endowments as arrays, three of them as deliberately non-contiguous slices; roommate preferences and roommate matchings as arrays. All of these already worked, since every input goes through `np.asarray`, and the description already calls these inputs sequences and arrays. |
| capacity type validation | **Declined as a test, taken as a prompt fix.** The advisory is conditional on non-integral capacities being intended as invalid, and they are not. Today `caps=[2.7, 1]` is silently truncated to `[2, 1]` and `caps=[0.5, 1]` truncates to zero and raises. Pinning either reaction would be wrong: asserting truncation freezes an arbitrary internal choice, and asserting rejection adds a requirement that the obvious `np.asarray(caps, dtype=int)` fails, for a rule with no behavioural value. The ambiguity the advisory found was real but it was in the prose, so `caps` is now described as "one strictly positive integer per respondent". That states the valid input without promising any particular reaction to input outside it, and no test was added. |

## Fifth round of coverage advisories (two taken, two declined)

| Advisory | Response |
| --- | --- |
| allocation preference validation | 3 tests added: a negative house through `top_trading_cycles`, and an out of range and a negative house through `serial_dictatorship`. The description already applies the preference list rule to every list, and houses are numbered like the agents, so this is stated coverage. |
| return array contract | 10 tests added asserting integer dtype and exact shape for all twelve entry points, including the `(0, 2)`, `(t, m)` and `(t, n)` cases. Three mutations returning float arrays were added and are killed. The assertion is on the dtype KIND (`np.issubdtype(..., np.integer)`), never on a width, so the false positive probe that returns `int32` still passes; asserting `int64` would have pinned a width the description does not promise. |
| integer validation of non-integral inputs | **Declined again, for the same reason as the fourth round.** `np.asarray(x, dtype=int)` truncates silently, so `caps=[2.7, 1]` becomes `[2, 1]` and a preference of `0.9` becomes `0`. There is no obvious correct reaction to a non-integral index: truncating, rounding and rejecting are all defensible, so any assertion here pins one arbitrary choice and fails the other two. The description already states the valid input domain (integer indices, strictly positive integer capacities) and no test exercises anything outside it. Booleans need no special handling: `True` is an integer and a capacity of `True` is a capacity of one, which is consistent with the stated contract. |
| array dimensionality | **Declined.** The advisory asks that a `(n, 1)` or `(1, n)` input be rejected, but the description never requires that: it says the RESULT is a one dimensional array, and describes each input by the entries it must hold. Today such an input is flattened and accepted. Rejecting it would be a new requirement and a solution change for no behavioural gain, and asserting that it is flattened would pin the opposite arbitrary choice. Left outside the specified domain, exactly like non-integral values. |

## Sixth round of coverage advisories (two taken, one declined)

| Advisory | Response |
| --- | --- |
| one sided asymmetric validation | 2 tests added. `is_roommate_stable` now has its own asymmetric matching test, matching the one `roommate_blocking_pairs` already had, plus an overlong matching. The rule is stated once for every one sided matching, and both routines share the same validator, but only one of them was exercising it. A real gap. |
| length edge cases | 3 tests added: an overlong `order`, an overlong `endowment` and an overlong `caps`. The existing tests only used short vectors, and each rule ("every agent exactly once", "a distinct house per agent", "one entry per respondent") is violated by an overlong vector just as much as by a short one. |
| non integer `caps`, and non integral inputs generally | **Declined for the third time.** The reasoning has not changed: `np.asarray(x, dtype=int)` truncates, so `caps=[2.7, 1]` becomes `[2, 1]`, and truncating, rounding and rejecting are all defensible reactions to a non integral index. Any assertion here freezes one of the three and fails implementations that chose either other one, for a rule with no behavioural content. The description states the valid domain and no test goes outside it. |

## Seventh round of coverage advisories (three taken, one declined, one prompt defect fixed)

The integer advisory was right about something, just not about the test. Chasing it a fourth time
found a real defect that the previous three rounds had missed.

**The prompt defect.** The fourth round tightened the capacity sentence to read "must hold one
strictly positive **integer** per respondent, or `ValueError` is raised". That sentence structure
promises rejection of a non-integral capacity, and the code truncates `2.7` to `2` instead. The
description was making a promise the solution does not keep, which is the same class of mismatch
the false positive check exists to find. Both that sentence and the matching sentence now enumerate
exactly the violations that are checked, so "integer" describes the domain without promising a
reaction outside it. No test and no requirement was added, and the contradiction is gone.

| Advisory | Response |
| --- | --- |
| roommate enumeration cross-check | 4 tests added. A second brute force reference, written from the definitions and independent of the solution, now lives in the test file and is compared against on four markets: the four agent market, an incomplete five agent market, the odd market, and the market with no stable matching at all. |
| TTC custom endowment retirement | 2 tests added on `prefs=[[], [1, 2], [0]]` with `endowment=[1, 2, 0]`, giving `[-1, 2, 0]`. The retiring agent owns house 1, not house 0, so an implementation that removes the retiree's index rather than its endowed house gets `[-1, 1, -1]`, which is the second test, run under the identity endowment for contrast. |
| capacity enumeration breadth | 6 tests added on `prop=[[1, 0], [0, 1], [0, 1], [0]]`, `resp=[[0, 2, 1], [3, 1, 2, 0]]`, `caps=[2, 1]`: a capacity of two, an incomplete list, a non mutual pair, a proposer unmatched in every stable matching, and two stable matchings. Every row is cross checked against the in-test reference and against `is_stable`. This market also has the proposer optimal matching as its LAST row, so it independently guards the sorted order rule. |
| integer validation of non-integral inputs | **Declined for the fourth time**, as a test. The reasoning is unchanged and is now also reflected in the prompt: truncating, rounding and rejecting are all defensible reactions, so any assertion pins one and fails the other two. |

## Test Fairness (one FAIL, cleared)

| Round | Verdict | Finding | Fix |
| --- | --- | --- | --- |
| first | **FAIL**, 5 of 147 unfair | The return-contract tests asserted an integer dtype for `blocking_pairs`, `stable_roommate_matchings`, `roommate_blocking_pairs`, `top_trading_cycles` and `serial_dictatorship`, but the description only used the word "integer" for the two sided matching. The shape halves of those tests were judged fair. | One sentence added to the opening paragraph stating that every array the subpackage returns holds integers, plus the `(k, 2)` and `(0, 2)` shapes now stated for roommate blockers. Prompt only: no test and no solution line changed, and both patches are byte identical across the fix. |

The assertions were kept rather than removed because three float-returning mutations
(`matching-result-not-integer`, `enumeration-result-not-integer`,
`allocation-result-not-integer`) are killed by them, and the allocation one has no other killer.

## Eighth round of coverage advisories (one taken, two declined)

| Advisory | Response |
| --- | --- |
| roommate blocker empty shape wording | **Taken as a prompt fix.** The advisory asked that `(0, 2)` be stated explicitly for roommate blockers as it already was for the two sided routine, since the suite asserts it. Done in the same edit that cleared the fairness FAIL. |
| strict integer validation | **Declined, fifth time.** |
| boolean and floating capacities | **Declined**, same question in another form. `[1.5, 1]` is truncated to `[1, 1]` today, and `True` is an integer so `[True, 1]` is a capacity of one. Asserting rejection would add a requirement that the natural `np.asarray(caps, dtype=int)` fails; asserting truncation would freeze an arbitrary choice. The prompt states the valid domain and no test leaves it. |

## Ninth round of coverage advisories (one taken, one declined)

| Advisory | Response |
| --- | --- |
| general stable enumeration scalability | **Taken, and the criticism was right.** The 4096 row family was twelve INDEPENDENT two by two blocks, so a solver that split the market into connected components and multiplied the per component answers would have sailed through it without ever handling a market as a whole. Three things were added. First, `linked_market(k)`: the same 2^k stable set, but every agent now ranks every partner, so the acceptability graph is complete and there is nothing to decompose. The count stays provable because each agent strictly prefers both of its block partners to every outsider, which forces every stable matching to pair inside the blocks. Verified at k = 1, 2, 3, 4 and used at k = 12 (4096 rows over 24 proposers, 0.5 s) and k = 8 (all 256 rows checked stable). Second, a five proposer market with seven stable matchings and a six proposer market with ten, both from random complete preferences and therefore genuinely interacting, each compared row for row against the in-test brute force reference (the six proposer comparison enumerates 117649 assignments in 0.24 s). Third, the six proposer market has its proposer optimal matching at row 5 and its respondent optimal at row 2, so neither extreme is the first or the last row, which guards the sorted order rule from a market where the two happen to coincide with the ends. |
| integer validation | **Declined, sixth time.** |

## F2P regression caught during this round

The F2P run reported 265 failures out of 266 rather than 266 of 266. The passing test was
`test_linked_market_lists_are_complete`, which only asserted a property of the fixture helper and
never called the package, so it passed on the base commit where `quantecon.matching` does not
exist. It now also asserts the enumeration shape on that market. Every one of the 266 tests fails
on base, and the run prints an explicit empty list of base-passing tests.

## Tenth round of coverage advisories (one taken, two declined)

| Advisory | Response |
| --- | --- |
| two sided no-respondent enumeration | 5 tests added. `stable_matchings([[], []], [])` is `[[-1, -1]]` with shape `(1, 2)`, and the same market is now also exercised through `respondent_optimal`, `blocking_pairs`, `is_stable` and `matching_join`. Deferred acceptance already covered the boundary; the other extremal and enumeration routines did not. |
| non integer index validation, and capacity integer type | **Declined, seventh time.** Unchanged reasoning. One wording change did come out of it: the sentence added in the fairness fix read "Everything here is index data, so every array these routines return holds integers", and the opening clause invited the reading that inputs are validated for integer-ness. It now reads simply "Every array these routines return holds integers", which is the return contract the fairness check actually needed and nothing more. |

The recurring integer advisory has produced two real prompt corrections across ten rounds (the
capacity sentence that promised a rejection the code does not perform, and now this clause) while
never producing a test. That is a reasonable trade: the advisory keeps pointing at wording that is
doing more work than intended, even though the test it asks for would pin an arbitrary choice.

## Test Fairness, second FAIL (cleared)

| Round | Verdict | Finding | Fix |
| --- | --- | --- | --- |
| second | **FAIL**, 1 of 271 unfair | `test_stable_roommate_matchings_large_block_family` enumerated a 24 agent one sided market. The count 64 follows from the stated semantics, but the market size implicitly requires a non brute force ROOMMATE enumerator, and the prompt's scale qualifier ("filtering all the ways of pairing the two sides is not a usable route") is written about proposers, so it only binds the two sided routine. | The test was removed. The largest remaining one sided market is 16 agents, which the check itself judged acceptable. Nothing was added to the prompt, because extending the scale requirement to the one sided routine would be a genuine new requirement rather than a wording fix, and the one sided difficulty lives in correctness (the no stable matching case, symmetry, unacceptable partners) rather than in scale. |

The two sided scale requirement is untouched: the connected 4096 row market over 24 proposers is
explicitly in the prompt and remains the anti brute force guard.

## Eleventh round of coverage advisories (both taken)

| Advisory | Response |
| --- | --- |
| roommate blocking with an unacceptable current partner | 3 tests added, and this needed a prompt fix first. The two sided paragraph states that a partner an agent does not accept counts as no partner at all; the one sided paragraph did not, yet the code applies the same rule and it is observable, because the roommate matching validator checks symmetry rather than acceptability. The one sided paragraph now says it too. |
| serial dictatorship with an empty preference row | 2 tests added, one where the agent with the empty row chooses first and one where it chooses second, both confirming it takes nothing while the later agents choose normally. |

## Advisories after the hardening round (one taken, two declined)

| Advisory | Response |
| --- | --- |
| capacity enumeration scalability | 4 tests added. The scale sentence covers `stable_matchings`, which takes `caps`, but every large market in the suite was one to one. `capacity_blocks(k)` replicates the three by two capacity market as independent blocks, giving 2^k stable matchings under capacities `[2, 1]` per block: 4096 rows over 36 proposers in about a second, plus exact rows at k = 2 and a k = 6 market where every row is checked stable and every respondent is checked to fill the same number of places in every row. |
| egalitarian unmatched-cost semantics | **Declined, and the fixture the advisory asks for cannot exist.** It wants a market where the rule that unmatched agents contribute nothing changes which stable matching has the smallest total. By the rural hospitals theorem the same agents are unmatched in EVERY stable matching, so the unmatched contribute the same amount to every candidate total and can never change the ranking between them. Measured as well as argued: over 4000 random markets with incomplete lists the unmatched set differed across stable matchings exactly zero times. The clause stays in the prompt because it fixes how the total is computed, but it is definitional rather than discriminating, and `test_egalitarian_unique_and_empty_markets` already exercises it on a market with an unmatched proposer. |
| integer type validation | **Declined, ninth time.** |

## Final advisory round (one taken, one declined)

| Advisory | Response |
| --- | --- |
| egalitarian preference validation symmetry | 2 tests added. The only bad-list test for this routine corrupted a proposer row, so a duplicate and an out of range entry in a RESPONDENT row are now exercised too. Covered by the global preference rule, which applies to both sides. |
| integral input validation | **Declined, tenth time.** The prompt states the valid domain and every `ValueError` sentence enumerates exactly the violations the code checks, so there is no promise to keep here. Truncating, rounding and rejecting a non integral index are all defensible, and any assertion pins one of the three. |

## Last advisory round (one taken, two declined)

| Advisory | Response |
| --- | --- |
| empty-output integer dtype | 1 test added covering the degenerate shapes in one place: the zero length results of `deferred_acceptance`, `respondent_optimal`, `egalitarian_stable_matching`, `top_trading_cycles` and `serial_dictatorship`, the `(1, 0)` results of both enumerators on an empty market, the `(0, 4)` result when no roommate matching exists, and both empty blocker arrays. The already-covered empty cases were the `(0, 2)` and `(0, 4)` ones; the zero-size shapes were the genuine hole. |
| integer type validation, and capacity element type | **Declined, eleventh time**, same reasoning. |

`solution.patch` is byte identical across this round (md5 `bcd43c18fe62248fe74c1f15a821c5fe`), and
base mode ignores the new test file, so the base suite result carries over from the previous round
rather than being re-measured.

## Test Fairness, third FAIL (cleared)

| Round | Verdict | Finding | Fix |
| --- | --- | --- | --- |
| third | **FAIL**, 10 of 39 unfair | The ten array-like input tests (two dimensional arrays, a ragged list of arrays, non contiguous views for matchings, capacities, orders and endowments) required a container compatibility the description never promised. It said only "sequence", and the check pointed out that neighbouring QuantEcon APIs write `array_like` when they mean it, citing `game_theory/normal_form_game.py:142` and `game_theory/utilities.py:83-90`. | One clause in the opening paragraph: every argument described as a sequence is `array_like` in the usual sense of the library, so a NumPy array works wherever a list does. Prompt only; no test and no solution line changed. |

**These ten tests exist because an earlier coverage advisory asked for them**, which is the tension
the playbook warns about: advisories are graded against what a good API should do, the fairness
check against what the prompt actually promises. The resolution is not to keep adding and deleting
tests each round but to make the prompt say what the code does, which it now does and which also
matches the repository's own documented convention.

Deleting the ten tests was the alternative and would also have cleared the FAIL, with the small
side benefit that fewer isolated tests is better for difficulty. It was rejected because the
implementation genuinely accepts `array_like` everywhere, so removing the tests would have left a
real behaviour unstated and unmeasured rather than fixing the description.

## Egalitarian validation symmetry (taken)

2 more tests: a negative and an out of range entry in a PROPOSER row for
`egalitarian_stable_matching`, which previously only had duplicate and respondent side cases.
The integral input advisory was declined for the twelfth time, unchanged.
