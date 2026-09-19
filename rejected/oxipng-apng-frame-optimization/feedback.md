# feedback.md — oxipng-apng-frame-optimization

Repo oxipng/oxipng (Rust, MIT, ★4.2k), base 36f3ef8a (= master 2026-09-19, v10.2.1). Lane from hunt
2026-09-19-E (joint APNG reductions + frame crop/merge). Work tree `worktrees/oxipng` branch `spike`.

## SHELVED 2026-09-19 — core-slice precheck: overlap Blocker (set-level derivative)
181/407 discounted lines (44.5%) vs an older APNG-wide reduction submission; 199/407 (48.9%) vs an
older canvas/cropping submission; union ruled "stitches two older major implementation blocks".
Not contestable. See Instructions/TOO-EASY.md § oxipng-apng-frame-optimization.

## Status (R0, 2026-09-19)
- Reference: 342 human-eff (hook) across 7 files (new src/animation.rs; lib.rs, sanity_checks.rs,
  headers.rs, options.rs, cli.rs, main.rs). ~20 of the lib.rs lines are the moved
  `evaluation_settings` helper.
- Tests: 40 in `tests/apng_frames_8ecd58.rs` (cfg sanity-checks): own APNG builder (RGBA8, indexed
  low depth, Adam7), chunk walker, `image`-crate timeline oracle (equal consecutive canvases merged,
  exact delays, default image compared).
- Clean room (fresh clone at base + test.patch, Docker as uid 1000, --network none): without solution
  base 296/296 pass, new 40/40 fail (build-failure fallback); with solution base 296/296, new 40/40,
  3x identical. Cold `docker build` 296 s.
- Mutations (12): all killed except "PREVIOUS treated as NONE", which got a new test
  (previous_dispose_restores_canvas_for_next_frame). Kill counts: BACKGROUND rule 3, display-only
  merge 1, no-op-only merge 2, aux fcTL 6, acTL 9, den 0 1, saturating delay 1, validator frame count
  9, --nx 1, validator ignores delay 1, transparent colours distinct 1.
- Design decisions: interlace option now applies to APNG (the `image`/`png` decoder mis-decodes
  interlaced sub-frames, so cropped interlaced frames can never pass `sanity-checks`; default output is
  de-interlaced). Evaluator-dependent colour-type/depth assertions relaxed to what meta states.
- meta.md 282 words, ASCII.

## Owed before any batch
1. Requirement 0: platform picker accepts oxipng/oxipng.
2. Step 4b core-slice precheck (dedupe): #551 is a public, long-lived request for exactly this lane.
3. Risk: repo `.dockerignore` excludes `/.git/` from the build context, so `/app` has no `.git` in a
   local build. Watch the first smoke run for diff-extraction problems.
4. FP pass (feature-stub, assertion flips), re-run exclusivity at submit.
