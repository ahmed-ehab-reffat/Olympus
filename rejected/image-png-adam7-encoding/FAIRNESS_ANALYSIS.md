# Exact-version fairness analysis - image-png static Adam7 encoding, L1

Verdict: **pass**.

Date: 2026-08-15  
Repository: `image-rs/image-png` at
`721fd56651038c51bb3a6c2eabe9ab11b086db6e`  
Artifact set: `meta bf10cb00`, `test cb5912a5`, `solution af00d4c4`,
`Dockerfile 52358a81`.

`FAIRNESS_ANALYSIS.md` at the workspace root was read before this audit. Every
logical rejection predicate and harness expectation below belongs to the full
hashes recorded in `ENVIRONMENT.md`.

## Rejection-predicate provenance

| Predicate | What it rejects | Public or repository provenance | Freedom preserved | Verdict |
|---|---|---|---|---|
| IHDR carries the requested dimensions, color/depth, and interlace method 1 | header-only or mislabeled output | public `Info` fields and PNG IHDR | chunk layout and implementation modules | fair |
| The public decoder reconstructs exact logical pixels | corrupt, incomplete, or misordered Adam7 output | explicit task plus crate decoder | row generation, buffering, iterator direction | fair |
| Inflated rows follow seven standard passes and exact active geometry | reordered, missing, or fabricated empty passes | prompt and PNG Adam7 semantics; pinned decoder constants | helper types and storage organization | fair |
| Each fixed filter advertises its selected type and reverses to the pass raster | ignored filter selection or wrong predecessor | public `Filter` variants and pass-independence clause | compression bytes and filter implementation style | fair |
| `MinEntropy` pass bytes equal the existing non-interlaced writer on the same pass raster | mapping the named strategy to another heuristic | prompt's preservation clause; `Filter::MinEntropy` public behavior and release note | no private entropy formula is reimplemented or named | fair |
| Packed logical samples match while unused output padding is masked | LSB-first extraction, row-padding-as-pixels, or wrong repacking | explicit packed-input clause and current row format | any values in semantically unused output bits | fair |
| Every valid color/depth combination decodes | one-family implementations | existing `ColorType::is_combination_invalid` surface and explicit prompt | production representation and helper sharing | fair |
| NoCompression uses filter 0 and a stored DEFLATE block | silently substituting compression | public `DeflateCompression::NoCompression` documentation | zlib header details beyond standard framing, stored block grouping | fair |
| Fdeflate and flate2 selections produce valid exact pixels | missing compression match arms | public compression enum | compressed identity, ratio, fallback, or level-specific bytes | fair |
| Borrowed/owned stream output honors arbitrary writes and custom IDAT ceiling | slice-only implementation, row-boundary assumption, or ignored size | explicit prompt and public stream constructors | full buffering and any number of chunks above the required minimum |
| Slice/stream inexact lengths fail and enabled sequence validation rejects a second image | accepted prefix/suffix or bypassed lifecycle state | explicit prompt; public `validate_sequence` and existing validation tests | exact error type text and failure timing before publication | fair |
| Non-interlaced encoding and the upstream suite pass | collateral regression | explicit compatibility clause | no interlaced APNG behavior is inferred | fair |
| Baseline/new modes start real test processes and emit JUnit testcase identities | verifier startup or missing-node false results | evaluator contract | no product deadline or performance condition | fair |

## Architecture replay

| Legitimate implementation | Distinct architecture | Exact result | Fairness conclusion |
|---|---|---:|---|
| reference `solution.patch` | materializes pass buffers in `adam7.rs`, then filters/compresses them | base pass; focused 17/17 | accepted |
| mandatory `verify/direct-row.patch` replay | extracts and repacks rows on demand inside the encoder; one production file | base pass; focused 17/17 | accepted; tests do not prescribe pass containers, module ownership, or helper names |

The environment gate applies `test.patch` only after each implementation. It
proved conflict-free injection, matching baseline/reference JUnit identities,
offline execution, and both modes for the two architectures.

## Unspecified-constraint audit

- Private implementation structure: no test imports private encoder/Adam7
  symbols, inspects allocations, or names a candidate-added API.
- Encoding and malformed bytes: standard IHDR, zlib, filter, and Adam7 bytes are
  inspected; no arbitrary malformed PNG is supplied. Invalid caller input is
  limited to publicly wrong raster lengths and a second image with validation
  enabled.
- Ordering, batching, and exact counts: only standard pass order and the public
  chunk-size ceiling are required. IDAT count and compressed bytes are otherwise
  free.
- Timing and scheduling: there are no sleeps, timeouts, races, or performance
  thresholds.
- Feature/build surfaces: the stable default feature set is used. The
  nightly-only `unstable` feature and interlaced APNG are not exercised.
- Harness environment: dependencies are cached at image build; runtime uses
  `--offline`, no network, UID/GID 10001, a read-only mounted source, writable
  temporary build/output directories, and Python 3 from the approved image.
- Error strings: no error wording or exact variant is asserted.

## Corrections and rejected complaints

- The first reference honored only the encoder's pre-stream filter and ignored
  `StreamWriter::set_filter`. The reference and test were corrected; both
  legitimate architectures now pass the public override case.
- The first independent packed-row comparison implicitly required zero unused
  output bits. It now masks unused bits and separately uses nonzero source
  padding to prove those bits are not pixels.
- A round-trip-only MinEntropy case admitted an Adaptive substitution. The
  replacement oracle delegates semantics to the crate's existing public
  non-interlaced writer for each pass, avoiding a private entropy formula.
- Requiring a specific fdeflate fallback, compressed byte stream, APNG result,
  or memory ceiling was rejected as an implementation constraint.
- The `NoCompression` stored-block assertion is not exact-byte pinning: stored
  DEFLATE is the observable meaning documented by that public variant.
- The IDAT test's `more than one` assertion follows mathematically from a
  no-compression raster larger than the announced 17-byte ceiling; it is not an
  arbitrary chunk-count preference.

## Final fairness statement

Every remaining rejection follows from the participant-facing contract,
standard PNG/DEFLATE framing, or a concrete public behavior of the pinned
crate. Tests observe only produced bytes, public decode results, and public
errors. They permit both measured architectures and impose no private layout,
buffering, timing, allocation, APNG, or compressed-identity choice. Exact-version
fairness verdict: **pass**. The formatting-only solution-patch regeneration was
followed by a predicate-by-predicate review and both architecture replays under
the exact environment gate; no assertion or implementation constraint changed.
