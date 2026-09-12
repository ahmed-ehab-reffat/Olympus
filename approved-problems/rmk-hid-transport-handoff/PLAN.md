# Plan — RMK lossless HID transport handoff

Status: **version 42 environment-verified; 0/10 calibration**

1. Completed the trajectory-informed startup gate and upstream ownership
   audit at the frozen pin.
2. Built independent bounded implementation modes and recorded the pure-test
   observation tradeoff.
3. Wrote the feature-request prompt, pure hidden suite, reference patch, and
   machine-independent JUnit wrapper.
4. Removed production code from `test.patch` and removed explicit family
   enumeration from the prompt after external review.
5. Began the title and opening sentence with “Add”.
6. Folded the standalone base-passing no-ghost assertion into the required
   positive offline-replay test; the base now fails every new test.
7. Replaced build-time channel inflation with bounded lazy reconciliation that
   passes while generated `REPORT_CHANNEL_SIZE` is exactly one.
8. Committed lockfiles for all three Cargo roots, removed Docker lockfile
   generation, added sibling-root offline preflights and required DBus tooling,
   and verified arbitrary-UID/network-disabled execution.
9. Repeated the exact-version nine-mutant false-positive audit; no incorrect
   survivor remains.
10. Passed baseline, focused, feature, Clippy, clean-application, JUnit-startup,
    and immutable-hash gates and froze version 7.
11. Corrected Docker for the platform's pre-patch build order, repeated the
    arbitrary-UID offline matrix and all nine mutants, and froze version 8.
12. Moved the RMK lock beneath randomized parent `.rmk-a01fa986/`, installed it
    only in the wrapper's disposable source copy, repeated every exact-version
    gate, and froze version 9.
13. Made Docker derive its own locks from the untouched checkout, added real
    RMK/Rynk build steps and complete locked fetches, pinned apt packages, made
    both patch orders commute, repeated every exact-version gate, and froze
    version 10.
14. Removed the public sentence that merely restated default `no_std`
    compatibility, repeated the exact matrix, feature checks, and nine-mutant
    audit, and froze version 11.
15. Warmed RMK's complete no-lock package resolution during the pristine image
    build, verified the newer graph offline as a non-root UID, repeated every
    exact-version gate, and froze version 12.
16. Made `/opt/cargo` explicit and arbitrary-UID-readable, cached the reported
    `bytemuck` 1.25.2 archive explicitly, aligned the randomized fallback lock
    byte-for-byte with Docker's authoritative lock, repeated every exact-version
    gate, and froze version 13.
17. Added a BLE host-notification steno probe and real reference delivery,
    restored representative public `Channel` methods through a compatibility
    wrapper, removed unused sibling locks and the wrapper toolchain override,
    replaced short new-test waits with deterministic polling, repeated the
    eleven-mutant audit and full matrix, and froze version 14.
18. Invalidated version 14 after fairness review, explicitly announced BLE
    Plover support in the prompt, replaced the private `BleHidServer` test seam
    with an in-memory HCI/GATT host-output probe, removed reference test-only
    layout workarounds, repeated the thirteen-mutant audit and every runtime,
    feature, patch-order, startup, and hash gate, and froze version 15.
19. Invalidated version 15 after directional and atomicity review, broadened
    BLE→USB to every enabled family, added a bounded producer/cutover race
    oracle, serialized route commit/reconciliation with state recording and
    enqueue in the reference, repeated fifteen isolated mutations and every
    baseline, focused, feature, Clippy, flake, patch-order, offline non-root,
    startup, and hash gate, and froze version 16.
20. Read all ten same-task trajectories, invalidated version 16, removed the
    private channel-alias test dependency and the public GATT service-location
    clause, stated the demonstrated per-family, single-transport, and Plover
    protocol boundaries, added four distinct probes across three feature lanes,
    restarted the 19-mutant audit, repeated the full offline/runtime matrix ten
    times, replayed every stored solver patch, and froze version 17.
21. Read all five `agent-runs2` trajectories and found that run 4 never reached
    behavior: the platform reset overlapping test files after a three-way
    `state.rs` merge failed, then compiled an impossible hybrid tree.
22. Moved hidden state behavior into randomized test-only module
    `handoff_verifier_7c91e4.rs`; run 4 now merges and executes real tests.
23. Added the five demonstrated semantic boundaries: offline nonblocking
    retention, dropped-neutral clearing, keyboard/media/system full-queue
    retention, all-family USB-only/BLE-only lifecycle, and explicit stale-route
    rejection in both directions.
24. Removed the 2,000-yield scheduling stress. An exact 16/16 survivor proved
    that no fair black-box deterministic oracle exists for other producer/setter
    races, so the prompt now scopes concurrency to the blocked-send case.
25. Restarted the false-positive audit, reproduced the combined version-17
    survivor, replayed all five stored patches, passed the 541/541 and 16-test
    matrices, three Clippy lanes, both patch orders, startup JUnit, and image
    gates, and froze version 18.
26. Read all five `agent-runs3` trajectories and identified the dominant
    false-negative mechanism: three solutions reconciled at the writers while
    fifteen hidden tests inspected only the legacy ordinary queues.
27. Eased the scope by removing focused all-family USB-only/BLE-only behavior,
    replaced state/queue inspection with real USB endpoint and BLE GATT host
    observation, and added one table-driven every-family dropped-neutral
    boundary.
28. Replayed all five stored patches. Two independent writer-side designs now
    pass 7/7, one fails only a real blocked-cutover leak, and two retain genuine
    descriptor integration compile errors.
29. Repeated the exact ten-mutant false-positive audit, 541/541 and 7-test
    matrices, three Clippy lanes, both patch orders, startup JUnit, and offline
    non-root image checks, then froze version 19.
30. Reopened design after review found that the blocked send was observed only
    on old USB/later USB and that no active-held state crossed a no-host gap to
    the other transport.
31. Added immediate BLE GATT observation of the pending send and an all-family
    active-BLE → none → USB writer replay phase without changing the public
    prompt or reference implementation.
32. Preserved fail-to-pass purity by combining the old-host blocked assertion
    with the new no-host replay phase; pristine again fails every one of seven
    focused testcases.
33. Repeated the eleven-mutant audit, all five stored replays, 541-test baseline,
    focused wrappers, three Clippy lanes, both patch orders, startup JUnit, and
    offline non-root focused matrix, then froze version 20.
34. Read the complete `agent-runs4` evidence and recorded the version-21 design
    gate before changing the prompt or verifier. Two independent writer-side
    solutions were legitimate passes; the remaining outcomes were real stale
    routing, incomplete lifecycle behavior, or descriptor integration errors.
35. Rephrased the blocked-send concurrency scope as natural issue prose without
    expanding it, and strengthened the host probes for per-packet stale output,
    all-family direct USB release, BLE-to-none, USB-to-none-to-BLE, offline-to-BLE,
    and the BLE-to-USB blocked-send boundary.
36. Repeated the exact 17-mutant audit with zero survivors, replayed all five
    stored patches, passed the 541/541 and 8-test matrices, three Clippy lanes,
    both patch orders, formatting, startup JUnit, and ten-run stability check.
37. Rebuilt Docker with `--no-cache` from the pristine repository and reproduced
    both complete baseline runs plus pristine 0/8 and reference 8/8 focused with
    networking disabled as UID/GID `12345:23456`, then froze version 21.
38. Reopened the trajectory-informed gate after review found that unrelated HID
    byte fragments could satisfy the Plover oracle and that capacity one could
    not distinguish clearing one stale packet from clearing the complete queue.
39. Replaced fragment scanning with a local HID-item parser and added a separate
    randomly named capacity-three lane that queues three stale packets while
    preserving the original capacity-one tests.
40. Repeated the exact 19-mutant audit with zero survivors, replayed all five
    stored patches, passed both 541-test baselines, the 0/9 and 9/9 focused
    matrices, three Clippy lanes, both patch orders, formatting, startup JUnit,
    ten-run stability, and offline arbitrary-UID containers, then froze version
    22 without a cold solver.
41. Reopened the trajectory-informed gate after review found that dropped
    neutral replacement reached only newly active USB and that the capacity-three
    stale probe covered only an old USB route.
42. Added real BLE-host observation for USB-full dropped neutral updates and ran
    the BLE GATT probe in the capacity-three lane with three distinct queued
    stale packets; removed evaluator-specific image framing from `test.sh`.
43. Repeated the exact 21-mutant audit with zero survivors, replayed all five
    stored patches, passed both 541-test baselines, the 0/10 and 10/10 focused
    matrices, three Clippy lanes, both patch orders, formatting, startup JUnit,
    ten-run stability, and offline arbitrary-UID containers, then froze version
    23 without a cold solver.
44. Reopened the trajectory-informed gate after review found that every hidden
    behavior module required `steno`, allowing the entire handoff feature to be
    absent from ordinary four-family builds.
45. Added a randomly named no-steno USB-writer probe and third wrapper lane.
    Pristine/reference now score 0/11 and 11/11 focused while both retain a
    541/541 baseline; formatting, no-steno warning-denying Clippy, and both
    patch orders pass. Per explicit user direction, the false-positive audit
    was not run, so version 24 remains an unapproved draft.
46. Reopened the trajectory-informed gate after strict fairness review found
    that the host probes imposed an unstated exact one-second completion
    deadline. Replaced those cutoffs with a named 30-second harness-only
    deadlock watchdog without changing any behavioral oracle.
47. Ran the exact 22-mutant audit with zero survivors, replayed all five stored
    patches, passed both 541-test baselines, the 0/11 and 11/11 focused
    matrices, four Clippy feature surfaces, both patch orders, startup JUnit,
    ten-run stability, and offline arbitrary-UID containers, then froze version
    25 without a cold solver.
48. Reopened the trajectory-informed gate after review found two independent
    replacement gaps: offline held→neutral was keyboard-only, and steno never
    changed directly from one nonzero chord to another before replay.
49. Rejected direct-channel drafts because legitimate stored solutions use
    writer-private queues/signals, and rejected a standalone absence test after
    it passed pristine through silence.
50. Added real USB endpoint probes for all-family initial-offline
    held→neutral, paired with a live progress marker and positive all-family
    replay, plus exact second-chord steno replay. Strengthened absence checks to
    accept only neutral output or the explicit current marker.
51. Added mandatory global gap-analysis and fairness-analysis protocols,
    templates, agent gates, and workflow documentation, then completed both
    exact-version records for this problem.
52. Repeated the frozen 24-mutant audit with zero survivors, all five stored
    replays, both 541-test baselines, pristine 0/13 and reference 13/13,
    formatting, four Clippy surfaces, both patch orders, startup JUnit,
    ten-run stability, and offline arbitrary-UID execution; froze version 26
    without a cold solver.
53. Reopened the trajectory-informed gate after review found that disconnected
    blocking sends covered only media and BLE-bound dropped-neutral mouse state
    was not isolated.
54. Added a real USB-writer blocking held→neutral→held all-family test and a
    real BLE GATT phase that rejects stale mouse buttons behind a full USB
    queue while a distinct system marker proves progress.
55. Repeated the exact test-only/reference baselines and three focused lanes,
    ten-run stability, formatting, four warning-denying Clippy surfaces, both
    patch orders, startup-error JUnit, all 27 mutations, and all 15 retained
    solution replays. No cold solver was run.
56. Completed exact gap and fairness analyses. Attempted the arbitrary-UID
    Docker matrix, but Docker Desktop's engine remained unresponsive before a
    container could start; leave that environment gate open rather than reuse
    version 26 evidence.
57. Audited every run-10 evaluator report, raw patch, and representative
    trajectory. Established that all five independently updated the same three
    legacy all-up assertions because those assertions contradict the current
    public no-release contract; Nova 3 and Nova 5 otherwise pass all ten focused
    tests.
58. Excluded only the three superseded release-specific state cases from the
    base nextest expression, retaining the other 538 regression tests and all
    focused behavior.
59. Repeated exact reference/pristine matrices, all five run-10 replays, the
    six-mutant audit, ten-run stability, warning-denying steno/no-steno Clippy,
    formatting, shell syntax, both patch orders, startup-error JUnit, gap
    analysis, and fairness analysis. Nova 3 and Nova 5 are now legitimate
    passes; Nova 1, 2, and 4 retain independent failures. Froze version 36 at
    calibration 0/10 without a cold solver.
60. Audited all run-11 patches and representative raw trajectories. Identified
    two clear legitimate passes, one behaviorally complete patch with an
    inconsistent manipulation label, and two solutions failing different
    host-output boundaries.
61. Replaced all fixed-yield late-stale checks with progress-delimited real
    writer observation, validated packets before per-family snapshot storage,
    and removed a test-side BLE clear exposed by the one-entry-drain mutant.
62. Demonstrated the new discriminator with a delayed-stale mutant that passes
    version 36 and 538/538 baseline but fails version 37. Repeated the exact
    reference/pristine matrices, seven-mutant audit, stored-solution replay,
    ten-run stability, warning-denying Clippy, formatting, patch-order,
    startup-JUnit, gap, and fairness gates. Froze version 37 at calibration
    0/10 without a cold solver.
63. Reopened the trajectory gate for the blocked-send, CCCD, description, and
    legacy-test findings. Confirmed the blocked duplicate-delivery hole and the
    reference's missing steno CCCD bookkeeping.
64. Repolled every blocked family after BLE→USB cutover, restored old-route
    capacity, and added a real BLE-writer marker that rejects late old-host
    output while preserving correct USB replay.
65. Moved the three contract updates into `test.patch`, restored the complete
    541-test baseline, removed the prompt's test-edit instruction, and repaired
    steno CCCD bookkeeping in the reference.
66. Repeated exact matrices, mutation and stored-solution replay, ten-run
    stability, warning-denying Clippy, formatting, patch-order, gap, fairness,
    and false-positive gates; froze version 38 at 0/10 without a cold solver.
67. Audited all five run-12 wrappers, patches, and representative trajectories;
    classified every result as an evaluator-injection error after the wrapper
    reset three naturally solver-owned production modules.
68. Moved all hidden tests to additive randomized files, registered them only in
    the wrapper's disposable source copy, and pinned the baseline to the exact
    538 authoritative pre-existing test IDs.
69. Added and enforced the global fail-fast environment gate across agent,
    design, testing, submission, calibration, and reusable template guidance.
70. Built the untouched Docker image and ran exact pristine, reference, and two
    independent known-good solution matrices offline as UID 10001; verified all
    five run-12 patch shapes compose without conflicts or resets.
71. Repeated exact mutation, gap, fairness, false-positive, patch-order,
    formatting, shell, and startup-JUnit checks; froze version 39 at 0/10
    without a cold solver.
72. Reopened the trajectory gate for run 13, inspected all five patches and
    representative raw trajectories, and identified the shared
    transport-identity shortcut in two otherwise successful solutions.
73. Added one deterministic USB→BLE→USB blocked-send discriminator and one
    fresh offline async-producer discriminator; made both behaviors explicit in
    the public contract and updated the reference with route activations.
74. Restarted the global environment gate from an untouched exact-head clone.
    A corrupt temporary clone failed fast and was discarded; the clean restart
    passed offline as UID 10001 with 538/538 baseline and 12/12 reference.
75. Replayed all five run-13 patches, isolated ten plausible mutants, and
    repeated patch-order, diff, shell, formatting, warning-denying Clippy, gap,
    fairness, and false-positive checks. Froze version 40 at 0/10 without a cold
    solver.
76. Audited every run-14 report, patch, log, and representative trajectory.
    Identified Nova 1 as a legitimate implementation rejected only because the
    probes named a private status static and concrete type.
77. Switched probe reset to RMK's existing test-support seam, expanded the
    fresh disconnected awaited-send case to all five families, and added the
    missing old-USB capacity-three real-writer boundary. Rejected an initial
    USB draft after it passed pristine, then added positive preserved-state
    replay so every new testcase is behavioral fail-to-pass.
78. Repeated the exact pristine/reference/known-good arbitrary-UID offline
    environment gate, replayed Nova 1 at 13/13 and Nova 2 at 10/13, rejected all
    twelve exact mutants, and passed patch-order, rustfmt, shell, steno/no-steno
    warning-denying Clippy, gap, fairness, and false-positive checks. Froze
    version 41 at 0/10 without a cold solver.
79. Audited all five run-15 reports, patches, logs, and available trajectory
    records. All reached product behavior: four solve version 41 and one fails
    four observable writer/replay boundaries; none is environment-blocked.
80. Added one phase to the integrated BLE host test that awaits fresh state for
    every enabled family while disconnected, activates BLE first, and requires
    exact GATT replay with zero relative mouse impulses.
81. Demonstrated the discriminator with a BLE-specific offline awaited-state
    mutant that passes the preceding 13-test suite and 538/538 baseline but
    fails the new phase. Repeated the exact offline non-root environment,
    pristine/reference, stored-solution injection, patch-order, shell, gap,
    fairness, and false-positive gates. Froze version 42 at 0/10 without a cold
    solver.

No cold solver run was launched or consumed. The stored patch replays above are
trajectory evidence, not calibration. Any submission-artifact change creates a
new immutable version and restarts all exact-version gates at 0/10.
