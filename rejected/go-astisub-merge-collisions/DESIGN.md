# DESIGN - go-astisub collision-safe subtitle merge

Status: `archived-too-easy` on 2026-08-01; closed to further hardening or runs.

Repository: `asticode/go-astisub` at
`52190f1d606f35190d40e86ecb02c31902f30272`.

## Public contract and repository evidence

Fix the existing mutating `(*Subtitles).Merge` so receiver and donor cues keep
the meaning of their named style and region references when the documents use
the same ID for different definitions. The merged document must have unique,
deterministic definition identities, close every supported item, line-item,
region-style, and parent-style reference over those definitions, preserve the
receiver graph and stable equal-time ordering, and not mutate the donor while
resolving collisions.

`subtitles.go` exposes every graph edge and uses stable ordering. TTML reads and
writes all edges independently by ID, providing a public round-trip oracle. SSA
provides a native named-style oracle and WebVTT a native region/cue-setting
oracle. The task does not require a clone algorithm, exact suffix spelling,
semantic deduplication, cyclic/malformed graph support, future alias isolation,
or features a target format cannot represent.

## Trajectory-informed design gate

Searches covered the problem index, candidate registry/successes, subtitles and
namespace/remap tasks, and archived moov, PcapPlusPlus, Calamine, Railway,
glTF, wasm, and ORC records. No prior go-astisub solver trajectory exists. Raw
moov runs 5/10/12 and representative PcapPlusPlus pass/near-pass/failure
evidence were inspected during the candidate gate.

| Evidence role | Problem / run | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | moov-ach run 5 | full baseline and focused pass | Staged multi-file state flow preserved ownership and proactively ran the full Go suite |
| Near-pass | moov-ach run 10 | 118/120 focused | Direct correction missed inverse closure at a linked semantic edge |
| Broad failure | moov-ach run 12 | 100/120 focused | Large patch still leaked tentative mutation and used the wrong metadata owner |
| Independent local pass A | go-astisub demand-aware importer | full suite/focused/race pass | Selectively copies donor nodes while importing directly into receiver; 1 production file |
| Independent local pass B | go-astisub clone/private rewrite | full suite/focused/race pass | Clones donor graph on collision, rewrites private IDs, then reuses original merge; 2 production files |

## Discriminator ledger

| Observed solver behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| Base treats equal ID as equal object | Keep receiver definition globally | Both receiver and donor cues retain meaning | TTML write/reopen with unequal same-ID definitions | Namespace identity | Tests meaning, not pointers or suffixes |
| Moov shallow copy mutated nested source | Rename donor objects in place | Collision handling leaves donor state unchanged | Before/after public graph snapshot | Ownership | Copy-on-write and full-clone designs both pass |
| Near-pass missed linked inverse state | Rewrite cue only | Every supported named edge closes over merged definitions | TTML parent, region-style, item, and span round trip | Transitive closure | Uses repository-defined edges only |
| Go map iteration is unordered | Allocate names in encounter order | Equivalent inputs produce deterministic normalized output | Reverse insertion order, serialize/reopen | Determinism | No exact generated spelling required |
| Rebuilding items can disturb sort | Use unstable ordering | Receiver precedes donor at equal start time | Equal-time public item order | Compatibility | Preserves existing `SliceStable` behavior |
| Convenient overwrite changes old cues | Replace receiver definition | Receiver definitions/references remain intact | Symmetric receiver/donor semantic assertions | Receiver ownership | Allows both proven architectures |

## Clause-to-test coverage

| Public requirement | Planned observable test | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Style collision | TTML receiver/donor cue round trip | Donor binds receiver style | Both retain font family |
| Region collision | TTML region/cue round trip | Donor binds receiver region | Both retain region attributes |
| Transitive closure | Parent style, region style, line item | Links serialize to wrong object | All links resolve to intended definitions |
| Donor non-mutation | Public graph snapshot | In-place rename mutant changes IDs | Snapshot unchanged |
| Determinism | Reverse map insertion and normalized TTML | Map-order allocator varies | Equivalent output graph |
| Stable ordering | Equal-start receiver and donor cues | Rebuilding or resorting items changes tie order | Receiver cue remains before donor cue |

## Environment and harness preflight

- Pin is current v0.42.0, MIT, 701 stars, Go 1.13 module.
- Official `golang:1.25.6-bookworm` digest and committed dependencies are warmed.
- `go test ./...`, `go test -race ./...`, `go vet ./...`, and network-disabled
  replay pass; baseline has 90 named tests.
- Fixtures are tiny in-memory documents; no copyrighted subtitle file or
  network/global state is used.

## Exact-version false-positive audit

Frozen artifacts:

- base commit: `52190f1d606f35190d40e86ecb02c31902f30272`
- `meta.md`: `43efe3271289d2c1fc60651871a2d219f1240187f43dbebcf8dd922a61d4ea13`
- `test.patch`: `da8c93beaeb1320868da68488a2a7ff23e382abb00b58f5b312e7a9ecd65df90`
- `solution.patch`: `c84f7cce962ee6285a03746496baf1ba2eb591100244dcec3d4f3e86c4528778`
- local image: `sha256:23a11a3bb37d5180e083d107965e6d9f40605765b4786e855ae3c895c936017d`

The clause-to-test table above maps every participant-facing requirement to its
strongest probe. Four compiling repository-grounded mutants were exercised:

| Mutant | Plausible shortcut | Focused result | Complete legacy result | Audit disposition |
|---|---|---|---|---|
| omit line-item rewiring | repair cue-level references only | rejected | not needed | Existing transitive-reference probe fails |
| omit parent-style rewiring | copy definitions shallowly | rejected | not needed | Existing parent-chain probe fails |
| omit item-region rewiring | solve styles but not region ownership | rejected | not needed | Existing region/transitive probes fail |
| rename donor graph in place | avoid an ownership copy | rejected | not needed | Donor TTML serialization changes |

No mutant survived the revised focused suite. Donor immutability is checked by
comparing its complete TTML serialization before and after the merge, not by
requiring pointer identity or a private copying strategy. No test is present for
noncolliding object identity, suffix spelling, map layout, malformed graphs, or
private helper structure. Representative legitimate implementations remain
accepted: both the demand-aware importer and clone/private-rewrite architecture
satisfy the behavioral contract.

Final patch-state matrix in the pinned official-image environment:

| State | Legacy mode | Focused mode |
|---|---:|---:|
| base + tests | 90 pass | 7 fail |
| base + tests + reference | 90 pass | 7 pass |

The reference also passes `go test -count=1 ./...`, `go test -race -count=1
./...`, and `go vet ./...`. Each of the six focused test entities fails on base
and passes with the reference. Mutation worktrees were isolated from the frozen
patch worktrees; no survivor remained in the attempted set.

After the final prompt-only edit removed the discoverable reference-type
examples, the exact matrix and all four mutants were replayed against the hash
above: legacy base/reference passed, focused base failed 6/6, focused reference
passed 6/6, and every mutant remained rejected.

The T4 revision added the missing independent region-allocation discriminator:
an occupied obvious fallback, reversed region-map insertion order, unique and
stable generated identity, cue rewiring, and TTML semantic round trip. On the
new immutable version, base fails all 7 focused entities; the reference passes
all 7 plus the 90-test legacy, full, race, and vet lanes; all four audit mutants
remain rejected. Replaying the four saved unhinted agent patches produced 4/4
passes without modification, so the discriminator closes a correctness gap but
does not improve the observed Olympus difficulty. Those old runs are trajectory
evidence only; calibration for this revised version is 0/10.

## Design verdict

The trajectory gate, discriminator ledger, exact-version false-positive audit,
clean patch application, harness matrix, full suite, race run, vet run, and
Docker build are complete. The task is correct but terminally archived for the
Olympus lane: 4/4 unhinted agents solved it, and all four saved patches passed T4
unchanged. No evidence-backed hardening lever remains.
