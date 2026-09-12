# feedback.md — quantecon-stable-matching

## Summary

Olympus submission on [QuantEcon/QuantEcon.py](https://github.com/QuantEcon/QuantEcon.py)
(MIT, 2386 stars, Python), base commit `13b436b8a43aa53313f6523509bd3f7a35d9dfd2`, which was
`main` HEAD at pick time.

Adds a `quantecon.matching` subpackage covering three market models: two sided stable matching
with capacities (`deferred_acceptance`, `respondent_optimal`, `blocking_pairs`, `is_stable`,
`stable_matchings`, `matching_join`, `matching_meet`, `egalitarian_stable_matching`, `minimum_regret_stable_matching`), one sided stable matching
(`stable_roommate_matchings`, `roommate_blocking_pairs`, `is_roommate_stable`) and allocation of
indivisible goods (`top_trading_cycles`, `serial_dictatorship`).

**674 human-effective LOC** across 7 files (6 new, 1 modified), **303 new tests**, all failing on
base with zero collection errors. Base suite 598 tests, green offline as uid 1000.

Every output is exact integer data. No tolerance and no RNG appear anywhere in the suite.

## Pick rationale

The standing preference is a fresh repo, so about half the session went to screening. Roughly
fifty candidates were checked against the pick gates on platform metadata first (primary language
and SPDX id), then on environment. What killed them:

| Candidate | Killed by |
| --- | --- |
| biotite | `setuptools-rust` + Cython build and `tests/database` reaches the network (already recorded in Task42) |
| pymoo | `tests/test_docs.py` imports `jupytext` at module scope and then executes every docs notebook |
| verde | `verde/tests/test_datasets.py` fetches sample data over the network, so the vanilla suite is red offline |
| textX | commit `2c780a1`, one before HEAD, is "detect non-consuming repetitions at metamodel construction", which is the live version of the grammar-analysis pick that was being designed; also HEAD needs an Arpeggio that is not on PyPI |
| optiland | already dropped in Task34 (PR #436, 717 PRs against 843 stars); PRs #203 and #342 have shipped temperature dependent indices |
| NURBS-Python, python-acoustics, poliastro | last commit older than 12 months or archived |
| hmmlearn | last commit 2024-10-31, fails the activity gate |
| pyGAM, pysindy, PyDMD, river, aeon, adaptive | the natural feature is "add another member of an existing plug-in family", which is the triviality auto-RED |
| Pyomo, pint, HyperNetX, scikit-network, deepdiff, lmfit, quimb, WNTR | `license.spdx_id` is NOASSERTION |
| movingpandas | trajectory generalisation, simplification and Frechet distance are the shape we shipped last week in `pyriemann-geodesic-curves` |
| mesa, pyroomacoustics, PyBaMM, PyPSA, sunpy, qutip | already recorded as dead in memory or in `rejected/` |

QuantEcon won because computational economics is the "obscure to problem authors" profile,
the environment recipe was already proven (`rejected/quantecon-average-reward-dp-OLD-REPO`), and
matching markets are a large, genuinely missing subsystem there.

## Exclusivity (SIX-CHECK)

Canonical slug confirmed `QuantEcon/QuantEcon.py`, no redirect. PR and issue search over all
states for `matching`, `deferred`, `stable`: zero hits on the feature class; the only PRs that
mention "stable" are about de-flaking timing tests. `gh search code` for `deferred_acceptance` and
`stable_matching`: zero. All 11 non-main branches enumerated with `compare/main...<branch>`; they
touch `optgrowth`, docs, `random/utilities`, `kalman`, `lqcontrol`, `polymatrix_game`,
`util/notebooks` and `util/numba`, none of them matching.

Local dedup across `Aprroved/`, `problems/`, `rejected/`, `_shelved/` and every `TaskN/problems/`
by feature class: nothing about matching markets. The one prior QuantEcon artifact is average
reward dynamic programming on `DiscreteDP` and `MarkovChain`, a different subsystem sharing no
machinery, and it is shelved.

## Environment

`python -m pytest` on the vanilla tree, offline, uid 1000, no `.git`: **598 passed in 5m29s**.
The only two failures in the untouched repo are in `quantecon/util/tests/test_notebooks.py`, which
downloads a file from github.com on every run; the Dockerfile removes that file with a comment
giving the reason. Nothing else in the suite reaches the network.

## Why it is hard

The definitions are all classical, so nothing here is knowledge-hard. The difficulty is in
composing rules that share one chokepoint, so that fixing one regresses another:

1. **Acceptability is mutual.** Listing a partner is not enough, the partner must list you back.
   This rule is shared by all twelve entry points, so a one sided reading leaves
   `deferred_acceptance` correct on complete lists and only shows up in the enumeration and
   blocking pair results.
2. **A partner an agent does not accept counts as no partner at all.** It frees the proposer to
   block, it fills no place at the respondent, and it is never the respondent's least preferred
   partner. Three separate consequences of one sentence, each observable through a different
   entry point.
3. **`is_stable` is not "no blocking pair".** It also demands mutual acceptability of matched
   pairs and respects capacities. Two fixtures have an empty blocking pair array and are still
   unstable.
4. **Capacity blocking uses the least preferred current partner**, and a free place blocks
   unconditionally.
5. **The matched set is the same in every stable matching**, so enumeration must not emit a row
   that leaves a proposer unmatched when the proposer optimal matching matches it.
6. **Enumeration cannot be brute forced.** The product family has 4096 stable matchings over 24
   proposers, so filtering every way of pairing the two sides never returns.
7. **Row order is lexicographic**, and one fixture is built so that the proposer optimal matching
   is the last row rather than the first, which kills implementations that return discovery order.

## Validation

- **Independent oracle.** A brute force reference written from the definitions alone, not from the
  solution, over 600 random two sided markets (incomplete lists, capacities up to two, arbitrary
  and deliberately irrational matchings), 400 random one sided markets and 300 random exchange
  markets. It checks blocking pairs, stability, the whole stable set, proposer and respondent
  optimality, lattice closure, and for `top_trading_cycles` the unique strict core allocation
  brute forced over every permutation and every coalition. All agree exactly.
- **Mutation battery: 34 of 34 killed.** Mutual acceptability dropped on either side, best instead
  of least preferred partner, free place not blocking, current partner not skipped, capacity check
  dropped, acceptability check dropped, unacceptable partner filling a place, unacceptable partner
  binding the proposer, rows unsorted, pairs unsorted, pessimal partner excluded from the search,
  join and meet swapped, unmatched counting as best, roommate acceptability ignored, roommate
  returning one matching, roommate pair order reversed, roommate symmetry check dropped, retired
  house left in the market, cycle members keeping their own house, choosing order ignored,
  `respondent_optimal` ignoring capacities, `deferred_acceptance` ignoring capacities.
  The first battery left four survivors and four discriminating fixtures were added for them.
- **FP check clean.** Every public return was wrapped to come back as an `int32` array or a
  `np.bool_`, both of which the description permits and neither of which it promises. All 275
  tests still pass, so no test pins a dtype, a container or Python bool identity. The description
  was then walked clause by clause against the tests in both directions.
- **Full matrix.** F2P 303 failures out of 303 with zero errors on base; 303 passed with the
  solution; base 598 passed with the solution applied, in both apply orders; new mode identical
  across three repeats; base mode identical across three runs; both patches unapply cleanly.

## Attempt history

| Round | What changed | Result |
| --- | --- | --- |
| 1 | Repo screening | about fifty candidates, eleven killed after real work; QuantEcon picked |
| 2 | First implementation (two sided + roommates) | 348 human-effective, under the floor |
| 3 | Capacities in the enumerator, top trading cycles, serial dictatorship, `respondent_optimal` | 467 human-effective |
| 4 | Oracle cross-check | two hand written fixture expectations were wrong, the code was right |
| 5 | Mutation battery | 18 of 22 killed, four fixtures added, then 22 of 22 |
| 6 | FP alignment walk | `is True` and `is False` identity assertions relaxed, one test that pinned an unstated row position changed to a membership check |
| 7 | AI check response | five coverage advisories taken as 33 more tests, one description WARNING fixed, six more mutations added; 187 tests, 28 of 28 killed |
| 8 | Second AI check response | three more advisories taken as 16 more tests, two more mutations added; 203 tests, 30 of 30 killed |
| 9 | Third AI check response | three more advisories taken as 10 more tests, one description sentence widened to cover `is_stable`, one more mutation added; 213 tests, 31 of 31 killed |
| 10 | Fourth AI check response | two advisories taken as 12 more tests, one declined on purpose with the prompt tightened instead; 225 tests |
| 11 | Fifth AI check response | two advisories taken as 13 more tests and 3 more mutations, two declined as out-of-domain input; 238 tests, 34 of 34 killed |
| 12 | Sixth AI check response | two advisories taken as 5 more tests, the non-integral input request declined for the third time; 243 tests |
| 13 | Seventh AI check response | a real prompt defect found and fixed (the capacity sentence promised a rejection the code does not perform), three advisories taken as 12 more tests including a roommate brute force reference; 255 tests |
| 14 | Test Fairness FAIL cleared | 5 dtype assertions were unstated; the integer-array contract is now stated once for the whole subpackage and the roommate blocker shape is stated. Prompt only, no test or solution change |
| 15 | Eighth AI check response | scale advisory taken: a connected 4096-row market and two exhaustively verified interacting markets, 11 more tests; F2P caught a fixture-only test that passed on base |
| 16 | Ninth AI check response | no-respondent boundary taken as 5 more tests; the integer-array sentence narrowed to the return contract it was added for; 271 tests |
| 17 | Second Test Fairness FAIL cleared | the 24-agent roommate market imposed a scale requirement the prompt only makes for the two-sided enumerator; that test removed. Two advisories taken as 5 more tests, one of which needed the one-sided unacceptable-partner rule stated; 275 tests |

## Test Fairness

The Test Fairness check FAILED once, at 5 of 147 tests, and the finding was correct. The round
that added return-contract tests asserted an integer dtype on all twelve entry points, but the
description only called the TWO SIDED MATCHING an integer array. For `blocking_pairs`,
`stable_roommate_matchings`, `roommate_blocking_pairs`, `top_trading_cycles` and
`serial_dictatorship` it said "array" and nothing more, so those five assertions pinned a
representation the prompt never promised.

The fix is one sentence in the opening paragraph: "Everything here is index data, so every array
these routines return holds integers." That covers all twelve entry points at once and removes an
inconsistency that was in the prose rather than in the tests, since the two sided sentence had
carried the word "integer" from the start. The roommate blocker paragraph also now states its
`(k, 2)` and `(0, 2)` shapes, which the suite was already asserting by analogy with the two sided
routine. No test and no solution line changed; `solution.patch` and `test.patch` are byte
identical across the fix.

Keeping the assertions rather than deleting them was deliberate. Three mutations that return float
arrays are killed only by those tests, and dropping the allocation one would have left
`allocation-result-not-integer` alive.

## AI check response

The check returned "Problem and tests are good quality" with one WARNING and five advisory
coverage suggestions.

The WARNING was real: the closing paragraph attached the `endowment` constraint to
`serial_dictatorship(prefs, order)`, which takes no `endowment`. The constraint moved into the
`top_trading_cycles` sentence. Nothing in the code or the tests was wrong, only the prose.

Each of the five advisories was checked against the description before being taken, because an
advisory that is not already stated adds a requirement rather than coverage. Four of them named
rules the description already stated once for every routine that shares them, so they became
tests directly. The fifth, roommate matching bounds, named a rule the one sided paragraph only
implied while the two sided paragraph stated it outright, so that sentence was tightened to
match. 33 tests were added, and six mutations were added to prove they are load-bearing.

## Open items

No platform agent batch has been run yet. The predicted band is 10 to 30 percent.


## Hardening after a 100 percent Nova batch

Every Nova run solved the first artifact, which is a too-easy reject. The diagnosis was not that
the problem needed more rules. All twelve entry points were independently implementable, the
algorithms were classical, and every trap was stated in the prompt, which is precisely the
contract-stated AND fix-stated shape that `HARDENING.md` records as dead. The eleven advisory
rounds had also grown the suite to 275 mostly isolated behavioural tests, and the same file warns
that test-count padding RAISES pass rate.

The fix is one new entry point whose contract is a single sentence but whose correct
implementation is a discovery: `egalitarian_stable_matching`, the stable matching with the
smallest total rank. Both natural shortcuts fail.

- **Enumerate and take the smallest.** Dead by scale: the connected market of 30 blocks has
  2^30 stable matchings and the prompt puts markets of that size in scope, so the answer has to
  come out of structure rather than a scan. It returns in hundredths of a second here.
- **Improve the proposer optimal matching one helpful step at a time.** Dead by correctness, and
  this is the interesting one. On the six-agent LOCKED market the rotation weights are `[1, -3]`
  with the helpful rotation locked behind the costly one, so a solver that takes only the
  improving steps returns total 17 while the optimum is 15. What it returns IS a stable matching,
  so it passes `is_stable`, every enumeration test and every lattice property; only the value is
  wrong. Misdirecting by construction.

The correct route is the rotation poset plus a minimum weight closed subset, which is a min-cut.
Stating the contract does not reveal any of that, so the trap is alive under
CONTRACT-STATED / FIX-HIDDEN.

Effective LOC rose from 467 to 649 across 7 files, and the suite went from 275 to 284 tests: nine
added, deliberately few, because more isolated tests would work against the difficulty.


## Second hardening pass: a competing objective

`minimum_regret_stable_matching` was added: the stable matching whose LARGEST single rank is as
small as possible, against the egalitarian one that minimises the TOTAL. The two are genuinely
different objectives, not a rewording. Measured over 3000 random markets they disagree in 250, and
one six-agent fixture now has all four routines returning four different matchings: deferred
acceptance `[0,2,3,1,4,5]`, respondent optimal `[4,5,2,3,0,1]`, egalitarian `[0,5,3,1,4,2]` and
minimum regret `[4,5,3,1,0,2]`. The last two even share a total of 20, and the regret answer gets a
largest rank of 3 where the egalitarian one gets 4, so returning either for the other is caught.

The two objectives also cannot share an implementation shortcut. Enumerating and taking an argmin
dies for both on the market with 2^30 stable matchings. The egalitarian answer needs the rotation
poset and a minimum weight closed subset; the regret answer does not, but it has its own trap.

**The regret trap.** The natural route is to delete every pair either side ranks worse than a
threshold and run deferred acceptance on what is left, raising the threshold until something comes
out. That produces a matching which is NOT always stable in the original market, so the result has
to be re-checked against the full market before it is accepted. `TRAP_PROP`/`TRAP_RESP` is a six
agent market where the reduced-market answer `[-1,2,0,4,1,5]` is unstable while the correct answer
is `[-1,4,0,2,1,5]`; both are pinned, and the unstable one is asserted unstable through the public
`is_stable`. That market was found by searching for a separator, not by intuition.

A guard that no mutation could kill was also removed rather than kept: the matched-set size check
in the regret loop survived 40000 random markets without ever changing an answer, so it was dead
weight and is gone. The regret mutation battery is 4 of 4 with it removed.
