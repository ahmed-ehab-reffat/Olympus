# enmime-preserving-edits - evaluation results

No agent batch has been run yet.

## Local validation

| Check | Result |
|---|---|
| Environment Quality (vanilla, offline) | `go build ./...` + `go test ./...` clean, 10/10 packages |
| Base mode, solution applied | 605 cases, 0 failures, exit 0 (TestRandOption excluded, see below) |
| New mode, solution applied | 100 cases, 0 failures, exit 0 |
| New mode on base (F2P) | 100 cases, 100 failures, exit 1 |
| Base mode on base | 606 cases, 0 failures, exit 0 |
| Untouched round trip, testdata/mail | 41 of 42 byte identical (erroneous.raw does not parse on base) |
| Flakiness, 3x both modes | identical every run |
| Test Fairness | 16 rounds; the last flag was errors.Is identity on the writer sentinel, now a report-and-recover check |
| Solution Quality | FAIL on two renamed test nodes (round 19 renames reverted); its epilogue-scan and robustness findings fixed |
| Verify Solution | base-run and solution-run node identities diff clean (100 == 100); all four accumulated boundary-test names emit |
| Harness exit code | verified: a mutated (failing) new-mode run reports exit 1 |
| solution.patch | 658 platform-counter, 495 reviewer-effective, 4 files |
| test.patch | 2560 platform-counter, 2 files, test.sh at mode 100755 |
| Banned test-name markers | none |

## Batch 1 (6 runs, Orion x3 + Nova x3, eval Nova) - 0/6 PASS, UNSOLVABLE

| Run | Solver | Verdict | Msgs | LOC | Files | Failed | Failure classes |
|---|---|---|---|---|---|---|---|
| 1 | Orion | FAIL_MISSED_REQUIREMENT | 78 | 1660 | 4 | 5 | mixed-ending framing, blank-line body, own-header collision, QP-emitted collision, short write |
| 2 | Orion | FAIL_MISSED_REQUIREMENT | 114 | 1502 | 4 | 4 | preamble/epilogue bytes, blank-line body, QP parity (Binary=true), own-header collision |
| 3 | Orion | FAIL_MISSED_REQUIREMENT | 99 | 1773 | 4 | 5 | own-header collision, short write, 3x QP over-encoding |
| 4 | Nova | FAIL_MISSED_REQUIREMENT | 55 | 1092 | 4 | 15 | built-part bodies, empty multipart, no-op delete, builder CTE, nested ending, own-header, short write |
| 5 | Nova | FAIL_MISSED_REQUIREMENT | 56 | 1054 | 4 | 61 | QP over-encoding, then stopped at the emptied-multipart reparse (58 unrun) |
| 6 | Nova | FAIL_MISSED_REQUIREMENT | 56 | 1043 | 4 | 8 | framing edge bytes, no-op delete, builder CTE, own-header, short write |

Every evaluator said description_clear, tests_deterministic, difficulty challenging, blocker none,
agent_blame_unfair false. Long-horizon metrics clear the floor comfortably: 55-114 messages (median
~67), 4 files, 1043-1773 LOC.

Failure classes by how many runs they killed:

| Class | Runs | Stated? | Action |
|---|---|---|---|
| own-header collision region | 5 | broad wording only; stricter than MIME delimiter parsing | made optional |
| short write, nil error | 4-5 | NOT stated (the writer clause was removed in round 24 on a HIGH) | test no longer gates on it |
| QP byte shape / encoder parity | 3 | round trip stated, byte shape only repo-inferable | tests read the round trip |
| framing edge bytes, blank-line body | 3 | explicit, and the core of the feature | KEPT |
| builder CTE per content type, no-op delete, built-part bodies, empty multipart | 1-2 each | explicit | KEPT |

## Batch 1 remediation (round 28)

Relaxed the three weakest-justified classes, kept every explicit one:

- `TestRewriteShortWriteWithoutAnErrorStillFails` no longer requires an error, only that the message
  survives the truncating writer, edited or not. The reference still reports `io.ErrShortWrite`.
- `TestRewriteReplaceUsesTheEncodingTheHeaderNames` and `TestRewriteNestedMultipartSurvivesAnEditBelowIt`
  read the edit back through the parser instead of matching one encoder's byte shape.
- `TestRewriteCollisionLooksAtTheEncodedBytesNotTheContent` derives the expected outcome from the bytes
  the implementation actually emitted, so any conforming encoder passes while a decoded-content scan
  still fails.
- `TestRewriteOwnHeaderMarkerForcesBoundaryRegeneration` accepts either reading and pins what both owe:
  the odd header exactly preserved, three structural marker lines in the body, a readable message.

Projected: the run-3 class (5 failures, all in the relaxed set) now passes clean; runs 1, 2 and 6 still
fail on the framing bytes that are the point of the task. Expect roughly 1 in 6, at the hard edge of
the band.

## Batch 2 (6 runs, Orion x2 + Nova x4, eval Nova) - 0/6 PASS

| Run | Solver | Verdict | Msgs | LOC | Failed | Dominant cause |
|---|---|---|---|---|---|---|
| 1 | Orion | FAIL_MISSED_REQUIREMENT | 73 | 1516 | 4 of 38 run | built-part Content ignored, then own panic on the emptied multipart |
| 2 | Orion | FAIL_MISSED_REQUIREMENT | 86 | 1543 | 4 of 38 run | built-part Content, corpus epilogue bytes, own slice panic |
| 3 | Nova | FAIL_MISSED_REQUIREMENT | 66 | 1169 | 7 | framing edge bytes, subtree ending, no-op delete, builder CTE |
| 4 | Nova | FAIL_MISSED_REQUIREMENT | 73 | 1207 | 4 executed | corpus epilogue (TeeReader read only what the parser consumed), built-part Content |
| 5 | Nova | FAIL_MISSED_REQUIREMENT | 69 | 1159 | 10 | built-part Content (6 of the 10), builder CTE, marker line endings |
| 6 | Nova | FAIL_MISSED_REQUIREMENT | 71 | 1491 | 8 | built-part Content, no-op delete, builder CTE, subtree ending, cross-tree marker choice |

The relaxations from batch 1 held: no run failed on short writes, quoted-printable byte shape, or the
multipart's own header. The profile moved entirely to a new dominant class.

| Class | Runs | Stated? | Action |
|---|---|---|---|
| a built part's `Content` never reaches the wire | 5 | NOT stated - meta never said where an added part's body comes from | STATED now |
| two separate trees must pick the same regenerated marker | 1 | not stated, and not implied | test relaxed to same-tree stability |
| the closing marker's own line ending in a mixed-ending message | 2-3 | ambiguous: meta says "the way that message's lines end", singular | epilogue assertion no longer pins it |
| framing edge bytes, blank-line body, subtree ending | 3-4 | explicit, and the core | KEPT |
| builder CTE per content type | 3 | explicit delegation + visible table | KEPT |
| no-op delete | 2 | explicit | KEPT |

## Batch 2 remediation (round 30)

- meta gained one sentence: an added part is written from its `Content`. Ignoring that field kills 8
  tests (AppendChild, InsertBefore, mid-chain insert, inserted-child collision, add-back after
  emptying, LF-only append, built-part delete, tail relink), which is exactly the run-5 profile.
- `TestRewriteBoundaryRegenerationSurvivesAWriterFailure` now checks the retry against the same tree
  rather than a separate control, so any deterministic-per-message choice passes. Verified: a different
  marker-numbering scheme now kills nothing.
- `TestRewriteKeepsPreambleAndEpilogueByteForByte` still pins the preamble and epilogue exactly but no
  longer pins which ending the closing marker line carries in the deliberately mixed-ending fixture.

Two runs also aborted the package on their own panics (slice bounds in their capture logic), and two
runs' evaluators flagged harness problems (test.patch 3-way merge failure, missing apply_patch on
PATH) without changing the verdict.

## Batch 3 (5 runs, Nova x5, eval Nova) - 0/5 PASS, but three runs never finished

| Run | Verdict | Msgs | LOC | Observed | What actually happened |
|---|---|---|---|---|---|
| 1 | FAIL_MISSED_REQUIREMENT | 70 | 1008 | 37 pass, 1 fail, 60 unreported | failed the empty-multipart two-marker form at test 38, process stopped |
| 2 | FAIL_MISSED_REQUIREMENT | 59 | 1107 | 91 pass, 7 fail | corpus epilogue, no-op delete, CT params dropped by Replace, builder CTE, boundary retarget, subtree ending, epilogue collision |
| 3 | FAIL_MISSED_REQUIREMENT | 49 | 1065 | 91 pass, 7 fail | extra ending in the empty multipart, subtree ending, ancestor blank line, blank-line body, no-op delete, builder CTE x2 |
| 4 | FAIL_MISSED_REQUIREMENT | 49 | 1110 | 1 fail, 97 synthesized | panicked on testdata/mail/multipart-wo-boundary.raw in the FIRST test; evaluator logged blocker_type verifier |
| 5 | FAIL_MISSED_REQUIREMENT | 73 | 1199 | 37 pass, 1 fail, 60 unreported | panicked reparsing its own emptied multipart at test 38, process stopped |

The batch-1 and batch-2 relaxations all held: nothing failed on short writes, quoted-printable byte
shape, the own-header rule, or built-part content. Three of five runs produced exactly ONE observed
failure and then died, so their true failure counts are unknown - run 5 was 37 for 37 before its panic.

## Batch 3 remediation (round 32) - aimed squarely at solvability

The suite was amplifying single defects into whole-run losses. Two structural fixes and one scope cut:

- The emptied-multipart tests no longer reparse what they produced. `--BOUND\r\n--BOUND--` is a
  degenerate message, and reparsing it is where runs 1, 5 (and batch-2 runs 1, 2) panicked or hung,
  costing 60 results each. The prompt only requires the two-marker form, which is still asserted
  exactly; reparsing it was my addition.
- `TestRewriteUntouchedIsIdenticalAcrossCorpus` moved from FIRST to LAST in the file. It feeds every
  repository fixture through Rewrite, so it is the likeliest place for someone's implementation to
  panic - and in run 4 it did, at test 1, taking 97 results with it. Go runs tests in source order, so
  the loss is now bounded to itself.
- `TestRewriteReplacementWithoutCTEFollowsTheBuilderForEveryContentType` no longer pins 8bit and base64
  per content type. It now requires a writable encoding to be named, exactly one CTE header added, and
  the content to round-trip. This was the single most-missed fair requirement: 5 of 12 runs across
  batches reached for the generic content scanner instead of the builder's per-type table.

Names are unchanged throughout; only assertion strength and source order moved.

## Batch 4 (10 runs, Orion x3 + Nova x7) - 0/10, but 1 to 4 failures out of 98

| Run | Failed | What failed |
|---|---|---|
| 1 | 2 | corpus message with a permissive closing delimiter; extra blank line before the enclosing marker |
| 2 | 2 | no-op delete; SetHeader boundary retention not written to the header |
| 3 | 1 | replacement content ending in CRLF lost its final CRLF |
| 4 | 4 | extra blank line x3 (incl. the emptied multipart); no-op delete |
| 5 | 2 | no-op delete; built part loses Content after DeleteHeader |
| 6 | 3 | no-op delete; built part after DeleteHeader; regenerated boundary not reported |
| 7 | 1 | no-op delete |
| 8 | 2 | extra blank line; epilogue left out of the collision scan |
| 9 | 1 | epilogue left out of the collision scan |
| 10 | 3 | no-op delete; extra blank line; boundary regenerated during SetHeader instead of at rewrite |

Every relaxation from rounds 32-35 held. The suite went from 5-15 failures per run to 1-4, and the mass
concentrated in exactly two places: the no-op delete (6 of 10) and one extra line ending where a rebuilt
child meets the enclosing marker (4 of 10). Run 7 was one test away.

## Round 36 - the two remaining blockers

- `TestRewriteDeleteMissingHeaderIsANoOp` dropped its corpus fixture and now uses a nested synthetic
  message instead. The rule is unchanged, but it no longer doubles as a rebuild-fidelity test on an
  exotic corpus message: every failing run rebuilt correctly for ordinary messages and only diverged on
  that fixture (4012 bytes to 1010).
- `TestRewriteOnANestedMultipartAfterRemovalReframesThatSubtree` accepts one optional line ending between
  a rebuilt nested closing marker and the enclosing delimiter, which is the same tolerance the
  part-scoped comparison already had since round 33. Pinning it whole-message while allowing it
  subtree-scoped was inconsistent.

Projection against these ten reports: run 7 goes to zero, runs 1, 2, 3, 4, 5, 8, 9 and 10 to one, run 6
to two.

## Round 35 - the auto-added CTE's position

One unfair, and the reasoning is exact: `TestRewriteOnAnEditedChildSerializesThatChildAlone` pinned the
automatically added Content-Transfer-Encoding AFTER the existing Content-Type. The prompt fixes a
position only for a field `SetHeader` adds; nothing says where an encoding the rewrite adds on its own
goes, and the repository's builder sorts its header keys, which would put it first.

The test now splits that child's own image into its header block and body, requires the body to be
`swapped`, requires exactly two fields, requires the one that is not `Content-Type: text/plain` to be a
Content-Transfer-Encoding naming a writable encoding, and does not care which order they arrive in. The
second child's image stays exact, because that IS a `SetHeader` addition and its position is stated.

Adding no CTE header at all still kills 5 tests, so the requirement is intact - only my choice of where
to put it is gone.

## Round 34 - the last builder-policy pin

The test-quality check raised its one WARNING on the same thing twice over: exact Content-Transfer-Encoding
values that come from the repository's builder policy rather than from the description. Round 33 relaxed
the per-content-type table; two pins were left, and both are gone now.

- `TestRewriteReplacementWithoutCTEPicksAnEncodingThatRoundTrips` asked for 7bit / quoted-printable /
  base64 by content shape. It now asks that a writable encoding be named and that the content round-trip
  byte-exactly, which is the part the description actually promises.
- `TestRewriteOnAnEditedChildSerializesThatChildAlone` pinned the added encoding inside an exact wire
  image. It now reads which writable encoding was added and holds the rest of the image exact.

No test in the suite names a specific transfer encoding for content the description does not name one for.
The alternative was to enumerate the builder's policy in the prompt, which is the enumeration the
difficulty depends on avoiding.

## Round 33 - second solvability cut (the three classes still killing finishing runs)

Batch 3's two complete reports (runs 2 and 3, seven failures each) were the only real evidence left, and
their failures clustered in three places. All three are relaxed now:

| Cut | Runs it was costing | What the test asks now |
|---|---|---|
| the separator after a part-scoped rewrite | 4 across batches 2-3 | the subtree image, with or without the trailing separator (`rwSubtree`) |
| exact line ending against a rebuilt marker (preamble) | 3-4 | the preamble's odd whitespace exactly, minus the ending touching the marker |
| the trailing blank line of an untouched body | 3 | the content survives and reparses; which trailing ending survives is free |

meta dropped the clause explaining that the line ending ahead of the next marker belongs to the marker,
since no test pins it any more: "Asked of a part it writes that part and what lies under it, and no more."
485 words.

Still kept: untouched messages byte for byte (corpus + the untouched family + no-reflow), the empty
multipart's two-marker form, the whole collision family, header edit position/case/repeats/folds,
error atomicity, tree links, encodings round-tripping, repeat-write stability.

Projection against the two complete reports: run 3 goes from 7 failures to about 1 (the no-op delete),
run 2 from 7 to about 4. Combined with round 32 unbinding the runs that died early, that is the best
shot this design has.

## Batch 6 (8 runs) - three runs at exactly one failure

| Run | Failed | What failed |
|---|---|---|
| 1 | 1 | no-op delete marks dirty, extra CRLF in the nested rebuild |
| 2 | 5 | charset added where none was named (x3), built-part CRLF, epilogue collision |
| 3 | 1 | built-part CRLF in an LF-only message |
| 4 | 12 | collision scan sees only children; boundary not synced back; charset; markers; tolerated line |
| 5 | 5 | charset (x3), built-part CRLF, epilogue collision |
| 6 | 8 | charset, empty-multipart opening marker, built-part CRLF, rfc822 round trip, epilogue collision |
| 7 | 1 | message/rfc822 replacement lost its trailing CRLF |
| 8 | 7 | built-part separator and line ending, header-empty block, epilogue collision |

Three runs blocked by one test each, and by three DIFFERENT tests. Frequency across the batch:
built-part line ending 5, charset-where-none-named 4 (worth 3 tests each), epilogue collision 4,
rfc822 round trip 2, no-op delete 1.

## Flakiness gate - repo-owned flaky test excluded (round 47)

Verify Flakiness failed on `TestRandOption`, one flip across 6 runs. It is a repository test, not one of
mine, and it is timing-dependent by construction: `buildEmail` seeds one builder from
`time.Now().UTC().UnixNano()`, sleeps a microsecond, seeds another the same way, and the test asserts the
two messages differ. Under load two seeds can land close enough to produce the same boundary, so it flips.

It cannot be affected by this submission: it exercises MailBuilder and Encode, never parses or rewrites a
message, and solution.patch touches only part.go, boundary.go, edit.go and rewrite.go on the parse and
rewrite paths. 12 runs of it on the UNPATCHED base commit all passed here, which is consistent with a rare
race rather than a defect the patch introduced.

Base mode now runs `go test -v $SKIP`, where SKIP resolves to `-skip TestRandOption` after a probe confirms the toolchain accepts the flag (Go 1.21+; this image is 1.26.3). The probe exists so an older toolchain would run the full suite rather than error on an unknown flag. Base count
606 -> 605. Six consecutive base runs and six new runs are identical, and three base runs on a freshly
patched tree agree.

## Batch 8 - two unfair verdicts caused by round 44's reword (round 46)

Two of three runs came back FAIL_TEST_MISMATCH with agent_blame_unfair true, blocker verifier,
description_clear FALSE, one grading the difficulty "unfair". Both had the same root cause, and it was
mine.

Round 44 answered an FP by weakening the sentence instead of the test: "the encoding building a message
would choose" became "an encoding this package can write". That made two things compliant that the suite
cannot accept - base64 for every CTE-less replacement (run 2) and quoted-printable escaping every octet
(run 1) - because roughly a dozen tests look for the replacement text on the wire, which only works when
the chosen encoding is transparent. Under the reworded prompt those agents were right and my tests were
wrong.

Fixed in both directions this time:

- The sentence is back and says what it means: the builder's choice is used, "so content that needs no
  encoding is written as it is".
- `TestRewriteReplaceAddsTransferEncodingWhenHeaderNamesNone` now enforces exactly that: a plain ASCII
  replacement appears literally, is not base64, is not escaped byte by byte. Choosing base64 for every
  CTE-less replacement now kills 10 tests, so the promise is enforced rather than assumed - which is what
  the round-44 FP was really asking for.

Note the difference from round 34: the per-content-type table (8bit for message/*, base64 for non-text)
is still NOT asserted. What is asserted is only the property the rest of the suite depends on -
transparent encoding for content that needs none.

Run 3's failures stand: InsertBefore accepts a non-child sibling and mutates on the error path, both
explicitly stated. Run 1's three preservation bugs stand too.

## Batch 7 - second pass, FP with two causes (round 44)

A candidate passed again, and the panel unanimously flagged it, on two independent defects. Both were
re-run against the reference: candidate fails, reference passes.

1. A parsed part moved between multiparts (Remove then AppendChild into a differently-bounded parent) was
   written under the marker it ARRIVED with, so the destination did not reparse to the intended tree.
   Nothing in 99 tests ever moved a parsed part between messages. Added
   `TestRewriteMovedPartIsFramedByItsNewParent`: destination reparses to two children in order, carries no
   marker from the source, has three structural markers, and the source is left with one child. Writing a
   moved child under its old marker kills it.
2. A CTE-less Replace chose by byte-scan rather than the builder's per-content-type policy. This one is
   MINE: round 34 relaxed that assertion (it was costing 5 of 12 runs) but left the description still
   promising "the encoding building a message would choose". Description and tests are now aligned the
   other way - the sentence promises an encoding this package can write, which is exactly what the tests
   check.

Suite 99 -> 100. meta 475 -> 474 words.

## Round 43 - the no-op delete's fixture, again

Run 1's sole failure was the no-op delete on a NESTED multipart: their delete marked dirty, the rebuild
ran, and their rebuild adds an extra CRLF where a rebuilt child meets the enclosing marker - a defect
round 36 already ruled tolerable in the nested subtree test. The fixture I introduced in round 36 to
replace the corpus message reintroduced the same coupling. It now uses a child of a flat multipart. The
rule stays asserted on a multipart root with preamble and epilogue, a folded leaf, and a child.

## Round 42 - the built part's own line endings

`TestRewriteAddedPartFollowsTheMessageLineEnding` no longer requires a freshly built part's own header
block to use the message's line ending; it requires the markers around it to, and the added content to
survive and reparse. Rationale: for a part that was built rather than parsed there is nothing preserved,
CRLF is what the MIME standard specifies, and an LF-only message is already non-canonical - so which
ending a fresh block uses is a defensible choice rather than a stated rule. It was also the single
most-failed test of the batch, at 5 of 8.

That converts run 3 (its only failure) to a pass, and drops runs 2, 5 and 8 by one each. The rule still
binds where it is genuinely about preservation: markers, separators, and header edits on a parsed block.

Not relaxed: the charset rule (a real byte-preservation violation, and stated), the epilogue collision
(stated), the rfc822 round trip (stated), the no-op delete (down from 6 of 10 to 1 of 8 after round 36).

## Batch 5 - FIRST PASS, and an FP against it (round 40)

A candidate passed all 98 hidden tests, the full baseline, and the panel's adversarial probing. The
solvability floor is cleared: this problem is solvable.

The FP check then upheld a solo flag from judge-c. The passing implementation drops a header-block line
that begins with a colon when a DIFFERENT field is edited: enmime's readHeaderInternal puts such a line
in rawHeader but not in its field list, and its renderer rebuilds the block from that list whenever any
field changed. Parse "X-Edit: old\n: malformed but tolerated\nX-Keep:  exact\n\nbody", SetHeader
X-Edit, rewrite, and the untouched tolerated line is gone. That is the title requirement failing on a
clean public-API input, and the reference preserves it - verified in my own worktree before writing
anything.

So the environment was missing a discriminator, exactly as the FP rule describes. Added
`TestRewriteHeaderEditKeepsToleratedLines`: a block holding a bare-colon line, a spaced-name line and a
two-space value, checked byte for byte across an untouched rewrite, a replaced field, an added field and
a deleted field. Dropping the bare-colon line on rebuild kills it. Suite 98 -> 99.

The class this covers is broader than the one line: any header-block line the parser tolerates without
reading it as a field has to survive an edit to its neighbours.

## Mutation proofs (kills out of 99 tests)

| # | Natural-but-wrong implementation | Kills |
|---|---|---|
| 1 | decode and re-encode every part | 34 |
| 49 | never regenerate a colliding boundary | 17 |
| 3 | regenerate the boundary without pointing Content-Type at it | 14 |
| 22 | add a Content-Type parameter instead of replacing the one already there | 14 |
| 2 | reuse the parent boundary after replacing content | 12 |
| 7 | collapse a multipart to its single remaining child | 4 |
| 4 | drop the preamble and the epilogue | 3 |
| 5 | normalise every line ending to CRLF | 3 |
| 6 | drop an edited header field and append it at the end | 3 |
| 8 | take the first replacement marker without re-checking | 3 |
| 26 | scan the decoded content rather than the bytes that will be written | 3 |
| 9 | scan only the parts, not the preamble | 2 |
| 10 | drop whatever followed the closing marker on its line | 2 |
| 13 | leave an emptied multipart with only its closing marker | 2 |
| 15 | mark only the edited part on a header edit, not the multiparts above it | 2 |
| 16 | write the caller's spelling rather than the package's canonical field name | 2 |
| 19 | separate a part from the next marker only when it does not already end in a newline | 2 |
| 21 | write the decoded bytes but leave the declared character set alone | 2 |
| 11 | swap the first textual match in Content-Type, not the boundary parameter | 1 |
| 12 | let a named binary encoding fall through and be re-chosen | 1 |
| 17 | accept an unwritable named encoding and quietly re-choose one | 1 |
| 18 | let a delete of an absent field still mark the message edited | 1 |
| 20 | take the separator from the enclosing header rather than from the marker line | 1 |
| 23 | attach the child before checking the named sibling really is a child | 1 |
| 24 | pick the encoding with the text scanner whatever the content type is | 1 |
| 25 | accept any field name | 1 |
| 27 | write every new header line with a carriage return | 1 |
| 28 | match the named transfer encoding without folding case | 1 |
| 29 | take a header value that carries its own line break | 1 |
| 30 | write a Content-Type header without re-reading what the part reports | 2 |
| 31 | find the closing marker's tail under the new boundary, not the arrived one | 1 |
| 32 | split a header block line by line, without keeping continuations with their field | 6 |
| 33 | write a built part with the line ending building a message would use | 1 |
| 34 | leave the breaks base64 and quoted-printable insert as carriage returns | 1 |
| 35 | let a delete on a part with no raw header block do nothing at all | 1 |
| 36 | take a Content-Type the media type parser hands back without a subtype | 1 |
| 37 | leave the removed part pointing at the sibling it sat before | 1 |
| 38 | append behind the first child instead of walking to the tail | 5 |
| 39 | scan for collisions against the arrived boundary rather than the one in hand | 2 |
| 40 | wire Envelope.Rewrite to the existing Encode path | 3 |
| 41 | leave the epilogue out of the regions the collision scan reads | 1 |
| 42 | leave the multipart's own header block out of those regions | 0 (relaxed in round 28; both readings accepted) |
| 43 | refuse an empty header value the way an empty field name is refused | 1 |
| 44 | take a Content-Type that changes whether a part is a multipart | 1 |
| 46 | drop the boundary when a same-kind Content-Type names none | 1 |
| 47 | write the Content-Type header before re-reading it, so a refused value has already landed | 4 |
| 48 | serialize a built part without its `Content` | 8 |
| 45 | keep only the error from Write and ignore the count it returned | 0 (relaxed in round 28; state preservation still pinned) |

## Per-agent table

| Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Approach note |
|---|---|---|---|---|---|---|---|
| _pending_ | | | | | | | |
