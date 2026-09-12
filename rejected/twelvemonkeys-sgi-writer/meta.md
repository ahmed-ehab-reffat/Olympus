Title: Add SGI image writing support

Add ImageIO writing support to the SGI plugin for the ordinary image modes its reader already represents. The writer must be discoverable through ImageIO and support grayscale, grayscale with alpha, RGB, and RGBA data using unsigned 8-bit or 16-bit samples.

Write both uncompressed and run-length encoded SGI images. Output must use a valid big-endian SGI header, channel-planar bottom-up rows, and, for compressed images, valid per-channel/per-row offset and length tables. RLE packets must support literal and repeated samples, split runs at the format limit, terminate each row, and use atoms matching the sample width. In particular, 16-bit RLE control atoms occupy two bytes with the control value in the low byte. Files produced in every supported mode must be readable by the existing SGI reader; repair that reader if necessary for valid 16-bit RLE data.

Honor standard ImageWriteParam source regions, subsampling periods and offsets, and source-band selection in caller-specified order. Apply selection before validating SGI dimensions, channel count, and sample width, and accept both rendered-image and raster IIOImage inputs when the selected layout is representable. Reject empty or oversized selections and unsupported or nonuniform sample layouts without emitting a partial image.

Metadata writing, image sequences, obsolete color-map modes, palette preservation, floating-point samples, and insertion into existing files are out of scope.
