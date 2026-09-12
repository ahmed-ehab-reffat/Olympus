# False-positive audit - OpenEXR multipart Image I/O

Verdict: `pass for immutable revision v17; no actionable survivor`.

Repository pin: `c101ab742a9e93c8c9c6f1781055e938cc160305`.
Artifact identity: `meta 926a2b88`, `test 4974070a`, `solution 55307ae4`,
`Dockerfile fc0ce006`, mutation script `9d2d3eef`.

## Revision v17 exact audit

The participant requirement map is retained from `GAP_ANALYSIS.md`. The new
plausible shortcut comes from a real ordering choice: mark replacement names
against every source header, then omit unsupported source parts. Existing
tests covered absent names and unsupported loading separately, so that wrong
implementation could satisfy both.

`rewrite_matches_unsupported_source_name` changes only the source-name matching
step for an unsupported part. It compiles and is killed by `RewriteValidation`
through both public transports. The reference and all four replayed run-8
architectures pass the new predicate, so the probe does not select one planning
implementation.

The final exact audit runs 76 production variants. All 75 behaviorally
incorrect variants are killed. The sole survivor delegates duplicate-name
rejection to the OpenEXR writer and passes 14/14 focused plus 127/127
pre-existing tests in 380.09 seconds. Exact replay scores remain 13/14, 14/14,
12/14, and 6/14. No actionable survivor remains.

## Revision v16 exact audit

The reported survivor is a plausible state-selection shortcut: after matching
and validating replacements, choose a singular raw-copy fast path from the
source being flat, one-part, and typeless, without checking whether that slot
has a replacement. Repository `saveImage()` behavior and the prior reference
both make this branch concrete; independent run-8 implementations show that it
need not be coupled to legacy preservation.

`rewrite_copies_named_typeless_replacement` removes only the replacement-state
guards from the filename and stream fast paths. It compiles and is killed by
`SinglePartLoad` when the complete replacement header differs from the raw
source. The reference and run-8 solution 2 pass. No extra scanline/tiled/deep
permutations were added because they do not challenge another implementation
mode.

The final exact audit runs 75 production variants. All 74 behaviorally
incorrect variants are killed. The sole survivor removes an explicit duplicate
name precheck while the OpenEXR writer still rejects the same collection; it
passes 14/14 focused and 127/127 pre-existing tests in 328.64 seconds. Exact
replay scores are 13/14, 14/14, 12/14, and 6/14. No actionable survivor
remains.

## Revision v15 exact audit

Removing the mandatory synthesized returned `type` creates no actionable
survivor. A legitimate implementation that substitutes the raw singular header
in `ImagePart` passes 14/14, proving the corrected architecture freedom. A
minimal or partially reconstructed load header still fails because the oracle
ignores only `type` and compares every other attribute.

The public untouched-rewrite rule remains independently strong. The
`rewrite_normalizes_typeless_single` production mutant compiles and is killed
because both serialized outputs must retain the exact raw typeless header.
All other participant-facing requirements retain their strongest tests from
the inherited map.

The final exact audit runs 74 production variants. All 73 behaviorally
incorrect variants are killed. The sole survivor removes an explicit duplicate
name precheck while OpenEXR still rejects the same input; it passes 14/14
focused and 127/127 pre-existing tests in 320.70 seconds. Exact replay scores
14/14, 13/14, 12/14, and 6/14. No actionable survivor remains.

## Revision v14 exact audit

The participant-facing map is in `GAP_ANALYSIS.md`. Revision v14 adds two
plausible production shortcuts grounded in the rewrite plan and pinned reader
behavior:

- validate and match the complete replacement collection but publish only the
  first matching replacement, copying later matching sources unchanged; and
- use the `MultiPartInputFile`-normalized header when copying an untouched
  typeless legacy single-part source.

`rewrite_applies_first_replacement_only` dynamically selects the first non-null
replacement plan entry and treats later entries as untouched. It compiles and
is killed by `RewriteParts`. `rewrite_normalizes_typeless_single` bypasses the
reference's exact singular-header copy branch for both transports; it compiles
and is killed by `SinglePartLoad`. Neither mutant depends on hidden filenames,
literal source indices, or an artificial data permutation.

The final exact audit runs 74 production variants. All 73 behaviorally
incorrect variants are killed. The only survivor removes an explicit duplicate
name precheck while OpenEXR still rejects the same collection; it passes 14/14
focused and the complete 127/127 pre-existing suite in 324.87 seconds. The
reference and the independent run-8 solution 2 pass 14/14. No actionable
survivor remains.

## Revision v13 exact audit

The participant-facing map is in `GAP_ANALYSIS.md`. Revision v13 adds three
repository- and trajectory-grounded shortcuts:

- remove the explicit identical-filename guard and allow later processing to
  throw after touching the same file;
- omit empty header/image intersection validation from the rewrite plan and
  defer failure until output construction; and
- reject `MIPMAP_LEVELS` specifically while accepting `RIPMAP_LEVELS` in a
  windowed named load.

Each mutant changes production code, compiles, passes unrelated setup, and is
killed by its intended black-box node. `rewrite_allows_same_filename` and
`rewrite_skips_empty_crop_prevalidation` fail `RewriteValidation`;
`window_accepts_ripmap` fails `WindowedLoad`. The probes use public state and
promised failure boundaries, not private helpers, serialized type bytes,
exception messages, timings, aliases, or arbitrary malformed input.

The final exact audit runs 72 production variants. All 71 behaviorally
incorrect variants are killed. The only focused survivor still removes the
explicit duplicate-name precheck while OpenEXR rejects the same collection; it
passes 14/14 focused and the complete 127/127 pre-existing suite in 315.24
seconds. Both legitimate run-8 implementations pass the strengthened 14/14
suite. No actionable survivor remains.

## Revision v12 exact audit

The participant-facing requirement map is in `GAP_ANALYSIS.md`. Revision v12
adds one plausible production shortcut from run-8's separate replacement
encoding branch: preserve the replacement pixels and type while dropping
replacement-only header state. The isolated
`rewrite_drops_replacement_header_state` mutant removes `comments` only after
the rewrite header is prepared. It compiles and is killed by `RewriteParts`.

The complete exact audit runs 69 production variants. All 68 behaviorally
incorrect variants are killed, including the new header-fidelity variant and
all eight windowed-load variants. The only focused survivor removes an explicit
duplicate-name precheck but delegates the same rejection to OpenEXR's public
multipart constructor. It passes 14/14 focused tests and the full 127/127
pre-existing suite in 316.57 seconds, so it remains equivalent rather than
actionable.

Both legitimate run-8 passes were replayed and retain 14/14 focused results.
No attribute whitelist, output-byte identity, private header layout, or extra
family permutation was added. The admitted probe is public, distinct,
reference-passing, targeted-mutant-failing, and still fail-to-pass on the
pristine missing-API tree. No actionable survivor remains.

## Historical revision v11.2 audit

Revision v11.2 changes no tested participant-facing behavior. The full
68-mutant audit was still rerun for the new prompt hash: all 67 behaviorally
incorrect variants are killed, including all eight windowed-load mutants, and
only the equivalent delegated duplicate-rejection variant survives focused
tests. Its exact-version escalation passes 127/127 pre-existing tests in
319.84 seconds.

## Revision v11 exact audit

Revision v11 adds eight production mutants derived from the common eager
architecture in the run-7 trajectories and the independent OpenEXR reader
families:

- filename or stream windowed wrappers ignore the requested box;
- flat or deep scanline paths read the complete source scanline range;
- flat or deep tiled paths read every source tile;
- the selected multiresolution part is accepted; and
- the returned header keeps the source data window.

All eight compile as production code and are killed by `WindowedLoad`. The four
eager-reader mutants are killed by separate self-checked damaged storage in
flat scanline, deep scanline, flat tiled, and deep tiled files. This means the
new discriminator is behavioral after the API exists; it is not merely a
compile-time novelty check.

The exact audit now has 68 variants. Sixty-seven behaviorally incorrect
variants are killed. The one survivor is unchanged from v9.1: removing the
explicit duplicate-name check delegates the same rejection to OpenEXR's public
multipart constructor. It is behaviorally equivalent and not an actionable
false positive. Its exact v11 escalation passes 14/14 focused and 127/127
pre-existing tests in 319.48 seconds. The mutation script restores both
production files and checks their hashes after the run.

The preliminary coverage pass also tested plausible omissions before freezing
the suite. It admitted deep-scanline and flat-tile outside-damage probes,
UTF-8/exact-name coverage on the new overload, stream disjoint/unsupported
coverage, and offset/sampled-channel copying. It rejected batch named loads,
same-path rewrite, raw preservation of arbitrary unknown chunks, read-count
oracles, and resource ceilings because they were redundant, platform-specific,
private-format, or unstated requirements.

All five run-7 patches compose with the exact verifier, retain 4/4 existing
tests, and fail the 14-case focused suite at the announced new overloads. Those
historical replays are architecture evidence only; calibration remains 0/10.

## Historical revision v9.1 audit

The participant-facing requirement map is in `GAP_ANALYSIS.md`. Mutants are drawn from independent repository branches, six solver batches, reported review gaps, and the new rewrite architecture. Every counted variant changes production code. Public lifecycle variants compile the library before the verifier rejects them; behavioral variants compile the full focused target before execution.

## Mutation families

The retained predecessor set challenges copy/move lifecycle, collection order and cardinality, every supported flat/deep scanline/tiled level family, deep sample-count setup, public attributes, data windows, tiling, rounding, compression, channel types, single-part input, stream behavior, exact named selection, eager filtering, and UTF-8 filename wrappers.

Revision v9 adds 21 focused variants across the newly exposed boundaries:

- six additional stream-only save wrappers silently accept one invalid collection family, completing the earlier empty-collection variant;
- load-all aborts on an unknown sibling;
- rewrite reverses source order, rejects empty replacements, ignores replacements, accepts an unmatched name, folds replacement-name case, or aborts on an unknown source part;
- rewrite decodes and resaves every untouched part;
- filename or stream rewrite ignores `DataWindowSource`;
- rewrite rejects non-ASCII input or output filenames; and
- stream load-all, selected load, or rewrite uses strict unknown-type header validation.

## Actionable trial found during drafting

The first v9 prototype's case-insensitive replacement matcher passed every focused test. The prompt already required exact, case-sensitive matching, and replacement lookup is independently implemented from named loading. A `TARGET` replacement against source `target` was added to `RewriteValidation` through both overloads. The reference passes and the isolated case-folded mutant now fails that node.

The first draft's valid lossy comparison did not distinguish decode/resave because its chosen DWA sample state was idempotent in that generation. A second-byte-generation assertion would have prescribed serialization. Instead, the final public probe writes a valid ZIP-compressed source, corrupts one untouched chunk using repository chunk metadata, and replaces a later valid part. Structural implementations succeed while the decoded/resaved mutant fails at the unreadable untouched part; the output's untouched part remains unreadable as explicitly required.

## Final result

All 60 variants were rerun after the v9.1 assertion removal. All 59 behaviorally incorrect variants are killed, including the seven stream-only save-validation variants. Those seven return normally for one invalid collection and therefore fail the retained exception oracle; none depended on checking stream bytes.

The only focused survivor removes the explicit duplicate-name precheck from `saveImages()`; OpenEXR's `MultiPartOutputFile` rejects the same collection. That variant passes 13/13 focused and 127/127 pre-existing tests in 318.06 seconds, confirming behaviorally equivalent delegation rather than an actionable false positive.

The exact reference passes 13/13 focused tests. The mutation script restores both production sources after every run. Controlled configuration and base-build probes separately demonstrate reliable pre-test reporting and are not counted as production mutants.

No probe was added for byte identity, exact compressed chunk layout, private multipart flags, helper names, read/seek counts, temporary-file strategy, exception wording, same-path replacement, malformed UTF-8, path normalization, memory ceilings, or repeated family/order permutations. A zero-actionable-survivor result is evidence only for these 60 variants, not proof that false positives are impossible.

The rejected invalid-save atomicity predicate is not replaced. It lacks public
or repository provenance, and no reviewed trajectory demonstrates partial
stream output as an incorrect observable behavior. Rewrite atomicity remains a
separate explicit requirement and discriminator.
