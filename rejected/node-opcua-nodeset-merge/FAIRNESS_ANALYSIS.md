# Exact-version fairness analysis

Status: `pass for review revision 6; calibration 0/10`.

Repository pin: `e233d906138995583f42359831d1908e3cb005e7`.

Artifact binding: `meta.md` `164e5deeaaa8`, `test.patch` `4605db209fca`,
`solution.patch` `7bda8973c435`, and Dockerfile `3a7c65b9b4fb`. Full hashes
are frozen in `ARTIFACTS.sha256`.

## Predicate audit

| Predicate family | Public or repository grounding | Fairness decision |
|---|---|---|
| Public helper accepts a valid selection | stated API contract | retain |
| Empty, repeated, and mixed-owner selections reject | stated boundary contract | retain; no error message or validation order is required |
| Caller permutations produce identical bytes | explicit deterministic-output contract | retain; no private sorting algorithm is required |
| Models and complete selected-node ownership | explicit all-and-only selection contract and UANodeSet semantics | retain; resolve every node in the committed selected fixture without prescribing XML order |
| Per-model metadata and required models | explicit contract plus existing exporter fields | retain; scope RequiredModels by ModelUri and compare semantic sets without prescribing element order |
| Selected relationship occurs once and reloads | explicit contract; repository-native custom reference | retain |
| Cross-selected subtype reloads | explicit cross-namespace relationship contract; repository-native `HasSubtype` semantics | retain; observe the loaded supertype rather than XML direction or ownership |
| External model stays declared while its nodes remain absent | explicit dependency boundary | retain |
| Shared translation survives reload | explicit contract and existing loader/exporter behavior | retain |
| Re-export is stable | explicit lifecycle contract | retain |
| RequiredModel version and publication date match the dependency | explicit required-model metadata contract and existing exporter fields | retain; quote and attribute order remain free |
| Existing exporter cases continue to pass | concretely discoverable pre-existing repository tests | retain only in the baseline lane; no hidden compatibility assertion or public clause |
| TypeScript build and offline runtime | repository toolchain and evaluator semantics | retain |
| Package-root TypeScript import compiles | helper is explicitly public from `node-opcua-address-space`; package manifest separately advertises `types` | retain; compile an isolated consumer against the built package root without requiring a source-barrel filename |
| Watchdog | only guards a hung run; not used as a product-performance threshold | retain |
| Feature testcase attribution | evaluator classification requires stable testcase identities across pristine and reference | retain; shared setup uses only repository APIs, and missing-helper failures occur inside the fifteen named tests |

## Encoding and architecture neutrality

Assertions inspect loaded models, nodes, references, and values wherever
possible. The few schema-level checks accept either XML quote style and do not
prescribe attribute order. Namespace indexes are derived from each document's
`NamespaceUris`; the tests do not require `ns=1`, `ns=2`, an alias spelling, a
root attribute order for the new API, a traversal strategy, or a particular
batching implementation.

The dependency fixture used to check declaration-only behavior is produced by
the repository's existing exporter and loaded through its existing loader. It
does not require arbitrary invalid bytes or a private hand-written XML shape.
The relation oracle accepts either endpoint as the canonical serialization
owner while requiring exactly one semantic representation.

The subtype assertion is intentionally semantic: after a fresh load, the
derived node must have the selected base node as its inverse `HasSubtype`
target. It does not require forward versus inverse XML, a NodeId ordering rule,
or the reference implementation's selected-index set. The package API check
asks the repository's installed TypeScript compiler to resolve the package
directory through its own `package.json` entry points. It does not inspect or
name `source/index.ts`, and it runs inside a named Mocha case so pristine
declaration absence is behavioral f2p rather than verifier startup failure.

The custom `ConnectsTo` relationship also provides the alias oracle. Its
translated custom reference-type alias must resolve for the relationship to
load and browse successfully. The suite does not prescribe the alias text or
require aliases when a legitimate serializer can use an equivalent NodeId.

During preflight, a proposed rule made every later selected model require every
earlier selected model. A reference implementation using only the repository's
existing dependency calculator passed all public behavior and produced a valid
reload, so the extra rule and test were removed. This is direct replay evidence
that the final suite accepts a materially simpler legitimate architecture.

No node-opcua solver trajectories exist yet. The candidate prototype and final
reference use the existing exporter seam, but tests do not require their file
layout or internal data structures. Future materially different solver patches
must be replayed before approval or calibration continuation.

## Narrow base-lane decision

The earlier 46-test authoring slice was broader than participant scoring needed.
The final base lane contains only `LNEX5` and `LNEX8`, the two pre-existing tests
that fail a deliberate legacy-ordering mutation. Unrelated loader cases are not
part of the evaluator. The complete 1,040-test package run is mutation-audit
evidence only.

## Review disposition

- Accepted: remove the explicit legacy-output sentence because it only restated
  normal regression expectations.
- Accepted: use the random `36c2ba` suffix for the additive hidden test path;
  it cannot collide with the predictable participant filename named by review.
- Accepted: directly inspect the natural external RequiredModel's Version and
  PublicationDate using quote- and attribute-order-neutral attribute checks.
- Rejected after the prompt edit: add a new hidden legacy byte fixture. Once
  the clause is removed, that would convert an unstated default into a hidden
  participant requirement. The two existing regression tests remain sufficient
  repository baseline evidence.
- No additional alias-spelling assertion was added because semantic resolution
  of the translated custom reference type already crosses that boundary.

The revision 4 environment gate applied the unpredictable test after the
reference without a collision or reset and passed all four offline UID 10001
lanes. Baseline and reference feature JUnit have the same thirteen testcase
identities; baseline has thirteen named failures, reference has thirteen passes,
and neither contains a hook/startup node. The exact mutation rerun produced no
compile, environment, timeout, or anonymous-hook kills. No representative
node-opcua solver architecture exists to replay.

The initial direct type-barrel re-export caused a circular runtime import and
was rejected before evidence collection. The final declaration-only signature
matches this repository's deliberate split between `main` and `types`; runtime
callability remains independently observed. The 120-second suite timeout is a
deadlock guard, not a product deadline, and the consumer compilation completed
well within it offline.

## Revision 5 predicate audit

The two new predicates are direct instances of the public requirement that one
namespace translation applies to data types and encoded values. A custom
structure field must resolve to its custom DataType after fresh load, and a
nested structured encoded value must preserve its nested typed value after
fresh load. Repository inspection proves these are independently implemented
serializer branches, so neither is a duplicate fixture for the existing scalar
typed-value case.

Both tests are black-box and architecture-neutral. They use public address-space
construction/loading APIs, repository-native structure definitions, derived
post-load NodeIds, and semantic value observations. They do not require a
private traversal, alias spelling, literal namespace index, XML ordering,
serialization owner, or source-file layout. The nested test deliberately keeps
the structure model external to the selected export, which is an explicitly
supported resource boundary rather than malformed input.

The exact wrapper composition reaches all fifteen named testcases on pristine
and reference. There are no suite-hook, compiler-startup, timeout, permission,
or skipped-feature predicates. The two targeted compiling mutants fail only
their corresponding new testcase; representative legitimate reference behavior
passes both. No raw solver architecture exists in the five no-start run records
to replay.

Verdict: `pass` for the exact revision 5 artifacts. Any change to the prompt,
tests, reference, Dockerfile, dependency graph, or evaluator injection path
invalidates this verdict.

## Revision 6 fairness audit

The complete-inventory assertion follows directly from “all nodes owned by the
selected namespaces.” It uses the committed repository fixture and the fresh
loader, derives document namespace indexes, and observes public browse
identities. It does not require an iterator order, XML node order, serializer
helper, or private storage. Checking the independent namespace-1 object is a
connectivity boundary, not another arbitrary node-class permutation.

The per-model dependency assertion follows directly from preserving each
model's required models. It identifies Model elements by their public ModelUri,
then treats their RequiredModels as unordered semantic sets. It accepts either
quote style and any Model/RequiredModel ordering. Expected dependencies come
from the repository-grounded fixture: alpha's external type creates its
external dependency, while beta has only standard type dependencies. Version
and publication date are derived from the source namespaces rather than fixed
private exporter data.

No new testcase, timeout, compile lane, malformed input, or base test was added.
The cold exact wrapper run reaches the same fifteen feature identities on
pristine and reference with no hook/startup/skip. Both new plausible mutants
compile and fail only their corresponding existing testcase. No solver
trajectory exists to reveal a materially different legitimate architecture;
the black-box reference and repository APIs remain the available replay.

Verdict: `pass` for the exact revision 6 artifacts. Any change to the prompt,
tests, reference, Dockerfile, dependency graph, or evaluator injection path
invalidates this verdict.
