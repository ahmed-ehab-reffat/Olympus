# Gap analysis - OpenEXR multipart Image I/O

Verdict: `pass for immutable revision v17`.

Repository pin: `c101ab742a9e93c8c9c6f1781055e938cc160305`.
Artifact identity: `meta 926a2b88`, `test 4974070a`, `solution 55307ae4`,
`Dockerfile fc0ce006`.

## Revision v17 exact-version audit

Revision v17 crosses replacement matching with source-part eligibility:

| Atomic requirement | Strongest black-box discriminator | Coverage |
|---|---|---|
| Reject a replacement whose exact name exists only on an unsupported source part | `RewriteValidation` constructs and self-checks a mixed supported/unknown-type source, supplies a replacement carrying only the unsupported part's name, and requires both filename and stream rewrites to reject before changing their destinations | direct |

This cell is not equivalent to an absent source name: an implementation can
index every source header name before filtering unsupported parts. It is also
not equivalent to loading while skipping unsupported siblings: that path has
no replacement-used state. The probe challenges the independent order of
classification and matching once; unsupported type families, positions, and
name permutations were grouped because they do not introduce another public
branch.

The targeted `rewrite_matches_unsupported_source_name` mutant compiles and is
killed by `RewriteValidation`. The complete exact audit runs 76 variants,
kills all 75 behaviorally incorrect variants, and leaves only the equivalent
duplicate-validation delegate. That survivor passes 14/14 focused and 127/127
pre-existing tests. Four materially different historical trees pass the new
predicate while retaining focused scores of 13/14, 14/14, 12/14, and 6/14.
No actionable gap survives; v17 calibration starts at 0/10.

## Revision v16 exact-version audit

Revision v16 adds one missing producer/state crossing to the inherited map:

| Atomic requirement | Strongest black-box discriminator | Coverage |
|---|---|---|
| Apply an exact-name replacement to a supported named typeless ordinary flat single-part source | `SinglePartLoad` creates and self-checks that source with `saveImage()`, rewrites it through filename and stream overloads, compares each complete emitted header with `saveImages()`, and compares the decoded payload with the replacement | direct |

This cell is independent from untouched typeless preservation: the reported
implementation built the correct replacement plan but chose the raw-copy path
from source shape alone. It is also independent from the existing flat/deep
replacement-family matrix, which already checks the image writers but did not
cross them with the legacy producer. Repeating every image family or source
name permutation would not add a new branch and was rejected.

The targeted `rewrite_copies_named_typeless_replacement` mutant compiles and is
killed by `SinglePartLoad`. The complete exact audit runs 75 variants, kills
all 74 behaviorally incorrect variants, and leaves only the equivalent
duplicate-validation delegation survivor. That survivor passes 14/14 focused
and 127/127 pre-existing tests. A materially different run-8 implementation
passes 14/14, while the representative controls remain 13/14, 12/14, and 6/14.
No actionable gap survives; v16 calibration starts at 0/10.

## Revision v15 exact-version audit

Revision v15 corrects an oracle without removing either public header-fidelity
cell:

| Atomic requirement | Strongest black-box discriminator | Coverage |
|---|---|---|
| Load a legacy ordinary file with its complete existing metadata and image | `SinglePartLoad` compares the returned and exact singular headers after erasing only the optional synthesized `type`, then compares the decoded image | direct |
| Preserve an untouched typeless ordinary source as-is through rewrite | The source and both rewrite outputs are inspected through `TiledInputFile`; all must remain typeless with exact raw headers and payloads | direct |

Ignoring only the returned `type` does not admit minimal-header implementations:
every other attribute is still compared. It also does not weaken output
fidelity: the isolated mutant that normalizes the serialized untouched rewrite
is still killed. Both raw-return and synthesized-return architectures pass
14/14.

The complete audit runs 74 variants. All 73 behaviorally incorrect variants
are killed; the sole delegated duplicate-validation survivor passes 14/14
focused and 127/127 pre-existing tests. Exact historical replay remains
discriminating at 14/14, 13/14, 12/14, and 6/14. No actionable coverage gap
survives; v15 calibration starts at 0/10.

## Revision v14 exact-version audit

The inherited map remains applicable. Revision v14 separates two cells whose
producer cardinality and header view cross independent implementation paths:

| Atomic requirement | Strongest black-box discriminator | Coverage |
|---|---|---|
| Apply every valid matching replacement, not merely the first entry after collection validation | `RewriteParts` supplies two named replacements in one collection through filename and stream overloads, then compares both emitted headers with `saveImages()` and both payloads with their inputs | direct |
| Preserve an untouched typeless flat single-part source as-is | `SinglePartLoad` produces the source with `saveImage()`, proves the exact singular header lacks `type`, rewrites with an empty collection through both transports, and compares each output's singular header and decoded image | direct |

The two-replacement fixture adds one collection-cardinality boundary without
permuting names or repeating every family. Existing untouched lossy, deep
scanline, and deep tiled parts remain in the same rewrite, so the stronger
success case does not weaken structural preservation coverage. The typeless
probe uses the producer-matched public reader rather than the normalizing
`MultiPartInputFile` view and compares public `Header` state rather than bytes.

Both isolated production mutants compile and are killed by their intended
nodes. The complete exact audit contains 74 variants: all 73 behaviorally wrong
variants are killed, and the sole delegated duplicate-validation survivor
passes 14/14 focused and 127/127 pre-existing tests. One materially different
run-8 architecture remains 14/14; the former second pass is correctly exposed
at 13/14 on the typeless promise. No actionable gap survives; v14 calibration
starts at 0/10.

## Revision v13 exact-version audit

The inherited requirement map remains applicable. Revision v13 separates three
validation cells that plausible implementations can branch independently:

| Atomic requirement | Strongest black-box discriminator | Coverage |
|---|---|---|
| Reject identical rewrite filenames before modifying the destination | `RewriteValidation` snapshots a valid source, calls the filename overload with the exact same path, requires rejection, and compares the source bytes afterward | direct |
| Reject a disjoint replacement header/image window before modifying either output transport | `RewriteValidation` uses `USE_HEADER_DATA_WINDOW` with a valid one-level replacement whose windows do not intersect, then requires the filename sentinel and stream buffer to remain unchanged | direct |
| Reject both public multiresolution modes from each windowed named-load overload | `WindowedLoad` selects separate mipmap and ripmap parts through filename and stream overloads and requires rejection | direct |

Mipmap and ripmap rejection had previously been grouped as one
`mode != ONE_LEVEL` cell. The new `window_accepts_ripmap` mutant demonstrates
that an implementation can instead special-case the two enum values, so they
are now challenged separately without defining any multiresolution crop
semantics. Filename and stream overloads remain separate public directions.

All three probes are already required by the public prompt, pass the reference,
and kill their isolated production mutants. The complete exact audit contains
72 variants: all 71 behaviorally incorrect variants are killed, and the sole
delegated duplicate-validation survivor passes 14/14 focused plus 127/127
pre-existing tests. Both legitimate run-8 architectures pass 4/4 existing and
14/14 focused on exact replay. No actionable gap survives; calibration starts
at 0/10 for the changed artifacts.

## Revision v12 exact-version audit

The inherited atomic-requirement map below remains applicable. Revision v12
changes one independently implemented rewrite cell:

| Atomic requirement | Strongest black-box discriminator | Coverage |
|---|---|---|
| A replacement emitted by `rewriteImages()` has the same complete header as that replacement emitted by `saveImages()` | `RewriteParts` saves the exact replacement with the public stream save overload, reloads its emitted header, and compares both filename and stream rewrite headers to it | direct |

The fixture carries nondefault line order and two custom attributes in addition
to the deep-tiled type, tile description, normalized compression, channels,
level mode, and rounding state. The oracle compares the complete public
`Header`; it does not enumerate only those fields. Filename and stream rewrite
remain separate because they are independent public overloads.

The exact mutation set now contains 69 production variants. All 68
behaviorally incorrect variants are killed. The new
`rewrite_drops_replacement_header_state` variant changes only replacement
encoding and is killed by `RewriteParts`. The only survivor delegates duplicate
save-name rejection to OpenEXR and is equivalent, passing 14/14 focused and
127/127 pre-existing tests.

Both legitimate run-8 passes retain 4/4 existing and 14/14 focused results on
exact v12 replay. No actionable gap survives. Calibration restarts at 0/10 for
the changed artifacts.

## Historical revision v11.2 audit

Revision v11.2 removes redundant ordering language, conventional stream
ownership boilerplate, and an untested claim about selecting an unnamed source
for replacement. It also restates the empty-replacement behavior in plain
language. The tested atomic requirements are unchanged, so the coverage matrix
below remains applicable. The exact environment and 68-mutant audits were
rerun for the new prompt hash; all 67 incorrect mutants are killed and the one
delegated duplicate-rejection survivor remains behaviorally equivalent. No
actionable gap survives.

## Historical revision v11 exact-version audit

The inherited multipart contract remains covered by the revision v9.1 map
below. Revision v11 adds one public API family: filename and caller-owned
`IStream` named loads with a requested `Box2i`. The exact-version map for that
addition is:

| Atomic requirement | Strongest black-box discriminator | Coverage |
|---|---|---|
| Both windowed overload declarations and `ImagePart` return type | `Build` resolves the filename and stream signatures at compile time | direct |
| Exact case-sensitive named selection, including an unsupported sibling | `WindowedLoad` rejects a case-folded spelling through both transports; `UnsupportedParts` selects a supported part after an unknown middle part and rejects the unknown name through both windowed overloads | direct |
| `ONE_LEVEL` flat/deep scanline/tiled decoding | `WindowedLoad` compares all four independent OpenEXR part families through filename and stream entry points | direct |
| Requested/source intersection and disjoint rejection | An outside-overlapping request verifies the exact intersection; disjoint filename and stream calls reject | direct |
| Reject an intersection incompatible with channel sampling | A 2x2 sampled flat channel is selected with a misaligned result through filename and stream overloads; both reject without message matching | direct |
| Complete copied header with only `dataWindow` adjusted | Every family and transport is compared against the complete-load header after changing only the expected `dataWindow` | direct |
| Exact channels, sampling, flat samples, deep counts, and deep samples | Offset-window flat fixtures include a 2x2 sampled channel; deep fixtures compare counts and HALF/FLOAT samples | direct |
| Reject selected mipmap or ripmap parts | Filename and stream select a mipmapped part and reject it; mipmap and ripmap share the public non-`ONE_LEVEL` predicate | direct, grouped |
| Do not require storage wholly outside the returned window to decode | Self-checked damaged flat/deep scanline chunks and flat/deep tiles are loaded through both transports; eager mutants for every family fail | direct |
| Valid UTF-8 filename behavior on the new overload | `Utf8Filename` performs a windowed named load on the mixed-script path and compares header and pixels | direct |

The family matrix keeps flat scanline, deep scanline, flat tiled, and deep tiled
separate because they use four independent OpenEXR readers. Deep reads also
cross the sample-count allocation boundary. Filename and stream wrappers stay
separate where earlier solver evidence showed transport asymmetry. Mipmap and
ripmap rejection are grouped because both are represented by the same public
`LevelMode != ONE_LEVEL` branch; no lower-level crop semantics are promised.

The preliminary audit found and closed four real gaps in the first v11 draft:
deep-scanline and flat-tile fault isolation, exact-name/UTF-8 behavior on the
new overload, stream-side disjoint and unsupported selection, and nonzero
coordinate plus sampled-channel copying. Each added probe passes the reference,
fails the pristine tree as part of the missing-API case, and kills its targeted
production mutant.

The exact mutation audit contains 68 production variants. Sixty-seven
behaviorally wrong variants are killed. The sole survivor removes an explicit
duplicate-name precheck but still rejects duplicates through OpenEXR's public
multipart constructor, so it is equivalent rather than actionable. The eight
new v11 mutants cover ignored requests, filename/stream wrapper omission,
eager reads in all four storage families, multiresolution acceptance, and stale
header windows; all eight are killed by `WindowedLoad`.

All five run-7 implementations compose cleanly, pass the 4/4 existing lane,
and fail the 14-identity focused lane because they lack the new public
overloads. This is a 0/5 historical replay, not fresh calibration. It confirms
that the discriminator crosses the shared eager architecture found in the
trajectories; it does not establish the future solve rate. No actionable gap
survives. Calibration remains 0/10 for the immutable v11 artifacts.

## Historical revision v9.1 atomic requirement map

| Public requirement | Strongest black-box discriminator | Coverage |
|---|---|---|
| Move-only `ImagePart`, public fields and constructor, alias, and every overload | `Build` checks construction, copy/move construction and assignment traits, overload resolution, return types, defaults, and linkage | direct |
| Save a nonempty ordered collection; reject null, unnamed, empty-name, duplicate-name, unsupported, and invalid multiresolution-crop inputs | `ApiAndValidation` requires every predicate to throw through filename and fresh `OStream` destinations without inspecting post-failure stream bytes | direct |
| Load/save every supported family and level structure in order | `LoadHeterogeneous`, `SaveHeterogeneous`, and `StreamRoundTrip` compare flat/deep scanline/tiled one-level, mipmap, and ripmap state | direct |
| Preserve public headers, windows, channel metadata, level rounding, flat samples, and deep counts/values | Heterogeneous comparisons plus independent low-level reopen and extraction | direct |
| Apply `DataWindowSource` per part | `HeaderAndCrop` covers flat and deep positive crop; stream crop and later-part multiresolution rejection cover independent branches | direct |
| Accept single-part producers and return independent ownership | `SinglePartLoad` and `OwnershipIsolation` | direct |
| Select by exact case-sensitive name without decoding unreadable siblings | `SelectiveLoad` distinguishes `Hero`, `hero`, and absent `HERO`, with a proven damaged unselected payload, through both transports | direct |
| Skip unsupported siblings while retaining supported relative order | `UnsupportedParts` crosses load-all and named load through filename and stream transports, including a supported part after the unknown type | direct |
| Accept valid non-ASCII UTF-8 filenames | `Utf8Filename` crosses save-all, load-all, named load, and both rewrite filenames using mixed-script paths | direct |
| Rewrite supported source parts in original order and skip unsupported parts | `RewriteParts` covers heterogeneous order; `UnsupportedParts` covers filename and stream rewrite around an unknown middle sibling | direct |
| Match replacement names exactly and validate the whole collection before output changes | `RewriteValidation` applies null, missing/empty/duplicate/unsupported/unmatched/case-folded/multiresolution cases to both overloads and checks unchanged destinations | direct |
| Encode replacements with save rules | `RewriteParts` performs a flat-tiled to deep-tiled family change and positive deep header-window crop through filename and stream rewrite | direct |
| Structurally preserve untouched parts, including empty replacement rewrites | `RewriteParts` compares untouched valid lossy/deep state, accepts an empty replacement collection, and proves rewrite succeeds past an unreadable untouched part that remains unreadable | direct |

## Repository-grounded dimensions

The supported image-family matrix includes flat scanline one-level; flat tiled one-level, mipmap, and ripmap; deep scanline one-level; and deep tiled one-level, mipmap, and ripmap. Unsupported scanline multiresolution cells are not invented. Explicit and implicit tiling, both rounding modes, FLOAT/UINT/HALF flat channels, FLOAT/HALF deep channels, and zero/one/many deep samples are represented.

Transport branches remain separate because each is a public overload: filename and stream save-all/load-all/load-one/rewrite all have positive behavior. Every save rejection crosses both output transports. Every rewrite rejection crosses both output transports and a no-publication oracle. Unknown-type handling crosses stream and filename load-all, selection, and rewrite rather than relying on one shared fixture call.

Rewrite crosses independently implemented states: a family-changing replacement, untouched flat lossy scanline, untouched deep scanline, untouched deep ripmap, empty replacements, an unsupported sibling, and an unreadable untouched payload. Positive deep crop runs through both rewrite overloads. Exact replacement matching distinguishes a present case-folded spelling from a genuinely absent name.

## Challenges and probe decisions

The first v9 draft exposed three actionable gaps during this audit. Invalid rewrite collections were tested only through the stream overload; exact replacement matching did not distinguish case folding; and the new filename and crop branches were covered only by older APIs. The final suite applies every invalid family to both overloads, adds `TARGET` beside source `target`, exercises mixed-script input and output rewrite paths, and positively crops a deep replacement through both rewrite transports.

The final overload audit then found stream-only gaps around unknown siblings. `UnsupportedParts` now loads all, selects supported and unsupported names, and structurally rewrites through both transports. Strict-validation mutants isolated to each stream entry point fail that scenario.

The v9.1 fairness review removed one stronger-than-public assertion: invalid
stream saves no longer have to leave the destination empty. This does not
weaken any atomic public requirement. Every save validation family still
crosses both overloads and all seven stream-only silent-acceptance mutants are
killed by the exception oracle. Rewrite validation retains unchanged filename
and empty stream destinations because pre-mutation rejection is explicit for
that API.

Admitted probes are public, reference-passing, pristine fail-to-pass through the absent API, and targeted-mutant-failing. Byte-identical files, chunk offsets, private constructor flags, helper names, read/seek counts, temporary-file use, same-path atomic replacement, malformed UTF-8, normalization, exception text, resource ceilings, and every family/order permutation remain excluded. They either prescribe private machinery, add an unstated policy, or repeat an already isolated semantic boundary.

## Mutation and replay result

Sixty production mutants were rerun against v9.1. Fifty-nine behaviorally incorrect variants are killed and one equivalent duplicate-validation delegation survives. The additions specifically kill filename-only stream validation, abort-on-unknown loading, strict stream header validation, reordered or ignored replacements, case-folded matching, decode/resave of untouched pixels, omitted per-overload crop handling, and ASCII-only rewrite filenames. There are zero actionable survivors.

All five run-6 implementations remain valid v8 architecture evidence and inject cleanly, but none has the rewrite API, so no historical outcome is relabeled as a v9.1 pass. The reference passes 13/13, the pristine implementation fails the missing public API, and the equivalent survivor passes the pre-existing suite 127/127. No actionable gap survives the exact-version audit.
