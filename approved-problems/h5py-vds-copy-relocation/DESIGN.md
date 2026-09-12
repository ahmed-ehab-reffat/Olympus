# DESIGN - h5py VDS reconstruction and relocation

Status: `material redesign locally verified; 41-entity exact false-positive
audit complete; uncalibrated at 0/10`.

Repository: `h5py/h5py` at
`2412db7ab71c52f3937e8cf6b966cbb189b7c2b3`.

Primary language and license: Python / BSD-3-Clause.

Task type: `enhancement`.

## Public contract and repository evidence

The current contract adds `VirtualLayout.from_dataset(dataset)` to reconstruct
a reopened VDS as an independent, reusable, normally extendable layout, plus
`VirtualLayout.relocated(filename, *, source_filename=None)` to return an
independent target-specific layout without changing any mapping's source-file
identity. Layouts constructed without a known target require an explicit old
resolution base. Explicit source selections remain metadata-only; every
whole-source mapping reads its own current named dataset space.

`Group.copy(..., relocate_vds=True)` is a separate consumer of those semantics.
It remains limited to a direct VDS, rejects `expand_refs=True`, and publishes
only after reconstruction and attribute copying succeed. The false default
retains native behavior.

Repository evidence:

- `Group.copy()` currently normalizes object and path forms, composes native
  `H5Ocopy` flags, and delegates publication to `h5o.copy()`.
- its established contract already preserves ordinary dataset metadata and
  attributes, honors existing copy flags, and retains native behavior when a
  new opt-in option is not selected. These inherited semantics remain
  repository compatibility checks rather than repeated prompt requirements;
- `Dataset.virtual_sources()` exposes every stored mapping filename, dataset
  name, virtual dataspace, and source dataspace.
- the dataset creation APIs accept those spaces directly, including unlimited
  regular hyperslabs;
- after reopening a VDS, HDF5 represents an all-source mapping with a scalar
  `SEL_ALL` sentinel and no recoverable rank or extent. Recreating that mapping
  requires the current source dataset dataspace, while explicit selections
  remain self-describing;
- HDF5 resolves relative VDS source filenames from the directory containing
  the VDS file, so native cross-directory object copy can select a different
  source without changing the stored mapping string; and
- h5py deliberately stores `.` for a same-file source so a renamed VDS file
  continues to refer to itself. Upstream review of PR #1622 explicitly
  identified copy-to-another-file as the boundary where the original filename
  may instead be required.

Recursive relocation remains out of scope. If a copied group contains both a
VDS and the dataset named by `.`, repository and upstream evidence do not choose
between following the recursively copied dataset and preserving the original
file. Hidden tests may not impose either policy.

## Trajectory-informed design gate

Searches covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, every candidate/problem/archive compact record
matching h5py, HDF5, VDS, virtual dataset, object copy, relative path, and
relocation, plus the complete records for the closest accepted copy-and-rewrite
problem, `pcapplusplus-pcapng-filtered-copy`. No h5py solver run, prior h5py
problem, or VDS-copy trajectory exists locally. The only unrelated h5py hit is
an OpenPNM harness dependency.

The PcapPlusPlus archive manifest, `DESIGN.md`, `SUMMARY.md`, `LEVELS.md`, and
`RUNS.md` were read. The raw evaluation, run metadata, solution patch inventory,
and stored trajectory material for the following `agent-runs4` members were
inspected directly from
`archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz`:

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | PcapPlusPlus `agent-runs4/Nova_Nova_6` | 69/69 base, 14/14 L5, 16/16 L6 replay | A substantive raw-block implementation coordinated section byte order, per-section interface state, BPF filtering, framing validation, finite-length repair, and staged replacement. It delayed packet-option validation until after packet selection. |
| Near-pass | PcapPlusPlus `agent-runs4/Nova_Nova_1` | 69/69 base, 14/14 L5, 15/16 L6 replay | A separate streaming input and temporary-output architecture validated malformed option bytes in a packet that its filter discarded. |
| Broad failure | PcapPlusPlus `agent-runs4/Nova_Nova_3` | 69/69 base, 10/14 L5, 11/16 L6 replay | A third raw-copy implementation handled the central format path but rejected valid option-bearing Decryption Secrets Blocks and missed other section/metadata boundaries. |

The comparison shows why an accepted copy task needs independent public state,
validation, and publication boundaries, not many fixtures around one pathname
formula. It does not establish h5py difficulty. The h5py candidate's complete
prototype measured only 57 strict production additions in one file, so Level 1
is an explicit experiment: freeze the honest direct-VDS contract and let solver
calibration, rather than padding or ambiguous recursive behavior, decide whether
the task can clear the current horizon.

The h5py repository itself supplies the relevant raw behavior. Native copy was
probed with source and destination trees containing different sentinel datasets
at the same relative mapping name; the copied VDS selected the destination-side
decoy. A separate `.` mapping likewise switched from the source-file dataset to
the destination-file dataset. Both are observable source-identity defects.

### Review-driven revision gate - 2026-08-07

Before revising the public prompt or hidden tests, `PROBLEM_DESIGN.md` and the
current h5py candidate/problem records were reread. Searches of
`problems/README.md`, `candidates/CANDIDATES.md`, and
`candidates/SUCCESSES.md` again found no h5py or VDS-copy solver history. The
accepted PcapPlusPlus copy problem's compact records and the raw
`agent-runs4/Nova_Nova_6`, `Nova_Nova_1`, and `Nova_Nova_3` evaluations,
metadata, trajectories, and patch inventories were re-inspected as the
representative pass, near-pass, and broad-failure evidence. They continue to
support independent source-identity, source-extent, scope-validation, and safe
publication boundaries; they do not support restating inherited API forms or
ordinary copy preservation as new requirements.

External review correctly identified four public clauses as redundant with the
existing `Group.copy()` contract: accepted source/destination forms, the
ordinary metadata-preservation list, `without_attrs`, and default native copy
behavior. Removing those clauses changes no reference behavior or hidden
oracle. The named-datatype rejection remains an explicit direct-VDS scope
boundary. Repository object classification makes a committed datatype a
plausible sibling input to groups and datasets, while the prior hidden suite did
not exercise it. One no-publication probe is therefore added to the existing
scope family instead of inventing a new discriminator.

### Editable-install environment revision - 2026-08-07

Before changing the Dockerfile, `PROBLEM_DESIGN.md`, the h5py compact records,
and local trajectory locations were searched again. No h5py raw or compact
solver run is available. External review supplied one concrete solver symptom:
an agent spent turns reconciling repository-root and installed-package pytest
entry points and symlinked site-packages over `/app`. The prior image compiled
extensions in place but did not install the project; a repository-root import
resolved `/app/h5py`, while the same import from `/tmp` failed.

The environment correction is an editable project install after all pinned
build dependencies are present. It makes both `pytest` and
`python -m pytest` resolve live `/app` edits from any working directory. This
changes no participant requirement, reference behavior, hidden oracle, or
discriminator. The build-critical Debian packages are pinned to the versions
resolved in the official base. Because the Dockerfile is a submission artifact,
the image build, patch-state matrix, complete suite, and then-active 16-mutant audit must be
restarted for the new immutable hash.

### Adversarial-review revision gate - 2026-08-07

Before revising `test.patch`, `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread. Searches again covered
`problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the h5py candidate/problem compact records, every
local `actual_trajectories/` and `estimate_trajectories/` directory, and archive
manifests matching h5py, HDF5, VDS, virtual dataset, copy, and relocation. No
h5py solver trajectory, legitimate pass, near-pass, or broad failure exists
locally. The previously inspected PcapPlusPlus pass, near-pass, and broad
failure remain the closest raw copy-and-rewrite trajectories, but they are not
used as evidence for h5py-specific same-file behavior.

External adversarial review supplied stronger h5py-specific black-box evidence.
Three plausible incorrect implementations passed the complete prior focused
and selected-base verifier: one relocated every cross-file VDS when the option
was omitted, one placed all relocation validation under a cross-file-only
branch, and one rejected every same-file relocation. These shortcuts correspond
to three distinct public/repository boundaries: an opt-in false default must
actually gate relocation; direct-VDS and `expand_refs` validation does not
depend on file identity; and an otherwise valid direct VDS remains accepted by
the established same-file `Group.copy()` API. The reported probes are retained
as external reviewer evidence rather than represented as local solver
trajectories.

The same review found three unfair exception-class whitelists. Neither the
prompt nor existing `Group.copy()` behavior promises `(OSError, ValueError)`
for an unreadable all-source mapping or `(TypeError, ValueError)` for scope and
option rejection. The revised oracle therefore accepts any ordinary exception
and continues to assert only the public failure and atomic non-publication
behavior. Exception messages and concrete classes remain unconstrained.

The planned additions are one omitted-option source-identity probe, three
parameterized same-file object-scope entities, one same-file `expand_refs`
entity, and one successful same-file direct-VDS entity. They reuse the smallest
fixtures needed to distinguish the three demonstrated shortcuts. They do not
add private helper, call-order, exception-message, or concrete exception-class
requirements. Because this changes the hidden test artifact, the immutable
version resets to 0/10 and requires a fresh patch-state matrix, complete-suite
run, and false-positive audit.

### Wrapper-compliance revision gate - 2026-08-07

Before revising `test.patch`, `PROBLEM_DESIGN.md` and the current h5py compact
records were reread. Searches again covered the repository/candidate indexes,
every local trajectory directory, and archive names matching h5py, HDF5, VDS,
copy, and relocation. No h5py solver pass, near-pass, broad failure, or archived
trajectory exists. The latest wrapper report is therefore external harness
evidence, not a solver trajectory.

The omitted-option source-identity entity correctly distinguishes an
implementation that implicitly relocates every cross-file VDS, but pristine
upstream also satisfies the legacy behavior because it has no new option at
all. The wrapper requires every focused entity to fail, error, or skip without
`solution.patch`. The fair correction is to assert the public
`relocate_vds=False` parameter exists before exercising the call with that
parameter omitted. This retains the behavioral discriminator: an implementation
that merely adds the parameter but relocates implicitly still reaches and fails
the source-identity assertions. It adds no private implementation or exception
requirement and reuses the same public-signature guard already present in the
rejection entities.

This is a one-line harness correction, not a new behavioral family. It changes
the exact `test.patch` identity, so the test-only wrapper, both patch orders,
complete suite, positive control, and 19-mutant false-positive audit must be
replayed for the revised immutable version.

### Five-run trajectory and completeness revision gate - 2026-08-08

Before revising `test.patch`, `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread. Searches covered the repository and
candidate indexes, all h5py compact records, local trajectory locations, and
the newly supplied `agent-runs1/` bundle. Every `eval-result.json`, `run.txt`,
test log, solution patch, workspace diff, and raw ATIF trajectory was inspected.
This is the first local h5py solver evidence. The bundle contains one legitimate
pass and four near-passes; a broad failure is unavailable.

| Evidence role | Run | Exact predecessor result | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | `Nova_Nova_2`, `rd7bxgx9rb2ksxhkwq6f6p1xn18c26fk` | 138/138 selected baseline, 18/18 focused | One production file, `h5py/_hl/group.py`, with 169 raw additions and 2 deletions, plus docs and tests. It enumerated every DCPL mapping, classified each filename independently, opened the mapped dataset for `SEL_ALL`, collected mappings before anonymous creation, copied attributes through low-level types, and published last. Its raw trajectory also proactively copied a zero-mapping VDS successfully. The platform agent-message count is unavailable in the compact ATIF schema; tool calls are not substituted for it. |
| Near-pass | `Nova_Nova_1`, `rd7fffzraqhb1xvz4zec86skhn8c3kyt` | 138/138 baseline, 17/18 focused | One production file with 111 raw additions and 4 deletions, plus docs and VDS tests. Its otherwise complete custom reconstruction rewrote `.` even when source and destination were the same file. |
| Recurring near-pass | `Nova_Nova_3`, `Nova_Nova_4`, `Nova_Nova_5` | each 138/138 baseline and 17/18 focused | Three independent one-production-file reconstructions made the same file-identity mistake, storing an absolute or basename spelling instead of retaining `.` for a same-file copy. Their production additions were 135, 168, and 174 respectively. |
| Broad failure | unavailable | - | No supplied h5py run failed more than the same-file direct-VDS entity. |

The recurring same-file miss validates the existing accepted-domain oracle but
does not justify multiplying same-file fixtures. The successful architecture is
not a false positive merely because a completeness reviewer produced six
plausible mutants. Each proposed probe must still trace to a separate public or
repository-supported boundary:

- the signature spells `relocate_vds=False`, so the parameter's default object
  must be exactly `False`, not merely present;
- the prompt applies rebasing to every ordinary relative source filename, and
  DCPL mappings are independent records, so rebasing only the first relative
  mapping violates source identity;
- explicit selections do not require source I/O regardless of whether their
  filename takes the relative or absolute path-classification branch;
- “current dataspace” is not satisfied by the originally declared extent or by
  a flattened virtual point count; a changed live extent must be observed
  before publication;
- opening only the source file is insufficient to read the current dataspace;
  the named source dataset must exist and open successfully; and
- repository VDS APIs and the existing `test_no_mappings` case establish that a
  zero-mapping dataset still has virtual layout and remains a valid direct VDS.

These are six distinct API-default, mapping-iteration, path/selection,
live-extent, dataset-open, and source-classification boundaries. The proposed
fixtures are black-box and constrain no helper, concrete exception class, or
message. The prompt and reference behavior need no change. The revised test
artifact invalidates the predecessor 1/5 calibration batch and restarts the
current version at 0/10; cold solvers are explicitly excluded from this local
verification request.

### Ten-run calibration and second completeness revision gate - 2026-08-08

Before revising `test.patch` again, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the h5py compact records, repository/candidate
indexes, and the complete supplied `agent-runs3/` bundle were read. All ten
evaluations, test logs, solution patches, workspace diffs, and raw ATIF
trajectories were inspected. The exact 24-entity version completed ten runs:
two legitimate passes, seven 23/24 near-passes, and one 22/24 broadest
near-pass. A genuinely broad failure is unavailable.

| Evidence role | Run | Exact result | Architecture, files, and useful evidence |
|---|---|---|---|
| Legitimate pass | `Nova_Nova_8`, `rd7cj570wajjs0n8kjwqyehqxd8c3v7z` | 138/138 base, 24/24 focused | One production file with 164 raw additions and 2 deletions, plus docs and tests. It copied the source DCPL, cleared only its VDS mappings, then rebuilt every mapping independently; this naturally retained nondefault creation properties. It also used live `SEL_ALL` spaces and anonymous publication. |
| Legitimate pass | `Nova_Nova_10`, `rd70edekgh5ff4skwf5wtjd9bh8c31a4` | 138/138 base, 24/24 focused | One production file with 142 raw additions and 2 deletions, plus tests. It built a fresh DCPL and manually copied allocation time, fill time, timestamp tracking, and attribute creation-order flags, but omitted the attribute phase-change thresholds. That omission is invisible to the 24-entity verifier despite changing inherited `Group.copy()` metadata. |
| Recurring near-pass | `Nova_Nova_1` through `Nova_Nova_5`, plus `Nova_Nova_7` and `Nova_Nova_9` | each 138/138 base and 23/24 focused | Seven independent reconstructions failed only the existing valid same-file direct-VDS case. Their raw production additions range from 132 to 174, each in one production file. |
| Broadest supplied near-pass | `Nova_Nova_6`, `rd7d66gjt67tnkgy2wqpcdjedn8c3d52` | 138/138 base, 22/24 focused | A two-production-file helper reused higher-level VDS construction, but failed metadata/selection preservation as well as the same-file case. It has 27 raw additions in `group.py` plus its `vds.py` implementation. |
| Broad failure | unavailable | - | No supplied run failed more than two focused entities. |

The ATIF export again has four platform steps per run and does not preserve the
platform-reported agent-message metric. Tool calls are not substituted for it.
Strict-effective solver LOC was likewise not supplied. The successful median is
nevertheless conclusively one production file, below the two-file
long-horizon requirement. The 2/10 solve rate satisfies the nominal difficulty
and solvability band, but the seven single-edge near-passes make that difficulty
thin; more importantly, the successful file median is already terminal for the
current long-horizon rubric.

The second completeness audit demonstrated five plausible incorrect
implementations that pass all 24 focused entities and 138 selected-base tests.
Each proposed addition crosses a distinct repository-supported boundary:

- `Group.copy()` resolves a string source relative to the `Group` on which the
  method is invoked, not unconditionally from the file root;
- filename classification must occur per mapping when absolute, ordinary
  relative, and `.` records coexist;
- source-selection handling must occur per mapping when an absent explicit
  source coexists with a readable `SEL_ALL` source;
- each `SEL_ALL` mapping needs its own mapped dataset's current dataspace, not
  one cached representative space; and
- relocation changes mapping filenames only; inherited `Group.copy()` metadata
  preservation includes observable nondefault DCPL properties and attribute
  creation order. The second legitimate solver's partial manual DCPL copy is
  direct trajectory evidence for this shortcut.

The mixed filename and mixed selection probes are not mere fixture
permutations: they distinguish per-record dispatch from the already-tested
iteration of homogeneous records. The heterogeneous `SEL_ALL` probe isolates
per-source current-space lookup. The creation-property probe checks public
low-level properties already preserved by native copy and by the reference; it
does not require a private helper or byte-identical property-list
representation. All five tests are therefore accepted.

The separate API-documentation finding is also valid: `docs/high/group.rst`
still advertises the old public signature. Documentation belongs in the
reference solution patch, but it is not converted into a hidden textual test.

Changing `test.patch` and `solution.patch` invalidates the completed 2/10 batch.
The revised immutable version must rerun every exact gate and restarts at 0/10.
No cold solver is part of this requested revision.

## Discriminator ledger

| Observed solver/repository behavior | Generalized shortcut | Fair public/repository invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| Native `H5Ocopy` retains relative mapping text while HDF5 changes its resolution base. | Delegate every copy to `h5o.copy()` unchanged. | An opted-in cross-directory copy resolves every ordinary relative mapping to the same source file as the original VDS. | Put different sentinels at the original and newly implied paths; the copy must read the original data and expose a rebased mapping. | Relative source identity | Any correct lexical or resolved-path implementation passes; the assertion is not tied to one helper. |
| Existing VDS creation stores same-file sources as `.`. | Leave `.` unchanged and silently retarget it to the destination file. | Cross-file relocation preserves the original same-file source. | Give source and destination files different same-named datasets; the copy reads the source-file value. | Special same-file mapping | Direct-copy behavior is explicit; ambiguous recursive-group behavior is excluded. |
| Absolute VDS names do not depend on the VDS directory. | Rewrite every filename with `relpath()`. | Absolute mappings remain absolute, unchanged, and select the same source. | Inspect the copied mapping and read an absolute-path source after a cross-directory copy. | Absolute versus relative classification | Preserves platform-native spelling and permits any reconstruction architecture. |
| HDF5 permits explicit VDS mappings to sources that are currently absent. | Open every mapped source even when the stored selection is self-describing. | Explicit source selections relocate without source I/O. | Relocate first, create the explicitly selected source only at its original future path, and then read it through the copy. | Metadata reconstruction versus source I/O | This follows established VDS missing-source behavior without pretending the unrecoverable `SEL_ALL` extent is stored. |
| Reopened all-source mappings expose a scalar `SEL_ALL` sentinel rather than the source extent. | Guess the source rank from the virtual selection, or publish an invalid mapping when the source is absent. | All-source mappings use the live source dataspace and fail without publication when it cannot be read. | Preserve an existing differently ranked all-source mapping; separately remove its source and verify rejection leaves no link. | Lost source-extent recovery | The rule follows an observed HDF5 representation limit and permits any way of reading the public source dataspace. |
| `virtual_sources()` returns both mapping dataspaces, including unlimited regular hyperslabs. | Reconstruct filenames but replace selections with full fixed extents. | Every virtual/source selection and unlimited-growth behavior is retained. | Compare mapping selections and append to the original unlimited source; the copied VDS grows and reads like the original. | Dataspace semantics | Tests public HDF5 behavior rather than a high-level layout implementation. |
| Native object copy retains dataset metadata and honors `without_attrs`. | Recreate only mappings and dtype. | Shape/maxshape, fill value, and ordinary attributes survive; `without_attrs` omits attributes. | Read gaps, inspect public properties, and compare attribute presence in two copies. | Dataset metadata and option composition | These are stable public `Dataset` and `Group.copy()` properties, not private DCPL bytes. |
| `Group.copy()` supports several source, destination, and name forms. | Special-case only a Dataset-object-to-root-group call. | Relocation works when the direct VDS is supplied by path and is published at a nested destination/name. | Copy through the path form to a destination group with an explicit nested name and read it after reopening. | Public argument normalization | Exercises the established high-level API, not extra path-spelling variants. |
| Reconstruction can fail after an HDF5 object has been created. | Publish the destination before validating scope/options or completing attribute transfer. | Unsupported scope and option combinations fail without leaving the requested destination link. | Attempt group, named-datatype, non-VDS, and `expand_refs` relocation beside sentinels; verify no requested link appears. | Validation and publication | Anonymous creation, validation-first, temporary links, and other safe approaches can pass. |
| Ordinary `Group.copy()` has a large native contract. | Route all calls through the reconstruction path after adding the keyword. | Calls with the default false value retain native group and ordinary-dataset behavior. | Exercise an existing recursive copy and an ordinary cross-file dataset copy with default options. | Backward compatibility | Prevents feature-wide interception without prescribing branching structure. |
| Every prior feature test explicitly passed `relocate_vds=True`; an adversarial implementation relocated cross-file VDS objects even when the option was omitted. | Advertise a false default in the signature but infer relocation from the source object or file boundary. | Omitting the opt-in keeps native destination-relative VDS filename resolution. | Place different data at the source- and destination-relative mapping targets, omit the option, and observe the native destination-side value and unchanged mapping text. | Option gating / backward compatibility | Any implementation that genuinely conditions the new behavior on the public option passes; no branch structure is prescribed. |
| An adversarial implementation placed scope and option validation inside a cross-file-only branch. | Treat same-file relocation as an unconditional native-copy fast path. | Direct-VDS scope and `expand_refs` incompatibility apply whenever relocation is requested, independent of file identity, and rejection publishes no link. | Attempt same-file group, named-datatype, ordinary-dataset, and `expand_refs` copies; require an ordinary exception and link absence. | Validation domain / atomic publication | The checks name public input classes and an explicit option conflict; accepting every ordinary exception avoids implementation coupling. |
| An adversarial implementation rejected every same-file relocation request. | Infer that the cross-file motivation makes different files an additional source-domain precondition. | A direct VDS is the permitted source domain and established same-file `Group.copy()` remains valid. | Copy a direct VDS to a new link in its own file and read the result. | Accepted-domain boundary | This preserves an existing public copy form and does not require relocation to do unnecessary rewriting. |
| A demonstrated signature mutant advertises `relocate_vds` with a truthy or sentinel default. | Add the parameter but choose relocation behavior unless callers explicitly disable it. | The public signature default is exactly `False`. | Inspect the public parameter default object. | API default | This is the literal public API declaration and does not prescribe control flow. |
| A demonstrated mapping mutant rebases only the first relative filename. | Treat one representative relative mapping as dataset-wide relocation state. | Every mapping is classified and relocated independently. | Use two relative mappings with destination-side decoys and verify both source identities. | Mapping iteration / relative path | Two independently resolved mappings distinguish per-record logic from another filename fixture. |
| A demonstrated source-I/O mutant treats an absolute explicit mapping as requiring validation. | Couple absolute-path classification to source opening even when the selection is self-describing. | Explicit selections remain metadata-only for both absolute and relative filenames. | Relocate an absent absolute explicitly selected source, create it later, and read through the copy. | Path classification x selection kind | Absolute and relative paths take distinct public branches; the test crosses that boundary without requiring an implementation helper. |
| A demonstrated `SEL_ALL` mutant synthesizes the source space from the declared or virtual point count. | Claim current-dataspace handling without observing a changed live extent. | `SEL_ALL` uses the mapped dataset's current dataspace and any incompatibility fails before publication. | Declare one source extent, create a differently sized current dataset, and verify exception plus link absence. | Live extent | This directly distinguishes the public word “current” from rank-only or point-count reconstruction. |
| A demonstrated `SEL_ALL` mutant opens the file but never opens the named dataset. | Treat file availability as sufficient and reuse stored extent metadata. | Reading the current source dataspace includes opening the named dataset; failure is atomic. | Use an existing HDF5 file without the requested dataset and verify exception plus link absence. | Dataset-open boundary | Missing file and missing dataset are different I/O stages; the oracle requires only public readability and publication behavior. |
| A demonstrated scope mutant uses mapping-list truthiness as the VDS predicate. | Reject a zero-mapping VDS as an ordinary dataset. | Virtual layout, not mapping count, defines the permitted direct source. | Relocate a fill-only zero-mapping VDS and inspect/read the result. | Source classification | Existing repository behavior establishes the empty form; any correct `is_virtual` or equivalent classification passes. |
| A demonstrated path-resolution mutant resolves every string source from the file root. | Reimplement the new validation lookup without retaining `Group.copy()`'s receiver-relative addressing. | A string source remains relative to the `Group` on which `copy()` is invoked. | Place a VDS below a non-root group and copy it by its group-relative name. | Public source addressing | This is an existing high-level API invariant, independent of relocation internals. |
| A demonstrated filename-dispatch mutant classifies one representative mapping and reuses that policy. | Treat absolute, relative, and `.` as dataset-wide state. | Each mapping's filename kind is handled independently. | Combine all three filename kinds in one VDS and verify spelling/source identity for each. | Per-mapping filename dispatch | The interaction distinguishes heterogeneous record handling from another homogeneous filename fixture. |
| A demonstrated selection-dispatch mutant uses one selection kind for every mapping. | Open all sources, or avoid all source I/O, based on one representative record. | Explicit and `SEL_ALL` mappings retain their independent source-I/O rules. | Combine an absent explicit mapping with a readable whole-source mapping and relocate successfully. | Per-mapping selection dispatch | Both policies are already public; their coexistence tests record-local application rather than call order. |
| A demonstrated current-space mutant caches the first live source dataspace. | Reuse one `SEL_ALL` extent for heterogeneous mapped datasets. | Every whole-source mapping uses its own named dataset's current dataspace. | Combine differently sized whole-source mappings and read the complete relocated VDS. | Per-source current dataspace | Different current extents expose inappropriate caching without prescribing how datasets are opened. |
| A demonstrated fresh-DCPL mutant copies only the common VDS properties. | Reconstruct mappings while silently resetting uncommon creation properties. | Relocation preserves inherited `Group.copy()` metadata except for the requested filename changes and `without_attrs`. | Create a VDS with nondefault allocation/fill/timestamp/attribute-order/phase properties and compare public getters plus attribute order. | Dataset creation metadata | These properties are public and native-copy-preserved; source-DCPL reuse and complete explicit copying both pass. |

## Requirement and compatibility coverage

| Source | Requirement / invariant | Observable test | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Prompt | Relative source identity | Cross-directory source/destination decoy tree | Original sentinel and rebased stored name | HDF5 VDS resolution rule |
| Prompt | `.` source identity | Same-named source and destination datasets | Original source-file data | Existing h5py same-file mapping behavior and PR #1622 discussion |
| Prompt | Absolute paths unchanged | Copy a VDS with an absolute source name | Same stored absolute name and data | Absolute paths are independent of the VDS directory |
| Prompt | Missing explicit source at copy time | Relocate before creating its relative source, then create it only at the original location | Later source is found and read | Explicit VDS mappings are self-describing metadata and may target absent files |
| Prompt | All-source extent recovery | Copy an existing full-source mapping with differing source/virtual ranks; repeat after source removal | Existing mapping is preserved; unavailable extent is rejected without a link | Reopened `SEL_ALL` source spaces lose rank and extent |
| Prompt | Direct-VDS and `expand_refs` limits | Reject group, named datatype, ordinary dataset, and incompatible option | Reject before link publication | Honest scope boundary; reference-expansion composition is not supplied by reconstruction |
| Prompt / repository | False default is opt-in | Omit `relocate_vds` while destination-relative data differs | Native mapping text and destination-relative data remain selected | Public default plus existing VDS copy resolution |
| Prompt / repository | Validation is independent of file identity | Repeat every forbidden source class and `expand_refs` conflict in one file | Ordinary exception and no destination link | The stated source/option domain does not acquire a same-file exception |
| Repository | Same-file direct VDS remains accepted | Copy a direct VDS to a new same-file link with relocation enabled | Virtual result reads the same source data | Existing `Group.copy()` same-file domain; different files are not a stated precondition |
| Repository | Selection, unlimited, metadata, and attribute compatibility | Multi-selection/growth and paired metadata copies | Existing `Group.copy()` semantics remain observable | Existing copy and VDS APIs |
| Repository | Existing source/destination/name forms | Path source to destination group with explicit nested name; Dataset-object source with default name | Established forms remain usable | Existing `Group.copy()` contract |
| Repository | Default behavior | 138-case existing group/VDS lane | Existing pass | Additive keyword default |

## Environment and harness preflight

- Exact source pin cloned at
  `Work/h5py-vds-copy-relocation/h5py`; repository status was clean after the
  detached checkout.
- The cached official
  `public.ecr.aws/d3j8x8q7/olympus-base:latest` image is Debian 12 with Python
  3.12.13. The deprecated `olympus-base-python` tag is unavailable, so the
  supported generic Python-capable image will be used.
- The earlier candidate audit built the pin with HDF5 1.10.8 and passed a
  157-case focused lane plus the complete offline lane: 842 passed, 56 skipped,
  4 network tests deselected, and 3 subtests passed in both pristine and
  prototype states.
- All new fixtures will use deterministic temporary paths and locally generated
  HDF5 files. No network, timing, shared global state, or binary fixture is
  required.

## Design verdict

Level 1 is locally verified for the explicit direct-VDS contract. The final
reference has 119 raw additions and 2 deletions, or 100 strict-effective
additions, in one production file. The broader result than the original
57-line prototype comes from the repository-observed all-source extent recovery
boundary, not from recursive scope or padding.

The current exact patch matrix passes. Pristine fails all 29 focused entities,
and the reference passes all 29. The complete pre-existing lane passes 842
tests offline, and the final 30-mutant audit has no survivor. The latest five
probes pin receiver-relative source addressing, heterogeneous filename and
selection dispatch, per-source whole-dataset spaces, and nondefault inherited
creation metadata. The rejection tests constrain no concrete exception class.
Full evidence is in `FALSE_POSITIVE_AUDIT.md`.

The later ten-run 24-entity batch completed 2/10. Both legitimate successes
changed one production file; seven failures were 23/24 on the same same-file
edge and one was 22/24. The revised replay preserves the source-DCPL pass at
29/29 and exposes an omitted creation property in the other predecessor pass,
which scores 28/29. Because the test and solution artifacts changed, the
completed 2/10 batch is historical and the current version is 0/10.

The package is not submission-ready. The completed predecessor's successful
median of one production file fails the current long-horizon rubric regardless
of the nominal 2/10 solve rate. Recursive group relocation may not be added to
manufacture scope. No cold solver was run for the current revision.

## Olympus redesign gate - 2026-08-08

The operator supplied the governing platform measurements for the completed
direct-copy version: 91 effective reference LOC and 133 median successful-agent
LOC. Both successful agents changed only `h5py/_hl/group.py`. These measurements
supersede the earlier local 100-line forecast and conclusively fail the current
long-horizon minimum of 200 median effective LOC in at least two production
files. Adding more relocation fixtures cannot change that architecture.

Before designing a replacement, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the h5py candidate/problem compact records, and all
ten supplied `agent-runs3` results were reread. The representative raw evidence
remains:

| Category | Evidence | Architecture and redesign consequence |
|---|---|---|
| Legitimate pass | Nova 8, `rd7cj570wajjs0n8kjwqyehqxd8c3v7z` | Reconstructed the complete VDS and copied attributes in one `Group.copy` implementation. A copy-only redesign will converge to the same file again. |
| Near pass | Nova 10, `rd70edekgh5ff4skwf5wtjd9bh8c31a4` | Built a fresh DCPL but omitted uncommon creation metadata. This supports a reusable layout-cloning boundary, not another metadata fixture attached only to `Group.copy`. |
| Broadest failure | Nova 6, `rd7d66gjt67tnkgy2wqpcdjedn8c3d52` | Split mapping reconstruction into `_hl/vds.py` and copy integration into `_hl/group.py`, but still implemented only the private copy path and missed same-file and metadata behavior. The split is useful only if the VDS layer becomes an independently public, black-box-tested feature. |

The redesign therefore replaces the copy-only feature with two independently
useful public behaviors:

1. `VirtualLayout.from_dataset(dataset)` reconstructs an
   existing direct virtual dataset as an independent reusable layout. It
   retains dtype, current/max shape, fill and relevant creation properties,
   reconstructs every virtual/source selection, permits subsequently adding
   mappings through the existing layout API, and rejects non-VDS inputs.
   Explicit source selections remain metadata-only; whole-source selections
   use their own live source dataset space. `VirtualLayout.relocated()` returns
   an independent target-specific layout and handles targetless old bases.
2. `Group.copy(..., relocate_vds=True)` uses the same public reconstruction
   semantics to publish a direct VDS atomically while retaining established
   copy addressing, naming, attribute, option, and default behavior.

This is a coherent VDS round-trip and relocation capability, rather than a
required private helper: callers can clone or extend a reopened VDS layout
without copying an object, while `Group.copy` is a separate consumer. Correct
solutions may share implementation or implement the two public surfaces
independently. Recursive group relocation remains excluded because it would
require inventing object-graph, hard-link, and reference policies primarily to
inflate scope.

### Redesign discriminator ledger

| Evidence | Plausible shortcut | Public invariant | Black-box oracle | Distinct boundary / anti-overfit rationale |
|---|---|---|---|---|
| Existing `VirtualLayout` can only be constructed prospectively. | Return the source DCPL or a wrapper tied to the open source dataset. | `from_dataset` returns an independent layout usable after the source file closes. | Reconstruct, close the source, create a new VDS, and read/inspect it. | Lifetime/ownership boundary; accepts any deep-copy representation. |
| Nova 10 copied only familiar VDS reconstruction fields. | Rebuild mappings but reset one or more declared creation properties. | The reconstructed layout round-trips the explicitly listed fill, timing, timestamp, attribute-creation, dtype, and dataspace behavior. | Read mapped/unmapped regions and compare the named public DCPL getters, dtype, shape, and maxshape after layout creation. | Direct layout reconstruction boundary supported by a demonstrated solver shortcut; the public contract now identifies the tested property families, and either DCPL reuse or complete explicit copying passes. |
| Reopened whole-source mappings expose `SEL_ALL` without their original extent. | Reuse the virtual selection or one representative source space. | Each whole-source mapping uses its own named dataset's current dataspace. | Reconstruct heterogeneous whole-source mappings after their live extents differ and verify success/failure before creation. | Per-source reconstruction boundary; not another filename fixture. |
| Existing VDS mappings may name future missing sources when their selections are explicit. | Open every mapped source while cloning a layout. | Explicit mappings can be reconstructed without source I/O. | Clone a layout with absent relative and absolute explicit sources, create sources later, then read the new VDS. | Metadata versus I/O boundary inherited from VDS semantics. |
| Relative, absolute, and `.` mappings may coexist. | Choose one filename policy for the layout. | Target-filename rebasing is applied independently per mapping. | Clone one heterogeneous layout to another directory and verify stored spelling and resolved identities. | Per-record path dispatch, already supported by demonstrated mutants. |
| `VirtualLayout.__setitem__` is the existing composition surface. | Produce a sealed copy artifact that cannot act as a layout. | A reconstructed layout remains extendable with new mappings before creation. | Clone a layout, assign an additional nonoverlapping mapping, and read both old and new regions. | New public composability boundary; distinguishes a reusable API from a private copy plan. |
| The direct feature's solvers localized all behavior in `Group.copy`. | Duplicate a partial mapping rewrite in the copy path and leave the public layout API inconsistent. | Layout reconstruction and copy relocation have the same source-identity and selection semantics. | Exercise equivalent mixed mappings through both public entry points. | Cross-consumer consistency; does not require one internal helper. |
| Native `Group.copy` publishes only after HDF5 copy success. | Link a partially reconstructed VDS before all layout/attribute work succeeds. | Relocation failures leave no requested destination link. | Trigger unreadable whole-source and attribute-copy failures beside sentinels. | Transaction/publication boundary independent of layout reconstruction. |

No canonical artifact is revised until a disposable reference spike proves a
cheapest complete implementation with at least two production files and enough
margin above 200 strict-effective LOC. A passing spike is still only a scope
forecast; after any canonical redesign the immutable calibration version resets
to 0/10, all exact and false-positive gates repeat, and successful-agent medians
remain governing. No cold solver is authorized during this redesign phase.

### Disposable redesign spike result

The smallest complete spike implemented only the two public components above:
layout reconstruction/relocation in `h5py/_hl/vds.py` and atomic copy
integration in `h5py/_hl/group.py`. The finalized reference measures 249 local
nonblank/noncomment production additions (199/6 raw additions/deletions in
`vds.py`, 88/3 in `group.py`) across exactly two production files. The prior
platform counter measured the old 100-local-line reference as 91 effective LOC;
applying that conservative ratio forecasts roughly 227 platform-effective LOC
for the spike, above the 200 floor without counting documentation or tests.

The spike round-tripped and relocated mixed ordinary-relative and `.` mappings
after closing the source, retained numeric, empty, string, and reference
attribute behavior through `Group.copy`, and supported retargeting a layout
originally constructed without a filename when an explicit resolution base was
provided. The pristine 157-case VDS/group lane passed. This closes the local
scope prefilter and authorizes canonical redesign, but it does not establish a
successful-agent median. The new immutable artifact starts at 0/10 and receives
no cold solver during this task.

### Exact redesigned artifact verdict

The canonical artifact has 41 focused entities. Pristine upstream fails all
41; both patch orders pass 41/41 plus 138/138 selected regressions; out-of-tree
execution passes 41/41; and the solution-only complete pre-existing lane passes
842 tests with 60 skips and 3 subtests offline as `nobody`. All 40 current
mutants are killed, and a RuntimeError exception-taxonomy control passes 41/41.

The strongest old copy-only solver replays at 29/41, confirming that the 12 new
entities require the independently public layout component. Exact artifact
hashes and requirement/mutant mappings are in `FALSE_POSITIVE_AUDIT.md`.

The redesign is viable for fresh calibration but not submission-ready. It is
at 0/10, and the conservative 227-LOC reference forecast cannot replace the
required median among successful solver patches or the platform message metric.

### DCPL fairness correction gate - 2026-08-08

The latest fairness review found one over-specified logical test group:
`test_reconstructed_layout_preserves_creation_behavior` combined the public
layout round-trip contract with exact equality for allocation time, fill time,
object timestamp tracking, attribute creation-order flags, and attribute
phase-change thresholds. The public prompt does not enumerate those five
low-level fields for `VirtualLayout.from_dataset`, and the closest repository
reconstruction convention does not establish that exact field set. Requiring
them would select the reference's DCPL-copy strategy rather than a public
behavior.

The correction removes only those five layout-level field requirements and
their nondefault fixture setup. The test continues to require the demonstrated,
participant-facing reconstruction boundary: mapped and fill-region reads,
dtype, current shape, and maximum shape. The separate `Group.copy` creation-
property test remains because the new option must preserve the established
native-copy semantics of that API, and the review did not challenge it. The
prompt and reference behavior are unchanged; no new discriminator is added.

This exact verifier revision invalidates the preceding artifact hash and resets
the immutable version to 0/10. The pristine gate, both patch orders, selected
and full regression lanes, out-of-tree execution, prior-solver replays, and all
40 documented mutants must be rerun. In particular, the phase-change mutant
must remain killed by the established `Group.copy` check rather than the
removed layout assertion. No cold solver is authorized for this correction.

The rerun closes that gate. The corrected `test.patch` hash is
`639aa99802bc44d6d3a834ac987f092633200ae4244cdaf7d882e4742915530f`;
the other three canonical hashes are unchanged. Pristine/test-only still passes
138/138 selected regressions and fails/errors all 41 focused entities. Both
patch orders pass 138/138 plus 41/41, out-of-tree and bare-`pytest` execution
pass 41/41, and the solution-only offline unprivileged full lane passes 842
tests with 60 skips and 3 subtests. The `RuntimeError` control passes 41/41.
All 40 mutants remain killed; `reset_attr_phase_change` now fails only the
established `Group.copy` property test at 40/41. Saved Nova 8, Nova 10, and Nova
6 replays remain 29/41, 28/41, and 27/41. No cold solver was run, and the exact
corrected version remains at 0/10.

### Targetless absolute-only relocation gate - 2026-08-08

Before revising the verifier, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the candidate/problem indexes, this problem's
compact records, and the representative Nova 8 pass, Nova 10 near-pass, and
Nova 6 broad failure were reread. Those trajectories predate the public
`VirtualLayout.relocated()` redesign and therefore provide no solver evidence
for this exact branch; they only confirm that older solvers concentrated on
copy-time per-mapping path rewriting. The controlling evidence is instead the
public prompt and API boundary: layouts constructed without a target filename
require `source_filename` to establish the old resolution base. That
precondition is stated for the layout, not conditional on whether its current
mappings happen to need rebasing.

| Evidence | Plausible shortcut | Public invariant | Black-box oracle | Distinct boundary / anti-overfit rationale |
|---|---|---|---|---|
| The existing targetless probe contains a relative mapping, while absolute mappings otherwise bypass rebasing. | Infer that an old base is unnecessary when every current mapping filename is absolute and silently accept an omitted `source_filename`. | Every targetless layout requires the explicit old base, including an absolute-only layout. | Build a targetless layout with one absolute mapping and require relocation without `source_filename` to fail; the existing success path with an explicit base remains. | Tests whether the layout-level precondition is enforced before per-mapping classification. This is a semantic control-flow boundary, not another spelling fixture or a prescribed implementation. |

The correction will extend the existing targetless logical test rather than add
a new public rule or another test entity. A matching isolated mutant will
conditionally bypass the guard only for absolute-only layouts; it must pass the
predecessor suite and fail the new assertion. The prompt, reference, and
Dockerfile remain unchanged. Any verifier edit creates a new immutable artifact
at 0/10 and requires the complete matrix, regression, saved-replay, exception-
taxonomy, and false-positive gates again. No cold solver is authorized.

The strengthened logical test preserves the 41-entity count. Its exact
`test.patch` hash is
`5e454546bae8ed797f7f78084365255cdd8723f5a7b8c6b3c3e2a0e5757d7977`;
the prompt, reference, and Docker hashes remain unchanged. The conditional
absolute-only bypass mutant passes the predecessor focused suite 41/41 and
fails the corrected test at 40/41, while the reference passes 41/41. All 41
active mutants are killed on the corrected artifact.

The complete rerun also passes: pristine/test-only has 138/138 selected
regressions and 41/41 focused failures/errors; both patch orders pass 138/138
plus 41/41; out-of-tree and bare-`pytest` execution pass 41/41; the offline
unprivileged full lane passes 842 tests with 60 skips and 3 subtests; and the
`RuntimeError` control passes 41/41. Saved Nova 8, Nova 10, and Nova 6 remain at
29/41, 28/41, and 27/41. No cold solver was run. The immutable version remains
at 0/10.

### Direct layout creation-property contract gate - 2026-08-08

Before acting on the T4 direct-surface finding, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the candidate/problem indexes, `SUMMARY.md`,
`LEVELS.md`, `RUNS.md`, the prior fairness record, and the raw Nova 8, Nova 10,
and Nova 6 evidence were reread. Nova 8 retained the source DCPL while rebuilding
mappings, so uncommon creation properties survived. Nova 10 built a fresh DCPL
and copied allocation time, fill time, timestamp tracking, and attribute
creation-order flags but omitted phase-change thresholds. Nova 6 separated VDS
reconstruction into `_hl/vds.py` and copy integration into `_hl/group.py` but
did not expose the redesigned public layout surface. These trajectories support
both the omission risk and the architectural possibility that copy integration
and direct layout reconstruction do not share one complete implementation.

The earlier fairness correction was correct for its exact public version: the
phrase "creation behavior" did not identify the five low-level property
families, so testing their exact getters selected an unstated contract. The new
completeness finding cannot be fixed fairly by silently restoring those hidden
assertions. The participant-facing description will instead define the intended
creation fidelity explicitly: fill value, allocation/fill timing, object
timestamp tracking, attribute creation-order and phase-change settings, dtype,
and current/maximum shape. With that public clarification, direct black-box
comparison of the cloned dataset's property-list getters is contractual rather
than reference-specific.

| Evidence | Plausible shortcut | Public invariant | Black-box oracle | Distinct boundary / anti-overfit rationale |
|---|---|---|---|---|
| Nova 10's demonstrated fresh-DCPL implementation omitted phase-change thresholds, and old solvers localized preservation inside copy integration. | Preserve complete creation properties only through `Group.copy`, while `VirtualLayout.from_dataset()` reconstructs common fields and mappings. | A dataset created directly from the returned layout retains every creation-property family explicitly listed in the prompt. | Create a source VDS with nondefault values, close its file after `from_dataset`, create a clone from the layout, and compare the named public DCPL getters plus fill/data, dtype, shape, and maxshape. | Direct public-surface fidelity, independent of the copy consumer; source-DCPL reuse and complete explicit copying both pass. |

The existing direct logical test will regain only the newly public nondefault
fixture and getter comparisons; no new test entity is needed. A matching
direct-surface mutant will omit phase-change fidelity from `from_dataset` while
retaining it for copy integration. It must pass the predecessor suite and fail
the strengthened direct test. This changes `meta.md` and `test.patch`, leaves
the already-complete reference and Dockerfile unchanged, resets the immutable
version to 0/10, and requires the full exact and false-positive rerun. No cold
solver is authorized.

The completed exact version has `meta.md` hash
`34e302790597695901fe26db04bf210aed995e5ac972f5f0462a733722e5af72`
and `test.patch` hash
`4610c8f3bedd950389cb423055ed4408bc8148e513f1521c87e161035d66b06c`;
the reference and Docker hashes are unchanged. The direct-only phase-change
mutant passes the predecessor 41/41 and fails the strengthened logical test at
40/41. The shared phase-change mutant now fails both public consumers at 39/41,
and all 42 active mutants are killed.

Pristine/test-only passes 138/138 selected regressions and fails/errors all 41
focused entities. Both patch orders pass 138/138 plus 41/41; out-of-tree and
bare-`pytest` execution pass 41/41; the offline unprivileged full lane passes
842 tests with 60 skips and 3 subtests; and the `RuntimeError` control passes
41/41. Saved Nova 8, Nova 10, and Nova 6 remain 29/41, 28/41, and 27/41. No cold
solver was run, and the clarified immutable version remains at 0/10.

### Direct explicit-selection geometry gate - 2026-08-08

Before changing the verifier for the direct-selection finding,
`PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, the candidate/problem indexes,
the current compact records, and the representative raw Nova 8, Nova 10, and
Nova 6 patches/evaluations were reread. All three old copy-time architectures
retrieved `get_virtual_srcspace()` and retained it for explicit selections;
they opened the mapped dataset only for `SEL_ALL`. That supports selection
preservation as established VDS behavior, but those runs predate the independently
public `VirtualLayout.from_dataset()` surface. They therefore do not establish
that a redesigned solver will preserve nontrivial explicit geometry directly.

The prompt already requires the reconstructed layout to reproduce the original
mappings. The current direct missing-source fixture uses only zero-based
contiguous selections, so synthesizing a new contiguous source space with the
same point count is observationally equivalent there. Existing offset/stride
coverage is attached to `Group.copy`; an independent direct implementation can
still be wrong while copy integration remains correct.

| Evidence | Plausible shortcut | Public invariant | Black-box oracle | Distinct boundary / anti-overfit rationale |
|---|---|---|---|---|
| Reopened explicit mappings expose a complete source dataspace, but the direct fixture currently uses only full zero-based ranges. | Reconstruct an explicit mapping as `0:n` using its selected point count, discarding offsets and strides. | `VirtualLayout.from_dataset()` preserves each explicit source selection's geometry as part of reproducing the mapping. | Reconstruct while two explicitly selected source files are absent, create them later with decoy values around offset/strided selections, then create/read the cloned VDS. | Source-selection geometry on the direct public surface; distinct from source-I/O avoidance, filename relocation, virtual selection, and whole-source extent recovery. Any representation producing the same selected values passes. |

The existing direct missing-source logical test will use offset/strided source
selections and decoy data; no new test entity or prompt rule is needed. A
matching direct-only mutant will flatten explicit source selections while
preserving the established copy integration path. It must pass the predecessor
41-entity suite and fail the strengthened logical test. Only `test.patch` is a
canonical change; `meta.md`, the already-complete reference, and Dockerfile
remain unchanged. The exact artifact resets to 0/10 and all matrix, regression,
saved-replay, exception, and false-positive gates repeat without cold solvers.

The exact strengthened `test.patch` hash is
`f091a54c8100289e06bf101a0fffb6497cde9df353a42337d304f6634a7e04e2`;
the other three canonical hashes are unchanged. The direct-only contiguous-
selection mutant passes the predecessor 41/41 and fails the strengthened
logical test at 40/41. The reference passes, and all 43 active mutants are
killed.

Pristine/test-only again passes 138/138 selected regressions and fails/errors
all 41 focused entities. Both patch orders pass 138/138 plus 41/41; out-of-tree
and bare-`pytest` execution pass 41/41; the offline unprivileged full lane
passes 842 tests with 60 skips and 3 subtests; and the `RuntimeError` control
passes 41/41. Saved Nova 8, Nova 10, and Nova 6 remain 29/41, 28/41, and 27/41.
No cold solver was run, and the immutable version remains at 0/10.

### Resized VDS current-extent gate - 2026-08-08

Before acting on the current-VDS-extent finding, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the candidate/problem indexes, compact records, and
the raw Nova 8, Nova 10, and Nova 6 extent paths were reread. Each old copy-time
implementation created the destination with `source.id.get_space()`, which is
the live VDS dataspace, rather than inferring the extent from its mappings.
Those trajectories predate `VirtualLayout.from_dataset()` but establish the
repository-shaped current-dataspace convention.

A frozen-image probe created a VDS with shape `(3,)` and unlimited maximum
shape, then called the public low-level `DatasetID.set_extent((5,))`. In that
open handle, the live dataset shape and data became `(5,)` and
`[7, -9, -9, -9, -9]`, while `virtual_sources()[0].vspace.shape` remained
`(3,)`. Reopening the file normalizes that mapping-space extent to `(5,)`, so
the discriminating call must reconstruct after the resize and before the source
handle closes, then use the returned layout after closure. High-level
`Dataset.resize` rejects VDS objects because they do not report chunking, so the
low-level extent operation is the applicable repository API.

| Evidence | Plausible shortcut | Public invariant | Black-box oracle | Distinct boundary / anti-overfit rationale |
|---|---|---|---|---|
| A resized VDS's live dataspace diverges from the unchanged mapping virtual-space extent until the file is reopened. | Infer the reconstructed layout shape from the first mapping's virtual space or union of mapping bounds. | `VirtualLayout.from_dataset()` uses the VDS's current shape while retaining its maximum shape. | Resize through `DatasetID.set_extent`, reconstruct from the still-open resized dataset, close it, create a clone, and verify the expanded fill region, current shape, and maxshape. | Dataset current extent versus mapping extent; distinct from live mapped-source `SEL_ALL` extent and from maxshape preservation. Any implementation reading the live dataset dataspace passes. |

The existing creation-behavior logical test will resize the source VDS before
reconstruction and update its data/current-shape assertions; no new test entity
or prompt rule is needed because the current shape is already explicit. A
matching mutant will derive the layout shape from a mapping virtual space and
must pass the predecessor suite while failing the strengthened test. Only
`test.patch` changes canonically; `meta.md`, reference, and Dockerfile stay
unchanged. The exact version resets to 0/10 and all verification and false-
positive gates repeat without cold solvers.

The final strengthened `test.patch` hash is
`aa79f055fceafbce32c9cd8b42965da64247b4ccd4346c1e852d237c0a5783cf`;
the other canonical hashes are unchanged. The mapping-extent mutant passes the
predecessor 41/41 and fails the resized-VDS logical test at 40/41. The reference
passes and all 44 active mutants are killed.

Pristine/test-only passes 138/138 selected regressions and fails/errors all 41
focused entities. Both patch orders pass 138/138 plus 41/41; out-of-tree and
bare-`pytest` execution pass 41/41; the offline unprivileged full lane passes
842 tests with 60 skips and 3 subtests; and the `RuntimeError` control passes
41/41. Saved Nova 8, Nova 10, and Nova 6 remain 29/41, 28/41, and 27/41. No cold
solver was run, and the immutable version remains at 0/10.

### Acceptance closeout - 2026-08-10

The user confirmed that the platform accepted the exact redesigned artifact.
Acceptance freezes `meta.md`, `test.patch`, `solution.patch`, and `Dockerfile`
at the hashes recorded in `SUMMARY.md`; no submission artifact changed during
closeout. The redesigned-version calibration remains historically 0/10 because
no cold solver was run, and predecessor copy-only runs are not carried forward.

The two validated uploaded solver ZIPs and the four preliminary candidate
records moved to `archive/h5py-vds-copy-relocation/`. Their hashes, member
counts, integrity checks, restore command, and canonical artifact identities are
recorded in the archive manifest. Readable run-directory mirrors remain in the
problem folder, so the archival operation deleted no solver evidence.
