# PLAN - complete per-sample metadata in MP4 probes

Status: upstream audit and task preflight passed on 2026-07-23. This is a self-contained implementation handoff. The design and measured-scope gates below remain mandatory.

## 1. Task identity

| Field | Decision |
|---|---|
| Repository | `abema/go-mp4` |
| Language | Go |
| Task type | enhancement |
| Base commit | `7f0bb4060772e78fb52d48b73a38b8c3928e83f0` |
| Base version | `v1.7.1` |
| License | MIT |
| Work namespace | `work/go-mp4-sample-locations/` |
| Public entry point | `Probe(io.ReadSeeker) (*ProbeInfo, error)` |
| Working title | Report byte location and timing for every local MP4 sample |

Extend the existing probe result so callers can locate every local media sample without reimplementing the relationships among MP4 sample tables. The same public sample representation must work for classic files and movie fragments, preserve all current aggregate probe data, and derive metadata without reading or decoding media payload.

The final problem description must name the added public surface because tests need to compile against it: `Sample` gains `Offset uint64`, `DecodeTime uint64`, `PresentationTime int64`, and `IsSync bool`; `Segment` gains `Samples Samples`. This is broader behavior for the existing probe, not a new editing, extraction, or codec API.

## 2. Eligibility and upstream audit

The pinned commit is the current tagged release and was the default-branch head at preflight: <https://github.com/abema/go-mp4/commit/7f0bb4060772e78fb52d48b73a38b8c3928e83f0>. On 2026-07-23 the repository had 543 stars, an MIT license, 28 releases, and a latest commit/release dated 2026-06-16. GitHub reported that Discussions are disabled and showed no open pull requests.

All issue and pull-request searches included closed and merged results.

| Surface | Concepts searched | Result |
|---|---|---|
| Issues | `sample location`, `sample index`, `sample iterator` | No result exposing or proposing this API. |
| Issues | `sample offset`, `DTS`, `PTS`, `timestamp`, `sync sample` | Adjacent issues only. In [#120](https://github.com/abema/go-mp4/issues/120), the maintainer explains how a caller can manually combine `stco` and other low-level APIs; no reusable implementation was proposed. Issue [#26](https://github.com/abema/go-mp4/issues/26) requested one aggregate composition offset and was fixed by PR #43. |
| Issues | `fragmented sample`, `trun`, `tfhd`, `trex` | No per-sample probe task. Issue [#127](https://github.com/abema/go-mp4/issues/127) gives general fragmented parsing guidance. |
| Pull requests | `probe`, `sample`, `offset`, `fragment` | [PR #87](https://github.com/abema/go-mp4/pull/87) created `Probe`; [PR #43](https://github.com/abema/go-mp4/pull/43) added the segment composition aggregate; [PRs #135](https://github.com/abema/go-mp4/pull/135) and [#136](https://github.com/abema/go-mp4/pull/136) added `co64` probing. None reports per-sample locations or fragment samples. |
| Relocation prior art | media movement, chunk offsets | Closed [issue #165](https://github.com/abema/go-mp4/issues/165) publicly demonstrates stale `stco` offsets after editing. Relocation-aware rewriting is excluded from this task. |
| Code and history | proposed fields, `sample location`, iterator names, decode/presentation time, sync status | No equivalent fields, helper, abandoned branch, or commit was found. Current `Probe` exposes classic sizes/deltas/chunks and fragment aggregates but not complete per-sample metadata. |
| Release and README history | probe and fragmented MP4 behavior | The latest release remains `v1.7.1`; the README describes `Probe` as a wrapper over low-level parsing and does not provide this result. |

Issue #120 is the closest prior-art risk. It establishes demand for locating a sample and confirms that the raw boxes are already accessible, but it was closed after usage guidance and neither supplies nor rejects a high-level `Probe` result. No maintainer statement declining this enhancement was found.

### Repository and local fit

`Probe` already expands `stco`/`co64`, `stsc`, `stsz`, `stts`, and `ctts` into public `Track`, `Chunk`, and `Sample` values, and it already summarizes `tfhd`, `tfdt`, and `trun` into `Segment`. Completing those existing public results is consistent with the library's low-level, non-decoding scope. It does not perform the complex data conversion that the README explicitly says is out of scope.

No existing Olympus problem targets MP4, cross-table sample addressing, or fragmented-media default resolution. This is a repository-specific binary-format task rather than a named textbook algorithm. The nearby 3D Tiles task concerns transactional publication and does not share its implementation shape or oracle.

Audit verdict: `proceed`.

## 3. Verified repository map

Read these files completely before producing `DESIGN.md`:

| Area | Files | Relevance |
|---|---|---|
| Probe model and coordination | `probe.go` | Owns `ProbeInfo`, `Track`, `Sample`, `Segment`, classic table expansion, fragment aggregation, bitrate helpers, and `FindIDRFrames`. |
| ISO BMFF boxes | `box_types_iso14496_12.go` | Defines all relevant table/run boxes, flag constants, signed composition-offset accessors, and 32/64-bit variants. |
| Tree traversal | `read.go` | Shows handler order, seek behavior, payload parsing, and how to avoid reading `mdat` bytes. |
| Focused extraction | `extract.go` | Supplies parent-scoped box lookup; scoping each `trun` to its owning `traf` is essential. |
| Byte ranges | `box_info.go` | Defines absolute box offsets, header sizes, and seek boundaries used to identify `mdat` payload ranges. |
| Existing public tests | `probe_test.go`, `testdata/sample.mp4`, `testdata/sample_fragmented.mp4` | Provide classic and fragmented baselines, exact aggregate compatibility, signed `ctts`, interleaved chunks, and real payload oracles. |
| CLI consumer | `cmd/mp4tool/internal/probe/probe.go` and its test | Must retain current report behavior while new public fields remain opt-in to consumers. |
| Related fragment code | `cmd/mp4tool/internal/divide/divide.go` | Demonstrates current `tfhd`/`trun` duration use but assumes one track fragment and one run; do not copy that shortcut. |

Important architecture facts:

- Classic samples are ordered by decode order inside each `Track.Samples`; `Chunk.DataOffset` plus `SamplesPerChunk` currently lets `FindIDRFrames` seek to payload manually.
- `stsz.SampleSize` represents a constant size and makes `EntrySize` empty. The current probe only copies `EntrySize`, so constant-size samples expose zero size today.
- `stss` is parsed by the library but ignored by `Probe`. Its numbers are one-based; if the box is absent, every sample is a sync sample.
- A movie fragment may contain multiple `traf` boxes and each `traf` may contain multiple `trun` boxes. The current implementation flattens all three paths and retains only the last `tfhd`, `tfdt`, and `trun`.
- Fragment duration, size, and flags use a precedence chain from a `trun` entry, through `tfhd`, to the matching `trex` default. Data offsets have a separate base/continuation state machine.
- `ReadBoxStructure` reads headers and selected metadata but seeks over an unexpanded `mdat`, making a no-media-read oracle deterministic.

## 4. Required public behavior

Translate these clauses into a two-way prompt/test ledger. The eventual `meta.md` must describe every tested behavior naturally, use ASCII, and remain below 500 words; target at most 470 words.

1. `Probe` populates the four named location/timing fields on every classic `Track.Samples` element and exposes every fragment sample through the named `Segment.Samples` field. Existing `Size`, `TimeDelta`, and `CompositionTimeOffset` values remain authoritative.
2. `Offset` is the absolute byte offset of the sample's first payload byte. `DecodeTime` and `TimeDelta` use the owning media track's timescale and are not adjusted by an edit list. `PresentationTime` is the signed sum of decode time and composition offset; negative presentation times are valid.
3. For classic tracks, reconcile `stco` or `co64`, `stsc`, `stsz`, `stts`, optional `ctts`, and optional `stss`. Support both constant and per-sample `stsz` forms, varying samples per chunk, 64-bit chunk offsets, and signed version-1 composition offsets.
4. Classic samples remain in decode order. Derive each within-chunk offset by accumulating preceding sample sizes. If `stss` is absent all samples are sync; otherwise only the listed one-based sample numbers are sync.
5. Emit one `Segment` per `traf`, in movie-fragment and track-fragment source order, retaining the owning `TrackID` and shared `MoofOffset`. Its `Samples` follow `trun` and entry source order; aggregate `SampleCount`, `Duration`, `Size`, `BaseMediaDecodeTime`, and earliest composition offset must retain their current meanings across all runs in that `traf`.
6. Resolve fragmented duration, size, and flags per sample with `trun` values taking precedence over `tfhd`, then matching `trex` defaults. `first_sample_flags` applies only to the first sample of its run when per-entry flags are absent. `IsSync` reflects the resolved non-sync flag.
7. Resolve fragment byte positions using explicit `tfhd.base_data_offset`, `default-base-is-moof`, or the preceding track-fragment data end as applicable. A `trun.data_offset` is signed and relative to that base; a run without one continues from the preceding run. Use `tfdt` when present and otherwise continue decode time for the same track, beginning at zero when no earlier value exists.
8. Accept `mdat` before or after metadata and files with multiple `mdat` boxes. Every non-empty returned sample range must be wholly contained in a local `mdat` payload. Empty initialization tracks and zero-sample fragments remain valid.
9. Reject malformed or contradictory metadata instead of truncating, indexing past a slice, wrapping arithmetic, or returning a partial `ProbeInfo`. This includes inconsistent classic table counts or chunk coverage, invalid `stsc`/`stss` indices, duplicate required fragment headers, unresolved run state, integer overflow, and sample ranges outside local media data. Exact error text is not part of the contract.
10. Do not read, copy, hash, decode, or otherwise inspect bytes inside sample payloads. Preserve all existing successful probe values, bitrate behavior, `FindIDRFrames` behavior, command output, and upstream tests.

Out of scope:

- applying `EditList` entries to reported media timestamps;
- compact `stz2` sample sizes, external data references, sample groups, dependency tables, or encrypted auxiliary-data locations;
- extracting or decoding video/audio/subtitle payloads;
- rewriting boxes, relocating media, repairing malformed files, or adding CLI output fields;
- returning samples from a separate external initialization segment that was not supplied to the same `Probe` call.

## 5. Intended design and measured scope

Keep one parsing path under `Probe`; do not add a second public iterator that reparses the file.

1. Extend the existing public structs and collect local `mdat` payload intervals while traversing top-level boxes.
2. Refactor classic table expansion so the declared sample count is established once, every run-length table is reconciled against it, chunk coverage is validated, and location/timing fields are filled during one ordered pass.
3. Parse `trex` defaults into a track-keyed lookup. Refactor fragment probing to enumerate `traf` parents first, then extract their direct `tfhd`, optional `tfdt`, and ordered `trun` children so values never leak between sibling tracks.
4. Carry only the small cross-fragment state needed for implicit data bases and decode-time continuation. Resolve each sample's precedence chain, update existing segment aggregates with checked arithmetic, and append it to that segment.
5. Before returning, validate each computed range against the collected `mdat` intervals. Construct and return `ProbeInfo` only on complete success; an error returns nil information.

A disposable prototype on the pinned commit changed only `probe.go`, populated both included fixture types, retained all upstream assertions, and passed `go vet ./...` plus the complete suite. It measured 230 strict effective added production lines before cleanup. The handoff target remains approximately 180-210 effective production lines in one or two files. `DESIGN.md` must identify concrete consolidation that closes most of the prototype gap; stop if a correct, readable implementation still exceeds roughly 230 effective lines rather than padding or silently changing the task.

Do not retain the disposable prototype as the reference solution. Reimplement from the pinned clean source after the design is approved.

## 6. Discriminators and shallow solutions to kill

The suite needs two independent architectural discriminators.

### Discriminator A: table/default parity

Plausible shortcuts handle only classic MP4, calculate offsets but omit timing/sync status, assume per-entry `stsz`, ignore signed `ctts`, or derive fragmented values only from `tfhd`. Cross the same per-sample fields through a classic constant-size/co64 case and a fragmented multi-run case whose duration, size, flags, and composition offsets come from different levels of the precedence chain.

### Discriminator B: source ownership and protocol state

Plausible shortcuts flatten all fragment children, keep only the last `traf`/`trun`, reset offsets at each run, treat signed data offsets as unsigned, or return partial data before detecting a later contradiction. Use one `moof` with two `traf` owners and multiple runs, followed by a malformed late table/range case. Assert segment/entry source order and nil information on refusal.

Payload non-reading, aggregate compatibility, and overflow checks reinforce these discriminators; they are not separate mini-tasks.

## 7. Behavioral test plan

Keep challenge tests outside the upstream package directories, for example in `grader_tests/` as an external package importing `github.com/abema/go-mp4`. Use generated in-memory boxes and the repository's small checked-in fixtures; do not download media or invoke FFmpeg.

| Case | Public assertions |
|---|---|
| Existing classic fixture | Exact offsets seek to the expected bytes; DTS/PTS/duration match table expansion; sync status matches `stss`; old probe and bitrate values are unchanged. |
| Classic constant `stsz` with `co64` | Every sample gets the constant size, 64-bit absolute offsets, varying chunk coverage, and exact decode order. |
| Classic signed `ctts`, no `stss` | Negative PTS is preserved; every sample is sync. |
| One `moof`, two `traf`, multiple `trun` | Two ordered segments retain their own track IDs; samples use source order and correct independent bases. |
| Fragment default precedence | Individual entries deliberately source size, duration, flags, and CTO from `trun`, `tfhd`, and `trex`; first-sample flags do not leak. |
| Fragment continuation | A missing later `tfdt` and missing later run data offset continue the correct per-track time and byte state. |
| Multiple and leading `mdat` boxes | Every range belongs to the correct payload regardless of top-level metadata order. |
| Payload-read guard | A custom public `io.ReadSeeker` fails any read inside `mdat` payload; `Probe` still succeeds. |
| Classic contradictions | Count mismatch, bad first/descending `stsc`, uncovered/extra samples, invalid/duplicate `stss`, and arithmetic overflow return error with nil info. |
| Fragment contradictions | Duplicate `tfhd`/`tfdt`, impossible base/data offset, overflow, and an out-of-`mdat` range return error with nil info. |
| Empty initialization | Existing zero-entry sample tables succeed and expose empty sample slices. |
| CLI and old API compatibility | Existing `probe_test.go`, `FindIDRFrames`, and command report tests remain unchanged and pass. |

Do not assert private helper names, exact parsing passes, allocation strategy, exact error strings, map types, or internal call order. Exact public field names are fair only because they must appear in `meta.md`.

Mutation checks must include: constant `stsz` ignored, `ctts` forced unsigned, absent `stss` treated as no sync samples, chunk-local accumulation omitted, `trex` defaults ignored, last-`traf` flattening, only first `trun` handled, first-sample flags applied to a whole run, data offset treated unsigned, per-track continuation replaced by one global cursor, `mdat` bounds skipped, and partial result returned after late failure. Every compiling mutation should break at least two behavioral assertions.

## 8. Harness preflight

Verified on Linux arm64 with Go 1.26.3 at the pinned commit:

- `go vet ./...` passed.
- `go test -count=1 ./...` passed all 308 tests across seven tested packages with no skips.
- The same commands passed with Docker networking disabled after `go mod download all` warmed the module cache.
- The repository has 31 Go test files and 364 KiB of checked-in media fixtures; no external service or large download is required.
- Upstream CI currently tests Go 1.23, 1.24, and 1.25 or newer even though `go.mod` retains a historical `go 1.14` directive.

Use an official supported Go image, preferably `golang:1.25-bookworm`. Download modules and install a pinned `gotestsum` during the image build, then prove both modes with networking disabled. Do not mutate `go.mod` or `go.sum` merely to modernize versions.

`test.sh` must support `base` and `new`, plus both accepted `--output_path PATH` placements. Base mode runs the complete upstream suite. New mode runs all challenge tests. Both modes must execute without fail-fast behavior, remove a stale report first, always emit well-formed JUnit XML (including setup/compile failures), and return nonzero on any failed test. Keep authoring and evaluation vocabulary out of repository-facing scripts and artifacts.

## 9. Execution sequence for the handoff agent

1. Start from the pinned clean source and create a separate solution worktree. Do not edit the audit source.
2. Create `DESIGN.md` first. Include the hard-rule ledger, refreshed upstream searches, public field contract, classic table state machine, fragment base/default state machine, overflow model, range-validation proof, compatibility ledger, discriminator matrix, clause/test ledger, and a fresh effective-LOC estimate.
3. Recheck default head, all issue and PR states, Discussions availability, releases, code, and history. Stop if equivalent work appeared after 2026-07-23.
4. Prototype the two-`traf`/multi-`trun` case and the constant-`stsz` classic case from a clean worktree. Demonstrate correct ownership, default precedence, nil-on-late-error behavior, and no `mdat` reads. Measure the production diff.
5. Present `DESIGN.md` for approval. Do not write the final tests, solution, Dockerfile, or submission artifacts until uniqueness, feasibility, behavior, and scope gates pass.
6. Write `meta.md` from the approved ledger in natural maintainer prose, ASCII only, below 500 words. Explicitly name the required public fields without prescribing private helpers.
7. Build behavior-only challenge tests and the offline harness. Prove base mode passes on the untouched commit and new mode fails for the intended missing behavior.
8. Implement the smallest reference solution. Preserve existing exports, aggregates, CLI output, errors not made stricter by the task, formatting, and Go compatibility. Run `gofmt`, `go vet`, upstream tests, and challenge tests.
9. Run four pristine-clone gates with networking disabled: base pass; new fail without the solution; new pass with it; base pass with it.
10. Run mutation testing, JUnit validation, payload-read guarding, ASCII/leak scans, patch-application checks, and an explicit patch file-list audit.
11. Create `solution.patch`, an identical `reference_solution.patch`, and a code-derived `solution_approach.md` that contains no calibration or evaluation language.
12. Calibrate with at least ten independent agent runs. The current target is a 30-40% legitimate solve rate with at least one solve; verify the live platform criteria before launching runs.

Expected durable artifacts after implementation are `DESIGN.md`, `meta.md`, `test.patch`, `solution.patch`, `reference_solution.patch`, `Dockerfile`, `solution_approach.md`, `SUMMARY.md`, `LEVELS.md`, `ERRORS.md`, `verify/`, and compact trajectory indexes/bundles as required by the current platform.

## 10. Stop conditions

Stop and report instead of improvising if:

- issue #120 or another upstream item is found to contain an unreviewed implementation rather than usage guidance;
- an equivalent issue, PR, fork, release, or archived local problem appears;
- fair tests require codec knowledge, external tools, private call-order assertions, or media downloads;
- correct local offsets cannot be defined without adding external data-reference or compact-size support to the same task;
- the clean implementation materially exceeds the 230-line ceiling or cannot preserve current `Probe`, CLI, and `FindIDRFrames` behavior;
- the full tested contract cannot be stated naturally inside the 500-word description limit;
- calibration produces no legitimate solve or a solve rate materially above the current target after fairness review.
