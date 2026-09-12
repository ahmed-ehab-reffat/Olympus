# ERRORS - OpenEXR multipart high-level Image I/O

Permanent record of review findings, false positives, invalid assumptions, and
costly dead ends.

## 1. A temporary single-part bridge is legitimate

- Date: 2026-08-11
- Source: promotion architecture trial
- Severity: warning
- Verdict: valid

### Evidence

A 141-line disposable bridge used the existing four `copyPixels()` families
and singular high-level helpers to extract and reassemble a four-part file. It
preserved ordered heterogeneous flat/deep and tiled level behavior in the smoke
scenario.

### Resolution

Hidden tests may assert only public headers, decoded samples, order, validation,
and ownership. They must not constrain temporary files, direct frame-buffer
dispatch, output bytes, timing, helper names, or production file count.

### Durable lesson

High-level behavior can be reconstructed through lower-level public seams;
architecture freedom is part of fairness even when the reference uses a more
direct implementation.

## 2. Focused-only Docker build failed Phase A

- Date: 2026-08-11
- Source: exact environment gate
- Severity: blocker
- Verdict: resolved; run quarantined

The first final Dockerfile built only `OpenEXRUtilTest`. CTest discovered 127
tests, but 123 executables were absent and reported `Not Run`. The Dockerfile
now builds every configured target. The final untouched lane passes 127/127
offline under UID/GID 10001.

## 3. Harness wrote into a read-only participant tree

- Date: 2026-08-11
- Source: exact evaluator replay
- Severity: blocker
- Verdict: resolved; run quarantined

The first harness configured `build-evaluator` below `/workspace`, while the
evaluator correctly mounted participant source read-only. It produced no
JUnit. Build state now lives beside the requested result XML on the writable
result volume. Baseline/reference JUnit identity parity passes.

## 4. Subsampling must respect OpenEXR layout constraints

- Date: 2026-08-11
- Source: reference fixture replay
- Severity: blocker
- Verdict: resolved; run quarantined

A first HALF subsampling probe attached sampling 2x2 to tiled and odd-sized
multilevel images. OpenEXR correctly rejects subsampled tiled channels and
misaligned windows. The final probe is a valid aligned scanline part; tiled
parts use unit sampling. This is a fixture correction, not relaxed behavior.

## 5. Coverage required a final repository-state matrix

- Date: 2026-08-11
- Source: exact-version gap/false-positive audit
- Severity: important
- Verdict: resolved before immutable v1

Early tests paired flat ripmaps with deep mipmaps but did not independently
exercise the opposite family/mode branches, implicit tiling, one-level tiled
plural load, non-FLOAT channels, partial data-window intersection, or required
display/compression state. Public black-box probes were added for each distinct
branch. Every artifact revision restarted the environment gate; no pre-revision
result is counted in immutable v1.

## 6. Predictable hidden-test filename repeated a known packaging error

- Date: 2026-08-11
- Source: automated naming-collision review and prior local problem history
- Severity: important
- Verdict: corrected in revision v2; exact-version gates invalidated

### Evidence

The hidden source was named `testMultipartImageIO.cpp`, a path a participant could reasonably choose. This was not a new lesson: `problems/gimli-debug-names/DESIGN.md`, `SUMMARY.md`, and `PLAN.md` already record the same failure and require a random suffix generated with `openssl rand -hex 3`. The design startup review used prior behavioral evidence but failed to transfer that packaging constraint.

### Resolution

The requested command produced `27b877`, and the hidden source is now `testMultipartImageIO_27b877.cpp` everywhere in `test.patch`. The public description was also rewritten without manual mid-sentence line wrapping. No pipeline was run at the user's direction; all exact-version gate verdicts are therefore invalid for v2.

### Durable lesson

Prior-error review must cover harness and submission packaging failures as well as behavioral discriminators. Before freezing any hidden patch, compare every added test path against the predictable names a participant would naturally use.

## 7. Legacy header type synthesis was an unfair hidden expectation

- Date: 2026-08-11
- Source: `agent-runs1/Nova_Nova_1`
- Severity: test mismatch
- Verdict: corrected in immutable revision v3

### Evidence

The solver correctly inferred the part kind needed to decode a legacy
single-part file, then returned an independent copy of the source header. The
source created through the established singular helper had no `type`
attribute. `SinglePartLoad` nevertheless called `Header::type()` and required
the plural loader to invent that absent metadata. The public task requires
successful legacy decoding and copied header state, not header normalization.

### Resolution

The synthesized-type assertion was removed. The test still checks one-part
cardinality, decoded image class, all levels and samples, display window, and
custom attributes. The adjudicated solver patch is bound in
`ENVIRONMENT_REPLAYS.sha256` and now passes 4/4 baseline and 7/7 feature tests
under exact evaluator composition.

### Durable lesson

An implementation detail used for internal dispatch does not become a public
output invariant. A legitimate near-pass must be replayed after removing an
undocumented expectation, not counted as a failed solution.

## 8. Validation coverage conflated attribute presence with value and part zero with the collection

- Date: 2026-08-11
- Source: hardening review and repository `dataWindowForFile()` behavior
- Severity: important
- Verdict: corrected in immutable revision v3

### Evidence

The validation scenario rejected a header with no name attribute but never a
present name whose value was empty. It also used
`USE_HEADER_DATA_WINDOW` only with one-level images, leaving a shortcut that
validated the mode for the first part but accepted a later multiresolution
part. Both are distinct branches of public requirements already stated in the
description.

### Resolution

`ApiAndValidation` now rejects `header.setName("")` and a collection whose
first part is one-level but whose second part is mipmapped under
`USE_HEADER_DATA_WINDOW`. The probes assert only rejection. Their isolated
production mutants compile and fail the intended scenario, while the reference
and mandatory replay pass.

### Durable lesson

Collection validation must cross both value-state and per-element boundaries.
“Nonempty” is stronger than “present,” and per-image sibling behavior must be
checked on a later part rather than inferred from part zero.

## 9. Positive DataWindowSource coverage stopped at the flat family

- Date: 2026-08-11
- Source: exact-version gap review
- Severity: high
- Verdict: corrected in immutable revision v4

### Evidence

`HeaderAndCrop` proved successful `USE_HEADER_DATA_WINDOW` intersection only
for a flat tiled part. Deep parts were saved only with the default image window,
and the multiresolution probe established rejection rather than successful
deep cropping. An implementation could therefore preserve every existing
result while restoring `img.dataWindow()` only in its deep output branch.

### Resolution

The crop scenario now places a valid one-level deep scanline part after two
flat parts. It verifies the intersected deep header window, extracts the part
and compares deep sample counts and values, and reloads it through
`loadImages()`. The isolated `ignore_deep_data_window_source` mutant compiles
and fails only `HeaderAndCrop`; the reference and mandatory replay pass 7/7.

### Durable lesson

A generic public rule still needs family-specific positive coverage when the
repository has independently implemented flat and deep writers. A rejection
case for one lifecycle state does not prove successful behavior in another.

## 10. The move-only API check covered construction but not assignment

- Date: 2026-08-12
- Source: `agent-runs2` API-contract review
- Severity: medium
- Verdict: corrected in immutable revision v5

### Evidence

The build node required `ImagePart` to be noncopyable and move-constructible,
but did not check either assignment trait. A type with deleted move assignment,
or one that remained copy-assignable, could therefore pass the public API lane.
All five legitimate current-batch implementations explicitly delete copy
assignment and default move assignment.

### Resolution

The verifier now checks `is_copy_assignable` and `is_move_assignable` beside
the existing construction traits. Separate copy-enabled and move-deleted
production mutants compile the library and fail only their matching verifier
assertion. The reference, mandatory mismatch replay, and three clean current
replays pass 7/7.

### Durable lesson

For a public C++ value contract, construction and assignment are separate
lifecycle boundaries. A compile oracle should cover both without requiring one
special-member spelling.

## 11. Deep comparison dereferenced channel lookup before checking it

- Date: 2026-08-12
- Source: assertion-robustness review
- Severity: medium
- Verdict: corrected in immutable revision v5

### Evidence

`compareDeep()` used `findChannel("A")->channel()` and the corresponding `Z`
lookup directly. A missing channel was already incorrect public behavior, but
the verifier could crash or produce an opaque failure before identifying it.

### Resolution

Both actual and expected `A` and `Z` lookups are asserted non-null before
metadata or samples are read. The channel requirement and test fixtures are
unchanged; this is a safe failure-path repair rather than a new discriminator.

### Durable lesson

Behavioral comparison helpers should validate lookup preconditions before
dereferencing them, especially when a plausible implementation defect is the
absence of the object being compared.

## 12. A perfect review score was mistaken for difficulty evidence

- Date: 2026-08-13
- Source: `agent-runs3` calibration review
- Severity: high
- Verdict: corrected in immutable revision v6

### Evidence

All five new solvers passed the v5 compatibility and feature lanes. Their
implementations differed in helper structure but all bound the public API to
filenames and eagerly decoded every part. The auto-review score established
artifact quality, not discrimination or solve rate.

### Resolution

The redesign adds caller-owned `IStream`/`OStream` transport and exact named
part loading whose public semantics exclude decoding unselected pixel payloads.
A representative formerly passing solver now fails the new API build. The new
version starts at 0/10 rather than inheriting the old passes.

### Durable lesson

Review quality and calibration difficulty are separate claims. When all
solvers converge on one successful architecture, the next discriminator should
cross a repository-native architectural boundary rather than add more fixtures
inside that architecture.

## 13. The first selective-load oracle used the participant to prove damage

- Date: 2026-08-13
- Source: v6 fairness review
- Severity: medium
- Verdict: corrected before the v6 freeze

### Evidence

An early test draft required the participant's full plural loader to reject a
file after an unselected chunk was damaged. That assertion was not needed for
the selective contract and could reject a legitimate loader with different
error recovery behavior.

### Resolution

The test now locates and verifies a genuinely compressed chunk through
OpenEXRCore and uses the existing low-level extraction/load path to demonstrate
the damage. Participant-facing assertions only require valid selected parts to
load and missing names to be rejected.

### Durable lesson

A discriminator fixture should establish its own preconditions independently.
Do not turn a supporting fact into an extra behavioral requirement on the API
under test.

## 14. Selective-load wording prescribed an internal sequence

- Date: 2026-08-13
- Source: v7 description review
- Severity: medium
- Verdict: corrected in immutable revision v7

The prompt told participants to inspect headers and then decode the selected part. The actual contract is only that an unreadable unselected sibling does not prevent the valid requested part from loading. Revision v7 states that result directly and leaves header scanning, buffering, staging, and decoder organization open.

## 15. Harness setup failures could be masked by CTest

- Date: 2026-08-13
- Source: v7 harness review
- Severity: high
- Verdict: corrected in immutable revision v7

The harness did not make CMake configuration and base-target compilation terminal. A later CTest invocation could therefore hide the real evaluator failure. `test.sh` now uses `set -euo pipefail`. Controlled configuration and compilation failures both return nonzero before CTest, while the exact baseline and reference lanes still emit their expected JUnit.

## 16. A constructor-flag split was not an observable discriminator

- Date: 2026-08-13
- Source: `agent-runs4` recovery-boundary prototype
- Severity: warning
- Verdict: rejected before the v7 freeze

Some solvers disabled chunk-offset reconstruction for named loads and others kept the default. A trailing damaged-part prototype did not distinguish reference variants with reconstruction restored. The prototype and reference edit were removed. A solver-internal split is evidence for a probe only when it produces a distinct public behavior.

## 17. The filename suite did not exercise its UTF-8 qualifier

- Date: 2026-08-13
- Source: v8 contract-coverage review
- Severity: medium
- Verdict: corrected in immutable revision v8

### Evidence

The public API explicitly calls its filename input UTF-8, but every hidden and participant-side path used only ASCII bytes. All five `agent-runs5` implementations forwarded filename strings through the repository's existing constructors, and none of their tests challenged that boundary. The pinned repository independently uses `画像.exr` in `testExistingStreamsUTF8`, so non-ASCII success is supported repository behavior.

### Resolution

`Utf8Filename` saves distinguishable flat and deep parts to one valid mixed-script path, reopens the produced multipart file at that path, and exercises both complete and selective high-level loading. Three isolated mutants reject high-bit bytes in one filename wrapper apiece; the new node kills all three. The test does not impose normalization, locale, malformed-input, or transcoding requirements.

### Durable lesson

An encoding qualifier is not covered by an ASCII path. Cross each independently implemented filename direction with one repository-grounded non-ASCII success case, then stop before inventing a broader Unicode policy.

## 18. Immediate setup failure could omit the requested report

- Date: 2026-08-13
- Source: v8 harness-reporting review
- Severity: medium
- Verdict: corrected in immutable revision v8

### Evidence

Revision v7 correctly made CMake configuration and base compilation terminal, but `set -e` exited before CTest could write JUnit. The evaluator therefore returned the right failure status while sometimes omitting the output artifact required to explain it.

### Resolution

The harness captures each command's status, preserves native CTest XML when present, and writes one bounded, escaped error testcase only if no report exists. Forced configuration and base-build failures returned nonzero, produced parseable XML under existing lane identities, retained diagnostics, and never reached CTest.

### Durable lesson

Fail-fast execution and reliable reporting are separate harness properties. A pre-test failure should remain terminal while still producing the evaluator's requested diagnostic artifact.

## 19. Save validation was not covered across both transports

- Date: 2026-08-13
- Source: run-6 review
- Severity: medium
- Verdict: corrected in immutable revision v9

The `OStream` save overload was exercised only with an empty collection. Null images, missing and empty names, duplicates, unsupported image subclasses, and a later multiresolution part under header-window mode all used only the filename overload. `ApiAndValidation` now sends every rejection family through both overloads. Seven stream-only validation mutants are killed by the required exception; v9.1 deliberately does not inspect post-failure stream bytes.

## 20. The reference aborted on an unsupported multipart sibling

- Date: 2026-08-13
- Source: run-6 solution-quality review
- Severity: high
- Verdict: corrected in immutable revision v9

The public wording required supported parts to be returned in relative file order, but the reference decoder was called unconditionally and rejected the first unknown type. The reference now classifies types before decoding and uses tolerant header validation. `UnsupportedParts` places an unknown type between supported deep and tiled parts and crosses load-all, named load, and rewrite through filename and stream transports.

## 21. Thirty solutions passed because the task stayed inside one architecture

- Date: 2026-08-13
- Source: trajectory-informed v9 redesign
- Severity: high
- Verdict: corrected in immutable revision v9; fresh difficulty still uncalibrated

All six solver batches converged on decoded collection dispatch. Repeated fixture additions hardened correctness but did not force another design. Revision v9 adds selective rewrite, which must encode named high-level replacements while structurally preserving untouched parts, including unreadable data. The repository supports both ingredients independently, but none of the thirty historical solutions composed them. This is a real architecture change; it is not yet a measured solve rate.

## 22. Initial v9 coverage still had overload and exact-name gaps

- Date: 2026-08-13
- Source: exact gap and false-positive audit
- Severity: medium
- Verdict: corrected before the v9 freeze

The first v9 draft checked most invalid replacements only through streams, did not distinguish `target` from `TARGET`, and relied on old APIs for UTF-8 and positive crop behavior. The final suite applies every invalid replacement to both destinations, adds exact case-fold rejection, exercises both mixed-script rewrite filenames, positively crops a deep replacement through both overloads, and crosses unknown siblings through every stream operation. A case-folded matcher that initially survived is now killed.

## 23. Platform replay patches contained generated build files

- Date: 2026-08-13
- Source: revision v9 environment gate
- Severity: environment blocker
- Verdict: quarantined and corrected; no solver outcome assigned

The first compatibility replay failed patch application because the platform patch contained tracked `build-bootstrap` output absent from the exact clean pin. The batch stopped before behavioral checks and restarted from zero. Source-only participant patches under `verify/replays-v9/` now apply cleanly and are used only as injection checks, since none implements the v9 API.

## 24. Invalid stream-save rejection was strengthened into atomicity

- Date: 2026-08-13
- Source: external fairness review
- Severity: unfair test
- Verdict: corrected in immutable revision v9.1

The public contract requires invalid `saveImages()` collections to be
rejected, but it states pre-mutation output behavior only for
`rewriteImages()`. The hidden helper additionally required every invalid
`OStream` save to leave its memory destination empty. No neighboring
OpenEXRUtil stream writer establishes that transactional rule, and historical
solver convergence on eager validation cannot create public provenance.

Revision v9.1 removes the byte assertion and retains exception coverage for
all seven validation families through both overloads. The exact mutation rerun
still kills all seven stream-only omissions, all 59 behaviorally incorrect
mutants are killed overall, and the equivalent survivor passes 127/127
pre-existing tests. Rewrite destination preservation remains tested because it
is explicitly public.

## 25. Replacement pixels passed while replacement header state could disappear

- Date: 2026-08-14
- Source: run-8 test-quality review
- Severity: high
- Verdict: corrected in immutable revision v12

`RewriteParts` compared complete headers for untouched parts but checked only
the family and payload of a replacement. A rewrite-only path could therefore
reconstruct a minimal header and still pass, despite the public requirement to
encode replacements as `saveImages()` would.

The final test saves the same replacement through `saveImages()`, reloads its
complete emitted header, and compares both rewrite results with that public
oracle. A production mutant that removes replacement comments only in rewrite
is killed. Both legitimate run-8 implementations continue to pass.

## 26. Two provisional v12 fixtures were invalid

- Date: 2026-08-14
- Source: exact environment gate
- Severity: environment blocker
- Verdict: quarantined and corrected; no outcome counted

The first edited patch had a stale new-file hunk count and was stopped at
composition. A later fixture gave the replacement a different multipart-shared
pixel aspect ratio, which OpenEXR correctly rejected before the intended
fidelity assertion. The hunk count was repaired and the conflicting shared
attribute was removed. All exact gates restarted from zero for the final
artifact hashes.

## 27. Rewrite rejection did not prove destination preservation

- Date: 2026-08-14
- Source: revision v13 validation review
- Severity: high
- Verdict: corrected in immutable revision v13

The identical-filename case asserted only an exception, so truncating the
source and failing later could pass. The reference also allowed a disjoint
replacement header/image intersection into its rewrite plan, opened a distinct
destination, and failed only during output setup. Both violated the public
requirement that invalid rewrites be rejected before destination modification.

`RewriteValidation` now snapshots and rechecks the identical-path source. It
also sends a disjoint one-level replacement through the existing filename and
stream sentinel helper. The reference rejects an empty intersection while
preparing the plan, before either writer opens. Isolated mutants that remove
the filename guard or the precheck compile and fail this node.

## 28. Grouping mipmap and ripmap hid an enum-specific shortcut

- Date: 2026-08-14
- Source: revision v13 gap review
- Severity: medium
- Verdict: corrected in immutable revision v13

The public windowed API is restricted to `ONE_LEVEL`, but the suite selected
only a mipmap. Treating mipmap and ripmap as one covered cell overlooked an
implementation that checks exactly `MIPMAP_LEVELS` and accepts
`RIPMAP_LEVELS`.

`WindowedLoad` now creates a valid ripmap sibling and requires rejection
through both filename and stream overloads. The targeted enum-specific mutant
is killed. The test still defines no multiresolution crop behavior; it observes
only the stated API domain.

## 29. Rewrite success exercised only one replacement

- Date: 2026-08-14
- Source: revision v14 coverage review
- Severity: medium
- Verdict: corrected in immutable revision v14

The suite thoroughly validated replacement collections but passed only one
replacement to every successful rewrite. Validation and publication are
separate loops in the reference and reviewed solver architectures, so an
implementation could validate all entries and publish only the first match.

`RewriteParts` now supplies two distinct matching replacements in one call
through both transports and verifies both headers against `saveImages()` plus
both decoded payloads. The existing untouched lossy and deep parts remain in
the fixture. A production mutant that dynamically publishes only the first
matching plan entry is killed by this node.

## 30. The single-part header oracle repeated an earlier normalization error

- Date: 2026-08-14
- Source: revision v14 solution-quality review
- Severity: high
- Verdict: corrected in immutable revision v14

The source was produced by `saveImage()` without a `type` attribute, but the
test read its expected header through `MultiPartInputFile`. The pinned
constructor auto-adds a type for legacy dispatch, so the oracle normalized away
the absence it was meant to preserve. The reference made the same mistake when
building an untouched rewrite plan. This repeated the durable lesson from the
revision-v3 synthesized-type mismatch: a dispatch view is not automatically an
exact output-header oracle.

`SinglePartLoad` now reads the exact source and rewritten headers through
`TiledInputFile`, requires `type` to remain absent through filename and stream
rewrites, and retains decoded image comparisons. The reference validates its
multipart plan, then copies a typeless flat single-part source through the
matching singular reader/writer. The normalized-header mutant is killed, while
an independent run-8 implementation still passes 14/14.

## 31. The corrected rewrite fixture still over-specified the load result

- Date: 2026-08-14
- Source: external fairness review
- Severity: unfair test
- Verdict: corrected in immutable revision v15

Revision v14 correctly used `TiledInputFile` as the exact oracle for the
serialized untouched rewrite, but also required `loadImages()` to return the
type-bearing header synthesized by `MultiPartInputFile`. The prompt never
chooses that normalization, and the existing singular high-level path returns
the raw typeless header. A legitimate historical solver used the latter form.

`SinglePartLoad` now erases only `type` from local returned and expected header
copies before comparing all remaining public state. Exact typeless source and
rewrite-output assertions remain unchanged. Raw and synthesized return-header
architectures both pass 14/14, while the serialized normalization mutant is
still killed.

## 32. A provisional v15 new-file hunk count was stale

- Date: 2026-08-14
- Source: exact environment gate
- Severity: environment blocker
- Verdict: quarantined and corrected; no outcome counted

The first v15 patch declared one fewer added line than its hidden source
contained, truncating the closing brace during evaluator composition. The gate
stopped immediately, repaired the hunk metadata, and restarted all exact checks
for the final artifact hash. The final declared and actual counts are both
2,222.

## 33. A legacy raw-copy fast path ignored a matched replacement

- Date: 2026-08-14
- Source: external solution-quality review
- Severity: correctness gap
- Verdict: corrected in immutable revision v16

The revision-v15 reference built a valid matching rewrite plan for a named,
typeless ordinary flat single-part source, then unconditionally copied that
source because it was flat, singular, and typeless. Both transports therefore
ignored the replacement even though the focused suite passed.

The raw-copy path is now limited to an untouched plan slot. `SinglePartLoad`
creates the source with the existing `saveImage()` helper, self-checks its exact
header, and applies a matching replacement through filename and stream paths.
Both outputs must match the complete header produced by `saveImages()` and the
replacement payload. The isolated old behavior is killed.

## 34. Provisional v16 audit batches were not immutable

- Date: 2026-08-14
- Source: environment and mutation gates
- Severity: environment blocker
- Verdict: quarantined; exact gates restarted

One mutation attempt referenced a temporary image after the environment gate
removed it. A second used an unconfigured result root. A third exposed a stale
mutation pattern after the reference condition changed. After those issues
were corrected, formatting changed the test artifact and invalidated the first
complete behavioral result.

No outcome from those batches is counted. The final environment, mutation,
survivor, and historical replay gates all restarted from clean compositions for
the immutable v16 hashes.

## 35. Replacement matching did not cross unsupported source eligibility

- Date: 2026-08-14
- Source: external test-coverage review
- Severity: coverage gap
- Verdict: corrected in immutable revision v17

`RewriteValidation` rejected an absent replacement name, while
`UnsupportedParts` proved that unsupported source siblings are skipped. The
suite did not combine those states. An implementation could therefore mark a
replacement as matched by any source header name and only afterward skip the
unsupported part.

The new fixture gives an unsupported source part a distinct exact name and
uses that name as the sole replacement. Filename and stream rewrites must
reject before changing their destinations. The targeted match-before-filter
mutant is killed, while the reference and all four run-8 replay architectures
pass the new assertion.

## 36. The first v17 mutation batch lacked its configured build root

- Date: 2026-08-14
- Source: exact false-positive audit
- Severity: environment blocker
- Verdict: quarantined; no outcome counted

The mutation script expects the exact reference build to initialize its
writable result root. The first invocation skipped that prerequisite, so every
variant reported `build-evaluator is not a directory`. The batch was stopped
and quarantined. After a clean 14/14 reference initialization, the complete
76-variant audit was rerun and produced valid compile and behavioral outcomes.
