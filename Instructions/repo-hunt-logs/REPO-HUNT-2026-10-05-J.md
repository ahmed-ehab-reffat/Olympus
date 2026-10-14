# REPO-HUNT-2026-10-05-J (hunter #58, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended). The orchestrator session restarted mid-hunt and the run was resumed from scratch files.
Result: **CANDIDATE marcomusy/pianoplayer, performed-order timeline (repeat/ending/D.C. unfolding plus a tempo map), 219 human-eff written.**
This is a thin candidate, returned under the 210-220 rule with its second lever written in. Its risks are listed below.

Scratch: `worktrees/_hunt/s_1005h58/`. It holds:
- the re-screen scripts `rescreen_h58.py` and `vocab_h58.py`;
- the cuts `rescreen_rows_h58.tsv`, `vocab_never_h58.tsv` and `vocab_mentioned_h58.tsv`;
- the mechanical screen `screen1_h58.txt` (29 repos);
- the lane-audit brief `AGENT_BRIEF_h58.md`;
- 15 `dossier_<repo>_h58.md` files and 4 written sketches.

All clones are deleted. Nothing was built.

## Standing inputs and defaults taken
- **Rules changed 2026-10-05 (user decision), applied as written:**
  - lane-only exclusion;
  - verdict-only dead list, with lane rows expiring after 60 days;
  - Requirement 7 kills only on a failing test workflow in the lane;
  - the star margin is ~505;
  - the return bar is 220 written (210-220 allowed with a real second lever);
  - the Stage 6 Q3 waiver applies only above ~300 with an internal wall;
  - the per-repo count is reported, never gated.
- **Not relaxed:** the maintainer-roadmap magnet rule; the AI-sweep, velocity and signature-account rules; licence, language, activity and exclusivity.
- **Softening:** misses = 0, so the 09-09-B softened rules apply as standing rules only, and no star or issue window was widened.
- **Requirement 0 (platform picker):** OWED.
- **Excluded lanes (in flight, HANDOFF or dead today):**
  - protobuf-es `.proto` printer (HUNTED), with protobuf-es descriptor validator and hayro revision history reserved as its fallbacks;
  - ray-optics module inlining + rename;
  - gonum/plot glyph layout;
  - commafeed relocation;
  - aptly publish history;
  - teavm fact reuse, pyOCD deferred writes, aerich squash, sqlalchemy-continuum squash.
- **Disk:** `/` had 7.4-7.5G free (under the 8G build gate), so there were no builds, venvs or npm.

## Stage 0-bis: proven pool
- **Approved/claimed/rejected pool:** spent for second lanes. Hunts #53-#57 wrote multi-lane verdicts on every repo, all under 60 days old. Not re-audited.
- **Star-floor WEAK rows:**
  - scipenai/tylax is at ★501, under the ~505 margin;
  - uoftcprg/pokerkit is at ★503, also under the margin.
- **Repos opened by today's narrowed 6-cap** (dasel 9, cliffy 7, yaegi 7, expr, pest, katex, knex):
  - They are proven repos, but we hold no local problem folders for them, so derivative overlap against our own 7-10 subs per repo cannot be checked.
  - expr has two signature accounts (ChrisJr404, SAY-5), which is a repo kill that stays.
  - katex and knex are famous (19k) and SQL/LaTeX spec-named.
  - pest's optimizer and validator lanes are mined by our own 10+ subs.
  - Not pursued. A dedicated hunt would need the old sub lists (Instructions grep: dasel-*, pest-*, yaegi-* slugs) first.
- **WEAK rows priced 200-249 on paper in earlier logs** (`weak200_h58.txt`, 30 rows), re-checked under the new written bar:
  - every row is still killed by a non-LOC gate: ipyflow in-lane AI, devpi maintainer fork, lebab no test workflow, purgecss magnet, MetPy xradar sibling, rust-minidump welcomed spec magnet;
  - aptly snapshot recipes ~200 sits on a HANDOFF repo, a different lane but too thin.
  - Earlier written sketches (h56/h57) were re-measured, and only ray-optics (taken) and protobuf-es (taken) clear 200.

## Stage 0: cached index re-screen against judged.tsv
- **Population:** profiled cache rows (hist*.jsonl joined to band*.jsonl) at 505-6000 stars, permissive, supported language, >= 15 commits/12mo, minus judged.tsv repo rows.
  - 11,417 rows; 148 carry a lane verdict and 11,269 carry none.
- **Domain vocabulary cut:** 2,926 rows. Of these, 2,408 are named in no hunt log, SATURATED, TOO-EASY or dossier, i.e. listed but never given a verdict.
  - Read by eye per language.
  - 29 picked for the mechanical screen (`screen1_h58.txt`). Repo-level kills at screen:

| Repo | Kill |
|---|---|
| receiptline/receiptline | Req 7: no workflow runs tests |
| influxdata/kapacitor | Req 7: no workflows |
| noflo/noflo | licence: the monorepo package @noflo/fbp-spec-runner was relicensed EUPL-1.2 on 2026-09-28. The maintainer is also mid-rewrite (EventTarget, Edge transport) |
| trustmaster/goflow | not audited. ~70KB, the DSL just landed in an AI-style phased rewrite, and lanes are fbp-grammar-named |

- **Notes from the screen:**
  - wanasit/chrono has 16 AI trailers; orgajs 10; vercel/nft 10;
  - thriftpy2 has a signature account Sanjays2402 x3;
  - wtf_wikipedia, beanshell, velocity.js and cargo-public-api carry AI marks.
  - These were not sent to audit.

## Lane audits (5 parallel subagents, 15 repos, brief `AGENT_BRIEF_h58.md`)
Licences were read from the LICENSE files, and all 15 are permissive. Submission counts are 0 for all of them.

| Repo | Verdict | Best lane, and what killed it |
|---|---|---|
| **marcomusy/pianoplayer** (★892) | **WEAK, RANK 1** | Performed-order timeline, **219 written**. Detail below |
| siemens/kas (★604) | DEAD | `type: archive` repos, 214 written. Fails Stage 6 Q3: one ArchiveRepo class plus wiring, under 300. Public branch `origin/wip/sha256sum` (+350) already carries the sha256 key and tree cache. Mailing-list development, so a kas-devel RFC check is owed for any lane |
| quietvoid/dovi_tool (★1023) | DEAD | DolbyLabsMDF XML export, **445 written** (real traps in `parser.rs`: an L2 target id invents an L10 block, first-match shot trims, integer MinimumBrightness). Killed by the sibling-library rule: saindriches/dovi_meta (MIT, Rust, on the same `dolby_vision` crate) ships RPU to XML. AV1 = open PR #424; #149 is a maintainer numbered roadmap |
| airspeed-velocity/asv (★1021) | DEAD | Maintainer roadmap #1278 endorses most tracker features (magnet), plus a tracker sweep and open PRs #1621/#1611/#1599. Shard merge is absorbed by `Results.add_result` |
| alan-turing-institute/CleverCSV (★1341) | DEAD | ~4.9k LOC. Table-region detection is a standalone module with outsider-named siblings (hypoparsr/Pytheas). `test_console` is red on master (Req 7 in the console lane). binggao1230 x1 outside the lane (note) |
| python-streamz/streamz | DEAD | min/max aggs written at 56; reset/exception lanes are open PRs #249/#433; watermarks #354 magnet. Master red only on a TCP sources test |
| itamarst/eliot | DEAD | Every deep lane is a maintainer numbered design (#329, #176, #271) |
| stringertheory/traces | DEAD | 2.6k LOC; domains removed by the maintainer (630605b, #169); the rest < 200 |
| connor4312/cockatiel | DEAD | A Polly port; caching and rate limiter already PRs #108/#109; maintainer declines |
| MichaelXF/js-confuser | DEAD | Single-maintainer transform stream; seeded mode = magnet (#183); renaming declined |
| hyparam/hyparquet | DEAD | Sole maintainer churns scan/plan/rowgroup monthly. Projection pushdown has open PRs #100/#143/#185. The filter lane has an in-lane signature PR (MaxFreedomPollard #177, x2 a week apart, not a burst) |
| emlearn/emlearn | DEAD | Maintainer roadmap issues (#34, #55-58, #66, #77); gbm PR #123; multi-output declined (#39) |
| davidmoten/rtree | DEAD (repo) | Activity: last code commit 2024-08, the 12-month stream is dependabot only |
| CGATOxford/UMI-tools | DEAD | The v1.0.0 blog "What we'd do next" is a maintainer roadmap covering consensus, paired-end, C library and parallel; the rest < 200. Overturns half of 09-20's verdict (the dormancy half; maintainer commits May-Jun, #714 merged 10-04) |
| Natooz/MidiTok | DEAD | Signature burst: MinLee0210, 7 PRs in a week, 3 of them tokenizer features, plus scattershot repos. Added to `sig_accounts.txt`. Overturns 09-23-E's "tests failing" (green since #293) |

## RANK 1: marcomusy/pianoplayer, performed-order timeline

### Mechanical
| Check | Result |
|---|---|
| Repo | ★892, MIT (LICENSE read), Python primary, only dependency `rich` (vedo/pretty_midi optional) |
| Activity | 75 commits/12mo, all marcomusy. The package was rewritten Feb-Jun 2026 as a native MusicXML backend replacing music21. Base HEAD `6fb0e2114d7b21f75c0be5208172e1243a57323e` (2026-06-22) |
| Requirement 7 | `ci.yml` green on master |
| Signature accounts | none in the last 60 PR authors |
| AI marks | 1 (`codex/audit-fixes-synced`, merged as 5e964bb "port audited fixes"). It is in the parser file but closes audit items, not repeats or tempo, so per the skill it is a NOTE |
| Our submission count | 0 |
| Removal record | `git log -S` over the whole history: no expandRepeats, no repeat expansion ever shipped |

### Lane
`--unfold-repeats` / reader option. Hand sequences follow the performed order, which covers:
- forward/backward repeats with `times`;
- first/second endings;
- D.C./D.S./Fine/To Coda.

Onsets are in seconds from `<sound tempo>` (default 120). The fingering of the first pass is written back to the MusicXML.

### Gate 1
Probe run on base HEAD: a two-measure score with a repeated measure 1 parses to 3 notes (C 0.0, D 1.0, E 2.0) instead of 5. The parser loop (`musicxml_io.py:337-366`) reads only attributes, backup, forward and note, so `<barline>` and `<sound>` are ignored.

### Written sketch
`s_1005h58/sketch_pianoplayer_repeat-unfold_h58.patch`.
- **Measured:** human-effective **219**, raw 238, padding-floor 157, 6 files (musicxml_io, hand, scorereader, core, cli, models).
- **Honest caveat:** about 10 lines are the annotator's `_set_note_fingering` block re-indented, so the true count is ~205-210. The D.C./D.S./Coda arms are breadth.
- **Second lever (real, written in):** the tempo map, i.e. piecewise seconds conversion over the unfolded timeline.

| Decision point | Price |
|---|---|
| Barline and sound parsing | ~45 |
| Play-order builder | ~50 |
| Unfold (time shift, tie-on-jump, seconds) | ~55 |
| Annotator by element identity | ~30 |
| Hand window | ~4 |
| Plumbing | ~15 |

### Traps (interdependent, misdirecting, file:line at base)
1. **Collision helper.** `_mark_colliding_notes_as_chords` keys on `note21.offset` and the measure, and rewrites `note.time` from the written offset (`musicxml_io.py:544, 578`). Shifting only INote.time merges pass 1 and pass 2 into one synthetic chord. (F-9 / F-19)
2. **Tempo conversion.** Converting to seconds after `noteseq_from_part` is undone by the same helper for every collision group, which leaves mixed units. Coupled to T1. (F-19)
3. **Measure window.** The `break` in `Hand.generate` (`hand.py:461, 470`) leaves later passes at finger 0. It reads as an optimizer failure. (F-39)
4. **Annotator.** The parallel index walk (`musicxml_io.py:777-834`) writes pass-2 fingers onto unrelated measures. (F-9)
5. **Ending passes.** The pass number resets between ending groups, and repeat-closed endings are skipped after D.C. (F-69)

### Stage 6 death-class guard
| Question | Answer |
|---|---|
| Q1: one shared kernel feeding several surfaces? | YES. The unfolded event timeline feeds the collision/chord model, the fingering optimizer window and the MusicXML write-back |
| Q2: interdependent traps? | YES. T1 and T2 share the collision helper; T3 and T4 both depend on pass identity carried through the timeline |
| Q3: standalone file? | NO. The order/unfold core could live in a new module, but T1, T3 and T4 force edits to `noteseq_from_part`/the collision helper, `Hand.generate` and `annotate_part_with_fingering`. No waiver is needed or claimed (219 < 300) |
| Guard 1 (uniform wrap) | no |
| Guard 2 (single-subsystem transform) | risk accepted: reader, optimizer and writer are three subsystems |
| Guard 3 (unstated rule) | no, the contract states it |
| Guard 4 (spec port) | MEDIUM. MusicXML repeat semantics are known and music21 `repeat.Expander` is a public Python crib for the play-order step (~50 of 219). Weight tests on T1/T3/T4 (fingering per pass, write-back identity), and consider capping D.S./Coda to cut outsider surface |
| Guard 5 (survives spelling-out) | YES, the integration walls survive a full contract |

**Verdict: PASS with risks.**

### Risks (for the builder)
- **LOC.** 219 is at the edge, and the honest count is ~205-210. The builder's spike must clear 200.
- **Contract length.** About 9 rules, which is tight for 200 words.
- **Magnet.** #8 "Fingering with voltas" was closed in 2018 and the maintainer commented ("a bit difficult to implement"). It is not an open uncommented issue, so MEDIUM.
- **Hot file.** The parser is the maintainer's hot file (Codex audit pass Feb-Jun). Re-check the commit stream at slice.

## Fallbacks
No other lane clears the bar.
- siemens/kas `type: archive` (214 written, fails Q3 under 300, sha256 branch overlap): only if the human waives Q3.
- dovi_tool XML export (445): dead on the sibling crib unless the human rules dovi_meta out of scope.

## Verdict rows appended to `worktrees/_hunt/judged.tsv`
- 18 rows: 4 repo-scope (receiptline, kapacitor, noflo, rtree) and 14 lane-scope.
- `sig_accounts.txt`: + MinLee0210.

## What the next hunt should change
1. **Yield measured on the cached-index re-screen:** 2,408 never-verdicted vocabulary rows produced 29 screened, 15 audited and 1 thin WEAK.
   - The listed-only rows are mostly app/infra libraries whose deep lanes are maintainer roadmaps, numbered designs or open PRs.
   - Do not repeat this cut. The next vocabulary-driven re-screen should target repos with a persisted format or two-way pipeline (reader + writer + optimizer) and moderate solo activity, as pianoplayer has.
2. **dovi_tool shows the sibling-crib check belongs in the brief's first pass.** It cost a full 445-line sketch. Run `gh search code` for the capability in the 3 nearest siblings before writing.
3. **The cap-opened proven repos** (dasel, cliffy, yaegi, pest) need our old sub lists before any lane audit. A hunt that wants them should first build the per-repo lane list from the Instructions slug mentions.
