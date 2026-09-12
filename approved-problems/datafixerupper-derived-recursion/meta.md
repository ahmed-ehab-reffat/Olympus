---
Repository: https://github.com/Mojang/DataFixerUpper
Issue: N/A
Commit: 5fc0978694e996cfe68a742b67a0d506c17de3f0
Language: Java
Category: feature-request
Title: Derive schema type recursion from the type template graph
---

# Derive schema type recursion from the type template graph

Add derived recursion structure to `Schema`. Right now the caller declares which registered types are recursive by passing a flag to `registerType`, and a wrong answer is fatal: types that refer to each other in a cycle without the flag recurse forever while the schema is being built, and a schema that declares no recursive type cannot be built at all.

Work the structure out from the templates instead. While a schema is being constructed, take each registered type's template and find which other registered types it refers to. A type is recursive when it lies on a cycle of those references, or when it was registered with the flag set, so the flag now forces recursion on rather than declaring it. A type that merely refers to a recursive type, without lying on a cycle itself, is not recursive.

Two recursive types belong to the same recursion group when each is reachable from the other, so a type that is recursive only because the flag was set, and lies on no cycle, is a group of its own. Build one recursion family per group instead of one for the whole schema, so a recursive type's unfolded form no longer carries branches for unrelated recursive types. Recursion indices start at zero within each group and follow registration order, and `getTypeRaw` still hands back a recursive type's recursion point. A reference to a recursive type outside the group being built resolves to that type as already built. A schema with no recursive types still builds.

Reject recursion that can never bottom out. A type has a value only if its template can produce one without resolving a reference to a type that has none. Throw `UninhabitedRecursionException`, whose `types()` returns every type with no value, in registration order. A reference to a name that was never registered stays an unknown type rather than a type without a value.

Add `recursiveTypeNames()`, returning the names of the recursive types in registration order; `recursionGroups()`, returning the groups as lists of names, with members in registration order and groups ordered by their earliest-registered member; and `typeReferences(TypeReference)`, returning the names of the distinct registered types that type's template refers to, in registration order. Registration order is the order of the first `registerType` call for each name, and re-registering a name replaces its template without moving it. Add a `registerType(TypeReference, Supplier<TypeTemplate>)` overload that registers without the flag.
