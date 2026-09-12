# THROUGHPUT-FACTORY — dual-track authoring for volume WITHOUT losing prestige

Goal: move from ~0.5 sub/day to 4-6 subs in flight, banking multiple approvals/week, WITHOUT rejection-driven prestige loss. The user is a Catharsis / high-reputation Diamond user: a string of rejects risks a downgrade, so "submit fast and let the platform measure" is BANNED. Every sub still clears the local gates before it ships. Throughput comes from re-homing PROVEN trap classes across a wide repo bench and running picks in PARALLEL, not from lowering the bar.

## The diagnosis (why we were slow)

- Funnel yield was ~10-20%: ~10 picks/week died PRE-authoring, each costing hours-to-a-day of bespoke recon. We paid full recon per pick and threw most away.
- We targeted only the hardest band (Olympus ~10%), the slowest tier to hit, one pick at a time, serially.
- We spent local effort PREDICTING difficulty (recon guesses, smoke-batches) that is only advisory — cold opus/sonnet imitators are NOT the real Nova/Orion/Vega/Castor, so the prediction is unreliable in both directions. That effort bought little and slowed everything.

## The model: two tracks, one bench

TRACK A — Mars volume (the daily banking engine). Tier Mars, band <=30% (wide), 100-380 eff LOC, 1-3 revision rounds. Author from PROVEN shapes re-homed onto bench repos. This is where the 4-6/week count comes from.
TRACK B — Olympus deep (the big payouts). Tier Olympus $250-350, band <=20%, >=450 eff LOC. 1-2 in flight at a time, drawn from the strongest bench picks with genuine cross-subsystem integration walls. Slower, higher $, keeps the deep muscle.
Both tracks draw from the SAME weekly repo bench (below). Quota forces breadth anyway: <=3 subs/repo/week, <=6/repo total ours, <=50/repo global.

## Prestige guard — which gates stay HARD vs which go advisory

The insight (user, 2026-07-02): the slow part of our pipeline was the UNRELIABLE part. Difficulty PREDICTION (recon "~X% pass", smoke-batches) is a simulation we can't trust, because we don't hold the real agents. So we CUT the slow-unreliable step and KEEP the fast-reliable ones.

HARD BLOCKS (free or cheap, high-signal — never skip, a fail here kills the pick):
- Death-class pre-pick guard (TOO-EASY.md taxonomy) — free, catches the classes that are ALWAYS too-easy regardless of agent.
- Repo-quota (SATURATED-REPOS.md + count our dirs; user platform-checks global count) — a wasted build if skipped.
- Star floor >500, permissive license (no GPL/AGPL/LGPL), right-repo-profile.
- Reproduce-on-base (the trap FAILS on base through the real public API/CLI). ⭐ RUN THIS BEFORE WRITING A PROMPT, not after. INVENTED picks especially: a documented-limitation or code-read gap can already be fixed/handled on base. 3 confirmed deaths at this gate (2026-07-03): lyon (no gap - base correct), mangle (already shipped c8a7df6), nickel-merge-priority (predicted contract-drop FALSE - base enforces). LAW: invented-from-code-READING without a base run is the death-prone class; every survivor was empirically grounded (CLI/harness/base-run), every pure-reasoning invention that skipped the base run died. For a documented-limitation pick, run the documented test ON BASE - the doc/manual can be stale. ⭐ A commented-out / FIXME / disabled test is the HIGHEST-risk stale-leftover signal, NOT reproduce-confirmation: KiteSQL's `count.slt` FIXME (rated the strongest signal in its batch) asked for exactly what base already produces = DEAD; mangle's documented test was already-shipped. Never treat a FIXME/doc-note as a confirmed gap - run it on base first. (2026-07-03 Mars batch: of 5 verified, 1 died here (KiteSQL), 2 survived strong (parry unimplemented!()-panic, jsondiff runtime-wrong), 2 survived LOC-thin needing wall-stacking (jd, deku). The gate paid for itself again.)
- f2p integrity (compile-on-base / fail-at-runtime; no new-exported-symbol trap; every new test fails-on-base and passes-after; delete base-passers).
- LOC floor via build-measure a real slice (Mars >=100, Olympus >=450).
- Flakiness (repo baseline deterministic 2-3x; our new tests deterministic 3x).
- Cold-not-live (Section-9 by DATES; re-run at submit — maintainer ships between design and submit).

ADVISORY ONLY (a weighted signal, NEVER a hard gate, NEVER shelves a structurally-sound pick):
- Smoke-batch (3-5 cold opus/sonnet). Hard-reject ONLY on an unambiguous chokepoint BLOWOUT — all solvers pass via the IDENTICAL single shared-primitive insight (gms-collation/fulltext/fancy-regex were N/N same-one-fix; that pattern transfers to real agents with confidence). Borderline / mixed / a-couple-pass = PROCEED to platform. The platform 10-run batch is the only real oracle. See feedback_measure_difficulty_not_predict.

Net: we stopped paying to PREDICT difficulty (unreliable) and kept paying to guarantee FAIRNESS + SUBMITTABILITY (reliable). The platform measures difficulty; our job is to never ship an unfair, unbuildable, quota-dead, or too-easy-by-known-death-class pick.

## The trap-class factory (recon once per CLASS, not per pick)

Our approved subs are the evidence base for what is hard-AND-fair. Each approved sub names a TRANSFERABLE trap class. Re-home a proven class onto a fresh bench repo instead of inventing difficulty from scratch:
- Emergent cross-subsystem integration wall (glaredb ordered-agg: global-sort breaks on hash-distinct; go-mysql-server) — the Olympus gold standard.
- Whole-sub-feature-hits-its-own-path (piccolo to-be-closed: generic-for 4th value = own opcode path; yaegi methodset).
- Uncorrelated capture/state leak (participle longest-match: shared-parent capture leak, off the feature's obvious path).
- Two-independent-evaluator-paths (static vs dynamic; graph-node vs policy-block) — the same capability must be re-applied on a second path the first fix never touches.
- Representation-divergent constant / canonical-form trap that survives full spec (yaegi const-representability).
- Defensive empty-result / boundary trap that is decisive on a real batch (data-forge resample).
A class is transferable when its wall is UNCORRELATED (different agents fail for different reasons; no single insight clears all) and survives full FAIR specification. Correlated-seam and uniform-wrap classes do NOT transfer — they are dead everywhere.

## Weekly cadence

1. Monday: refresh the bench. Fire 4-6 parallel recon agents across obscure deep-engine domains (compression/diff, numerical/geometry, non-flagship data engines, DSL/type-systems, protocol/parsers). Each applies every HARD gate + the death-class taxonomy and nominates features with UNCORRELATED walls only. Output = a ranked bench table. (User platform-checks global sub-count on the top candidates' repos.)
2. Assign: 3-4 bench picks to Track A (Mars, re-home a proven class), 1-2 to Track B (Olympus, integration wall).
3. Author in PARALLEL worktrees (isolation per pick; quota-spread across repos). Each pick runs the HARD gates; smoke-batch is advisory.
4. Hand finished picks to the user for platform submission (user does final submit + reviewer back-and-forth). Keep <=3/repo/week, <=6/repo total.
5. On approval: run the standard post-approval tracking updates (CLAUDE.md checklist) and fold the confirmed class back into the factory's transferable-class list.

## Guardrails (do not let volume erode these)

- Same-repo subs must partition cleanly (no superset overlap; each an independent diff vs the same base, each >=450 for Olympus). feedback_same_repo_subs_partition.
- Derivative check: grep ALL dirs (problems/, diamond-problems/, Olympus-Approved/, rejected/) by FEATURE CLASS before authoring; a match to an approved OR a rejected sub is dead.
- Never commit/push (user commits manually). Never skip the death-class guard to hit a number. A too-easy or unfair sub costs more prestige than a missed day of volume.
