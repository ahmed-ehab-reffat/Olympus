# False-positive audit — immutable version 7

Verdict: `pass for the attempted mutation set`.

Repository: `b3eb37b942acb4c7e2d2487706e614aa29b7f9b2`.

Artifact hashes:

- prompt: `27b8bfcb2d3cf4c92d8fefb4e6bd16c4b1f5e2a777a64c383cf863f75ea5cafc`
- tests: `35520d3dfd8392f911f6850f910d048226a601bb9c3964649c098dcc5685631e`
- reference: `42bb5c0434f2d130cc70872f24001d4b4ed3ddd8baa0347c6a2b324cca7e1aee`
- Dockerfile: `08d4df4c43468592168153cc6e92b83a668bd4cb4ec6d1962831f088a5ad0309`

The exact environment gate passed before mutation work. Pristine failed all 36
feature cases behaviorally; the reference passed 36/36 and the complete base
lane at 7,842 passed, 97 skipped, and 1 xfailed.

## Requirement-to-strongest-test map

| Public family | Plausible shortcut families | Strongest behavioral oracle |
|---|---|---|
| queued selection and validation | whitelist, queue overwrite, shallow/partial validation | ordinary types, two calls, five invalid kinds, atomic valid-prefix rejection |
| ancestry and key identity | flatten path, derive key from type/name, retain blocker orphan | nested/root keys, ownership flags, blocked ancestor, reload |
| hard/soft dictionaries | omit hard content, discard matching dictionary, retain source soft links | hard graph, matching merge, soft isolation |
| one source identity across producers | deduplicate only direct repeats, only future discoveries, or only prior queue entries | triple direct repeat plus hard-reference and child-first inline cases |
| conflict lifecycle | unconditional/fixed prefix, direct-only conflict, missing redirect/cleanup | repeated generated collision, resource conflict, exclusive/shared dependents |
| DWD lifecycle | fallback-as-membership, omit default registration/map/owner, leak merged default | reused target, copied default, merged source-default absence |
| XRECORD reachability and mapping | hard-code sampled codes, omit endpoints, discover soft pointers | lower/upper codes, soft-only target, XDATA 1005 |
| unknown opaque graph | shallow raw tags, omit embedded path, call only raw mapper and skip base XDATA | ordinary/embedded hard targets and valid XDATA before/reload |

## Version-7 survivor analysis

The reported duplicate-copy defect comes from three independently plausible
shortcuts. A registry can queue a hard-referenced child even though its
hard-owned parent already supplies an inline clone. It can suppress later
registrations but fail to remove a child selected before the parent. Or it can
remove earlier entries but fail to suppress later discovery. The two final
probes deliberately cross both timing directions while asserting only one
target object and correct reference identity.

The unknown-object override also creates a separate false-positive path. An
implementation may preserve and map unknown raw and embedded groups but omit
the base entity's XDATA mapper. Existing XRECORD group-1005 coverage would still
pass. Adding valid XDATA to the unknown object exposes this omission without
making a soft pointer a discovery edge.

The description rewrite adds no behavior. It retains the same contract in
shorter sections and therefore does not create or remove a discriminator.

## Exact mutation isolation

All 34 isolated plausible mutants imported and ran the complete 36-case file
offline. All failed behaviorally. The predecessor families retained their
version-6 results adjusted to the larger suite, and these four new mutations
were isolated:

| Mutation | Focused result | Strongest detected boundary |
|---|---:|---|
| independently queue a hard-referenced inline child | 34/36 | both XREF/NUM resource-inline cases |
| retain a direct child queued before its hard-owned parent | 34/36 | both XREF/NUM child-first selection cases |
| do not suppress a child discovered after its parent | 34/36 | both XREF/NUM resource-inline cases |
| omit only unknown-object base XDATA mapping | 35/36 | unknown group-1005 live/reload case |

The other 30 mutants cover dependent cleanup, 320 translation, omitted
350/390/480 and 1005 mapping, restricted or over-broad XRECORD discovery,
embedded discovery/mapping, soft-entry registration, DWD registration and
ownership, queue overwrite, key derivation, free-key prefixing, hard-owner
rewrite, shallow unknown data, validation, KEEP redirect, matching dictionary
reuse, a fixed generated candidate, all six upper pointer endpoints, incoming
hard-dependency tracking, and merged-default cleanup. Their focused scores
ranged from 12/36 to 35/36; none survived.

No mutant qualified for complete-suite survivor replay. The unmutated reference
passed that suite. Five independent historical solutions did pass their exact
complete base lanes and scored 35/36, 31/36, 28/36, 26/36, and 24/36. The
35/36 architecture passes every version-7 addition and supplies the materially
different legitimate replay required by the audit.

## Rejected trials

No probe was added for parent-first explicit selection because the hard-
reference fixture already exercises the same later-registration suppression
boundary, while the child-first fixture uniquely exercises removal of an
earlier queue entry. Adding both explicit permutations would repeat an existing
semantic cell.

External-XREF traversal, incomplete CAD formats, graphical objects without a
layout, malformed raw bytes, arbitrary nesting or tag-order permutations,
every interior member of bounded pointer ranges, exact handles, exact generated
keys, target insertion order, private helpers, diagnostics, and performance
deadlines remain rejected as out of scope, equivalent, artificial, or
unsupported by trajectories and repository evidence.

No actionable survivor remains in the attempted set. A zero-survivor result is
evidence for that set, not proof that false positives are impossible.
