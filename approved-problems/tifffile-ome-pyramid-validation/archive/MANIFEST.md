# tifffile OME pyramid validation archive

The operator reported this problem accepted on 2026-08-08. Canonical
submission artifacts and compact design records remain in
`problems/tifffile-ome-pyramid-validation/`; this directory preserves the bulky
solver evidence removed from the active problem folder.

## Raw solver evidence

- Archive: `agent-runs.tar.gz`
- Preserved roots: `agent-runs`, `agent-runs2`, and `agent-runs3`
- Run directories: 29
- Archive members: 260 total, including 228 files
- Exclusions: three disposable `.DS_Store` files
- Compressed size: 4,495,719 bytes
- SHA-256:
  `75e9635db3650e25ef807bcee113a154e8bf9343bef7a0845e1c955bd75230dd`
- Ordered member-list SHA-256:
  `94c89057a288def42741ced82fd0beb8cd0404be82c6753081654d57a04ef239`

The tarball passed `gzip -t`. A disposable full extraction was compared
recursively with all three readable source roots while excluding only
`.DS_Store`; all 228 file members matched. The uploaded `agent-runs.zip`,
`agent-runs2.zip`, and `agent-runs3.zip` bundles each passed `unzip -t` and
matched the corresponding readable directory byte for byte. They were
redundant and are not nested inside the durable archive.

Restore the raw evidence from the Olympus workspace root with:

```sh
tar -xzf archive/tifffile-ome-pyramid-validation/agent-runs.tar.gz \
  -C problems/tifffile-ome-pyramid-validation
```

The compact interpretation and replay results remain in
`problems/tifffile-ome-pyramid-validation/RUNS.md`; restoring raw trajectories
is unnecessary for ordinary problem selection or review.

## Canonical accepted artifacts

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `ab70cb61e377aa8d4b6cc78ac37298c81bf25042d4ba9bac387cd73a15241aeb` |
| `test.patch` | `aa547b84a18d55ea2d5a83a8920729e34aed12ccdda565fdb30de65cdd26ce30` |
| `solution.patch` | `6e23a2ed70b3743acf1bd9390519551ded0a414e4ad8229458dd7920cfd60f11` |
| `solution_approach.md` | `9a2b3b930124804ddeb9bdd5dc0531b08ed3e3c9c3ad87ca0c70af71866165a1` |
| `Dockerfile` | `d7a789bda59cc68257ca0b0f63755c64b8e5128a927e7058960e07677c32e489` |

Closeout changes only status/history records and evidence placement, not these
submission artifacts.

## Cleanup result

After archive and duplicate checks passed, the three raw directories, three
redundant ZIP uploads, and four disposable `.DS_Store` files were moved to:

```text
/Users/andrewemad/.Trash/Olympus-tifffile-ome-pyramid-validation-20260808
```

That move removed 235 files from the active workspace and reduced the live
problem folder from about 49 MB to 276 KB. The Trash copies remain recoverable
until the user empties Trash; `agent-runs.tar.gz` is the durable recovery path
afterward.
