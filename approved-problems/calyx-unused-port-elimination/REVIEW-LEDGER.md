# Review Ledger - calyx-unused-port-elimination

Every reviewer finding across all rounds, with status. CHECK THIS BEFORE EVERY RESUBMISSION.
Reviewer rule: "with each CR I list all findings. Be mindful of previous points, ensure you
don't repeat them or leave any point without fixing or justification."

Status: FIXED (code/test/meta changed) | JUSTIFIED (argued, accepted) | OPEN (this round)

## v2 (Jul 27, 3:14 PM) - Desc 2/3, Tests 1/3, Sol 2/3
| id | finding | status |
|---|---|---|
| P4 | opening led with motivation before the ask | FIXED r22 - opens "Add a `dead-port-elimination` pass." |
| T3/T4 | constant-output never tested through an invoke output binding | FIXED r22 - `a_constant_output_bound_to_an_invoke_destination_survives` |
| T4 | no ref-only component in the report | FIXED r22 - `report_lists_a_component_that_lost_only_ref_cells` |
| S2 | `cargo fmt --all -- --check` fails | FIXED r22 - 0 violations. NOTE: recurred as v6 S2 in a different form (see below) |

## v3 (Jul 27, 7:58 PM) - Desc 3/3, Tests 1/3, Sol 1/3
| id | finding | status |
|---|---|---|
| T3/T4 | no coverage of the `fsm` surface | FIXED r23 - 4 FSM tests |
| S1/S2 | liveness/constants/rewrite all omit `Component::fsms`; `read_control` no-ops `FSMEnable` | FIXED r23 - fsms wired into round/value_driven_to/constant_output_ports/rewrite + `rewrite_fsms`. FSMEnable no-op JUSTIFIED: carries only `RRC<FSM>`, and `round`/`rewrite` traverse `comp.fsms` directly |

## v5 (Jul 28, 12:15 PM) - Desc 3/3, Tests 1/3, Sol 1/3
| id | finding | status |
|---|---|---|
| T3/T4 | no ref primitive as invoke target | FIXED r25 - dynamic + static tests |
| T3/T4 | never activates one instance via both `@go` and an invoke constant | FIXED r25 - but the FIX created v6 P4#1/T5/S1#1 |
| T3/T4 | FSM cases only test survival, not pruning or guard constant-rewrite | FIXED r25 - 2 tests |
| S1/S2 | `read_invoke` never records the invoke TARGET as a ref use | FIXED r25 - one line, covers dynamic + static (shared `read_invoke`) |
| S1 | `value_driven_to` ignores structural `@go` activation | FIXED r25 - `go_driven_structurally`. INCOMPLETE: misses invoke outputs -> v6 S1#1 |

## v6 (Jul 28, 10:14 PM) - Desc 1/3, Tests 1/3, Sol 1/3  <-- CURRENT
| id | finding | plan |
|---|---|---|
| P4#1 | `@go` sentence contradicts the structural-constant test | FIXED r27 - exception stated, covers structural wiring AND invoke outputs |
| P4#2 | ref rule silent on post-pruning mention | FIXED r27 - cascade stated explicitly |
| P4#3 | stateful-primitive boundary unclear | FIXED r27 - conservative rule stated |
| T5 | same `@go` prose/test misalignment | FIXED r27 via P4#1 |
| T3/T4 | no test for invoke OUTPUT bound to another instance's `@go` | FIXED r27 - `an_input_constant_at_an_invoke_started_by_an_invoke_output_survives` |
| T3/T4 | no test decides the ref fixed point | FIXED r27 - `a_caller_ref_bound_only_to_an_unused_callee_ref_is_removed` |
| T3/T4 | stateful-primitive boundary untested | FIXED r27 - `an_input_feeding_only_a_dead_memory_read_address_survives` + pre-existing `input_written_directly_into_local_memory_survives` |
| S1#1 | `go_driven_structurally` missed invoke output destinations | FIXED r27 - scans invoke outputs, FP-verified |
| S1#2 | `write_survives` treats every non-comb primitive input as a sink | JUSTIFIED+STATED r27 - kept conservative rule, now in meta |
| S2 | two test fns exceed `max_width=80` | FIXED r27 - renamed to 74/66 chars, 0 wrapped braces |

## Standing justifications (sent, accepted)
- direct `@external` sink: `well-formed` rejects `@external` in a non-entrypoint component with AND
  without the pass. Valid route is a ref binding, covered by
  `a_port_reaching_an_external_memory_through_a_ref_survives`. ACCEPTED by reviewer.
- `@done` driver liveness: `@done` is an instance output; front end rejects a caller driving it
  (verified: `l.done = fin` errors). ACCEPTED by reviewer.
- ref cascade design intent: reviewer replied "your fixed-point interpretation is reasonable and
  consistent with the port cascade... the intended cascade just needs to be stated explicitly and
  covered by one focused test." So KEEP behavior, add prose + 1 test.

## Retracted claims (do NOT reuse)
- "`@clk` driver is not constructible" - FALSE. `component mid(tick: 1) { wires { l.clk = tick; } }`
  parses, is well-formed, and our pass correctly keeps `tick`. It is a test gap, not a justification.

## Recurring failure pattern (watch for this)
Three times now: an ABSOLUTE sentence in meta + an implementation carrying an UNSTATED exception.
`1'b1` radix, the `@go` blanket veto, the ref post-pruning rule. Each time the text won.
When adding a rule, state its exceptions in the same sentence.

## r27 finding worth telling the reviewer (S1 ref cascade)
`PortLiveness::new(ctx)` is rebuilt on every outer round (`start_context` loop). So the caller ref
is re-derived after the dead callee binding is pruned, and BOTH readings of the `continue` converge
to the same final program. Verified by mutation: removing the callee-liveness guard entirely still
passes all 101 tests. The suggested "record the caller use before filtering" change is therefore a
no-op for output; only the round count differs. What DOES change the output is permanent
preservation, and the new cascade test catches that (mutation making every ref permanently live
fails it plus 4 others).

## Auto Review (v7 pre-check) - status after r28
| item | status |
|---|---|
| P4 trim redundant motivation | FIXED r28 - opener merged with a colon, flagged clause gone (591 -> 583 words) |
| T4 `@clk` driver test | FIXED r28 - `an_input_driving_a_sub_instance_clk_survives`. FP: fires when Clk dropped from `is_interface_port` |
| T4 entrypoint unmentioned ref | FIXED r28 - `an_unmentioned_ref_cell_on_the_entrypoint_survives`. FP: uniquely discriminating (102/1) |
| S1 caller-ref liveness | NOT CHANGED - deliberate. Human reviewer accepted the cascade in writing; Auto Review wants the opposite. Mutation proves both readings give the IDENTICAL final program (removing the guard passes all tests), so their fix is a no-op for output. Following the human reviewer, who is the accepting gate. |

## Where the two reviewers disagree (keep this straight)
Auto Review S1 says preserve the caller ref; the human reviewer said the cascade is "reasonable and
consistent with the port cascade" and only asked it be stated + tested. We did the latter. If Auto
Review re-flags it, answer with the mutation evidence, not a code change.

## r29 self-found FP hole (not reviewer-reported)
FSM-state `@go` drive was HANDLED by `go_driven_structurally` but UNPINNED by any test. Verified
exploitable: an implementation scanning groups/comb/static but not `fsms` for `@go` passed all 103
tests while diverging from the reference. Highest-probability hole in the submission, since FSM
omission is this task's proven agent failure mode (v3's entire finding; auto-review logged 4 runs
"omitted... especially FSM wiring"). Closed with
`an_input_constant_at_an_invoke_started_by_an_fsm_go_drive_survives`; mutation now fails ONLY that
test (103/1). Free: both projected passers handle it.

## Interface-port coverage, final
- signature preservation: all four, by attribute and by name (2 tests)
- `@go` driver/activation: continuous, group, FSM state, renamed, invoke-output (5 forms)
- `@reset` driver: 1 test | `@clk` driver: 1 test
- `@done` driver: JUSTIFIED unconstructible - front end rejects a caller writing an instance output

## v7 (Jul 29) - Desc 3/3 CLEAN, Sol 3/3 CLEAN, Tests 1/3
Reviewer closing: "Fix this without breaking anything else, and I think we are good to go."

| id | finding | status |
|---|---|---|
| T3/T4 | every stateful sink in the suite is a `reg`/`mem`, so the former 98/98 name-based classifier (`name.contains("reg") || name.contains("mem")`) satisfies all of them while violating the stateful rule; add a stateful primitive matching neither substring and require its source port and drive to survive | FIXED r30 - `an_input_feeding_an_unread_stateful_pipe_survives` (`std_mult_pipe`) |

### r30 change set (test-only; no source, no meta edit)
- ONE test added, 104 -> 105. Test carries its own imports (`core.futil` + `binary_operators.futil`)
  so the shared `PREAMBLE` used by the other 104 tests is untouched.
- Asserts: `leaf` keeps `a: 32` in its signature, `m.left = a;` survives in the body,
  the caller binding `a = src.out` survives, and the output stays well-formed.
- No meta change needed. The requirement was already stated verbatim in v6 P4#3:
  "A value reaching any input of a stateful primitive counts as reaching that state,
  even when nothing reads that primitive back." Generic over "stateful primitive",
  never reg/mem-specific. Traceability holds; no new discoverability burden.
- Reference needs no change: `write_survives` classifies via `cell.is_comb_cell()`
  (a real IR predicate), never by name, so `std_mult_pipe` was already handled.
  The test PINS that behavior rather than adding it.

### FP / discrimination proof
Mutated `write_survives` to the exact former implementation the reviewer described
(`type_name().contains("reg") || contains("mem")` in place of `is_comb_cell()`):
  -> 104 passed, 1 failed, and the single failure is the new test.
Discriminates precisely, and nothing else in the suite depends on the mutation.

### Regression audit vs all prior rounds
No source file touched, so every v2-v6 fix is bit-identical. Verified after the change:
base 254/0 (3x), new 105/0 (3x), 105/105 fail on pristine base, rustfmt 0 violations,
0 build warnings, 0 fn signatures over 80 chars (the v6 S2 root cause), meta 585 words
ASCII unchanged, banned-marker scan clean, test.sh mode 100755, patches ASCII/LF.

## r31 CRITICAL - patch incompleteness (found by platform Verify Solution, not by a reviewer)
Platform verdict: FAIL. `cargo-build::compilation` failed, `E0433 unresolved crate serde_json`,
104 synthesized fallback failures in BOTH base and new mode.

ROOT CAUSE (mine, not the platform's): the integration test uses `serde_json` to parse the
`dump=<file>` report. That required `serde_json = "1.0.79"` in the ROOT `[dev-dependencies]`
plus a one-line `Cargo.lock` update. Both files sat UNCOMMITTED in the worktree and were in
NEITHER patch, because the generators were scoped:
  solution.patch = git diff BASE -- calyx/
  test.patch     = git diff BASE -- test.sh tests/
Every local run passed because the worktree carried the change. The patches did not.

FIX: test.patch now also carries `Cargo.toml` + `Cargo.lock` (a dev-dependency is test
infrastructure, so it belongs in test.patch; solution.patch stays source-only, verified 0
Cargo references). serde_json was ALREADY in the BASE Cargo.lock (used by calyx-utils /
backend / opt), so no new crate is downloaded and `--locked` offline builds still work.

VERIFIED:
- reproduced: reverting Cargo.toml to BASE gives the exact E0433; restoring it gives 105/105
- `cargo build --locked --offline -p calyx --bins --tests` exits 0 (Cargo.toml/lock agree)
- reverse-apply solution.patch -> 105 tests, 105 failures, NO build-fallback (compiles cleanly)
- forward-apply -> new 105/0, base 254/0
- pristine BASE worktree + both patches == my validated worktree, 11/11 files byte-identical

STANDING RULE (this class must never recur): after generating patches, diff the set of files
that differ from BASE against the set of files the patches cover. They must be equal.
  comm -23 <(git diff --cached --name-only $BASE | sort) \
           <(grep -h '^+++ b/' solution.patch test.patch | sed 's|^+++ b/||' | sort)
Empty output = complete. A green local test run does NOT prove patch completeness, because the
worktree can carry changes the patches omit. This is the SECOND time worktree-vs-patch drift
bit this submission (the first was the stash incident in r30).

### r31 revision-regression re-audit (after regenerating BOTH patches)
All 12 ledger-named tests present, and present in test.patch. All 8 ledger-named source fixes
present in solution.patch (fsms wiring, rewrite_fsms, go_driven_structurally, bound_by_invoke
invoke-output scan, record_ref_use, FixedSignature seed, is_comb_cell sink rule,
continuous_write second-invoke guard). rustfmt 0 violations, 0 fn signatures over 80 chars,
0 build warnings. FP re-check: name-based classifier mutation fails ONLY the new v7 test (104/1).
Nothing from v2-v7 regressed.
