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

`cwerg-bcopy-bzero-lowering` adds a Python identity variant: IR instructions define `__eq__` as an
identity ASSERT, so `bbl.inss.remove(ins)` on the constant-zero path dies inside `list.remove`
(**2 of the first 5 runs** in batch 1, **1/10** in batch 4, which failed 8 of 13 cases). The repo's own
passes rebuild `bbl.inss` as a new list or slice it by position (`cfg.py`, `liveness.py`, `ir.py`), which is the in-repo correct example.

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

`mwparserfromhell-site-aware-parsing`: **2 of 19 runs** left unrecognised XML tags as Tag nodes in
some contexts (list items, table cells, headings, inside a recognised tag body). The designed F-7 site,
a stray closing `</foo>` inside a recognised body, killed 2/19; the eight other context tests killed
at most 1 each, always inside runs already failing 15+ tests.

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
the result away at the stage boundary. ir-sim-scenario-events: **0/11** on its origin variant (`reset(random=True)` returns early past a re-arm added to `reset()`, and `reload()` must re-read the events); every agent wired all three lifecycle paths once the prompt named them.

planetiler-custommap-schema-composition: **3/10 runs** (rd73pngb, rd746wb2, rd7es6yf) on
`validator_resolves_examples_of_a_standalone_bundled_schema`. The loader resolved `shortbread.yml` as
a bundled resource, and the validator later re-resolved its `examples: shortbread.spec.yml` string
against a filesystem `Path`, having lost the bundled origin at the stage boundary. Verbatim
(rd7es6yf): *"SchemaValidator retains a String examples value and resolves it against
schemaPaths.getLast() rather"* than the bundle. The reference made the same mistake at round 4 (L50).

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

`ray-optics-formula-conditionals` adds a NUMERIC-domain variant, **3/10 in batch 3**: the repo's
derivative code expresses "a equals b" as a nonzero guard on `a - b`, and agents reused that idiom for
the comparison switching set. For finite operands whose difference overflows (`x < -x` at 1e308) the
guard sees infinity and marks a point that is not a switch invalid. Verbatim, Nova #8:
*"derivative.js:242-245 builds guardNonzero(left - right, value)"*. The reference made the same
choice until a round-10 Solution Quality finding (L50); a guard on a `!=` node cannot overflow.

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

`ray-optics-formula-conditionals` adds a CODE-GENERATION cell: axis 1 = the new node's lowering
(plain f32 when the range analysis proves it valid), axis 2 = its operand's lowering (wrapped when
the operand may be invalid). The cell is a VALID comparison over a MAYBE-INVALID operand,
`fallback(1 / x, 7) < 8`, where the raw comparison must read the wrapped operand's `.value`.
**6/10 in batch 3, 6/10 in batch 2, 5/11 in batch 1**, and the SOLE failure of the 94/96 near-miss
(Nova #9: both failing tests are this cell). Several runs defined an `asF32(id, states)` helper in
their own patch and never called it on the new node. A grammar cell killed 2/10 more: comparisons
inside a VARIADIC call argument (`max`/`min`), whose production still called `parseAdditive` after
the fixed-arity path had been updated.

`sfepy-adaptive-stepping-accounting` adds a HOSTILE-HOOK cell: axis 1 = the adaptive retry and
final-time bounds, axis 2 = a user `adapt_fun` that overshoots. Three words of contract cover it
("whatever `adapt_fun` sets"). **7 of 13 runs** failed it: 6 on the overshoot retry, where
`min(ts.dt, attempt_dt)` gives a retry EQUAL to the rejected attempt when the hook proposes a larger
step, and 2 on a hook setting twice the final time, which left `ts.time` at 9.0 against `t1` 4.0. It
was the sole failure of the 116/117 Vega run, and 6 of the 7 also missed F-34. Description reviewers
asked for that clause to be cut three times (L26).

`mwparserfromhell-site-aware-parsing` adds a TWO-PATH cell: axis 1 = the leading-colon escape,
axis 2 = where the namespace is computed (at parse time vs after `node.title = ...`). Both halves are
stated in one sentence each. **All 5 Vega runs** returned 0 for `node.title = ":File:Foo.png"`; every
one handled the colon on the parsed link and on plain reassignment. It was the sole failure of two
189/190 Vega runs. No Nova run missed it.

**Arsenal mapping.** HARDENING S2 (composition of documented rules).

`kira-loop-crossfade` adds a LIVE-CHANGE cell: axis 1 = the shortened wrap (a crossfaded pass is
loop - L frames), axis 2 = a handle switching to a loop region that ends before the current
playhead. Each half is one stated sentence. **1/10** (Nova #6, the sole failure of a 54/55 run): the
wrap subtracted the full loop length once and added the fade once, so after the switch to loop 9..11
the position stayed past the new end; the reference keeps stepping by (loop - L) until it is inside.
It was the ONLY genuine kill of the batch. Every rule stated on its own was transcribed by all ten
runs.

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
`FAIL_MISSED_REQUIREMENT` -- the only two regression verdicts in the batch. ir-sim-scenario-events: **0/11** on "objects added with `add_object` stay" across an event undo; stated in one sentence, nobody over-reset.

Also `pyfakefs-block-inode-accounting`: **3/10 runs** (accepted batch). The feature makes
`create_dir` all-or-nothing, while the contract keeps `add_real_directory` stepwise; both import
paths build their target's ancestors THROUGH `create_dir`, so a deep import that runs out of inodes
takes back ancestors it should keep. Evaluator on Nova_8: *"adds an OSError cleanup loop in
create_dir that removes all newly created directories, and leaves _create_fake_from_real_dir calling
create_dir(target_path)"*. The reference had the identical bug until Solution Quality found it (R17),
and the probe of batch-2 solutions showed 3/14 more. The shared helper was the REPO's, not the
agent's, which is the variant worth knowing: no refactor is needed for the leak.

Also `datafixerupper-derived-recursion`: base wraps every registered template in
`DSL.named(name, ...)`, so type identity carries the registered name; rebuilding the assembly path
dropped that wrapper and two structurally identical recursive types became indistinguishable to
`TypeRewriteRule.ifSame`, letting a fix aimed at one rewrite the other. **3 of 10 runs** failed
`a_fix_targeting_one_recursive_type_leaves_its_twin_alone`. No base test covered the wrapper --
the reference lost it too, and only a reviewer caught it. Generalises F-20 beyond sibling APIs:
ANY rewrite of an assembly path can drop untested behaviour the path was carrying.

Also `pyocd-sequence-expression-kernel`: **3/10 runs** in the accepted batch plus Vega in batch 1,
at ARGUMENT level: the width rule for `DAP_JTAG_Sequence`'s sent bits leaked onto the sibling `tms`
argument, which base forwards to the probe unchanged. **This one was an accident.** The tests passed
`tms=3`, outside the probe API's documented "Either 0 or 1", and the CMSIS-DAP layer itself does
`tms & 1`, so the agents' masking was defensible. Evaluators still judged it fair (calls are
observable; base forwards `tms` untouched). Verbatim, Nova #5: *"masks the TMS argument from 3 to 1
before calling the probe"*. It was the SOLE failure of one near-miss (147/150). See L92.

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

**Counter-evidence, planetiler-custommap-schema-composition: 0/10.** "Every argument is settled
together after composition, so a default may refer to an argument another file defines" looked like
this pattern and killed nobody: the repo's `Contexts.buildRootContext` already runs the fixed point
AFTER the new merge, so the solver only had to merge maps. F-22 needs the solver to build or extend
the fixed point itself.

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


### F-26. Correlated operands estimated as independent intervals ★ top killer on ray-optics-formula-conditionals (7/10, after 5/10 and 5/11 in two earlier batches)

**Mechanism.** The repo owns an interval (abstract-interpretation) estimator over a DAG that SHARES
nodes, so `x < x` or `sin(x) != sin(x)` reaches the new operator as one node on both sides. Agents
extend the estimator the idiomatic way: estimate each operand, then combine the two intervals. Two
independent copies of `[lo, hi]` overlap, so the comparison is estimated as possibly true AND
possibly false, and a branch it can never select is kept. That branch's values and invalidity leak
into the enclosing range.

**Why it misdirects.** Combining two operand intervals is correct for every operand pair except
the identical one, and the base estimator is dependency-blind everywhere else (the textbook interval
"dependency problem"), so nothing in the repo suggests the case exists. The failing assertion reads
as an invalidity-propagation bug (`maybeInvalid` true where false was expected), which sends the
agent to the `if` branch-union code rather than to the comparison. The second killer,
`an_invalid_parameter_does_not_revive_an_impossible_branch`, failed in the SAME seven runs because
one of its three forms is a self-comparison: two test names, one cause.

**Evidence.** `ray-optics-formula-conditionals` batch 3: **7 of 10 runs**
(`self_comparison_branch_is_unselectable` 7/10 and
`an_invalid_parameter_does_not_revive_an_impossible_branch` 7/10, identical run set). It reproduced
under three different descriptions: batch 2 5/10, batch 1 5/11, plus 7/11 on the sibling
`an_identical_comparison_over_an_invalid_operand_is_invalid` in batch 1. Verbatim: Nova #3 *"the
patch's estimateComparison has no identical-node special case"*; Nova #5 *"`restrictComparison`
only handles two distinct bare parameters (`leftNode.name !== rightNode.name`)"*; Nova #8
*"range-estimator.js lacks identical-comparison handling"*. All seven evaluators marked it described
AND code-inferable. The seam was first found in the REFERENCE, by a round-4 Solution Quality finding
(L50).

**Precondition.** An estimator (interval, sign, nullability, type set) over an IR that shares
identical subexpressions, plus a new operator that is exact on identical operands but not on
independent operands with equal ranges: comparisons, equality, subtraction, `min(a, a)`. Confirm the
sharing first: build `x < x` through the repo's builder and check both operand ids are the same
node. Without sharing, identity is expensive to detect and the test turns unfair.

**How to build.** State the consequence, not the case: "a branch counts as unselectable when the
condition's estimated range cannot select it" plus "comparison ranges are subsets of {0, 1}". Test
three forms (`x < x`, `x >= x`, a shared non-parameter subexpression), asserting both the estimated
range and the evaluated values. Never write "identical operands" in meta.md; that phrase is the fix.
Scope the claim to node identity, not algebraic equivalence, or your own reference cannot meet it.

**Arsenal mapping.** HARDENING A4 (representation semantics) x S6 (two evaluators): the concrete
evaluator gets `x < x` right for free, the estimator does not. Costs zero description words.


### F-27. Polarity copied from the sibling combinator ★ 6/10 on ray-optics-formula-conditionals, RISING across three batches (3/11, 3/10, 6/10)

**Mechanism.** A flow-sensitive refinement pass narrows parameters inside the branch a condition
selects. `and` narrows its TRUE branch (every operand holds there); `or` can narrow only its FALSE
branch (every operand fails there). Agents build `and` first, derive `or` by symmetry, and apply the
operands' restrictions to the `or` true branch too, where only one operand is known to hold. The
range there becomes too narrow: unsound, not merely imprecise.

**Why it misdirects.** Symmetry with `and` is the right instinct for every other part of the
combinator (short-circuit values, truth sets, derivative 0, WGSL lowering), so the one asymmetric
rule is the part copied without thought. The failure surfaces as a missing hazard (`maybeInvalid`
false where a division by zero is reachable), which reads like wrong bound arithmetic in comparison
narrowing, two functions away from the `or` arm. The description stated the rule outright ("`or`
into the branch where it fails"), and the kill count ROSE when the redesign made that sentence
shorter and clearer.

**Evidence.** `ray-optics-formula-conditionals`: `disjunction_does_not_narrow_the_true_branch`
**6/10** in batch 3, 3/10 in batch 2, 3/11 in batch 1. Batch 3 also:
`disjunction_narrowing_composes_through_a_dependent_comparison` 2/10,
`disjunction_narrows_the_false_branch` 1/10. Verbatim: Nova #4 *"conditionContexts() narrows an OR
true branch via leftTrue"*; Nova #6 *"`restrictCondition` handles `or` with a `desired` true case
that narrows both alternatives"*; Nova #8 *"range-estimator.js:147-150 narrows the true branch of
or"*. All marked described AND inferable.

**Precondition.** A refinement / narrowing / type-guard engine (interval ranges, TypeScript-style
narrowing, null-flow) into which you add a DUAL pair of combinators (`and`/`or`, `all`/`any`,
`every`/`some`), where the sound refinement for one polarity would need a union the pass does not
build, so the right answer there is "no restriction".

**How to build.** State both polarities in ONE sentence with one verb ("`and` passes them into the
branch where it holds and `or` into the branch where it fails"), so the rule is explicit without the
asymmetry being highlighted. Test the `or` true branch with a hazard reachable through only one
operand and assert it is still reported; add the false-branch positive twin so a "never narrow `or`"
implementation fails too.

`cwerg-bcopy-bzero-lowering` shows the same copy-from-sibling failure without any polarity: `bcopy`
derived from the one-cursor `bzero` loop advances the destination and never the source, so an
upward copy writes `aaaaaaaa` for `abcdefgh`. **1/10 in batch 4, 1/9 in batch 5, 1/10 in batch 6**; in
batch 6 the bug is in both the Python and C++ twins (the port copied it). Verbatim, batch 6 Nova #4: *"both
FunExpandByteOps implementations add a source load in the positive body and increment dst_iter, but
add no positive-body increment of src_iter."* Costs nothing: any overlap or distinct-byte copy fixture
catches it.

**Arsenal mapping.** HARDENING A-tier polarity inversion x S2 (composition of documented rules).
Pairs with F-10: polarity crossed with composition order killed separately (2/10).


### F-28. Composite concept split into sibling container keys ★ top killer on worldengine-orographic-precipitation (7/10, after 4/10), the SOLE failure of all four 63/66 near-misses

**Mechanism.** The contract names ONE thing (a layer, a record, an entry) that carries two parallel
components, plus one setter taking both. The repo keeps its concepts in a keyed container and already
ships composite value types for multi-part concepts. Agents store each component under its own key
instead (`layers["wind_direction"]`, `layers["wind_strength"]`). The accessors, the simulation, the
drawing and even the serialised VALUES all still work. Only a check that reaches the concept through
the container by its name fails: `layers["wind"]` after a round trip, the round-tripped key set, the
layer object's equality.

**Why it misdirects.** The failure is `KeyError: 'wind'` inside a protobuf or HDF5 round-trip test, so
it points at the serialisers, and the agent's serialisers are correct. Every public accessor the agent
exercised returns the right arrays.

**Evidence.** worldengine-orographic-precipitation: **batch 2 7/10 runs**, the only failure of Nova #2,
#3, #4 and #5 (63/66 each); **batch 1 4/10**. Every evaluator marked it
`was_mentioned_in_description: true` and `was_inferable_from_codebase_excluding_tests: true`.
Evaluator, batch 2 Nova #2: "The reference architecture uses one composite wind layer containing
direction and strength; the public accessors can still expose those arrays." Auto Review scored Tests
3/3 and called the `layers["wind"]` checks "fair and discoverable from the singular wind-layer contract
and the repository's semantic-layer model".

**Precondition.** A keyed container of named concepts (`World.layers`, a component registry, a record
map) with at least one EXISTING composite value type (worldengine: `LayerWithThresholds`,
`LayerWithQuantiles`), and a new concept with two or more parallel components.

**How to build.** Name the concept in the singular with its components ("a wind layer with a direction
and a strength per cell") and give it ONE setter taking both. Test it through the container by NAME
after a serialisation round trip: key-set equality and object equality. Never name the composite
class. Grep for the existing composite type first: without that precedent the check is a
representation pin and L49 applies.

**Arsenal mapping.** A-tier, F-16 family (a shape the repo demonstrates), but observable at the
data-model level instead of as a compile error. It kills three tests, not the suite, so near-misses
stay near, which is what lets it decide a band.

---

### F-29. Declared applicability guard never consulted on the direct call — 3/20 on worldengine-orographic-precipitation (2/10, after 1/10)

**Mechanism.** The repo gives every simulation an applicability predicate next to `execute`, and
nothing calls it: worldengine defines `is_applicable` 8 times at base with zero call sites. The contract
adds a keep-what-the-caller-supplied rule ("a world that already carries winds keeps them"). Agents
write the predicate correctly (`not world.has_wind()`) and copy the siblings' unconditional `execute`,
so a direct call overwrites the supplied value.

**Why it misdirects.** The predicate reads as the implementation of the rule and it is right; eight
sibling classes confirm the shape. Only a direct `execute` on a world that already carries the value
shows the gap.

**Evidence.** worldengine-orographic-precipitation batch 2 Nova #6 and #7 (62/66 each, with F-28),
batch 1 Nova #1. Evaluator, batch 1 Nova #1: "wind.py defines is_applicable as not world.has_wind(),
but execute unconditionally calls prevailing and assigns world.wind, so the supplied wind is
replaced." My own reference had the identical bug in round 1 (L50).

**Precondition.** A plugin/simulation family whose members declare an applicability predicate that no
call path consults (count definitions, then call sites; zero calls = live), plus a contract rule about
preserving caller-supplied state.

**How to build.** State the preservation rule behaviourally, never "check `is_applicable`". One test:
call `execute` directly on a world carrying a DISTINCTIVE supplied value and assert it is unchanged.
Pipeline-level preservation tests alone are weaker.

**Arsenal mapping.** A8-adjacent (guard present, not wired). ~10 test lines, no extra description
words beyond the preservation clause.

---

### F-30. Low-bits invariant of an existing pass broken by a new full-width consumer ★ lead wall on cwerg-bcopy-bzero-lowering (10/10 → 8/11 → 7/10 → 3/9 → 2/10 across five batches)

**Mechanism.** A pre-existing pass rewrites values into a wider representation and promises only a
weak invariant: the low w bits still hold the narrow value. Every existing consumer re-truncates
(narrow arithmetic, stores, compares at width), so the weak invariant has always been enough. The new
feature adds the FIRST consumer that reads the whole register: a length, a count, an index, a shift
amount. The narrow value that wrapped (`U8 255 + 1 = 0`) is now 256 at 32 bits, and the new
instruction runs 256 times.

**Why it misdirects.** The agent's lowering is correct for every value it is handed. The failure is a
segfault in the OPTIMIZED C executable while the plain one passes, so it reads as an optimizer bug or
a C-backend bug, never as "your opcode is missing from a width pass you did not know touched it". The
pass lives in shared lowering and runs from the optimizer and two of three native legalizers, so
whether it bites depends on the target and on whether the program was optimized first.

**Evidence.** `cwerg-bcopy-bzero-lowering`, `bulkmem.c/...64.opt` (+ `.optcc` once it existed):
**batch 1 10/10** (before meta stated it), **batch 2 8/11**, **batch 4 7/10**, **batch 5 3/9**,
**batch 6 (accepted) 2/10**. The meta sentence "a value that has wrapped at its own width is used as it
stands, which stays true when the program is optimized first" went in after batch 1 and the wall still
killed in every later batch: stating the contract does not hand over the fix, because the fix is in a
pass the agent never opened. Verbatim, batch 6 Nova #6: *"The agent patch leaves BE/Base/lowering.py
and lowering.cc FunRegWidthWidening without the BCOPY/BZERO handling present in the reference change.
The hidden fixture exercises this with add m m 1 on U8/U16/U32..."*. Upstream's own docstring states
the weak invariant: *"the lower w bits of reg b will always contain the same data as reg a would
have"*. The same trap found MY reference first: Solution Quality round 5 ("A32/A64 lowered AFTER the
narrow-width widening passes") after four clean rounds.

**Precondition.** (a) a pass that widens, boxes, promotes or canonicalises values and documents (or
implies) a low-bits / modulo invariant; (b) that pass runs on SOME pipelines only (optimizer, some
targets), so the plain path passes; (c) the new feature consumes a value at full width. Compilers with
register widening, integer-promotion passes, bytecode VMs that store small ints in machine words.

**How to build.** State the observable rule once, at the value ("a value that has wrapped at its own
width is used as it stands, which stays true when the program is optimized first"). Never name the
pass. Then run the SAME golden program through every pipeline the repo already has (plain, optimized,
each target): the repo's own `TEST_OPT_EXES` convention made this fair. Put the narrow wrap in the
length, not in a constant, so constant folding cannot remove it.

**Arsenal mapping.** HARDENING S4 (machinery-riding integration) x F-1 (a pipeline stage destroys
information a later stage needs). Pairs with F-31 when the repo has twin implementations.

---

### F-31. Twin implementations with different host integer semantics ★ 2/10 on cwerg (identical 5-test set), 1/9 before

**Mechanism.** A system implemented twice (Python spec + C++ port, JS + WGSL, interpreter + JIT)
under an "identical output" contract. One host has unbounded integers, the other fixed-width ones.
Constant folding in each twin was written against its own host: C++ keeps `uint64` bits, Python keeps
the mathematical value. Old instructions never exposed the gap because every consumer re-truncated.
The new instruction prints its folded operand as-is, so `add fw1:S32 MAX MAX` serialises as
`4294967294` in one twin and `-2` in the other.

**Why it misdirects.** The failures arrive as three unrelated symptoms at once: an optimizer IR text
diff, an a64 immediate-encoding diff (`movz/movk` vs `movn`), and an x64 instruction-selection abort
(`could not find matching pattern for mov fw1@rdx 4294967294`). None mentions constant folding. The
agent's own lowering and C backend are both correct, and neither agent patch touched `eval.py` or
`eval.cc`.

**Evidence.** `cwerg-bcopy-bzero-lowering` batch 6: **Nova #2 and Nova #7 failed the IDENTICAL 5-test
set** (`.64n` a64/x64 parity, x64 cc, optcc, optimizer parity) and nothing else; batch 5: Nova #1
(the closest run, masked in others by earlier walls). Verbatim, Nova #2: *"The agent patch changes
lowering and CodeGenC but does not change BE/Base/eval.py or BE/Base/eval.cc, while the failures show
4294967294 versus -2 and 4294967298 versus 2 in optimized IR."* Both marked described AND inferable.
Came from an Auto Review High coverage finding (round 25), L17/L22 again.

Also `pyocd-sequence-expression-kernel`: **2/10 runs** in the accepted batch, with no host-language
difference: the twins are a parse-time constant folder and the interpreter, both consumers of one
operator table. Agents moved the value semantics into the interpreter and left the folder's old
identities (`x || 0 -> x`, `0 - x -> x`). The repo's OWN fold table encoded exactly those identities
(test.patch deletes three rows), so a solver reading the base tests was pointed at the wrong answer
(F-12). Verbatim, Nova #1: *"_ConstantFolder.binary_expr still returns the left operand for x || 0
and the right operand for 0 - x"*. Both runs also hit the `tms` accident (F-20), so F-31 decided
neither alone.

**Precondition.** Twin implementations under a parity contract, differing host integer (or float)
semantics, and a feature whose operand can be a FOLDED constant that the new consumer emits without
re-truncating.

**How to build.** One sentence of parity ("the Python and the C++ optimizers must emit identical
optimized IR text") plus the wrap rule from F-28. Fixture: all-constant overflowing arithmetic at
S32/U32/S64/U64 feeding the new instruction, so the optimizers fold it. Ship ONLY arithmetic the
feature's operand actually reaches (see L60): wrapping ADD/SUB/MUL/SHL, never signed DIV rounding or
float division, whose twin divergences are pre-existing and unrelated.

**Arsenal mapping.** HARDENING S6 (two evaluators of the same model) x A4 (host-language semantics).

---

### F-32. Scale-only malformed CFG surfaced by a stricter sibling renderer ★ 9/10 → 3/11 → 2/10 → 2/10 on cwerg

**Mechanism.** The new lowering splits blocks and rewires edges in the C++ twin. With a few
occurrences the resulting IR is well-formed enough for every consumer. Past a threshold (about ten
bulk operations in one function) something in the split / edge bookkeeping goes wrong, and only the
TEXT renderer (`-mode normal`) walks the structure strictly enough to crash. The binary emitter on the
same program succeeds.

**Why it misdirects.** It is a SIGSEGV in the codegen tool with no message, on the large parity
program only; the smaller programs and every execution test pass, so it reads as a platform or
memory-pool problem. I bisected Orion's batch-1 patch and ruled out pool capacity (same crash at
`-multiplier` 4/8/16/32), my wrap cases and every single construct in isolation; six batch-1 agents
passed the program in `-mode binary` and failed `-mode normal`.

**Evidence.** `cwerg-bcopy-bzero-lowering` `bulkmem.parity` a64 + x64: **batch 1 9/10** (while meta
omitted "however many times", so partly unfair, restored after), **batch 2 3/11**, **batch 4 2/10**
(Nova #7, #9, INTEGRATION), **batch 6 2/10** (Nova #1, #8, both `FAIL_INTEGRATION_ERROR`,
`Segmentation fault | build/${target}_codegen_tool.exe -mode normal`). Auto Review: *"their C++ lowering
produced malformed or unstable CFG state on the larger repeated-operation inputs"*. Per-run root cause
was not diagnosed; the count is measured, the mechanism above is the bisect result on one patch.

**Precondition.** A feature that edits the CFG (splits blocks, adds loops) in a hand-written C++
(or other manual-memory) twin, a contract that says it works "wherever and however many times", and
two output paths that walk the IR with different strictness.

**How to build.** State multiplicity in the prompt ("work wherever they appear in a function and
however many times"). Use ONE golden program with dozens of occurrences across branches, loops and
helpers, and run it through the strict path (text / parity) as well as execution. Without the
multiplicity sentence the test is unfair (L26: I trimmed it once and batch 1 read 9/10 on it).

**Arsenal mapping.** HARDENING A4 (host-language semantics) x F-10 (multiplicity axis).

---

### F-33. Inherited aggregate merged with the base operator ★ 3/10 on tippecanoe-tile-join-size-recourses, and first found in the reference

**Mechanism.** The repo already reads a metadata field back from every input and folds it into one
value with a fixed operator: `tile-join`'s `handle_strategies` adds every inherited strategy field with
`+=`. The feature redefines what one of those fields means ("the largest size any tile at that zoom
wanted to be ..., counting the sizes inherited from the inputs") without adding a field. Agents build
the new value on the path they are writing (the workers' per-tile records) with the right operator
and leave the input reader alone, so inherited values still sum.

**Why it misdirects.** The reader is not on the feature's path. It runs in the per-input metadata loop
after every tile is processed, and each sibling field it merges (`dropped_as_needed`,
`dropped_by_rate`, ...) is correctly additive, so the loop reads as finished code. A single-input
fixture cannot tell `+=` from a maximum, and a run with no inherited metadata never reaches the
reader at all.

**Evidence.** `tippecanoe-tile-join-size-recourses` accepted batch: **3 of 10 runs** (rd7ckrvd,
rd74p16c, rd78mncm), each described by its evaluator as otherwise covering most of the shedding path.
Verbatim: rd7ckrvd "its final handle_strategies logic still adds inherited tile_size_desired values
instead of taking the largest value"; rd74p16c "the implementation's strategy parser adds inherited
tile_size_desired values with +=, while the task requires the largest desired size across inherited
inputs and newly processed tiles"; rd78mncm "handle_strategies adds inherited values with +=". All
three evaluators marked it described; two also marked it inferable from the code. The reference had
the same bug until a round-3 Solution Quality finding (L50), and a later Auto Review showed the
one-input test could not see it.

**Precondition.** A feature that changes how a field the repo ALREADY merges from its inputs
aggregates (sum to maximum, overwrite to sum, first-wins to union). Find the input reader and its
operator, and confirm the base suite has no multi-input case for that field.

**How to build.** One clause on the value, never on the reader. Test with TWO inputs carrying distinct
inherited values, both larger than the newly measured one, so a sum, a last-wins overwrite and a
maximum all disagree; add one single-input case where the inherited value is SMALLER, so "keep the
inherited value" fails too.

**Arsenal mapping.** HARDENING S3 inverted: the shared chokepoint must CHANGE for one field while every
sibling field through it stays the same. Costs one clause and two tests.

### F-34. Rollback snapshot aliases a buffer the existing solver updates in place ★ top killer on sfepy-adaptive-stepping-accounting (8/13)

**Mechanism.** The contract says a stopped run returns an earlier state ("one that accepted nothing
returns the state it held before its first solve"). The natural code saves that state by assignment,
`initial_vec = vec0`, and the repo's nonlinear solver then writes its iterate into the same NumPy
array. By the time the snapshot is returned it holds the solved values. Nothing crashes, and every
run that accepted something still passes, because there the snapshot is re-taken after an acceptance.

**Why it misdirects.** The rollback logic is visibly right: the state is saved before the solve and
returned on the stop path. The failing assertion shows solved values where initial ones were
expected, which reads as "restored the wrong snapshot" or "rolled back one step late", not as "a
solver you did not write mutates its argument".

**Evidence.** `sfepy-adaptive-stepping-accounting`: **8 of 13 runs with real results** (two wrapper
timeouts excluded), all Nova, and the **sole failure of both 116/117 near-misses** (Nova 3, Nova 6).
Evaluator, Nova 3: *"the snapshot is assigned as `initial_vec = vec0` before `self.solve_step0(...)`,
then reused on rejection; the failing test reports current values [0, 0, 0, 0.5, 0.5, 0.5, 1, 1, 1]
versus the original [0, 0, 0, 0, 0, 0, 1, 1, 1]."* Nova 9: *"records vec_before_solve = vec0 without
copying it."* Both passers copied (Orion `vec0.copy()`, Vega a helper returning `vec.copy()`). A probe
on two near-miss patches showed the returned vector and the problem variables were the same array, so
the test was not reading the wrong surface (Pattern 93). My own reference had the identical bug first:
Auto Review R21, "the working iterate doubled as the accepted state".

**Precondition.** An iterative engine whose solve step writes its iterate into the state vector it was
handed (NumPy/SciPy solvers, Eigen, Go slices, any `x += dx` over a caller buffer), plus a feature that
must hand back a state from BEFORE a solve. Confirm the in-place write with a file:line citation; a
solver that returns a fresh array has no seam.

**How to build.** State the outcome only, in the same sentence as the ordinary rollback ("returns the
last state it accepted; one that accepted nothing returns the state it held before its first solve").
Never mention copying. Test the nothing-accepted case with a fixture whose first solve is rejected but
still moves the iterate (a tight `eps_a` with one Newton iteration) and compare, with exact array
equality, against a copy captured before the solve. The accepted-then-stopped case cannot see it.

**Arsenal mapping.** HARDENING A4 (host-language semantics, value vs reference). Silent cousin of
F-4: same aliasing family, no crash.

---

### F-35. Rollback extended to the position counter — 2/13 on sfepy, sole failure of a 114/117 run

**Mechanism.** The contract says a stopped run stops "before advancing" and returns the last accepted
STATE. The base stepper increments its index before an attempt runs, so a stopped run leaves the
attempted index current. Agents who implement the state rollback also rewind the index, because
"undo the rejected step" reads as undoing all of it.

**Why it misdirects.** Rewinding looks like the careful, symmetric choice and is invisible to every
value assertion. It only shows as a mismatch between the last log record's step and the stepper's
step, which reads as a logging off-by-one.

**Evidence.** `sfepy-adaptive-stepping-accounting`: **2 of 13** (Nova 5, Vega 3), all three stop
tests in both, and the SOLE failure of Vega 3 at 114/117. Evaluator, Vega 3: *"the implementation
rolls the time-step index back after logging the final rejection ... In the baseline
VariableTimeStepper, advance() increments step before the attempt is yielded; breaking before the next
advance leaves the attempted step current."* Nova 5: *"adds _restore_previous_step(), which causes the
failing assertions to observe log step 1 versus solver step 0."* ir-sim-scenario-events: **0/11** on the id-counter rewind a replay after `reset()` needs; every agent rewound it (the reference-side over-rewind is L76).

**Precondition.** A stepper, cursor or iterator that advances its index before the work for that index
runs, plus a stop rule that rolls data back.

**How to build.** Put "stops before advancing" and "returns the last state it accepted" in one
sentence, so both are stated and the reader has to separate them. Assert the relation
(`log[-1].step == stepper.step`) after every kind of stop (cap, floor, first order), not an index value.

**Arsenal mapping.** A7 determination channel; relative of F-14 (what a terminal state carries vs
where it is decided).

---

### F-36. Lookahead consumed from a pre-segmented, backtracking token stream ★ top killer on mwparserfromhell-site-aware-parsing (11/19), sole failure of four 189/190 near-misses

**Mechanism.** A feature absorbs a run of characters that FOLLOWS a construct (a link trail, a unit
suffix, a trailing modifier). The host tokenizer does not read characters: it reads a list of
segments produced by splitting the input on its marker characters, and it backtracks by resetting a
head index into that shared list. The absorbed run can cross segment boundaries (a trail set that
contains a marker such as `-`), and the construct can be re-parsed after a failed route. Agents
consume the run the way the salient case suggests, and each shortcut breaks a different invariant:
scanning only the next segment, slicing the unread remainder back into the shared list, re-splitting
the whole input into single characters, or, on the REJECT branch (a file or category link that takes
no trail), emitting the peeked characters as a separate text token instead of leaving them unread.

**Why it misdirects.** Every straightforward trail test passes: `[[foo]]bar` has one segment of
letters and no backtracking. The failures surface as a character-loss round-trip diff deep inside a
composed string (`[[Talk:x|t]]bar` renders as `[[Talk:x|t]]r`), as a C-versus-Python tree difference,
as an extra adjacent Text node after a file link, or as unrelated tag tests failing because tag names
are now split into single-character text tokens. None of them names the trail scanner.

**Evidence.** `mwparserfromhell-site-aware-parsing` accepted batch (re-eval of batch 1), **11 of 19
runs**: the seeded generated parity corpus **10/19**, and the SOLE failure of four 189/190 runs; the
reject-branch text split (Cyrillic, lowercase-namespace and Unicode-namespace cases) **4/19**. Verbatim:
Orion, *"parser/tokenizer.py adds _consume_linktrail() that mutates self._text while scanning, while
parser/builder.py repairs file/category links by returning [link, Text(trail)]... the resulting
adjacent Text-node structure and the lost 'ba' from a 'bar'"*; Nova #10, *"C ('Wikilink',
'[[Talk:x|t]]ba') versus Python ('Wikilink', '[[Talk:x|t]]')"*; Nova #8, *"after changing _text to
list(text)... leaves the tag name split into individual Text tokens"* (28 failures). All marked
described AND inferable. **My own reference had the cross-segment form first** (Solution Quality R2:
linktrail `a-b` attached `a` in Python and `a-b` in C). The decisive corpus was an Auto Review
advisory coverage suggestion (R5), L17 again.

**Precondition.** A regex- or marker-split token stream with an index-based backtracking head, plus a
feature that consumes a variable-length run AFTER an existing construct, with a reject branch.

**How to build.** State the run as "the longest run of X characters immediately after", let the
character set be user-supplied (so it can include a marker), and require identical trees from twin
tokenizers if the repo has two. Test: a trail containing a marker, a trail of markers only, a run
ending mid-word, a construct that is re-parsed after a failed enclosing route, and the reject branch
followed by more text. Add a SEEDED generated corpus (fixed seed, fragments that include failed
routes) comparing twins and asserting exact round trip; it carried this problem's band.

**Arsenal mapping.** HARDENING S2 (composition) x F-31 (twin implementations). F-7's cousin: F-7 is
where a rule must be suppressed, F-36 is how much input the rule may take and what it must leave.

---

### F-37. In-band end-of-input sentinel collides with a character the feature must accept ★ 7/19 on mwparserfromhell-site-aware-parsing, all on the C arm

**Mechanism.** A C reader returns `'\0'` both for an out-of-range read and for a real U+0000 in the
input, and every existing loop tests `!this` for end of input. No existing feature ever had to accept
NUL, so the conflation was invisible. The new feature lets the USER choose a character set ("every
character that may form a link trail"), so NUL becomes a legal member, and a loop written the
repository's way stops at it.

**Why it misdirects.** The Python twin passes, so the failure reads as a narrow C-arm bug in the new
loop. Agents copy the idiom they see forty times in the file. The fix the contract actually needs is
in the READER (a distinct sentinel), and a local fix in the new loop leaves the NUL to be dropped by
the next existing loop that reads it.

**Evidence.** `mwparserfromhell-site-aware-parsing`: **7/19 runs**, every one on the `[c]` param
only, and never the sole failure of a run; it paired with the parity corpus in 3 runs and with title
reassignment in 3 Vega runs. Verbatim, Nova #4: *"tok_support.c still returns '\0' for out-of-range
reads, while Tokenizer_take_linktrail in tok_parse.c loops with 'while ((this =
Tokenizer_read(...)))', making an actual NUL indistinguishable from end-of-input."* Marked described
AND inferable. **The reference had it first**: Solution Quality R3 and R4. The full fix touched 18
end-of-input checks in `tok_parse.c`, and the backwards-read checks gating headings, lists and rules
broke 51 base tests until they were converted too.

**Precondition.** A C, or C-extension, reader with an in-band EOF value, a caller-supplied character
set or delimiter, and a Python twin or reference that has no sentinel.

**How to build.** One test with the sentinel character in the user set, followed by more text. Do
NOT also test the sentinel as ordinary text outside the feature (L60): that is a pre-existing base bug
the feature never touches.

**Arsenal mapping.** HARDENING A4 (host-language semantics) x F-31.

---

### F-38. Validity checked against the running accumulator instead of the pre-input snapshot ★ top killer on planetiler-custommap-schema-composition (7/10), the sole failure of three 82/83 near-misses

**Mechanism.** An ordered fold over inputs (files, layers, migrations, patches) where one input may
both ADD entries and REMOVE (or override) entries, and a removal is valid only for entries that
existed BEFORE this input. Agents validate the removal against the map they are mutating. An entry
added earlier in the SAME input is already in that map, so "remove it" succeeds instead of failing.

**Why it misdirects.** The running map is the object in scope, and every sibling rule is correctly
expressed against it: an inherited id keeps its position, its features are appended, a removal
drops the position, a re-add after a removal is appended. The tests everyone expects (remove an
inherited id, remove an id nobody defined) both pass with the live check. The failing test reports
only "expected ParseException, nothing was thrown", which reads as a missing validation, and the
validation is visibly there.

**Evidence.** planetiler-custommap-schema-composition accepted batch: **7 of 10 runs** (rd7evswb,
rd70p6bc, rd75wbrt, rd78hnxn, rd73pngb, rd746wb2, rd7es6yf); for rd7evswb, rd75wbrt and rd78hnxn it
was the ONLY failure out of 83. Verbatim: rd7evswb *"mergeLayers adds a new layer directly to
destination and later checks only destination.containsKey(id), so a second entry for that ID in the
same contribution is incorrectly accepted"*; rd75wbrt *"the agent's layer merge uses the current
aggregate map rather than tracking IDs inherited before the current file"*; rd78hnxn *"mergeLayers
removes from the shared destination map ... after adding the first entry ... so no exception is
thrown"*. All 7 evaluators scored it `was_mentioned_in_description: true`. The shim counterfactual on
the compile-wiped batch 1 read 5/8 on the same test (L72). The reference had the same bug until a
round-1 Solution Quality finding (L50).

**Precondition.** A merge or overlay format with an explicit removal or override marker whose
contract ties it to what EARLIER inputs contributed (config inheritance with `remove:`/`delete:`,
migration chains that drop a column, patch series, overlay filesystems with whiteouts). The repo
must merge inputs one at a time, so a per-input snapshot is a design decision the solver has to make.

**How to build.** One provenance clause: "removing an id that the earlier files did not contribute
is an error". Test ONE input that adds an id and then removes it. Keep a same-input remove then
re-add as legal, so "any second mention is an error" fails too.

**Arsenal mapping.** An F-10 cross-product cell (add x remove inside one input) with F-14's
provenance distinction: same observable map, two different histories. Costs one clause and one test.

### F-39. A repo helper whose latent bug only the new calling pattern reaches ★ 3/11 on featurevisor-minimal-rebucketing, three independent implementations, and the reference had it first

**Mechanism.** The repo ships a small helper that is correct for every call it gets today. Its bug sits
in a regime the existing callers never enter. The feature needs exactly that regime, and reusing the
helper is the idiomatic move. featurevisor's `getUpdatedAvailableRangesAfterFilling(ranges, fill)`
walks the free ranges while `remaining > 0` and returns only what it walked. When a fill exactly
consumes an early range, the loop stops and the untouched later ranges vanish. Existing callers fill
one contiguous region from the front, so nothing after the stop point was ever there to lose.
Rebucketing refills a discontiguous free set, so the next variation gets less space than it is owed.

**Why it misdirects.** Reuse looks like the respectful, lower-risk choice: the helper has the right
name, lives in the right file, and has its own spec. Every contiguous fixture passes. The failing test
shows a variation short by an exact slot's worth of buckets, which reads as an off-by-one in the
agent's own arithmetic rather than a defect in code the agent did not write.

**Evidence.** featurevisor-minimal-rebucketing accepted batch (re-eval of batch 1): **3 of 11 runs**
(Nova_3, Nova_8, Vega_1), each failing the same two tests, removed variations refilled in declared
order, and grouped slots walked in order. Verbatim: Nova_3 *"it updates discontiguous free ranges with
getUpdatedAvailableRangesAfterFilling. When that fill exactly consumes the first slot, the helper stops
and discards later slots"*; Vega_1 *"That helper returns no untouched ranges after a fill exactly
consumes the first range, so later slot ranges are lost"*. The Auto Review classed it "subtle but fair"
because the prose says slot ranges are "walked in order" and deficits take free values "lowest first".
The reference's first draft reused the same helper and failed the same way; the fix subtracts the
filled ranges instead.

`featurevisor-target-specialization` adds a PARSER instance: the base builder's `parseIfStringified`
decodes only strings starting with `{` or `[`, while the SDK decodes any non-`*` condition string, and
the builder writes a global override's `conditions: "*"` as `JSON.stringify("*")`. **Every one of the 10
batch-1 solutions and the R0 reference** kept the `{`/`[` rule and pruned that catch-all (local replay of
the Auto Review's High finding). Stated in meta.md as "stringified in any form the builder writes today,
scalar JSON included", it killed **0/10** in batch 2 (L77).

**Precondition.** A small allocation, cursor or range-arithmetic helper whose loop exits early and
rebuilds its result from only the items it touched, used today only by callers whose input keeps the
bug unreachable (one element, contiguous input, partial fills). Confirm by calling it with the new
regime's input in a scratch test before designing.

**How to build.** Do not mention the helper. State the observable rule the new regime needs ("walked
in order", "lowest first") and test two cases where an earlier range is used up EXACTLY: a removed
variation's freed space followed by later free space, and a grouped feature with two slot ranges.

**Arsenal mapping.** F-20's cousin: where F-20 contaminates from an untested sibling API, F-39 inherits
from a tested helper whose tests only cover the old regime. Zero description words.

### F-40. A per-key record built on a plain object loses the key `__proto__` ★ 7/11 on featurevisor-minimal-rebucketing, the sole failure of six 33/34 near-misses

**Mechanism.** The feature reports something per user-supplied string key (a variation value, a tag, a
field name) as a record. In JavaScript and TypeScript the natural `const out = {}; out[key] = ...`
never creates an own `__proto__` entry: the assignment hits the inherited setter, and a lookup such as
`if (!out[key])` finds `Object.prototype` and skips creation. The key is silently absent.

**Why it misdirects.** Every realistic key works, and the code is the most idiomatic TypeScript there
is. Nothing in the task prose mentions prototypes, so an agent has no prompt to reach for
`Object.create(null)` or a `Map` unless it already treats record keys as untrusted.

**Evidence.** featurevisor-minimal-rebucketing accepted batch: **7 of 11 runs** (Nova_1, 2, 3, 4, 5, 6,
7); for six of them it was the ONLY failure out of 34, after passing all 1050 baseline tests.
Verbatim: Nova_5 *"For the variation value __proto__, that assignment changes the object's prototype
instead of creating an own record entry"*; Nova_4 *"that expression resolves to Object.prototype, so no
own entry is created"*. Fairness held on two repo facts: `VariationValue` is typed `string`
(`packages/types/src/feature.d.ts:6`), and the repo's own diff tests already treat special keys as
data. The test exists because a Solution Quality review found the same bug in the reference (L50).

**Precondition.** A JS/TS repo whose feature emits a record keyed by strings the user controls, with
the key type unrestricted (`string`, not an enum) in the repo's own types.

**How to build.** Say the record gives figures "per variation value" (or per key) and nothing more. Add
one test that uses `__proto__` as a key and asserts it is an own, enumerable entry with the right
values. Keep the rest of the suite on ordinary keys so the edge stays a single cell.

**Arsenal mapping.** A4 host-language semantics. Strong but narrow, and reviewers call it peripheral
(L74): pair it with a core-algorithm killer, never make it the only lead trap.

### F-41. A runtime creation path that skips an attribute the batch loader injects ★ 10/11 on ir-sim-scenario-events, the sole failure of six 89/90 near-misses

**Mechanism.** The repo builds its scene through a batch loader that quietly adds a per-entry attribute
the entry itself never states. ir-sim's `EnvConfig._build_scene` calls `create_from_parse`, which passes
`group=group_start_index + group_index`, so every YAML entry becomes its own group. The public factory
call a runtime feature reaches for, `object_factory.create_object(role, **template)`, does not, and
`ObjectBase` defaults `group=0`. A spawned object therefore joins the first authored group. Group
behaviors are dispatched per `ObjectGroup` from its first (delegate) member, so a spawned robot that is
driven only by `group_behavior` inherits group 0's empty behavior and never moves.

**Why it misdirects.** The spawn works: the object exists, has the right id, name, state and goal, is
in `robot_list`, collides and is seen by sensors. The only symptom is a robot that stays put, with a
throttled "Behavior not defined for rover_1" warning, which reads as a behavior-config problem in the
test rather than a missing attribute the loader used to supply. Agents who rebuilt the group list
correctly still lost, because the object was already in the wrong group.

**Evidence.** ir-sim-scenario-events accepted batch (re-eval of batch 1): **10 of 11 runs** (all but
Nova #3), and for six of them the ONLY failure out of 90. Verbatim: Nova #10 *"ObjectBase defaults group
to 0, ObjectGroup derives its group behavior from its delegate member, and the agent's spawn
implementation does not assign a new group when the template has none. The new-test failure confirms
rover_1 stayed at x=1.0"*. Every evaluator marked it mentioned in the description ("everything the
environment does, including ... behaviors, sees spawned and deleted objects") and inferable from the
code. The Auto Review classed it "subtle but fair" and approved. The test exists because the round-1
Solution Quality review found the reference had the same gap (L50).

**Precondition.** A loader that constructs objects in bulk and injects an index, id, owner or grouping
key per entry, beside a public single-object constructor that leaves it at a default; plus a runtime
subsystem that dispatches by that key. Find it by diffing the loader's call into the factory against
the factory's public signature.

**How to build.** Promise that runtime-created objects are ordinary members of everything the engine
does, and test one whose behavior comes ONLY through the keyed dispatch (a group-behavior-only robot).
Never name the attribute. Pair it with a template that sets the key explicitly (joins an existing
group) so both directions are covered.

**Arsenal mapping.** S4 machinery-riding integration, and F-9's origin variant one level down: the two
origins are the loader and the direct factory. Zero description words. It decided the band alone
(L20 bimodal risk), so give it a partner killer.

### F-42. Several positional deletions replayed in the wrong order on undo — 2/11 on ir-sim-scenario-events

**Mechanism.** An undo restores objects to the list positions they held when they were deleted. When
several are deleted in turn, each saved index is relative to the list AFTER the earlier deletions. The
restores are only correct in reverse deletion order. Restoring in deletion order, or sorting by saved
index ascending, lets an earlier insertion shift a later one.

**Why it misdirects.** Deleting one object and resetting always works, and so does deleting several
from the end. The failing assertion is a list of names in the wrong order after reset, which looks
like a sorting or id problem rather than index drift.

**Evidence.** ir-sim-scenario-events accepted batch: **2 of 11 runs** (Nova #9, Nova #4), both from
`test_reset_removes_spawned_and_restores_deleted_in_place` (one event deletes `robot_0` and then
`obstacle_2`). Verbatim: Nova #9 *"events.py:320-322 restores deleted objects by ascending saved index,
which yields the wrong order when more than one object was deleted."*

**Precondition.** Any undo/rollback that re-inserts removed items into an ordered container by recorded
position.

**How to build.** One fixture deletes two items at different positions in one pass, the earlier one
first, and asserts the exact order after the undo. State only "comes back with its place in the list".

**Arsenal mapping.** A9 exact-fit index arithmetic: the one-item case passes every reading.

### F-43. The implicit-AND list arm dropped from a hand-written recursive evaluator — 3 runs across 2 batches on featurevisor-target-specialization

**Mechanism.** The repo's expression language lets a bare LIST appear anywhere an expression can, with
implicit-AND meaning, including nested inside `and`, `or` and `not`. An agent re-implementing the
evaluator (here, a three-valued specializer) handles the top-level list, then writes the recursive
node function with branches for the named operators and the leaf type only. A nested list reaches the
leaf branch, is not a leaf, and is decided false.

**Why it misdirects.** Every hand-written fixture uses lists only at the top. The failure appears only
in a generated equivalence corpus, as a flag or variable value that differs for some random datafile,
nowhere near the missing `Array.isArray` branch.

**Evidence.** featurevisor-target-specialization: batch 1 **2/10** (Nova_2, Nova_8), batch 2 **1/10**
(Nova_8), each failing exactly the six seeded-equivalence batches whose datafiles nest a list under a
group operator. Verbatim (batch 2): *"The agent patch's specializeGroupSegmentNode checks strings, then
objects containing and/or/not, but never checks Array.isArray; an array child therefore fa[lls to the
leaf]"*; batch 1: *"The stateful condition and segment specializers do not recurse into nested lists,
so valid SDK expressions are treated as always false."* Both evaluators: mentioned in the description,
inferable from `sdk/src/conditions.ts`.

**Precondition.** An expression format with an implicit container (list = AND, map = AND, bare string =
reference) that is legal below the named operators, and a feature that makes the agent evaluate or
rewrite expressions itself instead of calling the repo's evaluator.

**How to build.** One sentence that the SDK's meaning is kept for every form ("segments, `and`, `or`,
`not` and condition lists keep the meaning the SDK gives them"). Test it with a SEEDED random corpus
compared against the repo's own evaluator (Pattern 99); hand-written cases put lists at the top and
never catch it.

**Arsenal mapping.** HARDENING A3 (reuse-the-machinery missing arm), found by P1-style property tests.

---

### F-44. Two type rewrites composed out of order: alias resolution × pointer lowering ★ lead trap on csbindgen-struct-layout-fidelity (7/10)

**Mechanism.** The feature has two independent rewrites of a type: follow aliases to their target, and
lower a raw pointer to an array into a pointer to the array's innermost element. Each is easy alone.
Composed, the order matters: the alias has to be resolved BEFORE the pointer decides whether its
pointee is an array, and resolution must keep the pointer DEPTH while stripping only the array
layers. Agents resolve the alias at the outer name and then hand the target to the array renderer
(`fixed byte* p`), lose or duplicate a pointer level (`ushort***` for `ushort**`), or classify an
alias-to-pointer as a fixed-buffer element.

**Why it misdirects.** Every direct form passes: `*const [u8; 4]` lowers correctly and a plain alias
resolves correctly. The failure only appears when a raw pointer's pointee is an alias, or an alias's
target is a raw pointer to an array, and the output is a wrong C# SPELLING, not a crash, far from the
function where the two rules meet.

**Evidence.** csbindgen-struct-layout-fidelity: batch 3 **6/16**, batch 4 **7/10** (the most-failed
axis in the accepted batch; failures spread across `aliases_to_raw_pointers_are_lowered`,
`pointers_follow_aliases_to_arrays_and_functions`, `pointers_to_arrays_units_and_functions`). Verbatim:
*"It also emits aliased raw pointers to arrays as invalid fixed-buffer forms such as fixed byte* p
instead of byte* p."* (batch 4); *"PtrKinds emits ushort*** and int*** where the expected C# types are
ushort** and int**, and AliasPtrs similarly emits float*** instead of float**."* (batch 3);
*"to_csharp_string resolves an aliased pointer into use_type and then calls use_type…"* (the run that
recursed into a stack overflow). Evaluators: mentioned in the description, inferable from code.

**Precondition.** A code generator whose type model already has aliases AND pointer/array wrappers, and
a feature that adds a second rewrite on top of an existing one (lowering, flattening, niche erasure).

**How to build.** State both rules once each, never their combination ("aliases are followed wherever a
type appears", "a raw pointer to an array points to the innermost element"). Then test the composition
cells: pointer-to-alias-of-array, alias-of-pointer-to-array, alias-of-pointer inside an array, and one
pointer-to-pointer level, each asserting the exact emitted type.

**Arsenal mapping.** HARDENING F-10 cross-product cell (rule × rule), misdirecting because the output is
a plausible-looking spelling.

---

### F-45. A scalar-only decoration leaks onto the aggregate form — 6 runs across 2 batches on csbindgen-struct-layout-fidelity

**Mechanism.** The existing emitter decorates a scalar field (`[MarshalAs(UnmanagedType.U1)]` before a
C# `bool`). The new feature adds an aggregate form of the same element (a `fixed bool` buffer). Agents
route the new form through the scalar emission path and keep the decoration. On a fixed buffer the
attribute compiles but makes the struct unmarshalable (`Marshal.SizeOf` throws).

**Why it misdirects.** The field type, length and position are all correct; only one prefix differs, and
the repo's own legacy array path (which never decorated) is the only precedent.

**Evidence.** csbindgen-struct-layout-fidelity: batch 3 **3/16**, batch 4 **3/10**. Verbatim: *"rs:155-162
applies the bool MarshalAs attribute before formatting a PlannedFieldKind::FixedArray."*; *"fixed bool
buffers gain an unwanted MarshalAs attribute"*. The Auto Review classed it "shared blind spot" and kept
it: the repo's pre-existing fixed-array path shows the convention.

**Precondition.** An emitter with per-kind decoration (attributes, annotations, casts) and a feature that
adds an aggregate or wrapped variant of a decorated kind.

**How to build.** Include the decorated element type in the aggregate fixture matrix (here `[bool; 3]`
alongside the numeric primitives) and assert the exact line. Verify on the real runtime that the
decorated form is actually wrong before relying on it (here: .NET 8 `Marshal.SizeOf` throws).

**Arsenal mapping.** HARDENING A3 (reuse-the-machinery wrong arm).

---

### F-46. The comparison's second side computed with the first side's model — 7 runs across 2 batches on csbindgen-struct-layout-fidelity

**Mechanism.** The feature decides by comparing two layouts: the source language's (Rust) and the one the
target runtime will actually produce (.NET). Agents compute the target side from source-side data: a
nested struct's C# alignment taken from its Rust alignment, an explicit union's C# size taken as its raw
field extent instead of the emitted `Size`, or C# offsets filled in from Rust offsets. The comparison
then says "differs" where the runtime would agree (over-promotion to Explicit) or "matches" where it
would not.

**Why it misdirects.** The container's own fields are right; the wrong input is the NESTED type's
target-side layout, computed one level down and reused.

**Evidence.** csbindgen-struct-layout-fidelity: batch 3 **5/16**, batch 4 **2/10**, all on the P2P guard
`container_of_sized_union_at_its_rust_offset_keeps_sequential` plus its A16 sibling. Verbatim: *"it
compares C# layout offsets against offsets it populated from the Rust layout"*; *"A union whose emitted
C# declaration receives Size = S is reported to parent layout calculation with the raw field size
instead, causing WideThenUnion to become explicit unexpectedly."*

**Precondition.** A feature whose output choice depends on comparing two models of the same data (source
ABI vs target ABI, schema vs wire format, logical vs physical plan).

**How to build.** Write the target-side rule for NESTED values explicitly in meta ("use the layout .NET
gives the emitted C# type"), then add P2P guards where a nested type became Explicit but its container
must stay Sequential. The guards cost nothing to pass for a correct solution and kill the reuse.

**Arsenal mapping.** HARDENING over-promotion guard (P2P cross-product), L-series "guards are free".

---

### F-47. New per-entry state the repo's persistence and aggregate bounds were never built to carry ★ lead wall on libspatialindex-tpr-temporal-knn (4/12), found by probe convergence

**Mechanism.** The feature gives each stored entry a property the old model did not have (here: a moment
after which the entry stops moving). The repo already has fields for it on the value type, but the
STORAGE and AGGREGATION layers throw it away: `Node::storeToByteArray` never wrote an entry's end time,
`loadFromByteArray` hard-coded it to infinity (the author's commented-out read/write lines were still in
the file), `insertData` overwrote it with infinity, and the node-bound maintenance combined children with
unclamped extrapolation. Every one of those was correct while nothing could stop. A correct solution must
carry the new state through all of them: keep it on insert, persist it per record, clamp position AND
rate in every predicate, and keep an aggregate bound sound when a child stops under a still-moving parent.

**Why it misdirects.** The local geometry is easy and gets written first, and point evaluation looks right
everywhere. The losses surface far from their cause: a silently missing id on a DEEP tree (node bounds),
an entry that keeps moving after a reload (page format), a crash when an older index is opened (no layout
marker). Nothing in the failing assertion names the serialisation or the bound.

**Evidence.** libspatialindex-tpr-temporal-knn, accepted 12-run pool (10 Nova + 2 Orion): **4/12 runs** on
this axis - three on integration (*"incorrect stopped-entry pruning"*; *"is not robust for deep trees
containing stopped entries"*; *"incorrect overlap logic and lost finite end-times"*) and one on
persistence, a run that passed all 73 new and 27 baseline tests and was STILL failed by its evaluator:
*"Node::loadFromByteArray always reads that extra field and does not inspect a format/version flag."* The
two deep stopped-entry scenes were the joint top killers (4/12 each). Measured lift from introducing the
axis: batch 1 (no expiry) read 7/10; the accepted batch read 5/12.

Designed layers that killed NOBODY in the accepted pool: containment split at stop instants
(`ContainmentSeesAnEntryStopInsideTheInterval`, 0/12) and a single-piece distance solver
(`NearestFindsTheClosestApproachBeforeAnEntryStops`, 0/12). The piecewise KERNELS were transcribed (L58);
the band came from the STATE layers.

**Precondition.** A persisted, indexed structure (tree pages, a WAL, a cache with an on-disk form) whose
value type already has a field the store drops or hard-codes on load. Tell: a commented-out
`memcpy`/`read` of a field, or a load path that assigns a sentinel (`max()`, `INF`, `None`) to a field
the write path never mentions.

**How to build.** State the new state behaviourally ("an entry moves until its insertion shape's end time
and holds its position from then on") and nothing about storage. Test it on a deep random tree against an
exhaustive oracle, after a close-and-reopen, and through the public C API. Do NOT pin the store's own
self-check (L82).

**Arsenal mapping.** L58 escape hatch ("look where prose cannot reach"); the discarded-state lever (L83).

---

### F-48. The feature narrows an existing entry point, and agents keep its old convenience ★ 3/12 on libspatialindex-tpr-temporal-knn, three capable runs

**Mechanism.** The base `pointLocationQuery(const Point&)` wrapped any plain `Point` in a static `Region` and
answered. The contract made it temporal: only the four time shapes are accepted and "a shape of any other
kind" is rejected. Agents rebuilt the method on the new machinery but kept the legacy path, synthesising
a current-time query for a raw `Point` instead of throwing.

**Why it misdirects.** The signature still takes a `Point`, the old code path still compiles, and keeping
existing behaviour feels like the safe, backwards-compatible choice. The rejection rule is stated once, in
the validation paragraph, far from the sentence that describes point location.

**Evidence.** libspatialindex-tpr-temporal-knn: **3/12** (Nova, Nova, Orion), each also failing an F-47
cell, so the two walls stacked on the same runs. Verbatim: *"accepts an untimed point-location query"*;
*"acceptance of an unsupported plain Point query"*; *"acceptance of an invalid raw Point query"*. The Auto
Review filed it as a *"shared blind spot ... rather than an unfair hidden expectation"* because the
contract states the boundary explicitly. Batch 1 had it too (1/10) before the contract said "any other kind".

**Precondition.** An existing public method whose parameter type is broader than what the new contract
accepts (base class in the signature, subclass required by the feature), and whose base implementation
already does something useful with the broad type.

**How to build.** One general rejection sentence covering every entry point ("a shape of any other kind is
rejected, whether ... query or mutation"), plus one test passing the base type to the narrowed method.
Zero extra description words if the rejection rule already exists.

**Arsenal mapping.** F-20's mirror image (F-20 leaks the new rule onto a sibling; F-48 leaks the old rule
past the new contract); F-10 validation cell.

---

### F-49. A deserialized graph re-parented onto the root: every node registered on the reading object instead of the one whose record referenced it ★ lead trap on siliconcompiler-flist-roundtrip (7/10), the sole failure of five 56/57 near-misses

**Mechanism.** The feature writes a graph out as a FLAT sequence of records, one per node, with the
parent/child relation carried by a marker INSIDE each record (`// sc-depfileset <design> <fileset>`
inside the group that owns the edge). Reading it back, the natural loop walks the flat sequence and
registers each named node on the object the read was called on. That reconstructs every node and every
file correctly, and it even records the nested edge itself; what it adds is an EXTRA direct edge from
the root to a transitive child. `head -> middle -> tail` comes back as `head -> {middle, tail}` with
`middle -> tail` also present, so nothing is missing and the graph is still wrong.

**Why it misdirects.** The flat serialized form has no nesting to imitate, so "read each record and
attach it" feels like the shape of the data. The contract's own reconstruction paragraph names the
reading design repeatedly (the prologue goes to its fileset, its own group merges into it, unreferenced
groups attach to it), which primes attaching everything to it. Nothing in the failing assertion points
at edge ownership: the diff is one extra name in a dependency list
(`assert ['tail', 'middle'] == ['middle']`), long after the parse, while every file, marker, filetype
and data root is right. Five runs shipped this as their only defect at 56/57.

**Evidence.** siliconcompiler-flist-roundtrip, accepted 10-Nova batch: **7/10 runs**, and the SOLE
failure of five of them (56/57). Evaluator wording, independently across runs: *"reconstructed nested
dependencies with an extra direct root edge"*; *"nested dependencies are flattened onto the reading
design"*; *"adds a transitive dependency directly to the reading design"*; *"missed nested dependency
ownership during marked-list reconstruction."* Every one recorded
`was_mentioned_in_description: true` and `description_clear: true`, and Auto Review classified the
convergence `shared_blind_spot` rather than an unfair test, because the contract assigns each marker
to "the group that carries it". Both passing runs cleared it.

**Precondition.** A repo that serialises a DAG or tree as a flat record list where the edges live
inside the records, and a public read entry point called ON one node of that graph (so there is an
obvious wrong object to attach to). Tell: the writer already walks the graph depth-first and flattens
it, and the reader currently produces a single object with no edges at all.

**How to build.** Two things are needed and neither is the edge rule itself. (1) A fixture at least
THREE levels deep: on a two-level graph (root plus siblings) re-parenting onto the root is
indistinguishable from correct, which is why a sibling-shaped suite measures nothing here. (2) A
separate rule for the leftovers ("a group that no marker references attaches to the fileset the
argument names") so that attaching everything to the root is visibly not the rule. State the ownership
clause once, plainly, and never say which object to call the repo's `add_dep` on.

**Arsenal mapping.** S2 composition of documented rules; adjacent to F-28 (a composite concept split
across container keys) in that the data is all present and only its ATTACHMENT is wrong.

---

### F-50. A value synthesised to REPORT an unlimited resource is enforced as a real LIMIT ★ 2/10 on pyfakefs-block-inode-accounting, and 4 runs on an earlier artifact

**Mechanism.** The contract has an "unlimited" setting (`total_size=None`, `inode_count=None`) and
ALSO requires the stats surface to report a finite number for it (a fixed placeholder capacity; an
unlimited inode count "reports as many inodes as blocks"). The natural implementation computes that
reporting figure once, in one helper, and then the allocation path calls the same helper to decide
whether a request fits. The placeholder silently becomes a ceiling: a file larger than the reported
total is refused, or the second empty file on a one-block mount raises ENOSPC because the reported
inode count was the block count.

**Why it misdirects.** Every reporting test passes, because the reported value is exactly right.
Every ordinary allocation test passes too, because real tests allocate far below the placeholder.
The failure needs a request that exceeds the REPORTED number on a mount that was declared unlimited,
which reads like an edge case rather than the core of what "unlimited" means. The reference author
makes the same mistake: this workspace's reference shipped it twice before a batch (a 1 TiB byte
placeholder that refused `st_size=UNLIMITED_SIZE + 1`, then `set_disk_usage(None)` rejecting a mount
already past the placeholder), both caught by Solution Quality.

**Evidence.** pyfakefs-block-inode-accounting accepted batch: **2/10 runs**, two different axes of
the same mechanism. Nova_10 (sole failure, 116/117): *"an unlimited inode count is incorrectly treated
as limited by the block count ... `_check_available` sets `total_inodes = total_blocks` when
`inode_count is None`"*. Nova_3: *"total_size=None means nothing is refused for lack of space"* was
missed on reconfiguration. Both recorded `was_mentioned_in_description: true`. Earlier artifact
(batch 2): `setting_no_limit_again_keeps_what_the_mount_holds` 3/12 and
`an_unlimited_mount_takes_more_than_the_total_it_reports` 1/12.

**Precondition.** A resource with an unlimited mode AND a reporting API that must return a finite
number for it (`statvfs`, `disk_usage`, a quota view, a pool's `capacity()`). Tell: the repo already
returns a hard-coded large constant for "unlimited" in its reporting path.

**How to build.** State both halves in adjacent sentences so neither is inferred: "no operation is
refused for lack of space" and "the reported total is a fixed placeholder". Then test each axis with a
request just PAST the reported figure: one byte over the byte placeholder, one inode over the
block-derived inode count, and the reconfiguration path (`set_disk_usage(None)` on a mount already
holding more than the placeholder). Clamp reported counts at zero, since the tracked side is genuinely
unbounded.

**Arsenal mapping.** S2 contract-stated / fix-hidden; sibling of F-24 (a sentinel replacing a real
behaviour), but here the sentinel is correct for reporting and wrong only when reused for admission.

---

### F-51. A platform-branched presentation size used as the stored size ★ 3/11, 5/12, 1/10 across three batches on pyfakefs-block-inode-accounting

**Mechanism.** The repo's size field is not the stored length on every platform: pyfakefs's
`FakeStatResult.st_size` deliberately returns 0 for a symbolic link on a Windows fake filesystem,
while the link path is still stored in the object. The feature charges storage for "the path it
holds". Agents charge the right blocks at creation (the content length is computed locally) but read
`size` / `st_size` again when RELEASING or REPORTING, so the Windows link frees nothing on removal and
`tree_usage` reports zero bytes for it.

**Why it misdirects.** The POSIX symlink tests all pass, and so does the Windows creation check. The
failing assertion is a zero in a usage report on an OS-type the rest of the suite never switches to.
The repo's own test (`test_lstat_size_windows`) asserts the zero, so reading the codebase REINFORCES
the wrong source of truth.

**Evidence.** pyfakefs-block-inode-accounting: `a_symlink_is_charged_for_its_path_where_stat_reports_nothing`
killed **3/11** (batch 1), **5/12** (batch 2) and **1/10** (accepted batch 3, Nova_6's sole failure:
*"its tree_usage calculation reports zero bytes for a Windows symlink whose mount accounting correctly
charges one block"*). In batch 2 it was the sole failure of the run one test from passing. The
reference shipped the same leak; Solution Quality found it at R4.

**Precondition.** A size, length or count field with an OS-type or mode branch in its GETTER, and a
feature that must account the real stored quantity. Tell: `if ... is_windows: return 0` (or similar)
inside a property that the rest of the code treats as the object's size.

**How to build.** Say what is charged in storage terms ("the path it holds, not its target") and add
one test on the non-default OS-type that asserts stat shows zero AND the mount shows one block AND
`tree_usage` shows one block AND removal gives it back. Toggle the OS type BEFORE configuring the
mount; switching it resets the filesystem.

**Arsenal mapping.** S2 contract-stated / fix-hidden; the codebase-inferable half of F-17 (a proxy
the repo itself presents as the real quantity).

---

### F-52. Two stacked boundaries with different rules collapsed onto the nearer one ★ 2/10 on pyocd-sequence-expression-kernel, the sole failure of both runs

**Mechanism.** The contract states one rule at an outer boundary and a narrower rule one layer
down. pyocd: a sequence function *receives the unsigned 64-bit form of every value it is passed*,
and `Write32` *reduces the word it writes to 32 bits*. The outer boundary is where the agent is
already editing (the interpreter's call path); the inner one is a different file (the delegate's
write functions). Agents apply the narrowing at the outer boundary, before the delegate is called,
so the delegate receives `0xffffffff` where the contract says `0xffffffffffffffff`.

**Why it misdirects.** Every transfer-width test still passes: the hardware write gets 32 bits
either way. Only tests that observe the delegate's INPUT through a recording delegate fail, and the
diff reads as a value-domain bug (`0xffffffff` vs `WORD_MASK`), not as a choice of layer. An agent's
own tests, written against the real delegate, cannot see it.

**Evidence.** `pyocd-sequence-expression-kernel` accepted batch: **Nova #7 and Nova #2, 146/150,
the identical 4-test set and nothing else** (`test_call_arguments_are_evaluated_left_to_right`,
`test_a_function_argument_is_a_value_of_the_domain`,
`test_a_call_made_as_a_statement_receives_values_of_the_domain`,
`test_the_last_statement_decides_a_predicate`). Verbatim, Nova #7: *"Interpreter.fncall adds width
masks before impl(*fn_args), whereas the reference applies those masks inside
DebugSequenceCommonFunctions."* Nova #2: *"adds _prepare_fn_args() and masks args[1] for
write32/writeap/writeaccessap/writedp"*. Both judged described AND inferable. The killing test was
built for Solution Quality's round-1 finding ("function results are not reduced"), which was the
OPPOSITE error: see the L90 counter-evidence.

**Precondition.** A call chain with an observable seam between two layers (a pluggable delegate,
driver or backend interface whose input the tests can record), and a narrowing that belongs to the
concrete operation below the seam, not to the seam itself.

**How to build.** State both rules in adjacent sentences: the full-domain rule at the seam, the
narrowing at the operation. Test the seam with a recording delegate AND the operation with the real
implementation over a mock. One sentence, and it only works once the seam rule is CONCRETE (L87):
batch 1, where the seam rule was abstract, failed the same tests by UNDER-reducing (7/11).

**Arsenal mapping.** HARDENING S6 / the F-9 family (stage placement). F-9 drops a normalisation
across a stage boundary; F-52 applies a narrowing one stage too EARLY.

---

### F-53. A must-property over the call graph solved from the pessimistic side ★ lead trap on teavm-method-summaries (4/10), the sole failure of three 25/26 near-misses

**Mechanism.** A fact that must hold on EVERY path through a recursive call graph (a method never
returns null, never throws, always terminates) is a greatest fixed point: start every method at
"true" and knock facts down until nothing changes. Agents start at "false" and promote a method only
once its callees are already proven, which is the least fixed point. It agrees on every acyclic
fixture and on every cycle that contains a null path. On a cycle whose members are jointly never-null
it never bootstraps: each member waits for the other.

**Why it misdirects.** Promotion-only is the natural reading of "prove it before you use it", and it
is what a sound per-method analysis does. It is also correct for the DUAL property the same feature
computes (written fields grow from empty; there least is right), so an agent who got the write sets
right by construction carries the same shape over to nullness. The failing assertion is a bare
`assertTrue` on one query, and it reads as a nullness-analysis gap, not as a direction error.

**Evidence.** `teavm-method-summaries` accepted batch: **4/10 (Nova #1, #4, #7 at 25/26 with nothing
else failing, #3 at 23/26)**, all on `neverNullHoldsThroughMutualRecursion`. Verbatim, Nova #1:
*"initializes Summary.neverReturnsNull to false and only sets it true inside `if
(!summary.neverReturnsNull && canProveNonNull(...))`, which cannot bootstrap this cycle."* Nova #7:
*"initializes neverReturnsNull to false and only sets it true after proving a method, so each member
of a mutually recursive cycle observes the other as nullable."* All four judged described AND
inferable. The sentence that states it was explicit: *"The facts are the most precise ones that hold
for all methods at once, so recursion and mutual recursion lose nothing by themselves."* Explicit
prose did not transmit the direction (L94).

**Precondition.** A whole-program analysis that computes a MUST fact (an all-paths property) over a
call graph with cycles, next to a MAY fact (a union) computed by the same pass. The repo must already
have the per-method analysis the fact is proven with, so the only new decision is where the
iteration starts.

**How to build.** One cycle of two methods where one member also has an anchored non-null exit (a
`new`), and a sibling cycle where a null reaches one member, so both directions are pinned. State the
"most precise facts for all methods at once" sentence. Auto Review later asked for an UNANCHORED pure
cycle too; that separates optimistic from anchor-seeded SCC solvers, which this batch did not show.

**Arsenal mapping.** HARDENING S-tier fixed-point family (F-2, F-22). F-22 is about WHICH quantities
share the fixed point; F-53 is about which END it starts from.

---

### F-54. The compatibility path "fixes" a legacy unsoundness the contract preserves — 2/10 on teavm-method-summaries

**Mechanism.** The feature adds a new input (here, summaries) and states that without it every pass
behaves as it does today. Building the feature exposes a latent bug in today's behaviour: the base
`RepeatedFieldReadElimination` keeps cached field reads across an `initClass`, although the class
initializer may write them. Agents who add the new `initClass` handler make it conservative on BOTH
paths, so the no-summaries path now forgets every read at `initClass` and no longer matches today.

**Why it misdirects.** The change is a soundness fix, and it reads as responsible engineering. Nothing
in the agent's own tests catches it, because nobody writes a test that asserts the OLD, weaker output.
The failing diff shows `field Counter.value` where `@a` was expected, which looks like the optimizer
being too cautious, not like a broken compatibility promise.

**Evidence.** `teavm-method-summaries` accepted batch: **Nova #6 at 25/26 (sole failure) and Nova #2**,
both on `withoutSummariesEveryPassBehavesAsBefore`. Verbatim, Nova #6: *"The baseline
RepeatedFieldReadElimination InstructionAnalyzer only overrides PutFieldInstruction and
InvokeInstruction; it has no InitClassInstruction handler. The agent patch adds a handler that sets
invalidatesAll = true when methodSummaries == null."* The test came from a platform coverage
suggestion ("Null-summary fallback"), not from the design, and it was also the old M20 mutant survivor.

**Precondition.** An opt-in feature whose off-state is promised unchanged, where the on-state has to
handle an instruction or case the base code silently ignores, and ignoring it is (at least
arguably) wrong.

**How to build.** One sentence ("with no X every pass behaves as it does today") and one test on the
off path that asserts today's output across the newly handled case. Mutation-check it: a
"conservative on both paths" mutant must die.

**Arsenal mapping.** F-12 family (repo behaviour as a discriminating axis), from the other side: F-12
keeps repo TESTS passing; F-54 keeps an untested repo BEHAVIOUR unchanged when the agent has a reason
to improve it.

---

### F-55. A wildcard sentinel routed into an existing per-variable entry point — 2/10 on teavm-method-summaries

**Mechanism.** The feature needs a new notion that the existing data model has no slot for ("this
field on EVERY instance"). Agents encode it as an out-of-band value in the existing slot (instance
variable `-2`) and pass it through the existing per-instance path, which indexes an array by that
variable (`AliasAnalysis.affectsEverything(instance)`). The reference and all four passers used the
same `-2` sentinel, and branched on it before the existing call.

**Why it misdirects.** The straight-line path is where the agent looks. The same sentinel is also
stored for the dominance-frontier join and replayed later through the generic
`invalidateField(instance, field)`, so a fix at one site leaves the other. The failure is an
`ArrayIndexOutOfBoundsException` deep in alias analysis, far from the new code.

**Evidence.** `teavm-method-summaries` accepted batch: **Nova #2 and Nova #3**, both killed by `Index -2
out of bounds for length 6` at `AliasAnalysis.affectsEverything` from `invalidateField`, on both
`fieldReadsSurviveACallThatDoesNotWriteThem` (straight line) and
`aCallInOneBranchForgetsItsFieldsAfterTheJoin` (join). Neither run had any other RFRE failure.

**Precondition.** An existing pass keyed by a variable or node index, with a second, deferred path
(join, frontier, replay queue) that stores the key and dispatches on it later, and a feature that
needs a key meaning "all of them".

**How to build.** Test the new "all" case on the straight-line path AND across a join, in separate
tests. Free if the pass already has both paths.

**Arsenal mapping.** A sibling of F-24 and F-37 (sentinel family). F-24 swaps a hard failure for a
sentinel; F-37 collides an in-band sentinel with real input; F-55 leaks an out-of-band sentinel into
an existing index-keyed API.

---

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

`sfepy-adaptive-stepping-accounting` adds a Python variant with no inline module: the discriminator is
a repo EXAMPLE test. The only Nova run to pass all 117 new tests failed on base alone, because its new
retry loop drove `linear_elasticity/linear_elastic_damping.py` through 439 retries to a singular
factor. The reference passes all 221 base tests.

`featurevisor-target-specialization` adds an EXPORTED-HELPER variant, and it was the top killer: the
repo's two-valued `applyContextToConditions` / `applyContextToSegments` have their own 4,000 lines of
unit specs, still in base mode. The natural move is to make those helpers three-valued; **3/10 in
batch 1 and 4/10 in batch 2 (7 of 20 runs)** did exactly that, passed every new test (28/28, then
33/33) and failed 20 to 36 helper specs. It was not an authored trap: the reference simply put the new
kernel in a new module and left the helpers alone. The meta names only `applyContextToDatafile`.

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

**Accounting variant: tippecanoe-tile-join-size-recourses, 4/10 runs** (rd776s2t, rd75za6b,
rd7bc7cz, rd70n6gm). The rule is stated on the EFFECT ("A run that sheds nothing leaves `strategies`
exactly as it inherited it"); the arming event is a tile going over the limit with shedding enabled.
Agents record `tile_size_desired` the moment the tile is oversized, so a lone feature that cannot be
shed still creates a strategies entry. Evaluator, rd70n6gm: "the agent's join_worker resizes the
per-zoom strategies vector and records tile_size_desired before it knows whether dropped is
nonzero." A fifth run (rd78mncm) made the mirror error, gating the SIZE on that tile's own drop, so a
larger unsheddable tile at a zoom where another tile shed was left out. The discriminating fixtures
are again the degenerate ones: a one-feature oversized tile with shedding on (with and without
inherited strategies), and a zoom where only a different tile sheds.

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

worldengine-orographic-precipitation: **4/20 runs (2/10 + 2/10), accessor-shape variant.** The meta
named `wind_direction` and `wind_strength` beside the per-cell `wind_at`; the repo exposes whole layers
as properties and cells through `*_at`. Two runs per batch wrote them as cell-taking METHODS, and 11-14
tests died at once as `TypeError: unsupported operand type(s) for -: 'method' and 'float'` (52-54/66),
graded INTEGRATION_ERROR both times and ruled inferable from the repo convention.

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


### ray-optics-formula-conditionals (JavaScript / formula DAG engine: parser, two evaluators, JS + WGSL codegen, symbolic derivative, interval range analysis) — ACCEPTED 2026-09-14

| | |
|---|---|
| Shape | O-Pipeline-hard: one new node family (comparisons, `if`, `and`, `or`, `not`) carried through all seven consumers of a shared IR |
| Final artifact | 7 files under `src/core/formula`, 329 human-effective LOC, 96 jest tests, meta.md 499 words |
| Pass-rate history | 11 precheck rounds, no batch → **batch 1 0/11** (94 tests: description wall 11/11 + trap stack) → route B, bare derivatives 0 everywhere (89 tests, harness 3/11) → **batch 2 1/10, the pass FP-flagged** → redesign: top-level-only switching, left-to-right `and`/`or`, scoped precision (92 tests) → five review rounds (96 tests) → **batch 3 1/10 (Vega), accepted** |
| Patterns used | F-26 (lead, 7/10), F-27 (6/10), F-10 WGSL raw-over-wrapped cell (6/10, near-miss decider), F-23 numeric-domain idiom (3/10), F-10 variadic-argument grammar cell (2/10) |
| Agent split | batch 3: Vega 1/1, Nova 0/9. All batches: Vega 1/2, Nova 0/29 legitimate (1 FP) |

**Why it held.** Four independent seams, each an exception to a general rule the agents otherwise
implemented correctly: identical operands (F-26), the `or` polarity (F-27), a valid node over an
invalid operand (F-10) and a repo equality idiom with a narrower numeric domain (F-23). Every failing
run failed at least two of the ten killing tests. Only 10 of 96 tests killed anything (40 kill
events: range estimator 24, WGSL codegen 11, derivative 3, parser 2). Nova median 7 files, +531 raw
LOC, 6.2M prompt tokens; the passing Vega run touched 12 files (+713) on 2.9M.

**What the batches taught.**
1. **A qualifier binds to its nearest clause (L52).** Batch 1 failed 10 tests in all 11 runs on "The
   derivative of a comparison, `and`, `or` or `not` is 0, and the derivative of `if` is the derivative
   of the selected branch, except on the switching set". Every agent bound "except" to `if` alone;
   every evaluator still called the tests fair.
2. **The FP check reads what the description STATES, not what the suite tests (L53).** Batch 2's lone
   pass was FP-flagged, and a probe battery over all ten solutions found no agent clean on every
   stated-but-untested sentence (order-independent `and` narrowing violated 10/10, nested-`if` value
   over-guard 8/10, invalid-only truth value 7/10). Testing each would have stacked the rate to 0;
   deleting the clauses produced a clean pass in batch 3.
3. **A regression test for every reviewer finding stacked to zero (L55).** Eleven precheck rounds
   turned about eight independent 30-60% reference findings into graded requirements; a local
   re-grade with both description walls removed still read 0/11. After pruning, the three strongest
   carried 17 of batch 3's 40 kill events: L50 works, within a budget.
4. **Precision findings get a scoped sentence, not a test (L54).** f32 rounding (emulating it would
   change base numerics for every formula) and later-operand infeasibility (its test failed 14 of 21
   saved solutions, 0 clean) were both closed by narrowing a promise: "agree while every value
   involved is exactly representable as a 32-bit float"; "other unreachable branches may still be
   included". The next batch was accepted.
5. **An external validator fails Verify Solution (L56).** A `naga-wasi-cli` WGSL validity test passed
   every local clean-room and failed Verify Solution on the platform twice. An in-process check
   (WGSL-only operators, bool `select` conditions) had 0 false rejections over 43 shaders x 22
   implementations.
6. **Killed nothing (L15).** The nested-switching machinery that precheck rounds 3-11 hardened (five
   reference bugs) was deleted in the redesign; its surviving "adds no switch" tests killed 0. So did
   WGSL evaluator agreement, the in-process WGSL check (two review rounds and a Verify failure),
   no-space parsing, bare logical switching, the 14 narrowing tests not about `or`, the 4
   statement-splitter tests and all 11 arity/reject tests.

**Reference bugs found: 16**, 13 across ten precheck rounds before any batch and 3 after the
redesign. Round 2: two Solution Quality highs. Round 3: nested-`if` switching guard; stale-range
narrowing. Round 4: nested-comparison traversal; self-comparison branch pruning (became F-26's
test); runtime-helper name collision. Round 5: an empty narrowed domain ignored under `maybeInvalid`
(became F-26's second test). Round 6: selection-aware nested-`if` guard. Round 7: invalid-only
operands kept a truth value. Round 8: a nested `and`/`or` lost its zero-crossing switch. Round 10:
subtraction-guard overflow (became the F-23 test). Round 11: nested-`if` selector without a guard.
After the redesign: CPU/GPU branch divergence on non-f32 literals (Auto Review S1); f32 intermediate
rounding, left by the S1 fix; a later `and`/`or` operand infeasible under earlier restrictions. The
nested-switching chain (rounds 3, 4, 6, 8, 11) ended only when nested propagation was deleted from the
description, which confirms L51 on a second problem.


### worldengine-orographic-precipitation (Python / procedural world generator: climate simulations, world model, protobuf + HDF5 persistence, drawing, CLI) — ACCEPTED 2026-09-16

| | |
|---|---|
| Shape | O-Composite-add: a prevailing-wind layer and a steady-state orographic moisture transport joined into the existing precipitation stage, carried through the world model, both serialisers, equality, drawing, generation steps and CLI info |
| Final artifact | 14 files (incl. `World.proto`, regenerated `World_pb2.py`, CLI manual, README), 251 human-effective LOC, 66 pytest tests, meta.md ~490 words |
| Pass-rate history | ~9 precheck/review rounds (rebuild-safety Dockerfile, Test Quality x4, Task Quality, Solution Quality, Auto Review x2) → **batch 1 1/10 by the grader, 0/10 regression-free** (every run stripped `Step.plates`; the two 65/65 runs carried the identical hunk and were graded PASS_LEGITIMATE and FAIL_REGRESSION) → one meta sentence + a plates test + float tolerance, then Test Quality dropped the direct-execute wind test → **batch 2 2/10, one FP-judge dissent overruled, accepted** |
| Patterns used | F-28 (lead, 7/10, sole failure of all four near-misses), F-16 accessor variant (2/10), F-29 (2/10) |
| Agent split | Nova only: batch 1 1/10 (0 clean), batch 2 2/10 |

**Why it held.** One contract-stated representation wall (F-28) with two smaller independent
integration seams beside it. 14 of 66 tests killed anything; batch 2's 46 kill events split
serialisation 25, precipitation/pipeline 11, wind 6, CLI 4, transport 0, drawing 0. Every failing run
passed the whole numerical model. Batch 2 Nova: 11-12 files, +324 to +441 raw LOC, 3.5M-6.5M prompt
tokens, 44-71 tool calls; the passers +418 and +380 on ~6M.

**What the batches taught.**
1. **Placement prose repairs an existing step (L57).** "A new winds step between plates and
   precipitations" made 10 of 10 batch-1 agents delete the three later-stage flags from `Step.plates`,
   which at base runs the whole pipeline. Nothing tested it, so a regression shipped inside a grader
   PASS. One sentence ("the plates, precipitations and full steps keep every stage they run today")
   and one end-to-end test took it to 0/10.
2. **The numerical kernel was free (L58).** The 24 transport tests (closed-form steady state, weak-wind
   laps, seams, warmth scaling, calm/no-ocean/no-land rows) killed 0 of 20 runs. The steady state had
   been chosen partly as the harder reading of "rows are loops".
3. **Four of six designed traps killed nobody (L15).** Wrap seam, steady state, mountain-start span and
   blend placement: 0/20 each. The serialiser trap killed 11/20, but through the container shape
   (F-28), not the predicted "skip the generated protobuf".
4. **Exact equality at a mathematically exact point is a test defect (L59).** 5 of 10 batch-1 runs
   returned 0.9999999999999993 for a band-centre `wind_at` strength; never a sole failure, but it cost
   an Auto Review round.
5. **A self-referential expected value cannot pin the helper it calls.** The combination test built its
   expected field from the implementation's OWN `base_field`. Batch 2's Nova #2 min-max normalised
   `base_field` and halved the sum, passed 66/66, and one FP judge flagged it; the adjudicator
   overruled citing that same test. Pin an exposed intermediate against a golden computed on base (the
   calm-wind golden pins only the final field, where the rescale washes the difference out).
6. **Every fairness rewrite needs the "fails on base" check again (L29).** Twice a test reduced to
   pre-existing repo behaviour (humidity from precipitation, calm-wind precipitation) and went green
   without the solution; each was re-tied to a feature-only observable.

**Reference bugs found.** 3 + 1 generated. `WindSimulation.execute` overwrote a supplied wind (round
1; the F-29 shape three agents later hit); 0/0 NaN on uniform temperature; 0/0 NaN on a 1x1 world in
the base noise normalisation; `World_pb2.py` regenerated at gencode 7.35.1 and unformatted where base
was 6.33.1 and ruff-clean.

### cwerg-bcopy-bzero-lowering (C++ + Python / twin compiler backend: IR opcode table, shared lowering, a32/a64/x64 legalizers, C backend, constant evaluators, optimizer) — ACCEPTED 2026-09-16

| | |
|---|---|
| Shape | O-Pipeline-hard, twin implementation: two experimental IR opcodes lowered to byte loops in Python AND C++ for three native targets plus the C backend, under byte-identical py/cc assembly and optimizer parity |
| Final artifact | 19 files, 690 human-effective LOC (≈375 excluding the generated `opcode_gen.cc`), 23 new-mode golden cases over 3 programs + 122 base cases, meta.md 293 words, Dockerfile 413 s cold build |
| Pass-rate history | 30 rounds. **batch 1 0/10** (multiplicity sentence trimmed + narrow wrap unstated) → meta states both → **batch 2 0/11** (parity-only `bulkshapes` program 11/11, a pre-existing narrow-parameter bug) → dropped, **re-eval 1/11** → reviewer coverage rounds → **batch 4 1/10** (fresh, meta edited) → 8 more review rounds, Dockerfile fixed for the 600 s environment timeout → **batch 5 0/9 on the strict suite** (float-div parity 9/9, U16/S16 DIV/REM/CNTPOP chains 8-9/9) → Docker replay of all 9 solutions picked suite A (3/9) → **batch 6 3/10 on suite A, accepted** |
| Patterns used | F-30 (lead, 2/10 here, 10/10 in batch 1), F-31 (2/10, identical 5-test set), F-32 (2/10), F-27 sibling-derived cursor variant (1/10, 3 runs over 3 batches) |
| Agent split | batch 6: Nova 2/9, Vega 1/1. All five solved batches: Nova 3/46 as graded in their own batch (plus 1 on the batch-2 re-eval), Vega 1/3, Orion 0/1 |

**Why it held.** Three independent walls sit in code the agents did not write (a width pass, two
constant evaluators, C++ CFG bookkeeping), and each is reached only by one pipeline (optimized C,
folded constants, the text renderer). Batch 6 killed through 18 of 23 cases (32 kill events): `.64n`
wrap program 16, `.64` optimized C 6, `.64` parity 4, `.64`/`.32` native py/cc 6; 12 of the 32 are one
run's broken copy loop (Nova #4). Every
failure was agent-attributed; no run marked unfair. Median failing Nova: 15 files, +849 raw LOC,
33M prompt tokens; the passers +1166, +1103 (Nova) and +851 (Vega, 23M tokens).

**What the batches taught.**
1. **A parity promise between twins imports every pre-existing divergence (L60).** Solution Quality
   found about nine pre-existing py/cc or C-undefined-behaviour defects over rounds 10-27 (signed
   overflow in folding and emitted C, signed DIV rounding, SHL count masking, float DIV, narrow
   DIV/REM/CNTPOP widening). I fixed all of them in the reference, and adding a test for the last two
   took batch 5 to 0/9. All three accepted passes still have the DIV-parity bug; the FP adjudicators
   overruled every judge dissent as "pre-existing, task-unrelated", because the fixtures only reach
   wrapping ADD/SUB/MUL/SHL.
2. **Replay saved solutions in Docker before choosing a suite (L32/L40 confirmed).** The strict
   control reproduced the platform's recorded failures for 9/9 runs; suite A (strict minus float and
   chains) read 3/9, suite B (also minus constant-fold add) 3/9 with the same runs, so B was strictly
   worse. The accepted batch then read 3/10.
3. **A breadth program can hit a pre-existing bug and become the whole wall (L61).** `bulkshapes`, a
   parity-only program added for coverage, killed 11/11 in batch 2 through callee-parameter widening
   (`parameter mismatch ... [A64,S32,U16,S64] vs [A64,S32,U32,S64]`), nothing to do with the feature.
   Found by bisecting the near-miss's own patch.
4. **The Docker build counts toward the platform's 600 s environment start (L62).** Verify Solution
   failed with `EnvironmentStartTimeoutError` while every local run was green. Tool build plus
   `chmod -R` over a lower COPY layer took 704 s; one `RUN --mount=type=bind` layer took 413 s with a
   byte-identical `/app`. (The bind mount is now itself a Dockerfile-check FAIL; see L62 for the COPY form.)
5. **A concision trim deleted the multiplicity sentence and batch 1 read 9/10 on it (L26, second
   problem).** Restored after batch 1; the same wall then killed 2-3 per batch, fairly.
6. **Killed nothing (L15).** `bulkmem.c` plain `.64` and `.64n`, `.64n` optimized C, `.64` optimizer
   parity and `.32` a32 parity: 0/10. The 13-mutant FP battery and the batch-4 optimizer-parity case
   (0/10) bought insurance, not difficulty. The Auto Review-demanded constant-zero `bcopy` case was
   never added.

**Reference bugs found: about 19 over 27 review rounds.** About ten in the feature: 64-bit lengths
narrowed to S32 at all three legalize sites; C loop variable captured IR register names; unsigned
constants >= 2^63; C loops at the S64/U64 extrema; opcode doc and C bindings not regenerated;
lowering placed AFTER width widening (F-30, round 5); signed hex constants; C++-optimized wrapped
lengths (round 16). About nine pre-existing twin divergences pulled in by parity (see lesson 1), plus
a 9,999 vs 99,999 derived-block-name ceiling asymmetry. Two harness defects: `build.cxx_tools` shared
by base and new, and a stale-tool leak after a failed build.

---

### tippecanoe-tile-join-size-recourses (C++ / vector-tile tileset merger) — ACCEPTED 2026-09-16

| | |
|---|---|
| Shape | O-Composite-add, graceful degradation fused with accounting: `-M`/`--maximum-tile-bytes` and `--drop-smallest-as-needed` for `tile-join`, plus tileset books (`strategies`, tilestats, zoom ranges, bounds) that describe only what was written |
| Final artifact | 5 files (`tile-join.cpp`, `mvt.cpp`, `mvt.hpp`, README, man page), 294 human-effective LOC, 49 CLI tests driven from Python plus 36 repo checks, meta.md 362 words |
| Pass-rate history | 2 precheck rounds and 4 Auto Review revisions before any batch (10 reference bugs, 3 harness bugs) → **batch 1: 1/10 (Nova), accepted**. Two runs were flagged ENV-blocked; both contests were upheld and the runs replaced |
| Patterns used | F-15 accounting variant (4/10), **F-33** (3/10, new). Designed but silent: F-17 attribute-pool compaction (the lead), F-9/F-20 booking restructure, F-3 whole-tile ranking, at-limit polarity |
| Agent split | Nova 1/10. No Orion |

**Why it held.** The primary defect of 7 of the 9 failing runs was a `strategies` edge cell (F-15 4,
F-33 3), each in a run its evaluator said implemented most of the shedding path. The other two were
a regression that segfaulted ordinary joins and a one-feature-at-a-time reduction loop that timed out
on the 90,000-feature fixture. The passer spent the fewest prompt tokens in the batch (9.6M against
a failing median of 15.1M) and was the only run that never restored build outputs.

**What the batch taught.**
1. **Tracked build outputs plus a plain incremental `make` grade the BASELINE binary (L63).** 9 of 10
   trajectories `git restore`d `.o` files or `tile-join` to keep a source-only diff; evaluators said 7
   runs were graded against stale or unlinked binaries, and each of those failed all 49 tests. The
   JUnit files therefore carry no per-test signal, and every attribution above comes from the
   evaluators' static reviews. Two runs were flagged ENV-blocked; contests citing the trajectory call
   that restored the binaries after the last build were upheld.
2. **Both killers were bugs in my reference first (L50 on another problem).** F-33's `+=` was a
   round-3 Solution Quality finding. The F-15 cells came from a round-8 Auto Review test gap and the
   S1 finding in the same round.
3. **Killed nobody (L15, L58), in evaluator attributions.** Attribute-pool compaction (the lead trap:
   a design-time spike shed 82,493 features without it against 56,301 with it), the booking
   restructure DESIGN.md called load-bearing, whole-tile ranking, the at-limit fixture, all three
   extent formulas, rescale- and exclusion-aware ranking, and merge-order ties. Seven runs were only
   reviewed statically, so a second defect behind the first could hide there.
4. **Every F2P node must fail on base.** Round 2 treated 2 of 29 new tests passing on base as a
   healthy ratio of preservation cells; precheck 2 failed Verify Solution on exactly those two.
5. **An adapter over the repo's own test runner is part of the test surface.** Base mode read Catch2
   JUnit for `<failure>` only and ignored the exit code once the XML parsed; a throwing unit test came
   out as 19 nodes and 0 failures. Auto Review scored Tests 0/3 on it.

**Reference bugs found: 10.** Round 1: `strategies` recorded for every written tile (broke the repo's
own golden file). Round 2: tie-break on layer position instead of merge order. Round 3 (precheck 1):
shedding floored to zero features; drops from a finally-skipped tile not recorded; inherited
`tile_size_desired` summed (became F-33); `-M` accepted junk. Round 4 (precheck 2): ranking erased by
`--exclude-all-tile-geometries`. Round 5: float-scaled staged extents made false ties after a
non-divisible rescale. Round 8: an unsheddable tile left out of `tile_size_desired`; bounds staged
before a later rescale. Harness bugs: an `allow-existing-test` golden that only matches at 8 or fewer
tippecanoe threads (pinned in test.sh), two F2P tests passing on base, the Catch2 `<error>` masking.

### sfepy-adaptive-stepping-accounting (Python / sfepy time-stepping solvers) — ACCEPTED 2026-09-16

| | |
|---|---|
| Shape | O-Composite-extend across a solver family: attempt-level `StepLog`/`StepRecord` accounting, declared `termination`, cap-over-floor precedence, rollback, final-time bounds and controller `get_state`/`set_state` for `ts.simple`, `ts.adaptive` and five elastodynamics solvers |
| Final artifact | 4 files (`ts_solvers.py`, `ts_controllers.py`, `solvers.py`, `ts.py`), 290 human-effective LOC, 117 tests, meta.md 444 words |
| Pass-rate history | batches 1-6: 0/5, 0/5, 0/8, 0/9, 0/10, 0/11 · batch 7 (re-eval): 1/11, FP-flagged on two base restart bugs · stated in meta.md (R48, R56) · batches 8-9: 0/8, 0/9 · R60 cut the restart lane · batch 10: 0/12 with runs at 117/116/116/115 · four runs appended to the same pool: **2/15, accepted** |
| Patterns used | **F-34** (8/13, new), **F-10** hostile-hook cell (7/13), **F-35** (2/13, new), F-12 on a repo example (1) |
| Agent split | Nova 0/11 with a result (9 with per-test data, 2 wrapper timeouts, plus 1 empty run), Orion 1/1, Vega 1/3 |

**Why it held.** Both main walls sit in the stop and retry path every solver shares, and every run
implemented that path. 8 of the 13 runs with real results returned an aliased pre-solve snapshot
(F-34), 7 let a hostile `adapt_fun` break a bound (F-10), and 6 did both. The near-misses split by
cause: two 116/117 runs on F-34 alone, a 116/117 Vega on the hook cell alone, a 114/117 Vega on F-35
alone. Every evaluator marked the description clear, and the passers cleared all three with ordinary
code: a `.copy()`, a strict retry bound, no index rewind.

**What the batches taught.**
1. **The pool is cumulative (L64).** The accepted batch folder re-listed batch 10's twelve runs under
   new numbers and appended four; added LOC and prompt tokens matched to the digit. Mining both folders
   as separate batches would have doubled every kill.
2. **A Nova zero measured the agent, not the problem (L65).** Nova went 0/11 with two runs at 116/117.
   The four appended runs held both passes (Orion, Vega). At 0/12 the option on the table was cutting a
   fair requirement; a probe showed the near-misses genuinely violated it (Pattern 93), and buying
   stronger agents was the fix.
3. **Cutting an unreachable lane worked twice; documenting it did not (L53).** R35 removed an
   elastodynamics cache trap after 10 of 10 failed the baseline. R60 removed the restart lane (19 tests,
   two meta sentences, `problem.py`) after stating its two base bugs (R48, R56) left batches 8 and 9 at
   zero.
4. **Both killers were reference bugs first (L50).** F-34 is Auto Review R21 on my reference; the hook
   cell grew from R27 (the callback boolean read as the floor) and R36 (an accepted step past the final
   time, in the call form of the repo's own damping example).
5. **Killed nobody (L15): 87 of 117 tests.** That includes the elastodynamics rollback lane built over
   R40, R45 and R46, the elastodynamics status copy and first-step clamp, the fixed-stepper schedule
   record, the `StepLog` queries, `truncate_from`, `summary` and the array round-trips. They stay as FP
   insurance; both FP adjudicators upheld the passes by citing this coverage.
6. **Our own docstring drew a false high.** R61's "custom adapt_fun hits a false reduction floor" did
   not reproduce (reference `completed`, a floor-on-`adt.red` mutant `step_floor`), but the docstring we
   added described the built-in floor as the floor. Two FP judges read it the same way later.

**Reference bugs found: 25 named in round titles.** Before batch 6 (12): R15 run past the end; R16
quasistatic initial solve, elastodynamics terminal restart; R18 retries overrunning the final time,
resumed elastodynamics sequence; R19 pending step size; R21 aliased accepted state; R22 one-shot
schedule; R23 schedule ending early; R27 callback boolean as floor; R32 edge case; R36 accepted step
past the final time. After batch 6 (13): R40, R41, R42, R43 x3, R44 x2, R45, R46, R49, R50, R52.

### mwparserfromhell-site-aware-parsing (Python + C extension / MediaWiki parser) — ACCEPTED 2026-09-18

| | |
|---|---|
| Shape | O-Composite-extend across twin tokenizers: a `SiteInfo` profile (linktrail characters, namespace names, recognised tags) threaded through `parse`, both tokenizers, the builder and `Wikilink` (`trail`, dynamic `namespace`) |
| Final artifact | 14 files (1 new, C and Python arms, README and limitations doc), 405 human-effective LOC, 98 test functions / 190 cases, meta.md 292 words |
| Pass-rate history | batch 1: **0/20**, 19/20 killed by one reviewer-requested test (`<ß>x</SS>` pairing) · test dropped, local Docker replay of all 20 patches projected 3/20 · re-eval: **2/19, accepted** (the pool dropped one projected passer) |
| Patterns used | **F-36** (11/19, new), **F-37** (7/19, new), **F-10** two-path cell (5/19), F-7 contexts (2/19) |
| Agent split | Nova 2/13, Orion 0/1, Vega 0/5 |

**Why it held.** The trail scanner sits on the tokenizer's regex-split, backtracking segment list,
and every shortcut through it broke a different invariant (F-36). Four 189/190 runs failed only the
seeded parity corpus; two 189/190 Vega runs failed only the colon-on-reassignment cell. Every
evaluator marked the description clear, and the failing runs kept all 2,006 baseline tests.

**What the batches taught.**
1. **A reviewer finding about PRE-EXISTING behaviour becomes a hidden requirement when you test it
   (L66).** Solution Quality R6 flagged that tag open/close pairing lowercases (`<ß>x</SS>`). I fixed it
   in the reference AND added a test. meta.md states caseless RECOGNITION, never caseless PAIRING, and
   the test killed 19 of 20 for the identical reason. Dropped: 0/20 to 2/19 with no other change.
2. **Both passers delegate the C arm to Python (L67).** When a site is given, their C tokenizer imports
   the Python tokenizer and returns its tokens, so "identical trees" holds trivially. Both FP panels
   upheld it ("correct for tree parity"). 8 of 20 runs in batch 1 delegated. The dual-machinery lead
   trap in DESIGN.md never had to be crossed, and the leanest passer measured 221 human-effective.
3. **Local replay predicted the re-eval run for run (L68).** Replaying the 20 saved patches in the
   submission image, offline, as uid 1000, gave the platform's failure count exactly for all 19 runs
   the pool kept. The pool dropped batch-1 Nova #13, a projected pass whose patch also edited two repo
   test files, so the projection read 3/20 and the re-eval 2/19.
4. **Killed nobody (L15): 66 of 98 test functions.** That includes every designed trap except the colon
   cell: the wiki-markup carve-out (italics, lists, rules, tables), namespace normalisation (alias,
   padding, underscores, unknown prefix), the Unicode trail sets as UCS-kind traps (the four Cyrillic
   kills were F-36's reject branch), profile-less parity, and the lossless round-trip tests. Predicted
   25-35%, measured 10.5%, carried by two reviewer-sourced tests and one designed cell.
5. **Auto Review "High" coverage gaps bought nothing.** Readable and iterable input, recognised tags
   with attributes and the Unicode namespace fold were each requested as High findings; each killed at
   most 1 run, always one already failing 15 or more tests. They stay as FP insurance.

**Reference bugs found: 5.** R2: trail scan stopped at regex marker segments (Python attached `a`,
C `a-b`), the F-36 form; R2: the new `WikilinkTrail` token class leaked into the repo's
`tokens.__all__` parametrized test; R3/R4: C NUL-as-EOF (F-37); R5: tag recognition used `lower()`;
R6: tag pairing used `lower()`. Harness bugs besides: R5, `|| cat` masked a failed C build and `/app`
was root-owned, so uid 1000 could not rebuild.

### kira-loop-crossfade (Rust / game-audio engine: static and streaming playback, shared transport, decoder-thread scheduler, static baking) — ACCEPTED 2026-09-18

| | |
|---|---|
| Shape | O-Composite-add across two playback paths: public `LoopCrossfade` with conversions, settings and handle commands on both sound kinds, shortened wrap in the shared transport, static blend before the resampler, streaming head-frame retention under stated decoder seek budgets, `bake_loop_crossfade` |
| Final artifact | 11 files, 237 human-effective LOC (agent patches 276-412), 55 tests, meta.md 496 words |
| Pass-rate history | seven review rounds before any batch (R3 on: tests only except two wording edits) · batch 1: **3/10 Nova, accepted** · finalize replay with the buffered-prefix test made queue-depth-independent: **9/10** |
| Patterns used | designed walls (none killed): decoder seek budgets, head frames kept for the pass, mirror reverse, clamp, easing, rate and stereo parity, bake parity · measured: **F-10** live-change cell (1/10, the only genuine kill) |
| Agent split | Nova 3/10 (all ten runs Nova) |

**Why it held: it did not, the harness did.** Six of the seven failures were one test,
`streaming_set_loop_region_keeps_the_buffered_audio_then_uses_new_weights`, at the same boundary:
47 exact old-loop frames and then 0.0 (one run: 24 and then silence). The test stopped the decoder
after 60 calls and then asked for 48 buffered frames. 48 is what MY scheduler queues from 60 calls;
schedulers that prepare the whole fade before enqueueing queue 47. Replaying each failing patch with
the prefix lowered to 12 frames: all six pass all 55 tests, run 6 still fails, pass run 3 still
passes. Every evaluator called the six failures fair (`description_clear: true`, "agent fault"), and
the FP panel upheld all three passes; only the post-batch Auto Review named the fixed 48 (Tests 2/3,
Medium false negative).

**What the batch taught.**
1. **L18's reachability checklist passed an unfair cluster (L69).** Passes existed, the near-misses
   cleared everything else, every evaluator marked the description clear, FP was clean. The tell was
   in the JUnit text: the same frame index and a silence value in every run. Replay before counting.
2. **Gating one resource and asserting on another encodes the reference's exchange rate (L70).**
   Round 1 removed a hard-coded 16384 buffer size on a quality review. Round 4 added a gate keyed on
   decoder calls with an assertion on output frames, which moved the same constant into a ratio.
3. **A spec that states every rule gets transcribed (L1, L58).** A 496-word description fixed the
   blend rule, landing, clamp, reverse mirror, seek wrapping, slice, rate, streaming timing, decoder
   budgets and bake result. All ten runs built all of it (mean 54.3/55, 13-14 source files,
   ~500 added lines). The one genuine kill sits where two stated rules meet (F-10).
4. **Reviewer coverage killed nobody here (L17 counterpoint).** Six review rounds grew the suite from
   33 to 55 tests (rate, stereo, reverse seeks, eased handle updates, live streaming seek, 4 Hz
   seconds, easing matrix, API matrix). Zero genuine kills; one of them made the six false negatives.
   L17 pays only when the suggested test sits on an intersection agents actually get wrong.
5. **Own-suite vacuity found by mutants (L71).** Four seek tests passed with the seek ignored or the
   landing frame unblended: the past-end seek tests (static and streaming) expected exactly what the
   first pass plays anyway, and two seek-into-fade tests let the settle window skip kira's duplicated
   landing frame. Two handle tests passed only because 2048-frame chunks ended on a pass boundary.
6. **Killed nothing: 53 of 55,** including the decoder-trace and startup-seek tests (R3-R4), the gated
   live-seek test, rate/stereo parity, the easing matrix and the bake tests. They are FP insurance; the
   adjudicators cited them to uphold all three passes.

**Reference bugs found: 2.** Startup double seek (Solution Quality R3: start 3 on loop 2..8 made seek
3, seek back for the head frames, seek 3 again, against a stated one-extra-seek budget) and a bake
capacity hint. Test-side defects found and fixed before the batch: 8 (the 16384 constant and two
event-order asserts, the single-node `compilation` fallback, the four vacuous seek tests, the two
chunk-aligned handle tests), plus the fixed 48 that shipped.

### planetiler-custommap-schema-composition (Java / planetiler custom-map YAML schemas: loader, composer, profile, CLI, validator) — ACCEPTED 2026-09-18

| | |
|---|---|
| Shape | O-Composite-add + second entry point: `extends` inheritance and a static `SchemaConfig.load(List<Path>)`, per-field merge rules (last-set scalars, sources by id, tag mappings per key, args per key with the existing fixed point, layers by id with position and `remove`, concatenated examples, uninherited definitions), bundled-sample parents, static `SchemaConfig.files(Path)`, comma-separated `--schema` for generation and verification, validator watch set |
| Final artifact | 7 files (5 Java + README + JSON schema), 316 human-effective LOC (passers 454-499), 83 tests, meta.md 485 words |
| Pass-rate history | seven review rounds before and between batches (R1-R6) · batch 1: **0/8 Nova, measured nothing** (8/8 compile-wiped on an unstated `files` shape, 1/8 also broke its own Maven repo) · shim counterfactual on the saved patches: 2/8 · batch 2 after naming both signatures: **3/10 Nova, accepted** |
| Patterns used | measured: **F-38** (7/10, new), **F-9** (3/10) · designed walls that killed 0: args fixed point (F-22 look-alike), layer position rule, raw-vs-accessor scalar inheritance, diamond dedup, cycle naming, depth-first order, relative-path resolution |
| Agent split | Nova 3/10 (all runs Nova); passers ran 68-112 messages per the Auto Review |

**Why it held.** One provenance clause. "Removing an id that the earlier files did not contribute is
an error" is satisfied by every sibling rule's natural implementation except one: validating against
the map being mutated lets a same-file addition be removed. Seven of ten runs fell there, three of
them with nothing else wrong, and every evaluator called the sentence clear. The second killer (3/10)
was a stage-boundary resolution drop in the validator (F-9).

**What the batches taught.**
1. **An unstated call shape wipes a batch (L72).** "`SchemaConfig.files` returns ..." read as an
   accessor to every agent. A one-line adapter replayed over the saved patches recovered the
   measurement (2/8, top killer 5/8) and predicted the paid batch (3/10, top killer 7/10) before it ran.
2. **Every killer was a reviewer finding against the reference (L50).** Both measured traps are
   regression tests for Solution Quality findings from R1 and R4. The designed traps, the whole merge
   rulebook, took 0 of 10 (L58): a fully stated rule set is transcribed.
3. **A fixed point the repo already runs downstream is free (F-22 counter-evidence).** Deferred
   argument settlement needed only a map merge because `Contexts` already settles afterwards.
4. **The verifier inherits the agent's container (L73).** One agent's plain `mvn install` replaced
   the flattened core POM and broke offline grading; test.sh now repairs and retries.
5. **Root-only Docker validation hid three blockers:** a root-owned `/app`, git's dubious-ownership
   check killing the buildnumber plugin, and root-owned `target/` trees the resource copy cannot
   timestamp. None cost a platform run because they were found locally first.
6. **Killed nothing: 80 of 83**, including the end-to-end Monaco generation test, the validator watch
   tests and every scalar, sources, args and tag-mapping merge test. They were FP insurance: the three
   passes survived judge dissents on a directory named `power.yml` and an absolute `/samples/`
   examples path, both overruled as unstated.

**Reference bugs found: 10**, two of them fix-induced (L51). R1: list roots folded independently
(shared parent contributed twice, later removal lost), a one-file list inlined examples, removal
validated against the live map, examples fell back to a bundled sample. R2: `/samples/` lookup broke
on Windows separators. R3: the verify CLI ignored the comma list; external examples dropped out of the
watch set after inlining. R4 (from R3): standalone bundled examples resolved against the working
directory. R5: a string-loaded relative parent could be shadowed by a working-directory file.
After acceptance (from R4): eager inlining stopped `--watch` from registering a missing or malformed
examples file. Harness and environment defects: 5 (three non-root Docker blockers, unchecked JUnit
writes, the Maven repair), plus the description defect that wiped batch 1.

### featurevisor-minimal-rebucketing (TypeScript / featurevisor datafile builder: traffic allocation, state file, build reporting) — ACCEPTED 2026-09-19

| | |
|---|---|
| Shape | O-Algorithm-correctness on the repo's own model: replace "refill from scratch" in `getTraffic` with minimum-disruption reallocation over allocation ranges (region = first `percentage` of the ordered slot ranges, keep each variation's lowest in-region buckets up to its target, refill deficits lowest-first in declared order, sort + merge), plus `getAllocationChanges` accounting, an optional `rebucketing` collector in `buildDatafile` and `formatRebucketing` output after each environment's targets |
| Final artifact | 4 source files, 164 human-effective by the hook (207 by the platform counter; passers 239 and 251), 34 new tests + 10 untouched `traffic.spec.ts` cases kept in base mode, meta.md 460 words |
| Pass-rate history | scope gate passed on a 160-eff core slice · R1-R3 quality and Verify Solution fixes, no batch · batch 1: **2/11** (8 Nova, 1 Orion, 2 Vega) · R4 tests-only Auto Review fixes, replayed locally at 2/11 · re-eval: **2/11, Auto Review Approved, accepted** |
| Patterns used | measured: **F-40** (7/11, new), **F-39** (3/11, new) · designed walls that killed 0: the inclusive/prefix/half-open boundary mismatch, lowest-first retention, declared-order refill, sort-and-merge, idempotent rebuild, rule-key reuse, zero-weight override, every accounting and build-report cell |
| Agent split | Orion 1/1, Vega 1/2, Nova 0/8; prompt tokens 2.9M to 9.1M per run, Orion highest |

**Why it held.** Two independent killers, both found in the reference before any agent saw the task.
A plain-object record loses `__proto__` (7/11, six of them failed nothing else), and the repo's own
free-range helper drops later ranges when a fill exactly consumes an earlier one (3/11, three
separately written implementations). Every evaluator on both called the requirement stated.

**What the batch taught.**
1. **A fully stated allocation algorithm is transcribed (L58).** Twelve kernel tests on retention,
   refill order, region cuts and normalisation killed 0 of 11. The difficulty the design was built
   around never showed up; the band came from a host-language edge and an inherited helper.
2. **Both killers were bugs in my reference first (L50).** The `__proto__` test is a Solution Quality
   finding; the multi-range tests exist because my first kernel reused the same helper.
3. **Reviewers discount a peripheral edge even when they accept it (L74).** The agent-run review filed
   a High "difficulty discrepancy": six of nine failures were one special key. Accepted anyway, but
   the strict rate was called an overstatement.
4. **Representation tests showed up in the run data first (L49).** Batch 1 had 7 kill events from
   formatter return shape and one-log-per-line assumptions. A shape-tolerant `renderLines` removed all
   7 and moved no pass.
5. **The replay predicted the re-eval exactly (L68):** 11 of 11 runs, same failing tests.
6. **Killed nothing: 31 of 34**, including the reviewer-requested stored-ranges case, disjoint
   accounting, positive `added` on a collected change and the two-environment print trace. Those were
   FP insurance; both passes were upheld with fuzzing against the reference.

**Reference bugs found: 3.** A zero rule-weight override read with a truthiness check (inherited from
the repo's own code), the `__proto__` record, and reuse of the range helper. Harness and test defects:
6. A brittle `(rule ...)` label assertion, 18 new-mode tests that passed on base because editing
`traffic.spec.ts` dragged its untouched cases into new mode, repo test titles containing `::` that
split the grader's `classname::name` IDs into 314 phantom extras, formatter-representation tests, two
missing spatial coverage cases, and a JUnit fallback that dropped jest's diagnostic.

### ir-sim-scenario-events (Python / robot simulator: YAML scene config, step loop, object lifecycle) — ACCEPTED 2026-09-19

| | |
|---|---|
| Shape | O-Composite-add on the repo's own model: a declarative `events:` YAML section checked at the end of every step (time/arrive/collision/distance/enter/leave + all/any/not; spawn/delete/goal/pause; repeat/cooldown/delay; `env.event_log`), with `reset()` undoing what events did and `reset(random=True)`/`reload()` starting them over |
| Final artifact | 3 source files + 1 docs file, 363 human-effective, 90 tests, meta.md 494 words (incl. title) |
| Pass-rate history | scope gate passed on the first artifact · 6 Solution/Test Quality rounds, no batch · batch 1 (10 Nova + 1 Vega, 88 tests): **0/11**, one unfair sensor-timing pin killed 11/11 · tests + solution only (pin removed, Auto Review fixes), local replay 1/11 · re-eval: **1/11, Auto Review Approved, accepted** |
| Patterns used | measured: **F-41** (10/11, new), **F-42** (2/11, new), closed-rectangle epsilon (2/11, L75) · designed walls that killed 0: random-reset early return (F-9 origin), id-counter rewind (F-35), shared-list aliasing into the collision tree, lazy enter/leave under all/any short-circuit, undo-before-reset order, reload re-reading events, same-check visibility, delayed-before-listed order, add_object survivors (F-20) |
| Agent split | Nova 1/10, Vega 0/1, no Orion; prompt tokens 9.3M to 19.4M per run, the passer highest (19.4M) |

**Why it held.** One integration cell decided the band: a spawned robot driven only by a group behavior
has to become its own group, as every YAML entry does through the loader. Ten of eleven near-complete
event engines (88-89 of 90) missed it. Two smaller clusters (restore order, epsilon edges) added depth.

**What the batch taught.**
1. ⭐ **Every lifecycle trap I designed killed zero.** Eleven mutants reproduced before authoring
   (random-reset early return, id rewind, list aliasing into the STRtree, lazy region tracking, undo
   order, reload re-read, snapshot-vs-sequential conditions, ...) were each handled by all eleven
   agents. Lifecycle integration that the prompt names path by path is transcribed (L58 again). L15:
   the mutants measured what the tests detect, not what agents get wrong.
2. **The band-deciding test came from a Solution Quality review (L17/L50).** Round 1 found the
   reference ignored group behaviors for spawned objects; the regression test for it became F-41.
3. **A reviewer-found reference bug every agent shares cannot be tested (L76).** Round 5 found that
   rewinding ids on reset reissued ids held by created-but-unadded objects. The regression test
   killed 11/11, the passer included, and meta.md says replay gives "the same ids". Shipped the fix,
   not the test. The FP panel still had one judge flag the passer on exactly that probe; the
   adjudicator ruled it unfair.
4. **My own first batch lost to an unfair pin (L8).** `test_lidar_sees_spawned_obstacle` asserted the
   sensor had NOT yet seen a spawn at the spawning check. All eleven agents refreshed sensors at once,
   and a later Solution Quality round demanded exactly that. Timing of a derived view is a contract
   decision; pin it only after the description or a reviewer fixes it.
5. **The two checkers disagreed, and the description arbitrated.** Solution Quality required
   creation-time `ValueError` for unknown spawn-template keys; Test Quality then ruled that test unfair.
   Naming "spawned object's mapping" in the validation sentence satisfied both.
6. **Float luck in my own tests (L75).** Circle centroids are polygon approximations
   (2.000000000000001), so three exact-boundary tests passed by chance until they moved to squares.
   Two agents failed the one remaining dynamic edge cell by widening the rectangle with 1e-12.
7. **Killed nothing: 87 of 90.** The replay predicted the re-eval exactly (L68): 11 of 11 runs.

**Reference bugs found: 11** — nested payload validation; spawn/delete ignoring object groups
(and positional group actions); stale arrive/collision between same-check events; spawn-template key
validation; template `group` overwritten; `cooldown: 0` rejected; pause status overwritten by the status
refresh; explicit `events: null` accepted; distance/regions measured from the state origin instead of
the geometry centre; id rewind reissuing created-but-unadded ids; sensors stale after a spawn/delete.
All came from review, none from the suite.

### featurevisor-target-specialization (TypeScript / featurevisor Target datafile builder: condition + segment specialization, first-match list pruning, segment GC) — ACCEPTED 2026-09-19

| | |
|---|---|
| Shape | O-Algorithm-correctness on the repo's own model: `applyContextToDatafile` becomes a three-valued specializer (a condition is decided only when the Target context has a value at its attribute path), folds decided conditions and segments with SDK semantics, prunes force / traffic / rule + variation overrides / global overrides by each list's own SDK match rule (requiredFeatures never known to match), and keeps exactly the referenced segments |
| Final artifact | 2 source files (new `specializeForTarget.ts` + rewired entry point), 232 human-effective; 33 new tests (21 behaviour, 3 build-path, 8 seeded equivalence batches of 40 random datafiles x 4 targets, SDK as oracle) + 2 base-mode guards; 24 superseded repo specs removed from base mode; meta.md 319 words |
| Pass-rate history | picked after dinit (105 eff, machinery-absorbed) · batch 1: **2/10** (all Nova), Auto Review Revision Requested (reference High: scalar-JSON condition parse; tests Medium: no stringified rule/global override cases; Nova_10 passed but pruned requiredFeatures-only overrides) · R1 fix + 5 tests: replay showed both passers fail the scalar pair (would re-eval 0/10) · R2 one meta clause naming the root cause, fresh batch: **3/10** (all Nova), Auto Review Approved (tests 2/3: operators beyond the six generated, requiredFeatures + false selector on global/variation), accepted |
| Patterns used | measured: **F-12 exported-helper variant** (3/10, 4/10), **F-43** (2/10, 1/10, new), F-39 scalar parser (10/10 latent in batch 1, 0/10 once stated) · designed walls that killed ~0: per-kind match rules (global AND 1/10 in batch 1, nothing in batch 2), requiredFeatures cut-off, stringified cells, nested-path presence, segment GC, `not` over a decided-false child (1/10 batch 2) |
| Agent split | Nova only in both batches: 2/10 and 3/10 legitimate; one PASS_CHEATED per batch; passers 61-91 messages, ~500-700 effective lines by the review's count |

**Why it held.** The equivalence corpus made every unsound fold visible, and the natural architecture
(teach the existing helpers three-valued logic) regressed their own specs. Both batches' failures were
diverse and every evaluator called them stated.

**What the batches taught.**
1. **The top killer was not designed (F-12).** Leaving the old two-valued helpers and their specs
   untouched cost 7 of 20 runs. Every one of those runs completed the new behaviour.
2. **A seeded equivalence corpus is the only test that caught nested expression bugs (F-43).** Twenty
   hand-written structural cells killed one run between them; the 8 generated batches killed three.
3. **A reviewer-found reference bug shared N/N is a description problem, not a lever (L76, L77).** The
   scalar-JSON gap was in every batch-1 solution. Shipping the test by re-eval would have read 0/10;
   naming the root cause in one clause took it to 0/10 kills on a fresh batch.
4. **Per-kind match rules stated as "the rule the SDK uses" were transcribed.** Force OR, global AND,
   rule-override precedence and requiredFeatures killed 1 of 20 runs in total (L58 again).
5. **Removing superseded repo specs invites a cheat verdict (L78).** One run per batch updated those
   specs itself and was graded PASS_CHEATED.
6. **Killed nothing in batch 2: 26 of 33**, including the scalar catch-all pair, the stringified
   override cells, requiredFeatures-only, every force / global cell and all three build-path tests.

**Reference bugs found: 1 in code, 4 in tests.** The scalar-JSON condition parser (Auto Review High).
Tests: a force assertion pinning an irrelevant residual segment, residual-shape pins relaxed to key
sets, a missing requiredFeatures-only case (Nova_10 passed with the bug), missing stringified cases on
rule and global overrides. Harness: a git worktree's `.git` pointer file broke `git apply` inside the
container (failed loudly, rebuilt from a real clone).

### csbindgen-struct-layout-fidelity (Rust / FFI binding generator, Rust→C# ABI layout) — ACCEPTED

| | |
|---|---|
| Shape | O-Algorithm-correctness across a parser → new layout engine → emitter pipeline; the output choice (Sequential / Pack / Explicit) is decided by comparing a Rust `repr(C)` layout against the layout .NET gives the emitted C# |
| Final artifact | 6 production files (new `layout.rs`), **402 human-eff** (peaked at 598 before narrowing), 96 tests = 70 F2P + 23 P2P + 3 repo lib; meta 488 words |
| Pass-rate history | batch 1 **0/11** (unfair `*const Option<fn>` cell) · batch 2 **0/11** (unfair aligned-enum 11/11 by panic, unstated dependency cell 7/11) · local re-grades 1→3/11 · **FP panel voided all 3 "passes"** (unasserted fixtures) · FP-clean R19 re-grade 0/11 · contract NARROWED (module scoping + const-name lengths removed) · batch 3 **0/16** (`c_float` unstated 7/16, niche-Option array 8/16) · two meta clauses · batch 4 **1/10 → accepted** |
| Patterns used | measured: **F-44** (7/10, new, lead), **F-45** (3/10, new), **F-46** (2/10, new), L6 name-prefix NonZero (1/10) · designed walls that killed 0 in batch 4: Int128/.NET alignment, zero-size fields, unions, bitfield storage, packed/align, transitive promotion — 63/70 new tests killed nobody |
| Agent split | batch 4: 10 Nova, 1 pass (Nova #8). batch 3: 15 Nova + Vega, 0 passes; Vega never passed in any batch |

**Why it held.** One composition cell family (F-44: alias resolution × pointer-to-array lowering)
killed 7/10 on its own; F-45 and F-46 took the rest. The irony worth recording: F-44's cells were
DROPPED in R14 as "fair but most-missed" to buy solvability, then RESTORED in R19 because the FP panel
counted their unasserted fixtures against us. The cell that had to be kept for fairness ended up
being the difficulty.

**What the batches taught.**
- **An unasserted generated fixture is an FP trap** (L79). Four rounds of "fix the solution, skip the
  test only the reference passes" left scoping fixtures generated but unchecked; the FP panel ruled
  3/3 passes false positives on exactly those fixtures.
- **A contract sentence that promises a host-language semantic in full turns Solution Quality into an
  unbounded ratchet** (L80). "A const or alias name resolves in the module that uses it" produced 11
  consecutive FAILs, each a narrower name-resolution corner (const scope → alias scope → alias keying →
  `super::` paths → emitter scope → dependency graph → NonZero identity). Deleting the sentence ended
  it: the next Auto Review approved 3/3/3.
- **An enumerated list in a contract reads as exhaustive** (L81). The scalar sentence named four 8-byte
  C types; 7/16 agents treated `c_float`/`c_double` as unsupported. Naming them: 1/10.
- **L77 confirmed.** The niche-Option array rule was derivable from two sentences and killed 8/16; one
  clause stating the combination took it to 0/10.
- **L76 confirmed three more times.** Aligned-enum panic (11/11), declaration pruning (7/11) and the
  generated Rust-wrapper spelling (Test Quality) were all real reference bugs whose TESTS were unfair
  because meta never stated the behaviour. Fix the solution; ship the test only when meta states it.

**Reference bugs found.** ~30 across 25 review rounds, every one a would-be FP: Int128 C# alignment;
zero-size nested/trailing fields; `()` fields; pointers to non-path pointees; pointer aliases (×3);
unions without `repr`; `usize`/`isize` enum bases; 128-bit enums; `Option` layout for non-niche
payloads; const lengths (literal, scope, `u64::MAX` panic); `NonZero*` by prefix; aligned-enum parse
panic (base bug); dependency recursion; nested-array Rust wrapper rendering; Pack=16 vs .NET; and five
module-scoping holes that the narrowing deleted rather than fixed.


### libspatialindex-tpr-temporal-knn (C++ / TPR-tree spatio-temporal index: kernels, nearest-neighbour, self-join, range queries, node persistence, C API) — ACCEPTED 2026-09-21

| | |
|---|---|
| Shape | O-Algorithm-correctness plus a state-carrying integration layer: implement the two TPR-tree stubs (`nearestNeighborQuery`, `selfJoinQuery`), make the range queries temporal over four shape kinds, and give stored entries a finite end of motion that must survive the node page, node bounds and reload |
| Final artifact | 8 production files, **350 human-eff**, 73 F2P tests + 27 base; meta 490 words |
| Pass-rate history | batch 1 **7/10** (pure geometry, too easy) · round 1: 16 coverage tests replayed **7/10 → 7/10**, 57-cell probe **0 divergence** among passers · round 2: entry-expiry wall (meta delta) · batch 2 **0/10**, but 9/10 blocked by my own `isIndexValid()` assertion; removed, replay **5/10** · rounds 3-6: nine review findings fixed, replay stays 5/10 · batch 3 **5/12** (FP panel voided one pass, 4/12) · batch 4 = re-eval of the same 12 solutions, FP clean, **5/12 → accepted** |
| Patterns used | measured: **F-47** (4/12, new, lead), **F-48** (3/12, new), self-join feasibility across motion pieces (2/12, two different mechanisms, not promoted), nearest-distance optimiser edges (2/12, two different mechanisms, not promoted) · designed walls that killed 0: containment split at stop instants, single-piece distance solver, the whole validation matrix, comparator parity, k=0, ascending order - 35/73 tests killed nobody |
| Agent split | accepted pool: Nova 4/10, Orion 1/2. Batch 1: Nova 7/10. Batch 2: Nova 0/10 (unfair assertion) |

**Why it held.** Not the geometry. Batch 1 shipped three fully stated kernels (minimum distance over an
interval, same-instant overlap, every-instant containment) and 7/10 transcribed them; a 57-cell
differential probe then found zero behavioural difference between the reference and any passer. The band
came from F-47: state the repo writes nowhere and reads back as a sentinel, which no amount of geometry
reasoning recovers. F-48 stacked on the same runs.

**What the batches taught.**
- **Probe convergence means the derivable surface is exhausted, not that the pick is dead** (L83). Three
  searches (57 probes, 16 reviewer-suggested coverage tests, 4 composition cells) killed zero passers;
  the next lever was a field `Node.cc` never persisted, and it moved 70% to 42%.
- **Reviewer coverage suggestions bought nothing here.** All six advisory suggestions plus both Auto
  Review follow-ups were written and replayed: 0 new kills. L17 holds only while the passing population
  still diverges.
- **Asserting the repo's own self-consistency checker zeroed a batch** (L82). `isIndexValid()` demands
  exact equality with its own recomputation of node bounds; 9 of batch 2's 10 blocking failures were that
  assertion, and the same solutions replayed at 5/10 without it.
- **A persisted-layout change is a live FP seam even when the prompt says nothing** (L84). A 73/73 run was
  failed by its evaluator for an unversioned page, and FP judges probed legacy loading on four more passers
  across two batches, upheld once, over-ruled three times. Header-level versioning was itself a reference
  bug (it silently dropped the end time of NEW inserts into a reopened old tree); per-record versioning
  through the node type word fixed it.
- **Broadening a contract sentence is a promise the reference must keep on every path.** Widening the
  rejection sentence to cover `insertData`/`deleteData` immediately produced a Solution Quality FAIL: the
  mutation path accepted any `ITimeShape`. Route every entry point through one normaliser.

**Reference bugs found.** 9 from review, each a would-be FP: negative `max_dist` treated as a cap;
single-instant moving shapes worked around only in the C wrappers; `k == 0` visiting zero-distance
entries; stopped entries pruned when inserted beside an identical mover at the same time; unversioned
page format; header-level legacy mode dropping new end times; `deleteData` moving current time backward on
a reversed interval; `insertData` accepting a reversed interval; mutations accepting any `ITimeShape`.
Plus one self-found before the batch (an instant interval collapsed to a single motion piece).

---

### siliconcompiler-flist-roundtrip (Python / EDA build-system schema) — ACCEPTED

| | |
|---|---|
| Shape | O-Composite-extend. An existing flattening aggregation (`get_fileset` walk + `__write_flist` emission + `__read_flist` parse) extended so the structure the flattening destroys survives a write/read round trip |
| Final artifact | 3 files (`design.py`, `schema_support/pathschema.py`, `schema_support/filesetschema.py`), 324 human-effective LOC, 57 new tests + 5 base-mode preservation tests |
| Pass-rate history | batch 1 **0/11** (10 Nova + 1 Vega) → repair round → batch 2 **2/10** (20%) |
| Patterns used | **F-49** (lead, 7/10), F-9 (emission chokepoint), F-12 (private `__get_fileset` signature pinned by a repo test), F-20 (flat output preserved), F-10 (include × marker-scope cells) |
| Agent split | Nova 2/10 in the accepted batch. No Orion in either batch; the one Vega (batch 1) failed |

**Why it held.** One trap carried it and nothing else came close: F-49 killed 7 of 10 and was the sole
failure of five runs at 56/57. A second, much smaller axis (a marked group with no content must still
materialise its fileset) took 2 more. Everything else in a 57-test suite killed nothing. The band was
therefore decided by ONE test on a THREE-level fixture; the same trap is invisible on the two-level
sibling graphs the rest of the suite used.

**What the batches taught.**

- **A 0% first batch is not automatically a difficulty verdict — mine it before touching the design.**
  Batch 1 read 0/11 and three of the four causes were mine: a test helper calling an accessor only the
  reference defined (masked 5-7 tests per run), one ambiguous spelling sentence (4 tests, 9-11/11,
  identical failure), and a `file://` data-root case a review round had added (11/11). Only after
  removing those did the real trap become visible underneath. See L85, L86, L87.
- **Replay the saved patches to choose what to cut.** Re-running all 11 batch-1 patches against each
  candidate suite in the platform image priced every option: fixing the helper and the spelling alone
  still read 0/11; also cutting the `file://` case read 3/11; additionally clarifying the ownership
  sentence read **9/11**. The last number is why that sentence was left exactly as written — it was the
  only thing standing between the artifact and a too-easy reject. Live batch 2 then measured 2/10,
  against a 3/11 projection.
- **Explicitness is a dial with a measured setting.** The same pre-existing-data-root test killed 6 of
  11 while the contract said "a root registered earlier", and **0 of 10** after the sentence named both
  kinds of existing root. Nothing in the code changed. Wording moved that axis from a band contributor
  to a free pass.
- **The passers used ONE source file; the reference used three.** Both passing patches (465 and 513
  raw, ~275-325 effective) changed only `design.py`. Splitting the reference across `pathschema.py` and
  `filesetschema.py` satisfied the file-count floor but described nothing agents had to do.

**Reference bugs found.** Seven, all by review rounds before any batch, and exactly one became a
measured killer:

1. Empty marked group never materialised its fileset, so a dependency reference to it raised — **became a 2/10 killer**.
2. Hierarchy output reused the flat writer's de-duplication, so one path stored under two filetypes lost an entry.
3. A `sc-fileset` marker cleared the active filetype.
4. File type not inherited into a pulled-in list.
5. An include that opened its own group lost its insertion point (`a.v, c.v, b.v`).
6. The data-root allocator ignored roots the design already had.
7. `file://`-spelled roots were not reused — later cut from tests, contract and reference together.

### pyfakefs-block-inode-accounting (Python / fake filesystem: block, inode and reserve accounting) — ACCEPTED

| | |
|---|---|
| Shape | O-Composite-add. Whole-block and inode accounting added to an existing byte-only mount model, reported through a new `statvfs` on two surfaces, with reserves, `mount_usages()` and a `du`-style `tree_usage()` |
| Final artifact | 4 files (`fake_file.py`, `fake_filesystem.py`, `fake_os.py`, `docs/modules.rst`), 334 human-effective LOC, 117 new tests + 4 base-mode deselects |
| Pass-rate history | batch 1 **0/11** (10 Nova + 1 Vega) → cut 9 tests → batch 2 **0/12**, +2 Vega = 1/14, the pass adjudicated **FP** → wording + FP fixes → batch 3 **5/10** (accepted) |
| Patterns used | **F-20** (lead, 3/10), **F-50** (2/10), **F-51** (1/10), F-10 (reserve × rename, open-fd × unlink cells), F-12 (repo tests pin byte-exact accounting at block size 1) |
| Agent split | Accepted batch: Nova 5/10, no Orion or Vega. Vega batch 2: 0/4 genuine (one FP). Batch 1: Vega 0/1 |

**Why it held.** Three independent causes, each the sole failure of a near-miss: stepwise imports
inheriting `create_dir`'s rollback (F-20, 3/10), an "unlimited" reporting figure enforced as a limit
(F-50, 2/10) and a Windows symlink sized by `stat` (F-51, 1/10). 108 of 117 tests killed nothing. The
accepted rate, **5/10 = 50%**, is ABOVE the 40% ceiling this workspace records, and a human reviewer
accepted it anyway; Auto Review called it "hard but fair ... failures were near-misses on explicitly
stated lifecycle details". Record the fact; do not treat it as a ceiling change.

**What the batches taught.**

- **Eight clean gate rounds, then 0/11.** Description 3/3 and Solution & Code 3/3 were reached before
  any batch ran. Every Solution Quality round added a requirement ("your contract promises atomicity,
  so this path must roll back too"), each individually fair; their sum was five distinct recursive
  undo mechanisms, and six tests killed 11 of 11. See L91.
- **Cutting tests alone does not cut a requirement.** Batch 1's cut dropped nine tests but kept the
  sentence promising them and the code implementing them; the next Auto Review scored Tests 1/3 for
  missing coverage of that promise. Cut tests, contract and reference together.
- **A one-sided carve-out moves unrelated tests.** Batch 2 named only the stepwise helpers
  (`os.makedirs`, `Path.mkdir(parents=True)`, ...). With tests and solution unchanged, the five
  single-object `create_dir`/`create_file` rollback tests went from **0/11** kills to **9-10/12**:
  `create_dir('/a/b/c')` builds parents like `makedirs`, so agents filed it on the stepwise side.
  Naming BOTH sides took the same five to **0/10** in batch 3. See L89.
- **A pronoun three sentences from its antecedent killed 10/11.** "`mount_usages()` returns it for
  every mount" produced `(0, 0)` pairs; naming the type (`os.statvfs_result`) took it to 0/10.
- **An FP is a hole in your suite, and the saved patches price the fix.** Batch 2's only pass could
  never turn a bounded mount unlimited again: "None keeps the current value" was written for four
  options and the primary argument had no test for its own None. Applying all 14 saved patches and
  probing showed 12/14 already reset correctly, so the new test was a fair discriminator, not a wall.
  Every later test addition was probed the same way before it was written.
- **Two authored walls decayed to zero.** Reserve-crossing renames and the unlinked-open-file resize
  each killed 4/12 in batch 2 and **0/10** in batch 3.
- **All three near-miss killers were reference bugs the gates had found first.** See L90.
- **Validate as an unmapped UID.** The offline validator runs as a non-root UID with no passwd entry;
  `test_owner_and_group_posix` passed for root and 1000 and failed for it, costing a Tests Blocker.

**Reference bugs found.** Twenty-seven over eighteen review rounds, none by a batch. The ones that
predict agent failure became F-20, F-50 and F-51; the rest, in short: `set_large_file_size` released
before charging; `statvfs` absent from `FakeOsModule.dir()`; a rename releasing and re-charging (data
loss under a reserve); `change_disk_usage` losing its documented signed-byte semantics; a 1 TiB
placeholder enforced as a cap; negative `f_ffree` / `f_blocks`; `reset` unable to keep `inode_count=0`
because the temp dir charged first; lazy rollback re-entering the lazy load; charges attributed to the
new device after mounting over a directory; an unlinked open file's `ftruncate` subtracting twice;
component-blind `startswith` mount matching (a base bug newly exposed); the leaf mode forwarded to
`makedirs` parents; an unrounded placeholder for non-power-of-two block sizes; a mount root reused from
an existing directory keeping its old charge. **One remained at acceptance:** `create_file` rolls back
only on `OSError`, so a `UnicodeEncodeError` from `encoding="ascii"` leaves the file and its parents.

---

### pyocd-sequence-expression-kernel (Python / debug-sequence expression engine: value domain, effects, transfer widths) — ACCEPTED

| | |
|---|---|
| Shape | O-Pipeline-hard. One unsigned-64 evaluation model shared by a parse-time constant folder, the interpreter, the semantic checker, the control-predicate loop and the sequence-function delegate |
| Final artifact | 4 files (`values.py` new, `sequences.py`, `scope.py`, `functions.py`), 243 human-effective LOC, 150 new test cases (90 functions) + a 3-row deletion in the repo's own fold table |
| Pass-rate history | batch 1 **0/11** (10 Nova + 1 Vega) → cut the control-predicate rule, made two boundary clauses concrete → six more review rounds (JTAG bytes stated literally, closed transfer list, the string-return split) → batch 2 **5/10** (accepted) |
| Patterns used | **F-52** (2/10, sole failure of both), **F-20** at argument level (3/10, one alone — accidental), **F-31** folder/interpreter twins (2/10, compound), F-10 (literal × operator matrix), F-12 (the repo's own fold table encoded three wrong identities) |
| Agent split | Accepted batch: Nova 5/10, no Orion or Vega. Batch 1: Nova 0/10, Vega 0/1 |

**Why it held.** Three causes, each the sole failure of at least one near-miss: collapsing two
stacked boundaries onto the nearer one (F-52, Nova #7 and #2 at 146/150), the `tms` accident (F-20,
Nova #5 at 147/150), and stale folder identities (F-31, twice, always with `tms`). 141 of 150 tests
killed nothing. The accepted rate, **5/10 = 50%**, is above the recorded 40% ceiling and was
human-accepted, the same as pyfakefs. Record it; do not treat it as a ceiling change.

**What the batches taught.**

- **Batch 1 was one rule.** Three tests for "a predicate must produce a value", added in review round 3
  to answer a reviewer, killed 8/11 and were BOTH near-misses' only failure. Replaying the saved
  patches picked the cut exactly (2/11 predicted) instead of the broader axis first tried, which fell to
  172 effective LOC, under the floor (L85, L86).
- **A concrete consequence sentence moves an axis, and then its mirror appears.** "A variable set to a
  negative value reads back as its unsigned form, and a sequence function receives the unsigned form
  of every value it is passed" took the scope test from **6/11 to 0/10** and under-reduction at the
  call boundary from **7/11 to 0/10**. Once concrete, 2/10 over-applied the rule one layer too early
  (F-52). Explicitness does not remove a boundary; it trades the error for its reflection (L87).
- **The replay is blind to description changes, in both directions.** The byte-response test failed
  every replayed batch-1 patch; stated in meta.md with one example ("the bytes 0x34 0x12 are the
  value 0x1234") it killed **0/10**. The replay projected 2/11 for the final suite; the batch read
  5/10 (L35).
- **The one run-deciding trap nobody designed was an accident.** Tests passed `tms=3` to JTAG, a value
  the probe API documents as 0 or 1 and the CMSIS-DAP layer masks itself. 3/10 plus Vega in batch 1.
  I had read Vega's batch-1 failure from the test NAMES as "JTAG width" and that framed a
  keep-or-cut decision; the assertion diff said `tms 1 != 3` (L92).
- **Eleven review rounds bought almost no difficulty.** Of the ~100 test cases added after the core
  slice, only the round-1 argument-domain test killed anyone, and it caught the opposite of the error
  it was written for. Every static-validation test, both literal matrices, the AP/DP widths and the
  byte test killed nothing (L90 counter-evidence, L91).
- **Reviewer-invented inputs cost rounds, not difficulty.** Rounds 8, 10 and 11 argued over a `-> str`
  sequence function that the repo does not have (23 return `int`, 16 return `None`). Resolved by
  doing both in the solution and keeping the contract silent on the one case tests could not afford;
  its tests killed 0/10 (L93).
- **A general principle keeps finding sites; a closed list ends it.** "Transfers keep only the bits
  their width names" drew `DAP_WriteABORT` twice (once via the scoping phrase "the Write functions",
  which it matched by name) and then read-side masking. Replaced by the exact functions the solution
  reduces.

**Reference bugs found.** Eleven, all by review gates, none by a batch: a function result never
reduced (deleted as "dead code" in the slice because the scope store normalised, but a result
reaches comparisons and shift counts without a store); compound assignment reading its target after
the right-hand side; control predicates bypassing the value check; variadic arguments bypassing it;
declaration predicates; JTAG TDO arriving as bytes from a real CMSIS-DAP probe; a `-> str` result
classified as a value; `DAP_WriteABORT` unmasked (resolved by scope, not code); a string-returning
statement crashing (introduced by me in round 9); three redundant normalisation points found by
mutation; and a string-argument sentence that banned `Message`'s own format string (description).
**One remained at acceptance:** a Low - the three-iteration while-loop test keeps a 5 s wall-clock
timeout that its read budget makes unnecessary.

---

### teavm-method-summaries (Java / TeaVM compiler: whole-program method summaries for the per-method optimizer) — ACCEPTED

| | |
|---|---|
| Shape | O-Pipeline-hard / O-Algorithm-correctness. New whole-program analysis (never-null returns + written-field sets, SPECIAL/VIRTUAL dispatch, `<clinit>` effects, simultaneous fixed point) consumed by four existing optimizer passes and wired into both TeaVM pipelines |
| Final artifact | 9 files (`MethodSummaries.java` new, `NullnessInformation(Builder)`, `MethodOptimizationContext`, RNCE, CCE, LIM, RFRE, `TeaVM.java`), 298 human-effective LOC, 26 new tests, 213 base tests |
| Pass-rate history | four platform gate rounds, no batch before acceptance (Dockerfile bind mount FAIL; Verify Solution + Solution Quality FAIL; Solution Quality FAIL; Auto Review Tests 1/3) → batch 1 **4/10** (accepted, Auto Review Approved 3/2/2) |
| Patterns used | **F-53** (4/10, lead, sole failure of three near-misses), **F-54** (2/10, one sole), **F-55** (2/10, compound), F-10 (straight-line × join) |
| Agent split | Nova 4/10. No Orion, Vega or Castor |

**Why it held.** One fixed-point direction decided the band: three of the four near-misses
failed only the mutual-recursion test. The rest came from the compatibility path (F-54) and the
all-instances sentinel (F-55). Every run touched exactly the reference's nine source files, so the
difficulty was not finding the scope. **21 of 26 tests killed nothing.** 4/10 = 40% sits exactly on
the ceiling: accepted, zero margin (at 22%/50% batch variance, the next batch could read too easy).

**What the batch taught.**

- **An explicit sentence did not transmit an algorithm's direction (L94).** "The most precise facts
  that hold for all methods at once, so recursion and mutual recursion lose nothing" is as direct as
  prose gets, and 4/10 still solved from the pessimistic end. All four were judged described AND
  inferable. This is the rare lever that stays hard after it is stated.
- **Every reference bug a gate found got a test, and those tests killed nothing (L90 counter-evidence,
  second problem).** Solution Quality found two real reference bugs (a VIRTUAL call to an absent class
  read as never-null and write-free; `SIMPLE`, TeaVM's default level, never built summaries). Auto
  Review asked for invokedynamic, arrays, a second optimized method, missing-class `initClass`, unknown
  calls in RFRE. 11 tests, 0 kills. Every agent got all of them right.
- **The one coverage-suggestion test that killed asserted the OLD behaviour (F-54, L17).** "Null-summary
  fallback" became `withoutSummariesEveryPassBehavesAsBefore`, 2/10, one sole failure.
- **Driver wiring is testable (Pattern 105).** "TeaVM passes summaries to every method" was flagged
  untested twice; a real `TeaVM.build` with a stub target and a looped `TeaVMOptimizationLevel` covered
  both pipelines in 37 s. It then killed 0/10, but it was the only thing that made the Solution Quality
  finding about `SIMPLE` non-regressible.
- **An unobservable frequency in the contract cost a Tests band (L96).** "Once per build" drew a High
  "untested" finding; the only discriminator was a bytecode agent counting the factory, which would
  also fail an agent building through its own overload. Dropped from meta.md.
- **Passers wrote more than the reference.** Median passing production diff ~425 effective lines
  (Auto Review) against the reference's 298; prompt tokens 12.9M-20.4M for passers, 9.5M-18.0M for
  failers.

**Reference bugs found.** Four by gates, plus harness bugs: (1) VIRTUAL call to a class absent from the
set got an empty target list, so "never null / writes nothing" held vacuously (Solution Quality R2);
(2) `SIMPLE` lazy pipeline never built summaries (Solution Quality R3); (3) direct `InvokeDynamicInstruction`
not invalidating RFRE caches in summary-aware mode, straight line and join (Auto Review at acceptance,
demoted to Medium as pre-existing, **still open**); (4) no test for an UNANCHORED recursive cycle (Auto
Review, Medium, **open**). Harness: a BuildKit bind-mount Dockerfile (FAIL, needs COPY), a new-mode
compile fallback that emitted a synthetic id outside f2p/p2p (Verify Solution FAIL), and stale XML
surviving an early runner failure (Medium, **open**).

---

## 3. CROSS-PROBLEM LAWS

| # | Law | Evidence |
|---|---|---|
| L1 | **Enumerated rules get transcribed; architectural impossibilities do not.** | pulldown 67% with every rule listed → 40% from one wall |
| L2 | **Globally-coupled beats pointwise, always.** Fixed points over a whole program hold their band across many batches; independently-implementable rule sets do not. | calyx held 10-40% over 13 batches; pulldown's rule set read 67% |
| L3 | **Scattered singleton failures mean the domain is separable — stop stacking traps.** | pulldown's 4 failures had 4 causes and no lever; adding rules would not have moved it |
| L4 | **Diverse failure causes at a low rate = healthy. One shared cause = unfair.** | calyx runs13: 6 failures, 6 root causes, all agent-fault |
| L5 | **The second axis of a one-sentence rule is free difficulty.** | calyx `@fixed_signature` ref cells, 28% kill |
| L6 | **Name-based shortcuts pass name-shaped suites.** Include one instance whose name breaks the pattern. | calyx v7 `std_mult_pipe`; costs zero pass-rate; csbindgen-struct-layout-fidelity: 1/10 treated any `NonZero*`-named struct as a niche integer (sole failure of an otherwise 70/70 run) |
| L7 | **Hardening surfaces your own reference bugs — 3 per problem, both times.** Every one would have shipped as an FP. | pulldown ×3, calyx ×3+ |
| L8 | **A test that pins where an ambiguity resolves is unfair even if your reference is right.** | pulldown removed 4 such tests |
| L9 | **An absolute meta sentence plus an unstated implementation exception costs a review round.** State exceptions in the same sentence. | calyx, three times |
| L10 | **Agent capability drifts upward between batches.** Ship at the low edge; a mid-band artifact can drift out of band while you iterate. | calyx Nova 0/18 → 3/9 in one day, harder artifact |
| L11 | **Patch completeness is independent of a green test run.** A worktree can carry changes the patches omit; every local channel inherits the contamination. | calyx: `Cargo.toml` dev-dep sat outside both patch scopes through 12 batches and every review round, caught only by Verify Solution |
| L12 | **A famous name overrides careful reading, even against a plain contrasting sentence in the prompt.** Cite the real external construction by name only if you want agents to retrieve and trust it over your text. | lyon-arcs-join: 9/10 Nova built SVG2's real osculating-circle arcs join instead of the stated same-radius variant |
| L13 | **A numeric bound in a test needs full justification or full elimination — a smaller magic number just buys one review round.** If a reviewer's objection is "this constant is unstated," remove the need for a constant (an invariant that's true by construction) rather than picking a smaller one. | lyon-arcs-join: exact count → unfair; `2x` bound → STILL unfair, same objection generalized; unsigned-angle-sum comparison → held (6 orders of magnitude separation, epsilon is pure float noise) |
| L14 | **A false positive is not always "the reference is buggy" — verify the reference before touching the solution.** A candidate's own extra defensive check can be the actual bug; the real gap is often that the hidden suite never exercised the input that exposes it. | lyon-arcs-join: candidate added `!miter_limit.is_finite() -> None`; reference verified bug-free by direct probe (infinity == 1e6 output); fix was 3 new tests, zero solution changes |
| L15 | **Mutation-kill counts do not predict agent-kill counts.** Mutations measure what your tests can DETECT; a batch measures what agents actually get WRONG. Build mutation coverage for FP protection; build composition cells (F-10) for difficulty. Never justify a hardening round on mutation evidence alone. | neva: the WaitAll barrier took mutation V10 from 0/12 to 2/15 and killed 0 of 10 agents; the trap that decided the band killed only 2 mutations. rust-minidump: the baseline-preservation axis was justified on "it reds 11 existing tests" and produced **0 baseline failures across 10/10 runs**. worldengine-orographic-precipitation: four of six DESIGN § 11 traps (wrap seam, steady state, mountain-start span, blend placement) killed 0 of 20 runs; the serialiser trap killed 11/20 through a mechanism I did not predict (F-28) |
| L16 | **One test usually decides the band.** Redundant tests still earn their place (fairness, FP insurance, coverage review), but hardening effort belongs on the un-tested intersections, not on more instances of a covered axis. | neva: 20 of 21 tests changed no outcome; the F-10 cell alone separated 2/10 from 4/10. datafixerupper-ordered-alternatives batch 9: **156 of 173 tests (90%) killed nothing**, 17 carried the band, and one of those 17 decided it. worldengine batch 2: 52 of 66 killed nothing, and three round-trip tests carried 23 of 46 kill events |
| L17 | **Reviewer coverage suggestions are free difficulty — take them.** They are written to close fairness gaps, and a fairness gap is by definition a behaviour the contract states but nothing tests, which is exactly where an agent can be wrong for free. | neva: the decisive test came from a Test Fairness coverage suggestion, not from the trap design **teavm-method-summaries:** 1 of 9 coverage-suggestion tests killed (null-summary fallback, 2/10, F-54); the rest 0 |
| L18 | **Refines L4 — a shared failure cause is unfair only when NO agent cleared it.** The test is reachability, not diversity. Check: did anyone pass? did near-misses get everything else? did the evaluators mark `description_clear: true`? was the FP panel clean? If yes, one dominant cause is a legitimate design wall (F-1/F-9 family), not a hidden requirement. | neva: 6 of 8 failures on one root cause, 2 passes + 2 at 20/21, accepted |
| L19 | **A wall that contradicts the repo's own published docs is a fairness bug that happens to be hard.** Concede it; do not buy it back by writing the contradiction into the meta. | neva: injected-dependency port remapping was the sole failure of 4 agents in an earlier round, and died to one line of the repo's own book |
| L20 | **A single-seam problem is BIMODAL: its pass rate is a coin flip, not a difficulty.** If one decision gates every killer test, batches swing wildly while the artifact only improves. The tell is a per-test kill table where the killers are perfectly correlated — every failing run fails the IDENTICAL set. Adding tests to that seam cannot stabilise it; they all die together. Fix by adding a lever whose failures are INDEPENDENT of the seam, and confirm via a kill table with two separated clusters. | customasm: 0/13 -> 90% -> 20% -> 57% -> 9%; agent-runs 3 had 3 failures on the identical 13 tests; the accepted batch showed a near-miss cluster (1-2 fails) and a deep cluster (18-19) |
| L21 | **An EXAMPLE appended to a general rule is read as the rule's scope, and can disarm the whole problem.** Rule-7 applies to examples, not just instance lists: keep the rule, delete the example. Note the example is usually added in good faith to clear a fairness flag — check the next batch's rate, because the fairness fix and the difficulty collapse arrive together. | customasm: "and spelling that width out explicitly leaves it whole" repaired a real 0/6 unfairness and took the batch to 90%; a later one-sided "contributing fewer than that does not" would have licensed a `>=` implementation |
| L22 | **Ask where the decisive test came from.** On two consecutive problems the band-deciding test came from a reviewer or FP-judge finding, not from the trap design. Budget review-response time as difficulty work, not as compliance overhead. | customasm: F-11 came from an FP-panel dissent and then killed 9/10; neva: the decisive cell came from a Test Fairness suggestion; rust-minidump: the top TWO killers (6/10 and 4/10) were both written in review response, rounds 25 and 26 of 28 |
| L23 | **Before complying with a review finding, check the repo.** A finding can be factually wrong, and complying can make your solution internally inconsistent or unsolvable. Verify the premise, then comply, contest, or comply differently. | numbat: Auto Review S1 demanded alias rejection that Test Fairness then failed; two fairness flags rested on a false claim about `unit_name`; S2's requested skip removal would have taken 2/10 to 0/10 because both passers deleted the tests it wanted graded |
| L24 | **A noun the format already defines needs its EXTENT stated, or agents read it in its natural-language sense.** Contract words like record / entry / block / section have a precise composite meaning in the file format and a smaller, more local meaning in ordinary English. The local reading is the one agents implement, and it is invisible to any fixture where the two coincide. | rust-minidump: "a single **record** that declares no caller and also computes one is discarded" — 6 of 10 runs discarded only the offending ROW and kept the record live; the twin fixture with the contradiction in the header killed 0 (F-13) |
| L25 | **For a tolerance rule ("allow one, stop at the second"), the discriminating fixture is the UNDER-threshold case.** The at-threshold fixture — the one the rule is literally written about — passes under both the correct reading and the stop-at-first reading. Author the N-1 case and assert that nothing happened. | rust-minidump: `a_second_reduced_frame_ends_the_walk` (two events) killed 0; `degradation_is_summarised_over_the_whole_walk` (one event, asserts the walk continued and stayed `Ok`) killed 4 (F-15) |
| L26 | **A concision trim on API prose can manufacture a compile-error kill cluster — check what a removed clause was load-bearing for.** Description reviewers optimise for brevity and cannot see the test crate. Removing a phrase that named a parameter, a return shape, or a type is not the same class of edit as removing a redundant behavioral sentence. | lyon-fill-internal-vertices: R3 added "that takes a boolean" to clear a signature-ambiguity WARNING; R4 removed it on a description reviewer's HIGH concision suggestion; batch 3 then had **4 of 10 runs** build a zero-argument builder and fail to compile (F-16). Auto Review still ruled it fair on repo convention, so the trim was survivable — but it was luck, not design. cwerg-bcopy-bzero-lowering: "Both instructions work wherever they appear, however many times" was cut as unnecessary; batch 1 then read **9/10** on the multiplicity program (F-32) with no sentence to trace it to. Restored before batch 2; sfepy: reviewers asked three times to cut "whatever `adapt_fun` sets", the clause behind 7/13 kills |
| L27 | **Your test helper is part of the contract surface — write it in the contract's vocabulary, not in the cheapest one.** When the helper computes a structural proxy for a semantic property, author and agent adopt the same wrong abstraction and the suite is blind to exactly the gap it exists to measure. | lyon-fill-internal-vertices: a topological `interior_vertex_count` proxied a geometric "full neighborhood" contract; an FP panel found a non-manifold interior vertex passing; the replacement direct check became the top killer at 8/10 and the sole failure of both near-misses (F-17) |
| L28 | **An FP panel that voids EVERY pass is a test-completeness report, not a difficulty verdict — read whether the FPs are correlated.** If each voided pass failed a DIFFERENT probe, the gaps are independent and closing them costs one run each. If they all failed the same probe, closing it zeroes the batch. | lyon-fill-internal-vertices batch 2: 4/4 passes voided, but on four different probes (rotated overlaps / self-crossing contours / non-manifold interior / epsilon collinearity). Closing three and deliberately declining the fourth (an f32-noise-floor probe) took 40% raw -> 1/10 genuine instead of 0/10 |
| L29 | **Every assertion you add to close a hole is an assertion nobody has fairness-checked.** Tightening and fairness pull in opposite directions, so a hole-closing round silently manufactures unfairness. After EVERY such round, re-run the fairness pass on the NEW assertions only, asking one blunt question each: does the description state this, in words an agent could read? If no, there are exactly two honest options — state it in the description, or drop the assertion. Never keep a hidden requirement because it kills a mutation. **The asymmetry is the point: an unclosed hole costs one risk; an unfair test fails correct agents and cannot be repaired after shipping.** | lyon-fill-internal-vertices: R4 closed FP holes by adding baseline preconditions; R5 Test Fairness then flagged **6 of 45** tests, all of them assertions added in R4, all pinning the pre-feature mesh. Fixed by stating the current behavior in the meta (one sentence) rather than deleting the checks. Repeated verbatim on datafixerupper-ordered-alternatives: the round that closed Auto Review's T3/T4 partial-path gap added two ordering tests, and the very next Test Quality pass flagged **exactly those two** as the only unfair tests in 48 - they pinned identifier-before-diagnostic WITHIN a candidate block, which no sentence states |
| L30 | **A test flagged as unfair has two repairs, and only one keeps the difficulty: state the rule, or delete the test.** Deleting is the reflex under review pressure and it silently spends your band. Check first whether the behaviour is already observable on base — if it is, the test is fair and the description is what is missing. | gluon-format-comments: the block-comment layout test was deleted in round A5 as pinning unstated layout, restored in A10 once meta stated the rule, then took **7 of 11** and was the sole failure of the closest near-miss. An agent contested it as an undocumented convention; the contest failed because the UNMODIFIED formatter already breaks that record |
| L31 | **A feature that invalidates an existing repo test manufactures a cheat trap.** The solver must update stale expectations to be correct, and editing repo tests is scored as cheating. Skipping those tests in base mode protects your numbers, not the solver. Prefer a contract that leaves existing expectations intact; if you cannot, expect to lose runs to PASS_CHEATED and say so in the submission notes. | gluon-format-comments: 3 runs across 2 batches scored PASS_CHEATED for editing `format/tests/pretty_print.rs`; 2 of the 5 tests they rewrote are ones the feature legitimately supersedes |
| L33 | **A mutation battery scoped to your NEW tests cannot see a baseline-preservation trap, and its silence reads as proof the requirement is vacuous.** An S3 trap's discriminator is an EXISTING test by construction, so run every mutation against BASE mode too. Corollary: "no fixture I own catches it" is a statement about your problem configuration, not about the repo. | sfepy-adaptive-stepping-accounting: removing the final-step clamp's `clear_lin_solver` left all 74 new tests green across four probed configurations (explicit/implicit stepper, cached/plain matrices, presolve on/off, `maxdiff = 0.0` every time), so the sentence was cut from meta.md and the code deleted as dead. The next base run returned **220 passed, 1 failed** on the repo's own `test_ed_solvers`, which uses `use_presolve: True` over five ED solvers. The trap was real; my own problem used the EXPLICIT velocity-Verlet solver with presolve off, where a stale factorization cannot change the answer |
| L32 | **A counterfactual over an old batch is valid only while the test suite is unchanged. Once it changes, run the differential harness instead.** Subtracting test names from an old failure list silently assumes the artifact the agents faced is the artifact you are shipping. | gluon-format-comments: projected 2/12 from batch-1 data after adding 11 tests, and batch 2 returned 0/14. Re-projected by APPLYING the near-miss runs' own patches to the reduced suite (two scored 37/37), and the next batch returned a legitimate pass |
| L34 | **A fairness disclosure is a difficulty DEBIT that settles one batch later.** Every clarification you write to clear a fairness flag also hands the fix for whatever trap that sentence was hiding. The edit looks locally correct and the collapse is invisible until the next batch. Pay the debt in the SAME round: when you disclose, add an orthogonal trap alongside it. | vrp-tsplib: three consecutive fairness rounds (DISPLAY_DATA_TYPE scoping, header-ordering, GEO restatement) took the display-data cluster 2/9 -> 0/10 and GEO 1/9 -> 0/10, leaving ONE surviving trap and a 50% batch. Also customasm L21, where the fairness fix and the difficulty collapse arrived together |
| L35 | **The differential harness measures a TEST-suite delta; it cannot measure a DESCRIPTION delta.** Replaying old passing patches through a hardened suite counts every agent who did not know the new rule -- but the next batch reads the new meta.md and most will implement it. Treat the harness kill count as an UPPER BOUND. When the hardening added a description sentence, discount it hard; when it only added tests for already-stated behavior, trust it. Refines L32, which prescribes the harness without bounding it. | vrp-tsplib: the ascending-node-order lever killed 3 of batch 11's 5 passing patches in the harness and **0 of 10** in batch 12. Those five never read the ordering sentence; the next ten did. **Largest instance measured:** datafixerupper-ordered-alternatives iteration 67 replayed both batch-8 passers against the reduced suite and BOTH failed (5 and 3 of 173), projecting **0/10 = unsolvable-reject**; batch 9 returned **5/10**. The projection was 50 points low because the round had rewritten the contract those two solutions were built against — when the description delta is a DELETION, the harness is not merely an upper bound, it is nearly uninformative **pyocd-sequence-expression-kernel:** the replay projected 2/11 for the final suite (0/11 with the byte test); batch 2 read **5/10**, and the byte-response test that failed every replayed patch killed **0/10** once meta.md stated the byte form with an example. |
| L36 | **Stale no longer means re-run: a tests-only round re-grades at ~30% via RE-EVAL, and the button's presence is the L35 test.** Editing `test.patch` / `solution.patch` leaves the agents' solving valid (same prompt, same repo), so the platform re-runs grading + evaluation over the last batch's solutions for roughly 30% of batch price. Editing `meta.md` / title / environment invalidates the solving and there is no button. Consequences: freeze the solver-visible surface BEFORE the first batch and iterate tests after it; never fire a smoke run while a re-eval is pending (any fresh run dismisses the offer); and treat re-eval as PAIRED steering over one fixed solution set, not a fresh sample — it cannot re-roll the batch variance that made one artifact read 22% and 50%. Operationalizes L32 (the differential harness, now run by the real grader) and mechanizes L35 (no button = your lever was a description delta). | Platform update 2026-09-03. Local precedent: gluon-format-comments needed a full batch to learn that dropping one printer axis turned 0/12 into a legitimate pass (L32); vrp-tsplib needed batch 12 to learn the harness had over-counted 3 kills to 0 (L35). Both are now re-eval-shaped questions |
| L37 | **An FP panel's defect report is DIFFICULTY, not just fairness debt — harvest it as a trap.** L17 says reviewer coverage suggestions are free difficulty; this is stronger. A false-positive finding names a behaviour a passing agent got WRONG, which is by construction a live discriminator, and the fix is a test you can write in an afternoon. Treat every FP report as a trap proposal, and re-read EVERY passer's diff for the same defect class -- the panel names the instance it can see, not the class. | go-workflows: the FP panel flagged one passer's `Select` regression; reading the other passers found the IDENTICAL defect in a second run the panel cleared (true FP count 2 of 3, not 1). The guard written from it became F-20 and decided the band (8/10, both near-misses). The trap I designed myself, the arrival-order queue, killed 2/10 |
| L38 | **When one fair trap kills ~100%, the lever is WHEN-discoverability, not deletion.** A cluster of tests failing in every run is not automatically over-strict: if it is one root cause and the contract already states the behaviour, agents are missing WHEN the behaviour must hold, not THAT it must. Restating the timing in the existing sentence, naming no API, is the cheapest lever measured on a 0% batch. | go-workflows scheduler-resumption cluster: 5/5 kills at batch 10 (0/5 overall). Changing "both proceed on their own" to "both **resume before the scheduler run that drained them finishes**" -- one clause, no new requirement, reference already conformed -- dropped it to **1-2/10** at batch 11 and the batch passed 2/10. Deleting the cluster was impossible: all 5 tests were one insight, so any subset left the near-miss still failing |
| L41 | **A promise about an object you do not own may be physically unimplementable — scope it to the implementations that can honour it.** Before writing a contract sentence about a caller-supplied abstraction, check whether that abstraction's own contract permits the effect. If any conforming implementation cannot exhibit it, the sentence is false for a whole family and no amount of implementation work repairs it; a reviewer reads the sentence, not the family. Put the general guarantee on the value you RETURN, and scope the convenience guarantee to the implementations that can carry it. Sibling of L39 (a contract sentence is a liability): L39 is about the reference failing a sentence it could satisfy, this is about a sentence nothing can satisfy. | datafixerupper-ordered-alternatives Iteration 57: meta.md promised "a caller who finishes the supplied builder still sees the failure". `RecordBuilder` returns a new builder from every operation, so a PERSISTENT implementation cannot be annotated at all - probe printed `SUPPLIED -> Success[{}]` beside `RETURNED -> Error['Alternative 0: bad']`. Solution Quality scored it a HIGH comprehensiveness defect. The tests had drawn the line correctly all along (supplied-builder assertions all used the mutable `JavaOps.mapBuilder()`, persistent cases asserted the returned builder); only the description over-promised |
| L40 | **A reviewer's suggested test is a hypothesis, not a spec: replay it against the saved PASSING patches before you ship it.** A defect finding in the REFERENCE is a solution fix and always safe; the regression test the same reviewer asks for is a difficulty change and can be fatal. Fixing the reference costs nothing in band; pinning the fix can cost the whole band, and the two arrive in the same paragraph as if they were one action. Run L32's differential harness on every suggested assertion, ship the ones the passers survive, and decline the rest IN WRITING with the measured kill counts. Refines L17 (reviewer coverage suggestions are free difficulty) with its exception: free only until it kills your last passer. | datafixerupper-ordered-alternatives Iteration 56: Auto Review filed an S1 High x3 on the MapCodec supplied-builder lifecycle and asked for "regression cases for each overload using a saved JsonOps map builder". The defect was real and the reference fix was ~30 lines. Replaying the three suggested cases against both batch-8 passers: **both fail all three**, and worse than the old reference did. Shipping them would have moved 2/10 to **0/10** = unsolvable-reject. The other 9 suggested/advisory tests were replayed too, both passers went 159/159, and all 9 shipped. Confirmed again on dfu-derived-recursion: the Blocker's suggested cross-group DataFix regression test failed the ONLY passing run (84 tests / 1 failure), i.e. 0/10 — the reference fix shipped, the test did not. |
| L39 | **A contract sentence is a LIABILITY as well as a fix — re-audit the reference against every sentence you add.** Adding a meta.md sentence to make a test fair also enlarges the surface the REFERENCE must satisfy, across the full domain of the new words, not just the scenario the new tests exercise. | go-workflows: the sentence added to justify three wake-up tests ("a value arriving while such a case waits must also run it") was immediately violated by my own reference on zero-capacity channels -- a parked Drain case was a progress-notification target but not a rendezvous target, so a nonblocking send was silently dropped. Caught by Solution Quality, not by me, one round after I wrote the sentence |
| L42 | **When a reviewer demands a test for a quantity the description leaves under-determined, the description edit comes FIRST and the test second.** A coverage finding of the form "nothing discriminates the sign / the normalisation / the convention" is really two findings: the suite is weak AND the prompt is ambiguous. Writing the assertion alone converts a fair problem into an unfair one, because the passing value was never derivable. Writing the sentence alone leaves the finding open. Do both, in that order, and say in the response which words you added. The edit is only free BEFORE the first batch (L36) - after it, a description edit costs a full-price batch while the test alone would have re-graded at ~30%, which is exactly the pressure that produces the unfair version. | rocketpy-propellant-slosh Round 5: Auto Review filed a High on "no assertion discriminates the force-per-total-mass drive coefficient", naming a sign reversal and a dry-mass divisor as passing wrong implementations. `meta.md` said only "driven by the body frame lateral force per unit mass acting on the rocket" - which fixes neither the sign nor whether gravity counts. Probing showed body-frame gravity at 5 degrees of tilt is 0.85 m/s2 against a real drive of 0.027, so a gravity-including implementation is a factor of 30 out and was passing. Added three clauses (total mass, gravity excluded, mode driven the other way) and then the tests; mutations m1/m2/m10 each die on exactly one of them |
| L43 | **To pin a WEIGHTED combination without reimplementing the physics, test its null space.** Reviewers ask for "assert the mass-weighted rate and acceleration enter the vehicle equations", and the obvious answer - recompute the 6-DOF right-hand side in the test - is both enormous and fragile. Instead build a state where the combination cancels under the CORRECT weights, and assert the downstream observable is bit-identical to the state where every term is zero; then build one where it does not cancel and assert the observable moves. The pair pins existence and weighting together, needs no expected value, and the tolerance gap is enormous: the correct weighting cancels to exactly 0.0 while an equal-weight implementation leaves a residue six orders of magnitude above the float noise. | rocketpy-propellant-slosh Round 5: two modes with participating masses in a 4:3 ratio. Velocities with `m1 v1 = -m2 v2` leave the 13 vehicle derivative entries changed by **0.0**; equal-weight cancellation leaves **2.4e-6**; a nonzero net rate leaves 9.5e-6. Same trick for the acceleration: displacements that cancel the OFFSET but not the accelerations move the vehicle by 0.037, which is only explicable through `r_CM_ddot`. Four tests, no physics duplicated |
| L44 | **Deleting an unimplementable contract clause costs BAND, and the bill arrives in the next batch — budget a replacement trap in the same round.** L41 tells you to scope or delete a promise nothing can honour; this is what that costs. The clause was carrying difficulty precisely because it was hard, and removing it also removes every test that pinned it. The correctness argument for deletion is usually airtight, which is what makes the difficulty loss invisible: no reviewer will mention it, and the artifact reads cleaner afterwards. Pair every soundness deletion with an orthogonal lever, exactly as L34 prescribes for fairness disclosures. | datafixerupper-ordered-alternatives: iteration 67 deleted the whole supplied-builder marking contract (an `ops.mapBuilder()` surrogate, ~140 lines) plus the 9 tests that asserted it, after **eight** consecutive Solution Quality rounds filed findings against it and the ninth named the mechanism outright. The deletion was correct — it fixed a real S1 and the P4 density flag at once. Batch 8 with the clause read **2/10 = 20%**; batch 9 without it read **5/10 = 50%**, over the current 40% ceiling. +30 points for one soundness fix |
| L45 | **The prompt sets SOLUTION QUALITY, not just fairness: softening a clause lowers how much machinery agents build, so a fairness edit can turn a passing batch into 0% with the tests unchanged.** When a batch collapses after a description edit, replay the OLD batch's saved solutions against the CURRENT suite before you touch a single test. If the old population still passes, the suite is fine and the prompt is the variable. Restore pressure with a clause that NAMES the surviving discriminators behaviourally while promising nothing about iteration counts or unbounded scale - the unbounded version is what generates the FP (L44's cousin, arrived at from the opposite direction: L44 is deletion costing band, this is SOFTENING costing band). | customasm-derived-bank-layout: 20 saved solutions replayed against ONE fixed suite. Batch 2, solved under "works whatever order the definitions appear in" (unbounded), scored **5/10**. Batches 3 and 4, solved after that clause was bounded to "a bank may be placed at the end of a bank whose definition appears later in the file", scored **0/10**. Same model, same tests, 15-point-plus swing from wording alone. All five batch-2 passers were probed against the reference on six stated-clause programs and agreed everywhere, so the higher rate was real capability, not luck |
| L46 | **Fix the reference for an integration finding; do NOT add a fixture for behaviour meta.md never names.** Solution Quality reports defects in directives, padding categories and output-stage edges the description never mentions. The reference fix is free and correct. The matching fixture turns an unstated requirement into a gate the whole population fails, and even when it changes no verdict it displaces the near-miss agent's blocker so the closest run stays stuck. Keep a written list of the nouns meta.md actually names and check every review-response fixture against it. Sharpens L40 (replay a suggested test before shipping it) with the prior question: is the behaviour even stated? | customasm-derived-bank-layout: I removed an `#addr` fixture on exactly this ground, then two rounds later added `err_backwards_addr_never_settles`, also `#addr`-dependent, in response to a reviewer finding. It killed 5/5 Nova, changed no verdict, and displaced the previous blocker so the closest Nova stayed at exactly one failure. Removing it plus the label-alignment extent fixture took batch 2 from **1/10 to 2/10** and produced the first Nova pass in 19 runs. The same discipline later SAVED the accepted pass: the FP adjudicator cleared it because the align fixtures only ever tested align WITH following content, ruling the trailing-align divergence "an underspecified edge... it cannot fairly gate the reward" |
| L47 | **Parametrise a "works for all forms of X" axis by what the IMPLEMENTATION distinguishes, not by what looks varied to a reader.** Spellings a human calls different are one cell to the code; the cells that kill are the ones the repo's own validator treats differently. | rocketpy: 7 callable spellings shipped, only `defaulted` and `keyword_only` killed (6/10 each); `partial`, callable-instance and `*args` killed nothing because `Function` accepts them. Read the wrapper's `inspect.signature` logic to find the boundary before writing the matrix |
| L48 | **A representation-tolerant reader in the test suite is FP-panel armour, not just fairness hygiene.** A helper that accepts every shape the contract permits is executable documentation of the permitted domain, and the adjudicator will cite it against a dissenting judge. | rocketpy FP panel: judge-c filed a solo `false_positive` on "no-slosh `slosh_mass` must be callable"; the adjudicator rejected it at high confidence *"contradicted by the verifier's OWN reported_slosh_mass helper, which explicitly accepts a bare 0"*. The helper had been added one round earlier purely to un-pin a representation |
| L49 | **A test that kills a run for a REPRESENTATION reason is visible in the run data long before a reviewer names it.** Treat "failed only on the shape of a returned value" as a fairness defect the first time it appears, not the third. | rocketpy batch 1: Nova #5 lost exactly the four `test_a_tank_without_slosh_has_no_participating_mass` cases by returning int `0`. The same pin was flagged by Test Quality at round 25, fixed at round 26, and was worth the whole band -- unfixed, batch 3 read **0/10 = reject**; fixed, the identical ten solutions read **1/10 = accepted**. featurevisor-minimal-rebucketing: batch 1 had 7 kill events from `formatRebucketing` return shape (joined string, per-change signature) and one-log-per-line counting; a shape-tolerant `renderLines` plus rendered-line counting removed all 7 and moved no pass (2/11 before and after). |
| L50 | **A bug a reviewer finds in YOUR reference predicts an agent failure mode — turn each one into a test.** You and the solvers face the same design pressure, so the mistake you made is the mistake they make. Every reference defect that got a regression test became a measured killer. | dfu-derived-recursion batch 2: the 3 tests written only to prove Solution-Quality findings took 4, 4 and 3 of 10 runs — 11 of 32 kill events — and grew the killing-test set from 5 to 8. The 79 tests the DESIGN was about killed nothing. worldengine: the round-1 reference bug (execute overwrote a supplied wind) became `test_a_supplied_wind_is_kept_by_execute`, 4/10 in batch 2 (F-29 twice, F-16 twice). tippecanoe-tile-join-size-recourses: both measured killers (F-33 3/10, the F-15 cells 4/10) were reviewer findings against the reference first, while every trap the design named took 0; sfepy: F-34 (8/13) was Auto Review R21 on the reference; the hook cell (7/13) grew from R27 and R36; planetiler-custommap-schema-composition: BOTH measured killers were Solution Quality findings against the reference (R1 same-file removal, F-38 7/10; R4 standalone bundled examples, F-9 3/10), while every trap the DESIGN named (args fixed point, position rule, raw-vs-accessor scalars, diamond, cycles) took 0. featurevisor-minimal-rebucketing: both measured killers started in the reference. The Solution Quality `__proto__` finding became F-40 (7/11); the free-range helper the first kernel reused became F-39 (3/11). Nothing the design named killed. |
| L51 | **In a long review cycle most reference bugs are FIX-INDUCED: after each reference fix re-run the whole matrix AND the agent replay, and prefer deleting the mechanism over narrowing the guard.** A patch that adds a phase flag, a cached field or a mutable "current scope" to make one finding go away is the next finding. | dfu-derived-recursion: 4 of 7 reference bugs were created by the previous round's fix (lazy placeholder → NPE at registration → wrong-group resolution → lost identity wrapper). The chain ended only when the phase variable was deleted and placeholders were substituted eagerly. planetiler: letting the validator accept bundled names (R3) broke standalone bundled examples (R4); fixing that by inlining examples eagerly broke `--watch` for a missing or malformed spec file, found by Auto Review after acceptance |
| L52 | **A qualifier binds to its nearest clause: a sentence with two subjects and one "except" / "including" / "unless" is misread by the whole population, and the evaluators will still call the tests fair.** Move each qualifier to the other subject; if the meaning changes, split the sentence so every qualifier has one possible subject. A unanimous same-reason failure overrides a "fair" verdict (L18). | ray-optics batch 1: 10 tests failed in **11 of 11** runs on "The derivative of a comparison, `and`, `or` or `not` is 0, and the derivative of `if` is the derivative of the selected branch, except on the switching set". All 11 returned 0 for bare comparisons and built a switching guard for `if`. A round-12 precheck had independently asked for that sentence to be split |
| L53 | **The FP check reads the DESCRIPTION, not the suite. A spec dense enough that every clause is either tested (traps stack) or untested (FP exposure) has no clean pass: shrink the spec.** Before redesigning after an FP flag, probe every saved solution against every stated-but-untested sentence (Pattern 89); the violation table picks the clauses to delete. | ray-optics batch 2: the lone pass was FP-flagged. Probes over 10 solutions: order-independent `and` narrowing violated by 10/10, nested-`if` over-guard 8/10, invalid-only truth value 7/10, identity range 4/10. Deleting nested propagation, order independence and full invalid-operand precision gave batch 3 a clean 1/10; sfepy: cutting the restart lane (19 tests, two sentences) turned 0/8 and 0/9 into near-misses, then 2/15 |
| L54 | **Answer a PRECISION or DOMAIN-BOUNDARY finding with a scoped promise, not an emulation and not a test.** When a finding shows the description promised more exactness than the base design delivers (float width, completeness of an analysis), meeting it means changing base semantics or demanding a new analysis from every agent. Narrow the sentence and keep any extra precision in the reference, untested. Refines L46/L50: correctness findings become tests, precision findings become scope. | ray-optics: f32 intermediate rounding (full emulation would change every existing formula's numerics) became "agree while every value involved is exactly representable as a 32-bit float"; a later-operand feasibility test failed **14/21** saved solutions, 0 clean, and became "other unreachable branches may still be included". The next batch was accepted |
| L55 | **L50 has a budget: a regression test for EVERY reviewer finding multiplies to zero.** Each finding is a 30-60% trap and eight independent ones give ~0%. Test the few with the highest predicted kill, preferably sharing a root cause with a designed trap; fix the rest in the reference only. | ray-optics: 11 precheck rounds, one test per finding, batch 1 **0/11**; a local re-grade with both description walls removed still read 0/11 (1-8 failures per run). After pruning, three reviewer-finding tests carried 17 of 40 kill events at an accepted 1/10 |
| L56 | **A test that shells out to a tool the Dockerfile installs will fail Verify Solution, whatever the local clean-room says.** Keep validators in-process, inside the test file. | ray-optics: a `naga-wasi-cli` WGSL validity test passed every local clean-room (fresh clone, `--network none`, non-root) and failed Verify Solution on two separate platform runs; Task Quality called it an undeclared dependency once and passed it once. An in-process operator / bool-`select` check replaced it: 0 false rejections over 43 shaders x 22 implementations, both injected defects caught |
| L57 | **Placement prose about a NEW stage is read as a statement about where the EXISTING stages stop.** "A new X step between A and B" makes agents repair step A to stop before X, even when the repo's A already runs past B. Nothing in the feature tests it, so the regression ships inside a grader PASS. State in one clause that existing steps keep every stage they run today, and pin that end to end. | worldengine-orographic-precipitation batch 1: **10/10** runs deleted `Step.plates`'s precipitation, erosion and biome flags; the two 65/65 runs carried the identical hunk and were graded PASS_LEGITIMATE and FAIL_REGRESSION. One sentence plus one end-to-end test: **0/10** in batch 2 |
| L58 | **Refines L1: on a cross-cutting feature a fully specified numerical kernel is free, including a closed-form fixed point. The band lives in the integration shape** (the concept's container representation, accessor form, lifecycle guards). Spend no hardening rounds on kernel cases; count them as LOC and FP insurance. | worldengine: 24 transport tests killed **0 of 20** runs across two batches, including the steady-state and weak-wind cases chosen as the harder reading; all 46 batch-2 kill events came from serialisation, pipeline, accessor and CLI integration. tippecanoe-tile-join-size-recourses: shedding order, attribute-pool compaction, the booking restructure and extent rescaling drew no failure attribution in 10 runs; 7 of 9 failures were `strategies` accounting cells. featurevisor-minimal-rebucketing: twelve allocation-kernel tests (lowest-first retention, declared-order refill, region cuts through later slots, sort-and-merge, idempotent rebuild) killed 0 of 11; all 16 kill events were a host-language key edge and an inherited helper. |
| L59 | **Never assert exact equality on a value a formula produces, even at a mathematically exact point.** Equivalent algebra lands a few ulps away, the review flags it as over-pinning (T5), and correct agents fail. Compare with a tolerance and keep discrete parts (direction, sign) exact. | worldengine batch 1: **5/10** runs returned 0.9999999999999993 or 0.9999999999999998 for a band-centre strength through `wind_at`; Auto Review Tests 1/3 cited it |
| L60 | **A parity promise between twin implementations imports every pre-existing divergence into review scope. Fix them all in the reference, but test only the divergences the feature's own inputs reach.** Each Solution Quality round finds another py/cc or undefined-behaviour asymmetry, and a regression test for one is a fresh trap unrelated to the feature (L55 through a new door). The FP adjudicator scopes "identical output" to what the feature exercises only when the fixtures stay inside that range. | cwerg-bcopy-bzero-lowering: about nine pre-existing divergences fixed over rounds 10-27. Testing float-DIV parity and narrow DIV/REM/CNTPOP chains took batch 5 to **0/9** (9/9 and 8-9/9 kills); a Docker replay without them read 3/9, and batch 6 was accepted at **3/10**. All three passes still fold signed DIV differently in Python and C++; every FP judge dissent on it was overruled as "pre-existing, task-unrelated... the hidden bulkwrap programs deliberately use only wrapping ops for lengths" |
| L61 | **Bisect a test that kills everyone against the near-miss's OWN patch before you touch the description: a breadth-only program can be reaching a pre-existing bug outside the feature.** Coverage programs added for reviewer breadth pick up whatever else the repo gets wrong for those inputs. | cwerg: the parity-only `bulkshapes` program killed **11/11** in batch 2 (1/10 in batch 1, before typed constants were loaded into it for reviewer findings). Bisecting Nova #10's build showed x64 diverging only on typed constants and a32/a64 failing in the Python backend on callee-parameter widening. Dropping it: re-eval **1/11**, projection exact |
| L62 | **The platform's environment start timeout (600 s) includes the Docker image build. Measure a cold `--no-cache` build, not a warm one.** Verify Solution reports `EnvironmentStartTimeoutError` while every local run is green. A C++ tool build followed by `chmod -R` over files from a lower `COPY` layer pays an overlayfs copy-up of the whole tree. | cwerg: cold build 704 s, `chmod -R a+rwX /app` alone 261 s. Moving COPY, build and chmod into one `RUN --mount=type=bind,source=.,target=/src` layer: 413 s, `/app` byte-identical (3080 hashes + modes), and batch 5 built in all nine runs. **2026-09-23: the platform Dockerfile check now FAILS a bind mount + `cp` (must use COPY).** Use `COPY --chown=1000:1000 . .` and chmod only directories and root-owned build outputs (`find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +`): teavm 431 s vs 816 s for a full `chmod -R`, and unmapped uid 4242 still applies patches (Pattern 91) |
| L63 | **In a compiled repo whose Dockerfile builds into `/app`, the build outputs are tracked files in the solver's sandbox. Agents `git restore` them to keep a source-only diff, the restore makes them newer than the edited sources, and a plain incremental `make` in test.sh then grades the BASELINE binary.** The batch reads as universal failure with no per-test signal, and evaluators flag runs as verifier blockers. Make test.sh rebuild what it tests regardless of timestamps (`make -B <targets>`, or delete the tracked outputs first), or be ready to contest every flagged run with the trajectory call that did the restore. | tippecanoe-tile-join-size-recourses: 9 of 10 trajectories restored `.o` files or `tile-join`; evaluators said 7 runs were graded against stale or unlinked binaries, each failing 49/49. The only run that never restored was the only pass. Two ENV-blocked flags were contested with the restore call and upheld. All seven also had a separate source defect, so forcing the rebuild would likely have left the rate at 1/10 while keeping the JUnit files usable |
| L64 | **The working pool is cumulative: a later batch folder re-lists every earlier run under new numbers and appends the new ones. Fingerprint runs (added LOC plus prompt tokens) before mining, or every kill counts twice and the appended runs look like repeats.** Mine only the latest folder. | sfepy: the accepted folder held batch 10's 12 runs renumbered plus 4 appended (Nova, Orion, Vega x2); Auto Review's "2 of 15" is the pool |
| L65 | **A zero from a Nova-heavy batch, with near-misses failing STATED sentences, measures the agent, not solvability. Add Orion or Vega runs before cutting a fair requirement.** Check fairness first: probe the near-miss patches to confirm they truly violate the sentence (Pattern 93). | sfepy: Nova 0/11 with two runs at 116/117; the 4 appended runs held both passes (Orion 1/1, Vega 1/2) |
| L66 | **When a reviewer flags PRE-EXISTING behaviour next to the feature, fix it in the reference and add a test only if meta.md already states that behaviour.** Otherwise the test is a hidden requirement, and it reads as a same-reason wipeout, not as difficulty. Sharper than L55: one such test is enough. | mwparserfromhell: Solution Quality R6 flagged base tag pairing (`lower()`), a test for `<ß>x</SS>` followed, and batch 1 read **0/20** with 19/20 failing it identically; meta.md only stated caseless RECOGNITION. Dropping the one test: **2/19**, accepted, and no reviewer re-raised it |
| L67 | **An "identical output" contract between twin implementations is satisfiable by delegation, and FP panels uphold it. Never count the second arm's machinery as a trap.** Budget LOC and difficulty as if the passer implements one arm plus a forwarding stub. | mwparserfromhell: both passes forward from the C tokenizer to the Python tokenizer when a site is given, 8 of 20 batch-1 runs delegated, the FP adjudicator called it "correct for tree parity", and the leanest passer measured 221 human-effective against the reference's 405 |
| L68 | **For a tests-only change, a local Docker replay of the batch's saved patches predicts the re-eval run for run. Project from the pool, not the folder: the pool can drop runs.** | mwparserfromhell: identical failure counts on all 19 runs the re-eval kept; the pool dropped a projected passer that had edited repo tests, so 3/20 projected, 2/19 measured. featurevisor-minimal-rebucketing: the R4 replay matched the re-eval on 11 of 11 runs (2/11, same failing tests); only two Vega run labels swapped between folders. |
| L69 | **A kill cluster that fails at the SAME index with a sentinel value (silence, zero, empty, timeout) is a harness boundary until a replay says otherwise, and L18's checklist cannot tell.** Passes exist, near-misses clear everything else, every evaluator writes `description_clear: true`, the FP panel is clean, and the cluster is still unfair. Replay the failing patches with the boundary relaxed before believing the pass rate. | kira-loop-crossfade: 6 of 7 failures at frame 47 (one at 24) reading 0.0; the relaxed replay passed all six at 55/55; 7/7 evaluators called them fair; accepted 3/10, fair suite 9/10 |
| L70 | **A test that throttles one resource and asserts on another encodes the reference's exchange rate between them** (decoder calls to output frames, packets to bytes, allocations to items). Assert only what the throttle provably yields in the worst case, or render until the first gap, then release and check the transition. This is L13 one level down: replacing a named constant with a gate just moves the constant into a ratio. | kira: round 1 removed a hard-coded 16384; round 4's 60-call gate plus 48-frame assertion matched only the reference's queueing (eager-prepare schedulers queue 47) |
| L71 | **An "eventually settles to X" assertion is vacuous unless X is impossible without the action under test. Run the action-ignored mutant on every such test.** Periodic output (loops, retries, polling) produces the expected steady state by itself, and a duplicated first frame lets a settle window step past a wrong one. Seek after the first pass, or require every heard value to be legitimate. | kira: 4 of 4 seek tests of this shape passed with the seek ignored or unblended (past-end static and streaming, forward seek-into-fade x2), all caught by mutants before the batch |
| L72 | **Name every new API the tests call with its full call shape (static or instance, parameter types). An unstated shape costs a whole batch: one compile error in a shared test unit zeroes every test in every run and measures nothing. Before paying for another batch, replay the saved patches with a one-line adapter to the tested shape.** Promotes candidate C-5 (second source). | planetiler batch 1: meta.md said "`SchemaConfig.files` returns the contributing files"; **8/8** Nova made it an instance accessor (7 as a record component) and all 83 tests failed to compile. A shim `static files(Path) { return load(path).files(); }` on each saved patch read **2/8** with the top killer at 5/8; the fixed description then measured **3/10** with the same top killer at 7/10. parley-justification-modes (C-5): 0/N on one enum payload type |
| L73 | **The verifier grades inside the agent's container, so an agent's build commands can break grading after the solution is done. In a Maven reactor that relies on a flatten profile, an agent's plain `mvn install` of a dependency module writes an unflattened POM whose parent is the literal `${revision}`, and the offline test run can no longer resolve anything.** Make test.sh detect that signature, reinstall the module offline with the profile, and retry once. Sibling of L63. | planetiler batch 1: 1/8 (the run's trajectory shows `mvn -o -pl planetiler-core -DskipTests install`); reproduced in the built image as uid 1000 with the agent's exact command: old test.sh 1 synthetic case, repaired test.sh 431/0 base and 83/0 new |
| L74 | **A host-language edge found by review can decide the band and still be accepted, but reviewers discount it as a tripwire.** When most failures are one special-key or one host-semantics cell, the agent-run review reports the strict pass rate as overstating difficulty. Pair such a cell with a core-algorithm killer so the failures are not mostly one edge. | featurevisor-minimal-rebucketing: `__proto__` took 7 of 9 failures, six of them near-misses at 33/34; the Auto Review filed a High "difficulty discrepancy" (effective difficulty "two full passes and six near-passes") and still approved, carried by the independent F-39 cluster (3/11) |
| L75 | **Exact-boundary semantics are only testable on binary-exact geometry. A trajectory or approximated shape that lands within float noise of an edge turns an epsilon policy into a kill.** Circle centroids come from a buffered polygon and miss the exact centre by an ulp; a robot integrated at 0.1 m per step can land an ulp either side of the edge. Put inclusive/strict boundary cells on squares at dyadic coordinates, and treat a dynamic crossing near an edge as a measurement of rounding, not of the rule. | ir-sim-scenario-events: three edge/threshold tests passed by chance on circles (centroid 2.000000000000001) until moved to squares; 2/11 agents failed the remaining dynamic `leave` cell by widening the closed rectangle 1e-12 (logged 2.1 instead of 2.0); the Auto Review still called it fair |
| L76 | **When a reviewer-found reference bug is one every agent shares (N/N), keep the fix and do not ship its test unless meta.md states the behaviour.** The test zeroes the batch, and a description that promises the opposite makes it a hidden requirement. Expect an FP-panel judge to probe the passer on it anyway; the adjudicator rules it out of scope. Refines L50/L55/L66. | ir-sim-scenario-events: the id-rewind regression test (created-but-unadded object keeps its id across reset) killed **11/11** in the local replay, the lone passer included, against a meta.md that promised "the same ids" on replay; shipped without it at 1/11; FP judge #2 flagged the passer on that probe and the adjudicator called the probe unfair |
| L77 | **Naming the root cause of an N/N inherited gap in one meta clause takes it to 0/N. It restores fairness; it buys no difficulty.** Use it when a reviewer-found reference bug is shared by every run and the behaviour is already implied by the contract, and budget the band on the other walls. | featurevisor-target-specialization: the `{`/`[`-only condition parser was in 10/10 batch-1 solutions and the reference; "stringified in any form the builder writes today, scalar JSON included" -> 0/10 kills in batch 2, which read 3/10 on the other walls; csbindgen-struct-layout-fidelity: the niche-Option array cell (two stated rules combined) killed 8/16 in batch 3, one clause naming the combination -> 0/10 in batch 4 |
| L78 | **When test.patch removes repo specs the feature supersedes, some agents update those specs themselves and are graded PASS_CHEATED.** The run counts as a failure however good the solution. Expect about one per batch and read the strict rate with that in mind; do not treat it as a difficulty signal. | featurevisor-target-specialization: 1/10 PASS_CHEATED in each batch (24 `applyContextToDatafile.spec.ts` / `buildDatafile.spec.ts` cases removed by test.patch) |
| L79 | **Every fixture the suite generates must be asserted or deleted. An unasserted fixture is an FP trap: a candidate that gets it wrong still passes, and the FP panel voids the pass.** Refines L76: when you drop an unfair test, drop its fixture too. | csbindgen-struct-layout-fidelity: ScopeOne/Two, LeftHolder/RightHolder, PtrAliases and DeepAlias were listed in TYPES but unasserted after four rounds of skipping reference-only tests; the FP panel ruled **3/3** batch-2 passes false positives on exactly those structs. A programmatic TYPES-vs-assertion audit kept every later round clean |
| L80 | **A contract sentence that promises a host-language semantic in full (name resolution, module scoping, overload rules) turns Solution Quality into an unbounded ratchet. Narrow the contract instead of chasing.** Each fix exposes a narrower corner the reviewer can ground in the same sentence. | csbindgen-struct-layout-fidelity: "a const or alias name resolves in the module that uses it" -> **11 consecutive Solution Quality FAILs**, each a deeper scoping corner, with the pass rate unmeasured throughout; deleting the sentence and the const-name feature -> next Auto Review **approved 3/3/3**, batch accepted at 1/10 |
| L81 | **An enumerated list in a contract sentence reads as exhaustive.** Agents treat anything the list omits as unsupported, even when the general rule covers it. Name every member the tests use, or state the rule without a list. Extends L1. | csbindgen-struct-layout-fidelity: "pointers, `usize`, `isize`, `c_long` and `c_ulong` take 8 bytes" -> **7/16** gave `c_float`/`c_double` no layout; adding "`c_float` takes 4 and `c_double` 8" -> **1/10** |
| L82 | **Never assert the repo's own self-consistency checker once the feature changes what it checks.** `isIndexValid()`-style validators recompute internal bookkeeping their own way and demand exact equality, so any sound-but-different representation fails while every query answer is right. That is a representation pin, not a behaviour. Assert the behaviour (oracle comparisons on a deep tree) instead; the base suite's own calls stay as they are. | libspatialindex-tpr-temporal-knn batch 2: **9 of 10** blocking failures were `ASSERT_TRUE(scene.tree->isIndexValid())` after entry expiry changed node-bound maintenance; five runs failed ONLY that. Removed, the same ten solutions replayed at **5/10**, and the five near-misses passed the very oracle comparisons the ASSERT had been aborting |
| L83 | **When a differential probe finds zero divergence among passers, the derivable surface is exhausted: stop adding cells and look for state the repo discards.** Grep the persistence and aggregation layers for a field the write path never mentions, a commented-out read, or a sentinel assigned on load, and make the feature depend on it (F-47). Reviewer coverage suggestions (L17) buy nothing against a converged population. | libspatialindex-tpr-temporal-knn: 57 probes x 7 passers = 0 divergences, 16 coverage tests (every advisory suggestion) = 0 new kills, 4 composition cells = 0; the per-entry end of motion `Node.cc` never persisted moved the rate **7/10 → 5/12** and carried the lead wall (4/12) |
| L84 | **A feature that widens a persisted record will be probed for loading the OLD format, stated or not. Version per record, not per header.** Evaluators fail 100% runs on it and FP judges split on whether it is in scope. A header flag cannot describe a tree that mixes old and new pages, and a "legacy mode" that keeps writing the old layout silently loses the new field for new data. | libspatialindex-tpr-temporal-knn: a run with 73/73 + 27/27 was failed by its evaluator for an unversioned page; FP judges raised the same probe on 4 more passers across batches 3-4 (upheld 1, over-ruled 3); the reference's header-level `LegacyEntries` mode was itself a Solution Quality FAIL (a reopened old tree dropped new inserts' end times) until the flag moved into the node type word |
| L85 | **A 0% batch is a claim about the ARTIFACT, not the design — mine it before changing anything.** Separate causes you own (a helper calling reference-only API, an ambiguous sentence, a wall a review round added) from difficulty, then re-measure. | siliconcompiler-flist-roundtrip batch 1: 0/11, of which a helper calling `get_filetypes()` masked 5-7 tests per run, one ambiguous spelling sentence took 4 tests at 9-11/11, and a `file://` requirement added in a Solution Quality round killed 11/11. The real trap (F-49, 7/10) was invisible until all three were removed; batch 2 read 2/10 **pyocd-sequence-expression-kernel** batch 1: 0/11, and one rule added in a review round (a control predicate must produce a value) killed 8/11 and was both near-misses' sole failure; batch 2 read 5/10. |
| L86 | **Price every candidate cut by replaying the saved patches against it; do not cut by intuition.** Each option has a measurable rate, and the difference between "fair" and "too easy" is usually one sentence. | siliconcompiler-flist-roundtrip: fixing the unfair items alone projected 0/11, also cutting the `file://` case 3/11, additionally clarifying the edge-ownership sentence **9/11**. The last option looked like the same class of fairness fix as the others and would have destroyed the problem **pyocd-sequence-expression-kernel:** the replay chose the cut (2/11) after an intuitive broader cut fell under the LOC floor, and after batch 1 it withheld three reviewer-requested tests that each replayed at 0/11 (undocumented JTAG bytes, `DAP_WriteABORT`, a string-returning statement). |
| L87 | **Explicitness is a measurable dial on a single axis, not a fairness switch.** Naming both readings of an ambiguous noun can take an axis from band-carrying to free, with no code change. | siliconcompiler-flist-roundtrip: the pre-existing-data-root test killed **6/11** under "a root registered earlier" and **0/10** once the sentence named both kinds of existing root **pyocd-sequence-expression-kernel:** one concrete consequence sentence took a scope test 6/11 -> 0/10 and call-boundary under-reduction 7/11 -> 0/10; the same batch then showed 2/10 OVER-applying the now-concrete rule one layer early (F-52). The dial moves the error, it does not delete the boundary. |
| L88 | **A mutation that kills nothing is a test-gap signal, and closing it can produce the band decider.** L15 still holds for justifying a TRAP on mutation evidence; this is the converse use — a surviving mutation names a behaviour no fixture reaches. | siliconcompiler-flist-roundtrip: the "edges recorded on the reading design" mutation survived the whole suite, which forced a three-level chain fixture; that fixture became the 7/10 lead killer and the sole failure of five near-misses. A two-level sibling graph cannot see it |
| L89 | **A carve-out that names only the exception pulls look-alikes across the boundary.** When a contract splits calls into two classes, name members of BOTH, with every tested call placed by name. Naming only the stepwise class made agents file anything that LOOKS stepwise with it. | pyfakefs-block-inode-accounting: five `create_dir`/`create_file` rollback tests, tests and solution unchanged: 0/11 (universal sentence) → 9-10/12 (one-sided carve-out) → 0/10 (both sides named) |
| L90 | **The reference bugs Solution Quality finds are the batch's near-miss killers — build a test for each one.** An author who has just made a mistake in their own reference has located a place a capable implementer goes wrong. Keep the fix AND add the discriminating test; it is the cheapest calibrated trap you will get. | pyfakefs-block-inode-accounting: all three accepted-batch near-miss causes (unlimited placeholder as a limit, Windows symlink sized by stat, imports inheriting `create_dir` rollback) were reference bugs found at R4, R5 and R17 **Counter-evidence, pyocd-sequence-expression-kernel:** eleven reference bugs found by gates, each given a test; in the accepted batch they killed NOTHING, except that the test built for the round-1 finding (results not reduced) caught the OPPOSITE error (arguments over-narrowed, F-52, 2/10). L90 holds when the reviewer finds a place implementers go wrong; it fails when the finding is a reviewer-invented input (L93) or a contract gap no implementer reaches. **teavm-method-summaries (second counter-case):** two real Solution Quality reference bugs (absent-class VIRTUAL call, unwired `SIMPLE` pipeline), each with a test: 0/10 kills; see L95. |
| L91 | **Refines L80 — Solution Quality only ever ADDS requirements, and their sum can pass solvable with every round individually fair.** Batch after the second gate round, not after the eighth. When a finding says "the contract promises X, so this path must do X too", prefer narrowing the sentence over implementing the Nth path. | pyfakefs-block-inode-accounting: Description 3/3 and Solution & Code 3/3 before any batch, then **0/11** with six tests at 11/11, all added between R4 and R9 **pyocd-sequence-expression-kernel:** eleven review rounds after the core slice; batch 1 0/11 was the round-3 predicate rule (8/11). Of the ~100 test cases added in review, only the round-1 argument test killed anyone in the accepted batch. |
| L92 | **An arbitrary value for an argument the rule under test does not govern is an accidental trap, and read the assertion diff, never the test name, before attributing a kill.** Pass every non-governed argument an in-contract value. A test name says which rule the test was FOR; the diff says which rule the agent broke. | pyocd-sequence-expression-kernel: `tms=3` (the probe API documents 0 or 1, and the CMSIS-DAP layer masks it itself) killed 3/10 in the accepted batch, one near-miss on its own, plus Vega in batch 1: the only run-deciding trap that nobody designed. Batch 1's Vega failure had been read from test names as "JTAG width", and that misreading framed a keep-or-cut decision |
| L93 | **A requirement a reviewer derives from a HYPOTHETICAL input costs rounds, not difficulty. Check whether the repo's own contract ever produces that input.** If it never does, satisfy the reviewer in the solution and keep the contract silent on the one case the tests cannot afford. A boundary sentence stating the repo's real contract may be overridden anyway. | pyocd-sequence-expression-kernel: rounds 8, 10 and 11 argued over a `-> str` sequence function; the repo has none (23 return `int`, 16 return `None`, and the delegate docstring says fixed-zero functions return `None`). The sentence saying so was overridden in round 11. Final design: static STRING rejection plus no-value at run time, contract silent on a bare string statement. Its tests killed 0/10 |
| L94 | **A sentence can state an algorithm's DIRECTION and still not transmit it.** Where the natural construction starts from the wrong end of a fixed point, the sentence stays a trap after it is written down, and evaluators rule it fair. | teavm-method-summaries: "the most precise facts that hold for all methods at once, so recursion and mutual recursion lose nothing by themselves", and still **4/10** initialized never-null to false and promoted (F-53), three of them 25/26; all judged described AND inferable |
| L95 | **Gate-found tests land where agents already converge.** A gate reads the reference, so its finding marks a place the AUTHOR went wrong, not a place implementers do. Budget them as insurance, not difficulty; the one that kills is the test asserting behaviour agents have a reason to change. | teavm-method-summaries: 2 Solution Quality reference bugs + 9 Auto Review / coverage cells, **0/10 kills** across all 11; the single coverage-suggestion kill (2/10) asserted the OLD no-summaries output (F-54). Second problem after pyocd (L90 counter-evidence) |
| L96 | **Never put a frequency or timing property in the contract (once, lazily, cached, only after X) unless a test can observe it.** Reviewers score it as an untested requirement, and the only discriminators are bytecode counting or timing, both unfair. | teavm-method-summaries: "builds the summaries once per build" drew a High "untested" finding and Tests 1/3; counting `MethodSummaries.build` would also fail an agent building through its own overload. Dropped from meta.md; the Tests band came back to 2/3 |

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
| A whole-program analysis computing a MUST fact (never null, never throws) over a call graph with cycles, next to a MAY fact the same pass computes | **F-53** — state "most precise facts for all methods at once"; test a jointly never-null cycle with one anchored exit, plus a cycle a null reaches | 4/10, sole failure of three 25/26 near-misses. Stays hard after it is stated (L94) |
| An opt-in feature whose OFF state is promised unchanged, where the ON state must handle a case the base code silently ignores (arguably wrongly) | **F-54** — one "without X every pass behaves as it does today" sentence and one off-path test across the newly handled case | 2/10, one sole failure. Came from a coverage suggestion |
| A pass keyed by a variable/node index with a second deferred path (join, frontier, replay queue) that stores the key, and a feature that needs "all of them" | **F-55** — test the "all" case on the straight line AND across a join, separately | 2/10, compound. Free if both paths exist |
| A pluggable delegate, driver or backend seam whose INPUT tests can record, with a narrowing that belongs to the concrete operation below it | **F-52** — state the full-domain rule at the seam and the narrowing at the operation in adjacent sentences; test the seam with a recording delegate and the operation with the real implementation over a mock | 2/10, the sole failure of both runs (146/150). One sentence, but only once the seam rule is concrete (L87); abstract, the same tests killed 7/11 by under-reducing |
| Writer flattens a DAG to a flat record list; reader rebuilds one object with no edges | **F-49** — round trip the graph, edges carried inside each record | 7/10, sole failure of five near-misses. Needs a THREE-level fixture; a two-level sibling graph measures nothing |
| An "unlimited" mode AND a stats API that must report a finite number for it | **F-50** — test a request just PAST the reported figure, on each axis (bytes, inodes, reconfiguration) | 2/10 accepted batch, 4 runs earlier. Zero extra words if both halves are already stated |
| A size or length getter with an OS-type / mode branch, and a feature that accounts the real stored quantity | **F-51** — one test on the non-default OS type asserting stat, the mount and the usage report | 3/11 → 5/12 → 1/10 across three batches; the repo's own test reinforces the wrong source |
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
| A batch loader that injects a per-entry attribute (group index, owner, id) that the public single-object constructor leaves at a default, and a subsystem that dispatches by it | **F-41** | 10/11 on ir-sim-scenario-events, the sole failure of six near-misses. Promise runtime-created objects are ordinary members; test one driven ONLY by the keyed dispatch. Zero description words |
| An undo that re-inserts several removed items by recorded position | **F-42** | 2/11 on ir-sim. One fixture deleting two items, earlier first; assert exact order after the undo |
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
| An interval / abstract-interpretation estimator over an IR that shares identical subexpressions, plus a new operator exact on identical operands (comparison, equality, subtraction) | **F-26** | 7/10 top killer on ray-optics, reproduced 5/10 and 5/11 under two other descriptions. Test `x < x` and a shared subexpression; never name the case |
| A refinement / narrowing pass to which you add a DUAL pair of combinators (`and`/`or`, `all`/`any`) | **F-27** | 6/10, rising across three batches as the sentence got clearer. One sentence states both polarities; test the `or` true branch with a one-operand hazard |
| A code generator that picks a representation per node from an analysis (plain vs wrapped, unboxed vs boxed, f32 vs guarded) | **F-10** (valid node over a maybe-invalid operand) | 6/10 and the sole failure of the 94/96 near-miss on ray-optics; zero description words |
| A keyed container of named concepts (`layers`, a registry) that already ships a composite value type, plus a new concept with two parallel components | **F-28** | 7/10 top killer on worldengine and the sole failure of all four 63/66 near-misses. Singular noun + one setter in the meta; test by container key after a round trip. Without an existing composite type it is an unfair representation pin (L49) |
| A plugin/simulation family whose members declare an applicability predicate nothing calls, plus a rule that caller-supplied state is kept | **F-29** | 2/10 (after 1/10) on worldengine. One direct-call test with a distinctive supplied value; no extra description words |

| The repo already reads a metadata or aggregate field back from every input and merges it with a fixed operator, and your feature changes how that field aggregates | **F-33** | 3/10 on tippecanoe, and the reference had the bug too. Two inputs with distinct inherited values; state the aggregate once, never name the reader |
| A "record what the recourse did" rule (counters, a report entry, a `strategies` row) beside a recourse that can be attempted without effect | **F-15** accounting variant | 4/10 on tippecanoe. Test the degenerate attempt: one unsheddable item, with and without inherited records |
| A pass that widens / promotes / boxes values under a documented low-bits invariant, run only on some pipelines (optimizer, some targets), plus a new consumer that reads the value at full width | **F-30** | Lead wall on cwerg: 10/10 → 2/10 over five batches, and still killing after the rule was stated. Run one golden program through every pipeline the repo already has |
| Twin implementations (Python spec + C++ port, interpreter + JIT) under an identical-output contract, with different host integer semantics in their constant folders | **F-31** | 2/10 on cwerg with an identical 5-test failure set. Fixture only the arithmetic the feature reaches (L60); a pre-existing DIV/float divergence is FP noise, not difficulty |
| A CFG-editing feature in a manual-memory twin, plus two output paths with different strictness (text renderer vs binary emitter) | **F-32** | 2-3 per batch on cwerg once "however many times" is stated. One program with dozens of occurrences through the strict path |
| An iterative solver that writes its iterate into the caller's state vector, plus a feature that returns a state from before a solve | **F-34** | 8/13 on sfepy, sole failure of both 116/117 near-misses; state the outcome, never the copy |
| A stepper or cursor that advances its index before the attempt, plus a stop rule that rolls data back | **F-35** | 2/13 on sfepy; one index-relation assert per stop kind |
| A user callback that can set the size or bound the feature must keep safe | **F-10** hostile-hook cell | 7/13 on sfepy from three words of contract ("whatever `adapt_fun` sets") |
| A tokenizer that splits its input on marker characters into a segment list and backtracks by resetting an index, plus a feature that consumes a variable-length run after an existing construct | **F-36** | 11/19 on mwparserfromhell, sole failure of four near-misses. Let the user choose the character set, test a marker inside the run, a failed-route re-parse and the reject branch, and ship a seeded generated corpus |
| A C reader returning `'\0'` for out-of-range reads, and a feature whose accepted characters come from the caller | **F-37** | 7/19 on mwparserfromhell, C arm only. One test with NUL in the set; never test NUL as ordinary text (L60) |
| A computed property the contract says follows a reassigned field, beside an escape rule stated for the parsed form | **F-10** two-path cell | 5/19 on mwparserfromhell, all Vega: test the escape through the setter |
| A layered-input format (config inheritance, overlays, migration chains) with a removal or override marker that may only target what EARLIER inputs contributed | **F-38** | 7/10 on planetiler, sole failure of three 82/83 near-misses. One provenance clause; test one input that adds and then removes the same id |
| A small range, cursor or allocation helper whose loop exits early and rebuilds its result from only the items it touched, used today only by callers whose input keeps that path unreachable, next to a feature that must feed it the other regime | **F-39** | 3/11 on featurevisor, three independent implementations. Zero description words: state the observable rule ("walked in order", "lowest first") and test a case where an earlier range is used up EXACTLY |
| A JS/TS feature that reports figures in a record keyed by user-controlled strings whose repo type is unrestricted `string` | **F-40** | 7/11 on featurevisor, sole failure of six 33/34 near-misses. One `__proto__` test; pair it with a core killer or reviewers call the rate overstated (L74) |
| An expression language where bare lists (implicit AND) may nest under named operators, and a feature that makes the agent evaluate or rewrite expressions itself | **F-43** | 2/10 then 1/10 on featurevisor-target-specialization; caught only by a seeded corpus compared against the repo's evaluator (Pattern 99) |
| A code generator with aliases AND pointer/array wrappers, plus a feature adding a second type rewrite (lowering, flattening, niche erasure) | **F-44** | 6/16 then 7/10 (lead trap) on csbindgen-struct-layout-fidelity; test pointer-to-alias-of-array, alias-of-pointer-to-array, and one extra pointer level |
| An emitter that decorates a scalar kind (attribute, annotation, cast) and a feature adding an aggregate form of that kind | **F-45** | 3/16 then 3/10; verify on the real runtime that the decorated aggregate is actually wrong |
| A feature that chooses output by comparing a source-side model against a target-side model of NESTED values | **F-46** | 5/16 then 2/10, all via free P2P "stays Sequential" guards on containers of a promoted nested type |
| Exported helpers with their own spec files that the feature's natural design would change | **F-12** (exported variant) | 7/20 on featurevisor-target-specialization; put the reference's new logic beside the helpers and keep their specs in base mode |
| A loader that resolves names against two origins (disk and bundled resources) plus a second consumer (validator, watcher, CLI) that re-resolves a relative reference on its own | **F-9** origin variant | 3/10 on planetiler. Test a standalone bundled root whose sibling reference must come from the bundle |
| A persisted index or cache whose value type already carries a field the store writes nowhere, reads back as a sentinel, or has commented out | **F-47** | 4/12 on libspatialindex-tpr-temporal-knn, lead wall; test on a deep tree, after reopen, and via the C API; never pin the store's self-check (L82) |
| An existing public method whose parameter type is broader than the new contract accepts, with a base path that already handles the broad type | **F-48** | 3/12 on libspatialindex-tpr-temporal-knn; one general rejection sentence plus one test passing the base type |

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
- **PROMOTED to L72 (2026-09-18)** on a second independent source: planetiler-custommap-schema-composition
  batch 1, 8/8 compile-wiped on an unstated static `SchemaConfig.files(Path)`.

### C-6 · Recursive removal releases only in the non-recursive branch (seen: pyfakefs-block-inode-accounting · Nova_9)
- Symptom: 112/117. Directory inodes leak on `rmdir`, on removing a tree, and on repeated
  create/remove cycles; files are released correctly.
- Root cause: `remove_entry` handles a recursive `FakeDirectory` in an `if` branch and put the
  release call only in the matching `elif`, so directories never give their inode back.
- Watch for: any accounting hook added to a removal function that branches on "recurse first".
  Promote on a second independent run.

