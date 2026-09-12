# feedback — taffy visibility:collapse

## Summary
Minimal derivative probe for `visibility: Collapse` on flex items in DioxusLabs/taffy.
Built to run the platform similarity/derivative check BEFORE committing to the full
Olympus build. Scoped to the zero-main-size behavioral core (strut + two-pass deferred).

## Pick provenance
Pivoted here after the scriggo-range-iterators probe returned DERIVATIVE (a prior author
owns scriggo's Go-language-completion space). taffy chosen from the verified niche shortlist:
domain engine (CSS layout), spec-authoritative, cold gap (issue #124), dedup-clean.

## Attempt history
| # | Date | Stage | Result |
|---|---|---|---|
| 0 | 2026-07-21 | Minimal probe built + locally validated | Ready for derivative check |

## Open decisions
- Awaiting platform derivative verdict on the probe.
- If NON-derivative: harden to full step-10 (strut + two-pass), re-scope meta.md to the full
  contract, run Vega/Nova batch, target <=20% pass, >=450 eff LOC. See DESIGN.md sec 9.
- If DERIVATIVE: quarantine to rejected/ + record in TOO-EASY/SATURATED, pick a different
  taffy cold gap (candidate: block auto-margin centering `margin: 0 auto`, or baseline
  alignment last-baseline) or a different shortlist repo.

## Local validation (see eval-results.md)
All green in olympus-base-rust container: patches apply both orders + reverse; base passes
(4573 tests); new fails-on-base (compile-error fallback) and passes-with-solution (5 tests);
deterministic 3x/3x. Docker image-build sanity check NOT completed (host disk filled; the
Dockerfile is the canonical Rust cargo2junit pattern).

## Key learnings
- taffy is actively developed (many in-flight PRs); had to steer clear of order/Display::Contents/
  scrollable-overflow/grid-content-size/etc. issue #124 (visibility:collapse) is a genuinely cold
  maintainer-tracked gap with no PR and no leaked solution.
- New required Style field breaks existing full `Style { .. }` literals (src defaults_match test,
  tests/xml.rs). Fixed in solution.patch (R5). Same class as the scriggo test-expectation fixes.
- Gating the new test file behind `--cfg taffy_probe_vis` keeps base mode compiling the file to
  empty on the base commit while new mode activates it -> clean fail-on-base via compile error.
