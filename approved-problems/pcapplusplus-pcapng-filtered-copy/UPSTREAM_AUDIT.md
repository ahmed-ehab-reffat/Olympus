# UPSTREAM_AUDIT - PcapPlusPlus PCAPNG filtered copy

Audit date: 2026-07-30

Repository: https://github.com/seladb/PcapPlusPlus

Pinned and current `master`:
`0dbbb9c75eb232135f13fdb794318c4da3270ebc`.

## Search method

Issue and pull-request searches used the GitHub Search API:

```text
GET https://api.github.com/search/issues?q=repo%3Aseladb%2FPcapPlusPlus+QUERY
```

Searches included all states and both issues and PRs. All returned titles were
inspected; potentially related results were opened and their conversations,
linked PRs, commits, and branches were followed. A broad `pcapng` search
returned 121 results over two pages; all titles were inspected. The exact
query/count ledger is:

| Exact `QUERY` after repository qualifier | Count | Collision decision |
|---|---:|---|
| `"pcapng filtered copy"` | 0 | Clean |
| `"filtered capture"` | 0 | Clean |
| `subcapture` | 0 | Clean |
| `light_subcapture` | 0 | Clean |
| `"copyTo"` | 3 | Address-buffer copy issues #1847, #333, #244; unrelated |
| `"copy packets"` | 5 | Packet-copy usages/issues; no structure-preserving rewrite |
| `"rewrite pcapng"` | 0 | Clean |
| `"preserve blocks"` | 0 | Clean |
| `"multiple section"` | 1 | Dependabot text; unrelated |
| `"section header" pcapng` | 4 | #2160, #1695, #1873 are parsing/length/null cases; #371 is prior idea below |
| `"mixed endian"` | 0 | Clean |
| `"byte order" pcapng` | 3 | File heuristics/other parsing; no implementation |
| `"interface id" pcapng` | 8 | #2132, #2180, #1761, #1334/#1337 and timestamp cases; adjacent only |
| `"interface statistics"` | 1 | Live-device statistics, unrelated |
| `"name resolution" pcapng` | 0 | Clean |
| `"decryption secrets"` | 2 | TLS/replay/Scapy discussions, not block-preserving copy |
| `"custom block" pcapng` | 2 | #2180/#2182 parser security; no copy policy |
| `"unknown block" pcapng` | 1 | #1334 malformed interface reference path |
| `0x00000BAD` | 0 | Clean |
| `0x40000BAD` | 0 | Clean |
| `"do not copy" pcapng` | 2 | Unrelated prose |
| `"packet comment" pcapng` | 10 | Reader/comment support and optimization; no raw rewrite |
| `"timestamp resolution" pcapng` | 3 | Existing conversion/precision behavior |
| `if_tsresol` | 1 | Historical timestamp handling |
| `"raw block" pcapng` | 1 | Truncated-input parsing |
| `"block iterator"` | 0 | Clean |
| `"block visitor"` | 0 | Clean |
| `copyFiltered` | 0 | Proposed API name clean |
| `"PcapSplitter" pcapng filter` | 0 | No equivalent implementation |
| `pcapng` | 121 | Complete title sweep; relevant items reduced to the cases below |

## Relevant issues and pull requests

### Closed issue #371

Issue #371 (2020) is the strongest prior collision. The reporter wanted to
filter/rebuild multiple PCAPNG inputs while keeping section/interface
information. A maintainer explained that interface metadata was not supported.
The reporter later proposed using Interface ID 0 and said copying SHB/IDBs
“should not be that hard,” but stopped at LightPcapNg internals. There is no
patch, PR, branch, or linked implementation, and the maintainer did not decline
the feature.

Decision: prior public idea, but not equivalent reachable code and not a
novelty hard stop. It reinforces the prototype's cheapness/convergence risk.

### Adjacent current work

- Open #1761 asks for interface names and multi-interface writing. A maintainer
  described it as not an easy fix; it has no PR and does not preserve existing
  sections.
- Open #1695 concerns unspecified (`-1`) SHB length; no PR.
- #1334 and merged #1337 address an invalid unknown Interface ID, not
  structure-preserving filtering.
- Open #2132 concerns uninitialized SPB link data; #2160 minimum sizes;
  #2180/#2182 block-length safety; and #2195 per-writer buffering. These are
  parser hardening, not equivalent APIs.
- PR #1792, commit `0f4e858`, temporarily switched the vendored engine to
  `PcapPlusPlus/LightPcapNg` v1.0.0. PR #1816, commit `52798c9`, reverted that
  integration twelve days later. Neither contains filtered-copy behavior.

No opened result supplies the proposed method, raw section transformer, copy
policy, or mixed-endian filtered rewrite. No maintainer rejection owns the
complete task.

## Branch, tag, release, and history audit

Fetched remote branches were `master`, `dev`, `compile-time-version`,
`deb-packages`, the current Dependabot branches,
`update-version-to-26.07-plus`, and `windivert-mock`. Tags from v16.02 through
v26.07 were searched. The latest v26.07 release notes, repository
documentation, changelog/history, and current default-branch delta contain no
equivalent feature. GitHub reports `has_discussions=false`, so there is no
Discussions corpus.

Across every fetched ref, `git log -S` / `-G`, blame, and source/test searches
were run for the query vocabulary, `light_subcapture`, standardized Custom
type constants, section byte-order handling, and the proposed API. The only
PcapPlusPlus history hits for `light_subcapture` are deletion/restoration
caused by the LightPcapNg fork switch and revert. There is no mixed-endian fix
or Custom copy-policy implementation.

Final `git ls-remote` confirmed that `origin/HEAD -> master` and current
`master` still equal the immutable pin.

## LightPcapNg provenance and forks

The current vendored provenance file names standalone
`rvelea/LightPcapNg` commit
`33296580096f83a9f17ebe7ea3d2c79977a24471` (2023-01-07). Its master and
history contain the old list/subcapture implementation but no section-aware
filtered copy, Custom copy policy, or mixed-endian repair.

`PcapPlusPlus/LightPcapNg` tag v1.0 / head around `3886393` contains the
standalone commit. Its later sync branch `1d484b5` changes only seven small
files and adds no equivalent feature.

The active independent fork `Technica-Engineering/LightPcapNg` was inspected
at `b36c701` (2026-06-18). It has a streaming block API, 2025 Custom Block
constants, and endian work in commit `a6bbabd` (+314/-84 C lines). It does not
provide filtered copy or standardized copy-policy handling. It is also C, so
it is neither equivalent code nor an eligible participant implementation
route.

Decision: no reachable fork contains the task. The independent endian patch
shows that repairing the existing C parser is material rather than a tiny
wrapper.

## Local Olympus similarity audit

Searches covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, dated audits, candidate/problem trees, and the
accessible submission archive for PcapPlusPlus, PCAPNG, filtered copy,
raw-block pass-through, packet capture, section, Interface ID, unknown block,
and Custom Block.

There is no prior PcapPlusPlus submission or section-aware capture rewrite.
The closest local shapes are:

- rejected fq embedded-PCAPNG secrets, where an explicit TODO and existing
  deferred TLS path collapsed the task;
- rejected go-mp4 sample-location rewriting, a locally complete 230-line
  format change rejected for cross-repository overlap; and
- noodles and 3D Tiles trajectory evidence showing that many format fixtures
  can converge on one event/raw-output loop.

Decision: no direct local duplication, but strong convergence precedent. The
candidate ultimately fails its own shape/size gates rather than novelty.

## Audit conclusion

Novelty is not the fatal gate. Issue #371 publicly describes the desire but
contains no implementation or decline; current issues/PRs, every fetched ref,
releases, both LightPcapNg lineages, the active independent fork, and local
Olympus history contain no equivalent code. There is no unresolved upstream
collision.

The audit nevertheless lowers confidence that the task is long-horizon:
the prior issue anticipated copying SHB/IDBs, and the successful prototype
confirms that a raw default branch plus an existing BPF predicate is the
entire honest architecture.
