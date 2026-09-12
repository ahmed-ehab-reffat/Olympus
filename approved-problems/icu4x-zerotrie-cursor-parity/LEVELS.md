# Calibration levels — ICU4X ZeroTrie cursor parity

## Level 1 — exact hardened escalation

Status: **superseded at 0/10 by the reviewer fairness repair**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `2121384cf14ab74cec10c26f3a014335e14bf45c1b0722d0a26d02e38675d64e`
- `test.patch`: `dbe0ac17838c3e5ca3f9770dbaaf5326ffe8c5abbacd4c2f16a036d4b97b17e6`
- `solution.patch`: `d71765413ac5c84ef33862a1e90fb07aa93bf61cf1f98bd3245d46a2e840f199`
- `Dockerfile`: `3e126a7a3a76d302d620ce46aa0502ab039bfc585debd9db4894a934989b9c74`

No solver run was made. The level was abandoned because two hidden compile
assertions selected `usize` for a count whose public contract permits another
wide integer type, and the rlib-scanning harness had stale-artifact risk.

## Level 2 — type-neutral probe result and source-bound clients

Status: **superseded at 0/10 by the Docker-only environment revision**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `2121384cf14ab74cec10c26f3a014335e14bf45c1b0722d0a26d02e38675d64e`
- `test.patch`: `64c28a0d3736fa72aae2cb7690b2c0f68612452e94a30a1eabbf6214b4c02c0b`
- `solution.patch`: `d71765413ac5c84ef33862a1e90fb07aa93bf61cf1f98bd3245d46a2e840f199`
- `Dockerfile`: `3e126a7a3a76d302d620ce46aa0502ab039bfc585debd9db4894a934989b9c74`

Level 2 removes the exact binary count type annotations and compiles each
binary public client through an isolated offline Cargo path project. A
conforming `u16` result passes 7 focused, 60 package, 64 doctest, and no-default
checks; an incorrect `u8` result fails the 256-child behavior. Exact environment,
gap, fairness, and false-positive gates pass.

The reference changes two production files with 500 additions and one deletion.
This is a scope forecast only; successful solver patches must supply the actual
long-horizon file/message/effective-LOC evidence.

No Level 2 solver attempt has been made or counted. Before platform upload, follow
`CALIBRATION_STRATEGY.md`: save 1–2 local frontier runs under
`estimate_trajectories/`; if both solve cleanly, harden and restart every gate.
Otherwise start one immutable 10-run platform batch in pairs, preserving every
trajectory under `actual_trajectories/`. Any change to a submission artifact
abandons the level, invalidates all exact-version audits, and returns the revised
level to 0/10.

## Level 3 — build-only Docker preparation

Status: **superseded at 0/10 by the plain-Cargo environment repair**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `2121384cf14ab74cec10c26f3a014335e14bf45c1b0722d0a26d02e38675d64e`
- `test.patch`: `64c28a0d3736fa72aae2cb7690b2c0f68612452e94a30a1eabbf6214b4c02c0b`
- `solution.patch`: `d71765413ac5c84ef33862a1e90fb07aa93bf61cf1f98bd3245d46a2e840f199`
- `Dockerfile`: `2a02c029ddc2d5fa09cddf82f748900d4eb40b8b2ec0dabb0f2d009b2d615181`

Level 3 replaces Docker's repository test-target compilation with an
all-feature `zerotrie` library build. No Docker build, test lane, exact
environment gate, downstream audit, or solver run was executed for this level.
Before calibration, rerun Phase A and Phase B and then repeat the gap, fairness,
and false-positive gates for these exact hashes.

## Level 4 — upstream-compatible plain Cargo test mode

Status: **superseded at 0/10 by the coverage and canonical-environment repair**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `2121384cf14ab74cec10c26f3a014335e14bf45c1b0722d0a26d02e38675d64e`
- `test.patch`: `64c28a0d3736fa72aae2cb7690b2c0f68612452e94a30a1eabbf6214b4c02c0b`
- `solution.patch`: `d71765413ac5c84ef33862a1e90fb07aa93bf61cf1f98bd3245d46a2e840f199`
- `Dockerfile`: `1f8715f2293dc9bf05efc7d2f3607a8265ff2f7da5a1c0b57233758ab09581ad`

Level 4 retains build-only image preparation and adds a Docker-level Cargo
shim. Plain `cargo test` receives `--all-features`, matching ICU4X's upstream
workspace test task and enabling `icu_pattern`'s unstable extraction surface.
Commands with an explicit feature selection and all non-test Cargo subcommands
are passed through unchanged. No repository file, prompt, hidden test, or
reference behavior changed. No Docker build, test lane, exact environment gate,
downstream audit, or solver run was executed for this level.

## Level 5 — concise contract, ExtendedCapacity PHF, and canonical environment

Status: **superseded after five supplied Nova runs and Level 6 hardening**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `4f91f8d5c3352ed84fbde792a5fc43c4810becfced3778c55d0716930126b599`
- `test.patch`: `3df0e72ba6c5ea0f477064b1767635a536b7f3c37c6373dd11f579d84d2a7943`
- `solution.patch`: `d71765413ac5c84ef33862a1e90fb07aa93bf61cf1f98bd3245d46a2e840f199`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- exact local image ID:
  `sha256:f52ea10cae54f1ab83e0d2acdae06a1810d87706435f968e1ce1fa831742789d`

Level 5 removes untested comparative/performance/internal framing from the
prompt, adds a distinct 32-child ExtendedCapacity PHF step/probe node through
both concrete and runtime cursors, synthesizes failure JUnit when collection
cannot report, and replaces grader-facing driver commentary. The Dockerfile now
uses the approved canonical Olympus base while retaining build-only preparation
and plain-Cargo feature routing.

The exact offline arbitrary-UID gate passes: baseline 60/60 base and 0/8
focused, reference 60/60 and 8/8, and mandatory conforming `u16` replay 60/60
and 8/8. JUnit identities match. The previously failing `icu_pattern`
extraction target compiles with a plain Cargo test command under the image. An
ExtendedCapacity-only PHF omission passes the other seven focused nodes and
fails only the new node, so gap, fairness, and false-positive audits pass for
the frozen artifacts.

The supplied `agent-runs1` bundle contains four Level 5 passes and one fair
near-pass. Run 1 also demonstrated a public runtime SimpleAscii formatting
false positive that survived all eight focused nodes. The level was superseded
when the prompt, tests, randomized evaluator paths, and diagnostic fallback were
revised; none of its runs counts toward Level 6 calibration.

## Level 6 — trajectory-driven format and harness hardening

Status: **superseded after eight supplied near-passes and Level 7 easing**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `2f0c3f9e626766438c9b390b5e3c378cb23097c10642bea4413049b075b5ba9e`
- `test.patch`: `5be37958629be30d55db53410bcb814250afa9d029083637d2b0998b93ffadaf`
- `solution.patch`: `d71765413ac5c84ef33862a1e90fb07aa93bf61cf1f98bd3245d46a2e840f199`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- fresh gate export manifest list:
  `sha256:b0683cddbc359c03f5674b943441e18a6b2a9b254f9ae01f7ac3c30984630f3c`

Level 6 adds four distinct behavioral nodes: runtime SimpleAscii formatter
error preservation, multi-byte span lengths, nested 15/16-child branch mode,
and normal W=0/W=3 offsets. It strengthens the existing no-default client to
compile and execute the complete named API. The prompt now explicitly binds
the complete cursor and convenience surface to that feature/resource boundary.

Every hidden source moved to randomized paths. `test.sh` streams and captures
color-free cargo output and embeds XML-escaped underlying diagnostics when
nextest cannot emit JUnit. A forced early failure produced valid XML with the
actual cargo cause.

The first exact gate was quarantined after the `u16` replay exposed an
accidental comparison with a `usize` variable. The corrected patch uses
type-inferred literals, and the restarted gate passes: baseline 60/60 base and
0/12 focused; reference, mandatory `u16`, and Nova runs 2/3/5 each 60/60 and
12/12. Nova runs 1/4 inject cleanly and fail one public behavior each when
executed.

Exact gap, fairness, and false-positive audits passed for the immutable Level 6
version. The supplied `agent-runs2` batch then produced zero solves across
eight valid runs: one reached 10/12 and seven reached 11/12. The repeated
failures were the actual 256 sibling total and runtime SimpleAscii formatting
error. Level 6 is therefore superseded at 0/8; its runs do not carry forward.

## Level 7 — trajectory-based clarity easing and completed resource coverage

Status: **superseded before calibration by Level 8 review repairs**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `e05edb3dc115a8d88f782ccffbd1bf9dc97e20eb043903175164acb4d3dc0404`
- `test.patch`: `feccb64b46b6efb96bc6d11e0ae2521f6820e6d166e5ff94692ca2e17875a2dd`
- `solution.patch`: `d71765413ac5c84ef33862a1e90fb07aa93bf61cf1f98bd3245d46a2e840f199`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- retained equivalent audit image ID:
  `sha256:f52ea10cae54f1ab83e0d2acdae06a1810d87706435f968e1ce1fa831742789d`

Level 7 states the two repeated Level 6 traps directly: a full byte branch
reports the actual total 256 without prescribing the Rust integer type, and
runtime formatting preserves the stored flavor, including non-ASCII success
for byte tries and the existing error for SimpleAscii. The no-default and
allocation rule is consolidated into one sentence.

The suite remains 12 focused nodes. The write node now requires successful
non-ASCII `write_char` across PerfectHash, ExtendedCapacity, and runtime byte
cursors. The no-default node now observes zero allocations during cursor
creation and use after all inputs are constructed.

The fresh exact gate passes offline as UID 10001: baseline 60/60 plus 0/12;
reference, mandatory conforming `u16`, and `agent-runs1` Nova 2/3/5 each 60/60
plus 12/12. All eight latest patches inject and execute; their only failures
remain the two clarified behaviors, so the stronger coverage adds no new trap.
Twelve exact plausible mutants are rejected, including one-method UTF-8 and
one-allocation isolation mutants. Gap, fairness, false-positive, collision,
and diagnostic-preservation audits pass. Level 7 had no counted solver run and
was superseded when the prompt and verifier were revised.

## Level 8 — public wording and runtime maximum-count parity

Status: **closed as too easy at 8/10**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `6067c0d2a363c5566a3ec780e1dec4f35d3a019007884b2691488dda2cfb56ff`
- `test.patch`: `e95a6e7ac61ae85e136d895c53283c19c39de602f850ea2c154a166718a9a2c2`
- `solution.patch`: `d71765413ac5c84ef33862a1e90fb07aa93bf61cf1f98bd3245d46a2e840f199`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- fresh gate image ID:
  `sha256:b1d5924db5016744cb7c0d76ca073027628114c2fd9707061721bdfd95a57020`

Level 8 removes an internal encoding explanation from the public description
while retaining only the observable requirement that a full byte branch report
256. It replaces the integration driver's reporting-oriented comment with a
short public-consumer rationale.

The 12-node suite now checks the 256-child PerfectHash probe through both the
concrete and runtime-dispatched cursor using the same builder-produced trie,
public iteration order, inferred result types, and destination values. A mutant
that narrows only the runtime result passes 11/12 and fails only that existing
probe node.

The fresh exact gate passes offline as UID 10001: baseline 60/60 plus 0/12;
reference, mandatory `u16`, and `agent-runs1` Nova 2/3/5 each 60/60 plus 12/12.
All eight latest near-passes retain exactly their prior failure sets. Twelve
retained mutants and the new runtime-only count mutant are rejected; none
survives. Environment, gap, fairness, false-positive, collision, and
diagnostic-preservation audits pass. Its calibration batch later produced
eight legitimate passes (Nova 1-7 and 10) and two long-span near-passes (Nova 8
and 9), so Level 8 is closed as too easy at 8/10.

## Level 9 — absorbing failure across concrete and runtime surfaces

Status: **closed as too easy at 9/10**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `6067c0d2a363c5566a3ec780e1dec4f35d3a019007884b2691488dda2cfb56ff`
- `test.patch`: `b7689d79445c53577d87ad84d9af3b15e311e700bcb7c8d036b37727e114c1fa`
- `solution.patch`: `d71765413ac5c84ef33862a1e90fb07aa93bf61cf1f98bd3245d46a2e840f199`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- fresh gate image/manifest-list ID:
  `sha256:3e4f2237f9f7e535f463ab99739f8ac327fab1bffcb58addec53694daa7d1ac3`

Level 9 keeps the public description and 12-node structure unchanged. It adds
sticky failed-step and out-of-range-probe sequences to the existing concrete
ExtendedCapacity PHF client and to the existing runtime client for stored
SimpleAscii, PerfectHash, and ExtendedCapacity flavors. Each sequence attempts
valid operations afterward, so returning a recoverable miss is observably
rejected without prescribing a private poison state.

The no-cache exact gate passes offline as UID 10001: baseline is 60/60 plus
0/12; reference, public `u16`, and all eight legitimate Level 8 solutions pass
their full base lane plus 12/12 focused. Nova 9 remains a long-span 11/12
near-pass. Nova 8 becomes 9/12 because the runtime client exposes its probe
revival in addition to its two existing span failures.

Eight fresh isolation mutants cover concrete ExtendedCapacity step/probe and
runtime step/probe for each stored flavor. Every mutant compiles and fails only
the intended existing node; none survives. Exact environment, gap, fairness,
false-positive, collision, and startup-diagnostic audits pass. Its subsequent
calibration batch produced nine legitimate passes and one fair 11/12 near-pass,
so Level 9 is closed as too easy at 9/10.

## Level 10 — ExtendedCapacity retained-span parity

Status: **superseded after a 9/10 compatibility replay; fresh calibration was not run**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `6067c0d2a363c5566a3ec780e1dec4f35d3a019007884b2691488dda2cfb56ff`
- `test.patch`: `1588d2c33462bc26a072678ca66447667bfad45bc0b03c66eda13df3795351fc`
- `solution.patch`: `d71765413ac5c84ef33862a1e90fb07aa93bf61cf1f98bd3245d46a2e840f199`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- fresh gate image index:
  `sha256:920546d81cd48768e56cdad2a4d7fb67738842a743977be9fafce74826e4dfe4`

Level 10 keeps the public description and 12-node structure unchanged. It
extends the existing continuation-length client with a builder-produced
ExtendedCapacity version of the same 300-byte-prefix trie. Concrete and runtime
cursors stop midway through the span, mix `step` and `probe` to finish it,
reach prefix and descendant values, and prove that a mismatching step and an
out-of-range probe remain absorbing while the span is retained.

The fresh no-cache exact gate passes offline as UID 10001: baseline is 60/60
plus 0/12; reference and the conforming public-`u16` alternative are 60/60 plus
12/12. All ten `agent-runs4` patches inject cleanly. Exact behavioral replay
then gives nine complete passes; Nova 7 remains 11/12 on its pre-existing
runtime PerfectHash probe-absorption defect. Every solver's base lane passes.

Four fresh isolation mutants cover ExtendedCapacity-only continuation-length
truncation, runtime-only retained-span loss, recoverable mid-span mismatch, and
recoverable mid-span out-of-range probe. Each compiles and fails only the
strengthened long-span node at 11/12. Exact environment, gap, fairness,
false-positive, collision, and startup-diagnostic audits pass.

The 9/10 result is a compatibility replay of patches authored for Level 9; it
is reported as requested but is not a fresh Level 10 calibration batch. Level
10 calibration starts at 0/10.

## Level 11 — reusable suffix views from retained cursor state

Status: **superseded by the Level 11.1 patch-canonicalization and fairness repair**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `e6b5db9fe5e0b4e6e1f99fffe21a0a19883f8aad8b8f44b637f9c4cf7c44b29d`
- `test.patch`: `e0b56b579aac58f814537b0a71c294f69712c57d2add04bb536c9cf1bf153f1e`
- `solution.patch`: `14b8d851ac22fbb2e06f27ed93221c1b74671159fc31ed6c06ad0092db4de62a`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- fresh gate image index:
  `sha256:0b54f9a3e400c316668943adee3aa302e48d7d72f64bc3a641650a9000038647`

Level 11 makes the repository's existing ASCII suffix-view convention public
for the new concrete and runtime byte cursors. `into_suffix_trie()` returns an
inferred, cloneable, reusable view rooted at the exact cursor state. The view
supports byte lookup, independent cursor creation, closure-driven lookup, and
emptiness while preserving partial spans and consumed current values. Its type
and representation remain free, and the whole surface remains allocation-free
without default features.

The restarted exact gate passes offline as UID 10001: baseline is 60/60 plus
0/13; reference and the conforming public-`u16` alternative are 60/60 plus
13/13. Two otherwise-valid reference mutants isolate retained-span loss and
ignored suffix closure errors at 12/13. Exact environment, gap, fairness,
false-positive, collision, and fallback-diagnostic audits pass.

All ten Level 10 patches inject cleanly. Nova 1-6 and 8-10 score 11/13, failing
only the two consumers of the newly public API; Nova 7 scores 10/13 because it
also retains its historical runtime probe defect. Thus the observed
compatibility result is **0/10**, exactly matching the pre-edit forecast for
old patches. It is not a fresh batch.

The pre-edit expected result for genuinely fresh Level 11 solvers is **3-5
successful solvers out of 10**. Fresh calibration remains **0/10 runs
performed** and must restart on this exact immutable version.

## Level 11.1 — canonical verifier and type-neutral sibling count

Status: **superseded after the supplied 5/5 Level 11.1 solver sample**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `e6b5db9fe5e0b4e6e1f99fffe21a0a19883f8aad8b8f44b637f9c4cf7c44b29d`
- `test.patch`: `001202e78a71d4884fab0d9da4b84eb1b53aa63b13c5677f3a2e3915e79352e8`
- `solution.patch`: `14b8d851ac22fbb2e06f27ed93221c1b74671159fc31ed6c06ad0092db4de62a`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- fresh gate image index:
  `sha256:f9c4f555e5fca869a5ae9d3ccde94d00e8d6944276f5cc00ebd92a58ee0eb0b3`

The behavior and 13-node suite are unchanged. The test patch is regenerated
with 15 unique path headers for 15 paths, so the driver and suffix client each
appear once as final additions. The concrete SimpleAscii sibling-count check
now compares its value with an inferred literal instead of assigning the field
to `u8`. The patch touches only randomized tests plus the harness/config,
retains both harness modes, and installs no packages.

The restarted exact gate passes: pristine is 60/60 plus 0/13, and reference
plus public-`u16` are each 60/60 plus 13/13. Both suffix mutants remain isolated
at 12/13 with 60/60 base. All ten retained patches were rerun; nine remain
11/13 and Nova 7 remains 10/13, so compatibility is still **0/10**. This
matches the repair forecast. Expected fresh calibration remains **3-5/10**;
fresh calibration is **0/10 runs performed**.

## Level 12 — alloc-gated suffix enumeration

Status: **superseded after the supplied 5/5 Level 12 solver sample**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `d3b8b26113bf6f06a51a13e210c86f5d65c0e06e048e8cb177ba592d05b62922`
- `test.patch`: `1c33f1e7f4e1dcd1e316f2103983fa371f76c6cdadaca4f3287dd26e585c730e`
- `solution.patch`: `7925111fdc5b4b2692f740b126c0d8f26ba93eef4af90c5fa41c9e2910f990b7`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- fresh gate image index:
  `sha256:5c54ae2262279b21d0a12a86bdbf28f178499e7d6285ddbd3f4deb0b77bff5a7`

The supplied `agent-runs5` batch contains five valid Level 11.1 successes. All
five implement reusable suffix point lookup but omit enumeration. Level 12
therefore adds an explicitly `alloc`-gated `iter()` to the inferred suffix
view, preserving remaining pairs and the trie's existing format order from
root, partial-span, and taken/untaken-value states. It also closes non-ASCII
`write_char` coverage for runtime dispatch storing ExtendedCapacity and removes
the suffix paragraph's repeated resource-language.

The final 13-node verifier covers concrete and runtime PerfectHash and
ExtendedCapacity iteration plus runtime SimpleAscii. A 20-child builder-produced
PHF fixture proves the public iterator oracle differs from lexical sorting.
The patch has 15 unique path headers, no production paths, no exact count-type
pin, both harness modes, and diagnostic-preserving startup JUnit.

The final restarted no-cache gate passes offline with read-only source and
UID/GID 10001: pristine is 60/60 plus 0/13, while reference and the conforming
public-`u16` alternative are each 60/60 plus 13/13. Four targeted mutants pass
their 60-test base lane and fail only the intended writer or suffix node at
12/13; none survives. Environment, gap, fairness, false-positive, collision,
patch-shape, and failure-diagnostic audits pass.

All five prior successful patches inject cleanly and now score 12/13, failing
only the suffix-view node; their base lanes pass. The observed compatibility
result is therefore **0/5**, exactly matching the pre-artifact forecast. It is
not fresh calibration.

The expected result after hardening is **2-4 successful solvers out of 10
fresh attempts**. Fresh Level 12 calibration remains **0/10 runs performed**;
the five historical attempts cannot be carried into the revised version.

## Level 13 — source-independent owned suffix views

Status: **superseded after the supplied 4/5 Level 13 solver result**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `a8f1779d786b7807ae1bab238422bc86d2a134e2dc1f95733ce6af9fe86c6de9`
- `test.patch`: `6b57dcfebaef18655f4e75264c64bb709ce4996626e054b38cc23777a83f4653`
- `solution.patch`: `99a78fa3aa2e820b242f4ccce26b0a1e87693b181169b6cdc972493b9d792498`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- fresh gate image index:
  `sha256:20085abfa677e7eed146f32fb61145e6d630a1522149fed4b4532e5f281cde9b`

All five supplied `agent-runs6` solvers pass Level 12 with mature traversal and
borrowed suffix implementations, but none crosses the source-lifetime boundary.
Level 13 requires alloc-gated, inferred `to_owned()` materialization of the
suffix view's exact logical state. The resulting view survives destruction of
the source and remains usable through lookup, cursor traversal, formatting,
clone, and iteration. The result type and rebuilding strategy remain open.

The same randomized suffix node now covers concrete and runtime PerfectHash and
ExtendedCapacity partial spans, taken and untaken values, runtime SimpleAscii
flavor preservation, non-ASCII runtime suffix formatting, and explicit closure
errors. The no-default allocator node measures runtime cursor operations for
SimpleAscii, PerfectHash, and ExtendedCapacity. No predictable test filename or
new focused node was added.

The final exact gate passes offline, read-only, as UID/GID 10001: pristine is
60/60 plus 0/13, while reference and the conforming public-`u16` alternative
are each 60/60 plus 13/13. Four targeted variants are isolated at 12/13 after
one initially surviving runtime-flavor mutant caused a test repair and complete
gate restart. Gap, fairness, false-positive, patch-shape, collision, and
failure-diagnostics audits pass.

Every Level 12 patch composes cleanly and scores 12/13, failing only the owned
suffix node with source-lifetime errors. Observed old-patch compatibility is
therefore **0/5**. The expected result after hardening is **1-3 successful
solvers out of 10 fresh attempts**. Fresh Level 13 calibration remains **0/10**;
the compatibility sample is not counted.

## Level 14 — serialized owned suffix stores and terminal lifecycle

Status: **superseded at 0/10 by the inferred-store fairness repair**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `e323bfcbf0415b1932ba7b4a9a150e83eec4bc4fbbb51b0cf7b7b690d2ce53bc`
- `test.patch`: `9aa96c2f704269a4a1b3ab5d2074663a6b2afe353b927bb502ec670710c7281b`
- `solution.patch`: `e912350b5764c484c821ec1a3e110e35b282b4fe0e8a55f7a688c244a488ec05`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- fresh gate image index:
  `sha256:e9da94c528513b075838cf9578ee289bdc00f382162bc2855c0a61661a606b19`

The supplied run7 batch closes Level 13 as too easy: Nova 1, 3, 4, and 5 pass
60/60 plus 13/13, while Nova 2 is a 12/13 near-pass caused by lost continuation
span state. All successes independently converge on owned cursor-state wrappers
holding copied serialized fragments and span metadata rather than ordinary
reconstructable trie stores.

Level 14 requires alloc-owned suffix results to interoperate with the existing
storage surface through inferred `as_bytes()`, `byte_len()`, and
`into_store()`. The known corresponding public constructor must accept both
borrowed and consumed stores and reproduce the exact current suffix state.
Reconstructed output must support another cursor/suffix/ownership generation.
No result name, exact type, canonical bytes, field layout, builder, or encoding
algorithm is prescribed.

The existing randomized suffix client also covers the reported terminal-state
gap: initially empty and already-failed concrete and runtime cursors produce
empty reusable views across all supported flavors. No new test node or
predictable path was introduced.

The exact no-cache gate passes offline, read-only, as UID/GID 10001. Pristine
is 60/60 plus 0/13; reference and the conforming public-`u16` alternative are
each 60/60 plus 13/13. All five run7 patches compose and then score 12/13 on
behavioral replay, failing only the strengthened suffix node. Observed
compatibility is **0/5**.

A raw-state exposure mutant and an empty-view resurrection mutant each score
12/13 and isolate the intended new predicates. A focused survivor that uses a
PerfectHash collector for runtime `into_store()` passes 13/13 and the complete
60-test base suite; it is rejected as a discriminator because public readers
accept the store and all observable behavior conforms. No canonical-byte test
was added. Gap, fairness, false-positive, patch-shape, collision, environment,
and startup-diagnostic audits pass.

The expected result after hardening is **0-1 successful solvers out of 10 fresh
attempts**, with one borderline solve as the target. Fresh Level 14 calibration
remains **0/10**; run7 is historical evidence only.

## Level 14.1 — type-neutral consumed-store reconstruction

Status: **superseded at 0/10 by the runtime iterator-key fairness repair**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `e323bfcbf0415b1932ba7b4a9a150e83eec4bc4fbbb51b0cf7b7b690d2ce53bc`
- `test.patch`: `f949cc76c6c6bfb8c6207198e2b89328975f2a55f8acc76124e5a9085534942c`
- `solution.patch`: `e912350b5764c484c821ec1a3e110e35b282b4fe0e8a55f7a688c244a488ec05`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- fresh gate image index:
  `sha256:f84dd4400caf0f2691a27b2ef14b4fd48eed61b0867d468b0c87c5e179b1bcfe`

Level 14.1 removes the sole reviewer-confirmed unfair assertion. The inferred
store returned by an owned suffix's `into_store()` is no longer required to
offer an inherent Vec-like `is_empty()` method. The verifier passes that value
directly to the known corresponding public constructor and checks the
reconstructed trie's empty lookup and iteration behavior.

A conforming reference variant returning a custom `AsRef<[u8]>` wrapper with
no inherent `is_empty()` passes 60/60 existing plus 13/13 focused tests. The
ordinary reference and public-`u16` alternative also pass 60/60 plus 13/13;
pristine remains 60/60 plus 0/13. Every run7 patch still scores 12/13, so
observed prior compatibility remains **0/5**.

The raw-continuation and empty-resurrection defects remain isolated at 12/13.
The behaviorally valid PerfectHash-normalized store remains a 13/13 and 60/60
survivor and is still excluded from rejection. Exact environment, gap,
fairness, false-positive, patch-shape, and startup-diagnostic gates pass.

This fairness-only repair does not lower the public implementation burden.
The expected result after hardening remains **0-1 successful solvers out of 10
fresh attempts**, with one borderline success as the target. Fresh Level 14.1
calibration starts at **0/10**; no Level 14 or run7 result carries forward.

## Level 14.2 — representation-neutral suffix iterator keys

Status: **superseded at 0/10 by the run8 owned-result verifier mismatch**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `e323bfcbf0415b1932ba7b4a9a150e83eec4bc4fbbb51b0cf7b7b690d2ce53bc`
- `test.patch`: `d85b20c2b5d79481b2856ee4b078649409bec74c6952093152f3d3aa96628e92`
- `solution.patch`: `e912350b5764c484c821ec1a3e110e35b282b4fe0e8a55f7a688c244a488ec05`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- fresh gate image index:
  `sha256:29bc20bca7ace0d2bedbc4d5071b0740c326d901e8eba0c05a589f658e84da8f`

Level 14.2 removes the reviewer-confirmed requirement that runtime SimpleAscii
suffix iterators yield `Vec<u8>` keys. Every inferred key is normalized through
`AsRef<[u8]>` before exact content/order comparison. Empty iterator assertions
use `is_none()`, so the unspecified key also need not implement `PartialEq`.

A legitimate reference variant with a public custom iterator key implementing
`AsRef<[u8]>` but neither `Vec<u8>` identity nor `PartialEq` passes 60/60
existing and 13/13 focused tests. The ordinary reference and public-`u16`
alternative also pass 60/60 plus 13/13; pristine remains 60/60 plus 0/13.

All five run7 patches still score 12/13, so observed prior compatibility is
**0/5**, matching the frozen forecast. Raw-continuation and empty-resurrection
mutants remain 12/13. The behaviorally valid PerfectHash-normalized store
remains a 13/13 plus 60/60 survivor and is correctly accepted. Exact
environment, gap, fairness, false-positive, patch-shape, and
startup-diagnostic gates pass.

This is a fairness-only verifier repair and does not lower the public
implementation burden. The expected result after hardening remains **0-1
successful solvers out of 10 fresh attempts**, with one borderline success as
the target. Fresh Level 14.2 calibration starts at **0/10**; no earlier result
carries forward.

The subsequent run8 batch cannot be counted against this level. All five
patches passed 12/13 and failed only an undocumented direct `iter()` call on
the unprescribed runtime-owned result. Four evaluators classified the outcome
as test mismatch, and repository/API review confirmed that verdict.

## Level 14.3 — owned-result fairness and no-default suffix Clone

Status: **superseded after run9 by Level 15**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `e323bfcbf0415b1932ba7b4a9a150e83eec4bc4fbbb51b0cf7b7b690d2ce53bc`
- `test.patch`: `6b3f4fdbc55ed416d1546d2c672827c3be4c45900bb6cf20838c7f7634e62e0a`
- `solution.patch`: `e912350b5764c484c821ec1a3e110e35b282b4fe0e8a55f7a688c244a488ec05`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- replay manifest: `91ee70b839591a15953cd8c0ccf1c643ec3785c12384efbc4e20a5c63aebbf7c`
- no-cache gate image index:
  `sha256:93fe90d701ab4ee820968543dcdd7e387b86f21dd057c997274c8f012dad8eec`

Level 14.3 removes every direct `owned.iter()` requirement from the suffix
client. Exact entries and order remain covered by reconstructing the public
concrete flavor from borrowed bytes and the consumed store. The no-default
counting-allocator client now clones the concrete and runtime suffix values,
checks `is_empty` on original and clone, and independently queries the clone
for PerfectHash, ExtendedCapacity, and all three runtime stored flavors.

The exact gate is pristine 60/60 plus 0/13, reference and public-`u16` 60/60
plus 13/13, and all five hash-pinned run8 patches pass both modes. Nova 3 has
65/65 pre-existing/own tests; the other four have 60/60. A custom iterator key,
a custom consumed store, and the flavor-rebuilding owned result all remain
accepted at 60/60 plus 13/13.

The alloc-gated suffix-Clone mutant fails only the no-default node at 12/13.
The raw-continuation and empty-resurrection mutants remain isolated at 12/13.
Exact environment, gap, fairness, false-positive, patch-shape, and startup-
diagnostic gates pass.

Observed run8 compatibility is **5/5**. The expected result after hardening is
**7-10 successful solvers out of 10 fresh attempts**, so this revision is
honestly still too easy for a one-borderline-success target. Fresh Level 14.3
calibration starts at **0/10**; the quarantined run8 batch does not carry
forward.

## Level 15 — concise contract and complete value-width preservation

Status: **superseded at 0/10 by the tone-only Level 15.1 prompt repair**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `50ff4f6e999ed14edbeb8e99130cc9a70a2091a955d243a7d07bfc9d1ee8b5e7`
- `test.patch`: `35ace96b1c98119d358ae08827b4d0cb8b4b25ba1a915bd368964b1ec90cbcd9`
- `solution.patch`: `e912350b5764c484c821ec1a3e110e35b282b4fe0e8a55f7a688c244a488ec05`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- replay manifest: `52710570ccf5da22224ded381bbe1083ff70e95e3e318f93185266a03eed8813`
- no-cache gate image index: `sha256:ce7b2748302c4d15374324a772dce831763784f4299a5bd4a91fb7a273ff0abc`

Run9 is a genuine 7/10 result. Level 15 makes the same contract easier to scan
and adds a distinct value-width discriminator across concrete/runtime cursor,
probe, suffix, iterator, ownership, and reconstruction surfaces. A two-width
cursor decoder passes the old 13/13 suite and fails the new node; every prior
successful run8 and run9 implementation passes it.

The final gate is pristine 60/60 plus 0/14; reference, public-`u16`, all five
run8 successes, and three representative run9 successes pass both modes.
Exact gap, fairness, false-positive, patch-shape, and environment audits pass.

Expected fresh result: **6-8/10, centered on 7/10**. Fresh calibration starts
at **0/10**. The observed run9 results are compatibility evidence only.

## Level 15.1 — direct maintainer-style contract

Status: **superseded by Level 16 after run10 solved 6/10**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `2243eeb63f682636e5fa7a1dedfe1f3218d78f079e1396af13af14ff19bb206a`
- `test.patch`: `35ace96b1c98119d358ae08827b4d0cb8b4b25ba1a915bd368964b1ec90cbcd9`
- `solution.patch`: `e912350b5764c484c821ec1a3e110e35b282b4fe0e8a55f7a688c244a488ec05`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- replay manifest: `52710570ccf5da22224ded381bbe1083ff70e95e3e318f93185266a03eed8813`
- no-cache gate image index: `sha256:fb7bf418e08d4de3da395ede7310988945ac841ef06ae9c58dd88a3a8798d731`

This prompt-only revision replaces four meta-spec phrases with direct prose.
The 14-node suite, reference, Dockerfile, and replay set are byte-identical to
Level 15. The complete exact environment gate was nevertheless restarted:
pristine is 60/60 plus 0/14, and reference, public-`u16`, all five run8
successes, and three run9 successes pass their existing/own suites plus 14/14.

The full-width truncation mutant passes 60/60 existing and fails only the
value-width node at 13/14. Exact gap, fairness, and false-positive audits pass.
Expected fresh result remains **6-8/10, centered on 7/10**. Fresh calibration
starts at **0/10**.

## Level 16 — allocation-free suffix walk and reversible exact iteration

Status: **superseded after run11 solved 6/10 and Level 17 hardening**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `204d577dc64ccf403ac87e6fe871ad51ee6a08e8c1d2372b3c1e4744cfcd5983`
- `test.patch`: `32ddc4ce046d1461ee1205a8b73a053312dbfb470ba1081d89293c44c840d70e`
- `solution.patch`: `a48395f3324e7b5f5d38c6fb092d134b24b9523f5c402766c9ca46cd62b2b9d5`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- replay manifest: `356cd7619e3ed94d0924682948db3c5231dcc341bd9c1064c1b14b6df5be2f20`
- no-cache gate image index:
  `sha256:2ffef69814219e2039bd7fa167ba86124c475e1ec186507b852ec333d54c1dcb`

Run10 is a clean predecessor result: Nova 3, 4, 5, 7, 8, and 10 pass; Nova 1,
2, and 6 miss the explicit runtime-owned `as_bytes` surface; Nova 9 mishandles
the 256-child PHF sentinel. The six successful implementations are large,
materially different architectures, and all pass a broad 401-entry/all-prefix
differential prototype. That broad probe was rejected because it found no new
false positive.

Level 16 instead adds a real public capability. Every exact-state suffix view
reports its remaining entry count and performs a fallible, allocation-free
`Push`/`Value`/`Pop` event walk. Alloc-enabled iteration additionally supports
reverse traversal, exact remaining length, and fused exhaustion. The focused
node crosses concrete and erased PerfectHash/ExtendedCapacity, erased
SimpleAscii, root/partial/taken/failed states, callback errors, no-default
compilation, and zero heap allocation.

A no-`Pop` adapter passes 60/60 existing and the 14/14 predecessor focused
suite but fails only the new traversal reconstruction. Forward-only and stale-
length iterator variants are rejected by distinct explicit trait/behavior
checks. The exact gate is pristine 60/60 plus 0/15 and reference 60/60 plus
15/15; JUnit identities and three representative run10 compositions pass.

Fresh calibration starts at **0/10**. The expected result after hardening is
**1-2 successful solvers out of 10, centered on one borderline success**.

Run11 later solved this immutable level 6/10: Nova 3, 4, 5, 6, 9, and 10
passed. Nova 1 omitted erased suffix iteration; Nova 7 and 8 omitted erased
owned-byte access; Nova 2 lost partial-span state and had an inexact iterator
size hint. Level 16 is therefore closed as too easy.

## Level 17 — cross-feature allocation and legacy ASCII suffix parity

Status: **accepted and archived 2026-08-17; user-confirmed platform success**

Repository pin: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

- `meta.md`: `4ee0a417a12d6e2dc89d3a74225b625699a631367b99ed95daf03f82c61f195d`
- `test.patch`: `1f434f99cc7735f9b1fa3bd0a665868626a98e1a9d085b80cca0e93accff27db`
- `solution.patch`: `8c57616dca3cd605da4ae12fd408ed378e8190c594f525904f862ac720326b04`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- replay manifest: `64091afc6de600a35fc8b0245b0b7659b3f726ca5e4d463fff7753fde792d75d`
- no-cache image index:
  `sha256:9bf98566c7cab2c37a900bdf3521448a5c80188c96b6399798fa85de20f54b55`

The 320-word prompt retains the full binary/runtime cursor and suffix contract
in five maintainer-style paragraphs. It explicitly completes `len` and
fallible `ByteTrieEvent` traversal for suffix tries produced by the existing
SimpleAscii and ASCII-ignore-case cursors, requires immediate callback stop on
error, and applies the no-heap core-operation rule with every feature set.

The new all-feature counting allocator covers concrete SimpleAscii,
ignore-case, PerfectHash, ExtendedCapacity, and all three erased stored
flavors. Legacy suffix traversal is checked at root, partial, taken-value, and
failed states against each trie's existing public iterator, under both
all-feature and no-default compilation. An eager alloc-gated `len` and a
deferred visitor-error implementation each pass 60/60 existing plus 15/16
focused nodes, failing only their new public predicate.

The exact gate is pristine 60/60 plus 0/16 and reference 60/60 plus 16/16.
Run11 Nova 5 and Nova 10 independently pass 60/60 plus 16/16; Nova 2 and Nova
7 compose cleanly in evaluator order. JUnit identities, fallback diagnostics,
18 unique randomized test-only paths, gap, fairness, and false-positive audits
all pass.

Fresh Level 17 calibration starts at **0/10**. Based on run11 architecture and
2/6 compatibility among its successes, the expected result after hardening is
**1-3 successful solvers out of 10 fresh attempts, centered on 2/10**.

The platform accepted this exact version on 2026-08-17. No fresh Level 17
calibration batch was run; acceptance closes the problem independently of that
historical 0/10 count and forecast. Cold run and recovery evidence moved to
`archive/icu4x-zerotrie-cursor-parity/`.
