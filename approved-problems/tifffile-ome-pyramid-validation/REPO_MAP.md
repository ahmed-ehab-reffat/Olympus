# Repo map - cgohlke/tifffile

Last verified: 2026-08-06 at
`940f7630df48edf8e13913962035ed80b408b5f4`.

## Build and test entry points

| Purpose | Command | Offline constraints |
|---|---|---|
| Install | `python -m pip install --no-cache-dir -e ".[test]"` | performed while building the frozen image |
| Existing bounded regression suite | `./test.sh base` after `test.patch` | skips external files, HTTP, XMLSchema validation, large, slow, and extended cases |
| Focused problem suite | `./test.sh new` after `test.patch` | generated temporary TIFFs only |
| Format and lint | `black --check` and `ruff --config pyproject.toml` on changed Python | run on the frozen prototype before patch generation |

## Relevant subsystems

| Subsystem | Public entry point | Important source files | Existing tests | Why it matters |
|---|---|---|---|---|
| TIFF reader | `TiffFile`, `TiffPage` | `tifffile/tifffile.py` | `tests/test_tifffile.py` | owns primary chains, raw tag 330 offsets, page shapes, axes, and reduced-image flags |
| OME series builder | `TiffFile.series`, `TiffPageSeries.levels` | `tifffile/tifffile.py` | OME and pyramid tests in `tests/test_tifffile.py` | maps OME `TiffData` planes and exposes grouped resolution levels |
| TIFF writer | `TiffWriter.write(..., subifds=...)` | `tifffile/tifffile.py` | SubIFD chain/tree and OME writer tests | generates small valid and malformed-topology fixtures without external data |
| XML metadata helper | `OmeXml` | `tifffile/tifffile.py` | OME metadata tests | supplies the assertion convention; XMLSchema validation is intentionally not part of the task |

## Data and control flow

Opening `TiffFile` parses the header and lazy primary IFD chain. OME metadata
constructs image series and maps full-resolution planes; each base page's tag
330 names direct child offsets. The validator reconciles those three public
views, loads child IFD structure without decoding pixels, checks required
ownership/order/shape rules, then optionally checks strict recommendation-only
flags and downsampling factors. It converts malformed relationships into the
documented boolean/assertion result and never writes the file.

## Public oracles

- OME-TIFF 6.3.1 sub-resolution storage requirements and recommendations.
- `TiffPage.subifds`, `is_subifd`, `is_reduced`, shape, and axes.
- `TiffFile.pages` primary-chain membership and OME series mappings.
- Existing `subresolution` floor-or-ceiling odd-dimension compatibility.
- Byte-for-byte input equality before and after validation.

## Extension seam and hazards

The repository-native seam is a public `TiffFile` query beside lifecycle/read
operations in `tifffile/tifffile.py`. A second parser or writer is unnecessary.
The main hazards are trusting grouped `series.levels` without reconciling raw
offset ownership, treating a child `NextIFD` chain as a direct OME list,
over-applying recommendation checks in default mode, decoding pixels, or
calling online-capable XMLSchema validation. Generated tests avoid fixture
licensing and network dependencies.
