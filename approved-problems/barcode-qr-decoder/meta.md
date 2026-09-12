---
Repository: https://github.com/boombuler/barcode
Issue: N/A
Commit: 3c3de55b6b64c2a9d5a0c96f2e3ebceaef576986
Language: Go
Title: Add a QR Code Decoder to the qr Package
---
# Add a QR Code Decoder to the qr Package

Add a QR decoder to the qr package: a new `Decode` function and `DecodeResult` type.

`Decode(img image.Image) (*DecodeResult, error)` returns a `DecodeResult` whose fields are `Content` (string), `Version` (byte), `Level` (the `ErrorCorrectionLevel`), and `Mask` (int, the mask index). It locates the symbol within the image, tolerating a surrounding quiet zone and an integer pixel scale. It reads both copies of the format information and uses whichever is still intact.

Damaged modules are corrected up to the symbol's error-correction capacity; damage beyond that capacity, an unreadable format, or an absent symbol are reported as an error. The decoded content may be numeric, alphanumeric, or byte (UTF-8).

Add to the root barcode package a `barcode.RegisterDecoder` that accepts a decoder func from `image.Image` to `(barcode.Barcode, error)`, and a package-level `barcode.Decode(img image.Image) (barcode.Barcode, error)` that tries the registered decoders and returns the first successful `barcode.Barcode`. The qr package registers its decoder there, and its decoded `barcode.Barcode` reports `CodeKind` `barcode.TypeQR` from `Metadata()`.
