# UPSTREAM AUDIT - Afero copy-on-write namespace mutations

Audit date: 2026-08-15.

Pin: `768f1fb0e5535b77d90e44c531aacd652aabd96a`.

GitHub reports a public, active, unarchived Apache-2.0 Go repository with 6,687
stars. The default-branch head is dated 2026-06-09; the latest release is
v1.15.0 from 2025-09-08.

All fetched source, branches, tags, and history were searched for
`CopyOnWriteFs`, its former union name, overlay, whiteout, tombstone, delete,
remove, rename, copy-up, opaque directory, and sandbox mutation. GitHub
all-state searches returned 20 exact-type items and zero results for whiteout,
tombstone, unionfs delete, or copy-on-write remove. The exact-type items cover
alternate overlay backends, constructor types, parent creation, stat errors,
mkdir behavior, optional link interfaces, mountable filesystems, and unrelated
cache work. None owns logical removal, opacity, or base-backed rename.

Relevant closed items are issue #60 (generic upper backends), issues #78/#86
(creation path errors), PR #248 (parent requirements), PR #145 (mountable FS),
and PR #181 (constructor return types). No linked fork or abandoned
implementation was identified. Discussions are disabled. Releases contain no
equivalent behavior. No external issue, PR, comment, or maintainer contact was
created.

Verdict: exact task ownership is clean for the frozen pin. Any upstream or pin
change requires a fresh audit.

## External disposition

The user later reported that someone else had already implemented the task.
No implementation identifier was supplied in the workspace. That external
outcome supersedes the local ownership verdict for submission purposes while
this file remains preserved as the exact search record that existed at the
time.
