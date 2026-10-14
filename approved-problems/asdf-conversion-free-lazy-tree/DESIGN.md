# DESIGN.md - asdf-conversion-free-lazy-tree

Repo: asdf-format/asdf (canonical, 567 stars, BSD-3-Clause, Python 100%), base
`376790c2742c18511a859eb7b1d7d4e55c47b4ff` (main HEAD, last merge 2026-09-11, release 5.4.0 + 21).
Source: hunt #33 composite (lane 1 lazy_tree pass-through write + issue #1795 conversion-free
info/search), spike measured 362 human-eff on one shared kernel.

## Phase 1 - Repo understanding

**Architecture (one paragraph).** asdf reads a YAML tree with binary blocks. `_io.open_asdf` parses
the YAML into a TAGGED tree (`tagged.TaggedDict/TaggedList/TaggedString` carrying `_tag`) plus a
block `Manager` (`_block/manager.py`) that knows every read block, its storage options and how to
write, renumber and update blocks. `open_asdf` then either converts the whole tagged tree to custom
objects (`yamlutil.tagged_tree_to_custom_tree`, one converter call per tagged node) or, with
`lazy_tree=True`, wraps it in `lazy_nodes.AsdfDictNode`, which converts a value only when it is
indexed and records the result in the file's `_tagged_object_cache` (keyed by the tagged node's id,
which is also what keeps YAML anchors/aliases identical after conversion). Writing
(`AsdfFile._serial_write` / `update` -> `_write_tree` -> `yamlutil.dump_tree` ->
`custom_tree_to_tagged_tree`) walks the custom tree with `treeutil.walk_and_modify`, calling each
converter's `select_tag` + `to_yaml_tree` (which always picks the converter's newest tag) and
allocating write blocks for arrays through the block manager (`make_write_block`,
`set_streamed_write_block`; `update` then rewrites blocks in place and renumbers). `info`,
`search` and `schema_info` build a `_node_info.NodeSchemaInfo` tree (breadth first, with
`__asdf_traverse__` / `Converter.to_info` hooks via `_make_traversable`) or walk the tree in
`search._walk_tree_breadth_first`, and `_display` renders it; every walker iterates the lazy tree,
so every node is converted.

**Five subsystems + boundaries.**
1. `lazy_nodes` - lazy containers + the tagged-object cache (conversion on access, alias identity).
2. `yamlutil` / `extension` - converters, `SerializationContext`, custom<->tagged walkers.
3. `_block` - block manager: read blocks, options (storage/compression/save_base), write blocks,
   streamed block, in-place `update` renumbering.
4. `_node_info` + `_display` - info/schema_info tree building and rendering.
5. `search` - `AsdfSearchResult`, filter composition, breadth-first walk, `node`/`nodes`/`paths`.
(`_asdf.AsdfFile` is the facade that wires 1-5: `open_asdf`, `_serial_write`, `update`, `info`,
`search`, `schema_info`.)

**Three high-entanglement zones.**
- `_asdf.py` write path: `_serial_write` (copies the root, which touches every top-level child),
  `_write_tree` (serialization context + finalizer), `update` (block rewrite + renumber).
- The conversion decision shared by the lazy containers (`_convert_and_cache`), the writer walker
  and the info/search walkers: whoever converts must store into the tree + cache or aliases and
  later edits diverge.
- `_node_info.NodeSchemaInfo.from_root_node` + `search._walk_tree_breadth_first`: both decide
  "container or leaf", "seen" (recursion) and "children of" from the CONVERTED object.

**Test framework.** pytest (`testpaths = ["asdf", "docs"]`, `--doctest-modules`,
`--doctest-glob=*.rst`, `filterwarnings = error`), tests under `asdf/_tests/`. Baseline:
2194 passed / 2 xfailed in ~38 s (local venv, numpy 2.5.3).

**Template test file.** `asdf/_tests/test_lazy_nodes.py` (plain module-level `def test_*`, `tmp_path`,
`asdf.config_context()` + in-test `Converter`/`Extension` subclasses, `pytest.warns`).

## Phase 2 - Existing-PR / publicly-solved / SIX-CHECK (run 2026-09-26, scope-lock)

CANON = `asdf-format/asdf` (`gh api repos/asdf-format/asdf -q .full_name`).

1. Literal/class PR search, all states: `lazy`, `lazy_tree`, `lazy tree`, `conversion info`,
   `search conversion`, `info convert`, `without conversion`, `passthrough`, `pass through`,
   `tagged tree write`, `untouched`, `preserve tag version`, `tag version rewrite`,
   `converter not called`, `raw yaml`, `_tagged_object_cache`, `materialize`. Plausible hits pulled
   by DIFF (`gh pr view N --json files`): #1733 (introduced lazy_tree, merged, is base), #1754/#1732/
   #1752/#1728 (closed lazy_tree drafts, `lazy_nodes`/`treeutil`/ndarray only, no writer or
   info/search bypass), #1677 (closed, `tree_type` read-as-tagged option: `_asdf.py`/`yamlutil.py`
   read path + force_raw_types deprecation, no lazy pass-through), #2133 (copy/deepcopy fix),
   #1983 (failed-conversion warning), #1884 (`Converter.to_info`, merged, base), #2141 (memmap
   warning). None implements writing untouched lazy nodes from their tagged form or conversion-free
   info/search. **EXCLUSIVITY: CLEAN.**
2. Issues (all states): `lazy_tree`, `lazy tree`, `info slow`, `search slow`, `conversion write`,
   `write_to converts`, `tag version changes`, `update converts`, `info converts`, `rewrites tags`,
   `tagged`. Only #1795 (OPEN, maintainer perrygreenfield, 0 comments, no design) is in the lane.
   #1598 (tag version mismatch conventions), #1908 (read to plain types), #1787 (ndarray on
   lazy_load=False), #1978 (lazy_tree warnings) read in full: no decline, no "by design", no
   "implemented".
3. Maintainer philosophy: no "prefer not to"/"won't add"/"by design" comment on lazy conversion. The
   `open(lazy_tree=...)` docstring DESCRIBES today's behaviour ("traversing the tree (like is done
   during AsdfFile.info and AsdfFile.search) will result in nodes being converted"); #1795 is the
   maintainer asking for the opposite. The solution updates that docstring.
4. Closed-with-implemented: none.
5. base..main: base IS main HEAD (no newer commits as of 2026-09-26).
6. Functional check on main: all 15 spike probes fail on base (info/search raise through a broken
   converter; write_to makes 5/5 converter calls and re-tags at 1.1.0; update converts; masked
   untouched array loses its mask on rewrite; search-result edit re-tags every Thing).
- PR-author profiling: binggao1230 #2058 (closed, `_node_info.py` ancestor-recursion fix, 16+/9-,
  no conversion logic) and #2069 (`asdf_library` warning). Outside the lane: NOTE only.
- Forks / branches (hunt #33): braingram:itertree (pre-lazy_tree walker rewrite, 2024), lazy_block_index
  (block index). Neither in the lane.

## Phase 3 - Candidates

| Candidate | One-line behaviour | Shape | Files | Raw | Meaningful | Pred. pass | Verdict |
|---|---|---|---|---|---|---|---|
| **A. Conversion-free lazy tree (info/search + write)** | untouched lazy nodes stay tagged through info/search/schema_info/write_to/update; conversions forced by a query go through the tree | O-Pipeline-hard | 5 mod + 1 new | ~440 | 362 measured | 20-35% | **PICK** |
| B. Lane 1 alone (pass-through write) | write_to/update write untouched nodes from tagged form | O-Composite-add | 3 | 214 | 176 measured | 35-50% | dead: under floor + enmime class |
| C. #1795 alone (info/search) | conversion-free info/search | O-Composite-add | 4 | ~250 | 195 measured | 40-55% | dead: under floor, T4 unreachable without writes |
| D. Lazy `validate()` | validate untouched nodes from tagged form | C | 2 | ~60 | ~40 | - | dead: sub-floor, missing arm |
| E. Tag-version-preserving eager rewrite | keep read tag versions for unmodified eager objects | - | - | - | - | - | dead: needs dirty tracking on arbitrary objects, unfair |

Step A (death-class guard) on A: #1 no uniform wrap (the convert/keep rule differs per operation and
node kind); #2 multi-subsystem (lazy_nodes cache, yamlutil writer, block manager, _node_info,
search, _display); #3 RISK - ~8-10 contract sentences; T4/T2/T3 survive full statement, T5/T7 weaken
once stated (priced as FP insurance + LOC); #4 not a port (libasdf C has no converters, no sibling
Python ASDF library); #5 yes, the difficulty is integration timing across walkers + writer.
Not pointwise-decoupled: one conversion decision is shared by four walkers and the writer, and a
local fix on one surface regresses another (measured, mutant M1).
Step B: lead S3 (baseline/edits preserved through a shared chokepoint: the tree + tagged-object
cache), S2 (composition of documented rules), A8 (chain-wide filter precedence).

## 1. Title
Add conversion-free info, search and writes for lazy trees

## 2. Shape
- Shape: O-Pipeline-hard (one new decision threaded through every consumer of the lazy tree:
  writer, block manager, info tree, search walk, display).
- Pass target: 15-35% (design toward the low edge).
- Best agent: Orion/Vega long-horizon; Nova thrashes on the block renumbering.
- Dominant verdict: MISSED_REQUIREMENT (edits lost on write, alias split) + REGRESSION (existing
  lazy/search/info tests).

## 3. Public API surface
No new public names. Behaviour change of existing APIs on `lazy_tree=True` files:
- `AsdfFile.info(...)`, `AsdfFile.search(...)` (+ chained `.search`, `.paths`, `.node`, `.nodes`,
  `repr`, `schema_info`), `AsdfFile.schema_info(...)`
- `AsdfFile.write_to(...)`, `AsdfFile.update(...)`
- `asdf.open(..., lazy_tree=True)` docstring updated.

## 4. Canonical output form
- info rendering of an untouched converted-type node: `name (DeclaredType)` with no value.
- Untouched ndarray: `name (NDArrayType)` (lazy_load=True) or `(ndarray)`/`(MaskedArray)`
  (lazy_load=False) with `shape`/`dtype` children exactly as base prints them.
- search `paths` order: unchanged (breadth first, identifiers as base).
- Written file: untouched node's tag text byte-identical to the input tag (version kept).

## 5. Blind-spot pre-empts
- rule-resolution: "converted the way tree access converts it" (cache + stored in the tree).
- compound-order: "a `value` or `filter_` criterion only sees a node after every `key` and `type_`
  criterion of the whole search chain has accepted it".
- pipeline-placement: none stated (writer placement is the fix, hidden).

## 6. Description draft
See `meta.md` (slice draft). Target <= 480 words; plain prose; one capability.

## 7. File footprint (measured on the spike, hook human-effective)
| Action | Path | Raw | Human-eff |
|---|---|---|---|
| NEW | asdf/_pass_through.py | ~290 | 252 |
| MODIFY | asdf/search.py | ~60 | 43 |
| MODIFY | asdf/_node_info.py | ~45 | 38 |
| MODIFY | asdf/_asdf.py | ~25 | 19 |
| MODIFY | asdf/yamlutil.py | 8 | 6 |
| MODIFY | asdf/_display.py | 5 | 4 |
TOTAL 362 human-eff across 6 files (floor 200, design buffer met).

## 8. Solution outline (one kernel)
- `_raw_items(container)` - raw (unconverted) items of any lazy/tagged container.
- `materialize(owner, container, key, value)` - convert exactly as tree access does: via the lazy
  container, else cache lookup, else a one-item `AsdfListNode`; store the result in the raw container.
- `has_private_blocks(tree, n_blocks)` - at open, decide whether some block is not an ndarray source.
- `PassThrough` (writer side): `view(node)` hands the writer a plain dict/list whose untouched tagged
  children are kept tagged; `_must_convert` (private blocks, ndarray storage change); `_write_ndarray`
  allocates blocks for passed-through arrays and records renumbering so `update` rewrites the
  in-memory `source`; streamed/external/inline handling; `_lazy_owner` (version + closed checks,
  cross-file owners).
- `LazyView` (info/search side): `describe` (descend or leaf, declared type, hide value),
  `children`, `type_of`, `materialize`, `resolved`; `_needs_conversion` (container/traverse
  declared type, multi-type converter, `to_info`), `_array_info` (shape/dtype from raw).
- `_node_info.accepts` - two-phase filter evaluation (every `pre` before any `post`).
- `search._Criterion(pre, post)` - key/type part vs value/filter part.
- `_asdf`: `_serial_write` copies the root's raw mapping (not the converting `copy.copy`), `update`
  writes the renumbered sources back after `blocks.update`.

## 9. Test file outline
Path: `asdf/_tests/test_lazy_untouched_11b889.py` (new, hex suffix).
- Block 1: imports (io, numpy, pytest, asdf, Converter, Extension).
- Block 2: builders - `Thing`, `ThingConverter` (tags 1.0.0/1.1.0, `from_yaml_tree` raises on
  negative values, records what it serialised), `_ext(tags)`, `_roundtrip(tree, tags)`,
  `_info_lines(af)`.
- Block 3: assertion helpers - `_tag_counts(bytes)`.
- Block 4 buckets (slice): info (broken converter, untouched rendering, ndarray shape/dtype),
  search (key, type_, filter two-phase, chained order, node/nodes convert through the tree),
  write (untouched tag versions kept, search-result edit written, alias shared), update (in place,
  arrays readable in session and after reopen).
FINISH adds: private blocks, version change, cross-file owners, streamed/external/inline storage
overrides, masked arrays, multi-type converters, `to_info`/`__asdf_traverse__` descent,
`schema_info`, recursion, OrderedDict, F-10 cells below.

## 10. Forced bounds
None (Python). Converter test doubles must not subclass anything beyond the public `Converter`.

## 11. Trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt (meta) | Test |
|---|---|---|---|---|---|---|---|---|
| T4 | query-forced conversion must go through the tree + cache | F-9 (drop at stage boundary) | S3 | where a conversion is stored | T2, T1 | converting search results locally is enough for every info/search test | "converted the way tree access converts it" | edit a search `.node`, write_to, reopen: edit present, others keep tag |
| T2 | alias identity (one tagged node at 2 places) | F-10 cell | S2 | reference multiplicity | T4 | per-slot conversion splits aliases | same sentence ("every other reference ... same object") | alias touched via search, written, reopen `is` |
| T3 | chain-wide two-phase filter order | F-6 | A8 | predicate order | - | chained search evaluates filters per stage in order | "only after every key and type_ criterion of the whole chain" | `search(filter_).search(key)` with a broken node |
| T1 | `_serial_write`'s `copy.copy(root)` converts top-level children | F-39 (repo helper) | S3 | write entry | T4 | the write loop looks right; the copy upstream already converted | none (fix hidden) | write_to with a broken top-level converter + tag kept |
| T6 | update renumbers blocks; passed-through ndarray `source` must follow | F-47 family | S4 | in-session state after update | T1 | reference to old block index after in-place rewrite | "arrays of untouched nodes are still readable after update" | update then read untouched array in the same session |
| T5/T7 | ndarray info from raw / type_ from declared type | - | B | display | - | stated once, transcribed | stated | info text equality, type_ search on broken converter |

## 11b. Cross-product matrix
| | untouched | touched by access | touched by search/info |
|---|---|---|---|
| **write_to** | tag kept (slice) | converted + written (FINISH) | edit written, others kept (slice, T4) |
| **update** | tag kept, arrays readable (slice) | FINISH | FINISH (T4 x T6) |
| **aliased node** | one anchor kept (FINISH) | FINISH | shared + written (slice, T2 x T4) |
| **chained search** | key-only (slice) | - | filter after chain keys (slice, T3) |
Off-diagonal cells marked FINISH are owed in MODE=FINISH.

Scope audit: "untouched" is per node (a touched container does not touch its children).
Format-noun audit: "node" = one tagged mapping/sequence/scalar as read, including its children
only while they are untouched themselves.

## 12. Tier + category
Olympus; feature-request ("Add ...").

## 13. Predicted pass rate
20-35%. T4/T2/T1/T6 are integration walls in code agents write around (the copy in
`_serial_write`, the block renumber in `update`, the cache); T3 is one stated precedence.

## 14. Quality gates
- [x] Repo understanding 5/5  - [x] PR check clean (commands above)  - [x] closest approved:
  enmime-preserving-edits (class overlap on the write half only, different language/format).
- [x] Title verb-led  - [x] shape declared  - [x] API surface listed (no new names)
- [x] canonical output stated  - [x] 0-1 codebase-inferable (the ndarray type name follows lazy_load)
- [x] LOC 362 measured, 6 files  - [ ] full test outline + F-10 cells (FINISH)
- [ ] flakiness 3x in container (slice validates once; FINISH runs 3x)

## Scope-lock gates (PICK-FILTER 1, 5, 6, 7b, 8 + SIX-CHECK)
- Gate 1 behavioural F2P: PASS - base raises from `info()`/`search()` through a converter nothing
  asked for, rewrites every custom tag at the converter's newest version, drops the mask of an
  untouched masked array on rewrite. These are output differences, not speed.
- Gate 5 cold: PASS - no one building the capability (#1795 0 comments, no PR, lazy code last
  touched by bug fixes #2133/#1983).
- Gate 6 reproduce on base: PASS - probes rerun 2026-09-26 against a fresh clone (see feedback.md).
- Gate 7b exclusivity PR-DIFF: PASS (above).
- Gate 8 defined behaviour: PASS - maintainer-filed #1795; the lazy tree's own conversion-on-access
  model defines "untouched".
- SIX-CHECK: PASS (above).
- Gate 7 dedup (all dirs): no asdf folder in approved-problems/, problems/, rejected/; class
  neighbour enmime-preserving-edits (Go MIME, byte-exact) noted.
- Gate 10 quota: 0/6.

## Why this is not a duplicate
Closest approved: enmime-preserving-edits (Go, write untouched MIME parts back byte-for-byte) and
siliconcompiler-flist-roundtrip (graph round trip). Differentiator: the difficulty here is the
conversion decision shared by the lazy cache, the writer, the block manager and the info/search
walkers (edits made through search must reach the writer; aliases stay one object), not byte
fidelity of a text format.

Predicted iteration cycles: 3.
