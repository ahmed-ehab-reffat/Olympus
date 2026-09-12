# UPSTREAM AUDIT - AcademySoftwareFoundation/openexr multipart Image I/O

Audit date: 2026-08-11. Frozen pin:
`c101ab742a9e93c8c9c6f1781055e938cc160305`.

All-state issue and pull-request searches covered `multipart ImageIO`,
`ImfImageIO multipart`, high-level multipart load/save, image collections, and
flat/deep/tiled combinations. Fetched refs, the 4,212-commit local history,
source, tests, documentation, release notes, and recent branches were searched.

No exact C++ `OpenEXRUtil` owner or implementation was found. Merged PR #2148
adds Python multipart wrappers; it does not add a C++ collection operation or
change `ImfImageIO.cpp`'s single-image contract.

PR #1245, PR #2036, and issue #1721 concern chunk-table reconstruction,
recovery, and raw copying. Those seams are excluded; this problem operates on
decoded high-level `Image` objects.

Verdict: `proceed`. Re-run the search if the repository pin changes.

## Revision v9 local ownership check

The fixed-pin source and history contain the four public `copyPixels()` part-family pairs and the `exrmultipart` tool's pure copy/combine dispatch. That makes a plain high-level copy wrapper existing prior art and unsuitable as a difficulty redesign. No C++ OpenEXRUtil API at this pin combines structural preservation of untouched parts with high-level `Image` replacement encoding in one multipart output. Revision v9 uses that hybrid boundary and leaves the existing pure-copy behavior as repository grounding rather than claiming it as new work.

The repository pin has not changed, so the earlier all-state issue, pull-request, branch, and history search remains the upstream ownership verdict. Revision v9 does not revive the excluded chunk-table recovery task; its unreadable untouched-part rule is an externally observable preservation property of the new hybrid operation.
