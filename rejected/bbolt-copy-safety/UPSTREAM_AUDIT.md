# Upstream audit - bbolt snapshot-copy safety

Audit date: 2026-08-15.

Repository: `https://github.com/etcd-io/bbolt`.

Pin: `0464afc4b2120d472bae971ac2934f947145418e` (`main`, committed
2026-08-14).

Status: `no exact upstream owner found; later rejected for fairness and
convergence scope`.

## Eligibility and provenance

GitHub's repository API reported 9,683 stars, 745 forks, Go as the primary
language, MIT licensing, an unarchived public repository, and `main` as the
default branch. A fresh fetch confirmed that the pinned commit remained the
default-branch head. The most recent 100 commits contain no direct Claude,
ChatGPT, Codex, OpenAI, Cursor, Copilot, or Gemini authorship marker.

No external issue, pull request, or discussion was created during this audit.

## Search surfaces and exact results

The source, tests, README, fetched default-branch history, and remote branch
names were searched for `CopyFile`, `WriteTo`, backup, alias, same-file,
short-write, truncation, and compaction terms. The earlier all-state scan of the
newest 1,000 GitHub issues and pull requests was refreshed with repository-wide
GitHub searches for `CopyFile`, `WriteTo`, `short write`, and `same file`; those
returned 7, 13, 2, and 19 results respectively. The enabled GitHub Discussions
surface was searched for the same concepts.

No issue, pull request, discussion, branch, or commit owns `Tx.CopyFile`
source/destination aliases or metadata-page short-write checking.

## Neighboring upstream work

| Item | State and relevance | Boundary for this task |
|---|---|---|
| [PR #1057](https://github.com/etcd-io/bbolt/pull/1057) | Merged; makes `Tx.WriteTo` reuse or verify the already-open database after pathname replacement. | Owns source replacement between transaction creation and backup, not destination aliasing or writer return counts. |
| [issue #850](https://github.com/etcd-io/bbolt/issues/850) | Closed discussion of keeping a transaction open through a long `WriteTo`. | Requests a different backup lifecycle/architecture. |
| [PR #1239](https://github.com/etcd-io/bbolt/pull/1239) | Merged; preserves pending same-transaction changes in `MoveBucket`. | Bucket movement is separate from file backup. |
| [issue #151](https://github.com/etcd-io/bbolt/issues/151) | Closed; records a same-database, two-transaction bucket-copy deadlock. | Reinforces the documented nested-transaction limitation; it does not establish same-handle `Compact` as a supported operation. |
| [issue #184](https://github.com/etcd-io/bbolt/issues/184) | Closed support question about an apparently empty `CopyFile` result. | Does not report source aliasing or pre-truncation validation. |

## Ownership verdict

The exact alias defect appears unowned at the immutable pin. Ownership is not
the terminal problem gate, however: an ordinary-filesystem repair and the
repository-compatible handle-based repair converge on 13 and 15 additions in
one existing function, and the attempted adjacent requirements are either not
fair under Go's public interface contract or do not add an independent
supported production boundary. The problem is therefore closed for scope
rather than promoted.
