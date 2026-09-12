# False-positive audit - Biopython mmCIF biological assembly

Status: **superseded and invalid; package retired 2026-08-14**.

The audit below was executed only in a noncompliant environment and cannot
satisfy the mandatory false-positive gate. Its mutant results are retained as
historical evidence only; they do not support submission or calibration.

## Requirement-to-strongest-test map

| Requirement family | Strongest discriminator |
| --- | --- |
| Public API, new structure, string assembly ID | identity-copy test with integer assembly ID |
| Generation rows and exact asym membership | mixed rows, duplicate row, and `A` versus `AA` |
| Lists and ranges | mixed bare/list/range plus `10-12` |
| Product arity and order | three adjacent groups and noncommuting rotate/translate |
| Every model and stable identity | two models with adversarial source IDs |
| Hierarchy ownership | source/sibling mutation at structure, model, chain, residue, atom, coordinate, and `xtra` boundaries |
| Disorder | separate atom-altloc and residue-variant selection/transform tests |
| Category validation | generation/operator ragged and missing columns plus scalar input |
| Grammar/reference validation | malformed token/group/asym, descending range, duplicate/unknown IDs |
| Lifecycle/numeric validation | no models, later-model missing asym, nonnumeric, and nonfinite transforms |
| Ordinary repository integration | `1A7G.cif` through `MMCIF2Dict` and label-chain parser |
| Input immutability | snapshots on valid, invalid, disorder, and real-fixture paths |

## Method and isolation

Every mutation changes one source branch in an otherwise exact
baseline-plus-reference tree. Each tree is composed with the verifier in the
same order as the evaluator and run offline as UID 10001. A focused survivor
must compile, emit real JUnit, and pass every focused case before it is run
through `Tests/run_tests.py --offline` without the hidden test file. Only a
public, distinct, reference-passing, mutant-failing probe is admitted. After
each artifact revision, the environment gate and complete audit were restarted
at zero.

## Actionable survivors and resulting probes

| Mutant | Why plausible | Pre-probe result | Added discriminator | Final result |
| --- | --- | --- | --- | --- |
| Deduplicate `(asym, operation tuple)` across rows | planners commonly canonicalize duplicate work | focused pass; full 515/515 | repeated identical generation rows produce two occurrences | killed |
| Match source chain IDs by substring in raw asym text | shortcut avoids token parsing | focused pass; full 515/515 | select `AA` when both `A` and `AA` exist | killed |
| Accept an empty source and return an empty result | model loop naturally does nothing | focused pass; full 515/515 | no-model `ValueError` | killed |
| Alias structure/model `xtra` dictionaries | shallow container construction | focused pass; full 515/515 | mapping identity checks | killed |
| Parse a range from its first/last character | works for one-digit fixtures | focused pass; full 515/515 | `10-12` | killed |
| Treat a scalar string as a one-row column | permissive normalization | focused pass; full 515/515 | scalar-column rejection | killed |
| Let missing columns leak `KeyError` | direct mapping access | focused pass; full 515/515 | missing generation and operator columns require `ValueError` | killed |
| Filter empty asym tokens | permissive comma splitting | focused pass; full 515/515 | `A,,A` is malformed | killed |
| Auto-strip a lone opening parenthesis | lenient expression parser | focused pass; full 515/515 | unbalanced expression rejection | killed |
| Alias chain/residue `xtra` after copying | partial deep-copy implementation | focused pass; full 515/515 | mutate one generated chain/residue and inspect sibling/source | killed |

All ten full-suite replays passed the exact final source/reference version. The
suite additions therefore target behavior absent from Biopython's pre-existing
coverage rather than repository regressions.

## Already-discriminated mutants

Fifteen additional plausible shortcuts were rejected without becoming
survivors: first generation row only; first expanded operation only; reverse
product multiplication; at most two product groups; first model only; integer
chain IDs; lost disorder selection; selected-residue-only transform; accepted
nonfinite values; first-model-only asym validation; no string conversion of
`assembly_id`; accepted descending ranges; zip-to-shortest category handling;
duplicate-operator overwrite; and untransposed rotation application.

On the final exact version every one of these 15 and the ten former survivors
compiled and produced a real focused-test failure. The reference passed 30/30,
and the pristine tree failed all 30 behaviorally. No mutation failure was
caused by patch conflict, missing test nodes, collection, startup, permissions,
network, or dependency resolution.

## Rejected and artificial trials

- One mutation per allowed operator punctuation character: arbitrary symmetry,
  and the prompt no longer prescribes a punctuation alphabet.
- Exact generated chain names or output order: private allocation choice.
- Author-chain support: outside the label-asym precondition.
- Very large ranges or assembly sizes: no public performance/resource bound.
- Nested parentheses and random malformed strings: not a distinct documented
  grammar branch after structural and token malformed cases.
- Separate empty-category fixtures: externally equivalent to the already
  required absent-assembly or unknown-operation `ValueError` outcomes.
- Deep-clone arbitrary objects stored as mapping values: stronger than the
  announced independent mappings and hierarchy.

## Exact final results

- Phase A: 514/514 pristine tests offline as UID 10001.
- Exact reference: 515/515 complete pre-existing discoveries after adding the
  new module, without the hidden test file.
- Phase B: baseline base 11/11; baseline feature 0/30 with 30 behavioral
  failures; reference base 11/11; reference feature 30/30; JUnit parity pass.
- Mutation matrix: 25/25 mutants killed; 0 survivors.
- Meaningful pre-probe survivors: each 515/515 on the complete pre-existing
  suite after the reference module was present.
- No domain solver patches exist to replay. Calibration remains 0/10.

Historical result: **superseded local pass**. This does not satisfy the Olympus
false-positive gate because its prerequisite environment verdict is invalid.
