# DataSketches Theta A-not-B persistence archive

Status: **accepted and archived 2026-08-17**.

The user confirmed platform acceptance. The canonical problem package and its
compact design, environment, gap, fairness, false-positive, error, upstream,
and verification records remain under
`problems/datasketches-theta-anotb-persistence/`. This archive holds the raw
solver bundle, preliminary candidate dossier, compact recovery patches, and
selected verification logs.

## Repository and immutable accepted artifacts

- Repository: `https://github.com/apache/datasketches-java`
- Pin: `d5cce9b3ad3f7c39faabcebb7f3934c4f73f14fc`

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `959c446e9974b757fe3a105e03d3cfdaec61950c48ef8407f520ca754caf98c0` |
| `test.patch` | `7f05e0d86b7b8df86362a1be9c370bc9074db47d8d710926600bae5553ae9132` |
| `solution.patch` | `b145b1895ff99fd1f0e53794c7c54a86e601f0ac80f5b3915ca6e230c834ec4f` |
| `Dockerfile` | `41810ee27e986f723d0c7176059da76beb5566d3b91c9180988bc66e94eb688d` |
| `solution_approach.md` | `6d8daadb55e7654aa2e6b1d1c8f96a52b0fc3a755fac7ce9f471cee4bd55e834` |

The immutable Level 3 reference passes 82/82 selected base tests, 16/16 focused
tests, and 2,295/2,295 complete composed tests. The pristine repository passes
2,279/2,279 complete tests and fails all 16 solution-required focused methods.
All 19 attempted compile-valid mutants are killed. Four of five compatible
historical solver patches pass; fresh exact-version calibration remained 0/10
at closeout. Acceptance is the user-confirmed platform result, not an inference
from that replay.

## Raw solver evidence

| Archive | Historical version | File members | SHA-256 |
|---|---|---:|---|
| `raw-runs/agent-runs1.zip` | Level 2, quarantined for evaluator mismatch and later replayed against Level 3 | 40 | `8ab4acfc67fa7ade0ca60d0d16cf723670e976d9f4d7d3a68b37a43f77118b19` |

The ZIP passed `unzip -t`. It was extracted and recursively compared with the
readable source directory, excluding only `.DS_Store`; all 40 files were
byte-identical. The duplicate extraction was removed only after this check.

Restore the batch from the Olympus root with:

```sh
mkdir -p problems/datasketches-theta-anotb-persistence/agent-runs1
unzip archive/datasketches-theta-anotb-persistence/raw-runs/agent-runs1.zip \
  -d problems/datasketches-theta-anotb-persistence/agent-runs1
```

## Preliminary and recovery evidence

`candidate-records/DESIGN.md` is the original preflight dossier, preserved
byte-for-byte with SHA-256
`c9413b720e03d048a9d30eeab62d15a4ab39f61c63887e56d6d79198297fd3be`.

The disposable audit trees contained dirty reference, mutant, and near-solver
checkouts at the repository pin. Their tracked working states are retained as
binary-capable `git diff HEAD` files in `recovery-patches/`; the common injected
test and harness remain reconstructible from the canonical `test.patch`. The
two Phase A `.dockerignore` files were identical and are also retained. Small
JUnit, complete-suite, clone, and fetch logs are under `verification-logs/`.
`SHA256SUMS` authenticates every archived evidence file.

## Cleanup

`cleanup-inventory.tsv` records the immutable pre-cleanup inventory and each
classification. After archive verification, closeout removed the duplicate
raw-run extraction, empty active candidate directory, `.DS_Store` metadata,
two task-only Trash trees containing reconstructible repository clones, and
the four remaining task-named files under `/private/tmp` after their contents
were archived. The task-only Docker image
`olympus-datasketches-phase-a:latest`
(`sha256:68256c95539fa67510c8b3fbeb0eb58b4b5604ec0e3d2c1693dd28d2d819d684`)
was removed; no matching container, volume, network, or named build-cache entry
existed. `docker-resources.tsv` records the Docker disposition.

All removed checkouts and the image are reconstructible from the pinned
repository, frozen artifacts, archived recovery patches, and accepted
Dockerfile. Unrelated workspace changes and shared Docker resources were left
untouched.
