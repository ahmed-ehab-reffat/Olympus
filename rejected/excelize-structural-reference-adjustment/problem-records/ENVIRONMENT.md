# Environment viability — Excelize structural reference adjustment

## Immutable version

- Date: 2026-08-16
- Repository pin: `40f8be41a7aecf250fae03b7d79478a22a4e75a9`
- `meta.md`: `745f5d75524980aad1094d27e49ac0939226592b79bc0b6b425f2fbc5677587d`
- `test.patch`: `619b5d4276e0ade214fc2c3539d4b81eed8624ea7defc265906b11861700dc4f`
- `solution.patch`: `0683b4099bc6c91a2625da2d35b75dc561b8d512905d555673b1e8314b4b3b7c`
- `Dockerfile`: `bc744ed1078ad721d86ca847c003e5f490880ddf075e9b8b4132ce0e45b03da6`
- Final gate image manifest:
  `sha256:8c89dd6261b5c1f0eed8b7e232c07d1a4384d3b8c75916ebb85eb42a34d954dc`

## Phase A

The checkout was a full detached clone at the exact pin and passed
`git fsck --full`. Docker 29.2.1 was available, and every clean build began
above the mandatory 12 GiB host-volume threshold. The submitted Dockerfile
starts with the approved general Olympus base and uses only `WORKDIR /app`.
Its build resolves and verifies `go.mod`/`go.sum`, installs
`go-junit-report` v2.1.0, disables runtime module resolution, and builds every
package without either patch present.

The final image ran offline as UID/GID 10001:10001. Go 1.26.1, the reporter,
module metadata, and the root-owned `/opt/go/pkg/mod` cache were readable. The
upstream tests create workbooks beneath the checkout's `test/` directory, so
`test.sh` copies the evaluator's read-only `/workspace` mount to a fresh
UID-owned directory under `/tmp` before invoking Go. With
`GITHUB_ACTIONS=true`, matching upstream CI's explicit skip for the sparse
temporary-file-over-4-GB case, the real base path passed 583 tests with 0
failures/errors and 1 upstream skip.

An early race-instrumented trial was OOM-killed in the deliberate
in-memory-ZIP64-over-4-GB case after 311 prior passes. The approved runtime has
7.653 GiB, and race overhead exceeds it. Those logs are quarantined under
`Work/excelize-escalation/phase-a/results/quarantine-race-oom/`; the attempt is
environment evidence only and was never counted as a product or solver
failure. The non-race upstream discovery path completes in roughly 35–40
seconds.

Phase A verdict: **pass**.

## Phase B — exact evaluator composition

Final command:

```text
scripts/environment_gate.sh \
  --problem problems/excelize-structural-reference-adjustment \
  --repo Work/excelize-escalation/source
```

The script rebuilt from the untouched exact pin, injected patches only after
the image existed, mounted every composed tree read-only, disabled networking,
and used UID 10001. Results:

| Tree/lane | Result | Real JUnit |
|---|---:|---:|
| baseline + `test.patch`, `base` | pass | 583 tests, 0 failures/errors, 1 skip |
| baseline + `test.patch`, `new` | behavioral fail | 12 tests, 12 failures, 0 errors |
| baseline + `solution.patch` + `test.patch`, `base` | pass | 583 tests, 0 failures/errors, 1 skip |
| baseline + `solution.patch` + `test.patch`, `new` | pass | 12 tests, 0 failures/errors |

The feature testcase identities were byte-for-byte identical between baseline
and reference JUnit. `test.patch` touches only the additive build-tagged test
and `test.sh`; it does not overlap the participant-owned `adjust.go`. Patch
application left no rejects, unmerged nodes, or hybrid tree.

Phase B verdict: **pass**. No representative external solver patches exist yet,
so there is no `ENVIRONMENT_REPLAYS.sha256` manifest. Any artifact, pin,
dependency, or evaluator-path change invalidates this record.
