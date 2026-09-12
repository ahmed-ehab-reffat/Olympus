# feedback.md — geo-hausdorff-distance

Olympus, O-Algorithm-correctness. Target ~8-12% pass. Status: DESIGN drafted, pre-eval.

## Attempt history
- R0 (design): meta.md + DESIGN.md drafted. Not yet built/evaluated. Known open risks: LOC floor (need expansion levers 1-3 from DESIGN §8), meta trim to <=200 words.

## SHELVED (under-floor) 2026-07-22
Measured minimal-golden solution = ~49 effective LOC (116 raw, mostly license+doc comments).
Root cause: golang/geo is a mature well-factored port; DirectedHausdorffDistance reduces to one
loop over source vertices reusing NewClosestEdgeQuery + NewMinDistanceToPointTarget + IncludeInteriors.
Cannot reach the 250 effective floor without padding or requiring an unneeded branch-and-bound
optimization (scope creep). Same class as taffy COMPACT-FEATURE (SATURATED-REPOS.md B2).
LESSON: on a mature port, MEASURE minimal-golden LOC by actually sketching+compiling BEFORE
committing to a full build. Estimates (330-390) overshot the real number (49) by ~7x.
