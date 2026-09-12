# Upstream audit - Afero copy-on-write namespace mutations

Audit date: 2026-08-15.

Repository: <https://github.com/spf13/afero>.

Pin: `768f1fb0e5535b77d90e44c531aacd652aabd96a` on `master`.

Status: `local audit superseded by user-reported prior implementation; archived`.

## Current eligibility facts

GitHub's repository API reported 6,687 stars, 569 forks, 128 open issues and
pull requests, Go as the primary language, Apache-2.0 licensing, and a public,
unarchived, enabled repository. The default branch is `master`; its frozen head
is a 2026-06-09 merge by Steve Francia, within the required twelve-month
window. GitHub recorded repository activity through 2026-08-15 and a branch
push on 2026-08-14. Discussions are disabled.

The latest published release is
[`v1.15.0`](https://github.com/spf13/afero/releases/tag/v1.15.0), dated
2025-09-08. The frozen root module declares Go 1.25 and one direct dependency,
`golang.org/x/text`. It contains 19 root test files and 125 test/example/
benchmark declarations. The separate `gcsfs` and `sftpfs` modules are outside
the proposed core task path.

## Exact source, branch, and history identity checks

The complete frozen checkout, its fetched remote branches, and Git history
were searched for `CopyOnWriteFs`, `CopyOnWriteUnionFs`, `union fs`, overlay,
whiteout, tombstone, deletion, removal, rename, copy-up, opaque directory, and
sandbox mutations.

The current source establishes the gap directly:

- `CopyOnWriteFs.Remove` and `RemoveAll` call only the layer and return `EPERM`
  when a base-only entry remains;
- removing an upper entry that shadows the base permits the base name to become
  visible again;
- `CopyOnWriteFs.Rename` returns `EPERM` for a base-only source and otherwise
  delegates only to `layer.Rename`;
- `Open` and `UnionFile.Readdir` already merge directories and prefer upper
  names; and
- the README advertises the composition as a writable sandbox whose changes
  are isolated from the base.

No branch contains a whiteout or full logical mutation implementation. Relevant
history includes the 2016 union-fs introduction and the subsequent removal of
the MemMap-only overlay restriction, directory merging, lstat/symlink support,
and generic parent-path fixes. None implements deletion hiding, opaque
directories, or base-backed rename.

## All-state GitHub audit

GitHub issue/PR search was run across all states with the exact type name and
broader terms:

- `repo:spf13/afero CopyOnWriteFs` returned 20 items;
- `repo:spf13/afero whiteout` returned 0;
- `repo:spf13/afero tombstone` returned 0;
- `repo:spf13/afero unionfs delete` returned 0; and
- `repo:spf13/afero copy-on-write remove` returned 0.

The 20 exact-type results were individually triaged. They cover constructor
return types, alternate overlay backends, parent creation, stat/not-exist
handling, mkdir behavior, optional lstat/symlink support, a mountable
filesystem, test frameworks, and unrelated CacheOnRead/Regexp/BasePath work.
None requests or implements logical delete/rename, whiteouts, opaque recreated
directories, or merged-tree relocation.

The most relevant historical items are:

- [issue #60](https://github.com/spf13/afero/issues/60), closed after allowing
  non-MemMap upper backends; it reinforces backend-generic composition but does
  not discuss deletion state;
- [issue #78](https://github.com/spf13/afero/issues/78) and
  [issue #86](https://github.com/spf13/afero/issues/86), closed parent-path and
  not-exist fixes for creation;
- [PR #248](https://github.com/spf13/afero/pull/248), a closed consistency
  change requiring parents on create;
- [PR #145](https://github.com/spf13/afero/pull/145), a closed mountable
  filesystem unrelated to union deletion; and
- [PR #181](https://github.com/spf13/afero/pull/181), a closed constructor
  return-type proposal.

Recent open work is concentrated elsewhere: CacheOnRead error handling,
`syscall.Conn` forwarding, MemMap parity fixes, GCS/SFTP behavior, and a new
`io/fs` bridge. None owns this seed. Release notes and the current README contain
no whiteout or full namespace-mutation implementation. Because repository
Discussions are disabled, there is no separate Discussion ownership surface.

No suspicious abandoned implementation or linked fork was found in any issue
or PR, so there is no evidence-based fork target to copy or audit further. No
external issue, PR, comment, or maintainer contact was created.

## AI-provenance and maintenance note

The frozen default-branch history was inspected around the target files and
recent semantic work. The copy-on-write files are mature repository code with
human-authored history dating to 2016 and a 2026 human fix in adjacent
`UnionFile` behavior. No public agent-authored branch or exact generated
implementation was identified for the proposed feature. The project is active,
but its current issue/PR queue raises ordinary review-latency risk rather than
task ownership.

## Ownership verdict

The exact task is unowned as of the audit date. The subsequent untouched
offline environment, independent scope, and exact submission gates pass in the
candidate and promoted problem records. Any new upstream item or frozen-pin
change invalidates this audit and requires a fresh all-state search.

The user later reported that someone else had already implemented the task.
No implementation identifier was supplied in the workspace. The external
rejection therefore supersedes this local search result without erasing it or
inventing missing provenance.
