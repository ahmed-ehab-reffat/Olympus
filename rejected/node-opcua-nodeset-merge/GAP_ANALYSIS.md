# Exact-version gap analysis

Status: `pass for review revision 6; calibration 0/10`.

Repository pin: `e233d906138995583f42359831d1908e3cb005e7`.

Artifact binding: `meta.md` `164e5deeaaa8`, `test.patch` `4605db209fca`,
`solution.patch` `7bda8973c435`, and Dockerfile `3a7c65b9b4fb`. Full hashes
are frozen in `ARTIFACTS.sha256`.

## Atomic public requirements

| Public requirement | Strongest black-box evidence | Distinct boundary |
|---|---|---|
| Export a nonempty namespace selection through the `node-opcua-address-space` package root | valid one- and two-namespace runtime exports, empty rejection, and isolated TypeScript consumer compilation against the advertised declarations | API/cardinality/packaging |
| Reject repeats and mixed address spaces | repeated and mixed-owner calls reject | identity/ownership |
| Include every selected model and all and only selected-owned nodes | two-model document plus fresh reload of every selected-owned fixture node; single-selected dependency case | projection/inventory |
| Preserve each model's URI, version, publication date, and its own required models | semantic model inspection before and after reload plus ModelUri-scoped RequiredModel URI/version/date sets | model metadata/scoping |
| Keep unselected dependencies declared but do not export their nodes | dependent-only export loaded beside an independently generated empty dependency NodeSet | selected/external boundary |
| Use one namespace translation for all emitted identities | cross-model reference, type definition, NodeId value, QualifiedName value, custom structure-field DataType, and nested structured encoded value survive reload | independent serializer branches |
| Preserve relationships between selected namespaces | custom-reference XML ownership plus fresh-load browsing, and a separate cross-model `HasSubtype` fresh-load oracle | reference kind/direction/ownership |
| Produce caller-order-independent bytes | both input permutations compare byte-for-byte | determinism |
| Reload and stably re-export | fresh load followed by equal re-export | lifecycle |

The removed legacy-output sentence is not an atomic public requirement in
revision 4. `LNEX5` and `LNEX8` remain ordinary baseline regression coverage
because they are existing repository tests, not hidden feature predicates.

## Coverage dimensions

The suite covers selection cardinality `0`, `1`, and `2`; duplicate and
mixed-owner invalidity; selected-to-selected and selected-to-unselected
resource boundaries; direct export, load, and re-export lifecycle states;
caller permutations; model declarations and per-model metadata; relationship
ownership; and four independently serialized identity surfaces: reference
targets, type definitions, NodeId values, and QualifiedName values.

Relationship kinds are grouped only when they share serializer behavior. The
custom non-hierarchical `ConnectsTo` edge and inverse-canonical `HasSubtype`
edge remain separate because `_dumpReferences` implements different branches
and later drops forward subtype edges. Runtime package loading and TypeScript
declaration resolution are likewise separate because `package.json` advertises
different `main` and `types` entry points.

Node class permutations that use the same exporter iterator and serializer are
grouped rather than multiplied into fixtures. The selected fixture includes
objects, variables, an object type, and a custom reference type. Method and view
fixtures would exercise the same selected-node union without introducing a new
public boundary. Arbitrary namespace-index numbers, XML quote styles, attribute
orders, filenames, and batching are deliberately not coverage cells.

## Mutation-guided closure

The audit challenges first-model-only and first-namespace-nodes-only exports,
caller-order dependence, selected edge loss and duplication, single-selection
rejection, transitive dependency-node export, missing external declarations,
lost selected-model metadata, omitted RequiredModel version/date metadata,
independently untranslated NodeId and QualifiedName values, and a repository
legacy byte-order regression. Revision 4 adds independently isolated mutants
that restore generic endpoint ownership for selected cross-namespace subtype
edges and omit the public declaration signature.

An early relationship assertion counted only one endpoint spelling and allowed
a duplicate-edge mutant to survive. The final test derives the document's
namespace indexes and counts both semantic endpoint representations. An early
reference version also added a selected-model dependency that the repository's
existing dependency calculator did not require. A simpler legitimate
architecture passed the public behavior, so that augmentation and its proposed
discriminator were removed rather than frozen as private policy.

The exact-version mutation result is recorded in `FALSE_POSITIVE_AUDIT.md` and
`verify/mutation-results.txt`. All fourteen feature/API mutants fail named
focused behavior. The one repository-regression mutation that survives the new
feature file is caught by the directly relevant pre-existing exporter cases and
by the complete package audit lane. No actionable survivor remains.

Review revision 2b added one distinct probe: omitting RequiredModel Version and
PublicationDate while preserving its ModelUri. The omission crosses separate
schema fields promised by the public metadata clause; it is not another model
fixture. The targeted mutant and final exact result are recorded in the false-
positive audit. Alias translation remains direct semantic coverage through the
custom reference type's successful fresh-address-space resolution.

Revision 3 changes no behavioral coverage cell. Its distinct evaluator probe
compares baseline and reference feature testcase identities. The exact rerun
found the same eleven names on both sides, with all eleven named failures on
pristine and all eleven passes on reference; neither side produced an extra
hook or startup node. The zero-based thirteen-mutant audit retained the same
12 focused kills and one full-suite legacy kill, so no gap was introduced by
moving participant-API access out of shared setup.

Revision 4 admits two distinct review probes. The revision 3 reference passes
the prior eleven tests but fails exactly the package-root declaration and
cross-namespace subtype cases. The corrected reference passes 13/13. Each new
isolated mutant fails only its corresponding test, and the complete zero-based
15-mutant audit leaves no actionable survivor. Method/view node permutations,
additional subtype classes, and both possible XML endpoint spellings were
rejected as equivalent fixtures rather than new semantic boundaries.

## Revision 5 exact-version coverage audit

The review finding at `nodeset_to_xml.ts:926` identified two ungrouped cells.
Structure-definition field DataTypes use `_dumpStructureDefinition`, whereas a
nested ExtensionObject uses `_dumpVariantInnerExtensionObject` recursively.
Neither is equivalent to the existing scalar NodeId/QualifiedName Variant case.

Two black-box probes were admitted. One fresh-loads selected namespaces whose
custom structure field points at a custom DataType in the other namespace and
checks the resolved field DataType. The other fresh-loads a selected value
namespace beside an independently loaded, unselected custom structure model and
observes the nested structure's DateTime leaf. The dependency remains declared
without exporting its nodes. Both derive namespace indexes from the loader and
do not inspect serializer implementation or literal XML layout.

The prior complete reference passes both probes. An untranslated
structure-field-DataType mutant fails only the first, and a skipped nested
ExtensionObject-recursion mutant fails only the second. The final exact gate is
15 named pristine failures versus 15/15 reference passes with identity parity.
All seventeen plausible defects were rerun from zero; sixteen public defects
are focused kills, while the one legacy-ordering survivor fails `LNEX5` and
`LNEX8` in the complete pre-existing suite.

Verdict: `pass` for the exact revision 5 artifacts. Any submission-artifact
change invalidates this mapping and verdict.

## Revision 6 exact-version coverage audit

The selected inventory cell was previously indirect: model count, relationship
ownership, and fresh-load checks did not observe namespace 1's independent
`i=1` object. The existing reload testcase now resolves all four selected-owned
fixture nodes after translation: both namespace 1 objects, its custom reference
type, and the namespace 2 object. An object-inventory mutant that retains only
objects participating in nonstandard references passes the predecessor but now
fails only this testcase.

The per-model dependency cell was likewise indirect because RequiredModel tags
were flattened across the document. The existing dependency testcase now finds
each selected Model by ModelUri, inspects only its child RequiredModels, and
checks the exact semantic URI set plus version/publication-date metadata. Alpha
requires the standard and external models; beta requires only the standard
model. A plausible global-union-per-model mutant passes the predecessor but now
fails only this testcase.

No new testcase, fixture, node-class permutation, or participant base case was
added. The final exact environment result remains fifteen named pristine
feature failures versus 15/15 reference passes. The zero-based nineteen-mutant
audit kills all eighteen public/API defects in named focused tests; the one
legacy-ordering survivor fails exactly LNEX5/LNEX8 in the complete pre-existing
suite. No actionable gap survived.

Verdict: `pass` for the exact revision 6 artifacts. Any submission-artifact
change invalidates this mapping and verdict.
