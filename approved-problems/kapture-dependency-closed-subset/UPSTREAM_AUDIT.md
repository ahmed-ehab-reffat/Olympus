# Upstream audit — kapture dependency-closed dataset subset

Status: `pass for selection as of 2026-08-17`.

Repository: `naver/kapture` at
`8225b77d0657e6a3eb1ffc941d009100b792fb25` (`origin/main`, `v1.1.12`).

## Eligibility

The GitHub repository API was refreshed on 2026-08-17. The repository is
public, unarchived, enabled, BSD-3-Clause, primarily Python, at 542 stars, and
last pushed on 2026-04-17. The default branch is `main`, currently equal to the
selected pin. It has no Discussions and no open issue/PR count.

## Ownership search

The complete first-page all-state API sets contain all 40 issues and all 16
pull requests. Searches used exact and broader combinations of `subset`,
`subsetting`, `filter`, `crop`, `prune`, `dependency`, `closure`, timestamp,
sensor selection, records, rigs, features, matches, points, and observations.
The same vocabulary was searched across all nine fetched branches, 922 commits,
source, tests, tools, documentation, tags, and commit messages.

No issue, pull request, branch, commit, test, or tool implements or owns general
dependency-closed dataset subsetting. Relevant apparent matches were resolved:

- [issue 46](https://github.com/naver/kapture/issues/46) asks for Bundler-derived
  match-pair export and does not discuss subsetting;
- commit `32eca31` only links a third-party image-cropping utility, which changes
  images/intrinsics rather than selecting a coherent dataset graph;
- converter-local filtering handles importer-specific partitions or export
  choices and exposes no general saved-subset operation; and
- `kapture_merge` combines datasets and supplies useful transfer precedents but
  performs the inverse selection operation.

## Local prior-art result

All local problem, candidate, success, and archive records were searched. The
closest accepted shapes are graph/resource closure in ezdxf and transformed
record copying in PcapPlusPlus, but neither uses kapture's timestamp/sensor
model, nested rigs, reconstruction point remapping, or mixed per-collection tar
producers. No exact kapture problem or solver run exists.

Verdict: `pass`. Recheck before submission if the repository pin or upstream
default branch changes.
