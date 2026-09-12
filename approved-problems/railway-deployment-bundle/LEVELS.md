# Calibration levels

## Canonical version 1 — superseded before calibration

The first artifact-complete bundle was revised at 0/10 after reviewer feedback
identified an undeclared grader-facing controller seam, exact-message
assertions, and ambiguous-looking test selection. No solver run was spent or
carried forward. Its prompt hash was
`54a9035f7a51631d25ccafea5a937e39ddb0b44fd379f5946943fb1f3f4e2492`
and its test hash was
`1b699f905dec33b6e5656b2dbe5fe55ae5ee5544e94a328aafab88abe08b9c1d`.

## Canonical version 2 — superseded before calibration

Status: superseded at 0/10 runs.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `bfaab788d1af0a9cc2fce6bdba49ec147abec722c9e34135f1888acb2cd988a5`
- tests: `3187049b49d4f16faa199f33039d74a61e5e09bec2a2a91d82368eb4ba8ef402`
- reference: `27c7a903e1a8302c3c4efdeb725f991a4ced7bbd79d44a2e87f6f5859bc51e33`
- explanation: `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

No solver run was spent or carried forward. A follow-up reviewer request
removed two unnecessary names of existing internal helpers from the prompt.
That prompt-only edit created version 3 and required the exact-version audit
again.

## Canonical version 3 — superseded before calibration

Status: superseded at 0/10 runs.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `7806b2c24d587c0aec67867f2ede46fc8b7b923021d0adc9b9a3ce7f08476a2d`
- tests: `3187049b49d4f16faa199f33039d74a61e5e09bec2a2a91d82368eb4ba8ef402`
- reference: `27c7a903e1a8302c3c4efdeb725f991a4ced7bbd79d44a2e87f6f5859bc51e33`
- explanation: `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

No solver run was spent or carried forward. Reviewer feedback exposed two
avoidable grader-only constraints: complete-plan equality required
undocumented convenience traits, and CLI checks called private parser/refresh
helpers.

## Canonical version 4 — superseded before calibration

Status: superseded at 0/10 runs.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `7806b2c24d587c0aec67867f2ede46fc8b7b923021d0adc9b9a3ce7f08476a2d`
- tests: `768e83a993e586a1001c6539ed347c3f3ffc9bd5b07c47129d92f2dce6898f38`
- reference: `27c7a903e1a8302c3c4efdeb725f991a4ced7bbd79d44a2e87f6f5859bc51e33`
- explanation: `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

The prompt and reference were unchanged. The grader no longer compared
complete plan values or called private CLI helpers; process-level conflict and
expired-OAuth request-count probes cover the same public requirements. The
exact-version 11-mutant false-positive audit is complete. The ten-run batch has
not started. Reviewer feedback then identified a redundant success-path
sentence and a two-connection process oracle.

## Canonical version 5 — superseded before calibration

Status: superseded at 0/10 runs.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `05d61e4f9e1f207e8b08fbee86dfb811cfc07abf780bc4504fb467aa818b5935`
- tests: `11590b3289d6462bd401c24a69e61fc2fa74d7b0abad5fa64dc41e069d42e553`
- reference: `27c7a903e1a8302c3c4efdeb725f991a4ced7bbd79d44a2e87f6f5859bc51e33`
- explanation: `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

The redundant valid-success sentence is gone. Successful local verification
must produce some network continuation, but the grader no longer assumes
separate refresh and remote-flow requests. The exact-version 11-mutant
false-positive audit completed, but reviewer feedback then identified
under-tested public schema boundaries. No solver run was spent or carried
forward.

## Canonical version 6 — superseded before calibration

Status: superseded at 0/10 runs.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `05d61e4f9e1f207e8b08fbee86dfb811cfc07abf780bc4504fb467aa818b5935`
- tests: `6fbcdc32575730de5abeb88ebb4164f501f75dcec6a96daa7ebf52349c2be098`
- reference: `27c7a903e1a8302c3c4efdeb725f991a4ced7bbd79d44a2e87f6f5859bc51e33`
- explanation: `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

The grader now observes actual top-level control values, generated directory
record shape, malformed directory metadata, and unsafe absolute or
parent-traversal paths. The nextest filter uses the equivalent default
contains spelling and selects all named entities. The exact-version
14-mutant false-positive audit is complete. Reviewer feedback then exposed an
unclassifiable synthetic wrapper testcase and an unfair unpaired project
selector in the offline write fixture. No solver run was spent or carried
forward.

## Canonical version 7 — superseded before calibration

Status: superseded at 0/10 runs.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `05d61e4f9e1f207e8b08fbee86dfb811cfc07abf780bc4504fb467aa818b5935`
- tests: `03781d163e0d9d61df133e6a077931e3831862cf815eccb0a0dbb159183f8007`
- reference: `27c7a903e1a8302c3c4efdeb725f991a4ced7bbd79d44a2e87f6f5859bc51e33`
- explanation: `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Test-only `new` still exits 101 when the solution-owned controller is absent,
but the runner fallback now marks its synthetic `new.run` testcase skipped so
it cannot pollute the regression or fail-to-pass census. Offline write uses no
remote selector. Invalid apply uses paired project and environment selectors,
so its local zero-request refusal is reconciliation-specific. The exact
14-mutant audit, 19-test macOS lane, and network-disabled 483/21 Linux lanes
were repeated. Prototype commands and mutation trials are not solver runs and
must not be counted.

## Canonical version 8 — superseded after invalid environment runs

Status: superseded at 0/10 valid runs.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `05d61e4f9e1f207e8b08fbee86dfb811cfc07abf780bc4504fb467aa818b5935`
- tests: `cd51d0d25782d0eb17c50bf57c7d4bc8d45250240bb43fadab587ba0157f21d2`
- reference: `3b1b56bdafa4b977627b41e97358b9cda0ea963c67bcaa2ee72b48d13c532bcc`
- explanation: `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Nine solution-only self-tests were removed without changing production
behavior. Four decoded tar-path comparisons now ignore stream order while
retaining normalized path-set, content, metadata, and plan-order assertions.
The exact wrapper census is 474 p2p, 21 f2p, one skipped synthetic placeholder,
and no unclassified entity. Host and network-disabled Linux reference base
lanes both pass the same 474 entities; reference `new` passes 19 on macOS and
21 on Linux. The 14-mutant exact-version audit was repeated with no actionable
survivor. No solver run was spent or carried forward.

Before recommending or spending a run, reread `CALIBRATION_STRATEGY.md`.
Target the standard ten-run batch and interpret the resulting solve count only
for this immutable version. Any artifact change creates a new level, requires
all gates again, and resets the new level to 0/10. Unused runs and evidence do
not carry forward.

## Canonical version 9 — superseded after calibration evidence

Status: superseded after 2/2 legitimate solver runs passed.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `bc682a86ed12764b43e6251586a62e4dd8366ad126c1828448aadb9f776c50c1`
- tests: `26a8751b9ddf9abccf1975e0cde75db436807914d87482308ade93b2de56b741`
- reference: `be61c9cad6bb3c1c478ed1141d84e1418e63c7b65783b3fb78e4007137cc5c59`
- explanation: `70ee500b728e09d24aae9655da168f324dc37b0d0cf813bb8042141ba9a30302`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

The earlier supplied official Nova results are invalid environment failures:
the wrapper fallback deleted each participant's `pub mod deploy_plan` export
before compilation, so no behavioral test ran. Corrected version-8 diagnostic
replay was 21/21 for Run 1 and 14/21 for Run 2; neither counts as calibration.

Version 9 removes the grader's overlapping `src/controllers/mod.rs` edit,
filters task-owned solver self-tests out of baseline accounting, and
de-couples Run 2's root omission from unrelated schema fixtures. It adds one
public coherent-plan-snapshot requirement and one malformed-plan-before-network
process oracle. Under the repaired exact harness:

- reference: 474/474 base, 20/20 macOS grader, 23/23 Linux grader;
- Run 1 replay: 474/474 base and 22/23 Linux grader, failing only coherent
  snapshot formation;
- Run 2 replay: 474/474 base and 22/23 Linux grader, failing only selected-root
  identity.

The exact 14-mode false-positive audit is complete, and the authoritative
wrapper census is 474 p2p, 23 f2p, one skipped synthetic fallback, and no
unclassified entity. These replays are design evidence, not solver runs for
version 9.

The later `agent-runs2` batch produced two legitimate complete solves at these
exact hashes: both passed 474/474 base and 23/23 new. Per the local 2/2 harden
rule, version 9 was revised immediately. Those two runs remain version-9
calibration evidence only and do not carry into version 10.

## Canonical version 10 — superseded before calibration

Status: superseded at 0/10 valid runs by a prompt-only cleanup.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `96ff6ae0eb5c125f0b643a94f67e901e4d25c27488d8b314b5421bb082c93e9b`
- tests: `440e3c1c6e7f7a48988f192650bbd272d554d95abf8df280438af4fe3b8e928c`
- reference: `135c2aef81648d28c7414af6fdc0b4a50e12b6876aa1465174e745dcf0770b0c`
- explanation: `e659d30558fa1548f62b7c04035c7eefe95c3d69b8c1b8b874f198eac94b469b`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 10 strengthens three independent public boundaries:

- planning detects same-size, same-mode in-place modification through stable
  descriptor modification time;
- public offline root resolution distinguishes a linked parent from an
  explicit project rooted at the current directory;
- write and invalid apply make zero requests without relying on caller-set
  updater, telemetry, tracking, or CI opt-outs.

The reference passes 474/474 base, 21/21 macOS grader, and 24/24
network-disabled Linux grader entities. Test-only accounting is 474 p2p, one
skipped synthetic fallback, and no unclassified entity. Both new version-9
solvers replay at 474/474 base and 23/24 new, failing only the strengthened
snapshot branch; the earlier near-pass is 474/474 and 21/24 across snapshot
and selected-root families. These are design replays, not version-10
calibration.

The exact false-positive audit was complete, but reviewer feedback removed one
redundant explanatory sentence from the prompt before any run was spent.
Version 10 is therefore historical.

## Canonical version 11 — superseded before calibration

Status: superseded at 0/10 valid runs after the external reference race
failure.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `55df6607e9a306939ec5a6b51b7da24aa8c87bcc32d82b4f6531d9460665d577`
- tests: `440e3c1c6e7f7a48988f192650bbd272d554d95abf8df280438af4fe3b8e928c`
- reference: `135c2aef81648d28c7414af6fdc0b4a50e12b6876aa1465174e745dcf0770b0c`
- explanation: `e659d30558fa1548f62b7c04035c7eefe95c3d69b8c1b8b874f198eac94b469b`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 11 removes only a redundant expansion of the ordinary-upload
source-root parity requirement. Tests, reference behavior, discriminator
families, validation counts, and environment remain byte-for-byte unchanged.
The exact prompt-level false-positive review confirms that the root-resolution
oracle is still supported by the retained high-level requirement.

No run was spent. The reference reliability correction created version 12.

## Canonical version 12

Status: superseded at 0/10 by the version-13 prompt cleanup.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `210c0849e50feb2ddb9ece2c63f80a38c026f5a9376c4c45fc2df9d92ec7f7be`
- tests: `440e3c1c6e7f7a48988f192650bbd272d554d95abf8df280438af4fe3b8e928c`
- reference: `be78e955fb5ccaf40357b6921c4253f32b00ec2d6b74d1cda6a3f8ec38fd2340`
- explanation: `05ef56f662047b1c1f5f200540cd44d274bc17f14a7d804e46125591c96cf8e9`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

The reference passes 474/474 Linux base, 24/24 Linux new with zero
failures/errors/skips in JUnit, and 21/21 macOS new. The snapshot entity passed
20 consecutive exact-image repetitions. However, the exact false-positive
audit records the old reference as a timing-dependent survivor: it passed five
local repetitions and failed the external verifier. Do not spend calibration
runs until that public oracle is made deterministic without prescribing a
private read architecture, or is removed and the difficulty is redesigned.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 13

Status: superseded after an observed 2/10 calibration batch.

Version 13 removes one redundant final sentence from Test assumptions. The
strict schema, version, ordering, metadata, digest, and rejection requirements
remain explicit earlier in the prompt. No executable artifact changed.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `a820a076e28b7a9129a40d47a670ebb68a5ce4a12699eccaf007d3fc0989aa22`
- tests: `440e3c1c6e7f7a48988f192650bbd272d554d95abf8df280438af4fe3b8e928c`
- reference: `be78e955fb5ccaf40357b6921c4253f32b00ec2d6b74d1cda6a3f8ec38fd2340`
- explanation: `05ef56f662047b1c1f5f200540cd44d274bc17f14a7d804e46125591c96cf8e9`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

The supplied `agent-runs3` batch preserved all 474 baseline entities in every
run. `Nova_Nova_1` and `Orion_Nova` were reported as complete passes, giving
the immutable version an official observed solve rate of 2/10. Six Nova runs
failed only the snapshot entity; `Nova_Nova_5` failed two pre-network apply
entities; and `Nova_Nova_4` combined those misses with the snapshot miss.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | pass | `agent-runs3/Nova_Nova_1/trajectory.json` | `agent-runs3/Nova_Nova_1/eval-result.json` | 474 base; 24/24 new |
| 2 | fail | `agent-runs3/Nova_Nova_2/trajectory.json` | `agent-runs3/Nova_Nova_2/eval-result.json` | 474 base; 23/24 new |
| 3 | fail | `agent-runs3/Nova_Nova_3/trajectory.json` | `agent-runs3/Nova_Nova_3/eval-result.json` | 474 base; 23/24 new |
| 4 | fail | `agent-runs3/Nova_Nova_4/trajectory.json` | `agent-runs3/Nova_Nova_4/eval-result.json` | 474 base; 21/24 new |
| 5 | fail | `agent-runs3/Nova_Nova_5/trajectory.json` | `agent-runs3/Nova_Nova_5/eval-result.json` | 474 base; 22/24 new |
| 6 | fail | `agent-runs3/Nova_Nova_6/trajectory.json` | `agent-runs3/Nova_Nova_6/eval-result.json` | 474 base; 23/24 new |
| 7 | fail | `agent-runs3/Nova_Nova_7/trajectory.json` | `agent-runs3/Nova_Nova_7/eval-result.json` | 474 base; 23/24 new |
| 8 | fail | `agent-runs3/Nova_Nova_8/trajectory.json` | `agent-runs3/Nova_Nova_8/eval-result.json` | 474 base; 23/24 new |
| 9 | fail | `agent-runs3/Nova_Nova_9/trajectory.json` | `agent-runs3/Nova_Nova_9/eval-result.json` | 474 base; 23/24 new |
| 10 | pass | `agent-runs3/Orion_Nova/trajectory.json` | `agent-runs3/Orion_Nova/eval-result.json` | 474 base; 24/24 new |

Version-14 exact replay later showed that both reported passes compare
descriptor `ctime` and fail the existing atomic-replacement invariant when its
watcher observes the intended window. This does not rewrite the official v13
2/10 result; it records why that result cannot carry into a revised version.

## Canonical version 14

Status: superseded by version 15 at calibration 0/10.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `83a9c0968716b32e2a4c2560746efbc17d82684f79b127dfd328e965fd56ed80`
- tests: `d1c6efb4aa1077913ecfb72ba69e6efc19ce9fc02017f609bf72786e710e5fc0`
- reference: `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b`
- explanation: `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

The prompt narrows option comparison to the two persisted controls and removes
the named Test Assumptions API. The reference rejects mode-less Unix records.
The grader adds public CLI option-mismatch and unsupported-socket probes,
separate size-only and mode-only descriptor races, bounded serialized watcher
loops, and diagnostic-preserving fallback JUnit.

Exact network-disabled Linux results are 474/474 base and 28/28 new with zero
failures, errors, or skips. macOS new is 23/23. Five isolated mutants are
rejected, the atomic reference test passes five consecutive repetitions, and
the complete false-positive record is in `FALSE_POSITIVE_AUDIT.md`.

No version-13 run carries forward. A new ten-run batch for these exact hashes
starts at zero.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 15

Status: superseded by version 16 at calibration 0/10.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `2d90da444a11e28174359472310ab6ef1e9e040049753480bbe4f6779da18536`
- tests: `9de6aaafeab48b579193eec31b3dc811c4327bc0898d92ea5ff4318eba3b1a57`
- reference: `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b`
- explanation: `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 15 restores only the compile interface required by the grader and adds
two explicit reader branches within the existing strict-schema test entity.
The historical reported pass and representative near-pass both satisfy those
branches. Exact network-disabled Linux results are 474/474 base and 28/28 new
with zero failures, errors, or skips; macOS new is 23/23. The exact
false-positive audit kills both permissive-reader mutants.

No version-13 or version-14 run carries forward. A new ten-run batch for these
exact hashes starts at zero.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 16

Status: superseded by version 17 at calibration 0/10.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `c63130a29db775e2d34ff6349cfa1c6bebde708273eea732235c05c033b02046`
- tests: `b9d5bdd33a89e702f25a75f7bfde4b9caddbf078a329cce9fa47312e3bda56aa`
- reference: `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b`
- explanation: `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 16 explicitly documents the selected-root `"."` entry, removes the
pre-existing upload helper from Test assumptions, and relaxes flag conflicts
from exit code 2 to any non-zero status with a diagnostic naming the supplied
options. Exact results are 474/474 network-disabled Linux base, 28/28
network-disabled Linux new with zero failures/errors/skips, and 23/23 macOS
new. The exact false-positive audit kills the root-omission and retained
strict-reader/late-network mutants.

No earlier run carries forward. A new ten-run batch for these exact hashes
starts at zero.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 17

Status: superseded by version 18 at calibration 0/10.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `e5bf0cacf57d9f9d486919224f43fc04684e99d82073d6a7792fe8171675ae79`
- tests: `b9d5bdd33a89e702f25a75f7bfde4b9caddbf078a329cce9fa47312e3bda56aa`
- reference: `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b`
- explanation: `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 17 removes one reader/serializer sentence already implied by the strict
schema paragraph. Every executable artifact is byte-identical to version 16.
Exact results are 474/474 network-disabled Linux base, 28/28
network-disabled Linux new with zero failures/errors/skips, and 23/23 macOS
new. Repeated reader and serializer mutants remain rejected.

No earlier run carries forward. A new ten-run batch for these exact hashes
starts at zero.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 18

Status: superseded by version 19 at calibration 0/10.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `dd0a8ea05ed813f74da325041962b655782a8209460ecbfd93e2fdcfd8fac838`
- tests: `745ec28c8b350ae1d98dfbbb838eaccc6407a6cf85428fefa1fecbe23ac54737`
- reference: `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b`
- explanation: `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 18 removes the accidental public `DeployPlan: Serialize` requirement,
defines archive paths as relative and without `..` components apart from the
root marker, and removes all conflict diagnostic-text expectations. Exact
results are 474/474 network-disabled Linux base, 28/28 network-disabled Linux
new with zero failures/errors/skipped testcases, and 23/23 macOS new.

No earlier run carries forward. A new ten-run batch for these exact hashes
starts at zero.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 19

Status: superseded by version 20 at calibration 0/10.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `4415e1706a5712107828028c4d060883ffc28e6e5d8932de90c62ba2c9c92c44`
- tests: `745ec28c8b350ae1d98dfbbb838eaccc6407a6cf85428fefa1fecbe23ac54737`
- reference: `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b`
- explanation: `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 19 removes only the internal prohibitions on pathname reopening and a
second source scan. The observable requirement that verified bytes become
archive bytes remains, and the unchanged atomic-replacement oracle rejects the
verify-then-reopen mutant after it passes all 474 baseline tests.

Exact results are 474/474 network-disabled Linux base, 28/28
network-disabled Linux new, and 23/23 macOS new.

No earlier run carries forward. A new ten-run batch for these exact hashes
starts at zero.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 20

Status: superseded by version 21 after a reviewer-reported 1/10 solve rate.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `fd4947f855b8aca3684960fe39f978efb5e83a00ca63853c817f2467b0d8e6c5`
- tests: `745ec28c8b350ae1d98dfbbb838eaccc6407a6cf85428fefa1fecbe23ac54737`
- reference: `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b`
- explanation: `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 20 removes only the abstract sentence describing each regular-file
record as a coherent descriptor-backed snapshot. The following concrete
non-regular, size, Unix-mode, and modification-change rejection rule remains.
Independent omissions of modification, size, and mode checks are rejected by
their matching synchronized Linux races.

Exact results are 474/474 network-disabled Linux base, 28/28
network-disabled Linux new, and 23/23 macOS new.

The external holistic review reports one legitimate solve in ten completed
runs. Individual version-20 run bundles were not added to this workspace, so
the aggregate is retained without inventing per-run identifiers. The reviewer
requested raw-reader ordering/uniqueness coverage and found a reference defect
in token/environment source-root parity.

No version-20 run carries into version 21.

## Canonical version 21

Status: superseded at calibration 0/10 by the version-22 atomic-replacement
fairness correction.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `2ebfb74eadff3739fe6f3ee0af959644c7bdaf8d375f132c3d272a3e876363be`
- tests: `fc7679b7296e78021877c22be6ad7276975cb96e274a1be0f2d38e8a70b17141`
- reference: `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889`
- explanation: `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 21 removes the benchmark-sounding heading, exercises raw unsorted and
duplicate plans through the public reader, extends apply root reconciliation
across linked, explicit-project, project-token, and environment targeting, and
fixes the reference to use the ordinary current-directory policy in the last
two modes.

Exact results are 474/474 network-disabled Linux base, 28/28
network-disabled Linux new, and 23/23 macOS new. Four isolated reader/root
mutants fail their matching focused assertions.

No earlier run carries forward. A new ten-run batch for these exact hashes
starts at zero.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 22

Status: superseded after a complete 3/10 batch.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `2ebfb74eadff3739fe6f3ee0af959644c7bdaf8d375f132c3d272a3e876363be`
- tests: `c6639ff612ba5144e5dd2fc800e8f96d5d043cd4717df763495f46e74760eebc`
- reference: `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889`
- explanation: `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 22 accepts either safe rejection of an observed atomic pathname
replacement or successful archiving of the complete verified old snapshot.
It still rejects a successful verify-then-reopen implementation that archives
replacement bytes.

Exact results are 474/474 network-disabled Linux base, 28/28
network-disabled Linux new, and 23/23 macOS new. The historical legitimate
conservative replay passes 28/28; the pathname-reopen mutant passes 27/28 and
fails the revised atomic assertion.

This exact version produced three nominal passes. Trajectory review then found
that each nominal pass omitted the public open-to-first-snapshot comparison and
passed a scheduler-dependent polling fixture. These results are historical
evidence for version 23 and do not carry forward.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | fail, 27/28 | `agent-runs4/Nova_Nova_1` | local evaluation | open-window omission |
| 2 | nominal pass, 28/28 | `agent-runs4/Nova_Nova_2` | local evaluation | false positive; deterministic v23 replay fails |
| 3 | fail, 26/28 | `agent-runs4/Nova_Nova_3` | local evaluation | open window plus token/environment root |
| 4 | fail, 27/28 | `agent-runs4/Nova_Nova_4` | local evaluation | open-window omission |
| 5 | fail, 27/28 | `agent-runs4/Nova_Nova_5` | local evaluation | open-window omission |
| 6 | nominal pass, 28/28 | `agent-runs4/Nova_Nova_6` | local evaluation | false positive; post-open descriptor samples only |
| 7 | nominal pass, 28/28 | `agent-runs4/Nova_Nova_7` | local evaluation | false positive; post-open descriptor samples only |
| 8 | fail, 27/28 | `agent-runs4/Nova_Nova_8` | local evaluation | open-window omission |
| 9 | fail, 27/28 | `agent-runs4/Nova_Nova_9` | local evaluation | explicit-project root selection |
| 10 | fail, 27/28 | `agent-runs4/Orion_Nova` | local evaluation | later snapshot mutation interval |

## Canonical version 23

Status: superseded after one supplied nominal pass was adjudicated a false
positive.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `858946bc4e4c6fc2bdfffda0def2d3fb910c967bed9735a1f8e9024f6f900d01`
- tests: `6ae1bc174f136556136d3d041a3307fbe6b2a092f9e087f60c77c1a490b663e7`
- reference: `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889`
- explanation: `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 23 uses synchronous Linux open/read barriers, adds raw-reader digest
and kind cases, and replaces subjective failure wording. Exact results are
474/474 network-disabled Linux base, 28/28 network-disabled Linux new, and
23/23 macOS new. The v22 Nova2 nominal pass now fails deterministically at the
open boundary. No actionable mutant survives the focused suite.

The supplied candidate passed 28/28 but rejected a valid `-hello.txt` source
because it assumed the globally sorted first entry was the `"."` root marker.
That result is design evidence for version 24 and does not carry forward.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | false positive, nominal 28/28 | supplied Nova adjudication | no local run artifact | positional root-marker assumption |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 24

Status: superseded after two legitimate failed calibration runs.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `858946bc4e4c6fc2bdfffda0def2d3fb910c967bed9735a1f8e9024f6f900d01`
- tests: `c678cf73834c743b3882ac7fd7c46d370f523bb550e1de6b7da3d3167b6f4e42`
- reference: `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889`
- explanation: `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 24 extends one existing entity with a `-hello.txt` source. Global
ordering places that entry before `"."`; ordinary upload, planning, and
verified archiving must all accept it. Exact results are 474/474
network-disabled Linux base, 28/28 Linux new, and 23/23 macOS new. The exact
Nova2 first-entry-root validator fails the strengthened entity with the
reported error.

No earlier run carried forward. Two version-24 Nova runs preserved all 474
baseline tests but passed only 22/28 and 23/28 new tests. Their repeated misses
were request suppression, root-marker position, and the open-to-first-metadata
snapshot interval; Run 1 additionally missed token/environment source-root
selection.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | fail, 22/28 | `agent-runs5/Nova_Nova_1` | local evaluation | incomplete request suppression, root-marker, snapshot, and target-root behavior |
| 2 | fail, 23/28 | `agent-runs5/Nova_Nova_2` | local evaluation | incomplete request suppression, root-marker, and snapshot behavior |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 25

Status: superseded before calibration; retained as historical evidence.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `858946bc4e4c6fc2bdfffda0def2d3fb910c967bed9735a1f8e9024f6f900d01`
- tests: `7de2674f9e78fb0a185ca3e36d538ca7ee2323ed6bd62a89325a440e23bc7c33`
- reference: `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889`
- explanation: `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 25 strengthens two existing entities without changing their names or
the 28/23 census. The public CLI now covers positional `PATH` with
`--path-as-root` across write, valid apply, and local option-mismatch
rejection. The reader receives a sorted embedded-parent record so entry
ordering cannot mask path validation.

Exact results are 474/474 network-disabled Linux base, 28/28 Linux new, and
23/23 macOS new. Prefix-only parent validation and offline current-directory
root selection each pass the other 22 macOS focused tests and all 474
regressions, then fail their strengthened entity.

No version-24 result carries forward. A new ten-run batch for these exact
hashes starts at zero.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 26

Status: historical; superseded by version 27 after six calibration runs.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `858946bc4e4c6fc2bdfffda0def2d3fb910c967bed9735a1f8e9024f6f900d01`
- tests: `f22d253cee5821b686d6112f8c6a979c081349dc6676cd2ff07149d6562dfbae`
- reference: `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889`
- explanation: `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`
- Linux image: `5e5fd4b380bebeebd6f553a23ae7227f0b3e31fa3f6538b30bb4318017aafc7e`

Version 26 strengthens the existing public CLI option entity with the
independent `--no-gitignore` mismatch branch, replaces fixed-delay proxy
observation with a channel-coordinated listener snapshot, and reports nonzero
no-JUnit runner outcomes as classified failures with diagnostics.

Exact results are 474/474 network-disabled Linux base, 28/28 Linux new, and
23/23 macOS new. A public command that hard-codes `no_gitignore=false` passes
the other 22 macOS focused entities and all 474 regressions, then fails the
strengthened CLI entity. Test-only Linux produces one classified fail-to-pass
JUnit entity with the unresolved-controller diagnostic.

No version-25 result carries forward. A new ten-run batch for these exact
hashes starts at zero.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 27

Status: historical; superseded by version 28 at calibration 0/10.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `47f4e4acd2eb5210f31d3ef933a9695bc5b844bf22b72d84a7e5254d36709715`
- tests: `3654aef8c014b318a7c34f98ffa40c3c0157f9bacf5f8e4a1cc6e03dd1ab62ad`
- reference: `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889`
- explanation: `9dd90f00ef21df6fd8452d1cc74115d62b203a11a09fbbb8c84f6f86e0172880`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`
- Linux image: `7a6c1bf366e560afad8405c3a1eb94c0bd01f023a0d606c1b63cafcc2bc09e5e`

Version 27 requires metadata stability while file contents are read and no
longer rejects implementations solely for beginning their coherent snapshot at
the first opened-descriptor metadata sample. It also captures the real public
upload body after a post-verification source mutation and requires the archived
file to contain the verified bytes.

Exact results are 474/474 network-disabled Linux base, 28/28 Linux new,
474/474 macOS base, and 23/23 macOS new. A discard-and-rebuild mutant passes
474/474 and 27/28, failing only the strengthened valid-apply entity. The exact
`agent-runs7/Nova_Nova_3` patch now passes 474/474 and 28/28, providing a
participant-side complete replay.

All version-26 results are historical. A new ten-run batch for these exact
hashes starts at zero.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 28

Status: historical; superseded by version 29 at calibration 0/10.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `47f4e4acd2eb5210f31d3ef933a9695bc5b844bf22b72d84a7e5254d36709715`
- tests: `eaf6275a57d92f0dc2beec6ae24100d43645a3f8fd1ac191deafde32fb2c0e47`
- reference: `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889`
- explanation: `9dd90f00ef21df6fd8452d1cc74115d62b203a11a09fbbb8c84f6f86e0172880`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`
- Linux image: `2cf635768bb6cecda709bae108d7f095cacae388fa1b345a39eb1111f18e834e`

Version 28 changes only the grader-owned test selector. It removes the
`Cargo.toml` feature hunk that collided with a participant dependency and uses
a checked compiler cfg supplied by `test.sh` in `new` mode. The prompt,
reference, behavioral assertions, and 28/23 Linux/macOS census are unchanged.

The exact reference passes 474/474 network-disabled Linux base and 28/28 new.
The Cargo fallback runs the same 20 controller and 8 CLI entities. Nova 6 now
assembles with its manifest edit intact and reaches 25/28 instead of failing
before discovery. The discard-and-rebuild mutant remains isolated at 27/28,
failing the verified public upload-body entity.

All version-27 results are historical. A new ten-run batch for these exact
hashes starts at zero.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 29 — historical

Status: fairness-corrected exact revision; calibration starts at 0/10.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `47f4e4acd2eb5210f31d3ef933a9695bc5b844bf22b72d84a7e5254d36709715`
- tests: `d48876ff5cb1c73bec776eab3fb15e7f1adccc2941fb5a71288f7b7c6b6b23d4`
- reference: `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889`
- explanation: `9dd90f00ef21df6fd8452d1cc74115d62b203a11a09fbbb8c84f6f86e0172880`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`
- Linux image: `84cff552b256bfff4cbc24ea529edf8e34a8468a8487d1f998a948e0251a092f`

Version 29 supplies the ordinarily required environment selector to the
explicit-project write fixture. The same entity continues to distinguish
linked-parent from current-directory roots and to enforce offline write plus
pre-request apply reconciliation. No participant-facing artifact or reference
code changed.

Exact results are 474/474 Linux base, 28/28 Linux new, 474/474 macOS base,
23/23 macOS new, and 28/28 through the Linux Cargo fallback. Nova 6 remains
25/28 and the discard-and-rebuild mutant remains 27/28.

All version-28 results are historical. A new ten-run batch for these exact
hashes starts at zero.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 30 — historical, superseded at 0/10

Status: I/O-mechanism fairness correction complete; calibration starts at
0/10.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `5ef4f164004f3856a96fe3737f4141c3b801963236016090bdc52dff0489fa3f`
- tests: `5e898074a9f73e23e60105290fc211d848c6e386e6483fdd9a53ef8a69b1fb7c`
- reference: `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889`
- explanation: `9dd90f00ef21df6fd8452d1cc74115d62b203a11a09fbbb8c84f6f86e0172880`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`
- Linux reference base image used with exact source binds:
  `84cff552b256bfff4cbc24ea529edf8e34a8468a8487d1f998a948e0251a092f`

Version 30 removes the four Linux entities whose mutation point depended on an
undisclosed libc `read(2)` hook and removes their matching prompt obligation.
It preserves the public captured-upload-body discriminator. The cargo fallback
now reports every discovered test rather than synthesizing one failure after a
successful run.

Exact results are 474/474 macOS base, 23/23 macOS new, and 24/24
network-disabled Linux new. Cargo fallback JUnit is 23/23 with zero skips.
Test-only JUnit is one diagnostic failure with zero skips. Exact Nova 3 and
`pread`/no-stability legitimate variants pass; the discard-and-rebuild mutant
remains isolated at 22/23 after passing all 474 regressions.

All version-29 results are historical. A new ten-run batch for these exact
hashes starts at zero.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 31 — historical, superseded at 0/10

Status: reference pathname-identity hardening complete; calibration starts at
0/10.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `5ef4f164004f3856a96fe3737f4141c3b801963236016090bdc52dff0489fa3f`
- tests: `5e898074a9f73e23e60105290fc211d848c6e386e6483fdd9a53ef8a69b1fb7c`
- reference: `52cfd1502465ef484db613a95d0d41430a7a28da4ade565bac40d45108e7ac14`
- explanation: `cd54d38e8ce2f6c5256de0a595e90940d35124a7115601ee8a857761f84b14bc`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 31 changes only the reference and its explanation. Stable Unix
snapshots now require the followed pathname to retain the opened descriptor's
device/inode identity after reading. The participant-facing prompt and hidden
suite remain byte-identical to version 30.

Exact macOS results are 474/474 baseline and 23/23 focused. Cargo fallback is
23/23 with zero skips; test-only mode is one diagnostic failure with zero
skips. The identity-free participant mode remains a legitimate 23/23 pass.
The discard-and-rebuild false positive is 474/474 plus 22/23 and remains killed
only by the captured-upload-body entity.

All version-30 results are historical. A new ten-run batch for these exact
hashes starts at zero.

| Run | Outcome | Trajectory | Evaluation | Notes |
|---:|---|---|---|---|
| 1 | not run | — | — | — |
| 2 | not run | — | — | — |
| 3 | not run | — | — | — |
| 4 | not run | — | — | — |
| 5 | not run | — | — | — |
| 6 | not run | — | — | — |
| 7 | not run | — | — | — |
| 8 | not run | — | — | — |
| 9 | not run | — | — | — |
| 10 | not run | — | — | — |

## Canonical version 32 — historical, superseded after 8/10

Status: valid-apply transport repair calibrated, then superseded by the
version-33 prompt clarification.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `5ef4f164004f3856a96fe3737f4141c3b801963236016090bdc52dff0489fa3f`
- tests: `850fa6491c50eb0e021a03340108eaf250706c323f5c1af3f4a8ca6580617851`
- reference: `52cfd1502465ef484db613a95d0d41430a7a28da4ade565bac40d45108e7ac14`
- explanation: `cd54d38e8ce2f6c5256de0a595e90940d35124a7115601ee8a857761f84b14bc`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Four Nova and four Orion runs all preserve 474/474 baseline tests. Focused
results are 21-23 of 24; every run fails root-position independence, and all
four Orion runs are otherwise 23/24. These results motivated the version-33
clarification and cannot be carried forward.

## Canonical version 33 — accepted

Status: accepted on 2026-07-29 after the root-order clarification and complete
startup, reference, false-positive, fairness, harness, and patch-integrity
gates.

Immutable identities:

- base: `4d49d9845a27a0947ab903b01789eb9f854414d8`
- prompt: `6674edbce3495a8d3dfba725ba769b0fa8a633cc94054f55bee2b4049799f8cd`
- tests: `850fa6491c50eb0e021a03340108eaf250706c323f5c1af3f4a8ca6580617851`
- reference: `52cfd1502465ef484db613a95d0d41430a7a28da4ade565bac40d45108e7ac14`
- explanation: `cd54d38e8ce2f6c5256de0a595e90940d35124a7115601ee8a857761f84b14bc`
- Dockerfile: `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`

Version 33 adds one schema clarification and leaves every executable artifact
byte-identical to version 32. Exact Linux results are 474/474 baseline and
24/24 focused; cargo fallback is 24/24; test-only is one diagnostic failure
with zero skips. The discard-and-rebuild false positive is 474/474 plus 23/24
and is killed only by the captured uploaded-byte oracle.

All earlier calibration remains historical and version-bound. Acceptance is
the final outcome; this record does not infer an additional solve-rate result.
The raw batch artifacts are archived under
`archive/railway-deployment-bundle/`, with the compact index in `RUNS.md`.
