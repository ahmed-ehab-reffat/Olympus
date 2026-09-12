# UPSTREAM AUDIT - umoci forward hardlink extraction

Audit date: 2026-08-15.

Repository: `opencontainers/umoci` at
`f5d1219acaf67127ebacf6306776d3ff465735ea`.

## Eligibility

- Public GitHub repository; 951 stars; Apache-2.0; primary and proposed
  production language Go.
- Default-branch pin date: 2026-03-05, within twelve months.
- Committed `go.mod`, `go.sum`, and `vendor/`; real package and integration
  suites; full ordinary Go package suite passed offline in the official base.
- GitHub reports Discussions disabled.

## Saved searches and history

GitHub all-state issue/PR searches were run for `hardlink`, `forward hardlink`,
`out of order hardlink`, `before hardlink`, `delayed hardlink`, and
`pending hardlink`, including titles, bodies, and comments. The only hardlink
results were:

- closed issue 29, which requested real hardlinks and notes the same ordering
  problem;
- merged PR 223, which defines ordinary clobber semantics but does not defer
  forward links;
- open issue 310, an unrelated unprivileged `link(2)` permission report; and
- open issue 256, a broad alternative OCI archive-format RFC.

The exact forward, out-of-order, delayed, and pending phrases returned no PR or
implementation. All issue/PR bodies across the repository were additionally
scanned for hardlink, link-target, tar-order, out-of-order, deferred-link, and
pending-link synonyms. Merged PR 232 concerns out-of-order whiteouts, not
hardlinks.

The complete fetched branches and tags and `git log --all` were searched for
the current FIXME and hardlink terms. The FIXME was introduced in 2016 and
survives at the frozen pin. No current remote branch implements it.

## Ownership and safety verdict

No open, merged, closed, or abandoned umoci PR implements forward-hardlink
resolution. There is no active assignee or development branch for the behavior.
However, closed issue 29 publicly recommends keeping an inode map and delaying
creation. That is not ownership, but it is strong reconstructability evidence
and lowers prior-art/scope safety. The escalation proceeds only through an
honest convergence trial and must be rejected if that public recipe produces a
small localized fix.
