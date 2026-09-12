#!/usr/bin/env bash

set -uo pipefail

SUB="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${1:-str0m-remote-offer-test}"

docker run --rm --network none \
    -v "$SUB":/patches:ro \
    "$IMAGE" bash -c '
set -uo pipefail
cd /app

apply_patch_file() {
    git apply --check "$1"
    git apply "$1"
}

run_gate() {
    expected="$1"
    report="$2"
    mode="$3"

    ./test.sh --output_path "$report" "$mode"
    status=$?

    if [ "$expected" = "pass" ] && [ "$status" -ne 0 ]; then
        echo "$mode unexpectedly failed with exit $status" >&2
        exit 1
    fi
    if [ "$expected" = "fail" ] && [ "$status" -eq 0 ]; then
        echo "$mode unexpectedly passed" >&2
        exit 1
    fi

    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import xml.etree.ElementTree as ET; ET.parse(\"$report\")"
    fi
}

apply_patch_file /patches/test.patch

run_gate pass /tmp/test-only-base.xml base
run_gate fail /tmp/test-only-new.xml new

apply_patch_file /patches/solution.patch

run_gate pass /tmp/solved-new.xml new
run_gate pass /tmp/solved-base.xml base
'
