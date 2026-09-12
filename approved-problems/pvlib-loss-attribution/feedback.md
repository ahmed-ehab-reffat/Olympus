# feedback.md — pvlib-loss-attribution

## Summary

Olympus submission on [pvlib/pvlib-python](https://github.com/pvlib/pvlib-python) (BSD-3-Clause,
1630 stars, Python). Adds a loss-attribution capability to `ModelChain`: the simulation is
re-evaluated stage by stage and the gap between a clear-sky, horizontal, loss-free reference and the
modeled AC power is decomposed into eight ordered, exactly-additive buckets.

- Base commit: `e6267a58d54964ab257321d0944ba179dc06a9bb` (2026-07-31)
- Shape: O-Algorithm-correctness
- Files: 1 new + 2 modified source files
- Effective LOC (Counter 2, hook): **327** raw 698
- Tests: **270**, all F2P (mutation-proved: 27 of 27 designed defects killed)
- Category: feature-request

## Pick rationale and gate log

Repo choice was autonomous (user standing preference: a repo never used in this workspace, plus a
genuinely hard feature). Ranked candidates by "deep engine in an unusual domain, obscure to problem
authors" per `SATURATED-REPOS.md § THE PATTERN`:

| Candidate | Verdict |
| --- | --- |
| ricosjp/truck (Rust CAD kernel) | DROPPED. `truck-platform` / `truck-rendimpl` test crates need a wgpu GPU adapter; the Environment Quality gate runs the repo's own suite, so a GPU-dependent baseline is a dead pick. |
| gdsfactory/gdsfactory (photonic IC layout) | DROPPED. Cloned and ran the vanilla suite: **357 failed / 1305 passed** on a clean checkout (stale GDS regression references). Fails the green-baseline gate outright. |
| egraphs-good/egg | DROPPED. 10 MB repo, low irreducible LOC. |
| dimforge/parry | DROPPED. Float-tolerance assertions; "add a shape" is pattern-followable. |
| Unidata/MetPy | DROPPED. 1.1 GB repo (test data), heavy image build. |
| **pvlib/pvlib-python** | **PICKED.** |

Gates run on the finalist:

- Stars 1630, BSD-3-Clause, Python. Last commit 2026-07-31.
- **Green baseline:** vanilla suite 1388 passed / 0 failed / 171 skipped in ~16 s, fully offline.
- **Flakiness (mandatory):** 5x new + 5x base, identical every run. No RNG, no clock, no network.
- **Cold path:** `pvlib/modelchain.py` has **1 commit in the trailing 12 months**, and it is a
  docstring typo fix (`690e4f4`). The subsystem is cold.
- **Exclusivity:** searched PRs and issues (all states) for "loss diagram", "waterfall", "loss
  attribution", "energy accounting", "loss breakdown", "loss decomposition", "marginal loss",
  "sankey", "attribution", "loss chain". No PR implements a decomposition. Nearest neighbours:
  issue #1069 (open, proposes PVsyst-style loss *models* as new chain stages, not a decomposition of
  an existing run) and PR #1354 (open, adds a standalone `pvlib/mlfm.py`; its source footprint is
  `mlfm.py` + `tools.py` + `temperature.py` and it **does not touch `modelchain.py`**, so there is no
  core-machinery overlap).
- **Dedup:** no pvlib submission anywhere in `Aprroved/`, `problems/`, `rejected/`,
  `Olympus/problems/`. No prior submission decomposes a modeled quantity into ordered marginal
  buckets.
- **Repo quota:** first submission against this repo; 1630 stars puts it in the niche band that
  `SATURATED-REPOS.md` recommends over household names. Not platform-verified (only the platform
  "Learn more" page can confirm the global count) - **verify before submit**.

## ⚠️ Open item for the user: effective LOC

`human-effective` is **259**. Which floor binds is ambiguous in the current rules:

- `CLAUDE.md § RULE UPDATE 2026-07 (SPRINT)` sets the long-horizon floor at **>= 250 effective LOC**
  ("gate on the hook's `human-effective` >= 250"), down from 450. On that rule this **clears**.
- The older hard rule and `effective_loc_check.py` still target **>= 430** (400 platform auto-block).

pvlib's numpydoc convention is the reason for the gap: the counter strips docstrings, and this patch
is 585 raw for 259 effective (~2.3 raw per effective line). Reaching 430 effective would need roughly
1000 raw lines in pvlib style.

Scope was raised twice rather than padded, per `PICK-FILTER.md § SCOPE-INVENT LEVERS`:

1. 138 eff - the staged conversion-side decomposition alone (6 buckets).
2. 198 eff - added the clear-sky reference and the `weather` bucket (new machinery spanning
   `location`, `clearsky`, `irradiance`), plus per-array `to_frame` / `as_fraction`.
3. 235 eff - added the horizontal reference and the `transposition` bucket, plus `cumulative()`.
4. **259 eff** - replaced the "put the inverter loss on array 0" wart with a real proportional
   allocation (with an equal-split rule where no array delivers power), plus `energies(freq=...)`.

Recommendation: submit against the 250 sprint floor. If the reviewer applies the 430 target instead,
the honest options are to add another co-equal axis or to re-home this feature class on a repo with a
lighter docstring convention. **Do not pad** - the hook already reports `padding-floor` 158 well below
`human-effective`, so repetitive breadth would be visible.

## Design decisions logged

- **Reuse over reimplementation.** Every stage runs through the chain's own `dc_model`,
  `dc_ohmic_model`, `losses_model` and `effective_irradiance_model`, so the decomposition is correct
  for every DC model (sapm / desoto / cec / pvsyst / pvwatts) and every AC model without
  model-specific code. This also avoids the "code duplication" revert cause.
- **Ideal inverter = sum of DC over arrays.** Makes stages comparable in AC terms and gives the
  inverter bucket a crisp definition (conversion and clipping together). Splitting clipping out was
  rejected: it would require reimplementing three inverter models without their power clamp.
- **Exact additivity is the load-bearing law** (the Task18 idempotence lesson applied here). It is
  self-checking, needs no external oracle, and kills any implementation that attributes each
  mechanism independently.
- **State is saved and restored** around the staged runs (`_ATTRIBUTION_STATE`), because
  `dc_ohms_from_percent` and `pvwatts_losses` mutate `results.dc` in place. Seven tests assert the
  ordinary results survive untouched.
- **NaN is pvlib's, not ours.** The `Entech_22X_Concentrator` SAPM module yields NaN DC at zero
  effective irradiance on the *base* run; the decomposition propagates it faithfully. Tests avoid
  configurations with a pre-existing NaN rather than pinning pvlib's behavior.
- **Pre-existing bug avoided:** `dc_ohms_from_percent` crashes for a single-array chain given
  list-wrapped input (pvlib issue #2829, reproduced on base). Tests never combine those two.

## Traps

| # | Trap | Interdependent | Misdirecting |
| --- | --- | --- | --- |
| 1 | Independent attribution instead of cumulative-in-order | yes, changes every bucket | yes, surfaces as a residual |
| 2 | Reference irradiance taken as `poa_global` instead of the chain's own effective-irradiance formula with the modifier set to one (differs whenever `FD != 1`) | yes, moves buckets 3 and 4 and the residual | yes |
| 3 | In-place mutation of `results.dc` leaking between stages | yes | yes, shows up in a *later* bucket |
| 4 | Per-array inverter bucket (it is system wide) | yes | yes, only breaks for multi-array systems |
| 5 | Clamping negative buckets to zero (cold cells and tilt gains are negative) | no | no |
| 6 | Dividing by a zero reference energy at night | no | no |
| 7 | Proportional inverter split loses the standby loss at night unless the zero-DC case splits equally | yes | yes |

Trap 3 is the single codebase-inferable requirement (visible in `modelchain.py`).

## Validation

Run in the platform's own order (build image from the base tree, then apply patches), offline
(`--network none`), non-root (`--user 1000:1000`):

| state | mode | exit | testcases | failures | errors |
| --- | --- | --- | --- | --- | --- |
| base | base | 0 | 1561 | 0 | 0 |
| base | new | 1 | 270 | 270 | 0 |
| solution | base | 0 | 1561 | 0 | 0 |
| solution | new | 0 | 270 | 0 | 0 |

- 270 F2P nodes, **0 collection errors** - the test module imports nothing from
  `pvlib.lossattribution` at module level, so pytest collects on base and every test fails
  individually at runtime.
- Both patches apply and unapply cleanly in either order; tree returns to base exactly.
- Confirmed the setuptools editable install created at image build time picks up the brand-new
  `pvlib/lossattribution.py` added later by `solution.patch`.
- Patches are ASCII + LF; `test.sh` is mode `100755`.
- No inline comments added by either patch (pvlib documents with numpydoc docstrings, which the
  solution matches; test bodies carry none).

## Attempt history

1. Design + implementation + 113 tests + full validation.
2. Review round 1 (description quality + alignment + coverage). Applied every suggestion, then ran a
   mutation battery that found two genuine false-positive holes. 113 -> 145 tests.
3. Review round 2 (four more coverage suggestions). 145 -> 166 tests, two more mutations added to the
   battery, and the additivity helper was tightened after it was found to tolerate a silently-NaN
   bucket. See below.
4. Review round 3 (Test Fairness FAIL on one test, one alignment warning, three coverage suggestions).
   166 -> 172 tests. See below.
5. Review round 4 (three coverage suggestions). 172 -> 187 tests, battery extended to 12 mutations.
6. Review round 5 (Test Fairness FAIL on two tests, two coverage suggestions). 187 -> 196 tests.
7. Review round 6 (two coverage suggestions). One of them found a **real bug in the reference
   implementation**. 196 -> 209 tests, battery extended to 15 mutations.
8. Review round 7 (Test Fairness FAIL on three tests, two coverage suggestions). 209 -> 221 tests,
   battery extended to 17 mutations, one of which initially survived.
9. Review round 8 (three coverage suggestions). 221 -> 235 tests, battery extended to 19 mutations.
10. Review round 9 (three coverage suggestions). Two applied, one deliberately declined as unfair to
    pin. 235 -> 248 tests, battery extended to 21 mutations.
11. Review round 10 (Test Fairness FAIL on 16 tests in three groups, two coverage suggestions).
    248 -> 249 tests, battery extended to 23 mutations.
12. **Batch 1 ran: 3 of 4 PASS = 75 percent, far over the 40 percent cap.** FP clean. Hardened with an
    order-independent `shapley()` reading. 249 -> 270 tests. See below.
13. Review round 12 (Test Fairness FAIL on the two shapley purity tests). Description pinned; no test
    changed.

## FP closure (review round 1)

### Description feedback applied

- HIGH "remove: and every result the ordinary run produced is left as it was" - **removed**. The seven
  preservation tests stay: the reviewer's own rationale is that solvers assume this by default, which
  makes it a fair default expectation rather than a hidden requirement. It is not automatic here (the
  staged re-runs mutate `results.dc` in place), so it remains the single inferable requirement.
- MEDIUM "remove: The last stage reproduces the ordinary run" - **removed**; the additivity sentence
  now names `ac` directly, so nothing is orphaned.
- LOW "remove: following the convention the other results already use" - **replaced, not deleted**.
  The alignment checker simultaneously asked for the singleton-tuple nuance to be stated explicitly,
  so the vague clause became the concrete rule: bare Series / tuple of Series / one-element tuple when
  a single-array system is given list-wrapped input.

### Alignment warnings applied

- `energies(per_array=True)` is now documented.
- The singleton-tuple shape rule is now documented (above).
- One further ambiguity was pinned pre-emptively: clear-sky irradiance is "evaluated at the solar
  position the run already computed". Two defensible readings existed (reuse the run's solar position,
  which carries measured air temperature through refraction, versus a fresh `get_clearsky(times)`) and
  they differ numerically by ~0.06 percent. That is exactly the ambiguity class that returns as an FP
  verdict, so the description now picks one.

### Coverage suggestions - all six added

| Suggestion | Tests added |
| --- | --- |
| Zero-DC inverter allocation | `..._is_equal_when_no_array_delivers`, `..._is_equal_at_night_three_arrays`, `test_night_inverter_loss_is_not_dropped` |
| Proportional inverter allocation | `test_inverter_allocation_equals_dc_share_two_arrays` / `..._three_arrays`, `..._is_not_all_on_first_array` |
| Effective-irradiance reference value | `test_effective_irradiance_reference_tracks_input`, `..._matches_lossless_run` |
| Alternate entry-point integration | 6 tests: multi-array additivity and shapes plus result preservation for both alternate entry points |
| Input validation | 6 tests: wrong frame count, mismatched indexes, missing columns on all three entry points |
| Periodized per-array energies | 3 tests: MultiIndex schema, reconciliation to system energies, total vs whole-index |

### Mutation proof (the actual FP gate)

Each designed defect was implemented in the reference on purpose and the suite re-run. A defect that no
test fails on is a false positive waiting to happen.

| Mutation | Round 1 | After fixes |
| --- | --- | --- |
| M1 inverter loss all on array 0 | killed by 3 | killed by 4 |
| M2 zero-DC share collapses to zero | **SURVIVED** | killed by 3 |
| M3 reference irradiance = `poa_global` | killed by 2 | killed by 2 |
| M4 reference cell temperature 20 C | killed by 6 | killed by 6 |
| M5 `dc_ohmic` / `dc_other` stages swapped | killed by 5 | killed by 5 |
| M6 no state restore after staging | **SURVIVED** | killed by 1 |
| M7 transposition stage dropped | killed by 4 | killed by 4 |
| M8 buckets clamped non-negative | killed by 28 | killed by 29 |

**M2 survived because the test was vacuous.** The night allocation test used a pvwatts inverter, which
draws exactly 0 W at zero DC, so "split equally" and "give nobody anything" both produce zeros and no
assertion can separate them. Fixed by moving the night-split tests onto a Sandia inverter, which has a
real night tare (0.075 W), and asserting the loss is non-zero before asserting how it is split.

**M6 survived because the corrupted field had no test.** Skipping the restore leaves `results.dc`,
`cell_temperature`, `effective_irradiance`, `total_irrad` and `aoi_modifier` all correct by accident -
the final stage reproduces the real run. The only field left wrong is `spectral_modifier`, stranded at
1.0 by the reflection stage, and nothing asserted it. Added
`test_results_spectral_modifier_preserved` on a chain with a real spectral model.

Both holes are the shapes the FP guidance names: an input that is a fixed point of the transformation
under test, and a reporting surface whose happy path still looks perfect.

### Round 2 - four more coverage suggestions

| Suggestion | Tests added |
| --- | --- |
| POA-start early-stage semantics | 5 tests pinning `reference`, the `transposition` level and the `weather` level for `run_loss_attribution_from_poa` against independently-run chains, plus that the reference ignores the supplied POA while `weather` responds to it |
| Period boundaries | 6 tests on a three-day index: period count, per-period totals against manual date slices, periods summing to the whole index, and the per-array variants |
| Tracking mounts | 6 tests on a `SingleAxisTrackerMount` array: additivity, the horizontal reference matching a flat fixed-mount run, the reference matching the fixed-mount chain's reference exactly (it must ignore the mount), the transposition level against a tracked clear-sky run, and result preservation |
| Per-array zero reference fractions | 3 tests: multi-array night for two and three arrays, plus an empty index, each dictionary independently zero |

**A third FP hole surfaced while writing these, in the test harness itself.** `assert_additive` summed
the buckets with `DataFrame.sum`, which skips NaN. A bucket that was silently all-NaN but whose true
value is zero would therefore have passed additivity unnoticed. Mutation M9 (spectral bucket forced to
NaN) confirmed it. The helper now requires that a NaN affects **every** bucket in a row or none of
them, which is the only pattern the run itself can produce, and checks additivity on the finite rows.
M9 is now killed by 43 tests.

The tracker tests also produced two failures that turned out to be **test** bugs worth recording:
`results.tracking` is `None` even after a plain `run_model` (the field is legacy and the mount API
does not populate it), and `np.allclose` returns False in the presence of NaN, which the tracker
legitimately produces at sunrise when the sun is below the horizon. The assertion helper now requires
the NaN masks on both sides to match and compares the finite values, which is stricter than before
rather than weaker.

10 of 10 mutations killed, 0 survivors.

### Round 3 - the one unfair test

`test_as_fraction_per_array_returns_tuple` asserted the outer container is a `tuple`, while the
description only promised "one such dictionary per array". A list would have satisfied the prose and
failed the test, which is the definition of an unstated requirement.

**Fixed by pinning the description, not by weakening the test.** The contract already commits to
tuples everywhere else per-array results appear ("a tuple of Series for several, and a one-element
tuple when ... wrapped in a list or tuple"), so `as_fraction(per_array=True)` returning anything else
would have been the inconsistency. The sentence now reads "a tuple of one such dictionary per array".
Relaxing the test to accept any sequence was the alternative and was rejected: it would have left the
container unpinned across an API whose every other per-array surface is a tuple, which is exactly the
"costs nothing today" ambiguity that returns later as an FP verdict.

### Round 3 - alignment warning

`LossAttribution.num_arrays` was read by the tests but never documented. Added to the shape paragraph:
"`num_arrays` reports how many arrays the per-array fields cover."

### Round 3 - three coverage suggestions

| Suggestion | Tests added |
| --- | --- |
| Plain-run unset for the alternate entry points | 2 tests confirming ordinary `run_model_from_poa` and `run_model_from_effective_irradiance` also leave `results.loss_attribution` unset |
| Exact spectral-stage oracle | `test_spectral_level_matches_full_optics_run` pins `cumulative()['spectral']` against a fixed-25 C run with both modeled reflection and modeled spectral modifier, plus a check that the reflection and spectral levels genuinely differ |
| Multi-array effective-input zero buckets | 2 tests asserting the first four buckets are zero for **every** array in two-array and three-array effective-irradiance runs |

### Round 4 - three coverage suggestions

| Suggestion | Tests added |
| --- | --- |
| `num_arrays` direct contract | 6 tests asserting the value directly on bare single-array, singleton-wrapped single-array, two-array, three-array and from-POA multi-array runs, plus agreement with the per-array tuple lengths |
| Alternate-start singleton wrapping | 6 tests: one-element list input to both alternate entry points gives one-element tuple buckets, stays additive, and matches the bare-input values |
| Alternate-start index validation | 3 tests: mismatched indexes and wrong frame counts for POA and effective-irradiance multi-array input |

Two mutations were added to the battery to confirm the newly-covered contracts are actually enforced:
M11 (single-array results always wrapped in a tuple) is killed by 47 tests, and M12
(`as_fraction(per_array=True)` divides by the system reference instead of each array's own) is killed
by 1. **12 of 12 mutations killed, 0 survivors.**

### Round 5 - the two reviewers disagreed, and the description was wrong

Test Fairness flagged `test_plain_run_model_from_poa_leaves_attribution_unset` and
`test_plain_run_model_from_effective_irradiance_leaves_unset` as unfair: the description named only
plain `run_model`, so extending "leaves the attribute unset" to the other two ordinary methods was an
unstated requirement.

Those two tests were added one round earlier **because a coverage suggestion asked for them**. The
reviewers were not in conflict about the behavior - both wanted it - they were pointing at the same
defect from opposite sides: the description under-specified a rule that obviously applies to all three
ordinary entry points. Fixed in the description, keeping the coverage:

> The ordinary run_model, run_model_from_poa and run_model_from_effective_irradiance leave that
> attribute unset.

Deleting the two tests was the alternative and was rejected: it would have removed coverage a reviewer
had explicitly requested in order to satisfy a rule that a one-clause edit fixes properly.

### Round 5 - two coverage suggestions

| Suggestion | Tests added |
| --- | --- |
| Negative transposition gain | 4 tests on a December fixture where tilt genuinely gains over horizontal (-578 W at 30 degrees, -820 W at 60): the bucket is negative, the gain grows with tilt, additivity still holds, and `as_fraction` reports the negative fraction. This is the first direct coverage of the prompt's "tilt gains" example of a negative bucket. |
| Real tuple containers | 5 tests passing an actual Python tuple (the earlier singleton tests all passed lists) to each of the three entry points, plus a two-array tuple case |

12 of 12 mutations still killed after the additions, 0 survivors. M7 (transposition stage dropped) is
now caught by 12 tests rather than 9, and M8 (buckets clamped non-negative) by 42 rather than 37 -
the winter tilt-gain fixture strengthens both, because a clamped implementation cannot represent a
gain at all.

### Round 6 - a coverage suggestion found a real bug

"Clearing stale attribution" was advisory, and it was correct. The reference implementation left
`results.loss_attribution` in place after a subsequent ordinary run, so this sequence produced a
silently misleading object:

    chain.run_loss_attribution(june)      # attribution describes June
    chain.run_model(december)             # results.ac now describes December
    chain.results.loss_attribution        # still describes June

The description already said the ordinary methods "leave that attribute unset", and the only reading
that is not misleading is that the attribute is None after an ordinary run. **Fixed in the solution**,
not by softening the tests: `_run_from_effective_irrad` now clears the field, which covers all three
ordinary entry points in one place because all three funnel through it, and the attribution methods
call their ordinary run first, so the clear always precedes the set.

The second suggestion also paid off. "Configured clear-sky / airmass / transposition models" exposed
that nothing pinned the chain's configured models against hard-coded defaults; M14 and M15 confirmed
a hard-coded `'ineichen'` or `'haydavies'` would previously have passed the whole suite.

Note for anyone extending this: `clearsky_model='haurwitz'` cannot work here, because pvlib's
haurwitz returns GHI only and transposition needs DNI and DHI. That is inherited pvlib behavior, not
a rule this task adds, so no test pins it. The configured-model tests use `simplified_solis`, which
returns all three components.

### Round 6 - tests added

| Area | Tests added |
| --- | --- |
| Stale attribution | 5 tests: each ordinary entry point clears a previous attribution, a second attribution replaces the first, and an attribution can be recomputed after an intervening ordinary run |
| Configured models | 8 tests: the reference and transposition levels change with `clearsky_model` and `transposition_model`, both match oracles built with the same configured models, both stay additive, and a non-default `airmass_model` leaves AC and additivity intact |

**15 of 15 mutations killed, 0 survivors.** The three new ones: M13 (ordinary runs do not clear a
stale attribution) killed by 3, M14 (clear-sky model hard-coded) killed by 3, M15 (transposition model
hard-coded) killed by 2.

### Round 7 - dictionary key order

Three tests asserted `list(as_fraction().keys()) == BUCKETS`, pinning Python dictionary **insertion
order** while the description promises only that the result is "keyed by the eight bucket names".

**Relaxed the tests to set equality** - the opposite of the round-3 decision, and deliberately so.
There the container type was already pinned everywhere else in the contract, so stating it was the
consistent fix. Here iteration order carries no behavioral meaning: two dictionaries with identical
keys and values are the same object for every purpose this API has. Pinning it in the description
would have been over-specification of an incidental Python detail. `to_frame` column order stays
pinned because it is a display/plotting contract and genuinely observable.

### Round 7 - two coverage suggestions, and a mutation that survived

| Suggestion | Tests added |
| --- | --- |
| Configured airmass stage | 3 tests using SAPM spectral response, which consumes absolute airmass, so the spectral bucket and its stage oracle change with `airmass_model` |
| Distinct effective inputs across arrays | 5 tests on a two-array system with **identical** modules but deliberately different per-array inputs, so the reference of array 1 must be exactly half that of array 0; plus a swapped-order case and a POA analogue that catch frame-to-array misrouting |

Adding M17 (clear-sky transposition uses absolute rather than relative airmass) **survived the first
run**. The cause is worth recording: pvlib's default `haydavies` transposition **ignores the `airmass`
argument entirely** - only `perez` consumes it - so with the default model the mutation is a no-op and
no test could ever detect it. That is exactly what the reviewer's airmass suggestion was pointing at.
Added four `transposition_model='perez'` tests, including a stage oracle, and M17 is now killed.

M16 (per-array inputs misrouted by swapping the arrays) is killed by 2 of the new distinct-input
tests, which is the defect the second suggestion targeted.

**17 of 17 mutations killed, 0 survivors.**

### Round 8 - three coverage suggestions

| Suggestion | Tests added |
| --- | --- |
| Custom model callables | 8 tests. ModelChain accepts a callable for `aoi_model`, `spectral_model`, `dc_ohmic_model` and `losses_model`, bound as `partial(model, self)`. Because a constant modifier scales effective irradiance uniformly and PVWatts DC is linear in irradiance at a fixed cell temperature, these give **exact** stage relations: a 0.95 spectral callable makes `cumulative['spectral']` exactly `0.95 * cumulative['reflection']`, a 0.95 ohmic callable makes the `dc_ohmic` bucket exactly 5 percent of the temperature level, and a 0.9 losses callable makes `dc_other` exactly 10 percent of the ohmic level. A unity AOI callable drives the reflection bucket to exactly zero. |
| Missing-value propagation | 5 tests on a single NaN GHI sample. Only what the contract actually implies is asserted: `reference` and `transposition` are **unchanged from the clean run**, because both come from the chain's clear sky rather than the supplied weather; the NaN appears no earlier than `weather`; the remaining complete rows still reconcile exactly; and reference energy is unchanged. The downstream NaN pattern itself is ordinary numeric propagation and is deliberately **not** pinned, since the description says nothing about it. |
| Public API / type | 1 test asserting the class name is `LossAttribution`. **The import path is deliberately not pinned.** The description names the class but never says which module it lives in, so asserting `pvlib.lossattribution.LossAttribution` would have created a fresh unstated-requirement failure of exactly the kind rounds 3, 5 and 7 were spent fixing. |

Two mutations were added: M18 (the reflection stage re-derives the IAM from `pvlib.iam.physical` instead
of reusing the chain's own modifier) is killed by 3, which is the defect the callable suggestion
targeted; M19 (the reference stage is rebuilt from the supplied weather instead of clear sky) is killed
by 16, which the missing-value tests strengthen because a weather-derived reference would inherit the
NaN. The custom-callable tests also strengthened M5 (7 killers, up from 5) and M15 (4, up from 2).

**19 of 19 mutations killed, 0 survivors.**

### Round 9 - two applied, one declined

| Suggestion | Decision |
| --- | --- |
| Additional custom model stages | **Applied.** 7 tests covering the three remaining configurable stages. A constant 45 C temperature callable makes the temperature bucket exactly 8 percent of the spectral level (PVWatts gamma -0.004 over a 20 degree rise); a temperature-independent DC callable makes the temperature bucket exactly **zero**, which is a strong reuse proof; a 0.9 AC callable makes the inverter bucket exactly 10 percent of the final DC level. Note the staging reaches these three differently from the optics stages: cell temperature is consumed through `results.cell_temperature` rather than by calling `temperature_model()`, and the AC model is never called during staging at all (the ideal-inverter stages sum DC), so `ac` reaches the inverter bucket only through the ordinary run. All three are still exercised end to end. |
| Input immutability | **Applied.** 6 tests across all three entry points plus singleton-wrapped, multi-array and missing-value inputs. pvlib copies inputs in `_assign_weather`, so nothing was mutated, but nothing pinned it either. |
| Failed-run state semantics | **Declined, deliberately.** Verified the behavior: a validation error raises out of `prepare_inputs` before the clearing step, so a previous attribution survives - consistent with pvlib itself, which likewise leaves `results.dc` and `results.ac` from the earlier run in place after a failed call. But the description says nothing about failure transitions, so a test pinning "preserved" versus "cleared" versus "partial" would be an unstated requirement, which is exactly the failure rounds 3, 5 and 7 were spent removing. Pinning it in the description was the alternative and was rejected as inventing contract surface for an edge nobody asked for behaviorally. Recorded here rather than silently skipped. |

Two mutations added. M20 (staging ignores the configured cell temperature and hard-codes 30 C) is
killed by 7. M21 needed a second attempt worth recording: the first version mutated
`results.weather`, which pvlib had already **copied** from the caller, so it never reached the input
frame and survived all 248 tests - a bad mutation testing the wrong object, not a coverage gap. Rewritten
to add a column to the caller's own DataFrame, it is killed by 2 of the new immutability tests.

**21 of 21 mutations killed, 0 survivors.**

### Round 10 - three unfair groups, fixed two ways

| Group | Fix |
| --- | --- |
| `cumulative()` column order (1 test) and `energies()` return structure (11 tests) | **Pinned in the description.** These were an inconsistency in my own prose, not test defects: the description already commits `to_frame` to "a DataFrame ... whose columns are ...", which is exactly why the reviewer passed every `to_frame` test as fair, while `cumulative()` and `energies()` were described only by what they compute. Both are real public API shapes a caller depends on, so the description now says `cumulative()` returns a DataFrame with `reference` then the eight bucket names, and `energies()` returns a Series indexed by those column names, or a DataFrame of one row per period with a frequency. |
| Empty-index execution (4 tests) | **Tests deleted.** The alternative was one more description clause, but meta was at 494 of a 500-word cap after the two pins above, and empty-index support is the least valuable of the three: the zero-denominator behavior it guarded is already covered by the night fixtures, which the description *does* state ("zero whenever that reference energy is zero"). Spending the last words on an edge nobody asked for behaviorally was the worse trade. |

### Round 10 - two coverage suggestions

Both target the boundary between the proportional and equal inverter-allocation rules, which no test
had separated. Built with `run_loss_attribution_from_effective_irradiance` feeding one array real
irradiance and the other exactly zero, on a two-array system with identical modules:

| Suggestion | Tests added |
| --- | --- |
| Mixed zero-DC inverter allocation | 3 tests: the idle array receives **no** inverter loss while any array is delivering, the equal split applies only on rows where *every* array is idle, and the mixed case still reconciles to the system frame |
| Per-array zero reference fraction | 2 tests: the zero-reference array reports all-zero fractions while the other array's are nonzero, and its reference Series is exactly zero |

M22 (equal split used whenever **any** array is idle rather than only when all are) is killed by 2 of
these, which is precisely the boundary the suggestion named. M23 (`cumulative()` drops its `reference`
column) is killed by 2 and guards the newly-pinned column contract.

**23 of 23 mutations killed, 0 survivors.**

## Next steps

1. Verify pvlib's global submission count on the platform "Learn more" page before submitting.
2. Run the agent batch (Nova/Orion), then the platform FP check on every passing agent.
3. Resolve the 250-vs-430 effective-LOC question with the user.


## Round 11 - the too-easy result, and what it cost to fix

Batch 1 landed 3 of 4 PASS_LEGITIMATE (75 percent) with a clean FP check. The clean FP is the useful
part of that signal: tests and description agree, so nothing was wrong with the artifact except that
it was not hard.

**The cause was my own review history.** Ten fairness rounds had each answered "this test pins
something the description does not state" with "then state it". By round 10 the description was a
complete specification of every rule the tests check, and implementing a complete specification is
typing, not problem-solving. The passing agents wrote 267, 362 and 509 added lines of direct
transcription. This is the documented failure mode in `TOO-EASY.md` and in the
`olympus-fairness-ratchet-kills-deterministic-picks` memory: **documented traps are implementable
traps.** More prose could only make it easier.

So the hardening could not be another rule. It had to be work that stays hard when fully stated -
the CONTRACT-STATED / FIX-HIDDEN axiom, difficulty in DOING rather than KNOWING.

### The hardening: `shapley()`

The eight sequential buckets depend on the order the stages are applied. `shapley()` credits each of
the six conversion mechanisms its mean marginal drop over all orderings of those six.

Why it resists transcription where the rest did not:

- **The easy answer is not reusable.** Shapley credits differ materially from the sequential buckets
  on the same run - inverter 76.8 W against 52.9 W, temperature 132.0 against 152.9. An agent cannot
  rename the values it already has.
- **The obvious construction is 4320 model evaluations.** Six mechanisms give 720 orderings, each
  walked as a six-step chain. Collapsing that to the 64-subset lattice with factorial weights
  `|S|!(n-|S|-1)!/n!` is the non-obvious step; the naive version is correct but roughly 70 times
  slower per call.
- **It is interdependent with machinery that already existed.** Evaluating a subset that includes
  `inverter` calls the real `ac_model` during staging, which nothing did before, so `ac` had to join
  `_ATTRIBUTION_STATE`, and the lattice must restore the ordinary results when it finishes.
  **This claim was initially false and the mutation battery caught it** - see below.
- **Exact additivity survives** as the self-checking invariant: the six credits sum to the `weather`
  column of `cumulative()` less `ac`, residual 2.8e-14.
- **It stays fair.** One paragraph states it, plus the one clause it genuinely needs (a subset without
  `inverter` again takes AC to be DC summed over the arrays). The word cap was raised by the user
  rather than trimming a stated contract.

Effective LOC rose from 263 to **327** as a by-product (raw 698), easing the separate floor question.

### Two things done carefully rather than quickly

- One test reached into the private `_lattice` to cross-check Shapley against a direct permutation
  average. That is exactly the implementation coupling rounds 3, 5, 7 and 10 were spent removing, so
  it was replaced by a public-API oracle: a chain whose every mechanism is a constant multiplicative
  factor, with the expected credits computed independently inside the test over all 720 permutations
  of scalars. This pins each individual credit exactly rather than only their sum.
- The effective-irradiance entry point cannot separate reflection from spectral response, because
  `results.total_irrad` carries no `poa_direct` there. The `optical` flag already threaded through
  the sequential path now also drives the lattice, so toggling those two mechanisms is a no-op and
  their credits are exactly zero - consistent with the existing rule that the first four buckets are
  zero for that entry point.

### Still open

**The new pass rate is unmeasured.** Only the platform runs agents. Batch 2 must be run against the
270-test artifact before this is submittable, and the hardening should be judged on that number, not
on the reasoning above.


## Round 11b - the battery caught me overstating the interdependence

I claimed the new lattice made state restoration load-bearing: get Shapley right but forget to restore
and a dozen preservation tests break. **M26 (remove the restore) survived all 270 tests.** The claim
was wrong.

The reason is the same accident that let M6 survive in round 1, which I had already recorded and then
failed to apply. `itertools.combinations` over sizes 0..6 evaluates the **full** subset last, and the
full subset reproduces the ordinary run exactly - so every field lands back on its correct value as a
side effect and the restore never has to do anything. Verified directly: `dc`, `ac`,
`cell_temperature`, `effective_irradiance`, `aoi_modifier`, `spectral_modifier` and `losses` were all
identical after `shapley()` with the restore deleted.

So M26 was a **no-op mutation against my reference**, not a coverage gap - the same category as the
first M21 attempt in round 9. But unlike M21 the underlying hazard is real for a solver: an agent that
walks the lattice largest-first, or in set iteration order, ends on a partial subset and leaves
`results` holding reference-stage values.

**Fixed by removing my reference's accidental immunity rather than by contorting a test.** The lattice
now evaluates largest subsets first, which is an equally natural choice and cannot change any value
because Shapley is order-independent by construction. The empty subset is now last, so skipping the
restore leaves the ordinary results at the reference stage. M26 is killed by 2 tests
(`test_shapley_does_not_disturb_ordinary_results`, `test_shapley_is_repeatable`).

The general lesson, now twice paid for: **a mutation that survives is not automatically a missing
test.** It can be a defect the reference is accidentally immune to, and the fix is then to remove the
accident, not to write a test for behavior that cannot differ.


## Round 12 - shapley purity

Test Fairness flagged `test_shapley_does_not_disturb_ordinary_results` and
`test_shapley_does_not_disturb_the_sequential_buckets`: the description specified what `shapley()`
returns but never said that computing it has no side effects, and the reviewer correctly noted that
ModelChain stage methods normally do mutate `results`.

**Pinned in the description rather than dropping the tests, and this one was not a close call.** Those
two tests are the only killers of M26 (the lattice not restoring state). Deleting them would have
re-created the exact survivor round 11b was spent eliminating, trading a fairness flag for a hole in
the hardening. The added clause is one sentence:

> ... and computing it leaves `results` and the eight sequential buckets as they were.

It is also a genuine property rather than a convenience: a diagnostic that silently corrupts the
simulation it is describing would be a defect, and the 64-subset lattice makes that a live hazard
rather than a theoretical one.

Meta is now 549 words. No test, patch or code changed, so the 270-pass suite, the 27 of 27 mutation
result and the generated patches are all unaffected.


## Round 13 - Description Quality FAIL: 7 accepted, 2 contested

Two bots reviewed the description. Nine suggestions total; seven applied, two contested with evidence.

### Applied

| Item | Change |
| --- | --- |
| "re-evaluates the chain stage by stage" prescribes an internal strategy | now "The buckets follow from replaying the model through a fixed stage order" |
| "the eight bucket names in order" restates the stage order | now "those bucket names in the same order" |
| "given a pandas offset alias" is API-reference jargon | now "when a resampling frequency is given" |
| "at every timestamp" | now "summing elementwise", which is shorter and removes a possible read as summing over time |
| "which `ac` reports" reads redundant | now "reported as `ac`", same information |
| illustrative examples for negative buckets | removed; the rule stands alone |
| clear-sky "at the solar position the run already computed" reads as a caching directive | **reworded, not deleted** - now "at the same solar position as the rest of the run", which states the required property without prescribing reuse |

The solar-position item deserves the note. Both bots called it an implementation detail and the
Description Quality bot's own `testPatchCheck` reported no test depends on it. That check is wrong:
`clearsky_like` in the test file passes `solar_position=chain.results.solar_position`, and six oracle
tests compare against it. Deleting the clause would make a fresh `get_clearsky(times)` legal by the
prose and failing by the tests - the difference is **0.078 W/m2, about 78000 times the 1e-6 test
tolerance**, because a fresh solar position uses default air temperature and so a different refraction
correction. Rewording keeps the description behavioral and the tests fair.

### Contested

**1. "The ordinary run_model and its two variants leave that attribute unset." (flagged HIGH, remove
as an obvious default.)**

It is not a default - it is the opposite of one, and pvlib got it wrong until this task fixed it.
Before round 6 an ordinary run left a stale `loss_attribution` in place describing a *different*
simulation, which is the bug that round found and fixed. Six tests assert it and mutation M13
(ordinary runs do not clear the attribute) is killed only by them. The sentence was also *added* in
round 5 because Test Fairness failed without it: two tests covering the alternate entry points were
ruled unfair on the grounds that the prompt named only `run_model`. Removing it now re-creates that
exact failure and silently deletes a trap.

**2. "computing it leaves `results` and the eight sequential buckets as they were." (flagged MEDIUM,
remove as a no-side-effects default enforced by tests.)**

Added one round ago because Test Fairness failed without it, on the reviewer's own reasoning that
"ModelChain stage methods normally do mutate `results`", so purity is not the default here. The two
tests it covers are the only killers of mutation M26. Removing the sentence makes those two tests
unfair again and leaves M26 - which already survived once - unguarded.

Both contests are narrow: each is one sentence, each is load-bearing for named tests and a named
mutation, and each was added to satisfy a previous FAIL from the sibling gate. The two gates disagree,
and the artifact cannot satisfy both by deletion.

Meta is now 546 words. No test, code or patch changed; the 270-pass suite and 27 of 27 mutation result
stand.
