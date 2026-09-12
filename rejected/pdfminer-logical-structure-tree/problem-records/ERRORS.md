# ERRORS - pdfminer.six logical structure tree

## 1. Locked Atheris requires Clang and the separate libFuzzer runtime

- Date: `2026-08-20`
- Source: local environment gate
- Severity: high
- Verdict: valid

### Evidence

Two pristine image attempts failed before tests: first because Clang was absent,
then because Clang alone did not provide the required libFuzzer archive.

### Resolution

Install exact Debian `clang` and `libclang-rt-14-dev` packages during the image
build. The final no-cache build compiles the locked Atheris 3.0.0 offline.

### Durable lesson

Locked Python development groups can include native fuzzing dependencies; a
successful ordinary runtime install is not an all-groups environment gate.

## 2. Root-owned `uv` paths and read-only evaluator trees

- Date: `2026-08-20`
- Source: exact evaluator composition
- Severity: high
- Verdict: valid

### Evidence

One image exposed `uv` through `/root`, another committed a root-owned runtime
cache, and `uv run` attempted to create `/workspace/.venv` in the read-only
composed checkout. Each failed before pytest and was quarantined.

### Resolution

Copy the binary to a system-readable path, separate build/runtime cache paths,
and invoke the image-installed `/app/.venv/bin/pytest` from `test.sh`. Final
offline UID-10001 composition passes all lanes.

### Durable lesson

`--no-sync` does not guarantee that a project runner will avoid environment
initialization. Test the exact read-only mount and arbitrary UID.

## 3. SCM version inference fails when `.git` is excluded

- Date: `2026-08-20`
- Source: exact no-cache Docker build
- Severity: high
- Verdict: valid

### Evidence

The evaluator excludes `.git`; setuptools-scm therefore could not build the
editable local project even though a research context containing Git metadata
had succeeded.

### Resolution

Set the exact pin-derived version `20260108.dev6+ga18de2a9c` during build. The
final image builds from the untouched non-Git context.

### Durable lesson

Phase A must use the evaluator's real build context, including its metadata
exclusions.

## 4. Missing public module caused collection instead of behavior failure

- Date: `2026-08-20`
- Source: verifier composition review
- Severity: medium
- Verdict: valid

### Evidence

The first test draft imported the new module unconditionally, which would turn
the pristine lane into a pytest collection error rather than behavioral test
failures.

### Resolution

Feature discovery is optional at import time and each test asserts the missing
entry point at runtime. Final pristine JUnit contains 14 failures and zero
errors; testcase identities match the reference.

### Durable lesson

Tests for a wholly new public module need runtime feature discovery so absence
is a real behavioral rejection, not a harness-startup failure.
