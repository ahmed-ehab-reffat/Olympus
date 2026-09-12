Title: Preserve named definitions when merging subtitles

Fix merging documents with colliding style or region IDs so it preserves the meaning of both documents. When the receiver and donor contain different definitions under the same ID, every merged cue must still serialize and reparse against the definition it referenced before the merge. Preserve the receiver's existing definitions and references, and do not change the donor while resolving collisions.

Handle every named-reference relationship supported by the subtitle model. Shared references in the donor must remain coherent in the merged document. Generated definition identities must be unique and deterministic for equivalent inputs, including when an obvious generated identity is already occupied; callers must not depend on Go map iteration order.

Keep stable item ordering, including receiver items preceding donor items when their start times are equal. Do not add format capabilities: preservation is required only when the chosen output format can represent the referenced feature.
