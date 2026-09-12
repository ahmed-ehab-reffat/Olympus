# REJECTED — publicly-solved (2026-07-29)

**New exclusivity-reject class, not previously catalogued:** maintainer publicly points to a working,
license-compatible EXTERNAL reference implementation (not a PR/issue in the same repo, and not an
in-repo capability) covering the core algorithm.

- Issue #644 comment (nical): "The way this is commonly done is via a simple stroke-to-fill conversion
  routine that is tessellated using the non-zero fill rule to properly handle self-intersections... there
  is a license-compatible implementation of the stroke-to-fill conversion algorithm that you can take
  inspiration from in pathfinder: pcwalton/pathfinder content/src/stroke.rs#L50" — this describes the
  EXACT architecture the submission used (offset geometry -> non-zero-fill tessellate -> dissolve).
- Issue #564 comment (collaborator): "FWIW, tiny-skia-path has a good implementation of this."

**Why the standard exclusivity check (CLAUDE.md HARD RULE) missed this:** that check searches
`gh pr list`/`gh issue list` in the SAME repo for a diff touching the same files. It does not search
issue COMMENT BODIES for pointers to EXTERNAL crates/repos. Both #644 and #564 were read in full during
Stage 1 of the review pass (comments included) and the pathfinder/tiny-skia mentions were VISIBLE in the
output at the time -- they were misread as "prior art the maintainer casually name-drops" rather than
correctly weighted as "the maintainer is handing the solver a working reference implementation,
disqualifying the core-algorithm exclusivity the same way a same-repo PR would."

**New rule for future picks:** when reading issue comments during Stage 1 (already mandatory), treat any
maintainer/collaborator comment linking to an EXTERNAL repo/crate that implements the SAME capability as
a HARD exclusivity blocker, identical in severity to an in-repo PR touching the same files -- not just a
"philosophy" or "namespace" signal. Read every linked external file at the URL given (not just the
comment text) to confirm it actually implements the core algorithm before treating it as safe.

Artifacts kept intact for reference only (not a submission). Full mutation-proofing, orthogonality
analysis, and Docker validation techniques used here remain valid reusable methodology for the next pick.
