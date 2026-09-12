# DESIGN - umoci forward hardlink extraction

Status: `rejected after pre-authoring convergence trial; Docker preflight only, no prompt/test/reference or calibration artifacts`.

Repository: `opencontainers/umoci` at
`f5d1219acaf67127ebacf6306776d3ff465735ea`.

## Public contract and repository evidence

Make `layer.UnpackLayer` accept an OCI layer tar stream whose hardlink entry
appears before the in-layer entry that supplies its target. Once extraction
completes, the link and target must identify the same inode, including when the
target is itself reached through a forward-hardlink chain or is a symlink.
Normal archive replacement order still applies: a later entry for a pending
link's destination supersedes that earlier link entry. If the target never
becomes available, including an unresolvable cycle, extraction returns an
ordinary error rather than silently omitting or fabricating an entry.

This contract is repository-grounded:

- `oci/layer/unpack.go` owns the complete-layer boundary and currently streams
  every header through one `TarExtractor`.
- `oci/layer/tar_extract.go` already creates real hardlinks, scopes hardlink
  targets beneath the rootfs without dereferencing the final component, omits
  independent hardlink metadata, and explicitly records that target-before-link
  ordering is the remaining failure.
- `TarExtractor.upperPaths` already retains layer-local ordering state for
  whiteout semantics, while every non-directory entry clobbers the preceding
  object at the same destination. That makes later-entry-wins behavior
  discoverable without exposing a private pending-link representation.
- Existing `TestUnpackHardlink` establishes inode identity, hardlinks to
  symlinks, and metadata behavior.
- The repository's closed issue 29 explains that tar entry ordering is not
  reliable and that link creation may need to be completed after later entries
  are seen. It does not provide a surviving implementation or test.

The contract does not prescribe a queue, graph, retry loop, callback, public
finalizer, map shape, or error wording. It applies to same-layer forward
references only; cross-layer hardlink policy is outside scope.

## Trajectory-informed design gate

Searches covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, all compact problem/archive records for `umoci`,
hardlinks, tar extraction, entry ordering, pending links, and OCI layers, plus
the complete fetched umoci source, branches, tags, and Git history. No earlier
umoci problem, candidate record, solver run, or forward-hardlink trajectory
exists. The empty `candidates/umoci-forward-hardlinks/` directory was the only
pre-existing local seed.

The closest raw evidence is the accepted PcapPlusPlus PCAPNG transformation,
which also had to preserve ordered archive-like records while deferring
decisions until enough framing state was known. The preserved
`archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz` manifest and the
raw `agent-runs4` evaluator records, workspace diffs, and trajectories for runs
1, 3, and 6 were inspected. The rejected `object` AIX archive escalation was
also reviewed because two independent implementations converged on one small
production seam.

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Analogical legitimate pass | PcapPlusPlus `agent-runs4/Nova_Nova_6` | 69/69 base and 14/14 focused | A streaming block scanner retained section-local state, validated framing before committing output, and preserved opaque bytes. Its decisions were staged without requiring one storage representation. |
| Analogical near-pass | PcapPlusPlus `agent-runs4/Nova_Nova_1` | Passed the predecessor suite; later failed only the discarded-packet validation-order discriminator | A full buffered parser validated data before learning whether it was semantically needed. This supports testing commit timing separately from parsing breadth. |
| Analogical broad failure | PcapPlusPlus `agent-runs4/Nova_Nova_3` | 69/69 base and 10/14 focused | A dedicated parser collapsed a payload and its trailing options into one extent, causing four failures from one incorrect state boundary. This warns against counting many chain fixtures as independent depth. |
| Domain-specific pass / near / broad failure | unavailable | No umoci run exists | Repository behavior and an honest convergence prototype must govern the initial decision. |

No hidden assertion name, fixture path, or private call sequence from those runs
is reused here.

## Discriminator ledger

| Observed solver or repository behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| Current extraction calls `link(2)` immediately and returns `ENOENT` | Assume tar target-before-link order | A same-layer hardlink can precede the entry that supplies its target | Extract a link-before-target layer and compare inode identity and content | Layer completion / deferred resolution | Any pending queue, graph, rescan, or staged extractor can pass. |
| A single retry handles only one dependency level | Retry deferred links once in input order | Forward-hardlink chains resolve whenever their terminal target is supplied | Extract a reversed multi-link chain and compare every inode | Dependency ordering | Tests observable inode equivalence, not an algorithm or map layout. |
| Existing code deliberately does not dereference the last hardlink component | Resolve through `stat` or copy target contents | A hardlink to a symlink shares the symlink inode and link text | Use a later symlink target and compare `lstat` identity plus `readlink` | Filesystem object identity | Both direct `linkat` and repository wrappers pass; content copying does not. |
| Every later non-directory entry clobbers an earlier destination | Replay an obsolete deferred link after its path was replaced | The last archive entry for a destination determines the final object | Put a later ordinary entry at a pending link destination and inspect final type/content | Archive overwrite order | Derives from current sequential unpack behavior and accepts any cancellation strategy. |
| The existing FIXME returns the original link error | Swallow links still missing at end or loop forever on cycles | Completion fails deterministically when no valid target can be reached | Unresolved and cyclic layers return an error after consuming the finite stream | Invalid dependency graph | No exact error text, timeout threshold, or private cycle detector is required. |
| Hardlink targets are scoped through `SecureJoinVFS` | Defer before validating or later join paths unsafely | Deferred processing preserves the existing rootfs confinement | A forward target path with escaping components cannot create an external link | Security boundary | Reuses the public extractor safety contract and permits eager or deferred validation. |

## Clause-to-test coverage

| Public requirement | Planned observable test | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Resolve one forward hardlink | Same-layer link precedes a regular target | returns `ENOENT` | succeeds with shared inode | source FIXME and issue 29 |
| Resolve forward chains | Reversed chain ending in a supplied object | fails on first link | all paths share the terminal inode | complete-layer semantics and ordinary hardlink identity |
| Preserve symlink inode identity | Forward hardlink targets a later symlink | returns `ENOENT` | hardlink shares symlink inode and text | existing `TestUnpackHardlink` |
| Preserve later-entry-wins replacement | Pending destination is later replaced before target appears | either fails early or would replay stale link | later replacement remains final | current clobber-before-create extraction order |
| Reject unresolved dependencies | Missing target and finite cycle | returns early on first link | returns an ordinary completion error | current error behavior and finite `UnpackLayer` contract |
| Retain root confinement | Forward hardlink uses an escaping target spelling | fails during link setup | still fails without touching outside root | current `SecureJoinVFS` hardlink path |

## Environment and harness preflight

- Host Docker 29.2.1 on arm64 was available with 89,934,584 KiB free, above
  the 12 GiB gate.
- The official Go base resolved to
  `public.ecr.aws/d3j8x8q7/olympus-base-go@sha256:fed7c2f8d5014c9cd9635da6ab143e90f219b67bc35a236a48a30814f0e4b990`.
- A no-cache pristine build produced image
  `sha256:259dcbcc6d034ee45110f1f1d591071b363e3df83105a4d8c5402dfb368afd9b`.
- Offline as UID/GID 10001 against both the image copy and a read-only exact
  checkout, `go build ./...` and `go test -run '^$' ./...` passed. The complete
  ordinary `go test ./...` lane also passed offline as UID/GID 10001.
- `go`, `go-junit-report`, `go.mod`, `go.sum`, `vendor/modules.txt`, the module
  cache, and the Go build cache were present and readable; dependency lookup was
  disabled with `GOPROXY=off` and `GOSUMDB=off`.
- Planned fixtures are in-memory tar streams and temporary directories. They do
  not need a container runtime, network, clock, randomness, special filesystem,
  or root privileges.

This is Phase A only. Exact evaluator composition remains mandatory if hidden
tests and a reference patch survive the convergence trial.

## Design verdict

The startup gate and pristine Phase A passed, and the user-authorized
escalation completed the required honest scope trial before any hidden patch
was written.

The complete prototype covers direct and chained forward links, hardlinks to
symlink inodes, exact and ancestor replacement, a lower-layer target replaced
later by the current layer, unresolved cycles, and existing path confinement.
It changes only `oci/layer/unpack.go` at 54 raw additions / 0 deletions and 48
strict nonblank, non-comment additions. The complete ordinary `go test ./...`
lane and all six prototype scenarios pass offline as UID/GID 10001. Its
formatted production diff is preserved in `prototype.patch` with SHA-256
`1083c6f67e25cd14ff73e661b09daa04344e264a0f30a862cd2d4ae02abb2d20`.

The repository already supplies the extractor, real hardlink operation,
rootfs-scoping rules, upper-path tracking, overwrite behavior, and the
complete-layer loop. The missing work is one pending-header collection plus a
fixed-point retry. Moving that state into `TarExtractor`, exposing a finalizer,
or replacing the slice with a dependency map changes private organization but
does not add another public production boundary. Closed issue 29 also sketches
the same delayed-link architecture, making the path unusually reconstructable.

This is sufficient repository and measured convergence evidence to reject the
task for Olympus long-horizon scope. More chain lengths, target spellings,
whiteout combinations, or malformed graphs would enlarge the test matrix but
would not create a distinct implementation boundary. Cross-layer hardlink
policy, tar writing, overlayfs behavior, or general extraction transactions
would be unrelated scope and must not be added to pad the task.

Test authoring is therefore **rejected**. No `meta.md`, `test.patch`,
`solution.patch`, `solution_approach.md`, exact Phase B, gap analysis, fairness
analysis, false-positive audit, solver run, or calibration batch was created.
Reconsider umoci only through a materially different task that crosses
independent production subsystems and restarts every gate.
