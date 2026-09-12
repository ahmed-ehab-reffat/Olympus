# False-positive audit - PcapPlusPlus PCAPNG filtered copy

Latest audit date: 2026-07-31

Status: `passed for the L6 filter/validation-order re-freeze; zero survivors
in the 33-active-mutant attempted set`.

The user confirmed platform acceptance of this exact immutable version on
2026-08-01. Acceptance closeout did not change any artifact identity below.

This is evidence for the attempted repository-grounded mutation set, not a
claim that false positives are impossible.

## Immutable version

- Source: `seladb/PcapPlusPlus`
  `0dbbb9c75eb232135f13fdb794318c4da3270ebc`
- Dockerfile base:
  `public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest`
- Resolved official base digest:
  `sha256:ce073a8809812fc472187ad4b9bd24dd1794f009a440b66ea6cbdc2d0fab9321`
- Built problem image:
  `sha256:d49c554406aeb41f9987c93dfd23637826a4318b31bd54bf32ed8e87a8220d71`
- `meta.md`:
  `d527f61ce418cd97a765c3b2705961db1b76b6e6beddeae1f358ef114392630e`
- `test.patch`:
  `00d7213a423facc6ca47b43d2ba5eb2f5365e303eac9e1a45ae002c26d54cfe8`
- `solution.patch`:
  `1f228c09ddab23d64d57791964c8f33008565560cc84fc56e686b4cf3ab514bf`
- `solution_approach.md`:
  `c00e34a724b0e84f362ed59bacb31150e9f26c6c020c1f9bd52fc79921a3d87b`
- `Dockerfile`:
  `70e8b8f853700ac56afb0738fec87c972782041f57336fc442668a8b55bca7ff`

The prior Dockerfile used the same digest directly and had SHA-256
`46ec25e8747c860fc26ec8173a0c4e22a97e79df17ffd122c182f60749d25f68`.
It is retired because the submission validator requires one of the permitted
`:latest` prefixes. Its two local solver passes remain trajectory evidence
only and do not count for this re-frozen version.

The behavioral probe set changed once during the initial audit. The
predecessor used a zero trailing-length corruption and had SHA-256
`04c1a14975bcb584bf14837ee554eda0aedb751d34c23d65535af78dd9855ea8`.
That version is retired and has no calibration results.

## Requirement-to-oracle map

| Participant-facing requirement | Strongest behavioral test |
|---|---|
| Add the documented const public method | `StructureAndFiltering` binds a configured reader to `const PcapNgFileReaderDevice&` and invokes the method; a non-const-only implementation builds the library but not the harness. |
| Work whether the reader is closed or open without changing read position | `PcapNgCopy.ReaderLifecycle` calls before/after lifecycle transitions and verifies the next packet and its comment. |
| Replace successfully when source and destination use the same path | `InPlaceReplacement` selects UDP from a DSB-free mixed EPB/SPB capture and exact-compares the shortened file written to its original path. |
| Keep every section, byte order, local Interface ID namespace, and all IDBs | `StructureAndFiltering` covers opposite-endian section transitions; `InterfaceSelection` retains two differently typed IDBs per section and reuses their numbers with different meanings. |
| Use an EPB's referenced interface | `InterfaceSelection` retains a TCP EPB and drops a UDP EPB through valid Interface ID 1 in both sections; index-zero-only filtering produces the opposite decision in one section. |
| Apply the configured BPF to EPB and SPB | `StructureAndFiltering` and `NoMatchingPackets` exercise TCP/UDP decisions in both packet block families. |
| Preserve accepted packet bytes and copyable metadata/unknown blocks in order | `StructureAndFiltering` compares the complete expected output byte-for-byte, then independently counts packet, NRB, ISB, DSB, Custom, and unknown blocks. |
| Omit only standardized do-not-copy Custom Blocks | `StructureAndFiltering` and `NoMatchingPackets` interleave both standardized Custom Block types and an unrelated unknown block. |
| Leave options inside retained blocks untouched | `OptionPreservation` compares an exact retained file containing valid copyable and do-not-copy Custom Options in an IDB and EPB. |
| Recompute finite section length but retain unspecified `-1` | Exact output comparison spans one finite little-endian section and one unspecified-length big-endian section. |
| Validate standardized retained-block option and NRB-record framing without interpreting discarded EPB options | `MalformedOptions` rejects overruns in retained blocks; `DiscardedPacketOptions` succeeds when the same malformed option area belongs to a filter-rejected EPB. |
| Reject malformed outer framing and relevant bad references without damaging an existing destination | `MalformedFraming` and `MalformedReferences` corrupt the BOM, version/length relationships, truncation, section boundaries, EPB/ISB references and sizes, and SPB/IDB relationship; every rejection verifies a sentinel destination. |
| Reject obsolete Packet Blocks and ordinary input/output failures | `UnsupportedAndIo` covers obsolete blocks, missing and compressed input, and a directory destination. |
| Preserve compatibility | The base lane runs the existing offline `Pcap++Test` selection; the solution-only audit also ran `Packet++Test`. |

## Plausible incorrect implementation modes

The modes came from the repository's high-level reader/writer split, the raw
scanner reference, format boundary asymmetries, and reviewed solver evidence.
Each source mutant was compile-valid and isolated: restore the exact solution,
apply one behavioral defect, build, run the nine focused CTest entities, and
restore before the next mutation.

| Mutant / shortcut | Focused result on the final suite | Distinct discriminator |
|---|---|---|
| Retain the do-not-copy Custom type by checking the wrong constant | Killed by `StructureAndFiltering`, `NoMatchingPackets` | Standardized Custom copy policy |
| Drop both Custom types | Killed by `StructureAndFiltering`, `NoMatchingPackets` | Copyable versus do-not-copy distinction |
| Never filter SPBs | Killed only by `NoMatchingPackets` | Packet-family completeness |
| Never filter EPBs | Killed by `StructureAndFiltering`, `InterfaceSelection`, `NoMatchingPackets` | Packet-family completeness |
| Count the SHB itself in rewritten finite section length | Killed by `StructureAndFiltering`, `InterfaceSelection`, `NoMatchingPackets` | Finite-length semantics |
| Carry the prior section's interface table across an SHB | Killed by `StructureAndFiltering`, `InterfaceSelection`, `NoMatchingPackets` | Section-local Interface IDs |
| Validate only that a trailing block length is at least 12 | Killed by `MalformedFraming` after the audit-added nonzero mismatch probe | Equality of leading/trailing block lengths |
| Accept an ISB reference unless it is `UINT32_MAX` | Killed by `MalformedReferences` | In-range section-local ISB reference |
| Copy obsolete Packet Blocks | Killed by `UnsupportedAndIo` | Explicit unsupported-block policy |
| Truncate the destination before validating input | Killed by `MalformedFraming`, `MalformedOptions`, `MalformedReferences`, and `UnsupportedAndIo` | Failure publication boundary |
| Require the reader to be open | Killed by `StructureAndFiltering`, `InterfaceSelection`, `OptionPreservation`, `ReaderLifecycle`, `NoMatchingPackets` | Lifecycle independence |
| Treat SPB original length as captured length despite IDB snap length | Killed by `StructureAndFiltering`, `NoMatchingPackets` | SPB captured-byte boundary |
| Parse every section as little-endian | Killed by `StructureAndFiltering`, `InterfaceSelection`, `NoMatchingPackets` | Per-section byte order |
| Normalize a retained EPB timestamp byte | Killed by `StructureAndFiltering`, `InterfaceSelection`, `OptionPreservation`, `ReaderLifecycle` | Accepted-block byte fidelity |
| Drop NRB, DSB, and unknown blocks | Killed by `StructureAndFiltering`, `OptionPreservation`, `NoMatchingPackets` | Opaque metadata preservation |
| Reject every nonzero EPB Interface ID | Killed only by `InterfaceSelection` | Valid nonzero section-local packet reference |
| Retain only the first IDB in a section | Killed only by `InterfaceSelection` | Preserve-all-IDBs policy |
| Filter every EPB with Interface ID 0's link type | Killed only by `InterfaceSelection` | Referenced-interface filter semantics |
| Strip a do-not-copy Custom Option from a retained IDB | Killed only by `OptionPreservation` | Complete-block policy versus option opacity |
| Accept a padded option whose declared value overruns its block | Killed only by `MalformedOptions` | Block-bounded option framing |
| Accept an NRB record whose declared value overruns the record area | Killed only by `MalformedOptions` | Block-bounded NRB-record framing |

An independent high-level packet reconstruction was also prototyped against
the owned capture. It produced a 172-byte one-section output from the
1,396-byte two-section input, while the exact retained output was 1,064 bytes.
The independent scanner/oracle rejected it. This establishes that the main
repository-native shortcut cannot pass by merely rewriting accepted packets.

## Actionable survivor and test change

The “trailing length is merely at least 12” mutant compiled and passed all six
focused entities under the predecessor artifact because its corrupted trailer
was zero, which accidentally satisfied the mutant's weak guard by failing it.
The mutant also passed the complete pre-existing base lane: 69 passed, zero
failed, 44 skipped out of 113.

The probe was changed to use a nonzero but unequal trailer of 12. The reference
rejects it and preserves the sentinel destination; the mutant accepts it and
is now killed only by `MalformedFraming`. This is public PCAPNG framing
behavior, is plausible for a hand-written scanner, and contributes a distinct
equality boundary rather than another truncation fixture. The artifact changed,
all patch-state checks were restarted, and calibration remained 0/10.

No mutant passes the final focused suite, so there is no final-suite survivor
to carry into the complete pre-existing suite.

## Legitimate architectures and rejected probes

The tests permit buffered or streaming copying, a direct block scanner or a
structured C++ model, and any internal representation that produces the
public block relationships. They require retention of all IDBs as the public
policy but do not require the reference scanner, private vendored C changes,
or a particular state machine.

The audit rejected tests for Zstd support, IDB pruning/remapping, merging,
packet editing, atomic publication, semantic interpretation of Custom Option
payloads, arbitrary unknown predicates, extra endian permutations without a
new boundary, exact log text, private LightPcapNg internals, and the crashing
ineligible C route. Those are excluded scope, private implementation choices,
duplicates, or unsupported by repository/trajectory evidence.

Three legitimate PcapPlusPlus participant trajectories now exist. All used raw
section scanners, but differed in buffering, stream-offset planning, and
staged-output details. Replayed against L2, all three pass the eight unchanged
or newly exposed copy/filter scenarios and fail only `MalformedOptions`. This
supports the new structural framing boundary without disqualifying their
otherwise legitimate architectures. Railway trajectories informed the
original size-risk decision, not hidden format predicates.

## Patch states and full-suite evidence

Fresh worktrees at the immutable source pin accepted `test.patch`
alone, `solution.patch` alone, test then solution, and solution then test.
Both combined application orders produced git diff SHA-256
`db3330a478c0f034ab0040c571b9d7351bd4c15eafef948107c0b33cfde65263`;
`git diff --check` passed.

| State | Base lane | New lane |
|---|---|---|
| Test only | 69/69 JUnit pass | Nine named JUnit failures with the missing-method compiler diagnostic; every registered new test is represented |
| Solution only | `Packet++Test` 259/259; `Pcap++Test` 69 passed, zero failed, 44 skipped | Not present by design |
| Test + solution | 69/69 JUnit pass | 9/9 CTest/JUnit pass |

The exact solution also passed the complete applicable upstream inventory:
`Packet++Test` 259/259 and `Pcap++Test` 69 passed, zero failed, 44 skipped.
The frozen package uses `--network none` and excludes the repository's
environment-dependent `live_device` group; it does not hide a product
regression.

## Predecessor Dockerfile `:latest` re-freeze

Changing only the Dockerfile's first line caused a mandatory exact-version
restart. The permitted tag resolved to the same audited base digest. Fresh
worktrees accepted all four patch states, both combined patch orders remained
byte-identical, and `git diff --check` passed. Its complete combined diff,
including then-untracked added harness files, was
`ae7e6fb36c7eb753dc1f231454ef915b81d8727250b7bcebf33d37419a51ff4d`.

The patch-state matrix above was rerun against image
`sha256:d49c554406aeb41f9987c93dfd23637826a4318b31bd54bf32ed8e87a8220d71`
with the same behavioral results; its predecessor converter represented
test-only/new as one generic build failure rather than six named failures.
All 15 listed mutants were restored from the exact reference, changed one at
a time, compiled successfully, and were killed by the six focused entities.
No focused survivor required full-suite escalation. After restoration, the
reference passed 6/6 again.

Raw JUnit, base logs, and the mutation result ledger are retained under
`verification/dockerfile-latest-refreeze/`. Current local calibration is 0/2
and platform calibration is 0/10.

## 2026-07-31 harness-compatibility re-freeze

Review identified two harness issues in the predecessor:

- `ElementTree.indent` required Python 3.9 or newer; and
- test-only/new represented the missing method as one generic harness failure,
  so wrapper accounting reported all six registered new tests as missing.

The converter now accepts repeated `--expected-test` names and emits one
failed testcase for each name when the target cannot build. The formatting
call was removed. A Python 3.8 container compiled and executed the converter,
which produced six named failures and returned nonzero for a simulated build
failure.

The prompt removed logging-convention wording and one omnibus exclusion
sentence. These are prose-only reductions: `solution.patch`, reference
behavior, test scenarios, and behavioral assertions are unchanged.

The complete patch-state matrix was rerun. Both application orders have
complete diff SHA-256
`b379ccdd1af901e72b6e2a605f470d8ead4b219151162d69c98f1406a05938ff`.
All 15 mutants compiled separately and were killed by the focused suite; the
restored reference passed 6/6. No focused survivor required full-suite
escalation. Evidence is retained under
`verification/harness-compatibility-refreeze/`. Current local calibration is
0/2 and platform calibration is 0/10.

## 2026-07-31 byte-for-byte prompt re-freeze

The public prompt now ends the accepted-packet requirement at
“byte-for-byte” and removes the redundant enumeration of fields and options.
Exact preservation remains public, and `StructureAndFiltering` still compares
the complete expected output byte-for-byte. No test, reference, or behavioral
oracle changed.

For the new `meta.md` SHA-256
`41706d1f2289434f91a7625b26da843b71b42ba945b75a8ced93d77db598b6fa`,
all four patch states passed `git diff --check`; both combined orders remained
byte-identical at complete diff SHA-256
`b379ccdd1af901e72b6e2a605f470d8ead4b219151162d69c98f1406a05938ff`.
Test-only/base passed 69/69, test-only/new emitted all six registered failures,
combined/base passed 69/69, combined/new passed 6/6, and solution-only passed
Packet++Test 259/259 plus Pcap++Test 69 passed, zero failed, 44 skipped.

All 15 listed mutants compiled independently and were killed by the focused
suite. The restored reference rebuilt and passed 6/6, leaving no survivor for
full-suite escalation. Raw evidence is retained under
`verification/byte-for-byte-prompt-refreeze/`. The edit creates a new
immutable version, so current calibration is local 0/2 and platform 0/10.

## 2026-07-31 L2 multi-interface and option-framing re-freeze

External review identified two public-behavior survivors in the predecessor:
index-zero/first-IDB-only implementations, and removal of a standardized
do-not-copy Custom Option from an otherwise retained block. The revised suite
isolates those requirements in `InterfaceSelection` and `OptionPreservation`.
It also adds the specification-backed `MalformedOptions` boundary for
block-bounded, padded option fields and NRB records in retained standardized
blocks.

The reference now has 253 raw production additions across two files and 231
non-comment, non-blank additions. This clears the revised 200-effective-LOC
floor through public validation behavior rather than comments, duplicated
fixtures, or a private architecture.

Fresh exact worktrees accepted all four patch states. Both combined orders were
byte-identical at complete diff SHA-256
`db3330a478c0f034ab0040c571b9d7351bd4c15eafef948107c0b33cfde65263`;
all states passed `git diff --check`. Test-only/base passed 69/69,
test-only/new emitted all nine registered failures, combined/base passed
69/69, combined/new passed 9/9, and solution-only passed `Packet++Test`
259/259 plus `Pcap++Test` 69 passed, zero failed, 44 skipped.
The exact converter also compiled and emitted the same nine named
build-failure cases under Python 3.8 without `ElementTree.indent`.

All 21 isolated mutants compiled. The 15 predecessor modes and six new modes
were killed by the focused suite, and the restored exact reference passed 9/9.
The new modes have deliberately narrow results:

- reject nonzero EPB references, retain only the first IDB, and filter every
  EPB through interface 0 each fail only `InterfaceSelection`;
- remove a do-not-copy Custom Option from a retained IDB fails only
  `OptionPreservation`; and
- accept an overrun option or overrun NRB record each fails only
  `MalformedOptions`.

There was no focused survivor to escalate through the full pre-existing suite.
The complete suite was nevertheless run on the exact reference as the
patch-state compatibility check above.

The two prior local `gpt-5.6-sol` patches and the new Nova platform patch all
apply cleanly with the L2 tests. Each passes eight of nine focused scenarios,
including `InterfaceSelection` and `OptionPreservation`, and fails only
`MalformedOptions`. These are replayed legitimate implementations, not current
L2 calibration runs; the L2 counters are local 0/2 and platform 0/10.

Raw JUnit, upstream-suite logs, mutation results, and trajectory-replay JUnit
are retained under `verification/l2-interface-option-refreeze/`.

## 2026-07-31 current-filter prompt re-freeze

External review removed the discoverable phrase “with `setFilter()`” from the
public description. The method now simply uses the reader's current packet
filter. No test, reference behavior, method signature, or discriminator
changed, but immutable-version policy restarted the audit.

For `meta.md` SHA-256
`22641f52eb9652c9458166ed036dda5f526a3615dbc12cb42ad4a3ef832fd97d`,
fresh executions produced:

- test-only/base 69/69 and all nine named test-only/new failures;
- combined/base 69/69 and combined/new 9/9;
- solution-only `Packet++Test` 259/259 and `Pcap++Test` 69 passed, zero
  failed, 44 skipped;
- byte-identical combined patch orders at complete diff SHA-256
  `db3330a478c0f034ab0040c571b9d7351bd4c15eafef948107c0b33cfde65263`;
  and
- nine simulated named build failures under Python 3.8.

All four states passed `git diff --check`. All 21 isolated mutants compiled and
were killed by the focused suite; the restored reference passed 9/9. There was
no focused survivor to escalate through the full pre-existing suite, which the
exact solution had already passed in the solution-only lanes above.

Raw evidence is retained under
`verification/current-filter-prompt-refreeze/`. Current calibration remains
local 0/2 and platform 0/10.

## 2026-07-31 L3 option-termination re-freeze

The L2 working-pool batch passed 4/4, so it is retired. Before changing the
suite, all four solution patches, evaluations, test logs, and representative
retained trajectories in `agent-runs2/` were reviewed. Three scanners
required an explicit `opt_endofopt` after every nonempty option list; one
accepted a valid list ending at the block boundary. Every prior filter fixture
used `tcp`. External review separately identified missing malformed-SPB,
SHB/ISB/NRB-option, and SHB-minor-version coverage.

### Current requirement-to-oracle map

| Participant-facing requirement | Strongest current behavioral test |
|---|---|
| Add the documented const public method | The new target compiles a call through `PcapNgFileReaderDevice`; test-only/new emits all 11 named missing-method failures. |
| Use the reader's current filter | `FilterState` uses a non-TCP expression over distinguishable TCP and UDP EPBs and SPBs. |
| Work closed or open without changing read position | `ReaderLifecycle` copies before, during, and after reader use and verifies the next packet and comment. |
| Preserve every section, byte order, local interface namespace, and all ordered IDBs | `StructureAndFiltering` spans opposite-endian sections; `InterfaceSelection` uses two differently typed IDBs per section, Interface ID 1, and section-local numeric reuse. |
| Filter EPBs through their referenced interface and SPBs through local ID 0 | `InterfaceSelection`, `FilterState`, and `NoMatchingPackets` make both packet families and link-type selection observable. |
| Copy accepted packets byte-for-byte | Complete expected-file comparisons in `StructureAndFiltering`, `OptionPreservation`, and `OptionTermination` preserve raw accepted blocks. |
| Retain ordered non-packet blocks, omitting only complete `0x40000BAD` blocks | `StructureAndFiltering` and `NoMatchingPackets` interleave NRB, ISB, DSB, both Custom Block policies, and unknown blocks. |
| Do not interpret or remove options inside retained blocks | `OptionPreservation` exact-copies standardized copyable and do-not-copy Custom Options. |
| Accept valid option framing at block end | `OptionTermination` uses nonempty padded option lists without explicit end markers in SHB, IDB, EPB, ISB, NRB, and DSB across both byte orders. |
| Rewrite finite section lengths and preserve `-1` | Exact output comparison spans one finite and one unspecified-length section. |
| Validate block framing, BOM, both supported version fields, and section boundaries | `MalformedFraming` includes nonzero trailing mismatch, bad BOM, version 2.0 and 1.1, truncation, and finite-boundary corruption. |
| Validate retained standardized-block option and NRB record framing | `MalformedOptions` independently overruns SHB, IDB, EPB, ISB, NRB record, NRB option, and DSB areas. |
| Validate relevant local references and packet lengths | `MalformedReferences` covers EPB/ISB references and lengths plus both short and extra-payload SPBs. |
| Reject obsolete blocks and input/output failures without replacing the destination on validation failure | `UnsupportedAndIo` plus all malformed suites verify unsupported/missing/compressed input, directory output, and sentinel preservation. |
| Preserve existing behavior | Test-only/base and combined/base run the 69-case offline `Pcap++Test` lane; solution-only also runs all 259 `Packet++Test` cases. |

### Mutants, survivors, and probe decisions

The exact reference was restored before each source mutation. All 28 mutants
changed production code, compiled, and returned nonzero from the 11-test
focused suite. The first 21 repository-grounded modes remain listed above.
Their failure sets broaden only when a new valid fixture observes the same
defect; none survives.

The seven L3 mutants are isolated:

| Mutant | Focused result | Distinct discriminator |
|---|---|---|
| Accept an SPB with extra bytes beyond its implied captured length | Fails only `MalformedReferences` | SPB length equality |
| Skip SHB option validation | Fails only `MalformedOptions` | SHB option-area entry point |
| Skip ISB option validation | Fails only `MalformedOptions` | ISB option-area entry point |
| Validate NRB records but skip the following options | Fails only `MalformedOptions` | NRB post-terminator option area |
| Accept section version 1.1 | Fails only `MalformedFraming` | Supported minor version |
| Require an explicit option terminator after a nonempty list | Fails only `OptionTermination` | Valid block-end list termination |
| Ignore the current filter and hard-code `tcp` | Fails only `FilterState` | Current-filter identity |

There is no final-suite survivor to run through the complete pre-existing
suite. The exact solution nevertheless passed the complete applicable
inventory: `Packet++Test` 259/259 and `Pcap++Test` 69 passed, zero failed,
44 skipped. The earlier weak-trailer survivor and its complete-suite replay
remain documented in the predecessor audit above; no actionable L3 survivor
was concealed by a focused-only failure.

The new probes were accepted because each violated behavior is public,
supported by PCAPNG framing or the current-filter contract, and backed by
either external review or repeated solver behavior. The audit rejected tests
for mandatory atomic replacement, Zstd support, interface pruning, merging,
packet editing, unknown-payload semantics, arbitrary option-code
interpretation, extra endian permutations without a new boundary, and exact
logging. Those would add excluded scope, private implementation detail, or
duplicate an existing discriminator.

### Legitimate and failing solution replay

All four legitimate L2 solutions apply and compile with the L3 suite.
`Nova_Nova_3` passes 11/11. `Nova_Nova_1`, `Nova_Nova_2`, and
`Nova_Nova_4` each pass 10/11 and fail only `OptionTermination`. Buffered,
LightPcapNg-backed, and streaming architectures remain admissible; the split
comes from one public reader behavior rather than a required private scanner.
No malformed-case discriminator is shared by all four replays.

### Exact patch states and immutable identifiers

Fresh worktrees accepted test only, solution only, test then solution, and
solution then test. Every state passed `git diff --check`; the two combined
orders are byte-identical at complete diff SHA-256
`77e0c75abab1b0cc02e773f191087e1af3b8973fb3f6a9698cf4a5819b9f8c3d`.

| State | Base lane | New lane |
|---|---|---|
| Test only | 69/69 pass | All 11 named cases fail because the method is absent |
| Solution only | `Packet++Test` 259/259; `Pcap++Test` 69 passed, zero failed, 44 skipped | Not present by design |
| Test plus solution | 69/69 pass | 11/11 pass |

The converter compiled under Python 3.8 and emitted all 11 named simulated
build failures without `ElementTree.indent`. The restored reference passed
11/11 after the mutation loop.

Current artifact SHA-256 values are:

- `meta.md`:
  `22641f52eb9652c9458166ed036dda5f526a3615dbc12cb42ad4a3ef832fd97d`;
- `test.patch`:
  `6bfafeaa05d84da563cfb54f5b6312ce13fc176eab3080d8ea04fcde382816bc`;
- `solution.patch`:
  `33f96aeb379e074cdddd07383acabccd45aa1d16d02ffe65996d036c9c824b4a`;
- `solution_approach.md`:
  `53cd447171bb1b4edecff2a3667cced20eccd344f29267e8050617434a9b8a0f`;
  and
- `Dockerfile`:
  `70e8b8f853700ac56afb0738fec87c972782041f57336fc442668a8b55bca7ff`.

Source pin and image remain
`0dbbb9c75eb232135f13fdb794318c4da3270ebc` and
`sha256:d49c554406aeb41f9987c93dfd23637826a4318b31bd54bf32ed8e87a8220d71`.
Raw matrix, regression, mutation, Python 3.8, and replay evidence is under
`verification/l3-option-termination-refreeze/`. This is a new immutable
version, so prior outcomes are trajectory replays only; current calibration is
local 0/2 and platform 0/10.

## 2026-07-31 L4 filter/opacity re-freeze

The three completed unhinted L3 runs each passed the base lane and 10/11
focused cases, failing only `OptionTermination`. The fourth run is incomplete.
Before editing tests, the raw trajectories and all compact artifacts were
reviewed and the design gate was recorded in `DESIGN.md`. The option-list
boundary rule is now explicit in the prompt, and three independent valid-input
oracles cover empty filter state and two opacity boundaries.

### Current requirement-to-oracle map

| Participant-facing requirement | Strongest current behavioral test |
|---|---|
| Add the documented const public method | The target compiles calls through `PcapNgFileReaderDevice`; test-only/new emits all 14 named missing-method failures. |
| Use the reader's current filter | `FilterState` selects UDP rather than TCP over distinguishable EPBs and SPBs. |
| Honor default and cleared filter states | `DefaultAndClearedFilter` exact-copies a mixed EPB/SPB capture before filter setup and after `clearFilter()`. |
| Work closed or open without changing read position | `ReaderLifecycle` copies before, during, and after reader use and verifies the next packet and comment. |
| Preserve every section, byte order, local interface namespace, and ordered IDB | `StructureAndFiltering` spans opposite-endian sections; `InterfaceSelection` uses two IDBs per section, Interface ID 1, and numeric reuse. |
| Ignore the IDB reserved field while preserving IDB bytes | `ReservedFieldOpacity` uses `0xa55a` and exact-compares the result. |
| Filter EPBs through their referenced interface and SPBs through local ID 0 | `InterfaceSelection`, `FilterState`, `DefaultAndClearedFilter`, and `NoMatchingPackets` observe both forms and link-type selection. |
| Copy accepted packet blocks byte-for-byte | Complete output comparisons in all valid-copy scenarios preserve raw packet blocks. |
| Retain ordered non-packet blocks, omitting only complete `0x40000BAD` blocks | `StructureAndFiltering` and `NoMatchingPackets` interleave retained metadata, both Custom Block policies, and unknown blocks. |
| Keep options inside retained blocks untouched | `OptionPreservation` exact-copies standardized copyable and do-not-copy Custom Options. |
| Treat unknown and local-use payloads as opaque | `LocalUseOpacity` exact-copies `0x80000001` with a body that is invalid if misread as TLVs. |
| Accept an option list ending at its owning block boundary | `OptionTermination` spans SHB, IDB, EPB, ISB, NRB, and DSB in both byte orders without an explicit marker. |
| Rewrite finite section lengths and preserve `-1` | Exact expected output spans one finite and one unspecified-length section. |
| Validate outer framing, BOM, supported version, and section boundaries | `MalformedFraming` covers nonzero trailer mismatch, bad BOM, versions 2.0 and 1.1, truncation, and finite boundaries. |
| Validate retained standardized option and NRB record framing | `MalformedOptions` overruns every standardized option entry point and an NRB record. |
| Validate local references and packet lengths | `MalformedReferences` covers EPB/ISB references, EPB lengths, and both short and extra-payload SPBs. |
| Reject obsolete blocks and input/output failures without replacing a destination after validation failure | `UnsupportedAndIo` and all malformed suites verify unsupported, missing, compressed, or invalid input, output failure, and sentinel preservation. |
| Preserve existing behavior | Base lanes run 69 offline Pcap++ cases; solution-only also runs all 259 Packet++ cases. |

### Incorrect implementations, survivors, and probe decisions

All 28 previously recorded repository-grounded mutants were rerun against the
exact L4 artifacts. They cover wrong Custom Block policy, skipped EPB/SPB
filtering, section/interface state leakage, weak block framing, invalid local
references, unsupported obsolete packets, premature destination truncation,
reader lifecycle coupling, SPB snap-length mistakes, endian mistakes, packet
normalization, metadata loss, first-IDB/nonzero-ID shortcuts, Custom Option
removal, option/record overruns, uncovered standardized option entry points,
minor-version acceptance, explicit-terminator dependence, and a hard-coded
`tcp` filter. Every mutation compiled and returned nonzero from the focused
suite.

Three additional plausible modes were isolated from the review and trajectory
evidence:

| Mutant | Focused result | Distinct discriminator |
|---|---|---|
| Reject copy when the BPF expression is empty | Fails only `DefaultAndClearedFilter` | Established empty-filter state |
| Require the IDB reserved field to be zero while reading | Fails only `ReservedFieldOpacity` | Writer rule versus reader opacity |
| Parse local-use block data as standardized options | Fails only `LocalUseOpacity` | Unknown/private payload opacity |

All 31 mutants were restored from the exact reference one at a time, compiled,
and were killed. The restored reference rebuilt and passed 14/14. There is no
final focused survivor to run through the complete pre-existing suite. The
exact reference nevertheless passed `Packet++Test` 259/259 and `Pcap++Test`
69 passed, zero failed, 44 skipped. The historical weak-trailer survivor and
its full-suite replay remain recorded above; no current survivor is hidden by
a focused-only result.

The audit rejected more malformed option permutations, extra byte-order
copies, atomic publication, Zstd support, IDB pruning/remapping, merging,
packet editing, exact log text, and payload-specific grammars. They duplicate
an existing family, add excluded scope, or depend on private implementation
choices. The new probes use valid captures, pass the reference, and do not
require buffering, streaming, LightPcapNg, or the reference scanner.

### Legitimate and failing solution replay

All three completed L3 solutions compile with the exact L4 suite. In raw form,
Nova 1 fails `OptionTermination` and `LocalUseOpacity`; Nova 2 fails
`OptionTermination` and `ReservedFieldOpacity`; Nova 3 fails only
`OptionTermination`. Every implementation passes `DefaultAndClearedFilter`.

Since the prompt now states the option-list rule, a second replay applies only
the corresponding terminal `false` to `true` correction. Nova 1 then fails
only `LocalUseOpacity`, Nova 2 fails only `ReservedFieldOpacity`, and Nova 3
passes 14/14. This projected 1/3 split admits buffered and streaming designs
and distributes failure across separate public invariants. The raw and
normalized JUnit reports are retained in the L4 evidence directory.

### Exact patch states and immutable identifiers

Fresh worktrees accepted test only, solution only, test then solution, and
solution then test. Every state passed `git diff --check`; both combined
orders are byte-identical at complete diff SHA-256
`ec0506fb5c0cd5533ed6414b702f1df1dcf3509ff85b6f01d9aae77cd634b9a8`.

| State | Base lane | New lane |
|---|---|---|
| Test only | 69/69 pass | All 14 named cases fail because the method is absent |
| Solution only | `Packet++Test` 259/259; `Pcap++Test` 69 passed, zero failed, 44 skipped | Not present by design |
| Test plus solution | 69/69 pass | 14/14 pass |

The converter compiled under Python 3.8 and emitted all 14 named simulated
build failures without `ElementTree.indent`. Current artifact SHA-256 values
are:

- `meta.md`:
  `5f09840a054adc4f32c47621d5d626cd3e034204ddb81b16379aa2d3ea593afa`;
- `test.patch`:
  `f5a63adbc9338e297ec673f0c92ab6b2d3719771b9d586eb52a027375edbcb6c`;
- `solution.patch`:
  `33f96aeb379e074cdddd07383acabccd45aa1d16d02ffe65996d036c9c824b4a`;
- `solution_approach.md`:
  `85cbffb348f051caf676838ad904d7f9b0184f53dc0ecd2aec9f0fad0888bcfb`;
  and
- `Dockerfile`:
  `70e8b8f853700ac56afb0738fec87c972782041f57336fc442668a8b55bca7ff`.

The source pin and image remain
`0dbbb9c75eb232135f13fdb794318c4da3270ebc` and
`sha256:d49c554406aeb41f9987c93dfd23637826a4318b31bd54bf32ed8e87a8220d71`.
Raw matrix, regression, mutation, Python 3.8, and replay evidence is under
`verification/l4-filter-opacity-refreeze/`. L4 is a new immutable version, so
calibration restarts at local 0/2 and platform 0/10.

## 2026-07-31 L5 minor-version fairness re-freeze

Fairness review found that L4's otherwise-valid SHB 1.1 rejection was not
supported by the prompt or repository. The trajectory gate was rerun before
editing tests. A legitimate retired L2 pass and an L3 near-pass both enforced
minor zero, but both were responding to the same prompt/test policy; they are
not independent authority. Bundled LightPcapNg stores and writes arbitrary
minor values without an exclusivity check.

### Current requirement-to-oracle map

| Participant-facing requirement | Strongest current behavioral test |
|---|---|
| Add the documented const public method | The target compiles calls through `PcapNgFileReaderDevice`; test-only/new emits all 14 named missing-method failures. |
| Use the reader's current filter, including empty and cleared states | `FilterState` selects UDP; `DefaultAndClearedFilter` exact-copies mixed EPB/SPB input before filter setup and after clearing. |
| Work closed or open without changing read position | `ReaderLifecycle` copies before, during, and after reader use and verifies the next packet and comment. |
| Preserve sections, byte order, local interface namespaces, and ordered IDBs | `StructureAndFiltering` spans opposite-endian sections; `InterfaceSelection` uses ID 1 and numeric reuse. |
| Ignore the IDB reserved field while preserving its bytes | `ReservedFieldOpacity` uses `0xa55a` and exact-compares the result. |
| Filter EPBs through their referenced interface and SPBs through local ID 0 | `InterfaceSelection`, `FilterState`, `DefaultAndClearedFilter`, and `NoMatchingPackets` observe both packet forms. |
| Copy accepted packets and retained blocks byte-for-byte | Every valid-copy scenario compares the complete expected output. |
| Omit only complete `0x40000BAD` blocks and keep retained-block options untouched | `StructureAndFiltering`, `NoMatchingPackets`, and `OptionPreservation` distinguish complete-block policy from option opacity. |
| Treat unknown and local-use payloads as opaque | `LocalUseOpacity` retains a local-use block whose body is invalid if misread as TLVs. |
| Accept an option list ending at its block boundary | `OptionTermination` spans all retained standardized option areas in both byte orders. |
| Rewrite finite section lengths and preserve `-1` | Exact expected output spans finite and unspecified sections. |
| Validate outer framing, BOM, supported major version, and section boundaries | `MalformedFraming` covers major version 2, nonzero trailer mismatch, bad BOM, truncation, and finite boundaries; it imposes no exact minor policy. |
| Validate retained standardized option and NRB record framing | `MalformedOptions` overruns every standardized option entry point and an NRB record. |
| Validate local references and packet lengths | `MalformedReferences` covers EPB/ISB references, EPB lengths, and short/extra SPBs. |
| Reject obsolete blocks and I/O failures without replacing a destination after validation failure | `UnsupportedAndIo` and malformed suites verify unsupported or invalid input, output failure, and sentinel preservation. |
| Preserve existing behavior | Base lanes run 69 offline Pcap++ cases; solution-only also runs all 259 Packet++ cases. |

### Mutants, fairness retirement, and survivors

Stable mutant IDs 1-25 and 27-31 were restored from the exact reference one at
a time. These 30 active repository-grounded implementations all changed
production code, compiled, and returned nonzero from the focused suite. The
three newest opacity/filter-state mutants still fail only their intended
scenarios. The restored reference rebuilt and passed 14/14.

L4 mutant 26—accept SHB minor version 1.1—is not an active mutant in L5.
Acceptance is the corrected behavior, so counting it as a killed false
positive would preserve the unfair policy. Its stable identifier is retained
as an explicit retired line in `mutation-results.txt` and explained in
`retired-minor-mutant.md`.

No active focused survivor remains for complete-suite escalation. The exact
solution nevertheless passes `Packet++Test` 259/259 and `Pcap++Test` 69
passed, zero failed, 44 skipped. An audit-only valid fixture with SHB 1.1 also
builds and exact-copies successfully. It is evidence for the corrected
reference, not a hidden minor-version discriminator.

The rejected-probe ledger remains unchanged except for minor-version policy:
no other minor permutation replaces the retired rejection. Extra malformed
option cases, endian copies, atomic publication, Zstd, pruning/remapping,
merging, editing, logging text, and private payload grammars remain duplicate,
excluded, or implementation-specific.

### Legitimate solution replay

All three completed L3 solutions compile with L5. Raw Nova 1 fails
`OptionTermination` and `LocalUseOpacity`; raw Nova 2 fails
`OptionTermination` and `ReservedFieldOpacity`; raw Nova 3 fails only
`OptionTermination`. After applying only the prompt-stated option-boundary
correction, Nova 1 and Nova 2 fail their different opacity scenarios and Nova
3 passes 14/14. Removing the unfair minor-version rejection neither creates a
shared failure nor changes this projected 1/3 split.

### Exact patch states and immutable identifiers

Fresh worktrees accepted test only, solution only, test then solution, and
solution then test. Every state passed `git diff --check`; both combined
orders are byte-identical at complete diff SHA-256
`4f572abf252ecb840e5a1759646b26a9ddab692d4946fb90023ed935e94db666`.

| State | Base lane | New lane |
|---|---|---|
| Test only | 69/69 pass | All 14 named cases fail because the method is absent |
| Solution only | `Packet++Test` 259/259; `Pcap++Test` 69 passed, zero failed, 44 skipped | Not present by design |
| Test plus solution | 69/69 pass | 14/14 pass |

The converter compiled under Python 3.8 and emitted all 14 simulated named
build failures. Current artifact SHA-256 values are:

- `meta.md`:
  `10b0b7ef006ef2d1ba8368dca777109105fe672294e6057b0de56a8245ebb863`;
- `test.patch`:
  `4727aaa1969cab52bcbd9156ed7b9dd9ee38af396403d15e42353d0ef4fecec4`;
- `solution.patch`:
  `3d8245aa3f0e06594d3bf290fcd3f633e97ffe73e17c4ea4555c713d9538b44a`;
- `solution_approach.md`:
  `775d8beed8a5a5f9abd89c7f36cc4a8f718b26a040adcf9ccd786733a3b5d332`;
  and
- `Dockerfile`:
  `70e8b8f853700ac56afb0738fec87c972782041f57336fc442668a8b55bca7ff`.

Source pin and image remain
`0dbbb9c75eb232135f13fdb794318c4da3270ebc` and
`sha256:d49c554406aeb41f9987c93dfd23637826a4318b31bd54bf32ed8e87a8220d71`.
Evidence is under `verification/l5-minor-version-fairness-refreeze/`. L4 is
retired without calibration, so L5 starts at local 0/2 and platform 0/10.

## 2026-07-31 L6 filter/validation-order re-freeze

Exact L5 calibrated at 7/10 in `agent-runs4/`, above the 50% cap. Before any
test edit, the design protocol and calibration strategy were reread; compact
history, all ten evaluations and patches, and representative raw pass and
failure trajectories were inspected. No broad failure exists: every run is a
substantive scanner, every baseline passes, and the largest L5 focused failure
is five of fourteen groups.

### Requirement map and distinct probes

The current requirement table above is updated for all L6 behavior. Three
boundaries changed or became directly observable:

| Requirement | Strongest exact L6 oracle | Mutation isolation |
|---|---|---|
| The specified method is const-qualified | `StructureAndFiltering` calls through a const reference | Non-const-only production API builds `Pcap++`; harness compile fails at that call |
| An identical input/output spelling can succeed | `InPlaceReplacement` filters a DSB-free TCP/UDP EPB/SPB capture to the same path | Early equal-path rejection fails only this scenario |
| Option framing applies to retained standardized blocks | `DiscardedPacketOptions` drops a bounded UDP EPB with a malformed option area and exact-compares the retained output | Pre-filter EPB option validation fails only this scenario |

The discarded EPB remains safe to inspect: outer and trailing block lengths,
section boundary, Interface ID, captured/original lengths, and captured-data
bounds are valid. Only bytes after its packet data are malformed. This probe
therefore does not ask implementations to accept unsafe packet framing.

The first same-path prototype reused the complex DSB fixture. It made Nova 3
and 5 fail a second scenario for their existing DSB parser defect, so it was
rejected as a coupled discriminator. The final fixture uses the independent
filter-state capture; all ten historical patches pass it. Tests for temporary
file naming, atomic rename, filesystem aliases, timestamp predicates, further
DSB permutations, and private unknown-block grammars were rejected as private,
duplicate, or unsupported.

### Exact mutation audit

Stable active mutants 1-25 and 27-31 were restored from the exact L6
reference one at a time. All 30 built and returned nonzero from the focused
suite. Historical ID 26 remains retired because arbitrary minor preservation
is correct. Three new repository/trajectory-grounded modes were then isolated:

| ID | Incorrect implementation | Result |
|---:|---|---|
| 32 | Remove `const` from declaration and definition | Production `Pcap++` build succeeds; focused target fails to compile |
| 33 | Reject `outputFileName == m_FileName` | Builds; only `InPlaceReplacement` fails |
| 34 | Validate every EPB option area before filtering | Builds; only `DiscardedPacketOptions` fails |

The reference was restored, rebuilt, and passed 16/16. No compile-valid mutant
survives the focused suite, so no new survivor required escalation through the
pre-existing inventories. Those complete inventories nevertheless pass on the
exact reference: `Packet++Test` 259/259 and `Pcap++Test` 69 passed, zero failed,
44 skipped. A zero-survivor result is evidence only for these 33 active modes.

### Ten-solution replay and calibration projection

All ten exact L5 patches compile against L6. Every patch passes the const call
and `InPlaceReplacement`. Nova 1, 2, 4, 8, and 9 fail only
`DiscardedPacketOptions`; Nova 6 and 7 pass 16/16. Nova 3 and 5 fail that new
case plus their four existing DSB-dependent groups. Nova 10 passes the new
case but retains its five multi-section/DSB failures. The projection is 2/10
and failure signatures are distributed across validation ordering, DSB
layout, and multi-section behavior rather than a single shared case. These are
retrospective replays, not L6 calibration runs.

### Exact patch states and immutable identifiers

Fresh states accepted test only, solution only, test then solution, and
solution then test. Every state passed `git diff --check`; both combined orders
are byte-identical at complete diff SHA-256
`a11d44fbc8e21720c7a0b26f3bdf52107b22c4b1a21dc8e1b9d5fe6fd74621ac`.

| State | Base lane | New lane |
|---|---|---|
| Test only | 69/69 pass | All 16 named cases fail because the method is absent |
| Solution only | `Packet++Test` 259/259; `Pcap++Test` 69 passed, zero failed, 44 skipped | Not present by design |
| Test plus solution | 69/69 pass | 16/16 pass |

The converter executed under Python 3.8 and emitted all 16 simulated named
build failures. The reference has 254 raw and 232 strict effective production
additions across two files. Exact artifact SHA-256 values are:

- `meta.md`:
  `d527f61ce418cd97a765c3b2705961db1b76b6e6beddeae1f358ef114392630e`;
- `test.patch`:
  `00d7213a423facc6ca47b43d2ba5eb2f5365e303eac9e1a45ae002c26d54cfe8`;
- `solution.patch`:
  `1f228c09ddab23d64d57791964c8f33008565560cc84fc56e686b4cf3ab514bf`;
- `solution_approach.md`:
  `c00e34a724b0e84f362ed59bacb31150e9f26c6c020c1f9bd52fc79921a3d87b`;
  and
- `Dockerfile`:
  `70e8b8f853700ac56afb0738fec87c972782041f57336fc442668a8b55bca7ff`.

Source pin and built image remain
`0dbbb9c75eb232135f13fdb794318c4da3270ebc` and
`sha256:d49c554406aeb41f9987c93dfd23637826a4318b31bd54bf32ed8e87a8220d71`.
Evidence is under `verification/l6-filter-validation-order-refreeze/`. Because
prompt, reference, and tests changed, L5 is retired at 7/10 and L6 calibration
starts at local 0/2 and platform 0/10.
