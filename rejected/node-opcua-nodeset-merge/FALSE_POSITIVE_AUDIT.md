# Exact-version false-positive audit

Status: `pass for review revision 6; calibration 0/10`.

Repository pin: `e233d906138995583f42359831d1908e3cb005e7`.

Artifact binding: `meta.md` `164e5deeaaa8`, `test.patch` `4605db209fca`,
`solution.patch` `7bda8973c435`, verifier `2f49b4befc3d`, and results
`05efb7041433`. Full hashes are frozen in `ARTIFACTS.sha256`.

## Requirement-to-oracle map

| Participant-facing requirement | Strongest behavioral test |
|---|---|
| selection validation | empty, repeated, and mixed-owner rejection |
| caller-order-independent output | reversed input byte equality |
| every selected model and all and only selected nodes | two-model declaration/ownership test plus fresh resolution of every selected-owned fixture node |
| per-model metadata and required models | ModelUri-scoped exact RequiredModel URI/version/date sets plus fresh reload |
| one cross-selected relationship | semantic XML count plus post-load browsing |
| cross-selected subtype relationship | fresh-load inverse `HasSubtype` lookup from the derived type to the selected base type |
| one identity translation | reference, type definition, NodeId value, and QualifiedName value after reload |
| stable load/re-export | fresh address-space round trip |
| one-namespace selected export | single selection with external dependency ownership |
| RequiredModel dependency metadata | quote/order-neutral Version and PublicationDate checks on the natural external dependency |
| public package-root TypeScript API | isolated consumer compilation through the package's advertised declaration entry point plus runtime callability |

The removed legacy-output sentence is not participant-facing in revision 4.
The existing `LNEX5` and `LNEX8` cases remain baseline repository regression
coverage and are not represented as a hidden public requirement.

## Plausible incorrect implementations

The reproducible audit in `verify/mutations.sh` composes the exact reference and
test patches, runs offline as UID 10001, and isolates fifteen defects:

1. preserve caller order;
2. duplicate selected cross-model edges;
3. drop selected cross-model edges;
4. reject one-namespace selections;
5. export unselected dependency nodes;
6. emit only the first model;
7. emit nodes from only the first namespace;
8. omit external declarations;
9. replace model version metadata with a constant;
10. omit RequiredModel version and publication-date metadata;
11. leave QualifiedName values untranslated;
12. leave NodeId values untranslated;
13. apply generic selected-edge ownership to a cross-namespace subtype and
    thereby lose its canonical inverse representation;
14. omit the helper from the package's advertised TypeScript declarations; and
15. change legacy single-namespace ordering.

Each mutation is repository-grounded. The first fourteen change public behavior;
the last challenges ordinary pre-existing regression safety. Compile or
harness-startup failures are rejected as evidence rather than counted as kills.
A mutant that passes the focused feature file is escalated to the full
pre-existing package suite after the randomly named hidden test file is removed.

## Design changes caused by the audit

- The first edge-ownership probe allowed a duplicate representation at the
  opposite endpoint. It was strengthened to count both semantic forms.
- An artificial selected-model dependency augmentation was removed from the
  reference after an implementation using existing repository dependency
  semantics passed every public requirement. No test was added for that private
  policy.
- XML checks were relaxed from fixed attribute order, quote style, alias text,
  and literal namespace indexes to schema- and loader-level observations.
- The participant base lane was reduced from 46 tests to the two exact existing
  cases that detect the repository-regression mutant.
- Review revision 2b removes the redundant legacy-output prompt sentence,
  randomizes the additive test path with suffix `36c2ba`, and directly checks
  RequiredModel Version and PublicationDate without fixing XML quote or
  attribute order. The targeted metadata-omission mutant fails that test.
- The interrupted mutation attempt made before the metadata probe existed is
  quarantined and contributes no result below.
- Revision 3 moves feature-helper invocation out of shared setup and requires
  exact baseline/reference testcase-name parity. This is evaluator attribution,
  not a new behavioral discriminator: the exact run has eleven named pristine
  failures matching the eleven reference passes and no hook/startup node.
- Revision 4 adds the two review-grounded probes. The complete revision 3
  reference acts as a combined plausible survivor: it passes the prior eleven
  cases and fails only the subtype and declaration tests. Each defect was then
  isolated as its own compiling mutant and failed only its targeted case.

## Exact-version result

| Result | Count | Interpretation |
|---|---:|---|
| killed by the 13-test feature file | 14 | every feature/API mutant failed a named behavioral test |
| survived the feature file | 1 | deliberate legacy byte-order change; it does not alter the new API |
| killed by complete pre-existing suite | 1 | exactly `LNEX5` and `LNEX8` failed among 1,040 tests, with 2 existing skips |
| actionable survivors | 0 | no plausible public or repository-regression defect passes the final evaluator evidence |
| artificial/rejected mutants | 1 proposed rule | selected-model dependency augmentation removed as an unsupported private policy |

The entire fifteen-mutant set was rerun from zero for revision 4. No mutation
was counted because of compilation, startup JUnit, timeout, anonymous hook, or
environment failure. The full result, including each named focused failure, is
in `verify/mutation-results.txt`; the isolated complete-suite result is mirrored
in `verify/legacy-complete-results.txt`.

## Revision 5 false-positive audit

The requirement map now adds two strongest oracles: `translates custom DataType
identifiers in structure definitions` for schema metadata, and `translates
nested structured encoded values` for recursive ExtensionObject bodies. These
are separate producer paths in the repository exporter and separate public
surfaces in the prompt.

The exact audit was restarted with all prior mutations plus two repository-
grounded defects:

16. emit a custom structure field's DataType with its address-space NodeId
    instead of the document translation; and
17. skip recursive serialization of a nested ExtensionObject field.

All seventeen mutations compiled and reached named tests offline as UID 10001.
The DataType mutant failed only `translates custom DataType identifiers in
structure definitions`; the recursion mutant failed only `translates nested
structured encoded values`. Fourteen other public/API defects also failed the
focused file. The intentional legacy-ordering mutation alone survived focused
testing and failed exactly `LNEX5` and `LNEX8` in the complete 1,040-test
pre-existing suite, which retained two existing skips. No compile, startup,
hook, timeout, permission, or environment outcome was counted as a kill.

| Result | Count |
|---|---:|
| killed by the 15-test feature file | 16 |
| focused survivors | 1 |
| focused survivors killed by directly relevant pre-existing tests | 1 |
| actionable survivors | 0 |

The five platform directories provide no solver patch or trajectory and cannot
contribute legitimate-architecture or shortcut evidence. They are quarantined
as no-start environment records. The mutation set is evidence for the attempted
defects, not proof that false positives are impossible.

Verdict: `pass` for the exact revision 5 artifacts. Any artifact change
invalidates the audit and requires a fresh zero-based run.

## Revision 6 false-positive audit

The exact audit adds two repository-grounded incorrect implementations while
retaining and replaying all seventeen predecessors:

18. export object instances only when they participate in a nonstandard
    namespace relationship, thereby omitting an independent selected object;
19. compute the external RequiredModel union once and attach it to every
    selected Model instead of preserving per-model lists.

Both mutants compile and pass the predecessor's weaker observations. On the
revision 6 suite, the inventory mutant fails only `reloads both models and their
cross-model relationship`; the dependency-union mutant fails only `keeps
unselected dependencies declared without exporting their nodes`. They therefore
demonstrate distinct public false positives without adding testcase breadth.

The complete zero-based nineteen-mutant run executed offline as UID 10001.
Eighteen public/API mutants fail named focused behavior. The deliberate
legacy-ordering mutation alone survives the 15-case feature file and fails
exactly LNEX5 and LNEX8 in the complete 1,040-test pre-existing package run,
which has two existing skips. No compile, startup, hook, timeout, permission,
or environment failure was counted as a kill, and there are no actionable
survivors.

| Result | Count |
|---|---:|
| killed by the 15-test feature file | 18 |
| focused survivors | 1 |
| survivors killed by directly relevant pre-existing tests | 1 |
| actionable survivors | 0 |

Verdict: `pass` for the exact revision 6 artifacts. Any artifact change
invalidates the audit and requires a fresh zero-based run.
