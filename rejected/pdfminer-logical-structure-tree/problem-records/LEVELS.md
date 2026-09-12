# LEVELS - pdfminer.six logical structure tree

Target band: 1 to 5 solves in 10 completed platform runs. The current local
Long-horizon record is a successful-solution median of at least two production
files, 20 platform-reported agent messages, and 200 strict effective production
LOC.

## History

| Level | Behavioral lever | Tests | Reference files / effective LOC | Successful solver median: files / messages / LOC | Platform | Verdict |
|---|---|---:|---:|---|---|---|
| L1 | semantic structure graph plus page/Form content association, all child/layout producer families, ParentTree recursion, context overrides, and safe malformed graphs | 14 | 6 / approximately 439 | not yet measured | 0/10 | uncalibrated; forecast 1-3/10 |

## Current level

### What changed

The initial 10-test suite was hardened from repository-grounded mutation
survivors. L1 added positive ParentTree child-node traversal, MCR-local page
override, actual image and vector layout objects, and multi-entry direct/class
attribute expansion. Each discriminator targets a separate parser or renderer
branch and isolates its mutant at 13/14.

### What did not change

The task remains semantic extraction of the explicit PDF structure order. It
does not infer visual reading order, repair arbitrary corrupt PDFs, define
reusable-Form occurrence aggregation, or prescribe private graph/cache
architecture. The public model and error latitude in `meta.md` are unchanged
from artifact authoring.

### Evidence and next decision

Pristine is 0/14 focused and 249/249 base. Reference is 14/14 focused,
249/249 base, 263/263 combined, Ruff-clean, and mypy-clean. Exact environment,
gap, fairness, and false-positive gates pass. No solver patch exists, so fresh
calibration is 0/10 and compatibility replay is unavailable. Run the local
frontier pre-filter on the immutable version before any platform probe.
