# Environment viability — node-opcua NodeSet merge

Status: `archived — repeated Shipd image-builder no-start; calibration 0/10`.

Repository: `node-opcua/node-opcua` at
`e233d906138995583f42359831d1908e3cb005e7`.

Revision 8 binding: `meta.md` `164e5deeaaa8`, `test.patch`
`4605db209fca`, `solution.patch` `7bda8973c435`, and Dockerfile
`1e4c8bc03ed6`.

## Frozen environment

- Accepted base declaration: `public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest`
- Digest resolved by the cold gate:
  `sha256:a2ac69f318e782a6b20fd29ceefe27ef31cd4d6fddbcab18eac57aa8ba0c5c90`
- Base digest:
  `sha256:a2ac69f318e782a6b20fd29ceefe27ef31cd4d6fddbcab18eac57aa8ba0c5c90`
- Revision 8 final image: built successfully from the untouched repository;
  the gate removes its per-run local tag after verification.
- Runtime network: disabled with both Corepack and npm offline controls.
- Runtime identity: arbitrary non-root UID `10001`.

The image installs the frozen pnpm graph, generates `node-opcua-types`, creates
the repository's sample certificates, and builds `node-opcua-address-space` and
its workspace dependencies. `/app` is writable by the arbitrary evaluator UID;
the repository's conventional `/app/tmp` root is sticky and world-writable.

## Exact evaluator composition

`scripts/environment_gate.sh` cloned the pinned repository with independent Git
objects, applied patches in the evaluator's order, built the untouched image,
and ran each lane offline as UID 10001.

| Composition | Base lane | Feature lane | Required interpretation |
|---|---:|---:|---|
| pristine + `test.patch` | 2/2 pass | 15/15 named failures | expected: public helper is absent |
| pristine + `solution.patch` + `test.patch` | 2/2 pass | 15/15 pass | reference verdict |

The pristine and reference feature JUnit files contain the same fifteen
testcase identities. Pristine emits fifteen ordinary named failures, zero
skips, and no hook or startup nodes; reference emits the same names as fifteen
passes. This is
the exact p2p/f2p-compatible shape required by the wrapper, not a compile,
import, permission, dependency, or JUnit-startup placeholder.

Revision 3 retains revision 2b's prompt, metadata checks, and unpredictable
path, but moves participant-API invocation out of suite setup. Revision 2b
removed the redundant legacy-output sentence from `meta.md`, added
direct RequiredModel version/date coverage, and renamed the additive feature
test to the unpredictable
`test_export_selected_namespaces.36c2ba.test.ts` path. Revision 5 adds the
custom-DataType and nested-structured-value cases at the same randomized path.
Both Phase A and Phase B
were rerun from zero after those changes. The unpredictable test applies after
the reference without overlapping participant-owned production files, and its
baseline absence-of-helper failure remains behavioral after real discovery.

The base lane is intentionally narrow. It runs only the existing `LNEX5` and
`LNEX8` cases from `test_loadnodeset_value.ts`: export/reload with data type and
enum values, and namespace translation when exporting objects added beneath an
existing namespace. Both directly guard the old exporter behavior touched by
this task. The complete package suite is not part of participant scoring; it is
used only to investigate a focused mutation survivor.

No representative solver patch exists yet, so Phase B exercised the required
baseline and reference compositions. Future solver-shaped patches must repeat
the same exact-version gate before any run is counted.

## Quarantined environment failures

The following authoring attempts were not interpreted as solution results:

1. Corepack initially tried to populate `/.cache/node/corepack/v1` as the
   arbitrary UID. `COREPACK_HOME=/opt/corepack` is now populated at build time.
2. The repository's tests initially could not create `/app/tmp`. The Dockerfile
   now creates it with mode `1777`.
3. A copied pnpm workspace changed its absolute installation path and attempted
   an offline reinstall. The harness now overlays changes into `/app`.
4. The first generic gate used a Bash array expansion that was unsafe on the
   host's Bash 3.2 and a shared Git clone whose absolute alternates were absent
   in the container. The gate now uses safe optional-array expansion and
   `git clone --no-local`.
5. The revision 2b pristine feature lane invoked the absent helper in a shared
   `before` hook, producing an unclassifiable hook testcase. Revision 3 keeps
   shared setup repository-only, makes missing-helper assertions belong to each
   named test, and adds exact baseline/reference testcase-name parity to the
   reusable environment gate.
6. The platform reported that cached evaluator image `im-Wem…` could not be
   pulled. Revision 7 changed the Dockerfile identity and the platform allocated
   the distinct image `im-fBWE9ZVQywsN5dG9uE5RQA`, proving the cache key did
   change. That image also failed, while its displayed build log contained only
   “Docker build log is empty, image was cached.” Both runs are quarantined:
   neither exposes an underlying Docker instruction failure or reaches tests.
7. The first revision 4 declaration prototype directly re-exported the runtime
   implementation from the separate type barrel and created a circular import
   before test discovery. It was discarded. The final reference uses a
   declaration-only signature in the advertised type barrel; the rebuilt image
   and all four exact lanes then passed offline as UID 10001.

Every artifact change after this verdict requires a fresh Phase A and Phase B
run. Calibration remains at `0/10`.

## Revision 5 cold viability and no-start diagnosis

The five directories under `agent-runs/` contain only a 199-byte `run.txt`
recording a run ID and platform URL. They contain no trajectory, solver patch,
build log, evaluator result, or JUnit. The run IDs are
`rd7f5msnfabhsjdrygbf70ehg18c975c`,
`rd7dyz53k417abhgycsvkeczpx8c8ztq`,
`rd75dkpjgfysxwe16qcep63yn58c88hk`,
`rd79k2takg47mv1c1rf6yg4q4s8c9ra1`, and
`rd70hs67j9mgtev6fz2s66p97n8c8y7s`. They are no-start environment records,
not five failed solutions; calibration remains `0/10`.

The local submission artifacts explained the no-start shape. This problem
lives in a cloud-managed Documents tree whose quota is exhausted. Before
repair, `meta.md`, `solution.patch`, and `Dockerfile` reported nonzero logical
sizes but had zero allocated blocks, carried the macOS `dataless` flag, and
read as empty. The concrete downstream messages were therefore accurate:
Docker saw an empty Dockerfile and Git saw no valid solution patch. The four
submission artifacts have been materialized and now have allocated blocks.
The repository still contains other dataless files, so artifact block/flag
checks remain part of preflight until the cloud quota problem is fixed.

Revision 5 uses the validator-approved TypeScript base declaration. The
reusable gate uses `docker build --pull --no-cache` and recorded the resolved
digest above; a genuinely cold untouched build completed successfully. The
final exact composition then ran
offline as UID/GID 10001:

| Composition | Base lane | Feature lane |
|---|---:|---:|
| pristine + `test.patch` | 2/2 pass | 15/15 named failures |
| pristine + `solution.patch` + `test.patch` | 2/2 pass | 15/15 pass |

Pristine and reference feature JUnit have exactly the same fifteen testcase
identities. Neither has a hook/startup node or feature skip. The exporter emits
some pre-existing loader diagnostics while loading the structured fixture, but
the process reaches and classifies the named testcases; these diagnostics are
not environment failures.

## Revision 6 exact environment result

Revision 6 strengthens assertions inside two existing feature testcases only.
The accepted TypeScript `FROM` line remained unchanged. The gate nevertheless
rebuilt the untouched image with `--pull --no-cache` and reran every exact
composition offline as UID/GID 10001. Pristine base passed 2/2, pristine
feature produced fifteen named failures, reference base passed 2/2, and
reference feature passed 15/15. Feature testcase identities match exactly;
there are zero feature skips and no hook, startup, compilation, permission, or
patch-application node. The participant test count remains fifteen.

## Revision 7 cache-key refresh and exact environment result

The only submission change is the inert
`org.opencontainers.image.revision=node-opcua-nodeset-merge-r7` OCI label. The
validator-approved first `FROM` line, prompt, test patch, reference patch,
dependency graph, evaluator injection path, and participant test count are
unchanged. The Dockerfile SHA-256 changed from `3a7c65b9b4fb…` to
`c721ed6e31d…`, so a content-keyed platform build must allocate a cache entry
different from failed image `im-Wem…`.

After that change, `scripts/environment_gate.sh` performed a fresh
`docker build --pull --no-cache` from the untouched pinned repository. The image
built successfully and all exact evaluator lanes ran offline as UID/GID 10001:
pristine base 2/2, pristine feature fifteen named failures, reference base 2/2,
and reference feature 15/15. Feature testcase identities match exactly, with no
hook, startup, skip, patch-application, dependency, permission, or image-pull
failure.

This proves the revision 7 evaluator image is locally viable and changes the
Dockerfile-derived cache key. Shipd subsequently allocated the new
`im-fBWE9ZVQywsN5dG9uE5RQA` image, but that image also failed and the UI exposed
no underlying build output. No broad package suite or mutation batch was run
for this metadata-only cache refresh.

## Revision 8 reduced-image result

The previous clean AMD64 image was 636,185,865 bytes. Its build left about 70
MB of disposable root cache and recursively changed every copied workspace
path. Revision 8 assigns copy permissions directly, creates build outputs under
a permissive umask, keeps `/app` writable by an arbitrary UID, and removes only
the root build caches after installation. Prompt, tests, reference patch,
dependency versions, and the accepted first `FROM` line remain unchanged.

A clean `linux/amd64` build at the pinned repository commit passed and produced
a 557,746,557-byte image, 78,439,308 bytes smaller. That image started with
network disabled as UID 10001, reported `x86_64`, allowed writes under `/app`,
resolved the frozen lock to pnpm 11.18.0, and contained the local Mocha binary.

The exact gate then rebuilt revision 8 with `--pull --no-cache` and passed all
four offline UID/GID 10001 lanes: pristine base 2/2, pristine feature fifteen
named failures, reference base 2/2, and reference feature 15/15. Testcase
identities match with no hook, startup, skip, patch-application, dependency, or
permission failure. No full package suite or mutation batch was added.

## Revision 8 platform result and retirement

Shipd allocated the distinct revision-8 image
`im-7NYIPWZIo3cDR19lk9noMD`, proving that the reduced Dockerfile was ingested.
The environment-quality check still failed before tests and again exposed no
underlying Docker output. Together with the earlier distinct failed images
`im-Wemk161Bsqc6RBpdKrljLW` and `im-fBWE9ZVQywsN5dG9uE5RQA`, this rules out a
stale image identity and shows that reducing the clean AMD64 image by
78,439,308 bytes did not repair the platform no-start.

The exact failure remains inside Shipd's image-builder/build-context boundary;
no available evidence identifies a Docker instruction. The problem is retired
as environment-blocked, all platform attempts remain quarantined, and
calibration remains `0/10`.
