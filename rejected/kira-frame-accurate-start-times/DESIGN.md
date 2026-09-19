# DESIGN.md — kira-frame-accurate-start-times

## 1. Title

Add frame-accurate start times to static and streaming sounds (full scope: tweens and tweeners too)

## 2. Shape classification

- Shape: O-Pipeline-hard with an S2/S3 lead (SHAPES.md § Pattern 11). One new kernel (the frame at
  which a clock time or delay is reached inside an internal buffer) feeds five consumers (static
  sound, streaming sound, `Parameter` tweens everywhere, the `Tweener` modulator, clock speed tweens),
  and the renderer's clock/modulator update order has to become dependency-aware for the kernel to
  have its inputs when each consumer runs.
- Pass rate target: 15-35%.
- Best agent: Orion (long-horizon, end-to-end testing).
- Dominant verdict: INTEGRATION_ERROR (ordering, Info plumbing) with MISSED_REQUIREMENT on the chain cells.
- Solver/our LOC ratio: ~1.4x.

## Phase 1 — Repo understanding

**Architecture.** kira is a game-audio engine. A `Backend` drives a `Renderer`: `on_start_processing()`
once per backend call (commands are read there), then `process(out)` splits `out` into internal
buffers of `internal_buffer_size` frames (`renderer.rs:74`) and runs `process_chunk` on each:
`modulators.process(dt*n)` → `clocks.update(dt*n)` → `listeners.update(dt*n)` → `mixer.process(frame dt)`
(`renderer.rs:81-101`). Clocks (`clock.rs`) hold ticks + fraction and advance once per buffer by
`speed * dt*n` after updating their `speed: Parameter<ClockSpeed>` (which can follow a modulator).
Everything that waits reads `Info` (`info.rs`): `when_to_start(ClockTime)` answers Now/Later/Never
from the clock's state at the moment of the call. `StartTime` (`start_time.rs`) is Immediate /
Delayed(Duration) / ClockTime; sounds call `StartTime::update(dt*n)` once per buffer and play the whole
buffer once it turns Immediate (`static_sound/sound.rs:189-207`, `streaming/sound.rs:230-246`).
`Parameter<T>` (`parameter.rs`) tweens a value per buffer; consumers read
`interpolated_value((i+1)/n)` per frame (a linear ramp from the previous to the new buffer-end value).
The `Tweener` modulator duplicates the tween start logic (`modulator/tweener.rs:65-98`). Resources
live in `SelfReferentialResourceStorage` and update in key order (`backend/resources.rs:152`).

**Subsystems.** (1) clocks (`clock.rs`, `backend/resources/clocks.rs`); (2) info / start time
(`info.rs`, `start_time.rs`); (3) parameters and tweens (`parameter.rs`, `tween.rs`); (4) modulators
(`modulator.rs`, `tweener.rs`, `lfo.rs`, `backend/resources/modulators.rs`); (5) sounds and mixer
(`sound/static_sound`, `sound/streaming`, `track/*`, `backend/resources/mixer.rs`, `renderer.rs`).

**High-entanglement zones.** The renderer's update order (modulators before clocks, while clocks can
follow modulators); the five `Info::new` sites (clocks, modulators, listeners, mixer, sub-track); the
three copies of tween start logic (`StartTime::update`, `Parameter::update_tween`, `Tweener::update`)
which already disagree on `Delayed` (the parameter checks before subtracting, the start time after).

**Tests.** Inline `#[cfg(test)] mod test` next to each file, MockInfoBuilder with static clocks,
`process_one` 1-frame buffers (94 lib tests); integration tests in `crates/kira/tests/`
(`change_sample_rate.rs`). Template: `approved-problems/kira-loop-crossfade/test.patch` (capture
`Backend` that keeps the `Renderer`).

## Phase 2 — Existing-PR + publicly-solved check

Canonical `tesselode/kira`. Hunt (09-18-C) searched PRs/issues all states for sample accurate,
frame accurate, timing, internal buffer, clock, start time, quantized, offset, latency, gapless,
schedule: #116, #119, #136 open (no design, no PR); #75/#76 pre-0.10 (the tick_accuracy test was
deleted when 0.10 went buffered). No PR in any state.

**Public prior art found (maintainer branches, never PRs):**
- `buffers`, `buffers-no-modulators`, `next-buffers` (2024-03, pre-0.10 layout): per-frame `ClockInfo`
  buffer (`BufferedClock`).
- `v0.10-buffered-rewrite` (2024-12, 14 commits off `eb530c6a`, from-scratch skeleton, same paths):
  per-frame clock and modulator buffers updated "in lockstep" (`f755330d`), `SingleFrameInfo` with a
  per-frame `when_to_start`, per-frame playback-state updates. No static/streaming sounds, no tween
  hold-then-ramp, no dependency ordering; the design is the per-frame architecture the maintainer
  abandoned for performance (changelog 0.10: "Clocks are no longer sample accurate ... I have some
  ideas for how sample-accurate clocks could be implemented within the buffered architecture").

Mitigation (user decision 2026-09-18): the reference solves a per-buffer crossing, not per-frame
state; a test catches the "force 1-frame internal buffers" jump; confirm at Docker time whether the
platform context carries remote refs; Step 4b core-slice precheck before any extra scope.

## Phase 3 — Candidates

| Candidate | One-line behavior | Shape | Files | Meaningful | Predicted | Verdict |
|---|---|---|---|---|---|---|
| **A. Frame-accurate start times (this pick)** | clock/delay start times land on the exact frame for sounds, tweens, tweener, clock speed tweens; dependency-ordered clock/modulator update | O-Pipeline-hard / S2+S3 | 14-16 | ~320 | 15-35% | keep |
| B. A + frame-accurate `resume_at` | also resume sounds and sub-tracks mid-buffer (children process only the rest of the buffer) | same | 18 | ~380 | — | REJECT: both `resume_at` repo tests (`static_sound/sound/test.rs:458`, `streaming/sound/test.rs:513`) pin today's one-buffer fade lag; a frame-accurate fade breaks them = L31 cheat trap |
| C. Runtime delay-time changes (changelog: "please make a PR!") | smooth delay-line time changes | C | 1 | ~120 | — | REJECT: textbook fractional delay, one file, under floor |
| D. Send-to-send routing | topological order of send tracks | C | 2 | ~150 | — | REJECT: textbook graph work |
| E. Tween-completion accuracy (#136) | tweens END on exact frames | A2 | 3 | ~80 | — | REJECT: one clamp; folded out of A |

Death-class guard on A: (1) not one guard at many sites — the kernel is shared, but the consumers
differ (silent prefix, hold-then-ramp, end-of-buffer elapsed) and the ordering problem is not a site
at all; (2) not single-subsystem (clock, info, parameter, modulator, sound, renderer); (3) difficulty
survives full statement: every rule is stated, the walls are the update order, the chain composition,
the internal-buffer extent and the five Info sites; (4) not a port — kira's ticks+fraction clocks,
buffer-end modulator values and per-buffer tween interpolation are kira's own model; (5) yes.

Arsenal: lead **S2** (clock-follows-modulator × tweener-waits-on-clock; one correct composition,
three wrong exits each failing a different test), **S3** (mock-based repo tests; existing modulator
timing), **A9** exact-fit (a time reached exactly at the buffer end), **F-9** origin (five `Info::new`
sites; a sub-track built without buffer timing silently falls back), **L24 noun extent** (internal
buffer vs backend call).

## 3. Public API surface

No new public API is needed by the tests. The tests use only existing public API: `AudioManager`,
a test `Backend`, `StaticSoundData`, `StreamingSoundData` with a test `Decoder`, `ClockHandle`,
`TweenerBuilder` / `TweenerHandle::set`, `Value::FromModulator` + `Mapping`, `Tween`, `StartTime`,
`TrackBuilder`, `VolumeControlBuilder`. The reference adds crate-private helpers and one provided
method on the public `Modulator` trait (`waits_on_clock`, default `None`) which no test calls.

## 4. Canonical output form

- n = frames in the internal buffer being rendered (the last one of a backend call may be shorter).
- Clock position at frame i of a buffer: `P0 + (P1 - P0) * i / n`, P0/P1 = its time before/after the
  buffer (0 before a clock's first ticking buffer).
- ClockTime T reached at frame j = smallest j in [0, n) with the clock ticking and position(j) >= T;
  none in [0, n) → not this buffer (so P1 == T exactly → frame 0 of the next buffer).
- Delay d reached at frame j = ceil(d / frame_dt) counted from the frame it began counting on.
- Sound: out[i] = 0 for i < j; out[j + k] = what an Immediate sound outputs at k.
- Tween: before j the previous value; frame i >= j: `prev + (end - prev) * (i + 1 - j) / (n - j)`;
  end = tween(elapsed = (n - j) * frame_dt).
- Tweener: value after the buffer = tween((n - j) * frame_dt).
- Parameters following a modulator: unchanged linear ramp over the whole buffer.
- Mock `Info` (unit tests): clocks static; an update is one frame.

## 5. Blind-spot pre-empts

- Stated inverse / preservation: "anything reached on the first frame of a buffer behaves exactly as
  it does today; so do `resume_at` and `Info::when_to_start`."
- Pipeline placement: "a clock whose speed follows a modulator moves at the value that modulator ends
  that buffer with, as today."
- Exact boundary: "a time reached exactly at the end of a buffer is reached on the first frame of the next."
- Extent: "internal buffer" used consistently (L24).
- Codebase-inferable (the one allowed): `Mapping` / decibel interpolation formulas are the repo's own.

## 6. Description draft

See meta.md (kept in sync); ~430 words, plain prose, no headers.

## 7. File footprint

| Action | Path | Raw | Meaningful | Reason |
|---|---|---|---|---|
| MODIFY | crates/kira/src/clock.rs | +40 | 30 | buffer-start state, advanced flag, speed dependencies |
| MODIFY | crates/kira/src/info.rs | +70 | 50 | buffer timing, `clock_crossing`, mock fallback, delay frames |
| MODIFY | crates/kira/src/start_time.rs | +35 | 25 | frame-accurate update returning the start frame |
| MODIFY | crates/kira/src/parameter.rs | +55 | 40 | frame start, hold-then-ramp, dependency accessors |
| MODIFY | crates/kira/src/modulator.rs | +8 | 5 | `waits_on_clock` provided method |
| MODIFY | crates/kira/src/modulator/tweener.rs | +25 | 18 | frame start, dependency |
| MODIFY | crates/kira/src/modulator/lfo.rs | +8 | 6 | dependency from its parameters |
| MODIFY | crates/kira/src/backend/renderer.rs | +15 | 10 | buffer timing, ordered update |
| MODIFY | crates/kira/src/backend/resources.rs | +60 | 45 | dependency-ordered clock/modulator update, `update_one` |
| MODIFY | crates/kira/src/backend/resources/{clocks,modulators,listeners,mixer}.rs | +30 | 20 | timing through Info |
| MODIFY | crates/kira/src/track/sub.rs | +6 | 4 | timing through Info |
| MODIFY | crates/kira/src/playback_state_manager.rs | +5 | 4 | resume keeps today's timing |
| MODIFY | crates/kira/src/sound/static_sound/sound.rs | +20 | 15 | silent prefix |
| MODIFY | crates/kira/src/sound/streaming/sound.rs | +20 | 15 | silent prefix |
| TOTAL | 15-17 files | ~400 | ~290 | |

## 8. Solution outline

- `Clock`: `buffer_start: State` captured at the top of `update`, `advanced: bool` reset per buffer.
- `BufferTiming { frames, frame_dt }` carried by `Info` (Real) ← internal-buffer sentence.
- `Info::clock_crossing(ClockTime) -> Crossing { At(frame), NotYet, Never }` ← clock rule.
- `Info::delay_frames(Duration) -> usize` (ceil, mock = whole update) ← delay rule.
- `StartTime::update_frames(frames, dt, info) -> StartFrame` ← sound sentence.
- `Parameter::update` records `ramp_start` fraction; `interpolated_value` holds then ramps ← tween sentence.
- `Tweener::update` elapsed from the start frame ← tweener sentence.
- `Resources::update_clocks_and_modulators(timing)`: modulators then clocks in key order, deferring
  any item whose dependency (clock a modulator waits on; modulator a clock's speed follows; clock a
  clock's speed tween waits on) has not been updated this buffer; a cycle falls back to key order
  ← clock-follows-modulator sentence + tweener sentence.
- Static/streaming sound: skip frames before the start frame ← sound sentence.
- `PlaybackStateManager` keeps whole-buffer resume ← preservation sentence.

## 9. Test file outline

Path: `crates/kira/tests/start_frames_<hex>.rs` (public API only), 64 Hz output, internal buffer 16.

- Blocks: capture backend (`render(n)` = one backend call); `manager(buffer)`; `data(n)` distinct
  values; `StepDecoder` with a drop signal so streaming tests wait for the whole sound to be buffered;
  `amp(db)`; tolerant slice comparison (1e-5).
- Static clock starts (6): mid-buffer, later buffer, exactly at buffer end, fractional tick, clock
  started this buffer (tick 0), already reached.
- Delays (4): 8 frames, non-integral (0.1 s → frame 7), exactly one buffer, zero.
- Streaming (3): clock mid-buffer, delay, exact boundary.
- Placement (3): sound on a sub-track, on a nested sub-track, one 64-frame backend call = four
  16-frame calls.
- Tweens (6): sound volume tween at a clock time (hold-then-ramp values), delayed tween, tween that
  starts and ends inside one buffer, eased end value, tween starting on a buffer boundary (as today),
  `VolumeControl` effect tween on a sub-track.
- Tweener (4): clock start mid-buffer (values per buffer through a sound volume), delayed, exact
  boundary, tween completing.
- Clock speed (4): speed tween waiting on another clock created before / after it; crossing in a
  buffer where the clock's speed changed; clock speed following a tweener set with an immediate tween.
- Chain (2): clock B follows a tweener waiting on clock A, sound on B; same with the resources created
  in the opposite order.
- Preservation (3): immediate start, immediate tween, `resume_at` still resumes on the buffer.

~35 tests.

## 10. Forced signatures

None new. Tests compile against base public API; on base they run and fail on values.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | Tweener runs before clocks: its crossing is computed from a clock not yet advanced this buffer → one buffer late | F-9 (order) | S2 | render order | #2, #3 | unit tests use static mock clocks and never show it | tweener sentence | `tweener_waiting_on_a_clock_*` |
| 2 | Reordering clocks before modulators makes clocks that follow a modulator lag a buffer | S3 | S3 | preservation | #1 | the obvious fix for #1 | clock-follows-modulator sentence | `clock_following_a_tweener_keeps_same_buffer_speed` |
| 3 | A late pass for waiting tweeners leaves a clock that follows such a tweener one buffer stale | S2 chain | S2 | composition | #1, #2 | the second-obvious fix for #1 | both sentences | `clock_following_a_waiting_tweener_*` |
| 4 | Clocks update in key order: a clock whose speed tween waits on a later-created clock sees it unadvanced | F-9 | A7 | key order | #3 | the same order bug inside one storage | tween sentence (clock speed listed) | `clock_speed_tween_waiting_on_a_later_clock` |
| 5 | Buffer-start state captured per backend call, not per internal buffer | L24 | A9 | noun extent | — | `on_start_processing` looks like the buffer start | "internal buffer" | `one_backend_call_of_four_internal_buffers` |
| 6 | Exact end-of-buffer crossing fires in the current buffer | A9 | A9 | boundary | — | `>=` on the end time | exact-boundary clause | `*_exactly_at_the_end_of_a_buffer` |
| 7 | Sub-track (and effect) `Info` built without buffer timing | F-9 origin | S4 | Info sites | — | five construction sites | "wherever" clause | `sound_on_a_nested_sub_track_*`, effect tween |
| 8 | Mock `Info` compatibility: repo unit tests with static mock clocks and 1-frame updates | S3 | S3 | baseline | — | a new required field or timing | preservation sentence | base mode (94 lib tests) |

## 11b. Cross-product matrix

| | static | streaming | tween | tweener | clock speed |
|---|---|---|---|---|---|
| clock, mid-buffer | ✓ | ✓ | ✓ | ✓ | ✓ (both key orders) |
| clock, exact end | ✓ | ✓ | — | ✓ | — |
| delay | ✓ | ✓ | ✓ | ✓ | — |
| speed changed in that buffer | ✓ | — | — | ✓ | — |
| on a (nested) sub-track | ✓ | — | ✓ (effect) | — | — |
| clock follows a modulator | ✓ (sound on it) | — | — | ✓ (chain) | ✓ |

Unbounded promises: none. Float audit: exact values only on dyadic rates; tolerance 1e-5 on
decibel-derived amplitudes (L59). Throttle audit (L70): streaming tests wait for the decoder to be
dropped (whole sound buffered), no call budgets.

## 12. Tier + category

Olympus; feature-request (the platform now offers only Feature Request / Bugfix / Refactor, and the user prefers Feature Request); title verb "Add".

## 13. Predicted pass rate

15-35%. The kernel and consumers are transcribable; the band rests on #1-#4 (one correct
composition of the update order) and #5-#7 (placement). If 0%: re-eval without the chain cells (#3, #4).

## 14. Quality-gate checklist

- [x] Repo understanding 5/5; Phase 2 run (plus the branch prior-art note); scaffold: kira-loop-crossfade
- [x] Title verb-led; shape named; no new API; canonical form spelled out
- [x] Footprint ~290 meaningful over 15-17 files (to measure)
- [x] Traps on eight axes, #1-#4 interdependent; F-10 matrix filled
- [x] L31 audit: `resume_at` excluded because its repo tests pin today's lag
- [ ] Trap reproduction (write the natural-but-wrong variants against the suite) — at authoring
- [ ] Core-slice precheck (Step 4b) before tweens/tweener/ordering scope

## Why this is not a duplicate

Our kira pick (loop crossfade) is transport / decoder work; this lane shares one file
(`static_sound/sound.rs`) on a different code path. No corpus entry touches clocks, start times or
modulator ordering.

Predicted iteration cycles: 3.
