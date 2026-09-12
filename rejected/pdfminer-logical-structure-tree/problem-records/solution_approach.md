# Solution approach

The reference adds a small public structure model and a safe parser rooted at
`PDFDocument.catalog["StructTreeRoot"]`. The parser walks explicit `/K` values,
resolves roles and class attributes, carries inherited page identity, preserves
OBJR targets, and traverses ParentTree nodes with active-object cycle guards.
It separately scans page/Form resources to map `StructParents` keys back to
page and stream object IDs.

The rendering side augments the existing device lifecycle rather than parsing
content a second time. `PDFLayoutAnalyzer` keeps page/Form StructParents and
nested MCID stacks and records the actual `LTItem` instances created by text,
image, and path rendering. `PDFPageInterpreter` brackets recursive Form
rendering with content-stream hooks and resolves resource-named marked-content
property dictionaries. The high-level entry point renders pages once, then
binds the captured `(StructParents, MCID)` associations into the semantic tree.

The approach is one proof, not a required internal architecture. A solver may
use lazy nodes, a flat graph with links, an association post-pass, or another
device implementation as long as the stated public objects and behavior match.
