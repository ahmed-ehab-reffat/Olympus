# feedback.md — go-workflows-channel-drain

## Summary

Olympus pick against `cschleiden/go-workflows` (durable workflow engine, deterministic replay).
Sourced via olympus-hunt: `core/`, `internal/workflowstate`, `workflow/executor` are cold
(0 commits/12mo, 0 open PRs touching them); the open-PR queue is entirely backend-adapter
infrastructure (postgres/sqlite/valkey), none of it touching the channel/select/signal machinery
this pick lives in.

Feature: `Channel.Drain`/`Peek` family (bulk, non-blocking, non-destructive read of everything a
channel can currently provide, including values held by blocked senders), a `Drain` Select case
and a `SelectAll` batch-processing mode, and configurable signal-channel capacity + overflow
policy (`OverflowBlock` default vs `OverflowDropOldest`), plus the backlog-replay ordering
correction this makes observable.

## Traps (see DESIGN.md § 11 for the original table; final set below)

- **Trap A (F-9, backlog replay order):** the pre-existing `GetSignalChannel` backlog flush
  iterated pending signals in REVERSE (`for i := len(pendingSignals)-1; i >= 0; i--`), silently
  reversing any signals that arrived before the workflow created their channel. Fixed to a forward
  loop. Mutation-confirmed: reverting to the reverse loop kills 4 of the new tests (order,
  drop-oldest-backlog, mixed-origin, DrainAll/PeekAllChannels).
- **Trap B (F-2, blocked-sender inclusion):** `Drain`/`Peek` must include values held by
  coroutines currently blocked on `Send`, not just the buffer slice `c.c`. Mutation-confirmed: a
  naive `Drain` that only copies `c.c` kills 2 tests (blocked-sender drain order, peek-does-not-
  resolve-a-send).
- **Trap C (unmeasured, closed-channel termination):** `tryReceive`'s three-value return
  `(v, ok, rok)` makes it easy to break only on `!rok`, which loops forever on a closed, empty
  channel (`rok` stays true, `ok` stays false, forever). Confirmed by reverting the fix locally:
  the closed-empty test's own 2-second internal timeout catches the hang and fails cleanly rather
  than hanging the whole suite; `go test -timeout=120s` is the backstop in test.sh.
- Attempt 11 (this session, Verify Flakiness FAIL: 2 flaky tests across 6 runs per state). Could
  not reproduce by running test.sh repeatedly as-is (6x, then 30-60x with -race/-shuffle/-cpu
  variations, all clean), so investigated by source. `internal/sync/coroutine.go`'s "coroutines"
  are real background goroutines synchronized over channels; three of the new tests deliberately
  leave one permanently blocked at the end (never resumed via a second `Execute()` or terminated),
  which is a genuine goroutine leak in the same test binary/process as any goroutine-count-based
  tests: `Test_ChannelSend_BlocksWhenFullUnderBlockPolicy`,
  `Test_SelectDrainCase_ReadyWithBlockedSenderOnUnbufferedChannel`, and
  `Test_WorkflowNewBufferedChannelWithPolicy_ExplicitOverflowBlock_BlocksWhenFull`. Fixed all
  three by calling `.Exit()` on the still-blocked coroutine once the test's assertions are done,
  matching the pattern the repo's own tests already use for cleanup elsewhere. This alone did not
  reproduce or eliminate a flake locally (stress-tested up to 30x with -race, clean), so kept
  digging: `workflow/executor/executor_test.go`'s `Test_Executor` has three subtests
  (`Close_removes_any_goroutines`, `_defer`, `_nested`) that assert exact `runtime.NumGoroutine()`
  deltas around executor shutdown -- a pattern that is inherently racy since goroutine teardown
  isn't perfectly synchronized with the signal that triggers the assertion. Reproduced this
  directly against an UNMODIFIED checkout of BASE_COMMIT (no patches applied at all): repeated
  `go test -count=30 -race ./workflow/...` runs failed 1/3, 12/3, 26/3 subtests across three
  attempts, confirming this is a pre-existing upstream flaky baseline entirely unrelated to this
  submission. `test.sh`'s package scope included `./workflow/...`, which recursively pulls in
  `./workflow/executor`, so this pre-existing flakiness was in scope for both `base` and `new`
  modes. Per the mandatory flakiness rule (known-flaky baseline -> scope base mode to the
  solution-relevant tests, with a documented reason), narrowed both modes' package list from
  `./workflow/...` to `./workflow` (the package itself, no subpackages) -- none of the new tests
  live in `workflow/executor`, and the logger-fix behavioral coverage for that file is already
  exercised through the `tester` package's own tests, so this drops zero coverage of anything this
  change touches. Documented the reasoning directly in `test.sh` as a comment above the mode
  dispatch. Re-stress-tested the narrowed scope: 6x clean (matching the platform's own
  methodology) plus 30x with `-race`, all clean, for both `base` and `new`. Test count unaffected
  (46 new); base count dropped from 157 to 131 (the removed `workflow/executor` +
  `workflow/executor/cache` packages' own pre-existing tests, none of which exercise anything this
  patch touches). Re-validated end to end in a fresh worktree at BASE_COMMIT: both patches apply
  cleanly, base 131/0, new 46/0.
- Attempt 12 (this session, Auto Review, Revision Requested; Description 3/3, Tests 0/3 ->
  fixed, Solution 1/3 -> fixed): a Blocker leak plus a real correctness bug, both fixed.
  (1) Blocker, platform-content leak: round 11's own flakiness-fix comment in `test.sh` named
  hidden-artifact terms directly ("BASE_COMMIT", "test.patch", "solution.patch"). Reworded to
  describe the same reasoning (pre-existing flaky Test_Executor subtests, reproduced on an
  unmodified checkout) without naming any of those artifact terms.
  (2) High, real solution bug: `channel.Send`'s retry loop could leave a stale entry in
  `c.senders` after its OWN retry succeeded directly via `trySend` (as opposed to being popped by
  a receiver, which already cleans up correctly) -- e.g. a coroutine blocked sending to a full
  buffered channel, where a later `ReceiveNonBlocking` opens capacity and the coroutine's next
  `Execute()` resumes and succeeds via `trySend` on its own retry. The old code just returned
  `true` on that path without ever removing the `pendingSend` it had queued earlier in the same
  call. Confirmed materiality: `Drain`/`PeekAll` would then double-report the value (once from the
  buffer, once from the stale sender), and `TryCloseDraining` would report `false` (still blocked)
  even though nothing was actually blocked anymore. Fixed by keeping a direct reference to the
  queued `pendingSend` (`ps`) instead of a bool flag, and removing it via a new
  `removeSender` helper whenever `trySend` succeeds with `ps != nil`. Added
  `Test_ChannelSend_ResumingAfterCapacityOpens_RemovesStalePendingSender`, which reproduces the
  reviewer's exact scenario (capacity-1 channel, buffer 1, block a sender with 2, receive the 1,
  resume the sender, then check `PeekAll` and `TryCloseDraining`). Mutation-confirmed: reverting
  just the cleanup call makes this exact test fail with `PeekAll` returning `[2, 2]` instead of
  `[2]`, matching the reviewer's predicted failing case precisely.
  (3) Medium, test coverage: `Test_DrainAllAndPeekAllChannels_CombineMultipleChannelsInOrder`
  checked `DrainAll`'s return value but never that it actually removed values from the input
  channels (an implementation aggregating `PeekAll` instead of `Drain` per channel would have
  passed). Added `a.Drain()`/`b.Drain()` empty-after assertions.
  (4) Medium, test coverage: the OverflowBlock `SendAllNonblocking` test never asserted
  `DroppedCount` for the one value that didn't fit. Added that assertion (expected 1, matching
  "stopping at the first one that does not fit").
  Test count: 46 -> 47 (+1 stale-sender regression test; the DrainAll and SendAllNonblocking fixes
  strengthened existing tests rather than adding new ones). Re-validated end to end in a fresh
  worktree at BASE_COMMIT: both patches apply and reverse cleanly, base 131/0, new 47/0. Also ran
  a heavier stress pass (count=20, -race) across the narrowed package scope purely as extra
  diligence beyond the platform's own 6-run methodology; it surfaced one single non-reproducing
  failure in the pre-existing `Test_Activity_Panic` (tester package, real time.Sleep-based, not
  touched by this diff) that did not reproduce across 5 further isolated and full-package attempts
  at pure BASE_COMMIT -- noted here for the record but not acted on further, since it did not
  reproduce even close to platform's own 6-run cadence and excluding the tester package would
  remove real coverage this submission needs.
- **F-10 cross-product:** mixed-origin drain (some backlog-origin, some post-creation live, on a
  capacity-limited channel) — a single `Drain()` call must return all of it in one combined
  arrival order. Covered by `Test_MixedOriginDrain_BacklogAndLiveSignalsCombineInOrder`.

## Validation performed this session (no platform run yet)

- Local Go toolchain installed (`go1.25.0`, not preinstalled in this environment) to
  `Olympus/.toolchains/go`.
- Full repo builds clean (`go build ./...`), all pre-existing packages pass (`go test`), 3x
  determinism, `-race` clean.
- Solution effective LOC (Counter-2 approximation): ~216 (Counter-1 looser measure: 288), against
  the current sprint's 200 floor.
- 35 (36 after the IsFull addition) new tests across `internal/sync` (channel + selector) and
  `tester` (behavioral, through `WorkflowTester`/`SignalWorkflow`, no mocks).
- Build-tag isolation (`//go:build channeldrain`) so `base` mode's plain `go test ./...` never
  touches the new files (pre-existing tests unaffected by their presence), and `new` mode uses
  `-tags=channeldrain -run '^(...)$'` to run only the 36 new tests.
- Fail-on-base verified for real: stashed the 8 solution files, confirmed `new` mode fails to
  COMPILE (undefined symbols) while `base` mode is unaffected; test.sh's build-failure fallback
  synthesizes one FAILURE `<testcase>` per expected new test name (F2P node alignment) when the
  tagged build produces `[build failed]` or an unexpected testcase count.
- Patches verified to apply cleanly in both orders and reverse cleanly (`git apply -R`) on a fresh
  clone at BASE_COMMIT.
- Mutation-tested all three named traps directly against the solution source (not just described
  as hypothetical) — each kills the tests named above.
- Found and fixed a real bug in my own first draft: `executor.go`'s dropped-signal log used the
  executor's raw `e.logger` instead of `e.workflowState.Logger()` (the replay-suppressed one),
  which re-logged on every replay pass. Confirmed via the tester's WARN log line count.

## Owed to the platform run

- Docker build/run verification (no local Docker in this environment).
- Nova/Orion/Vega pass-rate batch — no empirical pass-rate data yet, only the design's predicted
  15-30% band (see DESIGN.md § 13).
- FP Check (verify every passing agent actually met every requirement) — deferred to the mandatory
  final gate once a batch exists.

## Attempt history

- Attempt 1 (this session): design + implementation + full local validation. Not yet submitted to
  the platform.
- Attempt 2 (this session, precheck round 1): "Problem and tests are aligned" precheck ERROR:
  meta.md didn't name `NewBufferedChannelWithPolicy`'s exact signature or `SelectAll`'s return
  value. Fixed both in meta.md; no code/test changes needed.
- Attempt 3 (this session, precheck round 2): two more precheck findings on the same re-run:
  (a) alignment ERROR that the description didn't pin the `internal/sync`-level signatures
  (`NewBufferedChannelWithPolicy[T](size int, dropOldest bool)`, `Drain`, `SelectAll`) the tests
  exercise directly, since `workflow` is a thin wrapper over `internal/sync`; (b) quality-review
  ERROR that `Test_LiveSignal_BeyondCapacityWithBlockPolicy_IsDroppedAndCounted` contradicts the
  stated "OverflowBlock waits for room" default, because a live signal is delivered via
  `SendNonblocking` (never blocks) so it is lost, not queued, when the default policy's buffer is
  full. Fixed by: (1) naming the internal/sync signatures explicitly in meta.md, (2) clarifying
  that OverflowBlock only waits for a *blocking* sender (a coroutine's own `Send`) and that a
  non-blocking delivery is lost and counted the same as a drop-oldest eviction. Also strengthened
  test coverage per the accompanying warnings: added a direct `workflow.Select(ctx,
  workflow.Drain(...))` test (previously only `sync.Drain` was tested directly) and asserted
  `workflow.SignalChannelDroppedCount` against a positive count (previously only the
  zero/uncreated-channel case was covered). Test count: 35 -> 37. Re-validated: 3x deterministic,
  fail-on-base still 37/37, patches re-verified to apply/reverse cleanly.
- Attempt 4 (this session, precheck round 3): quality-review ERROR that `workflow.SelectAll` was
  a stated requirement but only its `internal/sync` counterpart was ever tested directly, so a
  solution could omit it entirely and still pass; also flagged `workflow.NewBufferedChannelWithPolicy`
  as untested. Separately, an AI-formatting warning flagged two 150+ word unbroken paragraphs, and
  a quality-suggestions pass said to REMOVE the internal/sync-mirroring sentences I had just added
  in round 2 (correctly — the real fix was to test the public API directly, not describe the
  private mirror). Fixed by: (1) adding `workflow/channel_drain_b7b95d_test.go`, five new tests
  exercising `workflow.SelectAll` (order + return count + Default-precedence), `workflow.Drain` as
  a `Select` case, and `workflow.NewBufferedChannelWithPolicy` (drop-oldest eviction + negative-size
  panic) directly via `sync.Background()` + `sync.NewCoroutine`, matching the exact pattern the
  repo's own `workflow` package tests already use (`activity_test.go`, `subworkflow_test.go`,
  `sleep_test.go`); (2) removing all internal/sync-signature-mirroring sentences from meta.md and
  splitting the two long paragraphs into eight shorter ones (422 words total, still under the
  500-word hard cap, no wall-of-text). Test count: 37 -> 42. Re-validated: 3x deterministic
  (157 base / 42 new), fail-on-base 42/42, patches apply/reverse cleanly on a fresh clone.
- Attempt 5 (this session, Test Fairness FAIL, decisive gate): 7 of 42 tests flagged unfair.
  Root causes: (a) 4 internal/sync tests hardcoded the private, unstated
  `NewBufferedChannelWithPolicy[T](size int, dropOldest bool)` signature — the description only
  ever pinned the public, enum-based `workflow.NewBufferedChannelWithPolicy`, so a fair
  implementation using an internal enum instead of a bool would fail to compile against these
  tests; (b) `Test_ChannelTryCloseDraining_FailsWithBlockedSenders` asserted `require.Nil` on the
  failure-case return slice, an unstated representation choice (nil vs allocated-empty); (c)
  `Test_ChannelPeekN_ReturnsUpToNAvailable` asserted `PeekN(0)` returns empty, but nonpositive-n
  behavior was never defined, and empty/reject/panic are all equally plausible; (d)
  `Test_DrainAllAndPeekAllChannels_CombineMultipleChannelsInOrder` pinned a flat `[]T` return
  without the description ever ruling out a grouped `[][]T` return.
  Fixed by: removed the 4 bool-signature `internal/sync` tests outright (their behavioral coverage
  already exists, or was added, at the public `workflow.NewBufferedChannelWithPolicy` level, which
  is the API the description actually specifies) rather than trying to describe an internal
  representation choice that doesn't need to exist; relaxed the `TryCloseDraining` failure-case
  assertion to not check the slice's nil-ness, only `ok` and `Closed()`; dropped the unstated
  `PeekN(0)` assertion instead of inventing a nonpositive-n contract nothing else needed; and
  explicitly stated in meta.md that `DrainAll`/`PeekAllChannels` return "one combined slice,
  concatenating each channel's own values" (locking the flat-return choice fairly, since the test
  already only exercised the flat form). Also tightened the `CloseDraining`/`TryClose`/
  `TryCloseDraining` return-type wording per a same-round WARNING (each verb's return type spelled
  out separately: `[]T`, `bool`, `([]T, bool)`), and trimmed illustrative examples out of the
  `OverflowBlock` sentence per an AI-quality suggestion. Test count: 40 (down from 42; -4 unfair
  removals, +2 replacement coverage at the workflow level already added in round 4). Re-validated:
  3x deterministic (157 base / 40 new, 0 failures), fail-on-base 40/40, patches apply/reverse
  cleanly on a fresh clone with no whitespace warnings.
- Attempt 6 (this session, Test Fairness FAIL, second pass): 2 of 40 flagged. Both were genuine
  unstated-contract gaps, not test bugs: `Test_ChannelPeekN_ReturnsUpToNAvailable` pinned the
  "up to n, fewer if unavailable" shortage rule without meta.md ever stating it, and
  `Test_SignalChannelDroppedCount_ReportsZeroForUncreatedChannel` pinned a zero-fallback for a
  name with no channel, also unstated. Fixed by adding one clause to meta.md for each (PeekN's
  paragraph now says "returns up to n values, fewer if the channel currently has fewer
  available"; the closing paragraph now says SignalChannelDroppedCount reports "0 if no channel
  with that name has been created yet") -- no test or solution changes needed, both tests already
  matched the now-stated behavior. Also applied two more quality-suggestion trims (dropped the
  now-redundant standalone `TryClose` sentence, folding its rule into the `TryCloseDraining`
  sentence instead of restating it twice; dropped the trailing "both by Channel.DroppedCount"
  clause). 438 words, still under the 500 cap. Verified: base 157/0, new 40/0, no code changes.
- Attempt 7 (this session, all three precheck categories WARNING, none FAIL): the decisive Test
  Fairness gate is clean now; remaining findings are advisory. Fixed the one real gap: the
  alignment check pointed out that `internal/sync` and `tester`-level tests call `c.DroppedCount()`
  directly on a `Channel` instance, but meta.md only ever named `workflow.SignalChannelDroppedCount`
  and never stated `Channel.DroppedCount` as its own public method -- this is exactly the trailing
  clause I trimmed in round 6 on a quality-suggestion basis, and removing it left the method
  genuinely undocumented. Re-added it as its own sentence: "`Channel.DroppedCount` reports how many
  values a channel has lost this way." Declined two other optional suggestions on purpose: (1)
  removing "A `Default` case among them only fires if none of the others were ready." -- this is
  not a restatement of ordinary Select semantics, it is the one sentence that resolves what happens
  to Default specifically under SelectAll's multi-case-fire model, and
  `Test_WorkflowSelectAll_DefaultOnlyFiresWhenNothingElseReady` depends on it being stated; (2)
  trimming the TryCloseDraining sentence to drop "using the same rule as TryClose: false instead of
  closing if coroutines are still blocked sending to it" -- after round 6 folded the standalone
  TryClose sentence into this one, it is now the ONLY place TryClose's blocked-sender rule is
  stated at all; removing it would leave `Test_ChannelTryClose_FailsWithBlockedSenders` unfair
  again. Also declined the advisory suggestion to re-describe internal/sync-level mirroring of
  Drain/SelectAll/channel methods in meta.md -- round 4's decisive Test Fairness FAIL already
  established that the fix for this exact ambiguity is testing the public workflow-level API
  directly, not restating private internals; the tests already do that. 448 words, still under the
  500 cap. No test or solution changes needed this round.
- Attempt 8 (this session, Auto Review, Revision Requested; Description 3/3, Tests 0/3, Solution
  1/3): the first review pass with real code-level findings rather than only description/test
  wording. Fixed all seven cited items:
  (1) Blocker, platform content leak: `test.sh`'s build-failure-synthesis comment named grading
  terminology ("F2P node set", "solution-applied run"). Reworded the comment in repo/test terms
  only, with no benchmark or grader vocabulary.
  (2) T8 Medium, failure diagnostics: `synthesize_build_failure_xml` replaced a real compile/test
  failure with a hardcoded "solution not applied" message, discarding the actual diagnostic on a
  genuine code defect. Changed it to capture the real `go test` output (XML-escaped) and embed it
  as each synthesized testcase's failure detail, so a real compiler error stays visible.
  (3) T8 Medium, reporter status: `base` mode's exit status came only from `go test` via
  `PIPESTATUS[0]`, so a `go-junit-report` failure after a successful test run could still exit 0.
  Rewrote both `base` and `new` modes to run `go test` to a file, then `go-junit-report` as a
  separate step, checking both exit codes directly (dropped `PIPESTATUS` entirely after hitting a
  bash quirk in this environment where indices past 0 read as unbound under `set -u`).
  (4) T3/T4 High, missing explicit-OverflowBlock coverage: no test exercised
  `workflow.NewBufferedChannelWithPolicy` with `OverflowBlock` passed explicitly at positive
  capacity, so an implementation that silently drop-oldest'd every explicit policy could still
  pass. Added `Test_WorkflowNewBufferedChannelWithPolicy_ExplicitOverflowBlock_BlocksWhenFull`.
  (5) T3/T4 High, missing blocked-sender bulk-peek coverage: `PeekN`/`PeekAll` were only tested
  against buffered values, never blocked senders, even though the implementation already handled
  both (this was a test gap, not an implementation bug). Added
  `Test_ChannelPeekNAndPeekAll_IncludeBlockedSenders`.
  (6) S1 High, real implementation bug: `channel.canSend()` (used by `Select`'s `Send` case
  readiness) ignored `dropOldest`, so a full `OverflowDropOldest` channel reported itself
  unready for `Select`/`SelectAll` even though a direct `Send`/`SendNonblocking` on the same
  channel would immediately succeed by eviction. Fixed `canSend` to also return true when
  `dropOldest && size > 0`. Added `Test_WorkflowSelect_SendCase_OnFullDropOldestChannel_IsReady`
  and mutation-confirmed it: reverting the `canSend` fix makes this exact test fail.
  (7) S1 Medium, `PeekN` allocation bound: `PeekN(n)` preallocated a slice of capacity `n`
  regardless of how many values were actually available, so a large `n` on a near-empty channel
  could force a huge allocation before returning the (correctly small) result. Fixed by clamping
  `n` to the actual available count (`len(c.c)+len(c.senders)`) before allocating.
  (8) S2 Medium, `PendingSignalNames` map-iteration nondeterminism: it built its result by
  ranging directly over the `pendingSignals` map, contrary to the repo's documented workflow
  determinism rule. Added `sort.Strings` before returning.
  Test count: 40 -> 43 (+3: explicit-OverflowBlock blocking, PeekN/PeekAll blocked-sender
  coverage, Select-Send-drop-oldest readiness). Re-validated end to end in a fresh worktree at
  BASE_COMMIT: both patches apply and reverse cleanly, fail-on-base 43/43 (with real compiler
  output embedded, not a generic message), solution-applied base 157/0 and new 43/0. Local run of
  the AI-formatting/word-count check still holds (448 words, ASCII, under the 500 cap) since
  meta.md was not touched this round -- the review's Description dimension was already 3/3.
- Attempt 9 (this session, Test Fairness FAIL): 2 of 43 flagged. Both were
  `Test_ChannelTryClose_SucceedsWithoutBlockedSenders` and
  `Test_ChannelTryClose_FailsWithBlockedSenders`, which called a standalone `c.TryClose()`
  directly. meta.md's only mention of `TryClose` is a comparison inside the `TryCloseDraining`
  sentence ("using the same rule as TryClose") -- it never asks for a standalone `TryClose` method
  as its own requirement, so two tests hard-requiring that exact method name to exist and compile
  pin an unstated, unrequested API surface. The reviewer flagged this as especially serious since
  it can fail the whole tagged package to compile if an otherwise-correct solution doesn't happen
  to add that extra method. Fixed by deleting both tests outright (not by adding a meta.md
  sentence requesting `TryClose`, since the prompt genuinely doesn't need it as a separate
  requirement -- `TryCloseDraining`'s own tests already exercise the same blocked-sender rule
  without needing a standalone method). Confirmed `TryCloseDraining`'s implementation does not
  depend on `TryClose` internally (implemented independently, not via delegation), so removing
  these two tests does not weaken coverage of anything meta.md actually requires. Left the
  solution's public `TryClose()` method in place (harmless extra API surface, not tested, not
  penalized). Test count: 43 -> 41. Re-validated end to end in a fresh worktree at BASE_COMMIT:
  both patches apply cleanly, base 157/0, new 41/0.
- Attempt 10 (this session, Test Fairness clean; advisory coverage suggestions only): with the
  decisive gate now clean, took the 3 of 5 advisory suggestions that trace directly to already-
  stated meta.md text with no new ambiguity risk, and declined the other 2. Added: (1) closed-
  empty checks for `Peek`, `PeekN`, `PeekAll` (meta.md already says "All of these return an empty
  result immediately on a channel with nothing available, whether or not it is closed" -- Drain
  already had this coverage, the bulk-peek methods didn't); (2) a `DroppedCount == 2` assertion
  added to the existing drop-oldest `SendAllNonblocking` test (the loss-accounting rule was
  already stated and already exercised for single sends, just not for this path); (3) two Select
  `Drain`-case readiness-edge tests -- an unbuffered channel with a blocked sender, and a closed-
  empty channel -- since meta.md states Drain's readiness "under the same condition as Receive,"
  and the existing coverage only exercised the buffered-values-ready case. Declined: PeekN(0) (this
  is the exact nonpositive-n ambiguity removed in round 5's Test Fairness FAIL -- adding it back
  risks reopening that exact finding); backlog-materialization-under-OverflowBlock (verified via
  code read that this scenario blocks the *creating coroutine itself* inside
  `GetSignalChannel`'s `c.Send` call, which doesn't return an channel handle in the test's own
  workflow function until unblocked -- correctly exercising this needs careful multi-workflow or
  timeout-based test scaffolding, and the risk of an accidentally-hanging or flaky test outweighed
  an advisory-only suggestion). Test count: 41 -> 46 (+3 closed-empty peek checks, +2 Drain-
  readiness-edge checks; the DroppedCount assertion strengthened an existing test rather than
  adding one). Re-validated end to end in a fresh worktree at BASE_COMMIT: both patches apply
  cleanly, base 157/0, new 46/0.
- Attempt 13 (this session, Test Fairness FAIL 1/48; three Warning-level precheck passes, no
  Blocker/Error): the decisive finding was `Test_PendingSignalNames_ReflectsUncreatedChannels`
  pinning an exact `[]string` return from `workflow.PendingSignalNames`, when meta.md only ever
  said the function "reports which signal names" are pending, never its return shape -- a map
  (matching the repo's own neighboring `PendingFutureNames() map[int64]string` convention) would
  be an equally reasonable implementation choice the test would wrongly fail. Fixed by naming the
  return type explicitly in meta.md ("`workflow.PendingSignalNames` returns a `[]string` of signal
  names...") rather than weakening the test, since the function itself is a genuine, deliberately-
  added requirement -- only its shape was unstated, unlike round 9's TryClose (an entire method
  nobody asked for). Also took three Warning-level suggestions that were free wins: (1) trimmed the
  opening sentence's dangling "and extend Select with a batch-processing mode" clause, now fully
  covered by the SelectAll paragraph two sentences later; (2) reworded TryCloseDraining's sentence
  to state its own rule directly instead of cross-referencing `TryClose` (which meta.md never
  otherwise introduces as its own requirement); (3) removed the concrete `.(*channel[int])` type
  assertions from every test in `channel_drain_b7b95d_test.go` -- every method those tests call
  (`SendNonblocking`, `Send`, `ReceiveNonBlocking`, `Drain`, `Peek`, `PeekN`, `PeekAll`, `Cap`,
  `IsFull`, `DroppedCount`, `CloseDraining`, `TryCloseDraining`) is already on the public `Channel`
  interface, so the downcast to the unexported struct was pure unnecessary coupling, not something
  any of the tests actually needed. Declined the two other advisory description trims (redundant
  "fewer if the channel currently has fewer available" and "on the same channel") only where they
  overlapped the same sentences already being edited for the fairness fix -- folded into the same
  pass rather than a separate no-op round. 437 words, ASCII, ASCII-clean, ~308 Counter-1 effective
  LOC on solution.patch (unchanged this round -- only meta.md and test files changed). Test count
  unchanged at 47 (no tests added or removed, only the fairness-flagged test's underlying
  requirement clarified in meta.md and unrelated tests de-coupled from the concrete type).
  Re-validated end to end in a fresh worktree at BASE_COMMIT: both patches apply and reverse
  cleanly, base 131/0, new 47/0.
- Attempt 14 (this session, Task Quality FAIL + Solution Quality FAIL): the first review pass to
  fail both dimensions at once. Task Quality flagged one fairness gap (Criterion 04); Solution
  Quality flagged three real correctness bugs (2 High comprehensiveness, 1 High comprehensiveness,
  1 Low doc-comment) plus its own coverage suggestions. Fixed all of it:
  (1) Task Quality, fairness: hidden tests call `c.Closed()` on the public `Channel` interface, but
  meta.md never states that `Channel.Closed` is part of the added public surface (it only existed
  on the pre-existing, unexported `ChannelInternal` before this submission). Since `Closed` is a
  genuine, deliberately-useful addition (not a stray unrequested method like round 9's `TryClose`),
  fixed by naming it explicitly in meta.md rather than removing the tests' dependency on it:
  "`Channel.Closed` reports whether the channel has already been closed."
  (2) Solution Quality High, `TryCloseDraining` drops its result on the blocked-sender path: it
  returned `nil, false` unconditionally instead of the remaining values. Fixed to `return
  c.PeekAll(), false` -- non-destructive, matching "without closing." Strengthened
  `Test_ChannelTryCloseDraining_FailsWithBlockedSenders` to check the returned slice and that the
  blocked coroutine is still unresolved, and added
  `Test_ChannelTryCloseDraining_FailsWithBlockedSenders_IncludesBufferedAndBlockedValues` (buffer
  + blocked sender both present). Mutation-confirmed: reverting to `nil, false` fails both.
  (3) Solution Quality High, explicit signal-channel capacity of 0 silently became 100:
  `GetSignalChannel` could not distinguish "capacity omitted" from "capacity explicitly 0" since
  both arrived as the same int. Fixed by moving default-resolution to the public API layer:
  `signalChannelOptions` in `workflow/signal.go` now tracks `capacitySet` separately from
  `capacity`, and `NewSignalChannel` only substitutes `DefaultSignalChannelCapacity` when the
  option was never supplied; `GetSignalChannel` no longer special-cases 0 at all, it just panics on
  negative and uses whatever it's given otherwise. Added
  `Test_SignalChannel_ExplicitZeroCapacity_CreatesUnbufferedChannel`. Mutation-confirmed: reverting
  either half of the fix (either file alone) reproduces the bug and fails this test.
  (4) Solution Quality High, Drain/Peek do not preserve one arrival order across buffered and
  blocked-sender values: `trySend` always let a fresh, unrelated `SendNonblocking` claim newly
  freed buffer capacity ahead of senders that had been queued and blocked longer, since nothing
  reserved the freed slot for them. Fixed by adding `promoteSenders`, called from `tryReceive`
  right after a buffer pop: it proactively moves the oldest queued blocked sender's value into the
  freshly freed slot (and resolves that sender), maintaining the invariant that capacity is only
  ever "free" when no sender is waiting for it -- so a later fresh send can never jump the queue.
  Added `Test_ChannelDrain_FreedCapacityGoesToOldestBlockedSender_NotANewSend`, reproducing the
  reviewer's exact scenario (buffer size 1, filled with 1, two blocked senders 2 and 3, receive
  frees the slot, a fresh nonblocking send of 4 must NOT claim it). Mutation-confirmed: reverting
  the `promoteSenders()` call fails this test. Verified no regressions from this change across all
  50 new + 131 base tests, run 3x.
  (5) Solution Quality Low, stale doc comments: `DroppedCount`'s comment said it was always 0
  without drop-oldest (false -- a failed nonblocking send under the default policy also counts),
  and `SendAllNonblocking`'s comment claimed drop-oldest always sends everything (false for a
  zero-capacity channel, which has no buffer to evict into). Fixed both comments in both places
  they're duplicated (`internal/sync/channel.go`'s and `workflow/channel.go`'s `Channel[T]`
  interfaces), plus reworded `TryCloseDraining`'s stale "nil, false" comment to match its corrected
  behavior.
  Caught and fixed a real regeneration mistake mid-round: the first solution.patch regen after
  these fixes omitted `workflow/channel.go` and `workflow/select.go` from the diff file list (they
  hold the public `Channel[T]` interface, `OverflowPolicy`, and the `Send`/`Receive` `Select` case
  wiring that call into the just-fixed `internal/sync` layer) -- caught immediately by the fresh-
  worktree round-trip check, which failed to even compile (`undefined: OverflowPolicy`, `missing
  method Cap`). Regenerated with the complete 8-file list and re-verified.
  Test count: 47 -> 50 (+3: TryCloseDraining buffered+blocked coverage, the promoteSenders ordering
  regression, the zero-capacity signal channel regression). Effective LOC (Counter-1) ~321, still
  comfortably above the 200 floor. 446 words, ASCII. Re-validated end to end in a fresh worktree at
  BASE_COMMIT, 3x each mode: base 131/0, new 50/0 every run; both patches apply and reverse
  cleanly.
- Attempt 15 (this session, Test Fairness FAIL, 3 of 52 unfair): all three flagged tests were ones
  added last round to cover the previous Solution Quality pass's findings, and all three turned
  out to pin behavior beyond what the prompt actually commits to.
  (1)+(2) `Test_ChannelTryCloseDraining_FailsWithBlockedSenders` and its
  `_IncludesBufferedAndBlockedValues` sibling additionally asserted that the failure path is
  non-destructive (a repeated `Drain()` returns the same values again, the blocked sender stays
  unresolved). The prompt only says the failed call "does not close" -- it never says the returned
  values remain available afterward, and both a destructive and a non-destructive reading are
  equally plausible with no repo convention settling it. Fixed by keeping the one assertion that
  traces directly to the actual bug fix (the call itself must return the remaining values, not
  nil) and dropping the extra non-destructiveness checks.
  (3) `Test_ChannelDrain_FreedCapacityGoesToOldestBlockedSender_NotANewSend` (added to cover last
  round's "Drain does not preserve arrival order" Solution Quality finding) pinned an additional,
  unstated scheduling policy: that freeing one buffered slot must atomically reserve it for the
  oldest already-blocked sender before any newly-arriving send can claim it. The reviewer pointed
  out this actually conflicts with the pinned base commit's own pre-existing trySend/tryReceive
  priority (a competent solver following that existing shape would let the new send claim the
  slot). Given the direct conflict between this fairness finding and the prior round's Solution
  Quality finding, sided with fairness (the decisive gate): reverted the `promoteSenders`
  mechanism from `internal/sync/channel.go` entirely (there is no way to test the ordering
  behavior it adds without also pinning the same unstated reservation-timing policy that makes it
  unfair), and deleted the test. The `TryCloseDraining` return-value fix from round 14 is
  unaffected by this revert (unrelated code path). Verified via full local re-run that reverting
  `promoteSenders` does not regress any of the other 48 tests -- the only test that exercised it
  was the one just deleted.
  Test count: 50 -> 49 (net: -1 FIFO-promotion test, 2 existing tests trimmed not removed). Local
  build hit real disk contention from a concurrent session's cargo build sharing this disk (a `go
  build` timed out at 2 minutes before completing successfully once retried with a longer budget)
  -- not a defect in this submission, noted here since it delayed this round's validation.
  Re-validated end to end in a fresh worktree at BASE_COMMIT, 3x each mode: base 131/0, new 49/0
  every run; both patches apply and reverse cleanly.
- Attempt 16 (this session, Test Fairness clean; advisory coverage suggestions only): with the
  decisive gate clean, took the 3 of 5 advisory suggestions that trace directly to already-stated
  meta.md text with zero new ambiguity, and declined the other 2 for reasons already established
  earlier this session. Added: (1)
  `Test_ChannelCloseDraining_WithBlockedSenders_ResolvesThemWithoutPanicking` -- meta.md separately
  and fully specifies both `Drain` (removes and resolves everything obtainable, including blocked
  senders) and `CloseDraining` ("closes a channel and returns any values still present"); combining
  the two already-stated behaviors is a single, directly-inferable composition (Drain empties
  `c.senders` before `Close` ever checks it, so it cannot hit the separate "still blocked" panic
  path), not a new invented requirement; (2)
  `Test_ChannelClosed_FalseOnFreshChannel_TrueAfterClose` -- trivial boundary check on the
  `Channel.Closed` sentence added to meta.md last round. Declined: PeekN(0) (the exact
  nonpositive-n ambiguity that caused round 5's Test Fairness FAIL -- reopening it risks that same
  finding, per round 10's identical call on the same suggestion); backlog materialization under
  OverflowBlock (round 10's finding still holds: this scenario blocks the *creating coroutine
  itself* inside `GetSignalChannel`'s `c.Send`, and reliably exercising that without an
  accidentally-hanging or flaky test needs scaffolding this suite doesn't have); multi-name
  `PendingSignalNames` ordering (the suggestion itself flags this as conditional on "if a
  deterministic ordering contract is intended" -- meta.md never states one, and after three
  fairness findings this session on exactly this class of unstated-behavior pinning, added only
  the ambiguity-free half of the suggestion instead: `Test_HasPendingSignal_UnknownName_ReturnsFalse`,
  which needs no ordering claim at all). Test count: 49 -> 52 (+3: CloseDraining-with-blocked-
  senders, Closed boundary check, HasPendingSignal-unknown-name). No solution.go changes this
  round. Re-validated end to end in a fresh worktree at BASE_COMMIT, 3x each mode: base 131/0, new
  52/0 every run; both patches apply and reverse cleanly.
- Attempt 17 (this session, Solution Quality FAIL + Warning description suggestions): Solution
  Quality re-flagged the exact ordering issue from round 14 (High), this time with a more precise
  reproduction that also explained why round 15's fix and its test were unfair: capacity-1
  channel, send 1, block a coroutine sending 2, `ReceiveNonBlocking()` consumes 1, then
  `SendNonblocking(3)` BEFORE resuming the blocked coroutine -- `Drain`/`PeekAll` returned [3, 2]
  even though 2 was already a currently obtainable blocked-send value before 3 ever arrived. Also
  flagged (Low) that `TryClose` is unrequested public API surface, unused by anything in the patch.
  The core tension from round 15 was resolved architecturally instead of picking a side again:
  round 14's `promoteSenders` fix enforced correct order by making a fresh send physically unable
  to claim capacity ahead of an older blocked sender (an invented atomic-reservation policy, which
  round 15's Test Fairness pass correctly rejected as unstated and conflicting with the pinned
  commit's existing accept-the-new-send behavior). This round's fix instead unifies the channel's
  internal representation: `internal/sync/channel.go`'s `c []T` buffer slice and `c.senders
  []*pendingSend[T]` queue were replaced with one arrival-ordered `c.queue []*queueItem[T]`
  (buffered or still-pending, tagged, always appended at the back on arrival). `trySend` still lets
  a fresh send claim free capacity immediately -- unchanged accept/reject behavior, so nothing
  about "does the new send succeed" changes -- but now every read path (`tryReceive`, `Peek`,
  `PeekN`, `PeekAll`, `Drain`) reads strictly from the front of this single queue regardless of
  whether the entry is a buffered value or a still-blocked sender, so true chronological arrival
  order is preserved automatically without pinning any capacity-reservation mechanism. `hasCapacity`
  now counts only buffered-tagged entries; drop-oldest eviction now scans for and evicts the oldest
  buffered-tagged entry specifically (never a still-pending one), matching the original semantics.
  Added `Test_ChannelDrain_PreservesArrivalOrder_AcrossAReceiveAndAnInterleavedSend`, reproducing
  the reviewer's exact scenario, including the assertion that `SendNonblocking(3)` still succeeds
  (so the test cannot be read as pinning a reservation policy the way round 15's version did) and
  that 2's `Send` only resolves once actually drained, not merely peeked. Mutation-confirmed:
  reverting `tryReceive` to buffer-first-then-pending priority (the shape of the original,
  pre-round-14 code) reproduces the exact failure this test catches. Also removed the unrequested
  `TryClose` method from both `internal/sync/channel.go`'s and `workflow/channel.go`'s `Channel[T]`
  interfaces and their implementations (confirmed unused anywhere else in the tree first). Took
  both Warning-level meta.md trims (redundant "or the remaining values and true otherwise" clause
  on `TryCloseDraining`; redundant "and return one combined slice" on `DrainAll`/`PeekAllChannels`).
  All 52 pre-existing new tests still pass unchanged against the rewritten channel internals (only
  1 new test added). Test count: 52 -> 53. 434 words, ASCII. Effective LOC (Counter-1) ~328.
  Re-validated end to end in a fresh worktree at BASE_COMMIT, 3x each mode: base 131/0, new 53/0
  every run; both patches apply and reverse cleanly.
- Attempt 18 (this session, Solution Quality FAIL, 1 High + 2 Medium): round 17's unified-queue
  redesign fixed the buffered/pending ordering across ONE resumed sender, but a sharper
  reproduction found the same class of bug still present for TWO senders: capacity-1 channel,
  buffer 1, block senders of 2 then 3, receive 1, execute only 2's coroutine. Its retry saw free
  capacity and (per round 17's `trySend`-then-`removeItem` sequencing) appended a brand new
  buffered entry for 2 at the queue tail and only then removed the original pending entry -- so
  the queue became [pending:3, buffered:2] instead of keeping 2 ahead of 3. Root cause: an
  already-queued sender's retry always went through the generic `trySend` (append-to-tail) path
  instead of resolving its OWN existing queue entry in place.
  (1) High, fixed: reworked `Send`'s retry loop so an item already in the queue is resolved via a
  new `tryResolvePending`, which either hands it straight to a waiting receiver (removing it, same
  as before) or flips its `buffered` field to `true` IN PLACE once there is capacity -- it is never
  removed and re-appended, so its position (and therefore its rank in arrival order) never moves.
  Added `Test_ChannelSend_ResumedSenderKeepsItsQueuePosition_AheadOfALaterSender`, reproducing the
  reviewer's exact two-sender scenario. Mutation-confirmed: reverting to the old
  trySend-then-removeItem sequencing reproduces the exact failure.
  (2) Medium, fixed: `internal/workflowstate/signalchannels.go`'s backlog replay used a blocking
  `c.Send(ctx, s)` per queued signal. Under the default OverflowBlock policy, if the backlog
  exceeds capacity, that blocking call yields the WORKFLOW'S OWN coroutine from inside
  `NewSignalChannel`, before the channel handle has even been returned to the caller -- nothing
  else can ever drain it to free room, so channel creation deadlocks permanently. Fixed by
  switching to `c.SendNonblocking(s)`, matching the already-established pattern for live signal
  delivery and matching meta.md's existing text ("materializing the backlog is itself subject to
  the channel's overflow policy" -- nonblocking delivery already respects the overflow policy
  without ever needing to block). No meta.md wording change needed; the description already
  described the correct behavior, only the implementation didn't match it. Added
  `Test_SignalBacklog_ExceedsCapacityWithDefaultBlockPolicy_MaterializesWithoutDeadlocking`.
  Mutation-confirmed: reverting to the blocking `Send` reproduces the platform's own deadlock
  detector firing ("No new events generated during workflow execution... workflow blocked?") inside
  the tester, exactly matching the reviewer's predicted failure mode.
  (3) Medium, fixed: `bufferedCount()` walked the entire mixed queue on every `hasCapacity()` call,
  making capacity checks (used by every `trySend`) quadratic in queue size for a long run of
  buffered sends. Replaced with an explicit `bufferedN int` field on `channel[T]`, incremented or
  decremented at every site that changes queue membership of a buffered item (`trySend`'s capacity
  and drop-oldest branches, `tryReceive`'s pop, `tryResolvePending`'s in-place flip, `removeItem`'s
  defensive cleanup) -- `hasCapacity()` and `Len()` are now O(1). No new test added for this one
  (a pure performance fix with no externally observable behavior difference); relied on the
  existing capacity-boundary tests (`Test_ChannelIsFull_...`, `Test_ChannelCap_...`,
  `Test_ChannelSendNonblocking_OnFullChannel_...`) passing unchanged to confirm no regression.
  Test count: 53 -> 55 (+2). Re-validated end to end in a fresh worktree at BASE_COMMIT, 3x each
  mode: base 131/0, new 55/0 every run; both patches apply and reverse cleanly. Effective LOC
  (Counter-1) ~346.
- Attempt 19 (this session, Test Fairness FAIL 1/55; 2 alignment Warnings): the flagged test was
  round 18's own deadlock regression,
  `Test_SignalBacklog_ExceedsCapacityWithDefaultBlockPolicy_MaterializesWithoutDeadlocking`. The
  underlying fix (backlog replay must use nonblocking delivery, or channel creation can deadlock)
  was a genuine bug independently confirmed by a Solution Quality pass last round, but meta.md
  never actually stated that backlog materialization is nonblocking -- it only said materialization
  is "subject to the channel's overflow policy," which is compatible with either a blocking or a
  nonblocking reading, so the test's exact no-deadlock/drop-two/keep-first assertions pinned an
  unstated author choice. Given this was a deliberate, load-bearing design decision (not an
  incidental implementation detail, and not an unrequested API the way round 9's TryClose was),
  resolved it the way round 13 (PendingSignalNames' return shape) and round 14 (Channel.Closed)
  were resolved: stated it explicitly in meta.md rather than weakening the test. The signal-channel
  paragraph now says replay "us[es] the same nonblocking delivery a live signal uses so replay
  never blocks channel creation" and that materialization is "subject to the channel's overflow
  policy exactly as a live delivery would be." Also picked up the alignment pass's other concrete,
  low-risk gap it flagged in the same paragraph: the default signal channel capacity (100) was
  never stated, yet existing tests rely on a small backlog fully replaying under it; added
  "omitting it uses a default capacity of 100." Declined the alignment pass's other Warning
  (documenting that Drain/SelectAll also exist at the internal/sync layer) -- this is the exact
  restate-the-internal-mirror suggestion round 7 already declined for the same reason (the fix for
  that ambiguity is testing the public workflow-level API directly, which the suite already does;
  restating internal/sync in the prompt would reopen exactly what round 4's Test Fairness FAIL
  required removing). Also took 2 of the round-18 coverage suggestions that are safe, direct
  extensions of already-stated text: (1) Peek/PeekN/PeekAll on a closed channel that still has
  buffered values, which meta.md's "return an empty result... whether or not it is closed" sentence
  already implies must remain visible when something IS available; (2) a live-signal (not backlog)
  OverflowDropOldest test, mirroring the existing live-signal OverflowBlock coverage with the
  already-stated policy swapped in. Declined the third suggestion (asserting TryCloseDraining's
  failure path is non-destructive) outright -- this is verbatim the exact pin round 15's Test
  Fairness FAIL already rejected two rounds ago; re-adding it would just reopen that finding.
  463 words, ASCII. Test count: 55 -> 57 (+2: closed-with-retained-values peek, live-signal
  drop-oldest). No solution.go changes this round. Re-validated end to end in a fresh worktree at
  BASE_COMMIT, 3x each mode: base 131/0, new 57/0 every run; both patches apply and reverse
  cleanly.
- Attempt 20 (this session, deliberate hardening rollback, user-directed): a batch of 5 Nova runs
  against the round-19 (57-test) suite came back 0/5 pass. All five agents independently converged
  on the same natural first-instinct architecture (a separate buffered slice + a separate blocked-
  senders list) and all five got caught by the same compounding cluster of ordering/lifecycle
  traps this session hardened into the suite over rounds 12-18. Per user instruction, no Orion/Vega
  runs will be spent confirming this further -- softened directly instead of waiting for a full
  10+-run solvability batch. Removed the two traps judged to be adding the most marginal difficulty
  per unit of fairness, both confirmed via the failure evidence to be compounding on top of traps
  that already force the correct architecture on their own:
  (1) `Test_ChannelSend_ResumedSenderKeepsItsQueuePosition_AheadOfALaterSender` (round 18's
  two-sender interleaved-resume case) -- the deepest, most narrow nuance in the whole ordering
  requirement (resuming one of TWO already-blocked senders must not let its retry jump behind the
  other). The simpler one-sender case
  (`Test_ChannelDrain_PreservesArrivalOrder_AcrossAReceiveAndAnInterleavedSend`, round 17) already
  forces the same "single arrival-ordered queue" architecture on its own and traces just as
  directly to the literal stated sentence ("in the order they became available"), so removing the
  two-sender case drops one layer of compounding difficulty without gutting the core requirement's
  own test coverage.
  (2) `Test_ChannelCloseDraining_WithBlockedSenders_ResolvesThemWithoutPanicking` (round 16's own
  advisory-suggestion addition, not a decisive-gate finding) -- meta.md never actually commits
  either way on whether `CloseDraining` must resolve blocked senders or may panic like a raw
  `Close()` does (the pre-existing, already-documented behavior it shares a namespace with); all 5
  agents assumed the panic-like reading, which is a reasonable inference from the repo's existing
  Close() semantics, not a mistake. Removing this test does not create any contradiction with
  meta.md (which was silent on this either way) and the reference solution's own `CloseDraining`
  (drain-then-close) still incidentally satisfies it without needing the test to require it.
  Neither change touched `internal/sync/channel.go` -- the reference solution keeps its more
  capable behavior on both fronts; only the corresponding pinning TESTS were removed, consistent
  with the CLAUDE.md project rule that difficulty is tuned via trap count, not by degrading the
  reference implementation. Test count: 57 -> 55. No meta.md changes needed (removing a test never
  requires touching the description). Re-validated end to end in a fresh worktree at BASE_COMMIT,
  3x each mode: base 131/0, new 55/0 every run; both patches apply and reverse cleanly. Docker
  validation still owed to the platform run for this problem specifically (this session's earlier
  attempts predate this workstation's 2026-08-25 Docker availability update; next validation pass
  should run `docker build`/`docker run` per the refreshed CLAUDE.md environment section instead of
  relying on static reasoning alone).
- Attempt 21 (this session, requirement-coverage check on the round-20/55-test suite: one real gap,
  6 advisory-only suggestions): the only non-advisory finding was that "omitting [signal capacity]
  uses exactly 100" (meta.md, round 19's own addition) was untested -- nothing distinguished a
  default of 100 from any other value above the tiny backlogs the existing tests use. Fixed by
  adding `Test_SignalChannel_OmittedCapacity_DefaultsTo100`
  (`tester/signal_channel_capacity_b7b95d_test.go`): creates a signal channel with no
  `WithSignalChannelCapacity` option and asserts `Cap() == 100` directly, mirroring the existing
  `Test_SignalChannel_ExplicitZeroCapacity_CreatesUnbufferedChannel`'s shape. No solution.go changes
  needed -- `NewSignalChannel`'s round-14 default-resolution logic already returns 100 correctly,
  this only closes a test-coverage gap. Declined all 6 advisory coverage suggestions (open-empty
  PeekN/PeekAll, SelectAll case-family mixing, additional negative-size values, the same default-
  signal-capacity gap already fixed above, CloseDraining-with-blocked-senders, and multi-name
  PendingSignalNames) since the check itself labeled them "advisory only -- these don't affect the
  check result," and per the standing user instruction to soften rather than add difficulty back
  (the CloseDraining-with-blocked-senders suggestion in particular is the exact test removed one
  round ago in the deliberate softening pass -- re-adding it would directly undo that).
  Test count: 55 -> 56. Environment note: this workstation's Go toolchain (previously at
  `~/sdk/go1.26/bin` per CLAUDE.md) was absent this round -- no `go` binary found anywhere on the
  system. Installed a fresh `go1.25.0` + `go-junit-report` under `/mnt/0844D3E544D3D392/toolchains/`
  (per the disk-space rule: never install toolchains on the root/home disk), confirmed working
  (~1.2G total, well within the 290G free on that partition). Re-validated end to end in a fresh
  worktree at BASE_COMMIT with the new toolchain, 3x each mode: base 131/0, new 56/0 every run; both
  patches apply and reverse cleanly. Docker validation is still owed to the platform run for this
  problem (unchanged from round 20's note).
- Attempt 22 (this session, Docker validation, no artifact changes): ran the submission's actual
  Dockerfile end to end for the first time this session, per this workstation's 2026-08-25 Docker
  availability update. Built a validation source tree in a fresh worktree at BASE_COMMIT with both
  test.patch and solution.patch applied, copied the submission's Dockerfile in unmodified, and
  `docker build`'d it (base image `olympus-base-go:latest`, `go mod download` + `go-junit-report`
  install + `go build ./...` all succeeded inside the container). Ran the built image as a
  container and executed `./test.sh new --output_path ...` and `./test.sh base --output_path ...`
  via `docker exec` (copying the resulting JUnit XML out with `docker cp` since the container has no
  bind mount), matching exactly what the platform invokes. Results: new 56/0, base 131/0 -- identical
  to the local (non-Docker) fresh-worktree numbers from round 21, confirming the Dockerfile's base
  image and build steps introduce no drift from local validation. Removed the built image and the
  scratch worktree afterward; no dangling layers left (`docker image prune` reclaimed 0B, the
  `olympus-base-go` base layers stay cached for the next validation pass, `/var/lib/docker` has 79G
  free so this is not a disk concern). Also found and cleaned up a redundant Go toolchain: round 21
  installed a fresh `go1.25.0` under `/mnt/0844D3E544D3D392/toolchains/` without checking for an
  existing one first; the user pointed out `Olympus/.toolchains/go` (dated 2025-08-08, from an
  earlier session) already had `go1.25.0` and `go-junit-report` in place. Deleted the redundant
  duplicate; future rounds in this problem should use `Olympus/.toolchains/go/bin/go` directly
  rather than reinstalling.
- Attempt 23 (this session, agent-runs/2 review + user-directed revert): a new batch (7 Nova + 1
  Orion, evaluator Nova) landed 0/8 against the round-21/22 (56-test) suite. 6 of 8 failures
  (5 Nova + the 1 Orion run) hit the same single-queue arrival-order requirement round 20
  deliberately kept as non-negotiable core coverage
  (`Test_ChannelDrain_PreservesArrivalOrder_AcrossAReceiveAndAnInterleavedSend` and/or
  `Test_ChannelSend_ResumingAfterCapacityOpens_RemovesStalePendingSender`) -- not touched, since it
  is the literal stated core feature, not a compounding nuance. One Nova run (Nova_Nova_3) was a
  total build failure (0/131 baseline too), agent-caused, no signal. The Orion run's own
  eval-result.json additionally surfaced a real compile-type mismatch: its `DroppedCount` returned
  `uint64` where the hidden tests assign to `int`, an unstated return type. Added "as an `int`" to
  both the `Channel.DroppedCount` and `workflow.SignalChannelDroppedCount` sentences in meta.md
  (469 words) on the reasoning that this was a real, generally-applicable gap (any solver picking
  `uint64` would hit the identical compile failure, not just Orion), matching this problem's
  established precedent for stating genuine unstated API shape explicitly (rounds 13/14/19).
  User then stated they will not run Orion anymore ("i feel it is broken") and asked whether
  anything had been changed because of the Orion result; confirmed the DroppedCount type edit was
  the only one, and was directed to undo it. Reverted both sentences in meta.md to their prior
  wording (word count back to 463, matching round 21/22's committed text exactly). No test or
  solution changes were made or need reverting -- the DroppedCount/SignalChannelDroppedCount
  reference implementation was never touched, only the meta.md wording round-tripped. The core
  ordering trap remains untouched throughout this round in either direction.
- Attempt 24 (this session, Solution Quality FAIL reported against agent-runs/2's own review pass):
  a review claimed no production implementation exists at all (no Drain, NewBufferedChannelWithPolicy,
  SelectAll, signal-capacity/replay changes anywhere in the tree) and separately asked to remove
  `test.sh` as "unrelated evaluator infrastructure." Both claims are directly contradicted by
  solution.patch, re-verified line-by-line this round: `NewBufferedChannelWithPolicy` (workflow/
  channel.go), `Drain`/`SelectAll` (both internal/sync/select.go and workflow/select.go), and the
  signalchannels.go capacity/nonblocking-replay fix are all present and were re-confirmed working via
  this session's own Docker build/run two rounds ago (new 56/0, base 131/0 with both patches applied).
  The review's own cited evidence describes the unmodified base-commit files, and test.sh is the
  CLAUDE.md-mandated deliverable format, not something a format-aware reviewer would ask to remove --
  both point to solution.patch simply not being applied for whatever generated this check (a platform-
  side submission issue, not a defect here). No code or meta.md changes made in response; flagged to
  the user to re-verify both patch files were actually attached before resubmitting this check.
- Attempt 25 (this session, user-directed, targeting a specific 100%-Nova-failure test): with Orion
  excluded per the user's standing decision (see Attempt 23), the 6 valid Nova runs in agent-runs/2
  still showed `Test_ChannelDrain_PreservesArrivalOrder_AcrossAReceiveAndAnInterleavedSend` failing in
  6/6 (100%), plus `Test_ChannelSend_ResumingAfterCapacityOpens_RemovesStalePendingSender` in 3/6. The
  user asked to "do something" about the 100%-failure test specifically. Judged this test fair and
  non-negotiable (it is the exact stated sentence "in the order they became available," already
  survived multiple Test Fairness passes, and is the one case round 20 deliberately kept over the
  two-sender variant as core coverage) rather than an unfair or over-narrow trap, so did not delete or
  weaken it. Every failing agent's own eval summary showed the SAME specific comprehension gap: they
  preserved arrival order in the easy cases but assumed a later send that resolves first (into newly
  freed capacity) also reports first -- not realizing an already-blocked sender's value counts as
  "available" from the moment it blocked, regardless of resolution order. Closed that gap by adding
  one clarifying sentence to meta.md's Drain paragraph stating the rule for exactly this edge case
  ("A value already held by a blocked sender became available before any send that arrives later, even
  if that later send is the one that ends up succeeding into newly freed capacity"), rather than
  describing an implementation approach -- consistent with this problem's established precedent
  (rounds 13/14/19) of stating a genuine, already-tested behavioral rule explicitly instead of touching
  the test or the solution. No test or solution changes; the reference implementation already satisfies
  this test and needed no changes. Word count: 463 -> 495 (still under the 500 hard cap, with only 5
  words of margin left -- worth trimming a redundant clause elsewhere if a future round needs more
  room). No patch regeneration needed since neither test.patch nor solution.patch changed.
- Attempt 26 (this session, Solution Quality FAIL, verified by direct reproduction before acting):
  a review claimed a High-severity duplicate-delivery bug (a blocked send already resolved by Drain
  gets re-delivered to a newly-blocked receiver on the sender's next Execute, because Send's retry
  loop calls tryResolvePending(item) before checking sentValue), a Low-severity misleading log
  message, and a suggestion to trim meta.md's default-signal-capacity sentence.
  Given the prior round's review turned out to be evaluating an unapplied solution.patch, did not
  trust the High claim without direct reproduction first: wrote the reviewer's exact scenario as a
  throwaway internal/sync test (unbuffered channel, block a sender on Send(7), Drain it, start a
  second coroutine blocked in Receive, then resume the sender) and ran it against the actual current
  channel.go. It does NOT reproduce -- `Send`'s loop checks `if sentValue` immediately after
  `cr.Yield()` returns, which is exactly where control resumes on the sender's next Execute() (the
  coroutine library's Execute() advances a goroutine from one Yield point to the next, one loop
  iteration per Execute() call), so the sender returns there and never reaches the top of the loop
  where tryResolvePending lives. Traced this precisely against coroutine.go's Execute/Yield
  implementation (channel-synchronized goroutine resume, not a replay-from-scratch model) to confirm
  why. Did not touch Send/tryResolvePending/removeItem; the throwaway test was deleted after
  confirming, not added to the suite (it does not test our own requirement, only refutes the
  review's specific claim).
  The Low finding was real and independent of the above: `internal/workflowstate/signalchannels.go`'s
  backlog-overflow warning hardcoded "oldest signals evicted" regardless of the channel's actual
  dropOldest policy -- under the default OverflowBlock policy a nonblocking send that finds no room
  loses the newest signal, not the oldest, so the message was factually wrong on that path. Fixed by
  branching the message on `dropOldest` (no test asserts this string, confirmed via grep, so no test
  changes needed).
  Declined the meta.md suggestion ("trim the default-capacity sentence, hidden tests don't assert
  the numeric default") -- both premises are false against this problem's actual current state:
  `Test_SignalChannel_OmittedCapacity_DefaultsTo100` (added round 21) does assert `Cap() == 100`
  directly, and the sentence itself exists specifically because round 19's Test Fairness FAIL
  required stating it explicitly (removing it now would reopen that exact finding). Combined with
  the disproven High claim, this is the second review in a row that appears to be evaluating a stale
  or mismatched submission state rather than the current artifacts; flagged to the user again.
  Rebuilt and re-ran 3x each mode: new 56/0, base 131/0, all clean. Regenerated solution.patch (only
  signalchannels.go changed; all 8 solution files confirmed present in the diff). Re-validated end to
  end in a fresh worktree at BASE_COMMIT: both patches apply and reverse cleanly, new 56/0, base
  131/0. test.patch unchanged (no test file touched this round).
  Also drafted and submitted a contest against the High duplicate-delivery finding on the platform,
  citing the reproduction above; contest is pending reviewer approval (verdict shows CONTESTED).
- Attempt 27 (this session, real FP Check output from agent-runs/3, four independent Nova runs plus
  one judge-dissent genuine pass): unlike Attempts 24/26, this was actual solver-agent evaluation
  data, not a Solution Quality review of our own artifacts, so it gets a different response --
  strengthen the hidden suite, not dispute anything. Two genuine test-coverage gaps, each confirmed
  by 2+ independent adjudicated Nova runs:
  (1) CloseDraining with a value held by a blocked sender: several candidate solutions check for
  blocked senders and panic before draining, instead of draining first (which resolves the sender)
  then closing. Verified our reference already does this correctly (`CloseDraining` calls `Drain()`
  before `Close()`, and `Drain` removes the pending item and calls its `notify` before `Close` ever
  checks `hasPending`), so this is a pure test-coverage gap, not a solution defect. Added
  `Test_ChannelCloseDraining_IncludesBlockedSender_ClosesWithoutPanicking` (buffered value + blocked
  sender together, matching the existing TryCloseDraining blocked-sender test's shape), confirmed it
  passes instantly against the reference.
  (2) SelectAll handling two cases that both looked ready off one shared value: some candidates
  snapshot every case's Ready() up front, then handle all of them unconditionally, so the second case
  ends up calling a blocking Receive on a value the first case already consumed. Verified our
  reference's SelectAll interleaves Ready()+Handle() per case within a single loop pass (no upfront
  snapshot), so a case's Ready() call always sees the previous case's mutation -- correct by
  construction. Added `Test_SelectAll_ConsumedValueDoesNotMakeAnotherCaseReady` (two Receive cases on
  one channel with exactly one buffered value; asserts the coroutine finishes with handled=1 rather
  than getting stuck waiting on the second case), confirmed it passes instantly against the reference.
  No meta.md changes -- both new tests trace to requirements already stated (CloseDraining's "returns
  any values still present" already covers blocked-sender values via Drain's own definition; SelectAll
  "handles every ready case" already implies rechecking readiness as cases are handled). Updated
  test.sh's NEW_SYNC_TESTS array (34 -> 36 sync-package entries) and regenerated test.patch; rebuilt
  and ran 3x each mode (new 58/0, base 131/0, all clean, deterministic), then re-validated end to end
  in a fresh worktree at BASE_COMMIT: both patches apply and reverse cleanly, new 58/0, base 131/0.
  solution.patch unchanged and confirmed byte-identical to the worktree diff (no solution files
  touched this round).

## Attempt 28 -- test.sh bug: single-package panic was zeroing out unrelated packages' results

User flagged "the last 3 agents failed in all the tests" after agent-runs/4 (Nova_Nova_1/2/3, the
first batch run against the Attempt-27 test suite) all showed `tests="58" failures="58"` in their
JUnit output. Investigated instead of assuming the agents were just uniformly bad.

Root cause confirmed by reproducing Nova_Nova_1's actual submitted solution-patch.patch locally
against our test.patch: its `CloseDraining` panics (real unrecovered Go panic, not a testify
assertion) on the blocked-sender test, and an unrecovered panic in a Go test crashes that package's
whole test binary, so every sync test after the crash point in file/declaration order never runs.
`internal/sync`, `tester`, and `workflow` are three separate `go test` binaries (three separate
packages) -- only `internal/sync`'s binary crashed. The raw output showed `tester` (13/13) and
`workflow` (9/9) both ran to completion and passed cleanly, and `internal/sync` itself had 20 real
passes and only 2 real failures before the crash. But the old `synthesize_build_failure_xml`
fallback fired on any global testcase-count mismatch and replaced the *entire* 58-test document with
synthetic failures, discarding all 42 genuine passes across all three packages. This is a fairness/
diagnostic bug, not a solvability problem: the platform-visible JUnit was misrepresenting "42/58
correct, 2 genuine misses" as "0/58, total failure," and reviewers or difficulty-calibration
decisions reading that XML would draw the wrong conclusion entirely.

Fixed by replacing that fallback with `reconcile_package` / `reconcile_junit_xml`: per package,
compare the real go-junit-report output against that package's expected-test-name list. If none of
a package's expected tests produced a real result (full compile failure, or crash before the first
expected test ran), synthesize the whole suite fresh (unchanged from before). If some tests are
missing but others have real results, keep every real result (pass or fail) untouched and only
append synthetic failures for the specific missing names, fixing up the suite's `tests`/`failures`
counts to match. No new dependency (python3 is not guaranteed present in the `olympus-base-go`
image) -- implemented in bash/awk/grep/sed only, matching the existing script's toolset.

Verified against all three real agent-runs/4 solution-patch.patch files locally: each now reports
accurately (sync 36 tests/15-16 failures with 20-21 genuine passes preserved, tester 13/0, workflow
9/0 -- 42-43/58 actually correct, not 0/58), and `test.sh` still exits 1 overall since real bugs
remain (no change to the pass/fail gate itself). Verified no regression on three scenarios: (1) the
reference solution still reports 58/0 with the fix, 3x deterministic, matching pre-fix behavior; (2)
a full compile-failure injected into internal/sync still produces full synthetic failure across all
three packages (correct, since tester/workflow import internal/sync and fail to build transitively
too -- not a case the fix needed to change); (3) base mode is untouched (only the `new` mode path
calls the new reconciliation). Regenerated test.patch (test.sh only changed; the 5 test files and
their 58 test names are unchanged from Attempt 27). solution.patch confirmed byte-identical --
unaffected, this was purely a grading-harness bug. Full round-trip in a fresh worktree at
BASE_COMMIT: both patches apply and reverse cleanly, new 58/0 and base 131/131 3x deterministic.

## Attempt 29 -- agent-runs/5 (4 Nova runs): one adjudicator caught a real capacity-accounting FP gap; closed it plus two advisory coverage gaps

Reviewed a fresh 4-run batch. Nova_Nova_1/2/4 failed on the already-known CloseDraining-panics-on-
blocked-sender trap (expected, nothing new). Nova_Nova_3 was the interesting one: it reported
baseline 131/131 and new 58/58 all passing, verdict FAIL_MISSED_REQUIREMENT anyway, because the
adjudicator's static review found a real bug the test suite did not exercise: their `releaseSender`
path sets a `released` flag on a resumed blocked sender but never increments their buffered-count
equivalent, so `Len`/`IsFull`/subsequent capacity checks stay wrong after a blocked sender resumes
into freed capacity -- a capacity-1 channel could silently accept a second value. This is exactly the
class of thing the FP Check gate exists to catch: a genuine implementation defect that the existing
58 tests let through as a full pass. Traced it against `Test_ChannelSend_ResumingAfterCapacityOpens_
RemovesStalePendingSender`: that test resumes a blocked sender via a receive and checks `PeekAll` /
`TryCloseDraining`, both of which only walk the queue and never depend on the buffered-count
bookkeeping, so the bug was invisible to it.

Also had a pasted platform FP/coverage report open at the same time flagging two more, separately
verified real discriminating gaps in the current test file (not this run's adjudicator output): (1)
`PeekN`/`PeekAll` only had `ClosedEmpty` cases, never an open/fresh-channel-empty case, unlike `Peek`
which has both -- a shortcut could special-case "closed" and mishandle a merely-empty open channel
for the two bulk methods specifically; (2) `Test_PendingSignalNames_ReflectsUncreatedChannels` only
ever queued one pending name, so a hardcoded/one-slot backing store would pass it. (The same pasted
report's note about meta.md pinning a numeric signal-channel-capacity default was checked against the
actual test file and found stale/incorrect for the current suite: `Test_SignalChannel_
OmittedCapacity_DefaultsTo100` already asserts the literal 100, so the description stating it is
consistent with a real test, not an unfair pin -- left unchanged.)

Fixed all three by editing the worktree test files directly, not by hand-patching the .patch: added
`Test_ChannelSend_ResumedSender_OccupiesCapacity` right after the existing resuming-sender test in
`internal/sync/channel_drain_b7b95d_test.go` (resumes a blocked sender into a capacity-1 channel's
one slot, then asserts `IsFull()` is true and a further `SendNonblocking` fails with `DroppedCount`
incrementing); added `Test_ChannelPeekN_OpenEmpty_ReturnsEmpty` and `Test_ChannelPeekAll_
OpenEmpty_ReturnsEmpty` beside their ClosedEmpty siblings; reworked `Test_PendingSignalNames_
ReflectsUncreatedChannels` to queue two distinct uncreated names, assert both appear via
`PendingSignalNames`/`HasPendingSignal`, create a channel for one, then assert only the other still
appears -- used `require.ElementsMatch` rather than a fixed-order slice, since meta.md never states
an ordering guarantee and the reference implementation's own comment says names are sorted only to
avoid exposing Go's non-deterministic map order, which is an implementation choice, not a stated
requirement. sync went from 36 to 39 new tests; tester and workflow test counts unchanged (58 -> 61
total). Registered all three new names in `test.sh`'s `NEW_SYNC_TESTS` array.

First regeneration attempt of test.patch silently picked up stale staged content (`git status` showed
`AM` on both edited test files -- the index still held the pre-edit version because the earlier
Attempt-28 session had staged them once and my new Edit calls only touched the working tree). Caught
it because the new `Test_ChannelSend_ResumedSender_OccupiesCapacity` never appeared in a scratch
round-trip's `go test -v` output at all, not even a RUN line, despite `test.sh`'s array already
naming it -- traced to the missing `git add` before diffing. Re-ran `git add` on both files and
regenerated; confirmed via `grep -c` on the three new test names against test.patch before proceeding
further.

Verified against the real Nova_Nova_3 solution-patch.patch in a fresh worktree, 3x: `Test_
ChannelSend_ResumedSender_OccupiesCapacity` now fails deterministically and specifically (`Should be
true` / "the resumed sender's value now occupies the channel's only buffered slot"), sync reports
39/1 with everything else passing, no crash, no other collateral failures -- confirms the new test is
both discriminating and precisely targeted at the one real defect, not a broad regression. Reference
solution re-verified 3x on both base (131/0) and new (61/0) modes, byte-for-byte matching pre-Attempt-
29 pass counts on the pre-existing 58. Fresh-worktree round-trip: test.patch and solution.patch both
apply and reverse cleanly against BASE_COMMIT; test.sh keeps its 100755 mode; no `shipd`/`datacurve`
markers in any test file.

## Attempt 30 -- Solution Quality FAIL: real scheduler-progress bug in the Drain Select case, plus 5 coverage gaps and a pinned-detail softening

Platform returned a Solution Quality verdict of FAIL (Comprehensiveness 1/3, Code Quality 2/3) on the
reference solution. Both cited issues were verified against the actual code and both were real.

### HIGH -- `channelDrainCase.Handle` never marked scheduler progress (real deadlock)

Confirmed by reading the code, not by trusting the report. `internal/sync/scheduler.go:40-46` stops the
whole `Execute` loop once every coroutine reports `Progress() == false`. Every other path that consumes
a value marks progress: `channelReceiveCase.Handle` delegates to `Receive(ctx)`, which calls
`cr.MadeProgress()` after a successful `tryReceive`; `Send` does the same in three places. The new
`channelDrainCase.Handle` called `cdc.c.Drain()` and went straight to the user handler.

`Drain()` -> `tryReceive()` calls `item.notify()` on each consumed pending item, so draining DOES
unblock every coroutine that was blocked in `Send`. Those coroutines are then runnable but still
yielded, and they need one more scheduler pass to return from `Send`. Without a progress mark the
scheduler concludes everything is blocked and returns, so the resumed senders never run. The reviewer's
repro is ordinary two-coroutine workflow code, not a degenerate input.

Fix in `internal/sync/selector.go`: capture the drain result, call `getCoState(ctx).MadeProgress()`,
then invoke the handler. Marking unconditionally is correct and matches `Receive` exactly, because
`Ready()` is `canReceive()`, which is true precisely when `Receive` would have returned immediately
(including the closed-channel sentinel).

### LOW -- `WithSignalChannelCapacity` doc comment contradicted the implementation

The comment said the overflow policy decides whether materializing a backlog "waits for room or evicts
older signals". Replay uses `SendNonblocking` and never waits; meta.md explicitly requires that. Comment
rewritten to say the backlog never waits, and that the policy decides whether the signals that do not
fit are dropped (`OverflowBlock`) or evict older ones (`OverflowDropOldest`).

### Regression test for the HIGH bug (this is the important part)

The bug survived 5 batches because nothing exercised a drain-then-wait sequence across two coroutines.
Added `Test_SelectDrainCase_ResumingBlockedSender_LetsSchedulerRunIt`: a real `Scheduler` with a sender
coroutine blocked in `Send` on an unbuffered channel that then sends to `done`, and a second coroutine
that drains via `Select` and then receives from `done`.

Trap-proof: with the `MadeProgress()` line removed the test fails on the exact intended assertion
("draining a blocked sender must let the scheduler resume it so its Send returns"), and it fails
CLEANLY in 0.00s rather than hanging -- `Scheduler.Execute` returns as soon as it believes everything is
blocked, so there is no suite-timeout or package-crash collateral. Restored and re-verified passing.

### Coverage suggestions -- all 5 verified against the current test.patch and closed

- Drain Select case not-ready behavior: added `Test_SelectDrainCase_OpenEmptyChannel_YieldsUntilValueArrives`
  (an always-ready Drain case passed the three existing ready-state tests).
- SelectAll across heterogeneous case kinds: added `Test_SelectAll_MixedCaseKinds_HandledInArgumentOrder`
  (Drain + Send + Await, asserting handling order and count; the existing ordering tests used only Receive).
- Negative-size class: extended the existing panic test with `-7` / `OverflowDropOldest` so a constructor
  special-cased on `-1` cannot pass. No new test.sh entry.
- Multi-channel helpers with blocked senders: added
  `Test_WorkflowDrainAllAndPeekAllChannels_IncludeBlockedSenders` -- an unbuffered channel with a blocked
  sender concatenated ahead of a buffered one, so each helper must really call the per-channel method
  rather than read buffered length.
- IsFull after capacity is freed: extended `Test_ChannelIsFull_ReportsBufferAndUnbufferedState` with a
  receive-then-assert-not-full step, catching a sticky-fullness implementation. No new test.sh entry.

### Flakiness note acted on

`Test_ChannelDrain_ClosedEmpty_ReturnsEmptyWithoutHanging` was flagged `timing` (goroutine plus
`time.After(2s)`). The goroutine is load-bearing -- it converts a hang into a test failure instead of a
package-wide timeout crash -- so it stays, but the bound went 2s -> 30s. That is a ~10^10 margin over a
nanosecond-scale pure call, which removes the scheduler/load-delay risk without changing semantics. It
is the only timing construct in any of the four new test files (verified by grep).

### Pinned implementation detail softened (user reaffirmed)

In Attempt 29 I checked the report's claim that the hidden tests "do not assert the numeric default"
and found it factually wrong for the current suite, so I left meta.md alone. The user reaffirmed the
request, so it is now actioned as a decision rather than re-argued.

Verified first that `100` really is a pre-existing repo value: base `signalchannels.go` creates signal
channels with `sync.NewBufferedChannel[T](100)`. So naming it in the description pinned a number the
solver can just read out of the code. meta.md now says "omitting it uses the existing default capacity",
and `Test_SignalChannel_OmittedCapacity_DefaultsTo100` became
`Test_SignalChannel_OmittedCapacity_UsesBufferedDefault`, asserting `cap > 0` instead of `== 100`.

No discriminating power was lost. The actual trap here is the `capacitySet` flag -- a naive
implementation treats `capacity == 0` as "unset" and breaks an explicit `WithSignalChannelCapacity(0)`.
That trap is fully captured by the pair (explicit 0 stays 0) + (omitted is buffered); the literal 100
was contributing nothing to it. Description and tests are now aligned in the soft direction rather than
the pinned one.

### Validation

- New-mode 65/0 and base-mode 262/0, 3x each, byte-identical every run (mandatory flakiness gate).
- Trap-proof on the new regression test: fails on the intended assertion with the fix removed, passes
  with it restored.
- Fresh-worktree round-trip from BASE_COMMIT: test.patch alone -> base 0 failures, new 65/65 failures
  (package does not compile without the solution, as intended); + solution.patch -> new 65/0, base 0
  failures; solution.patch reverses cleanly.
- `go vet -tags=channeldrain` clean across all three packages.
- Patches ASCII/LF; test.sh retains `new file mode 100755`; no `shipd`/`datacurve` markers.
- solution.patch human-effective LOC 271 (floor is 200; the hook's 275 line is its own design-buffer
  target, not the gate). meta.md body 494 words, under the 500 cap, ASCII, zero em dashes.

Test count 61 -> 65. Files touched by solution.patch unchanged at 8.

## Attempt 31 -- Solution Quality FAIL: SelectAll dropped all but the last Default case

Second consecutive Solution Quality FAIL, this time Comprehensiveness 1/3 with Code Quality 3/3 (the
Attempt 30 code-quality fix to the `WithSignalChannelCapacity` comment took). Verified against the
actual code before acting; the claim is correct.

### The defect

`SelectAll` collected deferred defaults into a single `deferredDefault SelectCase` variable, so each
Default in the list overwrote the previous one, and the fallback branch ran that one handler and
returned a hardcoded `1`. For `SelectAll(ctx, Default(a), Default(b))` both cases are ready
(`defaultCase.Ready()` is unconditionally true) but only `b` ran, and the count was 1 rather than 2.
`workflow.SelectAll` is a straight delegation to `sync.SelectAll`, so the same bug was visible at the
public layer.

This contradicts the description's own sentence: "handles every ready case in one call, in the order
the cases were given, and returns how many cases it handled."

### Fix chosen, and why not the other one

The reviewer offered two acceptable resolutions: handle every default in order, or explicitly reject
multiple defaults. Took the first.

Rejecting multiple defaults would need a new meta.md sentence to be a fair requirement, and meta.md is
at 494 body words against a 500 hard cap -- no room. Handling every default in order needs NO
description change at all, because it is just the literal composition of two sentences already in the
prompt: every ready case is handled in given order, and Default cases are the ones deferred until
nothing else was ready. So the fix makes the code match the existing contract instead of amending the
contract to match the code.

`deferredDefault SelectCase` became `deferredDefaults []SelectCase`, appended in input order, and the
fallback branch now runs the whole slice in order and returns `len(deferredDefaults)`. Doc comments on
both `sync.SelectAll` and `workflow.SelectAll` updated from "A Default case ... only fires" to "Default
cases ... fire only if none of the other cases were ready, and are then handled in that same order".

### Regression test

Added `Test_SelectAll_MultipleDefaults_AllFireInGivenOrder`, deliberately two-phase so it pins both
halves of the contract and cannot be satisfied by a naive "just always run all the defaults" fix:

- Phase 1, empty channel: `Default(first), Receive(empty), Default(second)` must produce
  `["first","second"]` and return 2.
- Phase 2, channel with a value: the same three cases must produce `["receive"]` and return 1, proving
  no Default fires while any other case was ready.

Trap-proof: reverting `SelectAll` to the last-default-wins behavior fails phase 1 on the exact intended
assertion (expected 2, actual 1, "every Default case is ready, so every one of them counts as
handled"). Restored and re-verified passing.

Note on the trap-proof run: the first attempt reported `Terminated` at a 200s timeout. That was the
cold Go rebuild after editing `selector.go`, not a hang -- warming the build first and re-running gave
the clean 0.005s failure above. Worth remembering, since a `Terminated` here reads exactly like a
deadlock and would have been easy to misdiagnose as one.

### Validation

- New-mode 66/0 and base-mode 262/0, 3x each, byte-identical every run.
- Trap-proof confirmed on the new test (fails with the old behavior, passes with the fix).
- Fresh-worktree round-trip from BASE_COMMIT: test.patch alone -> base 0 failures, new 66/66 failures;
  + solution.patch -> new 66/0, base 0 failures; solution.patch reverses cleanly.
- Patches ASCII/LF; test.sh retains `new file mode 100755`; no `shipd`/`datacurve` markers.
- solution.patch human-effective LOC 272 (floor 200; the hook's 275 line is its own design buffer, not
  the gate). Files touched by solution.patch unchanged at 8.

Test count 65 -> 66. meta.md untouched this round.

## Attempt 32 -- Test Quality FAIL: the Attempt 31 multi-default test pinned an unstated policy

Test Quality returned FAIL, 1 of 66 unfair. The single flagged test was
`Test_SelectAll_MultipleDefaults_AllFireInGivenOrder` -- the test I added last round to satisfy the
Attempt 31 Solution Quality FAIL. The other 65 were called fair and grounded, with no suite-wide timing
or environment issue.

### The two reviewers were both right, and that is the actual lesson

Solution Quality (Attempt 31) said the code contradicted "handles every ready case in one call" because
`SelectAll` ran only the last Default. Test Quality now says the prompt never specified what multiple
Defaults do, that the singular phrasing "A `Default` case among them only fires if none of the others
were ready" can literally point the other way, and that ordinary `Select`'s first-ready behavior at
`internal/sync/selector.go:42-47` supports a reasonable one-default implementation.

Both are correct. Fixing the CODE to satisfy reviewer A created an untested-then-tested requirement
that reviewer B correctly called ungrounded. The gap was never the code or the test in isolation -- it
was that the prompt did not settle the policy.

Resolution: state the policy, do not drop it. Dropping the test would leave the solution implementing a
multi-default behavior that nothing documents and nothing checks, which just relocates the same hole.

### meta.md change (the real fix)

"A `Default` case among them only fires if none of the others were ready."
-> "Every `Default` case given fires, in that same order, only if none of the others were ready."

Plus 3 words, 494 -> 497 body words against the 500 hard cap, still ASCII with zero em dashes. Chose a
REPHRASE of the existing sentence rather than an added sentence precisely because of the cap. Composed
with the sentence before it ("handles every ready case in one call, in the order the cases were given,
and returns how many cases it handled"), the multi-default policy is now explicit: all of them fire, in
order, and all of them count.

### Test split (the reviewer asked for this explicitly)

`Test_SelectAll_MultipleDefaults_AllFireInGivenOrder` carried two scenarios. The reviewer called the
ready-nondefault half "explicit and fair" and only the all-defaults co-assertion ungrounded, and asked
for a split. Done:

- `Test_SelectAll_MultipleDefaults_AllFireInGivenOrder` -- empty channel, two defaults, expects
  `["first","second"]` and 2.
- `Test_SelectAll_MultipleDefaults_NoneFireWhenAnotherCaseIsReady` -- ready channel, same three cases,
  expects `["receive"]` and 1.

The split is validated as a real separation, not cosmetic: against the reverted last-default-wins
implementation ONLY `AllFireInGivenOrder` fails, while `NoneFireWhenAnotherCaseIsReady` passes either
way. Each test now depends on exactly one policy.

Also renamed the leftover `order2`/`handled2`/`cr2` locals in the extracted test back to
`order`/`handled`/`cr` to match the rest of the file.

### Deliberately NOT changed

The 30-second timeout in `Test_ChannelDrain_ClosedEmpty_ReturnsEmptyWithoutHanging` was noted as "tagged
for timing sensitivity" but was NOT listed as unfair -- the reviewer explicitly cleared the suite of
timing/environment problems and confirmed the tester's millisecond delays use workflow time, not wall
clock. The goroutine there is load-bearing (it converts a hang into a clean test failure instead of a
package-wide timeout crash), so it stays at 30s. Two review rounds have now passed it on fairness; not
churning it.

### Validation

- New-mode 67/0 and base-mode 262/0, 3x each, byte-identical every run.
- Trap-proof: reverted implementation fails only `AllFireInGivenOrder`, on the intended assertion.
- Fresh-worktree round-trip from BASE_COMMIT: test.patch alone -> base 0 failures, new 67/67 failures;
  + solution.patch -> new 67/0, base 0 failures; solution.patch reverses cleanly.
- Patches ASCII/LF; test.sh retains `new file mode 100755`; no `shipd`/`datacurve` markers.
- solution.patch unchanged this round (272 human-effective LOC, 8 files).

Test count 66 -> 67. Only meta.md and test.patch changed.

## Attempt 33 -- Solution Quality FAIL: direct-Drain deadlock (reviewer's diagnosis right, their proposed FIX provably wrong) + prealloc lint

Third consecutive Solution Quality FAIL. Comprehensiveness 1/3, Code Quality 1/3. Both issues real, but
the high-severity one needed a different fix than the reviewer proposed, and I only know that because I
tested it instead of implementing it on trust.

### HIGH -- direct `Drain()` never wakes the scheduler

Attempt 30 fixed this for the `Select` Drain case only. The reviewer correctly points out that
`Drain()`, `DrainAll`, and `CloseDraining` called directly have the same obligation and do not meet it.
Reproduced from scratch with a `Scheduler`, a sender coroutine blocked in `Send`, and a second
coroutine that calls `c.Drain()` then `done.Receive(ctx)`: the sender's value is taken, `sentValue` is
set, and both coroutines report no progress, so `Scheduler.Execute` returns with the workflow stalled.
Confirmed failing before any change.

### The reviewer's suggested fix does NOT work, and I verified that empirically

They proposed capturing the sending coroutine state in `queueItem.notify` and calling
`cr.MadeProgress()` there. Applied exactly that, alone: the repro still fails.

Reason, from reading `coroutine.go` and `scheduler.go`: `Scheduler.Execute` reads each coroutine's
`Progress()` immediately after that coroutine's own `Execute()` returns, and `coState.Execute()` calls
`ResetProgress()` at its start. In the reviewer's own scenario the sender is created first, so its
`Progress()` is read at index 0 BEFORE the drainer at index 1 runs and fires the notify. Setting the
sender's flag afterward is never read again -- the pass ends with `allBlocked` still true.

The invariant the working paths follow is that the CONSUMER marks its own progress (`Receive` does
exactly this), and `Drain()` has no ctx, so it cannot.

### Fix actually shipped: notify mark PLUS an ordering-tolerant scheduler

Two coordinated changes, and the trap-proof below shows BOTH are required:

1. `internal/sync/channel.go`: `notify` now also calls `cr.MadeProgress()` (the reviewer's half).
2. `internal/sync/scheduler.go`: after an inner pass concludes `allBlocked`, take a second look across
   all coroutines for a progress flag set during that pass. A coroutine can be credited with progress
   by a LATER coroutine in the same pass, which the single-read loop structurally cannot see.

### The option I rejected, and why

The architecturally "pure" fix is to give `Drain` a ctx so the drainer marks its own progress, matching
`Receive(ctx)` / `Send(ctx, v)`. Measured the blast radius first: ~41 test call sites plus the `Channel`
interface in two packages, `DrainAll`, `CloseDraining`, `TryCloseDraining`.

Rejected it for a solvability reason, not an effort one. meta.md never states signatures, so a
ctx-taking `Drain` would be an unstated API-SHAPE requirement: an agent that implements `Drain()`
without ctx fails to COMPILE against the hidden tests. That is a non-behavioral trap that could take
the batch to 0%. The scheduler fix keeps `Drain()`'s signature, so no meta.md change and no shape trap.

### Regression test

Added `Test_ChannelDrain_DirectDrain_ResumesBlockedSenderUnderScheduler`, the repro promoted to a real
test. Fairness: meta.md already says Drain "removes and returns ... values held by coroutines currently
blocked sending to the channel" -- if the sender never returns from `Send`, its value was not really
taken. The Attempt 30 Select-path analogue asserts the same thing and was explicitly cleared as fair in
the Attempt 32 Test Quality review (65 of 66 fair, only the multi-default test flagged).

Why this survived five batches: the existing `Test_ChannelDrain_IncludesBlockedSenders_InOrder` drives
`crA.Execute()` / `crB.Execute()` BY HAND and never constructs a `Scheduler`, so it could never observe
a progress-accounting bug. Lesson: a hand-driven coroutine test does not cover scheduler lifecycle.

Trap-proof, three ways: passes with both halves; FAILS with the notify mark removed; FAILS with the
scheduler re-scan removed. That is the direct evidence that the reviewer's single-half fix is
insufficient.

### Code Quality -- prealloc

`.golangci.yml:15` does enable `prealloc`, with no exclusion for `internal/sync`. Fixed
`deferredDefaults` in `SelectAll` to `make([]SelectCase, 0, len(cases))`. Swept the rest of the patch
for the same pattern and found two MORE the reviewer did not cite: `DrainAll` and `PeekAllChannels` in
`workflow/channel.go` both declared `var values []T` and appended inside a range loop. Fixed both --
the complaint was that `make lint` cannot pass, so fixing only the cited site would not have satisfied
it. `golangci-lint` is not installed on this workstation, so this is a config-read fix, not a
lint-run-verified one.

Side effect checked: those two now return an empty non-nil slice instead of nil for zero channels. All
assertions on them use `require.Empty` or compare non-empty slices, so nothing changed.

### Validation

- New-mode 68/0 and base-mode 262/0, 3x each, byte-identical every run.
- Broad regression sweep after the scheduler change (it is shared machinery):
  `./internal/... ./workflow/... ./tester/... ./client/...` all ok, including `workflow/executor`.
- Fresh-worktree round-trip: test.patch alone -> base 0 failures, new 68/68 failures; + solution.patch
  -> new 68/0, base 0 failures, broad sweep clean; solution.patch reverses cleanly.
- Patches ASCII/LF; test.sh retains `new file mode 100755`; no `shipd`/`datacurve` markers.
- solution.patch human-effective LOC 277 (was 272), now 9 files (added `internal/sync/scheduler.go`).

Test count 67 -> 68. meta.md untouched this round.

## Attempt 34 -- Test coverage: 4 advisory suggestions, all closed with mutation proof; one partially reverses Attempt 30

No unfair tests this round -- the first clean fairness result since the multi-default problem. Six
requirements came back "partial" with four advisory coverage suggestions. Closed all four.

Three of the four were extensions to EXISTING tests rather than new test functions, because each adds a
case to the SAME requirement rather than a new policy. That is the distinction the Attempt 32 reviewer
drew when demanding a split: splitting matters when one test pins two independent policies, not when it
covers more of one. No test.sh churn for those three.

### The four

1. **PeekN zero limit** (extends `Test_ChannelPeekN_ReturnsUpToNAvailable`). Asserts `PeekN(0)` and
   `PeekN(-1)` are empty on a NONEMPTY channel, and the trailing Drain still returns all three values so
   the peek is proven non-consuming.
2. **Exact omitted signal capacity** (`Test_SignalChannel_OmittedCapacity_UsesBufferedDefault`).
   Assertion strengthened from `Cap() > 0` back to `== 100`. See the conflict note below.
3. **SendAllNonblocking against pre-existing occupancy** (extends
   `Test_ChannelSendAllNonblocking_StopsAtFirstThatDoesNotFit`). Capacity-3 channel already holding two
   values, batch of three: exactly one is sent, exactly one is counted dropped (proving later inputs are
   not attempted), and the channel ends `[1 2 3]`.
4. **IsFull across a multi-slot buffer** (extends `Test_ChannelIsFull_ReportsBufferAndUnbufferedState`).
   Capacity raised 1 -> 3 and walked through empty, one-of-three, two-of-three, exactly-full, then
   freed-one. The old capacity-1 test could not distinguish "full" from "nonempty" at all.

### Mutation proof (each test vs the exact shortcut the reviewer named)

Every one of the four was verified to FAIL against the specific cheat it is supposed to block:

- nonpositive `n` treated as PeekAll -> `Test_ChannelPeekN_ReturnsUpToNAvailable` FAILS.
- `IsFull` returns `len(queue) > 0` -> `Test_ChannelIsFull_ReportsBufferAndUnbufferedState` FAILS.
- `SendAllNonblocking` allowance hardcoded to constructor capacity, ignoring occupancy ->
  `Test_ChannelSendAllNonblocking_StopsAtFirstThatDoesNotFit` FAILS.
- `DefaultSignalChannelCapacity` silently changed 100 -> 1 ->
  `Test_SignalChannel_OmittedCapacity_UsesBufferedDefault` FAILS.

All four restored and re-verified passing afterward.

### Conflict note: this partially reverses Attempt 30, and that is correct

Attempt 30 acted on a user-reaffirmed instruction to stop pinning the default capacity, and I changed
BOTH meta.md ("a default capacity of 100" -> "the existing default capacity") AND the test
(`== 100` -> `> 0`). This round's reviewer asks for the numeric assertion back, tagged
**Repo-discoverable**, on the grounds that `Cap() > 0` lets an implementation silently change the
established default to 1.

These are reconcilable, and the resolution is to split the two halves:

- **meta.md stays soft.** The original instruction was explicitly about the DESCRIPTION pinning an
  implementation detail the solver can read out of the code ("Trim or soften this ..."). That wording is
  unchanged at "the existing default capacity".
- **The test asserts 100 again.** Changing the test was my own extension of that instruction, not part
  of it. Asserting the repo's real existing default is exactly what "the existing default capacity"
  MEANS, and it is a legitimate repo-discoverable requirement (the base repo creates signal channels
  with `sync.NewBufferedChannel[T](100)`), which sits inside the <=1 codebase-inferable allowance.

Net: description does not pin the number, tests do. Both reviewers satisfied without contradiction.

### Validation

- New-mode 68/0 and base-mode 262/0, 3x each, byte-identical every run.
- Mutation proof on all four new assertions (above).
- Fresh-worktree round-trip: test.patch alone -> base 0 failures, new 68/68 failures; + solution.patch
  -> new 68/0, base 0 failures; broad sweep across `./internal/... ./workflow/... ./tester/...` clean;
  solution.patch reverses cleanly.
- Patches ASCII/LF; test.sh retains `new file mode 100755`; no `shipd`/`datacurve` markers.
- solution.patch unchanged this round (277 human-effective LOC, 9 files). meta.md unchanged (497 body
  words). Test count stays 68 -- all four additions extended existing tests except the capacity
  assertion, which was an in-place strengthening.

## Attempt 35 -- Test Quality FAIL: two unstated edge-case policies; fixed one by deleting, one by wording

2 of 69 unfair. Both flagged assertions pinned a policy the prompt never settled. Handled them
differently on purpose, because only one of the two semantics is worth stating.

### 1. `PeekN(-1)` -- DELETED

My own addition in Attempt 34, and the reviewer is right that it was ungrounded. meta.md says only "up
to n values", and it specifies a panic for a DIFFERENT negative argument (buffer size), so panic vs
empty vs validation are all equally plausible for negative n. Deleted the single
`require.Empty(t, c.PeekN(-1))` line.

`PeekN(0)` STAYS and was not flagged: "returns up to n values" with n=0 means up to zero values, which
is directly derivable. Only the negative case was open.

Judgment: not worth spending prompt words to specify a negative-limit convention nobody asked for. The
value of the Attempt 34 addition was the zero case (it blocks the nonpositive-n-as-PeekAll shortcut),
and that survives intact -- re-confirmed by the M1 mutation still failing.

### 2. `Test_SelectAll_ConsumedValueDoesNotMakeAnotherCaseReady` -- SPECIFIED, not deleted

The reviewer notes the prompt never says whether readiness is SNAPSHOTTED at call entry or RE-EVALUATED
after each earlier handler mutates state, and that both readings are grounded in the repo. Correct: two
`Receive` cases on a one-value channel both see `canReceive()` true up front, so a snapshot
implementation handles both and blocks on the second.

Kept this one and stated the policy, because unlike negative-n it is a real semantic that the feature
genuinely depends on -- the reviewer themself called it "a valuable semantic choice".

meta.md, first sentence of the SelectAll paragraph:
"handles every ready case in one call, in the order the cases were given, and returns how many cases it
handled" -> "handles every case that is still ready when it is reached, in the order given, and returns
how many it handled".

"still ready when it is reached" carries the whole re-evaluation semantics: readiness is evaluated at
the moment each case is reached, and "still" says it may have stopped being ready since. Deliberately
rewritten at EXACTLY the same word count (22 -> 22) so the body stays at 497 against the 500 cap --
there was no room to add a sentence.

Mutation-proved afterward: rewriting `SelectAll` to snapshot ready cases first and then handle them
makes `Test_SelectAll_ConsumedValueDoesNotMakeAnotherCaseReady` FAIL. The test pins exactly the
semantics the sentence now states.

### 3. The 30-second timeout -- REMOVED (flagged as the only quality concern three rounds running)

`Test_ChannelDrain_ClosedEmpty_ReturnsEmptyWithoutHanging` is now a plain
`require.Empty(t, c.Drain())`. Dropped the goroutine, the `time.After(30 * time.Second)` guard, and the
now-unused `time` import.

Previously I kept the guard on the grounds that it converts a hang into a clean failure instead of a
package-wide timeout crash. That reasoning still holds, but hang protection is already provided by
`go test -timeout=120s` in test.sh, and the reconcile logic added in Attempt 28 handles the resulting
crash by synthesizing failures only for tests that produced no result. Since this was the LAST
remaining quality flag and it had been raised in three consecutive reviews, removing the wall clock
entirely is worth more than the marginally nicer failure mode. There is now ZERO wall-clock timing in
any of the four new test files (verified by grep). The reviewer separately confirmed the tester's
`time.Duration` values are deterministic workflow time (`tester/tester.go:128-129`), not wall clock.

### Validation

- New-mode 68/0 and base-mode 262/0, 3x each, byte-identical every run.
- Mutation proof: snapshot-readiness `SelectAll` fails the ConsumedValue test; the Attempt 34 M1
  nonpositive-n mutation still fails the PeekN test after the `-1` line was dropped.
- Fresh-worktree round-trip: test.patch alone -> base 0 failures, new 68/68 failures; + solution.patch
  -> new 68/0, base 0 failures; broad sweep clean; solution.patch reverses cleanly.
- Patches ASCII/LF; test.sh retains `new file mode 100755`; no `shipd`/`datacurve` markers.
- solution.patch unchanged this round (277 human-effective LOC, 9 files). meta.md 497 body words,
  ASCII, zero em dashes.

Test count stays 68. Only meta.md and test.patch changed.

## Attempt 36 -- Test Quality FAIL: SelectAll blocking semantics unstated; 4 advisory gaps closed

1 of 68 unfair, plus 4 advisory coverage suggestions. Kept the flagged test and stated the semantics,
rather than deleting it.

### `Test_SelectAll_NothingReady_Yields` -- SPECIFIED, not deleted

The reviewer is right that nothing said whether `SelectAll` BLOCKS when nothing is ready and there is
no `Default`. Scanning once and returning 0 immediately is equally consistent with "returns how many
cases it handled". Two viable semantics, one pinned by the test.

Kept it because blocking is what makes `SelectAll` usable as a wait primitive and it mirrors the
existing `Select`. Deleting would have left the behavior both unstated AND untested, so an agent could
ship a non-blocking `SelectAll` -- a materially different primitive -- and nothing would notice.

### The word-budget problem, and how it was solved

meta.md was at 497 of a 500 hard cap. The clause needed ~10 words, so words had to be FREED first.
Compressed three sentences with no requirement lost:

- "Signals delivered before a workflow ever creates a channel for that name ... replayed into the
  channel once it is created, in the order they originally arrived" -> "Signals delivered before a
  channel exists for that name ... replayed once it is created, in the order they arrived" (-7)
- "`WithSignalChannelCapacity` to size a signal channel's buffer" -> "to size the buffer" (-2)
- "`Channel.Closed` reports whether the channel has already been closed" -> "... whether the channel is
  closed" (-3)

Then appended to the Default sentence: "; with no `Default` and nothing ready, `SelectAll` waits like
`Select`." Landed at 496 words, so there is a small margin again instead of sitting exactly on the cap
(a first pass hit exactly 500, which is too tight to be safe).

### Four advisory gaps, all closed and all mutation-proved

1. **Empty unbuffered direct operations** -> NEW `Test_ChannelUnbufferedEmpty_DrainAndPeeksReturnEmpty`.
   Only new test.sh entry this round.
2. **OverflowBlock eventual progress** -> extended BOTH blocking tests. The reviewer said "the current
   blocking tests permit an implementation that blocks forever" (plural); I initially fixed only the
   `internal/sync` one and caught the second via a `grep -c 'cr.Exit()'` check on the regenerated patch
   returning 1 instead of 0. `Test_WorkflowNewBufferedChannelWithPolicy_ExplicitOverflowBlock_BlocksWhenFull`
   now also resumes and asserts completion. There are now ZERO `cr.Exit()` abandonments in the suite --
   every blocked coroutine is driven to completion.
3. **SendAllNonblocking boundaries** -> extended with empty-slice, all-fit, and zero-free-slot cases.
4. **Cap across configured sizes** -> extended to 0, 1, 4, 7 plus unbuffered.

Mutations, each failing the intended test and only that test:
- `Cap` hardcoded to the two previously-tested sizes -> `Test_ChannelCap_ReportsConfiguredSize` FAILS.
- blocking `Send` never resolves its queued item -> `Test_ChannelSend_BlocksWhenFullUnderBlockPolicy` FAILS.
- unbuffered peeks consulting sender state wrongly -> `Test_ChannelUnbufferedEmpty_...` FAILS.

### Process note

The `cr.Exit()` grep is worth keeping as a habit. The reviewer's wording was plural but cited one test
by name in the heading, and I had already regenerated patches believing the item was closed. A cheap
post-regeneration grep for the construct being removed caught the miss before it shipped.

### Validation

- New-mode 69/0 and base-mode 262/0, 3x each, byte-identical every run.
- Fresh-worktree round-trip: test.patch alone -> base 0 failures, new 69/69 failures; + solution.patch
  -> new 69/0, base 0 failures; broad sweep clean; solution.patch reverses cleanly.
- No wall-clock constructs and no abandoned coroutines anywhere in the new tests (grep-verified).
- Patches ASCII/LF; test.sh retains `new file mode 100755`; no `shipd`/`datacurve` markers.
- solution.patch unchanged this round (277 human-effective LOC, 9 files). meta.md 496 body words,
  ASCII, zero em dashes.

Test count 68 -> 69.

## Attempt 37 -- Auto Review "Revision Requested": S1 empty-SelectAll returns instead of waiting, plus T4/T1

Auto Review bands: Description 3/3 clean, Tests 2/3, Solution 1/3. One High and two Medium, all real,
all fixed. The agent-run manifest was empty (`"runs": []`), so there is no pass-rate signal in this
round at all -- the review is entirely static.

### S1 (High) -- and it was MY OWN Attempt 36 sentence that created it

`SelectAll` opened with `if len(cases) == 0 { return 0 }`, which predates this review cycle. It only
became a DEFECT in Attempt 36, when I added "with no `Default` and nothing ready, `SelectAll` waits like
`Select`" to meta.md to fix the previous round's unfair-test finding. That sentence is unqualified, and
the named comparator `Select` does yield on an empty case list, so the early return now contradicts the
description directly. `workflow.SelectAll(ctx)` returned 0 and ran on.

Fix: deleted the early return. The empty range then handles nothing, finds no defaults, and falls
through to `cs.Yield()` -- exactly the existing `Select` path, which is what the sentence promises.

Lesson worth keeping: tightening a description to close a fairness gap can retroactively turn existing
code into a contract violation. After ANY meta.md wording change, re-read the implementation against the
new sentence, not just the tests. Nothing failed here -- 69/69 stayed green across Attempt 36 -- because
no test called the zero-case form.

### T4 (Medium) -- bulk send through an unbuffered rendezvous

`SendAllNonblocking` had cases for buffered capacity, full buffers, nil input and drop-oldest, but never
with a waiting receiver on an unbuffered channel. `canSend` is `len(c.receivers) > 0 || c.hasCapacity()`,
so a receiver already parked in `Receive` IS room right now; an implementation computing room as
`Cap()-Len()` returns 0 for every unbuffered channel and would have passed the whole existing batch.

Added `Test_ChannelSendAllNonblocking_UnbufferedWithWaitingReceiver_SendsOneThroughRendezvous`: receiver
blocked in `Receive`, `SendAllNonblocking([]int{1, 2})` returns 1, the receiver gets 1, drop count is 1.

### T1 (Medium) -- base mode was dropping the whole workflow/executor package

`test.sh` base scoped to `./workflow` rather than `./workflow/...` specifically to dodge three flaky
`Close_removes_any_goroutines*` subtests. That was too blunt: `solution.patch` changes
`workflow/executor/executor.go`, and the package holds `Test_Executor/Workflow_with_signal`, a direct
regression test for the signal-receipt path this change touches.

Fix: base now runs `./workflow/...` with `-skip 'Close_removes_any_goroutines'`, isolating exactly the
three demonstrated-flaky subtests by name instead of discarding the package. Base coverage went
**262 -> 314 tests**, and `Test_Executor/Workflow_with_signal` is now present in the JUnit output
(verified by grepping the emitted XML, not assumed).

Because this widens base into a package with KNOWN flakiness, I ran base 5x rather than the usual 3x:
314/0 every run. The three skipped subtests appear as empty zero-time testcases -- that is
go-junit-report's rendering of a skip, and they contribute no failures.

### Trap-proof (all three, each against the reviewer's own stated wrong implementation)

- restore `if len(cases) == 0 { return 0 }` -> BOTH `Test_SelectAll_NoCases_Yields` and
  `Test_WorkflowSelectAll_NoCases_Yields` FAIL.
- compute bulk-send room as `size - bufferedN`, ignoring waiting receivers ->
  `..._UnbufferedWithWaitingReceiver_SendsOneThroughRendezvous` FAILS.

### Validation

- New-mode 72/0, 3x identical. Base-mode 314/0, **5x** identical.
- Fresh-worktree round-trip: test.patch alone -> base 314/0, new 72/72 failures; + solution.patch ->
  new 72/0, base 314/0; solution.patch reverses cleanly.
- Patches ASCII/LF; test.sh retains `new file mode 100755`; no `shipd`/`datacurve` markers.
- solution.patch 9 files. meta.md untouched this round (496 body words) -- the S1 fix moved the CODE to
  match the description rather than weakening the sentence.

Test count 69 -> 72. Base count 262 -> 314.

## Attempt 38 -- Auto Review: public workflow.Channel surface was never compiled by the tests

Bands: Description 3/3 clean, Solution 3/3 clean (no defect found -- the S1 from Attempt 37 is gone),
Tests 1/3 with three High findings. All three are the SAME root cause and all three are real. Agent-run
manifest was empty again, so still no pass-rate signal.

### The gap

`workflow.Channel` is a hand-written interface that DUPLICATES the internal one -- it declares every
method explicitly (workflow/channel.go), and `NewChannel` / `NewBufferedChannel` /
`NewBufferedChannelWithPolicy` all return that INTERFACE, not the concrete type. So a solver who adds a
method to `internal/sync` but forgets to declare it on `workflow.Channel` produces a channel whose new
method is unreachable for every downstream workflow caller.

Measured which of the new methods any workflow-package test actually calls (constructors return the
interface, so any call in that package is an interface call):

```
Drain 5   SendAllNonblocking 1   DroppedCount 6
Peek 0    PeekN 0    PeekAll 0   IsFull 0   Closed 0   CloseDraining 0   TryCloseDraining 0
```

### Narrowing the reviewer's finding

The reviewer listed three groups. Checking each, two of the methods they did NOT name are in fact
already enforced, and for a non-obvious reason: `PeekAll` and `Drain` are called by the SOLUTION's own
`PeekAllChannels` / `DrainAll` on a `Channel[T]` value, so omitting them from the interface breaks the
solution's compile; and `Cap` is called through the interface by the tester package's
`Test_SignalChannel_ExplicitZeroCapacity_CreatesUnbufferedChannel`. The genuinely unenforced set is
exactly the six the reviewer named: Peek, PeekN, IsFull, Closed, CloseDraining, TryCloseDraining.

### Fix

Three workflow-package tests, one per group, each binding the constructor result to an explicitly typed
`var c Channel[int]` so the enforcement is a compile-time fact rather than an accident of inference:

- `Test_WorkflowChannel_PeekAndPeekNAreReachableAndNonDestructive`
- `Test_WorkflowChannel_CloseLifecycleIsReachable` (both the clean close-and-drain path and the
  blocked-sender TryCloseDraining path the reviewer asked for)
- `Test_WorkflowChannel_IsFullIsReachableAndTracksOccupancy`

Fairness: every one of these methods is named in meta.md as `Channel.X`, and meta.md is written
throughout in terms of the `workflow` package. Testing them through the public interface is exactly what
the description already promises, so nothing new had to be stated -- meta.md is untouched.

### Trap-proof (this class is compile-time, so it needed a different check than usual)

Deleted each group's declarations from the `workflow.Channel` interface in turn; every group produced a
build failure in package workflow. Then ran the FULL harness with `IsFull` removed to confirm the
failure is legible rather than silent:

```
internal/sync  tests=48 failures=0
tester         tests=13 failures=13
workflow       tests=14 failures=14      exit=1
```

27 failures where the previous suite reported zero. The tester package fails too because it imports
workflow -- extra evidence the omission is genuinely user-visible, not a test-only artifact.

### Validation

- New-mode 75/0, 3x identical. Base-mode 314/0, 3x identical.
- Fresh-worktree round-trip: test.patch alone -> base 314/0, new 75/75 failures; + solution.patch ->
  new 75/0, base 314/0; solution.patch reverses cleanly.
- Patches ASCII/LF; test.sh retains `new file mode 100755`; no `shipd`/`datacurve` markers.
- solution.patch unchanged this round (9 files, 275 human-effective LOC). meta.md unchanged (496 words).

Test count 72 -> 75.

### Standing note on LOC

solution.patch sits at 275 human-effective, exactly the hook's design target, after Attempt 37's S1 fix
deleted the three-line early return. The real floor is 200, so there is real margin against rejection,
but none against the hook's warning line -- any further source deletion trips it.

## Attempt 39 -- STALE RE-REVIEW: identical Auto Review of the Attempt 37 artifact; no action taken

Received an Auto Review whose text is byte-identical to the one handled in Attempt 38 -- same three T4
High findings, same wording, same "Your takeaway". It is a review of the PREVIOUS revision, not of what
Attempt 38 produced.

### How that was established, before doing any work

Three independent markers, all pointing at the Attempt 37 artifact:

- The review states "new mode runs all **72** named hidden tests". Attempt 37 ended at exactly 72;
  Attempt 38 raised it to 75.
- It states "**157/157** base tests pass", the pre-Attempt-38 base count.
- Its Solution 3/3 narrative already describes the scheduler's second progress check and SelectAll
  yielding, which are the Attempt 33 and Attempt 37 fixes -- so it is not older than 37 either. It
  brackets exactly to the Attempt 37 revision.

### The findings are already closed

Verified against the CURRENT test.patch rather than assumed:

```
statically-typed public-interface bindings (var ... Channel[int])   5
Test_WorkflowChannel_PeekAndPeekNAreReachableAndNonDestructive      present
Test_WorkflowChannel_CloseLifecycleIsReachable                      present
Test_WorkflowChannel_IsFullIsReachableAndTracksOccupancy            present

calls in the WORKFLOW-package test file (i.e. through the public interface):
  Peek 1   PeekN 2   PeekAll 1   IsFull 5   Closed 4   CloseDraining 1   TryCloseDraining 2
registered tests: 75
```

Every method named across the three findings is now exercised through a statically typed
`Channel[int]`, which is precisely the "Expected" remedy each finding asks for.

### Action taken: none to the artifact

Adding the requested tests again would duplicate `Test_WorkflowChannel_*`. Re-validated only that
nothing drifted: both patches still regenerate byte-identically from the worktree. Attempt 38's full
validation (new 75/0 and base 314/0 3x each, clean-room round-trip, compile-time trap-proof showing 27
failures when a public declaration is removed) stands unchanged, since no file has been touched since.

The artifact to resubmit is the current one. If this review returns a third time still citing 72 tests,
the upload did not take rather than the fix being wrong.

### Standing, unchanged

- solution.patch 275 human-effective LOC (hook target 275, real floor 200) -- no margin against the
  hook's warning line, real margin against rejection.
- Agent-run manifest empty for the third consecutive review, so solvability is STILL unmeasured since
  the 0-pass batches 4 and 5. That remains the one open risk no static review can retire.

## Attempt 40 -- Precheck FAIL: base mode used `-skip`; removed it and gained coverage doing so

Test-patch sanity check failed: "base mode uses an unsupported go test flag (`-skip`)". The `-skip`
flag was introduced in Attempt 37 to isolate three flaky executor subtests while restoring the
workflow/executor package that finding T1 asked for.

### On the merits, the flag would have worked -- but that does not matter

`-skip` was added in Go 1.21, and this repo's go.mod requires `go 1.25.0`, so the platform image must
carry Go >= 1.25 and would have accepted it. The precheck is evidently matching against a whitelist of
allowed flags rather than executing anything. A failed gate is a failed gate: it is not contestable and
not worth arguing, so the flag is gone.

### The removal made the suite BETTER, not worse

Rather than engineering a workaround (a negated `-run` regex is impossible -- Go uses RE2, no negative
lookahead -- and post-filtering the JUnit would still leave a nonzero exit on a flake), I went back and
checked the premise: are those three subtests actually flaky HERE?

The upstream flakiness note says they fail intermittently **under `-race`**. `test.sh` has never run
`-race`. Measured:

- 10/10 clean running just `Test_Executor/Close_removes_any_goroutines` in isolation.
- 10/10 clean running the entire `workflow/executor` package.

So the exclusion was never needed in this harness. Dropped `-skip` entirely and kept `./workflow/...`.
The three subtests now genuinely EXECUTE in base mode, where Attempt 37 had them appearing as empty
skipped entries. Confirmed by name in the emitted XML, and `Test_Executor/Workflow_with_signal` is still
covered.

Base then ran **8x** consecutively at 314/0 -- more repetitions than the usual gate, because this round
deliberately re-admitted tests previously judged unstable.

### Flag audit

Everything `test.sh` now passes to `go test` is long-standing and unremarkable: `-v`, `-count=1`,
`-timeout=120s`, plus `-tags=channeldrain -run` in new mode. Nothing version-gated remains.

### Lesson

Attempt 37 inherited "these three subtests are flaky" from an older comment in this very file and
engineered around it without re-testing the claim. Re-measuring it cost ten minutes, removed the
offending flag, AND increased real coverage. Inherited flakiness claims should be re-measured before
being designed around, especially when the mitigation is what breaks a gate.

### Validation

- Base 314/0 **8x**; new 75/0 3x.
- Fresh-worktree round-trip: test.patch alone -> base 314/0, new 75/75 failures; + solution.patch ->
  new 75/0, base 314/0; solution.patch reverses cleanly.
- Patches ASCII/LF; test.sh retains `new file mode 100755`; no `shipd`/`datacurve` markers; no `-skip`
  anywhere in test.patch.
- solution.patch untouched (9 files, 275 human-effective LOC). meta.md untouched (496 words).
  Test count stays 75.

## Attempt 41 -- Auto Review: SelectAll readiness tested in only ONE direction

Bands: Description 3/3 clean, Solution 3/3 clean, Tests 1/3 with a single High finding. The precheck
`-skip` problem from Attempt 40 is gone (base ran 157 regression tests fine), and the Attempt 38
public-interface findings did not return -- so this round's review is finally of the CURRENT artifact,
not a stale one.

### The finding, and why it is a genuinely good catch

`SelectAll`'s contract is "handles every case that is still ready when it is reached". That is a
BIDIRECTIONAL claim, and the suite only ever tested one direction:

- ready -> unready: `Test_SelectAll_ConsumedValueDoesNotMakeAnotherCaseReady` (two Receives, one value).
- unready -> ready: NOTHING.

The wrong implementation this permits is not a strawman: pre-scan the non-default cases once, keep the
initially-ready ones, then execute that list rechecking only retained entries. It needs the pre-scan
anyway to decide whether defaults fire, so it is a natural way to write this. It skips a case that
BECOMES ready mid-pass.

Note this is the mirror image of the Attempt 32 finding, where the same sentence was called unfair for
not stating the semantics at all. Having stated it, the suite then had to actually pin both directions
of what was stated.

### Fix

Added `Test_SelectAll_FreedCapacityMakesALaterCaseReady` (internal/sync, sitting beside its
ready->unready sibling so the pair is legible) and
`Test_WorkflowSelectAll_FreedCapacityMakesALaterCaseReady` (workflow package -- the reviewer's Expected
explicitly asks for the public surface). Capacity-1 channel holding one value, cases
`Receive(c), Send(c, &2)`: the Receive frees the only slot, so the Send is ready by the time it is
reached. Asserts handled == 2, order receive-then-send, and value 2 left in the channel.

### Trap-proof, showing the gap was exactly as described

Implemented the reviewer's snapshot-then-recheck variant and ran the whole `Test_SelectAll_*` family:

```
snapshot impl:  Test_SelectAll_FreedCapacityMakesALaterCaseReady            FAIL
snapshot impl:  Test_SelectAll_ConsumedValueDoesNotMakeAnotherCaseReady     ok
```

The wrong implementation passes the old test and fails only the new one -- the reviewer's claim
reproduced precisely, and the coverage hole is now closed from both sides.

### Validation

- New-mode 77/0, 3x identical. Base-mode 314/0, 3x identical.
- Fresh-worktree round-trip: test.patch alone -> base 314/0, new 77/77 failures; + solution.patch ->
  new 77/0, base 314/0; solution.patch reverses cleanly.
- Patches ASCII/LF; test.sh retains `new file mode 100755`; no `shipd`/`datacurve` markers; no `-skip`.
- solution.patch untouched (9 files, 275 human-effective LOC). meta.md untouched (496 words).

Test count 75 -> 77.

### Standing

Agent-run manifest empty for the FOURTH consecutive review (totalEligibleWorkingPool=0). Description and
Solution have now both been 3/3 for three reviews running, and every remaining finding has been a test
coverage gap. Solvability remains the one unmeasured risk since batches 4 and 5 came back 0-pass; no
static review can retire it.

## Attempt 42 -- Auto Review: buffered Drain frees capacity but credits nobody; fixed the whole class

Bands: Description 3/3 clean, **Tests 3/3 CLEAN (first time)**, Solution 1/3 on one High. The Attempt 41
SelectAll readiness finding did not return, and verifyFairness now reports "all requirements covered,
no unfair tests, no coverage suggestions".

### The finding

`Drain()` removing an ordinary BUFFERED item frees capacity but marks no coroutine as having
progressed. My Attempt 33 fix only covered draining a PENDING sender, whose `notify` credits that
sender. So: coroutine A parked in `Select(Send(c,...))` on a full capacity-1 channel, coroutine B drains
the buffered value then blocks elsewhere -> `Scheduler.Execute` returns with A runnable but never re-run.

Reproduced exactly as described before touching anything.

### Measuring the real scope first, which changed the fix

Rather than patching the reported case, I built the full waiter x freer matrix. BEFORE:

```
waiter          freed by Drain    freed by ReceiveNonBlocking
Select(Send)    STRANDED          STRANDED
plain Send      completes         STRANDED
```

Two things fell out that the report did not say:

1. **`ReceiveNonBlocking` -- untouched BASE-REPO code -- has the identical hole.** This is not something
   `Drain` introduced; it is a pre-existing property of every ctx-less consume. `Drain` just made it
   easy to hit.
2. **plain `Send` + `Drain` already worked**, because Drain also takes the pending item and its `notify`
   credits the sender. So the gap is precisely "a ctx-less consume that frees BUFFERED room credits
   nobody", not "Drain is broken".

That reframing is why the fix targets the transition rather than the method.

### Fix

A package-level `capacityFreed atomic.Uint64` in `internal/sync`, incremented in `tryReceive` exactly
where a buffered item is removed (`c.bufferedN--`). `Scheduler.Execute` samples it around each
`c.Execute()` and treats a change as that coroutine having progressed.

Why the counter rather than crediting a coroutine directly: the coroutine that benefits is whichever one
is parked in a Select send case polling `canSend`, and a polling selector registers itself NOWHERE, so
there is no waiter list to mark. The drainer would be the natural one to credit, but `Drain()` has no
ctx -- the same constraint that ruled out the ctx-on-Drain refactor in Attempt 33 (~41 call sites plus
an unstated compile-shape requirement). The counter is global because the scheduler has no handle on the
channels its coroutines touch; an unrelated scheduler's increment costs at most one extra no-op pass.

Only the buffered branch increments. Pending-item removal already credits via `notify`, and incrementing
on sends too would risk spinning on a degenerate `for { SendNonblocking; Yield }` loop.

AFTER: all four matrix cells complete -- including both pre-existing `ReceiveNonBlocking` cases, which
this fixes as a side effect.

### Regression tests

`Test_SelectSendCase_DrainFreeingBufferedRoom_LetsSchedulerRunIt` (internal/sync) and
`Test_WorkflowSelectSendCase_DrainFreeingBufferedRoom_LetsSchedulerRunIt` (workflow -- the reviewer
listed the public path explicitly). Both are the reviewer's exact scenario.

Trap-proof, and the important half is the second line:

```
scheduler ignores freed room:  both new tests                                    FAIL
scheduler ignores freed room:  Test_SelectDrainCase_ResumingBlockedSender...     ok
                               Test_ChannelDrain_DirectDrain_ResumesBlocked...   ok
```

The two EXISTING scheduler tests still pass under the defect, which is exactly the reviewer's point that
neither reached this path -- and confirms the new tests close a genuinely distinct hole rather than
duplicating cover.

(First mutation attempt failed to compile on an unused variable rather than failing cleanly; redone so
the mutation actually builds. A build-failure "FAIL" is not a trap-proof.)

### Validation

- New-mode 79/0, 3x identical. Base-mode 314/0, 3x identical.
- Broad sweep after touching shared scheduler + channel machinery:
  `./internal/... ./workflow/... ./tester/... ./client/...` all clean.
- Fresh-worktree round-trip: test.patch alone -> base 314/0, new 79/79 failures; + solution.patch ->
  new 79/0, base 314/0, broad sweep clean; solution.patch reverses cleanly.
- Patches ASCII/LF; test.sh `new file mode 100755`; no banned markers; no `-skip`.
- meta.md untouched (496 words) -- the fix moved code to match the contract, not the contract to match
  the code.

Test count 77 -> 79. solution.patch 9 files, LOC now above the hook target again (the counter + scheduler
change added source), which also retires the "275 exactly, no margin" note from Attempts 37-41.

## Attempt 43 -- Auto Review: blocked-sender peek tests proved nothing; SelectAll reverse-ordering edge

Bands: Description 3/3 clean, Solution 3/3 clean (second consecutive), Tests 1/3 on one High + one
Medium. Last round's scheduler High did not return.

### HIGH -- the peek tests were checking a state that cannot have changed yet

`Test_ChannelPeek_BlockedSender_DoesNotResolveSend` asserted `require.False(t, cr.Finished())`
immediately after `Peek()`, without resuming the coroutine. That assertion is vacuous: a blocked
coroutine does not become Finished when its sender callback fires -- it becomes Finished on its NEXT
`Execute()`. So the check was true for the correct implementation AND for a peek that destructively
invokes `item.notify()` while copying the value. The later `Drain()` still returns the queued value, so
every other assertion passed too.

This is a sharp lesson about assertion placement, not coverage: the test named the right property
("Peek must not resolve a blocked sender") and looked correct, but observed the wrong moment. The same
mistake was replicated in `Test_ChannelPeekNAndPeekAll_IncludeBlockedSenders` and, at the public layer,
in `Test_WorkflowDrainAllAndPeekAllChannels_IncludeBlockedSenders`.

Fix: insert `Execute()` immediately after the peek and require the sender still `Blocked()` and not
`Finished()`, THEN drain and resume it to completion. Applied to all three.

### MEDIUM -- SelectAll ordering, the other direction

Attempt 41 added the forward case (an earlier handler makes a LATER case ready, which must run). The
mirror was missing: a case already passed over while unready must NOT be revisited when a later handler
frees room. Added `Test_SelectAll_EarlierUnreadyCaseIsNotRevisited` and its workflow twin -- full
capacity-1 channel, `Send` listed FIRST (unready) and `Receive` second; expects handled == 1, order
`["receive"]`, channel empty.

Together with Attempt 41's test, `SelectAll`'s single-ordered-pass contract is now pinned from both
sides, which is what "handles every case that is still ready when it is reached, in the order given"
actually claims.

### Trap-proof

- Peek invoking the pending sender's callback while leaving values queued -> all three strengthened
  tests FAIL (internal Peek, PeekN/PeekAll, and public PeekAllChannels).
- SelectAll rescanning unhandled cases until nothing more is ready -> both new ordering tests FAIL.

Both mutations are exactly the wrong implementations the reviewer described, and both compile and run
(no build-failure false signal, per the Attempt 42 note).

### Validation

- New-mode 81/0, 3x identical. Base-mode 314/0, 3x identical.
- Fresh-worktree round-trip: test.patch alone -> base 314/0, new 81/81 failures; + solution.patch ->
  new 81/0, base 314/0, broad sweep clean; solution.patch reverses cleanly.
- Patches ASCII/LF; test.sh `new file mode 100755`; no banned markers.
- solution.patch UNTOUCHED this round (9 files, 283 human-effective LOC). meta.md untouched (496 words).

Test count 79 -> 81.

### Pattern worth carrying forward

Three of the last four rounds found a test that ASSERTED the right property but at a moment when the
wrong implementation was indistinguishable from the right one (Finished-before-Execute here;
internal-only method calls in Attempt 38; one readiness direction in Attempt 41). Writing the assertion
is not the hard part -- choosing the observation point that separates correct from incorrect is. Every
new behavioral test should now be paired with the concrete wrong implementation it is meant to reject,
and actually run against it.

## Attempt 44 -- Auto Review: recovered workflow panics masked three tester assertions

Bands: Description 3/3 clean, Solution 3/3 clean (third consecutive), Tests 1/3 on one High + two
Medium. All three are one root cause.

### The mechanism, verified before changing anything

`tester/tester.go:390-397` sets `workflowFinished = true` and `workflowErr = a.Error` TOGETHER on
completion, and the error is reachable only through `WorkflowResult()` (line 634). A panic inside a
workflow is recovered and recorded as a workflow error -- it does NOT make `WorkflowFinished()` false.

Proved it directly with a throwaway workflow that panics before assigning its output variable:

```
WorkflowFinished()=true   dropped=0 (exactly the asserted value)   WorkflowResult err=true
```

So for any tester test whose expected value happens to equal the Go zero value, a panicking
implementation is indistinguishable from a correct one. Three tests were in that position:
`SignalChannelDroppedCount` on an uncreated name (expects 0), explicit zero capacity (expects 0), and
`HasPendingSignal` on an unknown name (expects false).

### Fix applied to ALL 13 tester tests, not the 3 cited

Inserted after every `require.True(t, tester.WorkflowFinished())`:

```go
_, wfErr := tester.WorkflowResult()
require.NoError(t, wfErr)
```

Deliberately uniform rather than surgical. Every one of these workflows is supposed to complete without
error, so the assertion is correct everywhere, and the failure mode is not "these three tests are
wrong" -- it is "WorkflowFinished alone never proved the workflow succeeded". Fixing only the cited
three would leave the same latent hole in any future test whose expectation coincides with a zero
value. This is the same lesson as Attempt 33 (amd64), Attempt 40 (the second blocking test), and
Attempt 43 (three peek sites): fix the class, not the citation.

### Trap-proof -- all three of the reviewer's stated wrong implementations

- `SignalChannelDroppedCount` dropping the map-existence guard -> `..._ReportsZeroForUncreatedChannel` FAILS.
- `HasPendingSignal` panicking on an absent name -> `..._UnknownName_ReturnsFalse` FAILS.
- signal capacity validated as `capacity <= 0` instead of `< 0` -> `..._ExplicitZeroCapacity_...` FAILS.

All three previously PASSED, which is exactly the reported defect.

### MY OWN ERROR THIS ROUND, and the guard that caught it

To restore `signalchannels.go` after the third mutation I wrote
`git checkout <file> || <python fallback>`. That file is tracked and MODIFIED-BUT-UNSTAGED, so
`git checkout` silently reverted it to the BASE version and destroyed the solution changes in it. The
`||` never fired because git checkout succeeded.

Caught it by checking for solution markers in the file immediately afterward (`grep -c` returned 0 and
`git status` showed the file clean, which it should never be). Restored with
`git apply --include=internal/workflowstate/signalchannels.go solution.patch`, then verified the whole
source tree regenerates BYTE-IDENTICALLY to the on-disk solution.patch before continuing.

Rule going forward: NEVER use `git checkout`/`git restore` on a file in this worktree. Source files are
modified-unstaged and test files are staged, so both forms of checkout destroy work. Always restore
mutations from an explicit `cp` backup taken in the same command, and verify with a patch-vs-worktree
diff, not by assuming.

### Validation

- New-mode 81/0, 3x identical. Base-mode 314/0, 3x identical.
- Worktree source verified byte-identical to solution.patch after the accidental revert.
- Fresh-worktree round-trip: test.patch alone -> base 314/0, new 81/81 failures; + solution.patch ->
  new 81/0, base 314/0, broad sweep clean; solution.patch reverses cleanly.
- Patches ASCII/LF; test.sh `new file mode 100755`; no banned markers.
- solution.patch unchanged in content (9 files, 283 human-effective LOC). meta.md untouched (496 words).

Test count stays 81 -- this round strengthened existing assertions rather than adding tests.

## Attempt 45 - batch 6 came back 0/5; fixed the unfairness that caused it

First real batch since batch 3. 5x Nova, 0 passed. Baseline 157/157 clean and deterministic in every
run, so this is a pure new-suite result.

### What the runs actually show

Per-run new-suite scores: 45, 44, 45, 53, 76 of 81. The spread is healthy; the problem is what sits
underneath it. Four tests failed in ALL FIVE runs, including the 76/81 near miss:

- `Test_ChannelDrain_DirectDrain_ResumesBlockedSenderUnderScheduler`
- `Test_SelectDrainCase_ResumingBlockedSender_LetsSchedulerRunIt`
- `Test_SelectSendCase_DrainFreeingBufferedRoom_LetsSchedulerRunIt`
- `Test_WorkflowSelectSendCase_DrainFreeingBufferedRoom_LetsSchedulerRunIt`

All four pin one requirement: draining must not leave a coroutine stranded. Either the blocked sender
whose value Drain consumed resumes, or the send case waiting on the room Drain freed becomes ready
and runs. Every one of the five platform evaluators named "scheduler resumption" in its own summary
without being prompted.

meta.md never stated it. Keyword scan over meta.md for progress / resume / schedul / wake / woken /
unblock / coroutine returned nothing outside the Drain definition sentence itself.

This is exactly the unfairness signal CLAUDE.md names: all agents failing for the same exact reason.
And it is a hidden requirement, not one genuinely hard step - Nova #5's Drain implementation is what
a competent engineer writes from the description (PeekAll, clear the buffer, pop every sender in FIFO
order). It releases the senders correctly. It simply never tells the scheduler, because nothing asked
it to.

### Why this crept in

The requirement entered the SOLUTION through Attempts 30, 33 and 42, each in response to a Solution
Quality FAIL saying the drain path deadlocks. Each time I fixed the solution and added a test pinning
the fix. The behavior is genuinely required for correctness. What I never did was carry it back into
meta.md, so the tests ended up enforcing an invisible contract.

Lesson: when a Solution Quality finding forces NEW behavior into the solution, the description edit is
part of that same fix, not a follow-up. A solution-only fix silently converts a review finding into a
hidden requirement.

### The fix (meta.md only)

Added to the Drain paragraph:

  Draining must not strand a coroutine: a blocked sender whose value Drain took, and a send case
  waiting on room Drain freed, both proceed on their own, with no further channel activity needed
  to wake them.

Behavioral, not prescriptive - it states WHAT must hold, and names neither MadeProgress nor the
scheduler's progress accounting, so the implementation route stays open.

The body was at 487 of 500 words, so I bought the 36 words back:

- Signal replay sentence compressed (saves 27): the "same nonblocking delivery a live signal uses so
  replay never blocks channel creation" clause overlapped the overflow-policy clause that follows it.
  Now "Replay never blocks: it is subject to the channel's overflow policy exactly as a live delivery
  is." Both tested behaviors (arrival order, backlog overflow policy) still stated.
- `SignalChannelDroppedCount` tail "or 0 if no channel with that name has been created yet" -> "or 0
  if none exists yet" (saves 6). Still states the uncreated-channel case that the test pins.

Body now 490 words, ASCII, zero em dashes.

### What I deliberately did NOT do

- Did not delete the four tests. Two separate Solution Quality reviews called the missing resumption
  a correctness bug; the behavior has to exist. The fair fix is documenting it, not dropping it.
- Did not touch test.patch or solution.patch. No code changed this round.
- Did not treat `Test_ChannelCloseDraining_IncludesBlockedSender_ClosesWithoutPanicking` (failed 4/5)
  as unfair. Nova #5 passed it, and CloseDraining closing successfully is derivable from the stated
  contrast with TryCloseDraining plus Drain's definition of "values still present". It is a real trap
  (base `Close()` panics with blocked senders, so Close-then-Drain fails) and it stays.

### Expected effect

Nova #5 was 5 tests from passing and 4 of those 5 were this requirement. Documenting it should convert
roughly that one run, putting the batch near 20% - inside the <=50% ceiling and still at the hard edge.
The 44-53 cluster is failing on much more than this and should stay failing.

### Validation

No code changed, so the suites are unchanged: new-mode 81/0, base-mode 314/0, both still 3x identical
from Attempt 44. solution.patch and test.patch byte-identical to Attempt 44. meta.md re-verified ASCII,
no em dashes, 490 body words, frontmatter Commit still 48e8119.

Note: this meta.md edit stales the batch-6 runs. Next batch measures the fixed artifact.

## Attempt 46 - Solution Quality FAIL: TryCloseDraining blind to Select send cases

Both findings are real. I reproduced the High one before touching anything, and did not contest.

### High: TryCloseDraining closes a channel with a blocked Select send case

Reproducer, run against the Attempt-45 artifact:

    c := NewChannel[int]()
    s.NewCoroutine(..., func(ctx Context) error {
        Select(ctx, Send(c, &v, func(ctx Context) { handled = true }))
        return nil
    })
    s.Execute()                      // coroutine parked, RunningCoroutines()==1
    values, ok := c.TryCloseDraining()

    -> values=[] ok=true   Closed()=true
    -> after re-Execute: handled=false running=1     (stranded forever)

Exactly as described. `channelSendCase` only calls `Channel.Send` from `Handle`, and `Handle` runs
only once `Ready` returns true, so a coroutine parked in a Select send case has NO `queueItem`.
`hasPending()` counts queue entries only, so `TryCloseDraining` saw nothing, closed, and returned
true. Once closed, the send case has no route to become ready again.

This contradicts meta.md twice over: "TryCloseDraining returns the remaining values and false
without closing if coroutines are still blocked sending to it", plus the Attempt-45 sentence that
expressly names "a send case waiting on room" as a blocked sender.

### Medium: package-global capacityFreed counter

Accepted without argument. I introduced it in Attempt 42 and documented the cross-scheduler coupling
in its own comment, which is a tell that it was the wrong shape. `Scheduler.Execute` is documented as
running "until they are all blocked"; keying that on a package-global that any other workflow's
buffered receive can bump makes one scheduler's quiescence depend on unrelated instances.

### Why I reached for a global in the first place

`Drain()` takes no Context. When a direct `c.Drain()` frees buffered room, the beneficiary is a
coroutine parked elsewhere in a Select send case, and Drain has no handle on the caller's coroutine
state, let alone the waiter's. A global counter was the only thing that survived that, so I used it.

The reviewer's suggestion dissolves the problem: if the WAITER registers itself on the channel, the
channel can notify it directly. No ctx needed at the Drain call site, and the right coroutine gets
credited rather than the whole scheduler being kept awake.

### The fix - one mechanism, both findings

Mirrored the receive side, which the repo already has (`receivers []*Receiver[T]` with
`AddReceiveCallback`/`RemoveReceiveCallback`). The send side simply lacked its twin.

`internal/sync/channel.go`:
- New `sendWaiter{notify func()}` plus `sendWaiters []*sendWaiter` on `channel[T]`, with
  `addSendWaiter` / `removeSendWaiter` / `notifySendWaiters`.
- `hasBlockedSenders() = hasPending() || len(sendWaiters) > 0`.
- `tryReceive` buffered branch: `capacityFreed.Add(1)` -> `c.notifySendWaiters()`. Single site, and
  because Drain/Receive/ReceiveNonBlocking all funnel through `tryReceive`, all three are covered.
- `TryCloseDraining` now tests `hasBlockedSenders()`.
- Deleted `capacityFreed`, `CapacityFreedCount`, and the `sync/atomic` import.

`internal/sync/selector.go`:
- `sendWaiterCase` interface; `channelSendCase` implements `registerSendWaiter`.
- `Select` and `SelectAll` register their send cases for the duration of each yield and unregister on
  wake. Preallocated (`make([]func(), 0, len(cases))`) for the enabled prealloc lint rule.

`internal/sync/scheduler.go`:
- Dropped `freedBefore`/`freedRoom`; back to plain `allBlocked && !c.Progress()`.

Left `Close()` alone (still panics only on `hasPending()`). CloseDraining closing unconditionally is
the documented contrast with TryCloseDraining, and changing it would alter base behavior.

### Tests: the suite did NOT catch this

Worth stating plainly. 81/81 passed both before and after the bug existed, so the suite had zero
discrimination on it. Three tests added (81 -> 84):

- `Test_ChannelTryCloseDraining_FailsWithBlockedSelectSendCase`
- `Test_ChannelTryCloseDraining_SucceedsOnceTheSelectSendCaseIsDone` (guards the unregister path, so
  a registration leak cannot pass)
- `Test_WorkflowChannel_TryCloseDrainingRefusesABlockedSelectSendCase`

Two false starts on my side, both my test logic rather than the fix: I first completed the send via
`ReceiveNonBlocking` (nothing to receive - the parked case has not sent yet), then via a receiver
coroutine (deadlocks, because a receiver arriving does not wake a polling send case, which is a
separate liveness question and out of scope). Settled on a full buffered channel: park the case,
refuse the close, `Drain` to free room, and the case completes. That exercises the documented path
end to end and stays inside stated semantics.

### Trap-proof (all mutations compile)

| Mutation | Result |
|---|---|
| `TryCloseDraining` uses `hasPending()` (the exact reported bug) | 2 fail: both TryCloseDraining select-case tests |
| `tryReceive` never calls `notifySendWaiters` | 2 fail: both DrainFreeingBufferedRoom tests |
| `Select` never registers send waiters | 4 fail: both classes together |

Restored from `cp` backups, then verified byte-identical with `cmp` - no `git checkout`, per the
Attempt-44 rule.

### Near-miss during patch regeneration

I generated solution.patch with `git diff --cached BASE -- <src>` and it came back EMPTY, overwriting
the file. Source files here are modified-UNSTAGED while test files are staged, so `--cached` sees
nothing for the source set. Caught it immediately on the byte count and the LOC hook reading 0.
solution.patch uses `git diff BASE -- <src>`; only test.patch uses `--cached`. Same split as the
Attempt-44 lesson, opposite direction: check the generated patch is non-empty and the file list is
right, every time, rather than trusting the command shape.

### Validation

- New mode 84/0, base mode 157/0, 3x each, identical.
- Clean-room round-trip from BASE: test.patch alone -> base 157/0, new 84/84 fail; + solution.patch ->
  new 84/0, base 157/0; solution.patch reverses cleanly.
- Broad `go test ./...` clean except the pre-existing MySQL backend test (needs a live DB, "Access
  denied for user 'root'"), which is in neither mode's package set.
- Patches ASCII/LF, test.sh `new file mode 100755`, no banned markers, no banned comment markers.
- human-effective LOC **310** (was 283), 9 source files.
- meta.md UNCHANGED - it already stated both halves of this contract, and the reviewer quoted both.

Base count note: the graded JUnit baseline is 157 testcases, which matches the platform's p2p=157
exactly. Earlier attempts in this file quote 314 for base mode; 157 is the number the platform grades.

## Attempt 47 - Solution Quality FAIL: stale send waiters after Scheduler.Exit

Real, and a regression I introduced in Attempt 46. Reproduced before changing anything.

### The finding

`internal/sync/coroutine.go` `yield()` ends in `runtime.Goexit()` when `shouldExit` is set, and the
repo's own comment there says Goexit "runs all deferred functions". My Attempt-46 code unregistered
the send waiters with a plain statement AFTER `cs.Yield()`:

    unregister := registerSendWaiters(cs, cases)
    cs.Yield()
    unregister()          // never reached on the Goexit path

So a coroutine torn down by `Scheduler.Exit` left its waiter registered forever, and since
`TryCloseDraining` treats any `sendWaiters` entry as a blocked sender, the channel could never be
closed again on behalf of a coroutine that no longer exists.

Reproducer on the Attempt-46 artifact (capacity-1 channel prefilled, one coroutine parked in
`Select(Send(...))`):

    after s.Execute():  parked
    after s.Exit():     TryCloseDraining -> values=[1] ok=false   Closed()=false     WRONG

After the fix: `ok=true`, `Closed()=true`.

This is the mirror image of the Attempt-46 bug. There, `TryCloseDraining` was blind to real waiters;
here it saw phantom ones. Same lifecycle state, opposite failure. Registering channel-owned state
means owning EVERY exit path, and in this codebase one of those paths is `runtime.Goexit`.

### The fix

Extracted the register/yield pair into a helper so cleanup is deferred:

    func yieldWaitingToSend(cs *coState, cases []SelectCase) {
        unregister := registerSendWaiters(cs, cases)
        defer unregister()

        cs.Yield()
    }

`Select` and `SelectAll` both call it in place of their inline register/yield/unregister. Normal
per-yield cleanup is unchanged; the Goexit path now cleans up too, since Goexit runs defers.

### Tests (84 -> 87)

- `Test_SelectSendCase_SchedulerExit_ClearsTheSendWaiter` - also asserts the refusal is still correct
  BEFORE the exit, so the test cannot pass by never registering at all.
- `Test_SelectAll_SchedulerExit_ClearsTheSendWaiter` - SelectAll has its own call site.
- `Test_WorkflowSelectSendCase_SchedulerExit_ClearsTheSendWaiter` - public-surface twin.

Using `s.Exit()` here is deliberate, not the abandonment pattern banned after Attempt 36: Exit is the
subject under test and every test asserts against the channel afterwards.

### Trap-proof

Reverting `defer unregister()` to the post-`Yield()` statement (the exact reported wrong
implementation, compiles cleanly) fails exactly the 3 new tests and nothing else. Restored from a
`cp` backup and verified identical with `cmp`.

### Validation

- New 87/0, base 157/0, 3x each, identical.
- Clean-room round-trip from BASE: test.patch alone -> base 157/0, new 87/87 fail; + solution.patch ->
  new 87/0, base 157/0; reverses cleanly.
- Patches ASCII/LF, non-empty, 9 source + 5 test files, test.sh `new file mode 100755`, no banned
  markers. Generated with `git diff BASE` for solution and `git diff --cached BASE` for tests, and
  the byte counts checked before writing (the Attempt-46 near-miss).
- human-effective LOC 311. meta.md unchanged at 490 words - the contract sentence already covers this
  ("...false without closing if coroutines are still blocked sending to it"); a coroutine killed by
  Exit is not blocked, so correct behavior here follows from the stated rule rather than needing a
  new one.

### Running note on this class

Three consecutive Solution Quality rounds have all been the same underlying gap: what counts as "a
coroutine blocked sending", and who is responsible for the bookkeeping. Attempt 42 papered over it
with a global counter, 46 replaced that with per-channel waiters but only covered registration and
notification, 47 closed the teardown path. The mechanism is now complete: register on park, notify on
free, unregister on every exit including Goexit.

## Attempt 48 - Solution Quality FAIL: phantom pending value after Scheduler.Exit

Real. Same lifecycle class as Attempt 47, on the other send path. Reproduced first.

### The finding

`Send` appends its pending `queueItem` and then yields with no deferred cleanup. A coroutine torn
down by `Scheduler.Exit` leaves through `runtime.Goexit`, so the item stays in the queue with no
coroutine behind it. Reproducer on the Attempt-47 artifact:

    parked:            PeekAll=[1]
    after s.Exit():    PeekAll=[1]                       WRONG, nobody holds it
                       TryCloseDraining -> ([1], false)  WRONG, refuses forever
                       Closed()=false

After the fix: `PeekAll=[]`, `TryCloseDraining -> ([], true)`, `Closed()=true`.

This is pre-existing base behavior in the sense that base `Send` has the same no-defer shape, but
base has no Drain/Peek/TryCloseDraining, so nothing could observe it. My patch made it observable and
meta.md promises values "held by coroutines currently blocked sending" - a dead coroutine holds
nothing. So it is squarely in scope.

### The fix

    defer func() {
        if item != nil && !item.buffered {
            c.removeItem(item)
        }
    }()

The `!item.buffered` guard is the whole subtlety, and I checked both resolution paths in
`tryResolvePending` before writing it:

- handed to a waiting receiver -> `removeItem(item)` already ran, item is out of the queue, so the
  deferred `removeItem` scan is a harmless no-op.
- flipped to buffered in place -> `item.buffered = true`, the value now belongs to the CHANNEL rather
  than to this send, and must survive. Removing it would silently drop a value the sender already
  successfully placed.

### Tests (87 -> 90)

- `Test_ChannelSend_SchedulerExit_RemovesThePhantomPendingValue` - asserts the pre-Exit refusal too,
  so it cannot pass by never queueing at all.
- `Test_ChannelSend_ResolvedIntoBufferSurvivesSchedulerExit` - the guard test, aimed squarely at the
  naive unconditional-removal fix.
- `Test_WorkflowChannelSend_SchedulerExit_RemovesThePhantomPendingValue` - public-surface twin.

### Trap-proof (both compile)

| Mutation | Result |
|---|---|
| no deferred cleanup (the reported bug) | 2 fail: both phantom-value tests |
| `removeItem` unconditionally, no `!item.buffered` guard | 4 fail, incl. 3 PRE-EXISTING send tests |

The second is the useful one: dropping the guard breaks `Test_ChannelSend_BlocksWhenFullUnderBlockPolicy`,
`Test_ChannelSend_ResumingAfterCapacityOpens_RemovesStalePendingSender` and
`Test_ChannelSend_ResumedSender_OccupiesCapacity` as well, so the suite already had teeth against
over-removal even before this round's additions. Restored from `cp` backup, verified with `cmp`.

### Validation

- New 90/0, base 157/0, 3x each, identical.
- Clean-room round-trip from BASE: test.patch alone -> base 157/0, new 90/90 fail; + solution.patch ->
  new 90/0, base 157/0; reverses cleanly.
- Broad sweep: only `Test_MysqlBackend` and `Test_PostgresBackend` fail, both needing a live DB
  ("password authentication failed for user root"). Verified they fail identically on PRISTINE BASE,
  so they are environmental and in neither mode's package set.
- Patches ASCII/LF, non-empty, 9 source + 5 test files, test.sh `new file mode 100755`, no banned
  markers. human-effective LOC 315. meta.md unchanged at 490 words.

### Class status

Four rounds on one question: who owns the bookkeeping for "a coroutine blocked sending".

| Attempt | Path | Gap |
|---|---|---|
| 42 | freed capacity | global counter instead of per-channel state |
| 46 | Select send case | no registration at all |
| 47 | Select send case | registered, never unregistered on Goexit |
| 48 | ordinary Send | queued, never dequeued on Goexit |

Both send paths now register on park, get notified on free, and clean up on every exit including
Goexit. I checked the receive side for the same shape: `Receive` uses `AddReceiveCallback` /
`RemoveReceiveCallback`, and a torn-down receiver leaves a stale `*Receiver[T]` by the same argument.
It is untouched base behavior, unobservable through anything this problem adds (no API reports
waiting receivers), so I did not change it - flagging it here rather than silently expanding scope.

## Attempt 49 - Test Quality FAIL: 5 tests pinned unstated failure-path non-destructiveness

Correct finding, narrow and real. Fixed in meta.md, tests untouched.

### The gap

meta.md said:

    `Channel.TryCloseDraining` returns the remaining values and `false` without closing if
    coroutines are still blocked sending to it.

That guarantees the return value and that the channel stays open. It says nothing about whether the
failed call LEAVES those values in the channel. The reviewer's alternative reading - detect the
blocked sender, report and drain the present values, decline to close - satisfies every stated word
and makes all five cited assertions wrong. Confirmed by search that nothing in the pre-patch repo
resolves it: there is no TryCloseDraining/CloseDraining anywhere before the patch.

Five tests co-asserted retention across the failed call. Fair call.

### Fix: state it (3 words), do not delete the tests

Non-destructiveness is the correct semantic and the one the solution implements
(`return c.PeekAll(), false`). A try-close that consumes the channel on failure would be a strange
API, and the retention assertions are genuinely valuable, so the right resolution is to state the
policy rather than drop the coverage.

    ... reports the remaining values and `false` without closing or removing anything if
    coroutines are still blocked sending to it.

`returns` -> `reports`, plus `or removing anything`. Body 490 -> 493 words, still under the 500 cap.
ASCII, no em dashes.

### Trap-proof

Implemented the reviewer's exact alternative (`return c.Drain(), false` on the blocked-sender branch,
compiles cleanly) and ran the suite:

    destructive-on-failure mutation -> failed: 5
      Test_ChannelTryCloseDraining_FailsWithBlockedSelectSendCase
      Test_SelectSendCase_SchedulerExit_ClearsTheSendWaiter
      Test_WorkflowChannel_TryCloseDrainingRefusesABlockedSelectSendCase
      Test_WorkflowSelectSendCase_SchedulerExit_ClearsTheSendWaiter
      Test_WorkflowChannel_CloseLifecycleIsReachable

Exactly the five cited, and nothing else. That is a clean two-way confirmation: the reviewer picked
the right test set, and those five are precisely the discriminator for the semantic now stated. No
other test in the suite depended on it.

### Validation

- meta.md only. solution.patch and test.patch byte-identical (md5 unchanged), and solution.patch
  re-verified equal to the live worktree diff.
- New 90/0, base 157/0, 3x each, identical.
- Test count stays 90.

### Note for future rounds

This is the third time the resolution has been "the tested behavior is right, the description was
silent" (Attempt 45 scheduler resumption, Attempt 45 signal replay wording, now failure-path
non-destructiveness). All three entered the suite alongside a SOLUTION fix. The pattern is
consistent: when a Solution Quality round forces new behavior, the behavior's CONTRACT needs a
description sentence in the same round, or the next Test Quality round flags it as unstated.

## Attempt 50 - Auto Review: CloseDraining strands a parked Select sender; SelectAll waiter untested

Both findings verified real before any change. Also fixed the 501-word overflow.

### S1 (High): CloseDraining strands a parked Select send case

Reproduced on the Attempt-49 artifact:

    parked:                       running=1
    CloseDraining -> [1]          Closed=true
    after 5 more Execute passes:  sent=false running=1      STRANDED

Mechanism is exactly as the reviewer traced. `CloseDraining` is Drain then Close. Drain frees the
buffered slot and calls `notifySendWaiters`, which only sets a progress FLAG - it does not run the
coroutine. Close then sets `closed`, and `canSend` returns false on a closed channel, so the parked
case polls an eternally unready channel.

### The fix: extend the rule the repo already has

`Close()` already panics when a coroutine is blocked sending (`hasPending()` -> "send on closed
channel"). My patch introduced a SECOND kind of blocked sender and never extended that predicate.
One-line consistency fix:

    if c.hasBlockedSenders() {
        panic("send on closed channel")
    }

That closes the stranding path entirely rather than papering over it, and it makes the three close
methods a coherent set: `TryCloseDraining` is the safe path (refuses, returns false), `Close` /
`CloseDraining` are the forcing path (report the blocked sender instead of silently stranding it).

Checked all three behaviors explicitly, since this touches base code:

| Case | Before | After |
|---|---|---|
| parked Select send case | strands silently | panics |
| no waiter at all | closes | closes (unchanged) |
| coroutine blocked in ordinary `Send` | closes | closes (unchanged - Drain resolves it first) |

The third is why `Test_ChannelCloseDraining_IncludesBlockedSender_ClosesWithoutPanicking` still
passes: Drain consumes the queued item, so by the time Close runs nothing is blocked.

### T3/T4 (High): the SelectAll waiter test proved nothing

Correct, and a sharp catch. `Test_SelectAll_SchedulerExit_ClearsTheSendWaiter` only asserted AFTER
`Exit`, and "never registered a waiter" also produces `ok=true` there. The other SelectAll send tests
become ready in the same pass, so none of them ever exercise the yield path. An implementation giving
Select proper waiter handling while leaving SelectAll on a bare `cs.Yield()` passed the entire suite.

Fixed both ways the reviewer asked for:
- Added a PRE-Exit assertion to the cleanup test: `TryCloseDraining` must return false, the channel
  must stay open, and the values must come back. This is what distinguishes registered from
  not-registered.
- Added `Test_SelectAll_DrainFreeingBufferedRoom_LetsSchedulerRunIt`, the SelectAll counterpart of
  the existing Select wake-up test: two coroutines, Drain frees the slot, the parked SelectAll send
  must run and acknowledge with no further channel event.

### Tests (90 -> 93)

- `Test_SelectAll_DrainFreeingBufferedRoom_LetsSchedulerRunIt`
- `Test_ChannelCloseDraining_RefusesToStrandAParkedSelectSender`
- `Test_WorkflowChannel_CloseDrainingRefusesToStrandAParkedSelectSender`
- plus the pre-Exit strengthening of `Test_SelectAll_SchedulerExit_ClearsTheSendWaiter`

### Trap-proof (both compile, both are the reviewer's stated wrong impl)

| Mutation | Result |
|---|---|
| SelectAll's nothing-ready branch as a direct `cs.Yield()` | 2 fail: the new wake-up test AND the now-strengthened cleanup test |
| `Close` reverts to `hasPending()` | 2 fail: both CloseDraining stranding tests |

The first is the proof that the gap is closed: that mutation previously passed all 90 tests.
Restored from `cp` backups, verified with `cmp`.

### meta.md: 501 -> 497 words

The platform counts the H1 TITLE plus the body (8 + 493 = 501); my own check had been counting the
body only, which is why 493 read as safe. Counting the title from now on.

Freed 10 words and spent 6:
- "All of these return an empty result immediately on a channel with nothing available, whether or
  not it is closed." -> "All of these return empty immediately when nothing is available, open or
  closed." (-7)
- signal replay "...replayed once it is created, in the order they arrived" -> "...replayed in
  arrival order once it is created" (-2)
- "panics if given a negative size" -> "panics on a negative size" (-1)
- CloseDraining sentence now states the panic rule (+6): "closes a channel and returns any values
  still present, panicking like `Close` if a coroutine is still blocked sending. TryCloseDraining
  instead reports the remaining values and `false` without closing or removing anything in that case."

Stating it matters: the new panic tests would otherwise pin behavior the description never mentions,
which is precisely the Attempt-49 failure mode. Description edit shipped in the SAME round as the
solution fix, per the note I left last time.

### Validation

- New 93/0, base 157/0, 3x each, identical.
- Clean-room round-trip from BASE: test.patch alone -> base 157/0, new 93/93 fail; + solution.patch ->
  new 93/0, base 157/0; reverses cleanly.
- Patches ASCII/LF, non-empty, 9 source + 5 test files, test.sh `new file mode 100755`, no banned
  markers. human-effective LOC 315. meta.md 497 words by the platform's own counting method.

### Standing note

Agent-run manifest was again empty (`totalEligibleWorkingPool: 0`), so difficulty is still unmeasured
since batch 6 (0/5, fixed in Attempt 45). Description held 3/3.

## Attempt 51 - Test Quality FAIL: my own Attempt-50 wording contradicted two tests

Self-inflicted. The two flagged tests are correct; the sentence I wrote last round was not.

### What went wrong

Attempt 50 added "panicking like `Close` if a coroutine is still blocked sending." I meant "still"
as "after the drain". Read plainly it covers a coroutine blocked in an ordinary `Send`, and two tests
assert CloseDraining SUCCEEDS in exactly that case. The reviewer read it correctly and flagged the
contradiction.

The implementation distinguishes the two, and the distinction is the whole point:

| Blocked how | Does Drain free it? | CloseDraining |
|---|---|---|
| ordinary `Send` (value sits in the queue) | yes, Drain takes the value | closes, no panic |
| Select send case (holds no value, waits for room) | no, there is nothing to take | panics |

So the reviewer's first Coverage Suggestion - "require CloseDraining to panic when a direct Send
coroutine is blocked" - would be WRONG for this design, and I did not follow it. It is downstream of
my bad sentence, not an independent finding. Fixing the sentence removes the basis for it.

### Fix: precise wording, tests unchanged

    `Channel.CloseDraining` closes a channel and returns any values still present. Draining frees a
    coroutine blocked sending one of those values, but not a send case waiting for room; closing
    while one waits panics as `Close` does. `Channel.TryCloseDraining` instead reports the remaining
    values and `false`, changing nothing, whenever any coroutine is blocked sending.

Three things this now gets right that the old sentence did not:
- names WHY a direct sender is freed (its value is taken) and a send case is not (nothing to take),
- scopes the panic to the send-case wait only,
- gives TryCloseDraining its own, broader condition ("whenever any coroutine is blocked sending"),
  which is what `Test_ChannelTryCloseDraining_FailsWithBlockedSenders` (direct) and
  `..._FailsWithBlockedSelectSendCase` actually assert. The old "in that case" wrongly chained
  TryCloseDraining's condition to CloseDraining's.

Both flagged tests are now covered by stated text and stay as they are.

### Coverage Suggestion 2 (adopted)

"After TryCloseDraining returns false for a direct blocked sender, assert Drain still returns the
reported value and the sender can then finish." Correct and cheap - the direct-sender test reported
the value but never checked it survived. Strengthened
`Test_ChannelTryCloseDraining_FailsWithBlockedSenders`:

    require.Equal(t, []int{1}, c.Drain(), "a refused close must leave the reported value in place")
    cr.Execute()
    require.True(t, cr.Finished(), "the sender must still be able to finish after a refused close")

Measured effect - destructive `TryCloseDraining` (`return c.Drain(), false`) now fails 7 tests, up
from 5, and the two new catches are exactly the gaps named:
`Test_ChannelTryCloseDraining_FailsWithBlockedSenders` (direct path, previously non-discriminating)
and `Test_SelectAll_SchedulerExit_ClearsTheSendWaiter`.

### Word budget

496 by the platform's method (title + body), 4 words of margin. Freed 12 to spend 16:
"lost instead of waiting, and this loss is counted" -> "lost, counted"; PendingSignalNames sentence
tightened; "every case that is still ready" -> "every case still ready"; dropped a stray "own" and
"one". No behavior sentence lost.

### Validation

- New 93/0, base 157/0, 3x each, identical. Test count unchanged at 93 (one test strengthened).
- Clean-room round-trip from BASE: test.patch alone -> base 157/0, new 93/93 fail; + solution.patch ->
  new 93/0, base 157/0; reverses cleanly.
- Patches ASCII/LF, non-empty, 9 source + 5 test files, test.sh `new file mode 100755`, no banned
  markers. human-effective LOC 315. solution.patch byte-identical to Attempt 50 (no code change).

### Lesson

Attempt 50's note said to ship the description edit in the same round as the solution fix. I did, but
wrote it too fast and too broadly: I described the RULE ("panics if a coroutine is blocked sending")
instead of the rule my code implements ("panics if draining cannot free them"). When adding a
contract sentence, check it against every EXISTING test that touches the same method, not just the
new one it is being written for. Two existing tests contradicted it and I did not re-read them.

## Attempt 52 - Test Quality FAIL: 5 Scheduler.Exit cleanup tests pinned unstated teardown

Correct finding. Fixed in meta.md; no code or test change.

### The situation

The five flagged tests exist because TWO prior Solution Quality reviews demanded exactly this
behavior as a High correctness defect:

- Attempt 47: "Exited Select send cases remain registered as blocked senders"
- Attempt 48: "A terminated ordinary Send remains a phantom blocked sender"

So Solution Quality says the teardown cleanup is REQUIRED; Test Quality says the tests pinning it are
UNFAIR because nothing states it. Both are right. The behavior is correct and the description was
silent, which is the Attempt-45 pattern for the fourth time.

Resolution is the same as Attempt 45: state it, do not delete the tests. Deleting them would
reintroduce the two defects with no coverage.

### The sentence

    A coroutine the scheduler tears down is not blocked sending, and the value it held is not
    available.

Placed after the TryCloseDraining sentence. It closes both halves of the finding:

- "is not blocked sending" feeds the already-stated TryCloseDraining condition ("...whenever any
  coroutine is blocked sending"), so a torn-down coroutine no longer keeps a close refused. Covers
  the three waiter-cleanup tests.
- "the value it held is not available" covers the two phantom-value tests, which assert PeekAll and
  Drain come back empty after Exit.

### Checked against EXISTING tests first (the Attempt-51 lesson, applied)

Last round I wrote a contract sentence without re-reading the existing tests that touched the same
method, and it contradicted two of them. This time I enumerated every test that calls Exit before
writing anything: six of them, the five flagged plus
`Test_ChannelSend_ResolvedIntoBufferSurvivesSchedulerExit`.

That sixth one asserts the value SURVIVES Exit, which looks like a contradiction and is not: the send
had already flipped to buffered, so the coroutine no longer held it. meta.md already draws exactly
that line in the Drain sentence, "buffered values AND values held by coroutines currently blocked
sending", so "the value it held" reads correctly against it. No conflict, verified rather than
assumed.

### Word budget

496 by the platform's method (title + body), 4 words of margin. My first pass landed at 501 because I
over-estimated the savings, so I measured and trimmed again rather than shipping at the cap. Freed
across eight spots (Drain select-case phrasing, "Default case given", DroppedCount, signal replay x2,
DrainAll concatenation, SendAllNonblocking, IsFull) plus four more on the second pass. No behavior
sentence dropped.

### Validation

- New 93/0, base 157/0, 3x each, identical.
- solution.patch and test.patch byte-identical to Attempt 51 (md5 unchanged), and solution.patch
  re-verified equal to the live worktree diff. meta.md only.
- Test count unchanged at 93.

### Class tally

Description-silent-on-required-behavior is now 4 for 4 in this problem: scheduler resumption (45),
failure-path non-destructiveness (49), the close-panic distinction (51), teardown cleanup (52). Every
one entered the suite alongside a Solution Quality fix. The generalization is stronger than what I
wrote in Attempt 49: it is not just "write the sentence in the same round", it is that a Solution
Quality fix which adds OBSERVABLE behavior always needs a contract sentence, because the reviewer
that reads the tests is not the reviewer that demanded the fix.

## Attempt 53 - Re-eval rule landed; froze the solver-visible surface and fixed a standing comment-convention violation

No reviewer output this round. The platform shipped **Re-eval** (2026-09-03): a batch staled by a
`test.patch` / `solution.patch` edit re-grades at ~30% of batch price, but editing `meta.md` / title /
Dockerfile / base commit invalidates the solving work and there is no button. Recorded in
`CLAUDE.md § RULE UPDATE 2026-09-03`, `failure-patterns.md § L36`, 8 Instructions files and both
authoring skills.

### Why this changes the sequencing here

Attempts 45-52 all touched meta.md. Every one of those would have been a description-delta, so the
cheap lane was never available to this problem. Going forward the order is inverted: freeze meta.md
FIRST, fire the batch, then iterate tests/solution against Re-eval. So a meta.md question is now
expensive-if-late and free-if-now, and I audited the freeze before spending anything.

### Freeze audit - meta.md is freezable as-is

Swept all 93 tests for the class that has forced four consecutive meta.md rounds (a test pinning
behavior meta.md does not state). Method: extracted every explanatory `require` message (72 unique)
and traced each to a description sentence, rather than re-reading test bodies.

Everything traced. Three soft spots, none actionable:

- `..._UnbufferedWithWaitingReceiver_SendsOneThroughRendezvous` asserts a waiting receiver is room
  for one value on an unbuffered channel, which meta.md never says and which reads against
  "(an unbuffered channel is always full)". NOT unstated: base `trySend` hands the value to a
  waiting receiver BEFORE checking capacity, and base `SendNonblocking` is exactly `trySend`, so
  this is unmodified behavior of an existing public method that `SendAllNonblocking` is defined on
  top of. `IsFull` is a capacity predicate; "as many as fit" is not. Left alone.
- `..._OnFullDropOldestChannel_IsReady` (11 kills): readiness follows from the stated eviction
  policy, and it is the same derivation needed to implement the policy at all.
- `SelectAll_MultipleDefaults_AllFireInGivenOrder`: a fired Default is "handled", covered by
  "returns how many it handled".

**Decision: no meta.md change.** Deliberate, and the asymmetry is the reason - if a reviewer does
flag the rendezvous test, deleting it is a test.patch edit and therefore re-eval-eligible at 30%.
That option only exists because no Solution Quality finding demands that test, unlike the four
rounds where the test was load-bearing and the sentence had to be added.

### Fixed: comment convention violation (CLAUDE.md CRITICAL RULE), found during the sweep

solution.patch carried **185 comment lines on 727 added (25%)** against a repo that runs ~8%, incl.
27 doc-comment blocks (82 lines). The convention is split cleanly by package, verified against base:

| Package | Base convention | Was | Now |
|---|---|---|---|
| `internal/sync/channel.go` | 17 funcs / **0** documented; interface documents **0 of 6** methods; 21 inline comments (`trySend` style) | 11 verbose interface docs + 6 decl docs | inline "why" comments only |
| `internal/sync/selector.go`, `internal/workflowstate/*` | 0 documented | 9 decl doc blocks | none |
| `workflow/channel.go`, `select.go`, `signal.go` | docs ARE convention, **1-2 lines** (`// NewChannel creates a new channel.`) | 4-5 line blocks | compressed to 1-2 lines |

Also reverted a drive-by edit to a BASE doc comment (`NewBufferedChannel`), which had been widened
to mention the default policy though its behavior did not change.

Result: **727 -> 619 raw added, 185 -> 77 comment lines.** `internal/sync/channel.go` now 24/292 =
8.2% against base 21/256 = 8.2%; `workflow/channel.go` 21/71 = 30% against base 10/35 = 29%.

**`human-effective` unchanged at 315.** Removing 108 comment lines moved the effective count by
zero, confirming comments were never carrying the floor (CLAUDE.md: "comments are dead weight for
Counter 2").

### Validation

- gofmt clean; `go build ./...` OK; `go vet` OK
- new **93/0**, 3x identical; base **157/0**, 3x identical
- solution.patch: reverse-applies to the worktree exactly, forward-applies cleanly to pristine BASE,
  test.patch applies on top. ASCII, LF. 26732 bytes (was 35523)
- meta.md and test.patch **byte-identical** to Attempt 52 (test.patch md5 78d7310e...)
- Test count unchanged at 93; no test touched

### Carry-forward

Two rules now interact and the order matters: the comment strip was solution-only, so it was
re-eval-eligible and could have waited - but doing it before the batch costs nothing, while doing it
after would stale the batch and spend a re-eval on a purely cosmetic change that cannot alter a
single verdict. **Bank every non-solver-visible cleanup before the first batch anyway; re-eval is
insurance for findings you could not predict, not a reason to defer work you can already see.**

## Attempt 54 - Batch 7: 0/5 with two runs at 92/93; dropped the single over-strict axis

### The batch

5x Nova, **0/5**, all FAIL_MISSED_REQUIREMENT. Auto Review returned **Approved, 3/3 / 3/3 / 3/3**.
Full table in eval-results.md. The shape:

| Run | New tests | Failures |
|---|---|---|
| Nova_2 | **92/93** | arrival-order ONLY |
| Nova_3 | **92/93** | arrival-order ONLY |
| Nova_1 | 87/93 | arrival-order + 5 scheduler-resumption |
| Nova_4 | 87/93 | arrival-order + 5 scheduler-resumption |
| Nova_5 | 48/93 | never built the workflow wrapper layer |

`Test_ChannelDrain_PreservesArrivalOrder_AcrossAReceiveAndAnInterleavedSend` killed **4 of 5** and
was the ONLY failure in both near-miss runs, at the identical assertion: line 366,
`require.True(t, c.SendNonblocking(3))`.

Mechanism: agents promote the blocked sender's value into the slot freed by `ReceiveNonBlocking`,
refilling the buffer, so the later `SendNonblocking(3)` returns false. The reference keeps the
pending item in place in the arrival-ordered queue and lets the later send take the freed capacity.

### Fairness was unanimous, so this was calibration not unfairness

All five evaluators: `description_clear=True`, `tests_deterministic=True`, `difficulty=challenging`,
`agent_blame_unfair=False`, `blocker_detected=False`, `was_mentioned_in_description=True`. Nova_3's
evaluator quoted the meta.md clause directly. **0% is a hard reject regardless of fairness**, so the
question was never "is this fair" but "which axis do I relax".

### Why I did not need a re-eval to choose

The per-test JUnit data already gives the paired answer a re-eval would have produced: both near-miss
runs failed nothing else, so removing that one test flips them to passes -> **2/5 = 40%**, with the
scheduler-resumption family still killing the other three. Re-eval steers when you cannot read the
counterfactual off the artifacts; here it was already readable for free. **Save the agent-runs and
read them BEFORE deciding whether to buy a re-eval.**

### Why relax the test rather than clarify the description

Considered and rejected: promoting the concessive clause to an explicit rule. The clause carries the
core design insight (freed capacity goes to the later arriving send, not to an already-blocked
sender). Stating it plainly hands agents the one non-obvious decision in the whole problem, and would
likely push the rate past the 50% ceiling into too-easy reject. It is also solver-visible, so it
costs a full batch instead of a re-eval. Relaxing the test keeps the trap out of reach while removing
the axis that made the problem unsolvable.

### FP consideration

Letting Nova_2/Nova_3 pass is NOT a false positive. The meta.md sentence is concessive: "A value
already held by a blocked sender became available before any send that arrives later, even if that
later send is the one that succeeds into newly freed capacity." It constrains ORDERING in the case
where the later send succeeds; it does not mandate that the send succeed. An implementation where
the later send fails does not contradict it, so the requirement is not violated by the passing runs.

**Known residual:** that clause is now described-but-untested. Left deliberately - editing meta.md
would forfeit re-eval eligibility, and the clause remains true of the reference. If a reviewer flags
it, trimming the clause is a meta.md edit and costs a full batch.

### Change

Deleted `Test_ChannelDrain_PreservesArrivalOrder_AcrossAReceiveAndAnInterleavedSend` (28 lines) and
its `test.sh` registry entry. **93 -> 92 tests.** No other test touched. Its unique coverage was the
capacity competition itself, which is intrinsic - a later send can only race a blocked sender when
they compete for one freed slot - so there was no way to keep the ordering assertion without the
axis that made it unsolvable. Peek-non-destructiveness remains covered by
`Test_ChannelPeek_BlockedSender_DoesNotResolveSend`.

### Validation

- gofmt clean; new **92/0** 3x identical; base **157/0** 3x identical
- Round trip from pristine BASE: test.patch alone -> **92/92 fail** (F2P clean);
  + solution.patch -> new 92/0, base 157/0
- test.patch: 5 files, test.sh `new file mode 100755`, ASCII/LF, no banned markers
- **meta.md byte-identical** (md5 `017f6345...`) - required for the Re-eval button to appear
- Deliverables changed this round: `test.patch` (md5 `6ac96db6`) and `solution.patch` (md5
  `13b31c80`, the Attempt-53 comment cleanup). Both re-eval-eligible, so the cleanup rides free
  exactly as predicted in Attempt 53.

### Carry-forward

**Batch 6 -> 7 shows the Attempt-45 fix landed.** The scheduler-resumption family failed in ALL five
runs of batch 6; in batch 7 it fails in 3 of 5 and is absent from the two best runs. A stated
requirement converted from universal blocker to partial discriminator - which is what a fair trap
should look like.

**New law candidate:** when a batch reads 0%, per-test kill counts tell you whether you have a broad
spec gap (batch 6: one family failing everywhere) or a single over-strict axis (batch 7: one
assertion, two otherwise-perfect runs). The two demand opposite fixes - state the requirement vs.
drop the assertion - and the JUnit data distinguishes them for free.

## Attempt 55 - Batch 8: 30% pass, one flagged FP plus one the panel missed; added the missing regression guard

### Result

Re-eval landed 2/5, a further 5 fresh runs added a pass: **3/10 = 30%**, in band and lower than the
40% my n=5 extrapolation predicted. Auto Review had already returned Approved 3/3/3.

### The FP

Panel reviewed all three passers: #1 genuine, **#2 FALSE POSITIVE**, #3 genuine.

The FP is **Nova_7**: it rewrote ordinary `Select` to route through a shared `readyCase()` helper
that skips `defaultCase` on the first pass. Base `Select` scans cases in argument order and
`defaultCase.Ready()` returns `true` unconditionally, so on base a `Default` listed FIRST fires even
when a later case is ready. Documented at `docs/source/includes/_guide.md:550`. My 92-test suite had
no guard, so a documented-behavior regression passed.

Verified the reference is clean: it preserves base `Select` verbatim, swapping only `cs.Yield()` for
`yieldWaitingToSend(cs, cases)`, and confines the deferred-default rule to `SelectAll`.

### What the panel missed

**Nova_2 has the same regression.** Its `Select` skips defaults on the first pass too ("Defaults are
considered only after every other case has been checked"), inline rather than via a named helper. The
panel flagged only the run whose helper was called `readyCase`. **True FP count was 2 of 3, not 1.**

Lesson: an FP panel finds the defect it can name. Reading every passer's diff for the SAME defect
class the panel described is worth doing on every FP report - the second instance was free to find
once I knew the shape, and shipping the fix without it would have left a known FP live.

### Fix - test.patch only, so re-eval-eligible

Added 4 tests, **92 -> 96**:

- `Test_Select_EarlierDefaultWinsOverALaterReadyCase` (discriminating)
- `Test_WorkflowSelect_EarlierDefaultWinsOverALaterReadyCase` (discriminating, cross-package)
- `Test_Select_LaterDefaultLosesToAnEarlierReadyCase` - the opposite direction, so the suite pins
  that `Select` is POSITIONAL rather than "Default always wins". Both-directions is the pattern
  Attempt 41 established.
- `Test_ChannelDrain_BufferedAndMultipleBlockedSenders_InOneCall` - closes the reviewer's
  "not discriminating" coverage note by exercising mixed-source Drain ordering directly instead of
  only through `TryCloseDraining`.

### Fairness of a regression guard with no description sentence

This is the 5th time a test has pinned behavior meta.md does not state, but it is NOT the same class.
The previous four pinned NEW behavior the solution introduced, which needs a contract sentence. This
pins EXISTING documented behavior on an API the task never asks to change. That needs no sentence -
"no regressions" is a standing rubric requirement, the behavior is in the repo's own docs, and base
passes it. Requiring a description sentence for it would mean enumerating the entire existing API in
every prompt. Recorded here so the reasoning is available if challenged.

### Trap-proof (local differential harness, real agent patches)

| Passer | 92-test | 96-test |
|---|---|---|
| Nova_2 | PASS | **94/96** - fails both new Select tests |
| Nova_7 | PASS | **94/96** - fails both new Select tests |
| Nova_8 | PASS | **96/96** - stays genuine |

Surgical: only the two intended discriminators fire. **Projected rate 1/10 = 10%.**

First attempt at this harness was wrong and I caught it: I had a `git checkout-index -a -f` in the
loop, which restored every file from the pristine index and wiped each agent patch, producing a
meaningless 96/96-fail for all three. A differential harness that reports EVERY test failing is
measuring its own setup, not the agent - verify the agent patch applied and the tree builds before
trusting any number.

### Declined

- **Re-adding the deleted arrival-order test** (reviewer coverage suggestion, advisory). That test
  produced 0/5 in batch 7, and two independent FP adjudicators have now ruled the clause it pinned is
  a concessive clarification rather than a mandate. Re-adding it would re-create the unsolvable axis
  the adjudicators say was never required.
- **Weakening `Test_SignalChannel_OmittedCapacity_UsesBufferedDefault`** (advisory warning that
  asserting the literal 100 is repo-specific). Verified it is discoverable: base
  `internal/workflowstate/signalchannels.go:33` is `sync.NewBufferedChannel[T](100)`, the exact line
  a solver must edit to add `WithSignalChannelCapacity`, and meta.md's "uses the existing default
  capacity" points at it. This is the single permitted codebase-inferable requirement. Weakening it
  would drop a real discriminator to satisfy an advisory note.
- **All four meta.md trim suggestions and the internal/sync-mirroring note.** Every one is
  solver-visible: a full-price batch each, for advisory-only warnings, on a description holding 3/3.
  meta.md stays frozen.

### Validation

- gofmt clean; `go vet` clean
- new **96/0** 3x identical; base **157/0** 3x identical
- F2P from pristine BASE: test.patch alone -> **96/96 fail**
- test.patch: 5 files, test.sh `new file mode 100755`, ASCII/LF, no banned markers
- **meta.md byte-identical** (`017f6345...`); **solution.patch unchanged** (`13b31c80...`)
- Only `test.patch` changed this round (`d6a8a99a...`) -> re-eval eligible

### Risk to watch

1/10 is in band and at the hard/high-payout edge, but it is one run from reading 0/10 = unsolvable on
a fresh batch. Re-eval is PAIRED so it will reliably report 1/10 on this population; that is steering,
not confirmation. If a fresh batch reads 0/10, the lever is to drop
`Test_Select_EarlierDefaultWinsOverALaterReadyCase`'s workflow mirror or relax the scheduler-resumption
cluster - both test-side, both re-eval-eligible.

## Attempt 56 - Batch 9 (1/10 as predicted); Auto Review Revision Requested: fixed a real wake-up bug and re-aligned the ordering contract

### Batch 9

**1/10 = 10%**, exactly the projection from the Attempt-55 differential. Nova_2 and Nova_7 came back
`FAIL_REGRESSION` - the Select/Default guard did precisely its job. The single passer (Nova_8) was
adjudicated a genuine pass at HIGH confidence. Description held 3/3.

### Finding 1 (S1 x2, High): Select(Drain) and SelectAll(Drain) can deadlock

Claim: parent parks in `Select(Drain(...))`, a later-spawned child blocks sending on an unbuffered
channel, neither marks progress, `Scheduler.Execute` returns with the Drain case ready but unhandled.

**Verified, and verified it is PRE-EXISTING.** Probe on untouched BASE:

| Variant | handled? |
|---|---|
| BASE `Select(Receive)` | **false** |
| mine `Select(Receive)` | false (identical to base, no regression) |
| mine `Select(Drain)` | false |
| mine `SelectAll(Drain)` | false |

Base `canReceive()` returns true when `len(c.senders) > 0`, and base `Send` appends its callback and
yields WITHOUT `MadeProgress`, so base `Select(Receive)` strands exactly the same way. My `Drain`
inherited it by doing what meta.md promises: "ready whenever `Receive` would be".

**Fixed anyway rather than contested** - it is a real gap in MY new API, and the fix adds substance.
Added a `receiveWaiter` list on `channel[T]` mirroring the existing `sendWaiter` one, notified at
every point a value becomes takeable (pending publication in `Send`, both buffered appends in
`trySend`, and `Close`), with `channelDrainCase` registering through a new `receiveWaiterCase`
interface in `yieldWaitingToSend`. After: `Select(Drain)` and `SelectAll(Drain)` both handled=true.

**Deliberately did NOT change `Receive`.** It is an untouched existing public API and altering its
semantics is precisely the unrequested-change class that produced this batch's two `FAIL_REGRESSION`
verdicts. The base probe is the evidence if this is questioned.

### Finding 2 (T3/T4, High): the missing overtaking test

The reviewer asked for exactly the test I deleted in Attempt 54, and the FP adjudicator - while
clearing the passer - said explicitly: "If this lazy-promotion timing is actually required, the prompt
should state it explicitly and the verifier should grade the pre-resume window."

**So Attempt 54's call was wrong, and the right fix was the one I rejected then.** I dropped the test
because the clause was concessive; the correct move was to make the clause a mandate AND keep the
test. Deleting a test to fix a 0% batch is only right when the requirement is genuinely optional -
here it was load-bearing and merely under-stated.

meta.md now says: "Freeing room does not hand that room to a coroutine already blocked sending: a
send arriving before that coroutine resumes takes the room, and still orders behind it." Restored the
test as `Test_ChannelDrain_LaterSendTakesRoomFreedWhileAnOlderSenderIsStillBlocked`.

This does not conflict with `Test_ChannelSend_ResumedSender_OccupiesCapacity`, which resumes the
sender FIRST. Together they now pin the timing on both sides of the resume.

### Fairness sweep on my own new tests

The differential showed the batch-9 passer failing 4 tests: the overtaking test plus all 3 wake-up
tests. The overtaking rule was now stated - the wake-up behavior was NOT, and base `Receive` does not
do it, so those 3 tests were pinning unstated behavior. Caught before shipping. meta.md now also says
"a value arriving while such a case waits must also run it".

**This is the 6th instance of the class, and the first time I caught it myself pre-submit rather than
being told.** The trigger that worked: run the differential, then ask of EVERY newly-failing test
"which meta.md sentence says this?" - not just the tests I added deliberately.

### Changes

- solution.patch: receive-waiter mechanism (**human-effective 315 -> 348**)
- test.patch: **96 -> 100** (overtaking + 3 wake-up regressions)
- meta.md: 2 new mandates, **497 words**, ASCII, no em dashes

### Validation

- gofmt/vet clean; new **100/0** 3x identical; base **157/0** 3x identical
- F2P from pristine BASE: **100/100 fail**
- both patches verified in sync with the worktree; test.sh mode 100755; no banned markers
- comment count 77 (unchanged density; stripped the one doc comment I had added in internal/, per
  the Attempt-53 convention)

### Risk - read this before the next batch

All three deliverables changed, so this is a FULL-PRICE batch, no re-eval. On the batch-9 solution
population the new suite would read **0/10**. That is NOT the expected fresh-batch rate: every one of
those four failures is on behavior that population was never told about. The explicit mandates are
the lever that should convert them from unguessable to implementable. If a fresh batch still reads
0/10, the cheap next move is test-side (drop the workflow-level wake-up mirrors, keep the sync one),
which IS re-eval-eligible.

## Attempt 57 - Solution Quality FAIL: my own Attempt-56 fix left an unbuffered rendezvous gap

### The finding, and why it is mine

"A waiting Drain select drops nonblocking deliveries on unbuffered channels." Correct, High, and a
direct consequence of the Attempt-56 fix: I made `receiveWaiter` a PROGRESS-NOTIFICATION hook but not
a RENDEZVOUS TARGET. `trySend` accepts only into `c.receivers` or buffered capacity, so on a
zero-capacity channel with a Drain case parked it took neither path, returned false, and counted a
drop. Reachable through `WithSignalChannelCapacity(0)` plus a live signal, and through
`workflow.NewChannel` + `SendNonblocking`.

Reproduced before touching anything:

```
SendNonblocking on unbuffered w/ parked Drain: ok=false dropped=1
after second Execute: drained=[]
```

**The obligation is one I created.** Attempt 56 added "a value arriving while such a case waits must
also run it" to meta.md. Before that sentence this corner was arguably unspecified; after it, the
solution contradicted a stated promise. Adding a contract sentence widens what the solution has to
honour - the sentence is not free, and I did not re-audit the solution against it at the time.

### Fix

Added `hasHandoffRoom()`: a parked receive-waiter is a consumer, so it can accept a value with no
buffered room, capped at one value per waiter (`bufferedN < size+len(receiveWaiters)`). Used it in
exactly two places:

- `trySend`'s accept path, so a nonblocking send reaches the parked case instead of dropping
- `canSend()`, so the readiness predicate agrees with `trySend` - otherwise a parked Select send case
  would never wake for a send that would now succeed

**Deliberately NOT used in `IsFull()`** (`!c.hasCapacity()`) or `Cap()`. Verified after the fix:
`ok=true dropped=0 drained=[1]` while `isFull=true cap=0`. The unbuffered channel still reports full
with capacity 0, so "an unbuffered channel is always full" holds and
`Test_ChannelIsFull_ReportsBufferAndUnbufferedState` is untouched. Also left `tryResolvePending`
alone: a blocked sender's value is already visible to Drain as a pending item, so it needs no
handoff slot.

### Tests

**100 -> 102.** `Test_SelectDrainCase_UnbufferedNonblockingSendReachesTheParkedCase` and its workflow
mirror, each asserting the send succeeds, nothing is dropped, the handler receives the value, AND
that `IsFull`/`Cap` still report the unbuffered channel as full with capacity 0 - so the test pins
the fix without licensing a capacity change.

No meta.md change: Attempt 56 already states the requirement. This round is solution + tests only,
which is **re-eval-eligible**.

### Validation

- gofmt/vet clean; new **102/0** 3x identical; base **157/0** 3x identical
- F2P from pristine BASE: **102/102 fail**
- `human-effective` 348 -> **351**; comment count unchanged at 77; stripped the one doc comment I had
  again drifted into `internal/`

### Carry-forward (new law candidate)

**A contract sentence is a liability as well as a fix.** Every meta.md sentence added to make a test
fair also enlarges the surface the reference must satisfy. Attempt 56 added the wake-up mandate to
justify three tests and shipped a solution that violated it in the zero-capacity corner. The check
that would have caught it: after adding any contract sentence, re-read the SOLUTION against the new
sentence's full domain - here, "a value arriving" across buffered, unbuffered, and drop-oldest
channels - not just against the scenario the new tests exercise.

## Attempt 58 - Batch 10: 0/5, one insight short; sharpened the no-stranding sentence

### What the batch says

0/5, but the diagnosis is the cleanest yet. Nova_2 landed **97/102** failing ONLY the five
scheduler-resumption tests, and its evaluator traced all five to a single root cause: Drain takes the
value and clears the sender without calling the sender coroutine's `MadeProgress`. Every fairness
field is clean (`description_clear`, `was_mentioned_in_description`,
`was_inferable_from_codebase_excluding_tests` all True; difficulty `challenging`; solvable).

**Two things worth banking:**

1. **The Attempt-56 mandate worked.** The overtaking test - the exact test that produced 0/5 in batch
   7 when the rule was only concessive - does not appear anywhere in batch 10's kill list. Stating a
   requirement plainly converted an unguessable trap into one agents implement. That is the cleanest
   evidence yet for the "state it, do not delete it" direction, and it retroactively confirms
   Attempt 56 over Attempt 54.
2. **The Attempt-57 rendezvous tests are not the blocker** (3/5, and absent from the near-miss).

### Why deleting tests is NOT the lever here

The five failures are five VIEWS of one missing insight, so dropping any subset leaves Nova_2 still
failing the rest. Flipping it would mean deleting all five - which is the explicit no-stranding
contract and the problem's central difficulty. Unlike Attempt 54, where the over-strict axis was one
assertion, here the axis IS the problem.

### Statistics before panicking

Pooled with batch 9 (1/10), this is 1/15 ~ 7%. At a true 10% rate **P(0 of 5) = 0.9^5 = 59%**, so
0/5 is more likely than not for a solvable problem here. This batch is underpowered, not proof of
0%. It still cannot be submitted, because the current artifact has no demonstrated agent pass.

### Change - discoverability, not difficulty

The gap is not that the behavior is unstated; it is that agents do not connect "proceeds on its own"
to the fact that the scheduler STOPS once every coroutine looks blocked. Sharpened, without naming
`MadeProgress` or any API:

> ...both **resume before the scheduler run that drained them finishes**, with no further channel
> activity needed.

This restates when the existing requirement must hold; it adds no new behavior, and the reference
already satisfies it. Freed the words by trimming two verbose phrases the reviewer had also flagged.
**499 words**, ASCII.

### Deliverables

**meta.md ONLY** (`8eeb7e45`). test.patch (`a7dc653e`) and solution.patch (`d62ec572`) are
byte-identical - no code or test changed, so nothing needed re-validating. Solver-visible change, so
**full-price batch, no re-eval**; a re-eval could not help anyway, since it re-grades existing
solutions and what we need is new ones.

### If the next batch is still 0

Then the resumption trap is genuinely at ~100% miss and the honest options are (a) more runs to find
the ~7-10% passer, or (b) split the cluster so the direct-Drain case and the parked-send-case are
separately winnable - i.e. accept a solution that resumes blocked senders but not parked select send
cases, by dropping tests 3-5 and keeping 1-2. That is test-side and re-eval-eligible, and it is the
first genuine relaxation available if this clarification does not move the rate.

## ACCEPTED 2026-09-04 - Olympus, 2/10 = 20%

Auto Review Approved: Description 3/3, Tests 3/3, Solution 3/3. Both passers cleared the FP panel at
high confidence; the only dissents were probes the adjudicator ruled unfair against the prompt.

Finalized via `olympus-finalize`. Carried forward:

- **`failure-patterns.md`**: new pattern **F-20** (sibling-API contamination, 8/10, band decider);
  F-10 evidence extended with this problem's 4/10 cross-product cell; new laws **L37** (an FP panel's
  defect report is difficulty, and it names the instance not the class), **L38** (when one fair trap
  kills ~100%, restate WHEN it must hold rather than deleting the cluster), **L39** (a contract
  sentence is a liability - re-audit the reference against every sentence you add); full dossier in
  section 2; targeting-table row.
- **Skills**: `olympus-hunt` (F-20 seam row + grep probe), `olympus-author` (targeting bullet,
  difficulty lever #2, DESIGN checklist item; lever list renumbered - it had duplicate numbers),
  `olympus-harden` (two new diagnosis rows: the 0%-binomial rule and the FP-report-as-trap rule).
- **Instructions**: `lessons-learned.md`, `KNOWLEDGE.md`, `PLAYBOOK.md`,
  `olympus-extreme-complexity-guide.md`, `PROBLEM-PROFILES.md`, `SHAPES.md` (O-Composite-add
  confirmed outside compiler stacks), `PATTERNS-ADVANCED.md` (Pattern 34).
- **`approved-problems/README.md`**: index entry.

Agent-run artifacts deleted after mining; all measured counts live in `eval-results.md` above and in
`failure-patterns.md`. The worktree clone was removed and is re-clonable from `BASE_COMMIT.txt`
(`48e811947bece0a2a9993d85edcf9a0f3a7e486b`).
