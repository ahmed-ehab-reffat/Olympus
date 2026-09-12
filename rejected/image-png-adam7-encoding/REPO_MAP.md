# REPO MAP - image-rs/image-png

Last verified: 2026-08-15 at
`721fd56651038c51bb3a6c2eabe9ab11b086db6e`.

## Build and test entry points

| Purpose | Command | Offline constraints |
|---|---|---|
| Compile all targets | `cargo test --no-run --all-targets --all-features` | dependencies must be cached during image build |
| Existing regression suite | `cargo test --all-features` | no service; committed fixtures only |
| Library and integration split | `cargo test --lib --all-features`; `cargo test --tests --all-features`; `cargo test --doc --all-features` | useful for JUnit wrapper classification |
| Format | `cargo fmt --all -- --check` | requires rustfmt in the image |
| Static checks | `cargo clippy --all-targets --all-features -- -D warnings` | requires clippy; not a substitute for behavior |

## Relevant subsystems

| Subsystem | Public entry point | Important source files | Existing tests | Why it matters |
|---|---|---|---|---|
| Static encoder configuration | `Encoder::with_info`, `Encoder::write_header` | `src/encoder.rs`, `src/common.rs` | encoder unit tests | owns interlace acceptance, IHDR, color/depth, filter, compression |
| Slice image producer | `Writer::write_image_data` | `src/encoder.rs`, `src/filter/*` | encoder round trips and compression cases | validates ordinary raster length and handles all compression branches |
| Streaming producer | `Writer::{stream,into_stream}_writer*`, `StreamWriter` | `src/encoder.rs` | streaming and APNG writer tests | arbitrary input segmentation, row assembly, chunk sizing, completion |
| Adam7 geometry | decoder-facing `Adam7Info`; private `Adam7Iterator` and `PassConstants` | `src/adam7.rs`, `src/decoder/interlace_info.rs` | extensive Adam7 unit tests and benchmark | established pass schedule, empty-pass omission, overflow handling |
| Packed samples | public color/depth configuration and decoder expansion | `src/common.rs`, `src/adam7.rs`, decoder transform modules | Adam7 bit expansion and palette tests | source and pass rows have independently padded packed samples |
| Row filtering | `Filter` option | `src/filter/mod.rs`, `src/filter/paeth.rs` | filter round trips | previous-row state must restart at every pass |
| Compression and PNG chunks | `DeflateCompression`, stream chunk-size constructors | `src/encoder.rs`, `src/chunk.rs` | encoder and streaming tests | one zlib stream, backend branches, IDAT chunk publication |
| Decode oracle | `Decoder`, `Reader`, `expand_interlaced_row` | `src/decoder/*`, `src/adam7.rs` | PNGSuite/corpus and bug fixtures | repository-owned exact raster oracle |

## Data and control flow

Current static slice path:

```text
Info / Encoder options
  -> Writer::init
     -> reject info.interlaced
     -> encode signature, IHDR, metadata
  -> Writer::write_image_data(row-major raster)
     -> exact ordinary raster-size check
     -> row filtering with one previous-row chain
     -> selected DEFLATE backend
     -> IDAT chunk publication
     -> image lifecycle accounting
```

Required static Adam7 path:

```text
ordinary row-major raster
  -> logical sample selection by pass geometry
  -> pass-local packed/byte-aligned rows
  -> filter chain reset for each nonempty pass
  -> one selected DEFLATE stream
  -> existing IDAT/chunk and lifecycle publication
```

The stream producer currently assembles ordinary rows before filtering them.
Adam7 output order differs from input order, so a correct stream solution may
gather pass data or the complete input before publication. The contract does
not require a private state shape or memory ceiling.

## Public oracles

- Decode the emitted file with the crate's public `Decoder` and compare the
  exact ordinary raster.
- Inspect IHDR and inflate concatenated IDAT bytes with an independent PNG
  scanline/pass parser.
- Use the standard Adam7 schedule and filter reversal to observe pass geometry,
  packing, and pass-local previous-row state.
- Exercise every public compression family without requiring compressed-byte
  equality.
- Observe stream completion and IDAT chunk length through the emitted file.
- Run the complete committed test suite for non-interlaced and APNG
  compatibility.

## Extension seams

| Seam | Evidence it is repository-native | Expected production files | Main risk |
|---|---|---|---|
| Static interlace acceptance | PR #681 and unreleased changelog explicitly identify the missing feature | `src/encoder.rs` | accepting APNG accidentally |
| Reverse/pass extraction | private decoder geometry and packed expansion already exist | `src/adam7.rs`, possibly `src/encoder.rs` | direct textbook implementation and architecture convergence |
| Shared filtering/compression | both producers already route through established filters and compressors | `src/encoder.rs`, perhaps a helper module | duplicating three branches or miscomputing fallback size |
| Streaming static input | public stream constructors and arbitrary `Write` boundaries | `src/encoder.rs` | whole-image buffering versus existing resource-oriented documentation |

## Hazards

- The hidden patch must not edit participant-owned `src/*.rs` files.
- Open PRs #707 and #708 touch encoder/filter or stream state at the current
  upstream head; APNG is excluded and additive test registration is preferred.
- PNGSuite files are third-party fixtures with their own included license; new
  focused fixtures should be generated in test code instead of copied from an
  external encoder.
- Compressed bytes vary by backend and library version. Tests must parse and
  decode behavior, not compare golden IDAT bytes.
- Rust overflow behavior differs by target width. Use small deterministic
  fixtures for functional tests and retain the repository's existing overflow
  suite.
