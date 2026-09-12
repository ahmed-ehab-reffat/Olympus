# REJECTED — platform AI Dedupe, verdict `duplicate` (0.92 confidence)

Not too easy. Fully built, hardened, reviewed, locally green (426 base / 91 new, 3x deterministic,
277 effective LOC, 16 files). Killed by the dedupe engine against FIVE prior candidates, three of
them gluon pattern-matching submissions by other authors.

| Candidate | Verdict | Sim | What it was |
|---|---|---|---|
| 1 | **duplicate** 0.92 | 0.774 | gluon guards + or-patterns, same external semantics |
| 5 | **derivative** 0.87 | 0.698 | gluon guards + or-patterns + range patterns |
| 3 | adjacent 0.82 | 0.726 | gluon guards (parenthesised guard syntax) |
| 4 | adjacent 0.78 | 0.705 | Rune or-patterns + ranges + @-bindings |
| 2 | distinct 0.90 | 0.753 | or-pattern AST node only, different repo |

**The judge's own words:** "Differences are internal representation and staging, not behavior, so
they teach the same debugging lesson."

## Why the differences could not be worked

All five listed "meaningful differences" are exactly what `CLAUDE.md § Derivative / Similarity
Warning Response` names as anti-patterns:

- `Alternative.guard: Option<Expr>` vs `Pattern::Guarded(pat, expr)` -- internal representation.
- `@`-over-or distributed at parse time vs at codegen -- staging.
- A dedicated `OrPatternBindingMismatch` vs a generic `TypeError::Message` -- API surface rename.
- Layout: closing the `If` context on `->` vs never opening one -- internal.
- `translate_guarded` vs threading guards through `Equation` -- internal.

None is a behavioral difference. Reworking any of them is the "rename the API surface" and
"reword meta.md" anti-pattern, and contesting a dedupe verdict on staging grounds burns reviewer
credibility the same way contesting an exclusivity reject does.

## ROOT CAUSE -- the magnet is the FEATURE'S FAME, not the issue tracker

This pick was chosen specifically to DODGE a derivative magnet. The ancestor
(`rejected/gluon-match-guards`) bundled exhaustiveness checking, which is gluon issue #9: open
since 2015, zero comments, no PR, famous feature -- the textbook
"Open-but-unimplemented feature request" death class. I dropped exhaustiveness for exactly that
reason and pivoted to guards + binding or-patterns, which have **no gluon issue at all**.

It made no difference. Three other authors had already submitted gluon pattern-matching work.

**The refinement this entry exists to record:** the death class is stated in terms of an open
issue, and that framing is too narrow. The magnet is not the issue, it is the FEATURE being a
famous one every language eventually grows. Guards, or-patterns, ranges, exhaustiveness and
`@`-bindings are the five things every author looks at when handed a small ML-family language,
whether or not the tracker mentions them. A clean SIX-CHECK proves nothing here, because prior art
lives in the submission pipeline where no GitHub query can see it.

**Operational rule:** before authoring a language feature, ask "would a competent author handed
this repo and told to add a language feature arrive here?" If yes, the lane is contested no matter
what the issue tracker says. Prefer subsystems nobody frames as a language feature: optimizer
passes, dataflow, name resolution internals, tooling output.

## What was salvaged

Two genuine gluon bugs found while building it, both real and both would have shipped:

1. `cargo build --workspace` (what the Dockerfile runs) failed on `repl/src/repl.rs`.
2. `w @ (A n | (B n | D n))` panicked with `ICE: Or-pattern survived pattern expansion`.

Plus the Dockerfile survey (all six approved Rust references) that produced the version-pinned
`cargo2junit`, `--locked`, and `chmod -R a+rwX /opt/cargo /opt/rustup /app` shape, and the finding
that `olympus-base-rust` keeps its toolchain in `/opt/cargo`, not `/root/.cargo`.

Keep for reference only. Do not submit. Do not re-pick anything in gluon's pattern-matching lane.
