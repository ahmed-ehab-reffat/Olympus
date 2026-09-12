# feedback — lyon-stroke-to-fill

Olympus. Repo nical/lyon (2590 stars, dual MIT/Apache, active 2026-05). Base 8071ec066c.
Feature: `StrokeToFill` trait converting a stroked path into a fillable outline `Path` (issue #564, maintainer-invited, unsolved). Category: feature-request.

## Shape / design
- Shape: O-Pipeline-hard + O-Composite-add breadth. Best agent Vega.
- Lead wall = the DISSOLVE (HARDENING sec 0/1, "hardness in DOING"): contract stated (even-odd == non-zero simple outline); fix (resolve all overlaps) is a discovery.
- Second wall (S3 baseline-preservation, found on request): reference reuses the crate's shared `math_utils::compute_normal` (same primitive `stroke.rs` uses at 3 call sites for miter geometry) instead of a bespoke line-intersection. A scale-inversion mutation of that shared function regresses 2 UNRELATED existing tests (`math_utils::test_compute_normal`, `stroke::correct_miter_clip_length`) misdirecting entirely away from stroke-to-fill. Narrow (2 of 3 tried mutations on that function did NOT trip it) but real and mutation-proven, not fabricated. No meta.md disclosure needed (fair per S3 doctrine: base mode already runs the shared-path tests).
- FP-safe oracle: winding-number membership (non-zero) + even-odd membership + grid-area, all implementation-invariant.

## PLATFORM PRE-CHECK RESPONSE (2026-07-25)

Ran the platform's automated pre-checks. 3 findings, handled as follows.

1. **Dockerfile: unpinned `cargo install cargo2junit`** (WARNING). Legitimate, no tradeoff. **Fixed:** pinned to `--version 0.1.15` (the exact version validated in every prior Docker run). Rebuilt + re-ran the full non-root offline container test to confirm: base 185/0 fail, new 38/0 fail.

2. **GitHub license `noassertion`** (WARNING). Manually re-verified: `crates/tessellation/Cargo.toml` declares `license = "MIT OR Apache-2.0"` explicitly; both `LICENSE-MIT` and `LICENSE-APACHE` at repo root are standard, unmodified texts (read verbatim via `gh api`, no conditional riders, not NCSA); these are the ONLY two license files anywhere in the tree (checked recursively). `NOASSERTION` is an artifact of GitHub's detector not resolving one SPDX id when a repo ships two separate license files (the standard Rust dual-license convention), not a real compliance issue. No repo action needed; documented here for a reviewer bypass message if contested.

3. **description_conciseness, HIGH + 2 MEDIUM + 1 LOW** (request_changes verdict). Verified each suggestion against the REPO'S OWN existing doc comments before acting (not just trusting the AI's claim):
   - HIGH (remove the general line_width-reach / line_join bevel-miter-round / start-end-cap butt-square-round paragraph): **verified genuinely obvious** — `LineCap` and `LineJoin`'s own doc comments in `crates/path/src/lib.rs` state these exact shapes verbatim (read directly via `gh api`). Applied.
   - MEDIUM (remove "curved segments approximated within tolerance"): verified `StrokeOptions.tolerance`'s own doc comment already covers this. Applied.
   - MEDIUM (remove "it does not intersect itself" as redundant with the even-odd/non-zero equivalence): the two clauses are operationally equivalent (even-odd == non-zero everywhere is precisely the condition for no overlapping region of winding magnitude >= 2); the equivalence clause is the testable one. Applied.
   - LOW (trim "has no caps" from the closed-subpath sentence, keep "interior empty"): "closed path = no free ends = no caps" is definitional, not lyon-specific. Applied.
   - **Did NOT blindly apply**: before trimming, independently verified the KEPT clauses are genuinely non-obvious, not just trusting the checker's classification. Notably confirmed `miter_limit` clamp-to-one is NOT inferable — the repo's own `with_miter_limit()` builder **panics** (`assert!(limit >= 1.0)`, has its own `#[should_panic]` test) on exactly the values my solution silently clamps, a completely different behavior. Also confirmed the zero-length round-cap doc comment is worded AMBIGUOUSLY on the exact radius ("radius equal to the stroke width" vs. the actual half-width every implementation including this one uses) — independently justifies keeping that clause explicit even though the checker's own reasoning for keeping it was less specific.
   - Re-ran the full FP alignment check (both directions) against the trimmed meta.md: every one of the 38 tests still traces to either a remaining sentence or a repo-doc-comment-verified codebase-inferable fact. No new alignment gap introduced by trimming.
   - meta.md: 256 -> 187 words (well under the 200 recommendation now, under the 500 hard cap).

4. **problem_and_tests WARNING: no test for the "plain sequence of path events" capability.** Structural tension, resolved by NOT adding a test: any test exercising this capability must call a concrete Rust symbol by an exact name, and the user explicitly directed meta.md to stay behavioral-only (no API names). Disclosing the exact name would satisfy the checker but violate that instruction; testing an undisclosed name would recreate exactly the hidden-requirement unfairness the FP check removed earlier. The checker itself marks this WARNING as non-blocking ("No blocking errors", "problem content does not need to change") and explicitly separates it from the request_changes verdict above. Accepted as advisory. If a human reviewer pushes on this, the fair resolution is to either name the function explicitly in meta (then test it) or drop the capability's mention entirely (then it's private, untested, and not a claim) — not to test an undisclosed name.

## Reference approach (kept out of meta)
Emit primitive contours (segment quads via `compute_normal`-based joins + caps) -> tessellate non-zero with lyon's own FillTessellator -> extract boundary (edges used once) -> chain into simple loops -> simplify collinear runs -> reused `stroke_to_fill_events` free function (mirrors the crate's own `StrokeTessellator::tessellate`/`tessellate_path` split, incl. the same `variable_line_width` debug_assert convention).

## DOCKER VALIDATION (2026-07-25) — full real docker build + run, not just host cargo

Ran actual `docker build` + `docker run --network none --user 1000:1000` (non-root, offline) end to end. Found and fixed TWO real environment bugs the host-only `cargo test` validation could not catch:

1. **Workspace scope bug**: root Cargo.toml's `members` list includes `examples/wgpu`/`examples/wgpu_svg` (heavy GPU deps: wgpu-core, wayland, x11rb) and `bench/*`. `cargo build --workspace` (the DOCKER.md canonical template) pulled in this entire unrelated dependency tree, wasting disk/time. **Fix**: scope to `cargo build -p lyon_tessellation --tests` (only what test.sh needs).
2. **Non-root write-permission bug**: `COPY . .` in the Dockerfile creates `/app` root-owned. At solve time the platform runs `--user 1000:1000` and needs to `git apply test.patch` / `git apply solution.patch` INSIDE the container (creating new files, e.g. `test.sh`) — this failed with "unable to write file 'test.sh': No such file or directory" until the whole `/app` tree (not just `/app/target`) was `chmod -R a+rwX`. DOCKER.md's "no chmod needed on olympus-base-rust" claim (from the nickel-1336 precedent) did NOT hold here — likely because that precedent's test.sh never needed to CREATE new files via git apply inside the running container. **Fix**: `chmod -R a+rwX /app` (safe — this is the user's own workspace, unlike the `/root` chmod DOCKER.md correctly warns against, which breaks cargo registry perms).

Final Dockerfile:
```
FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo install cargo2junit && cargo build -p lyon_tessellation --tests && chmod -R a+rwX /app
CMD ["/bin/bash"]
```

**Full container validation (both apply orders, non-root, `--network none`):**
- Clean checkout (no patches) builds successfully.
- test.patch only: base 185/0 fail; new = build-fail fallback (1 failing testcase, exit 101) — correct, feature absent.
- + solution.patch: base 185/0 fail; new 35/0 fail.
- Reverse order (solution then test): base 185/0 fail; new 35/0 fail.
- Disk managed carefully throughout (16G budget); all intermediate images/build-cache pruned after validation.

## Local (host cargo) validation summary
- 38 new tests, base 185 pass (no regressions), both apply orders green, reverse-apply clean, ASCII, test.sh 100755, no banned markers, no non-doc comments, deterministic 3x.
- LOC: Counter-1 (auto-block) 342; Counter-2 (human-effective) 250 (== 250 floor, no buffer — see Open items).

## FP CHECK (2026-07-25, mandatory final gate) — full bidirectional alignment audit

Read meta.md sentence by sentence, mapped each testable clause to specific tests, then read every test and checked it traces back to a meta.md clause. Found and fixed 6 issues, all mutation-verified after the fix.

**Direction 1 — meta.md clauses with NO discriminating test (a wrong impl could pass):**
- A1. `PathSlice` impl named in meta but zero tests called `.stroke_to_fill()` via `PathSlice`. Added `path_slice_stroke_to_fill_matches_path`. Mutation-verified: a no-op `PathSlice` impl fails it.
- A2. `start_cap`/`end_cap` independently settable per meta, but every existing test set both identically via `.with_line_cap()`. Added `start_and_end_cap_are_independent`. Mutation-verified: swapping end_cap to start_cap's value fails it.
- A3. Meta says zero-length subpaths become "a full disc or square" but only round was tested. Added `zero_length_square_is_a_square`. Mutation-verified: routing Square to the round arc code fails it.
- A4. "a `line_width` that is not a positive finite number yields an empty path" — only NaN/Infinity were tested, not zero/negative (the more obvious half of the clause). Added `zero_line_width_yields_empty_path` and `negative_line_width_yields_empty_path`. Mutation-verified: `negative` catches the exact plausible bug ("added `is_finite()`, dropped the old `>0.0` check"). `zero` turned out unfalsifiable by any mutation I could construct (FillTessellator itself produces zero triangles for an exactly-zero-area degenerate input, independent of my guard AND of `simplify_loop`'s degenerate filter) — not an FP risk (it never asserts something false), just a weak/non-discriminating test kept for direct contract coverage.
- Also mutation-verified the untouched `tolerance`-approximation clause (removing `.flattened(tol)` before curve segments reach `outline()`) — confirmed `curved_segment_follows_the_curve` catches it; no gap there.

**Direction 2 — tests exercising something meta.md never states (hidden requirement, unfair):**
- B1. `generic_iterator_entry_point_matches_path_method` tested a free function `stroke_to_fill_events` never mentioned in meta.md. **Removed the test; made the function private** (it's still used internally by both trait impls, so no dead code) — this also closes a "public API scope creep" risk (HARDENING: "never pad LOC with public API"), and is LOC-neutral on Counter-2 (import-line edits aren't counted).
- B2. `straight_butt_segment_is_a_minimal_rectangle` asserted an exact `vertex_count() == 4` — internal representation efficiency, not a described behavior. A correct solution emitting extra collinear boundary points (very plausible from a tessellator-based dissolve) would legitimately fail this. **Removed.** The underlying `simplify_loop` code stays (it also does real correctness work: near-duplicate-point merging and degenerate-loop rejection from the tessellator's boundary extraction, both load-bearing and exercised by other passing tests) — only the unfair exact-count assertion was cut.

Net: 35 -> 38 tests (removed 2 unfair, added 5 gap-closing), all mutation-proofed, zero surviving alignment gaps in either direction as far as this audit could find.

**R2 revision (user request): restored `stroke_to_fill_events` rather than deleting it.** Made it `pub` again (it is real, idiomatic, already exercised internally since both trait impls delegate to it) and disclosed its BEHAVIOR in meta.md ("the same outline should also be reachable from a plain sequence of path events, for callers that do not already hold a `Path` or `PathSlice`") without naming the function — per DESCRIPTION.md's WHAT-not-HOW rule, meta.md never names new internal symbols, only describes capability. Deliberately did NOT re-add a test that hardcodes the exact function name: doing so would recreate the same "must-guess-an-undisclosed-name" unfairness the FP check removed, just with a name-shaped fig leaf instead of a real disclosure. The capability stays real (used internally, described in prose) without becoming a name-guessing trap.

## Mutation / trap-proof (no wall unchecked, all confirmed on the FINAL 38-test suite)
- naive quad-only (no joins/caps): 8 FAIL (was 7; +curved_segment now also depends on this path).
- region-correct overlapping soup (no dissolve): 5 FAIL (even-odd walls).
- no miter_limit clamp: 3 FAIL.
- fill closed-loop interior: 3 FAIL (annulus walls).
- shared compute_normal scale-inversion: 2 FAIL (existing, unrelated base tests — S3).
- half<=0.0 NaN/Infinity gap: 2 FAIL when reverted to buggy guard.
- broken PathSlice impl (no-op): 1 FAIL (A1).
- start/end cap confusion: 1 FAIL (A2).
- zero-length Square routed to Round: 1 FAIL (A3).
- is_finite-only guard (drops the >0.0 check): 1 FAIL (A4, negative width).
- skip `.flattened(tol)` entirely: 1 FAIL (tolerance clause, confirmed no gap).

All 6 pillar traps (naive-completeness, dissolve, miter-limit, annulus, NaN/Infinity guard, PathSlice/start-end-cap/zero-square as a completeness cluster) have EMPIRICALLY DISJOINT failure sets across every mutant tried — zero pairwise overlap. Orthogonal in the strong (contract-forced) sense for everything except the S3 compute_normal lever, which is architecture-contingent (only fires if a solution happens to reuse that shared primitive) — flagged as a bonus catch, not counted in the difficulty projection.

## Open items
- LOC is EXACTLY at the 250 human-effective floor, zero buffer. My counting script approximates the platform's real strip logic; if the platform's actual count differs even slightly, this could dip under. Recommend re-verifying with the real `.claude/hooks/effective_loc_check.py` if/when available, or adding 10-20 more genuine lines of margin before submit.
- Pass rate NOT measured (smoke batch deferred per user). Projection ~10-25%, lead wall = dissolve.
- meta.md 228 words (over 200 recommendation, under 500 cap).

## Attempt history
- R0 (2026-07-25): authored, dissolve lever, compute_normal S3 lever, NaN/Infinity fix, mutation-proofed, LOCALLY validated AND full real-Docker end-to-end validated (non-root, offline, both patch orders).
- R1 (2026-07-25): full FP check — closed 4 alignment gaps (PathSlice, start/end cap, zero-length square, zero/negative line_width), removed 2 unfair hidden-requirement tests (undisclosed free function, exact-vertex-count), made the free function private. 35 -> 38 tests. Re-validated both apply orders + base regression + LOC floor. Not yet submitted / batched.
