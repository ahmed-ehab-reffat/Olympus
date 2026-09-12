---
Repository: https://github.com/tamasfe/taplo
Issue: N/A
Commit: 08f343be02ce1b20296470396a42f0fa47820449
Language: Rust
Category: feature-request
Title: Add Structural Insert and Remove Operations to the DOM Rewrite API
---

# Add Structural Insert and Remove Operations to the DOM Rewrite API

Add structural insert and remove operations to the DOM `Rewrite` API. Today `Rewrite` only supports renaming an existing key in place; there is no way to add a new entry to a table or array, or delete one, while keeping the rest of the document's formatting and comments untouched.

Add `insert_entry(table, key, value)` and `remove_entry(key)` for table entries, and `insert_array_value(array, value)` and `remove_array_value(array, index)` for inline array elements, all keyed by the same dotted-path syntax `rename_keys` already accepts. `key` and `value` are inserted verbatim as already-formatted TOML.

A new entry is inserted after a table's own last directly-declared entry, or right after its header if it has none, or at the document's start for the top-level table, always before any of that table's own nested table or array-of-tables declarations. Inline table and array insertions append as the last element, separated from the current last element by `", "`. Removing a table entry deletes its own line, including a trailing same-line comment. Removing an inline entry or array value also removes the comma that used to separate it from its neighbor: the following comma normally, or the preceding one when it was the last element. Inserting a duplicate key errors instead of overwriting. A key that resolves to a dotted-key group does not support `insert_entry` or `remove_entry` and returns an error, and an out-of-range array index returns an error too.
