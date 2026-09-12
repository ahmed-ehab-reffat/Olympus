# feedback.md — comrak-reference-style-links

## Status
DESIGN.md complete 2026-08-05. No code yet. Next gate: trap reproduction (write the
natural-but-wrong implementation and confirm trap #1 fails with a misdirecting symptom).

## Pick provenance
Selected after veryl lost four consecutive candidates to capability collisions (see
REPO-HUNT-2026-08-04-D.md). comrak was the shelved RANK 2; the renderer surface was chosen
deliberately over comrak's extension surface, which would have been derivative against our own
two pulldown-cmark markdown submissions.

## Gates cleared at pick time
- Licence: BSD-2 + vendored cmark BSD-2 + houdini/sundown MIT, all read, no riders
- Build 26s, 649+203 tests, determinism 3/3 identical
- Exclusivity: no PR implements reference-style link rendering (all states searched)
- Maintainer philosophy: issue #740 comment from kivikakk (OWNER) explicitly welcomes the feature
  and reports no design of his own. Quote: "I'd be happy for this feature to be implemented and
  would welcome PR(s) to do so, though thinking through it, there are many complicated edge-cases."
  Used as EVIDENCE the lane is open, NOT as a binding spec - the canonical form in DESIGN.md § 4 is
  invented here.
- Repo quota: 0/6

## Owed
- Trap reproduction for traps 1-4
- Naive-agent benchmark (target 70-85%)
- Docker validation: NOT possible locally (no Docker on this workstation). Static check only;
  carried to the platform run.

## Attempt history

### Round 1 - build + design-time hardening (2026-08-05). NO AGENT BATCH YET.

**This round is PREDICTION, not measurement.** No agent runs exist, so the pass rate is unmeasured
and every difficulty claim below rests on trap reproduction and structural reasoning only
(HARDENING Stage 1: agent runs are the only oracle).

Built the capability, then ran the harden pass before batching.

**Scope lever (forced).** First complete implementation measured **87 effective LOC** against a 200
floor - the "machinery reuse lands under the LOC floor" failure (HARDENING section 0, kcl precedent).
DESIGN.md section 7 had flagged this exact risk. Cleared it with genuine capability, never padding:
a second label style (`ReferenceLinkStyle::Text`) with slug derivation, CommonMark-fold-aware
collision disambiguation, a lowest-unused-number fallback, and the CommonMark collapsed/shortcut
short forms with an adjacency guard. 87 -> 171 -> 188 -> 196 -> 209 -> **214 effective**.

Two candidate levers were REJECTED as padding rather than capability: a multi-line-title "fix"
(probed it, titles already round-trip correctly - no bug to fix) and slug length truncation
(arbitrary). Recorded because rejecting a lever is as informative as taking one.

**Traps: 6 axes, ALL REPRODUCED** by writing the natural-but-wrong implementation and measuring the
symptom. See DESIGN.md section 11 for the table. The lead trap (A, exclude-before-number) produces
`[a][2] then [b][3]` - wrong labels on ORDINARY links, far from the autolink that caused it.

**Measured interdependence cycle:** the lazy no-pre-pass architecture (natural, avoids a second
traversal, and makes trap E easy) produces post-order numbering and causes trap B; fixing B needs
the document-order pre-pass, and the participation filter must be re-applied inside it, which is
exactly where trap A is lost.

**F-10 cross-product cells found a REAL BUG IN THE REFERENCE.** Filling the empty Text-style cells
(HARDENING Stage 3 lever 1) showed `[![Logo](img)](a)` rendering as `[![Logo][logo-2]]`, which does
NOT re-parse to the same document - the shortened form is unsafe when the link text contains a
nested link or image. Fixed with a nested-reference guard, added the rule to meta.md, and added 5
cross-product tests. This is the DIFFERENTIAL-HARNESS law working as advertised: the harness catches
your own reference's bugs, not just the agents'.

**Scope discipline:** a second round-trip failure (blockquote + `width = 20`) was traced to
PRE-EXISTING comrak behaviour - inline mode fails identically on base - so it was left alone rather
than fixed as scope creep, and no test asserts a round-trip that base comrak does not hold.

**Giveaway audit:** removed a sentence from meta.md that handed a worked example of trap A ("a
document that opens with an autolink still numbers its first ordinary link 1"). The RULE stays, the
instance is gone (Rule 7 / WORKED-EXAMPLE-HANDS-THE-APPROACH).

**Validation (clean room, fresh reset to BASE_COMMIT):**

| Check | Result |
|---|---|
| base mode on base (test.patch only) | 650 cases, 0 failures, exit 0 |
| new mode on base | exit 101, build-failure fallback emits 1 failing case |
| new mode + solution | 55/55 pass, 3 runs identical |
| base mode + solution | 650 pass, 0 failures, 3 runs identical |
| Flakiness gate | PASS - test-name digests byte-identical across 3 runs |
| Patch apply both orders | clean |
| Patch reverse-apply | clean |
| human-effective LOC | 214 (floor 200) |
| Files touched | 5 |
| meta.md | 452 words, ASCII, no headers |

**Predicted pass rate: 10-25%. UNMEASURED.** The next step is a 10-run Nova-heavy batch, which is
the only oracle. If it lands above 40 percent, the diagnosis order is: fill remaining cross-product
cells first, and do NOT reach for wording.

**Owed:** Docker validation (no Docker on this workstation - Dockerfile written to the Pattern A
rust template and checked statically only, carried to the platform run).


### Round 1b - self-review pass (olympus-review, 2026-08-05)

Ran the 7-stage reviewer process against the VISIBLE artifacts only (meta.md + patches + Dockerfile).
Stage 0 precheck, Stage 1 Pattern-22 re-run at submit time, Stages 4-6.5 content review.

**Stage 1 re-run clean.** No PR implements reference-style link OUTPUT (#98 "New Node Type for Broken
Reference Links" is CLOSED and parse-side, a different capability). No commits touch src/cm.rs since
the base commit. Maintainer position on the lane remains positive.

**Three real defects found and fixed by the review, all of the kind that sink submissions:**

1. **FP gap, description -> test direction.** Four tests assert the rendered document re-parses to
   the same thing, which meta.md only IMPLIED. Added one sentence stating it. Without this the tests
   enforce an undocumented requirement, which is the single most common reject cause.
2. **A1 API-enumeration gap.** meta.md names the `--reference-links` CLI flag but nothing asserted
   it. Added 3 CLI tests driving the real binary through `CARGO_BIN_EXE_comrak` (flag on, flag with
   `--reference-link-style text`, flag absent). meta.md now also names `--reference-link-style`.
3. **Dockerfile bug that local Docker would have caught if we had it.** The image built with
   `cargo build --all-targets`, which FAILS on pristine base comrak: `benches/progits.rs` needs
   `#![feature(test)]` and the toolchain is stable. Verified pre-existing (2 errors on an untouched
   base checkout), so it is comrak's own constraint, not ours. Switched the image to
   `cargo build --lib --bins --tests`, and confirmed that exact command succeeds offline.

**One CLI test expectation was wrong and the code was right.** The CLI emitted
`[Read More][read-more]` where the test expected the shortened `[Read More]`. Correct behaviour:
"Read More" folds to `read more`, which is not equal to the label `read-more`, so the shortened form
does not apply, while single-word "Docs" does collapse. Fixed the test, not the code.

**Dead-code audit (A2):** clean, no unused warnings on `cargo build --lib --bins --tests`.

**Final state:** 58 new tests, 650 base tests, 214 effective LOC, 5 files, meta.md 475 words ASCII.
Full clean-room re-validated after every change; flakiness 3x identical.

**Verdict on my own submission: READY TO BATCH, not ready to submit.** The pass rate is still
unmeasured, and that is the only remaining gate that matters.


### Round 1c - Dockerfile fix after a platform image-build failure (2026-08-05)

The platform image build failed at `RUN cargo install cargo2junit ...`:
`error: rustup could not choose a version of cargo to run, because one wasn't specified explicitly,
and no default is configured`.

**Root cause: wrong template.** I built the Dockerfile from the legacy Pattern A block in the
olympus-author skill (ENV RUSTUP_HOME / CARGO_HOME / PATH + chmod + symlink loop) instead of the
canonical cargo2junit Dockerfile in DOCKER.md, which states NO ENV block, NO chmod, NO symlink loop.
`olympus-base-rust` does not keep its toolchain under /root/.rustup, so overriding RUSTUP_HOME aimed
rustup at an empty directory with zero installed toolchains.

**A SECOND latent failure was hiding behind the first.** After fixing the ENV block I re-checked the
build command against the tree the platform actually builds - BASE_COMMIT + test.patch, WITHOUT
solution.patch - and `cargo build --lib --bins --tests` produced 4 compile errors there, because the
new integration test cannot compile until the solution exists. `cargo build --workspace` produces 0
on the identical tree. My earlier local check was worthless because I ran it against my finished
working tree, which had the solution in it. `--all-targets` (the version before that) was worse
again: comrak's `benches/progits.rs` needs `#![feature(test)]` and fails on stable even on a
pristine base checkout.

**Final Dockerfile is the DOCKER.md canonical, verbatim:**
`FROM olympus-base-rust` / `WORKDIR /app` / `COPY . .` /
`RUN cargo install cargo2junit && cargo fetch && cargo build --workspace` / `CMD ["/bin/bash"]`.

Re-verified after the fix, on the correct tree each time: image-build command clean on
base+test.patch; base 650 pass and new 58 pass once solution.patch is applied; test.sh unaffected by
the removed ENV block since it exports its own PATH.

**Carried back into the docs so it cannot recur:** replaced the dangerous Pattern A template in
`.claude/skills/olympus-author/SKILL.md` (it shipped the build-breaking ENV block, the solve-time
0/10 chmod, and no cargo2junit) and added both new NEVER rules to `Instructions/DOCKER.md`, each with
the measurement behind it.
