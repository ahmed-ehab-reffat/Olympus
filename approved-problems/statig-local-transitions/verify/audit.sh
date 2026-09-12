#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TASK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="${STATIG_SOURCE_DIR:-$TASK_DIR/../../work/statig-local-transitions/source}"

words="$(wc -w <"$TASK_DIR/meta.md")"
if [ "$words" -gt 500 ]; then
    echo "meta.md has $words words; maximum is 500" >&2
    exit 1
fi

if LC_ALL=C grep -n '[^ -~]' "$TASK_DIR/meta.md"; then
    echo "meta.md is not ASCII-only" >&2
    exit 1
fi

git -C "$SOURCE_DIR" apply --check "$TASK_DIR/test.patch"
git -C "$SOURCE_DIR" apply --check "$TASK_DIR/solution.patch"

expected_test_files="$(
    printf '%s\n' \
        .config/nextest.toml \
        grader_tests/.gitignore \
        grader_tests/Cargo.toml \
        grader_tests/src/lib.rs \
        grader_tests/tests/k5r7.rs \
        grader_tests/tests/q7m2.rs \
        grader_tests/tests/t9c4.rs \
        grader_tests/tests/v3n8.rs \
        test.sh
)"
actual_test_files="$(
    git -C "$SOURCE_DIR" apply --numstat "$TASK_DIR/test.patch" | awk '{print $3}'
)"
if [ "$actual_test_files" != "$expected_test_files" ]; then
    echo "unexpected test.patch file list" >&2
    diff -u <(printf '%s\n' "$expected_test_files") <(printf '%s\n' "$actual_test_files") || true
    exit 1
fi

expected_solution_files="$(
    printf '%s\n' \
        README.md \
        statig/src/awaitable/inner.rs \
        statig/src/awaitable/state.rs \
        statig/src/blocking/inner.rs \
        statig/src/blocking/state.rs \
        statig/src/blocking/superstate.rs \
        statig/src/outcome.rs
)"
actual_solution_files="$(
    git -C "$SOURCE_DIR" apply --numstat "$TASK_DIR/solution.patch" | awk '{print $3}'
)"
if [ "$actual_solution_files" != "$expected_solution_files" ]; then
    echo "unexpected solution.patch file list" >&2
    diff -u <(printf '%s\n' "$expected_solution_files") <(printf '%s\n' "$actual_solution_files") || true
    exit 1
fi

if grep -Eni \
    'Olympus|Shipd|challenge author|reference solution|private dispatch metadata|solution\.patch|PLAN\.md|DESIGN\.md' \
    "$TASK_DIR/test.patch" "$TASK_DIR/meta.md"; then
    echo "authoring vocabulary leaked into participant-visible artifacts" >&2
    exit 1
fi

if grep -En \
    '^diff --git a/(target|grader_tests/target)|\.rustc_info|/deps/' \
    "$TASK_DIR/test.patch"; then
    echo "build output leaked into test.patch" >&2
    exit 1
fi

production_churn="$(
    git -C "$SOURCE_DIR" apply --numstat "$TASK_DIR/solution.patch" |
        awk '$3 ~ /^statig\/src\// { total += $1 + $2 } END { print total + 0 }'
)"
if [ "$production_churn" -lt 300 ] || [ "$production_churn" -gt 475 ]; then
    echo "production churn $production_churn is outside the approved 300-475 band" >&2
    exit 1
fi

echo "audit passed: $words words, $production_churn production lines, exact file lists"
