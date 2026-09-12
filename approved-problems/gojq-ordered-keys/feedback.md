# feedback.md — gojq-ordered-keys

## Summary

Olympus submission on itchyny/gojq (Go, MIT, 3786 stars, base `2e210b5c`): an `--ordered-keys`
option which keeps the key order of objects read from JSON, plus the `keys_unsorted` builtin and
`--sort-keys` (`-S`) that the missing order made pointless.

The difficulty is not in the semantics, which are jq's and can be stated in a page. It is in the
representation: gojq decodes into `map[string]any`, sorts on the way out, and backtracks by
restoring fork points that share value references. Adding an ordered object means a second
representation living beside the first through eighteen type switches, the two encoders, the
decoder, the comparison chokepoint and the update machinery, without moving the default off the
old path.

## Why this pick, after two dead ones

This is the third feature this task. The first two died on the same law from our own notes, from
opposite directions:

- **goawk nested arrays** was built end-to-end and killed at platform dedupe, Derivative 90%, by an
  older submission implementing the same `a[i][j]` core with `isarray`. The judge rated our extras
  (split into subarrays, getline into subarrays, subarray function parameters, nested Go API maps)
  as "incremental scope extensions over the same core lesson". You cannot out-add a superset.
- **goawk writable named fields**, the natural pivot inside the same repo, hit the maintainer on
  issue 245: "I wouldn't mind designing a better API for this, but I'm not sure what it would look
  like", and later "I still don't have a perfect answer for this". That is the defined-behavior
  gate, and PR 127 was closed with "I don't love that API either".

The repo hunt that followed env-gated eight candidates. `bazelbuild/buildtools` (7 red packages
offline), `thought-machine/please` (asp tests need build-graph data), `yassinebenaid/bunster`
(red, 100s), `gokrazy/rsync` (red) and `PyVRP` (C++ core) all failed. Two survived: gojq and
`flanglet/kanzi-go`. Kanzi is the better host on the gates but every feature there is a codec, and
a codec is judged by round-trip, which is the self-certifying shape `TOO-EASY.md` calls
recallable-dead.

## Known risk

Key order is a limitation gojq documents in its own README, which is where authors shop, so this
carries the same exposure that killed the goawk pick. It is mitigated but not removed by the fact
that an invasive value-representation change is a much less likely pick than an additive language
feature. The maintainer angle is defensible: the same README line says "I would implement when
ordered map is implemented in the standard library of Go", and opt-in is exactly what that
reservation asks for, since it leaves the default and every existing behavior alone.

## Design decisions worth recording

- **Opt-in, so the existing suite is the regression net.** The default representation stays
  `map[string]any` and the default output stays sorted, which is what lets a change this invasive
  be validated against the repository's own tests rather than against a rewritten baseline.
- **Order lives in the value, not in a mode flag read at print time.** Storing it on the value is
  what makes it survive arrays, variables and function arguments, and it is also what creates the
  copy-on-write problem, since the VM's fork points share value references.
- **`objectKeys` returns sorted keys for a plain map.** That one helper is why the ordered path and
  the default path can share every call site: iteration, encoding and `to_entries` ask for the key
  order and get the sorted order when there is none. It also let the redundant sort in the
  iteration opcode go away without changing base behavior.
- **`to_entries` was changed to use `keys_unsorted`, which is jq's own definition.** For a plain map
  `keys_unsorted` is sorted, so base behavior is byte-identical, and the ordered case falls out.
- **Constant-path assignment is compiled to a direct `setpath` call.** `.z = 1` never reaches the
  `_assign` builtin, so wiring the ordered allocator into `compileAssign` alone left object
  creation from `null` sorted. This took a debug print to find and is the sort of thing an agent
  will only notice by testing assignment on a null input.
- **`split` fills arrays in place, `update` writes through only what it allocated.** The allocator
  became a struct carrying the mode so an update can create the right representation, and it is
  still the thing that decides whether an object may be written through.

## Not done

The local imitator smoke batch was not run, so difficulty is argued from structure and the
mutation proof, not measured. The 10-run platform batch remains the only oracle.

YAML input is not made order-preserving; the yaml package in use carries order only through its
node type, and the description does not claim it.

### Round 40 — the same ambiguity, arriving from the other side

Two rounds ago I removed five tests because the description never said whether an object a builtin
constructs keeps order, and an implementation which ordered them would have been failed for a choice
nothing forbade. This round the solution review marked the reference down 2 of 3, twice, for the
opposite reason: not ordering them, "under a literal reading of objects the program builds".

Same sentence, two readings, and the ambiguous word was "the program". I meant the jq query. It was
read as gojq itself. Neither reading is unreasonable, which is exactly what makes it a defect.

The fix was one word and one clause, not more code. Converting every internal object-producing site
would have added a whole axis in the week I spent removing three of them, and would have needed tests
of its own to be fair. Saying which objects are in scope costs nothing and closes both readings.

The general lesson: when a word in the description can name either the user's program or the
implementation, it will eventually be read both ways, once by an agent and once by a reviewer.
Ambiguity does not fail in a fixed direction, so it is worth spending a word to close even when the
current reading happens to be the one you meant.

### Round 39 — check the premise before obeying a HIGH

A high-severity item asked me to delete the mention of `--sort-keys` because the flag "is already part
of the CLI". It is not: `grep` over the base tree finds nothing, and the README lists `-S` among the
things gojq deliberately does not have. Obeying would have orphaned 32 tests and taken the rate to
zero by itself.

The lesson is not that the checks are unreliable, it is that a severity label is a claim about
consequence, not about accuracy. Every item asserting that something is "already present",
"discoverable from the codebase" or "implied" is a factual claim about the repository at the base
commit, and it takes one grep to settle. I have now had two such claims turn out false, both at HIGH,
both of which would have broken the submission.

Everything else this round was refused on evidence already recorded: the truncated-input sentence is a
false-positive anchor, the visiting-order clause carries 12 tests through paths the named builtins do
not reach, and the assignment-creates-object clause was added to close an axis that had already killed
two runs.

### Round 38 — when adding coverage is the wrong move

Two advisory coverage suggestions arrived while the submission sits at zero of ten, and both were
refused. That is worth writing down because the reflex for most of this submission's history has been
to take every suggestion.

A coverage suggestion asks for a new assertion. A new assertion on a behavior the description does not
state is a new way to fail, and pass rate is a product across ways to fail. When a submission is
comfortably solvable, that trade is cheap. When it is at zero, it is the thing making it zero. The
concurrency one also duplicated coverage the garbage-collection tests already provide, and would have
introduced timing dependence into a suite the flakiness gate requires to be deterministic.

The same reasoning retired the YAML group: three tests, two of ten runs killed, and not one word about
YAML in the description. Identical in shape to the builtin-object tests removed last round.

The rule I would keep: audit coverage suggestions against the description before taking them. If the
assertion cannot be traced to a sentence, it is not coverage, it is a new requirement, and a new
requirement is the most expensive thing you can add to a problem that is already too hard.

### Round 37 — auditing the suite for axes nobody has hit yet

With the batch at zero, the useful exercise is not only fixing what killed runs but finding what would
kill the next one. Five tests rested on a choice the description never makes: whether an object a
builtin constructs, like a `match` result, is ordered or orderless under the option. The reference
treats it as orderless. An implementation which ordered it would be equally consistent with every
sentence in the description and would fail those five. Removed.

The habit worth keeping: when a submission is failing everywhere, audit the tests for assertions that a
*correct-looking* alternative implementation would fail, not just the ones agents actually hit. Latent
axes are invisible until an agent meets them, and each one multiplies into the pass rate exactly like a
measured one.

### Round 36 — batch 3, zero of four, and the arithmetic of axes

Ten fair runs, no passes. The tally matters more than any single run: truncated input killed six of
ten and all four of batch 3, the `add` fast path three, and the compiler axis three but none in batch
3, because round 33 fixed the opening sentence which had scoped the feature to decoded input.

That last point is the method. Correcting wording on the axis the batch says is killing runs works,
and it is not the same as making the task easier: the work still has to be found and done, the
description just stops misdirecting.

The arithmetic worth remembering: I replayed batch 3 against a suite where only truncated input was
solved, and all four still failed. Pass rate is a product across axes, so moving one axis from a
0-of-N submission usually changes nothing. Either move two, or accept that nothing changes. That is
why this round has two sentences rather than one, and why the previous single-clause rounds did not
shift the rate.

Both are behavior with the fix left hidden. Truncated input is now named by its symptom, "a cut-short
object or array is an error, not the end of the input", because the underlying trap is a stdlib
asymmetry (`Token` returns `io.EOF` where `Decode` returns `io.ErrUnexpectedEOF`) that produces a
silent success, and no amount of "is still rejected" makes a silent success visible. `from_entries` is
restored after being deleted in round 2 as implied; three runs then lost order through the `add` path
it is built on, which is what "implied" cost.

Risk stated plainly: this may overshoot. Two of batch 3 would now pass. The remaining axes have to
hold the rate under the cap, and if they do not, the fix is to add difficulty back, not to re-break
the description.

### Round 35 — a version warning worth checking rather than obeying

The sanity check warned that `for range 256` and `slices` need recent Go. Worth checking rather than
reflexively rewriting: `go.mod` declares `go 1.24.0`, so no toolchain that can build the repository at
all lacks either feature, the image is go1.26.3, and the base repository already uses the same
construct in `execute.go`. I rewrote the loops to the three-clause form, saw it cost nothing but the
repository's idiom, and put them back.

The general point: a portability warning is a claim about the floor, and the floor is written down in
`go.mod`. Check it before changing code, because matching the surrounding style is a real cost and
insuring against an impossible toolchain is not a real benefit.

### Round 34 — the second false positive, and a test I should not have removed

A second passing candidate, this time on the pointer-side-table design: order kept in a package-global
map keyed by memory address, never cleaned, so a default-mode compile inherits stale order once the
heap reuses an address. It breaks two clauses the description states outright.

The part worth carrying forward is that **the suite used to catch this**. Batch 1 run 2 had the same
design and the evaluator recorded a hidden test catching it. What changed is round 24, when the
test-quality check called the direct `gojq.Marshal` host-map assertions coupled and non-essential and I
removed them. They were part of what made a default-mode compile over a plain map observable after
ordered work.

So: a quality check that calls a test redundant is reasoning about style, and it cannot see which tests
are the only discriminator for a defect class. Before removing a test on that advice, check what
mutation or past run it is the sole catcher for. That is the second time an advisory removal has cost a
false positive, after the malformed-input axis.

The replacement tests are built the way the adjudicator described, and deliberately assert only the
sorted default-mode result, so a correct value-carrying design passes deterministically while an
address-keyed one fails once addresses are reused.

### Round 33 — a description item that was probably costing runs

The high item about the opening phrase is the most valuable thing this gate has produced. It said
"objects read from JSON" is misleading because ordering applies to program-created objects too, and it
is right in a way that matters: four of six fair batch runs died on program-created objects, and one
trajectory records the agent deciding literal order was "likely acceptable" to leave unordered. A
headline which scopes the feature to decoded input is a plausible cause of that reading, and I had been
treating the resulting failures purely as difficulty.

Worth generalising: when the same axis kills most runs, re-read the *summary* sentence before
concluding the task is hard. A rule stated correctly in paragraph three does not undo a headline which
frames the feature more narrowly, and agents read headlines.

The other high item asked to remove the sentence added one round earlier because a false positive shipped
without it. Refusing that is not stubbornness: a clean false-positive check is a submit gate, this one is
advisory, and its stated reason (an obvious default) is precisely the claim a real candidate disproved.

### Round 32 — a coverage suggestion answered by deleting code

The `-S`-on-diagnostics suggestion asked us to clarify the boundary, and clarifying it showed the
reference was on both sides of it: `debug` and `stderr` threaded the flag into their own encoders,
`halt_error` did not. Round 22 had already narrowed the rule to results precisely so diagnostics fall
outside, so the answer was to stop passing the flag in two places rather than to write a test. The
solution got smaller and now matches its own description.

The judgement worth keeping is why no test followed. Sorting diagnostics is neither required nor
forbidden by the description, so an implementation which does it is not a false positive, and a test
asserting it must not happen would create an axis where the natural implementation is the failing one.
Test what the description states; leave what it deliberately does not say untested.

The layouts suggestion collided head-on with the test-quality check, which two rounds earlier had
called exact whitespace assertions brittle and orthogonal. Asserting the key *sequence* instead of the
bytes satisfies both: pull the keys out of compact, pretty, tab, indent and join output and compare
them against each other. When two gates want opposite things about the same tests, look for the
assertion that is weaker than either and still discriminates.

### Round 31 — the halt_error path solved an old problem

The `halt_error` suggestion is the most useful single pointer this submission has had. Five rounds were
spent declining to test the exported `gojq.Marshal` on an order-carrying value, because every route to
one went through the new compiler option and naming it breaks compilation at the base commit. The
answer was that the CLI reaches `Marshal` itself, on the `halt_error` path, so the value can be built
by `--ordered-keys` and observed on standard error without the test naming anything new.

The lesson generalises past this feature: when a value shape is unreachable from the public API without
a symbol you cannot name, look for a place the product itself already builds that shape and observe it
there. The regex builtins solved the same problem for orderless objects a few rounds earlier, and this
is the same move.

Also added a default-mode guard on that path, because it is precisely where the false-positive
candidate leaked order without the option, and the partial-output rejection case, which the fixtures
restored after the false-positive review had missed: they all had a malformed *first* value, so nothing
covered a stream where output has already been written before the parse error.

### Round 30 — false positive, and the two lessons behind it

An agent passed all 238 tests without meeting the requirements, on two counts, and both were mine.

The first is the one I chose. The malformed-input tests were removed in round 20 to bring the pass rate
into band and declined again two rounds ago when the coverage check asked for them back, on the
grounds that they cost two of three runs in batch 1. A candidate then shipped exactly the defect they
existed to catch: bare `io.EOF` from the object-key read, so `{"a":1,` exits 0 and the input vanishes.
The rule I got wrong: **a clean false-positive check is a submit gate and difficulty is not.** When the
only thing standing between a wrong implementation and a pass is a test you deleted for pass-rate
reasons, you have not calibrated difficulty, you have bought a false positive.

The second is more general and worth carrying to every submission. The candidate leaked insertion order
into the default mode, and made base mode pass **by editing three expectations in the repository's own
`cli/test.yaml`**. Base mode runs the repository's tests as they exist after the patch, so an agent can
edit the test data and the regression net disappears. The only defence is new-mode tests which pin the
default behavior directly. Every submission which adds an opt-in mode needs those, and I had only two
of them where I needed six.

### Round 29 — the alignment check earns its place

The alignment check ran for the first time and immediately found something eight rounds of the
description-quality gate had not: a rule stated too narrowly. The sorted fallback for objects with no
order of their own was written as a property of `keys_unsorted`, but a dozen tests lean on it for
iteration, `to_entries`, `paths`, printing and both merges, using host maps and `match` results as the
orderless values.

The fix is worth generalising as a habit: when one gate says a rule is under-stated and another keeps
demanding brevity, promote the rule out of the clause it was buried in rather than listing the places
it applies. "An object which keeps no order of its own counts as sorted wherever the order is used"
covers all of them in one sentence and costs six words, and `keys_unsorted` gets shorter.

Also worth noting which gate to believe about fairness. The description gate optimises for brevity and
has been wrong twice now about what is implied; the alignment gate maps tests to sentences, which is
the same question the fairness gate asks. When they conflict, the ones checking coverage win.

### Round 28 — holding the line, and where it moved

Two high items. One moved: "the order survives wherever the object goes" went, because the printing
sentence says "the order **it keeps**", which already makes order a property of the value, and that is
what the transport tests actually need. Re-reading a sentence to find the one it is redundant *with* is
worth doing before defending it; this one really was covered.

The other was compressed instead. The merge rule now reads "`a + b` appends b's new keys in b's order,
and `a * b` does the same at every depth", which answers "over-specified" while keeping the two free
choices. Both parts are measured: a merge which builds from the map kills six or seven tests, so the
order of appended keys is specified rather than derived.

The coverage request to restore malformed-input checks is the clearest case yet of two gates pulling
against each other. That axis cost two of three fair runs in batch 1, and its only anchor was removed
twice by the description gate at high severity. Restoring it would mean testing a requirement the
description is not allowed to state. Unlike the YAML case there is no weaker assertion available,
because the failure mode is a silent success rather than a crash, so there is nothing to catch short of
comparing against the plain path.

### Round 27 — the YAML boundary, documented without reopening the axis

The suggestion to document whether the option affects YAML output was the useful kind, because it
pointed at a gap I had left when the YAML tests were removed for difficulty: the description scopes
ordering to JSON, but the failure mode there is not a wrong order, it is `{}` for every object, since
the YAML encoder cannot marshal a type with unexported fields.

The answer was to assert the pairs and not their order. Sort the output lines, compare the set, with
and without `-S`. An implementation which flattens ordered objects to plain maps passes, one which
keeps the order passes, and only one which lets the new type reach the encoder untouched fails. That
is a regression the feature introduces rather than a requirement being added, and the one run which
ever failed on YAML would have passed it.

The technique is worth keeping: when a removed axis leaves a documented ambiguity, re-add the weakest
assertion that still catches the regression class, not the one that was removed. Order-agnostic
assertions over a set are the usual shape.

### Round 26 — coverage round, one closed by scoping

The `-S`-on-stderr suggestion found a real false-positive hole rather than a coverage gap, and the fix
was a word rather than a test. "Everything it prints as JSON" swept in the diagnostic output of `debug`
and `stderr`, which nothing tested, so an agent that never threaded the flag into those two encoders
would have passed while leaving a stated rule unmet. Scoping it to "every result it prints" closes the
hole without adding a failure axis, which is the right trade while the pass rate is at zero.

Worth generalising: when a coverage suggestion names an untested consequence of a broad rule, there are
two ways to close it, and with difficulty already too high the wording is usually the better one. Test
it when the behavior is central, scope it out when it is peripheral.

The `gojq.Marshal`-on-an-ordered-value request came back for the fourth time and the answer is
unchanged, but it is worth writing down why it keeps recurring: the suggestion is reasonable on its
face and only fails on a constraint invisible to the checker, that naming a new exported symbol in a
same-package test breaks compilation at the base commit. Recording the answer where a reviewer will see
it is cheaper than re-deriving it each round.

### Round 25 — coverage round, two of three taken

The assignment-created-nesting suggestion is the most useful the coverage check has produced here: it
lands on the axis that killed four of six batch runs, and an object created as an *intermediate* level
on the way down a path is a harder case than one created at the top. Five tests added.

`debug` and `stderr` were taken in half on purpose. Both print in the carried order and that is free
for any implementation whose encoder handles ordered objects, so those two tests cost nothing. Whether
`-S` reaches those separately-built encoders is a distinct piece of flag threading, and with the
submission sitting at zero passes over six runs, adding a failure axis is the wrong direction. Noted
rather than tested.

The module-loader suggestion was declined because it would fail our own reference solution, which is
the check worth running on every coverage suggestion before taking it: does the reference actually do
this? If not, the suggestion is a scope increase wearing a coverage hat.

### Round 24 — test-quality and description round

Seven tests removed on the test-quality warning. The `gojq.Marshal` pair was the fair hit: the
description says nothing about the Go marshaller and their library halves duplicated existing tests.
The formatter and colour trims are the same idea, cutting cases which exercise machinery the feature
does not touch.

The description round cost the equality sentence, which is the first anchor I have given up while its
tests stayed. It is defensible here because those tests assert that existing behavior is unchanged and
`Compare` visibly sorts keys, which is the strongest form of repo-discoverable; three of that group
were already classified that way. Worth watching in the next fairness run.

Declined the request to remove the clause added last round for the object-created-by-assignment case.
It was flagged low severity as unnecessary elaboration, and it is the clause that exists because a run
lost eight tests to that exact ambiguity. When a gate calls something redundant and a batch says
otherwise, the batch wins.

### Round 23 — second platform batch, 0 of 3, one clause added

Three more Nova runs against the reduced suite, all FAIL_MISSED_REQUIREMENT, all on the same axis:
objects the jq program creates rather than decodes. Six fair runs across two batches and that axis
killed four of them. Nobody has failed on the representation, decoder, encoder, comparison, deletion
or iteration; what gets missed every time is `compiler.go`, the object-construction opcode, and the
allocator/setpath selection.

The response was one clause, chosen to be the narrowest available. Batch 2 run 2 ordered everything
except the moment an assignment has to *create* the object, where it passed `ordered=false` because
the current value was null. That is a genuine gap in the wording: "a key the program creates goes to
the end" says where the key goes and nothing about what the container is when the assignment brings it
into being. Naming that converts a measured 227-of-235 into a pass and leaves the literal axis alone.

The bigger clarification was available and refused. Restoring "an object built by the program keeps
the order its keys were created in", which the description gate made us delete in round 18 as
redundant, would likely have converted three more runs and pushed the rate over the too-easy cap.

Two lessons, both about calibration rather than code:

- When a batch comes back 0 of N, resist the urge to clarify the axis that killed the most runs. Find
  the run that came closest, work out the single ambiguity that cost it, and fix only that. Difficulty
  is a product across axes, so one clause moves the rate far more than it looks like it should.
- The description gate's "this follows from the general rule" is a claim about a careful reader, and a
  batch is the only way to test it. It was wrong here: four agents read the key-creation rule and left
  object literals unordered, one of them explicitly reasoning that literal order was not crucial.

### Round 22 — first platform batch, 0 of 4, and the fixes

Four Nova runs, four failures. Three were legitimate and informative; the fourth was our bug.

**The bug worth remembering.** Our test file declared a package-level helper called `ordered`. An
agent put its ordered-object type in `internal/ordered`, imported it in three cli files, and the
tagged test binary then refused to compile: a same-package test helper shares its namespace with
every import in every file of that package. All 258 tests were reported missing and the evaluator
called the blame unfair. Three of our identifiers were single lowercase words, `ordered`, `obj` and
`wide`, each of which is a plausible package name. The rule to carry forward: no package-level
identifier in a same-package test file may be a single lowercase word, because the solution gets to
choose its own package names and will collide with you.

**Difficulty is real, and it was slightly too high.** The two core traps each killed a run on their
own and neither agent found the other's problem: run 1 missed that `funcAdd` has a map fast path
separate from `funcOpAdd`, which is what `from_entries` is built on, and run 2 never touched the
compiler's object-construction path. Those stay.

What went was the peripheral axes that were both weakly anchored and repeatedly fatal: truncated-input
parity, whose only description sentence the description gate had forced out twice at high severity,
and YAML output, which is now scoped out of the description as well as the tests. Replaying the three
fair runs against the reduced suite turns run 3 into a pass while leaving runs 1 and 2 failing on the
core, which is the band we want.

The general lesson about axes: pass rate is the product of per-axis success, so the way to move a
0-of-N submission into band is to delete whole peripheral axes, not to soften the central trap. Pick
the axes the description cannot state, since those are unfair and expensive at the same time.

### Round 21 — nineteenth review response

Description Quality reached minor_suggestions for the first time, after five rounds of trimming. The
shape that got there: state each rule once, at the level of the rule rather than its instances, and
keep only the clauses a test actually rests on. Both remaining items were optional; the low one was
taken and the medium one declined because it is the round-1 fairness anchor.

Both coverage suggestions were worth taking. The escaped-duplicate-key case is a genuinely good edge:
`{"a":1,"\u0061":2}` names one key twice and the rule has to be applied after decoding, not to the
text. It already worked, and one of the six new tests uses an input whose surviving order differs from
sorted so it cannot pass by accident, which is the check I should apply to every new expected value.

### Round 20 — eighteenth review response

Three of five description items taken. The high one was split the same way as the merge sentence two
rounds ago: the conceptual framing went, the operative claim stayed. That split is now the reliable
answer to this gate, because its "derivable from the general rules" argument is usually right about the
abstraction and wrong about the specific consequence.

Two medium items were declined for the second and third time, and the fairness report is what makes
declining defensible: it lists, per test group, the description sentence it treated as the anchor. Any
sentence named there cannot be deleted without turning that group into an author choice. Keeping that
mapping to hand is worth more than arguing each round from memory.

Separately, reading the generated patch turned up a defect no check had flagged: the new compiler
option had been inserted between `WithInputIter`'s doc comment and its function, so the comment
documented the wrong symbol and `WithInputIter` was left bare. Fixed. Add it to the pre-submit list:
grep the diff for an added function that lands between an existing comment block and its declaration.

### Round 19 — seventeenth review response

Test Fairness failed on one test of 248, added by me the round before, and the verdict is right. For a
merge whose left operand carries no order and whose right one does, I asserted the result matches plain
mode exactly, which forces globally sorted keys. The description's merge wording points at least as
strongly the other way, sorted-left then the right operand's own order, and the pre-feature repository
cannot decide it. Deleted.

The lesson corrects something I had started to treat as a rule. Differential assertions have settled
four fairness questions in this submission, so I reached for one again here, but the comparison itself
has to be forced for that to work. "Identical to plain mode" was not a neutral baseline in this case, it
was one of the two contested answers wearing a baseline's clothes. Check that the thing being compared
against is fixed by the prompt or the repository before treating equality as fair.

Also worth recording: I noticed this half was the debatable one while writing it, and shipped it anyway
because the mechanism looked safe. The doubt was the signal, not the mechanism.

### Round 18 — sixteenth review response

Both coverage suggestions taken. The first was the interesting one: it asked what happens when an
ordered object meets one with no order to give, which the library route cannot reach without naming the
new option. The way in was to find a source of order-free objects inside the CLI, and the regex builtins
are one, since `match` builds its result as a plain Go map. Worth remembering as a technique: when a
suggestion needs a value shape the public entry point cannot produce, look for a builtin which
constructs that shape internally.

Half of the resulting tests need no description support because they are differential: with the
order-free object on the left the output is byte-identical to the same query without the option. That is
the third time this round-12 pattern has resolved a fairness question without adding a sentence, which
matters while the description gate is removing them.

### Round 17 — fifteenth review response

Five items, three addressed. The interesting one is the merge sentence, flagged high as
over-specified. It is half right, and splitting it was the answer: the part about shared keys keeping
their position genuinely follows from the general existing-key rule, but the order in which the right
object's new keys get appended is a free choice, and so is the recursion in `a * b`. Round 1's
fairness report had cited that exact sentence as the evidence making nineteen merge tests
prompt-stated, so deleting it wholesale would have traded a description warning for a fairness
failure. Compressing to the two non-derivable choices satisfies both.

That is now the standing method for this gate: for every clause it calls derivable, work out which
half actually is, delete that half, and keep the choice. Deriving "follows from the general rule" is
usually true for the value semantics and false for the ordering, which is the whole subject of the
task.

### Round 16 — fourteenth review response

The two gates asked for opposite things about the same behavior in the same round: the description gate
wanted the malformed-input clause gone as an obvious default, the coverage gate wanted more
malformed-input tests. That is not a contradiction once you notice they are answering different
questions, and the resolution updates what I said in the previous round. My worry was that the eight
malformed tests rested on an unstated requirement. The gate which judges that had already passed them
three rounds running before the clause existed, and the description gate now calls the requirement an
obvious default, which is the same thing said from the other side. So the clause was defensive rather
than necessary, and the high item is right that it reads as noise. The scope half of the sentence stays
and carries it.

Lesson for the next submission: when two gates conflict, check which one owns the question. Fairness is
owned by the fairness gate, and its verdict on a specific test set is better evidence than my own
reading of the prompt.

Two of the four lower items were declined because each is the only anchor for a group of tests, and one
of those, the visiting-order sentence, exists precisely because the fairness gate failed seven tests
without it in round 1. Worth keeping a note of which description sentences were added to satisfy a
previous gate, since a later gate will ask to remove them.

### Round 15 — fairness audit of the malformed-input tests

Reviewed the eight malformed-input tests on request. Solvable yes, they pin only exit-code parity.
Fair no, until this round: the description said nothing about malformed input, the failure is silent,
and the hazard is an `encoding/json` detail the repository never touches, so neither the prompt nor
the codebase pointed at it. Base mode does not cover it either, because none of the repository's 22
malformed-input cases use the new option. Fixed with one sentence of contract rather than by deleting
the tests, which turns an undocumented gotcha into the shape we want: contract stated, fix hidden.

The general check this suggests, for every future submission: for each group of tests that fails for
one shared reason, ask whether the prompt states the requirement and whether base mode would catch a
solver who missed it. If the answer is no twice, it is a hidden requirement no matter how correct the
behavior is.

### Round 14 — thirteenth review response

Both high description items taken, and they cost nothing this time. That is the payoff from the
previous round: once the sorted-side tests became differential, the description no longer needed to
say what the default was, so the sentence the gate had been flagging for three rounds could finally
go. Worth generalising: a description clause that exists only to anchor a literal assertion can often
be removed by rewriting the assertion as a comparison against the unchanged path.

The medium item is declined. It would remove the statement that printing follows the kept order, on
the grounds that the visiting-order sentence implies it. Printing order is what most of the suite
asserts and "visited" is not "printed", so that inference is too load-bearing to rely on.

The test-quality warning was ours: a test named for an array of scalars fed a string. Renamed. The
same check cleared the cli-struct coupling this round without further argument.

### Round 13 — twelfth review response

The test-quality check flagged the collation tests as pinning behavior the description does not state,
which was fair: they were added two rounds earlier at the coverage check's request and I wrote them as
literal expected orders. They are differential now, comparing the same input with and without the
option, which is what the original suggestion actually asked for ("confirm the existing ordering is
retained") and pins nothing. The general form is worth reusing: when a coverage suggestion asks you to
confirm existing behavior survives a change, assert equality against the unchanged path, never a
literal.

The other half of the warning, coupling to the private `cli` struct, is kept. It is the repository's
own test convention, it is the only way to capture the output streams without swapping process-global
file descriptors, and moving to the exported entry point would reintroduce the F2P classification
problem. Recorded in `eval-results.md` so a reviewer sees the reasoning rather than re-deriving it.

### Round 12 — eleventh review response

The checker read the test helpers and found a bug in one: `return outStream.String(), c.run(args)`
evaluates left to right, so the output string was captured before the query ran and was always empty.
Every assertion built on it was vacuous. Worth remembering as a Go-specific trap in test helpers,
since it reads correctly and the tests it feeds go green.

Fixing it broke a test, which is the point: comparing the already-emitted output of the two routes was
wrong, because the value printed before the failure comes out in different key orders on each side.
The comparison now belongs to that one test, and the shared helper asserts that neither route printed
anything, which is true for every other malformed case.

The library tests now marshal through the public `gojq.Marshal` instead of `encoding/json`, which
costs nothing and puts the public serialization API under test. The ordered half of that suggestion
stays declined for the standing reason: naming the new compiler option in a test breaks compilation at
base and costs per-test F2P classification for the whole package.

### Round 11 — tenth review response

The advisory check found its second real defect. Malformed JSON on the ordered route exited 0:
`json.Decoder.Token` reports `io.EOF` when the input stops inside a value, `Decode` reports
`io.ErrUnexpectedEOF` for the same thing, and the input iterator treats `io.EOF` as a clean end of
stream. So a token-based decoder silently accepts every truncated input, and the whole suite missed
it because every test fed it valid JSON. Reading tokens through a helper which converts that one
error fixes it.

The general lesson is bigger than this feature: replacing a library call with the lower-level API it
is built on inherits none of its error normalisation. `Decode` was doing work beyond parsing, and
that work has to be redone by hand. Any future decoder written against a token or event API needs a
malformed-input test per shape, compared against the call it replaced rather than against a pinned
message.

The colored-output tests are written to survive a palette change: strip the escape sequences, compare
the remainder, then assert escapes were there at all. `noColor` needs no save and restore because
`runInternal` already defers it.

### Round 10 — ninth review response

Both coverage suggestions taken, and both were about the *sorted* side rather than the carried side,
which is where the suite was thinner than it looked. Recursive sorting was covered through nested
objects but never across an array boundary, and the Unicode tests all checked carried order, so
nothing confirmed that adding a second key order left jq's string ordering alone. Eleven tests now
cover both, all matching jq.

Pattern after ten rounds: the checker keeps finding the *complement* of what was tested. Order kept
was covered before order sorted; objects inside objects before objects inside arrays; carried
Unicode before sorted Unicode. Worth building the next suite in pairs from the start, since each
rule with an opposite has two halves and only one tends to get written.

### Round 9 — eighth review response

Solution Quality passed with comprehensiveness 3 of 3 and code quality 2 of 3. Both nits were real
and are fixed: a duplicate ordered decoder left in `cli/inputs.go` by a botched deletion (the
comment went, the body stayed), and a map copy in the CLI encoder. `OrderedObject.Map()` went with
the second fix, since that call was its only user.

The test-quality warning was about brittleness, and the fix improved the tests rather than weakening
them. Comparing the exit code of `keys_unsorted` against the exit code `keys` gives for the same
input states the actual requirement, where matching "cannot be applied to" only stated the current
wording. The first attempt at it was wrong in an instructive way: running both sides under
`--ordered-keys` made all five tests pass at base, because an unknown flag makes both exit
identically. A differential assertion is only F2P-safe if the baseline half runs on the surface that
already exists.

One mutation could not be written at all. Making the encoder rewrite the value's key order while
sorting is a no-op, because `Delete` is copy-on-write and the key slice is unexported, so no code
outside the gojq package can reorder a value it is printing. Worth remembering as a design result:
some properties are better enforced by the type than proven by a test, and a mutation that refuses
to bite is sometimes telling you that.

### Round 8 — seventh review response

Both coverage suggestions taken. The `with_entries` one is the most useful the checker has produced:
renaming keys is where the creation-order rule and the existing-key rule meet, and a collision is
the only place their composition is observable. A mutation making a key written again move to the end
kills eighteen tests, so that composition was under-tested before even though both rules were
covered separately.

The base-passer trap appeared once more, in a new disguise: a collision which collapses two keys
onto one leaves a single-key object, whose sorted and carried order are identical, so the assertion
holds at base. Any expected output with one key, or with keys that happen to be in alphabetical
order, is a base-passer regardless of what it is testing. Check the expected string, not the query.

### Round 7 — sixth review response

Both coverage suggestions taken. Streaming input needed the base-passer treatment again: `--stream`
already emits events in text order at base, since the decoder reads tokens in sequence, so the
event-order assertions are paired with a `fromstream(inputs)` reconstruction which base gets wrong.

The deep-merge suggestion turned up a measurement error in our own proof method, worth carrying
forward. Go randomises the starting offset of a small map's iteration and then walks it in slot
order, so iterating a map yields a *rotation* of the insertion order, not an arbitrary permutation.
A single n-key test therefore lets a map-order implementation through about one run in n, not one in
n factorial, which is why an earlier six-key test looked like a solid discriminator and was not. The
fix is several tests of different widths per family, and reporting map-order mutation kills as a
range over several runs rather than a single number.

### Round 6 — fifth review response

Two of three coverage suggestions taken; the third asked for tests naming the new compiler option
on the public API, which cannot be done without losing per-test F2P classification for the whole
package, so it was declined with the reasoning in `eval-results.md`. Worth keeping: the F2P
constraint that decides where tests live also decides which coverage suggestions are reachable, and
a reviewer will ask for the ones it forbids.

The library-level tests exposed the base-passer trap again, and in a new way. Three of them
asserted that a plain Go map iterates, lists entries and yields paths in sorted order, which is
already true at the base commit, so they passed there. The fix is cheap once seen: fold a
`keys_unsorted` assertion into the same query, so the query itself cannot compile at base. Any test
written to check a fallback to existing behavior is a base-passer by construction; check for that
before running the batch.

### Round 5 — fourth review response

The advisory coverage check earned its keep: one of its three suggestions found a real defect.
`--yaml-output` combined with `--ordered-keys` printed `{}` for every object, because the YAML
encoder cannot marshal a type with unexported fields and fails quietly. Nothing in the suite went
near YAML output, and the differential harness only ever ran JSON, so it would have shipped. Fixed
by building a mapping node with the keys in order, honouring `-S`.

The lesson for the next build is about the proof rather than the code: the first two mutations
written to kill the new YAML tests did not compile, and a build failure emits no `--- FAIL` lines,
so the harness scored them zero and they read exactly like untested behavior. That is the same
shape as the `[build failed]` node trap already in our notes. The harness now checks for a build
failure before counting kills.

### Round 4 — third review response

Description Quality, one high and four lower items; four taken, one refused with a reason recorded
in `eval-results.md`. The refused one is the sentence stating the current default, which is the
only anchor left for the tests that assert default behavior after round 1 deleted the other
statement of it. Taking it would trade an advisory warning for a fairness failure, and fairness is
the blocking gate.

The pattern across three description rounds is worth naming: the checker asks for the general rule
and not the instances, every time. Write the rule once, precisely enough to be a contract, and
never enumerate what follows from it. The one thing it will not tell you is which of its own
suggestions is load-bearing for a test, so check every quoted sentence against the suite before
deleting it.

### Round 3 — second review response

Test Fairness passed; three advisory coverage suggestions, all taken. The first was the only one
that needed a decision rather than a test: whether `-S` reaches `tojson` and `@json`. It does not,
which is what jq does too, so the boundary is now pinned from both sides and the description says
`-S` "sorts the keys of everything it prints" instead of "prints keys sorted". The second exposed a
wording gap rather than a behavior gap: the duplicate-key rule said "the input", which reads as
stdin, while `fromjson` and `--argjson` decode through their own path; it now says "in the text".
The third needed nothing but tests, being the creation-order rule composed with the existing-key
rule.

### Round 2 — review response

Description Quality asked for one removal (a backward-compatibility assurance) and four trims
(a historical aside and three example lists). All five taken. The rule from our notes held: every
trim kept the general clause, because two of the removed example lists were the only anchor named
by a coverage suggestion, and deleting the rule as well as the examples would have made those tests
unfair. The default-mode anchor moved into the opening sentence about what gojq does today.

Test Fairness failed on 7 tests in 3 groups, all pinning the order in which an object's members are
visited (`[.[]]`, `paths`, `tostream`) which the description never stated. One sentence covering
all three went in rather than deleting the tests, since the visiting order is genuinely part of the
contract and is what `to_entries` and everything else derives from. Worth recording: the checker
found this by reading `execute.go:283-302` and noting the pinned VM sorts object iteration, so it
is checking assertions against the base repository, not just against the prompt.

All five coverage suggestions were taken (12 new tests). Two of them were real weaknesses rather
than gaps: `sort` compared single-key objects and `min_by` compared a numeric projection, so
neither could have detected an order-sensitive comparison at all, which is the trap they were
named for. One test name described the opposite of what it asserted and was renamed.

### Round 1 (initial build)

- Semantics fixed against jq 1.7 in the base image before any code; a 50-program differential run
  and ten fork-point probes match jq apart from error wording and one builtin gojq lacks.
- Built in dependency order: ordered object type, then the binary-operator chokepoint, then the
  two encoders and the iteration opcode, then the object builtins, then the decoder, the compiler
  option, the object literal opcode and the allocator.
- Four defects found and fixed along the way: `getpath` did not accept the new type, so every
  update-assign failed; the `fromjson` special case swallowed the default path until it was moved
  out of the name switch; the allocator's zero value stopped recording allocations and turned
  `delpaths` quadratic, which showed up as the CLI suite going from 1.4s to 39s; and constant-path
  assignment bypassed the ordered allocator entirely.
- Mutation proof ran twice. The first pass exposed three requirements the tests did not
  discriminate and two mutations that killed nothing because the method they targeted was
  unreachable. The dead method was removed and twenty-two tests over a six-key object were added,
  since a two-key object matches Go's map iteration order half the time.
