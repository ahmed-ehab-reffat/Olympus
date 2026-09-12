# Solver runs - OpenEXR multipart Image I/O

Revision v17 starts at 0/10. The run-8 batch solved v11.2, so its results are
trajectory and difficulty evidence rather than v17
calibration results.

| Batch | Version solved | Results | Raw production additions | Main architecture |
|---|---|---|---|---|
| `agent-runs1` | v2 | four passes, one verifier mismatch | 503, 526, 531, 547 for passes; 592 for mismatch | direct filename multipart dispatch |
| `agent-runs2` | v4 | five passes | 472, 485, 603, 539, 567 | direct filename dispatch with complete move-only traits |
| `agent-runs3` | v5 | five passes | 622, 590, 629, 509, 560 | filename dispatch and eager all-part load |
| `agent-runs4` | v6 | five passes | 675, 711, 789, 701, 617 | stream-aware dispatch and selected-part decoding |
| `agent-runs5` | v7 | five passes | 665, 538, 668, 563, 695 | direct dispatch with exact named-part selection |
| `agent-runs6` | v8 | five passes | 666, 655, 813, 725, 667 | decoded collection load/save with shared validation |
| `agent-runs7` | v9.1 | four passes, one near-pass | 768--995 in `ImfImageIO.cpp`; 60--74 in `ImfImageIO.h` | hybrid rewrite plus eager complete selected-part decoding |
| `agent-runs8` | v11.2 | two passes; one 12/14 near-pass; one 8/14 and one 5/14 failure | 1,119--1,422 total production lines in the inspected representative patches | bounded four-family readers plus hybrid rewrite; incomplete variants miss deep crop or source/header edges |

## Revision v17 historical replay

The exact v17 verifier gives run-8 solutions 1, 2, 3, and 5 focused scores of
13/14, 14/14, 12/14, and 6/14; all four pass 4/4 existing tests. Every replay
passes the new `RewriteValidation` predicate because each materially different
rewrite plan restricts matches to supported source parts.

The isolated match-before-filter mutant is killed. These four executions are
historical architecture and discriminator controls, not fresh v17 solver
attempts. Calibration starts at 0/10.

## Revision v16 historical replay

The exact v16 verifier gives run-8 solutions 1, 2, 3, and 5 focused scores of
13/14, 14/14, 12/14, and 6/14. All four pass the 4/4 existing lane. Solution 2
is the materially different legitimate architecture; the other failures remain
at public typeless preservation, deep window, or broader image-layout
boundaries.

The new named-typeless replacement probe does not reject solution 2 and kills
the isolated old-reference shortcut. These are historical replay controls, not
fresh v16 attempts. Calibration starts at 0/10.

## Revision v15 historical replay

The exact v15 verifier gives run-8 focused scores of 14/14, 13/14, 12/14, and
6/14 for the four representative trees. The 13/14 implementation is no longer
rejected for returning a raw legacy header; it fails only because its untouched
rewrite output gains a `type`, contrary to the public preservation rule. The
first, near, and broad trees retain their established 4/4 existing result; the
production artifacts did not change.

A separate legitimate architecture that returns the raw singular-reader
header while using the multipart header only for dispatch passes 14/14. These
are fairness and difficulty controls, not fresh v15 attempts. Calibration
starts at 0/10.

## Revision v14 historical replay

Run-8 solution 2 remains 4/4 existing and 14/14 focused against the exact v14
verifier. Former pass 1 remains 4/4 existing but is now 13/14, failing only the
explicit requirement to preserve an untouched typeless legacy header. The
representative near and broad implementations remain 12/14 and 5/14 focused.

The new multi-replacement assertion passes all four replayed architectures that
reach `RewriteParts`; the newly exposed distinction is the legacy producer's
exact header, not a verifier injection issue. These replays are not fresh v14
solver attempts. Calibration starts at 0/10.

## Revision v13 historical replay

The two legitimate run-8 implementations were recomposed from the clean pin
with source-only participant changes followed by the exact v13 verifier. Each
passes 4/4 existing and 14/14 focused tests, including destination preservation
and ripmap rejection. A representative near implementation remains 12/14, and
a broad failure remains 5/14; both still pass the 4/4 existing lane.

These are replay controls, not fresh v13 solver attempts. The changed test and
reference artifacts reset calibration to 0/10.

## Revision v12 historical replay

The two run-8 implementations that passed v11.2 were recomposed from the clean
pin with the final v12 verifier. Each passes 4/4 existing and 14/14 focused
tests, including complete replacement-header fidelity in `RewriteParts`. The
other three already fail public requirements unchanged by v12 and retain their
historical 12/14, 8/14, and 5/14 results.

This keeps a useful two-of-five difficulty signal without carrying those runs
into the revised version. Fresh v12 calibration remains 0/10.

## Revision v11 historical replay

All five run-7 production patches were composed from clean pinned clones with
the final v11 verifier. Every patch passes 4/4 existing tests and fails the
14-identity focused lane at the missing three-argument `loadImagePart()`
overload. The exact replay is therefore 0/5 pass. It is not a fresh calibration
batch and v11 remains 0/10.

The raw trajectories show the shared shortcut targeted by v11: scanline readers
decode the complete header data-window range, tiled readers decode all tiles at
all levels, and deep readers load all sample counts before all samples. The v11
windowed API crosses that architecture with publicly supported bounded reads
and outside-damage isolation.

One initial replay composition was quarantined when archived run 4 attempted to
delete generated bootstrap artifacts absent from the pin. The clean replay used
only participant-owned source changes, matched the evaluator composition
accepted by the environment gate, and restarted all five outcomes from zero.

Every run-6 compact record, patch, log, JUnit report, and trajectory was inspected. The ATIF archives contain four top-level envelopes and the complete tool transcript in the final envelope. They contain 104, 84, 117, 80, and 69 unique tool-call identifiers; these are not treated as platform message counts or strict effective LOC. Total non-build raw additions are 823, 783, 959, 725, and 838 lines.

All five implementations skip unsupported part types and share validation between filename and stream saves, so the two reported findings exposed a reference mismatch and a verifier gap rather than solver failures. More importantly, every implementation eagerly decodes supported source parts and none uses any production `copyPixels()` family. That convergence selected the v9 hybrid rewrite boundary.

The original run-6 platform patches included generated `build-bootstrap` diffs. Those caused an exact composition failure and were quarantined as infrastructure contamination, not behavioral outcomes. Source-only copies under `verify/replays-v9/` inject cleanly against the final verifier. Because the patches do not declare or implement `rewriteImages()`, they are not scored against v9.

No historical result carries into v15 calibration. The next legitimate
evidence is a fresh immutable solver batch, beginning at 0/10.

Revision v11.2 changed description wording only and was the version exercised
by run 8. Revision v12 changes the description and replacement-header oracle,
so the 2/5 run-8 outcome remains historical evidence only.
