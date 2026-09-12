Title: Add verified deployment plans to `railway up`

Add an offline planning mode to `railway up`. `railway up --write-plan <FILE>` must use the same source selection and local source-root resolution as an ordinary upload. The command must write the plan and exit without authentication, token refresh, or any remote request, including auxiliary background requests; this guarantee must not depend on network opt-out environment variables. Rewriting a plan located inside the selected root must exclude the plan file itself and produce identical bytes when the selected inputs have not changed.

The plan is strict, deterministic, versioned JSON. Its top-level fields are `version`, `pathAsRoot`, `noGitignore`, and `entries`. Entries are uniquely sorted by normalized UTF-8 archive path and contain `path`, `kind`, `size`, and, where applicable, `mode` and `sha256`. The selected root itself is represented as a directory entry; when that directory is the archive root, including with `--path-as-root`, its normalized path is `"."`. The root entry participates in the same path ordering as every other entry and need not be first. Apart from that root marker, paths must be relative archive paths and contain no `..` components. `kind` is `file` or `directory`; directory size is zero and directories have no digest. Regular-file digests are lowercase SHA-256. Unix plans record permission bits for files and directories. Planning must fail if a selected input is not a regular file when opened. Reject unknown fields, unsupported versions, invalid paths, malformed records, duplicates, and unsorted entries.

Add `railway up --from-plan <FILE>`. It must parse the plan, repeat ordinary source selection, and reject a `--path-as-root` or `--no-gitignore` setting, path set, entry type, size, Unix mode, or regular-file content that differs from the plan. This entire reconciliation must finish before authentication, token refresh, or any remote request.

The verified bytes must be the bytes placed in the upload archive. Applying a plan reads the currently selected local sources, and links follow the same containment behavior as ordinary `railway up`. Broken links, unsupported input types, and non-UTF-8 archive paths must return an error.

`--write-plan` and `--from-plan` conflict with each other and with `--new`.

## Compatibility

Expose `controllers::deploy_plan` with public `DeployPlan` and its schema fields, and public `DeployEntryKind::{File, Directory}`. The grader calls:

- `create_deploy_plan(service_root: &Path, project_root: &Path, plan_path: Option<&Path>, no_gitignore: bool, path_as_root: bool) -> anyhow::Result<DeployPlan>`
- `create_deploy_tarball_from_plan(service_root: &Path, project_root: &Path, plan_path: Option<&Path>, no_gitignore: bool, path_as_root: bool, plan: &DeployPlan) -> anyhow::Result<Vec<u8>>`
- `read_deploy_plan(path: &Path) -> anyhow::Result<DeployPlan>`
- `serialize_deploy_plan(plan: &DeployPlan) -> anyhow::Result<Vec<u8>>`
