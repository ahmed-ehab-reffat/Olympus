# barcode-qr-decoder — Feedback / Strategy Log

## Summary
Olympus, feature-request. Repo: boombuler/barcode (Go, MIT, **1556 stars** verified >= 500 floor,
active). Feature: a **QR-code decoder** for the `qr` package (the repo is entirely encode-only;
`grep "func Decode"` = 0 hits, two closed user feature-requests, no PR). Shape:
O-Algorithm-correctness (Reed-Solomon GF(256) decoding + BCH format decode) stacked with masking/
geometry, block de-interleaving, and multi-mode bitstream parsing. Target ~8-12% pass.

## Why this repo (redo after 500-star violation)
- PREVIOUS attempt used arran4/golang-ical (406 stars) -> DISQUALIFIED by the hard >=500 star gate;
  shelved to _shelved/. This repo clears the floor decisively at 1556 stars (verified via GitHub API
  and LICENSE=MIT).
- Fresh: boombuler/barcode never used locally; QR decoding is a brand-new domain (no barcode/QR/
  Reed-Solomon problem in approved-problems/ or problems/).

## Oracle strategy (self-oracle, no external tools needed)
- Round-trip against the repo's OWN encoder: `Encode(s, level, mode)` -> `Decode(img)` MUST equal s,
  across versions/levels/masks/modes. This is a perfect in-repo oracle.
- Reed-Solomon surface: corrupt up to t modules of a valid symbol, assert Decode still recovers s
  (t = ErrorCorrectionCodewordsPerBlock/2 per block). Naive decoders that skip ECC pass clean
  round-trips but FAIL corrupted ones -> the difficulty discriminator.
- Cross-language oracle (zxing/Java) available as a backstop but not required.

## Reusable encoder internals (decoder inverts these)
- versionInfos table (block structure per version x level) -> de-interleave.
- formatInfos[level][mask] 15-bit patterns -> format BCH decode by nearest-Hamming match.
- setMasked (8 mask formulas, self-inverse) -> unmask.
- iterateModules (zigzag data order) + drawFinder/Alignment/timing/dark -> rebuild `occupied`, read data.
- charCountBits, numeric/alphanumeric/unicode mode tables -> bitstream parse.
- utils.GaloisField(285,256,0) + utils.GFPoly -> RS decoder (syndromes/Berlekamp-Massey/Chien/Forney).

## Scope
- Decode modes the encoder can PRODUCE: numeric, alphanumeric, byte(UTF-8). (No Kanji: encoder has none.)
- Versions 1-40, EC levels L/M/Q/H, all 8 masks. Input: unscaled 1px/module image (as Encode returns).

## Attempt history
| Round | Change | Result |
| ----- | ------ | ------ |
| 0 | Repo re-selected (>=500 star), gap + no-PR confirmed | done |
| 0 | Decoder implemented (5 files) + fuzzed vs self-oracle | 0 failures |
| 1 | Full-version fuzz + hardening + AI-review response | 0 failures / all checks addressed |

## Round 1 -- ensure-hard + AI review response
FULL-VERSION VALIDATION (was a gap: earlier fuzz used short content, only ~v7): fuzzed round-trip
across ALL versions 1-39 (0 fails / 3,000 cases) and multi-block corrupt-recover (0 fails / 1,471).
Two detection bugs found + fixed at high versions: (a) dim from finder span could snap wrong ->
snap dim to nearest valid QR dimension with a tolerance bound; (b) one finder mis-clustered by a
neighbouring data pattern drifted the lattice -> use the MEDIAN module-size estimate and sample from
the clean top-left origin (immune to one bad finder).

HARDENING (ensure hard): the encoder internals are reusable in-package, so most inversions are easy
and the genuine difficulty concentrates in surfaces the encoder does NOT provide. Added discriminators
on exactly those: v13 numeric (char-count 12-bit width), v11 alphanumeric (8 blocks / 2 groups) and
v19 byte (14 blocks / 2 groups) multi-group de-interleave, and an uncorrectable-damage error case
(18 spread module flips -> RS must detect and error, catching agents that skip post-correction
syndrome verification and silently miscorrect). Difficulty now requires getting ALL of: finder
detection (novel; NOT in the encoder; 4 subtle geometry bugs hit during authoring), GF(256) RS
decode, multi-group de-interleave, version-dependent char counts, dual format-copy fallback, and
mode bitstream parsing -- right simultaneously on 46 exact-output tests. Independent miss-rates
compound -> O-Algorithm-correctness ~8-12% band.

AI REVIEW RESPONSE (round-1 checks):
- Alignment FAILED (return type): meta now states the exact signature
  `Decode(img image.Image) (*DecodeResult, error)` AND the DecodeResult fields with types
  (Content string, Version byte, Level ErrorCorrectionLevel, Mask int) -- statically-typed hidden-
  signature pre-empt.
- Tests-cover-behavior WARNING: added TestQRDecode_uncorrectableDamageErrors (coverage suggestion
  ADDED, per the always-add-coverage rule).
- Necessary-information request_changes (2 HIGH + 3 MEDIUM): COMPLIED by trimming pure-HOW clauses
  that no test pins (finder 1:1:3:1:1 ratio, module-size-from-centres, interleaved read order,
  version-from-dimension, RS half-bound). Verified none orphans a test (tests assert outputs, not
  HOW), so no hidden requirements are created. Kept "version-dependent character counts" (a MEDIUM,
  non-blocking) because the new v13/v19 discriminator tests target it -- alignment > optional style.
  No bypass needed: removing the HIGH clauses satisfies the check without breaking alignment.

Re-validated after all changes: 46/46 new tests pass; base suite (57) no regressions; effective LOC
517/5 files; meta 157 words ASCII; 4-cell Docker matrix green; F2P node IDs aligned; patches apply
both orders + reverse.

## Round 2 -- Test Fairness FAIL + necessary-info round-2
TEST FAIRNESS FAIL (2 of 59 unfair): the two hard-coded exact mask literals (Mask==3, Mask==6) over-
pinned an encoder penalty-selection artifact not stated in prompt or repo. FIXED by dropping the exact
mask asserts from TestQRDecode_numericShortV1 and TestQRDecode_alphaNumericHelloWorld (kept content +
version + level, all ruled fair). Mask coverage is retained fairly by TestQRDecode_maskRecoveredInRange
(Mask in 0..7). The re-run fairness report ruled ALL version asserts fair ("repo-discoverable" from the
capacity tables in versioninfo.go) and RS/format/scaling/quiet-zone behaviors fair -- so versions stay
(they are the char-count / multi-group discriminators).

NECESSARY-INFO round-2 (3 HIGH): the flagged clauses (de-interleave+RS, segment parsing+char-counts,
format nearest-pattern selection) all describe TESTED behavior -- deleting them would create hidden
requirements and BREAK the Test Fairness that the same reviewer just confirmed (it cited those exact
prompt clauses as the fairness basis). Resolved WITHOUT bypass by rewording from algorithmic STEPS to
BEHAVIOR: "de-interleaved into blocks ... Reed-Solomon" -> "Damaged modules are corrected up to the
symbol's error-correction capacity; beyond that ... an error"; "parsed into segments using version-
dependent character counts" -> "content may be numeric, alphanumeric, or byte (UTF-8) ... across all
versions and levels"; "matching each ... nearest level-and-mask pattern and keeping the better copy"
-> "reads both copies ... and uses whichever is still intact". Every tested behavior remains described
(fairness preserved); the algorithmic HOW the check objected to is gone. meta now 152 words.

COVERAGE SUGGESTIONS (advisory, all 3 skipped with cause):
- version-info robustness: adding a "corrupt version-info, still decode" test would be UNFAIR -- it
  penalizes a valid implementation that derives version from the version-information blocks, which the
  description deliberately leaves open (the necessary-info check itself said any method is acceptable).
- format-copy tie-break (both copies damaged, different Hamming): both within BCH capacity decode to the
  same (level,mask) -> no observable discriminator beyond the existing recoversFromSecondFormatCopy test;
  also would re-pin the selection algorithm just abstracted out of meta.
- mixed-mode segments: not producible by the repo's single-segment Encode and not a claimed behavior;
  would need a fragile hand-built matrix. Out of scope.

Re-validated: 46/46 pass; base 57 no regressions; LOC 517; meta 152 words ASCII; matrix green; F2P
aligned; patches apply both orders + reverse; zero remaining exact-mask assertions.

## Round 3 -- description polish (necessary-info HIGH + Description-Quality FAIL) + version WARNING
Description checks converged to filler/over-broad phrasing. COMPLIED (no bypass; none orphan a test):
- Dropped the "encodes ... but cannot read them back" preamble (filler).
- Removed "by its three finder patterns" (detection HOW) -- kept "locates the symbol ... tolerating
  quiet zone, scale, and other content around it" (the locatesSymbolInLargerCanvas behavior).
- Removed the illustrative tail "so a symbol whose first copy is damaged still decodes" and the
  redundant "DecodeResult reflects the symbol as it was encoded" sentence.
- Softened "across all versions" -> "across many versions and all error-correction levels" (accurate:
  tests sample versions but cover all four levels). meta now 123 words.

VERSION-COUPLING WARNING (recurring, non-blocking): relaxed ALL exact `Version == N` asserts. Kept
content + level everywhere; kept versionGrowsWithData (relational, ruled fair). The three high-version
discriminators now assert content + a relational lower bound (`Version >= 10` char-count-12 regime;
`Version >= 8` multi-group regime). DIFFICULTY IS PRESERVED: decoding the *content* correctly at v13/
v19 already forces correct version-dependent char-count widths and multi-group de-interleaving -- the
exact version number was redundant for the discriminator, only fragile. Zero exact `Version ==`/`!=`
asserts remain.

Re-validated: 46/46 pass; base 57 no regressions; LOC 517 (solution untouched); meta 123 words ASCII;
4-cell matrix green; F2P aligned; patches apply both orders + reverse.

## Round 4 -- quality WARNING flipped direction (asked to RE-ADD precise Mask/Version)
This WARNING (non-blocking; check is approvable at 3 OK + 1 WARNING) directly conflicts with the
earlier BLOCKING Test Fairness FAIL (which ruled exact mask UNFAIR) and the earlier version-coupling
WARNING. Resolved by using the approach BOTH checkers suggested -- "infer the expected value from the
encoded image, not hardcoded constants":
- VERSION: added TestQRDecode_versionMatchesDimension, asserting res.Version equals the version implied
  by the image's module DIMENSION ((dim-21)/4+1). This is precise (satisfies this WARNING) AND fair
  (derived from the rendered image, not coupled to the encoder's capacity/selection strategy -- the
  other checker's objection). Uses an unscaled symbol so bounds width == module dim.
- MASK: NOT re-added. There is no oracle for the expected mask other than decoding itself; Test
  Fairness explicitly ruled a hardcoded mask literal unfair. TestQRDecode_maskRecoveredInRange (0..7)
  is the fair maximum. Documented here so a human reviewer sees the deliberate fairness>coverage call.
47/47 pass; matrix green; F2P aligned.

## Round 5 -- reviewer coverage suggestions (3) ADDED
Per the always-add-coverage rule, all three added (fair form, derive expectations from the image):
1. Exact metadata at v>=7: the v10/v26/v27 char-count-boundary tests assert exact Version via the
   module DIMENSION ((dim-21)/4+1) -- precise + fair, at versions where version-info bits are present.
   Exact MASK still NOT asserted: there is no oracle for the expected mask except decoding itself, so a
   hardcoded literal remains unfair (as Test Fairness ruled). maskRecoveredInRange (0..7) is the fair max.
2. Version-boundary payloads: added TestQRDecode_charCountBoundaryV9 (462 numeric digits), V10 (553),
   V26 (3058), V27 (3284) -- these straddle the two numeric char-count-width transitions in
   versioninfo.go (10->12 bits at v10, 12->14 bits at v27). Content round-trip forces the correct
   width; version-via-dimension pins the version fairly.
3. High-version error correction: added TestQRDecode_multiBlockCorrectsErrors -- a v10, Q-level,
   8-block (2-group) symbol with 6 corrupted data modules, verifying multi-block de-interleave + RS
   correction beyond the v1/scaled-v1 cases.
Now 52 tests. Re-validated: 52/52 pass; base 57 no regressions; LOC 517 (solution untouched);
4-cell matrix green; F2P aligned; patches apply both orders + reverse.

## HUMAN REVIEWER revision (Beasttt Opp) -- 6 points, ALL fixed (agents already evaluated, so
## no test FUNCTION renamed/deleted; only bodies modified + new tests added)
Tests:
- T4 exact Mask: repurposed TestQRDecode_maskRecoveredInRange to assert res.Mask == 0 exactly for the
  fixed "MASK CHECK 42"/M/AlphaNumeric symbol (deterministic at BASE). NOTE: an AI Test-Fairness pass
  earlier called a hardcoded mask literal "unfair"; the HUMAN reviewer explicitly requested exact-mask
  coverage, and the human reviewer is the binding authority -- so the exact assert is in, by request.
- T4 format-copy fallback both directions: added TestQRDecode_recoversFromFirstFormatCopy (corrupts
  only the SECOND copy, asserts recovery from the first) to mirror recoversFromSecondFormatCopy.
- T7 helper name collision (build-fairness): prefixed EVERY test helper/var with qrdec* (qrdecEncode,
  qrdecDecode, qrdecGrayCopy, qrdecFlipModules, qrdecWantContent, qrdecWithQuietZone,
  qrdecNumericPayload, qrdecV1DataModules, qrdecFormatModules, qrdecV1FormatModulesCopy2,
  qrdecV1SpreadDataModules) so a solver's own untagged _test.go declaring a natural name like
  mustEncode cannot trigger a redeclaration build failure for the tagged suite.
- T4 zero-area panic: added TestQRDecode_zeroAreaImageErrors (Rect 0x0, 0x100, 100x0 -> non-nil error,
  no panic). The reference returns "could not find three finder patterns" on all three (verified).
Solution:
- S2 staticcheck SA4006 (+ ineffassign) in median3: rewrote as
  math.Max(math.Min(a,b), math.Min(math.Max(a,b),c)) -- no dead stores. Installed and ran the repo's
  lint set (staticcheck/errcheck/ineffassign/govet) on the 5 solution files AND the tagged test file:
  all CLEAN.
- S4 over-documentation: stripped doc comments from all new UNEXPORTED helpers to match the qr
  package convention (splitToBlocks/render/setMasked/etc. carry none); kept doc comments only on the
  exported Decode and DecodeResult.
Re-validated: 54/54 new tests pass; base 57 no regressions; effective LOC 511/5 files; staticcheck +
gofmt clean (solution + test); 4-cell matrix green (base 57 PASS / new 54); F2P node IDs aligned;
patches apply both orders + reverse.

## Round: Test Fairness FAIL (1/54) -- exact-mask conflict resolved with a FAIR oracle
The AI Test Fairness pass flagged exactly one test: the exact `Mask == 0` literal in
TestQRDecode_maskRecoveredInRange as "unfair value-pinning" (no repo/prompt basis for that specific
value). The AI is right AND the human reviewer's intent (verify mask CORRECTNESS, not just range) is
right -- these seemed to conflict. Resolved by satisfying both: the test now derives the expected mask
from the SYMBOL'S OWN format-info bits via the repo's own formatInfos table (qrdecExpectedMask reads the
15 format modules from the image and matches them against formatInfos[level][mask], the base-repo table
in encoder.go), then asserts Decode's Mask equals it. This is:
  - FAIR: the expected value is derived from the rendered image + repo-visible table, not hardcoded
    (analogous to the accepted versionMatchesDimension test); the AI's "no repo basis for value 0"
    objection no longer applies.
  - STRONG (human's intent): a decoder that reports a wrong/constant mask fails, since the reported
    Mask must equal the mask independently read from the image.
The helper uses the base repo's unexported formatInfos (available in package qr), independent of the
agent's Decode.

Also added the 2 advisory coverage suggestions (fair):
- TestQRDecode_byteCharCountBoundaryV10: 231-byte payload -> v10, probing the byte-mode char-count
  width change (8->16 bits) at version 10 (mirrors the numeric V9/V10 boundary tests).
- TestQRDecode_decodesFromNonZeroBounds: decodes an image whose Bounds().Min is (7,7), since Decode
  accepts any image.Image; the reference handles absolute coordinates (verified).

Now 56 tests. Re-validated: 56/56 pass; base 57 no regressions; effective LOC 511; staticcheck+gofmt
clean (solution+test); 4-cell matrix green (base 57 / new 56); F2P aligned; patches apply both orders.

## Validation (Step 4/6)
- Reference passes all 42 new tests; base repo suite (57 nodes) passes with no regressions.
- Fuzz vs the encoder self-oracle: 0 mismatches across 4,000 round-trips (numeric/alnum/byte x L/M/Q/H,
  versions 1..~7) + 1,500 corrupt-and-recover (flip up to ecc/2 modules per block) + 1,500 detection
  cases (random integer scale + quiet zone + placement in a larger canvas).
- Bugs found & fixed by fuzzing: (1) repo's GaloisField.Divide negative-modulo panic -> divide via
  Multiply(a,Invers(b)); (2) finder horizontal-centre off-by-one (double-subtracted the 5th run);
  (3) vertical-centre found the run bottom not midpoint -> expand run both ways; (4) false-positive
  finders from data -> corner-selection (pick the 3 forming the L: equal, perpendicular arms).
- 4-cell Docker matrix (offline, --user 1000:1000): base PASS/new FAIL without solution (synth per-test
  nodes), base PASS/new PASS with solution; F2P node IDs aligned. Patches apply both orders + reverse.
- Effective LOC: 508 human-effective / 781 raw across 5 files.

## Orthogonal surfaces stacked (difficulty compounding, all documented)
1. GF(256) Reed-Solomon block decode (syndromes/Berlekamp-Massey/Chien/Forney).
2. BCH format-info decode with TWO copies + nearest-pattern fallback.
3. Finder-pattern detection (1:1:3:1:1 ratio + corner-selection) with scale/quiet-zone tolerance.
4. Block de-interleave per version table + multi-mode bitstream parse (numeric/alnum/byte, version-
   dependent char counts).

## Easiness red-team (all "too-easy" flags negative)
- Single-file shim / verbatim-meta transcription pass? No -- correct output requires GF(256) RS, BCH
  format decode, finder geometry, de-interleave tables, and mode-aware bitstream parsing.
- 50-line stub pass >half? No. A naive decoder that omits the hard surfaces fails, at minimum, the 5
  corrupt-recover + 2 format-copy + 4 scaled/quiet-zone + 1 canvas + 1 no-finder = 13 tests (ceiling
  ~29/42), and getting the base round-trip path (module traversal order, de-interleave, format decode)
  exactly right is itself where agents botch it -- so the realistic naive pass sits well below that.
  A full naive-decoder re-implementation was judged disproportionate; the empirical Nova/Orion runs are
  the binding difficulty/solvability gate. Solvability is proven by the reference (42/42).
- Tests span 12+ distinct behaviours (3 modes x versions x levels x masks, RS, format fallback,
  scaling, quiet zone, canvas location, error cases) -- not variants of one behaviour.

## Why this is not a duplicate
No barcode / QR / Reed-Solomon / error-correction / image-decode problem exists in
Olympus/approved-problems/feature-request/ or problems/. boombuler/barcode is a fresh repo, first use
locally. Closest shapes are pest-dispatch (O-Algorithm-correctness) and goja-using (O-Composite-add) --
shape only, not feature. Distinct repo, distinct domain/subsystem.

## MANAGER REVISION (Mohammed Siddiq, review reverted) -- file-count floor
BINDING ISSUE: Olympus requires the MEDIAN of meaningful touched files across PASSING agent solutions
to be >= 2. Passing Nova_6 put all production code in one file (qr/decoder.go); Nova_2 used 2 -> median
1.5 < 2. Go does NOT enforce file splits within a package, so the only robust fix is to make the feature
span TWO PACKAGES (which forces >= 2 files, uncrammable).

FIX -- add a package-level entry point via the registry pattern (mirrors Go's image.Decode /
image.RegisterFormat, and fits the repo per issue #38 "contributor reader code accepted"):
- NEW root file decode.go (package barcode): DecoderFunc type + RegisterDecoder + Decode(img) that
  tries registered decoders and returns a barcode.Barcode.
- NEW qr/register.go: a decodedQR type implementing barcode.Barcode (embeds image.Image + Content +
  Metadata) and an init() that registers the qr decoder with barcode.Decode.
This split is ARCHITECTURALLY FORCED: barcode.Decode must live in the root package, which cannot import
qr (qr imports barcode -> cycle); the decode logic must live in qr (it needs qr's unexported tables:
versionInfos, formatInfos, iterateModules). And qr.Decode itself must stay in qr for the 55 existing
qr-package tests. So every passing solution now touches >= 2 files across >= 2 packages -> median >= 2.
Added 2 tests (TestQRDecode_barcodePackageDecode, ...ErrorsOnNonBarcode) that exercise barcode.Decode,
so an agent must implement the root entry + registration to pass.

ALSO fixed: the misleading Decode doc comment ("unscaled image") -> now "locating the symbol by its
finder patterns and tolerating a surrounding quiet zone and integer pixel scaling." Repo-alignment
concern (issues #17/#60 creation-only vs #38 reader-accepted) addressed by the package-level reader API.

Solution now 7 files / 2 packages, effective LOC 541. Re-validated: 57/57 new tests pass; base suite
(whole repo, incl root barcode + all extensions) no regressions; gofmt+staticcheck+vet clean across all
new files; 4-cell matrix green (base 57 / new 57); F2P aligned; patches apply both orders + reverse.
meta 169 words ASCII (now documents barcode.Decode).

## necessary-info round (post-barcode.Decode addition) -- meta trimmed, alignment preserved
The check re-fired because my barcode.Decode sentence added detail (the human manager had already marked
Problem Description 3/3 Clean on the prior meta). Complied without breaking Test Fairness -- every trimmed
clause is inferable or repo-discoverable, so no test is orphaned:
- HIGH: dropped the barcode.Decode dispatch/return-shape detail -> kept only "registers a decoder with
  barcode.Decode, which returns the read symbol as a barcode.Barcode". The barcodePackageDecode asserts
  (Content == data, Metadata().CodeKind == TypeQR) are repo-discoverable (the encoder's Barcode already
  follows exactly that Content/Metadata convention), so they stay fair.
- HIGH: folded the standalone error sentence into the correction sentence ("damage beyond that capacity,
  an unreadable format, or an absent symbol are reported as an error"); the 6 error tests still trace to
  it, and barcode.Decode-errors-on-non-barcode is inferable from a dispatcher + the error return.
- MEDIUM/LOW: removed "and other content around it" (implied by "locates the symbol within the image" ->
  locatesSymbolInLargerCanvas still traces), "across many versions and all levels" (covered by returning
  Version/Level), and the redundant opening line.
meta now 109 words ASCII. Meta-only change; solution/tests/matrix unchanged (7 files/2 packages, 57/57,
matrix green, F2P aligned).

## De-trap 2 (0%-trap: same-7-tests universal miss) -- Jul 13
locatesSymbolInLargerCanvas required ignoring an off-symbol dark blob, but meta had trimmed the "other
content around it" clause -> unfair hidden requirement + a finder-vs-bbox surface stacked on RS that broke
the 2/10 floor. Relaxed the test to match meta (blob removed; offset-in-white-canvas kept). RS tests kept.
51 tests, matrix green, F2P aligned. Why not document instead of relax: re-adding "other content" re-grows
the trimmed word count AND keeps the stacked surface -> solvability (absolute) wins, so relax.

## necessary-information HIGH (request_changes) -- Jul 13
Check flagged 3 HIGH clauses in the integration sentence as inferable/redundant. Complied (not bypassed)
because they ARE inferable and the check deliberately LEFT the one non-obvious tested value unflagged:
  removed: "barcode.Decode returns the QR symbol as a barcode.Barcode" (implied by RegisterDecoder sig),
           "Content() is the decoded text" (obvious accessor), "errors when no decoder matches" (only
           sensible design; qr-level absent-symbol error still stated).
  kept:    "registers with barcode.RegisterDecoder" + "CodeKind barcode.TypeQR from Metadata()" -- the two
           bits that caused the interface-puzzle budget drain DE-TRAP 3 fixed, so solvability relief holds.
2 MEDIUM (optional) KEPT: modes line backs byteUtf8Multibyte/alphaNumeric*/multiGroup* tests; error line
backs uncorrectable/corruptBothFormatCopies/invalidDimension/noFinder/nonSquare/tooSmall/zeroArea tests --
removing either = Test Fairness violation (tested behavior undescribed). Meta 148->121 words, ASCII clean.
Solution + tests unchanged; patches unaffected (meta is not in any patch).

## FAIL_TEST_MISMATCH: under-specified barcode.Decode signature -- Jul 13 (agentBlameUnfair=true)
Nova declared barcode.Decode(kind,img)/RegisterDecoder(kind,decoder); hidden test compiles against
barcode.Decode(img). Base repo has NO barcode.Decode (creation-only) so the arg shape was a free design
choice the prompt never pinned -> all hidden tests failed to BUILD (not to decode). Evaluator itself set
agentBlameUnfair=true, environmentBlocker.type=verifier => zero difficulty signal + unfair. This is the
statically-typed-signature trap (a hidden test won't compile against the wrong shape).
FIX (required, not a bypass): meta now pins the exact signature
"Add a package-level barcode.Decode(img image.Image) (barcode.Barcode, error) ... register with
barcode.RegisterDecoder; the returned QR barcode.Barcode reports CodeKind barcode.TypeQR". Matches solution
decode.go func Decode(img image.Image) (Barcode, error) exactly. Meta 121->133 words, ASCII clean. This ALSO
helps solvability: removes a compile-fail failure mode that was knocking out otherwise-RS-capable runs on top
of the RS wall. Does NOT conflict with the necessary-info trim (that removed inferable semantics; an exact
compile-critical signature agents demonstrably guess wrong is required, and re-flagging is bypass-eligible).
Contest filed for this run (verifier-convention artifact, now fixed); needs re-run on the pinned-signature meta.
