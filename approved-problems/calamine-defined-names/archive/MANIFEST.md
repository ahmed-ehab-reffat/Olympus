# Calamine structured defined names archive

The platform accepted this problem on 2026-08-01. Canonical submission and
compact design records remain in `problems/calamine-defined-names/`; this
directory holds bulky solver evidence removed from the active problem folder.

## Raw solver evidence

- Archive: `agent-runs.tar.gz`
- Original collections: `agent-runs1`, `agent-runs2`, `agent-runs3`,
  `agent-runs4`, `agents-run5`, and `agent-runs6`
- Original uploaded bundles: `agent-runsUNO.zip`, `agent-runs4.zip`, and
  `agent-runs6.zip`
- Run directories: 34, of which 33 have completed evaluations and one is
  incomplete
- Archive members: 309 total, including 269 files
- Exclusions: three disposable `.DS_Store` files
- Compressed size: approximately 8.3 MB
- SHA-256:
  `e3378555230ba7cf2ce2b1f2a73c0dfaebff8bb8d6ae37704c82c7ec19f9cc68`
- Ordered member-list SHA-256:
  `a93e582f43bc813430726160de1191316bc163f99a548103094e97b43a90c361`

The original ZIP bundles are retained inside the archive because their uploaded
member sets are not identical to every readable directory snapshot. The tarball
was checked with `gzip -t`, and its 269 file members were compared exactly with
the readable source inventory before cleanup.

Restore from the Olympus workspace root with:

```sh
tar -xzf archive/calamine-defined-names/agent-runs.tar.gz \
  -C problems/calamine-defined-names
```

The compact interpretation remains in
`problems/calamine-defined-names/RUNS.md`; restoring raw material is unnecessary
for ordinary problem selection or review.

## Retired authoring record

`retired-artifacts.tar.gz` contains the acceptance-time `CONTEST.md`. Its
arguments about inaccessible Microsoft specifications and the distinction
between input-format facts and parser architecture are consolidated in the live
`DESIGN.md`, `ERRORS.md`, and `RUNS.md` records.

- SHA-256:
  `46b1fba5e4bc83ac3adc1e402fa3b401dbb1f8977ce84505317ff5888241921d`
- Compressed size: approximately 4 KB
- Integrity check: `gzip -t
  archive/calamine-defined-names/retired-artifacts.tar.gz`

Restore with:

```sh
tar -xzf archive/calamine-defined-names/retired-artifacts.tar.gz \
  -C problems/calamine-defined-names
```

## Prototype and authoring recovery

The 1.4 GB disposable audit namespace contained a clean pinned checkout, two
distinct prototype worktrees, fixture-generation tools, repeated authoring
outputs, false-positive probes, and a final package checkout whose accepted
state is already reconstructible from the canonical patches. The unique small
artifacts were preserved before retiring that namespace:

| Artifact | Contents | SHA-256 |
|---|---|---|
| `prototype-owned.patch` | Owned structured-record prototype tracked diff | `6a261608f7838ce9457a01a88976f9d60afc9701841aa8d255df3f42fe192f0c` |
| `prototype-owned-untracked.tar.gz` | Prototype example, focused test, and four binary fixtures | `5671b9de0973a7df1fa3128ed2e0506855d80a2cddeb6d945ca659703abafce8` |
| `prototype-sidecar.patch` | Tuple-plus-sidecar prototype tracked diff | `903d1f58b46350f6e50fcfee9be62d5f58d877ea88c8a4856097e665881e3e76` |
| `prototype-sidecar-untracked.tar.gz` | Sidecar inspection example | `0f310b42e9d8b4e18c9809c0edd0530498d3498bf34a54e7c8cfe5a50bf6027e` |
| `authoring-tools.tar.gz` | Fixture generators, false-positive probes, four deterministic fixture runs, and four XLS conversions | `cd5b17cd6f77ad825d2f54164da8fc2a0fbb50452f3af3024f0e2fe6b6760fe1` |

Both prototype patches pass `git apply --check` against the pinned commit. All
three recovery tarballs pass `gzip -t` and list successfully. Generated build
trees, duplicate clean checkouts, and the reconstructible final package are not
archived.

To recover a prototype, check out the pinned commit, apply its patch, then
extract the corresponding untracked tarball at the checkout root. Extract
`authoring-tools.tar.gz` into a separate scratch directory when regenerating or
inspecting fixtures.

## Canonical accepted artifacts

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `c66206a43a9525461e72ed326dd517251cfe74338c4de366dd0005b2688f6ee2` |
| `test.patch` | `5b25619b1c81e835be5eaa17fe758e0d99ea04b76328925b8e68aaf14a8deb78` |
| `solution.patch` | `626d8c458d5818ec7f0ed5ffb74f44c759b22fd74ee70ab72993bb8f5e12508b` |
| `solution_approach.md` | `3f2a6234e5d188612a0addca0d3ce4fd41cfa0b020c078125f0db434871b0fcb` |
| `Dockerfile` | `e9de487abfc5f756639fab5e6ef1fc00cb5e7cbbccdbe1dc347c60fdecbd13b9` |

Acceptance freezes these identities. The post-acceptance closeout changes only
compact status/history records and evidence placement, not the submission
artifacts.

## Cleanup result

After every archive and patch-recovery check passed, the following live copies
were moved to macOS Trash rather than permanently erased:

- the six raw run collections and three uploaded ZIP bundles;
- the superseded live `CONTEST.md`;
- disposable `.DS_Store` metadata; and
- the 1.4 GB `work/calamine-defined-names-audit/` namespace.

The active problem folder fell from roughly 39 MB of submission and run
material to about 304 KB of canonical and compact records. Cold evidence and
prototype recovery plus the explicit cleanup inventory occupy about 10 MB under
this archive directory. The Trash
copies remain recoverable until the user empties Trash; the archive is the
durable recovery path afterward.

Post-acceptance registry cleanup also moved the eight preliminary screening
records from `candidates/calamine-defined-names/` to `candidate-records/`.
Their content hashes are unchanged. They preserve the original size-risk
assessment and promotion plan without leaving an accepted problem in the active
candidate namespace; `problems/calamine-defined-names/` remains canonical.

`cleanup-moved-files.txt` explicitly lists all 12,211 files and symbolic links
moved out of the workspace, including generated build output that was not
appropriate for a durable recovery archive. Its SHA-256 is
`3a4bd32a8e86c142b9149a62a1d1ef9b34d6e0ae0b50dc9500602346311c0373`.
