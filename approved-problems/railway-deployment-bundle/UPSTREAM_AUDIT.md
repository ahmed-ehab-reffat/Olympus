# Railway deployment-bundle upstream audit

Status: passed the upstream prior-art/task-identity gate on 2026-07-26 at
`4d49d9845a27a0947ab903b01789eb9f854414d8`. This does not override the later
scope rejection.

## Search coverage

The full clone includes every advertised remote branch and tag. Searches used
the exact plan vocabulary and discovered names:

```text
bundle, deployment bundle, deploy bundle, package, archive
upload, deploy input, file plan, file list, manifest
inspect, preview, dry run, explain, deterministic
ignore, .gitignore, .railwayignore, root, service root
symlink, hard link, traversal, canonicalize, workspace
tar, gzip, zip, compression, checksum, digest
include, exclude, hidden file, executable mode
create_deploy_tarball, upload_deploy_tarball, DeployPaths, get_deploy_paths
```

The audit covered:

- all open and closed issues, and all open, closed, and merged pull requests,
  using GitHub search;
- Discussions capability (the repository has Discussions disabled);
- releases and the repository's release configuration;
- every fetched branch and tag, including all branches not merged into the
  pinned revision;
- full Git history using commit-message, path, `-G`, and `-S` searches;
- current source, inline tests, README/docs, assets, workflows, and dependency
  manifests; and
- every issue/PR/commit linked from issue #181 and the symlink/ignore history.

Representative local commands were:

```bash
git log --all --oneline --grep='bundle\|archive\|manifest\|preview\|dry.run'
git log --all -G'create_deploy_tarball|railwayignore|follow_links|path_as_root'
git log --all -S'node_modules' -- src
git grep -I -n -E \
  'deployment (bundle|plan)|upload (plan|manifest)|bundle manifest|file manifest' \
  <each fetched remote ref>
rg -n -i \
  'bundle|archive|manifest|preview|dry.?run|checksum|symlink|railwayignore' \
  src README.md .github Cargo.toml Cargo.lock
```

The remote-ref search found only unrelated deploy/log help text. No fetched
branch contains an upload plan, deployment manifest, or deployment-bundle
preview.

## Current source result

The pinned implementation has one complete collector/archive seam:

1. `src/commands/up.rs::get_deploy_paths` chooses the walked root and archive
   prefix.
2. `src/controllers/upload.rs::create_deploy_tarball` configures
   `ignore::WalkBuilder`, collects all entries, filters `.git` and
   `node_modules`, and writes an in-memory gzipped tar.
3. `src/controllers/upload.rs::upload_deploy_tarball` sends that exact
   `Vec<u8>` as the HTTP request body.

There is no second server-side or client-side scan after archive creation.
There is no reusable manifest type, public upload-set listing, preview command,
deployment dry run, or deployment checksum. The only observability is progress
over walked entries and compressed body length under `--verbose`.

This means the upstream-overlap stop condition does not fire: the exact public
inspection operation is absent. It also creates the separate scope risk later
confirmed by `PROTOTYPE.md`: almost all required behavior already exists
privately in one helper.

## Relevant history

| Record | Upstream behavior established |
|---|---|
| [issue #181](https://github.com/railwayapp/cli/issues/181), [PR #187](https://github.com/railwayapp/cli/pull/187), commit `9f60d77` | Introduced a Railway ignore file instead of only hard-coded exclusions. |
| [issue #152](https://github.com/railwayapp/cli/issues/152), PRs [#170](https://github.com/railwayapp/cli/pull/170) and [#177](https://github.com/railwayapp/cli/pull/177), commit `64f6a17` | Established the historical choice to follow and copy symlink targets. |
| PR [#210](https://github.com/railwayapp/cli/pull/210), commit `d2620f9` | Added nested ignore-file handling. |
| issue #224, PR #226, commit `3eff97e`; PR #296, commit `67c8099` | Reordered ignore evaluation and symlink resolution, then changed it again. |
| issue #473; PRs #481, #482, and #484 | Debated Git ignore behavior and retained it behind the current `--no-gitignore` control. |
| PR #413 | Established unconditional component filtering for `.git` and `node_modules`. |
| [issue #595](https://github.com/railwayapp/cli/issues/595), [PR #596](https://github.com/railwayapp/cli/pull/596), commit `d5f1933` | Added `--path-as-root`. |
| issue #608, PR #609, commit `d8e3632` | Corrected `--no-gitignore`. |

The currently open
[issue #1023](https://github.com/railwayapp/cli/issues/1023), filed on
2026-07-24 against v5.28.1, reports that an exact `.railwayignore` match cannot
shield a dangling symlink: `follow_links(true)` resolves the target before the
ignore decision and returns `ENOENT`. It cites the earlier symlink changes.
This is important repository evidence that symlink semantics remain unsettled,
but the issue does not request or implement a deployment plan.

Searches also located Windows release-archive work and generic tar/archive
fixes. Those operate on CLI release artifacts or old upload failures, not an
inspectable upload plan. No referenced thread identified an equivalent fork.

## Search-query ledger

| GitHub query family | Results reviewed | Exact operation |
|---|---:|---|
| `bundle OR archive OR tarball OR manifest OR package` | 92 | absent |
| `preview OR inspect OR "dry run" OR explain OR deterministic` | 38 | absent; matches concern other commands |
| `checksum OR digest OR compression OR "file list" OR "file plan"` | 18 | absent |
| `gitignore OR railwayignore OR symlink OR canonicalize OR traversal` | 34 | adjacent history above |

Counts are the 2026-07-26 search snapshot, not durable repository metrics.

## Audit verdict

Pass for uniqueness, with a symlink-policy warning. Upstream does not already
provide the proposed central public operation, and no issue/PR publicly
specifies it. The candidate therefore advanced to the local-similarity and
cheapest-solution gates. The audit does not support inventing containment,
canonical-link, byte-reproducibility, or snapshot semantics: current behavior
follows out-of-root links, errors on loops and ignored dangling links, and
reads the live tree while constructing the archive.
