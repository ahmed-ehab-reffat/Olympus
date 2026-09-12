# feedback.md — mp4ff-progressive-writer

## Summary

- Repo: [Eyevinn/mp4ff](https://github.com/Eyevinn/mp4ff), Go, MIT, 648 stars, 45k source LOC, one dependency (`go-test/deep`).
- BASE_COMMIT: `b7b7b79f6f8378dc48eb3769396335f39811906e`
- Tier: Olympus. Category: feature-request. Shape: O-Composite-add.
- Feature: `File.ToProgressive` builds a progressive (non-fragmented) file from a fragmented one.
- Status: built and locally validated. No agent batch run yet.

## Why this repo (host selection log)

Repos rejected on hard gates before landing here:

| Candidate | Killed by |
| --- | --- |
| bebop/poly | recency: 0 source commits in the trailing 12 months |
| mochi-mqtt/server | recency: last real commit 2025-03; also no capability gap (MQTT5 complete) |
| oxigraph/oxigraph | environment: `oxrocksdb-sys` needs a RocksDB git submodule, a submodule-less clone fails `cargo test --workspace` |
| RDFLib/rdflib | environment: repo `.dockerignore` excludes `test/`, so base-mode tests cannot exist in the image |
| apache/yunikorn-core | environment green, but every candidate feature reuses existing scaffolding and compresses under the LOC floor (REUSE-VS-NEW law); preemption/quota area is also a live workstream with a known flaky test (YUNIKORN-3333) |
| lf-edge/ekuiper | firehose (daily commits) + 126MB repo with heavy deps |
| brimstone, gosub-engine | firehose, young, spec-driven |

mp4ff was the only candidate clearing every fatal gate: license, stars, real source activity (72 source commits in 12 months), zero-dep offline build, and a vanilla suite that is green offline and deterministic across 3 runs.

## Why this feature

- Capability gap confirmed by the maintainer in [issue #427](https://github.com/Eyevinn/mp4ff/issues/427): "it has little support for writing progressive files". The library has `examples/segmenter` for the progressive to fragmented direction and nothing for the reverse.
- Exclusivity: `gh pr list -R Eyevinn/mp4ff --state all --search` for progressive / defragment / flatten / mux / remux / "sample table" returns no PR touching this capability. Sample-table boxes are cold (last real change 2025-01).
- Not shadowed by `cmd/mp4ff-crop`: crop truncates existing tables, it never constructs them, and it has no chunk layout, interleaving, edit list or auxiliary-information handling.

## Design decisions logged

- Scope was extended from plain table construction to include the encrypted-content surface (senc to track level saiz/saio, auxiliary data laid out in mdat) after the first LOC measurement came in at 352 human-effective. That surface is orthogonal depth, not breadth: it adds a second data kind to the mdat layout, so the chunk offsets now depend on the auxiliary blocks as well.
- The reference fixes a real upstream bug in `NewSdtpEntry` (it used `sampleDependedOn` twice and dropped `sampleDependsOn`). The feature is that helper's only real consumer. This doubles as a trap of the "the repo's own tempting helper implements the wrong policy" class: an agent that calls the helper unchanged fails `TestProgressiveSdtpEntriesPerSample`, and the failing assertion names an sdtp value, not the helper.
- New tests carry a `//go:build progressive` tag so base mode runs the repository's own suite untouched and new mode runs only the new tests. No test.sh trickery, no file moving.
- Test fixtures are built in memory with the library's own API (`CreateEmptyInit`, `CreateMultiTrackFragment`, `InitProtect`, `EncryptFragment`) and round-tripped through encode and decode. No binary fixtures.

## Traps

1. Chunk offsets are absolute file offsets, so they depend on the ftyp plus moov size and on the mdat header size (8 or 16 bytes). The natural implementation accumulates inside mdat and lands 8 bytes early.
2. Chunk ordering is compared in movie timescale. Two tracks with different media timescales interleave wrongly if raw decode times are compared.
3. Encrypted tracks put an auxiliary block in front of every chunk, so sample offsets shift by the auxiliary size. Getting the layout right but the offset base wrong yields a file that parses and decodes to garbage.
4. `NewSdtpEntry` is broken upstream (see above).
5. `File.AddChild` flips a file to fragmented when the first track has an empty stts, so building the output through `AddChild` misdetects a file whose first track has no samples.

Traps 1, 2 and 3 are interdependent: the header size shifts every offset, the ordering decides which sample each offset must point at, and the auxiliary blocks change both.

## Validation

| Check | Result |
| --- | --- |
| `human-effective` LOC (Counter 2) | 556 across 3 files (raw 834) |
| tests | 115 |
| base tree + test.patch, base mode | PASS, 1201 test cases, 0 failures |
| base tree + test.patch, new mode | FAIL, 115 cases, 115 failures (build-failure synthesis) |
| + solution.patch, base mode | PASS, 1201 cases, 0 failures (no regressions) |
| + solution.patch, new mode | PASS, 115 cases, 0 failures |
| apply order solution then test | identical results |
| flakiness, 3x base and 3x new | identical every run |
| offline, non-root (`--network none`, uid 1000) | green |
| vanilla suite before any patch | green offline, deterministic 3x |

## Attempt history

- R1: engine plus tables implemented, 44 tests, all green, existing suite unaffected. LOC measured 352 human-effective, under the floor.
- R2: added the encrypted-content surface and 7 tests. LOC 439 human-effective. Full validation matrix green.
- R3: acted on the first five coverage suggestions, 51 tests to 59. Solution unchanged; one fairness clarification
  in meta.md (sdtp entries keep the four dependency fields of the sample's flags) so the widened sdtp
  assertion traces to a stated sentence. Full matrix re-run green.
- R22: added sample description switching to raise difficulty. 111 tests to 115, LOC 536 to 556, sweep
  23 of 23 with zero holes after removing one piece of dead code the sweep exposed.
- R21: Description Quality FAIL, all four comments applied (prompt 482 to 450 words). The HIGH comment
  reverses R17's disclosure, so the conflict is documented above. 112 tests to 111.
- R20: two coverage suggestions added, 110 tests to 112; the nil-on-error contract is now stated rather
  than assumed.
- R19: three coverage suggestions added, 107 tests to 110; two overflow mutations added to the sweep,
  now 20 of 20 caught.
- R18: Solution Quality 2/3 + 2/3 with two named gaps, both fixed (per-trun offset window, stale edit
  list). 104 tests to 107, LOC 507 to 536, mutation sweep 18/18.
- R17: Task Quality FAIL on fairness. The sdtp helper defect is now stated in the prompt instead of being
  a hidden requirement; one coverage test added, 103 to 104. Mutation sweep re-run clean.
- R16: no fairness failures. Both coverage suggestions added, 101 tests to 103; mutation sweep re-run clean.
- R15: Test Fairness FAIL on one subcase (missing init ftyp), removed rather than stated; no coverage
  suggestions raised. 103 assertions to 101 tests, solution unchanged.
- R14: Test Fairness FAIL on one test (relaxed to what the contract determines), both coverage suggestions
  added, 98 tests to 101, plus a sixteen-mutation false-positive sweep with zero holes.
- R13: acted on all three coverage suggestions, 94 tests to 98. Found and fixed a uint64 overflow in time
  conversion, 32-bit truncation of large durations, and an edit list missing from the returned object.
- R12: acted on all three coverage suggestions, 90 tests to 94. Found and fixed a real no-mutation
  violation (trun defaults written back into the input) and finally implemented the unknown-traf error.
- R11: acted on two of three coverage suggestions, 87 tests to 90; the duration rule was reworded to remove
  a composition-offset ambiguity. Third suggestion declined again on fairness plus word budget.
- R10: Test Fairness FAIL on one test, fixed by widening the error clause by two words. Two coverage
  suggestions: one added (nested unknown boxes), one deliberately declined as undetermined. 85 tests to 87.
- R9: acted on the three follow-up coverage suggestions, 81 tests to 85. Two of them were unstated-implication
  gaps of the kind the fairness check flags, so both were stated; the description was tightened to stay
  inside the 500 word cap.
- R8: acted on the three follow-up coverage suggestions, 77 tests to 81. Found and fixed a panic and a
  silent-corruption path on malformed fragments; one meta clause added for the new error.
- R7: Test Fairness FAIL on two tests. One wording gap (ctts version 0) and one real description defect
  (track duration excluded the leading empty edit while the reference included it). Description corrected
  both times; 72 tests to 77 from the three new coverage suggestions.
- R6: Test Fairness FAIL on one test. Kept the behaviour and stated the rule instead of deleting;
  acted on the three new coverage suggestions, 69 tests to 72, and stated the rounding policy.
- R5: Test Fairness FAIL on one test. Removed `SecondFlattenIsStable`, acted on the four new coverage
  suggestions, 65 tests to 69, and fixed a nil-mvex panic found by the error-path suggestion.
- R4: acted on the four follow-up coverage suggestions, 59 tests to 65. Solution unchanged; two fairness
  clarifications in meta.md (the result shares nothing with the input; auxiliary information keeps the
  fragment layout of initialization vector followed by subsample ranges).

## Coverage round (R3)

| Suggestion | Tests added | Outcome |
| --- | --- | --- |
| Source-order breadth | `KeepsOrderAcrossSegmentsAndTruns`, `OneChunkPerFragmentAcrossSegments` | new builder emits real media segments (styp per fragment) and interleaves per-sample so each traf carries several truns; reference passed unchanged |
| Chunk timescale and boundary rounding | `ChunkDurationUsesTheTrackTimescale`, `ChunkClosesBeforeCrossingTheLimit` | 90000 timescale, 100 ms limit. Exactly-on-threshold sample stays in the chunk, crossing sample starts a new one. Timescales chosen so the ms conversion is exact, so no undetermined rounding rule is pinned |
| Encrypted split chunks | `EncryptedFragmentSplitIntoChunks` | one encrypted fragment split into two chunks; one saio offset per chunk and the auxiliary block verified in front of each chunk against the input IVs |
| Dependency preservation | `SdtpKeepsEveryDependencyField` | all four fields across three samples with distinct flag combinations |
| Mixed protection tracks | `MixedProtectionOnlyMarksTheEncryptedTrack`, `MixedProtectionInterleavesByTime` | `InitProtect` and `EncryptFragment` both refuse multi-traf input, so the fixture builds per-track fragments and protects only track 1; saiz and saio land on the encrypted track only and interleaving still holds |

Trap-proof for the sdtp discriminator: reverting the `NewSdtpEntry` fix makes
`TestProgressiveSdtpEntriesPerSample` and `TestProgressiveSdtpKeepsEveryDependencyField` fail, so the
broken in-repo helper is genuinely caught rather than being a dead test.

## Coverage round (R4)

| Suggestion | Tests added | Outcome |
| --- | --- | --- |
| Deep-copy independence | `OutputDoesNotShareBoxesWithTheInput`, `OutputSampleBytesAreCopied` | pointer identity plus post-hoc mutation of moov, tkhd, mdhd, stts and mdat bytes; the input is re-read afterwards |
| Non-IV-only encryption metadata | `EncryptedSubSampleAuxInfoBytes`, `EncryptedVaryingAuxInfoSizes` | AVC content from the repo's own `testdata/init.mp4` and `testdata/1.m4s` gives senc records with subsample ranges (16 byte entries, uniform, `DefaultSampleInfoSize`); a second fixture varies one sample's subsample count so `saiz.SampleInfo` carries per sample sizes 16, 22, ... Both assert the exact auxiliary bytes against the input senc |
| Init metadata preservation | `KeepsTheMetadataOfTheInitSegment` | mvhd NextTrackID and Rate, tkhd Width, Height, Layer, AlternateGroup, mdhd language and a udta box all survive; mvex is gone |
| All-empty fragmented input | `WithoutAnySamples` | init-only fragmented file: empty tables, zero durations, empty mdat, no optional tables, no edit lists, output not fragmented |

Mutation proof for the new deep-copy pair: shallow-copying the moov instead of cloning it (sub-boxes
shared) is caught by `OutputDoesNotShareBoxesWithTheInput` and `InputFileUnchanged` and by nothing else,
so the added test buys real coverage rather than duplicating an existing one.

Two findings from this round:

- The varying-auxiliary-size branch of `saiz` (per sample `SampleInfo` instead of
  `DefaultSampleInfoSize`) had no test before R4. It behaves correctly, but it was untested code.
- Library limitation, recorded rather than worked around: when NO track has any sample, the output is a
  legal ftyp + moov + mdat file, but mp4ff's own `DecodeFile` rejects it, because its
  fragmented-or-progressive heuristic keys on the first track having an empty stts and then finds an
  mdat with no moof. Any implementation of this feature produces the same file, so `WithoutAnySamples`
  asserts on the returned file rather than on a re-decode, and the description says nothing about
  re-reading that degenerate case.

## Fairness round (R5) and coverage round

Test Fairness reported FAIL, 1 of 65 unfair: `TestProgressiveSecondFlattenIsStable` compared whole
encoded byte streams across two conversions, which is broader than anything the description promises.
An implementation that stamps creation times into mvhd, tkhd or mdhd would have failed a rule that was
never stated. The test is REMOVED rather than rescued: every table, offset and byte range it touched is
already pinned exactly by other tests, so narrowing it would only have duplicated them.

The four accompanying coverage suggestions:

| Suggestion | Action | Outcome |
| --- | --- | --- |
| Malformed fragmented inputs | `RejectsAnInitWithoutMvex`, `RejectsATrackWithoutTrex` | found a real defect: an init segment with no mvex made the reference dereference a nil `MvexBox` and panic. Now an error. Both tests assert only that an error comes back, never a message. One meta sentence added so the contract determines them |
| True multi-trun ordering | `KeepsOrderAcrossSeveralTrunsOfOneTrack` | asserts the fixture really produces at least two truns for one track in one traf before checking order and chunk count, so the earlier segments-and-truns test is no longer the only evidence |
| Offset overflow policy | solution change, deliberately untested and undocumented | `stco` offsets beyond 32 bits now return an error instead of silently truncating. Reproducing it needs a 4 GB fixture, so it is neither tested nor stated in the description; an agent that omits it still passes |
| Additional encryption modes | `EncryptedWithSixteenByteIV`, `ConstantIVEncryptionHasNoAuxInfo` | 16 byte per-sample IVs give 16 byte auxiliary records. cbcs with a constant IV emits no senc at all, so no saiz or saio is written while the `enca` sample entry and all sample data survive |

Dropped on fairness grounds rather than added: a test for a fragment whose traf names a track that is not
in the moov. Tolerating it and rejecting it are both defensible, the description determines neither, so
pinning either one would have been the next unfair test.

## Fairness round (R6) and coverage round

Test Fairness reported FAIL, 1 of 69 unfair: `TestProgressiveKeepsTheMetadataOfTheInitSegment` pinned
specific inner moov values (NextTrackID, Rate, width, height, layer, alternate group, language) and a
udta child that the container-level sentence about the moov did not single out.

Fixed by STATING the general rule rather than deleting the test: a converter that silently drops the
transformation matrix, the language or a udta box is broken, so the behaviour is worth keeping under
test. The description now carries one Rule-7 style sentence, "Everything else it holds, its own boxes
and the fields of its tracks, is kept unchanged", which determines every one of those assertions
without enumerating them.

The three accompanying coverage suggestions:

| Suggestion | Action | Outcome |
| --- | --- | --- |
| Bidirectional independence | `InputChangesDoNotReachTheOutput` | the reverse direction of the no-sharing rule: after conversion, mutating input mdhd, tkhd, mvhd and the source fragment's mdat bytes leaves the already-built output untouched |
| Trex and tfhd default sample fields | `ReadsSamplesThatUseFragmentDefaults` | fixture encodes with `OptimizeTrun`, so durations, sizes and flags move out of the trun into the fragment defaults. The test asserts the trun really lost them before checking the rebuilt tables and payloads |
| Duration rescaling rounding | `RoundsConvertedDurationsDown` plus one meta clause | media timescale 44100 against movie timescale 90000 gives non-dividing values: track and movie durations 16326, empty edit 10204, media edit 6122. The rounding policy was previously unstated, so it is now stated ("rounded down") and pinned |

## Fairness round (R7) and coverage round

Test Fairness reported FAIL, 2 of 72 unfair. One was a wording gap, the other was a genuine defect in
the DESCRIPTION rather than in a test:

- `CttsVersionZeroForPositiveOffsets` pinned version 0 while the description only said version 1 is used
  for negative offsets. ISO BMFF permits version 1 for positive offsets too, so the exact zero was an
  unstated author choice. Now stated: "version 1 when some offset is negative and version 0 otherwise".
- `RoundsConvertedDurationsDown` expected a track duration of 16326, which is
  floor((5000+3000)*90000/44100) and therefore INCLUDES the leading empty edit. The description said the
  track and movie durations are the media-duration sum converted, which gives 6122. The checker is
  right that the two disagreed. The reference is the correct side: a track that starts late really does
  occupy the empty edit in the presentation timeline, and a movie duration that excluded it would end
  before the track's content does. Earlier duration tests hid this because their tracks start at zero,
  where both readings coincide. Fixed by correcting the description, not the code: "A track duration
  covers the whole presentation of that track in movie timescale, rounded down, the leading empty edit
  included, and the movie duration is the longest of them."

The three accompanying coverage suggestions:

| Suggestion | Tests added | Outcome |
| --- | --- | --- |
| Fragment default flags | `ReadsSyncFlagsFromFragmentDefaults`, `ReadsFirstSampleFlagsFromTheFragment` | two distinct paths: uniform flags land in `tfhd` defaults, mixed flags land in `first_sample_flags` with the rest defaulted. An implementation that reads only per-sample trun flags gets zeros and writes the wrong stss and sdtp. Writing these caught a fixture mistake of mine first: `runOfSamples` marks only the first sample sync, so it exercises the first-sample-flags path, not the defaults path |
| Deep-copy breadth | `NestedBoxesAreNotShared` | mutates nested ftyp compatible brands and the stsd child list after conversion, in the encrypted case where stsd carries protection boxes |
| Fractional chunk thresholds | `ChunkLimitAtAnAudioTimescale`, `ChunkLimitExactlyReached` | 44100 Hz with a 7 ms limit, where the conversion is not exact. Below, exactly at, and above the threshold. No integer sample sum can fall between floor(limit) and the exact limit, so the two possible readings of the rule agree and nothing ambiguous is pinned |

## Coverage round (R8)

| Suggestion | Tests added | Outcome |
| --- | --- | --- |
| Variable-duration chunk boundaries | `ChunkBoundaryFollowsAccumulatedDuration` | durations 1000,1000,1000,1000,4000,1000 with a 5 s limit split into chunks of 4 and 2, so neither sample count nor the first sample's duration can produce the right answer |
| Subsample encryption with duration splitting | `EncryptedSubSamplesSplitIntoChunks` | the varying-subsample AVC fixture split by duration; every chunk's saio offset is checked against the exact concatenation of that chunk's variable-size records, walked through stsc, and the chunk data is verified to start right after its auxiliary block |
| Malformed fragment error propagation | `RejectsAFragmentWithTooLittleData`, `RejectsASampleBeyondTheMdat` | **found two real defects** (below) |

Two defects this round, both in the reference:

- A sample size reaching past the fragment's mdat made the conversion PANIC with a slice-bounds error,
  because `Fragment.GetFullSamples` slices the mdat payload without a bounds check.
- A truncated mdat produced NO error and NO panic, but silently emitted a corrupt progressive file: Go
  re-slicing within capacity succeeds, so the garbage past the length was copied out as sample data.
  This is the worse of the two, since the output looks valid.

Both are fixed by `checkFragmentData`, which resolves the trun defaults and compares the total sample
bytes of the track against the fragment's mdat payload before any sample is read. One meta clause was
added so the new error is part of the contract: an error is also returned for "a fragment whose sample
data does not fit its mdat box".

## Coverage round (R9)

| Suggestion | Tests added | Outcome |
| --- | --- | --- |
| Default saio mode | `SaioVersionZeroWithoutLargeOffsets` | version 0 was only implied by the LargeOffsets sentence, the same gap the fairness check flagged on ctts. The clause is now bidirectional: "`LargeOffsets` selects co64, a 64 bit mdat header and saio version 1; without it stco and saio version 0" |
| Ftyp field preservation | `KeepsTheFtypBox` | a custom ftyp (major brand mp42, minor version 512, three compatible brands) survives in full. Preservation of the ftyp was never actually stated, only the moov's, so the description now says "The ftyp comes from the init segment unchanged" |
| Malformed fragment structure | `RejectsAFragmentWithoutMdat`, `RejectsAFragmentWithoutMoof` | already handled by `checkFragmentData`, now covered. The error clause was widened to "a fragment that has no mdat box or whose sample data does not fit it" |

The description hit its 500 word ceiling this round. Three clauses were needed, so ten sentences were
tightened first (redundant qualifiers, "in ascending order of" to "by ascending", semicolons in place of
"and other tracks get none") to buy the room. No tested requirement was dropped: the word count went
493 to 493 while gaining the ftyp, saio version 0 and missing-box rules.

## Fairness round (R10) and coverage round

Test Fairness reported FAIL, 1 of 85 unfair: `RejectsAFragmentWithoutMoof` required an error for a nil
moof, which the description never named. The guard is real (`checkFragmentData` covers both boxes), so
the fix was two words rather than a deletion: the error clause now reads "a fragment that has no moof or
mdat box, or whose sample data does not fit it". 495 words, still inside the cap.

| Suggestion | Action | Outcome |
| --- | --- | --- |
| Unknown nested metadata | `KeepsUnknownNestedBoxes`, `NestedUnknownBoxesAreNotShared` | a free box nested inside minf survives with its payload intact while the sample tables beside it are rebuilt, and it is a distinct object in the output. Covered by the existing "everything else the moov holds" clause, so no new wording was needed |
| Fragment-to-init track mapping | deliberately NOT tested | a traf naming a track the moov does not describe: ignoring it and rejecting it are both defensible and the description determines neither. This is the same case dropped in R5 for the same reason. The reference ignores it, since it walks the moov's tracks rather than the fragments' trafs, but nothing pins that, so an implementation that errors also passes |

## Coverage round (R11)

| Suggestion | Action | Outcome |
| --- | --- | --- |
| Presentation duration with composition offsets | `DurationIgnoresCompositionOffsets`, `DurationWithCompositionOffsetsAndLateStart` | the wording was the problem, not the code. "Covers the whole presentation" could be read as extending the duration by composition offsets; the reference does not, and neither do ordinary muxers, since tkhd duration is the sum of edit durations and edits are expressed in media time. The rule is now literal: "A track duration is its media duration plus any leading empty edit, in movie timescale, rounded down". Two tests pin it, one with mixed positive and negative offsets, one combining offsets with a late start |
| Minimal ctts runs across fragment boundaries | `CttsRunMergesAcrossFragments` | equal non-zero offsets on the last sample of one fragment and the first of the next merge into a single run of two, so fragment boundaries do not break run compression |
| Unknown fragment track IDs | DECLINED, third time | see below |

The unknown-traf case has now been raised three times: dropped in R5 as undetermined, declined in R10,
and asked for again here as "a clean error". Two things block it. It is genuinely undetermined, so a test
either way pins an author choice, which is the exact failure the fairness gate has caught six times. And
the description has no room: it sits at 492 of a hard 500 words, and a clause naming the case costs about
ten. Making it fair would mean dropping a currently tested behaviour to buy the words. That is a scope
call for the user, not a silent edit, so the reference keeps ignoring such trafs (it walks the moov's
tracks, not the fragments') and nothing pins it either way.

## Coverage round (R12)

| Suggestion | Tests added | Outcome |
| --- | --- | --- |
| Failed-conversion immutability | `LeavesFragmentSamplesUntouched`, `LeavesTheInputUntouchedAfterAnError` | **found a real contract violation** (below) |
| Unknown fragment track | `RejectsAFragmentOfAnUnknownTrack` | resolved at last, see below |
| Sparse multi-track fragments | `SkipsFragmentsWithoutSamplesOfATrack` | a track missing from the middle fragment produces no empty chunk: three chunks for the complete track, two for the sparse one, sample order intact, and the sparse track's second chunk still lands after the other track's middle chunk |

The immutability suggestion exposed a genuine defect. `Fragment.GetFullSamples` fills each sample's
missing duration, size and flags from the tfhd and trex defaults IN PLACE, by design; its own doc comment
says so. So converting a file whose truns rely on defaults, which is the normal shape after
`OptimizeTrun`, wrote those resolved values back into the INPUT. The description promises "the input must
be left untouched", so the contract was simply false, and `InputFileUnchanged` never caught it because it
only inspected the init segment, not the fragments' truns. Fixed in the code rather than by weakening the
rule: `snapshotTrunSamples` copies the affected sample slices before reading and `restoreTrunSamples` puts
them back, on the error path as well. Mutation proof: removing the snapshot makes
`LeavesFragmentSamplesUntouched` fail and nothing else.

The unknown-traf case, raised in R5, R10, R11 and again here, is now IMPLEMENTED rather than declined.
The framing in this round is what unblocked it: the existing sentence already says an error comes back
when the "init segment does not describe its tracks for fragments", with the mvex and trex cases as
examples rather than an exhaustive list. A traf naming a track the moov never declares is exactly that,
so `checkFragmentTracks` now rejects it and no new words were needed. Word count stays at 492.

## Coverage round (R13)

| Suggestion | Tests added | Outcome |
| --- | --- | --- |
| Track-ID tie breaking | `TieBreakUsesTrackIDNotMoovOrder` | a moov whose track order is 7 then 3: at equal decode times the chunk of track 3 must come first, so sorting by slice index instead of track ID now fails |
| Overflow-safe time conversion | `ConvertsLargeTimesWithoutOverflow` | **found two real defects** (below) |
| Encrypted multi-traf fragment | `EncryptedAndClearTrafInOneFragment` | one moof holding an encrypted and a clear traf: auxiliary extraction is per traf, saiz and saio land only on the protected track, the auxiliary block sits before its chunk, and the clear track's samples and ordering are intact |

Two defects, both surfaced by the large-time case:

- `rescaleTime` multiplied before dividing, so a live-style epoch-anchored timestamp (1.75e9 seconds at
  90 kHz, a shape DASH sources produce routinely) overflowed uint64 and produced 110036176970782 instead
  of 315000000012000. Now the whole part is converted first and only the remainder is scaled, which
  cannot overflow unless the result itself does. The chunk limit conversion goes through the same helper.
- Durations past 32 bits were written into version 0 mvhd, tkhd and elst boxes, which carry 32-bit
  fields, so the correct value was computed and then truncated on encode. The in-memory probe missed this
  entirely; only the encode/decode round-trip in the test exposed it. Those boxes now switch to version 1
  when a value needs 64 bits.

A third defect came out of probing rather than the suggestions: `EdtsBox.AddChild` appends only to
`Children` and does not populate the typed `Elst` slice, against the repository's own container
convention. The returned file therefore had an edit list that was invisible until a round-trip. Every
existing test re-decodes the output, so none of them could see it. `ReturnedEditListIsReadable` now
inspects the returned object directly.

## Fairness round (R14): unfair test, coverage, and a mutation sweep

Test Fairness reported FAIL, 1 of 98 unfair: `ConstantIVEncryptionHasNoAuxInfo` required saiz and saio
to be ABSENT for constant-IV cbcs. The checker is right that the description never singles out omission,
and the repository's own encryption path creates both boxes unconditionally before it looks at the
scheme, so a solver following that structure would keep empty boxes. The assertion is now on what the
description does determine: no auxiliary BYTES (the record size is zero and mdat holds only sample data).
Whether the empty boxes are present is left free.

| Suggestion | Tests added | Outcome |
| --- | --- | --- |
| Missing init structure | `RejectsAFileWithoutInitSegment` | three variants in one test: no Init, no Moov, no Ftyp |
| Malformed encryption metadata | `RejectsSencWithWrongSampleCount`, `RejectsTruncatedSubSampleRecords` | a senc that does not cover every sample is rejected, and the input is verified unchanged afterwards. The error clause grew three words, "sample or encryption data does not fit it", so the case is contract-stated |

### Mutation sweep (the false-positive gate)

`../mutate.py` applies sixteen single-point mutations, each one a plausible wrong choice a solver could
make, and requires every one to be caught by at least one test. A mutation that passes the whole suite is
a false-positive hole: a stated requirement no test discriminates.

| Mutation | Caught by |
| --- | --- |
| offsets measured from the mdat payload, not the file start | ChunkBoundaryFollowsAccumulatedDuration (+3) |
| interleave compared in raw media timescale | MixedProtectionInterleavesByTime |
| tie broken by moov order instead of track ID | TieBreakUsesTrackIDNotMoovOrder |
| auxiliary block written after the sample data | EncryptedAndClearTrafInOneFragment (+4) |
| chunk boundary counts samples instead of duration | ChunkAlwaysHoldsOneSample (+3) |
| edit list never written | EmptyEditForLateStart (+1) |
| mvex kept in the output moov | DropsMvex (+1) |
| track duration ignores the leading empty edit | ConvertsLargeTimesWithoutOverflow (+2) |
| stts one entry per sample | ReadsSamplesThatUseFragmentDefaults (+3) |
| stsz never uses the uniform size | ReadsSamplesThatUseFragmentDefaults (+1) |
| stss written even when every sample is sync | ReadsSyncFlagsFromFragmentDefaults (+2) |
| ctts always version 0 | CttsVersionOneForNegativeOffsets |
| stsc entry per chunk, no run compression | StscMultipleEntries (+1) |
| saiz always uses per-sample sizes | EncryptedAndClearTrafInOneFragment (+3) |
| saio version 1 regardless of LargeOffsets | SaioVersionZeroWithoutLargeOffsets |
| the broken in-repo `NewSdtpEntry` left as it is | ReadsFirstSampleFlagsFromTheFragment (+3) |

16 of 16 caught, zero holes. Every mutation is also a live trap, so the same table is evidence that the
difficulty is real rather than assumed: a solver has sixteen distinct ways to be plausibly wrong, and
each one fails.

## Fairness round (R15)

Test Fairness reported FAIL, 1 of 103 unfair, and raised no coverage suggestions for the first time.
The flagged assertion was the `no-ftyp` subcase of `RejectsAFileWithoutInitSegment`: the description
enumerates the missing mvex, trex, moof and mdat errors but says nothing about a missing init ftyp, and
synthesising a default ftyp is a defensible alternative to rejecting. The subcase is REMOVED. The `no-init`
and `no-moov` subcases were both rated fair and stay. The reference still errors on a missing ftyp;
nothing pins it, so either behaviour passes.

The description was NOT extended for this. At 494 of 500 words there is no room for a clause, and the
case does not earn one: unlike the unknown-traf case in R12, no existing sentence can be read to cover
it, so stating it would have cost a tested behaviour elsewhere.

## Coverage round (R16)

| Suggestion | Tests added | Outcome |
| --- | --- | --- |
| Chunking across a trun boundary | `ChunkLimitCrossesATrunBoundary` | one fragment whose track-1 samples are split over several truns, with a 3 s limit landing mid-stream: chunks of 3 and 1 in two minimal stsc entries, order intact. Confirms truns of one fragment are a single sample stream for chunking, and that only fragment boundaries break a chunk |
| Multiple encrypted tracks | `TwoEncryptedTracksKeepSeparateAuxInfo` | two protected tracks with 8 and 16 byte records: independent saiz default sizes, one saio offset each, auxiliary blocks of 16 and 32 bytes ahead of their own chunks, records identified by a per-track marker byte, and the interleave still ordered by time then track ID |

Fixture note: `InitProtect` refuses mjpg sample entries ("visual sample entry type mjpg not yet
supported"), so the second encrypted track is audio. `protectOneTrack7c1e4b` also has to set `Moov.Trak`
as well as `Moov.Traks`, because `InitProtect` reads the stsd through `Moov.Trak` while checking the
length of `Moov.Traks`.

The false-positive sweep was re-run against the widened suite: 16 mutations, 16 caught, zero holes.

## Task Quality round (R17): the sdtp trap was unfair

Task Quality FAILED criterion 04 (The Challenge is Fair) on the one thing this file has been defending
since R2: the hidden tests require correct sdtp dependency fields, which the repository's own
`NewSdtpEntry` cannot produce because it packs `sampleDependedOn` twice and drops `sampleDependsOn`.
I had classified that as the HARDENING S5 pattern, "the repo's own tempting helper implements the wrong
policy", and treated the failing assertion as sufficient signal.

The reviewer is right and the earlier reasoning was wrong. S5 assumes the solver can SEE the failure and
work back from it. Here the tests are hidden, so a solver who reasonably trusts a helper the library
ships gets no signal at all: they satisfy every stated sentence, and still fail. The trap was not
"fix-hidden", it was requirement-hidden, which is a different and unfair thing.

Resolved the way the reviewer's second option suggests, by surfacing it in the prompt. The sdtp sentence
now ends "; the package's own entry helper packs them wrongly and needs fixing". Six sentences elsewhere
were tightened to pay for it, so the description went 494 to 480 words while gaining the disclosure.

This costs difficulty and that is the correct trade: a trap that only works while the prompt hides a
requirement is not difficulty, it is an unfair biter, and the too-easy risk it leaves behind is a problem
for the batch to measure rather than a reason to keep an unfair test.

## Coverage round (R17)

| Suggestion | Test | Outcome |
| --- | --- | --- |
| Oversized encryption auxiliary record | `RejectsAnOversizedAuxiliaryRecord` | a sample whose IV plus 60 subsample ranges exceeds the 8-bit size field of saiz is rejected, and the input is verified unchanged afterwards |

## Solution Quality round (R18): both 2/3 gaps closed

Solution Quality PASSED but scored 2/3 on comprehensiveness and 2/3 on code quality, naming two concrete
requirement-level gaps. Both were real and both are now fixed, which also makes the task harder rather
than easier: each gap is one more way for a solver to be plausibly wrong.

- `checkFragmentData` only compared the TOTAL sample bytes of a track against the mdat length. A trun
  whose data offset points late could pass that sum and still address past the end of the payload, which
  `GetFullSamples` would then slice. The check now resolves each trun's real window the way the library
  does, base data offset then `default-base-is-moof` then the trun data offset, and requires
  start+size to lie inside the payload. Offsets pointing before the payload are rejected too.
- `setTrackEditList` installed an edit list for late-starting tracks but never removed one the init
  segment already carried, so a zero-start track could keep an inherited `edts` even though the
  description says other tracks get none. `removeTrakEdts` now drops it.

Three tests added: `RejectsATrunPointingPastTheMdat`, `RejectsATrunStartingBeforeTheMdat`, and
`DropsAnEditListOfATrackStartingAtZero`. Both fixes were added to the mutation sweep, which now runs 18
mutations with 18 caught and no holes; the aggregate-size-only variant is caught solely by the new
trun-window test, so the added coverage is real rather than incidental.

## Coverage round (R19)

| Suggestion | Test | Outcome |
| --- | --- | --- |
| Unknown-box payload independence | `NestedUnknownBoxPayloadIsCopied` | the earlier test only proved distinct box pointers. This one writes into the output FreeBox payload and re-reads the input, so a shallow copy that shares the backing array is caught |
| Missing trex on an empty track | `RejectsAnEmptyTrackWithoutTrex` | confirms the trex rule is unconditional: a track carrying no samples is still rejected when its trex is gone, since the check runs over the moov's tracks before any sample is read |
| Large cross-track time ordering | `OrdersLargeTimesAcrossTracks` | two tracks at 90000 and 48000 Hz starting around 1.75e9 seconds, arranged so the correct interleave alternates between them. The previous large-time test had a single track and therefore never exercised the comparison arithmetic, only the duration conversion |

Two mutations were added to the sweep for the overflow work found in R13, which until now had no entry:
multiplying before dividing in `rescaleTime`, and never switching the duration boxes to version 1. Both
are caught. The sweep now runs 20 mutations, 20 caught, zero holes.

## Coverage round (R20)

| Suggestion | Test | Outcome |
| --- | --- | --- |
| Error result shape | `ReturnsNoFileWithAnError` | four error paths (not fragmented, no init, no mvex, truncated mdat) each return a nil file alongside the error. The suggestion hedged this with "if that API contract is intended", so it was STATED before being tested: the error sentence now reads "Errors come back, with no file, for ..." |
| Encryption metadata preservation | `KeepsProtectionMetadata` | cenc and cbcs cases compare scheme type, original data format, default KID, per-sample IV size, constant IV and the protected flag against the input, then byte-compare the whole encoded sinf. Also asserts the output does not share the sinf box with the input |

The first suggestion is a good example of why the hedge matters. Asserting a nil return without stating
it would have been the same unstated-requirement failure the fairness gate has now caught seven times;
four words in the prompt turn it into a contract. The second needed no words: "everything else the moov
holds, its boxes and its tracks' fields, is kept unchanged" already covers sinf, schm and tenc, which
live inside the sample description.

## Description Quality round (R21) — and a direct conflict with Task Quality

All four description comments applied; the prompt went 482 to 450 words.

| Comment | Action |
| --- | --- |
| HIGH: drop "the package's own entry helper packs them wrongly and needs fixing" | replaced with the observable requirement, "each packing the four dependency fields of that sample's flags" |
| MEDIUM: redundant "its boxes and its tracks' fields" | trimmed to "Everything else the moov holds is kept unchanged" |
| MEDIUM: filler "with no file" | removed, and `ReturnsNoFileWithAnError` deleted with it |
| inferable preamble about what the package can already do | removed; the prompt now opens on the API to add |

### The conflict, stated plainly

R17 Task Quality FAILED criterion 04 BECAUSE the sdtp helper defect was undisclosed: "hidden tests
depend on fixing a separate existing bug ... a reasonable solver could trust and use that visible helper
... then fail hidden tests for reasons not surfaced by the prompt." R21 Description Quality now blocks
that same disclosure as an implementation hint.

Both are blocking, so the resolution follows the wording Description Quality itself proposed, and its own
reasoning is the argument to use if Task Quality objects again: "Hidden tests care about the emitted
bits, not whether the agent fixes that specific helper." The requirement is now stated as an obligation
on the OUTPUT ("each entry packs the four dependency fields of that sample's flags"), which is the same
shape as every other trap here: the offset base, the movie-timescale comparison and the auxiliary-block
placement are all stated as output contracts, and none of them names an internal.

If Task Quality fails on this again, the contest is: the prompt states the sdtp obligation as plainly as
it states the others, and the two checks cannot both be satisfied by naming the helper.

Removing `ReturnsNoFileWithAnError` reverses the first half of R20. The coverage suggestion that asked
for it hedged with "if that API contract is intended"; Description Quality has now answered that it is
not, so both the sentence and the test are gone rather than leaving an unstated assertion behind.

## Difficulty round (R22): sample description switching

Added a capability the reference previously hardcoded. `buildStsc` always wrote description index 1, so
a fragmented file whose fragments switch stsd entries was silently flattened onto the wrong sample entry.
Real input does this: `tfhd` carries a sample description index per traf, falling back to the trex
default. The conversion now resolves it per fragment, records it per sample, carries it on each chunk,
validates it against the stsd, and keys the stsc run compression on it.

This compounds with machinery that was already there rather than sitting beside it: an stsc run now
continues only while BOTH the sample count and the description hold, so the run-compression rule that
four earlier tests pin has a second dimension. The mutation "stsc run ignores the sample description"
is caught by nothing except the new tests.

Four tests: `KeepsTheSampleDescriptionOfEachFragment`, `StscRunBreaksOnADescriptionChange`,
`KeepsOneStscRunForOneDescription`, `RejectsAnUnknownSampleDescription`. One contract sentence, +30 words
before trimming, 480 total.

Two things the sweep and the repo taught during this round:

- A first attempt guarded against a chunk MIXING two descriptions. The sweep flagged it as a
  false-positive hole, which was correct for a better reason than it knew: `tfhd` is per traf, so the
  index cannot change inside a fragment, and chunks never span fragments. The guard was unreachable and
  the matching meta clause vacuous, so both were removed. This is the sweep catching dead code, not just
  missing tests.
- `StscBox.GetSampleDescriptionID(chunkNr)` indexes its slice per CHUNK while `AddEntry` and `EncodeSW`
  populate and read it per ENTRY, so it panics on any multi-entry stsc. The tests deliberately assert on
  `Entries` and `SampleDescriptionID` instead, and the solution does NOT fix that accessor: the feature
  never calls it, and requiring an unrelated helper fix is exactly what failed Task Quality in R17.

## Test Fairness round (R23)

The check returned FAIL on 1 of 115: `TestProgressiveRejectsAnUnknownSampleDescription` pinned an error
policy that the meta's enumerated error list did not name. The report is right, and the flag is a
description bug rather than a test bug: the reference DOES reject an out-of-range index, and a solver
who preserved index 7 verbatim would have written a file whose stsc points past stsd. Fixed by naming
the case in the error sentence (a fragment "that names a sample description the init segment does not
hold"), which is where the other five error cases already live. meta.md 480 -> 491 words, still ASCII,
still under the 500 cap.

Also took the single advisory suggestion: `TestProgressiveFallsBackToTheTrexSampleDescription` builds a
fragment whose tfhd omits the index while trex carries a non-default 2, then asserts the run's
description. The previous cases only exercised tfhd-provided indices or the ordinary default of 1, so
the trex fallback half of the contract sentence had no discriminating test. A new mutation ("trex
default description ignored, plain 1 used instead") confirms it discriminates: caught only by this test.

Two side fixes the round surfaced:

- The report called `KeepsOneStscRunForOneDescription` shallow on the description itself, because
  `StscBox` stores a single shared ID in an unexported field and leaves `SampleDescriptionID` empty, so
  the test's guarded assertion normally skipped. Both single-run tests now assert through the repo's own
  `GetSampleDescriptionID(1)`, which is exact and representation-independent. (Safe here: that accessor
  is only broken for multi-entry boxes, and both of these are single-entry.)
- Two mutation patterns had gone stale against refactors and were silently reporting SKIP rather than
  CAUGHT, which is a false green. Re-anchored; the sweep is now 25 mutations, 25 caught, 0 skipped,
  0 holes.

## Coverage round (R24)

Two advisory suggestions, both taken.

`TestProgressiveRejectsAnUnknownTrexSampleDescription` covers the half of the validation the R23 test
missed: the out-of-range index arriving from the trex default rather than from an explicit tfhd. Same
guard, different path into it.

The second suggestion asked for the missing-ftyp error case, which is the subcase Test Fairness FAILed
at R15 and I removed then. Re-added, and the R15 reasoning is what changed, not the verdict: the
objection was that nothing in the description pinned it, and the note there records I could not state it
because meta stood at 494 of 500 words. Trimming since has left room, so the error sentence now reads
"with no ftyp or mvex", the case is stated, and the test is fair on the checker's own terms. meta.md
491 -> 493 words. This is the R15 conflict actually resolved rather than deferred again.

A "missing init ftyp not rejected" mutation confirms the re-added subcase discriminates; without it the
conversion reaches `cloneFtyp(nil)`.

Sweep now 25 mutations, 25 caught, 0 skipped, 0 holes. (The R23 note's count of 25 was off by one; 24
was the true figure at that point, since the stale-pattern re-anchoring restored two that had been
silently skipping rather than adding any.)

## Coverage round (R25)

Both suggestions taken, and one of them found a real weakness rather than just a gap.

`EncryptedSampleDataRoundTrip` only checked that each output sample was 16 bytes. The ciphertext is not
known to the fixture (`EncryptFragment` rewrites the sample data in place), so the expectation now comes
from decoding the input and reading its samples back through `GetFullSamples`, and the test compares
byte for byte. Proof it matters: under a new "chunk writes its first sample repeatedly" mutation, every
sample is still 16 bytes and the old assertion passed; the new one fails. That mutation is caught by 16
tests in total, so the encrypted path was the thin spot, not the concept.

`DefaultModeMdatHeader` and `LargeOffsetsMdatIsSixteenByteHeader` assert the mdat header itself
(`LargeSize`, `HeaderSize()`, `Size()`, `PayloadAbsoluteOffset()`) instead of inferring it from a chunk
offset. Two mutations pin them: dropping the `mdatHdrSize += 8` and dropping `LargeSize` on the built
box. The second is the more interesting one, since offsets and header can disagree independently.

Also fixed the sweep script: it piped test output through `tail -40`, so failure counts were truncated
(the offsets mutation reported 7, the true figure is 26). Hole detection was never affected, since a
mutation that fails nothing produces short output either way, but the per-mutation counts were lower
bounds and read as if requirements were more narrowly covered than they are. Now greps the FAIL lines
directly.

Sweep: 28 mutations, 28 caught, 0 skipped, 0 holes. Eight are caught by exactly one test, which is the
list of single-point discriminators to keep an eye on if a test is ever cut.

## Coverage round (R26) - one taken, one declined

`TestProgressiveLargeOffsetsWithSplitSubSampleChunks` takes the first suggestion: the AVC fixture with
varying subsample records, split by a 100 ms limit, under `LargeOffsets`. It pins co64 present with stco
absent, saio version 1, a 16 byte mdat header, one saio offset per chunk, every auxiliary block byte for
byte at its 64-bit offset, each co64 offset landing exactly at the end of its block, and strictly
increasing offsets. Nothing new had to be stated: every clause it checks is already in the description,
which is the point of a composition case.

The second suggestion is DECLINED, and not because it is wrong. Probed the reference: strip the senc
from the encrypted AVC fragment and conversion SUCCEEDS, emitting ciphertext samples with no saiz, no
saio and a 24516 byte mdat. That is silent data loss and an error would be better behaviour.

It is declined because making it testable needs a rule the description does not have, and there is no
room to add one. The rule cannot be "a protected track without senc is an error": the cbcs fixture in
`ConstantIVEncryptionHasNoAuxInfo` is a protected `enca` track that legitimately carries no per-sample
information, and that test already passes and is rated fair. So the sentence has to distinguish tracks
whose samples carry their own initialization vectors, which costs about 18 words. meta.md is at 493 of
a hard 500. A compression pass over the error sentence recovered 1 word, and the only 12-word block
worth cutting is "so a later change to one never shows up in the other", which is the clause the
fairness check cites as the anchor for both mutation-based aliasing tests. Trading a proven-fair anchor
for an untested new rule is the wrong direction.

Recorded here as a known limitation rather than a gap: current behaviour is defensible under the
description as written, and the input-purity half of the suggestion is already covered by
`LeavesTheInputUntouchedAfterAnError` and the two aliasing tests.

## Coverage round (R27) - the declined suggestion, reversed

The same two suggestions came back. The first is stale: `LargeOffsetsWithSplitSubSampleChunks` went into
test.patch in R26 (it is at line 1866 of the patch). No action.

The second repeated, so I reversed the R26 decline. What changed is the budget, not the analysis: a
lossless compression pass over the description freed the words the rule needs.

- "a single mdat" -> "one mdat"
- "an init segment that does not describe its tracks for fragments" -> "an init segment not describing
  the tracks its fragments carry"
- "past that many milliseconds, and every chunk holds" -> "past that many milliseconds; every chunk holds"
- "the smallest number of entries" -> "the fewest entries"

Four words freed, all pure paraphrase, no stated behaviour dropped. The error list now includes a
fragment "that has no senc for samples carrying their own initialization vectors". meta.md 499 of 500.
I did NOT cut the "so a later change to one never shows up in the other" clause that R26 identified as
the tempting 12-word block; it stays, since it anchors both aliasing tests.

`needsPerSampleIV` resolves the sinf of the RESOLVED sample description (the R22 index, not
`Moov.GetSinf`, which only ever reads `Children[0]`) and returns true only when tenc reports protected
AND a non-zero per-sample IV size. `fragmentAuxInfo` errors when such a track's traf has no senc.

The point of the rule is the trap pair, and the sweep proves it opposes:

| Mutation | Caught by |
| --- | --- |
| missing senc not rejected | `RejectsAProtectedFragmentWithoutSenc` (1 test) |
| senc demanded of EVERY protected track, constant IV included | `ConstantIVEncryptionHasNoAuxInfo` + 2 more |

So the obvious fix for the first failure ("protected means senc is required") breaks a different test
that says nothing about senc, and its failure message is about auxiliary info sizes rather than the rule
that is wrong. Interdependent and misdirecting, which is what the tier asks for. `ConstantIVFragmentNeedsNoSenc`
makes the counterpart explicit by stripping the senc from the cbcs fixture and requiring conversion to
succeed with no saiz or saio.

Sweep now 30 mutations, 30 caught, 0 skipped, 0 holes. Solution 556 -> 572 human-effective LOC.

## Formatting round (R28)

AI-shape heuristic warned on two 150+ word walls of prose (0 em dashes, 0 hard wraps, so structure only).
Split at existing sentence boundaries: chunking rules out of the moov paragraph, durations and edit lists
out of the table paragraph. Not one word changed, so every test still traces to the same sentence and no
re-validation of the suite was needed.

First split gave 7 body paragraphs, one over the 2-6 range in the description rules, so the errors
sentence went back into the opening paragraph. Final shape: 6 body paragraphs, longest 132 words, 499
total, ASCII, no em dashes. Both signals satisfied at once.

## Test-quality round (R29)

One WARNING: `RoundsConvertedDurationsDown` and `OrdersLargeTimesAcrossTracks` asserted the output movie
timescale equals 90000, which the description does not mandate.

The 90000 is the INPUT fixture's timescale, set by the repo's own `CreateMvhd`, and keeping it is
already required by "Everything else the moov holds is kept unchanged". So the assertion was fair but
phrased as a policy claim. Both now compare against `inputMovieTimescale7c1e4b(t, data)`, so they read
as what they are: preservation checks. Strictly stronger too, since a solver who rewrites the timescale
to anything now fails with a message naming the right cause.

`RoundsConvertedDurationsDown` keeps its literal 16326 / 10204 / 6122, which are the rounding results the
test exists to pin. Those follow from the fixture's 44100 media timescale plus the preserved movie
timescale and the stated rounding rule, so they are derived, not policy. Added a guard that fails loudly
if the fixture's timescale ever stops being 90000, so the derivation cannot silently rot.

New mutation "output movie timescale rewritten instead of kept" is caught by 6 tests, which is the proof
that preservation is pinned independently of the literal.

Sweep now 31 mutations, 31 caught, 0 skipped, 0 holes. No description change, no test removed.

## FP check round (R30) - a real hole in the tests

FALSE POSITIVE, adjudicated. The bug is in the CANDIDATE, not the reference, but per the FP rule that
makes it MY defect: an agent passed all 122 hidden tests while getting a stated requirement wrong, so the
tests were the thing at fault.

The candidate resolved per-sample IV size with `Moov.GetSinf(trackID)`, which reads only
`stsd.Children[0]` ("Get first (and only)"), instead of the description the fragment selects. The
reference already did this correctly via `needsPerSampleIV(trak, descID)`. Every encrypted fixture I had
was single-description, so `Children[0]` and the selected entry were always the same box and nothing
could tell the two apart. Two directions were undetectable:

- protected entry NOT first and selected -> missing senc goes unnoticed
- protected entry first and a CLEAR entry selected -> a valid fragment is wrongly rejected

`buildMixedDescriptions7c1e4b` builds a track whose stsd holds both an enca and an mp4a entry in either
order, by assembling the protected entry from an `InitProtect`ed init and the clear entry from a plain
one. `SencIsRequiredByTheSelectedDescription` and `SencNotRequiredByAClearSelectedDescription` cover one
direction each, and both assert the fixture's stsd order first so they cannot silently stop testing what
they claim. New mutation "per-sample IV decided from stsd[0], not the selected description" reproduces
the candidate exactly and is caught by both.

The judges split on a second point, which turned out to be a real ambiguity of mine. Judge #2 read the
track-duration clause as sum-of-floors and called it defensible; judge #3 called it a fail. Rereading
"its media duration plus any leading empty edit, in movie timescale, rounded down", both readings fit.
Worse, `RoundsConvertedDurationsDown` could not discriminate: with its numbers 10204 + 6122 = 16326
exactly, so floor-of-sum and sum-of-floors agree and the test proved nothing about which was meant.

Fixed on both sides. The clause now reads "the sum in movie timescale, rounded down", and
`TrackDurationRoundsTheWholeSum` uses a fixture where the two readings diverge: media timescale 44100,
1000 ticks of leading edit and 1000 of media, so the edits round to 2040 each while the track duration
is 4081. Sum-of-floors gives 4080. Mutation "track duration sums the rounded parts" is caught by exactly
that one test. Paid for by "The media duration is the sum of the sample durations" ->
"The media duration sums the sample durations", so meta.md went 499 -> 498.

Sweep now 33 mutations, 33 caught, 0 skipped, 0 holes. 122 -> 125 tests. Solution unchanged at 572
human-effective LOC; the reference needed no fix in either case, only the tests and one sentence.

## Batch 1 (R31) - fairness fixed, and the real finding is difficulty

Two Orion runs, both FAIL, both on the SAME assertion: `TrackDurationRoundsTheWholeSum`, media edit
2041 vs 2040. Evaluator #1 called it a missed requirement, evaluator #2 called it a verifier blocker
with `agent_blame_unfair: true` and `description_clear: false`. Evaluator #2 is right.

The description pins the whole-sum rounding of the TRACK duration. It never says each elst
SegmentDuration is independently converted and rounded down. Both agents computed the media edit as
trackDuration minus the leading edit, which keeps the two edits summing to tkhd duration and is a
coherent reading. I introduced that assertion in R30 to settle the FP judges' split on track-duration
rounding, and in doing so pinned a SECOND, undocumented convention.

Measured which assertions actually depended on it by re-implementing the agents' reading in the
reference and running the suite: exactly one test failed, the one I added. Every other edit-list test
(`EmptyEditForLateStart`, `RoundsConvertedDurationsDown`) uses figures where both readings agree, so
they were never at risk. Removed the two elst SegmentDuration assertions from that test and kept the
tkhd/mvhd ones, which are the documented rule; the test still discriminates floor-of-sum from
sum-of-floors (4081 vs 4080) and the "track duration sums the rounded parts" mutation is still caught by
it. Both readings now pass the whole suite. Chose this over documenting the convention because meta.md
sits at 498 of 500 and the clause needs about 9 words, and because a rounding convention is a
single-point self-revealing trap, which is not the kind of difficulty the tier wants.

### The finding that matters

With that assertion gone, both runs become PASSES. Batch 1 corrected reads 2/2 = 100% against a 40%
cap. Both agents built a complete, correct implementation in ~20 minutes, 38 and 54 messages, 1356 and
1385 LOC, and diverged from the reference on ONE line.

So the design assumption was wrong. The difficulty was expected to come from the breadth of the
conversion (chunking, cross-track ordering, table minimisation, absolute offsets, encryption aux
layout, deep-copy purity). Neither run had trouble with any of it. The 125 tests are thorough and fair,
but thoroughness is not difficulty: every requirement is individually stated and individually
implementable, and nothing forces a wrong first attempt.

There is currently NO surviving trap. The only discriminator this batch produced was unfair, and
removing it leaves the problem too easy. This is not fixable by adding more coverage; it needs a real
interdependent + misdirecting mechanism, or a different pick.

## Coverage round (R32) - both declined, and the reason is the ceiling

Probed suggestion 1 (clear/protected description switch inside ONE track) instead of assuming. It is
currently a rejection in TWO different ways, and neither is documented:

- clear entry FIRST: mp4ff itself cannot parse the fragment's senc. `Fragment.ParseSenc`
  (mp4/fragment.go:94-113) resolves the per-sample IV size through `init.Moov.GetSinf(trackID)`, the same
  `stsd.Children[0]` accessor the R30 FP was about. With a clear entry first there is no tenc to find, so
  the senc stays read-but-not-parsed and conversion fails with "senc box is not parsed".
- protected entry FIRST (so the library can parse): conversion fails with "trackID 1 has auxiliary
  information for 2 of 4 samples", because auxiliary info is collected per track and half the fragments
  contribute none.

Supporting it properly means saiz with per-sample sizes that are zero for the clear samples, and chunk
auxiliary blocks only where protected samples land. That is real work and, more to the point, real
DIFFICULTY of the interdependent kind: the R22 description switching would start coupling to the R27
encryption layout, and a solver treating auxiliary info as all-or-nothing per track would fail on byte
offsets rather than on anything naming protection.

It is not buildable within the description budget. meta.md is at 498 of a hard 500 and the rule needs
roughly 15 words. I tried compressing the error sentence (61 words) and got a 47-word version, but the
14 words it frees come out of "for samples carrying their own initialization vectors", which is exactly
the precision that keeps the constant-IV case fair. Trading it would re-break what R27 fixed.

Deliberately did NOT add a test pinning either rejection. Both are undocumented, and pinning undocumented
behaviour is precisely the mistake that produced the R31 unfair-failure batch. Leaving them unpinned is
safe: a solver that supports mixed protection and one that rejects it both pass, and neither is a stated
requirement, so no FP exposure either way.

Suggestion 2 (32-bit offset overflow without LargeOffsets) is declined as impractical, which the
suggestion itself allows for. Offsets only pass 2^32 after about 4 GB of real sample bytes, and
`checkFragmentData` requires those bytes to actually exist in the fragment mdat, so there is no cheap
synthetic route. Noting the asymmetry for the record: `writeChunkOffsets` DOES error when an stco offset
exceeds MaxUint32, while saio version 0 has no equivalent guard and would truncate. Both paths are
unreachable in any test I can build, so I am not adding a guard that no test can exercise.

### What this round confirms

Two consecutive advisory rounds have now landed on capability the description has no room to state. That
is the same wall as R26 (missing senc, deferred) and R27 (paid for with the last words). The description
is saturated at 498/500 with 125 tests, and the batch says the tested surface is too easy. Those two
facts together are the argument that this pick has reached its ceiling, not that it needs another
coverage round.

## Fairness and solvability audit

- Description to test: every clause in meta.md has at least one test.
- Test to description: all 59 tests trace to a clause (mapped by bucket: box order 1, fragmented flag 2,
  mvex 1, sample order 6, chunking 7, mdat order and offsets 6, LargeOffsets 4, sample tables 18,
  durations 2, edit lists 2, empty track 1, encryption 7, purity 2). Nothing unmapped.
- Signatures pinned: `ToProgressive`, `ProgressiveConfig` and both field names and types are stated
  verbatim in meta.md, so no test can fail on a guessed API shape (the fake-difficulty anti-pattern).
- Codebase-inferable requirements: one, the derived `FirstSampleNr` bookkeeping inside the repo's own
  `StscBox`, exercised by `TestProgressiveStscChunkLookup`. Within the limit of one.
- The `NewSdtpEntry` trap is CONTRACT-STATED and FIX-HIDDEN: meta states the entries keep the four
  dependency fields, and only the fact that the repo's helper drops one of them is left to discovery.
- Left deliberately untested because the description does not determine it: `parse_source`-style entry
  points are not part of this task, and `File.AddChild` misdetecting a progressive file whose first
  track has no samples is not forced by any test (the empty-track fixture puts the empty track second).
- Deterministic output is required by the stated ordering rule, so `SecondFlattenIsStable` cannot fail a
  correct implementation; it only catches map-iteration-order layouts.

## Open items before submit

- No agent batch has been run. Difficulty is unmeasured; the 10-run batch is the only oracle.
- If the batch reads too easy, the first lever is composition (chunk duration limit crossed with encrypted tracks and LargeOffsets at once), not more table breadth.
