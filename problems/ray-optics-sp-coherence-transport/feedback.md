# ray-optics-sp-coherence-transport — feedback

NEXT (human): Requirement 0 picker check + upload this slice to the platform precheck, then write the verdict in pipeline/INBOX.md

## STATUS
- 2026-09-23 MODE=SLICE started. Clone `worktrees/ray-optics` @ e55947ec (same base as the approved formula-conditionals problem; upstream HEAD unchanged since 2026-08-28).
- Exclusivity/SIX-CHECK 1-3 (2026-09-23): canonical slug unchanged (ricktu288/ray-optics, 1781 stars, Apache-2.0). PR+issue search in all states for polarizer/polarization/waveplate/retarder/birefringent/stokes/jones/coherence/phase shift/fresnel/TIR/quarter-wave/brewster: only #135 diffraction grating, #60 Fresnel lens example, #6 beam splitter (2017, closed "implemented by pfalstad"), none touch coherence. Discussion #250 (Wollaston): maintainer says Custom Surface handles it (s/p power split only). No maintainer refusal. Fork-branch scan of every fork pushed in 2026: no polarization/coherence commits (ssenhorst/wave-optics is a scalar wave engine, keshuaixu zemax import, shihanqu webgpu, jakobpl UI). CLEAN.
- ROADMAP: primitive engine becomes default early 2027; wave optics 2028-30. Polarization not listed (no public pick-list row).
- Gate 9 baseline: `npx jest test/primitive test/sceneObjs` 62 suites / 1072 tests, 3/3 identical.
- Gate 6 F2P (base, CPU engine): crossed +45/-45 formula polarizers pass 0.25 (physics 0); a surface DAG reading C_0r evaluates NaN and the ray is dropped silently.
- CORE SPIKE (contract validation + source C + boundary transmit/Fresnel reflect/TIR phase + GRIN + formula-surface default/explicit/clamp + detector input/pass-through + sampling + membership discard): hook 183 human-eff / 218 raw over 5 files (includes ~20 eff of routing helpers not yet wired). Honest core ~165 > 150: PROCEED. Padding-floor 90 (the C real/imag pair doubles lines) - FINISH must add orthogonal depth (Stokes detector, Polarizer/Retarder surface types, source polarization, WebGPU decline + automatic routing), not breadth.
- Preservation seam found: existing `cpuOutgoingRays.test.js` hand-builds source rays without coherence fields; a solution that reads them as NaN fails 3 base tests (a ray without the fields must count as incoherent).
- `summarizePrimitiveWorkload` is pinned by `toEqual` in `primitiveEngineSelection.test.js`: routing must not add a field there.

## Decisions made unattended (conservative choices)
(none yet)

## Attempt history

### 2026-09-23 SLICE READY (Step 4b)
- Solution (6 files): new `src/core/primitive/coherence.js`; `preprocess.js` (pair + reserved-name validation); `CpuSimulationEngine.js` (source C_r/C_i, clamp, membership discard); `cpuOutgoingRays.js` (TIR phase, Fresnel r_s r_p, sqrt(T_s T_p), GRIN, formula-surface default/explicit/clamp, detector input + pass-through); `stableRayPowerSampling.js` (C follows amplification); `WebGpuSimulationEngine.prepare` rejects coherence scenes (CPU fallback). Hook: 192 human-eff / 231 raw (slice only, under floor by design).
- Tests: `test/primitive/coherence-e4d83f.test.js`, 27 tests, all observed through detector DAG inputs (no internal ray fields). 27/27 fail on base, 27/27 pass with the solution. 4 tests first passed on base vacuously (base cannot read C, so "C = 0" held) and were given base-failing observations.
- Trap reproduction (natural-but-wrong mutants): (A) reusing the repo's signed p expression kills 3 (normal + oblique reflection AND the sampling test: interdependent); (B) sampling not rescaling C kills 1; (C) default-rule side test from the local frame (`d_jy`) instead of the curve kills the smoothLineSegment cell.
- Docker clean room (fresh clone at BASE, `--network none`) as 0:0, 1000:1000 and 4242:4242: base on base 1301/0, new on base 27/27 fail, base+new with solution 1301/0 and 27/0, three identical runs. Build 87 s (Dockerfile: COPY --chown + find chmod, no bind mount, no chmod -R).
- meta.md draft: 471 words incl. frontmatter, ASCII, one line per paragraph.

### FINISH plan (differentiating scope, after the precheck verdict)
- Detector object Stokes readout (S1, S2 = 2 Re C, S3 = 2 Im C, signed by crossing like power).
- Polarizer and Retarder as primitive surface types (axis angle flipped by sigma for back-side incidence; retarder phase sign vs TIR phase sign = rhomb+retarder cancellation cell), scene objects with a stated power-only legacy projection.
- Source polarization property (shared helper across Beam/PointSource/SingleRay/AngleSource).
- Automatic engine selection keeps coherence scenes on CPU WITHOUT changing `summarizePrimitiveWorkload`'s shape (pinned by toEqual in primitiveEngineSelection.test.js).
- Fresnel-rhomb composite cell, detector-reads-C WebGPU decline cell, meta trim to stay under 500 words.
- Target >= 250 human-eff (projection ~330).

### 2026-09-25 Auto Review: Revision Requested (Desc 3/3, Tests 1/3, Solution 2/3)
- T3/T4 High: the only WebGPU test used a coherent SOURCE, so a source-only prepare guard passed. Added `keeps scenes whose only coherence is a surface output off the WebGPU engine`: plain source + MIRROR prepares (resolves), same scene with `C_1r = 0; C_1i = 0;` rejects. Resolve half also blocks a reject-everything guard. Fails on base.
- S1 Medium x2 (P_s=P_p=1e160 overflow): `limitCoherence` now uses sqrt(P_s)*sqrt(P_p); `scaleCoherenceByPowers` checks each power > 0 and multiplies per-component sqrt ratios. Probe: bound case -> 1e160, halving surface -> 5e158 (was 1e161 / NaN). Ordinary values unchanged. No test added for 1e160 (not stated in meta; would be a hidden wall).
- meta.md, Dockerfile, base unchanged -> test/solution-only edit (re-eval eligible; no batch run yet anyway).
- Docker clean room (fresh clone @ BASE, --network none, uid 0): new on base 28/28 fail; with solution new 28/0 x3, base 1301/0 x3; new test with solution reverted fails.
- Still open: human-eff 192 < 200 floor (slice). FINISH scope still owed before submit.

### 2026-09-25 Auto Review round 2: Revision Requested (Desc 3/3, Tests 1/3, Solution 2/3)
- T3/T4 High (transmission only at normal incidence, T_s = T_p): added `transmits coherence with the geometric mean of unequal oblique transmissions` (45 deg into n=1.5, detector inside the region, asserts T_s != T_p). Mutant "C times T_s" killed by exactly this test.
- T4 Medium (non-finite C_i untested): added source `C_i = 1/0` and slot `C_1i = sqrt(-1)` tests. Mutant dropping the C_i finiteness check killed by exactly these 2.
- S1 Medium (degenerate curves skipped the new type checks): surface and detector coherence checks moved ahead of `preparePrimitiveCurve`. Probed: zero-length surface with a half pair and zero-length detector declaring C_0r both throw TypeError. No test added (degenerate geometry is not in meta; would be a hidden wall).
- S2 Low: types.js JSDoc now documents C_0r/C_0i, C_jr/C_ji, source C_r/C_i and the reserved-name rule.
- Advisory coverage taken: second TIR case (45 deg, m=1.6, complex C), second GRIN case (unequal powers, other alpha/step), WebGPU read-only surface and detector cases folded into the first WebGPU test. Skipped: basis-convention and a second sampling weight.
- FOUND BY ME, NOT THE REVIEWER: meta said the reflected C is "multiplied by r_s r_p" and TIR uses "the same two coefficients". With complex TIR coefficients that literal product gives the phase SUM; the tests and solution use r_s conj(r_p) (phase difference, correct for C = E_s conj(E_p)). Mutant "literal r_s r_p" fails both TIR tests, so an agent following the text exactly would fail. meta.md reworded: "multiplied by r_s times the complex conjugate of r_p ... while they are real that is just r_s r_p". Body 466 words, ASCII.
- This round touched meta.md, so a batch after it is full price (no batch yet, so no loss).
- Clean room: new on base 32/32 fail; with solution new 32/0 x3, base 1301/0 x3.
- LOC: hook says 205 but 13 of that is types.js JSDoc; real code about 192, still under the 200 floor. FINISH scope still owed.

### 2026-09-25 Auto Review round 3: Revision Requested (Desc 3/3, Tests 1/3, Solution 2/3; LOC counted ~205 by reviewer)
- T3/T4 High (zero INCOMING product untested): added a scene to `gives no coherence to slots that carry a single polarization`: source (P_s, P_p) = (0, 0.5) through an unlabeled slot with P_1s = P_1p = P_0p, detector expects [0.5, 0.5, 0, 0]. Folded into the existing test because on its own it passes on base (base reads C as 0). Mutant "no incoming > 0 guard" (0 * Infinity -> NaN -> slot dropped) killed by exactly this test.
- S1 Medium x2 (Math.hypot overflow at 1.3e308 components): `limitCoherence` now normalises by the larger component before hypot and compares against limit / largest. Probe: (1.3e308, 1.3e308) with P = 1e150 -> 7.07e149 each (was 0). Small and ordinary inputs unchanged. No test (pathological, not in meta).
- Advisory taken: both half-pair directions for source and surface, both C_0r and C_0i on surface and detector (loops in the existing 4 validation tests); second oblique reflection case at 60 deg into n=1.8 (near Brewster, r_p ~ 0.01) with maxRayDepth 2 (without it a multiply-reflected ray reaches the detector, +0.0073 on P_s). Skipped: basis rotation, simulator-level CPU fallback (jest has no WebGPU, so the fallback path is not discriminating there).
- test.patch + solution.patch only this round (meta untouched since round 2).
- Clean room: new on base 32/32 fail; with solution new 32/0 x3, base 1301/0 x3.

### 2026-09-25 Batch 1: 7/10 Nova (70%), over the ceiling (now 50%)
- Graded the round-3 artifacts (workspace diffs contain the round-3 test content). Agents saw the conjugate TIR wording.
- Diagnosis: fully stated kernel, transcribed (L58). Kernel tests 0 kills; the only kills are the N2/N7 misreading (pair rule applied to C_0 inputs) and N3 TIR arithmetic.
- Differential probe: 31 axes, zero divergence among passers (L83). More test cells on this contract will not move the rate; re-eval levers are exhausted.
- Auto Review (Approved, Tests 2/3) Medium gap: slot-2 explicit C and slot-2 half pair untested. Added `sets explicit coherence on a later output slot` + slot-2 half-pair loop. Probe says 0 kills (all agents correct): coverage only.
- NEXT: harden needs a description delta (full batch). Candidate = the FINISH scope (scene-object integration: light-source polarization, Detector Stokes readout, Polarizer/Retarder objects, automatic CPU routing), which also lifts the reference over the LOC floor. Awaiting user decision.

### 2026-09-25 FINISH round (harden after batch 1 = 7/10): description delta, needs a FULL batch
- Diagnosis (batch 1 + 31-axis probe): stated kernel transcribed (L58), zero passer divergence (L83). Lever = new integration scope with a derivation the contract states but does not hand over.
- Added scope (meta 466 -> 742 words, under the 1000 reject line; >500 is only a warning per user 2026-09-25):
  - `Polarizer` + `Retarder` scene objects (src/core/sceneObjs/other/, exported from sceneObjs.js, toolbar, en locales, theme). Axis fixed to the object: cos(axis) s + sin(axis) (p2-p1)/|p2-p1|, projected onto the ray's transverse plane and renormalised. In the local surface frame that is a_p ~ sigma * (-d_0y) * sin(axis): the sigma back-side flip and the oblique factor are the hidden derivation. Retarder: e^(i retardance) on the (-a_p, a_s) component.
  - Detector `polarimetry` option: `stokes` = [S1, S2, S3] signed like `power`, filled by updateMeasurementsFromPrimitiveResults, null when off; bins move after the Stokes sums; the off state keeps the old detector types so WebGPU still accepts it.
  - Power-only legacy onRayIncident for both objects and S1 in the legacy Detector (unstated, untested, product completeness).
- Dropped from the FINISH plan: source polarization (breadth, no new mechanism) and automatic routing (only testable through internal selection methods; the base fallback already runs coherent scenes on CPU).
- Tests 33 -> 48: 11 element tests (crossed/aligned objects, back side, swapped endpoints, oblique Polarizer, slanted Polarizer, defaults, QWP circular, HWP rotation, Retarder from behind, oblique Retarder, double-pass QWP isolator), 3 Detector tests, 1 scene JSON load/save test. Oracle = complex Jones matrices on the coherency matrix in world coordinates (independent of the reference's closed forms). The isolator passing confirms the whole sign convention is physically consistent.
- Mutants (each asserted applied): ignore sigma -> 4 killed (back side, swapped, Retarder back, isolator); ignore obliquity -> 3; conjugate retarder phase -> 3; unsigned Stokes -> 1; bins not offset -> 1; always polarimetric detector type -> 1 (WebGPU cell).
- Clean room: new on base 48/48 fail; with solution new 48/0 x3, base 1301/0 x3. Counter-2 human-effective 480 (was ~192).
- Prediction: 20-40%. The sigma/obliquity derivation and the Retarder arithmetic are the new walls; batch-1 walls (pair-rule misreading, TIR arithmetic) stay.

### 2026-09-26 Auto Review on the FINISH round: Revision Requested (Desc 3/3, Tests 1/3, Solution 3/3), no runs yet
- T3/T4 x3, all test-only (meta and solution unchanged):
  - `keeps the force readings of an oblique crossing unchanged`: same 30-degree ray through identical Detectors with polarimetry off/on; power, normal, shear, binData equal (normal and shear asserted nonzero), plus stokes null vs [0.2, 0.4, 0.2] so the test fails on base.
  - `uses the direction of a slanted or reversed Retarder for its axis`: Retarder on [3,-5]->[6,15] and on reversed [5,10]->[5,0], Jones oracle with the actual segment direction.
  - JSON test now asserts saved `type` names (Polarizer, Retarder, Detector) and reloads the saved JSON as a round trip.
- Mutants: polarimetry branch zeroing normal/shear -> 1 killed; Polarizer without static type -> 1; Retarder static type renamed -> 1. The "hardcoded +y Retarder" mutant cannot be written on this architecture (shared local-frame formula); the new cases' axes differ from a vertical segment's (slanted 0.8221/0.5693 vs 0.8192/0.5736, reversed sign flip).
- Clean room (harness now under worktrees/_probe/rayoptics/val, scratchpad was wiped): new on base 50/50 fail; with solution new 50/0 x3, base 1301/0 x3.
- Still owed: the FULL batch on the FINISH meta (description delta, no re-eval).
