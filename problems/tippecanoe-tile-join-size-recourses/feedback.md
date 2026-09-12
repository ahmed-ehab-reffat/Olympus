# feedback.md — tippecanoe-tile-join-size-recourses

## Strategic summary

Give `tile-join` the tile-size recourses `tippecanoe` has. Today an over-limit merged tile is
dropped from the output entirely (`tile-join.cpp:884`) while the tileset metadata keeps advertising
it. The pick adds `-M`/`--maximum-tile-bytes` and `--drop-smallest-as-needed`, and makes the
tileset's own books (strategies, tilestats, zoom ranges, bounds) describe what was produced.

Shape: O-Composite-add · S-G degradation fused with S-F accounting. Target 15-25%.

## Status

| Stage | State |
|---|---|
| Repo picked, gates cleared | DONE (`REPO-HUNT-2026-09-12.md`) |
| Gap reproduced on base in the platform image | DONE |
| Docker feasibility built + suite run offline | DONE (61s build, 75s suite, `--network none`) |
| Baseline determinism 3x | DONE (no test flips) |
| Phase 1 repo understanding | DONE |
| Phase 2 existing-PR / publicly-solved | DONE, 0 hits, bodies + comments read, both orgs |
| Spike (thinnest end-to-end) | DONE — built, ran, 161 raw / 102 human-effective |
| DESIGN.md | DONE (14 sections + Phase 5 audit) |
| Dockerfile | DONE — verified non-root incremental rebuild (31s) |
| test.sh + tests | DONE — 15 new tests, 36 base testcases, JUnit valid |
| Reference solution (CORE SLICE) | DONE — 151 human-effective, 3 files |
| Patches | DONE — apply in both orders, ASCII, test.sh mode 100755 |
| Clean-room validation | DONE — see Round 1 |
| **Core-slice precheck (Step 4b)** | **OWED — upload now, before the differentiating scope** |
| Differentiating scope | NOT STARTED, deliberately — gated on the precheck |
| Batch | not run |

## Attempt history

### Round 0 — design (2026-09-12)

- Spike measured 102 human-effective for options + extent + ladder + strategy merge. Remaining
  clusters (pool compaction and tag remap, the booking restructure, zoom/bounds reconciliation)
  put the design at ~300-330. Re-run the hook on the first complete reference BEFORE writing tests.
- The spike exposed the lead trap empirically: dropping features without pruning the layer's
  key/value pools left the tile at 457,530 bytes only after shedding **82,493 of 90,000 features**,
  because `mvt_tile::encode()` writes the whole constant pool regardless of what survives.
- Phase 5 audit found two hidden requirements (under-limit tiles written byte-for-byte;
  `--no-tile-compression` changes the measured size) and both are now stated in the draft.

### Round 1 — core slice built and validated (2026-09-12)

Clean-room in the platform image, pristine base + patches:

| Stage | Result |
|---|---|
| base mode on base | **36/36 pass**, exit 0 |
| new mode on base | **1/15 pass**, exit 1 |
| base mode with solution | **36/36 pass** — no regressions |
| new mode with solution | **15/15 pass** |
| reverse apply order | ok |
| JUnit testcases | base 36 / new 15 |

The one new test that passes on base is `oversized_tile_is_skipped_without_the_option` — the
deliberate baseline-preservation cell flagged in the Phase 5 audit, not a feature test.

**Base regression found and fixed, and kept as trap 6.** The first complete core slice recorded
`tile_size_desired` for every tile it wrote, which injected a `strategies` key into the metadata of
every join and broke the repo's own `tests/raw-tiles/raw-tiles-z67-join.json` at byte 1424. Narrowed
to record only when a reduction actually happened, and to report the PRE-reduction size (matching
`tile.cpp:2892`). Recorded in DESIGN.md as a predicted trap rather than silently fixed (L50).

**The lead trap is measured, not assumed.** Reducing the same 1,001,495-byte tile:
- without pool compaction (the naive implementation): 82,493 of 90,000 features shed
- with compaction: **56,301 shed, 33,699 survive** at 423,278 bytes

A naive implementation keeps ~4.5x fewer features and reports a wildly different
`dropped_as_needed`, because `mvt_tile::encode()` writes a layer's entire key/value pool regardless
of what survives.

## Fix history

| # | Issue | Fix |
|---|---|---|
| 1 | `strategies` written for every tile broke `raw-tiles-z67-join` golden file | record only when `dropped > 0`; report pre-reduction size |
| 2 | `atoll_require` is not linked into tile-join | use `atoll`, matching tile-join's own `atoi` style |
| 3 | `an_emptied_layer_is_not_written` fixture used a budget no tile could reach | size the budget from a wide-layer-only join |
| 4 | `__pycache__` captured into test.patch | `git rm --cached`, regenerate |

## Open questions

- Whether to ship README + regenerated `man/tippecanoe.1`. The repo's CI fails if the man page
  drifts from README, and `go-md2man` is not in the platform image — it has to be generated on the
  host. Decision: yes, generate both, so the reference matches repo convention.
- How many of the ~39 tests pass on base (target: keep the preservation-only cells to a handful).
