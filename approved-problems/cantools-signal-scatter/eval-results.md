# eval-results — cantools-signal-scatter

## Batch 0 — local validation (no agents yet)

| Check | Mode | Cases | Failures | Notes |
| --- | --- | --- | --- | --- |
| base + test.patch | base | 413 | 0 | repo suite green, new file ignored |
| base + test.patch | new | 155 | 155 | F2P, every node fails on `Database.encode_signals` missing |
| base + both patches | base | 413 | 0 | no regressions |
| base + both patches | new | 155 | 0 | |
| Docker offline non-root | base | 413 | 0 | `--network none --user 1000:1000` |
| Docker offline non-root | new | 155 | 0 | |
| Docker x3 after R2 | base + new | 413 / 155 | 0 / 0 | identical every run |

## Batch 0b — platform checks (2026-08-03)

| Check | Verdict | Notes |
| --- | --- | --- |
| Test Fairness | FAIL -> fixed | 3 of 63 unfair: unstated `[]` for an uncarried name, `DecodeError` vs the repo's `KeyError`, same policy on `reencode_frames`. All three answered in `meta.md`; no test relaxed |
| Description only necessary | request_changes -> partly accepted | dropped the round trip restatement; kept the export location and the database-order tie breaker and backed both with tests; kept the CAN data length list, which is not in the repo |
| Problem and tests aligned | WARNING -> fixed | `reencode_frames` input forms and `Message.encode_signals` return type now stated |
| Coverage suggestions | 4 of 4 added | export/`_fields`, equal identifiers, padding ladder, CLI multi-line |

## Batch 0c — second coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Qualified-key errors | added, one call mixing three unknown key shapes |
| Container mux fan-out | added, exact packing order plus the split case |
| Container reencoding | found a real defect: a frame was rebuilt from the named messages, not the ones it held. Fixed in `database.py` and `message.py`, one sentence added to `meta.md`, three tests |
| Decode overwrite across containers | added, contained versus ordinary message, both orders |
| Option propagation in reencode | added, `scaling=False` |

## Batch 0d — third coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Message-level mux and container | added, direct `Message.encode_signals` on both |
| CLI extended-ID formatting | added, `multiplex.dbc` identifier 0x123456 |
| Malformed CLI input and unknown names | added, both assert the offending token reaches the user; one sentence added to `meta.md` |
| Padding ladder boundaries | added, exact 8, 12 and 64 byte frames plus a 68 byte over-capacity case |

## Batch 0e — fairness round 2 and fourth coverage round (2026-08-03)

| Item | Response |
| --- | --- |
| Unfair: frame past the 64 byte ceiling | test deleted; the description's ladder ends at 64 and defining behavior above it would be nonstandard |
| Unfair: malformed CLI token echoed in the exit text | description now says the command fails "naming it"; test kept |
| Message-level qualified names | added |
| Reencode validation errors | added, four cases; found that `reencode_frames` never checked its keys, now shared with `encode_signals` |
| CLI `--set` validation | added, several items plus malformed and unknown |
| False positive pre-check | every description clause has an asserting test, all tests trace to a clause |

## Batch 0f — fairness round 3 and fifth coverage round (2026-08-03)

| Item | Response |
| --- | --- |
| Unfair: 11 tests read `frame.message.name` or assert identity | description now says the tuple holds the message it belongs to |
| Unfair: two assignments on one stdin line | description now says the items are white space separated |
| Unfair: repeated `--set` | description now says `--set` may be given more than once |
| Message-level option forwarding | added, `scaling=False` and `padding=True` |
| Qualified reencode precedence | added |
| CLI update identifier formatting | added, extended identifier through `--update` |

## Batch 0g — sixth coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Combined encode validation | added, valid and invalid keys in one call |
| Decode defaults and empties | added, `decode_frames([])` and the default choices and scaling path |
| CLI malformed candump update input | added; found that unparsable lines were silently dropped, now an error, one clause added to `meta.md` |
| Maximum container and DLC boundary | added, a 64 byte container splitting into 44 and 36 byte frames, filled to 48 each |

## Batch 0h — seventh coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Ordinary frame CAN FD padding | added, a nine byte message padded to twelve |
| Aggregated reencode key errors | added |
| CLI malformed assignment variants | added; the item shape is now one equals sign between a non-empty name and value, stated in `meta.md` |
| Mixed frame input forms | added, one list holding both forms through decode and reencode |

## Batch 0i — eighth coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Unknown contained payloads during reencode | added; found that an entry the database cannot place was dropped, now kept in position |
| Container reencode padding and DLC interaction | added; found that filling with the unused bit pattern made padded container frames undecodable, now filled with zeros |

## Batch 0j — ninth coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Container padding removal during reencode | added |
| Compact candump update input | added; found the command could not read its own printed output, `--update` now accepts it |
| Malformed frame tuple inputs | declined, the suggestion conditions on documented error semantics and there are none; pinning Python type errors would be over-specification |

## Batch 0k — tenth coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Container header byte order | added, both orders asserted on the encoded header; no solution change, the paths delegate to `Message.encode` |
| Combined final ordering | added, all three comparator levels in one scenario |

Noted, not fixed: `unpack_container` parses the contained header big endian regardless of
`header_byte_order`, a pre-existing bug on the base commit.

## Batch 0l — eleventh coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Qualified contained message precedence | added, two contained messages sharing a signal name |
| CLI no-op update | added, a `--set` name the given frame does not carry |
| Decode option forwarding for containers | added, `decode_choices=False` and `scaling=False` |

No solution change; all three already behaved correctly.

## Batch 0m — twelfth coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Untouched reencode with padding | added, untouched wins over filling |
| Known but unplaceable container entry | added; found that a known header with a payload of the wrong length was rewritten from defaults, now kept raw |
| CLI numeric parsing edges | added, negative, exponent and surrounding white space |
| Malformed compact candump | added, odd length, missing identifier and non hexadecimal data |

## Batch 0n — thirteenth coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Qualified key error in `Message.encode_signals` | added, message level ignores it, database level errors |
| Decode and reencode malformed frame tuples | declined again, no defined exception semantics to pin |
| CLI blank line handling | added; the behavior existed but was unstated, `meta.md` now says a blank line is passed over |

## Batch 0o — fourteenth coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Argument type validation | declined a third time, no documented exception semantics to pin |
| CLI update with no `--set` | added, every frame comes back untouched |
| CAN FD upper boundary | added, sixty to sixty four under padding, and a sixty one byte entry in a sixty four byte container |

No solution or description change; both behaviors follow from clauses already written.

## Batch 0p — fifteenth coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Update mode streaming | added, two lines updated in input order |
| Empty reencode changes | added, payloads, identifiers and message objects all preserved |
| Mixed decode failure during reencode | added, unknown identifier after two good frames raises with nothing returned |

No solution or description change.

## Batch 0q — sixteenth coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Qualified CLI keys | added, both modes, joined key beats plain |
| Malformed frame objects | ADDED, reversing three earlier declines; `split_frame` now raises `DecodeError` naming the item, stated in `meta.md` |
| Additional DLC transitions | added, the twenty and twenty four byte steps |

## Batch 0r — fairness round 4 and seventeenth coverage round (2026-08-03)

| Item | Response |
| --- | --- |
| Unfair: exact phrase "Expected a frame" pinned | fixed, the test now asserts only that the item is named, with a fragment identical under `str` and `repr`; `meta.md` says "named as it was given" |
| CLI unknown frame identifier | added, `--update` on an identifier the database lacks names `0x123` |
| Duplicate key token handling | added; the last value silently won and nothing said so, `meta.md` now states it |

## Batch 0s — fairness round 5 (2026-08-03)

| Item | Response |
| --- | --- |
| Unfair x2: trailing zeros treated as removable filling | root cause fixed, container frames are never filled; the ambiguity with a zero id, zero length entry cannot arise |
| Container filling disambiguation | resolved by removal, not by a new rule; ladder tests moved onto ordinary messages |
| Public export surface | added, `__all__` membership and identity |
| Decode input errors | added, truncated payload behind a valid pair |

## Batch 0t — eighteenth coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Full CAN DLC boundary matrix | added, 24, 25, 32, 33, 48 and 49 |
| Duplicate frame identifiers during decode | added; found that `decode_frames` ignored the message an `EncodedFrame` carries and lost a signal, now used, stated in `meta.md` |
| CLI validation propagation | added, out of range and undefined choice in both modes |
| Malformed container decode | added, an entry running past its frame |

## Batch 0u — nineteenth coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Repeated update option precedence | added, the later `--set` wins |
| Foreign `EncodedFrame` message | added as a test rather than a restriction; a message from another database is honoured, which is the stated rule and the useful behavior |

## Batch 0v — fairness round 6 and twentieth coverage round (2026-08-03)

| Item | Response |
| --- | --- |
| Unfair x2: `PartA` pinned in the container overflow error | relaxed to the exception type only; the solution still names the entry |
| Candump update syntax breadth | added, both timestamped forms the repository parser supports |
| Container overflow diagnostics | resolved by relaxing the tests rather than growing the description |

## Batch 0w — twenty-first coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Reencode qualified key mismatch | added, `Other.Mode` names the whole key |
| CLI successful choice input in plain mode | added; already covered inside a multi line test, now focused |

## Batch 0x — twenty-second coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| CAN FD padding overflow | added; the R5 open corner is now stated, a frame past the ladder is left as it is |
| Input container type robustness | half added; an `EncodedFrame` whose data is not bytes now gives the documented `DecodeError`, a non-iterable `frames` argument declined as argument type checking |

## Batch 0y — fairness round 7 and twenty-third coverage round (2026-08-03)

| Item | Response |
| --- | --- |
| Unfair: CLI numeric grammar pinned | fixed by stating how a value is read, which also closes the unstated whole number versus choice string order |
| Multiple frame decode error atomicity | added |
| Little endian container decode | declined; `unpack_container` parses the header big endian regardless, so a round trip cannot pass and asserting the current result would pin a pre-existing bug |

## Batch 0z — alignment warning (2026-08-03)

| Item | Response |
| --- | --- |
| Container header byte order not stated | stated in `meta.md`; fairness had passed the test as repo-discoverable, but the gap is now closed outright |

## Batch 1a — solution quality and twenty-fourth coverage round (2026-08-03)

| Item | Response |
| --- | --- |
| Solution Quality 2/3, container reencode flattened its fallback | FIXED; the fallback is now derived per contained entry from that entry's own bytes. Regression test added |
| Little endian container decoding | fixed rather than declined; `unpack_container` now honours `header_byte_order`, which the description requires since R26 |
| Three digit standard identifier | added, identifier 0x1 prints `001` |
| Exact fit container boundary | added, a final entry landing exactly on the container length stays in the frame |
| Description over 700 words | cut 774 to 697, no tested behavior dropped |

## Batch 1b — twenty-fifth coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Malformed container tails | added, a tail under four bytes is passed over by decode and reencode |
| Excess ordinary payloads | added, data longer than the message decodes anyway |
| CLI lower case candump input | added, the parser accepts either case, output stays upper |

## Batch 1c — twenty-sixth coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| `EncodedFrame` metadata mismatch | added; decoding follows the held message, and the description now states a reencoded frame keeps the identifier it was given |
| Repeated contained message entries | added, the same contained message twice with different values, each preserved |
| CLI container update | added, a real ARXML container through `--update` |

## Batch 1d — fairness round 8 (2026-08-03)

| Item | Response |
| --- | --- |
| Unfair: little endian container decode | REVERTED the R27 `unpack_container` edit; the description names byte order only for encoding, so decoding it that way was unsignalled behavior change |
| Unfair: malformed frame errors pinned decimal `512` | relaxed to the exception type |
| Unfair: lower case compact candump identifier | test deleted; the repository parser restricts identifiers to upper case |

## Batch 1e — twenty-seventh coverage round (2026-08-03)

| Suggestion | Response |
| --- | --- |
| Little endian container decode | restored, with the decode paragraph now stating a container's headers are read in its own byte order; the fairness objection was to the silence, not the behavior |
| Invalid frame diagnostics | added for the string case only, where `str` and `repr` agree; tuple cases stay type-only because no fragment is derivable |

No solution or description change.

No solution or description change.

No solution or description change.

## Agent runs

| Agent | Evaluator | Verdict | Messages | Files | LOC | Failed tests | Failure reason | Approach |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| _pending_ | | | | | | | | |

Predicted: 8 to 20 percent pass. Expected dominant verdict MISSED_REQUIREMENT, from a partial
multiplexer cover (one frame per message) or physical rather than raw filled in values.
