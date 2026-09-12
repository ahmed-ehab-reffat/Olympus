# Gap analysis — kapture dependency-closed dataset subset, immutable v8

Verdict: `pass`.

Repository: `naver/kapture @ 8225b77d0657e6a3eb1ffc941d009100b792fb25`.

Version ID: `08aaa4d7231bb1232f0bb29c4c2705ad7442fd0b7e7f4ef4e04f5a46fc9eeac2`.

## Atomic requirement map

| Public obligation | Independently challenged dimensions | Strongest focused coverage |
|---|---|---|
| Both APIs and exact packaging surface | in-memory, directory, callable import, `python -m`, installed wheel | API guard and both CLI nodes |
| Timestamp/sensor/image selection | inclusive and one-sided bounds, conjunction, repeated/unknown/idle/rig IDs, reverse image timestamps | interval, validation, image-seed, CLI nodes |
| All record families and absence | three file-backed, six inline, all absent | interval, saved, sparse nodes |
| Dependency and reconstruction closure | nested rigs, trajectories, three feature families, matches, point compaction/remap | combined, shared-path, image-seed, saved nodes |
| Independent full/filtered models | unused definitions and nested mutable values | deep-independence node |
| Self-contained saved result | return value, reopen, record/feature/match payload reads | mixed-store and empty nodes |
| Producer preservation | ordinary and tar collections mixed independently | mixed-store node |
| Output identity and force lifecycle | normalized alias with force, no-force refusal, direct and CLI force | existing-output and CLI nodes |
| Transactional failure | absent/existing destinations, early record and late reconstruction failures | transactional node |
| Successful ownership-aware replacement | stale record, ordinary feature, match, and tar payload retirement; unrelated root/record/ordinary/tar/match sidecars survive | transactional node |

Absent public collections may be `None` or empty. Order is ignored except for
source-order point compaction. Empty directories and unreferenced paths may
remain; the output is not required to be a minimal tree.

## Exact-version gap trials

The 37 v7 mutants were rebased. IDs 39 and 40 add the two newly public
ownership shortcuts:

| ID | Plausible shortcut | Result |
|---:|---|---|
| 39 | overlay the new subset without removing stale old managed payloads | killed only by the transactional node |
| 40 | preserve the destination root but recursively delete standard record/feature roots | killed only by the transactional node |

The first 39-mutant run exposed one actionable survivor: mutant 21 compared
source/output strings before normalization. With `force=False`, the later
overwrite guard still rejected `source/.`; with `force=True`, the same code
could replace its source. The alias probe now supplies force and verifies an
unchanged source hash. Both complete architectures pass it, pristine still
fails all 13 nodes, and mutant 21 is killed only by the lifecycle node.

The complete final stream contains IDs 1–29, 31, and 32–40. All 39 apply to
their intended complete architecture and all are killed; no focused survivor
remains for base-suite escalation.

## Family and lifecycle audit

- Record families cover every separate public attribute and the all-absent
  state.
- Selector directions cover lower, upper, conjunction, empty, repeated,
  duplicate, known-but-excluded, and unknown states.
- Graph resources cover physical sensors, direct/nested rigs, trajectory
  IDs/times, image relations, matches, point rows, and observation IDs.
- Storage producers cover ordinary arrays, tar arrays, tar matches, and record
  files through public readers.
- Destination lifecycle covers absent/existing success, absent/existing
  failure, no-force refusal, force-enabled normalized identity, exact stale
  managed retirement, and nested unrelated preservation.
- Distribution lifecycle covers the source module, PEP 621 target,
  `python -m`, built wheel, and installed command.

Rejected additions include exact archive bytes/order, empty-directory pruning,
extension-based ownership of unreferenced files, symlink policy beyond ordinary
normalization, arbitrary invalid bytes, private staging names, and timeouts.
Every atomic public requirement has a direct black-box observation across its
independently implemented family or lifecycle branch.

