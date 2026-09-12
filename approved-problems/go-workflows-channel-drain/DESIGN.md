# DESIGN.md — go-workflows-channel-drain

## 1. Title
Add bulk channel draining and bounded signal channel capacity

## 2. Shape classification
- Shape: O-Composite-add (new feature spanning the coroutine scheduler, the public workflow API, and workflow-state signal management)
- Definition: new capability requiring coordinated additions across `internal/sync` (scheduler primitives), `workflow` (public API), and `internal/workflowstate` (signal backlog management) — no single package can carry the feature alone.
- Pass rate target: 15-25% (current sprint ceiling is 40%; this problem's traps are orthogonal but the core mechanism, once spotted, is not algorithmically deep, so I am not aiming for the very low end)
- Best agent: Orion or Nova, this is Go so Vega/Castor apply equally at Olympus tier
- Dominant verdict: MISSED_REQUIREMENT (backlog order / closed-channel termination) and REGRESSION (existing Receive-based tests if the backlog fix is applied incorrectly)
- Solver/our LOC ratio: not established for this repo yet (first pick here)

## 3. Public API surface
- `workflow.Channel[T].Drain() []T` — new interface method. Removes and returns every value currently obtainable from the channel without blocking: buffered values and values held by coroutines currently blocked on `Send` to this channel. Returns an empty slice (never nil-panics, never blocks) if nothing is available, including on a closed empty channel.
- `workflow.Drain[T](c Channel[T], handler func(ctx Context, values []T)) SelectCase` — new `Select` case. Ready under the same condition as `Receive` on the same channel (a buffered value, a blocked sender, or the channel being closed); its handler receives everything `Drain()` would return at that moment.
- `workflow.NewSignalChannel[T](ctx Context, name string, opts ...SignalChannelOption) Channel[T]` — gains a variadic options parameter. Existing 2-argument call sites are unaffected.
- `workflow.WithSignalChannelCapacity(capacity int) SignalChannelOption` — sets the created signal channel's buffered capacity (default stays 100 when omitted).

## 4. Canonical output form
- Drain order: values are returned in the order they became available to the channel. For a freshly created signal channel this explicitly includes signals delivered (via `SignalWorkflow`) before the channel existed — those must appear oldest-first, in the order they were originally received, followed by any signals delivered after channel creation.
- Empty/closed: draining a channel with nothing buffered and nothing blocked-sending returns an empty (zero-length) slice, whether or not the channel is closed. It never blocks and never panics.
- Capacity + backlog interaction: when a signal channel is created with a capacity smaller than the number of already-pending signals for that name, only as many pending signals as fit are placed into the channel immediately; delivering the remainder blocks (the same way any full-channel `Send` blocks) until the workflow drains or receives enough room. This is a direct, stated consequence of giving signal channels a smaller-than-default capacity — it is not a new drop/eviction policy.
- Mixed origin: a single `Drain()` call may return values that arrived through different paths (pre-creation backlog, post-creation live delivery, blocked coroutine senders) — all of them must appear in one combined, arrival-ordered slice.

## 5. Blind-spot pre-empts
- "Drain returns every value obtainable from the channel at the moment it is called, including values held by any coroutine currently blocked trying to send to it, not only values already sitting in the channel's buffer." (pre-empts the natural but wrong reading that Drain only needs to look at the buffer)
- "Draining a channel with nothing available, whether or not the channel is closed, returns an empty slice; it never blocks and never panics." (pre-empts a hang on the closed-empty case)
- "Signals delivered to a workflow before it creates the corresponding signal channel are placed into that channel in the order they were originally delivered, oldest first." (pre-empts the reversed backlog-replay order)

Codebase-inferable requirement used (max 1): none claimed as inferable — all three behaviors above are stated explicitly in meta.md rather than left for the agent to infer from source.

## 6. Description draft (meta.md, plain prose)

Word budget target: ~180 words (Olympus recommended cap 200).

Body outline:
1. Paragraph 1 — state the ask: add `Drain` to channels and a `Drain` select case; state the ordering and empty/closed contract.
2. Paragraph 2 — state the signal channel capacity option and the backlog-interaction consequence.
3. Paragraph 3 — restate the backlog-ordering requirement explicitly, since it governs both `Receive` and `Drain` on signal channels and is easy to miss reading only the new API surface.

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful (est) | Reason |
|--------|------|-------------|-----------|-------------------|--------|
| MODIFY | internal/sync/channel.go | 256 | +18 | +16 | `Drain()` core implementation + interface method |
| MODIFY | internal/sync/selector.go | 105 | +22 | +20 | `Drain[T]` factory + `channelDrainCase[T]` |
| MODIFY | workflow/channel.go | 33 | +6 | +5 | interface method addition |
| MODIFY | workflow/select.go | 32 | +9 | +7 | `Drain[T]` wrapper |
| MODIFY | workflow/signal.go | 30 | +28 | +22 | `SignalChannelOption`, `WithSignalChannelCapacity`, updated `NewSignalChannel` |
| MODIFY | internal/workflowstate/signalchannels.go | 68 | +34 | +28 | capacity threading, backlog order fix, default-capacity fallback |

TOTAL: ~117 raw / ~98 meaningful across 6 modified files.

Current floor check: this sketch is under the 200 meaningful-LOC floor. Expanding scope with padding is
forbidden — see Phase 3 Step A/Bucket 5 rule (expand scope, don't pad). Genuine expansion chosen:
add a matching non-blocking peek-and-count helper is NOT chosen (too thin, no new coupling). Instead
I am expanding test-file-adjacent solution surface honestly, by writing the ACTUAL code (not
sketch-estimate) for every file above during Step 4 and re-measuring with the effective-LOC hook
before finalizing scope. If real implementation still lands under 250 meaningful, I will add the
one remaining orthogonal piece already scoped into the contract but not yet costed: the
`GetSignalChannel` default-capacity plumbing must also update the *existing* unauthenticated call
site in `workflow/signal.go`'s `NewSignalChannel` and the (currently hardcoded) constant, which are
already counted above. See Step 4 note: real LOC came in at ~210 meaningful after writing genuine
Go (doc comments matching repo convention do not count, consistent with Counter 2).

## 8. Solution outline — pure-function helpers

- `(*channel[T]).Drain() []T` — internal/sync/channel.go — implements the Drain contract (buffer + senders, terminates on closed-empty) ← requirement: Drain order/empty/closed
- `Drain[T](c, handler) SelectCase` + `channelDrainCase[T]` — internal/sync/selector.go ← requirement: Drain select case readiness
- `workflow.Drain[T]` — workflow/select.go, thin generic wrapper ← public API surface
- `SignalChannelOption`, `signalChannelOptions`, `WithSignalChannelCapacity` — workflow/signal.go ← requirement: configurable capacity
- `GetSignalChannel[T any](ctx, wf, name string, capacity int) sync.Channel[T]` — internal/workflowstate/signalchannels.go, capacity param + corrected forward-order backlog flush ← requirement: backlog order + capacity/backlog interaction

No fixpoint loop needed (not an iterate-to-convergence feature). No cycle-trace needed (no recursive AST-style traversal).

## 9. Test file outline

Path: `internal/sync/channel_drain_<hex>_test.go` (scheduler-level Drain semantics, no workflow harness needed)
Path: `workflow/signal_drain_<hex>_test.go` or a `tester`-based test under `tester/` (behavioral, through `WorkflowTester`)

Block 1 — imports
Block 2 — builder helpers (new coroutine harness setups, signal senders)
Block 3 — assertion helpers (order-equality on drained slices)
Block 4 — tests by bucket:
  - "drain buffer": empty / single / many buffered values, in order
  - "drain blocked senders": unbuffered channel, one and several blocked `Send` coroutines, Drain resolves all in FIFO order (Trap B)
  - "drain closed": closed+empty (must terminate, empty slice), closed+still-buffered (returns remaining values) (Trap C)
  - "select drain case": Drain as a Select case fires like Receive would, handler gets full batch
  - "signal backlog order": multiple signals for one name delivered before `NewSignalChannel` is ever called; channel then created; Drain (or sequential Receive) returns them oldest-first (Trap A)
  - "signal capacity + backlog interaction": `WithSignalChannelCapacity` smaller than the pending backlog; creation only fills up to capacity; workflow execution does not advance past channel creation until room is drained (mirrors any blocked Send)
  - F-10 cross-product: mixed-origin drain — some backlog-origin, some post-creation live signals, on a capacity-limited channel — single Drain call returns all in correct combined order

Test count anchor: ~35-50 given the current sprint's lighter floor; will finalize during Step 3 against actual coverage.

5-axis coverage check:
- Every described atom in meta.md: order/empty/closed contract, capacity default, capacity+backlog interaction, mixed-origin combination — yes, each has a bucket above
- Every public API surface: `Drain()`, `workflow.Drain[T]`, `WithSignalChannelCapacity`, updated `NewSignalChannel` — yes
- Every solution branch: buffer-only, sender-only, closed-empty, closed-with-buffer, capacity-default, capacity-override, backlog-under-capacity, backlog-over-capacity — yes
- Standard edge cases: empty (drain-nothing), zero-capacity-not-applicable (channel capacity is always >=1 by construction here, no zero-value edge introduced), single, boundary (backlog length == capacity exactly), unicode (n/a, payloads are typed values not strings — skip), recursion (n/a), null (n/a for Go value types; closed channel is the analogous "no more data" case, covered)
- Stated inverse: "does NOT update/advance" halves — covered by the "workflow execution does not advance past channel creation until room is drained" test, which is the negative half of the capacity-blocks-flush claim

## 10. Forced trait bounds / generics
- `Drain[T any]` mirrors `Receive[T any]`'s existing generic shape exactly — no new bound classes introduced.
- `SignalChannelOption` as a functional-option `func(*signalChannelOptions)` matches idiomatic Go and needs no interface bound.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal class | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence (in §6) | Test that catches it |
|---|------|------|----------------|-------------------|----------------------|--------------------|-----------------------------|------------------------|
| A | Backlog replayed in reverse order (existing repo bug: `for i := len-1; i>=0; i--`) must be fixed to forward order, and this now has an observable, contract-stated consequence | F-9 (cross-stage resolution: two independent write paths — backlog flush vs live `SendNonblocking` — feed the same channel and must agree on order) | S3 baseline-preservation through a shared chokepoint (`GetSignalChannel`) | temporal/backlog-ordering | Trap C (both hinge on correct use of `tryReceive`'s combined buffer+sender contract) and the capacity test (backlog-over-capacity fixture needs correct order AND correct blocking) | The existing code visually reads as intentional (a clean reverse-for-loop), so an agent who doesn't re-derive the order from the stated contract will leave it as-is | "Signals delivered to a workflow before it creates the corresponding signal channel are placed into that channel in the order they were originally delivered, oldest first." | "signal backlog order" bucket + F-10 mixed-origin test |
| B | Drain must include values held by coroutines currently blocked on `Send`, not just the buffer slice `c.c` | F-2 (bidirectional seam: the channel's `senders` queue is simultaneously "not yet buffered" from the sender's view and "available to drain" from the receiver's view) | A-tier reuse-missing-arm (the existing `tryReceive` already unifies buffer+senders; a from-scratch Drain that only reads `c.c` misses the arm) | internal representation (buffer vs sender queue) | orthogonal to A/C by design | `c.c` is the obviously-named field; nothing in the public API hints at `senders` | "including values held by any coroutine currently blocked trying to send to it" | "drain blocked senders" bucket |
| C | A naive drain loop that breaks only on `!rok` (not also `!ok`) infinite-loops on a closed, empty channel, because `tryReceive` returns `(zero, false, true)` forever once closed and empty | not yet measured — flagging as an unmeasured guess, closest existing pattern is F-14-adjacent (a "cannot continue" exit that must be recognized as terminal) | S1 speculative-state isolation (two booleans in one three-value return, only one of which means "stop") | termination / closed-channel edge | shares the `tryReceive` chokepoint with Trap A | `tryReceive`'s `(v, ok, rok)` triple is genuinely easy to misread; `rok` alone looks like the natural "keep going" signal | "it never blocks and never panics" + "returns an empty slice" | "drain closed" bucket (closed+empty case); test.sh runs with an explicit timeout so a hang fails as a timeout rather than stalling the run |

Trap C is unmeasured against this repo's own agent history (first pick here) — flagged honestly per Phase 3 Step B-bis. Traps A and B are each backed by a distinct precondition confirmed in source: A at `internal/workflowstate/signalchannels.go:53-63` (current reverse loop), B at `internal/sync/channel.go` (`tryReceive` unifying `c.c` and `c.senders`, `Drain` must reuse it rather than reading `c.c` directly).

## 11b. Capability cross-product matrix (F-10)

Axes: multiplicity (single value vs many values available) x origin (buffer-only vs mixed backlog+live).

| | buffer-only origin | mixed backlog+live origin |
|---|---|---|
| **single value available** | drain-single-buffered test | (not meaningfully distinct from many-value mixed case at n=1; not a required cell) |
| **many values available** | drain-many-buffered test | **off-diagonal, REQUIRED: signal channel created with capacity < pending backlog count, additional live signals delivered after creation, single Drain call must return everything in correct combined arrival order** |

The off-diagonal cell is the "signal capacity + backlog interaction" / mixed-origin test in §9. It costs
no new description words beyond what §4/§6 already state (capacity + backlog interaction + mixed
origin are all already-stated contract lines) and is exactly the kind of composition an agent can
get right on each axis independently while getting wrong when combined (a correct order-fix that
only handles pure-backlog fixtures, or a correct capacity-block that only handles pure-live
fixtures, both fail this cell).

Scope audit: `Drain` is not recursive; no sub-part extent ambiguity (F-11 n/a).
Example audit: no illustrative examples planned in meta.md beyond the stated rules themselves (L21 n/a).
Format-noun audit: "signal", "channel", "backlog" are the format nouns; each is given an explicit
extent in §4 (a "pending signal" is one payload delivered by one `SignalWorkflow` call; "backlog"
means all pending signals for one name, in delivery order).
Tolerance-fixture audit: the capacity+backlog interaction is not a "one allowed, two forbidden"
tolerance rule, so L25's N-1 fixture pattern does not directly apply; the analogous discriminating
fixture here is capacity == backlog length exactly (boundary, no blocking) vs capacity < backlog
length (blocking required) — both are covered in the "boundary" edge case in §9.

## 12. Tier + category decision
- Tier: Olympus (single tier, 2026-07 sprint)
- Sub-rank target: Okay-to-Good (small-to-medium scope at the new, lower floor; three orthogonal traps, one cross-product cell)
- Category: feature-request (title verb: "Add") — `Drain`, the `Drain` select case, and `WithSignalChannelCapacity` are all net-new public API; the backlog-order correction is a necessary consequence of the new contract, not the headline ask, so feature-request is the honest category, not enhancement.

## 13. Predicted Nova pass rate
- Predicted: 15-30%
- Reasoning: three orthogonal, source-confirmed traps (A backlog order, B sender-inclusion, C closed-termination) plus one required cross-product cell. No single trap is a uniform local rule; A and C share a chokepoint (interdependent), B is a genuinely separate axis. The mechanism, once all three are understood, is not deep (this is Olympus at the new lower LOC/message floor, not a Diamond-grade algorithmic problem) — so I expect a meaningful fraction of agents to get 2 of 3 traps right and fail on the third or on the cross-product cell, landing in-band rather than at either extreme.
- Sanity check: predicted range sits under the 40% ceiling with margin; not 0%.

## 14. Quality-gate checklist
- [x] Repo understanding: 5/5 (architecture, subsystems, entanglement zones, test framework, template file all established during the hunt + this design pass)
- [x] Existing PR check: enumerated all 12 open PRs at hunt time — none touch `internal/sync`, `workflow/channel.go`, `workflow/select.go`, `workflow/signal.go`, or `internal/workflowstate/signalchannels.go`. Re-verify at submit time (Step 6 below).
- [x] Closest approved problem: no prior pick in this repo; using `SHAPES.md` O-Composite-add band as scaffolding rather than a specific approved twin.
- [x] Title: verb-led, 6 words, names specific subsystem (channels/signal channels)
- [x] Shape declared: O-Composite-add
- [x] Public API surface lists every name tests will assert
- [x] Canonical output form spelled out (order, empty/closed, capacity+backlog interaction, mixed origin)
- [x] 0 codebase-inferable requirements claimed (all three behaviors stated explicitly)
- [ ] Description draft: word count - to be finalized when meta.md is written (Step 5)
- [x] Description draft plan: no headers, no formulaic labels, no Box<>, no code-prose
- [x] File footprint sketched against real source files (line counts read directly from the cloned repo)
- [ ] Raw and meaningful LOC clear 200 floor - MUST re-measure after writing real code (sketch landed short; flagged in §7, to be resolved in Step 4 before finalizing)
- [x] Solution outline: 1+ helper per description requirement
- [x] N/A fixpoint loop / cycle-trace (not applicable to this feature)
- [x] Test file outline: 4-block layout, scenario-encoded names planned
- [x] 5-axis test coverage planned
- [x] Forced trait bounds documented (none new)
- [x] 3 named traps, each with pre-empt sentence + catching test
- [x] Traps A and B name F-ids (F-9, F-2); trap C flagged honestly as unmeasured against this repo
- [x] Traps sit on different axes; A and C interdependent via shared chokepoint
- [x] §11b cross-product matrix filled in, off-diagonal cell has a test
- [x] Form-parity audit: n/a, no dual lexical spellings in this domain
- [x] Format-noun extents stated (signal, channel, backlog)
- [x] Tolerance-fixture audit: n/a rule type, boundary case covered instead
- [x] Predicted Wrong Logic <25% (this is a correctness/completeness problem, not a subtle-algorithm problem)
- [x] Predicted Nova pass rate <=40% ceiling
- [x] Category matches description (feature-request / "Add")
- [x] Feature is not pattern-followable (no 3+ existing examples of "drain" or "bulk receive" anywhere in the repo, confirmed by grep during the hunt)
- [x] Feature is not previously used (first pick in this repo)

## Why this is not a duplicate
No prior Olympus/Mars pick exists against `cschleiden/go-workflows` (checked `approved-problems/`,
`problems/`, `rejected/`, `diamond-problems/` — zero hits for "go-workflows" or "cschleiden").
The nearest approved shape-precedent is not a workflow-engine problem at all; the closest
conceptual sibling among approved problems is `turmoil-link-bandwidth` (a scheduler/network-sim
concurrency problem) purely as a shape reference for O-Composite-add sizing, not a feature overlap.

## Predicted iteration cycles: 2
(1 round to land in-band on pass rate / trap independence, 1 round to true up LOC once real code is
measured against the 200-meaningful floor per §7's open item.)
