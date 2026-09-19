# DESIGN.md — oxipng-apng-frame-optimization

Repo oxipng/oxipng (Rust, MIT, ★4.2k), base `36f3ef8aac65ecf1761739ea2f2e530281f1312b` (= master
2026-09-19, v10.2.1). Lane from hunt 2026-09-19-E. Spike on branch `spike` in `worktrees/oxipng`:
323 human-eff / 7 files (hook), all 296 base tests green with `--features sanity-checks`.

## Phase 1 — repo understanding
- **Architecture.** `PngData::from_slice` (png/mod.rs) splits a file into the default image
  (`raw: Arc<PngImage>`, unfiltered bytes + `IhdrData`), compressed APNG `frames: Vec<Frame>` (fcTL
  fields + fdAT bytes) and `aux_chunks` (every other chunk in order, with an empty `IDAT` marker; an
  fcTL that precedes IDAT stays here, so the default image's frame control has a different origin
  from every other frame's). `optimize_png` (lib.rs) runs `preprocess_chunks` (headers.rs, which today
  turns every reduction off when acTL is present), then `optimize_raw` = `perform_reductions`
  (reduction/mod.rs: alpha clean, 16->8, gray, expand, palette, alpha removal, indexed, sorts, depth)
  scored by `Evaluator` (evaluate.rs: filter+deflate each candidate, smallest wins) followed by
  `perform_trials`, then `recompress_frames` re-deflates each fdAT with the main image's filter, and
  `PngData::output` writes IHDR/PLTE/tRNS/aux/IDAT/fcTL+fdAT with renumbered sequence numbers. With
  `sanity-checks`, `validate_output` (sanity_checks.rs) decodes input and output with the `image`
  crate and demands equal frame counts and equal frames.
- **Subsystems:** container parse/write (png/, apng.rs, headers.rs), reductions (reduction/*),
  evaluation (evaluate.rs, lib.rs trials), options/CLI (options.rs, cli.rs, main.rs), validation
  (sanity_checks.rs).
- **Entanglement zones:** (1) `optimize_png` flow, where the default image and the frames are handled
  by different code paths; (2) the shared IHDR/PLTE/tRNS, which every reduction rewrites; (3) the two
  origins of frame control (aux fcTL vs `frames`).
- **Tests:** integration tests in `tests/*.rs` through `optimize` / `optimize_from_memory` plus
  `internal_tests::PngData`; CI runs `cargo nextest run --release --features sanity-checks`.
  Template: `tests/flags.rs` (options with `force: true`, CLI via `CARGO_BIN_EXE_oxipng`).

## Phase 2 — prior art (all run 2026-09-19)
`gh pr list --state all --search apng`: #88/#511/#626/#668/#713 = read/write + fdAT recompression
only. Issue #551 open since 2023-08 (maintainer's 4-stage plan; stages 3 reductions + 4 crop/dedup not
done). Branch `79-APNG-Support` (2018) parse-only. 45 recent forks: none carry APNG reduction work. No
Rust sibling ships APNG optimisation; apngopt (C++) re-chooses dispose/blend per frame, a different
contract from the one below. CHANGELOG: no removal record ("reductions still not supported yet").

## 1. Title
Add joint reductions and frame cropping for animated PNGs

## 2. Shape
O-Pipeline-hard (new pipeline stage + cascading through container, reductions, validator, CLI;
invented kernel). Dominant verdict expected: MISSED_REQUIREMENT / Wrong Logic on the state rules.

## 3. Public API surface
- `Options::frame_reduction: bool` (default `true`, every preset)
- CLI `--nf` (turns it off); existing `--nx` also turns it off
- behaviour of `optimize` / `optimize_from_memory` on APNG input
- `sanity-checks` validation (`internal_tests::validate_output`) accepts merged output and compares
  what is shown and for how long

## 4. Canonical form
- Displayed canvases compared with every fully transparent pixel equal regardless of colour.
- Crop: smallest rectangle inside the frame's region that yields the same displayed canvas AND the
  same canvas for the next frame; dispose/blend kept; first animation frame never cropped; a frame
  needing no pixel but not mergeable becomes 1x1 inside its region.
- Merge: frame k folds into the previous kept frame iff dropping it and adding its delay changes
  neither what is displayed nor what the next frame is drawn over. Delays added exactly, den 0 = 100;
  if the reduced sum does not fit u16/u16 the frame is kept. acTL num_frames rewritten, num_plays kept.
- Reductions: decided once for default image + every written frame (after crop/merge); interlacing
  kept.

## 5. Blind-spot pre-empts
compound-order ("after cropping and merging"), falsy (single-pixel frame), rule-resolution (zero
denominator), pipeline-placement (validator under `sanity-checks`).

## 6. Description draft
See `meta.md` (kept in sync; ~330 words).

## 7. File footprint (spike, measured)
| Action | Path | human-eff |
|---|---|---|
| NEW | src/animation.rs (render, needed_rect, crop, delays, optimized_frames, stack/split) | 196 |
| MODIFY | src/lib.rs (prepare_animation, compress_frames, evaluation_settings split) | 96 |
| MODIFY | src/sanity_checks.rs (timeline) | 21 |
| MODIFY | src/cli.rs, main.rs, options.rs, headers.rs | 10 |
TOTAL 323 human-eff / 7 files. Leanest passer estimate 210-260 (raw-sample compare, no helper split).

## 8. Solution outline
`read_pixel` (normalised RGBA16, transparent collapsed) -> `render` (displayed + after per dispose)
-> `needed_rect` (changed ∪ BACKGROUND-visible) -> `optimized_frames` (merge test on displayed+after
vs last kept, exact delay add, crop or 1x1) -> `prepare_animation` (decode + normalise to 8/16-bit
non-interlaced, animation list incl. aux-fcTL default frame, write back aux fcTL + acTL, stack ->
`perform_reductions` + Evaluator -> split, restore depth/interlace) -> `optimize_raw` on the default
image with reductions off -> `compress_frames`.

## 9. Test outline
One new file `tests/apng_<hex>.rs` (cfg sanity-checks): APNG builder (RGBA8 / indexed / interlaced),
chunk walker, `image`-crate timeline oracle (merge equal consecutive canvases, exact delays).
Buckets: joint reductions (opaque->no alpha, union forces depth 8, hidden default image colours,
gray+colour frame, transparency key, interlaced kept, sub-byte input, reduction after crop), crop
(changed block, BACKGROUND keeps visible pixels, PREVIOUS, OVER transparent border, SOURCE transparent
border, first frame, 1x1), merge (into aux-fcTL default frame, chain, den 0, overflow kept, same
display different state kept, BACKGROUND re-draw mergeable, into hidden-default first frame, acTL,
num_plays), options (`frame_reduction = false`), CLI (`--nf`, `--nx`), validator (accepts merged,
rejects changed delay / changed pixels).

## 10. Forced bounds
`Options` gains a bool field; struct-literal users use `..Default::default()` (tests do).

## 11. Trap matrix
| # | Trap | F-id | Axis | Interdependent with | Test |
|---|---|---|---|---|---|
| 1 | crop = bbox of changed pixels only; BACKGROUND frame's cleared area shrinks | F-9-like state seam (new) | dispose semantics | #2 (same state model) | crop_background_keeps_visible |
| 2 | merge on equal display only / only no-op frames merge | F-10 (display x state) | merge condition | #1 | merge_same_display_other_state_kept, merge_background_redraw |
| 3 | fold into default-image frame edits `frames` not the aux fcTL | F-9 origin / F-38 | container origin | #4 | merge_into_default_frame |
| 4 | acTL count left verbatim | F-33 inherited aggregate | container count | #3 | actl_counts_frames |
| 5 | hidden default image left out of joint reduction / cropped | F-24-style cell | reduction domain | #6 | hidden_default_colours |
| 6 | reductions decided before crop | F-6 ordering | pipeline order | #1 | reduction_after_crop |
| 7 | den 0 / overflow in delay add | F-15-like arithmetic | delay | #2 | delays_* |
| 8 | validator keeps frame-count equality / ignores delays | F-20 sibling behaviour | validation | #2 | validator_* |
| 9 | `--nx` leaves frame reduction on | F-10 flag cell | options | — | cli_nx |

## 11b. Cross-product
| | SOURCE | OVER |
|---|---|---|
| NONE | changed bbox | transparent border dropped |
| BACKGROUND | visible pixels kept | visible pixels kept (OVER) |
| PREVIOUS | changed bbox | changed bbox |
Plus default image {hidden, first frame} x {merge target, reduction domain}.

## 12. Tier/category
Olympus, feature-request ("Add").

## 13. Predicted pass rate
15-35%. Risk of too-easy if agents copy apngopt-style reasoning correctly; risk of 0% if the state
rules read ambiguous (mitigated by exact wording and a rich oracle).

## 14. Quality gate
Floor: 323 human-eff spike, 7 files. Open items: platform picker (Req 0), core-slice precheck (4b),
Docker cold build, flakiness 3x, FP mutation pass.

## Not a duplicate
Nearest approved PNG work: image-png-adam7-encoding (encoder interlacing in image-rs/png). Different
repo, different capability (animation optimiser vs encoder pass layout).
