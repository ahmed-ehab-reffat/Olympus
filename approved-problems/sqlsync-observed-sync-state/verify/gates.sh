#!/usr/bin/env bash

set -euo pipefail

IMAGE="${SQLSYNC_VERIFY_IMAGE:-olympus-sqlsync-observed-base:v24}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TASK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_ROOT="$(mktemp -d /tmp/sqlsync-gates.XXXXXX)"

run_gate() {
    local name="$1"
    local command="$2"

    set +e
    docker run --rm --platform linux/amd64 --network none \
        -v "$TASK_DIR:/patches:ro" \
        "$IMAGE" \
        /bin/bash -c "$command" >"$LOG_ROOT/$name.log" 2>&1
    local status="$?"
    set -e

    printf '%s\n' "$status" >"$LOG_ROOT/$name.status"
    printf '%s: %s\n' "$name" "$status"
    tail -n 10 "$LOG_ROOT/$name.log"
    return "$status"
}

overall=0

run_gate pristine \
    'just test && just package-sqlsync-worker dev' || overall=1

run_gate tests_only_base \
    'git apply /patches/test.patch
     ./test.sh --output_path /tmp/report.xml base
     test -s /tmp/report.xml
     grep -q "failures=\"0\"" /tmp/report.xml
     grep -q "<system-out>" /tmp/report.xml
     grep -q "test result: ok" /tmp/report.xml' || overall=1

run_gate tests_only_base_stock_tools \
    'git apply /patches/test.patch
     toolchain_bin="$(dirname "$(rustup which cargo)")"
     PATH="$toolchain_bin:/usr/bin:/bin" ./test.sh --output_path /tmp/report.xml base
     test -s /tmp/report.xml
     grep -q "failures=\"0\"" /tmp/report.xml
     grep -q "<system-out>" /tmp/report.xml
     grep -q "test result: ok" /tmp/report.xml' || overall=1

run_gate tests_only_new_rejects \
    'git apply /patches/test.patch
     set +e
     ./test.sh --output_path /tmp/report.xml new
     status=$?
     set -e
     test "$status" -ne 0
     test -s /tmp/report.xml
     grep -q "failures=\"1\"" /tmp/report.xml
     grep -q "<system-out>" /tmp/report.xml
     grep -q "SyncState::status accepts neither an owned nor borrowed receipt" /tmp/report.xml' || overall=1

run_gate solution_only \
    'git apply /patches/solution.patch && just lint && just test && just package-sqlsync-worker dev' || overall=1

run_gate combined_new \
    'git apply /patches/solution.patch
     git apply /patches/test.patch
     ./test.sh --output_path /tmp/report.xml new
     test -s /tmp/report.xml
     grep -q "failures=\"0\"" /tmp/report.xml
     grep -q "<system-out>" /tmp/report.xml
     grep -q "HOOK_RUNTIME_PROBE" /tmp/report.xml
     grep -q "BROWSER_PROBE" /tmp/report.xml' || overall=1

run_gate combined_new_missing_browser_tools_rejects \
    'set -e
     git apply /patches/solution.patch
     git apply /patches/test.patch
     stock_bin="$(mktemp -d)"
     toolchain_bin="$(dirname "$(rustup which cargo)")"
     for command_name in node dirname rm env mkdir mktemp cat tee tr sed cc ld ar; do
         ln -s "$(command -v "$command_name")" "$stock_bin/$command_name"
     done
     set +e
     PATH="$stock_bin:$toolchain_bin" /bin/bash ./test.sh --output_path /tmp/report.xml new
     status=$?
     set -e
     test "$status" -ne 0
     test -s /tmp/report.xml
     grep -q "failures=\"1\"" /tmp/report.xml
     grep -q "<system-out>" /tmp/report.xml
     grep -q "required browser integration tool is missing: pnpm" /tmp/report.xml
     ! grep -q "<skipped\|skipped=" /tmp/report.xml' || overall=1

run_gate combined_base \
    'git apply /patches/solution.patch
     git apply /patches/test.patch
     ./test.sh --output_path /tmp/report.xml base
     test -s /tmp/report.xml
     grep -q "failures=\"0\"" /tmp/report.xml
     grep -q "<system-out>" /tmp/report.xml
     grep -q "test result: ok" /tmp/report.xml' || overall=1

printf 'logs: %s\n' "$LOG_ROOT"
exit "$overall"
