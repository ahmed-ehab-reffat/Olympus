# Kapture dependency-closed subset archive

Status: **accepted and archived 2026-08-19**.

The user confirmed platform acceptance. The canonical accepted package and its
compact design, environment, gap, fairness, false-positive, error, upstream,
run, and verification records remain under
`problems/kapture-dependency-closed-subset/`. This archive holds the two raw
solver bundles, the preliminary candidate dossier, and cleanup inventories.

## Repository and immutable accepted artifacts

- Repository: `https://github.com/naver/kapture`
- Pin: `8225b77d0657e6a3eb1ffc941d009100b792fb25`
- Version ID: `08aaa4d7231bb1232f0bb29c4c2705ad7442fd0b7e7f4ef4e04f5a46fc9eeac2`

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `884ab178305c1cab97083f56d1a738a1c39850694ac337077b1ec311aa523a42` |
| `test.patch` | `46a9ff2e39dfae9f0f7a6eb14971b1028100555bcfabbfa1b1e4d0796c20210c` |
| `solution.patch` | `4aa7b4893c27e82c85ff2c9136ecc6963e39fa9c233b63e2c793db72f2b5b4db` |
| `Dockerfile` | `d3f84bad6e90b98984a0c152f3b4c27c28896cb08390ad245a225d26a4e03682` |

The immutable v8 reference and an independent inverse-overlay architecture
each pass 181 base tests with five skips and all 13 focused tests. The pristine
repository fails all 13 focused tests, and all 39 attempted mutants are killed.
The historical v7-patch compatibility replay was forecast and observed at 1/5;
fresh exact-v8 calibration remained 0/10 at closeout. Acceptance is the
user-confirmed platform result, not an inference from local verification.

## Raw solver evidence

| Archive | Historical version | File members | SHA-256 |
|---|---|---:|---|
| `raw-runs/agent-runs1.zip` | pre-v7, ten solvers | 80 | `8fdaa31dc6b6e18154b7bea33ca47eb462c8bb829d9f4f95dc06a7663f6f4808` |
| `raw-runs/agent-runs2.zip` | v7, five successful solvers | 40 | `ac9a77a3a9c68ba94f79b5aeda345a9248c85fd75111b15204accce6d5b4cd41` |

Both ZIPs passed `unzip -t`. Every non-`.DS_Store` member was compared with
its readable extraction: all 80 and 40 files, respectively, were byte-identical.
The duplicate extractions were removed only after these checks.

Restore either batch from the Olympus root with, for example:

```sh
mkdir -p problems/kapture-dependency-closed-subset/agent-runs2
unzip archive/kapture-dependency-closed-subset/raw-runs/agent-runs2.zip \
  -d problems/kapture-dependency-closed-subset/agent-runs2
```

## Preliminary and scratch evidence

`candidate-records/DESIGN.md` is the original preflight dossier, preserved
byte-for-byte with SHA-256
`f2f0848fa1c9cbe8502d76a63ab49021a3591d09e33f78fd76afa62a3847dcaf`.

All discarded scratch trees were checkouts of the pinned repository. The clean
source had the public upstream URL and exact pin above. The two authored trees
were verified at the Git-blob level against the frozen `solution.patch` or
`verify/architecture-b.patch`, each composed with `test.patch`. The five
compatibility trees matched the corresponding archived `agent-runs2` solution
patch plus the current verifier for every present changed file; their omitted
`test.sh` was not unique evidence. The two mutant-application checks matched
the frozen reference and architecture-B production blobs. Generated caches,
test results, and installed metadata were reproducible and disposable.

## Cleanup

`cleanup-inventory.tsv` records the immutable pre-cleanup inventory,
classification, archive destination, and disposition. After archive integrity
verification, closeout removed the duplicate run extractions, the empty active
candidate directory, Finder metadata, four task scratch roots, seven temporary
index directories created only for blob comparison, and two task-only Docker
images. No task-matching container existed. Unrelated workspace changes,
containers, images, volumes, networks, and build cache were left untouched.

All removed checkouts and images are reconstructible from the pinned repository,
frozen artifacts, archived solver bundles, and accepted Dockerfile.
