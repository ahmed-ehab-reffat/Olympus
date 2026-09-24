---
name: olympus-factory
description: Continuous hunt -> slice loop. Keeps one olympus-hunter and one olympus-builder subagent busy and hands each new problem over at SLICE-READY, so the human finishes it in a session of their own; it only runs a FINISH itself when asked to. Run with /olympus-factory; stop by typing "stop" or creating pipeline/STOP.
disable-model-invocation: true
---

# Olympus factory: the hunt -> author loop

You are the ORCHESTRATOR. Do no hunting or authoring yourself: every hunt and every authoring run is a
fresh subagent. That keeps this session's context small so it can run for days. Your jobs are to launch
workers, parse their result blocks, keep `pipeline/LEDGER.md` accurate, and react to `pipeline/INBOX.md`.

Arguments (optional, free text): language or domain preferences, and limits such as
`max-handoff=5` (stop after 5 HANDOFF rows) or `no-hunt` (only drain existing work). Pass preferences on
to every hunter. `finish-here` restores the old behaviour: the loop also runs FINISH builds itself.

## Where the loop hands over (DEFAULT)

The loop's job is hunt -> scope-lock -> core slice. When a SLICE builder returns `SLICE-READY`, the
problem is HANDED OVER: set the row `HANDOFF`, notify, and never launch another worker on that slug.
The human runs the picker and the precheck and then finishes the problem in their own session, because
FINISH is where scope judgement, description wording and batch strategy live.

Run a FINISH build only when the human asks for one: an inbox line `<slug>: finish` (optionally with
pasted precheck warnings after a `|`), or the `finish-here` argument, which makes `clean` verdicts queue
a FINISH the way they used to. Without that, a `clean` verdict is only bookkeeping.

## State

- `pipeline/LEDGER.md`: one row per candidate. You are its only writer. Also append one dated line per
  event to its `## Log`.
- `pipeline/INBOX.md`: the human writes here, and you move each handled line from `## New` to
  `## Processed`.
- `pipeline/STOP`: if this file exists, stop launching work.

Statuses: `HUNTED` (queued) -> `SLICING` -> `HANDOFF` (default end state: the human takes it from here).
With `finish-here` or a `finish` inbox line the older path still exists:
`HANDOFF` -> `PRECHECK-CLEAN` -> `BUILDING` -> `READY`. Side exits: `DEAD`, `CLAIMED`.

## Limits

- At most ONE hunter and ONE builder running at once. They run in parallel with each other.
- Launch a hunter only while fewer than 2 rows are `HUNTED`.
- Launch a SLICE builder only while fewer than 4 rows are `HANDOFF`. Past that the human is the
  bottleneck: send one notification and stop slicing until a row clears (`CLAIMED`, `DEAD` or finished).

## The tick (run it at start, after every worker result, and after every wake-up)

1. **STOP check.** If `pipeline/STOP` exists or the user said stop: launch nothing new, let running
   workers finish (or TaskStop them if the user said "stop now"), update the ledger, print the summary
   (see "Stopping"), and end. If the user said "pause", finish the running workers and wait on the inbox
   without launching new ones.
2. **Inbox.** Process each line under `## New`:
   - `clean`: set the row `PRECHECK-CLEAN` and keep any pasted warnings. Queue a FINISH only under
     `finish-here`; otherwise the row is the human's and the loop just records it.
   - `finish` (optionally `| <pasted precheck warnings>`): the human wants the loop to build this one
     after all. Set `PRECHECK-CLEAN` and queue a FINISH build.
   - `dead` or `picker-refused`: launch nothing. Shelve the problem yourself: `git mv problems/<slug>
     rejected/<slug>` (or plain `mv`), plus a one-line entry in `Instructions/SATURATED-REPOS.md` (A0
     for a picker refusal, the lane ledger for a dedupe death). Set the row `DEAD`.
   - `claimed`: set `CLAIMED` and never touch that slug again.
   - `hunt-hint`: add it to the hunter preferences.
   Then move the line to `## Processed`.
3. **Worker results.** Parse the result block of any worker that just finished (formats are in
   `.claude/agents/olympus-hunter.md` and `olympus-builder.md`):
   - Hunter `CANDIDATE`: add a `HUNTED` row keyed by repo (slug `TBD`) and reset the miss counter.
     `NO-CANDIDATE`: add 1 to the miss counter and keep its `NEXT_HUNT_HINT`.
   - Builder `SLICE-READY`: set `HANDOFF`, fill in the real slug, and notify the human (see
     "Notifications"). Launch nothing else on that slug.
   - Builder `READY`: set `READY` and notify.
   - Builder `DEAD`: set `DEAD` with the reason. If it was a SLICE run and the hunt had `FALLBACKS`, add
     the first unused fallback as a new `HUNTED` row.
   - Garbled result or crashed worker: read `problems/<slug>/feedback.md` to recover the state. Retry the
     same job once; if it fails twice, mark the row `DEAD (worker failure)` and move on.
4. **Disk gate.** Run `df -h / /var/lib/docker`. Launch builders only if both have >= 10G free. If not,
   notify the human once, keep hunting (hunts barely use disk), and re-check each tick. Never prune Docker
   and never delete anything outside `worktrees/<repo>/target` yourself.
5. **Launch builder** (if the builder slot is free and the disk gate passed). Pick in this order:
   a. FINISH the oldest `PRECHECK-CLEAN` row that the human asked for (a `finish` line, or any
      `PRECHECK-CLEAN` row under `finish-here`); set it to `BUILDING`;
   b. otherwise SLICE the oldest `HUNTED` row (set it to `SLICING`), if the `HANDOFF` cap allows.
6. **Launch hunter** (if the hunter slot is free, fewer than 2 rows are `HUNTED`, and no `no-hunt`).
   Pass `CONSECUTIVE_MISSES`, the preferences, and the last `NEXT_HUNT_HINT`. After 5 misses in a row,
   notify the human once and keep going. The hunter itself widens its search as misses grow.
7. **Idle.** If nothing is running and nothing can be launched, the loop is waiting on the human. Start
   `bash .claude/skills/olympus-factory/wait_inbox.sh 7200` with `run_in_background: true`. When it exits
   you are re-invoked: run the tick again. If the user talks to you meanwhile, answer and re-tick.
8. Write the ledger, then end your turn. Running workers wake you up when they finish.

## Launching workers

Use the Agent tool with `subagent_type: "olympus-hunter"` or `"olympus-builder"`. Keep prompts short:
the agent file holds the whole contract. Include today's date, and:

- hunter: `CONSECUTIVE_MISSES=<n>`, preferences, the last hint.
- SLICE builder: `MODE=SLICE REPO=<owner/repo> LANE=<...> HUNT_LOG=<path> FALLBACKS=<...>`.
- FINISH builder: `MODE=FINISH SLUG=<slug>`, plus the precheck warnings pasted verbatim from the inbox.

Never run two builders on the same slug. Never launch any worker on a `CLAIMED` row or on a
`problems/` folder that has no ledger row (it belongs to a human session).

## Notifications

When the PushNotification tool is available (load it with ToolSearch), use it for: a handed-over slug
(include the slug and "picker + precheck, then finish it in your own session"), a READY slug from a
requested FINISH, the disk gate blocking, and 5 hunt misses in a row. Otherwise print one clear line in this session.
Do not notify on routine ticks.

## Stopping

Print a table of every ledger row touched this run, with its status and next human step. Report counts
(HANDOFF / READY / DEAD) and the remaining disk. For each `HANDOFF` row give the handover facts the
human's next session needs: folder path, what is owed (picker, precheck), the measured LOC and the
FINISH plan in its `DESIGN.md`. Do not commit. The human decides what enters
git.

## Rules that stay in force

The PRIME DIRECTIVE and every HARD RULE in `CLAUDE.md` bind the workers. The orchestrator does not relax
any gate to keep the pipeline moving: a dead pick is recorded and replaced, never pushed through.
