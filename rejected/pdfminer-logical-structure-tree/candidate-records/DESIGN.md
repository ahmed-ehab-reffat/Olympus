# DESIGN - pdfminer-logical-structure-tree

Status: `promoted to problems/; exact v1 gates pass; calibration pending`.

Repository: `pdfminer/pdfminer.six` at
`a18de2a9c479b4c847538500017b449ddaec177e` (2026-03-12).

Production language: Python.

Task type: feature request.

## Solvability forecast

- Start of this design iteration: **2-4 successful solvers out of 10**, a
  fresh-calibration expectation inside the accepted 1-5/10 band. The parser
  already exposes PDF objects and marked-content callbacks, but the logical
  structure graph and content association are absent.
- End of this design iteration: **2-3/10**, still a fresh expectation with no
  observed replay. Source inspection confirmed distinct structure-tree,
  number-tree, content-stream, Form XObject, and layout association boundaries.
  The narrowed contract follows explicit `/K` order and does not invent an
  accessibility reading-order heuristic.

## Public contract and repository evidence

Add a public semantic tagged-PDF structure API, provisionally
`PDFDocument.get_struct_tree()`, with these observable behaviors:

1. Parse `/StructTreeRoot` into a stable logical tree. Preserve structure-child
   order from `/K` across child structure elements, integer MCIDs, marked-content
   reference dictionaries (MCR), and object references (OBJR).
2. Expose both the original structure type `/S` and its `/RoleMap`-resolved
   standard role. Expand `/ClassMap` attributes as metadata without requiring a
   private Python class hierarchy.
3. Resolve the page/resource context for content references, including inherited
   `/Pg`, explicit MCR `/Pg`, and marked content inside Form XObjects. Associate
   page plus MCID references with the text/image/layout content already produced
   by pdfminer.six.
4. Use `/ParentTree` and page/Form `/StructParents` to support reverse
   association where the structure tree uses indirect content references.
5. Terminate deterministically on cyclic structure nodes, cyclic number trees,
   dangling references, and structurally invalid child values. Strict mode may
   raise the repository's PDF syntax/type errors; non-strict mode may retain an
   unresolved reference, but neither mode may recurse forever or attach content
   to the wrong node.
6. Preserve explicit structure order only. The task does not ask pdfminer.six to
   infer visual reading order, repair arbitrary malformed PDFs, or expose a
   prescribed dataclass layout.

The README advertises “Tagged contents extraction,” but the current feature is
only syntactic marked-content XML. `PDFPageInterpreter` handles MP/DP/BMC/BDC/EMC
operators and calls device hooks; the base device hooks are no-ops, while
`TagExtractor` emits nested XML tags. No production code mentions
`StructTreeRoot`, `ParentTree`, `RoleMap`, `ClassMap`, MCR, or OBJR. Conversely,
`PDFDocument.catalog`, indirect object resolution, page layout objects, and a
generic `NumberTree` parser already provide all repository-native seams needed
for a semantic implementation.

The cheapest credible implementation adds a small public structure model, a
safe graph walker, page/Form MCID capture in the interpreter/device path, and a
high-level association pass. Estimate: **300-520 production lines across 4-7
files**, low confidence. Lazy iterators, eager models, and device-assisted
construction are all legitimate.

## Trajectory-informed design gate

Searches covered all local PDF/document, parser, graph, resource-identity,
binary-format, and exact-repository records in `problems/`, `candidates/`, and
`archive/`. Compact evidence read: h5py VDS relocation design/summary, Mido
MIDI range design/summary, Vineflower switch design/summary, Object AIX
summary, Statig summary, and accepted Tablesaw design/summary. No pdfminer.six
semantic-structure trajectory exists.

| Evidence role | Problem / run | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | PcapPlusPlus filtered-copy Nova 1 and Nova 6 | 14/14 plus baseline | Two different section-copy architectures preserved legal producer families and boundary state. |
| Near-pass | h5py VDS relocation Nova 6 | 22/24 plus baseline | Missed same-resource identity despite broad relocation support. |
| Broad failure | PcapPlusPlus filtered-copy Nova 10 | 9/14 plus baseline | Applied an old section's boundary to a new section and rejected legal DSB options. |

The raw evidence suggests that graph traversal alone is not depth. The useful
discriminators are independently produced reference forms, resource context,
identity, and lifecycle/reset boundaries.

## Discriminator ledger

| Observed solver behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| Near-pass missed same-resource identity | Key content by MCID alone | MCIDs are scoped by page or Form content stream | Reuse MCID 0 on two pages and in a Form, then verify distinct owners | resource identity | Any internal key type passes if associations are correct. |
| Broad failure reused an old boundary | Inherit the root page for every descendant | Explicit and inherited `/Pg` apply at their defined graph locations | Structure children switch page context mid-tree | context inheritance | Tests inspect semantic associations, not traversal internals. |
| Broad failure rejected legal producer families | Handle integer MCIDs but ignore MCR/OBJR | `/K` supports all public child forms | Interleave structure nodes, integer MCID, MCR, and OBJR | producer/reference family | Each is a distinct PDF structure form, not fixture multiplication. |
| Passing solvers used different architectures | Require a specific node/dataclass representation | Public tree order, roles, metadata, and associated content define behavior | Normalize the public result before comparison | representation | Eager, lazy, flat-plus-links, or nested models may pass. |
| Parser history includes cycle fixes | Traverse indirect graphs without visited identity | Malformed cycles terminate deterministically | Cyclic structure element and cyclic ParentTree child | termination/security | Stable no-hang behavior is public and architecture-neutral. |
| Marked tags and semantic roles are separate | Treat BDC tag names as the logical structure tree | Structure hierarchy comes from `/StructTreeRoot` | Content tags differ from `/S` and `/RoleMap` role | syntax vs semantics | Detects reuse of existing TagExtractor without semantic parsing. |

## Clause-to-test coverage

| Public requirement | Planned observable test | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Ordered `/K` traversal | Mixed child forms with deliberate non-visual order | no API | returns explicit order | PDF catalog/structure dictionaries |
| Role and class mapping | Custom role plus class attributes | no API | exposes original/resolved role and metadata | `/RoleMap` and `/ClassMap` semantics |
| Page/MCID association | Same MCID on two pages | TagExtractor emits tags only | attaches each page's own text | page-scoped marked-content operators |
| Form association | Form XObject with `/StructParents` | no semantic link | attaches Form content to target node | interpreter already processes Forms/resources |
| ParentTree reverse map | MCR/OBJR reached through number-tree entry | NumberTree exists but unused here | resolves owning structure node | existing `NumberTree` helper |
| Malformed graph | Cycle and dangling child under strict/non-strict settings | potential recursion or absent API | deterministic error/unresolved result | existing parser strictness model |

## Environment and harness preflight

- Eligibility observed 2026-08-20: public GitHub repository, 7.0k stars, MIT,
  active within the last year, entirely Python production code.
- Existing harness has 19 primary pytest modules plus sample PDFs and tool
  integration tests. Contribution command is `make check`; focused tests can
  use `uv run pytest`.
- Minimal tagged PDFs can be assembled as deterministic byte fixtures without
  a network service or proprietary document. A second public PDF reader may be
  used during reference development, but hidden runtime assertions should use
  the public pdfminer API and fixture semantics.
- Exact offline arbitrary-UID Phase A has not run. No downstream gate or solver
  work has started.

## Ownership and similarity audit

Dated 2026-08-20 searches covered `StructTreeRoot`, structure tree, logical
structure, tagged PDF, `ParentTree`, `StructParents`, `RoleMap`, `ClassMap`,
MCR, OBJR, MCID association, all visible issue/PR states, changelog, and
reachable history. No implementation, issue owner, or declined design was
found. Existing tagged-content fixes concern syntactic tag values and output,
not the catalog structure tree.

Local similarity risk is moderate because document/binary parsers are common in
the archive, but no local task reconstructs PDF semantic structure and links it
to independently rendered content. Avoid testing private accessibility policy
or generic PDF repair.

## Design verdict

**Shortlist, 9/10** (eligibility 9, rarity 9, applicability 9, depth 9,
harness 8, safety 8). This is the strongest overall candidate because every
major discriminator has a public PDF object and a repository seam. Before
selection, pass the environment gate and prototype one page-MCID case plus one
Form/ParentTree case to validate the public API boundary.

## Escalation outcome

The candidate passed pristine arbitrary-UID environment validation and both
required end-to-end prototypes, then was promoted to
`problems/pdfminer-logical-structure-tree/`. Immutable v1 passes the exact
environment, gap, fairness, and false-positive gates with 249/249 base tests,
14/14 reference-focused tests, 0/14 pristine-focused tests, and five isolated
mutation survivors closed. The end forecast is 1-3/10, fresh calibration is
0/10, and no independent solver or compatibility replay exists yet. Continue
from the promoted problem records rather than this preliminary dossier.
