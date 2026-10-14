---
Repository: https://github.com/asdf-format/asdf
Issue: N/A
Commit: 376790c2742c18511a859eb7b1d7d4e55c47b4ff
Language: Python
Category: feature-request
Title: Add conversion-free info, search and writes for lazy trees
---

# Add conversion-free info, search and writes for lazy trees

We want to read and write tagged files with `lazy_tree` set to True, keeping the tags of untouched nodes in written files without converting them and preventing problems with bad converters in `info()`.

A tagged node is not converted until accessed by a container iterator or index or by a search result's `node` or `nodes`. The converted object replaces the node in the tree.

`info`, `search` (and results), and `schema_info` view and search unconverted nodes without converting them. Tags with no converter are displayed and searched as they are now. Tags with a converter are displayed using the single Python class name from the converter, with no value, such as `bad (Thing)`, and `type_` matches them as that class.

In `info`, `schema_info` and searches, a node is converted only when needed: if a node's declared type is a dict, list, or tuple or has `__asdf_traverse__`; if a `value` or `filter_` condition looks at it; or if `node` or `nodes` returns it. `key` and `type_` conditions across the whole search chain are applied before `value` and `filter_` conditions on nodes.

`write_to` and `update` write unconverted nodes in their original tagged form, using the original tag version and no converter. History entries are handled like other unconverted nodes. Every unconverted node, including scalars and lists, records its extension in the history like converted nodes. If any binary data blocks were found when the file was opened, unconverted non-array nodes will be converted before writing and given either the original or a new tag by the converter.
