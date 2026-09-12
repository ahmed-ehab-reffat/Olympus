#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 REPOSITORY_CHECKOUT DOCKER_IMAGE" >&2
    exit 2
fi

repo_dir="$(cd "$1" && pwd)"
image="$2"
problem_dir="$(cd "$(dirname "$0")/.." && pwd)"
audit_root="$(mktemp -d "${TMPDIR:-/tmp}/kapture-mutations.XXXXXX")"
cleanup() {
    rm -rf -- "$audit_root"
}
trap cleanup EXIT

survivors=0
for mutant in "$problem_dir"/verify/mutants/*.patch; do
    name="$(basename "$mutant" .patch)"
    tree="$audit_root/$name"
    git clone --quiet --no-local "$repo_dir" "$tree"
    if [[ "$name" == 12-* ]]; then
        git -C "$tree" apply "$problem_dir/verify/architecture-b.patch"
    else
        git -C "$tree" apply "$problem_dir/solution.patch"
    fi
    git -C "$tree" apply "$mutant"
    git -C "$tree" apply "$problem_dir/test.patch"
    chmod +x "$tree/test.sh"
    mkdir "$tree/results"
    chmod 0777 "$tree/results"

    exit_code=0
    docker run --rm --network none --user 10001:10001 \
        -v "$tree:/source:ro" \
        -v "$tree/results:/results" \
        "$image" bash -lc \
        'cp -R /source /tmp/workspace && cd /tmp/workspace && ./test.sh --output_path /results/new.xml new' \
        >"$tree/new.log" 2>&1 || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo "SURVIVED $name"
        survivors=$((survivors + 1))
        docker run --rm --network none --user 10001:10001 \
            -v "$tree:/source:ro" \
            -v "$tree/results:/results" \
            "$image" bash -lc \
            'cp -R /source /tmp/workspace && cd /tmp/workspace && ./test.sh --output_path /results/base.xml base' \
            >"$tree/base.log" 2>&1 || true
    else
        nodes="$(grep -E '^(FAILED|ERROR) tests/' "$tree/new.log" \
            | sed -E 's/^(FAILED|ERROR) tests\/test_dataset_partitioning.py::TestDependencyClosedSubset::([^ ]+).*/\2/' \
            | paste -sd, -)"
        echo "KILLED $name nodes=$nodes"
    fi
done

echo "survivors=$survivors"
[[ $survivors -eq 0 ]]
