# Solution approach - complete MP4 sample metadata

## Public model

The implementation extends the existing `Sample` value with absolute byte
offset, decode time, signed presentation time, and sync status. `Segment` now
holds the same `Samples` collection used by classic tracks. No second parser or
payload API is introduced, so callers keep using `Probe` and all existing
aggregate fields remain available.

## Top-level collection

The selective `ExtractBoxes` traversal now includes `trex`. While visiting the
returned box locations, `Probe` records each top-level `mdat` payload as a
half-open byte interval and indexes fragment defaults by track ID. It never
expands or unmarshals `mdat`; the normal reader seeks to the box end.

Track and fragment samples are built from metadata, then every non-empty sample
range is checked against the collected intervals. Validation happens before
the result is returned, so a late bad range produces an error and nil
information rather than a partial result.

## Classic tracks

`stsz.SampleCount` is the common sample count. The implementation expands
`stts` only while it stays within that count, verifies exact completion, and
uses either the constant `stsz.SampleSize` or the corresponding entry size.
Optional `ctts` runs must also cover exactly the same samples.

The `stsc` map must start at chunk one, progress strictly, address real chunks,
and assign a positive sample count. Walking the resulting chunks in order does
four jobs in one pass:

1. assign the current absolute chunk cursor to `Offset`;
2. assign and advance checked decode time;
3. form signed presentation time from decode time and composition offset; and
4. advance the chunk cursor by the resolved sample size.

The walk must consume exactly the declared sample count. With no `stss`, sample
construction defaults `IsSync` to true. With `stss`, samples start non-sync and
only valid unique one-based entries are marked sync.

## Movie fragments

Each `moof` is first divided into its direct `traf` children. Each child is
parsed independently and requires one `tfhd`, at most one `tfdt`, and any
number of ordered `trun` boxes. This prevents headers or runs from sibling
tracks from being combined.

The traf data base comes from `tfhd.base_data_offset`, the enclosing `moof`, or
the preceding traf's data end. A present signed `trun.data_offset` is added to
that base with checked signed arithmetic. Otherwise a later run starts at the
prior run end.

`fragmentSampleFields` starts with the matching `trex` defaults, overlays
present `tfhd` defaults, then overlays per-entry `trun` values. First-sample
flags are applied last only for entry zero when entry flags are absent. The
non-sync bit becomes the inverse of `IsSync`.

Decode state is stored per track. `tfdt` replaces it when present; otherwise a
traf continues that track's prior end, with a missing initial value naturally
starting at zero. Each resolved sample updates both this state and the run byte
cursor. The same resolved size, duration, flags, and composition offset feed
the public sample and the existing segment aggregates, so they cannot diverge.

## Checked arithmetic

Unsigned additions reject wraparound. Signed byte offsets and presentation
times use separate positive and negative paths, preserving negative PTS while
rejecting values outside the destination type. Existing `uint32` segment
count, size, and duration fields and the `int32` earliest composition field are
checked before update. This keeps all public offsets, times, ranges, and legacy
summaries representable.
