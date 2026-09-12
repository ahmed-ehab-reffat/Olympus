# DESIGN.md - enmime-preserving-edits

Repo: https://github.com/jhillyerd/enmime (Go, MIT, 518 stars, default branch `main`).
Base: `0d919cc223e9cb6c2d45d6c653e7a64156006351` (2026-07-21).
Packages under change: root (`part.go`, `boundary.go`) plus two new files.

## 1. Title

Rewrite a parsed message without disturbing what was not edited

## 2. Why this pick is hard rather than transcribable

Nothing in RFC 2045/2046 says anything about *preservation*: the standard defines what a valid
message looks like, not which bytes an editor is allowed to move. So the contract has to be
invented, and knowing MIME does not tell an agent what to build. The difficulty lives in doing it -
retaining raw regions through a parser that currently throws them away, and keeping a rewritten
message consistent when every boundary, encoding and offset depends on every other one.

Today `ReadEnvelope` then `Encode` reorders headers, re-cases them, re-wraps quoted-printable to a
different line length and re-encodes content that was never touched. Issue #305 ("Parser can loose
the original content format", closed 2023, still unfixed) is that gap, reported by a user; issue
#395 asks for control over transfer encoding on the way out. No PR in any state touches either.

## 3. Shape classification

- Shape: **O-Composite-extend**. A new edit + rewrite path is added, but it runs through the same
  `Part` tree, boundary reader and header machinery every existing behaviour uses, so the whole
  envelope/part/builder/encode suite has to stay green.
- Pass-rate target: <= 40% cap, designed for the hard edge.
- Best agent: Orion. Dominant expected verdict: MISSED_REQUIREMENT with a REGRESSION tail.

## 4. Public API surface

Small on purpose, so nothing can be guessed wrong at the API level. As shipped:

- `(*Part).Replace(content []byte) error` - swap a leaf part's decoded content.
- `(*Part).Remove() error` - detach a part from its parent.
- `(*Part).InsertBefore(sibling, child *Part) error` and `(*Part).AppendChild(child *Part) error`.
- `(*Part).SetHeader(name, value string) error` and `(*Part).DeleteHeader(name string) error`.
- `(*Part).Rewrite(w io.Writer) error` and `(*Envelope).Rewrite(w io.Writer) error`.

## 5. Canonical behaviour

- **Untouched means byte identical.** Any part and any header not modified since parsing comes back
  exactly as it arrived: the same transfer encoding, the same line breaks inside encoded content,
  the same header order, the same header case, the same folding, the same encoded words.
- **Touched means freshly encoded** by the rules the package already uses when building a message.
- The bytes before the first boundary and after the closing boundary of a multipart are carried
  through unchanged.
- Rewriting again with nothing changed in between writes the same bytes, even though the first
  rewrite is what settles encodings, charsets and a regenerated boundary.
- Line endings are carried through as they arrived, per part, including a message that mixes them.
  A part built rather than parsed, and the breaks an encoder inserts into a replaced body, follow the
  line ending of the message they join.
- **Boundaries.** A multipart keeps its boundary unless some content the rewrite emits contains it,
  in which case that multipart gets a fresh boundary and the parts under it are re-emitted with it.
  A fresh boundary is chosen so it appears in nothing the rewrite emits.
- **Collapse.** Removing children until one is left leaves the multipart in place; removing the last
  one leaves an empty multipart with its boundary pair and nothing between them.
- Adding a part to a message that is not a multipart is an error, as is removing the root. An
  operation that reports an error leaves the message exactly as it was. A removed part keeps neither
  its parent nor its sibling pointer.
- A header value is written out as given, and a value carrying a line break is refused, so no edit
  can put a second line into a header block.
- A `Content-Type` written through SetHeader is re-read, so the part reports what its header says and
  a multipart is framed with the boundary that header names. One that does not read as a type and a
  subtype is refused, as is one that would change whether a part is a multipart. A same-kind type
  that names no boundary keeps the boundary the part is framed with.
- An edited part is re-encoded with the transfer encoding its own header names; where it names none,
  the encoding the builder would choose is used and a `Content-Transfer-Encoding` header is added.

## 6. Blind-spot pre-empts

- Result ordering -> "the same header order" stated rather than left to the writer.
- Adjacent vs all-positions -> boundary regeneration stated over "anything the rewrite emits".
- Unstated inverse -> the collapse rule states both the one-child and the no-child case.
- Falsy-on-invalid -> the two illegal edits are errors, not silent no-ops.
- Codebase-inferable requirements: 1 (that a freshly encoded part uses the encoding rules the
  builder already applies).

## 7. File footprint

| Action | Path | Current LOC | Raw delta (est) | Reason |
|---|---|---|---|---|
| NEW | `rewrite.go` | - | +190 | the rewrite walk, boundary selection, raw-vs-fresh decision |
| NEW | `edit.go` | - | +268 | the mutators, the edit flags, the surgical header-block edits |
| MODIFY | `part.go` | 519 | +55 | retain the whole message, the raw header block, the raw body and the line ending |
| MODIFY | `boundary.go` | - | +10 | keep the preamble and the first delimiter |

Measured: 658 platform-counter across 4 files, 495 under the reviewer's strip.

## 8. Trap matrix (MEASURED by mutation, not predicted)

Each row was written into a scratch copy of the reference as the natural-but-wrong implementation
and the suite re-run. "Kills" is how many of the 98 tests that mutation breaks. No row is dead.

| # | Natural-but-wrong implementation | Kills |
|---|---|---|
| 1 | decode and re-encode every part | **22** |
| 3 | regenerate the boundary without pointing Content-Type at it | **14** |
| 22 | add a Content-Type parameter instead of replacing the one already there | **14** |
| 2 | reuse the parent boundary after replacing content | **12** |
| 7 | collapse a multipart to its single remaining child | **4** |
| 4 | drop the preamble and the epilogue | **3** |
| 5 | normalise every line ending to CRLF | **3** |
| 6 | drop an edited header field and append it at the end | **3** |
| 8 | take the first replacement marker without re-checking | **3** |
| 26 | scan the decoded content rather than the bytes that will be written | **3** |
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
| 29 | take a header value that carries its own line break | 1 |
| 30 | write a Content-Type header without re-reading what the part reports | 2 |
| 32 | split a header block line by line, without keeping continuations with their field | **6** |
| 31 | find the closing marker's tail under the new boundary, not the arrived one | 1 |
| 33 | write a built part with the line ending building a message would use | 1 |
| 34 | leave the breaks base64 and quoted-printable insert as carriage returns | 1 |
| 35 | let a delete on a part with no raw header block do nothing at all | 1 |
| 36 | take a Content-Type the media type parser hands back without a subtype | 1 |
| 38 | append behind the first child instead of walking to the tail | **5** |
| 40 | wire Envelope.Rewrite to the existing Encode path | **3** |
| 41 | leave the epilogue out of the regions the collision scan reads | 1 |
| 42 | leave the multipart's own header block out of those regions | 1 |
| 43 | refuse an empty header value the way an empty field name is refused | 1 |
| 44 | take a Content-Type that changes whether a part is a multipart | 1 |
| 47 | write the Content-Type header before re-reading it, so a refused value has already landed | **4** |
| 46 | drop the boundary when a same-kind Content-Type names none | 1 |
| 45 | keep only the error from Write and ignore the count it returned | 1 |
| 39 | scan for collisions against the arrived boundary rather than the one in hand | 2 |
| 37 | leave the removed part pointing at the sibling it sat before | 1 |
| 28 | match the named transfer encoding without folding case | 1 |

Trap 1 is the architectural wall: an implementation that does not retain raw regions fails 34 of the
98 tests. Traps 2, 3, 8, 9, 11, 22 and 26 are interdependent with it - raw retention is what makes 1
pass, and it is exactly what makes the rest possible to get wrong, because a retained region is only
valid under the boundary it was parsed with, and the boundary only holds if the header agrees.

One trap was retired rather than kept alive artificially. An earlier round scanned a part's own
header for the replacement marker; once the collision rule was narrowed to markers that open a line,
that scan became unnecessary, because a header block is read before any delimiter scanning happens.
The scan was removed from the reference and the trap dropped, rather than propped up with a fixture
that only fails under an over-strict rule.

## 9. Test outline

Path: `rewritetest/rewrite_<hash>_test.go`, its own package importing enmime, so a missing API on
base is a build failure in that package alone and cannot take the main package down. Uses the
`testdata/mail` corpus the repo already ships plus inline fixtures. 98 tests delivered.

Buckets: untouched round trip over the whole corpus; each mutator in isolation; nested multipart;
boundary collision and regeneration; preamble/epilogue; mixed line endings; header order/case/
folding/encoded words; collapse cases; the two error cases; re-read of a rewritten message.

## 10. Tier + category

Olympus, feature-request. Demand signals: issue #305 (closed, unfixed, no maintainer comment) and
issue #395 (open).

## 11. Predicted pass rate

0-20%. There is no spec to transcribe, the contract is statable in full without revealing that the
parser has to start retaining raw regions, and the existing envelope/part/builder/encode suites
police every other behaviour.

## 12. Quality gate

- [x] Environment Quality pre-verified: `go build ./...` + `go test ./...` clean offline in
      `olympus-base-go`, all 10 packages
- [x] Cold: 19 commits in 12 months, mostly dependency bumps; #305 open-as-a-gap since 2023
- [x] Exclusivity: no PR in any state implements editing, preservation or round tripping
- [x] Maintainer philosophy: #305 was closed without a decline comment; #395 asks for more control
      over encoding on the way out, so this is aligned rather than contrary
- [x] Licence MIT, 518 stars, last commit 2026-07-21
- [x] Repo quota: no prior submission of ours; no MIME or email feature anywhere in the corpus
- [x] Exact signatures pinned against `part.go`
- [x] LOC floor measured: 658 platform-counter, 495 reviewer-effective, across 4 files
- [x] Traps mutation-proven: 45 of 47 kill; two were relaxed after batch 1 (see eval-results.md)
- [x] Flakiness 3x: identical every run
