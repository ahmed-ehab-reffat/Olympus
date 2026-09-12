# Levels - tifffile OME pyramid validation

Target band: 1 to 5 solves in 10 completed platform runs. The current local
long-horizon record requires a successful-solution median of at least two
production files, 20 platform-reported agent messages, and 200 strict-effective
production LOC. The current submission form remains authoritative.

## History

| Level | Behavioral lever | Tests | Reference files / effective LOC | Successful solver median: files / messages / LOC | Platform | Verdict |
|---|---|---:|---:|---|---|---|
| L1 | Required OME SubIFD topology, multi-file ownership and lifecycle, plus recommendation-only strict factor/shape checks | 26 cases | 1 production file / 166 strict-effective additions | 1 / unavailable / 370.5 | 2/5 preliminary | abandoned after artifact revision |
| L2 | Strict area order; independent X/Y reduction and rounding; equal level counts; layout independence; success/failure companion-state symmetry | 36 cases | 1 production file / 166 strict-effective additions | not measured | 0/10 | superseded before solver calibration |
| L3 | Normalize I/O failure when a closed mapped companion cannot be reopened | 38 cases | 1 production file / 166 strict-effective additions | 1 / unavailable / 428.5 | 4/10 | completed, then superseded by requested review fixes |
| L4 | Remove an ambiguous tag promise and independently accept `NewSubFileType=5` | 39 cases | 1 production file / 166 strict-effective additions | not measured | 0/10 | superseded before solver calibration |
| L5 | Exercise mixed tile/strip independence in both base-to-child directions | 40 cases | 1 production file / 166 strict-effective additions | not measured | 0/10 | superseded before solver calibration |
| L6 | Allow sibling child levels to choose tile or strip storage independently | 41 cases | 1 production file / 166 strict-effective additions | not measured | 0/10 | superseded before solver calibration |
| L7 | Isolate strict assertion routing, global ownership, empty-series validity, tile-size independence, and unit-axis ceiling division | 46 cases | 1 production file / 166 strict-effective additions | not measured | 0/10 | superseded after fairness review found the empty-series oracle undefined |
| L8 | Remove the unfair empty-series oracle; quantify storage, shape, reduction, and strict properties across legal settings and later levels | 51 cases | 1 production file / 166 strict-effective additions | 1 / unavailable / 360 | 5/10 | completed, then superseded by run-3 gap closure |
| L9 | Retain ambiguous odd-rounding factor candidates and normalize non-I/O metadata parser failure | 53 cases | 1 production file / 166 strict-effective additions | not measured | 0/10 | superseded before solver calibration |
| L10 | Preserve a common factor when a later parent is smaller than it; remove internal companion-history wording | 54 cases | 1 production file / 172 strict-effective additions | not measured | 0/10 | withdrawn after fairness review found the factor boundary unstated |
| L11 | Remove the unfair small-parent factor boundary while retaining observable companion lifecycle wording | 53 cases | 1 production file / 166 strict-effective additions | not measured | 0/10 | superseded by companion coverage and reference performance revision |
| L12 | Cover missing companion primary mappings; derive strict factor ranges arithmetically | 54 cases | 1 production file / 196 strict-effective additions | not measured | 0/10 | superseded by optional-codec fixture fairness repair |
| L13 | Guard the optional multi-codec storage fixture while preserving every structural discriminator | 54 cases | 1 production file / 196 strict-effective additions | not measured | 0/10 | current exact version; verification and false-positive audit complete |

## Current level: L13

The Level 1 five-run sample produced two legitimate passes and three 25/26
near-passes. The successful median was one production file and 370.5
strict-effective lines, while the platform message metric was unavailable.
Level 2 used those trajectories to close area-order, independent-axis,
level-count, layout, and companion cleanup gaps, but no cold solver was run.

The latest review found that Level 2 normalized unreadable child parsing but
did not independently reach I/O failure while reopening a closed mapped
companion. L3 moves the generated companion only after OME loading has mapped
and closed it, then checks both configured validation outcomes. The reference
already catches this failure and leaves the cached handle closed.

The exact L3 reference passes 38/38 in both patch orders; pristine upstream
fails all 38 focused cases; and the bounded lane remains 702 passed and 3,548
skipped. All 40 predecessor mutants and the new reopen-I/O mutant are killed.
The five saved L1 patches replay at 36/38 or 37/38 and retain only their earlier
failures.

Direct platform-style pytest completes at 740 passed and 3,548 skipped on ARM64
and AMD64, and `python setup.py build` succeeds on both. Only `test.patch`
changed from L2; the prompt, reference, solution approach, Dockerfile, source
pin, base digest, and image IDs remain unchanged.

Changing a hidden test still changes the immutable artifact set, so L2 was
superseded at 0/10 rather than carried forward. The subsequent exact Level 3
batch completed ten runs with four legitimate passes. Exact local replay
reproduces 4/10, every baseline is 702/702, and no evaluator found an
environment blocker or unfair agent blame.

The six failures are implementation failures against explicit clauses: two
cached-frame families reject valid mapped planes, three patches omit direct
child `NextIFD` or later-IFD shape checks, and one cleanup path leaks `TypeError`
for malformed input. No run fails the unreopenable-companion probe. The focused
suite is not distorting the solve rate.

The successful-solution medians are one production file, an unavailable
platform agent-message count, and 428.5 strict-effective production lines.
Difficulty, solvability, minimum runs, and LOC pass, but the two-production-file
long-horizon signal does not. This prevents a submission-ready claim even
though the 4/10 difficulty band is healthy.

The requested review fix intentionally supersedes L3. L4 removes the vague
promise about “unrelated tag choices” while retaining the concrete tile,
strip, and compression guarantees. It also adds a separate legal bilevel
pyramid whose children use `NewSubFileType=5` (`REDUCEDIMAGE|MASK`).

The exact L4 reference passes 39/39 in both patch orders; pristine upstream
fails 39/39; and the bounded lane remains 702 passed and 3,548 skipped. Direct
pytest completes at 741 passed and 3,548 skipped, and `python setup.py build`
succeeds. All 41 established mutants were rerun and killed. The former
`{1, 3}` whitelist survivor is now mutant 42 and fails only the new value-5
case.

All ten L3 patches were replayed against L4. Each accepts the new positive
case, so their earlier outcomes become 37, 39, 38, 39, 38, 37, 28, 39, 37,
and 39 passes. These are fairness replays only; calibration restarts at 0/10
for the new immutable version.

Level 5 parametrizes mixed storage across both directions. The new
stripped-base/tiled-child parameter passes the reference and all ten saved
patches. An isolated implementation that permits only tiled-base/stripped-child
passes all 39 predecessor cases and the 702-test baseline, then fails only the
new parameter.

The exact L5 reference passes 40/40 in both patch orders; pristine upstream
fails 40/40; the bounded lane remains 702 passed and 3,548 skipped; and direct
pytest completes at 742 passed and 3,548 skipped. All 43 mutants are killed.
Level 5 starts calibration at 0/10.

Level 6 adds a mixed-sibling parameter with a tiled 32x32 child and stripped
16x16 child. The homogeneous-children mutant passes all 40 Level 5 cases and
the complete baseline, then fails only the new parameter. The reference and all
ten saved patches accept it.

The exact L6 reference passes 41/41 in both patch orders; pristine upstream
fails 41/41; the bounded lane remains 702 passed and 3,548 skipped; and direct
pytest completes at 743 passed and 3,548 skipped. All 44 mutants are killed.
Level 6 starts calibration at 0/10.

Level 7 adds five independent public boundaries. A strict-only failure must
still reach the outer assertion convention; child ownership spans all exposed
OME series; an OME marker without any valid OME series is not a structurally
valid flat OME-TIFF; legal tiled levels may choose different tile dimensions;
and strict ceiling division may keep an adjacent unit axis equal to one while
the child remains smaller than the full-resolution owner.

Each new mutant passes the other 45 focused cases and the complete 702-test
baseline, then fails only its intended probe. The exact L7 reference passes
46/46 in both patch orders; pristine upstream fails 46/46; the bounded lane
remains 702 passed and 3,548 skipped; and direct pytest completes at 748 passed
and 3,548 skipped on ARM64 and AMD64. All 49 mutants are killed. Saved Level 3
patches replay at 43, 45, 44, 45, 44, 44, 35, 46, 42, and 46. These are
historical replays, not calibration, so Level 7 starts at 0/10.

Level 8 removes the only unfair Level 7 case: the prompt does not define the
result for a repository-recognized OME marker that yields no OME series. Its
mutant now passes 51/51 and is withdrawn. The revised suite instead exercises
explicit universal clauses at later child levels, both full-resolution XY
fields, a second pixel-decoding path, and repository-valid PackBits, LZW, Zstd,
short-strip, and rectangular-tile choices.

The exact L8 reference passes 51/51 in both patch orders; pristine upstream
fails 51/51; the bounded lane remains 702 passed and 3,548 skipped; and direct
pytest completes at 753 passed and 3,548 skipped on ARM64 and AMD64. All 57
actionable mutants are killed. Each of the nine new mutants passes the other 50
focused cases and the complete baseline. Saved Level 3 patches replay at 49,
50, 49, 50, 49, 49, 40, 51, 47, and 51. These are historical replays, not
calibration, so Level 8 starts at 0/10.

The completed Level 8 run-3 batch contains five legitimate passes and five
public implementation failures among ten substantive evaluated runs. Its
successful median is one production file and 360 strict-effective additions;
the platform message metric remains unavailable. Four extra delivered bundles
are not part of that ten-run result: two have substantive but unevaluated
patches, and two stop before a tool call with empty patches. Every runner and
baseline finishes, so those early terminations are not environment crashes.

Level 9 adds two distinct public boundaries. A valid odd-rounded sequence must
retain every locally compatible factor until one series-wide factor can be
chosen, and a missing required Pixels relationship attribute must use the
configured validation result instead of leaking `KeyError`. Each new mutant
passes the other 52 focused cases and the complete 702-test lane, then fails
only its matching probe.

The exact L9 reference passes 53/53 in both patch orders; pristine upstream
fails 53/53; the bounded lane remains 702 passed and 3,548 skipped; and direct
pytest completes at 755 passed and 3,548 skipped on ARM64 and AMD64. All 59
actionable mutants are killed, and all 60 mutant trees pass the complete
pre-existing lane. The withdrawn empty-series mutant passes 53/53. Saved Level
3 patches replay at 51, 51, 50, 51, 50, 49, 42, 53, 48, and 53; all five
successful Level 8 patches pass both additions.

Changing `test.patch` makes the Level 8 5/10 result historical and starts
Level 9 at 0/10. The latest successful median still fails the two-file
long-horizon signal. The repository owns this API in one monolithic production
module, so splitting the reference or requiring another surface would be
padding rather than legitimate hardening.

Level 10 responds to two later review findings. The description now says to
reopen companions when necessary and restore their prior state without
explaining why a handle was closed. The reference and focused suite also retain
a series-wide factor across `6x6 -> 2x2 -> 1x1`, where the last parent is
smaller than a still-valid common factor. The isolated parent-bound mutant
passes the other 53 cases and all 702 pre-existing tests before failing only
that positive.

The exact L10 reference passes 54/54 in both patch orders; pristine upstream
fails 54/54; the bounded lane remains 702 passed and 3,548 skipped; and direct
pytest completes at 756 passed and 3,548 skipped on ARM64 and AMD64. All 60
actionable mutants are killed, all 61 mutation trees pass the complete
pre-existing lane, and withdrawn mutant 47 passes 54/54.

Saved Level 3 patches replay at 52, 51, 50, 51, 51, 49, 43, 53, 49, and 54.
The ten substantive run-3 patches replay at 49, 50, 52, 53, 53, 54, 48, 53,
53, and 42. Only one of the five former Level 8 passes accepts the new factor
boundary. These are trajectory replays rather than calibration. Changing the
prompt, reference, solution approach, and verifier supersedes Level 9 at 0/10
and starts Level 10 at 0/10.

Fairness review then rejected the Level 10 positive. The prompt permits floor
or ceiling rounding for odd dimensions; it does not authorize ceiling division
of an even `2x2` parent by a factor larger than that parent. The repository's
neighboring `subresolution` helper also rejects that domain. Level 11 removes
the test, restores parent-local factor candidates in the reference, and leaves
the companion wording cleanup intact. Level 10 is withdrawn at 0/10 rather
than repaired by adding a new public rule.

The exact L11 reference passes 53/53 in both patch orders; pristine upstream
fails 53/53; the bounded lane remains 702 passed and 3,548 skipped; and direct
pytest completes at 755 passed and 3,548 skipped on ARM64 and AMD64. All 59
actionable mutants are killed, all 60 retained mutation trees pass the
pre-existing lane, and withdrawn mutant 47 passes 53/53. Saved Level 3 patches
replay at 51, 51, 50, 51, 50, 49, 42, 53, 48, and 53. The ten substantive
run-3 patches preserve the Level 9 five-pass/five-failure split. Level 11 starts
at 0/10; no cold solver was launched.

Level 12 parametrizes the existing missing-primary mapping check across root
and named-companion ownership. The new companion shortcut mutant passes the
other 53 cases and all 702 pre-existing tests before failing only that
parameter. The reference also replaces dimension-proportional factor
enumeration with interval intersection. That performance repair is verified by
189,225 exhaustive small-shape comparisons and a billion-pixel range probe; no
timing requirement or implementation-specific hidden test was added.

The exact L12 reference passes 54/54 in both patch orders; pristine upstream
fails 54/54; the bounded lane remains 702 passed and 3,548 skipped; and direct
pytest completes at 756 passed and 3,548 skipped on ARM64 and AMD64. All 60
actionable mutants are killed, all 61 retained mutation trees pass the
pre-existing lane, and withdrawn mutant 47 passes 54/54. Saved Level 3 patches
replay at 52, 52, 51, 52, 51, 50, 43, 54, 49, and 54. The ten substantive
run-3 patches preserve the five-pass/five-failure split. Level 12 starts at
0/10; no cold solver was launched.

Level 13 accepts the fairness finding that the PackBits, LZW, and ZSTD writer
fixture cannot be mandatory when Imagecodecs is unavailable. The test now
follows repository policy by skipping only that fixture unless the module and
all three encoders are available. The unconditional Deflate, uncompressed,
tile/strip direction, mixed-sibling, and independent-tile-size positives remain
active, so the public storage-independence contract is not weakened.

With the frozen encoders, pristine upstream still fails 54/54 and the
reference passes 54/54 in both patch orders. With `SKIP_CODECS=1`, the
reference passes 53 runnable cases and skips one, while pristine upstream fails
those same 53 and skips one; ARM64 and AMD64 agree. All 60 actionable mutants
retain their focused failures, all 61 retained mutation trees pass the
pre-existing lane, and every saved replay score is unchanged. Level 13 starts
at 0/10; no cold solver was launched.
