# Fairness analysis — Afero copy-on-write namespace mutations, version 3

Verdict: `pass`.

Repository: `spf13/afero` at
`768f1fb0e5535b77d90e44c531aacd652aabd96a`.

Artifact identifiers: prompt
`7c54baa9a4250d090542bc73a866b8c9f87dd869a13b8791768a5a260ff4af8a`,
test patch
`0d882efc4555640ebeba57de65c64de300690ba5c1b1047ffeaeb4a1201b4cd1`,
reference
`65939f4dc645bb3407d00b8a644e521b3a38e0b42ebbc97074fbb31debbf90a1`,
Dockerfile
`33c69a5c4ac80b747abb40dcd63c8fbbb29f96476ea1b8189fc14af7d66fc72f`,
reference combined tree `df3a8a2ae2cb3ceef4091404d7a744793663c75d`,
and redirect combined tree `5b9d2f7a6c81d46650236908661b9c8e29d30953`.

## Rejection-predicate provenance

| Test/assertion/lane | What it rejects | Public or repository provenance | Implementation freedom preserved | Verdict |
|---|---|---|---|---|
| `os.IsNotExist` after removal/rename | a lower entry reappears through `Stat` or `Open` | prompt states those observations; Afero and Go use not-exist classification | exact error value and message are ignored | fair |
| exact sorted and paged directory sets | hidden or stale entries remain, or bookkeeping leaks | prompt requires parent iteration and invisible bookkeeping; `File.Readdirnames` is public | storage, native iteration order, and batching strategy are ignored; results are sorted | fair |
| accepted `ENOTEMPTY` or `EEXIST` | non-empty `Remove` succeeds or mutates the view | ordinary filesystem behavior and repository generic removal tests | both repository-observed non-empty classifications are accepted; strings are ignored | fair |
| direct base reads after mutations | an implementation writes into the base | central prompt and README sandbox invariant | any upper representation is allowed | fair |
| recreated-directory exact child set | opacity is absent after recursive removal | explicit prompt clause | map, marker, materialization, and redirect designs all qualify | fair |
| moved content, structure, and permission bits | source data or metadata is dropped | explicit prompt clause and public `FileInfo.Mode` | timestamps, ownership, inode identity, and private layout are not asserted | fair |
| replacement has no stale destination entries | rename overlays rather than replaces | explicit same-kind replacement clause | staging order and data-movement strategy are unconstrained | fair |
| repeated rename and moved deletion state | bookkeeping remains at an old prefix | explicit lifecycle clause | eager bytes, path redirects, and other journals are accepted | fair |
| cleaned aliases on `BasePathFs`/`OsFs` | raw-string keys split one logical path | explicit prompt clause plus `filepath.Clean`/Afero path behavior | no key representation is inspected | fair |
| conditional early and later failure snapshots | an error returns after exposing a partial namespace mutation | explicit pre-commit failure clause | a solution may avoid the faulting method and commit; success is accepted if complete | fair |
| `base` harness lane | production changes regress supported behavior | real root-module suite | no selected-test shortcut; all ordinary root packages run | fair |
| build-tagged `new` lane and JUnit | focused behavior is missing or the harness never starts | repository Go toolchain and evaluator contract | production filenames and internal symbols are never imported or inspected | fair |

## Architecture replay

| Legitimate implementation | Distinct architecture | Result | Fairness conclusion |
|---|---|---:|---|
| `solution.patch` | eager logical-tree staging, upper backups, and in-memory hidden/opaque state | 176/176 base with one skip; 7/7 focused | establishes one complete implementation |
| `redirect-replay.patch` | lazy destination-to-base redirects plus upper moves and namespace journal | 176/176 base with one skip; 7/7 focused | proves that tests do not require eager copying or the reference state seam |

## Unspecified-constraint audit

- Private implementation structure: no production symbol, field, filename,
  marker encoding, staging prefix, or layer contents are inspected.
- Encoding and malformed bytes: the task has no byte encoding. File payloads
  are ordinary short values used only to distinguish source and destination.
- Ordering, batching, and exact counts: directory order is sorted before
  comparison. A one-entry pagination lane checks public iterator behavior, not
  a required internal batch size.
- Timing, scheduling, and watchdogs: there is no product timeout, sleep,
  goroutine schedule, or concurrency assertion.
- Feature/build surfaces: only the root Go module is in scope. Independent
  nested GCS/SFTP modules and new symlink behavior are excluded publicly.
- Harness tools, network, permissions, and UID: the submitted image installs
  its reporter during build. Runtime is offline and succeeds as UID/GID 10001
  with a read-only source mount.
- Error strings and wrapper expectations: assertions classify stable Go errors
  and never match text. Fault wrappers implement the public `Fs` interface; an
  implementation is not required to call their failing operation.

## Corrections and rejected complaints

- An early prototype expected the lower `/src` mode after an upper child had
  already materialized the directory with a different mode. That prescribed a
  private copy-up choice. The oracle was corrected to preserve the actual
  logical source mode observed immediately before rename.
- Cross-layer symlink relocation was removed before public artifacts because
  independent `BasePathFs` roots do not expose a portable link-target
  representation through Afero's optional interfaces.
- Failure injection was made conditional: if a legitimate architecture avoids
  the injected backend call and returns success, only the fully committed view
  is required. If it returns an error, the original views are required. The
  second-call wrapper therefore probes rollback without mandating a call count.
- A complaint that exact directory sets prescribe internal markers is rejected:
  the public prompt explicitly says bookkeeping must not appear, while any
  invisible representation remains accepted.
- Arbitrary invalid names, cross-kind replacement, persistence across wrapper
  reconstruction, and concurrency were considered and rejected rather than
  converted into hidden predicates.

## Final fairness statement

Every remaining rejection predicate is grounded in the public prompt,
discoverable Afero behavior, or stable Go filesystem semantics. All observations
are through public filesystem APIs, and two materially different complete
architectures pass the exact verifier. The exact-version fairness verdict is
`pass`.
