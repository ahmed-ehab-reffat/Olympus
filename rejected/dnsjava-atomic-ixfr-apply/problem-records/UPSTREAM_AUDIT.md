# Upstream audit - dnsjava atomic IXFR application

Audit date: 2026-08-11. Frozen pin:
`06a0599933114f36efe59667cd80ee0246a1a882`.

## Eligibility

- GitHub metadata at audit time: 1,076 stars, active and unarchived, default
  branch `master`, last pushed 2026-06-14.
- License: BSD-3-Clause.
- Production language: Java.
- Repository surface: DNS records/messages, AXFR/IXFR, TSIG, DNSSEC, zone
  storage and lookup, with a large Maven regression suite.

## Ownership and overlap search

All-state GitHub issue/PR searches returned zero results for each of:

- `repo:dnsjava/dnsjava "apply IXFR"`
- `repo:dnsjava/dnsjava "Zone" "IXFR"`
- `repo:dnsjava/dnsjava "incremental zone"`
- `repo:dnsjava/dnsjava "getIXFR"`
- `repo:dnsjava/dnsjava "apply delta"`
- `repo:dnsjava/dnsjava "secondary zone"`

The issue/PR indexes, releases, fetched branch names, complete frozen source and
test tree, commit subjects, and exact API/error strings were also searched. No
branch, issue, PR, release item, or implementation applies IXFR deltas to an
existing `Zone`.

The seam is repository-grounded: `ZoneTransferIn` already exposes parsed
ordered deltas and response modes; `Zone.fromXFR` accepts only AXFR construction;
and current zone updates are record/RRset-at-a-time. No adjacent upstream work
prescribes the proposed atomic operation or API.

## Provenance and local similarity

The latest 250 default-history commits were inspected. Four are direct
Dependabot dependency updates; no generative coding-agent author marker was
found. Local searches found no prior dnsjava problem. The `miekg/dns` truncation
seed concerns packet budgeting and complete message RRsets, not stateful zone
lifecycle or transfer application. Archived transactional publication
trajectories informed the public atomicity ledger but supply no DNS
implementation.

The default-branch head and frozen pin were identical at audit time. The
repository exposed one current remote branch and 93 fetched tags; the ownership
queries remained empty after the disposable implementation trials.

Historical local verdict: `clean upstream ownership and local novelty` for the
frozen pin. The user later reported a platform rejection because the feature
had already been implemented before. The external implementation identifier is
not present in this workspace, so this record is preserved but no longer
authorizes the task.
