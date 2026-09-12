# Design — kapture dependency-closed dataset subset

Status: `accepted by the platform and archived 2026-08-19; immutable v8; exact environment, gap, fairness, and false-positive gates pass`.

Repository: `naver/kapture` at
`8225b77d0657e6a3eb1ffc941d009100b792fb25` (`v1.1.12`, 2026-04-17).

Production language: Python. Task type: feature request.

## Public contract and repository evidence

Add an in-memory library operation and a saved-dataset operation for selecting
records by an inclusive timestamp interval, physical sensor identifiers,
camera image identifiers, or their conjunction. The selected model is
independent of the source and is closed over the relationships required to use
it:

- every record family is filtered through the same timestamp/sensor predicate;
- only sensor definitions used by surviving records remain;
- rig membership is followed transitively through nested rigs, and trajectory
  entries remain only at surviving record timestamps for retained sensors or
  their required rig ancestors;
- camera record paths define the retained image identifiers for keypoints,
  descriptors, global features, matches, and reconstruction observations;
- matches remain only when both endpoints survive, while points with at least
  one surviving observation are compacted in source order and observation
  point identifiers are remapped; and
- every retained record/feature/match payload is copied into a self-contained
  output. Each reconstruction collection preserves whether its source payloads
  are ordinary files or one of kapture's supported tar collections.

The ordinary no-filter call is an independent full copy. Reversed timestamp
bounds, unknown physical sensor identifiers, and identical source/output paths
are rejected without mutating the source. Exact error text is not part of the
contract.

Saved materialization is transactional. Successful forced replacement retires
old kapture metadata and payload paths that the new dataset does not own while
preserving non-kapture files at every nesting depth; it does not require a
minimal directory tree or removal of empty directories.

The command packaging is now fully public: PEP 621 `[project.scripts]` must
map `kapture_subset` exactly to
`tools.kapture_subset:subset_command_line`; that callable must exist, and the
same module must run through `python -m tools.kapture_subset`.

This behavior is grounded in the pinned repository rather than a private
reference design:

- `Kapture` exposes nine record attributes, sensors, rigs, trajectories, four
  reconstruction payload families, points, and observations as public model
  members.
- `RecordsBase`, `Rigs`, `Trajectories`, `Matches`, and `Observations` expose the
  public keys that form the dependency graph. Existing trajectory tests include
  nested rigs, so transitive rig ancestry is a supported repository surface.
- `kapture.io.csv.kapture_from_dir` filters dependent tables while loading and
  `kapture_to_dir` is the public round-trip boundary.
- `kapture.io.features` and `kapture.io.tar` define equivalent directory/tar
  readers and writers for keypoints, descriptors, global features, and matches.
- `kapture.io.records` and `kapture.io.binary.TransferAction` define record
  payload transfer behavior.
- `tools/kapture_merge.py` establishes the repository pattern of a library
  operation plus a thin installed command, destination cleanup, tar-aware
  input, and explicit payload transfer.

The contract does not prescribe a selection-plan type, destructive pruning of
a deep copy versus reconstruction, traversal order, one payload job pipeline,
archive member order, exact CSV ordering beyond the existing writers, helper
names, or exact exceptions/messages.

## Trajectory-informed design gate

Searches covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the complete `problems/`, `candidates/`, and
`archive/` histories for kapture, subsetting/filtering, dependency closure,
graph copy, archive-backed payloads, and reconstruction pruning. The exact
kapture repository, all nine fetched remote branches, 922 reachable commits,
40 issues, 16 pull requests, tests, documentation, and tool history were
searched. No kapture subset implementation or exact solver trajectory exists.
Issue 46 is Bundler match export; the linked cropping utility changes image
geometry and is not a general dataset subset.

Relevant compact records were read for ezdxf XREF object collections, h5py VDS
relocation, PcapPlusPlus filtered copy, umoci forward hardlinks, and the accepted
DataSketches persistence task. Representative h5py and PcapPlusPlus raw
trajectories, evaluator results, and patches were inspected directly before
test design.

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Analogical legitimate pass | `problems/h5py-vds-copy-relocation/agent-runs3/Nova_Nova_8` | 24/24 focused and baseline pass | Reconstructed a complete mapping plan before publication and handled relative, absolute, same-file, and live-dataspace producers. This supports model/payload round trips without prescribing an internal copy graph. |
| Analogical near-pass | `problems/h5py-vds-copy-relocation/agent-runs3/Nova_Nova_6` | 22/24 focused; baseline pass | Split work across group and VDS helpers but missed an identity-specific same-file branch. Relationship-family and producer-mode boundaries need independent oracles. |
| Analogical broad failure | `archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz`, `agent-runs4/Nova_Nova_10` | 9/14 focused; baseline pass | A separate 533-line copier handled common blocks but rejected valid multi-section and option-bearing inputs. A broad rewrite does not prove alternate storage producers or trailing relationships. |
| Domain-specific pass / near / broad | unavailable | No kapture solver run exists | The repository model, I/O APIs, and two honest prototypes govern initial fairness and scope. |

Two complete pre-authoring prototypes were then built against one common
black-box probe. Architecture A reconstructs a new model from selection state
and transfers each retained payload through type-aware readers/writers.
Architecture B deep-copies the source, prunes it in place, compacts
reconstruction state, and executes a unified payload-job stream. Both handle
nested rigs and mixed directory/tar sources and leave the source unchanged.

### 2026-08-18 revision startup review

Before revising the harness or hidden test, the local histories in
`problems/README.md`, `candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`,
`problems/`, `candidates/`, and `archive/` were searched again for kapture,
`subset_kapture_from_dir`, saved-operation return values, dataset copying, and
dependency-closed subsetting. No exact kapture solver run, trajectory, or new
calibration evidence exists; the problem remains 0/10.

The current kapture design, gap, fairness, error, and false-positive records
were reread. The representative h5py Nova 8 pass and Nova 6 near-pass raw
trajectories/patches and the archived PcapPlusPlus Nova 10 broad failure were
reinspected. They continue to support independent lifecycle and producer-mode
oracles without prescribing an implementation layout. For this revision, the
decisive repository evidence is more direct: both materially different
kapture implementations save the selected model and return that same public
`Kapture` result, while an otherwise correct writer can plausibly discard it
and return `None`.

The resulting new discriminator is limited to the already-public saved API
contract. The black-box probe will compare the returned model with the model
reopened from the output directory. It does not require object identity, a
private helper, an encoding, or a particular save/copy strategy.

### 2026-08-18 Lyra coverage/fairness revision gate

The local history and exact kapture records were searched again after Lyra's
adversarial audit. There are still no kapture solver trajectories or platform
calibration runs. Lyra supplied stronger exact-version evidence: nine plausible
incorrect implementations each passed the six-node v3 verifier and the
181-test base lane while violating public behavior. The proposed replacement
verifier passed its reference trial.

All nine gaps are admitted, with one fairness correction to the proposed
oracle. They cover absent optional record families; deeply shared mutable
values in a nominal copy; validation of defined-but-recordless physical sensors
and rejection of rig IDs as sensor filters; a camera path shared by surviving
and excluded records; normalized source/output aliases; refusal to replace an
existing output without `force`; actual importability of the declared entry
point; and the required `-i`/`-o` aliases. Existing-output refusal will accept
any ordinary exception and verify an unchanged output tree because the prompt
does not specify `ValueError` for that case.

Lyra also demonstrated one unfair predicate: physical absence of an
unreferenced discarded camera file. The public contract requires every retained
payload and a coherent reopened model, not a minimal output tree. That assertion
is removed rather than adding a new minimality clause. Extra unreferenced files
remain allowed. This correction also removes rejected-file enumeration from the
design oracle below.

### 2026-08-18 S1/T4 solution and API-lifecycle revision gate

Before revising the reference or verifier, the local problem, candidate, and
archive histories were searched again for kapture, no-filter/full-copy
semantics, unused or recordless sensor definitions, direct saved-operation
force replacement, and CLI-only force handling. No domain-specific kapture
solver trajectory or calibration run exists; the previously inspected h5py
legitimate pass/near-pass and PcapPlusPlus broad failure remain the only useful
raw analogical evidence. The current prompt, v4 verifier, both complete
implementations, and mutation ledger were inspected directly.

The S1 finding is a reference blocker. The prompt's explicit no-filter full-copy
clause preserves all source model content, including defined sensors that no
record uses. Both v4 implementations instead always applied dependency pruning;
their existing equality fixture happened to use every sensor. The fair oracle
adds one unused physical sensor to a normal populated model, performs a
no-filter call, checks public model equality, and then retains the existing deep
ownership mutations. The implementation fix may use a deep-copy fast path or
reconstruct every source member; no architecture is prescribed.

The T4 finding is also admitted. CLI force coverage reaches the saved API in the
reference, but a legitimate solver can implement CLI-side cleanup while leaving
the public `force=True` API argument ineffective. A direct saved-API overwrite
of observably distinct existing data therefore crosses a separate public entry
surface. The oracle checks only successful replacement, the returned public
model, and reopened content; it does not prescribe cleanup helpers or staging.
The public description already specifies both behaviors and does not change.

### 2026-08-18 `agent-runs1` calibration and mismatch gate

The complete `agent-runs1` batch was inspected before any further verifier
revision. All ten Nova runs started normally, passed all 181 baseline tests
with the five declared skips, and reached either 9/11 or 10/11 focused tests.
There is no legitimate focused pass and no broad behavioral failure in this
batch. Runs 3 and 8 are representative near-passes; run 6 is the representative
distinct missed-requirement case.

| Evidence role | Run | Result | Architecture, validation, and decisive behavior |
|---|---|---|---|
| Legitimate pass | unavailable | 0/10 exact passes | No run may be counted as a pass because the verifier version is now quarantined for mismatch. |
| Near-pass / legitimate representation | `Nova_Nova_3` | 181/181 base; 10/11 focused; evaluator `FAIL_TEST_MISMATCH` | Reconstructed a new model and returned the publicly reopened saved model; 404 strict additions across `kapture/algo/subset.py`, `pyproject.toml`, and `tools/kapture_subset.py`. It kept `{'SIFT': Matches()}` after every pair was filtered, matching the empty named-match representation exercised in repository `tests/test_tar.py`. Its own ordinary/tar/mixed, CLI, wheel, and full-suite checks all passed. |
| Independent near-pass / legitimate representation | `Nova_Nova_8` | 181/181 base; 10/11 focused; evaluator `FAIL_TEST_MISMATCH` | Reconstructed and returned the pre-save model, with a distinct storage-transfer implementation; 401 strict additions across five files. Its focused check deliberately accepted an empty per-type `Matches`, so the hidden outer-container normalization was not discoverable from its validation. |
| Distinct missed requirement | `Nova_Nova_6` | 181/181 base; 9/11 focused | Deep-copied/pruned state but expanded a selected rig to the unused physical sibling sensor, contradicting the explicit used-sensor rule; 376 strict additions across four files. Its second failure is the same empty-container returned/reopened normalization issue. |
| Broad failure | unavailable | every run reached at least 9/11 | No unrelated low-coverage failure is substituted. |

The raw trajectory schema reports four platform messages for each representative
run, with 32, 45, and 44 embedded tool calls respectively. Tool calls are not
substituted for the platform message metric. The exact evidence hashes are:

- run 3 evaluator / patch / trajectory:
  `8d183b9e2d2a00e87b559b557f28a6579c6db97f417db33d84267fca343dde5c`,
  `57311f449e59e6faba7e5490a728c5f5a4fe2862896ef521807a678e9d88bea2`,
  `550c809874ef275d701daeec83dbccfa2caced5ac8cd9f9ef6812b5d3ea0f625`;
- run 8 evaluator / patch / trajectory:
  `94c3eb74120ad44477047eb868ab4726314e03fa925ee9c269b1686bc22b2977`,
  `d90ca173516f34d8cd21ee81993baaf83bf268c7f04037f66ceed3d49403f262`,
  `c60932772f27bafbc006ba59493eb4cc09071210072fc7391e3704de705975b5`;
- run 6 evaluator / patch / trajectory:
  `044456b5e773f39a948b2255a0b931471d6bda1e2c2471fc1772281051f65c36`,
  `79b18460c8b5f74c30ad04041ba11133efd9092c9fb8d3f0cfd2259065f66f27`,
  `d73ae5ccd6e6c103dd48867e43bc0cb92b9ebc216f6097de6d02252972c7769f`.

Two rejection predicates are quarantined. First, the combined-selection test
requires the outer `matches` mapping itself to be absent or empty. The public
contract requires that no invalid match pair survive and explicitly permits
empty collections; repository `tests/test_tar.py` recognizes a non-`None`
matches mapping containing an empty named `Matches` set. The fair oracle must
therefore flatten public match pairs and require that set to be empty without
prescribing outer normalization.

Second, direct-force coverage compares the returned pre-save model with the
reopened model through strict `equal_kapture`. Public writers/readers normalize
some empty record/feature containers and `equal_kapture` distinguishes those
representations. The saved API must still return a `Kapture` containing the
selected public data, but exact equality across allowed empty representations
is not required. The fair oracle will compare the selected nonempty public
content and reopenability instead.

Removing only those predicates is expected to make nine of these ten historical
patches compatible; run 6 still fails the explicit sibling-sensor invariant.
That 9/10 compatibility estimate implies a fresh 6–9/10 expectation, outside
the accepted band. The mismatch repair is necessary fairness work, not successful
difficulty hardening. Any additional discriminator must be a distinct public
behavior supported by repository branches and must be replayed against these
legitimate near-pass architectures.

The same replay exposed a separate installability gap. The reference and runs
3 and 5 declared the required PEP 621 script but explicitly packaged only
`kapture` and `tools`, omitting the new `kapture.algo.subset` module from their
wheels. A command that works only while the source checkout shadows the wheel
is not the installable command promised by the public task. The fair oracle
builds a wheel offline, installs it without dependencies into an isolated
target, and runs the installed `kapture_subset --help` outside the checkout; it
does not prescribe setuptools discovery or package layout. Fixing the reference
and adding that discriminator is forecast to accept 7/10 historical patches
(runs 3 and 5 fail packaging; run 6 fails dependency closure), with a fresh
5–8/10 expectation. This remains correctness hardening rather than evidence of
accepted difficulty.

The final fairness pass found the same normalization assumption in the
mixed-storage return oracle: it still used whole-model `equal_kapture` even
though the prompt permits absent collections as either `None` or empty. It now
checks the returned public type and retained camera, depth, lidar, match, and
point content directly, alongside the separately reopened result. Mutant 19
still fails both return-value nodes. The exact environment gate, all 31
mutants, and all ten compatibility patches were rerun after this last verifier
change; the 7/10 compatibility outcome was unchanged.

### 2026-08-18 level-7 redesign gate: reverse seeds and transactional commit

The redesign search re-read `problems/README.md`, the candidate and success
catalogs, the current problem's `SUMMARY.md`, `DESIGN.md`, `LEVELS.md`,
`ERRORS.md`, and `RUNS.md`, and searched active/candidate/archive records for
kapture, dependency-closed copies, dataset subsetting, reverse selection, and
transactional directory output. No second kapture task or prior implementation
of these proposed semantics exists. The exact repository pin was restored and
its root model, camera-record identifiers, CSV readers/writers, feature/tar
payload APIs, and `delete_existing_kapture_files` lifecycle were inspected.

Raw `agent-runs1` trajectories and submitted patches were then reviewed. Run 8
is the representative legitimate v6 pass; run 3 is the normalization-legitimate
near-pass with a separate incomplete-wheel defect; run 6 is the distinct
dependency-closure miss. A broad behavioral failure is unavailable: every run
passed all 181 base tests and reached at least 9/11 focused nodes. Their exact
evidence hashes are already recorded above. Run 8 has 401 strict additions,
four platform trajectory steps, and 45 embedded tool calls; run 3 has 404,
four, and 32; run 6 has 376, four, and 44. Embedded tool calls are not treated
as the platform agent-message metric.

All seven v6-compatible patches (runs 1, 2, 4, 7, 8, 9, and 10) independently
converge on the same data flow: first filter record tables by timestamp/sensor,
then derive image and reconstruction closure. Their strict additions range
from 341 to 413. Every directory implementation also mutates lifecycle state
before transfer completion: it deletes existing output data or creates/writes
the destination before all retained record and reconstruction payloads have
been read successfully. Several solvers proactively exercised ordinary/tar
round trips and wheel installation, but none staged a complete result or
tested rollback after a late payload failure.

Level 7 therefore adds two public implementation boundaries rather than more
fixtures for existing rules:

| Observed behavior | Generalized shortcut | New fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|---|
| All compatible solvers begin from record keys and only flow forward to image relations. | Treat every selection seed as a predicate local to record timestamp/sensor keys. | Optional requested camera image identifiers reverse-select their surviving camera occurrences; those occurrences seed the timestamps allowed for every record family, after which ordinary dependency closure applies. | Use repeated image paths, co-timestamped camera/non-camera records, one requested image excluded by another selector, an unknown image, and repeatable CLI image options; inspect only public model keys and reopened payloads. | Reverse selection/dataflow | Accepts indexing, two-pass scans, graph traversal, or reconstruction; it does not prescribe an internal plan or traversal order. |
| Every compatible saved implementation deletes/creates destination data before all retained payload reads succeed. | Treat materialization as an eager destructive copy with no commit boundary. | Saved subsetting is transactional: on any load/save/payload failure an existing destination is byte-for-byte unchanged, while an initially absent destination remains absent; successful forced replacement preserves unrelated destination entries. | Remove a retained ordinary payload and, separately, a late reconstruction payload produced by public writers; call the public API with fresh and pre-existing destinations and compare public tree hashes/existence. | Filesystem commit/failure lifecycle | Failure is induced through valid metadata referencing a missing required payload, not monkeypatching private helpers; staging, preflight, backup/rollback, and other implementations all pass. |

The old-patch compatibility forecast is 0/10 because the public API and CLI gain
an image-seed surface and all seven known saved implementations are eagerly
destructive. The fresh-calibration expectation is 2–5/10: the model operation
remains solvable through a two-pass selection, while transactional mixed-store
materialization requires a new plan/commit architecture. This is a fresh-run
forecast, not a reinterpretation of the abandoned v5 batch. No submission
artifact may change until this gate is recorded; this section completes that
prerequisite.

### 2026-08-18 level-7 exact outcome

The final immutable submission stream has version ID
`65e3a806681c137b8131650140c9ad6b9bf21c6b4bd7e6c1d908cd66f747ae40`.
The no-cache environment gate passes offline as UID/GID 10001: pristine is
181 passed/five skipped plus 0/13 focused, while the reconstruction reference
and independent deep-copy/prune architecture are each 181/five plus 13/13.

The first 37-mutant run exposed one actionable survivor: mutant 32 applied the
image filter only to camera paths. A lower bound in the original fixture had
coincidentally removed the non-camera records that should have been removed by
reverse seeding. A single requested image without a time bound was added; it
passes both complete architectures and fails that shortcut. The exact gate was
restarted. Fairness review then replaced a decoder-specific malformed-byte
failure with a public payload path that cannot be a feature file, accepted any
ordinary exception, and checked only destination rollback. Every exact gate
was restarted again on the final artifacts.

The final false-positive result is 37/37 killed with zero survivors. Gap and
fairness verdicts pass. Historical compatibility was forecast at 0/10 and is
observed at 0/10: runs 1–5 and 7–10 pass 9/13, run 6 passes 8/13, and all ten
still pass the complete base lane. The compatibility forecast is therefore
confirmed. Fresh calibration remains 0/10 until a new exact-version batch is
run; its forecast remains 2–5/10.

### 2026-08-18 level-8 redesign gate: ownership-aware forced replacement

The five-run `agent-runs2` batch invalidates the level-7 fresh forecast at its
hardest edge: all five unhinted runs are legitimate passes, each with 181 base
passes/five skips and 13/13 focused nodes. The exact evaluator, patch, and raw
trajectory records for every run were inspected. Each trajectory contains four
platform steps; no broader agent-message measure is inferred from token usage.
The submitted patches add approximately 431, 448, 475, 493, and 533 nonblank,
non-comment production/configuration lines by a common lexical count, for a
median of 475 across four production/configuration files. This is substantive
work, but the observed 5/5 solve rate is outside the accepted difficulty band.

The startup search re-read `problems/README.md`, the candidate catalogs, the
current problem records, and the active/candidate/archive histories for
managed files, stale payloads, replacement, transactionality, and preservation
of unrelated output entries. The closest compact records are the abandoned
3D Tiles atomic-output design, whose directory publication preserves unrelated
entries, and the rejected pydicom FileSet replacement design, whose generated
publication removes the superseded managed file. Neither defines kapture's
mixed record/feature ownership surface. No second kapture task or exact prior
ownership-aware replacement implementation exists.

The exact repository pin was inspected again. `kapture.io.csv.CSV_FILENAMES`
and `FEATURES_CSV_FILENAMES` identify metadata files;
`kapture.io.records.get_record_fullpath` maps record values to payload paths;
`kapture.io.features` maps feature/image or match identifiers to ordinary
payload paths; and `kapture.io.tar.get_feature_tar_fullpath` maps tar-backed
collections to one archive payload. By contrast,
`kapture.io.structure.delete_existing_kapture_files` recursively removes the
whole standard record and feature roots. That helper is suitable for ordinary
destructive writes, but it cannot satisfy the already-public promise to retain
unrelated files nested inside those roots.

There is no near-pass or broad behavioral failure in `agent-runs2`; substituting
one would misstate the calibration evidence. The representative legitimate
architectures are:

| Evidence role | Run and exact hashes | Architecture and decisive replacement behavior |
|---|---|---|
| Legitimate pass, broad-root cleanup | `Nova_Nova_1`; patch `6860e23b58221f3ef94e1a40423002722b58be4bfc25f494605454223c24212e`, trajectory `10a868264409c66e51b4cb7d47b4b70a3b7f31beeaddeab71c59d45882a2233e`, evaluator `32b55929f0ae781fac89234fc63775c92a54c353f97993dcff520a5bfda0299c` | Copies the pre-existing tree, recursively removes the standard records and four feature roots, overlays the staged subset, then commits with backup/restore. It is transactional but loses unrelated nested entries. Runs 3 and 4 independently use the same generalized shortcut. |
| Legitimate pass, collection cleanup | `Nova_Nova_2`; patch `7393e907c989f1ea3d4388efdd217fc1a59d50e1143729f252dc5e63b7777c9f`, trajectory `0900986c2c04d8e4f0e7438b5c478b1f31598a744d681339dee0e9d27260696b`, evaluator `095f725c0ccb38b856dbc08d2a601a91564e863d8756063b73359fbbf60f7466` | Removes record payloads named by the old record tables, but recursively removes any feature collection directory containing recognizable kapture data. It preserves unrelated top-level entries while losing unrelated files beside an owned collection. |
| Legitimate pass, selective cleanup | `Nova_Nova_5`; patch `fc7aafeae9b7d9d8b7bb0cdf726e7962886a637be0c780669e50405a6f850d10`, trajectory `77e3191f8f90b276e48bd007c72b65dd6478243f957cf78713ba476c6677e1e6`, evaluator `856d6a0d9fbea35d3e8fea8fc0734d724b18264c63e29a79019c2c31524a7bef` | Enumerates old metadata, referenced record payloads, and repository-recognized ordinary/tar feature payload names, deletes those files from a copied tree, overlays the new subset, and commits transactionally. It is the one compatibility architecture predicted to satisfy exact nested preservation and stale cleanup. |
| Near-pass / broad failure | unavailable | All five runs legitimately pass every v7 public test; no failing run is manufactured for this category. |

The reviewer findings expose two sides of one ownership boundary. The v7
verifier proves successful replacement only with a root sentinel and checks
new metadata, so a whole-subtree deletion and a stale-payload-preserving overlay
both pass. The v7 reference itself uses whole-root cleanup and therefore
violates the nested-preservation reading of its public clause. Level 8 makes
the ownership rule explicit instead of adding an unstated minimal-tree test:

| Observed behavior | Generalized shortcut | New fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|---|
| Four of five successful solvers recursively remove a whole records root or feature collection; the reference does likewise. | Treat a standard directory as wholly owned once any kapture entry appears beneath it. | A forced replacement preserves every pre-existing non-kapture file at any nesting depth, including files beside record and feature payloads. | Place byte-distinct sentinels inside the standard records root and inside ordinary and tar-backed feature collection directories, replace through the public saved API, and compare their paths/bytes. | Path-level ownership within shared directories | Copy-overlay, explicit ownership sets, selective pruning, manifests derived from public readers, and any equivalent implementation pass; no private helper or directory layout beyond repository conventions is required. |
| V7 checks replacement metadata but never the old payload namespace. | Overlay the new subset while leaving old referenced payload files behind. | Successful forced replacement removes old kapture metadata and payload files that are not owned by the new dataset, while allowing unrelated files and empty directories to remain. | Seed the destination through public writers with record, ordinary-feature, match, and tar payloads absent from the replacement; after force, assert those exact old managed paths are absent and reopen/read the new subset. | Managed-resource retirement on successful commit | The old managed paths come from public model identifiers and path helpers. The oracle does not require a minimal tree, extension-based sweeping, empty-directory removal, archive byte identity, or one cleanup algorithm. |

The public CLI paragraph will also lose its redundant introductory deliverable
sentence; its exact PEP 621 mapping, callable, and module execution requirements
remain unchanged. This is clarity-only and contributes no discriminator.

Compatibility replay is forecast at 1/5: run 5 already performs path-selective
cleanup, while runs 1–4 delete a whole standard subtree or feature collection
and should fail nested-sentinel preservation. The fresh-calibration expectation
is 2–4/10. That forecast is based on the observed five-solver convergence plus
the repository's split ownership APIs; it is a fresh exact-version expectation,
not a claim that compatibility replay is fresh calibration. The accepted band
would therefore be restored if the exact replay and all mandatory gates confirm
the design. No `test.patch` change began before this gate was recorded.

### 2026-08-18 level-8 exact outcome

The immutable submission version is
`08aaa4d7231bb1232f0bb29c4c2705ad7442fd0b7e7f4ef4e04f5a46fc9eeac2`.
The final no-cache environment gate passes offline as UID/GID 10001: pristine
is 181 passed/five skipped plus 0/13 focused; both complete architectures are
181/five plus 13/13 with matching JUnit identities.

The first v8 mutation stream killed the two new ownership shortcuts but exposed
mutant 21: a raw-string same-path check still raised for `source/.` only because
the later no-force overwrite guard masked it. The public alias probe now uses
`force=True` and confirms the source hash is unchanged. All submission artifacts
were invalidated, the environment gate restarted, and the complete final stream
then killed all 39 mutants with zero survivors. Exact gap and fairness verdicts
pass.

Compatibility was forecast at 1/5 and is observed at 1/5. Runs 1–4 pass 12/13
and fail only nested unrelated preservation; run 5 passes 13/13; every run
passes 181 base tests with five skips. The compatibility forecast is therefore
confirmed. Fresh v8 calibration remains 0/10 until a new exact-version batch is
run; its expectation remains 2–4/10.

## Discriminator ledger

| Observed solver/repository behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| h5py near-pass missed one identity-specific mapping branch. | Filter only top-level record maps. | Every surviving record has exactly its physical sensor and transitive rig/trajectory dependencies. | Select one member of a nested rig and reopen the saved result; every reference resolves and unrelated siblings are absent. | Core relationship closure | Reconstruction, deep-copy pruning, reachability, and staged-plan implementations all pass. |
| Kapture owns nine independently loaded record attributes. | Handle camera records only, or apply time and sensor predicates inconsistently. | The same inclusive predicate covers every present record family. | Mix file-backed and inline record types at both interval endpoints and across selected/unselected sensors. | Record family / selection dimensions | Each family has a separate loader/writer branch; this is not fixture symmetry. |
| H5py and ezdxf histories show direct selection can omit reachable resources. | Copy retained image files but omit derived payload metadata/data. | Retained camera image identifiers close over every present feature family. | Reopen and read retained arrays for keypoints, descriptors, and global features while checking model references. | Metadata-to-payload reachability | Accepts eager copying, lazy jobs, decoded transfer, raw file copying, and extra unreferenced files. |
| PcapPlusPlus broad failures preserved the common producer but rejected another. | Support ordinary feature directories only, or convert all collections through one assumed store. | Directory and tar-backed feature collections have identical semantics, preserving each collection's producer mode. | Use mixed directory/tar collections in one source and compare reopened models and arrays. | Storage producer modes | Uses public tar handlers and does not pin archive member order or bytes. |
| Graph-copy histories commonly leave dangling or overretained edges. | Keep matches with one endpoint, leave removed-only observations, or fail to remap point rows. | All match endpoints exist; points are source-order compacted exactly when an observation survives. | Crossing matches plus shared and removed-only points, followed by CSV save/reopen. | Reconstruction edge lifecycle | Tests public identifiers/arrays, not the compaction algorithm. |
| Copy operations can prune the source while building output. | Mutate the input model or source files, or alias nested values into the result. | The source model/tree remains unchanged and returned objects are independent. | Compare a deep snapshot and tree hashes, mutate the result, then create a second different subset. | Ownership/isolation | Deep copy, reconstruction, and copy-on-write approaches pass. |
| The saved API is specified to save and return its self-contained subset, but disk-only implementations can discard the result. | Produce correct output files and return `None` or another model. | The saved operation returns a public `Kapture` model equivalent to the dataset it just saved. | Capture the return value, reopen the output, and compare both through public model equality. | Saved-operation return lifecycle | Accepts any internal save/copy architecture and does not require object identity. |
| Lyra demonstrated a copy that reallocates top-level containers but shares mutable sensor, pose, inline-record, point, or feature values. | Treat equality plus one immutable string reassignment as proof of independence. | Every result is independent at mutable public model surfaces; a no-filter result also preserves the complete model. | Compare a no-filter result containing an idle definition, then mutate representative nested values in full and filtered results and verify the source remains unchanged. | Full-copy identity and deep ownership | Accepts deep-copy, reconstruction, and copy-on-write implementations that actually detach on mutation. |
| Lyra demonstrated validation against used record IDs instead of sensor definitions, and acceptance of a rig namespace ID. | Conflate defined, used, physical-sensor, and rig identifiers. | Any defined physical sensor is valid even when recordless; non-physical rig IDs are invalid filters. | Select a defined idle sensor for an empty result and reject a known rig ID. | Identifier namespace/validation | Uses only public sensor and rig definitions; no private type tag is required. |
| Lyra demonstrated exact-string path comparison and unconditional existing-output replacement. | Validate path/lifecycle only for the happy quadrant. | Aliases of the same location are identical, and replacement requires `force`. | Use `source/.`; separately decline an unforced overwrite of distinct data and verify the output is unchanged. | Filesystem identity/output lifecycle | Does not prescribe normalization internals, return-versus-exception behavior, prompt interaction, or exception class. |
| Lyra demonstrated a working module with a missing declared callable and a long-options-only parser. | Test related CLI surfaces without invoking the exact promised one. | The PEP 621 target imports as a callable and both required path aliases work. | Import the target attribute and execute one subset through `-i`/`-o`. | Packaging/CLI interface | Parser library, wrapper structure, and console-script installation mechanics remain free. |
| Lyra demonstrated occurrence-based image pruning when one path appears in both excluded and surviving camera records. | Let an excluded occurrence negate a surviving identifier. | Surviving image identifiers are the set of paths in surviving camera records. | Reuse one path across included/excluded records and validate feature/reconstruction closure from the surviving set. | Identifier-set reachability | Tests public path identity, not traversal order or deduplication strategy. |
| S1 review showed both complete implementations prune unused definitions even on an explicit no-filter full copy. | Reuse the filtered dependency-closure path when no selection predicate exists. | A no-filter call preserves the entire public source model while remaining independent. | Add an unused sensor definition, call without filters, compare public model equality, then mutate nested result values. | No-filter identity versus filtered closure | Accepts a deep-copy fast path, complete reconstruction, or detached copy-on-write; only public equality/ownership is observed. |
| T4 review showed forced replacement is exercised only through the command wrapper. | Implement forced cleanup in the CLI while ignoring the saved API's `force` parameter. | `subset_kapture_from_dir(..., force=True)` directly authorizes replacement and returns the saved subset. | Seed distinct output, invoke the library API directly with force and a different selection, then compare return and reopened content. | Library versus CLI lifecycle surface | Does not prescribe where cleanup occurs or how overwrite is staged; both public entry surfaces may share or separate code. |
| Agent-runs 3 and 5 declare the script target but omit its imported algorithm module from the built wheel. | Rely on the repository checkout shadowing an incomplete installed distribution. | Installing the project provides a working `kapture_subset` command and its complete import closure. | Build offline, install the wheel without dependencies into an isolated target, and execute the installed command outside the checkout. | Installed-distribution dependency closure | Observes only the promised command; package discovery, explicit package lists, and build backend configuration remain free. |

## Clause-to-test coverage

| Public requirement | Planned observable test | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Public in-memory and saved operations plus command | Import/call both APIs and invoke the tool over a temporary dataset | module/command absent | exact selected model saved and reopened | existing `kapture.algo` plus installed `tools/kapture_merge.py` pattern |
| Inclusive timestamp and physical-sensor selection | Lower/upper endpoints, time-only, sensor-only, combined, no-filter, and empty result | API absent | exact record keys across all families | public timestamp/sensor record keys |
| Transitive sensor/rig/trajectory closure | Nested rig with selected member and unrelated sibling | API absent | required ancestors/poses retained, sibling removed | nested-rig tests and public rig/trajectory model |
| Feature and relation closure | Partial per-family image coverage, crossing matches, shared points | API absent | no dangling image/point reference and source-order point remap | public feature/match/observation structures |
| Directory/tar payload equivalence | One source mixing stores per collection | API absent | arrays reopen through corresponding public handlers | existing `features` and `tar` readers/writers |
| Self-contained output, saved return, and source isolation | Read every retained payload, compare the returned model with the reopened output, hash source, mutate nested result values | API absent | returned/output models agree; output independent; source byte/model identity unchanged | explicit saved return plus independent model semantics and existing transfer utilities |
| Ownership-aware forced replacement | Record, ordinary feature, match, and tar stale paths plus unrelated files nested beside each producer | API absent | exact old managed paths retired; unrelated paths/bytes preserved; new result reopens | public metadata/payload path maps and explicit replacement clause |
| Sparse/namespace/path/CLI edge behavior | Empty optional families; idle physical sensor and rig ID; duplicate image path; `source/.`; declined overwrite; callable import; `-i`/`-o` | API absent | all public edge cases pass in both complete architectures | prompt's physical-sensor, path, independence, image-set, and exact interface clauses |

## Environment and harness preflight

- Host Docker 29.2.1 on ARM64 was healthy with 243,981,268 KiB available.
- The approved base resolved to
  `public.ecr.aws/d3j8x8q7/olympus-base-python@sha256:6ddc78fc675e6cd3a63b60fc63d87eea35a479f503a44a89cf92923abe905dd8`.
- The untouched no-cache build produced image
  `sha256:48ea413e0b37359089eec58292700e3f6ebd90e8ad8a960f068e99ebe5d090f0`.
- A direct read-only-source run was quarantined: 184 tests passed, five
  repository-declared ROS tests skipped, and two COLMAP tests failed before
  behavior because a tracked WAL-mode SQLite fixture requires a writable
  companion-file directory. This is an environment constraint, not a test or
  solution result.
- The evaluator-shaped harness copies the immutable mounted tree into an
  unprivileged temporary work tree before execution. Offline as UID/GID 10001,
  the documented `python -m unittest discover -s tests` path then passed all
  186 discovered tests with the same five declared ROS skips in 1.562 seconds.
- Prototype A passed the two common focused scenarios and 188/188 combined
  tests; prototype B passed the same focused scenarios and all 186 pre-existing
  tests. Both ran offline as UID/GID 10001 from read-only injected source copies.

This Phase A verdict authorizes prototyping and hidden-test authoring. It does
not replace exact Phase B after all four submission artifacts exist.

## Design verdict

Approve promotion and hidden-test authoring. The two complete architectures
remain materially above the 200-effective-line forecast and cross three
production files:

| Trial | Architecture | Production diff | Strict nonblank/noncomment additions | Full result |
|---|---|---:|---:|---:|
| A | reconstruct selected model; per-family payload transfer | 298 additions across 3 files | 253 | 181/181 base, 11/11 final focused, five skips |
| B | deep-copy/prune; unified payload-job stream | 317 additions across 3 files | 267 | 181/181 base, 11/11 final focused, five skips |

The final implementation patch hashes are
`c0fd070b00ea05ed9a2dad071d69f3efd0a52e42468176616457a705fd9e82ed`
and
`4c66c15429381839bb87186596526413acc6c789ed945e359bea3b545942be6a`.
These are prototypes, not successful platform-solver measurements, so the
long-horizon verdict remains provisional. The active runner-up is MaterialX
inheritance flattening at 9/10, but it has no Phase A or complete prototype;
kapture now wins on measured viability and independent implementation depth.
The former higher-ranked DataSketches candidate is already accepted and closed.

The corrected immutable v6 version is
`f3ff1fcbf0a9174956337aa2d0aeb2bb4b6e0af319368e8623860a403049e5d5`.
Exact Phase B passes pristine/reference/architecture-B/run-8 composition; all
31 attempted plausible mutants are killed; exact gap and fairness verdicts
pass. Mismatch-only compatibility was forecast and observed at 9/10; final
installed-distribution compatibility was forecast and observed at 7/10. The
fresh-calibration expectation is 5–8/10, so this is not submission-ready and
fresh calibration remains 0/10.

Do not pad the task with archive atomicity, byte-identical tar ordering,
arbitrary malformed payloads, image cropping, geometry changes, or private path
layout. Any future submission-artifact change invalidates every downstream
verdict and restarts calibration.
