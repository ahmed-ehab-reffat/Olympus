# Tablesaw Arrow stream interoperability

Status: **accepted by the platform and archived 2026-08-20**.

- Repository: `https://github.com/jtablesaw/tablesaw`
- Pin: `e36c3ff3c9e21026f4a04590a5319edfc27f5c84`
- Production language: Java
- Task type: enhancement

The accepted package integrates Arrow IPC streams with Tablesaw's normal I/O
options and extension registries while preserving the legacy file helpers. Its
behavioral contract crosses every record batch, caller-owned streams,
configurable batch boundaries, Arrow validity, direct and dictionary UTF-8,
the module's scalar and temporal surface, explicit unrepresentable-state
rejection, and reader recovery after conversion failure.

## Immutable accepted artifacts

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `9d0a55d07ab6008e661537e55c209ad7986765f3f2db1d20dc58fbe545d9edda` |
| `test.patch` | `86fec7eab6211ca038a617f7e178815b2a42a4866a4a4b6d91d3a041ca8cbc83` |
| `solution.patch` | `7f1eb0788491006d18fe4c0ba2a873a7251b2cba73edb724fd19c8310ed9e588` |
| `Dockerfile` | `4825c81a115e455df5493271c0a97685abfb2c1e257ace5e7eea92fdb9f823ba` |

The pristine repository passes its three existing Arrow writer tests and fails
all 28 focused methods behaviorally. The reference passes 3/3 existing and
28/28 focused methods. The complete untouched and composed 11-module reactors
pass offline as UID/GID 10001. Two materially different legitimate writer
representations pass 28/28, and none of nine final compiling mutants survives
the focused verifier.

The five run-6 patches solved the preceding 24-behavior version. Their exact
compatibility replay against the accepted version is 0/5: all five retain the
24 earlier behaviors and miss the four public option/registry/batching
discriminators. The final fresh-calibration expectation was 2--4/10, inside the
accepted 1--5/10 band, but fresh exact-version calibration remained 0/10 at
closeout. Platform acceptance is the user's external disposition, not an
inference from those historical runs.

Six raw solver bundles, the preliminary candidate dossier, authoring recovery,
verification results, and cleanup inventories are under
`archive/tablesaw-arrow-stream-interoperability/`.
