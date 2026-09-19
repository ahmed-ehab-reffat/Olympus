# feedback — scriggo-attribute-escaping-contexts

## Status

CORE SLICE BUILT (2026-09-17), awaiting Step 4b platform precheck. Base commit `2f437fb8222e48af03cf4087794b05a23316b07a`.

## How this pick was reached (2026-09-16-C)

Reached through Stage 0-bis (proven-repo pool), after `benjamn/recast` died on the SIX-CHECK
maintainer-philosophy item: recast #429 is closed by the maintainer as "working as designed" over
the exact array-reprint lane. Full hunt record in
`Instructions/repo-hunt-logs/REPO-HUNT-2026-09-16-C.md`.

scriggo's Go LANGUAGE CORE is contested (platform derivative verdict already on file) and its own
conformance skip list is a published, issue-numbered gap matrix. The TEMPLATE engine is open, which
`SATURATED-REPOS.md` had already predicted in writing. The pick sits there.

## The gap, measured on base

`<style>p{color: {{ v }} }</style>` CSS-escapes its value. `<p style="color: {{ v }}">` does not.
`<button onclick="f('{{ v }}')">` applies HTML entity escaping only, which the HTML parser undoes
before the JS parser runs.

## Open items

1. **Responsible disclosure is an unresolved user decision.** The `on*` handler behaviour is an
   unreported XSS vector in a live 575-star template engine with a `SECURITY.md`. Disclosing it
   would very likely kill this pick. Nothing has been sent upstream.
2. scriggo has no test-running CI workflow. Deviation accepted and recorded in DESIGN.md section 15
   on the strength of `go.sum` pinning plus a locally measured green, deterministic 5s suite.

## Attempt history

### R0 core slice (2026-09-17, no batch)

- DESIGN.md section 5 was wrong: the JS escaper writes `\u0027` / `\u003c`, and a tool round-trip had
  decoded those escapes out of the table, so row 3 displayed the raw injection. Rewritten from measured output.
- New wall found in code: `decodeRenderContext` masks the context to 4 bits in two packages. With 14
  existing contexts, new ones wrap silently (onclick output comes out CSS-escaped). Reference widens
  both masks. This is now T1.
- Context values 0-5 double as `ast.Format`, and parser/emitter gate on `> ContextMarkdown`, so new
  contexts must be appended.
- Built: 6 files, 263 raw / 195 human-effective (below the 250-300 target on purpose, precheck first).
- Tests: 6 F2P functions via the public API only. Clean room: base 1063/0 x3, new 6/0 x3, 6/6 fail unsolved.
- The invalid-type test now asserts only that `BuildTemplate` errors (meta says building fails, never names the message).
- Dockerfile: uid 1000 could not write /app (agents could not edit, `test/compare` failed). Added
  `chmod -R a+rwX /app` and system `safe.directory`.
- meta.md drafted at 285 body words; tighten after the precheck.
- Docker (rebuilt image, offline, uid 1000): base 1063/0, new unsolved 6 failing, solution applies
  in-container, base 0 failures, new 6/0. Image carried the test.patch from just before the
  build-error assertion edit; that edit is test-only and re-verified locally. Cold-build timing (L62)
  still owed, since this build shared the daemon with another build.

## REJECTED 2026-09-17 — repository reserved

Platform repo picker: "This repository can't be selected — it's reserved to prevent data
contamination. Choose a different repository." Not a quality, difficulty or exclusivity verdict;
the whole repo is blocked. Recorded in `Instructions/SATURATED-REPOS.md § A0` and as Requirement 0 in
the olympus-hunt skill. Moved to `rejected/` for reference. The responsible-disclosure question about
`on*` attribute escaping in scriggo is independent of this and still open.
