# Summary - tifffile OME pyramid validation

Status: **Accepted (operator confirmed on 2026-08-08); canonical artifacts and
compact records retained, with raw solver evidence archived**.

Repository: `cgohlke/tifffile`

Pin: `940f7630df48edf8e13913962035ed80b408b5f4`

Production language: **Python**

Task type: **feature request**

The task adds opt-in, read-only validation of OME-TIFF pyramid topology. It
checks direct tag-330 ownership and strict area ordering, separation from the
primary IFD chain and OME `TiffData`, full-resolution and level consistency
across planes and companion files, and optional strict OME recommendations for
reduced-image flags, page shape, and one integer XY factor. It normalizes
malformed parser relationships to the API's return/raise convention, restores
every companion's prior open or closed state on success and failure, and does
not decode pixels or invoke `OmeXml.validate`.

The design deliberately accepts legal independent storage choices, including
different tile dimensions and tile/strip layouts across base and child levels.
Default ordering is by strictly decreasing plane area; one axis may grow
between adjacent child levels as long as every child remains below its
full-resolution owner in both axes. Strict odd-size reductions may
independently use floor or ceiling rounding per axis and step, including a unit
axis that remains one under ceiling division. The abandoned normalization idea
remains excluded because neither OME nor tifffile defines one public repair
policy.

The exact Level 13 suite has 54 focused cases. Pristine upstream fails all 54;
the reference passes 54/54 in both patch orders while the bounded repository
lane remains 702 passed and 3,548 skipped. Both orders produce the identical
complete-tree SHA-256
`c3b6b43afca13831f6d5edf8961973deffa48fa28f45b6cbb226905ec2c6e845`.
Direct `python -m pytest -q` completes at 756 passed and 3,548 skipped, and
`python setup.py build` succeeds on ARM64 and AMD64. The Dockerfile
starts from the permitted
`public.ecr.aws/d3j8x8q7/olympus-base:latest` and owns tifffile's bounded-suite
controls, fixing the predecessor's exit-137 environment failure.

The exact false-positive audit maps every public requirement to its strongest
test and kills all 60 actionable isolated mutants. The prior families cover
equal-area acceptance, per-axis child-level monotonicity, truncated level-count
comparisons, coupled odd rounding, forced layout equality, one-axis-only
reduction, and four success/failure cleanup asymmetries. Later review mutants
cover reopen-I/O normalization, a two-value `NewSubFileType` whitelist, and a
one-way mixed-layout restriction. The nine newest mutants isolate codec, tile,
and strip allowlists; first-child-only reduction, flag, axes, and nonspatial
checks; alternate pixel decoding; and ImageWidth-only base comparison. The two
Level 9 mutants greedily commit to one locally valid odd-rounding factor or
leak metadata `KeyError`. The old empty-series mutant is withdrawn because the
prompt never defined that result and still passes 54/54. The proposed Level 10
small-parent mutant and discriminator are also withdrawn after fairness review;
they are not counted in the current exact audit.

Five saved solver patches from the 26-case Level 1 predecessor were inspected
and replayed. Two legitimately passed L1 and three were 25/26 near-passes. The
successful median is one production file and 370.5 strict-effective production
lines; the platform message metric is unavailable. Under the revised 38-case
suite the former passes score 37/38 and the near-passes 36/38. These runs are
trajectory and replay evidence only.

The complete Level 3 batch in `agent-runs2` has four legitimate passes and six
implementation failures. All ten use the same prompt and 38-case suite, every
baseline is 702/702, and exact offline replay reproduces each result. None of
the failures is caused by the companion-reopen cases, an environment problem,
or an unstated requirement.

The four passing implementations use several raw-IFD and series/page
architectures. Their successful medians are one production file, 497 raw added
lines, and 428.5 strict-effective production lines; the platform agent-message
metric is unavailable. Difficulty, solvability, minimum runs, and LOC pass, but
the two-production-file long-horizon signal fails.

Level 4 applies the requested review fixes. The ambiguous “unrelated tag
choices” promise is gone, and a separate strict-positive fixture now uses
legal `NewSubFileType=5` children. It passes the reference and all ten saved L3
patches while killing the `{1, 3}` whitelist mutant. Because both `meta.md` and
`test.patch` changed, the completed 4/10 L3 batch is preserved only as
historical evidence and Level 4 calibration starts at 0/10.

Level 5 also parametrizes the mixed-storage positive across both directions:
tiled base with stripped children and stripped base with tiled children. The
new direction passes the reference and all ten saved patches. A directional
mutant passes all 39 Level 4 cases and the complete 702-test baseline, then
fails only the new parameter. Level 5 remained at 0/10 and was superseded
before solver calibration.

Level 6 adds sibling-level independence: one child is tiled and the other is
stripped. An isolated homogeneous-children mutant passes all 40 predecessor
cases and the 702-test baseline, then fails only this parameter. The reference
and all ten saved patches accept it. Level 6 remains at 0/10.

Level 7 closed several demonstrated control-flow and independence gaps but also
introduced an unfair empty-series oracle. Level 8 removes that oracle and adds
only participant-facing universal and storage-independence coverage. Exact
saved-patch replay scores are 49, 50, 49, 50, 49, 49, 40, 51, 47, and 51;
runs 8 and 10 still pass the complete revised suite. These replays consume no
cold-run budget.

The supplied Level 8 `agent-runs3` collection adds the governing trajectory
evidence. Ten substantive evaluated implementations finish at five legitimate
passes and five public-requirement failures. The successful median is one
production file, 431 raw production additions, and 360 strict-effective
additions. Two extra code-producing bundles are unscored, and two empty-patch
bundles stop before a tool call. Every baseline and focused runner completes;
the early terminations are agent/orchestration events rather than environment
crashes.

Level 9 closes the two demonstrated survivor families without changing the
prompt or reference. All five Level 8 passes accept both new cases, and exact
replay preserves the same five-pass/five-failure split. The ten saved Level 3
patches replay at 51, 51, 50, 51, 50, 49, 42, 53, 48, and 53. All 60 mutation
trees pass the complete pre-existing lane, while every actionable mutant fails
the focused suite. No cold solver was launched.

Level 10 removed the internal explanation of why companion handles are closed,
but also added a constant-factor positive across `6x6 -> 2x2 -> 1x1`. Fairness
review found that its even small-parent transition was not stated by the prompt
and conflicted with the neighboring repository helper's factor domain. That
test and matching reference expansion are withdrawn; Level 10 remains
historical at 0/10.

Level 11 retains only the observable companion reopen-and-restore wording and
returns to the fair 53-case behavior. Saved Level 3 patches replay at 51, 51,
50, 51, 50, 49, 42, 53, 48, and 53. All 60 retained mutation trees pass the
complete pre-existing lane, while every one of the 59 actionable mutants fails
the focused suite. The ten substantive run-3 implementations preserve the
Level 9 five-pass/five-failure split. No cold solver was launched.

Level 12 covers the same missing-primary requirement through the named
companion resolution branch. Its isolated shortcut passes the other 53 cases
and all 702 pre-existing tests. The reference factor calculation now derives
and intersects integer ranges rather than iterating through page dimensions;
189,225 exhaustive small-shape comparisons match the former results, and a
billion-pixel probe remains constant-size. No timing oracle or new public
performance requirement was added.

Saved Level 3 patches replay at 52, 52, 51, 52, 51, 50, 43, 54, 49, and 54.
All 61 retained mutation trees pass the complete pre-existing lane, while all
60 actionable mutants fail the focused suite. The ten substantive run-3
implementations preserve the five-pass/five-failure split. No cold solver was
launched.

Level 13 fixes the optional-codec fairness issue without changing the public
contract or reference. The PackBits/LZW/ZSTD writer fixture now follows the
repository's Imagecodecs availability policy. With codecs installed, all 54
cases run with unchanged results. With `SKIP_CODECS=1`, the reference passes
53 cases and skips only that fixture, while pristine upstream fails the same 53
and skips the same fixture on ARM64 and AMD64. Unconditional storage positives
still cover Deflate, uncompressed, tile/strip direction, mixed sibling layouts,
and independent tile dimensions.

All 60 actionable mutant failures, all 61 bounded-lane passes, and every saved
replay score remain unchanged. No cold solver was launched.

Changing the prompt and verifier supersedes Level 9 at 0/10; removing the
unfair Level 10 boundary started Level 11 at 0/10; the new artifacts start Level
13 at 0/10. The one-file successful median
cannot be improved honestly: this
public method and the relevant TIFF/OME machinery live in the repository's
single production module. Requiring another file would be implementation-shape
padding, not behavioral hardening.

Post-acceptance closeout preserves all 29 raw run directories in
`archive/tifffile-ome-pyramid-validation/agent-runs.tar.gz`. The three uploaded
ZIPs were verified as exact duplicates and removed with the expanded run
directories from the active problem folder. Canonical submission hashes and
restore instructions are recorded in the archive manifest.
