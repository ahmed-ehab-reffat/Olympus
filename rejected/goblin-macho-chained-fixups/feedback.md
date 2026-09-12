# feedback.md — goblin-macho-chained-fixups

## Summary

Olympus (one-tier, 2026-07 sprint floor). `m4b/goblin` (Rust, MIT, pure, no CGO/-sys deps),
scope-locked from `REPO-HUNT-2026-08-15.md` RANK 1. Feature: implement `LC_DYLD_CHAINED_FIXUPS`
parsing so `MachO::imports()` resolves imports on modern Mach-O binaries that use chained fixups
instead of the legacy `LC_DYLD_INFO`/`LC_DYLD_INFO_ONLY` bind-opcode stream. Confirmed dead
before this pick: the load command has been recognized as a generic offset+size stub since PR
#240 (merged 2020) and nothing has ever parsed the payload; two independent open GitHub issues
(#323 opened 2022, #542 with a full PoC) report symptoms of the same root gap but neither is the
feature itself (both read as narrow bounds-check bug reports on the exact wrong-fix path, treated
as Stage-2b derivative-magnet risk and deliberately not mirrored — see DESIGN.md's magnet warning
in § "TRAP SEAMS" evidence section).

## Environment constraints this session

No local Docker, no platform eval access (no Nova/Orion/Vega/Castor batch could be run). Every
claim about F2P behavior, patch application, and determinism below was verified locally via
`cargo build`/`cargo test` against a clean checkout of `BASE_COMMIT`, not inferred. Docker build
validity is reasoned about statically against `DOCKER.md` Pattern A and is owed to the platform
run. Pass-rate prediction (DESIGN.md § 13, 15-30%) is a design-time estimate only; no empirical
batch data exists for this submission.

## Design

`DESIGN.md` in this folder, 14 sections, written before any code per the hard gate. Shape:
O-Composite-add (historical label; current floor governs). Three named traps, each mapped to an
F-id from `failure-patterns.md`: F-9 (merge-not-replace at the `imports()` chokepoint), F-13
(rebase-vs-bind discard-unit granularity within a chain), F-10 (pointer-format x import-format
cross-product). Traps 2 and 3 sit on different axes; trap 1 is interdependent with both through
the shared accumulator.

## Build process

1. Hunted and scope-locked the repo/capability (`REPO-HUNT-2026-08-15.md`).
2. Fetched the authoritative struct layout from `apple-oss-distributions/dyld`'s public
   `include/mach-o/fixup-chains.h` via `gh api` rather than relying on memory, since the bit-field
   packing (43/34/24/19/16/12/11/8-bit fields depending on pointer format) is exactly the kind of
   detail that is cheap to get subtly wrong from recollection alone.
3. **Confirmed Gate 1 by measurement, not inference:** hand-built a synthetic Mach-O binary
   (`mach_header_64` + 3 segments + 1 dylib + 1 `LC_DYLD_CHAINED_FIXUPS` command, no legacy
   `LC_DYLD_INFO`) via a Python byte-packer, ran it through base `goblin::mach::Mach::parse` +
   `.imports()` via a throwaway `cargo run --example`, and observed `imports() returned 0 entries:
   []` even though `libs` correctly showed the target dylib. This is the literal F2P gap, produced
   through the real public entrypoint.
4. Implemented `src/mach/chained_fixups.rs` (new) + wired `src/mach/mod.rs` (modified): 2 files,
   ~252 human-effective LOC by the Counter-2-style stripper (blank/comment/brace-only/use/mod
   lines excluded) against solution.patch, clearing the >=200 floor with a real (not padded)
   margin. Raw added: 359; Counter-1-style (blank+comment stripped only): 306.
5. Hit and fixed one real bug during first-pass fixture debugging: `walk_segment` read
   `page_count`/`page_start[]` two bytes off from their true struct offsets (20/22, not 22/24) —
   caught immediately because the Gate-1 fixture kept returning 0 imports after the feature was
   wired in. Fixed, re-verified against the same fixture, correct single import produced.
6. Wrote the full test file (`tests/mach_chained_fixups_27e49b.rs`, 17 tests, hex-suffixed per the
   banned-marker rule) directly in Rust with shared low-level byte-builder helpers, covering every
   bucket in DESIGN.md § 9. Two authoring bugs surfaced and were fixed during local validation
   (both in the TEST fixtures, not the solution): an out-of-range `lib_ordinal` in the ARM64E
   fixtures (copy-paste value 2 against a 2-entry `libs` array), and a hardcoded
   `starts_in_segment_len` that didn't account for a 2-page `page_start[]` array in the
   multi-page test. Both were caught by the tests failing against the ALREADY-CORRECT solution,
   which is exactly the intended signal (test bug, not solution bug) and is recorded here so a
   reviewer doesn't need to re-derive it.

## Local validation (full Step 6 + FP + flakiness)

- Both patch orders (`test.patch` then `solution.patch`, and the reverse) apply cleanly against a
  clean `git reset --hard $BASE_COMMIT` checkout.
- `test.patch` alone on base: `base` mode 0 failures (no regression), `new` mode 15/17 fail for the
  right reason (the feature is missing), 2/17 legitimately pass on base by design
  (`legacy_bind_opcodes_alone_still_resolve` is the untouched-path regression guard;
  `empty_imports_count_yields_no_imports` is trivially true whether or not the feature exists).
- `test.patch` + `solution.patch`: `base` 0 failures, `new` 17/17 pass, both directions.
- Flakiness gate: 5x `new`, 5x `base`, identical pass/fail counts and exit codes every run.
- **FP mechanical checks (mutation + feature-stub), all confirmed catching the intended trap:**
  - Feature-stub (no-op the entire chained-fixups branch in `imports()`): 15/17 fail, matching the
    base-mode profile exactly.
  - Rebase-vs-bind discrimination flip (treat every chain entry as a bind): exactly the 3 tests
    built for F-13 fail (`rebase_then_bind_chain_yields_exactly_one_import`,
    `bind_then_rebase_chain_still_yields_exactly_one_import`,
    `arm64e_auth_rebase_is_walked_not_emitted`); all others still pass.
  - Merge-vs-replace flip (`if legacy else if chained else []` instead of concatenating both):
    caught by `legacy_and_chained_fixups_together_are_both_reported`, confirmed via the RAW
    libtest `--format json` stream with `--test-threads=1` (`failed
    legacy_and_chained_fixups_together_are_both_reported`, all 16 others `ok`) — see the
    `cargo2junit` caveat below for why the raw stream, not the converted XML, is the ground truth
    here.

## Known local-tooling caveat: `cargo2junit` output misattribution (platform-verification owed)

Under this mutation (exactly one real failure among 17 tests), the LOCAL `cargo2junit` binary
(version unpinned; whatever `cargo install cargo2junit` resolved in this environment) converts the
correct raw libtest JSON stream into XML that marks a DIFFERENT, unrelated test
(`arm64e_auth_bind_resolves_same_as_unauth_with_zero_addend`) as the failure instead of the real
one. Reproduced twice, deterministically, both with default thread count and with
`--test-threads=1` (which ruled out a parallel-output-interleaving theory). Piping the same
captured raw JSON directly into `cargo2junit` reproduces the misattribution outside of `test.sh`
entirely, so it is unambiguously a `cargo2junit` conversion defect, not a bug in the solution, the
tests, or `test.sh`'s invocation of cargo.

This did not affect any run actually used for this submission's F2P claims (the `test.patch`-alone
base-mode run showing 15/17 correct failures was independently spot-checked against the expected
per-test list and matched; the fully-passing 0-failure runs have no failure to misattribute). It is
recorded here because the platform's own Docker image may pin a different `cargo2junit` version
than whatever this workstation resolved, so the fair action is to flag it for verification rather
than assume it is either present or absent on the platform. If a platform run ever shows an
unexpected single test named as failing where the described behavior looks correct, re-check
against the raw `--format json` stream before concluding the solution is wrong.

## Attempt history

- 2026-08-15: Design, implementation, full local validation, FP mechanical checks, deliverables
  produced. No Nova/Orion/Vega batch run (no platform access this session). Owed before submit:
  a real batch to confirm the 15-30% predicted pass rate and to run the mandatory FP Check against
  live agent solutions (not just my own reference mutations).

## Harden pass (2026-08-15, `olympus-harden` applied at design time, no batch evidence)

`ls problems/goblin-macho-chained-fixups/agent-runs*` returns nothing — no Nova/Orion/Vega/Castor
run exists for this submission. Per `olympus-harden` Stage 1, that means every statement below is a
PREDICTION, not a measurement, and the correct action is to record that honestly rather than add
speculative traps to chase a number. No traps were added in this pass.

What Stage 5's mutation harness (the trap-proof, run as the "weak proxy" Stage 1 names for the
no-evidence case) already showed, carried over from the build process above: three natural-but-wrong
implementations an agent could plausibly write (skip the feature; treat every chain entry as a
bind, ignoring rebase discrimination; replace the legacy import source instead of merging with it)
were each caught by exactly the test(s) built for that trap, and nothing else. That is coverage
evidence (the tests are not decorative), not difficulty evidence (`olympus-harden` L15: mutation
kills do not predict agent kills) — the pass-rate prediction in DESIGN.md § 13 (15-30%) stands as a
design-time estimate only.

Per Stage 3's lever order, the three traps already built are the first three levers the doctrine
prioritizes before reaching for a fourth: F-10 cross-product (pointer-format x import-table-format),
F-9 cross-stage merge-not-replace, and a second orthogonal mechanism (F-13 discard-granularity) on a
different axis from the other two. F-1 (convergent-architecture wall, the single largest measured
lever) was deliberately NOT reached for, because it requires reading a real batch's PASSING patches
to find, which does not exist yet (Stage 3, item 3: "you must read passing patches first").

**Next action owed, not deferred by choice:** run a real batch. If it lands within 15-40%, submit
as designed. If 0%, Stage 2's "0 passes, one axis carries most kills" row applies first — check
whether the ARM64E auth-variant sub-scope (the densest, least-precedented part of the design) is the
wall before touching anything else, since DESIGN.md § 13 already names it as the most likely first
cut. If >40%, re-run Stage 2 against the actual failure distribution before picking a lever; do not
guess which of the three traps is weak without that evidence.
