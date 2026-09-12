# SUMMARY - go-mp4 sample locations

**Status: REJECTED FOR OVERLAP. The implementation remains fully locally
verified, but this task must not be submitted or calibrated.**

| Field | Value |
|---|---|
| Repository | `abema/go-mp4` |
| Production language | Go |
| Task type | enhancement |
| Base commit | `7f0bb4060772e78fb52d48b73a38b8c3928e83f0` (`v1.7.1`) |
| Suggested title | Report byte location and timing for every local MP4 sample |
| Description | `meta.md`, 401 words, ASCII |
| Production change | `probe.go`, 230 strict effective added lines (`+288/-92` raw diff) |
| Challenge suite | 42 tests in `grader_tests/sample_locations_test.go` |
| Existing suite | 308 tests |

## Result

`Probe` now reports the byte offset, decode time, signed presentation time, and
sync status of every local classic or fragmented sample. Classic sample tables
are reconciled exactly. Fragment ownership, defaults, signed offsets, and
per-track decode continuation are resolved in source order. All sample ranges
must lie inside a local `mdat` payload, and payload bytes are never read.

Existing sample fields, aggregates, bitrate helpers, `FindIDRFrames`, and CLI
output remain compatible. A malformed or overflowing file returns an error and
nil probe information, including when the failure occurs after earlier valid
samples.

## Verification

The final four gates ran in the packaged image with networking disabled:

| Checkout state | Mode | Result |
|---|---|---|
| `test.patch` only | `base` | 308 passed |
| `test.patch` only | `new` | expected compile failure: public fields absent |
| both patches | `new` | 42 passed |
| both patches | `base` | 308 passed |

The gate exercised all accepted output-path argument placements, removed stale
reports, and parsed every generated JUnit document. Both patches pass
`git apply --check` on the untouched pinned checkout. `go vet` is not part of
the grading path.

Mutation testing killed all 12 behavior mutations. Each produced at least two
independent assertion failures. The mutations cover constant `stsz`, signed
`ctts`, absent `stss`, chunk accumulation, `trex` defaults, multiple `traf` and
`trun` boxes, first-sample flags, signed data offsets, per-track decode state,
`mdat` containment, and nil-on-late-error behavior.

Patch SHA-256 values:

- `solution.patch` and `reference_solution.patch`:
  `0679f01b8d2018b190397afc533b14881d2370ad4a54984ef86919bad7a1243f`
- `test.patch`:
  `bc79d9248d0fd519f857085530e431bcaa3ae198bbe67b690ea5d8c25f7a6e49`

## Upstream and uniqueness audit

The repository audit found no equivalent go-mp4 issue, pull request, release,
or local problem. A later submission-archive review found an existing
cross-repository task with the same core: enumerate progressive and fragmented
MP4 samples with offsets, DTS/PTS, sizes, sync state, fragment defaults, data
cursors, and `mdat` validation. Its CLI surface, `sdtp`, edit-list, `sidx`, and
soft-error additions were judged incremental rather than a distinct behavioral
slice.

This is a terminal uniqueness failure under `PLAN.md`. Extending this task with
those same additions would increase the overlap rather than cure it.

## Coverage review

The final suite directly covers explicit `tfhd.base_data_offset`, the enclosing
`moof` offset, a nonzero earliest fragment composition summary, metadata before
and after `mdat`, multiple `mdat` boxes, empty initialization tracks, and
zero-sample fragments. These checks are public-API assertions and the media-read
guard remains behavioral.

No calibration should be launched for a rejected task. `LEVELS.md` records L1
as archival only.

## Artifacts

| File | Purpose |
|---|---|
| `meta.md` | submission description |
| `DESIGN.md` | contract, state machines, proofs, and audit ledgers |
| `test.patch` | behavior tests and executable two-mode harness |
| `solution.patch` / `reference_solution.patch` | identical production patch |
| `Dockerfile` | reproducible Go image |
| `solution_approach.md` | code-derived implementation explanation |
| `verify/` | offline four-gate and mutation runners |
| `LEVELS.md` | calibration state and adjustment levers |
| `ERRORS.md` | operational exceptions and unresolved boundary |
