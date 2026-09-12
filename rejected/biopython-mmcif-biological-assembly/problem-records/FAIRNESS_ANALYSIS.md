# Fairness analysis - Biopython mmCIF biological assembly

Status: **superseded and invalid; package retired 2026-08-14**.

The analysis below depends on an environment verdict that did not satisfy the
Olympus base-image and `/app` requirements. It is retained as historical
reasoning only and is not an approval of the rejected package.

## Predicate provenance

| Logically distinct rejection predicate | Provenance | Implementation freedom preserved |
| --- | --- | --- |
| Importable public callable and fresh `Structure` | Explicit prompt; `Bio.PDB` already re-exports peer helpers | No module, helper, class, or parser layout is inspected. |
| Assembly ID is compared in string form | Explicit prompt | Any conversion point or lookup representation may be used. |
| Matching row/asym/operator multiplicity and coordinates | Explicit “every occurrence” contract and PDBx assembly-generation semantics | Coordinate multisets and counts are tested; internal batching and provenance are not. |
| Exact comma-delimited label-asym selection | Explicit prompt and `MMCIFParser(auth_chains=False)` repository behavior | No author-chain support or private parser state is required. |
| List/range/product grammar and right-to-left composition | Explicit prompt and the official PDBx operation-expression definition | Any tokenizer, matrix convention, affine representation, or direct coordinate algorithm may pass. |
| Multi-model identity and deterministic unique string chain IDs | Explicit prompt; duplicate sibling IDs are rejected by `Entity.add` | Literal IDs and output spelling are ignored. Only uniqueness, type, stability, and corresponding-model equality are checked. |
| Header, hierarchy, coordinate, and `xtra` independence | Explicit prompt; public Biopython hierarchy APIs expose those objects | `Entity.copy`, builders, reconstruction, and custom deep-copy strategies are all accepted. Nested arbitrary values inside mappings are not required to be recursively cloned. |
| Disorder alternatives, selected child, occupancy, and altloc | Explicit prompt and public `DisorderedAtom`/`DisorderedResidue` APIs | No child-dictionary layout beyond the public wrapper interface is prescribed. |
| `ValueError` on absent, malformed, non-sequential, ragged, duplicate, unknown, empty-model, and numeric-invalid inputs | Explicit rejection list | Exact error text and validation order are ignored; only exception class and lack of input mutation are observed. |
| Real `MMCIF2Dict`/label-chain integration cardinality | Explicit input surface and repository fixture `Tests/PDB/1A7G.cif` | No hard-coded output chain names, private lookup tables, or source traversal order is asserted. |
| Inputs unchanged | Explicit prompt | Tests compare public hierarchy state, coordinates, and metadata rather than implementation internals. |
| Base and feature lanes build offline as UID 10001 | Published harness contract and environment gate | Source is copied to writable `/tmp`; no writable checkout, home, network, root privilege, or external service is required. |

The product-order rule is also documented by the official PDBx dictionary and
assembly example:

- <https://mmcif.wwpdb.org/dictionaries/mmcif_ma.dic/Items/_pdbx_struct_assembly_gen.oper_expression.html>
- <https://mmcif.wwpdb.org/docs/sw-examples/python/html/assemblies.html>

## Negative data and determinism audit

All malformed inputs are created by taking the same valid, public
`MMCIF2Dict`-shaped mapping used by positive tests and violating one announced
constraint: delete a required column, make peer lengths differ, replace a list
with a scalar, duplicate or remove a referenced ID, insert an empty token or
unbalanced group, reverse a range, or use nonnumeric/nonfinite components. No
foreign serializer bytes, magic encoding, private field, or unspecified
validity rule is used. Exact exception messages are never compared.

There are no timeouts, sleeps, concurrency races, progress markers, absence
sampling, network calls, external processes, or quiescence assumptions in the
focused tests. Coordinate expectations are deterministic NumPy operations on
small synthetic structures. The one repository fixture is pinned with the
repository.

## Architecture replay and implementation freedom

No Biopython or molecular-assembly solver patch exists in local history, so no
materially different domain implementation is available to replay. The
reference is therefore not treated as architectural provenance. The suite was
instead challenged with 25 isolated architectures/shortcuts spanning parsers,
matrix composition, builders, identity allocation, disorder traversal, and
validation. The black-box assertions do not inspect any of those choices.
Analogical archived trajectories informed the design gate only and were not
used as substitute correctness replays.

The following freedoms are intentionally preserved:

- generated chain-ID spelling and traversal order;
- parser/tokenizer and matrix storage/orientation strategy;
- eager plan versus streaming construction, provided failures expose no
  partial result and inputs remain unchanged;
- copy, builder, or hierarchy reconstruction architecture;
- internal provenance, caching, batching, and helper/module layout; and
- error wording and which invalid condition is detected first.

## Corrections and rejected complaints

During the audit, the prompt's arbitrary punctuation enumeration for operator
IDs was replaced by the implementation-neutral “numeric or character codes.”
No punctuation-specific probe remains. Header mapping independence, already
asserted by the suite, was made explicit in the prompt. Missing-column,
malformed-asym, malformed-grouping, and hierarchy-`xtra` probes were admitted
only after their public mutants passed both the focused and complete
pre-existing suites.

Potential complaints about label-asym input, repeated generation-row output,
right-to-left products, string chain IDs, and `ValueError` are rejected because
each is stated directly in the public task and has repository or format
provenance. Complaints seeking exact chain names, author-chain support, nested
parentheses, arbitrary punctuation, or deep cloning of objects stored inside
metadata values are accepted as valid warnings; the suite does not require
them.

Harness verdict: pristine base 11/11, reference base 11/11, pristine feature
30/30 behavioral failures, reference feature 30/30 passes, and identical JUnit
testcase identities. `test.patch` and `solution.patch` own disjoint paths.

Historical result: **superseded local pass**. This does not satisfy the Olympus
fairness gate because its prerequisite environment verdict is invalid.
