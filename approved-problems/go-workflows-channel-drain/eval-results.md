# eval-results.md - go-workflows-channel-drain

## Batch 6 (2026-09-02) - 5x Nova, solver Nova / evaluator Nova

**0/5 passed.** Baseline clean in every run (157/157, deterministic). New suite f2p=81.

| Agent | Evaluator | Verdict | New tests | Files touched | LOC | Failure reason |
|---|---|---|---|---|---|---|
| Nova_Nova_1 | Nova | FAIL | 45/81 | 10 | 726 | Drain does not resume scheduler-blocked senders; CloseDraining panics with blocked senders present |
| Nova_Nova_2 | Nova | FAIL | 44/81 | 11 | 663 | Sender ordering wrong; missing scheduler resumption; CloseDraining panics |
| Nova_Nova_3 | Nova | FAIL | 45/81 | 9 | 921 | CloseDraining calls Close() before Drain() so it panics; Drain does not wake the scheduler |
| Nova_Nova_4 | Nova | FAIL | 53/81 | 10 | 787 | CloseDraining explicitly panics on blocked sender; Drain flips the sender flag but never notifies the scheduler |
| Nova_Nova_5 | Nova | FAIL | 76/81 | 11 | 725 | NEAR MISS. Only the 4 scheduler-resumption tests + arrival-order across an interleaved send |

### Decisive finding: 4 tests failed in ALL 5 runs

- `Test_ChannelDrain_DirectDrain_ResumesBlockedSenderUnderScheduler`
- `Test_SelectDrainCase_ResumingBlockedSender_LetsSchedulerRunIt`
- `Test_SelectSendCase_DrainFreeingBufferedRoom_LetsSchedulerRunIt`
- `Test_WorkflowSelectSendCase_DrainFreeingBufferedRoom_LetsSchedulerRunIt`

All four pin the same requirement: draining must leave no coroutine stranded. meta.md never stated it
(keyword scan for progress/resume/schedul/wake/unblock returned nothing outside the Drain definition).
Every one of the five platform evaluators independently named "scheduler resumption" as the cause.
This is the "all agents fail for the same exact reason" unfairness signal, and it is what produced 0%.

Fixed in Attempt 45 by stating the requirement in meta.md. Tests unchanged.

### Non-blocking observations

- Spread is otherwise healthy: 44 / 45 / 45 / 53 / 76 of 81. No other clustering.
- `Test_ChannelCloseDraining_IncludesBlockedSender_ClosesWithoutPanicking` failed 4/5 but Nova #5
  passed it, and it is derivable from the CloseDraining/TryCloseDraining contrast. Fair trap, kept.
- Deterministic: the same 4 tests fail in every run. No flakiness.
- Platform p2p is 157 (its own node-id set), not the 314 our local base mode runs. Baseline passed
  157/157 in all 5 runs, so no regression signal is being lost.

## Batch 7 (2026-09-03) - 5x Nova, solver Nova / evaluator Nova

**0/5 passed.** Baseline clean in every run. New suite 93 tests.

| Agent | Verdict | New tests | Files | +LOC | Prompt tokens | Failure reason |
|---|---|---|---|---|---|---|
| Nova_Nova_1 | FAIL_MISSED_REQUIREMENT | 87/93 | 9 | 897 | 3.7M | arrival-order + 5 scheduler-resumption |
| Nova_Nova_2 | FAIL_MISSED_REQUIREMENT | **92/93** | 13 | 1026 | 7.2M | arrival-order ONLY |
| Nova_Nova_3 | FAIL_MISSED_REQUIREMENT | **92/93** | 11 | 969 | 14.1M | arrival-order ONLY |
| Nova_Nova_4 | FAIL_MISSED_REQUIREMENT | 87/93 | 11 | 945 | 6.3M | arrival-order + 5 scheduler-resumption |
| Nova_Nova_5 | FAIL_MISSED_REQUIREMENT | 48/93 | 11 | 856 | 8.4M | never built the workflow wrapper layer |

Trajectories are `compacted: true` with `steps=4`, so step count is not a message count; token volume
(3.7M-14M prompt) and 9-13 files / 856-1026 added LOC per run confirm long-horizon.

### Decisive finding: ONE test is the entire gap

`Test_ChannelDrain_PreservesArrivalOrder_AcrossAReceiveAndAnInterleavedSend` kills **4 of 5**, and is
the ONLY failure in the two near-miss runs. Failure point is identical in both: line 366,
`require.True(t, c.SendNonblocking(3))`.

Mechanism: the agents eagerly promote the blocked sender's value into the buffer slot freed by
`ReceiveNonBlocking`, so the buffer is full again and the later `SendNonblocking(3)` returns false.
The reference keeps the pending item in place in the arrival-ordered queue and lets the later send
take the freed capacity.

Second cluster (3/5): the scheduler-resumption family, unchanged from batch 6 in shape but now only
hitting Nova_1/4/5 rather than everyone.

### Fairness: unanimously clean

All five evaluators: `description_clear=True`, `tests_deterministic=True`, `difficulty=challenging`,
`agent_blame_unfair=False`, `blocker_detected=False`, `was_mentioned_in_description=True`. Nova_3's
evaluator quoted the meta.md clause directly. Auto Review returned **Approved, 3/3 / 3/3 / 3/3**.
Nova_2 flagged an environment blocker only for optional backend services (MySQL/Postgres), which
reproduces on pristine BASE and does not touch the failing behavior.

**So this is not an unfairness problem. It is calibration: 0% = reject regardless of fairness.**

### Batch 6 -> 7 movement

Batch 6 was 45/81, 44/81, 45/81, 53/81, 76/81 with the scheduler-resumption family failing in ALL
five. Attempt 45 stated that requirement; batch 7 shows it now landing for 2 of 5. The remaining
0% is a single, much narrower trap rather than a broad spec gap.

## Batch 8 (2026-09-03) - Re-eval (5) + fresh 5, then 10x Nova

**3/10 passed = 30%.** In band. Baseline clean in every run.

| Verdict | Runs |
|---|---|
| PASS_LEGITIMATE | Nova_2, Nova_7, Nova_8 |
| FAIL_MISSED_REQUIREMENT | Nova_1, Nova_3, Nova_4, Nova_5, Nova_6, Nova_9, Nova_10 |

### FP review outcome

Panel reviewed all three passers: #1 genuine, **#2 FALSE POSITIVE**, #3 genuine. Both "genuine"
adjudications independently ruled that the meta.md concessive clause is "an ordering clarification,
not a behavioral mandate" - confirming the Attempt-54 reading.

The FP (panel #2 = **Nova_7**): rewrote ordinary `Select` to route through a shared `readyCase()`
helper that skips `defaultCase` in the first pass, so a `Default` listed BEFORE a later ready case no
longer fires. Base `Select` scans in argument order and `defaultCase.Ready()` returns `true`
unconditionally, so base fires the Default. Documented at `docs/source/includes/_guide.md:550`:
"A `Default` case is executed if no previous case is ready to be selected." Genuine regression of
existing public behavior, and the 92-test suite had no guard for it.

### My own finding the panel MISSED

**Nova_2 has the identical regression.** It rewrote `Select` so "Defaults are considered only after
every other case has been checked" - same observable behavior change, implemented inline instead of
via a named `readyCase()` helper. The panel flagged only the run that named the helper. So the true
FP count in this batch was **2 of 3 passers, not 1**.

### Differential harness (96-test suite vs the three passers, run locally)

| Passer | 92-test | 96-test | Change |
|---|---|---|---|
| Nova_2 | 92/92 PASS | **94/96** | now FAILS (both new Select tests) |
| Nova_7 (flagged FP) | 92/92 PASS | **94/96** | now FAILS (both new Select tests) |
| Nova_8 | 92/92 PASS | **96/96** | stays a genuine pass |

Surgical: the only failures are the two discriminating tests. The non-discriminating direction
(`Test_Select_LaterDefaultLosesToAnEarlierReadyCase`) and the mixed-source Drain test pass on all
three, so they add coverage without inflating the kill.

**Projected rate after the fix: 1/10 = 10%.**

## Batch 10 (2026-09-03) - 5x Nova, fresh solves against the Attempt-56/57 artifact

**0/5.** Fresh run IDs (not re-graded batch-9 solutions), so these agents DID see the new mandates.
Baseline clean in every run. New suite 102 tests.

| Run | New tests | Failures |
|---|---|---|
| Nova_2 | **97/102** | the 5 scheduler-resumption tests ONLY |
| Nova_1 | 89/102 | 13 |
| Nova_3 | 90/102 | 12 |
| Nova_4 | 47/102 | 55 |
| Nova_5 | 47/102 | 55 |

### The Attempt-56 mandates WORKED

`Test_ChannelDrain_LaterSendTakesRoomFreedWhileAnOlderSenderIsStillBlocked` does not appear in the
kill list at all. Stating the freed-capacity rule converted it from the trap that produced 0/5 in
batch 7 into a requirement agents now implement. The Attempt-57 rendezvous tests kill only 3/5 and do
not block the near-miss.

### Sole blocker: the scheduler-resumption cluster, 5/5

| Test | Kills |
|---|---|
| ChannelDrain_DirectDrain_ResumesBlockedSenderUnderScheduler | 5/5 |
| SelectDrainCase_ResumingBlockedSender_LetsSchedulerRunIt | 5/5 |
| SelectSendCase_DrainFreeingBufferedRoom_LetsSchedulerRunIt | 5/5 |
| SelectAll_DrainFreeingBufferedRoom_LetsSchedulerRunIt | 5/5 |
| WorkflowSelectSendCase_DrainFreeingBufferedRoom_LetsSchedulerRunIt | 5/5 |

All five are ONE root cause. Nova_2's evaluator: "Drain marks blocked sender values as taken and
clears the sender list without calling the sender coroutine's MadeProgress method ... This accounts
for all five new failures." Verdict fields: `description_clear=True`,
`was_mentioned_in_description=True`, `was_inferable_from_codebase_excluding_tests=True`,
difficulty `challenging`, and the task is confirmed solvable.

### Statistical read

Pooled with batch 9 (1/10) this is 1/15 ~ 7%. At a true 10% rate, **P(0 of 5) = 0.9^5 = 59%** - 0/5
is MORE LIKELY THAN NOT for a solvable problem at this difficulty. This is an underpowered sample,
not evidence of unsolvability. But the current artifact has no demonstrated agent pass, so it cannot
be submitted on this batch.

## Batch 11 (2026-09-04) - 10x Nova graded (+1 scratched) - ACCEPTED

**2/10 = 20%.** Auto Review Approved, 3/3 / 3/3 / 3/3. Both passers cleared the FP panel at high
confidence. Baseline clean in every run. New suite 102 tests.

| Run | Verdict | Failed |
|---|---|---|
| Nova_2 | PASS_LEGITIMATE | 0 |
| Nova_5 | PASS_LEGITIMATE | 0 |
| Nova_10 | FAIL_REGRESSION | **2** - the Select/Default pair ONLY |
| Nova_11 | FAIL_REGRESSION | **2** - the Select/Default pair ONLY |
| Nova_9 | FAIL_MISSED_REQUIREMENT | 3 |
| Nova_8 | FAIL_MISSED_REQUIREMENT | 4 |
| Nova_6 | FAIL_MISSED_REQUIREMENT | 6 |
| Nova_4 | FAIL_MISSED_REQUIREMENT | 7 |
| Nova_1 | FAIL_MISSED_REQUIREMENT | 9 |
| Nova_7 | FAIL_MISSED_REQUIREMENT | 56 |
| Nova_3 | SCRATCHED (run.txt only) | - |

### Per-test kills (top)

| Kills | Test |
|---|---|
| 8/10 | Test_Select_EarlierDefaultWinsOverALaterReadyCase |
| 8/10 | Test_WorkflowSelect_EarlierDefaultWinsOverALaterReadyCase |
| 4/10 | Test_SelectDrainCase_UnbufferedNonblockingSendReachesTheParkedCase |
| 4/10 | Test_WorkflowSelectDrainCase_UnbufferedNonblockingSendReachesTheParkedCase |
| 3/10 | Test_ChannelSend_ResumedSender_OccupiesCapacity |
| 2/10 | the 5-test scheduler-resumption cluster (was 5/5 at batch 10) |
| 2/10 | Test_ChannelDrain_LaterSendTakesRoomFreedWhileAnOlderSenderIsStillBlocked |

**43 of 102 tests killed nothing** - the whole signal-backlog family, every Peek variant,
Cap/IsFull. Fairness and FP insurance, zero difficulty.

### The band decider

Nova_10 and Nova_11 scored **100/102**, failing ONLY the Select/Default pair. Without that pair the
batch reads **4/10 = 40%**, at the ceiling; with it, **2/10 = 20%**. That test came from the batch-8
FP panel report, not from the trap design. Promoted to `failure-patterns.md` as **F-20** and
`PATTERNS-ADVANCED.md` Pattern 34.

### Long-horizon (10 graded runs)

Median 11 files touched, 1026 added LOC, 11.2M prompt tokens. `trajectory.json` `steps` reads 4 with
`compacted: true` and is NOT a message count.

### Evaluator fairness fields

`description_clear: true` and `difficulty: challenging` in all 10. Failing runs that cited a
requirement marked `was_mentioned_in_description: true` and
`was_inferable_from_codebase_excluding_tests: true`.
