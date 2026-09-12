# Gap analysis — ICU4X ZeroTrie cursor parity

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
maps remain historical context.

## Atomic requirement map

| Public obligation | Strongest black-box oracle | Coverage |
|---|---|---|
| `cursor()` on PerfectHash, ExtendedCapacity, and runtime tries | Span/PHF, extended, threshold, offset, and runtime clients use inferred return types | Direct |
| borrowed `into_cursor()` on all three families | Span, extended, runtime, and no-default clients move borrowed stores and advance them | Direct |
| cloneable cursors advance independently | Clones fork inside short and 300-byte spans and across concrete/runtime families | Direct |
| complete surface works without default features | An isolated `default-features = false` client compiles and runs cursor, moved cursor, clone, step, take, empty, probe, formatting, and closure lookup | Direct |
| cursor creation and use do not allocate | The same client constructs all inputs, resets a counting global allocator, exercises every operation family, and observes zero allocations | Direct |
| `step` consumes one arbitrary byte | Literal, short-span, and long-span states advance high-bit, zero, ASCII, and UTF-8 bytes individually | Direct |
| `take_value` is destructive without blocking descendants | Empty/prefix values are taken twice before continuing to longer keys | Direct |
| live and failed `is_empty` state is correct | PerfectHash and ExtendedCapacity partial spans stay live; concrete and runtime mid-span mismatches/probe failures become and stay empty | Direct |
| probing advances one byte and reports byte plus complete sibling count | Literal/span, W=0/W=3/W=4, 15/16/32, and all 256 PerfectHash indices validate result and destination; the 256 case runs through both concrete and runtime cursors | Direct |
| probe order matches existing format iteration | PerfectHash, threshold, and ExtendedCapacity PHF cases use public `iter()` as the oracle | Direct |
| failed step/probe is absorbing | Separate failed-step and out-of-range-probe cursors attempt later valid steps, probes, and value reads on concrete PerfectHash, concrete ExtendedCapacity, all three runtime flavors, and concrete/runtime ExtendedCapacity midway through a continuation span | Direct |
| every accepted layout works | Builder spans through concrete/runtime PerfectHash and ExtendedCapacity, nested 15/16 branches, PHF roots, prefix values, and `get`-validated W=0/W=3/W=4 fixtures cross separate reader arms | Direct |
| ExtendedCapacity combines PHF and wide offsets | A 32-child root exercises step/probe through concrete and runtime cursors; W=4 is checked separately | Direct |
| runtime dispatch preserves all stored flavors | SimpleAscii, PerfectHash, and ExtendedCapacity arms are traversed; SimpleAscii formatting errors are observed | Direct |
| byte cursors implement UTF-8 `fmt::Write` | Fragmented `write_str`, `write!`, and successful non-ASCII `write_char` reach concrete PerfectHash/ExtendedCapacity and runtime cursors storing both binary flavors | Direct |
| closure lookup succeeds and preserves `fmt::Error` | Success and explicit closure errors are exercised across concrete/runtime surfaces and no-default compilation | Direct |
| cursor-to-suffix conversion preserves exact logical state | Concrete PerfectHash and ExtendedCapacity plus runtime PerfectHash/ExtendedCapacity views are created midway through a 300-byte span; runtime SimpleAscii is covered separately | Direct |
| suffix views are reusable and non-destructive | Repeated `get`, cloned views, independent `cursor()` traversal, misses, and later successful queries are compared with builder inputs | Direct |
| suffix views preserve current-value consumption and closure errors | Untaken and taken prefix values are distinguished; an explicit `fmt::Error` at a live value returns no result across both concrete families and runtime dispatch | Direct |
| suffix views enumerate remaining pairs with `alloc` | Concrete and runtime PerfectHash/ExtendedCapacity plus runtime SimpleAscii views are collected repeatedly from root, partial-span, untaken-value, and taken-value states | Direct |
| suffix iteration preserves existing format order | Expected suffix pairs are derived from each concrete trie's public `iter()` after prefix stripping; a 20-child PHF fixture proves the expected order is non-lexical | Direct |
| serialization, existing ASCII behavior, builders, and `no_std` remain intact | Additive verifier ownership, 60 existing tests, no-default builds, ordinary `get`, reference, and the alternate public-`u16` architecture pass | Indirect non-regression |

## Dimensions and equivalence classes

| Dimension | Kept separate | Grouped after boundary coverage | Reason |
|---|---|---|---|
| Public family | PerfectHash, ExtendedCapacity, runtime | Owned/borrowed stores after both constructors are proved | Separate impl and dispatch surfaces |
| Runtime flavor | SimpleAscii, PerfectHash, ExtendedCapacity | Repeated values within an arm | Three arms; SimpleAscii has distinct formatting semantics |
| Reader state | literal, partial span, value, small branch, PHF, extended branch | Extra keys in one match arm | Independently implemented transitions |
| Span framing/family | one-byte length; continuation length on concrete/runtime PerfectHash and ExtendedCapacity; mismatch and bad probe while retained | More long lengths and repeated positions | Framing, per-options traversal, runtime erasure, and retained failure progress differ |
| Cardinality/surface | 15, 16 below a prefix, 32 ExtendedCapacity PHF, 256 concrete and runtime PerfectHash | Other PHF fanouts | Transition, per-type combination, count capacity, and runtime result conversion are distinct |
| Offset width | W=0, W=3, W=4 | W=1/W=2 | Zero special case, largest normal width, extended width |
| Operation | step, probe, take, empty, clone, formatting methods, closure lookup | More fragments after the method seams are crossed | Public state transitions differ |
| Lifecycle | root, partial span, available/consumed value, descendant, absorbing failure | More calls after absorption | Value and failure states differ |
| Suffix-view lifecycle | partial span, untaken value, taken value, independent child cursor, failed lookup, repeated lookup, repeated iteration | More suffix fixtures after these states | Conversion, point lookup, and enumeration are separate producer/consumer directions |
| Enumeration branch | literal/span, small branch, 20-child PHF; concrete and erased flavors | More PHF fanouts | The PHF fixture proves format order differs from lexical sorting |
| Feature/resource | alloc-enabled iteration; full non-iterating no-default API; measured zero-allocation window | Unpromised feature products | The prompt explicitly gates only iteration on `alloc` |

The suite does not take the full Cartesian product. PerfectHash's 256-child
case proves count capacity; ExtendedCapacity's 32-child case exists because
PHF selection is independently configured for that trie. Successful
non-ASCII `write_char` is checked once per independently implemented concrete
writer and once through byte-capable runtime dispatch.

## Exact false-positive audit

The startup gate inspected every `agent-runs4` raw record, patch, workspace
diff, JUnit report, log, verdict, and representative raw trajectory. Nine
solutions pass and one is a runtime-probe near-pass. Several successful
solutions and their own regression tests exercise partial spans only through
PerfectHash even though they expose distinct ExtendedCapacity wrappers,
options paths, and runtime variants. Nova 5's ExtendedCapacity long key is
walked end to end without observing retained state. This trajectory evidence,
the prompt's explicit accepted-layout rule, and repository options separation
justify the concrete/runtime ExtendedCapacity partial-span discriminator.

Fresh exact-composition mutation runs produced:

| Plausible shortcut | Focused result | Rejecting node(s) |
|---|---:|---|
| Runtime ExtendedCapacity `step` is a no-op | 10/12 | runtime dispatch; ExtendedCapacity PHF |
| Probe inside a partial span returns no result | 10/12 | span/prefix; long span |
| ExtendedCapacity/runtime cursors omit Clone | 8/12 | no-default; runtime; extended offsets; ExtendedCapacity PHF |
| All new entry points require `alloc` | 11/12 | no-default surface |
| ExtendedCapacity closure lookup ignores `fmt::Error` | 11/12 | write/closure API |
| ExtendedCapacity supports wide offsets but omits PHF | 11/12 | ExtendedCapacity PHF |
| Only convenience lookup requires `alloc` | 11/12 | no-default surface |
| Span length uses only the lead nibble | 11/12 | long-span framing |
| PHF begins at `n > 16` | 11/12 | nested 15/16 transition |
| Normal W=3 truncates to W=2 | 11/12 | normal W=0/W=3 offsets |
| Byte cursor `write_char` rejects non-ASCII while `write_str` works | 11/12 | fragmented UTF-8/write API |
| Cursor creation allocates after compiling without default features | 11/12 | no-default zero-allocation surface |
| Runtime PerfectHash narrows only its type-erased sibling total to eight bits | 11/12 | 256-child probe |
| Concrete ExtendedCapacity restores state after a failed step | 11/12 | ExtendedCapacity PHF |
| Concrete ExtendedCapacity restores state after only an out-of-range probe | 11/12 | ExtendedCapacity PHF |
| Runtime SimpleAscii restores state after a failed step | 11/12 | runtime dispatch |
| Runtime PerfectHash restores state after a failed step | 11/12 | runtime dispatch |
| Runtime ExtendedCapacity restores state after a failed step | 11/12 | runtime dispatch |
| Runtime SimpleAscii restores state after only an out-of-range probe | 11/12 | runtime dispatch |
| Runtime PerfectHash restores state after only an out-of-range probe | 11/12 | runtime dispatch |
| Runtime ExtendedCapacity restores state after only an out-of-range probe | 11/12 | runtime dispatch |
| ExtendedCapacity narrows only continuation-span length to eight bits | 11/12 | long-span state |
| Runtime ExtendedCapacity alone drops a retained span longer than 255 bytes | 11/12 | long-span state |
| ExtendedCapacity returns a recoverable mid-span byte mismatch | 11/12 | long-span state |
| ExtendedCapacity returns a recoverable out-of-range mid-span probe | 11/12 | long-span state |

The `write_char` and allocation rows are Level 7 isolation mutants. Each compiles; the first fails
only `write_api_supports_fragmented_utf8_and_errors`, and the second fails only
`public_cursor_surface_is_available_without_default_features`. The allocation
mutant uses an otherwise valid reference and performs one heap allocation in
PerfectHash `cursor()`, proving that the counter observes behavior rather than
merely feature availability. The new Level 8 mutant leaves the concrete
PerfectHash count correct but narrows only the runtime match arm; it compiles
and fails only `perfect_hash_probe_iteration_order_and_256_siblings`. The eight
Level 9 mutants are otherwise-valid reference variants. Each method/flavor
variant compiles and fails exactly the named existing node, including
probe-only variants that leave failed-step behavior correct.

The Level 10 delta is strictly additive inside the existing long-span client;
every earlier rejecting statement and client remains unchanged. The retained
21-mutant rejection map was checked against that monotonic delta, so no prior
failure can become a survivor. The four new otherwise-valid reference mutants
were freshly executed. Each compiled and passed 11/12, failing only
`multibyte_span_lengths_preserve_incremental_state`. None survived, so the
protocol did not promote a new mutant to the complete base lane.

Level 11 first replayed all ten `agent-runs4` implementations against recursive
generated-map traversal, combined 256-way PHF/wide-offset descendants, and
maximum-index failures. The same nine implementations passed, proving that
more current-contract fixtures would not harden the task. The public suffix
view addition then produced the expected 0/10 compatibility result: every old
patch passes the unchanged eleven behavior nodes and fails the two consumers
that compile the new API; Nova 7 also retains its prior probe defect. This is
diagnostic compatibility replay, not fresh Level 11 calibration.

Two otherwise-valid Level 11.1 mutants were freshly recomposed and executed. A
partial-span-discarding suffix conversion passes 12/13 and all 60 base tests,
failing only the suffix
node. An error-ignoring suffix closure initially survived 13/13 and all 60 base
tests; the public closure-error assertion was then added at a live value. On the
final immutable verifier it fails only the suffix node, while the reference and
conforming `u16` implementation pass. No actionable survivor remains.

Level 12 begins from all five supplied `agent-runs5` implementations passing
Level 11.1 at 13/13. Raw trajectories, patches, workspace diffs, reports, and
logs show five substantive two-file cursor implementations. Every patch
implements reusable suffix point lookup, but none supplies enumeration. This
is the relevant successful-solver shortcut behind the alloc-gated suffix
iterator, while the reported runtime ExtendedCapacity non-ASCII `write_char`
cell closes an independently dispatched writer branch already promised by the
public contract.

The first Level 12 suffix fixture compared small-branch output with public
iteration, but lexical sorting could accidentally pass those cases. The gap
audit caught that survivor before approval. A builder-produced 20-child PHF
fixture was added; its expected order is obtained from the concrete trie's
public `iter()` and is asserted to differ from lexical order. All exact-version
gates were restarted after that artifact change.

Four otherwise-valid Level 12 reference mutants were recomposed against the
final artifacts:

| Plausible shortcut | Base | Focused | Rejecting node |
|---|---:|---:|---|
| Runtime ExtendedCapacity alone rejects non-ASCII `write_char` | 60/60 | 12/13 | write/closure API |
| Suffix iteration omits the retained current/root value | 60/60 | 12/13 | suffix view |
| Suffix iteration drops the first retained edge | 60/60 | 12/13 | suffix view |
| Suffix iteration sorts every branch lexically | 60/60 | 12/13 | suffix view |

No mutant survived the focused suite. The complete base lane was nevertheless
run for all four and passed, demonstrating that the focused failures are new
public-contract discriminators rather than upstream regressions. Exact replay
of all five successful `agent-runs5` patches produced 12/13 focused tests for
each, with only the suffix-view node failing. Their base results were 62/62 for
Nova 1, whose patch adds two repository tests, and 60/60 for Nova 2-5. Thus the
Level 12 compatibility result is **0/5**; it is diagnostic replay, not fresh
calibration.

## Rejected and non-actionable probes

- Exact public sibling-count types remain rejected. The mandatory `u16` replay
  passes all lanes; assertions compare type-inferred values only.
- Cursor size, clone cost, timing, allocation timing before the measurement
  window, and allocator implementation details are rejected. The counter asks
  only whether explicitly allocation-free public operations allocate.
- More PHF sizes, every offset width, random/malformed bytes, and full
  family/operation products add no independently implemented boundary.
- Manual serialization is used only when ordinary `get` first validates the
  bytes; other fixtures are builder-produced.
- Private cursor names/fields, state layouts, helper placement, PHF table
  offsets, builder selection, and the concrete suffix-view return type remain
  unconstrained.
- The suffix iterator's concrete return type, item representation beyond the
  existing public iterator convention, storage strategy, and traversal
  algorithm remain unconstrained. Expected order comes from public `iter()`,
  not a serialized-table assertion.
- Randomized filenames and diagnostic-preserving fallback JUnit are evaluator
  delivery, not behavioral predicates.

## Exact results and verdict

The final restarted Level 12 no-cache gate produced baseline 60/60 base plus
0/13 focused; reference and conforming public-`u16` implementations produced
60/60 plus 13/13. All five `agent-runs5` patches accept exact evaluator-order
verifier injection. Exact compatibility replay produced 0/5 because each old
patch lacks suffix enumeration while continuing to pass the other 12 nodes.
All lanes were offline with read-only source and UID/GID 10001, and focused
JUnit identities matched.

No actionable gap survived the exact repository- and trajectory-grounded
audit. Verdict: **pass**. This is evidence for the attempted mutation set, not
a claim that false positives are impossible. Fresh Level 12 calibration is
**0/10 runs performed**; the pre-artifact forecast is **2-4 successful solvers
out of 10**.

## Level 13 exact-version coverage addendum

This addendum supersedes the Level 12 result language above. It was completed
after the final submission-artifact change and after the exact environment
restart.

### New and changed atomic requirements

| Atomic public requirement | Strongest black-box oracle | Independent dimensions covered |
|---|---|---|
| With `alloc`, a suffix view provides inferred `to_owned()` | Standalone public consumer calls the method without naming its result type | Concrete PerfectHash, concrete ExtendedCapacity, and all runtime flavors |
| The owned view is self-contained | Construct trie/store, cursor, and suffix inside an inner scope; use the owned result only after all sources are dropped | Borrowed-to-owned lifetime boundary for typed and erased producers |
| Owned materialization preserves the exact cursor state | Escaped partial-span, untaken-value, and taken-value views are queried by `get`, fresh cursor, and iteration | Span position, retained current value, consumed current value, descendants |
| Owned views remain reusable and independent | Repeat lookup, clone the view, fork cursors, and compare iteration with the public source iterator | Producer reuse, clone lifecycle, point and enumeration consumers |
| Runtime owned views preserve stored flavor | Runtime SimpleAscii owned cursor still rejects non-ASCII `write_char`; binary flavors accept it | SimpleAscii, PerfectHash, ExtendedCapacity dispatch arms |
| Runtime binary suffix views preserve non-ASCII text and closure errors | PerfectHash and ExtendedCapacity suffix views accept `write_char('🚂')` and return no value on explicit `fmt::Error` | Success/error direction across both erased binary branches |
| No-default cursor operations allocate zero bytes for every erased flavor | Build runtime inputs before resetting the counting allocator, then cursor/clone/step/probe/query/suffix operations under the counter | SimpleAscii, PerfectHash, ExtendedCapacity resource boundary |
| Public cursor documentation describes the expanded surface | Reference removes the obsolete two-flavor limitation | Documentation only; no hidden rejection predicate |

The owned materialization cells are not equivalent to borrowed suffix lookup or
iteration. All five Level 12 implementations passed those older directions but
failed compilation when an inferred materialization was required to escape its
source scope. Likewise, runtime flavor preservation is not equivalent to key
set equality: rebuilding a SimpleAscii suffix as PerfectHash preserved every
pair yet changed its public formatter behavior.

### Exact false-positive audit

Repository evidence and the five Level 12 trajectories produced four plausible
incorrect implementations. Each was applied independently to the otherwise
conforming reference and run through the final 13-node focused suite.

| Mutant | Result | Strongest failing requirement |
|---|---:|---|
| Ignore runtime suffix closure errors | 12/13 | Error preservation on erased binary suffix writers |
| Drop the untaken current value while owning a runtime PerfectHash suffix | 12/13 | Exact-state materialization |
| Rebuild a runtime SimpleAscii suffix using PerfectHash | Initially survived; 12/13 after the direct formatter probe was added | Stored-flavor preservation |
| Allocate while creating erased PerfectHash/ExtendedCapacity cursors without default features | 12/13 | All-flavor allocation-free resource contract |

The flavor-erasure survivor caused a real test revision. That revision
invalidated the candidate audit and environment verdict; both were restarted.
No mutant survives the final focused suite. The exact reference passes the
complete 60-test pre-existing suite, so no focused survivor required further
promotion.

### Rejected coverage expansions

- An exact owned result type, wrapper name, storage type, serialization, or
  rebuilding algorithm would prescribe private architecture. All result types
  remain inferred.
- Allocation is permitted for `iter()` and `to_owned()` under `alloc`; only the
  separately promised no-default, non-iterating cursor operations are measured.
- More key permutations, PHF sizes, and offset widths would repeat existing
  decoder families rather than add an ownership or dispatch boundary.
- Exact sibling-count types remain out of scope. The conforming public-`u16`
  architecture passes 60/60 base and 13/13 focused.
- Invalid bytes, object-size limits, clone-cost limits, and deadlines lack a
  public or repository-grounded requirement.

### Exact result

Pristine is 60/60 base plus 0/13 focused. Reference and public-`u16` are each
60/60 plus 13/13. All five prior successful solutions compose cleanly and score
12/13, failing only source-independent owned suffix materialization; observed
compatibility is **0/5**. No actionable coverage gap remains for the exact
Level 13 hashes. Verdict: **pass**. Fresh calibration is **0/10**, with an
expected result of **1-3 successful solvers out of 10**.

## Level 14 exact-version coverage addendum

This is the controlling audit for the hashes at the top of the record. It was
performed after the final artifact change and exact environment restart.

### New atomic requirement map

| Atomic public requirement | Strongest black-box oracle | Independent cells |
|---|---|---|
| Empty-root conversion yields an empty reusable suffix view | Convert empty concrete and runtime tries, then repeat `is_empty`, lookup, clone, cursor, iterator, ownership, bytes, and consumed-store checks | Concrete PerfectHash/ExtendedCapacity; runtime SimpleAscii/PerfectHash/ExtendedCapacity |
| Absorbing failed cursors remain empty after suffix conversion | Force a valid cursor to miss, verify failure, convert, and replay the complete empty-view consumer set | Same five producer flavors; failed lifecycle distinct from initially empty storage |
| Alloc-owned suffix results expose an ordinary serialized store | On inferred results, compare `byte_len()` with `as_bytes().len()`, borrow through the corresponding public `from_store()`, and consume a clone through `into_store()` | Concrete PerfectHash/ExtendedCapacity and all runtime flavors |
| Serialized results preserve exact logical state | Reconstructed tries yield the suffix map after partial spans and after taken or untaken current values | Partial span, retained empty key, consumed empty key, descendants |
| Runtime owned serialization remains usable as the stored public flavor | Reconstruct runtime-produced bytes/stores through the known originating concrete constructor and compare lookup/iteration/cursor behavior | SimpleAscii, PerfectHash, ExtendedCapacity |
| Ownership and serialization compose recursively | Reparse first-generation output, create a cursor, advance within that suffix, convert again, own again, drop intermediates, and compare remaining pairs | Concrete PerfectHash/ExtendedCapacity and all three runtime flavors |

These cells are not equivalent to Level 13 source independence. Four of five
run7 implementations pass every earlier node by copying cursor-state fragments,
but none can supply a valid ordinary store. Empty/failed conversion is also a
separate lifecycle: a live partial-state implementation can reinitialize or
resurrect terminal state only when producing a reusable view.

The full operation/layout map from earlier levels remains exercised unchanged:
step, probe, value consumption, sticky failures, partial and continuation
spans, 15/16 and PHF branches, 256 siblings, extended offsets, streamed UTF-8,
closure errors, all runtime arms, no-default compilation, and measured
zero-allocation cursor use. Level 14 changes only the existing randomized
suffix consumer, so those established independent branches remain visible as
the other 12 focused nodes.

### Exact false-positive audit

All five run7 solutions were freshly composed and executed. Each scores 12/13,
failing only the strengthened suffix node; compatibility is **0/5**. A
trajectory-derived raw-state mutant added the named storage methods to Nova 4
but exposed only its retained continuation vector. It compiled, passed the
other 12 nodes, and failed when a partial-span suffix was reparsed. A separate
reference mutant resurrected empty concrete suffix conversion as a valid
one-entry sentinel; it likewise scored 12/13 and failed the new empty-view
predicate. Neither survives.

A runtime consuming-store variant that reserialized all maps with the
PerfectHash builder passed 13/13 and was carried through the full existing
suite, where it passed 60/60. That survivor is non-actionable: the bytes remain
accepted by the corresponding public constructors and reproduce every
required operation. Rejecting it would require canonical byte equality or a
private flavor tag not promised by the task. No probe was added for it.

No actionable survivor remains in the attempted mutation set. Additional
empty fixtures, generation depth, byte-pattern checks, named return types, and
allocation strategies are grouped or rejected unless new trajectory evidence
shows an independently implemented public boundary.

### Exact results and verdict

The no-cache gate produced pristine 60/60 plus 0/13, reference 60/60 plus
13/13, and public-`u16` 60/60 plus 13/13. It used offline read-only sources and
UID/GID 10001, matched focused JUnit identities, and accepted exact evaluator
composition of every run7 patch. The 15 test-patch paths remain unique and
randomized, and startup JUnit retains the underlying synthetic status-102 Cargo
diagnostic.

No actionable public cell remains uncovered in this exact trajectory- and
repository-grounded audit. Verdict: **pass**. This is evidence for the tested
families, not proof that false positives are impossible. Fresh Level 14
calibration is **0/10**, with an expected **0-1 successful solvers out of 10**.

## Level 14.1 exact-version coverage addendum

This is the controlling coverage audit for the hashes at the top of this
record. The submission behavior and 13-node topology are unchanged; one
inferred-store assertion was weakened from a Vec-like method call to a public
semantic reconstruction.

### Changed predicate and coverage preservation

| Atomic requirement | Previous oracle defect | Level 14.1 oracle | Coverage result |
|---|---|---|---|
| A consumed owned-suffix store is valid input for its known public flavor and represents the same empty suffix | Called `is_empty()` directly on the inferred store, selecting an unstated inherent method | Pass the inferred store directly to the corresponding `from_store()`, then require the reconstructed trie to be empty, miss `b""`, and yield no iteration item | Direct; all ten empty/failed concrete and runtime producer cells remain covered |

The new oracle is at least as strong behaviorally: it proves that the consumed
bytes form a valid ordinary trie store and that public lookup and enumeration
observe the empty suffix. It does not call `AsRef` directly, name the store
type, or assume a method beyond the explicit owned-result surface. All other
Level 14 cells remain byte-for-byte unchanged, including partial spans,
taken/untaken values, three runtime flavors, borrowed reconstruction,
consuming reconstruction, and second-generation ownership.

### Exact false-positive audit

The reference with a custom public consumed-store wrapper implementing
`AsRef<[u8]>` but no inherent `is_empty()` passes 60/60 existing and 13/13
focused tests. This is a materially different legitimate API architecture and
directly exercises the repaired inference boundary.

The trajectory-derived Nova 4 raw-continuation exposure still scores 12/13:
its bytes cannot reconstruct a partial-span suffix. The reference mutant that
resurrects an empty concrete suffix as a one-entry view still scores 12/13 and
fails the first empty-view predicate. The behaviorally conforming runtime
PerfectHash-normalized store still passes 13/13 and, on a fresh complete run,
60/60 existing tests; it remains correctly rejected as a canonical-byte
discriminator. No new probe was added.

All five run7 implementations remain 12/13 for exact compatibility 0/5. The
repair cannot make them pass because they lack the explicitly required
`as_bytes`, `byte_len`, and `into_store` surface altogether. The exact gate
remains pristine 60/60 plus 0/13 and both reference and public-`u16` 60/60 plus
13/13.

No actionable public cell is uncovered. Verdict: **pass** for Level 14.1. The
fresh calibration batch is **0/10**, and the pre-artifact expected result
remains **0-1 successful solvers out of 10**, targeting one borderline solve.

## Level 14.2 exact-version coverage addendum

This is the controlling coverage and false-positive audit for the hashes at
the top of this record. Only the representation-neutrality of suffix iterator
comparisons changed; the 13-node topology, fixtures, lifecycle coverage, and
all participant-facing requirements are unchanged.

### Changed predicates and coverage preservation

| Atomic requirement | Previous oracle defect | Level 14.2 oracle | Coverage result |
|---|---|---|---|
| Suffix iteration returns every remaining byte key/value pair in existing format order | Runtime SimpleAscii results were directly compared to `Vec<(Vec<u8>, usize)>`, selecting `Vec<u8>` for an unspecified iterator key | Normalize each inferred key through `AsRef<[u8]>` and compare the resulting byte vector and value sequence | Direct; root, partial-state, concrete/runtime, PHF-order, owned, and recursively reconstructed cells remain covered |
| Empty and failed suffix views remain empty and reusable | `assert_eq!(iter.next(), None)` incidentally required the unspecified key type to implement `PartialEq` | Assert `iter.next().is_none()` repeatedly before and after ownership/reconstruction | Direct; all ten concrete/runtime empty and failed producer cells remain covered without a key comparison trait |

The normalization helper is generic over `K: AsRef<[u8]>`; it does not name a
concrete key type, call a key-specific method, relax order, sort results, or
drop duplicates. Therefore the strongest observable behavior remains exact
byte content, exact values, exact cardinality, and exact existing iteration
order.

### Exact false-positive audit

A reference variant whose iterator item is a public custom key wrapper with
`AsRef<[u8]>` passes 60/60 existing plus 13/13 focused tests. It has no
`PartialEq` implementation and is not `Vec<u8>`, so it directly proves both
repaired inference boundaries accept a materially different legitimate
architecture.

The trajectory-derived raw-continuation mutant and the empty-view resurrection
mutant each remain isolated at 12/13. The behaviorally conforming runtime
PerfectHash-normalized store remains a 13/13 survivor and also passes 60/60
existing tests, so it is correctly excluded from a canonical-byte rejection.
All five run7 implementations remain 12/13 for exact compatibility **0/5**.
No new behavioral probe was added.

The exact environment gate remains pristine 60/60 plus 0/13 and reference and
public-`u16` 60/60 plus 13/13. Static patch-shape and forced startup-diagnostic
checks pass. The one memory-starved parallel replay was quarantined and all
reported compatibility/mutation results were reproduced serially.

No actionable public cell is uncovered. Verdict: **pass** for Level 14.2.
Fresh calibration is **0/10**. The expected result after hardening remains
**0-1 successful solvers out of 10**, targeting one borderline success.

## Level 14.3 exact-version coverage and false-positive addendum

This is the controlling audit for the immutable hashes at the top of this
record. The 13-node topology is unchanged. One unfair producer/consumer edge
was removed and one explicit feature/resource cell was strengthened.

| Atomic requirement | Level 14.2 gap or defect | Level 14.3 strongest oracle | Coverage result |
|---|---|---|---|
| An alloc-owned suffix exposes bytes and a consumed store that reconstruct the exact remaining map; its concrete type is not prescribed | The client also called `iter()` directly on a runtime-owned result, although the prompt assigns iteration to the suffix view and the repository runtime trie has no such method | Reconstruct the known concrete stored flavor from both `as_bytes()` and `into_store()`, then compare its public iterator exactly; perform lookup/cursor/length checks on the owned result only where required | Direct without selecting an owned runtime wrapper or adding an iterator method |
| Every inferred suffix view is cloneable and exposes `is_empty` without default features | The no-default client created suffix views but exercised only lookup, formatting, and cursor creation; all-feature tests could hide these methods behind `alloc` | After the allocator reset, clone live concrete PerfectHash and ExtendedCapacity views and runtime views storing SimpleAscii, PerfectHash, and ExtendedCapacity; check original/clone emptiness and an independent lookup | Direct across concrete/runtime, all runtime producer flavors, feature-disabled compilation, and zero-allocation boundary |

All other public cells retain their Level 14.2 strongest probes: span and
prefix lifecycle, 15/16/256 sibling boundaries, normal and extended offsets,
concrete/runtime absorbing failure, streamed UTF-8 and closure errors,
empty/failed reusable suffix views, format-order iteration, source-independent
ownership, consumed-store reconstruction, and second-generation re-rooting.

### Exact false-positive audit

All five run8 implementations pass after the unfair `owned.iter()` predicate
is removed. Their shared use of the existing `ZeroTrie<Vec<u8>>` runtime owned
result is therefore accepted as a legitimate public architecture. A custom
iterator-key wrapper without `PartialEq`, a custom consumed-store wrapper with
only `AsRef<[u8]>`, and a flavor-rebuilding owned result each pass 60/60
existing plus 13/13 focused tests. These replays cover materially different
representations at every repaired inference boundary.

The new targeted mutant gates suffix-view `Clone` behind `alloc`. It compiles
and passes all other focused behavior, scores 12/13, and fails only the
no-default public-surface node with missing-`clone` errors on runtime,
PerfectHash, and ExtendedCapacity views. The empty-view resurrection and raw
partial-continuation mutants remain isolated at 12/13 on the suffix node. No
test was added for the behaviorally conforming flavor-rebuilding survivor.

The exact gate is pristine 60/60 plus 0/13, reference and public-`u16` 60/60
plus 13/13, and all five run8 solutions pass both modes. Static patch-shape and
forced startup-diagnostic checks pass. No actionable public cell is uncovered.

Verdict: **pass** for Level 14.3. Fresh calibration is **0/10**. Based on the
observed 5/5 run8 compatibility and the narrow feature-gate discriminator, the
expected result after hardening is **7-10 successful solvers out of 10**.

## Level 15 exact-version coverage and false-positive addendum

This is the controlling audit for `meta.md`
`50ff4f6e999ed14edbeb8e99130cc9a70a2091a955d243a7d07bfc9d1ee8b5e7`
and `test.patch`
`35ace96b1c98119d358ae08827b4d0cb8b4b25ba1a915bd368964b1ec90cbcd9`.
The solution and Dockerfile remain the Level 14.3 versions.

The public requirement that `take_value` expose the current node's existing
`usize` value had only small-value coverage. Every focused value was at most
172, while the repository's visible value varint crosses independent widths at
15/16, 2,063/2,064, and 264,207/264,208 and supports `usize::MAX`.

| Atomic requirement | Producer modes | Consumer/lifecycle modes | Resource surface | Strongest oracle |
|---|---|---|---|---|
| Preserve the complete stored value through new cursor APIs | PerfectHash and ExtendedCapacity; concrete and runtime-dispatched | root `take_value`; stepped child; indexed probe; suffix `get`/`iter`; `to_owned`; borrowed and consumed-store reconstruction | alloc-enabled iteration/ownership, with core cursor decoding shared by no-default behavior | Builder-produced entries at every visible value-width boundary and `usize::MAX`; compare exact values and public format order |

The new fixture uses a 20-child branch so both direct stepping and indexed
probing consume wide values. It derives expected order from each concrete
trie's existing iterator, normalizes only key bytes through `AsRef<[u8]>`, and
replays the same checks through erased PerfectHash and ExtendedCapacity. This
crosses producer flavor, dispatch, direction, lifecycle, and serialization
boundaries without adding a representation requirement.

The reference, all five run8 solutions, and all seven run9 successes pass the
probe. A cursor-only two-width decoder mutant passes the complete previous
13/13 focused suite and fails only the new value-width node. The broader
deterministic topology matrix was rejected because all legitimate
implementations passed and it did not isolate another plausible survivor.

No other atomic cell changed. The concise prompt preserves the Level 14.3
cursor, failure, span, branch, offset, UTF-8, feature, allocation, suffix,
iteration, ownership, and reconstruction obligations. Static inspection finds
16 unique test-only paths and no submission-side production edit.

The final no-cache environment replay passed for these exact hashes: pristine
is 60/60 plus 0/14; reference, public-`u16`, all five run8 successes, and three
representative run9 successes pass both existing/own and 14/14 focused lanes.

Verdict: **pass** for the exact Level 15 version. Fresh calibration is **0/10**. Historical compatibility is
**7/10** for run9 and **5/5** for run8; the expected fresh result is **6-8
successful solvers out of 10, centered on 7/10**.

## Level 15.1 exact-version coverage and false-positive addendum

This audit is bound to `meta.md`
`2243eeb63f682636e5fa7a1dedfe1f3218d78f079e1396af13af14ff19bb206a`
and the unchanged Level 15 test, solution, Dockerfile, and replay-manifest
hashes. The four wording changes preserve the same atomic cells:

| Revised prose | Strongest unchanged oracle | Coverage |
|---|---|---|
| Probe reports a sibling count wide enough for 256 children | Concrete and runtime 256-way probing with the numeric result equal to 256 | Direct; no integer type selected |
| Every cursor produces a reusable, cloneable suffix view | Concrete/runtime lookup, clone independence, empty/failed reuse, formatting, and child-cursor checks | Direct across lifecycle and flavor modes |
| `alloc` enables suffix iteration and source-independent ownership | Exact format-order iteration, ownership after source drop, and recursive reconstruction | Direct across alloc and ownership boundaries |
| Owned representation and serialization are implementation-defined beyond the required round trip | Custom key/store and flavor-rebuilding architectures plus reconstruction through `as_bytes()` and `into_store()` | Direct without a named representation |

No test node, fixture, producer mode, consumer mode, lifecycle state, feature
surface, or rejection predicate changed. The exact environment replay again
accepts reference, public-`u16`, all five run8 architectures, and three
materially different run9 architectures.

The targeted cursor decoder that reduces newly decoded values modulo 2,064 was
replayed in the exact Linux environment. Its complete pre-existing suite is
60/60 and it scores 13/14 focused nodes, failing only full-width value
preservation with `Some(255)` instead of `usize::MAX`. Because `test.patch` is
byte-identical, its previously established 13/13 predecessor-suite result is
unchanged. No new survivor or uncovered public cell results from the prose
revision.

Verdict: **pass** for Level 15.1. Fresh calibration is **0/10**; expected fresh
success remains **6-8/10, centered on 7/10**.

## Level 16 exact-version coverage and false-positive addendum

This is the controlling audit for the immutable hashes at the top of this
record. All Level 15.1 cursor, layout, runtime, formatting, suffix, ownership,
and value-width cells retain their prior strongest oracles. Level 16 adds two
public capability families:

| Atomic requirement | Producer/lifecycle modes | Direction/error/resource modes | Strongest oracle | Coverage |
|---|---|---|---|---|
| A suffix view's `len()` is its exact remaining entry count | PerfectHash and ExtendedCapacity, concrete and erased; erased SimpleAscii; root, partial span, taken root value, and failed state | Repeated query before/after a stopped visit; no-default zero-allocation client | Compare to normalized public iteration and the number of emitted `Value` events; empty/failed views report zero | Direct across every independently dispatched flavor and lifecycle boundary |
| `visit` emits `Push`, `Value`, and `Pop` in format order without changing the view | Same five producer surfaces and four lifecycle states | Value before children; matched push/pop; high and zero bytes; wide values; first-error return; post-error reuse | Reconstruct the remaining map from events and compare exactly to each concrete trie's existing iterator; inject an error on the fifth callback | Direct semantic reconstruction rather than an implementation/layout check |
| `len` and `visit` remain core, allocation-free operations | Concrete PerfectHash/ExtendedCapacity and runtime SimpleAscii/PerfectHash/ExtendedCapacity | `default-features = false`; clone/live lookups and visits after allocator reset | Isolated public client compiles and observes zero global-allocator calls while visiting all stored flavors | Direct feature and heap-resource boundary |
| Alloc suffix iteration is reversible, exact-sized, and fused | Concrete and erased binary flavors plus erased SimpleAscii | Forward, reverse, alternating front/back, remaining length, size hint, and repeated exhaustion | Compile against `DoubleEndedIterator + ExactSizeIterator + FusedIterator`; normalize only keys through `AsRef<[u8]>`; compare exact format order and its reverse | Direct across trait, direction, cardinality, and exhaustion states |

The 401-entry all-prefix differential prototype passed the reference and all
six run10 successes and was rejected as fixture inflation: it found no
distinct incorrect architecture. The admitted event-walk discriminator has
isolation evidence instead. A plausible public adapter that omits every `Pop`
event passes all 60 pre-existing tests and the complete 14-node predecessor
suite, then fails only event reconstruction in the new traversal node. Removing
the three iterator trait implementations similarly leaves predecessor behavior
unchanged and fails the new public compile bound; stale iterator length is
checked independently by mixed front/back pulls.

Reference passes 60/60 existing plus 15/15 focused tests. Pristine passes the
same 60 existing tests and fails all 15 focused nodes. The no-default client,
failed/empty traversal, partial spans, taken values, concrete/runtime dispatch,
visitor errors, iterator direction, and exhaustion cells leave no actionable
public gap. Verdict: **pass** for Level 16. Fresh calibration is **0/10**. The
expected result after hardening is **1-2 successful solvers out of 10, centered
on one borderline success**.

## Level 17 exact-version coverage and false-positive addendum

This audit is bound to the Level 17 hashes in `ENVIRONMENT.md`. Every Level 16
cursor, layout, failure, formatting, suffix, ownership, and iterator cell keeps
its strongest oracle. The shortened prompt changes presentation only. Three
public cells are completed:

| Atomic requirement | Independent modes and lifecycle states | Strongest black-box oracle | Coverage |
|---|---|---|---|
| Core cursor/suffix operations allocate no heap with any feature set | All-features concrete SimpleAscii, ignore-case, PerfectHash, ExtendedCapacity and erased SimpleAscii/PerfectHash/ExtendedCapacity | Build fixtures before enabling a global counter, then call `get`, `cursor`, `is_empty`, `len`, and `visit`; require zero allocations | Direct feature/resource boundary, independent of the no-default lane |
| A visitor error stops callbacks immediately | Legacy ASCII suffixes and concrete/runtime binary suffixes with nonempty walks | Return an error on a fixed callback and assert both the error value and exact final callback count, then reuse the view | Direct error-timing and post-error lifecycle coverage |
| Existing ASCII cursor suffixes expose exact `len` and fallible event traversal | SimpleAscii and ASCII-ignore-case; root, partial, root-value-taken, and failed cursors | Reconstruct `(key, value)` entries from public events and compare normalized bytes to each trie's existing public iterator; repeat under no-default and all-feature allocation counters | Direct across two separately implemented repository policies and four states |

The all-feature allocator deliberately excludes alloc-only `iter` and
`to_owned`: it measures only the core operations the prompt declares
allocation-free. Construction and expected-output allocation occur before the
counter is enabled. Legacy event order and stored spelling come from public
iterators, not serialized offsets or reader internals. Existing no-default
coverage still compiles cloneable suffix values and exercises binary concrete
and all erased flavors.

Two plausible survivors establish distinctness. An alloc-feature `len` that
eagerly materializes the existing iterator passes all 60 pre-existing tests
and 15/16 focused nodes, then fails only the new all-feature allocation node.
A visitor that records the first error but continues invoking the callback
also passes all 60 and 15/16, failing only the exact callback-count assertion.
Run11 Nova 5 and Nova 10 independently pass the added legacy surface; Nova 3,
4, 6, and 9 omit one or both public methods and are rejected at that new
surface rather than by another fixture for Level 16 behavior.

No actionable public survivor remains in the audited matrix. Empty, failed,
partial, taken, concrete, erased, feature, allocation, callback-error,
iteration-direction, ownership, and full-width value boundaries all have a
reference-passing and pristine-failing oracle. Verdict: **pass** for the exact
Level 17 version. Fresh calibration is **0/10**; expected fresh success is
**1-3/10, centered on 2/10**.
