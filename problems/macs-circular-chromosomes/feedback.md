NEXT (human): Requirement 0 picker check + upload this slice to the platform precheck, then write the verdict in pipeline/INBOX.md

# macs-circular-chromosomes - feedback

Repo: macs3-project/MACS (BSD-3-Clause, 784 stars). Hunt: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-23-P.md` (hunt #29).
Base: 760ff63b958f79cc82abc8c1a9847705cd99c907 (main HEAD 2026-09-24, merge of #749 summit padding fix; chosen over the hunt's ece08963 so the #749 overlap is already in base).

## Status
- 2026-09-24: SLICE started (factory builder). Clone `worktrees/MACS` (hardlinked from `worktrees/_hunt/f_bio/MACS`).
- 2026-09-24: SLICE READY (Step 4b). Core = hunt spike rebased onto 760ff63b + #749 conflict resolved
  (summit padding keeps negative starts on circular chromosomes) + pileups of circular chromosomes
  extended to the chromosome length (the spike left the tail after the last fragment unscored, so
  q-values depended on where the origin was). 326 human-eff / 402 raw / 11 files. 16 tests, all fail
  on base, all pass with the reference; clean room green (see eval-results.md).
- 2026-09-25: precheck round. FAILED "Python installs are editable or test invocation is documented"
  -> Dockerfile now installs the project editable (`pip install --no-deps --no-build-isolation -e .`,
  build_ext parallel=8 via DIST_EXTRA_CONFIG). setuptools 82 builds editable extensions in a temp
  build_lib, so the image seeds build/lib with the in-tree .so files; without that the first test.sh
  `build_ext --inplace` recompiled all 65 units (measured), with it it compiles 0. Dropped the separate
  `setup.py build_ext` step (pip compiled everything a second time, serially: +280 s). Dockerfile
  warnings (git init, simde clone, build step, chmod/safe.directory) answered with short comments: the
  repo .dockerignore drops .git/*, simde is an uncarried submodule pinned to the base gitlink, the
  extensions are Cython, the grader runs as arbitrary uids. meta.md: cut "bedGraph tracks show it at
  half height" (current-behavior narration); reworded the aligner clause as a rule ("Aligners do not
  flag such a pair as proper, and it must still be used") because base Parser drops `not flag & 2`
  pairs and the fixture flags origin pairs improper, so the clause is load-bearing. Kept "listed in
  order of start" (tested: starts == sorted(starts)), the q-value/cutoff-analysis clause (cutoff
  analysis tested) and "fragment length unchanged" (PeakModel) against the AI suggestions.
  Also: setup.py `scripts=['bin/macs3']` is COPIED by an editable install, and bin/macs3 holds the
  argparse parser the solution edits, so the `macs3` on PATH stayed stale (rejected --circular after
  the patch). Replaced it with a 2-line wrapper that execs /app/bin/macs3.
  Validation (cold --no-cache build 437 s, was 441): uid 1000 / 0 / 4242 each: git status clean,
  import resolves to /app, base 117 (4 skip) 0 fail x4, new 16/16 fail before solution, 16/16 pass
  x3 after, `macs3 callpeak --help` shows circular 0 before / 2 after, bare `pytest` 16 passed.
- 2026-09-25: precheck round 2. Test Quality FAIL (2/17 unfair) + Solution Quality FAIL (4 issues).
  Tests: `q-score > 3.0` on the origin site replaced by a rotation comparison (move the origin so the
  site sits mid-chromosome; its narrowPeak row must match column for column, from the stated "leaves
  every score unchanged"); gappedPeak `blockCount >= 3` dropped (the rotated gappedPeak comparison
  already pins every column). Solution: (1) BAMPE origin fallback mask 3868 -> 2876: drops the
  duplicate bit 1024 (ordinary BAMPE mask 2820 leaves dups to --keep-dup) and requires mate-forward
  (0x20 clear); the `> rlength // 2` shortest-arc rule replaced by `thisend > nextpos` (reverse read
  must end before its mate starts). (2) `--circular` names validated against the BAM headers of the
  treatment files before loading (`circular_header_lengths`), not treat.get_rlengths(), which only
  keeps chromosomes with reads. (3) `__rotate_circular_regions` k == 0 (every gap round the circle
  within max_gap) now cuts at the widest gap instead of the origin. New tests (18 -> 19 total incl.
  the replaced one): long origin pairs (650-700 bp on a 1000 bp plasmid) + reverse/reverse decoy
  pair; header-listed chrM with no reads is accepted; whole-circle plasmid component is rotation
  invariant. Old solution fails exactly those 3; a mate-bit mutant (2876 -> 2844) fails the plasmid
  test. meta.md: added "while a name the header lists is accepted even when no read maps to it".
  human-effective 340.
- 2026-09-25: precheck round 3. Solution Quality FAIL (2 issues) + advisory coverage notes.
  (1) Read-less header contig "excluded from statistics": decided the OTHER way and pinned it. Base
  MACS scores only chromosomes with reads in both treatment and control; counting an empty chrM
  because it is named circular would change every q-value on chr1. meta.md now says "such a
  chromosome is skipped like any other chromosome without reads"; the test compares
  `--circular chr1,chrM` with `--circular chr1` over the same header (narrowPeak + cutoff analysis
  identical). (2) `__rotate_circular_regions` returned for n < 2 before resetting startpos[0], so in
  `__pre_computes` (which, unlike narrow/broad calling, never resets it) a single region covering the
  whole circle became [L, L) and vanished from the cutoff analysis. Reset moved above the n < 2 return.
  New test: uniformly covered plasmid, --nolambda, cutoff analysis must list npeaks 1 / lpeaks P
  (previous solution fails it). Advisory coverage taken: treatment-only (no -c) circular pileup +
  crossing peak; xls abs_summit within 1..L; format error parametrized BED/BEDPE/SAM; per-base
  clipping of the linear chrA treatment pileup (a chrA-wrapping mutant fails it). 23 tests.
- 2026-09-25: Auto Review round (Tests 1/3, Solution 1/3, Description 3/3).
  S1 pooled headers: `circular_header_lengths` now reads the header of EVERY -t and -c file; each
  must list every circular name, with one length, else exit 1 (a later header omitting it used to
  reset the pooled track length to INT_MAX). meta.md reworded to match (per-file headers, length
  mismatch is an error). T4 PeakModel: new model-enabled test, 120 circular 3 kb contigs each with
  one strand-paired site straddling its origin, rotated to mid-contig; `# d =` and narrowPeak rows
  must match. A no-PeakModel mutant exits 1 (0 paired peaks). That test also exposed a REAL
  reference bug: summit ties pick the middle of the tied segment list, and the origin always splits
  a segment, so a plateau across the origin got a different summit (fold 8.76 vs 5.40). Fix:
  `__merge_equal_segments` joins adjacent equal (treat, ctrl) segments of a peak on circular
  chromosomes before the summit search (canonical segmentation; linear chromosomes untouched).
  Other: FRAG added to the format matrix; unknown-name and read-less-contig tests parametrized over
  BAM/BAMPE; pooled-header test x {treatment, control, length} x {BAM, BAMPE} with a valid pooled
  call in each; test.sh tees pytest output and puts it in the no-results fallback (verified with a
  broken conftest). 33 tests; previous solution fails 7.
- 2026-09-26: Auto Review round (Tests 1/3, Solution 1/3, Description 3/3).
  S1 local lambda: `wrap_circular_ranges` capped any range longer than the chromosome to one lap
  while PeakDetect still scaled by d/llocal, so the default 10 kb llocal on a 3 kb plasmid was ~0.3x
  too low. Now a range goes round once per full rlength plus its folded remainder. meta.md adds "A
  local lambda window longer than the chromosome goes around it as many times as its length
  requires, so every control read inside it counts once per lap" (the reviewer also offered an
  effective-width normalization, which gives different numbers, so the rule had to be stated).
  New per-base oracle test on a 3 kb plasmid (control in one arc, -g 10x so llocal decides); the
  previous solution fails only that test. Tests: sparse-tail rotation test (data block moved from
  mid-chromosome to the end, narrowPeak + cutoff analysis equal); a mutant that drops the terminal
  background segment fails 11 tests incl. the new one (the old rotation tests already caught it).
  Broad test gets a second site and asserts raw start order in broadPeak/gappedPeak. Pooled-header
  test adds control_length. Linear-chromosome test compares chrA treat and control-lambda tracks
  with a run without --circular. 37 tests.
- Image `factory-macs-circular-chromosomes` removed and worktree build outputs cleaned at the end of the SLICE run; clones `worktrees/MACS` (branch `circular`, WIP), `worktrees/MACS-cleanroom` (pristine base) kept for FINISH.
- Session was interrupted once (orchestrator restart) mid-mutation; PileupV2.py was restored from
  the mutant state and re-verified (2 `extend_to_rlength` call sites). WIP backups in
  `worktrees/MACS-backup/`.

## Decisions log (conservative choices made unattended)
- Base moved from hunt's ece08963 to 760ff63b (main HEAD, #749 merged today) so the only open overlap
  (#749 summit padding in CallPeakUnit.py) is already in base.
- Contract written as a ROTATION LAW (P1): results must not depend on where the origin lies. Tests are
  metamorphic (run, rotate every read, rerun, compare with names ignored) plus independent per-base
  oracles for the pileup and control lambda. No exact values are pinned from the reference.
- Every position of a circular chromosome is scored (pileups end at L). Required by the law; the
  hunt spike violated it; a tail-less mutant fails 6/16 tests.
- BAMPE origin pairs: stated for pairs aligners report as improper (reverse read before its forward
  mate). Pairs flagged proper that cross the origin are NOT specified (reference would take the base
  linear path); FINISH must decide (fix the reference or keep the scope sentence).
- `--circular` requires BAM/BAMPE (lengths from the header); errors tested only by exit status and
  absence of output (no message pins). Each error test also runs a valid `--circular` call so it
  fails on base (argparse rejects the unknown option on base).
- Repo `.dockerignore` drops `.git/*`, so the image has an empty `.git`. The Dockerfile rebuilds a
  local repo (`git init`, one commit named after the base hash) only when `.git/HEAD` is missing, and
  excludes build outputs via `.git/info/exclude`; `git status` in the image shows nothing before the
  patches. Cold `--no-cache` build 441 s (pip 106 s, COPY+git+build 196 s, export 119 s): under 600 s
  but with ~160 s margin. Dropping the git rebuild would save ~90 s if the platform objects.
- Kept three one-line attribute comments in the solution (`# lengths of circular chromosomes`): the
  same classes already comment every declared attribute that way. Docstrings on new helpers match the
  repo's docstring convention.
- test.sh rebuilds the Cython extensions in place (`build_ext --inplace`, incremental, ~20 s after a
  patch) before pytest; if the build fails every collected testcase is rewritten as a failure with the
  build log (stale `.so` files cannot pass for a broken build); no XML at all -> one diagnostic case.

## OWED (FINISH / human)
- Human: picker check (Requirement 0) and core-slice precheck upload.
- FINISH: PeakModel F2P (plasmid fixture: many circular contigs, one origin site each; linear model
  finds 0 pairs), pad-and-fold mutant proof, dense-control cell against the rotate-to-gap architecture,
  BAMPE x {summits, broad, cutoff}, proper-flagged origin pairs decision, 3x flakiness in container,
  full mutation sweep, SIX-CHECK + PR-DIFF re-run before final patches.

## Attempt history
