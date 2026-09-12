# DESIGN - pcapplusplus-ntp-extension-fields

Status: `version-4 trajectory-informed hardening in progress; false-positive re-audit intentionally not run;
calibration reset to 0/10`.

Repository: `seladb/PcapPlusPlus` at
`8ac4366c4184f096973ef4a0ca084559935828d0` (`dev`, 2026-08-04).

## Public contract and repository evidence

The task adds generic NTPv4 extension-field support to `NtpLayer` without
interpreting extension-specific contents. PcapPlusPlus already documents the
48-octet NTPv4 header, optional extension fields, and optional authentication;
its current `getKeyID()` and `getDigest()` support only field-free 20- and
24-octet authentication tails and carry the original unsupported-extension
TODO from merged PR #788.

The frozen public API follows the repository's DHCPv6/Radius lightweight-record
idiom:

- `NtpExtensionField` is a borrowed view with null testing, type, total encoded
  size, encoded data size/data pointer, and record-base access;
- `NtpExtensionFieldBuilder` accepts a type and opaque caller bytes;
- `NtpLayer` supplies first/next/count traversal, append, insert-before-first-
  type, remove-first-type, and remove-all operations.

These names are a necessary compilation contract, but the internal tail
partition, span representation, allocation strategy, and scanner architecture
are not prescribed. An independent copied/indexed prototype demonstrates that
the behavioral contract does not require the reference's private record-reader
flow.

RFC 7822 supplies the generic wire rules: encoded length includes the four-byte
header and padding, is word-aligned, ranges from 16 to 65,532 octets, and the
final no-authentication field must be at least 28 octets while earlier fields
may be 16. RFC 5905 supplies header/extensions/MAC order and the four-byte
Crypto-NAK. Existing PcapPlusPlus structures establish supported 20- and
24-byte key-ID/tag envelopes. RFC 8573 prevents naming the 20-byte envelope's
algorithm from framing alone; RFC 8915/9748 establish that registered, unknown,
private, duplicate, and NTS types must remain opaque to this generic API.

The builder zero-pads to word alignment and the 16-octet minimum; views expose
all encoded post-header bytes including padding. Appending a final field still
requires an encoded length of at least 28. Inserting before an existing field
may use a 16-octet field. Removal must preserve valid list closure.

The tail partition recognizes no auth, four-byte terminal auth, and the
repository's 20/24-byte terminal auth. A field-free 20/24-byte tail is auth even
when its first word resembles a field header. Negotiated longer authentication
is out of scope. Existing key-ID representation and NTPv3 access remain
unchanged.

Extension mutation is refused atomically whenever supported authentication is
present because the library has no key/algorithm with which to recompute the
tag. Malformed tails produce no partial extension traversal or edit.
`isDataValid()` and UDP/123 classification retain their existing header-length
boundary. Attached and detached layers use ordinary Packet++ resize semantics;
callers continue to invoke `Packet::computeCalculateFields()` for containing
lengths/checksums.

## Trajectory-informed design gate

Searches covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, every same-repository candidate/problem record,
nearby TLV/opaque-binary candidates, and archive manifests for PcapPlusPlus,
NTP, extension fields, MAC/authentication tails, optional records, framing,
packet editing, and attached/detached ownership.

No earlier Olympus NTP task or NTP solver trajectory exists. The closest raw
evidence is the accepted same-repository PCAPNG problem. The archive manifest
and representative `trajectory.json`, solution/workspace patches, test logs,
and evaluations were inspected before test authoring:

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
| --- | --- | --- | --- |
| Legitimate pass | `archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz`, `agent-runs4/Nova_Nova_6` | L5 14/14 and exact L6 replay 16/16; 10 header + 406 source additions | Section-local raw scanner; delayed optional-data validation. Preserve opaque NTP values and validate only generic framing. |
| Near-pass | same archive, `agent-runs4/Nova_Nova_1` | L5 14/14, L6 15/16; 7 header + 532 new-source additions | Coherent streaming design overvalidated data that public behavior discarded. Do not decode NTS/Autokey or negotiated MAC semantics. |
| Broad failure | same archive, `agent-runs4/Nova_Nova_10` | L5 9/14, L6 11/16; 8 header + 533 new-source additions | Mixed section state and independent optional-block assumptions. Use one consistent tail partition for traversal, auth access, and edit safety. |

The production seams and exact raw trajectories are analogous evidence only;
no PCAPNG fixture, hidden assertion, or implementation is copied. NTP operates
inside Packet++ and adds authentication-bound packet editing, not section-aware
file copying/publication.

The design also inspected the candidate's independent prototypes and mutation
history. The repository-shaped complete prototype measured 200 strict effective
production additions; the copied/indexed complete prototype measured 100. That
variation preserves alternative architectures while the mutation audit proves
several independently wrong-able behaviors.

## Discriminator ledger

| Observed solver/repository behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
| --- | --- | --- | --- | --- | --- |
| Existing auth access uses exact total packet lengths | bolt enumeration beside unchanged auth access | 20/24-byte auth remains accessible after fields | fields plus both auth sizes return exact key/digest | tail partition / legacy API | public wire semantics; any architecture can locate the terminal |
| A MAC word can resemble a TLV header | greedily parse every tail word | field-free 20/24 bytes are auth, not a final short field | extension-shaped auth yields zero fields and correct auth | extension/auth boundary | changes public bytes, not a private branch |
| RFC has 16-byte earlier and 28-byte final minima | require 28 everywhere or accept final 16 | list closure depends on terminal form | compare 16+28, final16, and 16+auth | structural closure | three semantic endings, not fixture permutations |
| Candidate mutant rounded 26 and omitted overrun bound | permissive/unsafe TLV length handling | encoded lengths are aligned and fully bounded before exposure | non-aligned and overrun records yield null traversal | framing / memory safety | direct standards rule and stable public null result |
| Candidate mutant collapsed duplicate types | represent fields as a type map | every occurrence remains in wire order | duplicate private types retain distinct sentinel bytes | multiplicity / order | permits views, spans, or copies; rejects only lost behavior |
| Near-pass overvalidated opaque data | whitelist or decode registered types | unknown/private/NTS bodies remain opaque | arbitrary bodies round-trip without semantic rejection | registry independence | RFC and repository generic-record convention |
| Current builder/mutation idiom spans attached/detached layers | support only standalone crafting | same public edit works in both ownership modes | edit both, reparse, and recalculate UDP/IP fields | ownership / packet resize | repository public behavior, not allocation internals |
| Bytes covered by a MAC cannot be recomputed | preserve stale auth or partly resize before failure | authenticated edits fail atomically | snapshot full length/bytes across each failed edit | auth/edit safety | public integrity consequence and explicit prompt policy |
| Candidate mutant discarded v3 auth | route every tail through v4 logic | NTPv3 key/digest remain unchanged | synthetic v3 auth uses existing representation | version compatibility | protects established API outside new feature |
| Candidate mutant tightened `isDataValid()` | make classification depend on full structural parsing | legacy classifier remains header-length-only | 49-byte input remains data-valid | classifier compatibility | repository source explicitly defines current boundary |
| Complete prototypes differ substantially in API internals | require reference view-scanner architecture | only named public behavior is required | same byte fixtures pass view/builder or indexed/copy model | architecture neutrality | preserves legitimate alternative implementations |

Each ledger row connects a public requirement to a distinct behavior or
ownership boundary. Multiple malformed lengths remain one framing family;
registered-type permutations remain one opacity family.

## Platform-feedback design checkpoint — 2026-08-05

Before revising the public description or reference, the existing trajectory
gate and discriminator ledger above were re-read together with the new platform
verification report. The report is a harness-wide failure, not a new NTP solver
trajectory: the submitted image lacked `cmake`, so both test-only and combined
runs produced the same single `Harness::Harness` failure before either the 259
existing cases or the fourteen NTP scenarios could execute. It supplies no
legitimate pass, near-pass, or broad implementation-failure evidence and does
not justify a new behavioral discriminator.

The report does identify three artifact-quality issues supported independently
by the public API and repository conventions:

- two generic compatibility sentences duplicate the specific NTPv4,
  authentication, and malformed-tail rules and should be removed;
- the named interface needs explicit return types, null/bool failure signaling,
  and `NtpLayer.h` visibility;
- builder-created records and layer-borrowed views share a record type, so the
  reference should retain ownership only for the former and make purging a
  borrowed view non-destructive.

These changes clarify the existing contract and harden the reference ownership
boundary. They do not add a hidden scenario or revise `test.patch`. The current
discriminator ledger therefore remains unchanged.

## Clause-to-test coverage

| Public requirement | Planned observable test | Base behavior | Reference behavior | Fairness evidence |
| --- | --- | --- | --- | --- |
| enumerate ordered opaque fields | single/multiple/duplicate/private/NTS traversal | API absent / test does not compile | exact views, order, bytes, and null end | record APIs plus RFC opacity |
| strict encoded length and closure | alignment, subminimum, overrun, final-short matrix | API absent | no partial exposure; valid 16+28 succeeds | RFC 7822 |
| supported terminal authentication | fields+20, fields+24, extension-shaped auth-only | accessors return empty after fields | exact legacy key/digest at terminal | existing structs and RFC closure |
| deterministic builder encoding | unaligned caller data and minimum/final sizes | builder absent | network header, zero padding, reparse | repository builder idiom |
| safe detached editing | append, insert-before, remove-first/all, closure refusal | methods absent | exact ordered bytes and atomic failures | Layer resize API |
| safe attached editing | add/remove in IPv4/UDP packet | methods absent | neighboring data preserved; recomputed lengths/checksums | existing Packet API |
| authenticated edit policy | add/remove attempts on 4/20/24 terminals | methods absent | false/null and full byte/length identity | explicit public safety contract |
| version and classifier compatibility | v3 auth and 49-byte validity | baseline passes | byte/value-identical baseline behavior | existing source/tests |
| copy/view lifetime | copy layer/packet and reacquire views | API absent | copy yields independent correct traversal | Layer copy convention |

## Environment and harness preflight

- Pristine official-image build at the pin: NTP 4/4 and Packet++ 259/259.
- Complete reference prototype: NTP 6/6 and Packet++ 261/261 before audit;
  strengthened candidate suite: NTP 11/11 and Packet++ 266/266.
- Offline: every configure/build/test replay used Docker `--network none` after
  source/image/tool acquisition; no external NTP service or fixture download.
- Sanitizers: focused ASan and UBSan pass for both complete architectures;
  LeakSanitizer is disabled only for the documented MemPlumber/global-static
  harness incompatibility.
- Formatting/static checks: clang-format 19.1.6, `git diff --check`, and focused
  clang-tidy checks pass.
- Determinism: tests use generated byte vectors, fixed IP addresses, and exact
  encoded values. No network, clock, randomness, secrets, or platform order.
- Worktree metadata warning: mounted Git worktree `.git` host paths prevent
  CMake from embedding commit text in Docker; host identity checks establish
  the immutable pin and do not affect compilation/tests.

## Candidate false-positive gate

The candidate audit attempted eighteen plausible mutation families. Five
actionable survivors from the first matrix were closed by one distinct public
probe each: non-aligned length, remaining-bound overrun, duplicate occurrence,
NTPv3 auth, and classifier compatibility. The strengthened suite kills sixteen
mutations in focused tests; a partial authenticated resize is killed by the
complete suite; and one Crypto-NAK private-state mutation is behaviorally
equivalent through the frozen API and was rejected rather than forcing a new
status method. Reference result: focused 11/11, Packet++ 266/266.

## Historical version-1 exact-artifact false-positive closure

After the prompt, Dockerfile, test patch, and solution patch were frozen, the
exact suite was replayed from fresh checkouts in test-only, solution-only, and
combined states. Test-only preserves all 259 pre-existing cases and reports all
fourteen new cases as named compile failures. The combined state passes 259/259
and 14/14.

The exact mutation driver compiled 33 plausible transformations. Thirty-two
behaviorally distinct mutants fail the new lane. One transformation that drops
four-byte Crypto-NAK from private partition state passes both lanes because the
public API has no observable distinction from another invalid four-byte tail;
it was rejected rather than forcing a private status method. During the audit,
one permissive rounding mutant exposed a non-isolating alignment fixture. The
fixture was changed to declared 30/actual 32 bytes, every artifact check was
restarted, and the mutant then failed `MalformedAlignment`. A separate corrupt
length mutant motivated a per-case timeout so incorrect implementations cannot
hang the runner.

The complete requirement map, mutant isolation, full-suite results, rejected
predicate, sanitizer findings, and immutable hashes are recorded in
`FALSE_POSITIVE_AUDIT.md`. No NTP solver patch exists to replay and no cold
solver was run; the same-repository saved trajectories remain startup-design
evidence only.

## Docker compatibility revision

Version 1 used
`public.ecr.aws/d3j8x8q7/olympus-base-cpp@sha256:ce073a8809812fc472187ad4b9bd24dd1794f009a440b66ea6cbdc2d0fab9321`.
That choice followed the previously successful PcapPlusPlus PCAPNG problem,
but it does not satisfy the current validator's literal Dockerfile first-line
allowlist. The local build therefore did not establish submission-platform
validity.

Version 2 changes only the Dockerfile. It uses the permitted generic Olympus
base, installs CMake explicitly, and was verified against the base image digest
`sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`.
The clean Docker build succeeded. Test-only preserves the passing base lane and
reports fourteen named new failures; the combined state passes the base lane
and all 14/14 new cases. No false-positive or mutation audit was run for this
revision at the operator's direction.

## Version-4 trajectory hardening

### Agent-run trajectory gate refresh — 2026-08-05

The five raw runs under `agent-runs/` were inspected after searching the prior
same-repository records already listed above. For each run, the evaluation,
JUnit files, wrapper log, raw `trajectory.json`, and production patch were read.
The current pre-hardening tests were also replayed against all five saved solver
patches in fresh containers.

| Evidence role | Run | Outcome | Architecture and decisive evidence |
| --- | --- | --- | --- |
| Legitimate pass | `Nova_Nova_1` | baseline and 19/19 focused pass; 498 production additions | Shared-ownership record copies, a single ordered tail scanner, explicit layer provenance, and ordinary resize calls. An extra manual full-suite invocation ran the binary from the source test directory and missed the OUI fixture copied beside the binary. |
| Legitimate pass / alternative ownership model | `Nova_Nova_3` | baseline and 19/19 focused pass; 533 production additions | Similar tail scanner but builder-owned record copies silently became non-owning aliases. The run proactively exercised a parsed raw packet, showing that parsed and constructed attached packets are a meaningful ownership boundary. |
| Near-pass | `Nova_Nova_5` | baseline pass and 18/19 focused pass; 612 production additions | Enumerated possible authentication suffixes but incorrectly applied the 28-byte field-only terminal minimum to authentication-terminated lists, rejecting a 16-byte field before authentication. |
| Broad failure | unavailable | no broad failure among the five runs | Four runs were complete passes and one missed one boundary; no unrelated failure was substituted. |

The other two legitimate passes used deep-copy ownership and the same public
header/source seams. Successful raw production additions were 498, 624, 533,
and 637 (median 578.5); platform sandbox LOC was 613, 796, 689, and 794. The raw
trajectory schema contains one large agent turn per run, so it does not provide
the platform's agent-message metric and is not used as a substitute for it.

Replay against the latest pre-version-4 suite preserved the original outcome:
the same four legitimate patches passed and the near-pass failed only the
authentication-terminated short-field boundary. This is 4/5 and therefore too
easy under the calibration protocol. Because version 4 changes participant
artifacts, all five runs are abandoned-version evidence and calibration restarts
at 0/10.

The OUI failure was not an official verifier failure: both official lanes were
green. It was a reproducible environment-path trap in the documented manual
workflow. CMake copies `PCPP_OUIDataset.json` beside the built test binary, while
the agent launched that binary with the source test directory as its working
directory. Version 4 exposes the same fixture there and bounds Docker's build
parallelism to avoid the previously observed resource-sensitive unbounded
build.

### Version-4 discriminator additions

| Observed behavior | Generalized shortcut | Public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
| --- | --- | --- | --- | --- | --- |
| Passing solvers chose shared, deep, and dangling-borrowed copy models for builder-owned records | leave copy semantics accidental | copy construction and assignment of an owned record produce independently mutable owned records | compare record addresses and mutate each copy independently | owned-record lifecycle | public copyable value plus record pointer/data APIs; permits any internal ownership mechanism that provides independence |
| One pass proactively edited a parsed packet while most validated only constructed packets | assume all attached storage starts through `Packet::addLayer()` | attached editing works for parsed raw packets too | parse IPv4/UDP/NTP bytes, append, remove all, and observe raw length | parsed packet ownership/resize | standard Packet++ attachment mode, not a private allocation detail |
| Version is a representable three-bit field; previous tests used only lower non-v4 values | implement a lower-bound or v3-specific gate | extension behavior is enabled only for version 4 | version 5 traversal and every edit remain null/false and byte-identical | upper version boundary | one semantic upper-bound probe, not a version permutation matrix |

The owned-copy rule is added to the public description and reference; it is not
a hidden expectation. The parsed-packet and upper-version checks exercise the
existing public contract. No arbitrary field-type decoding, private parser
state, or reference-only architecture is required.

No false-positive, mutation, or cold-solver audit was run for version 4 at the
operator's direction. Version 4 must therefore not be described as
submission-ready even after its ordinary build and test matrix passes.

## Version-5 feedback hardening gate — 2026-08-05

Before revising the hidden tests, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the current NTP design/level records, the candidate
indexes, and the PcapPlusPlus compact history were searched again. The raw
Nova 1, 3, and 5 trajectories and their production patches were re-inspected as
the representative legitimate-pass, alternative-pass, and near-pass evidence;
no broad implementation failure exists in the five-run set. The agent messages
summarize successful opaque editing, while the patches show resize-and-copy
editors and several tests that inspect only type/order or a first marker byte.
Nova 5 remains the concrete near-pass for applying the field-only 28-byte
terminal rule to authentication-terminated lists whose total tail length is not
itself a supported field-free authentication size.

| Observed behavior | Generalized shortcut | Public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
| --- | --- | --- | --- | --- | --- |
| Successful edit checks usually inspect field order and one payload marker, while encoded padding is explicitly exposed | rebuild or shift an unaffected opaque record while corrupting bytes not decoded by the editor | successful insertion and removal preserve every byte of each unaffected encoded field | snapshot complete encoded records with nonuniform payload/padding and compare them after both edits | editor byte preservation | checks public encoded bytes and permits any resize/move architecture |

The complete-record requirement is already participant-facing: fields are
opaque and data access includes encoded padding. The suggested 16-byte field
followed by four-byte authentication probe was rejected after reference replay.
Its complete post-header tail is 20 bytes, and the public precedence rule says a
field-free 20-byte tail is authentication even when its leading bytes resemble
a field. The existing 28-byte-field plus four-byte-authentication fixture is the
unambiguous positive case; accepting the suggested interpretation would
contradict `ExtensionShapedAuthentication`. This revision therefore strengthens
one black-box oracle without changing the public description or reference
behavior. As with every artifact edit, prior calibration evidence remains
abandoned-version evidence and the current version is 0/10.

## Version-6 ownership-test fairness correction — 2026-08-06

Before revising `test.patch`, the problem-design and calibration protocols,
current compact NTP records, candidate indexes, and the archived five-run ZIP
were re-read. Nova 1 and Nova 3 remain representative legitimate ownership
architectures, Nova 5 remains the near-pass, and no broad implementation failure
is available. Their raw trajectories and patches show materially different
record constructors and ownership mechanisms. In particular, a pointer-taking
public constructor is sufficient to represent a null/borrowed view; the public
contract does not require default construction.

The copy-assignment oracle currently default-constructs its destination before
assignment. That setup adds an undocumented interface constraint unrelated to
the owned-copy discriminator. Initialize the destination with another public
`build()` result and then copy-assign into it instead. This continues to observe
independent assigned storage, replacement of an already owned record, mutation
isolation, and purge isolation while accepting implementations without a public
default constructor. No public description or reference behavior changes.
Calibration remains 0/10 because the hidden test artifact changes.

## Current design verdict

Accepted version 6 retains the trajectory-driven hardening while removing the ownership
test's undocumented public-default-constructor dependency. It retains independent copy
semantics for owned builder records, covers parsed-packet editing and the upper
non-v4 boundary, removes the manual OUI-fixture environment trap, and adds exact
unaffected-record preservation across successful edits. The five saved runs do
not count toward calibration; the revised version is at 0/10. Version-6
patch application succeeds and the combined focused lane passes 19/19 as the
non-root evaluation user. The correction changes only test setup; the previously
verified baseline, expected test-only failures, Docker environment, public
description, and reference are unchanged. No false-positive, mutation,
saved-solver replay, or cold-solver check was run for this correction. The
exact-version false-positive audit remains recorded as not run. The platform
accepted the exact canonical artifacts on 2026-08-06 according to the user's
confirmed outcome; acceptance freezes those artifacts despite that deliberately
absent local gate.
