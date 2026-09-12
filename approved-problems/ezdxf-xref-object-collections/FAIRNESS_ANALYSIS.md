# Fairness analysis — immutable version 7

Verdict: `pass`.

Repository: `b3eb37b942acb4c7e2d2487706e614aa29b7f9b2`.

Artifact hashes:

- prompt: `27b8bfcb2d3cf4c92d8fefb4e6bd16c4b1f5e2a777a64c383cf863f75ea5cafc`
- tests: `35520d3dfd8392f911f6850f910d048226a601bb9c3964649c098dcc5685631e`
- reference: `42bb5c0434f2d130cc70872f24001d4b4ed3ddd8baa0347c6a2b324cca7e1aee`
- Dockerfile: `08d4df4c43468592168153cc6e92b83a668bd4cb4ec6d1962831f088a5ad0309`

The exact environment gate passed first. Pristine and reference lanes ran
offline from read-only mounts as UID/GID 10001, emitted real JUnit with the same
36 feature identities, and passed the complete base suite where required.

## Predicate audit

| Predicate family | Public or repository provenance | Implementation freedom retained |
|---|---|---|
| reject graphic, foreign, root, unnamed, and detached selections atomically | explicit Selection section and existing loader validation style | no message, validation order, command type, or staging representation asserted |
| append calls and deduplicate one source identity | explicit queued execution and one-copy requirement | no queue class, batching, registry set, or copy order asserted |
| reconstruct paths, keys, ownership mode, and cloning flags | explicit Target paths section and pinned `Dictionary` behavior | eager plans, recursive attachment, delayed finalization, and mapping tables all pass |
| reuse matching dictionaries and preserve target DWD defaults | explicit target-path/default rules | merge may be eager, deferred, recursive, or source-mapped |
| remove unused defaults and owned conflict copies while retaining shared ones | explicit no-unattached rule and “retain when used elsewhere” qualifier | reference counts, graph tracing, ownership scans, and transactional staging all pass |
| retain free keys and create unique conflict keys | explicit conflict rules | no spelling, prefix format, starting index, or helper is asserted |
| apply conflicts to direct and resource leaves | explicit same-behavior requirement | one shared placement phase is not required |
| collapse inline, direct, and resource producers to one copy | explicit one-copy rule plus repository hard-owned inline copy behavior | no registration order or authoritative mapping data structure is prescribed |
| preserve hard and soft dictionary semantics | explicit ownership section and pinned copy/resource protocols | nested soft management containers remain out of scope |
| discover hard targets but not soft-only targets | explicit opaque-handle reachability rules and stable code categories | no scanner, traversal order, or classifier helper asserted |
| map complete stated ranges but not 320-series handles | explicit group ranges | no internal range table or mapping implementation prescribed |
| preserve XRECORD and unknown raw/embedded/XDATA data | prompt and public entity/XDATA APIs | no vendor schema, malformed byte representation, or private container required |
| audit and reload successfully | explicit Persistence section and public document operations | only graph identity, keys, payloads, ownership, and resolved references are observed |

## Version-7 data and boundary review

The inline resource fixture uses public hard-owned dictionaries and XRECORD
group 340. It requires the final `A` pointer to resolve to the sole target `B`
and searches target OBJECTS by a public payload. It does not inspect handles,
copy tables, temporary clones, or the spelling of a key that an incorrect
implementation might generate.

The explicit duplicate fixture supplies `[child, dictionary]` to the documented
sequence argument. Input order is public, but target insertion order is not
asserted. The oracle requires one named `CHILD` and one object carrying its
payload. A conforming implementation may pre-deduplicate the sequence, retract
an earlier queue entry, or redirect mappings after copy.

The unknown-object XDATA fixture calls public `set_xdata()` with valid group
1005. Its target is already participating through a hard raw tag, so the test
checks translation rather than reachability through a soft pointer. It observes
the mapped target handle before and after a public save/reload operation and
also verifies that the source XDATA is unchanged. This does not prescribe
whether base-class or unknown-specific code performs the mapping.

All earlier boundary reviews remain valid: generated names are checked only for
uniqueness, pointer endpoints are valid members of the published ranges, 320
values remain arbitrary handles, shared descendants are retained only through
a surviving hard edge, and a merged DWD is judged only by its final audited
graph. No malformed input, exact diagnostic, private field, or timing limit is
used.

## Architecture and harness evidence

Five historical implementations composed cleanly, passed exact complete base
lanes, and scored 35/36, 31/36, 28/36, 26/36, and 24/36. The strongest was
written before the version-7 tests and passes all four new cases through a
different path/resource architecture. The remaining failures are ordinary
public graph mismatches rather than verifier assumptions or startup failures.

There are no private imports, LOC assertions, exact diagnostics, exact target
handles or generated keys, target insertion-order checks, random schedules,
writable-source assumptions, network calls, or product deadlines. The complete
base lane and focused lane use the repository's ordinary pytest entry point and
a generous environment runtime. Verdict: `pass` for the exact hashes above.
