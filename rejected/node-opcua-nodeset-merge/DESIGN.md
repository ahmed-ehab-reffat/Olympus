# Design - node-opcua deterministic multi-model NodeSet export

Status: `review revision 4 locally verified; calibration 0/10`.

Repository: `node-opcua/node-opcua` at
`e233d906138995583f42359831d1908e3cb005e7`.

Task type: `feature request`.

## Public contract and repository evidence

The public operation is frozen as
`exportNodeset2XML(namespaces: INamespace[]): string`, exported from
`node-opcua-address-space`. It accepts a nonempty unique selection from one
address space and emits one deterministic UANodeSet containing each selected
model and only its nodes. Model metadata, required models, namespace-index
translation, aliases, references, values, and reload behavior are observable
requirements. Existing single-namespace exporter behavior remains ordinary
repository regression coverage, not a participant-facing clause.

The pinned repository already owns every constituent behavior in
`src/nodeset_tools/nodeset_to_xml.ts`,
`src/nodeset_tools/construct_namespace_dependency.ts`, `source/xml_writer.ts`,
and the NodeSet loader. Its public exporter is single-namespace only, while
`fixture_custom_nodeset.xml` supplies two models and a custom cross-model
reference and the nested-datastructure fixture supplies model dependencies and
encoded values. OPC UA Part 6 F.2 permits multiple Model entries and defines
their relationship to NamespaceUris. No raw-XML merge, collision policy, or
cross-address-space copy behavior is requested.

## Trajectory-informed design gate

Searches covered `PROBLEM_DESIGN.md`, both candidate registries,
`problems/README.md`, local NodeSet/OPC-UA history, namespace remapping, model
dependency ordering, graph export, aliases, and ExtensionObjects. There is no
prior node-opcua problem or solver trajectory. The complete candidate record
also inspected all four archived go-astisub collision-merge runs and
representative pass, near-pass, and broad-failure PCAPNG filtered-copy runs.

| Evidence role | Problem / run | Outcome | Architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | `go-astisub-merge-collisions`, all four archived runs | 4/4 passed | Demand-aware import or clone-then-rewrite maps preserved reference closure; this shows ordinary deterministic remapping alone is an easy family. |
| Legitimate pass | PCAPNG `agent-runs4/Nova_Nova_6` | complete pass | Maintained section-local state, format-specific framing, selective validation, and staged publication. |
| Near-pass | PCAPNG `agent-runs4/Nova_Nova_1` | failed one later boundary | Validated a discarded entity before the public selection decision. |
| Broad failure | PCAPNG `agent-runs4/Nova_Nova_10` | failed five scenarios | Conflated section boundaries and option layouts across independent state families. |

The disposable repository prototype added the proposed helper in two production
files with 88 strict effective additions. Its first run dropped the committed
selected-to-selected reference by applying the legacy external-reference rule
per namespace. Its first complete-suite run then changed legacy root-attribute
ordering. After both were corrected, 47 focused and 1,041 package tests passed,
with two pending. Those observed failures are direct repository evidence for
reference ownership and compatibility discriminators. The compact prototype is
an honest calibration risk, not permission to pad behavior.

## Discriminator ledger

| Observed behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary | Anti-overfit rationale |
|---|---|---|---|---|---|
| Existing export is one model. | Concatenate single-model XML or export only the first input. | One valid document contains every selected Model and selected node set. | Parse and reload one document, then resolve nodes from each selected model. | Multi-model construction | Accepts any implementation producing a valid UANodeSet. |
| Remapping alone solved the related archive. | Translate NodeIds but omit per-model semantics. | Each selected model preserves metadata and its own required models. | Inspect Models and reload an interdependent selection. | Model/dependency projection | Tests metadata, not graph algorithm or ordering internals. |
| The serializer handles identifiers in several value surfaces. | Use different maps for attributes, references, and encoded values. | One translation remains coherent across every emitted identity. | Reload and observe cross-model references, typed NodeId/QualifiedName values, and ExtensionObjects. | Identity/value closure | Semantic reload permits different serializers and internal maps. |
| The prototype dropped the custom cross-model edge. | Apply the legacy external filter independently or emit inverse duplicates. | A selected-to-selected relationship appears once and reconstructs the same graph. | Count semantic XML edges and browse both endpoints after reload. | Reference ownership | Uses a repository-native relationship, not arbitrary XML spelling. |
| Caller arrays are not a canonical order. | Preserve input order or sort only URI strings. | The selected set determines byte-identical output in dependency-valid order. | Export both permutations and compare bytes, then reload. | Determinism/topology | Does not prescribe the sorting implementation. |
| The full suite caught attribute reordering. | Route the legacy API through a changed serialization path. | Production changes continue to pass the repository's existing exporter tests. | Run the two existing tests demonstrated to fail this regression. | Repository regression safety | Preserves discoverable behavior without adding a participant-facing requirement. |
| OPC permits references to models not exported. | Export dependency nodes transitively or omit declarations. | Unselected dependencies may be declared but their nodes remain outside the selection. | Export only a dependent model; inspect declarations and node ownership. | Selection boundary | Avoids inventing raw-XML conflict or recursive-copy policy. |
| Inputs are already composed in one address space. | Silently accept empty, duplicate, or mixed-owner arrays. | The public boundary rejects all three invalid selections. | Call the public API and assert rejection without output or mutation. | API validation | Error wording and internal validation order remain free. |

## Planned clause-to-test coverage

| Public requirement | Planned observable | Base | Reference | Fairness source |
|---|---|---|---|---|
| Public helper and selection validation | valid call plus empty/duplicate/mixed-owner rejection | missing/fail | pass | exported helper conventions and address-space ownership |
| Multi-model metadata and selected-only nodes | Models/RequiredModels plus fresh reload | fail | pass | existing exporter and committed fixtures |
| Coherent identity and value translation | reload references and typed values after index changes | fail | pass | existing NodeSet loader/serializer contract |
| Caller-order-independent bytes | reversed arguments give equal strings | fail | pass | public deterministic contract |
| Stable round trip | reload and re-export selected models | fail | pass | established loader/exporter interoperability |
| Repository exporter regressions | two existing single-model cases | pass | pass | concretely discoverable baseline behavior, not a prompt clause |

## Review-triggered design gate — artifact revision 2

Before revising the prompt or hidden-test patch, the startup search was repeated
across `problems/README.md`, both candidate registries, the current problem and
candidate records, and local directories named `actual_trajectories`,
`estimate_trajectories`, or `agent-runs*`. There are still no node-opcua solver
trajectories. The prior go-astisub and PCAPNG representative pass, near-pass,
and broad-failure evidence above remains the closest relevant raw evidence; no
new solver architecture is available to replay.

The new review contributes two design signals:

1. The explicit sentence requiring unchanged legacy API bytes restated normal
   repository regression expectations without adding participant behavior. It
   will be removed from `meta.md`. The two existing tests that exposed the
   actual regression remain in the base lane, but no new hidden legacy oracle
   will be added and compatibility is no longer mapped as a public clause.
2. The descriptive hidden-test filename was predictable. The reviewer required
   a random suffix; `openssl rand -hex 3` produced `36c2ba`. The additive test
   path will become
   `test_export_selected_namespaces.36c2ba.test.ts`, and every harness and
   verifier reference will follow it. The suffix is evaluator plumbing and is
   not exposed in the public description.

The apparent request to add a new legacy byte assertion conflicts with the
high-priority removal of that public requirement. The fair resolution is to
remove the public clause and retain only the repository's already existing
baseline regressions. Alias translation is already observed semantically: the
translated custom reference-type alias must resolve for the cross-model
relationship to reload. RequiredModel `Version` and `PublicationDate`, however,
were only indirect through the fixture. They are independent public metadata
fields, so revision 2 admits quote- and attribute-order-neutral checks on the
natural external dependency entry. The interrupted mutation attempt against
the pre-addition artifact is quarantined and cannot contribute evidence.

This refreshed ledger completes the design gate for revision 2 and authorizes
the prompt and hidden-test-path edits. It does not authorize downstream audit
reuse: environment, gap, fairness, and false-positive verdicts must all restart
from zero for the revised immutable artifacts.

## Wrapper-attribution design gate — artifact revision 3

The startup search was repeated across the current problem and candidate
records, both registries, `candidates/SUCCESSES.md`, and local solver-run
directories. No node-opcua solver trajectory exists, so the prior representative
go-astisub and PCAPNG evidence remains unchanged. The new evidence is the
wrapper-driven pristine run itself: because the suite-level `before` hook called
the absent API, JUnit emitted only
`"before all" hook for "rejects an empty selection"`. That identity appears in
neither the reference pass set nor the intended fail-to-pass set, so the wrapper
correctly rejected the run as unclassifiable.

| Observed behavior | Generalized harness shortcut | Fair evaluator invariant | Black-box oracle | Anti-overfit rationale |
|---|---|---|---|---|
| Pristine fails before named tests execute. | Invoke the participant-added API during shared fixture setup and treat any nonzero result as an acceptable baseline failure. | Every feature failure on pristine is owned by the same named testcase that passes with the reference; fixture construction itself succeeds. | Compare pristine and reference JUnit testcase identities: all 11 names exist, pristine marks each failed, reference marks each passed, and neither contains hook/startup nodes. | Changes only failure attribution and preserves every behavioral assertion, fixture, and implementation freedom. |

Revision 3 will make shared setup load only repository fixtures. It will compute
the common XML only when the helper exists, and the three rejection tests will
check helper availability outside their `should.throws` blocks so absence cannot
accidentally count as the requested validation error. Every other testcase
already fails inside its own body when the XML/helper is absent. The public
prompt, reference solution, Dockerfile, test count, and behavioral discriminator
set remain unchanged.

This records the required design gate before revising `test.patch`. The wrapper
failure and all revision 2b downstream verdicts were quarantined. Revision 3
repeated exact environment composition, including explicit testcase-set parity,
before rerunning mutation, gap, fairness, and false-positive analysis.

## Correctness-review design gate — artifact revision 4

Before revising the hidden tests or reference, the startup search was repeated
across `problems/README.md`, both candidate registries, the current problem and
candidate records, and every local `actual_trajectories`,
`estimate_trajectories`, and `agent-runs*` directory. There is still no
node-opcua solver trajectory to inspect. The archived go-astisub and PCAPNG
representative pass, near-pass, and broad-failure evidence recorded above
remains the closest raw history; no new legitimate solver architecture is
available to replay.

The new evidence is the completed wrapper run plus its source review. The run
proved the revision 3 harness shape—2/2 p2p and 11/11 f2p—but the review found
two repository-grounded public surfaces that the suite never exercised:

| Observed behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary | Anti-overfit rationale |
|---|---|---|---|---|---|
| Generic cross-selected endpoint ownership runs before reference-kind rules, while the writer later drops every forward `HasSubtype`. | Treat all cross-model edges as interchangeable inverse pairs even though the legacy serializer gives subtype edges a canonical inverse representation. | A subtype relationship whose supertype and subtype are in different selected namespaces survives export and fresh reload. | Construct a repository-native type in each namespace, export both, reload, and observe the subtype's supertype and `isSubtypeOf` result. | Reference-kind semantics | Tests the public relationship round trip and accepts any XML ownership or sorting strategy that reloads correctly. |
| Package runtime and declaration entry points differ: `main` targets `dist/src/index_current.js`, while `types` targets `dist/source/index.d.ts`; only the runtime barrel exports the helper. | Add a runtime export without exposing the symbol through the package's advertised TypeScript API. | A TypeScript consumer can import the new public helper from `node-opcua-address-space`, and the imported runtime value is callable. | Compile an isolated consumer against the built package's own `main`/`types` entry points, then load the package root at runtime. | Public API packaging | Uses the package manifest and compiler as consumers do; it does not prescribe which source barrel implements the declaration. |

The subtype probe is distinct from the existing custom `ConnectsTo` check:
`HasSubtype` follows an independently implemented serializer branch with an
explicit forward-reference omission. The package-root probe is also distinct
from runtime behavior because TypeScript resolves the separately advertised
declaration barrel. Both requirements already follow from the public contract:
relationships between selected namespaces must round-trip, and the helper must
be exported from `node-opcua-address-space`.

Revision 4 may add one semantic subtype round-trip test and one consumer-facing
package API test. The latter must fail inside a named testcase on pristine, not
during verifier compilation, so the wrapper retains ordinary f2p attribution.
The public prompt needs no new clause. The reference may repair reference
ownership and add the declaration export, but the Dockerfile and dependency
graph should remain unchanged unless the environment retry proves otherwise.

This completes the design gate before any revision 4 test or reference edit.
All revision 3 environment, mutation, gap, fairness, and false-positive
verdicts are quarantined, and calibration remains `0/10`.

## Design verdict

The user's escalation is treated as local-owner approval of the API shape. The
trajectory gate authorized packaging, and the untouched plus exact-composition
environment gates now pass. Hidden tests were authored only after that gate was
recorded. No calibration or long-horizon claim is made: there are no solver
runs for this version, and its compact three-file reference remains a real risk.

## Environment preflight log

The first untouched image built successfully on the official TypeScript base,
but the arbitrary-UID offline probe stopped before test discovery because
Corepack tried to create `/.cache/node/corepack/v1`. This is classified only as
an environment blocker. The Dockerfile now freezes `COREPACK_HOME` at
`/opt/corepack` and populates it during the network-enabled build. The next
retry reached 46 real focused tests as UID 10001 but 14 tried to create the
repository's conventional `/app/tmp` directory and failed with `EACCES`; its
32 passes and 14 environment failures are also quarantined. The Dockerfile now
creates that expected temp root with sticky world-writable permissions. A later
reference-authoring lane copied the pnpm workspace to a different absolute path;
pnpm correctly treated the copied installation as stale and attempted an
offline reinstall. The harness now keeps pnpm at `/app`, whose container-local
overlay is writable by the arbitrary runtime UID. The Dockerfile change
invalidated the earlier Phase A pass, so both phases were rerun from zero. A
later exact-gate attempt exposed two generic harness defects: unsafe empty-array
expansion on Bash 3.2 and shared-clone Git alternates that were unavailable
inside Docker. The gate now uses optional-array-safe expansion and
self-contained `--no-local` clones.

The final immutable composition passed on the official base, offline as UID
10001: pristine base 2/2, pristine feature behavioral failure, reference base
2/2, and reference feature 11/11. The scoring base was narrowed from the
authoring-time 46-test slice to only the existing `LNEX5` and `LNEX8` exporter
cases that detect the observed legacy-ordering regression. The complete package
suite is mutation-audit escalation evidence only.

## Fairness preflight corrections

The final tests do not freeze literal namespace indexes, XML quote style,
attribute order, or alias spelling. Namespace indexes are derived from each
document, relationship ownership counts either endpoint representation, and
model/dependency behavior is checked semantically through the existing loader
where possible.

An intermediate reference also made later selected models depend on earlier
selected models even when the repository's dependency calculator did not. A
simpler legitimate implementation passed all public requirements, so the
augmentation and its proposed test were removed. This prevents the benchmark
from requiring one private model-ordering policy.

## Exact-version discriminator result

The revision 3 audit restarted from zero after the testcase-attribution change
and isolated the same thirteen compiling plausible defects. The exact
environment composition also proved that pristine and reference feature JUnit
contain the same eleven testcase identities: pristine reports 11 named
failures, reference reports 11 passes, and neither emits a hook or startup node.
Twelve were killed by the direct feature file: caller-order dependence, duplicate and missing
selected edges, one-namespace rejection, dependency-node leakage, first-model
and first-namespace truncation, missing external declarations, constant model
version, omitted RequiredModel version/date metadata, and independently
untranslated QualifiedName and NodeId values.

The deliberate legacy-ordering change correctly survived the new API file. It
then failed exactly the pre-existing `LNEX5` and `LNEX8` cases in a 1,040-test
complete package run with two existing skips. Those are now the only two tests
in the participant base lane. No actionable mutation survived, and no compile,
startup, timeout, or environment result was counted as a behavioral kill.

This closes the revision 3 design, environment, gap, fairness, and
false-positive gates for the frozen artifacts. It does not close calibration:
there are no local frontier or
platform solver runs, and every artifact edit restarts all gates and the batch
at `0/10`.

## Revision 4 exact-version result

The frozen revision 4 composition rebuilt the untouched repository image from
the pinned base digest and passed all four offline UID 10001 lanes: pristine
base 2/2, pristine feature 13 named failures, reference base 2/2, and reference
feature 13/13. Baseline and reference expose exactly the same feature testcase
identities with no hook, startup, or skipped feature node. The separately
reported cached-image pull failure was reproduced as a successful direct pull
and is quarantined as transient platform infrastructure.

The completed revision 3 reference was replayed against the revision 4 tests.
It passed the prior eleven cases and failed exactly the two review probes. The
corrected reference preserves inverse-canonical `HasSubtype` handling before
generic selected-edge ownership and exposes a declaration-only signature
through the package's advertised type barrel without creating a runtime cycle.

The zero-based revision 4 audit isolated fifteen compiling plausible defects.
Fourteen public feature/API mutants failed named focused cases; the two new
mutants each failed only its corresponding subtype or declaration test. The
legacy-ordering mutant alone survived focused testing and failed exactly
`LNEX5` and `LNEX8` in the complete 1,040-test package run, with two existing
skips. No compile, startup, timeout, environment, or anonymous-hook result was
counted as a kill, and no actionable survivor remains.

Status: revision 4 design, environment, gap, fairness, and false-positive gates
are `pass`; calibration remains `0/10`.

## No-start and coverage-review design gate — artifact revision 5

Before revising the verifier, the local-history search was repeated across both
candidate registries, the current problem and candidate records, and every
`actual_trajectories`, `estimate_trajectories`, and `agent-runs*` directory.
The five new node-opcua run directories each contain only a 199-byte `run.txt`
with a platform run ID and URL. They contain no trajectory, solver patch,
evaluator result, build log, or JUnit output. The run pages redirect an
unauthenticated client to sign-in, so there is no raw solver architecture to
inspect locally or through the available session. These records corroborate a
no-start batch; they are quarantined as environment failures and calibration
remains `0/10`. The prior representative raw evidence recorded above remains
the closest relevant trajectory history.

The environment evidence also invalidates revision 4's verdict. Although its
record says the untouched image was rebuilt from a pinned base digest, the
submitted Dockerfile still names the mutable `:latest` tag, and the reusable
gate invokes `docker build` without `--pull` or `--no-cache`. The recorded build
therefore proved only a warm local cache. The platform's cached-image pull
failure cannot be dismissed as a solver result or as proof of a viable cold
submission. Revision 5 must first perform a genuinely cold build of the
untouched pin, start it offline as UID 10001, and exercise real discovery. If
that succeeds, the cold gate will record the observed digest while the
Dockerfile retains the validator-approved exact `:latest` declaration, and the
entire exact-composition gate will restart on the freshly pulled image.

The source review exposes two independent serializer branches that the current
typed-value case does not enter:

| Review evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Distinct boundary |
|---|---|---|---|---|
| Structure fields write their custom `DataType` through `_dumpStructureDefinition`, separately from scalar Variant values. | Translate NodeIds appearing as values while leaving custom schema DataType identifiers at address-space indexes. | One translation applies to data types as well as values. | Define a custom structure field whose DataType is owned by another selected namespace, export/reload, and observe that the field resolves to the reloaded custom DataType. | DataType-definition metadata |
| Nested `ExtensionObject` fields recurse through `_dumpVariantInnerExtensionObject`; their TypeIds, nested schema lookup, NodeIds, and QualifiedNames do not use the ordinary scalar-variable path. | Handle top-level NodeId/QualifiedName values while emitting nested structured values with stale indexes. | Structured encoded values round-trip under the same selected-namespace translation. | Export a custom outer value containing a custom nested structure and namespace-bearing leaf values, reload it, and observe the nested constructor/value identities. | Recursive encoded-value serialization |

Both probes derive directly from the public sentence requiring one translation
for data types and encoded values. They will assert only fresh-loader semantics,
not literal indexes, XML layout, alias spelling, or a private implementation.
The custom-DataType probe and nested-value probe are distinct because plausible
implementations can independently translate schema metadata and recursive value
bodies. This ledger completes the startup design gate for revision 5. No test
patch may change until the cold Phase A environment gate passes; all revision 4
gap, fairness, mutation, and environment verdicts are invalidated.

## Revision 5 result

The cold Phase A gate passed before test mutation. Revision 5 then added exactly
the two ledgered probes. The custom-DataType case defines a custom field type in
one selected namespace and a structure using that type in another, exports and
fresh-loads both, and resolves the field's translated DataType. The nested-value
case exports only the value-owning namespace while a repository-native custom
structure model remains an unselected declared dependency; after fresh load it
observes the nested structure and its DateTime leaf. Thus the cases challenge
schema metadata and recursive encoded-value serialization independently.

The final cold exact evaluator gate has 2/2 pristine and reference baseline
passes, fifteen named pristine feature failures, and 15/15 reference feature
passes, with testcase identity parity and no hook/startup/skip. The zero-based
seventeen-mutant audit killed all sixteen public feature/API defects in named
focused tests. The deliberate legacy-ordering defect alone survived focused
testing and failed exactly the repository's `LNEX5` and `LNEX8` cases in the
complete 1,040-test package run (two existing skips). The two new mutants each
failed only its intended new case. No actionable survivor remains.

Status: revision 5 design, environment, gap, fairness, and false-positive gates
are `pass`; solver calibration remains `0/10` because the five platform records
never produced a trajectory.

## Selected inventory and per-model dependency review gate — revision 6

Before changing the verifier, the local-history search was repeated across
`problems/README.md`, both candidate registries, the current problem and
candidate records, and every local `actual_trajectories`,
`estimate_trajectories`, and `agent-runs*` location. The five node-opcua run
directories still contain only their 199-byte `run.txt` records; there is no
solver patch, trajectory, evaluator log, or JUnit to inspect. Repository and
fixture evidence therefore supplies the discriminators below.

The accepted TypeScript `FROM` declaration passed a cold untouched build and
the exact four-lane environment gate immediately before this review. That gate
reached the two named baseline cases and all fifteen named feature cases; no
hook, startup, permission, or skipped-feature node occurred.

| Repository/review evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Distinct boundary and anti-overfit rationale |
|---|---|---|---|---|
| `fixture_custom_nodeset.xml` owns four selected nodes, but fresh-load assertions observe only the relationship-bearing object, its target, and the custom reference type; namespace 1's independent `i=1` object is unobserved. | Emit model declarations and the nodes needed by tested relationships while silently dropping another selected-owned node. | The document contains all nodes owned by every selected namespace. | Fresh-load the exported document and resolve every selected-owned fixture node, including namespace 1 `i=1`, by its translated namespace and public browse identity. | Selected-node inventory/connectivity; strengthens the existing reload case and accepts any serialization order or implementation architecture. |
| The dependency case collects every `RequiredModel` tag in the document, so a dependency attached to the wrong selected `<Model>` still passes. | Compute one union of dependencies and place it under an arbitrary model. | Each selected model preserves its own repository-derived required-model list and metadata. | Locate each selected Model by `ModelUri`, inspect only its child RequiredModels, and compare the semantic URI set; verify dependency version/date on the owning model. | Per-model metadata scoping; does not prescribe model order, RequiredModel order, quote style, or the dependency algorithm's internal representation. |

Revision 6 may strengthen the two existing testcases only. It must not add a
new file, expand the participant base lane, or turn the complete package suite
into scoring. The test patch may change only after this ledger is recorded.

### Revision 6 result

The verifier was strengthened in place and remains fifteen feature testcases.
The cold exact environment gate passed all compositions offline as UID 10001:
pristine base 2/2, pristine feature fifteen named failures, reference base 2/2,
and reference feature 15/15, with exact testcase identity parity and no
hook/startup/skip. The independent-object and global-dependency-union mutants
compile and each fail only the intended existing testcase. The complete
nineteen-mutant replay leaves no actionable survivor; only deliberate legacy
ordering survives focused testing and it fails LNEX5/LNEX8 in the pre-existing
suite. Revision 6 design, environment, gap, fairness, and false-positive gates
are `pass`; calibration remains `0/10`.
