# DESIGN.md — mp4ff-progressive-writer

Repo: github.com/Eyevinn/mp4ff (Go, MIT, 648 stars, 45k source LOC, zero runtime deps)
BASE_COMMIT: b7b7b79f6f8378dc48eb3769396335f39811906e

## 1. Title

Build progressive MP4 files from fragmented input

## 2. Shape classification

- Shape: O-Composite-add (new capability spanning sample-table construction, chunk layout, box assembly)
- Pass rate target: <=40% cap, designed for the hard edge (~10-20%)
- Best agent: Orion (long-horizon)
- Dominant verdict: MISSED_REQUIREMENT / INTEGRATION_ERROR

## 3. Public API surface

In package `mp4`:

- `type ProgressiveConfig struct { ChunkDurationMS uint32; LargeOffsets bool }`
- `func (f *File) ToProgressive(cfg ProgressiveConfig) (*File, error)` — returns a new non-fragmented `File`
  whose `Children` are `ftyp`, `moov`, `mdat` in that order.

Errors are asserted as errors only, never by message substring: flattening a file that is not
fragmented must fail.

## 4. Canonical output form

- Child order: ftyp, moov, mdat. Exactly one mdat.
- Per-track sample order: segment order, then fragment order, then trun order, then sample order.
- Chunking: a chunk never spans a source fragment. With `ChunkDurationMS == 0` there is one chunk per
  (track, fragment) that carries samples. Otherwise a chunk is closed before the sample that would push
  its accumulated duration past `ChunkDurationMS` (converted to the track's media timescale); every
  chunk holds at least one sample.
- mdat order: chunks ascending by the decode time of their first sample **compared in movie timescale**;
  ties by ascending track ID. Sample data is contiguous in that order.
- Chunk offsets are absolute file offsets of the chunk's first sample byte.
- `stco` unless `LargeOffsets`, then `co64` and a 64-bit-largesize mdat header.
- `stts`/`ctts` run-length compressed to the minimal number of entries.
- `ctts` present only if some composition offset is non-zero; version 1 iff some offset is negative.
- `stss` present only if not every sample is a sync sample; 1-based sample numbers.
- `sdtp` present only if some sample carries non-zero dependency flags.
- `stsz` uses the uniform size when all sample sizes are equal.
- `mdhd.Duration` = sum of sample durations. `tkhd.Duration` and `mvhd.Duration` = track/max duration
  converted to movie timescale.
- Edit list: a track whose first sample has decode time t0 > 0 gets `elst` = empty edit
  (`SegmentDuration` = t0 in movie timescale, `MediaTime` -1) followed by a full-media edit
  (`MediaTime` 0). Otherwise no `elst` is produced.
- Empty tracks are kept with empty tables and zero duration.
- `mvex` is removed from the output moov.

## 5. Blind-spot pre-empts

- Result ordering: "compared in movie timescale, ties by ascending track ID" (sort-order bank entry).
- Iteration/edge: "every chunk holds at least one sample" (boundary bank entry).
- Falsy-on-empty: "empty tracks are kept with empty tables" (empty-input bank entry).
- Codebase-inferable (1 max): the derived `FirstSampleNr` bookkeeping inside the repo's own `StscBox`,
  exercised through `ChunkNrFromSampleNr`. Every other table is asserted through public accessors, so no
  internal representation is pinned.

## 6. Description draft

See meta.md (<=200 words, plain prose).

## 7. File footprint

| Action | Path | Raw delta | Reason |
| --- | --- | --- | --- |
| NEW | mp4/progressive.go | 417 | flatten engine: sample collection, chunking, layout, tables |
| NEW | mp4/progressive_tables.go | 231 | table builders (stts/stsz/stsc/stco/co64/stss/ctts/sdtp) |
| MODIFY | mp4/sdtp.go | 1 | fix `NewSdtpEntry`, which drops its `sampleDependsOn` argument |

Measured: 834 raw / 556 human-effective (Counter 2) across 3 files.

## 8. Solution outline (pure helpers, 1+ per described behavior)

- `collectTrackSamples(f *File) (map[uint32]*trackSamples, error)` — resolve trun/tfhd/trex defaults.
- `buildChunks(ts *trackSamples, cfg ProgressiveConfig) []chunk` — fragment-bounded greedy chunking.
- `orderChunks(tracks) []chunkRef` — movie-timescale ordering, trackID tie-break.
- `layoutChunks(order, headerSize) (offsets, mdatData)` — absolute offsets.
- `buildStts/buildStsz/buildStsc/buildStco/buildCo64/buildStss/buildCtts/buildSdtp` — one per table.
- `buildEditList(t0, mediaDur, movieTimescale, mediaTimescale) *EdtsBox`
- `setDurations(moov, tracks)`

## 9. Test file outline

Path: `mp4/progressive_<hash>_test.go` (random hex suffix, no banned markers)
Blocks: imports -> fragmented-file builders (in-memory, no binary fixtures) -> assertion helpers
-> granular tests grouped by: sample fidelity round-trip, chunking, ordering/interleaving, each table,
edit lists, durations, config knobs, error cases, edge cases (empty track, single sample, all-sync,
negative composition offsets, uniform vs varying sizes).

## 10. Forced signatures

`ToProgressive` returns `(*File, error)`; `ProgressiveConfig` is a value struct. Both pinned in meta.md
so a statically-typed test compiles against the intended shape (fake-difficulty anti-pattern avoided).

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Stated contract | Catching test |
| --- | --- | --- | --- | --- |
| 1 | Chunk offsets measured from mdat data start instead of file start (off by the 8/16 byte mdat header) | The natural code accumulates within mdat | "absolute file offsets" | sample-data round-trip via re-decode |
| 2 | Interleave order compared in raw media timescale | Tracks share a timeline only after conversion | "compared in movie timescale" | two tracks, different timescales |
| 3 | stsc run compression / FirstSampleNr bookkeeping | The repo's StscBox keeps a derived FirstSampleNr | canonical minimal runs | chunk-size-varying fixture |
| 4 | ctts version/representation (cumulative EndSampleNr, signed v1) | Internal form differs from the spec's counts | "version 1 iff some offset is negative" | negative-offset fixture |
| 5 | Offsets vs LargeOffsets header growth | co64 + largesize changes both moov and mdat sizes | "64-bit largesize mdat header" | LargeOffsets round-trip |

Traps 1/2/5 are interdependent: fixing the header size shifts every offset, and the ordering decides
which sample each offset must point at.

## 12. Tier + category

Olympus, feature-request.

## 13. Predicted pass rate

15-30%. The contract is fully statable while the layout fixpoint (header size -> offsets -> table sizes)
and the cross-timescale ordering stay discovery work.

## 14. Quality gate

- [x] Repo understanding (5/5)
- [x] Exclusivity: no PR for progressive writing; maintainer states in issue #427 "it has little support
      for writing progressive files"; sample-table boxes cold since 2025-01
- [x] Env quality: vanilla `go test ./...` green offline, deterministic 3x
- [x] Signatures pinned in meta
- [x] LOC: 439 human-effective / 649 raw across 3 files (clears the 400 auto-block with margin)
- [x] F2P: all 125 new tests fail on base (build-failure synthesis emits 125 named failure nodes)
- [x] No regressions: 1201 base test cases pass in every state
- [x] Flakiness: base and new both deterministic across 3 runs, offline, non-root

## Why this is not a duplicate

Closest local work is media/container parsing (allsorts COLRv1 apply-half, docx-rs field instructions).
No submission in `Aprroved/`, `problems/`, or `rejected/` touches ISOBMFF sample-table construction or
mp4ff. Repo is fresh to the corpus (0 prior submissions).

Predicted iteration cycles: 2
