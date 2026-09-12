# Design - bbolt snapshot-copy safety

Status: `rejected after the pre-authoring fairness/convergence probe; Phase A
passed; calibration 0/10`.

Repository: `etcd-io/bbolt` at
`0464afc4b2120d472bae971ac2934f947145418e`.

Primary language and license: Go / MIT.

Task type under evaluation: bug fix.

## Candidate public contract

The audit began with the safety of bbolt's public database-copy surface.
`Tx.WriteTo` explicitly promises that a nil error means exactly `tx.Size()`
bytes were written, and the README presents `Tx.WriteTo` and `Tx.CopyFile` as
consistent hot-backup APIs. Two suspected boundaries were investigated:

- its two generated metadata pages use one `io.Writer.Write` call each and
  accept a short write with a nil error; and
- `Tx.CopyFile` opens its destination with `O_TRUNC` before determining whether
  that pathname, symlink, or hard link names the live source database.

The alias defect is a fair public safety obligation. The metadata case is an
observable `WriteTo` postcondition violation only when the supplied writer
itself violates Go's `io.Writer` contract by returning `n < len(p)` and a nil
error; it therefore cannot be an approved hidden-test discriminator. The
adjacent exported `Compact(dst, src, txMaxSize)` operation was audited but did
not supply an independent supported boundary. No task may add a particular
temporary-file scheme, error string, write batching policy, pathname
canonicalization strategy, or private helper merely to increase scope.

## Trajectory-informed design gate

The local-history search covered `problems/README.md`, candidate success and
index records, and compact records under `problems/`, `candidates/`, `archive/`,
and `Work/` for `bbolt`, `etcd-io`, Bolt database, backup, copy, compaction,
alias, short-write, snapshot, and atomic-publication terms. There is no prior
bbolt candidate, problem, checkout, solver run, or compact record in the
workspace.

The closest repository-level compact records read were:

- `frostdb-atomic-snapshot-load/DESIGN.md` and `SUMMARY.md`, where a real
  snapshot rollback defect was rejected after the complete repair converged to
  25 strict additions in one file; and
- `h5py-vds-copy-relocation/DESIGN.md`, `SUMMARY.md`, and `RUNS.md`, whose
  original direct-copy version calibrated at 2/10 but had successful one-file
  solutions and was only accepted after redesign added an independently useful
  reconstructable/relocatable layout abstraction.

Representative raw h5py copy trajectories, evaluator results, run metadata,
and production patches were inspected directly:

| Evidence role | Raw run | Outcome | Architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | `agent-runs3/Nova_Nova_8` | focused pass | Implemented direct VDS relocation in one production file, including per-mapping path resolution, readable whole-source dataspace lookup, validation, attribute copying, and anonymous creation before publication. |
| Near-pass | `agent-runs3/Nova_Nova_6` | 22/24 in the historical record | Split the same behavior across group and VDS modules but missed two independently implemented boundary cells; this became the broadest near-pass used in redesign replay. |
| Broad failure | `agent-runs3/Nova_Nova_1` | focused failure | Implemented the central one-file copy path and atomic link publication but did not cover the full mapping/property surface. |

Those trajectories establish a design discriminator, not bbolt hidden-test
details: a viable copy problem needs multiple repository-supported production
boundaries with plausible independent mistakes. More fixtures around one alias
comparison or one `io.Writer` loop do not create long-horizon scope. The
FrostDB record independently warns against converting lifecycle fixtures around
one adjacent cleanup seam into artificial implementation breadth.

No bbolt trajectory exists to copy or privilege. Every requirement considered
during the audit was therefore derived from exported behavior and repository
evidence at the immutable pin.

## Initial discriminator ledger

| Repository or trajectory evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Current status |
|---|---|---|---|---|---|
| `Tx.WriteTo` promises exact size on nil error but directly calls `Write` for each metadata page. | Treat a nil writer error as a complete write. | A nil return means exactly `tx.Size()` bytes reached the writer. | A positive short count with nil reproduces the mismatch, but that writer violates the language interface contract. | Writer protocol / success accounting | **Rejected as a hidden discriminator.** Go requires `io.Writer` to return a non-nil error whenever `n < len(p)`. |
| `Tx.CopyFile` opens with `O_TRUNC` before any identity check. | Compare path strings, or validate after destructive open. | A copy destination that aliases the open source must fail without changing the source. | Try the direct path and supported filesystem aliases, then read through the live handle and reopen the database. | Resource identity / pre-destructive validation | **Confirmed and unowned**, but two independently structured probe repairs converge on 13–15 additions in `tx.go`; the handle-based version preserves `Options.OpenFile`. |
| `Compact` accepts two open database handles and commits intermittently. | Guard only pointer equality or assume the destination is always unrelated and empty. | Any alias behavior must be explicitly supported by repository semantics and must not damage the source. | Exercise same underlying file through distinct handles only if bbolt can legitimately open them and the public API supplies a stable expected outcome. | Resource identity / compaction lifecycle | **Excluded.** One handle in both roles is the documented nested-transaction deadlock shape; distinct aliases cannot be opened through the normal locking contract. CLI alias preflight repeats the same identity decision. |
| H5py pass delayed linking until copy and metadata work succeeded. | Add destination failure atomicity without repository evidence because it increases breadth. | Hidden checks may require only failure behavior grounded in bbolt's public contract or existing lifecycle. | Observe documented API results and persistent files, never a prescribed temp-file design. | Publication / failure lifecycle | Excluded unless independent bbolt evidence is found. |
| FrostDB's many failure fixtures still converged to one 25-line cleanup seam. | Count aliases, error offsets, or reopen variants as separate implementation boundaries. | The task must retain at least two honest production decisions after convergence probing. | Measure the cheapest complete reference before authoring hidden tests. | Scope / convergence | Mandatory promotion criterion. |

## Upstream ownership audit

The exact default branch, fetched Git history, the newest 1,000 GitHub issues
and pull requests, targeted all-state searches, and the enabled Discussions
surface were searched. A fresh fetch confirmed that the immutable pin is still
the default-branch head. No result owns short-nil metadata writes or `CopyFile`
source aliases. Nearby work is excluded:

- PR #1057 and its backports fix `WriteTo` reading a replaced underlying file;
- issue #850 discusses a different transaction/backup lifecycle;
- PR #1239 owns loss of pending same-transaction changes in `MoveBucket`; and
- issue #151 records the nested-transaction deadlock shape rather than making
  same-handle compaction a supported operation.

Exact links and repository metadata are recorded in `UPSTREAM_AUDIT.md`.

## Disposable behavioral and convergence probe

The probes ran in disposable exact-pin checkouts with image
`sha256:f2b65569deffe420022d05a370a751e44c2aee7db758eb546e47cf08903a2ea5`,
offline as UID/GID 10001. They were never made submission artifacts or hidden
tests. One initial batch had malformed disposable patch headers and never
reached Go test execution; it was discarded and every case was restarted from
fresh checkouts.

For each alias case, the probe created a 131,072-byte database containing a
64-KiB value, ran `Tx.CopyFile` in a subprocess, compared the source bytes, and
reopened the source read-only. On the pristine pin, direct path, hard link, and
symbolic link all returned an error only after reducing the source to 8,192
bytes.

Two independently structured repairs passed all three cases:

| Architecture | Production diff | Decision timing |
|---|---:|---|
| Pre-open `os.Stat` / `os.SameFile` | `tx.go`, 13 additions | Rejects an existing ordinary-filesystem alias before the destructive open, but bypasses the `Options.OpenFile` abstraction. |
| Open without truncation, reuse `sameFile`, then `Truncate` | `tx.go`, 15 additions / 1 deletion | Compares the actual opened handles and truncates only after they differ. |

The second, repository-compatible implementation is preserved as
`prototype.patch`, SHA-256
`c08615dddf3c28e479d752ec8c92823e7ac8380dfe67d5f21e841f519642ee13`.
It also passed the focused `Tx.CopyFile`, metadata-error, data-error,
concurrent-copy, and overwritten-path tests with `BBOLT_VERIFY=all` under both
`hashmap` and `array` freelist modes. A final fresh-checkout replay using only
the preserved production patch and alias probe reported
`ok go.etcd.io/bbolt 1.139s` for `hashmap` and
`ok go.etcd.io/bbolt 0.873s` for `array`.

The short-write probe made only its first metadata write return one byte short
with nil error. Pristine returned nil after 24,575 of 24,576 bytes; an eight-line
helper corrected it. The same image's `go doc io.Writer` states that a writer
**must** return a non-nil error when `n < len(p)`, so this is robustness against
an invalid collaborator rather than a fair participant-facing requirement.
Even retaining it produces a combined one-file diff of only 25 additions and 3
deletions.

## Design verdict

Reject the task for fairness and convergence scope at **3/10 current; 6/10
initial**. The source-alias bug is real, severe, repository-native, and unowned,
but the complete fair repair is one 15-addition decision in one existing
function; the simpler ordinary-filesystem variant converges at 13 additions.
Direct, hard-link, symbolic-link, live-handle, and reopen cases are
fixtures around that one file-identity boundary. The proposed writer behavior
cannot pass the fairness gate, and compaction does not introduce a distinct
supported implementation boundary.

Adding destination failure atomicity, concurrent pathname replacement,
same-handle compaction, or more malformed writers would invent guarantees or
repeat the same discriminator. No `meta.md`, `test.patch`, `solution.patch`,
`solution_approach.md`, Phase B, gap analysis, fairness analysis,
false-positive audit, solver run, or calibration batch was created. Reconsider
bbolt only through a materially different subsystem and behavior after fresh
design and environment gates.
