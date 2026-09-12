# Verification — revision 8 environment / revision 6 semantics

Repository pin: `e233d906138995583f42359831d1908e3cb005e7`.

## Environment diagnosis

All five platform run directories contain only `run.txt`; none contains a
trajectory, solver patch, evaluator log, or JUnit. Before repair, three canonical
submission files had the macOS `dataless` flag, zero allocated blocks, and read
as empty. This explains both `Dockerfile cannot be empty` and `No valid patches
in input`. Those attempts are environment no-starts, not failed solutions, and
calibration is `0/10`.

The four canonical artifacts are materialized. The Dockerfile begins with the
exact validator-approved TypeScript base declaration, and the reusable gate
builds with `--pull --no-cache` while recording the resolved digest.

Revision 7 changed the Dockerfile identity, and Shipd allocated a genuinely new
image, `im-fBWE9ZVQywsN5dG9uE5RQA`, instead of `im-Wem…`. The new image also
failed, and the only displayed log was “Docker build log is empty, image was
cached,” so no failing Docker instruction is available from the platform.

Revision 8 reduces the clean AMD64 image from 636,185,865 to 557,746,557 bytes
by assigning workspace permissions during `COPY` and deleting disposable root
build caches. Its Dockerfile SHA-256 is `1e4c8bc03ed6…`. Prompt, tests,
reference implementation, dependency versions, and test counts remain
byte-identical to revision 6.

## Cold exact evaluator result

| Tree | Base | Feature |
|---|---:|---:|
| pristine + tests | 2/2 pass | 15/15 named failures |
| reference + tests | 2/2 pass | 15/15 pass |

The untouched image built cold, then all four lanes ran offline as UID/GID
10001. The base cases are the existing `LNEX5` and `LNEX8`. Pristine and
reference feature JUnit have the same fifteen testcase identities, with no
hook, startup, or skipped feature node.

This complete four-lane gate was rerun after the revision 8 image reduction and
passed. A separate clean AMD64 build and offline non-root startup also passed.
No broad suite or mutation batch was added to this environment retry.

## Coverage and mutation result

Revision 5 added two tests: custom DataType identifiers in structure definitions
and nested structured encoded values. The first independently fails an
untranslated-field-DataType mutant; the second independently fails a skipped-
recursion mutant. The zero-based seventeen-mutant audit kills sixteen public
feature/API defects in the 15-test file. The single focused survivor changes
legacy ordering and fails exactly `LNEX5` and `LNEX8` in the complete 1,040-test
pre-existing suite, which has two existing skips. There are no actionable
survivors and no nonbehavioral kills.

Revision 6 adds no testcase. It strengthens the existing cross-model reload
case to resolve every selected-owned fixture node and strengthens the existing
dependency case to inspect exact RequiredModel metadata under each selected
Model. The focused count remains fifteen. The exact nineteen-mutant replay
kills the isolated-object omission and global dependency-union defects only in
their intended cases; eighteen public/API mutants are focused kills in total.
The cold four-lane environment gate was rerun after the patch and passed.

## Reproduction

```sh
./scripts/environment_gate.sh \
  --problem problems/node-opcua-nodeset-merge \
  --repo /path/to/pristine-node-opcua

problems/node-opcua-nodeset-merge/verify/mutations.sh \
  /path/to/pristine-node-opcua \
  node-opcua-nodeset-merge-phase-a
```

Patch application, artifact materialization, exact composition, testcase
identity parity, and mutation results were all rechecked after the final test
change.
