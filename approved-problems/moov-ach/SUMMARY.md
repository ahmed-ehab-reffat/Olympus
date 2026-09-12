# SUMMARY - moov-io/ach ApplyCorrections L4b

**Status: accepted on 2026-07-23. The final panel-requested correctness revision
is implemented and fully verified.**

## Why this level exists

L1, L2, and L3 were all too easy: six Nova runs produced six legitimate solutions.
Runs 5 and 6 passed all 74 L3 tests and all 1534 baseline tests with the same basic
forward architecture: immutable matching, ordered classification, immediate
mutation with one rollback snapshot, refusal collection, offset/control rebuild,
and refused-file construction. Nova 5 also added IAT targets proactively.

L4 crossed three shapes that the earlier trajectories had not implemented:

| Axis | Added behavior |
|---|---|
| C | Persist each accepted pre-state and construct reverse-order executable Undo; applying Undo constructs redo |
| H | Match bounded ordinary and IAT targets through one typed pipeline, including C08 and Addenda15 |
| V | Validate tentative C05 against the concrete ACK/ATX/DNE/ENR/ordinary/IAT batch and roll back on C69 |

Nova 7-12 all failed L4 legitimately, with hidden totals from 100/120 to 118/120.
Every run failed the same two IAT C05 service-class tests; Nova 10 failed only
those two, while five runs also failed offsets. L4a clarifies the directional
service-class result. Nova 13 then passed 120/120 and Nova 14 passed 118/120, but a
panel probe proved Nova 13's custom corrected-data parser accepted incomplete
composite data. L4b adds that missing coverage and fixes the reference's output
service-class handling without changing public behavior.

## Repository and output

- Repository: `moov-io/ach`
- Production language: Go
- Task type: feature request
- Commit: `d550ecb851b889c37bb8e474bcf1cfd982638453`
- API: `ApplyCorrections(corrections ...*File) (*CorrectionResult, error)`
- Solution files: `correction.go`, `correction_target.go`,
  `correction_undo.go`, `correction_refused.go`
- Solution size: 713 physical lines, about 564 nonblank non-comment lines
- Hidden suite: `test/corrections/corrections_eda8cb_test.go`, 125 named tests
- Harness: `test.sh`, mode 100755
- Description: 492 words including Title, pure ASCII, with no hard-wrapped sentences

Canonical artifacts live in this directory. `RUNS.md` is the compact calibration
index, and the raw run bundles are preserved under `archive/moov-ach`. Scratch
checkout cleanup is recorded separately so the pre-existing dirty checkout remains
protected.

## Upstream concept sweep

A read-only 2026-07-22 GitHub API sweep confirmed `master` still resolves to the
pinned commit. All-state issue/PR searches found no `ApplyCorrections`, refused
correction, or offset/IAT correction implementation. Related closed work remains
record-level support such as issue 1714 on partial CorrectedData parsing and PR
1031 on refused COR/NOC codes; neither implements this file-level operation. This
supports repository novelty but is not evidence about private evaluation archives.

## Four gates and entity census

All gates run from the pristine pinned image with `--network none` and invoke tests
only through `./test.sh`.

| Gate | Result |
|---|---|
| test patch only, `base` | 1534 tests, 0 failures, exit 0 |
| test patch only, `new` | 125 tests, 125 failures, 0 errors, exit 1 |
| test plus solution, `new` | 125 tests, 0 failures, exit 0 |
| test plus solution, `base` | 1534 tests, 0 failures, exit 0 |
| entity census | identical names; all 125 entities fail-to-pass |

The gate also verifies both output-path argument forms, mode placement, missing-mode
exit 2, executable mode, and stale-report replacement. The base run contains no
`[build failed]` or other synthetic testcase.

## Mutation evidence

`verify/mutate.py` applies 41 compiling source mutations inside the same offline
image.

- Survivors: 0
- Synthetic or compile-only kills: 0
- Mutations killed by fewer than two named tests: 0
- Minimum kill count: 2
- `nova-5-as-written` composite: 45 kills
- `nova-6-as-written` composite: 27 kills

The matrix adds incomplete composite parsing, both C06 forward fields, and output
service-class rebuilding to the prior inverse, matching, IAT, concrete-validation,
rollback, refusal, offset, and C/H/V composite coverage.

## Static and artifact checks

| Check | Result |
|---|---|
| `gofmt -l` on changed Go files | clean |
| `go vet ./ ./test/corrections/...` | clean |
| both patches apply with `--whitespace=error` | clean at the pinned commit |
| ASCII scan of `meta.md`, patches, and verification docs | clean |
| word-boundary leak scan | clean |
| solution/reference comparison | byte-identical |
| Dockerfile | unchanged from the settled L3 image |

Patch contents are exact:

```
test.patch      -> test.sh
                   test/corrections/corrections_eda8cb_test.go
solution.patch  -> correction.go
                   correction_refused.go
                   correction_target.go
                   correction_undo.go
```

## Fairness review

The contract states the result nil matrix, source and target representations,
supported ordinary/IAT codes, refusal precedence, complete composite-data parsing,
concrete validation and rollback, offset order, both output artifacts, final-DFI
history, inverse data, undo/redo behavior, directional and existing-mixed service
classes, controls, source immutability, accepted no-ops, and no-notification case.
It states the refused addenda's required values and accessor behavior without
enumerating fields already discoverable in the public struct.
The sentence-deletion audit found no redundant summary or contrapositive sentence.
Every asserted behavior maps to a public clause and public library state; tests do
not require a private helper, chosen architecture, timing, network, or error text.
