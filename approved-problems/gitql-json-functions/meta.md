Repository: https://github.com/AmrDeveloper/GQL
Language: Rust
Issue: json-functions
Commit: 3a76cfee02a00ee6ce20eeac6447573b34f25d86
Title: Add JSON Functions and Access Operators to the Query Language

# Add JSON Functions and Access Operators to the Query Language

Add a new family of JSON scalar functions and two access operators. Functions and operators consuming a JSON document return null when invalid; `json_valid` reports validity. In a path `$` is the root, `.key` and `."quoted key"` select members, `[n]` the element at zero-based index `n`, `[#]` the appending position past the end, and `[#-n]` the element `n` from the end, so `[#-0]` is past-the-end and never appends. A malformed path or valueless lookup yields null; a mutation with an absent parent leaves the document unchanged.

The right operand of `->` and `->>` selects an object member when text, the array element `[n]` when integer `n`, or a path beginning with `$`, any other operand yielding null; `->` returns JSON text, and `->>` a typed value with containers as JSON text and a JSON null as SQL null. The operators chain left to right and bind tighter than arithmetic.

`json_type` returns `object`/`array`/`integer`/`real`/`text`/`true`/`false`/`null` at an optional path. `json_extract` with one path returns it as JSON text for containers, typed for scalars; several paths give a JSON array, null for each missing one. `json_query` runs an extended path, always returning a JSON array of every match in pre-order (earlier members before later), duplicates kept; a pattern may also use `.*` (members or elements), `[*]` (array elements), `..key`/`.."key"` (at any depth) and `..*` (every descendant value); `[#]` forms are rejected.

`json` reparses a document. `json_quote` renders a value as JSON. `json_array` builds an array from arguments; `json_object` builds one from alternating key/value arguments, null for an odd count or non-text key; text arguments are embedded as JSON strings. `json_array_length` returns the array length at an optional path, zero for a non-array.

`json_set`, `json_insert` and `json_replace` apply alternating path/value pairs left to right: set writes whether the target exists, insert only when it is absent, replace only when it is present. For set and replace `$` replaces the whole document, while insert leaves it unchanged; an out-of-range index is a no-op. `json_remove` deletes the values at its paths left to right and reindexes arrays, null when a path is `$`. `json_patch` merges a patch: object members recurse, a null member removes that key, and any non-object patch replaces the target, while an object patch treats a non-object target as `{}`.

`json_keys` returns an object's member names as a JSON array, null for a non-object. `json_contains` reports containment: scalars match by equality, a scalar matches an array containing it, and each candidate element or member must be present regardless of count. `json_depth` returns nesting depth, one for scalars and empty containers. Member order follows the document, updates keep position, and output is minified except `json_pretty`, space-indented with each member and element on its own line.
