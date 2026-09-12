# Plan

Status: **version 56; wrapper compile/startup classification repaired; reference-verified; false-positive audit skipped; calibration 0/10**

1. Completed: trajectory-informed redesign gate over all four `agent-runs3`
   compact records, raw trajectories, patches, and evaluator results.
2. Completed: explicit exact macro-write contract and non-square row-major
   keymap fixture.
3. Completed: zero-sized macro success boundary and strict final partial macro
   extent checks.
4. Completed: two-slot combo, fork, and Morse coverage plus actual cross-unit
   restore under different target transport limits.
5. Completed: reference native and runtime WASM checks on arm64 and amd64, plus
   replay of all four saved `agent-runs3` implementations.
6. Completed: logical-stage failure injection across all eight restore stages,
   exact completed-prefix assertions, and no-later-mutation checks.
7. Completed: replay of all four saved `agent-runs4` implementations against
   the expanded failure matrix.
8. Completed: direct preflight rejection for three independent identity fields
   and all ten structural geometry fields, with no mutation.
9. Completed: second-request failure for encoder, fork, and macro stages, with
   exact completed prefixes and no later mutation.
10. Completed: arm64/amd64 reference checks and all four `agent-runs5` replays.
11. Completed: trajectory-informed version-21 redesign gate based on the four
    latest unconditional-restore implementations and existing protocol APIs.
12. Completed: complete target-baseline reads, dirty-stage-only restore,
    late-read no-write failure, and sparse completed-stage accounting in the
    public contract, reference, native tests, and runtime WASM script.
13. Completed: 22/22 focused native tests and 1/1 runtime WASM test on arm64
    and amd64, plus 83/83 pre-existing workspace tests on arm64.
14. Skipped at the user's request: the exact version-23 false-positive audit,
    full patch-state matrix, and calibration.
15. Completed: shorten the participant description from 518 whitespace-counted
    words to 421 without changing the public contract, tests, or reference.
16. Completed: separate export ordering, baseline completeness, and write-stage
    ordering; relax exact encoder/macro traces; and make the WASM peer accept
    identity reuse or reread. Remove two redundant description sentences.
17. Completed: 22/22 focused native and 1/1 runtime WASM tests on arm64 and
    amd64, plus 83/83 pre-existing workspace tests on arm64.
18. Completed: inspect all four `agent-runs6` compact records, production
    patches, evaluations, and raw trajectories; record their shared
    whole-resource dirty-stage architecture before changing the tests.
19. Completed: publish item-sparse indexed writes, chunk-sparse macros, and
    fresh-baseline retry behavior without prescribing single versus bulk
    endpoints or packing.
20. Completed: add logical-entry recording across both endpoint families,
    mixed equal/dirty fixtures for every indexed resource, first/last dirty
    macro chunks around an equal middle chunk, and retry after the second
    request fails in each of the six multi-request stages.
21. Completed: add successful malformed-baseline validation with zero setters,
    and expand later-request failures to all six multi-request stages.
22. Completed: 25/25 focused native and 1/1 runtime WASM tests on arm64 and
    amd64, plus 83/83 pre-existing workspace tests on arm64.
23. Skipped at the user's request: the exact version-24 false-positive audit,
    full patch-state matrix, historical replay, and calibration.
24. Completed: record the version-26 design gate from the reported version-24
    platform batch, noting that no raw version-24 trajectories reached the
    workspace and that the 75% pass rate is a floor because its single failure
    was a hidden-test false negative.
25. Completed: accept a baseline assembled from per-entry reads by folding
    single-entry and bulk reads to one phase per resource in the two remaining
    command assertions.
26. Completed: add a dependency-free `alloc`-only surface crate and build it as
    the first step of the new lane, after confirming that rynk's dev-dependencies
    re-enable `std` and so defeat an example or integration-test check.
27. Completed: raise the level to geometry-adaptive grouped restore. Accept any
    target no smaller in every geometry dimension, compare and address entries
    in the target's coordinates, leave uncovered slots untouched, and send
    consecutive differing entries in as few requests as the advertised page
    allows.
28. Completed: rewrite the participant description as prose, keeping the field
    and variant names the hidden tests construct by name.
29. Completed: 26/26 focused native tests, 1/1 runtime WASM test, and the
    `alloc`-only surface build on arm64 and amd64, plus 83/83 pre-existing
    workspace tests on arm64 with the test patch alone.
30. Skipped at the user's request: the exact version-26 false-positive audit,
    full patch-state matrix, historical replay, and calibration.
31. Completed: move the `alloc`-only surface check from a shell step into the
    graded nextest set, so it is absent behind the skipped compile placeholder
    before the solution and passes after it, instead of appearing only as a
    failure in the run without `solution.patch`.
32. Completed: stop the surface crate pinning exact result and error types; it
    now discards results and names the error types separately.
33. Completed: drive the seven rejecting-preflight tests against the stateful
    peer, which answers every read, and assert only that no setter was sent.
34. Completed: answer a macro read with an error when the device advertises a
    zero chunk, and collapse six duplicated peer-state literals onto one
    `blank_target_state` constructor.
35. Completed: 27/27 focused native tests and 1/1 runtime WASM on arm64 and
    amd64; 83/83 pre-existing on arm64 with the test patch alone; the run
    without `solution.patch` yields only the skipped compile placeholder.
36. Completed: rerun the four version-26 discriminator mutants, plus a mutant
    that reads the whole device during preflight (must pass, and does) and one
    that writes before validating (must fail, and does).
37. Skipped at the user's request: the exact version-27 false-positive audit,
    full patch-state matrix, historical replay, and calibration.

38. Completed: inspect all five `agent-runs7` runs, the first raw trajectories
    since version 23, and record that 0/5 was caused by one assertion plus one
    undocumented variant shape rather than by the intended boundary.
39. Completed: match `RestoreError::Preflight { .. }`, which accepts a tuple or
    a struct variant, so a shape the description never prescribes cannot stop
    the suite from compiling.
40. Completed: drop the advertised-page write cap and the request-shape ledger.
    `max_bulk_keys` is documented for reads only, and the crate's own
    `split_pages` sizes writes by payload budget.
41. Completed: give every multi-request stage a dirty-equal-dirty gap so a
    second request exists whatever an implementation packs into one, which
    keeps the partial-failure and retry families implementation-independent.
42. Completed: state in the description that `RestoreError` has exactly two
    cases and that every pre-write rejection is `Preflight`.
43. Completed: split the description into shorter thematic paragraphs, longest
    now 57 words, at 493 words total.
44. Completed: replay all five `agent-runs7` implementations against the
    repaired tests. 4/5 pass; the fifth fails only on the error mapping that
    step 42 documents.
45. Completed: 27/27 focused native tests and 1/1 runtime WASM on arm64 and
    amd64, plus 83/83 pre-existing on arm64 with the test patch alone.
46. Skipped at the user's request: the exact version-28 false-positive audit,
    full patch-state matrix, and calibration.
47. Outstanding and blocking approval: version 28 is measured as far too easy.
    A new fair lever must be chosen before any calibration batch is spent.

48. Completed: move the WASM round trip into the graded nextest set as
    `snapshot_wasm_client_round_trips_under_node`, so the merged JUnit holds all
    28 cases and none can be reported missing. Confirmed it fails, and fails the
    runner, when the WASM wrapper is broken.
49. Completed: reuse the crate's payload-aware `split_pages` for dirty runs,
    drop the bulk-transfer precondition from `export_configuration`, and remove
    restore's duplicate capability and identity reads via `export_with`.
50. Completed: 28/28 focused native tests on arm64 and amd64, 83/83 pre-existing
    on arm64, and a re-replay of all five `agent-runs7` implementations at 4/5.

51. Completed: probe for the wasm32 target, `wasm-bindgen-test-runner`, and
    `node` before the WASM round trip, standing down with a message when any is
    absent. Verified the round trip still executes and still gates in the image,
    and stands down when the runner is hidden from `PATH`.
52. Completed: drop "`RestoreError` has exactly two cases" from the description,
    keeping the requirement that every pre-write rejection is `Preflight`.
53. Completed: 28/28 on arm64 and amd64, and a re-replay of all five
    `agent-runs7` implementations at 4/5.

54. Completed: drop the postcard mandate from the description and make the
    suite codec-free, replacing the hand-encoded unknown-version input with a
    check that `validate` rejects it and `to_bytes` refuses to emit it.
55. Completed: route all nine `Preflight` matches through `rejected_before_writing`
    and add `snapshot_preflight_pattern_matches_either_variant_shape`, which
    proves the shared pattern accepts a tuple variant and a struct variant.
56. Completed: 29/29 on arm64 and amd64, and a re-replay of all five
    `agent-runs7` implementations at 4/5.

57. Completed: read all five `agent-runs8` runs, the first batch that passes,
    and record their shared streamed-write architecture before changing tests.
58. Completed: fix the S1 defect in the reference. All keymap, combo and Morse
    pages are planned before the first write, and a page the target's frame
    cannot carry is `Preflight`, not `Write`.
59. Completed: state the rule in the description, and add
    `snapshot_restore_plans_every_write_before_touching_the_device`, whose
    target advertises a frame that carries reads, keymap and encoder writes but
    never a combo write.
60. Completed: assert `Serialize + DeserializeOwned` in the surface crate, and
    require `to_bytes` to refuse every validation failure rather than only an
    unknown version.
61. Completed: replay both saved batches. `agent-runs8` falls from 4/5 to 1/5
    and `agent-runs7` stays at 0/5; every failure is the new check and nothing
    else regressed.
62. Completed: 30/30 on arm64 and amd64, 83/83 pre-existing on arm64.
63. Outstanding: the replayed 1/10 is a floor because all ten implementations
    predate the stated rule. A fresh probe batch of two runs is the only way to
    size Level 5 honestly.

64. Completed: compare every per-stage write set through `touched`, which sorts
    first, since only stage order is stated and `write_all` dispatches pages
    concurrently.
65. Completed: drop the `SnapshotGeometry` serde bound, which the task never
    required, and keep the `ConfigurationSnapshot` one.
66. Completed: restore the unsupported-version rule to the description. Version
    31 dropped it with the postcard sentence, leaving two tests resting on a
    predicate the contract no longer stated.
67. Completed: trim the description to 496 words, under the 500-word target.
68. Completed: 30/30 on arm64 and amd64, 83/83 pre-existing on arm64, and a
    re-replay of both batches at an unchanged 1/10.

69. Completed: judge a write failure by whether the rejected request was
    reached and whether any later stage ran, instead of counting same-stage
    requests exactly, since `write_all` keeps several pages in flight.
70. Completed: drop the optional batching sentence from the description, now
    481 words.
71. Completed: 30/30 on arm64 and amd64, 83/83 pre-existing on arm64, and a
    re-replay of both batches at an unchanged 1/10.
72. Completed: diagnose the Harbor oracle start timeout. The artifacts do not
    explain it, the same run classified 83 pass-to-pass and 30 fail-to-pass
    exactly, and the image measurements for a possible slimming are recorded in
    `DESIGN.md` and `HANDOFF.md`.

73. Completed: name `SnapshotRead`, and the other exist-only items in the
    surface crate, by import rather than by a type expression that would pin
    them nongeneric and lifetime-free.
74. Completed: state in the description that the two restore methods borrow the
    snapshot, which the retry test depends on and no test can avoid.
75. Completed: 30/30 on arm64 and amd64, 83/83 pre-existing on arm64, and a
    re-replay of both batches at an unchanged 1/10.

76. Completed: export per entry through `get_key`, `get_combo` and `get_morse`
    when the device does not advertise bulk transfer, which the task requires of
    restore only.
77. Completed: measure every single-entry write against the target's frame
    before the first write, not just the paged stages, since `send_frame`
    enforces the budget for all requests alike.
78. Completed: extend the planning test to two budgets, 8 for a paged stage and
    12 for the single-entry fork write, and mutation-test both fixes.
79. Completed: withdraw a non-bulk export test after measuring that it fails all
    ten saved implementations and takes replay from 1/10 to 0/10, losing the
    only existence proof for the Solvable gate. The reference satisfies it; the
    test is recorded in `DESIGN.md` for restoration if a probe comes back easy.
80. Completed: 30/30 on arm64 and amd64, 83/83 pre-existing on arm64, replay
    back at 1/10.

81. Completed: read all eleven `agent-runs9` runs. Ten completed, eight passed,
    so version 36 measured 80%. Both failures are genuine: two implementations
    declare `Box` without importing it under `alloc` without `std`, and one
    writes a macro chunk a byte past the snapshot's region.
82. Completed: restore the non-bulk export test and state the asymmetry in the
    description, after a review flagged its absence as a HIGH false-positive
    risk. Measured cost against `agent-runs9`: 8/10 becomes 6/10.
83. Completed: try two candidate levers against the same ten implementations,
    zero-extent resources and sub-chunk or absent macro regions. Neither caught
    anyone; both kept as regression coverage.
84. Completed: 33/33 on arm64 and amd64, 83/83 pre-existing on arm64.
85. Outstanding: 6/10 is still above the 50% cap. The next lever is a contract
    change, requiring restore to work without bulk transfer, which needs a
    decision rather than an edit.

86. Completed: name `Debug` and `PartialEq` in the description, which six tests
    require by comparing whole snapshots. Both patches are unchanged, so the
    version-37 verification of that exact pair carries over.

87. Completed: read all ten `agent-runs10` runs. Five passed. Four failures are
    genuine: two do not build with `alloc` on and `std` off, one uses the source
    encoder stride on a larger target, one writes an extra macro byte.
88. Completed: repair the fifth. The WASM test called
    `export_configuration_snapshot` in Rust and used the result as a `Vec<u8>`,
    failing a wrapper that returns `js_sys::Uint8Array`, which wasm-bindgen
    surfaces identically to JavaScript. Export now goes through `Reflect` like
    restore already did. Verified that both representations pass and a broken
    wrapper still fails.
89. Completed: replay `Nova_Nova_3` against the repaired suite, 36/36. Version
    38's true rate was 6/10, and version 39 measures 6/10.

90. Completed: drop the bulk-transfer requirement from restore. Neither
    direction needs it; the reference branches planning and writes on the
    capability, and the frame check covers per-entry requests too.
91. Completed: replace the unsupported-bulk rejection test with a per-entry
    restore test, and add per-dimension geometry growth coverage.
92. Completed: measure three probes against the saved implementations. None
    caught anyone; all kept for regression value only.
93. Completed: establish that a merely stated rule gets satisfied. Two of ten
    missed export-without-bulk unstated, none of ten missed it once stated.
94. Outstanding: the recommended next step is a Dockerfile rebuild that adds
    `thumbv7em-none-eabihf` and discards the Cargo target directories, which
    strengthens the most reliable discriminator and slims the image from about
    12.2 GB to roughly 7 GB.

95. Completed: read all five `agent-runs11` runs. All passed, so version 40 was
    saturated and no existing check discriminated.
96. Completed: find a lever in the types rather than the prose. `KeyAction`'s
    hand-written `PartialEq` ignores the morse-profile index in `TapHold` while
    serde still writes it, so two equal snapshots encode differently unless the
    encoder normalizes it. Confirmed by measurement: equal actions encoding to
    `[4,19,3,0,0]` and `[4,19,3,0,7]`.
97. Completed: state the determinism rule in general instead of naming
    `Morse.actions` as though it were the only case, normalize the ignored index
    across keymap, encoders, combos and forks in the reference, and add
    `snapshot_canonicalizes_actions_equality_treats_as_the_same`.
98. Completed: measure against `agent-runs11`. All five fail the new check, the
    first lever here to catch a whole batch that passed everything else.

99. Completed: drop the `Clone` bound on `ConfigurationSnapshot` and the `Copy`
    bound on `SnapshotGeometry` that test setup imposed. Three sites, one more
    than reported, found by grepping for the same shape.
100. Completed: verify by stripping both traits from the reference. All fifteen
     resulting errors point into `rynk/src/snapshot.rs` and none into the hidden
     tests, and the version-41 lever still catches all five.

101. Completed: widen the canonicalization test to a combo's actions and output
     and a fork's trigger and both outputs, closing the loophole where a
     canonicalizer covering only keymap and encoders would pass. Verified by
     deleting that normalization from the reference.
102. Completed: answer the density note by reorganization alone. Three
     paragraphs each carrying two subjects are split at the seam; the text is
     word-for-word identical with whitespace collapsed, longest paragraph down
     from 56 words to 42.
103. Noted, no change: the advisory that difficulty concentrates in narrow edge
     cases. That concentration is what versions 37 to 40 measured to be the only
     thing that survives a batch, and the rate is in band at 30%.

104. Completed: read all ten `agent-runs12` runs. Three passed, a 30% rate. Six
     of the seven failures are the version-41 canonicalization lever, one is a
     long final macro chunk on a larger target, one a `step_by(0)` panic that
     failed natively and again under WASM. All genuine.
105. Completed: give each nested Cargo build its own `CARGO_TARGET_DIR` and cap
     the pair with a nextest test group, removing the package-cache and
     artifact-directory contention that cost one build 3m36s. The lane now logs
     zero blocking lines and finishes in 33 seconds.

106. Completed: make the WASM test prove its byte argument is decoded and
     applied. Junk bytes must be rejected, and a record differing from the board
     must produce a write carrying the changed action, accepted through either
     endpoint. Verified by a wrapper that ignores `bytes`, which now fails.

107. Completed: read all ten `agent-runs13` runs. Three passed, seven failed on
     the canonicalization lever, and one pass was a reported false positive.
108. Completed: confirm the report. `Nova_Nova_10` sizes every entry of the whole
     record against the frame before comparing to the baseline, so a board that
     already holds an oversized entry is rejected when it must succeed writing
     nothing.
109. Completed: add the intersection the suite was missing, the frame that stops
     a fork write against a board that already matches. The reference passes,
     `Nova_Nova_1` and `Nova_Nova_3` still pass, `Nova_Nova_10` now fails on that
     test alone.

110. Completed: cover a second baseline-failure source. The peer gains
     `corrupt_read`, answering a named read with an undecodable payload, and the
     late-read test runs both that and the device-level rejection.
111. Completed: fix a vacuous assertion found while doing so. That test used a
     matching board, so its no-mutation check could not fail; it now uses a
     dirty board where an implementation pressing on would leave a mark.
112. Completed: collapse the last four inline peer-state literals onto
     `blank_target_state`, so adding a field means editing one place.
113. Completed: drop "the rest the protocol's own types" from the description,
     after weighing that the element types stay reachable through `get_key`,
     `get_combo` and `get_morse`.

114. Completed: require the WASM wrapper to propagate a native failure. Valid
     bytes naming another board are refused at preflight, so only propagation
     rejects; a wrapper that discards the native error now fails.
115. Completed: require export to fail on a late rejected or undecodable read,
     rather than return a record with a defaulted field.
116. Completed: reduce the stated traits to `PartialEq` by comparing whole
     snapshots with `==` instead of `assert_eq!`, which satisfies both the
     review that wanted the traits stated and the one that called them filler.

117. Completed: cover a retry after the default-layer write is refused, the one
     ordering where behaviour has already been applied and only the last write
     is missing. Every entry must be written once across both attempts,
     behaviour exactly once and the default layer exactly twice.
118. Completed: replace "including but not limited to" with plain prose that
     keeps the warning that the Morse map is not the only case.

119. Superseded in version 52: the one-sided raw-postcard rejection probe was
     not codec-independent and has been removed.
120. Completed: pin `ConfigurationSnapshot.version` as `u16` independently of
     the constant, which could otherwise be narrowed with it.
121. Completed: frame-check the behaviour stage, which has neither a bulk
     endpoint nor a per-entry loop and so escaped a stage-by-stage planner.
122. Completed: convert the last two whole-record `assert_eq!` comparisons,
     missed in version 48, so the suite really does need only `PartialEq`.
123. Outstanding and blocking: `agent-runs15` scored 9/10. The canonicalization
     lever has been absorbed, as every stated rule before it was. The three
     audit gaps are correctness coverage and change nothing here: all nine
     passing implementations still pass. A new lever is needed.

124. Completed: replaced the difficulty lever. Restore now plans the fewest
     requests per stage, a contract stated in full in the description, whose
     difficulty is in computing the plan rather than in noticing a rule.
125. Completed: five mutants, each killed, three of the new tests killing one
     uniquely. Six existing restore tests moved to the new contract, and the
     paged partial-failure scenario moved to a grown target where the target's
     gaps still force several requests per stage.
126. Outstanding: version 56 has no measured rate. Run a fresh batch of 10.
     `CALIBRATION_STRATEGY.md` step 0 advises 1 to 2 local frontier runs first,
     which needs an explicit request for a solver simulation.
127. Completed: reread the problem-design protocol; search the local problem
     history and repository; inspect a legitimate pass, near-pass and broad
     failure; and record the version-52 trajectory gate before editing tests.
128. Completed: remove the two foreign-postcard decoder cases, retain the
     implementation-native trailing-input and encoder-validation checks, and
     verify 83/83 base plus 41/41 focused on arm64 and amd64.
129. Skipped at the user's explicit request: all version-52 false-positive,
     mutation and survivor checks.
130. Completed: record the version-53 packaging gate and restore the historical
     decoder testcase name without restoring either foreign-postcard assertion.
131. Completed: exact arm64 and amd64 lanes pass 83/83 base and 41/41 focused,
     and both generated JUnit reports contain the wrapper's expected testcase
     identity.
132. Skipped at the user's explicit request: all version-53 false-positive,
     mutation and survivor checks.
133. Completed: record the version-54 trajectory-informed design gate before
     editing the hidden patch, and classify the arbitrary WASM byte literal as
     a second codec-collision fixture.
134. Completed: replace that literal with bytes exported by the implementation
     under test plus one trailing byte, while retaining the wrapper-registered
     native testcase identity and every independent runtime behavior check.
135. Completed: exact arm64 and amd64 lanes pass 83/83 base and 41/41 focused,
     and both generated JUnit reports contain the wrapper's expected testcase
     identity.
136. Skipped at the user's explicit request: all version-54 false-positive,
     mutation and survivor checks, plus solver and calibration runs.
137. Completed: record the version-55 trajectory-informed design gate and
     reproduce the exit-96 nextest store failure, zero-error fallback XML,
     unreadable warmed crate source and root-owned nested targets under an
     arbitrary UID with networking disabled.
138. Completed: move nextest's store and outer Cargo target to a private runtime
     directory, move nested Cargo targets under the system temporary directory,
     improve nested spawn diagnostics and make fallback JUnit report one error.
139. Completed: normalize warmed Cargo/rustup read and search permissions in the
     final image layer without making the checkout writable or assuming a UID.
140. Completed: exact arm64 and amd64 lanes pass offline as UID/GID 42424 with
     83/83 base and 41/41 focused tests, including both nested checks; forced
     startup failure exits nonzero and records one JUnit error.
141. Skipped at the user's explicit request: all version-55 false-positive,
     mutation and survivor checks, plus solver and calibration runs.

142. Completed: record the version-56 trajectory-informed wrapper gate and
     reproduce the unclassified `new.harness-startup` as new-mode exit 101
     after rustc reports the deliberately absent participant API.
143. Completed: classify only new-mode exit 101 without JUnit as one skipped
     `new.compile-placeholder`; retain errored `harness-startup` for every
     other nonzero no-JUnit result and preserve native JUnit when present.
144. Completed: exact arm64 and amd64 lanes pass offline as UID/GID 42424 with
     83/83 base and 41/41 focused tests; the test-only lane exits 101 with one
     skip, while a forced missing-Cargo startup exits 127 with one error.
145. Skipped at the user's explicit request: all version-56 false-positive,
     mutation and survivor checks, plus solver and calibration runs.
146. Completed: review the proposed semantic-invalid decoder probe against the
     trajectory gate, public byte API and version-52 codec-freedom finding.
147. Completed: reject foreign serialization, assumed byte offsets and a
     mutant-specific conditional mutation sweep; record the semantic decoder
     rule as a black-box observability gap and leave every artifact unchanged.

Version 56 cannot be approved while the false-positive gate remains skipped.
Calibration is also still 0/10; any further artifact change abandons this exact
version and restarts calibration at 0/10.
