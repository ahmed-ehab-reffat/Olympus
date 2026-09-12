# DESIGN - Afero copy-on-write namespace mutations

Status: `rejected as previously implemented; archived 2026-08-15`.

Repository: `spf13/afero` at
`768f1fb0e5535b77d90e44c531aacd652aabd96a`.

Primary and proposed production language: Go.

Task type: enhancement.

## Public contract and repository evidence

Extend `CopyOnWriteFs` so its ordinary `Fs` namespace mutators operate on the
merged logical filesystem, including entries that exist only in the read-only
base, while never mutating that base.

The proposed behavior is:

- `Remove` hides a logically existing file or empty directory, including a
  base-only entry. It retains the ordinary `Fs` errors for a missing path and a
  non-empty directory.
- `RemoveAll` hides the selected logical subtree and returns nil for an absent
  path. Recreating a removed directory produces a new empty logical directory;
  old base children do not leak back into it.
- `Rename` moves a base-only, layer-only, or merged file/directory tree in the
  logical namespace. The old path becomes absent, the destination contains the
  complete pre-rename logical source, and replacement does not expose stale
  base-only destination children.
- Later `Create`, `OpenFile`, `Mkdir`, and `MkdirAll` calls can recreate removed
  paths. An exact recreated file overrides its base object, while a recreated
  directory after subtree removal remains opaque to the old base subtree.
- `Stat`, `Open`, and directory iteration agree on what is logically absent.
  No whiteout or bookkeeping entry is visible through the composed filesystem.
- A failed multi-step namespace mutation leaves the logical source and
  destination views unchanged. File contents, modes, directory structure, and
  regular-file/directory identity survive a successful rename.

These are behavioral requirements, not a marker format or data-structure
contract. An in-memory deletion journal, encoded upper-layer whiteouts, opaque
directory state, eager copy-up, and lazy path redirection are all potentially
legitimate architectures if the public observations agree.

The seed is repository-native. `Fs` already promises `Remove`, `RemoveAll`, and
`Rename`; the shared repository tests establish missing-path removal,
destination replacement, and directory-tree rename behavior. The current
`CopyOnWriteFs` nevertheless returns `EPERM` for a base-only rename or removal.
If a name exists in both layers, `Remove` deletes only the upper entry and then
allows the base entry to reappear. `Open` and `UnionFile.Readdir` already own
the merged-directory seam, while the README presents `CopyOnWriteFs` as a
sandbox in which application modifications are isolated from the base. Full
namespace mutation is therefore a coherent extension of an existing public
composition type, not a generic new filesystem utility.

The leading alternative was failure-atomic `copyToLayer`. It was not selected:
the existing helper already removes a partially copied output on copy/stat/close
failure, and a stronger temporary-file publication change would be localized
and close to the accepted PcapPlusPlus atomic-publication neighborhood. The
namespace seed instead crosses logical lookup, merged directory iteration,
subtree opacity, copy-up, replacement, path identity, and commit
timing.

## Trajectory-informed design gate

Searches covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, all compact `SUMMARY.md`, `DESIGN.md`, `LEVELS.md`,
`ERRORS.md`, `RUNS.md`, and `PLAN.md` records for Afero, filesystem
abstractions, copy-on-write, overlays, whiteouts, tombstones, namespace
isolation, copy-up, rename, deletion, and atomic copy. No earlier Afero record
or Afero solver trajectory exists.

The closest same-domain compact records were rejected wazero reusable preopen
namespaces and rejected umoci forward-hardlink extraction. Wazero warns against
inventing live resource-clone semantics without an abstraction contract; this
seed stays within Afero's existing `Fs`, `File`, `Lstater`, `Linker`, and
`LinkReader` behavior. Umoci warns that many whiteout fixtures do not create
depth when they all exercise one pending-entry loop; this design therefore
separates lookup precedence, directory opacity, tree relocation, object
identity, and failure publication rather than counting more names as more
boundaries.

Raw evidence was inspected from
`archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz` after reading its
manifest. The selected `agent-runs4` evaluator results, solution patches,
workspace diffs, run records, and agent trajectories were read directly.

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | PcapPlusPlus L6 replay, `agent-runs4/Nova_Nova_6` | 69/69 baseline and 16/16 L6 replay; about 406 production additions plus declaration | A streaming scanner in the existing reader source kept section-local interface state, deferred parsing of discarded packet options, and published through a temporary destination. It demonstrates that validation and publication order can be independently observable without requiring one buffer architecture. |
| Near-pass | PcapPlusPlus L6 replay, `agent-runs4/Nova_Nova_1` | 69/69 baseline and 15/16 L6 replay | A separate roughly 532-line streaming source validated discarded packet options too eagerly. Its staged destination and section model were otherwise complete. The generalized lesson is to validate only the state a public operation depends on and to commit logical changes only after required work succeeds. |
| Broad failure | PcapPlusPlus L6 replay, `agent-runs4/Nova_Nova_3` | 69/69 baseline and 11/16 L6 replay | A roughly 448-line dedicated parser collapsed Decryption Secrets payload and trailing options, causing a multi-test family failure, and also missed the later discarded-packet boundary. It shows that repeated fixtures around one mistaken extent are one failure family, not several discriminators. |
| Domain-specific pass / near / broad failure | unavailable | No Afero namespace-mutation run exists | Frozen repository behavior, a pristine environment gate, and honest independent prototypes must govern the initial scope decision. |

No hidden test name, fixture path, byte sequence, or private call order from the
PCAPNG evidence is reused.

## Discriminator ledger

| Observed solver or repository behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| Current `Remove` deletes the layer entry and exposes the same base name again, or returns `EPERM` for a base-only name. | Treat removal as an upper-backend operation only. | A successful logical removal makes the name absent while the base object remains unchanged. | Build overlapping and base-only entries; remove through the composed `Fs`; compare `Stat`, `Open`, parent iteration, and a direct base read. | Overlay precedence / exact whiteout. | Any journal, marker, or virtual lookup architecture can pass; the marker representation is not inspected. |
| A flat exact-name tombstone can hide a directory but cannot describe its later recreation. | Clear a directory tombstone on `Mkdir` and merge all old lower children back in. | Recreating a removed subtree begins as an empty logical directory, while later upper children remain usable. | `RemoveAll` a populated base tree, recreate its root, add one child, and enumerate/open the result. | Opaque-directory lifecycle. | This tests ordinary delete-and-recreate behavior, not a particular opaque-bit encoding. |
| Calling only `layer.Rename` moves upper entries but loses base-only members of a merged source directory. | Rename only the currently materialized upper tree. | The destination of a successful rename contains the complete logical source tree and the source is absent. | Rename base-only and mixed trees, then compare recursive public snapshots and the untouched base. | Cross-layer tree relocation. | Eager materialization, redirects, or another complete logical plan all pass. |
| A source-only whiteout leaves lower entries at an existing destination visible. | Move source data without replacing or making the destination namespace opaque. | Rename replacement exposes exactly the moved source view, not stale base-only destination descendants. | Rename a mixed source over a destination with distinct lower and upper children; recursively inspect both paths. | Destination replacement / namespace opacity. | The oracle follows existing rename replacement semantics and does not constrain commit mechanics. |
| The Pcap near-pass validated discarded state before it knew that state mattered. | Mutate whiteouts or delete upper entries before checking that `Remove` targets an empty logical directory or that rename copy-up can complete. | A failed namespace operation preserves the observable source and destination views. | Use a non-empty logical directory and a deterministic failing `Fs` wrapper; snapshot public views before and after the error. | Validation and commit timing. | Faulting implementations are permitted by the public `Fs` interface; no internal call count or exact error text is required. |
| String-keyed bookkeeping can disagree for equivalent path spellings or hidden ancestors. | Record raw caller strings and check only exact keys. | Logical lookup and mutation use the same path identity as the participating Afero backends. | Remove or rename through a cleaned alias and access through another equivalent spelling, including a child of a hidden ancestor. | Path normalization / ancestor lookup. | Uses repository and Go filepath behavior, without requiring a map key format. |
| Current creation falls through to base-parent checks before writing the layer. | Never reconcile deletion state when recreating a name. | Creation after deletion makes the new upper object visible without resurrecting the removed object or unrelated lower subtree. | Remove, recreate as file and directory in separate cases, write, and compare logical/base views. | Mutation-state transition. | This is a public lifecycle transition shared by all whiteout implementations. |

## Clause-to-test coverage

This is a preliminary map. It authorizes prototype design, not `test.patch`.

| Public requirement | Planned observable test | Pristine behavior | Complete prototype behavior | Fairness evidence |
|---|---|---|---|---|
| Remove base-only and overlapping files | Logical read/stat/list absence; direct base still present | `EPERM`, or removed upper reveals base | absent logically; base unchanged | `Fs.Remove`, generic `TestRemove`, sandbox README |
| Reject non-empty directory removal without changes | Snapshot before/after ordinary `Remove` | may return `EPERM` before logical emptiness is considered | ordinary non-empty error; snapshots equal | filesystem removal semantics and repository generic suite |
| RemoveAll and opaque recreation | Delete populated base tree, recreate root, list one new child | base tree is still visible or operation is forbidden | only new child visible | `Fs.RemoveAll`, sandbox isolation, merged-directory API |
| Rename base-only file and tree | Compare content/tree/mode at destination and absence at source | `EPERM` | logical move succeeds; base unchanged | `Fs.Rename`, generic file and MemMap directory tests |
| Rename a mixed directory | Recursive before/after logical snapshot | only layer subtree can move | complete merged tree moves | `CopyOnWriteFs.Open` and `UnionFile.Readdir` merged view |
| Replace an existing logical destination | Distinct source/destination descendants | unsupported for base source or leaks lower destination | destination equals source view | generic rename replacement test |
| Preserve failure state | Inject deterministic create/write/rename failure in the layer | no composed guarantee | public views unchanged on failure | explicit enhancement clause plus `Fs` error surface |
| Recreate deleted names | file and directory lifecycle | forbidden or base children return | new upper object visible with correct opacity | ordinary filesystem lifecycle and sandbox contract |

## Environment and harness preflight

- Host preflight on 2026-08-15 found Docker server 29.2.1 and 117,039,684 KiB
  free before the checkout was created.
- The frozen repository has 19 root-module test files and 125 root test,
  example, or benchmark declarations. The root module has only
  `golang.org/x/text`; `gcsfs` and `sftpfs` are separate nested modules and are
  not on the proposed core `CopyOnWriteFs` evaluator path.
- The intended pristine lane is root-module `go build ./...`, compile-only
  tests, and complete `go test ./...`, converted to JUnit, with module lookup
  disabled and an arbitrary non-root UID against both image-copy and read-only
  bind-mount layouts.
- Static Phase 0 passed: the disposable Dockerfile begins with the exact
  approved general Olympus base, uses only `WORKDIR /app`, performs dependency
  warming and `go build ./...` but no test during image construction, and ends
  with `CMD ["/bin/bash"]`.
- A no-cache build resolved the approved base to
  `sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`
  and produced untouched image
  `sha256:002b074c6f96b7533b53931514b10e6cbc3c9e118cdcd963cdd7f9921d730d07`.
- Offline as UID/GID 20002, both the image-copy `/app` layout and a read-only
  bind of the exact checkout passed `go build ./...`,
  `go test -count=1 -run '^$' -v ./...`, and
  `go test -count=1 -v ./...`. Each full JUnit report contains 176 cases,
  zero failures/errors, and one skip; the root package contributes 153 cases.
- `go version go1.26.1 linux/arm64`, `go-junit-report`, `go.mod`, `go.sum`, the
  module cache, and the build cache were readable. `GOPROXY=off`, `GOSUMDB=off`,
  and `GOFLAGS=-mod=readonly -buildvcs=false` were effective.
- Image-layout full log/XML SHA-256 values are
  `a26536c8dc35b8d8633dec6445a1ba8f8110c1f66b9f136cd7d121e5d1d014ab`
  and `4c367631bfab8f0c22e4851b6387ed7fef86ead8395ce2ea262544d659328c08`.
  Read-only-layout values are
  `86d9bfed38faeedd5664e44cb998caa980c047b47dc052c61d5859ea2f78eb2f`
  and `f17346d8b21e210f2d9df46c4dffd261165e9fae8fa4ee5b657d95946a5bbc52`.
  Raw gate logs remain disposable under `/tmp/afero-phase-a.ukbllQ`; the
  checkout was clean after both runs.
- Phase A therefore passes for the proposed root-module evaluator. No
  prototype, mutation, gap, fairness, false-positive, solver, or calibration
  result is claimed yet.

This preliminary record does not replace exact evaluator Phase B if submission
artifacts are later authored.

## Preliminary applicability and design verdict

| Dimension | Score | Reason |
|---|---:|---|
| Eligibility and health | 9 | Public active Apache-2.0 Go library, 6,687 stars, current default-branch work, small root dependency graph, and a real native suite. |
| Rarity | 7 | Whiteouts are a known filesystem concept, but behavioral overlay mutation across Afero's generic backends is less benchmark-like than parsers, caches, or ordinary copying. |
| Task applicability | 8 | The existing public composition type and sandbox story expose a concrete gap with direct black-box oracles; no upstream owner was found. |
| Behavioral depth | 8 | Exact hiding, subtree opacity, merged relocation, replacement, failure staging, and optional object identity cross independently implemented boundaries. Prototype convergence remains the key risk. |
| Harness feasibility | 10 | Core scenarios use MemMapFs, BasePathFs/OsFs, and deterministic fault wrappers without services or network. |
| Prior-art and similarity safety | 6 | Exact Afero prior art is clean, but generic overlayfs whiteouts and local atomic-copy/OCI-layer history require disciplined behavioral scope. |

Weighted preliminary rating: **8/10**.

The trajectory-informed startup gate, ownership audit, pristine Phase A, and
independent scope gate pass. Two complete implementations satisfy the same
memory- and OS-backed probe and complete offline suite. Eager logical-tree
materialization changes two production files at 433 strict effective
additions; lazy base-path redirection changes two at 503. They do not converge
on one whiteout-map seam.

Cross-layer symlink relocation is intentionally excluded. A prototype showed
that Afero's optional link interfaces do not provide a backend-independent
target representation across separate `BasePathFs` roots. The selected problem
covers regular files and directories without prescribing wrapper internals.

The candidate was promoted and its exact local gates passed. The user later
reported that someone else had already implemented the task. That external
disposition supersedes the local novelty conclusion: calibration is closed at
0/10, and the exact task must not be resubmitted or cosmetically rescoped.
