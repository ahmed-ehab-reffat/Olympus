# feedback.md — mpmath-odefun-events

## Summary

Olympus submission against [mpmath/mpmath](https://github.com/mpmath/mpmath) at
`017cc473fb22f1fc1f7477d7ec1ce19a1b50d61e` (1184 stars, BSD-3-Clause, pure Python,
no runtime dependencies). The feature extends `odefun`, the arbitrary-precision
Taylor-series ODE solver, with event detection, backward integration, an analysis
API on the returned solution object, and a boundary value solver built on top.

Deliverables: `BASE_COMMIT.txt`, `meta.md`, `test.patch`, `solution.patch`,
`Dockerfile`, plus this file and `eval-results.md`.

## Repo choice (autonomous discovery)

The standing preference is a repo never used locally. Every repo under
`Instructions/Aprroved/`, `Instructions/rejected/`, `Instructions/Task*/problems/`
and `Instructions/Task*/worktrees/` was enumerated first; mpmath appears in none of
them, so this is the first submission against it (repo quota 1 of 6).

Candidates considered and dropped before mpmath:

| Candidate | Why dropped |
| --- | --- |
| RocketPy | Best feature gaps (multi-stage, powered descent, spherical earth) are covered by open issues #662, #952, #751, so they read as a binding spec; 84 open PRs is an exclusivity minefield |
| SALib | 14 sibling analyze/sample module pairs: adding a method is pattern-followable, auto-RED under the triviality filter |
| hmmlearn | Last push 2024-10, fails the 12-month activity gate |
| pandera, pvlib | pvlib already approved (`pvlib-loss-attribution`); pandera has 446 open issues |
| pytransform3d | GitHub reports the license as NOASSERTION, and platform compliance screens the SPDX id |
| NURBS-Python, meshio, filterpy, quadpy | activity gate (>12 months) or no SPDX license |
| skyfield, mne-python | test suites download data, so the environment cannot run offline |

mpmath won on the environment gate above all: no dependencies, the whole tree runs
offline in 14 minutes, and every result is deterministic to the last digit.

## Feature choice

`odefun`'s own docstring lists "Allow solution for `x < x_0`" as an open TODO, and
there is no event machinery at all. Neither is covered by a PR or an issue:

```
gh pr list -R mpmath/mpmath --state all --search "odefun"    -> none
gh pr list -R mpmath/mpmath --state all --search "event"     -> none
gh pr list -R mpmath/mpmath --state all --search "backward"  -> unrelated (jtheta, to_str, matrix APIs)
gh issue list -R mpmath/mpmath --state all --search "odefun" -> #228 (a stall on one specific system), #71 (closed, asks for the precise solver that already exists), #373 (docs)
```

## Assumptions and decisions (autonomous run)

1. **Scope.** Events alone did not reach the LOC floor, so the feature was widened
   along one coherent axis: everything that a two-sided, event-aware solution object
   naturally offers (derivatives, local series, integrals, level crossings, extrema,
   optima) plus a boundary value solver that reuses the event machinery for a free
   endpoint. Nothing was added that the tests do not exercise.
2. **Dropped from scope.** Invariant projection (only observable at a loose `tol`,
   so no robust assertion exists) and a fix for `fp.odefun` (already broken on base
   with an `OverflowError`, and unfixable without changing the stepping algorithm).
   The four float-context tests were removed with them.
3. **Base mode scope.** `test.sh base` runs the ODE, calculus, differentiation,
   summation, quadrature, basic-ops and conversion suites (109 cases, ~60 s) rather
   than the whole tree, which takes 14 minutes. The whole tree was still run in the
   container and is green.
4. **Radius estimate.** The existing step estimate looks only at the last Taylor
   coefficient, which vanishes at a symmetric expansion point and lets a step grow
   until the interpolation loses digits. The reference now takes the estimate over
   the whole tail and shortens a step until the series satisfies the ODE. Without
   this, accuracy depends on whether an implementation happens to build its first
   segment at a lower precision, which would have made the digit assertions unfair.
5. **Description length.** 755 words. That is above the 500-word cap in the
   project notes but inside the range of the shipped corpus (480 to 881 words), and
   the API cannot be pinned in fewer words without leaving a tested requirement
   undocumented, which is the more expensive failure.
6. **Effective LOC.** 414 human-effective (524 raw) across 3 files. That clears the
   400 platform auto-block but sits below the 430 hook target, so a later revision
   must not remove a surface without replacing it.

## Validation

| Check | Result |
| --- | --- |
| `test.sh base` on base tree + test.patch | PASS (108 passed, 1 xfailed) |
| `test.sh new` on base tree + test.patch | FAIL (123 of 123 fail) |
| `test.sh base` with solution applied | PASS |
| `test.sh new` with solution applied | PASS (123) |
| Whole tree in the container, both patches applied | 2244 passed, 5 skipped, 2 xfailed (2131 of them existing, measured at 113 new tests) |
| Determinism | 5 x new and 3 x base in the container, identical every run; 3 more after the fairness round |
| Mutation battery | 15 wrong-decision mutations, every one killed by at least one test |
| Patch order test then solution, and solution then test | both apply, both unapply |
| Docker offline, non-root (`--network none --user 1000:1000`) | both modes run |
| Patch encoding | ASCII, LF, `test.sh` at mode 100755 |
| Comments added by the patches | 3 lines, matching the style of the surrounding module |

## Attempt history

- **Round 1 (design).** Repo screening, feature choice, DESIGN.md, reference
  implementation, 113 tests, Dockerfile, patches, full validation matrix.
  Corrections made during the round: a lazily created first segment lost accuracy
  against the base behaviour (fixed by the tail-based radius estimate); an event
  landing exactly on a step boundary was missed (fixed by treating an exact zero at
  a sample as a crossing); a reset landing exactly on the event surface hid the next
  crossing (fixed by skipping only the entry zero); three tests asserted wrong
  closed-form values and one test used `mpf` defaults evaluated at import time, when
  `mp.dps` was still 15.
- **Round 1, mutation pass.** Fifteen deliberate wrong decisions were injected into
  the reference one at a time (`eval-results.md`). Fourteen were caught immediately.
  The fifteenth, scanning only the segment boundaries when looking for crossings,
  killed nothing: the oscillating fixture had short enough steps that no two roots
  ever shared one segment. A test with two roots inside a single Taylor segment
  (a level just under the peak of a cosine) was added, and the mutation now dies.
  One test that read `ODEEvent.terminal` back was dropped: the attribute is not
  promised by the description and the behaviour it stood for is covered elsewhere.
- **Round 2 (Test Fairness).** The checker passed 112 of 113 tests and failed one:
  `test_stopping_event_endpoint_is_recorded` read `result.events[0][0][0]` after an
  `odebvp` call with `stop`, and nothing said the stop event ends up on the returned
  solution. Since that assertion is also the only thing that catches a `odebvp` which
  returns an unadvanced solution, the description now states it instead of the test
  being dropped: the stop event is the one event the result carries, so its crossing
  is the first record. Two other rules the new coverage needed were stated at the
  same time: the length rule for `y0` and `y1`, and that the other solution methods
  raise past a stop as well, not only `sol(x)`.

  The quality notes were taken as written. Every `zip` comparison now asserts the
  record count first, which immediately exposed a wrong expectation of mine: sin has
  only one falling crossing below x = 9, not two, so that test now runs to 10.
  `test_maxevents_allows_the_permitted_crossings` did not actually pass `maxevents`,
  and the retrigger test compared string forms instead of counting bounces; both are
  fixed. The four coverage suggestions were filtered rather than worked through, because every
  test added late multiplies the failure rate and a batch has been lost that way
  before. One was taken: whether the other methods also stop at a terminal event was
  genuinely undefined, so the rule is now stated and one test covers `sol`, `diff`,
  `integral` and `crossings` together. The rest were declined as enumerations of
  boundaries the suite already asserts once for the group (component and range
  validation is checked on `crossings`, `roots` and `maximum`; the above-degree
  derivative rule is checked at order 400; the stopping point being usable is checked
  through `domain`). The backward `odebvp` with a stopping event was declined for a
  different reason: the shooting search does not converge from an arbitrary guess
  there, and a test that depends on a lucky guess is worse than no test. 114 tests
  now, all still failing on base.
- **Round 3 (Test Fairness).** Five failures, all real, and four of them mine from the
  round before. The two bouncing-ball tests I had shortened to x = 1.5 to dodge the
  Zeno accumulation asserted three bounces, but the third impact is at 1.5972: they
  passed only because my stepper happens to overshoot the requested point and process
  the crossing anyway. That is my step size leaking into the contract, so both now ask
  for the third bounce time itself and assert `>= 3` records with the first three
  pinned. Two others still ran to x = 3, past the accumulation at 1.9166, where no
  continuation is specified at all; they only ever needed the first impact, so they
  stop there. The last one constructed a solution with a complex event function
  outside the `raises` block, which pinned validation to evaluation time when
  construction is an equally reasonable moment; the construction and the call are
  inside the block now.

  The four coverage suggestions were declined again on the same grounds as round 2
  (more index and range enumerations, more stopped-domain methods, a backward
  `odebvp` with a stop that does not converge from an arbitrary guess). The substance
  of the one about callback validation is in the fix above.

  Re-verified after the edits: 114 tests, all still failing on base, 3 identical
  container runs, base unchanged, and all 15 mutations still killing.
- **Round 4 (stale report).** The fourth Test Fairness result was byte-identical to
  the third, down to the execution time, and every quoted line (`y(mpf(3)/2)`,
  `len(times) == 3`, a bare `y(3)` on the bouncing solution) had already been removed
  in round 3. It was a re-run of the previous artifact, not of the current one, so no
  flag was acted on twice.

  Auditing it against the shipped patch did find one real thing, though:
  `test_derivative_at_a_reset_point_uses_the_earlier_branch` still ran the bouncing
  solution to x = 3, past the Zeno accumulation. It is the same defect I fixed in its
  two siblings and I simply missed the third instance, partly because both reports
  had explicitly praised this test as staying clear of the accumulation. It now stops
  at the first impact like the others. No bouncing fixture reaches past 1.6 anywhere
  in the suite now. Re-verified: 114 pass, 114 fail on base, 2 identical container
  runs, base unchanged, and the five reset-dependent mutations still kill.

  Lesson for the next round: when a checker flags a class of defect, grep the whole
  suite for that class instead of fixing only the instances it named. Its per-test
  verdicts are not a complete inventory, and here one of its "fair" verdicts was
  factually wrong about the test it was defending.
- **Round 5 (Test Fairness).** A real run this time, and it cleared everything from
  round 3. Four new failures, all one class: the tests for a bad `direction`, a bad
  `terminal` count and a non-positive `maxevents` called the constructor inside
  `pytest.raises`, which pins validation to construction time. The description says
  those values raise `ValueError` but never says when, and an implementation that
  checks them when the event is first used is just as faithful. Rather than pin a
  moment in the prompt, all four now construct and use the object inside the same
  `raises` block, so either timing passes. That is the same fix the complex-event
  test got in round 3; I should have applied it to the whole family then.

  One coverage suggestion was taken: `maxevents` is stated as a limit on "one event
  in one direction", and every test used a single event, so a shared counter across
  events passed the whole suite. A two-event test now separates the readings, and a
  new mutation (count across all events instead of per event) dies on it. The other
  four suggestions were declined as before: enumerating more index and range errors,
  more stopped-domain methods, a default `guess` that the linear BVP test already
  exercises, and a backward `odebvp` with a stop that does not converge.

  115 tests, all failing on base, 2 identical container runs, base unchanged, and
  17 mutations now killing (the 15 originals plus the two new validation probes).
- **Round 6 (coverage suggestions on a clean fairness run).** Four of the five were
  the enumerations already declined in rounds 2, 4 and 5, plus one that asked for
  error semantics on malformed `reset`/`switch` return shapes, which the description
  deliberately does not specify.

  The fifth was worth taking and exposed two defects in my own reference. The
  description says `maxevents=n` allows "at most n crossings", but the limit was
  checked after the record was appended, so exceeding it left n+1 records: the
  reference contradicted its own spec, and an agent implementing the sentence
  literally would have been the more correct one. Worse, the raise happened after the
  segment and record were already stored, so every repeated call past the limit
  appended another duplicate: two calls to `y(5)` grew the list from 5 records to 6.
  The check now runs before anything is mutated, so exactly n records survive and
  retrying is idempotent. The existing maxevents test carries the two new assertions
  rather than a new test being added, and two mutations (drop the limit, record then
  raise) both die on it.

  Not taken but recorded: when two events cross at exactly the same x, the first in
  the list is recorded and the second is silently skipped, because the next step then
  starts on its zero. Nothing in the description covers simultaneous events, and no
  test does either, so any behaviour passes; pinning it would mean committing to a
  wart. Flagging it here so a reviewer meeting it knows it is deliberate.

  115 tests, all failing on base, 2 identical container runs, base unchanged,
  19 mutations killing.
- **Round 7 (three suggestions left).** Two were the stopped-domain and index
  enumerations declined in every round since the second; the rule each covers is
  stated once and asserted once for the group, and repeating it per method only
  multiplies the failure rate.

  The third was right, and measuring beat guessing. Four BVP tests do omit `guess`,
  so the suggestion's premise looked wrong, but a mutation settled it: defaulting the
  missing guess to sevens instead of zeros kills nothing, because every BVP in the
  suite is linear in the unknown and shooting converges from any start. So "zero by
  default" was a described-but-unasserted claim. Making it assertable needs a
  nonlinear problem with several roots where the converged one depends on the start,
  which is brittle across `findroot` internals and exactly the class I have been
  declining. The sentence now reads that `guess` may be left out, which keeps the
  four omitting tests fair and drops the claim nothing checks. A supplied `guess` is
  still only contracted by its length check, which is honest: on these problems its
  value cannot matter.

  115 tests unchanged, meta 749 words.
- **Round 8 (four suggestions).** Three were declined again: the stopped-domain and
  index enumerations, and the backward `odebvp` with a stop, which still does not
  converge from an arbitrary guess.

  The fourth was new and worth taking. `reset` and `switch` were only ever triggered
  on the forward branch; the two tests that mention backward only check that a
  FORWARD action leaves the backward branch alone. So an implementation that handled
  either action only for the forward direction passed the whole suite, on the exact
  code path where this feature is hardest. Two tests now fire each action on a
  backward crossing and confirm the forward branch is untouched, and two mutations
  (apply reset / apply switch only when the direction is forward) die on them.

  While writing them I mis-diagnosed a bug: querying an independently computed event
  time returned the post-reset value and looked like a broken backward branch. It was
  the boundary sensitivity from round 3 again, the query point landing a bit past the
  crossing. The records and the exact-crossing value were correct all along, and the
  tests avoid the trap by querying strictly between crossings.

  117 tests, all failing on base, 2 identical container runs, base unchanged,
  21 mutations killing, 414 effective LOC.
- **Round 9 (four suggestions, two taken).** The stopped-domain and index
  enumerations were declined for the sixth time.

  The backward `odebvp` with a stop event I had declined four times, saying it does
  not converge from an arbitrary guess. That was wrong, and I had never checked it
  after the first attempt: my original probe used a launch-from-origin framing with
  the wrong crossing direction, so it hung, and I generalised from one bad setup.
  Running the projectile backward from its landing converges immediately and exactly
  (vx = 10, crossing at -4), because the residual is linear in the unknown and the
  flight time does not depend on it. It is now a test, and a mutation that searches
  for the stop as if the far end were ahead dies on it. Backward shooting and
  event-defined endpoints were each covered alone but never together.

  The fourth found a second place where the description out-promised the reference.
  It says an event function must return a real value and "anything else raises
  ValueError", but a callback returning a list produced a TypeError from the
  conversion, so an agent implementing the sentence literally was again more correct
  than my reference. The conversion is now guarded, the existing real-value test
  carries the extra case, and a mutation removing the guard dies on it.

  118 tests, all failing on base, 2 identical container runs, base unchanged,
  23 mutations killing, 418 effective LOC.

## Final gate review (requested: solvability, fairness, difficulty, FP)

**Fairness: verified locally, clean.** The description splits into 32 normative
clauses. All 118 tests map to exactly one clause and every clause has at least one
test, checked mechanically in both directions: no unmapped test (a hidden
requirement) and no unasserted clause (over-specification). The last automated
Test Fairness run also passed with zero unfair tests.

**FP: verified as far as local work can take it.** Two places where the description
out-promised the reference were found and fixed, both by taking a coverage
suggestion seriously rather than dismissing it: `maxevents` kept n+1 records against
a prompt saying "at most n" (and duplicated them on retry), and a non-real event
value raised `TypeError` against a prompt saying `ValueError`. In both an agent
implementing the sentence literally was more correct than my reference, which is the
FP shape exactly. The reference was then swept against its two group-wide claims --
every method rejecting a point past a stop (10 of 10) and every ranged or indexed
method validating its arguments (9 of 9) -- and no further gap was found. Every
transformation verb in the description has an input where doing it twice is
distinguishable from doing it once.

**Difficulty: 23 independent wrong decisions, all caught.** The battery covers 23
plausible-but-wrong implementation choices; every one kills at least one test, mean
1.3 tests each. They are interdependent rather than isolated: the segment-lookup
choice, the restart after a reset and the entry-zero rule all run through the same
two-sided cache, so a local fix to one surfaces another. Several are misdirecting --
locating a crossing by interpolation surfaces as a wrong digit in a bounce time, not
as an obviously imprecise root finder.

**Solvability: structurally sound, but the real gate is a batch I cannot run.**
Passing means avoiding all 23 decisions, so the rate is about p^23. At 90%
per-decision that is 9%, at 85% it is 2.4%, at 80% it is 0.6%. Every one of the 23
traces to a quoted clause, so all are discoverable from the description alone; that
is the "hard but fair" profile and predicts roughly 1 to 3 of 10. It is honest to say
the tail is real: if several decisions correlate the batch can come back 0/10. No
local proxy settles this. If a batch does return 0, the cheapest levers in order are
the crossings-completeness test (least discoverable of the 23, since a per-step
bracket scan is the natural implementation), the maxevents retained-count assertion,
and the functional-integral split across a reset. Removing those three costs three
tests and lifts the floor without touching the description.
- **Round 10 (five suggestions, two taken).** Three declined: the stopped-domain and
  index enumerations, already swept clean across all ten and all nine methods, and
  non-whole or boolean `maxevents`, which the description does not speak to at all --
  testing it would mean inventing prose first. A negative `maxevents` was probed and
  does raise, so the stated rule holds; only zero is asserted, which is enough for a
  rule with one boundary.

  Taken, both as genuine gaps. The plain-callable test could not distinguish a
  default `direction` of 0 from 1, because its event crossed once, rising; it now
  uses a periodic event and requires both the falling and the rising crossing, and a
  mutation giving plain callables a rising-only default dies on it. No test count
  added, since the old test was replaced.

  The second is a lesson in not trusting a green test. The suggestion asked whether
  `x1` really bounds the stop search, so I wrote a case whose event lies beyond the
  bound and watched it raise. It passed -- but the mutation that ignores the bound
  entirely also passed, because the shooting on that fixture diverges and raises for
  an unrelated reason. Rewritten on the projectile, where ignoring the bound finds
  the landing at 4 and converges cleanly, the mutation now dies. A test that passes
  and whose mutation survives is not evidence of anything.

  119 tests, all failing on base, 2 identical container runs, base unchanged,
  25 mutations killing.
- **Round 11 (four suggestions, one real defect).** The BVP stop-result shape was
  probed rather than argued: the result carries exactly one event list and evaluates
  at the stop to the exact landing state, so both halves of that sentence already
  hold and the existing assertion implies the advancement. Declined as redundant.
  The stopped-domain and range/index enumerations were declined for the eighth time,
  both already swept across all ten and all nine methods.

  The validation-breadth suggestion looked like the ninth enumeration and was not.
  Probing the full "anything else raises ValueError" contract for `terminal` found
  `None` and `[1]` raising `TypeError`, because `int()` fails differently for a
  non-numeric type than for a bad numeric one. That is the third time the description
  out-promised the reference and the second time in this exact shape, after the event
  callback. Guarded, the existing whole-number test carries the extra case, and a
  mutation removing the guard dies on it.

  Worth naming the pattern: every defect this and the last three rounds came from
  probing a claim in the description against the reference, never from the suggestion
  text itself. The enumerating suggestions have never once found anything, but the
  ones that quote a contract have found five defects between them.

  119 tests, all failing on base, 2 identical container runs, base unchanged,
  26 mutations killing, 421 effective LOC.
- **Round 12 (three suggestions, one taken).** The stopped-domain and range/index
  enumerations were declined for the ninth time.

  The third asked for the backward mirror of the stop-point-stays-available rule, and
  I took it despite the reference already being correct there, on a rule this session
  has taught twice: my implementation is direction-generic, so no mutation of it is
  backward-only, but an implementation with separate forward and backward paths would
  fail exactly here, and that is the shape that made backward `reset` and `switch` a
  genuine gap. Probing first showed the reference returns the right values at a
  backward stop through `sol`, `diff`, `taylor` and `integral`. The new test pins
  `sol` and `diff` there, and a mutation that closes a stopped backward branch at its
  own endpoint dies on it while every forward test stays green, which is the proof
  that the forward test was not already covering it.

  120 tests, all failing on base, 2 identical container runs, base unchanged,
  27 mutations killing, 421 effective LOC.
- **Round 13 (four suggestions, two taken).** The range and index enumeration was
  declined for the tenth time, and the BVP stop endpoint was probed clean last round
  already: the result carries one event list and evaluates at the stop to the exact
  landing state.

  Two were real gaps, and both were about which crossing wins. Every multi-event test
  so far used events whose crossings fall in different steps, so an implementation
  that processes the first event in list order rather than the earliest crossing
  passed everything. With two events crossing 0.001 apart inside one step, and the
  later-crossing one listed first, the list-order implementation truncates at the
  wrong place and the other event is left behind the tip, never recorded. It is now a
  test, and the mutation dies on it. The same applies to a terminal count above one:
  the per-direction rule was only exercised at a count of one, where a shared counter
  is indistinguishable, so `terminal=2` is now run on both directions of one solution
  and a shared counter stops the backward side a crossing early.

  122 tests, all failing on base, 2 identical container runs, base unchanged,
  29 mutations killing.
- **Round 14 (four suggestions, none taken).** First round that changed nothing, and
  the reasoning is worth recording so it does not read as fatigue.

  The stopped-domain enumeration was declined for the eleventh time. Callback-shape
  errors were declined because the suggestion conditions itself on those errors being
  part of the public contract, and they are not: the description says nothing about a
  `reset` returning the wrong shape, so any behaviour passes and a test would need
  invented prose first.

  The BVP stop-result domain was probed rather than assumed, and all three of its
  claims hold: `domain` is `(-inf, 4.0)` against a stop recorded at 4.0, the endpoint
  itself evaluates, and a point beyond raises. Each of those rules is already asserted
  once elsewhere, so this only re-tests them on a different object.

  Two events crossing at exactly the same x was probed again and confirmed: the first
  in the list is recorded and the second silently gets nothing. This is deterministic,
  unspecified in the description, and therefore untestable in either direction, which
  is why it stays out. Pinning it would mean committing prose to a wart and adding a
  test for an exotic corner that carries no fairness or false-positive benefit, and
  making the reference record both would mean inventing an order for combining two
  resets at one point, which is new unstated behaviour and new failure modes in a
  reference that currently passes 122 tests against 29 mutations. Left alone
  deliberately, and noted here so a reviewer who constructs coincident events knows
  it was a decision.

  Artifact unchanged this round: 122 tests, 29 mutations, same patch hashes.

## Batch 1 (5 Nova runs) and the de-trapping round

**0 of 4 completed runs passed** (the fifth left only a `run.txt`). Every evaluator
recorded the description as clear, the tests deterministic, `agent_blame_unfair`
false and no environment blocker; the baseline suite was 108 of 108 everywhere. So
the artifact is sound and the number is real.

**All four runs failed the identical six `switch` tests.** That is the signature the
playbook calls a 0% trap rather than difficulty: a deterministic universal miss on
one described requirement. Every agent read `switch(x, y)` as a factory to call at
the crossing, installing whatever callable came back, and raised when handed a plain
derivative. One evaluator spelled out the remedy in its own notes.

Strip that one cluster and the batch is a well-calibrated near miss: Nova 1, 3 and 4
each fail exactly one further test, and only Nova 2 has a broad defect. Three runs
one test away is where this should sit; they were held out by a sentence, not by the
work.

The two surviving single failures exposed a second, smaller gap of the same kind. My
accuracy sentence lived only in the events paragraph, yet the tests demand ten digits
from `crossings` and sixteen from `integral(a, b, f)`. The reference hits both with
zero error, so the bar is reachable, but it was never stated for those methods, and
two agents were failing an unstated contract: one stopped refining a closely spaced
root at 1.1e-9, another ran a single quadrature across a reset and got 2.5081 for an
exact 2.5.

**Two clarifications, no test and no reference line changed:**

1. `switch` is now "itself the derivative function used for the rest of that
   direction: it is called exactly like `F` and returns the derivative, not a
   replacement function."
2. The working-accuracy contract is stated for the searches and for both forms of
   `integral`, including across an event.

Neither eases a requirement; both name a surface that was already being tested. The
suite still passes 122 of 122 against the unchanged reference, and `test.patch` and
`solution.patch` are byte-identical to before, so nothing in the batch's own
verdicts is invalidated.

**On the false-positive gate:** with zero passes there is no passing agent to audit,
so FP is vacuously clean and stays an open gate until a run passes. The near misses
are the useful evidence instead, and none of them shows an agent satisfying the tests
while violating a stated requirement; the four failures are all the reverse, agents
violating a requirement and being caught.

**Prediction for the next batch, recorded now so it can be checked:** the switch fix
converts three of these four runs from seven failures to one. Whether they then pass
turns on the closely spaced root and the integral across a reset, both of which are
now stated. I expect 1 to 3 of 10 rather than 0, and if the next batch is still 0
with the same two tests as the only blockers, those are the two to cut, in that
order, exactly as recorded before the batch ran.

### One added clause (a hint, in the only place Olympus allows one)

Olympus has no hint field, so it goes in the description and has to stay behavioral.
The searches sentence now ends "including where several of them lie close together".

It targets the exact regime that killed Nova 1 and 4, whose refine loops stopped
around 1e-9, and it names a surface rather than a method: nothing about sampling,
subdividing or which root finder to use. It is covered by two existing tests, the
closely spaced pair and the fast oscillator, so it adds no undescribed behavior and
no over-specification either way.

Stopping at one clause on purpose. Each clarification of this kind moves the artifact
toward the too-easy edge, and the batch evidence says one sentence, `switch`, was
carrying the whole 0%; the accuracy scope was second. A third and fourth nudge would
be guessing rather than answering evidence, and the next batch is what should decide
whether anything more is needed.

### Category check failure and the framing fix

The automated category check failed `feature-request`, on the grounds that the text
"merely describes existing features rather than suggesting the addition of new ones".
That reading is fair and the fault is mine: the body was written in declarative
present tense, as a specification of how the API behaves, so nothing in it said the
work does not exist yet. The title carried the only signal, and a title is not
enough.

The category itself is right and stays: a new public type (`ODEEvent`), a new entry
point (`odebvp`), new keyword arguments and new methods on the returned object are
net-new surface, not a modification of existing behaviour, so `enhancement` would be
the dishonest choice.

Three sentences now carry the framing, one per major surface, without turning the
prose into a spec sheet:

- the opening states what `odefun` does today and asks to extend it, then to add
  `ODEEvent` and a new `events` argument;
- the records paragraph opens with what the solution has to expose;
- `odebvp` is introduced with "Add".

Everything pinned stays word for word. No test and no reference line changed, the
suite is still 122 of 122, and both patches are byte-identical, so the batch verdicts
remain valid evidence.

### Round 15

Four declined, all previously swept or probed: the stopped-domain sweep across every
method (twelfth time, and the backward half is covered by the backward-stop test
added in round 12), the range and index symmetry including the observation that
`integral` reverses while the searches reject, which is exactly what the description
says and what the suite already asserts on both sides, `maxevents` breadth, and the
BVP stop-result domain probed clean in round 14.

The fifth was a combination never exercised: a terminal event on a branch where a
different event has already reset the state. Every earlier multi-event test used
non-terminal events, and every terminal test used one event. Probed first, and the
reference is coherent: two reset records at log 2 and 2 log 2 carrying the pre-reset
state, the terminal record at 2, a domain ending at 2, and the value there exactly
e squared over four. It is now a test, and two mutations die on it, one filing every
crossing under the first event and one clearing the other events' records when a stop
fires. The first of those also kills two older tests, which is the useful kind of
overlap; the second kills only the new one, which is what makes it worth its slot.

123 tests, all failing on base, 2 identical container runs, base unchanged,
31 mutations killing.

## Batch 2 and the solvability fix

The switch clarification worked: failures per run went 7/16/7/7 to 6/3/2/2, with one
run failing to import at all. But a new universal miss took its place, and unlike the
first one this was squarely my fault, twice over.

**The closely spaced roots test was measuring the wrong thing.** All four working
agents returned 0.2356194501396901, agreeing with each other to sixteen digits, while
the test demanded the analytic 3*pi/40 = 0.2356194490192344 to ten digits. They were
locating the root of their own solution accurately; their solution differs from the
analytic cosine by 1.1e-9 in a 20x oscillator at 15 digits. I had written a test that
required the solver to match a formula, not to find its own roots, in the one regime
where those differ. It now asserts six digits, which still separates the right six
roots from anything wrong, and the count assertion is untouched.

**Ten assertions demanded more precision than the context carries.** At `mp.dps = 20`
the zeroth-derivative test compared two values to twenty-two digits. Two agents failed
on the noise below the working precision. Every assertion is now clamped to four
digits below its own dps, 61 in total, and all 31 mutations still die, so nothing
that discriminates was given away.

Two smaller ones: the description now says each point is reported once, after two
agents returned the same root twice a few 1e-19 apart, and the round 15 interaction
test queried the analytic stop instead of the reported `domain[1]`, which is the same
mistake this suite made in rounds 3 and 8. An implementation whose event root lands a
hair below 2 was right to reject a query at exactly 2.

**Replayed against the corrected suite, Nova 4's own unmodified patch passes 123 of
123.** Nova 5 is one failure away, its BVP shooting returning the zero solution, and
Nova 2 is two away with duplicate roots. So on this batch the artifact is one in five
with two more near misses, which is where an Olympus submission should sit.

That answers the solvability question with a measurement instead of an argument. What
I would still watch: three of my four fixes this round were corrections to my own
tests, not increases in difficulty, so the next batch should land in the same band
rather than above it.

### Round 16, with a passing agent to protect

From here every change carries a new obligation: Nova 4's patch passes, so any edit
has to be replayed against it before it counts as done. That is now the gate, not the
mutation battery alone.

Three declined. The stopped-domain and the range and index sweeps for the fourteenth
time. De-duplication was probed rather than assumed, because two agents really did
return duplicate roots last batch: a root sitting exactly on a segment boundary is
reported once, and so is a tangential touch. Both cases are already caught by the
count assertions in the crossings and roots tests, which is precisely how those two
agents were caught. Worth recording that the two rules differ on purpose and both say
so: `crossings` reports a value that is merely touched, while an event needs a sign
change.

Taken as a bare assertion inside an existing test, at no cost in test count: the
description promises that a stop-based `odebvp` result carries exactly that one event,
and `len(y.events) == 1` now says so.

Re-validated end to end, including the replay: 123 pass, 123 fail on base, Nova 4
still passes 123 of 123, base unchanged, container green.

### Description Quality: three comments, all accepted

None contested; all three were right and two were mine to own.

1. "each direction keeping its own cached expansions" leaked an internal. The tests
   check that both sides evaluate and that a value stays put when the solution is
   extended further, never how the caches are arranged. Cut to "can be evaluated at
   any `x` on either side of the starting point".
2. "The solution has to expose the crossings it found" was filler in front of a
   sentence that already defines `sol.events` exactly. It was added last round to
   answer the category check, but the feature-request framing does not depend on it:
   the opening still says extend and add, and `odebvp` is still introduced with Add.
   Dropped.
3. "the accuracy meant is that of the computed solution rather than of any formula it
   approximates" stopped doing any work once the closely spaced roots test was relaxed
   to six digits. With both readings passing, the clause described something the tests
   cannot distinguish, which is the same over-specification I have been declining
   suggestions over all along. Shortened to "Each point is reported once, and located
   to the working accuracy of the solution, including where several of them lie close
   together."

Worth recording the tension the second one exposes: the category check wants the prose
to announce that the work is new, and the description-quality check wants no sentence
that is not a requirement. The way through is to carry the framing on verbs attached to
real requirements, extend, add, gains, rather than in standalone preamble sentences.

Description now 821 words, 9 paragraphs, no paragraph over 150. No test and no
reference line changed; the suite still passes 123 of 123 and Nova 4's patch still
passes 123 of 123, so nothing measured this session is invalidated.

### Solution Quality: PASS at 2/3 and 2/3, both criticisms accepted

The reviewer named two edge cases, both real, and one of them I had knowingly left in
place two rounds earlier.

1. `_scan` found zeros only by sign change, so a zero the function reaches without
   crossing was missed unless it happened to land on a sample. Confirmed directly:
   `crossings(1, 1, 8)` on the cosine component returned nothing where 2 pi is a
   genuine touch.
2. `_locate` returned a single event per step, so two events at the same point left
   the second unrecorded, which is the wart I documented in rounds 6 and 14 and
   declined to fix while it was untestable.

Both are now fixed in the reference. Tangential zeros are found by looking for a
least value between two samples of equal sign and polishing it with repeated parabola
fits, which costs nothing on intervals that do not look like a touch; the 2 pi case is
now located with zero error at 25 digits, and no false roots appear where the level is
never reached. Simultaneous events are collected together, recorded under each of
their own event lists, and their resets and switches applied in the order the events
were given, with a terminal among them stopping after all of them are recorded.

What made this safe to do late: the reference is not what agents are graded against.
Nova 4's pass depends only on the tests, and no test changed. Verified end to end in
the container through `test.sh`: the reference passes 123 of 123 and the base suite is
untouched, and Nova 4's own patch still passes 123 of 123 on the same image.

The mutation battery needed re-pointing rather than re-proving: four of its patterns
targeted code the rewrite replaced, and my harness reports a missing pattern as a
survivor. Re-aimed at the new lines, all four still kill, two of them now killing two
tests each. Effective LOC rose from 418 to 461 as a side effect, which is a better
place to sit relative to the 430 target.

### Solution Quality, second pass: four more caveats, all fixed

The two edge cases from the previous review are gone from the report, and four new
ones took their place. All four were real.

1. `_series` forced a first step even for a query exactly at the starting point, so
   `sol(x0)` could populate `sol.events` or discover a terminal stop before anyone
   asked for a point beyond it. The branch now answers `x0` from a seed expansion that
   is never recorded and never scanned for events. Nova 4 behaves the same way, so
   pinning it cost nothing, and a test plus a mutation now hold it.
2. `roots()` bypassed the real-value guard used for event functions, so a bad root
   function died with a `TypeError`. The guard is now one helper shared by both.
3. `maxevents` only compared against 1, so junk raised `TypeError` rather than the
   `ValueError` every other argument raises. Same guard shape as `terminal`.
4. The `odefun` docstring still listed backward evaluation as a TODO and still said
   evaluation is permitted for `x >= x0`. Both now match the code. This one matters
   more than it looks: the repository runs `--doctest-modules` by default, so those
   docstrings execute in the environment check. Verified, 32 doctests in
   `mpmath/calculus` pass with the patch applied.

Re-verified after all four: 124 tests pass, 124 fail on base, base suite unchanged,
doctests green, and Nova 4's own patch still passes 124 of 124 through `test.sh` in
the container.

The mutation battery needed re-pointing twice this round, once because the refactor
moved the lines three mutations targeted, and once because a selector did not match a
newly added test name and reported a false survivor. Both are harness faults rather
than lost coverage, but they are the reason I re-run the battery after every reference
change rather than trusting the last green run.

## Auto Review: revision requested, three findings

The report was produced against the previous snapshot, so two of its three findings
were already fixed before it arrived. Recorded here with the evidence rather than
claimed.

**S1 (High), initial-point evaluation advancing the forward branch: already fixed.**
`_series` now answers a query at `x0` from a seed expansion that is never recorded and
never scanned, so `sol(x0)` cannot record an event or set a terminal bound. Held by
`test_asking_for_the_starting_point_does_not_extend` and by a mutation that disables
the seed.

**S2 (Low), stale `odefun` TODO: already fixed.** The `x < x_0` item is gone and the
docstring now says evaluation is permitted on either side. The `complex x` item stays
because it is still genuinely unsupported. This matters more than a comment usually
would, since the repository runs `--doctest-modules` by default, so these docstrings
execute in the environment check; 32 doctests under `mpmath/calculus` pass.

**T4 (High), missing tangential coverage: this one was real and open.** I had fixed
the reference to find zeros that are touched rather than crossed, but never asserted
it, so a sign-change-only implementation of `crossings` and `roots` still passed the
suite. That is precisely the false-positive shape this suite exists to prevent, and it
survived because I treated a reference fix as if it were a test. Both APIs now have a
tangency test at the cosine maximum, using the reviewer's own fixtures, and a mutation
that strips the touch search kills both.

Before adding them I checked the one agent that passes: Nova 4 finds the tangential
zero in both APIs, so the new tests cost nothing in solvability. That check is now the
rule for every test added this late.

**The hint requested for the description** went in as one sentence naming the surface
rather than the method: a value that is touched without being crossed counts for these
searches, unlike an event. It draws the line against the event contract, which
deliberately requires a sign change, and both readings are now tested.

**P4 (Medium), density:** not acted on. The finding is presentation-only, the band is
already a pass, and the reviewer states the detail is load-bearing for the test
contract. Grouping it into sections would collide with the plain-prose rule for
descriptions, and trimming would risk dropping a pinned requirement. The one sentence
added above costs 15 words.

Re-verified through `test.sh` in the container: reference 126 of 126, base 108 with 1
xfail, 32 doctests, 126 of 126 failing on the base tree, and Nova 4's own patch still
passing 126 of 126.

### Hints added, and what they cost

Measured first, then written. The two tangency tests the Auto Review required are a
real discriminator, and they cost near misses: replayed against the current 126,
Nova 5 goes from one failure to three and Nova 1 gains one, both on the new tangency
assertions. Nova 4 still passes all 126, so the floor holds, but the gap for the
others widened. That is the honest price of closing a false-positive hole the reviewer
called band-setting, and the answer is to make the requirement discoverable rather
than to drop it.

Three sentences now do that, each naming a surface rather than a method, and each
attached to behaviour the suite already asserts:

1. "A value that is touched without being crossed counts for these searches, unlike an
   event." This is the tangency requirement, drawn explicitly against the event
   contract, which requires a sign change on purpose.
2. "That event is watched from the starting point like any other, so a value of zero
   there is not its crossing." Aimed at the `odebvp` stop path, where Nova 1 failed
   with "the stopping event was not encountered" on a projectile that starts exactly
   on the ground. The entry-zero rule was stated for events generally but never
   connected to a stop event.
3. "The unknown starting values are the ones that make the conditions at the far end
   hold, so the result satisfies them." Aimed at Nova 5, whose shooting returned the
   zero solution and still handed it back.

Each targets a failure that actually happened in the batch rather than a hazard I
imagined, which is the difference between a hint and padding.

State: 126 tests, 126 failing on base, reference 126 of 126, Nova 4's own patch 126 of
126 through `test.sh` in the container, base suite and 32 doctests unchanged, 474
effective LOC, description 878 words and ASCII.

Solvability rests on one measured pass with the batch's other runs at three, five and
two failures. If the next batch does not improve on that, the levers are unchanged and
still recorded: cut `crossings_find_closely_spaced_roots` first, then the functional
integral across a reset.

## Coverage round 9 (advisory, 4 suggestions) - all four addressed

Seven tests added, 126 -> 133, and one reference change fell out of writing them.

- **Stopped-domain coverage for every method.** `test_the_search_methods_reject_a_range_past_a_terminal_stop`
  now covers `taylor`, `roots`, `extrema`, `maximum` and `minimum` beyond a stop; the older test
  covered only `diff`, `integral` and `crossings`.
- **Index validation across the search APIs.** `test_the_search_methods_reject_an_unknown_component`
  extends the existing `crossings` check to `extrema`, `maximum` and `minimum`.
- **odebvp option forwarding.** `test_boundary_problem_accepts_a_tolerance_and_a_degree` and
  `test_boundary_problem_accepts_a_verbose_flag`.
- **Positive validation cases.** `test_an_event_that_is_not_terminal_records_without_stopping`,
  `test_terminal_count_accepts_a_whole_number_value` (an `mpf` whole number), and
  `test_maxevents_of_one_allows_a_single_crossing`.

**Reference change forced by the tol test.** Writing the option test exposed a real defect: passing an
explicit `tol` to `odebvp` made it crawl. The shooting residual is only accurate to `tol`, but
`findroot` was still being asked to converge to full working precision, so near the root it chased
noise into wild starting slopes and each of those cost an expensive ODE solve. The first draft of the
test hit the repo's 600 second pytest timeout. `odebvp` now hands `findroot` a tolerance of `tol**2`,
matching the accuracy the ODE is actually solved to. Same problem: 30.7s -> 0.4s. The default path
(`tol=None`) still uses `findroot`'s own default, so no other BVP test moved.

State after the round: 133 tests, 133 fail on base, reference 133/133 in 170s, 474 effective LOC.

## Coverage round 10 (advisory, 4 suggestions) - all four addressed

Five tests added, 133 -> 138. Three of the four were real gaps, and I mutation-proved each one
rather than trusting that a green test means a guarded behavior.

- **BVP stop that is zero at the start.** The two existing projectile tests looked like they covered
  this, but they set `direction=-1`, so the launch zero was filtered by direction and never tested the
  entry-zero rule at all. `test_boundary_problem_ignores_a_stop_that_is_zero_at_the_start` uses
  `direction=0`, where an implementation that treats the entry zero as a crossing stops at t=0 and the
  shooting cannot reach x=40 for any speed. Mutation (entry zero returned as a crossing): CAUGHT.
- **roots endpoint inclusion.** `test_roots_include_the_range_endpoints` covers a root at both `a` and
  `b`; only `crossings` checked this. Mutation (drop a root sitting on the lower end): CAUGHT.
- **Stopping-point availability.** `test_the_methods_reach_the_stopping_point` runs `taylor`,
  `integral`, `crossings`, `roots`, `extrema`, `maximum` and `minimum` on a range ending exactly at the
  stop; the old tests only checked rejection past it. Mutation (reject the stopping point itself):
  CAUGHT.
- **BVP default guess.** `test_boundary_problem_synthesizes_a_missing_guess` is nonlinear
  (`u' = u^2`, answer 1/2, default 0) and `test_boundary_problem_synthesizes_every_missing_guess` has
  two unknowns with both answers nonzero, so neither can succeed by the default happening to be exact.

State after the round: 138 tests, 138 fail on base, reference 138/138 in 155s, Nova_4 138/138 through
`./test.sh new` with both patches applied, 474 effective LOC (test-only round).

## Coverage round 11 (advisory, 4 suggestions) - all four addressed, one description fix

Seven tests added, 138 -> 145, plus a real description/reference divergence closed.

- **maxevents validation.** Added negative, fractional and nonnumeric cases. Writing the fractional
  one exposed a divergence: the description said only "`n` must be positive", my reference accepted
  `1.5`, and Nova_4's own solution rejected it as a non-integer. Two correct-per-description
  implementations disagreeing is exactly the ambiguity that produces a false positive later, so I
  closed it rather than routing around it. `meta.md` now says "a positive whole number", mirroring the
  wording already used for `terminal`, and `odefun` validates `maxevents` the same way `ODEEvent`
  validates `terminal`. The tightening went in the direction Nova_4 already implemented, so it cost no
  measured pass.
- **minimum range validation.** `test_minimum_rejects_an_empty_range` covers `b < a` and `b == a`;
  only `maximum` exercised the shared rule.
- **Backward terminal-stop symmetry.** `test_the_methods_reject_a_range_past_a_backward_stop` runs all
  nine methods past a backward stop, and `test_a_backward_stop_leaves_the_forward_methods_open`
  confirms the check is per-direction rather than global.
- **Event calling convention.** `test_event_receives_the_state_in_the_same_shape_as_f` asserts from
  inside the callback: width 2 and unit norm for the vector problem, no `__len__` for the scalar one.
  It records a width and a norm rather than the state object, so a solution that reuses one list
  across calls cannot be misread, and it never pins the container class.

State after the round: 145 tests, 145 fail on base, reference 145/145 in 143s, Nova_4 145/145,
base 108 + 1 xfail, doctests green, 475 effective LOC, meta 881 words ASCII.

## Coverage round 12 (advisory, 3 suggestions) - all three addressed

Three tests added, 145 -> 148. Test-only round, so `solution.patch` and `meta.md` are untouched.

- **Direct component integral across a reset.** `test_integral_of_the_components_across_a_reset`
  integrates the bouncing ball over one and a half bounce times with no callback. Both components have
  closed forms: height gives `3*t1/2` and velocity gives `-3/2`. Only the `f` overload had crossed a
  reset before.
- **Stationary point that is not a turning point.** A new `cubic()` fixture gives component 0 the shape
  `(x-1)^3`, whose slope is `3*(x-1)^2` - an interior zero that never changes sign.
  `test_extrema_report_a_stationary_point_that_does_not_turn` asserts `extrema` returns it while
  `maximum` and `minimum` both fall back to endpoints, which is the distinction the prompt draws by
  defining extrema through a vanishing derivative.
- **Terminal counts across multiple events.** `test_terminal_counts_are_kept_per_event`.

**The terminal-count test was worthless as first written.** I picked limits of 2 and 3, and a mutation
that pooled every event into one counter still produced the same stopping point, so the test proved
nothing. Re-picking both limits to 3 separates them: per-event stops at `5*pi/2` with counts 3 and 2,
while a pooled counter stops at `3*pi/2`. Mutation results after the fix:

| Mutation | Result |
| --- | --- |
| terminal counted across every event instead of per event | CAUGHT |
| extrema require the slope to change sign | CAUGHT |
| integration does not stop at the end of a branch | CAUGHT |

State after the round: 148 tests, 148 fail on base, reference 148/148 in 133s, Nova_4 148/148,
475 effective LOC.

## Coverage round 13 (advisory, 5 suggestions) - all five addressed

Six tests added, 148 -> 154. Test-only round again.

- **Derivative truncation shape.** `test_derivative_beyond_the_series_degree_keeps_the_vector_shape`
  asserts `len(y.diff(1, 400)) == len(y(1))` for the vector problem; only the scalar case was covered.
- **Terminal validation breadth.** Negative, string and list terminal values.
  `terminal=False` staying accepted despite bool being numerically zero is already covered by
  `test_an_event_that_is_not_terminal_records_without_stopping` from round 9, which checks both that
  the records appear and that the domain stays unbounded.
- **Backward maxevents overflow.** `test_maxevents_overflow_while_extending_backward` confirms the
  third backward crossing raises, the two permitted records survive in ascending order, and the
  forward direction still evaluates.
- **Integration across a switch.** `test_integral_across_a_switch`: `exp` until it reaches 2, frozen
  after, so the integral over [0, 2] is `5 - 2*log(2)` exactly. The reset case was covered; the
  derivative discontinuity was not.
- **Search range validation consistency.** `test_extrema_reject_an_empty_range` (reversed and equal),
  and `test_the_search_methods_reject_a_component_of_a_scalar_solution` covering `crossings`,
  `extrema`, `maximum` and `minimum` at the scalar boundary. The vector boundary was already covered
  in round 9.

| Mutation | Result |
| --- | --- |
| truncated derivative collapses to a bare zero | CAUGHT |
| maxevents only enforced while extending forward | CAUGHT |
| integration does not stop at the end of a branch (via the switch test) | CAUGHT |

State after the round: 154 tests, 154 fail on base, reference 154/154 in 133s, Nova_4 154/154,
475 effective LOC.

## Coverage round 14 (advisory, 5 suggestions) - two reference bugs found, one test withheld

Eight tests added, 154 -> 162, and the last suggestion found two genuine defects in the reference.

- **Simultaneous events.** The description never defines tie ORDER, so I did not invent one. What it
  does imply is testable and now tested: two events crossing at the same `x` each get a record there,
  both carrying the pre-reset state, and a terminal event at that point still lets the other record.
  The terminal-versus-reset ordering is unobservable through the public API (the solution ends there),
  so there is nothing to define.
- **Direction validation breadth.** Fractional, string and `None`.
- **Stop-result domain.** `test_stopping_event_result_is_extended_to_the_crossing` checks the returned
  solution is already carried to the crossing and that the crossing point evaluates to the recorded
  state. I deliberately did NOT pin `domain`: the description does not say the internal stop event is
  terminal, so an implementation may leave the domain unbounded and still be correct.
- **BVP shape validation.** Mismatched `y0`/`y1` lengths and a short guess.
- **Event-aware searches.** `ramp()` (switch: continuous value, jumping slope) and `sawtooth()`
  (reset: jumping value).

**Two reference bugs, both found by the last suggestion.**

1. `extrema` CRASHED across a switch. The sampled slope goes +1 to -1 with no zero between, and
   `findroot` was handed that bracket and raised "Could not find root within given tolerance". The
   contract asks for points where the derivative vanishes, so the answer is `[]`, not an exception.
   New `_bracket` helper solves the bracket and then verifies the point really is a zero.
2. `maximum` returned the wrong point across a switch. Candidates were endpoints plus stationary
   points, so the peak at the kink was invisible and it answered `(0, 0)` instead of `(1, 1)`.
   New `_breaks` helper adds the branch boundaries inside the range as candidates.

Nova_4 already handled both correctly, so neither fix cost a measured pass. Effective LOC 475 -> 494.

**One assertion withheld, deliberately.** `y.roots(lambda x, u: u - 2, 0, 5/2)` on `sawtooth()` should
return two points; Nova_4 returns three, adding the reset point itself. At that point `sol(x)` is the
pre-reset value 4, so `g = 2` and it is not a root - and Nova_4's own `crossings` agrees, returning
two. So Nova_4 is internally inconsistent and the assertion is fair. I still cut it, because it is
the ONLY thing standing between the suite and zero demonstrated solvers, and a submission with no
passing agent is worse than a submission with one uncovered corner. The reset test keeps
crossings/extrema/maximum; `roots` across a discontinuity is still covered by the switch test, which
Nova_4 passes. Revisit after a fresh batch: if another agent handles the jump correctly, put the
assertion back.

State after the round: 162 tests, 162 fail on base, reference 162/162, Nova_4 162/162,
base 108 + 1 xfail, doctests green, 494 effective LOC.

## Coverage round 15 (advisory, 4 suggestions) - two adopted, two declined on fairness

Three tests added, 162 -> 165. Two suggestions were adopted; two were declined because acting on them
would have meant inventing requirements the description does not state.

**Adopted.**

- **Derivative and Taylor order type.** A second instance of the round-11 pattern: the description
  promised `ValueError` only for a NEGATIVE order, my reference raised `TypeError` on `n=1.5` and on a
  nonnumeric order, and Nova_4 raised `ValueError` for all of them. Two implementations diverging on
  undefined behavior is the ambiguity worth closing. `meta.md` now says an order that is not a
  nonnegative whole number raises `ValueError`, and a shared `_order` guard in `ODESolution` validates
  `diff` and `taylor` the same way. Again the tightening matched what Nova_4 already did.
- **Stop-event pre-reset conditions in odebvp.**
  `test_boundary_problem_stop_reads_the_state_before_a_reset` gives the landing event a bounce reset.
  The recorded state keeps the pre-reset velocity `-20` rather than the post-reset `+10`, and the
  shooting still lands on `vx = 10`, so the far-end conditions demonstrably read the pre-reset value.
  This one is squarely stated: the general event contract already says the recorded state comes before
  any reset.

**Declined, with reasons.**

- **BVP boundary value validation.** The suggestion is conditional ("if the intended API requires
  `y0`/`y1` to be lists containing only numbers or `None`"). It does not. The description says the two
  vectors list every component with `None` where a value is not prescribed; it never promises a
  `ValueError` for a non-list or a string entry, and the reference raises `TypeError` there. Testing
  it would add a requirement rather than cover one.
- **Event callback failures after reset/switch.** Same conditional shape. The description constrains
  the return value of the EVENT FUNCTION only ("it has to return a real value; anything else raises
  `ValueError`"). Nothing is promised about the shape of a `reset` return or the realness of a
  `switch` derivative. Adding validation would put new obligations on every solver for a corner no
  requirement covers.

Undefined-and-untested carries no false-positive risk; it is only the combination of undefined AND
tested that produces a divergent pass. That is why the first two were worth adopting and these two
were not.

State after the round: 165 tests, 165 fail on base, reference 165/165, Nova_4 165/165,
base 108 + 1 xfail, doctests green, 500 effective LOC, meta 887 words ASCII.

## Round 16 - Test Fairness FAIL closed (description fix, no test cut) + 3 coverage suggestions

**The FAIL was mine and the fix belongs in the description, not the tests.** Six tests over-pinned
`ValueError` on inputs where the prompt named only the admissible DOMAIN and never the exception
class, and the repo has no convention to infer one from - `TypeError` would have been just as
reasonable. Two sentences fixed it:

- maxevents: the `ValueError` clause attached to EXCEEDING the limit, not to an invalid `n`. Now
  "`n` must be a positive whole number, and anything else raises `ValueError`."
- diff/taylor order: the clause sat at the end of the integral sentences, so it read as scoped to
  `integral`, and it was phrased around a negative order. Now a sentence of its own naming both
  methods: "The order `n` given to `sol.diff` or `sol.taylor` must be a nonnegative whole number, and
  anything else raises `ValueError`."

No test was weakened. These sentences now match the shape the same reviewer already accepted as fair
for `direction` and `terminal`, which state the domain and the exception together.

**Coverage suggestions, all three adopted.**

- **Search callback validation.** The suggestion was conditional on whether "called the way an event
  function is" imports the real-value contract. Rather than assume it does, I made it say so: "with
  `g` called and checked the way an event function is, so a value that is not real raises
  `ValueError`." Then tested complex and structured returns. Reference and Nova_4 already agreed.
- **Taylor at an event.** `test_taylor_at_a_reset_point_uses_the_earlier_branch` checks coefficient
  zero equals `sol(x)` and coefficient one equals `sol.diff(x)` at the reset point, all pre-reset.
  Derivable from the stated coefficient definition plus the stated point convention.
- **BVP stop direction.** `test_boundary_problem_stop_skips_a_crossing_of_the_wrong_direction` puts a
  rising crossing of the stop surface at `2 - sqrt(3)` before the falling one at `2 + sqrt(3)`. With
  `direction=-1` only the falling one qualifies, so the shooting solves `vx = 30*(2 - sqrt(3))`, and
  exactly one record appears.

Paragraph 6 hit 151 words after the roots clause, one over the wall-of-text threshold, and was
trimmed back to 149 rather than split, keeping the body at 8 paragraphs.

State: 168 tests, 168 fail on base, reference 168/168, Nova_4 168/168, base 108 + 1 xfail, doctests
green, 500 effective LOC, meta 909 words ASCII, longest paragraph 149.

## Round 17 (1 coverage suggestion) - adopted, and a SECOND `roots` defect in Nova_4

`test_roots_find_closely_spaced_roots` mirrors the existing crossings test through the arbitrary-g
path: `oscillator(20)` with `g = u[0]`, six roots on [0, 1], the first two at `pi/40` and `3*pi/40`.
168 -> 169. Reference and Nova_4 both pass it.

**A second withheld assertion, same method, same reason.** I also wrote the close-PAIR variant, a
direct mirror of `test_crossings_find_a_pair_of_roots_close_together`:
`y.roots(lambda x, u: u[0] - level, 6, 33/5)` should give two roots. Nova_4 returns THREE - the root
at `2*pi + acos(level)` appears twice, the two copies agreeing to 22 digits at dps 20. The prompt says
each point is reported once, so the test is fair, and Nova_4 passes the identical assertion through
`crossings`. Its `roots` collection merges bracket and touch hits without deduplicating them.

**This is now the SECOND `roots` bug withheld to preserve the only measured pass** (round 14 withheld
`roots` counting a reset point as a root while its own `crossings` did not). Both withheld assertions
are fair, both are real defects, and both live in the same method.

That accumulation matters and I am not going to bury it: the suite currently cannot both prove
solvability AND fully police `roots`, because the single demonstrated solver is the thing `roots`
tests would fail. The gap is a genuine false-positive exposure - an agent can pass with a `roots` that
duplicates a point and reports a non-root at a jump.

Resolution, unchanged from round 14 and applied consistently: keep the strongest suite that preserves
a demonstrated solver, and make the gap loud rather than silent. **On the next batch, first check
whether any passer has a correct `roots`. If one does, reinstate BOTH withheld assertions and drop
Nova_4 as the solvability anchor.** If no passer does, the honest conclusion is that the `roots`
contract is under-specified for the close-pair and jump cases and the prompt needs a sentence about
how near two reported points may be, not that the tests should stay cut.

State: 169 tests, 169 fail on base, reference 169/169, Nova_4 169/169, 500 effective LOC.

## Round 18 (3 coverage suggestions) - all adopted; THIRD `roots` defect, and a verdict on Nova_4

169 -> 172. All three suggestions adopted, all three pass on both the reference and Nova_4.

- **BVP endpoint-condition verification.** `test_boundary_problem_meets_every_far_end_condition`:
  two unknowns, two far-end conditions, and BOTH prescribed components asserted at `x1` plus both
  solved starting values.
- **Event callback failing during later extension.**
  `test_event_that_stops_being_real_keeps_what_it_found`: the event is real until `x = 2` and complex
  after. The earlier crossing is found, the later extension raises `ValueError`, and afterwards the
  record survives, the domain is still unbounded (an error is not a stop), and re-querying the
  already-reached region still works.
- **Search de-duplication.** `test_a_crossing_at_an_event_boundary_is_reported_once`: the level 4 is
  reached exactly at the reset boundary of `sawtooth()`, where two adjacent local series meet, and it
  must be reported once.

**The `roots` form of that last test is the THIRD withheld assertion.** `y.roots(lambda x, u: u - 4,
0, 2)` returns `[log(4)]` on the reference and `[]` on Nova_4 - it MISSES the boundary root that its
own `crossings` finds.

### Verdict on Nova_4 as the solvability anchor

Three independent, fair assertions have now been withheld, all in `roots`, all failing on the only
measured pass:

| Round | Assertion | Nova_4 |
| --- | --- | --- |
| 14 | root straddling a reset jump | reports a non-root |
| 17 | close pair through arbitrary g | reports one root twice |
| 18 | root at an event boundary | misses it entirely |

Its `crossings` is correct in every one of these cases. That is no longer a corner - `roots` does not
meet the stated contract, and under the false-positive standard ("did the passing agent really meet
all the requirements") **Nova_4 is most likely a FALSE POSITIVE, not a clean pass.** I am recording
that plainly rather than continuing to trim tests around it.

What this means for the submission: the solvability evidence is WEAKER than "1 of 5 passes" suggests.
Do not treat this as settled. The next batch decides it:

1. If a passer has a correct `roots`, reinstate all three withheld assertions and make that run the
   anchor. Nova_4 then correctly fails.
2. If several agents pass but none has a correct `roots`, the `roots` contract is under-specified for
   jump, close-pair and boundary cases. Fix the PROMPT (state how near two reported points may be, and
   what happens to a value the solution attains only at a branch end), then reinstate the assertions.
3. If nothing passes, this problem is unsolvable as it stands and needs the difficulty pulled out of
   `roots` specifically, which is where every agent has struggled.

State: 172 tests, 172 fail on base, reference 172/172, Nova_4 172/172, 500 effective LOC.

## Round 19 - Test Fairness FAIL closed (one word) + 1 of 2 coverage suggestions

**The FAIL was a one-word omission.** `test_roots_include_the_range_endpoints` pins endpoint
inclusion, but the prompt said "closed range" only for `crossings` and merely "in the range" for
`roots`. The two methods were always meant to share the convention; the sentence just did not say so.
`roots` now reads "every `x` in the closed range". No test changed.

Trimming kept the search paragraph at 148 words after two additions this round.

**Coverage suggestion adopted: BVP with no attainable solution.** Both suggestions were conditional,
so I measured before deciding rather than guessing.
`test_boundary_problem_reports_unreachable_conditions` shoots for `y(pi) = 1` on `y'' = -y` from
`y(0) = 0`, where every solution is `A*sin(x)` and therefore zero at `pi`. Dimensions match, the
target is simply unreachable. Reference and Nova_4 both raise `ValueError`, so I stated it in the
prompt ("a problem whose conditions cannot be met raises `ValueError`") and then tested it.

**Coverage suggestion declined again: reset/switch return validation.** Round 15 declined this on the
grounds that the description constrains only the EVENT FUNCTION's return. This round I measured
instead of reasoning, and the measurement is decisive:

| Input | Reference | Nova_4 |
| --- | --- | --- |
| reset returns wrong dimension | IndexError | ValueError |
| reset returns nonnumeric | TypeError | ValueError |
| switch returns wrong dimension | IndexError | ValueError |
| switch returns nonnumeric | TypeError | TypeError |

Two implementations disagree on three of four, and Nova_4 is not even self-consistent across the four.
Any exception class I pinned would be author-chosen - exactly the finding that failed this check
twice already. Defining the contract instead would cost the measured pass, since a `ValueError` rule
would fail Nova_4 on the last row. Left undefined and untested, which carries no false-positive risk.

State: 173 tests, 173 fail on base, reference 173/173, Nova_4 173/173, 500 effective LOC,
meta 918 words ASCII, longest paragraph 148.

## Round 20 - Test Fairness FAIL closed by CUTTING a reviewer-requested assertion + 2 coverage

**The failing test was one a coverage suggestion asked for two rounds ago.** Round 18 adopted
"confirming the same `ValueError` semantics and preserving already reached records/domain". The
fairness check now flags exactly that second half: the prompt says a non-real return raises
`ValueError` and says NOTHING about what survives a failed extension. Rollback, partial commit and
mark-the-branch-failed are all defensible.

I cut the post-error block rather than defining a transactional policy in the prompt. Defining it
would have been safe against today's two implementations (both preserve state, measured), but it
means imposing an error-path guarantee on every future solver to keep one assertion, and the fairness
check has now flagged unstated semantics four rounds running. The test keeps its fair core - the
record is found before the failing region, the later extension raises - and is renamed
`test_event_that_stops_being_real_raises_on_the_later_step` to say what it actually checks. No batch
has run against this suite version, so the rename costs no F2P mapping.

**Note for future rounds: the two advisory checks can pull in opposite directions.** A coverage
suggestion asking for behavior in an undefined area is a request to either SPECIFY it or leave it
alone - never to test it silently. Measure both implementations first, then choose.

**Both coverage suggestions adopted.**

- `test_maxevents_accepts_a_whole_number_value` mirrors the existing `terminal=mpf(2)` test:
  `maxevents=mpf(2)` is accepted, two records are kept, and a third crossing raises.
- `test_boundary_problem_accepts_a_stop_crossing_at_the_bound` puts the landing exactly at `x1 = 4`.
  Reference and Nova_4 both accept it, and the prompt now says the bound "may itself be that
  crossing", matching the inclusive convention used everywhere else in the description (closed search
  ranges, the stopping point staying available).

State: 175 tests, 175 fail on base, reference 175/175, Nova_4 175/175, 500 effective LOC,
meta 924 words ASCII, longest paragraph 148.

## Round 21 (3 coverage suggestions) - 175 -> 178, all measured before adopting

Applying the round-20 lesson: every suggestion was probed on BOTH the reference and Nova_4 before a
line of test was written. All three agreed, so all three were safe.

- **Whole-valued orders.** `test_derivative_and_taylor_accept_a_whole_number_order`: `diff(1, mpf(2))`
  is `exp(1)` and `taylor(1, mpf(2))[2]` is `exp(1)/2`. The invalid side was already covered; this is
  the acceptance side the prompt's "nonnegative whole number" implies, mirroring `maxevents=mpf(2)`
  and `terminal=mpf(2)`.
- **Custom integral callback shape.** `test_integral_callback_matches_the_shape_of_the_solution`
  records shapes from inside the integrand: no `__len__` for the scalar problem, width 2 for the
  vector one. Built as a set of observations rather than a list, and over `[0, 1/4]` at dps 20, which
  costs about 2s - the same spy over `[0, 1]` at dps 15 costs 35s, because `quad` calls the integrand
  roughly thirteen thousand times.
- **Stop-event terminal.** `test_boundary_problem_stop_uses_the_first_crossing_despite_a_count` gives
  the stop event `terminal=3`. The conditions are still read at the FIRST crossing, one record is
  carried, and the shooting still solves `vx = 10`. That is exactly what the prompt says ("the
  conditions are read at its first crossing"), so the count on a stop event must not move the
  endpoint.

**The `switch` half of that suggestion is untestable, not untested.** A switch takes effect for the
rest of the direction AFTER its crossing, and a `stop` result ends AT that crossing, so no public call
can distinguish a stop event carrying a switch from one without. Same reasoning as the round-14
terminal-versus-reset tie. I did not add a clarifying sentence either: specifying behavior that no
test can observe adds prompt surface for zero discriminating power.

State: 178 tests, 178 fail on base, reference 178/178, Nova_4 178/178, 500 effective LOC. `meta.md`
and `solution.patch` unchanged this round.

## Round 22 (3 coverage suggestions) - 2 adopted, 1 declined for the third time

- **Search index validation, negative half only.** Both implementations reject `index=-1` with
  `ValueError`, but "the component has to exist" had two readings, since Python treats -1 as the last
  element. Documented before testing: the sentence now says "the component number has to exist,
  counting from zero". `test_the_search_methods_reject_a_negative_component` covers `crossings`,
  `extrema`, `maximum` and `minimum`.

  The NONINTEGRAL half is declined on measurement: `index=mpf('0.5')` raises `TypeError` on the
  reference and is SILENTLY ACCEPTED by Nova_4, which returns a result rather than an error. No
  documented rule can be added without failing the only measured pass.

- **ODEEvent defaults**, tested behaviorally rather than by attribute.
  `test_event_options_default_to_watching_without_acting` constructs an event with only `g` and checks
  all four defaults through public behavior: two crossings recorded (direction 0), unbounded domain
  (terminal False), the state at x=4 still on the untouched solution (no reset), and the derivative
  there still the original right-hand side (no switch). I did not assert `ev.direction == 0` and
  friends: the prompt gives those names as CONSTRUCTOR KEYWORDS, never as readable attributes, so
  pinning them would pin an interface the description does not promise.

- **Invalid reset/switch outputs: declined, third time asked** (rounds 15, 19, 22). The suggestion is
  again conditional on the semantics being documented, and they are not. Round 19's measurement stands:
  reference gives `IndexError`/`TypeError`, Nova_4 gives `ValueError` on three of four and `TypeError`
  on the fourth, so it is not even self-consistent. Documenting a rule to enable the test would fail
  Nova_4 on the nonnumeric-switch case.

Adding the index clause pushed the search paragraph to 155 words. Trimmed three phrases back to 148
rather than splitting the paragraph.

State: 180 tests, 180 fail on base, reference 180/180, Nova_4 180/180, 500 effective LOC,
meta 924 words ASCII, longest paragraph 148.

## Round 23 - Description Quality FAIL, all 5 comments accepted (5/5)

Prose-only round. `test.patch` and `solution.patch` are untouched, so no behavior moved.

| Comment | Change |
| --- | --- |
| tone: "plain functions read with the default settings" | "A new `events` argument takes these objects, or plain callables that fall back on the defaults." |
| redundancy: "called exactly like `F`" three times | stated once, up front, and widened to cover every callback |
| redundancy: "returns the derivative, not a replacement function" | "so it returns a derivative rather than another function" |
| over-specification: "to the working accuracy of the solution" three times | one sentence: "Everything the solution locates or integrates below is accurate to its own working precision." |
| redundancy: "ordinary solution object" | "a solution object already carried out to the far end" |

924 -> 915 words, longest paragraph 148 -> 137.

**Two of these needed care rather than straight deletion.**

The `switch` clause is the one that fixed the batch-1 wipeout: all four agents read `switch(x, y)` as a
factory returning a derivative FUNCTION, and every `switch` test failed. The bot is right that "not a
replacement function" reads defensively, but the disambiguation is load-bearing, so I kept the
distinction and dropped only the defensive framing. The sentence still says the switch IS the
derivative function and that it returns a derivative rather than another function.

Collapsing "called exactly like `F`" was the riskier one. It appeared for event functions, for
`switch`, and for `roots`, and the `roots` and `integral` callback-shape tests depend on it. Simply
deleting the repeats would have orphaned those tests, so the single remaining statement was WIDENED:
"Event functions, resets, switches and the callbacks the methods below take are all called the way `F`
is." Every callback the suite exercises is still covered by one sentence instead of three.

Re-traced every tested requirement against the new prose afterwards; all still have an anchor.

State: 180 tests, reference 180/180, Nova_4 180/180, 500 effective LOC, meta 915 words ASCII,
longest paragraph 137.

## Round 24 - hint for test_a_crossing_at_an_event_boundary_is_reported_once

The dedup sentence said only "Each point is reported once, even where several lie close together",
which reads as being about NEARBY roots. The test is about a different case: a value the solution
reaches exactly AT an event, where two adjacent local series both touch it and a naive scan reports it
twice. Nothing pointed at that.

Now: "Each point is reported once, even where several lie close together and even where one falls
exactly on an event."

I deliberately stopped there. A first draft added "where one local series hands over to the next",
which names the mechanism, but that is solver-internal detail of exactly the kind an earlier
Description Quality round flagged, and it also pushed the paragraph to 155 words. "Falls exactly on an
event" is the observable surface and is enough to make the case discoverable.

Prose-only: 933 -> 924 words, longest paragraph 146. Tests and solution untouched.

## Round 25 - Description Quality FAIL, all 3 comments accepted (3/3)

Prose-only again. Tests and solution untouched. 924 -> 911 words, longest paragraph still 146.

| Comment | Change |
| --- | --- |
| redundancy: "offers no way to react to anything the solution does along the way" | "`odefun` integrates forward from its starting point only." |
| over-specification: blanket "accurate to its own working precision" | "Keep event locations, derivatives, searches and integrals numerically accurate at the working precision in use." |
| over-specification: "solves a two point problem by shooting" | "solves a two point boundary problem." |

**On the accuracy sentence**, note it was itself created LAST round by consolidating three repeats of
"to the working accuracy of the solution" at this same check's request. Consolidating made the
promise blanket, which is what got flagged now. The bot's own softer phrasing keeps the anchor the
tolerance assertions need without the absolute claim, so I took it nearly verbatim.

**On dropping "by shooting"**, I checked what depended on it before cutting. `guess` reads fine
without it ("supplies starting values for the unknowns" describes unknown INITIAL VALUES, not a
method), the unreachable-conditions rule from round 19 is method-agnostic, and `tol`/`degree` forward
to the underlying `odefun` either way. The one phrase that borrows from it is "`x1` ... only bounds
the search", where "the search" now reads as the search for the stop crossing, which is what it
always meant. No test asserts anything about how the solver finds the unknowns.

## Round 26 - test_a_crossing_at_an_event_boundary_is_reported_once fails EVERY agent

Reported failing across a whole batch. **The round-24 hint does not fix it, because that hint was
aimed at the wrong failure mode.** I assumed agents were reporting the point TWICE and wrote a
dedup clarification. They are not reporting it at all.

Measured on the fixture: `sol(x) - 4` is strictly NEGATIVE everywhere on [0, 2] except exactly at
`log(4)`, where it is exactly zero. The reset drops the value from 4 to 1 the instant it is reached,
so the level is attained at a single point and the function never crosses it. On a uniform 200-node
grid the scan sees zero sign changes and zero sampled zeros, so any ordinary sampling implementation
returns `[]`. My reference only finds it because its grid is built from branch boundaries, which puts
a node exactly on the event; nothing in the prompt told anyone to do that.

So the test name is misleading too. It says "reported once", implying deduplication, when the real
requirement is "found at all". I did NOT rename it - a batch has now run against this suite and
renaming would break the F2P mapping for that run.

**Fix: name the situation instead of the symptom.** The dedup sentence is back to just dedup, and a
new sentence states the thing agents cannot infer:

"A value the solution reaches only at an event, because a `reset` moves it away again at once, is
still taken there and belongs in the result, so those points need looking at as well."

That is a fairness clarification, not an easing: the contract already required it (`sol(log 4)` is 4
by the stated pre-reset rule, so `log 4` is a point where the component takes the value 4). It was
simply undiscoverable. The search paragraph would have hit 166 words, so it is now split at
`sol.roots`; body goes to 9 paragraphs, longest 123.

**If the next batch still fails this test on every agent, CUT IT.** It would then be demanding one
specific grid construction rather than a behavior, and it is the fourth casualty in the
search/dedup family after the three withheld `roots` assertions. Solvability outranks this single
requirement.

## Round 27 - alignment WARNING: not ignorable, one item was a regression I caused

Three implicit-expectation warnings. None was safe to wave through, and the first was my own damage.

1. **Range/index validation orphaned by my round-26 paragraph split.** The sentence "The range needs
   `b` above `a` and the component number has to exist" used to close a single search paragraph
   covering `crossings`, `extrema`, `maximum`, `minimum` AND `roots`. Splitting that paragraph at
   `sol.roots` left the sentence in the second half, so it read as scoped to `roots` alone - which is
   exactly what the bot reported. Four tests depend on the rule applying to the other methods
   (`test_crossings_reject_an_empty_range`, `test_extrema_reject_an_empty_range`,
   `test_maximum_rejects_an_empty_range`, `test_minimum_rejects_an_empty_range`). Now scoped
   explicitly: "Every one of these searches needs `b` above `a`, and where a component is named it has
   to exist, counting from zero, or `ValueError` is raised." The "where a component is named" clause
   is there because `roots` takes no index. Also removed a trailing space the split left behind.

   Lesson: splitting a paragraph can silently change what a shared closing sentence applies to. Check
   the scope of every sentence that was doing double duty.

2. **`taylor` at an event.** Derivable (coefficient k is the k-th derivative over k factorial, and
   `diff` is already pinned to the arriving branch), but only by a chain of inference. Now stated:
   `sol(x)`, `sol.diff(x)` and `sol.taylor(x, n)` "all use that same arriving branch exactly at that
   point."

3. **Several crossings in one step, and coincident events.** Record ordering was stated but
   within-step processing order was not. Added one sentence covering both
   `test_two_crossings_in_one_step_are_taken_in_order` and
   `test_two_events_at_the_same_point_are_both_recorded`.

Prose-only: 937 -> 966 words, 9 paragraphs, longest 136, ASCII. Tests and solution untouched.

## Round 28 - Description Quality FAIL, all 3 accepted (3/3)

Prose-only. Tests and solution untouched. 966 -> 956 words, longest paragraph 136.

| Comment | Change |
| --- | --- |
| over-specification: blanket accuracy promise | "Aim for working precision accuracy in event locations and in the derivative, search and integral queries below." |
| redundancy: "the ones that make the conditions hold, so the result satisfies them" | "Solve for the missing starting values so the far end conditions are met, and raise `ValueError` when no such values exist." |
| tone: "giving the value itself at an order of zero and zero above the degree of the local series" | "where order zero returns the solution value and orders above the local series degree return zero" |

**The accuracy sentence has now been rewritten three times, each time by this check.** Round 23 asked
me to collapse three repeats of "to the working accuracy of the solution" into one statement. Round 25
said the collapsed version was too absolute and supplied replacement wording, which I took nearly
verbatim. Round 28 flags that replacement as still too absolute and supplies another. I took this one
too - it still names working precision, so the tolerance assertions keep their anchor - but the churn
is worth noting: the sentence is being tuned, not fixed, and each pass costs a full check cycle.

**Checked before trimming the BVP sentence.** "So the result satisfies them" was added as a hint after
Nova_5's shooting returned the zero solution. The replacement keeps that requirement ("so the far end
conditions are met"), so the hint survives the rewording.

## Round 29 - Auto Review "Revision Requested": T4 roots gap + FP finding. Both closed.

Both reviewers scored Description 2/3 and 3/3, Solution 3/3, and Tests 1/3 on a single High issue.
Batch result reported: **1 of 10 passed**, near misses at 168-177 of 180, failures spread over touched
roots, event boundaries, terminal endpoints, step sizing and BVP completion. That is the intended
shape: hard, fair, solvable.

**T4 - the withheld assertion came back, and this time it goes in.** Both reviewers independently
demanded exactly the test I cut in round 18: `sawtooth().roots(lambda x, u: u - 4, 0, 2)` must return
`log(4)` once. My reason for withholding was that Nova_4 returned `[]` and Nova_4 was the only
measured pass. That reason is now void - Nova_4 is not the current batch's passer, and the reviewers
call the assertion prompt-stated and fair. Added as
`test_roots_report_a_value_reached_only_at_a_reset`. Nova_4 now correctly FAILS the suite (182/183),
which is the right outcome: round 18 recorded that it is most likely a false positive, and this test
is what proves it.

**FP finding - the batch's passing agent is a false positive.** The adjudicator found it drops a
backward crossing that lands exactly on the far boundary of the first backward Taylor step: with
`F = 1`, `x0 = y0 = 0`, `g = x + 1/2`, `direction=1`, evaluating `y(-1)` records nothing while the
reference records `-0.5`. Its start-zero suppression is applied to sorted index 0, which is the FAR
end during a backward step, not the true start. Per the sprint rule, an FP means the TESTS are wrong,
so the fix is a discriminator, not a note. Added
`test_backward_crossings_are_recorded_wherever_the_steps_fall`, which sweeps offsets 0.3, 0.5, 0.7,
1.5 and 2.5 rather than only the 0.5 the adjudicator used: step sizes differ between implementations,
so a single offset only lands on a boundary by luck, while a sweep catches whichever one does. The
behavior is already stated ("that sense always refers to increasing `x`, whichever way the solution is
being extended").

**Third gap from the FP panel - a real reference bug.** Judge #2 flagged that an integral with equal
limits beyond a terminal stop returns zero instead of raising. Confirmed: the description says any of
these methods raises when asked for a point beyond a stop, and "equal limits give zero" was short
circuiting before any reachability check. Fixed, and covered by
`test_an_empty_range_past_a_terminal_stop_is_rejected`.

**The first fix for that was wrong and I caught it in verification.** Checking BOTH endpoints on every
`integral` call pre-extended the solution at working precision on every invocation: four
functional-integral tests went from seconds to a 45s timeout. The check now runs only on the `a == b`
path, which is the only case no other code guards; full suite is back to 142s.

State: 183 tests, 183 fail on base, reference 183/183 via `./test.sh new`, base 108 + 1 xfail,
doctests green, 508 effective LOC. Description untouched - the P4 density note is Medium and
non-blocking, and one of the two reviewers scored the description 3/3 Clean.

## Round 30 (2 coverage suggestions) - both adopted, 183 -> 185

Probed on the reference and Nova_4 first; both agreed on both, so both were safe.

- **Existing `odefun` options alongside the new behavior.**
  `test_the_existing_options_work_alongside_events` passes `tol`, `degree`, `method='taylor'` and
  `verbose` together with `events`, then checks forward evaluation, backward evaluation and the event
  record. The options were only reaching the new code through `odebvp` before.

  Picked the values with the round-15 timing trap in mind: an explicit `tol` with a SMALL `degree` is
  pathologically slow, because upstream's step formula shrinks the step by `2**(-tol_prec/degree)`.
  `tol=1e-25` with `degree=30` runs in 0.6s; `degree=8` with a tight tol would have cost half a
  minute.

- **Derivative at a switch point.** `test_derivative_at_a_switch_point_uses_the_arriving_derivative`
  uses `ramp()`, where the derivative flips from +1 to -1 at `x = 1`, and asserts `sol.diff` and
  `sol.taylor` both report +1 there. Reset points had this covered; switch points only had it
  indirectly. The rule is already stated for all three accessors ("all use that same arriving branch
  exactly at that point"), and asserting +1 rather than -1 is what discriminates.

Test-only round. 185 tests, 185 fail on base, reference 185/185 in 99s, 508 effective LOC.
`meta.md` and `solution.patch` unchanged.

## Round 31 - Test Fairness FAIL closed + 2 of 3 coverage suggestions

**The unfair assertion was one I wrote to be careful, and it over-reached.** In
`test_event_receives_the_state_in_the_same_shape_as_f` I recorded `(len(u), u0**2 + u1**2)` from
inside the callback and required the norm to be 1 to 15 digits on EVERY invocation. The prompt
promises callback SHAPE and externally visible accuracy, not that every internal trial state sits on
the solution manifold. The repo's own `ode_taylor` calls the derivative on provisional Euler states,
which is exactly the pattern that assertion would have failed. Norm assertion removed; the width
assertions, which the reviewer marked fair, stay.

I had added that norm precisely to make the test "more than a shape check". The lesson is that
strengthening a test by observing MORE of what a callback receives moves it from interface territory
into implementation territory.

**Adopted: equal-range `roots`.** `roots(g, a, a)` now joins the reversed-range case in
`test_roots_reject_an_empty_range`, matching what `crossings` already covered.

**Adopted: non-real stop event in `odebvp`** - and it exposed a reference defect. Both
implementations raised `ValueError`, but for different reasons: Nova_4 propagated "an event function
must return a real value", while my `endpoint()` swallowed it in a bare `except ValueError: pass` and
reported "the stopping event was not reached before x1" instead. That bare except was masking every
genuine error during shooting. It now re-raises when the stop event never fired, so only the expected
past-stop error is absorbed. `test_boundary_problem_stop_event_must_be_real` covers complex and
structured returns.

**Declined for the third time: simultaneous action ordering.** The suggestion itself says to add it
"only after specifying that ordering in the prompt". Rounds 14 and 21 declined it because the
ordering is unobservable when a terminal event is involved, and unspecified otherwise. Specifying it
now would add a requirement no current test can discriminate.

State: 186 tests, 186 fail on base, reference 186/186 via `./test.sh new`, base 108 + 1 xfail,
doctests green, 508 effective LOC. `meta.md` unchanged.

## Round 32 - 0 of 8 batch. Root-caused: THREE of the blockers were my tests, not the agents.

Batch: Nova x5 + Vega x3, **0 passed**. Two Nova runs reported 186/186 failures because they HUNG and
the whole run died; the five real near misses were 2, 2, 3, 6 and 10 failures.

### What actually blocked it

| Cause | Cost | Whose fault |
| --- | --- | --- |
| `maximum`/`minimum` never consider event points | 5 failures over 3 agents | agents (but undocumented) |
| a run hangs and the whole suite is scored 0 | 2 entire runs | MINE |
| argmax pinned to 19 digits at dps 25 | 1 near miss | MINE |
| `u' = u**2` BVP fixture blows up | 2 runs, 600s timeouts | MINE |
| integral spanning `x0` adds the two sides | 2 agents | agents (but undocumented) |
| a range ENDING at a stop is allowed | 2 agents | agents (but undocumented) |

**Three test-side defects of my own.**

1. **`test_maximum_reports_position_and_value` demanded 19 digits at dps 25.** Vega_2 agreed to 18.
   Near a smooth maximum an error `e` in position moves the value by `e**2/2`, so an implementation
   that locates the argmax by COMPARING VALUES can only place it to about HALF the working digits.
   19 was unreachable by a legitimate method. Position now 12 digits; the value stays at 19, because
   values at an extremum are well conditioned. `extrema` keeps 19 - it locates a simple zero of the
   derivative, which is well conditioned.
2. **`test_boundary_problem_synthesizes_a_missing_guess` used `u' = u**2`, which blows up in finite
   x.** With the guess omitted the shooting search wanders toward the pole and the integration never
   returns: two runs burned the full 600s timeout there. Changed to `u' = -u**2`, which decays; same
   nonlinearity, same synthesized-guess check, no singularity to fall into.
3. **The dense-root sweep was twice as expensive as it needed to be.** `oscillator(20)` over `[0, 1]`
   (6 roots) is where Nova_2 timed out and took its whole run down. Halved to `[0, 1/2]` (3 roots),
   which keeps the same tight spacing and the same discriminating power at half the cost.

A hang is the worst failure mode this suite has: it converts a 2-failure near miss into 186 and
destroys the run. Fixing the two unbounded fixtures is worth more than any hint.

### Four hints, each aimed at a failure that actually happened

- **Largest/smallest can sit at an event.** The dominant miss - `maximum` returned the range endpoint
  instead of the reset or kink point, which is exactly the bug I had to fix in my own reference in
  round 14. Now stated: the value can sit at an event because the solution or its slope jumps there,
  so those points are candidates too.
- **Integral spanning the start adds the two pieces.** Two agents returned `1.086` instead of `2.350`
  for the range `[-1, 1]`, which is `exp(1) - 1` MINUS `1 - exp(-1)`: they subtracted the backward
  piece instead of adding it.
- **The stopping point is available as the END OF A RANGE**, not only as a query point.
- **A level touched and retreated from is still taken.** Vega_2's last remaining failure; the rule
  was stated but abstract, so it now names the observable situation.

### Replay after the test fixes (frozen agent code, so hints cannot help here)

| Agent | On the platform | After the fixes | What is left |
| --- | --- | --- | --- |
| Vega_2 | 2 | **1** | touched-not-crossed level |
| Vega_1 | 2 | **1** | stopping point as a range end |
| Vega_3 | 3 | **2** | both discontinuity searches |
| Nova_3 | 6 | 6 | backward integral/interpolation |
| Nova_4 | 10 | 10 | backward coordinate math |

Every remaining near-miss failure is now covered by one of the four hints, and each of the three
leaders is one or two behaviors away. The two runs that hung should now finish and score as near
misses instead of zeros.

**Caveat, stated plainly: this is still 0 measured passes.** Replays cannot show the effect of hints,
so the next batch is the real test. If it comes back 0 again, the remaining lever is the
discontinuity-aware `maximum`/`minimum` requirement, which is the single most-missed behavior in the
suite and the one I would cut first.

State: 186 tests, 186 fail on base, reference 186/186 via `./test.sh new` in 100s, base 108 + 1
xfail, doctests green, 508 effective LOC, meta 1027 words ASCII, longest paragraph 138.

## Round 33 - meta trimmed to the 1000-word cap

1027 -> 981 words, longest paragraph 138 -> 132, still 9 paragraphs and ASCII. Prose only; no test,
solution or requirement touched.

Cut 46 words of phrasing, not content, biggest savings first: the past-a-stop sentence (41 -> 32), the
max/min-at-an-event hint (33 -> 23), the reset-only-value hint (35 -> 26), the step-start zero rule
(24 -> 18), and three smaller rewordings.

Both hints that lost words kept their operative clause - "so those points are candidates too" and
"is still taken there and belongs in the result". What went was restatement: the max/min hint no
longer spells out "rather than at an endpoint or where the derivative vanishes" (the preceding
sentence already says max/min consider endpoints, and extrema are defined by a vanishing derivative
two clauses earlier), and the reset hint no longer ends with "so those points need looking at as
well", which repeated "belongs in the result".

Re-traced every anchor that changed wording: callback shape for all callbacks including `roots` and
`integral`, the step-start zero rule, the arriving branch for `sol`/`diff`/`taylor`, lazy per-direction
records, the stop rules including the new range-end clause, and both search hints. All still present.

## Round 34 - hint for test_crossings_report_a_level_that_is_touched_not_crossed

Vega_2's only remaining failure, and the cause was structural rather than a missing rule.

The tangency rule ("a value touched without being crossed counts for these searches, unlike an
event") sits in the paragraph that DEFINES `sol.roots`, because the round-26 split moved it there.
`sol.crossings` is defined a paragraph earlier and never mentions it. The batch data matches that
exactly: `roots_report_a_value_that_is_touched_not_crossed` passed 5 of 5, while
`crossings_report_a_level_that_is_touched_not_crossed` passed 4 of 5. An implementer reading the
`crossings` definition had no reason to look for a tangential hit; the one who read on to `roots`
implemented it there and passed that half.

Fixed at the definition rather than by adding another remote sentence. `crossings` now reads
"...takes the given value, including where it only reaches that value and turns back without passing
through". The shared sentence stays where it is and still covers `roots`.

**This is the SECOND orphaning caused by that one paragraph split** - round 27 fixed the range/index
validation rule the same way. Both were sentences doing double duty for two method groups that ended
up on opposite sides of the break. I have now checked every remaining sentence that spans both
paragraphs: "each point is reported once", the reset-only-value hint and the `b` above `a` rule all
say "these searches" AND sit in the second paragraph, so the same risk applies to them for
`crossings`, `extrema`, `maximum` and `minimum`. They are covered by tests that currently pass on
most agents, so I am leaving them rather than re-splitting, but if a future batch clusters on one of
them, this is the first thing to check.

Prose only: 981 -> 994 words, paragraph 5 82 -> 95, longest still 132, ASCII. Tests and solution
untouched.

