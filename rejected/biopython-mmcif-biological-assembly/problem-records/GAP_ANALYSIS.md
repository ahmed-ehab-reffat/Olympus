# Gap analysis - Biopython mmCIF biological assembly

Status: **superseded and invalid; package retired 2026-08-14**.

The audit below ran only after an environment verdict that did not satisfy the
Olympus base-image and `/app` requirements. It is retained as historical test
design evidence but cannot approve this problem or support calibration.

## Immutable version

- Repository: `biopython/biopython`
- Pin: `c9489604d1d9607602ca9199a3852c1219ed330f`
- `meta.md`: `50b9d93fa9c87397a9fdd4b3350f1d18b413316d4d879053567bf12ffb45b9a7`
- `test.patch`: `a2df8d2ea209f4b903f6dc7a23db2554507aa8053f0da6e6c2cde5a7160004f3`
- `solution.patch`: `849cd80349f976d8e35092c6b9c4ae3b1a53431dddd9d7f1a649dcfb4db565c8`
- `Dockerfile`: `3998a8e2e610aad537817b0280b60fd9b875f8e4ba60427a3090156be6d09bf1`
- Focused discovery: 30 pytest entities; pristine 0/30, reference 30/30.

## Atomic requirement map

| Public obligation | Strongest black-box coverage | Coverage |
| --- | --- | --- |
| Public `Bio.PDB` callable, string-form assembly ID, and fresh `Structure` | identity assembly called with integer `1` | direct |
| Use every matching generation row and every occurrence | mixed matching/nonmatching rows plus repeated identical rows | direct |
| Select exact comma-delimited label-asym IDs | `A`/`AA` prefix collision and real `auth_chains=False` fixture | direct |
| Bare IDs, comma lists, ascending ranges, and character codes | mixed list/range test and `R`, `S`, `T`, `U`, `V` operators | direct |
| Multi-digit inclusive bounds | `10-12` with three distinguishable translations | direct |
| Any number of adjacent product groups | noncommuting two-group and three-group expressions | direct |
| Right-to-left product application | asymmetric point under rotation and translation | direct |
| Every model, retaining IDs and serials | two models with distinct IDs, serials, and coordinates | direct |
| Deterministic collision-free string chain IDs | adversarial `A`/`A_2`, repeated call, and cross-model comparison | direct |
| Preserve hierarchy and copy all ordinary data independently | header/structure/model metadata plus chain, residue, atom, coordinate, and sibling mutations | direct |
| Preserve and transform all disorder alternatives and selection | separate `DisorderedAtom` and `DisorderedResidue` probes | direct |
| Reject malformed category shapes with `ValueError` | generation/operator raggedness, scalar column, and missing column in both categories | direct |
| Reject bad expressions and asym lists | empty token, unbalanced group, descending range, malformed asym list | direct |
| Reject duplicate/unknown references and absent assembly | isolated duplicate operator, unknown operator/asym, and absent assembly cases | direct |
| Reject empty source and bad numeric transforms | no-model, nonnumeric, and nonfinite cases | direct |
| Leave both inputs unchanged | valid synthetic, every rejection case, real fixture, and metadata snapshot | direct |
| Work with ordinary repository mmCIF data | `MMCIF2Dict` plus `MMCIFParser(auth_chains=False)` on `1A7G.cif` | direct |

## Dimension and equivalence-class audit

| Dimension | Independently meaningful cells | Result |
| --- | --- | --- |
| Category family | assembly-generation versus operator-list columns | Both have ragged and missing-column probes; shared sequential/empty semantics are grouped. |
| Expression form | bare/list, numeric range, parenthesized product, more than two groups, malformed token, malformed grouping | Every cell is direct; multi-digit range has a separate parser-boundary oracle. |
| Transform state | identity, translation, rotation, scale, noncommuting composition, nonnumeric, nonfinite | Direct across synthetic cases; coordinate comparisons do not prescribe matrix storage. |
| Selection | matching/nonmatching assembly, exact asym token, repeated row occurrence, missing asym | Direct, including the model-boundary failure case. |
| Model lifecycle | empty, one model, multiple models, selected chain missing from a later model | Direct. |
| Hierarchy family | ordinary entity, disordered atom, disordered residue | Direct; both selected state and unselected alternatives are observed. |
| Ownership boundary | source versus result, generated sibling versus sibling, metadata mapping versus consumer | Direct at structure, model, chain, residue, atom, coordinate-array, and `xtra` levels. |
| Identity allocation | initial collision, generated collision, repeated call, corresponding models | Direct without testing literal chain-ID spelling. |
| Data source | synthetic dictionary and repository `MMCIF2Dict` fixture | Direct. |

Empty generation columns are black-box equivalent to an assembly with no
matching row, and empty operator columns are equivalent to referenced operators
being absent: each must raise `ValueError`, and the existing cases already
observe that outcome. Separate empty fixtures would not distinguish a new
public behavior. Likewise, larger ranges exercise resource size rather than a
new grammar branch after multi-digit bounds are covered.

## Gap challenge and admitted probes

Ten plausible mutants compiled, passed the then-current focused suite, and
passed all 515 pre-existing tests (514 original discoveries plus the new
module's doctest): generation-occurrence deduplication, substring asym
selection, accepting an empty structure, aliasing structure/model `xtra`,
single-digit range bounds, scalar-column acceptance, leaking `KeyError` for
missing columns, filtering empty asym tokens, auto-balancing a missing close
parenthesis, and aliasing chain/residue `xtra`.

Each survivor produced a distinct public probe. The final suite adds repeated
row multiplicity, exact asym membership, `10-12`, empty-model rejection,
structure/model metadata identity, scalar rejection, missing columns in both
categories, malformed asym and grouping cases, and chain/residue ownership.
The reference passes all 30 cases; each targeted mutant fails its intended
probe on the final immutable version.

Fifteen additional one-branch mutants were already rejected: first row only,
first operation only, reverse product multiplication, two product groups only,
first model only, integer chain IDs, lost disorder selection, selected-residue
transform only, accepted nonfinite transforms, first-model-only asym
validation, no assembly-ID string conversion, accepted descending ranges,
zip-to-shortest categories, duplicate-operator overwrite, and wrong rotation
orientation. All 25 mutations were isolated source changes and produced real
focused-test failures, not collection, build, permission, or harness errors.

## Rejected additions

- Exact generated chain spelling or output iteration order: explicitly left
  open and unnecessary for identity/cardinality/coordinate behavior.
- Punctuation-by-punctuation operator IDs: the earlier punctuation alphabet
  was removed from the prompt; character codes are already covered without an
  arbitrary symmetry matrix.
- Author-chain structures: outside the explicit label-asym input contract.
- Nested parentheses, descending-range permutations, huge ranges, and random
  malformed strings: no new documented grammar or implementation boundary.
- Deep-copying arbitrary objects stored inside header or `xtra` values: the
  public requirement is independent mappings/hierarchy objects, not an
  unrestricted object-graph serializer.

Historical result: **superseded local pass**. No direct or indirect requirement
cell had an actionable surviving mutant in the non-platform run. This result
does not satisfy the Olympus gate.
