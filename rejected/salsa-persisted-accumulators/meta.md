Title: Persist accumulator outputs with tracked queries

Add persistence support for Salsa accumulators. An accumulator annotated with
`#[salsa::accumulator(persist)]` must retain values produced by persisted
tracked queries across database serialization and deserialization, and the
annotation must accept `serialize` and `deserialize` hooks with the same
semantics as other persisted Salsa values.

Restored values must be available through the existing generated
`accumulated` API without re-executing an eligible persisted producer. This
also applies when the API is called on a restored persisted caller whose
values were produced by a restored persisted callee. Preserve each accumulator
type separately along with its production order and duplicate values.

Accumulators not marked `persist` must remain usable with payload types that do
not implement serde traits. Existing behavior for values produced solely by
non-persisted tracked queries is unchanged, and no particular serialized byte
layout is required.
