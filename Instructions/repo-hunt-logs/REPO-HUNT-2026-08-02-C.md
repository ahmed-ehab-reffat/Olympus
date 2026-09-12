# Repo hunt 2026-08-02 (C) — after the orb derivative verdict

Prior context: `REPO-HUNT-2026-08-02-SCIENTIFIC.md` (rust-bio feature-dead, orb chosen), then orb
came back **`derivative`** with five prior candidates. This sweep applies two gates that did not
exist before, each paid for by one of those failures.

## The two new gates

**Gate A — FEATURE-FIRST.** Never rank a repo on gate-cleanliness. Name 2-3 candidate FEATURES
and kill-test them before the repo gets a score. *Paid for by rust-bio: every repo gate passed,
then five consecutive features died (architecture-jump, not-a-gap, too-small, externally-named,
sibling-is-the-answer-key).*

**Gate B — NO SCOPE LEVERS.** The core capability must clear 200 effective LOC on its own. A
second feature bolted on to reach the floor does not differentiate; it doubles the collision
surface. *Paid for by orb: the antimeridian lever I added purely for LOC turned out to be
independently owned prior art, and collided at 0.63 while the core collided at 0.70.*

**Domain correction.** "Scientific like lyon" steered me into computational geometry, which is
the most author-contested scientific subdomain in the set: lyon (ours), georust/geo, golang/geo,
kurbo, truck and orb ALL produced prior art or a structural blocker. Steer instead to scientific
domains where the repo defines its OWN model rather than implementing an external standard —
that is the only reliable anti-derivative property, because a capability that cannot be named
without repo-internal nouns cannot be independently converged on.

---

## RANK 1 — calyxir/calyx — ★607 — the strongest anti-derivative profile available

- **URL:** https://github.com/calyxir/calyx | **License:** MIT | **Language:** Rust, pure
- **Last push:** 2026-07-31 | **Open issues (no PR):** 90 — inside the 100-1000 band's spirit
- **Our quota:** **1 of 6** (`approved-problems/calyx-unused-port-elimination`, ACCEPTED)
- **Open PRs: 10, of which 7 are dependabot.** The only substantive ones are #2692 (yxi:
  `backend/verilog.rs`, `frontend/workspace.rs`, `ir/component.rs`, `ir/context.rs`), #2685
  (source-location tracking) and #2674 (`comb_prop.rs`). **The entire `calyx/opt/src/passes/`
  surface outside `comb_prop` is cold.** Best exclusivity picture in three sweeps.
- **Architecture:** 6 crates — `frontend` / `ir` / `opt` (40+ passes) / `backend` / `stdlib` /
  `utils`

**Why the derivative profile is strong.** Every calyx capability is named in calyx's own
vocabulary: `@go`/`@done` handshakes, groups, `comb` groups, `ref` cells, `invoke`, and
`static<n>` latency islands. Write the one-line summary the dedup engine would emit and it
cannot be phrased without those nouns — which is the Stage 2b LOW-risk test. Contrast orb, where
"enforce polygon ring winding" was intelligible to anyone and three authors reached it
independently.

**Proven track record on this exact repo.** calyx held **10-40% across 13 batches** without
drifting to either extreme, because the feature was globally coupled (a fixed point over the
whole program). `failure-patterns.md` L2 says that is the property that holds a band.

### Feature shortlist (Gate A — surface identified, kill-test NOT yet run)

The **static timing family** is the target: 8 passes, **4142 LOC**, and our approved submission
never touched it.

| # | Candidate surface | LOC | Why it fits | Honest risk |
|---|---|---|---|---|
| 1 | `static_inference` (106) + `static_promotion` (700) — latency inference and promotion of dynamic control to `static<n>` | 806 | Globally coupled by construction: a seq's latency is the sum, a par's the max, and promoting one group enables promoting its parent, to a FIXED POINT. Wrong latency silently produces incorrect hardware — misdirecting by nature. Pure calyx vocabulary | must confirm a real f2p gap, not "improve it" |
| 2 | `schedule_compaction` (386) — reorders statically-scheduled ops by data dependency | 386 | Own model; carries an explicit `total_order` assumption at line 82 | likely too small alone; would violate Gate B if it needed a lever |
| 3 | `compile_static` (1429) + `static_fsm_allocation` (302) — lowering static islands to FSMs | 1731 | Large core, cross-stage (opt -> backend) = F-9 shape | biggest, least explored |

**Explicitly excluded to avoid self-collision:** `cell_share`, `infer_share`, `dead_*`, and
anything touching `invoke` bindings or port liveness — that is our own approved
dead-port-elimination and would flag against ourselves.

**Still owed before authoring (Gate A):** pick ONE of the three, find a concrete behavioural f2p
gap, reproduce it on base, and measure minimal-golden LOC. No scope lever permitted (Gate B) —
if the core cannot reach 200 effective by itself, drop the candidate rather than bolt something on.

---

## Also still live (not yet feature-checked)

| Repo | ★ | Note |
|---|---|---|
| Axect/Peroxide | 723 | Very active maintainer = Gate 5 risk; own numeric model |
| smartcorelib/smartcore | 940 | ML algorithms all textbook-named — fails Gate A on inspection |
| elodin-sys/elodin | 538 | Aerospace sim + its own DSL; 261 commits/12mo is a firehose |
| oxfordcontrol/Clarabel.rs | 582 | 2 src commits/12mo, 15 open PRs against 22 issues |

## Dead this sweep

- **paulmach/orb** — `derivative`, 5 prior candidates, geometry core contested. Recorded in
  `SATURATED-REPOS.md § B1`.
- **Computational geometry as a domain** — six repos, six blockers. Treat as author-saturated.

---

## Gate A kill-test results (run 2026-08-03) — candidate 1 DEAD, repo still RANK 1

**The repo passed everything.** Gate 5 recency on the static family, measured per file:
`schedule_compaction.rs` 2025-02-03 (18 mo), `static_fsm_allocation.rs` 2025-04-24 (15 mo),
`compute_static.rs` 2025-08-01 (12 mo), `static_promotion.rs` + `compile_static.rs` 2025-12-10
(8 mo). Issue #2297 "First Class FSMs" last moved 2025-01-09 — 19 months stale, NOT a live
workstream. PR queue is 7/10 dependabot. Self-collision checked against our approved
`calyx-unused-port-elimination`: it touched `frontend/attribute.rs`, `ir/structure.rs`,
`analysis/port_liveness.rs`, `passes/dead_port_elimination.rs` — **zero overlap** with the
static family beyond the registration plumbing (`passes/mod.rs`, `default_passes.rs`).

**Candidate 1 — static promotion of `if`-`with` / `while`-`with`: KILLED.**

The gap is real and I verified it in the source: `compute_static.rs:116-145` bails to `None`
whenever `self.cond.is_some()` for both `If` and `While`, even though a `with` clause is by
definition a COMBINATIONAL group and therefore zero-latency, so `max(t,f)` and `bound * body`
would both still hold. `ir::StaticIf` (control.rs:120) has `port`/`latency`/`tbranch`/`fbranch`
and **no field for a condition group**, and `IntoStatic::make_static` for `If` silently drops
`self.cond`. That is an IR-level limitation, large and cross-crate — it would have cleared
Gate B on its own with no scope lever.

It dies anyway, on two independent flags:

1. **Maintainer philosophy — issue #1699 `[Semantics] with groups and if/while`** (open, 6
   comments, sampsyo + rachitnigam + calebmkim). The semantics are openly UNSETTLED ("our
   compiler doesn't compile things this way, it just semantically reserves the right to do
   so"), and the stated eventual goals include **"Get rid of `with` on `if/while` ports."**
   Building static promotion on a construct the maintainers are discussing REMOVING is the
   dasel-slice-operator class: the spec contradicts the maintainers' direction.
2. **Derivative magnet — issue #2595 `Cycle inefficiency of if with comb group`** (open, zero
   comments, 2025-12-03) names the exact inefficiency the feature would fix. Open +
   uncommented + recent is the Stage 2b magnet signature that already killed lol-html and orb.

**Lesson reinforced:** Gate A works. One issue-read killed a pick whose CODE-level analysis was
completely sound (real gap, right size, cross-crate, no self-collision). Source analysis cannot
see repo politics — only the SIX-CHECK can.

**Remaining calyx candidates, both still unflagged:**
- `compile_static` (1429) + `static_fsm_allocation` (302) — lowering static islands to FSMs,
  15-18 months cold, spans opt -> backend (F-9 shape). Largest untouched core. **Next to test.**
- `schedule_compaction` (386) — 18 months cold, explicit `total_order` assumption at line 82.
  Likely fails Gate B alone (needs to reach 200 effective without a lever).

**Do NOT re-pick:** anything routed through `with`-clause semantics on `if`/`while`.

## Candidate 3 kill-test (2026-08-03) — DEAD on Gate 6, reproduction failed

**Candidate 3 — `Or`/`And` interval handling in `compile_static::get_interval_from_guard`: KILLED.**

Source analysis looked excellent: `Or` hits `unreachable!()` (line 514) and the `And` arm carries
`assert!(end1-beg1 == lat || end2-beg2 == lat)` which two proper sub-intervals violate. Both
forms appear in the repo's OWN test corpus (`tests/passes/simplify-static-guards/basic.futil`:
`(%[2:3] | lt.out) & %[1:5]` and `%[2:5] & (%[5:7] | lt.out) & %[3:7] & %[4:10]`), so the
syntax is unquestionably legal.

**Gate 6 REPRODUCE-ON-BASE: FAILED TO REPRODUCE.** Built calyx (31s) and ran `compile-static`
over crafted inputs — `static<6>` group with `a.write_en = %[0:2] | %[4:6] ? 1'd1;` and
`static<8>` with `%[2:5] & %[3:7]`. **Both compiled cleanly. No panic.**

**Why, and this is the reusable part:** `get_interval_from_guard` is called at ONLY two sites
(lines 606, 699), both guarded by `PortParent::StaticGroup(sgroup)` — i.e. only for assignments
whose destination is a static CHILD GROUP's port (`static_child[go] = %[i:j] ? 1'd1;`), the tree
structure built for NESTED static control. `num_repeats` is then derived from `end - beg`, which
assumes each child executes in exactly ONE contiguous window. An `Or` would mean invoking one
child instance in two disjoint windows, which calyx's tree model cannot express at all. The
`unreachable!()` is **defensive, not a gap** — that is why it is written `unreachable!` rather
than returning an error.

**Lesson (add to the gate list): `unreachable!` / `assert!` / `panic!` are NOT evidence of a
gap.** They are frequently invariants the surrounding construction genuinely guarantees. Grepping
for them is a cheap way to GENERATE candidates and a worthless way to VALIDATE them. Only Gate 6
reproduction through the real entrypoint decides, and it cost 31 seconds of build plus two
crafted inputs to overturn a confident source-level analysis.

**calyx status:** repo still RANK 1 on every gate (cold static family, near-empty PR queue,
own-vocabulary, 1/6 quota, no self-collision). Candidates 1 and 3 dead. Candidate 2
(`schedule_compaction`, 386 LOC, 18 months cold) is the only one left and was already assessed
as likely failing Gate B (cannot reach 200 effective without a lever, which Gate B forbids).
A fresh candidate would need a new pass through the 40-pass surface.
