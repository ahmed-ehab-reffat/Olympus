# Solution approach

Extend the existing NodeSet exporter rather than parsing or concatenating XML.
Validate that the selected namespaces are nonempty, unique, and owned by one
address space, then derive a deterministic order using the repository's current
namespace priorities.

Compute the existing dependency projection for each selected model. Build one
namespace translation containing selected namespaces followed by their
external dependencies, and pass that translation through the established
alias, identifier, reference, type, and value serializers. Emit one Model entry
per selection, union the existing node/type iterators across the selection, and
exclude nodes owned only by declaration dependencies.

The legacy exporter omits references that point outside its namespace. A
multi-selected document instead needs one owner for a relationship whose two
endpoints are selected. Use a deterministic endpoint rule so exactly one
representation remains, while retaining legacy behavior for selected-to-
unselected relationships. Preserve the serializer's canonical inverse
`HasSubtype` representation before applying the generic cross-selected rule;
otherwise a chosen forward subtype edge is discarded by the established writer
and the relationship disappears.

Expose the helper through both package surfaces. The callable implementation is
exported by the runtime barrel, while a declaration-only signature is added to
the separate barrel advertised by `package.json#types`. Keeping the declaration
type-only avoids introducing a circular runtime import through internal source
modules.

Keep `Namespace#toNodeset2XML()` on its byte-compatible ordering path. The new
public helper can share the serializers and aggregation machinery without
changing old single-namespace output.
