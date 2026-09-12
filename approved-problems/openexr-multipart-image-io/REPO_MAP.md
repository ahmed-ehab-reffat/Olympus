# REPO MAP - AcademySoftwareFoundation/openexr

Last verified: 2026-08-13 at
`c101ab742a9e93c8c9c6f1781055e938cc160305`.

## Build and test entry points

| Purpose | Command | Offline constraints |
|---|---|---|
| Configure | `cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON -DOPENEXR_BUILD_EXAMPLES=OFF -DOPENEXR_BUILD_TOOLS=OFF` | Imath, zlib, and libdeflate must be installed; vendored OpenJPH is present. |
| Build | `cmake --build build --parallel` | No runtime fetch after configuration. |
| Existing util tests | `ctest --test-dir build -R '^OpenEXRUtil\.' --output-on-failure` | Four repository tests; generated temporary EXRs only. |
| Complete suite | `ctest --test-dir build --output-on-failure` | 127 tests passed in Phase A. |
| Style | `git diff --check` and repository clang-format when available | No network. |

## Relevant subsystems

| Subsystem | Public entry point | Important source files | Existing tests | Why it matters |
|---|---|---|---|---|
| Generic high-level image I/O | `saveImage`, `loadImage` | `src/lib/OpenEXRUtil/ImfImageIO.{h,cpp}` | `src/test/OpenEXRUtilTest/testIO.cpp` | Natural public API and current multipart refusal. |
| Flat images | `FlatImage`, flat single-image I/O | `ImfFlatImage*.{h,cpp}` | `testFlatImage.cpp`, `testIO.cpp` | Scanline/tiled channels and level frame buffers. |
| Deep images | `DeepImage`, deep single-image I/O | `ImfDeepImage*.{h,cpp}`, `ImfSampleCountChannel.*` | `testDeepImage.cpp`, `testIO.cpp` | Two-phase sample-count allocation and sample slices. |
| Multipart I/O | Four input/output part class pairs and `copyPixels()` | `src/lib/OpenEXR/Imf*Part.*`, `ImfMultiPart*File.*` | `OpenEXRTest/testMultiPart*.cpp` | Ordered heterogeneous file mechanics and raw part transfer. |
| Header/type model | `Header`, `PartType`, `TileDescription` | `ImfHeader.*`, `ImfPartType.*` | header and multipart tests | Names, types, shared attributes, windows, channels, and tiling. |

## Data and control flow

For save, the collection record supplies a header and decoded `Image`. The
per-part header is reconciled with image channels, data window, flat/deep kind,
and level/tiling mode before `MultiPartOutputFile` is opened. The selected
output-part class receives a flat or deep frame buffer for each relevant
scanline range or tiled level.

For load, `MultiPartInputFile` exposes ordered headers. The type selects a flat
or deep image and one scanline/tiled input-part class. Channels and level
storage are allocated from the header; deep sample counts are read before deep
samples. Each result then owns its copied header and decoded image.

For selective rewrite, source headers determine output order. A supported part
with an exact-name replacement is encoded through the high-level save rules;
an untouched supported part is copied through its matching low-level part
family without decoding it. Unknown source types are omitted. This hybrid path
preserves untouched compression, metadata, and unreadable pixel payloads while
still allowing a later named part to be replaced.

## Public oracles

- Reopen output through `MultiPartInputFile` and the four low-level part APIs.
- Reload output through the new high-level collection API.
- Compare `Header` fields, channel metadata, level modes/windows, flat values,
  deep counts, and deep samples.
- Mutate source/result values and observe sibling/file isolation.
- Corrupt an untouched source chunk and verify that a later replacement still
  succeeds while the copied part remains unreadable.
- Mix supported and unknown source types and verify supported output order.

## Extension seams

| Seam | Evidence it is repository-native | Expected files | Main risk |
|---|---|---|---|
| Plural generic Image I/O | Existing singular generic functions and explicit multipart refusal. | `ImfImageIO.h`, `ImfImageIO.cpp` | Public collection ABI and ownership. |
| Shared internal part adapters | Four low-level classes mirror singular file classes. | Same two files or refactored flat/deep I/O files. | Regressing singular behavior. |
| Hybrid selective rewrite | Each output-part family has a matching `copyPixels()` overload for its input-part family. | Implementation-selected. | Accidentally decoding untouched parts or aborting on unknown siblings. |
| Temporary single-part bridge | `copyPixels()` accepts input files and input parts for all four families. | Implementation-selected. | Cleanup/collision robustness; legitimate for decoded load/save helpers but insufficient for unreadable untouched rewrite parts. |

## Hazards

- Generated files: CMake build output must never enter patches.
- Shared multipart attributes: display window and other common attributes must
  satisfy existing writer validation; tests use valid shared values.
- Deep compression: existing high-level helpers normalize deep output to ZIPS.
- Fixtures: generated in memory or under the test temporary directory; no
  external licensing or corpus dependency.
- Validation: missing/duplicate names and null/unsupported images must be found
  before unsafe dereference; exact error text is not contractual.
