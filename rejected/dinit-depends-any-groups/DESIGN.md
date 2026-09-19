# DESIGN.md — dinit-depends-any-groups

Source: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-19.md` Part 2 (RANK 1), dossier
`worktrees/_hunt/agents/dinit-0919.md`. Base `bf63b446aee776e306ad54c5b0df2a2a50685d41` (master HEAD,
2026-09-07). Picker check passed 2026-09-19.

## Phase 1 — repo understanding

**Architecture (one paragraph).** dinit is a service manager. `service_record` (service.h/.cc) holds
each service's state machine: current + desired state, an acquisition count (`required_by`), pins,
and two lists of `service_dep` links (`depends_on`, `dependents`). State changes run in two phases
over two queues owned by `service_set`: propagation (`do_propagation`: require/release, start/stop
requests, failure, pin propagation; may set STARTING/STOPPING, never STARTED/STOPPED) and execution
(`execute_transition`: wait for dependencies/dependents, `bring_up`/`bring_down`). Every dependency
decision is made per link from `dep_type` via `is_hard()` / `is_only_ordering()`. Service files are
parsed by one templated parser (`load-service.h`, `process_service_line`) instantiated by the daemon
loader (`load-service.cc`, dependency record `prelim_dep`), `dinit-check` (own record type) and
`dinitctl`. The control protocol (`control.cc`) serves dinitctl, including the "gentle stop"
dependents check.

**Subsystems.** (1) service state machine `service.cc`/`service.h`; (2) service-description parser
`load-service.h` + daemon loader/reload `load-service.cc`; (3) process services `baseproc-service.cc`,
`proc-service.cc`; (4) control protocol `control.cc` + client `dinitctl.cc`; (5) offline checker
`dinit-check.cc`.

**Entanglement zones.** (a) `stop_dependents` / `stop_check_dependents` / `stopped()` (stop,
restart, force-stop and soft-link breaking all meet here); (b) `failed_to_start` + `do_propagation`
(failure propagation through the prop queue); (c) the parser template (every instantiation must
accept whatever record constructor the parser calls).

**Tests.** Hand-rolled assert harness, `RUN_TEST` in `src/tests/tests.cc` (abort on first failure,
prints `name... PASSED`). Service-level tests build `test_service` records (`src/tests/test_service.h`)
from `prelim_dep` lists and drive `started()` / `failed_to_start()` by hand over a mocked event loop
and mocked syscalls. Template: `test_softdep*` and `test_pin*` in `tests.cc`; control tests in
`src/tests/cptests/cptests.cc` (`cptest_gentlestop`).

## Phase 2 — exclusivity (run 2026-09-19)

Canonical `davmac314/dinit`. PR + issue search for `depends-any`, `any of`, `alternative`,
`dependency group`, `one of`, `provider`, `OR dependency`, `either`: no implementation. #432 (q66,
providers, open, no maintainer reply), #54 (q66 floats providers, no design), #562 (ordering-only
"any instance", closed on process). Full history `git log -S` (2112 commits) + all public branches:
no removal record. systemd/s6/runit have no any-of dependency; OpenRC `provide` selects ONE provider
by name; Upstart `or` is an event expression without stop/failure propagation. Not a port.

## 1. Title

Add depends-any dependency groups to dinit services

## 2. Shape

O-Composite-add (new capability through the state machine, loader, control protocol and checker).
Pass target 15-30%. Dominant verdict predicted: MISSED_REQUIREMENT on composition cells.

## 3. Public API surface (names tests call)

- service setting `depends-any = <name> [<name> ...]`: one group per setting line, one or more names.
- `dependency_type::ANY`: the link type of a group member.
- `prelim_dep(service_record *to, dependency_type type, unsigned group)`: third argument is the
  group number (defaults to 0 for existing two-argument uses). Members of one group share a nonzero
  number; different groups of the same dependent use different numbers.
- existing APIs exercised unchanged: `service_set::start_service/stop_service`, `service_record::
  restart/forced_stop/pin_start/unpin/get_state/get_stop_reason`, control STOPSERVICE gentle stop,
  `dirload_service_set::load_service`, the `dinit-check` binary.

## 4. Canonical behaviour (the contract)

- Starting the dependent acquires every member, as depends-on does.
- The dependent's start proceeds once any member of each group is STARTED; it does not wait for the
  rest.
- A member failing to start does not affect the dependent until every member of that group has
  failed to start (none STARTED); then the dependent fails to start (DEPFAILED) as with depends-on.
- A STARTED member that stops, restarts, or is forced to stop affects the dependent exactly as a
  depends-on dependency would (dependent stopped first and the member waits for it, restarted
  together, or forced down) only when it is that group's last STARTED member. Otherwise it releases
  the dependent's hold without waiting and the dependent is untouched.
- Pinning the dependent started pins every member, as for depends-on.
- Gentle stop lists a group dependent only when the member is its group's last STARTED member.
- Each `depends-any` line is a separate group; the dependent needs all of its groups plus its other
  dependencies. An empty `depends-any` is a service description error.
- dinit-check accepts the setting and treats members as dependencies for its cycle and depth checks.

## 5. Blind-spot pre-empts

- "as depends-on would" anchors every group-member stop/restart/force outcome to an existing,
  tested semantics (removes invented-outcome ambiguity; the depends-on twin is the test oracle).
- "each setting line is a separate group" (dedup / scope).
- ≤1 codebase-inferable: a pinned-STOPPED service's start attempt is a start failure (service.h header).

## 6. Description draft

In meta.md (≈380 words). Plain prose, dinit nouns (acquire, STARTED, DEPFAILED, pins, gentle stop).

## 7. File footprint (sketch; measured after the reference exists)

| Action | Path | Work | eff (est) |
|---|---|---|---|
| MODIFY | src/includes/service-constants.h | `ANY` enumerator | 2 |
| MODIFY | src/includes/service.h | group on `prelim_dep`/`service_dep`, group helpers, `add_dep` | 40 |
| MODIFY | src/service.cc | start readiness, failure-when-all-failed, last-member stop/restart/force, stop-wait, pins, soft release/re-attach | 150-170 |
| MODIFY | src/includes/load-service.h | parse multi-name `depends-any`, group numbering, empty error | 30 |
| MODIFY | src/includes/dinit-settings.h, src/settings.cc | setting id + table entry | 6 |
| MODIFY | src/load-service.cc | carry group through load + reload | 15 |
| MODIFY | src/control.cc | gentle-stop dependents check | 10 |
| MODIFY | src/dinit-check.cc | record type accepts group | 5 |
| **total** | 9 files | | **~260-300** |

## 8. Solution outline (helpers)

- `service_dep::get_group()`; `service_record::group_has_other_started(dep)` (sibling scan over the
  dependent's `depends_on` for the same group, STARTED only);
- `service_record::group_failed(dep)` — per-link failure marks, all members of the group marked;
- `is_last_started_member(dept)` used by `stop_dependents`, `stop_check_dependents`, `stopped()`,
  control `check_dependents`;
- start: `start_check_dependencies` / `check_deps_started` treat a group as waiting until one member
  STARTED; member `started()` releases every sibling's `waiting_on`;
- pins: group links count as hard in `prop_pin_dpt` and `pin_start`/`unpin` propagation.

## 9. Test outline

New file `src/tests/anydeptests_<hex>.cc`, own `main`, fork per test, prints `name: PASSED|FAILED`;
test.sh maps to JUnit. Buckets:
- start (first member suffices; waits with none started; members all acquired; mixed with depends-on)
- failure (all failed -> DEPFAILED; one failed + other starts -> starts; pinned-stopped member in
  propagation (T1); all pinned-stopped)
- stop (last stops dependent first, member waits (T2); non-last leaves dependent STARTED and does not
  wait; then the remaining member becomes last; common-dependency double stop (T3); released member
  stops when nothing else needs it)
- restart / forced stop x {last, not last}, each compared to a depends-on twin (F-10)
- pins (pinned dependent holds non-last member; unpin) (T4)
- groups (two lines = two groups; merge trap)
- control gentle stop x {last, not last}
- loader (files via dirload: two groups behave independently; empty line is an error)
- dinit-check subprocess (setting accepted; cycle through a member reported)

## 10. Forced shapes

`prelim_dep` three-argument constructor and `dependency_type::ANY` are the only new symbols the tests
compile against. Both stated verbatim in meta.md (L72 compile-wipe). Tests never read a group number
back.

## 11. Trap matrix

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Meta sentence | Test |
|---|---|---|---|---|---|---|---|---|
| T1 | member fails inside propagation before siblings' queued starts run; "any sibling STARTED/STARTING" reads none and fails the dependent | F-1 (two-phase), new | S2 | start-failure timing | T3 (same "which siblings count" predicate) | sibling states lag the prop queue | "fails only when every member of that group has failed to start" | pinned-stopped member + slow member |
| T2 | last member must wait for the dependent; deciding at `stopped()` (execution) lets the member stop first | F-2 | S4 | stop ordering | T3 | soft-break code path lives in `stopped()` | "as depends-on would: the dependent is stopped first" | auto_stop=false member, assert ordering |
| T3 | two members stopped in one propagation round (common dependency) — a "not STOPPED" sibling check leaves the dependent running with no member | F-26 | S2 | sibling classification | T1, T2 | STOPPING looks alive | "only when it is that group's last STARTED member" | common-dependency stop |
| T4 | pins use `is_hard()` twice; a group-aware `is_hard` pins only a "last" member | F-3 | A6 | pins | T2 (same predicate reuse) | reuse of the new last-member predicate | "pinning the dependent started pins every member" | pinned dependent + non-last stop |
| T5 | groups merged across lines | F-11 | A2 | group scope | — | one set per dependent is simpler | "each line is a separate group" | two groups |
| T6 | restart/force x last/not-last cells | F-10 | S2 | event kind | T2 | each event is a separate code path in `stop_dependents` | "stops, restarts, or is forced to stop" | twin comparison |

## 11b. Cross-product

| | last STARTED member | not last |
|---|---|---|
| stop | dependent stops first, member waits | untouched, no wait |
| restart | dependent restarted with it | untouched |
| forced stop | dependent forced down | untouched |
| gentle stop check | dependent listed | not listed |

Plus multiplicity: one group x two groups; group + depends-on.

## 12. Tier / category

Olympus, feature-request ("Add").

## 13. Predicted pass

15-30% on an Orion-heavy mix. Risk is 0% (many cells); mitigation: re-eval on tests only, and the
description names each rule outright.

## 14. Gates

- [x] Phase 1 5/5 · [x] Phase 2 clean · [x] title · [x] API shapes pinned · [x] every trap has an
  F-id, axes differ, T1/T2/T3 interdependent · [x] cross-product planned · [x] traps reproduced
  · [ ] **LOC: FAILED (105 human-effective)** · [ ] core-slice precheck

## Why this is not a duplicate

No service-manager problem in approved-problems/, problems/, rejected/. Closest corpus shape is the
go-workflows scheduler (state machine) — different domain and capability. Outsider name "OR
dependencies" is the derivative risk; meta.md is phrased on dinit's acquisition/pin/DEPFAILED model.

Predicted iteration cycles: 2.

## MEASURED 2026-09-19 — reference built, traps reproduced, LOC gate FAILED

Full reference (kernel, loader, reload, control, pins) over 8 files: **145 raw / 105
human-effective** (`effective_loc_check.py`). The audit's 315-340 sketch was wrong: dinit's
two-phase queue and acquisition counts absorb the feature. The kernel change is three predicates
(`group_member_started`, `group_failed`, `is_binding_dependent`), `propagates_pin`, and one
failure case; stop, restart, forced stop, stop ordering and soft release all ride the existing
`stop_dependents` / `stopped()` machinery through one call-site swap.

Trap reproduction (10 core tests, reference 10/10), each naive design killed by exactly its own
discriminator:

| Naive design | Killed by |
|---|---|
| N1 failure rule reads sibling states (STARTED/STARTING) | `any_pinned_stopped_last_listed_member_does_not_fail_dependent` (prop queue is LIFO: a member listed LAST fails before siblings' queued starts run) |
| N2 a STOPPING sibling counts as up | `any_common_dependency_stop_stops_dependent` (dependent orphaned) |
| N3' dependent stopped from the member's `stopped()` | `any_last_member_stop_stops_dependent_first` (member STOPPED before dependent) |
| N4 groups merged across lines | `any_two_groups_are_independent` |
| N3 `stop_check_dependents` left per-link | nothing (ordering already enforced by `stop_dependents`; not a wall) |

Verdict: difficulty is real, size is not. Stage 3b absorption class (sketch < 150 dies).
Reaching 200+ would need bolted-on capabilities (missing-member tolerance in loader + dinit-check,
checker lint, a keep-one-provider hand-off), each adding words and 0%-risk faster than LOC.
Work kept in `worktrees/dinit` (uncommitted diff + `src/tests/anydeptests_88f904.cc`).
