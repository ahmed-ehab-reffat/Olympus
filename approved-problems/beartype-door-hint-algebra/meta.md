---
Title: Add hint simplification and meets to the DOOR API
Repository: https://github.com/beartype/beartype
Language: Python
Issue: door-hint-algebra
Commit: 687adb0356327668d9cf1a6993b9b66c5cb4d635
---

# Add hint simplification and meets to the DOOR API

`beartype.door` orders type hints but never combines them. Extend it with a lattice. `TypeHint` gains `simplify()`, `join(other)`, `meet(other)`, `difference(other)` and `is_disjoint(other)`, each returning a wrapper again except `is_disjoint`, with `|`, `&` and `-` as operators for the join, the meet and the difference; `meet` and `difference` return `None` when there is nothing to return. A method or operator handed anything but a wrapper raises `BeartypeDoorException`.

The functions `simplify_hint(hint)`, `join_hints(hint1, hint2)`, `meet_hints(hint1, hint2)`, `difference_hints(hint1, hint2)`, `is_disjoint(hint1, hint2)` and `cover_hint(hint, hints)` mirror those combinators on unwrapped hints, `None` again meaning nothing, and are importable from `beartype.door`. One of them handed an object that is not a type hint raises `BeartypeDoorException` too.

Simplifying a hint canonicalises the children nested inside it as well as the hint itself, while the shape around those children survives: a callable keeps its ignorable (`...`) or empty parameter list and an annotated hint its metadata. A hint that is already canonical comes back unchanged.

A union is flattened, equal members collapse to one, literal members fuse into a single literal whose arguments are deduplicated by equality, the comparison the package already applies to them, so `True` and `1` are one argument rather than two, either spelling serving for it, that literal then loses every argument the subhint relation already places inside a different member and disappears when none is left, and finally every member that is a subhint of a different surviving member is dropped. A union with `Any` in it is `Any`, and a union of one member is that member. Neither the members of a union nor the arguments of a literal carry an order.

The join of two hints is their canonical union. Their meet is canonical too. `Any` meets a hint as that hint. A union distributes over the meet: the surviving pairwise meets of its members form the canonical result, and the hints are disjoint when none survives.

Two literals meet as the arguments common to both, another hint meets a literal as the arguments whose type is a subhint of it, and no surviving argument means disjoint. An annotated hint meets an unannotated one as its metahint's meet carrying its metadata, and two annotated hints likewise but only when their metadata are equal, differing metadata being disjoint, as is metadata that raises rather than answer whether it is equal. A union drops one annotated member for another, and a difference drops an annotated member for an annotated subtrahend, on those same terms, equal metadata and a metahint the other's subsumes, rather than by the subhint relation.

Fixed-length tuples meet elementwise and only at equal lengths, and against a variable-length tuple each item meets that tuple's single child, keeping the fixed length. Callables meet elementwise over parameters and return, where ignorable parameters (`...`) meet as the parameters of the other callable and two parameter lists otherwise need equal lengths.

Any other pair of subscripted hints of the same kind meets as the narrower of their two origins subscripted by the elementwise meets, unrelated origins or differing child counts being disjoint; an effectively unsubscripted hint such as `list` or `list[Any]` takes on the other hint's children, but only when its own origin is the strictly narrower of the two and takes child hints at all, which `str` and `bytes` never do however sequence-like they are, and never for a bare `tuple`, since subscripting `tuple` by one child means a one-item tuple. A pair matching none of these, a sequence-like hint met with a tuple among them, meets as the narrower of the two when one is a subhint of the other and is disjoint otherwise.

The difference of two hints keeps each literal member minus the arguments the subhint relation already places inside the subtrahend, and each other member whole unless it is a subhint of the subtrahend, which drops it. The result is canonical, or nothing when no member survives. `Any` minus anything but `Any` is `Any`.

`cover_hint` reports how an ordered iterable of hints, walked once so a generator serves as well as a tuple and raising `BeartypeDoorException` when it cannot be iterated at all while an iterable that fails partway through is left to raise as it is, covers one hint, as a `HintCoverage`, that class being importable from `beartype.door` as well. Its `residual` is a hint, `matched` a tuple holding one hint per covering hint, `unreachable` and `removable` tuples of indices in ascending order, `overlapping` a tuple of index pairs in ascending order, and `is_exhaustive` a boolean. Every hint it reports is canonical. Each covering hint is matched against the residual only, which starts as the covered hint: `matched` holds the meet of the residual and that hint, `None` when there is none, in which case that index is `unreachable`, and the residual then becomes its difference with that hint.

Once the residual is gone every later hint is unreachable. `overlapping` pairs the indices `(i, j)` with `i` before `j` of covering hints that are not disjoint with each other, whatever the residual. `removable` holds every index whose omission would leave the same residual. `is_exhaustive` holds when no residual is left.
