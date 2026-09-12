# eval-results — python-control-analysis-points

## Batch 1 (Nova x14 submitted, 3 runs captured, 2026-08-04)

| Agent | Evaluator | Verdict | New failed | Baseline | Failure reason | Approach note |
| --- | --- | --- | --- | --- | --- | --- |
| Nova #1 | Nova | FAIL_MISSED_REQUIREMENT | 67 / 272 | 3815 pass | default point names, contributed names, validation | full rewrite inside nlsys, points stored per subsystem |
| Nova #3 | Nova | FAIL_MISSED_REQUIREMENT | 54 / 272 | 3815 pass | default point names, missing-value contract | closest run; same per-subsystem point store |
| Nova #4 | Nova | FAIL_MISSED_REQUIREMENT | 120 / 272 | 3815 pass | default point names, index representation | also returned (subsystem, local index) pairs |

Every captured run passed the whole 3815-test baseline and every one failed on
the same first requirement, so the batch is one coordinated miss rather than
three independent ones. 45 tests failed in all three runs. The evaluator rated
the task `description_clear: True`, `difficulty: challenging`,
`agent_blame_unfair: False` on all three, and wrote that it "is broad but fair
and solvable".

### Differential harness on the closest run (Nova #3)

Its patch was replayed against the suite and repaired one ambiguity at a time.

| State of the patch | New tests failing |
| --- | --- |
| as submitted | 54 |
| default point name uses the signal base name | 20 |
| plus `find_analysis_point` reporting stacked positions | 12 |
| plus S and T carrying L's output labels, `io_transfer` taking `name` | 10 |

44 of the 54 failures traced to four sentences in the description, not to the
work. The 10 that survive are genuine gaps against stated rules: inserting an
LTI block at a point (the agent's replacement was a no-op), wiring an
`analysis_point` block explicitly, single-channel vector specifications such as
`K.u[0]`, the missing-value error, the declared-versus-undeclared redeclaration
rule, opening nested points of two subsystems together, and applying `name`.

## Batch 2 (Nova x5 + Orion x1 captured, 2026-08-04, after the R1 clarifications)

| Agent | Evaluator | Verdict | New failed | Baseline | Failure reason |
| --- | --- | --- | --- | --- | --- |
| Nova #1 | Nova | FAIL_MISSED_REQUIREMENT | 35 / 272 | pass | declared names still subsystem-qualified |
| Nova #2 | Nova | FAIL_MISSED_REQUIREMENT | 6 / 272 | pass | all six were unstated choices of mine |
| Nova #3 | Nova | FAIL_MISSED_REQUIREMENT | 19 / 272 | pass | nested propagation, API details |
| Nova #4 | Nova | FAIL_MISSED_REQUIREMENT | 7 / 272 | pass | nested points, generated labels, validation |
| Nova #5 | Nova | FAIL_MISSED_REQUIREMENT | 15 / 272 | pass | nested points |
| Orion #1 | Nova | FAIL_MISSED_REQUIREMENT | 10 / 272 | pass | block point name, nested points |

The R1 clarifications worked: worst case fell from 120 to 35 and the best run
reached 6. Six failure modes remained, and each one was a choice the
description never made rather than work the agent skipped.

| Blocker | Runs hit | Resolution |
| --- | --- | --- |
| position of a redeclared point in the list | 6/6 | test compares membership, not order |
| channel-label prefix for an ad hoc `S.e` specification | 4/6 | test asserts the pair and the suffixes, not the prefix |
| delimiter coverage rode on that same unstated prefix | 4/6 | retargeted onto contributed names, which the description does fix |
| `close_loop` on a system that was never opened | 3/6 | test removed; the description does not define it |
| point name contributed by an `analysis_point` block | 3/6 | description now says it contributes one called `name` itself |
| whether a block's point sits on its input or its output | 1/6 | test accepts either; both give identical behaviour for a pass-through block |

### Replay of every captured patch against the revised suite

| Agent | Before | After |
| --- | --- | --- |
| Nova #1 | 35 | 34 |
| **Nova #2** | 6 | **0, passes all 271** |
| Nova #3 | 19 | 17 |
| Nova #4 | 7 | 3 |
| Nova #5 | 15 | 10 |
| Orion #1 | 10 | 8 |

A real submitted patch now passes the whole suite, so the task is solvable in
fact and not just in principle. On this sample the rate is 1 of 6, inside the
band and close to the corpus mode of 1 in 10. The five that still fail do so on
work the description states: nested loop transfer values, opening nested points
of two subsystems together, inserting an LTI block at a point, explicit block
wiring, and the missing-value error.

## Batch 3 (10 runs, 2026-08-04, after the R2 clarifications)

| Run | Solver | New failed | Blocking tests |
| --- | --- | --- | --- |
| 1 | Orion | **1 / 271** | all_nested_points_round_trip (algebraic loop) |
| 2 | Nova | 2 / 271 | nested_loop_transfer, all_nested_points_round_trip |
| 3 | Nova | 4 / 271 | close by ad hoc spec, nested mapping |
| 4 | Orion | **1 / 271** | all_nested_points_round_trip (KeyError on the default path) |
| 5 | Nova | 3 / 271 | nested_loop_transfer, overlapping open, round trip |
| 6 | Nova | 9 / 271 | block name `u_u`, overlap, nested, partial close |
| 7 | Nova | 3 / 271 (+2 baseline) | lone spec named `C_u`, nested mapping |
| 8 | Nova | 17 / 271 | false algebraic loop in nested, missing-value, overlap |
| 9 | Nova | 2 / 271 | lone spec named `C_u`, missing replacement value |
| 10 | Nova | 110 / 271 | lone spec named `C_u`, cascading |

Every run passed the full baseline except #7, which broke two documentation
checks by adding public API without the docstrings the repo demands. Two runs
came within a single test of passing, and it was the same test both times.

Two things changed as a result.

**`test_all_nested_points_round_trip` stays, and the description now says so.**
It asks for every point of a nested system to be opened at once and then closed,
which is the deepest composition in the suite and was the sole blocker for two
otherwise complete implementations. Each ingredient was already stated but the
combination was not, so the sentence describing `close_loop` now ends "opening
every point at once, contributed ones included, and closing them all restores
it". Two fairness fixes came with it: the fixture gives each subsystem one point
instead of two, so the failure cannot be a design-sensitivity artefact, and the
label comparison is by membership rather than order, since nothing states the
order a reconstructed list takes.

Replaying the saved patches against the restored test: Nova #2 from batch 2 still
passes all 271, and Nova #4 fails it by rejecting two contributed points from
different subsystems as overlapping, which is the same class the two Orions hit
and is exactly what the new clause contradicts.

**The lone-specification naming sentence was rewritten.** It read "A lone
specification, a list naming each point after its signal's base name alone, or
a dictionary of chosen names all work", which attaches the base-name rule to the
list form only, so three runs gave a lone `C.u` the name `C_u`. It now reads "A
lone specification or a list names each point after its signal's base name
alone".

Projected effect on this batch: runs 1 and 4 pass on the new clause, 9 drops to
a single failure, 7 and 10 lose their naming cascade. That is 2 of 10, inside
the band and at the corpus mode.

## Fairness audit of the three hardest tests (post-batch-3)

Asked whether `test_index_specification`, `test_nested_loop_transfer` and
`test_all_nested_points_round_trip` are fair, I pulled the per-test verdict out
of every saved JUnit file instead of judging by eye.

| Test | Batch 1 | Batch 2 | Reading |
| --- | --- | --- | --- |
| `test_index_specification` | 0/3 pass | 5/6 pass | fair; the batch-1 losses were the naming cascade, since fixed |
| `test_nested_loop_transfer` | 0/3 pass | 1/6 pass | was unfair, see below |
| `test_all_nested_points_round_trip` | 3/3 pass | 3/6 pass | fair now that the open-all clause is in |

`test_nested_loop_transfer` was the real finding. Three runs returned the
byte-identical wrong value `-2.403846+0.480769j`. Three independent
implementations agreeing to eight digits is a description gap, not three bugs,
so I solved for what that number is: it is `loop_transfer` at `inner.r`, the
inner subsystem's input port, where the expected `-6/(s+1)` is the transfer at
its internal `C.u`. All three collapsed the contributed point onto the
subsystem boundary. Two more runs never got that far, failing to resolve the
hoisted name at all.

Nothing in the description placed a contributed point. "A subsystem contributes
its own points under such names" says the names exist and says nothing about
where they sit, and the boundary is the cheaper place to put them. The sentence
now ends "each still on the signal it named, not the subsystem's port". Note
that the boundary reading also makes `inner_u` a duplicate of `ro`, which is
the same location; the reference gives both `-5/(s+2)`.

Tests and patches are unchanged by this. Meta only, still 600 words.

## Test Fairness round 7 (69 sampled, 4 unfair)

All four were one class: `close_loop` raising when handed a point that is
declared but not currently open. `test_close_loop_cannot_close_the_same_point_twice`,
`test_close_loop_rejects_every_name_on_a_system_never_opened`,
`test_close_loop_rejects_a_point_opened_on_another_system` and
`test_close_loop_after_a_partial_close_rejects_the_closed_name`. The reviewer
was right: the description defined closing as reconnecting an injection to its
measurement and errored on absent and repeated names, and said nothing about a
name that is present but has no open pair, so no-op was as good a reading as
raising. The error sentence now includes "close a point that is not open".
Kept all four tests; the rule is a real trap and a no-op implementation now
fails a stated requirement instead of an invented one.

The same round rated `test_nested_loop_transfer` and
`test_outer_loop_transfer_of_a_nested_system` fair, citing the clause added
after the previous audit: "Important behavioral check that prevents a plausible
but incorrect port-level implementation." That is the exact failure three runs
had, so the clause closed it.

All three coverage suggestions taken:

| Suggestion | Test |
| --- | --- |
| string form should show the signal, not just the name | `test_string_form_pairs_a_point_with_its_signal` |
| `find_analysis_point` on a contributed point | `test_find_a_contributed_point_reports_the_internal_signal` |
| `openings` naming a contributed point | `test_openings_may_name_a_contributed_point` |

The string-form test needed care. `'C.u' in str(sys)` is true even with no
analysis points declared, because the connection table already prints it, so
that assertion proves nothing. It now declares two points on different signals,
takes the text following each name on its own line, and requires each tail to
name its own signal and the two tails to differ.

Three mutations were added for the new ground: `close_loop` no-oping on a closed
point, a contributed point collapsing onto the subsystem port, and the string
form dropping the signal. 28 of 28 killed.

## What the coverage tests did to the solvability evidence

Adding the three suggested tests broke the replay I had been citing as proof.
Nova #2, the one saved patch that passed the whole suite, failed two of them.

The first failure was my fault outright. I asserted that a contributed point and
a declared point report different stacked positions. In the reference they are
[1] and [2] because hoisting exposes an extra tap output on the subsystem;
Nova #2 reports [1] for both because it does not add that output. Nothing in the
description fixes that layout, so the assertion pinned my implementation. It is
gone; the test now checks the kind and the channel count, which is what actually
separates an internal signal from the subsystem port.

The second is a real defect in Nova #2 and it survives. Asked for
`loop_transfer(sys, 'ro', openings=['inner_u'])` it raises "analysis point
'inner_u' repeated", in both directions, although it computes each of the two
loop transfers correctly on its own. Two distinct points, right individually,
rejected in combination. The description now says contributed points "serve
anywhere they do", so the requirement is stated rather than implied.

That leaves the submission with no replay-proven passer: Nova #2 sits at 1 of
274. Keeping the test was still the right call. Dropping it would restore the
citation but the citation would be a false positive, an agent passing every test
while failing a stated requirement, and the FP check is a submit gate. A visible
fail beats a silent pass.

## Word cap lifted, distinctness stated

With the 600-word cap lifted the description says the rule outright instead of
implying it. Nova #2's two remaining failures are one defect: it reports the
same stacked position for a contributed point and a declared point, and it
rejects one named as a point beside the other named as an opening with
"analysis point 'inner_u' repeated", in both directions, while computing each
loop transfer correctly alone. Two distinct points collapsed into one location.

The description now carries "Points at different signals are different
locations, so naming one as a point and another as an opening is not a repeat,
and each keeps its own position among the stacked signals." That also makes the
`inner_indices != outer_indices` assertion description-backed rather than
layout-pinned, so it is restored; distinctness follows from positions
identifying signals, while the specific values [1] and [2] never do.

The budget also bought back precision I had traded away at 600 words: S and T
carry L's input and output labels rather than "L's labels", `io_transfer`
defaults to all of `sys`, `openings` are "broken" rather than "break", and the
error list reads "open one location twice or with taken channel labels". Meta is
661 words, ASCII, no em dashes.

Nova #2 stands at 2 of 274, both on the one stated rule. No saved patch clears
the suite, so solvability remains projected rather than proven until a batch
runs against this artifact.

## Description Quality round 1 (FAIL, 3 comments)

All three were style rather than substance, and the check confirmed none of them
is pinned by a test, so the fix was free.

| Comment | Was | Now |
| --- | --- | --- |
| "outputs before inputs" reads like a parser note | `Each entry names a subsystem signal in a connection's format, without a gain, outputs before inputs.` | names the forms `interconnect` already accepts, then states the rule the test actually checks: where a specification matches both an output and an input, the output is taken |
| the not-a-repeat clause reads like an internal dedup explanation | `so naming one as a point and another as an opening is not a repeat` | `only a name repeated within one call, or two names covering one location, is an error` |
| "the four transfer functions" makes the reader count | `the four transfer functions need it linear` | names `loop_transfer`, `sensitivity`, `complementary_sensitivity` and `io_transfer` |

The summary also called the whole write-up overly compressed, which it was:
every earlier squeeze went into shorter phrasing rather than fewer
requirements. The description was rewritten for a developer reading it cold,
then brought back to a 650-word ceiling. 768 words across 18 paragraphs, ASCII, no em dashes.

Fitting 31 tested requirements into 650 words means the three fixes had to be
paid for elsewhere, so the decompression is spent where it was flagged and the
surrounding prose stays terse.

Every requirement was carried across verbatim in meaning. The one that needed
care was the "outputs before inputs" replacement: the phrase was doing two jobs,
resolving name collisions and telling the reader which vector a bare index
counts into. Saying "where a name matches" would have covered only the first and
broken `test_index_specification`, which passes the tuple `(1, 0)`; it says
"specification" so it covers both.

Tests and patches are unchanged by this round.

## Formatting and sanity warnings

Two warnings, one cosmetic and one real.

The formatting heuristic flagged two paragraphs over 150 words. Split into
seven, the longest now 144. No wording changed, so nothing else moved.

The sanity check caught a genuine mismatch I had introduced myself. Compressing
the distinctness clause to "only a repeated name or two names at one location is
an error" read as a declaration-time rule, and the tests say otherwise:
`test_two_names_on_one_location_cannot_open_together` declares
`{'first': 'C.u', 'second': 'C.u'}` successfully, asserts both labels are
listed, and only then expects `loop_transfer(sys, ['first', 'second'])` to
raise. `test_duplicate_point_names_rejected` does error at declaration, but for a
repeated name rather than a shared location. The clause now reads "only a name
repeated in one call, or two names opened at one location, is an error", which
covers both: a name repeated in any call, declaration included, and a shared
location only when the names are used together.

That is the second time compressing this one sentence has cost something. The
first pass dropped where a contributed point sits and three runs collapsed it to
the subsystem port; this pass dropped when the overlap rule applies. A sentence
carrying two quantifiers does not survive being shortened.

## Test Fairness round 8 (68 sampled, 3 unfair)

One class again. All three are the dictionary forms of `replace_point`, and the
raises themselves were rated fair; what was not supported is the co-assertion
that the original system survives a failed call intact:
`test_replace_points_rejects_an_absent_key_without_applying_the_rest`,
`test_replace_points_rejects_a_wrong_sized_value_in_a_dictionary`,
`test_replace_points_rejects_a_wrong_shaped_system_in_a_dictionary`.

The reviewer read it as a rollback guarantee. It is really the weaker and more
general property that these functions are non-mutating, which the reviewer's own
task summary lists as an existing repository convention but which the
description never claimed. Stated it: "All take an interconnected system, name
their result, and never modify it, even on error." That covers the three
assertions and every other call, and a mutating implementation now fails a
written requirement.

The same round rated the two clauses added in earlier rounds as doing their job:
`test_nested_loop_transfer` "strongly catch incorrect placement at the child
port", and `test_two_names_on_one_location_cannot_open_together` "correctly
distinguishes legal declaration from illegal simultaneous opening", which is the
timing distinction the previous sanity warning caught.

## Test Fairness round 9 (174 sampled, 1 unfair)

`test_string_form_pairs_a_point_with_its_signal`, the test I added two rounds
ago for a coverage suggestion, pinned a one-line-per-point layout with the name
before the signal. Neither is stated, and pinning a repr layout is the same
over-specification I had already stripped elsewhere. Fixed in the test, not the
description.

The difficulty was always that `'C.u' in str(sys)` is true even with no points
declared, because the connection table already prints it. The new version is
differential instead: two systems identical except for the signal one point sits
on, same point name, same explicit system name. If the string form shows the
signal, they render differently; if it shows only names, they are identical. A
third system repeating the first must render identically to it. No layout is
assumed. Pinning the system name mattered, since the auto-generated `sys[N]`
counter differs between constructions and would have satisfied the inequality on
its own.

Both coverage suggestions taken:

| Suggestion | Test |
| --- | --- |
| `analysis_point` size type edges | `test_analysis_point_accepts_a_numpy_integer_size`, `test_analysis_point_rejects_a_false_size` |
| source immutability on success, not just on error | `test_successful_calls_leave_the_source_alone` |

`size=True` is deliberately not tested. It equals 1, so neither accepting nor
rejecting it follows from "fractional or sub-unit", and a test either way would
pin an unstated choice. `False` equals 0, which is sub-unit and therefore stated.

277 tests. 28 of 28 mutations still killed, the string-form mutation included.

## Batch 4 (7 runs, agent-runs(26)) and the block naming

| Run | Solver | New failed | Baseline |
| --- | --- | --- | --- |
| Nova #1 | Nova | 10 / 277 | 3815 pass |
| Nova #2 | Nova | 22 / 277 | 3815 pass |
| Nova #3 | Nova | 9 / 277 | 3815 pass |
| **Nova #4** | Nova | **7 / 277** | 3815 pass |
| Nova #5 | Nova | 23 / 277 | 3815 pass |
| Orion #1 | Orion | 118 / 277 | 3815 pass |
| **Orion #2** | Orion | **6 / 277** | 3815 pass |

Zero passes, but the failures are not spread out. Six tests account for almost
all of it:

| Failing in | Test |
| --- | --- |
| 7/7 | `test_analysis_point_block_declares_a_point` |
| 7/7 | `test_analysis_point_block_wired_explicitly` |
| 7/7 | `test_multichannel_block_declares_one_point_of_two_channels` |
| 7/7 | `test_multichannel_block_round_trip` |
| 7/7 | `test_a_declared_name_may_not_collide_with_a_block_contribution` |
| 6/7 | `test_find_a_contributed_point_reports_the_internal_signal` |

Five of the six are a single assertion, `['u_u'] == ['u']`. Every agent applied
the general contributed-name rule to the `analysis_point` block, so a block named
`u` carrying a point named `u` produced `u_u`. The description did say the block
"contributes one called `name`", but the sentence immediately before it
establishes `<subsystem><delim><point>` for contributed points, and the general
rule won 7 times out of 7. Same shape as the lone-specification bug from batch 1:
a general rule stated first swallowing the specific one stated second. It now
reads "contributes a point called `name` alone, never prefixed by the block".

The sixth is `inner_indices != outer_indices`, which I had removed once as
representation-pinning and then restored when the distinctness clause went in.
6 of 7 says restoring it was wrong: reporting distinct stacked positions requires
exposing the inner signal at the outer level, which is an implementation
strategy, not a behavior. Removed again, and the clause that existed to justify
it ("each keeping its own position among the stacked signals") went with it. The
port-collapse bug it was meant to catch is still caught behaviorally by
`test_nested_loop_transfer` and `test_openings_may_name_a_contributed_point`.

### Differential harness

Replay cannot show a description fix working, so both close runs were patched
with the one-line naming change the corrected sentence asks for.

| Run | As submitted | With the bare block name | Remaining |
| --- | --- | --- | --- |
| **Nova #4** | 7 | **0 of 277** | none |
| Orion #2 | 6 | 1 of 277 | `test_all_nested_points_round_trip`, a broadcast crash in its own nested wiring |

One agent's submission passes the entire suite once the naming rule it misread is
stated plainly, and nothing else in that submission is wrong. A twenty-ninth
mutation was added for the new rule (block point prefixed with the block name)
and is killed.

## The overlap wording

`test_partly_overlapping_points_cannot_open_together` is fair and solvable on the
record: 15 of 16 runs across three batches pass it, the single miss coming from a
run that failed eight other things, and Test Fairness rated it prompt-stated
twice. It is still the weakest of the overlap family, because the rule read
"two names opened at one location" while the test declares
`{'both': 'K.u', 'first': 'K.u[0]'}` and opens them together. Those are not one
location; they are two points sharing one channel. The rule only reached the case
if the reader took "location" to mean a channel, which the rest of the
description supports but never says.

Now channel-explicit: "only a name repeated in one call, or two names opening one
channel, is an error", and the error list reads "open one channel twice". That
covers both the exact-overlap test and the partial-overlap test with the same
words, and leaves genuinely distinct points alone. One word shorter, so 647.
A thirtieth mutation disables the shared-channel check and is killed.

## Batch 5 (10 runs, agent-runs(27)): first genuine pass, then a false positive

| Run | Solver | New failed |
| --- | --- | --- |
| **Nova #1** | Nova | **0 / 277** |
| Nova #2 | Nova | 120 / 277 |
| Nova #3 | Nova | 1 / 277 |
| Nova #4 | Nova | 10 / 277 |
| Nova #5 | Nova | 1 / 277 |
| Nova #6 | Nova | 119 / 277 |
| Nova #7 | Nova | 120 / 277 |
| Nova #8 | Nova | 5 / 277 |
| Orion #1 | Orion | 4 / 277 |
| **Orion #2** | Orion | **1 / 277** |

The block-naming fix from batch 4 worked: 1 of 10 pass, at the corpus mode, with
three more runs a single test away. Every run cleared the 3815-test baseline.

Then the FP adjudicator ruled Nova #1 a functional false positive on two defects
the 277 tests could not see, and it was right on both:

1. Opening a nested contributed point rebuilds and **renames** the child
   subsystem (`inner` becomes `sys[20]`), so a later name-based selection such as
   `io_transfer(sys, 'ref', 'inner.y', opened='inner_u')` raises "not a subsystem
   output". The description documents subsystem-signal selection and `opened` as
   independent capabilities of the same call, so composing them is stated; no
   test composed them.
2. `io_transfer`'s index path used `isinstance(item, int)`, rejecting numpy
   integers. The repository convention is `isinstance(x, (int, np.integer))`, and
   my own suite passes `np.int64` to `analysis_point`.

Both are now tested: `test_io_transfer_names_a_subsystem_signal_past_an_open_nested_point`
and `test_io_transfer_accepts_a_numpy_integer_index`. Verified against the
reference first, which keeps the subsystem names and returns the correct
transfers.

## Solution Quality: the two gaps behind 2/3

The reviewer passed the patch but scored Comprehensiveness and Code Quality 2/3
each, on two accurate findings.

**The runtime APIs were string-only.** The description says "All accept a
subsystem signal specification in place of a point name", and construction-time
declaration did accept the tuple and index forms, but `_channels`, `_selection`
and `replace_point` all required a plain string. A `_canonical` helper now spells
any accepted specification the way its dotted string form reads, and a tuple is
treated as one specification rather than a sequence of names in both `_channels`
and `_default_names`. `open_loop`, `close_loop`, `loop_transfer`, `sensitivity`,
`complementary_sensitivity`, `io_transfer` and `replace_point` all take
`('C', 'u')` and `(1, 0)` now, covered by
`test_a_signal_tuple_serves_wherever_a_point_name_does` and
`test_an_index_tuple_serves_wherever_a_point_name_does`.

**`connection_type` was dropped on rebuild.** `_rebuild` set it on the
interconnected system and then wrapped it in `LinearICSystem(newsys)`, whose
constructor overwrites the copy with its own `connection_type=None` default. It
now forwards `connection_type=sys.connection_type`.

Both coverage suggestions are in as well:
`test_failing_calls_leave_the_source_alone` (non-mutation on the error path of
every API, not just dictionary replacement) and
`test_analysis_point_block_is_named_after_its_signal`.

## The error-class pin

`test_two_analysis_point_blocks_may_not_share_a_name` failed 4 of 10 runs, all
with `RuntimeError: algebraic loop detected` rather than the ValueError/TypeError
the test accepted. Mutation testing settled it: disabling the reference's own
duplicate-name guard makes the reference raise the same RuntimeError. Both
implementations refuse to build the system; they differ only in which error
arrives first. That is an error-class pin, not a behavioral discriminator, and
the description names no exception class. The tuple now accepts RuntimeError.

The `_claim` mutant was dropped from the battery with it, since its only kill was
that class difference. The two sibling collision tests still kill the nlsys-side
duplicate guard behaviorally, because that mutant produces a silently wrong
system rather than an error. 29 mutations, all killed.

## Where solvability stands

Replayed against the revised 283-test suite:

| Run | Result |
| --- | --- |
| **Orion #2** | **283 passed, 0 failed** |
| Nova #5 | 1 failed (`partly_overlapping_points_cannot_open_together`) |
| Nova #1 | 2 failed, both new discriminators, so the false positive is caught |
| Nova #3 | 2 failed |
| Orion #1 | 3 failed |

A real submission passes the whole suite, and it is not the run the adjudicator
flagged. Nova #5's single failure is the overlap rule, whose wording was already
sharpened to "two names opening one channel" after batch 27 ran; its
implementation has no location-overlap check at all, so that one is a genuine
gap in its work rather than in the description.

## Test Fairness round 10 (104 sampled, 1 unfair)

`test_io_transfer_accepts_a_numpy_integer_index`, one of the two tests I added
to close the false positive. The reviewer's evidence contradicted the FP report
and is correct: python-control's signal-spec parser uses plain
`isinstance(spec, int)` at control/iosys.py:1257 and `isinstance(signal_spec,
int)` at 1308-1319, so numpy integers are excluded there. `np.integer` appears
only for signal counts at 1107, which is a different form. The FP adjudicator's
judge-c cited "the repo convention isinstance(x, (int, np.integer)) in iosys.py"
as backing; that convention exists for counts, not for indices, so the probe was
not repo-grounded after all.

That leaves two ways out: drop the test and leave the second FP defect
undetectable, or state the rule. Stated it, since dropping a test that catches a
real defect in a passing submission is what produced the false positive in the
first place. The description now says "A numpy integer serves as a count or
index", which covers the size parameter the reviewer already rated fair and the
`io_transfer` indices it did not. 646 words after five trims.

`test_analysis_point_accepts_a_numpy_integer_size` was rated fair and unchanged,
so the two now rest on one stated sentence rather than on two different readings
of the same repository file.

Tests and patches are unchanged by this round; Orion #2 still passes all 283.

## Coverage round: all three taken

| Suggestion | Test |
| --- | --- |
| string form should show the actual signal, not just the name or a whole-string difference | `test_string_form_shows_the_signal_each_point_sits_on` |
| default names for `sensitivity` and `complementary_sensitivity` | `test_sensitivity_names_its_result_by_default`, `test_complementary_sensitivity_names_its_result_by_default` |
| `replace_point` on a contributed point | `test_replace_a_contributed_point` |

The string one had to thread between two earlier verdicts. The first version was
flagged unfair for pinning a one-line-per-point layout; the replacement compared
two whole strings, which the reviewer then called insufficient because it never
shows the signal. The new test takes the lines present in a point-bearing system
and absent from its point-free twin, which is exactly the analysis points
section, and asserts that text names the point and its own signal and not the
other one. Signals are named `zeta` and `omega` so the tokens cannot appear
incidentally, and the separator is never asserted, so no layout is pinned.

`test_replace_a_contributed_point` substantiates "contributed points serve
anywhere declared ones do" on the one API that had no contributed-point
coverage: replacing the nested point by one leaves the system alone, by 0.5
gives `2.5/(s+4)` against a nominal `5/(s+7)`, and the point list survives.

287 tests. Orion #2 still passes all of them, so the coverage additions cost no
solvability.

## Coverage round 2: both taken

| Suggestion | Test |
| --- | --- |
| invalid top-level argument types beyond a plain LTI system | `test_every_api_rejects_something_that_is_not_a_system` |
| the block's own timebase, asserted directly | `test_analysis_point_block_carries_no_timebase_of_its_own` |

The first is written as nested loops over the seven APIs and five bad values,
not `pytest.mark.parametrize`. Parametrized node ids carry brackets, which the
platform verifier scores as missing tests, so parametrize stays out of every test
patch regardless of how well it reads.

The second asserts `dt is None` plus neither strictly continuous nor strictly
discrete, which is how python-control spells "compatible with any timebase". The
existing tests only reached that property through continuous and discrete
interconnections; now the block states it itself.

289 tests. Orion #2 still passes all of them.

## Quality warning: state assertions

Four tests asserted state counts or state-label order after `open_loop`,
`close_loop` and `replace_point`. The description only promised states stay put
for declaration, so the checker was right that the transforms had no such
guarantee. Test Fairness had passed all four in earlier rounds, but "not stated"
is the same defect either way.

Split the fix rather than picking one side, because the four tests were not
asking the same thing.

Three of them assert preservation, which every one of these calls really does:
`open_loop`, `close_loop`, `replace_point`, `loop_transfer`, `sensitivity` and
`io_transfer` all come back with the same state count on the fixtures. That is
now stated: the final paragraph reads "All take an interconnected system, name
their result, keep its states, and never modify it, even on error". Three words,
649 total.

The fourth, `test_replace_point_with_a_mimo_system`, asserted `nstates` equals
the original plus two after inserting a two-state block. That one is genuinely a
realization detail, and stating it would have contradicted the preservation
clause I had just written. Replaced with the behavior it was standing in for:
the loop transfer through the inserted block equals the original divided by
`s + 3` at every tested frequency. Stronger and free of any state claim.

289 tests, 29 of 29 mutations killed, Orion #2 still passes all of them.

## Batch 6 (17 runs, agent-runs(28)) and the side the labels go on

No passes, but Nova #13 failed exactly one test and Nova #5 and Orion #1 failed
two. Every run cleared the 3815-test baseline.

Nova #13's single failure was `test_sensitivity_labels`, and the assertion says
everything:

    assert ['u_inj'] == ['u_meas']

Its sensitivity carries `u_inj` on both sides. The line responsible is
`_assign_io_labels(result, loop.input_labels, loop.input_labels)`, passing L's
input labels to inputs and outputs alike. The description said S and T take
"L's input and output labels" without ever saying which side of S gets which,
and inverting `I - L` swaps the roles, so reading it the other way is not
careless. It now reads "both square, both taking `openings`, injections
labelling inputs and measurements outputs", which names both actors on both
sides at the same word count.

Eight other runs fail the same test, but none for that reason: four are the
`C_u_inj` naming cascade, four cannot resolve the point at all. Nova #13 is the
only run that reached the labels and put them on the wrong side.

### Differential harness

| Run | As submitted | With outputs taken from L's outputs |
| --- | --- | --- |
| **Nova #13** | 1 | **0 of 289** |

One word in one call. Nothing else in that submission is wrong.

The other frequent failures are not description gaps.
`test_io_transfer_names_a_subsystem_signal_past_an_open_nested_point` (12/17) and
`test_replace_a_contributed_point` (10/17) fail almost entirely with "couldn't
find system 'inner_u'", which is the contributed-name machinery missing
upstream. `test_point_on_a_subsystem_input` (12/17) is 8 runs returning None,
meaning input points were never implemented, and 4 returning `('input', [3])`
against the repo's own syslist-order offsets.

### Standing

| Run | Failures |
| --- | --- |
| Nova #13 | 1, the label side, now stated |
| Nova #5 | 2 |
| Orion #1 | 2 |
| batch-27 Orion #2 | **0 of 289, unmodified** |

## Full sweep: every saved submission against the current suite

Asked not to rest solvability on a single agent, I replayed all 43 saved
submissions from batches 2, 4, 5 and 6 against the current 288-test suite.

| Failures | Runs |
| --- | --- |
| **0** | 1 |
| **1** | 5 |
| 2 | 2 |
| 3 | 1 |
| 5-9 | 9 |
| 10+ | 25 |

Eight of forty-three land within two tests of a full pass. That distribution is
the real evidence: this is not a wall that one lucky run happened to clear.

### The five at exactly one failure

| Run | Blocker | Reading |
| --- | --- | --- |
| b28 Nova #13 | `test_sensitivity_labels` | description gap, now stated; harness takes it to 0 |
| b17 Nova #2 | `test_openings_may_name_a_contributed_point` | its contributed point shares a stacked location, contradicting a rule added two batches later |
| b27 Nova #1 | `io_transfer` past an open nested point | the rename defect the FP adjudicator found; genuine |
| b27 Nova #3 | `close_loop_after_an_undeclared_signal_declares_nothing` | "a specification never joins the list" is stated; genuine |
| b27 Nova #5 | `partly_overlapping_points_cannot_open_together` | no overlap check at all; genuine |

### Two submissions demonstrated at zero

| Run | Result |
| --- | --- |
| b27 Orion #2 | **288 passed, unmodified** |
| b28 Nova #13 | **288 passed** after the one-word label-side fix the corrected sentence asks for |

They come from different batches and different solvers.

## The numpy-index test, removed

`test_io_transfer_accepts_a_numpy_integer_index` is gone, and the clause "A
numpy integer serves as a count or index" with it. Three things lined up
against it:

1. Test Fairness flagged it as pinning a type coercion contrary to the
   neighbouring parser, which uses plain `isinstance(spec, int)` at
   control/iosys.py:1257 and 1308-1319.
2. The FP adjudicator's own judge #2 called it one of "two under-specified edges
   no fair probe can require".
3. It was the single most common last blocker among near-passers: b26 Nova #4,
   b27 Nova #1 and b27 Nova #3 all had it as a remaining failure.

I had answered the fairness flag by stating the rule instead of dropping the
test. With the sweep in hand that looks like the wrong trade: the clause bought
one FP probe of medium confidence at the cost of a requirement that contradicts
the repository's own convention and blocked three otherwise strong runs. The
other FP defect, the nested rename, is the one the adjudicator led with and is
still tested by
`test_io_transfer_names_a_subsystem_signal_past_an_open_nested_point`.

`test_analysis_point_accepts_a_numpy_integer_size` stays. Test Fairness rated it
repo-discoverable on its own, before any clause existed, because counts really
do accept `np.integer` at control/iosys.py:1107.

288 tests, 640 words, 29 of 29 mutations killed.

## Auto Review: revision requested, three passes, four findings

Three independent Auto Review passes converged on the same list. Two were real
bugs in my own reference, and both are fixed.

**S1 (High, all three passes): a subsystem with two names on one signal could not
be embedded.** `_hoist_analysis_points` exposed child points by calling
`open_loop(sys, labels)` with every child label at once, and `open_loop` rejects
two names resolving to one channel. So a child declaring
`{'first': 'C.u', 'second': 'C.u'}` was legal on its own and could be opened one
alias at a time, but putting it inside a parent raised the same-location error.
The description only makes that an error when both names are opened together, so
the internal hoisting step was behaving as though it were a user request.

Fixed by splitting the guard from the machinery. `open_loop` still resolves
channels, checks for a shared location, and raises; the channel building moved to
a private `_open_channels` that hoisting calls directly. Aliases now contribute
both prefixed names, and opening both on the child still raises.

**S1 (High, third pass): `close_loop` split a tuple into two names.** Its own
argument parsing ran `list(points)`, so `('C', 'u')` became the names `C` and
`u`. I had canonicalized specifications in `_channels` and `_default_names` when
the Solution Quality review asked for tuple support across the runtime APIs and
missed that `close_loop` parses its argument separately. It now treats a tuple as
one specification and canonicalizes it.

**T4 (High/Medium, all three): no test opened and closed with the same tuple.**
That is exactly why the `close_loop` bug survived. Added
`test_close_loop_takes_a_signal_tuple` and `test_close_loop_takes_an_index_tuple`,
plus `test_two_names_on_one_signal_may_be_declared_together` and
`test_a_subsystem_with_two_names_on_one_signal_can_be_embedded` for the alias
path. 292 tests.

**P4 (Medium, all three): the description was too dense.** Seven long
semicolon-heavy paragraphs, with the final error sentence quoted in every pass.
Restructured into 18 short paragraphs grouped by API, longest now 54 words
against 138 before, and the error contract split into two sentences instead of
one nine-clause chain. No headers or bullets, since the repo convention is plain
prose. 645 words, so still inside the cap.

The mutation battery needed one retarget: the "every loop is opened" mutant
pointed at a line the refactor moved. Repointed at the surviving guard, and it
kills again. 29 of 29.

Orion #2 still passes all 292 unmodified, with the four new tests included.

## Closing the FP properly

Removing `test_io_transfer_accepts_a_numpy_integer_index` during the solvability
sweep left half the false positive uncovered. The flagged submission still
rejected `np.int64(-1)` as an index and nothing in the suite noticed.

It is back, and this time the fairness objection is answered rather than
sidestepped. Test Fairness had said "the prompt says index but does not specify
NumPy scalar acceptance", which is a complaint about the description, not the
test. The `io_transfer` sentence now reads "by label or index, a negative index
counting from the end, numpy integers included", so the form is specified where
the selector is described. Three words, 648 total.

The earlier version of this fix put the rule in a standalone sentence at the end
of the contract, away from the API it governs. Attaching it to the index clause
costs less and reads as part of the selector rather than as an appended
requirement.

Both defects the adjudicator found are covered again, and the flagged run fails
all three of these:

| Test | Defect |
| --- | --- |
| `test_io_transfer_names_a_subsystem_signal_past_an_open_nested_point` | opening a nested point renames the child |
| `test_io_transfer_accepts_a_numpy_integer_index` | plain `isinstance(item, int)` |
| `test_close_loop_takes_a_signal_tuple` | caught incidentally by the Auto Review fix |

Solvability is unaffected: b27 Orion #2 passes all 293 unmodified, as it did with
this test present before. The cost falls on runs that were already failing for
other reasons.

293 tests, 29 of 29 mutations killed, 648 words.

## Running the FP check myself

Rather than keep saying an FP could not be ruled out, I built the adjudicator's
own instrument: 73 differential probes across the whole API surface, run in a
reference tree and in the demonstrated passer's tree, compared field by field.
Signatures cover labels, sizes, state labels, point lists, timebase and the
rounded frequency response, plus 17 error probes checking the exception class.

First run: 10 divergences of 73. One was a real defect, in my reference.

**Opening a declared location by specification did not retire the point.**
`open_loop(sys, 'u')` removed the declared point, but `open_loop(sys, ('C','u'))`
and `open_loop(sys, 'C.u')`, naming the same physical channel, left it listed.
Same location, different answer depending on how it was addressed. The
description says a broken point is no longer listed, so the candidate, which
retires it either way and restores it on close, was right and the reference was
wrong.

Fixed by tracking the declared owner of each opened channel instead of matching
on the label used. Opening retires whatever point covers the channel, and
closing gives that name back. All four addressing forms now agree, and an
undeclared specification elsewhere still leaves the declared point alone. Two
tests pin it, and the description says so.

The other nine divergences are all names or shapes nothing specifies:

| Divergence | ref | candidate |
| --- | --- | --- |
| channel labels for a specification-addressed point, 8 probes | `C_u_inj` | `u_inj` |
| state label of a block inserted by `replace_point` | `sys[329]_x[0]` | `u_replacement_x[0]` |
| state count of a loop transfer with no points | 0 | 1 |

Every numeric response matched. Test Fairness had already rated leaving the
generated prefix unpinned as correct, and the suite only checks the suffix. To
make that explicit rather than merely untested, the description now says a
specification "ends its channels the same way, on a leading part of the
implementation's choosing", so the freedom is stated instead of assumed.

Second run after the fix: the semantic divergence is gone and only the nine
name-and-shape differences remain, which no prompt-grounded probe can call a
violation.

295 tests, 29 of 29 mutations killed, 500 effective LOC, 689 words. Orion #2
still passes all 295 unmodified; the flagged FP run fails 4.

## Hints aimed at the measured failure classes

The Auto Review tallied which mistakes actually cost runs, and my own batch
analysis agrees. Four clauses added, each pointed at a counted class rather than
at a guess.

| Runs lost to it | What went wrong | Clause added |
| --- | --- | --- |
| 5 | specifications implemented only as aliases for already declared points, so `S.e` was rejected | "The signal need not be declared: any subsystem signal can be opened, measured or replaced on the spot" |
| 5 | an omitted `replace_point` value read as a zero replacement | "It has no default: leaving it out is an error rather than a zero" |
| 4 | the hierarchical prefix applied to directly declared names, giving `C_u` for a declared `C.u` | "Only names the library generates are built that way; a declared point takes its signal's base name, or the one its dictionary key gives, never a prefixed form" |
| 3 | input-point positions reported in a combined output-plus-input space | "of that kind" restored to the `find_analysis_point` sentence, plus "An input point counts from the first subsystem input, not from anywhere in the outputs" |

The third and fourth were already stated but buried. The `find_analysis_point`
sentence had said "positions in the stacked signals of that kind" until I trimmed
"of that kind" to hold a word cap several rounds ago, which is exactly the
distinction three runs then missed. Restoring it costs three words and was my
error to begin with.

Each clause was checked against the reference before being written, so none of
them describes behaviour the implementation does not have:

    declared list form  -> ['u']                  unprefixed base name
    dictionary form     -> ['control', 'error']   dictionary keys
    input point         -> ('input', [0])         stacked inputs
    undeclared 'S.e'    -> opens, replaces, leaves the point list alone
    missing value       -> raises

768 words in 18 paragraphs, longest 79. Tests and patches are unchanged; this is
a description-only round.

## Coverage round: two taken in full, one taken in part

| Suggestion | Test |
| --- | --- |
| a failed call with `name=` must not rename the source | `test_a_failing_call_does_not_take_the_name_it_was_given` |
| numpy integers inside an index list | `test_index_lists_may_hold_numpy_integers` |
| boolean and non-finite replacement scalars | `test_boolean_replacement_scalars_act_as_one_and_zero`, booleans only |

The third was split deliberately. `True` and `False` are worth pinning: Python
makes them 1 and 0, and the description already gives 1 and 0 their meanings, so
the expected behaviour follows without inventing anything. The reference agrees,
`True` leaving the system alone and `False` opening the loop.

`NaN` and infinities are a different matter. They currently surface as
`RuntimeError` out of the algebraic-loop detector, which is an artifact of how
the fixed point is solved rather than a decision the description makes. Pinning
either outcome, the error or an acceptance, would fix an unstated error class,
which is the same trap that made `test_two_analysis_point_blocks_may_not_share_a_name`
unfair earlier in this submission. Left untested on purpose.

Same reasoning as `analysis_point(size=True)` two rounds ago, and the opposite
conclusion for booleans here, because the questions differ. There the choice was
accept versus reject with nothing to decide it. Here the value is determined by
Python and the meaning of that value is already in the description.

298 tests. Orion #2 still passes all of them; the flagged FP run fails 5.

## Local verification (author)

| Check | Result |
| --- | --- |
| Base suite on vanilla repo, pinned deps | 3814 passed, 0 failed |
| Base suite with solution applied | 3814 passed, 0 failed (no regressions) |
| New tests on base | 298 failed, 0 passed |
| New tests with solution | 298 passed |
| Effective LOC (`human-effective`) | 500 across 4 files |
| Flakiness, base 3x | identical |
| Flakiness, new 3x | identical |
| Mutation battery | 29 of 29 mutations killed |
| Docker offline, uid 1000 | base 4385 cases 0 failures; new 298 cases 0 failures |
| Test Fairness | 22 flagged across 6 runs, all resolved; 32 coverage suggestions taken, 6 real bugs found |
| Both patch apply orders | clean, 298 passed either way |
| Description formatting | paragraphs unwrapped; no em dashes, ASCII |
| Problem/test quality AI check | internal-matrix assertions and repr-header parsing both removed |
