# Repository map

- `imageio/imageio-sgi`: target Maven module.
- `SGIImageReader`, `SGIImageReaderSpi`, `SGIHeader`, and `RLEDecoder`: existing reader-side format behavior.
- `SGIProviderInfo`: ImageIO provider metadata and current reader/writer association.
- `META-INF/services`: Java ImageIO service discovery.
- `imageio-core` test utilities: shared reader/writer contract harnesses.
- `imageio/imageio-sgi/src/test/resources`: existing real SGI fixtures.

The reference solution adds the writer-side classes within the existing SGI package and makes the narrow reader change required for two-byte RLE atoms.
