# DESIGN.md — rust-minidump-stack-containment

Repo: https://github.com/rust-minidump/rust-minidump
BASE_COMMIT: `0155eaf70114f5ed3cbb172968eceaf6106940f7` (2026-07-27)
Tier: Olympus (one tier, 2026-07 sprint). Category: **feature-request**.

> **R2 REDESIGN (2026-07-31).** The first draft centred on a containment guard inside `walk_stack`.
> Audited against `TOO-EASY.md` it was a **uniform-wrap + membership/validation contract**: one guard,
> one site, and the fairness sentence that made the leaf carve-out fair ("equal is allowed for a leaf,
> which the per-architecture walkers already allow") pointed straight at `arm64.rs:478`. That is the
> ironcalc law and it would have batched too-easy. The capability below keeps the region model as the
> *scope* but moves the difficulty onto **trust degradation observed by five silent consumers**, which
> is an S6 two-evaluators / A7 determination-channel seam. Section 11 records the orthogonality and the
> fix-one-breaks-another coupling.

---

## 1. Title

**Add trust accounting and walk termination reporting to the stack unwinder**

(Rounds 1-2 titled this "Degrade frame trust when a stack walk leaves the thread's stack". Retitled
in round 8 so the central capability reads as accounting and reporting rather than validation, which
is what separates it from the Adjacent candidate. See feedback.md round 8.)

---

## 2. Shape classification

- **Shape:** O-Composite-add with O-Algorithm-correctness traits (`SHAPES.md` Pattern 12).
- **Pass rate target:** 10-20% (sprint ceiling 40%; 0% = reject).
- **Best agent:** Orion / Vega (long-horizon). Nova predicted to ship a plausible partial.
- **Dominant verdict predicted:** REGRESSION, then MISSED_REQUIREMENT.
- **Lead arsenal class:** **S6** (two-evaluators / analyzer-missed), supported by **S5** (dual-path +
  closed policy on a wrong-policy in-repo helper), **S3** (baseline preservation), **S2** (composition).

---

## 3. Public API surface

- `StackRegion` — the extent of the thread's stack. `base` inclusive, `end` exclusive.
  - `StackRegion::contains(address) -> bool`
- `WalkTermination` — why the walk stopped: `Exhausted`, `LeftStackRegion`, `StackPointerRegressed`,
  `NoStackMemory`, `FrameLimit`. Plus `WalkTermination::as_str()`.
- `CallStack::termination` — field recording the above.
- `CallStackInfo::WalkTruncated` — new variant when the walk stopped for a containment reason.
- `StackFrame::trust_degraded` — whether this frame's trust was reduced from what the unwinder claimed.
- `StackFrame::claimed_trust` — the trust the unwinder originally reported, retained for output.

**Superseded by rounds 3-7; the shipped surface is larger.** Added since: `DegradeReason` and
`StackFrame::degrade_reason`; `MAX_WALK_FRAMES` and `WalkTermination::{FrameLimit, EndOfStack}`;
`FrameWalker::set_end_of_stack`; `CallStack::{is_truncated, degraded_frame_count,
trusted_prefix_len, degrade_reason_counts}`; and use of the pre-existing but never-constructed
`FrameTrust::CfiScan`. Removed since: `StackPointerRegressed` (the per-architecture walkers already
enforce that), `StackRegion::{len, is_empty}` (dead accessors).

There is still deliberately **no new `SymbolProvider` method**. Round 6 added one and round 7 removed
it again after the file-overlay test against PR #1162; corroboration now probes through the existing
`walk_frame`. meta.md is the authoritative surface list.

---

## 4. Canonical output form

- **Region:** exactly the address range of the stack memory the walk was given; `base <= sp < end`.
- **Degradation rule:** a frame whose stack pointer is outside the region keeps its position in the
  frame list but is recorded with `FrameTrust::Scan`, the weakest recovered trust, and
  `trust_degraded = true`. `claimed_trust` keeps what the unwinder reported.
- **Propagation rule:** the degraded trust is the value later stages of the same walk observe. The
  original claimed trust is never what a subsequent frame sees.
- **Termination:** the walk stops at the first frame whose stack pointer regresses, or that would be
  the second consecutive degraded frame. A frame that terminates the walk is not part of the result.
- **Ordering:** existing frame order preserved (index 0 innermost).
- **Inline frames:** entries in `StackFrame::inlines` are not frames and are never degraded or checked.
- **No stack memory:** terminates `NoStackMemory`, never `LeftStackRegion`; nothing is degraded.
- **Token form:** `as_str()` returns lowercase snake_case.
- **Corroboration policy:** a module for which no symbols are available does **not** corroborate an
  address. Absence of information is not evidence.

---

## 5. Blind-spot pre-empts

- *Iteration termination:* "the walk stops at the first frame that regresses or that would be the
  second consecutive degraded frame."
- *Adjacent-vs-all:* "consecutive means immediately preceding, not anywhere earlier in the walk."
- *Falsy-on-invalid:* "a module with no symbols does not corroborate an address."
- *Pipeline placement:* "degradation is applied to a frame the unwinder has already produced and
  returned, and is what the rest of the walk observes from then on."
- *Result ordering:* "frame order is unchanged."

Codebase-inferable requirements: **1** (that `FrameTrust::Scan` is the weakest recovered level).

---

## 6. Description draft (meta.md) — SUPERSEDED, see the shipped meta.md (451 words)

The draft below is the round-2 text, kept for the design record. The shipped description names the
full public surface (required by reviewer pattern A1) and leads with `Add`.

> # Degrade frame trust when a stack walk leaves the thread's stack
>
> Each architecture's unwinder reports how it recovered a frame, and the walker takes that report at
> face value. Nothing checks the frame still sits on the thread's stack, so a return address picked up
> by scanning can carry a confident label while pointing into unrelated memory, and later frames are
> searched as if that confidence were earned.
>
> Give the walk the stack region implied by the stack memory it was handed, where the low address
> counts as inside and the high address does not. When a frame the unwinder produced and returned has
> a stack pointer outside that region, keep the frame but record it at the weakest recovered trust,
> remember what the unwinder originally claimed, and mark it as degraded. From then on the degraded
> value is what the rest of the walk observes; the original claim is never what a later frame sees.
>
> Stop the walk at the first frame whose stack pointer regresses, or that would be the second
> consecutive degraded frame, where consecutive means immediately preceding. That frame is not part of
> the result. Record why the walk ended and surface it in the processed output. A thread with no usable
> stack memory is not a containment failure, and a module with no symbols does not corroborate an
> address.

197 words. No headers, no formulaic labels, ASCII only, no em dashes.

---

## 7. File footprint

| Action | Path | Raw delta | Meaningful (x0.65) | Reason |
|---|---|---|---|---|
| NEW | `minidump-unwind/src/bounds.rs` | +230 | ~150 | region, containment, degradation policy, consecutive-degrade tracking, termination taxonomy, `as_str` |
| MODIFY | `minidump-unwind/src/lib.rs` | +115 | ~75 | `CallStack::termination`, `CallStackInfo::WalkTruncated`, `StackFrame::{trust_degraded, claimed_trust}`, walk-loop integration, Display |
| MODIFY | `minidump-processor/src/processor.rs` | +40 | ~26 | populate termination, map to `CallStackInfo` |
| MODIFY | `minidump-processor/src/process_state.rs` | +95 | ~62 | JSON + human output of termination and degradation |
| MODIFY | `minidump-processor/json-schema.md` | +12 | 0 | doc only, counts zero |

**~492 raw / ~313 meaningful across 1 new + 4 modified, 2 crates.** Floor is 200 meaningful / 2 files.
To be re-measured with the hook after implementation; the sketch is a lower bound and mature
well-factored code absorbs line items (the taffy / golang-geo lesson).

Crucially the footprint contains **no per-architecture file**. That is both the correct architecture
for a whole-walk invariant and the deliberate way to stay clear of PR #1162's changed-file set.

---

## 8. Solution outline — pure-function helpers

- `StackRegion::from_memory(mem) -> Option<StackRegion>` <- "the stack region implied by the stack memory it was handed"
- `StackRegion::contains(&self, addr) -> bool` <- "low address counts as inside and the high address does not"
- `degrade(frame: &mut StackFrame)` <- "record it at the weakest recovered trust, remember what the unwinder claimed, mark it degraded"
- `advance_regressed(prev_sp, next_sp) -> bool` <- "the first frame whose stack pointer regresses"
- `should_terminate(prev_degraded, this_degraded, regressed) -> Option<WalkTermination>` <- "or that would be the second consecutive degraded frame"
- `WalkTermination::as_str()` <- "surface it in the processed output"

Integration point: `walk_stack`, `minidump-unwind/src/lib.rs:794-812`, between `get_caller_frame`
returning and `stack.frames.push(new_frame)`.

---

## 9. Test file outline

`minidump-unwind/tests/stack_containment_<hex>.rs` and
`minidump-processor/tests/walk_termination_<hex>.rs`. `<hex>` from `openssl rand -hex 3`; no `shipd` /
`datacurve` substring.

No source edits needed from `test.patch`: `minidump_unwind` already publicly exports
`string_symbol_supplier`, `walk_stack`, `CallStack`, `Symbolizer`, `SystemInfo` (proven by the
out-of-crate consumer `minidump-unwind/fuzz/fuzz_targets/unwind.rs:7`), and `test-assembler` is a
dev-dependency.

Buckets: containment boundaries; degradation records both trusts; propagation into the next frame's
search width; consecutive-degrade termination; non-consecutive degrades do not terminate; regression
termination; no-stack-memory; inline frames untouched; per-architecture behavior preserved
(x86 / amd64 / arm64 leaf); cross-crate JSON output.

Assertions are `assert_eq!` on frame instruction lists, `FrameTrust` values and `WalkTermination`
values. No `is_ok()`, no `len() > 0`. Zero comments in test bodies.

---

## 10. Forced bounds

`StackFrame::context.get_stack_pointer()` returns `u64` on every architecture, so the invariant is
expressible once in the shared loop with no per-architecture generics. `walk_stack` is generic over
`P: SymbolProvider + Sync` and async; nothing new is added to that bound. `WalkTermination` must be
`Copy + PartialEq`.

---

## 11. Predicted trap matrix — orthogonal axes, coupled fixes

The five silent consumers of `args.callee_frame.trust`, verified in source. Each asks a *different*
question of the same value, so there is no single chokepoint that answers them all — this is what
makes the axes orthogonal rather than a correlated funnel:

| Site | Question it asks | Correct answer for a degraded frame |
|---|---|---|
| `x86.rs:207`, `amd64.rs:255`, `arm.rs:181`, `arm64.rs:327` | how wide to scan next | narrow (degraded is not trustworthy) |
| `arm64.rs:40`, `arm64_old.rs:40` | is the callee's link register heuristic | yes, treat as frame-pointer grade |
| `arm64.rs:478` | is the callee a context leaf | unchanged, degradation must not fabricate a leaf |
| `arm.rs:319` | is this a leaf that may keep sp | unchanged |
| `mips.rs:98` | should last_sp skip the argument slots | unchanged |

| # | Trap | Class | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|
| A | Degradation is applied but the rest of the walk still observes the claimed trust (e.g. stored in a side field only, or applied after the frame is pushed and read) | **S6** | The frame list looks right; the only observable is how *wide the next frame is searched*, several frames later | "From then on the degraded value is what the rest of the walk observes; the original claim is never what a later frame sees" | `degraded_frame_narrows_next_search`, `claimed_trust_not_observed_downstream` |
| B | Corroboration reuses `instruction_seems_valid_by_symbols`, whose documented behavior is to return **true** when the module has no symbols ("assume valid so that scanning works when we have no symbols", `lib.rs:887-891`) | **S5** | The repo's own tempting helper implements the exact inverse policy, and it is the obvious thing to call | "a module with no symbols does not corroborate an address" | `no_symbols_does_not_corroborate` |
| C | Degradation is applied *before* the architecture returns, or the degraded value is fed to the leaf carve-outs, fabricating or destroying a leaf | **S3** | `arm64.rs:478` reads `trust == Context` and `arm.rs:319` reads `trust == Context && sp == last_sp`; a degraded value flowing there silently changes termination | "degradation is applied to a frame the unwinder has already produced and returned" | existing `arm64_unittest` / `arm_unittest` leaf tests go red in base mode |
| D | "Second consecutive degraded frame" implemented as a running count of degraded frames anywhere in the walk | **S2** | Composition of two documented rules; the natural encoding is a counter, not an adjacency check | "consecutive means immediately preceding" | `two_non_adjacent_degrades_do_not_terminate` |

**The coupling the design is built on (fixing one breaks another):**

Trap A's natural fix is "make the degraded trust the value everything downstream reads." Applied
bluntly, that same change routes the degraded value into the `arm64.rs:478` and `arm.rs:319` leaf
carve-outs, which is exactly trap C, and the existing architecture leaf tests go red. The correct
composition makes the degraded value visible to the *search-width* channel while leaving the
*leaf-determination* channel reading the frame's own origin. Two `==` sites, one enum value, opposite
correct answers. Conversely, an agent who protects the leaf channel first (passing C) typically does so
by keeping the claimed trust as the canonical value, which reinstates trap A.

Trap D is orthogonal to both: it lives in the termination bookkeeping, not the trust channel, and is
caught by a fixture that neither A nor C touches. Trap B is orthogonal again: it is a policy question
about the symbol provider, reachable regardless of how the trust channel is wired.

CONTRACT-STATED / FIX-HIDDEN verified per trap: each contract sentence states an observable
consequence and none names a file, a helper, a call site, or the number of channels. Rule-7 holds —
the meta states one general principle ("the degraded value is what the rest of the walk observes")
and never enumerates the five consumers.

Predicted Wrong Logic ~20% (under the 25% line).

---

## 12. Tier + category

Olympus, sub-rank Good. Category **enhancement** — the walk already exists; this changes what it
records and what later stages observe.

---

## 13. Predicted Nova pass rate

**10-20%.** Trap C surfaces as a *base-suite* regression in architecture files the agent never edited,
and it is entangled with trap A's natural fix, so the two cannot be cleared independently. Traps B and
D are genuinely separate axes. Above 0% because every contract sentence is stated and an agent that
instruments the walk carefully can reach the right composition.

---

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (Phase 1)
- [x] Exclusivity + philosophy run (Phase 2)
- [x] Title verb-led, 8 words
- [x] Shape declared with citation
- [x] Public API surface complete
- [x] Canonical output form spelled out
- [x] 1 codebase-inferable requirement
- [x] Description 197 words, plain prose, ASCII
- [x] File footprint sketched against real source
- [x] ~313 meaningful / 5 files clears the 200 / 2 floor
- [x] 1+ helper per description sentence
- [x] Test outline 4-block, 5-axis coverage
- [x] Forced bounds documented
- [x] 4 named traps, orthogonal axes, coupled fixes, each with pre-empt + catching test
- [x] Lead trap is S-tier (S6), 4 arsenal traps total
- [x] TOO-EASY death-class audit run and the first design **rejected** by it (see R2 note)
- [x] Rule-7 de-enumeration: the five consumers are never listed in the meta
- [x] Predicted Wrong Logic ~20%, predicted pass 10-20%
- [x] Category honest
- [ ] **OWED:** reproduce each trap against a natural-but-wrong implementation
- [ ] **OWED:** measure meaningful LOC with the hook after implementation

---

## Phase 1 — Repo understanding (5/5)

**Architecture.** `minidump-common` holds raw format types; `minidump` parses a dump into typed
streams; `breakpad-symbols` loads `.sym` files and answers symbol and CFI queries behind the
`SymbolProvider` trait; `minidump-unwind` walks each thread's stack via one `walk_stack` loop plus six
architecture modules; `minidump-processor` orchestrates these into a `ProcessState` and serializes it;
`minidump-stackwalk` is the CLI; `minidump-synth` builds synthetic dumps for tests.

**Five subsystems.** format types, dump parsing, symbol/CFI supply, unwinding, orchestration/output.

**Three high-entanglement zones.** (a) `walk_stack`, `minidump-unwind/src/lib.rs:741-819` — every
architecture, trust level and symbolication path funnels through it. (b) the `FrameTrust` lattice —
assigned in six architecture files, read back at five silent comparison sites (table in section 11),
emitted as JSON at `process_state.rs:1113`. (c) `CallStackInfo` — produced at `processor.rs:1062-1089`,
consumed at `process_state.rs:767`, asserted at `minidump-processor/tests/test_processor.rs:69,115`.

**Test framework.** cargo. Architecture unit tests in-crate as `minidump-unwind/src/*_unittest.rs`,
registered at `lib.rs:906-913`. Integration tests in `minidump/tests`, `minidump-processor/tests`,
`minidump-stackwalk/tests`. Fixtures via `test-assembler` `Section`, symbols as in-memory strings. No
network, no external fixtures.

**Formatting template.** `minidump-unwind/src/x86_unittest.rs:10-90`.

**Comment convention.** Source carries doc comments and substantial explanatory inline comments
(`x86.rs:222-246`). Test bodies carry almost none. So: concise doc comments on new public items,
**zero comments in test bodies**.

## Phase 2 — Exclusivity and philosophy (2026-07-31; re-run before patch generation)

Canonical org resolved first: `rust-minidump/rust-minidump`, no redirect.

PR search by feature class, all states: "stack bounds", "end of stack", "cfi_scan", "CfiScan",
"frame trust", "stack scanning", "wandering". Two open PRs touch the unwinder; both diffs read in full:

- **#1162 `add configurable UnwindStrategy to SymbolProvider`** (OPEN, 2026-07-10). Adds
  `UnwindStrategy::{CfiFirst, FramePointerFirst}` plus a `SymbolProvider::unwind_strategy()` method,
  then wraps the existing CFI / frame-pointer calls in a `match` inside each architecture's
  `get_caller_frame`. Pure reordering plumbing: no trust level, no bounds rule, no termination reason,
  no processor wiring. Does not implement this capability. **Two mitigations applied anyway:** the
  footprint contains no architecture file, and the design deliberately adds neither a new `FrameTrust`
  variant nor a new `SymbolProvider` method, because both would echo #1162's shape.
- **#1164 `Gradual off-by-one bitflip confidence detractor`** (OPEN, 2026-07-20). Touches
  `process_state.rs`, `processor.rs`, `test_processor.rs`. Different capability (a per-frame confidence
  score from bitflip heuristics) but edits two of the four modified files. Re-diff before patch-gen.

Maintainer philosophy — **positively blessed**. Issue **#1002** (OPEN, 2024-05-24, cold): `luser`
proposes "change the API so unwinders could return any of: The caller frame / Unable to find a caller
frame / Definitive end of call"; `gabrielesvelto` replies "That's an interesting idea, and I'd be
game". Issue **#918** (OPEN, 2023-12-06) cross-links it. Issue **#739** (OPEN, 2022-11-22, no comments).
No "prefer not to" / "by design" / "not planned" for this class. Per `RULES.md` these issues **inform**
that the class is welcome; the region model, degradation semantics, propagation rule, consecutive-degrade
termination and the corroboration policy are invented here and are materially broader than the
three-outcome enum sketched in the thread.

Publicly-solved check: no comment in #918 / #1002 / #739 / #1122 links an external implementation or
posts a working snippet.

Gate 5 COLD-NOT-LIVE: `minidump-unwind` 7 commits / 12 months, `minidump-processor` 13. Cold.
Gate 9 flakiness: workspace suite run 3x, 266 tests, identical, ~6s, offline.
Gate 10 quota: zero prior submissions on this repo; not in `SATURATED-REPOS.md`.

## Why this is not a duplicate

Closest authored siblings: `problems/cfn-guard-cidr-operator` (new enum variant honored at several
silent consumer sites) and `problems/calyx-unused-port-elimination` (whole-graph invariant during a
traversal). This differs on the axis that matters: the central capability is a **value that must be
visible on one determination channel and invisible on another**, inside a sequential walk where frame
N's recorded trust changes how frame N+1 is recovered. Neither sibling has a channel-selective
propagation constraint, and neither spans an engine crate into a serializer crate.

**Predicted iteration cycles: 2.**
