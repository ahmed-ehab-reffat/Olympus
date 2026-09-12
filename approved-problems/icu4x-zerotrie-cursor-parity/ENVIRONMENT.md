# Environment gate — ICU4X ZeroTrie cursor parity

Status: **pass for the frozen Level 17 artifacts**

Gate date: 2026-08-16

Repository: `unicode-org/icu4x @ c0846c9000467f1292e6d6a0e98db6798cf6a417`

## Immutable inputs

- `meta.md`: `4ee0a417a12d6e2dc89d3a74225b625699a631367b99ed95daf03f82c61f195d`
- `test.patch`: `1f434f99cc7735f9b1fa3bd0a665868626a98e1a9d085b80cca0e93accff27db`
- `solution.patch`: `8c57616dca3cd605da4ae12fd408ed378e8190c594f525904f862ac720326b04`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- replay manifest: `64091afc6de600a35fc8b0245b0b7659b3f726ca5e4d463fff7753fde792d75d`
- approved base image ID: `sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`
- fresh gate image index:
  `sha256:9bf98566c7cab2c37a900bdf3521448a5c80188c96b6399798fa85de20f54b55`
- fresh Linux platform manifest:
  `sha256:483de3f40561b30f25c11450a237b797b18ed7b0c9be5370f162700cc8584284`
- fresh image config:
  `sha256:992606ae31768b6e9f7616005e6152c75cf90c0e421018dd8fe8a2cb1f6acea6`
- fresh provenance attachment:
  `sha256:d3b6131bda2ea1c700e719ac143770b4e55d6aa795f1f9df9267ad41701b92f5`
- Rust: 1.97.1; cargo-nextest: 0.9.140

The gate built the submitted Dockerfile from scratch with `--pull --no-cache`.
The completed automated no-cache build supplies the exact image-index and
platform-manifest identifiers above.

Level 17 adds cross-feature allocation coverage and legacy ASCII suffix
traversal parity. The addendum at the end is the controlling exact-version record;
the earlier level records are retained only as history.

## Phase 0 and Phase A

The Dockerfile begins with the approved Olympus base and uses only
`WORKDIR /app`. Its context is the untouched pinned repository, with no
participant, reference, or verifier patch. It resolves the committed lockfile,
builds the all-feature `zerotrie` library, checks the no-default library, and
prewarms Rust and nextest under arbitrary-UID-readable `/opt` paths.

`scripts/environment_gate.sh` rebuilt the exact image, disabled runtime
networking, mounted composed sources read-only, and ran as UID/GID 10001. The
pristine base lane discovered and passed all 60 pre-existing `zerotrie` tests.
Cargo, rustc, nextest, lockfiles, indexes, dependencies, and writable external
target state were available offline.

Phase A verdict: **pass**.

## Phase B — exact evaluator composition

Every tree used evaluator order: clone/reset/clean the pin, apply a participant
or reference patch when present, stage it, then inject the current
`test.patch`. The mandatory manifest supplied the conforming public-`u16`
implementation. All five successful `agent-runs5` patches were also composed
and accepted verifier injection without overlap, conflict, unmerged files, or
loss.

| Composition | Base | Focused |
|---|---:|---:|
| pristine + verifier | 60/60 pass | 0/13 pass; 13 real named behavioral failures |
| reference + verifier | 60/60 pass | 13/13 pass |
| conforming `u16` + verifier | 60/60 pass | 13/13 pass |

Baseline and reference focused JUnit testcase identities match. No gate lane
reported a missing node, startup sentinel, network resolution, permission
failure, patch conflict, or collection failure.

Phase B verdict: **pass**.

## Canonical-patch delivery check

The repaired `test.patch` contains 15 `diff --git` headers for 15 unique
paths. Every path appears once, every test source is added directly from
`/dev/null` in its final state, and `git apply --check` succeeds on a fresh
clone. The patch touches only `.config/nextest.toml`, `test.sh`, and randomized
files under `utils/zerotrie/tests`. `test.sh` retains both `base` and `new`
modes, runs Cargo offline, and contains no package-install command.

The prior exact-`u8` assignment is absent. The SimpleAscii probe now compares
the sibling total to the inferred literal `1`, so the verifier observes the
numeric value without selecting a Rust integer type.

## Exact prior-solver compatibility replay on Level 12

All five successful `agent-runs5` patches were freshly recomposed against the
immutable Level 12 verifier and executed offline, read-only, as UID/GID 10001.
The Dockerfile, pinned dependencies, Rust, nextest, evaluator order, and
runtime restrictions match the fresh gate.

| Run | Base | Focused | Verdict |
|---|---:|---:|---|
| Nova 1 | 62/62 | 12/13 | missing suffix iteration |
| Nova 2 | 60/60 | 12/13 | missing suffix iteration |
| Nova 3 | 60/60 | 12/13 | missing suffix iteration |
| Nova 4 | 60/60 | 12/13 | missing suffix iteration |
| Nova 5 | 60/60 | 12/13 | missing suffix iteration |

Thus **0 of 5 prior successful solvers succeed on the new immutable version**.
All still pass the other 12 focused nodes, showing that the difference is the
newly public suffix enumeration direction rather than verifier drift. This
compatibility replay is not fresh Level 12 calibration; fresh calibration
remains 0/10 with a forecast of **2-4 successful solvers out of 10**.

All replay JUnit documents contain the same 13 testcase identities and no
startup sentinel.

## Harness failure-report check

The exact current harness was forced to fail before collection by mounting an
empty Cargo home and target. It exited 102, wrote the requested JUnit file, and
`xmllint --noout` accepted it. The `harness-startup` failure body includes the
missing `displaydoc` package and the failed offline `cargo metadata` command.
The sentinel remains an environment blocker and is never interpreted as
participant behavior.

## Delivery ownership

`test.patch` remains additive: `.config/nextest.toml`, `test.sh`, the randomized
driver `cursor_contract_8b72d6.rs`, and randomized clients beneath
`cursor_contract_cases_c4a91f`. Level 12 extends the randomized
`write_api_b508ec.rs` and `suffix_view_6f2a91.rs` clients without introducing a
predictable test filename. It emits each path once and does not overlap
production paths.

## Verdict

**Pass.** The exact Level 12 prompt, verifier, reference, Dockerfile, pin,
dependency graph, replay manifest, alternate public API architecture,
evaluator order, arbitrary-UID offline runtime, JUnit identities, solver
compatibility replay, and fallback diagnostics are viable. Any later
submission-artifact or evaluator change invalidates this record and resets
calibration to 0/10.

## Level 13 exact restart

This section supersedes the Level 12 result language above. The final candidate
was restarted after adding the direct runtime SimpleAscii flavor-preservation
assertion; no earlier environment result was reused.

The submitted Dockerfile was rebuilt without cache from the approved base. The
exact image identifiers are those in `Immutable inputs`. All runtime lanes were
offline, used read-only composed source, and ran as arbitrary UID/GID 10001
with Rust 1.97.1 and cargo-nextest 0.9.140.

| Exact composition | Existing tests | Focused tests | Result |
|---|---:|---:|---|
| Untouched pinned repository + verifier | 60/60 | 0/13 | Expected baseline; all focused failures are real named cases |
| Repository + reference + verifier | 60/60 | 13/13 | Pass |
| Repository + public-`u16` alternative + verifier | 60/60 | 13/13 | Pass |

Focused JUnit discovery and execution contained the same 13 testcase
identities. `test.patch` has 15 diff headers for 15 unique paths, emits each
path only once, changes no production file, uses randomized source names, and
supports both `base` and `new`. The harness installs nothing. Its existing
startup fallback retains the failing command's captured build/collection
diagnostic in the requested valid JUnit artifact.

All five `agent-runs6` Level 12 patches apply after verifier injection in the
exact evaluator order. Each passes 12/13 focused nodes and fails only
`suffix_views_preserve_partial_state_and_independent_lookup`; the nested public
consumer reports `E0597` because its purported owned result still borrows the
source that has left scope. Thus exact prior-patch compatibility is **0/5**.
These runs are environment/compatibility evidence and are not counted as fresh
Level 13 calibration.

The alternate public-`u16` lane proves that no exact sibling-count type has
returned. Patch application and static shape checks also confirm no duplicate
new-then-modified diff records, missing test node, predictable flagged test
path, stale rlib selection, production overlap, or evaluator-order conflict.

**Pass.** The exact Level 13 prompt, verifier, reference, Dockerfile, pin,
dependency graph, replay manifest, legitimate alternate architecture,
evaluator composition, offline arbitrary-UID runtime, JUnit identities, and
five compatibility replays are viable. Any later submission-artifact or
evaluator change invalidates this verdict and restarts calibration at 0/10.

## Level 14 exact restart

This section supersedes every earlier result statement. The environment gate
was restarted after the final prompt, verifier, reference, alternate, and
replay-manifest changes; no Level 13 verdict was carried forward.

The submitted Dockerfile was rebuilt with `--pull --no-cache` from approved
base image
`sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`.
The resulting index, Linux platform manifest, and config are recorded under
`Immutable inputs`. Every runtime lane disabled networking, mounted composed
source read-only, ran as UID/GID 10001, and used Rust 1.97.1 with
cargo-nextest 0.9.140.

| Exact composition | Existing tests | Focused tests | Result |
|---|---:|---:|---|
| Untouched pin + verifier | 60/60 | 0/13 | Expected separation; all 13 are real named failures |
| Reference + verifier | 60/60 | 13/13 | Pass |
| Public-`u16` alternative + verifier | 60/60 | 13/13 | Pass |

Baseline and reference focused JUnit contain the same 13 testcase identities.
Phase A proves offline arbitrary-UID startup and build viability; Phase B
reproduces evaluator composition for baseline, reference, alternate, and all
five run7 patches without conflicts, missing nodes, resets, permission faults,
or dependency resolution.

The five run7 solutions were additionally executed against the final focused
suite. Each passes 12/13 and fails only the strengthened suffix node because it
lacks serialized owned-store interoperability. Observed compatibility is
**0/5**. Those are old-patch diagnostics, not fresh Level 14 solver attempts.

Static delivery checks pass: `test.patch` has 15 diff headers for 15 unique
paths, emits every path once, changes only the nextest config, harness, and
randomized tests, and contains no exact `total_siblings` integer assignment.
`solution.patch` changes only `utils/zerotrie/src/cursor.rs` and
`utils/zerotrie/src/reader.rs`. The harness supports `base` and `new`, runs
offline, and installs nothing.

The fallback lane was freshly forced to fail before collection with status
102. It returned the requested XML-valid `harness-startup` JUnit and preserved
`synthetic startup diagnostic: missing <crate> & metadata` with correct XML
escaping. No diagnostic-only result was interpreted as participant behavior.

**Pass.** The exact Level 14 artifacts, dependency graph, evaluator injection,
alternate public API architecture, offline arbitrary-UID runtime, discovery,
JUnit, and prior-patch composition are viable. Any later submission-artifact
change invalidates this verdict and restarts calibration at **0/10**.

## Level 14.1 exact restart

This section supersedes every earlier environment result. The reviewer found
that one empty-owned assertion called `is_empty()` on the inferred value
returned by `into_store()`, although the public contract leaves that store type
unspecified. After replacing that call with reconstruction through the known
public concrete constructor, the exact-version gate was restarted from Phase A.

The submitted Dockerfile was rebuilt with `--pull --no-cache` from approved
base image
`sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`.
The resulting image index is
`sha256:f84dd4400caf0f2691a27b2ef14b4fd48eed61b0867d468b0c87c5e179b1bcfe`,
with Linux manifest
`sha256:da7f48a16cdbbf6335d3c9dcd7ee1797dce5f8ddf7dac33e7c18d21b464d4820`
and config
`sha256:758b02024f5ef9b5c7eaaea9693350eb4fadc697d58a4a9d90607c678a02b18a`.
Every lane ran offline with read-only composed source as UID/GID 10001 using
Rust 1.97.1 and cargo-nextest 0.9.140.

| Exact composition | Existing tests | Focused tests | Result |
|---|---:|---:|---|
| Untouched pin + verifier | 60/60 | 0/13 | Expected separation; 13 real named failures |
| Reference + verifier | 60/60 | 13/13 | Pass |
| Public-`u16` alternative + verifier | 60/60 | 13/13 | Pass |

Focused testcase identities match between pristine and reference. All five
run7 patches compose in evaluator order without overlap, conflict, missing
nodes, permissions faults, or network resolution. Exact behavioral replay
remains 0/5: each historical implementation scores 12/13 and fails only the
owned-suffix storage node. A freshly recomposed, unmodified Nova 4 patch
confirms that result independently of the raw-state mutant replay tree.

A structurally different legitimate architecture was then replayed: the
reference runtime owned suffix returns a public custom store implementing only
`AsRef<[u8]>`, with no inherent `is_empty()` method. It passes 60/60 existing
and 13/13 focused tests. This directly proves that the repaired verifier no
longer relies on a Vec-like inferred store API.

Static delivery checks pass. `test.patch` has 15 headers for 15 unique paths,
each emitted once; it changes only the nextest configuration, harness, and
randomized test paths; it supports `base` and `new`; and it contains neither a
direct `store.is_empty()` assertion nor an exact sibling-count type
assignment. The harness installs nothing.

The exact fallback lane was also forced to fail before collection by mounting
an empty Cargo home. It returned status 102 and an XML-valid requested JUnit
artifact whose `harness-startup` failure preserves the underlying missing
`displaydoc` and failed offline `cargo metadata` diagnostics. The sentinel is
an environment blocker, never a participant failure.

**Pass.** The frozen Level 14.1 artifacts, dependency graph, evaluator
composition, legitimate custom-store architecture, offline arbitrary-UID
runtime, discovery, JUnit, and diagnostic fallback are viable. Any artifact
change invalidates this verdict and restarts calibration at **0/10**.

## Level 14.2 exact restart

This is the controlling environment verdict for the immutable hashes at the
top of this record. `test.patch` changed after the runtime SimpleAscii iterator
review, invalidating Level 14.1 and restarting both phases and calibration at
0/10.

The no-cache build resolved the approved base
`sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`.
Its output image index is
`sha256:29bc20bca7ace0d2bedbc4d5071b0740c326d901e8eba0c05a589f658e84da8f`,
with Linux manifest
`sha256:8c5acafccf80de443dfbb6f97b387d073c3c2e5e008af1c57895f5591d8a6834`
and config
`sha256:c9a3850c069dd7e1cd59243814b3e630c7bf7c4443fc1b1b278d9e9cbc4a1390`.
Every lane ran offline with read-only composed source as UID/GID 10001 using
Rust 1.97.1 and cargo-nextest 0.9.140.

| Exact composition | Existing tests | Focused tests | Result |
|---|---:|---:|---|
| Untouched pin + verifier | 60/60 | 0/13 | Expected separation; 13 real named failures |
| Reference + verifier | 60/60 | 13/13 | Pass |
| Public-`u16` alternative + verifier | 60/60 | 13/13 | Pass |

Focused testcase identities match. All five run7 patches compose in exact
evaluator order, and their serial behavioral replays each score 12/13 for
**0/5** compatibility. A legitimate reference variant whose iterator key is a
custom public `AsRef<[u8]>` wrapper without `PartialEq` passes 60/60 plus
13/13, proving the repaired client does not depend on `Vec<u8>` identity or an
unstated comparison trait.

Static delivery checks pass: `test.patch` has 15 headers for 15 unique
test-only paths, applies cleanly to the pin, supports `base` and `new`, and
installs nothing. A forced pre-collection failure returns 102 and writes valid
fallback JUnit whose `harness-startup` failure contains the underlying missing
`displaydoc` and failed offline `cargo metadata` diagnostics.

An over-parallelized exploratory replay was quarantined after host memory
pressure SIGKILLed compiler processes. Its outcomes were discarded, all
containers were stopped, and the five compatibility patches plus three
mutation variants were rerun serially without resource faults.

**Pass.** The frozen Level 14.2 artifacts, exact evaluator composition,
legitimate custom-key architecture, offline arbitrary-UID runtime, discovery,
JUnit, and diagnostic fallback are viable. Any artifact change invalidates
this verdict and restarts calibration at **0/10**.

## Level 14.3 exact restart

This is the controlling environment verdict for the immutable hashes at the
top of this record. The test and mandatory-replay artifacts changed after the
run8 mismatch review, invalidating Level 14.2 and restarting both phases and
calibration at 0/10.

The first restart stopped at the fail-fast host-space preflight (10.8 GiB free
against the required 12 GiB). No lane ran and no solver result was counted.
Only obsolete ICU4X task images were removed; they are reproducible from the
submitted Dockerfile. The complete gate was then restarted from zero. A second
fully logged run was used for the controlling result so the final shell status
was preserved explicitly.

The submitted Dockerfile built with `--pull --no-cache` from the untouched pin.
The approved base is
`sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`;
the output image index is
`sha256:93fe90d701ab4ee820968543dcdd7e387b86f21dd057c997274c8f012dad8eec`,
the Linux/arm64 manifest is
`sha256:8e85f83691924f4663c3ff2bce559099bfa14148ed90942c83a60550aa54d42e`,
and the provenance attachment is
`sha256:b14fda2888467e42262c3435e2535aecb0207a35563d4630472a136fd741212d`.
Every evaluator lane ran offline with read-only composed source as UID/GID
10001 using Rust 1.97.1 and cargo-nextest 0.9.140.

| Exact composition | Existing tests | Focused tests | Result |
|---|---:|---:|---|
| Untouched pin + verifier | 60/60 | 0/13 | Expected separation; 13 real named failures |
| Reference + verifier | 60/60 | 13/13 | Pass |
| Public-`u16` alternative + verifier | 60/60 | 13/13 | Pass |
| Run8 Nova 1 + verifier | 60/60 | 13/13 | Pass |
| Run8 Nova 2 + verifier | 60/60 | 13/13 | Pass |
| Run8 Nova 3 + verifier | 65/65 | 13/13 | Pass |
| Run8 Nova 4 + verifier | 60/60 | 13/13 | Pass |
| Run8 Nova 5 + verifier | 60/60 | 13/13 | Pass |

Focused testcase identities match. The five run8 patches are hash-pinned in
`ENVIRONMENT_REPLAYS.sha256`, so future gate invocations cannot silently omit
these adjudicated legitimate architectures.

Separate exact-source replays accept a custom iterator-key wrapper, a custom
consumed-store wrapper without inherent Vec-like methods, and a behaviorally
valid flavor-rebuilding owned result at 60/60 plus 13/13. Static delivery
checks find 15 headers for 15 unique test-only paths, clean application to the
pin, both harness modes, no package installation, and no exact
`total_siblings` type or direct `owned.iter()` requirement.

The forced pre-collection lane returns 102 and produces XML-valid JUnit at the
requested path. Its `harness-startup` failure contains the underlying missing
`displaydoc` resolution error and failed offline `cargo metadata` command.

**Pass.** The frozen Level 14.3 artifacts, dependency graph, exact evaluator
composition, mandatory replay set, offline arbitrary-UID runtime, JUnit, and
diagnostic fallback are viable. Fresh calibration remains **0/10**; the
five run8 replays are compatibility evidence, not fresh attempts.

## Level 15 exact restart

This is the controlling environment verdict for:

- `meta.md`: `50ff4f6e999ed14edbeb8e99130cc9a70a2091a955d243a7d07bfc9d1ee8b5e7`
- `test.patch`: `35ace96b1c98119d358ae08827b4d0cb8b4b25ba1a915bd368964b1ec90cbcd9`
- `solution.patch`: `e912350b5764c484c821ec1a3e110e35b282b4fe0e8a55f7a688c244a488ec05`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- replay manifest: `52710570ccf5da22224ded381bbe1083ff70e95e3e318f93185266a03eed8813`

The Dockerfile rebuilt with `--pull --no-cache` from the untouched pin. The
approved base remains
`sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`.
The output image index was
`sha256:ce7b2748302c4d15374324a772dce831763784f4299a5bd4a91fb7a273ff0abc`,
with Linux/arm64 manifest
`sha256:0a6d2b17e95509df02eb08ddeeb7f92fce8b823ab4c1b26a22445cd3c1b273a2`,
config
`sha256:2a779ea1c5822e290e3f7ae43577f5f9b5cd0ebb0976babfc28139d0bd9aa0ae`,
and provenance attachment
`sha256:6c6545665522d6c1a3c3b2bf52ee72d355195a15c4cba7d66c3bb7627fa0b3ff`.

Every evaluator lane ran offline as UID/GID 10001 with read-only composed
source, Rust 1.97.1, and cargo-nextest 0.9.140.

| Exact composition | Existing/own tests | Focused tests | Result |
|---|---:|---:|---|
| Untouched pin + verifier | 60/60 | 0/14 | Expected separation; 14 named behavioral/compile failures |
| Reference + verifier | 60/60 | 14/14 | Pass |
| Public-`u16` alternative + verifier | 60/60 | 14/14 | Pass |
| Run8 Nova 1 | 60/60 | 14/14 | Pass |
| Run8 Nova 2 | 60/60 | 14/14 | Pass |
| Run8 Nova 3 | 65/65 | 14/14 | Pass |
| Run8 Nova 4 | 60/60 | 14/14 | Pass |
| Run8 Nova 5 | 60/60 | 14/14 | Pass |
| Run9 Nova 1 | 60/60 | 14/14 | Pass |
| Run9 Nova 5 | 60/60 | 14/14 | Pass |
| Run9 Nova 8 | 61/61 | 14/14 | Pass |

Baseline and reference focused JUnit testcase identities match. The replay
manifest now pins the public-`u16` architecture, all five run8 successes, and
three materially different run9 successes. Patch composition produced no
overlap, conflict, missing node, permission error, startup sentinel, or network
resolution.

Static inspection finds 16 headers for 16 unique test-only paths. The patch
applies cleanly to the pin, supports `base` and `new`, installs nothing, and
does not constrain the sibling-count integer, `step` return type, cursor/view/
iterator/owned/store representation, or serialization bytes.

**Pass.** Phase A and exact Phase B are viable for Level 15. Fresh calibration
is **0/10**. Historical compatibility is run8 **5/5** and run9 **7/10**; the
expected fresh result is **6-8/10, centered on 7/10**.

## Level 15.1 exact restart

This is the controlling environment verdict for the tone-only prompt revision:

- `meta.md`: `2243eeb63f682636e5fa7a1dedfe1f3218d78f079e1396af13af14ff19bb206a`
- `test.patch`: `35ace96b1c98119d358ae08827b4d0cb8b4b25ba1a915bd368964b1ec90cbcd9`
- `solution.patch`: `e912350b5764c484c821ec1a3e110e35b282b4fe0e8a55f7a688c244a488ec05`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- replay manifest: `52710570ccf5da22224ded381bbe1083ff70e95e3e318f93185266a03eed8813`

The Dockerfile rebuilt with `--pull --no-cache` from the untouched pin. The
approved base remains
`sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`.
The output image index was
`sha256:fb7bf418e08d4de3da395ede7310988945ac841ef06ae9c58dd88a3a8798d731`,
with Linux/arm64 manifest
`sha256:970d9ed1781e74285c30fdfd600720c342982b7589c3834eedfd90f0a87be5f9`,
config
`sha256:93bb2cbf86a35aecf063164114c74d530b76aaa6fb08b27f9046285cdc3518ce`,
and provenance attachment
`sha256:d96c46d94b95e268db7710294bc79ec6a2d6a50e658b4370a5cc292f1508d025`.

Every lane ran offline with read-only composed source as UID/GID 10001 using
Rust 1.97.1 and cargo-nextest 0.9.140. Pristine passed 60/60 existing and
failed all 14 named focused nodes. Reference, the public-`u16` alternative,
all five run8 replays, and run9 Nova 1, 5, and 8 passed their 60/60, 65/65, or
61/61 existing/own suites plus 14/14 focused nodes. Focused JUnit identities
matched, and no composition conflict, missing node, permission failure,
startup sentinel, or network resolution occurred.

**Pass.** Both phases are viable for Level 15.1. The prompt edit changes no
evaluator input or production behavior, but the complete exact-version gate
was rerun as required. Fresh calibration is **0/10** and the expected result
remains **6-8/10, centered on 7/10**.

## Level 16 exact restart

This is the controlling environment verdict for the immutable hashes at the
top of this record. An initial attempt used a partial promisor clone and failed
before testing because a required Git object was absent. That batch was
quarantined as an environment blocker. A complete clone of the pinned
repository was then used and the gate restarted from Phase A; no result from
the blocked attempt was counted.

The submitted Dockerfile rebuilt with `--pull --no-cache`. Every runtime lane
disabled networking, mounted the composed source read-only, and ran as
UID/GID 10001 with Rust 1.97.1 and cargo-nextest 0.9.140. The exact results
were:

| Composition | Existing tests | Focused tests | Result |
|---|---:|---:|---|
| Untouched pin + verifier | 60/60 | 0/15 | Expected separation; all failures are real named API/behavior nodes |
| Reference + verifier | 60/60 | 15/15 | Pass |

Baseline and reference focused JUnit contain the same 15 testcase identities.
Run10 Nova 10, Nova 1, and Nova 9 were recomposed in exact evaluator order as
representative pass and near-pass architectures; participant staging followed
by verifier injection completed without overlap, unmerged paths, reset state,
or a missing test node. They are composition checks, not conforming Level 16
replays, because the new traversal API did not exist in run10.

The exact `test.patch` has 17 diff headers for 17 unique paths, and each path
appears once in its final state. It changes only nextest configuration,
`test.sh`, and randomized test sources. `test.sh` supports `base` and `new`,
runs Cargo offline, installs nothing, and preserves a pre-collection failure's
diagnostic. A forced missing-`cargo` run exited 127 and produced XML-valid
`harness-startup` JUnit containing `cargo: command not found`.

**Pass.** Phase A proves offline arbitrary-UID build/start viability; Phase B
proves exact baseline/reference separation, JUnit identity, and representative
solver composition. Fresh Level 16 calibration is **0/10**. The expected
result after hardening is **1-2 successful solvers out of 10 fresh attempts,
centered on one borderline success**.

## Level 17 exact restart

This is the controlling environment verdict for:

- `meta.md`: `4ee0a417a12d6e2dc89d3a74225b625699a631367b99ed95daf03f82c61f195d`
- `test.patch`: `1f434f99cc7735f9b1fa3bd0a665868626a98e1a9d085b80cca0e93accff27db`
- `solution.patch`: `8c57616dca3cd605da4ae12fd408ed378e8190c594f525904f862ac720326b04`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- replay manifest: `64091afc6de600a35fc8b0245b0b7659b3f726ca5e4d463fff7753fde792d75d`

The first launch was quarantined before testing because only 6.0 GiB was
available and the gate requires 12 GiB. Only disposable task-created clones
and build targets were removed. With 17.7 GiB available, the whole gate was
restarted at Phase A; the blocked launch contributes no result.

The submitted Dockerfile then rebuilt with `--pull --no-cache` from approved
base `sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`.
The exported image index was
`sha256:9bf98566c7cab2c37a900bdf3521448a5c80188c96b6399798fa85de20f54b55`,
with arm64 manifest
`sha256:483de3f40561b30f25c11450a237b797b18ed7b0c9be5370f162700cc8584284`,
config `sha256:992606ae31768b6e9f7616005e6152c75cf90c0e421018dd8fe8a2cb1f6acea6`,
and provenance attachment
`sha256:d3b6131bda2ea1c700e719ac143770b4e55d6aa795f1f9df9267ad41701b92f5`.

Every execution lane was offline, read-only, and UID/GID 10001. The exact
results were:

| Composition | Existing tests | Focused tests | Result |
|---|---:|---:|---|
| Untouched pin + verifier | 60/60 | 0/16 | Expected separation; all 16 public nodes fail |
| Reference + verifier | 60/60 | 16/16 | Pass |
| Run11 Nova 5 + verifier | 60/60 | 16/16 | Independent known-good pass |
| Run11 Nova 10 + verifier | 60/60 | 16/16 | Independent known-good pass |

Baseline and reference JUnit reports have the same 16 testcase identities.
Run11 Nova 2 and Nova 7 also compose in exact participant-then-verifier order
without conflicts, missing test nodes, reset state, permissions faults, or
network resolution; they are compatibility injections, not conforming Level
17 claims. A forced missing-`cargo` launch exits 127 and creates XML-valid
`harness-startup` JUnit containing the underlying `cargo: command not found`
diagnostic.

The patch has 18 headers for 18 unique test-only paths, including randomized
`ascii_visit_alloc_9e4b20.rs`; every path appears once. Both submission
patches apply cleanly to the pin. `test.sh` supports `base` and `new`, installs
nothing, and retains collection/build diagnostics in fallback XML.

**Pass.** Both environment phases and exact evaluator composition are viable
for Level 17. Fresh calibration is **0/10**. The expected post-hardening result
is **1-3 successful solvers out of 10 fresh attempts, centered on 2/10**.
