# Fairness analysis — ICU4X ZeroTrie cursor parity

Verdict: **pass**

Audit date: 2026-08-16

Repository: `unicode-org/icu4x @ c0846c9000467f1292e6d6a0e98db6798cf6a417`

## Audited immutable version

- `meta.md`: `4ee0a417a12d6e2dc89d3a74225b625699a631367b99ed95daf03f82c61f195d`
- `test.patch`: `1f434f99cc7735f9b1fa3bd0a665868626a98e1a9d085b80cca0e93accff27db`
- `solution.patch`: `8c57616dca3cd605da4ae12fd408ed378e8190c594f525904f862ac720326b04`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- replay manifest: `64091afc6de600a35fc8b0245b0b7659b3f726ca5e4d463fff7753fde792d75d`
- fresh gate image index:
  `sha256:9bf98566c7cab2c37a900bdf3521448a5c80188c96b6399798fa85de20f54b55`

The Level 17 addendum below is the controlling exact-version audit; earlier
inventories remain historical context.

## Predicate-to-provenance audit

| Distinct rejection predicate | Provenance | Fairness finding |
|---|---|---|
| Three named trie types expose `cursor()` and borrowed `into_cursor()` | Explicit prompt; existing ASCII conventions | Return types are inferred; no cursor name or representation is selected |
| Cursors implement Clone and advance independently | Explicit cloneable requirement; Rust value semantics | No size, timing, allocation, or clone-cost bound |
| One `step(byte)` consumes one arbitrary byte | Explicit prompt; binary trie key contract | High-bit and zero bytes are valid keys, not malformed data |
| `take_value` is destructive while descendants remain usable | Explicit prompt; repository prefix-key support | Only public values and subsequent traversal are observed |
| `is_empty` reports live and failed states | Explicit prompt; existing cursor surface | No sentinel or private state layout is required |
| Failed step and out-of-range probe are independently absorbing on concrete ExtendedCapacity and every runtime flavor, including while a span is retained | Explicit prompt; existing ASCII cursor behavior; accepted partial-span/mismatch layout; explicit per-flavor runtime requirement | Fresh cloned cursors and deterministic valid follow-up operations prove each public lifecycle; no state representation is inspected |
| `probe(i)` advances one edge and returns byte plus complete sibling total | Explicit prompt | Numeric assertions are type-inferred; mandatory public `u16` passes |
| A 256-child branch reports 256 through concrete and runtime PerfectHash cursors | Explicit value and type-erased requirements; byte domain has 256 members | Tests observe only the public count, child byte, and destination value; the field type remains inferred |
| Probe order matches existing iteration order | Explicit prompt; public `iter()` | No PHF table location or private ordering mechanism is inspected |
| Short and continuation-length spans traverse byte by byte through concrete/runtime PerfectHash and ExtendedCapacity | Accepted-layout and type-erased requirements; `reader.rs` format, per-trie options, and builder output | The same builder-produced 300-byte fixture and intermediate position are reused; no private offset, representation, or product deadline is asserted |
| 15 and 16 children work below a consumed prefix | Accepted-layout requirement; repository transition is 16 | Builder plus `get`/`iter` are oracles; no algorithm name is required |
| W=0, W=3, and W=4 offsets work | Accepted-layout requirement; reader accepts those widths | Each compact fixture is first validated by ordinary `get` |
| ExtendedCapacity PHF works through concrete and runtime cursors | Accepted-layout requirement; `options.rs:148` combines these policies | Builder-produced 32-child input; no builder selection assertion |
| Runtime dispatch preserves three stored flavors | Explicit type-erased requirement and existing variants | No enum layout, wrapper, or delegation strategy is inspected |
| Runtime SimpleAscii rejects non-ASCII formatting | Prompt preserves existing ASCII semantics; existing writer returns `fmt::Error` | Direct result check exposes a repeated dispatch bug |
| PerfectHash, ExtendedCapacity, and runtime byte writers storing each binary flavor accept non-ASCII `write_char` | Explicit streamed UTF-8 requirement and stable `fmt::Write` semantics | One scalar's standard UTF-8 bytes are observed through public lookup; no buffering or dispatch strategy |
| Fragmented `write_str`, `write!`, and closure errors work | Explicit formatting/convenience requirements; ASCII precedent | No optional writer crate, invalid UTF-8, or exact error text |
| Complete public surface works with default features disabled | Explicit prompt; supported `no_std` crate surface | Isolated Cargo path consumer invokes every named operation offline |
| Creating and using cursors does not allocate | Explicit prompt | Counting starts only after all trie/input construction and measures public cursor/lookup calls; no object-size or timing limit |
| `into_suffix_trie` returns a reusable view rooted at exact retained state | Explicit prompt addition; existing ASCII method convention | Return types remain inferred; tests observe `get`, `cursor`, clone, and emptiness without naming or inspecting the result type |
| Suffix conversion preserves partial spans and taken values | Explicit prompt addition; repository binary spans require retained state | Builder-produced keys and ordinary expected values are the oracle; no state field or reslicing strategy is selected |
| Suffix lookups are independent and preserve closure errors | Explicit reusable/non-destructive and error requirements; stable `fmt::Write` result semantics | Repeated calls and an explicit error at a live value distinguish behavior without requiring receiver mutability or internal cloning |
| With `alloc`, suffix views iterate all remaining pairs from exact retained state | Explicit Level 12 prompt; existing alloc-gated trie iteration convention | Expected entries are derived from builder inputs or the original trie's public iterator; concrete iterator type and implementation are inferred |
| Suffix iteration preserves existing format order, including PHF order | Explicit Level 12 prompt; public concrete `iter()` is the stable repository oracle | A 20-child builder-produced PHF fixture proves the oracle is non-lexical; tests compare public results and never inspect serialized tables |
| Base mode has 60 existing tests and new mode 13 real nodes | Evaluator contract; additive verifier | Exact composition proves discovery, failure, and pass states |
| Startup failures preserve their diagnostic at the output path | Environment viability protocol | `harness-startup` is an environment sentinel, never participant behavior |

## Allocation-oracle review

The no-default client runs in its own process and installs Rust's ordinary
`System` allocator behind a counting `GlobalAlloc`. It constructs all trie
values and borrowed inputs before resetting the atomic counter. The measured
window then creates and clones cursors, calls `is_empty`, `probe`, `step`,
`write_str`, `take_value`, both moved-cursor constructors, convenience lookup,
suffix conversion, repeated suffix lookup, and suffix cursor creation for
concrete and runtime surfaces. Only the total number of allocator calls is
asserted to be zero.

This directly observes the prompt's allocation-free behavior. It does not
forbid stack state, borrowed slices, enums, generic wrappers, or any particular
cursor size. Runtime initialization, Cargo, formatting of a failure message,
trie construction, and test-project creation all occur outside the counter
window. A reference mutant performing one otherwise harmless allocation in
PerfectHash `cursor()` compiles and fails only this node, while the reference
and public `u16` variant pass the complete measured surface.

## Fixture and negative-data review

No client feeds arbitrary malformed serialization. PerfectHash, long-span,
threshold, and ExtendedCapacity PHF inputs are builder-produced. Compact W=0,
W=3, and W=4 fixtures are accepted by ordinary `get` before cursor assertions.
Miss bytes and out-of-range indices are normal public operation inputs.

The 300-byte prefix crosses the repository's continuation-length decoder; it
is not a deadline or capacity stress test. Level 10 reuses that same existing
fixture for ExtendedCapacity rather than selecting another arbitrary length.
The 173-byte stopping point merely guarantees the public cursor remains inside
the span; no assertion depends on that number as a boundary. Cardinalities 15
and 16 are adjacent repository-defined cases. The non-ASCII scalar `é` has a
stable two-byte UTF-8 encoding and isolates `write_char` from already-covered
`write_str`. The runtime ExtendedCapacity call is necessary because runtime
flavor dispatch is a separately implemented public branch, not because a
private wrapper layout is expected.

Suffix iteration uses only builder-produced tries. Expected suffix pairs are
computed by stripping the consumed prefix from entries yielded by the same
concrete trie's public `iter()`. The 20-child fixture crosses the existing PHF
selection boundary and first proves that this public order differs from a
lexical sort. It therefore rejects order normalization without selecting PHF
table positions, a hash implementation, or serialized offsets.

## Implementation freedom preserved

- Cursors may share a state machine, use separate or generic structs, delegate,
  or erase runtime variants. Public return types are inferred.
- Span progress may use indices, subslices, tagged state, or another
  allocation-free value representation.
- Branch lookup and probing may use repository helpers or independent decoding.
  Public `get`/`iter`, not internal tables, are the oracles.
- Binary `total_siblings` may be `u16`, `usize`, or another ordinary integer
  representation that reports 256. No assignment selects an exact type.
- Formatting may override or inherit trait methods so long as public UTF-8 and
  stored-flavor results match.
- Closure lookup may wrap a cursor or use another streaming traversal.
- A suffix view may be a dedicated public value, the cursor itself, or another
  allocation-free representation; its concrete type and name are not pinned.
- Its alloc-gated iterator may coordinate cloned cursor state, use repository
  iteration helpers, or use another traversal. The concrete iterator type is
  inferred, and only yielded suffix/value pairs and the existing format order
  are observed.
- Production modules and helpers may be reorganized; hidden files are additive
  and randomized.
- The prompt does not prescribe private branch terminology, builder flavor,
  suffix-view layout, cursor names, object size, clone cost, or helper placement.

## Legitimate and prior-solver replay

The mandatory alternative patch exposes a public `u16 total_siblings`; it
passes 60/60 base and 13/13 focused tests on Level 12. All five successful
`agent-runs5` patches inject cleanly. They implement suffix point lookup but
predate the newly public iterator, so each passes 12/13 and fails only
`suffix_views_preserve_partial_state_and_independent_lookup`. Their base lanes
also pass: 62/62 for Nova 1 because its patch adds two tests and 60/60 for Nova
2-5. The resulting 0/5 is compatibility evidence, not fresh calibration and
not evidence that an alternate conforming iterator architecture fails.

The reference deliberately uses the cursor itself as the inferred suffix view.
The prompt and clients also permit a separate view type. A conforming `u16`
implementation supplies the same behavior with a different public count type.
Four Level 12 plausible incorrect variants compile and pass all 60 base tests.
Rejecting non-ASCII only in the runtime ExtendedCapacity writer fails only the
write node. Omitting the retained root value, omitting the first retained edge,
or lexically sorting suffix branches each fails only the suffix node at 12/13.
These are behavioral predicates rather than API-layout checks. The conforming
public-`u16` replay demonstrates that the widened sibling count remains
type-neutral.

## Harness and delivery fairness

Each behavior source is compiled through an isolated offline Cargo path
dependency against the exact composed source, so stale rlibs cannot satisfy a
client. The gate uses networking disabled, read-only source, and UID 10001.
Baseline/reference focused JUnit identities match; reference and conforming
alternate implementations pass their complete base lane and all 13 focused
nodes. There are no sleeps, retries, performance
deadlines, silence checks, progress markers, or quiescence predicates.

All non-mandated test-source paths contain random hexadecimal suffixes. The flagged
`cursor_parity_cases_7e1f/extended_capacity.rs` path and banned names are
absent. If collection fails, fallback JUnit includes the XML-escaped underlying
Cargo diagnostic; a forced status-102 failure produced XML accepted by
`xmllint` with the missing-package and metadata-command errors intact.

## Corrected and rejected concerns

- Exact-`usize` and exact-`u8` sibling-count annotations and stale-rlib
  discovery remain removed.
- The prompt identifies the public 256 value and per-flavor non-ASCII results
  without describing a private branch-count encoding or selecting an
  implementation.
- The no-default/allocation rule appears once for the always-available API.
  The suffix paragraph states only the distinct `alloc` feature gate on
  iteration and does not repeat the allocation-free contract.
- The runtime 256 check reuses the concrete builder-produced trie and public
  iterator oracle. A conforming public `u16` result and three distinct runtime
  wrapper architectures pass.
- The integration-driver preamble now explains inferred public consumers; it
  contains no grader, JUnit, or reporting rationale.
- Private fields, table offsets, malformed bytes, object sizes, clone cost,
  allocator timing outside the promised operations, and deadlines are rejected.
- The 256, 32, and 15/16 fixtures cross separate public boundaries rather than
  repeating one fanout stress case.
- Sticky-failure checks reuse existing builder-produced fixtures and inferred
  cursor/result types. Separate step and probe mutants for concrete
  ExtendedCapacity and each runtime flavor fail only the intended existing
  node; no private poison flag, enum variant, or rollback mechanism is required.
- ExtendedCapacity partial-span checks reuse the PerfectHash long-span keys and
  ordinary `get` oracle. Variant-wide span truncation, runtime-only state loss,
  recoverable mid-span mismatch, and recoverable mid-span probe mutants each
  fail only the long-span node at 11/12; no field, decoder helper, or wrapper
  architecture is prescribed.
- Suffix checks reuse the same builder-produced continuation span and public
  key/value map. The stopping point selects a logical partial-span state, not a
  private offset. The exact result type is inferred, and closure failure is
  checked only because the public contract states it.
- Suffix ordering uses the original trie's public iterator as its oracle. The
  PHF fixture exists because a lexical implementation otherwise survives the
  smaller fixtures; no test derives or asserts a private PHF layout.

## Verdict

Every rejection predicate is grounded in the public prompt, discoverable
repository behavior, or stable Rust semantics. Type-neutral, structurally
different, and no-default legitimate implementations pass. Harness-only
sentinels are separated from participant behavior. No unresolved uncertainty
remains. Verdict: **pass** for the exact Level 12 hashes above.

## Level 13 exact-version predicate audit

This audit was rerun after the final runtime-flavor assertion changed
`test.patch`; no earlier verdict is carried forward.

| Distinct rejection predicate | Public/repository provenance | Fairness finding |
|---|---|---|
| An `alloc` suffix view exposes `to_owned()` | Explicit prompt; existing ZeroTrie types use `to_owned()` for borrowed-to-owned conversion | The caller infers the return type; no wrapper name, store type, or representation is required |
| The owned result outlives the source trie and store | Explicit self-contained requirement; stable Rust ownership and lifetime semantics | Inner lexical scopes prove independence without inspecting fields, memory, or serialization |
| Materialization preserves a partial-span position | Explicit exact-current-state requirement; accepted span layouts are repository-visible | Builder-produced keys and public `get`/cursor/iterator behavior are the only oracles |
| Materialization preserves untaken and taken values | Explicit destructive `take_value` and exact-state requirements | Public empty-key lookup distinguishes the two lifecycle states; no sentinel is observed |
| Owned results support point lookup, cursor traversal, formatting, cloning, and iteration | Explicit owned-view usability plus the already stated suffix surface | Operations are invoked on inferred values; no trait-object or concrete API architecture is selected |
| Runtime owned materialization preserves stored flavor | Explicit runtime-flavor requirement | SimpleAscii's established non-ASCII `fmt::Error` is a public semantic discriminator even when key/value contents are identical |
| Runtime PerfectHash and ExtendedCapacity suffix formatting accepts non-ASCII and preserves closure errors | Explicit streamed UTF-8 and closure-error requirements across stored flavors | Uses valid Unicode and an explicit `fmt::Error`; no buffering, decoder, or dispatch implementation is selected |
| Runtime cursor use for all three flavors allocates zero bytes with default features disabled | Explicit complete no-default/no-allocation requirement | All trie and key construction occurs before the counter reset; only promised cursor, clone, step, probe, lookup, and suffix conversion operations are measured |
| Expanded cursor documentation no longer says only two old ASCII types are supported | Public API accuracy | Reference-quality correction only; hidden tests do not reject on wording |

The ownership check does not require the owned view to reuse serialized bytes,
rebuild entries, implement a named trait, return a particular public type, or
allocate a particular amount. Allocation is allowed for `to_owned()` itself.
The result is judged only through its public behavior after every source value
has left scope.

The no-default allocator predicate is separate. Its inputs are built before
measurement and it never calls `iter()` or `to_owned()`, the two explicitly
`alloc`-gated producers. It therefore tests the prompt's allocation-free cursor
surface without extending that promise to the new owned result.

All fixture bytes are either builder-produced or first validated with ordinary
public lookup. Non-ASCII formatting uses stable `core::fmt::Write::write_char`
semantics and valid UTF-8. Closure-error checks inject `fmt::Error` directly and
assert only that lookup produces no value. No error message, buffering pattern,
callback count, or invalid-byte policy is constrained.

The complete public-`u16` alternative passes 60/60 base and 13/13 focused,
demonstrating that sibling totals remain type-neutral. The five structurally
different Level 12 implementations all compose successfully and pass the 12
unchanged behavioral nodes; they fail the newly explicit ownership API at
compile time because their views still borrow the source. This is a fair
rejection of the new source-independence requirement, not an API-name or layout
pin.

Harness behavior remains non-behavioral: randomized test paths avoid collision,
`base` and `new` modes preserve the same 13 testcase identities, and a
pre-collection failure produces diagnostic-bearing `harness-startup` JUnit.
There is no network access, arbitrary deadline, stale rlib search, exact integer
annotation, malformed serialization, or production-file overlap.

Every final Level 13 predicate is grounded in the prompt, discoverable public
repository behavior, or stable Rust semantics. Legitimate type-width and
representation alternatives pass, and no unresolved predicate remains.
Verdict: **pass** for the Level 13 hashes at the top of this record.

## Level 14 exact-version predicate audit

This audit was rerun after the final Level 14 submission-artifact change. No
earlier fairness verdict is carried forward.

| Distinct rejection predicate | Public/repository provenance | Fairness finding |
|---|---|---|
| Initially empty concrete/runtime cursors convert to empty reusable suffix views | Explicit prompt; existing `is_empty`, suffix lookup, cursor, clone, and iteration semantics | Uses valid empty stores and inferred view types; no empty sentinel or field is selected |
| Already-failed cursors convert to empty reusable suffix views | Explicit absorbing-failure and suffix-state requirements | Failure is produced by an ordinary missing edge, then only public consumers are invoked |
| Alloc-owned suffix output exposes `as_bytes()`, `byte_len()`, and consuming `into_store()` | Explicit Level 14 contract; the same public storage surface exists on repository trie types | Return type and store construction are inferred; only byte-length consistency and accepted public readers are observed |
| Borrowed and consumed stores reconstruct the exact suffix map | Explicit ordinary-store interoperability and exact-state requirements | Public `from_store`, `iter`, lookup, and cursor behavior are the oracle; byte-for-byte canonical output is never compared |
| Runtime results remain usable through the originating concrete flavor | Explicit runtime stored-flavor requirement and public conversion constructors | The test knows the flavor from the trie it built; it does not inspect a private enum or serialized tag |
| Reconstructed output supports a second cursor/suffix/ownership generation | Explicit further-conversion requirement; stable public ownership semantics | Intermediate values are dropped and only the recursively remaining map is compared; no recursion implementation or cache policy is prescribed |
| Empty owned results expose zero-length valid stores | Explicit empty-view and ordinary-store requirements; repository empty stores are valid | Empty slices are public valid inputs, not malformed serialization or a private sentinel check |

All result variables are type-inferred. No public wrapper name, exact result
type, field, trait-object choice, or backing-store type is asserted. Concrete
binary `to_owned()` may return the existing typed trie or any interoperable
result with the required surface; runtime output may be an enum, wrapper, or
other value. Solvers may collect entries, incrementally encode, cache a valid
store, or use another strategy.

The verifier does not compare serialized bytes with the reference or prescribe
a canonical encoder. This boundary was tested directly during the
false-positive audit: rebuilding a runtime owned store through the PerfectHash
collector still produced bytes accepted by the known corresponding public
constructors and passed all 13 focused plus 60 existing tests. It was rejected
as a hidden discriminator because failing it would require a private encoding
distinction. The contract is interpreted behaviorally: a valid corresponding
store with exact suffix semantics conforms.

The raw-state trajectory mutant is fairly rejected because its exposed bytes
are not a serialized suffix map: reparsing them loses the unconsumed portion of
a public partial span. The empty-resurrection mutant is fairly rejected because
an empty public view immediately reports a value. Both compile and pass the
other 12 focused nodes, isolating the new public predicates. All five prior
solver patches also compose and pass those other nodes; their missing storage
surface is a direct absence of the new explicit API, not a layout mismatch.

Existing exclusions remain in force: exact sibling-count integer types,
canonical bytes, private flavor tags, malformed stores, result names, state
fields, allocation amount or strategy under `alloc`, timing, object size,
builder selection, and helper placement. The public-`u16` alternative passes
60/60 plus 13/13, confirming the earlier type-neutral guarantee.

Harness predicates remain environment-only. The 15 test paths are unique and
randomized, `base` and `new` are supported, no production path appears in
`test.patch`, and status-102 pre-collection failure produces XML-valid JUnit
containing the escaped underlying diagnostic. Exact lanes use no network,
read-only source, UID/GID 10001, Rust 1.97.1, and nextest 0.9.140.

Every Level 14 rejection predicate is grounded in the explicit public prompt,
discoverable repository APIs, or stable Rust semantics. The alternative type
width and behaviorally conforming serialization architecture pass. No
unresolved uncertainty remains. Verdict: **pass** for the Level 14 hashes at
the top of this record.

## Level 14.1 exact-version predicate audit

This addendum controls the immutable hashes at the top of the record. The
reported unfair predicate was confirmed: the old empty-owned macro consumed
`owned.clone().into_store()` and immediately called `store.is_empty()`. The
prompt explicitly leaves the store type unspecified, and the repository's
generic `ZeroTrie<Store>::into_store(self) -> Store` supplies no inherent
method guarantee. That compile-time requirement was therefore removed.

The replacement is public and behavioral. Each of the ten initially-empty or
already-failed producer cases supplies its known originating concrete
constructor to the macro. The inferred consumed store is passed directly to
that constructor, and the reconstructed trie must report `is_empty()`, miss
the empty key, and produce no iterator item. The test neither names the store
type nor invokes `AsRef` itself. A custom wrapper is valid so long as normal
constructor inference accepts it, exactly matching the participant-facing
interoperability requirement.

The materially different legitimate replay makes this concrete. A reference
variant returns a public `ZeroTrieOwnedStore(Vec<u8>)` implementing
`AsRef<[u8]>` and deliberately provides no inherent `is_empty()` method. It
passes all 60 existing and 13 focused tests. The mandatory public-`u16`
architecture also remains 60/60 plus 13/13. Thus the two previously identified
API-shape freedoms—count width and consumed-store type—are both demonstrated,
not merely inferred.

Every remaining predicate is unchanged and retains its Level 14 provenance.
The empty-resurrection mutant fails at 12/13 because the suffix view itself is
observably nonempty. The raw continuation-store mutant fails at 12/13 because
public reconstruction loses an unconsumed span. The PerfectHash-normalized
store passes 13/13 and 60/60 because it is behaviorally valid; no canonical
serialization assertion was introduced.

The reported PID/case temporary-directory naming and lack of pre-setup cleanup
were reviewed as reliability observations, not participant rejection
predicates. Evaluator cases run in fresh processes and exact lanes completed
without stale-state contamination. The harness was not changed in this
fairness-only repair; a forced pre-collection failure still produces XML-valid
JUnit with its underlying Cargo diagnostic. Any future evidence of concurrent
same-process reuse should be handled as an environment defect and should not
be scored against a solver.

Static inspection confirms 15 unique randomized/configuration paths, no
production changes in `test.patch`, no direct consumed-store `is_empty()` call,
no exact `total_siblings` type assignment, and no package installation. All
five historical patches compose and remain 12/13 only on the explicit owned
storage surface.

No unresolved unfair rejection predicate remains. Verdict: **pass** for the
exact Level 14.1 hashes.

## Level 14.2 exact-version predicate audit

This is the controlling assertion-by-assertion fairness audit for the immutable
hashes at the top of this record. The reported defect is confirmed: the prompt
requires suffix key/value content and existing iteration order but leaves the
view and iterator result types inferred. The repository does not establish one
runtime key representation: concrete SimpleAscii iteration yields `String`,
concrete PerfectHash and ExtendedCapacity iteration yields `Vec<u8>`, and the
runtime trie has no prior iterator method.

Two compile-time predicates in the randomized suffix client were therefore
removed:

| Removed rejection predicate | Why it was unfair | Replacement |
|---|---|---|
| Direct equality between inferred runtime SimpleAscii iterator items and `Vec<(Vec<u8>, usize)>` | Selected `Vec<u8>` despite the explicit return-type freedom and conflicting neighboring precedents | A generic helper accepts `K: AsRef<[u8]>`, copies only the public byte view for comparison, and preserves exact sequence and values |
| Equality between `Option<(K, usize)>` and `None` | Incidentally required the otherwise unspecified `K` to implement `PartialEq` | `next().is_none()` observes only iterator exhaustion |

The same normalization is used for shared concrete/runtime and owned iterator
comparisons because the type-erased method has one associated item type across
stored flavors. It does not prescribe allocation, ownership, enum layout,
storage fields, serialization, sorting, batching, or a concrete key type.
`AsRef<[u8]>` is the repository-common public byte-view surface implemented by
the neighboring `String` and `Vec<u8>` key types and by standard boxed byte
slices.

The direct legitimate-architecture replay uses a public custom key wrapper
that implements `AsRef<[u8]>`; it is neither `Vec<u8>` nor `String` and
deliberately lacks `PartialEq`. It passes 60/60 existing and 13/13 focused
tests. The ordinary reference and mandatory public-`u16` variant also pass
60/60 plus 13/13. This is stronger evidence than historical solver convergence
on `Vec<u8>`.

Every other rejection predicate is unchanged and retains the provenance in
the complete table above. The five run7 patches still score 12/13, both
actionable public mutants still score 12/13, and the behaviorally conforming
reserialization variant still passes 13/13 plus 60/60 and remains accepted.
The exact offline environment, patch-shape, JUnit, and startup-diagnostic gates
pass. The memory-starved parallel replay was quarantined and replaced by
serial evidence.

Verdict: **pass** with no unresolved uncertainty for the exact Level 14.2
hashes. Fresh calibration is **0/10** and the expected result remains **0-1
successful solvers out of 10**, targeting one borderline success.

## Level 14.3 exact-version predicate audit

This is the controlling assertion-by-assertion audit for the hashes at the top
of this record.

The run8 rejection predicate was unfair. The prompt requires suffix iteration
on the returned suffix view, then separately requires an owned result with
`get`, `cursor`, `as_bytes`, `byte_len`, and consuming `into_store`; it
explicitly leaves that owned concrete type open. The existing runtime
`ZeroTrie` has no general `iter()` precedent. Direct calls to `owned.iter()`
therefore selected an extra method and rejected the legitimate
`ZeroTrie<Vec<u8>>` result used independently by all five run8 solvers.

| Changed rejection predicate | Public/repository provenance | Fairness finding |
|---|---|---|
| Exact owned suffix entries and iteration order are checked after reconstruction from `as_bytes()` and `into_store()` | Explicit serialized-store interoperability and ordinary public concrete constructors/iterators | Fair: observes the required bytes and consumed store without selecting the owned result type or requiring its own iterator |
| Inferred suffix values support `clone()` and `is_empty()` with `default-features = false` | Explicit cloneable-view and `is_empty` requirements; prompt excludes only iteration from the no-default surface | Fair: return types remain inferred, no trait bound is named beyond calling the required method, and no representation or cost bound is imposed |
| Clone, emptiness, and lookup allocate zero in the no-default client | Explicit no-allocation cursor/suffix surface; stable counting-allocator observation | Fair: all trie construction occurs before the counter reset, and only public suffix operations are observed afterward |

The repaired owned checks retain exact content, values, cardinality, format
order, borrow reconstruction, consuming reconstruction, and recursive
re-rooting. They do not prescribe serialization bytes, concrete owned/view/key
types, storage fields, builders, or flavor normalization. Numeric sibling
assertions remain type-inferred.

All five run8 architectures now pass 13/13, as do a custom iterator-key wrapper
without `PartialEq`, a custom consumed-store wrapper without inherent Vec-like
methods, and the behaviorally conforming flavor-rebuilding owned result. The
new alloc-gated-Clone mutant fails only the explicit no-default predicate at
12/13. Existing empty-resurrection and raw-continuation mutants retain their
isolated public failures. This architecture replay removes the uncertainty
identified by the mismatch reports.

Harness predicates remain environmental rather than participant-specific: the
exact gate runs offline as arbitrary UID with read-only source, requires real
JUnit identities, and treats startup fallback as status 102. The forced
fallback preserves the underlying missing `displaydoc` and failed offline
`cargo metadata` diagnostics. Static inspection confirms 15 unique test-only
paths, no duplicate diff entries, no package installation, no exact count
type, no direct consumed-store method, and no direct owned-runtime iterator
requirement.

Verdict: **pass** with no unresolved uncertainty for the exact Level 14.3
hashes. Fresh calibration is **0/10**. The expected result after hardening is
**7-10 successful solvers out of 10**, based on observed 5/5 compatibility and
the limited scope of the new feature-gate probe.

## Level 15 exact-version predicate audit

This is the controlling fairness audit for `meta.md`
`50ff4f6e999ed14edbeb8e99130cc9a70a2091a955d243a7d07bfc9d1ee8b5e7`
and `test.patch`
`35ace96b1c98119d358ae08827b4d0cb8b4b25ba1a915bd368964b1ec90cbcd9`.

The one new rejection family checks exact stored values across visible varint
widths. It is grounded twice: the public trie API already maps keys to
`usize`, and the prompt requires the new cursor and suffix surfaces to expose
the current/remaining values. The fixture contains only valid entries produced
by the existing public builders; it does not inject malformed serialization or
prescribe how values are decoded.

| Predicate | Provenance | Fairness result |
|---|---|---|
| Concrete and erased `take_value` return values at 15/16, 2,063/2,064, 264,207/264,208, and `usize::MAX` | Existing `usize` value API and visible repository varint/builder behavior | Fair; exact value preservation is semantic, not a field/layout choice |
| Indexed probing returns those same child values in concrete format order | Explicit probe advancement/order contract; expected order comes from public concrete `iter()` | Fair; no lexical order, hash algorithm, or sibling-count type is selected |
| Suffix iteration and owned reconstruction preserve the same values | Explicit remaining-entry iteration and serialized-store interoperability | Fair; inferred key bytes are normalized with `AsRef<[u8]>`, and owned concrete/store types remain inferred |
| The same checks run for PerfectHash and ExtendedCapacity, concrete and erased | Explicit listed trie types and stored-flavor dispatch | Fair; these are independently implemented public producer modes |

An early prototype asserted that `step(byte)` returned `Some(byte)`. Nova 4
legitimately implements `step` with unit return, and the public contract does
not prescribe a return type, so that predicate was removed before the patch was
admitted. The final test merely calls `step` and observes `take_value`.

No exact `total_siblings` type, concrete cursor/view/iterator/owned/store type,
serialization bytes, iterator key representation, direct consumed-store
method, allocation strategy, or private reader function is asserted. The
participant can delegate to the existing reader, decode independently, or
materialize alloc-gated suffix data. All five run8 and all seven successful
run9 architectures pass the final predicate.

The concise prompt changes presentation only: every behavioral requirement has
an unchanged strongest predicate except the newly completed value-width cell.
The targeted two-width mutant's 13/13 old-suite pass and isolated new failure
show that the added rejection is behavioral and distinct.

The final no-cache environment replay passed for these exact hashes: pristine
separates at 0/14, while reference, public-`u16`, all five run8 successes, and
three representative run9 successes pass 14/14 without environment sentinels.

Verdict: **pass** with no unresolved fairness uncertainty for Level 15. Fresh
calibration is **0/10**; expected fresh success is **6-8/10, centered on
7/10**.

## Level 15.1 exact-version predicate audit

This audit is bound to `meta.md`
`2243eeb63f682636e5fa7a1dedfe1f3218d78f079e1396af13af14ff19bb206a`
and the unchanged Level 15 test, solution, Dockerfile, and replay-manifest
hashes.

The revised sibling-count sentence states the behavioral capacity directly.
Tests compare inferred numeric values, including 256, and contain no explicit
`u8`, `u16`, or `usize` assignment. The suffix-view sentence requires only the
listed methods and lifecycle behavior on an inferred result. The alloc prose
retains iteration and ownership without prescribing a heading-derived API
shape. Finally, saying that the owned representation and serialization are up
to the implementer preserves the existing freedom: tests observe only the
required methods and round trip through the corresponding public concrete
constructor.

No compile lane or assertion changed. The public-`u16`, custom iterator-key,
custom consumed-store, flavor-rebuilding, and twelve historical successful
architectures remain legitimate. The exact environment replay passes all nine
mandatory alternative patches, while pristine still separates at 0/14. The
full-width truncation mutant fails only its explicit semantic predicate at
13/14 and passes all 60 pre-existing tests.

No named cursor/view/iterator/owned/store type, private layout, serialization
byte sequence, sibling-count integer, `step` return type, unstated allocation,
or hidden timing constraint is imposed. Verdict: **pass** with no unresolved
fairness uncertainty for Level 15.1. Fresh calibration is **0/10** and expected
fresh success remains **6-8/10, centered on 7/10**.

## Level 16 exact-version predicate audit

This audit covers every new logical rejection predicate for the hashes at the
top of this record. The prompt now deliberately fixes the public probe result
as `ByteProbeResult { byte: u8, total_siblings: usize }`; this resolves the
earlier type ambiguity, so compiling that named interface is public contract,
not a hidden type choice. The tests still avoid redundant typed assignments.

| Predicate | Public/repository provenance | Fairness result |
|---|---|---|
| `ByteTrieEvent` exposes `Push(u8)`, `Value(usize)`, and `Pop` | Explicit public contract; existing byte-key and `usize` value domains | Fair; no derives, discriminants, memory layout, or extra trait implementations are selected |
| `visit` emits a value before descendants and encloses every probed child with push/pop in format order | Explicit event-walk contract; public probe/iterator order is the oracle | Fair; reconstruction observes only public events and accepts recursive, iterative, delegated, or materialized implementations |
| The first visitor error is returned and the suffix view remains reusable | Explicit fallible/reusable contract and stable Rust `Result` semantics | Fair; the error value and callback count are public observations, with no batching or internal state expectation |
| View `len()` equals emitted values at root, partial, taken, and failed states | Explicit cardinality definition | Fair; no cached-versus-computed strategy or complexity bound is asserted |
| Core traversal allocates no heap with default features disabled | Explicit resource and feature requirement | Fair; all trie construction precedes the counting-allocator reset, and only public clone, len, visit, and lookup calls are measured |
| `iter()` implements the three named standard iterator traits | Explicit alloc contract and stable standard-library traits | Fair; the iterator concrete type, storage strategy, and key representation remain inferred |
| Reverse order, mixed pulls, precise remaining length, and fused exhaustion hold | Explicit directional/cardinality semantics of those traits | Fair; expected order comes from each trie's existing public iterator, and key types are normalized only through `AsRef<[u8]>` |

The new fixtures are produced by ordinary public builders. They contain valid
zero/high bytes and wide values already in the trie's domain, not malformed
serialization. Runtime SimpleAscii is checked only through behavior applicable
to its erased suffix view. Concrete ExtendedCapacity and PerfectHash plus all
three erased flavors are independent public branches, so replaying each is not
private implementation leakage.

No test names a cursor, suffix-view, iterator, owned-result, key, or store
concrete type. It does not prescribe eager versus lazy iteration, recursion
versus an explicit stack, caching, serialization bytes, PHF internals, event
enum layout, or a time limit. The all-prefix topology matrix was rejected when
it failed to separate any run10 architecture. The admitted no-`Pop` and
missing-standard-trait mutants each violate an expressly documented behavior
and are isolated from the predecessor suite.

The exact environment gate passes reference at 60/60 plus 15/15 and separates
pristine at 60/60 plus 0/15, with matching JUnit identities. Verdict: **pass**
with no unresolved uncertainty for Level 16. Fresh calibration is **0/10**.
Expected fresh success is **1-2/10, centered on one borderline success**.

## Level 17 exact-version predicate audit

This audit covers every changed rejection predicate for the Level 17 hashes
recorded in `ENVIRONMENT.md`; all unchanged Level 16 predicates retain their
prior pass verdict.

| Predicate | Public/repository provenance | Fairness result |
|---|---|---|
| Core cursor and suffix operations make zero heap allocations with all features enabled | The prompt now says these operations allocate no heap with any feature set | Fair; builders, expected maps, and alloc-only iteration/ownership are outside the measured interval |
| The callback is not invoked after its first `Err` | The prompt directly requires returning the first callback error before another invocation | Fair; exact count observes public callback behavior, not recursion, batching, or error storage |
| SimpleAscii and ASCII-ignore-case suffix tries provide `len` and `visit` | The prompt names both established cursor producers and their returned concrete reusable suffix tries | Fair; tests use inferred existing return values and require no new named view type |
| Legacy event content/order equals existing iterator content/order | The prompt says events reproduce existing iterator output | Fair; keys are normalized only through `AsRef<[u8]>`, and no iterator item type, case-normalization strategy, or serialization is selected |
| Legacy root/partial/taken/failed views remain reusable | Explicit suffix-state and destructive-value semantics already required across the task | Fair; these are externally reachable cursor states, not fabricated serialized bytes |

The public probe interface remains exactly the named
`Option<ByteProbeResult>` with `byte: u8` and `total_siblings: usize`; tests add
no redundant typed assignment. All suffix view, iterator-key, owned result,
store, and serialization representations remain inferred. The new allocator
client observes seven public producer variants but imposes no complexity,
stack, cache, eager/lazy, reader-layout, or implementation-path requirement.

Two materially different run11 implementations, Nova 5 and Nova 10, pass the
new legacy methods and all 16 nodes without adopting the reference state
machine. The eager-allocation and deferred-error mutants pass the complete
pre-existing 60-test suite and every unrelated hidden node, confirming that
the new predicates reject only their explicit public violations. Fixtures are
builder-produced valid tries; no malformed bytes or timeout predicate is used.

The exact environment gate passes reference and both alternatives at 60/60
plus 16/16, while pristine passes 60/60 and fails all 16 named nodes. Verdict:
**pass**, with no unresolved fairness uncertainty for Level 17. Fresh
calibration is **0/10** and expected fresh success is **1-3/10, centered on
2/10**.
