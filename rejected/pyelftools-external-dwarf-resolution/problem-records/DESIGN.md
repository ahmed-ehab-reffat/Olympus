# Design - pyelftools external DWARF resolution

Status: `rejected for overlap and archived on 2026-08-20;
calibration 0/10`.

Repository: `eliben/pyelftools` at
`e5fa2a4f3e665d082cfc453fd0877f5516200926` (2026-07-30).

Production language: Python. Task type evaluated: enhancement.

## Iteration solvability forecast

- Start of candidate design: **2-4 successful solvers out of 10**, a fresh
  expectation inside the accepted 1-5/10 band.
- Start of escalation: **2-4/10** for the combined external-resolution task.
- End of escalation: no submission version exists because the central behavior
  is publicly owned. Removing build-ID/debug-root resolution leaves mainly
  per-hop loader rebasing and cycle bookkeeping in one resolver module,
  forecast **7-10/10**, outside the accepted band.

The initial estimate was supported by independent search, identity, and
per-hop context boundaries. The ending estimate is based on the pinned source:
all remaining mechanics are concentrated in `elftools/elf/elffile.py` around
`get_dwarf_info()` and `get_supplementary_dwarfinfo()`. Neither estimate is a
compatibility replay. No pyelftools solver run or artifact version exists, and
calibration remains 0/10.

## Retired technical contract

The proposed task would have completed the repository-native external-debug
resolver by:

1. preserving `.gnu_debuglink` CRC validation while searching a sibling,
   `.debug/`, and explicitly supplied debug roots;
2. resolving a stripped binary through its GNU build ID at the conventional
   `.build-id/xx/yyyy.debug` path and checking candidate build-ID identity;
3. rebasing `.debug_sup` and `.gnu_debugaltlink` at every containing ELF;
4. preserving strict `follow_links=False`, deterministic mismatch handling,
   and cycle termination; and
5. retaining a custom-loader extension without prescribing a resolver class,
   cache, or stream ownership representation.

The pin makes this technically coherent. `get_dwarf_info()` has an explicit
build-ID TODO, validates only one literal debuglink through `stream_loader`, and
warns that inheriting the primary loader gives an external file the wrong base
for its supplementary link. `get_supplementary_dwarfinfo()` opens the next
stream without a loader, so deeper chains cannot resolve. ELF note parsing
already recognizes `NT_GNU_BUILD_ID`.

These facts do not establish novelty. The upstream audit below is terminal.

## Trajectory-informed design gate

Searches covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, dated candidate reports, and all local
problem/candidate/archive records for pyelftools, ELF, DWARF, external debug
files, build IDs, resource identity, chained resolution, and relative bases.
No pyelftools problem or solver trajectory exists.

Relevant compact records read included Object AIX big archives, accepted h5py
VDS relocation, accepted PcapPlusPlus filtered copy, and accepted Statig local
transitions. Representative raw records were inspected directly from
`archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz` and
`archive/h5py-vds-copy-relocation/agent-runs3.zip`:

| Evidence role | Raw record | Outcome | Architecture and transferable behavior |
|---|---|---|---|
| Legitimate pass | PcapPlusPlus `agent-runs4/Nova_Nova_1` | 69/69 base and 14/14 focused | Added a separate 532-line scanner. Its distinct state organization confirms that tests should observe resolution, not a private resolver layout. |
| Legitimate pass | PcapPlusPlus `agent-runs4/Nova_Nova_6` | base and 14/14 focused | Integrated about 406 additions into the existing device path. It reached the same public result through a materially different architecture. |
| Near-pass | h5py VDS `Nova_Nova_6` | 138/138 base and 22/24 focused | Its 182-production-addition helper design lost same-file `.` identity and variable-length Unicode attributes. Resource identity needs an independent oracle. |
| Broad failure | PcapPlusPlus `agent-runs4/Nova_Nova_10` | 69/69 base and 9/14 focused | A 533-line scanner reused the wrong enclosing section boundary and mishandled a separate option producer. Large size did not prevent stale-context errors. |

The analogs inform shortcut selection only. Upstream pyelftools behavior and
the public task would have remained the fairness authority.

## Retired discriminator ledger

| Repository / trajectory evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary | Status and anti-overfit rationale |
|---|---|---|---|---|---|
| h5py near-pass lost same-file identity | accept the first name match without validating resource identity | CRC or build ID matches the requesting ELF metadata | place a wrong earlier candidate and a valid later candidate | identity | Retired by ownership; enumeration and caching strategy would remain free. |
| Pcap broad failure reused an old section context | resolve every nested reference relative to the root ELF | each relative link is based at the ELF containing it | stripped primary -> external debug file in a subdirectory -> supplementary sibling | chained context | Retired; only resolved DWARF behavior would be observed. |
| pinned source handles one literal sibling | implement sibling `.gnu_debuglink` only | announced roots and build-ID mode resolve their standard candidate families | sibling, `.debug/`, root, and build-ID-only arrangements | search producer | Build-ID/root lookup is exactly owned by open issue #186. |
| successful analogs differ architecturally | require one resolver/cache object | custom-loader and filesystem paths remain behaviorally viable | equivalent filesystem and loader-backed chains | extension boundary | Retired; no call counts, helper names, or cache shape would be asserted. |
| recursive debuglink path has no visited context | follow links without termination state | a cycle terminates deterministically | two valid links returning to prior resources | lifecycle | The remaining unowned bookkeeping is too narrow once the owned core is removed. |

## Upstream ownership gate

The preliminary shortlist search was incomplete. Open
[issue #186](https://github.com/eliben/pyelftools/issues/186), "Support for
separate dwarf files?", gives a stripped Ubuntu loader and its exact
`/usr/lib/debug/.build-id/6f/...debug` companion, asks how pyelftools can
correlate them, and received the maintainer response that the behavior was not
supported and that pull requests were welcome. The issue remains open.

Merged [PR #596](https://github.com/eliben/pyelftools/pull/596) later introduced
the current `.gnu_debuglink` path and CRC validation. Its description explicitly
states that build-ID linking through the GNU separate-debug-files convention is
not supported. It closed issue #594, not #186. The pinned source retains the
matching build-ID TODO and the default branch remains exactly at the pin.

Thus the candidate's central build-ID/debug-root requirement is neither an
unowned inference nor a novel combination: it is the concrete example and
requested feature of an open upstream issue. Adding `.debug/` search,
candidate fallback, nested rebasing, and cycles around it would not erase that
overlap. Cosmetic narrowing to rebasing/cycles removes the cross-family depth
that supported the original 2-4/10 estimate.

## Environment and artifact status

The exact pin was cloned only for read-only source and history inspection. The
ownership result occurred before the mandatory environment gate, so no
Dockerfile, prompt, hidden tests, reference patch, prototype, mutation audit,
solver run, or calibration batch was created. No environment verdict is
claimed.

## Design verdict

Reject at **4/10 current; 9/10 preliminary** for direct open-issue overlap.
Do not resubmit the same behavior as build-ID discovery, external debug roots,
separate DWARF correlation, or a broader resolver chain. Reconsider pyelftools
only through a materially different subsystem after a fresh ownership and
trajectory gate.
