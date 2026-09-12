# Upstream audit - tifffile OME pyramid validation

Audit date: 2026-08-06

Repository: [`cgohlke/tifffile`](https://github.com/cgohlke/tifffile)

Frozen pin and current default-branch head:
`940f7630df48edf8e13913962035ed80b408b5f4` (`master`, release v2026.7.31,
2026-08-01).

## Eligibility and provenance

The public repository was active at the audit date, not archived, had 660
stars and 161 forks, used BSD-3-Clause, and had issues enabled. Discussions are
disabled and `master` is the only upstream branch. The latest 100 fetched
commit records contained zero direct agent-attribution markers. No repository
agent instruction or security file changed the audit procedure.

The production implementation is Python. Source inspection counted 695 direct
test functions and 129 parametrizations. The package and its test extras install
under Python 3.14, and a bounded 706-test repository lane plus five adjacent
SubIFD writer/error tests pass in an official Python image with networking
disabled.

## Exact ownership searches

GitHub all-state issue and pull-request searches covered
[`validate pyramid`](https://github.com/cgohlke/tifffile/issues?q=is%3Aissue%20%22validate%20pyramid%22),
[`OME pyramid validation`](https://github.com/cgohlke/tifffile/issues?q=is%3Aissue%20%22OME%20pyramid%22%20validation),
[`OME-TIFF consistency`](https://github.com/cgohlke/tifffile/issues?q=is%3Aissue%20%22OME-TIFF%22%20consistency),
[`validate OME`](https://github.com/cgohlke/tifffile/issues?q=is%3Aissue%20validate%20OME),
[`validator`](https://github.com/cgohlke/tifffile/issues?q=is%3Aissue%20validator),
[`SubIFD validation`](https://github.com/cgohlke/tifffile/issues?q=is%3Aissue%20SubIFD%20validation),
and
[`NewSubFileType`](https://github.com/cgohlke/tifffile/pulls?q=is%3Apr%20NewSubFileType).
The issue results were cross-checked with all-state pull-request searches for
[`validate pyramid`](https://github.com/cgohlke/tifffile/pulls?q=is%3Apr%20%22validate%20pyramid%22),
[`OME-TIFF validation`](https://github.com/cgohlke/tifffile/pulls?q=is%3Apr%20%22OME-TIFF%22%20validation),
and
[`SubIFD validation`](https://github.com/cgohlke/tifffile/pulls?q=is%3Apr%20SubIFD%20validation),
plus release notes, source, tests, fetched history, and the sole default branch.

The decisive results were:

- issues for `validate pyramid`, `OME pyramid validation`, and `OME-TIFF
  consistency`: zero exact results;
- pull requests for `validate pyramid`, `OME-TIFF validation`, and `SubIFD
  validation`: zero exact results;
- `SubIFD validation` returned only
  [issues #326](https://github.com/cgohlke/tifffile/issues/326) and
  [#328](https://github.com/cgohlke/tifffile/issues/328), which concern DNG
  SubIFD tree reading and page relationships, not OME pyramid conformance;
- the one `NewSubFileType` pull-request result,
  [closed PR #62](https://github.com/cgohlke/tifffile/pull/62), is Aperio
  support and does not implement this validator;
- broader `validate OME` results point to metadata/rewrite conversations such
  as [#119](https://github.com/cgohlke/tifffile/issues/119), not a
  storage-topology validator.

[Issue #326](https://github.com/cgohlke/tifffile/issues/326) was fixed in
v2026.5.2 and shows that SubIFD trees remain an active maintainer-owned reader
area. It does not expose OME pyramid validation.
[Issue #207](https://github.com/cgohlke/tifffile/issues/207) points pyramid
users to the OME specification and tifffile's examples.
[Issue #119](https://github.com/cgohlke/tifffile/issues/119) recommends
rewriting selected series and handling OME-XML manually for structural
removal; together with
[#74](https://github.com/cgohlke/tifffile/issues/74), it supports excluding
deterministic normalization rather than claiming an upstream repair contract.
Issues [#132](https://github.com/cgohlke/tifffile/issues/132),
[#140](https://github.com/cgohlke/tifffile/issues/140),
[#153](https://github.com/cgohlke/tifffile/issues/153), and
[#159](https://github.com/cgohlke/tifffile/issues/159) are adjacent historical
page-flag, series-level, pyramid, and format-specific behavior, but none owns
the proposed API or complete contract.

## Source and release-history audit

At the pin, `TiffPage.subifds`, `TiffPage.is_subifd`,
`TiffPage.is_reduced`, `TiffFile.pages`, `TiffPageSeries.levels`,
`subresolution`, `pyramidize_series`, and `series_ome` expose or infer the
relationships a validator needs. `OmeXml.validate` validates XMLSchema only;
`validate_jhove` delegates file validation to an external JHOVE executable.
Neither checks OME pyramid storage topology.

Recent releases added/fixed DNG SubIFD trees and multi-file pyramidal OME
handling, which confirms active maintenance and raises the value of a clean
pin. No release note, source TODO, abandoned branch, or merged/closed pull
request supplies the proposed read-only OME validator.

## Local prior art

Local searches found no tifffile problem or solver run. The closest compact
candidate is `geotiffjs/geotiff.js` nested SubIFD traversal, rejected at 4/10
because public issue #524 owns that repository's traversal request and a broad
version would aggregate several independent backlogs. The proposed tifffile
task neither adds SubIFD traversal nor writes/repairs a pyramid; it validates
relationships already exposed by tifffile against the OME contract.

Result: no ownership collision was found for read-only OME-TIFF pyramid
validation at the frozen pin. Deterministic normalization is not cleared and
is explicitly out of scope. Repeat this audit if the pin, API, strictness
semantics, or public contract changes.
