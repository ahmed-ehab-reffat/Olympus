# Repo Diamond Recon — methodology + invocation

Reusable deep-research workflow for any candidate repo. Outputs 3 deliverables ready for authoring kickoff.

## When to use
- New repo proposed for Diamond/Olympus authoring
- Revisit a previously-rejected repo (e.g., user thinks "maybe too easy")
- Pre-flight before scope-locking any Diamond pick

## When NOT to use
- Shortlist hunt across many repos (use CANDIDATE-HUNT broad search instead)
- Single-issue feasibility check (just run SIX-CHECK manually)
- Mars-tier only authoring (use olympus-author skill directly)

## Invocation
```js
workflow({
  name: 'repo-diamond-recon',
  args: { repo: 'OWNER/NAME', language: 'Go' }
})
```

Examples:
```js
workflow({ name: 'repo-diamond-recon', args: { repo: 'HDT3213/rdb',          language: 'Go' } })
workflow({ name: 'repo-diamond-recon', args: { repo: 'jhillyerd/enmime',     language: 'Go' } })
workflow({ name: 'repo-diamond-recon', args: { repo: 'collective/icalendar', language: 'Python' } })
workflow({ name: 'repo-diamond-recon', args: { repo: 'd5/tengo',             language: 'Go' } })
```

## Output
3 files written to `analysis-folders/<repo>-analysis/`:

| File | Purpose |
|---|---|
| `DIAMOND-ASSESSMENT.md` | 12-section assessment mirroring calcite-analysis/ASSESSMENT.md |
| `diamond-candidates.md` | Ranked Diamond picks (after LOC-fit + SIX-CHECK gating) |
| `olympus-candidates.md` | Olympus fallback picks (if Diamond Castor pass band misses) |

Plus structured return value with `verdict.repo_verdict`: `GO_DIAMOND` / `GO_OLYMPUS_ONLY` / `HARD_REJECT`.

## 6-phase pipeline

| Phase | Agents | Purpose | Hard-gates |
|---|---|---|---|
| 1. Recon | 1 (schema-locked) | gh api metadata + maintainer philosophy + recent activity + soft-archive detection | RED severity flag = abort |
| 2. Architecture | 1 | Subsystem map + entanglement zones + LLM-saturation 0-10 per zone | No zone with saturation under 5 = abort |
| 3. Propose | 5 parallel (Diamond) + 3 parallel (Olympus) | One candidate per high-value zone, schema-validated | No Diamond proposals = downgrade. **GATE 1 behavioral-f2p** (base observably WRONG, NOT composable/perf-only) + **GATE 3 uniform-wrap** (multiple opposing interdependent traps, not one mechanism) enforced — fail = dropped |
| 4. LOC-fit | Pipeline per Diamond candidate | Natural meaningful-LOC verify per orb precedent | Under 400 = REJECT, over 650 = NEEDS_BROADEN reverse. **GATE 4 LOC-ceiling**: a fix to already-mostly-correct code is surgical sub-floor (loc_ceiling_risk) = dropped (estimate the ACTUAL diff, not file sizes) |
| 5. Verify | Parallel per LOC-survivor | Pattern 22 SIX-CHECK + **GATE 7 dedup-our-authored-set** (all dirs by feature class) + **GATE 6 reproduce-on-base** (bug-fix: repro must FAIL on base) + cold-not-live by DATES | RED = drop, YELLOW = flag, GREEN = keep |
| 6. Synthesize | 1 | Write 3 deliverable files + final verdict | — |

## Filter rules baked in

> Canonical gate list: **`Instructions/PICK-FILTER.md`** (run all 8). The workflow enforces them across phases: GATE 1 behavioral-f2p-gap + GATE 3 uniform-wrap (Propose), GATE 2 saturation (Architecture), GATE 4 LOC-ceiling-actual (LOC-fit), GATES 5/6/7/8 cold-not-live / reproduce-on-base / dedup-our-authored-set / defined-behavior (Verify). Each gate = a dead pick this session (diff-dataflow #80 perf-only, cel-exhaustive uniform-wrap, yaegi-value-bridge LOC-ceiling, loro-742 already-shipped, yaegi-reflect-identity our-prior-art).

### LLM-saturation filter (CANDIDATE-HUNT section 14.11)
- Reject zone if 5+ widely-used tutorials in domain
- Reject if reference impl in another language is famous (turndown.js / jinja2)
- Reject mega-popular repos (>10k stars)
- Reject single-axis dispatch (per-tag handler, per-blend mode, per-dialect store)

### LOC-natural-fit filter (calibrated 2026-05-30)

**Calibration data:** measured ALL 39 approved Olympus + Diamond submissions. Distribution:
- 3 approved Diamonds: cliffy-command-aliases 267 / dasel-csv-options 408 / tengo-crypto 601 meaningful
- 36 approved Olympus median: 280-300 meaningful
- 19% of approveds clear 500 meaningful; 25% clear 450; 50% clear 280

**Banded verdict (replaces previous 400-650 single GO band):**

| Band | Meaningful LOC | Fit value | Action |
|------|----------------|-----------|--------|
| REJECT | < 250 | REJECT | Too small for any tier — abandon |
| OLYMPUS_ONLY | 250-399 | OLYMPUS_ONLY | Below user Diamond policy (500). Downgrade to Olympus, do NOT force-broaden |
| GO_ACCEPTABLE | 400-499 | GO_ACCEPTABLE | Meets PLAYBOOK § 3 floor. Matches dasel-csv-options approved Diamond (408). Below user pref but valid |
| GO_PREFERRED | 500-650 | GO_PREFERRED | **User policy + Castor sweet spot** (tengo-crypto 601 / Castor 4/10). FIRST CHOICE |
| GO_EXTENDED | 650-850 | GO_EXTENDED | Over PLAYBOOK ceiling but historically approved (canopy-snapshot 627, dasel-html 623, markdownit-ast 536). Allow |
| NEEDS_NARROW | > 850 | NEEDS_NARROW | Plagiarism + API overflow risk (orb-ring-orientation 507 + 30 APIs hit 0.691 similarity flag). Carve coherent sub-feature |

**Rules:**
- NEVER force-broaden a naturally-small feature (orb-ring-orientation precedent)
- If ALL candidates in a repo fall <400 meaningful → repo is Diamond-incompatible at user policy → return GO_OLYMPUS_ONLY honestly
- If ALL candidates fall <250 → HARD_REJECT
- Raw LOC = meaningful / 0.65 (so 500 meaningful = 770 raw, 400 meaningful = 615 raw)
- Test files counted separately; LOC band measures source ADD only

### Section 9 gate (DIAMOND-PLAYBOOK section 9)
- Soft-archive signals: HARD REJECT (miekg/dns precedent)
- Closed-with-implemented: RED
- "By design / won't add" comments: RED
- Post-base maintainer fix in zone: YELLOW (verify still relevant)

### Diamond quality criteria (DIAMOND-PLAYBOOK section 2)
- Admits 2+ natural implementations
- 2-fact COMBINATION constraint
- Operates on a BOUNDARY
- Test asserts SPECIFIC structural value

## Token budget
Mean cost per invocation: ~50,000-80,000 tokens (1 recon + 1 arch + 5+3 propose + 5 LOC + 3 SIX-CHECK + 1 synthesize = ~18 agent calls).
Cost vs savings: catches HARD-REJECT repos (miekg/dns precedent saved ~$500 + 12 attempts) and prevents LOC-overflow scope spread (orb precedent saved 1 plagiarism cycle). Net positive even on GO outcomes.

## Source-of-truth references
- `Instructions/DIAMOND-PLAYBOOK.md` sections 1-9 (trap categories + bands + Section 9 gate)
- `Instructions/DIAMOND.md` (pipeline + staleness)
- `Instructions/PATTERNS-ADVANCED.md` Pattern 22-24
- `CLAUDE.md` Critical Rule (SIX-CHECK protocol)
- `analysis-folders/calcite-analysis/ASSESSMENT.md` (shape mirror)
- `analysis-folders/CANDIDATE-HUNT-2026-05-13.md` section 14.11 (LLM-saturation rules)
- `diamond-problems/orb-ring-orientation/feedback.md` (LOC-band overflow precedent)
- `diamond-problems/tengo-crypto/feedback.md` (LLM-saturation hardening cycle precedent)
- `diamond-problems/dasel-multi-file/feedback.md` (Stage 0 maintainer-philosophy reject precedent)

## Iterating on the workflow
Edit `.claude/workflows/repo-diamond-recon.js`. Schemas live at top; phase logic below. Add new schemas for new constraint dimensions (e.g., dispatch-absorber detection score, post-base PR velocity).

## Resume support
If a run is interrupted: `workflow({ name: 'repo-diamond-recon', scriptPath: '<returned-path>', resumeFromRunId: '<wf_id>' })`. Same args = 100% cache hit on unchanged phases.
