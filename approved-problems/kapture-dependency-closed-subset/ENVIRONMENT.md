# Environment gate — kapture dependency-closed dataset subset, immutable v8

Status: `Phase A and exact Phase B pass`.

Repository: `naver/kapture @ 8225b77d0657e6a3eb1ffc941d009100b792fb25`.

Version ID: `08aaa4d7231bb1232f0bb29c4c2705ad7442fd0b7e7f4ef4e04f5a46fc9eeac2`.

## Phase A

The final submitted Dockerfile was rebuilt with `--pull --no-cache` from the
untouched pin. It resolved
`public.ecr.aws/d3j8x8q7/olympus-base-python@sha256:6ddc78fc675e6cd3a63b60fc63d87eea35a479f503a44a89cf92923abe905dd8`.
The final image manifest, config, and manifest-list digests were respectively
`sha256:87e9a9e9806184ae1c79142ff211753984b6122e432f85cbb348a8f31d46afdf`,
`sha256:69632de0b1e8039820214c87525a641b642a6da13e72103ad1cd8e2f376142ea`,
and `sha256:0c46ce5b382b64f77cb4e18906e82d67f75187c066be5c0c7f51cbf1990cd6ff`.

Every runtime lane used `--network none --user 10001:10001`, a read-only
injected tree, and UID-owned scratch. The untouched base lane completed all 186
discovered tests: 181 passed and five pre-existing ROS tests skipped.

## Exact Phase B

Composition order was implementation patch, verifier patch, then direct
`./test.sh --output_path ... {base,new}` execution.

| Composition | Base | Focused | Verdict |
|---|---:|---:|---|
| pristine plus verifier | 181 passed, 5 skipped | 0/13; 13 behavioral failures, 0 errors | expected fail |
| `solution.patch` plus verifier | 181 passed, 5 skipped | 13/13 | pass |
| mandatory `verify/architecture-b.patch` plus verifier | 181 passed, 5 skipped | 13/13 | pass |

Baseline/reference JUnit testcase identities match. `test.sh` is mode 100755
and writes per-test XML. Verifier paths do not overlap participant-owned
production paths, and injection leaves no unmerged nodes.

The exact v8 compatibility replay also applied the verifier after each of the
five `agent-runs2` patches without conflict. Every patch passed 181 base tests
with five skips. Runs 1–4 passed 12/13 focused nodes and failed only nested
non-kapture preservation; run 5 passed 13/13.

Final submission hashes:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `884ab178305c1cab97083f56d1a738a1c39850694ac337077b1ec311aa523a42` |
| `test.patch` | `46a9ff2e39dfae9f0f7a6eb14971b1028100555bcfabbfa1b1e4d0796c20210c` |
| `solution.patch` | `4aa7b4893c27e82c85ff2c9136ecc6963e39fa9c233b63e2c793db72f2b5b4db` |
| `Dockerfile` | `d3f84bad6e90b98984a0c152f3b4c27c28896cb08390ad245a225d26a4e03682` |

An initial v8 mutation pass found the raw-string same-path mutant surviving
because the no-force overwrite guard happened to reject `source/.`. The final
verifier exercises the same normalized alias with `force=True` and confirms the
source tree remains byte-identical. The no-cache environment gate above is the
complete restart after that change.

Any submission-artifact, dependency, pin, harness, or injection-path change
invalidates this verdict and resets calibration to 0/10.

