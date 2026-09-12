# Levels — kapture dependency-closed dataset subset

## Level 8 — ownership-aware forced replacement

Status: `accepted by the platform and archived 2026-08-19; immutable v8`.

All five fresh v7 solvers passed, exposing difficulty convergence. Four treated
a standard record root or feature collection as wholly owned during successful
force replacement; the v7 reference made the same mistake. V8 states a precise
path-level rule: retire old kapture metadata and payloads absent from the new
dataset, but preserve unrelated files at every nesting depth unless the new
dataset claims their exact path. Empty directories remain unconstrained.

The pre-change compatibility forecast was 1/5 and exact replay observed 1/5.
Runs 1–4 pass 12/13 and fail only nested unrelated preservation; run 5 passes
13/13; all five pass 181 base tests with five skips. Both complete v8
architectures pass 181/five plus 13/13, and all 39 mutants are killed after
closing one force-enabled normalized-alias survivor.

The fresh expectation is **2–4 successful solvers out of 10**. This is a fresh
exact-version forecast; calibration remains 0/10.

## Level 7 — reverse image seeds and transactional materialization

Status: `immutable v7 verified; ready for fresh calibration; 0/10 run`.

Trajectory review showed that all seven v6-compatible solvers used the same
forward, record-first data flow and eagerly created or erased destination data
before retained payload reads completed. V7 adds two public boundaries: camera
paths can reverse-select the timestamps eligible in all record families, and
directory materialization must commit transactionally while preserving
unrelated destination files.

The pre-change historical compatibility forecast was 0/10; replay observed
0/10, while all ten patches still pass 181 base tests with five skips. Both
complete v7 architectures pass the same base lane and 13/13 focused nodes. The
first mutation draft exposed one camera-local image-filter survivor; the final
single-image/no-bound assertion kills it. All 37 final mutants are killed, and
the exact environment, gap, fairness, and false-positive gates pass.

The fresh expectation is **2–5 successful solvers out of 10**, down from v6's
**5–8/10**. This is a fresh-calibration forecast; no v7 solver run exists, so
calibration remains 0/10.

## Level 6 — calibration mismatch repair and installed-distribution closure

Status: `immutable v6 verified; not submission-ready; fresh calibration 0/10`.

The first ten-solver batch passed all 181 baseline tests in every run, but the
evaluator reported no successful solution: each patch reached 9/11 or 10/11
focused nodes. Runs 3 and 8 were explicitly adjudicated as test mismatches.
Both removed every forbidden match pair but preserved a named empty `Matches`
bucket, which is allowed by the prompt's `None`/empty rule and represented in
the repository's own tar tests. The direct-force node also compared returned
and reopened models with strict `equal_kapture`, making it sensitive to public
writer normalization of empty containers. Those two predicates now check
actual match pairs, returned public type/selected content, and reopenability.

The mismatch-only compatibility forecast was 9/10 and replay observed exactly
9/10: only run 6 still violated the explicit sibling-sensor closure rule. A
separate installation probe then showed that the reference and runs 3 and 5
declared the console script but omitted `kapture.algo.subset` from their wheels.
After correcting both reference architectures and adding isolated installed
command execution, the refined compatibility forecast was 7/10 and the final
replay again observed exactly 7/10. Runs 3 and 5 fail only installation; run 6
fails only dependency closure; runs 1, 2, 4, 7, 8, 9, and 10 pass 11/11.

Exact Phase B accepts the corrected reconstruction reference, independent
deep-copy/prune architecture, and run 8 at 181 passed/five skipped plus 11/11.
All 31 repository-grounded mutants are killed. Exact gap and fairness audits
pass. The initial fresh expectation was 6–9/10 after mismatch repair and was
refined to **5–8 successful solvers out of 10** after installation hardening.
That remains outside the accepted difficulty band, so this revision is a fair
correctness repair, not successful calibration. Because submission artifacts
changed, none of the historical runs count toward immutable v6: fresh
calibration is 0/10.

## Level 5 — full-copy correction and direct force lifecycle

Status: `immutable v5 verified; fresh calibration 0/10`.

S1 review exposed a reference defect: a no-filter call still ran dependency
pruning, so a defined but unused sensor disappeared instead of being included
in the promised full copy. Both complete architectures now preserve the entire
source model through a detached full-copy branch. The focused oracle adds a
recordless sensor, checks public model equality, and verifies ownership.

T4 review exposed a distinct public entry surface: CLI forced replacement did
not prove that direct `subset_kapture_from_dir(..., force=True)` replacement
worked. The output-lifecycle node now invokes the library API directly, checks
the returned `Kapture`, reopens the replacement, and distinguishes the new
selection from the pre-existing output.

An initial mutation pass showed that the no-filter fast path could mask the
existing sparse-family and shallow-copy mutants. The final verifier exercises
absent families with a real timestamp filter and mutates nested values in a
filtered result. After restarting every exact-version gate, both architectures
pass 181 base tests with five skips and all 11 focused nodes; all 30 mutants are
killed. The compatibility forecast was 2/2 and the observed replay is 2/2. The
fresh-calibration expectation remains **1–4 successful solvers out of 10**, but
no v5 solver run exists, so calibration is 0/10.

## Level 4 — Lyra fairness and false-positive revision

Status: `immutable v4 verified; fresh calibration 0/10`.

Lyra demonstrated nine public-behavior shortcuts that passed immutable v3's
6/6 focused suite and the 181-pass/five-skip base suite: absent-family crashes,
shallow nested copies, record-key sensor validation, rig-ID acceptance,
occurrence-based duplicate-image pruning, raw same-path comparison,
unconditional output replacement, a missing declared callable, and long-only
path options. Five black-box tests now reject those families.

One Lyra assertion was removed as unfair: discarded/unreferenced payloads need
not be physically absent because the public task does not require a minimal
output tree. The no-force test is likewise implementation-neutral about return
versus exception and checks only preservation of observably distinct existing
data.

The pre-change compatibility forecast was 2/2 because both materially
different complete implementations already satisfied all nine public edge
behaviors. The observed immutable-v4 replay is exactly 2/2: each architecture
passes 181 base tests with five skips and all 11 focused nodes. The complete
28-mutant audit has zero survivors; mutants 20–28 are each isolated to one
intended new node.

The fresh-calibration expectation is **1–4 successful solvers out of 10**, down
from v3's **2–5** because the revision closes nine demonstrated shortcuts
without adding private implementation constraints. This is a fresh-calibration
forecast, not a compatibility estimate. No solver run belongs to v4, so the
batch remains 0/10 and must start from zero.

## Level 3 — executable harness and saved-return coverage

Status: `immutable v3 verified; fresh calibration 0/10`.

The level includes inclusive timestamp/sensor selection across every record
family, transitive nested-rig and trajectory closure, all retained-image feature
families, endpoint-safe matches, source-order point/observation compaction,
mixed directory/tar payload transfer, round-trip reopening, and source/result
isolation.

Two complete reference-shaped implementations measure 250 and 264 strict
production additions across three files. That is low-confidence scope evidence,
not a successful-solver median. Before any run, the initial fresh-calibration
forecast is **2–5 successful solvers out of 10**: the public API is direct, but
correctness crosses nine record branches, nested graph closure, four payload
producer families, and reconstruction index remapping. This forecast is not a
compatibility replay because no kapture solver trajectory exists.

Immutable v2 left the behavioral task and hidden suite unchanged. It made
the tested PEP 621 entry-point mapping, callable name, and module execution
surface explicit, stated the repository-root pytest command, conditionally
handles the packaging README, pins the resolved dependency closure, and uses an
editable local install.

Immutable v3 removes redundant non-mutation prose and the operational test
paragraph, creates `test.sh` with executable mode `100755`, and strengthens an
existing saved-dataset node to compare the API's returned `Kapture` model with
the reopened output. A dedicated disk-correct/return-`None` mutant is killed
only by that assertion.

Before this repair, both complete legitimate architectures passed 181 base
tests plus all six focused nodes. The compatibility-replay forecast was 2/2;
the observed immutable-v3 result is 2/2. The fresh-calibration expectation
remains **2–5 successful solvers out of 10**, but no solver run belongs to v3,
so fresh calibration remains 0/10. Exact environment, gap, fairness, and
false-positive gates pass, and all 19 mutants are killed.

Do not harden by adding archive atomicity, arbitrary corrupt arrays, byte/order
identity, geometry mutation, converter behavior, or private path rules. Any
artifact revision creates a new immutable level, repeats every exact gate, and
resets calibration to 0/10.
