# DESIGN - OpenEXR multipart high-level Image I/O

Status: `immutable revision v17 exact gates pass; calibration 0/10`.

Repository: `AcademySoftwareFoundation/openexr` at
`c101ab742a9e93c8c9c6f1781055e938cc160305`.

## Revision v17 unsupported-source replacement design gate

Before revising `test.patch`, I reread the mandatory design, environment, gap,
fairness, false-positive, and calibration protocols. The history search covered
the OpenEXR entries in `problems/README.md`, `candidates/CANDIDATES.md`, and
`candidates/SUCCESSES.md`, then this problem's current `SUMMARY.md`,
`DESIGN.md`, `LEVELS.md`, `ERRORS.md`, and `RUNS.md`. I inspected the raw run-8
patches, evaluations, and trajectory tool calls for legitimate solution 2, near
solution 3, and broad solution 5. Their production additions are 1,275, 1,119,
and 1,422 lines across the two library files; the near and broad runs also add
visible `testIO.cpp` checks. Platform agent-message counts are unavailable in
the ATIF records, which contain one agent envelope with 100, 71, and 131 tool
calls respectively; tool-call counts are not substituted for that metric.

All three implementations keep supported-source classification in the
replacement match. Solution 2 builds rewrite results only after skipping an
unsupported type and validates replacement names against those results.
Solution 3 builds its name map from `supportedParts`. Solution 5 requires the
matched source descriptor's `supported` flag. Their planning structures differ,
so this is useful legitimate-architecture evidence rather than a private helper
convention. The broad run still fails unrelated mipmap writer behavior.

The current verifier separately covers a replacement whose name is absent from
the file and a rewrite that skips an unsupported source sibling. It never
crosses those cells. An implementation may index every source name first, mark
a replacement as matched by an unsupported header, then skip that source from
output. That violates the prompt's explicit requirement to reject names that do
not match a supported source part while passing both existing checks. The v16
reference already filters unsupported parts before matching, so no reference or
prompt change is needed.

### Revision v17 trajectory-informed discriminator ledger

| Evidence | Generalized shortcut or risk | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|---|
| Existing tests separate absent-name rejection from unsupported-source skipping; independent solver plans explicitly restrict their name maps or match scans to supported sources | Treat any exact source-header name as a successful replacement match, even when that part is later omitted as unsupported | A replacement name must identify a supported source part; a name present only on an unsupported part is unmatched | Build a valid mixed multipart source, change one uniquely typed named part to an unknown type, then require both rewrite overloads to reject a replacement carrying only that name before changing output | Crosses source eligibility with matching once; it does not repeat every unsupported type, image family, source position, or name permutation |

The planned fixture derives the malformed source from a low-level file produced
by the repository helpers and replaces one unique, equal-width type string. The
existing byte helper proves the target encoding occurs exactly once. A targeted
mutant will mark replacements as used when their names match an unsupported
header before continuing past that part. The probe stays in `RewriteValidation`,
uses no exception-message oracle, and reuses the already-public pre-modification
boundary for invalid replacements. This gate is complete before editing
`test.patch`.

## Revision v17 exact discriminator result

`RewriteValidation` now creates a two-part source named `supported-only` and
`unsupported-only`, changes the latter's unique `tiledimage` type value to the
equal-width unknown value `unknown___`, and self-checks that the new value is
not any supported part type. A replacement named `unsupported-only` is then
rejected by both filename and stream rewrites. The existing destination-safety
helper proves that the filename sentinel is unchanged and stream output remains
empty, as the public invalid-replacement rule promises.

The isolated `rewrite_matches_unsupported_source_name` production mutant is
killed only by the new `RewriteValidation` assertion. The complete exact audit
runs 76 variants: all 75 behaviorally incorrect variants are killed, while the
duplicate-validation delegation survivor remains behaviorally equivalent and
passes 14/14 focused plus 127/127 pre-existing tests in 380.09 seconds. Run-8
solutions 1, 2, 3, and 5 retain 13/14, 14/14, 12/14, and 6/14 focused scores;
all pass the new predicate and 4/4 existing tests. The fresh no-cache
environment gate passes offline as UID/GID 10001. Exact gap, fairness, and
false-positive verdicts are `pass`; calibration restarts at 0/10.

## Revision v16 named legacy replacement design gate

Before revising `test.patch`, I reread the mandatory design, environment, gap,
fairness, false-positive, and calibration protocols. I searched the OpenEXR
entries in `problems/README.md`, `candidates/CANDIDATES.md`, and
`candidates/SUCCESSES.md`, then reviewed this problem's `SUMMARY.md`,
`DESIGN.md`, `LEVELS.md`, `ERRORS.md`, and `RUNS.md`. Raw run-8 patches,
evaluations, and trajectory tool calls were inspected for the two legitimate
passes, the 12/14 near-pass, and the broad failure. The new solution-quality
report supplies an additional concrete survivor: the revision-v15 reference
passes the focused suite while ignoring a matched replacement on a named,
typeless ordinary flat source.

The repository's existing `saveImage(filename, header, image)` overload accepts
a header with a name and writes an ordinary flat file without requiring a
multipart `type`. Such a file is a supported single-part source. The public
rewrite rule says a replacement's exact name identifies one supported source
part; its producer form does not exempt legacy typeless files. The v15 reference
correctly builds a matched rewrite plan, but then takes its exact-header raw-copy
branch whenever the source is flat, single-part, and typeless. That branch
checks neither the plan nor the replacement collection.

The raw trajectories show that this is not an unavoidable consequence of
legacy preservation. Run-8 solution 2 enters its whole-file copy path only when
`replacements.empty()`. Run-8 solutions 1 and 5 select replacement behavior per
source part. The near-pass also stores replacement pointers per planned output
slot. These architectures separate "preserve an unmatched legacy part" from
"apply a matched replacement" even though they differ in reader and writer
structure.

### Revision v16 trajectory-informed discriminator ledger

| Evidence | Generalized shortcut or risk | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|---|
| The v15 reference validates and matches a replacement, then lets a producer-specific raw-copy fast path override the plan; independent solver architectures guard the copy path or dispatch per planned part | Choose untouched publication from source shape alone instead of the matched rewrite state | An exact-name replacement applies to every supported named source part, including an ordinary typeless flat single-part producer | Create a named typeless source with the existing `saveImage()` overload, replace it through filename and stream rewrites, and compare the complete emitted replacement header and image with the public `saveImages()` result | Crosses replacement selection with the already-supported legacy producer once; it does not prescribe singular versus multipart output, a copy helper, or internal planning order |

The planned reference correction limits the exact raw-copy path to an unmatched
plan entry. The planned test extends `SinglePartLoad`, where the producer is
already self-checked as ordinary and typeless, with one named source and one
matching replacement through both transports. A targeted production mutant
will deliberately raw-copy only this named typeless replacement case. No prompt
change or new rejection predicate is needed. This gate is complete before
editing `test.patch`.

## Revision v16 exact result

Final identity: `meta 926a2b88`, `test 68ee33f5`, `solution 55307ae4`,
`Dockerfile fc0ce006`, mutation script `42b06c08`.

`SinglePartLoad` now creates a named, typeless ordinary tiled file with the
existing `saveImage()` overload and self-checks that producer state through
`TiledInputFile`. Matching replacements are applied through filename and
stream rewrites. Their complete output headers are compared with the public
`saveImages()` result, and their full image payloads are compared with the
replacement image. An unmatched typeless source still exercises exact raw
preservation separately.

The reference now takes its singular raw-copy path only for an untouched
typeless flat source. A matched replacement uses the normal replacement writer
for both transports. This is a state guard, not a required implementation
shape: the independent run-8 solution 2 remains 14/14.

The fresh no-cache gate rebuilt 285/285 targets offline as UID/GID 10001. The
pristine existing lane passed 4/4 and its focused lane produced the expected
missing-API Build failure with the full 14-node JUnit report. The reference
passed 4/4 existing and 14/14 focused, with matching focused identities.

The exact mutation audit ran 75 variants. All 74 behaviorally incorrect
variants were killed, including the named-typeless raw-copy shortcut. The only
survivor delegates duplicate-name validation to OpenEXR and passed 14/14
focused plus 127/127 pre-existing tests in 328.64 seconds. Exact run-8 replays
all passed 4/4 existing and scored 13/14, 14/14, 12/14, and 6/14 focused for
solutions 1, 2, 3, and 5. Gap, fairness, and false-positive audits pass. Any
fresh calibration starts at 0/10.

## Revision v15 legacy-load-header fairness gate

Before changing `test.patch`, I reread the mandatory design, environment, gap,
fairness, false-positive, and calibration protocols. The history search covered
the OpenEXR entries in `problems/README.md`, `candidates/CANDIDATES.md`, and
`candidates/SUCCESSES.md`, plus this problem's `SUMMARY.md`, `DESIGN.md`,
`LEVELS.md`, `ERRORS.md`, and `RUNS.md`. The closest raw evidence is the first
solver batch: `agent-runs1/Nova_Nova_1` is a legitimate near-pass whose patch,
trajectory, and evaluation show that it inferred the missing single-part type
for dispatch but returned the original typeless header. The independent pass
`Nova_Nova_2` used `MultiPartInputFile`'s normalized header. A broad failure is
not available in that batch, as the revision-v3 record already notes.

The revision-v14 rewrite probe correctly switched its source and output oracles
to `TiledInputFile`, because the public rewrite contract says an untouched part
is kept without changing its header. However, the same test also compared each
`loadImages()` result with `MultiPartInputFile::header(0)`. That constructor's
default `autoAddType` behavior synthesizes `TILEDIMAGE`, while the existing
high-level singular load path exposes the raw typeless header. The prompt does
not choose between those two reasonable returned-header forms for legacy input.
This is the same unfair normalization choice corrected in revision v3 and is
not justified by the later rewrite requirement.

### Revision v15 trajectory-informed discriminator ledger

| Evidence | Generalized shortcut or risk | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|---|
| A legitimate solver infers a missing legacy type only for dispatch; repository singular and multipart readers expose different header forms | Treat a convenient decoding view as the uniquely required public `loadImages()` header | Legacy ordinary files decode successfully with their complete existing metadata, image class, levels, channels, and samples; no normalization of an absent `type` is prescribed | Compare the returned and exact singular headers after erasing only `type` from local copies, then check the decoded image | Accepts raw and normalized returned headers while still detecting loss of every other header attribute |
| The public rewrite rule explicitly requires untouched headers not to change | Removing the unfair load assertion could accidentally weaken the separate rewrite invariant | An untouched typeless ordinary source remains typeless and otherwise header-identical after rewrite | Continue inspecting source and filename/stream rewrite outputs through `TiledInputFile` and compare their exact raw headers | Separates output fidelity from load-result representation and asserts only the stated rewrite behavior |

No new discriminator or prompt rule is added. Revision v15 replaces the three
comparisons with a normalization-agnostic complete-header oracle and removes the
`MultiPartInputFile` header oracle. All exact raw rewrite-header and
decoded-payload checks remain. This gate is complete before revising
`test.patch`.

## Revision v15 exact result

Final identity: `meta 926a2b88`, `test 2a4ab32c`, `solution d0c75ee5`,
`Dockerfile fc0ce006`, mutation script `63825bd5`.

`SinglePartLoad` now compares each returned legacy header with the exact
singular-reader header after erasing only `type` from local copies. Raw and
type-synthesized return values are both valid, while loss of any other public
attribute still fails. The separate rewrite oracle remains exact: the source
and both untouched outputs are inspected with `TiledInputFile`, must remain
typeless, and must retain the complete raw header and decoded image.

The fresh no-cache environment gate rebuilt all 285 targets offline as UID/GID
10001. The pristine tree passes 4/4 existing tests and reaches the expected
missing-API focused `Build` failure with a 14-node JUnit report. The reference
passes 4/4 existing and 14/14 focused, with matching testcase identities. A
provisional patch with a stale new-file hunk count was quarantined at
composition; every exact-version gate restarted after the metadata was fixed.

A legitimate alternative that returns the raw singular-reader header while
using the multipart view only for dispatch passes 14/14. Exact run-8 replays
score 14/14, 13/14, 12/14, and 6/14; the 13/14 implementation now fails only
the separately public untouched-rewrite fidelity rule. The 74-variant mutation
audit kills all 73 behaviorally incorrect variants, including normalization of
the serialized typeless rewrite. The sole survivor delegates duplicate-name
validation to OpenEXR and passes 14/14 focused plus 127/127 pre-existing tests
in 320.70 seconds. Exact gap, fairness, and false-positive audits pass.
Calibration restarts at 0/10.

## Revision v14 replacement-cardinality and legacy-header design gate

Before changing `test.patch`, I reread the mandatory design, environment, gap,
fairness, false-positive, and calibration protocols. The history search covered
the OpenEXR rows in `problems/README.md`, `candidates/CANDIDATES.md`, and
`candidates/SUCCESSES.md`, then this problem's `SUMMARY.md`, `DESIGN.md`,
`LEVELS.md`, `ERRORS.md`, and `RUNS.md`. I inspected the raw run-8 patch,
evaluation, test log, and trajectory for the legitimate pass
`Nova_Nova_1`, the 12/14 near-pass `Nova_Nova_3`, and the 5/14 broad failure
`Nova_Nova_5`.

The legitimate pass builds a name-to-index map, records the selected
replacement index in every rewrite entry, and writes each matching entry. The
near-pass likewise builds a source-part map and stores a replacement pointer per
output slot. The broad failure maps every replacement name separately for both
filename and stream implementations. The hidden success fixture, however,
contains only one replacement, so a writer that validates the complete
collection but publishes only its first matching entry is not distinguished.

The pinned `MultiPartInputFile` constructor has an `autoAddType` path that adds
`SCANLINEIMAGE` or `TILEDIMAGE` to a legacy header that lacks `type`. Singular
`InputFile`/`TiledInputFile` expose the original header, and their matching
output classes accept filenames or caller streams and support `copyPixels()`.
The legitimate run-8 pass explicitly detects non-multipart input and uses a
singular-copy path; the broad failure also snapshots the exact single-part
header before multipart classification. The near-pass uses only
`MultiPartInputFile` headers and was already the historical unnamed-source
failure. Revision v13's reference removed the name rejection but still copies
the synthesized multipart header, while the test's source oracle makes the same
normalization and therefore misses the mutation.

### Revision v14 trajectory-informed discriminator ledger

| Evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|---|
| All inspected solvers validate a replacement collection separately from per-source publication; current success coverage has cardinality one | Validate every replacement, then apply only the first matching entry | Every valid replacement in the collection replaces its exact matching supported source part | Add a second distinct source and replacement, rewrite through filename and stream overloads, and compare both emitted headers and payloads with the public `saveImages()` oracle | Crosses collection iteration and source matching once; it does not permute order, prescribe a map, or repeat validation fixtures |
| `MultiPartInputFile(autoAddType=true)` normalizes a typeless legacy header; legitimate solvers retain an exact singular-header path | Reuse the normalized multipart header when structurally copying an untouched legacy source | An untouched supported single-part source is preserved as-is, including absence of optional header attributes | Produce a typeless flat file with `saveImage()`, read its exact header through the matching singular reader, rewrite it unchanged through both transports, and require the output's singular header to remain typeless and otherwise equal | Observes public header state and the explicit preservation rule; singular copy, careful attribute removal, or any equivalent output architecture passes |

Planned mutants apply only replacement index zero during publication and force
the untouched single-part rewrite through the multipart-normalized header. The
two probes cross different lifecycle boundaries: multi-entry replacement
application versus source-producer header fidelity. `meta.md` already says that
matching replacements are encoded and that an untouched unnamed single-part
source is preserved as-is, so no public contract change is needed.

## Revision v14 exact result

Final identity: `meta 926a2b88`, `test 0b7a91b7`, `solution d0c75ee5`,
`Dockerfile fc0ce006`, mutation script `63825bd5`.

`RewriteParts` now carries two distinct replacements through the same filename
and stream calls. Both emitted headers are compared with the public
`saveImages()` result, and both payloads are compared with their corresponding
inputs. `SinglePartLoad` reads the source and rewritten tiled files through
`TiledInputFile`, proving that the original optional `type` attribute is absent
and remains absent through both rewrite transports. Its existing decoded image
checks remain in place.

The reference classifies a flat non-multipart source before constructing the
multipart planning view. It still builds and validates the complete plan first,
then uses singular flat scanline or tiled `copyPixels()` only when the exact
source header is typeless. This preserves raw-copy behavior and does not weaken
replacement or destination validation.

The no-cache environment gate rebuilt all 285 targets offline as UID/GID 10001.
The pristine tree passes 4/4 existing tests and reaches the expected missing-API
focused failure; the reference passes 4/4 existing and 14/14 focused. Exact
run-8 replay leaves `Nova_Nova_2` at 14/14. Previously passing
`Nova_Nova_1` is now 13/14, failing only the public typeless-header invariant;
the representative near and broad implementations remain 12/14 and 5/14.

The exact mutation audit contains 74 variants. All 73 behaviorally incorrect
variants are killed, including the new first-replacement-only and normalized
legacy-header variants. The sole survivor delegates duplicate-name rejection
to OpenEXR and passes 14/14 focused plus 127/127 pre-existing tests in 324.87
seconds. Exact gap, fairness, and false-positive audits pass. Calibration starts
again at 0/10; all run-8 outcomes remain historical evidence.

## Revision v13 validation and level-mode design gate

Before changing `test.patch`, I reread the mandatory design, environment, gap,
fairness, false-positive, and calibration protocols. The local search covered
the OpenEXR entries in `problems/README.md`, `candidates/CANDIDATES.md`, and
`candidates/SUCCESSES.md`, plus this problem's `SUMMARY.md`, `DESIGN.md`,
`LEVELS.md`, `ERRORS.md`, and `RUNS.md`. Raw evidence remains available in
`agent-runs8`; I inspected the patch, evaluation, test log, and trajectory for
the legitimate pass `Nova_Nova_1`, the 12/14 near-pass `Nova_Nova_3`, and the
5/14 broad failure `Nova_Nova_5`.

All three implementations put filename equality checks before output creation.
The pass performs an additional complete validation pass before opening its
output stream, the near-pass builds a rewrite plan first, and the broad failure
also validates its multipart headers before constructing the writer. Their
windowed tiled readers all inspect `LevelMode`; the correct implementations use
the categorical `mode != ONE_LEVEL` rule, while their ordinary full-image paths
branch separately for mipmap and ripmap. These are public validation and enum
boundaries, not reference-only structure.

The v12 verifier has three weak cells. First, identical-path rewrite asserts
only that an exception occurs, so a late exception after truncation passes.
Second, the replacement planner calls `dataWindowForFile()` but accepts an
empty intersection; the reference then opens the distinct destination and
fails only while publishing it. Third, `WindowedLoad` exercises only a mipmap
part, allowing a special case that rejects `MIPMAP_LEVELS` but accepts
`RIPMAP_LEVELS` despite the stated `ONE_LEVEL` domain.

### Revision v13 trajectory-informed discriminator ledger

| Evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|---|
| Every inspected solver checks identical filename strings before constructing the destination, but the current test observes only a later exception | Open or truncate the same path, then fail during input/output processing | Identical input/output filenames are rejected before the destination is modified | Snapshot the valid source bytes, call filename rewrite with that exact path as both arguments, require rejection, and compare the bytes afterward | Observes the explicitly promised publication boundary; it does not require alias detection, canonicalization, a temporary-file strategy, or an exception type |
| The legitimate pass and near-pass validate a complete rewrite plan before opening output; the reference misses empty header/image intersections | Defer a disjoint `USE_HEADER_DATA_WINDOW` failure until the writer is already open | Every invalid replacement collection is rejected before changing either destination transport | Use a named one-level replacement whose header and image data windows are disjoint; require the existing filename sentinel and stream buffer to remain unchanged | Reuses the public invalid-window rule and existing transaction oracle rather than inventing byte identity for a successful rewrite |
| Tiled load paths branch on the three public `LevelMode` values; current coverage selects only mipmap | Reject exactly `MIPMAP_LEVELS` while allowing a ripmap crop | The `Box2i` overload accepts only `ONE_LEVEL` and rejects both multiresolution modes | Add a valid ripmap sibling and require both filename and stream windowed overloads to reject it without matching exception text | Crosses a real enum branch used independently throughout OpenEXR; it adds no new crop semantics or redundant image-family matrix |

Planned mutations remove the same-path guard, remove the new empty-intersection
precheck, and narrow the categorical multiresolution rejection to mipmap only.
The public description already states all three behaviors, so `meta.md` does not
need a contract change.

## Revision v13 exact result

Final identity: `meta 926a2b88`, `test dc6a2e9c`, `solution b2b8e45f`,
`Dockerfile fc0ce006`, mutation script `fa5d6a13`.

`RewriteValidation` now proves that an identical-path rejection leaves the
source bytes unchanged. Its existing dual-transport rejection helper also
receives a one-level replacement whose header and image data windows are
disjoint; both the filename sentinel and fresh stream remain unchanged. The
reference rewrite plan rejects that empty intersection before either output
transport is opened. `WindowedLoad` adds a valid ripmap sibling and requires
both `Box2i` overloads to reject it.

The no-cache exact environment gate rebuilt all 285 targets offline as UID/GID
10001. The pristine composition passes 4/4 existing tests and reaches the
expected missing-API focused failure; the reference passes 4/4 existing and
14/14 focused tests. Exact source-only replays preserve both legitimate run-8
implementations at 4/4 and 14/14. The representative near-pass remains 12/14,
and the broad failure remains 5/14.

The exact mutation audit now contains 72 variants. All 71 behaviorally wrong
variants are killed. In particular, removing the same-path guard and the
empty-intersection precheck fails `RewriteValidation`, while accepting only
ripmap windowed input fails `WindowedLoad`. The sole survivor delegates
duplicate-name rejection to OpenEXR; it passes 14/14 focused and 127/127
pre-existing tests in 315.24 seconds and remains behaviorally equivalent.
Gap, fairness, and false-positive audits pass for these hashes. The artifact
change resets calibration to 0/10; the run-8 2/5 outcome remains historical
difficulty evidence only.

## Revision v12 run-8 design gate

The startup search covered the OpenEXR entries in `problems/README.md`,
`candidates/CANDIDATES.md`, and the current `SUMMARY.md`, `RUNS.md`,
`LEVELS.md`, and `ERRORS.md`. Raw evidence exists in `agent-runs8`; the review
used the patch, evaluator record, test log, and complete trajectory for a
legitimate pass (`Nova_Nova_1`), the 12/14 near-pass (`Nova_Nova_3`), and the
5/14 broad failure (`Nova_Nova_5`). No substitute run was needed.

The five v11.2 runs produced two legitimate passes and three implementation
failures. The passing implementation inspected the existing singular flat and
deep helpers, then built direct multipart dispatch with shared header
synthesis, bounded readers, and `copyPixels()` for untouched rewrite parts; it
added 1,297 production lines across `ImfImageIO.cpp` and `ImfImageIO.h`. The
near-pass used the same public seams in 1,119 production lines but mishandled
an unnamed single-part source and deep-tiled crop samples. The broad failure
added 1,422 production lines, iterated invalid Cartesian mipmap levels, and
failed several deep and header boundaries. All three modified the same two
production files, kept state in public `Header`/`Image` values, and reached the
real 4/4 baseline lane; there was no environment or verifier failure.

The review finding exposes one independent branch left weak by the current
suite. `RewriteParts` compares complete headers for every untouched part, but
for the replacement it checks only the resulting family and image payload.
The public contract already says a replacement is encoded with the same header
and data-window behavior as `saveImages()`. A rewrite-only implementation can
therefore drop the replacement's display window, line order, compression
normalization, custom attributes, or other emitted header state and still pass.

### Trajectory-informed discriminator ledger

| Evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|---|
| All inspected runs split untouched raw-copy handling from replacement encoding; the current verifier fully compares only untouched headers | Reconstruct a minimal replacement header while preserving source headers correctly | Rewriting a replacement uses the same observable header and data-window behavior as `saveImages()` | Save the exact replacement through `saveImages()`, load its emitted header, and require both filename and stream rewrite results to emit the same complete header | Compares two public APIs rather than enumerating attributes or requiring the reference helper; copied, reconstructed, and direct-writer implementations all pass |

The new probe is one discriminator across the replacement-encoding boundary,
not another image-family permutation. It uses a nondefault line order and
custom attributes, while the image family supplies type, tiling, compression,
channels, and level metadata. The public description now states the existing
`saveImages()` equivalence directly in shorter maintainer-issue prose.

## Revision v12 exact result

Final identity: `meta 926a2b88`, `test fe6a6a0d`, `solution 672589e8`,
`Dockerfile fc0ce006`, mutation script `792c5603`.

`RewriteParts` saves the replacement once through the public stream
`saveImages()` overload, reloads that complete emitted header, and compares it
to the replacement header produced by both rewrite transports. The comparison
uses public `Header` state and does not hard-code an attribute whitelist or a
serialized file layout. The targeted rewrite-only header-drop mutant fails
this node.

The exact environment gate rebuilt all 285 targets offline as UID/GID 10001.
The pristine tree passes 4/4 existing tests and reaches the expected missing
API failure; the reference passes 4/4 existing and 14/14 focused tests. The
69-mutant audit kills all 68 behaviorally incorrect variants. The only
survivor delegates duplicate-name rejection to OpenEXR, passes 14/14 focused
tests, and passes all 127 pre-existing tests in 316.57 seconds.

The two legitimate run-8 passes were replayed against the final exact verifier.
Both retain 4/4 existing and 14/14 focused results, including the new header
oracle. The original v11.2 batch therefore remains useful 2/5 historical
difficulty evidence, but the v12 artifact change resets calibration to 0/10.

## Revision v11.2 description cleanup

This prompt-only revision responds to the description review without changing
the verifier or reference behavior. It combines unsupported-part skipping and
file order in one sentence, removes the conventional caller-stream ownership
note, replaces "structural rewrite" with plain language, and limits the unnamed
source statement to the behavior the suite observes: an untouched unnamed
single-part source is accepted and preserved. The narrower wording removes an
untested replacement-selection claim rather than adding a hidden requirement.
All exact-version gates restart for the new `meta.md` hash at calibration 0/10.

Final v11.2 artifact identity: `meta 25844f5b`, `test f6c7154c`,
`solution 672589e8`, `Dockerfile fc0ce006`. The clean no-cache environment
gate passes with pristine 4/4 and the expected missing-API feature failure;
the reference passes 4/4 existing and 14/14 focused tests. The exact
68-mutant audit kills all 67 behaviorally incorrect variants. The sole
survivor delegates duplicate rejection to OpenEXR and remains equivalent,
passing the complete 127/127 pre-existing suite in 319.84 seconds.

## Revision v11.1 description cleanup

This revision changes only `meta.md`; it does not alter the API contract,
hidden tests, reference implementation, harness, repository pin, or selected
discriminators. The opening now states the task directly, `saveImages()` is
described as taking a nonempty `ImageParts` collection, the public
`saveImage()` behavior is referenced without restating its visible mechanics,
and stream ownership is stated once for all APIs. No requirement was added,
removed, or weakened. The artifact change nevertheless invalidates the v11
exact-version records, so environment, gap, fairness, and false-positive gates
restart for the v11.1 prompt hash at calibration 0/10.

Final v11.1 artifact identity: `meta 0009304e`, `test f6c7154c`,
`solution 672589e8`, `Dockerfile fc0ce006`. The clean no-cache environment
gate passes with pristine 4/4 and reference 4/4 plus 14/14 focused tests. The
exact 68-mutant audit again kills all 67 behaviorally incorrect variants; the
only survivor delegates duplicate rejection to OpenEXR and remains equivalent,
passing the complete 127/127 pre-existing suite in 314.43 seconds.

Final v11 artifact identity: `meta 49d2c9af`, `test f6c7154c`,
`solution 672589e8`, `Dockerfile fc0ce006`.

## Revision v11 final discriminator result

The completed gap pass extended the first draft across every independently
implemented storage family. `WindowedLoad` now proves bounded behavior for flat
scanline, deep scanline, flat tiled, and deep tiled selected parts through both
filename and stream overloads. It also exercises offset coordinates, a sampled
flat channel, exact header copying, partial intersection, disjoint and
multiresolution rejection, exact-case lookup, UTF-8 filename lookup, and an
unsupported sibling. Damage fixtures self-check that a complete load fails
before accepting the bounded-load result.

The final environment gate rebuilt the clean repository in a no-cache image and
passed offline as UID/GID 10001. The pristine composition passes 4/4 existing
tests and fails the announced missing overload; the reference passes 4/4
existing and 14/14 focused identities. The final test and production sources
also pass `clang-format --dry-run --Werror`, shell syntax, patch applicability,
and whitespace checks.

All five run-7 implementations were replayed from clean pinned clones with
participant-owned source changes followed by the final verifier. Every runner
passes 4/4 existing tests and fails the 14-case feature lane at the missing
three-argument overload. The historical result is therefore 0/5, compared with
four passes and one near-pass before v11. This is not fresh calibration and the
revision remains at 0/10.

The exact false-positive audit runs 68 production mutants. Sixty-seven
behaviorally incorrect variants are killed. The single survivor delegates
duplicate-name rejection to OpenEXR and is behaviorally equivalent. All eight
v11-specific mutants are killed: ignored filename/stream windows, eager reads
for each of the four part families, accepted multiresolution input, and a stale
returned header window. No private read-count, chunk-layout, timing, or memory
oracle was added. The restored reference passes 127/127 pre-existing tests in
322.37 seconds, and the equivalent survivor passes the same 127/127 lane in
319.48 seconds after passing 14/14 focused tests.

One historical replay setup was quarantined before execution when the archived
run-4 patch attempted to delete generated bootstrap files absent from the clean
pin. The clean source-only replay batch restarted from zero. A later mechanical
format pass changed the submission hashes, invalidated every provisional v11
verdict, and caused the environment, replay, mutation, and full-suite checks to
restart for the final hashes above.

## Revision v11 windowed selective-load design gate

Before revising a submission artifact, I reread `PROBLEM_DESIGN.md` and the
environment, gap, fairness, false-positive, and calibration protocols. I
searched the OpenEXR problem and candidate indexes again, reviewed the current
problem records, and inspected the raw run-7 trajectories, patches, evaluations,
JUnit, and logs. `Nova_Nova_2` through `Nova_Nova_5` remain representative
legitimate passes at 4/4 baseline and 13/13 focused cases. `Nova_Nova_1` remains
the only near-pass at 4/4 and 8/13, with one deep-tiled sample-count defect.
There is no broad failure in the batch.

The four passing production implementations use independent direct dispatches,
but converge on the same selected-part data flow: after an exact header-name
scan, scanline parts read the complete header data-window y range, while tiled
parts read every tile at every level. Deep paths similarly read all sample
counts and then all samples. Their raw production additions remain 768--995
lines in `ImfImageIO.cpp` and 60--74 lines in `ImfImageIO.h`; raw trajectories
do not expose trustworthy platform agent-message or strict effective-LOC
metrics, so those are not inferred.

The pinned repository exposes a harder adjacent public seam. `InputPart` and
`DeepScanLineInputPart` accept bounded scanline ranges, and `TiledInputPart` and
`DeepTiledInputPart` expose tile coordinates, per-tile data windows, bounded
sample-count reads, and bounded tile reads. A high-level windowed named load can
therefore avoid unrelated damaged chunks using public APIs. It still permits
staging, the C++ part classes, OpenEXRCore, or another behaviorally equivalent
implementation; the contract concerns only the returned header/image and
whether wholly unrequested storage is decoded.

### Revision v11 discriminator ledger

| Evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|---|
| All run-7 implementations decode the complete selected part because the existing overload requests the complete part. Public scanline and tile readers accept bounded ranges. | Implement a windowed overload as `loadImagePart()` followed by an in-memory crop. | For a named `ONE_LEVEL` part, the windowed overload returns the intersection with the source data window and does not require chunks or tiles wholly outside that intersection to be readable. | Corrupt a self-checked scanline chunk below a top crop and a self-checked deep tile outside a disjoint crop; require filename and stream windowed loads to return exact flat/deep samples and the adjusted copied header. | Intra-part fault isolation and bounded producer reads, separate from sibling isolation, exact-name matching, and save-time cropping. | The test observes success and returned state, not read counts, timing, memory, helper names, staging layout, or use of a particular low-level API. |
| All four image families have independent read paths, and deep data requires a sample-count phase before pointer allocation. | Implement the bounded path only for flat scanlines, or bound deep samples without bounding sample counts. | Windowed loading supports flat/deep scanline/tiled `ONE_LEVEL` parts through filename and caller-owned stream overloads. | Use state-distinct flat scanline, flat tiled, deep scanline, and deep tiled parts with interior x/y crops; compare channels, deep counts, and sample values to explicitly cropped expected images. | Four storage families plus the deep two-phase resource boundary. | One heterogeneous fixture crosses genuinely separate OpenEXR classes; it does not repeat filenames or demand a private dispatch structure. |
| `Image::resize()` derives multiresolution level geometry from the level-zero window, so cropping a multiresolution part has ambiguous lower-level semantics without a new policy. | Quietly collapse or regenerate mip/ripmap levels. | The new overload is defined only for `ONE_LEVEL`; it rejects a selected mipmap or ripmap part and a request disjoint from the source data window. | Exercise both rejection predicates without matching exception text or commit timing. | API-domain validation, not pixel decoding. | The restriction avoids inventing hidden coordinate rules and leaves existing complete multiresolution loading unchanged. |

A multi-name batch loader was rejected because every observed implementation
already has the header scan and indexed decoder needed to implement it as a
small loop. Same-path rewrite was rejected because atomic filesystem replacement
would add platform-specific commit semantics rather than a new image-data
boundary. Preserving arbitrary unknown-type chunks was rejected because the
typed public C++ copy APIs require a known part family and a raw-chunk contract
would expose private format choices. Windowed loading is selected because it is
repository-supported, externally observable, independently branched, and
cannot be reduced to the four passing eager architectures when the unrequested
storage is unreadable.

This gate is recorded before changing `meta.md`, `solution.patch`, or
`test.patch`. Revision v11 starts at calibration 0/10; the v10 environment and
historical replay results become evidence only when any artifact changes.

### Revision v11 preliminary exact-version gap review

The first v11 draft killed all five run-7 production patches because none
declared the windowed overloads. Before accepting that result, I mapped the new
contract across storage family, transport, filename encoding, name selection,
unsupported siblings, coordinate origin, and chunk-fault boundaries. That
review found four actionable holes in the draft rather than treating the old
compile failures as sufficient evidence:

- fault isolation covered flat scanline and deep tiled data, but deep scanline
  sample-count/pixel reads and flat tiled reads are separate producer paths;
- the new filename overload had not been exercised with a UTF-8 path, and its
  name lookup had no direct case-sensitive rejection;
- disjoint-window and unsupported-selected-part behavior had only partial
  transport coverage; and
- every positive fixture began at `(0, 0)` and used only unit-sampled flat
  channels, leaving offset arithmetic and sampled-channel copying unchecked.

A final public-model review found one related fairness edge after the first
exact pass: not every geometric intersection can be represented by `Image`
when a channel is subsampled. The prompt now explicitly requires rejection when
the result origin or extent conflicts with channel sampling, and `WindowedLoad`
checks that predicate through both overloads. This records behavior already
enforced by the repository image model instead of leaving it as a hidden
reference exception.

These are public behavior cells backed by independent OpenEXR classes or by
transport/name boundaries that have produced earlier solver asymmetries. The
next test revision will add one deep-scanline damaged-chunk probe, one flat-tile
damaged-chunk probe, exercise the windowed filename path on the existing UTF-8
fixture, extend the existing unsupported/case/disjoint checks to the new
overloads, and use an offset source window with a sampled flat channel. No new
requirement, private read-count oracle, byte layout, or exception message is
introduced. Because this changes `test.patch`, the provisional v11 environment,
full-suite, and historical-replay results are not the final exact-version
verdicts and will be repeated.

## Revision v10 run-7 trajectory-informed design gate

Before changing a submission artifact, I reread `PROBLEM_DESIGN.md`,
`ENVIRONMENT_GATE.md`, `GAP_ANALYSIS.md`, `FAIRNESS_ANALYSIS.md`,
`CALIBRATION_STRATEGY.md`, and the worked false-positive record. I searched the
problem and candidate indexes and reviewed this problem's design, summary,
levels, errors, runs, verification, gap, fairness, and upstream records. I then
inspected every run-7 evaluation, solution patch, log, JUnit report, and raw
trajectory. This gate is recorded before revising `test.patch`.

Run 7 is an incomplete five-run sample for immutable revision v9.1. Four
solutions pass 4/4 baseline and 13/13 focused cases. `Nova_Nova_1` is a
legitimate near-pass: it passes the baseline and 8/13 focused cases, with all
five failures caused by one missing deep-tiled sample-count edit path. There is
no broad behavioral failure. The solutions add 768--995 lines to
`ImfImageIO.cpp` and 60--74 lines to `ImfImageIO.h`; three also add 120--193
lines to `testIO.cpp`. Their raw trajectories retain the tool transcript inside
an agent envelope, so platform agent-message counts are unavailable and are
not inferred from tool calls or token totals.

All five implementations use direct four-family decoding and return a copy of
the selected source header. Their rewrite paths preserve untouched headers by
copying the corresponding source `Header`, while their matching logic varies:
some explicitly guard `hasName()`, and at least the near-pass and one pass add
participant tests for an empty structural rewrite of a legacy unnamed
single-part file. This convergence confirms that full header retention and the
unnamed-source path are repository-natural, but it does not excuse the current
verifier from observing them. The current reference alone rejects every
supported unnamed source header in `prepareRewrite()`.

### Revision v10 discriminator ledger

| Trajectory or repository evidence | Plausible shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Decision |
|---|---|---|---|---|---|
| Named loading has its own header-scan and decode entry point. Every run-7 solver copies the source header, but the verifier currently checks only name and pixels. | Reconstruct a minimal header around the decoded image and discard custom or less commonly used source attributes. | `loadImagePart()` returns the same complete header as the corresponding part from `loadImages()`. | Give the selected part nondefault windows, line order, compression, screen state, and custom attributes; compare the filename and stream results with the complete-load header state. | Selective decode metadata fidelity, independent of exact-name matching and pixel isolation. | Add one state-rich fixture and compare both transports. |
| Untouched rewrite parts are prepared separately from replacements. All run-7 solvers copy source headers, but the existing oracle checks only names and one compression field. | Preserve the fields needed to construct an output part while dropping custom attributes or unrelated public header state. | Every untouched supported part retains its source header. | Add distinct custom and nondefault state to untouched flat and deep parts, then compare the rewritten filename and stream headers with the decoded source headers. | Structural-copy metadata fidelity, independent of pixel-copy fidelity and replacement encoding. | Extend the existing heterogeneous rewrite, without adding another rewrite fixture family. |
| Existing `saveImage(filename, image)` produces a valid supported single-part file without a name. Run-7 implementations can structurally rewrite that shape, while the reference rejects it before publication. | Apply replacement-name validation to source parts even when there is no replacement to match. | Rewriting accepts single-part and multipart input; an unnamed supported source part is preserved by an empty structural rewrite. | Produce the source through the existing high-level single-image helper, self-check that its header has no name, and structurally rewrite it through filename and stream overloads. | Source producer/cardinality and absent optional metadata, distinct from invalid replacement names. | Clarify the observable source rule, add both transport probes, and remove the reference rejection. |

Header comparison will use public header fields and typed custom attributes
present in the fixture. It will not require attribute serialization order,
private chunk tables, byte-identical files, a particular `copyPixels()` call,
or exception text. Unnamed replacement headers remain invalid; only a source
part that is not being named as a replacement target is covered. Any v10
artifact edit makes the v9.1 exact-version verdict historical, abandons the
incomplete 4/5 run-7 sample, and restarts calibration at 0/10.

### Revision v10 environment and historical replay result

The first exact environment attempt was quarantined when the reference fixture
gave different multipart parts conflicting shared `pixelAspectRatio` values.
That was an invalid verifier fixture, not a solution failure. The fixture was
corrected to use legal per-part custom attributes and line-order state, and the
complete gate restarted with a new no-cache image. The corrected gate passes:
the pristine baseline is 4/4, the pristine feature lane reaches the expected
missing-API failure, the reference is 4/4 and 13/13 offline as UID/GID 10001,
testcase identities match, and four run-7 plus five run-6 representative
patches inject without verifier-owned path overlap.

After that gate passed, all five run-7 production patches were replayed against
the revised verifier in clean exact-pin trees. Every replay passes the 4/4
baseline. `Nova_Nova_1` still passes 8/13 focused cases; its failures are the
same five deep-half-sample failures caused by its missing deep-tiled
sample-count edit path. `Nova_Nova_2` through `Nova_Nova_5` each pass 13/13.
The new header-fidelity and unnamed-source probes therefore close real coverage
and reference gaps, but they do not discriminate the four previously passing
architectures. This is historical replay evidence, not a fresh solver batch,
and it does not support a claim that v10 is barely solvable.

## Revision v9.1 save-stream fairness correction gate

Before revising the hidden patch, I reread `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the environment, gap, fairness, and false-positive
protocols, and the worked false-positive record. I searched the problem and
candidate indexes and reviewed this problem's current design, run, level,
error, summary, gap, fairness, and verification records. I also reopened the
raw evaluation, trajectory, run report, and solution patch for representative
run-6 passes 1, 3, and 5. All five run-6 cases are legitimate passes; there is
still no near-pass or broad failure to substitute for those unavailable
evidence categories.

The external fairness review found one unsupported predicate in
`ApiAndValidation`: after each invalid `saveImages(OStream&)` call throws, the
test also requires the destination to contain zero bytes. The prompt requires
the collection to be rejected and applies every validation family to both save
overloads, but it reserves validation-before-output semantics for
`rewriteImages()`. The pinned repository has no neighboring OpenEXRUtil stream
save API that strengthens rejection into transactionality. All five historical
implementations happen to validate before opening the multipart writer, but
that convergence is implementation evidence, not public-contract provenance.

### Revision v9.1 discriminator decision

| Observed evidence | Candidate predicate | Fair public invariant | Decision | Anti-overfit rationale |
|---|---|---|---|---|
| All five v8 solvers share validation across filename and stream saves, while the public task promises only rejection for invalid save collections. | Require an invalid stream save to leave `MemoryOutputStream` exactly empty. | Every stated invalid collection is rejected through both save overloads. | Remove the empty-buffer assertion and retain the exception oracle for every validation family. | A conforming implementation may discover an invalid later part after emitting bytes. Requiring rollback or preflight validation would prescribe unstated commit timing and does not isolate a trajectory-supported behavioral shortcut. |

No replacement discriminator is added. The existing filename and stream calls
still directly cover empty, null, missing-name, empty-name, duplicate,
unsupported-image, and multiresolution-crop rejection. Rewrite destination
preservation remains because it is explicit in the public contract. The v9
exact-version environment, gap, fairness, and mutation verdicts become
historical as soon as `test.patch` changes, and v9.1 remains at calibration
0/10.

### Revision v9.1 exact-version result

The final patch removes only the invalid-save stream byte-count assertion. The
exception oracle remains for all seven save validation families through both
overloads, and the explicit filename/stream rewrite preservation checks remain
unchanged. `meta.md`, `solution.patch`, `Dockerfile`, the collision-safe test
path, and the 13 testcase identities are byte-identical to v9.

The first v9.1 environment attempt was quarantined before test execution
because the hand-edited unified-diff hunk count was stale. After correcting the
patch syntax, the gate restarted from a new no-cache image and passed offline
as UID/GID 10001: 285/285 image targets built, pristine existing tests passed
4/4, pristine feature tests reached the expected missing-API failure, the
reference passed 4/4 and 13/13, JUnit identities matched, and all five run-6
compatibility patches injected cleanly.

The exact 60-mutant audit again kills all 59 behaviorally incorrect variants.
All seven stream-only invalid-save variants are still killed by failure to
throw, proving the removed byte oracle contributed no required discriminator.
The duplicate-validation delegation remains the sole equivalent survivor and
passes the 127-case pre-existing suite in 318.06 seconds. Gap, fairness, and
false-positive analysis pass for hashes `meta 6e7fb620`, `test 0fdcba49`,
`solution e7f17fa7`, and `Dockerfile fc0ce006`. Calibration remains 0/10.

## Revision v9 selective-rewrite design gate

Before changing any submission artifact, I reread `PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`, searched the problem and candidate indexes, reviewed the current OpenEXR design, run, level, error, upstream, gap, fairness, and verification records, and inspected every artifact in all five `agent-runs6` packages. All five are legitimate v8 passes at 4/4 baseline and 10/10 feature tests. The batch contains no near-pass and no broad failure, so those evidence roles are unavailable.

The five ATIF trajectories contain four top-level envelopes and retain the complete tool transcript in the final envelope. They contain 104, 84, 117, 80, and 69 unique tool-call identifiers. Platform agent-message counts and strict effective production LOC are not available and are not inferred from those counts. Raw production additions across `ImfImageIO.h` and `ImfImageIO.cpp` are 666, 655, 813, 725, and 667 lines; four solvers also edited `testIO.cpp`. Their total non-build raw additions are 823, 783, 959, 725, and 838 lines.

Every implementation follows the same decoded collection architecture: prepare all output headers, dispatch the four image families through frame buffers, eagerly decode supported input parts, and perform named reads by part index. None uses a production `copyPixels()` path. All five already skip unsupported multipart parts, and all five prepare and validate the collection through a helper shared by the filename and `OStream` save overloads. The reported unsupported-load defect is therefore a reference mismatch with the public wording, while the reported stream-validation defect is a genuine oracle gap that the observed implementations happen to satisfy.

The repository offers a harder adjacent boundary. `OutputPart`, `TiledOutputPart`, `DeepScanLineOutputPart`, and `DeepTiledOutputPart` each expose `copyPixels()` specifically to preserve compressed pixel data without a decode/re-encode generation. The `exrmultipart` tool already demonstrates pure structural combination, so adding a plain copy wrapper would be predictable prior art rather than meaningful escalation. No repository utility or local history provides a high-level operation that mixes replacement `Image` encoding with structural preservation of untouched parts in one output.

Revision v9 will add `rewriteImages()` overloads for two UTF-8 filenames and for caller-owned `IStream`/`OStream` objects. A replacement list is matched by exact header name. The output contains every supported source part in original file order, skips unsupported source siblings, encodes matching replacements with the existing per-part save rules, and structurally preserves unmatched supported parts so a lossy input does not acquire another compression generation. An empty replacement list is a valid structural rewrite. Invalid, duplicate, unnamed, null, unsupported, or unmatched replacements are rejected before the output stream is changed. Filename input and output are distinct paths; stream objects remain caller-owned.

### Revision v9 discriminator ledger

| Observed behavior or evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|---|
| Thirty legitimate solutions converge on fully decoded load/save dispatch; none mixes raw preservation with new high-level image encoding. The repository exposes four `copyPixels()` families, while its command-line tool covers only pure copy/combine. | Implement rewriting as `loadImages()`, replace vector entries, then `saveImages()`, silently applying a second lossy compression generation to every untouched part. | A selective rewrite encodes replacements but preserves the public header and decoded sample state of untouched supported parts exactly, including lossy-compressed input. | Rewrite a heterogeneous source with one family-changing named replacement, then compare order and replacement state while requiring an untouched lossy part's decoded samples and compression metadata to equal the source exactly. Exercise both filename and stream transports. | Hybrid publication: raw preservation and high-level encoding coexist in one multipart writer. | The oracle observes headers and decoded samples, not helper names, chunk offsets, serialized file identity, or a mandated API call. Direct `copyPixels()`, safe compressed staging, or any behaviorally equivalent design passes. |
| All five current solvers interpret “every supported image part” by skipping unsupported siblings, but the reference calls the decoder unconditionally and aborts. | Treat the first unknown multipart type as fatal even when valid supported siblings remain. | `loadImages()` returns supported parts in their original relative order and ignores unsupported siblings; selecting an unsupported named part is rejected. | Place an unsupported typed part between distinguishable supported parts and exercise filename and stream load-all plus supported and unsupported named reads. | Header classification before decoder construction, independently of pixel corruption and exact-name matching. | The fixture changes only the public type value and accepts every classification/dispatch structure. It requires no handling of the unknown payload and no exception wording. |
| The verifier calls `OStream` save only for an empty collection even though all observed solvers share validation across transports. | Put complete validation only in the filename wrapper and silently accept invalid collections through the stream overload. | Every stated collection and `DataWindowSource` rejection applies identically to filename and `OStream` save overloads. | Replay null image, absent name, empty name, duplicate name, unsupported image, and later multiresolution crop cases through a fresh memory output stream and require an exception. | Transport symmetry, separate from each validation predicate. | Uses the same public invalid values as the filename lane and leaves exception type, message, predicate order, commit timing, and post-failure stream bytes unconstrained. |

The pure-copy-only proposal was rejected because `exrmultipart.cpp` already publishes that exact four-way architecture. Byte-identical whole files, compressed chunk offsets, thread scheduling, peak memory, progress callbacks, same-path atomic replacement, malformed UTF-8, and recovery from a corrupted selected part remain excluded. This gate and ledger are recorded before revising `meta.md`, `solution.patch`, or `test.patch`; every prior exact-version verdict is now historical and v9 begins at 0/10.

### Revision v9 exact-version result

The final API adds filename and caller-owned stream overloads for selective rewrite. `UnsupportedParts` now crosses load-all, named load, and rewrite through both transports. `RewriteParts` mixes a family-changing replacement with untouched flat/deep scanline/tiled parts, proves positive deep `USE_HEADER_DATA_WINDOW` cropping through both overloads, accepts an empty replacement collection, and uses a genuinely unreadable untouched payload to distinguish structural preservation from decode-and-resave. `RewriteValidation` applies every invalid replacement family to both overloads, preserves an existing filename destination and an empty memory destination, and distinguishes exact `target` matching from case-folded `TARGET`. `Utf8Filename` now crosses both UTF-8 rewrite filenames as well as the older filename operations.

The first exact gate attempt was quarantined before behavioral replay because platform solution patches contained generated `build-bootstrap` diffs absent from the clean pin. Five source-only compatibility patches were derived from the same participant-owned changes and hash-pinned in `verify/replays-v9/`; they inject cleanly without overlapping verifier-owned paths. They remain historical v8 solutions, not v9 passes.

The final clean no-cache environment gate passes offline as UID/GID 10001. The pristine lane passes 4/4 existing tests and fails the 13-case feature lane at the missing API as intended. The reference passes 4/4 existing and 13/13 feature tests, with identical pristine/reference testcase identities, and all five filtered run-6 patches inject cleanly. Controlled configuration and base-build failures return nonzero, never reach CTest, and still produce parseable requested JUnit.

The exact reference passes the complete 127-case pre-existing suite in 369.57 seconds. The equivalent duplicate-validation survivor passes 13/13 focused and 127/127 pre-existing tests in 315.38 seconds, confirming that its delegated rejection is not an actionable survivor.

The exact mutation audit attempts 60 production variants. Fifty-nine behaviorally incorrect variants are killed, including seven stream-only save-validation omissions, strict unknown-type handling in each stream operation, case-folded replacement matching, ignored replacements, reversed rewrite order, decoded/resaved untouched parts, per-overload crop omissions, and ASCII-only rewrite filenames. The only survivor removes an explicit duplicate-name precheck and delegates the same rejection to `MultiPartOutputFile`, so it is behaviorally equivalent. There are zero actionable survivors.

Gap and fairness analysis pass for hashes `meta 6e7fb620`, `test c2b6d1e0`, `solution e7f17fa7`, and `Dockerfile fc0ce006`. Revision v9 crosses a new repository-native hybrid architecture that none of the thirty historical solutions implemented, but there is no fresh v9 solver result. The honest difficulty status is therefore a real escalation at 0/10, not a proven 8/10 or “barely solvable” claim.

## Revision v8 UTF-8 filename and pre-test-reporting gate

Before changing the hidden test patch, I reread `PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`, searched the OpenEXR problem and candidate history, reviewed this problem's design, run, level, error, gap, fairness, and verification records, and inspected every file in all five `agent-runs5` packages. All five are legitimate v7 passes at 4/4 baseline and 9/9 feature tests. The batch has no near-pass and no broad failure, so those evidence roles are unavailable.

The ATIF archives retain four top-level envelopes and place the complete tool-call transcript inside the final agent envelope. The five transcripts contain 63, 111, 61, 119, and 85 tool calls. Platform agent-message counts and strict effective production LOC are not present and are not inferred from those tool counts. Raw additions across `ImfImageIO.h` and `ImfImageIO.cpp` are 665, 538, 668, 563, and 695 lines. Every solver also adds repository tests, for three changed files total.

All five solutions use the same repository-native filename seam: the three filename overloads pass `fileName.c_str()` to the existing multipart constructors. None of their participant tests uses a non-ASCII path even though the prompt explicitly calls the filename UTF-8. The pinned repository has an established UTF-8 filename fixture in `testExistingStreamsUTF8`, using `画像.exr`, so this is a concrete missing public boundary rather than an invented encoding rule.

The review also found that v7's fail-fast harness repair creates a reporting hole. A configuration or base-target build error exits before CTest can create the requested XML. The harness must preserve the nonzero status and create one well-formed failing JUnit testcase only when no native report exists. Native CTest JUnit remains authoritative whenever it was written.

### Revision v8 discriminator ledger

| Observed behavior or evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|---|
| All five current passes forward filename bytes to repository constructors, but none tests the prompt's explicit UTF-8 qualifier. The repository independently tests non-ASCII filenames. | Treat filename strings as ASCII-only, reject high-bit bytes, or lose them in one of the save, load-all, or load-one wrappers. | Every filename overload accepts a valid UTF-8 path with non-ASCII code points. | Save two distinguishable parts to a filename containing Japanese, Latin, and Cyrillic UTF-8 bytes; load the collection and one named part from the same path and compare public state. | Filename encoding across write, plural read, and selective read, separate from stream transport and header-name equality. | The fixture follows a pinned repository precedent and observes only successful public I/O. It prescribes no transcoding library, filesystem wrapper, locale, path class, or internal representation. |

Pre-test JUnit fallback is evaluator-integrity work rather than a participant discriminator, so it has no behavioral ledger row. Separate harness probes will force configuration and base-build failure, require nonzero exit, parse the requested XML, and verify that CTest was not reached. This gate is recorded before revising `test.patch`. Any v8 artifact change invalidates all v7 environment, gap, fairness, and mutation verdicts and restarts calibration at 0/10.

### Revision v8 exact-version result

`Utf8Filename` now saves a flat one-level part and a deep mipmapped part to a path containing Japanese, accented Latin, and Cyrillic UTF-8 bytes. It reopens the physical file through `MultiPartInputFile`, then verifies high-level load-all and exact selected-part loading from the same path. Three isolated production mutants reject non-ASCII input in save-all, load-all, or load-one respectively; each is killed only by this node.

The harness now captures configuration, base-build, and CTest status without losing immediate failure semantics. If CTest has not written the requested report, the harness emits one error testcase under an existing lane identity with bounded XML-escaped diagnostics and exits with the original nonzero status. Forced configuration and base-build probes both produced valid XML and did not reach CTest. Successful reference execution retained native CTest JUnit with all ten feature identities.

The final exact offline non-root gate passes for pristine, reference, and every `agent-runs5` patch. Pristine passes 4/4 existing tests and reaches the expected missing-API feature build failure with native JUnit. The reference and all five legitimate direct multipart implementations pass 4/4 existing and 10/10 feature tests. The untouched full suite passes 127/127 in 315.27 seconds.

The v8 mutation audit attempted 39 production variants. All 38 behaviorally incorrect variants are killed; the sole survivor delegates duplicate-name rejection to OpenEXR and is behaviorally equivalent. Gap and fairness analysis pass for hashes `meta 8dd28d3b`, `test dcbd0b22`, `solution 8bc37f01`, and `Dockerfile fc0ce006`.

This hardening closes two genuine omissions but does not make an honest barely-solvable claim possible: all five v7 solvers also pass v8. The submission is frozen at calibration 0/10. A later difficulty redesign needs a new public, repository-native architectural boundary supported by fresh trajectory evidence, not more permutations of already solved behavior.

## Revision v7 selective-isolation and harness gate

Before revising the hidden test patch, I reread `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md`, searched the problem and candidate indexes, reviewed
this problem's current design, level, error, run, and summary records, and
inspected every file in the five new `agent-runs4` packages. All five are
legitimate v6 passes at baseline 4/4 and feature 9/9. There is no near-pass or
broad failure in the batch, so those evidence roles are unavailable.

The archived trajectories contain the system message, environment context,
public prompt, and final response as four envelopes, plus aggregate token
metrics; they do not retain the solver's intermediate messages or tool calls.
Those unavailable fields are not inferred from token counts or evaluator
summaries. The solution patches and logs do expose the implementation choices.
All five modify `ImfImageIO.h`, `ImfImageIO.cpp`, and the existing
`testIO.cpp`. Raw production additions across the two library files are 675,
711, 789, 701, and 617 lines. Each solution uses direct multipart part-class
dispatch, exact `std::string` equality for names, and a selected-part decoder
rather than load-all-then-filter.

The reviewer also identified two exact-version defects. The prompt describes
an implementation sequence (inspect headers, then decode) where only isolation
is public, and the test harness continues after failed CMake configuration or
base compilation. The sequence wording will be removed. The harness will fail
immediately on either setup failure so a later CTest status cannot mask it.

### Revision v7 discriminator ledger

| Observed behavior or evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|---|
| The prompt says exact name, but all existing fixtures use names with no case-only neighbor and every current solution happens to use `std::string::operator==`. | Case-fold names or accept a case-insensitive fallback without being detected. | Header names are exact, case-sensitive identifiers. | Store distinguishable valid parts whose names differ only by case, load each spelling, and reject a third case variant. | Identifier equality rather than cardinality or missing-name handling. | Ordinary public string values are used; no locale, Unicode normalization, lookup structure, or exception type is prescribed. |

Harness fail-fast behavior is an evaluator-integrity repair rather than a
participant discriminator, so it has no ledger row. This gate is recorded
before changing `test.patch`. Any v7 artifact edit invalidates all v6 gate
verdicts and restarts calibration at 0/10.

An additional recovery-boundary hypothesis was prototyped after the gate. Two
solutions disable chunk-offset reconstruction for named loads and two use the
default constructor, suggesting a possible split when an unreadable trailing
part also has an incomplete offset table. Both reconstruction-enabled reference
mutants still passed the prototype. The flag choice is therefore not an
observable defect for this contract, and the trailing permutation and reference
change were rejected rather than turned into an implementation-specific test.

### Revision v7 exact-version result

The final description states observable exact-name and unreadable-sibling behavior without prescribing header inspection or decode order. `SelectiveLoad` now distinguishes valid `Hero` and `hero` parts and rejects absent `HERO`; the isolated case-folded selector mutant fails that node. The harness uses `set -euo pipefail`, and controlled configuration and base-build failures both terminate before CTest.

The exact offline non-root gate passes for pristine, reference, and solver composition. The pristine repository passes 4/4 existing tests and produces the expected missing-API feature build failure. The reference and two independent `agent-runs4` patches each pass 4/4 existing and 9/9 feature tests; two further current patches inject cleanly. The untouched full suite passes 127/127 in 319.91 seconds.

The final mutation audit attempted 36 production variants. All 35 incorrect variants are killed by their intended scenarios. One explicit duplicate-name precheck removal survives because OpenEXR delegates the same rejection, making it behaviorally equivalent. Gap and fairness analysis pass for hashes `meta 8dd28d3b`, `test 679c28f4`, `solution 8bc37f01`, and `Dockerfile fc0ce006`.

All five `agent-runs4` outcomes remain legitimate historical passes. Revision v7 fixes contract and harness quality but does not supply evidence for a barely-solvable rate. Calibration restarts at 0/10, and difficulty must not be inferred from review or mutation scores.

## Revision v6 transport and selective-decode gate

Before revising any participant artifact or hidden test, I reread
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`, searched this problem's
complete local history, and inspected the five new `agent-runs3` packages.
Every compact evaluation, solution patch, JUnit report, and test log was read.
The raw trajectories for the shortest production patch (`Nova_Nova_4`) and an
independent no-test-source patch (`Nova_Nova_3`) were inspected step by step,
including their repository searches, implementation edits, local smoke
programs, and verification commands.

All five runs are legitimate passes at baseline 4/4 and focused 7/7. Their raw
production additions across `ImfImageIO.h` and `ImfImageIO.cpp` are 622, 590,
629, 509, and 560 lines. Each implementation opens a filename directly,
constructs a `MultiPartInputFile`, and eagerly walks every part. None exposes
caller-owned `IStream`/`OStream` transport or a one-part read path. There is no
near-pass and no broad failure in this batch, so those evidence roles remain
unavailable rather than being replaced with older or unrelated runs.

The five successful implementations show that another channel type, level
fixture, validation value, or flat/deep permutation would add test volume
without changing the solution architecture. Revision v6 instead extends the
same high-level operation across two repository-native boundaries. The pinned
`MultiPartInputFile` and `MultiPartOutputFile` constructors accept existing
`IStream` and `OStream` objects, and `testExistingStreams.cpp` demonstrates
multipart operation over caller-owned and memory-backed streams. The part
input classes decode by part number, so a named part can be loaded after
header inspection without reading sibling pixel chunks.

The public API will add stream overloads for `saveImages()` and `loadImages()`,
plus filename and stream overloads of `loadImagePart()` for one named part.
Streams follow the existing OpenEXR `IStream`/`OStream` contract and remain
caller-owned. A named read returns the same independently owned header and
image state as the corresponding element of `loadImages()`, rejects a missing
name, and does not decode unselected pixel payloads. The last clause is
observable on a file whose selected part is valid while an unselected sibling
has a damaged compressed chunk; it rules out the tempting load-all-then-filter
shortcut without prescribing helper structure, buffering, or temporary files.

### Revision v6 discriminator ledger

| Observed behavior or evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|---|
| All five current passes bind both public operations directly to a filename, while the pinned multipart classes and existing tests support caller-owned streams. | Implement only filesystem paths or stage through an inaccessible filename assumption. | Multipart save and load provide equivalent high-level behavior for conforming `OStream` and `IStream` objects without taking ownership. | Round-trip heterogeneous flat/deep parts entirely through a memory-backed stream, destroy the input stream, and compare the independently owned result. | Transport abstraction and caller-owned lifetime. | Any direct stream use, memory staging, or temporary-file bridge passes; the oracle observes only bytes delivered through the public stream and returned image state. |
| Every current loader decodes all parts in a single loop before returning. | Implement named lookup by calling `loadImages()` and filtering the vector afterward. | `loadImagePart()` decodes only the requested named part and returns the same supported metadata, levels, counts, and samples as a full load. | Select a later deep multiresolution part after damaging a compressed chunk belonging to an unselected flat sibling; require the selected part to load through both filename and memory-stream overloads. | Header selection before pixel decode, across flat/deep and path/stream modes. | The file remains structurally valid and the selected public payload is valid. No read count, offset order, exception text, cache, helper, or internal part-class choice is asserted. |
| A selected loader can accidentally special-case the happy-path name or return the first part. | Treat the requested name as advisory, or silently fall back when it is absent. | Selection is by exact public header name and an absent name is rejected. | Place distinguishable parts before and after the target, select the nonzero-index name, and request one missing name. | Name resolution and negative cardinality. | Uses ordinary multipart header state and asserts only the returned public value or rejection, not lookup implementation or exception class. |

This gate is recorded before any revision to `test.patch`. Revision v6 is a
new contract, so every earlier calibration result becomes trajectory evidence
only and the revised version starts at 0/10.

### Revision v6 exact-version result

The frozen reference passes the four existing compatibility tests and all nine
feature identities offline as UID/GID 10001. The pristine repository passes
the compatibility lane and fails the feature build on the absent public API.
The untouched repository passes its complete 127-test suite. A representative
previously successful v5 solver composes cleanly but fails the v6 build on the
new stream overloads and `loadImagePart()`, confirming that the chosen boundary
distinguishes the architecture observed in all five current trajectories.

The final mutation audit attempted 35 distinct production mutants. All 34
behaviorally incorrect mutants are killed by their intended scenarios. The
single survivor removes an explicit duplicate-name precheck while continuing
to reject duplicates through `MultiPartOutputFile`, so it is equivalent
delegation rather than a false positive.

Gap review admitted stream-side validation and cropping, single-part stream
compatibility, exact selection, missing-name rejection, and selection past one
damaged unselected compressed payload. It rejected deep-corruption and
before/after permutations as repeated fixtures for the same eager-decode
failure. Fairness review also removed an early assertion that the participant's
full loader must reject the damaged file; existing low-level OpenEXR decoding
now establishes the sibling corruption independently. No oracle constrains
bytes, stream-call counts, seeks, exception wording, temporary files, helpers,
or buffering.

Hashes: `meta d8575082`, `test 83651ff9`, `solution 8bc37f01`, `Dockerfile
fc0ce006`. These local results justify freezing v6 for calibration; they do not
establish the target solve rate.

## Revision v5 API and assertion-hardening gate

Before changing the verifier, the local problem index, candidate records,
compact OpenEXR records, prior error log, and all five raw `agent-runs2`
packages were searched and inspected. Each package includes the solution patch,
trajectory, evaluator verdict, JUnit, and logs. All five are legitimate passes
at baseline 4/4 and feature 7/7. This batch contains no near-pass and no broad
behavioral failure, so those two evidence roles are unavailable rather than
replaced with older or unrelated runs.

The raw trajectories contain only the prompt and final response around harness
metadata. Platform-reported agent-message counts and strict effective
production LOC are therefore unavailable, and the four recorded harness steps
are not substituted for either measure. The patches are still useful design
evidence: all five use the natural `ImfImageIO.h` and `ImfImageIO.cpp` public
seam, add 472, 485, 603, 539, and 567 raw production lines respectively, and
dispatch flat/deep and scanline/tiled data directly. Every patch explicitly
deletes copy construction and copy assignment and explicitly defaults move
construction and move assignment for `ImagePart`.

The existing build oracle checked only construction traits. That allowed a
record with deleted move assignment to satisfy the verifier even though the
public prompt asks for a move-only value and every observed legitimate
implementation supplies the full move-only special-member contract. Revision
v5 adds standard compile-time assignment traits. It does not require a specific
declaration spelling: explicit, defaulted, and correctly implicit special
members remain acceptable.

The same review found a verifier robustness issue, not a new discriminator.
Deep comparisons checked for `A` or `Z` only by dereferencing the lookup result.
Revision v5 first asserts that each channel exists, then compares its type,
sampling, counts, and payload. This turns a missing-channel implementation into
a localized assertion failure instead of undefined behavior while preserving
the same public channel-round-trip requirement.

### Revision v5 discriminator ledger

| Observed behavior or evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|---|
| All five current legitimate passes implement both assignment traits, while the build node checked only construction. | Delete move assignment or accidentally permit copy assignment while keeping construction traits correct. | `ImagePart` is a move-only value: it is move-constructible and move-assignable, but neither copy-constructible nor copy-assignable. | Compile standard `is_move_assignable` and `is_copy_assignable` assertions beside the existing construction assertions. | Public value lifecycle: construction versus assignment. | Uses standard C++ type properties only; no helper, layout, exception, storage, or spelling is prescribed, and all observed legitimate solutions remain accepted. |

The deep lookup guards do not add a ledger row because they do not distinguish a
new semantic family. They make the existing `A` and `Z` payload oracle safe and
diagnostic. The trajectory-informed gate is complete before revising
`test.patch`.

## Revision v4 deep-cropping gate

The current problem records, candidate history, five raw `agent-runs1`
trajectories, their solution patches, and the exact repository pin were
rechecked for the reported deep `DataWindowSource` gap. Four historical v2
runs are legitimate passes, `Nova_Nova_1` is the adjudicated near-pass, and no
broad behavioral failure exists. All five implementations call
`dataWindowForFile()` for the generic `Image` before choosing a flat or deep
output part, so none exhibits the proposed deep-only shortcut and all remain
legitimate architectures.

Repository evidence nevertheless makes the missing branch distinct.
`ImfDeepImageIO.cpp` implements deep scanline and deep tiled saving separately
from the flat helpers, and both established singular paths apply
`dataWindowForFile()` before binding a `DeepFrameBuffer`. The public task says
that existing header and data-window behavior applies to every part. Revision
v3 positively observes header-window intersection only for a flat image; its
deep fixtures use the default image window, while its multiresolution case
asserts rejection rather than successful deep cropping.

### Revision v4 discriminator ledger

| Observed behavior or evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|---|
| Singular deep scanline and tiled writers independently apply `dataWindowForFile()`, but the plural suite positively crops only a flat part. | Honor `USE_HEADER_DATA_WINDOW` for flat output while always using the image window for deep output. | Existing `saveImage()` data-window behavior applies independently to flat and deep parts. | Place a valid one-level deep scanline part after flat parts, save with `USE_HEADER_DATA_WINDOW`, verify the intersected public header window, then extract and compare deep counts and samples over that crop. | Flat versus deep output preparation, plus cropped `DeepFrameBuffer` publication. | Uses a valid repository-generated image and public file state. It accepts centralized and family-specific implementations and asserts no helper layout, exception, byte encoding, or staging policy. |

This is one missing family-direction cell, not a new public requirement or a
new difficulty lever. The current prompt already specifies the behavior, so
only the hidden oracle, its isolated mutant, and the exact-version records need
revision. The design gate is complete before changing `test.patch`.

## Revision v2 packaging gate

The local history search found the same packaging failure in `problems/gimli-debug-names/SUMMARY.md`, `PLAN.md`, and `DESIGN.md`: a predictable hidden-test filename can collide with a participant's file, and the recorded correction was a suffix generated by `openssl rand -hex 3`. That lesson was missed during v1 assembly. For v2, the command produced `27b877`, so the added source is now `testMultipartImageIO_27b877.cpp`. The public description was also rewritten as naturally flowing Markdown paragraphs without manual mid-sentence wrapping.

The discriminator ledger was unchanged because neither correction changed public behavior, assertions, fixtures, or reference code. They did change the submission artifacts, so the v1 environment, gap, fairness, false-positive, and verification results became historical rather than a verdict for v2. At the user's direction, no build or test pipeline was run for that revision. Revision v3 has since rerun every gate against the current artifacts.

## Revision v3 trajectory review

The new `agent-runs1` batch contains five OpenEXR solver runs and supersedes the unrelated pre-calibration examples as the closest design evidence. The extracted `trajectory.json`, `solution-patch.patch`, `eval-result.json`, JUnit, and logs were inspected directly. Four runs are legitimate passes at baseline 4/4 and feature 7/7. `Nova_Nova_1` is a legitimate near-pass at baseline 4/4 and feature 6/7. There is no broad behavioral failure in this batch, so that evidence role is unavailable rather than being filled with an unrelated run.

| Evidence role | Raw run | Outcome | Architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | `agent-runs1/Nova_Nova_2/{trajectory.json,solution-patch.patch,eval-result.json}` | 4/4 baseline, 7/7 feature | Direct dispatch through the four multipart part classes, with 503 production additions across `ImfImageIO.h` and `ImfImageIO.cpp`. It validated null images and both missing and empty names, prepared every output header before opening the multipart writer, and copied source headers on load. |
| Near-pass / verifier mismatch | `agent-runs1/Nova_Nova_1/{trajectory.json,solution-patch.patch,eval-result.json}` | 4/4 baseline, 6/7 feature | A separate direct implementation with 592 production additions inferred the missing type of a legacy single-part file for decode dispatch, then returned an unchanged copy of the source header. Only `SinglePartLoad` failed because the hidden test called `header.type()` and demanded an undocumented synthesized attribute. |
| Additional legitimate passes | `Nova_Nova_3`, `Nova_Nova_4`, and `Nova_Nova_5` | each 4/4 baseline, 7/7 feature | Independent direct implementations added 526, 531, and 547 production lines across the same two natural files. Together with the near-pass, they support behavior-level oracles without prescribing header normalization or helper layout. |
| Broad failure | unavailable | none in five runs | No run failed multiple public behavior families, so v3 adds no discriminator justified by a broad-failure trajectory. |

The near-pass is an actual test mismatch, not a missing public invariant. Existing single-image writers may omit the part `type` attribute; the public task says returned parts own copied headers, not normalized headers. V3 therefore removes the synthesized-type assertion while retaining the observable requirements that the file loads as the correct image class, keeps its existing header attributes, and preserves all levels and samples.

The review also exposed two distinct public edges that the current suite names but does not exercise. First, “nonempty name” includes a present name attribute whose string value is empty, not only an absent attribute. Second, applying existing `saveImage()` data-window behavior independently means `USE_HEADER_DATA_WINDOW` must reject a collection if any part is multi-resolution; repository `dataWindowForFile()` throws `ArgExc` for `levelMode() != ONE_LEVEL`. The new oracle places a valid one-level part before a multiresolution part so a first-part-only validation shortcut cannot pass.

### Revision v3 discriminator ledger

| Observed behavior or evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|---|
| The near-pass inferred a legacy type for dispatch but preserved the copied header. | Normalize an absent attribute because the verifier happens to read it. | `loadImages()` must decode legacy single-part input and preserve the header attributes that exist; synthesizing absent metadata is not required. | Check returned image class, levels, samples, display window, and comments without calling absent `Header::type()`. | Producer compatibility versus header normalization. | Accepts both inferred internal dispatch and implementations that expose a type only when the source header provides one. |
| Passing implementations explicitly check both `!hasName()` and `name().empty()`, while the old oracle covered only the first branch. | Treat attribute presence as sufficient validity. | Every saved part has a nonempty name. | Supply a valid image with `header.setName("")` and require rejection. | Attribute presence versus attribute value. | Uses the exact public predicate and does not constrain exception type, text, or validation order. |
| Repository `dataWindowForFile()` rejects multiresolution images under `USE_HEADER_DATA_WINDOW`. | Validate cropping only for part zero or only for one-level fixtures. | Existing data-window behavior applies independently to every part. | Put a valid one-level part first and a mipmapped part second, call `saveImages(..., USE_HEADER_DATA_WINDOW)`, and require rejection. | Per-part mode validation and collection traversal. | Reuses stable sibling behavior and asserts only rejection, not timing, output-file cleanup, or helper structure. |

## Public contract and repository evidence

Add ordered, ownership-safe multipart operations beside the existing
`OpenEXRUtil` `saveImage()` and `loadImage()` helpers. `ImagePart` is the
move-only public record of one `Header` and one owned `Image`; `ImageParts` is
the ordered collection. `saveImages()` applies the existing per-image header,
channel, tiling, and data-window rules to every valid named part, and
`loadImages()` returns all supported image parts from single- or multipart
files in file order.

The contract covers flat and deep scanline parts, flat and deep tiled parts,
and one-level, mipmap, and ripmap level structures. Headers and decoded sample
storage returned for different parts are independently owned. It does not
require byte-identical files, raw compressed-chunk copying, a temporary-file
policy, transactional publication, a CLI, or one internal dispatch layout.

Repository provenance is direct: `src/lib/OpenEXRUtil/ImfImageIO.{h,cpp}`
already owns the high-level generic image API and explicitly rejects multipart
input; `ImfFlatImageIO.cpp` and `ImfDeepImageIO.cpp` define the public
single-image header/data-window rules; and the four multipart input/output part
class pairs expose distinct decoded frame-buffer and tiled-level paths.

## Original v1 trajectory-informed design gate

Searches covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, OpenEXR candidate and rejection records, and local
history for multipart collections, heterogeneous format branches, level
round-trips, ownership, and raw-copy shortcuts. Raw members were inspected in
`archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz`, after reading its
manifest and member list. Calamine and Statig compact records and manifests
were also reviewed. No OpenEXR solver trajectories existed at that time; the
five later OpenEXR runs are reviewed in the revision v3 gate above.

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | PcapPlusPlus `agent-runs4/Nova_Nova_6/{trajectory.json,solution-patch.patch,eval-result.json}` | L5 14/14 and L6 replay 16/16 | A 75-tool direct streaming implementation kept section-local state, validated before publication, added its own regression tests, and deferred discarded-packet option parsing; distinct data branches remained explicit. |
| Near-pass | PcapPlusPlus `agent-runs4/Nova_Nova_1/{trajectory.json,solution-patch.patch,eval-result.json}` | L5 14/14; L6 replay 15/16 | A separate 532-line source and temporary-output architecture implemented the broad contract but validated packet options before filter discard. This supports testing semantic branch timing, not file layout. |
| Broad failure | PcapPlusPlus `agent-runs4/Nova_Nova_3/{trajectory.json,solution-patch.patch,eval-result.json}` | L5 10/14 | A 448-line scanner handled most framing but collapsed Decryption Secrets payload and option boundaries. Four fixtures failed through one mistaken branch, showing that fixture count is not discriminator count. |

The full raw review also showed proactive full/no-network builds, focused smoke
programs, and repository tests in passing implementations. The broad failure
compiled and passed the complete selected baseline, so its missed branch was a
behavioral omission rather than an environment failure.

## Promotion architecture trials

Two disposable implementations were compiled and executed offline in the
Phase-A image before test authoring:

1. A direct decoded adapter added 487 raw production lines across
   `ImfImageIO.h` and `ImfImageIO.cpp`. It built all 285 configured targets and
   round-tripped four ordered heterogeneous parts, flat ripmaps, deep mipmaps,
   asymmetric samples, public headers, and post-load source mutation.
2. A 141-line single-part bridge extracted each multipart part through the
   repository's `copyPixels()` APIs, reused `loadImage()`/`saveImage()` on
   temporary single-part files, and reassembled the four-part file. It also
   passed the same end-to-end smoke. This is a legitimate architecture and
   must remain accepted; polished collision-safe cleanup and the public API
   would increase its production scope, but the Long-horizon forecast remains
   uncertain until successful solver patches exist.

The move-owned record API was selected over parallel header/image vectors
because it makes ordering and ownership one public value and prevents vector
length drift without prescribing either internal architecture.

## Discriminator ledger

| Observed solver behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| Raw scanners can implement one family and omit an independently parsed family. | Route every part through flat scanline handling. | Every supported flat/deep and scanline/tiled part loads and saves. | Reopen a heterogeneous file and compare dynamic image/type/sample state by ordered index. | Four independent low-level part-class branches. | Any direct, refactored, or temporary-file implementation that produces the same public file passes. |
| Near-passes often mishandle a branch only after a later semantic decision. | Choose tiling from header alone or image levels alone. | The existing `saveImage()` selection rule applies per part. | Mix explicit one-level tiles, implicit multilevel tiles, and scanline parts. | Header/image reconciliation. | Tests the documented sibling behavior, not helper selection. |
| One framing bug caused several fixture failures in a single family. | Treat more fixtures as more semantic coverage. | Mipmap and ripmap traversal retain every independently addressed level. | Place distinguishable values in asymmetric `(lx, ly)` levels. | Tiled level traversal. | One asymmetric level oracle rejects collapsed traversal without requiring loop shape. |
| Payload/options were conflated at a nested data boundary. | Read deep pixels without the sample-count allocation phase. | Deep sample counts and every per-pixel sample survive. | Compare counts first, then values for varying zero/one/multiple-sample pixels. | Deep allocation and frame-buffer lifecycle. | Uses the public `DeepImage` model and accepts all allocation strategies. |
| Alternative architectures staged data through temporary outputs. | Reject non-reference storage or publication choices. | Only ordered headers/images and resulting EXR behavior are contractual. | Low-level reopen plus high-level reload; no path, size, byte, or timing assertion. | Architecture freedom. | Explicitly preserves the compiled bridge implementation. |
| Collection APIs invite first-element implementations. | Load or save only part zero, or reuse one buffer/header across entries. | All parts remain ordered and independently owned. | Three-plus distinguishable parts, then mutate one returned/source part and inspect siblings/file. | Collection cardinality and ownership. | Observes public values and aliases, never private addresses beyond required non-alias behavior. |

## Clause-to-test coverage

| Public requirement | Planned observable test | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Exact move-owned API | Compile and construct/move `ImagePart` and call both functions. | Missing declarations/symbols. | Compiles and links. | Necessary public calling contract. |
| Ordered heterogeneous save/load | Four part kinds with unique names and attributes. | Multipart high-level load is unsupported. | All parts compare in order. | Four repository part-class pairs. |
| Tiled level structure | Flat ripmap and deep mipmap with asymmetric level values. | No collection API. | All levels round-trip. | Existing `Image` level API and tiled I/O sibling behavior. |
| Deep samples | Variable zero/one/multiple counts and values. | No collection API. | Counts and values round-trip. | Public `DeepImage` sample-count contract. |
| Header/data-window rules | Custom attributes, windows, channels, explicit tiling, and crop mode. | No collection API. | Per-part behavior matches `saveImage()`. | Existing single-image contract. |
| Ownership and input stability | Mutate source after save and one loaded part after load. | No collection API. | File and siblings remain unchanged. | Move ownership plus separate decoded images. |
| Single-part producer and validation | Load a low-level single-part file; reject empty/null/unnamed/duplicate/unsupported collections or parts. | Missing API or existing explicit multipart refusal. | Defined outcomes. | Multipart writer requirements and public prompt. |

## Environment and harness preflight

- Phase A at the immutable pin passed configure, full build, and 127/127 CTest
  offline as UID 12345 in image
  `sha256:980b738972ce8dfd0178331d15a9668071df977a496bc3c0cdbe79117a69eb93`.
- Both architecture trials compiled and ran in that network-disabled image.
- Tests will use additive C++ sources and a test-only CMake registration; no
  hidden patch will edit `ImfImageIO.h` or `ImfImageIO.cpp`.
- Fixtures are generated deterministically in process. No scheduler, network,
  external image corpus, or byte-identical output oracle is planned.

This preflight does not replace Phase B exact evaluator composition.

## Exact-version closure

The final additive verifier has seven named nodes: one build/API node and six
behavioral scenarios. It covers the complete supported family/layout/level
matrix, both data-window modes, required and custom header state, FLOAT/UINT/
HALF flat channels, FLOAT/HALF deep channels, ordered ownership, invalid
collections, and single- and multipart producers. Pristine passes the four
selected base tests and fails the feature build for the missing public API;
the reference passes 4/4 base and 7/7 feature tests.

The exact environment, gap, and fairness gates pass for revision v5. All 27
mutations compile: 26 incorrect implementations are killed by their intended
public discriminator, while one focused survivor delegates duplicate-name
rejection to `MultiPartOutputFile`. Because invalid input is still rejected,
that survivor is behaviorally equivalent rather than a false positive. No
actionable survivor remains. The mandatory `Nova_Nova_1` mismatch replay and
three clean current solver replays pass 4/4 baseline and 7/7 feature tests.
The untouched repository passes 127/127 tests offline as UID 10001.

The canonical reference has 397 strict effective additions in the two natural
production files. The temporary-file bridge remains a legitimate alternative
and no test asserts helper layout, file bytes, staging policy, or timing.

## Design verdict

Immutable revision v5 passes the design, environment, gap, fairness, and
false-positive gates. The behavior has distinct flat/deep, scanline/tiled,
level, header, data-window, collection, validation, and ownership boundaries,
while the compiled bridge and solver patches keep the suite black-box across
legitimate architectures. The deep positive crop still kills its isolated
family-specific mutant, and the new assignment traits kill two
production-compiling lifecycle mutants without changing the seven public test
identities. The earlier solver batches are historical evidence only: changing
the verifier created revision v5 and reset calibration to 0/10. The 8/10
difficulty rating remains an uncalibrated candidate estimate.
