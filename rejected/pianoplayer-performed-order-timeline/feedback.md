REJECTED 2026-10-13 at platform review (see the top section). Shelved to rejected/; not a submission.

# pianoplayer-performed-order-timeline - feedback

Repo: marcomusy/pianoplayer (MIT, Python, 892 stars). Base 6fb0e2114d7b21f75c0be5208172e1243a57323e
(master HEAD 2026-06-22; re-checked 2026-10-06: no newer commit on any branch).
Source: hunt #58 RANK 1 (Instructions/repo-hunt-logs/REPO-HUNT-2026-10-05-J.md). Factory MODE=SLICE.
Our submissions on this repo: 0.

## REJECTED 2026-10-13 (platform review, derivative)
- overlap Blocker: 88/206 discounted subject lines (42.7%) align with an older same-repo task's
  repeat-fingering engine and workflow; it "re-delivers the older task's central played-measure
  fingering capability, notwithstanding its additional jump and tempo behavior".
- overlap Medium (distinct): 9/206 (4.4%) note-element mapping vs another foreign task.
- publicly-solved Medium: issue #8 owner comment "this would actually be a bit difficult to
  implement", a historical signal, not a rejection.
- No batch was ever run. Repo marked DO-NOT-PICK; entry in Instructions/TOO-EASY.md.

## Status (2026-10-06, SLICE-READY)
- Lane: `unfold_repeats` reads the score in performed order (backward/forward repeats with `times`,
  numbered endings with the pass count restarting per section, D.C./D.S. to segno, Fine and To Coda
  after the jump, repeats not retaken after it), times in seconds from `<sound tempo>` (120 default,
  a mark holds from where it is played), `Hand.generate` window on every pass, first-pass fingering
  written back by element identity.
- Solution: 207 human-effective (hook), 225 raw, 6 files, padding-floor 156.
  The hunter's sketch measured 219, but ~10 of those lines were a re-indent and it carried two bugs
  (below). The honest reference lands at 207: above the hard 200, a little under the 210-220 band
  the 2026-10-05 ruling accepts. FINISH levers that are real behaviour, not padding: score-level
  navigation/tempo marks shared by every part (two-part piano scores usually carry `<sound>` only in
  the top part; ~+15-20) and `time-only` passes on `<sound>` marks (~+10).
- Tests: 13 new (tests/test_performed_order_9b08e3.py), all fail on base (no `unfold_repeats`).
- meta.md draft: 223 words incl. title (warn zone 201-400). FINISH must trim or accept the warning
  before the first batch.

## Reference bugs found while slicing (L50 candidates for FINISH tests)
1. Hunter sketch rewrote `annotate_part_with_fingering` to identity lookup with `note.element`,
   which raises AttributeError on the duck-typed `SimpleNamespace(fingering=1)` items of base test
   `test_annotate_handles_short_hand_sequence`. Fixed: identity map only when items carry an
   element, index walk otherwise. This is a live S3/F-12 seam for agents.
2. Sketch reset the ending pass counter whenever the previously played measure had endings, which
   also fires right after jumping BACK from a first ending, so `1 2(1st) 1 3(2nd) 4` came out as
   `1 2 1 2 4`. Fixed: reset only when moving forward out of an ending group, and the next backward
   repeat without a forward repeat returns to that point.
3. Sketch's tie-on-jump rule re-attacked tie-stop notes of any measure entered by a jump, which is
   wrong for a second ending entered from the measure that holds the tie start. Dropped (unstated,
   untested; base semantics kept).

## Conservative choices made unattended
- Kept D.C./D.S./Fine/Coda in scope (dropping them puts the lane at ~150-165, under the floor),
  even though they cost description words.
- Seconds only under `unfold_repeats` (base times are quarter lengths and existing optimizer
  regression tests depend on them).
- No docstrings/comments added (repo docstrings most functions; default NONE per CLAUDE.md).
- Dockerfile installs rich/pytest before COPY, then `pip install --no-deps --no-build-isolation -e .`
  (rebuild-check rule: network steps before COPY, no git commands).

## Precheck risks to read the verdict against
- Publicly-solved/sibling crib: music21 `repeat.Expander` (and MuseScore playback) implement the
  play-order step (~50 lines of the reference). The integration (per-pass fingering, write-back by
  identity, window, tempo map on the performed timeline, collision helper per pass) has no crib.
- Unmerged 2021 branch `Pedro/fixing-chords` computes seconds through music21 `secondsMap`
  (old architecture, no PR). Not the central capability.
- #8 "Fingering with voltas" closed 2018 with "a bit difficult to implement" (not a decline).
