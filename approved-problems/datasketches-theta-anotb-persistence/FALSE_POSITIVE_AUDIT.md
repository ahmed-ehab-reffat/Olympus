# False-positive audit — stateful Theta A-not-B persistence

Verdict: `pass` for the immutable artifacts identified in `ARTIFACTS.sha256`.

Exact artifact hashes:

- `meta.md`: `959c446e9974b757fe3a105e03d3cfdaec61950c48ef8407f520ca754caf98c0`
- `test.patch`: `7f05e0d86b7b8df86362a1be9c370bc9074db47d8d710926600bae5553ae9132`
- `solution.patch`: `b145b1895ff99fd1f0e53794c7c54a86e601f0ac80f5b3915ca6e230c834ec4f`
- `Dockerfile`: `41810ee27e986f723d0c7176059da76beb5566d3b91c9180988bc66e94eb688d`

## Requirement-to-strongest-test map

| Participant-facing requirement | Strongest discriminator |
|---|---|
| Both direct builder routes and all public restoration factories. | `publicFactoriesAndBothBuilderRoutesAreAvailable`, exact continuation, reset/reuse, and read-only dispatch. |
| Exact public static `int getMaxAnotBResultBytes(int k)` sizing interface. | Focused-test compilation plus direct exact, estimation, live-view, and capacity allocations made from the returned size. |
| Virgin, empty, exact, estimation, and zero-retained nonempty state. | The two state-family methods, including heap and direct producers plus exact direct-image restoration. |
| Heap detachment versus live wrapping. | Source-byte destruction, same-resource checks, two live views, and native/off-heap status. |
| Immediate synchronization after `setA`, every `notB`, and reset. | Shared-view mutation, direct estimation continuation, reset/reuse, and null-`setA` reset. |
| Atomic capacity rejection. | Full-resource and public-result equality before/after a failed larger `setA`. |
| Continuation, interim result, final reset, and reuse. | Exact uninterrupted/checkpoint parity, estimation view continuation, and unrelated second operation. |
| Seed preservation and validation. | Nondefault heap and direct producers plus wrong expected-seed restoration. |
| Stateless independence. | Serialized state equality before/after a heap stateless call and read-only stateless behavior. |
| Read-only nonmutation. | Detached heapify plus typed/generic wrap queries and all three state mutators. |
| Common envelope and logical-state validation. | Implementation-produced wrong-family, wrong-version, inconsistent-empty, isolated nonpositive-theta, invalid/duplicate retained-hash, seed-mismatch, and truncated images across generic and typed entry points. |

## Mutation set

Nineteen one-defect, compile-valid implementations were audited in isolation:

| ID | Plausible incorrect behavior | Decisive method family |
|---|---|---|
| M01 | Default typed wrap heap-copies. | Public factories/default overload. |
| M02 | Generic wrap rejects read-only images. | Read-only typed/generic matrix. |
| M03 | Direct state always stores exact theta. | Direct estimation continuation. |
| M04 | Direct construction always uses the default seed. | Custom-seed direct build. |
| M05 | Typed wrap omits family/version/empty consistency while retaining size/seed validation. | Common preamble validation. |
| M06 | Generic heapify rejects read-only input. | Read-only detached heapify. |
| M07 | Heapify retains and aliases source memory. | Detachment and memory-status tests. |
| M08 | Direct `notB` updates only object-local/heap state. | Shared views and direct continuation. |
| M09 | Reset leaves direct backing state stale. | Reset visibility and second operation. |
| M10 | Capacity checking occurs after preamble mutation. | Atomic capacity failure. |
| M11 | Every zero-retained result is marked empty. | Zero-retained estimation state. |
| M12 | A direct exact-zero state is persisted as nonempty. | Exact direct serialization/restoration. |
| M13 | Restore ignores expected seed. | Custom-seed mismatch rejection. |
| M14 | Stateless A-not-B overwrites heap state. | Stateless-state independence. |
| M15 | Null `setA` resets heap but not direct state. | Null-reset synchronization. |
| M16 | Read-only mutators defer to raw segment failures instead of the repository exception. | Read-only mutation contract. |
| M17 | Generic restore reads header bytes before checking source length. | Truncation exception family. |
| M18 | Restore omits the explicit theta-domain check while retaining empty/count and hash validation. | Zero-retained nonempty estimation image with theta set to zero. |
| M19 | Restore accepts zero, out-of-theta, or duplicate retained hashes. | Implementation-produced standard-payload hash corruptions. |

Exact final result:

```text
reference focused: 16 tests, 0 failures, 0 errors
mutations: killed=19 survived=0 invalid=0 total=19
```

## Clarified-prompt repeat audit

The requirement inventory and all 17 mutant predicates were re-audited after
the prompt change rather than carrying the prior verdict forward. For that
prompt-only revision, the executable artifacts were byte-identical to the prior
version, and the exact reference focused and complete suites were rerun
successfully. M15—the mutant
that resets heap state but leaves writable direct state unchanged before the
null argument exception—was rebuilt and replayed against the clarified version:
16 focused tests ran and exactly the named null-reset method failed. The other
16 isolated outcomes remain execution-equivalent because `test.patch`,
`solution.patch`, `Dockerfile`, repository pin, and evaluator order are
unchanged; each predicate was nevertheless checked against the revised public
text and remains grounded.

The sizing helper needs no new behavior mutant: it already exists in the
pristine public API, while the hidden class directly compiles and executes calls
to the exact owner/name/parameter/return contract. Renaming or removing it is a
straight interface violation, not a plausible implementation shortcut that can
compile the focused suite. No new survivor or artificial discriminator was
introduced by either clarification.

The suite deliberately keeps 16 solution-required TestNG method identities;
additional discriminators are conjuncts in the appropriate state/API methods,
not fixture-only identities.

## Demonstrated prior-suite survivors

M01–M06 each compiled and passed the predecessor focused suite 16/16. They
model independent public overload, dispatch, writer, seed, validator, and
resource-mutability branches rather than arbitrary predicates. Each also
passed the complete pre-existing suite in the approved offline arbitrary-UID
environment before its probe was admitted. In the final suite each is killed
by the corresponding public-behavior conjunct.

M12 was found during the final exact audit. Merely checking `getResult()` did
not kill it because compact-result canonicalization hid the corrupt persisted
empty bit. A serialization/heapification conjunct was admitted: it passes the
reference, fails M12, uses only public operations, and the containing method
continues to fail on pristine.

No final focused survivor required a complete-base lane. The reference passes
the complete pre-existing suite after exact evaluator composition. At that
earlier level there were no exact solver patches; the Level 3 audit below
supersedes that compatibility statement.

## Rejected and artificial trials

- A serializer that includes all supplied capacity or produces different but
  valid bytes on repeated calls was rejected. Neither compact length nor byte
  determinism is promised, and requiring them would prescribe the reference
  representation.
- Exact retained-hash order, zeroed unused tail bytes, a 24-byte private
  preamble, table load factors, and private helper/class layouts were rejected.
- Wrong-family testing with another supported set-operation family was
  corrected to an unsupported public family rather than treating a valid
  generic image as corrupt.
- Additional state permutations were not added once the same writer and state
  predicate were directly covered. Exact-empty and estimation-empty remain
  separate because Theta assigns them different public empty semantics.
- Product timeouts, allocation limits, and serialized-size limits are absent.

No actionable survivor remains in the attempted set. A zero-survivor result is
bounded evidence for these mutations, not proof that false positives are
impossible. Fresh calibration for this immutable version remains 0/10.

## Platform-path exact-version repeat audit (historical Level 2)

The submission-artifact change restarted this audit. The requirement map and
all 17 one-defect implementations were reconsidered against the exact hashes
above. A direct comparison shows no change at all to the hidden TestNG source;
the only `test.patch` delta is the harness's explicit image-tool selection.
`solution.patch` and the public prompt are unchanged. Consequently every
compiled behavioral predicate and each prior mutant/reference outcome is
execution-equivalent once Maven starts; none is being credited from an
environment failure.

The exact reference was freshly composed and passed 102/102 base, 16/16
focused, and 2,295/2,295 complete tests. Pristine passed 102/102 base and
produced 16/16 real behavioral failures. The most relevant actionable shortcut,
M15, was rebuilt and executed through the new stripped-environment harness: 16
tests ran, with exactly one failure in
`nullSetAResetsDirectStateBeforeReportingTheArgumentError`. No mutant can become
a survivor from the path change because the selected JDK, Maven, cache,
toolchain, compiled tests, and production inputs are identical; the repair only
ensures that execution begins.

No new shortcut, survivor, artificial predicate, or probe emerged. The exact
audit result remains `killed=17 survived=0 invalid=0 total=17`, with fresh
execution evidence for the reference, pristine, and path-sensitive M15 replay.
Fresh calibration remains 0/10.

## Level 3 mismatch and malformed-state repeat audit

The new immutable version re-audits every participant-facing requirement and
adds M18/M19 to the mutation set. The prior 17 killing assertions are unchanged
inside the additive class; removing `SetOperationTest` from the selected base
lane cannot make a focused mutant survive. M15 was nevertheless rebuilt on the
final tree and again failed exactly
`nullSetAResetsDirectStateBeforeReportingTheArgumentError`.

M18 demonstrated a real survivor during authoring. Removing only
`checkThetaCorruption` passed the first expanded suite 16/16 because its
nonempty zero-theta image was rejected by retained-hash range validation. The
probe was isolated with an implementation-produced zero-retained nonempty
estimation state. On the final hash M18 compiles and produces one failure in
`commonPreambleFamilyVersionAndEmptyConsistencyAreValidated`.

M19 removes retained-hash domain and duplicate validation while preserving the
common preamble, theta, and empty/count checks. It compiles and produces one
failure in that same validation method. The reference passes the method and all
16 focused tests. The four mandatory compatible solution patches also pass
82/82 base and 16/16 focused, showing that the probe does not select the
reference layout. Raw-long mutation is skipped when public result hashes cannot
be located, so an alternate encoding is not a false negative.

Exact final result:

```text
reference: base 82/82; focused 16/16; complete 2295/2295
pristine:  base 82/82; focused 16/16 behavioral failures; complete 2279/2279
mutations: killed=19 survived=0 invalid=0 total=19
compatible replay: 4/5 pass (the fifth is 14/16: short-header and duplicate-hash misses)
```

No actionable survivor remains in the attempted repository-grounded set.
Verdict: `pass`. This is a coverage/fairness result, not successful difficulty
hardening: compatible replay is 80%, and fresh calibration remains 0/10.
