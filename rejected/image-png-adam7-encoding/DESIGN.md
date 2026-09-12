# DESIGN - image-png static Adam7 encoding

Status: `terminal external prior-work rejection; locally verified artifacts
retained for history; calibration closed at 0/10`.

Repository: `image-rs/image-png` at
`721fd56651038c51bb3a6c2eabe9ab11b086db6e`.

Production language: Rust.

Task type: feature request.

## Public contract and repository evidence

The selected task makes the existing static PNG encoder accept
`Info::interlaced = true` and emit Adam7 image data from the same ordinary,
row-major raster buffer accepted by non-interlaced encoding.

The intended contract is:

- write the seven standard Adam7 passes in order and omit passes with no rows
  or samples;
- treat every nonempty pass as an independent image for row filtering;
- support every color-type and bit-depth combination the pinned encoder
  already accepts, including packed grayscale and indexed samples;
- retain the selected filter and DEFLATE backend and the existing IDAT chunk
  publication path;
- accept the static-image data through `Writer::write_image_data` and the
  `StreamWriter` entry points, with arbitrary input write boundaries and the
  same exact-length and opt-in sequence validation; and
- keep non-interlaced behavior compatible.

Animated PNG is excluded. The pinned crate has active, unresolved APNG encoder
work and does not establish whether Adam7 should apply to the default image,
individual frame rectangles, or both. A conforming solution may continue to
reject interlaced animated configurations.

Repository evidence at the pin makes each selected clause discoverable:

| Surface | Pinned behavior | Contract consequence |
|---|---|---|
| `Info::interlaced` and `Writer::init` | The public flag is serialized to IHDR, but PR #681 added `InterlacedEncodingUnsupported` because ordinary rows would make corrupt IDAT data. | Static interlacing is a documented missing encoder capability, not a new option invented for the problem. |
| `adam7.rs` | `PassConstants` and `Adam7Iterator` implement the seven pass offsets, strides, empty-pass omission, and overflow-aware geometry for decoding. | Encoder geometry can reuse repository concepts without prescribing a reverse iterator or buffer layout. |
| `Writer::write_image_data` | Validates an ordinary row-major raster, then filters and compresses rows through three DEFLATE modes and publishes IDAT chunks. | The input representation, validation behavior, filter selection, compression settings, and publication path are established. |
| `StreamWriter` | Accepts arbitrarily split ordinary image bytes, assembles rows, filters them, and writes through `ChunkWriter`. | A second public producer mode must remain functional; buffering strategy and memory layout are not prescribed. |
| `ColorType` / `BitDepth` helpers | `raw_row_length_from_width` and prediction-byte calculation support packed and byte-aligned encodable combinations. | Pass extraction must operate on logical samples, not assume one source byte per pixel. |
| Decoder and `expand_interlaced_row` | The crate decodes Adam7 data and publishes pass metadata; its committed corpus includes interlaced PNGs. | Exact raster reconstruction and pass behavior have repository-owned black-box oracles. |

No resource ceiling, allocation count, helper type, iterator direction, pass
buffer organization, or compressed byte identity is required. An
implementation may gather the complete static raster before producing pass
data, including for the stream API. Tests may observe correct output and the
configured chunk-size ceiling, not private buffering or timing.

## Trajectory-informed design gate

`PROBLEM_DESIGN.md` was read again before promotion. Searches covered
`problems/README.md`, `candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`,
candidate/problem/archive records by `image-png`, PNG, Adam7, interlacing,
packed samples, binary image writers, pass-local state, and streaming. No prior
image-png or Adam7 encoder problem or solver trajectory exists.

The closest compact records reviewed were h5py VDS reconstruction/relocation,
tifffile NDTiff recovery, metadata-extractor compressed-movie parsing,
TwelveMonkeys SGI writing, OpenEXR multipart I/O, and Statig local transitions.
The SGI task is terminal because of external similarity and supplies no solver
runs. H5py and tifffile show that normal cases do not substitute for identity,
tiny geometry, or independently represented branches. The most useful raw
evidence is metadata-extractor because successful implementations crossed
binary framing, nested traversal, state reset, and later-sibling continuation
through several valid architectures.

Raw `trajectory.json`, `eval-result.json`, `run.txt`, and solution patches were
inspected directly from
`problems/metadata-extractor-cmov/agent-runs4.zip` and
`problems/metadata-extractor-cmov/agent-runs1.zip`.

| Evidence role | Problem / raw run | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | metadata-extractor `agent-runs4/Nova_Nova_3` | Baseline and focused lanes passed; the current Level 6 replay also passes. | Added a bounded compressed-resource decoder, parsed child framing before inflation, replayed decoded bytes through both existing movie readers, and repaired parent-bound cleanup and handler transitions. Seven production files, +354/-48 raw production lines. The final report called out exact size/trailing checks, repeated handler state, and later-sibling recovery. |
| Near-pass | metadata-extractor `agent-runs4/Nova_Nova_1` | Baseline passed; focused lane failed, and the current replay misses only valid zero-length decoded output. | Used a shared buffering/inflation helper and both existing readers, with extended headers, state alternation, and recovery, but one numeric boundary remained wrong. Seven production files, +276/-37 raw production lines. |
| Broad failure | metadata-extractor `agent-runs1/Nova_Nova_2` | Passed its older lane; current replay misses overlong method framing, zero output, an extended later sibling, and nested parent containment. | Buffered the complete resource and delegated decoded content to both readers, but accepted a prefix instead of an exact method payload and did not carry every outer-bound/lifecycle rule through recursion. Six production files, +236/-25 raw production lines. |

Strict effective LOC is unavailable for these archived patches, so raw counts
are scope evidence only. Their shared buffered architecture remains legitimate;
the design lesson is that one correct main transformation does not establish
small/empty geometry, exact packing, state restart, or every public producer
path.

## Selection comparison

The active shortlist was compared before promotion. Jsoncons was already
selected separately because it had a measured environment and full prototype.
Among the remaining candidates, image-png stays ahead of go-pmtiles,
segmentio/encoding, AudioFile, and excelize because the exact encoder gap,
independent decoder oracle, packed representation families, filtering state,
three compression modes, and two public producer modes are concrete at the
pin. The main risk is convergence on the standardized pass algorithm, which
must be measured by two disposable complete approaches before submission
artifacts are approved.

## Discriminator ledger

Each row is a distinct public failure family or implementation boundary.

| Observed evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| The broad framing run implemented the main transform but missed independent representation branches. | Implement only RGB/RGBA 8-bit pixels. | Every color/depth combination already accepted for non-interlaced static images is accepted for Adam7. | Encode patterned representatives and recover the exact raster with the public decoder and an independent decoder. | Representation family | Tests group equivalent byte-aligned formats while separately challenging packed samples; no helper layout is required. |
| The near run missed the valid zero boundary after handling ordinary payloads. | Assume all seven passes and all pass rows are nonempty. | Empty Adam7 passes are omitted and tiny nonzero images remain valid. | Round-trip narrow and short images whose active-pass sets differ. | Empty/tiny geometry | Dimensions are chosen by pass geometry, not as repeated random fixtures. |
| Existing decoder state is pass-aware, and the PNG standard treats each pass independently. | Carry the prior filtered row from one pass into the next. | The first row of every nonempty pass is filtered with no prior row from another pass. | Inflate IDAT, parse pass rows, and independently reverse the advertised filters. | State lifetime | Any filter choice and any internal storage pass if the emitted scanlines obey public PNG semantics. |
| Packed decoder paths extract logical 1-, 2-, and 4-bit samples. | Slice source bytes at pass coordinates or preserve source-row padding inside pass rows. | Pass rows contain the selected logical samples repacked from the high bit, with only final-byte padding. | Use odd-width patterned grayscale/indexed rasters and compare decoded samples plus independent pass bytes. | Bit packing and row padding | The oracle observes samples and format bytes, not a private bit iterator. |
| `write_image_data` has three distinct compression branches and an fdeflate stored fallback. | Implement Adam7 only in one DEFLATE branch or calculate fallback size from non-interlaced rows. | Every existing compression selection emits one valid zlib stream containing the same Adam7 scanlines. | Exercise no-compression, fdeflate, and a flate2 level; decode and inspect scanline accounting. | Compression backend | Compressed byte equality and ratio are not required. |
| Public `StreamWriter` accepts arbitrary write boundaries, unlike the slice producer. | Fix only `write_image_data`, or assume stream writes end on source rows. | Stream entry points accept the same ordinary raster under arbitrary chunking and preserve their configured IDAT chunk ceiling. | Feed identical pixels whole, bytewise, and across row boundaries; decode exact output and inspect chunk lengths. | Producer mode and publication | Full buffering, pass spooling, and other architectures remain valid; no allocation ceiling is asserted. |
| Active APNG PR #708 repairs a different frame-state machine. | Apply static pass logic indiscriminately to APNG frames or regress non-interlaced animation. | Static Adam7 succeeds; non-interlaced PNG/APNG behavior remains compatible; interlaced APNG is not required. | Run the complete upstream suite and one static-versus-animation scope check. | Feature boundary / compatibility | Excluding APNG avoids adopting unresolved upstream frame policy. |
| Existing producers enforce exact ordinary raster length and expose opt-in sequence validation. | Validate against total pass bytes, accept a prefix/suffix after reordering, or bypass the one-static-image rule on the new path. | The caller still supplies one ordinary full raster per image, and enabled sequence validation rejects a second static image. | One-byte short and long inputs fail through slice and stream completion paths; an enabled validator accepts the first complete image and rejects a second. | Input contract and lifecycle | Error wording and internal failure timing are not prescribed. |

## Clause-to-test coverage

This is a design map, not an authored hidden suite.

| Public requirement | Planned observable test | Pristine behavior | Required behavior | Fairness evidence |
|---|---|---|---|---|
| Static `Info::interlaced` is accepted | Encode a patterned static image and inspect IHDR/decode | header creation rejects | valid interlaced PNG and exact raster | public flag, PR #681, existing decoder |
| Standard pass order and geometry | Independent scanline parser over a nontrivial and a tiny raster | no file emitted | expected nonempty passes and row lengths | `PassConstants`, PNG specification |
| Pass-local filtering | Use a fixed vertical predictor and inspect each pass start | no file emitted | independent filter reversal reproduces pass samples | filter API and standard pass independence |
| Packed samples | Odd-width 1/2/4-bit grayscale and indexed patterns | header creation rejects | exact logical sample round trips | existing encoder combinations and decoder expansion |
| Byte-aligned formats | Grouped 8-/16-bit grayscale, color, and alpha representatives | header creation rejects | exact raw output after decode | existing encode/decode matrix |
| Compression settings | Representative from each existing backend | header creation rejects | all decode to identical pixels | public compression API |
| Slice and stream producers | Whole slice plus arbitrarily segmented stream writes | header creation rejects | both produce valid equivalent rasters | public `Writer` and `StreamWriter` surfaces |
| Configured IDAT chunk ceiling | Small stream chunk size | header creation rejects | data chunks respect configured size and decode | `stream_writer_with_size` documentation |
| Exact ordinary input length and sequence validation | Short/long slice, unfinished/overlong stream, and enabled static sequence validation | header creation rejects | deterministic length failure; first static image accepted and second rejected when validation is enabled | existing parameter/lifecycle semantics |
| Compatibility and APNG exclusion | Complete suite and explicit configuration scope | existing suite passes | suite passes; interlaced animation need not succeed | pinned behavior and active APNG ownership |

## Environment and harness preflight

- Docker 29.2.1 is available, and the final preflight had 64,616,464 KiB free.
- The untouched checkout is clean at the exact default-branch head.
- Cargo declares Rust 1.73 as the MSRV. This library intentionally does not
  commit `Cargo.lock`; the approved image resolves and caches dependencies at
  build time and proves offline resolution without an author-only lock.
- The repository is pure Rust for production and tests; no service or
  unsupported runtime is required.
- A no-cache official-base image passed the complete default suite offline as
  UID/GID 10001: 105 passed and 1 ignored. The root-owned source remains
  untouched; a disposable writable worktree is required because one committed
  doctest creates `target/text_chunk.png`.

`ENVIRONMENT.md` records the image, tools, exact command shape, quarantined
attempts, and invalidation rules. Phase B remains impossible until the prompt,
tests, and reference exist.

## Cheapest complete implementation evidence

Two complete disposable architectures passed their focused matrices and the
full upstream default suite:

| Architecture | Production files | Raw additions/deletions | Strict-effective additions/deletions | Distinct design |
|---|---:|---:|---:|---|
| direct pass rows | 1 | 259/69 | 231/50 | Extract and repack each pass row directly from the ordinary raster immediately before filtering and compression. |
| materialized pass buffers | 2 | 247/69 | 220/50 | Transform the ordinary raster into pass-row buffers in `adam7.rs`, then feed the established pipeline. |

The strict-effective count excludes blank and comment/doc-comment-only added
lines from zero-context production diffs. Both implementations cover packed
samples, byte-aligned color/depth families, tiny active-pass geometries, all
three compression branches, stream writes split at arbitrary boundaries, and
the IDAT chunk ceiling. `PROTOTYPE.md` records exact hashes and verification.

The architectures do not converge materially below the current 200-line
preliminary signal. Their differences also confirm genuine design freedom at
the row-generation boundary. No APNG, performance, malformed-input, or private
layout requirement was added to obtain this result.

## Design verdict

**Approved for prompt, hidden-test, and reference-patch authoring.**

The trajectory, pristine environment, ownership, and two-architecture scope
gates pass, and the exact feature remains unimplemented upstream. The public
contract is frozen above. APNG, performance limits, compressed byte identity,
private iterator structure, and arbitrary malformed PNG data remain excluded.
Exact Phase A/B, gap, fairness, and false-positive verdicts must be rerun after
the submission artifacts are frozen.

## Exact L1 verification and audit result

The frozen L1 artifact hashes are recorded in `ENVIRONMENT.md`. Exact Phase A
and Phase B pass offline as UID/GID 10001. The pristine tree passes all 105
upstream tests with one ignored and fails all 17 focused JUnit cases. The
pass-buffer reference and mandatory direct-row replay both pass the same base
lane and all 17 focused cases.

Gap and fairness analyses pass. The final false-positive matrix compiles 16
plausible one-defect implementations and catches all of them. A predecessor
MinEntropy-to-Adaptive substitution survived 16/16 plus the complete suite;
the admitted public-oracle probe compares each pass with the pinned writer's
non-interlaced MinEntropy behavior and kills only that mutation. Earlier audit
corrections also preserve `StreamWriter::set_filter`, mask semantically unused
packed output bits, challenge nonzero source padding, and retain opt-in static
sequence validation.

Local evidence establishes solvability and test integrity. It does not replace
the required median of legitimate successful solver patches; immutable
calibration remains 0/10.

## External disposition

On 2026-08-15, the operator reported that external review rejected this problem
because it had been done before. No comparison identifier accompanied that
handoff, so this record does not infer one. The external prior-work verdict
supersedes the earlier local ownership result. The task is terminal: preserve
the package as historical evidence, but do not submit, calibrate, paraphrase,
or expand it to seek a different outcome.
