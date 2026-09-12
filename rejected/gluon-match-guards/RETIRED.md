# RETIRED — superseded by problems/gluon-match-alternatives

Not shelved for being too easy. Never batched. Retired at authoring time because the successor
covers the same ground better.

**What was here:** guards + non-binding or-patterns + exhaustiveness checking, 228 effective LOC,
58 tests, base mode scoped to 2 test targets (21 tests).

**Why it was replaced:**

1. **Exhaustiveness checking is a derivative magnet.** gluon issue #9 has been open since 2015
   with zero comments and no PR, for a famous language feature. That is `TOO-EASY.md`'s
   "Open-but-unimplemented feature request" death class verbatim: the SIX-CHECK reads clean
   precisely because nobody upstream engaged, so the prior art lives in the submission pipeline
   where GitHub queries cannot see it.
2. **It manufactured a cheat trap (L31).** Rejecting non-exhaustive matches invalidates
   previously-valid gluon programs. gluon-format-comments lost 3 runs across 2 batches to
   PASS_CHEATED for editing repo tests under exactly that pressure.
3. **Two latent bugs.** `cargo build --workspace` (what the Dockerfile runs) failed on
   `repl/src/repl.rs`, and the or-pattern expansion in `vm/src/core/mod.rs` was not recursive, so
   an or-pattern nested inside another one hit an ICE.
4. **The or-pattern design had an escape hatch.** Making a binding branch a type error avoided the
   hard part. The successor allows bindings, which is where its lead trap lives.

Keep these artifacts for reference only. Do not submit.
