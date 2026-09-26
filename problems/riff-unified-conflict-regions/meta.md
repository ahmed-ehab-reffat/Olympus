---
Repository: https://github.com/walles/riff
Issue: N/A
Commit: 62ef8a7371a7823d3ea65542751c6068f591cc6b
Language: Rust
Category: feature-request
Title: Add conflict region highlighting to one-column unified diffs
---

# Add conflict region highlighting to one-column unified diffs

Add conflict region highlighting to riff's ordinary one-column unified diffs. Today riff handles conflict markers only in raw files and combined `diff --cc` output. In a normal diff, such as `git log --remerge-diff`, a marker is just another removed or added line.

A region opens at a removed or added line holding an opening marker: seven or more `<` characters, optionally followed by a space and a label. It then needs an optional base marker made of `|`, a separator made only of `=` and a closing marker made of `>`, in that order, each with the opening marker's diff prefix and character count. The base and closing markers may carry a label too. Marker-like lines with another prefix or count are ordinary content. A block is a run of removed lines followed by added lines, and a region runs from the start of the block holding its opening marker to the end of the block holding its closing marker, so it can continue across hunks. Another opening marker with the same prefix in the block holding a closing marker starts the region's next marker set, with its own marker length. The lines between two sets belong to every side, and to the base when the sets have base markers, and are shown as part of the first side. A set is out of order if it disagrees with the first set on having a base marker.

When the markers are removed lines the region is resolved. Each side, and the base, is made of the removed and context lines between its markers, and the resolution is every added and context line of the region. Each side and the base are compared with the resolution, and the resolution shows every part highlighted in at least one of these comparisons. A base with no lines is not compared. Context lines keep their plain look.

When the markers are added lines the region is unresolved. Each side, and the base, is made of the added and context lines between its markers. Without base lines the first side is compared with the second. With base lines each side is compared with the base, and the base shows what either side removed, or only what the other side removed when one side is empty. Context lines here keep a plain prefix and plain text outside highlighted parts.

Every comparison is riff's usual word refinement over the whole texts, with the differing parts in reverse video. Marker lines are shown in reverse video after their prefix. Lines in no side and no resolution look like removed or added lines with nothing to compare against. Every line, hunk headers included, keeps its text and position. If any marker set of a region is out of order, or still open where the file's diff ends, the whole region is shown exactly as riff shows it today.
