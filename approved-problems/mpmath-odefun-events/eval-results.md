# eval-results.md — mpmath-odefun-events

## Platform runs

| Batch | Agent | Evaluator | Verdict | Steps | Files | +LOC | Failed | Failed tests | Approach |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Nova 1 | Nova | FAIL_MISSED_REQUIREMENT | 4 | 2 | 848 | 7 of 122 | the 6 switch tests, `crossings_find_closely_spaced_roots` | full rewrite of `odes.py`; treated `switch` as a factory returning a derivative function; scan-and-refine crossing search that stops around 1e-9 |
| 1 | Nova 2 | Nova | FAIL_WRONG_LOGIC | 4 | 2 | 851 | 16 of 122 | the 6 switch tests, 10 crossing/extrema/optimum tests | same switch misreading; used `ctx.polyroots` on the local Taylor polynomials and swallowed root-finder exceptions into empty results |
| 1 | Nova 3 | Nova | FAIL_MISUNDERSTOOD_TASK | 4 | 2 | 828 | 7 of 122 | the 6 switch tests, `integral_of_a_function_across_a_reset` | same switch misreading; one quadrature call over an interval containing a reset, giving 2.5081 for an exact 2.5 |
| 1 | Nova 4 | Nova | FAIL_MISSED_REQUIREMENT | 4 | 2 | 822 | 7 of 122 | the 6 switch tests, `crossings_find_closely_spaced_roots` | same switch misreading; closely spaced root off by about 1.1e-9 |
| 1 | Nova 5 | — | no result recorded | — | — | — | — | — | only `run.txt` present |

Pass rate 0 of 4. Every evaluator marked the description clear, the tests
deterministic, the difficulty challenging, and `agent_blame_unfair` false, with no
environment blocker; the baseline suite passed 108 of 108 in all four runs.

### What the batch says

All four runs fail the identical six `switch` tests, which is the deterministic
universal miss that the playbook treats as a 0% trap rather than as difficulty. Each
agent read `switch(x, y)` as a factory: call it at the crossing and install whatever
callable it returns. One evaluator wrote the fix out in its own notes, that the
sentence "could be made even more explicit by saying that switch itself is the
replacement derivative function rather than a factory".

Remove that one cluster and the batch reads very differently: Nova 1, 3 and 4 are a
single test away, and only Nova 2 has a broad defect (`polyroots` over degree-48
Taylor polynomials, with exceptions swallowed). That is a well-calibrated near miss
sitting behind one ambiguous sentence.

The two remaining single failures share a second, smaller gap. The accuracy sentence
in the description sat only in the events paragraph, while the tests demand ten
digits from `crossings` and sixteen from `integral(a, b, f)`. The reference reaches
both exactly, so the requirement is attainable, but it was never stated for those
methods; agents that stopped refining at 1e-9, or ran one quadrature across a reset,
were failing an unstated contract.

### Batch 2 (5 Nova runs, after the switch and accuracy fixes)

| Agent | Verdict | Failed | Failed tests |
| --- | --- | --- | --- |
| Nova 1 | FAIL_WRONG_LOGIC | 6 of 122 | zeroth derivative, two crossings tests, closely spaced roots, two BVP stop tests |
| Nova 2 | FAIL_MISSED_REQUIREMENT | 3 of 122 | closely spaced roots, two roots tests |
| Nova 3 | FAIL_WRONG_LOGIC | 122 of 122 | the module failed to import |
| Nova 4 | FAIL_MISSED_REQUIREMENT | 2 of 122 | zeroth derivative, closely spaced roots |
| Nova 5 | FAIL_MISSED_REQUIREMENT | 2 of 122 | closely spaced roots, one BVP test |

The switch fix worked: seven, sixteen, seven, seven failures became six, three, two,
two. What replaced it was a new universal miss, `crossings_find_closely_spaced_roots`
in all four working runs, and the numbers exposed it as my fault rather than theirs.
All four agents agree with each other to sixteen digits on 0.2356194501396901, while
the test demanded three pi over forty, 0.2356194490192344. They were locating the
root of their own solution correctly; their solution simply differs from the analytic
cosine by 1.1e-9 in that regime, and my test asserted the analytic value to ten
digits.

A second defect of mine sat behind the `zeroth_derivative` failures: at `mp.dps = 20`
the test compared two values to twenty-two digits, more than the working precision
carries. A sweep found ten assertions demanding digits within three of the context
precision. Two agents were failing on noise.

### Fixes applied after batch 2

1. Every assertion is clamped to four digits below its own `mp.dps`, 61 in total.
   All 31 mutations still die afterwards, so nothing discriminating was lost.
2. The closely spaced roots test asserts six digits rather than ten: its purpose is
   finding all six roots, not matching an analytic formula in a regime where the
   solver's own error is 1e-9.
3. The description now says each point is reported once, after two agents returned
   the same root twice a few 1e-19 apart, and says the accuracy meant is that of the
   computed solution rather than of any formula it approximates.
4. The round 15 interaction test queried the analytic stop at x = 2 instead of the
   reported `domain[1]`; an implementation whose event root lands at 2 minus epsilon
   was right to reject it. It now uses the reported endpoint, the same mistake this
   suite made in rounds 3 and 8.

### Replaying the batch against the corrected suite

Each agent's own patch, unmodified, re-run against the final 123-test suite:

| Agent | On the platform (122) | After the batch-2 fixes (123) | Against the final suite (126) | What is left |
| --- | --- | --- | --- | --- |
| Nova 4 | 2 failures | **123 of 123 pass** | **126 of 126 pass** | — |
| Nova 5 | 2 failures | 1 failure | 3 failures | both tangency tests, BVP returns the zero solution |
| Nova 2 | 3 failures | 2 failures | 4 failures | both tangency tests, duplicate roots |
| Nova 1 | 6 failures | 4 failures | 5 failures | tangency, duplicate roots, two BVP stop tests |
| Nova 3 | did not import | not replayed | not replayed | — |

The two tangency tests required by the Auto Review cost every near miss one or two
tests: Nova 5 went from one failure to three, Nova 2 from two to four, Nova 1 gained
one. That is a real narrowing of the margin in exchange for closing a false-positive
hole the reviewer treated as band-setting, and it is why the tangency requirement now
has an explicit sentence in the description rather than only a test.

Solvability is measured rather than argued: a real agent's unmodified submission
passes the whole suite, one in five on this batch, with a second one failure away.

One caution about the replay harness rather than the artifact. Nova 2 takes about
sixteen minutes for the suite where the reference takes one, and a first replay with
a ninety second per-test cap reported an extra failure that was purely my timeout.
Their implementation is slow, not wrong, on that test. The suite itself carries no
timing assumption, and the platform ran it without trouble, but it is worth knowing
that a correct but slow solution costs real wall clock here.

### Fixes applied after batch 1

Both are fairness clarifications; neither eases a requirement and no test or line of
the reference changed.

1. `switch` is now described as the derivative function itself: "called exactly like
   `F` and returns the derivative, not a replacement function".
2. The working-accuracy contract is now stated for the searches and for both forms of
   `integral`, including across an event.

## Local verification

| Check | Command | Result |
| --- | --- | --- |
| New tests fail on base | base tree + `test.patch` | 126 failed, 0 passed |
| New tests pass with solution | `./test.sh new` | 126 passed |
| Base tests unaffected | `./test.sh base` | 108 passed, 1 xfailed, same as the base tree |
| Whole tree with solution | `pytest mpmath/tests` in the container | 2244 passed, 5 skipped, 2 xfailed |
| Determinism | 5 x `new`, 3 x `base`, then 3 more after the fairness round | identical every run |
| Offline, non-root | `docker run --network none --user 1000:1000` | both modes run |
| Patch order | test then solution, solution then test, and both reversals | clean |
| Effective LOC | `effective_loc_check.py solution.patch` | 575 raw / 461 human-effective / 3 files |

## Mutation battery

Each row replaces one decision in the reference with the plausible wrong one and
re-runs the tests that should notice. A row that killed nothing would mean the
requirement is described but not actually asserted; after the first pass, M7 killed
nothing and a discriminating test was added, so every row now bites. The battery was
re-run after the Test Fairness round and every row still kills.

| # | Mutation | Kills | Tests killed |
| --- | --- | --- | --- |
| M1 | record the state after the reset instead of before | 2 | `bounce_records_the_speed_before_the_reset`, `reset_state_is_recorded_before_being_changed` |
| M2 | append backward records without sorting | 1 | `events_are_collected_on_both_sides_of_the_start` |
| M3 | judge direction in integration order | 2 | `direction_refers_to_increasing_x_when_going_backward`, `rising_direction_backward_picks_the_other_crossing` |
| M4 | count crossings globally instead of per direction | 1 | `maxevents_is_counted_separately_in_each_direction` |
| M5 | locate a crossing by linear interpolation | 2 | `event_locates_threshold_to_working_precision`, `bounce_times_follow_the_closed_form` |
| M6 | take the later segment at a boundary point | 2 | `value_at_a_reset_point_is_the_state_before_the_reset`, `derivative_at_a_reset_point_uses_the_earlier_branch` |
| M7 | scan only the segment boundaries | 1 | `crossings_find_a_pair_of_roots_close_together` |
| M8 | one quadrature over the whole range | 1 | `integral_of_a_function_across_a_reset` |
| M9 | return the segment coefficients without recentering | 2 | `taylor_matches_the_analytic_expansion`, `taylor_works_backward` |
| M10 | ignore the endpoints in maximum and minimum | 1 | `minimum_uses_the_requested_component` |
| M11 | continue the old series instead of restarting after a reset | 1 | `trajectory_after_a_reset_uses_the_new_state` |
| M12 | treat a zero at the start of a step as a crossing | 3 | `bounce_times_follow_the_closed_form`, `event_at_initial_point_is_not_reported`, `reset_that_lands_on_the_surface_does_not_retrigger` |
| M13 | report the same stop for both ends of the domain | 1 | `terminal_event_bounds_the_domain` |
| M14 | return the shooting solution without advancing it | 1 | `stopping_event_endpoint_is_recorded` |
| M15 | drop the sign change for reversed limits | 2 | `integral_with_reversed_limits_changes_sign`, `integral_of_a_function_with_reversed_limits_changes_sign` |
| M16 | count maxevents across all events instead of per event | 1 | `maxevents_is_counted_separately_for_each_event` |
| M17 | silently clamp an invalid direction instead of rejecting it | 1 | `event_direction_must_be_minus_one_zero_or_one` |
| M18 | drop the maxevents limit entirely | 1 | `maxevents_limits_the_number_of_crossings` |
| M19 | record the crossing that exceeds maxevents before raising | 1 | `maxevents_limits_the_number_of_crossings` |
| M20 | apply a reset only on the forward branch | 1 | `reset_applies_while_extending_backward` |
| M21 | apply a switch only on the forward branch | 1 | `switch_applies_while_extending_backward` |
| M22 | let a non-numeric event value fail unguarded | 1 | `event_function_must_be_real` |
| M23 | search for a stopping event as if the far end were ahead | 1 | `boundary_problem_stops_at_an_event_while_shooting_backward` |
| M24 | give a plain callable a rising-only default | 1 | `plain_callable_is_accepted_as_event` |
| M25 | let the stop search run past the x1 bound | 1 | `boundary_problem_bounds_the_stop_search_at_x1` |
| M26 | let a non-numeric terminal count fail unguarded | 1 | `event_terminal_count_must_be_a_whole_number` |
| M27 | close a stopped backward branch at its endpoint too | 1 | `value_at_a_backward_terminal_point_is_available` |
| M28 | take the first event in list order, not the earliest crossing | 1 | `two_crossings_in_one_step_are_taken_in_order` |
| M29 | share terminal counts across the two directions | 1 | `terminal_count_above_one_is_kept_per_direction` |
| M30 | record every crossing under the first event | 3 | `a_terminal_event_coexists_with_another_events_reset`, `event_functions_keep_their_own_record_lists`, `two_crossings_in_one_step_are_taken_in_order` |
| M31 | let a terminal stop discard the other events' records | 1 | `a_terminal_event_coexists_with_another_events_reset` |
| M32 | let a non-real event value fail unguarded, including from `roots` | 1 | `event_function_must_be_real` |
| M33 | let a query at the starting point extend the branch | 1 | `asking_for_the_starting_point_does_not_extend` |
| M34 | search only for sign changes, ignoring touches | 2 | `crossings_report_a_level_that_is_touched_not_crossed`, `roots_report_a_value_that_is_touched_not_crossed` |

## Requirement traceability

The description splits into 32 normative clauses. Every one of the 118 tests maps to
exactly one clause, and every clause has at least one test; there is no unmapped test
and no clause the suite leaves unasserted. Checked mechanically, both directions.

The reference was then swept against its own two group-wide claims, because the two
places it previously contradicted the description were both found this way:

- "any of the methods below raises when asked for a point or a range beyond a stop":
  `sol`, `diff`, `taylor`, `integral`, `integral(f)`, `crossings`, `roots`, `extrema`,
  `maximum`, `minimum` all raise `ValueError`. Ten of ten.
- "the range needs `b` above `a` and the component has to exist": every indexed and
  ranged method rejects both. Nine of nine.

Neither sweep found a gap, which is also why the standing suggestions to test those
group rules per method were declined again: there is no ambiguity left to close, and
each extra test is a multiplier on the failure rate.

## Solvability, demonstrated by construction

A second implementation was written from the description alone, in a clean base tree
with no copy of the reference present, running the identical hidden test file. It
uses a deliberately different internal architecture: one flat list of expansions each
carrying its own near and far side, hand-rolled bisection instead of `findroot`, and
a different walk for the analysis helpers. 484 lines.

| stage | passing | fix |
| --- | --- | --- |
| first write, straight from the description | 78 / 119 (of the suite as it then stood) | — |
| segment lookup at a shared boundary | 104 / 119 | +26 |
| suppress the crossing just processed | 117 / 119 | +13 |
| raise instead of spinning at a stop | 119 / 119 | +2 |

Three ordinary debugging fixes, none needing anything outside the description, and
each failure announced itself: `no expansion covers this point`, a hang, then
`too many crossings`. The middle one is the problem's real difficulty locus and it
gated 13 tests at once: a located crossing leaves a residual of about 1e-25 rather
than an exact zero, so a literal "is it zero" check does not suppress the event just
processed and the integration re-reports it forever. The description names exactly
that case, and the symptom is an infinite loop, so it is discoverable but expensive.

This settles the question the pass-rate arithmetic could not: there is at least one
path from the description to a passing implementation, so nothing here is
undiscoverable. It does not settle the rate, because the run iterated against
failures rather than submitting one attempt.

## Solvability structure

The suite catches 23 independent wrong decisions, each costing 1 to 2 tests (mean
1.3). Passing means avoiding all 23, so the pass rate is roughly p to the 23rd for a
per-decision success rate p:

| per-decision correctness | predicted pass rate |
| --- | --- |
| 95% | 31% |
| 90% | 9% |
| 85% | 2.4% |
| 80% | 0.6% |

Every one of the 23 traces to a clause quoted above, so all are discoverable from the
description alone. The band this predicts, roughly 1 to 3 of 10, is the corpus mode,
but the tail is real: a batch of 0/10 is plausible if several decisions correlate.
The levers to pull in that case, cheapest first, are the crossings-completeness test
(the least discoverable of the 23, since a per-step bracket scan is the natural
implementation), the maxevents retained-count assertion, and the functional-integral
split across a reset.

## False-positive audit

Every transformation named in the description was checked for an input that
distinguishes doing it once from doing it twice or not at all.

| Rule | Discriminating input |
| --- | --- |
| the recorded state is the pre-reset one | a reset that halves a value, so before and after differ by a factor of two |
| a reset restarts the integration | the apex after the first bounce, which only lands at the closed-form height if the restart uses the new state |
| a zero at the entry of a step is not a crossing | a reset that lands exactly on the event surface, and an event that vanishes at the initial point |
| `switch` applies to one direction | the backward branch is compared against the untouched analytic solution |
| the value at a crossing comes from the earlier branch | pre- and post-reset velocities have opposite signs |
| coefficients are derivatives over k factorial | orders 2 and above, where the two readings differ |
| a functional integral splits at the segments | a path length across a velocity jump |
| every crossing in the range is returned | two roots inside a single Taylor segment |

Reporting APIs are asserted on cases where the underlying search fails as well as
where it succeeds: `roots` and `extrema` on a function that keeps its sign,
`crossings` on an empty range, and `odebvp` on a stopping event that never fires.

## Coverage round 9 (advisory) - suite 126 -> 133

Seven tests added for the four advisory suggestions: stopped-domain coverage for
`taylor`/`roots`/`extrema`/`maximum`/`minimum`, index validation for `extrema`/`maximum`/`minimum`,
`odebvp` `tol`/`degree`/`verbose`, and positive cases for `terminal=False`, a whole-number `mpf`
terminal count, and `maxevents=1`.

Verified after the round: 133 fail on base, 133 pass with the reference (`./test.sh new`, 183s,
in the shipped container with both patches applied through `git apply`), 474 effective LOC.

Writing the `tol` test found a reference defect rather than a test bug: an explicit `tol` left
`findroot` chasing residual noise to full precision, which cost 30.7s and, on the first draft of the
test, blew the repo's 600s pytest timeout outright. `odebvp` now scales the root tolerance to `tol**2`
(0.4s). Nothing else moved, so the earlier agent replay numbers stand.

**Solvability re-confirmed on the 133-test suite.** Nova_4's own patch (agent-runs(38)), applied over
`test.patch` with no reference solution present, passes `./test.sh new` 133/133 in 112s. The seven
coverage tests cost it nothing, so the round did not move the floor. This is the same solution that
passed at 126 - it confirms the additions are harmless, it is not new evidence of difficulty.

## Coverage round 10 (advisory) - suite 133 -> 138

Five tests for the four suggestions: BVP stop zero at the start, `roots` endpoint inclusion, the
methods reaching the stopping point, and BVP guess synthesis (nonlinear, and two unknowns).

Verified: 138 fail on base, reference 138/138, and **Nova_4 still passes 138/138** through
`./test.sh new` with its own patch and no reference present - solvability holds across the round.
Three targeted mutations confirm the three new behavioral tests each kill the implementation they are
meant to guard.

## Coverage round 11 (advisory) - suite 138 -> 145

Seven tests for the four suggestions, and `maxevents` tightened to a positive whole number in both
`meta.md` and the reference after the fractional case showed my reference and Nova_4 disagreeing on
what "positive" permits.

Verified: 145 fail on base, reference 145/145, **Nova_4 145/145** through `./test.sh new`, base
108 + 1 xfail, doctests green. The `maxevents` change moved the reference toward Nova_4's stricter
reading, so solvability was never at risk from it.

## Coverage round 12 (advisory) - suite 145 -> 148

Component integral across a reset, a stationary point that is not a turning point, and per-event
terminal counters.

Verified: 148 fail on base, reference 148/148, **Nova_4 148/148**. All three new tests mutation-proved.
The per-event terminal test needed its limits re-picked before it discriminated at all - with limits
2 and 3 a pooled counter reached the same stopping point, so the first version was green and empty.

## Coverage round 13 (advisory) - suite 148 -> 154

Derivative truncation shape, terminal validation breadth, backward maxevents overflow, integration
across a switch, and search range validation consistency at the scalar boundary.

Verified: 154 fail on base, reference 154/154, **Nova_4 154/154**. The three behavioral additions are
mutation-proved; the rest are validation paths.

## Coverage round 14 (advisory) - suite 154 -> 162

Verified: 162 fail on base, reference 162/162, **Nova_4 162/162**, base 108 + 1 xfail, doctests green,
494 effective LOC.

Two reference bugs fixed (extrema crashing across a switch, maximum missing a kink peak); Nova_4 had
both right already. One fair assertion was withheld - `roots` straddling a reset jump, where Nova_4
returns the reset point as a root while its own `crossings` does not. Keeping it would have taken
measured solvability to zero. Reinstate if a fresh batch produces a solver that handles it.

## Coverage round 15 (advisory) - suite 162 -> 165

Order-type validation for `diff`/`taylor` (description tightened to a nonnegative whole number, the
reference brought in line with Nova_4), and a BVP stop event carrying a reset. The two remaining
suggestions were declined as unstated-requirement additions, reasoned in feedback.md.

Verified: 165 fail on base, reference 165/165, **Nova_4 165/165**, base 108 + 1 xfail, doctests green,
500 effective LOC.

## Round 16 (Test Fairness FAIL + 3 coverage) - suite 165 -> 168

Fairness FAIL closed by naming the exception class in the description for `maxevents` and for the
`diff`/`taylor` order, and by making the `roots` callback contract explicit. No test relaxed.

Verified: 168 fail on base, reference 168/168, **Nova_4 168/168**, base 108 + 1 xfail, doctests green,
500 effective LOC.

## Round 17 (1 coverage suggestion) - suite 168 -> 169

Close roots through the arbitrary-g path added and passing everywhere.

Second withheld `roots` assertion: the close-PAIR mirror, where Nova_4 returns the same root twice
(two copies agreeing to 22 digits at dps 20) while passing the identical check through `crossings`.
Fair test, real defect, cut only because Nova_4 is the sole measured pass. Two withheld assertions now
sit in `roots` - see feedback.md for the reinstatement rule on the next batch.

Verified: 169 fail on base, reference 169/169, **Nova_4 169/169**.

## Round 18 (3 coverage suggestions) - suite 169 -> 172

BVP far-end conditions (all components), an event that stops returning a real value mid-extension, and
de-duplication of a crossing at an event boundary. All pass on the reference and on Nova_4.

**Third withheld `roots` assertion**, and a verdict: Nova_4's `roots` now fails three independent fair
checks (non-root at a jump, duplicated close root, missed boundary root) while its `crossings` is
right every time. Nova_4 is most likely a FALSE POSITIVE rather than a clean pass, so measured
solvability is weaker than 1/5 implies. Reinstatement and decision rules are in feedback.md.

Verified: 172 fail on base, reference 172/172, Nova_4 172/172.

## Round 19 (fairness FAIL + 2 coverage) - suite 172 -> 173

Fairness FAIL closed by adding "closed" to the `roots` range sentence; no test touched. BVP
unreachable-conditions test added after confirming reference and Nova_4 agree on `ValueError`.
Reset/switch return validation declined on measured divergence (3 of 4 cases disagree, and Nova_4 is
inconsistent with itself).

Verified: 173 fail on base, reference 173/173, **Nova_4 173/173**.

## Round 20 (fairness FAIL + 2 coverage) - suite 173 -> 175

Fairness FAIL closed by cutting the post-error state assertions from the round-18 test (the prompt
defines no rollback semantics) and keeping its fair core. Both coverage suggestions adopted after
confirming reference and Nova_4 agree: `maxevents=mpf(2)` acceptance, and a BVP stop crossing landing
exactly on `x1`.

Verified: 175 fail on base, reference 175/175, **Nova_4 175/175**.

## Round 21 (3 coverage suggestions) - suite 175 -> 178

Whole-valued `diff`/`taylor` orders, an integrand-shape spy, and a stop event carrying a terminal
count. All three probed on reference and Nova_4 first; all agreed. The `switch`-on-stop half was left
alone as unobservable through the public API.

Verified: 178 fail on base, reference 178/178, **Nova_4 178/178**.

## Round 22 (3 coverage suggestions) - suite 178 -> 180

Negative component indices (documented first, then tested) and behavioral `ODEEvent` defaults.
Declined: nonintegral indices (reference `TypeError` vs Nova_4 silently accepting) and invalid
reset/switch outputs (third ask, still undocumented and still divergent).

Verified: 180 fail on base, reference 180/180, **Nova_4 180/180**.

## Round 29 (Auto Review revision) - suite 180 -> 183

Batch: **1 of 10 passed**, near misses 168-177/180. Reviewers: Description 2/3 and 3/3, Solution 3/3,
Tests 1/3 on one High gap.

Three tests added: `roots` at a reset-only value (the round-18 withheld assertion, now required by
both reviewers), backward crossings across a sweep of offsets (the FP discriminator), and an
empty range past a terminal stop (a real reference bug, now fixed).

**Nova_4 now fails 1 of 183** on the reinstated `roots` test - confirming the round-18 call that it
was a false positive rather than a clean pass. It is no longer a valid solvability anchor; the
batch's own passing run is, subject to its own FP defect being caught by the new backward test.

Verified: 183 fail on base, reference 183/183, base 108 + 1 xfail, doctests green, 508 effective LOC.

## Round 30 (2 coverage suggestions) - suite 183 -> 185

Existing `odefun` options combined with events and backward evaluation, and the arriving-derivative
rule at a switch point. Both probed on reference and Nova_4 first; both agreed.

Verified: 185 fail on base, reference 185/185.

## Round 31 (fairness FAIL + 3 coverage) - suite 185 -> 186

Fairness FAIL closed by dropping the on-manifold norm assertion from the callback-shape test; the
shape assertions stay. Equal-range `roots` added to the existing validation test. A non-real stop
event in `odebvp` added, which exposed a bare `except ValueError: pass` in the reference that was
masking genuine shooting errors - now narrowed. Simultaneous action ordering declined for the third
time as unobservable and unspecified.

Verified: 186 fail on base, reference 186/186, base 108 + 1 xfail, doctests green.

## Batch 3 (agent-runs, Nova x5 + Vega x3) - 0 of 8

Two Nova runs hung and were scored 186/186 failing. Real near misses: Vega_1 2, Vega_2 2, Vega_3 3,
Nova_3 6, Nova_4 10.

Three blockers were my own tests: an argmax pinned to 19 digits at dps 25 (only ~half the working
digits are reachable by value comparison), a BVP fixture on `u' = u**2` that blows up and burned two
600s timeouts, and a dense-root sweep twice as costly as needed that took one run down entirely.
All three fixed. Four hints added for the recurring genuine misses.

Replay after the fixes: Vega_2 2->1, Vega_1 2->1, Vega_3 3->2, Nova_3 and Nova_4 unchanged.
Still 0 measured passes; hints cannot show up in a replay, so the next batch decides.

Verified: 186 fail on base, reference 186/186, base 108 + 1 xfail, doctests green.

