# False-positive audit - tifffile OME pyramid validation

Status: complete for the exact Level 13 artifact set below; calibration is
0/10 after the optional-codec fixture fairness repair. The audit found
one initial actionable survivor, later closed three single-file, four
multi-file, two strict-shape, one companion-lifecycle, and one companion-access
review mutant, withdrew one undefined empty-series oracle, and killed all 60
current actionable mutants. All ten Level 3 solver patches and all fourteen
delivered run-3 bundles were replayed; the analogous
PcapPlusPlus trajectories remain earlier design evidence only.

## Exact candidate version

- source: `cgohlke/tifffile`
  `940f7630df48edf8e13913962035ed80b408b5f4`;
- `meta.md` SHA-256:
  `ab70cb61e377aa8d4b6cc78ac37298c81bf25042d4ba9bac387cd73a15241aeb`;
- candidate `test.patch` SHA-256:
  `aa547b84a18d55ea2d5a83a8920729e34aed12ccdda565fdb30de65cdd26ce30`;
- candidate `solution.patch` SHA-256:
  `6e23a2ed70b3743acf1bd9390519551ded0a414e4ad8229458dd7920cfd60f11`;
- `Dockerfile` SHA-256:
  `d7a789bda59cc68257ca0b0f63755c64b8e5128a927e7058960e07677c32e489`;
- `solution_approach.md` SHA-256:
  `9a2b3b930124804ddeb9bdd5dc0531b08ed3e3c9c3ad87ca0c70af71866165a1`.

The exact 970-line focused file has Git blob
`e68eecaf7aa12f075bdc71b845a2cb1e7afd6574` and SHA-256
`ece4f2440fcbd37c65ce73a9b8fea40c1ae21c9784e0d135e353c3257a607a1f`.

The candidate reference has 231 raw and 196 strict effective production
additions after excluding blanks, comments, and the public docstring. This is a
reference scope measurement, not a solver-horizon claim. The review lane's
independent 179-effective-line count is likewise a calibration signal only; it
does not change an instrument band or the 8/10 verdict.

## Requirement-to-strongest-test map

| Participant-facing requirement | Strongest behavioral test |
|---|---|
| exact keyword-only API, defaults, and assertion convention | `test_validate_ome_pyramid_signature`, `test_valid_pyramid_and_assertion_mode`, and strict-only failure routing in `test_strict_failure_honors_assertion_mode` |
| non-OME invalid; structurally valid flat OME valid | `test_non_ome_fails_and_flat_ome_succeeds` |
| malformed relationships return the validator result instead of parser errors | nonzero beyond-EOF child offset in `test_unreadable_subifd_uses_validation_result` and missing required Pixels relationship attribute in `test_malformed_ome_relationship_uses_validation_result` |
| an OME-mapped closed companion that cannot be reopened uses the validator result | moved companion path in both modes of `test_unreopenable_companion_uses_validation_result` |
| every OME-mapped base plane is present and primary in its owning file | root and companion parameters of `test_mapped_ome_plane_missing_from_primary_chain`, plus `test_subifd_cannot_alias_primary_chain` |
| every sub-resolution is directly listed in tag 330 | `test_every_subresolution_is_listed_in_tag_330` |
| one full-resolution owner per child, including across OME series | `test_subifd_has_one_full_resolution_owner`, `test_subifd_owner_is_unique_across_ome_series` |
| full-resolution shape and corresponding child shape agree across base planes | independent later-primary ImageWidth and ImageLength mutations in `test_all_base_planes_have_corresponding_levels` and `test_full_resolution_y_shapes_must_match`, plus the later-child ImageLength mutation |
| every base plane has exactly the same level count | asymmetric tag-330 lengths in `test_each_plane_has_same_number_of_subresolution_levels` |
| multi-file series validate every owning TIFF with per-file offsets | valid equal-layout companion pyramid, out-of-range companion primary mapping, and two secondary-only failures in `test_mapped_ome_plane_missing_from_primary_chain[companion]`, `test_multifile_pyramid_uses_each_owning_file`, and `test_multifile_secondary_topology_is_validated` |
| companions remain readable and return to their prior open or closed state on success and failure | closed/open success cases in `test_multifile_pyramid_uses_each_owning_file` plus return/raise failure cases in `test_failed_multifile_validation_restores_companion_state` |
| strictly decreasing plane area without per-axis child-level monotonicity | reverse order, equal area, and valid one-axis-growth cases in `test_required_order_and_xy_reduction` and `test_default_order_is_by_area_not_each_consecutive_axis` |
| every child is smaller than its owner in both X and Y | independent first-child X/Y cases in `test_required_order_and_xy_reduction` and the valid-first/invalid-later case in `test_every_child_is_smaller_than_base_in_both_axes` |
| every strict child has the reduced-image bit while other bits remain valid | first-child missing bit 0 and valid `subfiletype=3` cases in `test_reduced_image_flag_is_strict_only`, later-child missing bit in `test_every_child_requires_reduced_image_bit`, and independent legal `subfiletype=5` coverage in `test_strict_accepts_reduced_mask_subfiletype` |
| strict common integer factor in both axes and across consecutive levels | anisotropic and changing-factor cases in `test_strict_rejects_nonuniform_factors` and the globally valid ambiguous odd sequence in `test_strict_accepts_ambiguous_odd_factor_sequence` |
| odd floor/ceiling rounding is independent per axis, factors other than two are valid, and ceiling division may keep a unit axis at one | all three cases in `test_strict_accepts_odd_rounding_and_other_integer_factors`, `test_strict_allows_unit_axis_to_remain_unchanged`, and the ambiguous factor-candidate positive |
| every strict child preserves page axes | contiguous RGB `YXS` base and separate-planar RGB `SYX` child, both with `S=3`, at the first level in `test_nonspatial_page_shape_is_strict_only[axes]` and later level in `test_every_child_preserves_strict_page_shape[axes]` |
| every strict child preserves nonspatial dimension sizes | contiguous `YXS` RGB and RGBA pages with `S=3` and `S=4` at the first level in `test_nonspatial_page_shape_is_strict_only[size]` and later level in `test_every_child_preserves_strict_page_shape[size]` |
| validate every series but scope factor state per series | `test_every_ome_series_is_validated`, `test_strict_factor_is_scoped_per_ome_series` |
| accept legal encodings and a mix of pyramidal/flat series | tiled, Deflate, uncompressed, and flat-series case in `test_legal_encodings_and_multiple_series_are_accepted` |
| storage layout, legal tile dimensions, strip length, and compression are independent across full-resolution and sibling child IFDs | tiled-base/stripped-child, stripped-base/tiled-child, and mixed-sibling parameters in `test_mixed_tile_and_strip_storage_is_accepted`; unequal tile dimensions in `test_tiled_levels_may_use_independent_tile_sizes`; unconditional Deflate and uncompressed coverage; and, when their optional encoders are available, PackBits/LZW/Zstd, rectangular tiles, and a short strip in `test_valid_compression_strip_and_rectangular_tile_choices` |
| do not decode pixels or call `OmeXml.validate` | `test_legal_encodings_and_multiple_series_are_accepted` replaces `TiffPage.asarray`, `TiffPage.segments`, and `OmeXml.validate` with failing sentinels |
| do not alter the file | byte-for-byte checks around successful and failed single-file validation and both files of a valid companion dataset |

## Actionable survivor and resulting probe

The first 19-case prototype accepted a file written with `subifds=-2`: tag
330 directly named the 32x32 child, whose `NextIFD` linked a second 16x16
reduced image. The ordinary reader exposed only one pyramid level, so a
validator that inspected the tag entries but not the child link returned true.
That implementation passed all 19 focused cases and the complete bounded
pre-existing lane: 706 passed and 3,544 skipped.

This survivor is plausible from repository evidence because
`test_write_subifd_chain` documents the writer's chain form and the reader's
choice to follow only the direct tag entry. It violates the public OME rule
that every sub-resolution offset is referenced from the full-resolution IFD.
The added probe uses the public writer form, passes the corrected reference,
and fails only the predecessor's missing direct-reachability check. It is not a
second size-order fixture.

## Final mutation isolation

The exact 54-case candidate reference passes 54/54. Each mutation below was
applied independently against the complete focused file.

| Mutant | Plausible incorrect implementation | Final focused result |
|---:|---|---:|
| 1 | validate only the first OME series | 52/54 |
| 2 | validate only the first base plane | 41/54 |
| 3 | allow one child to have multiple owners | 52/54 |
| 4 | accept a reduced child reachable only through `NextIFD` | 53/54 |
| 5 | ignore a later base plane's level shape | 52/54 |
| 6 | require descending area but not reduction in both axes | 51/54 |
| 7 | apply strict recommendations in default mode | 45/54 |
| 8 | ignore the reduced-image bit | 51/54 |
| 9 | ignore both strict page axes and nonspatial sizes | 50/54 |
| 10 | infer independent X and Y factors | 52/54 |
| 11 | forget the factor between consecutive levels | 53/54 |
| 12 | allow only factor two | 51/54 |
| 13 | require exact divisibility | 48/54 |
| 14 | share factor state between separate OME series | 53/54 |
| 15 | require children to use the base plane's encoding | 52/54 |
| 16 | ignore missing OME-mapped planes | 52/54 |
| 17 | reject a valid OME image without a pyramid | 52/54 |
| 18 | never raise in assertion mode | 42/54 |
| 19 | decode every child during structural validation | 53/54 |
| 20 | call `OmeXml.validate` during structural validation | 53/54 |
| 21 | use a `TiffFrame` keyframe's dimensions instead of its own primary IFD | 52/54 |
| 22 | re-raise `TiffFileError` from unreadable child parsing | 53/54 |
| 23 | require `NewSubFileType == 1` instead of masking bit 0 | 52/54 |
| 24 | validate mapped pages only when their parent is the root TIFF | 48/54 |
| 25 | reject every OME series that spans more than one TIFF | 52/54 |
| 26 | reopen a closed companion but leave it open after validation | 51/54 |
| 27 | treat equal numeric SubIFD offsets in separate TIFFs as one owner | 52/54 |
| 28 | compare strict page axes but ignore nonspatial dimension sizes | 52/54 |
| 29 | compare strict nonspatial dimension sizes but ignore page-axis identity and order | 52/54 |
| 30 | unconditionally close an already-open companion after validation | 53/54 |
| 31 | allow equal-area adjacent child levels | 53/54 |
| 32 | require both axes to decrease between consecutive child levels | 51/54 |
| 33 | truncate later base planes to the first plane's level count | 53/54 |
| 34 | require both odd axes to use the same rounding direction | 53/54 |
| 35 | require base and child IFDs to share tile/strip layout | 50/54 |
| 36 | check only Y when enforcing base-relative XY reduction | 52/54 |
| 37 | restore an initially closed companion only after successful validation | 52/54 |
| 38 | close an initially open companion on every validation failure | 52/54 |
| 39 | skip closed-companion restoration before assertion-mode failure | 53/54 |
| 40 | close an open companion only on assertion-mode failure | 53/54 |
| 41 | rethrow `OSError` while reopening a closed companion | 52/54 |
| 42 | accept only `NewSubFileType` values 1 and 3 | 53/54 |
| 43 | allow only tiled-base to stripped-child layout changes | 53/54 |
| 44 | require all child levels to share one tile/strip layout | 52/54 |
| 45 | return `False` directly from strict-only failure handling before the assertion adapter | 53/54 |
| 46 | reset child ownership state at every OME-series boundary | 53/54 |
| 47 | accept any `is_ome` file when the exposed OME-series collection is empty | withdrawn; 54/54 after removing the undefined oracle |
| 48 | require tiled children to use the full-resolution IFD's tile dimensions | 53/54 |
| 49 | require both axes to decrease between every consecutive strict level | 52/54 |
| 50 | allow only uncompressed and Deflate IFDs | 53/54 |
| 51 | allow only square tiles | 53/54 |
| 52 | require every strip to span the full image height | 53/54 |
| 53 | inspect the reduced-image bit only on the first child | 53/54 |
| 54 | enforce base-relative XY reduction only on the first child | 53/54 |
| 55 | compare page axes only on the first child | 53/54 |
| 56 | compare nonspatial dimension sizes only on the first child | 53/54 |
| 57 | decode child pixels through `TiffPage.segments` | 53/54 |
| 58 | compare only ImageWidth across full-resolution planes | 53/54 |
| 59 | select one locally compatible odd-rounding factor greedily | 53/54 |
| 60 | normalize prior parser exception families but leak metadata `KeyError` | 53/54 |
| 62 | reject absent root mappings but silently skip an absent named-companion mapping | 53/54 |

The predecessor 20-case reference passed the host inventory with 726 passes
including the focused cases and 3,544 skips. That historical Python 3.14 result
is retained only as predecessor evidence. The current frozen image matrix
below is authoritative for the 54-case artifact. All 60 predecessor mutations
and the new companion mutant were rerun against the exact file; all 60
actionable mutants are killed, and all 61 retained trees pass the complete
702-test lane. Mutant 47 is rejected rather
than counted as an actionable survivor because its sole difference concerns
the undefined empty-series boundary. The earlier meaningful survivor's 706/706
pre-existing pass is recorded above rather than discarded.

Those counts are from the host Python 3.14 audit environment. The final frozen
problem image uses Python 3.12 and its current resolved optional dependencies,
so four inventory cases move from pass to skip without a failure. With
`--network none`, its exact patch-state matrix is:

| Patch state | Pre-existing lane | Focused lane |
|---|---:|---:|
| test only | 702 passed, 3,548 skipped | 54 failed on pristine upstream |
| solution only | 702 passed, 3,548 skipped | not present |
| test then solution | 702 passed, 3,548 skipped | 54 passed |
| solution then test | 702 passed, 3,548 skipped | 54 passed |

Every state passed `git apply --check` and `git diff --check`. The two combined
orders produced identical complete diffs with SHA-256
`c3b6b43afca13831f6d5edf8961973deffa48fa28f45b6cbb226905ec2c6e845`.
The rebuilt problem image IDs are
`sha256:35ed8d719b721fe8ed6b52e327b4dc5b928a2833cdb030b3d88dc19d6c02967d`
for ARM64 and
`sha256:73fda2b22c93a8a73c5650508ae891ac4fffe3855e17295fcde319587b954d48`
for AMD64.

The Dockerfile-only compliance refreeze replaced the unsupported
`olympus-base-python` image with the permitted `olympus-base` image. Because a
Dockerfile is part of the immutable artifact set, the complete matrix above and
the mutation audit were repeated rather than inherited. Mutants 1-19 were each
run against the complete focused file in isolated `--network none` containers;
their results are the table above. Mutant 20 failed its isolated schema
sentinel. No focused survivor remained, so no new mutant required escalation
through the complete pre-existing lane. The participant prompt, tests,
reference behavior, and source pin did not change.

The later description-format refreeze removed manual mid-sentence line breaks
from the four participant-facing paragraphs without changing any word,
punctuation mark, requirement, test, reference behavior, source pin, or
Dockerfile instruction. Because `meta.md` is still an immutable submission
artifact, the four patch states, both application orders, and all 20 mutants
were run again under `--network none`. Results remained exactly as recorded in
the matrix and mutation table above, including the identical combined-diff
SHA-256. Calibration remained 0/10 throughout.

The collision-safety refreeze then removed three redundant prompt phrases and
renamed the focused file to
`tests/test_ome_pyramid_validation_a0d7bb.py`. The suffix `a0d7bb` was produced
by `openssl rand -hex 3` and contains neither banned token. The retained opening
still defines the validator as read-only and structural, the direct tag-330
rule still excludes transitively linked children, and the final paragraph still
states the actionable pixel, encoding, and schema prohibitions. No behavioral
requirement or test oracle was removed.

Because both `meta.md` and `test.patch` changed, fresh source copies were used
to repeat the four patch states, both application orders, and all 20 isolated
mutants under `--network none`. The matrix and mutation-table counts remained
unchanged. The combined diff hash changed only because the test pathname
changed and was identical in both orders. No focused survivor remained for
full-suite escalation; calibration stayed at 0/10.

An external fairness review then identified one ambiguity and one unfair
fixture. The prompt prohibited only online schema validation while the sentinel
rejected every `OmeXml.validate` call; the prompt now states the exact no-call
rule. The old missing-plane fixture changed `PlaneCount` from two to one, which
removed a mapping and did not prove its docstring claim. It was replaced with
`test_mapped_ome_plane_missing_from_primary_chain`: generated metadata retains
`PlaneCount="2"` but shifts `IFD="0"` to `IFD="1"`. With two primary IFDs, the
mapping therefore resolves to pages `[1, None]`; the second explicitly mapped
plane points to nonexistent primary IFD 2. This directly exercises the public
mapping requirement without imposing a Pixels-dimension policy.

The corrected prompt and test patch were applied to fresh source copies. Test
only passed the bounded 702-case baseline and failed all 20 focused cases;
solution only preserved the baseline; both combined orders passed the baseline
and all 20 focused cases and produced that predecessor's identical complete
diff.
All 20 mutants were recreated and rerun. In particular, mutant 16, which skips
`None` mapped pages, failed only the corrected mapping test, and mutant 20
failed the explicit no-`OmeXml.validate` sentinel. No focused survivor remained
for full-suite escalation. The reported 1-of-25 unfairness finding is closed
for this artifact version.

The subsequent S1/T4 review exposed three distinct gaps. First, a later mapped
primary IFD can be represented by `TiffFrame`; reading `base.keyframe` hid that
IFD's changed ImageWidth. The reference now seeks to every frame's own offset,
materializes its primary `TiffPage`, and compares one full-resolution XY shape
across the series. Mutant 21 restores the predecessor shortcut and fails only
that new base-shape case.

Second, the zero-offset probe did not reach child parsing. The new malformed
fixture writes a nonzero tag-330 offset beyond EOF and verifies both documented
failure modes without matching an internal exception. Mutant 22 deliberately
re-raises `TiffFileError` and fails only this case. An attempted mutant that
caught `ValueError` survived, but was rejected as legitimate because repository
`TiffFileError` subclasses `ValueError`; it correctly normalizes the parser
failure and violates no public behavior.

Third, the repository implements reduced-image status as
`bool(subfiletype & 0b1)`. The strict-valid `subfiletype=3` fixture rejects
equality-based implementations while preserving independent legal bits. Mutant
23 requires equality with one and fails only this case. After these prompt,
test, and reference changes, fresh source copies passed that version's
four-state matrix and both application orders, and all 23 mutants were
recreated and killed. No tifffile solver patch existed to replay at that
refreeze. Calibration remained 0/10.

The multi-file review then identified a repository-supported scope that the
single-file fixtures did not exercise. The generated replacement metadata maps
one 64x64 plane from each of two named OME-TIFF files. Both files have the same
layout, including equal numeric child offsets, so a valid strict result proves
that offsets are namespaced by owning file. The test also confirms that the OME
loader closed the companion before validation, that validation restores that
closed state, and that neither file's bytes change.

Two mutations affect only the secondary TIFF: one removes a child relationship
and one changes a child's ImageLength. They leave series construction intact
while rejecting a root-only validator. Mutant 24 skips non-root parents;
mutant 25 rejects every multi-file series; mutant 26 leaks the reopened
companion; and mutant 27 merges offsets across files. Their focused results are
22/24, 23/24, 23/24, and 23/24 respectively. All 27 mutants were recreated
against the final prompt, tests, reference, and approach; none survived. No
full-suite escalation was needed beyond the reference's bounded 702-case lane.
Calibration remains 0/10.

The subsequent description review removed the summary clause “Evaluate
primary-chain membership, offset identity, ownership, and topology within each
plane's owning file.” The following sentences still state every behavioral
requirement precisely, and the companion open/close restoration remains
explicit. This changed only `meta.md`; tests, reference behavior, source pin,
Dockerfile, and solution approach did not change.

Fresh source copies repeated the four patch states and both application orders
under `--network none`: the bounded lane remained 702 passed and 3,548 skipped,
pristine upstream failed all 24 focused cases, and both combined orders passed
24/24. All 27 isolated mutants were rerun with unchanged outcomes and no
focused survivor. The combined source-tree hash remains unchanged because the
description is not applied to the repository. Calibration remains 0/10.

The T3/T4 strict-shape review then identified that the RGB-to-grayscale case
changed both page axes and a nonspatial dimension size. It was replaced with
two independently parametrized cases. The axes case compares contiguous RGB
`YXS` with separate-planar RGB `SYX` while both retain `S=3`; the size case
keeps contiguous `YXS` while changing `S` from three to four. Both remain valid
in default mode and fail only in strict mode.

Mutant 28 retains only the page-axis comparison and fails only the size case.
Mutant 29 retains only the nonspatial-size comparison and fails only the axes
case. Fresh source copies repeated the four-state matrix and both application
orders under `--network none`; pristine upstream failed all 25 cases, both
combined orders passed 25/25, and the bounded lane remained 702 passed and
3,548 skipped. All 29 isolated mutants were killed. No solver patch exists to
replay and no focused survivor required a new complete-suite escalation.
Calibration remains 0/10.

An environment-quality review then showed that platform checks invoking
`python -m pytest` directly bypassed the skip controls local to `test.sh`.
On 64-bit systems tifffile enables its large and extended inventories by
default, and the prior platform run was killed with exit 137 near 90 percent.
The Dockerfile now exports the same six repository-supported controls used by
the harness: `SKIP_LARGE`, `SKIP_SLOW`, `SKIP_EXTENDED`, `SKIP_FILE`,
`SKIP_VALIDATE`, and `SKIP_HTTP`.

The image was rebuilt with `--pull`; the Olympus base resolved to the same
digest. `python setup.py build` succeeds in the rebuilt image. Without any
command-level environment overrides, direct `python -m pytest -q` completes at
702 passed and 3,548 skipped on pristine upstream and at 727 passed and 3,548
skipped on the combined problem tree. The four-state matrix remains 702 base
passes plus the expected 25 focused failures or passes, both patch orders keep
the same complete-diff hash, and all 29 isolated mutants were rerun and killed.
The Dockerfile was also built for Linux AMD64; `python setup.py build` and both
direct pytest checks completed there with identical counts. No prompt, test,
reference, or solution-approach behavior changed. Calibration remains 0/10.

The companion-lifecycle review then exposed an asymmetric oracle. The existing
multi-file fixture covered only the state produced by OME loading: a cached
companion that was closed before validation and had to remain closed. The
participant wording now explicitly requires restoration of each companion's
prior open or closed state, and the same generated fixture is parametrized to
start once closed and once explicitly open.

Mutant 30 unconditionally closes every companion after validation. It passes
the closed case and fails only the new open case, finishing at 25/26. The
reference already records `was_closed`, opens only when necessary, and closes
only companions that started closed, so no production change was required.
Fresh source copies repeated all four patch states under `--network none`:
pristine upstream failed 26/26 focused cases, both combined orders passed
26/26, and every state retained the 702-pass, 3,548-skip bounded lane. The two
combined orders produced the identical complete-diff SHA-256 recorded above.
All 30 isolated mutants were rerun and killed; none required complete-suite
escalation. Direct `python -m pytest -q` completed without command-level
overrides at 728 passed and 3,548 skipped on both ARM64 and AMD64 combined
trees. The source pin, reference patch, solution approach, Dockerfile, base
digest, and image IDs are unchanged. Calibration remains 0/10.

Five platform solver bundles were then supplied for the 26-case predecessor.
Runs 2 and 4 were legitimate 26/26 passes; runs 1 and 3 missed direct child
`NextIFD` rejection, and run 5 missed a later full-resolution IFD's own shape,
each finishing at 25/26. The successful patches add 264 and 477
strict-effective production lines, for a 370.5 median, but both modify only one
production file. The ATIF schema does not expose the platform agent-message
metric. Exact run IDs, approaches, proactive checks, and patch measurements are
recorded in `DESIGN.md` and `RUNS.md`.

Reviewing those patches together with the external gap report exposed seven
public boundaries. Most importantly, both legitimate passes used `>` for the
adjacent-area rejection and therefore accepted equal-area child levels despite
the public word “strictly.” The prompt now defines default order as strictly
decreasing plane area, allows an individual axis to grow between child levels
when area still decreases, states that odd axes round independently, makes
base/child storage-layout independence explicit, and requires companion-state
restoration on success and both failure modes.

The focused suite now separately checks unequal per-plane level counts, equal
adjacent areas, X and Y base-relative reduction, valid area order with one child
axis growing, mixed floor/ceiling rounding, tiled-base/stripped-child storage,
and the four combinations of initially open/closed companion state with
False-returning/assertion failure. Mutants 31-40 isolate those boundaries. Each
new mutant fails its intended case or cases, and all 40 mutants in that version
are killed. No mutant survived for full-suite escalation.

All five saved solver patches were replayed against the 36-case suite. Runs 2
and 4 now finish at 35/36, failing only equal-area strict ordering. Runs 1, 3,
and 5 finish at 34/36, retaining their original single failure and also failing
equal-area ordering. These are fair replays of the clarified public contract,
not calibration runs for the revised artifact.

Fresh source copies repeated all four patch states and both application orders
under `--network none`. Pristine upstream fails 36/36 focused cases, both
combined orders pass 36/36, and every state retains the 702-pass, 3,548-skip
bounded lane. The combined orders had an identical complete diff for that
version. Direct `python -m pytest -q` completes at 738 passed and 3,548
skipped on ARM64 and AMD64; `python setup.py build` also succeeds on both. The
reference patch, Dockerfile, image IDs, source pin, and base digest remain
unchanged.

Under `CALIBRATION_STRATEGY.md`, changing the prompt, tests, and solution
approach abandons the predecessor's preliminary 2/5 batch. At that refreeze,
the revised Level 2 artifact returned to 0/10. No cold solver was launched for
that version.

The unreopenable-companion review then identified a separate I/O boundary
inside the existing malformed-or-unreadable requirement. The new generated
fixture first lets OME loading map and close a valid companion, then moves that
companion path before validation attempts temporary access. Return mode must
produce `False`, assertion mode must raise `AssertionError`, and neither may
leak the resulting `FileNotFoundError`; the cached handle remains closed.

Mutant 41 rethrows `OSError` while preserving the reference's normalization of
all other parser and structural exceptions. It passes every Level 2 case and
fails only the two new parameter instances, finishing 36/38. The other 40
mutants were recreated with the exact current focused file and remain killed at
the counts above. No current survivor required complete-suite escalation.

All five saved solver patches were also replayed. Their broad exception
normalization accepts the new failure outcome, so runs 2 and 4 finish at 37/38
and runs 1, 3, and 5 finish at 36/38, retaining only their earlier behavioral
failures. These are predecessor replays, not Level 3 calibration.

Fresh source copies repeated all four patch states and both application orders
under `--network none`. The bounded lane remains 702 passed and 3,548 skipped;
pristine upstream fails 38/38 focused cases; and the reference passes 38/38 in
both orders. The two combined trees have the identical SHA-256 recorded above.
Direct `python -m pytest -q` completes at 740 passed and 3,548 skipped on ARM64
and AMD64, and `python setup.py build` succeeds on both. The prompt, reference,
solution approach, Dockerfile, source pin, base digest, and image IDs are
unchanged.

Changing `test.patch` created Level 3 and abandoned Level 2 before any solver
run. At that refreeze, Level 3 returned to 0/10; the completed Level 3 batch is
recorded below.

The completed Level 3 batch contains ten bundles with identical rendered
prompt and focused-test hashes. Four patches legitimately pass 38/38, and the
other six are killed by explicit public behaviors: cached-frame handling,
direct child reachability, later-IFD base shape, and malformed-input exception
normalization. Exact offline replay reproduces every evaluator result. All ten
baselines are 702/702, and every evaluator reports deterministic tests, a clear
description, no environment blocker, and no unfair agent blame.

The new companion-reopen cases do not fail any solver patch. Two audit-only
positive probes were run against all ten implementations and the reference. A
legal bilevel pyramid with `NewSubFileType=5` and a pyramid carrying private tag
65000 both pass every implementation. The calibrated solve rate is therefore
not hiding a false negative from either review concern.

A synthetic mutant that accepts only `NewSubFileType` values 1 and 3 compiles
and passes the Level 3 suite. Although all ten independent patches naturally
mask bit zero and the repository's `TiffPage.is_reduced` does the same, the
operator requested explicit positive coverage for another legal bit. Level 4
therefore promotes the already-prototyped value-5 probe. The reference and all
ten saved patches pass it, while the whitelist mutant fails only that case.

Level 4 also removes the undefined “unrelated tag choices” phrase instead of
trying to test an unbounded promise with private tags. The concrete tile,
strip, compression, mixed-layout, no-decode, and no-schema-validation clauses
remain mapped to behavioral tests.

The exact 39-case audit is zero-survivor for the attempted 42-mutant set. Both
patch orders apply cleanly and produce complete-diff SHA-256
`2ce20e7a98bd8653f614e7029d4a65ca443af9753d453dd7388afb18cae8980c`.
Pristine upstream fails 39/39, the reference passes 39/39, the bounded lane is
702 passed and 3,548 skipped, direct combined pytest is 741 passed and 3,548
skipped, and the build succeeds under `--network none`.

The ten Level 3 patch replays finish at 37, 39, 38, 39, 38, 37, 28, 39, 37,
and 39. Every patch accepts the new positive, so the same six public failure
families remain. These are replay evidence, not Level 4 calibration. Changing
the prompt and tests abandons the Level 3 4/10 result and starts Level 4 at
0/10.

Level 5 parametrizes the mixed-layout positive in both directions. The new
stripped-base/tiled-child case is justified by the asymmetric TIFF tag sets for
tiles and strips, passes the reference and all ten saved patches, and does not
change any existing failure family. Mutant 43 rejects only tiled children of a
stripped base. It passes the 39 predecessor cases and the complete 702-test
baseline, then fails only the new parameter.

The exact Level 5 audit kills all 43 mutants. Both patch orders produce
complete-diff SHA-256
`fba2fb8a43c706278b48eb0734d53ff46711e29aa4c1cb9a245e7d38c6770468`.
Pristine upstream fails 40/40, the reference passes 40/40, the bounded lane is
702 passed and 3,548 skipped, direct combined pytest is 742 passed and 3,548
skipped, and the build succeeds under `--network none`. Saved-patch replay
counts are 38, 40, 39, 40, 39, 38, 29, 40, 38, and 40. Level 5 remains at
0/10.

Level 6 adds the mixed-sibling storage parameter. Mutant 44 treats the first
child's tile/strip choice as series-level state and rejects a later child that
differs. It passes all 40 Level 5 cases and the complete 702-test baseline,
then fails only `mixed-children`. The reference and all ten saved patches pass
the new case.

The exact Level 6 audit kills all 44 mutants. Both patch orders produce
complete-diff SHA-256
`7c64e1e1bdcfd82d6508d6c116840e08b44270ded723c8379a005c7cce3fe5b6`.
Pristine upstream fails 41/41, the reference passes 41/41, the bounded lane is
702 passed and 3,548 skipped, direct combined pytest is 743 passed and 3,548
skipped, and the build succeeds under `--network none`. Saved-patch replay
counts are 39, 41, 40, 41, 40, 39, 30, 41, 39, and 41. Level 6 remains at
0/10.

Level 7 promotes five distinct demonstrated survivors. Mutant 45 bypasses the
outer assertion adapter only for strict failures. Mutant 46 scopes ownership
state per OME series. Mutant 47 treats an empty OME-series collection as a
vacuous success after checking `is_ome`. Mutant 48 compares tile dimensions
when every page is tiled. Mutant 49 requires each strict axis to decrease at
every adjacent step, rejecting the valid `ceil(1 / 2) == 1` fixed point. Each
implementation passes the other 45 focused cases and all 702 baseline tests,
then fails only its matching black-box probe.

All 44 predecessor mutants were rerun against the exact 46-case file and
remain killed with the counts above. The five new mutants were also run through
the complete pre-existing lane. The reference passes 46/46, pristine upstream
fails 46/46, and both patch orders produce complete-diff SHA-256
`4bf413c8bf3402a9af3da320654b7b668224f326be33d97d7aaf31ebfbceffe3`.
The bounded lane remains 702 passed and 3,548 skipped, direct combined pytest
is 748 passed and 3,548 skipped on ARM64 and AMD64, and the build succeeds on
both architectures under `--network none`.

Exact replay of the ten saved Level 3 patches yields 43, 45, 44, 45, 44, 44,
35, 46, 42, and 46 passes. Runs 1 and 9 expose empty-series vacuity; runs 2,
3, 4, 5, and 9 reject the valid unit-axis reduction. Runs 8 and 10 pass the
entire Level 7 suite. These are public-behavior replays, not cold runs or
current calibration. Level 7 remains at 0/10.

Level 8 removes `test_ome_marker_without_ome_series_is_invalid`. The public
description does not decide whether an `is_ome` marker with no exposed OME
series is invalid, and the repository permissively recognizes that marker
without supplying a validation policy. Mutant 47 consequently passes 51/51 and
is withdrawn as an artificial distinction rather than treated as a surviving
incorrect implementation.

Nine new isolated mutants cover the remaining review findings. Three
independently whitelist compression, square tiles, or full-height strips;
three inspect the reduced-image bit, axes, or nonspatial size only on the first
child; one enforces required XY reduction only on the first child; one decodes
through `TiffPage.segments`; and one compares only ImageWidth across mapped
full-resolution planes. Each passes the other 50 focused cases and the complete
702-test baseline before failing only its intended public probe. All 48 retained
predecessor mutants were rerun against the exact file and remain killed, for 57
current actionable mutants total.

The reference passes 51/51, pristine upstream fails 51/51, and both patch
orders produce complete-diff SHA-256
`53bc69c1b93ba92bec53112ab712e8dff3ade04de1548052c8a8c04f754034cd`.
The bounded lane remains 702 passed and 3,548 skipped, direct combined pytest
is 753 passed and 3,548 skipped on ARM64 and AMD64, and the build succeeds on
both architectures under `--network none`.

Exact replay of the ten saved Level 3 patches yields 49, 50, 49, 50, 49, 49,
40, 51, 47, and 51 passes. Every saved patch accepts the new legal-storage and
later-child cases except run 9's already-known keyframe shape shortcut also
hides the new ImageLength mismatch. Runs 8 and 10 pass the entire Level 8
suite. These are fairness replays, not cold runs or current calibration. Level
8 remains at 0/10.

Level 9 closes two demonstrated false-positive families after inspecting all
run-3 trajectories and patches. The valid `3x11 -> 1x4 -> 1x2` pyramid requires
retaining every locally compatible odd-rounding factor until the series-wide
intersection is known. Mutant 59 greedily selects the smallest local factor;
it passes the other 52 cases and all 702 pre-existing tests, then fails only
`test_strict_accepts_ambiguous_odd_factor_sequence`.

The malformed relationship fixture changes the required Pixels
`DimensionOrder` attribute to an unknown same-length name. The repository's OME
series builder consequently raises `KeyError`. Mutant 60 normalizes the parser
and I/O exception families reached by every predecessor fixture but leaks that
metadata exception. It passes the other 52 focused cases and the complete
pre-existing lane, then fails only
`test_malformed_ome_relationship_uses_validation_result`. This differs from
the withdrawn empty-marker oracle: the file contains a concrete Pixels
relationship whose required field is malformed, and the public contract
already normalizes malformed pyramid relationships.

All 58 predecessor mutant trees were rerun with the exact 53-case file. The 57
actionable predecessors remain killed, mutant 47 remains a 53/53 withdrawn
implementation, and the two new mutants are killed, for 59 actionable kills in
the attempted set. Every one of the 60 trees also passes 702 pre-existing tests
with 3,548 skips.

Fresh source copies reproduce the four-state matrix above. Both application
orders produce complete-diff SHA-256
`90b48713ce3f9b23f91c9a468fb119ed0ad0179b4742e36979471e4bb925a3c3`.
Direct combined pytest completes at 755 passed and 3,548 skipped on ARM64 and
AMD64; `python setup.py build` succeeds on both; `setup.py check`, `pip check`,
`compileall`, shell syntax, and collection of all 53 cases succeed offline.
The frozen image does not include Black or Ruff, so those optional commands
were unavailable rather than treated as passing checks.

All ten saved Level 3 implementations apply cleanly and replay at 51, 51, 50,
51, 50, 49, 42, 53, 48, and 53. All fourteen delivered run-3 bundles were also
replayed: the ten substantive evaluated implementations retain five passes and
five public failures, two unscored implementations remain failures, and the two
empty patches fail because the API is absent. Every replayed tree passes its
pre-existing lane, including any solver-authored tests. No cold solver was
launched.

The two run-3 early terminations stop after their initial agent message without
a tool call or solution patch. In contrast, their test logs complete the
702-case baseline and all 51 then-current focused cases. The direct Level 9
quality suite also completes normally. This is agent/orchestration termination,
not an environment, image, verifier, or resource crash, so no Dockerfile or
harness change is justified.

Level 10 removed the repository-internal phrase about why a companion is
closed, but it also added a `6x6 -> 2x2 -> 1x1` positive whose constant factor
three exceeds the later even parent dimensions. Fairness review found that the
public wording relaxes exact division only for odd dimensions and that the
neighboring repository `subresolution` helper explicitly rejects a factor
larger than the current parent. The test, matching reference expansion, and
mutant 61 are therefore withdrawn rather than defended by expanding the
prompt. Level 10 remains historical at 0/10 and is not a valid calibration
target.

Level 11 retains the observable companion reopen-and-restore wording and
restores the repository-aligned factor domain. Fresh source copies reproduce
all patch states and both application orders. The two combined orders have
complete-diff SHA-256
`90b48713ce3f9b23f91c9a468fb119ed0ad0179b4742e36979471e4bb925a3c3`.
The exact focused suite is 53/53, all 59 actionable mutants are killed, mutant
47 remains withdrawn at 53/53, and all 60 retained mutation trees pass 702
pre-existing tests with 3,548 skips.

Direct combined pytest completes at 755 passed and 3,548 skipped on ARM64 and
AMD64. `python setup.py build`, `setup.py check`, `pip check`, `compileall`,
shell syntax, and collection of all 53 cases succeed offline on both
architectures. Black and Ruff remain unavailable in the frozen image rather
than being reported as passing checks.

The ten saved Level 3 patches replay at 51, 51, 50, 51, 50, 49, 42, 53, 48,
and 53. The fourteen run-3 bundles replay at 48, 49, 52, 0, 53, 53, 53, 48,
53, 49, 0, 53, 51, and 42. The ten substantive evaluated implementations
retain the same five passes and five public failures as Level 9. Every replayed
tree passes its complete pre-existing lane, including 0-3 solver-authored
tests. No cold solver was launched.

Level 12 extends the existing missing-primary mapping test across root and
named-companion ownership. The companion parameter writes an OME mapping for
IFD 1 in a companion with one primary page, verifies that the repository loader
leaves the mapped plane absent, and observes only the configured validation
result. Mutant 62 skips absent mappings when OME metadata names a companion; it
passes the other 53 focused cases and all 702 pre-existing tests, then fails
only the companion parameter. Historical mutant 61 remains withdrawn with the
unfair Level 10 boundary and is not part of the current mutation set.

The reference now derives compatible factor intervals arithmetically rather
than enumerating every integer through the larger parent dimension. This is a
solution-quality change, not a participant requirement, so no timing oracle was
added. Extracting the exact helper from the applied reference and comparing it
with the former enumeration produced identical factor sets for 189,225
combinations of parent and child shapes through dimension 30. A
`1,000,000,000 x 900,000,000` parent to `1 x 1` transition produces the single
range `(500000001, 1000000000)` without dimension-proportional iteration.

Fresh source copies reproduce all patch states and both application orders.
The two combined orders have complete-diff SHA-256
`aa5fa384706a8c86189fde58c2d91ac9a9dacc1789c0dcce497cfe364ad3e4cd`.
The exact focused suite is 54/54, all 60 actionable mutants are killed, mutant
47 remains withdrawn at 54/54, and all 61 retained mutation trees pass 702
pre-existing tests with 3,548 skips.

Direct combined pytest completes at 756 passed and 3,548 skipped on ARM64 and
AMD64. `python setup.py build`, `setup.py check`, `pip check`, `compileall`,
shell syntax, and collection of all 54 cases succeed offline on both
architectures. Black and Ruff remain unavailable in the frozen image rather
than being reported as passing checks.

The ten saved Level 3 patches replay at 52, 52, 51, 52, 51, 50, 43, 54, 49,
and 54. The fourteen run-3 bundles replay at 49, 50, 53, 0, 54, 54, 54, 49,
54, 50, 0, 54, 52, and 43. The ten substantive evaluated implementations
retain five passes and five public failures. Every replayed tree passes its
complete pre-existing lane, including 0-3 solver-authored tests. No cold solver
was launched.

Level 13 guards the optional PackBits, LZW, and ZSTD fixture with
`pytest.importorskip('imagecodecs')` plus the three codec availability flags,
matching the pinned repository's own setup policy. With the frozen encoders,
the reference still passes 54/54 and pristine upstream fails 54/54. With
`SKIP_CODECS=1`, the reference passes all 53 runnable cases and skips only the
codec fixture; pristine upstream fails the same 53 runnable cases and skips the
same fixture. The no-codec result is identical on ARM64 and AMD64.

This fairness repair creates no behavioral mutant and changes no reference
result. All 60 actionable mutants retain their Level 12 focused failures,
mutant 47 remains withdrawn at 54/54, and all 61 retained trees pass 702
pre-existing tests with 3,548 skips. All saved replay scores and pre-existing
lanes are unchanged. No cold solver was launched.

Fresh source copies reproduce all patch states and both application orders.
The two combined orders have complete-diff SHA-256
`c3b6b43afca13831f6d5edf8961973deffa48fa28f45b6cbb226905ec2c6e845`.
Direct combined pytest completes at 756 passed and 3,548 skipped on ARM64 and
AMD64. `python setup.py build`, `setup.py check`, `pip check`, `compileall`,
shell syntax, and collection of all 54 cases succeed offline on both
architectures. Black and Ruff remain unavailable in the frozen image rather
than being reported as passing checks.

## Rejected or artificial probes

- A separate “SubIFD referenced by `TiffData` but not primary” probe is not
  constructible: `TiffData` names a primary-chain IFD index. It is the same
  storage violation as primary aliasing, not a second offset namespace.
- BigTIFF, byte-order, filename, and additional dimension permutations repeat
  the same public relationships without another semantic boundary.
- Rejection of an `is_ome` marker with no exposed OME series is withdrawn. The
  prompt does not resolve that malformed-metadata boundary, and repository
  recognition alone does not establish a validator outcome.
- Further `NewSubFileType` combinations remain rejected after values 0, 1, 3,
  and 5 establish the missing-bit and independent legal-bit boundaries. More
  flag combinations would repeat the same bitmask invariant.
- Further corrupt-offset values and private cache mutations were rejected after
  the nonzero beyond-EOF case established parser-exception normalization.
- A companion missing before OME series construction, more companion counts,
  and byte-order variants remain rejected after the valid multi-file and
  secondary-only probes established file coverage. Post-load companion
  unavailability is now covered separately as an access-failure boundary.
- Repeated open/close toggles and multiple already-open companions were rejected
  after the paired closed/open cases established prior-state restoration in both
  directions.
- More planar configurations, axis permutations, and sample counts were
  rejected after first- and later-child cases established axis identity/order
  and nonspatial cardinality as separate boundaries.
- Additional compression codecs, strip heights, and tile-size permutations
  were rejected after PackBits, LZW, Zstd, a short strip, rectangular tiles,
  both layout directions, and mixed sibling levels established storage
  independence. The decoding sentinels separately establish pixel opacity.

A zero-survivor result applies only to this attempted mutation set. Any change
to the prompt, tests, reference behavior, Dockerfile, or source pin creates a
new immutable version and requires this audit again.
