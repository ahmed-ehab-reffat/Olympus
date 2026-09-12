# feedback.md — sfepy-modal-analysis

## Summary

Olympus submission against [sfepy/sfepy](https://github.com/sfepy/sfepy) at
`70bbaabb551de75a9a56352ff1a2a4b05f05ff65`. Adds `sfepy.discrete.modal`: the
generalized eigenvalue solve wired into `Problem`/`Equations`/`Variables`, plus
the derived quantities a vibration engineer needs (normalizations, rigid body
directions, participation factors and effective masses, MAC and pairing,
harmonic and base-harmonic response, response spectrum combination, exact
piecewise-linear transient response, Rayleigh damping).

- solution: 3 files, 451 human-effective LOC (728 raw)
- tests: 108 new tests, all fail on base, all pass with the solution
- base suite: 221 existing tests, green offline before and after the patch

## Pick gates

| Gate | Result |
|---|---|
| stars / license / language | 837, BSD-3-Clause, Python |
| activity | 45 source commits in the trailing 12 months |
| repo quota (ours) | 0 prior submissions in any dir |
| exclusivity | `gh pr list --state all` over modal / eigen / participation / response spectrum / frequency response / damping returns only merged example and solver-config work; the repo has a single branch, `master` |
| dedup | no approved, rejected or in-flight problem covers modal analysis |
| maintainer philosophy | no closed issue declines a modal API; `sfepy/examples/linear_elasticity/modal_analysis.py` is a script, not a library surface |
| env quality | vanilla suite 221 passed / 0 failed offline as uid 1000 in 15m44s |
| flakiness | see the determinism runs below |

## Iteration history

### Round 1 (authoring)

First run of the new tests: 97 passed, 11 failed. Causes and fixes:

1. `assemble_matrices` ignored the linear combination operator, so the assembled
   matrices were in the essential-condition space while `make_full_vec` expects
   the linear-combination space. Fixed by applying `mtx_lcbc` on both sides.
   This is also the sharpest architectural trap in the problem.
2. Guards demanding a positive modal stiffness or a positive frequency never
   fire: a free-free block has rigid modes with eigenvalues around `1e-6`, not
   zero. Removed the guards and their four tests rather than pin a tolerance.
3. Matrix symmetry compared with `nm.allclose`, whose absolute tolerance is
   swamped by round-off on entries of order `1e10`. Switched to a relative
   bound.
4. MAC of a solution with itself is not the identity: the modes are M-orthogonal,
   not orthogonal. Test now asserts the diagonal is one and is the row maximum.
5. `cqc` versus `srss` compared with the default `atol`, which hid a 0.2 percent
   difference on entries of order `5e-8`. Switched to a relative comparison.
6. The two-unknown-variable fixture passed the wrong argument names to
   `Term.new`.

### Round 2 (FP closure)

Walked the description in both directions before any agent run. Six requirements
had no discriminating test; each got one:

- the names are reachable from `sfepy.discrete`, not only `sfepy.discrete.modal`
- the assembled matrices are sized in the linear-combination space
- `effective_masses`, `mass_fractions` and `cumulative_mass_fractions` are
  refused with linear combination conditions, not only `participation_factors`
- a one dimensional problem is refused by `rigid_body_vectors`
- decreasing time samples are refused
- the clipping of a negative eigenvalue was dropped from the description instead,
  since no fixture reliably produces one

Nothing in the tests asserts behavior the description does not state.

### Round 3 (platform pre-checks)

Three findings from the automated pre-checks, all addressed.

1. **Install mode failed.** The image only built the C extensions in place, so
   `sfepy` was not on `sys.path` outside `/app` and the grader's invocation was
   left to guesswork. The Dockerfile now runs
   `pip install --no-build-isolation --no-deps -e .` and only then
   `setup.py build_ext --inplace`. Both steps are needed: skbuild's develop mode
   leaves the compiled modules under `_skbuild`, so without the in-place build
   `import sfepy.discrete` dies on `cmapping`. Verified from `/` that
   `sfepy.__file__` is `/app/sfepy/__init__.py` and the extension resolves to the
   source tree.
2. **Version pinning warned.** Every pip requirement is now an exact `==` pin, at
   the versions the validated build resolved.
3. **Two interface clauses warned.** `static_correction(load)` now reads as a
   `ModalSolution` method in its own right rather than only appearing inside the
   `frequency_response` sentence, and `create_output` now states that each entry
   is the output data `Problem` saves for the variable, one row per mesh vertex
   and one column per component.

The remaining Dockerfile warning is the explicit `setup.py build_ext --inplace`.
It is unavoidable: sfepy ships C extensions built through scikit-build and cmake,
and the container has no network at run time.

### Round 4 (coverage suggestions)

Five advisory suggestions from the pre-check, all taken. Twelve tests added,
108 to 120, and none of them found a bug in the reference.

- wrong-size refusals asserted directly on `expand`, `project`,
  `frequency_response`, `static_correction` and the transient load and starting
  state, not only on `restrict`
- the static correction is the same vector added at 0, 7 and 31 Hz, not only in
  the zero-frequency case where the total collapses to the exact static solution
- a ramp history checked against the closed form of an undamped mode driven by a
  linearly increasing load, which is what pins the piecewise-linear reading
- the sign convention asserted on the FIRST index attaining the largest
  magnitude, so a tie is resolved by the lowest index rather than by whatever
  `argmax` happens to return
- `assemble_matrices` called directly with a missing name and with one name for
  both, and `Problem.solve_modes` called with custom equation names

The description sentence about a wrongly sized vector was widened at the same
time: it read as if it covered only `expand`, `restrict` and `project`, and now
covers every method that takes a load or a starting state.

### Round 5 (coverage suggestions, second pass)

Six more advisory suggestions, all taken. Thirteen tests added, 120 to 133.
Again none of them found a bug in the reference; one was my own test bug (a
4x5 MAC block compared against a 4x4 diagonal).

- both assembled matrices compared entry by entry against an independent
  assembly through `Equations.evaluate`, and under linear combination
  conditions against `mtx_lcbc.T @ K @ mtx_lcbc`
- the CQC result compared against the double sum written out from the
  prompt formula at a shared ratio of 0.07, not only against SRSS
- `base_frequency_response` checked against its closed form at 9 Hz, plus
  centre dependence of the rotational direction, the centre independence of a
  translational one, negative frequencies and both bad damping forms
- `expand` on a linear combination problem compared against
  `mtx_lcbc @ reduced` scattered into the free degrees of freedom
- MAC computed entry by entry between two genuinely different solutions of the
  same mesh, with `pair` checked against the row maxima of that matrix
- Rayleigh refusals for a zero first frequency, two equal frequencies and a
  negative frequency in the ratios

One description clause moved with them: `base_frequency_response` said only that
it is "the same sum", so it now says it takes the same frequencies and damping
and refuses them the same way.

### Round 6 (coverage suggestions, third pass)

Four more suggestions, all taken. Thirteen more tests, 133 to 137.

- `solve_modes(problem)` and `Problem.solve_modes()` called bare, so the
  `n_modes=6` default and both equation-name defaults are pinned together
- `modal_masses` and `modal_stiffnesses` asserted mode by mode against
  `phi^T M phi` and `phi^T K phi`, on the returned solution and again after
  `normalize('max')` where the values are no longer one
- `create_output` exercised on an order 2 field, where the field carries 65
  nodes and the mesh 21: each saved mode must still hold 21 rows
- the Rayleigh coefficients compared against the two-by-two proportional
  damping system solved independently, which catches a pair of errors that
  cancel in the round trip

### Round 7 (coverage suggestions, fourth pass)

Five suggestions, all taken, 137 tests to 146. Three of them moved the
description, which is the useful part of this round.

- `transient_response` now has the damping contract asserted directly: negative
  refused, a wrong per-mode length refused, and a valid per-mode vector below
  one accepted. The description stated the damping rule only under
  `frequency_response`, so it now reads "here and wherever else one is taken".
- `rayleigh_damping_ratios` is asserted to take frequencies in any order. The
  refusal sentence bundled ordering with positivity across both helpers and
  could be read as refusing an unsorted list, so it is now split per function.
- an empty solution from `select` is exercised across every method. All of them
  answer: per-mode arrays with no rows, an empty output, zero responses, and a
  static correction that is the whole static response, since no mode carries any
  of it. That contract is now a sentence in the description rather than an
  accident of the implementation.
- `response_spectrum` and `base_frequency_response` now cover the upper
  direction bound as well as the lower, and all six directions of a three
  dimensional problem.
- the transient exactness check now includes a three segment, non monotone
  history compared against the superposition of ramp responses, which is what
  actually pins the piecewise-linear reading; the earlier ramp case could not
  distinguish it from a single-slope treatment.

### Round 8 (coverage suggestions, fifth pass)

Four suggestions, all taken, 146 tests to 152. Two moved the description.

- `response_spectrum` now asserts the shared damping contract for every rule,
  not only for `cqc`: negative refused, a length that is neither one nor the
  mode count refused under `srss`, `abssum` and `cqc` alike, and a valid
  per-mode vector accepted outside `cqc`.
- `base_frequency_response` and `response_spectrum` are asserted to refuse a
  linear combination problem, which they do through the participation factors
  they rest on. The description refused "all four" participation quantities and
  said nothing about the methods built on them, so it now adds "as is anything
  below that rests on them".
- `solve_modes` is asserted to bound the mode count by the linear-combination
  reduced count, not the larger essential-condition count: 21 modes are
  accepted and 22 refused where 24 degrees of freedom survive the essential
  conditions. An implementation bounding on the wrong count passes every other
  test. The description said "more than there are free degrees of freedom",
  which names the wrong space, and now says "more than that reduced space
  holds".
- `rayleigh_coefficients` now covers a negative first ratio and a second
  frequency that is zero or negative, matching the existing second-ratio and
  first-frequency cases.

### Round 9 (coverage suggestions, sixth pass)

Five suggestions, all taken, 152 tests to 156. One moved the description.

- the zero-mode case now also asserts `base_frequency_response` is zero, the one
  modal response the empty tests had skipped
- `create_output` entries are compared against the mode vectors themselves,
  not only checked for key, type and shape
- a wrong-length `centre` is asserted refused through every method that takes
  one, not only `rigid_body_vectors`. The description attached that refusal to
  `rigid_body_vectors` alone, so it now reads "wherever one is taken".
- `base_frequency_response` accepts a correctly sized per-mode damping vector,
  the success case beside the existing failure ones
- `rayleigh_coefficients` refuses a negative first frequency, the last
  unexercised corner of its four-argument validation

### Round 10 (coverage suggestions, seventh pass)

Five suggestions, four taken, 156 tests to 160. No description change needed.

- the component check is now exercised from both sides: a 2D problem with a
  three component field and a 3D problem with a two component one. The old
  scalar-only case passed against an implementation that merely rejects scalar
  fields, which is the weaker rule.
- `Problem.solve_modes` is driven through every argument positionally, by
  keyword, and with the count defaulted while both names are custom, rather
  than inferring forwarding from one matching call
- all four normalization kinds exercised on a zero-mode solution, not only
  `max`, with the vector shape checked each time
- `rayleigh_coefficients` fed frequencies straight out of a solution, which is
  how a caller reaches it, so numpy scalars are covered

The fifth suggestion asked for a test of array-like scalar inputs to the
Rayleigh helpers. I did not add one: the description says two frequencies and
two ratios and states no refusal for anything else, so asserting either
acceptance or rejection would pin behavior the prompt does not define. The
numpy-scalar case above is the part of it the prompt does cover.

### Round 11 (coverage suggestions, eighth pass)

Three suggestions, all taken, 160 tests to 163. No description change needed.

- `cqc` accepts a per-mode array whose entries are all equal and returns what
  the scalar gives, the acceptance side of "one ratio shared by every mode"
- a damped ramp checked against the closed form of a damped mode under a
  linearly increasing load. This is the one path the transient tests had not
  crossed: forcing and damping were each exact against a reference, but only
  separately, so the damped recurrence coefficients were unverified against an
  independent formula. They match to 1e-8 relative.
- `rayleigh_coefficients` accepts zero damping targets and returns zero
  coefficients, guarding an implementation that demands strictly positive
  ratios where the prompt refuses only negative ones

### Round 12 (coverage suggestions, ninth pass)

Four suggestions, all taken, 163 tests to 167. One moved the description.

- the zero-mode case now pins `eigenvalues`, `omegas`, `frequencies` and both
  vector arrays, not only the derived quantities
- `select` covered with an upper bound alone, and with a count larger than the
  band leaves, which simply keeps them all
- `transient_response` given the same record shifted five seconds later returns
  the same history, and honours the initial state at the first sample. Only the
  spacing enters the recurrence, so the description now says so rather than
  leaving a reader to infer that the origin is free.
- `assemble_matrices` asserted to return sparse matrices through
  `scipy.sparse.issparse`, with and without linear combination conditions,
  rather than relying on `.todense()` existing

### Round 13 (coverage suggestions, tenth pass)

Two suggestions. The second found a defect in the solution, not a gap in the
tests. 167 tests to 171, and the solution changed for the first time since it
was written.

- the dynamic responses are asserted to be invariant under `normalize('max')`:
  `frequency_response` with and without the static correction,
  `static_correction`, `base_frequency_response` and `transient_response` all
  agree with the mass-normalized solution. Nothing silently assumes unit modal
  masses.
- `frequency_response`, `static_correction` and `transient_response` routed
  their load through the public `restrict`, which refuses a problem with linear
  combination conditions, so the whole load-driven family was unusable there and
  neither the tests nor the description said so. A load reduces through the
  TRANSPOSE of the operator, unlike a displacement, so the three now use an
  internal load restriction that applies `mtx_lcbc.T`. They are checked against
  a direct solve and against the constrained region staying rigid. `restrict`,
  `project` and the participation quantities keep refusing, since a displacement
  does not reduce that way, and a transient starting state, which rests on the
  projection, is refused and now tested.

Two description sentences moved with it: the projection joins restriction in the
refusal, and the load-reduction rule with its starting-state exception is
stated.

### Round 14 (Test Fairness FAIL + coverage suggestions)

Test Fairness failed 4 of 172 on one point: four assertions pin the return form
of `pair(other)` as two parallel arrays in index-then-value order, including the
empty shapes, while the description gave only the pairing semantics and the
repository has no prior `pair`/`mac` API to infer the container from.

Fixed on the description side, not by loosening the tests. The return form is a
real part of the contract, the same as the shapes stated for every other method,
so the sentence now reads: `pair(other)` returns two arrays holding one entry
per mode, the index of the other mode of the largest such value, and that value.
That pins order, count and the empty shapes together.

Three coverage suggestions came with it, all taken, 171 tests to 172:

- a transient starting state under linear combination conditions is refused for
  `velocity` as well as `displacement`
- the transient damping refusal is exercised above one and in a per-mode vector,
  not only exactly at one
- `expand` is given a wrong reduced size under linear combination conditions, so
  the size check is seen against the linear-combination count rather than the
  ordinary active one

### Round 15 (Test Fairness FAIL + coverage suggestions)

Test Fairness failed 1 of 172. `test_restrict_is_refused_with_a_linear_combination`
reached for `sol.problem` to get the full DOF count, and the description's list
of what a solution carries does not include a `problem` attribute. The refusal
under test was fair; the setup was not, and an implementation storing the
problem privately would have failed on a line that is not the point of the test.
Fixed by keeping the fixture in the test and asking it for the count.

Three coverage suggestions, all taken, 172 tests to 175:

- `pair` against a solution with no modes was undefined: row-wise `argmax` over
  zero columns has no answer. It now refuses, the description says the other
  solution must hold a mode, and both directions are tested. Pairing FROM an
  empty solution still works, since that has no rows to fill.
- `rayleigh_damping_ratios` accepts negative coefficients, which is the reading
  of a sentence that restricts only the frequencies
- `solve_modes` accepts a one dimensional field with one component, the positive
  side of the component-per-dimension rule whose refusals were already covered

Effective LOC 460 to 463.

### Round 16 (description length)

The length check failed at 1119 words against a 1000 hard cap. Compressed to
998 with no requirement dropped and no test or code touched.

The saving came from structure, not from cutting behaviour. The refusals had
been stated inline, one or two per paragraph, each costing a clause of framing
("... is refused", "Every refusal above raises `ValueError`"). They are now one
list at the end covering all twenty classes, and the prose paragraphs carry only
behaviour. A grep for each of the twenty confirms every one survives, and the
behavioural spec was walked method by method afterwards. Longest paragraph is
118 words, so the wall-of-text signal is clear too.

This also fixed a loose thread the inline form had hidden: the `cqc` shared
ratio was written as "needs one ratio shared by every mode" and its refusal hung
on the closing "every refusal above" sentence. With that sentence gone the rule
would have been unanchored, so it is now named in the list.

### Round 17 (Test Fairness FAIL, second)

Two assertions failed on pinned magic numbers. Both were mine and neither was
needed to check the API.

- `test_free_block_has_three_rigid_body_modes` asserted the first three
  frequencies fall below `1e-3` times the fourth, and that the fourth exceeds
  1 Hz. The `1e-3` was a separation ratio I invented and the 1 Hz was an
  absolute cutoff tied to nothing in the prompt. Rewritten against modal
  stiffness instead: a rigid mode has no strain energy, so the first three
  `phi^T K phi` are numerical zero against the fourth, and the rest are
  positive. That is a roundoff tolerance on a computed scale, the same shape as
  the kernel test the reviewer accepted, not a physical threshold.
- `test_mac_matches_an_independent_computation` required some off-diagonal to
  exceed `1e-6`, a guard against accidentally comparing a model with itself.
  The guard is worth keeping but belongs on the fixtures, so it now asserts the
  two solutions have different frequencies.

One coverage suggestion taken, 175 tests to 176: `Problem.solve_modes` is
checked to forward the missing-equation, duplicate-name and bad-count refusals.

The other suggestion asked whether `assemble_matrices` performs the
unknown-variable and component validation. It does not, and the description
attaches that requirement to `solve_modes`, so a test either way would pin
behaviour the prompt does not define. Left alone, for the same reason the
Rayleigh array-shape suggestion was left alone in round 10.

### Round 18 (coverage suggestions)

Two suggestions, 176 tests to 177.

- The assembly-side validation question came back a second time, so it is now
  settled in the description rather than left to inference: `solve_modes`, not
  the assembly, needs the one unknown vector variable. `assemble_matrices` is
  shown assembling a problem that carries a second unknown, with `solve_modes`
  refusing the same problem, so the division is asserted from both sides.
  I first wrote the matching component-count case too, but the mismatched
  fixture cannot be assembled at all: a three component field in two dimensions
  makes the material coefficient shape invalid inside `dw_dot`. That is a
  fixture limit, not a contract question, so the case was dropped and the
  component rule stays covered by the `solve_modes` refusals.
- both MAC orientations against an empty solution are now checked next to the
  pairing refusal: `(4,0)`, `(0,4)` and `(0,0)`.

The description gained six words and lost eight elsewhere, so it stays at 998.

### Round 19 (Solution Quality PASS, two real defects)

The quality review passed but named two edge cases from reading the code. Both
reproduce exactly as described, and both were breaking a stated requirement
with no test to catch it. 177 tests to 178.

- `create_output` called `variables.set_state` with a full DOF vector, and
  `Variables.set_full_state` refuses that outright when the problem has linear
  combination conditions ("cannot set full DOF vector with LCBCs!"). So the
  method raised on exactly the problems whose mode expansion is the hardest
  part of the feature, while the description specifies it generically. Fixed
  with `force=True`, which is what that flag is for, and covered by a test that
  saves the modes of the rigid-region problem.
- `response_spectrum(rule='cqc')` read `ratios[0]` before using it, so a
  zero-mode solution raised `IndexError` instead of returning zeros. The
  description says every modal response of an empty solution is zero, and my
  own empty-response test only exercised the default `srss`. The cqc path now
  returns zeros for a zero-mode solution and the test loops over all three
  rules.

Both were mine to catch: the first because I tested `create_output` only on
unconstrained problems, the second because I checked the empty contract on one
rule out of three. Effective LOC 463 to 465.

### Round 20 (Solution Quality, chasing 3/3)

The second quality review ran against the 177-test artifact, so the CQC
zero-mode gap it names is the one already fixed in round 19; the shipped patch
returns zeros there for all three rules. That was the only Comprehensiveness
deduction, so nothing further was needed for it.

The two Code Quality deductions were real and are now closed. No test changed.

- The eigensolve hardcoded a scipy call and its own sort. It now builds an
  `eig.scipy` conf and goes through `Solver.any_from_conf`, the abstraction the
  repository already uses for this, `eigh`/`SM` under the dense limit and
  shift-inverted `eigsh`/`LM` above it. The solver does the ascending sort and
  the truncation itself, so that bookkeeping left the module.
- `frequency_response` and `base_frequency_response` carried the same loop over
  frequencies, the same denominator and the same resonance guard. Both now call
  `_harmonic_sum`, and the shared frequency validation moved to
  `_frequencies`. The two methods differ only in where their modal load comes
  from, which is the only thing that ever differed.

Effective LOC 465 to 453, still clear of the floor. Removing duplication costs
LOC; padding it back would be the wrong trade.

### Round 21 (Description Quality FAIL)

Five style comments, all fixed rather than contested. The check confirmed none
of the flagged wording is depended on by the test patch, so the prose could be
rewritten freely, and every comment was fair: the description had drifted into
generated-spec register while I was compressing it under the word cap.

- the attribute list read as an API sentence with a dangling "their square
  roots". It now names `ModalSolution` as the subject and says the square root
  of each, with the reduced and full mode shapes named as what they are.
- "here and wherever else one is taken" was an editorial aside. The damping rule
  is now one clean sentence: any damping argument takes either a single ratio or
  one per mode.
- the base response opened with "is the same sum, under the same frequencies and
  damping", which restates the signature. It now says it uses that same modal
  denominator with the modal load set to minus the participation factor.
- "`ValueError` refuses:" was robotic; it reads "Raise `ValueError` for" now.
- "It also refuses ..." was a second near-duplicate lead-in, an artifact of
  splitting the list to stay under 150 words per paragraph. The split now falls
  on a real seam: the structural refusals in one paragraph, the dynamic methods
  and the two Rayleigh helpers in the next, each introduced by what it covers
  rather than by repeating the verb.

All twenty-two refusal classes were re-grepped afterwards and every one
survives. 998 words, longest paragraph 125.

### Round 22 (first agent batch: 0/6, unsolvable)

Six runs, zero passes. Not a difficulty problem, a specification defect, and one
I introduced myself.

Round 16 compressed the description by folding every scattered refusal into a
single `ValueError` list. The linear-combination refusals never made it into
that list. What remained was one sentence ending "`restrict`, `project`, the
four participation quantities and anything resting on them do not", which says
those operations do not hold but never says they raise. Four tests rest on it.
They failed in 6, 6, 6 and 5 of the six runs, and Nova_5 failed nothing else.

Fixed by naming them and saying what happens: everything mapping a full vector
the other way raises `ValueError` there, listing `restrict`, `project`, the four
participation quantities, `base_frequency_response`, `response_spectrum` and a
transient starting state.

Two orientation gaps came out of the same batch and are now stated:

- the mode arrays hold a column per mode. Nova_4 stored them row-wise and lost
  37 tests to it, and the earlier fairness review had already marked the
  column convention as "standard external semantics" rather than prompt-stated.
  That was a warning I did not act on.
- `frequency_response` returns a row per frequency and `transient_response` a
  row per sample. Orion transposed both.

Replaying the recorded failures against the fixed text: Nova_5 passes outright,
Nova_1 falls to one failure. That is 1/6 with the transient-exactness cluster,
the deliberate difficulty, still failing the other five. No test and no solution
line changed; the whole fix is description.

### Round 23 (coverage suggestions)

Three suggestions, all taken, 178 tests to 180. No description change.

- `assemble_matrices` is shown succeeding on a scalar-field problem while
  `solve_modes` refuses the same one, which pins the division the description
  now states from the assembly side too. The component-mismatch half of the
  suggestion still cannot be tested: a three component field in two dimensions
  makes the `dw_dot` coefficient shape invalid, so that fixture never reaches
  the assembly. The scalar case carries the point.
- `frequency_response` with nonzero damping and max-normalized modes is now
  compared against the stated formula term by term, with an assertion that the
  modal masses are not one so the non-unit path is really exercised. The
  damped harmonic sum previously had only invariance and zero-frequency checks
  on it, while the base response had an exact one.
- `Problem.solve_modes` is checked to return the same reduced vectors and the
  same assembled matrices, not only the frequencies and full vectors.

### Round 24 (coverage suggestions)

Three suggestions, all taken, 180 tests to 183. Two of the three were worth
more than coverage.

- Nonzero essential values. The description says a mode is zero where an
  essential condition fixes it, and the reference gets that by forcing the value
  during expansion. Every fixture until now prescribed zero, so the requirement
  and the default were indistinguishable. A fixture prescribing 0.5 now
  separates them: an implementation that expands without forcing carries 0.5
  into the mode and fails. That is a real discriminator the suite was missing.
- Repeated eigenvalues. The free-free block has a threefold zero eigenvalue, so
  its first three mode vectors are an arbitrary basis of the rigid space and no
  test may pin them individually. The new test compares the two subspaces in
  both directions by projection, which is basis independent. My first attempt
  also asserted the rigid basis is Euclidean-orthogonal to the higher modes;
  that is false, the modes are M-orthogonal, and the failure was mine.
- Combined initial state. Displacement and velocity supplied together with
  damping, checked against the closed form and against the sum of the separate
  free and forced runs. My first analytic reference double counted the
  `zeta*omega*q0` term, which the exact-response comparison caught immediately.

Both failures this round were test bugs, not solution bugs.

### Round 25 (second batch: 0/5, one pin left)

The LCBC fix landed: zero linear-combination failures across five runs, against
four such tests failing in five or six of six runs before it. What remained was
the many-small-pins shape the playbook warns about, two to five failures per run
on largely different tests.

One pin dominated. The two one-dimensional tests fail together in three of five
runs, from a single cause: the agent refuses a 1D problem in `solve_modes`, so
the rigid-vector test dies in its setup line as well. That is a fair reading of
a description that talks about vector fields and about two and three dimensions
throughout, and never says a one dimensional problem is welcome.

I cut them rather than specify them. A one dimensional vector field is a
degenerate corner that carries no part of modal analysis, the tests were pinning
a coin flip rather than a behaviour, and the matching refusal left the
description with them. 183 tests to 181, 992 words.

Nova_1 and Nova_2 fail nothing else, so this puts the batch at 2/5. That is at
the top of the band rather than in its middle, and the transient exactness
cluster is what still holds Nova_3, Nova_4 and Nova_5 out.

### Round 26 (coverage suggestions)

Two suggestions, both taken, 181 tests to 184.

- the LCBC load-driven family was checked at zero frequency against a direct
  solve, and qualitatively in the transient. It now also has a damped frequency
  response at 9 Hz and a ramp transient, each compared term by term against the
  stated formula with the load reduced by `mtx_lcbc.T`. That is the transpose
  reduction asserted on the damped path, not only the static one.
- the 3D rigid columns had every rotation checked but the translations only in
  two dimensions. The first three 3D columns are now asserted to be the unit
  x, y and z translations, which is the translations-then-rotations order the
  description promises.

A note on the risk, since the batch sits at 2/5. Every test added after a batch
can only lower the pass rate, and I cannot re-measure without another run. Both
of these are formula checks that a correct implementation satisfies, and the two
passing agents cleared every comparable formula test, so the expectation is no
change. It is an expectation, not a measurement.

### Round 27 (coverage suggestions)

Two suggestions, both taken, 184 tests to 185.

- `solve_modes` and `select` are now refused a negative count as well as zero.
  The description says fewer than one mode and a count below one, and only the
  zero boundary was exercised.
- the spacing-only transient test shifted the record five seconds later. It now
  also shifts it five seconds earlier, so the record starts before zero and the
  origin is shown to be ignored in both directions, with the starting state
  still held at the first sample.

Both are validation-only checks that any correct implementation already
satisfies, which is what makes them safe to add to a suite whose batch sits at
2/5.

## Mutation proof

One mutation at a time, in the base image offline. No mutation survives, so
every trap the design claims is really asserted. The counts below were measured
against the 108-test suite and are lower bounds for the 146-test one.

| Mutation | Tests killed |
|---|---|
| linear combination operator dropped from `assemble_matrices` | 4 |
| modal mass divisor dropped from `effective_masses` | 3 |
| two dimensional rotation column sign flipped | 3 |
| `mass_fractions` denominator replaced by one | 2 |
| mesh vertices used instead of field nodes | 1 |
| sign convention not applied | 1 |
| static correction not added to the response | 1 |
| identity used for the CQC correlations | 1 |
