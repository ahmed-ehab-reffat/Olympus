# Solution approach

The reference adds a persistable state image to the existing stateful
`ThetaAnotB` implementation while preserving its set-difference algorithm.
The image records the seed hash, empty state, theta, retained count, and
retained hashes using the common Theta set-operation preamble.

`ThetaAnotB` gains byte serialization and typed wrap factories.
`ThetaSetOperation` dispatches A-not-B images from generic heapify/wrap, and
`ThetaSetOperationBuilder` supports both family-based direct construction and
the convenience direct builder. Heap restoration validates and copies image
state. Wrapping validates but retains the supplied `MemorySegment`, reading
state from it and writing every mutation back to it.

All direct mutations preflight required capacity before writing. Reset uses the
same state writer, including the reset performed before the existing null-A
error. Read-only wrappers allow result, serialization, and stateless calls but
reject stateful mutation through the repository's read-only exception family.
Generic source-header checks convert short-image failures into the established
argument-exception family before dispatch.

Because direct construction changes a pre-existing unsupported-operation
contract, the reference patch also replaces that obsolete regression with an
unconditional check that the built operation owns the supplied resource. This
compatibility edit is reference-only; the verifier patch remains additive so
participant test edits cannot collide with hidden-test injection.

This compact state image is only the reference architecture. The task permits
separate heap/direct implementations, a shared state object, a hash table, an
updatable-sketch-backed design, or another representation with equivalent
public ownership, restoration, validation, and lifecycle behavior.
