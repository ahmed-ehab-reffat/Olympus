# False-positive audit - Calamine structured defined names

Status: `complete for the artifact accepted on 2026-08-01`.

Audit date: 2026-07-31

Source pin: `0a24c2a9f1e38c0932c1299e633270dc730db505`

This audit covers the exact level-3 prompt, tests, reference patch, fixtures,
and runner identified below. Final builds used the pinned Rust 1.88 toolchain
with Cargo offline; the already verified Dockerfile is unchanged.

The audit was repeated after the run-6 fairness and XLSX finite-set revision,
then repeated again for the prompt-only binary-guidance trims. The 383-word
prompt removes ordinary XLS and XLSB name and formula reconstruction details
already present in the pinned parsers, plus a duplicated comment-nullability
statement. It retains the otherwise missing owner, flag, record-association,
and comment-framing facts needed for an offline solve, enumerates the eight
standardized SpreadsheetML built-in names, and directly prohibits
formula-derived scope. The verifier continues to accept both coherent ODS
legacy projections.

The clause-to-test mapping and all fourteen level-3 mutants were rechecked
against the shortened wording. Every tested behavior remains public and every
mutant retains the same discriminator. Since `test.patch`, `solution.patch`,
the fixtures, runner, and container are byte-for-byte unchanged, this revision
does not alter any executable oracle or prior patch-state result; only the
prompt hash changes and calibration remains at 0/10.

For the exact artifact hashes below, the clean reference passes 6/6 focused
and 205/205 regression tests. Prefix-only M30 and Print-Area-only M31 each pass
205/205 and fail only XLSX at 5/6, proving the two sides of exact finite-set
membership independently. The representative run-6 near-pass still scores
5/6 and fails only its original XLS behavior; the seven added XLSX positives
do not manufacture a second failure.

## Trajectory basis

Level 1 produced nine legitimate passes and one near-pass. Level 2 then
produced five legitimate passes in its first five working-pool runs, so its
calibration stopped under the former 40% policy: no remaining outcomes could
bring the solve count down to its accepted 1-4 range. The complete `agent-runs1` and
`agent-runs2` bundles were searched, and every compact result, solution patch,
test log, and raw trajectory was inspected before level 3 was designed.

The shortest level-2 pass, `Nova_Nova_2`, used one shared owned vector and
implemented all four native parser seams in 216 sandbox LOC. The independent
longest pass, `Nova_Nova_5`, used the same public architecture but independently
encountered BIFF string-width and ODS container issues while developing its
own fixtures. There was no near-pass or broad failure in level 2. Those facts
support changing the semantic discriminator instead of adding more owner,
order, or low-flag examples.

The first two `agent-runs3` attempts are legitimate near-passes. Each passed
all 205 baseline tests and five of six focused tests. `Nova_Nova_1` failed only
XLS after sourcing publication state outside the `Lbl` flags;
`Nova_Nova_2` failed only XLSB after reusing the XLS high-bit masks. Both raw
trajectories inspected every parser path and claimed missing-versus-empty
comment and native built-in coverage. There is no run-3 legitimate pass or
broad failure to substitute. The two new fixture cases close independent
public shortcuts that those trajectories and the format boundaries make
plausible.

Both run-3 solution patches were replayed against the repackaged exact suite.
Each still passes five of six focused tests and fails its original single
format case. Their added self-tests also pass. The path-only fixture revision
therefore neither rescues nor creates a solver failure.

Run 4 contains eleven completed evaluations and one incomplete run record.
Three (`Nova_Nova_3`, `Nova_Nova_5`, and `Nova_Nova_9`) are legitimate passes.
Six of the eight failures reused BIFF8 high-bit masks in BIFF12, and five
mishandled BIFF8 comments. Raw trajectories were inspected for a legitimate
pass, two single-format near-passes, and a broad focused failure. One near-pass
could not fetch the official binary documentation because the request returned
HTTP 403; the representative pass consulted external Apache POI source before
implementing the missing layouts.

All three legitimate patches passed the then-revised six-test lane, including the
simultaneous flags and direct scope-owner checks. `Nova_Nova_3` also passes its
210-test baseline lane, which includes five solver-authored regressions.
`Nova_Nova_1` and `Nova_Nova_10` remain isolated 5/6 failures in XLSB and XLS,
respectively; broad failure `Nova_Nova_2` remains rejected. This preserves
legitimate implementation diversity while exposing enough schema information
to make the task self-contained.

Run 5 contains one legitimate partial implementation. It passes all 205
regressions and four of six predecessor focused tests. Inspection of every
compact artifact plus the raw trajectory found a distinct shared shortcut:
run 5, the reference, and all three run-4 passes classified built-in XLSX names
with `starts_with("_xlnm.")`. The current prompt makes the finite standardized
set explicit, so those predecessor patches are evidence for M30 rather than
accepted implementations of this exact revision.

Run 6 contains four legitimate implementation attempts and no complete pass.
All four preserve the 205-test regression lane and score between three and
five of six focused tests. The raw trajectories for the 5/6 near-pass and the
3/6 broad focused failure were inspected alongside the other two records.
Runs 2 and 3 were explicitly classified unfair because the cited Microsoft
pages were inaccessible; run 2 received HTTP 403 and then searched several
third-party parsers before guessing the wrong XLSB masks. Run 4 also recorded
failed or empty documentation downloads. This exact evidence justifies
embedding the small binary field map instead of delegating required semantics
to external links.

Run 6 also supplied the M31 false-positive report: the prior fixture proved
only `_xlnm.Print_Area` as positive even though the prompt enumerated eight
standardized names. The revised fixture contains all eight positives plus the
existing `_xlnm.UserDefined` negative. Replaying `Nova_Nova_1` against it
preserves that patch's original 5/6 XLS-only failure and confirms its exact-set
XLSX implementation remains accepted.

A later fairness review claimed that the local-owner helper imposed an
unstated `Copy` bound on `DefinedNameScope`. The claim does not reproduce: all
four run-6 implementations omit `Copy` and still compiled the focused suite to
runtime, and a minimal Rust 1.88 place-pattern reproduction also compiles. An
exact reference control with `Copy` removed and the parser cloning its scope
where needed passes 6/6. The helper now matches the scope by reference anyway,
making the intended `Debug + PartialEq + Clone` contract explicit without
changing an assertion or accepted behavior.

## Requirement and regression map

| Public requirement | Strongest behavioral oracle |
|---|---|
| Exact crate-root types, public fields, traits, and slice accessor | The integration crate imports and constructs the types, independently requires `Debug + PartialEq + Clone` for each, and assigns the associated `Reader` method to `fn(&R) -> &[DefinedName]` |
| Concrete and automatic reader support | Each of XLS, XLSX, XLSB, and ODS is opened through its concrete reader and cross-checked against `Sheets` |
| Native fields, owners, flags, comments, and encodings | XLSX, BIFF5/8, and BIFF12 records are decoded through public readers and compared as complete records |
| Encoded owner, zero-based worksheet indexes, order, and duplicates | Complete ordered slices include global and local shadows whose formulas reference different sheets, and every `Worksheet(n)` resolves to the encoded owner through `sheets_metadata()[n]` |
| Native hidden and built-in semantics | OOXML attributes, all eight standardized XLSX built-in positives, a nonstandard `_xlnm.` negative, BIFF/BIFF12 low bits, reserved-looking flag-clear binary names in XLS and XLSB, and BIFF5 ownership are compared exactly |
| Native comments and absent-versus-empty distinction | XLSX checks escaped, empty, and missing attributes; XLS correlates missing, explicitly empty, and Unicode `NameCmt` states; XLSB checks null, empty, and non-empty trailing strings |
| Native publish and workbook-parameter semantics | Simultaneously set values exercise independent OOXML attributes, BIFF bits 13/14, and BIFF12 bits 15/16, while other records retain single-set and clear states |
| Honest ODS absence | Every ODS record has `None` for all five unsupported properties |
| Coherent ODS legacy compatibility regression | `defined_names()` may equal either the ordered workbook-scoped projection or the ordered all-record projection, but not a partial or reordered subset |
| Empty-accessor regression | Existing no-name fixtures for all four reader families return empty metadata through concrete and automatic dispatch |
| Stable accessor and existing formula regressions | Complete records are compared before and after worksheet reads; Excel legacy tuples and indexed formula strings are checked |

## Level-3 mutation set

M18-M30 remain in the ledger because their public requirements and strongest
assertions are unchanged. The run-6 revision adds M31 and rebuilds M30 against
the complete finite set. Every current-version mutant is killed:

| ID | Incorrect implementation | Focused result and isolation |
|---|---|---|
| M18 | Add the fields but default every Excel comment to `None` and both new flags to `false` | 3/6; XLS, XLSX, and XLSB fail independently |
| M19 | Collapse an explicitly present empty comment into `None` | 3/6; isolated in the XLS, XLSX, and XLSB tests |
| M20 | Associate BIFF `NameCmt` by the first matching spelling instead of the preceding `Lbl` record | 5/6; the duplicate-spelling XLS fixture fails |
| M21 | Reuse BIFF bits 13/14 as the BIFF12 publish and workbook-parameter masks | 5/6; only XLSB fails |
| M22 | Decode both BIFF `NameCmt` strings as compressed text | 5/6; only XLS fails on its Unicode comment |
| M23 | Invent `Some(false)` publish and workbook-parameter values for ODS | 5/6; only ODS fails |
| M24 | Seed an empty XLSX metadata vector with a placeholder record | 5/6; only `empty_defined_name_metadata` fails |
| M25 | Return only worksheet-local ODS records from the old `defined_names()` accessor | 5/6; only `ods_defined_name_metadata` fails |
| M26 | Give `DefinedName` a custom `Debug` implementation while omitting `Debug` from `DefinedNameScope` | The predecessor focused lane passes 6/6 and the 205-test regression lane passes; the revised lane fails compilation at the direct scope trait bound |
| M27 | Map both a missing XLS `NameCmt` and an explicitly present empty one to `None` | 5/6; only XLS fails |
| M28 | Derive XLSB built-in state from an `_xlnm` name prefix instead of the encoded flag | 5/6; only XLSB fails |
| M29 | Decode `workbook_parameter` only when `published` is false, treating independent bits as mutually exclusive | 5/6; only XLSB fails |
| M30 | Classify every XLSX `_xlnm.` spelling as built in rather than matching the standardized set | 5/6; only XLSX fails |
| M31 | Classify only `_xlnm.Print_Area` as built in and reject the other seven standardized names | 5/6; only XLSX fails |

M18 still passes all 205 pre-existing wrapper tests, demonstrating that the
new failures come from the level-3 behavior rather than unrelated regressions.
The opposite BIFF string-width shortcut was also tested: forcing UTF-16 for
both the compressed name and Unicode comment scores 5/6 while its pre-existing
lane remains 205/205. The fixture therefore exercises both string modes without
adding a mirror fixture.

M26 is the review-triggered interface survivor. It demonstrates why record-level
`assert_eq!` is insufficient: a custom record implementation can hide the
missing scope trait. The retained generic bound passes the reference and fails
the mutant before runtime without imposing any trait beyond the public prompt.
The separate no-`Copy` control passes all six focused tests, confirming that the
helper and direct trait bound require no additional enum trait.

M27 and M28 are the run-3 fixture-hardening mutants. Each passes all 205
pre-existing wrapper tests and fails exactly one focused format test. The
reference passes both probes without a production change. This isolates native
record presence from zero-length payload in XLS and encoded flag state from
name spelling in XLSB. Both mutants were rebuilt and replayed after the
run-4 revision with the same 5/6 focused and 205/205
regression outcomes.

M29 is the run-4 review-triggered interaction mutant. It compiled and passed
all 205 pre-existing tests, and it would pass the predecessor focused fixtures
where the two high flags were never true together. The revised XLSB record
kills it alone at 5/6. The XLS and XLSX fixtures encode the same public
combination without adding records, while the three legitimate run-4
implementations passed that revision.

M30 is the run-5 trajectory-triggered over-acceptance mutant. It is the
reference with prefix-based XLSX classification. M31 is the run-6
review-triggered under-acceptance mutant and recognizes only `Print_Area`.
Both compile, pass all 205 pre-existing tests, and fail only
`xlsx_defined_name_metadata` at 5/6. The fixture now exhausts the finite public
positive set and retains one negative reserved-prefix control, so the two
mutants isolate opposite membership errors without adding another binary-flag
fixture.

The all-record ODS behavior considered alongside M25 is a legitimate control
rather than a mutant. That mode passes 6/6 focused tests and all 205 wrapper
regressions. The unchanged workbook-only reference also passes both lanes. A
worksheet-only partial projection scores 5/6 and fails only the ODS
compatibility assertion.

The level-2 M01-M17 set remains relevant repository evidence. Its owner,
order, low-flag, exact-trait, BIFF5, formula-consumer, and partial-projection
failure conditions are still asserted in the level-3 test source. Old
level-1/2 solution patches are not counted as level-3 mutants because the
three new public fields make them fail compilation by design. Replaying the
shortest level-2 pass and the level-1 XLSB near-pass confirms that both stop at
the missing `comment`, `published`, and `workbook_parameter` fields.

## Survivors and rejected probes

No member of the retained fourteen-mutant level-3 set survives its applicable
focused lane, and no exact-version replay survives the revised lane. The
following additional probes were considered and rejected:

- swapping numeric and textual OOXML boolean spellings repeats a boolean
  parsing boundary already represented by the fixture;
- reversing the position of ODS top-level and table-local containers repeats
  the existing source-order boundary;
- adding another compressed or Unicode BIFF fixture repeats a boundary already
  covered inside one `NameCmt` record;
- fabricating a nonzero BIFF12 formula auxiliary payload without a
  repository-backed valid record would test private byte layout rather than a
  supported public workbook.

These exclusions avoid arbitrary predicates and symmetry permutations. There
are no actionable survivors from the attempted level-3 set.

## Wrapper accounting and patch states

The exact wrapper classifies every visible test entity:

- pristine: the complete 44-unit, 161-passing/1-ignored integration, and
  67-doctest suite passes;
- test-only `base`: 205/205 pass;
- test-only `new`: exits 101 at compilation and exports one skipped `new.run`
  placeholder;
- solution-only: the complete suite passes;
- combined `base`: the same normalized 205 identities pass;
- combined `new`: all six randomized focused identities pass.

The census is therefore 205 p2p, 6 f2p, one skipped compilation placeholder,
and zero unclassified entities. The sorted test-only and combined base
identities are byte-for-byte equal after normalization.

The test patch has eight new-file hunks. Every hunk starts with
`--- /dev/null` and `+++ b/<path>`, and `git apply --check` succeeds on the
pin. A separate line-level scan confirms that every one of its 2,019 added
lines begins with `+`. The five encoded workbook payloads use neutral
randomized `.txt` paths, with no binary workbook suffix in the patch filename.
Every fixture line begins with `++`: the first character is the diff marker and
the second is literal payload text ignored by the hex decoder. `test.sh`
supports both `base` and `new`, installs no packages, exports the real nextest
report from either target location, and uses a skipped fallback only when
compilation prevents per-test discovery. The test patch contains no production
paths.

## Build and portability checks

- Focused reference lane: 6/6.
- Wrapper regression lane: 205/205 with the repository's one configured skip.
- Complete reference suite: 44/44 unit, 161/162 integration with one ignored,
  and 67/67 doctests.
- Rust 1.88 formatting: pass.
- Rust 1.88 WASM with no default features: pass.
- Rust 1.88 WASM with all features: pass.
- Stable all-target/all-feature Clippy with `-D warnings` and only
  `clippy::uninlined_format_args` allowed: pass.

Strict Clippy without that allow fails on the same pre-existing formatting
site in pristine and solution-only trees. The failure is not introduced by
the patch and is recorded rather than hidden.

## Exact artifact version

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `c66206a43a9525461e72ed326dd517251cfe74338c4de366dd0005b2688f6ee2` |
| `test.patch` | `5b25619b1c81e835be5eaa17fe758e0d99ea04b76328925b8e68aaf14a8deb78` |
| `solution.patch` | `626d8c458d5818ec7f0ed5ffb74f44c759b22fd74ee70ab72993bb8f5e12508b` |
| `Dockerfile` | `e9de487abfc5f756639fab5e6ef1fc00cb5e7cbbccdbe1dc347c60fdecbd13b9` |
| generated `Cargo.lock` | `26080103f273c18ee7da9c79be8549768763b9cf4935613bd00b1f098dfcec57` |

Decoded fixture SHA-256 values:

| Fixture | SHA-256 |
|---|---|
| `biff5_defined_name_metadata.xls` | `9b2e4dcbebe0934a59f59715b0da0b3d45b1d70251150ca1c01b350a8d5d8305` |
| `scoped_names.xlsx` | `d72db84bcd32fc8c4c6814f45c1cdf6743fa90e46cb7987e7e2860fc46a90a87` |
| `scoped_names.xls` | `90cfeb58db18df6bb92386fcaa4cc8155e8c0ed30b34140581a6405c30698def` |
| `scoped_names.xlsb` | `dd61c9d682e54e1671f420811e159a40bd05a60c10c446ba05a2623e00f08931` |
| `scoped_names.ods` | `31dda4fa8d60a2c8a3be7df0df82b1661509c9e1b5fd1628845591041ee36d92` |

The corresponding randomized text-payload hashes are
`02892ad53080a0dcf94c1806dafe91d48c8fdeb80e7fd46f5027cf8267c94944`,
`8dc66d1b9d19b0209388aa346e496806909a23cf45aa1e166c07f3ef38994468`,
`0ff34a1eb11b5704db9c0f1ce5067942403811283a49dc9c28ad099597e926fb`,
`6cb16e897d678de1821ce1590c5c8b3d87775efe5ef4bae45b3b6495734ebd18`,
and `dd2b20cdf6946ace4af3eb5d501b060150cff8d9fdbeb0d442db6206974cf9ba`
in the table's fixture order.

The level-3 XLS generator hash is
`7d180cd43d2c85c3e1e4e4b206375221eea725a470232e8ba8376f174a32eabc`;
the cross-format generator hash is
`d887d2a27448dd95fb21780cb427c70091bdf77f99908f0d8c9ace9858036d99`.

The locally built verification image is
`sha256:ae9fa52297b23ae4193c949bb3b0f6093ba68d19df80581fe506ab4a080fd39e`.

The platform accepted this exact Level 3 artifact on 2026-08-01. Its identities
are frozen. Any future prompt, test, solution, fixture, runner, or container
change would create a different problem version and require the complete audit
again.
