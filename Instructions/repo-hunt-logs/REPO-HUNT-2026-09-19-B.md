# Repo hunt 2026-09-19-B — four new niches (games, notation, embedded, planning); 0 RANK, 1 weak fallback

Discovery is still the binding constraint. Four subagents swept niches no earlier hunt had covered,
each doing band-cache regex + 15-50 topic searches + named projects, minus `deadlist_v4`, then
`screen.sh` and up to 3 lane audits (`worktrees/_hunt/agents/BRIEF-0919-B.md`). 234 slugs screened in
total; all are now in `worktrees/_hunt/deadlist_v5.txt` (4,463 slugs). Per-repo reject reasons:
`worktrees/_hunt/agents/{games,notation,embedded,planning}-0919B.md`.

| Niche | Screened | Result | Closest misses (killer) |
|---|---|---|---|
| games | 43 | none | evennia XYZGrid cross-map routing (2 decision points, ~120-160 eff, scipy-Dijkstra shortcut); boardgame.io (turn/phase lane under 5 open PRs + AGENTS.md wave); ggrs (maintainer burst, GGPO prior art, UDP tests) |
| notation | 96 | none | opensheetmusicdisplay (Claude co-authored sweep across every engraving lane, MusicXML-nameable); smilesDrawer (named algorithms shipped by RDKit.js/openchemlib); goat (markdeep/svgbob prior art, 2 commits/12mo) |
| embedded | 64 | none | leshan LwM2M CBOR codec (SenML-reuse shortcut ~100-150 eff, 1.2 not planned); defmt (display-hint arms, big lanes in PRs); tokio-modbus (open PRs cover core files) |
| planning | 31 | FALLBACK | exchange_calendars multi-break sessions (below) |

Why the niches are dry: copyleft owns the mature engines (MuseScore, LilyPond, Verovio, PlantUML, D2,
chess/go engines, most CAN/fieldbus/emulator tools); the permissive rest implement famous specs
(MusicXML, SMILES, Modbus, OPC UA, LwM2M) where only missing spec arms remain, or are hardware-bound,
or have no test CI.

## FALLBACK — gerrymanoim/exchange_calendars (Python, Apache-2.0, ★667) — N-break sessions

- Lane: any number of intraday breaks per session, clipped against special opens/closes, honoured by
  schedule accessors, minutes under all four `side` values, `is_break_minute`, `is_open_at_time`,
  minute counts and `trading_index`.
- Missing algorithm: ordered break-list clipping against each session's actual open/close (today a
  special close wipes the break, a special open keeps it) + an N-segment minute/index kernel replacing
  the two-segment am/pm one.
- F2P on base: two breaks -> ValueError; late open after the break keeps a stale break and
  `trading_index` crashes ("negative dimensions"), matching #142 where the maintainer says late opens
  should drop the break. Scoped base 657 passed + 1 xfailed, 3/3 identical ONLY with
  `--hypothesis-seed=0` (pin it in test.sh).
- Size: 6 decision points, ~230-290 eff; a segment-flattening passer may land 180-220 -> needs the
  clipping + `trading_index` coupled lever.
- Risks: heavy description (API + clipping + `side` rules); partial sibling prior art
  (pandas_market_calendars "interruptions"); 2 signature-shaped accounts, holiday-data lane only.
- Gate before authoring: 1-hour reference spike of clipping + `trading_index`; drop under ~230 eff.
  Clone kept at `worktrees/exchange_calendars` (source only).

## Tooling changes
- `screen.sh` now also counts AI `Co-Authored-By` trailers over the last 100 commits. OSMD read 11
  subject-line marks but 64 trailers; the old count understated trailer-only sweeps.
- `sig_accounts.txt` += `kadyrbekovhamit-cyber` (finance-library sweep: QuantLib, dinero.js,
  FinancePy, pyxirr, pyliferisk), `uttam12331`. `DMZ22` borderline, not added.
- Watch: uoftcprg/pokerkit (MIT, Python, own poker-variant model) at ★498, two short of the floor.

# PART 2 — reference spikes on the three parked fallbacks (`worktrees/_hunt/agents/BRIEF-SPIKE-0919.md`)

Build the core, measure human-effective with the hook, write the shortcut a strong agent would try.

| Repo | Verdict | Measured core | Projected full | Shortcut |
|---|---|---|---|---|
| **Cysharp/csbindgen** | **GO (narrow)** | 224 eff, 6 files | ~255-265 (bitfields + `*const [T;N]` params); ~320 with array expansion (prior art) | 63-eff lean fails 13/21; 215-eff strong fails 3/21, all on nested C#-vs-Rust alignment (misdirecting) |
| gerrymanoim/exchange_calendars | NO-GO | 160 eff | ~200-215 | segment-flattening 100 eff passes 657 scoped tests + 17/18 cells |
| ricktu288/ray-optics | NO-GO | 242 eff | ~270-280 | 69-line probe shortcut passes 16/16 cells + 100/100 gallery objects |

Lessons: exchange_calendars' "clipping" lever collapsed to a filter under backward compatibility
(XHKG 12:30 early closes inside its break), and every surface but `trading_index` already rides the
generic minutes index; a lane whose new state flattens into an EXISTING representation is absorbed.
ray-optics confirms the 09-18 in-repo-oracle gate: the fairness sentences hand agents the fix list.

csbindgen next steps: Requirement 0 picker check; verify the .NET explicit-struct alignment rule in a
dotnet container; state LP64 in meta.md. Branches `spike-0919*` in `worktrees/csbindgen`.
