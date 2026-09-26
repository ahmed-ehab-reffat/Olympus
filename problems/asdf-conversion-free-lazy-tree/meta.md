---
Repository: https://github.com/asdf-format/asdf
Issue: N/A
Commit: 376790c2742c18511a859eb7b1d7d4e55c47b4ff
Language: Python
Category: feature-request
Title: Add conversion-free info, search and writes for lazy trees
---

# Add conversion-free info, search and writes for lazy trees

Add support for keeping the untouched nodes of a lazy tree unconverted when a file opened with `lazy_tree=True` is inspected or written. Today `info`, `search`, `schema_info`, `write_to` and `update` walk the tree through the lazy containers, so every tagged node gets converted: a converter that fails breaks `info()` over nodes nobody asked about, and a rewrite re-tags every custom object with the tag its converter picks today.

A tagged node is untouched until something reaches it through the tree, by indexing or iterating the containers or through a search result's `node` or `nodes`. Whenever one of the operations below does convert a node, it converts it the way tree access does: the object takes the tagged node's place in the tree and every other reference to that node gives the same object, so a change made to an object returned by a search is what gets written.

`info`, `search` and `schema_info` show and match untouched nodes without converting them. A node whose tag no converter handles is shown as it is today. For a node a converter handles, the type used for display and by `type_` is the single Python type the converter declares, and while the node is untouched it is shown with that type name and no value, for example `bad (Thing)`. An untouched ndarray is shown and matched by `type_` as the array it would convert to, with the shape and dtype recorded in the file, exactly as the converted array shows them. A node is converted only when the operation needs the object: when its declared type is a dict, list or tuple or defines `__asdf_traverse__`, or, for `info` and `schema_info`, when its converter defines `to_info`; when the converter declares more than one type; when a `value` or `filter_` criterion has to look at it; and when `node` or `nodes` returns it. A `value` or `filter_` criterion only looks at a node after every `key` and `type_` criterion of the whole search chain has accepted it.

`write_to` and `update` write an untouched node from the tagged form it was read in, tag version included, without calling its converter. Arrays inside untouched nodes are written like any other array, honouring the compression and storage settings of the write, and stay readable in the same session after `update`. Converted nodes are written from their objects as today. Untouched nodes other than arrays are converted before writing, as today, when the file has a block that no ndarray in its tree refers to, and every node is converted when the write changes the file's ASDF Standard version. A node taken from another file opened with `lazy_tree=True` follows the same rules when both files use the same ASDF Standard version.
