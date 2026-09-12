# Design — image-png Adam7 encoding

## Status and identity

- Status: **terminal; promoted package later rejected for prior-work overlap**
- Repository: `image-rs/image-png`
- Pin: `721fd56651038c51bb3a6c2eabe9ab11b086db6e`
- Production language: Rust
- Task type: feature request
- Preliminary rating: **8/10 historical; ineligible after external rejection**
- The later problem package and its test/reference artifacts are archived.

## Mandatory trajectory-informed startup gate

Searched the full candidate/problem/archive history before design. The closest
records were the SGI writer, OpenEXR, tifffile NDTiff recovery, and binary
writer/round-trip candidates; no prior image-png Adam7 encoder task exists.
Read the compact h5py VDS, tifffile NDTiff, metadata-extractor `cmov`, and
Statig records. Inspected raw h5py, tifffile, and metadata-extractor solver
trajectories and evaluator outcomes.

The decisive trajectory evidence was boundary-specific: most h5py solvers got
the main relocation algorithm but missed same-file identity; near-passing
metadata-extractor solvers missed zero-length data or continuation after a bad
sibling. Therefore this design separates pass lifetime, tiny geometry, packed
samples, and streaming rather than multiplying normal-image fixtures.

## Repository evidence

`src/encoder.rs` rejects interlaced output because normal rows would make a
corrupt Adam7 stream. The crate already contains Adam7 geometry, decoder row
iteration, packed-sample expansion, filters, compression, and IDAT streaming.
PR #681 introduced rejection rather than encoding. Dated exact issue/PR/source
searches found no active implementation owner.

## Candidate public contract

When `Info::interlaced` is true for a static PNG, accept the same ordinary
raster buffer as non-interlaced encoding and emit a valid Adam7 PNG. Produce
the seven standard passes, omit empty passes, restart row-filter history for
each pass, support every currently encodable color type/bit depth, and retain
existing filter/compression/IDAT behavior. APNG is out of scope.

## Discriminator ledger

| Evidence | Plausible shortcut | Public invariant/oracle | Independent boundary |
|---|---|---|---|
| h5py solvers missed one identity mode | Interlace only common RGB8 images | existing decoder and an independent decoder reproduce exact raster | representation family |
| metadata trajectory missed empty output | Assume every pass has a row | 1×N, N×1, and tiny images omit empty passes without errors | empty/tiny geometry |
| Decoder explicitly resets at pass start | Carry previous filtered row across passes | first row of every nonempty pass is filtered against zeros | state lifetime |
| Packed decoder paths already exist | Slice bytes rather than samples | 1/2/4-bit grayscale and palette round-trip exact odd widths | packing boundary |
| Encoder already streams/chunks IDAT | Materialize or bypass configured pipeline | configured filter/compression/chunking remains observable | producer mode/resource boundary |

Anti-overfit rule: tests may inspect decoded pixels and a small independent
pass-byte oracle, but must not require a particular iterator, buffer layout, or
helper structure.

## Risks and next gate

The Adam7 schedule is standardized and the decoder supplies reusable concepts,
so architecture convergence is the main risk. Before selection, run the exact
environment gate and implement two disposable approaches if practical: a
pass-row iterator and a pass-buffer transform. Measure the cheapest complete
production shape before deciding whether depth survives.

## Later disposition

The candidate was promoted and fully verified locally. On 2026-08-15, external
review rejected the resulting problem because it had already been done. That
verdict is terminal and supersedes the preliminary shortlist rating. Preserve
this record to prevent reselection or paraphrasing of the same task.
