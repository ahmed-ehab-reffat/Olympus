# DESIGN.md - pianoplayer-performed-order-timeline

Repo marcomusy/pianoplayer (MIT, Python 3.10+, runtime dep `rich` only). Base
6fb0e2114d7b21f75c0be5208172e1243a57323e (master HEAD 2026-06-22; unchanged on 2026-10-06).

## Phase 1 - repo understanding

Architecture: a score file is parsed by a native MusicXML reader (`musicxml_io.parse_musicxml`)
into `PartInfo` objects holding a flat list of `EventInfo` (note/chord/rest with a written offset in
quarter lengths and the live `ET.Element`s). `scorereader.reader` turns one part into an `INote`
sequence through `noteseq_from_part`, which expands chords with a seconds stagger and then runs
`_mark_colliding_notes_as_chords` (multi-voice collisions become synthetic chords keyed on measure,
staff and the SOURCE event offset). `core.load_note_sequences` routes parts/staves to the right and
left hand, `hand.Hand.generate` runs the 9-note look-ahead optimizer over a measure window, and
`core.write_annotated_output` writes either PIG text (times from `INote.time`) or MusicXML, where
`annotate_part_with_fingering` walks the written events and consumes the hand sequence by index.

Subsystems and boundaries:
1. MusicXML reader (`musicxml_io.parse_musicxml`, `EventInfo`/`PartInfo`) - XML to events.
2. Note-sequence builder (`noteseq_from_part`, `_mark_colliding_notes_as_chords`, `scorereader`).
3. Routing / pipeline (`core.load_note_sequences`, `_resolve_musicxml_routing`, `annotate`).
4. Fingering optimizer (`hand.Hand.generate`, `optimize_seq`, chord consistency).
5. Writers (`annotate_part_with_fingering`, `clear_part_fingering`, PIG writer, cost CSV).

High-entanglement zones: (a) event offset is read by the collision helper, the duplicate filter and
the INote builder; (b) the annotator must stay index-consistent with `noteseq_from_part`'s skip rules;
(c) `Hand.generate`'s measure window assumes measure numbers grow along the sequence.

Tests: pytest under `tests/`, file-local MusicXML strings written to `tmp_path`
(template: `tests/test_annotate_bounds.py`, `tests/test_audit_regressions.py`). 46 tests, ~30 s,
3 identical local runs.

## Phase 2 - exclusivity / publicly-solved

Canonical org = marcomusy/pianoplayer (no move). PR+issue searches (all states): repeat, volta,
unfold, ending, da capo, segno, coda, tempo, seconds, performed order, playback, expand. Hits:
#8 "Fingering with voltas" (CLOSED 2018, maintainer: "this would actually be a bit difficult to
implement" - not a decline), #20 (repeated chords should reuse fingers, unrelated), #44 "Timing
information units?" (OPEN, uncommented). No PR ever touched repeats or tempo (10 PRs total).
Side branches: `Pedro/fixing-chords` (2021, music21 era, unmerged, no PR) uses music21
`secondsMap` + metronome propagation for seconds; different architecture (music21 was removed in the
2026 rewrite) and not the central capability. `git log -S` over all refs: no repeat expansion ever.
SIX-CHECK 5: base == HEAD, no commits since. SIX-CHECK 6: base reads a repeated score straight through
(probe: 3 notes instead of 5).

Publicly-solved risk (MEDIUM, logged for the precheck): music21 `repeat.Expander` and MuseScore
playback implement the play-order step (~50 of the reference's lines). The integration (fingering per
pass, write-back by element identity, measure window, tempo map, collision helper) has no crib.

## Phase 3 - candidates (lane fixed by the hunt; alternatives already ruled out in the dossier)

| Candidate | Verdict |
|---|---|
| R performed-order timeline + tempo map + write-back | PICK (219 written spike) |
| G grace notes | absorption < 200 |
| M MIDI output (#34) | absorption < 200, claimed in 2021 |
| V voice routing | maintainer fixed 2026-06-21 |
| T tempo alone | only as R's second lever |

Step A guard: not a uniform wrap (four consumers each need a different change), not a single
subsystem (reader, optimizer, writer), the hardness survives a full contract (integration walls),
Guard 4 MEDIUM (MusicXML repeat semantics are public; weight tests on integration).

## 1. Title
Add performed-order reading of repeats and jumps to the score reader

## 2. Shape
O-Pipeline-easy / Mars D-new hybrid: new reader mode + cascading consumers. Predicted dominant verdict
MISSED_REQUIREMENT (one consumer left on written order) and REGRESSION (annotator rewrite breaks the
duck-typed short-sequence test).

## 3. Public API surface
- `reader(score, beam=0, chord_note_stagger_s=0.05, unfold_repeats=False)` - performed-order INotes.
- `AnnotateOptions.unfold_repeats` / `run_annotate(..., unfold_repeats=False)` / CLI `--unfold-repeats`.
- `annotate_part_with_fingering(part, seq, ...)` accepts a performed-order sequence.
- `Hand.generate(start_measure, nmeasures)` windows by written measure number on every pass.

## 4. Canonical output form
- Sequence order: performed order; within a pass, the order the reader uses today.
- Times and durations: seconds when unfolding (tempo = `<sound tempo>` quarter notes per minute,
  120 until the first mark, a mark applies from where it is played, every pass).
- `INote.measure` keeps the written measure number.
- Write-back: each written note gets the finger of its first performed occurrence.

## 5. Blind-spot pre-empts
- pipeline placement: "every pass is read like a written measure" (collisions/chords per pass).
- compound order: "a jump happens at the end of the measure that holds it".
- stated inverse: without the option nothing changes.

## 6. Description draft
See `meta.md` (draft, ~200 words). Rules: repeats with times; numbered endings by pass, counting
restarts per repeated section; D.C./D.S. to segno, repeats not retaken after the jump (the last
ending is played); Fine and To Coda apply only after a jump; seconds + tempo map; stagger stays in
seconds; measure window on every pass; first-pass write-back; option off = unchanged.

## 7. File footprint (measured, not sketched)
| Action | Path | Raw | human-eff |
|---|---|---|---|
| MODIFY | pianoplayer/musicxml_io.py | ~220 | ~200 |
| MODIFY | pianoplayer/hand.py | 4 | 4 |
| MODIFY | pianoplayer/scorereader.py | 4 | 4 |
| MODIFY | pianoplayer/core.py | 6 | 6 |
| MODIFY | pianoplayer/models.py | 2 | 2 |
| MODIFY | pianoplayer/cli.py | 5 | 4 |
Hunter spike: 219 human-eff / 238 raw / padding-floor 157 / 6 files (hook, 2026-10-06 re-run).
Slice reference after removing the sketch's re-indent, its dead `back` flag and its wrong tie rule,
and adding the legacy annotator fallback: **207 human-eff / 225 raw / padding-floor 156 / 6 files**.
Leanest plausible passer (no D.S./Coda arms, no tempo points per pass): ~150-165.

## 8. Solution outline
- `MeasureInfo` per written measure: start/end, forward, backward times, ending numbers, whether the
  ending is closed by a backward repeat, segno/coda/tocoda/dalsegno/dacapo/fine, tempo points.
- `performance_order(measures)` - pass counter per repeat section, ending filter, jump state.
- `unfold_part(part)` - copies events per played measure with shifted offsets, builds the tempo map
  on the performed timeline, converts offsets/durations to seconds piecewise.
- `noteseq_from_part` records `INote.element`; the annotator maps by element identity (first pass),
  falling back to the index walk for sequences that carry no elements (keeps base behaviour).
- `Hand.generate`: out-of-window notes are skipped, not a `break`.

## 9. Test outline
New file `tests/test_performed_order_<hex>.py`, file-local MusicXML builder helpers.
Buckets: repeats (plain, times=3, implicit start), endings (1/2, "1, 2"/3, two sections), jumps
(D.C. al Fine, D.S. al Coda, repeats not retaken), tempo (default, change, change before a repeat,
mid-note), chords/collisions per pass, write-back identity, measure window, CLI/core end to end.

## 10. Forced kwargs
`reader(..., unfold_repeats=True)` keyword; `AnnotateOptions(unfold_repeats=...)` field
(from_namespace copies by field name, so the field is forced for the CLI path).

## 11. Trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Test |
|---|---|---|---|---|---|---|
| 1 | Collision helper keys on `note21.offset` and rewrites `note.time` from it (musicxml_io.py:544,578): passes sharing the written event merge into one chord | F-9 / F-19 | S3 shared chokepoint | event identity per pass | 2 | chord + voice collision in a repeated measure, per-pass chord ids and times |
| 2 | Seconds applied after the INote stage: stagger scaled, helper rewrites times back to written offsets | F-19 | S4 machinery-riding | time units | 1 | stagger in seconds on pass 2 at tempo 60 |
| 3 | `Hand.generate` `break` (hand.py:461,470) leaves later passes at finger 0 | F-39 | A-tier latent helper bug | optimizer window | 4 | window = measure 1, both passes fingered |
| 4 | Annotator index walk (musicxml_io.py:777-834) writes pass-2 fingers onto later measures; the identity rewrite breaks the base duck-typed short-sequence test | F-9 + F-12 | S3 | write-back | 3 | measure after the repeat keeps its own finger; base `test_annotate_handles_short_hand_sequence` |
| 5 | Ending pass counter not restarted per repeated section; repeat-closed endings after a jump | F-69 | A8 | play order | - | two sections with endings; D.C. through endings |
| 6 | Tempo in effect on pass 2 taken from written order | F-10 cell | S2 | tempo x repeat | 2 | tempo change late in the section, no mark at its start |

## 11b. F-10 matrix (axes: structure {repeat, ending, D.C./D.S.} x consumer {times, chords, window, write-back})
Every off-diagonal cell gets one test in FINISH; the slice covers the diagonal plus write-back x repeat.

## 12. Tier / category
Olympus, feature-request ("Add ...").

## 13. Predicted pass rate
25-45%. Play order is public knowledge; the band rests on traps 1-4 and 6. FINISH must add the F-10
cells and the composition tests (tempo x jump, chord x ending, window x D.C.).

## 14. Quality gate
Phase 1 5/5; exclusivity clean (above); title verb-led; API listed; canonical form stated; LOC
measured at 207 (edge: above the hard 200, just under the 210-220 band the user ruling accepts with
the tempo map as the second lever; FINISH levers: score-level `<sound>` marks across parts ~+15-20,
`time-only` passes ~+10); traps on
different axes with 1-2 and 3-4 interdependent; F-10 matrix planned.

Why not a duplicate: no approved/in-flight problem touches music notation; closest shapes are
riff (regime split) and macs (topology change reaching an estimator).
Predicted iteration cycles: 3.
