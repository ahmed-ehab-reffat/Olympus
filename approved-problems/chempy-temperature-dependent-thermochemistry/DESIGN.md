# DESIGN — chempy temperature dependent thermochemistry

## 1. Title

Add temperature dependent thermochemistry to chempy.

## 2. Repo, base, tier

- Repo: `bjodah/chempy`, BSD-2-Clause, 655 stars, Python, last source commit 2026-05-10.
- Base commit: `b291866275e9232495a0984e222e6f3a650f85ed`.
- Tier: Olympus (single tier, sprint 2026-07). Target the hard end of the band.
- Shape: O-Composite-add (a missing subsystem with several co-equal behavioural axes over
  one shared model layer), with an O-Algorithm-correctness core (two numerical solvers).

Pick gates, in the order `PICK-FILTER.md` asks for them:

| Gate | Result |
| --- | --- |
| behavioural F2P gap | `chempy.thermodynamics` holds a single equilibrium expression with **constant** enthalpy and entropy (`GibbsEqConst`). Nothing in the package knows a heat capacity, so no property can be evaluated away from 298.15 K. |
| saturation | chempy has never been submitted (0 of 6). One earlier local pick on the repo (`problems/chempy-redox-balancing`, ion-electron balancing) was shelved at design time on the LOC wall; different subsystem, different math, no shared surface. |
| uniform wrap | four opposing conventions (relative enthalpy, absolute entropy, kJ vs J, segment selection) that no single guard discharges. |
| LOC ceiling | missing core, not a repair of nearly correct code. Footprint table in section 7. |
| cold not live | issue #10 lists "Shomate equation" and "NIST-JANAF" under `chempy.thermochemistry` as unchecked since 2015. No commit has touched the area. |
| reproduce on base | every new test fails on base with `ImportError`/`AttributeError` on the new module. |
| dedup | no thermochemistry pick in `Aprroved/`, `problems/`, `rejected/`, or any `TaskN/problems/`. |
| exclusivity | `gh pr list --state all` over shomate, thermochemistry, JANAF, NASA, Kirchhoff, heat capacity, enthalpy, entropy, adiabatic: zero PRs. All 12 branches compared against master: only `chempy-0.6.x` touches `chempy/thermodynamics/`, and only its test file. |
| defined behaviour | the maintainer wrote the wishlist entry himself. The two polynomial forms are published models, the reaction level is classical thermodynamics. |
| no flaky repo | 551 passed / 33 skipped / 5 xpassed in 7.1 s, offline, as uid 1000, identical across runs. |
| repo quota | 0 of 6 ours; niche computational-chemistry repo at 655 stars, no global saturation profile. |

## 3. Public API surface

New subpackage `chempy/thermochemistry/`:

```python
Shomate(A, B, C, D, E, F, G, H, T_min=298.15, T_max=6000.0)
NASA7(coefficients, T_min, T_max)          # a1..a7
PiecewiseThermo(segments)                  # ordered models
SubstanceThermo(model, enthalpy_of_formation=0.0)

# every model and SubstanceThermo:
    .heat_capacity(T) -> J/(mol K)
    .enthalpy(T)      -> J/mol
    .entropy(T)       -> J/(mol K)
# SubstanceThermo adds:
    .gibbs_energy(T)

reaction_heat_capacity / reaction_enthalpy / reaction_entropy (reaction, thermo, T)
reaction_gibbs_energy(reaction, thermo, T)
equilibrium_constant(reaction, thermo, T)
as_equilibrium(reaction, thermo, T)
reaction_quotient(amounts, reaction, pressure)
gibbs_energy_at_composition(amounts, reaction, thermo, T, pressure)
mixture_enthalpy / mixture_heat_capacity / mixture_entropy (amounts, thermo, T)
entropy_of_mixing(amounts)
total_entropy(amounts, thermo, T, pressure)
adiabatic_temperature(amounts, reaction, thermo, T, extent=1.0)
equilibrium_temperature(reaction, thermo, K, T_min, T_max)
equilibrium_composition(amounts, reaction, thermo, T, pressure)
isentropic_temperature(amounts, thermo, T, pressure, final_pressure)
adiabatic_equilibrium(amounts, reaction, thermo, T, pressure)
simultaneous_equilibrium(amounts, reactions, thermo, T, pressure, tolerance, max_iterations)
Shomate.fit(temperatures, heat_capacities, enthalpy, entropy, T_ref, T_min, T_max)
```

`chempy/__init__.py` re-exports the four classes.

## 4. Canonical output form

- All quantities are plain floats in SI: J/mol, J/(mol K), K. No `quantities` objects.
- `enthalpy` is always **relative to 298.15 K** for a bare model, and **absolute** for a
  `SubstanceThermo` (formation enthalpy plus the model's relative term).
- `entropy` is always **absolute** (third-law), for both.
- Reaction level uses `Reaction.net_stoich`, so a species on both sides nets out.
- Out of range temperature raises `ValueError`; a solver with no root in the bracket raises
  `ValueError`.

## 5. Blind spot pre-empts

Sentences that must appear in `meta.md` because a test asserts them:

1. Shomate's tabulated enthalpy term is in kJ/mol while its heat capacity is in J/(mol K).
2. `NASA7.enthalpy` must be shifted to the same 298.15 K reference as `Shomate.enthalpy`.
3. Segment lookup picks the first segment containing the temperature; the shared boundary
   therefore belongs to the lower segment.
4. `SubstanceThermo.gibbs_energy` combines an absolute enthalpy with an absolute entropy.
5. `adiabatic_temperature` conserves the enthalpy of the whole mixture, not of the reaction.
6. `equilibrium_temperature` needs a bracket and rejects one that does not change sign.
7. `Shomate.fit` solves for A..E by least squares and for F, G, H exactly.

## 6. Description draft

See `meta.md`. Word budget target 470, hard cap 500.

## 7. File footprint

| File | Status | Raw + | Meaningful |
| --- | --- | --- | --- |
| `chempy/thermochemistry/models.py` | new | 326 | 188 |
| `chempy/thermochemistry/reaction.py` | new | 450 | 245 |
| `chempy/thermochemistry/__init__.py` | new | 35 | 28 |
| `chempy/__init__.py` | modified | 6 | 5 |

Measured: 817 raw, 466 human-effective over 4 files. The first draft came in at 368 and was
raised by adding the composition dependent Gibbs energy, the mixing and pressure terms of
the entropy, and the three coupled searches, not by widening the model family.

## 8. Solution outline

- `_BaseThermo` with `heat_capacity`, `enthalpy`, `entropy`, `_check_range`.
- `Shomate`: `t = T/1000`; Cp polynomial; enthalpy `1000 * (A t + B t^2/2 + C t^3/3 +
  D t^4/4 - E/t + F - H)`; entropy `A ln t + B t + C t^2/2 + D t^3/3 - E/(2 t^2) + G`.
- `NASA7`: Cp/R, H/(RT), S/R; `enthalpy` subtracts the value at 298.15 K.
- `PiecewiseThermo`: linear scan for the first containing segment.
- `SubstanceThermo`: adds the formation enthalpy, forwards entropy, derives Gibbs energy.
- Reaction level: `net_stoich` weighted sums; `equilibrium_constant` = `exp(-dG/(R T))`.
- `adiabatic_temperature`: enthalpy balance `H(products, T) - H(reactants, T0) = 0`,
  bracketed by the models' validity range, bisection to 1e-9 relative, explicit loop.
- `equilibrium_temperature`: bisection on `ln K(T) - ln K`.
- `Shomate.fit`: least squares on the five Cp basis functions, then F, G, H closed form.
- `reaction_quotient` and `total_entropy`: ideal gas activities and the mixing term.
- `isentropic_temperature`: bisection on the total entropy across a pressure change.
- `adiabatic_equilibrium`: the composition solve nested inside the temperature solve.
- `simultaneous_equilibrium`: sweep the reactions until no amount moves, else `ValueError`.

## 9. Test outline

Four blocks: builders for the four reference substances (H2O, CO2, N2, O2 Shomate cards and
one NASA7 card, all inline), assertion helpers, then granular tests. Coverage:
each model property at several temperatures against NIST tables, the two conventions, the
segment boundary, out-of-range errors, all five reaction functions, Kirchhoff consistency
as an invariant, mixture enthalpy, both solvers including their failure modes, the fit
round trip, and the re-exports.

## 10. Forced conventions

The description states every convention; nothing is left to the codebase to infer except
the use of `Reaction.net_stoich`, which is the only codebase-inferable requirement.

## 11. Predicted trap matrix

| Trap | Interdependent with | Misdirection |
| --- | --- | --- |
| kJ vs J in Shomate enthalpy | every reaction level function | heat capacity tests still pass |
| NASA7 absolute vs relative enthalpy | reaction enthalpy, adiabatic solver | entropy tests still pass |
| segment tie at the shared boundary | piecewise enthalpy and the solvers | looks like a rounding failure |
| enthalpy balance over the mixture | adiabatic temperature | looks like a bad bracket |
| bracket sign check | equilibrium temperature | looks like a tolerance failure |
| F, G, H from the constraints, not from the fit | fit round trip | Cp fit still matches |

## 12. Tier and category

Olympus, feature request.

## 13. Predicted pass rate

Target under 40 percent. The polynomial forms are trained knowledge, so difficulty rests on
the conventions and the two solvers rather than on the algebra.

## 14. Quality gates

- human-effective LOC >= 450 (hook): 466.
- every new test fails on base.
- base suite green, both apply orders, three identical runs.
- mutation battery over the traps.
- FP probe over the passing surface.
