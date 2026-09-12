Title: Report byte location and timing for every local MP4 sample

Extend `Probe` so callers can locate every media sample described by the MP4 file they supply. Add `Offset uint64`, `DecodeTime uint64`, `PresentationTime int64`, and `IsSync bool` to `Sample`. Add a `Samples` field of type `Samples` to `Segment`. Populate these fields for classic sample tables and movie fragments.

`Offset` is the absolute byte offset of the sample's first payload byte. Decode time, duration, and composition offset use the owning media track's timescale and are not adjusted by edit lists. Presentation time is the signed sum of decode time and composition offset, so it may be negative. Samples stay in decode order.

For classic tracks, reconcile `stco` or `co64`, `stsc`, both constant and per-sample forms of `stsz`, `stts`, optional `ctts`, and optional `stss`. Account for varying samples per chunk and preceding sample sizes within a chunk. Support signed version 1 composition offsets. When `stss` is absent, every sample is a sync sample; otherwise its entries are one-based sample numbers.

For fragmented media, return one segment per `traf` in movie-fragment and track-fragment source order. Keep all of that `traf`'s samples in `trun` and entry order, its track ID, and the enclosing `moof` offset. Resolve each sample's duration, size, and flags from its `trun` entry, then `tfhd`, then the matching `trex` default. `first_sample_flags` applies only to the first sample of its run when entry flags are absent, and the resolved non-sync flag determines `IsSync`. Existing segment counts, duration, size, base decode time, and earliest composition offset must summarize all runs in the `traf`.

Honor explicit `tfhd.base_data_offset`, `default-base-is-moof`, and the preceding track-fragment data end. A `trun.data_offset` is signed and relative to that base; a run without one continues from the prior run. Use `tfdt` when present. Otherwise continue decode time for the same track, starting at zero when that track has no earlier fragment.

Accept empty initialization tracks, zero-sample fragments, `mdat` before or after metadata, and multiple `mdat` boxes. Every non-empty sample range must fit wholly in one local `mdat` payload. Do not read, copy, hash, decode, or otherwise inspect sample payload bytes.

Reject malformed or contradictory metadata with an error and nil probe information. This includes inconsistent table counts or chunk coverage, invalid `stsc` or `stss` indices, duplicate required fragment headers, unresolved fragment defaults or offsets, arithmetic overflow, and sample ranges outside local media data. Exact error text is not part of the API.
