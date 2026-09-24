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
