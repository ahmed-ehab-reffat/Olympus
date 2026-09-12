#!/usr/bin/env bash

set -euo pipefail

IMAGE="${STATIG_VERIFY_IMAGE:-statig-local-transitions:verification}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TASK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_ROOT="$(mktemp -d /tmp/statig-gates.XXXXXX)"

run_gate() {
    local name="$1"
    local command="$2"

    set +e
    docker run --rm --network none \
        -v "$TASK_DIR:/patches:ro" \
        "$IMAGE" \
        bash -c "$command" >"$LOG_ROOT/$name.log" 2>&1
    local status="$?"
    set -e
    printf '%s' "$status" >"$LOG_ROOT/$name.status"
}

run_gate test_only_base \
    'git apply /patches/test.patch && ./test.sh --output_path /tmp/report.xml base && test -s /tmp/report.xml && grep -q "<testsuites" /tmp/report.xml' &
run_gate test_only_new_rejects \
    'git apply /patches/test.patch && ./test.sh --output_path /tmp/report.xml new; status=$?; test "$status" -ne 0 && test -s /tmp/report.xml && grep -q "skipped=\"1\"" /tmp/report.xml' &
run_gate solution_new \
    'git apply /patches/test.patch && git apply /patches/solution.patch && ./test.sh --output_path /tmp/report.xml new && test -s /tmp/report.xml && grep -q "<testsuites" /tmp/report.xml' &
run_gate solution_base \
    'git apply /patches/test.patch && git apply /patches/solution.patch && ./test.sh --output_path /tmp/report.xml base && test -s /tmp/report.xml && grep -q "<testsuites" /tmp/report.xml' &

wait

overall=0
for name in test_only_base test_only_new_rejects solution_new solution_base; do
    status="$(cat "$LOG_ROOT/$name.status")"
    echo "$name: $status"
    tail -n 8 "$LOG_ROOT/$name.log"
    if [ "$status" -ne 0 ]; then
        overall=1
    fi
done

exit "$overall"
