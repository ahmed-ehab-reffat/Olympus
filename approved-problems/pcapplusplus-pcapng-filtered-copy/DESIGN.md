# DESIGN - PcapPlusPlus section-aware PCAPNG filtered copy

Status: `exact L6 accepted on 2026-08-01 after trajectory-informed hardening,
patch-state verification, and the 33-active-mutant false-positive audit`.

Repository: `seladb/PcapPlusPlus` at
`0dbbb9c75eb232135f13fdb794318c4da3270ebc`.

Primary language and license: C++ / Unlicense.

Task type: `feature request`.

## Public contract and repository evidence

Add a public filtered-copy operation to `PcapNgFileReaderDevice`. It uses the
reader's current device filter, including the established match-all empty
state, to copy its source to a plain, uncompressed PCAPNG destination. The
operation keeps or drops packets without reconstructing retained blocks.

The operation must:

- retain every section in its original byte order and preserve each
  section-local Interface ID namespace;
- retain all Interface Description Blocks, so retained packet and statistics
  references do not require remapping;
- apply the current repository-native filter to Enhanced and Simple Packet
  Blocks using the owning section's interface link type;
- preserve every accepted packet block byte-for-byte;
- preserve copyable non-packet and unknown blocks byte-for-byte and in relative
  order;
- omit standardized do-not-copy Custom Blocks (`0x40000BAD`);
- recompute a finite SHB section length after blocks are dropped while
  preserving `-1` unspecified lengths; and
- reject malformed framing, invalid relevant Interface IDs, unsupported
  obsolete Packet Blocks, and output failures through ordinary file-device
  `false`/logging behavior.

The method is additive and source-compatible:

```cpp
bool PcapNgFileReaderDevice::copyFiltered(
    const std::string& outputFileName) const;
```

It is independent of `open()` and current read position. Accepted packets
cannot be edited or replaced.

Zstd, interface pruning/remapping, merging, anonymization, packet editing,
atomic publication, generalized repair, and do-not-copy Custom Option
interpretation are out of scope. Obsolete Packet Blocks are rejected rather
than silently copied without filtering.

Repository evidence:

- the current reader exposes packets and comments but skips all other blocks;
- the writer synthesizes one section and fixes packet Interface ID to zero at
  the C++ boundary;
- the ordinary public loop reproduced a 172-byte one-section output from the
  owned 1,396-byte two-section input;
- retaining all IDBs is the smallest compatible policy and makes remapping
  unnecessary; and
- a raw C++ section scanner can use the existing BPF wrapper without exposing
  vendored C types.

The primary format authority is
`draft-ietf-opsawg-pcapng-05` (2026-03-17), SHA-256
`43f522a9c61057cb93887f99f78ecd36290d1911a920578947322fd20459022d`.

## Trajectory-informed design gate

The startup searches covered `problems/README.md`,
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, all PcapPlusPlus
candidate records, the fq, go-mp4, noodles, 3D Tiles, Calamine, and Railway
compact records, and the Railway raw-run archive. There is no prior
PcapPlusPlus solver trajectory or local capture-rewrite problem.

The original candidate gate inspected the closest format trajectories:

- 3D Tiles run 3, a legitimate staged-publication pass;
- 3D Tiles run 2, a near-pass missing the public error boundary; and
- the cold noodles trajectory, which legitimately reduced many format cases
  to one event stream and canonical writer.

The user reopened this candidate on 2026-07-30 because Railway demonstrates
that a small reference can substantially underpredict solver work. The
following raw Railway members were inspected directly from
`archive/railway-deployment-bundle/agent-runs.tar.gz`, including trajectories,
patches, evaluations, and test outcomes:

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate participant architecture | Railway `agent-runs7/Nova_Nova_3` | Later accepted after removal of an over-constrained open-phase oracle; patch had 857 additions across six production files | The solver traced upload, auth, telemetry, and source selection; created a strict controller; buffered verified bytes; and performed extensive proactive CLI checks. It missed only the retired open-to-first-metadata interval. |
| Near-pass | Railway `agent-runs4/Nova_Nova_1` | 474/474 base, 27/28 focused; about 873 additions across six production files | It independently built descriptor-backed snapshots, strict schema, early offline CLI routing, and verified archive bytes, but sampled metadata only after open. |
| Broadest representative failure | Railway `agent-runs4/Nova_Nova_3` | 474/474 base, 26/28 focused; about 916 additions across six production files | It used the same substantive architecture but also chose the wrong source root under token/environment targeting. |

Railway's immediate preview was 81 production additions; its accepted
reference reached 638 additions across six files, and representative solver
patches exceeded 850 additions. That evidence invalidates a policy of rejecting
PcapPlusPlus solely from its 178-line reference. It does not prove this task is
long-horizon: PCAPNG still has a stronger raw-copy convergence risk. Actual
PcapPlusPlus solver patches must decide the question.

### 2026-07-31 harness-compatibility revision gate

Before revising `test.patch`, the design protocol and current calibration
strategy were reread and the two saved PcapPlusPlus local trajectories,
solution patches, JUnit outputs, and run summaries were revisited. Both are
legitimate passes using distinct raw-scanner storage strategies. No
PcapPlusPlus near-pass or broad failure exists.

External review found that test-only/new correctly fails to compile without
the public method, but the wrapper conversion represented that one build
failure as a generic `Pcap++Test.Harness` case. Consequently, a wrapper that
expects the six registered `PcapNgCopy.*` entities reported all six as
missing. This is a harness-accounting defect, not a missing behavioral
discriminator: combined/new already executes and passes all six independent
CTest entities.

The fair correction is limited to failure reporting:

- when the new target cannot build, emit one failed JUnit testcase for each
  registered `PcapNgCopy.*` entity, carrying the same compiler log;
- leave successful CTest execution and every behavioral assertion unchanged;
  and
- remove reliance on Python 3.9's `ElementTree.indent`, since formatting is
  irrelevant to JUnit semantics.

The public prompt also drops two reviewer-identified prose-only clauses:
logging-convention wording and an omnibus final exclusion sentence. Neither
change alters reference behavior or a hidden oracle. The current
discriminator ledger therefore remains complete and no new hidden behavior is
introduced.

### 2026-07-31 byte-for-byte prose-reduction gate

Before changing the prompt again, the design protocol, current calibration
strategy, existing two legitimate PcapPlusPlus pass trajectories, and current
discriminator ledger were reread. There is still no near-pass or broad
PcapPlusPlus failure to add, and the raw-scanner architectures in both passes
already interpreted “byte-for-byte” as exact preservation of the retained
block.

The field-by-field examples after that phrase are therefore redundant rather
than a distinct requirement. Removing them leaves the public byte-fidelity
invariant and its complete-output comparison unchanged. No test, reference
behavior, or hidden oracle changes for this wording-only revision.

### 2026-07-31 L2 multi-interface and option-framing gate

Before revising `test.patch`, the design protocol, updated calibration
strategy, current compact records, both prior local pass trajectories, and the
new platform Nova run under `agent-runs1/Nova_Nova/` were read. The strategy
now accepts one through five solves in ten and requires a 200-effective-LOC
successful median. The new run is another legitimate pass, not a near-pass or
broad failure; neither missing category is available for PcapPlusPlus.

Nova inspected the public reader, LightPcapNg I/O, BPF wrapper link-type
recompilation, build, and tests before implementing. Its production path used
a streaming raw-block scanner, a section-local vector of link type/snapshot
length pairs, and staged destination replacement. It changed two production
files by 427 raw additions, with roughly 267 effective production additions,
and made 54 tool calls. It proactively added an upstream test and ran the
complete no-network suite. It passed all six hidden entities.

The run reinforces the raw-scanner convergence signal but also exposes two
coverage holes confirmed by external review:

- every valid packet fixture still referenced Interface ID zero and every
  section had only one IDB, so an index-zero-only filter or first-IDB-only
  copier could pass despite the public multi-interface contract; and
- the exact-copy fixtures used ordinary and private option codes, but not the
  standardized copyable/do-not-copy Custom Option codes. A block copier that
  wrongly removes a do-not-copy Custom Option while correctly removing a
  complete do-not-copy Custom Block could pass.

Those requirements will be isolated instead of added to the already broad
`StructureAndFiltering` entity:

- `InterfaceSelection` will retain two differently typed IDBs per section,
  filter a valid EPB through nonzero Interface ID 1, and reuse IDs with
  different meanings in the next section;
- `OptionPreservation` will retain standardized copyable and do-not-copy
  Custom Options byte-for-byte inside retained blocks; and
- `MalformedOptions` will exercise a separate parser boundary: public
  Type-Length-Value option and Name Resolution record framing in retained
  standardized blocks.

The last family is the legitimate implementation expansion for L2. The pinned
PCAPNG draft defines discoverable option starts for standard blocks, 32-bit
padding, block-bounded TLVs, and an NRB record terminator. Requiring structural
validation prevents malformed retained output and adds a parser obligation
independent of packet selection, endian reset, or raw-copy policy. It does not
require semantic interpretation of unknown options, removal of Custom Options,
or validation of opaque Custom/unknown block payloads. The reference must clear
the 200-effective-production-LOC floor through this behavior, not comments,
blank lines, duplicated fixtures, or private architecture constraints.

### 2026-07-31 current-filter wording-reduction gate

Before revising the prompt, the design protocol, current L2 design and
discriminator ledger, all three prior legitimate trajectories, and the exact
false-positive record were revisited. There remains no PcapPlusPlus near-pass
or broad failure to add.

External review correctly identifies “with `setFilter()`” as discoverable API
instruction rather than participant-facing behavior. Replacing the sentence
with wording that relies on the reader's current filter preserves the same
contract: every existing implementation and test already observes the filter
state stored by `PcapNgFileReaderDevice`. No method signature, lifecycle rule,
filter semantics, hidden test, reference behavior, or discriminator changes.
This is a prose-only reduction, but it creates a new immutable artifact version
and therefore requires the patch-state and 21-mutant false-positive checks to
be repeated before re-freeze.

## Discriminator ledger

| Observed solver/repository behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| Ordinary Pcap++ packet copy loses all capture structure. | Feed accepted packets into a fresh writer. | Filtering retains sections and copyable non-packet blocks. | Parse input/output independently and compare retained block sequence. | Packet API versus container structure | A raw scanner, structured event model, or repaired parser can pass. |
| LightPcapNg treats byte order/interface state too globally. | Parse later sections using the first section's assumptions. | Each SHB resets byte order and local Interface IDs. | Opposite-endian sections reuse ID 0 with different supported link types. | Section transition | Tests observe format relationships, not a private state machine. |
| Raw copy naturally preserves all packet fields. | Reconstruct packets and normalize ticks/options. | Accepted EPB/SPB bytes remain unchanged. | Compare accepted blocks byte-for-byte and inspect public packets. | Packet fidelity | Both streaming and buffered implementations pass. |
| Blind raw copy retains both Custom codes. | Treat standardized copy policy as opaque. | `0x00000BAD` is retained and `0x40000BAD` omitted. | Interleave both types with a distinct unknown block. | Copy policy | One public standardized distinction, not custom payload parsing. |
| All passing fixtures had one IDB per section even though all three solvers stored an interface collection. | Special-case Interface ID zero, reject valid nonzero EPBs, or retain only the first IDB. | All IDBs remain ordered and EPBs use their referenced section-local interface. | Two differently typed IDBs per section, a matching EPB on ID 1, and ID reuse with different meanings after an SHB. | Interface selection | Exercises a public index/link-type relationship; vectors, maps, streaming, and buffered scanners all pass. |
| Complete Custom Block codes were tested, but Custom Option codes were not. | Apply the complete-block do-not-copy rule inside a retained block. | Options inside retained blocks remain untouched, including do-not-copy Custom Options. | Exact-copy a retained block containing both standardized Custom Option policies. | Block policy versus option opacity | Tests the prompt's explicit distinction without parsing private payload semantics. |
| Every pass copied option bytes opaquely and current malformed probes stop at outer block/packet framing. | Accept a structurally truncated TLV or NRB record and reproduce malformed retained output. | Retained standardized blocks have block-bounded, padded option/record framing. | Independently corrupt IDB/EPB/DSB option lengths and NRB record framing; reference rejects without replacing a sentinel destination. | Inner block framing | Public format structure, distinct from semantic option interpretation and independent of scanner architecture. |
| Three of four unhinted L2 passes require `opt_endofopt`; one correctly accepts the block boundary. | Treat a writer requirement as a reader requirement and reject a valid capture. | A reader accepts a nonempty option list whose final padded field reaches the block boundary without an explicit terminator. | Retain and filter standard blocks with bounded unterminated option lists in both byte orders; compare exact output. | Valid option-list termination | Pinned PCAPNG reader semantics; no scanner, buffering, or publication architecture is prescribed. |
| Every focused fixture configures `tcp`. | Ignore the reader's filter state and hard-code the fixture predicate. | Packet selection uses the reader's current filter expression. | Run a separate capture through a non-TCP filter and compare the inverse packet selection. | Filter state versus packet decoding | Direct public behavior and repository-native BPF state, independent of raw parser structure. |
| Malformed packet length is tested only for EPB even though SPB derives its body length differently. | Validate EPB fields but accept a truncated or oversized SPB. | Both packet block families have consistent captured-data framing. | Independently truncate and extend an SPB while retaining valid outer length fields; reject without replacing a sentinel. | SPB packet-data boundary | Directly stated packet-length validation at a distinct block layout. |
| SHB, ISB, and NRB option areas are parsed by the reference and all L2 passes but not corrupted by tests. | Invoke the option validator only for currently probed block types. | Every retained standardized option area is block-bounded. | Overrun each omitted option area independently after a valid fixed prefix/NRB terminator. | Option entry-point coverage | Exercises three public offsets, not semantic option payload interpretation. |
| The L2 reference checks only SHB major version; all four participant passes check 1.0. | Accept an unsupported 1.x section while claiming supported-version validation. | Supported Section Header version is exactly 1.0. | Change the minor field to 1 and reject before destination replacement. | Section-version pair | Fixes a reference/test asymmetry using the pinned draft's current version. |
| Railway solvers greatly exceeded a small preliminary implementation. | Infer solver horizon directly from reference LOC. | Experimental acceptance is based on successful solver patch medians. | Freeze one honest package and measure files, messages, and strict effective LOC for every success. | Calibration methodology | The task is neither padded nor rejected by proxy. |

## Clause-to-test coverage

| Public requirement | Planned observable test | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Public API and lifecycle | Compile and invoke the documented method before/after an ordinary read | API absent | Additive method works without changing reader position | Existing file-device ownership model |
| Sections, endian, local interfaces | `StructureAndFiltering` covers section transitions; `InterfaceSelection` uses two IDBs, nonzero EPB references, and reused IDs | High-level copy flattens/loses the second section; index-zero shortcuts mis-filter | Exact independent parse and retained bytes pass | PCAPNG SHB/IDB rules |
| EPB/SPB filter and fidelity | Keep TCP and drop UDP across Ethernet and SLL; compare retained raw blocks | Packet path reconstructs | Accepted blocks exact | Existing BPF vocabulary and format fields |
| Metadata and order | Interleave NRB, ISB, DSB, Custom, and unknown blocks | Reader skips them | Retained sequence exact | Standard block framing/copy behavior |
| Custom copy policy | Include both standardized Custom codes | Blind copy keeps both | Only do-not-copy blocks absent | Pinned PCAPNG draft |
| Custom Option opacity | `OptionPreservation` places copyable and do-not-copy Custom Options inside retained blocks | A block-policy shortcut removes the latter | Complete retained bytes are unchanged | Public block/option policy distinction |
| Inner option/record framing | `MalformedOptions` corrupts bounded TLV and NRB-record layouts in retained standard blocks | Raw outer-block scanner accepts and reproduces malformed content | Reject and preserve sentinel destination | Pinned option and NRB formats |
| Valid option termination | `OptionTermination` omits `opt_endofopt` only when the final padded option reaches the owning block boundary | Three of four L2 passes reject this valid representation | Accept and preserve exact bytes | Pinned reader requirement for missing end marker |
| Current filter expression | `FilterState` selects UDP rather than TCP on a mixed capture | A fixture-specific TCP selector produces the old output | Output contains only UDP packet blocks | Existing reader BPF state |
| Finite length and malformed input | Verify finite boundary after drops; corrupt length/reference/version and observe failure | No operation | Rejects before output publication | Block framing and file-device errors |
| Compatibility | Full offline Pcap++/Packet++ regression lane | Pass | Pass | Repository suite |

## Environment and harness preflight

- Immutable source and current default head are both
  `0dbbb9c75eb232135f13fdb794318c4da3270ebc`.
- Dockerfile base:
  `public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest`, resolving during the
  re-freeze to
  `sha256:ce073a8809812fc472187ad4b9bd24dd1794f009a440b66ea6cbdc2d0fab9321`.
- GCC/G++ 12.2, CMake 4.3.2, libpcap 1.10.3, and clang-format 19.1.6
  built the reference as C++14.
- The disposable prototype passed exact fixture comparison and full CTest 2/2
  offline. The `-n -t pcapng` selectors are a union, so the package must not
  claim that command as a focused intersection.
- Fixture source is audit-owned and deterministic. Input SHA-256 is
  `c27c548a813dc9992cebd34d3f403bed8a06c3dc4f81e27e4639f494ecc1ca7f`;
  expected output is
  `6d3972b7df8ffdd98a3f8858cc69f3cfba7af5436887c06e21fc136e652f2558`.

## Historical L1 verdict

This section preserves the L1 decision and immutable hashes as trajectory
history. The current L2 verdict follows it.

The frozen L1 package was approved for an **experimental size-risk** local
pre-filter. That experiment is now complete.

The 178-addition reference did not predict participant work. Two independent
cold `gpt-5.6-sol` solutions passed all six hidden entities and all 70 base
cases. Run 1 changed four production files with 420 strict effective
production additions and 72 message/tool events. Run 2 changed two production
files with 525 effective production additions and 54 events. Successful
medians are three production files, 472.5 effective additions, and 63 events.
The user's Railway objection is confirmed: LOC is not a blocker.

The raw-copy convergence risk appears instead in difficulty. Both first
attempts solved the task, independently choosing a section-aware raw scanner;
one buffered retained output while the other built a stream-offset copy plan
and staged publication. Under `CALIBRATION_STRATEGY.md`, this clean 2/2 local
result is a too-easy signal. The unchanged L1 must not consume platform runs.
Any L2 requires a distinct, public, repository-supported invariant and a full
new design, patch-state, false-positive, and local-pre-filter cycle. If no such
invariant exists without scope padding, the correct rejection reason is
difficulty, not LOC.

The final attempted mutation set has zero focused-suite survivors. One
predecessor survivor exposed a weak zero-valued trailing-length corruption;
the final black-box probe uses an unequal nonzero trailer, passes the
reference, and kills that plausible scanner defect. The exact evidence,
rejected artificial probes, isolation, patch-state matrix, and frozen hashes
are recorded in `FALSE_POSITIVE_AUDIT.md`.

No solver result from another version may decide this version. The frozen
artifact hashes are:

- `meta.md`
  `41706d1f2289434f91a7625b26da843b71b42ba945b75a8ced93d77db598b6fa`;
- `test.patch`
  `925e1e87f9087e0de5a403e6803730a8bf555e032c147521a6fbe27bf8380e61`;
- `solution.patch`
  `459b089a64714ce5e90a971ebfa01992a35a45a23515e89b02902b8619c72246`;
- `solution_approach.md`
  `2c97ed8b378345df93cbc31ac5aee3085f07651b514f7175f9432c6ec57a6f1e`;
  and
- `Dockerfile`
  `70e8b8f853700ac56afb0738fec87c972782041f57336fc442668a8b55bca7ff`.

The source pin is
`0dbbb9c75eb232135f13fdb794318c4da3270ebc`, and the built problem image
is
`sha256:d49c554406aeb41f9987c93dfd23637826a4318b31bd54bf32ed8e87a8220d71`.
All four patch states apply; the combined application orders are
byte-identical at complete diff SHA-256
`b379ccdd1af901e72b6e2a605f470d8ead4b219151162d69c98f1406a05938ff`;
test-only/base passes 69/69; test-only/new reports six named failures with the
missing API; combined/base passes 69/69; and combined/new passes 6/6.

The harness-compatibility revision was rebuilt and the complete patch-state
and 15-mutant false-positive audit repeated. Its converter also executed
under Python 3.8. The previous two local passes still establish strong LOC
and difficulty evidence, but immutable-version policy prevents counting them
toward the new version. Current local calibration is 0/2 and platform
calibration is 0/10.

The subsequent byte-for-byte prose reduction removed only the redundant
packet-field examples from `meta.md`. The exact patch-state matrix and
15-mutant audit were repeated again with unchanged results; raw evidence is
under `verification/byte-for-byte-prompt-refreeze/`. The prompt edit creates
another immutable version, so current calibration remains local 0/2 and
platform 0/10.

## Retired L2 verdict

The review-supported L2 is approved for a new calibration batch. It adds three
independent public discriminators rather than enlarging the original omnibus
fixture:

- `InterfaceSelection` proves that all IDBs remain ordered and a valid EPB on
  nonzero section-local Interface ID 1 is filtered with the referenced link
  type across two sections;
- `OptionPreservation` proves that standardized copyable and do-not-copy
  Custom Options inside retained blocks are both left untouched; and
- `MalformedOptions` requires bounded, padded option fields and Name
  Resolution records in retained standardized blocks.

The last boundary expands the honest reference from the review-counted 158
effective additions to 253 raw production additions, 231 of them non-comment
and non-blank. This clears the 200-effective-LOC floor through a
specification-backed validation obligation. It does not require semantic
option interpretation, unknown-block payload validation, or a particular
scanner architecture.

All four exact patch states apply and pass `git diff --check`. Both combined
application orders are byte-identical at complete diff SHA-256
`db3330a478c0f034ab0040c571b9d7351bd4c15eafef948107c0b33cfde65263`.
Test-only/base passes 69/69, test-only/new emits all nine expected named
failures, combined/base passes 69/69, combined/new passes 9/9, and
solution-only passes `Packet++Test` 259/259 plus `Pcap++Test` 69 passed, zero
failed, 44 skipped.

The exact 21-mutant audit has zero survivors. Its six new modes are cleanly
distributed: three fail only `InterfaceSelection`, one fails only
`OptionPreservation`, and two fail only `MalformedOptions`. The restored
reference passes 9/9. The two prior local solutions and the new Nova platform
solution each pass eight of nine L2 scenarios and fail only
`MalformedOptions`, showing that the added boundary varies the discriminator
without rejecting their valid interface and option-copy behavior.

The current immutable artifact hashes are:

- `meta.md`
  `22641f52eb9652c9458166ed036dda5f526a3615dbc12cb42ad4a3ef832fd97d`;
- `test.patch`
  `d43bbc6c8b1e21b12d329bcddbf3535c2c79b446b8670a0c1bc63ac2d642975b`;
- `solution.patch`
  `03e94b197fa99723086f00807e29637afa1076c721fba7c8552ecf24270d88e0`;
- `solution_approach.md`
  `f67f2fc513c48591773a91a906a17e9c667f9c71eb810f0bc63a8d79b0852b64`;
  and
- `Dockerfile`
  `70e8b8f853700ac56afb0738fec87c972782041f57336fc442668a8b55bca7ff`.

The source pin remains
`0dbbb9c75eb232135f13fdb794318c4da3270ebc`; the built problem image is
`sha256:d49c554406aeb41f9987c93dfd23637826a4318b31bd54bf32ed8e87a8220d71`.
Because prompt, tests, and reference behavior changed, this is a new immutable
problem version. Prior solver results are trajectory replays only; current
calibration is local 0/2 and platform 0/10.

### Current-filter prompt re-freeze

The prompt now relies on the reader's current packet filter without naming
`setFilter()`. The change removes discoverable API instruction and does not
alter any behavioral clause, test, reference line, or Docker layer.

For `meta.md` SHA-256
`22641f52eb9652c9458166ed036dda5f526a3615dbc12cb42ad4a3ef832fd97d`,
all four patch states passed `git diff --check`; both combined orders remained
byte-identical at complete diff SHA-256
`db3330a478c0f034ab0040c571b9d7351bd4c15eafef948107c0b33cfde65263`.
Test-only/base passed 69/69, test-only/new emitted all nine named failures,
combined/base passed 69/69, combined/new passed 9/9, and solution-only passed
`Packet++Test` 259/259 plus `Pcap++Test` 69 passed, zero failed, 44 skipped.
The converter emitted all nine simulated build failures under Python 3.8.

All 21 isolated mutants compiled and were killed by the focused suite; the
restored reference passed 9/9. Raw evidence is under
`verification/current-filter-prompt-refreeze/`. This prompt edit creates
another immutable version, so calibration remains local 0/2 and platform
0/10.

### 2026-07-31 L3 option-termination and coverage-completion gate

Before revising `test.patch`, the design protocol, calibration strategy,
current compact records, all four unhinted working-pool runs under
`agent-runs2/`, their solution patches, evaluations, test logs, and retained
trajectories were read. All four are legitimate L2 passes: 69/69 base and 9/9
focused in every run. No PcapPlusPlus near-pass or broad failure is available;
those categories are recorded as unavailable rather than replaced with
unrelated evidence.

The four solutions are substantive but convergent:

| Run | Production shape | Scanner/publication architecture | Relevant validation behavior |
|---|---|---|---|
| `Nova_Nova_1` | CMake, header, and a new 550-addition C++ source | Streaming input abstraction, section state, temporary output replacement | Checks SHB 1.0, SPB exact size, SHB/IDB/EPB/ISB/NRB/DSB option areas; incorrectly requires an explicit option terminator after any nonempty list |
| `Nova_Nova_2` | Header and 452-addition existing C++ source | Whole-input buffer, optional Zstd path, temporary replacement | Checks both version fields, SPB size, and every standard option area; incorrectly requires an explicit option terminator |
| `Nova_Nova_3` | Header and 427-addition existing C++ source | LightPcapNg input, buffered section output, temporary replacement | Checks both version fields, SPB size, and every standard option area; uniquely accepts a nonempty option list that reaches block end without a terminator |
| `Nova_Nova_4` | CMake, header, and a new 532-addition C++ source | Streaming reader, richer interface-option state, temporary replacement | Checks both version fields, SPB size, and every standard option area; incorrectly requires an explicit option terminator |

The 4/4 result exceeds the 50% cap and abandons L2. It is a deterministic
difficulty signal, not leakage or invalidity. All four production patches are
well above the 200-effective-LOC floor, so difficulty and solution size remain
separate findings.

External review also identifies three exact public coverage defects:

- malformed packet-length probes cover EPBs but not the independently framed
  SPB packet body;
- malformed option probes omit the SHB, ISB, and the NRB option area after its
  required record terminator; and
- the reference checks SHB major version 1 but not minor version 0.

L3 will close those holes without multiplying copies of one fixture. SPB
length corruption remains in the packet-reference/length family;
SHB/ISB/NRB-option overruns remain in the inner-option family; and the minor
version check remains in outer framing/version validation. A separate
`FilterState` scenario will use a non-TCP expression because every predecessor
fixture used `tcp`, leaving a plausible hard-coded-predicate shortcut. A
separate valid-input scenario will exercise option lists whose final padded
field ends exactly at the block boundary without `opt_endofopt`.

The last discriminator comes directly from the pinned PCAPNG draft: writers
must emit `opt_endofopt`, but readers must not assume it is present and should
treat the block boundary as the end of the list. It is not a malformed-input
permutation. It exercises acceptance of a valid representation, and the four
independent L2 patches split 1/4 on the exact parser decision. Buffered and
streaming scanners can both pass with the same public behavior.

#### L3 discriminator ledger

| Candidate discriminator | Evidence source | Expected architecture impact | False-positive risk | Decision |
|---|---|---|---|---|
| Valid option list ending at block boundary | Pinned PCAPNG draft plus 3/4 explicit-terminator solver implementations | Requires the option walker to distinguish block completion from malformed overrun | Low: applies equally to buffered and streaming readers and preserves exact bytes | Add as independent `OptionTermination` |
| Non-TCP current filter | Every predecessor fixture used `tcp`; current-filter behavior is public | Prevents a literal or cached fixed predicate without constraining BPF plumbing | Low: ordinary valid BPF behavior | Add as independent `FilterState` |
| SPB captured-length mismatch | External T4 review and the SPB/IDB snapshot-length equation | Completes the independent SPB packet framing branch | Low: short and long forms share one public equality | Add to `MalformedReferences` |
| SHB, ISB, and post-record NRB option overruns | External T4 review and distinct standardized option starts | Proves callers invoke a shared or equivalent validator at every retained block family | Low: no private parser shape is required | Add to `MalformedOptions` |
| Unsupported minor version | External solution-quality review and supported SHB version 1.0 | Adds the missing half of a public two-field check | Low | Add to `MalformedFraming` and reference |
| More byte-order permutations, private unknown-block payload rules, atomic publication, Zstd, pruning, or merging | No distinct trajectory survivor or public in-scope boundary | Would enlarge fixtures or change scope | High or duplicate | Reject |

The planned probes were prototyped before freezing. The exact reference passes
all 11; test-only/new reports every registered name. Isolated mutants for the
seven new defects compile and fail only their intended focused scenario
(three option-entry mutants share the public `MalformedOptions` entity but
change distinct entry points). No test requires the reference scanner,
temporary-file strategy, or a private LightPcapNg representation.

#### L3 false-positive audit and re-freeze

All 28 isolated mutants compile and are killed. The restored reference passes
11/11. No focused survivor remains for full-suite escalation; the exact
solution independently passes `Packet++Test` 259/259 and `Pcap++Test` 69
passed, zero failed, 44 skipped. The current requirement-to-oracle map,
survivor handling, rejected probes, and mutation isolation are recorded in
`FALSE_POSITIVE_AUDIT.md`.

Retrospective replay of the four legitimate L2 platform solutions produces
the intended varied result:

| Replay | L3 result |
|---|---:|
| `Nova_Nova_1` | 10/11; only `OptionTermination` fails |
| `Nova_Nova_2` | 10/11; only `OptionTermination` fails |
| `Nova_Nova_3` | 11/11 |
| `Nova_Nova_4` | 10/11; only `OptionTermination` fails |

Fresh exact patch states pass `git diff --check`. Test-only/base is 69/69;
test-only/new has all 11 required failures; combined/base is 69/69;
combined/new is 11/11; and solution-only passes both complete applicable
upstream inventories. Both combined application orders are byte-identical at
complete diff SHA-256
`77e0c75abab1b0cc02e773f191087e1af3b8973fb3f6a9698cf4a5819b9f8c3d`.
Python 3.8 emits all 11 simulated named build failures.

The L3 reference adds 254 raw production lines across two files, 232 of them
non-comment and non-blank. Exact immutable artifact SHA-256 values are:

- `meta.md`
  `22641f52eb9652c9458166ed036dda5f526a3615dbc12cb42ad4a3ef832fd97d`;
- `test.patch`
  `6bfafeaa05d84da563cfb54f5b6312ce13fc176eab3080d8ea04fcde382816bc`;
- `solution.patch`
  `33f96aeb379e074cdddd07383acabccd45aa1d16d02ffe65996d036c9c824b4a`;
- `solution_approach.md`
  `53cd447171bb1b4edecff2a3667cced20eccd344f29267e8050617434a9b8a0f`;
  and
- `Dockerfile`
  `70e8b8f853700ac56afb0738fec87c972782041f57336fc442668a8b55bca7ff`.

The source pin and image remain
`0dbbb9c75eb232135f13fdb794318c4da3270ebc` and
`sha256:d49c554406aeb41f9987c93dfd23637826a4318b31bd54bf32ed8e87a8220d71`.
Raw evidence is under
`verification/l3-option-termination-refreeze/`. Because tests and reference
behavior changed, calibration restarts at local 0/2 and platform 0/10.

### 2026-07-31 L4 empty-filter and discriminator-diversification gate

Before revising `test.patch`, the design protocol and calibration strategy
were reread. Searches covered the repository/problem indexes, all compact
PcapPlusPlus records, `estimate_trajectories/`, `agent-runs1/`,
`agent-runs2/`, and the new `agent-runs3/` batch. The three completed L3
runs are legitimate near-passes: each passes 69/69 base and 10/11 focused
tests and fails only `OptionTermination`. `Nova_Nova_4` contains an
unfinished workspace diff but no solution patch, evaluation, or test result.
There is no L3 pass or completed broad failure; those categories are recorded
as unavailable rather than replaced with unrelated evidence.

All three completed solvers independently built raw section scanners and used
the reader's `m_BpfWrapper.matches()` path for EPBs and SPBs. They differ in
buffering and publication:

| Run | Production shape | State/data flow | Proactive checks and missed boundary |
|---|---|---|---|
| `Nova_Nova_1` | 435 production additions plus repository tests | Light file input, per-section memory buffer, temporary destination | Tested closed/open lifecycle and packet counts; required an explicit option terminator |
| `Nova_Nova_2` | 472 production additions | Streaming Light input and seekable temporary output | Built custom mixed-section probes and inspected compression/input behavior; required an explicit option terminator |
| `Nova_Nova_3` | 536 production additions plus repository tests | Dedicated source file, streaming input/output, copied BPF wrapper, parsed IDB timestamp options | Tested lifecycle, destination preservation, and invalid input; required an explicit option terminator |

The batch is abandoned at 0/3. Repeating or merely expanding
`OptionTermination` would not create a new discriminator. L4 instead starts
with the reported public state edge: the repository documents that
`BpfFilterWrapper::matches()` returns true for an empty filter and
`IFilterableDevice::clearFilter()` disables a prior filter. A valid capture
with both EPBs and SPBs must therefore copy every packet before any filter is
set and after a filter is cleared.

#### L4 provisional discriminator ledger

| Observed behavior | Generalized shortcut | Public invariant | Black-box oracle | Failure family | Anti-overfitting rationale |
|---|---|---|---|---|---|
| No current test calls `copyFiltered()` with the default or cleared filter | Require a nonempty BPF program, or special-case “filtered” as necessarily selective | Repository empty-filter semantics accept every packet; `copyFiltered()` uses the current filter | Exact-copy a valid EPB/SPB capture before setting a filter, then set and clear a filter and exact-copy again | Public filter state | Exercises established device behavior, not a parser architecture |
| All three L3 near-passes fail only the same valid option-list form | Let one subtle parser decision be the sole difficulty gate | Discriminators must span distinct public boundaries | Keep block-end termination as one oracle but prototype additional state, framing, and publication boundaries separately | Portfolio concentration | Prevents fixture multiplication around the same TLV loop |
| The three scanners differ in memory versus streaming publication and in which optional block structures they recognize | Overvalidate unknown payloads, publish before complete validation, or mishandle a valid section boundary in one scanner shape | Unknown blocks are opaque; destination replacement follows validation; section lengths count retained bytes after each SHB | Differentially prototype repository/spec-backed captures, retaining only probes that pass the reference and separate legitimate patches for a public reason | Parser/publication boundary | Candidate probes are rejected unless independently supported and architecture-neutral |

No hidden-test edit will be retained merely because it distinguishes these
three patches. Candidate probes must first pass the reference, map to prompt
or repository behavior, and expose a plausible shortcut. Empty/cleared filter
is already accepted on that basis. Other candidates remain provisional until
differential replay identifies a distinct, fair boundary; artificial
predicates and private implementation details are excluded.

#### L4 accepted discriminator ledger

The provisional probes were implemented outside `test.patch` first and run
against the exact reference plus the three completed L3 solution patches.
Three candidates survived the fairness gate:

| Discriminator | Independent authority | Reference | Raw L3 differential | Decision |
|---|---|---:|---|---|
| Default and cleared filter | `BpfFilterWrapper::matches()` documents empty-filter acceptance; `clearFilter()` restores it | Pass | All three pass | Add to close the reported false positive, not to force a split |
| Nonzero IDB reserved field | Pinned PCAPNG draft says writers emit zero and readers ignore it; prompt preserves the complete IDB | Pass | Only Nova 2 fails | Add as reader-opacity boundary |
| Opaque local-use block | Pinned draft reserves high-bit block types for local use; prompt copies unknown blocks byte-for-byte | Pass | Only Nova 1 fails | Add as unknown-payload-opacity boundary |

Rejected prototypes included further endian permutations, extra malformed TLV
sites, output-publication variations, and payload-specific private grammars.
They either duplicate an existing family, lack a public invariant, or would
privilege one scanner shape. `OptionTermination` remains tested, but its exact
rule is now public prose rather than the sole unstated difficulty gate.

#### L4 exact false-positive audit and replay

The current requirement-to-oracle map is in `FALSE_POSITIVE_AUDIT.md`. The 28
L3 mutants were rerun unchanged. Three new plausible incorrect implementations
were then isolated: require a nonempty filter, reject a nonzero IDB reserved
field, and parse a local-use payload as standardized options. All 31 production
mutants compiled and failed the focused suite. The new mutants fail only
`DefaultAndClearedFilter`, `ReservedFieldOpacity`, and `LocalUseOpacity`,
respectively. The restored reference rebuilt and passed 14/14. No final
focused survivor remained for full-suite escalation; the exact solution also
passed `Packet++Test` 259/259 and `Pcap++Test` 69 passed, zero failed, 44
skipped.

Raw replay of the three completed L3 solutions gives:

| Replay | Raw L4 result |
|---|---:|
| `Nova_Nova_1` | 12/14; `OptionTermination`, `LocalUseOpacity` |
| `Nova_Nova_2` | 12/14; `OptionTermination`, `ReservedFieldOpacity` |
| `Nova_Nova_3` | 13/14; `OptionTermination` |

Because L4 explicitly states the option-list boundary rule, the relevant
projection changes only the terminal exhaustion result in each solver's
option validator. Those normalized replays are 13/14 with only
`LocalUseOpacity`, 13/14 with only `ReservedFieldOpacity`, and 14/14. This is a
1/3 split with distinct failure families rather than three agents failing the
same hidden case. All three pass the reported empty-filter test.

Fresh exact patch states pass `git diff --check`. Test-only/base is 69/69;
test-only/new has all 14 required failures; combined/base is 69/69;
combined/new is 14/14; and solution-only passes both complete applicable
upstream inventories. Both combined application orders are byte-identical at
complete diff SHA-256
`ec0506fb5c0cd5533ed6414b702f1df1dcf3509ff85b6f01d9aae77cd634b9a8`.
Python 3.8 emits all 14 simulated named build failures.

The unchanged reference adds 254 raw production lines across two files, 232
of them non-comment and non-blank. Exact immutable artifact SHA-256 values
are:

- `meta.md`
  `5f09840a054adc4f32c47621d5d626cd3e034204ddb81b16379aa2d3ea593afa`;
- `test.patch`
  `f5a63adbc9338e297ec673f0c92ab6b2d3719771b9d586eb52a027375edbcb6c`;
- `solution.patch`
  `33f96aeb379e074cdddd07383acabccd45aa1d16d02ffe65996d036c9c824b4a`;
- `solution_approach.md`
  `85cbffb348f051caf676838ad904d7f9b0184f53dc0ecd2aec9f0fad0888bcfb`;
  and
- `Dockerfile`
  `70e8b8f853700ac56afb0738fec87c972782041f57336fc442668a8b55bca7ff`.

The source pin and image remain
`0dbbb9c75eb232135f13fdb794318c4da3270ebc` and
`sha256:d49c554406aeb41f9987c93dfd23637826a4318b31bd54bf32ed8e87a8220d71`.
Raw evidence is under `verification/l4-filter-opacity-refreeze/`. Prompt and
tests changed, so L3 is retired and L4 calibration restarts at local 0/2 and
platform 0/10.

### 2026-07-31 L5 minor-version fairness correction gate

Before changing the prompt, reference, or tests, `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread. Searches covered the repository and
candidate indexes, every compact PcapPlusPlus design/calibration record, all
saved run families, and the new fairness report. A representative legitimate
pass from the retired L2 batch (`agent-runs2/Nova_Nova_3`) and a representative
L3 near-pass (`agent-runs3/Nova_Nova_1`) were inspected again. Both used
section-aware raw scanners and both rejected any SHB minor version other than
zero. No completed broad failure exists; that category remains unavailable.

The trajectories do not independently justify the restriction: every solver
saw a prompt that said to validate the “supported section version,” and the L3
hidden test required exactly 1.0. Repository behavior points the other way.
Bundled LightPcapNg reads the two version fields into
`light_pcapng_file_info`, preserves the minor value when writing, and performs
no minor-version rejection. The public prompt never named 1.0 as the only
accepted minor version. External fairness review therefore identifies a real
reference-policy leak, not a missing prompt hint.

#### L5 fairness ledger

| Observed behavior | Generalized shortcut or overconstraint | Public/repository invariant | Black-box action | Failure family | Decision and anti-overfitting rationale |
|---|---|---|---|---|---|
| L4 rejects an otherwise valid 1.1 SHB | Treat the reference's emitted minor value as an exclusive reader version | Repository parser stores and round-trips arbitrary minor values; the task only needs a supported major format family | Accept and byte-preserve an SHB with major 1 and a different minor value | Version compatibility | Remove the rejection rather than add a new acceptance discriminator; this restores repository behavior and avoids pinning speculative forward-compatibility policy |
| Major version 2 remains rejected | Accept a structurally different major format without a supported contract | Major version identifies the incompatible format version; all repository and trajectory implementations already distinguish it | Keep the existing major-version corruption in `MalformedFraming` | Major format compatibility | Retain: this is the strongest fair version boundary already stated by “supported major section version” |
| L4's default-filter and two opacity probes split normalized replays | Remove an unrelated discriminator while fixing version fairness | Those tests map to repository BPF behavior or explicit opaque-copy requirements | Leave them unchanged | Filter state / payload opacity | Retain: the fairness correction must not perturb independent discriminators |

The L5 change will remove the 1.1 rejection case, delete the reference's minor
zero check, narrow the prompt to the supported **major** section version, and
retire the corresponding mutant. It will not replace the unfair assertion with
another version permutation. Because prompt, test, and reference behavior all
change, the L4 immutable version is abandoned and every patch-state,
regression, replay, compatibility, and false-positive check restarts for L5 at
0/10.

#### L5 exact audit and re-freeze

The public contract now requires the supported **major** section version. The
1.1 rejection and test-scanner minor-zero assumption were removed, and the
reference no longer reads the minor field as a validity predicate. No new
minor-version hidden test replaces them. An audit-only exact-copy fixture with
SHB 1.1 builds and passes, establishing the corrected reference behavior.

The 27 fair predecessor mutants with stable IDs 1-25 and 27-28 were rerun, as
were L4's three filter/opacity mutants 29-31. All 30 active production mutants
compile and fail the focused suite. Historical mutant 26 is recorded as
retired because accepting minor 1.1 is now correct, not a false positive. The
restored reference rebuilds and passes 14/14; no focused survivor remains for
full-suite escalation. The exact solution independently passes `Packet++Test`
259/259 and `Pcap++Test` 69 passed, zero failed, 44 skipped.

Raw and prompt-normalized solver replays are unchanged: raw Nova 1 fails
`OptionTermination` and `LocalUseOpacity`, raw Nova 2 fails
`OptionTermination` and `ReservedFieldOpacity`, and raw Nova 3 fails only
`OptionTermination`. After the explicit option-rule normalization, Nova 1 and
Nova 2 fail their distinct opacity cases and Nova 3 passes 14/14.

Fresh exact patch states pass `git diff --check`. Test-only/base is 69/69;
test-only/new has all 14 required failures; combined/base is 69/69;
combined/new is 14/14; and solution-only passes both complete applicable
upstream inventories. Both combined orders are byte-identical at complete diff
SHA-256
`4f572abf252ecb840e5a1759646b26a9ddab692d4946fb90023ed935e94db666`.
Python 3.8 emits all 14 simulated named build failures.

The corrected reference adds 253 raw production lines across two files, 231
of them non-comment and non-blank. Exact immutable artifact SHA-256 values
are:

- `meta.md`
  `10b0b7ef006ef2d1ba8368dca777109105fe672294e6057b0de56a8245ebb863`;
- `test.patch`
  `4727aaa1969cab52bcbd9156ed7b9dd9ee38af396403d15e42353d0ef4fecec4`;
- `solution.patch`
  `3d8245aa3f0e06594d3bf290fcd3f633e97ffe73e17c4ea4555c713d9538b44a`;
- `solution_approach.md`
  `775d8beed8a5a5f9abd89c7f36cc4a8f718b26a040adcf9ccd786733a3b5d332`;
  and
- `Dockerfile`
  `70e8b8f853700ac56afb0738fec87c972782041f57336fc442668a8b55bca7ff`.

The source pin and image remain
`0dbbb9c75eb232135f13fdb794318c4da3270ebc` and
`sha256:d49c554406aeb41f9987c93dfd23637826a4318b31bd54bf32ed8e87a8220d71`.
Evidence is under `verification/l5-minor-version-fairness-refreeze/`. L4 is
retired without calibration, and L5 restarts at local 0/2 and platform 0/10.

### 2026-07-31 L6 trajectory-informed hardening gate

Before revising a submission artifact, `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread in full. Searches covered
`problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, every compact record in this problem, and all four
saved calibration families. The new `agent-runs4/` batch contains ten complete
unhinted runs against exact L5: Nova 1, 2, 4, 6, 7, 8, and 9 pass all 69
baseline and 14 focused groups; Nova 3 and 5 fail four focused groups; Nova 10
fails five. Every baseline suite passes. L5 therefore calibrates at 7/10,
exceeds the 50% cap, and is retired; no result or unused run carries into L6.

Raw trajectories and solution patches were inspected, not only evaluator
summaries. Nova 6 is the representative legitimate pass: it built a streaming,
section-local scanner, used a temporary destination, and deliberately moved EPB
option validation after the filter match. Nova 10 is the strongest available
failure: it built the same general scanner/temporary-file architecture but
misparsed valid Decryption Secrets options and also rejected valid
multi-section captures. Nova 3 is a second failing architecture with the DSB
options defect. No broad implementation failure exists in this batch: all ten
are substantive, all preserve the full baseline, and the largest focused
failure is five of fourteen groups. That missing representative category is
recorded rather than substituted.

The ten patches expose two nearly universal choices and one meaningful split.
All ten declare both the public method and definition `const`, so the reported
const-qualification omission is a real API coverage gap but not a calibration
discriminator for this batch. All ten write a sibling temporary file and then
rename or replace the destination (Nova 7 additionally buffers the complete
input); this should support an exactly identical source/destination path in the
Linux lane, so an in-place success probe is a publication-boundary regression,
not a projected split. Among the seven existing passes, Nova 1, 2, 4, 8, and 9
validate an EPB's option area before applying the filter, while Nova 6 and 7
validate it only after the EPB is retained. L5's reference also validates too
early. The prompt, however, requires option framing in **retained** standardized
blocks. Dropped packets must still have safe fixed-field, interface, captured
length, original length, and packet-data bounds, but their discarded option
area is not part of the output contract.

#### L6 discriminator ledger

| Observed behavior | Generalized shortcut or overconstraint | Public/repository invariant | Black-box action | Failure family | Decision and anti-overfitting rationale |
|---|---|---|---|---|---|
| Five of seven L5 passes validate EPB options before knowing whether the EPB is retained | Treat every standardized block as retained for option validation | The prompt scopes option/record validation to retained standardized blocks and separately requires filtering packet blocks | Put an invalidly framed option area on a structurally safe EPB rejected by the current filter; require successful copy and exact output without that EPB | Filter/validation ordering | Accept as the principal discriminator: it is an explicit semantic boundary, separates five current legitimate-but-overstrict implementations from the two that modeled the state transition correctly, and is not another DSB fixture |
| Tests instantiate a mutable reader at every call site | Implement only a non-const overload despite the exact required signature | The public API explicitly ends in `const`, which controls source compatibility | Configure a filter, bind the reader as a const reference, and invoke `copyFiltered()` | Public API compatibility | Accept as a compile-time contract probe; all current patches should pass, so it closes a false positive without concentrating calibration failures |
| No success case uses one identical source/destination spelling | Truncate or reject the source path instead of consuming it safely before publication | The operation creates or replaces the destination independently of reader open state; L5 reference already consumes input before opening the output | Filter a valid capture to the exact same path and compare the replacement bytes | Input/output alias publication | Accept with an explicit public same-path sentence; all current temporary-file implementations are expected to pass, so this is a distinct non-calibration regression |
| Three L5 failures already reject valid DSB option tails | Assume the secrets payload occupies the entire DSB body | DSB is explicitly retained and its trailing options are ordinary retained options | Existing `OptionPreservation`, `OptionTermination`, and related cases | DSB layout | Retain existing coverage but add no DSB permutation; repeating this family would make failures less diverse |
| Every run uses a temporary output | Require a particular temporary naming scheme, atomic rename, or buffering strategy | Only destination preservation on failure and successful replacement are public | None | Private publication mechanism | Reject: same-path behavior is public, but the mechanism remains unconstrained |
| Potential timestamp-resolution and offset differences appear across scanners | Require filter predicates over timestamps | Repository BPF matching for these fixtures is packet/link-type based and the public task does not expose time predicates | None | Private/non-observable filter input | Reject as artificial and non-discriminating |

The provisional L6 change therefore adds three independent checks: const API
use, successful identical-path replacement, and discarded-EPB option opacity.
The reference must move EPB option validation after a successful match. Before
freezing, the discarded-option probe will be replayed against all ten L5
solutions to confirm the projected two-pass split, while the const and same-path
probes will be checked for non-concentration. Any unexpected outcome will be
recorded and the ledger revisited before accepting the test.

#### L6 prototype outcome and exact audit

Prototype replay confirmed the discriminator ledger. Nova 1, 2, 4, 8, and 9
pass const use and identical-path replacement but fail only
`DiscardedPacketOptions`; Nova 6 and 7 pass all 16. Nova 3 and 5 retain their
four DSB-dependent failures and also fail the new validation-order case. Nova
10 passes the new case but retains its five multi-section/DSB failures. The
exact projected split is therefore 2/10 with distinct failure signatures.

The first same-path prototype used `makeComplexCapture()` and caused Nova 3
and 5 to fail that scenario because of the fixture's DSB options. It was
rejected as failure-family coupling. The final `InPlaceReplacement` uses the
DSB-free filter-state capture and a UDP filter; every one of the ten patches
passes it. Every patch also compiles the const-reference call. Thus those two
coverage repairs do not artificially lower the replay solve rate.

The exact L6 reference validates EPB fixed fields, local interface, packet
length relationship, and captured-data extent before filtering. It walks EPB
options only after a positive match. The discarded-options input is therefore
safe to classify but its unretained option bytes remain opaque.

Stable active mutants 1-25 and 27-31 were rerun and killed. New mutant 32
removes API const qualification: the production library builds, and the
focused target fails at the const call. Mutant 33 rejects identical paths and
fails only `InPlaceReplacement`. Mutant 34 restores pre-filter EPB option
validation and fails only `DiscardedPacketOptions`. The restored reference
passes 16/16, leaving zero survivors in the 33-active-mutant attempted set.
The complete exact reference inventories pass `Packet++Test` 259/259 and
`Pcap++Test` 69 passed, zero failed, 44 skipped.

Fresh test-only/base is 69/69, test-only/new emits all 16 named failures,
combined/base is 69/69, and combined/new is 16/16. Python 3.8 emits the same 16
simulated build failures. Every patch state passes `git diff --check`; both
combined orders are byte-identical at complete diff SHA-256
`a11d44fbc8e21720c7a0b26f3bdf52107b22c4b1a21dc8e1b9d5fe6fd74621ac`.
The Dockerfile retains the required first line.

The reference has 254 raw and 232 non-comment, non-blank production additions
across two files. Exact immutable artifact SHA-256 values are:

- `meta.md`
  `d527f61ce418cd97a765c3b2705961db1b76b6e6beddeae1f358ef114392630e`;
- `test.patch`
  `00d7213a423facc6ca47b43d2ba5eb2f5365e303eac9e1a45ae002c26d54cfe8`;
- `solution.patch`
  `1f228c09ddab23d64d57791964c8f33008565560cc84fc56e686b4cf3ab514bf`;
- `solution_approach.md`
  `c00e34a724b0e84f362ed59bacb31150e9f26c6c020c1f9bd52fc79921a3d87b`;
  and
- `Dockerfile`
  `70e8b8f853700ac56afb0738fec87c972782041f57336fc442668a8b55bca7ff`.

The source pin and image remain
`0dbbb9c75eb232135f13fdb794318c4da3270ebc` and
`sha256:d49c554406aeb41f9987c93dfd23637826a4318b31bd54bf32ed8e87a8220d71`.
Evidence is under `verification/l6-filter-validation-order-refreeze/`. L5 is
retired at 7/10, and exact L6 calibration restarts at local 0/2 and platform
0/10.

On 2026-08-01, the user confirmed that the platform accepted this exact L6
package. No submission artifact changed during acceptance closeout, and the L5
batch plus L6 replays retain their recorded historical version ownership.
