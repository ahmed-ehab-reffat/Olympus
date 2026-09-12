# DESIGN - Afero copy-on-write namespace mutations

Status: `rejected as previously implemented; archived 2026-08-15; calibration closed at 0/10`.

Repository: `spf13/afero` at
`768f1fb0e5535b77d90e44c531aacd652aabd96a`.

Primary and proposed production language: Go.

Task type: enhancement.

## Public contract and repository evidence

`CopyOnWriteFs` already presents a merged directory view and copies base files
up for content/metadata mutations. The README calls it a sandbox whose writes
leave the base untouched. The `Fs` interface and generic repository tests
define ordinary remove, recursive remove, file replacement, and directory
rename observations. Yet the current implementation returns `EPERM` for
base-only remove/rename and exposes a lower name again after its upper shadow is
removed.

The selected contract extends the merged view to regular-file and directory
namespace changes. Successful removal hides the lower name; recursive removal
creates an opaque subtree boundary that survives directory recreation; rename
moves the complete logical tree and its deletion state; destination replacement
does not reveal old lower children; equivalent cleaned paths share state; and a
reported pre-commit layer failure preserves public source/destination views.
State lifetime is one wrapper instance. Durable marker recovery, concurrency,
and new cross-layer symlink behavior are excluded.

## Trajectory-informed design gate

Before prototype or hidden-test work, searches covered `problems/README.md`,
both candidate registries, accepted/rejected compact records, and all problem
or archive records for Afero, filesystem abstractions, overlays, whiteouts,
tombstones, namespace isolation, copy-up, rename, deletion, and atomic copying.
No Afero problem or solver run exists.

The rejected wazero namespace record warned against inventing clone semantics
that host-resource interfaces cannot express. The rejected umoci record warned
that many whiteout fixtures around one pending-entry loop are one discriminator.
Those lessons removed cross-root symlink relocation and separated exact hiding,
subtree opacity, logical relocation, replacement, path identity, and commit
timing.

The PcapPlusPlus filtered-copy archive manifest was read, then raw evaluator
results, patches, workspace diffs, run records, and agent trajectories were
inspected directly from
`archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz`.

| Evidence role | Raw run | Outcome | Architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | `agent-runs4/Nova_Nova_6` | 69/69 baseline and 16/16 L6 replay | Existing-source streaming scanner, section-local state, deferred discarded-packet validation, staged publication; about 406 production additions plus declaration. |
| Near-pass | `agent-runs4/Nova_Nova_1` | 69/69 baseline and 15/16 L6 replay | Separate roughly 532-line streaming source validated discarded packet state too eagerly despite otherwise complete staged output. |
| Broad failure | `agent-runs4/Nova_Nova_3` | 69/69 baseline and 11/16 L6 replay | Roughly 448-line parser collapsed payload and trailing-option boundaries and missed later validation timing. |
| Afero-specific evidence | unavailable | no run exists | Frozen repository behavior plus independent complete prototypes govern initial scope. |

No raw hidden name, fixture, byte sequence, or private call order is reused.

## Trajectory-informed discriminator ledger

| Evidence signal | Generalized shortcut | Fair public invariant | Black-box oracle | Failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| Current removal deletes only the upper name or rejects a base-only name. | Treat removal as an upper-backend call. | Successful removal hides the logical name and leaves the base unchanged. | Compare stat/open/parent listing through the wrapper and direct base reads. | Exact overlay precedence. | Any journal, marker, or virtual lookup can pass. |
| A flat tombstone cannot distinguish deleted from recreated directory state. | Clear one marker on `Mkdir` and reveal all lower children. | Recreated recursively removed directories start empty while accepting new upper children. | RemoveAll, recreate, write one child, enumerate. | Opaque subtree lifecycle. | No marker encoding is inspected. |
| Calling only `layer.Rename` loses base-only members. | Move only materialized upper entries. | A destination contains the complete pre-rename logical source. | Recursively compare base-only, upper-only, and mixed trees. | Cross-layer relocation. | Eager and redirect implementations both pass. |
| A source whiteout alone leaves stale lower destination children. | Move source without replacing the logical destination. | Same-kind replacement exposes exactly the moved source view. | Use distinct lower/upper children at source and destination. | Destination replacement. | Tests result, not staging mechanics. |
| Pcap near-pass committed validation to discarded state too early. | Mutate bookkeeping or upper entries before validation/work succeeds. | A reported pre-commit layer error leaves source/destination views unchanged. | Fail the first and second required backend rename and compare snapshots. | Validation and commit timing. | Faulting wrappers are valid public `Fs` implementations; no call count is required by the prompt. |
| String-keyed state can disagree on equivalent spellings. | Use raw caller strings and exact-key lookup only. | Cleaned aliases address one logical name, including under hidden ancestors. | Mutate through one spelling and access through another. | Path identity. | Uses Go/Afero path behavior, not a key layout. |
| Deletion state can remain under an old prefix after rename. | Move visible data but not namespace history. | Hidden children and opaque recreated subtrees move with their directory. | Delete/recreate children, rename parent, inspect both prefixes. | State relocation. | Both materialized and redirect architectures can pass. |
| One redirect may work but chains can resolve to stale paths. | Implement only one base-backed rename. | Repeated renames retain content, modes, and source absence. | Rename a base directory twice and inspect every public path. | Lifecycle composition. | Does not restrict whether bytes move. |

## Scope prototypes

The common probe covers memory and independent OS-backed layers, exact and
recursive removal, recreation, merged replacement, first/second backend-failure
rollback, path aliases, moved deletion state, repeated rename, modes, and upper
shadows. Both implementations pass `go build ./...` and the complete 187-case
offline JUnit lane with one skip.

- Eager staging/materialization: two production files, 456 raw additions and
  43 deletions, 433 strict effective additions.
- Lazy base-path redirect journal: two production files, 527 raw additions and
  111 deletions, 503 strict effective additions.

They do not converge on one state seam. Exact patches and hashes are preserved
in the candidate record.

## Environment preflight

The approved general Olympus base resolved to
`sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`.
The untouched image ID was
`sha256:002b074c6f96b7533b53931514b10e6cbc3c9e118cdcd963cdd7f9921d730d07`.
Offline as UID/GID 20002, both image-copy and read-only exact-checkout layouts
passed `go build ./...`, compile-only discovery, and all 176 pristine JUnit
cases with one skip.

After every verifier revision, the exact gate restarted from the untouched
pin. Final version 3 rebuilt without cache, ran offline as UID/GID 10001, and
passed evaluator composition for pristine, eager reference, and the mandatory
lazy-redirect replay. Pristine fails all 7 focused tests behaviorally;
reference and redirect each pass 176/176 base cases with one skip and 7/7
focused cases.

## Exact-version discriminator audit

The final verifier directly covers layer-only, base-only, overlapping, and
merged producer modes; regular files and directories; exact and recursive
removal; both recreation APIs; replacement; repeated state relocation; memory
and OS backends; and early/later failure points. Ten isolated plausible mutants
are killed. Two full-suite survivors were rejected as observationally
equivalent because they differ only in private tombstone timing/retention while
producing the required public view.

The exact requirement matrix and weak-cell decisions are in `GAP_ANALYSIS.md`.
Every rejection predicate and both legitimate architecture replays are audited
in `FAIRNESS_ANALYSIS.md`. `FALSE_POSITIVE_AUDIT.md` records mutation isolation,
focused results, full-suite survivor results, rejected artificial probes, and
the immutable identifiers.

Final artifact hashes are prompt
`7c54baa9a4250d090542bc73a866b8c9f87dd869a13b8791768a5a260ff4af8a`,
test patch
`0d882efc4555640ebeba57de65c64de300690ba5c1b1047ffeaeb4a1201b4cd1`,
reference
`65939f4dc645bb3407d00b8a644e521b3a38e0b42ebbc97074fbb31debbf90a1`,
and Dockerfile
`33c69a5c4ac80b747abb40dcd63c8fbbb29f96476ea1b8189fc14af7d66fc72f`.

## Design verdict

The task is repository-native, behaviorally fair for regular files/directories,
unowned upstream, offline-testable, and substantial across independent
architectures. Exact environment, gap, fairness, and false-positive gates pass.
The immutable version is ready for the calibration protocol; calibration is
0/10 and no solver outcome is inferred from author-built prototypes.

This local design verdict is retained as historical evidence. The user later
reported that someone else had already implemented the task, which supersedes
the local novelty conclusion and closes the exact proposal. It must not be
calibrated, resubmitted, or cosmetically rescoped.
