# feedback.md - starlark-go-inplace-mutation (was starred-unpacking)

Olympus. Feature: in-place list/dict mutation - list slice assignment (x[i:j]=y),
the `del` statement (del x[i] / x[i:j] / d[k]), and in-place list.sort()/list.reverse().

## Why this shape (DERIVATIVE PIVOT)
The prior starred-unpacking version was flagged DERIVATIVE (0.73, sim 0.78) vs a prior
submission that already did starred unpacking (assignment + display splicing + dict **).
Reviewer confirmed my slice assignment was the DISTINCT part. Reshaped: dropped all
starred/display/`**` work (the overlap), kept slice assignment, and added `del`
(reserved-but-unimplemented keyword) + in-place sort/reverse. New core purpose =
in-place mutation, distinct from all 5 candidates (starred, serialization, imports,
type-annotations, optimizer). Renaming/rewording was NOT used (anti-pattern).

## Also fixed from the same review
- Error tests now use bare err!=nil (no message-substring coupling) - fixes the
  tests_focus_on_behavior WARNING.
- Rewrote meta from scratch: no "as before" / "Slicing bounds follow the same rules" /
  "preserving order," / "not only indexable ones." - fixes the description request_changes.

## Status: LOCAL-VALIDATED, submit-ready (no platform eval yet)
- Genuine effective LOC = 276 (strict whitespace-normalized; >=250 floor).
- 31 new tests pass on solution, FAIL on base (parse/resolve/runtime errors for the
  missing syntax); full base suite green; base+new deterministic x3 (flakiness gate).
- Patches apply+reverse both orders; base mode excludes new tests via //go:build mutate_bc87cd;
  test.sh 100755, test file 100644; no banned markers; meta ASCII-clean.
- Comments match repo doc-comment convention (incl. the repo's own #list<middot>sort spec-URL style).

## Hardening (fair, FP-safe)
- del x[i]: one syntax dispatches list-index-delete vs dict-key-delete (two behaviors).
- Slice + del reuse the read-path sliceIndices (identical bound/step normalization).
- A8/A9: extended-slice exact-length; empty-slice insert/delete; iterable (range/string) RHS;
  out-of-range / missing-key / immutable-target rejections; multi-target del left-to-right.
- sort is stable with key=/reverse= mirroring sorted(); returns None; frozen/iteration guards.

## Open (pre-submit)
- meta ~330 words (<500 cap; dense, no filler, no flagged phrases).
- 1 codebase-inferable: augmented-assignment rejection of slice targets (existing behavior).
- Folder renamed problems/starlark-go-inplace-mutation.

## SHELVED (maintainer-philosophy) 2026-07-22
Platform blockers: list.sort() DECLINED (bazelbuild/starlark#174 "no significant benefit");
del DELIBERATELY UNSUPPORTED (PR#321 documents it). Both LOC-boosting features are maintainer-
declined; slice-assign alone is ~99 eff (under 250) + same risk.
ROOT CAUSE: starlark-go is a deliberately-MINIMAL config language; maintainers decline language-
syntax additions. Accepted space = stdlib-module fns / Go embedding API / correctness fixes only,
all small/pattern-followable. => starlark-go is a POOR Olympus target for language features.
Also note: the starred-unpacking version (earlier) was DERIVATIVE. Two distinct death causes on
one repo. Do NOT author language-syntax features on starlark-go.
