# ERRORS - h5py VDS copy relocation

Permanent record of review findings and resolved assumptions.

## 13. Copy-only relocation cannot satisfy Olympus long-horizon scope

- Date: 2026-08-08
- Source: completed platform batch and operator LOC report
- Severity: terminal for L1; resolved by material redesign
- Verdict: valid

### Evidence

The direct `Group.copy` version measured 91 effective reference LOC and a 133
effective-LOC median among successful agents. Both successful patches changed
one production file. More mapping fixtures improved completeness but could not
change the convergent architecture.

### Resolution

The copy-only artifact was abandoned. The replacement adds independently
public `VirtualLayout.from_dataset()` and `VirtualLayout.relocated()` behavior
in `_hl/vds.py`, with `Group.copy` as a separate consumer in `_hl/group.py`.
The disposable/canonical reference measures 249 local effective additions
across two production files, conservatively forecasting about 227 under the
prior platform counter ratio. All calibration resets to 0/10.

### Durable lesson

Verifier breadth cannot manufacture long-horizon implementation depth. Once
successful-solvers establish a sub-floor median, require a new public component
with an independent oracle or close the candidate.

## 1. Reopened all-source mappings do not retain their extent

- Date: 2026-08-07
- Source: local reference implementation
- Severity: high
- Verdict: valid

### Evidence

After reopening a VDS, HDF5 exposes an entire-source selection as a scalar
`SEL_ALL` sentinel. Passing it back to `H5Pset_virtual` mismatches a multi-point
virtual selection; the original source rank and extent are unavailable from the
mapping record. The earlier candidate prototype did not exercise this case.

### Resolution

The prompt distinguishes explicit self-describing selections from all-source
mappings. The reference reads the live source dataspace only for the latter and
rejects an unavailable all-source mapping before publication. Separate tests
cover a differently ranked available source and an unavailable source.

### Durable lesson

Round-tripping a public property-list record can lose creation-time context.
Probe reopened state before promising metadata-only reconstruction.

## 2. Canonical absolute fixture allowed a normalizing false positive

- Date: 2026-08-07
- Source: exact false-positive audit
- Severity: medium
- Verdict: valid

### Evidence

An implementation that normalized absolute mapping names passed the predecessor
11-case suite and the complete 842-test lane despite violating “unchanged.”

### Resolution

The existing absolute fixture now uses a valid redundant path component. The
reference passes and the mutant fails only that entity. All exact-version gates
and mutations were restarted for the new test-patch hash.

### Durable lesson

An exact-spelling clause needs a noncanonical but valid spelling; asserting an
already-canonical value does not distinguish preservation from normalization.

## 3. Complete permission test fails under root

- Date: 2026-08-07
- Source: complete-suite preflight
- Severity: warning
- Verdict: valid environment asymmetry

### Evidence

`TestFileOpen.test_append_permissions` expects opening a chmod-read-only file for
append to raise. Root bypasses that permission restriction, producing the sole
failure in an otherwise 841-pass root run.

### Resolution

The focused harness is unaffected. Complete-suite audit runs as `nobody` inside
the same offline image and passes 842 tests. No valid test is deselected to hide
a production regression.

## 4. Review found redundant prompt clauses and missing named-datatype coverage

- Date: 2026-08-07
- Source: external problem review
- Severity: high
- Verdict: valid

### Evidence

The prompt repeated established `Group.copy()` source/destination forms,
ordinary preservation behavior, `without_attrs`, and default native behavior.
Those are discoverable repository semantics, not new relocation requirements.
Conversely, named datatypes were explicitly rejected but only groups and
ordinary datasets were exercised by the scope test.

### Resolution

The four inherited clauses were removed, reducing `meta.md` from 198 to 140
words. A committed datatype was added to the existing parametrized
no-publication test. A named-datatype-only native-fallback mutant scores 11/12
and fails only that new entity. The exact matrix and mutation audit were
restarted for the new hashes.

## 5. Project-install Docker path was invalid and unpinned

- Date: 2026-08-07
- Source: external image build
- Severity: high
- Verdict: valid

### Evidence

The reported build attempted `pip install --system`, but the image's pip does
not support that option. Review also flagged the project install and unpinned
Python dependency specifications.

### Resolution

The Dockerfile now pins Cython 3.2.9, NumPy 2.5.1, pkgconfig 1.5.5, and
pytest-mpi 0.6, then runs `python setup.py build_ext --inplace` instead of a pip
project install. A fresh official-base build completed successfully as ARM64
image `sha256:4c862f8aa109dd032094546f824eee858971e59317fceefb5da97595993f977b`.
This intermediate compile-only correction was later superseded by the editable
install in finding 7.

## 6. Complete-suite no-network option requires the test path at discovery

- Date: 2026-08-07
- Source: revised-image verification
- Severity: low
- Verdict: resolved invocation error

### Evidence and resolution

Calling bare `python -m pytest --no-network` failed because the option is
registered by `h5py/tests/conftest.py`, which was not loaded during initial
argument parsing. The recorded command names `h5py/tests` before
`--no-network` and ignores the focused module when counting pre-existing tests;
it passes 842 tests, skips 60, and passes 3 subtests as `nobody`.

## 7. Compile-only image made pytest entry points ambiguous

- Date: 2026-08-07
- Source: external solver-environment review
- Severity: high
- Verdict: valid

### Evidence

The compile-only image imported `/app/h5py` from the repository root, but an
import from `/tmp` raised `ModuleNotFoundError`. Review observed a solver spend
turns discovering this mismatch and symlink site-packages over `/app` to cover
both likely pytest invocation paths. No corresponding raw h5py trajectory is
available locally, so that symptom is recorded as external evidence.

### Resolution

The Dockerfile now installs the project editably with
`python -m pip install --no-build-isolation -e .`. Direct apt requirements are
pinned to `libhdf5-dev=1.10.8+repack1-1` and `pkg-config=1.8.1-1`. Imports from
both `/app` and `/tmp` resolve `/app/h5py`; a post-build solution patch is live
from `/tmp`, and both pytest entry points pass the focused suite. The current
ARM64 image is
`sha256:94ea8621192650ca61e2048470fc7454ebc8c70644abcab3232318bd60ef87f3`.
The exact matrix, full suite, and then-active 16-mutant audit were restarted for this
Dockerfile hash.

## 8. Rejection oracles over-specified exception classes and missed same-file/default branches

- Date: 2026-08-07
- Source: external adversarial verifier review
- Severity: high
- Verdict: valid

### Evidence

The prompt requires failure and atomic non-publication but names no concrete
exception class. The predecessor suite nevertheless accepted only
`(OSError, ValueError)` for an unreadable all-source mapping and
`(TypeError, ValueError)` for scope and `expand_refs` rejection. The repository
has no established convention making those pairs part of the new API.

The same review demonstrated three plausible branch shortcuts that passed the
complete predecessor verifier: implicit relocation of every cross-file VDS
when the option was omitted, cross-file-only validation that allowed forbidden
same-file copies, and blanket rejection of valid same-file VDS relocation.

### Resolution

All rejection tests now accept any ordinary exception while retaining the
public failure, sentinel, and requested-link-absence assertions. Six focused
entities cover omitted-option legacy resolution, the three same-file forbidden
object kinds, same-file `expand_refs`, and successful same-file direct-VDS
copying. The prompt and reference did not change. The revised reference passes
18/18 focused and 138/138 selected-base tests; the complete unprivileged lane
passes 842 tests with 60 skips and 3 subtests; all 19 active mutants are killed.

### Durable lesson

If a failure class is not public or repository-established, assert failure and
atomicity rather than whitelisting an implementation's exception taxonomy.
Option defaults and validation domains need behavioral boundary probes even
when the signature and cross-file happy path look correct.

## 9. Omitted-option compatibility probe passed pristine upstream

- Date: 2026-08-07
- Source: wrapper-driven test-only run
- Severity: high
- Verdict: valid harness failure

### Evidence

The default-false probe intentionally omits `relocate_vds` and checks legacy
destination-relative mapping resolution. Pristine upstream naturally satisfies
that compatibility behavior even though it does not expose the new option, so
the entity passed without `solution.patch`. The wrapper requires every focused
entity to fail, error, or skip in that state.

### Resolution

The probe now calls the existing public-signature guard before performing the
omitted-option copy. Pristine upstream fails because `relocate_vds` is absent;
an implementation that adds the option but relocates implicitly still fails the
source-identity assertions. Test-only now fails 18/18, while both combined patch
orders pass 18/18 and 138/138 selected-base tests. The complete suite, positive
exception-taxonomy control, and 19-mutant audit were replayed for the new
`test.patch` hash.

## 10. Shared-clone verification context produced invalid container Git alternates

- Date: 2026-08-08
- Source: fresh-image verification
- Severity: medium
- Verdict: verification-context error, not a Dockerfile defect

### Evidence

An initial no-cache rebuild used `git clone --shared`. Tests ran, but Git inside
the image referenced an objects alternate that existed only on the host, so
in-container diff checks could not reliably resolve the repository history.

### Resolution

The context was discarded and recreated with `git clone --no-local` at the
exact pin. A `--pull --no-cache` rebuild produced the self-contained image
`sha256:4fbbd5673cbe000c53bbbd33f1f96fc6aeadbe0090aa9b2a821fba81683aee22`.
The complete patch-state matrix, full suite, exception positive control, solver
replays, and all 25 mutants were rerun there.

### Durable lesson

Do not use shared or local-object clones as Docker build contexts when the
container must run Git checks. Make the checkout self-contained first.

## 11. Six public verifier boundaries were missing

- Date: 2026-08-08
- Source: verifier completeness audit plus five saved solver trajectories
- Severity: high
- Verdict: valid

### Evidence

Six plausible incorrect implementations passed the 18-entity predecessor
suite: a non-`False` default, first-relative-only rebasing, opening an absolute
explicit source, reusing a declared whole-source extent, accepting a missing
mapped dataset inside an existing file, and treating an empty VDS as nonvirtual.
Each violates a public or repository-established boundary and represents a
distinct implementation mode.

The saved passing solver was separately reviewed. Its per-mapping
reconstruction, current-dataspace lookup, deferred publication, and proactive
empty-VDS probe pass all six additions; it scores 24/24 and is not a false
positive. Four near-passes remain 23/24 on the pre-existing same-file VDS case.

### Resolution

Six focused probes and six isolated mutants were added. New broad
`pytest.raises(Exception)` probes invoke the signature guard first so pristine's
unknown-keyword error cannot satisfy them. Test-only fails 24/24, both combined
orders pass 24/24 and 138/138 base tests, the full lane remains 842 passed, and
all 25 mutants are killed. The prompt, reference, and Dockerfile are unchanged.

The test change invalidates the predecessor 1/5 batch for current calibration;
the revised artifact is 0/10. No cold solver was run.

## 12. Heterogeneous mapping and inherited metadata gaps survived 24 tests

- Date: 2026-08-08
- Source: second completeness audit and `agent-runs3`
- Severity: high
- Verdict: valid verifier gaps; separate long-horizon failure confirmed

### Evidence

Five plausible mutants passed all 24 focused and 138 selected-base cases while
breaking receiver-relative source lookup, heterogeneous filename dispatch,
heterogeneous selection dispatch, per-source whole-dataset spaces, or
nondefault dataset creation properties. The completed ten-run bundle contained
two legitimate passes, seven 23/24 near-passes, and one 22/24 near-pass. One
successful solver manually copied only common DCPL properties and omitted
attribute phase-change thresholds, directly confirming the metadata shortcut.

The public API reference also retained the old `Group.copy` signature and no
description of `relocate_vds`.

### Resolution

Five focused tests and five isolated mutants were added. Each new mutant scores
28/29 and fails only its matching test; all 30 active mutants are killed. The
source-DCPL legitimate patch remains 29/29, while the partial-DCPL predecessor
pass is correctly reclassified at 28/29. Public RST now includes the parameter
and its direct-VDS/`expand_refs` restriction without adding a textual hidden
test.

The exact matrix passes, pristine fails 29/29, the complete lane remains 842
passed, and the cache-deleted image was recreated from scratch. The completed
24-entity batch is historical 2/10 after the artifact change. Both successes
changed one production file, so the problem fails the current long-horizon
file-median requirement despite its nominal solve rate. No cold solver was run.

## 13. Layout reconstruction test pinned an unstated DCPL field set

- Date: 2026-08-08
- Source: 35-group fairness review
- Severity: high
- Verdict: valid unfair-test finding

### Evidence

`test_reconstructed_layout_preserves_creation_behavior` mixed fair observable
round-trip assertions with exact equality for allocation time, fill time,
timestamp tracking, attribute creation-order flags, and attribute phase-change
thresholds. The public layout contract does not enumerate those five fields,
and repository reconstruction conventions do not establish that exact set.
Consequently, the logical test group selected a low-level DCPL-copy strategy
even though alternative implementations could preserve the stated layout
behavior.

### Resolution

Only the five low-level equality checks and their nondefault fixture setup were
removed. Mapped/fill-region reads, dtype, current shape, and maximum shape stay
covered. The independent `Group.copy` property test remains because it checks
that API's established native-copy behavior. The prompt, reference, and
Dockerfile are unchanged.

The exact corrected artifact was replayed from pristine: test-only fails all
41 focused entities while 138 selected regressions pass; both patch orders,
out-of-tree and bare-`pytest` execution, the 842-test offline full lane, and the
exception-taxonomy control pass. All 40 mutants remain killed, with the
phase-change mutant now isolated to the `Group.copy` oracle at 40/41. The three
saved non-cold solver replays remain 29/41, 28/41, and 27/41. This test change
resets the artifact to 0/10.

## 14. Targetless absolute-only layouts bypassed the old-base oracle

- Date: 2026-08-08
- Source: T4 edge-case coverage review
- Severity: medium
- Verdict: valid verifier gap

### Evidence

The prompt requires `source_filename` for layouts originally constructed
without a target filename. The existing targetless test used only an ordinary
relative mapping, so it did not distinguish an unconditional layout-level
guard from an implementation that waived the argument whenever all mappings
were absolute. Absolute mapping relocation otherwise bypasses path rebasing,
making that conditional shortcut plausible.

An isolated implementation of the shortcut passed the predecessor focused
suite 41/41. This is a control-flow boundary between validating layout state
and classifying individual mappings, rather than another absolute-path spelling
fixture.

### Resolution

The existing targetless logical test now also requires omission to fail for an
absolute-only layout. No new test entity or public requirement was added. The
matching mutant fails only that logical group at 40/41; the reference passes,
and all 41 active mutants are killed.

The complete exact-version rerun passes both patch orders, 138 selected
regressions, out-of-tree and bare-`pytest` invocation, the 842-test offline full
lane, and the `RuntimeError` control. Pristine still fails/errors all 41 focused
entities, the three saved solver scores are unchanged, and no cold solver was
run. The revised artifact remains at 0/10.

## 15. Full creation fidelity was covered only through copy integration

- Date: 2026-08-08
- Source: T4 direct-surface coverage review
- Severity: high
- Verdict: valid gap requiring a public-contract clarification

### Evidence

After the earlier fairness correction, the direct
`VirtualLayout.from_dataset()` test checked fill/data, dtype, current shape, and
maximum shape, while exact allocation/fill timing, timestamp tracking,
attribute creation-order, and phase-change settings were checked only through
`Group.copy`. The two are independently public surfaces, and a solver may
implement them separately. Nova 10's demonstrated fresh-DCPL architecture
already omitted phase-change thresholds, while Nova 8's source-DCPL reuse
retained them.

The prior removal was still correct for that artifact: the prompt then said
only "creation behavior" and did not enumerate the low-level field set. Restoring
the hidden assertions without changing the public contract would have repeated
the unfairness.

### Resolution

`meta.md` now explicitly lists dtype, current/maximum shape, fill value,
allocation/fill timing, timestamp tracking, and attribute creation-order and
phase-change settings. The existing direct logical test was strengthened to
compare those named properties after closing the source and creating a clone.
The reference and Dockerfile required no change.

A direct-only phase-change mutant restores the property in copy integration but
not in `from_dataset`; it passed the predecessor suite 41/41 and now fails only
the direct test at 40/41. All 42 active mutants are killed. The complete matrix,
138 selected regressions, 842-test offline full lane, exception control, and
three saved replays were repeated successfully. No cold solver was run, and the
clarified artifact remains at 0/10.

## 16. Direct reconstruction did not pin explicit source-selection geometry

- Date: 2026-08-08
- Source: test-coverage review
- Severity: high
- Verdict: valid verifier gap

### Evidence

The direct missing-source test used only zero-based contiguous source ranges.
It established that `VirtualLayout.from_dataset()` does not open an explicitly
selected absent source, but an implementation could replace every stored
explicit source selection with a new `0:n` selection having the same point
count. Existing offset/stride selection coverage exercised `Group.copy`, not an
independent direct reconstruction implementation.

The prompt already requires the reconstructed layout to reproduce its mappings,
so selection geometry needs no new textual requirement. The old Nova 8, Nova
10, and Nova 6 implementations all retained explicit source spaces in their
copy paths, but none implemented the redesigned direct API.

### Resolution

The existing logical test now reconstructs absent relative and absolute sources
with offset/strided selections, then creates them with decoy values around the
selected elements. A direct-only contiguous-selection mutant preserves copy
integration, passes the predecessor suite 41/41, and fails only the strengthened
test at 40/41.

The reference passes and all 43 active mutants are killed. The complete patch
matrix, 138 selected regressions, 842-test offline full lane, exception control,
and three saved replays were repeated successfully. `meta.md`, `solution.patch`,
and Dockerfile are unchanged; no cold solver was run, and the exact version
remains at 0/10.

## 17. Direct reconstruction did not distinguish a resized VDS's live extent

- Date: 2026-08-08
- Source: T4 current-VDS-extent review
- Severity: medium
- Verdict: valid verifier gap

### Evidence

The public contract explicitly requires the VDS's current and maximum shape,
but the creation-behavior fixture reconstructed the dataset at its original
extent. A frozen-image probe showed the distinct state: after public low-level
`DatasetID.set_extent((5,))`, the still-open VDS reports shape `(5,)` while its
mapping virtual space remains at the creation extent `(3,)`. Reopening the file
normalizes the mapping-space extent to `(5,)`, so reconstruction must occur
before closure and consumption after closure to expose the shortcut.

All three representative old copy solvers used `source.id.get_space()`, the
live VDS dataspace. They did not implement the redesigned direct API, where an
implementation might instead infer shape from the first mapping or mapping
bounds.

### Resolution

The existing creation-behavior test now extends the VDS from three to five,
calls `VirtualLayout.from_dataset()` on the still-open resized object, closes
the source, and verifies a five-element clone with the expanded fill region and
unchanged unlimited maximum shape. No new test entity or prompt rule was added.

A mapping-extent mutant passes the predecessor suite 41/41 and fails only the
strengthened test at 40/41. All 44 active mutants are killed. The complete patch
matrix, 138 selected regressions, 842-test offline full lane, exception control,
and three saved replays pass; no cold solver was run, and the version remains
at 0/10.
