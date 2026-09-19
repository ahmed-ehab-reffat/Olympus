# Repo hunt 2026-09-18-C — second lanes in the five newest proven repos; kira RANK 1 (conditional)

Third hunt of the day. The cached band is swept (09-16-B) and the parked leads are spent (09-18-B), so
this pass took Stage 0-bis at its best odds: the five repos whose first pick was approved this week,
each at 1/6 quota, none screened for a second lane since approval. One subagent per repo, shared brief
`worktrees/_hunt/agents/BRIEF-0918-C.md` (adds a self-collision constraint to `BRIEF-0918.md`).

## Result

| Repo | Verdict | Lane / killer | eff |
|---|---|---|---|
| **tesselode/kira** | **RANK 1, conditional** | frame-accurate clock-scheduled starts inside the buffered renderer | ~270-300, 10-11 files |
| ricktu288/ray-optics | fallback, weak-moderate | `convertHandleToModule` emits frame-relative module templates | ~240-270, 4 files |
| onthegomap/planetiler | fallback, weak | direction-aware line merging (#298) | ~130 core; ~250-290 only with source-attribute tracking |
| felt/tippecanoe | dead in practice | overzoom cross-tile feature reassembly sits on maintainer draft PR #551 (mapbox, 2018); ~250 eff | — |
| earwig/mwparserfromhell | DEAD | tokenizer owned by our approved pick; template spacing = wikitextparser `set_arg(preserve_spacing)`; SmartList = open PR #235; round-trip escaping = Parsoid `WikitextEscapeHandlers.php` | — |

Every repo re-checked clean mechanically: CI green on the default branch, zero commits since our
approved base, no new signature accounts. The deaths are all lane-level.

## RANK 1 — tesselode/kira — frame-accurate clock starts (dossier `worktrees/_hunt/agents/kira-0918C.md`)

- **Lane:** clock-scheduled and delayed start times (static + streaming sounds, `resume_at` on sounds and
  sub-tracks, parameter tweens, the `Tweener` modulator) land on the exact frame inside an internal
  buffer instead of snapping to the buffer boundary.
- **Missing algorithm:** the frame within a buffer at which a clock time (ticks + fraction, with a speed
  change possibly scheduled inside the buffer) or a `Delayed` duration is reached, expressed relative to
  the slice a consumer is processing, plus a silent/held stretch before it in every consumer.
- **F2P on base (64 Hz, buffer 16, 8 frames/tick):** starts due at frame 8 play from frame 0; for a
  frame-24 target a volume tween starts at 16 (one buffer early) and a `Tweener` at 32 (one buffer late),
  because modulators update before clocks (`renderer.rs:84-101`). Opposite errors on two surfaces is the
  lead misdirecting trap; sub-track resume mid-buffer (slice origin) is the second.
- **Self-collision:** one shared file with the approved crossfade (`static_sound/sound.rs`), different
  code path, ~5%.
- **Gate 8, verified here:** `changelog.md:119-124` (v0.10, committed 2025-01-04) records dropping
  sample-accurate clocks as a deliberate performance trade-off, then: "I have some ideas for how
  sample-accurate clocks could be implemented within the buffered architecture, so if you find yourself
  needing sample-accurate clocks, let me know!" Welcomed, no design published, no PR. Issues #116 and
  #136 (zero-duration tweens last one buffer, maintainer confirms) are open.

### Risks (the reason it is conditional)

1. **Public prior art in maintainer branches, verified here.** `buffers`, `next-buffers`,
   `buffers-no-modulators` (2024-03, pre-0.10 layout, never PRs) carry commit "save clock info and
   modulator values to buffers": a `BufferedClock` holding one `ClockInfo` per frame. That is the storage
   half of a per-frame design. It has no slice-relative offset, no hold-then-ramp, no ordering fix and no
   track resume. Do not use the per-frame-buffer design for the reference, and keep `.git` remote refs out
   of the Docker context.
2. **Welcomed-lane magnet.** The invitation is 20 months old and in the changelog every author reads;
   "sample-accurate scheduling" is outsider-nameable (Web Audio `start(when)`). Stage 2d reads an old
   invitation as a queue. Phrase meta.md on kira nouns (`ClockTime` ticks + fraction, internal buffer,
   `resume_at`, sub-track, `Tweener`), and run the platform precheck early.
3. **Difficulty.** The crossfade pick's fair suite ran 9/10; transcribable rules pass in this repo. The
   band must come from the ordering, nesting and exact-boundary cells, stated in meta.md but not
   derivable locally. Dyadic rates keep assertions exact.

## Fallbacks

- **ray-optics** (`ray-optics-0918C.md`): conversion is broken on base (`removeObj` rebuilds the handle,
  `indexOf` at `Scene.js:1008` returns -1). Traps: GRIN `origin` is a schema point that `rotate`/`scale`
  never move (F-20), `focalLength`/`fontSize` scaling, TextLabel degree wrap, F-3 split between
  `objIndices` and `controlPoints`. Risks: an agent probing each object's own transform on a clone clears
  every per-type cell at once (chokepoint), and `ModuleObj.js:241-256` promises the feature in a comment.
- **planetiler** (`planetiler-0918C.md`): maintainer-asked (#298, 2022), OpenMapTiles carries a `TODO
  merge preserving oneway`, JTS `LineMerger` has no directed mode. Core absorbs as filters over the
  twin-edge graph (~130 eff); needs a thin spike before any commitment.

## Ledger notes

- mwparserfromhell: the node-tree layer is the only non-tokenizer surface and all three lanes on it are
  dead. Treat the repo as closed for us.
- tippecanoe: merged PR #361 deleted overzoom bins/clip-polygon, `--accumulate-numeric-attributes`, the
  sqlite join and the Felt filter evaluator; re-adding any contradicts a maintainer decision. 40 of 52
  open PRs are the maintainer's.

## Housekeeping

Clones kept (source only, build outputs removed): `worktrees/kira` 14M, `worktrees/ray-optics` 196M,
`worktrees/planetiler` 146M, `worktrees/tippecanoe` 186M, `worktrees/mwparserfromhell` 4.1M. No Docker
prune.

## Addendum — kira RANK 1 killed at the core-slice precheck (same day)

Authoring found a second public maintainer branch (`v0.10-buffered-rewrite`, per-frame clock and
modulator buffers in lockstep); the user chose to continue with mitigations. The core slice (static
and streaming sound starts, 173 eff, 25 tests, Docker-green) went to the platform precheck and came
back **`publicly-solved`, Blocker, unfixable**: kira 0.10 deliberately REMOVED sample-accurate
clock-driven starts (commit 4c29057a, `changelog.md` L102-L124), and the gate treats restoring a
removed capability as prior art regardless of the new mechanism. Corpus overlap was 0/206 lines.

The Stage 2d reading above ("Welcomed, no design published, no PR") was the error: the "let me know"
sits inside the removal paragraph. The skill now checks changelogs for removals before reading them
for invitations; TOO-EASY.md has the death-class row; SATURATED-REPOS.md § B2-KIRA marks kira
DO-NOT-PICK (every surveyed lane dead). Folder: `rejected/kira-frame-accurate-start-times`.

Remaining fallbacks from this hunt: ray-optics (weak-moderate), planetiler (weak, needs a LOC spike).
Check both for removal records before reviving either.

## Addendum 2 — ray-optics fallback killed at the chokepoint spike

Full history has no removal record for the lane (no changelog; `git log` removals are unrelated). The
spike then wrote the shortcut an agent would reach for: probe each bound object's own
`move`/`rotate`/`scale` on a clone and emit frame-relative templates. About 50 lines matched the
Handle exactly on seven object types, including every cell the audit listed as a trap (GRIN origin,
focal length, TextLabel angle wrap and font size, Drawing strokes), under four operation sequences.
This is TOO-EASY's "make X consistent with existing-correct Y" class, and it would also leave the
leanest passer near 100 eff. SATURATED-REPOS § B2-RAYOPTICS. Planetiler remains as a weak fallback
(core ~130 eff, #298 wishlist magnet); recommendation is a fresh hunt instead.
