# Exact-version false-positive audit - image-png static Adam7 encoding, L1

Status: **complete; pass**.

Date: 2026-08-15  
Repository: `image-rs/image-png` at
`721fd56651038c51bb3a6c2eabe9ab11b086db6e`.

Immutable submission artifacts:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `bf10cb00065ca0328f911b62b3f138d9e01e58921406efc642977c9b334dd46f` |
| `test.patch` | `cb5912a5dc5c09c8cd328854b80f1adbec007defa46aafd01418a4356707f689` |
| `solution.patch` | `af00d4c4e798ba3ba07a5244bc787120ff1b0a292bcbc94e73c060d97692582f` |
| `Dockerfile` | `52358a813ace9b8e812cab2831613cbd9fc601265ab205f04b9dcff529e57289` |
| `verify/mutations.sh` | `aaec5d832621b5930203e6271f43191227a0f3b0c3d8f051e8cdbc1f8261d1e4` |

The worked Statig false-positive record was read before this audit. Requirement
mapping and equivalence decisions are in `GAP_ANALYSIS.md`; assertion provenance
and architecture freedom are in `FAIRNESS_ANALYSIS.md`.

## Method

1. Map every public clause to its strongest behavioral oracle.
2. Construct plausible shortcuts from encoder match arms, the two complete
   prototypes, packed-row asymmetries, stream lifecycle, and prior binary-format
   trajectory lessons.
3. Compile and run each mutation against all focused tests without fail-fast.
4. Run any focused survivor through the complete upstream suite.
5. Admit a probe only when the reference and direct-row implementation pass,
   the pristine tree still fails, and the probe observes a distinct public
   boundary.
6. Rerun the exact offline composition gate after every artifact revision.

## Requirement-to-strongest-test map

| Requirement family | Strongest current discriminator |
|---|---|
| valid static Adam7 / IHDR | `rgb8_slice_roundtrip_and_ihdr` |
| pass geometry/order/empty passes | `tiny_images_omit_empty_passes` plus the independent scanline oracle |
| byte-aligned families | `byte_aligned_color_depth_matrix` |
| packed MSB samples and row padding | the two packed-family tests plus `source_row_padding_is_not_selected_as_pixels` |
| fixed filters and pass reset | `fixed_filters_apply_and_restart_at_each_pass` |
| named adaptive filter behavior | `min_entropy_matches_noninterlaced_pass_filtering` |
| compression branches | `compression_backends_encode_the_same_raster` |
| borrowed/owned stream boundaries | the two stream ownership tests |
| stream filter override and IDAT ceiling | their two isolated stream tests |
| exact input and sequence lifecycle | slice, stream, and sequence validation tests |
| non-interlaced compatibility | paired compatibility test plus base mode |

## Mutation results

`verify/mutations.sh` applies 16 one-defect implementations to the reference.
All compile. Current focused results:

| Mutation family | Result |
|---|---:|
| omit pass 7; reverse pass rows; carry filter state | caught, each by multiple pass/decode tests |
| LSB packed extraction; floor source stride | caught by four packed/stream/padding tests each |
| copy one byte per byte-aligned pixel | caught by ten representation/producer tests |
| leave streaming non-interlaced | caught by all five stream tests |
| ignore stream filter override | 16/17; isolated failure |
| ignore custom IDAT size | 16/17; isolated failure |
| accept a long slice | 16/17; isolated failure |
| discard excess stream input | 16/17; isolated failure |
| force all filters to Up | 14/17 |
| map MinEntropy to Adaptive | 16/17; isolated failure |
| compress `NoCompression` | 16/17; isolated failure |
| Adam7-encode non-interlaced output | 15/17 |
| bypass enabled interlaced sequence validation | 16/17; isolated failure |

The isolation results show that the narrow stream, compression, filter, length,
and sequence probes contribute distinct discriminators rather than more
fixtures for pass geometry.

## Actionable survivor and admitted probe

Before the current MinEntropy oracle was added, an implementation that replaced
interlaced `Filter::MinEntropy` with `Filter::Adaptive` compiled and passed all
16 focused tests. It then passed the complete suite:

- 89 library tests passed, 1 ignored;
- all eight pre-existing integration tests passed;
- all eight doctests passed; and
- all 16 then-current focused tests passed.

This is plausible because both public variants are adaptive selectors sharing
one internal call shape, while round-trip tests cannot distinguish them. The
new black-box probe constructs each expected Adam7 pass raster, encodes that
raster through the existing non-interlaced public MinEntropy path, and compares
the inflated scanlines. It does not reproduce the private entropy formula.

Results on the revised artifact:

- pass-buffer reference: 17/17;
- independent direct-row implementation: 17/17;
- MinEntropy-as-Adaptive mutation: 16/17, failing only the new probe;
- pristine implementation: 0/17 under the JUnit lane.

The probe is public, distinct, reference-passing, targeted-mutant-failing, and
still fail-to-pass on the pristine tree, so it was admitted.

## Other corrections and rejected survivors

- The first post-format audit replay cloned a local reference commit that had
  omitted the three newly added test files. Cargo's missing-target result was
  quarantined as setup failure and contributed no mutation evidence. The
  reference commit was rebuilt with all evaluator files, and the audit helper
  now aborts on a missing test target, compilation error, or non-test startup
  failure. The complete 16-mutant matrix above is from the corrected exact
  artifact replay.
- A pre-freeze review found that the initial reference ignored the public
  stream filter override. Correcting the implementation and adding its isolated
  probe prevented the reference from defining an incomplete contract.
- Source padding with nonzero unused bits was admitted because it crosses the
  packed-row stride/sample boundary. The oracle masks unused output bits, so it
  does not demand one private padding value.
- Enabled static sequence validation was admitted as an independent public
  lifecycle branch. Validation-disabled multiple writes were not generalized
  into hidden policy.
- Adaptive's exact cost heuristic, fdeflate byte identity/fallback ratio,
  arbitrary malformed PNGs, APNG, flush timing, allocation limits, and symmetry
  permutations were rejected as private, unstable, out of scope, or redundant.

## Final result

The exact current mutation set has zero survivors. That is evidence only for
the attempted 16 plausible defects. The one demonstrated predecessor survivor
was run through the full suite and closed with a distinct public oracle. Both
known legitimate architectures pass the final 17-test suite and the complete
base lane. The formatting-only regeneration of `solution.patch` was followed
by a new exact environment gate and corrected full mutation replay before this
verdict. False-positive verdict: **pass**.
