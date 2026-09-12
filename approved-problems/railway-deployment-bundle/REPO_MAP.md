# Railway deployment repository map

Revision:
`4d49d9845a27a0947ab903b01789eb9f854414d8` (`railwayapp` 5.28.1).

## End-to-end data flow

| Stage | Pinned seam | Input / owner | Output / owner | Ordering and read timing | Repeated selection |
|---|---|---|---|---|---|
| CLI dispatch | `src/main.rs`, generated `commands!` enum; `src/commands/up.rs::Args` | Process arguments | Private `up::Args` | Clap preserves argument values; no filesystem read | no |
| Linked-root discovery | `src/config.rs::get_closest_linked_project_directory`, `get_linked_project` | Current directory, global Railway config, token/env overrides | `LinkedProject.project_path` | Lexical ancestor walk over configured absolute strings; token/env paths use current directory | no |
| Deploy path resolution | `src/commands/up.rs::get_deploy_paths` | Optional positional path, linked project path, `--path-as-root` | `DeployPaths { project_path, archive_prefix_path }` | No canonicalization; relative paths remain relative | no |
| Target resolution | `up::command` | Project/environment/service identifiers | Remote project/environment/service IDs | Network/API work occurs before packaging in ordinary `up` | unrelated to file selection |
| Walk and ignore | `src/controllers/upload.rs::create_deploy_tarball` | Project path, archive prefix, `no_gitignore` | `Vec<Result<DirEntry>>` | `ignore::WalkBuilder` order is not explicitly sorted; all entries are collected before tar writes | once |
| Component filter/name | same helper | Each walked path | Archive name `PathBuf::from(".").join(path.strip_prefix(prefix))` | Lexical `strip_prefix`; components named `.git` or `node_modules` are skipped after walking | no |
| Archive/compression | same helper | Live source paths and archive names | Complete in-memory `Vec<u8>` gzip/tar | `tar::Builder::append_path_with_name` reads metadata/content sequentially after the walk; `gzp` compresses with CPU-count threads | no |
| Progress/size | closure in `up::command` | Raw walked count and compression progress; final body | TTY progress or verbose byte count | Raw total includes entries later skipped by the manual component filter | no |
| Upload | `src/controllers/upload.rs::upload_deploy_tarball` | Complete `Vec<u8>` plus remote IDs/message | HTTP response / deployment IDs | No filesystem access; request body is exactly the supplied bytes | no |
| Other callers | `deploy_new_project`, `commands/mcp/handler.rs` | Current directory or MCP path | Same tar `Vec<u8>` | Same helper, root/prefix equal in these calls | no |

The uploader does not stream a tree and does not ask the server to rescan it.
One in-memory archive is the immutable upload input. A public plan can therefore
describe the exact archive entries without changing the HTTP boundary, but
creating such a plan is only a refactor/projection of this helper.

## Roots, workspace, and configuration

For an ordinary linked invocation, `get_closest_linked_project_directory`
walks from the process directory toward the filesystem root until it finds a
path key in the global Railway configuration. That configured ancestor is the
archive prefix.

`get_deploy_paths` then applies:

- `--path-as-root PATH`: both walked project path and archive prefix are
  `PATH`; the flag refuses an omitted positional path;
- positional `PATH` without `--path-as-root`: walk `PATH`, but name entries
  relative to the linked-project ancestor (or current directory when no linked
  path is supplied);
- no positional path: walk and prefix the linked-project ancestor/current
  directory.

This is service-root behavior only in the sense that the user supplies a path.
The selected Railway service does not supply another filesystem root.
Workspace selection is used for remote project creation and does not alter the
archive walk. `deploy_new_project` always packages the current directory after
creating/linking the project.

Neither root is canonicalized in this path. `strip_prefix` is lexical and
errors if a walked path cannot be expressed under the chosen archive prefix.

## Ignore and filesystem semantics

`WalkBuilder::new(project_path)` enables normal Git ignore processing.
`add_custom_ignore_filename(".railwayignore")` layers Railway ignore files
using the same walker. `--no-gitignore` only calls `git_ignore(false)`;
`.railwayignore` remains active. `hidden(false)` includes hidden files.

After the walker has produced entries, the CLI unconditionally skips any path
with a component exactly equal to `.git` or `node_modules`. Those components
cannot be re-included. All other ignore negation/parent behavior is delegated
to `ignore 0.4.23`; the CLI has no separate matcher or documented precedence
table. Nested ignore support came from PR #210.

The walker and tar builder both follow links. A focused Linux probe at the
pinned revision established:

- a symlink to a file outside the walked root is accepted and archived as a
  regular file under the link's in-root name, with the outside target bytes;
- two hard-linked names are both archived as ordinary full-content entries;
- a symlink loop returns `File system loop found`;
- even an exact `.railwayignore` match for a dangling symlink returns `ENOENT`
  before the ignore can suppress it, matching open issue #1023.

There is no path-containment policy for resolved targets. Windows behavior is
owned by the same crates and the upstream Windows CI lane, but the repository
has no deployment-link tests and Windows symlink creation/permissions can
differ. Rejecting all links or enforcing canonical containment would change
current public behavior rather than clarify it.

`tar::append_path_with_name` carries filesystem-derived type/mode/metadata and
includes directory entries, including empty directories. The CLI does not
normalize modes. Rust `Path` and tar support non-UTF-8 Unix path bytes in the
existing upload, while a JSON plan using `PathBuf` would need an explicit
machine-readable encoding decision. The repository currently makes no such
JSON promise.

## Consistency, errors, and cleanup

The walk is materialized first, but file metadata and contents are opened later
while the tar is written. A file may therefore change between discovery and
read. Deletion, permission loss, loop detection, broken-link resolution,
prefix failure, tar failure, or compression failure returns `anyhow::Error`
and prevents upload. There is no filesystem snapshot, retry, rollback, or
temporary archive file to clean; the incomplete buffer is dropped in memory.

The body is uploaded only after `create_deploy_tarball` returns successfully.
Concurrent change semantics are consequently “whatever bytes and metadata tar
successfully reads,” not “the state at indexing time.” A durable plan created
before archive construction would invent staleness semantics unless it also
materialized the archive. The cheapest safe plan is the archive plus its entry
list, as prototyped.

## Public output conventions and tests

`up` already has `--verbose` and `--json`. JSON mode is machine-oriented for
deployment/log results, while many other commands serialize camel-case objects
with `serde_json`. A flag such as `up --plan` or `up --dry-run --json` is more
natural than a public Rust API because the project is a binary crate and the
packaging types are private implementation modules.

There are 474 inline Rust tests at the pinned revision and no `tests/` or
fixture directory. None targets `controllers::upload` or `get_deploy_paths`.
There are no checked fixtures for nested deploy roots, ignore files,
permissions, hard links, symlinks, empty directories, or non-UTF-8 names. The
official CI uses stable Rust for check, formatting/lints, and tests on Ubuntu,
macOS, and Windows.

## Feasibility answers

1. **Natural surface:** an `up` flag with ordinary and JSON output. A new
   subcommand would duplicate `up` arguments/root logic; a Rust public API does
   not fit this binary crate.
2. **Uploader shape:** a complete in-memory gzipped tar is built locally, then
   sent as one request body.
3. **Canonical selection:** yes, one `WalkBuilder` inside
   `create_deploy_tarball`; it is not factored as a separate public plan.
4. **One immutable plan:** yes, if the plan owns the already-materialized body
   and the exact entry list. The uploader already accepts that body.
5. **Semantic root:** the rules in “Roots” above; Railway service/workspace
   choices do not independently select filesystem roots.
6. **Ignore order/root:** delegated to a walker rooted at `project_path`;
   `.railwayignore` is added as a custom ignore name, Git ignore is default and
   optional, then `.git`/`node_modules` are filtered by component.
7. **Re-inclusion:** delegated for ordinary ignored parents; the two hard-coded
   component exclusions cannot be re-included.
8. **Links:** targets are followed, outside targets are accepted, broken links
   and loops error, hard links are duplicated. Platform behavior is not
   normalized by Railway.
9. **Modes/directories/names:** tar preserves filesystem metadata and directory
   entries. Existing upload can carry raw Unix names; JSON inspection needs an
   additional non-UTF-8 representation choice.
10. **Concurrent changes:** no snapshot; tar reads live paths after the walk and
    aborts on read errors.
11. **Determinism:** sorting normalized entry paths can stabilize the file-set
    and tar entry order. Byte-identical gzip/tar output is not promised because
    source metadata/content and compression details remain live.
12. **Scope:** no. The honest implementation is 81 strict effective production
    lines across two existing files and delegates all substantive behavior to
    the current walker/archive libraries.
