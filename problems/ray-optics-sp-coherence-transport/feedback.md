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
