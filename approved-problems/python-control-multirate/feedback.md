# feedback.md — python-control-multirate

Olympus submission. Target: [python-control/python-control](https://github.com/python-control/python-control)
at `75a658b6f731785dfdebedadcb06dad522ec63e3`, BSD-3-Clause, 2059 stars.

## Status

| Item | Result |
|---|---|
| Effective LOC (Counter 2, hook) | 378 over 4 source files |
| New tests | 156, all F2P (156/156 fail on base, 156/156 pass with solution) |
| Base mode | 3814 passed / 559 skipped, identical to the vanilla tree |
| Apply orders | test-then-solution and solution-then-test both clean |
| Flakiness | new mode 5x identical, base mode 6x identical, `--network none` |
| Vanilla env | whole tree green under `control/`; `doc/test_sphinxdocs.py` fails on the unpatched repo because the sphinx `generated/` stubs are a build product, so base mode is scoped to `control/tests` (same scoping as the approved sibling submission at this commit) |
| FP check | mapping below, both directions closed |
| Solvability | **Proven**: Nova_4 + the minimal implementation of the now-stated `*`/`+` rule passes 156/156. |
| Test Fairness (platform) | run 1 FAIL 3 of 91 (round 7), run 2 PASS + 4 suggestions (round 8), run 3 FAIL 2 of 102 (round 9), run 4 FAIL 1 of 106 (round 10), run 5 PASS + 3 suggestions (round 11), run 6 FAIL 1 of 112 (round 12), run 7 FAIL 1 of 121 (round 13), run 8 PASS + 3 suggestions (round 14), run 9 FAIL 10 of 129 (round 15), run 10 PASS + 3 suggestions (round 16), run 11 PASS + 3 suggestions (round 17); every unfair finding fixed. Category classifier FAIL and Solution Quality 2/3 both addressed in round 18 |

## Attempt history

**Round 1 — design.** Time-delay systems were the first idea for this repo and are
exclusivity-dead: PR [#1148](https://github.com/python-control/python-control/pull/1148)
"Add support for continuous delay systems" is open. Multirate has no PR, no open issue and
no side branch.

**Round 2 — first build.** Interconnection, `MultirateSystem` and `lift` only: 188 effective
LOC. Also tried supporting mixed sample times in `series` / `parallel` / `feedback`, which
broke `timebase_test.py::test_composition`: the repo pins `(0.2, 0.1) -> ValueError` for all
three. Reverted; the block-diagram operators keep their contract, and only a multirate
operand routes through `interconnect`.

**Round 3 — depth.** Added sample time offsets, continuous subsystems entering as their zero
order hold equivalent, nesting of a multirate subsystem (the outer period comes from the
inner period, not from its sample time), nonlinear subsystems, `poles`, `dcgain` and an exact
`linearize`. 357 effective LOC.

**Round 4 — semantics fix found by the tests.** The first implementation held a slow
subsystem's *input* between actions. That leaves its output moving one base step after its
state advances, so a sampled block's output was not piecewise constant over its own sampling
interval. Switched to holding the *output*: one extra state per output rather than per input.

**Round 5 — fairness.** Every `pytest.raises` match string on a message this task introduces
was relaxed to the bare `ValueError`, since no agent can guess new wording. Only two pins
survive, both on messages the unmodified repo already produces
(`common_timebase` and `input_output_response`). Relaxing them made five negative tests pass
vacuously on base; each now also asserts the positive case in the same function.

**Round 6 — meta-tests.** `docstrings_test.py` rejected `period` documented as both a
parameter and an attribute, and `kwargs_test.py` rejected `MultirateSystem.linearize` for
taking `**kwargs` with no registered keyword test. Both fixed in the solution rather than
excluded.

**Round 7 — platform Test Fairness FAIL, 3 of 91.** Two tests pinned rejection of `pi` and
`sqrt(2)` while the description only said "not close to a fraction with a small denominator",
which leaves the acceptance boundary undefined: `pi` is 22/7 or 355/113 depending on the bound
you pick. Fixed on the description side, since dropping the tests would let an agent accept an
incommensurate pair and build an interconnection with millions of phases. The rule is now
stated exactly as the implementation applies it: a ratio further than a relative 1e-9 from
every fraction with denominator at most 1000. The third was `test_linearize_at_later_step`
asserting that `linearize` preserves state labels, which contradicts the repository's own
default (`copy_names` is False, `control/nlsys.py:579-584`); the assertion was replaced by the
full A, B, C, D comparison against the phase model.

Also from that round, all advisory: `pytest.raises(Exception)` on the algebraic loop narrowed
to `RuntimeError` matching the repository's own `"algebraic loop detected"`
(`control/nlsys.py:993-995`); `commensurate_timebase` gained singleton, empty-list and
negative-sample-time cases, with the description widened from "continuous" to "not positive"
and empty lists named; and the multirate `feedback` test gained a full trajectory comparison
instead of only checking type, state count and period. The suggestion to add a nonlinear
`linearize` rejection was declined: the description deliberately requires linearity for
`poles`, `dcgain` and negation only, and `linearize` falls back to the inherited numerical
Jacobian.

**Round 8 — second Test Fairness run: PASS, 4 coverage suggestions, all four added.**
Boundary cases for the now-stated rational-approximation rule (a ratio needing denominator
exactly 1000 is accepted, 1002/1001 is not; a ratio 5e-10 relative from an integer is
accepted, 5e-8 is not). `linearize` on a multirate system holding a nonlinear subsystem, at
an acting phase and a holding phase, which pins the fallback to the inherited numerical
Jacobian that the description deliberately leaves available. A continuous MIMO plant, checking
that the ZOH conversion preserves both A and B and the whole state layout, plus a continuous
transfer-function subsystem. And `phase_system` at negative and very large indices, which
"counted round the period" already covers.

**Round 9 — third Test Fairness run: FAIL 2 of 102, and one was self-inflicted.** Round 8's
quality note had me narrow the algebraic-loop rejection from `Exception` to
`RuntimeError`; the checker then read that against the description's blanket "every rejection
raises `ValueError`" and called the type unfair. The rejection is pre-existing repository
behaviour and no description clause claims it, so the assertion is gone; the trajectory
assertion in the same test, plus `multirate_loop_broken_while_holding`, still cover the
phase-dependent feedthrough. Lesson: narrowing an exception type is only safe when the
description's own error contract admits that type.

The second, `test_forced_response_time_step_check`, pinned `input_output_response` on a
multirate system to a strict base-step grid. The repository's own discrete path accepts
integer multiples of the sample time (`control/timeresp.py:1208-1221`), so which path a
multirate system travels is an implementation choice the description never fixes. Test
deleted rather than papered over with a new clause.

All three coverage suggestions added: `interconnect` applying the commensurability rule itself
(irrational ratio and a ratio needing denominator 1001), `lift` validation for `dt=True`,
`dt=None` and non-finite requested sample times (which needed a real guard in `lift`, since
`int(round(inf))` raised `OverflowError` rather than `ValueError`), and `linearize` at times
past one full period.

**Round 10 — fourth run: FAIL 1 of 106, an ambiguity I wrote myself.**
`test_lift_default_sample_time` pinned `lift(sys)` on an ordinary system to one sample
interval, but the description only said `dt` "defaults to that period" right after introducing
period as a multirate notion, and an ordinary `StateSpace` has no period in this repository.
Fixed in the description: the default is now "the period, or the sample time when `sys` is not
multirate". A default that depends on the argument type has to name both branches.

Two of the three suggestions added: the lifted system's signal labels (which follow the
repository's default `u[i]`/`y[i]` naming, so the earliest-first stacking shows in metadata as
well as in the blocks), and `interconnect` with a subsystem whose timebase is unspecified,
covering both `dt=None` and `dt=True` with a trajectory check. That needed one new description
sentence, since an unspecified subsystem acting at every base step was previously only implied
by `static_gain_keeps_period`.

The third, a fully direct algebraic loop, is declined for a structural reason rather than
preference: `_compute_static_io` iterates a fixed number of times and raises
`RuntimeError("algebraic loop detected")` for *any* feedthrough loop, convergent or not
(measured: loop gain 0.2 still raises). So the acting-phase half is only observable through an
exception whose type the description's "every rejection raises `ValueError`" excludes, which is
exactly the assertion round 9 removed as unfair. Re-adding it would trade a coverage note for a
fairness failure. The holding half is already covered by
`multirate_loop_broken_while_holding`.

**Round 11 — fifth run: PASS, 3 suggestions, 2 taken.** The equal-rate test now asserts
`isinstance(result, ct.LinearICSystem)` outright instead of only that it is not a
`MultirateSystem`, which is what the description actually names. Offsets are now validated as
base step indices through `operator.index`, so `0.5` and a non-numeric entry raise `ValueError`
while numpy integers still work; previously `int(offset)` silently truncated a fraction.

The fully-direct algebraic loop is declined a second time, now with the mechanism rather than
just the measurement. `InterconnectedSystem._compute_static_io` (`control/nlsys.py:955-995`)
ends its fixed-point sweep only on `(ulist == new_ulist).all()`, exact equality, after at most
`len(syslist) + 1` passes. A contractive feedthrough cycle converges asymptotically and never
hits exact equality in that many passes, so every true feedthrough cycle raises
`RuntimeError("algebraic loop detected")` regardless of loop gain. There is no algebraic solve
to verify: the acting-phase half is reachable only through an exception type the description's
`ValueError` contract excludes, which round 9 already removed as unfair.

**Round 12 — sixth run: FAIL 1 of 112, on an assertion I could simply drop.**
`test_commensurate_timebase_inside_tolerance` pinned base and period for the noisy pair
`[1.0, 2*(1+5e-10)]`. Acceptance and the ratios `[1, 2]` are specified, but nothing says which
of the two nearly-equivalent inputs the reported base is normalized against, so an
implementation could reasonably report either. The test now asserts only what holds whichever
reference is chosen: the ratios, and `period == 2 * base`. Exact base and period values are
already pinned on the six non-noisy cases, so no coverage is lost.

All four suggestions taken, and three needed real guards rather than only tests. `np.inf` in
`commensurate_timebase` raised `OverflowError` out of `Fraction`, and `np.nan` raised a
`ValueError` with a confusing message from the same place; both are now rejected up front, and
the description says "not finite and positive" rather than "not positive". A non-numeric `lift`
target reached `np.isfinite` and raised `TypeError`. `phase_system` with a fractional or
non-numeric index raised `TypeError` from the list index; it now goes through
`operator.index` like `offsets`. Offsets against a nested multirate subsystem needed no change:
a nested system at the base rate has ratio 1, so the stated "each below its own ratio" already
allows only offset 0, and the test pins that.

**Round 13 — seventh run: FAIL 1 of 121, and this one was an implementation/description
mismatch, not just a test.** `test_nested_multirate_offsets` accepted `offsets=[0, 0]` on a
nested system whose two outer operands both run at 0.1. The description says offsets apply
"only when the sample times differ", so that acceptance contradicted both the description and
`test_offsets_require_mixed_rates`. The implementation was the wrong side: it gated `offsets`
on the interconnection being multirate, which a nested periodic subsystem makes true even at a
single outer rate. `_multirate_offsets` now rejects whenever every ratio is 1, so the code
matches the sentence, and the nested test asserts rejection for both `[0, 0]` and `[1, 0]`.

All three suggestions taken, including the algebraic loop, declined twice before. The way
through is `pytest.raises((ValueError, RuntimeError))`: it accepts the type the description
mandates and the `RuntimeError` the repository already raises, so it pins neither. A cycle with
feedthrough in both members at 0.1 and 0.2 now asserts that construction is rejected. Its
second half stays out of scope by construction: phase 0 fails, so no object exists whose
holding phases could be inspected. Also added `dcgain` value and output-ordering checks against
a long simulation instead of only a shape assertion, and a lift/response equivalence test for a
system built with a nonzero offset.

**Round 14 — eighth run: PASS, 3 suggestions, all taken, and one exposed a real bug.**
The suggestion to linearize between grid points found that `_phase` used `round(t / dt)` while
the description says `linearize` returns the model at the step *holding* the time. Rounding
sends `t = 0.16` to step 2, but the step holding 0.16 is step 1. It is now
`floor(round(t / dt, 9))`, floor for the holding semantics and the inner rounding so a value
like `0.7 / 0.1 = 6.999999999999999` still lands on step 7. Grid-aligned times, which is all
the simulation ever passes, are unaffected. Tests pin 0.05, 0.15, 0.19, 0.25 and a negative
time.

Also added a stateful `dt=None` subsystem, so the unspecified-timebase rule is checked on a
block with dynamics rather than only a static gain, and `commensurate_timebase` rejections for
systems carrying `dt=None`, `dt=True` and `dt=0` rather than raw values.

**Round 15 — ninth run: FAIL 10 of 129, all one defect repeated.** Every
`commensurate_timebase` value test asserted `ratios == [1, 2]`, which pins the return
CONTAINER to a Python list. The description fixes the ratio values but says nothing about
list versus tuple versus array, and the repository has no precedent for this function. All ten
now use `np.testing.assert_array_equal`, which checks the values for any ordered container.
The lesson generalises past this problem: `==` against a literal list is a type assertion as
much as a value assertion, so a described sequence of values wants
`assert_array_equal`, not `==`.

Both suggestions taken: `lift` rejecting a plain `NonlinearIOSystem`, which the description's
enumerated "state space, transfer function or multirate system" already implies, and
equal-rate discrete NONLINEAR subsystems staying an ordinary `InterconnectedSystem` (the
existing equal-rate test used linear blocks and so only covered `LinearICSystem`); the same
test then flips one rate and confirms the multirate path takes over.

**Round 16 — tenth run: PASS, 3 suggestions, all taken with one deliberate limit.**
The tolerance-boundary suggestion asked to pin inclusivity exactly at relative 1e-9. Measured,
`2 * (1 + 1e-9)` is REJECTED even though the arithmetic says the error is exactly at the
threshold: the double nearest that expression sits a few ulp above it, so the verdict at the
knife edge turns on float representation rather than on the stated rule. Pinning it would
re-create the round-12 defect of asserting something the description cannot decide. The bracket
is instead tightened to 9e-10 accepted and 1.1e-9 rejected, ten percent either side, which
fixes inclusivity to within a tenth of the threshold while staying far outside float noise.

The other two are straightforward. The multi-input `dcgain` test uses a fixture whose gain
matrix is deliberately NOT symmetric, so a swapped output/input axis cannot pass, and checks
each column against a simulation driven on that channel alone. The three-rate offsets test
gives 0.1, 0.2 and 0.4 subsystems independent offsets of 0, 1 and 3 and matches the whole
twelve-step trace against a hand recurrence, plus a rejection for offset 4 on the ratio-4
block.

**Round 17 — eleventh run: PASS, 3 suggestions, and two of them were bugs.** A non-numeric
member of the `commensurate_timebase` list reached `np.isfinite` and raised `TypeError`, and
`lift` on a multirate system built from a NONLINEAR subsystem reached `phase_system(k).C` on an
`InterconnectedSystem` and raised `AttributeError`. Both are contract violations against
"every rejection raises `ValueError`", and the second is the more interesting one: `lift` is a
phase-level operation that needs linear subsystems exactly like `poles`, `dcgain` and negation,
but the description had not said so and nothing tested it. The description now lists `lift`
alongside them, and there is a test.

The interconnect propagation suggestion turned up a useful boundary: python-control itself
rejects `dt=-0.2` when the `StateSpace` is built ("invalid timebase"), so a negative rate never
reaches this feature. `np.nan` and `np.inf` are accepted by `ct.ss`, do reach `interconnect`,
and are now tested there. The nonlinear linearization test also grew from an A-only check to
the full A, B, C, D at both an acting and a holding phase.

**Round 18 — category classifier FAIL, plus the Solution Quality caveat.** The classifier read
the description as documentation of existing behaviour rather than a feature request, and it
was right: every sentence was present-tense description of how the feature behaves, with
nothing saying the capability does not exist yet. Reframed without dropping a single mapped
clause: it now opens with the gap ("`interconnect` refuses subsystems whose sample times
differ ... Add multirate support"), and the new surface is introduced with "Add
`commensurate_timebase`", "return a new `MultirateSystem`", "A new `offsets` argument" and
"Add `lift`". Still 499 words. The lesson is that a behavioural spec and a feature request are
not the same document, and a title starting with "Add" does not rescue a body written entirely
in the present indicative.

Solution Quality passed 3/3 on code quality but 2/3 on comprehensiveness, citing
`_multirate_structure` returning `None` whenever an unspecified timebase and a continuous
subsystem appear together. That was a defensive guard from the round where unspecified
subsystems were added, and it contradicted two description sentences that each say those
subsystems join at the base step. Removed, so a list holding a continuous plant, a static gain
and two sampled blocks now builds; base mode is unchanged and there is a test.

**Round 19 — the Nova batch came back 0/5, and the diagnosis was in the failure histogram.**
Agents were not far off: three of the five landed 133-135 of 140. Five tests failed nearly
everyone, two of them all five, and not one of the five traces to a description sentence:
a direct-feedthrough cycle had to be REJECTED (the description says only where a loop is
algebraic, and solving an invertible cycle is compliant), lifted signal labels had to be flat
`u[0]..u[3]` (naming appears nowhere), `linearize` had to pick the holding step for OFF-GRID
times (a corner nothing in the library produces), and nested offsets had to be refused on a
reading of "sample times differ" that is genuinely ambiguous for a nested periodic subsystem.
Every one of them arrived in rounds 11-14 from Test Fairness *coverage suggestions* rather than
from the design. Removed, solution untouched, and no clause left without a test.

Rather than projecting the effect, each saved agent patch was re-applied to a clean base tree
and run against the revised suite: Nova_4 passes 136/136, Nova_5 misses by one, Nova_1 by two.
**1/5 = 20% measured**, above the solvability floor and inside the cap, with every remaining
failure on a plainly stated requirement.

The standing lesson: a coverage suggestion is a hypothesis about what the tests SHOULD cover,
and taking one means adding a requirement. If the description does not already state it, the
test is a hidden requirement no fairness pass will catch and every agent will fail. Check each
suggestion against a description sentence before writing the test, not after the batch.

**Round 20 — 4 more coverage suggestions, and two of them were the tests that caused the 0/5.**
The algebraic-loop cycle and the lift signal labels came back, for the fourth and second time.
Both are re-declined, now on evidence rather than argument: each failed 5 of 5 agents, and
neither traces to a description sentence. Rejecting a direct-feedthrough cycle is not required
anywhere (the description says only WHERE a loop is algebraic, and solving an invertible one is
compliant), and lifted signal naming appears nowhere at all, which four evaluators noted
independently. Re-adding either takes the artifact back to 0%.

The other two were new, and both were taken after being checked the right way round: write the
candidate assertion first, run it against the saved agent patches, and only keep it if the
passing agent still passes. `phase_system` on a nonlinear multirate system is quotable, because
the linearity list ("`poles`, `dcgain`, `lift` and negation") is an enumeration that excludes
it, and the test asserts dimensions rather than a type. `*` and `+` with a multirate operand at
the same base rate turned out not to be broken at all: they build the ordinary composition
through the generic nonlinear path and agree with `series`/`parallel` to the last digit, so the
test asserts that equivalence instead of a class. Both pass on Nova_1, Nova_4 and Nova_5, and
the replayed pass rate is unchanged at 1/5.

**Round 21 — 2 suggestions, 1 taken.** The algebraic-loop cycle was requested a fifth time and
is declined a fourth, on the same evidence: it failed 5 of 5 agents and the description never
requires a cycle to be rejected. The decline is recorded here rather than re-argued each round,
because reversing under repetition is the actual risk.

The other is a genuine hole and cheap: `commensurate_timebase` was only ever exercised on an
all-numeric list or an all-system list, never a mixed one, even though the description's first
sentence says it takes "sample times, or systems carrying them". A four-entry list alternating
raw floats and systems now pins extraction together with order-preserving ratios. It passes on
Nova_1, Nova_3, Nova_4 and Nova_5 under the intake replay, and the measured rate stays 1/5.

**Round 22 — 4 suggestions, 3 taken.** The algebraic-loop cycle came back a sixth time and is
declined a fifth; the evidence has not changed and re-adding it costs the only passing agent.

The other three all cleared the intake replay before being written into the suite. A nonlinear
`phase_system(k)` now has its update and output compared against the parent multirate system at
an acting and a holding phase, which is what "the model in force at base step `k`" actually
promises and is stronger than the dimension check it replaces. `*`, `+`, `parallel` and
`feedback` are now checked to refuse a multirate operand paired with a different sample time,
where only `series` was covered before, and that is stated verbatim. `poles` and `dcgain` are
checked on an offset system against the phase product and the long-run periodic response, so
the analysis path is pinned to the shifted schedule rather than the unshifted one.

Nova_4 still passes all 142, so the measured rate is unchanged at 1/5. Nova_5 picks up a second
failure on the new operator test, but from the defect it already fails on (its `_series_pair`
never calls `common_timebase`), so no agent is newly blocked.

**Round 23 — FAIL 3 of 143, all the same mistake in three places: pinning a type or domain
policy on my own new API.** NumPy scalar offsets, NumPy scalar phase indices, and negative
phase indices wrapping modulo. None is stated, and for each the opposite choice is equally
defensible: accepting only built-in `int`, and rejecting a negative step rather than wrapping
it. The repository's NumPy-integer handling at `control/iosys.py:1103-1110` is a signal-count
parser, not a precedent for these. The NumPy-offsets test is gone, the NumPy assertion inside
the fractional-index test is replaced by a plain-integer anchor, the negative-index test is
gone, and the stray `-1` probe in the nonlinear `phase_system` loop went with it.

The generalisation, which is what actually matters after three rounds of this: for a brand new
API, only the BEHAVIOUR the description states is fair game. Accepted scalar classes, index
domains, container types and label formats are all choices the description does not make, and
they are exactly what the checker keeps catching.

Of the two suggestions, the all-acting algebraic loop is declined a sixth time on the batch
evidence. The other is a genuine gap and cleared intake replay on all four saved patches plus
the reference: a `dt=None` subsystem acts every base step, so its ratio is one and only offset
zero is valid, which follows from "below its ratio" plus the unspecified-timebase rule.

**Round 24 — 3 suggestions, 1 taken, and one of the declines is a reversal.** The checker asked
for `phase_system(-1)` to wrap to the last phase. It declared that exact test unfair one round
ago, on the grounds that "counted round the period" does not say whether a negative step index
is accepted or rejected. Nothing about the description changed in between. When round N flags an
assertion as unfair and round N+1 asks for it back, the honest reading is that the domain is
genuinely ambiguous, so it stays unpinned in BOTH directions rather than tracking whoever asked
last. The all-acting algebraic loop is declined a seventh time on the batch evidence.

The third is a real regression guard and was taken: an interconnection of only continuous
subsystems has no discrete base step, so the multirate path must not touch it. It stays an
ordinary continuous `LinearICSystem` at `dt = 0`. Paired with a multirate assertion so it fails
on base rather than passing vacuously, and it clears intake replay on all four saved patches and
the reference.

**Round 25 — negative phase indices settled by clarifying rather than by declining again.**
The item was raised a third time, but this round it offered the option I had not taken: clarify
the description instead of leaving the domain unpinned. That is the better fix. "counted round
the period" now reads "counted round the period, negative steps included", paid for by three
words trimmed elsewhere, and the test is back. It wraps `-1`, `-2` and `-4`, and it passes on
all four saved patches including Nova_4, so the measured rate is unchanged. When an ambiguity
keeps coming back and the behaviour is not actually contentious, adding the sentence beats
re-declining, because it converts an unpinnable corner into a stated requirement.

The other two are declined. The algebraic loop is now an eighth request; the batch evidence has
not changed and the description does not require a cycle to be rejected. The offsets-metadata
item is conditional on offsets being exposed as public `MultirateSystem` state, and they are
not: they are consumed at construction and no attribute stores them, so there is nothing to
assert. Exposing them to satisfy the suggestion would be unstated scope.

**Round 26 — the one unfair test was created by the previous round's fix.** Clarifying that
phase indices count round the period "negative steps included" made negative steps meaningful
for `phase_system`, which left the offsets rule inconsistent: it said only "below its ratio",
so rejecting a negative offset pinned a lower bound the description no longer implied. The
checker spotted exactly that contradiction. Fixed the same way, by stating it: offsets now run
"from zero and below its ratio", three words paid for elsewhere, and the rejection test stands
unchanged. Worth remembering that clarifying one corner can unpin an adjacent one; when a
sentence is added about a domain, re-read every other sentence that shares it.

Of the two suggestions, the algebraic loop is a ninth request and a seventh decline. The other
is taken and cleared intake replay on all four patches plus the reference: `phase_system`,
wrapped and negative indices, and `linearize` on a system built with a nonzero offset, where
only offset time responses and `poles`/`dcgain` were covered before. It also pins the thing
that actually matters about an offset, that the acting phase moves, by asserting phase 0 and
phase 1 differ.

**Round 27 — both suggestions declined, and this time with a number rather than an argument.**
Both ask for tests that were removed in the solvability round, so instead of re-arguing them I
wrote each candidate and ran it against the saved agent patches. Both fail on Nova_4, the only
passing agent, and on Nova_1 and Nova_5 as well. Adding either returns the artifact to 0/5.

- Direct-feedthrough cycle, tenth request. `pytest.raises((ValueError, RuntimeError))` on a
  cycle whose members both have feedthrough: Nova_4 FAILS. Its interconnection solves the
  invertible loop rather than raising, which the description permits, since the description says
  only where a loop is algebraic and never that one is rejected. The suggestion's second half,
  contrasting a holding phase, is unobservable anyway: if the acting phase raises there is no
  object left to inspect.
- Off-grid and negative `linearize` times: Nova_4 FAILS. Agents select the phase by rounding to
  the nearest step rather than the step holding the time. The distinction only shows for times
  the library itself never produces, and it costs the entire pass rate.

Nothing changed in the artifact this round, so the measured 1/5 and all validation still stand
on the bytes already recorded above.

## FP mapping

| meta.md clause | Tests |
|---|---|
| `commensurate_timebase` returns gcd, ratios, lcm | `commensurate_timebase_halves`, `_no_common_member`, `_three_rates`, `_equal_rates` |
| takes sample times, or systems carrying them | `commensurate_timebase_accepts_systems`, `commensurate_timebase_mixes_numbers_and_systems` |
| a non-finite, non-positive or unspecified timebase is incompatible | `_rejects_continuous`, `_rejects_negative`, `_rejects_nan`, `_rejects_infinite`, `_rejects_unspecified`, `_rejects_true`, `_rejects_system_without_timebase`, `_rejects_system_unspecified_rate`, `_rejects_continuous_system`, `_rejects_non_numeric` |
| a ratio further than 1e-9 relative from every fraction with denominator at most 1000 is incommensurate | `_rejects_incommensurate`, `_rejects_irrational_ratio`, `_denominator_limit`, `_beyond_denominator_limit`, `_inside_tolerance`, `_outside_tolerance`, `_just_inside_tolerance`, `_just_outside_tolerance` |
| every rejection raises `ValueError` | every `pytest.raises(ValueError)` above and below |
| `interconnect` returns a `MultirateSystem` at the base timebase with `period` and `nphases` | `interconnect_mixed_rates_type`, `multirate_three_subsystems`, `interconnect_rejects_incommensurate_rates`, `interconnect_rejects_beyond_denominator_limit`, `interconnect_rejects_nan_subsystem_rate`, `interconnect_rejects_infinite_subsystem_rate` |
| an unspecified subsystem timebase acts at every base step | `unspecified_subsystem_timebase`, `unspecified_discrete_subsystem_timebase`, `unspecified_dynamic_subsystem_timebase` |
| a subsystem acts every `k`th step and produces its output from its held state | `multirate_response_matches_rules`, `multirate_response_varying_input` |
| its state and output do not move otherwise | `multirate_slow_output_is_held`, `multirate_slow_state_is_held`, `multirate_fast_state_moves_every_step` |
| outputs come from the pre-update state, so listing order does not matter | `multirate_order_of_subsystems` |
| a subsystem that is not acting has no feedthrough | `multirate_loop_broken_while_holding`, `multirate_algebraic_loop_only_at_shared_steps`, `multirate_feedthrough_only_when_acting`, `multirate_all_direct_cycle_never_algebraic` |
| base is the gcd, period the lcm | `multirate_base_is_greatest_common_divisor`, `multirate_neither_acts_every_step` |
| one hold state per output, after its own states, named `<output>_hold` | `multirate_state_labels`, `multirate_hold_state_per_output`, `multirate_hold_register_tracks_output` |
| the hold state starts at zero | `multirate_slow_output_before_first_action`, `initial_hold_register_is_used` |
| `offsets`: a base step index, one per system, below its ratio, mixed rates only | `offsets_reject_fractional`, `offsets_reject_non_numeric`, `offsets_shift_the_first_action`, `offsets_change_the_response`, `offsets_out_of_range`, `offsets_negative`, `offsets_wrong_length`, `offsets_on_every_step_system`, `offsets_require_mixed_rates`, `offsets_unspecified_subsystem_is_ratio_one`, `offsets_across_three_rates`, `offsets_across_three_rates_out_of_range` |
| a continuous subsystem joins as its zero order hold equivalent and must be linear | `continuous_and_unspecified_subsystems_together`, `continuous_subsystem_is_sampled`, `continuous_subsystem_matches_sampled_loop`, `continuous_mimo_subsystem_sampled`, `continuous_transfer_function_subsystem`, `continuous_nonlinear_subsystem_rejected` |
| an ordinary interconnection when everything acts each step | `continuous_subsystem_single_phase` |
| discrete subsystems may be nonlinear | `nonlinear_subsystem_multirate` |
| a multirate subsystem repeats after its own period | `nested_multirate_period`, `nested_multirate_response`, `nested_multirate_state_labels`, `static_gain_keeps_period` |
| `phase_system(k)` is a base step counted round the period | `phase_system_nonlinear_subsystem`, `phase_system_nonlinear_model_behaviour`, `phase_system_matrices`, `phase_system_holding_matrices`, `phase_system_wraps`, `phase_system_negative_index`, `phase_system_large_index`, `phase_system_rejects_fractional_index`, `phase_system_rejects_non_numeric_index` |
| `poles` are the monodromy eigenvalues | `poles_are_monodromy_eigenvalues`, `offset_poles_and_dcgain`, `offset_phase_models`, `poles_match_lifted_system`, `poles_of_slower_loop` |
| `dcgain` is the per-step steady state, indexed step, output, input | `dcgain_matches_steady_state`, `dcgain_phase_dependent`, `dcgain_values_per_output`, `dcgain_multiple_inputs` |
| `linearize` returns the model at that step | `linearize_returns_phase_system`, `linearize_at_later_step`, `linearize_nonlinear_subsystem`, `linearize_wraps_past_the_period` |
| an empty list is incompatible | `commensurate_timebase_rejects_empty` |
| a single sample time is its own base and period | `commensurate_timebase_single_entry` |
| `poles`, `dcgain`, `lift` and negation need linear subsystems | `nonlinear_multirate_rejects_poles`, `_rejects_dcgain`, `_rejects_lift`, `_rejects_negate` |
| `lift` stacks inputs and outputs, earliest first, keeping the states | `lift_scalar_system`, `lift_keeps_states`, `lift_with_feedthrough`, `lift_mimo_ordering`, `lift_multirate_matrices`, `lift_multirate_keeps_state_labels`, `lift_multirate_matches_response`, `lift_multirate_with_offset` |
| `lift` takes a state space, transfer function or multirate system | `lift_transfer_function`, `lift_multirate_matrices`, `lift_rejects_nonlinear_system` |
| `lift` names its result | `lift_names_the_result` |
| `dt` must be a positive finite integer multiple of the sample time, and of the period | `lift_rejects_zero_sample_time`, `lift_rejects_negative_sample_time`, `lift_rejects_non_numeric_sample_time`, `lift_rejects_non_multiple`, `lift_rejects_shorter_sample_time`, `lift_multirate_two_periods`, `lift_multirate_rejects_partial_period`, `lift_multirate_rejects_odd_multiple` |
| `dt` defaults to the period, or the sample time when not multirate | `lift_default_sample_time`, `lift_multirate_matrices` |
| `lift` needs a specified, finite sample time | `lift_rejects_continuous`, `lift_rejects_unspecified_sample_time`, `lift_rejects_absent_sample_time`, `lift_rejects_non_finite_sample_time` |
| single rate `interconnect` still gives a `LinearICSystem` | `interconnect_all_continuous_unchanged`, `interconnect_single_rate_unchanged` (asserts the class directly), `equal_rate_nonlinear_interconnect_unchanged` |
| `*` and `+` keep their ordinary composition meaning | `operators_compose_with_multirate` |
| the operators still refuse different sample times | `operators_still_reject_mixed_rates`, `operators_multirate_reject_other_rate`, `interconnect_continuous_and_discrete_still_rejected`, `series_multirate_rejects_other_rate` |
| `series`, `parallel`, `feedback` take a multirate operand | `series_with_multirate`, `parallel_with_multirate`, `feedback_with_multirate`, `negate_multirate` |

Reverse direction: every test traces to a clause above. The three tests that pin an error
message (`operators_still_reject_mixed_rates`, `series_multirate_rejects_other_rate`,
`forced_response_time_step_check`) pin only strings the unmodified repository already emits.
`multirate_isdtime`, `multirate_signal_labels` and `multirate_named_result` assert timebase
and naming behaviour that `InputOutputSystem` already defines.

## Round 29 — 2 coverage suggestions: one real gap taken, one re-declined

**Taken: an all-direct cycle.** The reviewer was right that no test built one. The two
loop-named tests each miss half of it: `algebraic_loop_only_at_shared_steps` has a real cycle
but `strict` carries `D = 0`, so it never goes algebraic, and `loop_broken_while_holding` has
feedthrough on both members but connects them one way, so it is not a cycle. The gap was real.

The half of the suggestion that asks for `ValueError` on an all-direct cycle is not
implementable as written. Probing one shows `interconnect` raises `RuntimeError: algebraic loop
detected` from the repository's own `_compute_static_io`, before any multirate code runs. So
the suggested assertion is factually wrong about this system, and the corrected `RuntimeError`
version pins inherited behaviour the description never promises, which Test Fairness already
flagged as unfair in round 8. Neither form is available.

What is available is the other half, and it is stated: "a loop through it is algebraic only
where every system in it acts." `multirate_all_direct_cycle_never_algebraic` builds a cycle in
which BOTH members carry feedthrough and gives them `offsets` that alternate, so no phase ever
has both acting and the loop is never algebraic. Both phase models have `D = 0` and the
response matches a hand reference. Intake: Nova_4 passes 146/146; the test fails Nova_2 and
Nova_3 only, so 2 of 5, the same tier as the existing hardest tests and not a cliff.

**Re-declined: lift channel labels.** Third request. This is `lift_signal_labels`, one of the
two tests that failed 5 of 5 and caused the 0/5 batch; four evaluators independently called it
unstated. The description fixes the numerical stacking ("earliest first") and that states are
kept, and says nothing about channel names. Adding the test means adding a naming rule to the
description, and the measurement says the cost is the submission: every stored patch fails it.
The stacking order the suggestion wants confirmed is already covered numerically by
`lift_mimo_ordering` and `lift_with_feedthrough`.

## Round 30 — test-quality WARNING on label and message brittleness

Advisory, no critical errors. All three flagged items were checked against the base commit
rather than argued about, and two of them are inherited convention:

`input_labels == ['u[0]']` / `output_labels == ['y[0]']` is what an equal-rate `interconnect`
already produces on the unmodified base commit, so it is python-control's own default naming.
It fails 0 of 5 stored implementations, which is the measurement that matters: every agent gets
it free and it cannot be a hidden requirement.

The cross-subsystem `state_labels` order is likewise base-native (`<subsystem>_<state>` in
listing order, confirmed on base). The only new part is the hold register, and the description
states both its name and its position: "one extra state per output, after its own states, named
for the output with `_hold` appended". These assertions are how trap 2 is caught structurally,
holding the input instead of the output produces correct values at the action steps and wrong
ones in between, and the three label tests are real discriminators at 1 of 5 each. Kept.

One item was a genuine fix. Of the seven `match="incompatible timebases"` pins, six sit on
paths the unmodified repository already owns (`fast * slow`, continuous-plus-discrete `series`),
where pinning the message is the guard against a solution that broadens `common_timebase`,
which is trap 5. The seventh, in `series_multirate_rejects_other_rate`, pinned wording on a NEW
code path where the description promises only `ValueError`; its sibling
`operators_multirate_reject_other_rate` tests the identical scenario with a bare `ValueError`,
so the pin was inconsistent as well as unpromised. Relaxed. The tally is unchanged: Nova_5 still
fails that test because it omits the rejection entirely, not because of the message text.

## Round 31 — second 0-batch (Nova x10), caused by a contradiction in the meta

Ten runs, 0 passes, but the histogram was not flat: Nova_6 failed ONE test, Nova_7 and Nova_9
two, Nova_1 and Nova_8 four. Three tests failed 7 of 10 and two more failed 6 of 10.

The 7/10 cluster is a single defect and it is mine. `nested_multirate_period`,
`static_gain_keeps_period`, `feedback_with_multirate` and `nested_nonlinear_response` all die on
`assert isinstance(sys, ct.MultirateSystem)` after the agent built a plain `InterconnectedSystem`
at dt=0.1. The meta's last paragraph told them to: "`interconnect` on equal sample times still
builds a `LinearICSystem`", and in all four tests every sample time IS equal (0.1). The agents
followed my sentence; the tests contradicted it.

`phase_system_rejects_fractional_index` (6/10) was simply unstated, the same coverage-suggestion
class that caused the first 0-batch.

Both fixed by aligning the meta to the tests, not by deleting tests: the single-rate paragraph
now applies only "where no subsystem is multirate", the operators "take a multirate operand,
including against a plain gain, and return a `MultirateSystem` keeping its period", and
`phase_system` states "a step that is not a whole number rejected". Tests and solution untouched.

Two measurements rather than projections. Nova_6's patch plus the two lines for the whole-number
rule passes 146/146, so the artifact is solvable by a real agent implementation. And Nova_1 plus
the minimal gate fix for the class rule STILL fails all four nesting tests, now on `0.1 != 0.2`,
because the outer period must fold in the nested period, a requirement that was already stated
and that it did not implement. The fix removes the unfairness without giving away the hard part.

Meta is now 526 words, over the documented 500 cap, at the user's explicit direction.

## Round 32 — batch 39: meta fix confirmed, one exception-class pin removed, 2/10

The round-31 corrections worked. The nesting family went 7/10 failures to zero and
fractional-index went 6/10 to zero: agents implement a rule once the description states it.

One defect remained. `lift_rejects_nonlinear_system` failed 7 of 10, all with `TypeError`, and
Nova_3 and Nova_4 failed nothing else. The test hands `lift` a plain `NonlinearIOSystem`, which
is none of the three kinds the description says it takes, so agents rejected it with the
idiomatic exception for a wrong-type argument and I failed them on the class. My own reference
only passed because of guards I had added converting `TypeError` to `ValueError` - the tell that
the pin was fighting the language, not testing behaviour.

Relaxed to `(ValueError, TypeError)` on the three wrong-TYPE rejections only. Domain rejections
keep `ValueError` as stated, including a nonlinear MULTIRATE system passed to `lift`, which is
the right type with the wrong property.

Replayed all ten against the corrected suite: **Nova_3 and Nova_4 pass 146/146, so 2/10 = 20%**,
inside the cap and on the hard side. Per-test tally over the ten: 123 clean, 18 at 1/10, 4 at
2/10, 1 at 3/10, nothing above. No cliff, difficulty spread over 23 tests.

The lesson from four 0-batches: my local oracle was stored patches from agents that never saw the
corrected description, so a spec bug could only be discovered by the NEXT batch. The two failure
signatures that matter are "DID NOT RAISE" (missing behaviour, fix by stating the rule) and
"correct rejection, wrong exception class" (unfair pin, fix by relaxing it). Reading the failure
TEXT rather than the count separates them.

## Round 33 — Description Quality FAIL: 4 style fixes taken, 1 contested

Four comments were phrasing and are applied: the motivational preamble is gone, the `ValueError`
sentence reads naturally (scope kept, since it is the only place the class is stated for the
later rejections), "the result is ordinary" is now concrete, and "Nothing single rate moves"
became "Keep existing single rate behavior unchanged".

The fifth, flagging "where no subsystem is multirate" as over-specification, is contested. It is
not an internal detail: whether a subsystem is itself multirate is a property of the argument the
caller passes, and it is what the tests assert on the result. The check's reasoning that the
tests "do not inspect or depend on this internal characterization" is wrong;
`nested_multirate_period`, `static_gain_keeps_period`, `feedback_with_multirate` and
`nested_nonlinear_multirate_response` all interconnect systems at EQUAL sample times (all 0.1)
and assert `isinstance(sys, ct.MultirateSystem)`, which the unqualified preceding sentence
contradicts.

The measurement settles it: with the clause absent, `agent-runs(37)` had 7 of 10 agents fail
those four tests; with it present, `agent-runs(39)` had 0 of 10. Removing it re-creates the exact
contradiction that produced a 0-batch. Kept, rephrased to "unless one of the subsystems is itself
multirate". Response written to `contest-description-quality.md`.

Meta is now 534 words.

## Round 34 — Auto Review revision + FP report: contract tightened, 4 FP holes closed

**Auto Review** scored Description 3/3 and Solution 3/3, Tests 1/3, on one issue: the three
`pytest.raises((ValueError, TypeError))` relaxations from round 32. The reviewer is right and I
was wrong to relax them. My own meta says "Raise `ValueError` ... for every other rejection
described here", so the exception class is a stated contract and enforcing it is fair, not a pin.
All three are back to `ValueError` alone, plus the requested `phase_system(np.nan)` and
`phase_system(np.inf)` coverage.

To keep that fair rather than merely strict, the `lift` paragraph now names its rejections
explicitly ("A system of any other kind, a `dt` that is not such a multiple, and a `dt` that is
not a finite number are all rejections"), so the `ValueError` contract reaches them by the
sentence that already governs every rejection. Tightening alone would have been the same mistake
as before: an enforced rule that the description mentions only in passing.

**FP report** flagged 2 of the 3 batch-40 passers as false positives, with four probes. I ran all
four against the reference first: it is correct on every one, so these are genuine holes in the
SUITE, not reference bugs. The nested-finer-base trajectory the adjudicator quotes
(`[0,0,0,0,0, 1.5,1.5,1.5,1.5, 3.075,...]`) reproduces exactly, and I hand-checked 3.075 =
0.8*1.5 + 1.875. All four are now tested:

| Probe | Prompt sentence | Fails on the batch-40 pool |
|---|---|---|
| nested multirate on a FINER outer base keeps its own period | "a multirate one repeats after its own period, not its sample time" | 3/11 |
| `offsets` rejected when all outer rates are equal | "only when sample times differ" | 1/11 |
| `linearize` at an interior time gives the holding step | "the model at the step holding its time" | 9/11 |
| `phase_system` rejects a near-integer step | "not a whole number" | 7/11 |

The last two are cliffs, and the adjudicator itself called the near-integer one "defensible but
weaker". Rather than drop coverage the FP check demands, both rules are now unmistakable in the
meta: "a step that is not exactly a whole number rejected, with no tolerance for one that is
merely close", and "so a time inside a step gives that step rather than an error". This is the
same move that took the nesting rule from 7/10 failures to 0/10 and the fractional-index rule
from 6/10 to 0/10.

Evidence the probes are satisfiable: **Nova_4 passes all four** and fails only
`operators_compose_with_multirate`, a separately stated requirement.

**Honest standing.** On the stored batch-40 patches the suite is now 0/11, because every one of
those agents predates both clarifications. That is the same stale-oracle limit that has misled me
before, and I am not going to claim a rate it cannot support. What the pool does establish: the
four probes are all passable by an existing implementation, and the two cliffs sit on rules that
were previously implicit and are now explicit. Batch 40 produced 3 passers on the looser suite, so
the feature is comfortably implementable; the open question is only whether the clarified wording
converts.

## Round 35 — the last gap was `*` and `+`, and solvability is now proven

Chasing the remaining failures produced a real description defect, not a hint problem.
`operators_compose_with_multirate` requires `inner * extra` to equal `series(extra, inner)` and
`inner + extra` to equal `parallel(inner, extra)`, but the meta said only "the last three"
(`series`, `parallel`, `feedback`) take a multirate operand. `*` and `+` were excluded by my own
sentence. Nova_4 had implemented that exclusion literally:

    def __mul__(self, other):
        raise ValueError("direct multiplication of multirate systems is not supported")

An agent writing an explicit refusal for the case my tests require is the clearest possible
evidence the description, not the agent, was wrong. Now stated: "all five take a multirate
operand ... with `*` and `+` agreeing with `series` and `parallel`".

Also stated, for the FP probe at 3/11: a nested multirate subsystem "keeps its own base and
period, so where the outer base is finer than its own it advances one of its own steps only once
every several outer steps".

**Solvability proof.** Nova_4's own patch, plus the minimal implementation of the now-stated
operator rule (delegate `__mul__`/`__add__` to `series`/`parallel` instead of raising), passes
**151/151**. Nova_5's three remaining failures are likewise all newly-stated rules
(nested-finer-base, interior-time `linearize`, exact whole-number step), so the same applies
there. The suite is passable by a real agent implementation once the rules it enforces are in the
description.

The pattern across every 0-batch on this task has been identical: a behaviour my tests required
that my description either omitted, contradicted, or explicitly excluded. Four rounds of it:
the equal-rate class rule, the fractional index, the `lift` rejection class, and now `*` and `+`.

## Round 36 — 3 coverage suggestions, and two of them found reference bugs

All three taken. Two were not coverage gaps at all, they were places where the reference
contradicted the description I had just written.

`phase_system(1.0)` raised. The meta says a step that is "not exactly a whole number" is
rejected, which is value language, but the reference used `operator.index`, which rejects a whole
valued float on type. Same for a float offset. Fixed with a shared `_base_step` that accepts a
value equal to a whole number and still rejects 0.5, 1+5e-10, NaN and Inf.

`inner * 2.0` and `inner + 2.0` returned a plain `InterconnectedSystem` with `period` None, while
`series` and `parallel` against the same gain returned a `MultirateSystem`. That directly
violates the round-35 sentence "all five take a multirate operand, including against a plain
gain, and return a `MultirateSystem` keeping its period": `*` and `+` bypassed the block diagram
helpers. `MultirateSystem` now defines `__mul__`, `__rmul__`, `__add__` and `__radd__`
delegating to `series` and `parallel`, which is exactly the fix that made Nova_4 pass.

The third, `lift` on an arbitrary object, was already correct and is now covered.

Five tests added (unsupported `lift` argument, plain gain across all five composition forms, a
scaled response against the reference, whole valued float phase index, whole valued float
offset). 156 total.

**Solvability proof re-checked against the enlarged suite:** Nova_4 plus the minimal
implementation of the stated `*`/`+` rule passes **156/156**.

Effective LOC rose to 392 with the operator delegation and `_base_step`.

## Round 36 — 3 coverage suggestions, two of which found reference defects

All three taken. Two were not coverage gaps at all, they were places where the reference
contradicted the description I had just written.

**Whole valued float phase index.** The meta says "a step that is not exactly a whole number
rejected", which is value based language, but `phase_system` used `operator.index`, so
`phase_system(1.0)` raised. The suggestion is right: exactly-a-whole-number is a property of the
value, not of the Python type. Same defect on a float `offsets` entry. Fixed with a shared
`_base_step` helper that accepts an integer type or a whole valued float and still rejects 0.5,
1 + 5e-10, NaN and inf.

**Plain gain composition.** Round 35 added "all five take a multirate operand, including against
a plain gain, and return a `MultirateSystem` keeping its period". The reference did not do that:
`inner * 2.0` and `inner + 2.0` returned a plain `InterconnectedSystem` with `period=None`,
because `*` and `+` bypassed the block diagram helpers. `series` and `parallel` were already
correct. Fixed by giving `MultirateSystem` `__mul__`/`__rmul__`/`__add__`/`__radd__` that delegate
to `series`/`parallel`, which is exactly the change that made Nova_4 pass.

**Unsupported lift object kinds** was a genuine coverage gap and the reference already behaved
correctly; now tested against an ndarray and a nested list.

Five tests added (156 total). Solution grew to 392 human-effective LOC.

**Solvability re-proven on the enlarged suite.** Nova_4 plus the single stated operator fix passes
**156/156**.

Per-test tally across the 11 stored implementations: 113 clean, 19 at 1/11, 17 at 2/11, 3 at
3/11, 2 at 4/11, and the two known cliffs at 7/11 and 9/11. Both cliffs are the FP probes whose
rules are now spelled out in the meta (`linearize` at an interior time, exact whole number step);
every stored patch predates that wording.

## Round 37 — test-quality WARNING: both concerns measured, one real nit fixed

Advisory, no critical errors, and the same two items as round 30. This time they were measured
against the 11 stored implementations rather than argued about.

**Error-message pins: 0 of 11.** All three tests carrying `match="incompatible timebases"` pass on
every stored patch. The string is the unmodified repository's own: `common_timebase` raises
`ValueError("Systems have incompatible timebases")` at the base commit, so any implementation that
routes through it gets the match free. Pinning it is what guards against a solution that broadens
`common_timebase`, which `timebase_test.py::test_composition` also protects.

**State-label assertions: 0 to 1 of 11.** `multirate_state_labels`,
`multirate_hold_state_per_output`, `lift_multirate_keeps_state_labels` and
`multirate_order_of_subsystems` each fail exactly one implementation;
`nested_multirate_state_labels` and `multirate_signal_labels` fail none. The cross-subsystem
`<name>_<state>` order is base-native, confirmed by running an equal-rate `interconnect` on the
base commit, and the only new part is the `_hold` suffix, which the description mandates by name
and position.

The one label-adjacent test with real failures, `continuous_mimo_subsystem_sampled` at 4 of 11, is
not a formatting pin. Two agents raise `ValueError: couldn't find system 'plant'` and one produces
`plant$sampled`: their ZOH conversion drops the subsystem name, so the named `connections` list
cannot resolve at all. Auto Review reviewed the same failures and called them fair, implied by the
repository's named wiring model. Kept.

**Fixed:** the reviewer also spotted a short `x0` in `linearize_between_base_steps`, which passed
a 2-vector to a 3-state system. Harmless for a linear system, but sloppy. Corrected to
`[0., 0., 0.]`.

## Round 38 — Test Fairness FAIL 1/156, plus 2 coverage suggestions

**The unfair test is removed and the reviewer is right about why.**
`test_offsets_accept_whole_valued_float` required `offsets=[0, 1.0]` to be accepted. The meta
gives offsets a meaning and bounds ("the first base step each subsystem acts at, one per system,
from zero and below its ratio") but never a representation rule, so integer-only validation and
integral-float acceptance are both reasonable. Contrast `phase_system`, where the meta does say
"not exactly a whole number", which is why the reviewer passed
`test_phase_system_accepts_whole_valued_float` as fair from explicit wording. The offsets test was
mine over-reaching from one stated rule onto an adjacent unstated one, the same shape as the
round-25 mistake. Removed; 155 tests.

The solution keeps accepting whole valued floats for offsets. A solution that is a superset of the
tests is fine; only the TEST was pinning the unstated choice.

**Coverage suggestion 1, shared-phase algebraic loop: declined, twelfth request.** A genuine
direct-feedthrough cycle whose members all act on one phase raises
`RuntimeError("algebraic loop detected")` from the repository's own `_compute_static_io`, before
any multirate code runs. The description never promises that behaviour, and pinning that inherited
string was flagged unfair by Test Fairness back in round 8. The stated half of this suggestion is
already covered by `multirate_all_direct_cycle_never_algebraic`, which the same report rated a
"strong disjoint-offset cycle case".

**Coverage suggestion 2, singular dcgain: declined on a measurement.** The suggestion is
conditional ("if singular or unstable systems have an intended convention"). The reference does
have one, `ValueError` when the monodromy leaves no unique steady state, so I wrote the test and
intake-tested it: **it fails 10 of the 11 stored implementations**, the largest cliff measured on
this task, and the meta says nothing about a missing steady state. Stating a brand new requirement
this late for a marginal edge case is a bad trade against a 10/11 cliff. The reference behaviour is
unchanged and simply untested.

## Round 39 — 3 coverage suggestions: 1 taken, 2 declined on measurement

**Taken: plain-gain arithmetic values.** `scaled_multirate_matches_reference` covered `*` by
value but `+` was only checked for metadata. `added_gain_matches_reference` now checks both
`cascade + 2.0` and `2.0 + cascade` against the reference response plus two. Intake: fails 2 of
11, the same tier as the other operator tests, no cliff. 156 tests.

**Declined: exact commensurability threshold.** The idea is sound, the arithmetic does not
cooperate. The natural construction `2.0 * (1 + 1e-9)` does not land on the boundary: its
deviation from 2 is 2.000000165e-9 against a threshold of 2.000000002e-9, so it rejects. Landing
exactly on `|frac - ratio| == 1e-9 * |ratio|` needs bit-level construction, and whether an
implementation uses `<=` or `<` at that single representable point is a choice no solver could
be expected to match. The existing pair already brackets the rule tightly at 9e-10 accepted and
1.1e-9 rejected, which the same Test Fairness report singled out for praise: "Potential floating
boundary sensitivity is mitigated by using 0.9x/1.1x, not exact equality". Adding the exact case
would undo precisely what it commended.

**Declined: shared-phase algebraic loops, thirteenth request.** Unchanged and still measured: a
cycle whose members all act on one phase raises `RuntimeError("algebraic loop detected")` from the
repository's own `_compute_static_io` before any multirate code runs. The description never
promises it, and pinning that inherited string was flagged unfair by Test Fairness in round 8.

## Traps

1. The base timebase is the gcd, not the fastest subsystem's rate. A 2:3 pair has no
   subsystem acting every step.
2. Holding the output costs a state per output. Holding the input instead reproduces the
   right values at the action steps and the wrong ones in between, with no error.
3. Feedthrough has to vanish at hold steps, otherwise a loop through a slow block reports a
   spurious algebraic loop.
4. Outputs come from the pre-update state; a sequential update makes the result depend on the
   order the subsystems were listed in.
5. `common_timebase` must not be relaxed: `timebase_test.py::test_composition` pins
   `(0.2, 0.1) -> ValueError` for `series`, `parallel` and `feedback`.
6. A nested multirate subsystem repeats after its period, not its sample time, so an outer
   interconnection at one single rate can still be periodic.
7. The lifted `D` is block lower triangular and each block carries a different power of the
   state matrix.
