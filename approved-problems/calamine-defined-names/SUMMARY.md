# SUMMARY - Calamine structured defined names

Status: **accepted on 2026-08-01**. Levels 1 and 2 remain abandoned
calibration history; the later Level 3 artifact is the accepted package.

Repository: `tafia/calamine`

Production language: Rust

Task type: enhancement

Pin: `0a24c2a9f1e38c0932c1299e633270dc730db505`

The problem adds a structured public view over defined-name metadata across
XLS, XLSX, XLSB, and ODS. Level 3 exposes scope, hidden and built-in state,
comments, publication, and workbook-parameter state through one public record.
The reference is 273 production additions and 23 deletions, or 241 strict
effective additions across five files.

Level 1 established that successful solver patches clear the platform's
200-line sandbox signal: nine legitimate passes had a median sandbox LOC of
284. Their raw production additions had a median of 153. The 90% solve rate
failed the difficulty gate. The only near-pass misread the XLSB owner offset
and scored 4/5.

Level 2 used that batch as trajectory evidence, then all five of its initial
working-pool agents passed. It was stopped and abandoned under the calibration
protocol.

Level 3 varies the discriminators instead of multiplying old scope cases. XLSX
parses attributes, XLS correlates a separate comment record with duplicate
names and mixed string widths, and XLSB decodes trailing nullable data after
formula payloads. The binary flag masks deliberately differ. ODS reports
unsupported properties as absent, and regression coverage retains the pinned
workbook-scoped behavior of its old tuple accessor while also accepting a
complete all-record projection. Empty readers and post-read metadata stability
are also checked.

The reviewed interface now states `Clone` alongside `Debug` and `PartialEq`
and checks those bounds directly on both public types. Local-scope assertions
borrow the enum explicitly, and a no-`Copy` control passes. Run 4 produced three
legitimate passes from eleven completed evaluations, but six failures reused
the XLS masks for XLSB and five mishandled XLS comments. A citation-only
revision then produced no pass in run 6; two evaluators explicitly classified
the inaccessible Microsoft documentation as unfair. The current 383-word
description removes ordinary XLS and XLSB name and formula reconstruction
details while retaining the owner, mask, association, and string-framing facts
required for the public behavior. The verifier accepts both coherent ODS
legacy projections without publishing that test-policy detail.

Run 5 exposed prefix-only XLSX built-in classification. Run 6 then identified
the opposite false positive: recognizing only `_xlnm.Print_Area` while
rejecting the other seven enumerated standardized names. The XLSX fixture now
contains all eight positives plus `_xlnm.UserDefined` as a negative, and the
reference uses exact finite-set membership.

The exact package passes every official offline patch state: 205/205 baseline
wrapper tests, 6/6 focused tests, the full 44-unit plus 161/1-ignored
integration plus 67-doctest suite, formatting, both WASM lanes, and Clippy. The
wrapper census is 205 p2p, 6 f2p, one skipped compilation placeholder, and zero
unclassified entities. Fourteen level-3 mutants are isolated with no survivor
in the attempted set. The final fixtures distinguish empty XLS `NameCmt` from
absence, make XLSB built-in state disagree with `_xlnm` spelling, and set
publication and workbook-parameter state simultaneously in every Excel format.
The prefix-only and Print-Area-only XLSX mutants each pass all 205 pre-existing
tests and fail only their targeted format test. The representative run-6
near-pass retains only its original XLS failure at 5/6, confirming that the
expanded XLSX oracle accepts a legitimate exact-set implementation.

All five workbook payloads now use neutral randomized `.txt` names. The final
test patch has eight valid new-file hunks, and every added line is explicitly
prefixed with `+`. Payload lines themselves carry a second literal `+`, which
the hex decoder ignores.

The platform accepted this exact package on 2026-08-01, as confirmed by the
user. The canonical artifact identities are frozen in `RUNS.md` and the archive
manifest. Historical solver batches remain evidence for their own immutable
versions and are not combined into a synthetic final calibration rate. Raw runs
are recoverable from `archive/calamine-defined-names/agent-runs.tar.gz`.
