# Encode a flat signal dictionary into CAN frames

Add `Database.encode_signals(signal_values, scaling=True, padding=False)`, returning a list of
`EncodedFrame`, a named tuple exported from `cantools.database` holding the `message` it belongs to,
that message's `frame_id` and its `data`. A key names a signal, or a message and one of its signals
joined by a dot, the joined form winning for that message. A key naming a signal its message lacks,
or that no message carries, raises `EncodeError` listing each. A message is encoded only when it
carries a named signal, and a name several messages carry goes into each.

A multiplexer takes every value whose signals are named, and the message is encoded once per
combination. Multiplexers are taken in the order their signals appear, values ascending, the first
varying the slowest, and one under another exists only under its own value. A multiplexer no named
signal needs takes the value it was given, else the smallest it defines; a value it cannot take is
an error too.

Every signal a frame carries is written: a named one with the value given, a multiplexer with the
value selected for it, any other with its initial value, or with the value its raw zero stands for
when it has none. A named value outside its signal's range, or a choice string it does not define,
is an error; filled in values are never checked. With `padding` unused bits take the unused bit
pattern of their message, and a frame which is not a container is filled with zeros up to the next
CAN data length, which past eight bytes is 12, 16, 20, 24, 32, 48 or 64; longer frames are left
alone.

A container is encoded from the messages it features that carry a named signal, in the order it
lists them, each behind its three byte header id, in that container's header byte order, and its one
byte length. A contained message which would take a frame past the container's length starts a new
one; one that does not fit an empty frame is an error. Frames come back ordered by identifier, then
database order, then as above. `Message.encode_signals` does this for one message, giving back the
data alone and ignoring any name it does not carry.

Add `Database.decode_frames(frames, decode_choices=True, scaling=True)`, merging the signals of
frames given as `EncodedFrame` objects or identifier and data pairs into one mapping. An
`EncodedFrame` is read with the message it holds, a pair by its identifier. A frame contributes what
it carries: for a multiplexed message the multiplexers and what their values select, for a container
the signals of every message it holds that the database knows. A container's headers are read in its
own byte order. A later frame replaces what an earlier one gave. An identifier no message defines
raises `DecodeError` naming it in hexadecimal, as does anything which is neither of those two forms,
named as it was given.

Add `Database.reencode_frames(frames, signal_values, scaling=True, padding=False)`, taking frames as
`decode_frames` does and keys as `encode_signals` does, failing the same way on either. A frame
whose message carries none of them comes back untouched; any other is encoded again once per
combination its named signals ask for, every signal they do not name keeping the value that frame
gave it. A container frame is encoded again from exactly what it held, each entry keeping its own
values and one which cannot be read kept as it is. A frame keeps the identifier it was given.

Add a `cantools encode` command printing, for the white space separated `Name=Value` items on a line
of standard input, one candump line per frame: `identifier#data` in upper case hexadecimal, the
identifier three digits wide, or eight when extended. With `--update` it reads candump frames
instead, the lines it prints itself included, and encodes them again with the `--set` items changed;
`--set` repeats. A value is read as a whole number, else a decimal, else a choice string. An item
which is not a name and value around one equals sign, or an `--update` line which is not a frame,
fails the command naming it. A blank line is passed over; a repeated name takes the later value.
