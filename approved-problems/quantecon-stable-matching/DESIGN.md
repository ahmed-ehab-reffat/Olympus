# DESIGN — quantecon-stable-matching

## 1. Title

Add stable matching markets to QuantEcon

## 2. Target

- Repo: [QuantEcon/QuantEcon.py](https://github.com/QuantEcon/QuantEcon.py) (canonical slug confirmed, no redirect)
- Stars 2386, SPDX `MIT`, primary language Python, latest commit 2026-08-02
- BASE_COMMIT `13b436b8a43aa53313f6523509bd3f7a35d9dfd2` (= `main` HEAD at pick time)
- Tier: Olympus

## 3. Shape classification

O-Composite-add: a new `quantecon.matching` subpackage sitting beside `quantecon.game_theory`,
wired into the top level `quantecon/__init__.py`. Twelve public entry points over four coupled
layers (preference bookkeeping, two-sided stability, one-sided stability, exchange), all of which
share one acceptability rule and one matching representation.

## 4. Why this pick clears the gates

| Gate | Evidence |
| --- | --- |
| behavioral f2p gap | No matching machinery of any kind exists in the repo. `quantecon.game_theory` covers normal form games, equilibria and dynamics; nothing computes stable matchings. |
| saturation | Computational economics is the "obscure to problem authors" profile. Repo is not the author-obvious host of a tooling category. |
| uniform wrap | The acceptability rule, the capacity rule and the lattice order are three separate mechanisms; a fix to one regresses another (see § 9). |
| LOC ceiling | Genuinely missing core, not a fix to almost-correct code. Estimate § 7. |
| cold not live | `git log` shows zero commits touching matching; the 11 non-main branches are optimization, docs, numba and kalman work. |
| reproduce on base | `import quantecon; quantecon.matching` raises `AttributeError` on base. |
| dedup | Nothing under `Aprroved/`, `problems/`, `rejected/` or any `TaskN/problems/` is about matching markets. The one prior QuantEcon artifact (`rejected/quantecon-average-reward-dp-OLD-REPO`) is average reward dynamic programming on `DiscreteDP`/`MarkovChain`, a different subsystem with no shared machinery. |
| exclusivity | PR and issue search over all states for `matching`, `deferred`, `stable`: zero hits on the feature class. All 11 branches enumerated with `compare/main...<branch>`, none touches the feature. `gh search code` for `deferred_acceptance` and `stable_matching`: zero. |
| defined behavior | Stability, the proposer optimal matching and the lattice are textbook definitions with no maintainer position against them; market design is squarely in QuantEcon's scope. |
| no flaky repo | Vanilla suite, offline, uid 1000, no `.git`: **598 passed in 5m29s**. Zero RNG and zero wall clock in anything the new code touches. |
| repo quota | 1 prior local artifact, and it is shelved. 2 of 6. |

## 5. Public API surface

All of it lives in `quantecon.matching` and is re-exported by `quantecon/__init__.py` as a
subpackage (`from . import matching`), matching how `game_theory`, `markov` and `optimize` are
wired.

Two sided market:

- `deferred_acceptance(prop_prefs, resp_prefs, caps=None)`
- `blocking_pairs(matching, prop_prefs, resp_prefs, caps=None)`
- `is_stable(matching, prop_prefs, resp_prefs, caps=None)`
- `stable_matchings(prop_prefs, resp_prefs)`
- `matching_join(matching1, matching2, prop_prefs)`
- `matching_meet(matching1, matching2, prop_prefs)`

One sided market (roommates):

- `stable_roommate_matchings(prefs)`
- `roommate_blocking_pairs(matching, prefs)`
- `is_roommate_stable(matching, prefs)`

## 6. Canonical output form

- A **two sided matching** is a 1-D int array of length `m` (number of proposers); entry `i` is the
  respondent matched to proposer `i`, or `-1`. The proposer side alone determines the matching even
  under capacities, so there is exactly one representation.
- A **roommate matching** is a 1-D int array of length `n`; entry `i` is the partner of `i` or `-1`,
  and `x[x[i]] == i`.
- A **set** of matchings is a 2-D int array whose rows are the matchings, sorted lexicographically
  by row (so `-1` sorts before `0`). Shape `(0, m)` when empty.
- **Blocking pairs** are a 2-D int array of shape `(k, 2)`, sorted lexicographically, shape `(0, 2)`
  when empty. Roommate blocking pairs are listed with the smaller index first.

Every output is exact integer data. No tolerance appears anywhere in the test suite.

## 7. File footprint

| File | Status | raw | meaningful |
| --- | --- | --- | --- |
| `quantecon/matching/__init__.py` | new | 20 | 12 |
| `quantecon/matching/_util.py` | new | 150 | 95 |
| `quantecon/matching/_core.py` | new | 400 | 250 |
| `quantecon/matching/_roommates.py` | new | 260 | 160 |
| `quantecon/__init__.py` | modified | 1 | 1 |

Target: >= 450 human effective per `effective_loc_check.py`.

## 8. Solution outline

`_util.py` — one acceptability layer shared by every entry point:

- `_preference_lists(prefs, num_partners, name)`: sequence of sequences to list of 1-D int arrays,
  raising `ValueError` on out of range entries and on repeats.
- `_rank_table(lists, num_partners)`: dense `(num_agents, num_partners)` rank array, `-1` where
  unacceptable. Every preference comparison in the package goes through this table.
- `_mutual_lists(...)`: per proposer, the acceptable respondents that also accept them.
- `_check_caps`, `_check_matching`: shape and range validation.

`_core.py`

- `deferred_acceptance`: proposal loop over the mutually acceptable shortlists with a per respondent
  sorted holding list truncated at its capacity. Rejected proposers return to the free stack. Result
  is order independent, which is why the returned object is the proposer optimal matching.
- `blocking_pairs`: for each proposer, walk its shortlist and test the two sided condition against
  the respondent's current load and its least preferred acceptable partner.
- `is_stable`: mutual acceptability of every matched pair, then capacities, then no blocking pair.
- `stable_matchings`: shortlists narrowed to the interval between the proposer optimal and proposer
  pessimal partners on both sides (a necessary condition), the matched set pinned by the proposer
  optimal matching, then depth first assignment with an incremental blocking test against the
  already assigned proposers, and a full stability check at each leaf.
- `matching_join` / `matching_meet`: pointwise better / worse partner under `prop_prefs`, with an
  unmatched proposer ranked below every acceptable respondent.

`_roommates.py`

- `roommate_blocking_pairs`, `is_roommate_stable`: same two layer split as the two sided pair.
- `stable_roommate_matchings`: phase one proposal reduction (sound: a pair deleted there is in no
  stable matching), then depth first assignment of the lowest indexed undecided agent to an
  acceptable partner or to nobody, incremental blocking test among decided agents, full check at
  each leaf.

## 9. Predicted trap matrix (interdependent + misdirecting)

| # | Trap | Interacts with | How it misdirects |
| --- | --- | --- | --- |
| 1 | Acceptability is **mutual**: `j` in `prop_prefs[i]` is not enough, `i` must also be in `resp_prefs[j]` | every entry point | a one sided reading leaves `deferred_acceptance` correct on complete lists and fails only the enumeration and blocking pair tests |
| 2 | `is_stable` is not `blocking_pairs(...) == []`: it also requires mutual acceptability of matched pairs and respects capacities | 1, 3 | the blocking pair tests pass while `is_stable` returns `True` for an individually irrational matching |
| 3 | Capacity blocking uses the respondent's **least preferred current partner**, and a free slot blocks unconditionally | 1, 2 | shows up as a missing blocking pair in a many to one instance, not as a capacity error |
| 4 | A partner an agent does not find acceptable is treated exactly like no partner: it fills no slot and is never the least preferred partner | 2, 3 | changes only the deliberately irrational fixtures |
| 5 | The set of matched agents is identical in every stable matching, so enumeration must not return a matching that leaves a proposer-optimal-matched proposer alone | 6 | surfaces as an extra row in `stable_matchings`, far from where the rule was missed |
| 6 | Enumeration must be sound on an instance with 4096 stable matchings over 24 proposers: enumerating all matchings is impossible | 5 | a brute force submission does not fail, it never returns |
| 7 | Row order is lexicographic with `-1` first | 5, 6 | a correct set in the wrong order fails everything |
| 8 | Roommates: no stable matching need exist, and unmatched agents are allowed | 1 | an implementation assuming a perfect matching returns a wrong non-empty answer |
| 9 | Join and meet are pointwise on the **proposer** order, so `matching_join` of two stable matchings is the proposer optimal of the two, not the respondent one | 1 | a swapped orientation still returns a stable matching, so only the value tests catch it |

Fixing 1 without fixing 4 regresses 2; fixing 5 without 7 regresses 6.

## 10. Test outline

Four blocks in `quantecon/matching/tests/test_matching_<hash>.py`:

1. builders — hand written fixtures (a 3x3 textbook market, an incomplete-lists market, a
   many-to-one market with capacities, an irrational matching, the 2^k product family, the
   roommates 4-cycle family, the classic no-stable-roommate-matching instance).
2. helpers — a brute force stability oracle over all matchings for small instances, used as the
   reference in the enumeration tests.
3. granular `test_*` functions with scenario names.
4. property tests: lattice closure, rural hospitals invariant, DA optimality against the brute
   force set, join/meet identities.

Every test reaches the package through `quantecon.matching.<name>` off a module level
`import quantecon as qe`, so the module collects on base and each test fails there with
`AttributeError`.

## 11. Forced conventions the description must state

- preference lists are most preferred first, list only acceptable partners, and are indexed by
  agent
- mutual acceptability
- `-1` for unmatched, matchings indexed by proposer
- capacity default 1, blocking under capacities
- lexicographic row order, `(k, 2)` blocking pair shape
- the three separate conditions inside `is_stable`
- which `ValueError`s are raised
- join and meet are on the proposer order

## 12. Tier and category

Olympus, feature request (net new subpackage plus one line of wiring).

## 13. Predicted pass rate

10 to 30 percent. The definitions are all classical, so nothing here is knowledge-hard; the
difficulty is in composing mutual acceptability, capacities, the fixed matched set and the
lexicographic contract without regressing one while fixing another, and in producing an enumeration
that survives an instance with 4096 answers.

## 14. Quality gate checklist

- [x] Env Quality: vanilla suite 598 passed offline, uid 1000
- [x] `human-effective` 674 over 7 files
- [x] every new test fails on base (303 of 303, zero collection errors)
- [x] base suite green with the solution applied (598 passed)
- [x] both apply orders clean, both patches unapply cleanly
- [x] 3x deterministic in new mode, 4 identical base runs
- [x] mutation battery 34 of 34 killed
- [x] FP check clean; Test Fairness FAIL cleared by stating the integer-array contract; twenty-five of thirty-five coverage advisories taken, ten declined on purpose

Scope grew after the first build measured 348 human-effective: capacities were added to the
enumerator, and `respondent_optimal`, `top_trading_cycles` and `serial_dictatorship` were added.
`stable_matchings` also gained a `caps` argument, so section 5 above lists twelve entry points
rather than nine.
