# hayro-optional-content-baking — feedback

NEXT (human): Requirement 0 picker check + upload this slice to the platform precheck, then write the verdict in pipeline/INBOX.md

STATUS (2026-09-23): SLICE-READY (Step 4b). Base 6dcda45859b7e9cc8488fb6cd011795ba0cca86b.
Slice = 165 human-effective (hook) over 3 files, 10 new tests, Docker clean room green as uid 0,
1000 and 4242 with --network none, 3x identical. No differentiating scope yet (by design).
Uncommitted slice lives in worktrees/hayro (target/ deleted); validation script in
worktrees/_hayro_val/val.sh.

Repo: LaurenzV/hayro (canonical, not moved), 771 stars, MIT/Apache-2.0, Rust.
Lane: hayro-write bakes the source document's default optional-content visibility into extracted
pages and XObjects (hidden-by-default content does not survive extraction; visible content untouched).
Promoted fallback of the dead vrp pick (hunt 2026-09-23-I).

## Scope-lock red flags (settled first)

1. Absorption: hayro-interpret/src/ocg.rs (170 lines, pub(crate), other crate; hayro-write depends only
   on hayro-syntax) computes the default-config inactive set and OCMD policies. Everything else the lane
   needs (content-stream rewriter, hidden-op policy that keeps state/clip/text advance, XObject /OC,
   recursion into forms/patterns, Tr restore) does not exist anywhere in the repo. To be measured by the
   slice.
2. No byte positions in UntypedIter: bounded (either re-emit operands through pdf-writer + the existing
   WriteDirect, or add an offset accessor in hayro-syntax).
3. Tests: existing write/render tests depend on downloaded PDFs + locally generated snapshot PNGs (no
   snapshots are checked in). New tests build PDFs in-test with pdf-writer and compare hayro renders of
   the extracted page against hayro's render of the source page, in-process. Base mode must be scoped to
   self-contained suites.
4. Competitor: 0xbe7a fork branches = write-preserve-oc (1-line preserve), write-copy-annots,
   write-page-dict-hook; none bakes. 76-fork branch scan: glyphst (lazy error propagation in hayro-write,
   OC resolve in interpret), cristim (interpret ocg overrides), 5x `vb` Cargo.toml bumps: none bakes.
   SAY-5 (signature account) forked 2026-06-18, fork deleted, no PRs: note only. No PR/issue for baking.

## Scope-lock verdicts (all four red flags settled, none fatal)

1. Absorption: NOT absorbed. The slice reuses nothing from `ocg.rs` (the config half is ~45 eff of
   fresh code in hayro-write; `OcgState` is `pub(crate)` in another crate with an interpreter-bound
   stack API). Slice measures 165 human-effective (hook). The rewriter, hidden-op policy, XObject
   `/OC` channel exist nowhere. FINISH plan (DESIGN.md sec 7/11): recursion into content the page
   draws (forms, tiling patterns, Type3 CharProcs, soft-mask groups) through the dependency copier
   (~40-60), per-use specialisation of shared forms whose baked output depends on inherited state
   (render mode, inherited Properties) against the copier's `ref_map` dedup (~50-70), pruning of
   resources only hidden content uses (~40-60). Sketch 295-355; discounted 40% for the known
   overstatement -> ~245-280. Borderline but credible. hook padding-floor reads 25 (the op-name
   match arms), so FINISH must add depth, not more op arms.
2. No byte positions: bounded. A 3-line public `UntypedIter::offset()` in hayro-syntax lets the
   baker copy every kept instruction byte-for-byte; only hidden instructions are replaced.
3. Tests: self-contained. Raw PDFs built in the test file, oracle = hayro's own (OC-aware) render of
   the SOURCE page vs render of the extracted page/XObject, exact pixels, in-process, offline. No
   snapshots, no downloads. Base mode is scoped to offline suites (crate libs + hayro-tests `load::`
   + the four snapshot-free write tests).
4. Competitor: clean (details above). Cross-repo: open-redact-pdf (8 stars) strips hidden
   `BDC..EMC` runs wholesale (naive, drops state) and iText OCGRemover (AGPL) = MEDIUM crib of the
   naive half only; pdf_oxide/xberg declare an unimplemented StripHidden option.

Gates: 1/6 reproduced (8/10 slice tests fail on base with "extracted page differs from the source
page"), 5 cold, 7b clean, 8 defined (PDF 32000 8.11 + hayro interpreter; baking honours the
maintainer's #1279 constraint), stars 771, MIT/Apache incl. vendored, Rust 95.8%, quota 0/6.
Conservative choices (unattended): hayro quirk `W f` (hayro only applies a pending clip on `n`) and
`VE` expressions are kept out of fixtures; doc tests are left out of base mode because their IDs
carry source line numbers an agent edit can shift.

## Slice build log

- Solution: new `hayro-write/src/optional_content.rs` (default-config evaluation incl. BaseState/ON/OFF
  and OCMD `P` policies; a baker that walks `UntypedIter`, copies kept instructions byte-for-byte,
  and in hidden content turns path paints into `n`, text shows into `3 Tr` + op + restore of the
  tracked render mode (q/Q stack), drops `Do`/`sh`/inline images; a visible `Do` of an XObject whose
  own `/OC` is off is dropped; returns None when nothing changed so visible-only streams stay
  byte-identical), wiring in `lib.rs` for both extraction modes, `UntypedIter::offset()` in
  hayro-syntax.
- Tests: `hayro-tests/tests/write_oc_0eadd0.rs`, 10 tests, oracle = hayro render of the source page vs
  render of the extracted page AND the extracted XObject. Two first-draft tests passed on base (hidden
  content drawn under visible content, and a hidden `W n` with nothing hidden drawn); both were
  rebuilt so every test fails on base for the right reason.
- test.sh: cargo2junit, build-failure fallback with the new test IDs, `::` normalised in classname
  and name, CARGO_NET_OFFLINE. Base mode = --lib of hayro-syntax/-write/-interpret/-cmap/-postscript
  (two download-dependent pdf-version tests skipped) + hayro-tests `load::` + 4 snapshot-free write
  tests = 475 cases.
- Dockerfile: COPY --chown=1000:1000, safe.directory, cargo2junit, fetch, pre-built test binaries,
  chmod -R /opt/cargo in the same layer, find-based chmod of /app dirs and root-owned outputs. Warm
  build ~140 s (base image cached).
- meta.md draft: 209 words incl. frontmatter, ASCII, one line per paragraph.

## Carry into FINISH (from DESIGN.md)
Recursion into forms/patterns/Type3/soft masks via the copier, per-use specialisation of shared forms
(inherited render mode / Properties) vs `ref_map` dedup, hidden-only resource pruning, the
byte-identical untouched-content guard as a test, F-10 cells (page vs form stream x marked-content vs
XObject-`/OC` x inherited render mode), mutation/FP sweep.
