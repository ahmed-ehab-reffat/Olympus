# Submission - explicit local and external transitions

Status: **accepted on 2026-07-26**. The accepted 46-test artifact, compact run
history, archive manifest, and reproducible submission package are complete.

## Target

- Repository: `https://github.com/mdeloof/statig`
- Production language: Rust
- Task type: feature request
- Base commit: `3780eecdbcf4326051c38676d592c6c2b4a3bab5`
- Production change: six core files, 349 changed lines
- Documentation change: README transition semantics and nested example
- Focused suite: 46 public-behavior tests across macro/direct and blocking/async APIs

## Artifacts

| File | Purpose |
|---|---|
| `meta.md` | 197-word ASCII task contract |
| `test.patch` | Focused tests, offline runner, nextest configuration, and JUnit handling |
| `solution.patch` | Reference implementation and README update |
| `Dockerfile` | Rust 1.90 offline verification image |
| `solution_approach.md` | Code-derived implementation explanation |
| `verify/gates.sh` | Four network-disabled patch-state gates |
| `verify/mutations.sh` | Thirty-three disposable false-positive mutations |
| `verify/audit.sh` | Patch, metadata, leak, file-list, and size checks |

`reference_solution.patch` is omitted because it would be byte-identical to
`solution.patch`.

## Verification

| Patch state | Mode | Result |
|---|---|---|
| Test patch only | `base` | 23 executable tests and 22 doctests passed |
| Test patch only | `new` | Rejected at compile time for the missing public variants |
| Test and solution patches | `new` | 46 focused tests passed |
| Test and solution patches | `base` | 23 executable tests and 22 doctests passed |

Both patches apply independently to the pinned clean source. The 20-test
predecessor passed all four gates in separate Linux containers with
`--network none`. Docker's client transport later stopped launching new
containers in this environment, so the final patch states were rerun in
separate pristine local clones with Cargo offline: clean base and solution base
passed, test-only new failed for the missing variants, and solution new passed
25/25. The focused harness also
compiles direct blocking use with no default features and direct awaitable use
with only the `async` feature.

The runner prefers Rust 1.90 and nextest when available, as guaranteed by the
Dockerfile, but falls back to the active Cargo toolchain and `cargo test` with
well-formed synthetic JUnit when either optional component is absent.
The focused-test crate adds no third-party runtime dependency; its awaitable
tests use a standard-library executor supplied by the local helper crate.

After the earlier 157-word prompt clarification and fairness adjustment, the complete
local reset verification was rerun in pristine clones: test-only base passed,
test-only new rejected the missing variants, solution new passed 26/26 plus the
feature-only compile checks, and solution base passed. The artifact/leak audit
and all twelve mutation checks also passed. `solution.patch` remains
byte-identical to the preceding level; `test.patch` changes only by removing
one duplicated blocking macro function and its now-unused fixture arms.

The hardest direct-trait cases keep an outside-subtree transition on its
ordinary common-ancestor path after handler mutation deepens the active source.
Another keeps the accepting handler as the leaf's immediate parent while
inserting a new ancestor above that handler; the new ancestor stays retained
while the accepting handler exits and re-enters. Separate static hierarchies
repeat one superstate variant at multiple depths, both within one branch and
across unrelated branches. Together they reject stale absolute-depth
bookkeeping and unqualified target-ancestry searches while asserting only
final state and action order.

The solution passes `cargo +1.90.0 check -p statig --no-default-features` and
the equivalent check with `--features async`. Every changed Rust file passes
Rust 1.90 formatting. The full workspace formatter retains only the two known
untouched example-file differences from the base commit.

## Mutation result

All twelve mutations are rejected. Every compiling semantic mutant produces at
least four failing observations: mapping new variants to legacy, incorrect
local self paths, skipped storage replacement, skipped zero-path hooks, lost or
hard-coded handler origin, unconditional external widening, either one-engine
implementation, and changed legacy self behavior. Removing public `Debug`
support and changing a public `handle` signature both fail compilation.

## Calibration

Ten independent timeboxed runs used only the task contract, focused tests, and
pinned source. Two completed all 18 original focused tests plus the complete
base suite with exactly five public variants. One additional run passed the
initial suite by introducing a sixth doc-hidden public origin variant; that
failure family was recorded and the final exhaustive public-variant check now
rejects it.
Other runs stopped on GAT ownership, trybuild compatibility, formatting
workflow, async parity, or the timebox. Calibrators consistently rated the task
medium-high to high and reported low behavioral ambiguity. Full details are in
`LEVELS.md`.

Four later Nova trajectories produced a 75% pass rate against the original
suite. Replaying their unchanged patches against the 20-test hardened suite
rejects all four: three mis-handle a mutable accepting superstate, and the
remaining implementation loses the active-leaf origin when its hierarchy
deepens during handling.

Four second-round Nova trajectories then passed that 20-test suite. Replaying
their unchanged patches against an interim 24-test suite rejected all four.
Relative-depth implementations that rediscover the target boundary by
superstate discriminant score 20/24; absolute-boundary implementations score
22/24. All four fail when a borrowed accepting handler inserts a hierarchy
level before returning, while the two discriminant-search implementations also
collapse repeated occurrences of the same superstate variant.

Five third-round trajectories all scored 22/24 against that interim suite,
failing only its mirrored borrowed in-subtree case. The final rebalancing
removed that concentrated edge and added static cross-depth outside-subtree
coverage plus a changed-source ordinary-path case. Three unchanged patches now
pass 26/26, one scores 24/26, and one scores 22/26, for a 60% pass rate with
two distinct failure families.

Four fourth-round trajectories then produced a 75% pass rate against that
26-test suite. The final hardening adds the stable-handler parent-change case
in both engines. After removing an export-path assertion not required by the
brief, the current replay scores are 24/26 for Nova 1, 24/26 for Nova 2, 22/26
for Nova 3, and 26/26 for Nova 4: a 25% pass rate.
Nova 1 fails to re-enter the accepting handler, Nova 2 unnecessarily
exits/re-enters the newly inserted parent, and Nova 3 inserts that parent into
the entry path while retaining its independent cross-branch collision failure.
Nova 4's relative-boundary implementation remains a legitimate pass.

The next immutable platform batch completed 0/10: six patches passed 25/27
focused tests and failed only the mirrored ancestor-above-handler case, three
passed 23/27 and also lost the mutated leaf-origin boundary, and one exposed a
sixth public outcome variant and failed compilation. Simply deleting the hard
pair would convert six historical patches into passes and project a 60% rate,
so the new iteration keeps every oracle and instead clarifies that handler
mutations include changes to ancestors above the accepting handler. This prompt
change resets calibration to 0/10. The later fairness removal deletes a test
that every compiling patch passed, so it changes raw replay totals but converts
none of those ten failures into a solve.

The following immutable version reached 0/6: four Nova and two Orion patches
all scored 22/26 and failed only the two repeated-superstate behaviors mirrored
across blocking and awaitable modes. They independently matched target
ancestors by superstate variant and therefore collapsed distinct hierarchy
occurrences. The current iteration states the positional rule directly, keeps
one in-subtree repeated case in blocking and one unrelated-branch collision in
awaitable, and adds an awaitable macro same-leaf storage case. The six unchanged
patches now score 23/25; that replay remains historical evidence because both
the prompt and test matrix changed.

The current 176-word version passed the artifact audit, both feature-only
checks, all twelve mutations, and all four patch states in pristine offline
local clones. Docker clients again hit the recorded host transport stall and
created no containers, so the equivalent local-clone gate was used. The
reference passes all 25 focused tests and the solution patch is unchanged.

## Acceptance and archive

The platform accepted this problem on 2026-07-26, as confirmed by the user.
Local and upstream similarity searches found no equivalent task; the
user-approved residual cross-repository risk remains recorded in `ERRORS.md`.

`RUNS.md` is the compact run index. Eight raw run collections, the three dirty
worktree recovery bundles, and retired authoring records are preserved under
`archive/statig-local-transitions/`. The 7.1 GB reproducible work namespace and
the 7.72 GB verification image were removed after archive and package
verification.
