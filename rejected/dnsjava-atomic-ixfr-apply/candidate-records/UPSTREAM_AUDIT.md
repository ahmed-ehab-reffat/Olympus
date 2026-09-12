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

The public issue and PR indexes, releases, fetched branch names, complete local
source/test tree, commit subjects available at the frozen checkout, and exact
API/error strings were also searched. No branch, issue, PR, release item, or
implementation applies IXFR deltas to `Zone`.

The seam is repository-grounded rather than speculative: `ZoneTransferIn`
already exposes parsed `Delta` objects and transfer modes; `Zone.fromXFR`
explicitly rejects non-AXFR construction; and the only current update API is
record/RRset-at-a-time mutation. No adjacent upstream work prescribes the
proposed atomic operation or its API.

## AI/provenance and local-similarity read

The resumed audit inspected the latest 250 default-history commits. Four are
direct Dependabot-authored dependency updates; no generative coding-agent
author marker appeared. The earlier blanket wording that no agent marker
appeared was therefore too broad and is superseded by this provenance-specific
result. Local searches found no dnsjava task. The existing `miekg/dns`
truncation seed concerns packet budgeting and complete RRsets, not zone
lifecycle or transfer application. Transactional publication trajectories
inform the atomic-publication ledger but do not provide a DNS implementation
path.

The default-branch head and frozen pin were still identical at the resumed
audit. The repository exposed one current remote branch and 93 fetched tags;
the ownership queries remained empty. The disposable implementation trials did
not reveal or create upstream ownership.

Historical local verdict: **clean upstream ownership and local novelty** at the
frozen pin. The user later reported a platform rejection because the feature
had already been implemented. The prior implementation identifier was not
available locally, so the task is closed rather than retroactively inventing
search evidence.
