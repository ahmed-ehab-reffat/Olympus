# RUNS - PcapPlusPlus section-aware PCAPNG filtered copy

Status: accepted on 2026-08-01.

Raw local, platform, retired L2/L3, and retired L5 trajectories are archived in
`archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz`. The preserved
archive roots are `estimate_trajectories`, `agent-runs1`, `agent-runs2`,
`agent-runs3`, and `agent-runs4`.

Before acceptance, exact L6 stood at local 0/2 and platform 0/10. Prompt,
tests, and reference behavior changed during trajectory hardening, so no
predecessor result counts toward L6. The user-confirmed acceptance is recorded
as the platform outcome, not as a relabeling of those historical runs.

The L4 version was fully audited but retired before calibration because its
minor-version rejection was unfair.

## Predecessor trajectory evidence

| Run | Predecessor focused | Base | Production files | Strict effective production additions | Message/tool events | Architecture |
|---|---:|---:|---:|---:|---:|---|
| `run_gpt-5.6-sol_1` | 6/6 | 70/70 | 4 | 420 | 72 | Buffered raw scanner plus BPF wrapper extension |
| `run_gpt-5.6-sol_2` | 6/6 | 70/70 | 2 | 525 | 54 | Stream-offset copy plan with temporary staging |
| `Nova_Nova` | 6/6 | 69/69 | 2 | about 267 | 54 tool calls | Streaming raw scanner, section-local interface vector, staged destination |

All three are legitimate passes. They confirm that the predecessor
reference's size did not predict participant work, but their 3/3 result also
confirms the need for a harder public discriminator.

## L2 replay

Each predecessor solution patch applies cleanly beside the L2 tests. Each
passes these eight scenarios:

- `StructureAndFiltering`
- `InterfaceSelection`
- `OptionPreservation`
- `ReaderLifecycle`
- `NoMatchingPackets`
- `MalformedFraming`
- `MalformedReferences`
- `UnsupportedAndIo`

Each fails only `MalformedOptions`. The replay shows that the interface and
Custom Option tests close genuine coverage holes without rejecting existing
valid architectures, while inner option/record framing provides the new
independent difficulty boundary.

Replays are design and false-positive evidence, not calibration results.

## Retired L2 working-pool batch

| Run | Base | L2 focused | Production additions | Architecture |
|---|---:|---:|---:|---|
| `Nova_Nova_1` | 69/69 | 9/9 | 550 in its new source, plus declaration/build edits | Streaming input abstraction and temporary output |
| `Nova_Nova_2` | 69/69 | 9/9 | 452 in the existing source, plus declaration | Whole-input buffer, optional Zstd path, temporary output |
| `Nova_Nova_3` | 69/69 | 9/9 | 427 in the existing source, plus declaration | LightPcapNg input and buffered section output |
| `Nova_Nova_4` | 69/69 | 9/9 | 532 in its new source, plus declaration/build edits | Streaming scanner with richer interface state |

This 4/4 unhinted result retired L2 under the 50% cap. The implementations are
independent and substantive; the outcome is not attributed to leakage or
insufficient LOC.

## L3 replay

All four retired L2 patches apply cleanly beside the L3 tests:

| Run | L3 result | Distinguishing outcome |
|---|---:|---|
| `Nova_Nova_1` | 10/11 | Fails only `OptionTermination` |
| `Nova_Nova_2` | 10/11 | Fails only `OptionTermination` |
| `Nova_Nova_3` | 11/11 | Accepts block-end option-list termination |
| `Nova_Nova_4` | 10/11 | Fails only `OptionTermination` |

The replay produces a 1/4 retrospective split and varies the discriminator
away from the shared malformed-input case that separated the earlier L1
solutions from L2. It remains trajectory evidence only; L3 starts at 0/10.

## Retired L3 working-pool batch

Three runs completed; the fourth contains only an unfinished workspace diff
and has no evaluation, solution patch, or JUnit result.

| Run | Base | L3 focused | Production shape | Architecture |
|---|---:|---:|---|---|
| `Nova_Nova_1` | 69/69 | 10/11 | 435 production additions plus repository tests | Light input, per-section memory buffer, staged destination |
| `Nova_Nova_2` | 69/69 | 10/11 | 472 production additions | Streaming Light input and seekable temporary output |
| `Nova_Nova_3` | 69/69 | 10/11 | 536 production additions plus repository tests | Dedicated streaming source, copied BPF wrapper, richer IDB state |

Every completed run failed only `OptionTermination`. The implementations are
legitimate and substantially above the 200-line floor, but the shared failure
means the subtle option-reader rule became the entire difficulty gate. The
batch is retired at 0/3 rather than extended under a changed prompt.

## L4 exact replay

Raw replay preserves the historical result and exposes two additional
independent boundaries:

| Run | Raw L4 result | Raw failures |
|---|---:|---|
| `Nova_Nova_1` | 12/14 | `OptionTermination`, `LocalUseOpacity` |
| `Nova_Nova_2` | 12/14 | `OptionTermination`, `ReservedFieldOpacity` |
| `Nova_Nova_3` | 13/14 | `OptionTermination` |

Because L4 now states the option-list rule directly, a second replay changes
only each implementation's natural-exhaustion return from `false` to `true`:

| Run | Prompt-normalized L4 result | Distinguishing outcome |
|---|---:|---|
| `Nova_Nova_1` | 13/14 | Fails only `LocalUseOpacity` |
| `Nova_Nova_2` | 13/14 | Fails only `ReservedFieldOpacity` |
| `Nova_Nova_3` | 14/14 | Passes |

All three implementations pass `DefaultAndClearedFilter`; that test closes a
reported false positive without being used as an artificial differentiator.
The normalized 1/3 split is the relevant design projection, not a calibration
result. L4 starts at 0/10.

## L5 fairness replay

Removing the SHB 1.1 rejection does not change the solver replay outcomes:

| Run | Raw L5 result | Prompt-normalized L5 result |
|---|---:|---:|
| `Nova_Nova_1` | 12/14: option termination and local-use opacity | 13/14: local-use opacity only |
| `Nova_Nova_2` | 12/14: option termination and reserved-field opacity | 13/14: reserved-field opacity only |
| `Nova_Nova_3` | 13/14: option termination only | 14/14 pass |

All six exact replays compile. L5 does not count these retrospective outcomes
as calibration and starts at 0/10.

## L5 calibration and L6 replay

The exact L5 `agent-runs4/` batch completed ten unhinted working runs:

| Run | L5 focused | Baseline | L6 replay | Distinguishing L6 result |
|---|---:|---:|---:|---|
| `Nova_Nova_1` | 14/14 | 69/69 | 15/16 | `DiscardedPacketOptions` only |
| `Nova_Nova_2` | 14/14 | 69/69 | 15/16 | `DiscardedPacketOptions` only |
| `Nova_Nova_3` | 10/14 | 69/69 | 11/16 | DSB family plus `DiscardedPacketOptions` |
| `Nova_Nova_4` | 14/14 | 69/69 | 15/16 | `DiscardedPacketOptions` only |
| `Nova_Nova_5` | 10/14 | 69/69 | 11/16 | DSB family plus `DiscardedPacketOptions` |
| `Nova_Nova_6` | 14/14 | 69/69 | 16/16 | Pass |
| `Nova_Nova_7` | 14/14 | 69/69 | 16/16 | Pass |
| `Nova_Nova_8` | 14/14 | 69/69 | 15/16 | `DiscardedPacketOptions` only |
| `Nova_Nova_9` | 14/14 | 69/69 | 15/16 | `DiscardedPacketOptions` only |
| `Nova_Nova_10` | 9/14 | 69/69 | 11/16 | Multi-section/DSB family; new discriminator passes |

L5's 7/10 result exceeds the 50% cap. Static patch inspection and raw
trajectory review show that every run used a const-qualified signature and a
temporary-file publication path. All ten therefore compile the L6 const call
and pass its isolated same-path fixture. Among the seven L5 passes, only Nova
6 and 7 defer EPB option validation until after a positive filter result; they
are the two exact L6 replay passes. These are retrospective projections, not
L6 calibration results.

## Railway design reference

The Railway pass/near-pass/broad-failure evidence informing the original
size-risk decision remains recorded in `DESIGN.md`. It does not count toward
this problem's batch.

## Accepted artifact

The platform accepted exact L6 on 2026-08-01. Its immutable SHA-256 identities
are:

- `meta.md`: `d527f61ce418cd97a765c3b2705961db1b76b6e6beddeae1f358ef114392630e`
- `test.patch`: `00d7213a423facc6ca47b43d2ba5eb2f5365e303eac9e1a45ae002c26d54cfe8`
- `solution.patch`: `1f228c09ddab23d64d57791964c8f33008565560cc84fc56e686b4cf3ab514bf`
- `solution_approach.md`: `c00e34a724b0e84f362ed59bacb31150e9f26c6c020c1f9bd52fc79921a3d87b`
- `Dockerfile`: `70e8b8f853700ac56afb0738fec87c972782041f57336fc442668a8b55bca7ff`
