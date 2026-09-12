# Solution approach

Keep the existing singular API and add the move-owned part record, ordered collection, filename overloads, stream overloads, and named-part overloads in `ImfImageIO.h`.

Factor save preparation so filename and `OStream` entry points validate every part and build the same ordered headers. Construct `MultiPartOutputFile` with the supplied transport, then dispatch flat/deep and scanline/tiled parts. Preserve the singular helper's data-window, tile-description, channel, rounding, and deep-compression rules for every level.

Factor one indexed decoder around `MultiPartInputFile`. It copies the selected header, creates the matching `FlatImage` or `DeepImage`, allocates all level structures and channels, reads deep sample counts before deep samples, and returns independently owned state. `loadImages()` calls it in file order.

For `loadImagePart()`, inspect headers for an exact name match and invoke the indexed decoder only for that part. Do not implement selection as `loadImages()` followed by filtering, because an invalid unselected pixel payload must not prevent a valid selected part from loading. The same helper can serve filename and caller-owned `IStream` entry points without taking ownership of the stream.

For `rewriteImages()`, validate and match every replacement before constructing the output. Build output headers in supported source-part order. Encode matched `ImagePart` replacements through the same per-family writers used by `saveImages()`, and transfer unmatched parts without decoding their pixels so their compressed generation and even an existing unreadable payload are preserved. Dispatch the transfer across flat/deep and scanline/tiled input/output part pairs. An empty replacement collection follows only the structural-transfer path.

Use the same rewrite planner for filename and stream transports. Filename input and output must differ, and neither stream is owned by the helper. Open multipart inputs in the repository's tolerant header mode so unknown part types can be skipped without making supported siblings unavailable.

This is one valid structure, not a hidden layout requirement. Alternative dispatch tables, staging strategies, buffering, and temporary files are acceptable when they preserve the public behavior.
