#!/usr/bin/env bash
# Four-gate verification inside the built image with no network, run through test.sh.
# Expects the image `moov-ach-test` to be built from a pristine clone at the pinned commit.
#
#   test.patch only        -> base passes, new fails with a well formed report
#   test.patch + solution  -> new passes, base passes

SUB=/Users/andrewemad/Documents/Olympus/problems/moov-ach

docker run --rm --network none \
    -v "$SUB":/patches:ro \
    moov-ach-test bash -c '
set -u
cd /app

fail() {
    echo "  FAIL: $*" >&2
    exit 1
}

report() {
    # go-junit-report records a compile failure as an error rather than a failure,
    # so both attributes matter when reading a report.
    head -2 "$1" | grep -o "tests=\"[0-9]*\"\( failures=\"[0-9]*\"\)\?\( errors=\"[0-9]*\"\)\?" | head -1
}

assert_status() {
    label="$1"
    expected="$2"
    actual="$3"
    if [ "$actual" -ne "$expected" ]; then
        fail "$label exit=$actual, expected $expected"
    fi
}

assert_report() {
    path="$1"
    tests="$2"
    failures="$3"
    errors="$4"
    python3 - "$path" "$tests" "$failures" "$errors" <<"PY"
import sys
import xml.etree.ElementTree as ET

path, tests, failures, errors = sys.argv[1:]
root = ET.parse(path).getroot()
actual = {
    "tests": int(root.get("tests", 0)),
    "failures": int(root.get("failures", 0)),
    "errors": int(root.get("errors", 0)),
}
expected = {"tests": int(tests), "failures": int(failures), "errors": int(errors)}
if actual != expected:
    raise SystemExit(f"{path}: {actual}, expected {expected}")
PY
}

echo "commit: $(git rev-parse HEAD 2>/dev/null || echo "no git metadata")"

echo
echo "### applying test.patch"
git apply --check /patches/test.patch 2>/dev/null && echo "  applies cleanly"
patch -p1 --silent < /patches/test.patch || exit 1
chmod 755 test.sh
echo "  test.sh mode: $(stat -c %a test.sh)"

echo
echo "### GATE 1: test.patch only -> base (expect exit 0)"
./test.sh --output_path /tmp/g1.xml base >/dev/null 2>&1
status=$?
echo "  exit=$status  report=$(report /tmp/g1.xml)"
assert_status "gate 1" 0 "$status"
assert_report /tmp/g1.xml 1534 0 0 || fail "gate 1 report"

echo
echo "### GATE 2: test.patch only -> new (expect nonzero + failing report)"
./test.sh --output_path /tmp/g2.xml new >/dev/null 2>&1
status=$?
echo "  exit=$status  report=$(report /tmp/g2.xml)"
[ "$status" -ne 0 ] || fail "gate 2 unexpectedly passed"
assert_report /tmp/g2.xml 125 125 0 || fail "gate 2 report"

echo
echo "### applying solution.patch"
patch -p1 --silent < /patches/solution.patch || exit 1

echo
echo "### GATE 3: + solution.patch -> new (expect exit 0)"
./test.sh --output_path /tmp/g3.xml new >/dev/null 2>&1
status=$?
echo "  exit=$status  report=$(report /tmp/g3.xml)"
assert_status "gate 3" 0 "$status"
assert_report /tmp/g3.xml 125 0 0 || fail "gate 3 report"

echo
echo "### GATE 4: + solution.patch -> base (expect exit 0)"
./test.sh --output_path /tmp/g4.xml base >/dev/null 2>&1
status=$?
echo "  exit=$status  report=$(report /tmp/g4.xml)"
assert_status "gate 4" 0 "$status"
assert_report /tmp/g4.xml 1534 0 0 || fail "gate 4 report"

echo
echo "### entity census: every new testcase must exist in both runs"
python3 /patches/verify/census.py /tmp/g2.xml /tmp/g3.xml
status=$?
echo "  census exit=$status"
assert_status "entity census" 0 "$status"

echo
echo "### argument parsing"
./test.sh --output_path=/tmp/eq.xml new >/dev/null 2>&1
status=$?; echo "  --output_path=<p>  exit=$status"; assert_status "equals argument" 0 "$status"
./test.sh new --output_path /tmp/after.xml >/dev/null 2>&1
status=$?; echo "  mode first         exit=$status"; assert_status "mode-first argument" 0 "$status"
./test.sh --output_path /tmp/none.xml >/dev/null 2>&1
status=$?; echo "  missing mode       exit=$status (expect 2)"; assert_status "missing mode" 2 "$status"

echo
echo "### stale report handling"
./test.sh --output_path /tmp/stale.xml new >/dev/null 2>&1
echo "  report after a passing run: $(report /tmp/stale.xml)"
assert_report /tmp/stale.xml 125 0 0 || fail "stale report handling"
'
