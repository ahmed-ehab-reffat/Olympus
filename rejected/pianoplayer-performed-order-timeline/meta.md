---
Repository: https://github.com/marcomusy/pianoplayer
Issue: N/A
Commit: 6fb0e2114d7b21f75c0be5208172e1243a57323e
Language: Python
Category: feature-request
Title: Add performed-order reading of repeats and jumps to the score reader
---

# Add performed-order reading of repeats and jumps to the score reader

We want pianoplayer to finger a MusicXML score in the order it is played. Today the reader ignores repeats and jumps, so a repeated passage is fingered once.

We'll add an `unfold_repeats` option to `reader`, `AnnotateOptions`, `run_annotate` and the CLI (`--unfold-repeats`). With it, a backward repeat returns to the last forward repeat or to the end of the previous repeated section, and the section plays `times` times (two by default). A numbered ending is played on the passes it lists, and the pass count starts over in each repeated section. The `<sound>` marks `dacapo` and `dalsegno` jump to the start or to the matching `segno` at the end of their measure. After that jump, repeats are not taken again, endings closed by a backward repeat are skipped, `fine` ends the piece and `tocoda` goes to the matching `coda`.

Times and durations then become seconds. The tempo comes from `<sound tempo>` in quarter notes per minute, 120 before any mark, and a mark holds from where it is played. Every pass is read like a written measure, with the chord stagger still in seconds. `Hand.generate` applies its measure window on every pass, and writing the fingering back gives each written note the finger from its first performance. Without the option nothing changes.
