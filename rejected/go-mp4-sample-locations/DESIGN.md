# Design - complete local sample metadata in `Probe`

Status: **rejected for cross-repository submission overlap on 2026-07-23.**
The design and implementation gates passed locally, but the later archive
finding invalidates the uniqueness gate and forbids submission or calibration.

## 1. Decision summary

Extend the existing probe model rather than add another parser. `Sample` gains
`Offset uint64`, `DecodeTime uint64`, `PresentationTime int64`, and
`IsSync bool`; `Segment` gains `Samples Samples`. `Probe` will populate these
fields for classic and fragmented local media while keeping the current sample
fields, segment summaries, bitrate helpers, CLI report, and `FindIDRFrames`
behavior.

The top-level scan will retain metadata box locations and every local `mdat`
payload interval without reading media bytes. Classic table reconciliation and
fragment run expansion will produce samples in source decode order. A final
range pass will reject any non-empty sample outside local media data before the
result is returned.

## 2. Hard-rule ledger

| Rule | Design decision | Public oracle |
|---|---|---|
| One result model | Add the named fields to `Sample` and `Segment`; do not add an iterator or extraction API. | Both `Track.Samples` and `Segment.Samples` use the same public type. |
| Absolute local location | `Offset` is the first byte of the sample payload in the supplied stream. | Seeking to each returned range reaches the generated or fixture payload. |
| Media time | Decode time starts at zero for classic tracks and at `tfdt` or per-track continuation for fragments. PTS is the checked signed sum of DTS and CTO. Edit lists are not applied. | Exact DTS, PTS, and duration values, including negative PTS. |
| Classic count authority | `stsz.SampleCount` establishes the sample count. `stts`, optional `ctts`, chunk coverage, and per-entry sizes must reconcile exactly. | Count mismatches return `(nil, error)`; no table is silently truncated. |
| Classic chunk protocol | Require a first `stsc` entry at chunk 1, strictly increasing valid first-chunk values, and exact sample coverage. Accumulate size within each chunk. | Varying samples-per-chunk and interleaving produce exact offsets; bad maps fail. |
| Classic sync protocol | No `stss` means every sample is sync. Otherwise entries are unique, one-based, and in range. | The fixture and generated absent/present `stss` cases distinguish both rules. |
| Fragment ownership | Enumerate `traf` parents under each `moof`; parse direct `tfhd`, optional direct `tfdt`, and all direct `trun` children for that owner only. | One `Segment` per `traf`, ordered by `moof`, `traf`, `trun`, then entry. |
| Fragment defaults | Resolve duration, size, and flags from entry, then `tfhd`, then matching `trex`. First-sample flags affect only entry zero of that run. | A mixed-default fixture checks every level and flags precedence. |
| Fragment bytes | Resolve the traf base from explicit base, default-base-is-moof, or the preceding traf data end. Signed run offsets are relative to the base; an omitted run offset continues the previous run. | Multi-traf/multi-run samples have exact independent and continued offsets. |
| Fragment time | `tfdt` wins. Without it, use the prior decode end for the same track, or zero if no prior segment exists. | Interleaved tracks continue independently across later fragments. |
| Local media proof | Collect all top-level `mdat` payload half-open intervals. Every non-empty sample range must fit wholly in one interval. | Leading/multiple media boxes work; gaps, headers, and EOF escapes fail. |
| Payload opacity | Only box headers and selected metadata payloads are read. `mdat` is recorded from `BoxInfo` and skipped by seeking. | A guarded `io.ReadSeeker` fails reads in media payload yet `Probe` succeeds. |
| Atomic refusal | All arithmetic and structural validation completes before a non-nil result is exposed. | A contradiction late in the file returns nil information. |
| Compatibility | Existing exported fields and aggregate meanings are retained. | The full upstream suite, command golden output, bitrate helpers, and IDR scan pass unchanged. |

Out of scope are edit-list application, `stz2`, external data references,
sample groups and dependency tables, encrypted auxiliary locations, payload
inspection or decoding, relocation, repair, and samples from a separately
supplied initialization segment.

## 3. Refreshed upstream and local audit

The audit was refreshed on 2026-07-23. `git ls-remote` reports both `master`
and tag `v1.7.1` at
`7f0bb4060772e78fb52d48b73a38b8c3928e83f0`. GitHub reports 543 stars, 36
forks, five open issues, no open pull requests, 28 releases, latest release
`v1.7.1` on 2026-06-16, and Discussions disabled.

Issue searches across open and closed results used `sample location`, `sample
offset`, `sample iterator`, decode/presentation time, sync sample, `tfhd`,
`tfdt`, `trex`, `trun`, and fragmented sample terms. Pull-request searches used
probe, sample, offset, and fragment terms. The only close results remain:

- issue #120 asks about arbitrary parsing and locating chunks. The maintainer
  points to `ReadBoxStructure`, `ExtractBoxWithPayload`, `stco`, and the old
  `FindIDRFrames`; the thread contains usage guidance, not an implementation or
  rejection of a high-level result;
- issue #26 and PR #43 concern only the existing aggregate composition offset;
- PR #87 introduced `Probe`, and PRs #135/#136 added `co64` probing without
  per-sample locations;
- issue #127 is fragmented WebVTT parsing guidance, while issue #165 explains
  relocation of `stco` after editing.

There are no open PRs. Repository code and all local history contain none of
the proposed fields or an equivalent sample result. Web searches for the field
names and feature concepts found no equivalent fork. The default branch and
release are unchanged since preflight, so no stop condition is met.

Primary records:

- https://github.com/abema/go-mp4/issues/120
- https://github.com/abema/go-mp4/issues/26
- https://github.com/abema/go-mp4/issues/127
- https://github.com/abema/go-mp4/issues/165
- https://github.com/abema/go-mp4/pull/43
- https://github.com/abema/go-mp4/pull/87
- https://github.com/abema/go-mp4/pull/135
- https://github.com/abema/go-mp4/pull/136
- https://github.com/abema/go-mp4/releases/tag/v1.7.1

Uniqueness verdict: proceed.

## 4. Repository seam and public contract

`Probe` already performs a selective top-level traversal. `ExtractBoxes` skips
unexpanded payloads by seeking, so adding `mdat` interval collection does not
read sample data. `probeTrak` already owns classic table expansion, while
`probeMoof` owns current fragment summaries. The implementation stays in
`probe.go` and keeps that call graph.

The public additions are exactly:

```go
type Sample struct {
    Size                  uint32
    TimeDelta             uint32
    CompositionTimeOffset int64
    Offset                uint64
    DecodeTime            uint64
    PresentationTime      int64
    IsSync                bool
}

type Segment struct {
    // existing fields unchanged
    Samples Samples
}
```

Classic samples and fragment samples are both in decode/source order. Times
are integers in the owning media track timescale. An empty track or zero-sample
traf has an empty slice and remains successful when its required metadata is
otherwise consistent.

## 5. Classic table state machine

The track extractor adds `stss` and rejects duplicate required sample tables,
simultaneous `stco` and `co64`, and missing required tables. It then follows one
bounded sequence:

```text
stsz count
   -> allocate exactly count samples and resolve every size
   -> expand stts exactly count entries while accumulating checked DTS
   -> expand optional ctts exactly count entries and compute checked PTS
   -> validate optional stss and set sync membership
   -> validate/expand stsc across every declared chunk
   -> walk chunks in order, assigning offset and adding each sample size
   -> require chunk coverage == count
```

`stsz.SampleSize != 0` supplies every size and requires no `EntrySize` values;
otherwise the unmarshalled entry list must match the declared count. `stts` and
present `ctts` run counts are summed with checked arithmetic and must equal the
same count.

For chunks, the first `stsc.FirstChunk` is one; subsequent values are strictly
increasing and no value is beyond the chunk count. Each covered chunk receives
one positive `SamplesPerChunk`. The ordered location pass starts at the
corresponding `stco`/`co64` offset and advances by each resolved size. It
refuses coverage beyond the sample count or leftover samples after the final
chunk. An empty track requires zero chunks and an empty `stsc` map.

## 6. Fragment default and base state machine

Before processing fragments, direct `moov/mvex/trex` boxes form a track-ID
default map. For each `moof`, direct `traf` boxes are enumerated in source
order. A traf requires exactly one direct `tfhd`, permits at most one direct
`tfdt`, and owns all of its direct `trun` boxes in source order.

Value resolution for sample `i` is:

| Value | First choice | Second choice | Third choice |
|---|---|---|---|
| Duration | `trun[i].sample_duration` | `tfhd.default_sample_duration` | matching `trex` default |
| Size | `trun[i].sample_size` | `tfhd.default_sample_size` | matching `trex` default |
| Flags | `trun[i].sample_flags` | `first_sample_flags` for `i == 0` | `tfhd` then matching `trex` default |
| CTO | `trun[i].sample_composition_time_offset` | zero | zero |

Presence, not a nonzero value, selects a default. A non-empty run whose value
or flags cannot be resolved is rejected. `sample_flags` together with
`first_sample_flags` is contradictory. Sync is the inverse of flag bit
`0x00010000`.

Byte state is local to each moof:

```text
traf base = explicit tfhd.base_data_offset
          | moof offset when default-base-is-moof
          | previous traf data end
          | moof offset for the first traf

run start = checked signed(base + trun.data_offset), when present
          | previous run end, for a later run
          | traf base, for the first run

sample offset = current run cursor
next cursor   = checked(offset + size)
```

The last run cursor becomes the implicit base for the next traf. A zero-sample
run leaves the cursor at its resolved start. Explicit bases do not inherit a
sibling's value.

Decode state is a map keyed by track ID. Segment start is `tfdt` when present,
otherwise that track's prior decode end, otherwise zero. Each sample receives
the current DTS and the cursor advances by resolved duration. A successful
traf stores its final time back into the track map.

Existing aggregates are computed across all runs in the traf. `SampleCount`,
`Duration`, and `Size` are checked `uint32` sums. `BaseMediaDecodeTime` is the
traf start. `CompositionTimeOffset` is the minimum checked signed value of
elapsed traf duration plus each sample CTO, matching the old meaning but no
longer only one run. `DefaultSampleDuration` remains the raw `tfhd` field.

## 7. Overflow model

No unchecked arithmetic contributes to a public field or slice index.

- Unsigned offset/end/time addition checks `a <= max-b` first.
- Signed `trun.data_offset` uses separate positive and negative branches, so a
  negative value cannot become a huge unsigned offset.
- PTS handles positive and negative CTO branches without converting an
  out-of-range DTS to `int64`; values outside `int64` are rejected.
- Table run counts and chunk coverage are widened to `uint64`, bounded by the
  declared `uint32` sample count, and converted to indexes only after checks.
- Segment count, duration, size, and earliest composition aggregate must fit
  their existing `uint32`/`int32` fields. Decode time remains `uint64`.
- `BoxInfo` payload endpoints and sample endpoints are checked before interval
  comparisons.

Any overflow returns `(nil, error)`. Saturation and wrapping would make the
reported location or existing aggregate untrustworthy and are not used.

## 8. Range-validation proof

For each top-level `mdat`, the probe records
`[Offset + HeaderSize, Offset + Size)`, after proving the header and endpoint do
not overflow and the header does not exceed box size. Neither recording nor
validation seeks into the payload.

Classic offsets begin at declared chunk offsets and advance by resolved sample
sizes; fragment offsets begin at a resolved base/run cursor and do the same.
The final pass computes each non-empty sample's checked half-open range and
accepts it only if one recorded media interval contains both endpoints. Thus a
sample cannot begin in a header or gap, cross between `mdat` boxes, or extend
past the local stream. Zero-size samples do not claim bytes and are exempt as
specified.

Because all top-level boxes are discovered before validation, `mdat` may appear
before or after `moov`/`moof`, and any number of media boxes is handled. Because
the return occurs only after the complete pass, a late bad range cannot expose
a partial `ProbeInfo`.

## 9. Compatibility ledger

| Existing behavior | Preservation mechanism | Regression check |
|---|---|---|
| Brands, movie time, fast-start | Keep the current top-level cases and assignments. | Existing `TestProbe`. |
| Track metadata/codecs/encryption/edit list | Leave extraction and decoder-config paths unchanged. | Existing fixture tests. |
| Sample size/delta/CTO | Fill the same fields from the same tables, adding exact validation. | Existing assertions and bitrate tests. |
| Chunk offsets/counts | Keep public chunks and populate them from the validated map. | Existing chunk assertions. |
| Fragment summaries | Preserve field types and semantics, generalized across every run in one traf. | Existing fragmented fixture values. |
| Bitrate helpers | They continue consuming the authoritative existing fields. | Existing helper and CLI tests. |
| `FindIDRFrames` | Sample order, size, and chunk layout remain unchanged. | Existing IDR and command tests. |
| CLI output | New public fields are not added to the private report structs. | Existing JSON/YAML golden output. |
| Deprecated aliases | `FraProbeInfo` and `SegmentInfo` still alias the extended types. | Compilation and upstream tests. |

The only intentional strictness is refusal of malformed or contradictory
metadata covered by the task. Valid existing inputs retain all prior values.

## 10. Discriminator matrix

| Plausible shallow implementation | Killing cases | Independent assertions |
|---|---|---|
| Per-entry `stsz` only | constant-size `stsz` with `co64` | size, absolute offset, and range seek |
| Unsigned or omitted classic CTO | signed version-1 `ctts` | negative CTO and negative PTS |
| No `stss` means no sync | absent `stss` | every sample reports sync |
| Chunk start copied to every sample | multi-sample chunks | distinct accumulated offsets |
| Last child wins in a flattened moof | two trafs, multiple runs | segment ownership/order and all sample lists |
| `tfhd` values only | mixed entry/tfhd/trex defaults | size, duration, flags, PTS, and aggregates |
| First flags leak across run | two-sample run | first and later sync states differ |
| Data offset cast to unsigned | negative signed run offset | exact local offset and valid range |
| Reset every run/track | omitted later offset and `tfdt` | byte continuation and per-track time continuation |
| Skip media bounds | header/gap/EOF samples | nil information and error |
| Return early result | valid first data plus late contradiction | error with nil info |
| Inspect media to verify | guarded seeker | success with zero payload reads |

The constant/co64 classic case and multi-traf/multi-run fragment case are the
two architectural discriminators. Late refusal and payload opacity reinforce
them without relying on private helpers.

## 11. Prompt/test ledger

| Contract clause | Public tests |
|---|---|
| Named fields populated for both forms; old fields authoritative | existing classic fixture; fragmented fixture; mixed generated files |
| Absolute offset and media-time DTS/PTS | payload byte seeks; exact timing arrays; negative PTS |
| Full classic table reconciliation | constant `stsz`/`co64`; varying chunks; signed `ctts`; malformed count table |
| Decode order, within-chunk accumulation, `stss` semantics | ordered sample comparisons; present and absent sync table |
| One ordered segment per traf and old aggregates | two-traf/multi-run file; existing fragmented fixture |
| Fragment precedence and sync flag | deliberately mixed trun/tfhd/trex values and first-sample flags |
| Signed/continued fragment byte and time state | negative data offset; later omitted offset and `tfdt`; interleaved tracks |
| Leading/multiple media boxes; empty forms | generated leading and split `mdat`; empty initialization and zero run |
| Refusal, overflow, nil partial result | malformed classic and fragment table-driven cases; late bad range |
| No payload reads and full compatibility | guarded seeker; full upstream suite, CLI, bitrate, and IDR tests |

`meta.md` will state every row in maintainer prose, including the exact public
field names because callers and tests must compile against them. It will not
name private helpers or prescribe traversal structure.

## 12. Measured scope and consolidation

The earlier disposable feasibility prototype changes only `probe.go` and has a
raw `+296/-81` diff. Its recorded strict effective addition was 230 lines. It
duplicates value selection and validation in the classic and fragment paths
and carries aggregate-only branches alongside sample expansion.

The clean implementation will consolidate most of that gap by:

1. using shared checked unsigned, signed, and presentation-time additions;
2. expanding classic fields directly into the final fixed sample slice instead
   of building separate partial slices;
3. resolving fragment sample fields once, then deriving both the sample and
   legacy aggregates from those values;
4. validating both track and segment sample ranges through one final interval
   pass; and
5. keeping traversal/refactoring in `probe.go` rather than introducing a second
   parser or model file.

The clean result is 230 strict effective production lines in `probe.go`, with
tests and harness excluded. Shared fragment field resolution and shared checked
time/offset arithmetic closed the prototype gap while retaining all required
validation. The implementation therefore meets the 230-line gate exactly.
