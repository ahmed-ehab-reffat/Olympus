#!/usr/bin/env bash

set -u

IMAGE=${IMAGE:-go-mp4-sample-locations:verify}
PATCHES=$(cd "$(dirname "$0")/.." && pwd)

docker run --rm --network none -v "$PATCHES":/patches:ro "$IMAGE" bash -lc '
set -u
cd /app

git apply --check /patches/test.patch
git apply /patches/test.patch
chmod 755 test.sh

./test.sh --output_path /tmp/base-before.xml base
base_before=$?
./test.sh --output_path /tmp/new-before.xml new
new_before=$?

git apply --check /patches/solution.patch
git apply /patches/solution.patch

./test.sh new --output_path /tmp/new-after.xml
new_after=$?
./test.sh --output_path=/tmp/base-after.xml base
base_after=$?

for report in /tmp/base-before.xml /tmp/new-before.xml /tmp/new-after.xml /tmp/base-after.xml; do
    python3 -c "import sys, xml.etree.ElementTree as ET; ET.parse(sys.argv[1])" "$report"
done

printf "base-before=%s new-before=%s new-after=%s base-after=%s\n" \
    "$base_before" "$new_before" "$new_after" "$base_after"
test "$base_before" -eq 0
test "$new_before" -ne 0
test "$new_after" -eq 0
test "$base_after" -eq 0
'
