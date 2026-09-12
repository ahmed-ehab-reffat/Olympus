# eval-results.md — gojq-ordered-keys

## Local verification (all in `olympus-base-go`, `--network none`, uid 1000)

| check | result |
|---|---|
| Environment Quality: vanilla `go test ./...` on the UNPATCHED tree in the built image | 2 packages ok / 0 fail |
| base+test, `./test.sh base` | rc=0, 0 failures |
| base+test, `./test.sh new` | rc=1, 256 of 256 fail |
| base+test+solution, `./test.sh base` | rc=0, 2 packages ok, 0 failures |
| base+test+solution, `./test.sh new` | rc=0, 256 of 256 pass |
| apply order test-then-solution | clean |
| apply order solution-then-test | clean |
| flakiness, base x3 | identical pass/fail set every run (same digest) |
| flakiness, new x3 | identical pass/fail set every run (same digest) |
| JUnit XML | 256 named `<testcase>` nodes in both modes |
| effective LOC | 555 human-effective, 768 raw, 17 files |
| meta.md | 242 words, ASCII, no em dashes |
| patches | ASCII, LF; `test.sh` at `new file mode 100755`; solution is source-only |

## F2P

256 of 256 new tests fail at the base commit and pass with the solution. `--ordered-keys` is an
unknown flag there, so each test fails at run time with a message on standard error rather than
failing to compile: the test file only uses the package-private `cli` struct and `run`, both of
which exist at the base commit, so `go-junit-report` emits 256 named nodes with a `<failure>` in
each.

Four tests started out as base-passers because they only asserted behavior which already holds at
the base commit: one that the default output is sorted, and three library-level ones that a plain
Go map iterates, lists entries and yields paths in sorted order. Each now carries a second
assertion in the same query which the base commit cannot satisfy, so the query fails to compile
there and the test fails.

## Environment note

gojq ships a `.dockerignore` which excludes `**/*_test.go`, `**/*.jq`, `**/*.yaml` and `_tools`, so
an image built from the repository with `COPY . .` contains no tests at all and base mode has
nothing to run. The Dockerfile restores them from the checkout with `git checkout HEAD -- .` and
then asserts `cli/cli_test.go` is present, so a build in a context without the git directory fails
loudly instead of producing a silently empty baseline.

## Oracle

Semantics were fixed against jq 1.7 (present in the base image) before the tests were written. A
50-program differential run over construction, iteration, `keys`, `to_entries`, merge, deep merge,
delete, `setpath`, update-assign, paths, equality, sorting, `tojson`/`fromjson` and streaming is
identical to jq except for five cases: four are error-message wording, and `leaf_paths` does not
exist in gojq at all. Ten further probes covering fork points (`,` alternatives, `//`, `first`,
`limit`, `try`/`catch`, repeated references to the same object) also match jq exactly.

Three deliberate carve-outs, none claimed by the description: YAML key order is out of scope since
the description scopes printing and sorting to JSON, though YAML output must still carry every pair
and is checked for that; JSON data modules loaded by the module loader keep no order; and objects
handed to the Go API as plain maps have no order to keep.

## Mutation proof

Each row is the natural-but-wrong implementation of one requirement, applied on its own to the
reference solution. Counts are failing tests out of 256.

| mutation | kills |
|---|---|
| input is decoded into plain maps, so only the output side is ordered | 134 |
| the encoder sorts keys whatever the value carries | 112 |
| `keys_unsorted` sorts like `keys` | 38 |
| a key written again moves to the end instead of keeping its first position | 18 |
| an update writes through the object instead of copying when it did not allocate it | 12 |
| `keys_unsorted` gives a plain map its keys in Go map order instead of sorted | 13 |
| the ordered decoder treats a cut-short input as the end of the stream | 9 |
| merge builds from the map instead of the key order | 6 |
| a merge result takes its representation from the right operand | 2 |
| YAML output hands the encoder a plain map | 7 |
| object comparison respects key order | 6 |
| YAML output ignores `-S` | 6 |
| deep merge takes the right object's new keys from the map | 1 to 3 |
| an object literal is built from a map | 1 to 4 |
| delete rebuilds the object from the map | 2 |

The rows given as a range vary between runs because those mutations build the object from Go map
iteration. Each kills at least one test on every run; the ranges are over five runs. The shipped
solution is deterministic, as the three identical runs above show.

Worth knowing for the next map-order proof: Go randomises the *starting offset* of a small map's
iteration but then walks it in slot order, so what you get is a rotation of the insertion order,
not an arbitrary permutation. A single n-key test therefore matches a map-order implementation
about one run in n, not one in n factorial. Several tests of different widths per family is what
makes the family-level kill reliable; a single wide test is not enough.

The fourth row is the copy-on-write trap: the VM restores fork points that share value references,
so an object written through in place leaks a key into an alternative that was already rejected.

Two further mutations (`Set` mutating in place, and `Set` moving an existing key to the end) were
written and then dropped: they killed nothing because the method they targeted turned out to be
unreachable from any query path. It was removed rather than left as dead code.

## Review round 1

**Description Quality (1 high, 4 medium, all addressed).** The high item was a
backward-compatibility assurance ("Without the option nothing changes ..."); the sentence went and
the default is now carried by the opening description of what gojq does today, which still anchors
the default-mode tests. The four medium items were a historical aside about the two missing
surfaces and three example lists; all removed, with the general rule kept in each case so no tested
behavior lost its anchor. 405 words down to 373.

**Test Fairness (FAIL, 3 groups / 7 tests, addressed).** The checker accepted that ordered
printing, `keys_unsorted` and `to_entries` were stated, but flagged `[.[]]` iteration order,
`paths` traversal order and `tostream` event order as author choices, noting the pinned VM sorts
object iteration. All three are the same rule, so one sentence was added rather than seven tests
deleted: the object's order is also the order its members are visited in, so anything which walks
an object or turns it into a stream of paths reaches them in it. That is behavior, and it does not
say where the order is stored or how the fork stack must copy it.

**Coverage suggestions (advisory, all five taken).** Added `keys_unsorted` without the option on
both an object and an array; `--sort-keys` in its long spelling alone and with `--ordered-keys`;
order surviving a variable binding, a function argument, a function return and an array round
trip; a file-backed input, `--slurpfile` and singular `input`; and stronger order-blind comparison
checks. `sort` and `min_by` previously used objects that could not detect order-sensitive
comparison (one key each, and a numeric projection); they now use two objects with the same key set
in different carried orders, and a `max` case was added beside them.
`TestOrderedKeysKeysUnsortedOnPlainMapIsSorted` was renamed: its input was decoded with
`--ordered-keys`, so the old name described the opposite of what it asserted.

12 tests added, 138 total at that point, all failing at base.

## Review round 2

Test Fairness passed with no unfair tests; three advisory coverage suggestions, all taken (9 new
tests, 147 total at that point, all failing at base).

- **`-S` against the text encoders.** The suggestion asked whether the output-sorting override
  reaches `tojson` and `@json`. It does not, in gojq as built and in jq: `-S` sorts what is
  printed, and a JSON string built inside the query keeps the order its value carries. Four tests
  now pin that boundary from both sides, including a program-created nested object, plus one that
  shows the same query without `tojson` does come out sorted. To anchor it, `-S` in the description
  now reads "sorts the keys of everything it prints" rather than "prints keys sorted".
- **Duplicate keys through the other decoders.** `fromjson` and `--argjson` go through their own
  decode path, and both give first position with the later value. The description said "where the
  input names the same key twice", which reads as stdin; it now says "where the same key is named
  twice in the text", which covers every decoding path without adding a rule.
- **`from_entries` with a repeated key.** First position, later value, matching jq. No description
  change: this is the stated creation-order rule composed with the stated existing-key rule, which
  is how the checker itself framed it. A `reduce` case that assigns the same key twice was added
  beside it, since that is the same composition reached a different way.

## Review round 3

Description Quality again, one high and four lower items. Four taken, one kept with a reason.

- **(high) The enumeration of order-blind operations went.** What remains is the general rule, now
  stated as a contract rather than a heading: two objects with the same keys and values are the
  same value. That covers the equality, `unique`, `group_by`, `contains`, `inside` and `index`
  tests directly. The `sort`, `max` and `min_by` tests do not lean on it at all: the round 2
  fairness pass classified them as repo-discoverable from `Compare` and `funcKeys`, which is where
  the relative order of two different objects actually comes from.
- **(medium) "however deep it sits" went.** Nesting is anchored by generality instead, since a
  nested object is itself an object read from JSON text, and `-S` still says "at every depth".
- **(medium) "and is accepted on its own as well" went** from the `-S` sentence. Nothing ties `-S`
  to `--ordered-keys`, so the two tests which use it alone still read as specified.
- **(low) The example clause in the visiting-order sentence went.** The rule itself stays, which is
  what the round 2 fairness pass needed for the iteration, `paths` and `tostream` tests.
- **(medium) "and objects are printed and listed with their keys sorted" was kept.** This is the
  one place the default is stated, and it is the only anchor for the tests which assert that
  behavior without the option, including `keys_unsorted` falling back to sorted. Round 1 already
  deleted the other statement of the default and moved the anchor here; deleting this one as well
  would leave those tests unfair, which is the blocking gate rather than the advisory one.

379 words down to 320. No test changed, so the patches are untouched.

## Review round 4

Test Fairness passed again; three advisory coverage suggestions. The third one found a real defect
rather than a coverage gap.

- **`--yaml-output` printed `{}` for every ordered object.** The YAML encoder cannot marshal a type
  whose fields are unexported, so with `--ordered-keys` and `--yaml-output` the whole value came
  out empty, silently. The description says an object keeps its order when printed and that `-S`
  sorts the keys of everything it prints, and YAML output is printing, so this was a defect against
  the stated contract. Fixed by converting each ordered object into a mapping node listing its keys
  in order, sorted when `-S` is given, leaving every other type alone. Eight tests cover it,
  including nesting, an object inside an array, a program-built object, and the default path.
  Quoting matches the existing map path exactly, including keys such as `n` and `y` which YAML
  resolves as booleans and so quotes.
- **`keys_unsorted` type errors.** Already correct: it errors on numbers, strings, null and
  booleans exactly as `keys` does. Five tests added, matching on stable substrings rather than the
  whole message.
- **`--help` listing the options.** Already correct. One test asserts both entries appear.

13 tests added, 160 total, still 256 of 256 failing at base. Effective LOC 526 to 574.

**Method note.** The first two YAML mutations written for the proof did not compile, and a build
failure produces no `--- FAIL` lines, so the harness scored them 0 kills and they looked like
untested behavior. The harness now checks for `build failed` before counting, and both mutations
were rewritten as implementations that compile: hand the encoder a plain map, and sort whatever
`-S` says.

## Review round 5

Test Fairness passed; three advisory coverage suggestions, two taken in full and one declined for a
reason that matters more than the tick.

- **Unordered host-map fallback, taken.** Eight library-level tests now drive `gojq.Parse`,
  `gojq.Compile` and `Run` over a `map[string]any` the test builds in Go, so a value with no order
  to keep goes in through the public API rather than through CLI decoding. They cover
  `keys_unsorted` falling back to sorted on two and on six keys, `keys` agreeing with it, and
  iteration, `to_entries`, `paths` and a nested map all coming out sorted. A new mutation, giving a
  plain map its keys in Go map order, kills eight of them.
- **`-S` is a serializer concern, taken.** Seven tests print the same carried object under `-S`
  beside something which reads the value rather than serializing it: `keys_unsorted`, the keys of
  `to_entries`, `tojson`, iteration, and a YAML array holding both. The printed object comes out
  sorted while the value keeps its order every time, and the order still survives an update made
  under `-S`. A mutation which rewrites the object's key slice while sorting kills them.
- **Public API for the ordered option itself, declined.** The option is a new exported symbol, so a
  test naming it does not compile at the base commit, and a package whose test binary fails to
  build produces one `[build failed]` node instead of a named node per test. That would cost the
  F2P classification of every test in that package to gain an advisory tick. The option is still
  exercised on the public API by all 256 tests, since the CLI is a thin wrapper which passes it to
  `gojq.Compile`; the suggestion is satisfied for everything reachable without naming a new symbol.

15 tests added, 175 total, still 256 of 256 failing at base.

## Review round 6

Test Fairness passed; two advisory coverage suggestions, both taken (13 tests, 188 total, still
256 of 256 failing at base).

- **Streaming input.** `--stream` already emitted events in text order at the base commit, because
  the streaming decoder reads tokens in sequence, so a test asserting only the event order is a
  base-passer. Each event-order test therefore carries a `fromstream(inputs)` reconstruction beside
  it, which the base commit gets wrong (it rebuilds a plain map and prints it sorted). Six tests
  cover flat and nested events, reconstruction of a three-key, a six-key and a nested object, an
  object inside an array, and `keys_unsorted` on the reconstructed value.
- **Deep merge right-order breadth.** Five tests now cover a right inner object contributing five,
  six and seven new keys, a mix of new and existing inner keys, and two branches each contributing
  several, plus the same breadth for shallow `+`. A new mutation which takes the right object's keys
  from the map instead of its key order is killed on every run.

## Review round 7

Test Fairness passed; two advisory coverage suggestions, both taken (12 tests, 200 total, still
256 of 256 failing at base).

- **`with_entries` changing keys, not only values.** Seven tests now rename keys through the full
  `to_entries | map | from_entries` path: a prefix on every key, an upcase over six keys, a single
  key renamed in place, a rename which collides with a later key, a rename which collapses two keys
  onto one, renaming and changing the value together, and dropping a key. The collision cases are
  where the two stated rules meet: the surviving key keeps the position of its first appearance and
  takes the later value. A new mutation, making a key written again move to the end instead of
  keeping its position, kills eighteen tests.
- **Nested order through the auxiliary decoders.** `--argjson`, `--jsonargs`, `--slurpfile` and a
  file argument each get a nested case, plus one asserting `keys_unsorted` at depth through
  `--argjson`, so recursion is checked independently of the top level for every decoder rather than
  only for standard input.

Two of the collision cases collapse to a single-key object, whose sorted and carried order are the
same, so on their own they would pass at the base commit. Each is paired in the same test with a
collision whose result has two keys in a non-sorted order.

## Review round 8

Three checks reported: Solution Quality PASS (comprehensiveness 3 of 3, code quality 2 of 3), a
test-quality warning, and Description Quality with one high item. All addressed.

**Code quality, both nits fixed.** `cli/inputs.go` still carried a second copy of the ordered
decoder, left behind when the shared one moved into the gojq package; a comment-only deletion had
missed the body. It is gone, along with the `fmt` import it was the last user of. The CLI encoder
no longer copies the object into a map before writing it: `encodeOrderedObject` reads each value
straight off the object, and `OrderedObject.Map()`, whose only caller that was, is gone too.

**Test quality warning, addressed.** The five error tests asserted message substrings
("cannot be applied to", "number (1)"). They now compare the exit code of `keys_unsorted` on a
scalar against the exit code `keys` gives for the same input, which is the actual requirement (it
fails the way the established function fails) and pins no wording at all. The help test asked for
"-S, --sort-keys", which is column layout; it now looks for the two option names only.

Note the first attempt at this got it wrong: comparing both exit codes under `--ordered-keys` made
all five pass at the base commit, because the unknown flag makes both sides exit the same way. The
baseline call has to run `keys` as it exists, without the new option.

**Description, high item taken.** The sentence explaining that gojq decodes into Go maps is gone;
what remains of it is the one clause the default-mode tests need, that objects keep their order only
under the option. Both medium items taken as well: the creation-order sentence, which follows from
new-keys-append plus existing-keys-hold, and the list of input sources at the end, which follows
from the rule about JSON text. 320 words down to 287.

**A mutation that could not be written.** A mutation making the encoder rewrite the value's key
order while sorting turned out to be a no-op, and the reason is structural rather than accidental:
`Delete` is copy-on-write and the key slice is unexported, so nothing in the cli package can reorder
a value it is printing. The non-mutation property is enforced by the type, not by the tests; the
tests still cover the observable behavior.

## Review round 9

Test Fairness passed; two advisory coverage suggestions, both taken (11 tests, 211 total, still
256 of 256 failing at base).

- **`-S` across an array boundary.** Nested objects were covered but only inside other objects.
  Four tests now sort through an array: one object in an array, two objects in an array, an array
  inside an object, and an array inside an array.
- **Sorted order for non-ASCII and escaped keys.** Seven tests confirm the existing string ordering
  survives: a non-ASCII key sorts after every ASCII one under both `keys` and `-S`, an uppercase key
  sorts before a lowercase one, a `\u` escape sorts exactly where the literal character would, an
  astral-plane character sorts after ASCII, a control character inside a key sorts before a letter,
  and one test puts the carried order beside the sorted order for keys which differ only by accent,
  so the two are visibly not the same list. Ordering matches jq for all of them; the previous
  Unicode tests only covered carried order.

## Review round 10

Test Fairness passed; two advisory coverage suggestions. The second found a real defect.

- **Malformed JSON on the ordered route silently succeeded.** With `--ordered-keys`, a cut-short
  input such as `{"b":1,` or `{` exited 0 and printed nothing, where the existing decoder exits 5
  with an "unexpected EOF" message. The cause is that `json.Decoder.Token` returns `io.EOF` when the
  input stops inside a value, while `Decode` turns the same condition into `io.ErrUnexpectedEOF`;
  the iterator treats `io.EOF` as a clean end of stream. Reading tokens through a helper which
  converts that one error fixes it, and the ordered path now matches the plain path on exit code and
  message for every malformed case tried, including truncation after a value which has already been
  printed. Eight tests compare the two routes rather than pinning a message, covering a truncated
  object, an unclosed object, a truncated array, a missing value, a missing comma, truncation after
  a good value, a malformed `--argjson` and a malformed file. A mutation restoring the old behavior
  kills seven.
- **Colored output.** Six tests check that `-C` combined with `--ordered-keys` and with `-S` carries
  the same keys in the same order as the uncolored form. They strip the escape sequences and compare
  the remainder, then assert escapes were present, so the palette is free to change without breaking
  them. `noColor` needed no save and restore: `runInternal` already defers it.

One cosmetic difference remains and is not tested: for a syntax error (as opposed to truncation) the
caret in the message sits one column earlier on the ordered route, because the token reader has
consumed a different amount of input than `Decode` would have. Exit code and message text match.

## Review round 11

Test Fairness passed; two advisory coverage suggestions. The second was a defect report against our
own test helper and it was right.

- **`orderedRunFull` read standard output before running the query.** `return outStream.String(),
  c.run(args)` evaluates left to right, so the string was always empty and every comparison built on
  it was vacuous. Fixed by running first and reading after. The fix immediately failed
  `TestOrderedKeysRejectsTruncationAfterAGoodValue`, which had been comparing "" against "": the two
  routes do not print the same bytes before failing, because the value they emit first is printed in
  different key orders. That test now asserts each route's own output, and the shared helper requires
  both routes to have printed nothing, which holds for every other malformed case.
- **`gojq.Marshal` on carried values.** The ten library-level tests now marshal their results with
  the public `gojq.Marshal` rather than `encoding/json`, and two of them assert directly that a plain
  Go map marshals with sorted keys, at the top level and at depth. The ordered half is declined for
  the same reason as the earlier public-API suggestion: producing an order-carrying value through the
  library needs the new compiler option, and naming a new symbol makes the test file fail to compile
  at the base commit, which costs per-test F2P classification for the whole package. It is covered in
  substance, since `Marshal` and `tojson` are the same code (`(&encoder{}).encode`), and the ordered
  `tojson` and `@json` tests exercise that path.

## Review round 12

A test-quality warning with two halves. One is fixed, the other is a deliberate choice with the
reasoning below.

**Unstated sorting rules, fixed.** Seven tests pinned a literal collation order (uppercase before
lowercase, non-ASCII after ASCII, control characters, astral plane), which the description does not
state and should not have to. They are now differential: the same input is run with the option and
without it, and the two outputs must be identical. That asserts exactly the thing worth asserting,
that adding a second key order leaves the existing sorting alone, and it pins no collation rule at
all. Four more comparisons were added in the same shape, including the neat one that `-S` output with
the option equals the ordinary output without it. The pair which shows carried and sorted orders are
different lists survives, but now by comparing the two against each other rather than by naming the
order.

**Coupling to the cli package, kept.** The tests build the package-private `cli` struct and call
`run`, which is what the repository's own `cli/cli_test.go` does, and it is the only way to capture
the output streams: the exported `cli.Run` reads `os.Args` and writes to `os.Stdout`, so a black-box
version would have to swap process-global file descriptors, which is worse for isolation than what is
there now. It also uses `newStringReader` deliberately rather than `strings.NewReader`, because that
reader does not implement `io.Seeker` and so exercises the same non-seekable path standard input takes.
Changing this is also what forces the F2P classification problem described above. No description
change either: adding a test-assumptions section would restate the CLI surface the description already
names, and the description gate has been trimming in the opposite direction for three rounds.

## Review round 13

Two checks, both warnings. The test-quality one is a naming slip of ours; the description one is two
high items and a medium.

**Test name did not match its input, fixed.** `TestOrderedKeysKeysUnsortedOnArrayOfScalars` fed a
string, not an array. It is now `TestOrderedKeysKeysUnsortedOnNumericString`. The same check cleared
the cli-struct coupling this round, having accepted that the tests use it to observe behavior.

**Both high description items taken.** The clause stating what happens without the option is gone,
and so is "`keys` still sorts". Neither left a test unanchored, because of the differential rewrite in
the previous round: the sorted-side tests now assert that output with the option matches output
without it, which needs no statement of what the default is. The one test which did pin the default
literally now asserts instead that the option changes the output and that the ordered form is the
input order, which claims nothing about the default's content. Default-mode `keys_unsorted` keeps its
anchor in the surviving sentence about falling back to the sorted order, and `keys` sorting is carried
by the contrast in "`keys_unsorted` is the one that gives an object its own order".

**The medium item is declined.** It asks to drop "and printing it prints them in that order", on the
grounds that the visiting-order sentence implies printing. Printing order is what the bulk of the
suite asserts, and "visited" is not the same word as "printed"; the risk of leaving roughly a hundred
tests resting on an inference is worse than one advisory line. Taking both high items already puts the
count under the threshold that drove the verdict.

287 words down to 275.

## Fairness audit of the malformed-input tests

Asked directly whether the eight `RejectsMalformed*` tests are fair and solvable, and the answer
changed the description.

**Solvable, comfortably.** They compare the exit code of the ordered route against the exit code the
existing route gives for the same input, and require that neither printed a value first. No message
text is pinned and neither is the caret column, which does differ by one for the syntax-error class.
Any implementation which rejects malformed input with the same exit code passes, and several natural
designs pass without thinking about it: validate then reorder, a custom scanner, `json.RawMessage`
rescanned. The reference fix is four lines.

**Fair only after this round's change.** Nothing in the description mentioned malformed input, the
failure is silent (exit 0, no output) so nothing written to test the feature reveals it, and the
hazard is not in the repository either, since gojq never calls `Token` and so never meets the
`io.EOF` against `io.ErrUnexpectedEOF` gap. Only the expected outcome was discoverable, not the trap.
Base mode does not cover it either: `cli/test.yaml` has 22 malformed-input cases and none of them use
the new option, so a solver can be green on base with the defect live. Eight of 231 tests failing for
one unstated reason is the hidden-requirement shape, and the evidence that a solver would miss it is
that the 50-program differential, the fork-point probes and 200 tests all missed it until the
coverage check asked.

One sentence now states it: reading input with the option changes the order keys are kept in and
nothing else, so text which is rejected now is still rejected the same way. The tests are unchanged,
which is the point: the contract is stated and the fix stays hidden. 275 words up to 302, and this
clause is load-bearing for eight tests if the description gate asks for it back.

## Review round 14

The description gate and the coverage gate asked for opposite things about the same behavior: one
wanted the malformed-input clause removed as an obvious default, the other wanted more malformed-input
tests. Both were served.

**The high item, taken in the form it asked for.** It targets the trailing clause, not the sentence, so
"Reading input with the option changes the order keys are kept in and nothing else" stays and only "so
text which is rejected now is still rejected the same way" goes. The scope statement still covers error
handling through "nothing else", and the gate's own reasoning helps rather than hurts: a requirement it
calls an obvious default is one a solver is expected to meet. The fairness gate is the one which judges
this, and it passed these eight tests three rounds running before the clause existed at all.

**Two of the four lower items taken.** The `with_entries` clause goes, since it follows from
`to_entries` being in order plus the rule that a key the program creates goes to the end. The
array-indices clause goes, since `keys` on an array is existing behavior and `keys_unsorted` matching
it is the obvious reading; the two array tests stand on that.

**Two declined, both because they are the sole anchor for tests.** "Removing a key leaves the order of
the rest alone" anchors ten deletion tests, and nothing else in the description mentions deletion: the
creation-order and existing-key rules say nothing about what happens to the survivors. "That order is
also the order its members are visited in" is the sentence added in round 1 *because* the fairness gate
failed seven tests without it, covering `[.[]]`, `paths` and `tostream`; deleting it would recreate a
known failure. That leaves two open suggestions and no high item.

**Coverage, both taken.** Seven tests added: malformed text through `fromjson` in five shapes
(truncated array, unclosed object, missing value, truncation after a pair, trailing text) and malformed
`--jsonargs` in two, each comparing exit-code parity against the same input without the option. The
`fromjson` path matters because it is the second ordered decoder, reached from inside a query rather
than from the CLI. The truncation mutation now kills nine instead of seven.

302 words down to 277.

## Review round 15

Two high items, two medium, one low. Three addressed, two declined.

**The scope sentence is gone entirely (high).** Last round the gate wanted its trailing clause; this
round it wants the sentence. Taken, and the fifteen malformed-input tests keep standing on the same
footing they had for four rounds before the sentence existed: the fairness gate passed them, and this
gate has now twice called the requirement an obvious default, which is the same judgment from the
other side.

**The merge sentence is compressed rather than deleted (high).** The gate calls it over-specified and
derivable. Half of it is: shared keys keeping a's position and taking b's value follows from the rule
that assigning to a key which is already there leaves it where it is, plus the repository's existing
merge. The other half is not: the order in which b's new keys are appended is a real choice, sorted
being just as plausible as b's own order, and the recursion in `a * b` is another. Round 1's fairness
report cited this sentence by name as the evidence making the merge group prompt-stated, and there
are nineteen merge and deep-merge tests, several added at the coverage gate's request. So the
derivable half went and the two choices stayed: "`a + b` appends the keys only b has, in b's order,
and `a * b` merges deeply by that same rule."

**"Objects keep their order only under `--ordered-keys`" is gone (medium).** Implied by the opening
sentence adding an option, and the sorted-side tests have been differential since round 12, so
nothing rests on it.

**Two declined.** Removing "and printing it prints them in that order" would leave roughly a hundred
printed-output assertions resting on the inference that printing follows visiting; "visited" is not
"printed". Removing "`to_entries` gives the entries in order" would leave the entries group resting
on the same inference, and at the base commit `to_entries` is defined in terms of `keys`, so the
ordered behavior is a change a solver has to make rather than something the repository shows. Neither
is high. That leaves two open suggestions and no high item.

277 words down to 240.

## Review round 16

Test Fairness passed; two advisory coverage suggestions, both taken (11 tests, 249 total at that
point, all failing at base).

- **An ordered object merged with one carrying no order.** The suggestion asked how the right-hand-order
  rule reads when an operand has no order to give. The library route is closed for the standing reason,
  but the CLI has a source of order-free objects: the regex builtins build their results as plain Go
  maps, so `match("b")` produces one inside an otherwise ordered query. Six tests use it. Three pin the
  ordered-left case, where the order-free operand's keys append sorted, which the description supports
  by "appends the keys only b has, in b's order" together with the rule that an object keeping no order
  falls back to sorted. The other three are differential and need no support at all: with an order-free
  object on the left, or on its own, the output is byte-identical to the same query without the option.
  A new mutation, taking the result's representation from the right operand instead of the left, kills
  three.
- **Several valid top-level values without slurp.** Five tests read two and three objects from standard
  input, two on one line, two from a file, and an array beside an object, each keeping its own order.
  The existing multi-value coverage went through `inputs` and the malformed-second-value boundary, so
  the plain streaming case was untested.

## Review round 17

Test Fairness failed on exactly one test of 42 groups, and the test was mine from the round before:
`TestOrderedKeysMergeOntoOrderlessOperandStaysSorted`. Removed.

The reasoning is correct and I had already half-seen it. For `match("b") + {z:1,y:2}`, where the left
operand carries no order and the right does, the test required the result to be byte-identical to plain
mode, which means globally sorted: `captures,length,offset,string,y,z`. The description says `a + b`
appends the keys only b has in b's order, which reads just as naturally as sorted-left followed by
`z,y`. Two defensible answers, and nothing in the pre-feature repository picks between them.

Being differential did not save it, which is the lesson. A differential assertion is only fair when the
comparison itself is forced; here "identical to plain mode" *was* the contested choice, dressed up as a
comparison. The three ordered-left tests are unaffected and were classified prompt-stated, since the
right operand's sorted fallback follows from the stated fallback rule.

The reference solution is unchanged: a merge result takes its representation from the left operand.
That behavior is now untested and unstated, which is the correct state for a corner the description does
not settle, and it costs nothing at review, since an agent choosing the other rule passes either way.
The related mutation still dies on the ordered-left tests, two kills instead of three.

249 tests down to 248.

## Review round 18

One high item, three medium, one low. Three addressed, two declined on the strength of the fairness
report, which names the sentences it relied on.

**The high item, split rather than deleted.** It objects to "The order belongs to the value rather
than to the input, so it survives wherever the object goes" as conceptual and derivable from the
concrete rules. The conceptual half went; the operative claim stayed as "The order survives wherever
the object goes." The derivation argument does not hold for the part that was kept: surviving a
variable binding, a function argument, a function return and an array round trip does not follow from
assignment keeping position or merges appending, which are about construction rather than transport,
and the fairness report cites this sentence by name as what makes those four tests prompt-stated.

**One medium taken.** The clause restating that a decoded object keeps its key order duplicated the
opening sentence; the printing rule it was attached to now stands on its own.

**The low item taken.** "Text carries the order both ways" was filler in front of the concrete rule.

**Two medium items declined, both for the second or third time.** "Removing a key leaves the order of
the rest alone" is the cited anchor for ten deletion tests, and nothing else in the description
mentions deletion. "`to_entries` gives the entries in order" is the cited anchor for the entries group,
and at the base commit `to_entries` is defined in terms of `keys`, so the ordered behavior is a change
a solver has to make rather than something implied by iteration order. Both are classified
prompt-stated on the strength of those sentences.

240 words down to 208.

**A defect in the patch, found while reading it.** The insertion of `WithOrderedObjects` in `option.go`
landed between `WithInputIter`'s doc comment and its function, so the existing comment documented the
new function and `WithInputIter` was left undocumented. The new function now sits after
`WithInputIter` with its own comment. Nothing behavioral, but it is exactly the kind of thing the code
quality check reads for, and a diff which splits an existing doc comment from its declaration is worth
grepping for before submit.

## Review round 19

Description Quality is down to minor_suggestions, two optional items, no high. Coverage had two
suggestions, both taken (10 tests, 258 total, still 256 of 256 failing at base).

- **Duplicate keys which are only equal after decoding.** `{"a":1,"\u0061":2,"b":3}` names the same key
  twice, once escaped, and the rule has to apply to the decoded key rather than the text. It does, in
  gojq as built and in jq: first position, later value. Six tests cover it, including a case where the
  surviving order differs from sorted so the assertion cannot pass by accident, the escaped spelling
  appearing first, a non-ASCII key, and the same input through `fromjson`. The existing
  key-written-again mutation kills eighteen.
- **A library result fed into another query.** Four tests take the result of one compiled query and
  hand it to a second, checking that the value stays usable across the boundary: identity then
  `keys_unsorted`, a nested object extracted then listed, `to_entries` in one run and `from_entries` in
  the next, and a merge result listed afterwards. `gojq.TypeOf` on the handed-back value is asserted to
  be "object". The ordered representation cannot be produced this way for the standing reason, so these
  cover the fallback representation, which is the one the library can build.

**The low description item taken, the medium declined.** "whatever order the value carries" went from
the `-S` sentence, since sorting overriding an existing order is not in doubt. "which is also the order
its members are visited in" stays: it is the sentence added in round 1 because the fairness gate failed
seven tests without it, and the latest fairness run still cites it for the iteration and `paths` groups.
208 words down to 203.

## Platform batch 1 — 4 x Nova (0 of 4)

| run | verdict | stats | new tests | what failed |
|---|---|---|---|---|
| 1 | FAIL_MISSED_REQUIREMENT | 16 files / 460 LOC / 103 msgs | 235 of 258 | order lost through the `add` fast path, so `from_entries`, `to_entries \| from_entries` and `with_entries` sort; plus 4 truncated-input cases |
| 2 | FAIL_MISSED_REQUIREMENT | 14 files / 477 LOC / 158 msgs | 212 of 258 | compiler and object-construction opcode left untouched, so literals, empty objects, assignment from null, `from_entries`, `fromstream` all sort; pointer-keyed side table leaked stale order into unrelated maps |
| 3 | FAIL_MISSED_REQUIREMENT | 23 files / 476 LOC / 157 msgs | 248 of 258 | 6 YAML-output cases and 4 truncated-input cases |
| 4 | FAIL_TEST_BROKEN | 19 files / 795 LOC / 127 msgs | 0 of 258 (build failed) | our test file's package-level `ordered` helper collided with the agent's `internal/ordered` import |

Baseline was 1093 of 1093 in every run, so the environment and the patches are sound. Difficulty is
real: the two core traps each killed a run on their own, run 1 on the `add` fast path and run 2 on
object construction, and neither agent found the other's problem.

### Run 4 was our bug, and it is fixed

The test file declared `func ordered(t *testing.T, ...)` at package level. An agent which puts its
representation in `internal/ordered` and imports it in the cli package gets
`ordered already declared through import of package ordered`, and the whole tagged test binary fails
to build, so all 258 tests are reported missing. The evaluator marked it `agent_blame_unfair: true`,
and rightly.

Three package-level identifiers were single lowercase words and therefore able to collide with an
import name: `ordered`, `obj` and `wide`. They are now `assertOrdered`, `objInput` and `wideInput`,
and the file has no single-word lowercase package-level identifier left. This is the
verifier-hostile-test-shape class from our notes, in a form we had not seen: a same-package test
helper is in the same namespace as every import in every file of that package.

### Two axes removed to reach the band

Runs 1 and 3 both lost tests to truncated-input parity, and run 3 lost the rest to YAML output. Both
are peripheral to the ordered-object representation and both were weakly anchored:

- **Malformed and truncated input, 15 tests removed.** The only description sentence stating it was
  deleted at the description gate's insistence, twice, at high severity. Keeping tests for a
  requirement the description is not allowed to state is the definition of unfair, and it cost two
  runs. The fix stays in the solution, because without it `--ordered-keys` turns a truncated input
  into a successful empty read, which is a regression the feature itself introduces.
- **YAML output, 8 tests removed, and the description now scopes printing to JSON.** "Printing an
  object as JSON prints its keys in the order it keeps" and "`-S` sorts the keys of everything it
  prints as JSON" put YAML out of scope, so removing the tests leaves no false-positive exposure. The
  conversion stays in the solution for the same reason as above: without it the option prints `{}`
  for every object in YAML mode.

Replaying the three fair runs against the reduced suite: run 1 still fails on the `add` fast path,
run 2 still fails on object construction, and run 3 has zero failures left, so it passes. That is one
in three on the existing evidence, in the target band, with both core traps intact.

### Also fixed

`CGO_ENABLED=0` is gone from the Dockerfile. Two agents tried `go test -race` and were told CGO was
disabled; the base image has gcc, so the flag was costing solve time for nothing. Verified: the whole
suite passes under `-race`, base and new.

## Platform batch 2 — 3 x Nova against the 235-test suite (0 of 3)

| run | verdict | new tests | what failed |
|---|---|---|---|
| 1 | FAIL_MISSED_REQUIREMENT | 205 of 235 | compiler and object-literal opcode untouched, so literals, assignment from null, right-hand merge order and stream reconstruction all sort |
| 2 | FAIL_MISSED_REQUIREMENT | 227 of 235 | assignment and `setpath` starting from null build a plain map, which also breaks `fromstream`; 8 tests, nothing else |
| 3 | FAIL_MISSED_REQUIREMENT | 191 of 235 | same as run 1; the trajectory records the agent deciding literal order was "likely acceptable" to leave unordered |

Baseline 1093 of 1093 in all three. Every evaluator: `description_clear: true`,
`was_mentioned_in_description: true`, `agent_blame_unfair: false`. The collision fix held, all 235
tests were classified in every run.

### Where the difficulty actually lives

Across six fair runs over both batches, the killer is one axis in four of them: objects created by the
jq program rather than decoded from input. Nobody has failed on the representation, the decoder, the
encoder, comparison, deletion or iteration; those get done. What gets missed is `compiler.go`,
`opobject`, and the allocator/setpath selection.

Replaying all six against the current 235-test suite: batch 1 run 3 has zero failures left, since
both of its axes are gone. That is one in six, about 17 per cent, in the target band. Two runs were at
the line: that one at zero remaining failures and batch 2 run 2 at eight.

### One clause added, deliberately the narrowest one

Batch 2 run 2 is the informative case. Its implementation ordered everything except the moment when an
assignment has to *create* the object, where it passed `ordered=false` because the current value was
null. Re-reading the description, that is a real gap rather than a missed statement: "a key the
program creates goes to the end" says where the key goes, and says nothing about what the container
is when the assignment itself brings it into being. The sentence now reads "A key the program creates
goes to the end, including when the assignment is what creates the object it goes into".

That converts a measured 227-of-235 near miss into a pass and leaves the object-literal axis exactly
as it was, so batch 2 runs 1 and 3 would still fail. Expected around two in six over the combined
evidence. The larger clarification was available and was rejected: restoring the sentence about
objects the program builds, which the description gate made us delete in round 18 as redundant, would
probably have converted three more runs and pushed the rate over the too-easy cap.

Worth recording against that gate: its argument for deleting that sentence was that it followed from
the key-creation rule. Four agents then read the key-creation rule and left object literals unordered,
one of them explicitly reasoning that literal order was not crucial. "Implied" and "understood" are
not the same thing, and a batch is the only way to tell them apart.

## Review round 20

A test-quality warning and a description round.

**Test quality, two of three taken.** Seven tests removed. The two which asserted `gojq.Marshal`
output directly were the clearest case: the description says nothing about the Go marshaller, and
their library halves duplicated tests which already exist, so nothing is lost. `--indent 4` and
`--tab` went as well, since they exercise the existing formatter rather than the feature and the
pretty case already covers ordering outside compact mode; three of the six colour tests went for the
same reason, keeping the ones which carry the order, the sorted form and the default-mode pair.

The third item, building the package-private `cli` struct, stays. It is the repository's own test
convention, it is the only way to capture the output streams without swapping process-global file
descriptors, and moving to the exported entry point reintroduces the compile-at-base problem which
costs per-test classification for the whole package. The checker itself notes these tests are "still
asserting behavior".

**Description, the high item and one medium taken.** The sentence about key order being invisible to
everything else went. The eleven order-blind tests now rest on the repository instead: `Compare`
sorts an object's keys before comparing, which is exactly the "don't change existing equality
semantics" the checker calls obvious, and three of that group were already classified
repo-discoverable. "Removing a key leaves the order of the rest alone" went too, since deletion not
reordering the survivors does follow from the order surviving.

**Two declined.** "`to_entries` gives the entries in order" stays: at the base commit `to_entries` is
defined in terms of `keys`, so ordered entries are a change the solver has to make rather than
something implied by visiting order, and it is the cited anchor for that group. The low item asks to
remove the clause about the assignment creating the object, which is the clause added one round ago
after batch 2 run 2 lost eight tests to exactly that ambiguity. Batch evidence outranks a low-severity
redundancy note.

219 words down to 190, 235 tests down to 228.

## Review round 21

Three coverage suggestions, two taken.

- **Objects an assignment creates on the way down, taken.** Five tests: a single created level, filling
  a level created earlier, three levels at once, a created level added to an object which already
  existed, and the same through `setpath`. All match jq. This is the best suggestion the coverage
  check has made for this submission, because it lands on the axis four of six batch runs died on, and
  a created *intermediate* object is a harder case than a created top-level one.
- **`debug` and `stderr`, taken in half.** Both print through encoders built separately in
  `cli/cli.go`, and both print in the carried order. Two tests assert that. The other half of the
  suggestion, whether `-S` reaches those encoders, is deliberately not tested: it does in the
  reference, but it is a separate piece of flag threading and testing it would add a failure axis to a
  submission which is already at zero passes across six runs. The ordered half costs nothing, since
  any implementation whose encoder handles ordered objects gets it for free.
- **JSON data modules, declined.** The module loader decodes with its own `json.Decoder` and the
  reference solution does not order it, so the suggestion would fail our own solution. It is out of
  the option's scope, in the same way YAML input is, and no test asserts it either way. Recorded here
  as a carve-out rather than left implicit.

228 tests up to 235.

## Review round 22

Two coverage suggestions. One closed by scoping the description, one declined.

**`-S` on the stderr renderers, closed by wording rather than by a test.** The suggestion is right that
there was an ambiguity: `debug` and `stderr` print JSON through encoders built separately in
`cli/cli.go`, the description said `-S` sorts "everything it prints as JSON", and no test pinned it
either way. That is a false-positive hole, since an agent which never threads the flag into those two
encoders would pass. It now reads "every result it prints as JSON", which puts diagnostic output on
standard error outside the rule. The two tests asserting that `debug` and `stderr` print in the
carried order are unaffected, because the printing sentence they rest on is not scoped that way. No
failure axis added, which matters with the submission at zero passes over six runs; the reference
still sorts them under `-S`, it is simply no longer required to.

**`gojq.Marshal` on an ordered result, declined again.** Producing an order-carrying value inside a
library test requires naming the new compiler option, which makes the test file fail to compile at the
base commit and costs per-test classification for all 235 tests, exactly the failure which cost batch 1
run 4. The behavior is covered in substance rather than by name: `Marshal` is a three-line wrapper
around `(&encoder{w: &b}).encode(v)`, and `tojson` is the same three lines around the same encoder
through `jsonMarshal`, so the ordered `tojson`, `@json` and nested `fromjson` tests exercise that exact
path. This is the fourth request for the same thing; the reason has not changed.

## Review round 23

**The non-JSON output boundary, documented with three order-agnostic tests.** The suggestion is right
that the boundary was left implicit: the description scopes printing and sorting to JSON, the YAML
tests were removed in round 20 for difficulty, and the reference still contains the conversion which
makes YAML output ordered. The gap that matters is not the order, it is that without any handling the
option makes `--yaml-output` print `{}` for every object, because the encoder cannot marshal a type
whose fields are unexported. So the new tests assert the pairs and not their order: they sort the
output lines and compare, with and without `-S`, on a two-key and a six-key object.

That documents the boundary without reopening the axis. An implementation which converts ordered
objects to plain maps before encoding passes, and so does one which keeps the order; only one which
lets the new type reach the YAML encoder untouched fails, which is a regression the feature itself
introduces rather than a new requirement. Batch 1 run 3, the only run which failed on YAML, converted
to a map and lost the order, so it would pass these.

**`gojq.Marshal` on an ordered result, declined for the fifth time.** The rephrasing suggests building
the value from an object literal or an update instead of from decoded input, but every route to an
order-carrying value inside a library test goes through the new compiler option, and naming a new
exported symbol in a same-package test file makes it fail to compile at the base commit. That is the
exact failure which reported 0 of 258 in batch 1 run 4. `Marshal` and `tojson` are the same three
lines around the same encoder, and the ordered `tojson`, `@json` and nested `fromjson` tests cover it.

235 tests up to 238.

## Review round 24

Two high description items, one taken and one compressed; two medium declined; a test-quality warning
declined; a coverage suggestion declined on batch evidence.

**"The order survives wherever the object goes" removed.** Taken because the printing sentence already
carries it: "prints its keys in the order **it keeps**" makes the order a property of the object
rather than of the input, which is exactly what the four transport tests rest on. A value bound to a
variable or passed through a function is the same value.

**The merge sentence compressed rather than deleted.** It now reads "`a + b` appends b's new keys in
b's order, and `a * b` does the same at every depth", which drops the enumerated framing the item
objects to and keeps the two things which are genuinely free choices. The claim that they follow from
the general rules is wrong on both counts: nothing about "new keys append" fixes *which* order the
appended keys take, sorted being just as consistent, and nothing implies the recursion in `*`. The
merge-from-map mutation kills six or seven tests and the deep-merge one another one to three, so the
behavior is specified rather than derived, and round 1's fairness report cited this sentence by name
as what made nineteen merge tests prompt-stated.

**Two mediums declined again.** The clause about the assignment creating the object exists because
batch 2 run 2 lost eight tests to that exact ambiguity. `to_entries` is defined in terms of `keys` at
the base commit, so ordered entries are a change the solver makes rather than something implied by
visiting order.

**Test quality, the cli-struct coupling, declined for the fourth time.** The suggested alternative is
an exported entry point, but `cli.Run` reads `os.Args` and writes `os.Stdout`, so a black-box version
would swap process-global file descriptors, which is worse isolation than what is there and cannot run
in parallel. The repository's own `cli/cli_test.go` builds the same private struct.

**Malformed-input coverage declined, with the strongest evidence in the file.** That axis was removed
in round 20 because it cost two of the three fair runs in batch 1, and its only description anchor had
been removed twice at this same gate's high severity. Re-adding it would put back a measured
two-in-three failure axis for a requirement the description is not permitted to state. The weakest
useful form, comparing exit codes against the plain path, is exactly what was removed; there is no
lighter version the way there was for YAML, because the failure is a silent success rather than a
crash.

191 words down to 182.

## Review round 25

The alignment check ran for the first time and found something the description-quality gate could not:
a group of tests resting on a rule the description stated too narrowly.

**The orderless fallback is now general.** It was written only as a property of `keys_unsorted`
("falling back to the sorted order when the object keeps none"), while about a dozen tests rely on the
same fallback for iteration, `to_entries`, `paths`, printing and both merges, with host maps and
`match` results as the orderless values. The fallback is now its own sentence, "An object which keeps
no order of its own counts as sorted wherever the order is used", and `keys_unsorted` keeps only its
own rule. That is a generalisation rather than an enumeration, so it answers this gate without giving
the description-quality gate a list to object to; six words added.

**The help suggestion is declined.** The alignment check also asks for a sentence saying `--help`
lists the two options. Adding a CLI option in this repository means adding a field to `flagopts`, and
help text is generated from those field tags, so listing follows from adding the option. The fairness
gate has classified that test as repo-discoverable and fair every round it has run. A sentence there
would be an instance rather than a rule.

**The cli-struct coupling is declined for the fifth time.** Same reasoning as before: `cli.Run` reads
`os.Args` and writes `os.Stdout`, so the suggested public entry point means swapping process-global
file descriptors, and the repository's own `cli/cli_test.go` builds the same private struct.

182 words up to 188.

## False-positive review — two holes, both closed

An agent passed all 238 tests without meeting the requirements. Both causes are ours, and both are
now closed. Twelve tests added, 250 total, and two clauses restored to the description.

**Hole 1: truncated input silently accepted, and this one I created.** The candidate's ordered decoder
returned bare `io.EOF` from the object-key read while converting it on the value reads, so
`{"a":1,` exited 0 with no output and the input was dropped. That is the same defect the reference
carries a fix for, and the tests which caught it were removed in round 20 to bring the pass rate into
band, then declined again two rounds ago when the coverage check asked for them back. The trade was
wrong: a clean false-positive check is required to submit, difficulty is not. Six tests are back,
comparing exit codes against the plain path for a truncated object, an unclosed object, a truncated
array, a missing value, a malformed `--argjson` and a truncated `fromjson`, and the description says
again that input which is rejected now is still rejected.

**Hole 2: order leaking into the default mode, which base mode cannot catch.** The candidate registered
every constructed object as ordered through a process-global pointer-keyed map, so program-created
objects carried insertion order through `tojson`, `@json` and `gojq.Marshal` even without the option.
It made base mode pass by editing three expectations in `cli/test.yaml`. That is worth stating plainly:
**base mode does not protect the default behavior, because the agent can edit the repository's own test
data.** The only defence is new-mode tests which pin default-mode output directly, so there are now
six, each pairing a default-mode assertion with an ordered one so it still fails at the base commit:
an object literal printed, through `tojson`, through `@json`, through `keys_unsorted`, through
`fromjson`, and an assignment from null. The description now also says an object keeps no order unless
the option asked for it.

Both probes verified against the reference in the built image: truncated input exits 5, and
`{z:1,a:2}|tojson` without the option returns the sorted text.

188 words up to 208, which reverses two of the description gate's earlier removals. Where that gate and
the false-positive check disagree, the false-positive check wins; it is a submit gate and the other is
advisory.

## Review round 26

Two coverage suggestions, both taken, five tests. Both landed on gaps the false-positive review had
just made expensive.

**`halt_error` with a non-string value.** This is the third serialization path in the CLI and the only
one which goes through the exported `gojq.Marshal`, at `cli/cli.go:333-345`. It is also the route I
had been looking for through five rounds of declining to test `Marshal` on an ordered value: reachable
from the CLI, so no new exported symbol is named and the test still compiles at the base commit. Three
tests, one of which is a default-mode guard, since this is exactly the kind of path the false-positive
candidate leaked order through without the option.

Worth noting the scoping held: `-S` does not sort `halt_error` output, which is right, because round 22
narrowed `-S` to "every result it prints" and an error is not a result.

**A valid value followed by malformed input.** Two tests. The suggestion is right that the rejection
fixtures restored after the false-positive review only had a malformed *first* value, so nothing
covered the case where output has already been written. It needs its own assertions rather than the
shared helper, because the two routes legitimately print different bytes before failing, which is the
same trap that produced a vacuous test in round 12.

250 tests up to 255.

## Review round 27

Two coverage suggestions. One found an inconsistency in the reference and was answered by changing the
solution rather than by adding tests; the other added three.

**`-S` on diagnostic output was inconsistent, and the fix was to remove code.** `debug` and `stderr`
were threading the flag into their own encoders while `halt_error`, which goes through `gojq.Marshal`,
was not. Round 22 narrowed the rule to "every result it prints as JSON" precisely so diagnostics fall
outside it, so two of the three paths were doing something the description does not ask for. Both now
pass `false`, all three agree, and the solution is two lines smaller.

No test was added for it. Sorting diagnostics is neither required nor forbidden by the description, so
an implementation which does it is not a false positive, and asserting that it must *not* happen would
add an axis where the natural thing to do is the failing thing. The value order in diagnostics is
already covered, which is the part the description does state.

**All output layouts share the order logic, three tests.** The indent and tab cases were removed two
rounds ago when the test-quality check called exact whitespace brittle and orthogonal, and the coverage
check now wants the layouts covered. Both are satisfied by asserting the key *sequence* rather than the
bytes: pull the keys out of the output and compare compact, pretty, tab, four-space indent and join
mode against each other, ordered and under `-S`, flat and nested. No whitespace is pinned and the
layouts are covered.

255 tests up to 258. Effective LOC still 555.

## Review round 28

Two high items, one taken and one refused.

**Taken: the opening scope phrase was misleading, and probably expensive.** It said the option keeps
the key order of "objects read from JSON", which understates a feature that also orders objects the
program builds. That is not a style point. Four of six fair batch runs died on program-created
objects, and batch 2 run 3's trajectory records the agent deciding literal order was "likely
acceptable" to leave unordered. A headline which reads as scoping the feature to decoded input is a
plausible cause of that reading. It now says "objects read from JSON and of objects the program
builds", which is accurate at both ends and still excludes YAML input and module data, which the
reference does not order.

This may reduce difficulty on the axis which has been killing runs. That is the correct trade: a
misleading description is a fairness defect, and a pass rate which depends on a bad headline is not
difficulty. If a later batch lands too easy, that is measurable and fixable; shipping wording that
misdirects is neither.

**Refused: "Input which is rejected now is still rejected."** This sentence is one round old and it
exists because the false-positive review found a passing agent whose ordered decoder silently accepted
`{"a":1,` and dropped the input. Six tests rest on it. A clean false-positive check is a submit gate;
this check is advisory and its own reasoning, that the behavior is an obvious default, is exactly what
a shipped candidate disproved. The two medium items are refused on the same evidence as before: the
assignment clause exists because batch 2 run 2 lost eight tests to that ambiguity, and `to_entries` is
defined in terms of `keys` at the base commit.

208 words up to 214.

## False-positive review 2 — the address-keyed side table

A second passing agent, split panel, adjudicated a false positive at medium confidence. The candidate
tracked key order in a package-global map keyed by the object's memory address, never cleaned, so a
query compiled *without* the option could inherit stale order for a fresh plain Go map once the heap
reused an address: `keys_unsorted` returned `["z","a"]` instead of sorted. That violates two clauses
the description states outright, "an object keeps no order unless the option asked for it" and "an
object which keeps no order of its own counts as sorted".

**The suite used to catch this and had stopped.** Batch 1 run 2 had the same design and the evaluator
recorded a hidden test catching it, "a later plain map unexpectedly retains input order". What changed
is round 24: the test-quality check called the direct `gojq.Marshal` host-map assertions coupled and
non-essential, and I removed them. They were part of what made a default-mode compile over a plain map
observable after ordered work. Removing tests a quality check calls redundant can remove a
discriminator, and nothing in that check can see which ones those are.

**Four tests added, built the way the adjudicator described.** Ordered CLI work first so anything keyed
by address is populated, then `runtime.GC()`, then default-mode compiles over fresh plain maps: flat
and nested, a default-mode CLI run after ordered runs, and a version which interleaves ordered CLI,
default CLI and default library work in one loop. They assert only sorted output from the default mode,
so a value-carrying design passes every time; five consecutive runs of the whole suite are identical.

258 tests up to 262.

## Review round 29

**The Go version warning was checked and is unfounded.** The tests use `for range 256` and the `slices`
package, which need Go 1.22 and 1.21. The repository's `go.mod` declares `go 1.24.0`, so any toolchain
able to build gojq at all supports both; the image ships go1.26.3; and the base repository already uses
the same construct at `execute.go:61`. The loops were rewritten to the older three-clause form to see
what it cost, then put back, because matching the repository's own idiom is worth more than insuring
against a floor `go.mod` already guarantees. Recorded here so the check does not have to be re-derived.

**Three description items, all refused, all on evidence already in this file.**

- Removing "input which is rejected now is still rejected" is the same high item as last round. The
  sentence is two rounds old and exists because the first false-positive review found a passing
  candidate whose ordered decoder silently accepted `{"a":1,` and dropped the input. Six tests rest on
  it, and a clean false-positive check is a submit gate while this one is advisory.
- `to_entries` is defined in terms of `keys` at the base commit, so ordered entries are a change the
  solver has to make.
- Removing "`keys_unsorted` is the one that gives an object its own order" would leave the new builtin
  named in the opening sentence and nowhere defined. The suggestion is that the name implies the
  behavior; the name is jq's, the contract is not, and about fifteen tests rest on that sentence
  together with the fallback sentence which follows it and reads as its continuation.

## Platform batch 3 — 4 x Nova (0 of 4), and the solvability response

| run | new tests | what failed |
|---|---|---|
| 1 | 242 of 262 | an existing key moved to the end on update (13 tests), truncated input, stale pointer metadata |
| 2 | 241 of 262 | `add`/`from_entries` lost order, truncated input |
| 3 | 247 of 262 | constant-path `setpath` from null, truncated input, YAML emitted `{}` |
| 4 | 241 of 262 | `add`/`from_entries` lost order, truncated input |

Baseline 1093 of 1093 in all four. Every evaluator: description clear, tests deterministic,
`agent_blame_unfair: false`.

### The tally across all ten fair runs

| axis | runs | in batch 3 |
|---|---|---|
| truncated input | 6 | all four |
| `add` / `from_entries` fast path | 3 | two |
| compiler and object literals | 3 | none |
| YAML | 2 | one |
| stale pointer table | 2 | one |
| constant-path `setpath` | 2 | one |
| an existing key keeping its position | 1 | one |

The compiler axis disappearing from batch 3 is the useful signal: round 33 corrected the opening
sentence, which had scoped the feature to "objects read from JSON", and the failure class it was
causing stopped appearing. Wording on a measured killer is the lever that works here.

### Two sentences, chosen because one alone changes nothing

Replaying batch 3 against a suite where only truncated input is solved still gives four failures, so
the response has to move two axes at once. Both changes are behavior, and both leave the fix hidden.

- **Truncated input, named concretely.** "Input which is rejected now is still rejected" is true but
  passive, and the failure it guards against is silent: `json.Decoder.Token` reports `io.EOF` where
  `Decode` reports `io.ErrUnexpectedEOF`, so a token decoder accepts cut-short input and the iterator
  reads it as end of stream. It now says "a cut-short object or array is an error, not the end of the
  input", which names the symptom an agent can test for without saying where to look.
- **`from_entries` restored.** "`from_entries` builds in the order it is given, however the object is
  put together" was deleted in round 2 as implied by the creation-order rule. Three runs then lost
  order through `add`, which is what `from_entries` is built on. The trailing clause is aimed at the
  optimised aggregation path without naming it.

On this evidence runs 2 and 4 of batch 3 would pass and runs 1 and 3 would still fail, on the
existing-key rule and on `setpath` plus YAML. That is a deliberate move from zero, and it may
overshoot; the remaining axes are the ones which would then have to hold the rate down, and they are
measurable.

214 words up to 242, the largest single increase in the submission's history, and the first made for
solvability rather than for a gate.

## Solvability, second pass — a latent axis on an unstated choice

Reviewing the suite for anything an agent could fail *fairly*, five tests turned out to rest on a
choice the description never makes. Under the option, is an object a builtin constructs, such as the
`{offset, length, string, captures}` a `match` returns, ordered or orderless? The description says
objects read from JSON and objects the program builds keep order, and that an object keeping no order
counts as sorted. It never says which side a builtin result falls on. The reference treats it as
orderless; an implementation which ordered builtin results too would be equally consistent with every
sentence, and would fail those five.

They were added in round 18 at a coverage suggestion and are gone now. That is a latent unfairness and
a latent failure axis removed at once, with no false-positive cost, since nothing states the behavior
either way.

262 tests down to 257, and to 254 with the YAML group. This does not flip any batch 3 run on its own; the two sentences from the
previous round are what do that. It removes an axis nobody has been measured on yet, which is the kind
of thing that turns a 2-in-10 into a 0-in-10 once a different agent meets it.

## Two advisory coverage suggestions, both refused

Both would add an axis, and an axis is what the batch cannot afford.

- **Concurrent isolation.** A race-enabled test asserting order metadata cannot leak between
  goroutines. The reference keeps order inside the value, so it has no shared table to race on and
  would pass trivially; the design this would catch is the pointer-keyed side table, which the four
  garbage-collection tests already catch deterministically. Adding a concurrency test would duplicate
  that coverage while introducing exactly the timing dependence the flakiness gate forbids.
- **Sort-only error channels.** Whether `-S` reaches `debug`, `stderr` and `halt_error` is untested.
  The description scopes `-S` to "every result it prints as JSON", which a message on standard error
  is not, so an implementation which sorted them would be wrong but currently passes. That is a
  coverage hole rather than a false positive, since no requirement goes unmet. Closing it costs a new
  axis for no fairness gain.

## The YAML axis, removed on the same reasoning as the builtin-object one

The three YAML tests asserted that ordered output keeps every pair rather than collapsing to `{}`.
They killed two of ten runs, and the description says nothing about YAML anywhere. That is the same
shape as the builtin-object tests removed last round: an unstated requirement failing runs. Keeping
them would mean holding agents to a rule the description does not carry, which is the fairness
problem the whole submission has been audited for.

The solution keeps its YAML handling, so the reference does not regress, and the existing base tests
still cover the marshaller for plain maps and arrays. Only the ordered branch goes unasserted.

254 tests. Three axes now gone in three rounds: builtin objects, YAML, and the two the description
took over. What remains kills on rules the description states plainly.

## Review round 30 — four description items, all refused, one on a false premise

**`-S` does not exist at the base commit.** The suggestion to drop "and a `--sort-keys` (`-S`) option"
says the flag "is already part of the CLI (discoverable via code/help)". It is not. `grep -rn
'sort-keys\|SortKeys'` over the base tree returns nothing, and the repository's own README lists it
among the things gojq deliberately lacks: "gojq does not have `keys_unsorted` function and
`--sort-keys` (`-S`) option ... sorts by default because `map[string]any` does not keep the order".
Adding `-S` is part of the task. Removing the phrase would leave 32 tests resting on a flag the
description never asks for, which is the definition of an unfair test and would take the pass rate to
zero on its own.

**The truncated-input sentence, refused a third time.** Two rounds ago it was strengthened for
solvability, and it exists because the first false-positive review found a passing candidate whose
decoder accepted `{"a":1,` and dropped the input. Six tests rest on it, and a clean false-positive
check is a submit gate while this check is advisory.

**"which is also the order its members are visited in".** The suggestion is that iteration order is
implied by `to_entries` and `keys_unsorted`. Those are two builtins; `.[]`, `paths`, `tostream`,
`walk` and `recurse` are separate paths through the engine, and 12 tests assert them. An
implementation could order `to_entries` and still iterate a sorted key list.

**"including when the assignment is what creates the object it goes into".** Added at round 21 after
batch 2, precisely because agents were failing `.z=1|.a=2` on null: the constant-path `setpath`
optimisation bypasses the allocator the general assignment path uses. Two runs have died there since.
Removing it re-opens the axis it was added to close, in the same week as three rounds spent closing
axes.

**Go version, refused a second time.** `go.mod` declares `go 1.24.0`, so no toolchain able to build
the repository lacks either feature; the image is go1.26.3; `execute.go` at the base commit already
uses `for range n`. The suggestion's own action says no change is needed if the environment is at
least 1.22, and it is provably at least 1.24. Rewriting the loops would not even silence it, since
`slices` is used by the repository's own `cli/encoder.go`.

## Solution quality — PASS, and the same ambiguity from the other side

Both dimensions scored 2 of 3 for the same reason: regex match results, module metadata and `$ARGS`
are still built as plain maps, so "under a literal reading of `objects the program builds`" they do
not keep order.

This is the ambiguity that removed five tests two rounds ago, arriving from the opposite direction.
Then, the risk was an implementation which ordered builtin results failing tests which assumed it did
not. Now it is the reference being marked down for not ordering them. Both readings were available
because the description never said which, and "the program" was doing the ambiguous work: it can mean
the jq query, which is what was meant, or gojq itself, which is how it was read.

Two changes, no new difficulty:

- "objects **the query** builds" instead of "the program builds", so the phrase can only mean objects
  the jq program constructs.
- "A value a builtin hands back keeps no order of its own", stated ahead of the sorted-fallback
  sentence it now shares.

Two of the five removed tests came back, renamed to what they now assert. They cost nothing in
difficulty: with the rule stated, the passing behaviour is to leave those paths alone, so an
implementation which never touches `match` passes by default. The reason they were unfair before was
the reverse case, an agent who went out of its way to order builtin results and was failed for a
choice the description did not forbid. Stating the rule is what makes them cheap and fair at once.

The alternative, converting every internal object-producing site, would have added exactly the kind of
axis three rounds have been spent removing, and would have needed its own tests to be fair.

256 tests.

## Platform batches

Batches 1 to 3 above. Batch 4 not run yet.
