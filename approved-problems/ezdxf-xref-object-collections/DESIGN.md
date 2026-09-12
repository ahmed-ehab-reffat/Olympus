# DESIGN - ezdxf XREF object collections

Status: `accepted and archived 2026-08-16; user-confirmed`.

Repository: `mozman/ezdxf` at
`b3eb37b942acb4c7e2d2487706e614aa29b7f9b2`.

## Public contract and repository evidence

Add an object-selection entry point to `xref.Loader` for non-graphical objects
that are linked through a chain of named `DICTIONARY` entries to the source
root dictionary.  Execution recreates that named ancestry in the target,
reuses the target root and matching management dictionaries, preserves source
dictionary keys and ownership modes, and applies the loader's existing conflict
policy without retaining cross-document references or unattached copies.

The contract includes existing repository-supported object representations:

- ordinary hard- and soft-owned `Dictionary` entries;
- `XRecord` data containing translatable handle tags; and
- non-graphical `DXFTagStorage` objects used for unknown/proxy object types.

The existing public resource-registration and mapping protocols govern pointer
behavior.  Hard pointers and hard owners make referenced objects reachable;
all translatable pointers that participate in the transfer are mapped; and a
mapped hard-owner tag makes the copied child owned by the copied parent.
Graphical tag-storage entities remain non-copyable because the new operation
has no layout destination.

The following repository evidence makes the behavior discoverable rather than
test-invented:

| Surface | Repository evidence | Contract consequence |
|---|---|---|
| `src/ezdxf/xref.py` object-loading note | Since 2023 the module describes reconstructing `ROOT_DICT -> DICTIONARY -> object`, reusing management dictionaries, and translating XRECORD/unknown-object handles. | Named ancestry and pointer translation are repository-owned behavior. |
| `Loader` and `LoadResources` | Public loader methods queue validated selections and use one registry/copy/map execution pipeline. | `load_objects()` queues selections and composes with existing `execute()`. |
| `_Registry.add_handle()` | Hard-referenced non-graphical resources can be discovered recursively; graphical entities are rejected. | Hard reference discovery uses the existing object boundary. |
| `Dictionary` | Hard-owned entries are copied content; soft-owned entries are shared references; keys may differ from object names. | The source dictionary key is identity, and the two ownership modes cannot be flattened. |
| `DictionaryWithDefault` | Missing-key lookup returns the dictionary-wide default, while `dxf.default` is a hard group-340 reference. | Presence checks must not mistake a default value for a real key conflict; a newly copied specialized dictionary must map its default, while a reused target management dictionary retains its own default. |
| `types.is_*pointer()` and `ResourceMapper.map_pointers()` | Group-code classification and translation behavior already exist. | Tests observe resolved graph identity, not a private scanner or hard-coded handle list. |
| `DXFTagStorage` | Unknown types preserve raw subclasses but previously rejected all copying. | Non-graphical unknown objects may be copied with independent tag storage; unknown graphical entities stay unsupported. |

The production-only scope spike implements the complete contract across four
natural production files.  Its zero-context Python-AST counter reports 265 raw
additions, 15 deletions, and **202 strict-effective additions / 11 strict
deletions** after excluding blanks, comment-only lines, and docstrings.  This is
an initial architecture estimate, not a substitute for successful-solver
medians under `CALIBRATION_STRATEGY.md`.

## Trajectory-informed design gate

Searches performed:

- `problems/README.md`, `candidates/CANDIDATES.md`,
  `candidates/REJECTED_REAUDIT_2026-07-26.md`, and the repository-specific
  candidate records;
- `archive/ezdxf-resource-remap/WORKTREE_MANIFEST.md` and its complete preserved
  prototype patch;
- current ezdxf source and full local Git history for XREF, dictionaries,
  object collections, raw object storage, and resource mapping;
- GitHub issue and pull-request searches for XREF object collections, named
  objects, groups, scales, table styles, and owner reconstruction; and
- the compact and raw records for the closest retained document/storage graph
  problem, `3d-tiles-atomic-output`, including raw runs 2 and 3 in
  `archive/3d-tiles-atomic-output/agent-runs.tar.gz`.

No ezdxf solver trajectory exists.  The archived ezdxf external-XREF prototype
was operator-authored and was rejected at 138 changed production lines.  It
recursively embeds external files; it is not an implementation or trajectory
for this in-document named-object operation.  External-file traversal, search
paths, cycles between files, and the incomplete `GROUP` / `SCALE` /
`TABLESTYLE` TODO branches are prohibited padding.

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | `3d-tiles-atomic-output`, `agent-runs/Nova_Nova_3` | 30/30 focused and 869/869 baseline | Traced public graph ownership, staged results privately, and committed through a transaction architecture different from another accepted implementation. Final graph state, not helper layout, is the fair oracle. |
| Near-pass | `3d-tiles-atomic-output`, `agent-runs/Nova_Nova_2` | 26/30 focused and all baseline | Implemented the main stage/publish graph but returned a raw `Error` where the repository required `PipelineError`. Adjacent public lifecycle/conflict behavior can remain independently discriminating. |
| Broad failure | unavailable | no behavioral record | The remaining retained run was blocked by missing offline tooling and is environment evidence only. It is not substituted for a behavioral failure. |

### Version 3 revision gate: local ezdxf solver batch

The earlier statement that no ezdxf solver trajectory existed is retained above
as the version-1 design history. Before revising version 2, the complete local
history under `agent-runs1/` was searched. All eight platform runs have a clean
8,000-test baseline lane and a behavioral focused result; none is an environment
failure. The raw `trajectory.json`, submitted patch, focused JUnit, and run
record were inspected for every run. The raw trajectories and patches for
`Nova_Nova_4`, `Nova_Nova_5`, and `Vega_Nova_1` were then read as representative
near-pass and broad-failure architectures.

| Run | Focused result | Distinct missed behavior |
|---|---:|---|
| `Nova_Nova_1` | 23/26 | soft dictionary isolation; KEEP reference redirect; XREF prefix on a free key |
| `Nova_Nova_2` | 23/26 | hard dictionary content; soft dictionary isolation; XREF prefix on a free key |
| `Nova_Nova_3` | 23/26 | hard dictionary content; soft dictionary isolation; XREF prefix on a free key |
| `Nova_Nova_4` | 25/26 | XREF prefix on a free key |
| `Nova_Nova_5` | 21/26 | soft dictionary isolation; KEEP redirect; XREF prefix on a free key; XRECORD and unknown-object resources |
| `Vega_Nova_1` | 25/26 | XREF prefix on a free key |
| `Vega_Nova_2` | 21/26 | same five behavioral families as `Nova_Nova_5` |
| `Vega_Nova_3` | 21/26 | same five behavioral families as `Nova_Nova_5` |

No legitimate pass exists in this batch, so the required pass category is
explicitly unavailable. `Nova_Nova_4` and `Vega_Nova_1` are materially
different near-passes: the former centralizes named path reconstruction and raw
tag handling in XREF transfer machinery, while the latter extends the entity
resource protocol and builds target paths as a queued command. Both independently
treated XREF/NUM prefixes as conflict resolution rather than unconditional
renaming, and both independently attempted target-side handling of a selected
`DictionaryWithDefault`. `Nova_Nova_5` is the broad-failure representative: it
also extended the entity resource protocol but missed ownership attachment and
reference redirection across five observable families. The raw trajectories
showed repository inspection of `xref.py`, `dictionary.py`, `dxfentity.py`,
`dxfobj.py`, pointer classifiers, object-section APIs, and focused/full tests;
there is no evidence that the shared XREF-prefix miss came from an environment
or patch-application blocker.

The batch solved 0/8, crossing the calibration strategy's mandatory easing
threshold. The revision therefore removes unconditional renaming as a
discriminator: XREF_PREFIX and NUM_PREFIX now generate a unique key only when
the source key is occupied, and retain a free source key. This deletes an 8/8
interpretation trap while preserving conflict handling at both leaves and
obstructing ancestors. It does not relax validation, named ancestry,
hard/soft ownership, KEEP redirection, raw-resource discovery, pointer mapping,
or persistence.

The external review also identified three coverage holes grounded in the
already-public transfer graph. Version 3 separates a 330-only soft pointer from
a 330 pointer whose target participates through a hard edge; separates an
embedded-only hard reference from an ordinary-subclass hard reference; and
requires a newly copied `DictionaryWithDefault` to register and map its
dictionary-wide default through save/reload. These are distinct reachability or
mapping boundaries. They do not add new formats, malformed data, ordering,
private helpers, or a preferred solver architecture. An existing target
management dictionary still retains its target-side default.

Resulting discriminator ledger for this revision:

| Decision | Evidence | Version-3 treatment | Difficulty effect |
|---|---|---|---|
| Free-key XREF prefix | failed by all 8/8 clean runs; existing dictionary-key helpers are conflict-oriented | free keys retain their source key; prefixes remain tested on real conflicts | explicit easing |
| Soft-pointer reachability | prior XRECORD fixture made its 330 target reachable through the same 340 tag | distinct 330-only target must remain unselected; participating soft pointer still maps | closes a false-positive hole without expanding scope |
| Embedded hard discovery | prior embedded 340 shared the ordinary-subclass 340 target | distinct embedded-only hard target must transfer and map | closes an independent producer branch |
| Copied dictionary default | `copy_data()` retains the source `_default`; two near-passes independently recognized target-side default handling | new named DWD maps `_default` and `dxf.default` and survives reload; reused target DWD remains unchanged | fixes a high-severity persistence invariant |

Editing any submission artifact after this record creates a new immutable
version. The eight historical runs are evidence for the design change, not
calibration credit for version 3; calibration restarts at 0/10.

### Version 4 revision gate: local ezdxf solver batch 2

Before revising the version-3 tests, the complete local history under
`agent-runs2/` was searched. All five platform runs have a clean 8,000-test
baseline lane and an ordinary behavioral focused result; none is an environment
failure. The compact run and evaluator records, submitted patches, focused
JUnit, and raw `trajectory.json` action/observation records were inspected for
all five runs. The raw trajectories and patches for the two 25/27 near-passes
(`Nova_Nova_2` and `Nova_Nova_5`) and the 22/27 broadest failure
(`Nova_Nova_3`) were then read in detail. No passing architecture exists in the
batch, so the required legitimate-pass category is explicitly unavailable.

| Run | Focused result | Distinct missed behavior |
|---|---:|---|
| `Nova_Nova_1` | 24/27 | reachable named-resource placement; KEEP redirect |
| `Nova_Nova_2` | 25/27 | soft-owned empty nested dictionary; copied DWD default ownership |
| `Nova_Nova_3` | 22/27 | hard dictionary content; soft-owned empty nested dictionary; reachable named resources; KEEP redirect |
| `Nova_Nova_4` | 23/27 | soft-owned empty nested dictionary; reachable named resources; KEEP redirect |
| `Nova_Nova_5` | 25/27 | soft-owned empty nested dictionary; copied DWD default transfer |

The two near-passes are materially different. `Nova_Nova_2` centralizes a
large path-and-resource transfer command and maps soft dictionary entries in
the entity protocol, but does not copy the empty nested soft entry and leaves a
copied default without the copied dictionary as owner. `Nova_Nova_5` builds
paths in a queued command with separate sets for selected, attached,
management, and default handles; it independently misses the same empty nested
soft entry and fails to retain the new DWD default. The broadest failure,
`Nova_Nova_3`, separates named paths in the registry and transfer layers but
does not attach hard-discovered named resources and also loses hard-owned
content. Raw action records show all three inspected `xref.py`, dictionary copy
semantics, `DXFTagStorage`, `XRecord`, and the pointer classifiers, wrote focused
manual probes, and completed broad pytest runs. Early debugging mistakes in the
raw records were resolved; final evaluator failures are behavioral and not
environmental.

The batch solved 0/5, so another explicit easing is mandatory. Four of five
independent implementations transferred a soft-owned leaf but omitted an empty
nested dictionary stored as another soft entry. Version 4 removes that nested
management-container cell from the public scope and verifier. A selected
soft-owned dictionary must still map its non-dictionary entries to independent
target-side resources, so the cross-document-reference boundary remains. This
is a narrower, evidence-driven scope reduction rather than an assertion-only
deletion.

The external review also found two high-severity false-positive families and a
description-quality issue. The pointer contract will state observable DXF
categories and group-code boundaries directly, without prescribing internal
classification helpers. Existing XRECORD and unknown-object fixtures will cover
soft pointers (330 and 1005), hard pointers (340, 390, and 480), a soft owner
(350), a hard owner (360), and an arbitrary 320-series handle that must remain
unchanged. The KEEP fixture will give the conflicting named leaf a hard-owned
dependent and require that discarded conflict subgraph to contain no live,
unattached imported object.

The final fairness review represents group 1005 through valid XDATA created by
the public XRECORD API. It does not place an XDATA-only code in ordinary raw
subclass or embedded-object tags. This keeps the category boundary observable
without relying on malformed vendor data.

Resulting discriminator ledger for version 4:

| Decision | Evidence | Version-4 treatment | Difficulty effect |
|---|---|---|---|
| Soft-owned empty nested dictionary | failed by 4/5 clean runs despite successful leaf copying | remove the nested-management entry from prompt and fixture; retain target-side soft leaf isolation | explicit easing |
| Reachable named-resource placement | missed by 3/5 and already implied by named reconstruction plus hard reachability | say directly that resource-reachable named objects use the same target path and conflict handling | clarification, no new behavior |
| Copied DWD owner | missed by both 25/27 near-passes | say directly that the copied default belongs to the copied DWD | clarification of existing persistence invariant |
| Pointer classification | 330/340/360 fixtures permit per-code hard-coding; repository classifiers expose stable omitted categories | cover 350, 390, 480, 1005 and unchanged 320 across both opaque producers | closes a high false-positive hole without prescribing helpers |
| KEEP dependent cleanup | current reference destroys only the conflicting leaf after dependent copies enter target OBJECTS | discard the conflicting copy's hard-owned descendants and redirect surviving references consistently | fixes a high-severity graph-lifecycle invariant |

Version-3 calibration results are evidence for this redesign only. The prompt,
tests, and reference changes below create a new immutable version, invalidate all
prior exact-version gates, and restart calibration at 0/10.

### Version 5 review gate: dictionary reuse and referenced conflicts

Before revising the verifier, the repository/candidate indexes, this problem's
design and run records, all five `agent-runs2` compact/evaluator records, and
the relevant submitted patches and raw trajectories were searched again. No
version-4 solver pass exists, so a legitimate pass remains explicitly
unavailable. `Nova_Nova_2` is the 25/27 near-pass representative: it builds one
path plan for directly selected and hard-reachable named resources and applies
leaf conflicts during attachment. `Nova_Nova_4` is a materially different
23/27 architecture that explicitly maps a source dictionary to a matching
target dictionary and merges content through a reuse path, although it misses
placement of hard-reachable named resources. `Nova_Nova_3` remains the broad
22/27 failure: it reconstructs only direct selections and therefore misses both
resource placement and related conflict redirection. All three passed clean
baseline lanes and completed normal source inspection and local pytest work;
none was environment-blocked.

Pinned repository behavior independently supports both review findings.
`Dictionary.copy_data()` copies hard-owned children inline, `post_bind_hook()`
binds those children into target OBJECTS, and existing owner-path reconstruction
already reuses a dictionary at a matching target key. The reference's direct
leaf path instead sends a selected dictionary through generic KEEP conflict
discard, deleting its copied contents. Separately, the public contract already
says that named objects reached through resource references use the same
conflict handling as direct selections, but the verifier exercises XREF/NUM
leaf conflicts only for directly selected objects.

Resulting discriminator ledger for version 5:

| Decision | Evidence | Version-5 treatment | Difficulty effect |
|---|---|---|---|
| referenced leaf under XREF/NUM conflict | N2 plans direct and reachable named leaves together; N3/N4 miss reachable placement; existing tests cover only direct conflict leaves | reach a named leaf solely through a hard reference, preoccupy its target key, and require the existing target plus one uniquely named imported leaf with the surviving pointer mapped to that import | closes a distinct selection-vs-resource producer branch without fixing a key format |
| directly selected matching dictionary | N4 independently implements dictionary reuse; repository hard-dictionary copying binds content inline; current generic KEEP branch discards the clone | under KEEP, preserve the matching target dictionary and its existing entry, merge the selected hard-owned dictionary's copied content, ownership, audit, and reload state | fixes a high-severity public reuse invariant without requiring N4's helper layout |

These checks do not introduce a new object type, naming scheme, traversal depth,
or private implementation mechanism. They distinguish two separately executed
branches of the existing public contract. The previous prompt-only prose edit
and this verifier/reference revision invalidate the version-4 exact hashes;
version 5 starts at calibration 0/10.

### Version 6 review gate: collision depth and retained resources

Before revising the verifier, the repository and candidate indexes, this
problem's `DESIGN.md`, `LEVELS.md`, `RUNS.md`, `ERRORS.md`, and `SUMMARY.md`,
all compact records under `agent-runs1/` and `agent-runs2/`, and the submitted
patches and raw action records for `agent-runs2/Nova_Nova_2`,
`Nova_Nova_4`, and `Nova_Nova_1` were searched again. No legitimate version-5
solver pass exists, so that evidence category is explicitly unavailable.
`Nova_Nova_2` is the near-pass architecture that plans selected and reachable
objects together and delegates generated names to the repository helper.
`Nova_Nova_4` is the materially different reuse architecture: its raw record
shows direct inspection of `xref.py`, `dictionary.py`, `types.py`, focused
manual graph probes, and a complete pytest run. `Nova_Nova_1` is the broader
resource-tracking architecture and explicitly records hard-resource scopes.
All three passed their historical complete baseline lanes; their shortcomings
are behavioral rather than environmental.

Pinned repository behavior supports the four review findings. The public
`get_unique_dict_key()` behavior is iterative and avoids every occupied key,
while a single fixed prefix would violate the prompt's uniqueness requirement.
The pointer classifiers use inclusive category endpoints through Python ranges
ending at 340, 350, 360, 370, 400, and the explicit `(480, 481)` tuple; the
public prompt names those endpoints. `DictionaryWithDefault` registers its
default as a distinct hard resource, so destroying a temporary merged clone
must also resolve that unnamed copy. Finally, the registry deduplicates one
source handle across all discovery paths. Ownership by a discarded source
leaf is therefore not sufficient reason to destroy a copied child that another
participating object still references through a hard edge.

Resulting discriminator ledger for version 6:

| Decision | Evidence | Version-6 treatment | Difficulty effect |
|---|---|---|---|
| generated-key collision depth | repository helper iterates until a free key; prior solvers commonly delegate to it, but a fixed one-shot prefix satisfies the current oracle | import two same-key conflicts sequentially and require two distinct imported keys without asserting either spelling | closes a plausible uniqueness shortcut without prescribing the naming scheme |
| pointer range endpoints | stable repository classifiers and explicit public ranges; current fixtures exercise only lower representatives | add 339, 349, 359, 369, 399, and 481 to valid XRECORD data and observe reachability, mapping, and owner behavior | closes inclusive-boundary hard-coding while reusing the existing graph fixture |
| shared hard-owned descendant | registry deduplication gives one copy to owner and hard-reference discovery; current recursive cleanup looks only at source ownership | discard the conflicting owner under KEEP but retain the shared child when another selected holder hard-references it | fixes a high-severity retention boundary without requiring dependency-table internals |
| merged dictionary-wide default | DWD default is an unnamed registered hard resource; temporary copied DWD is destroyed after target dictionary reuse | preserve the target DWD default and require the unused copied source default to be absent before and after reload | fixes a high-severity lifecycle leak without asserting temporary-copy order |

These checks are observable consequences of the existing public contract. The
collision test learns no key format, the endpoint tags are valid repository
categories, and both lifecycle tests inspect only the final audited graph.
They add no new object type, recursion depth, malformed data, private helper,
or timing requirement. This verifier/reference revision creates immutable
version 6 and restarts calibration at 0/10.

### Version 7 review gate: inline hard-owned identity and unknown XDATA

Before revising the verifier, the repository and candidate indexes, this
problem's compact records, all local run summaries, and the submitted patches
and raw action records for `agent-runs1/Nova_Nova_4` and
`agent-runs2/Nova_Nova_1`, `Nova_Nova_2`, `Nova_Nova_4`, and `Nova_Nova_5`
were searched again. No legitimate version-6 solver pass exists, so that
evidence category remains unavailable. The strongest historical architecture,
`agent-runs1/Nova_Nova_4`, scores 31/32 on version 6 and centralizes path and
resource registration. `agent-runs2/Nova_Nova_4` is a materially different
reuse-oriented implementation, while `agent-runs2/Nova_Nova_1` is the broader
failure representative with explicit resource-dependency tracking. Their raw
records show direct inspection of dictionary copy/mapping code, opaque object
storage, pointer classifiers, manual graph probes, and complete pytest runs.
The reported failures are behavioral, not environment failures.

Pinned repository behavior independently exposes both review boundaries.
`Dictionary.copy_data()` clones hard-owned children inline, and
`post_bind_hook()` binds those clones into the target OBJECTS section.
`Dictionary.get_handle_mapping()` then publishes the source-child to
inline-clone mapping. A separately registered copy of the same source child can
overwrite that mapping in `CopyMachine.copy_block()`, which turns one source
object into two apparent leaf candidates during conflict handling. This can
happen either when an inline child is reached through a sibling's hard pointer
or when the child is also selected directly. Separately, XDATA is stored and
mapped by the base entity resource protocol, including group 1005. The unknown
object implementation calls that base protocol in addition to mapping its raw
subclass and embedded tags, but the existing unknown-object fixture has no
XDATA and therefore cannot observe that producer path.

Resulting discriminator ledger for version 7:

| Decision | Evidence | Version-7 treatment | Difficulty effect |
|---|---|---|---|
| hard-referenced inline child identity | hard-owned dictionary copying and resource registration are separate repository producers; the current mapping can be overwritten by a second copy | select one hard-owned dictionary whose child hard-references a sibling and require one target sibling under XREF/NUM, with the pointer resolving to that inline copy | closes a high-severity graph-identity bug without requiring registry or mapper internals |
| directly selected inline child identity | `load_objects()` accepts repeated reachability, while a selected hard-owned dictionary already supplies its child inline | select the child before its dictionary and require one target object and one named entry under XREF/NUM | separates removal of an earlier direct selection from later resource suppression without asserting target insertion order or generated names |
| unknown-object XDATA mapping | base `DXFEntity` owns valid XDATA mapping; unknown raw subclass and embedded containers are a separate override path | attach group 1005 through the public XDATA API to a non-graphical unknown object and verify its target handle before and after reload | closes a distinct producer-mode gap using valid public data |
| maintainer-style description | review found dense but substantively correct prose | organize the same contract into shorter sections and sentences | presentation-only easing; no behavioral discriminator is added or removed |

The identity checks observe only final graph cardinality, dictionary membership,
reference resolution, audit state, and persistence. They do not require the
reference registry set, registration order, copy-machine layout, or a generated
key spelling. The XDATA check uses the public API and an already-supported
pointer category. This gate authorizes the version-7 prompt, verifier, and
reference revisions; all version-6 exact verdicts are invalidated, and
calibration restarts at 0/10.

## Discriminator ledger

| Observed solver behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| Existing XREF code dispatches a few resources by concrete class. | Add more `isinstance` branches for visible TODO types. | Any selected, supported non-graphical object with a dictionary-only path is attached through its source ancestry. | Select ordinary nested public objects, execute, inspect target dictionaries, audit, and save/reload. | Generic owner reconstruction | Does not require helper names or the rejected incomplete object types. |
| Dictionary keys need not equal an object's internal name. | Use `dxf.name` or a type-specific collection API as leaf identity. | The source dictionary key is retained subject to the existing conflict policy. | Store a named object under an independent key and resolve it by that key after transfer. | Dictionary identity | Observes the public mapping, not insertion order or handles. |
| Hard and soft dictionaries have different copy models. | Recursively clone every entry, or preserve source references in soft copies. | Hard content is independently copied; soft non-dictionary links resolve only to target-side copies with no source-document references. | Exercise both ownership modes, soft leaf isolation, audit, and round-trip. | Ownership/resource boundary | Crosses two separately implemented repository branches rather than permuting fixtures. |
| The default dictionary returns its default on a missing lookup and `copy_data()` retains the source default object. | Treat every missing key as a conflict or leave a copied DWD pointing into the source document. | Only actual keys conflict; reused target defaults stay unchanged; a newly copied DWD maps its default to a target-side object. | Exercise reused and newly copied DWDs, then audit and reload the new copy. | Specialized container semantics and persistence | Public type, handle, fallback identity, and ownership are observed without prescribing mapper structure. |
| Existing conflict policies redirect resources or rename occupied keys. | Attach an orphan, overwrite regardless of policy, or rename free entries. | `KEEP`, `XREF_PREFIX`, and `NUM_PREFIX` retain their public conflict semantics at leaves and obstructing ancestors; free named keys are retained. | Exercise free and occupied leaves plus ancestor conflicts, then inspect dictionary state and copied references. | Conflict and mapping lifecycle | Does not require a particular generated suffix or helper. |
| XRECORD and unknown objects preserve opaque tags. | Copy raw tags without correct reachability, or scan only ordinary subclasses. | Hard references become reachable, soft-only references do not; all participating translatable handles map; hard owners point to the copied parent. | Use distinct soft-only, hard-reachable, embedded-only hard, and owned targets, then audit and reload. | Raw representation/resource discovery | Separates producer and pointer classes using stable repository classifiers, not tag-order permutations. |
| A queueing API can partially accept a sequence before a later invalid item. | Queue valid prefixes or accept unnamed/foreign objects. | Validation is all-or-nothing for a call and accepts only source-bound, non-root objects with named dictionary ancestry. | Mix valid and invalid inputs, catch `EntityError`, execute, and observe no import from the rejected call. | API boundary / partial mutation | Error type and no-partial-queue behavior follow existing loader validation style; exact text is not asserted. |

## Clause-to-test coverage

| Public requirement | Planned observable test | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| `Loader.load_objects()` and validation | Valid nested selection plus mixed invalid sequences | method absent | valid call queues; invalid call raises `EntityError` atomically | sibling loader methods validate source ownership before queueing |
| Reconstruct named ancestry and keys | absent nested dictionaries and root-level leaf | method absent | keys, owner links, and ancestry survive | 2023 source design note and `Dictionary.find_key()` |
| Hard/soft ownership and identity | hard descendants, matching target hard dictionary, soft non-dictionary link, inline child reached by hard reference, child-first direct selection | method absent | target-only copies, merged hard content, correct ownership, one copy per source identity | current dictionary copy and registry semantics |
| Existing and copied specialized dictionaries | reused DWD target/default, selected new DWD/default, merged source-default cleanup | method absent | target default remains; copied default maps; unused source default is absent after reload | public specialized dictionary type, fallback, group-340 reference, and no-unattached-copy rule |
| Conflict policies | free/occupied direct leaf, generated-candidate collision, resource conflict, wrong-type ancestor, exclusive/shared dependent | method absent | unique keys, redirect, no orphan, and retained participating hard resource | explicit contract and public dictionary/hard-reference behavior |
| XRECORD pointer resources | soft-only/participating targets plus lower and upper category endpoints | tags copied but not registered/mapped | complete stated ranges map; hard endpoints discover; ownership follows category | stable pointer classifiers and mapping protocol |
| Unknown object storage | distinct main and embedded hard references plus valid XDATA 1005 | copy rejected | independent copy, every target mapped, round-trip | `DXFTagStorage`, base XDATA protocol, and source XREF note |
| Regression boundary | unknown graphical tag storage and ordinary dictionary copying | current behavior passes | remains unchanged | existing entity and dictionary tests |

## Environment and harness preflight

- Exact repository pin:
  `b3eb37b942acb4c7e2d2487706e614aa29b7f9b2`.
- Initial Python base image digest:
  `python@sha256:62eafe52c91cad83c2c74e630bfde917da8c253673e695665d454def84fc9a13`.
- Two incomplete dependency images were quarantined after PySide6 collection
  exposed missing `libEGL.so.1` and then `libxkbcommon.so.0`.
- The corrected official-base image pins `libegl1`, `libgl1`, `libdbus-1-3`,
  and `libxkbcommon0`.  Image ID
  `sha256:8e527ddf4541d8e3e0d6ac43747390416f253703ae955792484a50729ace4d96`
  ran the untouched checkout offline as UID/GID 4242.
- Phase A result: **8241 passed, 54 skipped, 1 xfailed** across `tests` and
  `integration_tests`, with real JUnit and no runtime network.
- Correct-source focused prototype lane: **166 passed** across XREF,
  dictionary, and XRECORD suites; production diff check passes.

Version 7 passed the exact approved-base gate offline as UID/GID 10001. The
pristine and reference base lanes each reported 7,842 passed, 97 skipped, and
1 xfailed; pristine produced 36 behavioral feature failures and the reference
passed 36/36 with identical testcase identities. Thirty-four isolated mutants
were killed. Five representative prior solver patches passed their complete
base lanes and scored 35/36, 31/36, 28/36, 26/36, and 24/36 on the version-7
feature lane. The 35/36 architecture passes all four version-7 additions. The
final reference changes 471 production lines across four files and removes 17.
See `ENVIRONMENT.md`, `GAP_ANALYSIS.md`,
`FAIRNESS_ANALYSIS.md`, and `FALSE_POSITIVE_AUDIT.md`.

## Accepted disposition

The user confirmed platform acceptance on 2026-08-16. The accepted submission
is the immutable version-7 artifact set recorded in the archive manifest.

The saved version-7 Nova batch solved 0/5, with focused results of 29/36,
32/36, 35/36, 34/36, and 34/36; every baseline lane passed. All five
implementations missed KEEP-conflict cleanup, while the other misses varied.
This remains useful difficulty evidence, but it is not rewritten as a
successful calibration result. Platform acceptance is user-confirmed rather
than inferred from that incomplete batch.

## Design verdict

Retain the accepted design rating of **7/10**. The prior trajectory-driven
easing remains in place, and the exact environment, gap, fairness, and
false-positive gates pass. Inline hard-owned identity composes correctly with
both hard-resource discovery and earlier direct selection, and valid
unknown-object XDATA is covered without prescribing mapper structure.

Do not expand the task with external XREF recursion, graphical group copying,
incomplete CAD formats, arbitrary malformed proxy bytes, exact handles,
insertion order, or private helper structure. The accepted artifacts are
frozen; any later edit would create a different, unaccepted version.
