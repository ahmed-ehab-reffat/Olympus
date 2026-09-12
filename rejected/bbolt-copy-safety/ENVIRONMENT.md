# Environment gate - bbolt snapshot-copy safety

Status: `Phase A pass after two quarantined discovery runs; Phase B not
applicable after pre-authoring rejection`.

Date: 2026-08-15.

Repository pin: `0464afc4b2120d472bae971ac2934f947145418e`.

## Phase 0 - Dockerfile contract

- First line: `FROM public.ecr.aws/d3j8x8q7/olympus-base:latest`.
- Sole workdir: `WORKDIR /app`.
- The exact source is copied, dependencies are downloaded, and all packages
  build during image creation.
- Tests do not run during image creation.
- `/app` alone is configured as a system Git safe directory so bbolt's
  Makefile can obtain its branch and commit when the container runs under an
  arbitrary UID.
- Final command: `CMD ["/bin/bash"]`.

Verdict: `pass`.

## Quarantined discovery runs

The first offline UID/GID 10001 run used `go test -count=1 ./...`. Every
ordinary package passed, including the 334.982-second root package, but
`tests/failpoint` reported eight `failpoint does not exist` errors. That package
is not part of the ordinary pristine lane: the upstream Makefile and CI first
rewrite the source with `go tool go.etcd.io/gofail enable .` and run it through
the separate `test-failpoint` target. The result was quarantined as an
incorrect composition, not a bbolt test failure.

The image was rebuilt from zero and the upstream ordinary `make test` lane was
selected. Its first attempt was stopped immediately because the Makefile's
read-only Git metadata queries rejected the root-owned `/app` checkout as
having dubious ownership under UID 10001. The Dockerfile was corrected with a
system-level safe-directory entry scoped to `/app`, invalidating the prior
image and run.

Neither discovery run is behavioral evidence, and calibration remains 0/10.

## Phase A - pristine environment restart

After the Dockerfile correction, the image was rebuilt from zero and the
complete gate restarted:

- Docker client/server: 29.2.1.
- Host free space before the first build: 116,983,056 KiB.
- Base digest:
  `sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`.
- Clean image ID:
  `sha256:f2b65569deffe420022d05a370a751e44c2aee7db758eb546e47cf08903a2ea5`.
- Runtime: `--network none --user 10001:10001`.
- Writable temporary Go cache and build directories were scoped under `/tmp`.
- UID/GID, `go.mod` readability, `go-junit-report` executability, and exact Git
  HEAD were checked before tests.
- Runtime Go: `go1.26.1 linux/arm64`, `GOTOOLCHAIN=local`, and
  `GOFLAGS=-mod=readonly`; the module's `go 1.25.0` and `toolchain go1.25.13`
  declarations required no network access.

Exact test command after the preflight checks:

```sh
make test
```

This is bbolt's supported ordinary test target. It runs the root, internal,
and command-package suites once with `TEST_FREELIST_TYPE=hashmap` and once with
`TEST_FREELIST_TYPE=array`, with `BBOLT_VERIFY=all`. Both modes and all command
packages passed, including the concurrency, long-reader, simulation,
copy/backup, reopen, and surgery-command tests.

Verdict: `pass`.

## Phase B

Not run. The disposable fairness/convergence audit rejected the task before
`meta.md`, `test.patch`, or `solution.patch` existed. Phase B and all downstream
exact-version audits are therefore not applicable. Any materially different
bbolt task must restart Phase A rather than inherit this verdict.
