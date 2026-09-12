# Environment viability — Excelize structural reference adjustment

## Immutable Phase A subject

- Date: 2026-08-16
- Repository: `qax-os/excelize`
- Exact commit: `40f8be41a7aecf250fae03b7d79478a22a4e75a9`
- Checkout: full clone; detached exact pin; `git fsck --full` passed and the
  worktree was clean before the build.
- Dockerfile: `Work/excelize-escalation/phase-a/Dockerfile`
- Approved base: `public.ecr.aws/d3j8x8q7/olympus-base:latest`
- Built image ID:
  `sha256:d7377f7fd2a1954f6f44de01c8aa464c785d72df89853c0a13ee6dd000c5af12`
- Host-volume preflight: 23,354,668 KiB free, above the required 12 GiB.
- Runtime: Docker 29.2.1, network disabled, read-only container root, UID/GID
  10001:10001, and a temporary writable staging tree copied from the root-owned
  `/app` source. The original source and `/opt/go/pkg/mod` cache remained
  non-owned and read-only to the runtime UID.
- Tools: Go 1.26.1 (`linux/arm64`) and
  `go-junit-report` v2.1.0 were executable. `go.mod`, `go.sum`, and a pinned
  module-cache record were readable offline. `GOFLAGS` was
  `-mod=readonly -buildvcs=false`.

## Fail-fast attempt and quarantine

The first direct read-only run failed because upstream Excelize tests create
generated workbooks under the repository's `test/` directory. This was a
harness-placement failure, not a repository behavior failure. The evaluator
must copy its read-only `/workspace` mount to a UID-owned temporary tree before
running Go tests.

The first staged run used the upstream race flag. It reached 311 passing tests
and was then OOM-killed in
`TestZip64/for_save_zip64_with_in_memory_file_over_4GB` after 708.392 seconds.
The approved runtime exposed 7.653 GiB, while that test deliberately allocates
more than 4 GiB before race-instrumentation overhead. Its JSON and JUnit logs
are quarantined under
`Work/excelize-escalation/phase-a/results/quarantine-race-oom/`. This run is not
behavioral evidence and cannot be counted as a solver failure.

## Phase A pass

The exact pin was rebuilt without any test or solution patch. The passing
offline lane used the repository's CI discovery path without race
instrumentation and with `GITHUB_ACTIONS=true`, matching the upstream skip for
the separate sparse temporary-file-over-4-GB ZIP64 case:

```text
go vet ./...
go build ./...
go test -json -v -timeout 60m ./... \
  -coverprofile=/tmp/excelize-coverage.txt -covermode=atomic
```

The Go JSON stream was converted by `go-junit-report -parser gojson
-set-exit-code` into real JUnit. Result: exit 0, 583 tests, 0 failures, 0
errors, 1 upstream skip, 40.240 seconds, and 99.8% statement coverage. Logs:

- `Work/excelize-escalation/phase-a/results/phase-a-go-test.json`
- `Work/excelize-escalation/phase-a/results/phase-a-junit.xml`

Phase A verdict: **pass**, provided the eventual evaluator stages the read-only
checkout in writable temporary storage and does not enable race instrumentation
inside the 7.653 GiB runtime.

## Phase B status

Completed after promotion. The final immutable submission rebuilt the
untouched pin and passed baseline/reference composition in evaluator order,
offline and as UID 10001. Baseline and reference each pass all 583 base tests;
the pristine tree fails all 12 focused assertions, and the reference passes all
12. The authoritative exact hashes, image manifest, and commands are recorded
in `problems/excelize-structural-reference-adjustment/ENVIRONMENT.md`.
