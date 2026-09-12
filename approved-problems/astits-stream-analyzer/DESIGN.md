# DESIGN.md — astits-stream-analyzer

Repo: https://github.com/asticode/go-astits (MIT, 615 stars, Go, last source commit 2026-05-14)
BASE_COMMIT: 5fcd7d85573d2d8330c01b0e98cba71149732b09

## 1. Title

Add a transport-stream analyzer to the demuxer

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (`PLAYBOOK § Pattern 12`) — a new subsystem whose difficulty is a
  subtle, stateful correctness kernel rather than breadth of API.
- Pass-rate target: design to 1/10 (10%), the corpus mode. Live cap is <=40%; 0% = reject.
- Best agent: Mixed (Orion-alone is the historical solver for this shape).
- Dominant verdict: MISSED_REQUIREMENT / WRONG_LOGIC on the clock kernel.

## 3. Public API surface

- `Analyzer` — the analyzer object.
- `NewAnalyzer(o AnalyzerOptions) *Analyzer` — constructor.
- `(*Analyzer).Packet(p *Packet)` — feed one transport packet in stream order.
- `(*Analyzer).Data(d *DemuxerData)` — feed one parsed data unit in stream order.
- `(*Analyzer).Report() *AnalyzerReport` — finalize and return the report.
- `AnalyzerOptions{MaxPCRInterval, MaxPATInterval, MaxPMTInterval time.Duration}` — zero fields take
  defaults 40ms / 500ms / 500ms.
- `DemuxerOptAnalyzer(a *Analyzer) func(*Demuxer)` — demuxer option; the demuxer feeds packets and data.
- `AnalyzerReport{Packets int, Events []AnalyzerEvent, PIDs []AnalyzerPIDStat, Programs []AnalyzerProgram}`
- `AnalyzerEvent{Kind AnalyzerEventKind, PID uint16, PacketIndex int, Time int64, Expected uint8, Actual uint8}`
- `AnalyzerEventKind` with `AnalyzerEventKindTransportError`, `AnalyzerEventKindUnreferencedPID`,
  `AnalyzerEventKindScramblingError`, `AnalyzerEventKindContinuityError`,
  `AnalyzerEventKindPCRDiscontinuityError`, `AnalyzerEventKindPCRRepetitionError`,
  `AnalyzerEventKindPATRepetitionError`, `AnalyzerEventKindPMTRepetitionError`,
  `AnalyzerEventKindPTSOrderError`, `AnalyzerEventKindDTSOrderError` (declared in that order).
- `AnalyzeStream(ctx context.Context, r io.Reader, o AnalyzerOptions) (*AnalyzerReport, error)` — demux a
  whole reader and report.
- `AnalyzerPIDStat{PID uint16, Packets int, ScrambledPackets int, PayloadBytes int, ContinuityErrors int,
  Discontinuities int, PCRs int, FirstTime int64, LastTime int64, MinPCRInterval int64,
  MaxPCRInterval int64, Bitrate int64}`
- `AnalyzerProgram{Number uint16, PMTPID uint16, PCRPID uint16, ElementaryPIDs []uint16, MissingPIDs []uint16}`

## 4. Canonical output form

- `Events` in packet order; within one packet in the fixed kind order, named explicitly in meta.md (transport, unreferenced,
  scrambling, continuity, PCR discontinuity, PCR repetition, PAT repetition, PMT repetition, PTS order,
  DTS order).
- `PIDs` sorted by PID ascending; `Programs` sorted by program number ascending; `ElementaryPIDs`
  ascending and deduplicated.
- Unknown time is `-1`; `Expected`/`Actual` are 0 for every kind except continuity.
- Empty stream: `Packets` 0, empty (non-nil is not asserted) slices.
- Clock arithmetic is modulo `1 << 33 * 300` ticks; elapsed is the signed representative in
  `[-half, half)`.
- Integer division everywhere (floor toward zero on non-negative operands only).

## 5. Blind-spot pre-empts

- dedup / first-occurrence: "only the first packet on such a PID is reported".
- result ordering: the fixed within-packet kind order plus packet order.
- iteration termination / deferred emission: "a packet is timed only once the next reference PCR closes
  its window".
- unstated inverse: duplicates are explicitly said not to count as a new table occurrence.
- falsy-on-invalid: unknown time is -1 and voids the measurement rather than counting as zero.

## 6. Description draft

See meta.md (dense, one paragraph per subsystem: entry points, clock, continuity, tables, per-PID stats).

## 7. File footprint

| Action | Path | Raw delta | Human-effective | Reason |
| --- | --- | --- | --- | --- |
| NEW | analyzer.go | +384 | 279 | packet ingestion, per-PID state machine, deferred window, checks, AnalyzeStream |
| NEW | analyzer_report.go | +178 | 128 | report types, per-PID state, program assembly, bitrate, ordering |
| NEW | analyzer_clock.go | +55 | 33 | modular 27MHz and 33-bit clocks, signed elapsed, interpolation |
| MODIFY | demuxer.go | +14 | 8 | option, feed hooks in NextPacket and updateData |
| MODIFY | muxer.go | +18 | 12 | option plus feed hooks on the WriteData and WritePacket paths |

MEASURED: **473 human-effective** across 4 files (hook run on the final solution.patch).
The clock and the deferred window were sized up in round 2 (AnalyzeStream, per-PID PCR interval
extremes, per-program missing PIDs) after the first cut measured 403.

## 8. Solution outline — helpers

- `clockTicks(cr *ClockReference) int64` — Base*300 + Extension.
- `clockElapsed(from, to int64) int64` — signed modular difference.
- `clockAdd(t, d int64) int64` — modular add.
- `durationToTicks(d time.Duration) int64` — nanoseconds * 27 / 1000.
- `interpolate(t0, delta int64, n, total int) int64` — floor interpolation inside a window.
- `(*analyzerPIDState).continuity(rec) (ok bool, expected uint8)` — the duplicate-aware CC machine.
- `(*Analyzer).flush(closing bool)` — the deferred window pass that stamps times and emits events.
- `(*Analyzer).referenced(pid uint16) bool` — reserved / null / PMT PID / declared PID.
- `(*AnalyzerReport).sortAll()` — canonical ordering.

## 9. Test file outline

Path: `analyzercheck/analyzer_<hash>_test.go`, `package analyzercheck` — a sibling package, not an
in-package test file. In Go an in-package test that references an unwritten API breaks the whole
package, which would take base mode down with it; a sibling package is excluded from base mode by
`go list ./... | grep -v /analyzercheck` and forces the tests onto the exported API only.

Block 1 imports; Block 2 builders (`anzPacket`, `anzStart`, `anzEmpty`, `anzPCR`, `anzBroken`,
`anzJumped`, `anzScrambled`, `anzPAT`, `anzPMT`, `anzPES`, `anzStream`); Block 3 assertion helpers
(`anzRun`, `anzKinds`, `anzTimes`, `anzTimesOf`, `anzStat`); Block 4 tests grouped by bucket:
continuity 15, clock/interpolation 10, PCR checks 8, table repetition 9, transport error 4,
scrambling 4, unreferenced PID 5, per-PID stats 12, programs 5, PES timestamps 5, ordering/report 5,
demuxer wiring and AnalyzeStream 5. **133 tests, all failing on base.**

5-axis coverage: every meta sentence, every exported name, every branch, edges
(empty stream / single packet / no PCR / wrap / duplicate at index 0 / unknown time), stated inverses.

## 10. Forced signatures

Go is statically typed, so every exported signature above is pinned verbatim in meta.md to avoid the
compile-wipe fake-difficulty anti-pattern (`Report() *AnalyzerReport`, `Time int64`, `Bitrate int64`).

**Batch 1 proved that pinning NAMES is not pinning SIGNATURES.** meta listed every field name and no
field type; 4 of 4 Nova runs chose maps, pointers or `time.Duration` and every run compile-wiped at
0/124 without reaching one behavioral assertion. meta now declares each field's type, states that
every collection is a slice of values rather than a map or pointers, and gives
`DemuxerOptAnalyzer(a *Analyzer) func(*Demuxer)` its return type. A script cross-checks every exported
field NAME and TYPE in the source against meta.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt in meta | Test |
| --- | --- | --- | --- | --- |
| 1 | Deferred interpolation (time known only when the next reference PCR closes the window) | Obvious code stamps the last PCR value | "interpolated by packet position between the two reference PCRs that surround it" | `time_is_interpolated_between_reference_pcrs` |
| 2 | 33-bit x 300 wrap, signed elapsed | Plain subtraction goes hugely negative | "the clock wraps ... elapsed is the signed difference" | `pcr_wrap_does_not_report_a_discontinuity` |
| 3 | CC does not advance without payload | Obvious code always expects +1 | "a packet with no payload repeats the previous counter" | `adaptation_only_packet_repeats_counter` |
| 4 | One legal duplicate, and a duplicate is not a new table occurrence | Obvious code errors on repeat, or counts it as a PAT | "duplicated once ... a duplicate is not a new occurrence" | `duplicate_pat_does_not_restart_interval` |
| 5 | TEI packets counted then ignored everywhere else | Obvious code runs CC on them | "counted, then ignored by every other check" | `errored_packet_does_not_break_continuity` |
| 6 | Irregular PCR interval voids the window's timestamps, which voids table intervals across it | Obvious code keeps interpolating | "packets in that window have unknown time" | `pat_interval_across_a_pcr_jump_is_not_reported` |
| 7 | Unreferenced PID reported once only, structure judged as known so far | Obvious code reports every packet | "only the first packet ... judged against the tables seen so far" | `unreferenced_pid_reported_once` |
| 8 | Bitrate uses intervals (count-1), not count | Fencepost | "the number of gaps between them" | `bitrate_uses_gaps_not_packets` |

Traps 1, 2 and 6 share the clock kernel; 3, 4 and 5 share the continuity kernel and feed 4/6 through the
table-occurrence path. Fixing one locally regresses another (interdependent), and the failing assertion
is usually a table-repetition or bitrate count rather than the clock itself (misdirecting).

## 12. Tier + category

- Tier: Olympus. Sub-rank: Good/Excellent. Category: **feature-request** (net-new public API).

## 13. Predicted pass rate

- Predicted 10-20%. Levers stacked: one interdependent kernel (clock) driving every interval surface;
  an independent Python oracle fuzzed to zero mismatches; 8 traps of which 3 are misdirecting; an
  obvious-code-is-wrong edge (wrap, fencepost); a de-trained bespoke domain (broadcast transport
  streams) with an invented report contract rather than a transcribable public spec; 5 files.

## 14. Quality gate

- [x] Repo understanding 5/5 (flat `astits` package: packet parse/write, packet buffer, packet pool,
      PSI/PES data parsers, demuxer, muxer, program map; entanglement zones are `NextPacket`,
      `parseData`, `programMap`; `testify` tests live beside sources; template `packet_test.go`).
- [x] Existing PR/issue check: `gh pr list -R asticode/go-astits --state all --search "<k>"` for
      analyz / conformance / continuity / statistics / metrics / monitor / PCR / report / quality — no hit.
      Single branch `master`. Canonical org confirmed `asticode/go-astits`.
- [x] Closest approved problems opened: `techan-costbasis` (accounting layer over an engine),
      `tantivy-pipeline-aggregations` (post-pass over an engine's output), `surrealkv-merge-operator`.
- [x] Corpus recipe: one kernel, oracle plan, >=3 interdependent+misdirecting traps, signatures pinned,
      not a famous portable spec (report contract is invented; thresholds are options).
- [x] Canonical output form spelled out (§4).
- [x] <=1 codebase-inferable requirement (the `DemuxerData`/`Packet` shapes are the repo's own types).
- [x] Not pattern-followable: no comparable subsystem exists in the repo.

## Why this is not a duplicate

Closest local work: `mp4ff-progressive-writer` (approved) is an ISOBMFF *writer* in a different repo and
container format; `turmoil-link-bandwidth` models a simulated network link rather than analyzing a real
byte stream; `tantivy-pipeline-aggregations` is a post-finalization pass over search aggregations. No
local problem touches MPEG-TS, and no problem in `problems/`, `rejected/` or `Instructions/Aprroved/`
targets asticode/go-astits or a stream-conformance report. The feature class (a deferred,
clock-interpolated conformance report over a demuxer) is invented here, not a published API.

Predicted iteration cycles: 2

## Verification performed before submit

- 4-cell validation matrix green in both apply orders; reverse-apply leaves a clean tree.
- 5x flakiness on base and new, identical results.
- 6400-case differential fuzz against a Python model written from meta.md alone: 0 mismatches.
- 13-mutant trap proof: every mutant killed, 3 of them across a different surface than the defect.
- human-effective LOC 485 (gate 430), 133 new tests, 170 existing testcases still green.
- Thirteen Test Fairness rounds: 16 flags resolved, 30 coverage suggestions added; one flag was a genuine reference bug at the antipodal DTS tie.
- Batch 1 (4x Nova) 0/4, all compile-wipes on unstated Go types; every type now declared in meta and the synth failure now carries the compiler output.
- 43-mutant trap proof after all rounds, every mutant killed.
- Suite is crash-resilient: no slice index can panic and abort the JUnit report.
