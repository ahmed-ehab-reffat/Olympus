# Prototype record - image-png static Adam7 encoding

Repository pin: `721fd56651038c51bb3a6c2eabe9ab11b086db6e`.

Verdict: `proceed-to-problem-artifacts`.

## Shared behavior

Two disposable implementations accept an ordinary row-major static raster when
`Info::interlaced` is true, emit the seven nonempty Adam7 passes, restart row
filter history for each pass, support packed and byte-aligned formats, preserve
all three compression branches, and serve both the slice and stream producers.
Interlaced APNG remains rejected. Each prototype uses the crate's decoder for
round-trip checks but implements the encoder-side transformation independently.

The shared verification matrix includes every accepted static color/depth
family, odd-width 1/2/4-bit packed rows, geometries with different active-pass
sets, no-compression, fdeflate, flate2 compression, arbitrary stream write
boundaries, and the configured IDAT chunk ceiling.

## Independent implementations

| Prototype | Architecture | Production files | Raw additions/deletions | Strict-effective additions/deletions | Production diff SHA-256 |
|---|---|---:|---:|---:|---|
| direct rows | Extract and repack each pass row from the caller's ordinary raster immediately before filtering/compression. | 1 | 259/69 | 231/50 | `f713ae6f33eac2a3ee70201f0118c87508c5d35f5801778a1c0ce97f52581b9a` |
| pass buffers | Build pass-row buffers in `adam7.rs`, then feed those rows to the established filtering/compression paths. | 2 | 247/69 | 220/50 | `93c9ca2e900c546439942b3e7247595bf61364a0e3776f321316132a35ef0b98` |

The strict-effective counter examines zero-context `src/` diff lines and
excludes blank and comment/doc-comment-only lines. Co-located updates to the
obsolete rejection regression remain counted because they are in a production
path; no disposable integration-test lines are counted.

## Verification

Both focused suites passed completely. Both prototypes then passed the complete
upstream default suite at the exact pin: 89 library tests with one ignored,
eight committed integration tests, eight doctests, plus their disposable
integration probes. `cargo fmt --all -- --check` passed for both.

The all-target Clippy lane is not a clean differential gate under the image's
Rust 1.93.1: the pristine code already reports warnings in untouched decoder,
filter, and test code. Neither prototype changes those findings.

## Scope conclusion

The implementations differ at the main architecture boundary: one keeps only a
source raster and constructs rows on demand, while the other materializes
complete pass buffers in the existing Adam7 module. Their cheapest complete
measurements are 231 and 220 strict-effective additions. Both exercise a real
two-producer lifecycle and independent packing, pass-state, compression, and
publication branches.

This clears the current 200-line preliminary signal without adding APNG,
performance limits, malformed-input policy, or private-structure requirements.
The candidate is therefore promoted to authored problem artifacts. These
reference estimates do not predict the eventual median solver work; calibration
must use an immutable artifact version and legitimate successful runs.
