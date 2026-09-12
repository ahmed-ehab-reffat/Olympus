Title: Export selected namespaces as one deterministic NodeSet

Add a public `exportNodeset2XML(namespaces)` function to
`node-opcua-address-space` that exports a nonempty selection of namespaces from
one address space as one UANodeSet XML document. Reject an empty selection,
repeated namespaces, and namespaces belonging to different address spaces.

The result must contain all and only the nodes owned by the selected
namespaces. Emit a Model entry for every selected namespace, preserving its
model URI, version, publication date, and required-model metadata derived by
the existing exporter. Keep unselected dependencies declared and addressable
when required, but do not export their nodes.

Use one namespace-index translation consistently for node identifiers, browse
names, aliases, references, data types, and encoded values. Relationships
between two selected namespaces must be represented once in the document and
must reconstruct the same relationship after loading.

Output for the same selected set must be byte-identical regardless of caller
order. It must load through the existing NodeSet loader into a fresh address
space with the selected models, nodes, references, and values intact, and
exporting that same selected set again must be stable.
