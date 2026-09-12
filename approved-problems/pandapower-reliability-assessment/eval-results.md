# eval-results.md — pandapower-reliability-assessment

Base commit `af68dbc0f5af548b6ac7099112160acde0927ed6`. Image built from the submitted
Dockerfile, every run offline (`--network none`) as uid 1000.

## Local validation matrix

| Run | Source | Tests | Result |
| --- | --- | --- | --- |
| 0 | base | vanilla `python -m pytest` (the Environment Quality command) | 1625 passed, 161 skipped, 23 xfailed, 11 xpassed, 0 failed (17:32) |
| 1 | base | `test.sh base` | 244 passed, 10 skipped, 2 xfailed (2:16) |
| 2 | base | `test.sh new` | 118 failed, 0 passed, 118 JUnit nodes |
| 3 | solution | `test.sh new` | 118 passed (0:38) |
| 4 | solution | `test.sh base` | 244 passed, 10 skipped, 2 xfailed (2:26) |

Run 0 collects 1819 tests with no collection errors. Before the Dockerfile fix it aborted at
`1719 tests collected, 1 error` on a missing `lxml`.

## Flakiness

| Mode | Run 1 | Run 2 | Run 3 |
| --- | --- | --- | --- |
| new | 118 passed | 118 passed | 118 passed |
| base | 244 passed, 10 skipped, 2 xfailed | 244 passed, 10 skipped, 2 xfailed | 244 passed, 10 skipped, 2 xfailed |

## Size

| Measure | Value |
| --- | --- |
| human-effective LOC (Counter 2) | 557 |
| raw added | 809 |
| padding floor | 346 |
| files touched | 14 |
| new tests | 118 |

## Mutation battery

Twenty four planted defects, twenty three with a non-empty kill set. Full table in `feedback.md`. The one
zero-kill defect is the redundant `reset_results` call inside `calc_reliability`; the contract it
touches is caught by a different mutation (2 kills).

## Batch 1 — 4x Nova (before the description fix)

| Agent | Verdict | Baseline | New tests | Where it failed |
| --- | --- | --- | --- | --- |
| Nova #1 | FAIL_MISSED_REQUIREMENT | pass | 81/107 | restoration set, the whole maintenance family, element table |
| Nova #2 | FAIL_MISSED_REQUIREMENT | pass | 100/107 | element table (6), one out-of-service-bus duration |
| Nova #3 | FAIL_MISSED_REQUIREMENT | pass | 89/107 | zone semantics, maintenance, element table |
| Nova #4 | FAIL_MISSED_REQUIREMENT | pass | 99/107 | planned outages (2), element table |

0 of 4, from two causes, one of them mine:

1. **All four** invented `saifi_share` / `saidi_share` / `ens_share` columns holding a NORMALISED
   ratio, because the description said the event table carries "its share of `saifi_1_per_year`,
   `saidi_h_per_year` and `ens_mwh_per_year`". Four independent agents reading one sentence the
   same way is a prompt bug, not four agent failures. It now says the table holds "how much of
   ... it causes, in columns of those three names".
2. Nova #2's only other failure was `test_an_out_of_service_bus_produces_no_event`, whose fixture
   left a line with one out-of-service terminal. Whether such a line still fails was never
   stated. The fixture now takes that line out of service too, which removes the question
   instead of answering it in the prose.

## Replay against the fixed suite

Every agent patch re-applied to the base tree, with only the naming and normalisation that the
corrected sentence pins rewritten inside their own code.

| Agent | New tests | What is left |
| --- | --- | --- |
| Nova #1 | 91/118 | restorable set (5), maintenance family, contributions |
| Nova #2 | **118/118 PASS** (re-checked after every change since the batch) | nothing |
| Nova #3 | 100/118 | zone cut (3), open switch, sparse indices, maintenance |
| Nova #4 | 110/118 | the two planned-outage traps, plus contribution values my rewrite could not reach |

**Projected 1 of 4, 25 percent.** Solvable, inside the 40 percent cap, and the traps that decide
it are the intended ones: the restoration set, the two different cuts, and planned outages not
tripping a breaker. Nova #4 normalises its shares through local variables rather than a dict
literal, so its four remaining contribution failures are an artifact of the rewrite, not a
genuine miss; its real remaining failures are the two maintenance tests.
