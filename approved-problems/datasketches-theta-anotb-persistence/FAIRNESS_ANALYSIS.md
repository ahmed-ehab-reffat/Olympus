# Fairness analysis — stateful Theta A-not-B persistence

Verdict: `pass` for the immutable artifacts identified in `ARTIFACTS.sha256`.

Repository pin:
`d5cce9b3ad3f7c39faabcebb7f3934c4f73f14fc`.

Exact artifact hashes:

- `meta.md`: `959c446e9974b757fe3a105e03d3cfdaec61950c48ef8407f520ca754caf98c0`
- `test.patch`: `7f05e0d86b7b8df86362a1be9c370bc9074db47d8d710926600bae5553ae9132`
- `solution.patch`: `b145b1895ff99fd1f0e53794c7c54a86e601f0ac80f5b3915ca6e230c834ec4f`
- `Dockerfile`: `41810ee27e986f723d0c7176059da76beb5566d3b91c9180988bc66e94eb688d`

## Predicate provenance

| Logically distinct rejection predicate | Provenance | Implementation freedom preserved |
|---|---|---|
| Production code compiles and the selected 82 pre-existing tests pass. | Pinned repository contract. | No source file, helper, class split, or storage architecture is prescribed. The superseded direct-builder rejection is not selected. |
| Both builder routes return an operation backed by the supplied segment, and the exact public static `int getMaxAnotBResultBytes(int k)` sizing interface is callable. | Explicit prompt; pinned public `ThetaSetOperation` ABI; sibling builders and `MemorySegmentStatus`. | Separate heap/direct classes, one shared class, tables, arrays, or another state image all pass; the helper's implementation is not prescribed. |
| Public serialization and typed/generic restoration preserve result and continuation. | Explicit prompt and sibling set-operation lifecycle. | Tests compare public sketch state and later operations, not private fields or layout. |
| Default typed wrap uses the default seed and remains a true wrap. | Explicit overload plus stable repository default-seed convention. | Delegation or an independent implementation passes. |
| Heapification detaches and wrapping aliases, including native status. | Explicit prompt and existing `MemorySegmentStatus` API. | No caching, copy timing, or internal ownership object is observed. |
| Virgin, empty, exact, estimation, and both zero-count states survive restoration. | Explicit state list; stable Theta empty/theta semantics. | Hash order, capacity, padding, and serialization strategy remain free. |
| `setA`, `notB`, reset, direct null-`setA` reset-before-throw, and reuse are immediately visible through another wrapper. | Explicit prompt, including `SketchesArgumentException` and ordering; heap null-reset is pinned pre-existing behavior. | Tests observe only public results from independent views and do not inspect how reset is committed. |
| A capacity failure leaves the previous bytes and public state unchanged. | Explicit atomic-failure requirement. The fitting resource size is derived from the repository's public A-not-B sizing API. | No exact failure message, internal preflight order, or allocation policy is asserted. |
| Read-only heapify succeeds; typed/generic wraps allow reads and reject state mutation with `SketchesReadOnlyException`. | Explicit read-only rule and the repository's sibling exception convention. | Queries may decode eagerly or lazily; mutation detection may occur anywhere before change. |
| Wrong family, serialization version, seed hash, common empty/count/theta consistency, invalid retained hashes, duplicates, and insufficient bytes are rejected through `SketchesException`. | Explicit prompt, common Theta preamble conventions, sibling validators, and repository exception hierarchy. | No exact subclass/message or private payload order is asserted; retained-hash mutations run only when public result hashes locate the standard raw-long payload. |
| Stateless calls do not alter state. | Explicit prompt and the existing `ThetaAnotB` Javadocs. | The calculation algorithm and temporary storage are unobserved. |
| Harness base/new lanes produce real TestNG/JUnit XML and preserve process failure. | Evaluator contract and stable Maven/Surefire behavior. | No production behavior, deadline, or host-specific path is imposed. |

## Invalid-input audit

Every malformed image starts as bytes returned by the implementation. The
tests then change a common family ID to the unsupported `QUANTILES` family,
change the common serialization-version byte, set the common empty flag while
retained entries remain, set the common theta field to zero on a zero-retained
nonempty estimation image, use the wrong public seed, or take strict prefixes of
a nonempty image. When public result hashes can be located as standard raw-long
payload values, the test also substitutes zero, theta, and a duplicate. These
are invalid under every allowed implementation that
follows the announced Theta set-operation conventions. The tests do not inject
another serializer's bytes, inspect a private retained-count offset, require an
exact error string, or demand rejection at a particular internal stage.

The family test originally used `INTERSECTION`. That was corrected before the
immutable revision because it can be a structurally valid image for another
supported generic dispatch target. `QUANTILES` is unsupported by the Theta
set-operation restore API and therefore makes the negative unambiguous. The
direct exact-empty probe observes serialization/restoration rather than a
package-private flag.

## Implementation freedoms and corrected assertions

The suite uses public sketch iterators, retained counts, theta, seed hash, and
empty state for result equality. It does not use the package-private sketch
cache or package-private operation state. Reflection is used only so the hidden
test compiles on the pristine tree while reporting an absent required public
API as a behavioral failure.

Two assertions were removed during this audit:

1. repeated `toByteArray()` calls need not be byte-for-byte identical; and
2. serialization need not trim unused caller capacity.

Both would have selected the reference's compact deterministic encoding even
though the prompt says the precise internal representation is not prescribed.
A full-capacity serializer mutant is consequently classified as artificial,
not failing. No test constrains hash order, padding bytes, table versus compact
storage, helper names, batching, or exact serialized length.

The test patch does not own or rewrite any existing repository test. The
reference solution patch cleanly replaces the obsolete direct-builder
expect-exception regression with an unconditional resource-identity assertion.
The additive hidden class independently mandates direct A-not-B support, while
the base lane omits the superseded method. There is no conditional legacy
acceptance, authoring-history comment, or runtime source rewrite.

The clarified sizing clause names an already public method because the tests
compile against that ABI; it does not demand a new private helper or one storage
layout. The clarified null clause states the previously non-obvious observable
ordering exactly: a writable direct image is reset before the documented
argument exception escapes. M15 demonstrates that the test rejects only the
opposite public ordering. These clarifications remove the two provenance gaps
reported by auto-review and add no rejection predicate.

## Environment and architecture evidence

The exact environment gate uses an untouched pin, networking disabled,
arbitrary UID/GID 10001, an isolated writable test copy, a checksum-pinned JDK
and Maven, and real Surefire XML. The harness selects only those submitted-image
tools through absolute `/opt` paths; `/usr/local/bin` links expose the same tools
to solver shells. A replay with inherited `PATH=/usr/bin:/bin` and blank
`JAVA_HOME` passes, so the evaluator does not depend on host tools or preserved
Docker ENV. The harness has no product timeout, sleep, scheduler race,
filesystem alias, network dependency, privilege dependency, or host tool
requirement.

Four exact DataSketches solver patches now pass the final 82/16 composition.
They use materially independent compact/table and shared heap/direct choices;
the remaining raw patch is a 14/16 behavioral near miss at generic truncated
input and duplicate-hash validation. The reference is one compact-image architecture, not an allowed-layout
specification. Multiple plausible architectures remain valid:
separate heap/direct subclasses, a shared state object, an updatable sketch
gadget, a compact array, or a hash table.

Every assertion, compile lane, wrapper expectation, malformed input, and
resource boundary is grounded in the prompt, pinned repository behavior, or
stable Java/Theta semantics. No unresolved fairness uncertainty remains.

## Platform-path exact-version re-audit (historical Level 2)

The two changed artifacts were audited as a new immutable version. The hidden
Java test class is byte-identical to the previous revision, while generated
`test.sh` replaces bare Maven discovery with the image's absolute Maven, JDK,
toolchain, and cache. The Dockerfile's three compatibility links point to those
same provisioned binaries. This narrows environmental ambiguity without adding
a product predicate, deadline, implementation layout, or host assumption.

Fresh arbitrary-UID Phase A, exact evaluator composition, stripped-environment
base/reference lanes, and the complete reference suite pass. Pristine still
fails each focused method behaviorally, and M15 still fails only its public
reset-before-error predicate. Every logically distinct rejection predicate in
the table therefore retains the same public provenance on this exact version;
the fairness verdict is `pass`.

## Level 3 exact-version fairness audit

The logical-state additions preserve representation freedom. The theta probe
uses an implementation-produced zero-retained nonempty estimation image and
the common Theta preamble field; it does not depend on payload layout. Hash
corruption scans only the standard payload region and proceeds only when the
implementation's public result hashes are found. Alternative encodings,
ordering, padding, and serialized lengths are therefore accepted. All three
restore routes are required to reject, but only through the public
`SketchesException` hierarchy because the canonical theta validator uses
`SketchesStateException` while other envelope checks use argument exceptions.

All four exact compatible solvers and the reference pass 16/16 after these
changes. M18 and M19 fail only the public malformed-state method. Pristine and
reference base lanes pass 82/82, the complete pristine/reference suites pass
2,279/2,279 and 2,295/2,295, and the final arbitrary-UID offline environment
gate passes. No unresolved private-layout or exception-subclass requirement
remains. Verdict: `pass`.
