# DESIGN.md — kira-loop-crossfade

## 1. Title

Add crossfaded loop regions to static and streaming sounds

## 2. Shape classification

- Shape: O-Pipeline-hard with an S5 dual-path core (SHAPES.md § Pattern 11): one rule on the shared `Transport` realised by two playback paths with different machinery (in-memory frames through a resampler; a decoder thread feeding a ring buffer), plus a third realisation that pre-renders the same rule into new sound data.
- Pass rate target: 25-40%.
- Best agent: Orion.
- Dominant verdict: MISSED_REQUIREMENT (streaming path, reverse polarity) with REGRESSION on the existing loop tests when the wrap arithmetic is changed for the L = 0 case.
- Solver/our LOC ratio: ~1.3x.

## Phase 1 — Repo understanding

**Architecture.** kira is a game-audio engine. `AudioManager<B: Backend>` owns a `Renderer` that mixes `Track`s; the `MockBackend` (and any user `Backend`) drives `Renderer::on_start_processing` / `process` by hand, so playback is deterministic and frame-exact in tests. Sounds implement `Sound { process(out, dt, info), on_start_processing, finished }`. Two sound kinds share one `Transport` (`sound/transport.rs`: `position`, `loop_region: Option<(usize, usize)>` with exclusive end, `increment_position` / `decrement_position` / `seek_to` doing the loop wrap). `StaticSound` (`sound/static_sound/sound.rs`) reads `frames: Arc<[Frame]>` through `frame_at_index(pos, frames, slice)`, pushes each source frame into a 4-frame cubic `Resampler`, and advances by `sample_rate * |playback_rate| * dt` per output frame; it can play backwards (`reverse` setting XOR negative rate). `StreamingSound` (`sound/streaming/sound.rs`) only consumes `TimestampedFrame { frame, index }` from an `rtrb` ring buffer filled by `DecodeScheduler` (`streaming/sound/decode_scheduler.rs`) on its own thread; the scheduler owns the `Transport`, calls `Decoder::decode()` for sequential 3-frame packets in the mock (real decoders: symphonia packets) and `Decoder::seek(index)` only when the wanted index is behind the decoder cursor (`frame_at_index`); after a loop wrap the position drops below the cursor so exactly one seek happens per pass. Streaming cannot play backwards (`playback_rate.max(0.0)`). Settings are consuming builders (`loop_region(impl IntoOptionalRegion)`, `fade_in_tween(impl Into<Option<Tween>>)`); handles send commands through `command_writers_and_readers!` pairs read at `on_start_processing` (static) or in `DecodeScheduler::run` (streaming, via `DecodeSchedulerCommandReaders`). `Decoder` is a public trait (users write their own, issue #40). Frames are clamped to [-1, 1] by the renderer.

**Subsystems.** (1) `sound/transport.rs` shared wrap arithmetic. (2) `sound/static_sound/*` data, settings, handle, sound, resampler. (3) `sound/streaming/*` data, settings, handle, sound, decode scheduler, decoders. (4) `command.rs` + per-sound command sets. (5) `backend/*`, `manager.rs`, `track/*` (untouched).

**High-entanglement zones.** The `Transport` (three wrap sites, used by both sound kinds); the static `push_frame_to_resampler` / `update_position` pair (frame content vs. position advance); the scheduler's `frame_at_index` cursor discipline (a backward index forces a decoder seek, a forward one forces sequential decoding of everything in between); the command plumbing that exists twice (static readers in the sound, streaming readers split between the sound and the scheduler).

**Tests.** Inline `#[cfg(test)] mod test` files next to each implementation (`static_sound/sound/test.rs` 24, `streaming/sound/test.rs` 25, `transport/test.rs` 7, others), frame-exact `assert_eq!` on `process_one` with `MockInfoBuilder`, sample rate 1 so one frame per second, fixtures `Frame::from_mono(i)`. `split()` and the scheduler are crate-private, so the new test file (`crates/kira/tests/`) goes through the public API: a test-side `Backend` that keeps the `Renderer` and captures interleaved `f32` output, `AudioManager::play`, handles, and a test-side `Decoder` that records every `seek` and `decode`. Template: `crates/kira/tests/change_sample_rate.rs` (public-API integration test).

## Phase 2 — Existing-PR + publicly-solved check

Canonical org `tesselode/kira` (no redirect). Searched 2026-09-15, PRs and issues, all states: `crossfade`, `gapless`, `loop fade`, `fade loop`, `loop region`, `seamless`; bodies of #118, #119, #97, #112, #102, #138 read.

- #118 "Fade in/out when looping" (2025-01, open): maintainer: "What kind of API do you have in mind?" No design, no PR.
- #119 gapless looping (c11): clicks at the seam, maintainer attributes them to data discontinuity; no design.
- #102 (closed): loop regions are relative to the slice (documented semantics, kept).
- #34 (closed, old): loop region changes during playback, implemented (`set_loop_region`).
- No PR in any state mentions crossfading; open PRs #115 (Doppler) and #156 (join on drop) touch `streaming/sound.rs` for unrelated capabilities.
- No external implementation linked anywhere. Nothing in the corpus touches kira or loop crossfades; `rejected/fundsp-feedback-edge` is the nearest audio-domain case and its death cause (an in-repo oracle unit) does not apply: kira has no component that reads two positions.

## Phase 3 — Candidates

| Candidate | One-line behavior | Shape | Files | Raw | Meaningful | Predicted | Verdict | Reject? |
|---|---|---|---|---|---|---|---|---|
| A. Crossfaded loop regions (this pick) | length + easing on the loop; blend the last L frames before the wrap with the L frames after it, wrap lands past them; static, streaming (decoder cursor discipline), reverse, rate, seeks, live changes, baked pre-render | O-Pipeline-hard / S5 | 12 | ~330 | ~240 | 30-45% | MISSED_REQ | keep |
| B. Audio events (#97) | end/loop/start events delivered to handles | O-Composite | 8 | ~250 | ~170 | 50%+ | wiring | REJECT: derivable wiring, no wrong obvious impl |
| C. stop_at (#150) | end position for playback | C | 4 | ~80 | ~60 | 70% | trivial | REJECT: `region`/slice already covers it (maintainer) |
| D. Tween by amplitude (#114) | linear-amplitude volume tweens | A2 | 3 | ~90 | ~60 | 60% | trivial | REJECT: one conversion helper |
| E. Phase vocoder (#90) | pitch shift without speed change | O-Algorithm | 4 | ~400 | ~300 | 10-20% | Wrong Logic | REJECT: famous DSP algorithm, numeric tolerance walls, no exact oracle |
| F. Doppler | listener-relative pitch | — | — | — | — | — | — | REJECT: open PR #115 |

Death-class guard on A: not one guard at many sites; not a single-subsystem transform (transport + two playback paths + scheduler + baked data + settings/handles/commands x2); the hardness does not rest on withholding (every rule is stated; the walls are the second playback path's cursor discipline, the reverse polarity of the window, the chunk-straddling blend, and the wrap target that must not change when L = 0); not a port (no library defines "loop crossfade" semantics; the weight ramp, the skipped head and the seek discipline are kira's); survives full statement because the difficulty is machinery.

Arsenal: lead **S5** (dual-path consistency: the obvious streaming implementation calls `frame_at_index` for every head frame, which seeks the decoder backwards and then decodes the whole loop forward again for every blended frame; the contract states what a user `Decoder` observes, so the wrong path is detectable), **S3** (existing loop tests are the discriminator for the L = 0 wrap arithmetic), **A8** (reverse polarity of the window and the wrap target), **A9** (exact-fit: agents self-test with a fade that ends on a chunk boundary), **F-10** cells, **F-16** (setter shape inferable from `fade_in_tween`).

## 3. Public API surface

- `LoopCrossfade { pub duration: PlaybackPosition, pub easing: Easing }` in `kira::sound`, with `Default` (zero, linear); `From<PlaybackPosition>` and `From<f64>` (seconds) build a linear crossfade.
- `StaticSoundSettings.loop_crossfade: LoopCrossfade` + builder `loop_crossfade(self, impl Into<LoopCrossfade>)`; same on `StreamingSoundSettings`.
- `StaticSoundHandle::set_loop_crossfade(&mut self, impl Into<LoopCrossfade>)`; same on `StreamingSoundHandle` (command, applied at the next processing pass / scheduler step).
- `StaticSoundData::bake_loop_crossfade(&self) -> StaticSoundData`: new data whose frames are the loop region already blended and shortened, with `loop_region` covering the new loop, `loop_crossfade` zero, and the slice resolved.
- Transport rule (internal but observable): with crossfade length L in frames, the wrap length is the loop length minus L.

## 4. Canonical output form

- L = crossfade duration in frames (`PlaybackPosition::into_samples`, rounding seconds). If there is no loop region, or L = 0, playback is byte-identical to today.
- Clamp: L > floor(loop_len / 2) becomes floor(loop_len / 2).
- Window: the last L frames the playhead visits before it wraps. Forward: indices `loop_end - L + k`, k = 0..L-1, paired with head `loop_start + k`. Backward (reverse XOR negative rate): indices `loop_start + L - 1 - k` paired with `loop_end - 1 - k`.
- Weight: `w_k = easing(k / L)` computed in f64 then cast to f32; output source frame = `tail * (1 - w) + head * w` (Frame arithmetic in f32).
- Wrap target: forward wrap lands on `loop_start + L`; backward wrap lands on `loop_end - L - 1`. Equivalently the wrap subtracts `loop_len - L`.
- Blending happens on source frames before resampling (static) / before the ring buffer (streaming), so playback rate and pitch apply to the blended frame.
- Explicit seeks land where asked, wrapping past loop bounds by whole loop lengths exactly as today; a seek into the window blends from that frame's own weight.
- Loop region or crossfade changed through the handle: applies from the next frame the sound processes (static) or the next frame the scheduler decodes (streaming); weights follow the new region.
- `EndOfAudio` end = number of frames of the (sliced) sound. Slices: all indices relative to the slice.
- `position()` reports the playhead (the tail index), unchanged.
- Streaming decoder discipline: besides the seek it already makes at every wrap, the decoder is asked to seek at most once when playback starts and at most once each time the loop region or crossfade changes; the blend itself never causes a seek; head frames for a pass are decoded right after the wrap, before the tail is decoded.
- `bake_loop_crossfade`: frames outside the loop unchanged; inside, the loop becomes `loop_len - L` frames: the first `loop_len - 2L` are the original frames from `loop_start + L`, then the L blended frames; `loop_region` = `[loop_start, loop_start + loop_len - L)`; `loop_crossfade` = zero; a data without loop region or with L = 0 bakes to an identical copy (settings kept). Playing the baked data equals playing the original with the live crossfade, frame for frame, forward.

## 5. Blind-spot pre-empts

- Parallel API: "the same settings, handle command and rule apply to streaming sounds".
- Stated inverse / preservation: "with no loop region or a zero crossfade, playback is exactly what it is today" (guarded by the repo's own loop tests).
- Ordering: "blended on source frames before resampling".
- Polarity: "the last L frames the playhead visits before it wraps ... in the direction it is moving".
- Codebase-inferable (the one allowed): `Easing`'s formulas (Linear, InPowi(n) = x^n and so on) are the repo's tween easings.

## 6. Description draft (meta.md body)

Add crossfaded loop regions to static and streaming sounds. A loop region today jumps from its last frame straight back to its first, which clicks unless the audio happens to be continuous there.

Give both sound settings a `loop_crossfade`, a `LoopCrossfade` made of a duration (a `PlaybackPosition`, seconds or samples) and an `Easing`, default zero and linear, buildable from a bare duration; both handles get `set_loop_crossfade`. With a crossfade of L frames on a loop region, the last L frames the playhead visits before it wraps are each blended with the frame the same number of steps past the wrap, in the direction the playhead is moving: the k-th such frame, counting from zero, weighs the frame past the wrap by the easing applied to k over L and the frame before the wrap by the rest. Because those frames past the wrap have then been heard, the wrap lands L frames further along than it does today, so every pass around the loop is L frames shorter. A crossfade longer than half the loop region is shortened to half of it. With no loop region or a zero crossfade, playback is exactly what it is today. The blend is applied to source frames, so playback rate and pitch apply to the blended frames. Reversed playback blends the mirror image: the last L frames before it wraps backward with the frames just before the loop end. Explicit seeks land where asked, wrapping past the loop bounds by whole loop lengths as today, and a seek into the fade blends from that frame's own weight. A loop region or crossfade set through a handle applies from the next frame the sound processes, with the weights of the new region. Loop ends at the end of the audio and loops inside a slice follow the same rule relative to the slice.

Streaming sounds obey the same rule from their decoder thread. Besides the seek a streaming sound already makes at every wrap, its decoder is asked to seek at most once when playback starts and at most once each time the loop region or crossfade changes; the crossfade itself never makes it seek, because the frames past the wrap are decoded right after the wrap and kept for the pass.

`bake_loop_crossfade` on static sound data returns new data in which the loop region is already crossfaded and shortened by L: frames outside the loop are unchanged, the loop keeps its original start, its length shrinks by L, the crossfade is reset to zero, and playing the result loops exactly as the original does with the live crossfade. Data without a loop region or with a zero crossfade bakes to an identical copy.

(~390 words)

## 6b. Changes made during authoring (round 1)

- `Transport` public shape unchanged (repo tests build it as a struct literal); crossfade state is a `Crossfade` companion in `transport.rs`; `increment_position_crossfaded` / `decrement_position_crossfaded` take the frame count, the old methods remain for the repo's tests under `#[cfg(test)]`.
- Baked data keeps the frame count; the last L loop frames are replaced, the loop region starts L later with the same end; equivalence is stated for forward play.
- Handle commands and seeks settle a few frames later (the static resampler reads ahead); meta.md states this and the tests assert settled patterns.
- Fixture table: 20 values over /256 with no blend/source coincidences under the weights used.
- Measured: 226 human-effective over 11 files; 32 tests.

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful | Reason |
|---|---|---|---|---|---|
| MODIFY | crates/kira/src/sound/transport.rs | 106 | +45 | 32 | crossfade length, clamp, window lookup, wrap length |
| MODIFY | crates/kira/src/sound.rs | 400 | +45 | 30 | `LoopCrossfade`, conversions, `blend_frames` helper |
| MODIFY | crates/kira/src/sound/static_sound/sound.rs | 300 | +40 | 28 | blended push, direction-aware window, command |
| MODIFY | crates/kira/src/sound/static_sound/settings.rs | 129 | +16 | 10 | field + builder |
| MODIFY | crates/kira/src/sound/static_sound/handle.rs | 330 | +10 | 7 | `set_loop_crossfade` |
| MODIFY | crates/kira/src/sound/static_sound.rs | 60 | +2 | 2 | command pair |
| MODIFY | crates/kira/src/sound/static_sound/data.rs | 420 | +50 | 38 | `bake_loop_crossfade` |
| MODIFY | crates/kira/src/sound/streaming/sound/decode_scheduler.rs | 216 | +70 | 52 | head buffer, wrap-time fetch, blended push, commands |
| MODIFY | crates/kira/src/sound/streaming/settings.rs | 120 | +16 | 10 | field + builder |
| MODIFY | crates/kira/src/sound/streaming/handle.rs | 330 | +10 | 7 | `set_loop_crossfade` |
| MODIFY | crates/kira/src/sound/streaming.rs | 130 | +12 | 9 | scheduler command pair |
| MODIFY | crates/kira/src/sound/streaming/data.rs | 380 | +3 | 2 | pass crossfade to scheduler |

TOTAL ~320 raw / ~225 meaningful across 12 files (Rust brace tax ~30%). Above the 200 floor; the real diff will be measured and the baked path is the buffer.

## 8. Solution outline

- `LoopCrossfade` + `From` impls <- settings sentence
- `Transport::new(..., loop_crossfade)` / `set_loop_crossfade` / `set_loop_region` recompute `loop_crossfade_frames` with the clamp <- clamp sentence
- `Transport::wrap_length()` = loop_len - L, used by increment/decrement <- "wrap lands L further" sentence
- `Transport::crossfade_pair(position, backwards) -> Option<(usize head_index, f64 progress)>` <- window sentence (both polarities)
- `blend_frames(tail, head, weight)` <- weight sentence
- static `push_frame_to_resampler`: frame = blend when `crossfade_pair` says so <- "applied to source frames"
- static `read_commands`: `set_loop_crossfade` <- handle sentence
- scheduler: `head_frames: Vec<Frame>`, `refill_head()` after wrap / seek / settings change, blended push in `run` <- streaming paragraph
- `StaticSoundData::bake_loop_crossfade` <- baking paragraph

No fixpoint loops.

## 9. Test file outline

Path: `crates/kira/tests/loop_crossfade_<hex>.rs` (public API only).

Block 1: imports. Block 2: builders: `CaptureBackend` (implements `Backend`, keeps the `Renderer`, `render(n) -> Vec<Frame>`), `manager()` with sample rate 1 and internal buffer 1, `mono(values)` static data with frames `v/16`, `RecordingDecoder` (records `Seek(i)` / `Decode`), `play_and_collect`, `expected_crossfade(frames, start, end, L, easing_fn)` computing the rule independently. Block 3: `assert_frames(actual, expected)` exact on mono left channel.
Block 4 buckets:
- Static forward (8): linear L = 4 on a 10-frame loop, values exact; wrap lands at start + L; second pass identical; L = 0 identical to base; no loop region ignores crossfade; clamp beyond half; `EndOfAudio` loop; slice-relative.
- Easing (2): `InPowi(2)` weights; `OutPowi(2)`.
- Reverse (3): reverse setting; negative playback rate; reverse with wrap target end - L - 1.
- Rate (2): rate 2 skips through the blended frames; blended values equal the rule at the visited indices.
- Seeks and live changes (5): seek into the window; seek past the loop end wraps by whole loop lengths; `set_loop_crossfade` mid-pass; `set_loop_region` mid-pass with new weights; setting crossfade then removing loop region.
- Streaming (7): forward blend equals the static rule; second pass; `set_loop_crossfade` through the handle; decoder seeks once per wrap over 5 passes; at most one extra seek at start (start inside loop after head); change of region counts one extra; no seek attributable to the blend (seek count equals passes + starts).
- Bake (5): baked frames equal the rule; baked loop region and zero crossfade; playing baked == playing live, forward, three passes; no-loop bakes identical; L = 0 bakes identical; slice resolved.
- Exact-fit (2): fade straddling the internal buffer boundary (buffer 3, L = 4); fade equal to buffer.

~34 tests.

## 10. Forced signatures

- `LoopCrossfade: Debug + Clone + Copy + PartialEq + Default`; `impl From<PlaybackPosition>`, `impl From<f64>`, `impl From<Duration>` (mirrors `PlaybackPosition`'s existing `From<f64>`).
- builders `loop_crossfade(self, impl Into<LoopCrossfade>) -> Self` on both settings; handles `set_loop_crossfade(&mut self, impl Into<LoopCrossfade>)`.
- `bake_loop_crossfade(&self) -> StaticSoundData`.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | Streaming cursor discipline: head frames fetched by `frame_at_index` inside the window seek backwards and re-decode the loop forward every frame | S5 (candidate new pattern: decoder-observable cursor) | S5 | streaming machinery | #4 (head must be refetched on region change) | the helper exists and gives correct frames | "the decoder is asked to seek at most once when playback starts ... the crossfade itself never makes it seek" | `streaming_decoder_seeks_once_per_wrap` |
| 2 | Wrap target: shortening the wrap by L must not touch the L = 0 path or the seek wrap | S3 (existing `loops_forward`, `loop_wrapping`, `seek_loop_wrapping`) | S3 | transport arithmetic | #3 | agents change `increment_position` for all cases or also `seek_to` | "wrapping past the loop bounds by whole loop lengths as today" | base suite + `seek_past_end_wraps_by_loop_length` |
| 3 | Reverse polarity: window and wrap target mirror | A8 / F-10 | A8 | direction | #2 | forward-only window test passes the reverse test only if mirrored | "in the direction the playhead is moving ... mirror image" | `reverse_blends_mirror_window` |
| 4 | Live change re-derives the window and refetches the head | F-14 | S4 | command timing | #1 | agents compute the head once at construction | "applies from the next frame ... with the weights of the new region" | `set_loop_region_mid_pass_uses_new_weights` |
| 5 | Chunk straddle: the blend is per source frame, not per output chunk | A9 | A9 | buffer geometry | #6 | agents blend per `process` call or align to the chunk | "applied to source frames" | `fade_straddles_internal_buffer` |
| 6 | Baked equals live: the baked loop must shorten and keep the start | F-20 style consistency | S2 | pre-render path | #2, #5 | agents bake the full loop with blended tail but keep the length | bake paragraph | `baked_data_plays_like_live_crossfade` |

Six axes; #1-#4 share the transport/head kernel; #6 composes #2 and #5.

## 11b. Cross-product matrix

| | forward | backward |
|---|---|---|
| **static, rate 1** | `static_linear_blend` | `reverse_blends_mirror_window` |
| **static, rate 2 / -2** | `rate_two_visits_blended_frames` | `negative_rate_blends_mirror` |
| **streaming** | `streaming_blend_matches_rule` | n/a (unsupported, unchanged) |
| **baked** | `baked_data_plays_like_live_crossfade` | `baked_data_reversed_matches_live_reverse` |
| **live change** | `set_loop_crossfade_mid_pass` | `set_loop_region_mid_pass_reverse` |

Scope audit: L is per sound; clamp per region; weights per frame. Format-noun: "loop region" = [start, end) exclusive end as documented; "wrap" = the transport's jump. Unbounded promises: none (seek counts are exact, small numbers).

## 12. Tier + category

Olympus, feature-request (Add), Good if 20-40%.

## 13. Predicted pass rate

30-45%. Static rule is transcribable; the band is carried by the streaming decoder discipline, the reverse mirror, the live-change refetch and the baked consistency.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5; Phase 2 clean; scaffold `crates/kira/tests/change_sample_rate.rs` + rocketpy meta side by side
- [x] Title, shape, API surface, canonical form, one codebase-inferable (Easing formulas)
- [x] Description ~390 words, plain prose
- [x] Footprint ~225 meaningful over 12 files
- [x] Helpers per sentence; no fixpoint
- [x] Test outline 4 blocks, ~34 tests, off-diagonal cells listed
- [x] Forced signatures documented
- [x] Six traps, six axes, F-ids or flagged candidate; F-16 audit (setter shape stated); F-20 audit (L = 0 old behaviour guarded both ways); F-21/23/24/25 n/a
- [x] Representation pins: frames compared exactly after clamp-safe fixtures (|v| < 1)
- [x] Qualifier attachment checked (each sentence one subject)
- [x] Stated-but-untested: every sentence has a test; Wrong Logic < 25%; category matches

## Why this is not a duplicate

Nearest corpus items: rejected fundsp-feedback-edge (audio graph, oracle unit) and go-workflows-channel-drain (F-20 sibling API). Different repo, different domain object (a loop transport under two decoders), different kernel. No corpus entry touches kira, loops or crossfades.

Predicted iteration cycles: 2.
