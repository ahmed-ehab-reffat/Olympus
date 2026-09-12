# Accept expressions where filters used to require literal values

A comparison in this filter language only accepts a literal to the right of the operator, so a filter cannot relate one field to another. Extend it so that wherever a literal value was required the language also accepts an expression that produces that value during execution: a field, an indexed access into an array or a map, or a function call. Both sides of a comparison must have the same type once map-each indexing is accounted for, and a filter whose sides disagree on type must not parse.

An `in` operand is an expression of array type holding the left side's type. Booleans order false below true. `contains` additionally accepts a braced set that mixes literals and expressions, matching when the left value contains any element; each element yields a single value rather than a mapped one, an element without a value never matches, and an empty set never matches. Regular expression and wildcard patterns still have to be literals.

Whole arrays and maps compare for equality only. Arrays are equal when they have the same length and their elements are equal in order; maps are equal when they hold the same keys and every key's values are equal. The other ordering operators must not parse for these types.

An index may also be computed: an array index is an expression of type Int, a map key an expression of type Bytes. A key the map does not hold, a negative index, and an index past the end all leave the access without a value. A computed index and `[*]` cannot both appear in one access chain, at any level of it.

When only the right side of a comparison maps over a collection, each of its elements is compared against the value on the left. When both sides map, elements pair by position and the comparison produces one boolean per pair, stopping at the shorter side.

If either side has no value the comparison does not match, except for the not equal operator, which matches, and a mapped side that has no value produces no booleans at all. Fields reached through an operand or a computed index are part of the filter, so asking whether a filter uses a field must account for them.
