---
Repository: https://github.com/mozman/ezdxf
Language: Python
Issue: none (original feature request)
Commit: b3eb37b942acb4c7e2d2487706e614aa29b7f9b2
Title: Synchronize block reference attributes with their definitions
---

# Synchronize block reference attributes with their definitions

Bring the ATTRIB entities of existing block references back in step with the ATTDEF entities of
their block definition.

`Insert.sync_attribs()` does that for one block reference, `BlockLayout.sync_attribs()` for
every reference of that block in the document and `BlocksSection.sync_attribs()` for every
reference in the document. Each hands back a report of whole numbers: `references` counts the
block references it worked on, needed or not, `added`, `removed` and `updated` count attributes,
one counting as updated when the run changed or moved it, and `changed` says whether any of
those three is not zero. Running it again afterwards changes nothing and reports no addition,
removal or update.

A synchronized block reference carries one attribute for each definition of its block that is
not constant and has a tag, in the order of the definitions. An attribute already there keeps
its content text, in full when that content is multiline, and stays the same entity, with its
handle and its extended data, and everything else comes from the definition, mapped into the
block reference exactly as a reference newly created from that block would get it, a definition
holding multiline content included, which yields a multiline attribute carrying that text, whose
single line text is the first line of it, unless the document is older than R2018 and cannot
hold one, when the attribute is single line and carries that first line alone.

A new attribute takes the text of its definition, in full when that is multiline, and belongs to
the document and the layout of its reference. An attribute with no definition to match is
removed, and where a tag turns up twice, among the definitions or on a reference, the first one
counts.

Tags are matched without regard to case wherever one is given, and an attribute takes the
spelling of its definition. Whether an attribute's position is locked is its own, and a locked
one keeps its own insert point and align point; everything else about it still follows the
definition. A reference whose block is not defined is left alone and not counted. The block
definition itself records whether it has non-constant attribute definitions.

`BlockLayout.out_of_sync_references()` gives back the references a synchronization would change,
and changes nothing.

`BlockLayout.attrib_placements()` says where the attributes of the block end up in the drawing.
It gives back an `AttribPlacement` of the `tag`, the `text`, the `location`, the `rotation`, the
`height` and the `insert` they hang on, one for every attribute of every reference of the block
a layout reaches, whether the layout holds that reference itself, holds another block that holds
it, however deep, or holds it as one element of a grid, each element counting on its own.

Location, rotation and height are the ones the attribute has in the drawing, so a reference
inside another block is measured through both. A block no layout reaches this way has none, a
reference a layout reaches more than one way is placed once for each of them, and a reference
leading back into a block the path already passed through is left out along with everything
under it, which stops that path alone and not the ones beside it. The model space comes first,
then the paper space layouts in tab order, and within a block the order of its own entities.

Editing definitions works the same way. `BlockLayout.rename_attdef()` renames a definition and
hands the content text of the matching attribute over to the new tag, dropping another attribute
that already carries it. `delete_attdef()` drops a definition and the matching attribute of
every reference. `reorder_attdefs()` takes the tags of all definitions, each exactly once, and
puts the definitions and the attributes in that order while the rest of the block content stays
in place.

Each of them reaches every reference in the document and returns the same report. A different
spelling of the same tag is a valid rename, a tag that is not defined raises `DXFKeyError`, and
a new tag that is empty or already defined, or a tag sequence that is not the tags of all
definitions each exactly once, raises `DXFValueError`. A rejected edit leaves the document as it
was.
