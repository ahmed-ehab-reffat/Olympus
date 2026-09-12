# Extend total ordering to compound values in Dyon

Extend the ordering operators `<`, `<=`, `>`, and `>=`, and the `min` and `max` functions, to accept arrays, objects, options, booleans, and vec4 values.

Comparing different kinds is an error whose message contains the word type. Booleans order with false below true. A vec4 compares by component x, then y, then z, then w.

Arrays compare element by element. The first position whose elements differ decides the result. When every compared element is equal the shorter array is the smaller one, so a proper prefix is less than the longer array.

Objects compare by their keys taken in ascending byte order. Walk the sorted key and value pairs of both objects and compare each key and then its value. An object with fewer keys whose shared leading pairs are equal is the smaller one.

An option orders none below any some value and compares two some values by their contents.

Add `cmp(a, b)` returning -1, 0, or 1 under this order. Add `sort(a)`, an ascending sort, and `dedup(a)`, which drops each element equal to the one before it. Add `is_sorted(a)` and `sorted_insert(a, x)`, which places x before the first larger element.

Over a sorted array, add `bsearch(a, x)` returning `some(index)` for a matching element or `none()`, `lower_bound(a, x)` and `upper_bound(a, x)` returning the leftmost and rightmost insertion indices, and `union(a, b)` and `intersect(a, b)` producing deduplicated results.

Add `argsort(a)` returning the indices that would sort a, `rank(a)` giving each element the count of strictly smaller elements, `group_by(a)` splitting runs of equal elements into subarrays, `merge(a, b)` merging two sorted arrays, `median(a)` returning the lower middle element, and `kth_smallest(a, k)` returning the element at sorted position k.

Ordering a value that contains nan is an error whose message contains the word nan. The `min`, `max`, and `median` functions error on an empty array with a message containing the word empty.
