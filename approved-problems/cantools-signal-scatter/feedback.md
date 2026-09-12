# cantools-signal-scatter — authoring log

## Summary

Olympus, feature-request. Repo `cantools/cantools` at `f74f76888d2c88329266b33947aa6ea534ddd213`
(MIT, 2259 stars, last commit 2026-07-29, 35k Python LOC). Feature: scatter a flat signal name to
value mapping across the frames that carry it (`Database.encode_signals`), merge frames back into one
mapping (`Database.decode_frames`), re-encode existing frames with signals changed
(`Database.reencode_frames`), plus a `cantools encode` CLI subcommand.

Status: locally validated end to end, platform checks answered (R2). No agent batch has been run yet.

## Repo choice (autonomous discovery — user defers)

Standing preference: a repo never used locally and a genuinely hard new feature. Candidates ranked:

| Repo | Stars | License | Verdict |
| --- | --- | --- | --- |
| cantools/cantools | 2259 | MIT | **picked** — niche automotive domain, deep encode/decode engine, integer-exact output, 8s deterministic offline suite |
| jhump/protoreflect | 1486 | Apache-2.0 | protobuf is a training-saturated spec |
| georust/geo | 1903 | dual | float output, fragile exact assertions |
| egraphs-good/egg | 1794 | MIT | famous in PL circles, small LOC ceiling |
| matthewwardrop/formulaic | 460 | MIT | under the 500 star gate |
| construct/construct | 1012 | NOASSERTION | last commit 2025-04, fails the recency gate |
| ariga/atlas | 8622 | Apache-2.0 | 8.6k stars, the obvious host for schema tooling: presumed globally saturated |

cantools appears in none of `problems/`, `rejected/`, `Instructions/Aprroved/`, `Olympus/problems/`,
`Task1..Task18/problems/` or `Starter/worktrees/`.

## Pick-filter gates

1. BEHAVIORAL-F2P-GAP — net-new capability; no composition of existing primitives produces it
   (`gather_signals` requires the multiplexer value in the input and raises on any missing signal).
2. SATURATION — the transform is invented, not a port of a reference.
3. UNIFORM-WRAP — five interdependent traps, three of them in one kernel (see below).
4. LOC-CEILING — 754 raw / 477 human-effective measured.
5. COLD-NOT-LIVE — `message.py` / `utils.py` last saw semantic change 2026-06; current maintainer work
   is a `dbc.py` cleanup series, which the patch does not touch.
6. REPRODUCE-ON-BASE — n/a for a feature; F2P verified (155 of 155 fail on base).
7. DEDUP — no cantools problem in any local directory; nearest local sibling by shape,
   `iso8583-message-validation`, is a validation contract over one message.
7b. EXCLUSIVITY — canonical org resolved (`cantools/cantools`, no move). `gh pr list --state all`
   for `encode_signals`, `gather_signals`, `scatter`, `multiplexer selection`, `flat signal
   dictionary`, `encode multiple messages`: zero hits implementing this capability.
8. DEFINED-BEHAVIOR — invented, so the description defines it end to end.
9. NO-FLAKY-REPO — baseline suite run 3x locally and 5x in the image: 413 pass every time.
10. REPO-QUOTA — 0 of ours. Risk logged below.

## Traps

1. One frame per needed multiplexer value, not one per message. The natural loop encodes each message
   once and silently drops the signals of the other values.
2. Signals outside the multiplexed part repeat on every frame of that message. Surfaces only after
   trap 1 is fixed, and the natural fix for trap 1 (partition the named signals per value) breaks it.
3. Filled in signals take the value their **raw** zero stands for, and a forced multiplexer value is
   raw as well. `signal.initial or 0` reads as a physical zero and gives different bytes whenever the
   offset is not zero; in the test database it also lands outside the signal's range.
4. A name several messages carry goes into each of them; first-match lookup emits one frame.
5. Container frames split greedily on the container's length; the obvious code emits one frame.

Trap 3 is the "obvious code is wrong" edge, and traps 1 to 3 share one kernel so a local fix to one
regresses another. The failing assertion is always a byte comparison or a missing key, never a hint
that more frames are needed.

## Assumptions and deviations (autonomous run)

- `meta.md` is 697 words by `wc -w`, under the 700 word cap the user set. Every
  clause is backed by at least one of the 155 tests, and each of the three coverage rounds added
  behavior that had to be stated to stay fair. This is the one number outside the approved band.
- `DESIGN.md` sketched a `typechecking.py` edit; the type aliases ended up in `frame_set.py` instead,
  so the patch touches 5 files rather than 6.
- An `invalid` keyword (fill unnamed signals with the database's invalid value) was implemented and
  then removed: it cost about 30 description words for 19 effective LOC and widened the surface the
  LOC hook already flagged as breadth-leaning.
- `Message.carries_any` and `Message.carried_signal_names` are public but not described in `meta.md`
  and not asserted by any test; they exist because `Database` needs them.
- `system-4.2.arxml` declares `MultiplexedStatic` with an initial value of 7 in a 3 bit signed field,
  which cantools cannot encode at all. Tests avoid that signal; the behavior is left undefined.

## Risks

- cantools is the obvious Python host for the CAN database category. Our gates cannot see the global
  submission count, so verify it on the platform's repo page before submitting (the cattrs and
  prompt_toolkit kills came from exactly this blind spot).
- The container axis rests on one AUTOSAR fixture plus synthetic databases built in Python.

## Validation

| Check | Result |
| --- | --- |
| `test.sh base` on base + test.patch | 413 pass |
| `test.sh new` on base + test.patch | 155 of 155 fail |
| `test.sh base` with solution | 413 pass |
| `test.sh new` with solution | 155 pass |
| test.patch then solution.patch | both apply |
| solution.patch then test.patch | both apply |
| `git apply -R` both | clean |
| Docker offline, `--network none --user 1000:1000` | both modes green |
| 3 consecutive Docker runs after R31 | identical |
| human-effective LOC | 551 across 5 files, 855 raw |
| ruff + mypy on `src/` | clean |
| banned test filename markers | none |
| meta.md encoding | ASCII, no em dashes |

## Attempt history

- R1 (2026-08-03) — design, implementation, 62 tests, Dockerfile, patches, full local validation.
  Effective LOC walked 331 -> 376 -> 418 -> 467 -> 448 as the reencode axis, qualified names, CAN data
  length padding and the CLI were added and the `invalid` knob was dropped.
- R2 (2026-08-03) — platform checks. Test Fairness FAIL (3 of 63 unfair), description "only necessary
  information" request_changes (1 high, 3 medium/low), alignment WARNING (2 interface details), 4
  coverage suggestions. All fixed, see below. 66 tests now.

## R2 — platform check responses

Fairness (blocking, all three fixed in `meta.md`, no test relaxed):

1. `Message.encode_signals` returning `[]` for a name it does not carry was unstated and read as a
   conflict with the database level "unknown key is an error". The description now ends that sentence
   with "ignoring any name that message does not carry", which also fixes alignment warning 2 by
   saying it gives back "a list of the data alone".
2. `DecodeError` for an unknown identifier contradicted the repo convention (`get_message_by_frame_id`
   raises `KeyError`). The description now names `DecodeError` outright.
3. `reencode_frames` inherited the same unstated policy. The description now says it takes frames the
   way `decode_frames` does and fails the same way, which also fixes alignment warning 1 (both input
   forms).

`EncodeError` is now named once on the encode side for the same reason.

Description check:

- HIGH "remove `exported from cantools.database`, not required by tests" — kept, and made
  test-required instead: `test_encoded_frame_is_exported_with_its_fields` asserts the export, the
  returned type and `_fields`. That was also coverage suggestion 1, so the two findings resolve
  together. The finding's premise (no test needs it) no longer holds.
- MEDIUM "drop the database-order tie breaker" — kept for the same reason, now covered by
  `test_messages_with_one_identifier_keep_database_order`, which was coverage suggestion 2.
- MEDIUM "drop the round trip restatement" — accepted, removed. The behavior follows from the encode
  and decode rules and `test_decode_frames_gives_every_named_signal_back` still covers it.
- LOW "drop the CAN data length list" — rejected. The reviewer assumed the list is discoverable in
  code; `grep` over the repo finds no such table, so removing it would make the requirement
  codebase-uninferable.

Coverage suggestions, all four added:

1. `test_encoded_frame_is_exported_with_its_fields`
2. `test_messages_with_one_identifier_keep_database_order`
3. `test_filling_climbs_the_can_data_length_ladder` (13 -> 16 and 33 -> 48, was only 9 -> 12)
4. `test_encode_command_reads_every_line` (two stdin lines, one with a choice string)

## R3 — second coverage round (5 suggestions, all added)

Suggestion 3 (container reencoding) exposed a real defect rather than a gap in the tests:
`reencode_frames` rebuilt a container frame from the messages carrying a named signal instead of the
messages that frame actually held, so an unmodified contained message was dropped from its frame and
a named one was injected into a frame that never carried it. `Message.encode_signals` now takes an
`only` restriction, `Database.reencode_frames` fills it from `unpack_container`, and the "touched"
test is frame scoped for containers. `meta.md` gained one sentence: "A container frame is encoded
again from exactly the messages it held."

New tests, on a synthetic container holding a multiplexed message plus a plain one:

1. `test_unknown_plain_and_joined_keys_are_listed_together`
2. `test_multiplexed_contained_message_fans_out_in_one_frame` and
   `test_fanned_out_contained_messages_split_on_length`
3. `test_reencode_keeps_the_contained_messages_a_frame_held`,
   `test_reencode_moves_a_contained_message_to_another_value`,
   `test_reencode_repacks_a_container_which_no_longer_fits`
4. `test_last_frame_wins_across_a_container_and_a_message`
5. `test_reencode_without_scaling`

74 tests. `meta.md` is 618 words.

## R4 — third coverage round (4 suggestions, all added)

No defect this time; the solution already behaved correctly in every case.

1. `test_message_encode_signals_covers_multiplexing` and
   `test_message_encode_signals_covers_containers` — the direct `Message.encode_signals` coverage was
   an ordinary message only.
2. `test_encode_command_widens_an_extended_identifier` — uses `multiplex.dbc`, whose extended
   identifier 0x123456 needs all eight digits, instead of the cascaded fixture's id 1.
3. `test_encode_command_rejects_a_malformed_item` and `test_encode_command_rejects_an_unknown_name` —
   both assert the offending token reaches the user. `meta.md` gained one sentence: "An item in any
   other shape fails the command, as does a name no message carries."
4. `test_filling_leaves_an_exact_can_data_length_alone` (8, 12 and 64 byte frames) and
   `test_filling_leaves_a_frame_past_the_ceiling_alone` (68 bytes, above the 64 byte ceiling).

81 tests. `meta.md` is 634 words.

## R5 — fairness round 2 plus a fourth coverage round

Fairness (2 of 81 unfair):

1. `test_filling_leaves_a_frame_past_the_ceiling_alone` pinned an unstated, nonstandard policy: the
   ladder in the description ends at sixty four and CAN FD has no larger payload, so leaving a sixty
   eight byte frame alone is only one reasonable answer. Test deleted rather than defining
   nonstandard behavior. The `pad_frame_data` fallback for a frame past the ceiling is now the only
   untested branch in the patch.
2. `test_encode_command_rejects_a_malformed_item` required the offending token in the exit text while
   the description only said the command fails. The description now says it fails "naming it", which
   the third coverage suggestion below also asks for.

Coverage suggestion 3 (`--set` validation) exposed a second real defect: `reencode_frames` never
checked its keys, so an unknown `--set` name was silently ignored instead of failing as it does for
`encode_signals`. Both entry points now share `_assert_signal_names_known`, and the description says
reencode takes "keys the way `encode_signals` does".

New tests:

1. `test_message_encode_signals_takes_joined_keys` (joined key precedence and a key aimed at another
   message, at the message level)
2. `test_reencode_rejects_a_value_out_of_range`, `..._an_undefined_choice_string`,
   `..._a_name_no_message_carries`, `..._a_multiplexer_value_which_selects_nothing`
3. `test_encode_command_takes_several_set_items`, `..._rejects_a_malformed_set_item`,
   `..._rejects_an_unknown_set_item`

88 tests. `meta.md` is 630 words.

## R6 — fairness round 3 plus a fifth coverage round

Fairness (13 of 88 unfair), all three causes were description gaps, no test relaxed:

1. Eleven tests reach through `frame.message.name` or assert object identity. The description named
   the `message` field but never said what it holds, so storing a name string was an equally valid
   reading. It now reads "a named tuple exported from `cantools.database` holding the `message` it
   belongs to, that message's `frame_id`, and its `data`".
2. `test_encode_command_prints_a_line_per_frame` puts two assignments on one stdin line. The
   description now says "the white space separated `Name=Value` items on each line".
3. `test_encode_command_takes_several_set_items` repeats `--set`. The description now says the
   `--set` items "may be given more than once".

The opening motivating sentence was dropped to pay for these words, which the corpus supports:
`gojq-ordered-keys` opens straight into "Add an `--ordered-keys` option".

New tests:

1. `test_message_encode_signals_forwards_its_options` (`scaling=False` and `padding=True` at the
   message level)
2. `test_reencode_takes_a_joined_key_over_a_plain_one`
3. `test_encode_command_updates_an_extended_identifier`

91 tests. `meta.md` is 632 words.

## R7 — sixth coverage round (4 suggestions, all added)

Suggestion 3 (malformed candump input under `--update`) exposed a third real defect: `_update_frames`
filtered out every line `logreader.Parser` could not parse, so a typo in a log silently produced
fewer frames than the input held. It now raises on any non-blank line that is not a frame, and the
description's CLI failure sentence covers both input paths: "An item, or a frame line under
`--update`, in any other shape fails the command naming it."

New tests:

1. `test_no_frame_comes_back_when_a_key_is_unknown` (valid and invalid keys in one call, every
   invalid one named, nothing returned)
2. `test_decode_frames_of_nothing_gives_nothing` and
   `test_decode_frames_scales_and_names_choices_by_default`
3. `test_encode_command_rejects_a_line_which_is_not_a_frame`
4. `test_contained_message_starts_a_new_frame_at_the_ceiling` (44 and 36 byte frames from a 64 byte
   container) and `test_frames_at_the_ceiling_are_filled_to_a_can_data_length` (both filled to 48)

97 tests. `meta.md` is 638 words.

## R8 — seventh coverage round (4 suggestions, all added)

Suggestion 3 (malformed assignment variants) needed a decision rather than just a test: `=1`,
`Name=` and `Name=1=2` all used to reach `encode_signals` and fail there, naming the signal instead
of the item, which does not match "fails the command naming it". An item is now exactly one equals
sign between a non-empty name and a non-empty value, and the description says so: "An item which is
not a name and a value around a single equals sign, or a line under `--update` which is not a frame,
fails the command naming it."

New tests:

1. `test_plain_frame_is_filled_to_a_can_data_length` (a nine byte ordinary message, unpadded and
   padded to twelve)
2. `test_reencode_lists_every_key_it_cannot_resolve`
3. `test_encode_command_rejects_an_item_of_another_shape` and
   `..._a_set_item_of_another_shape`, each over all three malformed shapes
4. `test_both_frame_forms_can_be_mixed` (one list holding an `EncodedFrame` and a pair, through both
   `decode_frames` and `reencode_frames`)

102 tests. `meta.md` is 651 words.

## R9 — eighth coverage round (2 suggestions, both added)

Suggestion 2 exposed the worst defect of the run. Filling a container frame with the message's unused
bit pattern produced frames `unpack_container` cannot read: it walks the buffer looking for headers,
so a four byte or longer tail of `0x55` reads as a header with length 0x55 and raises. A three byte
tail happened to be ignored, which is why every earlier padded container test passed. The
description's own round trip law was therefore false for padded containers whenever the filling
reached four bytes. Frames are now filled with **zeros**, which read back as an empty entry the
decoder skips, and the description says "each frame is filled with zeros up to the next CAN data
length". Unused *bits inside* a message still take its unused bit pattern, which is what that field
means in cantools.

Suggestion 1 was a second real gap: `reencode_frames` dropped a contained entry whose header the
database does not know, so re-encoding a frame lost data. `pack_container` now carries raw entries
alongside decoded ones, and the description says a container frame is encoded again "from exactly
what it held, an entry it cannot place kept as it is and its filling dropped". The filling clause is
needed because zero filling unpacks as an empty entry, which must not be re-emitted as content.

New tests:

1. `test_reencode_keeps_a_contained_payload_it_cannot_place`
2. `test_reencode_repacking_crosses_a_can_data_length` (a 32 byte frame becoming 32 and 16 under
   padding) and `test_reencode_repacking_without_padding` (28 and 14)

Both padded-frame tests now also decode what they encoded, which is what would have caught this.

105 tests. `meta.md` is 665 words.

## R10 — ninth coverage round (2 of 3 added, 1 declined)

Suggestion 2 was another real defect, and an embarrassing one: `cantools encode` prints
`identifier#data`, but `--update` fed that back rejected it. cantools' `logreader` has no bare
`identifier#data` pattern; its log form needs a timestamp and a channel. So the command could not
read its own output and `cantools encode | cantools encode --update` failed. `--update` now accepts
the printed form as well, parsed in the subcommand rather than by touching the shared `logreader`,
and the description says it reads "candump frames instead, the lines it prints itself included".

Suggestion 1 is covered by `test_reencode_drops_the_filling_of_its_source`: a source frame carrying
an unknown raw entry, a known entry and four bytes of zero filling comes back fifteen bytes long with
the unknown entry in place and the filling gone.

Suggestion 3 (malformed frame tuples) is DECLINED, on its own terms: it asks for this "if the
intended public error semantics are documented", and they are not. A pair of the wrong shape or with
data that is not bytes raises whatever Python raises, and pinning `ValueError` or `TypeError` in the
description would be over-specification of behavior no caller should rely on. Worth noting the
accepting side already works: `bytearray` and a list of integers both decode, because the
implementation calls `bytes()` on the data. That is left unstated and untested rather than pinned.

New tests: `test_reencode_drops_the_filling_of_its_source`,
`test_encode_command_reads_back_what_it_printed`, `test_encode_command_reads_back_an_extended_line`.

108 tests. `meta.md` is 671 words.

## R11 — tenth coverage round (2 suggestions, both added)

No change to the solution: both paths already behaved correctly.

1. `test_container_header_follows_its_byte_order` builds the same contained message under a big
   endian and a little endian container and asserts the header bytes come out `112233` and `332211`.
   The scatter and reencode paths never touch the header; they hand the entries to the repository's
   own `Message.encode`, which is what the suggestion asked to confirm.
2. `test_identifier_then_database_order_then_combinations` puts all three comparator levels in one
   scenario: three messages, two sharing identifier 0x50, one of those fanning out over two
   multiplexer values. The order is Cee 0x40, then both Bee frames in combination order, then Ay,
   because Bee comes before Ay in the database.

⚠ Found while testing, NOT fixed: `Message.unpack_container` reads the contained header with
`int.from_bytes(data[pos:pos+3], 'big')`, ignoring `header_byte_order`, while `_encode_container`
honours it. A little endian container therefore encodes correctly and decodes to nothing, in the
repository as it stands. This is a pre-existing cantools bug on the base commit, not something this
patch introduces, and fixing it would change `Message.decode` for existing users, so it is left
alone. The new test asserts only the encoded bytes for the little endian case, and the description
makes no round trip promise, so nothing here is unfair. It is worth knowing about if a solver goes
looking.

110 tests.

## R12 — eleventh coverage round (3 suggestions, all added)

No change to the solution again; all three paths already behaved correctly.

1. `test_joined_key_wins_inside_the_message_it_names` uses a container whose two featured messages
   both carry a signal called `Shared`. With `{'Shared': 1, 'PartB.Shared': 7}` the frame comes out
   `0000110201000000220107`, so `PartA` took the plain value and `PartB` the joined one. The
   assertion is on the bytes because both entries land in one frame and the decoded mapping keeps
   only the last of the two.
2. `test_encode_command_leaves_a_frame_it_does_not_touch` sets `S9`, which `multiplex_2.dbc` carries
   on `ExtendedTypes` but not on the `Normal` frame given, so the line comes back byte for byte.
3. `test_decode_frames_of_a_container_without_choices` and `..._without_scaling` show both options
   reaching the contained messages: `Seven` versus `7`, and physical 20 versus raw 5.

114 tests.

## R13 — twelfth coverage round (4 suggestions, all added)

Suggestion 2 found the last real gap, the same class as the unknown-entry one from R9 but a step
subtler: a container entry whose header resolves to a KNOWN message but whose payload is not that
message's length was decoded to nothing, then re-encoded from defaults at the declared length. A two
byte `beef` payload for a five byte message came back as five zero bytes. `reencode_frames` now keeps
such an entry raw, which is what the description already promised: "an entry it cannot place kept as
it is". No description change, the code simply did not match the sentence.

The other three needed no solution change:

1. `test_reencode_leaves_an_untouched_frame_unfilled` pins the precedence: a frame whose message
   carries none of the names comes back byte for byte even under `padding=True`, because "untouched"
   wins over filling.
3. `test_encode_command_reads_negative_and_exponent_values` and
   `..._ignores_surrounding_white_space` cover `-5`, `1.5e3` and a line padded with spaces.
4. `test_encode_command_rejects_a_malformed_printed_line` covers odd length data, a missing
   identifier and non hexadecimal data, each naming the whole line.

119 tests.

## R14 — thirteenth coverage round (2 of 3 added, 1 declined again)

Suggestion 3 was a genuine unstated behavior: both CLI modes already passed over blank stdin lines,
but nothing said so, so a test pinning it would have been unfair. The description now ends with "A
blank line is passed over", and `test_encode_command_passes_over_blank_lines` covers both modes.

Suggestion 1 needed no decision: a joined key naming this message but a signal it lacks is a "name
that message does not carry", which the description already tells `Message.encode_signals` to ignore.
`test_message_encode_signals_ignores_a_joined_key_it_lacks` pins the pair of behaviors that makes the
split explicit, the message level ignoring it and the database level erroring on the same key.

Suggestion 2 is DECLINED for the second time, on the same grounds and for the same reason it was
raised conditionally: there are no defined exception semantics for a malformed frame tuple, and
inventing them would mean pinning `ValueError` or `TypeError` for a caller mistake. Nothing in the
description promises anything about wrongly shaped input, so no test can be unfair here, and no agent
can pass by getting it wrong.

121 tests. `meta.md` is 677 words.

## R15 — fourteenth coverage round (2 of 3 added, 1 declined a third time)

No solution change and no description change; both added behaviors follow from clauses already
written.

2. `test_encode_command_updates_nothing_without_a_set` covers `--update` with no `--set` at all.
   Every frame carries none of the (empty set of) named signals, so every frame comes back untouched
   and is reprinted in the form this command uses. This is the reencode untouched rule applied to an
   empty mapping, not a new behavior, so rejecting the invocation would be wrong.
3. `test_filling_reaches_the_top_of_the_ladder` takes a sixty byte frame to sixty four under padding
   and decodes it back, and `test_contained_message_over_a_full_container_is_an_error` puts a sixty
   one byte contained message in a sixty four byte container, which cannot fit even an empty frame.

Suggestion 1 is DECLINED a third time. It has been raised in R10, R14 and now R15, each time
conditioned on the exception behavior being documented, and it is not. Adding a defined exception
for a wrongly shaped tuple would be inventing contract for a caller mistake, and since the
description promises nothing there, no test can be unfair and no agent can pass by getting it wrong.
This is a settled decision, not an oversight.

124 tests.

## R16 — fifteenth coverage round (3 suggestions, all added)

No solution change and no description change; all three follow from clauses already written.

1. `test_encode_command_updates_every_line_in_order` sends two different candump lines through
   `--update` and checks both come back updated, in input order.
2. `test_reencode_of_nothing_keeps_every_frame` passes an empty mapping to `reencode_frames` for both
   a container and an ordinary database, asserting the payloads, the identifiers and the message
   object itself all survive, not only the bytes.
3. `test_reencode_gives_nothing_back_when_a_later_frame_is_unknown` puts an unknown identifier after
   two good frames and confirms `DecodeError` with nothing returned. The frames are built one at a
   time into a list which the raise discards, so a partial result is impossible by construction.

127 tests.

## R17 — sixteenth coverage round (3 suggestions, all added, one earlier decline reversed)

Suggestion 2 asked a fourth time for malformed frame input, and this time prescriptively: document
the exception rather than leave validation implicit. REVERSED my three earlier declines, and they
were wrong. I had been treating two different options as one: pinning `ValueError` or `TypeError`,
which really would be over-specifying a caller mistake, versus raising our own named error, which is
plain API quality and removes the ambiguity for good. `split_frame` now raises `DecodeError` naming
the offending item for anything that is neither an `EncodedFrame` nor an identifier and data pair,
the description says so, and `test_frame_of_another_shape_is_an_error` covers four shapes through
both entry points. Cost was six lines and eleven words, which is much less than three rounds of
argument.

The other two needed no solution change:

1. `test_encode_command_takes_joined_keys` and `..._prefers_a_joined_key` put `Message.Signal` keys
   through both CLI modes, the second proving the joined key beats the plain one for that message.
3. `test_filling_stops_at_the_middle_ladder_steps` fills an eighteen byte frame to twenty and a
   twenty two byte frame to twenty four, the two ladder steps no test had touched.

131 tests. `meta.md` is 690 words.

## R18 — fairness round 4 plus a seventeenth coverage round

Fairness (1 of 131 unfair), and it was self inflicted from the round before:
`test_frame_of_another_shape_is_an_error` pinned the literal phrase "Expected a frame", which nothing
states. Adding the defined error in R17 was right; asserting my own wording for it was not. The test
now asserts only that the offending item is named, using a fragment identical under `str` and `repr`
(`512` for the tuples, `nope` for the string) so a solver formatting the item either way passes. The
description gained "named as it was given" to make that requirement explicit rather than assumed.

Coverage:

1. `test_encode_command_rejects_an_unknown_identifier` sends a syntactically valid frame whose
   identifier the database lacks through `--update`, and the command fails naming `0x123`.
2. Duplicate keys on one line were genuinely unstated: `Name=Value` twice built a dictionary, so the
   later value silently won. The description now says "an item repeating a name takes the later
   value" and `test_encode_command_takes_the_later_of_two_same_names` covers it.

133 tests. `meta.md` is 705 words.

## R19 — fairness round 5: the container filling rule was unspecifiable, removed

Both unfair tests rested on the same impossible discrimination, and the check is right: four trailing
zero bytes in a container are SYNTACTICALLY IDENTICAL to a valid unknown entry with header id 0 and
length 0. `unpack_container` parses them as `(0, b'')` and keeps them. No byte level rule can tell
padding from that entry, so "filling dropped" could never be specified, only guessed. Note the check
passed `test_reencode_repacking_crosses_a_can_data_length` on the same bytes purely because they
happened to be genuine 28 to 32 padding, which shows how fragile the distinction was.

Fixed at the root rather than patched: **a container frame is never filled**. There is then no
filling to recognise or drop, `reencode_frames` keeps every entry `unpack_container` yields, and the
ambiguity cannot arise. The description now says a frame "which is not a container" is filled, and
the reencode sentence no longer mentions filling. Losing padded containers costs nothing real, since
a container padded with anything is exactly what cantools cannot decode.

This was my rule, introduced in R9 to fix the earlier undecodable-padding bug, and it traded one
container padding defect for another. The lesson: when a fix requires the reader to distinguish two
byte sequences that are identical, the rule is wrong, not the wording.

Test changes:

- every CAN data length ladder test moved onto ordinary messages, where the tail is not parsed as
  entries and filling is unambiguous: 13 to 16, 33 to 48, 18 to 20, 22 to 24, 60 to 64, and 8, 12
  and 64 left alone
- `test_container_frame_is_never_filled` and `test_container_frames_at_the_ceiling_keep_their_length`
  replace their padded counterparts
- `test_reencode_keeps_every_entry_a_frame_held` inverts the old filling test
- `test_reencode_keeps_an_entry_whose_payload_does_not_fit` lost its trailing zeros, so it now tests
  only the malformed entry
- `test_reencode_repacking_keeps_container_lengths` replaces the padded repacking test

Coverage, both added:

- `test_encoded_frame_is_named_in_the_package_exports` asserts `__all__` membership and identity
- `test_frame_with_a_payload_of_the_wrong_size_is_an_error` covers a truncated payload behind a valid
  pair, through both entry points

135 tests. `meta.md` is 706 words.

## R20 — eighteenth coverage round (4 suggestions, all added)

Suggestion 2 found a real hole, and a round trip one. `decode_frames` resolved every frame by
identifier alone, discarding the `message` an `EncodedFrame` carries. In a database with two messages
on one identifier, encoding `{'F0': 1, 'S0': 2}` produced a correct frame each, but decoding them
gave `{'F0': 1}`: the `Second` frame was read with `First`'s layout, so `S0` vanished and its byte was
misread. `split_frame` now returns the message as well, both entry points use it when the frame
carries one, and the description says a frame given as an `EncodedFrame` is read with the message it
holds while a pair goes by its identifier. Since I already test database order tie breaking, duplicate
identifiers were plainly in scope and this should not have survived nineteen rounds.

The other three needed no solution change:

1. `test_filling_walks_the_whole_can_data_length_ladder` covers 24, 25, 32, 33, 48 and 49, so every
   listed step and the transition into it now has a case.
3. `test_encode_command_rejects_a_value_out_of_range` and `..._an_undefined_choice_string` show
   `EncodeError` reaching the user through both CLI modes with the signal named.
4. `test_decode_frames_of_a_container_running_past_its_frame` pins the existing `unpack_container`
   behavior for an entry whose declared length overruns the frame.

140 tests. `meta.md` is 724 words.

## R21 — nineteenth coverage round (2 suggestions, both added)

No solution change and no description change; both follow from clauses already written.

1. `test_encode_command_takes_the_later_of_two_set_items` repeats a name across two `--set` options
   and the later one wins, matching the duplicate name rule the description already gives for items.
2. `test_encoded_frame_beats_the_identifier_lookup` answers the open half of the suggestion by
   testing rather than restricting: an `EncodedFrame` holding a message from a DIFFERENT database is
   still decoded with that message, giving `AY=8` where the identifier lookup alone would give
   `HX=4`. That is the plain reading of "read with the message it holds", and it is the useful
   behavior for a gateway juggling several databases, so rejecting foreign messages would be a
   restriction with no reason behind it.

142 tests.

## R22 — fairness round 6 plus a twentieth coverage round

Fairness (2 of 142 unfair), and the same mistake I named after R18: both container overflow tests
required the exception text to contain `PartA`, which nothing states. The check offered two fixes and
I took the cheaper one, asserting only `EncodeError`. The solution still names the entry, agents just
are not required to. Adding "naming it" to the description would have worked too, but the description
is already 724 words and this buys nothing an agent needs.

The rule this finally makes explicit, and which I should have applied at R17: assert an error
FRAGMENT only when the description states it, or when an existing repository path produces that same
diagnostic for the same scenario. That is exactly why the check accepted the range and choice and
multiplexer fragments (cantools already names signals there) and rejected these two (container
packing overflow is new code with no repository analogue).

Coverage: `test_encode_command_reads_a_timestamped_line` covers both timestamped candump forms
`logreader.Parser` supports, the bracketed one and the log form with `id#data`. Both already worked,
since `--update` reads through the repository's parser; only the compact form needed the extra
parsing added in R10.

143 tests.

## R23 — twenty-first coverage round (2 suggestions, both added)

No solution change and no description change.

1. `test_reencode_rejects_a_joined_key_its_message_lacks` puts `Other.Mode` through `reencode_frames`
   and gets the same `EncodeError` naming the whole key that encoding gives, which the description
   already covers by saying reencode takes keys the way `encode_signals` does.
2. `test_encode_command_takes_a_choice_string` gives plain mode its own successful choice case. It
   was already exercised as the second line of `test_encode_command_reads_every_line`, so this is
   redundancy rather than new coverage, but a focused test is cheap and the bundled one was easy to
   miss.

145 tests.

## R24 — twenty-second coverage round (1 added, 1 partly added)

1. The ladder ceiling is the corner I deliberately left open at R5 and it has now come back, so it is
   settled instead of dodged. The description says "a frame past the last of them is left as it is",
   `test_filling_leaves_a_frame_past_the_ladder_alone` covers a seventy byte ordinary message, and
   `pad_frame_data`'s fallback is no longer the untested branch flagged at R19. My R5 reasoning does
   not apply here: that was about a CONTAINER, where the fill bytes were ambiguous with entries, and
   containers are no longer filled at all. For an ordinary message longer than any CAN length the
   database is already malformed and leaving it untouched is the only reading of "up to the next"
   with no next.
2. The `EncodedFrame` half is a genuine hole and is fixed: `split_frame` trusted the named tuple and
   passed its `data` through uncoerced, so a string reached the decoder as a `TypeError`. It now
   coerces inside the same guard as the pair form, giving the documented `DecodeError`, and the shape
   table covers it. The non-iterable `frames` half is DECLINED: that is checking the argument type of
   a call, not validating input, and cantools does not do it anywhere. Nothing in the description
   promises it, so no test can be unfair and no agent can pass by getting it wrong.

146 tests. `meta.md` is 737 words.

## R25 — fairness round 7 plus a twenty-third coverage round

Fairness (1 of 146 unfair): `test_encode_command_reads_negative_and_exponent_values` pinned a CLI
numeric grammar nothing states. Rather than drop the test I stated the grammar, because the gap is
wider than the one test: nothing said HOW a value is read at all, so `Mode=2` could legitimately mean
raw 2 or a choice named "2", and every CLI value test rested on that unstated order. The description
now says a value is read as a whole number if it is one, then as a decimal number if it is one, and
otherwise as a choice string. `test_encode_command_ignores_surrounding_white_space` also used
exponent notation incidentally and now uses a plain decimal, so the whitespace claim stands on its
own.

Coverage:

2. `test_decode_gives_nothing_back_when_a_later_frame_is_unknown` mirrors the reencode atomicity
   test on `decode_frames`.
1. Little endian container decode is DECLINED, and the reason is the pre-existing bug recorded in
   R11: `unpack_container` reads the contained header big endian whatever `header_byte_order` says,
   so a little endian container does not round trip in cantools as it stands. A round trip assertion
   would fail, and asserting the actual result, that it decodes to nothing, would pin a repository
   BUG: an agent who fixed `unpack_container` would then fail my test. The suite already covers what
   is fair here, the encoded header bytes for both orders and a big endian round trip.

147 tests. `meta.md` is 764 words.

## R26 — alignment warning: container header byte order stated

The alignment check flagged that `test_container_header_follows_its_byte_order` expects the three
byte header id to follow the container's `header_byte_order`, which the description never mentioned.
The Test Fairness check has repeatedly passed that test as repo-discoverable, since the property is
public on `Message` and the existing `_encode_container` honours it, so this was a WARNING rather
than a fairness failure. I stated it anyway: the description now says each entry sits behind its
three byte header id "in the byte order the container gives its headers". Six words to remove a
flagged gap is worth it, and every earlier round where I left something merely inferable saw it come
back.

Only `meta.md` changed. Neither patch is touched and no test or source line moved, so the validation
matrix from R25 stands unaltered rather than being re-run.

`meta.md` is 774 words.

## R27 — solution quality 2/3 to 3/3, description under 700, three more coverage cases

**The Solution Quality reviewer found a real bug my whole suite missed.** `reencode_frames` derived
ONE flattened fallback by decoding the entire container frame, then handed that same mapping to
every contained message. `decode_frames` merges later signals over earlier ones, so when two
contained messages carry the same signal name the later value overwrote the earlier before
re-encoding, and both entries came back with it. That contradicts "every signal they do not name
keeping the value that frame gave it". The fallback is now derived per entry from that entry's own
bytes, the flat decode is only computed for ordinary messages, and an entry whose payload its
message cannot read is kept raw (which subsumes the old length check).
`test_reencode_keeps_each_entry_its_own_values` is the regression: two contained messages both
carrying `Shared`, one reencode of an unrelated signal, each keeps its own value.

That is the second defect found in the container reencode path after R9 and R13, and the third
overall. All three were the same shape, container reencoding losing or corrupting per entry state,
and none of my own passing tests could see them because every container fixture I had used DISTINCT
signal names. Shared names across entries was the blind spot.

**Little endian container decoding is now fixed rather than declined.** I turned this suggestion down
in R11 and R25 because `unpack_container` reads the contained header big endian whatever
`header_byte_order` says. That reasoning expired in R26 when the description started requiring the
container's byte order to govern headers: my own contract then implied the round trip. Two lines in
`unpack_container` now honour it. No repository test covers a little endian container, and the ARXML
fixture container is big endian, so nothing existing changes.

**Description cut to 701 words** (from 774), the cap the user set. Nothing tested was dropped; the
savings came from prose (numerals for the CAN length ladder, "database order" for the long form,
"`--set` repeats", a shorter value parsing sentence). Every clause listed in the false positive walk
below still has its asserting test.

Also added: `test_container_fills_a_frame_exactly` (a final entry landing exactly on the container
length stays put) and `test_encode_command_pads_a_short_identifier` (identifier 0x1 prints `001`).

150 tests. 551 human-effective LOC.

## R28 — twenty-fifth coverage round (3 suggestions, all added)

No solution change and no description change; all three follow from clauses already written.

1. `test_container_tail_too_short_for_a_header_is_dropped` covers a container ending in two stray
   bytes. `unpack_container` logs and ignores a tail under four bytes, so those bytes are not an
   entry the frame "held", and both decoding and reencoding pass over them.
2. `test_decode_frames_takes_more_data_than_a_message_holds` pins that an ordinary payload longer
   than its message decodes anyway. This is the same `allow_excess` path every padded frame round
   trip already depends on; it just had no test of its own.
3. `test_encode_command_reads_lower_case_hexadecimal` feeds `1f0#0006e0...` to `--update`. The
   printed form is upper case but the parser accepts either, which matches the repository's own
   candump handling.

The description went from 701 to 697 words to sit under the 700 the user set with `wc -w`, which
counts the title's `#` as a word. Two phrases were shortened, no clause touched.

153 tests.

## R29 — twenty-sixth coverage round (3 suggestions, all added)

1. `test_encoded_frame_keeps_the_identifier_it_was_given` builds an `EncodedFrame` whose `frame_id`
   disagrees with its message's. Decoding follows the held message, which the description already
   says; the reencode half did NOT say which identifier comes back, so the description now ends the
   reencode paragraph with "A frame keeps the identifier it was given". Six words were shaved
   elsewhere to pay for it and stay under the 700 cap.
2. `test_reencode_keeps_repeated_entries_apart` is the harder version of the R27 fix: one container
   frame holding the SAME contained message twice with different payloads. Each entry keeps its own
   value when an unrelated signal is reencoded. The flattened fallback would have given both the
   second value, so this is the case that should have existed when I wrote the R27 regression.
3. `test_encode_command_updates_a_container_frame` drives a real ARXML container through
   `cantools encode --update`, so the CLI now covers container preservation end to end rather than
   only through the Python API.

156 tests. `meta.md` is 698 words.

## R30 — fairness round 8: three of my own recent additions rolled back

All three unfair tests came from the last four rounds, and all three were me over-reaching on a
coverage suggestion instead of asking whether the suggestion was fair to a solver.

1. **Little endian container decode, REVERTED.** In R27 I changed `unpack_container` to honour
   `header_byte_order`, reasoning that R26's description made the round trip my contract. The check
   read the description more carefully than I did: byte order appears only in the container ENCODING
   paragraph, so decoding it that way is a change to pre-existing behavior no solver is pointed at.
   The edit is gone, `solution.patch` no longer touches `unpack_container`, and only the encoding
   assertions remain. This is also the drive-by-refactor the authoring rules warn about, and I talked
   myself into it. The little endian decode bug stays a cantools bug, recorded here and untested.
2. **`test_frame_of_another_shape_is_an_error` relaxed** to the exception type. "Named as it was
   given" does not fix a representation: `(0x200,)` could reasonably be rendered with a hexadecimal
   identifier, so requiring decimal `512` pinned my own formatting. Same mistake as the container
   overflow error at R22, and I had already written the rule that should have stopped it.
3. **`test_encode_command_reads_lower_case_hexadecimal` deleted.** The repository's compact candump
   pattern restricts the identifier to `[0-9A-F]`, so asserting lowercase acceptance demands
   behavior contrary to the visible parser. My own parser stays lenient, which harms nothing; only
   the assertion was unfair.

Nothing in the description changed, so it stays at 698 words. 155 tests, 548 effective LOC.

The pattern across these three, and worth stating plainly: a coverage suggestion is a hint about
what to look at, not a warrant. Three times running I implemented one without first checking that a
solver could derive the behavior from the prompt plus the repository.

## R31 — the two checks disagreed; resolved by stating, not by oscillating

Both suggestions asked for exactly what the fairness check called unfair one round earlier. Rather
than flip a third time I read WHY each was rejected and fixed the cause.

1. **Little endian container decode, restored with a clause.** The fairness objection was precise:
   the description named byte order "only in its encoding paragraph, so the little-endian decode
   assertion requires changing pre-existing behavior NOT SINGLED OUT to the solver". That is an
   objection to silence, not to the behavior. The decode paragraph now says "A container's headers
   are read in its own byte order", the two line `unpack_container` fix is back, and the round trip
   is asserted for both orders. Ten words elsewhere paid for it, so the description is 697.
   Encoding that honours byte order while decoding ignores it was never coherent; this settles it in
   the direction that makes the library correct.
2. **Invalid frame diagnostics, added only where a representation is stable.** R30 removed these
   because `(0x200,)` may fairly be rendered with a decimal or hexadecimal identifier, so no
   fragment is derivable. That reasoning holds for the tuples and they stay type-only. It does NOT
   hold for the string `'nope'`, which appears verbatim under `str` and `repr` alike, so that case
   now asserts the fragment the description promises. Partial, and deliberately so.

155 tests. 551 effective LOC. `meta.md` 697 words.

The lesson from R30 stands but needs a second half: a coverage suggestion is not a warrant, AND a
fairness rejection is not always a verdict on the behavior. Sometimes it is a verdict on the
description. Reading which one it is beats reversing course each round.

## False positive pre-check (prompt to test, both directions)

Walked every clause of `meta.md` against the suite after each round. All behavioral clauses have at
least one asserting test, so no requirement can be skipped by a passing agent, and every one of the
155 tests traces back to a clause. Eighteen gaps have been closed this way, each found by a check rather
than by the walk itself: `Message.encode_signals` on a name it does not carry, `reencode_frames` on
an unknown key, what `EncodedFrame.message` holds, the CLI item grammar, a `--update` line that is
not a frame, the exact shape of a `Name=Value` item, a container entry the database cannot place, and
what a padded frame is filled with, a printed line fed back to `--update`, and a container entry
whose payload does not fit its message, blank lines on standard input, and a frame argument of the
wrong shape, a repeated key on one command line, which message an `EncodedFrame` decodes with, the
byte order a container's headers are read in, and
an `EncodedFrame` whose data is not bytes, how a command line value is read, per entry value preservation when a container reencodes, and which identifier a reencoded frame
keeps. The padding one had
made the round trip law false, and the lesson is
that an assertion on encoded bytes proves nothing about whether those bytes can be read back: every
padded test now decodes its own output. The last deliberate hole, a padded frame past sixty four bytes, was closed in R24.
