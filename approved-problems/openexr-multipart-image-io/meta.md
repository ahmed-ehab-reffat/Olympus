Title: Add high-level multipart Image I/O

Add high-level multipart image I/O to `ImfImageIO.h`, so callers can use `Image` objects without assembling frame buffers themselves.

Represent a part with a move-only `ImagePart` containing public `Header header` and `std::unique_ptr<Image> image` members and an `ImagePart(Header, std::unique_ptr<Image>)` constructor. Call the corresponding `std::vector` alias `ImageParts`. Add `saveImages()` and `loadImages()` overloads for UTF-8 filenames and existing `OStream` or `IStream` objects. The save forms take an optional `DataWindowSource`, defaulting to `USE_IMAGE_DATA_WINDOW`.

Loading should handle both ordinary single-part files and multipart files. Return supported parts in file order and skip unknown multipart types. Cover the same flat and deep scanline or tiled images, including one-level, mipmap, and ripmap layouts, that the current high-level helpers support. Each result owns its header and image data; part storage must not be shared.

Also add `loadImagePart()` for a filename or `IStream` and an exact, case-sensitive part name. It returns the same complete header and image as a full load of that part, while unreadable data in another part stays out of the way. A second pair of overloads takes a `Box2i`. For a `ONE_LEVEL` flat or deep scanline or tiled part, return the intersection with its data window and update both returned windows. Keep all channel metadata and samples inside the result. Reject missing intersections, mipmap or ripmap parts, and windows that do not align with channel sampling. Damage confined to scanlines or tiles outside the result should not block this load.

`saveImages()` takes a nonempty collection whose images are non-null flat or deep values and whose header names are nonempty and unique. Apply the existing `saveImage()` header and data-window rules to every part. Preserve order, headers, channels, level layout and rounding, flat pixels, and deep counts and samples through both filename and stream APIs. Later changes to caller inputs must not affect data already written.

Finally, add `rewriteImages()` for distinct input and output UTF-8 filenames and for an `IStream`/`OStream` pair. Both forms take replacements plus the same optional `DataWindowSource`. Match replacements by exact header name, keep supported source parts in order, and skip unsupported ones. Encode each replacement exactly as `saveImages()` would, including its complete emitted header. Copy every untouched part without changing its header, compression, or decoded samples; this must also work when that untouched payload is unreadable. An empty replacement list simply rewrites the supported parts, including an unnamed supported single-part source.

Reject null or unsupported replacement images, missing or duplicate replacement names, names that do not match a supported source part, invalid header-window requests, and identical input/output filenames before modifying the destination.
