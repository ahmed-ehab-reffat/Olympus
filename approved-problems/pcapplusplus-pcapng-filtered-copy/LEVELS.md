# LEVELS - PcapPlusPlus section-aware PCAPNG filtered copy

Target: 1–5 solves in one immutable ten-run batch. Successful-solution medians
must be at least two files, 20 agent messages, and 200 strict effective production
LOC.

## Retired level 1

L1 was the honest uncompressed section-aware filtered-copy contract. Two cold
local runs passed 2/2 and a later Nova platform run also passed. Their
production work was materially larger than the reference, so the size concern
was disproved, but the clean solve rate was a too-easy signal.

Its final reference had 158 effective additions under the review counter and
its valid fixtures used only Interface ID 0. It also distinguished complete
Custom Block policy without exercising standardized Custom Options inside a
retained block.

## Retired level 2

Status: `retired after 4/4 unhinted working-pool passes`.

L2 retains the same core operation and adds three public format boundaries:

- preserve and select among multiple section-local IDBs, including a valid EPB
  on Interface ID 1;
- preserve both standardized Custom Option policies inside retained blocks;
  and
- validate bounded, padded options and Name Resolution records in retained
  standardized blocks.

The exact reference is 253 raw production additions and 231 non-comment,
non-blank additions across two files. The focused suite has nine independent
CTest entities. Its 21-mutant audit has zero survivors, with the six new
mutants isolated among `InterfaceSelection`, `OptionPreservation`, and
`MalformedOptions`.

Its first working-pool batch under `agent-runs2/` produced four legitimate
passes with 69/69 base and 9/9 focused cases in every run. All four production
solutions were substantive and above the LOC floor, but the 100% pass rate
exceeded the 50% cap.

## Retired level 3

Status: `retired after three completed 10/11 runs failed the same test`.

L3 adds two distinct valid-input boundaries:

- option lists in retained standardized blocks may end exactly at the block
  boundary without an explicit `opt_endofopt`; and
- the current BPF expression is observable through a non-TCP filter fixture.

It also closes the reported malformed-SPB, SHB/ISB/NRB-option, and minor-version
coverage gaps. The exact reference is 254 raw production additions and 232
non-comment, non-blank additions across two files. The focused suite has 11
CTest entities and the 28-mutant audit has zero survivors.

The four retired L2 solutions replayed at 1/4 on L3: one passed 11/11 and
three failed only `OptionTermination`. The subsequent unhinted L3 batch had
three completed runs, all 10/11 with only that same failure. The fourth run
was incomplete. This is not a broad difficulty spread, so L3 is not extended.

The exact `test.patch` SHA-256 is
`6bfafeaa05d84da563cfb54f5b6312ce13fc176eab3080d8ea04fcde382816bc`.
No predecessor solve counts toward this immutable version.

## Retired level 4

Status: `retired before calibration after an unfair minor-version assertion`.

L4 makes the block-end option-list rule explicit and adds three independent
valid-input behaviors:

- default and cleared filters retain all EPBs and SPBs;
- readers ignore an IDB's reserved field while the copy preserves its bytes;
  and
- local-use blocks remain opaque retained blocks.

The reference behavior is unchanged except for the new explicit prose because
it already satisfied all three behaviors. It remains 254 raw and 232 strict
effective production additions across two files. The focused suite has 14
CTest entities, and the 31-mutant audit has zero survivors.

Raw replay of the three completed L3 solutions is 0/3 because all retain their
historical `OptionTermination` defect. After normalizing only that now-explicit
rule, the replay is 1/3: Nova 1 fails only `LocalUseOpacity`, Nova 2 fails only
`ReservedFieldOpacity`, and Nova 3 passes. These are retrospective design
results, not L4 calibration runs.

The exact `test.patch` SHA-256 is
`f5a63adbc9338e297ec673f0c92ab6b2d3719771b9d586eb52a027375edbcb6c`.
No predecessor outcome counts toward L4.

L4 was not calibrated. Fairness review found that `MalformedFraming` required
an otherwise valid SHB 1.1 capture to fail even though the prompt did not name
minor zero as exclusive and bundled LightPcapNg preserves arbitrary minor
values. That defect invalidates the immutable version despite its otherwise
clean matrix and discriminator split.

## Retired level 5

Status: `retired after 7/10 unhinted working-pool passes`.

L5 retains all 14 L4 scenario entities and its independent filter-state and
opacity boundaries. It narrows version validation to the supported major
version, removes the 1.1 rejection from `MalformedFraming`, removes the
minor-zero reference check, and retires the corresponding mutant.

The exact reference has 253 raw and 231 strict effective production additions
across two files. The exact 30-mutant active set has zero survivors. An
audit-only SHB 1.1 exact-copy probe passes, but minor-version permutations are
not used as hidden discriminators.

Raw and prompt-normalized replays are unchanged from L4. The normalized split
is 1/3: Nova 1 fails only `LocalUseOpacity`, Nova 2 fails only
`ReservedFieldOpacity`, and Nova 3 passes 14/14. These remain retrospective
design evidence.

The exact `test.patch` SHA-256 is
`4727aaa1969cab52bcbd9156ed7b9dd9ee38af396403d15e42353d0ef4fecec4`.
Its exact `agent-runs4/` batch produced seven passes and three substantive
failures, with every baseline at 69/69. The 70% solve rate exceeds the 50%
cap, so the version cannot be extended in place.

## Accepted level 6

Status: `accepted on 2026-08-01 after trajectory hardening and exact-version
audit`.

L6 retains every fair L5 requirement and adds three independent public
boundaries:

- invoke the exact API through a const reader reference;
- support a successful copy when source and destination use the same path; and
- validate EPB options only when that packet block is retained, while still
  validating fixed fields, references, lengths, and packet-data bounds before
  filtering.

The focused suite has 16 CTest entities. The same-path fixture uses the valid
DSB-free filter-state capture, keeping it independent from the three L5 DSB
failures. All ten L5 solutions pass the const and same-path additions. Exact
L6 replay leaves Nova 6 and 7 at 16/16; five former passes fail only
`DiscardedPacketOptions`; the other three retain separate DSB/multi-section
failures. The projected solve rate is therefore 2/10 without concentrating
every failure in one case.

The exact reference has 254 raw and 232 strict effective production additions
across two files. All 33 active mutants are killed and the restored reference
passes 16/16. The exact `test.patch` SHA-256 is
`00d7213a423facc6ca47b43d2ba5eb2f5365e303eac9e1a45ae002c26d54cfe8`.
No predecessor outcome counts toward L6.

The platform accepted this exact package on 2026-08-01, as confirmed by the
user. The acceptance does not convert the L5 batch or L6 retrospective replays
into a new calibration batch; their recorded version ownership remains intact.
