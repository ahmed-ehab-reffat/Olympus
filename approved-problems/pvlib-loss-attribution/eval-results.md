# eval-results.md — pvlib-loss-attribution

Base commit: `e6267a58d54964ab257321d0944ba179dc06a9bb`
Tier: Olympus · Shape: O-Algorithm-correctness · Predicted pass rate: 10-25%

## Agent runs

### Batch 1 (2026-08-03) - 249-test version, BEFORE the shapley hardening

**3 of 4 PASS = 75 percent. Over the 40 percent cap: TOO EASY.** FP check clean - every passing run
was judged PASS_LEGITIMATE with `agent_blame_unfair=false`, so the tests and the description are
aligned and the problem is purely under-difficult.

| Batch | Agent | Evaluator | Verdict | Files | Added LOC | Failed tests | Failure reason |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Nova #1 | Nova | PASS_LEGITIMATE | 2 | 362 | 0 | - |
| 1 | Nova #2 | Nova | FAIL_MISSED_REQUIREMENT | - | - | 4 of 249 | staging always assigned tuple-shaped effective irradiance, breaking custom DC callables on single-array runs |
| 1 | Nova #3 | Nova | PASS_LEGITIMATE | 4 | 267 | 0 | - |
| 1 | Orion #1 | Nova | PASS_LEGITIMATE | 4 | 509 | 0 | - |

Root cause of the 75 percent: after ten fairness rounds the description had become a complete,
transcribable specification. The evaluator's own summary of a passing run - "staged recomputation,
shape preservation, summaries, inverter allocation, and clearing stale attribution" - is a list of
rules to type in, not a problem to solve. The only failure came from an interaction the prose did not
hand over (per-array shape versus custom callables), which is the shape the hardening had to take.

### Batch 2 - not yet run

The `shapley()` hardening below landed after batch 1. **A fresh batch is required**; the pass rate of
the current artifact is unmeasured.

## Local validation (2026-08-03)

Platform order replayed: image built from the base tree, patches applied afterwards, run offline
(`--network none`) as `--user 1000:1000`.

| State | Mode | Exit | Testcases | Failures | Errors |
| --- | --- | --- | --- | --- | --- |
| base + test.patch | base | 0 | 1561 | 0 | 0 |
| base + test.patch | new | 1 | 270 | 270 | 0 |
| base + both patches | base | 0 | 1561 | 0 | 0 |
| base + both patches | new | 0 | 270 | 0 | 0 |

F2P: 270 of 270 new tests fail on base and pass with the solution. Zero collection errors.

## Flakiness gate (mandatory)

| Mode | Runs | Result |
| --- | --- | --- |
| new | 3 | `270 passed` every run |
| base | 5 | `1388 passed, 171 skipped, 2 xfailed` every run |

Vanilla repo suite before any change: `1388 passed, 0 failed` (3 independent runs, identical).
No RNG, clock, network, ordering or resource dependence in the new tests.

## Size

| Metric | Value | Floor |
| --- | --- | --- |
| human-effective LOC (Counter 2) | 327 | 250 (2026-07 sprint) / 430 (older target) |
| raw added LOC | 698 | 500 |
| padding-floor | 192 | - |
| source files | 3 (1 new, 2 modified) | 2 |
| new tests | 270 | - |
| meta.md words | 536 | cap raised by user |

Per-file: `pvlib/lossattribution.py` 353 raw / 132 eff · `pvlib/modelchain.py` 344 raw / 194 eff ·
`pvlib/__init__.py` 1 raw / 1 eff.

## Reference behavior spot-checks

Additivity residual (`reference - sum(buckets) - ac`, worst timestamp) across configurations:

| Configuration | Residual | Note |
| --- | --- | --- |
| pvwatts, 1 array, clear sky | 1.8e-15 | |
| pvwatts + pvwatts_losses | 2.8e-17 | `dc_other` 208 W |
| sapm + sapm spectral + ohmic | 0.0 | all eight buckets exercised |
| cec single-diode + ohmic + losses | 0.0 | |
| 2 arrays, sandia multi inverter | 4.6e-13 | float noise on ~21 kW |
| 3 arrays, pvwatts | 2.3e-13 | |
| cloudy input | 1.1e-13 | `weather` bucket 11.5 kW of 26.1 kW reference |
| cold input | 1.1e-16 | `temperature` bucket negative (-164 W) |
| night only | 0.0 | all buckets zero, fractions zero |
| empty index | n/a | empty Series, fractions zero |
| single-array list input (singleton tuples) | 7.1e-15 | buckets returned as 1-tuples |
| from_poa | 1.1e-16 | |
| from_effective_irradiance | 1.1e-16 | first four buckets zero |
| `FD = 1.0 / 0.5 / 0.0` | <= 7.1e-15 | reference 1887 / 1777 / 1668 W - the `poa_global` trap discriminates |

## Mutation proof (FP gate, review round 1)

Every designed defect implemented in the reference on purpose; a surviving mutation is a false
positive waiting to happen.

| Mutation | Killed by | Notes |
| --- | --- | --- |
| M1 inverter loss all on array 0 | 4 | |
| M2 zero-DC share collapses to zero | 3 | survived round 1; night test was vacuous on a pvwatts inverter (0 W at night) |
| M3 reference irradiance = `poa_global` | 2 | fires only when `FD != 1` |
| M4 reference cell temperature 20 C | 6 | |
| M5 `dc_ohmic` / `dc_other` stages swapped | 5 | |
| M6 no state restore after staging | 1 | survived round 1; only `spectral_modifier` is left corrupted |
| M7 transposition stage dropped | 4 | |
| M8 buckets clamped non-negative | 29 | |

| M9 spectral bucket silently NaN | 43 | added round 2; `DataFrame.sum` skips NaN, so the additivity helper tolerated it until tightened |
| M10 transposition stage uses run weather, not clear sky | 6 | added round 2 |

| M11 single-array shape always wrapped in a tuple | 47 | added round 4 |
| M12 `as_fraction(per_array=True)` uses the system reference | 1 | added round 4 |

| M13 ordinary runs do not clear a stale attribution | 3 | added round 6; found a real bug in the reference |
| M14 clear-sky model hard-coded to ineichen | 3 | added round 6 |
| M15 transposition model hard-coded to haydavies | 2 | added round 6 |

| M16 per-array inputs misrouted (arrays swapped) | 2 | added round 7 |
| M17 clear-sky transposition uses absolute airmass | 1 | added round 7; **survived** until perez transposition tests were added, because haydavies ignores the airmass argument |

| M18 reflection stage re-derives IAM instead of reusing the chain | 3 | added round 8 |
| M19 reference stage rebuilt from the supplied weather | 16 | added round 8 |

| M20 staging ignores the configured cell temperature | 7 | added round 9 |
| M21 attribution scribbles a column on the caller input | 2 | added round 9; first version mutated the already-copied `results.weather` and survived, which was a bad mutation rather than a gap |

| M22 equal split whenever any array is idle | 2 | added round 10 |
| M23 `cumulative()` drops the reference column | 2 | added round 10 |

| M24 shapley uses uniform instead of factorial weights | 8 | added round 11 |
| M25 shapley baseline is the reference stage | 9 | added round 11 |
| M26 lattice does not restore results | 2 | added round 11; **survived** until the lattice was reordered largest-first, because the full subset was evaluated last and restored the state by accident |
| M27 subsets keep the actual inverter always | 9 | added round 11 |

27 of 27 killed, 0 survivors.
