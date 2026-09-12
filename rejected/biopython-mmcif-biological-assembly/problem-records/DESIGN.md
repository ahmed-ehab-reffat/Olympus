# DESIGN - Biopython mmCIF biological-assembly materialization

Status: `rejected and retired 2026-08-14; calibration 0/10; historical design record only`.

## Terminal retirement decision

This package is retired because its Dockerfile uses neither an approved
Olympus base image nor `WORKDIR /app`. The purported environment pass was
therefore not evaluator-equivalent, invalidating every downstream gate verdict.
In addition, Olympus did not recognize the repository's
`LicenseRef-Biopython-License-Agreement`, so the hard license gate remains
unresolved. No solver runs began. The four submission artifacts are retained
unchanged solely as the rejected version's audit snapshot.

This decision supersedes every pass or escalation statement later in this
historical record. Reopening the idea would require explicit confirmation that
the license is permitted, a new compliant Dockerfile, fresh exact-version
environment/gap/fairness/false-positive gates, and calibration restarted at
0/10.

Repository: `biopython/biopython` at
`c9489604d1d9607602ca9199a3852c1219ed330f`.

## Public contract and repository evidence

Add a public `Bio.PDB.build_biological_assembly(structure, mmcif_dict,
assembly_id)` operation. The source structure uses mmCIF label-asym chain IDs,
as produced by `MMCIFParser(auth_chains=False)`, and `mmcif_dict` has the
ordinary `MMCIF2Dict` mapping shape. The operation returns a new `Structure`
containing the selected assembly in every source model while leaving the source
hierarchy and coordinates unchanged.

The final public behavior is:

- select every generation row matching the string form of `assembly_id` and
  every label-asym chain named by that row;
- expand bare or parenthesized operator IDs, comma lists, inclusive numeric
  ranges, and Cartesian products of adjacent parenthesized groups;
- apply product groups from right to left, as required by the PDBx/mmCIF
  dictionary, and apply every resulting affine transform to every atom,
  including all alternatives in disordered atoms and residues;
- retain source model IDs and serial numbers, allocate deterministic unique
  string chain IDs without prescribing their spelling, and deep-copy all
  selected hierarchy objects so copies and the source are independently
  mutable; and
- reject absent assemblies, malformed category shapes or expressions,
  duplicate/unknown operators, unknown asym IDs, and nonnumeric transform
  components with `ValueError` rather than silently returning a partial
  assembly.

Repository evidence is concrete: `MMCIF2Dict` exposes all named categories as
lists; `MMCIFParser(auth_chains=False)` builds chains from
`_atom_site.label_asym_id`; `Entity.copy()` recursively copies hierarchy and
disorder wrappers; `Entity.transform()` and `DisorderedAtom.transform()` cover
ordinary and alternative atom coordinates; and `Model` preserves an explicit
`serial_num`. Existing fixtures `1A7G.cif`, `3JQH.cif`, `4CUP.cif`, and
`6WG6.cif` contain native assembly/operator rows. The official PDBx dictionary
defines lists, ranges, and Cartesian products and states that product groups
are applied from right to left.

## Trajectory-informed design gate

Searches were repeated across `problems/README.md`,
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, all candidate/problem
folders, and `archive/` for Biopython, mmCIF, biological assembly, operator
expression, graph materialization, deep copy, transform composition, stable
identity, and format-branch parsing. No Biopython or molecular-assembly solver
trajectory exists. The exact candidate audit and upstream record were reread.

Raw evidence was inspected through the archive manifests without copying hidden
fixtures or call sequences into the contract:

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Analogical legitimate pass | Statig `agent-runs4/Nova_Nova_4` in `archive/statig-local-transitions/agent-runs.tar.gz` | 23/23 base and 26/26 focused | Carried accepting-handler provenance privately through blocking and awaitable dispatch, recomputed paths at commit time, preserved the five-variant public API, and modified both engines. It demonstrates that mutation-stable identity can be retained without exposing a private encoding. |
| Analogical near-pass | Statig `agent-runs5/Nova_Nova_1` in the same archive | 23/23 base; focused compile failure | Implemented the core behavior but transported private provenance through a sixth public enum variant. This motivates testing only output identity and independence, never a required internal provenance carrier. |
| Independent-format pass | Calamine `agent-runs1/Nova_Nova_4` in `archive/calamine-defined-names/agent-runs.tar.gz` | 205/205 base and 5/5 focused | Added one shared owned model while decoding four native parser branches. It confirms that independent source branches, not fixture count, create meaningful breadth. |
| Independent-format near-pass | Calamine `agent-runs1/Nova_Nova_9` in the same archive | 205/205 base and 4/5 focused | Covered all formats but read one XLSB owner field one byte early. This supports a non-commuting product oracle rather than several commutative transform fixtures. |
| Alternate materialization passes | PcapPlusPlus `estimate_trajectories/run_gpt-5.6-sol_1` and `_2` in `archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz` | both 70/70 base and 6/6 focused | One buffered copied blocks, while one built a stream-offset copy plan; both preserved the same black-box container behavior. This supports accepting any copy/assembly strategy and using only public hierarchy/coordinate oracles. |
| Domain-specific broad failure | unavailable | no Biopython trajectories exist | No unrelated broad failure is substituted. Repository branches and isolated mutants must supply any further discriminator evidence. |

The inspected trajectories consistently validate three design rules: keep
provenance private, use a non-commuting oracle for ordered transforms, and
separate grammar, selection, model lifecycle, and graph ownership rather than
inflating one parser with more fixtures.

## Discriminator ledger

| Observed solver or repository behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| PDBx expressions contain bare lists, ranges, character IDs, and products | Split only on commas or assume numeric singletons | Every valid listed operation sequence expands exactly once | Compare coordinate multisets for a mixed list/range/product expression | Expression grammar | Any tokenizer, parser, regular expression, or recursive descent can pass. |
| The official dictionary defines products as right-to-left application | Multiply product matrices in encounter/application order | Non-commuting affine operations compose in the specified order | Rotate then translate an asymmetric point and compare the unique result | Affine composition | Tests mathematical output, not matrix orientation or helper representation. |
| Assembly generation has independent row, asym-selection, and operator columns | Apply all transforms to all chains or only the first row | Each matching row expands exactly its named label-asym chains | Use two rows with disjoint chain sets and distinguishable coordinates | Row selection | No output chain spelling or iteration implementation is required. |
| `MMCIFParser` supports multiple models with preserved serial numbers | Expand model zero only or merge copies into new models | Every model is expanded from its own coordinates and retains identity | Two models with different source coordinates and equal expansion cardinality | Model lifecycle | Copy-per-model, builder, and reconstruction architectures all pass. |
| Biopython hierarchy may contain `DisorderedAtom` and `DisorderedResidue` wrappers | Iterate selected atoms only and flatten alternatives | All alternatives, selection state, occupancy, altloc, and residue ownership survive | Inspect and independently mutate a copied disordered subtree | Graph ownership/disorder | Uses public hierarchy APIs and permits any deep-copy mechanism. |
| `Entity.copy()` is available but output siblings require unique IDs | Reuse source chain IDs for every operation or reuse one object | Copies are independently addressable with deterministic collision-free string IDs | Repeat assembly, compare ID sequences, and mutate one duplicate | Identity allocation | Exact spelling is deliberately ignored. |
| Raw category columns can be absent, ragged, duplicated, or cross-reference missing IDs | Zip to the shortest column or silently skip missing rows | Invalid metadata fails before a partial result is returned and source stays unchanged | Isolate malformed shape, unknown op/asym, and absent assembly cases | Validation/reference integrity | Accepts any `ValueError` text and any validation order that has no observable mutation. |

## Clause-to-test coverage

| Public requirement | Planned observable test | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Public `Bio.PDB` callable and new structure | Import and identity-only materialization | import fails | returns a distinct `Structure` | Existing package exports peer helpers from `Bio.PDB.__init__`. |
| Lists, ranges, products, right-to-left order | Synthetic non-commuting matrix metadata | callable absent | exact coordinate multiset | Official PDBx operation-expression definition. |
| Assembly-row/asym selection | Two matching rows plus one other assembly | callable absent | only named occurrences appear | `_pdbx_struct_assembly_gen` category semantics and fixture corpus. |
| Every model and preserved serial identity | Two-model synthetic structure | callable absent | both models expanded independently | Existing `test_PDB_MMCIFParser.testModels`. |
| Disorder and deep-copy isolation | Public disorder wrappers with two alternatives | callable absent | wrapper state and all coordinates survive; mutations do not alias | `Entity.copy`, `DisorderedAtom.transform`, and public hierarchy APIs. |
| Deterministic collision-free chain identity | Repeated operations and adversarial source IDs | callable absent | unique strings and stable repeated output | `Entity.add` rejects duplicate sibling IDs, making uniqueness repository-required. |
| Deterministic rejection | One isolated case per distinct validation family | callable absent | `ValueError`, unchanged source | Parser and entity APIs already use exceptions for malformed input and duplicate IDs. |

## Environment and harness preflight

- The final submitted Dockerfile rebuilt the untouched frozen pin from a clean
  archive. All 514 official discoveries passed offline as UID 10001.
- Exact evaluator composition passed: baseline base 11/11, baseline feature
  30 behavioral failures, reference base 11/11, reference feature 30/30, and
  identical JUnit testcase identities.
- Source is mounted read-only and copied to writable `/tmp` before extension
  compilation. Runtime uses `--network none`; tests do not require a writable
  checkout, home directory, service, or elevated UID.

## Historical design verdict (superseded)

The trajectory-informed gate is complete. The user explicitly authorized
escalation of the 7/10 reserve. A fresh pristine Phase A passed 514 official
offline tests as UID 10001 using the proposed Dockerfile.

The honest prototype adds a new assembly module plus one package export. It is
207 nonblank, noncomment production lines across two files after formatting,
without tests or compatibility padding. Its implementation has independent
expression, category validation, affine composition, generation planning,
disorder traversal/selection, identity allocation, and model construction
seams. A synthetic non-commuting product produced the official right-to-left
coordinate; repository fixture `1A7G.cif` produced eight unique chains and
twice the selected source atom count; and a manually selected two-altloc
`DisorderedAtom` retained selection, transformed both alternatives, and did
not alias the source. The task therefore does not collapse into an ordinary
`Entity.copy()` call. Test authoring was approved at that stage, but the
retirement decision above supersedes that approval.

The exact gap and false-positive audits challenged 25 isolated implementation
shortcuts. Ten initially survived the focused suite and all 515 pre-existing
discoveries with the reference module present. Their distinct probes cover
duplicate occurrence preservation, exact asym membership, multi-digit range
bounds, empty-model rejection, scalar and missing columns, malformed asym and
group syntax, and metadata ownership at structure/model/chain/residue levels.
On the final immutable version all 25 mutants are killed, the reference passes
30/30, and the pristine tree fails 30/30 behaviorally. Fairness passes without
requiring chain-ID spelling, output ordering, parser layout, exact error text,
or a private copy/matrix architecture.

Final submission hashes are recorded in `ARTIFACTS.sha256`. This is an
uncalibrated Level 1 artifact at 0/10; any submission-artifact edit invalidates
these verdicts and restarts the batch at zero.
