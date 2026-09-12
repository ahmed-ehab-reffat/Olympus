# Known error families

- Writing top-down or pixel-interleaved data while producing a superficially valid header.
- Treating 16-bit RLE controls as one-byte atoms or normalizing unsigned samples.
- Producing row payloads without correct absolute offset and length tables.
- Omitting literal packets, repeat packets, row terminators, or 127-sample splitting.
- Applying source selection after dimension/channel validation, ignoring offsets, or sorting selected bands.
- Registering a concrete writer without making it discoverable through ImageIO.
- Writing valid 16-bit RLE that the existing byte-oriented reader cannot decode.
