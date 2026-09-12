# Solution approach - collision-safe merge

The implementation preserves the original fast path when receiver and donor
definition namespaces do not collide. On collision it creates a private donor
graph, rewrites conflicting identities there, and passes that graph through the
existing append, map-union, and stable-order logic.

`cloneForMerge` copies style and region nodes, reconnects parent-style and
region-style edges, and copies item, line, and line-item containers while
reconnecting their named references. Inline style attributes and metadata stay
shared because collision handling never mutates them.

Collision resolution first records which cloned definitions are referenced.
It walks sorted source keys, drops unreferenced duplicate definitions to retain
existing behavior, and gives referenced duplicates the first identity unused by
both documents. Styles are resolved before regions so region-style links already
point at renamed style objects. Since references use object pointers, changing a
cloned definition's ID updates every connected edge without touching the donor.

The non-collision branch retains existing alias and ordering behavior. The
collision branch preserves receiver objects, donor state, shared-reference
closure, deterministic names, and receiver-before-donor ordering at equal start
times. TTML round trips verify the complete graph; format-specific behavior is
not added where SSA or WebVTT cannot represent an edge.

