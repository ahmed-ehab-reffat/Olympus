---
Repository: https://github.com/oxipng/oxipng
Issue: N/A
Commit: 36f3ef8aac65ecf1761739ea2f2e530281f1312b
Language: Rust
Category: feature-request
Title: Add reductions and frame cropping for animated PNGs
---

# Add reductions and frame cropping for animated PNGs

Add color reductions and frame cropping and merging to the optimization of animated PNGs. Today an APNG gets no reductions at all and only has its image data recompressed.

The default image and every frame share one IHDR, PLTE and tRNS, so reductions are now decided for all of them together, including a default image that is not part of the animation, and are decided on the frames as they are written, after cropping and merging. The interlacing option now applies to animations too, to every frame alike.

A new `frame_reduction` option in `Options`, on by default in every preset and turned off by a new `--nf` flag and by `--nx`, crops and merges frames. Every frame after the first is cropped to the smallest rectangle inside its region that still displays the same canvas and leaves the same canvas for the frames after it. Its dispose and blend operations stay as they are, and a frame that needs no pixels but has to be kept becomes a single pixel of its region. A frame is merged into the frame before it when dropping it and adding its delay to that frame changes neither what is displayed nor what the following frames are drawn over. Delays are added exactly, with a zero denominator meaning hundredths of a second, and if the total cannot be written with a 16-bit numerator and denominator the frame is not merged. The acTL frame count is rewritten and the play count is kept. Throughout, fully transparent pixels are equal whatever their color.

With the `sanity-checks` feature, output validation has to accept an optimized animation: it compares what is displayed and for how long, not frame by frame.
