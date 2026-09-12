# Environment - tifffile OME pyramid validation

Verification date: 2026-08-07

## Immutable source and image

The package targets `cgohlke/tifffile` commit
`940f7630df48edf8e13913962035ed80b408b5f4`, the `master` head and v2026.7.31
release commit at verification time. The problem Dockerfile starts from
`public.ecr.aws/d3j8x8q7/olympus-base:latest`, which resolved during the
build to
`sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`.

The derived verification images were:

```text
olympus-tifffile-ome-pyramid:env-fix
sha256:35ed8d719b721fe8ed6b52e327b4dc5b928a2833cdb030b3d88dc19d6c02967d
linux/arm64

olympus-tifffile-ome-pyramid:env-fix-amd64
sha256:73fda2b22c93a8a73c5650508ae891ac4fffe3855e17295fcde319587b954d48
linux/amd64
```

Observed tools were Python 3.12.13, pip 26.0.1, pytest 9.0.3, and Git 2.39.5.
`python -m pip install --no-cache-dir -e ".[test]"` completed while building
the image. The Dockerfile exports tifffile's controls for large, slow,
extended, external-file, schema-validation, and HTTP tests. All verification
after the image build used `--network none`.

## Test entry points

Applying `test.patch` creates `test.sh`. It repeats the image's repository
controls for external files, HTTP, XMLSchema validation, large, slow, and
extended cases. The two public harness modes are:

```bash
./test.sh --output_path /tmp/base.xml base
./test.sh --output_path /tmp/new.xml new
```

The focused suite synthesizes all TIFF files in pytest temporary directories;
it does not fetch schemas or fixture corpora. The validator is read-only and
the tests replace pixel decoding and XMLSchema validation with failing
sentinels where architecture neutrality matters.

## Frozen patch-state verification

| State | Base result | New result |
|---|---:|---:|
| test only | 702 passed, 3,548 skipped | 54 expected failures |
| solution only | 702 passed, 3,548 skipped | not present |
| test then solution | 702 passed, 3,548 skipped | 54 passed |
| solution then test | 702 passed, 3,548 skipped | 54 passed |

Every patch passed `git apply --check`; every resulting tree passed
`git diff --check`. Test-first and solution-first produced the same
complete diff SHA-256:
`c3b6b43afca13831f6d5edf8961973deffa48fa28f45b6cbb226905ec2c6e845`.

The exact submission-artifact hashes and mutation results are recorded in
`FALSE_POSITIVE_AUDIT.md`. Host Python 3.14 has four additional optional test
passes (706 passed, 3,544 skipped); this dependency-sensitive inventory
difference is not a regression and is not substituted for the frozen image's
exact counts.

The predecessor image kept those controls only inside `test.sh`. A platform
quality check invoking `python -m pytest` directly therefore enabled tifffile's
large and extended inventories on a 64-bit runner and was killed with exit 137
near 90 percent. The current image owns the same controls, so commands that
bypass the harness remain bounded. `python setup.py build` succeeds, direct
`python -m pytest -q` completes at 702 passed and 3,548 skipped on pristine
upstream, and the same direct command completes at 727 passed and 3,548 skipped
on the predecessor combined problem tree and at 728 passed and 3,548 skipped
on the 26-case predecessor combined tree and at 738 passed and 3,548 skipped
on the 36-case predecessor combined tree, at 740 passed and 3,548 skipped on
the Level 3 tree, at 741 passed and 3,548 skipped on Level 4, at 742 passed
and 3,548 skipped on Level 5, at 743 passed and 3,548 skipped on Level 6, at
748 passed and 3,548 skipped on Level 7, and at 753 passed and 3,548 skipped
on the Level 8 tree, at 755 passed and 3,548 skipped on Level 9, at 756 passed
and 3,548 skipped on the withdrawn Level 10 tree, at 755 passed and 3,548
skipped on Level 11, and at 756 passed and 3,548 skipped on the current Level
13 tree. No command-level
environment overrides were used for those checks. The Level 4 verification
used the frozen ARM64 image; Level 13 direct pytest and build checks cover both
architectures. `python setup.py build` succeeds.

The allowed-base replacement changed only the first Dockerfile line. The image
was rebuilt with `--pull`, and the full patch-state and 20-mutant audits were
repeated for the resulting artifact version. No prior environment result is
being carried forward as current evidence.

After the four description paragraphs were reflowed without semantic changes,
the same image was used to repeat the full patch-state matrix and 20-mutant
audit offline. The matrix counts, mutant outcomes, and combined-diff hash were
unchanged. The current `meta.md` hash is recorded in
`FALSE_POSITIVE_AUDIT.md`.

The focused test file is now
`tests/test_ome_pyramid_validation_a0d7bb.py`, with its six-hex suffix generated
by `openssl rand -hex 3`. The harness base mode ignores that exact randomized
path and new mode runs it directly. After this path and prompt cleanup, the full
matrix and 20-mutant audit were repeated in fresh source copies; all counts were
unchanged and both application orders agreed for that predecessor version.

Following the fairness review, the mapping fixture was rebuilt to shift a
two-plane `TiffData` range from IFD 0 to IFD 1, making its second mapped plane
refer to nonexistent primary IFD 2. The prompt now explicitly prohibits any
`OmeXml.validate` call. The full matrix and all 20 mutants were rerun in fresh
offline source copies; counts remained unchanged and the two combined orders
agreed for that predecessor version.

The S1/T4 refreeze added per-IFD full-resolution shape, nonzero beyond-EOF
exception normalization, and reduced-image bitmask coverage. That predecessor
reference had 181 raw and 146 strict effective production additions. Fresh
source copies produced its 21-case matrix, identical combined-order hashes, and
23/23 killed mutants under `--network none`.

The multi-file refreeze added a generated two-file OME dataset whose loader
closes the secondary handle, plus secondary-only missing-child and shape
mutations. The reference now temporarily reopens each owning file and restores
its prior closed state. Fresh source copies produced that version's 24-case matrix
above, identical combined-order hashes, and 27/27 killed mutants under
`--network none`. That reference had 199 raw and 166 strict effective
production additions.

The final description-only refreeze removed a redundant owning-file summary
while retaining the precise per-file requirements and companion lifecycle.
The same frozen image repeated that predecessor's matrix and 27-mutant audit
with unchanged outcomes. The current `meta.md` hash is recorded in
`FALSE_POSITIVE_AUDIT.md`.

The strict-shape isolation refreeze replaced the combined RGB-to-grayscale
case with two cases that independently vary page axes and nonspatial sample
size. Fresh source copies produced that version's 25-case matrix in both
application orders. All 29 isolated mutants were rerun under `--network none`;
the axes-only and size-only implementations each failed only its complementary
case. The production patch, image, source pin, Dockerfile, and participant
description are unchanged.

The environment-quality refreeze moved the six existing harness controls into
the Dockerfile: `SKIP_LARGE`, `SKIP_SLOW`, `SKIP_EXTENDED`, `SKIP_FILE`,
`SKIP_VALIDATE`, and `SKIP_HTTP`. The image was rebuilt with `--pull`; the base
digest remained unchanged. In addition to the direct quality checks above,
fresh source copies repeated the four patch states and both application orders,
and all 29 mutants were rerun under `--network none`. The matrix, mutation
outcomes, and combined source-tree hash remain unchanged. The current
Dockerfile hash and architecture-specific image IDs are recorded in
`FALSE_POSITIVE_AUDIT.md`.

The companion-state symmetry refreeze clarifies the participant requirement
as restoration of each companion's prior open or closed state and parametrizes
the existing generated multi-file fixture across both starting states. The
reference patch and image did not change. Fresh source copies produced that
predecessor's 26-case matrix, and all 30 isolated mutants were rerun under
`--network none`; the new unconditional-close mutant failed only the open case.
Both combined application orders produced that version's identical diff, and
direct pytest completed at 728 passed and 3,548 skipped on ARM64 and AMD64.

The five-run gap-closure refreeze clarifies strict area ordering, independent
odd-axis rounding and base/child storage layout, and companion restoration on
both failure modes. It adds asymmetric level-count, both-axis reduction, valid
area-order, mixed-rounding, mixed-layout, and failure-lifecycle cases. The
reference and Docker image remain unchanged. Fresh source copies produced that
predecessor's 36-case matrix, and all 40 isolated mutants were rerun under
`--network none`. Both combined application orders produced that version's
identical diff. Direct pytest completed at 738 passed and 3,548 skipped on
ARM64 and AMD64, and `python setup.py build` succeeded on both architectures.

The unreopenable-companion refreeze adds two parameter instances that move a
mapped companion after OME loading has closed its cached handle. The prompt,
reference, solution approach, Dockerfile, source pin, and images remain
unchanged. Fresh source copies produced that version's 38-case matrix and
killed all 41 isolated mutants under `--network none`. Both patch orders
produced that version's identical diff hash. Direct pytest completed at 740 passed
and 3,548 skipped on ARM64 and AMD64, and `python setup.py build` succeeded on
both architectures.

The ten Level 3 platform bundles use that exact 38-case file. Their JUnit
records all report 702/702 baseline tests, with focused results of 36, 38, 37,
38, 37, 36, 27, 38, 36, and 38 passes. Every evaluator environment assessment
reports no blocker. Applying each saved solver patch to fresh pinned source and
running the focused file under `--network none` reproduces all ten results
exactly. Those results are now historical calibration evidence.

The Level 4 review refreeze removes one ambiguous prompt promise and adds a
strict-positive bilevel pyramid with `NewSubFileType=5`. Fresh source copies
repeat the four patch states and both application orders under `--network
none`: pristine fails 39/39, the reference passes 39/39, and the bounded lane
remains 702 passed and 3,548 skipped. Direct combined pytest completes at 741
passed and 3,548 skipped, and the build succeeds. All 42 mutants are killed,
including the former `{1, 3}` whitelist survivor. Replaying all ten Level 3
patches gives 37, 39, 38, 39, 38, 37, 28, 39, 37, and 39 passes; every patch
accepts the new positive case.

The Level 5 refreeze parametrizes mixed tile/strip storage in both directions.
Fresh source copies reproduced that version's 40-case matrix in both patch
orders. All 43 mutants are killed; the new directional-layout mutant passes
the 39 predecessor cases and all 702 baseline tests, then fails only the
stripped-base/tiled-child parameter. Direct combined pytest completes at 742
passed and 3,548 skipped, and the build succeeds under `--network none`.
Every saved Level 3 patch accepts the new parameter.

The Level 6 refreeze adds a mixed-sibling storage parameter. Fresh source
copies reproduced that version's 41-case matrix in both patch orders. All 44
mutants are killed; the homogeneous-children mutant passes all 40 predecessor
cases and the full baseline before failing only the new parameter. Direct
combined pytest completes at 743 passed and 3,548 skipped, and the build
succeeds under `--network none`. Every saved patch accepts the new case.

The Level 7 refreeze adds five independent probes for strict assertion
routing, ownership across OME series, an OME marker with no exposed OME
series, legal independent tile dimensions, and unit-axis ceiling division.
Fresh source copies reproduced that version's 46-case matrix in both patch
orders. All 49 mutants are killed; each new mutant passes the other 45 cases
and the complete 702-test baseline before failing its intended probe. Direct
combined pytest completes at 748 passed and 3,548 skipped on ARM64 and AMD64,
and `python setup.py build` succeeds on both under `--network none`. The ten
saved Level 3 patches replay at 43, 45, 44, 45, 44, 44, 35, 46, 42, and 46.
No cold solver was launched.

The Level 8 refreeze removes the unfair empty-series oracle and adds universal
later-child coverage, full-resolution Y agreement, alternate pixel-decoding
sentinel coverage, and a valid PackBits/LZW/Zstd pyramid with rectangular tiles
and a short strip. Fresh source copies reproduce the current 51-case matrix in
both patch orders. The 57 actionable mutants are killed; the nine new mutants
each pass the other 50 cases and all 702 baseline tests before failing only
their intended probe. The withdrawn empty-series mutant passes 51/51 because
its only behavioral difference is now outside the public contract.

Direct combined pytest completes at 753 passed and 3,548 skipped on ARM64 and
AMD64, and `python setup.py build` succeeds on both under `--network none`.
The ten saved Level 3 patches replay at 49, 50, 49, 50, 49, 49, 40, 51, 47,
and 51. No cold solver was launched.

The Level 9 refreeze adds two generated cases without changing the prompt,
reference, Dockerfile, source pin, or image. Fresh source copies reproduce the
53-case matrix above in both patch orders. The complete diff hash is identical
between orders, direct combined pytest completes at 755 passed and 3,548
skipped on ARM64 and AMD64, and `python setup.py build` succeeds on both.
`setup.py check`, `pip check`, `compileall`, `bash -n`, and collection of all 53
cases also succeed under `--network none`. Black and Ruff are not installed in
the frozen image, so their optional checks are recorded as unavailable.

All 60 mutation trees pass the 702-case bounded lane. The 59 actionable
mutants fail the focused suite, while the withdrawn empty-series mutant passes
53/53. Both new mutants are isolated at 52/53. All ten saved Level 3 patches
and all fourteen delivered run-3 bundles apply or replay cleanly against the
exact file; every pre-existing lane passes, including solver-authored tests.

The two run-3 bundles described as crashes contain no tool call or solution
patch, but their baseline and focused runner logs complete normally. Direct
quality pytest also completes in the frozen image. They are agent/orchestration
early terminations rather than an environment or resource failure, so neither
the Dockerfile nor `test.sh` required a change.

The Level 10 refreeze changed the participant wording, reference factor domain,
solution approach, and generated focused file. Its later-parent positive was
subsequently found unfair because the public prompt only relaxes odd-dimension
division and the repository's neighboring helper rejects a factor larger than
the current parent. Level 10 is withdrawn; its successful environment checks
remain historical evidence only.

Level 11 keeps the observable companion wording and removes that test,
reference expansion, and mutant. Fresh source copies reproduce the 53-case
matrix above in both patch orders, whose complete diff hash is identical.
Direct combined pytest completes at 755 passed and 3,548 skipped on ARM64 and
AMD64. Build, package check, dependency check, compileall, shell syntax, and
collection of all 53 cases succeed on both architectures under `--network
none`; Black and Ruff remain unavailable in the image.

All 60 retained mutation trees pass the 702-case bounded lane. The 59
actionable mutants fail the focused suite, while withdrawn mutant 47 passes
53/53. All ten Level 3 and fourteen run-3 replay trees pass their complete
pre-existing lanes, including solver-authored tests. No cold solver was
launched and no environment artifact changed.

Level 12 adds one companion primary-mapping parameter and replaces the
reference's dimension-proportional factor enumeration with interval arithmetic.
Fresh source copies reproduce the 54-case matrix above in both patch orders,
whose complete diff hash is identical. Direct combined pytest completes at 756
passed and 3,548 skipped on ARM64 and AMD64. Build, package check, dependency
check, compileall, shell syntax, and collection of all 54 cases succeed on both
architectures under `--network none`; Black and Ruff remain unavailable in the
image.

All 61 retained mutation trees pass the 702-case bounded lane. The 60
actionable mutants fail the focused suite, while withdrawn mutant 47 passes
54/54. All ten Level 3 and fourteen run-3 replay trees pass their complete
pre-existing lanes, including solver-authored tests. Exhaustive arithmetic
equivalence checks cover 189,225 shape combinations, and the large-dimension
probe completes using one factor interval. No cold solver was launched and no
environment artifact changed.

Level 13 guards the optional PackBits, LZW, and ZSTD storage fixture using the
same Imagecodecs availability policy as the repository's visible tests. With
the frozen encoders installed, the normal 54-case results above are unchanged.
With `SKIP_CODECS=1`, the reference passes 53 runnable cases and skips only the
codec fixture, while pristine upstream fails those same 53 cases and skips the
same fixture. ARM64 and AMD64 reproduce the same no-codec result.

Both patch orders, all 61 retained mutation trees, every saved replay, the
702-case bounded lane, direct pytest, build, package, dependency, compilation,
shell, and collection checks were rerun for the exact Level 13 artifacts. No
environment artifact changed and no cold solver was launched.
