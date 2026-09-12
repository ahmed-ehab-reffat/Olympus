# LEVELS - Calamine structured defined names

## Experimental level 1

Status: `abandoned after 10 runs: 9 legitimate passes, 1 near-pass`.

Level 1 tested the unpadded cross-format metadata contract. Successful
platform-reported sandbox LOC values were 210, 212, 253, 273, 284, 319, 331,
368, and 415, giving a median of 284. Raw production additions had a median of
153. Every successful run also touched the required multi-file surface and used
more than 40 agent steps.

The platform LOC signal therefore cleared 200, but difficulty did not: 9/10 is
far above both the former 4/10 and current 5/10 ceilings. The only failure
decoded the XLSB owner field one byte early and was already caught by the
level-1 verifier.

The run bundle is retained in `agent-runs1` as trajectory and replay evidence.
It cannot count toward any revised artifact.

## Experimental level 2

Status: `abandoned after 5 runs: 5 legitimate passes`.

Level 2 keeps the same spreadsheet metadata work. It documents both coherent
ODS legacy tuple policies, opens all four concrete readers, verifies the exact
generic `Reader` slice method, cross-checks automatic dispatch, and rejects
partial or reordered ODS tuple projections.

Two predecessor false positives justify these additions. A wrapper-only
inherent accessor and a partial ODS legacy projection both passed level 1 and
the complete pre-existing suite; level 2 rejects them. All nine legitimate
level-1 patches still pass, including the implementation that exposes all ODS
metadata records through the tuple accessor.

The first five working-pool runs all passed with sandbox LOC values from 216
to 381. Calibration stopped at that point because five solves exceeded the
then-current maximum of four. Under the revised 50% policy, five solves alone
would no longer trigger an early stop, but this abandoned artifact remains
trajectory evidence and cannot count toward a revised version.

## Experimental level 3

Status: `accepted on 2026-08-01`.

Level 3 keeps the structured API and adds native comment, publication, and
workbook-parameter metadata. The formats now require different data flow:
OOXML attributes, BIFF8 correlation with a separate `NameCmt` record, and a
BIFF12 trailing nullable string. The binary formats also use different high
flag bits. ODS reports honest absence.

The verifier adds the reviewer-requested zero-cardinality case, metadata
stability after worksheet reads, and a coherence check for ODS
`defined_names()`. The final reconciliation accepts either the workbook-only
or all-record ordered ODS projection, removing the unstated legacy policy. The
prompt leaves ordinary empty/lifecycle defaults implicit. The current fairness
revision embeds the minimum BIFF8/BIFF12 field map because those definitions
are absent from the pinned parsers and citation-only access failed repeatedly.
It provides offsets, masks, ownership rules, and comment framing without
prescribing parser helpers or storage.

The reference measures 273 additions and 23 deletions, or 241 strict effective
production additions across five files.

The first two run-3 attempts are retained only as trajectory evidence. Both
passed all 205 baseline tests and five of six focused tests: one failed only
the XLS high flags, and the other failed only the XLSB high flags. The fixture
hardening revision adds an explicitly present empty XLS comment and an XLSB
name whose `_xlnm` spelling disagrees with its built-in flag. That edit creates
a new immutable version, so level 3 restarts at 0/10 and none of the earlier
runs count toward it. The later description and fixture-transport revision
also restarts the immutable version at 0/10; it changes no behavioral oracle.

Run 4 evaluated eleven completed solutions, with three legitimate passes and
eight focused failures; one additional run record is incomplete and is not
counted. That 3/11 solve rate and the 418-481 added lines in successful patches
confirm both difficulty and long-horizon implementation size. The batch also
confirmed a fairness defect: six failures reused the XLS flag masks for XLSB,
five mishandled XLS comments, one official-document fetch returned HTTP 403,
and a legitimate pass consulted external parser source for the missing binary
layouts.

The post-run-4 revision clarifies the two accepted ODS legacy projections. Its
fixtures exercise simultaneous publication and workbook-parameter bits in XLS,
XLSX, and XLSB, and its scope oracle directly resolves every `Worksheet(n)`
through `sheets_metadata()[n]`. A subsequent blocking review removed both
binary-layout paragraphs; four exact Microsoft specification sections now
provide the fairness breadcrumb without prescribing parser mechanics. The
production reference and tests are unchanged. The 3/11 batch is trajectory
evidence only, and the revised immutable version starts at 0/10.

Run 5 contains one completed attempt. It passes all 205 regressions and four of
six predecessor focused tests, failing only XLS comment decoding and BIFF5
ownership. Its raw trajectory also exposed a verifier survivor shared by the
reference and all three run-4 passes: classifying every `_xlnm.` XLSX name as
built in. The current prompt enumerates the eight standardized names, and the
XLSX fixture now pairs `_xlnm.Print_Area` with `_xlnm.UserDefined`. The revised
reference is 6/6; the isolated prefix mutant and representative run-4 patch are
5/6; run 5 is 3/6. This artifact again starts at 0/10.

The latest prompt-only revision removes the paragraph describing accepted
legacy tuple projections. The verifier remains permissive between the two
complete ODS policies, while existing regressions continue to protect Excel
behavior. Tests, fixtures, and reference behavior are unchanged; the prompt
also drops a duplicated scope explanation while retaining the direct
prohibition against formula-derived scope. Its hash changes and calibration
remains at 0/10.

Run 6 contains four completed attempts against that citation-only prompt. All
passed 205/205 regressions and scored between 3/6 and 5/6 focused, but no run
passed. Two evaluations classified the task as unfair because Microsoft pages
returned HTTP 403 or otherwise could not be retrieved; a third recorded the
same access failure as a mixed blocker. The revised prompt therefore embeds
the required binary facts directly.

Run 6 also exposed a distinct verifier survivor: an XLSX implementation could
recognize only `_xlnm.Print_Area` and still pass even though the prompt lists
eight standardized built-ins. The current fixture contains all eight positive
spellings plus the nonstandard-prefix negative. Prefix-only and
Print-Area-only mutants each pass 205/205 regressions and fail only XLSX at
5/6. The run-6 near-pass still scores 5/6 with only its original XLS failure.
This new immutable artifact is verified and restarts at 0/10.

The final test-source clarification matches worksheet scope by reference. The
review that prompted it incorrectly inferred an unstated `Copy` bound: every
run-6 implementation omits `Copy` and compiled, and an exact no-`Copy` control
passes 6/6. The edit changes no oracle or fixture but produces a new test-patch
hash, so the immutable calibration version again remains at 0/10.

## Acceptance closure

The platform accepted the final self-contained Level 3 package on 2026-08-01,
as confirmed by the user. No formal ten-run batch was completed against that
last prompt, so the earlier batches retain only their version-specific results;
they are not combined or relabeled after acceptance. `RUNS.md` is the compact
index, and the raw evidence is preserved under
`archive/calamine-defined-names/`.
