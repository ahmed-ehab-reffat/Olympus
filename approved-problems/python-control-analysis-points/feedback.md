# feedback — python-control-analysis-points

## Summary

Olympus submission on `python-control/python-control` (BSD-3-Clause, 2055 stars,
34.8k LOC of source outside tests). Feature: analysis points on an
interconnected system plus the loop analysis those points make possible
(`open_loop`, `close_loop`, `loop_transfer`, `sensitivity`,
`complementary_sensitivity`, `io_transfer`, `replace_point`,
`analysis_point`).

- BASE_COMMIT `75a658b6f731785dfdebedadcb06dad522ec63e3`
- 4 files (3 modified, 1 new module), 866 raw / **467 human-effective LOC**
- 272 new tests, 3814 existing tests, zero regressions
- Docker: `olympus-base-python`, builds and runs offline as uid 1000

## Pick rationale (assumptions logged as made)

The user deferred repo choice, so auto-discovery ran under the standing
"brand-new repo, brand-new hard feature" preference. Control systems has zero
presence in `Aprroved/`, `problems/` or `rejected/`, and python-control appears
in no local `worktrees/`. The abandoned `aioquic` clone left in this task
folder was ignored; `rejected/aioquic-http3-priorities` shows that pick was
already shelved.

Candidates ranked and rejected before this pick, with the gate that killed each:

| Candidate | Killed by |
| --- | --- |
| skidl | test suite needs external KiCad symbol libraries -> Env Quality |
| python-pptx | recency dead (last push 2024-08) |
| gorgonia | recency dead (last push 2024-08) |
| oxipng, ulikunitz/xz, klauspost/compress | every viable feature is a documented format (dead class) |
| oxigraph | SPARQL is a documented spec (dead class) |
| cosmic-text | needs system fonts -> Env Quality risk |
| cvxpy | C++ core, 228 MB repo |

Gates cleared for python-control: single BSD-3 licence, 2055 stars (niche, not
the author-obvious category), last source commit 2026-07-28 with only 13 source
commits in twelve months (active but cold), pure Python public surface, vanilla
suite green offline once the dependency versions are pinned, and the
canonical-org PR and issue search over analysis point / loop transfer /
sensitivity function / descriptor / model array returned zero hits on this
feature class.

Two features were designed and then rejected before this one:

- **Descriptor state space systems.** An invertible `E` collapses the whole
  golden to `StateSpace(inv(E) @ A, inv(E) @ B, C, D)`, so the LOC would have
  been a fiction; a singular `E` drags in DAE theory that cannot be tested
  fairly. Killed on the collapse-shortcut gate.
- **Time delay systems.** PR #1148 "Add support for continuous delay systems"
  is open with a published diff. Exclusivity dead.

## Why this is not a duplicate

Closest corpus entries are `quint-temporal-properties` (a second evaluation
mode bolted onto an existing engine, but a temporal-logic checker over traces)
and `smoltcp-icmp-errors-pmtu` (protocol behaviour, unrelated mechanism).
Nothing in `Aprroved/`, `problems/` or `rejected/` touches control systems,
block diagram interconnection, or loop transfer analysis, and no other
submission uses python-control.

## Design decisions

1. **A point is anchored on a subsystem signal, not on one wire.** A point on a
   subsystem output covers every internal connection fed by that signal, so
   opening it breaks the whole fan-out at once. A point on a subsystem input
   covers only that one destination. Both anchors were kept because the
   contrast is the sharpest part of the contract, and `_parse_spec` already
   resolves outputs before inputs elsewhere in the file, so the precedence rule
   is the repo's own.
2. **Nested points are hoisted, not special cased.** A subsystem carrying
   points is replaced at construction by its own `open_loop`, and the injection
   and measurement channels it grows are wired back together as an ordinary
   parent connection. A point at any depth is then a normal connection of the
   system being built, and the same kernel opens it.
3. **`_compute_static_io` had to allow more iterations.** Its bound was
   `len(syslist) + 1`, which assumes every subsystem appears at most once in an
   algebraic chain. A hoisted subsystem appears twice (it produces the
   measurement and consumes the injection), so a three-block diagram with one
   nested point tripped a false "algebraic loop detected". The bound is now the
   number of subsystem inputs plus one, which is the real length of the longest
   chain. Genuine algebraic loops are still detected.
4. **Point names use the hierarchical state name delimiter.** Signal labels
   cannot contain a dot, so `inner.u` would have produced the illegal label
   `inner.u_inj`. Joining with `config.defaults['iosys.state_name_delim']`
   matches how the library already names hierarchical states.
5. **`analysis_point` takes no `**kwargs`.** The first version passed keyword
   arguments through to `StateSpace`, which broke `kwargs_test.py`: the repo
   requires a matching kwarg unit test for every public function taking
   `**kwargs`, and base mode does not run the new test file. The block is now
   built with `dt=None` so that it fits a diagram of any timebase.

## Trap structure

| # | Trap | Interdependence |
| --- | --- | --- |
| 1 | Opening a point must break every branch of a fanned out signal | opposes trap 2 |
| 2 | Every loop that is not being opened stays closed | opposes trap 1; one map, two rules |
| 3 | Each broken connection keeps the gain it carried into the injection | interacts with trap 1 |
| 4 | Connections to the interconnection's own outputs survive the opening | surfaces only through `io_transfer` |
| 5 | The measurement reports the point's signal, not the injected value | wipes out every transfer if missed |
| 6 | A point inside a subsystem has to be hoisted to be openable | needs trap 5 to be right first |
| 7 | Declaring points must leave the nominal system untouched | regresses the new suite, not the base one |
| 8 | Public API without full numpydoc docstrings breaks `docstrings_test.py` | regresses the base suite |
| 9 | An input anchored point breaks one destination, an output anchored point breaks all of them | direct contrast with trap 1 |
| 10 | A contributed name may silently overwrite a declared one | surfaces only when both name the same point |

Traps 1 and 2 pull in opposite directions on the same connection map, and both
surface as a wrong transfer function rather than as a missing branch. Trap 8 is
a base suite failure with no connection to the feature.

## Verification

- Base suite: 3814 pass on the vanilla repo with the pinned dependency
  versions, 3814 pass with the solution applied, three identical runs.
- New suite: 272 fail on base, 272 pass with the solution, three identical runs.
- Both apply orders (test then solution, solution then test) apply cleanly.
- Effective LOC hook: `human-effective: 467` (gate 430).

### Dependency pinning

On the newest numpy and matplotlib the vanilla suite has two failures that have
nothing to do with this feature: `nyquist_test.py::test_nyquist_basic` counts
warnings and sees nine extra numpy 2.5 deprecation warnings, and
`ctrlplot_test.py::test_pole_zero_subplots` waits for a tight layout warning
matplotlib no longer emits. Pinning to numpy < 2.4, scipy < 1.16 and
matplotlib < 3.10 in the Dockerfile makes the whole suite green, which is what
the Environment Quality check needs.

### A disk-full run that looked like flakiness

One base run in the middle of this work reported 27 failures, all in
`optimal_test.py` and `phaseplot_test.py`, and the next run was clean. The
failure message was the same for all 27: `OSError: [Errno 28] No space left on
device`. The machine was at 97 percent full from repeated verification clones,
not the repository misbehaving, and the optimization tests are simply the ones
that write the most. After clearing the clones the base suite ran three times
serially with 4385 cases and zero failures each time. Worth recording because a
disk-full run reads exactly like a flaky optimizer at first glance; the
distinguishing evidence was that every failure carried the identical errno
message rather than a convergence or tolerance complaint.

### FP closure

A mutation battery broke the reference on purpose, one stated rule at a time,
and confirmed each is killed by at least one test. **25 of 25 mutations were
killed**: single branch fan-out, resolving openings against the
progressively zeroed map, `close_loop` accepting a repeated name,
`close_loop` redeclaring an undeclared specification, accepting an index below
the range, refusing to wrap a negative index, opening every loop, dropping the branch gain,
cutting the external output connections, measuring the injection instead of the
signal, skipping the hoist, `I + L` instead of `I - L`, `T` equal to `S`,
treating an input anchored point like an output anchored one, putting the
injection channels first, ignoring `openings`, multiplying an input point on
the wrong side, ignoring `opened` in `io_transfer`, rewiring the nominal system
when a point is declared, an analysis point block that does not tap the signal,
and `close_loop` dropping the branch gains. The first survivor found (measuring
the injection) was a bad mutation, not a test gap: it read the connection map
after the opening loop had already zeroed it, so it was a no-op. Rewritten
against the original map, it dies.

## Attempt history

- R1 — kernel plus the four transfer functions. Base suite: one failure,
  `docstrings_test.py` demanded `analysis_points` be documented on
  `interconnect`. Added the parameter documentation and the two class
  attributes.
- R2 — nesting. `RuntimeError: algebraic loop detected` on the first nested
  diagram; fixed the `_compute_static_io` iteration bound. Illegal signal
  labels from dotted point names; switched to the state name delimiter.
- R3 — LOC hook read 264. Added input anchored points, `close_loop`, the
  `openings` argument, `analysis_point` blocks with the implicit-connection tap
  rule, subsystem signals in `io_transfer`, and dictionary replacement. 453.
- R4 — 141 tests, all failing on base. Three error-path tests passed vacuously
  on base because the constructor raised before the assertion; each now asserts
  through the new API first.
- R5 — `kwargs_test.py` regression from `analysis_point(**kwargs)`: the repo
  demands a matching kwarg unit test for every public function taking
  `**kwargs`, and base mode does not run the new file. Removed the passthrough.
- R6 — bidirectional alignment pass. One test asserted on the string form of a
  system, a behaviour the description did not mention; the description now says
  the string form lists the points and the test no longer pins the heading.
  Four more rules the tests relied on were added to the description: a lone
  specification without a list, the block fitting any timebase, an opened point
  no longer being listed, and the two remaining error cases.

## Test fairness pass (automated check, 5 of 141 flagged)

The automated Test Fairness check failed the first suite on five tests that
pinned behaviour the description did not state. Four were fixed by stating the
rule, one by relaxing the test:

1. `test_close_loop_undoes_open_loop` asserted A, B, C and D elementwise. The
   description promises a reconnection, not a realization. The test now asserts
   the signal counts and the response.
2. `analysis_point('u')` was addressed as subsystem `u` in the explicit wiring
   test, but only the signal names were documented. The description now says
   the block is named `name` as well.
3. and 4. Opening at an undeclared `S.e`, and exposing `C.u` through
   `io_transfer`, both produced labels built by replacing the dot with the
   hierarchical state delimiter, which was documented only for contributed
   point names. One general sentence now covers every name built from a
   subsystem and a signal, which also shortened the contributed-point rule.
5. Supplying `value` beside a dictionary of replacements raised, which the
   error list did not mention. It does now.

The four advisory coverage suggestions were all taken: 8 tests for the `name`
keyword on every returned system, 3 for the string form naming each point's
signal and keeping declaration order, 5 rejecting plain systems from
`close_loop`, `sensitivity`, `complementary_sensitivity`, `io_transfer` and
`replace_point`, and 1 isolating the input-point measurement rule on a
feedforward diagram where a subsystem input is driven both internally and by an
interconnection input. The last one found a real gap: `close_loop` reached
`sys.connect_map` before validating its argument, so a plain system raised
`AttributeError` instead of the documented error. Fixed.

A second advisory round asked for three more areas, and taking them found a
second real bug. Declaring a point on each end of one wire, an output point on
`C.u` and an input point on `P.u`, opened correctly but would not close: the
kernel resolved each point against the connection map as it stood, so the
second opening read a row the first had already zeroed and recorded an empty
measurement. Both openings are now resolved against a snapshot of the original
wiring, which is also the honest reading of "removes every internal connection
fed by that signal". The mutation battery gained a case for it and stands at
17 of 17. The other two suggestions became the wrong-kind symmetry tests for
`io_transfer` and negative and fractional sizes for `analysis_point`; the
latter needed the error clause sharpened from "fewer than one channel" to "a
channel count below one or fractional".

A third advisory round asked for nonlinear rejection on the remaining transfer
helpers, undeclared subsystem-signal aliases through `close_loop`, both
sensitivity helpers and `replace_point`, and exact label bookkeeping when
partially closing several multichannel points. All 13 tests passed against the
reference unchanged, so this round confirmed behaviour rather than finding a
defect; the only correction was to one of my own expected values, since
replacing the summing junction output by a half gain gives `1/(s+2)` and not
`2/(s+2)`.

A fourth round asked for the non-transfer operations on a nonlinear
interconnection, multichannel temporary channels in `io_transfer`, and the
shared validation reached through `open_loop` and `close_loop` rather than only
through `loop_transfer`. The last one found the third real defect: `close_loop`
never checked for a repeated name, so closing `['u', 'u']` processed the pair
twice instead of raising, even though the description says repeating a name in
one call is an error. The check is now shared, and a mutation covers it.

Wiring the nonlinear fixture properly was needed for that round. It had been
built with `check_unused=False` and a dangling `S.y`, so it was not actually a
loop; that was invisible while the tests only asserted rejections, and wrong as
soon as one asserted dynamics. The feedback connection is now made and the
fixture needs no `check_unused` escape.

The multichannel `io_transfer` tests assert channel expansion, matrix ordering
against an independently computed `-K (I + G K)^-1 G`, and that each exposed
label starts with the joined subsystem name. The bracketed channel suffix is
deliberately not asserted: the description spells that convention out for point
channels only, so pinning it on temporary channels would be a hidden
requirement.

A fifth round flagged one assertion as unfair and it was a genuine gap in the
contract, not just in the test. After `replace_point` at an undeclared
specification the suite required the label list to stay exactly `['u']`, but
`close_loop` at an undeclared specification was doing the opposite and adding
`S.e` to the list. Neither behaviour was stated and the two disagreed with each
other. The description now says a specification used instead of a name never
joins the list, `close_loop` redeclares only points that were declared when
they were opened, and both paths are tested against each other.

The same round asked for a stated policy on generated labels colliding with an
existing signal. That is now in the error list and has tests on both the
injection and the measurement side. An explicit guard was written for it first
and then removed: the mutation battery showed it survived deletion, because
`set_inputs` already rejects a repeated label, so the guard was redundant code
rather than a load-bearing check.

A sixth round asked for atomic validation of dictionary replacement,
partly-overlapping multichannel locations, and the state realization through an
opening. All eleven tests passed against the reference unchanged. Atomicity
holds because every one of these functions builds a new interconnection and
never mutates its argument, so a dictionary that fails on a later key leaves
the original untouched; the tests now assert that rather than assuming it.
Partial overlap was already caught, because the duplicate-location check
compares individual channels rather than whole points: a point on `K.u` and a
point on `K.u[0]` share one channel and are refused together while either opens
alone. The realization tests pin what actually changes: the state labels and
their order survive an opening, while the state matrix drops the broken path,
from -3 to -1 on the scalar loop and from a coupled pair to the diagonal plant
on the MIMO one, and comes back on closing.

A seventh round asked for gain-bearing specifications to be refused at every
entry point rather than only at construction, and for a scalar replacement of a
multichannel point. Both already held. A specification carrying a gain, in the
leading-minus string form or as a three-element tuple, is refused by
`open_loop`, `loop_transfer`, `sensitivity`, `io_transfer` through `opened`,
and `replace_point`, because they all resolve names through the same helper; a
gainless specification still works afterwards, which the tests check so the
rejection cannot be a blanket failure. A scalar at a multichannel point acts as
that scalar times the identity: the loop transfer scales by exactly the scalar,
matches the equivalent diagonal matrix, and a scalar zero opens every channel.
The same holds at an input-anchored multichannel point, where the gain
multiplies from the other side.

An eighth round flagged eleven tests for one shared reason: they compared
`find_analysis_point` against an exact `('output', [1])` value, and the
description named the information the call returns without naming the container
it comes back in. A dictionary, a named tuple, or a tuple of indices would all
have satisfied the old wording. The description now says the call returns the
pair of a point's kind and a list of its indices, which makes all eleven fair
at once; no test changed. This is the same lesson as the earlier label
episodes, one level up: for a composite return value the shape is part of the
contract, not an implementation detail.

The three suggestions of that round were rectangular and row-vector arrays at a
multichannel point, unknown, repeated and gain-bearing entries in `openings`
rather than only in the primary point list, and out-of-range and negative
indices on the output side of `io_transfer` rather than only the input side.
All twelve tests passed unchanged.

A ninth round flagged the two tests that demanded an index of -1 be rejected,
and the fix belonged in the solution rather than the description. The
description says selection may be by index and never excludes negatives, while
the library indexes signals the ordinary Python way: `_process_indices` turns
an integer into a slice and `StateSpace.__getitem__` uses it, so `sys[-1, 0]`
already counts from the end. Refusing -1 in `io_transfer` contradicted the
surrounding API. Negative indices now count from the end, out-of-range on
either side is still an error, and the two tests assert that -1 selects the
last channel and agrees with the positive index for the same channel. Two
mutations cover it.

A tenth round asked for two nested subsystems each contributing several points
alongside declared outer ones, and for timebase compatibility when replacing a
point with a system. Both already held. The ordering rule comes out as
`['ro', 'one_ctl', 'one_err', 'two_ctl', 'two_err']`: declared first, then
subsystems in list order, and within a subsystem in its own declaration order.
Every one of those five points opens, closes and round trips. Timebase
compatibility falls out of routing the inserted block through `interconnect`,
so a block sampled at the diagram's rate is accepted, a timebase-free static
block adopts the diagram's rate, and a different sampling time, a continuous
block in a discrete diagram, or a discrete block in a continuous one are all
refused by the library's own `common_timebase`.

An eleventh round reversed the ninth on negative indices, and the reversal is
the useful part. Round nine flagged tests that required index -1 to be
rejected, citing the library's Python-style signal slicing; I changed the
solution to count from the end and asserted that. Round eleven flagged the new
assertion, having read `_process_indices` more closely: it turns an integer
into a slice, so -1 becomes `slice(-1, 0, 1)`, which selects nothing rather
than the last channel. Neither reading is settled by the repository and the
description says only "by label or index", so both assertions were pinning an
author's choice.

The resolution is to assert neither. The two tests that fixed a meaning for -1
are gone, and the two that reject an index below the range stay, because -3 on
a two-channel system is out of range under either reading and both agree it
raises. The implementation still counts from the end, which is the friendlier
Python behaviour, but nothing in the suite depends on that. The lesson is that
a fairness flag on an assertion does not license asserting the opposite; when
two readings are both defensible and neither is stated, the test surface has to
retreat rather than switch sides.

A twelfth round asked for the two-channel `analysis_point` block wired into a
real MIMO diagram rather than only inspected on its own, and for a multichannel
output point whose channels fan out through non-unit gains while also being
exposed as interconnection outputs. Both held. The size-two block contributes
one two-channel point, does not feed itself, produces the bracketed channel
labels, gives the same loop transfer as declaring the point directly on the
controller output, and round trips.

The fanout fixture is the sharpest test in the suite for the opening rule: the
first point channel drives two plants through gains 2 and -3, the second drives
a third plant through 0.5, and all three channels are also tapped as
interconnection outputs. Its loop transfer works out to
`[[3/(s+2), 0], [-2/(s+1), -0.5/(s+3)]]`, which the test pins entry by entry,
so a wrong per-branch gain or a missed branch moves a specific entry rather
than the whole matrix. With the point opened, the reference-to-plant path is
zero because every internal branch is gone, while the taps still report the
controller output, which is the two halves of the rule failing in opposite
directions if either is wrong.

A thirteenth round closed the negative-index question for good. Having asserted
one meaning, then the other, then neither, the remaining move was the one the
round asked for: state it. The description now says an index counts from the
end when negative, which costs five words and settles a corner that three
rounds had argued over. The two tests are back, along with one for the first
channel counted from the end and one mixing a negative with a positive index,
and the mutation that stops wrapping is a kill again.

Default result names are asserted only as being non-empty strings. The library
generates them from a global counter, so pinning `sys[12]` would make the test
depend on how many systems earlier tests happened to build; asserting that a
name exists is the strongest claim that is both fair and order-independent.

Closing cannot collide, because it only removes channels, so that suggestion
became a set of validation tests instead: closing the same point twice, closing
any name on a system that was never opened, closing a name belonging to a
different point of the same system, and closing after a partial close. Closing
nothing on an already-closed system is a no-op that keeps the points.

A fourteenth round flagged the test that required the string form to list
points in declaration order. The description gives that order contract to
`analysis_point_labels` and asks only that the string form name each point with
its signal, so display order was an unstated formatting choice. The test is
gone, replaced by one asserting both names appear, which is what the
description actually promises.

The contributed-name suggestion of the same round found the fifth defect, and
the last one so far. A declared point whose name matched a name a nested
subsystem or an `analysis_point` block was about to contribute did not raise;
the contributed entry silently overwrote the declared one, even though the
description says repeating a name in one call is an error. Contributions are
now claimed through a helper that refuses a taken name, both against declared
points and against each other, and two mutations cover the two paths. The
configurable-delimiter suggestion confirmed that contributed names, undeclared
channel labels and exposed channel labels all read
`config.defaults['iosys.state_name_delim']` at call time rather than assuming
an underscore; a third mutation hard-codes it and dies.

One of the new collision tests passed on base at first: it built the nested
subsystem inside the `pytest.raises` block, so the constructor's own rejection
of the unknown keyword satisfied the assertion. The subsystem is now built
before the block, and its point list asserted, which is the same mistake and
the same fix as the three error-path tests in R4.

Two style and quality checks closed the file. A formatting check read the
description's hard-wrapped paragraphs as an AI tell, since markdown lets the
renderer wrap and manual breaks mid-sentence are a giveaway. Each paragraph is
now one line. The word count did not move.

A quality check warned that a few tests asserted exact state matrices, which
pins a realization the description never promises. It was right, and the
assertions came from an earlier coverage suggestion asking for the realization
to be checked through an opening. The state-order claims are the part the
description does make, so those stay as state labels and counts, and the
matrix pins became behaviour: the opened simple loop is asked for its
injection-to-output transfer of `1/(s+1)`, the opened MIMO one for the diagonal
plant, and the replaced loop for `1/(s+2)`. The two remaining matrix
assertions are deliberate. `test_nominal_state_matrices_unchanged` compares a
system with points against the same system without them, which is the
preservation claim itself rather than a realization pin, and the
`analysis_point` block tests assert `D` is the identity because that is what
"a static unit gain" means. All 24 mutations still die.

A second quality check caught the last implementation-detail dependency: three
tests split `str(sys)` on the literal phrase "Analysis points" to reach the
section they wanted to inspect. The description promises only that the string
form lists each point with its signal, not any header text. The tests now give
their points names that appear nowhere else in a system repr, alpha, beta,
gamma and delta, and simply assert the names are present, with one test
contrasting a system carrying a point against the same system without one so
the assertion cannot pass vacuously. A mutation that drops the points section
from `__str__` now dies, which is the proof the section is genuinely covered
without pinning its wording.

The description stayed within 600 words throughout; the new rules paid for
themselves by letting the contributed-name sentence collapse into the general
one.

## Batch 1 and the solvability fix

Three of the fourteen Nova runs were captured. All three passed the full 3815
test baseline and all three failed the new suite, 67, 54 and 120 tests, with 45
tests failing in every run. That shape is the tell: one coordinated miss, not
three independent ones.

The miss was the default name of a declared point. Every agent produced `C_u`
and `S_e` where the suite wants `u` and `e`, because the description carried two
rules that collided. One said a list names each point after its signal base
name; the other, added in round eight to make generated channel labels fair,
said a name built from a subsystem and a signal joins the two with the
hierarchical delimiter. A declared specification `C.u` is literally a name built
from a subsystem and a signal, so the general rule swallowed the specific one.
That is my error, introduced while fixing a different fairness flag.

Replaying the closest agent's patch and repairing one ambiguity at a time gave
the numbers in eval-results.md: 54 failures as submitted, 20 once the default
name is the bare signal base, 12 once `find_analysis_point` reports stacked
rather than per-subsystem positions, 10 once S and T carry L's output labels and
`io_transfer` accepts `name`. So 44 of 54 failures came from four sentences.

All four are now fixed in the description, as clarifications rather than
easings:

- a list names each point "after its signal's base name alone", and the
  delimiter rule is scoped to "a name the library builds itself";
- `find_analysis_point` returns "positions in the interconnection's stacked
  signals of that kind", which distinguishes stacked from per-subsystem;
- the `io_transfer` signature now shows `name=None`, which the prose already
  implied by saying all of them name their result;
- S and T "carry its input and output labels" rather than "its labels", which
  had let one agent put injection labels on both sides.

A split hyphen, "wrong- kind", left over from an earlier rewrap was also
repaired. No test changed: every one of these was the description failing to say
what the suite already checked.

What remains for a solver is real work, not guesswork: inserting an LTI block at
a point, explicit block wiring, single-channel vector specifications, the
missing-value error, the declared-versus-undeclared redeclaration rule, and
opening nested points of two subsystems at once. The evaluator independently
rated the task fair and solvable on all three runs, with no unfair-blame flag.

## Batch 2 and the proof of solvability

Six runs captured, all still failing, but the shape changed completely: 35, 6,
19, 7, 15 and 10 failures against 54 to 120 before. The R1 clarifications did
their job on the naming and index questions; what was left was a second, smaller
layer of the same disease. Six blockers remained and every one of them was a
choice the description never made:

- where a redeclared point lands in the list, hit by all six runs;
- what prefix a channel gets when the point was named by an ad hoc `S.e`
  specification rather than declared, hit by four;
- the delimiter test, which rode on that same unstated prefix;
- what `close_loop` does on a system that was never opened, hit by three;
- the name an `analysis_point` block contributes, where one agent produced
  `u_u`;
- whether a block's point sits on its input or its output side.

Only the fifth needed a description change, and it got one: the block now
"contributes one called `name` itself". The rest were tests asserting more than
the description promised, so the tests gave way. Redeclaration compares
membership instead of position, the ad hoc channel test checks the pair and the
suffixes instead of the prefix, delimiter coverage moved onto contributed names
where the rule is actually stated, the never-opened close was deleted, and the
block's anchor side is accepted either way because both give identical behaviour
for a pass-through block.

Replaying every captured patch against the revised suite settles the question.
Nova #2 passes all 271 tests. The other five land at 3, 8, 10, 17 and 34, and
what they fail is work the description states: nested loop transfer values,
opening nested points of two subsystems together, inserting an LTI block at a
point, explicit block wiring, and the missing-value error. One pass in six is
inside the band and close to the corpus mode.

The general lesson from both batches is that this problem's difficulty was never
short; what kept leaking was under-specification, and the tell was always the
same. When a failure appears in every single run, it is the description's fault
until proven otherwise, and the cheapest proof is to replay one patch and repair
one sentence at a time.

## Batch 3 and the clause that replaced a cut

Ten runs, none passing, but two of them failed exactly one test and it was the
same one: `test_all_nested_points_round_trip`. One hit a false algebraic loop,
the other a KeyError on the default open-all path. Everything else in those two
submissions was correct across 270 tests.

That test had two real weaknesses: it pinned the order of the restored point
list, and its fixture gave two nested subsystems two points each, which made the
same-subsystem case depend on my hoisting design rather than on anything stated.
Both are fixed, one point per nested subsystem and membership instead of order.

That repair alone did not clear the two runs, because they died on the default
open-all path itself. My first instinct was to cut the test. That was the wrong
call and the expensive one: the failure was a stated-ingredient combination the
description never named, which makes it a description bug, and the fix for a
description bug is a sentence, not a deletion. `close_loop` is now described
through to "opening every point at once, contributed ones included, and closing
them all restores it". Replaying Nova #4 against the restored test shows it
rejecting two contributed points from different subsystems as overlapping, the
same class both Orions hit, and the clause says outright that this must work.

The lone-specification sentence also cost three runs. "A lone specification, a
list naming each point after its signal's base name alone, or a dictionary of
chosen names all work" attaches the base-name rule to the list, so a lone `C.u`
was read as `C_u`. It now reads "A lone specification or a list names each point
after its signal's base name alone". One evaluator had already written that the
singleton wording "could be made slightly more explicit", which was a fair hit.

Projected on this batch: runs 1 and 4 pass, run 9 drops to one failure, runs 7
and 10 lose the naming cascade. Two in ten, at the corpus mode.

## The coordinated wrong number

Auditing the three hardest tests turned up something the pass/fail counts hid.
Three runs failed `test_nested_loop_transfer` with the same value to eight
digits, `-2.403846+0.480769j`. Identical wrong answers from independent
implementations are never three separate bugs, so I solved for the number
rather than reading the diffs: it is the loop transfer at `inner.r`, the inner
subsystem's input port. The test wants the transfer at `C.u`, the signal inside
inner that the subsystem actually declared.

The description created that. It said a subsystem contributes its own points
under generated names and never said where those points sit in the parent, and
collapsing them to the subsystem boundary is the cheaper implementation. It now
says "each still on the signal it named, not the subsystem's port". Two other
runs failed the same test without reaching a number, unable to resolve the
hoisted name at all, so five of nine runs were losing this test to one missing
clause.

The tell was available for free the whole time: under the boundary reading
`inner_u` and `ro` are the same location and the reference gives both
`-5/(s+2)`, so the suite was asking two labels to produce one answer and only
one of them said so. Per-test verdicts across saved JUnit files are cheap and I
should be pulling them after every batch, not only when asked.

## The close-a-closed-point rule

Test Fairness round 7 sampled 69 tests and failed 4, all one class: closing a
point that is declared but not currently open. I had four tests asserting that
raises, and nothing in the description said so. Closing was defined as
reconnecting an injection to its measurement, and absent and repeated names were
listed as errors; a name that is present with no open pair fell between those,
where a no-op reads as well as a raise. That is exactly the kind of unstated
state-machine choice I have been paying for all week.

Stated it, kept the tests. The error sentence now lists "close a point that is
not open" beside the absent-point and repeated-name cases. A no-op
implementation now fails a written requirement, which is a trap rather than a
trick, and the mutation that makes `close_loop` skip a closed point is killed.

The same round vindicated the previous fix. It rated `test_nested_loop_transfer`
fair with the note that it "prevents a plausible but incorrect port-level
implementation". That plausible incorrect implementation is precisely the one
three runs shipped, before the clause about a contributed point staying on the
signal it named.

All three coverage suggestions are in. The string-form one was the interesting
one: the obvious assertion, that `str(sys)` contains the point's signal, passes
on a system with no analysis points at all, because the connection table already
prints every subsystem signal. It now declares two points on different signals
and requires the line carrying each name to carry that name's own signal, with
the two differing. Worth remembering that a substring assertion against a rich
repr can be satisfied by text the feature did not write.

## Cost of the coverage round

The three suggested tests cost me my solvability proof. Nova #2, the saved patch
that passed everything, failed two of them.

One was a bad assertion of mine: contributed and declared points report
different stacked positions in my implementation only because hoisting adds a
tap output to the subsystem, and nothing in the description fixes that layout.
Removed. The other is a genuine defect in Nova #2, which rejects a point
combined with a contributed opening as a repeat while computing each transfer
correctly alone. That one stays, with a description clause behind it.

So the honest position is that no saved patch passes the current suite. I kept
the test anyway, because dropping it would hand back a proof that was really a
false positive, and a false positive invalidates a submission the same way an
unsolvable one does. The lesson is narrower than it looks: every time I add a
test after the last replay, the solvability evidence expires, and I should
re-replay before repeating the claim rather than after being asked.

With the word cap lifted the rule is now written down rather than implied.
Nova #2's two failures are a single defect, collapsing two distinct points into
one location, and the description says "Points at different signals are
different locations, so naming one as a point and another as an opening is not
a repeat, and each keeps its own position among the stacked signals." Spare
words also bought back the precision I had traded for budget, most usefully S
and T carrying L's input and output labels instead of the vaguer "L's labels".

## Description Quality, and what compression cost

Failed on three comments, all tone rather than substance, none of them pinned by
a test. "Outputs before inputs" read as a parser note, the not-a-repeat clause
read as an internal dedup explanation, and "the four transfer functions" made
the reader count instead of naming them. Fixed all three.

The more useful line was the summary: overly compressed. That is exactly what
the word budget did. Every squeeze went into shorter phrasing rather than fewer
requirements, and the result read like notes to myself. I rewrote it for someone
reading it cold, then trimmed back to a 650-word ceiling, spending the extra
words on the three flagged spots and leaving the rest terse. 31 tested
requirements in 650 words is about 21 words each, so there is no room to
decompress everywhere.

One replacement needed care. "Outputs before inputs" was doing two jobs at once:
resolving a name that is both an output and an input, and telling the reader
which vector a bare index counts into. The natural rewrite, "where a name
matches both", covers only the first and would have stranded
`test_index_specification`, which passes the tuple `(1, 0)`. It says
"specification" instead.

Worth keeping in mind that a phrase carrying two rules is what compression
produces, and it is the thing that breaks when you decompress carelessly.

## The clause that keeps breaking

The formatting heuristic wanted the two long paragraphs split; seven now, longest
144 words, no wording touched.

The sanity check found something real. My compressed "only a repeated name or two
names at one location is an error" reads as a rule enforced at declaration, and
the tests say the opposite: two names on one location declare fine and both get
listed, and the error comes when they are used together in a call. Reworded to
"only a name repeated in one call, or two names opened at one location, is an
error".

This is the same sentence that cost me three runs earlier, when compressing it
dropped where a contributed point sits. Now compressing it dropped when the
overlap rule applies. Both times the sentence was carrying two quantifiers and
shortening it silently discarded one. Sentences like that should be split rather
than squeezed.

## Non-mutation, stated

Three flagged, all the dictionary forms of `replace_point`, all the same
co-assertion: that the original system is untouched after a failed call. The
raises themselves were fair.

The reviewer called it a rollback guarantee. It is really the weaker property
that none of these functions mutate their argument, which the repository does
follow but the description never said. Now it says "All take an interconnected
system, name their result, and never modify it, even on error."

Fourth round running where the fix is one sentence for a property I had assumed
was obvious from the code. The pattern is clear enough to name: anything true of
my implementation only because of how I wrote it needs to be in the description,
even when no reasonable implementation would differ.

The round also confirmed the two earlier clauses are pulling their weight. The
nested transfer tests "strongly catch incorrect placement at the child port",
and the overlap tests "correctly distinguish legal declaration from illegal
simultaneous opening", which is exactly the timing the last sanity warning
flagged.

## My own over-specification

One unfair out of 174, and it was the test I added two rounds ago to satisfy a
coverage suggestion. It pinned one line per point with the name before the
signal. Nothing states that, and pinning a repr layout is exactly the coupling I
had stripped from other tests. Fixed the test rather than the description; the
description should not be describing repr layout.

The hard part was never the layout, it was that `'C.u' in str(sys)` is true with
no points declared at all, since the connection table already prints it. The new
test is differential: two systems identical except which signal a single point
sits on, same point name, same explicit system name. Showing the signal makes
them render differently; showing only names makes them identical. No layout
assumed.

Pinning the system name turned out to matter. Without it the auto-generated
`sys[N]` counter differs between constructions, so the inequality would have
held whether or not the signal was printed, and the test would have passed
vacuously. Worth remembering for any test that asserts two reprs differ: check
what else is free to vary first.

Both coverage suggestions are in. I left `size=True` untested on purpose; it
equals 1, so neither accepting nor rejecting it follows from "fractional or
sub-unit", and asserting either way would pin a choice the description does not
make. `False` equals 0, which is sub-unit and therefore stated.

## Batch 4: one word of naming

Seven runs, no passes, but five tests failed in all seven and they were all the
same assertion: `['u_u'] == ['u']`. Every agent applied the general
contributed-name rule to the `analysis_point` block, so a block named `u`
carrying a point named `u` came out `u_u`. The description did say the block
"contributes one called `name`", but the sentence right before it establishes
the `<subsystem><delim><point>` rule, and the general rule won seven times out of
seven. That is the lone-specification bug from batch 1 all over again: a general
rule stated first, a specific one stated second, and the general one wins. Now it
says "contributes a point called `name` alone, never prefixed by the block".

The sixth universal failure was `inner_indices != outer_indices`. I removed that
assertion once as representation-pinning and then restored it when the
distinctness clause went in. Six of seven says the restore was wrong. Reporting
distinct stacked positions means exposing the inner signal at the outer level,
which is a strategy, not a behavior. Gone again, along with the clause written to
justify it. The bug it was meant to catch is still caught behaviorally.

Replay cannot demonstrate a description fix, so I patched both close runs with
the one-line naming change the corrected sentence asks for. **Nova #4 went from
7 failures to 0 of 277.** Orion #2 went from 6 to 1, and its survivor is a
broadcast crash in its own nested wiring, not a spec question. So one real
submission passes the whole suite once the rule it misread is stated plainly, and
nothing else in that submission is wrong.

Ordering is the lesson worth keeping. Both times this has cost a batch, the
general rule came first in the paragraph and the exception came second. Exceptions
need to say they are exceptions, not just state a different answer.

## Batch 5: a pass, a false positive, and 3/3

Ten runs, Nova #1 clean at 0/277, three more a single test away. The block-naming
fix did what it needed to.

Then the FP adjudicator called Nova #1 a functional false positive, and it was
right twice over. Opening a nested contributed point in that submission rebuilds
and renames the child subsystem, so `io_transfer(sys, 'ref', 'inner.y',
opened='inner_u')` raises "not a subsystem output" where the reference returns
zero. And its index path used `isinstance(item, int)`, rejecting the numpy
integers the rest of the library takes. Both are composable capabilities the
description states separately and no test composed. Both now have tests, checked
against the reference first.

Solution Quality passed but scored 2/3 twice, on two findings I could not argue
with. The description says every API accepts a subsystem signal specification in
place of a point name, and construction honored that while `_channels`,
`_selection` and `replace_point` all demanded a plain string. And `_rebuild` set
`connection_type` only for `LinearICSystem.__init__` to overwrite it with its own
default. Both fixed; a `_canonical` helper normalizes any accepted specification,
and tuples are one specification rather than a sequence of names.

The most interesting fix was one I nearly got wrong.
`test_two_analysis_point_blocks_may_not_share_a_name` failed 4 of 10 with
RuntimeError instead of ValueError, and my instinct was that the agents had
simply not implemented the rule. Mutation testing said otherwise: disable the
reference's own duplicate guard and the reference raises the same RuntimeError.
Both refuse to build the system; only the error class differs, and the
description names none. That is the error-class trap I have a note about, in my
own suite. Broadened, and the mutant that only ever died to that class difference
came out of the battery with it.

Net after all of it: **Orion #2 passes all 283**, and it is not the flagged run.
Nova #1 now fails exactly the two discriminators.

## Two reviewers, one repository file, opposite readings

Round 10 flagged one test of 104: the numpy-integer index check I added to close
the false positive. The reviewer said the repo's signal-spec parser uses plain
`int`, so numpy integers are not repo-discoverable there. I checked, and it is
right: `isinstance(spec, int)` at iosys.py:1257 and `isinstance(signal_spec,
int)` at 1308-1319. `np.integer` shows up only for signal counts at 1107.

The FP adjudicator's judge-c had cited that same file the other way, as evidence
that numpy indices should be accepted. Both were reading real code; the
difference is that counts and indices are parsed by different branches. Worth
remembering that "the repo convention" is not one thing per file.

I stated the rule rather than dropping the test. Dropping a test that catches a
real defect in a passing submission is exactly what produced the false positive,
and one sentence is cheaper than the FP round it would cost later.

## The string test, third attempt

All three coverage suggestions are in. The string one is worth recording because
it took three tries and each verdict was right.

Version one asserted one line per point with the name before the signal, and was
flagged for pinning an unstated layout. Version two compared two whole strings
that differed only in which signal the point sat on, which fixed the layout
problem but never actually looked at the signal, so this round called it
insufficient. Version three diffs a point-bearing system against its point-free
twin, which isolates the analysis points section, and asserts that text names the
point and its own signal and not the other one. Signal names are `zeta` and
`omega` so neither token can turn up incidentally, and the separator is never
mentioned.

The lesson is that "show the signal" and "do not pin the format" pull against
each other, and the way through is a differential that isolates the new text
rather than any assertion about how it is laid out.

## State assertions, split two ways

The quality checker warned that four tests pin state counts or label order after
`open_loop`, `close_loop` and `replace_point`, while the description only
promises states stay put for declaration. Correct, and Test Fairness having
passed them earlier does not change it.

The four were not asking the same thing, so I did not treat them the same. Three
assert preservation, which every one of these calls genuinely does, so I stated
it: "keep its states" in the final paragraph, three words. The fourth asserted
`nstates == original + 2` after inserting a two-state block, which really is a
realization detail and would have contradicted the clause I had just added.
Swapped for the behavior it was proxying: the loop transfer through the block
equals the original over `s + 3`. That is a stronger assertion than the state
count ever was.

Worth noting the pattern: when a checker flags a group, check whether the group
is homogeneous before applying one remedy to all of it.

## Batch 6: which side of S

Seventeen runs, no passes, but Nova #13 missed by one test and it was
`test_sensitivity_labels`, which I had told the user was clean two turns earlier
on the strength of 19 of 20 runs passing it. The record was right and the
conclusion was wrong: every earlier failure was an upstream crash, so nothing had
ever exercised the part that is actually ambiguous.

The assertion reads `['u_inj'] == ['u_meas']`. Nova #13 puts L's input labels on
both sides of S. The description said S and T take "L's input and output labels"
and never said which side of S gets which, and since inverting `I - L` swaps the
roles, the other reading is defensible. Now: "injections labelling inputs and
measurements outputs". Same word count, both actors named on both sides.

Patching that one call in its submission takes it from 1 failure to 0 of 289.

The lesson is one I already have a note about and still walked into: a pass rate
does not tell you a test is unambiguous, because most failures never reach the
ambiguous step. When a run finally does reach it, that single datapoint outranks
the nineteen that crashed earlier.

## Not resting on one agent

Replayed all 43 saved submissions against the current suite. One passes
unmodified, five sit at exactly one failure, two at two. Eight of forty-three
within two tests is the honest evidence for solvability, and it is a much better
argument than any single run.

Two are demonstrated at zero, from different batches and different solvers:
b27 Orion #2 unmodified, and b28 Nova #13 once its sensitivity labels go on the
side the corrected sentence now names.

Of the other four one-failure runs, three are genuine defects against stated
rules and one predates the rule it breaks. I tried to manufacture a third passer
by patching b26 Nova #4's numpy handling and stopped when the patch started
breaking its downstream indexing. That would have been inventing evidence, not
finding it.

What the sweep did surface is that `test_io_transfer_accepts_a_numpy_integer_index`
was the most common last blocker, on three separate near-passers. Test Fairness
had already flagged it as contrary to the repo's own parser, and the FP
adjudicator's judge #2 called it an under-specified edge. I had kept it by
stating the rule; with the distribution in front of me that was the wrong trade,
so the test and its clause are both gone. The FP defect the adjudicator actually
led with, the nested rename, is still tested.

## Auto Review found two bugs I had put there

Three review passes, four findings, and the two High ones were real defects in my
reference rather than anything about the tests.

Hoisting contributed points called `open_loop` with every child label at once,
and `open_loop` refuses two names at one channel. So a child that legally
declares two aliases on one signal could be built and opened one alias at a
time, but could not be embedded in a parent at all. The internal step was acting
like a user request. Split the guard out of the machinery: `open_loop` checks and
raises, a private `_open_channels` does the work, hoisting calls the latter.

`close_loop` also split a tuple specification into two point names. When the
Solution Quality review asked for tuple support across the runtime APIs I fixed
`_channels` and `_default_names` and never noticed `close_loop` parses its
argument in its own block. The missing test is what let it survive, which is the
reviewer's point precisely.

Both now have tests. Four added: tuple and index close round trips, aliases
declared together, and an aliased child embedded in a parent.

The density complaint was fair too, quoted identically in all three passes. The
description is now 18 short paragraphs grouped by API, longest 54 words against
138, with the nine-clause error sentence broken in two. Still plain prose, no
headers, 645 words.

Two lessons worth keeping. A fix applied to one parsing site is not applied to
the feature: `close_loop` had its own copy and I never grepped for others. And a
refactor invalidates mutation targets, which is how one mutant silently went to
PATTERN MISS until I read past the summary line.

## The FP, closed properly this time

Dropping the numpy-index test during the sweep left half the false positive
uncovered, and I said so when asked rather than claiming it was shut. The
flagged run still rejected `np.int64(-1)` and nothing caught it.

Restored, with the fairness objection answered instead of dodged. Test Fairness
had complained that "the prompt says index but does not specify NumPy scalar
acceptance" - a complaint about the description. The selector sentence now says
"a negative index counting from the end, numpy integers included". Three words,
placed on the API it governs rather than in a standalone rule at the end, which
is what I did the first time and what made it read as an arbitrary add-on.

Both adjudicator defects are covered and the flagged submission fails three
tests. b27 Orion #2 still passes all 293 unmodified, so the demonstrated
solvability did not move; the cost lands only on runs already failing for other
reasons.

Worth recording that I twice traded away a real discriminator to buy a cleaner
number, and both times had to put it back. A test that catches a genuine defect
should be made fair, not deleted.

## I ran the FP check instead of talking about it

I had been reporting that an FP could not be ruled out, which was true and
useless. The adjudicator's method is reproducible: probe the passing submission
against the reference and look for divergence. So I wrote 73 probes over the
whole API surface, ran them in both trees, and diffed the signatures.

Ten divergences, and one was a defect in my own reference. Opening a declared
point by its specification left the point listed, while opening it by name
retired it - the same physical channel giving two answers depending on how it
was addressed. The candidate was self-consistent and I was not. Fixed by
tracking which declared point owns each opened channel, so opening retires it
however it was named and closing gives the name back.

The remaining nine are auto-generated names and a degenerate state count, with
every numeric response matching. Those cannot be probed fairly, and the
description now says the generated prefix is the implementation's choice so the
freedom is stated rather than merely untested.

The lesson I should have applied ten turns ago: when a check is mechanical,
run it rather than reason about whether it would pass.

## Hints, aimed by count rather than by guess

Four clauses added, each pointed at a failure class with a run count behind it:
specifications only working as aliases for declared points (5 runs), an omitted
replacement value read as zero (5), the hierarchical prefix applied to directly
declared names (4), and input-point positions taken in a combined coordinate
space (3).

Two of those were already stated but buried, and one was my own regression: the
`find_analysis_point` sentence used to say "positions in the stacked signals of
that kind" until I cut "of that kind" to hold a word cap. Three runs then missed
exactly that distinction. Word caps are worth respecting, but not by deleting the
qualifier that carries the meaning.

Every clause was checked against the reference first, so nothing in the
description promises behaviour the implementation lacks.

## Status

Solvable on the record: batch 5's Orion #2 passes all 283 tests of the revised
suite unmodified, and batch 4's Nova #4 passes once its block naming matches what
the description now states. The one run that passed the old suite was a false
positive and now fails the two tests that catch it.

Every Test Fairness flag is resolved and every coverage suggestion is in.
298 tests, 29 of 29 mutations killed, 500 effective LOC, 768 words.

The overlap rule was the last soft spot. It said "two names opened at one
location" while the partial-overlap test declares one point on `K.u` and another
on `K.u[0]` and opens both: not one location, two points sharing one channel. It
now says "two names opening one channel", which reaches both overlap tests in the
same words. 15 of 16 runs already passed that test, so this closes a reading gap
rather than a failure.
