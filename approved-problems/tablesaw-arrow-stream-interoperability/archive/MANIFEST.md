# Tablesaw Arrow stream interoperability archive

Status: **accepted and archived 2026-08-20**.

The user confirmed platform acceptance. The canonical accepted package and its
compact design, environment, gap, fairness, false-positive, summary, and run
records remain under `problems/tablesaw-arrow-stream-interoperability/`. This
archive preserves raw solver bundles, the preliminary candidate dossier,
deduplicated authoring recovery, selected verification results, and cleanup
inventories.

## Repository and immutable accepted artifacts

- Repository: `https://github.com/jtablesaw/tablesaw`
- Pin: `e36c3ff3c9e21026f4a04590a5319edfc27f5c84`

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `9d0a55d07ab6008e661537e55c209ad7986765f3f2db1d20dc58fbe545d9edda` |
| `test.patch` | `86fec7eab6211ca038a617f7e178815b2a42a4866a4a4b6d91d3a041ca8cbc83` |
| `solution.patch` | `7f1eb0788491006d18fe4c0ba2a873a7251b2cba73edb724fd19c8310ed9e588` |
| `Dockerfile` | `4825c81a115e455df5493271c0a97685abfb2c1e257ace5e7eea92fdb9f823ba` |

The exact final reference passes 3/3 pre-existing Arrow tests, 28/28 focused
methods, and the complete 11-module reactor offline as UID/GID 10001. The
untouched complete reactor also passes, while pristine fails all 28 focused
methods behaviorally. Two legitimate writer representations pass 28/28 and all
nine final compiling mutants are rejected. Run-6 compatibility is 0/5; the
fresh expectation was 2--4/10, but fresh exact-version calibration remained
0/10. Acceptance is the user's external platform result.

## Raw solver evidence

| Archive | Files | SHA-256 |
|---|---:|---|
| `raw-runs/agent-runs1.zip` | 80 | `026a9f874d4d62b8b9e5458285cce3a7b8960bd1944cb97a3fb1feee13ba7974` |
| `raw-runs/agent-runs2.zip` | 40 | `c5206e437834e7e602366963e15eda1a2c7c7d66e4f11eb316b161b22045320f` |
| `raw-runs/agent-runs3.zip` | 80 | `90fe156909e301b582d9c1494d62abe621a99cf3ed70fe125b062d9e75361515` |
| `raw-runs/agent-runs4.zip` | 40 | `a0b254ef918e30d62b892d0250735fdce783d89e220572d3ecb528898611ad27` |
| `raw-runs/agent-runs5.zip` | 40 | `1eba01d16f36cbd2ec346b4b4418908c93cd0aef0dfb4212c35a6c2f82383deb` |
| `raw-runs/agent-runs6.zip` | 40 | `f810206d9c965303ad0fa04b966ebf7092dbc07608cc6cc0133a2de707093c6f` |

All six ZIPs passed CRC validation. Every one of their 320 non-Finder files
was compared with the corresponding readable extraction and was byte-identical.
The expanded directories and active ZIP copies may therefore be retired after
the archive checksum gate.

Restore a bundle from the Olympus root with, for example:

```sh
mkdir -p problems/tablesaw-arrow-stream-interoperability/agent-runs6
unzip archive/tablesaw-arrow-stream-interoperability/raw-runs/agent-runs6.zip \
  -d problems/tablesaw-arrow-stream-interoperability/agent-runs6
```

## Preliminary, authoring, and verification evidence

`candidate-records/` preserves the three-file preliminary dossier byte-for-byte.

`authoring-recovery.tar.gz` has SHA-256
`23ff37b35b6cad2b33a3ace769932ae83546e4a1e85bfbdef1a037e444b72712`.
It inventories 234 task scratch repositories and preserves 137 distinct binary
Git patches plus 91 distinct non-generated untracked blobs with path mappings.
It explicitly excludes 168 generated JavaCPP/MKL/Finder files totaling
4,196,771,970 bytes. Every archive member was compared byte-for-byte with its
source before cleanup.

`verification-results.tar.gz` has SHA-256
`e5db2baa6ab75334f61fc7eae042f619fb658286e2d877c1be8b99e07c22f287`.
It preserves 217 regular files from 39 small result/log roots, including the
final environment, focused, complete-suite, variant, mutant, and compatibility
outputs. Every archived regular file matched its source hash.

## Cleanup result

`cleanup-inventory-pre.json` is the cleanup skill's read-only 102-record
inventory. `cleanup-inventory.tsv` adds evidence classifications and final
dispositions. `cleanup-inventory-post.json` is the read-only verification
inventory: only the canonical problem record remains, with zero matching
Docker containers or images. `docker-resources.tsv` records the ten removed
task-owned image tags and immutable IDs; no task-matching container existed.

After the complete archive passed checksum, ZIP, gzip, member, source-parity,
and readability checks, closeout permanently removed:

- six expanded run directories and their six now-archived active ZIP copies;
- the byte-identical preliminary candidate duplicate and Finder metadata;
- 100 explicitly inventoried `/private/tmp` files/directories totaling about
  46.45 GiB in the pre-cleanup inventory; and
- ten container-free Tablesaw image tags and their unshared image records.

The live problem directory is now about 248 KiB and the cold archive about
32 MiB. Removed checkouts and images are reconstructible from the upstream pin,
frozen artifacts, raw solver bundles, recovery archive, and accepted
Dockerfile. Deletion itself is not recoverable, but the unique evidence is.
Unrelated workspace changes, containers, images, volumes, networks, and build
cache were left untouched.
