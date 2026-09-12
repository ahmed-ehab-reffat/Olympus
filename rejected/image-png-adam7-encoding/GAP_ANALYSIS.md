# Exact-version gap analysis - image-png static Adam7 encoding, L1

Verdict: **pass**.

Date: 2026-08-15  
Repository: `image-rs/image-png` at
`721fd56651038c51bb3a6c2eabe9ab11b086db6e`  
Artifact set: `meta bf10cb00`, `test cb5912a5`, `solution af00d4c4`,
`Dockerfile 52358a81`.

`GAP_ANALYSIS.md` at the workspace root was read before this audit. The audit
was restarted after each prompt or verifier revision and applies only to the
full hashes recorded in `ENVIRONMENT.md`.

## Atomic requirement map

| Public obligation | Independent dimensions | Strongest black-box discriminator | Coverage |
|---|---|---|---|
| A static interlaced request emits a valid Adam7 PNG | IHDR flag, slice producer, exact raster reconstruction | `rgb8_slice_roundtrip_and_ihdr` inspects IHDR and decodes exact pixels | direct |
| Seven passes use standard order/geometry and omit empty passes | nontrivial all-pass image; 1x1, narrow, short, and asymmetric tiny images | independent IDAT inflater/unfilterer plus `tiny_images_omit_empty_passes` | direct |
| Every currently valid color/depth pair works | 15 valid combinations; byte-aligned versus packed | byte-aligned matrix plus separate packed grayscale/indexed cases | direct |
| Packed input is MSB-first and row-padded; padding is not a pixel | 1/2/4-bit, odd width, grayscale/indexed, nonzero source padding | independent logical-sample pass rows and padding-masked decoded comparison | direct |
| Each pass restarts filter history and honors `Filter` | five fixed filters, `Adaptive`, `MinEntropy`, encoder setting and stream override | exact advertised fixed filters; pass-local reconstruction; each `MinEntropy` pass compared with the existing non-interlaced writer; stream override probe | direct |
| Existing DEFLATE selections remain usable | stored, fdeflate, and flate2 branches | all three independently inflate/decode; no-compression requires filter 0 and a stored DEFLATE block | direct |
| Slice, borrowed stream, and owning stream accept the ordinary raster | whole slice; irregular write splits; packed and byte-aligned representatives | three producer tests decode exact pixels; both stream ownership forms are explicit | direct |
| Stream chunk ceiling remains effective | custom 17-byte IDAT payload ceiling, multi-chunk output | every IDAT payload is at most 17 bytes and more than one is emitted | direct |
| Exact length and enabled sequence validation remain effective | slice short/long; stream incomplete/excess; first/second static image | dedicated negative lifecycle cases use only `is_err`, after a valid interlaced positive | direct |
| Non-interlaced behavior remains compatible | ordinary static slice plus complete upstream suite | paired interlaced/non-interlaced decode and five genuine base groups | direct |
| Interlaced APNG is excluded | animation/default-image/frame policy | no focused predicate | intentionally absent |

## Equivalence classes and weak cells

| Dimension | Grouped equivalent cells | Separate repository branches challenged | Remaining weak cell | Evidence and decision |
|---|---|---|---|---|
| Color/depth | Same byte-copy logic groups grayscale/indexed 8-bit and the multi-sample 8/16-bit families | packed 1/2/4 versus byte-aligned; indexed versus grayscale | none | all 15 accepted pairs run; one-byte-pixel mutant scores 7/17 |
| Geometry | Dimensions with the same active-pass set are grouped | all-pass, 1x1, vertical-only, horizontal-only, and asymmetric tiny forms | no extra width/height permutations | omit/reverse-pass mutants score 3/17; more sizes repeat the same arithmetic |
| Filtering | Fixed filters share selection plumbing but have separate filter implementations | five fixed variants, Adaptive round trip, MinEntropy semantics, pass reset, stream override | Adaptive's private cost heuristic | exact Adaptive byte choice is not promised; MinEntropy has a named repository semantic and is direct |
| Compression | Levels within the flate2 arm are grouped | NoCompression, fdeflate, flate2 | fdeflate stored-fallback size choice | valid zlib output is public; compressed identity and ratio are explicitly unprescribed |
| Producer | default constructors delegate to their sized variants | slice, borrowed stream, owning stream, irregular `Write` boundaries | explicit empty writes and mid-row `flush` | ordinary `Write` behavior and existing mid-row flush policy add no Adam7 semantic branch |
| Validation | byte-aligned representatives exercise generic length counters | short, long, incomplete, excess, and opt-in sequence state | palette-missing wording and validation timing | palette success is direct; exact errors and unrelated invalid configurations are outside the contract |
| Compatibility | metadata/chunk publication remains in the existing writer | non-interlaced static plus full upstream PNG/APNG suite | interlaced APNG | explicitly excluded because upstream policy is unresolved |

## Gap trials

All current mutations compile. Scores are focused passes out of 17.

| Plausible incorrect implementation | Focused result | Full-suite result if needed | Targeted result | Decision |
|---|---:|---:|---|---|
| Omit pass 7 or reverse all pass rows | 3/17 each | not escalated | broad independent scanline/decode failures | caught; distinct pass-order family |
| Carry filter history across pass boundaries | 3/17 | not escalated | fixed/pass-local filter cases fail | caught |
| Read packed samples LSB-first or floor the padded source stride | 13/17 each | not escalated | both packed families, stream-packed, and nonzero-padding case fail | caught |
| Treat every byte-aligned pixel as one byte | 7/17 | not escalated | multi-sample and 16-bit families fail | caught |
| Keep the old non-interlaced stream path | 12/17 | not escalated | all stream behavior fails | caught |
| Ignore `StreamWriter::set_filter` | 16/17 | not escalated | only `stream_filter_override_applies_to_adam7_rows` fails | caught and isolated |
| Ignore the custom IDAT size | 16/17 | not escalated | only the chunk-ceiling case fails | caught and isolated |
| Accept a long slice or discard excess stream bytes | 16/17 each | not escalated | only the corresponding length case fails | caught and isolated |
| Force every requested filter to Up | 14/17 | not escalated | fixed, MinEntropy, and tiny no-filter cases fail | caught |
| Encode `NoCompression` with a compressed level | 16/17 | not escalated | only compression selection fails | caught and isolated |
| Apply Adam7 to non-interlaced files | 15/17 | not escalated | paired compatibility and MinEntropy oracle fail | caught |
| Bypass validation on a second static interlaced image | 16/17 | not escalated | only enabled sequence validation fails | caught and isolated |
| Map interlaced `MinEntropy` to `Adaptive` | predecessor 16/16; current 16/17 | predecessor passed 89 library tests (1 ignored), eight upstream integration tests, and eight doctests | new pass-local public-oracle test passes reference and fails mutant alone | admitted; actionable survivor closed |

`verify/mutations.sh` reproduces the current 16-mutant matrix. The material
predecessor survivor was run through the complete suite before the additional
probe was admitted.

## Rejected gap candidates

- Testing the full Cartesian product of dimensions, filters, compressions, and
  producer chunk splits repeats already challenged shared branches.
- Exact compressed bytes, ratios, fdeflate fallback selection, allocation
  counts, buffering, and pass container layout are explicitly not promised.
- APNG interlacing is excluded; requiring either rejection or acceptance would
  choose an unresolved upstream frame policy.
- Partial-row `flush`, empty `Write` calls, and validation-disabled repeated
  static writes are existing generic writer policy, not independent Adam7
  obligations.
- Exact values in unused pass-row padding bits are not semantic. The oracle
  masks them while proving that nonzero source padding never becomes pixels.

## Final coverage statement

Every atomic public requirement has a direct behavioral oracle on the exact
artifact version. The only demonstrated focused survivor crossed a named
`Filter::MinEntropy` branch and was closed with a repository-public oracle.
All 16 current repository-grounded mutations are caught, while two materially
different legitimate encoder architectures pass. This pass is evidence for
the attempted matrix, not proof that no false positive can exist. After the
formatting-only solution-patch regeneration, this mapping was reviewed against
the new full hash and the complete 16-mutant matrix was rerun; no requirement,
predicate, or result changed.
