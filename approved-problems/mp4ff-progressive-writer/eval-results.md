# eval-results.md — mp4ff-progressive-writer

Batch 1 (2 runs) is recorded below. Headline: both runs failed on ONE assertion, which was mine and
unfair, so the corrected reading of this batch is 2 of 2 PASSING, not 0 of 2. That is a too-easy
signal, well above the 40% cap, and it is now the open problem.

## Local validation

| Run | Tree | Mode | Cases | Failures | Exit |
| --- | --- | --- | --- | --- | --- |
| L1 | vanilla base (no patches) | `go test ./...` | full suite | 0 | 0 |
| L2 | base + test.patch | base | 1201 | 0 | 0 |
| L3 | base + test.patch | new | 125 | 125 | 1 |
| L4 | base + test.patch + solution.patch | base | 1201 | 0 | 0 |
| L5 | base + test.patch + solution.patch | new | 125 | 0 | 0 |
| L6 | solution.patch applied first, then test.patch | base + new | 1201 / 125 | 0 / 0 | 0 |
| L7-L9 | full patched tree, repeated 3x | base + new | 1201 / 125 | 0 / 0 | 0 |

All runs offline (`--network none`) as uid 1000 in the submission image.

## Discriminator proof

Full sweep in `feedback.md` (33 mutations, 33 caught, 0 skipped, 0 false-positive holes). Highlights:

| Mutation | Tests that fail |
| --- | --- |
| `NewSdtpEntry` left with its upstream typo | `TestProgressiveSdtpEntriesPerSample`, `TestProgressiveSdtpKeepsEveryDependencyField` |
| moov shallow-copied instead of cloned | `TestProgressiveOutputDoesNotShareBoxesWithTheInput`, `TestProgressiveInputFileUnchanged` |
| moov reused outright (no copy) | whole suite dies at the first test (nil mvex panic) |
| nil-mvex guard removed | `TestProgressiveRejectsAnInitWithoutMvex` (panics rather than returning an error) |
| stsc run ignores the sample description | `TestProgressiveKeepsTheSampleDescriptionOfEachFragment` |
| fragment description index ignored | `TestProgressiveKeepsTheSampleDescriptionOfEachFragment` |
| trex default description ignored, plain 1 used | `TestProgressiveFallsBackToTheTrexSampleDescription` |
| missing init ftyp not rejected | `TestProgressiveRejectsAFileWithoutInitSegment` |
| chunk writes its first sample repeatedly | 16 tests, incl. `TestProgressiveEncryptedSampleDataRoundTrip` (the case the byte-for-byte comparison added) |
| mdat header stays 8 bytes with LargeOffsets | `TestProgressiveLargeOffsetsMdatHeader`, `TestProgressiveLargeOffsetsMdatIsSixteenByteHeader` |
| mdat box never uses the 64-bit size | `TestProgressiveLargeOffsetsMdatIsSixteenByteHeader` |
| missing senc not rejected for per-sample IV tracks | `TestProgressiveRejectsAProtectedFragmentWithoutSenc` |
| output movie timescale rewritten instead of kept | 6 tests, incl. `TestProgressiveRoundsConvertedDurationsDown`, `TestProgressiveOrdersLargeTimesAcrossTracks` |
| per-sample IV decided from stsd[0], not the selected description | `TestProgressiveSencIsRequiredByTheSelectedDescription`, `TestProgressiveSencNotRequiredByAClearSelectedDescription` (the FP an agent slipped through) |
| track duration sums the rounded parts | `TestProgressiveTrackDurationRoundsTheWholeSum` |
| senc demanded of every protected track, constant IV included | `TestProgressiveConstantIVEncryptionHasNoAuxInfo`, `TestProgressiveConstantIVFragmentNeedsNoSenc` (the opposing half of the trap pair) |
| aggregate size check without the per-trun window | `TestProgressiveRejectsATrunPointingPastTheMdat` |
| stale edit list kept on a zero-start track | `TestProgressiveDropsAnEditListOfATrackStartingAtZero` |
| multiply-before-divide in `rescaleTime` | `TestProgressiveConvertsLargeTimesWithoutOverflow` |
| version stays 0 for 64-bit durations | `TestProgressiveConvertsLargeTimesWithoutOverflow` (truncated on encode) |
| `Elst` field left unset on the built edts | `TestProgressiveReturnedEditListIsReadable` |
| snapshot/restore of trun samples removed | `TestProgressiveLeavesFragmentSamplesUntouched` (input trun samples gain the resolved defaults) |
| `checkFragmentData` removed | `TestProgressiveRejectsASampleBeyondTheMdat` (panics), `TestProgressiveRejectsAFragmentWithTooLittleData` (silently emits corrupt output) |

## Per-agent results

### Batch 1 (2026-08-02, 2 runs, both Orion solver / Nova evaluator)

| Agent | Evaluator | Verdict | Messages | Files | LOC | Failed tests | Failure reason | Approach note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Orion #1 | Nova | FAIL_MISSED_REQUIREMENT | 38 | 2 | 1356 | `TrackDurationRoundsTheWholeSum` | media edit 2041, want 2040 | whole-sum floor for tkhd, media edit as remainder (`setProgressiveEdit(..., trackDuration-leadingDuration)`) |
| Orion #2 | Nova | FAIL_TEST_MISMATCH (`agent_blame_unfair: true`, `blocker_type: verifier`, `description_clear: false`) | 54 | 3 | 1385 | `TrackDurationRoundsTheWholeSum` | media edit 2041, want 2040 | same architecture, same remainder choice (`updateProgressiveDurations`) |

Both passed 1195/1195 baseline and 124/125 new. Both chose the SAME edit-list architecture and differed
from the reference on the SAME single line. Evaluator #2 named it: the prompt fixes the whole-sum
rounding of the track duration but never says each elst SegmentDuration is independently converted and
floored, so the remainder is a fair reading.

Corrected pass rate after removing that assertion: **2/2 = 100%**, versus the 40% cap. Both agents
reached a complete, correct implementation in ~20 minutes and 38-54 messages.

Difficulty read from this batch:

- The whole feature is reachable. Neither run struggled with the chunking, ordering, table-building,
  offset, encryption or purity requirements, which is where the design assumed the difficulty lived.
- Message counts (38, 54) clear the >=40 long-horizon floor only marginally, and run #1 is under it.
- The problem currently has NO surviving trap. The single discriminator was a rounding convention, and
  it was unfair rather than hard.

## Capture protocol reminder

At every batch, save each passing agent's diff to `agent-runs/<batch>-<run>.patch` plus the one or two
most instructive failures, and record failed test NAMES and the architecture each agent chose.
