# Fairness analysis - OpenEXR multipart Image I/O

Verdict: `pass for immutable revision v17`.

Repository pin: `c101ab742a9e93c8c9c6f1781055e938cc160305`.
Artifact identity: `meta 926a2b88`, `test 4974070a`, `solution 55307ae4`,
`Dockerfile fc0ce006`.

## Revision v17 predicate audit

The new rejection predicate is stated directly in the prompt: replacement
names that do not match a supported source part are invalid, and invalid
replacements must be rejected before either destination is modified. A name
on an unsupported part therefore does not satisfy the supported-source match.

The fixture is repository-grounded. Public low-level writers first create a
valid named multipart source; the existing exact-occurrence helper then changes
one unique, equal-width serialized type value to an unknown value. The test
proves that value differs from every supported type before exercising either
rewrite overload. It does not inspect participant layout, require a name-map
order, match exception text, or constrain how unsupported parts are skipped.
Index-after-filter, filter-during-scan, and supported-plan-map architectures all
pass.

All four run-8 architectures pass the new assertion. The reference passes
14/14; the targeted public-behavior mutant fails it; and the exact environment,
gap, 76-variant mutation, survivor, and false-positive audits pass. Verdict for
immutable v17: `pass`.

## Revision v16 predicate audit

Revision v16 adds no rejection predicate and does not change the prompt. The
positive check follows directly from two discoverable public facts: the
existing `saveImage(filename, header, image)` overload accepts a named header
and writes a valid typeless ordinary flat file, and `rewriteImages()` requires
an exact-name replacement to replace its supported source part.

The test proves the source's name and absent `type` through the matching
singular reader. Expected replacement state comes from the participant's own
public `saveImages()` overload, then the test compares complete public headers
and decoded images. It does not require singular or multipart output, raw copy,
a planning pass, a writer class, serialized bytes, exception text, or any
specific batching strategy. Whole-stream copy when there is no replacement,
per-slot dispatch, and direct multipart writing all remain valid.

The filename and stream checks cover separate public overloads. The independent
run-8 solution 2 passes 14/14. Exact environment, gap, 75-variant mutation,
survivor, and false-positive audits pass. Verdict for immutable v16: `pass`.

## Revision v15 predicate audit

The prior `SinglePartLoad` assertion unfairly made
`MultiPartInputFile(autoAddType=true)` the unique returned-header oracle for a
legacy ordinary file. The prompt does not require that normalization, and the
neighboring high-level singular reader exposes the raw typeless header.

The corrected assertion copies the returned header and exact singular-reader
header, erases only `type` from both copies, and compares all remaining public
state. It therefore accepts raw and synthesized forms without permitting lost
custom attributes, channels, windows, tiling, compression, or other header
state. Exact absence of `type` is still required for the separately specified
untouched rewrite output and is observed through `TiledInputFile` on both
transports.

The reference's normalized-return architecture and a replayed legitimate
raw-return architecture both pass 14/14. No exception text, serialized byte
layout, internal reader choice, or private helper is prescribed. The exact
environment, 74-variant mutation, survivor, gap, and false-positive audits
pass. Verdict for immutable v15: `pass`.

## Revision v14 predicate audit

Revision v14 adds no rejection rule. Its first discriminator strengthens a
positive plural-collection requirement: every valid replacement name identifies
and replaces its supported source part. The test uses two entries only to cross
the one-versus-many iteration boundary. It observes each result through public
headers and decoded images and derives expected emitted headers from the
participant's public `saveImages()` implementation. Maps, scans, indexed plans,
and direct writers all pass; replacement collection order is not prescribed.

The second discriminator applies the prompt's explicit "preserve it as-is"
rule to a source produced by the existing `saveImage()` helper. The matching
public `TiledInputFile` proves that the valid source header has no `type`
attribute, while `MultiPartInputFile` is documented in the pinned source to add
one when `autoAddType` is enabled. The oracle uses the singular reader on both
outputs and compares public header attributes, not serialized bytes, version
flags, writer classes, helper names, or compressed layout. A singular copy path,
careful de-normalization, or another behaviorally equivalent design passes.

The filename and stream directions are retained because they are separate
public overloads. No exception text, timing, temporary-file strategy, or
private state is checked. `Nova_Nova_2` supplies a materially different 14/14
implementation. `Nova_Nova_1` fails only this explicit public invariant and is
therefore an incomplete historical implementation, not a verifier mismatch.
Exact environment, 74-mutant, and survivor escalations pass. Verdict for
immutable v14: `pass`.

## Revision v13 predicate audit

Revision v13 adds no public requirement. It strengthens three rejection
predicates already stated in the prompt.

The identical-path check uses the same filename string for input and output,
requires only an exception, and compares the valid source before and after the
failed call. That is exactly the promised "before modifying the destination"
boundary. It does not require alias, symlink, case-fold, or canonical-path
detection; a temporary-file strategy; successful-output byte identity; or a
particular exception.

The disjoint replacement fixture is ordinary public `Header` and `Image` state:
both windows are valid boxes, but their `USE_HEADER_DATA_WINDOW` intersection
is empty. The prompt explicitly calls that replacement invalid and explicitly
requires rewrite validation before either destination changes. Reusing the
existing filename sentinel and fresh stream buffer is therefore fair here,
unlike the removed invalid-`saveImages(OStream&)` atomicity assertion. The test
does not match exception type, text, predicate order, or planning structure.

`MIPMAP_LEVELS` and `RIPMAP_LEVELS` are the two public values outside the
announced `ONE_LEVEL` domain. Rejecting each through both public `Box2i`
overloads observes only that domain restriction; it does not prescribe how the
mode is inspected or define lower-level crop behavior. The categorical check
passes two independent legitimate run-8 implementations. Exact environment,
replay, 72-mutant, and survivor escalations pass. Verdict for immutable v13:
`pass`.

## Revision v12 predicate audit

Revision v12 adds no new rejection predicate. It strengthens one positive
relational requirement already stated publicly: replacement encoding through
`rewriteImages()` must preserve the same complete emitted header as
`saveImages()`.

The expected header is produced by the participant's own public
`saveImages(OStream&)` implementation and observed after an ordinary public
load. The rewrite result is compared as public `Header` state. The check does
not require attribute insertion order, serialized bytes, a reference helper,
temporary-file policy, or a particular writer architecture. Direct writers,
header reconstruction, staging, and shared helper designs all pass when their
observable headers agree.

The replacement uses valid shared multipart state; a provisional conflicting
pixel-aspect fixture was rejected and removed. The final discriminator varies
only legal per-part state such as line order, custom attributes, type, tiling,
compression normalization, channels, and level structure. Both legitimate
run-8 implementations pass the exact test, providing replay evidence for more
than the reference architecture.

All rejection predicates inventoried in the historical v11 and v9.1 tables are
unchanged and remain grounded in the public prompt, pinned repository behavior,
or stable C++ semantics. The exact environment, 69-mutant, and survivor audits
pass. Verdict for immutable v12: `pass`.

## Historical revision v11.2 predicate audit

Revision v11.2 preserves every tested predicate while removing redundant order
wording, stream-ownership boilerplate, and an untested restriction on selecting
an unnamed source for replacement. The empty-replacement requirement is merely
restated in plain language. The exact predicate inventory below remains a
`pass`.

## Historical revision v11 predicate audit

| Rejection predicate | Provenance and implementation freedom |
|---|---|
| Exact two new overloads and return type | Explicit public API contract plus ordinary C++ overload resolution; declaration order, helper layout, and implementation dispatch are unobserved |
| Exact case-sensitive selected name and supported image type | Explicit contract inherited by the new named-load overloads; linear scans, maps, hashes, and header indexes all pass |
| Nonempty requested/source intersection | Explicit contract; the test accepts any exception type and text for a disjoint request |
| Result is representable under every channel's sampling | Explicit contract grounded in `Image::resize()` and the public channel/data-window model; the test accepts delegated validation and any exception text |
| Selected part is `ONE_LEVEL` | Explicit public restriction avoids inventing mip/ripmap crop rules; the test does not constrain how the mode is detected |
| Returned header and image use the exact intersection | Explicit public result and OpenEXR's public `Header`/`Image` state; copied, reconstructed, staged, and direct-reader designs pass if all public header state is retained |
| Channels, sample counts, and samples inside the intersection are exact | Explicit public result; comparisons use public image APIs and permit any temporary allocation or copy strategy |
| Damage wholly outside the result does not block the load | Explicit observable isolation requirement; direct bounded readers, chunk staging, caching, OpenEXRCore, or another equivalent implementation passes |
| UTF-8 filename and stream-overload behavior | Explicit qualifiers inherited by the overload family and established repository filename/stream support |

The outside-damage fixtures begin as valid files written by public OpenEXR
writers. OpenEXRCore locates an actual chunk or tile for the selected part, the
test changes only its packed payload (and the public deep sample-count table
when present), and an ordinary complete load must observe the damage before the
windowed assertion is accepted. The hidden oracle never relies on the numeric
offset, compressed bytes, exception text, or implementation read count. It
only observes success for a result whose requested storage remains intact.

Offset source windows and the sampled flat channel are valid public `Image`
state. Their values are compared only at coordinates where the channel exists.
The test does not require a private base-pointer formula. Flat and deep
scanline/tiled damage checks are retained separately because the pinned
repository exposes four different reader classes and deep data has a distinct
sample-count phase; they are not arbitrary permutations.

The old run-7 solutions use materially different dispatch/helper structures,
but all are contract-incomplete for v11 and fail only at the announced overload
declarations. They are therefore historical discriminator evidence, not
legitimate v11 implementations mislabeled as behavioral failures. The pinned
repository APIs and the reference demonstrate bounded scanline, tile, and deep
sample-count implementations without requiring one of them.

No assertion checks read/seek counts, memory use, timing, helper names,
temporary files, serialized output bytes, attribute order, exception wording,
or post-failure bytes from invalid `saveImages(OStream&)`. The harness is
offline, arbitrary-UID, read-only on participant source, and has no product
timeout. Verdict for the exact v11 predicates: `pass`.

## Historical revision v9.1 predicate audit

## Predicate audit

| Rejection predicate | Provenance and implementation freedom |
|---|---|
| Public record shape, move-only lifecycle, overloads, defaults, and return types | Explicit API contract plus stable C++ semantics; correct explicit, defaulted, or implicit implementations pass |
| Save validation across filename and stream overloads | Explicit public rejection rules; any exception type, text, predicate order, delegated rejection, or post-failure stream contents pass |
| Replacement validation across filename and stream overloads | Explicit validation-before-output rules; any exception type, text, predicate order, or delegated rejection passes when the destination remains unchanged |
| Ordered heterogeneous image state | Explicit contract and OpenEXR's public `Image` model; direct dispatch, tables, memory staging, and temporary singular files pass |
| Caller-owned streams | Explicit contract and repository multipart stream constructors; only resulting bytes, continued caller ownership, and decoded state are observed |
| Per-part `DataWindowSource` behavior | Explicit reuse of singular `saveImage()` behavior; centralized and family-specific implementations pass |
| Exact case-sensitive selection and replacement matching | Explicit public identifier rule; linear scans, maps, hashes, and other exact structures pass |
| Skip unknown part types | Explicit public behavior; header classification may occur at any time and no unknown payload decoder is required |
| Unreadable unselected or untouched sibling isolation | Explicit observable result; buffering, compressed staging, direct transfer, or another equivalent design passes |
| Untouched lossy sample preservation | Explicit public result; the oracle compares public compression metadata and decoded samples, never serialized bytes or API calls |
| Valid non-ASCII UTF-8 filenames, including both rewrite paths | Explicit filename qualifier and pinned repository precedent; byte forwarding, platform widening, path wrappers, or equivalent mechanisms pass |
| Stable order and family-changing replacement | Explicit rewrite contract; no helper, batching, publication, or dispatch order beyond final file order is prescribed |

## Fixture provenance

All ordinary files, headers, channels, levels, and pixels are created through public OpenEXR writers and image APIs. The unsupported-part fixture replaces the public `type` attribute value `scanlineimage` with an equal-length unknown value while leaving the otherwise valid multipart file intact. Tests require only that supported siblings remain available; they never require the unknown payload to decode or assert exception wording.

The unreadable-part fixtures first write valid compressed OpenEXR data. OpenEXRCore identifies a real compressed scanline chunk before its packed payload is changed. Existing low-level extraction demonstrates that the selected chunk is unreadable. Participant-facing assertions then observe only the stated isolation boundary: another named part can be loaded or replaced, and structural rewrite does not make the untouched corruption disappear.

The UTF-8 paths use fixed byte escapes for valid mixed-script strings, avoiding source-encoding dependence. The tests do not impose normalization, locale, case folding, canonicalization, malformed-byte behavior, or a particular path library. Windows cleanup follows the repository's `WidenFilename` pattern.

## Rewrite freedom

The suite does not require `copyPixels()`, a private helper, exact compressed chunks, byte-identical output, or one writer architecture. A direct compressed transfer, safe staging, or any other approach passes if untouched public state is preserved and an unreadable untouched payload remains unreadable while replacements are encoded normally. The corruption oracle is needed because decoded valid samples alone cannot distinguish a second lossless encode and the valid lossy comparison was experimentally idempotent for the first draft.

The destination sentinel in negative rewrite filename tests is not parsed as OpenEXR input; it exists only to establish the explicit validation-before-output rule. Negative rewrite streams begin with an empty caller-owned buffer and likewise observe no publication. Invalid `saveImages(OStream&)` calls are required only to throw; their post-failure bytes are deliberately unobserved. No assertion depends on the order in which invalid predicates are checked.

## Harness and architecture replay

The collision-safe hidden source remains `testMultipartImageIO_27b877.cpp`. The harness uses 13 stable CTest identities, offline execution, read-only participant source, a writable result volume, and UID/GID 10001. It has no product timeout or scheduler assertion. Native CTest JUnit remains authoritative; fallback XML is emitted only when setup fails before CTest and preserves the original nonzero status.

All five run-6 direct decoded architectures inject cleanly and remain accepted for every v8 requirement. None is contract-complete for the rewrite API, so they are not mislabeled as legitimate v9.1 failures. Repository `exrmultipart` and all four public copy-part families establish compressed structural transfer as supported behavior, while the reference demonstrates the hybrid transfer/encode composition. No materially different contract-complete v9.1 solver exists yet.

The external review's one unfair predicate was corrected: rejection of an invalid stream save no longer implies empty output. The exact 60-mutant replay confirms all seven stream-validation omissions are still rejected without that assertion. There are no progress markers, quiescence windows, sleeps, exact byte counts, call counts, seek order, temporary-path restrictions, error-message checks, network dependencies, privilege assumptions, or private layout predicates. Verdict: `pass`.
