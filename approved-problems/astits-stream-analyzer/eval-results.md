# eval-results.md — astits-stream-analyzer

## Agent runs

### Batch 1 - 4x Nova (pre-fix): 0/4, all COMPILE-WIPE on the public API representation

| Run | Agent | Evaluator | Verdict | Messages | Files | LOC | Failed tests | Failure reason |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Nova | Nova | FAIL_AMBIGUOUS_TASK | 32 | 2 | 647 | 124/124 build | `PIDs`/`Programs` as maps, `Time` and stats as `time.Duration`, `Bitrate` float64 |
| 2 | Nova | Nova | FAIL_TEST_MISMATCH | 35 | 3 | 804 | 124/124 build | `Events []*AnalyzerEvent`, `PIDs`/`Programs` maps of pointers, `time.Duration` + `uint64` scalars |
| 3 | Nova | Nova | FAIL_TEST_MISMATCH | 51 | 3 | 770 | 124/124 build | `PIDs`/`Programs` as `map[uint16]...` |
| 4 | Nova | Nova | FAIL_TEST_MISMATCH | 34 | 3 | 852 | 124/124 build | maps of pointers, `Time time.Duration` |

Every run: baseline 170/170 green, new 0/124, all failures the synthetic build-failure node. Three of
four evaluators set `agent_blame_unfair: true` and `blocker_type: verifier`; all four set
`description_clear: false` and `difficulty: unfair`. Not one run reached a behavioral assertion.

**Diagnosis.** meta.md named every FIELD but no field's TYPE. "Holds `PIDs` by PID" reads equally well
as a map keyed by PID, and "time" reads equally well as `time.Duration`. Four independent agents each
picked a defensible representation, and the hidden package - which indexes `r.Programs[i]` and appends
`e.Time` to `[]int64` - could not compile against any of them. This is the corpus's
signature-coin-flip anti-pattern: the run measured whether the agent guessed my struct layout, not
whether it implemented the analyzer.

**Encouraging signal inside the failures.** Two evaluators statically reviewed the agent code and found
REAL behavioral defects that would have failed even after the API was fixed: no modular normalization
of interpolated time across the PCR wrap (runs 1, 2, 4) and bitrate computed over packet-index span
rather than gaps between timed packets (run 1). The intended traps bite; they were simply never
reached. Both evaluators called the task "challenging and solvable" on behavior.

**Fixes applied before batch 2** (see `feedback.md` round 14).

### Batch 2 - 4x Nova: compile wipe GONE, one deterministic universal miss, one harness defect

Artifacts in `agent-runs(1)/`. All four now COMPILE, run, and are judged `description_clear: true`,
`difficulty: challenging`. The platform reported 43-48 failures each, but that number was an artifact:
one of my tests PANICS on a nil report, killing the test binary, so 42 downstream tests never emitted a
node and the node-id wrapper scored them all failed.

Genuine failures per run, recovered by replaying each agent patch against the repaired suite:

| Run | Platform verdict | Genuine failures | Which |
| --- | --- | --- | --- |
| 1 | FAIL_MISSED_REQUIREMENT | 3 | TransportErrorIsNeverUnreferenced, ErroredPacketIsIgnoredByTheClockAndTheStats, AnalyzeStreamOnAnEmptyReader |
| 2 | FAIL_MISSED_REQUIREMENT | **1** | AnalyzeStreamOnAnEmptyReader |
| 3 | FAIL_MISSED_REQUIREMENT | 3 | TimeWrapsAroundTheClockLimit, BitrateIgnoresUntimedPackets, AnalyzeStreamOnAnEmptyReader |
| 4 | FAIL_MISSED_REQUIREMENT | 17 | five PAT/PMT occurrence tests plus twelve others |

**★ SOLVABILITY IS NOW PROVEN, not predicted.** Nova_2's own analyzer, with the single change the newly
stated empty-reader rule asks for, passes 129/129 new and 170/170 base. Measured, not estimated:

```
EXIT=0  nodes=129 failures=0
base EXIT=0 cases=170 failures=0
```

That puts the batch at an expected 1 of 4, which is the corpus mode and well inside the 40% cap. The
remaining failures are genuine trap kills: the PCR wrap (trap 2, run 3), the transport-error
short-circuit (trap 5, run 1), and table-occurrence deferral (trap 6, run 4).

### Batch 3 - 8x Nova + 9x Orion: SOLVED, 2 passes, only the long-horizon message median short

Artifacts in `agent-runs(4)/`.

| Metric | Result |
| --- | --- |
| Pass rate | **2 of 17 (12%)** - Orion #1 and Orion #2, both `PASS_LEGITIMATE` |
| Nova | 0 of 8, all FAIL_MISSED_REQUIREMENT |
| Orion | 2 of 9 |
| Long-horizon median (passing runs) | files 2.5 (need >= 2, OK), LOC 553.5 (need >= 200, OK), **messages 16.5 (need >= 20, SHORT by 3.5)** |

12% is the corpus mode and well inside the 40% cap, so difficulty and solvability are both settled.
The single remaining gate is the message median.

**Diagnosis.** Both passing runs put the whole analyzer in `analyzer.go` and touched only `demuxer.go`
besides. The feature was answerable in two files, so a decisive solver writes it in a handful of large
edits: 553 LOC in 16 messages. Nothing forced them to read unfamiliar existing code.

**Fix: a second integration surface in existing code.** `MuxerOptAnalyzer(a *Analyzer) func(*Muxer)`
feeds the analyzer every packet the muxer writes through `WriteData` and `WritePacket`. That is a
natural counterpart to the demuxer option (validate the stream you produce, not only the one you read)
and it forces work the previous shape did not:

- `muxer.go` is 450 lines of unread code, so the solver must explore it rather than write fresh.
- The packet writes leave through TWO paths, and `WriteTables` deliberately is not one of them because
  it emits pre-serialized table bytes rather than packets. Missing the second path costs an
  edit-test-fix cycle.
- Footprint goes from 4 files to 5, and the passing shape from 2-3 touched files to 3-4.

Expected effect on the median: +3 to +6 messages. This needs a rerun to confirm; it is a reasoned
estimate, not a measurement.

### Batch 4 - 10x Nova: 0/10, two shared misses, both traced to the description

Artifacts in `agent-runs(7)/`. Every run compiled and produced all 139 nodes; baseline 170/170 green
everywhere. Failure counts were 2, 2, 2, 3, 3, 4, 4, 6, 17, 17 - three runs sat two tests from passing.

| Failing test | Runs | Verdict |
| --- | --- | --- |
| `BitrateIgnoresUntimedPackets` | 8/10 | description under-specified the COUNT |
| `ErroredPacketIsIgnoredByTheClockAndTheStats` | 8/10 | description contradicted itself |
| `TimeWrapsAroundTheClockLimit` | 6/10 | genuine trap, kept |
| everything else | <= 3/10 | genuine traps, kept |

**A parsing artifact nearly sent me the wrong way.** My first extraction reported
`ContinuityFirstPacketIsNotReported` failing 10/10, which reads exactly like a universal-miss prompt
bug. It was a regex defect: passing tests are self-closing `<testcase ... />` nodes and my pattern ran
past them into the next failing node, so every run's first failure was mis-attributed to the first test
in the file. Confirmed against the raw `--- FAIL` lines before acting. A "universal miss" that appears
on the FIRST test of a file should always be checked against the raw runner output first.

**Fix 1, the contradiction.** The errored-packet rule said the packet "is ignored by everything else",
while five paragraphs later the `AnalyzerEvent` rule said `Time` is the packet's time, "an errored one
included". All 8 failing runs applied the nearer, stronger rule and emitted `Time: -1`. The clause now
lives where the tension is: the event is raised "carrying its packet's time", and the far-away
qualifier is gone.

**Fix 2, the count.** Bitrate said "the gaps between its timed packets", which names the right
population but not the arithmetic; Nova_2 summed index distances between timed packets instead of
counting them, giving exactly double. Now stated as "one less than its number of timed packets", and
`FirstTime`/`LastTime` are defined positively rather than only by their -1 case.

**Solvability is MEASURED, not projected.** Nova_2's own analyzer, with only the changes the clarified
text asks for (count gaps rather than index distance; stop sealing the errored record and exclude it
from the timed-packet list instead), passes 139/139 new and 170/170 base. Replaying the batch with the
two clarified tests treated as passing puts the batch at **2 of 10, 20%**, inside the 40% cap and at the
hard edge. `TimeWrapsAroundTheClockLimit` survives as the dominant discriminator in 6 of 10 runs.

**FP hole found and closed while fixing this.** Once "ignored by everything else" clearly excluded
errored packets from timed-packet statistics, nothing tested it: the errored-packet test asserted
counters but never `FirstTime`, `LastTime` or `Bitrate`, so an agent that counted the errored packet as
timed would have passed. Added those three assertions (`Bitrate` discriminates: 50133 versus 100266)
and mutant M55, which dies to that test alone.

### Batch 5 - 10x Nova: 0/10, and one blocker was an assertion I added in the prior round

Artifacts in `agent-runs(8)/`. All 139 nodes everywhere, baseline green. Failures 1, 1, 1, 2, 2, 2, 3, 5,
17, 20 - three runs at a SINGLE failure.

| Failing test | Batch 4 | Batch 5 |
| --- | --- | --- |
| `TimeWrapsAroundTheClockLimit` | 6/10 | **9/10** |
| `ErroredPacketIsIgnoredByTheClockAndTheStats` | 8/10 | 6/10 |

**Two authoring errors, both mine.**

1. *The batch-4 projection was computed on the sample it was fitted to.* Fixing two of three shared
   misses left the third to dominate: the wrap trap rose from 6/10 to 9/10 and the projected 2/10 came
   out 0/10. An on-sample projection after a targeted fix is worth far less than a fresh batch, and it
   should never be reported as though it were a measurement.
2. *The FP assertions I added last round created the second blocker.* Batch 5's errored-packet failures
   are all `expected 50133, actual 100266` - the `Bitrate` assertion I added. It pins a distinction the
   description never draws: a packet that HAS a time versus a packet that COUNTS as a timed packet. My
   own transport sentence says the event carries "its packet's time", so reading the packet as timed is
   the natural one. Unfair by the standard applied everywhere else in this problem, and it was not
   covered by the Test Fairness pass, which reviewed that test before the assertions existed.

**Fix: reverted those three assertions and dropped M55.** The unspecified property returns to
unspecified, so both readings pass - the same treatment already applied to value-slice aliasing.

**Solvability MEASURED on an unmodified submission.** Nova_4's patch, with no edits at all, passes
139/139 new and 170/170 base against the reverted suite. Its only failure had been my assertion.
**Then MEASURED the whole batch instead of projecting it.** Every one of the ten batch-5 agent patches
was replayed against the final suite:

| Failures after the fix | Runs |
| --- | --- |
| 0 (PASS) | run 4 |
| 1, all `TimeWrapsAroundTheClockLimit` | runs 1, 6, 8, 10 |
| 2 or more | runs 2, 3, 5, 7, 9 |

**1 of 10 = 10 percent, measured on real submissions.** That is the corpus mode and satisfies the
solvability gate. Four more runs sit one test away, all on the same trap, so the calibration is thin by
design rather than by accident: stating the wrap rule would convert those four into passes and put the
batch at 50 percent, over the 40 percent cap. The trap stays.

`TimeWrapsAroundTheClockLimit` is KEPT as the hard trap. The Test Fairness check reviewed it
independently and rated it "Prompt-stated: good wrap interpolation", so it stands as the one
inference-heavy requirement rather than a spec gap.

### Batch 6 - 11x Nova: 1/11 pass, solvability confirmed a third time

Nova_8 passed with zero failures. Failure counts 0, 1, 2, 2, 2, 15, 16, 17, 20, 139 and one run that
never compiled. Dominant misses: `TimeWrapsAroundTheClockLimit` 7/11 and
`StatsCountDiscontinuitiesOnTheNullPID` 6/11. Auto Review independently reported "1 of 10 runs passed
all 139 new tests" and classed the null-PID convergence as benign, since the description defines
per-PID discontinuity statistics separately and limits the skip to continuity checking.

### Auto Review round (3 runs): tests 1/3, description 2/3, solution 3/3

Solution scored clean in all three runs with no defect found. Two findings, both fixed.

**High, tests: event PID attribution was never asserted for whole event families.** PCR
discontinuity, PCR repetition, PAT repetition, PTS order and DTS order tests checked kind, index and
time but never `AnalyzerEvent.PID`, so an implementation could hardcode zero for those kinds and pass.
A real FP hole. Added PID assertions to one representative test per family, following the existing PMT
repetition pattern. Mutant M55 zeroes the PID on every emitted event and is now killed by 10 tests.

**High, tests: no end-to-end proof that parsed PES reaches the analyzer.**
`DemuxerOptionFeedsParsedData` only covered PAT/PMT, and every PTS/DTS test injected `DemuxerData`
directly, so a demuxer hook that silently dropped PES units would pass. Added
`AnalyzeStreamSeesParsedTimestamps` and `DemuxerOptionFeedsParsedTimestamps`, both muxing real PES
packets with descending PTS and requiring a `PTSOrderError` with the right PID. Mutant M56 drops the
PES branch and dies to 9 tests.

**Medium, description: generated-spec tone.** The cited line was "Every collection is a plain slice of
values, never a map or pointers". The load-bearing part is the concrete types, which are already
written inline on every field; the negative contrast was the redundancy. Folded into the sentence as
"each of those three a slice holding its elements by value", which keeps the value-slice contract that
fixed the batch-1 compile wipe while dropping the standalone spec-sheet sentence.

**Solvability re-verified AFTER strengthening.** Both known passers, Nova_8 from batch 6 and Nova_4
from batch 5, still pass 141/141. The new assertions close the FP hole without over-constraining.

Next: rerun 10x Nova + 2x Orion and re-read the long-horizon medians. Save every passing diff to
`agent-runs/<batch>-<run>.patch` while the run view is open, plus the two most instructive failures.

## Local validation matrix (regenerated patches, `olympus-base-go`, `--network none`, uid 1000:1000)

| Cell | Command | Result |
| --- | --- | --- |
| base, test.patch only | `./test.sh --output_path /out/b1.xml base` | PASS, 170 testcases, 0 failures |
| new, test.patch only | `./test.sh --output_path /out/n1.xml new` | FAIL, 141 testcases, 141 failures |
| base, both patches | `./test.sh --output_path /out/b2.xml base` | PASS, 170 testcases, 0 failures |
| new, both patches | `./test.sh --output_path /out/n2.xml new` | PASS, 141 testcases, 0 failures |

Apply orders: test then solution, and solution then test, both clean. `git apply -R` of both leaves
`git status --porcelain` empty.

## Flakiness (mandatory gate)

Five consecutive runs of each mode with the solution applied, offline, non-root:

| Run | base exit | new exit |
| --- | --- | --- |
| 1 | 0 | 0 |
| 2 | 0 | 0 |
| 3 | 0 | 0 |
| 4 | 0 | 0 |
| 5 | 0 | 0 |

Test-name sets identical across all five runs in both modes; zero failures in every run. Nothing in the
suite reads the clock, the network, the filesystem, a random source, or map iteration order (every
report field is sorted before it is asserted).

## Differential oracle (independent Python model built from meta.md only)

| Seed | Cases | Mismatches |
| --- | --- | --- |
| 1 | 800 | 0 |
| 2 | 800 | 0 |
| 3 | 800 | 0 |
| 4 | 800 | 0 |
| 5 | 800 | 0 |
| 6 | 800 | 0 |
| 7 | 800 | 0 |
| 8 | 800 | 0 |
| 11 | 800 | 0 |
| 12 | 800 | 0 |
| 13 | 800 | 0 |
| 14 | 800 | 0 |
| 21 | 800 | 0 |
| 22 | 800 | 0 |
| 23 | 800 | 0 |
| 31 | 800 | 0 |
| 32 | 800 | 0 |
| 41 | 800 | 0 |
| 42 | 800 | 0 |
| 51 | 800 | 0 |
| 52 | 800 | 0 |
| 61 | 800 | 0 |
| 62 | 800 | 0 |
| 71 | 800 | 0 |
| 72 | 800 | 0 |
| 81 | 800 | 0 |
| 82 | 800 | 0 |
| 91 | 800 | 0 |
| 92 | 800 | 0 |
| 101 | 800 | 0 |
| 102 | 800 | 0 |
| 111 | 800 | 0 |
| 112 | 800 | 0 |
| 113 | 800 | 0 |
| 114 | 800 | 0 |
| 115 | 800 | 0 |
| 116 | 800 | 0 |

Seeds 111 and up run the generator extended to emit timestamps a half wrap apart, which is where the
round-12 reference bug lived. Generator biases toward the interesting states: PCR jumps forwards and backwards, PCR values near the
`1<<33 * 300` wrap, duplicate and payload-less packets, discontinuity indicators, errored packets,
scrambled table packets, unit starts on PID 0 and on program map PIDs, PMTs arriving before and after
the packets they describe, and PTS values near and exactly a half wrap from the `1<<33` wrap.

## Mutation battery (trap proof)

56 mutants, each the obvious implementation of one rule, applied to a copy of the reference. Every
mutant is killed by at least one test; totals and cross-surface kills are in `feedback.md`. M14-M56
were added to prove the four coverage-suggestion tests, and M17 initially killed nothing because every
non-continuity event in that test sat on a packet whose counter was already zero. The fixture now uses
non-zero counters, which is the fixed-point FP trap caught in its own suite.

## FP check (mandatory final gate)

| Pass reviewed | Panel | Adjudication | Action |
| --- | --- | --- | --- |
| Nova, run A | 1 genuine, 1 FP (`HasPCR`) | Genuine pass, high confidence | None; dissent recorded and declined |
| Nova, run B | 2 FP, independent probes | **False positive**, high confidence | Two tests added, one description sentence corrected |

Run B's two probes were both genuine holes in the suite, not agent faults:

| Probe | Reference | Flagged agent | Closed by |
| --- | --- | --- | --- |
| Four identical continuity counters | 1 error | 2 errors | `ContinuityDuplicateIsLegalAgainAfterAReportedRepeat`, mutant M51 |
| Reader returning its last bytes with `io.EOF` | reports empty | wrapped error | `AnalyzeStreamOnAReaderEndingWithItsLastBytes`, mutant M52 |

The continuity probe's test was then flagged unfair in round 20 because the sentence it rested on was
ambiguous; the test was kept and the description reworded. Detail in `feedback.md`.

The second probe also exposed a prose/reference contradiction: the old sentence claimed any reader
holding no packet reports, but a plain short reader errors because astits converts it to a sync-byte
failure. The description now states the `ErrNoMorePackets`-or-`io.EOF` contract, which is true of every
reader shape. Detail in `feedback.md`.

## test.sh base-mode guard (sanity-check warning, fixed)

Base mode keyed its synthesis on the absence of `<testcase>`, which forces a failure on any repo with
zero baseline tests. Now keyed on exit code instead: synthesize only when the runner exits non-zero and
the report carries no `<failure>`. Behaviour table verified in `feedback.md`; the build-failure path
still synthesizes, and a test-free repo now exits 0.

## Crash resilience

Every slice index in the suite goes through a helper that calls `t.Fatalf` rather than panicking. On a
build whose `Report` returns no programs, the JUnit XML still carries all 129 testcases and exactly 8
failures (the program tests). A panicking suite would instead abort the binary and lose every result
after the first crash.

## Size

| Metric | Value |
| --- | --- |
| human-effective LOC (Counter 2, the binding gate) | 485 |
| raw added LOC (Counter 1) | 631 |
| source files touched | 5 (3 new, 2 modified) |
| new tests | 141 |
| existing tests still green | 170 testcases |
| meta.md words | 845 (12 paragraphs, longest 120) |
