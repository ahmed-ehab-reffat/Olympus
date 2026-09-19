---
Repository: https://github.com/tesselode/kira
Issue: N/A
Commit: 3d6421e37b8bc0194cfa9fdf840d2eb206fe7270
Language: Rust
Category: feature-request
Title: Add crossfaded loop regions to static and streaming sounds
---

# Add crossfaded loop regions to static and streaming sounds

A loop region should be able to fade across its wrap instead of cutting to the first frame. Today it jumps from its last frame straight back to its first, which clicks unless the audio is continuous there.

Give both sound settings a `loop_crossfade`, a `LoopCrossfade` with public `duration` (a `PlaybackPosition`) and `easing` fields. `LoopCrossfade::NONE` is the zero-duration linear crossfade both settings default to. A `LoopCrossfade` converts from a `PlaybackPosition` with linear easing, and from a bare duration in seconds; the `loop_crossfade` builders on both settings types and `set_loop_crossfade` on both handles accept anything that converts into a `LoopCrossfade`.

Take a crossfade of L frames on a loop region. The last L frames the playhead visits before it wraps are blended, in order, with the first L frames past the wrap. For the k-th of them, counting from zero, the frame past the wrap is weighted by the easing applied to k / L and the frame before the wrap by the rest. Those frames past the wrap have now been heard, so the wrap lands L frames further along than it does today and every pass is L frames shorter. A crossfade longer than half the loop region is shortened to half of it.

The blend is applied to source frames, so playback rate and pitch apply to the blended frames. Reversed playback blends the mirror image: the last L frames before it wraps backward are blended with the frames just before the loop end, and it lands L frames before the loop's last frame. Explicit seeks land where asked, wrapping past the loop bounds by whole loop lengths. A seek into the fade blends from that frame's own weight. Loops that end at the end of the audio and loops inside a slice follow the same rule, relative to the slice. A loop region or crossfade set through a handle takes effect within the next few frames, with the new region's weights. For streaming sounds, loop region and crossfade changes take effect after the audio already buffered has played, as seeks do.

Streaming sounds obey the same rule, with two limits on their decoder. It may be asked to seek at most once more than usual when playback starts. After that, every wrap makes exactly the one seek it makes without a crossfade: the frames past the wrap are decoded right after that seek, in order, and kept for the pass.

`bake_loop_crossfade` on static sound data returns new data with the crossfade already applied: the same frames, except that the last L frames of the loop region are replaced by the blended ones; the loop region then starts L frames later with the same end, the crossfade is reset to zero, the slice is resolved into the frames and every other setting is kept, so playing the result forward loops exactly as the original does with the live crossfade. Data without a loop region or with a zero crossfade bakes to an identical copy.
