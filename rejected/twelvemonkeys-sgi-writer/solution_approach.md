# Solution approach

Introduce an SGI writer, write parameter, and writer SPI, then register the SPI in the module's Java and OSGi service metadata. Normalize either raster or rendered-image input into a selected raster view described by its source bounds, subsampling, requested bands, output dimensions, and common sample width.

Emit a 512-byte big-endian SGI header followed by channel-planar rows in bottom-up order. The uncompressed path writes selected samples directly. The compressed path reserves both row tables, encodes each channel-row with literal and repeated packets capped at 127 samples, records its absolute offset and encoded length, and seeks back to populate the tables. Encode every atom at the selected sample width, including the high zero byte of 16-bit control atoms.

Make the existing reader's RLE decoder sample-width aware so standards-compliant 16-bit compressed files round-trip. Preserve the one-byte behavior for existing 8-bit fixtures.
