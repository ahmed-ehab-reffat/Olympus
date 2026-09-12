Title: Add static Adam7 PNG encoding

Add Adam7 interlacing support to static PNG encoding. When `Info::interlaced` is true, `Writer::write_image_data` must accept the same complete ordinary row-major raster used by non-interlaced encoding and emit a valid interlaced PNG. Write the seven standard Adam7 passes in order, omit passes with no samples or rows, and restart row-filter history for every nonempty pass.

Support every color-type and bit-depth combination already accepted by the encoder, including 1-, 2-, and 4-bit grayscale and indexed images. Sub-byte input keeps the existing most-significant-bit-first, row-padded representation; pass rows must select logical samples and repack their final-byte padding correctly.

Preserve the selected `Filter` and `DeflateCompression` behavior. Both borrowed and owning `StreamWriter` entry points must accept the ordinary raster across arbitrary write boundaries, enforce its exact total length, and keep their configured IDAT chunk-size ceiling. Slice input must retain the same exact-length contract, and existing static sequence validation must remain effective.

Keep non-interlaced encoding compatible. Animated PNG interlacing is outside this task and may remain rejected. Compressed byte identity, buffering strategy, allocation limits, and exact error wording are not prescribed.
