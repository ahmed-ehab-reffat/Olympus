Title: Finish cursor and suffix traversal support across ZeroTrie

PerfectHash and ExtendedCapacity still lack the stepwise cursor workflow used
by the ASCII trie. Add it to those concrete types and to runtime `ZeroTrie`,
preserving the stored flavor. Each trie should expose `cursor()` and borrowed
slice stores should also expose `into_cursor()`.

The cursors are cloneable and support `step`, destructive `take_value`,
`is_empty`, `fmt::Write`, and indexed `probe`. Keep the probe API public and
concrete: it returns `Option<ByteProbeResult>`, whose fields are `byte: u8` and
`total_siblings: usize`. A successful probe follows that child in existing
iteration order. A failed step or out-of-range probe is absorbing. This must
work for every serialization these tries already accept, including partial
spans, empty and prefix keys, PHF branches, wide offsets, arbitrary bytes, and
full-width `usize` values. Preserve the existing SimpleAscii formatting error
for non-ASCII input; binary cursors consume `write_char` as UTF-8.

`into_suffix_trie()` should turn the current position into a reusable,
cloneable view without losing partial-span or taken-value state. The view
supports `get`, `cursor`, `get_with_write_fn`, `is_empty`, and `len`. Its
fallible `visit` accepts `ByteTrieEvent::{Push(u8), Value(usize), Pop}`, emits
values before children in probe order, and balances every push with a pop.
Return the first callback error before invoking the callback again. `len()` is
the number of value events. Give the suffix tries returned by the existing
SimpleAscii and ASCII-ignore-case cursors the same `len` and `visit` behavior;
their events reproduce their existing iterator output.

These cursor and suffix operations must allocate no heap with any feature set
and must compile without default features. With `alloc`, suffix `iter()` keeps
format order and also implements `DoubleEndedIterator`, `ExactSizeIterator`,
and `FusedIterator`; mixed front/back pulls cannot duplicate or skip entries.
`to_owned()` must preserve the exact state and flavor after the source is
dropped, expose `as_bytes`, `byte_len`, and `into_store`, and round-trip through
the corresponding concrete `from_store`. Concrete view, iterator-key, owned,
store, and serialization representations remain implementation choices.

Do not change the serialized format, existing lookup/case-folding behavior, or
`no_std` support.
