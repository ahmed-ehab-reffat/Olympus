# DESIGN.md — ray-optics-sp-coherence-transport

## 0. Phase 1 — repo understanding

- **Architecture.** ray-optics is a 2D ray tracer. Scene objects (`src/core/sceneObjs/*`) describe themselves as *primitives* (`src/core/primitive/types.js`: sources, surfaces, regions, detectors) whose optics are formula DAGs (`src/core/formula`). `preprocessPrimitives` deduplicates types, prepares curves and builds a BVH. Two engines run the processed scene: `CpuSimulationEngine` (JS; populate, initial region membership, then megakernel cycles that trace, write outgoing rays with `cpuOutgoingRays.js`, and resample the queue with `stableRayPowerSampling.js`) and `WebGpuSimulationEngine` (WGSL megakernel). `PrimitiveBasedSimulator` chooses an engine (`primitiveEngineSelection.js`) and falls back to CPU when WebGPU throws. A legacy engine (`Simulator.js`, `onRayIncident`) still exists and is scheduled for removal (ROADMAP, early 2027).
- **Subsystems.** (1) primitive contract + preprocessing (`primitive/types.js`, `preprocess.js`); (2) formula DAG compiler/evaluators (`formula/*`, owned by our approved conditionals problem, NOT touched here); (3) CPU engine (`simulationEngines/cpu/*`); (4) engine-shared queue and power policy (`stableRayPowerSampling.js`, `rayPower.js`, `primitiveEngineSelection.js`); (5) WebGPU engine (`simulationEngines/webgpu/*`); (6) scene objects + legacy engine.
- **High-entanglement zones.** `writeRegionBoundary` (Fresnel + TIR + membership), `writeSurfaceOutputs` (local frame, `outputCrossesBoundary` with the smoothLineSegment carve-out, membership), `finishMegakernelCycle` → `collectRayPowerQueue` (weak-ray amplification).
- **Tests.** jest, `test/primitive/*.test.js`, headless. Template: `test/primitive/CpuSimulationEngine.test.js` / the hunter probe (build primitives with `parseFormula`, `preprocessPrimitives`, run `CpuSimulationEngine`, read `update.result.detectors`).

## 1. Title
Add polarization coherence transport to the primitive simulation engine

## 2. Shape
O-Pipeline-hard (one new per-ray quantity carried through every ray-producing stage of an existing pipeline, with a contract extension and consumers). Best agent: Orion/Vega (long-horizon). Dominant verdict predicted: MISSED_REQUIREMENT (sign / site coverage), some REGRESSION (base unit tests without the new fields).

## 3. Public API surface
- Source DAG: optional labeled outputs `C_r`, `C_i` (both or neither; default 0).
- Surface DAG: reserved inputs `C_0r`, `C_0i`; optional per-slot outputs `C_jr`, `C_ji` (both or neither per slot).
- Detector DAG: reserved inputs `C_0r`, `C_0i`.
- `C_0r` / `C_0i` may not be surface or detector `paramNames` (TypeError at preprocessing); a half-labeled pair is a TypeError.
- `WebGpuSimulationEngine.prepare` rejects any processed scene that uses coherence (existing CPU fallback takes over).
- FINISH scope (not in the slice): Detector object Stokes readout, Polarizer / Retarder surface types (+ scene objects with a stated power-only legacy projection), source polarization property, automatic engine selection keeping coherence scenes on CPU.

## 4. Canonical form / conventions (all stated in meta.md)
- `C = E_s · conj(E_p)` as (real, imaginary). Basis: s out of the plane, p = the ray direction rotated by +90° (`(-d_y, d_x)`), in world and in the local surface frame alike.
- Valid state: `|C|² ≤ P_s·P_p`. Any C written by a source or an explicit surface output is scaled down to that bound keeping its phase; a non-finite C makes the ray invalid/inactive exactly like a non-finite power.
- Region boundary: transmitted C × sqrt(T_s·T_p) (unchanged without partialReflect); reflected C × r_s·r_p (Fresnel amplitude coefficients in this basis; at normal incidence = −R, the sign an ideal mirror gives); TIR uses the same coefficients with cos θ_t = −i·sqrt(m² sin²θ_i − 1).
- GRIN step: C × exp(−αL). Detector: pass-through keeps C.
- Formula surface slot without explicit outputs: C × sqrt(P_js·P_jp / (P_0s·P_0p)), negated when the slot stays on the incident side of the curve, 0 when either product is 0.
- Anything that rescales a ray's powers without an interaction rescales C by the same factor (the one site is weak-ray power sampling; NOT named in meta).

## 5-6. Description draft
See `meta.md` (draft). Budget target ≤ 450 words: the conventions are the fairness floor.

## 7. File footprint (spike measured, hook)
| Action | Path | human-eff |
|---|---|---|
| NEW | src/core/primitive/coherence.js | ~84 |
| MODIFY | src/core/simulationEngines/cpu/cpuOutgoingRays.js | ~72 |
| MODIFY | src/core/simulationEngines/cpu/CpuSimulationEngine.js | ~16 |
| MODIFY | src/core/primitive/preprocess.js | ~9 |
| MODIFY | src/core/simulationEngines/stableRayPowerSampling.js | 2 |
| MODIFY | src/core/simulationEngines/webgpu/WebGpuSimulationEngine.js | ~5 |
Slice total ≈ 190. FINISH plan: Detector Stokes (+25), Polarizer + Retarder primitive surface types with side flip (+70), source polarization property shared helper + 4 sources (+35), automatic engine routing in PrimitiveBasedSimulator (+15), legacy power-only projections (+20) → ≈ 330 human-eff. Floor 200 cleared by the core plus any two consumers.

## 8. Solution outline
`coherence.js` helpers: slot/pair validation, reserved-name validation, `limitCoherence`, `scaleCoherenceByPowers`, `multiplyCoherence`, `processedSceneUsesCoherence`. Engine: `createOutputRay` carries/limits C; each writer computes its factor; `getRayCoherence` treats a ray without the fields as incoherent (base unit tests build such rays).

## 9. Test outline
`test/primitive/coherence-<hex>.test.js`. Helpers: source builder with C outputs, Stokes-reading detector (P_0s, P_0p, C_0r, C_0i via k/v writes), segment/region builders, `run()` to completion. Buckets: contract validation, sources, formula surfaces (explicit, clamp, default rule sign, split, mixed slots, smoothLineSegment), region boundary (normal/oblique reflection, transmission, TIR), GRIN, detector pass-through, sampling amplification, WebGPU decline. Observation ONLY through detector DAG inputs (no internal ray field names).

## 10. Forced shapes
Tests only use DAG label names and existing engine APIs; no new JS signature is called except `WebGpuSimulationEngine.prepare` (existing).

## 11. Trap matrix
| # | Trap | F-id | Class | Axis | Interdependent with | Why agents hit it | Meta sentence | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | Repo's signed p expression is −r_p in the stated basis; reuse flips reflected C | F-20 family / A8 polarity | A8 | reflection sign | #3 (mirror default sign; a mismatch test fails whichever is wrong) | the expression is right there, squared, and "just remove the square" is natural | "product of the amplitude coefficients in that basis ... −R at normal incidence, the sign an ideal mirror gives" | normal + oblique reflection, circular light off glass vs mirror |
| 2 | Weak-ray sampling amplifies powers in a separate module; C must follow | F-1 / S4 machinery-riding | S4 | engine bookkeeping | #5 (detector reading is where it shows) | powers are rescaled outside any interaction, in a file about queues | general principle only, never names sampling | weak reflected ray, normalized coherence at detector |
| 3 | Default rule side test must be the geometric curve side (smoothLineSegment carve-out), not the local interpolated normal | F-9 origin / F-17 proxy | S2 | slot polarity | #1 | local frame is what the DAG sees; `d_jy>0` looks equivalent | "stays on the incident side of the curve" | smoothLineSegment cell |
| 4 | Base unit tests build rays without coherence fields | S3 preservation | S3 | baseline | — | NaN from undefined invalidates rays | none (repo tests) | base mode |
| 5 | Detector pass-through / TIR / GRIN sites each need C | F-9 | S4 | site coverage | #2 | writers rebuild rays from powers only | "every ray the engine produces carries C" | detector series, TIR, GRIN |
| 6 | Explicit-vs-default per slot, split slots, clamp | F-10 | S2 | slot form | #3 | per-type instead of per-slot | stated | mixed-slot cell |

## 11b. Cross-product
| | transmitted slot | reflected slot |
|---|---|---|
| default rule | + scale (test) | − scale (test) |
| explicit outputs | as given (test) | as given, clamp (test) |
| smoothLineSegment | geometric + (test) | geometric − (test) |

## 12. Tier/category
Olympus, feature-request ("Add ...").

## 13. Predicted pass rate
25-40% on the slice contract (sign conventions are stated; the walls are sampling, smoothLineSegment side test, reflection sign). FINISH consumers (polarizer side flip, retarder, Stokes sign by crossing direction) should push toward 15-30%.

## 14. Gates
- Quota: 1 approved ray-optics sub (formula conditionals) + this = 2/6. Dead lane handle-to-module (SATURATED-REPOS B2-RAYOPTICS) is a different subsystem.
- Derivative vs approved: approved pick = formula DAG language (src/core/formula/*: parser, evaluators, WGSL, derivative, range estimator; traps F-26/F-27). This pick touches none of those files; it is ray-state transport in the engines (traps: sign conventions, machinery-riding sampling, geometric side test). Different subsystem, different trap class.
- Exclusivity / SIX-CHECK / fork scan: clean (see feedback.md). Gate 5: engine programme merged 2026-08-22, repo quiet since 2026-08-28; no coherence work anywhere. Gate 8: no maintainer statement against; discussion #250 only covers the s/p power split.
- Gate 9: baseline 3/3 identical.

## Why this is not a duplicate
Closest approved: ray-optics-formula-conditionals (same repo, formula language). This one never edits the formula subsystem; the approved one never touched the engines. No approved problem in the corpus carries polarization or coherence (grep polariz/stokes/jones/fresnel/coheren: 0 hits).

Predicted iteration cycles: 2-3.
