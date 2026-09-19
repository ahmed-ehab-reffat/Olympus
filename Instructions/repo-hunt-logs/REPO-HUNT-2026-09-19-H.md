# Repo hunt 2026-09-19-H — factory hunter #3 (CONSECUTIVE_MISSES=0); NO-CANDIDATE on the dependents / org-siblings axis

Third `olympus-factory` hunt of the day. Taken per `pipeline/LEDGER.md`: libspatialindex (HUNTED),
messageformat, oxipng, csbindgen (CLAIMED). walles/riff and macs3-project/MACS are reserved as
libspatialindex fallbacks. The miss count is 0, so no BRIEF softenings were applied and the star and
issue windows were not widened. Requirement 0 (platform picker) cannot be checked by an agent and
would be OWED.

Per the 09-19-G hint, the discovery axis was switched away from topic niches to **org-siblings,
contributor-siblings and package dependents of the proven corpus**.

| Step | Result |
|---|---|
| 0-bis proven pool | Nothing new. Every pool repo already has a lane verdict: 09-18-C (planetiler weak, mwparserfromhell dead, tippecanoe, ray-optics), 09-19-F (kira, Cwerg, pcapplusplus, makerjs, rmk, h5py, openexr, worldengine), 09-19-G (ir-sim), 09-16 (acoular absorbed + self-colliding). featurevisor used two lanes today |
| Cached band | Not re-screened. 09-19-G re-filtered `unshown_0919.txt` against v10 and found 314 junk rows; v11 only adds the `term`/`ld` slugs, so the result cannot change |
| Sweep 1: org-siblings + contributor-siblings | Owners of 106 corpus repos (70 with URLs in meta/README, 36 mapped by hand), swept with `users/<owner>/repos`: 213 rows >= 500 stars, supported language, pushed in 12 months. Then the top 4 human contributors of each corpus repo (410 accounts), swept the same way: 95 rows. After deadlist_v11 and licence filtering, almost every row is a famous tool (tokio, axum, wgpu, rich, xarray, dioxus, hexyl), a GPU/UI/bindings project, or a small CLI |
| Sweep 2: crates.io reverse dependencies | Reverse deps of 16 approved-repo crates (lyon, smoltcp, goblin, grmtools, minidump, kira, tinywasm, yara-x, starlark, statig, icu, pulldown-cmark), top 40 by downloads each: 345 crates -> 255 GitHub repos -> 28 at >= 500 stars. All are apps or famous frameworks (AFFiNE, atuin, iced, slint, clap, embassy, esp-hal, cairo), except `rcoh/angle-grinder` and `facebook/starlark-rust` |
| Dependents via GitHub/npm web pages | Not usable. The GitHub dependents page is sorted by recency, not stars (lyon page 1 = 30 zero-star repos). npmjs.com `browse/depended` is behind Cloudflare. PyPI has no reverse-dependency API |

## Screened survivors and verdicts

- **facebook/starlark-rust** (Rust, Apache-2.0, ★1024, CI green on main, 885 commits/12mo). Closest lead,
  REJECTED.
  - **Lane: flow-sensitive type narrowing in the static typechecker.**
    - `typing/bindings.rs` is fully flow-insensitive: one solved type per `BindingId`, and an `if` pushes only its condition onto a flat `check` list.
    - Unions pass if at least one alternative does (`ty.rs:89`).
    - F2P REPRODUCED on base `9bfc581` (2026-09-07, the parent of `10c5512`, which moved the vendored buck2 crates to unpinned `git = buck2 branch main` deps):
      - `if type(x) == "int": x.upper()` with `x: int | str` gives no error;
      - `isinstance(x, int)` gives no error;
      - `if x == None: return x` under `-> str` gives no error;
      - a dead `type(x) == "str"` branch on `x: int` DOES error.
    - Probe: `worktrees/_hunt/h_orgsib/slr_narrow_probe.rs` (integration test, 2.0G target, deleted).
    - Sketch: 280-410 eff over bindings/typecheck/ctx/ty.
    - Seams: F-27 (and/or/not polarity), F-22 (the `solve_bindings` fixpoint), F-8 (Starlark `type("a") == "string"`, not "str"), F-10.
    - Lane density: zero narrowing commits, and typing churn is pagable serialization.
  - **Why dead:**
    1. TOO-EASY `Famous-language-feature lane`: type narrowing is a feature every gradual type checker for this family eventually grows (mypy, pyright, TS). Like exhaustiveness, which is on the carve-out list, it is a checker analysis, not syntax. The 2026-09-10 carve-out makes this a pick-time REJECT, not a mitigation. Astral `ty` (Rust) also ships `narrow.rs`.
    2. The account `metsw24-max` filed 3 PRs in 6 days (2026-06-09..14; overflow fixes, outside the lane). Its footprint is surgical fixes across unrelated permissive libraries (FreeRDP, cpp-httplib, pypdf, fontations, unblob, Taywee/args, Simd). That is a burst under 2b-bis, and the account is now in `sig_accounts.txt`.
  - Also live: a whole-repo "lifetimes" rebrand by JakobDegen (about 80 commits in September), so the base must predate 2026-09-08.
- **rcoh/angle-grinder** (Rust, MIT, ★3758). DEAD.
  - Only 1 code commit in 12 months (2026-01-01), so it is dormant.
  - A signature account (`ChrisJr404`, already in `sig_accounts`) has an open PR.
  - The operators are a catalogue of 23-88 line arms, so it fails Stage 3b absorption.
  - The only deep lane, sliding-window aggregates (#164, 2022, 0 comments), is a nameable, uncommented magnet.
- **beartype/plum** (Python, MIT, ★655). DEAD on capability consumption. `nstarman` has 20 open PRs across dispatch caching, generics, PEP 695 and resolution, plus a copilot-swe-agent PR, and keyword args (#40) is a magnet.
- **moov-io/watchman** (Go, ★509). DEAD: the maintainer is shipping the scorer lanes this week, and the algorithms are textbook fuzzy matching.
- **Mojang/brigadier**: no code since 2024-12 (Req 3/6).
- **pydicom/pynetdicom** and **pydata/patsy**: lint- or pre-commit-only streams (Req 6).
- **wader/fq** (★10.6k): penalty band, and the maintainer refactors the decode core weekly. fq was authored in an earlier workspace generation, and a new decoder is pattern-followable.
- **naver/egjs-infinitegrid**: 3 commits in 12 months, and the tests are DOM/karma-bound.
- **brendanzab/codespan**, **m4b/bingrep**, **sharkdp/pastel**, **Boshen/cargo-shear** and **askama**: small CLIs, dormant, or a famous-spec template engine.

## Result

NO-CANDIDATE. libspatialindex remains the factory's HUNTED pick, and riff and MACS remain its
reserved fallbacks.

## Tooling

- `worktrees/_hunt/h_orgsib/` holds the scripts:
  - `sweep_orgsib.sh`: owner repos;
  - `contribs.sh` + `usersweep.sh`: contributor repos;
  - `cratesdeps.sh` + `crate_repo.sh`: crates.io reverse deps.
- Raw rows are in `raw1-3.tsv` and `crate_hits.tsv`.
- Shallow clones `slr` (starlark-rust, 14M) and `ag` (angle-grinder, 3.6M) are kept; no build output is left.
- `deadlist_v12.txt` (5,776 slugs) = v11 + every slug these sweeps returned.

## Next hunt

The proven-corpus neighbourhood (org, contributor and crate-dependent siblings) is now exhausted too:
it returns famous frameworks or small tools, because the corpus's own maintainers mostly own one
engine each. The next hunt should either (a) run a star-band sweep BELOW the famous band on a
different axis, `gh search repos` by `created:` year windows plus `size:>5000`, filtered to
engine-shaped descriptions, or (b) accept softened-rule leads at misses >= 2. starlark-rust
narrowing stays dead under the carve-out, whatever the miss count. A non-famous starlark-rust lane
would need the repo's own model (pagable heaps, freeze, the Approximation gaps), and none was found.
