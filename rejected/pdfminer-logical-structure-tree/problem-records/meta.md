Title: Extract the semantic structure tree of tagged PDFs

Add semantic logical-structure extraction to pdfminer.six. Provide
`extract_struct_tree()` in `pdfminer.high_level`, following the existing
file/password/caching conventions, and `PDFDocument.get_struct_tree()` for an
already parsed document. Return `None` when the catalog has no
`StructTreeRoot`; otherwise return a `PDFStructTree` whose `roots` contains the
top-level structure elements.

Expose `PDFStructTree`, `PDFStructElement`, and `PDFStructContent` from
`pdfminer.structure`. Structure elements have `type`, `role`, `objid`,
`attributes`, and ordered `children`. `type` is the element's original `S` name
and `role` is its `RoleMap`-resolved name. `attributes` must contain direct `A`
attribute dictionaries followed by the dictionaries selected through `C` and
`ClassMap`. Preserve the explicit `K` order across nested structure elements,
integer marked-content IDs, marked-content reference dictionaries, and object
reference dictionaries.

Represent non-element children as `PDFStructContent` values. Expose `kind`,
`mcid`, `page_objid`, `stream_objid`, `object_objid`, `object`,
`struct_parent`, and `items` as applicable. Use kind `mcid` for integer
marked-content IDs, `mcr` for explicit marked-content reference dictionaries,
`objr` for object references, and `parent_tree` for content recovered only
through reverse association. Integer marked-content IDs and MCRs must inherit
or override their page context according to `Pg`. OBJRs must identify and
expose their referenced PDF object. For rendered marked content, `items` must
contain the actual layout objects produced by pdfminer.six, not a separate
text-only reconstruction.

Keep marked-content identity scoped by the containing page or Form XObject, so
the same MCID can safely occur in multiple content streams. Support inline and
resource-named marked-content property dictionaries. Use page and Form
`StructParents` together with `ParentTree` to recover reverse associations,
including a structure element that has no explicit content child.

Cyclic structure nodes, cyclic ParentTree nodes, dangling references, and
invalid child values must always terminate without associating content with the
wrong element. In strict mode these cases may raise the repository's existing
PDF syntax or type exceptions; in non-strict mode they may be omitted from the
result. Do not infer visual reading order or attempt general malformed-PDF
repair: the semantic order is the order stated by the structure data.
