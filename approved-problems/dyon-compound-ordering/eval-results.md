# eval-results.md — dyon-compound-ordering

## Local Docker validation (olympus-base-rust, --network none, --user 1000:1000)
| Order | base (no regressions) | new (fail pre / pass post) | reverse-apply clean |
| ----- | --------------------- | -------------------------- | ------------------- |
| test then solution | 7/0 both | 48 fail (pre) -> 0 fail (post) of 57 | OK |
| solution then test | 7/0 | 57/0 | OK |

JUnit testcase counts: base 7, new 57 (>1). New-mode determinism in-container: 57/0 x3 identical. Image edition-2024 build: OK.

## Effective LOC (Counter 2 / hook human-effective)
- human-effective 472 (>= 430 target); raw 629; 4 files (dyon_std/mod.rs, module.rs, runtime/mod.rs, lib.dyon). Hook: OK.

## Solvability sim (3 Sonnet imitators, meta-only, blind to hidden tests, graded via image; 57 tests)
| Run | Result | Failed tests | Failure reason | Approach note |
| --- | ------ | ------------ | -------------- | ------------- |
| imit1 | **56/57** | 1: variable_built_equal_arrays_are_equal | solved the deep-ref trap for ORDERING (switched less/greater to Runtime-based registration for stack access + deep_clone) but did NOT extend value-resolution to `==`, so variable-built equal arrays still hit the latent Ref-swallow | base 7/0 clean; a valid alternative approach to the deep-ref requirement |
| imit2 | 36/57 | 21: whole compound-ordering core (array/object/option/vec4/bool + deep-ref) | got the canonical order + typecheck overloads wrong | implemented cmp/utilities but not the operator core |
| imit3 | **54/57** | 3: nested_variable_arrays_ordered, variable_built_arrays_compare_by_value, variable_built_equal_arrays_are_equal | ONLY the deep-ref trap: edited module.rs + dyon_std/mod.rs but NOT call_binop, so variable-built array elements (Refs) were not value-resolved | correctly implemented all 16 utilities + core order + object key-sort + error-propagation from meta alone |

Fair/unfair split: all remaining failures are FAIR (each traces to a documented behavior). One UNFAIR test found + removed: `kth_smallest_out_of_range_errors` pinned an undocumented "range" error keyword that both imitators missed (deterministic universal miss -> relaxed by dropping; out-of-range k is unspecified). Deep-ref trap DOCUMENTED post-sim (meta: "reads the current value ... rather than by reference") to keep it fair-discoverable and protect the solvability floor.

FP check: no imitator fully passed, so there is no false-positive pass to audit. Two independent NEAR-MISSES (imit1 56/57, imit3 54/57), both tripped ONLY by the documented deep-ref/value-resolution trap in its variants; imit1 found a valid alternative fix path (per-op Runtime registration). All 16 utilities implemented correctly from meta alone by imit1 and imit3 -> strong meta<->test alignment. Solvability: proven by construction (reference 57/57) and strongly supported by two 55+/57 near-misses on a now-documented trap. Predicted platform pass-rate: low but non-zero (deep-ref value-resolution + object-key-sort are the crux) -> hard/low-pass edge of the <=40% band, which is the target. Platform run is the real oracle.
