# feedback.md — kira-frame-accurate-start-times

## Summary

Repo: tesselode/kira (Rust game-audio engine, MIT OR Apache-2.0, ★1060). Base 3d6421e37b8bc0194cfa9fdf840d2eb206fe7270 (same base as our approved kira-loop-crossfade; no commits since).
Pick source: hunt 2026-09-18-C (second lane in a proven repo; maintainer invitation in changelog v0.10).
Tier: Olympus. Category: feature-request (platform categories are now Feature Request / Bugfix / Refactor; user prefers Feature Request).

Known risk (accepted by the user 2026-09-18): public maintainer branches `buffers*` and
`v0.10-buffered-rewrite` implement per-frame clock/modulator buffers (never PRs). Reference uses a
per-buffer crossing instead; core-slice precheck owed before extra scope.

## Attempt history

| Round | Date | Change | Result |
|---|---|---|---|
| 0 | 2026-09-18 | DESIGN.md | — |
| 1 | 2026-09-18 | Core slice for the Step 4b precheck: shared kernel (`Clock` buffer-start state + `advanced` flag reset per internal buffer; `Info` carries `BufferTiming`; `frame_reached` / `frame_after_delay`, mock clocks static), `StartTime::start_frame`, silent prefix in static and streaming sounds, timing through the five `Info::new` sites. 11 files, 173 human-effective (hook). 25 public-API tests (`crates/kira/tests/start_frames_d57a37.rs`), meta.md 246 body words scoped to sounds only. | Local: 94 lib tests unchanged; new 20/25 fail on base (the 5 passing are preservation cases), 25/25 with the slice. Clean room (fresh clone at base, test.patch applied, image built, `--network none`, uid 1000): base 96/96 without and with the solution; new 20 failures / 25 cases without, 25/25 with on 3 runs; base 3x identical. Cold image build 222 s. **Awaiting the platform precheck (user).** |

## Status

**REJECTED at the Step 4b precheck (2026-09-18): publicly-solved, Blocker, unfixable.** Moved to
`rejected/`. Scope gate: "Kira deliberately removed sample/frame-accurate clock-driven sound starts
when v0.10 introduced buffered processing; the submission restores that removed capability." Cited
commit 4c29057a76b94ecbda888f625b5445eb11d01869 (replaced per-frame processing with buffered
processing) and `changelog.md` L102-L124 ("Clocks are no longer sample accurate"). "The gate rules
treat reintroduction of a capability maintainers removed as unfixable, regardless of whether the
modern implementation uses a new buffered-compatible mechanism." Corpus overlap was Low: 0 of 206
authored lines against the nearest submission.

Lesson: the hunt and DESIGN both read that changelog paragraph as a maintainer INVITATION ("let me
know!") and the removal-era branches as mitigable prior art. The gate reads the same paragraph as a
removal record. A capability the repo used to ship and deliberately dropped is prior art in its own
history, whatever the new mechanism. See TOO-EASY.md (removed-capability row) and the olympus-hunt
removed-capability check.

The "Owed" list below is kept for the record only.

## Owed after a clean precheck

1. `Parameter` tweens: frame-quantized start, hold-then-ramp `interpolated_value`, end value at the
   elapsed time since the start frame (sound, track, effect and clock speed tweens).
2. `Tweener`: frame-accurate start; `Modulator::waits_on_clock` provided method.
3. Dependency-ordered clock/modulator update (tweener waits on a clock; clock follows a modulator;
   clock speed tween waits on another clock); cycles fall back to key order.
4. meta.md: the tween / tweener / clock-follows-modulator sentences; `Info::when_to_start` unchanged.
5. Tests: tweens, tweener, clock speed (both key orders), chain, preservation (see DESIGN § 9).
6. Trap reproduction: base order, reorder, late pass, key-order-only; one-backend-call extent.
7. Docker: check whether the platform context carries remote branch refs (`buffers*`,
   `v0.10-buffered-rewrite`).
