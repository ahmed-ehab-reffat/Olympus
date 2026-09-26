# ray-optics-sp-coherence-transport — eval results

No platform batch yet. Local validation numbers are logged here as they are measured.

## Local validation — SLICE (2026-09-23)
| Check | Result |
|---|---|
| Docker build (factory-ray-optics-sp-coherence-transport) | OK, 87 s |
| base mode on base (uid 0 / 1000 / 4242) | 1301 cases, 0 failed |
| new mode on base | 27 cases, 27 failed |
| base mode with solution x3 | 1301 / 0 each run |
| new mode with solution x3 | 27 / 0 each run |
| hook human-effective (slice) | 192 (raw 231, padding floor 93) |
| mutants A/B/C | 3 / 1 / 1 tests killed |
No platform batch yet.

## Local validation, Auto Review fix round (2026-09-25)
| Check | Result |
|---|---|
| new mode on base | 28 cases, 28 failed |
| new mode with solution x3 | 28 / 0 each run |
| base mode with solution x3 | 1301 / 0 each run |
| surface-output WebGPU test with solution reverted | fails |
| 1e160 probes (bound / default slot) | 1e160 / 5e158 (was 1e161 / NaN) |
| hook human-effective | 192 (unchanged, under 200 floor) |

## Local validation, Auto Review round 2 (2026-09-25)
| Check | Result |
|---|---|
| new mode on base | 32 cases, 32 failed |
| new mode with solution x3 | 32 / 0 each run |
| base mode with solution x3 | 1301 / 0 each run |
| mutant: transmitted C times T_s only | 1 killed (oblique transmission) |
| mutant: no C_i finiteness check | 2 killed (both imaginary non-finite tests) |
| mutant: literal r_s r_p TIR phase | 2 killed (both TIR tests) |
| degenerate surface/detector coherence validation | TypeError thrown (probe, no test) |
| hook human-effective | 205 (13 are JSDoc; real code about 192) |

## Local validation, Auto Review round 3 (2026-09-25)
| Check | Result |
|---|---|
| new mode on base | 32 cases, 32 failed |
| new mode with solution x3 | 32 / 0 each run |
| base mode with solution x3 | 1301 / 0 each run |
| mutant: default slot without zero-incoming guard | 1 killed (single-polarization test) |
| limiter probe (1.3e308, 1.3e308), P = 1e150 | 7.07e149 each (was 0) |

## Batch 1 (2026-09-25, 10x Nova, round-3 artifacts): 7/10 PASS = 70% (ceiling now 50%)
| Run | Verdict | Exec calls | Src LOC (non-comment) | Failed tests | Approach note |
|---|---|---|---|---|---|
| N1 | PASS | 106 | 436 | - | coherence.js helper module + own tests in 5 existing test files |
| N2 | FAIL_MISSED_REQUIREMENT | 90 | 321 | crossed diagonal polarizers; matching polarizer | pair rule misapplied to INPUTS: rejects a surface reading only C_0r |
| N3 | FAIL_WRONG_LOGIC | 73 | 314 | both TIR tests | complex r_s numerator missing the imaginary term |
| N4 | PASS | 83 | 322 | - | definitionUsesCoherence per kind |
| N5 | PASS | 87 | 386 | - | no helper module; also touched webGpuParameterRanges.js |
| N6 | PASS | 88 | 315 | - | helper module |
| N7 | FAIL_MISSED_REQUIREMENT | 63 | 348 | crossed diagonal polarizers; matching polarizer | same misreading as N2 |
| N8 | PASS | 72 | 321 | - | inline label/param scan in WebGPU prepare |
| N9 | PASS | 56 | 356 | - | helper module |
| N10 | PASS | 76 | 363 | - | helper module |

Kill table: polarizer pair (2 tests) 2/10, TIR pair 1/10, the other 28 tests 0/10.
Long-horizon: median ~80 exec calls, passer source diffs 315-436 non-comment lines.

### Differential probe (worktrees/_probe/rayoptics, src-only apply on clean BASE, Docker)
31 stated-but-untested scenes x (REF + 10 runs): slot-2 explicit / half pair / clamp, TIR without partial reflection, curved and back-side mirrors, boundary-merging surfaces (both curve directions), inside-glass reflection/transmission, shared-edge and nested regions, GRIN with partial reflection, NaN in an ignored slot, zero-power sources with C, chained default slots, C_0i-reading formulas, multi-generation sampling, 8 WebGPU accept/reject cases.
Result: ZERO divergence among the 7 passers on every axis. Only split: N2/N7 reject a surface reading one of C_0r/C_0i (their known bug). Derivable surface is exhausted (L83).

## Local validation, slot-2 tests (2026-09-25)
| Check | Result |
|---|---|
| new mode on base | 33 cases, 33 failed |
| new mode with solution x3 | 33 / 0 each run |
| base mode with solution x3 | 1301 / 0 each run |
| probe: slot-2 axes vs the 10 saved runs | 0 divergence (coverage only, no kills expected) |

## Local validation, FINISH round (2026-09-25)
| Check | Result |
|---|---|
| new mode on base | 48 cases, 48 failed |
| new mode with solution x3 | 48 / 0 each run |
| base mode with solution x3 | 1301 / 0 each run |
| M5 axis ignores sigma | 4 killed |
| M6 axis ignores obliquity | 3 killed |
| M7 retarder phase conjugated | 3 killed |
| M8 Stokes unsigned | 1 killed |
| M9 bins not offset on read | 1 killed |
| M10 always polarimetric detector type | 1 killed |
| Counter-2 human-effective | 480 (raw 724) |
| meta.md body | 742 words, ASCII |

## Local validation, FINISH Auto Review round (2026-09-26)
| Check | Result |
|---|---|
| new mode on base | 50 cases, 50 failed |
| new mode with solution x3 | 50 / 0 each run |
| base mode with solution x3 | 1301 / 0 each run |
| W1 polarimetry zeroes normal/shear | 1 killed |
| W3 Polarizer static type missing | 1 killed |
| W3b Retarder static type renamed | 1 killed |
