---
Repository: https://github.com/tesselode/kira
Issue: N/A
Commit: 3d6421e37b8bc0194cfa9fdf840d2eb206fe7270
Language: Rust
Category: feature-request
Title: Add frame-accurate start times to static and streaming sounds
---

# Add frame-accurate start times to static and streaming sounds

Add frame-accurate start times to static and streaming sounds, so that a sound begins on the exact frame where its clock time or delay is reached. Today the renderer checks a start time once per internal buffer and, as soon as it is reached, plays the whole buffer, so a sound can begin up to an internal buffer early.

Within one internal buffer (the `internal_buffer_size` chunks the renderer processes, however many of them one backend call covers), a clock's time moves in equal steps per frame from its time at the start of the buffer to its time at the end. A clock time is reached on the first frame that begins at or after that time while the clock is ticking, so a time reached exactly at the end of a buffer is reached on the first frame of the next one. A delay is reached on the first frame that begins at least that long after the first frame the sound is processed.

A sound whose start time is reached partway through a buffer is silent before that frame and, from it, plays exactly what it would have played had it started on that frame. This holds for sounds on the main track and on sub-tracks at any depth. A start time already reached on the first frame of a buffer behaves exactly as it does today, and `resume_at` keeps its current timing.
