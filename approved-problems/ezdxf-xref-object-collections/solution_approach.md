# Solution approach

Validate each `load_objects()` argument before adding a loading command.  Walk
from the selected object through its owning dictionaries, require every child
to be present under a dictionary key, stop only at the source root dictionary,
and reject cycles, foreign objects, graphics, unnamed objects, and the root
itself.  Keep the validated selection in the existing resource-loading command
so duplicate handles are naturally deduplicated by the registry.

At transfer time, map the source root to the target root and recursively resolve
each source owner dictionary.  Reuse an existing dictionary entry, otherwise
create an ordinary dictionary with the source ownership and cloning flags.
Distinguish real key presence from `DictionaryWithDefault.get()` fallback
behavior.  Attach the copied leaf under the source key, use the existing unique
dictionary-key helper for actual prefix-policy conflicts, retain a free source
key, and apply the same decision whether the leaf was selected directly or
reached through a hard resource reference. Redirect or destroy copies when
`KEEP` selects an existing entry or blocks reconstruction. When a conflicting
leaf is discarded, walk the copied
ownership graph and discard its dependent hard-owned copies as well. Redirect
their handle mappings before resource mapping so surviving objects cannot point
at a destroyed or unattached import.

When both an imported leaf and the existing target entry are dictionaries,
redirect the source and temporary clone mappings to the target dictionary and
merge the clone's copied entries into it. Recursively reuse matching child
dictionaries, keep or rename conflicting non-dictionary children according to
the active policy, preserve resident target entries, and update the owner of
every moved hard-owned child. Destroy the emptied temporary clone only after
its mappings and contents have been resolved.

Check generated conflict keys against the current target dictionary until a
free key is found. Across repeated transfers, the first generated candidate
may already be occupied even though the original source key still initiates
the conflict.

Treat hard-owned dictionary children as in-object copies and recursively map
their resources. Register soft-owned non-dictionary children as independent
resources, clear only the XREF clone's temporary source links before binding
it, and repopulate that clone from the handle map. This keeps ordinary
`Dictionary.copy()` unchanged while preventing cross-document references and
false conflicts.

Before registering a hard-owned dictionary, mark every descendant that its
normal copy operation will create inline. Remove an already queued descendant
and ignore later direct or hard-resource attempts to queue it again. The
dictionary's in-object handle map then remains the single mapping for that
source child, so conflict handling never sees the inline clone as a pre-existing
target occupant and references resolve to the one inline copy.

Make `XRecord` and non-graphical `DXFTagStorage` register hard pointer/owner
targets and pass their copied tag groups through the existing pointer mapper.
Clone unknown objects' complete `ExtendedTags`, including embedded objects, but
retain the prior rejection for unknown graphical entities.  Let the mapper
rewrite soft pointers, hard pointers, soft owners, hard owners, and extended
data handles while leaving 320-series arbitrary handles unchanged. Update child
ownership only for hard-owner tags. Call the base entity resource mapper as
well, so valid XDATA such as group 1005 is translated for unknown objects in
addition to their raw subclass and embedded groups.

Treat a `DictionaryWithDefault` default as an unnamed hard resource. Register
the source default, do not attach it as a named leaf, and map the copied
dictionary's default handle and live fallback object to the target copy. Update
the copied default's owner so the relationship survives save/reload. This path
is used only for a newly copied specialized dictionary; reusing an existing
target management dictionary preserves its target-side default.

Record incoming hard-resource edges while registration recurses. Defer
destruction of owned descendants until named conflict resolution is complete,
then trace surviving hard-reference and ownership paths through the candidate
subgraph. Destroy only candidates with no surviving path, and give a retained
resource a valid target-side owner if its copied owner was discarded. Treat a
temporary merged dictionary as a discarded owner for this analysis so an
unused copied DWD default is removed, while a default referenced by another
surviving participant can remain.

Other implementations may build an ancestry plan during registration, attach
objects in a separate finalization pass, or represent soft links differently.
Only validation atomicity and the final audited, serializable target graph are
observable.
