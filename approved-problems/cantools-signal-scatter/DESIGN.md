# DESIGN.md — cantools-signal-scatter

## 1. Title

Encode a flat signal dictionary into CAN frames

Verb-led, names the subsystem (the encode path of `cantools.database.can`).

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (PLAYBOOK § Pattern 12) — a new public capability whose difficulty is a
  subtle, interdependent correctness kernel (multiplexer selection cover) that drives every other surface.
- Pass rate target: <=40% sprint cap; **design target 1/10 (10%)**, the corpus mode.
- Best agent: Mixed (Orion-alone likely single solver).
- Dominant verdict: MISSED_REQUIREMENT (partial mux cover / physical-vs-raw defaults).

## 3. Public API surface

- `EncodedFrame` — named tuple exported from `cantools.database` with fields `message`, `frame_id`, `data`.
- `Database.encode_signals(signal_values, scaling=True, padding=False) -> list[EncodedFrame]` — scatter a flat
  name-to-value mapping across every frame that carries one of the names.
- `Database.decode_frames(frames, decode_choices=True, scaling=True) -> dict[str, SignalValueType]` — merge the
  signals of a sequence of frames (each an `EncodedFrame` or a `(frame_id, data)` pair) into one flat dictionary.
- `EncodeError` — raised for unknown names, out-of-range named values, unknown choice strings, and a contained
  message that cannot fit an empty container frame.
- `DecodeError` — raised for a frame identifier no message defines.
- `cantools encode <database>` — CLI subcommand reading `Name=Value` lines from standard input and printing
  one `frame_id data` line per frame.

## 4. Canonical output form

- Frame order: by frame identifier ascending; messages sharing an identifier keep database order; within one
  message, selection order; container frames in packing order.
- Selection order: multiplexers in the order their signals appear in the message, values ascending, the first
  multiplexer varying slowest.
- Default for an unnamed signal: its initial value if it has one, otherwise the value its raw zero stands for.
- Default for a multiplexer nothing selects: the smallest value it defines.
- Dedup: none; every message carrying a named signal is emitted.
- Unknown names: `EncodeError` naming all of them.
- Padding off: unused bits are zero. Padding on: the message's unused bit pattern.
- Container packing: greedy, in the order the container lists the contained messages, never exceeding the
  container's length; a contained message that does not fit an empty frame is an error.
- `decode_frames`: later frames replace earlier ones for the same name.

## 5. Blind-spot pre-empts (DESCRIPTION.md sentence bank)

- Result-list ordering — "Frames come back ordered by identifier..." (result list ordering).
- Adjacent-vs-all — "A name several messages carry goes into each of them" (adjacent vs all positions).
- Iteration termination — "one frame per combination" (enumeration, not first-match).
- Falsy-on-invalid — defaults are never range checked (unstated inverse pre-empt).
- Compound order preservation — contained messages keep the container's order.

Codebase-inferable requirements: exactly 1 (the multiplexer tree is visible via `Message.signal_tree`).

## 6. Description draft

See `meta.md` (~430 words, prose only, no headers).

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Reason |
| --- | --- | --- | --- | --- |
| NEW | src/cantools/database/can/frame_set.py | — | 274 | the key/selection/default/packing kernel + type aliases |
| MODIFY | src/cantools/database/can/message.py | 1320 | 141 | per-message frame value sets, `encode_signals`, `carries_any` |
| MODIFY | src/cantools/database/can/database.py | 670 | 191 | `encode_signals` / `decode_frames` / `reencode_frames` |
| MODIFY | src/cantools/database/__init__.py | 383 | 4 | export `EncodedFrame` |
| NEW | src/cantools/subparsers/encode.py | — | 141 | CLI integration |

TOTAL (measured): 730 raw / 460 human-effective across 3 modified + 2 new files. The type aliases
stayed in `frame_set.py` rather than `typechecking.py`, so the footprint is 5 files, not 6.

## 8. Solution outline — pure-function helpers

- `_needed_selections(codec, named)` -> list of selection dicts — the kernel; one entry per combination of the
  multiplexer values whose subtree carries a named signal (per description requirement "one frame per combination").
- `_subtree_names(codec)` -> set[str] — every signal name at or below a codec node (requirement "at any depth").
- `_codec_for_selection(codec, selection)` -> list of codec nodes on the selected path (requirement "every signal
  on the path is written").
- `_default_value(signal, scaling)` -> value — initial, else what raw zero stands for (requirement "default").
- `_frame_values(message, selection, named, scaling)` -> dict (requirement "named ones with the given value").
- `_pack_container(container, entries)` -> list[bytes] (requirement "greedy packing").
- `_message_owners(database)` -> dict[str, list[Message]] (requirement "a name several messages carry").
- `Message.required_selections(names)` / `Message.selection_values(selection, names, scaling)` — the two hooks the
  database entry points call.

No fixpoint loop; the recursion terminates on the multiplexer tree, which is finite and acyclic by construction.

## 9. Test file outline

Path: `tests/test_signal_scatter_<hash>.py`

Block 1 — imports.
Block 2 — builder helpers: `_db(dbc_string)`, `_sig(...)`, `_msg(...)`, `_frames(db, values)`.
Block 3 — assertion helpers: `_assert_frames(actual, expected)`, `_assert_error(callable, *fragments)`.
Block 4 — buckets:
- plain messages: single message, several messages, shared names, unnamed message skipped
- defaults: initial value, raw-zero fallback with offset and scale, signed, float, choices
- multiplexing: one frame per needed value, common signals repeated, nested multiplexers, combinations,
  ascending order, unselected multiplexer defaults to the smallest value
- containers: single contained message, several, splitting on length, oversize error, multiplexed contained
- errors: unknown name, out-of-range, unknown choice string, unknown frame id
- padding / scaling flags
- decode_frames: pairs and EncodedFrames, later-frame override, containers, round trip
- CLI: encode subcommand output

5-axis coverage: every meta sentence, every public name, every branch, edge cases (empty mapping, message with
no signals, single-value multiplexer), stated inverse (defaults not range checked).

## 10. Forced kwargs / typing

`encode_signals` takes positional `signal_values` then keyword `scaling`, `padding` mirroring `encode_message`.
`decode_frames` mirrors `decode_message`'s `decode_choices`, `scaling`. `EncodedFrame` must be a tuple-like with
named fields so tests can index and attribute-access it.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt in meta | Test |
| --- | --- | --- | --- | --- |
| 1 | One frame per needed multiplexer value, not one per message | The natural loop is "for message in messages: encode once" | "one frame for every combination" | `mux_two_values_gives_two_frames` |
| 2 | Signals outside the multiplexed part repeat on every frame of that message | After splitting by mux, agents partition all named signals | "every signal the frame carries" | `mux_common_signal_on_every_frame` |
| 3 | Defaults are raw-zero, not physical zero; forced multiplexer values are raw | `signal.initial or 0` reads as physical | "the value its raw zero stands for" | `default_offset_signal_encodes_raw_zero` |
| 4 | A shared name feeds every message that carries it | First-match lookup | "goes into each of them" | `shared_name_emits_both_messages` |
| 5 | Container frames split greedily on length | Agents emit one container frame | "never exceeding the container's length" | `container_splits_when_full` |

Wrong Logic >= 25% expected — this is an O-Algorithm-correctness shape, and the spec is exhaustive, not ambiguous.

## 12. Tier + category

- Tier: Olympus. Sub-rank: Olympus-Good.
- Category: **feature-request** (net-new public API).

## 13. Predicted Nova pass rate

- Predicted: 8%-20%.
- Reasoning: five interdependent traps, three of them (1, 2, 3) in one kernel where fixing one surfaces the next;
  exact byte-level output; corpus levers 1 (one kernel driving encode, containers, CLI and decode), 3 (misdirecting
  — the failure shows as wrong bytes or a missing name, never as "emit more frames"), 4 (raw-vs-physical zero is
  the obvious-code-is-wrong edge), 5 (bespoke invented transform in a low-training automotive repo), 6 (six files).
  Lever 2 is served by the decode round-trip law rather than an external oracle.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (see feedback.md Phase 1)
- [x] Existing PR check: 0 hits (searches in feedback.md)
- [x] Closest approved problems opened: mp4ff-progressive-writer, gojq-ordered-keys
- [x] Corpus hardness recipe: one kernel, >=3 interdependent+misdirecting traps, obvious-code-is-wrong edge,
      every signature pinned in meta, invented feature (not a portable spec)
- [x] Title verb-led, 5-10 words
- [x] Shape declared
- [x] Public API surface lists every asserted name
- [x] Canonical output form spelled out
- [x] <=1 codebase-inferable requirement
- [x] Description prose only, under the 500-word cap
- [x] File footprint against real source files
- [x] LOC within band (gate on human-effective >= 450)
- [x] 1+ pure helper per described behavior
- [x] Test outline 4-block, scenario-encoded names
- [x] 5-axis coverage planned
- [x] Traps have pre-empt sentences and catching tests
- [x] Tier and category match
- [x] Not pattern-followable (no sibling API scatters across messages)

## Why this is not a duplicate

Closest approved: **mp4ff-progressive-writer** (rebuild one structure from many fragments) and **gojq-ordered-keys**
(a new mode threaded through an existing evaluator). Both differ in repo, language and subsystem; neither scatters a
flat value mapping across a multiplexer tree. No cantools problem exists in `problems/`, `rejected/` or
`Instructions/Aprroved/`. The nearest local sibling by name, `iso8583-message-validation`, is a validation contract
over one message, not a cross-message encode kernel.

Predicted iteration cycles: 2
