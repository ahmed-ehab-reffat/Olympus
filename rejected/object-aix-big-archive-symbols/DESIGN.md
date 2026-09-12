# DESIGN - `object` AIX big-archive symbol iteration

Status: `rejected after convergence trial; no submission or calibration artifacts`.

Repository: `gimli-rs/object` at
`400e64fbcb03fddb4b1ae8aef1868976ab999acc` with `testfiles` submodule
`fe8da208d4013ec3691311915fdc7d71436c0d1e`.

## Public contract and repository evidence

Complete `ArchiveFile::symbols()` for AIX big archives. The fixed header may
point independently to a 32-bit-object global symbol table, a 64-bit-object
global symbol table, both, or neither. When both exist, iteration returns all
32-bit-table entries first and all 64-bit-table entries second, preserving each
table's stored order. A present zero-entry table still means the archive has a
symbol table, while two absent tables retain the existing `None` result.

Each AIX table uses the IBM big-archive representation: an 8-byte big-endian
symbol count, that many 8-byte big-endian archive-member offsets, and exactly
the same number of NUL-terminated names in the remaining member data. Each
yielded `ArchiveSymbol::offset()` must resolve through the existing
`ArchiveFile::member()` operation. Truncated or overflowing count/offset/name
framing, missing or extra names, malformed referenced members, and either bad
table location return an ordinary parser or iterator error and never panic.

This behavior is repository-grounded rather than reference-defined:

- `archive::AixFileHeader` already exposes independent `gstoff` and
  `gst64off` fields and `parse_aixbig` already reads both, but intentionally
  retains only one table.
- `ArchiveKind::AixBig` is the only archive kind whose symbol iterator still
  returns the explicit implementation TODO.
- `ArchiveMember::parse_aixbig`, `ArchiveFile::member`, `ReadRef`, and `Bytes`
  provide the existing public member-resolution and checked-read boundaries.
- IBM's AIX big-archive specification defines the two optional tables, their
  32-bit/64-bit member roles, the 8-byte count and offsets, and the one-to-one
  NUL-terminated name sequence.
- The repository README states that malformed input should return an error
  rather than panic or parse incorrectly.

The contract deliberately does not prescribe storage fields, helper names,
eager versus lazy validation, exact error text, or one iterator-state design.

## Trajectory-informed design gate

Before authoring any hidden patch, searches were performed across
`problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, `candidates/NEW_CANDIDATES_2026-08-11.md`, the
candidate dossier, `problems/`, and `archive/` for `gimli-rs/object`, AIX big
archives, archive symbols, dual representations, member indexes, malformed
binary framing, and reader-without-writer work. The current upstream default
branch and complete fetched history were also searched for `AixBig`,
`ArchiveSymbolIterator`, `gstoff`, and `gst64off`; the frozen pin remains the
default branch and no later implementation exists. Exact GitHub issue/PR
searches found no public owner for this task.

No domain-specific `object` solver trajectories exist. Representative raw
binary-format trajectories were therefore inspected from the preserved
Calamine and PcapPlusPlus archives rather than substituting an unrelated run as
if it were AIX evidence:

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Analogical legitimate pass | Calamine `agent-runs1/Nova_Nova_4` in `archive/calamine-defined-names/agent-runs.tar.gz` | 205/205 base and 5/5 focused | Added one shared owned metadata model while decoding four independent native parser branches. It preserved source order and old API projections, showing that independently represented branches can feed one public iterator without prescribing storage. |
| Analogical near-pass | Calamine `agent-runs1/Nova_Nova_9` in the same archive | 205/205 base and 4/5 focused | Implemented all format branches but decoded one XLSB owner field one byte early. This supports checked framing at semantic boundaries rather than many equivalent fixtures. |
| Binary-format pass | PcapPlusPlus `agent-runs4/Nova_Nova_6` in `archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz` | 69/69 base and 14/14 focused | Built a full block scanner with per-section state, validation, and staged output; it preserved opaque bytes while validating only documented framing. |
| Binary-format near-pass | PcapPlusPlus `agent-runs4/Nova_Nova_1` in the same archive | 69/69 base and 14/14 predecessor focused; 15/16 hardened replay | Parsed the requested format but validated packet options before learning the packet would be discarded. This generalizes to validating the AIX table that is publicly present without coupling symbol iteration to unrelated object payload parsing. |
| Binary-format broad failure | PcapPlusPlus `agent-runs4/Nova_Nova_3` in the same archive | 69/69 base and 10/14 focused | Assumed a retained metadata block ended with its payload and rejected valid trailing options, collapsing several failures onto one incorrect framing model. This motivates separating AIX count/offset/name cardinality rather than counting fixture failures as distinct depth. |
| Domain-specific pass / near / broad failure | unavailable | no `object` solver run exists | The escalation must use two independent honest implementation spikes and repository-grounded mutants before approving test authoring. |

Raw inspection included each selected run's evaluator record, final workspace
diff, run metadata, and representative trajectory messages. No hidden fixture
path, assertion name, or private call sequence is copied into the participant
contract.

## Discriminator ledger

| Observed solver or repository behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| `parse_aixbig` currently prefers the 64-bit table | Retain one range or overwrite one with the other | Both independently present tables are visible in deterministic 32-then-64 order | Archive with disjoint ordered names in both tables | Header discovery and multi-source iteration | Any pair of ranges, chained iterator, flattened plan, or custom state machine can pass. |
| IBM gives both tables the same 8-byte framing | Reuse the GNU 32-bit iterator or parse the count as printable decimal | Counts and offsets are unsigned 8-byte big-endian values | Non-ASCII count/offset bytes and an offset above the 32-bit boundary | Binary width/endian decoding | Checks the documented wire format, not a helper or type choice. |
| Calamine near-pass missed one representation-specific field | Parse only the preferred table robustly | Either table works alone and a bad independently present table is not hidden by the other | 32-only, 64-only, and one valid plus one malformed table-location scenario | Independent header branches | The two fields are separately implemented repository branches, not cosmetic fixture symmetry. |
| Pcap broad failure collapsed payload and trailing framing | Consume any remaining bytes as names or stop after the offset count | The remaining table data contains exactly one terminated name per offset | Missing terminator, too few names, and trailing extra name/bytes | Name/cardinality framing | Any eager or lazy validator passes; repeated spelling fixtures are unnecessary. |
| `ReadRef` supports bounded reads and the repository promises errors | Multiply or slice unchecked from an untrusted count | Truncation and arithmetic overflow return `Err`, never panic or allocation failure | Oversized count with a short table plus cut points at count/offset/name regions | Resource and bounds handling | Uses tiny deterministic inputs and ordinary checked-read semantics, not a timing or memory quota. |
| Existing symbol iterators expose offsets without parser internals | Yield unchecked integers from a well-framed table | Each reported AIX symbol points to an archive member that the public `member()` API accepts | Resolve every emitted offset; separately corrupt a referenced member header | Cross-API member interoperability | Accepts eager validation, lazy validation, member-index lookup, or direct member parsing. |
| Header offsets may both be zero while a present table may contain zero symbols | Treat an empty iterator and no table as the same API result | `None` means both tables absent; a present zero-count table yields `Some(empty)` | Compare absent, empty-32, empty-64, and empty-plus-nonempty behavior | Presence semantics | Derives from existing `symbols()` Option semantics and fixed-header presence, not private fields. |

## Clause-to-test coverage

| Public requirement | Planned observable test | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Parse either or both AIX global tables | One dual-table archive and isolated single-table archives | `symbols()` yields an empty iterator | Names and offsets appear in 32-then-64 order | IBM fixed header and global-table sections. |
| Decode 8-byte count/offset framing | Values whose bytes differ under decimal, little-endian, and 32-bit interpretations | no entries | exact names and member offsets | IBM specifies `sgetl`/`sputl` 8-byte values. |
| Preserve one name per offset | Valid multi-entry table plus isolated malformed cardinalities | no entries, so positive cases fail | valid entries pass; malformed inputs return `Err` | IBM states equal sequential string and offset counts. |
| Interoperate with `member()` | Resolve yielded symbols and corrupt one target header | no entries | valid targets resolve; malformed target errors | Existing public `ArchiveFile::member` seam. |
| Checked malformed-input behavior | Short count/offset/name regions and oversized count | missing feature or unchecked shortcut | ordinary errors without panic | README reliability promise and `ReadRef` conventions. |
| Preserve absent versus present-empty semantics | Header with no tables versus zero-count table | both look absent/empty | `None` versus `Some(empty)` | Existing `symbols()` return type and zero-offset convention. |

## Environment and harness preflight

- Candidate Phase A previously passed the complete all-feature workspace
  offline as UID 12345 at the exact repository and submodule pins using Rust
  1.90. That verdict predates the submitted Dockerfile and is not carried
  forward as the problem-version verdict.
- The submitted Dockerfile uses the approved Olympus Rust base and `/app`,
  pins the Rust and `cargo-nextest` toolchains, fetches the exact fixture
  submodule when evaluator checkout composition omits it, and warms the locked
  all-feature workspace build.
- A fresh no-cache pristine build produced image
  `sha256:b831bf13a37aa45bca0e66a7c37a2779ad6032f1fdedfe6e2f9a53d2eaf3dd2e`.
  Offline as UID/GID 10001 against a read-only source mount, the complete
  locked all-feature workspace passed 91 executable tests and 10 doctests.
- The first submitted-image attempt was quarantined before any test run:
  `cargo-nextest 0.9.140` requires Rust 1.91 and could not install under the
  repository's pinned Rust 1.90 lane. The Dockerfile now pins the compatible
  `cargo-nextest 0.9.128`; no result from the failed image is reused.
- Tests will use only in-memory deterministic archives; no AIX host, network,
  clock, randomness, writable source tree, or scheduler behavior is required.

This preliminary record does not replace exact Phase B. After tests and both
implementation patches exist, `ENVIRONMENT.md` must record the exact evaluator
composition before any mutation, gap, fairness, or false-positive analysis.

## Design verdict

The trajectory-informed startup gate and fresh pristine Phase A completed, and
the user-authorized escalation ran the candidate's required two-implementation
convergence trial before any hidden patch was written.

Both implementations satisfy the complete provisional contract, pass three
focused positive/negative scenarios, and pass the full locked offline
workspace: 91 pre-existing executable tests, 10 pre-existing doctests, and
their three focused tests. They differ materially in timing and state:

| Trial | Architecture | Production diff | Full offline result |
|---|---|---:|---:|
| A | Stores two member ranges, validates both tables and referenced members when `symbols()` is called, then chains two slice iterators | one file, 96 additions / 27 deletions | 104/104 including doctests |
| B | Parses both tables eagerly into borrowed table descriptors during `ArchiveFile::parse`, tracks explicit presence, then uses indexed iterator state | one file, 116 additions / 15 deletions | 104/104 including doctests |

The SHA-256 identities of the formatted production diffs are
`3176f11196288b8bfa09cd654da05ec7b3d7227a817492e91b3d1f3057567bfc`
for A and
`23514b95fe49cb4ec47629475de4ada7f8a8d20369478fc4dd4aae878fc24f48`
for B. Both pass `git diff --check`.

The two trials converge on the same single existing production module and stay
well below 200 raw production additions even though they include exact name
cardinality, target-member validation, present-empty semantics, dual-table
ordering, and an exact `size_hint`. Their production scope has only two coupled
seams: AIX special-member discovery and the existing archive symbol iterator.
Additional malformed fixtures would strengthen verification but would not add
an implementation boundary or a second production-file surface.

This is not presented as a platform successful-agent median; no solver run or
calibration occurred. It is the candidate's pre-authoring convergence gate,
which was explicitly designed to reject this reserve if two complete
architectures remained thin. The result confirms that risk. Test authoring is
therefore **rejected**. The task must not be rescued by adding z/OS, archive
writing, XCOFF parsing, private representation rules, arbitrary malformed
bytes, or repeated fixture permutations.

No `meta.md`, `test.patch`, `solution.patch`, `solution_approach.md`, gap audit,
fairness audit, false-positive audit, or calibration batch was created. A
future `gimli-rs/object` candidate requires a materially different task that
crosses independently public production subsystems and must restart every gate.
