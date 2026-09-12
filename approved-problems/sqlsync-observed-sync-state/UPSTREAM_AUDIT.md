# SQLSync observed mutation progress - upstream audit

Initial audit date: 2026-08-01

Latest freeze check: 2026-08-02

Repository: <https://github.com/orbitinghail/sqlsync>

Pinned commit: `7dc1af6b082023982fd2697f913f5b27453747f1`

## Eligibility facts

| Fact | Result |
|---|---|
| Public repository | Yes |
| Primary production language | Rust |
| Proposed production language | Rust, with Rust/Wasm and TypeScript bridge changes |
| Task type | Feature request |
| Stars / forks at audit | 2,910 / 41 |
| License | Apache-2.0 |
| Default-branch pin date | 2025-11-19 |
| Activity gate on 2026-08-01 | Pass: within 12 months |
| Archived | No |
| Dependency locks | `Cargo.lock` and `pnpm-lock.yaml` committed |
| Offline intended lane | Pass on official-base x86_64 after dependency warming |

The repository has 207 commits at the pin. Search over commit messages and
authorship found no direct AI/agent attribution at the audit date.

## Public ownership signal

[Issue #31, "Add sync state API"](https://github.com/orbitinghail/sqlsync/issues/31)
is open and asks for visibility into subscribed database synchronization,
timeline upload, coordinator application, and ideally a way to await a
mutation. A maintainer-related comment also notes that a demo should expose
state. This is positive demand, but the issue does not specify receipt identity,
the precise received/applied observation boundaries, reconnect semantics, or a
public representation.

The redesign uses that demand but does not claim to implement the entire issue.
It narrows to a per-document observed snapshot and stable mutation receipt.

## Exact and broad searches

Searches were run across open/closed/merged pull requests, open/closed issues,
Discussions, all branches, releases, source/tests/docs, and Git history for:

- `MutationReceipt`, mutation receipt, mutation status, mutation progress;
- sync state, synchronization state, observed state, received, applied;
- timeline acknowledgement, range acknowledgement, applied LSN;
- await mutation, wait mutation, subscription state, database state; and
- the proposed receipt/snapshot field combinations and likely helper names.

Results:

- No pull request in any state implements the receipt/snapshot contract.
- Exact repository searches for `MutationReceipt` and the proposed API shape
  returned no source or history match.
- The current branches are `main`, `renovate/configure`, and `updates`. The two
  non-main branches contain only Renovate configuration and an old dependency/
  lint update; neither contains the design.
- Git history contains earlier work around `applied_lsn`, but it is the existing
  coordinator application table used by the redesign, not a public state API.
- No release or changelog entry supplies the feature. The repository has no
  GitHub Releases at the pin.
- [Discussion #53](https://github.com/orbitinghail/sqlsync/discussions/53)
  describes a future content-addressed roadmap architecture but does not add,
  decline, or prescribe mutation receipts or this observed snapshot.
- Other reviewed Discussions, including server-side mutations and encryption,
  do not occupy this contract.

Useful audit surfaces:

- [Pull-request search](https://github.com/orbitinghail/sqlsync/pulls?q=is%3Apr+%22sync+state%22)
- [Issue search](https://github.com/orbitinghail/sqlsync/issues?q=%22sync+state%22)
- [Discussions](https://github.com/orbitinghail/sqlsync/discussions)
- [Branches](https://github.com/orbitinghail/sqlsync/branches/all)
- [Releases](https://github.com/orbitinghail/sqlsync/releases)

## Local similarity audit

Local history searches found no prior SQLSync problem or solver run. The nearest
records were:

- RustPBX reconnect/idempotency, where the desired task collapsed to an
  existing-identity cache;
- Calyx checkpoint reconstruction, which established that replay and
  reconstruction are legitimate when black-box equivalent;
- Statig cross-path provenance, whose passes/failures motivate identity and
  public-compatibility discriminators; and
- str0m validation-before-commit, whose solver convergence warns against
  counting many fixtures as independent depth.

The task remains somewhat adjacent to local persistence/progress themes, so
prior-art safety is scored 5/10 rather than treated as pristine. Its particular
SQLite timeline/Wasm boundary and three repository-native observation stages
are distinct.

## Audit conclusion

**Clear for selection at this pin.** The broad request is public, but no public
implementation or prescribed exact solution was found. The redesign derives
its precise contract from existing source semantics and was independently
implemented in a disposable trial.

Repeat this audit before freezing participant artifacts. Stop if a new issue,
PR, branch, release, or roadmap decision implements or declines the same
receipt/snapshot behavior.

## 2026-08-02 freeze check

GitHub's repository API and a fresh full clone agree that `main` remains
`7dc1af6b082023982fd2697f913f5b27453747f1`; the repository has not been pushed
since 2025-11-19. Issue #31 remains open and reports no linked branch or pull
request. There are no open pull requests or releases. All ten historical pull
requests, every open and closed issue returned by the API, all three branches,
the roadmap Discussion #53, the Discussions index, and all 210 reachable
commits were checked again.

Exact and synonym searches for receipts, sync state, mutation progress,
applied LSNs, and acknowledgements returned no pull request and only issue #31.
Source/history searches over all refs again found no `MutationReceipt`, browser
`syncState`, or equivalent receipt/snapshot contract. The two non-main branch
diffs were inspected: `renovate/configure` adds only `renovate.json`, while
`updates` changes dependencies and lints. The audit therefore remains clear at
the recorded pin.

## 2026-08-07 acceptance-time follow-on screen

The repository API, open issue set, local candidate registry, and frozen source
were screened for a materially distinct second Olympus problem before
archiving. The repository still reports its latest push at 2025-11-19 and no
new implementation of the accepted observed-sync-state feature.

No second candidate clears the bounded, missing, independently testable task
gate:

- issue #17's table-level query invalidation is already implemented at the pin
  through SQLite root-page dependency collection and intersection with storage
  changes;
- issues #1, #21, and #22 leave schema migration, durability, and reducer-
  upgrade policy unresolved rather than defining a stable behavioral contract;
- issue #15 is an empty OPFS-journal request with a browser-persistence harness
  burden, while issue #18 is a performance heuristic rather than a stable
  functional oracle; and
- issues #8, #45, and #49 are successive repository-scale replication/snapshot
  redesigns, not bounded additions adjacent to the accepted task.

The local `candidates/sqlsync-observed-sync-state/` directory was empty, and no
other SQLSync checkout, worktree, problem, or raw candidate prototype existed.
Accordingly the accepted problem follows normal closure: keep the compact
prototype, design, run, and upstream records; archive raw solver evidence; and
do not seed another SQLSync task from an occupied or under-specified issue.
