# eval-results.md — chempy-temperature-dependent-thermochemistry

Per-agent results per batch. Columns: agent | evaluator | verdict | msgs | files | LOC |
failed tests | failure reason | approach note.

## Repo screen that preceded the pick

| Repo | Stars | Licence | Verdict |
| --- | --- | --- | --- |
| pyart, flopy, openmc, tomopy, deepdiff, LibCST, pulp, pymatgen, networkx, fipy, yt, jwst, MintPy | - | NOASSERTION | licence gate |
| pysheds (893), pyo, obspy, omicverse, bakta, plip, gempy | - | GPL / LGPL / EUPL / MPL | licence gate |
| ross (193), spaghetti (284), harmonica (302), xmldiff (229) | - | - | under the 500 star gate |
| meshio | 2318 | MIT | last push 2024-07, fails the recency gate |
| scikit-mobility | 806 | BSD-3 | last push 2024-05, fails the recency gate |
| biotite | 969 | BSD-3 | environment gate, `tests/database` is network by design (already recorded in an earlier cycle) |
| PlasmaPy | 703 | BSD-3 | 46 open PRs, several of them adding formulary (fusion cross-sections, gyrokinetic dispersion, thermal equilibration); exclusivity minefield |
| PyBaMM | 1634 | BSD-3 | 73 open PRs and 62 branches |
| optiland | 843 | MIT | open PRs or branches already cover GRIN, non-sequential and multi-sequence tracing, thin films, Zernike, ISO drawings, Buchdahl materials |
| movingpandas | 1407 | BSD-3 | 6.8k LOC and the distance / mobility-metric space is a live workstream |
| momepy, verde, datacompy, pydata-sparse | 628-666 | BSD-3 / Apache-2.0 | pointwise-decoupled character families or too compact for the LOC floor |
| ruptures | 2070 | BSD-2 | same feature class as `rejected/augurs-offline-changepoint` |
| pymoo | 2933 | Apache-2.0 | stochastic outputs |
| regclient | 1905 | Apache-2.0 | viable, but every candidate feature is OCI spec transcription and the layer work is adjacent to the approved afero overlay pick |
| **bjodah/chempy** | 655 | BSD-2 | **picked**: an almost empty `thermodynamics` subsystem the maintainer wishlisted himself, clean exclusivity, 7 s offline suite |

## Mutation battery

Round 1, 21 mutations of the solution against the new tests.

| Mutation | Outcome |
| --- | --- |
| Shomate enthalpy left in kJ/mol | killed |
| Shomate heat capacity without `t = T/1000` | killed |
| NASA enthalpy left absolute | killed |
| piecewise takes the last matching segment | killed |
| range limits made exclusive | killed |
| `SubstanceThermo.entropy` adds the formation enthalpy | killed |
| fit ignores the entropy constraint | killed |
| discontinuity sign flipped | killed |
| equilibrium constant sign | killed |
| Gibbs energy drops the entropy term | killed |
| adiabatic search uses the reaction enthalpy | killed |
| bisection without the sign check | killed |
| equilibrium composition drops the pressure term | killed |
| equilibrium composition uses amounts, not mole fractions | killed |
| reaction quotient drops the pressure ratio | killed |
| entropy of mixing sign | killed |
| total entropy pressure sign | killed |
| isentropic search drops the mixing and pressure terms | killed |
| adiabatic equilibrium ignores the composition shift | killed |
| simultaneous equilibrium stops after one sweep | killed |
| reaction sum recomputes the net stoichiometry by hand | survives, equivalent |

Round 2, 5 further mutations.

| Mutation | Outcome |
| --- | --- |
| reaction sum drops the reactants | killed |
| reaction sum uses the product coefficient only | killed |
| mixture skips the negative amount check | killed |
| simultaneous equilibrium ignores `max_iterations` | killed |
| extent helper drops its negative amount guard | survives, equivalent (the mixture sum raises instead) |

## Validation record

| Check | Result |
| --- | --- |
| F2P | 261 of 261 new tests fail on base, named nodes, no collection error |
| new mode with solution | 261 passed |
| base mode with solution | 551 passed / 33 skipped / 5 xpassed |
| apply order test then solution | green |
| apply order solution then test | green |
| determinism | 4x new and 4x base, identical |
| vanilla bare `pytest` in the image | 551 passed / 33 skipped / 5 xpassed in 6.3 s |
| vanilla `python -m build --no-isolation`, offline, no `.git` | wheel and sdist built |
| human-effective LOC | 550 over 4 files |
| meta.md | 835 words, ASCII, 11 body paragraphs, longest 152 words |

## Platform precheck round 1 (2026-08-09)

| Check | Verdict | Action |
| --- | --- | --- |
| Environment Quality | FAIL, `python -m build --no-isolation` could not resolve `setuptools<=72.1.0` offline | pinned setuptools, wheel, build and pytest in the Dockerfile, editable install with `--no-build-isolation`, plus a system `safe.directory` entry |
| Dockerfile guidelines | 2 warnings, editable install and unpinned packages | every explicitly installed package now carries an exact version |
| Prompt and tests aligned | warning, constants not given numerically | `meta.md` states 8.314462618 and 298.15 |
| Test Fairness | FAIL, 4 of 146 | 3 `discontinuities` tests rewritten to read records without pinning the container, 1 `SubstanceThermo` range-forwarding test deleted |

## Platform precheck round 2 (2026-08-09)

| Check | Verdict | Action |
| --- | --- | --- |
| Test Fairness | FAIL, 21 of 145, all "accuracy pinned on a search called without `tolerance`" | description now defines what `tolerance` measures for the five bracketed searches; 22 call sites in the accuracy-sensitive tests pass an explicit `tolerance` |

Everything else from round 1 stayed green. The 21 flagged tests were not wrong about the
physics; they asserted 1e-6 to 1e-9 agreement while leaving the stopping rule to a default
the description never named.

## Platform precheck round 3 (2026-08-09)

| Check | Verdict | Action |
| --- | --- | --- |
| Test Fairness | FAIL, 7 of 145: four `Shomate.fit` calls without `T_ref`, three readings of an omitted `pressure` as the standard pressure | every `Shomate.fit` call passes `T_ref` and every pressure-taking call passes `pressure`, 37 call sites; verified by an AST walk that no such call is left defaulted |

The pattern across rounds 2 and 3 is one rule: a test may not lean on the value of an
optional argument the description does not fix. Passing it explicitly is cheaper than
buying the words, and it changes no expected value because the values passed are the
defaults.

## Coverage suggestions (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| piecewise internal gaps | taken, 3 tests; the blanket out-of-range sentence already covers it and the solution already raises |
| solver validation for `isentropic_temperature` and `adiabatic_equilibrium` | taken, 5 tests, same reasoning |
| constructor validation for non positive or reversed `T_min`/`T_max` | declined, it would add a requirement the description does not state |
| a call omitting `pressure` to confirm it defaults to the standard pressure | declined, it recreates the round 3 unfairness |

## Coverage suggestions round 2 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| `Shomate.fit` at exactly five points and at the range limits | taken, 2 tests |
| missing thermochemistry and out of range for the other reaction helpers | taken, 5 tests |
| non positive `max_iterations` | taken, 1 test, the sweep loop already gives up and raises |
| composition tolerance semantics | taken, 1 test bounding the extent by `tolerance` times the feasible range |
| non positive `tolerance` | declined, bisection converges to machine precision rather than raising, so the test would demand unstated behaviour |
| constructor validation, reversed or non finite bounds | declined again, it would add a requirement |

## Coverage suggestions round 3 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| NASA7 at both exact range limits | taken, 1 test |
| entropy inside a piecewise gap | taken, 1 test |
| negative amount and missing species in `adiabatic_temperature` | taken, 2 tests |
| negative `max_iterations` | taken, 1 test |
| constructor range validation, and non positive `tolerance` | declined, third and second time; neither is stated, so a test would demand new behaviour |

## Platform precheck round 4 (2026-08-09)

| Check | Verdict | Action |
| --- | --- | --- |
| Test Fairness | FAIL, 7 tests over the LAYOUT of two composite returns | the description now fixes both: a `(temperature, heat capacity, enthalpy, entropy)` tuple from `discontinuities` and a `(temperature, amounts)` tuple from `adiabatic_equilibrium` |
| coverage, NASA7 range propagation | taken, 2 tests |
| coverage, simultaneous solver inputs | taken, 3 of 4; an inert species without thermochemistry does not raise, since the sweep only looks up the species its reactions name |
| coverage, constructor and tolerance validation | declined, fourth and third time |

Rounds 1 to 3 moved test call sites; this one had to move the description. A test cannot
read a returned record without committing to an access pattern, so when a return is
composite the prompt has to name its layout.

## Coverage suggestions round 4 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| missing thermochemistry for a reaction species in `equilibrium_composition` | taken, 1 test |
| non positive `tolerance` rejected by each search | declined, fourth time; it does not raise, bisection converges to machine precision, so the test would need new unstated behaviour |
| constructor validation of `T_min > T_max` | declined, fifth time; not stated anywhere in the description |

Both declines are deliberate and stable across four review rounds. The description is at
499 of 500 words, so neither behaviour can be bought into the contract; implementing it
unstated would recreate the fairness failures already fixed.

## Coverage suggestions round 5 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| pressure propagation through the coupled solvers | taken, 3 tests on a mole changing chain; the only suggestion so far that found untested behaviour rather than an unstated contract |
| non positive `tolerance` | declined, fifth time |
| constructor validation of `T_min > T_max` | declined, sixth time |

## Coverage suggestions round 6 (advisory, 2026-08-09)

| Suggestion | Probe | Action |
| --- | --- | --- |
| equal explicit bracket | raises | taken, 1 test |
| reversed explicit bracket | returns the midpoint, no raise | declined, would need new behaviour |
| empty or all zero basic mixtures | return zero, no raise | declined, the description states neither reading; the asymmetry with `entropy_of_mixing` is deliberate |
| non positive `tolerance` | converges, no raise | declined, sixth time |
| constructor validation of `T_min > T_max` | no check exists | declined, seventh time |

## Coverage suggestions round 7 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| piecewise overlap wider than an endpoint, and unsorted segments | taken, 2 tests; a real gap, every earlier fixture was ordered and touching |
| default `extent` | taken, 1 test; one mole is stated in the description |
| default `pressure` and default `tolerance` | declined, neither is stated; this is the exact unfairness rounds 2 and 3 removed |
| non positive `tolerance`, constructor validation | declined, seventh and eighth time |

## Platform precheck round 5 (2026-08-09)

| Check | Verdict | Action |
| --- | --- | --- |
| Test Fairness | FAIL, 2 assertions on the aggregate `PiecewiseThermo` range | the description now says it spans all its segments' ranges |
| coverage, mixture zero amount for the other two sums | taken, 2 tests |
| coverage, invalid model ranges and non positive `tolerance` | declined, ninth and eighth time |

Second time a fairness finding had to be answered in the description rather than in the
tests. Both were the same species of gap: the prompt described a value without fixing what
it IS, once for a composite return and once for an aggregate attribute.

## Coverage suggestions round 8 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| non positive absolute temperature | taken, 1 test; it falls under the range check |
| a participating species at exactly zero amount | taken, 2 tests; the log of zero boundary raises rather than returning an infinite quotient |
| non positive `tolerance` | declined, ninth time |
| constructor range validation | declined, tenth time |

## Coverage suggestions round 9 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| mixture validation symmetry | taken, 4 tests |
| endpoint roots, temperature searches | taken, 2 tests; a root on either bracket limit is returned directly, a branch nothing else reached |
| endpoint roots, composition search | not applicable, the extent bracket is inset so an exact endpoint root cannot occur |
| `tolerance` and constructor validation | declined, tenth and eleventh time |

## Coverage suggestions round 10 (advisory, 2026-08-09)

| Suggestion | Probe | Action |
| --- | --- | --- |
| empty fit data | raises | taken, 1 test |
| non finite inputs | NaN temperature returns NaN, NaN fit data gives NaN coefficients | declined, would need finiteness guards the description does not promise |
| constructor range validation, `tolerance` domain, invalid explicit fit range | no check exists | declined, twelfth and eleventh time |

Ten advisory rounds have now added 47 tests. The last four rounds produced one genuine
behavioural gap between them (pressure through the coupled solvers); the rest converged on
the same unstated-contract items. Treating the loop as finished.

## Platform precheck round 6 (2026-08-09)

| Check | Verdict | Action |
| --- | --- | --- |
| Test Fairness | FAIL, 2 of 192 | "unconverged" added to the blanket error sentence; the `reaction_quotient` zero-amount test deleted as an author choice standard quotient semantics do not support |
| coverage, NASA7 upper coefficient count | taken, 1 test |
| coverage, model/fit range and `tolerance` domains | declined, thirteenth and twelfth time |

The second finding is the only one across six rounds where the reviewer disagreed with the
BEHAVIOUR rather than with what the description pinned. Q = 0 is a legitimate limiting
composition; rejecting it is defensible but unstated, so the assertion went rather than the
code.

## Coverage suggestions round 11 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| endothermic adiabatic case | taken, 2 tests; a real hole, every adiabatic test was exothermic |
| zero amount ignored by `entropy_of_mixing` and `total_entropy` | taken, 2 tests |
| constructor range validation, `tolerance` domain | declined, fourteenth and thirteenth time |

## Coverage suggestions round 12 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| non positive temperature through NASA7 and the mixture sums | taken, 2 tests |
| constructor range validation, `tolerance` domain | declined, fifteenth and fourteenth time |

Loop closed here. Twelve advisory rounds, 55 tests added, two of which closed genuine
behavioural gaps. The two standing declines are stable and documented; everything else has
converged on restating covered contract points at further entry points.

## Coverage suggestions round 13 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| negative `extent` | taken, 2 tests; a third genuine behavioural gap. It is not rejected outright, it obeys the same feasibility rule as a too large positive extent, and it exercises the product side of that check |
| constructor range validation, `tolerance` domain | declined, sixteenth and fifteenth time |

## Coverage suggestions round 14 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| `discontinuities` for unsorted and overlapping segments | taken, 2 tests; both report nothing, settled by the "boundary two consecutive segments share" wording |
| empty or all zero basic mixtures | declined again, see round 6 |
| constructor range validation, `tolerance` domain | declined, seventeenth and sixteenth time |

## Platform precheck round 7 (2026-08-09)

| Check | Verdict | Action |
| --- | --- | --- |
| Test Fairness | FAIL, 1 of 202, a test added in the previous advisory round | deleted; asserting that a feasible negative `extent` runs the reaction backwards pinned an unstated exception to the description's own "anything negative raises" sentence |
| coverage, `tolerance` domain, empty mixtures, constructor ranges | declined, seventeenth, third and eighteenth time |

Second time a coverage suggestion led me into an unfair test (the first was the zero amount
`reaction_quotient`). Both times the suggestion asked for a case the description does not
settle, and taking it meant choosing a policy. The safe reading: a coverage suggestion is
only free when the behaviour it names is already fixed by a sentence in the prompt.

## Coverage suggestions round 15 (advisory, 2026-08-09)

None taken; all three were the standing declines. One was settled by experiment: a solution
variant that raises on an empty or all-zero mixture passes all 201 tests, exactly like the
shipped variant that returns zero. The empty-mixture reading is therefore unasserted in
both directions, so neither implementation is penalised and a test would pick a side the
description does not.

| Suggestion | Action |
| --- | --- |
| empty base mixtures | declined, both readings pass the suite (probed) |
| constructor range validation | declined, nineteenth time |
| `tolerance` domain and non finite controls | declined, eighteenth time |

## Platform precheck round 8 (2026-08-09) — Description Quality

| Comment | Action |
| --- | --- |
| "plain float" pins a Python type no test asserts | softened to "Use SI units throughout" |
| "by least squares" pins an algorithm no test inspects | dropped, the behaviour it produces is still pinned |
| "stop once their bracket is narrower than `tolerance`" pins an internal stopping rule | restated as "`tolerance` is the convergence tolerance", keeping the kelvin and extent-fraction meanings Test Fairness round 2 required |
| "Six searches close it" reads as generated prose | "Six solvers finish the subpackage" |

⭐ The two checks pull in opposite directions. Test Fairness fails a test that leans on
anything the description leaves open; Description Quality fails a description that pins
anything the tests do not need. The line between them is the OBSERVABLE contract: state
units, meanings, defaults, layouts and error classes; never state types, algorithms or
stopping rules.

## Coverage suggestions round 16 (advisory, 2026-08-09)

| Suggestion | Settled by a sentence? | Action |
| --- | --- | --- |
| empty mixture into `adiabatic_temperature`, `adiabatic_equilibrium`, `simultaneous_equilibrium` | yes, "empty ... raises `ValueError`" | taken, 3 tests |
| constructor range validation | no | declined, twentieth time |
| `tolerance` domain | no | declined, nineteenth time |

This round is the clean application of the rule the two unfair tests taught: take a
suggestion when a prompt sentence decides the outcome and the solution already behaves that
way, decline it when taking it would mean choosing a policy.

## Coverage suggestions round 17 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| reverse feasible extent for `adiabatic_temperature` | declined; this is verbatim the test Test Fairness failed in precheck round 7 and which was deleted for it |
| non positive `tolerance`, non finite scalars | declined, twenty-first time; probed, neither raises |
| constructor range validation | declined, twenty-second time |

⭐ The advisory coverage checker and the blocking Test Fairness checker directly contradict
each other on the feasible negative extent: coverage wants it asserted, fairness rejects
asserting it because the description's blanket negative rule leaves the carve-out unstated.
The blocking check wins. Resolving it properly would mean spending words to state that a
negative extent runs the reaction backwards, which then has to be reconciled with that same
blanket sentence.

## Platform precheck round 9 (2026-08-09) — Task Quality + Description Quality

| Check | Verdict | Action |
| --- | --- | --- |
| Task Quality, criterion 04 fairness | FAIL, Shomate and NASA7 equations neither in the repo nor in the prompt | all six polynomial expressions written into the description, plus the ideal gas activity and both entropy terms |
| Description Quality | FAIL, 7 comments | 5 addressed by deleting the prose the formulas replace, 2 answered: the NASA reference shift is now part of the formula Task Quality demands, and the `tolerance` meanings are required by Test Fairness round 2 |

Self-sufficiency proof: the description's formulas were transcribed verbatim into an
independent script and compared with the solution over 41 temperatures per card. Worst
relative deviation 6.3e-16; the mixing entropy matched exactly. A solver reading only the
prompt can now reproduce every pinned number.

⭐ Difficulty cost, recorded honestly: two of the four designed traps are gone. `1000*(...)`
in the printed formula removes the kJ versus J misdirection, and "less its own value at
298.15 K" removes the NASA reference-shift trap. The surviving traps are the shared-boundary
segment tie, the whole-mixture enthalpy balance, the two coupled solvers, the pressure
exponent, and net-stoichiometry cancellation.

## Platform precheck round 10 (2026-08-09)

| Check | Verdict | Action |
| --- | --- | --- |
| Test Fairness | FAIL, 1 of 204, the tight-tolerance non-convergence test | deleted; it became algorithm coupled the moment Description Quality made me soften the sweep's stopping rule. Coverage of the budget path survives through `max_iterations` 0 and -1, which no implementation can converge inside |
| coverage, missing species in `adiabatic_equilibrium` | taken, 1 test |
| coverage, `tolerance` domain and constructor ranges | declined, twenty-second and twenty-third time |

⭐ Description Quality and Test Fairness form a closed loop on any internal rule: state it
and the test is fair but the description is over-specified; soften it and the description
passes while the test becomes algorithm coupled. Escape by asserting only what holds under
BOTH readings, here a zero iteration budget rather than a tolerance no sweep could meet.

## Coverage suggestions round 18 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| positive but insufficient `max_iterations` | declined; this is the test Test Fairness failed in precheck round 10, and no fair version exists: a positive budget is only insufficient if the solver's trajectory is assumed, and an unreachable tolerance does not help because an exact solve sees no movement and converges under any tolerance |
| `tolerance` domain | declined, twenty-fourth time |
| constructor range validation | declined, twenty-fifth time |

Second advisory note asking for something a blocking check already rejected, after the
feasible negative extent. Both declines are recorded with the round number of the failure.

## Re-hardening after batch 1 (2026-08-09)

Dropped: `Shomate.fit`, 11 tests. Added: reconciliation of a multi segment model to the
segment holding 298.15 K, so enthalpy and entropy are continuous while heat capacity is not
shifted and `discontinuities()` still reports the raw jumps.

| Mutation of the new trap | Outcome |
| --- | --- |
| anchor is always the first segment | killed |
| reconcile only upward from the anchor | killed |
| offset sign flipped | killed |
| heat capacity reconciled too | killed |
| `discontinuities` reports the reconciled jump | killed |
| no reconciliation at all | killed |
| entropy left unreconciled | killed |
| a gap does not stop the accumulation | killed |

8 of 8. The trap is interdependent (reconciling by mutating the segments zeroes what
`discontinuities` must report) and misdirecting (a wrong anchor still yields continuous
enthalpy and still satisfies dH/dT = Cp, so the failure appears later as a wrong reaction
enthalpy). It also enables an invariant the old design could not satisfy: Kirchhoff's law
across a segment boundary, 500 to 1100 K.

## Platform precheck round 11 (2026-08-09)

| Check | Verdict | Action |
| --- | --- | --- |
| Test Fairness | FAIL, 16 of 202 | NASA7 now documented as taking its seven coefficients "as one sequence"; the zero default scoped to "in the searches" so it no longer overrides the blanket absent rule for `reaction_quotient` |

Fifteen of the sixteen were one unstated constructor container, inherited by every NASA7
fixture. The sixteenth was a contradiction introduced by the batch fix itself: a sentence
written for the solvers silently rewrote the quotient's contract. Scope every new rule to
the functions it is meant for.

## Word cap lifted (2026-08-09)

The user lifted the 500 word cap. Spent on the three things that had been cut only to fit,
nothing else:

| Restored | Why |
| --- | --- |
| `Shomate.fit`, 10 tests | dropped only to buy words for reconciliation; LOC margin 453 to 501 |
| which functions take a `pressure` | the last trim left `adiabatic_equilibrium` and `simultaneous_equilibrium` merely inferable, and batch 1 proved inferable is not enough |
| the composition solvers return a mapping | return shape was unstated, the same class as the `discontinuities` and tuple findings |

The 150 word per-paragraph wall-of-text limit is unaffected by the cap, so the description
was split into seven paragraphs, longest 107.

## Coverage suggestions round 19 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| gas-constant alias `R` | not a coverage gap but a description bug: "here `R`" read as an exported name. Reworded to "which the formulas below write as R". No alias, no test |
| public call signatures | taken behaviourally, 2 tests calling the six ordered functions fully positionally and comparing with the keyword call. Deliberately NOT `inspect.signature`, which would pin defaults the description does not state |
| piecewise entropy offsets | taken, 1 test mirroring the enthalpy version in both directions |
| positive but insufficient `max_iterations` | declined, third time; Test Fairness deleted exactly that test in precheck round 10 |

## Coverage suggestions round 20 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| `as_equilibrium` return class | taken, 1 test; the class is stated outright |
| piecewise entropy beyond a gap | taken, 1 test mirroring the enthalpy version |
| positive but insufficient `max_iterations` | declined, fourth time, deleted as unfair in precheck round 10 |
| non positive `tolerance` | declined, twenty-sixth time, probed and does not raise |

## Coverage suggestions round 21 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| non positive `pressure` into `gibbs_energy_at_composition` | taken, 1 test |
| positive but insufficient `max_iterations` | declined, fifth time |
| non positive `tolerance` | declined, twenty-seventh time |
| constructor range validation | declined, twenty-sixth time |

## Coverage suggestions round 22 (advisory, 2026-08-09)

| Suggestion | Action |
| --- | --- |
| inert dilution in `reaction_quotient` | taken, 2 tests; every earlier quotient case held only reacting species, so the total including inerts was untested. The diluted result is also asserted to differ from the undiluted one |
| positive but insufficient `max_iterations` | declined, sixth time |
| non positive `tolerance` | declined, twenty-eighth time |

## Coverage suggestions round 23 (advisory, 2026-08-09)

Two of the three standing declines were rested on "not stated, and no words to state it".
The cap is gone, so they became contract instead of declines.

| Suggestion | Action |
| --- | --- |
| non positive `tolerance` | TAKEN after 28 declines: the description now requires a positive tolerance, six searches guard it, 2 tests |
| constructor range validity | TAKEN after 26 declines: a model whose `T_min` exceeds `T_max` is rejected, 3 tests including equal limits being allowed |
| positive but insufficient `max_iterations` | declined, seventh time, and this one is permanent: it is unfixable rather than unstated |

LOC 501 to 515. ⭐ A decline whose reason is a budget expires when the budget does; re-read
old declines whenever a constraint is lifted.

## Batch 2, 9x Nova + 1x Orion, 2026-08-09: 0 of 10, but nearly solved

| Agent | Verdict | Failed of 225 |
| --- | --- | --- |
| Nova_1 | FAIL_WRONG_LOGIC | 1 |
| Nova_8 | FAIL_MISSED_REQUIREMENT | 2 |
| Nova_7 | FAIL_MISSED_REQUIREMENT | 4 |
| Nova_3 | FAIL_MISSED_REQUIREMENT | 5 |
| Nova_6 | FAIL_MISSED_REQUIREMENT | 6 |
| Nova_2 | FAIL_INTEGRATION_ERROR | 7 |
| Orion | FAIL_MISSED_REQUIREMENT | 7 |
| Nova_9 | FAIL_MISSED_REQUIREMENT | 8 |
| Nova_4 | FAIL_INTEGRATION_ERROR | 12 |
| Nova_5 | FAIL_MISSED_REQUIREMENT | 20 |

Baseline green in all ten. Error classes: 53 `ValueError`, 18 `TypeError`, 1 assertion. The
single assertion failure in the whole batch is the only substantive defect anywhere.

### The six unstated micro-contracts, now stated

| Gap | Runs hit | Clarification |
| --- | --- | --- |
| a root exactly on a bracket limit read as unbracketed | 9 | a root on either limit counts as bracketed |
| unsorted, overlapping or gapped segment lists rejected | 6-7 | segments are used as given and need not be sorted, contiguous or disjoint |
| absent or zero participant in the quotient returned zero | up to 6 | both quotient functions reject it, the activity makes the quotient undefined |
| `gibbs_energy_at_composition` argument order guessed | 3 | every signature is now written out |
| zero amount not skipped before the thermochemistry lookup | 2 | skipping happens before the lookup, so such a species needs none |
| zero `extent` treated as invalid | 2 | a zero extent leaves the temperature where it started |

### Replay projection

Nine of the ten runs have zero residual failures once the six are stated. The tenth keeps one
genuine defect, an `adiabatic_equilibrium` that does not conserve the mixture enthalpy.

### ⚠⚠ Difficulty verdict

Not one agent failed the reconciliation trap: all ten got the reference shifts, both
accumulation directions, the unshifted anchor and the raw jumps right. A fully stated
requirement is not a trap for these agents. Projected pass rate about 90 percent, far above
the 40 percent ceiling. Across two batches and 15 runs the only substantive error was one
broken coupled solve, which is the single evidence backed lever left.

## Second re-hardening: the coupled axis (2026-08-09)

Added `adiabatic_simultaneous_equilibrium`, the energy balance coupled to the multi-reaction
sweep: a fixpoint inside a bracket, where the composition is re-equilibrated at every
candidate temperature and every reaction must meet its own constant at the temperature found.

| Mutation | Outcome |
| --- | --- |
| equilibrate once at the initial temperature | killed |
| return the composition from the initial temperature | killed |
| equilibrate only the first reaction | killed |
| bracket ignores species only the reactions name | survives, equivalent under these fixtures |

Chosen because it is the ONLY place in fifteen runs across two batches where an agent made a
substantive error. It is a bet, not a guarantee: the reconciliation trap was equally well
stated and all ten agents implemented it correctly.

## Prompt and tests aligned, warning (2026-08-09)

Tests call the searches without a `tolerance`, so it is optional, but the description never
said so nor gave a default. Fixed by unifying rather than enumerating: `tolerance` is 1e-9
everywhere, `max_iterations` is 200, `pressure` is the standard pressure, all three stated,
and the 1e-12 and 1e-10 one-off defaults are gone. `inspect.signature` confirms every default
in the code matches the description.

## Description Quality round 2 (2026-08-09)

| Comment | Action |
| --- | --- |
| motivational preamble | shortened, the ask now leads |
| the R aside | its own short sentence; the earlier "here `R`" wording had been read as an exported name, so it cannot simply be dropped |
| the signature block | kept in full, reworded from a reference dump into a list of calls. Guessed argument order caused the 0/10 of batch 1 and still cost three runs in batch 2, and the comment itself asks to keep names and order |
| the catch-all error sentence | same coverage, written as a sentence. Several tests rest on its empty, out-of-range, unbracketed and unconverged clauses |

Coverage, all three taken and all free: five validation paths for
`adiabatic_simultaneous_equilibrium`, a test that an omitted `pressure` equals the standard
pressure across four functions, and `Shomate.fit` obeying the inverted range rule.

## Test Fairness round 8 (2026-08-09)

3 of 240 unfair, one cause: empty segment and reaction sequences are rejected but only an
empty MIXTURE was stated. Widened the error sentence to cover "an empty sequence of segments
or of reactions"; the three tests stand.

Coverage, one of two taken. Overlapping segments leave both unshifted (the overlap twin of the
gap test). DECLINED the non-convergence-after-positive-sweeps item: failing at
`max_iterations=1` assumes sweep-by-sweep iteration, so a direct coupled solve would fail a
test the prompt does not justify. Zero and negative counts remain covered.

## Coverage round (2026-08-09)

All three taken, all free. `reaction_quotient` rejects a zero amount participant directly;
`adiabatic_simultaneous_equilibrium` at 1e6 Pa meets every reaction constant, not merely a
higher temperature; and the three coupled solvers are called with `pressure`, `tolerance` and
`max_iterations` all omitted and matched against the explicit call. 244 tests.

## FP review, batch 3 (2026-08-09) - 4/4 Nova pass, 2 adjudicated false positive

| Finding | Verdict | Fix |
| --- | --- | --- |
| Nova 2, 3: `equilibrium_composition` insets the extent bracket by `tolerance*span`, so a large K root is excluded and it raises "could not bracket" | REAL, suite gap | large K (about 1e10) test asserting near complete conversion. Q = K cannot be asserted, my reference is only 0.22 accurate there; and a tighter tolerance shrinks their bad inset too, so it must run at the default |
| Nova 3: `simultaneous_equilibrium` gives up on a favoured chain (K about 1.5e4) with a valid equilibrium | REAL, suite gap | chain test asserting both constants at rel 1e-4; reference solves to 6e-6 |
| Nova 4: reconciliation across a gap disagrees with the reference | MY DESCRIPTION was wrong. Reference leaves a 10000 J/mol jump at a shared boundary beyond a gap, contradicting "so enthalpy and entropy are continuous" | reworded to the chain-of-shared-boundaries rule, gap or overlap breaks the chain, continuity claimed only where the chain reaches; three segment test added |
| adiabatic strongly favoured | DROPPED | the reference itself cannot bracket that enthalpy release, so it measured a reference limit |

4 of 4 is far too easy. These three discriminators double as the hardening lever, all on
solver robustness the suite had never probed.

## FP review, batch 4 (2026-08-09) - 2 Nova, 1 adjudicated false positive

Both findings, plus two of the four corners raised against the run that passed cleanly, are one
hole: a species that cancels to zero net stoichiometry.

| Finding | Verdict | Fix |
| --- | --- | --- |
| `reaction_quotient` and the reaction quantities reject or look up a spectator | MY WORD "participating" was ambiguous. A spectator enters as activity**0 and cannot make the quotient undefined; the reference skips it everywhere | reworded to "a species of non zero net stoichiometry" plus an explicit sentence that a cancelled species needs neither amount nor thermochemistry; 3 tests |
| `equilibrium_composition` invents a `tolerance < 1` rule | description only ever said positive, reference accepts 1.0 and 2.0 | test walking 0.5, 1.0, 2.0 |
| 1e-15 inset floor at 1e-20 mole amounts | DECLINED | pathological; pinning it ties the suite to my floating point choices |
| log K flat to machine precision across the bracket | DECLINED | same |

The adjudicator on the CLEAN run noted that
`test_reaction_nets_a_species_present_on_both_sides` deliberately keeps C in thermo, so the
suite read as NOT requiring the skip. Now pinned the other way.

## Description Quality round 3 (2026-08-09)

Same four items a third time; all four taken.

| Comment | Action |
| --- | --- |
| motivational clause | deleted |
| signature roll-call | lead-in reworded to a contract ("keep these names and this argument order exactly"); every signature kept |
| "arguments therefore run in this order" | DELETED as truly redundant, the signature list already fixes the order; only the zero-start residue survives |
| error catalog | condensed, not deleted. Its empty-mixture, empty-sequence, out-of-range, unbracketed and unconverged nouns are what make Test-Fairness-flagged tests fair, and the empty-sequence clause was added last round to clear three of them |

## Coverage round (2026-08-09, post-FP)

| Item | Action |
| --- | --- |
| solver temperature inputs | TAKEN, all five solvers reject an out-of-range starting temperature directly |
| piecewise duplicate / shared reference | TAKEN, duplicate equal ranges and two segments both holding 298.15 K, pinning first-wins and first-holder-anchors |
| fit input validity | DECLINED. Probed: none of it raises `ValueError`. NaN temperature gives `LinAlgError`, NaN heat capacity returns a garbage model silently, five duplicate temperatures least-square fine. Making it true needs a new description sentence plus new validation code, and pinning `LinAlgError` would be an undocumented error class |

## Coverage round (2026-08-09, second post-FP)

| Item | Action |
| --- | --- |
| noisy fit | TAKEN. Asserts the STATED T_ref exactness plus loose tracking within 3x the noise. Deliberately does NOT assert the residual sum (3.7e-13), which is a least-squares signature and would pin an algorithm the description no longer names |
| reversed segments sharing a boundary | TAKEN. "Consecutive" means consecutive in caller order: no discontinuity, no shift, selection still walks the given order |
| nonconvergent positive budget | DECLINED, second time, same reason. The description only says the sweeps give up after `max_iterations`; a direct coupled solve converges in one sweep, so no fixture makes exhaustion fair - "deliberately difficult" is solver relative |

## Test Fairness round 9 (2026-08-09)

1 of 256 unfair, and it is the test the previous COVERAGE round asked for. The checkers pulled
opposite ways; fairness is right that sharing was never stated to be directional.

| Item | Action |
| --- | --- |
| reversed segments sharing a boundary | description fixed, not the test: "meaning the earlier one's `T_max` equals the later one's `T_min`". Governs the chain rule too |
| cancelled species with a mole-changing net | TAKEN and it matters: with Delta nu = 0 the spectator cancelled algebraically. With Reaction({A:1,B:2},{A:1,C:1}) Q is 0.75 absent vs 3.0 present, because a present spectator counts in the total moles like an inert. Now stated, since "takes no part in any reaction quantity" could be read as leaving the denominator |

Two authoring errors caught by the suite: asserted -5000 for an enthalpy whose Delta nu is -1
(heat capacities no longer cancel), then repaired the WRONG test because the identical
assertion line appears earlier in the Delta nu = 0 test.

## Test Fairness round 10 (2026-08-09)

2 of 257 unfair, both fixed by stating the contract rather than deleting a test.

| Item | Action |
| --- | --- |
| `as_equilibrium` `.reac`/`.prod` | only the constant was promised. Now says it carries "the reaction's own reactants and products"; the field names stay repo-discoverable, as the passing `.param` sibling already relies on |
| noisy fit policy | SECOND test in a row that one checker requested and the other rejected. "matches the tabulated data" does not define a policy for data no Shomate fits exactly, so the description now says "is the least squares fit". This re-adds a phrase Description Quality once removed, but fairness named it in its own quality note and fairness is the FAIL gate. With it stated, the 0.15 envelope is a consequence, not a policy |
| cancelled species in the searches | TAKEN, free. Absent from both `amounts` and `thermo` blocks neither search, and returns at zero since the result names every reaction species |
| NASA7 equal endpoints | TAKEN, free. Mirrors the Shomate equal-limits test |

## Coverage round (2026-08-09, post-fairness-10)

Both taken, both free, both discriminating.

| Item | Action |
| --- | --- |
| lowest anchor not first listed | TAKEN. Needs THREE segments: directional sharing means a chain only forms on ascending caller order, so a reversed pair leaves everything raw and the anchor unobservable. With [2000-3000, 3000-4000, 500-1000] the anchor is the last-listed 500-1000 by lowest `T_min`, the chain to it is broken, so 3000-4000 stays RAW; a first-listed anchor would have shifted it by the 3000 K jump, which the test asserts is non-zero |
| degenerate endpoint bracket | TAKEN. `T_min == T_max` holding the root returns it, the one-point case of the stated endpoint rule; pairs with the existing test where the same bracket misses the root and raises |

## Agent runs

### Batch 1, 5x Nova, 2026-08-09: 0 of 5. UNSOLVABLE AS SHIPPED.

| Agent | Verdict | New tests | Failed | Shape or contract | Genuine physics | Blame |
| --- | --- | --- | --- | --- | --- | --- |
| Nova_1 | FAIL_AMBIGUOUS_TASK | 204 | 52 | 52 | 0 | unfair: no |
| Nova_2 | FAIL_TEST_MISMATCH | 204 | 12 | 12 | 0 | unfair: yes |
| Nova_3 | FAIL_TEST_MISMATCH | 204 | 50 | 50 | 0 | unfair: yes |
| Nova_4 | FAIL_TEST_MISMATCH | 204 | 57 | 57 | 0 | unfair: yes |
| Nova_5 | FAIL_MISSED_REQUIREMENT | 204 | 30 | 30 | 0 | unfair: no |

Every baseline suite passed (555 tests) in every run, so the environment is sound. Across
all five runs the error classes were 90 `TypeError` and 111 `ValueError`, and EVERY failure
traces to the call contract: positional argument order for the solvers, `discontinuities`
written as a property instead of a method, and a reaction product absent from `amounts`.
**Not one assertion about a thermodynamic value failed in any run.** Three evaluators
flagged `agent_blame_unfair`, and four called the description unclear on this exact point.

### Diagnosis and fix

The description named every function and gave every formula but never gave a signature.
That is the API-shape lottery from memory `olympus-python-api-shape-coin-flip`, and it cost
the whole batch. The description now states the argument order as a rule, gives the two
signatures that do not follow it, writes `heat_capacity(T)`, `segment_at(T)`,
`discontinuities()` and `gibbs_energy(T)` with their call parentheses, and says a reaction
species missing from `amounts` starts at zero. 490 words. An automated check confirms all
19 public functions in the solution obey the stated ordering rule.

### Solvability proof by replay

Nova_2's own patch was replayed against the suite with only the two documented call shapes
adapted, nothing else touched: **204 of 204 passed**, and the base suite stayed green. The
physics, fitting, and both coupled solvers that agent wrote were already correct.

### FP check, closed

Probes run against that passing implementation with oracles built from the description and
from closed-form thermodynamics, never from the test suite:

| Probe | Result |
| --- | --- |
| models vs the description's own formulas, 62 points | worst relative deviation 0.0 |
| equilibrium constant vs a closed form | relative deviation 0.0 |
| `equilibrium_composition` at 6e5 Pa, quotient over constant | 1 + 5.5e-13 |
| `adiabatic_temperature` whole-mixture enthalpy balance | imbalance 1.5e-11 J, and the temperature matches an independent closed form to 6 decimals |

The passing implementation genuinely solves the described task. No false positive.

### ⚠ Difficulty risk opened by this batch

All five agents got the thermodynamics right; the only thing separating them from a pass was
the contract. With the contract stated, the expected pass rate is high and may exceed the
40 percent ceiling. The difficulty this submission was measuring had become the API-shape
lottery, which the rules class as fake difficulty, and the earlier Task Quality fix had
already removed the kJ-versus-J and NASA-reference traps. Re-hardening needs a trap that
survives being fully specified.
