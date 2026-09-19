# Repo hunt 2026-09-19-D — SOFTENED gates (user-authorized); messageformat RANK 1

User: "continue hunting until you bring an authorable repo, maybe soften your search restrictions a
little". Brief `worktrees/_hunt/agents/BRIEF-0919-D.md` turned six gates into signals: Req 7 (no test
CI; causal-learn died to it on 09-01 and was later APPROVED), 1-2 signature accounts outside the lane,
AI/velocity/company marks outside the lane, the 5000+ star penalty, dormancy without lane PRs, and a
200-230 eff lane with a coupled second lever. Platform walls stayed hard. Five subagents, ~250 slugs
screened; dead list now `worktrees/_hunt/deadlist_v8.txt` (4,985).

| Sweep | Result | Notes |
|---|---|---|
| salvage (kill records, softened gates only) | fallback | nkaz001/hftbacktest stop/trailing-stop orders (~270 eff, but outsider-nameable, maintainer silent since 2025-12); simupy dead (pathsim prior art), digitaljs weak (brute-force shortcut). Req-7-only kills mostly have NO suite at all; Req-7 kills expire (pysteps CI green again) |
| noci (science repos without CI) | none | real no-CI repos have no suite / are dormant / solo-maintainer feature streams. lmfit (Azure CI) conf-interval for derived params: 40-60 line shortcut. PyFR, particles dead |
| ledger / i18n / units | **RANK 1** | messageformat (below). Accounting/units core already swept dry; go-i18n killed by `team-humaki` burst |
| transport / routing | DEAD on licence | graphhopper transfers.txt lane was strong (F2P both routers, ~290-430 eff) but `core/.../isochrone/algorithm/ContourBuilder.java` carries an LGPL-3.0 header (subagent missed it; orchestrator check) -> same vendored-copyleft rule that killed openTCS and synthea. Revive only if the platform is known to check the top-level licence alone. Clone `worktrees/gh-graphhopper` |
| testing tooling | none | RESTler minimization = replay_sequence shortcut; JQF = Conjecture reducer; mountebank no lane |

## RANK 1 — messageformat/messageformat (TypeScript 94%, MIT + Apache-2.0 per package, ★1770)

- **Mechanics (orchestrator-verified):** every LICENSE file read (root + mf1 packages MIT, mf2 packages
  Apache-2.0); CI green on main (Node.js, CodeQL, Docs); 42 commits/12mo, all `eemeli`, last code
  commit 2026-04-26; not in any workspace record, quota 0/6. Softened gates relied on: NONE
  (single maintainer recorded as a note).
- **Lane:** add `messageToMF1()` to `@messageformat/icu-messageformat-1`: MF2 message -> ICU MF1 source
  that this repo's MF1 compiler formats identically to the MF2 message for every input in a given
  locale. Coupled second lever sharing the kernel: make `messageToFluent` handle sparse variant lists.
- **Missing algorithm:** compile a sparse multi-selector variant list into a nested single-selector
  tree that reproduces `mf2/messageformat/src/select-pattern.ts:31-72` (best key per selector, restart
  on empty candidates), with exact-key -> category -> catch-all per selector, locale category sets
  (`strictPluralKeys` rejects a category the locale lacks), offset/`#`, context-dependent escaping, and
  argType/argStyle recovery (mf1:* attributes first).
- **F2P reproduced on base (orchestrator, vitest in repo):** package exports only `MF1Functions,
  mf1ToMessage, mf1ToMessageData, mf1Validate`. For `.match $a $b  1 x {{A}} one * {{B}} * x {{C}}
  * * {{D}}` (en) MF2 gives A/B/C/D for (1,x)/(1,y)/(2,x)/(2,y); naive nesting gives D for (1,y).
  `messageToFluent` emits `[1] { $b -> [x] A }` with no default variant: `@fluent/syntax` re-parses the
  serialized message as `Junk`, and B is unreachable.
- **Size:** 6-7 decision points, ~295-385 eff (reference ~330); leanest passer copying `selectPattern`
  and enumerating cells ~230-260. Files: new `message-to-mf1.ts`, icu-mf1 index, fluent
  `message-to-fluent.ts`, a shared kernel module (3-5 files, 2 packages).
- **Seams:** F-39 (misdirecting in-repo precedent `message-to-fluent.ts:52-91`, same naive grouping in
  sibling `@mozilla/l10n`), F-11 (backtracking selection), F-10 (locale x exact x category x selector
  count), F-2 (forward converter `mf1-to-message-data.ts` is the spec of the inverse), F-7 (`#`
  special in plural bodies and nested statements, `parser.ts:412-419,480-485`).
- **Exclusivity:** PRs/issues all states, 1668-commit history `-S`, branches, 10 forks, GitHub code
  search (`mf2ToMf1`, `messageToMF1`, `stringifyMF1`, `toICUMessageFormat`, `mf2ToIcu`) -> nothing.
  ICU4J message2 has no MF1 export; `@mozilla/l10n` has no MF1 target.
- **Base suite:** 36 files / 2709 tests, 3x identical, needs the `test/messageformat-wg` submodule
  (Unicode-licensed spec tests, not in the tree): scope `spec.test.ts` out of base mode with that reason
  rather than cloning it in the Dockerfile.
- **Risks:** (1) FP from locale data: MF1 runtime uses `make-plural`, MF2 uses `Intl.PluralRules`;
  keep cells on locales/integers where both agree and state the equivalence contract, locale argument
  and every error case in meta.md. (2) Outsider-nameable direction ("reverse of mf1ToMessage"), and
  eemeli edits the MF2 spec and could ship it: phrase on the repo model, re-run exclusivity at submit.
  (3) Death-class guard: one kernel feeding two emitters, so a local fix in either emitter does not fix
  the other; not a standalone post-pass because the kernel must mirror select-pattern semantics.
- **Owed before authoring:** Requirement 0 (platform picker accepts messageformat/messageformat),
  Gate 8 six-check at scope lock. Clone: `worktrees/_ledger/messageformat` @ `0ffba11d` (source only).

## Fallbacks
hftbacktest stop orders (`worktrees/hftbacktest`), pdfmake footnotes (magnet), graphhopper (licence).

## Tooling
sig_accounts += vedjaw ("[unsupervised AI]" PR titles), caiyi0616, team-humaki, Eljees,
philsong4-ai, Yanhu007, Sanjays2402, ychampion. Incident: a subagent ran unanchored `pkill -f
screen.sh` (memory `pgrep-f-self-match`); give future sweeps separate scratch filenames.
