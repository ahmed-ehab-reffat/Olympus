# Environment gate - Afero copy-on-write namespace mutations

Status: `pass`.

Immutable version:

- Repository: `spf13/afero @ 768f1fb0e5535b77d90e44c531aacd652aabd96a`
- Prompt: `7c54baa9a4250d090542bc73a866b8c9f87dd869a13b8791768a5a260ff4af8a`
- Test patch: `0d882efc4555640ebeba57de65c64de300690ba5c1b1047ffeaeb4a1201b4cd1`
- Solution patch: `65939f4dc645bb3407d00b8a644e521b3a38e0b42ebbc97074fbb31debbf90a1`
- Dockerfile: `33c69a5c4ac80b747abb40dcd63c8fbbb29f96476ea1b8189fc14af7d66fc72f`
- Mandatory legitimate replay:
  `1889804c3febd969a054e5c3f08aff0a5d3330bdec039eada6a266189f7d18ae`
  (`redirect-replay.patch`)

## Quarantined source-clone attempt

The first invocation stopped before Docker and before any test process because
the original discovery checkout was a promisor clone missing an object needed
by the gate's mandatory `git clone --no-local`. It emitted an early-EOF pack
error. That invocation is quarantined and contributes no behavioral result.

A new ordinary complete clone was created at the same exact pin. It has no
`remote.origin.promisor` setting, passes `git fsck --full`, and was clean before
the gate. The complete exact gate then restarted from Phase A at 0.

## Phase A - pristine image

- Host Docker server: 29.2.1; free space before the exact build exceeded 110
  million KiB, above the 12 GiB threshold.
- Static Dockerfile contract: exact approved first line
  `FROM public.ecr.aws/d3j8x8q7/olympus-base:latest`, only `WORKDIR /app`, no
  build-time test, and `CMD ["/bin/bash"]`.
- Approved base digest:
  `sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`.
- The no-cache untouched build passed dependency download/verification,
  `go-junit-report` installation, and `go build ./...`. Its exported manifest
  list was
  `sha256:dae962087d73c823a1fee885fc5ef562f8e383483d21ab0a3c64845f49031a32`.
- Runtime networking was disabled. Exact lanes ran as UID/GID 10001 against
  read-only fresh clones. `go.mod`, `go.sum`, Go 1.26.1, the warmed module/cache,
  and `go-junit-report` were readable. `GOPROXY=off`, `GOSUMDB=off`, and
  readonly module flags were effective.
- Plain root-module discovery is real: the baseline mode emits 176 JUnit cases,
  zero failures/errors, and one skip. The root package contributes 153 cases;
  ordinary `mem`, `tarfs`, and `zipfs` tests also run. Nested independent GCS
  and SFTP modules are not part of the core task.

## Phase B - evaluator composition

| Tree | Injection | Base | New | JUnit/startup |
|---|---|---:|---:|---|
| pristine + `test.patch` | clean three-way/direct fallback, no unmerged entries | pass, 176 cases / 1 skip | behavioral fail, 7 cases / 7 failures | real JUnit, no startup error |
| eager reference + `test.patch` | clean | pass, 176 cases / 1 skip | pass, 7 cases | real JUnit |
| lazy redirect replay + `test.patch` | clean; manifest hash verified | pass, 176 cases / 1 skip | pass, 7 cases | real JUnit |

Baseline and reference new-mode testcase identities match exactly. Test patch
paths are additive (`cowfs_namespace_regression_test.go` and `test.sh`) and do
not overlap either implementation's participant-owned production paths.

This is the complete version-3 restart after the final coverage revision. The
new exact cells are layer-only remove/rename, mixed recursive removal,
base-only non-empty removal, base-only regular-file rename, and a conditional
later-stage rollback probe. No earlier version's environment result was carried
forward.

No near/broad solver patch exists for this new problem. The baseline supplies
the required behavioral-failure lane, and the structurally independent redirect
patch supplies the mandatory legitimate replay. No solver outcome is inferred.

## Verdict

`pass` for the immutable hashes above. Both pristine and exact evaluator
composition phases complete offline as an arbitrary non-root UID with real
JUnit output and conflict-free injection. Any artifact, pin, dependency,
harness, or replay-manifest change invalidates this verdict.
