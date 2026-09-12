---
Repository: https://github.com/Mojang/DataFixerUpper
Issue: N/A
Commit: 5fc0978694e996cfe68a742b67a0d506c17de3f0
Language: Java
Category: feature-request
Title: Add ordered multi-way alternative codecs to the serialization DSL
---

# Add ordered multi-way alternative codecs to the serialization DSL

Add `Codec.orderedAlternatives` and `MapCodec.orderedAlternatives` as static factories that take a list of codecs.

Decoding tries candidates in list order. The moment any candidate fully succeeds, that is the result, even if an earlier candidate produced only a partial. If nothing fully succeeds, the result carries the partial value of the earliest candidate that produced one. If no candidate produces a value, the result is a plain error with no partial. When the combined result is an error, its message reports every attempted candidate, in list order.

A full success keeps the winning candidate's own lifecycle. If no candidate fully succeeds, combine the lifecycles of every candidate that contributed a partial result, ignoring candidates that failed outright. That combination uses each lifecycle's own combining rule, which keeps the lower deprecation version number when two are deprecated. When no candidate contributed a partial, the lifecycle is stable.

Encoding a `Codec` built this way scans candidates the same way decoding does. Encoding a `MapCodec` built this way always goes through the first candidate only. The builder that `encode` returns carries what that candidate reported, even when the candidate hands back a replacement builder. On a full success or a partial, the lifecycle is that candidate's own; on an outright failure carrying no partial, it is stable instead. A lifecycle applied to the whole codec afterwards, as `withLifecycle` and `deprecated` do, still wins over that stable normalization. That failure names the first candidate by position, or by label from the labeled factory, whatever RecordBuilder the caller supplies. Everything the ordered codec adds goes to the builder it returns, so when a candidate hands back a different builder the supplied one is left exactly as that candidate left it. `keys(ops)` remains the concatenation, in list order, of every candidate's own keys, keeping duplicates.

The plain factories accept a covariant candidate list, so a list of a narrower candidate type still compiles, and encoding a value one of those narrower candidates cannot handle at runtime is treated as that candidate's own failure rather than aborting the encode. A companion `orderedAlternativesLabeled` factory on both types accepts a list of `Pair<String, Codec<A>>` (or `Pair<String, MapCodec<A>>` for `MapCodec`, using `com.mojang.datafixers.util.Pair`), reporting each candidate's label instead of its zero-based position in error messages.

A null or empty candidate list, a null entry in the labeled list, a duplicate candidate instance, a duplicate label, and a blank or whitespace-only label all raise `IllegalArgumentException`. A null codec or a null label raises `NullPointerException`. The codec's `toString()` lists every candidate, separated by a comma and a space, inside `OrderedAlternatives[...]` (or `OrderedAlternativesMapCodec[...]` for `MapCodec`), prefixing each candidate with its label and an equals sign when the labeled factory was used. Two such codecs are equal exactly when built from the same candidate instances, in the same order, with the same labels.
