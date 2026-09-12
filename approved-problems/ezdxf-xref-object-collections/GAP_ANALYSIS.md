# Gap analysis — immutable version 7

Verdict: `pass`.

Repository: `b3eb37b942acb4c7e2d2487706e614aa29b7f9b2`.

Artifact hashes:

- prompt: `27b8bfcb2d3cf4c92d8fefb4e6bd16c4b1f5e2a777a64c383cf863f75ea5cafc`
- tests: `35520d3dfd8392f911f6850f910d048226a601bb9c3964649c098dcc5685631e`
- reference: `42bb5c0434f2d130cc70872f24001d4b4ed3ddd8baa0347c6a2b324cca7e1aee`
- Dockerfile: `08d4df4c43468592168153cc6e92b83a668bd4cb4ec6d1962831f088a5ad0309`

The exact environment gate passed before this audit. Pristine produced 36
behavioral feature failures; the reference passed all 36 cases and the complete
7,842-test base lane.

## Atomic requirement map

| Public obligation | Independent cells and boundaries | Strongest black-box coverage |
|---|---|---|
| queue selections and compose with `execute()` | one/multiple calls; repeated direct selection; ordinary leaf types | root/nested objects, `DictionaryVar`, two calls, triple duplicate |
| validate the whole call atomically | graphic, foreign, root, unnamed, detached branch; valid then invalid | five rejection parameters plus valid-prefix atomicity |
| reconstruct named ancestry and keys | root/nested; missing/reused/obstructed path; direct and hard-resource producer | root/nested/key cases, flags, matching dictionaries, leaf and ancestor conflicts |
| preserve dictionary lifecycle | hard inline content; matching hard dictionary; soft non-dictionary resources | hard graph/reload, matching merge, soft isolation, clean audit |
| preserve DWD lifecycle | reused target; newly copied default; temporary merged source default | target-default identity, copied default mapping/owner, unused-default absence and reload |
| apply conflict policies | KEEP/XREF/NUM; direct/resource leaf; free key; generated collision | redirect/no-orphan, distinct generated imports, resource conflicts |
| create one copy per source object | direct repetition; inline child then explicit selection; inline child then hard-reference discovery | triple selection and the two XREF/NUM inline-identity tests |
| retain or discard dependencies correctly | exclusive hard-owned child; shared hard-referenced child; merged default | final object presence, mapped holder, audit, reload |
| discover only through hard edges | XRECORD ranges/endpoints; raw ordinary/embedded tags; soft-only target | distinct hard targets, embedded-only target, absent soft-only target |
| map participating pointer categories | 320; 330/339/1005; 340/349/390/399/480/481; 350/359; 360/369 | unchanged arbitrary handle, mapped endpoints, hard-owner rewrite |
| preserve opaque producers and serialization | XRECORD; unknown subclass, embedded groups, and XDATA | independent data, mapped graph, source unchanged, live/reloaded assertions |
| retain graphical boundary | ordinary graphic and graphical tag storage | selection rejection and unchanged OBJECTS rejection |

Direct selection and hard-resource discovery remain distinct producer modes.
Hard-owned dictionary copying introduces a third source of an object copy: the
dictionary clone owns its children inline. Version 7 crosses both registry
timing directions. The hard-reference case discovers B after its parent has
already made B inline; the direct-selection case queues the child before the
hard-owned parent and requires the earlier queue entry to collapse into the
inline copy. Both policies are exercised without asserting a generated name.

Unknown-object raw subclasses, embedded groups, and base-entity XDATA use
separate repository paths. Version 7 adds valid group-1005 XDATA to the unknown
object and checks it before and after reload. This is distinct from the existing
XRECORD XDATA case and from unknown raw tag mapping.

The earlier easing remains unchanged: soft-owned dictionaries transfer
non-dictionary entries, but no nested soft management container is required.

## Exact mutation challenge

Thirty-four isolated plausible mutants imported and ran the complete 36-case
focused file offline as UID/GID 10001. All failed behaviorally; none survived
to require complete-suite replay.

| Mutant family | Focused result | Distinct shortcut challenged |
|---|---:|---|
| omit dependent cleanup sweep | 33/36 | orphan/shared/default cleanup |
| translate 320 or omit 350/390/480 | 34/36 each | adjacent or representative pointer category collapsed |
| omit XDATA 1005 globally | 34/36 | both opaque XDATA producers omitted |
| restrict XRECORD discovery to 340/360 | 35/36 | extended hard reachability omitted |
| omit embedded raw discovery or mapping | 35/36 each | embedded producer branch omitted |
| discover through XRECORD soft pointers | 35/36 | soft-only target imported |
| omit soft-entry registration | 34/36 | target-side soft resource omitted |
| omit DWD registration or copied-default ownership | 35/36 each | unnamed default lifecycle omitted |
| overwrite queue | 35/36 | previous valid call lost |
| derive keys from DXF type | 12/36 | dictionary-key identity lost |
| prefix free XREF keys | 32/36 | conflict-only rename rule lost |
| omit hard-owner rewrite | 33/36 | copied-child ownership omitted |
| shallow-copy unknown tags | 35/36 | source and target storage aliased |
| skip named-path validation | 33/36 | invalid selections accepted |
| KEEP cleanup without redirect | 35/36 | surviving pointer mapped to null |
| disable matching-dictionary reuse | 34/36 | hard/DWD matching merge lost |
| return one fixed generated key | 34/36 | occupied generated candidate overwritten |
| omit endpoint 339, 349, 359, 369, 399, or 481 | 35/36 each | one inclusive endpoint omitted |
| omit incoming hard dependencies | 35/36 | shared hard-owned child destroyed |
| omit merged-default cleanup | 35/36 | unused source default retained |
| independently queue hard-referenced inline child | 34/36 | resource discovery duplicates inline content |
| retain explicit child queued before parent | 34/36 | earlier direct selection duplicates inline content |
| fail to suppress child discovered after parent | 34/36 | future resource/direct registration duplicates inline content |
| omit only unknown-object base XDATA mapping | 35/36 | unknown 1005 remains source-side while XRECORD succeeds |

The last four mutations isolate every version-7 addition. Five materially
different historical solutions also passed their complete base lanes and
scored 35/36, 31/36, 28/36, 26/36, and 24/36. The 35/36 architecture predates
the tests and passes every version-7 case, which demonstrates that the probes
do not require the reference registry design.

## Admitted and rejected probes

Admitted probes are the two inline-copy producer cases and unknown-object XDATA
mapping. They are public, repository-grounded, reference-passing, pristine-
failing, and each kills a targeted plausible mutant. Selecting the child before
its parent was retained because it crosses the independently implemented
“remove an earlier queue entry” branch; the sibling hard-reference case covers
the opposite “suppress a later discovery” branch.

Rejected additions remain external-XREF traversal, unfinished CAD formats,
graphical copying without a layout, malformed vendor bytes, arbitrary tag
orders or nesting depths, every interior code in an already bounded range,
exact handles or generated-key spelling, target object insertion order, private
helpers, diagnostics, and performance limits. These are outside the contract,
equivalent to stronger existing cells, or unsupported by repository evidence.

No actionable gap survived the attempted exact-version analysis. This is
evidence for the attempted matrix, not proof that no gap can exist.
