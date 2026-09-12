# Solution approach

The reference implementation separates Adam7 row construction from PNG
compression. The existing decoder-side pass iterator supplies pass geometry;
an encoder helper walks the caller's ordinary raster, selects pass pixels, and
creates one packed row at a time. Byte-aligned pixels are copied by complete
pixel width. Sub-byte grayscale and indexed samples are extracted and repacked
from the high bit so source and pass-row padding never become pixels.

The static slice writer validates the ordinary raster length before selecting
the interlaced path. Each compression backend consumes the generated rows in
pass order. Filter prediction uses the preceding row only when it belongs to
the same pass, with an all-zero predecessor at each pass start. The
no-compression and fdeflate stored fallback paths write the same pass-row
framing without requiring compressed-byte equality.

The stream writer retains static interlaced input until the exact ordinary
raster is complete, then invokes the same transformation and writes the zlib
stream through the established chunk writer. This preserves arbitrary caller
write boundaries, exact-length completion, owned and borrowed stream forms,
the stream writer's public filter override, and the configured IDAT payload
ceiling. Existing streaming remains unchanged for non-interlaced images.

Header initialization now permits interlacing only for static images. The
existing APNG rejection is intentionally retained because frame/default-image
interlace policy is outside the task. The former unit regression is updated
from expecting rejection to verifying successful static output.
