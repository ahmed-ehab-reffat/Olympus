# DESIGN.md — pvlib-loss-attribution

Repo: [pvlib/pvlib-python](https://github.com/pvlib/pvlib-python) · BSD-3-Clause · 1630 stars · Python
BASE_COMMIT: `e6267a58d54964ab257321d0944ba179dc06a9bb` (2026-07-31)

## 1. Title

Add loss attribution to the ModelChain simulation pipeline

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (`PLAYBOOK § Pattern 12`) — a new capability whose difficulty is a
  subtle staged-recomputation contract, not breadth of surface.
- Pass rate target: **<=40% sprint cap; designed for the corpus mode of ~1/10.**
- STATUS: built and locally validated 2026-08-03. Sections 3-7 and 11 are the AS-BUILT design; the
  reference grew from "modelled plane-of-array, loss-free" to "clear-sky on a horizontal surface",
  which added the `transposition` and `weather` buckets (eight in total, not six).
- Best agent: Mixed (Orion decisive-implement fits; Nova likely thrashes on the staging kernel).
- Dominant verdict: MISSED_REQUIREMENT (bucket definition) / INTEGRATION_ERROR (per-array shape).

## 3. Public API surface

- `ModelChain.run_loss_attribution(weather) -> self` — runs the ordinary model, then the decomposition.
- `ModelChain.run_loss_attribution_from_poa(data) -> self` — same, starting from plane-of-array irradiance.
- `ModelChain.run_loss_attribution_from_effective_irradiance(data) -> self` — same, starting from effective
  irradiance; reflection and spectral buckets are then zero.
- `ModelChainResult.loss_attribution` — the `LossAttribution` produced by the three methods above.
- `pvlib.modelchain.LossAttribution` — dataclass holding the decomposition.
- `LossAttribution.reference` — per-array Series [W]: DC power from clear-sky irradiance on a
  horizontal surface, loss-free, at 25 C.
- `LossAttribution.transposition` / `.weather` / `.reflection` / `.spectral` / `.temperature` /
  `.dc_ohmic` / `.dc_other` — per-array Series [W], one per bucket, in stage order.
- `LossAttribution.inverter` — system-level Series [W].
- `LossAttribution.ac` — system-level Series [W]; equals `ModelChainResult.ac`.
- `LossAttribution.num_arrays` — int.
- `LossAttribution.to_frame(per_array=False) -> pd.DataFrame` — fixed column order; `per_array=True`
  gives a MultiIndex of array position over the same names.
- `LossAttribution.cumulative() -> pd.DataFrame` — power remaining after each stage.
- `LossAttribution.energies(per_array=False, freq=None) -> pd.Series | pd.DataFrame` — column totals,
  optionally per period.
- `LossAttribution.as_fraction(per_array=False) -> dict | tuple[dict]` — bucket energy over reference
  energy.
- `LossAttribution.shapley() -> dict` — order-independent credit for the six conversion mechanisms;
  each is the mean marginal drop over all orderings of those six, summing to the `weather` column of
  `cumulative()` less `ac`.
- `pvlib.lossattribution.BUCKET_NAMES` / `PER_ARRAY_BUCKETS` / `FRAME_COLUMNS` /
  `REFERENCE_CELL_TEMPERATURE` — module constants.

## 4. Canonical output form

- **Stage order (fixed, cumulative):** reference, then `transposition`, `weather`, `reflection`,
  `spectral`, `temperature`, `dc_ohmic`, `dc_other`, `inverter`. Each stage retains every mechanism
  switched on by the earlier stages.
- **Bucket value:** previous stage power minus this stage power. Buckets may be **negative** (cell
  temperature below 25 C, spectral modifier above one, a tilt that gains over horizontal).
- **Additivity:** `sum_arrays(reference) - sum(all eight buckets) == ac` elementwise, exactly.
  Measured worst residual across 14 configurations: 4.6e-13 on a ~21 kW reference.
- **Reference irradiance:** clear-sky irradiance (the chain's own clear-sky, airmass and transposition
  models) transposed onto a **horizontal** surface, then passed through the chain's own
  effective-irradiance formula with both modifiers set to one — NOT `poa_global` (they differ whenever
  the module defines `FD != 1`).
- **Reference cell temperature:** 25 degrees Celsius.
- **Reference inverter:** AC power is taken to be the sum of DC power over the arrays.
- **Per-array vs system:** `reference` and the first seven buckets are per array (bare Series for one
  array, tuple of Series for several, matching the existing `_singleton_tuples` convention).
  `inverter` and `ac` are system wide.
- **`to_frame()` column order:** `reference`, the eight bucket names in stage order, then `ac`.
- **`to_frame(per_array=True)`:** MultiIndex `(array position, name)`; the inverter loss is split
  between arrays in proportion to the DC power each delivered, and **equally wherever no array
  delivered any**, so summing over arrays reproduces the system frame.
- **`cumulative()` columns:** `reference` followed by the eight bucket names; the last column equals
  `ac`.
- **`as_fraction()` keys:** the eight bucket names only, no `reference`, no `ac`. Energy is the sum of
  power over the index. **All fractions are zero when the reference energy is zero** (night-only
  input). `per_array=True` returns one dict per array, each over that array's own reference.
- **From effective irradiance:** `transposition`, `weather`, `reflection` and `spectral` are Series of
  zeros; the reference uses the supplied effective irradiance directly.
- Empty index: every field is an empty Series; `as_fraction()` returns zeros.

## 5. Blind-spot pre-empts (from `DESCRIPTION.md` sentence bank)

- *Compound order preservation* -> "in this order: reflection, spectral, temperature, DC ohmic, other DC
  losses, inverter" + "each stage keeps the mechanisms switched on by the earlier stages".
- *Result list ordering* -> the fixed `to_frame()` column order is stated verbatim.
- *Falsy-on-invalid* -> "every fraction is zero when reference energy is zero".
- *Parallel optimized API* -> the three entry points are named explicitly with their differing behavior.
- *Adjacent vs all positions* -> "the reflection-free irradiance comes from the chain's own
  effective-irradiance calculation with the corresponding modifier replaced by one".

Codebase-inferable requirements: **1** (that per-array results follow the existing bare-Series /
tuple-of-Series convention is visible in `ModelChainResult`).

## 6. Description draft

See `meta.md`. Prose, no headers, **432 words** (approved corpus spans 187-603, median ~420).

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful (~0.8 for Python) | Reason |
| --- | --- | --- | --- | --- | --- |
| NEW | `pvlib/lossattribution.py` | — | +300 | ~240 | `LossAttribution` container, staging kernel, aggregation |
| MODIFY | `pvlib/modelchain.py` | 1950 | +230 | ~190 | three entry points, staged re-run driver, result field |
| MODIFY | `pvlib/pvsystem.py` | 3200 | +40 | ~32 | ideal-inverter DC summation helper used by the staging kernel |

TOTAL: ~570 raw / ~460 meaningful across 1 new + 2 modified files.
Gate on the hook's `human-effective` >= 450 before submit; expand via the third entry point's validation
surface if short.

## 8. Solution outline — pure-function helpers

- `_effective_irradiance_with(chain, aoi_modifier, spectral_modifier)` -> per-array Series
  <- description requirement "reflection-free irradiance comes from the chain's own formula"
- `_stage_dc(chain, effective_irradiance, cell_temperature, ohmic, extra_losses)` -> per-array p_mp
  <- the single interdependent kernel every stage runs through
- `_ideal_ac(per_array_p_mp)` -> Series <- "AC power is taken to be the sum of DC power over the arrays"
- `_bucket(previous, current)` -> per-array Series <- "the drop in power caused by that stage alone"
- `_sum_over_arrays(per_array)` -> Series <- `to_frame` aggregation
- `_energy_fraction(bucket_energy, reference_energy)` -> float <- "zero when reference energy is zero"
- `LossAttribution.to_frame()` / `.as_fraction()` <- canonical output form

No fixpoint loop required. Deep-copy discipline is required: `dc_ohms_from_percent` and `pvwatts_losses`
mutate `results.dc` in place, so each stage must start from an independent copy.

## 9. Test file outline

Path: `tests/test_loss_attribution_<hex>.py` (pvlib keeps tests in top-level `tests/`, reusing
`tests/conftest.py` fixtures: `sapm_module_params`, `cec_module_params`, `cec_inverter_parameters`,
`sapm_temperature_cs5p_220m`).

Block 1 — imports. Block 2 — builder helpers (single-array sapm chain, single-array pvwatts chain,
two-array chain, chain with `FD != 1`, night-only weather, cold-weather). Block 3 — assertion helpers
(`assert_additive(attr)`, `assert_per_array_shape(attr, n)`). Block 4 — tests by bucket:

- additivity (every chain variant, incl. multi-array, night, cold) — 12
- reference stage definition (25 C, no modifiers, FD != 1 case) — 10
- each bucket's value vs an independently staged reference — 18
- ordering / cumulative semantics (a permuted order gives different buckets) — 6
- per-array shapes and `_singleton_tuples` — 8
- the two alternative entry points — 10
- `to_frame` column order / aggregation — 8
- `as_fraction` incl. zero-reference and negative buckets — 8
- edge cases: empty index, single timestamp, all-night, cold (negative temperature bucket) — 8

AS BUILT: **270 tests**, mutation-proved (12 of 12 designed defects killed), all F2P. 5-axis coverage: described behavior, public API, solution branches, edge cases,
stated inverse (negative buckets).

## 10. Forced signatures

Python: no trait bounds, but the **return shapes are load-bearing** and must be pinned in meta —
per-array fields are a bare Series for one array and a tuple for several; `to_frame` returns a DataFrame
with a fixed column order; `as_fraction` returns a dict of six floats. Pinning these avoids the
fake-difficulty signature coin-flip.

## 11a. Difficulty history (batch-driven)

Batch 1 on the pre-shapley artifact: **3 of 4 PASS = 75 percent, too easy.** The description had
become a transcribable specification after ten fairness rounds. Hardened by adding `shapley()`,
whose difficulty is in DOING (a 64-subset lattice with factorial weights, replacing an obvious
4320-evaluation construction) rather than KNOWING, and which forces the real `ac_model` into the
staging path so `ac` must join the saved state. Pass rate of the hardened artifact is **unmeasured**;
batch 2 required.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt sentence (in meta) | Test that catches it |
| --- | --- | --- | --- | --- |
| 1 | Independent instead of cumulative attribution (each bucket = full minus full-without-X) | It is the obvious reading of "the loss caused by X"; interactions then leave a residual | "each stage keeps the mechanisms switched on by the earlier stages" + "the reference minus the six buckets equals AC power at every timestamp" | `additivity_*` and every per-bucket value test |
| 2 | Reference irradiance taken as `poa_global` | `poa_global` is the obvious loss-free irradiance and matches when `FD == 1`, so it passes the easy cases | "not plane-of-array global irradiance: it comes from the chain's own effective-irradiance calculation with the corresponding modifier replaced by one" | `reference_uses_chain_formula_when_fd_below_one` |
| 3 | In-place mutation of `results.dc` leaking across stages | `dc_ohms_from_percent` and `pvwatts_losses` mutate the DataFrame in place; reusing it double-applies losses | none (this is the one codebase-inferable requirement, visible in `modelchain.py`) | `dc_other_bucket_*`, `results_unchanged_after_attribution` |
| 4 | Per-array inverter bucket | Every other bucket is per array, so the inverter looks per array too; additivity then fails only for multi-array systems | "`inverter` and `ac` are system wide" | `two_array_*` additivity and shape tests |
| 5 | Clamping negative buckets to zero | "loss" reads as non-negative | "buckets are powers in watts and may be negative when a mechanism increases output" | `cold_weather_temperature_bucket_negative` |
| 6 | Dividing by zero reference energy at night | Natural fraction implementation | "every fraction is zero when reference energy is zero" | `as_fraction_night_only_all_zero` |

Traps 1, 2 and 3 are **interdependent** — fixing the cumulative order changes every bucket, fixing the
reference formula changes buckets 1 and 2 and therefore the additivity residual, and the mutation leak
surfaces as a wrong *later* bucket. Traps 1 and 3 are **misdirecting**: the failing assertion names a
downstream bucket, not the cause.

## 12. Tier + category

- Tier: **Olympus**
- Sub-rank: Olympus-Good targeted
- Category: **feature-request** (net-new public API on ModelChain)

## 13. Predicted pass rate

- Predicted: **10% - 25%**
- Reasoning: six named buckets are transcribable from meta (that is deliberate and fair), so the
  difficulty is entirely in DOING — staging seven recomputations through a pipeline that mutates its own
  results in place, with a per-array/system split that only breaks on multi-array systems. Corpus levers
  stacked: (1) one interdependent kernel driving seven stages, (3) misdirecting traps, (4) the
  obvious-code-is-wrong `poa_global` edge, (5) de-training via an obscure domain, (6) multi-file span.
  Lever (2) is satisfied by an internal exact invariant (additivity) rather than an external library.
- 0% risk: low — the contract is fully stated and a careful implementer reusing the chain's own methods
  lands it.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (architecture, subsystems, entanglement zones, pytest in `tests/`, template
      test file `tests/test_modelchain.py`)
- [x] Existing PR/issue check: 0 hits implementing loss attribution. Searched PRs and issues for
      "loss diagram", "waterfall", "loss attribution", "energy accounting", "loss breakdown",
      "loss decomposition", "marginal loss", "sankey", "attribution". Nearest neighbours: issue #1069
      (open, adds PVsyst-style loss *models*, not a decomposition) and PR #1354 (open, adds standalone
      `pvlib/mlfm.py`, does **not** touch `modelchain.py`) — no core-file overlap.
- [x] Closest approved problems opened side-by-side: `techan-costbasis` (invented accounting contract over
      an existing engine), `mp4ff-progressive-writer` (staged re-run of a pipeline)
- [x] Corpus hardness recipe: one kernel, exact invariant, 6 traps (3 interdependent, 2 misdirecting,
      1 obvious-code-is-wrong), all signatures pinned, not a famous portable spec
- [x] Title verb-led, 8 words, names the subsystem
- [x] Public API lists every asserted name
- [x] Canonical output form spelled out
- [x] <=1 codebase-inferable requirement (the in-place mutation)
- [x] Description ~380 words, in the approved corpus range, plain prose
- [x] File footprint sketched against real source
- [x] Meaningful LOC ~460, above the 450 design floor
- [x] 1+ pure-function helper per described behavior
- [x] Test outline 4-block, scenario-encoded names, ~85 tests
- [x] Return shapes pinned
- [x] 6 named traps with pre-empts and catching tests
- [x] Tier and category match
- [x] Not pattern-followable (no existing decomposition in the repo)

## Phase 5 — Failure-mode self-audit

- Bucket 1 (hidden requirements): every test in section 9 traces to a sentence in `meta.md`; the only
  unstated requirement is trap 3, which is visible in `modelchain.py` (the allowed single inferable).
- Bucket 2 (tech-spec tone): description is plain prose, no headers, no labels.
- Bucket 3 (passes on base): every test touches `run_loss_attribution` / `LossAttribution`, absent on base.
- Bucket 4 (over-constrained): no assertion on internal helper names or storage; all assertions are on
  public values and shapes.
- Bucket 5 (too small): ~460 meaningful LOC across 3 files, above the floor.

Real-revert-cause walk: no test.sh trickery, no exact full-string error assertions, no code duplication,
no scope creep, no regression on base, no AI comments (pvlib source *does* carry docstrings — match that
convention exactly), no weak assertions, no dead code, no flaky tests (suite verified deterministic 3x).

## Why this is not a duplicate

Closest approved: `techan-costbasis` (invented accounting contract over an existing engine — but a
lot-matching kernel in Go finance, not a staged re-simulation) and `mp4ff-progressive-writer` (pipeline
re-run — but byte-level container writing). Nothing in `Aprroved/`, `problems/`, `rejected/` or
`Olympus/problems/` touches pvlib, energy-loss decomposition, or marginal attribution. First pvlib
submission from this workspace.

Predicted iteration cycles: 2
