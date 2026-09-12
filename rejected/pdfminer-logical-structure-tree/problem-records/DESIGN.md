# DESIGN - pdfminer.six logical structure tree

Status: `submission artifacts validated; fresh calibration pending`.

Repository: `pdfminer/pdfminer.six` at
`a18de2a9c479b4c847538500017b449ddaec177e` (2026-03-12).

## Iteration forecast

- Start of candidate design: **2-4 successful solvers out of 10**.
- End of candidate design: **2-3/10** after source and trajectory review.
- Start of promotion/hardening: **2-4/10** for the exact version being authored.

All three figures are fresh-calibration expectations, not compatibility replay
results, and are inside the current accepted 1-5/10 band. The promotion
forecast is supported by the passing scope spike: 366 strict nonblank,
non-comment production additions across six files, with separate structure
graph, number-tree, content-stream, Form-resource, and layout-binding seams.
Fresh exact-version calibration remains 0/10 until a platform batch is run.

## Public contract and repository evidence

Add a public semantic tagged-PDF API that returns a logical structure tree and
associates its content references with the layout objects already produced by
pdfminer.six. The public result must preserve `/K` order across structure
elements, integer MCIDs, MCR dictionaries, and OBJR dictionaries; expose both
original and `/RoleMap`-resolved roles; expand `/ClassMap` attributes; preserve
page and Form resource identity; and use `/ParentTree` for reverse association.
Malformed cycles and dangling references must terminate deterministically.

The task explicitly excludes visual reading-order inference and general repair
of malformed PDFs. Internal traversal, caching, and model construction remain
implementation choices.

Repository evidence:

| Surface | Pinned behavior | Contract consequence |
|---|---|---|
| `PDFDocument.catalog` and `getobj()` | Catalog and indirect objects are public parser state. | `/StructTreeRoot` can be traversed without a second parser. |
| `PDFPage.create_pages()` | Pages expose object IDs, resources, and inherited page attributes. | Page identity and inherited `/Pg` can be resolved repository-natively. |
| `PDFPageInterpreter` | Handles MP/DP/BMC/BDC/EMC and recursively renders Form XObjects. | Semantic association can reuse existing content-stream lifecycle. |
| `PDFDevice` / `PDFLayoutAnalyzer` | Device hooks receive marked-content operators and construct `LTItem` objects. | Associations can expose the actual layout objects rather than copied text. |
| `NumberTree` | Generic number-tree behavior already exists. | `/ParentTree` is a repository-supported tree family, with added cycle safety required here. |
| `TagExtractor` | Existing tagged extraction is syntactic XML only. | BDC tag names are not substitutes for semantic `/S` and `/RoleMap` roles. |

## Trajectory-informed design gate

Searches performed before test authoring:

- all local problem and candidate indexes for PDF, document graph, parser,
  resource identity, marked content, structure tree, and number-tree work;
- compact records for h5py VDS relocation, Mido MIDI range handling,
  Vineflower fallthrough switches, Object AIX archives, Statig transitions,
  Tablesaw Arrow streams, and PcapPlusPlus filtered copies;
- representative raw solver trajectories and patches for the retained
  PcapPlusPlus passing/broad-failure runs and the h5py near-pass; and
- the pinned pdfminer.six source, reachable Git history, issue/PR terms, and all
  occurrences of `StructTreeRoot`, `ParentTree`, `StructParents`, `RoleMap`,
  `ClassMap`, `MCR`, `OBJR`, and `MCID`.

No pdfminer.six semantic-structure solver trajectory exists. The closest raw
records are used only for general shortcut families; repository evidence owns
the actual PDF contract.

| Evidence role | Problem / run | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | PcapPlusPlus filtered-copy, Nova 1 and Nova 6 | 14/14 focused plus baseline | Different copy architectures both preserved producer families and boundary state; final behavior was independent of helper layout. |
| Near-pass | h5py VDS relocation, Nova 6 | 22/24 plus baseline | Broad relocation support still keyed identity too coarsely and missed same-resource identity. |
| Broad failure | PcapPlusPlus filtered-copy, Nova 10 | 9/14 plus baseline | Reused an old section boundary and rejected another legal producer family. |

## Prototype evidence

Phase A used the approved Python base at digest
`sha256:6ddc78fc675e6cd3a63b60fc63d87eea35a479f503a44a89cf92923abe905dd8`.
Three failed image attempts were quarantined: missing Clang, missing the
separate libFuzzer runtime, and an arbitrary-UID-inaccessible `uv` symlink.
The corrected image copied the `uv` binary to a system-readable path and
installed `clang` plus `libclang-rt-14-dev`.

The passing pristine run used image ID
`sha256:7f10c5f10d2057069abc1763c501b71f2f3d625653d1fe4445640248ef2aa3d1`,
network disabled, UID/GID 10001, Python 3.12.13, uv 0.11.19, and pytest 9.0.2.
Ruff format/check, mypy over 65 source files, and all 249 tests passed; JUnit
reported 249 tests, zero failures, zero errors, and zero skips.

The production-only scope spike changed six production files and contained 366
strict nonblank, non-comment additions. Its two deterministic raw-PDF probes
passed:

1. a page integer-MCID with custom role and class attributes resolved to the
   actual rendered `LTChar` objects for `Hello`; and
2. a Form XObject with `/StructParents 1`, no explicit content child, and a
   `/ParentTree` entry resolved to the Form stream, containing page, and actual
   rendered `LTChar` objects for `Form`.

The complete prototype tree passed Ruff, mypy, `git diff --check`, and all 251
tests. Production diff identifier:
`117c6d098dfda0f783f15e1b792c263e4dd1dfbd4a2e26872d6696128570fbe0`.

## Discriminator ledger

| Evidence-backed shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|
| Key content by MCID alone | MCIDs are scoped by page or Form stream. | Reuse MCID 0 across pages and a Form and assert distinct object/page/content identities. | resource identity | Any internal compound key or traversal passes. |
| Reuse the root page for descendants | Explicit and inherited `/Pg` change at their graph location. | A nested element changes page context while a sibling inherits the prior page. | context inheritance | Tests inspect resolved public identities, not walker state. |
| Support only integer MCIDs | `/K` admits structure elements, integers, MCRs, and OBJRs in explicit order. | Interleave all four and inspect normalized order. | producer/reference family | Each is a standard observable PDF child form. |
| Treat BDC tags as roles | Semantic roles come from `/S` and `/RoleMap`. | Use a BDC tag different from both original and mapped semantic roles. | syntax versus semantics | Prevents reuse of `TagExtractor` as the tree model. |
| Parse forward children only | `/ParentTree` connects page/Form content back to owners. | Omit explicit content child and recover page and Form associations in reverse. | reverse association | Does not prescribe eager versus lazy graph construction. |
| Follow indirect objects recursively | Cycles and dangling references never recurse forever or misassociate content. | Structure and number-tree cycles terminate in strict and non-strict modes. | malformed graph / security | Allows repository-style errors or unresolved results. |
| Expose parsed metadata only | Content references associate with existing layout objects. | Assert object identity and text/image association, not serialized summaries. | parser/render integration | Leaves public object model internals flexible beyond the stated API. |

## Clause-to-test coverage plan

| Public requirement | Planned observable test | Pristine behavior | Prototype/reference behavior | Fairness evidence |
|---|---|---|---|---|
| Public entry points and absent tree | document/high-level APIs on untagged and tagged PDFs | API absent | `None` or semantic tree | existing high-level/document API style |
| Ordered mixed `/K` | structure node, integer, MCR, OBJR, nested element | API absent | explicit PDF order retained | PDF structure dictionary semantics |
| Role/class metadata | custom role and direct/class attributes | API absent | original/mapped roles and attributes exposed | catalog maps |
| Page identity | same MCID on two pages; explicit/inherited `/Pg` | API absent | content stays in its page context | page object IDs and attrs |
| Form identity | explicit MCR and reverse ParentTree association | API absent | stream/page/MCID and layout objects agree | existing recursive Form renderer |
| OBJR identity | annotation/object reference in ordered children | API absent | referenced object and page identity exposed | standard OBJR dictionary fields |
| Safe malformed handling | cycles, dangling refs, invalid child type | API absent | finite result or repository error | `settings.STRICT` parser convention |

## Design verdict

**Approved for hidden-test authoring.** The trajectory gate, pristine
environment gate, and two required end-to-end prototypes are complete. Test
authoring may begin. No exact-version environment, gap, fairness, or
false-positive verdict is implied; those gates must run after all four
submission artifacts are frozen.

## Promotion/hardening outcome

The immutable version-1 artifacts now pass the exact environment, gap,
fairness, and false-positive gates. The reference changes six production files
with 492 raw additions and 18 deletions; a zero-context counter reports 444
nonblank, non-comment added lines, or approximately **439 strict-effective
additions** after excluding the five public docstring lines. This remains a
reference architecture estimate, not a substitute for successful-solver
medians.

The 10-test predecessor exposed three plausible survivors: root-only
ParentTree traversal, inherited-only MCR page handling, and text-only layout
capture. The 13-test intermediate exposed two more: omission of vector layout
objects and first-only attribute-array expansion. All five passed the complete
249-test upstream suite. Each final mutant scores 13/14 and fails only its
targeted public discriminator; the reference scores 14/14 and the pristine
tree produces 14 real behavioral failures.

End-of-hardening forecast: **1-3 successful solvers out of 10**, a
fresh-calibration expectation inside the accepted 1-5/10 band. It is supported
by the six-file / approximately 439-effective-line cross-layer reference and
the five independent predecessor survivors. No compatible pdfminer.six solver
patch exists, so an observed compatible-solver replay result is unavailable;
the passing reference and failing mutants are not presented as solver replay.
Fresh calibration remains **0/10** until a new exact-version batch is run.
