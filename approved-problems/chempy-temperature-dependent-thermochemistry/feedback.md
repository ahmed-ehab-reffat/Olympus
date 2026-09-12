# feedback.md — chempy-temperature-dependent-thermochemistry

## Summary

Olympus submission on `bjodah/chempy` (BSD-2-Clause, 655 stars, Python), base commit
`b291866275e9232495a0984e222e6f3a650f85ed`. Adds a `chempy.thermochemistry` subpackage:
molar heat capacity models with a validity range, the enthalpy and entropy which follow
from integrating them, the reaction and mixture properties built on those, and six searches
(adiabatic temperature, equilibrium temperature, equilibrium composition, isentropic
temperature, adiabatic equilibrium, simultaneous equilibrium).

550 human-effective LOC across 4 files (3 new, 1 modified), 261 new tests, all 261 failing
on base as named nodes. Base suite 551 passed / 33 skipped / 5 xpassed, offline as uid
1000, unchanged by the solution and identical across runs.

## Pick rationale

`chempy.thermodynamics` holds exactly one equilibrium expression, `GibbsEqConst`, whose
enthalpy and entropy are temperature independent. Nothing in the package knows a heat
capacity, so no property can be evaluated away from 298.15 K. The maintainer's own wishlist
([issue #10](https://github.com/bjodah/chempy/issues/10)) lists "Shomate equation" and
"Data equivalent to NIST-JANAF" under `chempy.thermochemistry`, unchecked since 2015.

Repo screening, in the order `PICK-FILTER.md` asks for:

| Gate | Result |
| --- | --- |
| licence / stars / language | BSD-2-Clause, 655, Python |
| activity | last source commit 2026-05-10, inside the 12 month window |
| churn | 4 open PRs, 12 branches, 35 open issues |
| environment | 551 passed / 33 skipped / 5 xpassed in 7.1 s, offline, as uid 1000; bare `pytest` at the repo root is green too |
| exclusivity | zero PRs and zero branches over shomate, thermochemistry, JANAF, NASA, Kirchhoff, heat capacity, enthalpy, entropy, adiabatic; only `chempy-0.6.x` touches `chempy/thermodynamics/`, and only its test file |
| dedup | no thermochemistry pick anywhere in `Aprroved/`, `problems/`, `rejected/` or any `TaskN/problems/` |
| repo quota | 0 of 6 ours |

A wide fresh-repo screen ran first and is recorded in `eval-results.md`. The one prior local
pick on this repo, `problems/chempy-redox-balancing`, was shelved at design time on the LOC
wall; it is ion-electron balancing over oxidation states, a different subsystem with no
shared surface, and it was never submitted.

## Difficulty

Four conventions pull against each other and no single guard discharges them:

1. The Shomate heat capacity is in J/(mol K) while its tabulated enthalpy polynomial is in
   kJ/mol. Getting this wrong leaves every heat capacity test passing.
2. Enthalpy is relative to 298.15 K but entropy is absolute, in the same model. The NASA
   polynomial is naturally absolute and has to be shifted; its entropy must not be.
3. A boundary shared by two segments belongs to the earlier one, which decides the value of
   every property there and both solvers that walk across it.
4. The adiabatic search conserves the enthalpy of the whole mixture, inert species included,
   not the enthalpy of the reaction.

The two coupled searches compound them: `adiabatic_equilibrium` nests the composition solve
inside the temperature solve, and `simultaneous_equilibrium` sweeps reactions until the
composition stops moving.

## Verification

- F2P: 261 of 261 new tests fail on base, each as its own named node (imports are inside
  the test bodies so collection succeeds without the solution).
- Both apply orders (test then solution, solution then test) give 261 passed and a green
  base suite.
- Determinism: new mode 4x and base mode 4x, identical every run.
- Environment Quality reproduced on a platform-like tree (`git archive`, no `.git`): the
  vanilla `python -m build --no-isolation` and the vanilla suite are both green offline.
- Mutation battery: 21 targeted mutations over the traps, 20 killed, 1 equivalent (a mutant
  that recomputes the net stoichiometry by hand). A second round of 5 killed 4, with one
  equivalent (removing the explicit negative-amount guard in the extent helper still raises
  through the mixture sum). Table in `eval-results.md`.
- Fairness pass: every sentence of `meta.md` maps to at least one test and every test maps
  back to a sentence. The single codebase-inferable requirement is that `as_equilibrium`
  puts the constant in `Equilibrium.param`, which is chempy's own constructor convention.
- Style: `black` clean and `flake8` clean under the repo's own configuration.
- Nothing optional is left implicit in the tests: every accuracy assertion passes its own
  `tolerance`, every `Shomate.fit` passes `T_ref`, and every pressure-taking call passes a
  `pressure`. Checked with an AST walk, not by eye.

## Attempt history

- 2026-08-09 built. First LOC measurement came in at 368 human-effective, under the 450
  floor. Added orthogonal depth rather than breadth: composition-dependent Gibbs energy and
  the reaction quotient, the ideal mixing and pressure terms of the entropy, the isentropic
  search, the coupled adiabatic equilibrium and the multi-reaction sweep. 466 after that.
- Dropped `vant_hoff_slope` during the fairness pass. Its only fair statement would have
  been a definition of the derivative it returns, and the description had no room left
  under the 500 word cap; the words went to the `Shomate.fit` range arguments, the
  `SubstanceThermo` default and the `extent` default instead.
- 2026-08-09 revision after the platform prechecks.
  - Environment Quality FAIL: `python -m build --no-isolation` could not resolve chempy's
    own pinned build requirement `setuptools<=72.1.0` offline. The base image ships
    setuptools 82. The Dockerfile now installs `setuptools==72.1.0`, `wheel`, `build` and
    `pytest` at pinned versions before an editable install with `--no-build-isolation`,
    which also clears the reproducibility warning about unpinned installs. A
    `git config --system --add safe.directory '*'` line keeps the same command working in a
    tree that does carry `.git`, where setup.py's git introspection would otherwise abort
    on ownership.
  - Test Fairness FAIL, 4 of 146. Three `discontinuities` tests pinned an unstated
    container shape (`len(...)`, `jumps[0][0]`, `== []`); they now read the records the way
    the accepted three-segment test does, through a comprehension over the returned
    records. The fourth required `SubstanceThermo` to forward `T_min` and `T_max`, which
    the description only promises for the three models; that test is deleted. The
    forwarding stays in the solution because the searches need it, and it is still
    exercised through `test_substance_thermo_out_of_range_raises`.
  - Prompt/test alignment warning: `meta.md` now gives the numeric values of
    `molar_gas_constant` and `reference_temperature` instead of only naming them. Trimmed
    five words elsewhere to stay under the cap; 495 words now.
- 2026-08-09 revision round 2, Test Fairness again, 21 of 145. All of them pinned numerical
  accuracy on a search called without `tolerance`, and the description named the argument
  without ever saying what it measures or what it defaults to. Fixed on both sides: the
  description now says the five bracketed searches stop once the bracket is narrower than
  `tolerance`, in kelvin for a temperature and as a fraction of the feasible extent range
  for a composition, and every accuracy-sensitive test now passes an explicit `tolerance`
  (22 call sites). No solver behaviour changed; the values passed match the defaults.
  Trimmed seven words and split the last paragraph to stay inside the cap at 497 words over
  six paragraphs.
- 2026-08-09 revision round 3, Test Fairness, 7 of 145. Two optional arguments were being
  relied on without the description ever giving them a value: `Shomate.fit` was called
  without `T_ref` in four tests, and three tests read the omitted `pressure` as the standard
  pressure. Same remedy as the tolerance round, applied to the tests rather than the
  description, which has no room left: every `Shomate.fit` call now passes `T_ref`, and
  every call that takes a `pressure` now passes one, 37 call sites in total. Two of the
  insertions landed in front of a trailing comma and one collided with a positional
  pressure; both were repaired before the suite went green again.
- 2026-08-09 Test Fairness clean, four advisory coverage suggestions left. Took two of them,
  because both are already covered by the description's blanket error sentence and neither
  needs a line of solution: eight tests for a temperature inside a gap between two piecewise
  segments (`heat_capacity`, `enthalpy`, `segment_at`) and for the error paths of
  `isentropic_temperature` and `adiabatic_equilibrium` (non positive pressure, empty
  mixture, no bracketed root). Every path was probed first to confirm the current solution
  already raises. Declined the other two: rejecting a reversed `T_min`/`T_max` at
  construction would be a new requirement the description does not state, and a test that
  omits `pressure` to check it defaults to the standard pressure would put back exactly the
  unfairness round 3 removed. 153 tests now.
- 2026-08-09 second advisory round, five suggestions. Took four and a half, all of them
  free: a fit at exactly five points and at both fitted range limits, missing
  thermochemistry and out of range temperatures for `reaction_heat_capacity`,
  `reaction_entropy` and `equilibrium_constant`, a `simultaneous_equilibrium` with
  `max_iterations` of zero, and a test that bounds the composition extent by `tolerance`
  times the feasible extent range, which is the only test that pins the fractional meaning
  the description gives that argument. Every path was probed first; none needed a line of
  solution. Declined constructor validation again, and declined the non positive
  `tolerance` half of the search-control suggestion: the bisection simply converges to
  machine precision there, so asserting a `ValueError` would be asking for behaviour the
  description does not state. 162 tests now.
- 2026-08-09 third advisory round, five suggestions, four taken: NASA7 at both exact range
  limits, entropy inside a piecewise gap, a negative amount and a missing species in
  `adiabatic_temperature` rather than only in the mixture helpers, and a negative
  `max_iterations`. All five paths probed first, all already raise, no solution change.
  Constructor range validation declined for the third time and the non positive `tolerance`
  half declined again, both for the same reason: the description does not state either
  behaviour, so a test would be asking for new code rather than covering existing code.
  167 tests now.
- 2026-08-09 revision round 4, Test Fairness, 7 tests over two composite returns. The
  description said what `discontinuities` and `adiabatic_equilibrium` return without fixing
  the layout, so reading a record positionally or unpacking a pair was an author choice a
  named-field result object would fail. This one had to be fixed in the description, since
  a test cannot read a value without some access pattern: `discontinuities` now gives a
  `(temperature, heat capacity, enthalpy, entropy)` tuple and `adiabatic_equilibrium`
  returns a `(temperature, amounts)` tuple. Shortening the second sentence paid for the
  first; 499 words. No test or solution change was needed.
  Also took the two free coverage items in the same round: out of range `enthalpy` and
  `entropy` for NASA7, and negative amount, non positive pressure and missing
  thermochemistry for `simultaneous_equilibrium`. A fourth was dropped after probing: an
  inert species without thermochemistry does not raise there, because the sweep only looks
  up the species its reactions name, so a test would have demanded new behaviour. 172 tests.
- 2026-08-09 fourth advisory round, three suggestions, one taken: missing thermochemistry
  for a reaction species in `equilibrium_composition`, which already raises through the
  constant it computes first. Declined the other two again, and the reasoning has not
  changed with repetition. A reversed `T_min`/`T_max` is not rejected anywhere in the
  description, and a non positive `tolerance` does not raise: bisection with a zero width
  target simply converges to machine precision and returns. Adding either check would mean
  writing new behaviour and then testing it against a description that does not promise it,
  which is the exact shape of the four fairness failures this submission already paid for.
  Buying the words is not possible either, the description sits at 499 of 500. 173 tests.
- 2026-08-09 fifth advisory round. Took the one new suggestion, which found a real hole:
  pressure was only ever exercised through the single reaction solver. Added a mole
  changing chain, 2A to B followed by B to C, and checked that `simultaneous_equilibrium`
  drops the total amount at the higher pressure, that both equilibrium conditions still
  hold there with the pressure ratio in the right place, and that `adiabatic_equilibrium`
  reaches a higher temperature at the higher pressure because more of the mole reducing
  reaction runs. Declined the other two for the fifth and fourth time, unchanged reasoning.
  176 tests.
- 2026-08-09 sixth advisory round. Probed all three and took the one that already holds: an
  equal `T_min` and `T_max` bracket for `equilibrium_temperature` raises, so that is now
  tested. The rest do not hold and would need new behaviour. A reversed bracket does not
  raise, it returns the midpoint of the inverted interval. The three weighted mixture sums
  return zero for an empty or all zero mapping rather than raising, which is deliberate: a
  sum over nothing is zero, while `entropy_of_mixing` raises because a mole fraction
  logarithm over nothing is undefined. The description states neither, so a test either way
  would pin an author choice. Constructor validation declined for the seventh time.
  177 tests.
- 2026-08-09 seventh advisory round. Took the piecewise ordering item, which was a real
  gap: every earlier segment fixture was ordered and touched at a point, so first
  containing selection was never tested against a genuine overlap or an unsorted list.
  Both now are. Took the default `extent` half of the defaults item, since one mole is
  stated. Declined the default `pressure` and default `tolerance` half: neither default is
  in the description, and testing them is precisely the unfairness rounds 2 and 3 removed.
  Constructor validation declined for the eighth time and non positive `tolerance` for the
  seventh. 180 tests.
- 2026-08-09 revision round 5, Test Fairness, 2 assertions pinning the aggregate
  `PiecewiseThermo` range. The description said the three models expose their range but
  never said what a piecewise model's range is, and first-and-last segment or a rejection
  of unsorted input were equally readable. Fixed in the description rather than by dropping
  the assertions, because the searches depend on that envelope: `PiecewiseThermo` now
  "takes segments, spans all their ranges, and answers from the first whose range contains
  the temperature". Four small rewordings paid for it; 498 words. Also took the one free
  coverage item, the skip-zero behaviour for `mixture_heat_capacity` and `mixture_entropy`,
  and declined invalid model ranges for the ninth time and non positive `tolerance` for the
  eighth. 182 tests.
- 2026-08-09 eighth advisory round. Took the zero and negative temperature check on a
  model, and the zero amount case for `reaction_quotient` and
  `gibbs_energy_at_composition`, which is the log of zero boundary the suggestion asked
  about: a participating species at exactly zero raises rather than producing an infinite
  quotient. Declined non positive `tolerance` for the ninth time and constructor range
  validation for the tenth. 185 tests.
- 2026-08-09 ninth advisory round. Took mixture validation symmetry, negative amount and
  missing thermochemistry for `mixture_heat_capacity` and `mixture_entropy` as well as
  `mixture_enthalpy`, and the temperature half of the endpoint-roots item: a root sitting
  exactly on the lower or upper bracket limit is returned rather than bisected away, which
  exercises a branch of the search nothing else reached. The composition half does not
  apply, the extent bracket is deliberately inset so an exact endpoint root is not
  reachable there. Declined `tolerance` for the tenth time and constructor validation for
  the eleventh. 191 tests.
- 2026-08-09 tenth advisory round, one line taken: an empty fit data set raises, which the
  stated fewer-than-five rule already covers. Everything else in the round was a variant of
  the two standing declines, plus non finite input. Probed the latter for the first time and
  it confirms the decline: a NaN temperature returns NaN and a NaN in the fit data yields
  NaN coefficients, because the comparisons and the least squares are silent about it.
  Asserting a `ValueError` there would mean adding finiteness guards the description never
  promises. 192 tests, and the suggestion loop has converged.
- 2026-08-09 revision round 6, Test Fairness, 2 tests. Both findings were right. The
  description said `simultaneous_equilibrium` gives up after `max_iterations` but never said
  the giving up is a `ValueError`, so the blanket error sentence now includes "unconverged";
  one word, 499. The second was a genuine author choice on my side: `reaction_quotient`
  rejects a participating species at exactly zero, but standard quotient semantics allow
  Q = 0 for a product at zero and only its logarithm needs strict positivity. The behaviour
  stays, the test asserting it is deleted. The neighbouring
  `gibbs_energy_at_composition` zero-amount test is kept, because that one really does take
  a logarithm. Also took the free advisory item: NASA7 rejects eight coefficients as well as
  three, which the "any other count" wording already promises. 192 tests.
- 2026-08-09 eleventh advisory round, two taken. The endothermic case was a real hole:
  every adiabatic test until now was exothermic, so nothing checked that the search runs
  downhill. It does, exactly to the analytic `400 - 5000/(10*30)`, and the mixture enthalpy
  is still conserved at the lower temperature. Also confirmed that a zero amount species is
  ignored by `entropy_of_mixing` and `total_entropy` rather than reaching a logarithm of
  zero or demanding thermochemistry. Constructor ranges and `tolerance` domains declined for
  the fourteenth and thirteenth time. 196 tests.
- 2026-08-09 twelfth advisory round, two taken: a non positive temperature through NASA7
  and through the mixture sums, both of which reach the same range check the Shomate case
  already covered. Constructor ranges and `tolerance` domains declined for the fifteenth and
  fourteenth time. 198 tests, and the advisory loop is closed: twelve rounds have produced
  two genuine behavioural gaps (pressure through the coupled solvers, and the endothermic
  adiabatic case) and 55 tests, the rest of which restate contract points already covered
  at other entry points. Further rounds cost review noise without moving difficulty,
  fairness or LOC.
- 2026-08-09 thirteenth advisory round, reopened for one genuinely new behaviour: a negative
  `extent`. It is not rejected outright, and should not be, since running a reaction
  backwards is meaningful; it is governed by the same feasibility rule as a too large
  positive extent. Both halves are now pinned: a negative extent that would consume more
  product than is present raises, and one with enough product runs the reaction backwards to
  the analytic `400 - 5000/(12*30)` while conserving the mixture enthalpy. This also
  exercises the product side of the feasibility check, which only the reactant side had
  covered. Constructor ranges and `tolerance` declined for the sixteenth and fifteenth time.
  200 tests.
- 2026-08-09 fourteenth advisory round, one taken: `discontinuities` over unsorted and
  overlapping segments. Neither pair shares a boundary in the sense the description states,
  so both report nothing, which the "boundary two consecutive segments share" wording
  already settles. Declined the empty mixture item again, for the reason given in round 6:
  the three weighted sums return zero rather than raising, the description states neither
  reading, and the asymmetry with `entropy_of_mixing` is deliberate. Constructor ranges and
  `tolerance` declined for the seventeenth and sixteenth time. 202 tests.
- 2026-08-09 revision round 7, Test Fairness, 1 test, and it was mine from the previous
  round. I added a test asserting that a FEASIBLE negative `extent` runs the reaction
  backwards, on the argument that a signed extent is standard. It is standard, but the
  description says anything negative raises, so rejecting a negative extent is an equally
  reasonable reading and the test pinned an unstated exception to my own stated rule. The
  test is deleted; the behaviour stays. The other half of that round survives and is the
  fair half: a negative extent that would consume more product than is present raises, which
  is the same feasibility rule as a too large positive extent. Lesson for the next build: a
  new behavioural case is only worth a test if the description settles it, and a broad error
  sentence makes every exception to itself unstated. All three advisory items were the
  standing declines. 201 tests.
- 2026-08-09 fifteenth advisory round, none taken, all three were the standing declines.
  Verified the empty-mixture one by experiment rather than by argument this time: a variant
  of the solution that RAISES on an empty or all-zero mixture passes all 201 tests, exactly
  as the shipped variant that returns zero does. So the reading is genuinely unasserted in
  either direction, which is the right state for a case the description does not settle, and
  adding a test would pick a side. Constructor ranges declined for the nineteenth time,
  `tolerance` and non finite controls for the eighteenth.
- 2026-08-09 Description Quality FAIL, 4 comments, all four addressed rather than contested
  because all four are right. They pull the opposite way from Test Fairness, which is the
  useful thing to notice: fairness pushes you to pin more, description quality punishes
  pinning anything the tests do not need. The resolution is to state the OBSERVABLE contract
  and drop the implementation. "Every quantity is a plain float in SI" became "Use SI units
  throughout", since no test asserts the Python scalar type. "by least squares" went, since
  no test inspects the fitting method and exact data in the same five term basis is
  recovered by any sensible fit. "The other five stop once their bracket is narrower than
  `tolerance`" became "`tolerance` is the convergence tolerance", which keeps the meaning
  round 2 demanded (kelvin for a temperature, a fraction of the feasible extent range for a
  composition) without the stopping rule. "Six searches close it" was just AI cadence and is
  now "Six solvers finish the subpackage". 491 words, nine freed and deliberately left
  unspent. No test or solution change.
- 2026-08-09 sixteenth advisory round, one taken and it passes the test I set myself last
  time: an empty mixture into the three remaining solvers is settled by a sentence, the
  blanket "empty ... raises `ValueError`", and the solution already raises on all three
  paths, so asserting it picks no side. Probed first: `adiabatic_temperature` fails on
  feasibility, `adiabatic_equilibrium` and `simultaneous_equilibrium` fail on the extent
  bracket, and all three surface `ValueError` as stated. Constructor ranges declined for the
  twentieth time and `tolerance` for the nineteenth. 204 tests.
- 2026-08-09 seventeenth advisory round, none taken. Two were the standing declines. The
  third asked for exactly the test Test Fairness FAILED in precheck round 7: an
  `adiabatic_temperature` case with a feasible negative extent, distinguishing valid reverse
  turnover from the infeasible one. That test existed, was flagged unfair because the
  description says anything negative raises and never carves out a signed extent, and was
  deleted for that reason. Re-adding it would re-introduce a blocking failure to satisfy an
  advisory note, so it stays out. The advisory checker and the fairness checker genuinely
  disagree on this case; the blocking one wins.
- 2026-08-09 Task Quality FAIL (criterion 04, fairness) and Description Quality FAIL, and
  the two pull against each other under the 500 word cap. Task Quality says naming Shomate
  and NASA7 without their equations makes the numeric tests unpassable from the repository
  and prompt alone; the repository has no such implementation to mirror, so it is right.
  Description Quality says the prompt pins things the tests do not need. Resolved together
  by REPLACING prose with formulas: the six polynomial expressions, the ideal gas activity
  and the two entropy terms are now written out, and the prose they replace goes away
  ("the eight coefficients NIST tabulates", "the one NIST prints in kJ/mol", "the NASA
  polynomial has to be shifted by its own value there", "fits the five heat capacity
  coefficients ... and fixes the rest"). Writing formulas without spaces around operators
  keeps them cheap: 453 words now, down from 491, with all six paragraphs under 150.
  Verified the description is self-sufficient by transcribing its formulas verbatim into an
  independent script and comparing against the solution over 41 temperatures per card:
  worst relative deviation 6.3e-16, and the mixing entropy matches exactly.
  Six of the seven Description Quality comments are addressed outright. Two are answered
  rather than obeyed, and both because a different blocking check requires them:
  "less its own value at 298.15 K" stays because Task Quality demands the exact NASA
  enthalpy formula, and the `tolerance` sentence keeps its two meanings (kelvin, and a
  fraction of the feasible extent range) because Test Fairness round 2 failed 21 tests over
  precisely that gap and two current tests assert those meanings; it is trimmed instead.
  ⭐ COST: giving the formulas removes two of the four traps. The kJ vs J factor is now
  printed as `1000*(...)` and the NASA reference shift is stated outright. What remains is
  the segment tie at a shared boundary, the whole-mixture rather than reaction enthalpy
  balance, the coupled adiabatic-equilibrium and multi-reaction solvers, the pressure
  exponent from the mole change, and the netting of a species on both sides. Expect the
  pass rate to be higher than the pre-fix design assumed; the batch is the only way to know.
- 2026-08-09 revision round 8, Test Fairness, 1 test, and it is the direct cost of the
  previous round. `test_simultaneous_equilibrium_without_convergence_raises` used
  `tolerance=1e-30` with `max_iterations=2` and expected a failure. That was fair while the
  description spelled out the sweep and its stopping rule; Description Quality asked me to
  soften that to "equilibrates reactions until they converge", and once the trajectory is
  unstated a direct solver could legitimately converge inside two iterations. Deleted. The
  budget-exhaustion path keeps full coverage through `max_iterations` of 0 and of -1, both of
  which are implementation independent: no solver can converge inside a budget of zero, and
  the reviewer passed both. Took the one free advisory item in exchange, a missing species
  in `adiabatic_equilibrium`, settled by "absent ... raises". 204 tests.
  ⭐ The two description checks now form a closed loop worth naming: pinning an internal rule
  keeps a test fair but fails Description Quality; softening the rule passes it and makes the
  test algorithm coupled. The stable answer is to test only what survives BOTH readings, in
  this case a zero iteration budget rather than a tight tolerance.
- 2026-08-09 eighteenth advisory round, none taken. Two were the standing declines. The
  third asks for `simultaneous_equilibrium` with a positive but insufficient
  `max_iterations`, which is the test precheck round 10 deleted as unfair, one round earlier,
  in a different dress. There is no fair version of it: to make a positive budget
  insufficient you must assume the solver needs more steps than you gave it, and the
  description no longer states a trajectory. Even an unreachable tolerance does not save it,
  since a solver that lands exactly on the answer sees no amount move at all and converges
  under any tolerance. That is why the surviving budget tests use zero and minus one, which
  no algorithm can get inside. Second time an advisory note has asked for something a
  blocking check already rejected; the blocking check wins again.
- 2026-08-09 BATCH 1, 5x Nova: 0 of 5, unsolvable as shipped, and the cause is one thing.
  Every failure in every run is the call contract, never a thermodynamic value: 90
  `TypeError` from positional argument order, `discontinuities` implemented as a property,
  and a reaction product absent from `amounts`. Baseline passed 555 tests in all five runs,
  so the environment is fine. Three evaluators set `agent_blame_unfair`. Fixed by stating the
  argument order as a rule, giving the two signatures that break it, writing the call
  parentheses on every method, and saying a reaction species missing from `amounts` starts at
  zero; 490 words, and a script confirms all 19 public functions obey the stated rule.
  Solvability is now proven rather than argued: Nova_2's own patch, with only those two call
  shapes adapted, passes 204 of 204 with the base suite green. FP closed against that
  implementation with description-derived and closed-form oracles: models exact, K exact,
  equilibrium quotient within 5.5e-13 of the constant, adiabatic enthalpy balanced to
  1.5e-11 J and matching a closed form to six decimals.
  ⚠ The batch also exposed the real difficulty problem: all five agents solved the physics.
  What was failing them was the undocumented API shape, which the rules call fake difficulty,
  and the Task Quality round had already removed the two misdirecting conventions. Expect the
  next batch to land high, possibly over the 40 percent ceiling. See the difficulty note in
  eval-results.md.
- 2026-08-09 RE-HARDENED against the batch evidence. The batch said the physics is easy for
  these agents and the only thing that stopped them was contract, so the new difficulty has to
  be a requirement that is fully stated and still hard. Traded `Shomate.fit`, the least
  interesting surface and the one Description Quality had already flagged, for segment
  RECONCILIATION: a multi segment model now shifts each segment by the jumps accumulated
  between it and the segment holding 298.15 K, so enthalpy and entropy run continuously,
  while heat capacity is never shifted and `discontinuities()` keeps reporting the raw jumps.
  Four ways to get it wrong, all fair because all stated: anchoring on the first segment
  instead of the one holding the reference, accumulating only upward from the anchor,
  the sign of the accumulated jump, and reconciling the wrong quantities. It is
  INTERDEPENDENT by construction: reconcile by mutating the segments and `discontinuities()`
  reports zeros; keep the raw jumps and forget to reconcile and every cross boundary enthalpy
  is wrong. It is MISDIRECTING: a wrong anchor still gives continuous enthalpy and still
  satisfies dH/dT = Cp, so the continuity and derivative tests pass and the failure surfaces
  as a wrong reaction enthalpy far away. And it buys a test that was impossible before: the
  Kirchhoff identity now holds ACROSS a segment boundary, 500 to 1100 K, which the old
  per-segment delegation could never satisfy. Mutation battery on the trap: 8 of 8 killed.
  453 human-effective LOC, 202 tests, meta 499 words.
- 2026-08-09 revision round 9, Test Fairness, 16 tests over two description gaps, both mine.
  Fifteen NASA7 tests inherited an unstated constructor shape: every fixture builds
  `NASA7([a1..a7], T_min, T_max)` while the description said only "takes seven coefficients"
  directly beside a Shomate that takes its coefficients positionally, so seven positional
  arguments were equally readable. The description now says the seven coefficients are given
  "as one sequence". The sixteenth is a contradiction I created myself when I added the zero
  default for the batch fix: "a reaction species missing from `amounts` starts at zero" made
  an absent species in `reaction_quotient` mean Q equals zero, while the blanket sentence
  says absent raises. Scoped the default to "in the searches", which is where the batch
  needed it, and left the quotient under the blanket rule; the test stands. Paid for both by
  trimming five words and dropping "`pressure` applies wherever a mixture does", which the
  argument-order list and the activity formula already carry. 495 words.
  ⭐ Both gaps came from the same place: a sentence added to fix one check reached further
  than intended. The zero default was written for the solvers and silently rewrote the
  quotient. Scope every new rule to the functions it is meant for.
- 2026-08-09 the 500 word cap was lifted by the user, so three things that had been cut only
  to fit went back in. `Shomate.fit` is restored with 10 tests, described by what it produces
  rather than by least squares, which is the phrasing Description Quality accepted; that also
  lifts the LOC margin from 453 to 501, comfortably clear of the 450 floor. The list of which
  functions take a `pressure` is back, closing the one shape ambiguity the last trim opened:
  `adiabatic_equilibrium` and `simultaneous_equilibrium` taking a pressure had become merely
  inferable, and the batch proved that inferable is not good enough. And the three composition
  solvers are now stated to return a mapping of species to amounts. 562 words over seven
  paragraphs, longest 107, still inside the 150 word wall-of-text limit that the cap removal
  does not touch.
- 2026-08-09 nineteenth advisory round, three of four taken, and the first one caught a real
  mismatch I had introduced while trimming for the old cap. Shortening the constant sentence
  to "here `R`" read as a claim that a name `R` is exported, which the solution does not do.
  Reworded to "which the formulas below write as R", so R is plainly notation; no alias is
  added and nothing is tested, because there is nothing to test. Took the positional-order
  item in the form that is behavioural rather than introspective: two tests call the six
  ordered functions with every argument positional and compare against the keyword call.
  That directly enforces the contract batch 1 died on, without pinning parameter names or
  defaults through `inspect.signature`, which would have asserted defaults the description
  does not state. Took the entropy-offset item, which mirrors the enthalpy test in both
  directions around the reference segment. Declined the positive-but-insufficient
  `max_iterations` item for the third time: Test Fairness deleted exactly that test in
  precheck round 10, and no fair version exists. 215 tests.
- 2026-08-09 twentieth advisory round, two of four taken, both free and both settled by a
  sentence: `as_equilibrium` returns an `Equilibrium`, which the description states outright
  and only the constant and stoichiometry were being checked, and the entropy half of the
  gap-anchor rule, mirroring the enthalpy version so both quantities are shown unshifted
  beyond a gap. Declined the positive-but-insufficient `max_iterations` item for the fourth
  time and the non-positive `tolerance` item for the twenty-sixth; both have been probed and
  neither is settled by the description. 217 tests.
- 2026-08-09 twenty-first advisory round, one of four taken: a non positive `pressure`
  straight into `gibbs_energy_at_composition`, which the pressure list and the blanket error
  sentence both settle and which already raises through the quotient it computes. The other
  three were the standing declines, now at five, twenty-seven and twenty-six repetitions.
  218 tests. The advisory loop has been asymptotic for several rounds: it is returning the
  same three items and finding roughly one free test per round.
- 2026-08-09 twenty-second advisory round, one taken and it was worth having: every earlier
  `reaction_quotient` case contained only reacting species, so nothing showed that an inert
  enters the mole fractions. Two tests now pin it on the mole-changing dimerisation, at the
  standard pressure and at 5e5 Pa, and the diluted quotient is asserted to differ from the
  undiluted one, so a total that skips inerts fails rather than passing by coincidence.
  Declined the two standing items again, at six and twenty-eight. 220 tests.
- 2026-08-09 twenty-third advisory round. Two of the three perennials were only declined
  because they were not stated and there was no word budget to state them. The cap is gone,
  so instead of declining a seventh time I turned them into contract: `tolerance` must be
  positive, and a model whose `T_min` exceeds its `T_max` is rejected. Both are now in the
  description, implemented behind small shared guards, and covered by five tests including
  one that fixes the boundary the suggestion left open, equal limits being allowed rather
  than rejected. 515 human-effective LOC, 225 tests, 584 words. The third perennial,
  a positive but insufficient `max_iterations`, stays declined for the seventh time: it is
  not a budget problem, it is unfixable, because a positive budget is only insufficient if
  the solver's trajectory is assumed and Test Fairness deleted that exact test in round 10.
  ⭐ Worth carrying forward: a decline whose reason is "no room to state it" expires the
  moment the room appears. Re-read old declines when a constraint is lifted.
