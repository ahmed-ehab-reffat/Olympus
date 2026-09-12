# Design - tifffile OME pyramid validation

Status: `Level 13 optional-codec fixture fairness repair verified;
exact-version false-positive audit complete; calibration is 0/10`.

Repository: `cgohlke/tifffile` at
`940f7630df48edf8e13913962035ed80b408b5f4` (`master`, 2026-08-01).

Production language: Python. Task type: feature request.

## Public contract and repository evidence

The retained task is read-only validation of
[OME-TIFF pyramid topology](https://docs.openmicroscopy.org/ome-model/6.3.1/ome-tiff/specification.html#sub-resolutions).
The original deterministic-normalization idea is excluded: OME specifies how
sub-resolutions are represented but does not prescribe how a reader should
repair conflicting page chains, metadata, dimensions, or tags. Validation can
have a public oracle without inventing a rewrite policy and never mutates or
rewrites the source file.

The frozen repository-shaped API is:

```python
TiffFile.validate_ome_pyramid(
    *, strict: bool = False, assert_: bool = True
) -> bool
```

It deliberately follows `OmeXml.validate(..., assert_=True)`: success returns
`True`; failure raises `AssertionError`, or returns `False` when `assert_` is
false. A non-OME TIFF is not an OME pyramid and fails validation. A
structurally valid OME-TIFF without sub-resolutions succeeds. Malformed or
unreadable pyramid relationships are validation failures rather than leaked
parser exceptions. Validation is deterministic and offline, does not call
`OmeXml.validate`, and does not alter file bytes.

Default validation covers the OME storage requirements:

- every full-resolution plane represented by an OME image series is present,
  remains on its file's primary IFD chain, and therefore retains its OME
  `TiffData` mapping;
- OME image series may span companion TIFF files; primary-chain membership,
  SubIFD ownership, and topology are evaluated in each plane's owning file;
- each companion filehandle returns to its prior open or closed state after
  successful validation and either configured validation-failure outcome;
- every sub-resolution is listed directly by its full-resolution plane's TIFF
  tag 330 (`SubIFDs`), rather than reached only through a child `NextIFD`
  chain, with offsets strictly ordered by decreasing plane area;
- a sub-resolution offset is neither in the primary IFD chain nor, as a
  consequence, addressable by OME `TiffData`;
- each sub-resolution has exactly one full-resolution owner; and
- every base plane in an OME image series has the same full-resolution XY
  shape, exposes the same number and XY shape of sub-resolution levels, and
  has children smaller in X and Y rather than unrelated images. An individual
  axis need not decrease between consecutive children when their areas remain
  strictly decreasing.

`strict=True` additionally checks the specification's recommendations: page
axes and nonspatial dimensions stay unchanged, X/Y use one common integer
downsampling factor throughout each image series, consecutive levels retain
that factor, and each pyramidal IFD has the reduced-image bit (`1`) set in
`NewSubFileType` 254. Other bits may also be set. Odd dimensions use the same
floor-or-ceiling tolerance already established by tifffile's public
`subresolution` helper. Each axis and step chooses floor or ceiling
independently; strictness does not imply exact divisibility. Different OME
image series may use different factors. Legal tile, strip, compression, and
unrelated-tag choices remain independent between full-resolution and child
IFDs.

The implementation may parse raw OME `TiffData`, inspect `TiffPage.subifds`,
walk `TiffFile.pages`, or reconcile `TiffPageSeries.levels`. It may share or
avoid `series_ome`, `subresolution`, and `pyramidize_series`. Tests may require
only the public result and exception behavior, never a helper layout or a
specific traversal architecture.

Repository evidence supplies a strong oracle. `TiffPage` exposes `subifds`,
`is_subifd`, and `is_reduced`; `TiffFile` exposes the primary page chain and
OME metadata; `TiffPageSeries` exposes shapes, axes, dtype, pages, and levels.
The writer already documents that OME SubIFDs must be sub-resolutions and
requires matching page counts per written level. The existing
`subresolution` helper enforces axes/dtype compatibility and floor-or-ceiling
spatial reduction, while `pyramidize_series` expects ordered, constant-factor
levels. The feature therefore validates relationships the library already
models instead of adding an alien abstraction.

## Confirmed behavioral gap

A pristine-pin probe generated five tiny OME-TIFFs using `TiffWriter`, reopened
them with tifffile, and requested the OME series with levels. The valid
64x64 -> 32x32 -> 16x16 pyramid was accepted as expected. The current reader
also accepted all four malformed or non-recommended structures without a
validation result:

| Probe | Generated levels | Pristine behavior |
|---|---|---|
| missing reduced-image bit | 64x64 -> 32x32 -> 16x16, first child tag 254 = 0 | accepted; reduced flags were false, false, true |
| anisotropic factor | 64x64 -> 32x16 -> 16x8 | accepted |
| changing factor | 64x64 -> 32x32 -> 8x8 | accepted |
| reverse size order | 64x64 -> 16x16 -> 32x32 | accepted |

This is not a claim that ordinary reading should fail. It establishes the
missing opt-in validation capability and gives four independently observable
strict/topology boundaries. Primary-chain aliasing, direct reachability,
unique ownership, and per-plane count disagreement were subsequently exercised
as generated structural probes, not represented as observed upstream bugs.

## Mandatory trajectory-informed startup gate

Before this design was recorded, searches covered `problems/README.md`,
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, dated candidate reports,
problem/archive Markdown records, and raw-run indexes for `tifffile`,
`OME-TIFF`, `SubIFD`, pyramids, TIFF topology, page chains, ordered offsets,
format validation, and normalization.

No tifffile problem, implementation, calibration run, or solver trajectory
exists locally. The closest same-format compact record is the rejected
`geotiffjs/geotiff.js` nested-SubIFD candidate. It scored 4/10 because open
[geotiff.js issue #524](https://github.com/geotiffjs/geotiff.js/issues/524)
owns traversal and a broader task would aggregate range,
parse, abort, endian, and writer gaps. That record reinforces keeping this task
to tifffile's unowned, read-only OME validation surface; it is not evidence for
a private repair or recursive-reader implementation.

The closest representative raw solver evidence is the accepted
PcapPlusPlus PCAPNG problem. Its archive manifest, raw trajectories, production
patches, logs, and evaluations were inspected because it also separates
ordered container structure from optional records:

| Evidence role | Raw run | Recorded outcome | Architecture and lesson carried forward |
|---|---|---|---|
| legitimate pass | `archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz`, `agent-runs4/Nova_Nova_6` | The saved platform evaluation passed its then-current 14/14 focused cases; exact retrospective L6 replay passed 16/16. The patch added 416 raw production lines across the public header and existing implementation file; a strict effective count was not preserved. | A section-aware scanner in `PcapFileDevice.cpp` fixed framing and section/interface state before selection, staged destination replacement, and deferred option validation until after a packet matched. Its platform message reported closed/open-state, cursor, exact-copy, malformed-input, and full offline checks. Validate OME topology before interpreting recommendations, and preserve opaque TIFF contents. |
| near-pass | same archive, `agent-runs4/Nova_Nova_1` | The saved platform evaluation passed its then-current 14/14 focused cases; exact retrospective L6 replay passed 15/16. The patch added 539 raw production code lines plus one build-list line; a strict effective count was not preserved. | A new streaming `PcapNgFileCopy.cpp` tracked section state and temporary publication, but eagerly validated options on a packet that public behavior discarded. Its platform message also surfaced unavailable optional Zstd verification instead of hiding it. Do not make unrelated tag payloads, compression, or pixel contents prerequisites for topology validation. |
| broad failure | same archive, `agent-runs4/Nova_Nova_3` | The saved platform evaluation passed 10/14 focused cases and failed four valid Decryption Secrets Block cases; exact retrospective L6 replay passed 11/16. The patch added 455 raw production code lines plus one build-list line; a strict effective count was not preserved. | A dedicated scanner mixed optional-block assumptions with otherwise sound per-section framing and temporary replacement. Its platform message reported only its own broader no-network suite, missing the independent failures. Use one consistent offset identity across the primary chain, OME references, and SubIFD ownership, while keeping recommendation-only checks isolated. |

These trajectories are analogous design evidence only. No PCAPNG fixture,
hidden assertion, scanner, or implementation is copied. OME pyramid validation
is read-only, standard-backed, and operates on page/series relationships rather
than publishing a filtered binary file.

### Review-triggered gate refresh - 2026-08-06

Before revising the focused tests for the S1/T4 review, local history and raw
trajectory searches were repeated for `TiffFrame`, keyframes, per-plane base
shape, unreadable nonzero offsets, parser exception normalization,
`NewSubFileType`, bitmasks, and combined public bits. No tifffile solver
trajectory exists, so the previously inspected PcapPlusPlus pass, near-pass,
and broad failure remain the only relevant raw trajectory analogs. They support
separating structure from opaque contents and normalizing malformed container
relationships, but they do not determine these TIFF-specific assertions.

Repository and review evidence supplies the new discriminators. A later OME
plane may be represented by `TiffFrame`, whose public `shape` delegates to its
keyframe; substituting `base.keyframe` can therefore hide that plane's own
ImageWidth/ImageLength tags. `TiffPage` construction can raise while following
a nonzero tag-330 offset beyond EOF, which exercises exception normalization
beyond the existing zero-offset range check. Finally, `TiffPage.is_reduced`
uses `bool(self.subfiletype & 0b1)`, proving that strict validation must test a
bit rather than require the complete `NewSubFileType` value to equal one.

### Multi-file review gate refresh - 2026-08-06

Before revising tests for the multi-file review, the required local searches
were repeated across `problems/README.md`, the candidate indexes and success
record, current and archived design/audit/run records, and raw-run member
indexes for multi-file OME, companion TIFF, secondary filehandles, UUID file
mappings, per-file ownership, and pyramid topology. No tifffile solver or
calibration trajectory exists. The same PcapPlusPlus legitimate pass,
near-pass, and broad failure were re-inspected from their raw evaluation,
run, trajectory, and production-patch members. They continue to support
per-container state and avoiding root-only shortcuts, but do not prescribe a
TIFF filehandle implementation.

Repository evidence directly supplies the new boundaries. Existing
`test_read_ome_multifile_pyramidal` documents a pyramidal OME series spanning
35 TIFF files and verifies that secondary filehandles are closed after series
construction and reading. In `_series_ome`, each `TiffData/UUID` opens its
named companion, loads its pages into the root file's `_files` cache, and then
calls `ftif.close()`. `FileHandle` explicitly supports reopening closed files.
Consequently a validator must use the `parent` of every mapped page as the
offset namespace and must obtain readable access while inspecting that
parent's primary chain and SubIFDs. Looking only at the initially opened TIFF
misses invalid secondary topology; treating offsets as global falsely merges
equal numeric offsets from separate TIFFs; and dereferencing a closed
companion handle falsely rejects a valid multi-file pyramid.

### Description-redundancy gate refresh - 2026-08-06

Before removing the review-flagged summary clause, the required local searches
were repeated for tifffile/OME problem history, description-format revisions,
owning-file and offset-identity requirements, bounded-suite evidence, and exit
137 reports. No tifffile solver trajectory or new behavioral evidence exists.
The PcapPlusPlus legitimate pass, near-pass, and broad failure evaluations and
run records were re-inspected from the raw archive; they do not make the
redundant wording necessary.

The removed clause only summarizes requirements stated immediately afterward:
per-file primary-chain presence, direct and unique tag-330 ownership, ordered
offsets, and cross-plane shape consistency. The companion-file sentence and
the requirement to restore a previously closed companion remain explicit. No
public behavior, black-box oracle, discriminator-ledger entry, test, or
reference behavior changes, so the existing ledger remains the resulting
ledger for this prompt-only refreeze.

### Strict-shape isolation gate refresh - 2026-08-06

Before splitting the review-flagged strict fixture, the required local searches
were repeated for tifffile/OME problem history, page-axis and nonspatial-shape
tests, `planarconfig`, RGB samples, and prior solver shortcuts. No tifffile
solver trajectory exists. The representative raw PcapPlusPlus trajectories
were re-inspected: Nova_Nova_6 is the legitimate pass, Nova_Nova_1 is the
near-pass analogue, and Nova_Nova_3 is the broad-failure analogue. They provide
only the general lesson that independently stated boundaries need independent
oracles; none contains a tifffile implementation or fixture to copy.

Repository inspection establishes two independent public constructions.
Contiguous RGB and separate-planar RGB pages can expose `YXS` and `SYX` while
retaining the same three-sample nonspatial dimension. Contiguous RGB and RGBA
pages can both expose `YXS` while changing that dimension from three to four.
The existing RGB-to-grayscale case changed both properties, so it could not
distinguish an axes-only validator from a nonspatial-size-only validator. The
public description already states both strict invariants separately; this
refresh therefore splits the oracle and mutant families without changing the
prompt or reference behavior.

### Companion-state symmetry gate refresh - 2026-08-07

Before revising the prompt and focused test for the open-companion review, the
required searches were repeated across the problem and candidate indexes,
current tifffile records, archived run manifests, companion lifecycle terms,
and prior-state restoration. No tifffile solver or calibration trajectory
exists. The raw PcapPlusPlus legitimate pass, near-pass, and broad failure were
re-inspected through their evaluation, report, trajectory, and patch signals.
Those runs independently show that open-state and cursor preservation are
observable lifecycle boundaries, but they do not supply a TIFF fixture or
implementation to copy.

Repository evidence supplies the exact discriminator. `FileHandle.open()` is
idempotent for an open handle, `FileHandle.close()` changes owned handles to the
closed state, and the reference records `was_closed` before temporary access.
The current multi-file test starts only from the loader's closed companion, so
an implementation that closes every companion in `finally` survives despite
changing an already-open caller-visible handle. The new oracle explicitly
opens the cached companion before validation and observes that it remains open
afterward. This is the complementary open-state half of the public lifecycle
contract, not another topology or companion-layout fixture. The participant
wording is clarified to say “prior open or closed state” so the oracle is
unambiguous.

After that gate was recorded, the paired fixture passed 26/26 with the
reference. The isolated unconditional-close mutant passed 25/26 and failed
only the already-open case. The complete 30-mutant refreeze, exact patch-state
matrix, and immutable artifact hashes are recorded in
`FALSE_POSITIVE_AUDIT.md`.

### Five-run review and gap-closure gate refresh - 2026-08-07

Before revising the participant contract or hidden tests, the required searches
were repeated across the problem and candidate indexes, success records,
current design and audit records, repository tests and helpers, and the raw
`agent-runs/Nova_Nova_1` through `Nova_Nova_5` bundles. Each run's evaluation,
test log, source patch, workspace diff, and ATIF trajectory were inspected. The
exact predecessor artifact had participant/test/reference/Docker/approach
SHA-256 values `9306ae5c607d`, `b506ebd6dcee`, `e78e24634b8b`,
`d7a789bda59c`, and `dae8db869900` respectively.

The predecessor produced two legitimate passes and three 25/26 near-passes:

| Evidence role | Raw run and outcome | Production shape and approach | Design consequence |
|---|---|---|---|
| legitimate pass | `Nova_Nova_2`, run `rd7cde74rqbd8k5rmyjx8jf0d58bz9tk`: 702/702 evaluator baseline and 26/26 focused | One production file, 326 raw and 264 strict-effective additions, plus 62 test lines. It materialized mapped pages, cached per-file primary chains, parsed direct children, intersected factor ranges, and restored known/discovered file states in `finally`. | Preserve series/page-oriented implementations. Its `area > previous_child_area` check nevertheless accepts equal adjacent areas despite the word “strictly,” supplying a trajectory-backed order mutant. |
| legitimate pass | `Nova_Nova_4`, run `rd7a7kcqrfnfp10ba8ncx34ndd8bzd66`: 702/702 baseline and 26/26 focused | One production file, 550 raw and 477 strict-effective additions, no added tests. It parsed OME mappings, cached owning-file identities and primary pages, restored both handle state and cursor, and normalized parser failures. | Preserve raw-XML-first and stronger cursor-preserving architectures. Its adjacent-area comparison also permits equality, independently confirming the same public shortcut. |
| near-pass | `Nova_Nova_1`, run `rd757zgchcdc5xg2rd2engn5618bys56`: 25/26 focused | One production file, 475 raw and 411 strict-effective additions, plus 61 test lines. It built a raw OME plane map and per-file caches, but rejected nested tag 330 only and omitted a child's `NextIFD`. | The existing direct-reachability discriminator remains useful and fair. |
| near-pass | `Nova_Nova_3`, run `rd7fz60bq6rbz86531errfvwrh8bzky6`: 25/26 focused | One production file, 367 raw and 317 strict-effective additions, plus 79 test lines. It used exposed OME series, explicit page reads, factor ranges, and global state restoration, but also omitted child `NextIFD`. | A recurring missed branch supports retaining, not multiplying, the direct-tag probe. |
| near-pass | `Nova_Nova_5`, run `rd7ej7m7p18a7gevw9ak50nwcx8bzys3`: 25/26 focused | One production file, 346 raw and 271 strict-effective additions, plus 78 test lines. It used the series/page seam and proactive open/closed tests, but replaced later `TiffFrame` planes with their keyframe when reading full-resolution dimensions. | The existing per-IFD base-shape discriminator remains useful and architecture-neutral. |
| broad failure | unavailable | Every failing run passed 25/26; no run failed several independent behaviors. | Do not relabel a near-pass as a broad failure or import an unrelated trajectory. |

The ATIF bundles contain one final agent envelope with 59-89 embedded tool
calls per run. That schema does not expose the platform's agent-message metric,
so neither the four recorded ATIF steps nor tool-call counts are substituted
for it. The successful-solution median is one production file and 370.5
strict-effective production lines. Thus the predecessor's 2/5 result is a
healthy preliminary difficulty signal and clears the LOC forecast, but does not
establish the two-production-file or message horizons and is not a completed
ten-run batch. This artifact revision abandons that batch at 2/5 and restarts
calibration at 0/10; the five patches remain replay evidence only.

Repository and review evidence identifies seven actionable refinements. The
successful patches independently demonstrate that “ordered” can be
misimplemented as non-increasing area, so equal adjacent areas need one invalid
oracle. The current one-axis fixture leaves the other half of the explicit X/Y
conjunction unobserved. A zip/truncation implementation can ignore an extra
level on a later base plane even though level counts must match. Success-only
companion tests do not exercise restoration while either public failure mode is
unwinding. The invalid reverse-order fixture can encourage per-axis monotonicity
although default order is strictly by plane area and each child only needs to
remain below the full-resolution owner in X and Y. `subresolution` accepts
floor or ceiling independently for each spatial axis, while existing odd cases
choose the same direction. Finally, `TiffWriter` selects tile or strip storage
per IFD and the public contract makes encoding opaque; a mixed base/child
layout is therefore materially different from merely adding another
compression value. That last evidence supersedes the earlier rejection of all
additional tile/strip probes.

Each refinement changes one public relationship or exercises a distinct
success/failure control-flow boundary. BigTIFF, byte order, more filenames,
additional compression codecs, repeated handle toggles, and extra geometric
permutations remain rejected as duplicate fixtures. The existing reference
already implements all seven behaviors, so no private reference architecture
is being elevated into the contract.

### Unreopenable-companion gate refresh - 2026-08-07

Before changing the hidden suite, searches were repeated across the problem
and candidate indexes, this problem's design, run, audit, and environment
records, tifffile's `FileHandle` implementation, and all five raw Level 1 run
bundles. The legitimate passes remain Nova 2 and Nova 4, the three unsuccessful
runs remain near-passes, and a broad failure remains unavailable. No run is
relabeled or replaced.

The raw implementations reinforce the public boundary without prescribing one
catch layout. Nova 2 and Nova 4 open cached companions inside their validation
flow and normalize broad exceptions before restoring handle state. Near-passes
Nova 1, Nova 3, and Nova 5 independently use the same broad normalization
around parser and companion I/O work; their recorded failures concern other
invariants. None proactively makes a companion unavailable after OME loading,
so the saved 26-case results do not establish this oracle.

Repository evidence supplies the distinct failure mode. `FileHandle.open()`
reopens a named closed handle with Python's built-in `open`, which can raise
`OSError` when the path disappears or becomes inaccessible. Existing malformed
coverage reaches `TiffPage` parsing through an out-of-file child offset, while
existing companion coverage always leaves the secondary path readable. A
validator that normalizes `TiffFileError` or shape failures but lets this reopen
exception escape therefore passes every Level 2 case despite violating the
already-public rule for malformed or unreadable pyramid relationships.

The new black-box oracle loads a generated multi-file OME series, confirms that
the repository has closed its cached companion, moves the companion path out of
reach, and invokes both configured failure modes. The expected observations are
`False` and `AssertionError`, with no leaked I/O exception and the cached handle
still closed. This tests availability at the file-access boundary rather than a
private helper, exception message, or monkeypatched method. The participant
description and reference behavior already cover it, so only the hidden test
and exact-version verification need revision. This creates Level 3 at 0/10;
the five saved patches remain replay evidence only and no cold solver is
authorized.

### Ten-run Level 3 calibration audit - 2026-08-07

The second raw bundle set, `agent-runs2/Nova_Nova_1` through
`Nova_Nova_10`, was inspected after the complete batch arrived. Every
evaluation, JUnit file, test log, source patch, workspace diff, run record, and
ATIF trajectory was read. All ten runs contain the same 655-line hidden test
content with SHA-256 `dc0b1d817ce0fa4eb17e9c1f102d7c48caba2e6e8b753931610a93ab385f4cff`
and the same rendered participant prompt with SHA-256
`38a0eea5fae50f7ea9c91a0b26caf4ef6eac77d26e98381acfe76532c8e59b70`.
The suite has 38 cases in every JUnit record and corresponds to the exact
Level 3 artifact hashes in `FALSE_POSITIVE_AUDIT.md`.

The batch supplies all three trajectory roles:

| Evidence role | Representative raw run | Architecture, timing, and proactive checks | Design conclusion |
|---|---|---|---|
| legitimate pass | Nova 2, `rd76rwb09v3hjmheaeft5h76bx8c1aar`, 38/38 focused and 702/702 baseline | One production file with 504 raw and 448 strict-effective additions. It parsed OME mappings and IFD tags, cached per-file primary offsets, normalized all validation exceptions, restored file states in `finally`, and added repository tests for valid, flat, invalid, chained, and companion cases. | Low-level tag parsing is a legitimate architecture. It uses `value & 1` for `NewSubFileType` and does not restrict unrelated tags. |
| near-pass | Nova 3, `rd734bk81y2mz8veg37zqp6jxh8c1f9n`, 37/38 focused and 702/702 baseline | One production file with 511 raw and 412 strict-effective additions. It implemented mapping, shape, companion, strict-factor, and cleanup logic but checked nested tag 330 without checking a child's `NextIFD`. Its own tests did not include the repository's chain form. | The direct-child discriminator kills a recurring, public topology shortcut rather than a private implementation choice. |
| broad failure | Nova 7, `rd779wp2zwq53jbmhz6n626p7h8c1k8b`, 27/38 focused and 702/702 baseline | One production file with 356 raw and 270 strict-effective additions. It called `_get_series('ome')`, then assumed changing `useframes` replaced already cached `TiffFrame` objects. Broad exception handling converted the resulting missing-tag errors into false results for valid multi-plane files. | Valid multi-plane and multi-series positives are necessary to prevent a root/keyframe-only implementation from appearing structurally conservative. |

Nova 4, Nova 8, and Nova 10 provide three additional legitimate passes using
series/page and raw-IFD variants. Nova 1 and Nova 9 repeat cached-frame or
keyframe mistakes, Nova 5 repeats the direct-child omission, and Nova 6 leaks a
cleanup `TypeError` on malformed inputs. Exact offline replay reproduced every
38-case result: four passes, two 37/38 near-passes, three 36/38 failures, and one
27/38 broad failure. Every evaluator reports a deterministic suite, clear
description, no environment blocker, and no unfair agent blame.

No failure is caused by the Level 3 companion-reopen test. All ten patches also
pass two additional audit-only positive probes: a fully legal bilevel pyramid
whose child `NewSubFileType` is `REDUCEDIMAGE|MASK` (`5`), and a pyramid carrying
a private tag 65000 on every IFD. The four successful implementations all use
general bitmask semantics naturally. A synthetic `{1, 3}` whitelist mutant
passes the focused suite, but it is rejected as a test-value-specific mutant:
no trajectory or repository path motivates that whitelist, the repository's
public `is_reduced` masks bit zero, and the proposed value-5 probe contributes
no observed solver discrimination. The undefined phrase “unrelated tag
choices” remains a description-quality concern, but the representative private
tag probe shows it did not create a false-negative calibration result.

The 4/10 solve rate satisfies difficulty, solvability, and minimum-run gates.
Successful patches have a median of one production file, 497 raw added lines,
and 428.5 strict-effective production lines. The ATIF schema exposes four
envelope steps rather than the platform agent-message measure, so that measure
remains unavailable. The one-file median fails the long-horizon file signal;
this is a submission-readiness issue, not evidence that hidden tests distorted
the batch. Changing the prompt or tests to address a noncritical review warning
would abandon all ten results and start a new level at 0/10.

### Level 4 review-fix gate - 2026-08-07

The operator explicitly requested promotion of both remaining review concerns
after the completed Level 3 audit. The evidence remains the ten raw Level 3
trajectories summarized above, the repository's `TiffPage.is_reduced` bitmask
implementation, and the synthetic `{1, 3}` whitelist mutant. All ten solver
patches naturally mask bit zero and accept a legal value-5 probe, so the change
does not respond to a solver failure. It closes an independently stated public
boundary and removes ambiguous participant-facing wording.

The Level 4 discriminator ledger therefore has two deliberate changes. The
prompt no longer promises acceptance of undefined “unrelated tag choices”; it
retains only concrete tile, strip, and compression guarantees. The focused
suite adds one strict-positive bilevel pyramid whose children set
`REDUCEDIMAGE|MASK` (`NewSubFileType=5`). That probe passes the unchanged
reference and fails the `{1, 3}` whitelist without prescribing how the tag is
read. No private-tag test is added because the corresponding public promise was
removed.

Changing `meta.md` and `test.patch` creates Level 4 at 0/10. All ten Level 3
patches were replayed against the 39-case file and accept the new case; those
replays are fairness evidence only, not calibration for the revised artifact.

### Level 5 mixed-layout direction gate - 2026-08-07

A human-review completeness pass identified that Level 4 demonstrates storage
independence only with a tiled full-resolution IFD and stripped children. The
reverse form is observably asymmetric at the TIFF layer: tiled children carry
tile offset, byte-count, width, and length tags that a stripped base does not.
A validator could therefore reject only the transition to tiled children while
still accepting the existing fixture.

An audit-only stripped-base/tiled-child pyramid passes the reference and all
ten saved Level 3 patches in default and strict modes. Inspection of their
production diffs finds no tile/strip comparison, so the probe is not expected
to change the observed solver outcome families. The operator is prioritizing
human-review completeness and explicitly requested the reverse direction.
Parametrizing the existing public storage-independence test contributes the
missing tag-direction boundary without adding a new requirement or storage
codec.

Revising `test.patch` creates Level 5 at 0/10. The exact matrix, mutation set,
and saved-patch replays must be repeated before approval.

### Level 6 sibling-layout independence gate - 2026-08-07

The next human-review pass identified a separate consistency shortcut: Level 5
varies storage between the base and a homogeneous pair of children, but does
not vary storage between sibling levels. This is not another direction
permutation. A validator may correctly allow base/child differences while
incorrectly treating child storage layout as series-level state that must be
constant across levels.

An isolated homogeneous-children mutant was applied to the unchanged
reference. It compiles, passes all 40 Level 5 focused cases and the complete
702-test baseline, and fails a generated pyramid only when its 32x32 child is
tiled and its 16x16 child is stripped. That mixed-sibling probe passes the
reference in default and strict modes and passes all ten saved Level 3 solver
patches. It therefore supplies a public, distinct discriminator without
penalizing any observed legitimate architecture.

The operator is maximizing human-review completeness and requested promotion
when relevant. Adding the mixed-sibling parameter creates Level 6 at 0/10 and
requires the exact matrix, mutation set, and saved-patch replays again.

### Level 7 control-flow and independence gate - 2026-08-07

The next review supplied five demonstrated survivor families. They map to
separate public clauses and implementation modes already visible in the raw
Level 3 architectures: a strict helper can return before the outer assertion
adapter; per-series loops can reset ownership state; an `is_ome` guard can be
followed by vacuous iteration over zero OME series; page signatures can compare
tile dimensions even after layout equality is removed; and strict factor code
can require each adjacent axis to decrease instead of applying ceiling
division to a unit axis.

Each proposed probe is black-box and repository-generated. The strict case
uses the existing missing reduced-image bit but exercises default assertion
routing. The malformed OME case presents an OME marker with no OME series. The
ownership case aliases one child offset across two OME series. The tile-size
case keeps every page tiled while varying otherwise legal tile dimensions. The
unit-axis case uses 3x8, 1x4, and 1x2 so every child remains below its base,
areas decrease, and factor-two ceiling division legitimately keeps one
adjacent axis at one.

These are distinct from the existing default-mode assertion, within-series
ownership, non-OME/flat-OME, tile-versus-strip, and mixed odd-rounding cases.
The operator explicitly requested all five for human-review completeness.
Adding them creates Level 7 at 0/10 and requires exact matrix, mutation, and
saved-patch replay evidence before approval.

### Level 8 universal-quantification and fairness gate - 2026-08-07

The required local search was repeated across `problems/README.md`,
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, this problem's compact
records, and all ten `agent-runs2` bundles for first-plane, first-child,
compression, tile, strip, decoding, axes, and shape shortcuts. The raw Level 3
trajectories and production patches for run 8 (legitimate pass), run 3
(near-pass), and run 7 (broad failure) were inspected again. All three build
per-series and per-child collections in one production file; runs 3 and 8
explicitly loop over every child for shape and strict checks, while run 7's
cached-frame architecture fails broadly before several otherwise-correct
per-child checks. The trajectories contain no platform agent-message count;
their recorded strict-effective sizes and outcomes remain in `RUNS.md`.

The new fairness report correctly rejects the Level 7 empty-series oracle.
`TiffFile.is_ome` recognizes the description marker, but the public prompt says
only that non-OME input is invalid and a structurally valid flat OME-TIFF is
valid. It does not define the result for a marker that produces no exposed OME
series. Existing solutions split on this boundary, so repository behavior and
trajectory architecture cannot supply the missing participant contract. The
test and empty-series mutant must be removed rather than preserving the result
or expanding the prompt after calibration evidence.

The remaining report items are explicit universal or independence clauses.
Repository probes confirm that `TiffWriter.write` independently accepts
PackBits, LZW, and Zstd compression, a non-full-height `rowsperstrip`, and
rectangular tiles in one valid pyramid under the frozen offline image.
`TiffPage.segments` is a second public pixel-decoding path alongside
`TiffPage.asarray`. ImageWidth and ImageLength are independent IFD fields.
Finally, the saved implementations' nested loops show why checking one
representative page or child is a natural but incomplete shortcut even though
the inspected solvers generally avoided it.

The Level 8 probes therefore vary only a later child for required XY reduction,
the reduced-image bit, page axes, and nonspatial size; vary only a later base
plane's ImageLength for full-resolution Y agreement; and use one valid pyramid
combining the repository-proven storage choices. The axes and nonspatial cases
remain separate because they are separate strict properties. The existing
sentinel is extended to `TiffPage.segments` without adding a new test case.
These black-box outcomes follow the participant prompt and do not prescribe a
loop, parser, allowlist representation, or decoding implementation. Revising
the hidden suite creates Level 8 at 0/10 and requires the full exact-version
audit again.

### Level 9 metadata-normalization and factor-candidate gate - 2026-08-07

The startup search was repeated before changing the verifier. It covered
`PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, this problem's design, audit,
environment, level, and run records, the prior `agent-runs` and `agent-runs2`
history, and every delivered `agent-runs3` patch, JUnit record, evaluation, and
trajectory envelope. Representative raw records were reread for run 12, a
legitimate pass; run 3, the 50/51 direct-tag near-pass; run 14, the 40/51
cached-frame failure; and runs 4 and 11, the empty-patch early terminations.
The local search also inspected the existing interval/set factor algorithms and
exception boundaries in the Level 1, Level 3, and new run-3 implementations.

The delivered run-3 collection contains ten substantive evaluated
implementations: runs 1, 2, 3, 5, 6, 7, 8, 9, 12, and 14. Five are legitimate
51/51 passes and five are public-requirement failures, so the exact Level 8
signal is 5/10. The successful patches all change only
`tifffile/tifffile.py`; their strict-effective production additions are 446,
252, 420, 353, and 360, with a median of 360. Two extra implementation bundles
have no evaluator result and run 48/51 and 50/51. Runs 4 and 11 contain no
solution patch and end after the initial agent message, before any tool call.
Nevertheless, all fourteen runner bundles complete the 702-case baseline and
the 51-case focused JUnit invocation. The evaluators consistently report no
environment blocker. The two early terminations are therefore agent or
orchestration failures, not evidence of a repository, image, test-runner, or
quality-suite crash; no environment artifact should be changed for them.

The new factor report identifies a real positive boundary. The public contract
requires one integer factor across both axes and all transitions while allowing
floor or ceiling rounding independently at each axis and step. For
`3x11 -> 1x4 -> 1x2`, the first transition permits factor three, and the second
transition permits both two and three locally; factor three remains valid
globally. Selecting the first local factor before intersecting all candidates
can therefore reject a valid series. The repository's pairwise
`subresolution` behavior makes that shortcut plausible, while the interval and
candidate-set implementations in prior successful trajectories demonstrate
that the black-box outcome does not require one private representation.

The metadata report also reaches a distinct public failure boundary. The
frozen `series_ome` implementation indexes the required Pixels
`DimensionOrder` attribute directly, so removing that relationship attribute
raises `KeyError` while constructing exposed OME series. Existing malformed
fixtures cover unreadable child offsets and unavailable companions, whose
parser failures fall into different exception families. The prompt already
requires malformed or unreadable pyramid relationships to use the configured
validation result. Replacing only that required relationship attribute and
observing `False` or `AssertionError` exercises the documented exception
boundary without prescribing which XML parser, series builder, or catch clause
an implementation uses. Unlike the withdrawn empty-OME-marker case, this file
contains a concrete OME Pixels relationship whose required field is malformed
and whose parser failure is observable.

These two probes contribute separate discriminator families: global
candidate-set intersection for a valid strict pyramid, and normalization of a
non-I/O metadata parser failure for an invalid OME relationship. Revising the
verifier creates Level 9 at 0/10; the run-3 5/10 result becomes historical and
cannot be carried into the new immutable version. The exact false-positive
audit, patch-order matrix, saved-patch replays, and full bounded checks must be
repeated.

The run-3 file median cannot be hardened honestly through more tests. The
public API is a method on `TiffFile`, and the reader, OME series builder, page
types, and XML helper all intentionally live in the repository's single
`tifffile/tifffile.py` module. Every successful Level 1, Level 3, and Level 8
solver architecture converges on that same production file. Requiring a helper
module, export shim, CLI, writer change, or documentation file would prescribe
implementation shape or add unrelated scope. The one-production-file median
therefore remains a long-horizon warning; it is not repaired by padding the
reference or verifier.

### Level 10 small-parent factor-domain gate - 2026-08-07

The mandatory startup search was repeated before revising the prompt,
reference, or verifier. It covered `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the candidate and problem indexes, this problem's
compact design, audit, environment, level, run, and summary records, and the
raw `agent-runs3` trajectory, solution patch, evaluator, and JUnit artifacts.
The representative raw records were run 6, a legitimate 51/51 pass; run 3, the
50/51 direct-tag near-pass; and run 14, the 40/51 cached-frame broad failure.
No Level 9 solver batch exists yet, so these remain the latest relevant
architecture evidence rather than being replaced with an unrelated run.

All three representative implementations, the Level 9 reference, and other
successful run-3 candidate-set implementations enumerate a transition's
integer factors only through the current parent width or length. That bound is
not implied by the public floor-or-ceiling rule. If the common factor is three,
`6x6 -> 2x2 -> 1x1` is valid: the first transition divides exactly and the
second uses ceiling division. At `2x2 -> 1x1`, factor three is larger than both
parent dimensions but remains valid because `ceil(2 / 3) == 1`. Bounding that
local candidate set by two discards the already-established series-wide factor
and falsely rejects the file.

The proposed positive changes only public IFD dimensions and observes the
strict boolean result. It does not require enumeration, sets, intervals, or a
particular finite bound; an implementation may carry an established factor
forward, derive mathematical candidate ranges, or use any equivalent method.
It is distinct from Level 9's eager-choice probe: that probe retains multiple
locally enumerated factors, while this probe preserves a valid factor outside
the later parent-derived enumeration domain. The recurrence in a legitimate
pass, a near-pass, a broad failure, and the reference makes the shortcut
plausible without designing around one solver.

The description review is also valid but behavior-neutral. Replacing “that OME
loading has closed” with a direct requirement to reopen companions when
necessary removes repository-internal history while preserving temporary
access and prior-state restoration on success and failure. No hidden test is
added for wording, reopening strategy, or a private filehandle transition.

Changing `meta.md`, `solution.patch`, `solution_approach.md`, and `test.patch`
creates Level 10 at 0/10. Level 9 has no cold runs to preserve. The exact
false-positive audit, patch-order matrix, saved-patch replays, architecture
checks, and bounded suite must be repeated before any new solver calibration.

### Level 11 small-parent fairness removal - 2026-08-07

The startup gate was repeated after the fairness verdict and before changing
`test.patch`. The search covered both mandatory protocols, the problem and
candidate indexes, this problem's compact records, the Level 10 audit outputs,
and the raw run-3 pass, near-pass, and broad-failure artifacts for runs 6, 3,
and 14. It also inspected the pinned repository's `subresolution` helper at
lines 25520-25532 and the public strict-mode wording. No Level 9 or Level 10
cold solver batch exists, so the Level 8 run-3 trajectories remain the latest
relevant implementation evidence.

The fairness verdict is correct. The prompt permits independent floor or
ceiling division “for odd dimensions”; it does not extend that relaxation to
an even `2 / 3` transition or state that a factor larger than the current
dimension remains valid. More decisively, the neighboring repository helper
returns `None` whenever the computed factor exceeds a spatial dimension before
testing floor or ceiling division. A solver that follows this visible helper
is therefore repository-aligned. The same bound in a legitimate pass, a
near-pass, a broad failure, and the Level 9 reference is evidence for accepting
that architecture, not evidence for a plausible incorrect shortcut.

Level 11 removes `test_strict_accepts_factor_larger_than_later_parent`, restores
the Level 9 reference and solution approach, and withdraws mutant 61. The
Level 9 ambiguous odd sequence remains fair because every rounded transition
starts from an odd dimension and no factor exceeds its current spatial
dimension. The metadata `KeyError` normalization probe also remains fair and
independent. The participant-facing companion sentence keeps the valid review
cleanup: reopen companions when necessary and restore their prior state,
without explaining repository loading history.

This is a fairness removal, not an easing lever or a replacement discriminator.
Adding explicit prompt text to authorize factor-larger-than-parent behavior
would override the repository seam merely to preserve a hidden test, so it is
rejected. Level 10 is withdrawn at 0/10. Level 11 is a new immutable version at
0/10 and requires the exact false-positive audit, patch-order matrix, replay,
and architecture checks before calibration.

### Level 12 companion-chain and factor-performance gate - 2026-08-07

The mandatory startup search was repeated before revising `test.patch`. It
covered `PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, the problem and
candidate indexes, this problem's design, audit, environment, level, run, and
summary records, and the raw run-3 trajectory, patch, evaluator, and test
artifacts. The representative raw records were again run 6, a legitimate
51/51 pass; run 3, the 50/51 direct-tag near-pass; and run 14, the 40/51
cached-frame broad failure. Their production patches use per-owning-file
primary-chain identities. All ten substantive run-3 patches do likewise, so
the reported companion gap is coverage of an independent repository branch,
not evidence that a known legitimate solver took the shortcut.

The companion finding is nevertheless fair and useful. The public contract
requires every OME-mapped full-resolution plane to be on its owning file's
primary chain. The pinned OME loader resolves a `TiffData/UUID` mapping against
the named companion's `pages` collection; an out-of-range companion IFD logs
the repository's `IndexError` path and leaves that mapped series position
absent. The existing negative reaches the analogous root-file branch only.
Raw-XML-first validators can validate root indexes while trusting companion
indexes, whereas page-series-first validators can handle both through the same
absent-plane result. Extending the existing mapping test across root and
companion ownership therefore covers a distinct file-resolution branch while
preserving every implementation architecture and the same public outcome. It
is not claimed as a new requirement or a second difficulty lever.

The performance finding is also correct, but does not justify a hidden timing
test. The Level 11 reference and four substantive run-3 patches enumerate all
integers through the larger parent dimension for every strict relationship.
That makes structural work proportional to potentially large image dimensions
even though compatible floor and ceiling factors can be represented by at
most two integer intervals per axis and intersected arithmetically. Level 12
changes the reference to bounded interval derivation and verifies exhaustive
equivalence against the old enumeration over small dimensions. The public
prompt, accepted results, and solver architecture remain unchanged; a solver
is not required to reproduce the interval representation.

The exact false-positive audit will add one companion-mapping mutant that
checks root mappings but trusts an out-of-range companion `TiffData` index.
The prior 59 actionable mutants and withdrawn empty-series mutant remain in
scope; historical mutant 61 remains withdrawn with the unfair Level 10 test.
Changing `test.patch`, `solution.patch`, and `solution_approach.md` creates
Level 12 at 0/10 and requires every patch-state, mutation, replay, bounded-lane,
and architecture check again before calibration.

### Level 13 optional-codec fixture gate - 2026-08-07

The mandatory startup search was repeated before revising `test.patch`. It
covered `PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, the problem and
candidate indexes, this problem's current compact records, and the raw run-3
pass, near-pass, and broad-failure artifacts for runs 6, 3, and 14. Those runs
remain representative: they implement the validator in one production module,
use distinct raw-IFD, raw-XML, and series/frame data flows, and fail only for
recorded behavioral omissions. Their frozen image supplied Imagecodecs, so no
trajectory reached the optional-codec fixture setup failure.

The fairness verdict is correct. The pinned repository treats Imagecodecs as
optional: its PackBits write coverage is guarded by `SKIP_CODECS`, LZW coverage
checks `imagecodecs.LZW.available`, and ZSTD coverage checks
`imagecodecs.ZSTD.available`. The focused storage-choice test writes all three
formats before calling the new validator. Without those encoders, fixture
construction raises for an environmental precondition and cannot observe the
participant's implementation.

Level 13 keeps the storage-independence oracle when all three encoders are
available and skips that one test otherwise, using the repository's own
availability model. It does not weaken the public rule, substitute a malformed
payload, add a new discriminator, or require a dependency the package does not
declare by default. The other uncompressed, Deflate, tile, strip, rectangular
tile, short-strip, and mixed-layout positives remain unconditional. This is a
fixture fairness repair rather than a behavioral lever, so the discriminator
ledger is unchanged.

Changing `test.patch` creates Level 13 at 0/10. The reference, prompt,
solution approach, Dockerfile, source pin, and accepted behavior do not change.
The exact false-positive audit, both patch orders, saved-patch replays,
bounded-suite checks, no-codec probe, and both architecture checks must be
repeated before calibration.

## Discriminator ledger

| Repository/trajectory evidence | Plausible shortcut | Fair public invariant | Planned black-box oracle | Distinct failure family | Anti-overfitting rationale |
|---|---|---|---|---|---|
| solver architectures split strict checks from the final result adapter | return `False` directly from a strict-only failure even when `assert_` is true | every invalid result uses the same configured return-or-raise convention | missing reduced-image bit in both strict return and default assertion modes | strict failure control flow | reuses an established public invalid input and changes only the API mode |
| current reader accepts tag 254 = 0 and exposes bitmask helpers for reduced image and mask | trust series grouping or whitelist observed values 1 and 3 | strict mode requires bit 0 while allowing other legal bits | generated children with value 0, 3, and legal `REDUCEDIMAGE|MASK` value 5 | recommendation/tag bitmask identity | observes public tag values without requiring how they are read and independently kills equality and two-value whitelist shortcuts |
| current reader accepts 32x16 from 64x64 | treat any smaller X/Y as a level | strict mode uses one integer factor for X and Y | paired isotropic and anisotropic files | spatial factor symmetry | compares public shapes and accepts any implementation producing the same result |
| current reader accepts 64 -> 32 -> 8 | compare every level only with base | strict mode keeps one consecutive factor | constant-factor and changing-factor pyramids | level-to-level state | exercises state across levels, not a helper, loop direction, or chosen baseline |
| odd rounded transitions can admit more than one integer factor | select one locally valid factor before later transitions are known | one factor remains viable across every X/Y transition in an image series | accept `3x11 -> 1x4 -> 1x2`, whose global factor is three | global factor-candidate intersection | observes only the public strict result and permits sets, intervals, ranges, or any equivalent implementation |
| current reader accepts 16 before 32 | preserve tag order without validating it | SubIFD offsets are largest-to-smallest | reverse only the two child offsets | required storage order | mutates the public SubIFD order while leaving size values and parser architecture open |
| both successful solver patches compare adjacent areas with `>` | allow equal-area adjacent children | tag-330 children are strictly ordered by decreasing plane area | construct two different child shapes with the same area | strict area-order boundary | distinguishes strict from non-increasing order without requiring either axis to be monotonic |
| an invalid reverse-order example can be implemented as per-axis monotonicity | require both child axes to shrink at every consecutive step | default order is by area; each child independently stays below the full-resolution owner in X and Y | accept decreasing-area children where one axis grows between child levels | area ordering versus strict-only factor geometry | prevents a stronger private ordering rule while preserving the explicit base-relative X/Y constraint |
| `test_write_subifd_chain` exposes a child `NextIFD` form | accept any reduced child transitively reachable below tag 330 | every OME sub-resolution is listed directly by its base IFD | write one direct child whose `NextIFD` reaches a second reduced child | direct reachability | distinguishes OME's flat tag-330 list from a repository-supported non-OME chain without requiring a traversal helper |
| OME series maps base pages from XML | validate only `series.levels` | child offsets never appear in the primary IFD chain and therefore cannot be addressed by `TiffData` | alias one child to a primary-chain IFD | metadata/chain separation | tests the one observable storage violation instead of pretending `TiffData` supplies an independent offset namespace |
| writer requires equal pages per level | check only the first base plane | all base planes have matching level count and association | multi-plane file with one missing or shape-mismatched child | per-plane topology | varies ownership across planes so raw-XML-first and page-series-first implementations remain valid |
| tag 330 is independently present on every mapped primary IFD | compare corresponding levels with truncating `zip` | every base plane has exactly the same level count | remove one direct tag-330 entry from only the first plane while leaving the later plane's extra level valid | level-count equality | observes the public count before corresponding-shape comparison and does not require a collection strategy |
| `_series_ome` maps `TiffData/UUID` planes from named companions, indexes each companion's primary `pages`, and existing tests cover a 35-file pyramid | validate root mapping indexes but trust companion indexes, validate only the initially opened TIFF, or reject all multi-file series | every mapped plane is on its owning file's primary chain and equal numeric offsets in different files remain independent | generated two-file OME pyramid with matching layouts, an out-of-range companion primary mapping, and secondary-only topology mutations | cross-file mapping resolution, coverage, and offset namespace | uses public OME filename/UUID mappings and outcomes without requiring access through `_files` or another private cache |
| `_series_ome` closes each loaded companion and `FileHandle` supports reopening | parse a secondary page through its already closed handle | valid companion SubIFDs remain readable during validation and the companion returns to its prior closed state | validate a generated two-file pyramid and observe success plus the repository's closed-companion lifecycle | secondary resource lifecycle | permits temporary reopen, fresh `TiffFile` instances, or any equivalent readable-access strategy while preserving established public filehandle state |
| `FileHandle.open()` preserves an open handle while `FileHandle.close()` changes owned-handle state | unconditionally close every companion after validation | an already-open companion remains open after validation | open the cached companion before validating the same generated two-file pyramid and observe it afterward | open companion lifecycle | tests only caller-visible state restoration and permits any temporary-access implementation |
| validation can exit by `False` or by `AssertionError` while a companion is temporarily readable | restore companion state only on the successful path or close every handle during error cleanup | prior open/closed state is restored on both validation failure modes | corrupt only the companion and observe initially open and closed handles after return and raise modes | failure-path resource lifecycle | exercises cleanup timing without pinning `try/finally`, cache ownership, or exact exception text |
| `FileHandle.open()` delegates reopening a named closed handle to built-in file I/O | catch child-parser failures but leak `OSError` while reopening a cached companion | an unreadable mapped companion produces the configured validation result | load and close a generated companion, move its path, then exercise return and assertion modes | companion access failure normalization | changes external availability after a valid OME mapping and observes only the public result and closed state |
| later primary OME planes may be `TiffFrame` objects whose shape delegates to a keyframe | replace every frame with its keyframe before reading base dimensions | each mapped primary IFD supplies its own ImageWidth/ImageLength and all base planes in a series have one XY shape | change the second primary IFD width while leaving the first and OME mapping intact | full-resolution per-IFD shape | observes raw public IFD dimensions and permits any materialization strategy rather than requiring `TiffPage` construction |
| TIFF tag 330 can repeat an offset and solver implementations choose per-series or per-file ownership sets | reset ownership tracking for each OME series | one sub-resolution belongs to exactly one full-resolution plane across the exposed file | point two base planes in separate OME series at the same otherwise valid child | cross-series SubIFD ownership | changes one public parent-child relationship and isolates ownership-state scope without requiring a cache representation |
| nonzero out-of-file tag-330 offsets reach page parsing rather than the zero guard | range-check only small or zero offsets and leak child parser errors | malformed or unreadable relationships use the documented validator result | replace one valid child offset with a nonzero value beyond EOF | exception normalization at parse boundary | checks only the public return/raise convention and does not pin the parser exception type or an offset precheck |
| `series_ome` directly indexes the required Pixels `DimensionOrder` attribute | normalize I/O and TIFF parser failures but leak another metadata parser exception | malformed OME relationship metadata uses the configured validation result | replace only `DimensionOrder` with an unknown same-length attribute | metadata exception normalization | uses a repository-owned required relationship and public outcomes without prescribing an exception list or XML traversal |
| `TiffPage.is_reduced` masks bit 0 and `TiffPage.is_mask` exposes bit 2 | require `NewSubFileType == 1` or whitelist values 1 and 3 | strict mode requires the reduced-image bit while allowing independent legal bits | strict-valid children with `subfiletype=3` and `subfiletype=5` | bitfield semantics | uses repository public flag behavior and independently kills equality and observed-value whitelist shortcuts |
| contiguous and separate-planar RGB pages expose `YXS` and `SYX` with the same three samples | compare only nonspatial dimension sizes | strict mode preserves the page-axis identity and order | use `YXS` and `SYX` levels whose `S` size remains three | page-axis identity/order | varies only the public axis representation and does not require a private comparison strategy |
| contiguous RGB and RGBA pages both expose `YXS` while their sample sizes differ | compare only the axes string | strict mode preserves every nonspatial dimension size | use `YXS` levels whose `S` sizes are three and four | nonspatial cardinality | varies only one public dimension and is independent of axis identity/order |
| per-child loops in saved patches make the first child an easy representative | validate strict page properties only at level one | reduced-image bit, page axes, and nonspatial sizes apply to every child | keep level one valid and vary only the later child's flag, axes, or nonspatial size | strict universal quantification | isolates three public properties at a later level without requiring a traversal order or helper |
| required XY reduction is another per-child loop and the existing failures target level one | validate both-axis reduction only for the first child | every child is smaller than its full-resolution owner in both axes | keep level one valid and make only a later child's X equal to the base | required reduction universal quantification | changes one later public IFD dimension while retaining decreasing area |
| ImageWidth and ImageLength are independent IFD fields | compare only width across mapped full-resolution planes | every full-resolution plane agrees in both X and Y | alter only a later primary IFD's ImageLength | full-resolution Y agreement | complements the existing width mutation without duplicating a storage form |
| `subresolution` tolerates odd dimensions | use raw divisibility or only total pixel count | strict mode accepts floor/ceiling odd reductions | valid odd XY reductions at factors two and three | XY rounding semantics | tests the public rounding boundary without coupling it to a nonspatial failure |
| `subresolution` evaluates floor or ceiling separately for every spatial axis, including `ceil(1 / factor) == 1` | require both axes to choose the same rounding direction or decrease at every adjacent step | either axis may independently round down or up at every strict reduction | mixed floor/ceiling step plus a valid unit axis that remains one | mixed and unit-axis XY rounding | isolates rounding direction and the ceiling fixed point while keeping one common factor |
| TIFF width and length are independent IFD fields, while the existing fixture leaves only Y unreduced | check only one spatial axis against the base | every child is smaller than its owner in both X and Y | pair one X-unreduced and one Y-unreduced child | base-relative XY conjunction | covers both explicit operands and permits any shape representation |
| `TiffWriter.write` selects layout and tile dimensions independently per IFD | require matching layouts, homogeneous child layouts, or equal tile dimensions | legal storage choices are opaque and independent across full-resolution and child IFDs | accept both layout directions, mixed siblings, and all-tiled levels with differing legal tile sizes | storage-setting independence | isolates layout tags from tile-dimension values without adding another codec or requiring a private parsing strategy |
| frozen-image writer probes accept PackBits, LZW, Zstd, short strips, and rectangular tiles | whitelist only the common Deflate and square/default storage fixtures | otherwise valid compression, strip, and tile choices remain independent | combine three codecs, a short strip, and rectangular tiles in one valid pyramid | storage allowlist rejection | one compact positive rejects representative allowlists without multiplying codec fixtures |
| `TiffPage.asarray` and `TiffPage.segments` can both decode pixels | avoid only the already-sentinelized decoding entry point | validation does not decode pixel data | replace both public decoding paths with failing sentinels during valid strict validation | alternate decoding path | observes only forbidden pixel access and permits all structural parsing strategies |
| PCAPNG near-pass overvalidated discarded options | validate storage encodings | valid compression and tile/strip choices plus pixel bytes are outside this structural API | structurally identical pyramids with differing legal encodings | architecture neutrality | prevents the reference's preferred encoding from becoming a private acceptance requirement |
| normalization has no public repair oracle | silently rewrite or select a winner | validation never changes source bytes or page state | snapshot file bytes and public topology around validation | read-only ownership | constrains only observable mutation, not caching, parsing, or traversal strategy |

Each planned oracle changes a public OME/TIFF relationship. Multiple sizes or
tag values inside one row are fixtures for one semantic boundary, not separate
discriminators. Tests must synthesize small files and vary dimensions and page
counts; they must not encode a private validator helper, exact error message,
iteration order, or one reference patch.

## Clause-to-test coverage planned for the audit prototype

| Public requirement | Strongest planned observable | Pristine behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| exact API and assertion mode | call the keyword-only method on valid, default-invalid, and strict-only-invalid inputs with both `assert_` values | method is absent | boolean result or `AssertionError` | mirrors `OmeXml.validate` and isolates outer result routing |
| non-OME fails; valid OME without a pyramid succeeds | generated files for both states | method is absent | false/raise versus true | OME-TIFF identity and optional sub-resolutions |
| full-resolution planes remain primary and mapped | corrupt an OME plane mapping or alias a child to a primary IFD | parser may warn or group it | validation fails | OME `TiffData` and storage clauses |
| direct tag-330 reachability, ordering, and unique ownership | add a reduced child only through `NextIFD`, reverse level order, duplicate a child owner within and across OME series, and use an invalid child offset | reader accepts or constructs partial levels | validation fails | OME storage requirements |
| per-plane full-resolution, level-count, and child-shape consistency | independently change a later primary IFD's width or length, remove a child, or change a later child shape | reader can retain frames or a partial/mixed series | validation fails | base and level dimensions apply to the complete image |
| multi-file plane coverage and per-file ownership | map equal-layout base planes from two named TIFFs, then corrupt only a companion's child relationship | OME loader constructs a multi-file series and closes the companion | valid topology passes; secondary-only corruption fails; equal offsets in separate files do not collide | existing multi-file OME reader and per-file TIFF offset namespaces |
| closed companion restoration | validate after OME loading has closed the cached companion | companion begins closed | validation succeeds and the companion remains closed | public companion lifecycle and reopenable `FileHandle` |
| open companion restoration | explicitly open the cached companion before validation | companion begins open | validation succeeds and the companion remains open | public prior-state contract and owned-handle close behavior |
| required XY reduction | attach an equal/larger or one-axis-unreduced first child, then repeat with only a later child invalid | ordinary reading remains available | validation fails | every sub-resolution is an XY downsampling |
| strict reduced-image bit | compare first- and later-child missing bit 0 with valid values containing other bits | ordinary reading succeeds | missing bit fails strict; combined bits pass | explicit OME recommendation and repository `is_reduced` bitmask behavior |
| strict common integer factor | anisotropic, changing-factor, valid factor-three, and ambiguous odd-rounded pyramids | ordinary reading succeeds for all | only files retaining at least one series-wide factor pass strict mode | explicit OME recommendation and `subresolution` |
| strict page axes | switch contiguous RGB `YXS` to separate-planar RGB `SYX` at the first and later child while keeping `S=3` | ordinary reading succeeds | default true, strict false | OME recommendation applies to every child's page axes |
| strict nonspatial sizes | keep contiguous `YXS` while changing `S` from three to four at the first and later child | ordinary reading succeeds | default true, strict false | OME recommendation applies to every child's nonspatial dimensions |
| odd-size rounding | factor-two floor/ceiling reductions from odd dimensions, including a unit axis retained by ceiling division | ordinary reading succeeds | strict true | repository `subresolution` behavior prevents exact-divisibility and adjacent-decrease overconstraints |
| encoding neutrality | both tile/strip directions, mixed siblings, differing tile sizes, rectangular tiles, a short strip, and PackBits/LZW/Zstd | ordinary reading succeeds | same validation result | OME permits supported independent storage choices |
| read-only and malformed-data behavior | hash bytes before/after success/failure, use a nonzero tag-330 offset beyond EOF, and remove a required Pixels relationship attribute | no validator | bytes unchanged; invalid result does not leak an unrelated exception | read-only API ownership and validator convention |

## Cheapest-legitimate-solution forecast

The original estimate was one method plus one or two small internal helpers in
`tifffile/tifffile.py`, or 80-150 effective production lines. The completed
Level 8 run-3 batch is now the governing architecture evidence: all five
legitimate passes modify one production file and add 252, 353, 360, 420, and
446 strict-effective lines, for a median of 360. Raw-XML-first, low-level IFD,
and page-series-first implementations all occurred in practice.

The frozen reference is 231 raw and 196 strict-effective additions in one
production file. The successful Level 8 median clears the 200-line horizon but
not the two-production-file horizon, and the ATIF bundles do not expose the
platform agent-message metric. The exact solver evidence therefore replaces the
old size forecast but does not satisfy the complete long-horizon gate.

The predecessor review lane independently reported 179 effective added lines
before the withdrawn Level 10 reference change, below its typical 200-line floor. That
historical counting result is a calibration signal only and used a different
exclusion rule. Inspection still finds substantial logic, so it does not
change an instrument band or the 8/10 verdict.

Per `SEARCH_INSTRUCTIONS.md`, LOC has no standalone rating dimension and may
move behavioral depth by only one point. The candidate remains viable as the
user-requested low-LOC feature because it has several independent structural
states and an unusually clear public standard. Five successful Level 8
trajectories now demonstrate substantial logic but consistent one-file
convergence. That is a reason to close or decline submission on long-horizon
grounds, not to add normalization or unrelated TIFF behavior.

## Harness preflight

At the frozen pin, source inspection counted 695 direct `test_` functions and
129 parametrizations. The host Python 3.14 environment installed the committed
test extras successfully. A broad lane reached 3,357 passes and 559 skips at
91% before it was deliberately interrupted on entry to large-data tests; it is
not recorded as a complete-suite pass.

The bounded repository lane used the project's skip controls for HTTP, external
files, XMLSchema validation, large data, and extended cases:

- host: 706 passed, 3,544 skipped in 8.29 seconds;
- `python:3.14-slim` container with `--network none`: 706 passed, 3,544 skipped
  in 11.67 seconds;
- adjacent generated SubIFD chain/tree and exception cases with
  `--network none`: 5 passed in 3.74 seconds.

External OME pyramid fixture tests skip because their files are not stored in
the repository. A future focused lane must generate tiny TIFFs at runtime and
must not download OME schemas or fixture corpora. The disposable checkout,
virtual environment, build Dockerfile, and audit image are not problem
artifacts and are removed after this record is written.

## Applicability rating

| Dimension | Score | Reason |
|---|---:|---|
| eligibility and health | 9 | active 2026 release, BSD-3-Clause, 660 stars, clean provenance, large real suite |
| rarity | 9 | OME-TIFF/SubIFD topology is uncommon and not a generic parser exercise |
| task applicability | 8 | opt-in validation fills a confirmed gap with direct public oracles and a frozen repository-shaped API |
| behavioral depth | 6 | several independent relationships, but likely one-module and low-LOC |
| harness feasibility | 9 | fast generated Python tests pass offline in the official container |
| prior-art and similarity safety | 7 | no exact upstream/local task; geotiff.js creates an adjacent but distinguishable SubIFD neighborhood |

Weighted score: 8.1, rounded to **8/10**. No cap applies. This is the first
survivor in the current ranked batch. `nodejs/llparse` remains only the fallback
if API freezing or a future false-positive audit invalidates tifffile.

## Current gate boundary

The Level 13 package is frozen at the hashes in `FALSE_POSITIVE_AUDIT.md`. Its
exact-version audit maps every public clause and kills all 60 actionable
mutants; the former empty-series mutant remains withdrawn with its undefined
oracle. Pristine upstream fails 54/54 focused cases; the reference passes
54/54 in both patch orders; and both orders produce identical complete diffs.
The bounded lane remains 702 passed and 3,548 skipped, direct combined pytest
completes at 756 passed and 3,548 skipped, and `python setup.py build`
succeeds on ARM64 and AMD64 under `--network none`.

Mutant 62 passes the preceding 53 focused cases and the complete bounded lane,
then fails only the named-companion mapping parameter. The reference's interval
factor helper matches the former enumeration across 189,225 small-shape
combinations and handles the billion-pixel probe as one range. No hidden timing
oracle was added.

The optional PackBits/LZW/ZSTD fixture now runs only when Imagecodecs and all
three encoders are available, matching visible repository setup policy. With
`SKIP_CODECS=1`, the reference passes 53 runnable cases and skips that fixture;
pristine upstream fails the same 53 and skips the same fixture. Both
architectures agree, and the remaining unconditional storage positives still
exercise Deflate, uncompressed, strip/tile direction, sibling-layout, and tile
dimension independence.

The completed Level 8 run-3 batch supplies the latest trajectory evidence:
five legitimate passes, five public implementation failures, and no
environment blocker among the ten substantive evaluations. The
two empty-patch early terminations did not execute tools, while all runner and
quality checks completed, so they are not environment failures. Exact Level 13
replay of the ten earlier Level 3 patches scores 52, 52, 51, 52, 51, 50, 43,
54, 49, and 54. Exact replay of the ten substantive run-3 patches scores 49,
50, 53, 54, 54, 54, 49, 54, 54, and 43 in run-number order, preserving the
same five-pass/five-failure split as Level 9.

Because the verifier changed after the run-3 batch, its 5/10 is historical and
Level 13 starts at 0/10. Level 10 is withdrawn at 0/10 because
its added small-parent boundary was not fairly stated. The successful median is
one production file and 360 strict-effective additions. That one-file
convergence remains a long-horizon
warning and cannot be repaired honestly by prescribing a second file.
