# DESIGN - Tablesaw Arrow stream interoperability

Status: `accepted by the platform and archived 2026-08-20; immutable final
package; exact environment, gap, fairness, and false-positive verdicts pass;
observed compatibility 0/5; fresh solver calibration remained 0/10 at
closeout`.

Repository: jtablesaw/tablesaw at
e36c3ff3c9e21026f4a04590a5319edfc27f5c84 (2026-03-01).

Production language: Java. Task type: enhancement/bug fix.

## Public contract and repository evidence

Make the existing ArrowReader and ArrowWriter interoperable with ordinary Arrow
stream producers and consumers for the logical types Tablesaw already claims
to support:

- read every record batch, including zero-row batches between populated
  batches, and append rows in stream order;
- write Arrow validity bits from Tablesaw missingness and read validity bits
  back into the matching Tablesaw missing sentinel for every supported type;
- reject a valid floating NaN explicitly as an unrepresentable Arrow state,
  while mapping a null floating slot to Tablesaw missingness;
- decode direct and dictionary-encoded text as UTF-8 and accept legal Arrow
  time/date/timestamp unit variants that Tablesaw can represent exactly,
  including seconds and milliseconds and microsecond/nanosecond values aligned
  to Tablesaw's millisecond precision;
- map timezone-bearing timestamps to Instant and timezone-free timestamps to
  local date-time behavior, with explicit errors for unsupported or lossy
  nested/logical types;
- ensure a failed conversion does not poison subsequent reads or prevent
  replacing the reader's source; and
- round-trip streams in both directions against the standard Arrow Java reader
  and writer, not only Tablesaw's paired implementation.

The current ArrowReader.read loop assigns loadNextBatch to an end-of-stream
variable and exits after the first successful batch. The reader and writer have
separate type switches; the writer emits Tablesaw missing sentinels as ordinary
vector values despite nullable fields, and the reader covers only selected minor
types/units. All Arrow code entered in baseline commit 17b5d76, with later
history dominated by dependency updates rather than these semantics.

The cheapest credible architecture was forecast as a corrected batch loop plus
paired, unit-aware read/write helpers that handle vector validity explicitly:
160-280 effective production lines across reader, writer, and type helpers.
That initial low-confidence estimate is retained here; the complete prototypes
measured 393 and 434 mechanically strict production additions.

The NaN clause changed during repository-grounded escalation. Tablesaw's
`FloatColumnType.valueIsMissing` and `DoubleColumnType.valueIsMissing` define
every NaN as the missing sentinel, and the corresponding columns expose that
same rule through `isMissing`. A valid Arrow NaN and an Arrow null therefore
cannot coexist as distinct Tablesaw states without redesigning the core column
model. Explicit rejection is the only non-lossy interoperable behavior within
the existing supported model; silently converting a valid NaN to missing would
erase Arrow validity. Likewise, `InstantColumn`, `DateTimeColumn`, and
`TimeColumn` store millisecond precision, so finer Arrow units are accepted
only when exact.

## Production-scope prototype trial

The exact pinned source was materialized into two detached disposable
worktrees after Phase A. Both implementations cover the same contract but use
independent production structures:

| Prototype | Architecture | Production delta | Focused result | Complete result |
|---|---|---:|---:|---:|
| A | Direct reader/writer type dispatch with unit-aware conversion helpers and explicit validity handling in each direction. | 459 raw additions / 385 deletions; **393 mechanically strict additions** across the two existing production files. | 6/6 | 1,109 tests, 0 failures, 0 errors, 5 existing skips |
| B | A bidirectional adapter registry owns column creation, schema types, batch appenders, and vector writers; reader and writer are thin lifecycle orchestrators. | 524 raw additions / 439 deletions; **434 mechanically strict additions** across one new and two existing production files. | 6/6 | 1,109 tests, 0 failures, 0 errors, 5 existing skips |

Strict additions exclude blank, comment-only, and brace-only added lines. The
complete count includes the six disposable focused probes; the pristine
reactor had 1,103 executed tests at this pin. Neither disposable worktree nor
its test class is a submission artifact.

The disposable focused lane used streams written directly with Arrow Java, not
Tablesaw's paired writer. It covered populated/empty/populated multi-batch
ordering; nullable UTF-8, signed integer, boolean, float/double, date, time,
local timestamp, and timezone-bearing timestamp vectors; all four
Arrow time and timestamp units at exactly representable values; standard Arrow
consumption of every Tablesaw-supported writer family; valid-NaN and lossy-time
rejection; and repeatable unsupported nested-type failure with field/type
context. Every Tablesaw writer field was externally observed as nullable, with
its missing row represented by Arrow validity rather than a payload sentinel.

Both architectures use resource ownership that closes the allocator, stream,
reader/writer, and schema root on normal and exceptional paths. Repeat reads of
the same valid and rejected sources succeeded or rejected consistently,
demonstrating that failure did not make the source unusable.

## Trajectory-informed design gate

The 447-repository held index and all local problem/candidate/archive records
were searched for Tablesaw, Arrow, multi-batch streams, validity, and logical
time conversion. The closest local seed was an earlier rejected arrow-rs stream
concatenation idea; it concerned compositional concatenation, not Tablesaw's
existing reader/writer validity and logical-type contract. No exact local task
or Tablesaw trajectory exists.

Compact records read were Salsa persisted accumulators, h5py VDS relocation,
PcapPlusPlus filtered copy, ezdxf XREF collections, Calamine defined names, and
Railway deployment bundles. Raw h5py pass Nova_Nova_8, h5py near-pass
Nova_Nova_6, and PcapPlusPlus broad-fail Nova_Nova_10 trajectories and
production diffs were inspected.

The h5py pass added 166 production lines and covered every focused family; it
warns that one compact native change can cover many fixtures. The 22/24 h5py
near-pass missed same-file identity and variable-length Unicode attributes,
making identity/resource lifecycle an independent boundary. The 533-line
PcapPlusPlus broad failure passed 9/14 focused checks but missed section and
option-bearing producer families, showing why independently produced legal
streams must be tested rather than adding only self-round-trip fixtures.
Tablesaw and Arrow's public APIs, not those analogs, remain the fairness
authority.

The 2026-08-18 environment/fairness remediation reopened this startup gate.
The same local problem, candidate, archive, and raw-run searches found no new
Tablesaw solver trajectory or closer prior problem. The new review evidence was
instead a concrete fairness defect in the frozen oracle: it required a two-row
writer result to occupy one record batch even though the public prompt leaves
writer batching unspecified. That evidence added batching-policy independence
to the discriminator ledger and caused the writer oracle to aggregate ordered
rows and validity across every loaded batch.

The subsequent first platform calibration batch supplied exact repository
evidence that the task was too easy: all ten Nova/Nova runs were legitimate
passes. Every solver changed both `ArrowReader` and `ArrowWriter`; eight also
added an independent Arrow regression test. The common architecture was direct
schema/minor-type dispatch in the reader plus a separate writer switch, with
method-local allocators/streams recreated on each `read()`. All ten validated
focused or module tests and the successful production patches had 368–526
mechanically strict added production lines (median **449**) across the two
participant-owned production files. The platform agent-message metric was not
present in the downloaded records and is not inferred from the four-step
trajectory envelope.

Raw trajectories and production diffs for Nova_Nova_2, Nova_Nova_5, and
Nova_Nova_10 were inspected as representative passes; all ten production diffs
were searched for boundary validation. No near-pass or broad-failure trajectory
exists in this all-pass batch, so those categories are recorded as unavailable.
The diffs exposed a useful split in proactive repository analysis: only five of
ten reject a valid empty UTF-8 value that aliases the string missing sentinel,
only four reject valid signed integer values equal to Tablesaw's numeric missing
sentinels, and roughly seven guard the packed signed-16-bit year boundary.
Lyra's independent completeness audit additionally demonstrated survivors for
negative temporal remainders, floating infinities, out-of-day time values,
neighboring unsupported integer kinds, and same-instance recovery. These are
repository/public-contract boundaries, not copied hidden fixtures.

The subsequent 7/19 fairness review was treated as new design evidence before
revising the verifier. The prior problem-history search and all ten available
Tablesaw solver diffs were revisited; there is no near-pass or broad-failure
trajectory to add, and neither the original Arrow module nor the legitimate
solutions establish a canonical diagnostic vocabulary. The review correctly
demonstrated that even case-insensitive any-of marker lists reject compliant
messages such as “collides with the sentinel” or “must be nonnegative.” Because
the invalid fixture itself fixes the rejected state, the fair observable is the
required exception class plus field identity. All author-selected state-word
markers are therefore removed rather than expanded.

The 2026-08-18 second hardening gate searched the same compact problem,
candidate, and archive records for Tablesaw, Arrow validity, zero-row streams,
and temporal conversion; no closer historical task was found. It then read all
five new `agent-runs2` verdicts and production diffs and inspected raw
trajectories for runs 1, 3, and 5. All five are legitimate passes, so this batch
again supplies no near-pass or broad-failure trajectory. The solutions use
independent direct-dispatch implementations, change the same two production
files, and add 390--416 mechanically strict production lines (median 396).
Their trajectories show repository inspection, Arrow API checking, focused
tests, and module verification rather than hidden-fixture adaptation.

Lyra's exact-version audit demonstrated seven distinct survivors: lazy column
initialization on a sole zero-row batch, boolean truthiness in place of
validity, rejection of every negative temporal value, omitted nanosecond-time
exactness, diagonal-only timestamp exactness, writer-side non-finite collapse,
and width-specific unsigned rejection. A separate oracle finding showed that a
timezone-bearing SECOND timestamp beyond Java's `Instant` range can leak a
`DateTimeException` without field context. These are added as black-box
discriminators because each follows an already-public family, crosses an
independently implemented branch, passes the reference after contextual
wrapping, and fails its isolated plausible mutant. Static replay review also
found that the five agent-runs2 solutions already implement the seven families
generically and generally catch SECOND overflow. The pre-change compatibility
forecast is therefore 5/5 survivors (roughly an 8--10/10 fresh solve signal):
this revision is verifier hardening, not yet credible difficulty hardening.

The 2026-08-18 third hardening gate repeated the repository, candidate,
success, problem-history, and archived-evidence searches for Tablesaw, Arrow
streams, validity, temporal conversion, and retry behavior. No closer prior
task or alternate Tablesaw trajectory was found. All ten `agent-runs3`
verdicts, solution diffs, test logs, and compact raw trajectory records were
read. Nine are legitimate passes; run 4 is the sole near-pass at 13/14 because
it evaluates a null `TimeSecVector` payload before checking validity. There is
no broad-failure trajectory in this batch. Representative raw records for
runs 1, 4, and 10 contain only the system/user envelope and final agent summary
rather than tool-level events; their diffs and evaluator logs therefore supply
the implementation and validation evidence.

Every run3 patch changes `ArrowReader`, `ArrowWriter`, and one independent
Arrow test. The two production files contain 477--587 added lines (median
523.5) and use direct minor-type dispatch, per-call table creation, explicit
missing checks in the writer, unit-specific divisors, and inclusive short-year
guards. Lyra proposed nine survivor families: writer false/null confusion,
retry contamination after partial progress, wrong DateMilli and nanosecond
divisors, exclusive year endpoints, an exclusive final local-time millisecond,
timezone-free construction overflow, Float2 widening, and loss of a
schema-only stream. Static replay predicted 8--9/10 run3 compatibility
(roughly an 8--10/10 fresh signal), because the nine successful solvers
implement these branches generically. This was a compatibility forecast and
supported verifier hardening only, not calibrated difficulty.

The schema-only discriminator originally received special harness treatment.
Pristine Tablesaw loops forever after reading a schema with no record batch, so
the admitted probe used a 30-second preemptive watchdog to make the pristine
failure deterministic. The remaining six admitted families were writer
false/null, partial-progress recovery, the two incorrect-divisor families,
timezone-free construction overflow, and Float2 widening. The inclusive year
endpoints and final in-day millisecond were rejected as hidden additions:
both standalone assertions already pass the pristine implementation, so
folding them into another failing method would not satisfy the required
fail-to-pass condition.

The 2026-08-18 strict assertion-level fairness review reopened the startup gate
before any further artifact edit. The local problem, candidate, success, and
archive searches still found no closer prior task. Representative run3 records
for runs 1, 4, and 10 were reinspected alongside the exact 6/10 replay. The
review correctly identified the schema-only probe's 30-second deadline as an
unstated performance predicate: repository tests establish no such timeout,
and the public contract establishes no completion bound. Removing only the
watchdog would make pristine verification nonterminating, while substituting a
thread, process, or larger watchdog would preserve the same arbitrary timing
requirement. The schema-only public clause and discriminator are therefore
retired rather than weakened or assigned another deadline. The related
process-oriented instruction to verify interoperability in a particular way is
also removed; independently observable interoperability behavior remains
covered. Static replay evidence predicts that runs 6, 7, and 10 recover, while
run 4 retains its independent null-`TimeSecVector` defect: **9/10 compatible
run3 solvers** and roughly **9--10/10 fresh signal**. This is a compatibility
replay forecast, not credible difficulty hardening, and exact-version
calibration remains 0/10 until the revised version clears every gate.

The repeated schema-only T4 report reopened the gate again before a fifth
hardening attempt. The local index, candidate, success, problem, and archive
searches still found no closer Tablesaw task. Run3's representative pass (run
1), sole near-pass (run 4), and another legitimate pass (run 10) were
reinspected through their evaluator records, production diffs, and raw
trajectories; no broad failure exists. The newer `agent-runs4` batch was also
read in full: all five exact-version verdicts are legitimate 19/19 passes, all
five production diffs implement direct physical-vector dispatch, and none
imports `DictionaryEncoder` or calls the stream reader's dictionary lookup.
Representative raw trajectories for runs 1, 3, and 5 contain 80, 75, and 61
tool calls respectively; they show substantial repository/API inspection,
focused regression construction, and module/full-reactor verification. Their
reader/writer changes add 463--549 strict production lines, yet the only
dictionary references retained are the original writer's null-provider call.
This supplies a second all-pass trajectory batch, not a near-pass or broad
failure. The schema-only omission is genuine, but it remains inadmissible:
pristine spins forever after schema EOF, so any test capable of finishing the
required pristine lane necessarily introduces a clock, CPU, scheduling, or
implementation-inspection bound. The same requirement is therefore not
restored.

The trajectory review instead exposed architecture convergence at a public
Arrow seam. Every run3 and run4 solution dispatches the root's direct scalar
vectors, and every writer passes a null dictionary provider. The original
repository's own `ArrowWriter` documentation nevertheless describes dictionary
providers as part of streaming record-batch production. Dictionary-encoded
UTF-8 is a standard representation of the already-supported string family, but
decoding it requires consulting the stream reader's dictionary provider rather
than treating its integer index vector as an ordinary Tablesaw integer. A
disposable independent Arrow producer demonstrated reference feasibility and
pristine failure; the predecessor reference passes all prior 19 methods but
fails only this new discriminator. All ten run3 implementations likewise
misclassify the logical string as an integer column, and static inspection
predicts the same result for all five run4 implementations. The pre-artifact
forecast is therefore **0/15 compatible historical solvers**, with a
**2--5/10 fresh-calibration expectation**: unlike prior boundary additions,
this requires a distinct encoded-producer lifecycle while remaining standard
Arrow behavior. This is a compatibility replay estimate plus a fresh-batch
expectation, not a calibration result. Large UTF-8, malformed UTF-8 bytes,
arbitrary dictionary value families, and dictionary output remain outside this
bounded candidate; they are not implied by this probe.

The 2026-08-19 run5 hardening request reopened the startup gate before any
submission-artifact change. Searches across the local problem, candidate,
success, archive, and compact-history records again found no closer Tablesaw
problem or alternate Arrow interoperability task. All five `agent-runs5`
verdicts, solution patches, evaluator logs, and compact trajectories were read.
Every run is a legitimate pass of the three baseline and twenty hidden methods;
there is no near-pass or broad-failure trajectory in this batch. Representative
raw traces for runs 1, 3, and 5 contain 85, 94, and 94 tool calls. They show
direct inspection of Arrow vector/dictionary APIs, Tablesaw sentinel and packed
temporal helpers, independent producer probes, focused tests, and module or
reactor verification. The five solutions add 522--612 raw production lines
across `ArrowReader` and `ArrowWriter` (before deletions), use independent
direct-dispatch implementations, and all explicitly decode dictionary strings.

The reported `TIME_MICROSECOND` out-of-day exception gap is public and sits in
an independently selected Arrow time-unit branch: local times outside one day
must be rejected through the field-identifying `IllegalArgumentException`
contract. It was therefore retained as a candidate discriminator for the
exact environment, reference, pristine, and targeted-mutant gates. Static run5
inspection showed that all five successful implementations first divide
microseconds exactly to milliseconds and then check the one-day domain; the
single candidate is consequently forecast to retain all five run5 solutions.
It can close a completeness hole, but by itself cannot constitute successful
difficulty hardening. Broader survivor analysis must find a distinct public
boundary that is evidenced by run5 implementations, or the correct outcome is
to retire/resign this design rather than accumulate symmetric fixtures.

The subsequent exact run5 survivor audit found two distinct encoded-producer
boundaries rather than another direct-string fixture. Arrow Java's standard
dictionary encoder/decoder accepts every `BaseIntVector` index representation,
including unsigned integer widths, and decodes a valid index pointing to a
null dictionary value as a null logical string. The public logical type remains
UTF-8 in both cases: an unsigned dictionary index is not an unsigned integer
logical column, and null may originate in either the index vector or the
dictionary value vector.

Disposable standard-Arrow producers proved both representations. Before the
artifact edit, the frozen reference passed both while pristine failed
behaviorally. Provisional exact replay left only solvers 1 and 3 compatible:
solvers 2 and 5 rejected unsigned dictionary indices, and solver 4 rejected a
valid index whose dictionary value was null. Each failing implementation still
passed all prior twenty methods. The start-of-iteration compatibility forecast
was therefore **2/5 run5 solvers**. Because the revised prompt makes both
dictionary dimensions explicit, the start-of-iteration fresh-calibration
expectation was **3--5/10 successful solvers**, inside the required 1--5/10
band. This was a compatibility replay estimate plus a fresh-batch forecast, not
a fresh calibration result.

The retained microsecond-time candidate was also isolated. An exactly
millisecond-aligned `TimeMicroVector` value large enough to overflow the
reference's nanos conversion leaked `ArithmeticException`; contextual wrapping
made the reference pass while pristine still fails behaviorally. Static run5
inspection predicted all five solutions retain this behavior because
they divide to milliseconds before applying the one-day domain check. It is
admitted only as completeness coverage and does not contribute to the
difficulty forecast.

The 2026-08-19 external fairness and coverage report reopened the startup gate
before another artifact edit. Searches of `problems/README.md`, both candidate
indexes, the active problem, archives, and compact records found no newer
Tablesaw task or solver batch. The five run5 evaluator records, solution
patches, workspace diffs, and available trajectory bundles were reinspected.
Run5 solver 1 remains the representative legitimate pass; solvers 2 and 4 are
the representative current near-passes, and no broad-failure trajectory exists.
The archived trajectory JSON is a compact four-message record rather than a
separate raw tool-event stream, so production diffs and evaluator artifacts are
the detailed evidence.

The new review identifies one unfair predicate and three public coverage gaps.
The writer oracle currently casts output to the reference's exact day/millisecond
temporal vectors and requires the literal timezone label `UTC`. The prompt
requires independently readable dates, local times, local date-times, and
instants at millisecond precision, but permits every supported exact Arrow unit
and any timezone-bearing instant representation. The oracle must therefore
compare Arrow Java's decoded temporal objects and instant identity, not private
unit or timezone-label choices.

The dictionary requirements also have independently implemented boundaries.
Arrow exposes signed and unsigned 8/16/32/64-bit index vectors, while the
current verifier samples only signed 32-bit and unsigned 8-bit indices. Run5
solvers 1 and 3 use generic standard decoding; solvers 2 and 5 explicitly reject
unsigned indices. A valid empty UTF-8 dictionary value is the encoded-producer
form of the already-public sentinel collision and must reject just like a direct
empty string. All five run5 solutions already perform that check, so it is
coverage rather than a difficulty lever.

Finally, the exact reference pre-creates only non-dictionary columns. When a
populated direct field precedes a dictionary field, adding the deferred empty
string column invokes `Table.addColumns`' documented convenience fill and then
appends decoded rows, corrupting alignment. Solvers 1, 3, 4, and 5 add complete
batch-sized columns; solver 2 pre-creates every logical schema column, so all
five avoid this ordering bug. The public mixed-schema producer boundary is
distinct from single-field dictionary decoding and requires a black-box row,
column, value, and missingness oracle, not a private table-construction order.

Before artifact changes, static compatibility replay predicts **2/5** run5
solvers, unchanged from the current observed replay. The writer relaxation does
not rescue any of the five, the expanded index family preserves the existing
solver 2/5 failures, and the empty-value and mixed-schema checks are predicted
to pass all five. The fresh-calibration expectation remains **3--5/10**, inside
the accepted 1--5/10 band. This is a compatibility estimate plus a fresh-batch
forecast, not fresh calibration.

The first post-freeze environment-gate attempt falsified one static assumption
and was quarantined. Run5 solver 1's dictionary decoder accepts `Number`
indices, but Arrow's unsigned-16 `getObject()` is a `Character`; the patch fails
that public width even though it passed unsigned 8-bit. This is an eligible
behavioral discriminator, not an environment or injection failure, but the
patch was incorrectly supplied as known-good and therefore invalidated that
gate invocation. Static follow-up leaves run5 solver 3 as the only predicted
pass; solvers 1, 2, and 5 miss at least one index representation, while solver
4 also misses dictionary-value nullability. The corrected compatibility
forecast is **1/5** and the fresh expectation is **2--4/10**, still inside the
accepted 1--5/10 band. The exact environment gate restarts from Phase A with
only solver 3 and the alternate temporal writer as must-pass architectures.

### 2026-08-19 run6 redesign gate

The local problem, candidate, archive, and history indexes were searched again
for Tablesaw, Arrow IPC, dictionary encoding, registry integration, I/O options,
stream ownership, and record-batch sizing. The current Tablesaw problem remains
the only relevant local problem record. No independent Tablesaw trajectory or
closer prior problem was found, so the current repository's sibling I/O formats
and the new run6 trajectories are the controlling evidence.

`agent-runs6` contains five runs, not ten. All five are legitimate passes: base
3/3 and feature 23/23, with no compilation, injection, startup, or environment
failure. The production diffs add 495, 605, 480, 508, and 530 mechanically
strict lines (median **508**) and all modify only the existing `ArrowReader` and
`ArrowWriter` production files. Runs 1, 3, and 5 were inspected as representative
raw trajectories; all show broad repository/API inspection followed by direct
reader/writer dispatch and focused/full-module verification. The remaining
diffs were searched for the same architectural boundaries. Run6 again supplies
no near-pass or broad-failure trajectory, so those categories are unavailable.
The records expose 74, 84, 70, 87, and 87 tool-call events respectively; they do
not contain the platform agent-message metric, and tool calls are not reported
as agent messages.

The proposed direct-UTF-8 plus dictionary-UTF-8 test is a real coverage repair,
but not a hardening discriminator. Runs 1, 4, and 5 already add their own tests
with ordinary and dictionary strings in one schema, including multiple batches
and nulls; runs 2 and 3 pre-create every schema field before appending rows and
are structurally compatible. The expected replay for that test alone is **5/5**.
It will be retained only as grouped schema/producer coverage.

The shared omission is Tablesaw's standard I/O architecture. Sibling formats
implement `DataReader`/`DataWriter`, expose `ReadOptions`/`WriteOptions`, register
extensions and option classes in `ReaderRegistry`/`WriterRegistry`, accept the
repository's binary `Source`/`Destination` paths, and follow the caller-owned
stream convention. None of the five run6 patches implements or mentions these
interfaces, registries, options, extension dispatch, configurable batch size,
or stream ownership. The current Arrow API also writes the complete table as a
single record batch, so batch-boundary behavior is never driven by a public
writer option.

The redesign therefore moves the problem's center of gravity from another
scalar acceptance matrix to standard Tablesaw I/O integration. It will add
`ArrowReadOptions` and `ArrowWriteOptions`, register `arrow` and `arrows`, accept
binary files and streams through the normal Table API, expose a positive writer
batch size, preserve values/nulls across the emitted batch boundaries, keep a
caller-owned output stream open, and retain the legacy Arrow entry points. The
public description will state that compact maintainer request directly rather
than narrating the hidden fixture matrix.

Before submission-artifact mutation, the compatibility forecast is **0/5**:
every run6 solution lacks the new public I/O surface and dataflow. The
exact-version fresh-calibration expectation is **2--4/10**, based on five
demonstrated complete Arrow converters but no solver that combined conversion
with options/registry/resource/batching integration. This is a fresh-calibration
forecast, not an observed result, and it lies inside the current accepted
**1--5/10** band. The direct/dictionary-only alternative forecasts 5/5
compatibility and is rejected as ineffective difficulty hardening.

## Discriminator ledger

| Evidence-derived shortcut | Fair public invariant | Black-box oracle | Independent family | Anti-overfit rationale |
|---|---|---|---|---|
| Fix only the inverted batch loop. | All batches and empty batches contribute exactly their rows in order. | Build a stream with empty/non-empty/empty/non-empty batches using Arrow Java, then read once. | stream lifecycle | Does not prescribe buffering, batching, or loop structure. |
| Self-round-trip missing sentinels as values. | Arrow validity and Tablesaw missingness agree in both directions. | Mix missing and sentinel-looking legitimate values, then inspect with an external Arrow reader and Tablesaw. | null representation | Uses each library's public missing/null model rather than private bytes. |
| Treat every NaN payload as missing. | Null NaN payloads become Tablesaw missing; valid NaNs fail explicitly because the existing core model cannot represent both states. | External Float vectors with a valid NaN and a distinct null slot. | payload versus validity | Prevents silent state loss without requiring a private core-storage redesign. |
| Support only the units emitted by Tablesaw. | Legal exactly representable Arrow time units read consistently; finer-than-millisecond values fail as lossy. | External vectors in second/milli/micro/nano forms at exact and one-sub-millisecond boundaries. | producer/type modes | Exercises distinct Arrow minor/unit branches, not permutations of one fixture. |
| Depend on paired writer assumptions. | Standard external producer and consumer interoperate independently. | Cross the two Tablesaw directions with standard Arrow implementations. | producer ownership | Allows any internal mapping architecture. |
| Emit correct writer rows in more than one batch. | Writer batch-size policy is explicitly unspecified. | Iterate every externally readable batch and aggregate exactly the expected rows, values, and validity in order. | consumer/batching mode | Accepts one batch, one row per batch, and intervening zero-row batches without weakening semantic checks. |
| Leave reader state poisoned after conversion failure. | A failed conversion does not prevent repeated failure, source replacement, or later valid reads. | Reject the same unsupported source twice, replace it, and read the valid stream twice. | failure lifecycle | Tests public lifecycle behavior, not close order or allocator accounting. |
| Append every valid payload directly, even when it aliases a Tablesaw missing sentinel. | Valid empty UTF-8 and signed minimum integer payloads must not silently become Arrow null/missing state. | Independently emit valid empty text and signed 64/32/16-bit minima; require contextual rejection because the current column model cannot preserve their validity distinction. | payload versus validity | Generalizes the public NaN rule to repository-documented missing sentinels and accepts any implementation that preserves or explicitly rejects rather than silently collapsing state. |
| Let packed temporal storage wrap years outside a signed short. | Dates, local timestamps, and instants outside Tablesaw's documented packed-year range are unrepresentable and must fail contextually. | Emit exact Arrow temporal values immediately beyond each side of the packed range in the independent producer direction. | storage-range boundary | Observes public values/errors only and does not prescribe packing or helper layout. |
| Validate exactness only for positive remainders. | Divisibility-based temporal loss checks apply equally to negative epoch values. | Mirror representative date/time/timestamp remainders below zero. | signed conversion boundary | Targets a demonstrated sign-asymmetric mutant, not arbitrary value permutations. |
| Reject every non-finite floating payload with NaN. | Infinity is a valid supported floating value; only NaN aliases Tablesaw missingness. | Read positive and negative infinity across more than one batch. | floating payload class | Distinguishes a plausible `isFinite` shortcut while retaining the existing multi-batch public oracle. |
| Allow Java conversion exceptions or width-based scalar acceptance at neighboring types. | Out-of-day times and unsupported unsigned/8-bit integers fail as contextual `IllegalArgumentException`s. | Use Arrow's public vectors at the time-domain boundary and adjacent integer minor types. | domain/type fallthrough | Exercises distinct conversion and dispatch branches without requiring exact exception prose. |
| Retry only by constructing a new `ArrowReader`. | A failed conversion must not poison later calls on the same public reader object. | Reject twice through one instance, replace its file contents, then read twice through that same instance. | object lifecycle | Directly checks the public reusable object rather than allocator internals or close order. |
| Emit a semantically sufficient diagnostic using vocabulary outside an author-selected word list. | Rejections use `IllegalArgumentException` and identify the field; exact prose is explicitly unspecified. | Trigger each concrete unsupported/unrepresentable state and assert only exception type plus field name. | diagnostic contract | The fixture identifies the state being exercised, while the oracle accepts every wording and avoids a hidden lexicon. |
| Initialize typed columns only after seeing a populated batch. | A consumed zero-row record batch retains its schema as typed zero-row Tablesaw columns. | Independently write a sole zero-row batch and inspect column name/type and row count. | empty-batch lifecycle | Tests an actual record batch and public schema, not a timeout or an implementation loop. |
| Infer missingness from a false/zero payload. | Arrow validity alone determines boolean missingness. | Read a valid false slot and assert false plus nonmissing. | validity/payload split | Uses the supported boolean family's two ordinary values and does not inspect storage bits. |
| Reject all negative temporal values to catch negative remainders. | Exact negative dates and timestamps are accepted in every supported unit while only nonzero sub-millisecond remainders fail. | Read an exact negative date and local/zoned timestamps in second, milli, micro, and nano units. | signed acceptance boundary | Complements rejection with the public accept side and avoids a sign-only shortcut. |
| Share one sampled fine-unit check across distinct vector branches. | TimeNano, local TimestampNano, and zoned TimestampMicro independently enforce exact millisecond representability. | Supply a one-unit remainder through each branch and require contextual rejection. | temporal branch cross-product | Covers independently dispatched vector/unit/timezone paths rather than more fixtures for one branch. |
| Treat all non-finite writer values as missing. | Tablesaw floating infinities remain valid Arrow values in the writer direction. | Write both signs and precisions, aggregate arbitrary Arrow batches, and inspect validity/value. | writer payload class | Mirrors the explicit two-direction contract without constraining output batching. |
| Reject only the sampled unsigned 32-bit vector. | Every Arrow unsigned integer width is unsupported and rejected with field identity. | Produce UInt8/16/32/64 fields independently. | integer dispatch width | Exercises Arrow's distinct vector classes under one public signed-only surface. |
| Let Java temporal constructors leak their native exception. | An unrepresentable timezone-bearing SECOND timestamp fails as `IllegalArgumentException` naming its field. | Feed epoch seconds beyond `Instant` construction range. | conversion error boundary | Requires the public error contract, not wording or a private conversion order. |
| Derive writer validity from boolean truthiness. | A valid false is a valid Arrow slot while only Tablesaw missingness clears validity. | Write false and missing, then inspect both through standard Arrow Java. | writer validity/payload split | Tests the opposite direction of a demonstrated reader shortcut without prescribing writer layout. |
| Reuse a partially populated result after failure. | Every `read()` starts a clean conversion, including retry after a later batch fails. | Append a valid batch, fail on a later valid NaN, replace the file, and reuse the same reader. | partial-progress failure lifecycle | Observes only returned data after replacement, not allocator or cleanup internals. |
| Use a nearby but incorrect temporal divisor. | DateMilli requires whole epoch days and nanoseconds require whole milliseconds. | Reject 1000 DateMilli units and 1000-nanosecond time/local/instant values. | divisor identity | Distinguishes two demonstrated arithmetic shortcuts rather than repeating a one-unit fixture. |
| Normalize construction failure only for zoned timestamps. | Timezone-free and timezone-bearing timestamp branches both use the field-identifying error contract. | Feed `Long.MAX_VALUE` seconds to the timezone-free branch. | local/zoned conversion split | Crosses separately implemented conversion paths while leaving message prose free. |
| Dispatch every Arrow floating kind through a widening helper. | Only supported Float4 and Float8 vectors are accepted; Float2 is unsupported. | Produce a valid Float2 field and require field-identifying rejection. | neighboring floating type | Mirrors the signed-integer fallthrough discriminator at an independent Arrow type family. |
| Ignore dictionary metadata and dispatch only the root's physical index vector. | Dictionary-encoded UTF-8 input is decoded to the supported Tablesaw string family with index validity preserved. | Produce a standard Arrow stream with a UTF-8 dictionary and nullable integer indices, then read it through Tablesaw. | encoded producer mode | Uses Arrow's public dictionary provider and string semantics; it accepts eager decoding, per-batch lookup, or another equivalent architecture and does not require Tablesaw to emit dictionaries. |
| Treat the physical index vector as a logical unsigned integer field or allow only signed dictionary indices. | Standard Arrow integer index representations identify dictionary entries without changing the UTF-8 logical type. | Produce dictionary-encoded UTF-8 with an unsigned index vector containing ordinary and null indices. | encoded index representation | Exercises Arrow's public dictionary index type independently of unsupported unsigned logical columns and accepts standard decoding or equivalent custom lookup. |
| Derive logical string nullability only from the dictionary index vector. | A valid index whose dictionary value is null is a null logical string and becomes Tablesaw missingness. | Produce a nullable UTF-8 dictionary containing a null entry and reference it from a valid index. | dictionary value validity | Distinguishes index validity from value validity without prescribing decoder placement or requiring malformed IPC. |
| Normalize one-day failures only in sampled SECOND/MILLISECOND time branches. | Every supported Arrow time unit rejects an out-of-day value through `IllegalArgumentException` with field identity. | Produce an exactly millisecond-aligned out-of-day `TimeMicroVector` value and inspect only exception type and field context. | time-unit error branch | Crosses a separate 64-bit vector/unit conversion path and leaves conversion order and diagnostic prose unconstrained; admission remains conditional on targeted-mutant and pristine evidence. |
| Emit interoperable temporal values using an exact Arrow unit or timezone label different from the reference. | Writer output preserves the logical date/time/local-date-time/instant value and nullability; unit and timezone label are not prescribed. | Decode with standard Arrow Java and compare temporal objects and instant identity rather than concrete vector classes or `UTC`. | writer encoding freedom | Removes a reference-layout predicate while retaining cross-tool behavioral observability. |
| Support only the two sampled dictionary index vectors. | Every standard signed and unsigned Arrow integer index type addresses the same logical UTF-8 dictionary. | Produce the same ordinary/null logical strings through all eight standard integer vector classes. | encoded index width/sign | Crosses distinct Arrow vector dispatch branches and groups them under one explicitly public family rather than treating each width as a difficulty lever. |
| Reject a direct empty UTF-8 value but append an empty decoded dictionary value as Tablesaw missingness. | A valid empty logical string is unrepresentable regardless of direct or dictionary producer mode. | Select a valid empty dictionary entry and require the public contextual rejection. | encoded sentinel collision | Reuses the established sentinel rule across a distinct producer path without adding a new calibration discriminator. |
| Initialize dictionary columns only after preceding direct rows have populated the table. | Mixed direct/dictionary schemas retain one aligned logical column per field and exactly one value per row. | Put a populated ordinary integer before dictionary UTF-8, then inspect row count, order, values, and missingness. | mixed-schema assembly | Exposes a demonstrated `Table.addColumns` alignment bug while allowing pre-creation, batch tables, or another correct architecture. |
| Assume a direct string and dictionary string cannot share a schema. | Direct and dictionary-encoded UTF-8 fields coexist in either schema order without row drift. | Read ordinary and dictionary UTF-8 together across nulls and multiple batches, then compare logical rows. | mixed producer/schema mode | Closes a public coverage cell, but is grouped as completeness because run6 solutions already exercise or structurally support it. |
| Keep Arrow as a standalone file-only utility. | Arrow participates in Tablesaw's standard reader/writer option and extension-dispatch paths for binary files and streams. | Round-trip through existing `Table.read()`/`Table.write()` entry points and both registered extensions. | framework integration | Uses repository-defined public interfaces and accepts any internal adapter organization. |
| Serialize every table as one record batch. | A positive Arrow writer batch-size option bounds non-empty emitted batches without changing row order, values, or validity. | Write rows/nulls straddling several configured boundaries and inspect all batches with standard Arrow Java. | writer batching/dataflow | Tests a public option and cross-boundary semantics, not a private default or exact buffer strategy. |
| Close every stream when the Arrow stream writer closes. | A caller-owned output stream remains open after the standard writer-option path returns. | Use an observable output-stream wrapper, then append a byte after Arrow writing completes. | resource ownership | Follows the existing `WriteOptions(OutputStream)` convention and does not inspect close order or allocator layout. |
| Register only filename extensions or only option types. | Both `arrow`/`arrows` extension dispatch and Arrow option-class dispatch resolve through Tablesaw's registries. | Exercise the existing generic Table APIs rather than constructing ArrowReader/ArrowWriter directly. | registry mode | Crosses independent registry maps and catches partial integration without prescribing static-initializer placement. |

## Clause-to-test coverage

| Public requirement | Planned observable test | Pristine behavior |
|---|---|---|
| all batches | mixed empty and populated standard Arrow batches | truncates after first loaded batch |
| validity in both directions | all supported scalar families with missing and non-missing values; valid NaN rejection | null state is lost, sentinels are serialized as values, or valid NaN is silently collapsed |
| time units/timezones | externally produced timestamp/time vectors at exact and lossy precision boundaries | some legal forms are rejected, truncated, or misinterpreted |
| UTF-8 | non-ASCII text from an external producer | conversion path must prove charset behavior |
| dictionary UTF-8 index and value validity | all eight standard signed/unsigned integer index vectors, null index, null dictionary entry, and valid empty dictionary entry | physical indices are misclassified as integers or a validity/sentinel source is lost |
| mixed direct/dictionary schema order | direct UTF-8 and dictionary UTF-8 in both orders, plus the populated direct integer case, with logical row/value/missingness checks | dictionary dispatch is absent and deferred empty-column insertion corrupts alignment |
| independent interoperability and writer representation freedom | Tablesaw-to-standard and standard-to-Tablesaw; dynamic temporal-unit decoding and alternate timezone-label replay | paired or reference-schema assumptions are unchallenged |
| failure lifecycle | repeated unsupported failure, source replacement, repeated valid read | pristine diagnostics lack field context and lifecycle is not comprehensively specified |
| standard I/O integration | Arrow read/write options plus generic Table file/stream and `arrow`/`arrows` extension dispatch | Arrow does not implement the repository's reader/writer framework |
| configurable writer batching | standard Arrow consumer observes bounded batches and unchanged ordered values/nulls across boundaries | legacy writer has no batch-size option and emits one complete-table batch |
| caller-owned output stream | output stream remains usable after the generic option-based write returns | ownership is not represented by the legacy Arrow API |

## Ownership and environment preflight

All-state issue/PR searches found closed issue #288 discussing Arrow and the
completed import work around #1067, but no current owner for multi-batch,
validity, or time-unit interoperability. Source and relevant history were
inspected at the exact pin.

The exact pin remained the default-branch head during the 2026-08-17/18
escalation refresh. The repository remained active and Apache-2.0 licensed.
Reachable history, fetched branches, and all-state GitHub issue/PR searches
still found no implementation or current owner for this combined behavior.

Initial diagnostic Phase A passed on evaluator-representative `linux/amd64`,
offline as UID/GID 10001 against a read-only exact checkout. The final
submission was then rebuilt from the JVM slim base without build-time tests;
the build installs the full reactor with `skipTests`, which compiles tests and
caches their complete dependency closure without executing them. Explicit
Surefire provider resolution completes the offline runtime cache.
`ENVIRONMENT.md` records both the final identities and every quarantined
environment-only attempt. None was counted as solution evidence.

Phase B passed for the final four-artifact version. Pristine base passed;
pristine feature produced 23/23 expected behavioral failures and no startup,
compiler, timeout, or JUnit error nodes; reference base/feature passed; run5
solver 3 and the alternate temporal writer passed both lanes; and run5 solvers
1, 2, 4, and 5 accepted verifier injection without conflict. Baseline and
reference feature testcase identities matched. The untouched and
reference-plus-verifier complete 11-module reactors passed offline as UID/GID
10001 in 2:31 and 2:52 respectively. Exact serial compatibility replay observes
1/5: solver 3 passes 23/23; solvers 1, 2, and 5 fail only the all-index-width
predicate; solver 4 fails that predicate plus dictionary-value nullability.
The mixed-schema and dictionary-empty mutants each pass all three pre-existing
tests and fail only their intended final method. `ENVIRONMENT.md` records the
exact hashes, fresh image identities, composition order, formatter result,
mutation isolation, and quarantined first gate attempt.

## Direct shortlist comparison

The runner-up SurrealKV manifest seed also cleared a substantial disposable
trial, but Tablesaw remains the selection for this slot. Tablesaw has the
larger measured minimum complete implementation (393/434 strict additions
versus 222/255 reported for SurrealKV), two independently owned interoperability
directions, a standard external producer/consumer oracle, and no same-repository
deleted predecessor implementation. SurrealKV has the more intricate
persistence lifecycle, but its directional VLog policy and legacy-state policy
increase prompt/fairness risk. The original 9/10 versus 8/10 ordering therefore
survives measured escalation.

## Design verdict

**Selected at 9/10; current hardening is exact-gate complete and awaits fresh
calibration.** The original dimensions were health 9, rarity 8, task fit
9, depth 9, harness 9, and prior-art safety 8. Phase A is viable, and two complete independent
architectures exceed the roughly 100-effective-line stop condition by more
than threefold while passing the same external-oracle lane and complete suite.
The core difficulty is not the obvious batch-loop fix: validity, producer unit
families, timezone mapping, lossy-state rejection, writer interoperability, and
failure-path ownership cross independently implemented boundaries.

The public description now states behavior without exposing the private packed
temporal representation or numeric endpoint inventory: millisecond precision
and contextual rejection outside Tablesaw's existing representable range. It
also states writer-side false validity, partial-progress recovery,
timezone-free construction errors, half-precision rejection, and the exact
DateMilli/nanosecond representability rules. It now also requires standard
dictionary-encoded UTF-8 input, makes the standard integer-index and two-source
null semantics explicit, and leaves output encoding unconstrained.
The process-oriented UTF-8/external verification sentence and the schema-only
completion clause are removed. The verifier keeps exception wording, writer
batching, decoder architecture, and execution time free.

Calibration history is not carried across artifact revisions. The first
frozen version produced 10/10 legitimate passes. The first behavioral
hardening retained 5/10 prior solutions, the diagnostic-fairness revision also
retained 5/10, and the run2 completeness revision retained 5/5. The third
hardening revision forecast **8--9/10 compatible run3 solvers** and observed
**6/10** because runs 6, 7, and 10 failed only the later-rejected schema-only
timeout while run 4 also retained its null-TimeSec defect.

Before the fourth revision, exact replay evidence forecast **9/10 compatible
run3 solvers** and roughly **9--10/10 fresh signal**. Exact replay matched that
forecast: solvers 1, 2, 3, 5, 6, 7, 8, 9, and 10 pass, while run 4 alone fails
the independent null-TimeSec validity behavior. A one-row-per-batch writer also
passes. The revision removes an unfair discriminator; it is fairness repair,
not successful difficulty hardening, and the submission is not
difficulty-ready. Fresh calibration for test hash
`22eb97ecc7f9d52923a62c4f5f0dfe34c4525be55b32c203e7962010640feda9`
remains **0/10** and must begin as a new exact-version batch.

Before the dictionary revision, the trajectory-informed forecast was **0/15
compatible historical solvers** and **2--5/10 successful fresh solvers**. The
observed exact replay is **0/15**, exactly matching the compatibility forecast:
fourteen implementations fail only the dictionary method, and run3 solver 4
also retains its earlier null-TimeSec defect. The predecessor reference likewise
passes all prior 19 methods and fails only the new discriminator, while the
updated reference and a one-row-per-batch writer variant pass 20/20. This is
credible difficulty hardening on compatibility evidence, but it is not a fresh
calibration result. Fresh calibration for test hash
`4bc08246c9fbc1dd3dc8acc169f4d48d0e872efd2beb2493692537b91287db7b`
remains **0/10** and must begin as a new exact-version batch.

At the start of the run5 hardening iteration, exact provisional replay
forecast **2/5 compatible run5 solvers**, and the public wording supported a
fresh expectation of **3--5/10 successful solvers**, inside the required
1--5/10 band. The frozen exact-version replay observes **2/5**, exactly matching
the compatibility forecast: solvers 1 and 3 pass all 22 methods; solvers 2 and
5 fail only unsigned dictionary indices; solver 4 fails only dictionary-value
validity. The large aligned TimeMicro addition is independently isolated but
passes all five solver implementations, confirming that it is completeness
coverage rather than a difficulty lever. The end-of-iteration fresh forecast
remains **3--5/10**, inside the accepted band. This observed 2/5 result is a
compatibility replay, not fresh calibration. Fresh calibration for test hash
`c8f4daf3a7c647418a80ee7d6f2cda37b77d1771fd2e2d836448328ffaa99c4a`
remains **0/10** and must begin as a new exact-version batch.

At the start of the external-review iteration, static evidence forecast **2/5
compatible run5 solvers** and **3--5/10 fresh solvers**. The first exact gate
showed that solver 1's generic-looking `Number` path does not accept Arrow
UInt2's `Character`, so that invocation was quarantined and the forecast was
corrected before restarting all gates: **1/5 compatibility** and **2--4/10
fresh solvers**. The corrected fresh forecast is inside the accepted 1--5/10
band.

The final exact replay observes **1/5**, matching the corrected compatibility
forecast: solver 3 passes all 23 methods; solvers 1, 2, and 5 fail only complete
dictionary index-width coverage; solver 4 fails that plus its pre-existing
dictionary-value-null defect. The legitimate alternate temporal writer passes
23/23 with DateMilli, TimeMicro, local TimestampMicro, instant
TimestampNanoTZ, and `Etc/UTC`. Each targeted new mutant fails only its intended
mixed-schema or encoded-empty-string discriminator. The end-of-iteration fresh
forecast remains **2--4/10**, inside the accepted band. This 1/5 observation is
a compatibility replay, not fresh calibration. Fresh calibration for test hash
`eac3d99997b1c89a66618aaf5039f05f2ac41a7b96ad903a927f355ff9bbaf5b`
remains **0/10** and must begin as a new exact-version batch.

## 2026-08-19 run6 redesign — exact end record

The iteration began after `agent-runs6` produced five legitimate passes out of
five and the user reported that the broader task had been solved roughly forty
times. The mandatory startup gate searched all local problem/candidate/archive
records, read the five compact run6 records and production diffs, and inspected
representative raw trajectories for runs 1, 3, and 5. No near-pass or broad
failure exists in this batch. All five use the same broad solution shape:
direct Arrow reader/writer dispatch in the two existing production classes,
with 480--605 strict production additions and median 508. None implements
Tablesaw's standard `DataReader`/`DataWriter` architecture, format option
classes, registry aliases, stream ownership, or configurable bounded batching.

That evidence changed the design rather than adding more scalar fixtures. The
public task now requires `ArrowReadOptions` and `ArrowWriteOptions`, generic
option and extension dispatch for `arrow`/`arrows`, binary stream sources and
destinations, preservation of caller-owned output streams, and a positive
maximum writer batch size. Direct UTF-8 plus dictionary UTF-8 in both schema
orders was also added as completeness coverage in response to review, but was
not counted as a difficulty lever because run6 implementations already pass it.
The public description was rewritten into concise maintainer prose and leaves
default batch size, batch partition, temporal vectors, timezone spelling, and
internal registry/decoder organization free.

Before artifact mutation, the trajectory-informed forecast was **0/5
compatible run6 solvers** and **2--4/10 successful fresh solvers**. The latter
is inside the current accepted 1--5/10 band and is a fresh-calibration
expectation, not a compatibility result.

### Exact immutable version

- pin `e36c3ff3c9e21026f4a04590a5319edfc27f5c84`
- meta `042df955f9eb79320a38e4df616e7946e852fe440a78125b34dceee40610d6f1`
- tests `d232fb99d4ea731e9bb019d222cb7e5e6a03616d83b42d5afb76d56b732f3c4b`
- reference `7f1eb0788491006d18fe4c0ba2a873a7251b2cba73edb724fd19c8310ed9e588`
- Dockerfile `4825c81a115e455df5493271c0a97685abfb2c1e257ace5e7eea92fdb9f823ba`

The first behaviorally passing prototype was invalidated because production
format validation failed. The second was invalidated because verifier format
validation failed. Neither is credited. The final version received a new cold
image build and complete gate restart. Offline/non-root exact composition
observed pristine base 3/3, pristine feature 0/27 with 27 assertion failures
and zero errors, reference base 3/3, and reference feature 27/27. Production and
verifier sources are formatter-clean. Untouched and reference-plus-verifier
complete 11-module reactors pass in 2:21 and 2:23.

All five run6 patches compose and compile in evaluator order. Each passes the
prior 24 methods and fails only the three new integration discriminators:
option-based bounded stream I/O, extension registry dispatch, and nonpositive
batch validation. Observed compatibility is therefore **0/5**, exactly
matching the start forecast.

Seven isolated shortcuts each pass all three pre-existing Arrow tests and fail
exactly one of 27 methods: ignored batch maximum, reset source offset, closed
caller stream, absent option registration, absent `arrows` alias, accepted
nonpositive size, and a homogeneous-text-schema assumption. A one-row-batch
writer and a DateMilli/TimeMicro/TimestampMicro/TimestampNanoTZ writer using
`Etc/UTC` both pass 27/27, demonstrating batching and temporal representation
freedom. The exact gap, fairness, and false-positive audits therefore pass.

The end-of-iteration forecast remains **2--4/10 successful fresh solvers**,
inside the accepted 1--5/10 band. The compatibility replay is observed old
solver evidence only. Any artifact change resets the gates, and fresh
calibration for test hash
`d232fb99d4ea731e9bb019d222cb7e5e6a03616d83b42d5afb76d56b732f3c4b`
remains **0/10** until a new exact-version batch is run.

## 2026-08-19 File-builder coverage and prose-fairness gate

This review iteration restarted the mandatory design gate before changing the
prompt or verifier. Searches of the local problem index, candidate records,
archive, current problem history, and `agent-runs*` folders found no run7 or
new Tablesaw trajectory. Run6 remains the controlling evidence: five
legitimate passes, no near-pass, and no broad failure. The compact records and
production diffs were reread, and the raw trajectories for runs 1, 3, and 5
were reinspected. Those trajectories contain the system/user/final envelope,
while their evaluator records establish ordinary repository inspection,
implementation in the two Arrow production classes, independent regression
tests, and successful Maven validation. None contains the later option-builder
surface, so they do not distinguish File from stream options.

External review identified two exact-version issues. First, the public prose
named `DataReader` and `DataWriter`, even though the observable requirement is
interoperability through Tablesaw's normal `Table.read()` and `Table.write()`
API. Those internal interface names will be removed; the black-box option and
extension behavior remains public. Second, the verifier directly invoked only
the InputStream and OutputStream option builders even though the prompt also
requires File builders. The repository's sibling options classes expose File
and stream construction as separate overloads, making stream-only support a
plausible, independently implemented omission.

| Observed evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|---|
| Current verifier invokes only stream option builders. | Implement `builder(InputStream/OutputStream)` but omit one or both `builder(File)` overloads. | Both Arrow option classes support binary files and streams through Tablesaw's normal option API. | Write through `ArrowWriteOptions.builder(File)` and `Table.write().usingOptions`, consume the result independently; read the same file through `ArrowReadOptions.builder(File)` and `Table.read().usingOptions`, then compare logical values and table name. | Exercises public overload families and real file I/O; it does not inspect interface declarations, constructors, fields, or registry implementation. |
| Public prose names two repository interfaces. | Treat one internal inheritance/implementation arrangement as the task rather than its observable behavior. | Arrow options and extensions work through the normal Tablesaw I/O API. | Existing generic option and extension calls remain the oracle after removing interface names from the prompt. | Preserves alternate implementations that satisfy dispatch behavior without prescribing an internal type declaration. |

The pre-mutation compatibility forecast is **0/5 run6 solvers**: all five lack
the entire option surface, so File coverage does not change their existing
three-method rejection. The fresh-calibration expectation remains **2--4/10**,
inside the accepted 1--5/10 band. This iteration is coverage and fairness
repair, not a new difficulty lever; fresh calibration is reset/remains **0/10**
after any artifact change.

### File-builder correction — exact end record

The public prose now requires only observable operation through the normal
`Table.read()` and `Table.write()` option flow; it no longer names
`DataReader` or `DataWriter`. A separate black-box method directly invokes the
public File overload on each Arrow option class. It writes a nullable two-column
table through the File write options, independently consumes all produced
batches with Arrow Java, then reads that file through the File read options and
compares table name, values, order, and missingness.

The corrected immutable artifacts are:

- meta `9d0a55d07ab6008e661537e55c209ad7986765f3f2db1d20dc58fbe545d9edda`
- tests `86fec7eab6211ca038a617f7e178815b2a42a4866a4a4b6d91d3a041ca8cbc83`
- reference `7f1eb0788491006d18fe4c0ba2a873a7251b2cba73edb724fd19c8310ed9e588`
- Dockerfile `4825c81a115e455df5493271c0a97685abfb2c1e257ace5e7eea92fdb9f823ba`

The final no-cache image was built from an untouched repository context; no
submission patch was present during image creation. Phase A passed offline as
UID/GID 10001. Exact evaluator composition observed pristine base 3/3,
pristine feature 28/28 behavioral failures with zero errors, reference base
3/3, and reference feature 28/28. Formatter validation passed. The one-row
batching and alternate-temporal writers each pass base 3/3 and feature 28/28.
The untouched and reference-plus-verifier complete reactors pass in 2:05 and
2:04.

Nine compiling mutants pass all three pre-existing Arrow tests and none
survives the feature suite. The independently omitted File-read and File-write
behaviors each fail only `fileOptionBuildersWorkThroughNormalTableIo`. Two
earlier attempts that made the File methods private without preserving legacy
callers caused production compile failures; they were quarantined and are not
mutation evidence.

All five run6 patches still compose and compile, pass the same prior 24
behaviors, and fail the four public option/registry/batching methods. Observed
compatibility is **0/5**, matching the start forecast. The end fresh expectation
remains **2--4/10**, inside the accepted 1--5/10 band. This is an observed
compatibility replay, not a fresh batch; calibration remains **0/10** for test
hash `86fec7eab6211ca038a617f7e178815b2a42a4866a4a4b6d91d3a041ca8cbc83`.
