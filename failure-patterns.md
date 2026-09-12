# FAILURE PATTERNS — What Actually Kills Agents (evidence registry)

Mined from shipped Olympus problems by reading every agent run's `eval-result.json`,
`solution-patch.patch` and `workspace-diff.patch` — not from intuition. Every pattern below
carries a measured kill count against a real batch.

**What this file is for.** `HARDENING.md` is the doctrine (S/A/B arsenal, the
CONTRACT-STATED/FIX-HIDDEN axiom, the re-hardening method). THIS file is the empirical
layer under it: the specific trap shapes that have been measured on OUR problems, with the
exact agent behaviour they exploit, so the next pick can reach for a proven shape instead of
re-deriving one. Read `HARDENING.md` for HOW to build fairly; read this for WHAT to build.

**How to use it.**
1. At design time, open § 1 and pick 2-3 patterns whose preconditions your repo satisfies.
2. Check the pattern's *precondition* honestly — most died elsewhere because the repo did
   not actually have the seam.
3. Reproduce the trap before writing tests (HARDENING 3a.4). A pattern from this file is
   still a guess until you have written the natural-but-wrong implementation and watched it fail.
4. After the batch, add your kill counts back into § 1 and add a dossier in § 2.

**Source problems.** `calyx-unused-port-elimination` (Rust, whole-program compiler pass, 13
batches / ~130 runs), `pulldown-cmark-gfm-autolinks` (Rust, markdown inline parser, 2+
batches / 22 runs), `lyon-arcs-join` (Rust, stroke tessellator, 1 agent batch / 10 runs,
plus multiple platform review rounds post-batch: Test Fairness, Task Quality, Auto Review, and
a 3-judge FP panel), and `neva-array-bypass-generalization` (Go, dataflow-language compiler +
runtime, 1 batch / 10 runs at 2/10 = 20%, 8 review rounds). All accepted or submission-ready.

---

## 1. THE PATTERN CATALOGUE

Ranked by measured kill rate. `F-` numbers are stable IDs — cite them in `DESIGN.md` and
`feedback.md` so evidence accumulates against the ID.

### F-1. Convergent-architecture wall ★ the highest-value pattern found so far

**Mechanism.** Every agent independently picks the SAME architecture (the obvious one). Find
the requirement that architecture structurally cannot satisfy, and make it a documented
contract. Not a bug in their code — a ceiling of their design.

**Why it misdirects.** Nothing in the failure points at "your architecture is wrong". The
agent sees one odd output case and patches locally, which cannot work; the fix is a rewrite
they have no reason to attempt.

**Evidence.** pulldown-cmark: the mid-hardening batch was **8/12 = 67%, too easy**, and all
12 agents (plus the author's own reference) used a post-pass over `Event::Text`. pulldown's
inline parser converts `*b*` to EMPHASIS *before* any post-pass can run, so
`http://example.com/a*b*c` links only `http://example.com/a` under a post-pass, while GFM
requires the whole URL. Documenting that contract and implementing source-based reclaim took
the batch to **4/10 = 40%, in band**. One lever, 27 points.

**Precondition.** A pipeline with an earlier stage that destroys information a later stage
needs. Parsers, compilers, and renderers have these; flat transformers do not.

**How to build.** Batch first at moderate difficulty and READ THE PASSING PATCHES — you cannot
guess the convergent architecture, you have to observe it. Then ask: what is this design
structurally blind to? State that as a behavioural contract (WHAT), never as "use source-based
detection" (HOW). Verify your own reference does the hard version; if your reference shares the
agents' architecture, you have found a wall you have not yet climbed.

**Cost warning.** This lever can overshoot to 0%. pulldown flagged the risk explicitly before
batching. Mitigate by naming the ROOT CAUSE in the meta (HARDENING 3c-bis) — pulldown's meta
says emphasis characters are ordinary parts of the run — so a competent solver can get there.

---

### F-2. Bidirectional seam through one construct — 25/50 failing runs (50%)

**Mechanism.** One language/IR construct participates in a rule in BOTH directions. Agents
implement one direction and miss the other, or implement both without letting them interact
to a fixed point.

**Why it misdirects.** The half-implementation passes every single-direction test. The failure
appears as an unrelated element surviving or vanishing two steps away.

**Evidence.** calyx invoke bindings — **the dominant killer in all six analysed batches**. An
`invoke` output binding both (a) keeps the callee's output live because something reads it, and
(b) must itself be pruned when its destination port dies, which can then kill the callee output
on a LATER round. Verbatim failures: *"A dead caller output remains live solely because it is
the destination of an invoke output binding"*; *"Invoke output bindings keep dead destination
ports and their callee outputs live, preventing the required fixed-point elimination."*

**Precondition.** A construct that is simultaneously a producer and a consumer in your analysis
(call bindings, aliases, bidirectional edges, two-way type constraints).

**How to build.** Require a fixed point over the whole program, not a single pass. State the
cascade in the meta as a rule ("a binding counts only while it survives") without enumerating
which cascades exist. Test the second round explicitly — a case that only resolves after the
first round's removal.

---

### F-3. Protected-carve-out applied to one axis only — 14/50 (28%)

**Mechanism.** A rule protects an entity ("this component's signature never changes"). The
signature has TWO axes (ports and ref cells). Agents implement the obvious axis and silently
drop the other.

**Why it misdirects.** The rule reads as one requirement, so agents believe it is done. The
protection tests for axis one all pass.

**Evidence.** calyx `@fixed_signature` + entrypoint: **14/50 failing runs**, present in every
batch. Verbatim: *"Unused ref cells are removed from protected signatures"*; *"Fixed-signature
and entrypoint ref cells are removed even though their signatures must remain unchanged."*

**Precondition.** A protected/exempt entity whose definition spans two collections in the data
model.

**How to build.** Write the exemption as ONE sentence covering the entity, never a list of the
axes it covers (Rule-7). The second axis is the trap; enumerating it hands the fix. Confirm the
naive implementation misses it before authoring.

**Arsenal mapping.** HARDENING A3 (reuse-the-machinery missing arm) / A6 (second-op narrow guard).

---

### F-4. Host-language ownership trap — 9/50 (18%), kills whole runs

**Mechanism.** The natural traversal violates the host language's aliasing/ownership rules.
Correct algorithm, runtime blow-up.

**Why it misdirects.** The failure is a panic in 30+ tests at once, reading as a catastrophic
bug rather than "restructure the traversal into collect-then-mutate".

**Evidence.** calyx: **9/50** runs died on `RefCell already mutably borrowed` while pruning
assignments inside a group — one run failed 32 tests from this alone. Verbatim: *"Dead-port
pruning panics on assignments in groups because it re-borrows a group while that group is
already mutably borrowed."*

**Precondition.** Rust `RefCell`/`RRC` graph IRs, Go maps mutated during range, Python
collections mutated during iteration. Fair only when the repo's own source demonstrates the
correct pattern.

**How to build.** Require mutation of a container while a visitor holds it. Do not mention it
in the meta — this is a repo-convention discovery, not a behaviour.

**Arsenal mapping.** HARDENING A4 (host-language semantics).

---

### F-5. Transitive reachability through a pass-through node type — 6/50 (12%)

**Mechanism.** Liveness/taint must flow THROUGH a node type that is not itself a sink.
Agents treat the node as terminal in one direction.

**Evidence.** calyx combinational cells: *"The pass incorrectly removes inputs that reach
observable state through combinational logic"*; *"Ports feeding observable state or live
outputs through combinational cells are incorrectly eliminated."* Also the source of the
**v7 reviewer finding**: agents had been classifying "stateful" by NAME
(`contains("reg")||contains("mem")`) rather than by the IR predicate, which satisfies every
reg/mem test while silently mishandling `std_mult_pipe`.

**How to build.** Include at least one instance of the class whose NAME does not match the
obvious substring. This is the cheapest possible discriminator against name-based shortcuts and
costs zero pass-rate when agents already use the right predicate.

---

### F-6. Ordering of validation against normalisation — measured on pulldown

**Mechanism.** Two documented steps whose ORDER is not stated because it seems obvious.
The natural order is wrong.

**Evidence.** pulldown: *"A standalone `www.` is incorrectly autolinked because domain
validation occurs before trailing-period removal"* — and a sibling run **panicked** slicing the
empty host of the same degenerate input. One documented rule pair, two distinct kills.

**How to build.** Two documented transforms + one input where applying them in the natural order
gives a different answer. State both rules, never their order. Include the degenerate input
(the empty/one-character case) — it converts a wrong answer into a crash.

**Arsenal mapping.** HARDENING A8 (validation-order / precedence inversion).

---

### F-7. Context-exclusion completeness — measured on pulldown

**Mechanism.** A feature must be suppressed inside N contexts. Agents implement the ones with
an obvious representation and miss the ones handled elsewhere in the pipeline.

**Evidence.** pulldown: *"Bare URLs inside fenced code blocks are incorrectly autolinked"*
(inline code spans were handled, fenced blocks were not); *"Bare autolinks are incorrectly
created immediately after a code span"* (boundary computed from the start of the text event
rather than the preceding source byte — the author's own reference had this bug too, flagged
twice by the reviewer).

`rocketpy-propellant-slosh`: **3 of 10 runs** drove slosh modes with parachute drag where the
contract says a phase resolving no lateral body-frame force uses a zero drive. Every run
suppressed the drive correctly on the RAIL (obviously constrained, zero rail tests killed
anyone) and missed the parachute, because the parachute phase visibly carries a force that
merely is not a resolved lateral body force. The context that superficially HAS the quantity is
the one that gets missed, not the one that lacks it.

**How to build.** Pick a repo where suppression contexts live in different pipeline stages.
State the exclusion as one general principle. **Nesting is the real trap** — pulldown's
reference used a `bool` for "inside a link", which an inner Image `End` cleared, so a URL after
an image but still inside the outer link autolinked into nested `<a>`. It had to become a depth
counter.

---

### F-8. Named-real-world-algorithm override ★★ near-total kill on a single lever

**Mechanism.** The feature's name or framing matches a FAMOUS, well-documented external
algorithm/spec (an RFC, a W3C spec, a textbook construction, another well-known library's
method). The task requires a DIFFERENT, project-specific variant of that named thing. Agents
recognise the name from pretraining, retrieve the famous construction from memory, and
implement THAT instead of the literal contract in front of them — even when the literal
contract is stated in plain, unambiguous prose and directly contradicts the famous version.

**Why it misdirects.** The agent is not being careless; it is being confident. Retrieving a
known, "correct", well-understood algorithm feels like the informed move, so the agent does not
re-read the spec's dissenting sentence as carefully as it would a genuinely novel requirement.
The failure surfaces as a geometry/output-shape mismatch deep in the diff, not as a missing
feature, so it reads like a subtle bug rather than "you solved a different, adjacent problem."

**Evidence.** `lyon-arcs-join`: task adds `LineJoin::Arcs`, explicitly described as keeping the
join surface "at the same radius `Round` uses" while bending through a curvature-derived
intermediate point (i.e. one circle centred ON the join, radius = half_width — curvature only
picks the peak's DIRECTION). SVG2's real, famous "arcs" line join is a different construction
entirely: two offset osculating circles (one per incoming/outgoing edge), meeting at their
nearest intersection — full curvature-following, no shared centre. **9 of 10 Nova runs**
independently built the SVG2 osculating-circle construction (verbatim from one run's own
reasoning: *"consciously designed the join as two equal-curvature offset circles meeting at
their nearest intersection... solves a different, more literal SVG arcs construction than the
task specified"*). All 9 failed the same core assertion (`polyline_points_stay_at_half_width_
from_the_join`), all 9 also reinvented the miter-limit boundary check (`half_width * miter_limit
* 2.0`) instead of reusing the repo's own `miter_limit_is_exceeded` helper — a correlated
secondary tell that once an agent commits to the famous external construction, it stops
consulting the local codebase's existing conventions too. Exactly 1/10 (Orion-style decisive
single-pass) read the meta's contrasting sentence literally and matched it. Kill rate: **90%
on a single documented sentence**, no additional traps needed to reach it.

**Precondition.** A feature whose natural name overlaps a real, named, well-known external
algorithm/format/spec, where the project's actual required behaviour is a deliberate,
documented DIVERGENCE from that famous version (same name, different math/semantics).

**How to build.** Pick a subsystem that borders a well-known external concept (a compression
format, a crypto primitive, a graph algorithm, a markup spec, a geometric construction from a
named standard). Confirm the target repo's actual required behaviour differs from the textbook
version in a specific, statable way. State the TRUE contract in the meta as one plain contrasting
sentence (WHAT: "at the same radius X uses", never HOW: "not two offset circles") and let the
name alone do the misdirection — do not warn the agent the famous version is wrong, that would
destroy the trap. Verify by literally writing the famous-textbook implementation yourself first
and confirming it fails your own tests; if it passes, your contrast sentence is not load-bearing.

**Cost warning.** This is a single-sentence, single-mechanism lever — pair it with at least one
orthogonal trap (a second dispatch site, a public-API consistency check) so the design does not
rest entirely on one comprehension slip, per the difficulty-calibration doctrine's "stacked, not
uniform" requirement. On its own this lever can plausibly overshoot toward 0% with a smart-enough
solver batch (Orion/Vega), since it is a single, fully-determinate reading comprehension check,
not a multi-step design wall.

**Arsenal mapping.** Adjacent to HARDENING's precision-wording levers, but the mechanism is
retrieval-override rather than ambiguity — closer to F-1's "wall" in kill rate, but the wall here
is prior knowledge, not architecture.

---

### F-9. Cross-stage resolution drop — 6/10 runs (60%), one cause, ten tests

**Mechanism.** A normalisation (name resolution, defaulting, desugaring) is computed by the
stage that VALIDATES, which then returns the ORIGINAL object unchanged. The stage that EMITS
lives in a different subsystem and no longer has the context that produced the normalised form.
Every downstream capability breaks at once, because they all ride the same dropped value.

**Why it misdirects.** Nothing in any failure names the validating stage. In neva, 7 of the 10
failing tests panicked *inside unrelated stdlib runtime functions* (`fan_in: array port not
found by name: data`, `fan_out: port 'data' is not array`, `wait_all: array port not found by
name: sig`) and the other 3 hung to a 60-second timeout with empty stdout AND empty stderr. An
empty or unresolved port name never appears in a single message. The agent reads it as a
runtime-wiring bug and goes looking in the runtime.

**Evidence.** `neva-array-bypass-generalization`: **6 of 10 runs, all failing the identical
10-test block** — chained, fan_out, into_barrier, into_barrier_three, nested_levels, outport,
portless_port, receiver_anchored_fan_out, single_slot, slot_identity. The evaluator on Nova #1
names it exactly: *"analyzeArrayBypassConnection obtains resolvedSender and resolvedReceiver
but analyzeConnection returns the original conn"*. The agents did the resolution work and threw
the result away at the stage boundary.

**Precondition.** Two stages where one validates and one emits, AND the repo's existing code
resolves the same thing at the LATER stage for the ordinary path — so both placements look
equally reasonable. neva's `processSender`/`processReceiver` re-resolve at IR generation, while
the analyzer is where normalisation "obviously" belongs. Without that ambiguity the agent has
no reason to pick the wrong side.

**How to build.** Find a construct with an elidable form (an omittable name, an implicit
default, an inferred type). Require the elidable form in the contract — state it as parity
("a port name may be omitted wherever it may be omitted elsewhere") and never say WHERE to
resolve it. The trap fires when the agent resolves in the natural place and the emitter
discards it.

**Why it stacks.** This is not a standalone rule — it rides EVERY other capability at once.
Chains, fan-out and direction inversion all break together, which is how one root cause cost
10 of 21 tests. That is the interdependence property the calibration model demands, obtained
for free rather than by bolting on a second mechanism.

**Arsenal mapping.** HARDENING S6 (two evaluators of the same model).

---

### F-19. Shared-helper side effect on the output channel -- 36/52 runs (69%), the single most durable killer measured

**Mechanism.** A new command must emit STRUCTURED output (JSON, CSV, a machine-readable blob) on
a channel the repo already writes prose to. The natural implementation reuses the repo's existing
entry point for the underlying work -- which is the correct engineering call for everything except
the channel -- and that helper carries an incidental, unrelated side effect: an informational log
written to the same stdout. The agent's own serializer is correct. The bytes it produces are
correct. They are just no longer the first bytes on the channel.

**Why it misdirects.** The failure surfaces as a PARSE error at column 1 of stdout, in the test's
JSON deserializer -- not in any code the agent wrote. Nothing in the message names logging, the
reader, or the helper. The agent reads it as a serialization bug and audits the serializer, which
is fine. The defect is one call site away, in a dependency the agent chose correctly.

**Evidence.** `vrp-tsplib-edge-weight-types`, the same test across four batches:
**batch 9: 7/9 runs · batch 10: 17/23 · batch 11: 5/10 · batch 12 (accepted): 7/10** -- every
failure the IDENTICAL single test `can_get_tsplib_locations_via_cli_with_pure_json_stdout`. The
evaluators name the mechanism precisely and independently: *"the LocationWriter parses the problem
with the normal TSPLIB reader and inherits TextReader's logger that prints index-construction
messages to stdout"* (Nova #6); *"it reparses with the normal logging reader and emits a timing
message before the JSON"* (Nova #4). All ten runs marked `description_clear: true`,
`was_mentioned_in_description: true`, `agent_blame_unfair: false`.

**Precondition.** (a) the repo has a shared entry point for the underlying work whose logger or
writer targets a GLOBAL channel (a `println!` logger, a package-level writer, an ambient
`io.Writer`); (b) the same channel is where the new command's structured output must land; and
(c) reusing that entry point is the obviously-correct choice on every other axis, so the agent has
no reason to look for a quiet variant. Without (c) it is a hygiene bug, not a trap.

**How to build.** Contract-state the OUTPUT (`the command returns this JSON`), never the channel
discipline (`suppress the reader log`). Then assert it from a SUBPROCESS test that parses the
process's whole stdout, not from an in-process call to the serializer -- an in-process assertion
cannot see the contamination and the trap silently evaporates. Pair the subprocess test with an
in-process one on the same data so a failure localises to the channel rather than the content.

**Why it is durable.** It survived four batches, three fairness rounds, a Verify Solution round and
a full FP panel without ever being ruled unfair, and it never dropped below a 50% kill rate. It is
CONTRACT-STATED and FIX-HIDDEN in the strongest form the axiom allows: the contract is one short
clause, and knowing the clause does not tell you the fix, because the fix is in a dependency you
were right to pick.

**Arsenal mapping.** HARDENING S4 (machinery-riding integration).

---

### F-23. Repo-idiomatic wrapper narrows the stated input domain -- 6/10 on rocketpy-propellant-slosh, across two solver families

**Mechanism.** The prompt states a broad input contract ("a number or a callable receiving X").
The repo already owns a ubiquitous container for exactly that shape, and using it is the
idiomatic move everywhere else in the codebase. That container validates its input by
INTROSPECTION, and its notion of an acceptable callable is NARROWER than the sentence the prompt
wrote. Agents delegate contract enforcement to the repo class and inherit its narrower domain.

**Why it misdirects.** Three ways at once. The exception is raised from a base-repo file the
agent never edited, so it reads as "I called the repo class wrong", not "this class is the wrong
home for this contract". Using the repo's own abstraction is the instinct that is CORRECT
everywhere else and is what a reviewer would ask for. And the rejected inputs are ordinary
Python that any reader would call a callable receiving one argument -- nothing in the failure
suggests the domain boundary lives in someone else's `inspect.signature` call.

**Evidence.** `rocketpy-propellant-slosh`: **6 of 10 runs** (5 Nova + Orion), each failing the
IDENTICAL six cases and nothing else. RocketPy's `Function` infers domain dimensionality from
`signature(source).parameters`, counting a defaulted or keyword-only parameter as an extra
dimension, then rejects a one-name `inputs` declaration. Verbatim (Nova #7): *"a callable that
accepts the fill fraction plus optional/default parameters still satisfies the stated callable
contract ... The implementation's reliance on Function's raw parameter count prevents those valid
callables from being used."* Reproducible across batches: the same mechanism killed Orion in
batch 2 and again in batch 3, and Orion's decisive-commit profile reproduced the choice exactly.
All six judges marked it `was_mentioned_in_description: true` and volunteered a rebuttal of the
unfair reading; Auto Review Description scored 3/3 Clean over it twice.

**Precondition.** The repo has a pervasive "value or provider" container (`Function`, `Supplier`,
`Lazy`, `Expr`, a coercion helper) that does signature or type introspection, AND you can state a
contract sentence broader than what that container accepts. Grep the container for
`inspect.signature` / `__code__.co_argcount` / arity checks; the spellings it refuses are your
kill cells.

**How to build.** State the domain in the prompt in ORDINARY language ("a number or a callable
receiving the tank's fill fraction") and never name the container. Then parametrise over
spellings the WRAPPER distinguishes, not the ones a human distinguishes -- see L47. Confirm your
own reference does not delegate: if it wraps, you have authored a wall you cannot clear.

**Cost warning -- this axis is BINARY, not a tuning knob.** Every one of the six runs failed BOTH
killing cells, so dropping either cell alone flips nobody and dropping both flips all six at once:
measured counterfactual 0/10 -> 5/9 = 56%, above the ceiling. Budget it as a whole trap, and never
plan to soften it a little when a batch reads low.

**Arsenal mapping.** HARDENING A4 (host-language semantics) x S2 (composition of documented
rules). Pairs with F-10: the pattern tells you WHICH cross-product cells will kill.

---

### F-10. Capability cross-product cell ★ the near-miss decider

**Mechanism.** State N capabilities as independent axes. Agents build a case analysis per axis
and pass every single-axis test. The CELL where two axes intersect is never constructed. The
failure is frequently OVER-firing (duplicate emission) rather than a missing feature, because
both axes' code paths run.

**Why it misdirects.** The agent's own case analysis looks complete — it handled every
capability the prompt named. Duplicate output reads as a message-routing bug two subsystems
away, not as "you never built this combination."

**Evidence.** `neva-array-bypass-generalization`, `array_bypass_receiver_anchored_fan_out`:
axis 1 = which side carries the component's own port (sender-anchored vs receiver-anchored),
axis 2 = multiplicity (one receiver vs many). **8 of 10 kills, and the SOLE failure of both
near-miss runs** (Nova #4 and #9 passed 20 of 21 and printed `20\n20\n` instead of `20\n`).
Both had implemented each axis correctly in isolation. Arithmetically decisive: without this
one test the batch reads **4/10 = 40%, at the ceiling**; with it, **2/10 = 20%**. `go-workflows-channel-drain`: **4/10 runs** on the cell (parked `Drain` select-case) x
(unbuffered channel + nonblocking send) -- each axis worked alone; the intersection dropped the
value. It was the sole remaining failure of the 98/102 near-miss (Nova #8) after the F-20 pair.

**Precondition.** Any feature stated as "X must work for all forms of Y". Two axes is enough;
one of them wants multiplicity (fan-out, N receivers, repeated rounds) and the other wants
polarity (direction, which side is anchored, in vs out).

**How to build.** Write the axes as a literal matrix in `DESIGN.md` before writing tests. For
every pair of axes, ask whether one test exercises the intersection. Ship the off-diagonal, not
just the diagonal. Cost is near-zero: the test is ~20 lines and needs **no new description
words**, because a contract that already says "every form ... including fan-out" and "either
side may be the component's own port" covers the cell by composition — both evaluators marked
this failure `was_mentioned_in_description: true`.

`rocketpy-propellant-slosh` refines the axis choice: the cross-product was seven spellings of
"callable receiving the fill fraction" (plain function, lambda, `functools.partial`, callable
instance, defaulted parameter, `*args`, keyword-only parameter), and only TWO cells killed --
`defaulted` and `keyword_only`, 6/10 each. `partial`, the callable instance and `*args` killed
nothing, because the repo's wrapper accepts them. Enumerate the axis by what the IMPLEMENTATION
distinguishes, not by what looks varied to a reader (L47); four of the seven cells were pure
fairness insurance.

**Arsenal mapping.** HARDENING S2 (composition of documented rules).


### F-20. Sibling-API contamination — the new rule leaks onto the adjacent existing API ★ band decider on go-workflows (8/10)

**Mechanism.** Ship a NEW entry point that is a variant of an existing one (`SelectAll` beside
`Select`, `try_x` beside `x`, a batch form beside the single form) and give the new one a rule the
old one must NOT have. Agents factor the two onto a shared helper -- which is good engineering --
and the new rule silently applies to the old API. The old behaviour is documented but has no
repo test, so nothing they can run tells them.

**Why it misdirects.** Every new-feature test passes: the agent implemented the new rule
correctly, and that is what the prompt is about. The whole baseline suite passes too, because the
base repo never tested the old behaviour -- that absence is precisely why the seam is live. The
failure surfaces only in a test of the UNTOUCHED api, which reads like an unrelated regression
rather than a consequence of the refactor they just did.

**Evidence.** `go-workflows-channel-drain`: `SelectAll` defers every `Default` until no other case
was ready; ordinary `Select` must keep base's first-ready-in-argument-order scan, where
`defaultCase.Ready()` returns `true` unconditionally so an earlier `Default` wins. **8 of 10 runs**
applied the deferral to `Select`. Arithmetically decisive: the two 100/102 near-misses
(Nova #10, #11) failed **ONLY** this pair, so without it the batch reads **4/10 = 40%, at the
ceiling**; with it, **2/10 = 20%**. Evaluators graded these `FAIL_REGRESSION`, not
`FAIL_MISSED_REQUIREMENT` -- the only two regression verdicts in the batch.

Also `datafixerupper-derived-recursion`: base wraps every registered template in
`DSL.named(name, ...)`, so type identity carries the registered name; rebuilding the assembly path
dropped that wrapper and two structurally identical recursive types became indistinguishable to
`TypeRewriteRule.ifSame`, letting a fix aimed at one rewrite the other. **3 of 10 runs** failed
`a_fix_targeting_one_recursive_type_leaves_its_twin_alone`. No base test covered the wrapper --
the reference lost it too, and only a reviewer caught it. Generalises F-20 beyond sibling APIs:
ANY rewrite of an assembly path can drop untested behaviour the path was carrying.

**Precondition.** The repo has an existing public API whose behaviour is documented in prose
(README / guide / doc comment) but NOT covered by its own test suite, and your feature adds a
sibling that deliberately differs on one rule. Verify the gap: the base suite must pass with the
old behaviour broken.

**How to build.** Scope the new rule to the new API in ONE clause ("`SelectAll` handles ... every
`Default` fires only if none of the others were ready") and say nothing about the old one --
adding a "do not change `Select`" sentence would hand over the trap. Then write the guard as a
test of the OLD api in both directions: earlier-Default-wins (discriminating) AND
later-Default-loses (proves the rule is positional, not "Default always wins"). Costs **zero
description words**; the contract already scopes the rule by naming only the new API.

**Arsenal mapping.** HARDENING S2 (composition of documented rules) + F-12 family (repo-behaviour
preservation as a discriminating axis), but distinct from F-12: F-12 preserves existing repo
TESTS, F-20 preserves existing repo BEHAVIOUR that has no test -- which is why the agent's own
green baseline run cannot warn them.


### F-21. Type-check shortcut for an unobservable interface ★ top killer + near-miss decider on datafixerupper (5/10)

**Mechanism.** The contract asks the solution to classify the OUTCOME of an object it reaches
through a public interface that exposes no accessor for that outcome. The repo ships an abstract
base class implementing most of the interface, and that base holds the state in a field. Agents
downcast -- `if (x instanceof SomeBase<?,?>)` -- read the field, and branch on it. It works for every
builder the repo itself hands out, so their own smoke tests and most of the suite go green. It fails
for any CONFORMING implementation outside that hierarchy. The sound implementation never inspects the
object at all: it DECORATES the returned object and observes the outcome at the terminal operation,
where the value is finally produced.

**Why it misdirects.** The failing assertion is about a LIFECYCLE or a diagnostic, so it reads as a
lifecycle bug. Nothing in the message points at the type test. The agent has already written the
lifecycle rule correctly -- it just never runs, because the guard excluded the fixture's builder. And
the type check looks like defensive engineering rather than a shortcut, so it survives self-review.

**Evidence.** `datafixerupper-ordered-alternatives` batch 9: `MapCodec.encode` must normalise an
outright no-partial failure to `Lifecycle.stable()` on the builder it returns, "whatever
RecordBuilder the caller supplies". **Nova_4 and Nova_6 independently wrote the identical guard**,
`if (builder instanceof RecordBuilder.AbstractBuilder<?, ?>)`, and both failed only on
`PersistentRecordBuilder`, a conforming non-mutating helper outside that hierarchy. The single test
`mapCodecEncodeOutrightFailureNormalizesTheReturnedBuilderWhenBuilderDoesNotMutateInPlace` took
**5 of 10 runs** -- the most of any test in the batch -- and was the **SOLE** failure of the closest
near-miss (Nova_6, 172/173). Without it the batch reads 6/10 = 60%, over the ceiling.

**Precondition.** The repo has (a) a public interface, (b) an abstract base class in the same file or
package implementing most of it and holding the interesting state in a field, (c) NO getter on the
interface for the quantity your contract talks about, and (d) room to write a conforming
implementation outside the hierarchy as a ~30-line test helper. Verify (c) by grepping the interface
for a reader -- if one exists the pattern is dead, because the honest implementation is a one-liner.

**How to build.** Phrase the rule over the INTERFACE and add the four-word concessive clause
("whatever `X` the caller supplies"). Costs zero extra description words -- it is a scope marker on a
sentence you were writing anyway. Then write ONE fixture whose object is a conforming implementation
outside the base class. Keep every other fixture on the repo's own builder so the type check stays
invisible until that one test.

**Arsenal mapping.** Sibling of F-17 (proxy-metric drift): F-17 is the AUTHOR adopting a structural
proxy in a test helper; F-21 is the AGENT adopting a structural proxy in the solution. Also a
concrete instance of the F-10 cross-product idea, where the second axis is "implementation family of
a caller-supplied abstraction" rather than a feature flag.


### F-22. Joint fixed point across heterogeneous quantity kinds ★ top killer on customasm-derived-bank-layout (8 of 9 failing runs)

**Mechanism.** The new quantity must reach a fixed point TOGETHER with quantities of other kinds
that the resolver already owns - labels, constants, instruction sizes - whose values are refreshed
only by a full traversal. Agents build a settling pass for the NEW quantity alone, or convert a
guessed intermediate into a settled one too early, so a dependency chain that passes THROUGH one of
the other kinds never converges. Direct chains work; the mixed chain does not.

**Why it misdirects.** Every single-hop fixture passes, because one hop needs no fixed point. The
failure surfaces as a spurious `did not converge` on a program that is obviously valid, which reads
as an iteration-budget problem rather than a scheduling one, so the natural response is to raise the
budget instead of settling the kinds together.

**Evidence.** customasm-derived-bank-layout batch 5 (1/10): `ok_three_bank_chain` **5/10**,
`ok_forward_ref_into_derived_bank` **4/10**, `ok_chain_eight_reversed` 3/10,
`ok_chain_two_dozen_banks` 3/10, `ok_extent_shrinks_while_settling` 3/10,
`ok_chain_through_function_reversed` 2/10, `ok_chain_through_constants` 2/10,
`ok_derived_through_constant` 2/10, `ok_empty_bank_in_chain` 2/10. It was the sole cluster behind
BOTH near-misses (Nova 2 at 2 failures: `ok_forward_ref_into_derived_bank` +
`ok_three_bank_chain`). Evaluator wording, unprompted and repeated across runs: "dependencies do not
settle transitively", "guessed intermediate values are converted too early", "do not reliably
converge through later banks, constants, labels, and settling instruction sizes". Every failing run
was scored `was_mentioned_in_description: true` AND `was_inferable_from_codebase: true`, so the
cluster is difficulty, not ambiguity.

**Precondition.** A repo with an EXISTING iterate-to-fixed-point resolver over ≥2 quantity kinds,
where the pick adds a new kind that the other kinds can depend on and that can depend on them. Grep
for a loop like `while !stable` / `resolve_iteratively` plus a per-node "is this a guess" flag.

**How to build.** State that a field may depend on the other kinds while they are themselves still
settling - name the kinds, promise nothing about iteration counts (that promise is what produced an
FP; see the dossier). Then build the MIXED chains, not the direct ones: a chain through a user
function, a chain through a constant, and a forward reference into a not-yet-placed unit. A direct
A-to-B chain discriminates nothing.

**Arsenal mapping.** S4 machinery-riding, and the interdependence cousin of F-9: one root cause
breaks every capability that routes through the other kinds, so stacking comes free.

---

### F-24. Absent-key sentinel replaces an existing hard failure ★ top killer on datafixerupper-derived-recursion, 8/10 in TWO independent batches

**Mechanism.** The feature adds an ANALYSIS PASS over a namespace the caller populates -- a
reference graph, a dependency order, a reachability closure. Some names in that namespace will not
resolve. An analysis pass wants to be a TOTAL function, so agents invent a sentinel to keep it
total: `UnknownType`, `MissingRef`, `Unresolved`. The sentinel is then carried into the
CONSTRUCTION path, and a lookup that previously threw now returns a usable object. The feature
works; an existing hard failure has quietly become a soft success.

**Why it misdirects.** Nothing in the feature is wrong -- the graph, the grouping and the ordering
are all correct, which is why these runs land at 85/87. The sentinel reads as good engineering:
the analysis must not crash on a partial graph, and a sentinel is the textbook way to say so. The
base suite passes because the repo never tested its own throw. And the failing assertion is about
an UNREGISTERED name, which reads as an edge case of the new feature rather than as a regression
of the old lookup.

**Evidence.** `datafixerupper-derived-recursion`: `Schema.resolveTemplate` throws
`IllegalArgumentException("Unknown type: " + name)` on base; the new derivation must keep that and
NOT treat an unregistered name as "a type with no value". **8 of 10 runs in batch 1 (79 tests) and
8 of 10 again in batch 2 (87 tests)** introduced a synthetic `UnknownType` and failed exactly
`unregistered_reference_still_reports_an_unknown_type` and
`a_required_reference_to_an_unregistered_name_reports_an_unknown_type`. **Four of those runs failed
ONLY that pair** at 85/87. Every evaluator recorded BOTH `was_mentioned_in_description: true` AND
`was_inferable_from_codebase_excluding_tests: true` -- the trap survived being doubly telegraphed.

**Precondition.** The repo has a lookup that throws on a missing key, that throw is NOT covered by
its own tests, and your feature adds a pass that must traverse the same namespace before every key
is known. Verify the gap the F-20 way: break the throw and confirm the base suite still passes.

**How to build.** One clause that names the distinction in the feature's own vocabulary and
nothing else -- "a reference to a name that was never registered stays an unknown type rather than
a type without a value". Do not say "keep throwing" and do not name the exception; the sentence has
to describe the SEMANTIC difference, which is what agents are about to erase. Then two tests: the
bare unregistered reference, and one where the unregistered name sits under a REQUIRED field, so a
sentinel that happens to be uninhabited is separated from one that is merely unknown.

**Arsenal mapping.** F-20 family (existing repo BEHAVIOUR with no repo test), but the inverse
direction: F-20 leaks a NEW rule onto an old API, F-24 deletes an OLD failure to make a new
analysis total. Pairs with any graph/closure feature for free -- the pass you are already asking
for is what creates the pressure.


### F-25. Placeholder validity window narrower than the caller's ★ 4/10 + 4/10 on datafixerupper-derived-recursion

**Mechanism.** The feature cannot resolve references at the moment they are written, because the
graph is not known until registration finishes, so both you and the agents introduce a deferred
PLACEHOLDER. The natural implementation scopes the placeholder to the pass that creates it -- a
`collecting` boolean, a "only valid during analysis" guard, a phase enum. But the placeholder is
handed to CALLER code through a public API, and callers keep values: they assign
`TypeTemplate ref = schema.id("a")` and reuse it in a later registration, or memoize the supplier
that produced it. Outside the window the placeholder either throws, or -- worse -- resolves against
whatever the phase variable happens to hold, silently binding to the wrong scope.

**Why it misdirects.** Every test that builds its templates inside a fresh lambda passes, and that
is how the repo's own schemas and almost every test are written. The failure needs a caller who
retains a value across the phase boundary, which looks like an unusual style rather than the
supported use of a public `Supplier`-based API. When it fails by mis-resolution rather than by
throwing, the symptom is a recursion point bound to the wrong family, several layers away from the
placeholder.

**Evidence.** `datafixerupper-derived-recursion` batch 2: `a_reference_assembled_during_registration_still_builds`
took **4 of 10** and `a_reference_retained_from_registration_stays_inside_its_group` took **4 of 10**
(the same four runs plus overlap). Evaluator on Nova_6: "SchemaReference.hmap and applyO explicitly
throw after construction"; on Nova_2: "Schema.id() calls getTemplate(name) for an already-registered
name before materialization". The reference had BOTH bugs in turn -- first an NPE when `id` was
called during `registerTypes`, then same-group references resolving as external once the family
unfolded lazily -- and neither was fixed until a reviewer named it.

**Precondition.** The feature forces deferred resolution, AND the thing being deferred is returned
through a public API the caller can store. If the placeholder never escapes your own pass, the
pattern is dead.

**How to build.** Do not say anything about placeholders -- the contract is just the feature. Write
two tests: one where the caller assigns the reference to a local and reuses it in a LATER
registration (acyclic, so it only tests the lifetime), and one where the retained reference closes
a CYCLE, so a wrong-scope resolution shows up as a broken family rather than as an exception. Take
the reference AFTER its target is registered; demanding a lookup of a not-yet-registered name is a
different, unstated requirement and will be read as unfair.

**Arsenal mapping.** HARDENING S2 (composition of documented rules) -- the trap lives in the seam
between the API's lifetime and the implementation's phases, and costs zero description words.


### F-11. Local-vs-global selection scope ★ the band decider on customasm (9/10)

**Mechanism.** A recursive decision procedure must choose each sub-part by a metric scoped to
THAT sub-part, then roll the result up. Agents instead maximise the metric over the WHOLE
explanation, letting a later sibling's score pay for an earlier sibling's worse local choice. Both
readings satisfy every single-field test; only a case with TWO consecutive variable sub-parts, each
with its own competing candidates, separates them.

**Why it misdirects.** Global maximisation looks strictly better - it is the more "optimal" answer,
and it passes every fixture that has one nested field. Nothing in the failure points at scope; the
output is a fully valid alternative parse, so it reads as a tie-breaking preference rather than a
rule violation.

**Evidence.** customasm-ruledef-disassembly: `ok_nested_local_specificity` killed **9 of 10** runs
and was the SOLE failure of all five near-miss runs (Nova 1, Orion 1, Orion 3) or one of two
(Nova 2, Nova 4). Bytes `0xF1ABCE` under `op {a: first} {b: second} => 0xf @ a @ b @ 0xe`: field a's
own candidates are `short` (4 fixed bits) and `long` (0), so local scoring picks `short` and the
answer is `op short any 0xabc`; global scoring picks `long` because field b's `fixed` contributes 8,
giving `op long 0x1a fixed`. The pattern was ALSO the sole finding of an FP-panel dissent before the
batch - it was found by a judge, not by the author.

**Precondition.** A recursive matcher/parser/decoder where a rule contains two or more
variable-extent sub-parts in sequence, each resolvable several ways, and a documented preference
metric (specificity, cost, length, priority).

**How to build.** State the metric and state that a sub-part is chosen by it "from its own
<span> and nothing past it", never "locally". Then build ONE fixture with two consecutive variable
sub-parts whose local and global optima disagree. Do not bother adding more single-sub-part
fixtures - they cannot discriminate.

**Arsenal mapping.** Adjacent to A7 (determination-channel seams); the shared shape is that the
correct answer is decided at a narrower scope than the obvious implementation uses.

---

### F-12. Repo-test preservation as a discriminating axis — 3/10 runs (30%), the half of the band nobody authors

**Mechanism.** The file the task forces the agent to rewrite contains an INLINE test module whose
tests call a PRIVATE helper of that file. Any restructuring that renames or absorbs the helper
orphans the tests, and the only way to a compiling crate is to delete them. The platform grades
pass-to-pass by test IDENTITY, so the deletion reads as a regression no matter how good the
feature work is.

**Why it misdirects.** Nothing in the prompt says the private symbol is load-bearing, and the
agent's own `cargo test` goes GREEN once the stale tests are gone — deleting them is what makes
the local signal healthy. The failure is invisible until the platform compares test IDs.

**Evidence.** `numbat-parse-unit-expressions` round 9: **3 of 10 runs passed all 88 feature tests
and still failed, on baseline alone** (Nova_2 5 baseline failures, Nova_5 6, Nova_8 12). Removing
that axis would have produced **5/10 = 50%, a too-easy reject**; with it the batch read
**2/10 = 20%, in band**. The same axis appeared in rounds 3, 7 and 8 (7 of 8 agents across two
rounds deleted the module). Both agents that finally passed had DELETED the two obsolete tests
and updated the rest — the discrimination is between deleting the whole module and surgically
revising it.

**Precondition.** A single implementation file that (a) the feature forces you to rewrite,
(b) carries `#[cfg(test)] mod tests`, and (c) whose tests call a private fn of that same file.
Rust repos with inline test modules are full of these; languages with out-of-tree tests are not.

**How to build.** You do NOT build it — you decide whether to keep it. Keep the inline module in
base mode, skipping ONLY the tests the feature genuinely invalidates. Do not skip the module
wholesale (it removes the axis AND draws a High review finding), and do not try to relocate the
tests: a test-only patch may not touch `src/`, and a solution-side deletion makes your own
reference fail the p2p check.

**Cost warning.** This axis is invisible in your own validation — the reference always preserves
its own tests. It only shows up in a batch, and it can be worth half the band.

**Arsenal mapping.** Not an authored trap; an environmental axis. Closest relative is HARDENING
S5 (baseline preservation through a shared chokepoint).

---

### F-13. Discard-unit granularity ★ top killer on rust-minidump (6/10)

**Mechanism.** The contract says a malformed/contradictory THING is discarded. The format defines
that THING as a composite (a record = a header plus its later delta rows), but the agent meets the
contradiction while parsing ONE row, and discards at the granularity it happens to be holding: it
drops that row's contribution and keeps the enclosing record live. Every fixture whose
contradiction sits in the header separates nothing, because there the row and the record coincide.

**Why it misdirects.** Local discard is the more conservative, more "graceful" reading — throwing
away one bad line rather than a whole record looks like better error recovery, and it keeps more
information. The failure surfaces far away, as an unwind that produced too few frames, never as a
parse complaint. Agents that get it wrong are otherwise complete: on rust-minidump the three runs
whose SOLE failure was this pattern each passed 48 of 49.

**Evidence.** rust-minidump-stack-containment: `a_delta_row_that_declares_and_computes_is_discarded`
killed **6 of 10** runs and was the ONLY failure of three of them (Nova 2, 5, 8). Evaluator, Nova 8:
"walker.rs parses each additional line into line_exprs and simply omits exprs.extend(line_exprs)
when that line conflicts, leaving the INIT rules active." Nova 5: "handles
`Err(CfiParseError::Contradictory) => {}` for an additional rule, preserving the previously parsed
expressions." The INIT-row twin of the same test
(`a_record_that_declares_and_computes_in_one_row_is_discarded`) killed **zero** — where the
contradiction is in the header, both readings agree.

**Precondition.** A text/binary format the repo already parses in two tiers: a base declaration
plus incremental amendments that override fields of it (Breakpad `STACK CFI INIT` + `STACK CFI`,
diff/patch hunks, cascading config layers, `@media` overrides). Plus a validity rule that can be
violated by an amendment alone.

**How to build.** Write the invalidation rule using the FORMAT's own noun ("record"), and put the
contradiction in an AMENDMENT row, not the header. Assert the downstream consequence (fallback
behaviour ran, N frames present), never a parse error code. Ship the header-row twin too — it costs
nothing and is the fairness proof that the rule is about contradiction, not about row position.

**Arsenal mapping.** S4 machinery-riding — it rides the repo's existing amendment semantics, and
the wrong answer is the one that respects the amendment layer instead of the record layer.

---

### F-14. Declared-vs-derived terminal state — 3/10 on rust-minidump

**Mechanism.** The feature adds a terminal state whose meaning is *someone asserted this*
(a symbol file declaring "no caller here"). The existing code already has many places that decide
*we cannot continue* — null pointer, non-advancing stack, exhausted candidates. Agents wire the new
state to all of them, because those sites are exactly where "the walk is over" is already known.
The distinction is PROVENANCE, not condition: same observable stop, two different reasons.

**Why it misdirects.** The existing giving-up sites are the obvious, discoverable attachment
points — grep for where the unwinder returns "no frame" and they are all right there. Wiring them
up makes the declared-end tests pass. Only a fixture that reaches an ORDINARY end and asserts the
plain terminal state separates the two, and that test looks like a trivial happy-path check.

**Evidence.** rust-minidump-stack-containment: three runs (Nova 1, 3, 7) conflated them.
Evaluator, Nova 7: "minidump-unwind/src/{x86,amd64,arm,arm64,arm64_old,mips}.rs change normal
nullish/backwards guards from returning no frame to returning WalkTermination::EndOfStack."
Nova 1 compounded it: "CallStack::print and process_state.rs match Exhausted | EndOfStack and omit
both" — having merged the states, the conditional-output rule merged with them. The killers were
`contained_walk_degrades_nothing_and_exhausts` (3) and
`a_declared_end_outranks_a_frame_a_later_strategy_would_produce` (3).

**Precondition.** A subsystem with several existing "cannot continue" exits, plus a new
externally-declared reason to stop. Any interpreter/walker/resolver with both failure exits and a
data-driven halt.

**How to build.** Name both states in the contract and give the ordinary one a fixture that
asserts it POSITIVELY on a clean run. State the output rule in terms of the ordinary state ("a walk
that ended plainly carries neither"), so a merged implementation breaks output as well as
termination — that coupling is what turns 1 failing test into 6.

**Arsenal mapping.** A7 determination-channel seam; the answer must survive being computed at a
different place from where the obvious sites live.

---

### F-15. Arming condition mistaken for firing condition — 4/10 on rust-minidump

**Mechanism.** A stop rule is stated in terms of the event that must NOT happen ("stop before
recording a SECOND degraded frame"). The first degraded frame is what makes the rule live, so
agents treat detection as the trigger and stop there. Both readings agree on every fixture that
has only one degraded frame — which is most of them, because one is the natural fixture.

**Why it misdirects.** Stopping at the first anomaly is the defensive reading and it is what the
surrounding code usually does. It also passes the headline test (the walk did stop, the frame was
marked), and it only shows up in the aggregate counts and the not-truncated status.

**Evidence.** rust-minidump-stack-containment: four runs (Nova 3, 4, 7, 10). Evaluator, Nova 4:
"the first out-of-region frame is pushed and then pending_termination is set to
LeftStackRegion, which is consumed at the next loop iteration." The killer was
`degradation_is_summarised_over_the_whole_walk` (4 kills), which asserts the walk stayed `Ok` and
kept its full frame list after ONE reduction — not the second-frame test itself
(`a_second_reduced_frame_ends_the_walk`, 0 kills).

**★ The discriminating test is the ONE-event case, not the two-event case.** The two-event fixture
passes under both readings. Author the single-event fixture and assert the walk continued normally.

**Precondition.** Any "stop after the Nth" / "allow one, reject the second" tolerance rule.

**Arsenal mapping.** A8 polarity/boundary inversion, with the twist that the boundary test people
naturally write (N=2) is the one that cannot discriminate.

---

### F-16. Unparameterised-setter inference gap — 4/10 on lyon-fill-internal-vertices, ALL as INTEGRATION_ERROR

**Mechanism.** The contract names a public boolean option field plus a `with_*` builder that "sets
it", without naming the builder's PARAMETER. Agents converge on a zero-argument, enable-only method
(`with_x(mut self) -> Self`) instead of the repo's boolean setter shape
(`with_x(mut self, v: bool) -> Self`). The hidden test crate then fails to COMPILE, so the entire
suite goes red at once.

**Why it misdirects.** "Turn the behavior on" / "sets it" reads as an imperative enabler, and a
zero-arg builder is the more elegant API in isolation. Nothing in the failing output points at the
description: the agent sees `error[E0061]: this method takes 0 arguments but 1 argument was
supplied` in a test file it never wrote and cannot read.

**Evidence.** lyon-fill-internal-vertices batch 3: 4 of 10 runs emitted
`pub const fn with_interior_vertex_elimination(mut self)` and died with E0061 on all 45 tests
(FAIL_INTEGRATION_ERROR, 0/45). The single passing run emitted
`pub const fn with_interior_vertex_elimination(mut self, eliminate: bool)`. Auto Review ruled it
FAIR because the repo's own `with_intersections(mut self, intersections: bool)` establishes the
convention.

**Precondition.** The repo already has >=1 boolean `with_*` setter on the same options struct (so
the shape is inferable and the wall is fair), AND your description phrases the new builder as an
action rather than naming its argument.

**How to build.** Name the field and the builder; describe the builder as setting the field. Do NOT
write "that takes a boolean". Verify the repo convention exists first — without it this is an
ambiguity, not a trap.

**★ CAUTION — this is the most fragile pattern in the catalogue.** It is a COMPILE error, not a
behavioral discriminator: it kills whole runs without measuring any understanding of the feature,
and a different reviewer could read it as under-specification. Treat it as a bonus that appears when
you write concise API prose, never as the lead trap. On this problem it was created ACCIDENTALLY by
taking a description reviewer's concision trim (see L26).

**Arsenal mapping:** A-tier, adjacent to A4 (host-language semantics) — the repo demonstrates the
correct pattern in its own source.

---

### F-17. Proxy-metric drift — the test helper measures a PROXY, not the contract's property ★ top killer on lyon (8/10)

**Mechanism.** The contract states a property in one vocabulary (geometric: "the filled region
covers a full neighborhood around it") while the test helper computes a cheaper structural PROXY
(topological: "has no unpaired boundary edge"). The two agree on every simple fixture and diverge on
degenerate/non-manifold configurations. An implementation that satisfies the proxy but violates the
stated property passes the whole suite.

**Why it misdirects.** The proxy is usually the natural way to compute the check, so author and
agent adopt the SAME wrong abstraction — the suite cannot see the gap because the suite IS the gap.
It surfaces only when an adversarial panel probes the stated property directly.

**Evidence.** lyon-fill-internal-vertices: batch 2 FP panel voided a pass because the candidate's
`is_interior` required a closed MANIFOLD one-ring, leaving a vertex at (5,3) strictly inside a
rectangle by a 2-unit margin — "the hidden verifier's `interior_vertex_count()` proxy is topological
and cannot detect a geometrically-interior non-manifold vertex". Replacing the proxy with a direct
geometric check (sample 16 directions at a small radius against the base mesh) made
`no_emitted_vertex_has_a_fully_filled_neighborhood` the **top killer of batch 3 at 8/10, and the
SOLE failure of both near-miss runs**.

**Precondition.** The contract's property is stated in a vocabulary your helper does not compute
directly — geometric vs topological, semantic vs syntactic, value vs identity.

**How to build.** Write the helper in the CONTRACT's vocabulary even when a cheaper structural proxy
exists. If you must use a proxy, add one test that checks the stated property directly on a
configuration where proxy and property provably diverge. Verify the direct check reports ZERO false
hits against your own reference before shipping it.

**Arsenal mapping:** S2 (composition of documented rules) — the divergence lives where two stated
properties meet.

---

### F-18. Token-form parity gap — one rule, two lexical spellings ★ decided the band on gluon (7/11)

**Mechanism.** The domain has two lexical forms of the SAME concept, and the contract states the
rule once, for the concept. Agents implement the salient form everywhere and the other form only at
the position where they first met it. Nothing in the contract looks incomplete, because it is not:
the gap is in the implementation's case analysis, not in the prose.

**Why it misdirects.** The agent has already written the rule and watched it pass, for the form it
was thinking about. The failing case looks like a layout or placement bug in a construct it
believes it handled, so the fix it reaches for is more placement logic rather than a second lexer
branch.

**Evidence.** `gluon-format-comments` accepted batch, 1 pass of 11. Block-comment cases took **22 of
the 37 total kills**: `a_same_line_block_comment_breaks_a_record_that_would_otherwise_fit` **7/11**,
`a_block_comment_after_a_record_field_stays_on_its_line` 6/11,
`a_trailing_block_comment_and_an_own_line_comment_in_one_gap_keep_their_order` 5/11,
block-comment-in-nested-match 2/11, same-line-block-on-a-let-binding 2/11. The 7/11 case was the
SOLE failure of the closest near-miss. Their line-comment twins at the identical positions killed
0-1 each: `trailing_comment_on_last_record_field` 0, `own_line_comment_before_closing_brace` 0,
`trailing_comment_on_a_let_binding` 0. Same rule, same positions, different lexical form, and all
the difficulty sat in the form nobody was thinking about.

**Precondition.** Two or more spellings of one concept that the contract treats as equivalent: line
vs block comments, short vs long option flags, single vs triple-quoted strings, `.0`/`.field` tuple
access, prefix vs infix call syntax.

**How to build.** State the rule for the CONCEPT and add one flat sentence that the forms are
equivalent ("Both comment forms behave this way"), never a per-form enumeration. Then test the
non-salient form at every position where you test the salient one. Cost is one test per position
and ZERO description words, because the equivalence sentence already covers them.

**Cost warning.** Parity tests are individually cheap and collectively decisive, which makes them
easy to under-author and easy to over-author. Check the kill table afterwards: on gluon the parity
cases carried the band while 15 of 37 tests killed nothing at all.

**Arsenal mapping.** F-3's lexical sibling. F-3 is one rule across two collections; this is one rule
across two spellings.

---

## 2. PROBLEM DOSSIERS

### calyx-unused-port-elimination (Rust / Calyx HDL compiler) — ACCEPTED

| | |
|---|---|
| Shape | Whole-program dataflow pass, cross-subsystem (frontend attribute + IR + analysis + pass + registration) |
| Final artifact | 7 source files, ~925 effective LOC (Counter 2), 105 tests |
| Pass-rate history | runs6 1/10 · runs7 1/10 · runs9 2/10 · runs11 1/10 · runs12 1/10 · runs13 4/10 |
| Patterns used | F-2 (lead), F-3, F-4, F-5 |
| Agent split | Orion 3/3 on the final artifact; Nova 3/27 (11%) |

**Why it held.** The feature is *globally coupled* — correctness is a fixed point over the whole
program, so no local fix converges. Passing solutions ran 1648-2386 added lines across 11-16
files; the task cannot be shortcut.

**What the batches taught.**
- **Failure diversity is the health signal.** runs13's six failures had six distinct root causes.
  A single test sinking everyone means unfair; a spread means genuinely hard.
- **Agent capability moves under you.** Nova went 0/18 across two batches to 3/9 overnight on a
  *strictly harder* artifact (one test added). The problem did not get easier. Read pass rates
  as a moving target and ship at the low edge of the band, never the middle.
- **Orion is the load-bearing solver.** 3/3 versus Nova's 3/27. A batch with no Orion would
  likely have read 0/10. Per HARDENING's AGENT-MIX law, only the standard mix is the oracle.

**Reviewer-round cost pattern.** Findings per round went 4 → 2 → 5 → 10 → 1. The spike was
self-inflicted: the v5 `@go` fix generated 4 of the 10 v6 findings. The recurring authoring
error, three times over: **an absolute sentence in the meta plus an implementation carrying an
unstated exception** (`1'b1` radix, the `@go` blanket veto, the ref post-pruning rule). Every
time, the reviewer read the text literally and the text won. State a rule's exceptions in the
same sentence that states the rule.

---

### pulldown-cmark-gfm-autolinks (Rust / markdown parser) — ACCEPTED

| | |
|---|---|
| Shape | Opt-in inline-parser extension behind an `Options` bit |
| Final artifact | ~350 C1 / ~265 C2 effective LOC, 61 tests |
| Pass-rate history | 8/12 = 67% (too easy) → **F-1 architecture wall** → 4/10 = 40% (in band) |
| Patterns used | F-1 (lead), F-6, F-7 |

**Why it was too easy at first.** The meta enumerated every rule (boundary chars, three forms,
domain validity, trailing-trim set) and each rule is *independently implementable*. That is a
pointwise-decoupled feature, which HARDENING lists as DEAD — and the enumeration made the meta a
checklist. The four failures were scattered singletons with no dominant trap, the textbook
"separable domain" signal that trap-stacking will not help.

**What fixed it.** Not more rules — one architectural wall (F-1). This is the single most
transferable result in this file: **when a batch is too easy and failures are scattered, do not
add traps. Find what the convergent architecture cannot do.**

**Fairness attrition — four tests removed across rounds.** Each pinned behaviour the meta did
not document:
- `backslash_escaped_punctuation_is_part_of_the_url` — relied on CommonMark backslash normalisation
- `interior_html_entity_is_part_of_the_url` — relied on entity normalisation
- `code_span_nested_in_emphasis` and its replacement — pinned an ambiguous `*` placement

The final replacement is the model: assert only the two UNAMBIGUOUS properties (the URL
autolinks; the nested link still renders) without pinning the exact stop point. **A test that
pins where an ambiguity resolves is unfair even when your reference is right.**

**Three reference bugs found by the hardening process**, all in the author's own solution:
`autolink_in_link` bool → depth counter; `consume_inline_construct` flattening nested code/links;
`scan_email` trimming `-` before validation. calyx produced a comparable count. Budget for this:
**hardening finds your bugs, not just theirs**, and every one would have been an FP.

---

### lyon-arcs-join (Rust / 2D stroke tessellator) — submission-ready

| | |
|---|---|
| Shape | New `LineJoin::Arcs` variant + 3 standalone public functions, cross-cutting fixed-width and variable-width stroking dispatch |
| Final artifact | ~201 effective LOC (Counter 2, solution unchanged since), 54 tests (grew from 46 across review rounds; solution.patch never needed a fix — every round after the first was pure test-coverage strengthening) |
| Pass-rate history | 1 batch: **1/10 = 10%** (Nova), measured BEFORE the meta.md wording named the exact construction; unmeasured after disclosure (see below) — treat as stale |
| Patterns used | F-8 (original lever) + one added post-disclosure orthogonal trap (concave-side curvature-vs-half-width overshoot, independent numeric edge case, not geometry-formula-dependent) |
| Agent split | 9/10 Nova failed identically pre-disclosure; the 1 pass matched the literal contract |

**Why it held.** The task's name ("arcs join", explicitly citing "the way SVG2's arcs join
does" in the meta for orientation) points straight at a real, famous, well-documented
construction — but the repo's actual required geometry is a deliberate divergence (shared
join-centred radius, not two offset osculating circles). 9 agents retrieved the famous version
from pretraining and built it with full confidence, including inventing a plausible-looking but
wrong miter-limit formula to match. This is F-8 in its purest form: a single documented
contrast sentence, no multi-step design wall, no second subsystem required, killed 90% of a
batch on its own.

**What the batch taught.**
* **A single comprehension-override lever can already land deep in-band alone.** No F-1-style
  architecture wall or F-2-style fixed point was needed — the named-algorithm trap did the
  entire job. This is notably cheaper to author than F-1/F-2 (no multi-stage pipeline
  requirement) but the tradeoff is real: it depends entirely on the repo bordering a famous
  external concept, which is a much narrower precondition to find than "has a pipeline."
* **Correlated secondary tell.** All 9 failing agents also skipped the repo's own existing
  `miter_limit_is_exceeded` helper in favour of reinventing the threshold — once an agent
  commits to an external mental model, it stops looking at the local codebase's established
  conventions too, which is itself a free, no-cost secondary discriminator worth testing for.
* **This lever is fragile to smart solvers.** Only one Nova run in this batch got it right by
  simply reading carefully; an Orion/Vega-heavy batch could plausibly clear this in one pass
  more often, since the "fix" is a single reading-comprehension act, not a multi-step build.
  Treat F-8 as a strong OPENER trap, not a standalone submission-safe design — pair it with an
  orthogonal integration trap (here: the dual fixed/variable-width dispatch sites, and the
  standalone-predictor/tessellator sign-consistency check) so a smart single-pass agent that
  gets the geometry right can still miss a second, independent requirement.
* **F-8 is ALSO fragile to fairness review, not just smart solvers — and this is the more
  dangerous fragility of the two.** Late in this problem's review cycle, a fairness check
  demanded an independent oracle test to close a coverage gap (T3/T4: asymmetric-corner
  direction was only checked via helper/tessellator self-consistency). Any oracle strong enough
  to independently confirm the RIGHT curvature construction is, definitionally, strong enough to
  also PIN that construction as canonical — which is exactly the information F-8 depends on
  withholding. Two rounds of attempting to word around this (excluding only the specific
  alternative construction a reviewer cited by name) failed: the reviewer simply cited a
  DIFFERENT plausible alternative each time ("tangent bisector" round one, "quadratic
  interpolation or another discrete-curvature estimator" round two). An under-specified
  "curvature-following direction" claim has no finite set of alternatives you can rule out one
  at a time — closing the fairness gap for real required naming the exact construction in the
  meta, which almost certainly collapses the measured 90% kill rate in any future batch. **A
  named-algorithm-override trap and an independent-oracle test covering the SAME behavior are
  close to mutually exclusive** — authoring both into one submission is very likely a
  self-defeating design, not a stackable pair. Decide up front which one the submission actually
  needs: the trap (accept the T3/T4-shaped coverage gap as a documented, honest limitation) or
  the oracle (accept that the disclosure needed to make it fair will likely neutralize the trap).
* **A numeric bound in a fairness-driven test needs to be either fully justified or fully
  eliminated — a smaller magic number is not a fix.** The branch-cut regression test went through
  three shapes: exact point-count equality (unfair — pins a subdivision strategy), a `2x`
  point-count ceiling (STILL unfair — reviewer's objection generalized to "any unstated numeric
  implementation constant", not the specific multiplier), then a genuinely constant-free rewrite:
  sum unsigned per-step angles (`acos(dot(unit vectors))`, immune to the atan2 branch cut since
  consecutive points are always closely spaced) and compare against the independently computed
  direct sweep through the already-established start/peak/end landmarks, using the same method.
  Verified numerically before committing: fixed code differs from the direct sweep by ~2.6e-6
  radians (float noise); the reverted bug differs by ~4.93 radians — six orders of magnitude
  apart, cleanly separated by a pure discretization epsilon (`0.01`) rather than a tunable
  implementation-quality choice. **Weakening a threshold buys one review round, not durability —
  if a reviewer's objection is "this constant is unstated," the fix is removing the need for a
  constant, not picking a smaller one.**
* **Post-disclosure, a second independent trap held up under full adversarial review (a 3-judge
  FP panel plus Auto Review) without needing to touch meta.md.** Added
  `arcs_join_position`'s existing `offset_radius <= 0.0 -> None` guard as a new orthogonal trap:
  the tessellator's own rendered (convex) side can never trigger it, so it is only reachable
  through the standalone helpers on the concave side of a corner whose curvature radius is
  smaller than `half_width`. This is a genuinely separate numeric edge case (curvature radius vs.
  stroke half-width) from "which construction to use for direction," so it survives even after
  the geometry formula was disclosed. **Distinct traps must be measured on distinct axes — a
  trap that shares its axis with a disclosed/weakened trap dies with it; one on an orthogonal
  axis does not.**
* **False-positive review can surface real coverage gaps even when the reference solution has no
  bug.** A 3-judge FP panel caught that a REVIEWED CANDIDATE's solution added
  `!miter_limit.is_finite() -> None`, forcing Bevel for an infinite `miter_limit` even though
  the repo's own public API (`StrokeOptions::with_miter_limit`) accepts `INFINITY` and the
  existing `miter_limit_is_exceeded` check can never trigger for it. The reference solution was
  verified to NOT have this bug (probe: infinite and `1e6` produce identical output). The actual
  gap was that the hidden test suite never exercised this input, so a wrong candidate passed
  anyway. **The lesson generalizes beyond this problem: a false-positive is not always "the
  reference is buggy" — it can be "an accepted edge case of an existing public API was never
  tested," which is a pure test-completeness gap, fixable without touching the solution.** Auto
  Review separately caught a genuine T3/T4 hole in the SAME batch: a tessellator-level tolerance
  test only checked non-decreasing triangle count plus peak proximity, which a solver that always
  emits a fixed 2-segment peak-fan (ignoring `StrokeOptions::tolerance` entirely) could satisfy,
  since the peak is one of that fan's own endpoints regardless of tolerance. Verified by forcing
  0 subdivisions in the tessellator and measuring an interior arc point's distance from the mesh
  boundary: 0.222 (mutant) vs. 0.00145 (real) — confirmed the gap was real before writing the
  fix, not assumed from the review's wording alone.

---

### neva-array-bypass-generalization (Go / dataflow-language compiler + runtime) — ACCEPTED

| | |
|---|---|
| Shape | O-Composite-add: generalise one connection form across analyzer, desugarer, IR generation, runtime and stdlib |
| Final artifact | 6 source files / 4 subsystems, 282 effective LOC (Counter 2), 21 e2e tests |
| Pass-rate history | 1 batch: **2/10 = 20%** (Nova 1/9, Orion 1/1). Two more at 20/21 |
| Patterns used | **F-9** (lead, 6/10) + **F-10** (decider, 8/10 incl. both near-misses) |
| Agent split | Orion 1/1 · Nova 1/9 (11%) — the calyx result again |
| Long-horizon | passing patches 610-693 added lines across 15-19 files; even failures ran 14-16 files and 5.9-14M prompt tokens |

**Why it held.** Two traps on genuinely different axes. F-9 is a *stage-boundary* failure that
breaks everything at once (one root cause, 10 tests); F-10 is a *composition cell* that breaks
exactly one thing for an agent who got everything else right. The first sets the floor, the
second decides the band. Neither is a rule you can transcribe from the prompt.

**What the batch taught.**

* **The deliberate second wall killed nobody.** Three hardening rounds went into a `sync.WaitAll`
  array-inport barrier — a new runtime func, a stdlib component, 4 tests — justified by mutation
  evidence (it took mutation V10 from 0/12 to 2/15). **All 4 `wait_all_*` tests passed in all 10
  runs.** No agent ever wrote the mutation the barrier was built to catch. See L15.
* **The last hardening round also killed nobody.** `slot_identity` (added round 8, specifically to
  make slot permutation observable) killed 6 runs — but always co-occurring with the F-9 block,
  never independently. It changed no outcome. `slot_identity_outport` killed zero.
* **The decisive test came from a reviewer, not from the trap design.** `receiver_anchored_
  fan_out` was added in round 5 to satisfy a Test Fairness *coverage suggestion*. It became the
  single test separating a 20% batch from a 40% one. See L17.
* **6 of 8 failures shared one root cause and it was still fair.** By L4 that reads as unfair.
  It survived because the wall was *reachable*: 2 agents cleared it, 2 more got 20/21, every
  evaluator recorded `description_clear: true` and `difficulty: challenging`, and the FP panel
  was clean. See L18.
* **11 of 21 tests never killed anything.** They are not waste — they carry fairness and FP
  insurance, and the FP panel explicitly credited the contract for not over-constraining
  architecture (the passing agents used different ones). But hardening effort spent adding more
  instances of an already-covered axis bought nothing.

**Reference bugs found by hardening.** Three, all before batch: an irgen `/in` path assumption
that broke the outport direction; a shared usage-map read that silently emitted nothing for one
direction; a one-shot barrier that could never re-arm. Each would have been an FP. Consistent
with L7's "3 per problem, every time."

**Review-round cost pattern.** 8 rounds. The two that mattered were both fairness FAILs, and
both were conceded rather than argued: an unstated barrier re-arm requirement (fixed in one
sentence) and a test leaning on the gap between the repo's documented interface-compatibility
rule and what its analyzer actually enforces. The second cost the problem's hardest wall
(injected-dependency port remapping, which had been the sole failure of 4 agents in an earlier
review) — **a wall that contradicts the repo's own published docs is not difficulty, it is a
fairness bug that happens to be hard.** Removing it also removed 38 effective LOC of
then-dead code.

---

### numbat-parse-unit-expressions (Rust / unit-aware calculator language) — ACCEPTED

| | |
|---|---|
| Shape | O-Composite-add — three builtins (`parse` extended, `unit_from`, `value_in`) over ONE shared unit-expression grammar |
| Final artifact | 3 files, 393 effective LOC, 88 tests, base 225 |
| Pass-rate history | 0/5 → **70%** → 0/5 → 0/3 → 0/11 → **70%** → 0/7 → 0/6 → **20% (2/10)** |
| Patterns used | F-12 (half the band), F-10 cross-product cells, F-9 attempted (stage-boundary temperature rewrite) |
| Agent split | final batch Nova-only, 2/10; Orion structurally blocked by F-12 in every batch it appeared in |

**Why it held.** Not because of the lead trap. The band came from two independent axes: repo-test
preservation (F-12, 3 runs) and a cluster of small grammar cross-products (negated parenthesised
ratio exponent 3, superscript round-trip 2+2). No single authored wall carried it.

**What the batches taught.**
- **The pass rate was BIMODAL for eight rounds (0/70/0/0/0/70/0/0) before landing at 20%.** Every
  0% round and every 70% round was the SAME artifact seen through a different base-mode skip
  setting. L20's single-seam signature, with the seam in the HARNESS rather than the feature.
- **81 of 88 tests killed nothing.** Seven tests did all the work. L16, at a larger scale than
  neva's 20-of-21.
- **The top feature killer came from the FP panel, not the design.** `a_negated_parenthesised_ratio_exponent_parses`
  (3 kills) was written to close an adjudicated false positive. Third consecutive problem where the
  decisive test came from a reviewer or judge — L22 is now well past coincidence.
- **Two reviewers can issue contradictory instructions, and the repo breaks the tie.** Auto Review
  S1 demanded `value_in` reject `celsius`/`degree_celsius`; Test Fairness then failed the suite for
  requiring exactly that. The repo settled it: `prefix_transformer.rs` maps all six spellings to one
  conversion, and `parse` already accepted the aliases — so the narrowing had made the solution
  internally inconsistent. Check the repo before complying with a review finding.
- **A fairness flag can rest on a false premise, twice on the same assertion.** The `m⁰` round trip
  was flagged on the claim that `unit_name` returns `""` for dimensionless values. It returns
  `"m⁰"`; the repo's `unit_name(0)`/`unit_name(1)` assertions are BARE scalars with no unit factors.
  Verified both times; dropped it anyway because Test Fairness is a blocking gate and the wall was
  already covered by `m¹⁰`.

**Reference bugs found.** Six, every one a live FP:
1. `--5 °C` returned -268.15 K — repeated signs resolved AFTER the affine conversion.
2. `unit_from("/s")` rejected while `parse("5 /s")` worked — the stated inverse was false.
3. `unit_from` could not read back `m¹⁰`/`m⁰` that `unit_name` prints — the tokenizer takes only
   single superscript digits, so the repo cannot round-trip its own output.
4. `value_in` inherited `Quantity::convert_to`'s zero exemption, so `value_in(0 s, "m")` returned 0.
5. Exponent grammar accepted computed ratios (`m^(1/2/3)`).
6. `offset_scale` narrowing (self-inflicted, from complying with S1 without checking the repo).

**Cost.** Nine batches. The dominant cost was not difficulty tuning — it was five rounds spent
flip-flopping the base-mode skip between "whole module" and "two tests", because the harness axis
(F-12) was invisible in local validation and each setting drew a different reviewer complaint.

### rust-minidump-stack-containment (Rust / crash-dump stack unwinder) — ACCEPTED 2026-08-06

| | |
|---|---|
| Shape | O-Composite-add; new containment/trust-accounting layer across 3 crates (breakpad-symbols parser, minidump-unwind walk loop, minidump-processor output) |
| Final artifact | 9 files, **327 effective LOC** (Counter 2), 49 tests, meta 523 words |
| Pass-rate history | one batch: **2/10 = 20%**, FP clean, Auto Review 3/3 description + 3/3 tests + 3/3 solution |
| Patterns used | **F-13** (lead, 6/10), **F-15** (4/10), **F-14** (3/10), F-12 absent by design (0 baseline failures in 10/10 runs) |
| Agent split | Nova 2/10. **No Orion, no Vega** — single-agent batch |
| Effort observed | 9-26 files, 439-685 added LOC, 9.2M-20.3M prompt tokens per run |

**Why it held.** Three INDEPENDENT causes, not one seam (contrast L20). The kill table shows no
correlated cluster: the delta-discard failures (Nova 2, 5, 8) were single-test near-misses at 48/49,
while the terminal-state conflation (Nova 1, 3, 7) produced 5-6 failures each. Two runs passed
cleanly. Every evaluator recorded `was_mentioned_in_description: True`, so all three walls are
contract-stated and fix-hidden.

**What the batch taught.**

1. ⭐⭐ **The two top killers were BOTH written in response to reviewer feedback, not designed.**
   `a_delta_row_that_declares_and_computes_is_discarded` (6 kills, top) came from a Test Fairness
   *coverage suggestion* in round 25; `a_reduced_frame_is_surfaced_even_when_the_walk_ended_plainly`
   (4 kills, joint 2nd) came from an Auto Review T4 finding in round 26. Together they account for
   the sole failure of three runs. This is the third consecutive problem where the band-decider came
   from a reviewer (L22), and the first where reviewer-sourced tests took the top TWO slots.

2. ⭐ **40 of 49 tests killed nothing.** Nine tests did all the work. Among the zero-kill set are
   the two I spent the most rounds on: the baseline-preservation contract (trap 8, rounds 14-15) and
   the already-at-weakest-trust marking rule (trap 9). **Zero baseline failures across all 10 runs**
   — every agent got conditional output omission right, so an axis justified on "it reds 11 existing
   tests" was worth nothing against real agents. Direct L15 confirmation.

3. ⭐ **The discriminating fixture for a tolerance rule is the UNDER-threshold case.**
   `a_second_reduced_frame_ends_the_walk` (the two-event fixture, the one the rule is written about)
   killed **zero**. `degradation_is_summarised_over_the_whole_walk` (one event, asserts the walk
   continued and stayed `Ok`) killed **4**. See F-15.

4. ⭐ **Format nouns need their extent stated.** "A single record that declares no caller and also
   computes one is discarded" — six agents read *record* as *row*. The word is the format's own
   term for a header-plus-amendments composite; the natural-language reading is the line in front of
   you. Nothing in the sentence is wrong, and it still cost 6 of 10 runs. See F-13.

5. **Late coverage rounds ARE difficulty work.** Rounds 25-28 were pure review response and added
   four tests. Those four hold two of the top three kill slots.

**Reference bugs found.** Three, each a live FP:
1. `classify_end_of_stack` read only the FIRST `.ra:` in a row (`split_once`), so
   `.ra: .undef .ra: <expr>` was accepted as a clean declaration — while the repo's own evaluator
   honours the LAST assignment. A machinery-riding bug: my semantics contradicted the mechanism I
   was reusing.
2. End-of-stack was a WHOLE-RECORD verdict, so INIT `.undef` plus any later delta was discarded
   instead of the delta replacing the rule. Fixed by making it per-address.
3. Frame cap checked BEFORE the push, so `FrameLimit` only fired on the 1025th attempt.

**Cost.** 28 rounds, one batch. Nearly all of it was review response; the difficulty came out where
the reviewers pointed, not where the design aimed.

### lyon-fill-internal-vertices (Rust, ACCEPTED 2026-08-07)

**Shape.** O-Algorithm-correctness. Opt-in interior-vertex elimination in lyon's fill tessellator:
a public `FillOptions` flag whose enabled path must emit only boundary vertices while preserving the
covered region exactly.

**Final artifact.** 45 tests, 431 raw / **260 human-effective** LOC across 4 files
(1 new module + 3 modified). meta 301 words.

**Pass-rate history.** batch 1 **6/10 raw -> 3 genuine** (FP voided 3) · batch 2 **4/10 raw -> 0
genuine** (FP voided ALL four) · batch 3 **1/10, ACCEPTED**. Agent split: Nova x10 each batch.

**Effort.** Failing and passing runs alike were substantial: 625-753 added LOC, 3-4 files,
7-15M prompt tokens. The passing run was the LEANEST (625 LOC) — size did not predict correctness.

**Patterns used.** F-16 (unparameterised setter, 4/10) · F-17 (proxy-metric drift, 8/10) ·
F-10 (overlap-multiplicity x winding-polarity cross product) · A10 (triangle handedness differs
between the Vertical and Horizontal sweeps).

**Why it held.** The capability is globally coupled by construction — deciding whether a vertex is
interior needs the whole mesh, so no local fix converges. Every agent independently converged on
per-vertex one-ring ear-clipping, and that architecture has three structural failure modes
(bails on non-manifold links, fans non-convex cavities, two-phase removal misses interleaving).
Zero of 45 tests killed nothing.

**What the batch taught.**

1. **The band decider was written in the LAST round, from an FP finding.** `no_emitted_vertex_has_a
   _fully_filled_neighborhood` was added in R6 in response to the batch-2 FP panel, and became the
   top killer (8/10) AND the sole failure of both near-misses. Third consecutive problem where the
   decisive test came from review response rather than trap design (L22).
2. **Two consecutive batches had EVERY pass voided by the FP panel** while the wrapper reported 60%
   then 40%. The wrapper rate was pure noise until the suite could tell a real solution from a
   broken one. Read FP correlation before reacting (L28).
3. **A description concision trim manufactured a 4/10 compile-error cluster** (L26).
4. **My own "cascades cannot occur" measurement was over-generalised from 7 fixtures** and the FP
   panel found a counterexample. A local sweep over your own fixture set is not a proof.

**Reference bugs found before the batch.** 1 — the ear-clipper normalised every patch to CCW, which
is correct for the Vertical sweep and wrong for Horizontal (lyon emits clockwise there); the symptom
was a stalled fixpoint that accused the classifier. Found by the skeleton probe, not by review.

**Investments that provably bought nothing.** The baseline-preservation axis (T3) was demoted at
design time on L15 grounds and correctly so: **0 baseline failures in 10/10 runs in all three
batches** — all 30 runs passed 185/185 baseline. Also: the epsilon-scale collinearity probe was
deliberately NOT authored (f32 noise floor, medium-confidence adjudication), and declining it is
what kept batch 3 at 1/10 instead of 0/10.

### gluon-format-comments (Rust / source formatter) — ACCEPTED 2026-08-07

| | |
|---|---|
| Shape | O-Algorithm-correctness; comment preservation and placement across the expression printer and the shared pretty-print layer |
| Final artifact | 3 files, 243 effective LOC (Counter 2), 37 tests |
| Pass-rate history | 0/12 -> 0/14 -> 0/10 -> **1/11 = 9%** (accepted) |
| Patterns used | **F-18** (lead, 22 of 37 kills), F-10 nested cross-product cells, F-6 ordering |
| Agent split | Nova 1/11; no Orion in the accepted pool |
| Long-horizon | passing patch 633 added lines / 2 files; failing runs 605-915 lines, 19-50M prompt tokens |

**Why it held.** The contract is fully statable and still hard, because the difficulty is not in
knowing the rule but in applying it at every position x every lexical form. The passing run
implemented a general gap model; every failing run implemented placement per-construct and left a
form or a position uncovered.

**What the batches taught.**

* **The band decider was a test I had already deleted once as unfair.** In round A5 I removed
  `a_same_line_block_comment_breaks_a_record_that_would_otherwise_fit` because meta.md pinned layout
  it never stated. Round A10 restored it once the rule WAS stated. It then took 7 of 11 and was the
  sole failure of the closest near-miss. An agent contested it as an undocumented convention; the
  contest failed on the base repro, because the unmodified formatter already breaks that record.
  **Deleting a test for unfairness and stating the rule are not the same repair, and only one of
  them keeps the difficulty.** (L30)
* **Three of the five block-comment killers came from reviewer coverage suggestions**, not from the
  trap design: the mixed line/block gap (5 kills) and the same-line block on a let binding (2) were
  both Auto Review T4 items. L17/L22 for the fourth consecutive problem.
* **15 of 37 tests killed nothing**, and they are almost exactly the tests I authored during the
  original design: `own_line_comment_before_closing_brace`, `trailing_comment_on_last_record_field`,
  `own_line_comment_before_the_first_alternative`, `comments_around_a_record_base`,
  `comments_at_inner_and_outer_let_boundaries`. The designed traps were the cheap half; the parity
  cells were the expensive half.
* **Dropping a whole feature was the solvability lever, and it was measured, not guessed.** Batches
  1-3 read 0/12, 0/14, 0/10 with a record-TYPE axis (a second printer in another file) carrying 8
  tests at 3-6 kills each. Removing that axis — tests, contract sentences, and the
  `base/src/types/mod.rs` half of the solution — was verified BEFORE the batch by applying the
  near-miss runs' own patches to the reduced suite: two scored 37/37. The next batch returned a
  legitimate pass. (L32)
* **Wording clarifications have a measurable, and sometimes excessive, price.** Counterfactuals over
  the run artifacts priced three candidate clarifications at 7/12, 4/12 and 2/12 passes. Shipping
  all three would have blown the ceiling; the blank-line one alone was the only one fairness
  actually required.

**Reference bugs found by hardening: 4.** `///` doc comments scanned as ordinary comments and
printed twice; the comma separator keyed on the field NAME span so the next field's gap re-printed
comments from inside the previous value, growing the output on every format pass; a match-alternative
gap emitting two breaks where one was needed; and own-line comments in a gap with no trailing comment
glued onto the previous line (found only by probing an Auto Review coverage finding).

**Two structural hazards this problem exposed.**
1. **A feature that invalidates an existing repo test manufactures a cheat trap.** Three runs across
   two batches were scored PASS_CHEATED for editing `format/tests/pretty_print.rs`, and two of the
   five tests they edited are ones this feature legitimately supersedes. Base mode skipping them does
   not protect the solver. (L31)
2. **Auto Review can request a change the repo's own tests forbid.** S1 asked that a same-line block
   comment force multiline layout; implementing it broke `preserve_block_comments` and
   `preserve_shebang_line`. Conceded on the DESCRIPTION side per L19 rather than widening the
   exclusions.


### vrp-tsplib-edge-weight-types (Rust / VRP solver, TSPLIB scientific reader + CLI) — ACCEPTED

| | |
|---|---|
| Shape | O-Composite-add — new parser capability in one crate plus a cross-crate CLI export surface |
| Final artifact | 8 files, 374 effective LOC (881-line solution.patch), 35 new tests + 60 base |
| Pass-rate history | b6 0/3 → b7 2/10 → b8 0/5 → b9 2/9 (22%) → b10 0/23 (regression) → b11 5/10 (50%) → **b12 3/10 (30%), accepted** |
| Patterns used | **F-19** (lead, all 4 measured batches), F-10 (metadata permutations x display axis) |
| Agent split | b12 was Nova x10, 3 solves. Orion appeared only in b11 (0/2) |

**Why it held.** One lead trap (F-19) that no fairness round could disclose away, because the
clause that makes it fair -- "have the command return this JSON output" -- is also the clause an
agent reads as already satisfied the moment its serializer is correct. Four batches, 52 runs,
never below a 50% kill rate, never once flagged unfair.

**What the batches taught.**

1. **A description clarification is a difficulty DEBIT, and it lands a batch later than the edit.**
   Three consecutive fairness rounds (DISPLAY_DATA_TYPE closed-set scoping, an explicit
   header-ordering sentence, a GEO formula restatement) each disclosed a trap without a
   replacement being added. The display-data cluster went 2/9 → 0/10 and GEO went 1/9 → 0/10 while
   every individual edit looked locally correct. Budget a replacement trap in the SAME round as any
   disclosure, not after the next batch reads soft. See L34.

2. **The differential harness over-predicts when the DESCRIPTION changed, not just the tests.**
   Replaying batch 11's five passing patches through the hardened suite killed 3 of 5. The next
   live batch killed **0 of 10** on that same axis. Those five agents never read the new sentence;
   the next ten did. See L35 -- this is the finding worth carrying forward.

3. **A requirement that is simple once stated buys no difficulty, however subtle the wrong version
   looks.** The added rule was "locations are returned in ascending node-number order", tested at
   DIMENSION 12 with permuted input so a lexicographic sort of the zero-based id STRINGS puts "10"
   before "2". It reads like a textbook index-space trap. Every one of 10 agents sorted numerically.
   Stating an ordering hands the fix, because there is only one reasonable ordering primitive.

4. **Reviewer coverage suggestions are not ALWAYS free difficulty (bounds L17/L22).** All three
   suggestions taken in the final round -- a NO_DISPLAY grammar rejection, a missing
   EDGE_WEIGHT_FORMAT rejection, and all six TWOD_DISPLAY metadata permutations -- killed **zero**
   agents. They were still worth taking (they closed real FP holes and cleared the review), but on
   this problem the decisive test came from the author's own scope redesign, not from review.

5. **34 of 35 tests killed nothing.** Consistent with L16, at the most extreme ratio measured
   so far.

**Reference bugs found.** 3, consistent with L7 — (a) a fixed-3-iteration loop in
`read_explicit_header_fields` that broke the missing-DISPLAY_DATA_TYPE path with a misleading
"expected colon separated string"; (b) three negative tests loosened to bare `is_err()` that then
passed VACUOUSLY on base, because base rejects `EDGE_WEIGHT_TYPE : EXPLICIT` before ever reaching
the key under test; (c) a solution-only symbol (`TsplibLocations`) imported into a test target that
base mode also compiles, which broke every base-mode test on the base tree and was caught by the
platform's Verify Solution rather than locally — my base mode had only ever been run on the
solution-applied tree.

---

### go-workflows-channel-drain (Go / durable-workflow engine, cooperative coroutine scheduler) — ACCEPTED 2026-09-04

| | |
|---|---|
| Shape | O-Composite-add: new capability surface across an internal channel/selector/scheduler core and its public workflow wrappers |
| Final artifact | 9 files, **351 effective LOC** (raw 683), **102 tests**, meta.md 499 words |
| Pass-rate history | b6 0/5 (81t) → b7 0/5 (93t) → b8 **3/10** (92t) → b9 **1/10** (96t) → b10 0/5 (102t) → b11 **2/10 = 20%** ACCEPTED |
| Patterns used | **F-20** (lead, 8/10), F-10 (4/10), scheduler-progress cluster (1-2/10 after L38 lever) |
| Agent split | Nova only, 10 graded + 1 scratched. 2 PASS_LEGITIMATE, 2 FAIL_REGRESSION, 6 FAIL_MISSED_REQUIREMENT |
| Long-horizon | median 11 files touched, 1026 added LOC, 11.2M prompt tokens per run |

**Why it held.** Three independent traps at different depths: F-20 on an adjacent untouched API
(8/10), an F-10 cross-product cell (4/10), and a scheduler-progress-propagation requirement
(1-2/10). Every evaluator marked `description_clear: true` and `difficulty: challenging` in every
batch; both passers cleared the FP panel at high confidence.

**What the batches taught (generalising).**
- **The trap I designed was not the trap that worked.** The arrival-ordered queue -- the
  architectural centrepiece, six rounds of authoring -- killed 2/10 at acceptance. The band was
  decided by F-20, a 40-line guard written in one round from an FP panel report (L37).
- **A 0% batch is not automatically unsolvable.** Batch 10 read 0/5; pooled with b9's 1/10 that is
  ~7%, and at a true 10% rate **P(0 of 5) = 0.9^5 = 59%**. Compute the binomial before redesigning.
- **Stating an under-stated rule beats deleting the test that enforces it.** At b7 the
  freed-capacity overtaking test killed 4/5 and I DELETED it (rate 0→30%). Reviewers demanded it
  back; I restored it AND promoted the concessive clause to a mandate -- at b11 it killed only
  2/10 and never appeared in a near-miss. Deletion bought rate; the mandate bought rate AND kept
  the trap (L38's sibling finding).
- **43 of 102 tests killed nothing** -- the entire signal-backlog family (8 tests), every Peek
  variant, Cap/IsFull. Real fairness and FP insurance, zero difficulty. The difficulty lived in
  ~12 tests across 3 clusters.

**Reference bugs found: 4** -- every one an FP if shipped.
1. Package-global `capacityFreed` counter let unrelated schedulers keep each other running.
2. Exited Select send cases stayed registered as blocked senders (`runtime.Goexit` skips
   post-`Yield` statements; the unregister had to move into a `defer`).
3. A terminated ordinary `Send` left a phantom pending value visible to Drain/Peek.
4. A parked Drain case was a progress-notification target but not a RENDEZVOUS target, so a
   nonblocking send to a zero-capacity channel was silently dropped (L39).

**Cost note.** 6 batches / 13 authoring rounds. Six meta.md edits, each a full-price batch. The
one round that would have been re-eval-eligible (a comment-convention cleanup) was correctly
bundled with a test edit rather than shipped alone (L36).


### datafixerupper-ordered-alternatives (Java / Mojang DataFixerUpper serialization DSL) — ACCEPTED 2026-09-08

| | |
|---|---|
| Shape | Composite codec added to an existing combinator DSL; decode scan + encode scan + MapCodec encode builder boundary |
| Final artifact | 5 source files, 270 effective LOC (Counter 2), 173 tests, meta 477 words |
| Pass-rate history | batch 8 **2/10** (150 tests, mirror contract) · batch 9 **5/10** (173 tests, mirror deleted) |
| Patterns used | F-21 (lead, 5/10) · F-10 (builder-kind cross-product) · F-2 (bidirectional seam, decode/encode) |
| Agent split | Nova 10/10 of the batch; **no Orion** |
| Long-horizon | passing patches 492-739 added lines across 4-5 files; platform reported 48-81 messages |

**Why it held.** All ten runs implemented the decode side correctly. The entire band was decided on
one axis: what `MapCodec.encode` must do to the builder it returns. `RecordBuilder` has no accessor
and `build()` is destructive, so the only sound way to classify the outcome is to decorate the
returned builder and inspect the `DataResult` at `build()` time. Agents either skipped the wrapper
entirely (Nova_2, Nova_9 — identical 17-test failure set) or wrote it behind a type check (F-21).

**What the batch taught.**
- **156 of 173 tests killed nothing — 90%.** The strongest L16 instance measured. Every decode test,
  every lifecycle-folding test, all validation, keys, `toString`, equality and covariance test scored
  zero. 17 tests carried the whole band and they are all on one subsystem.
- **All four traps named in DESIGN.md killed zero.** Earliest-partial selection, partial-lifecycle
  folding, aggregated error messages and covariance were the designed difficulty (F-9 x3 + F-2).
  Covariance had killed 5/10 in batch 8 and killed **0** in batch 9. The difficulty that survived was
  discovered through review response, not design (L22, third consecutive problem).
- **Deleting an unimplementable clause cost 30 points of band.** See L44.
- **The differential harness predicted 0/10 and the batch returned 5/10.** See L35's new cell — the
  largest over-prediction measured.
- **A coverage hole shipped and was accepted.** Auto Review's final Tests band was 2/3 on a real
  T3/T4 gap: every full-success lifecycle assertion on the three scanning surfaces uses a STABLE
  winner, so an implementation that rewrites every success to stable would pass. Nobody exploited it
  — but it was live for 9 batches and only the accepting review named it.

**Reference bugs found by hardening.** Three, consistent with L7. (1) `StableWhenNoPartialBuilder.
setLifecycle` re-wrapped itself, so `MapCodec.withLifecycle` / `.deprecated(n)` were overwritten with
stable (iteration 63). (2) The `sameKindAs` class-identity provenance gate was unsound AND provably
not load-bearing — reverting it failed nothing (iteration 63). (3) The `ops.mapBuilder()` surrogate
disagreed with the real supplied builder, returning an unqualified error whenever the mirror accepted
what the real builder rejected (iteration 67, Auto Review S1).

**One finding was filed that does not reproduce.** Auto Review's second S1 claimed a compressed
JsonOps builder loses its candidate's lifecycle. `JsonOps.getStringValue` is
`isString() || isNumber() && compressed`, so the numeric key it specifies is ACCEPTED under
`JsonOps.COMPRESSED` and no mismatch arises; substituting a boolean key does produce the mismatch, but
`mergeToList` into a compressed empty pins `Experimental` regardless, so nothing is observable. Fixed
structurally anyway by deleting the surrogate. Recorded because L23 says verify the premise — here the
premise was false and complying was still correct, since the OTHER instance was real.


### customasm-derived-bank-layout (Rust / assembler resolver) — ACCEPTED

| | |
|---|---|
| Shape | O-Pipeline-hard. Promote a quantity out of a single-pass `eval_certain` pre-pass INTO the existing fixed-point resolver, plus a new measured quantity (`used`/`end`) read back through an existing value type |
| Final artifact | 13 files, 980 effective LOC, 68 fixtures |
| Pass-rate history | b1 **0/6** (old suite) -> b2 **1/10** -> b3 **0/5** -> b4 **0/5** -> b5 **1/10 = 10% ACCEPTED**. Solver effort: median 690 added LOC, 16 files, 12-24M prompt tokens per run |
| Patterns used | **F-22** (lead, 8 of 9 failing runs), high-water-extent cluster (2 runs), non-convergence propagation to dependent labels (3 runs) |
| Agent split | Nova 1/24 across all batches, Orion 1/2. **Orion was the only passer until batch 5**, where a Nova finally passed after four fairness relaxations |

**Why it held.** The lead trap rode the repo's own machinery: the feature is not a new subsystem but
a change of WHEN bank fields are evaluated, so every capability routes through one fixed point and a
partial implementation fails the mixed chains while passing the direct ones. Ten runs produced ten
`FAIL_MISSED_REQUIREMENT`/`PASS_LEGITIMATE` verdicts with `was_mentioned_in_description: true` on
every single failure - zero fairness flags across the accepted batch.

**What the batches taught.** (generalising findings only)

1. **The PROMPT sets solution quality, not just fairness — see L45.** Replaying all 20 saved
   solutions against ONE fixed suite: batch 2, solved under an unbounded order clause, scored
   **5/10**; batches 3 and 4, solved after that clause was bounded for fairness, scored **0/10**.
   Same model, same tests. This is the single most useful measurement of the whole arc.
2. **Do not gate on behaviour meta.md never names — see L46.** Four fixtures were removed on this
   ground (label-alignment extent, `#addr` twice, bare-forward-`#addr` extent). Removing two of them
   took batch 2 from 1/10 to 2/10 and produced the FIRST Nova pass in 19 runs. The rule paid twice:
   the FP panel's adjudicator later cleared the accepted pass precisely BECAUSE the align fixtures
   only ever tested align WITH following content, calling the trailing-align case "an underspecified
   edge... it cannot fairly gate the reward".
3. **An unbounded promise is an FP generator.** "works whatever order the definitions appear in"
   was ruled a functional false positive when a passer failed reversed chains beyond the iteration
   budget: reproduced exactly at 3/8/10 banks OK, 11 and 12 failing. Bounding the clause fixed the
   FP and cost the band, which is L44 arriving on a different problem.
4. **The platform's JUnit rewrite mis-pairs names with failure bodies.** `test::file::x` comes back
   as `test.file.x`, and in batches 1-2 the failing-name SET matched the cargo log on only 4 of 9
   entries, with bodies filed under the wrong names. **Mine `test-log.txt`, never the returned XML.**
5. **40 of 68 fixtures killed nothing.** The extent semantics (partial units, `#res`, `fill`,
   backward cursor, non-byte units) are fairness and FP insurance, not difficulty. Two composite
   fixtures authored specifically as levers (`ok_res_partial_unit_bits3`,
   `ok_res_in_derived_bank_feeds_size`) killed **zero** agents - L15 again.

**Reference bugs found: 8** - far above the ~3 of L7, and every one would have been an FP.
(1) `#addr` range check tripping on a guessed bank start; (2) pending optional `outp`/`size` members
reading as `Void` so arithmetic errored instead of waiting; (3) a PRESENT field evaluating to void
read as omitted; (4) settle termination comparing layouts by value only, ignoring the guess flag;
(5) zero-size `fill` bank underflowing `offset + size - 1` into a panic; (6) `used_units` ceiling
division overflowing near `usize::MAX`; (7) the lower-bound `#addr` deferral suppressing the promised
dependent-label diagnostic; (8) **still open at acceptance** - `bankdef_context` re-evaluates settled
fields under the iterator's END-OF-FILE `symbol_ctx`, so a forward *contextual* label (`.target`) in
any of the four fields can be looked up in an unrelated later scope. Auto Review filed it High x4;
the problem was accepted anyway. Fix by capturing the `SymbolContext` at the `#bankdef` declaration.

---

### rocketpy-propellant-slosh (Python / flight-dynamics simulation) — ACCEPTED 2026-09-10

| | |
|---|---|
| Shape | O-Pipeline-hard — one new physical mode threaded through every phase of an existing integrator |
| Final artifact | 10 files, **375 effective LOC**, 146 tests |
| Pass-rate history | batch 1 **0/6** (one correlated tolerance-padding cause) -> callable-form lever + fairness rounds -> batch 2 **2/10 = 20%** -> review-driven coverage growth -> batch 3 **0/10 = reject** -> ONE test-side fairness fix, re-eval of the same ten solutions -> batch 4 **1/10 = 10%, ACCEPTED** |
| Patterns used | **F-23** (lead, 6/10), F-7 (3/10), F-10 (axis design), F-23 x F-10 pairing |
| Agent split | Nova 9 + Orion 1. The single pass was Nova; Orion failed to F-23 in batch 2 AND batch 3 |

**Why it held.** Three disjoint clusters, each run dying to exactly one: F-23 callable-domain
(6), F-7 parachute context (3), representation pin (1, and that one was the defect). Judges
returned `description_clear: true` / `tests_deterministic: true` /
`was_mentioned_in_description: true` / difficulty "challenging" on every failing run across two
batches, with zero unfairness, cheating or environment flags -- several rebutted the unfair
reading unprompted. Auto Review scored 3/3/3 Clean.

**What the batches taught.**

- **The band lived entirely on a fairness fix, not on a trap.** Batch 3 and batch 4 are the SAME
  ten solutions. The only delta is one test helper that stopped pinning a returned value's type.
  0/10 reject -> 1/10 accepted. See L49.
- **Re-eval executed as documented, and for a TEST-only delta the local replay is exact.** The
  local differential harness predicted the live result precisely: Nova #8 flips to 146/146, Nova
  #2 unchanged at 6 failures. That is the case L35 says to trust, and the button's availability
  is what certifies it -- contrast vrp-tsplib, where a description delta made the replay a lie.
  Cost ~30% of a batch to convert a reject into an acceptance.
- **The dominant trap was binary and could not be tuned.** All six F-23 runs failed BOTH killing
  cells, so the axis flips 0 or 6 runs and nothing between: the measured counterfactual for
  softening it was 5/9 = 56%, over the ceiling. When a batch reads 0%, check whether your lead
  trap even HAS a middle setting before planning to soften it.
- **Auto Review now grades the near-miss DISTRIBUTION, not just the rate.** It filed a Medium
  advisory: *"The 1/10 exact pass rate overstates effective difficulty because every failing
  implementation passed at least 140 of 146 new tests and the failures were confined to two
  narrow edge patterns."* Benign here, but a problem whose rate is carried entirely by two edge
  cells is now visible to the reviewer as such.
- **134 of 146 cases killed nothing.** They are FP insurance and they earned their keep at the FP
  panel (L48), but no difficulty was bought there. Four of the seven callable-spelling cells were
  pure insurance too (L47).

**Reference bugs found.** Three, each an FP in waiting: (1) the seeded-mode block labelled the
two lateral entries as the y and z body axes when `R1`/`R2` are x and y; (2) a `LevelBasedTank`
`ZeroDivisionError` that turned out to be a fixture whose `flux_time` ended before `total_mass`
reached zero, not a solution defect; (3) a new test that hung a legitimate agent implementation
for 150s+ by flying to apogee while asserting only on `flight.solution[0]` -- capped to
`max_time=0.5`, 1.18s, identical assertions. Shipped, (3) would have read as a failure and
silently corrupted the pass rate.

---

### datafixerupper-derived-recursion (Java / serialisation schema + term-rewriting engine) — ACCEPTED 2026-09-11

| | |
|---|---|
| Shape | O-Pipeline-hard. Replace a caller-declared flag with a derived reference graph: SCC recursion groups, dependency-ordered construction, one recursion family per group, inhabitation fixed point |
| Final artifact | 6 production files, 389 effective LOC (582 raw), 87 tests |
| Pass-rate history | batch 1 (79 tests) 1/10 → Auto Review revision ×3 → batch 2 (87 tests) **1/10, ACCEPTED** |
| Patterns used | **F-24** (lead, 8/10 twice) · **F-25** (4/10 + 4/10) · F-20 family (3/10) · F-9 (2/10, the DataFix depth pair) |
| Agent split | 10 Nova, 1 solve. Orion/Vega locked at Iron rank — no split available |

**Why it held.** The unknown-name distinction (F-24) is the whole band and it is the cheapest
sentence in the description. Everything the problem was DESIGNED around — reference collection
across nine template forms, SCC grouping, group-local indices, dependency build order, the
inhabitation fixed point — was implemented correctly by nine of ten runs. 79 of 87 tests killed
nothing. The difficulty lives entirely in three seams that the FEATURE creates as a side effect:
what happens to a name that is not in the namespace, how long a deferred placeholder stays valid,
and what an assembly-path rewrite silently drops.

**What the batches taught.**
- **Two full batches, four levers apart, both read exactly 1/10 with the identical dominant
  cluster.** Against the vrp-tsplib 22%-vs-50% swing, a band carried by a semantic distinction
  (rather than by a numeric/ordering edge) is reproducible across batches.
- **The 8 tests that killed anything were not the tests the design was about.** Three of them
  (11 of 32 kill events) exist only because a reviewer found the corresponding bug in the
  REFERENCE. See L50.
- **Adding those three tests grew the killing set from 5 to 8 and did not move the rate.** When a
  dominant cluster already saturates the band, extra discrimination is free but invisible — measure
  it as coverage, never as expected pass-rate movement.
- **A doubly-telegraphed trap still killed 8/10 twice.** Every evaluator recorded the requirement
  as both stated in the description and inferable from the codebase. Fairness and difficulty were
  not in tension here; the pressure to invent a sentinel is stronger than the sentence forbidding it.
- **Four runs failed ONLY the F-24 pair** at 85/87. The near-miss margin is one clause.

**Reference bugs found.** Seven, across four Auto Review rounds — and **four of the seven were
introduced by the previous round's fix** (L51):
1. A test pinned iteration order of the pre-existing `types()` Set that meta.md never promised (test-side fairness defect, not a reference bug).
2. Dead `collectedReferences` bookkeeping that nothing read.
3. **Blocker** — cross-group DataFix traversal: an external group's recursion point embedded with `DSL.constType` was never entered, because `RecursiveTypeFamily.everywhere` traverses with `recurse=false` and `RecursivePointType.everywhere` no-ops in that mode. Base has no such hole (one family for the whole schema), so it was a real regression.
4. A memoized `Supplier` cached an inert placeholder tree that could not be applied *(introduced by the graph-collection design)*.
5. NPE when `id()` was called during `registerTypes` *(introduced by fix 4 — the placeholder was gated on a phase flag instead of on whether the structure existed)*.
6. A retained reference resolved against a mutable `buildingGroup` that had already been cleared, so a same-group reference became external *(introduced by fix 5)*.
7. `ExternalRecursionType` delegated only codec/equality/`everywhere`, so `point`, `all`, `one` and the optic finders returned Type's empty defaults through a cross-group reference *(introduced by fix 3)*.
8. The `DSL.named` wrapper base puts on every registered template was dropped when the assembly path moved off `getTemplate` *(introduced by the fix for 6)*.

The durable fix for 4/5/6/8 was not another guard: it was to stop resolving late at all —
snapshot each supplier ONCE, then substitute every placeholder eagerly per group before the family
is built. Every narrowing patch created the next bug; the redesign that deleted the phase variable
ended the chain.


## 3. CROSS-PROBLEM LAWS

| # | Law | Evidence |
|---|---|---|
| L1 | **Enumerated rules get transcribed; architectural impossibilities do not.** | pulldown 67% with every rule listed → 40% from one wall |
| L2 | **Globally-coupled beats pointwise, always.** Fixed points over a whole program hold their band across many batches; independently-implementable rule sets do not. | calyx held 10-40% over 13 batches; pulldown's rule set read 67% |
| L3 | **Scattered singleton failures mean the domain is separable — stop stacking traps.** | pulldown's 4 failures had 4 causes and no lever; adding rules would not have moved it |
| L4 | **Diverse failure causes at a low rate = healthy. One shared cause = unfair.** | calyx runs13: 6 failures, 6 root causes, all agent-fault |
| L5 | **The second axis of a one-sentence rule is free difficulty.** | calyx `@fixed_signature` ref cells, 28% kill |
| L6 | **Name-based shortcuts pass name-shaped suites.** Include one instance whose name breaks the pattern. | calyx v7 `std_mult_pipe`; costs zero pass-rate |
| L7 | **Hardening surfaces your own reference bugs — 3 per problem, both times.** Every one would have shipped as an FP. | pulldown ×3, calyx ×3+ |
| L8 | **A test that pins where an ambiguity resolves is unfair even if your reference is right.** | pulldown removed 4 such tests |
| L9 | **An absolute meta sentence plus an unstated implementation exception costs a review round.** State exceptions in the same sentence. | calyx, three times |
| L10 | **Agent capability drifts upward between batches.** Ship at the low edge; a mid-band artifact can drift out of band while you iterate. | calyx Nova 0/18 → 3/9 in one day, harder artifact |
| L11 | **Patch completeness is independent of a green test run.** A worktree can carry changes the patches omit; every local channel inherits the contamination. | calyx: `Cargo.toml` dev-dep sat outside both patch scopes through 12 batches and every review round, caught only by Verify Solution |
| L12 | **A famous name overrides careful reading, even against a plain contrasting sentence in the prompt.** Cite the real external construction by name only if you want agents to retrieve and trust it over your text. | lyon-arcs-join: 9/10 Nova built SVG2's real osculating-circle arcs join instead of the stated same-radius variant |
| L13 | **A numeric bound in a test needs full justification or full elimination — a smaller magic number just buys one review round.** If a reviewer's objection is "this constant is unstated," remove the need for a constant (an invariant that's true by construction) rather than picking a smaller one. | lyon-arcs-join: exact count → unfair; `2x` bound → STILL unfair, same objection generalized; unsigned-angle-sum comparison → held (6 orders of magnitude separation, epsilon is pure float noise) |
| L14 | **A false positive is not always "the reference is buggy" — verify the reference before touching the solution.** A candidate's own extra defensive check can be the actual bug; the real gap is often that the hidden suite never exercised the input that exposes it. | lyon-arcs-join: candidate added `!miter_limit.is_finite() -> None`; reference verified bug-free by direct probe (infinity == 1e6 output); fix was 3 new tests, zero solution changes |
| L15 | **Mutation-kill counts do not predict agent-kill counts.** Mutations measure what your tests can DETECT; a batch measures what agents actually get WRONG. Build mutation coverage for FP protection; build composition cells (F-10) for difficulty. Never justify a hardening round on mutation evidence alone. | neva: the WaitAll barrier took mutation V10 from 0/12 to 2/15 and killed 0 of 10 agents; the trap that decided the band killed only 2 mutations. rust-minidump: the baseline-preservation axis was justified on "it reds 11 existing tests" and produced **0 baseline failures across 10/10 runs** |
| L16 | **One test usually decides the band.** Redundant tests still earn their place (fairness, FP insurance, coverage review), but hardening effort belongs on the un-tested intersections, not on more instances of a covered axis. | neva: 20 of 21 tests changed no outcome; the F-10 cell alone separated 2/10 from 4/10. datafixerupper-ordered-alternatives batch 9: **156 of 173 tests (90%) killed nothing**, 17 carried the band, and one of those 17 decided it |
| L17 | **Reviewer coverage suggestions are free difficulty — take them.** They are written to close fairness gaps, and a fairness gap is by definition a behaviour the contract states but nothing tests, which is exactly where an agent can be wrong for free. | neva: the decisive test came from a Test Fairness coverage suggestion, not from the trap design |
| L18 | **Refines L4 — a shared failure cause is unfair only when NO agent cleared it.** The test is reachability, not diversity. Check: did anyone pass? did near-misses get everything else? did the evaluators mark `description_clear: true`? was the FP panel clean? If yes, one dominant cause is a legitimate design wall (F-1/F-9 family), not a hidden requirement. | neva: 6 of 8 failures on one root cause, 2 passes + 2 at 20/21, accepted |
| L19 | **A wall that contradicts the repo's own published docs is a fairness bug that happens to be hard.** Concede it; do not buy it back by writing the contradiction into the meta. | neva: injected-dependency port remapping was the sole failure of 4 agents in an earlier round, and died to one line of the repo's own book |
| L20 | **A single-seam problem is BIMODAL: its pass rate is a coin flip, not a difficulty.** If one decision gates every killer test, batches swing wildly while the artifact only improves. The tell is a per-test kill table where the killers are perfectly correlated — every failing run fails the IDENTICAL set. Adding tests to that seam cannot stabilise it; they all die together. Fix by adding a lever whose failures are INDEPENDENT of the seam, and confirm via a kill table with two separated clusters. | customasm: 0/13 -> 90% -> 20% -> 57% -> 9%; agent-runs 3 had 3 failures on the identical 13 tests; the accepted batch showed a near-miss cluster (1-2 fails) and a deep cluster (18-19) |
| L21 | **An EXAMPLE appended to a general rule is read as the rule's scope, and can disarm the whole problem.** Rule-7 applies to examples, not just instance lists: keep the rule, delete the example. Note the example is usually added in good faith to clear a fairness flag — check the next batch's rate, because the fairness fix and the difficulty collapse arrive together. | customasm: "and spelling that width out explicitly leaves it whole" repaired a real 0/6 unfairness and took the batch to 90%; a later one-sided "contributing fewer than that does not" would have licensed a `>=` implementation |
| L22 | **Ask where the decisive test came from.** On two consecutive problems the band-deciding test came from a reviewer or FP-judge finding, not from the trap design. Budget review-response time as difficulty work, not as compliance overhead. | customasm: F-11 came from an FP-panel dissent and then killed 9/10; neva: the decisive cell came from a Test Fairness suggestion; rust-minidump: the top TWO killers (6/10 and 4/10) were both written in review response, rounds 25 and 26 of 28 |
| L23 | **Before complying with a review finding, check the repo.** A finding can be factually wrong, and complying can make your solution internally inconsistent or unsolvable. Verify the premise, then comply, contest, or comply differently. | numbat: Auto Review S1 demanded alias rejection that Test Fairness then failed; two fairness flags rested on a false claim about `unit_name`; S2's requested skip removal would have taken 2/10 to 0/10 because both passers deleted the tests it wanted graded |
| L24 | **A noun the format already defines needs its EXTENT stated, or agents read it in its natural-language sense.** Contract words like record / entry / block / section have a precise composite meaning in the file format and a smaller, more local meaning in ordinary English. The local reading is the one agents implement, and it is invisible to any fixture where the two coincide. | rust-minidump: "a single **record** that declares no caller and also computes one is discarded" — 6 of 10 runs discarded only the offending ROW and kept the record live; the twin fixture with the contradiction in the header killed 0 (F-13) |
| L25 | **For a tolerance rule ("allow one, stop at the second"), the discriminating fixture is the UNDER-threshold case.** The at-threshold fixture — the one the rule is literally written about — passes under both the correct reading and the stop-at-first reading. Author the N-1 case and assert that nothing happened. | rust-minidump: `a_second_reduced_frame_ends_the_walk` (two events) killed 0; `degradation_is_summarised_over_the_whole_walk` (one event, asserts the walk continued and stayed `Ok`) killed 4 (F-15) |
| L26 | **A concision trim on API prose can manufacture a compile-error kill cluster — check what a removed clause was load-bearing for.** Description reviewers optimise for brevity and cannot see the test crate. Removing a phrase that named a parameter, a return shape, or a type is not the same class of edit as removing a redundant behavioral sentence. | lyon-fill-internal-vertices: R3 added "that takes a boolean" to clear a signature-ambiguity WARNING; R4 removed it on a description reviewer's HIGH concision suggestion; batch 3 then had **4 of 10 runs** build a zero-argument builder and fail to compile (F-16). Auto Review still ruled it fair on repo convention, so the trim was survivable — but it was luck, not design |
| L27 | **Your test helper is part of the contract surface — write it in the contract's vocabulary, not in the cheapest one.** When the helper computes a structural proxy for a semantic property, author and agent adopt the same wrong abstraction and the suite is blind to exactly the gap it exists to measure. | lyon-fill-internal-vertices: a topological `interior_vertex_count` proxied a geometric "full neighborhood" contract; an FP panel found a non-manifold interior vertex passing; the replacement direct check became the top killer at 8/10 and the sole failure of both near-misses (F-17) |
| L28 | **An FP panel that voids EVERY pass is a test-completeness report, not a difficulty verdict — read whether the FPs are correlated.** If each voided pass failed a DIFFERENT probe, the gaps are independent and closing them costs one run each. If they all failed the same probe, closing it zeroes the batch. | lyon-fill-internal-vertices batch 2: 4/4 passes voided, but on four different probes (rotated overlaps / self-crossing contours / non-manifold interior / epsilon collinearity). Closing three and deliberately declining the fourth (an f32-noise-floor probe) took 40% raw -> 1/10 genuine instead of 0/10 |
| L29 | **Every assertion you add to close a hole is an assertion nobody has fairness-checked.** Tightening and fairness pull in opposite directions, so a hole-closing round silently manufactures unfairness. After EVERY such round, re-run the fairness pass on the NEW assertions only, asking one blunt question each: does the description state this, in words an agent could read? If no, there are exactly two honest options — state it in the description, or drop the assertion. Never keep a hidden requirement because it kills a mutation. **The asymmetry is the point: an unclosed hole costs one risk; an unfair test fails correct agents and cannot be repaired after shipping.** | lyon-fill-internal-vertices: R4 closed FP holes by adding baseline preconditions; R5 Test Fairness then flagged **6 of 45** tests, all of them assertions added in R4, all pinning the pre-feature mesh. Fixed by stating the current behavior in the meta (one sentence) rather than deleting the checks. Repeated verbatim on datafixerupper-ordered-alternatives: the round that closed Auto Review's T3/T4 partial-path gap added two ordering tests, and the very next Test Quality pass flagged **exactly those two** as the only unfair tests in 48 - they pinned identifier-before-diagnostic WITHIN a candidate block, which no sentence states |
| L30 | **A test flagged as unfair has two repairs, and only one keeps the difficulty: state the rule, or delete the test.** Deleting is the reflex under review pressure and it silently spends your band. Check first whether the behaviour is already observable on base — if it is, the test is fair and the description is what is missing. | gluon-format-comments: the block-comment layout test was deleted in round A5 as pinning unstated layout, restored in A10 once meta stated the rule, then took **7 of 11** and was the sole failure of the closest near-miss. An agent contested it as an undocumented convention; the contest failed because the UNMODIFIED formatter already breaks that record |
| L31 | **A feature that invalidates an existing repo test manufactures a cheat trap.** The solver must update stale expectations to be correct, and editing repo tests is scored as cheating. Skipping those tests in base mode protects your numbers, not the solver. Prefer a contract that leaves existing expectations intact; if you cannot, expect to lose runs to PASS_CHEATED and say so in the submission notes. | gluon-format-comments: 3 runs across 2 batches scored PASS_CHEATED for editing `format/tests/pretty_print.rs`; 2 of the 5 tests they rewrote are ones the feature legitimately supersedes |
| L33 | **A mutation battery scoped to your NEW tests cannot see a baseline-preservation trap, and its silence reads as proof the requirement is vacuous.** An S3 trap's discriminator is an EXISTING test by construction, so run every mutation against BASE mode too. Corollary: "no fixture I own catches it" is a statement about your problem configuration, not about the repo. | sfepy-adaptive-stepping-accounting: removing the final-step clamp's `clear_lin_solver` left all 74 new tests green across four probed configurations (explicit/implicit stepper, cached/plain matrices, presolve on/off, `maxdiff = 0.0` every time), so the sentence was cut from meta.md and the code deleted as dead. The next base run returned **220 passed, 1 failed** on the repo's own `test_ed_solvers`, which uses `use_presolve: True` over five ED solvers. The trap was real; my own problem used the EXPLICIT velocity-Verlet solver with presolve off, where a stale factorization cannot change the answer |
| L32 | **A counterfactual over an old batch is valid only while the test suite is unchanged. Once it changes, run the differential harness instead.** Subtracting test names from an old failure list silently assumes the artifact the agents faced is the artifact you are shipping. | gluon-format-comments: projected 2/12 from batch-1 data after adding 11 tests, and batch 2 returned 0/14. Re-projected by APPLYING the near-miss runs' own patches to the reduced suite (two scored 37/37), and the next batch returned a legitimate pass |
| L34 | **A fairness disclosure is a difficulty DEBIT that settles one batch later.** Every clarification you write to clear a fairness flag also hands the fix for whatever trap that sentence was hiding. The edit looks locally correct and the collapse is invisible until the next batch. Pay the debt in the SAME round: when you disclose, add an orthogonal trap alongside it. | vrp-tsplib: three consecutive fairness rounds (DISPLAY_DATA_TYPE scoping, header-ordering, GEO restatement) took the display-data cluster 2/9 -> 0/10 and GEO 1/9 -> 0/10, leaving ONE surviving trap and a 50% batch. Also customasm L21, where the fairness fix and the difficulty collapse arrived together |
| L35 | **The differential harness measures a TEST-suite delta; it cannot measure a DESCRIPTION delta.** Replaying old passing patches through a hardened suite counts every agent who did not know the new rule -- but the next batch reads the new meta.md and most will implement it. Treat the harness kill count as an UPPER BOUND. When the hardening added a description sentence, discount it hard; when it only added tests for already-stated behavior, trust it. Refines L32, which prescribes the harness without bounding it. | vrp-tsplib: the ascending-node-order lever killed 3 of batch 11's 5 passing patches in the harness and **0 of 10** in batch 12. Those five never read the ordering sentence; the next ten did. **Largest instance measured:** datafixerupper-ordered-alternatives iteration 67 replayed both batch-8 passers against the reduced suite and BOTH failed (5 and 3 of 173), projecting **0/10 = unsolvable-reject**; batch 9 returned **5/10**. The projection was 50 points low because the round had rewritten the contract those two solutions were built against — when the description delta is a DELETION, the harness is not merely an upper bound, it is nearly uninformative |
| L36 | **Stale no longer means re-run: a tests-only round re-grades at ~30% via RE-EVAL, and the button's presence is the L35 test.** Editing `test.patch` / `solution.patch` leaves the agents' solving valid (same prompt, same repo), so the platform re-runs grading + evaluation over the last batch's solutions for roughly 30% of batch price. Editing `meta.md` / title / environment invalidates the solving and there is no button. Consequences: freeze the solver-visible surface BEFORE the first batch and iterate tests after it; never fire a smoke run while a re-eval is pending (any fresh run dismisses the offer); and treat re-eval as PAIRED steering over one fixed solution set, not a fresh sample — it cannot re-roll the batch variance that made one artifact read 22% and 50%. Operationalizes L32 (the differential harness, now run by the real grader) and mechanizes L35 (no button = your lever was a description delta). | Platform update 2026-09-03. Local precedent: gluon-format-comments needed a full batch to learn that dropping one printer axis turned 0/12 into a legitimate pass (L32); vrp-tsplib needed batch 12 to learn the harness had over-counted 3 kills to 0 (L35). Both are now re-eval-shaped questions |
| L37 | **An FP panel's defect report is DIFFICULTY, not just fairness debt — harvest it as a trap.** L17 says reviewer coverage suggestions are free difficulty; this is stronger. A false-positive finding names a behaviour a passing agent got WRONG, which is by construction a live discriminator, and the fix is a test you can write in an afternoon. Treat every FP report as a trap proposal, and re-read EVERY passer's diff for the same defect class -- the panel names the instance it can see, not the class. | go-workflows: the FP panel flagged one passer's `Select` regression; reading the other passers found the IDENTICAL defect in a second run the panel cleared (true FP count 2 of 3, not 1). The guard written from it became F-20 and decided the band (8/10, both near-misses). The trap I designed myself, the arrival-order queue, killed 2/10 |
| L38 | **When one fair trap kills ~100%, the lever is WHEN-discoverability, not deletion.** A cluster of tests failing in every run is not automatically over-strict: if it is one root cause and the contract already states the behaviour, agents are missing WHEN the behaviour must hold, not THAT it must. Restating the timing in the existing sentence, naming no API, is the cheapest lever measured on a 0% batch. | go-workflows scheduler-resumption cluster: 5/5 kills at batch 10 (0/5 overall). Changing "both proceed on their own" to "both **resume before the scheduler run that drained them finishes**" -- one clause, no new requirement, reference already conformed -- dropped it to **1-2/10** at batch 11 and the batch passed 2/10. Deleting the cluster was impossible: all 5 tests were one insight, so any subset left the near-miss still failing |
| L41 | **A promise about an object you do not own may be physically unimplementable — scope it to the implementations that can honour it.** Before writing a contract sentence about a caller-supplied abstraction, check whether that abstraction's own contract permits the effect. If any conforming implementation cannot exhibit it, the sentence is false for a whole family and no amount of implementation work repairs it; a reviewer reads the sentence, not the family. Put the general guarantee on the value you RETURN, and scope the convenience guarantee to the implementations that can carry it. Sibling of L39 (a contract sentence is a liability): L39 is about the reference failing a sentence it could satisfy, this is about a sentence nothing can satisfy. | datafixerupper-ordered-alternatives Iteration 57: meta.md promised "a caller who finishes the supplied builder still sees the failure". `RecordBuilder` returns a new builder from every operation, so a PERSISTENT implementation cannot be annotated at all - probe printed `SUPPLIED -> Success[{}]` beside `RETURNED -> Error['Alternative 0: bad']`. Solution Quality scored it a HIGH comprehensiveness defect. The tests had drawn the line correctly all along (supplied-builder assertions all used the mutable `JavaOps.mapBuilder()`, persistent cases asserted the returned builder); only the description over-promised |
| L40 | **A reviewer's suggested test is a hypothesis, not a spec: replay it against the saved PASSING patches before you ship it.** A defect finding in the REFERENCE is a solution fix and always safe; the regression test the same reviewer asks for is a difficulty change and can be fatal. Fixing the reference costs nothing in band; pinning the fix can cost the whole band, and the two arrive in the same paragraph as if they were one action. Run L32's differential harness on every suggested assertion, ship the ones the passers survive, and decline the rest IN WRITING with the measured kill counts. Refines L17 (reviewer coverage suggestions are free difficulty) with its exception: free only until it kills your last passer. | datafixerupper-ordered-alternatives Iteration 56: Auto Review filed an S1 High x3 on the MapCodec supplied-builder lifecycle and asked for "regression cases for each overload using a saved JsonOps map builder". The defect was real and the reference fix was ~30 lines. Replaying the three suggested cases against both batch-8 passers: **both fail all three**, and worse than the old reference did. Shipping them would have moved 2/10 to **0/10** = unsolvable-reject. The other 9 suggested/advisory tests were replayed too, both passers went 159/159, and all 9 shipped. Confirmed again on dfu-derived-recursion: the Blocker's suggested cross-group DataFix regression test failed the ONLY passing run (84 tests / 1 failure), i.e. 0/10 — the reference fix shipped, the test did not. |
| L39 | **A contract sentence is a LIABILITY as well as a fix — re-audit the reference against every sentence you add.** Adding a meta.md sentence to make a test fair also enlarges the surface the REFERENCE must satisfy, across the full domain of the new words, not just the scenario the new tests exercise. | go-workflows: the sentence added to justify three wake-up tests ("a value arriving while such a case waits must also run it") was immediately violated by my own reference on zero-capacity channels -- a parked Drain case was a progress-notification target but not a rendezvous target, so a nonblocking send was silently dropped. Caught by Solution Quality, not by me, one round after I wrote the sentence |
| L42 | **When a reviewer demands a test for a quantity the description leaves under-determined, the description edit comes FIRST and the test second.** A coverage finding of the form "nothing discriminates the sign / the normalisation / the convention" is really two findings: the suite is weak AND the prompt is ambiguous. Writing the assertion alone converts a fair problem into an unfair one, because the passing value was never derivable. Writing the sentence alone leaves the finding open. Do both, in that order, and say in the response which words you added. The edit is only free BEFORE the first batch (L36) - after it, a description edit costs a full-price batch while the test alone would have re-graded at ~30%, which is exactly the pressure that produces the unfair version. | rocketpy-propellant-slosh Round 5: Auto Review filed a High on "no assertion discriminates the force-per-total-mass drive coefficient", naming a sign reversal and a dry-mass divisor as passing wrong implementations. `meta.md` said only "driven by the body frame lateral force per unit mass acting on the rocket" - which fixes neither the sign nor whether gravity counts. Probing showed body-frame gravity at 5 degrees of tilt is 0.85 m/s2 against a real drive of 0.027, so a gravity-including implementation is a factor of 30 out and was passing. Added three clauses (total mass, gravity excluded, mode driven the other way) and then the tests; mutations m1/m2/m10 each die on exactly one of them |
| L43 | **To pin a WEIGHTED combination without reimplementing the physics, test its null space.** Reviewers ask for "assert the mass-weighted rate and acceleration enter the vehicle equations", and the obvious answer - recompute the 6-DOF right-hand side in the test - is both enormous and fragile. Instead build a state where the combination cancels under the CORRECT weights, and assert the downstream observable is bit-identical to the state where every term is zero; then build one where it does not cancel and assert the observable moves. The pair pins existence and weighting together, needs no expected value, and the tolerance gap is enormous: the correct weighting cancels to exactly 0.0 while an equal-weight implementation leaves a residue six orders of magnitude above the float noise. | rocketpy-propellant-slosh Round 5: two modes with participating masses in a 4:3 ratio. Velocities with `m1 v1 = -m2 v2` leave the 13 vehicle derivative entries changed by **0.0**; equal-weight cancellation leaves **2.4e-6**; a nonzero net rate leaves 9.5e-6. Same trick for the acceleration: displacements that cancel the OFFSET but not the accelerations move the vehicle by 0.037, which is only explicable through `r_CM_ddot`. Four tests, no physics duplicated |
| L44 | **Deleting an unimplementable contract clause costs BAND, and the bill arrives in the next batch — budget a replacement trap in the same round.** L41 tells you to scope or delete a promise nothing can honour; this is what that costs. The clause was carrying difficulty precisely because it was hard, and removing it also removes every test that pinned it. The correctness argument for deletion is usually airtight, which is what makes the difficulty loss invisible: no reviewer will mention it, and the artifact reads cleaner afterwards. Pair every soundness deletion with an orthogonal lever, exactly as L34 prescribes for fairness disclosures. | datafixerupper-ordered-alternatives: iteration 67 deleted the whole supplied-builder marking contract (an `ops.mapBuilder()` surrogate, ~140 lines) plus the 9 tests that asserted it, after **eight** consecutive Solution Quality rounds filed findings against it and the ninth named the mechanism outright. The deletion was correct — it fixed a real S1 and the P4 density flag at once. Batch 8 with the clause read **2/10 = 20%**; batch 9 without it read **5/10 = 50%**, at the ceiling. +30 points for one soundness fix |
| L45 | **The prompt sets SOLUTION QUALITY, not just fairness: softening a clause lowers how much machinery agents build, so a fairness edit can turn a passing batch into 0% with the tests unchanged.** When a batch collapses after a description edit, replay the OLD batch's saved solutions against the CURRENT suite before you touch a single test. If the old population still passes, the suite is fine and the prompt is the variable. Restore pressure with a clause that NAMES the surviving discriminators behaviourally while promising nothing about iteration counts or unbounded scale - the unbounded version is what generates the FP (L44's cousin, arrived at from the opposite direction: L44 is deletion costing band, this is SOFTENING costing band). | customasm-derived-bank-layout: 20 saved solutions replayed against ONE fixed suite. Batch 2, solved under "works whatever order the definitions appear in" (unbounded), scored **5/10**. Batches 3 and 4, solved after that clause was bounded to "a bank may be placed at the end of a bank whose definition appears later in the file", scored **0/10**. Same model, same tests, 15-point-plus swing from wording alone. All five batch-2 passers were probed against the reference on six stated-clause programs and agreed everywhere, so the higher rate was real capability, not luck |
| L46 | **Fix the reference for an integration finding; do NOT add a fixture for behaviour meta.md never names.** Solution Quality reports defects in directives, padding categories and output-stage edges the description never mentions. The reference fix is free and correct. The matching fixture turns an unstated requirement into a gate the whole population fails, and even when it changes no verdict it displaces the near-miss agent's blocker so the closest run stays stuck. Keep a written list of the nouns meta.md actually names and check every review-response fixture against it. Sharpens L40 (replay a suggested test before shipping it) with the prior question: is the behaviour even stated? | customasm-derived-bank-layout: I removed an `#addr` fixture on exactly this ground, then two rounds later added `err_backwards_addr_never_settles`, also `#addr`-dependent, in response to a reviewer finding. It killed 5/5 Nova, changed no verdict, and displaced the previous blocker so the closest Nova stayed at exactly one failure. Removing it plus the label-alignment extent fixture took batch 2 from **1/10 to 2/10** and produced the first Nova pass in 19 runs. The same discipline later SAVED the accepted pass: the FP adjudicator cleared it because the align fixtures only ever tested align WITH following content, ruling the trailing-align divergence "an underspecified edge... it cannot fairly gate the reward" |
| L47 | **Parametrise a "works for all forms of X" axis by what the IMPLEMENTATION distinguishes, not by what looks varied to a reader.** Spellings a human calls different are one cell to the code; the cells that kill are the ones the repo's own validator treats differently. | rocketpy: 7 callable spellings shipped, only `defaulted` and `keyword_only` killed (6/10 each); `partial`, callable-instance and `*args` killed nothing because `Function` accepts them. Read the wrapper's `inspect.signature` logic to find the boundary before writing the matrix |
| L48 | **A representation-tolerant reader in the test suite is FP-panel armour, not just fairness hygiene.** A helper that accepts every shape the contract permits is executable documentation of the permitted domain, and the adjudicator will cite it against a dissenting judge. | rocketpy FP panel: judge-c filed a solo `false_positive` on "no-slosh `slosh_mass` must be callable"; the adjudicator rejected it at high confidence *"contradicted by the verifier's OWN reported_slosh_mass helper, which explicitly accepts a bare 0"*. The helper had been added one round earlier purely to un-pin a representation |
| L49 | **A test that kills a run for a REPRESENTATION reason is visible in the run data long before a reviewer names it.** Treat "failed only on the shape of a returned value" as a fairness defect the first time it appears, not the third. | rocketpy batch 1: Nova #5 lost exactly the four `test_a_tank_without_slosh_has_no_participating_mass` cases by returning int `0`. The same pin was flagged by Test Quality at round 25, fixed at round 26, and was worth the whole band -- unfixed, batch 3 read **0/10 = reject**; fixed, the identical ten solutions read **1/10 = accepted** |
| L50 | **A bug a reviewer finds in YOUR reference predicts an agent failure mode — turn each one into a test.** You and the solvers face the same design pressure, so the mistake you made is the mistake they make. Every reference defect that got a regression test became a measured killer. | dfu-derived-recursion batch 2: the 3 tests written only to prove Solution-Quality findings took 4, 4 and 3 of 10 runs — 11 of 32 kill events — and grew the killing-test set from 5 to 8. The 79 tests the DESIGN was about killed nothing |
| L51 | **In a long review cycle most reference bugs are FIX-INDUCED: after each reference fix re-run the whole matrix AND the agent replay, and prefer deleting the mechanism over narrowing the guard.** A patch that adds a phase flag, a cached field or a mutable "current scope" to make one finding go away is the next finding. | dfu-derived-recursion: 4 of 7 reference bugs were created by the previous round's fix (lazy placeholder → NPE at registration → wrong-group resolution → lost identity wrapper). The chain ended only when the phase variable was deleted and placeholders were substituted eagerly |

---

## 4. ADDING A NEW PROBLEM (keep this file extensible)

After every batch, append. The file is only worth its measured counts.

**Step 1 — mine the batch.** Do this while the run view is open; the artifacts are the only source.

```bash
cd problems/<name>/<batch>
for d in */; do n=${d%/}
  python3 -c "
import json;d=json.load(open('$n/eval-result.json'))
print('$n', d.get('details',{}).get('kind'), '|', (d.get('quick_failure_summary') or d.get('summary',''))[:160])"
done
```

**Step 2 — classify.** Map each failure to an existing `F-` ID. A failure that matches nothing is
a candidate new pattern — but only promote it once it has killed in **two independent runs**;
one-off failures are agent noise.

**Step 3 — update § 1.** Add your kill count to the pattern's evidence line, in the form
`<problem>: n/m runs`. Never overwrite an existing count — patterns earn weight by accumulating.

**Step 4 — add a dossier to § 2** using this skeleton:

```markdown
### <problem-name> (<language> / <domain>) — <ACCEPTED | REJECTED | SHELVED>

| | |
|---|---|
| Shape | |
| Final artifact | <files>, <effective LOC>, <tests> |
| Pass-rate history | <batch → rate, showing every lever> |
| Patterns used | <F-ids, lead first> |
| Agent split | <per-agent solve counts> |

**Why it held / why it did not.**
**What the batches taught.** (only findings that generalise)
**Reference bugs found.** (count + one line each — these predict your FP risk)
```

**Step 5 — promote to `HARDENING.md`** only when a pattern has kill counts from **two different
problems**. Until then it lives here as problem-specific evidence. Demote to the DEAD list in
`TOO-EASY.md` if a pattern reads >40% twice.

---

## 5. TARGETING TABLE — pick by what the repo gives you

| Repo has… | Reach for | Expected |
|---|---|---|
| A pipeline stage that destroys info a later stage needs | **F-1** | Largest single lever measured (+27 pts). Overshoot risk — disclose the root cause |
| A construct that is producer AND consumer | **F-2** | ~50% kill; needs a real fixed point |
| An options struct with an existing boolean `with_*` setter | **F-16** | 4/10, but a COMPILE error — bonus only, never the lead trap |
| A contract property your helper can only compute via a structural proxy | **F-17** | 8/10 top killer; write the helper in the contract's vocabulary |
| A public interface with NO accessor for the state your rule quantifies over, plus an abstract base class in the repo that holds it in a field | **F-21** | 5/10 top killer and sole near-miss failure on datafixerupper. Costs a ~30-line conforming test helper OUTSIDE the base class and a four-word clause ("whatever `X` the caller supplies"). Grep the interface for a getter first — if one exists the pattern is dead |
| A lookup that throws on a missing key with NO repo test covering the throw, plus a feature that must traverse the same namespace before every key is known | **F-24** | 8/10 in two independent batches on dfu-derived-recursion, and four runs failed ONLY this pair. Costs one clause naming the semantic difference. Verify the gap the F-20 way: break the throw, confirm the base suite still passes |
| A feature that forces deferred resolution, where the placeholder is returned through a public API the caller can store in a local or memoize | **F-25** | 4/10 + 4/10 on dfu-derived-recursion. Zero description words. Test a retained reference reused in a LATER registration, and one that closes a cycle; take it AFTER its target is registered or the test becomes unstated |
| An exemption spanning two collections | **F-3** | ~28% kill, one sentence, free |
| A `RefCell`/aliasing-graph IR | **F-4** | ~18%, kills whole runs; needs an in-repo correct example to stay fair |
| Analysis flowing through a non-sink node type | **F-5** | ~12%; add the off-name instance (L6) |
| Two documented transforms with an unstated order | **F-6** | Pair with the degenerate input to turn a wrong answer into a crash |
| Suppression contexts across several pipeline stages | **F-7** | Test the NESTED case — that is where references break |
| A pervasive "value or provider" container (`Function`, `Supplier`, `Lazy`, a coercion helper) that validates by signature/type introspection | **F-23** | 6/10 on rocketpy, reproducible across batches and solver families. Grep the container for `inspect.signature` / arity checks to find the spellings it refuses; those are the kill cells. BINARY axis — it flips all runs or none, so never plan to soften it |
| An inline `mod tests` in the file the feature forces you to rewrite | **F-12** | ~30% kill, free, invisible in your own validation. Skip only the tests the feature invalidates |
| Two or more variable-extent sub-parts in sequence, each resolvable several ways, under a documented preference metric | **F-11** | Band decider on customasm (9/10 on ONE fixture); single-sub-part tests cannot discriminate |
| A feature bordering a famous named external algorithm/spec, where the repo's real behaviour deliberately diverges | **F-8** | ~90% kill on ONE sentence, cheapest lever measured; pair with an orthogonal integration trap, do not ship alone |
| A validating stage and an emitting stage in different packages, where the repo already re-resolves the same thing at the LATER stage for the ordinary path | **F-9** | ~60% kill; one root cause breaks every capability at once, so interdependence comes free |
| A repo with an EXISTING iterate-to-fixed-point resolver over ≥2 quantity kinds, where the new quantity and the old ones can depend on each other | **F-22** | 8 of 9 failing runs on customasm-derived-bank-layout and the sole cluster behind both near-misses. Build MIXED chains (through a function, through a constant, forward reference); a direct A-to-B chain discriminates nothing. Never promise an iteration bound - that clause is what caused the FP |
| A contract of the form "X must work for all forms of Y", where the forms have ≥2 axes (one with multiplicity, one with polarity/direction) | **F-10** | Costs ~20 test lines and ZERO description words; decides the band by killing the 20/21 near-misses. Author this in EVERY problem that has two axes |
| A format parsed in two tiers — a base declaration plus amendment rows that override its fields (Breakpad CFI INIT+delta, patch hunks, cascading config, `@media`) — and a validity rule an amendment alone can break | **F-13** | Top killer measured on rust-minidump (6/10), 3 of them sole-failure near-misses at 48/49. Put the contradiction in an AMENDMENT row; the header twin costs nothing and proves fairness |
| Several existing "cannot continue" exits, plus a NEW externally-declared reason to stop | **F-14** | ~30%. Agents wire the declared state to every giving-up site. Couple the output rule to the ordinary state so a merge breaks output too |
| Any "allow one, stop at the second" tolerance rule | **F-15** | ~40%. Author the ONE-event fixture and assert the walk continued — the two-event fixture cannot discriminate (L25) |
| A shared entry point whose logger/writer targets a GLOBAL channel (stdout `println!`, package-level writer), AND a new command that must emit STRUCTURED output on that same channel, AND reuse of that entry point is right on every other axis | **F-19** | Most durable killer measured: 36/52 runs across 4 batches, never below 50%, never ruled unfair. Contract-state the OUTPUT, never the channel discipline; assert from a SUBPROCESS test that parses whole stdout -- an in-process assertion cannot see it and the trap evaporates |
| An existing public API whose behaviour is documented in prose but has NO repo test, plus your feature adds a sibling entry point that deliberately differs on one rule | **F-20** | Band decider on go-workflows (8/10, and the SOLE failure of both near-misses). Zero description words -- scope the rule to the new API by naming only it. Guard the OLD api in both directions |
| Two or more lexical spellings of one concept the contract treats as equivalent (line vs block comments, short vs long flags, quote styles) | **F-18** | Decided the band on gluon (7/11, and 22 of 37 total kills). One test per position per form, ZERO description words beyond a single equivalence sentence |

**Ship-in-every-problem shortlist.** F-10 has no precondition worth calling a precondition —
almost every multi-capability contract has two axes — and it is the only pattern measured to
separate near-miss agents from passing ones. Treat "did I test the off-diagonal cells?" as a
checklist item, not a design choice.

**Anti-targets** (from these three problems, consistent with `TOO-EASY.md`): a fully enumerable
rule set implementable rule-by-rule; any feature where the meta must list N independent
behaviours; anything a post-pass over the public event/AST stream can do end to end.


### customasm-ruledef-disassembly (Rust / custom-ISA assembler) — ACCEPTED 2026-08-03

| | |
|---|---|
| Shape | O-Algorithm-correctness; new subsystem (ruledef-driven disassembly) + driver/help/web integration |
| Final artifact | 7 files, 493 effective LOC (Counter 2), 54 fixtures |
| Pass-rate history | 0/13 → 90% → 20% → 57% → **9% (1/10)** across five batches |
| Patterns used | F-11 (lead, 9/10), F-10 cross-product cells, F-9 cross-stage drop, F-2 fixpoint/termination |
| Agent split | Orion 1/4 pass, Nova 0/6, 1 env-failed run excluded |

**Why it held.** The final batch produced TWO separated failure clusters — near-miss (1-2 fails,
5 runs) and deep (18-19 fails, 4 runs) — instead of the single 13-test cluster that made earlier
batches swing. The near-miss cluster was unanimous on F-11; the deep cluster was the slice-form
wall.

**What the batch taught.**

1. ⭐ **A single-seam problem is BIMODAL, and its pass rate is a coin flip, not a difficulty.**
   Batches read 0/13, 90%, 20%, 57% while the artifact only improved. Diagnosed from agent-runs 3,
   where all three failing agents failed the IDENTICAL 13 tests — every one depending on the same
   decision (recognising exact-width slice forms, which also bound nested fields). Pass rate was
   `P(agent handles slice forms)`. The tell is a per-test kill table where the killers are perfectly
   correlated. Adding tests to that seam cannot stabilise it; they all die together.
2. ⭐ **A clarifying EXAMPLE appended to a general rule silently narrows it, and can disarm the
   whole problem.** Round 3 added "and spelling that width out explicitly leaves it whole" to repair
   a genuine 0/6 unfairness. It was correct and necessary — and it took the batch to 90%, because
   that one seam carried all the difficulty. Later, "contributing fewer than that does not" was a
   one-sided example on a rule that said "exactly", which would have licensed a `>=` implementation.
   Both were fixed by deleting the example and keeping the rule (Rule-7 applied to examples, not
   just to instance lists).
3. **Reviewer and FP-judge suggestions produced the decisive test.** F-11 came from an FP-panel
   dissent, not from the design. It then killed 9/10. L17 again.
4. **65% of the suite killed nothing** (35 of 54). Every eligibility/rejection fixture — computed
   output, repeated parameter, omitted parameter, unsized constant, over-wide and under-wide slices,
   untyped parameters — killed ZERO. Those cost several review rounds each. They are correct and
   FP-necessary, but they bought no difficulty, and the next problem should not spend rounds there.
5. **Every hardening round found a bug in the reference, not just in the tests.** Seven: greedy
   nested commitment, eager tie marking before viability filtering, unbounded nested ranking,
   i128 operand truncation, stack overflow on cyclic ruledefs, ignored address unit, and an
   over-broad wrapper exclusion. Each would have been an FP.

**Reference bugs found: 7** (listed above), all caught by trap-proofing or by probing a reviewer
finding rather than by the test suite.

---

## Candidate patterns (unpromoted — single-source, from a sibling workspace's early-stage trap log)

**These are UNCONFIRMED, single-observation candidates, distinct from the F-1..F-18 catalogue above.**
The F-numbered entries above are proven, multi-run-confirmed patterns (each backed by 2+ independent
agent kills). The C-numbered entries below were logged from a sibling workspace's early-stage trap
journal (`FAILING-PATTERNS.md`) after only ONE observed agent run each (unless noted). They are kept
here as leads to watch for a second confirmation, NOT as validated trap classes — do not treat a
C-id as equivalent in strength to an F-id, and do not renumber or merge them into the F-sequence.

### C-1 · Existing-model field-contract inversion (seen: syncpack-pnpm-override-selectors · Nova)
- Symptom: 803/803 baseline + 36/37 new. ONE new test failed. JSON reported the pnpm override
  as `qar>zoo` instead of dependency `zoo`.
- Root cause the agent missed: agent stored the original selector key in `descriptor.name` and the
  target package in `internal_name` — inverted from the established descriptor model where `name`
  is the actual dependency and `internal_name` is reserved for grouping aliases.
- Misdirecting? YES — the emitted string (`qar>zoo`) is structurally plausible, so the mistake is
  invisible except to the one assertion that checks WHICH field carries the dep name.
- Single-point-fixable? Borderline — only 1/37 caught it, so 36/37 pass, this ALONE is a weak
  (~high-pass) trap. Belongs stacked on top of other traps, not as the sole difficulty.
- Reusable as a CLASS: reuse an existing data structure whose field SEMANTICS are defined
  elsewhere in the repo; make the correct solution populate those fields per the existing
  contract. Agents that infer field meaning from the local task (not the model) invert them.
  Fair only if the field contract is inferable from visible code (<=1 codebase-inferable req).
- Hardening note: to make this bite, add MORE assertions that pin the field contract across
  entry points (JSON output, fix output, grouping) so a single inversion fails several tests,
  and stack it with an orthogonal trap so 36/37 can't slip through.

### C-2 · Scope-establishment vs name-uniquification (ACCEPTED in the source workspace — customasm-for-directive · Nova)
- Status noted by the source workspace: shipped/approved there, so the trap held under review at
  that tier. Kept here as a candidate anyway since it has not been confirmed inside THIS workspace.
- Symptom: 691/691 baseline + 81/94 new. 13 new tests failed, all around per-iteration local
  scope (`deferred_bound_with_per_iteration_local_label`, dotted `.local` labels/constants).
- Root cause the agent missed: the feature requires each loop iteration to establish a TRUE
  independent nested scope. Agent took the shortcut of uniquifying local names with numeric
  suffixes in the existing flat namespace, leaving them as hierarchy-level locals with no
  per-iteration PARENT scope — so top-level loop bodies containing `.local` symbols couldn't
  assemble.
- Misdirecting? YES — the suffix/uniquify approach passes 81/94 (all the simple cases), so it
  looks basically correct; only tests where the scope STRUCTURE itself matters expose it.
- Single-point-fixable? NO — the fix is a different model (insert a real parent scope per
  iteration), not a local patch.
- Reusable as a CLASS: for any "repeat / instantiate / expand a body N times" feature (loops,
  macros, generics, templates, inlining), the correct impl must create a real nested SCOPE per
  instance; the tempting shortcut is flat name-mangling. Add tests that exercise scope BOUNDARIES
  (symbol visible after the block? shadowing across iterations? dotted/hierarchical locals at top
  level? forward refs across the boundary?) — mangling passes the easy ones and fails these.

### C-2 (dup id in source) · Misplaced authoritative-rule scope (seen: syncpack-pnpm-override-selectors · design bet, not agent-confirmed)
- Shape: a rule ("X is authoritative / X wins") is CORRECT only for a subset of inputs; a separate,
  higher-priority branch handles the excluded subset. The reference is right only because the rule
  sits at the narrow call site the excluded branch never reaches.
- Trap: the obvious implementation places the rule too broadly (at the group winner / globally /
  early in the visit) and silently REGRESSES the excluded subset.
- Concrete: override-of-a-locally-developed-package must LOWER the override to the local version; a
  global "override always wins" forces the local package UP instead.
- Misdirecting? Yes — the wrong output looks like the documented rule working, just on the wrong
  instance. Single-point-fixable? No — moving the rule to the correct site is a design decision, not
  a one-line patch; and it interacts with the excluded branch.
- Reusable as a CLASS: any feature with a precedence ladder (pin > override > default, local >
  everything). State the full ladder in the description; test the EXCLUDED subset (the
  highest-priority branch) so a too-broad placement fails.

### C-3 · Cross-grammar / cross-source same-entity conflict (seen: syncpack-pnpm-override-selectors · design bet, not agent-confirmed)
- Shape: the same logical entity is expressed through TWO different input grammars/sources that
  group into one unit; a "winner" is chosen; every loser must be written back at its OWN distinct
  location/format.
- Trap: an agent wires ONE write-back path (the grammar it noticed) and the other loser silently
  no-ops. The winner-selection looks done.
- Concrete: one package overridden in pnpm flat yaml AND npm nested json; highest wins; the pnpm
  loser must be raised at its yaml key while the npm winner stays in the json tree.
- Misdirecting? Yes — the winner is correct and one location updates; the missed location is
  invisible unless a test reads it. Single-point-fixable? No — the two persistence paths are
  separate code, and both must also agree with the winner.
- Reusable as a CLASS: when a grouped unit spans >1 serialization, always assert the on-disk result
  in EVERY source format after a fix, not just one.

### C-4 · Unicode-category classification misses ASCII / context-dependent chars (source workspace notes this as PROMOTED to its own T3; kept here as an unconfirmed candidate in THIS workspace — confirmed 2 Nova runs at the source: Run 1 + Run 3)
- Symptom: 57/57 baseline + 31/32 new. ONE new test failed:
  `hanging_first_shifts_the_opening_quote_into_the_margin` — a leading ASCII `"` in `"hello"` did
  not hang for `HangingPunctuation::FIRST`.
- Root cause the agent missed: `is_opening_punctuation` accepted only Unicode
  `GeneralCategory::OpenPunctuation` + `InitialPunctuation`. The ASCII straight double quote
  `U+0022` is `OtherPunctuation`, so it was excluded. Reference handles context-dependent straight
  quotes with an EXPLICIT character set on top of the category check.
- Misdirecting? YES — classifying by Unicode GeneralCategory is the "textbook-correct" move and
  passes every fancy `(` `[` `"` `'` case; only the plain ASCII quote (mis-categorized by Unicode as
  OtherPunctuation) fails. The agent even wrote a focused hanging test — using `(`, so it
  self-confirmed the wrong classifier.
- Single-point-fixable? Borderline — 31/32 pass, so ALONE it's a weak (~high-pass) trap. But the
  mistake is a natural one (trust the Unicode category), fair, and not obvious from visible tests.
- Reusable as a CLASS: any feature that classifies characters/tokens by a STANDARD category table
  (Unicode GeneralCategory, `char::is_*`, a lexer class) where a few real-world members are
  mis-categorized (ASCII straight quotes as OtherPunctuation, `_` in identifiers, `-` in dates). The
  obvious impl uses the table alone; the reference adds an explicit exception set. Test the
  mis-categorized members specifically.

### C-5 · Unstated public-API signature = COMPILE-WIPE — FAIRNESS HAZARD, not a difficulty trap (seen: parley-justification-modes · Nova)
- Symptom: baseline green, ALL new tests fail to compile (0/N) with a single Rust E0308 at the
  shared test helper. Source example: agent used `StyleProperty::TabSize(TabSize)` vs expected
  `TabSize(f32)`.
- Why it's a HAZARD not a trap: the whole new-test file compiles as one unit, so one wrong enum
  payload / return type / arity zeroes every test at once — 0% for a reason unrelated to the actual
  difficulty. Different agents guessing different shapes gives an artificially collapsed pass-rate
  = unfair.
- This is NOT a difficulty lever. State the exact new public API in the description: enum payload
  types, function arity + return type, error-variant shapes. Keep it <=1 codebase-inferable
  requirement (a strong repo convention helps, but STATE it so the wipe can't happen).
- Detection: any run reported as an all-new-tests-fail-to-compile integration error. Treat that
  batch's pass-rate as INVALID until the API is documented, then re-run.
