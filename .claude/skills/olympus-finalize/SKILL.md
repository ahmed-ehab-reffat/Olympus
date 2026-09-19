---
name: olympus-finalize
description: Use AFTER a problem is accepted by a human reviewer — the carry-forward pass that turns one success into reproducible method. Mines every agent run in the problem folder (per-test kill counts, failure clusters, near-miss margins, tests that killed nothing, agent split, long-horizon metrics), classifies each failure against the F-ids in failure-patterns.md, extends that catalogue with new patterns/dossiers/laws, folds the findings back into the olympus-hunt and olympus-author skills, archives the problem into approved-problems/, and reclaims the disk the batch artifacts and worktree clone were holding. Triggers when the user says "it got accepted", "problem approved", "finalize this problem", "we shipped it", or pastes an acceptance notice. Source of truth: Olympus/failure-patterns.md § 4 (adding a new problem), CLAUDE.md § After Approval, Instructions/HARDENING.md, Instructions/TOO-EASY.md.
---

# Olympus Finalize — turn one accepted problem into reusable method

Runs ONCE per accepted problem, after a **confirmed human reviewer** acceptance. Auto Review,
Test Fairness and FP panels passing are NOT acceptance — do not run this on them.

The output is not a summary. It is: new measured rows in `failure-patterns.md`, edits to the
skills that will author the next problem, an archived folder, and reclaimed disk.

---

## Stage 0 — Preconditions (30 s)

```bash
P=problems/<name>
ls $P                       # 5 deliverables + feedback.md + eval-results.md
ls -d $P/agent-runs* 2>/dev/null || echo "NO RUNS — see Stage 1 fallback"
du -sh $P worktrees/<repo>
```

If there are no agent-run artifacts, say so plainly and run Stages 4-7 only. The catalogue is
worth exactly its measured counts — never write a kill count you did not compute.

---

## Stage 1 — Mine the batch (MECHANICAL, 5 min)

**Parse JUnit with ElementTree, never regex.** The platform's `junit-new.xml` is one flat
`<testsuite name="new">` whose passing cases are SELF-CLOSING `<testcase .../>`. A
`<testcase[^>]*>(.*?)</testcase>` regex spans from a self-closing tag to the next real closing
tag and attributes failures to the wrong test — it will tell you a confident, wrong story.

```bash
cd problems/<name>/agent-runs*/<latest batch>
python3 - <<'EOF'
import glob, json, os, xml.etree.ElementTree as ET
from collections import Counter
kills, runs, verdicts, allt = Counter(), {}, {}, set()
for d in sorted(glob.glob('*/')):
    n = d.strip('/')
    ev = d+'eval-result.json'
    verdicts[n] = json.load(open(ev)).get('verdict') if os.path.exists(ev) else 'NO_RESULT'
    if not os.path.exists(d+'junit-new.xml'):
        print(f"{n:16} {verdicts[n]:24} no junit"); continue
    cases = list(ET.parse(d+'junit-new.xml').iter('testcase'))
    failed = [tc.get('name') for tc in cases
              if tc.find('failure') is not None or tc.find('error') is not None]
    allt.update(tc.get('name') for tc in cases)
    runs[n] = failed
    wiped = len(failed) == len(cases)
    if not wiped:
        kills.update(failed)
    print(f"{n:16} {verdicts[n]:24} {len(failed):3}/{len(cases)} failed{'  WIPEOUT, not counted' if wiped else ''}")
print("\nPASS RATE:", sum(1 for v in verdicts.values() if 'PASS' in (v or '')), "/", len(verdicts))
print("\nPER-TEST KILLS (wipeouts excluded):")
for k, v in kills.most_common(): print(f"  {v:3}  {k}")
print("\nKILLED NOTHING:", len(allt - set(kills)), "of", len(allt))
EOF
```

**Key on `name`, and compare element counts, never sets of names.** pytest puts the module in
`classname` and the test in `name`, so keying on `classname` collapses the whole suite into one row.
A wrapper timeout can write duplicate test names (sfepy: 117 elements, 116 distinct), so a set-based
"failed everything" check lets it through and inflates every kill count.

**The pool is cumulative (L64).** A later batch folder re-lists earlier runs under new numbers and
appends the new ones. Mine only the LATEST folder, and fingerprint runs (added LOC plus
`total_prompt_tokens`) to tell appended runs from re-listed ones before you write any split.

**If most failing runs fail EVERY new test, the JUnit files are not data.** Check the evaluators for
"stale", "restored" or "unbuilt" first (L63). Then per-test kill counts are an artifact of the harness,
and the failure taxonomy has to come from the evaluators' static findings plus a trajectory scan for
`git restore`/`checkout` of build outputs after the last build. Say so in the dossier.

Then the qualitative half — the evaluator's own words are the best failure taxonomy you will get:

```bash
python3 -c "
import json, glob, os
for d in sorted(glob.glob('*/')):
    if not os.path.exists(d+'eval-result.json'): print(d, 'NO RESULT'); continue
    j = json.load(open(d+'eval-result.json'))
    print('=='*30); print(d, j.get('verdict'))
    print('SUMMARY:', str(j.get('summary'))[:400])
    ju = j.get('justification') or {}
    print('EVIDENCE:', str(ju.get('evidence'))[:600])
    print('MENTIONED IN DESC:', ju.get('was_mentioned_in_description'),
          '| INFERABLE FROM CODE:', ju.get('was_inferable_from_codebase_excluding_tests'))
    print('ASSESSMENT:', str(j.get('problem_assessment'))[:300])
"
```

Long-horizon and scope facts, from the patches and trajectories:

```bash
python3 -c "
import json, glob, os, re
for d in sorted(glob.glob('*/')):
    if not os.path.exists(d+'solution-patch.patch'): continue
    p = open(d+'solution-patch.patch').read()
    fm = json.load(open(d+'trajectory.json')).get('final_metrics', {})
    print(d.strip('/'), 'files', len(re.findall(r'^diff --git', p, re.M)),
          '| +LOC', len([l for l in p.splitlines() if l.startswith('+') and not l.startswith('+++')]),
          '| prompt_tok', fm.get('total_prompt_tokens'))
"
```

`trajectory.json` `steps` is a truncated summary (often 6 entries) — it is NOT a message count.
Use prompt-token totals as the effort proxy and say so rather than inventing a message count.

---

## Stage 2 — Analyse (the stage that produces the lessons)

Answer all seven. Each maps to a law that already exists or a new one.

| # | Question | Read it as |
|---|---|---|
| 1 | **Pass rate**, and where in the ≤40% band | ≤40% and ≥1 pass = healthy. Near 40% = the next problem needs a stronger lead trap |
| 2 | **Failure clusters** — do N runs fail the IDENTICAL test set? | One dominant cause is FAIR if anyone cleared it (L18). Check: passes exist? near-misses got everything else? evaluators said `description_clear: true`? FP clean? |
| 3 | **Near-misses** (20/21, 19/21) — what was their SOLE failure? | This is the band decider. Almost always an F-10 cross-product cell. Record it by name |
| 4 | **Which tests killed NOTHING?** | Not waste (fairness + FP insurance), but proof that effort there bought no difficulty. Name them so the next problem does not repeat the spend |
| 5 | **Did a deliberately-authored wall kill zero agents?** | L15. Say it out loud. A trap justified on mutation evidence is unproven until a batch |
| 6 | **Where did the decisive test come from** — your design, or a reviewer's coverage suggestion? | L17. If it was the reviewer's, that is the finding |
| 7 | **Agent split** (Nova vs Orion vs Vega) | Orion has been load-bearing on every problem so far. A batch without it reads lower than the truth |

Also: what did HARDENING find in **your own reference** before the batch? Every problem so far
has produced ~3 reference bugs, and each would have been an FP (L7). Count them.

---

## Stage 3 — Classify against `failure-patterns.md` § 1

Map every distinct failure cause to an F-id.

- **Existing F-id** → add the count to that pattern's Evidence line in the form
  `<problem>: n/m runs`. **Never overwrite an existing count** — patterns earn weight by
  accumulating.
- **No match** → candidate new pattern. Promote it ONLY if it killed in **two independent runs**;
  a single failure is agent noise. Give it the next F-number and write the full block:
  Mechanism / Why it misdirects / Evidence (verbatim evaluator quotes) / Precondition /
  How to build / Arsenal mapping.
- **Read >40% twice across problems** → demote to the DEAD list in `TOO-EASY.md`.

---

## Stage 4 — Write it back (the actual deliverable)

1. **`failure-patterns.md`**
   - § 1: new F-block and/or updated Evidence lines.
   - § 2: a dossier using the § 4 skeleton — Shape / Final artifact / Pass-rate history /
     Patterns used / Agent split, then "Why it held", "What the batch taught" (only findings that
     GENERALISE), "Reference bugs found".
   - § 3: any new law, next L-number, with its evidence cell filled from THIS batch.
   - § 5: a targeting-table row per new pattern — "Repo has… / Reach for… / Expected".
2. **`.claude/skills/olympus-hunt/SKILL.md`** — if the new pattern has a precondition you can spot
   in a source tree, add a Stage-3 seam row, a grep probe, and a dossier row. A pattern nobody can
   find at hunt time is a pattern nobody will use.
3. **`.claude/skills/olympus-author/SKILL.md`** — add the pattern to Phase 3 Step B-bis targeting,
   to the Difficulty Levers ranking (with its MEASURED number), and to the DESIGN.md § 11 / § 11b
   checklists if it introduces a new required audit.
4. **`.claude/skills/olympus-harden/SKILL.md`** — if the batch showed a lever that worked (or one
   that provably did not), update the diagnosis→lever table.
5. **Per CLAUDE.md § After Approval**, append a concise, file-appropriate section to:
   `Instructions/lessons-learned.md`, `Instructions/KNOWLEDGE.md` (agent blind spots),
   `Instructions/PLAYBOOK.md` (or the two Diamond files if Diamond),
   `Instructions/olympus-extreme-complexity-guide.md`, `Instructions/PROBLEM-PROFILES.md`,
   `Instructions/SHAPES.md` (only if a shape was introduced/confirmed),
   `Instructions/PATTERNS-ADVANCED.md` (only if a reusable numbered pattern emerged).
   Differentiate by each file's purpose — do not paste the same text into all of them.
6. **`approved-problems/README.md`** — add the compact index entry: what made it hard, what broke
   it and the fix each time, in the voice of the existing entries.

---

## Stage 5 — Archive

```bash
git mv problems/<name> approved-problems/<name>    # flat, no repo subdir
```

Keep: the 5 deliverables + `feedback.md`, `eval-results.md`, `DESIGN.md`. Those are the durable
record and they are small.

---

## Stage 6 — Reclaim disk (do this LAST, and only after Stage 4 is written)

The batch artifacts are hundreds of MB and are worthless once mined. The worktree clone is
usually the biggest single item in the repo.

```bash
du -sh approved-problems/<name>/agent-runs* worktrees/<repo>
rm -rf approved-problems/<name>/agent-runs*        # extracted dirs AND the .zip
rm -rf worktrees/<repo>                            # re-clonable from BASE_COMMIT.txt at any time
df -h / | tail -1
```

**Order matters.** Everything durable must already be in `failure-patterns.md` and
`feedback.md` before anything is deleted — the runs are the only source for kill counts and you
cannot recompute them later.

---

## Stage 7 — Report

Short. What the batch measured, which pattern it confirmed or added, which of your own hardening
investments provably did nothing, what changed in the skills, and how much disk came back.

---

## Anti-patterns

- **Do not write a kill count you did not compute.** The file is worth exactly its measured numbers.
- **Do not promote a one-run failure to a pattern.** Two independent runs minimum.
- **Do not launder a failed investment.** If a wall you spent three rounds on killed nobody, that
  is the most valuable line in the dossier. Write it.
- **Do not delete before writing.** Stage 6 after Stage 4, always.
- **Do not paste the same paragraph into seven Instructions files.** Each has a purpose; write to it.
