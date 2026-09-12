# DESIGN - Calamine structured defined names

Status: **accepted on 2026-08-01**. Level 1 was abandoned at 9/10 passes,
Level 2 stopped after 5/5 passes, and the later Level 3 package is canonical.

Repository: `tafia/calamine`

Pinned commit: `0a24c2a9f1e38c0932c1299e633270dc730db505`

Task type: `enhancement`

This problem began as an explicit size experiment. Level 1 deliberately kept
the 128-line reference below the 200-line target and measured solver behavior
instead of padding the task. After level 1 solved 9/10 and level 2 solved its
first 5/5, level 3 broadens the same defined-name feature with native comment,
publication, and workbook-parameter metadata. The complete level-3 reference
is 241 strict effective production additions, so it now clears the minimum on
its own while retaining one coherent feature boundary.

The first exact problem version passed every patch-state check and its mandatory
false-positive audit, then calibrated at 9 legitimate passes out of 10. Its
successful patches had a median platform-reported sandbox LOC of 284, while
their raw production additions had a median of 153. Level 2 added exact trait
dispatch and compatibility probes, but all five working-pool runs solved it.
Both earlier levels are abandoned as calibration versions and retained only as
trajectory evidence.

## Frozen public contract

Calamine currently exposes defined names only as `(String, String)` tuples.
The task adds crate-root `DefinedName` and `DefinedNameScope` types, both with
`Debug`, `PartialEq`, and `Clone`, plus a
`Reader::defined_names_metadata()` slice
accessor across XLS, XLSX, XLSB, and ODS.

`Worksheet(usize)` is a zero-based index into `sheets_metadata()`. Scope comes
from the name's owner, never from a sheet referenced by its formula. Excel
formats expose hidden, built-in, publish, and workbook-parameter state as
`Some(bool)`. They expose native comments as `Some(String)`, preserving an
explicit empty string, or `None` when no comment is present. ODS uses `None`
for all five properties because ODF has no equivalent metadata. Records
preserve source order, duplicate spellings, and current format-specific formula
strings.

The existing Excel `Reader::defined_names()` tuple view and XLS/XLSB
formula-token name resolution remain behaviorally unchanged. ODS structured
metadata includes worksheet-local names; the task makes no new promise about
whether the legacy tuple view remains workbook-only or projects every metadata
record. Empty readers return an empty slice, and ordinary worksheet reads do
not change metadata content or order. The bounded contract excludes formula
evaluation or normalization, writing or mutation, validation, ODF base-address
modeling, macro/function flags, and normalized built-in kinds.

## Trajectory-informed startup gate

The gate was completed before the test patch was authored. Searches covered:

- `problems/README.md`, candidate registries, success records, and dated audits
  for Calamine, spreadsheets, cross-format parsing, defined names, scope,
  formula compatibility, and format round trips;
- the compact records for `moov-ach`, `statig-local-transitions`,
  `pydicom-fileset-replace`, `str0m-remote-renegotiation`, `noodles-md`,
  `go-mp4-sample-locations`, `3d-tiles-atomic-output`, and the Calyx checkpoint
  investigation;
- `archive/moov-ach/MANIFEST.md` and the raw trajectory, evaluation, and
  solution-patch records for runs 5, 10, and 12; and
- the pinned Calamine source, existing tests, all local repository history,
  and the complete upstream issue/PR history.

No Calamine solver trajectory or earlier spreadsheet defined-name problem
exists locally. The moov evidence is analogical evidence about solver
shortcuts across multiple independent format representations; it does not
define spreadsheet semantics.

| Evidence | Outcome | Generalized solver behavior used in this design |
|---|---|---|
| moov ACH run 5 | complete pass | A solver can absorb a second representation into one correct forward pipeline, so merely naming four formats is not a discriminator. |
| moov ACH run 10 | near-pass | A shared architecture can miss one representation-specific control invariant, motivating independent owner/flag semantics for each public reader. |
| moov ACH run 12 | broad focused failure with baseline pass | Preserving the obvious output can leave coupled state wrong, motivating explicit compatibility checks for legacy tuples and internal formula consumers. |
| pydicom fileset replacement | rejected at 72 strict lines | A coherent lifecycle contract may still compile into a small patch; cheapest-complete size must be measured rather than inferred from prose. |
| str0m renegotiation | 10/10 at 97-147 lines | Solvers can converge on the same compact architecture, so reference size is a real risk even when behavior is valid. |

Repository evidence establishes four genuinely different parser boundaries:
OOXML attributes, BIFF `Lbl` flags and one-based ownership, BIFF12 `BrtName`
flags and sentinel ownership, and ODF placement-based scope. It also establishes
that XLS and XLSB formulas consume the existing tuple vector by numeric name
index.

## Discriminator ledger

| Shortcut or architecture risk | Public invariant | Strongest black-box oracle | Distinct boundary |
|---|---|---|---|
| Implement only the easiest XML format or default every other format | Every supported reader exposes the same public record meaning, with honest absence where the format lacks a property | Equivalent static XLS, XLSX, XLSB, and ODS workbooks produce exact format-derived records | Independent format readers |
| Infer owner scope from a formula reference | Owning scope and referenced sheets are independent | Local names whose formulas refer elsewhere retain their encoded local owner | Scope versus formula identity |
| Store names in a map keyed only by spelling | Same-spelled names in different scopes remain distinct and ordered | Exact cardinality, source order, and scope for global and local shadows | Multiplicity and order |
| Infer built-in state from spelling in every format | Built-in state follows the source format's actual semantics | Binary built-in flag differs from a user-spelled `_xlnm` name; ODS reports absence | Format-native flags |
| Replace tuple storage without tracing its consumers | Existing public tuples and indexed formula rendering remain unchanged | Legacy projection in XLS, XLSX, and XLSB plus formula cells in formats with indexed name tokens | Compatibility and internal consumer |
| Expand the task to manufacture 200 lines | Only the frozen metadata contract is required | Clause-to-test ledger contains no evaluation, writing, normalization, or unrelated flags | Anti-padding boundary |

Any parser organization, storage strategy, or helper decomposition may pass.
Tests observe only public reader behavior and compatibility. They do not
require the reference implementation's private `Metadata` layout.

### Review-triggered gate update

The 2026-07-30 wrapper review was evaluated against the existing trajectory
gate before revising the hidden tests. The prior raw solver evidence and parser
discriminator ledger remain applicable. Additional searches covered the
unclassified-entity records in `statig-local-transitions`, `moov-ach`, and
`railway-deployment-bundle`, plus direct reproduction in the official Calamine
image.

Two issues were confirmed. First, nextest stores its JUnit report under the
repository's `target/nextest` tree even when `CARGO_TARGET_DIR` points at the
warmed image target. The runner searched only the latter, so both modes
exported synthetic failures while the real 205 baseline entities remained
unclassified. The revised runner searches and clears both stores, exports the
real per-test report when available, and marks the no-report compilation
placeholder skipped while preserving the failing process status.

Second, the ODS legacy-projection assertion was not supported by the public
contract or pinned behavior. The existing tuple API sees top-level ODS names,
whereas the new metadata API must additionally discover table-local names.
That assertion is removed rather than promoted into the description. The
reference keeps the old tuple projection workbook-only, but hidden tests do
not require one private storage strategy.

### Level 2 trajectory gate

The complete first calibration batch is stored under `agent-runs1`. Searches
also rechecked the local Calamine candidate records, the problem registries,
the earlier moov analogues, and the Statig false-positive worked example.
Every run's evaluation, solution patch, test log, and raw trajectory was
inspected. The raw trajectory review used the shortest legitimate pass as the
representative pass and the sole failing run as the near-pass. There is no broad
failure in this batch.

| Evidence role | Run | Outcome | Architecture, checks, and decisive behavior |
|---|---|---|---|
| Legitimate pass | `Nova_Nova_4` | 205/205 baseline and 5/5 focused; 210 sandbox LOC | The solver mapped all four parser seams, added owned shared metadata, retained the tuple vector for Excel consumers, parsed ODS locals while walking tables, added format-specific regression tests, and ran the all-feature suite. Its ODS tuple projection included local names, which is a defensible reading not prohibited by the level-1 prompt. |
| Additional legitimate range | `Nova_Nova_1` through `Nova_Nova_8`, plus `Nova_Nova_10` | Nine total legitimate passes; platform sandbox LOC 210-415, median 284; raw production additions median 153 | All successful patches implemented the real format parsers rather than stubbing the API. They converged on the same small architecture: one shared owned vector, native owner/flag extraction in each reader, and ODS table-local collection. Tests and full-suite checks were common proactive steps. |
| Near-pass | `Nova_Nova_9` | 205/205 baseline and 4/5 focused; 307 sandbox LOC | The solver completed every format but decoded the XLSB `itab` from bytes 4-7 instead of 5-8. The key byte shifted worksheet owner 2 to 512. The existing nonzero XLSB owner assertion isolates this mistake. |
| Broad failure | unavailable | none of the ten runs failed broadly | No unrelated run was substituted. The absence of a broad failure means level 2 cannot justify widening the task beyond the existing public behavior. |

The batch demonstrates that the task is genuinely multi-file and naturally
exceeds the 200-LOC median target for successful solvers, but its semantics are
straightforward for Nova: nine runs independently reached complete parser
integration. Tightening must therefore close interface or compatibility false
positives still permitted by the verifier, not manufacture new spreadsheet
features or reject the nine correct implementations.

Two level-2 discriminators follow from the runs and the autoreview dispute:

| Observed behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfitting rationale |
|---|---|---|---|---|---|
| Every solver correctly edited `Reader`, but the focused suite called the accessor only on the `Sheets` auto-dispatch enum. | Add an inherent method only to the tested wrapper or return a collection type that merely supports the observed calls. | The method belongs to the public `Reader` trait and returns exactly `&[DefinedName]` for each concrete reader implementation. | A generic helper with `R: Reader` assigns the result to `&[DefinedName]`, and the four format tests open concrete `Xls`, `Xlsx`, `Xlsb`, and `Ods` readers. | Public trait dispatch versus wrapper dispatch | This is an exact participant-facing interface requirement. It accepts any storage architecture and does not depend on parser internals. |
| A correct passing implementation exposed ODS locals through `defined_names()`, while the reference preserved the pinned workbook-only result; autoreview treated the difference as a missing assertion. | Accidentally build an incoherent ODS tuple view containing a partial or reordered subset while still returning correct structured metadata. | ODS legacy tuples may follow either defensible policy, but must be one complete ordered projection: workbook-scoped metadata only, or all metadata. | Compare the tuple slice with both exact projections and accept either complete form. | Legacy compatibility policy versus new authoritative metadata | The oracle explicitly preserves the observed legitimate solver and the reference. It rejects arbitrary partial projections without elevating one undocumented policy over the other. |

The existing XLSB nonzero-owner test already kills the only observed failure.
Equivalent OOXML boolean spelling, reversed ODS container order, additional
BIFF flag combinations, and more copies of the same four-format fixture remain
rejected: they are symmetry or breadth additions, not new failure families
supported by this batch.

### Level 3 trajectory gate

The second calibration batch is stored under `agent-runs2`. It contains five
completed Nova runs against the exact level-2 artifact. Every compact
evaluation, solution patch, test log, and raw trajectory was inspected. The
search also rechecked the Calamine candidate records, both earlier run batches,
the local problem registries, and the Statig false-positive worked example.

All five runs are legitimate passes. The then-current calibration protocol
therefore stopped level 2 at its fifth solve because its maximum accepted
result was four solves in ten. The later 50% policy would permit five solves,
but this abandoned artifact remains historical evidence. There is no
near-pass or broad failure in this batch, and no unrelated run is substituted
for either missing category.

| Evidence role | Run | Outcome | Architecture, checks, and decisive behavior |
|---|---|---|---|
| Shortest legitimate pass | `Nova_Nova_2` | 205/205 baseline and 5/5 focused; 216 sandbox LOC; 48 trajectory steps | The solver located the shared `Metadata` seam and all four parsers, checked the binary layouts, added one owned vector, projected legacy tuples, and validated the full all-feature suite. It populated exactly the five public fields at the point each name is parsed. |
| Independent legitimate pass | `Nova_Nova_5` | 205/205 baseline and 5/5 focused; 381 sandbox LOC; 81 trajectory steps | This solver used the same production architecture but independently added parser helpers and in-memory format tests. Its temporary fixture failures exposed string-encoding and ODS-container assumptions, which it corrected before the complete suite passed. |
| Remaining legitimate range | `Nova_Nova_1`, `Nova_Nova_3`, and `Nova_Nova_4` | Three more complete passes; sandbox LOC 254-374 | Every implementation touched the same five production files, preserved indexed formula consumers, and added ordinary regression tests. None used a wrapper-only shortcut or a partial ODS projection. |
| Near-pass | unavailable | no level-2 run failed a focused test | The level-1 XLSB offset failure remains useful replay evidence but is not relabeled as a level-2 near-pass. |
| Broad failure | unavailable | no level-2 run failed broadly | The absence is recorded directly. |

The five successful solutions show that more assertions over the existing
scope/hidden/built-in fields will not materially change difficulty. The next
level therefore broadens the same public metadata feature with three native,
cross-format properties rather than adding formula evaluation or an unrelated
API:

- an optional comment, preserving the distinction between absent and present
  empty strings;
- the Excel publish flag; and
- the Excel workbook-parameter flag.

XLSX stores these as `definedName` attributes. BIFF8 stores a comment in a
separate `NameCmt` record associated with the preceding `Lbl`, with publish and
workbook-parameter bits at 13 and 14. BIFF12 stores the comment as a trailing
`XLNullableWideString`, with the two flags at bits 15 and 16. ODF has no
equivalent properties, so ODS reports absence. These are documented native
defined-name semantics, not padding: they add record correlation,
variable-length decoding, distinct bit layouts, and an unsupported-format
boundary to the existing feature.

The autoreview observation about empty metadata is also actionable. Every
level-2 interface call used a workbook with names, and the helper explicitly
asserted non-emptiness. Empty workbooks are common repository fixtures and a
public slice accessor must return an empty slice without inventing a record or
failing dispatch.

#### Level 3 discriminator ledger

| Observed behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfitting rationale |
|---|---|---|---|---|---|
| All level-2 interface checks require at least one record, and autoreview identified the uncovered zero-cardinality case. | Seed shared metadata with a placeholder, retain stale records, or special-case the tested non-empty fixtures. | A reader with no defined names returns an empty metadata slice through both its concrete `Reader` implementation and automatic dispatch. | Open existing no-name XLS, XLSX, XLSB, and ODS workbooks through concrete readers and `Sheets`; require exact empty slices and matching legacy emptiness. | Zero cardinality and initialization | This uses ordinary upstream fixtures and one categorical boundary, not four new semantic variants. |
| Every level-2 solver constructs a record only while parsing the primary name element or record. | Support the easy OOXML comment attribute but ignore comments that live after the primary binary record. | Comments are decoded from each format's native storage; absent, empty, and non-empty values remain distinct. | One fixture per native representation checks an escaped OOXML attribute, a BIFF8 `NameCmt` associated with its `Lbl`, a BIFF12 trailing nullable string, and ODS absence. | Attribute parsing versus record correlation versus trailing variable data | The formats require genuinely different data flow. The probes compare only public records and accept any storage architecture. |
| Existing binary work reads only flag bits 0 and 5, which happen to align in XLS and XLSB. | Reuse one mask for all new flags or default every newly added property to false. | Publish and workbook-parameter values follow each format's native bit or attribute layout; ODS reports absence. | Independent true/false combinations use OOXML attributes, BIFF bits 13/14, and BIFF12 bits 15/16. | Non-aligned flag layouts and unsupported properties | Two properties share one fixture matrix but exercise a new high-bit boundary that the current low-bit checks cannot detect. |
| Existing fixtures prove non-empty values at open time only. | Populate a side collection inconsistently with the authoritative metadata or lose it after worksheet access. | The borrowed metadata slice is stable for the reader lifetime and remains the source-order record view after ordinary worksheet reads. | Compare complete records before and after a representative formula/range read while retaining the legacy projection checks. | Reader lifecycle and shared storage | This is a public accessor invariant and reuses the same workbooks; it does not prescribe `Metadata` as the storage location. |

Level 3 is a new problem contract, not a verifier-only trap. The prompt,
reference solution, tests, fixture record, and false-positive audit change
together. Its reference preserves the pinned workbook-scoped ODS behavior,
while the reconciled verifier also accepts a complete all-record projection.
All level-1 and level-2 calibration results become trajectory evidence only,
and level 3 starts at 0/10 after exact-version verification.

### Review-triggered interface and specification gate

The post-level-3 review was evaluated against the same `agent-runs2` evidence
before revising the test patch. Searches rechecked both Calamine run bundles,
the local problem and candidate registries, the pinned public types surrounding
`Reader`, and the raw trajectories for the shortest and independent level-2
passes.

All five level-2 solutions derived `Clone` for both new types even though the
level-2 prompt named only `Debug` and `PartialEq`. That convergence makes
`Clone` a natural Rust API choice, but it does not make an unstated trait bound
fair. The level-3 lifecycle test calls `to_vec()` on the borrowed slice, so the
public contract now explicitly requires `Clone` for `DefinedName` and
`DefinedNameScope`. A generic compile-time helper independently requires
`Debug + PartialEq + Clone` for each type; this prevents a custom
`DefinedName::eq` implementation from masking missing traits on the scope enum.

The raw trajectories for `Nova_Nova_2` and `Nova_Nova_5` show that both solvers
paused to confirm binary owner and flag layouts before editing. One otherwise
complete level-1 solver decoded the XLSB owner one byte early, which proves that
the skipped bytes are a real opaque boundary rather than an ordinary repository
convention. A later Criterion 04 review correctly found that requiring exact
binary comments, high flags, and owner semantics while directing participants
to external specifications was unfair. The public prompt therefore gives a
compact interoperable field map for XLSX, BIFF `Lbl`/`NameCmt`, and BIFF12
`BrtName`. It identifies record fields, indexes, masks, string encodings, and
the nullable-comment sentinel without prescribing parser helpers or storage.

The same fairness review found the ODS legacy policy ambiguous. A legitimate
level-1 implementation exposed worksheet-local names through
`defined_names()`, while the pinned implementation and level-3 oracle retain a
workbook-only tuple view. Because the strict level-3 test selects one of those
two defensible interpretations, the public prompt now states that selection
explicitly. It also states the all-record projection used by the three Excel
readers. The oracle remains a black-box compatibility check and does not
constrain how either metadata view is stored.

| Review finding | Generalized false positive | Fair invariant and oracle | Distinct boundary | Decision |
|---|---|---|---|---|
| `to_vec()` imposed an unstated `Clone` bound | Implement exactly the written traits and fail only in hidden-test compilation | State `Clone` publicly and compile a generic `Debug + PartialEq + Clone` assertion for both exported types | Public Rust interface | Prompt and test updated |
| `DefinedName` could implement custom equality without comparable/debuggable scope | Hide a deficient scope enum behind record-level trait implementations | Require the trait bounds directly on `DefinedNameScope` | Nested public type interface | Test updated |
| Binary mappings require external format research and include bytes skipped by the pinned parsers | Correctly implement XML readers but omit or misalign opaque binary metadata | Publish the minimum record-field, flag, indexing, and string-layout map needed to derive the same observable metadata while allowing any parser strategy | Cross-format public behavior and opaque binary layout | Compact implementation map added to the prompt; black-box assertions unchanged |
| The strict ODS oracle selects workbook-only legacy projection from two defensible readings | Expose correct structured metadata but fail only because local ODS names leak into the legacy accessor | State the selected legacy projections for ODS and the three Excel readers, then check exact black-box output | Existing public API compatibility | Compatibility expectation added to the prompt; behavior unchanged |

### Description-concision review gate

The next HIGH-severity description review requested the opposite public-prose
decision: remove both binary layout blocks, the legacy projection paragraph,
and the empty/lifecycle paragraph because it classifies them as
repository-discoverable implementation detail or ordinary compatibility
defaults. Before accepting that revision, the local history search was repeated
across both Calamine run bundles, their raw trajectories and evaluations, the
current parser seams, and the prior false-positive records.

All five level-2 passes independently found the relevant parser seams, and the
existing code already frames `Lbl`, `NameCmt`, and `BrtName` records closely
enough for a solver to extend them. The counterevidence remains material:
`Nova_Nova_9` misaligned the XLSB owner by one byte, and an otherwise legitimate
level-1 implementation expanded the ODS legacy tuple view. The new review
nevertheless explicitly treats both behaviors as discoverable defaults. The
description is therefore shortened as requested without changing any oracle,
fixture, runner, or reference behavior. The earlier Criterion 04 concern is
retained as an open review risk rather than silently declared resolved.

| Review request | Repository and trajectory evidence | Public-contract decision | Oracle decision |
|---|---|---|---|
| Remove the XLS and XLSB byte-layout maps | Existing parsers expose the record framing and every complete level-2 solver found the extension points; one near-pass still misaligned `itab` | Remove both low-level bullets and retain only observable cross-format field semantics | Keep the existing complete-record black-box checks |
| Remove explicit legacy projection prose | The pinned accessor is workbook-only for ODS, but one earlier solver expanded it while adding local metadata | Treat preservation of the existing accessor as an ordinary repository compatibility default | Keep the strict pinned-behavior regression assertion |
| Remove empty and lifecycle prose | Empty slices and immutable borrowed reader metadata are conventional accessor behavior | Remove both sentences from the public description | Keep the zero-cardinality and post-read regression probes |
| Reduce description below 500 words | The API and observable metadata semantics remain complete without implementation walkthroughs | Target a compact description with renderer-managed paragraph wrapping | No behavioral change |

### Criterion 04 fairness restoration gate

The subsequent Criterion 04 result confirms that the concise version crossed
the fairness boundary: the hidden suite still selects one legacy ODS policy and
requires metadata stored in binary fields that the pinned parsers currently
skip. The user selected the guidance-first remedy rather than weakening those
cross-format discriminators.

The same representative evidence was replayed before revising the prompt.
`Nova_Nova_2` and `Nova_Nova_5` found and extended all native parser seams, so a
compact record-level map is sufficient; no reference architecture needs to be
published. `Nova_Nova_9` read the XLSB worksheet owner from byte 4 instead of
byte 5, demonstrating the one non-obvious framing boundary worth naming. The
earlier ODS implementation that projected local names into `defined_names()`
demonstrates that generic “preserve behavior” language does not select the
strict hidden oracle.

| Evidence-backed ambiguity | Fair public guidance | Existing black-box oracle | Anti-overfitting decision |
|---|---|---|---|
| XLS metadata is split between `Lbl` and `NameCmt`, with format-specific high flags | Name the two records, owner indexing, flag bits, and option-byte comment strings | Exact BIFF5/8 metadata records | Publish semantic field sources, not every byte offset |
| XLSB has a one-byte field before `itab`, distinct high flag bits, and a trailing nullable comment | Name `BrtName`, byte 5 for `itab`, the sentinel/index rule, flag bits, and trailing nullable string location | Exact BIFF12 metadata records | Publish the observed framing trap without prescribing helpers or storage |
| ODS local metadata can reasonably leak into the legacy tuple vector | State the selected tuple projection for each reader family | Strict ordered legacy projections | Make the hidden compatibility policy explicit |
| Empty and post-read behavior are conventional borrowed-accessor regressions | No additional prompt prose | Empty and lifecycle probes | Keep them as regressions; do not re-expand the description |

The restored guidance must remain below the 500-word description target and
must use renderer-managed wrapping. `test.patch`, fixtures, and
`solution.patch` remain unchanged because the revision exposes existing
oracles rather than adding behavior.

### High-level guidance reconciliation gate

The next HIGH-severity review disallows the restored byte offsets, bit numbers,
nullable sentinel, and explicit legacy projection prose. Because the user
cannot contest that review, this revision resolves fairness through two
different mechanisms instead of silently returning to the 207-word version.

First, the public description keeps a source-level format matrix. It tells
participants which native element or record owns scope, flags, and comments:
XLSX `definedName` attributes, XLS `Lbl` plus its associated `NameCmt`, and XLSB
`BrtName`. This removes reference-oriented byte parsing instructions while
still exposing that binary comments require record correlation or trailing
metadata rather than formula inference. The observable boolean, nullability,
scope, and ordering semantics remain stated in the main contract.

Second, removing the legacy paragraph makes the strict ODS projection
indefensible as a new hidden requirement. Repository evidence and the
level-1/2 trajectories support two coherent implementations: retain the pinned
workbook-only tuple view, or project every newly parsed ODS metadata record.
The hidden assertion will again accept either complete encounter-ordered
projection and reject only partial or reordered tuple views. Excel projection
checks remain ordinary regressions because their structured and tuple records
come from the same existing parser stream.

| Review constraint | Plausible implementation mode | Revised fair oracle | Distinct discriminator retained |
|---|---|---|---|
| No XLS/XLSB offsets, masks, or string-layout prose | Extend the named native record using any correct format-decoding strategy | Exact public metadata records for each binary reader | Separate record correlation, trailing metadata, and format-native flags |
| No explicit legacy-accessor paragraph | Either preserve workbook-only ODS tuples or project all newly discovered names | Accept either complete ordered ODS projection; reject partial/reordered views | Coherent compatibility projection without selecting an unstated policy |
| Keep the description below 500 words | Follow the source matrix and observable semantics without a parser walkthrough | Static word-count and renderer-wrap check | Concision without hiding the location of native metadata |

This test revision changes the accepted behavior, so the prior strict-ODS M25
mutation is retired and the exact-version false-positive audit must be repeated.
All earlier calibration remains historical evidence, and the revised package
starts at 0/10.

### Run-3 fixture-hardening gate

The first two runs against the high-level-guidance version are stored under
`agent-runs3`. Both are legitimate near-passes: each passed all 205 baseline
tests and five of six focused tests. `Nova_Nova_1` failed only XLS because it
looked for publication metadata outside the `Lbl` flags, while
`Nova_Nova_2` failed only XLSB because it reused the XLS high-bit masks. No
run-3 legitimate pass or broad failure exists yet, so neither category is
substituted.

Both trajectories inspected the native formats, implemented all four parser
paths, added their own synthetic tests, and explicitly claimed coverage for
missing-versus-empty comments and built-in flags. The hidden fixtures still
leave two independent implementation modes unclassified. XLS exercises a
missing comment and a non-empty Unicode `NameCmt`, but not a present empty
`NameCmt`. XLSB exercises an `_xlnm` spelling only when its encoded built-in
flag agrees, even though an XLS record already proves that spelling and binary
flag can disagree. A parser can therefore be correct for the currently tested
mode and wrong in exactly one reader.

| Evidence-backed survivor | Public invariant | Revised black-box oracle | Distinct boundary | Anti-overfitting rationale |
|---|---|---|---|---|
| Collapse present-empty XLS `NameCmt` and a missing comment to `None` | An explicitly present empty native comment is `Some("")`; absence is `None` | Add one empty `NameCmt` to the existing XLS fixture and assert `Some("")` beside the existing missing and Unicode cases | BIFF record presence versus zero-length payload | XLS uses a separate correlated record, unlike the already covered XML attribute and XLSB nullable string paths |
| Infer XLSB built-in state from an `_xlnm` prefix | XLSB `built_in` follows its encoded flag, not spelling | Add one `_xlnm`-looking `BrtName` whose flag is clear and assert `Some(false)` | BIFF12 spelling versus encoded flag | This closes the XLSB-specific shortcut with one mismatched record rather than duplicating every spelling/flag permutation |

Both requirements are already explicit in the public contract. The additions
modify only deterministic fixture generation and exact public-record
assertions; they do not prescribe storage, helpers, or parser control flow.
The reference parser should pass without production changes. The exact prompt
is unchanged, while the test, fixture, audit, and calibration hashes must be
recomputed and calibration restarts at 0/10.

### Submission-validator packaging gate

The post-hardening submission check rejected the textual fixture hunks as
invalid even though the exact local artifact passes `git apply --check` and a
strict hunk scan confirms that every one of the 1,383 fixture payload lines
begins with `+`. The reported examples are files named
`*.xls.hex`; those names retain a binary workbook suffix immediately before
the textual suffix and are the only new packaging mode introduced to satisfy
the earlier binary-header review.

The trajectory search was repeated across `agent-runs1`, `agent-runs2`, and
the two run-3 near-passes. Solver behavior, public seams, and the discriminator
ledger are unchanged: both run-3 patches still reach all four parsers and fail
one native flag case each. No legitimate pass or broad run-3 failure exists.
Related Olympus test patches use ordinary text fixture or source names and do
not provide evidence that a binary-looking double extension is required.

| Packaging failure | Required invariant | Revision | Behavioral effect | Anti-overfitting rationale |
|---|---|---|---|---|
| A submission validator classifies `*.xls.hex` payloads as malformed binary additions despite valid Git prefixes | Every fixture addition must be accepted as an ordinary new-file unified-diff hunk | Rename the lossless text payloads to neutral randomized `.txt` paths, prefix each payload line with a literal `+`, and map format keys to those paths in the test helper | None; the decoder ignores non-hex prefixes, so bytes, assertions, test identities, and runner modes remain identical | This changes only transport representation and avoids relying on one validator's treatment of binary-looking filenames or parsed hunk content |

The description also drops the sentence naming concrete record types, as
requested by review. The remaining contract still requires native values and
forbids formula- or spelling-based inference. Because both `meta.md` and
`test.patch` change, the exact-version false-positive audit and all patch-state
checks must be repeated, and calibration remains at 0/10.

### Run-4 fairness and coverage gate

The fourth solver bundle contains eleven completed evaluations and one
incomplete infrastructure record. Every completed run's evaluation, solution
patch, test log, and compact result was inspected. Raw trajectories were read
for the legitimate pass `Nova_Nova_3`, the single-format near-passes
`Nova_Nova_1` and `Nova_Nova_10`, and the broad focused failure
`Nova_Nova_2`. No unrelated run was substituted for an evidence role.

Three runs (`Nova_Nova_3`, `Nova_Nova_5`, and `Nova_Nova_9`) are legitimate
passes. Six of the eight failing implementations reused the BIFF8 publish and
workbook-parameter masks in `BrtName`; five misread, omitted, or associated
BIFF8 comments incorrectly. `Nova_Nova_10` additionally shows that an attempt
to fetch the official binary documentation can fail with HTTP 403. The
representative pass consulted Apache POI source before implementing the binary
layouts, while the broad failure wrote self-tests around its incorrect native
field assumptions. The repository exposes record framing but not the required
high-bit masks or complete comment schemas. This repeated convergence confirms
the Criterion 04 concern: the binary behavior is public, but the minimum format
facts needed to implement it are not locally discoverable.

All completed solutions used the same legitimate architecture: exported owned
records in the shared metadata model, one population path per reader, retained
legacy tuples for formula consumers, and parser-local helpers for variable
data. Successful patches changed six files and added 418-481 lines; all three
passed 205 baseline and six focused tests. The run-4 pass rate is 3/11, within
the current difficulty band, and successful implementations remain well above
the 200-line signal. The revision must therefore improve fairness and oracle
precision without adding another feature or weakening existing discriminators.

| Evidence-backed issue | Generalized shortcut or ambiguity | Fair public invariant | Black-box oracle | Decision |
|---|---|---|---|---|
| Six failures reused BIFF8 high-bit masks for BIFF12, and correct runs relied on external format material | Treat similarly named flags as sharing positions across binary formats | Each binary reader decodes owner and boolean fields from its own native schema | Existing exact XLS and XLSB records, including clear and set values | Add a compact schema-level field map to the description; keep the existing oracle |
| Five failures sourced or correlated BIFF8 comments incorrectly; official documentation was unavailable in one near-pass | Treat the `Lbl` description bytes as the public comment, or join comments by spelling | Missing, empty, and non-empty native comments stay distinct on the source record, including duplicate names | Existing XLS fixture with duplicate scopes and three comment states | Name the `NameCmt` layout and encoding in the field map without prescribing storage or helper structure |
| The concise description omitted the verifier's accepted ODS legacy policies | Preserve one defensible policy but fail an unstated compatibility choice | ODS legacy tuples may be the complete workbook-only projection or the complete all-record projection | Existing two-alternative ordered projection check | State both accepted outcomes in one sentence |
| The two high flags are tested only in mutually exclusive records | Decode them with mutually exclusive control flow even though the encoded bits are independent | `published` and `workbook_parameter` can both be true on one name | Set both native bits/attributes on one existing record in XLS, XLSX, and XLSB and compare the complete record | Strengthen the existing high-flag discriminator; do not add records or a new feature |
| Scope assertions compare numeric enum values but do not state the owner sheet name in the oracle | Return an encoded index without demonstrating its public relation to sheet metadata | `Worksheet(n)` names `sheets_metadata()[n]` | For every local fixture record, compare the indexed sheet name with the fixture's encoded owner | Integrate the direct relation into the existing scope oracle; this is fixture-contract validation, not a new discriminator |

The simultaneous-flag case is retained because the two public fields are
independent encoded bits and a compiling `else if` mutant is a plausible
implementation mode. It replaces a single-true fixture state instead of adding
a symmetry fixture. The sheet-name linkage likewise reuses every existing
record and introduces no additional permutation. The solution patch requires
no production change: the reference already decodes independent masks and
owner indexes correctly. Any prompt, fixture, or test edit starts a new
immutable level-3 revision at 0/10 and requires the complete false-positive and
patch-state audit again.

### Binary-guidance review reconciliation

The next blocking description review asked for both byte-layout paragraphs to
be removed and the contract kept at the behavioral level. That request is
compatible with the earlier fairness review only through the alternative the
fairness reviewer explicitly offered: cite the exact normative format sections
instead of reproducing their layouts. The repository and run-4 evidence remain
unchanged, so silently removing all guidance would reopen the recorded
Criterion 04 defect.

The public description therefore removes every byte offset, bit position,
sentinel value, string-option rule, and record-association instruction. In
their place it gives only the exact Microsoft specification coordinates:
`[MS-XLS]` sections 2.4.150 and 2.4.176, plus `[MS-XLSB]` sections 2.4.718 and
2.5.167. These are the normative defined-name, name-comment, and nullable
string definitions verified against the current Microsoft Open Specifications
index. This is a documentation pointer, not a parser strategy, and it preserves
the high-level observable contract and all accepted implementations.

No test, fixture, runner, reference behavior, or discriminator changes in this
revision. The exact prompt hash and audit record must still be recomputed, and
calibration remains at 0/10.

### Run-5 trajectory and XLSX built-in gate

`agents-run5` contains one completed Nova attempt against the citation-based
description. The run is a legitimate partial implementation: all 205 baseline
tests pass, while the focused lane scores 4/6. It passes XLSX, XLSB, ODS, and
empty-reader coverage but fails the XLS comment decoder and BIFF5 owner index.
There is no run-5 pass or broad failure, so neither category is synthesized.
The existing run-4 pass, near-pass, and broad-failure evidence remains
historical context rather than being relabeled as run 5.

The raw trajectory confirms the public multi-reader architecture but also
exposes a distinct XLSX false positive. The run-5 solution, all three legitimate
run-4 solutions, and the golden reference classify every `_xlnm.` prefix as
built in. The public wording instead says the standardized SpreadsheetML names.
ISO/IEC 29500 defines eight such names, so an arbitrary reserved-prefix spelling
is not a member of that set. The reviewer-proposed negative is therefore a
public semantic boundary, not an adversarial malformed-input predicate.

| Evidence-backed shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfitting rationale |
|---|---|---|---|---|
| Treat every `_xlnm.` prefix as a standardized XLSX built-in | XLSX `built_in` is true only for the eight standardized SpreadsheetML spellings | Add one `_xlnm.UserDefined` record to the existing XLSX fixture and require `Some(false)` beside the existing `_xlnm.Print_Area` positive | Reserved namespace prefix versus enumerated standardized identity | The exact shortcut occurs independently in four solver patches and the reference; one negative record closes it without multiplying prefix variants |

The prompt will enumerate the eight accepted spellings so the discriminator is
self-contained. No binary, ODS, ordering, lifecycle, or legacy-projection
requirement changes. Because `meta.md`, the XLSX fixture, `test.patch`, and
`solution.patch` change, all exact-version checks, the false-positive audit, and
calibration restart at 0/10.

#### Run-5 duration evidence

The 85-minute wall time was solver work, not test execution. The recorded agent
phase spans 72.5 minutes before its last visible turn and about 79 minutes before
post-agent processing begins. Four model turns contain 343 top-level tool calls,
including 385 shell-command invocations, 135 network/search/clone commands, 150
broad filesystem searches, and 31 Cargo checks or test commands. The trajectory
processed 46.8 million tokens after repeated large repository dumps and external
format research, with compaction enabled. Post-agent patch generation and all
211 wrapper tests then took under one minute. The dominant costs were exhaustive
binary-spec hunting, cloning many third-party parsers, repeated full-suite runs,
and debugging an introduced XLSB regression.

### Legacy-projection description reconciliation

The latest HIGH-severity description review asks to remove the paragraph that
states the accepted `defined_names()` projections. The trajectory and
repository evidence already recorded above remains decisive: preserving
workbook-only ODS tuples and projecting all newly discovered ODS names are both
legitimate implementations. The current black-box oracle accepts both complete
ordered policies, while the pinned regression suite protects the existing
Excel tuple behavior.

Removing the paragraph therefore does not select an unstated implementation or
weaken a new-API discriminator. It removes verifier-policy prose from the
participant description while retaining a permissive compatibility regression.
No test, fixture, runner, or reference change is justified. This prompt-only
revision requires new artifact hashes and an exact-version false-positive audit,
and calibration remains at 0/10.

### Scope wording deduplication

The next HIGH-severity description review identifies two sentences expressing
the same owner-versus-formula invariant. Removing the earlier explanatory
sentence is safe because the later directive still requires each format's own
owner definition and explicitly forbids inferring scope from formula text. The
scope-index oracle, fixtures, and every accepted implementation remain
unchanged. This is another prompt-only revision: no test, fixture, runner, or
reference edit is warranted, while hashes and the exact-version audit must be
refreshed.

### Run-6 self-containment and XLSX finite-set gate

`agent-runs6` contains four completed Nova attempts against the citation-only
prompt. Every run passed all 205 baseline tests, but none passed all six focused
tests: run 1 scored 5/6, run 2 scored 3/6, run 3 scored 4/6, and run 4 scored
3/6. The compact records, solution patches, test logs, and raw trajectories were
inspected before changing the verifier. Run 1 is the representative near-pass;
run 2 is the representative broad focused failure; no legitimate pass exists in
this batch.

The raw evidence resolves the earlier conflict between concision reviews and
Criterion 04. Runs 2 and 3 were classified unfair because the cited Microsoft
pages were unavailable. Run 2 received an HTTP 403 from the Microsoft host and
then searched SheetJS, Apache POI, LibreOffice, local registries, and other
repositories before guessing the wrong XLSB high-bit masks. Run 4 likewise
received empty or failed downloads and reconstructed specialized layouts from
third-party parsers. Run 1 nearly completed the task without an external
blocker, but still omitted native `NameCmt` data. A citation is therefore not a
self-contained substitute for the small set of binary facts selected by the
public behavior.

The post-run review also identified a genuine finite-domain false positive.
The prompt enumerates eight standardized XLSX built-in names, but the fixture
proves only `Print_Area` as positive. A parser hard-coded to that one spelling
passes beside the existing `_xlnm.UserDefined` negative. Testing the other
seven enumerated values is not an arbitrary symmetry expansion: it exhausts a
small, explicitly public set and distinguishes under-acceptance from the
separately tested prefix-only over-acceptance shortcut.

| Evidence-backed issue | Plausible incorrect implementation | Public invariant | Revised oracle or guidance | Distinct boundary and decision |
|---|---|---|---|---|
| Three runs could not retrieve the cited binary specifications and independently guessed owner, flag, or comment layouts incorrectly | Correct XML/ODS readers plus approximated BIFF offsets and shared XLS/XLSB masks | XLS and XLSB expose exact native owner, flags, and comment nullability | Replace the external-only citation with compact field offsets, masks, indexing rules, and comment-string framing in `meta.md`; keep black-box format assertions | Offline self-containment at an opaque binary boundary; prompt change, not an implementation constraint |
| The XLSX positive fixture contains only `_xlnm.Print_Area` | Return true only for `Print_Area` and false for every other name | All eight enumerated standardized spellings are built in, while an arbitrary `_xlnm.` spelling is not | Add the remaining seven names to the same XLSX workbook and exact ordered record assertion | Complete finite-set membership versus one-value hard-coding; focused fixture strengthened |

The binary guidance will describe interoperable record facts rather than a
parser architecture, helper decomposition, or storage strategy, and the whole
description remains below 500 words. The reference already recognizes all
eight XLSX names, so no production behavior changes. Because `meta.md`, the
XLSX fixture, and `test.patch` change, the exact-version false-positive audit,
patch-state verification, and calibration count all restart at 0/10.

### Scope `Copy` review gate

The next fairness review claimed that `assert_local_scope_owners` moves a
`DefinedNameScope` out of a shared slice and therefore imposes an unstated
`Copy` bound. The prior trajectory search was repeated across the four run-6
solutions and the relevant public-type changes in earlier batches. All four
run-6 implementations derive exactly `Debug`, `PartialEq`, and `Clone` for
`DefinedNameScope`, without `Copy`, and all four focused suites compiled and
reached runtime assertions. Their failures were in format behavior rather than
interface compilation.

A minimal Rust 1.88 reproduction confirms the language behavior: matching the
`Worksheet(usize)` variant through a shared indexed place can copy the `usize`
payload without copying or moving the enum itself. The existing helper thus
does not actually require `DefinedNameScope: Copy`, and a prompt-compliant
implementation is already accepted.

The helper will nevertheless match `&record.scope` and dereference the captured
index explicitly. This makes the intended borrow visible to both contributors
and static reviewers without changing the public contract, fixture, runtime
oracle, discriminator set, or accepted implementation space. Because the test
source and `test.patch` hash change, exact patch-state verification and the
false-positive audit are repeated even though no behavioral test changes.

### Binary-guidance concision gate

The next description review was checked against the run-4 and run-6 trajectory
evidence already recorded above. The ordinary XLS name-length, formula-length,
name-decoding, and formula-placement details are already represented by the
pinned parser and are not needed to locate the new metadata, so they are
removed. The same applies to the XLSB key byte, ordinary name decoding, and
byte-by-byte formula and auxiliary-payload traversal; only the comment's
position after those already-parsed regions remains. The duplicated statement
mapping missing and present-empty `NameCmt` records to `None` and `Some("")` is
also removed because the public comment paragraph already states that
observable distinction.

The retained XLS guidance is limited to facts absent from the pinned parser:
the owner location and indexing convention, metadata masks, `NameCmt`
association, and its string framing. No public requirement, fixture, oracle,
reference behavior, or accepted implementation changes. The clause ledger and
all fourteen level-3 mutants were re-audited against the shortened prompt; each
remains connected to the same public requirement and focused discriminator.
This prompt-only revision changes the artifact hash and keeps calibration at
0/10.

## Clause-to-test ledger

| New participant-facing requirement | Strongest behavioral test |
|---|---|
| Crate-root record, enum, and exact `Reader` slice accessor exist with the stated fields, variants, `Debug`, `PartialEq`, and `Clone` | The integration test imports and constructs the public types, applies direct generic trait bounds to each, assigns the associated trait method to `fn(&R) -> &[DefinedName]`, and opens each concrete reader |
| XLSX native metadata | An OOXML workbook combines owner, hidden, escaped and empty comments, simultaneous publish and workbook-parameter attributes, all eight standardized built-in positives, and a nonstandard `_xlnm.` negative |
| XLS native metadata | BIFF8 combines owner and low flags with simultaneously set high bits 13/14, separate missing, empty, and Unicode `NameCmt` states, duplicate spellings, mixed string widths, and indexed formulas; BIFF5 remains an independent ownership/flag mode |
| XLSB native metadata | A BIFF12 workbook combines the owner sentinel and low flags with simultaneously set high bits 15/16, missing, empty, and non-empty trailing nullable comments, and an `_xlnm`-looking name whose encoded built-in flag is clear |
| ODS placement scope and unavailable metadata | An ODF workbook has local containers in two tables plus top-level names and asserts `None` for all five unsupported properties |
| Source order, duplicate spellings, scope indexing, and current formula text | Each format asserts its complete ordered record slice, and every local record resolves `sheets_metadata()[n]` to its encoded owner sheet |
| ODS legacy tuples remain coherent without selecting a new compatibility policy | The ODS test accepts either the exact encounter-ordered workbook projection or the exact all-record projection and rejects partial or reordered views |
| Empty readers and stable borrowed metadata | Existing no-name fixtures are opened through concrete and automatic readers, and named fixtures are compared before and after worksheet formula reads |

The suite separately protects pre-existing public behavior where the new
metadata source is already the legacy source: XLS, XLSX, and XLSB project
metadata back to the legacy tuple slice, representative indexed formulas retain
their rendered strings, and the complete existing suite runs. ODS retains the
reference's pinned workbook-only projection while the verifier also accepts an
all-record projection. These are regression safeguards, not private storage
constraints.

Static fixtures derive from the repository's MIT-licensed fixtures. Their
generation and semantic inspection are recorded in the candidate's
`PROTOTYPE.md` and `FORMAT_MATRIX.md`. The test patch stores lossless hexadecimal
encodings under neutral randomized `.txt` names so every addition is an
ordinary text unified-diff hunk. Each payload line has a literal `+`, so its
diff representation begins with `++`. The Rust integration test ignores the
non-hex prefix and decodes the original bytes without extra packages.

## Reference architecture and size risk

The reference stores structured owned records and retains a tuple projection
for the compatibility API and formula consumers. It changes the public/shared
metadata seam and the four reader implementations:

- XLSX reads owner and boolean attributes plus the optional comment;
- XLS correlates `NameCmt` with its preceding `Lbl`, decodes both BIFF string
  widths, and reads distinct low and high flag bits;
- XLSB skips formula and auxiliary payloads before decoding the trailing
  nullable wide comment and its distinct high flag bits;
- ODS returns table-local definitions and labels them with the table index while
  retaining workbook-only records in the reference tuple projection.

The reference is 273 production additions and 23 deletions across five files,
or 241 strict effective additions after excluding blank and comment-only
lines. Every added branch maps to a participant-facing metadata semantic; no
unrelated feature or padding was added.

## Verification state

The exact level-3 artifact version is recorded in `FALSE_POSITIVE_AUDIT.md`.

- Pristine base: exact pin; full all-feature suite passes offline.
- Test-only: 205/205 wrapper baseline passes and exports its real JUnit
  identities; the focused lane exits 101 because the public API is absent and
  exports one skipped compilation placeholder.
- Test patch format: all 8 new-file hunks have `/dev/null` and `b/<path>`
  headers, every one of the 2,019 added lines has a leading `+`, and
  `git apply --check` passes. The fixture payloads use neutral randomized
  `.txt` names and their payload lines begin with `++` in the diff. The wrapper
  exposes both `base` and `new`, and no production path or package installation
  is present.
- Solution-only: 44/44 unit, 161/162 integration with 1 ignored, and 67/67
  doctests pass; formatting and both Rust 1.88 WASM checks pass. Stable Clippy
  passes with only the pinned repository's pre-existing
  `uninlined_format_args` lint allowed; the unmodified pin fails strict Clippy
  on that same lint.
- Combined: 205/205 wrapper baseline and 6/6 focused tests pass. The sorted
  normalized 205 baseline identities are identical before and after the
  solution, giving 205 p2p, 6 f2p, one skipped placeholder, and zero
  unclassified entities.
- False-positive audit: fourteen level-3 mutants isolate public trait bounds,
  defaulted metadata,
  comment nullability and encoding, BIFF record correlation, non-aligned high
  bits, XLS present-empty comment handling, XLSB spelling-versus-flag state,
  simultaneous independent flags, unsupported ODS properties, empty
  initialization, partial ODS legacy projection, and both over- and
  under-accepting XLSX built-in classification. Every mutant fails a focused
  test; the all-record ODS control passes, and M27-M31 each pass all 205 pre-existing tests while
  failing only their intended format test.

The representative run-6 near-pass still scores 5/6 and fails only its
original XLS behavior, confirming the complete XLSX positive set accepts its
exact classifier. The revised reference passes 6/6 and the complete suite.

Two same-boundary symmetry survivors were prototyped and deliberately not
added: the equivalent OOXML textual boolean spelling and the opposite ODS
global/local container order. The reference passes both prototypes and each
mutant fails, but neither contributes a new discriminator.

Core artifact hashes:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `c66206a43a9525461e72ed326dd517251cfe74338c4de366dd0005b2688f6ee2` |
| `test.patch` | `5b25619b1c81e835be5eaa17fe758e0d99ea04b76328925b8e68aaf14a8deb78` |
| `solution.patch` | `626d8c458d5818ec7f0ed5ffb74f44c759b22fd74ee70ab72993bb8f5e12508b` |
| `Dockerfile` | `e9de487abfc5f756639fab5e6ef1fc00cb5e7cbbccdbe1dc347c60fdecbd13b9` |
| generated `Cargo.lock` | `26080103f273c18ee7da9c79be8549768763b9cf4935613bd00b1f098dfcec57` |

Level 1 is abandoned at 9/10 passes, and Level 2 stopped after five consecutive
solves. Historical runs remain bound to their exact versions and are indexed in
`RUNS.md`.

## Acceptance and archival closure

The user confirmed platform acceptance on 2026-08-01. The canonical prompt,
grader, reference, explanation, and image are frozen at the artifact identities
above; no post-acceptance submission change was made.

Raw solver directories and the original uploaded ZIP bundles are preserved in
`archive/calamine-defined-names/agent-runs.tar.gz`. The archive contains 269
files, passed exact source-inventory comparison and `gzip -t`, and is indexed by
the adjacent archive manifest. `RUNS.md` is the compact trajectory index.

The accepted outcome validates the central experiment: a task can have a
compact early reference yet still produce successful solver patches above the
200-line median signal when the real work crosses independent native formats.
The harder and fairer version did not multiply scope fixtures; it introduced
different data-flow boundaries for comments and non-aligned flags. The other
durable lesson is operational: external specification citations do not make an
offline task self-contained when agents receive HTTP 403 or empty documents.
A concise field map can describe fixed input semantics without prescribing a
parser architecture.
