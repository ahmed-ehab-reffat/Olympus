Title: Load named DXF objects through XREF

Add `Loader.load_objects(objects)` to `ezdxf.xref`. It should queue selected non-graphical objects for the loader's normal `execute()` operation.

## Selection

Each selected object must belong to the loader's source document. The source root dictionary cannot be selected. Every selection must also have a named path back to that root containing only `DICTIONARY` entries.

Raise `EntityError` for an invalid selection. Validate the entire argument before adding anything to the queue, so a later invalid item does not leave earlier items queued.

## Target paths and conflicts

Recreate each named dictionary path in the target. Apply the same path and conflict behavior to named objects reached through resource references. Reuse the target root and any dictionary already present at a matching key. When an ordinary dictionary is missing, copy its ownership and cloning settings. Keep the source dictionary keys; do not infer them from entity attributes.

A non-dictionary object at a required key is a conflict. Apply the loader's conflict policy both to named leaves and to conflicts that block a path. Under `KEEP`, preserve the target entry and redirect references to an existing leaf when possible. Do not leave discarded imports or their hard-owned descendants unattached, but retain a descendant that is still used elsewhere in the transfer.

Under `XREF_PREFIX` and `NUM_PREFIX`, an occupied key must produce a unique target key. A free key keeps its source name.

An existing `ACDBDICTIONARYWDFLT` keeps its target-side default. Its fallback value does not make every missing key a conflict. A newly copied `ACDBDICTIONARYWDFLT` must receive a copied and mapped default owned by that copied dictionary.

## Ownership and identity

Hard-owned dictionary contents become independent target-side copies, and their owner handles must identify the copied owner. Soft-owned non-dictionary entries also become independent mapped resources rather than references into the source document. If the same source object is selected or reached more than once, create only one target copy.

## Opaque handle data

Include handle-bearing data from `XRECORD` and non-graphical unknown objects in resource transfer. Hard pointers and hard owners make their non-graphical targets reachable. When a target participates, translate these pointer categories:

- soft pointers in groups 330-339 and 1005;
- hard pointers in groups 340-349, 390-399, and 480-481;
- soft owners in groups 350-359; and
- hard owners in groups 360-369.

Leave arbitrary handles in groups 320-329 unchanged. A mapped hard-owner tag also makes the referenced copy a child of the copied owner.

Unknown objects must preserve independent raw subclass and embedded-object tag data. Unknown graphical entities remain unsupported.

## Persistence

Do not modify the source document. The target must pass the normal audit and preserve its dictionary paths, keys, ownership, opaque data, and mapped references after save and reload.
