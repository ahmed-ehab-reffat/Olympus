# Website-flagged issues - go-mp4 sample locations

Reviewed: 2026-07-23. Verdict: **REJECTED - cross-repository task overlap.**

## 1. Terminal uniqueness failure

The reviewed task shares the same central solver work as an existing
submission: reconcile progressive and fragmented MP4 metadata into per-sample
absolute offsets, DTS/PTS, size, sync state, and data-cursor positions, then
validate ranges against `mdat`.

The other submission exposes a reporting CLI and additionally handles `sdtp`,
edit-list mapping, `sidx`, and soft-error rows. The reviewer found those to be
incremental features atop the shared core rather than a meaningful new
behavioral slice. The library API here is also a surface difference, not a
different underlying task.

This satisfies the explicit stop condition in `PLAN.md`. Do not submit,
calibrate, or attempt to rescue it by adding the cited incremental features.

## 2. Description defects - resolved

The source `meta.md` contains one copy of the description. The redundant
compatibility clause was removed, and the public field declaration now reads
unambiguously as "a `Samples` field of type `Samples`." The final description is
401 words and ASCII-only.

## 3. Coverage warnings - resolved

The final behavior-only suite adds direct assertions for:

- explicit `tfhd.base_data_offset`;
- the enclosing `moof` offset stored on each relevant segment;
- a nonzero earliest fragment composition-time summary;
- metadata preceding `mdat`, alongside the existing `mdat`-first and
  multiple-`mdat` cases; and
- an empty initialization track.

The suite now has 42 tests. All pass with the solution, the untouched base still
fails for the intended missing API, all 308 upstream tests pass in both
compatibility gates, and all 12 mutations remain killed.

## 4. Runner warning - resolved

`go vet ./...` was removed from base mode. The harness now grades the complete
upstream test suite without making unrelated static-analysis warnings fatal.
It still removes stale output, runs without test fail-fast behavior, accepts
both output-path forms, and emits well-formed JUnit on compile/setup failure.

## 5. Dependency warning - not applicable

The pinned repository contains both `go.mod` and `go.sum`. The image installs
`gotestsum@v1.13.0` and downloads modules during image construction. All four
runtime gates pass with Docker networking disabled.
