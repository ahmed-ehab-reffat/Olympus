# verify/

Local verification for the `moov-io/ach` ApplyCorrections submission. Everything
here runs offline against a container built from a pristine clone at
`d550ecb851b889c37bb8e474bcf1cfd982638453`.

## Building the image

```bash
git clone https://github.com/moov-io/ach.git ach && cd ach
git checkout d550ecb851b889c37bb8e474bcf1cfd982638453
cp ../Dockerfile Dockerfile.build
docker build -f Dockerfile.build -t moov-ach-test .
rm Dockerfile.build
```

The image must build with **neither** patch applied.

To confirm the runtime is genuinely offline and user-agnostic:

```bash
docker run --rm --network none              moov-ach-test bash -lc 'cd /app && go build ./...'
docker run --rm --network none -u 1000:1000 moov-ach-test bash -lc 'cd /app && go build ./...'
```

Both must succeed. `docs/webui` cannot link on a non-js platform as upstream ships
it, so the Dockerfile supplies the stub it is missing; see `../ERRORS.md`
section 6a.

## `gates.sh`

The four-gate check plus harness argument handling. Runs with `--network none` and
drives everything through `./test.sh`, never `go test` directly.

```
base with test.patch only        -> exit 0
new  with test.patch only        -> nonzero, well-formed failing report
new  with test.patch + solution  -> exit 0
base with test.patch + solution  -> exit 0
```

The script enforces the exact reports: 1534 baseline entities, and 125 feature
entities which all fail before the solution and all pass after it.

`report()` reads both `failures` and `errors`, because `go-junit-report` encodes a
package that does not compile as an `error` on a `[build failed]` testcase rather
than as a failure.

It then runs `census.py` over the gate 2 and gate 3 reports as a fifth gate.

## `census.py`

Diffs the testcase names of the `new` run before and after the solution. The grading
wrapper classifies individual testcases, so a name present in only one of the two
runs lands in neither the pass-to-pass nor the fail-to-pass set and is reported as
unclassified. It flags:

- names present in only one of the two runs;
- synthetic entities (`[build failed]`, `[no tests to run]`, `[no test files]`);
- entities that already pass without the solution, or still do not pass with it.

This was added after a review round caught a `[build failed]` entity that all four
original gates had passed over; see `../ERRORS.md` section 4.

Current result: **125 entities before, 125 after, all failing without the solution and
passing with it.**

## `mutate.py`

41 textual mutations of the solution cover the C history journal, H bounded IAT
targets, V concrete-batch validation, composite-data parsing, C06 forward fields,
output service classes, carried L3 behavior, both observed Nova recipes, and every
single- or two-axis C/H/V partial. They run inside the image with both patches
applied.

```bash
docker run --rm --network none -v <submission>:/patches:ro moov-ach-test bash -c '
    cd /app
    patch -p1 --silent < /patches/test.patch
    patch -p1 --silent < /patches/solution.patch
    chmod 755 test.sh
    python3 /patches/verify/mutate.py'
```

Exits non-zero if any mutation survives **or** if any mutation is killed by fewer
than two tests. A mutation whose only effect is a compile failure is reported as
`BUILD-ONLY` and proves nothing; rewrite it rather than accept it.

Current result after the review revision: **41 mutations, 0 survivors, 0 weak or
synthetic kills, and a minimum of 2 tests killed per mutation.** The
`nova-5-as-written` and `nova-6-as-written` composites are killed by 45 and 27 tests
respectively.
