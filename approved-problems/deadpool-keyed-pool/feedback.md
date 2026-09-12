# deadpool-keyed-pool -- tracking

## Task
Add a keyed managed pool to `deadpool-rs/deadpool` (Rust, MIT/Apache-2.0, ~1.2k stars). deadpool's
managed pool is a single semaphore-gated FIFO pool with no notion of keys (`grep keyed|by_key|HashMap`
in `managed/` returns nothing). The feature adds `KeyedPool`: per-key sub-pools that all draw from ONE
global `max_size`, with per-key limits, cross-key FIFO fairness, and - the core engineering surface -
**cross-key LRU eviction**: when the pool is globally full and the requested key has no idle object,
the least-recently-returned idle object of a *different* key is detached to make room. Plus the pool
operations deadpool's own `Pool` has: timeouts, `resize`, `close`, `clear_key`, `retain`, TTL
`reap_idle`, a builder, and status/introspection.

Tier: Olympus. Language: Rust. Base commit: 8feed310a6f69b4b51c4963604ea1bc5f5a586c3
(recency verified by `git log`: last commit 2026-07-13, well within 12 months).

## Why this is not a duplicate
Checked against all approved problems in `Olympus/approved-problems/feature-request/` and every
in-flight problem under `problems/`. No approved or in-flight problem touches connection/object
pooling, concurrency limiting, semaphores, or the deadpool repo (first use). The domain
(resource-pool lifecycle + concurrency correctness) is orthogonal to the interpreter/object-model,
glob/pattern-matching, SQL, geometry, units, and string-formatting families that dominate the corpus.
This was chosen specifically as an ENGINEERING-SURFACE feature (capacity coordination, fairness,
eviction, backpressure) rather than a syntax/feature-family addition, because the latter is what
kept colliding with the corpus (see attempt history).

Pre-flight dedup: GitHub issue/PR search for `repo:deadpool-rs/deadpool keyed` returns **0** results,
so the feature is not publicly solved.

## Effective LOC (measured before deliverables; impl only, tests excluded)
`.claude/hooks/effective_loc_check.py`: **human-effective 505 >= 430**, raw ~911, across 4 files:
- `managed/keyed/mod.rs` 696 raw / 411 eff (pool, slots, get + reuse/create/evict decision, resize,
  close, clear_key, retain, reap_idle, KeyedObject + Drop, status)
- `managed/keyed/config.rs` 159 raw / 73 eff (KeyedPoolConfig, KeyedPoolBuilder)
- `managed/keyed/manager.rs` 51 raw / 17 eff (KeyedManager trait)
- `managed/mod.rs` 5 raw / 4 eff (module + re-exports)
The distinct logic (dual-semaphore capacity coordination, LRU eviction across keys, permit
accounting across resize/take/clear/retain/reap, object lifecycle) is genuine and non-amortizable.

## Correctness review (I own this code - reviewed line by line)
The subtle part is permit accounting. `available_permits == max_size - in_flight` is the invariant.
- `get` acquires a per-key permit then the global permit (tokio's Semaphore is FIFO-fair, giving
  cross-key fairness); both are `forget()`-ed on success and returned on `Drop`.
- The async `create`/`recycle` never run while the `std::sync::Mutex` slots guard is held.
- `clear_key` / `retain` / `reap_idle` deliberately do **not** call `add_permits`: an idle object
  already returned its permit on `Drop`, so removing it only decrements `size`, leaving that permit
  to back "room to create" instead. Calling `add_permits` there would over-issue permits and could
  drive `get` into the evict branch with an empty LRU. Only `resize`-shrink forgets permits, because
  it simultaneously lowers the cap.
- The evict branch's `expect("no idle object to evict")` is safe: holding a global permit while
  observing `size == max_size` under the lock implies an idle object exists (if a concurrent
  `clear_key`/`retain` removed it, `size` dropped too, so the create branch is taken instead).

## Validation (offline, non-root uid 65534, real olympus-base-rust image)
- Environment quality: the VANILLA crate builds and its tests pass in the base image
  (rustc 1.95, edition 2024).
- 4-cell from a fresh `git archive BASE` context:
  - BASE + `new`  -> exit 1, 15/15 named per-test failures (the hidden suite references the
    not-yet-added `KeyedPool`, so cargo fails to compile it; test.sh synthesizes one named JUnit node
    per `#[tokio::test]` with the compiler error, preserving F2P granularity).
  - BASE + `base` -> exit 0 (crate lib tests + doctests; integration targets are not compiled in base
    mode, so the hidden suite is excluded).
  - SOL  + `new`  -> exit 0, 15 pass.
  - SOL  + `base` -> exit 0 (no regressions).

## Notes / gotchas
- deadpool has **no root workspace manifest**; each crate under `crates/` is standalone, so all
  build/test commands run in `crates/deadpool`.
- The crate is `edition = "2024"` (needs rustc >= 1.85). `olympus-base-rust` ships 1.95, so it builds;
  a plain `rust:1.83` image cannot even parse the manifest.
- `Runtime::Tokio1` is behind the `rt_tokio_1` feature, so the hidden suite (and the Dockerfile's
  dependency pre-fetch) use `--features rt_tokio_1`.
- `cargo test --lib --doc` is rejected by cargo ("can't mix --doc with other target selecting
  options") - run the two separately.
- Dockerfile pre-runs `cargo build`/`cargo test --no-run`/`cargo fetch` (with the feature) so the
  offline run has every dependency, and `chmod -R a+rwX /app /opt/cargo` so the non-root test user can
  write `target/`.
- Test filename `keyed_pool_behavior_matrix.rs` is distinctive (collision pre-check).

## Revision 1 (AI-check round: quality + necessary-info + alignment)
The necessary-information check (request_changes) wanted the meta TRIMMED while the alignment check
wanted API details ADDED. Fairness wins: in a statically-typed language a hidden test does not even
compile against the wrong signature, so an undocumented API a test depends on is a hidden
requirement. Resolution: documented the exact signatures the tests rely on and paid for the words by
cutting the genuinely redundant prose.
- Alignment (WARNING) - now documented in meta: `KeyedPoolConfig::new(max_size, max_per_key)`,
  `KeyedPool::manager`, `KeyedObject::id`, the full `KeyedManager` method signatures (including the
  `&Metrics` parameter and `RecycleResult` return), the `retain` predicate shape `(&Key, &Type,
  Metrics)`, and `keys()`.
- Necessary-information (HIGH + MEDIUMs) - removed the duplicated config fields
  ("timeouts, and max_idle_lifetime", already covered by the builder), "that derefs to the managed
  type", "so the total stays at the cap", and "Slots freed by any of these are reusable by any key".
  meta.md is now 422 words, ASCII-clean.
- Test coverage (WARNING) - added tests for every named gap, all of which were behaviors the meta
  ALREADY described but the suite did not assert: the eviction victim is the least-recently-returned
  idle object (`eviction_victim_follows_return_order` reverses the return order so the policy cannot
  pass by accident), a stale idle object is discarded on `get`, `max_per_key == 0` is unlimited,
  `status().keys`, and `timeout_get` overriding a configured (unbounded) wait. 15 -> 21 tests.

### No false positives (mutation-verified)
Added two capacity-invariant guards (`capacity_is_still_enforced_after_clear_key` /
`..._after_reap_idle`) that catch the subtlest bug in this feature - over-issuing permits when
removing idle objects - and then PROVED the suite discriminates by mutating the implementation:
- Injecting `semaphore.add_permits(n)` into `clear_key` (the classic mistake) makes
  `capacity_is_still_enforced_after_clear_key` fail, panicking in the evict branch exactly as
  predicted.
- Changing the eviction victim from `pop_front` (LRU) to `pop_back` makes BOTH eviction tests fail.
The implementation was restored afterwards and `solution.patch` is byte-identical to the shipped one;
21/21 pass and the 4-cell is green (BASE new -> 21 named failures; BASE base / SOL new / SOL base pass).

## Revision 2 (Solution Quality FAIL + Test Fairness FAIL + Dockerfile FAIL)

### Two REAL bugs found by Solution Quality (my own review missed them)
1. **`close()` did not unblock per-key waiters.** `get()` acquires the per-key semaphore BEFORE the
   global one, but `close()` only closed the global semaphore. A caller for a key that was at its
   `max_per_key` limit blocked on the per-key gate forever instead of getting `PoolError::Closed` -
   a direct contract violation. Fix: `close()` now closes every per-key semaphore (holding the
   per-key lock while closing the global one so a concurrently-registered key cannot be created
   open), and `per_key_semaphore()` creates an already-closed semaphore for a key first seen after
   close.
2. **`resize` grow over-issued permits.** A shrink cannot remove checked-out objects, so it can leave
   `size > max_size`. Growing then added `max_size - old_max_size` permits unconditionally, handing
   out capacity that surviving objects already occupy. That made the `expect("no idle object to
   evict")` a REACHABLE panic. Fix: `additional = max_size.saturating_sub(old_max_size.max(size))`.
   Separately, both `expect`s are gone: the evict branch now uses `KeyedSlots::evict_lru()` and falls
   back to a plain create when nothing is idle, so no panic path remains in library code.

### Test Fairness (3 unfair) - fixed by aligning with the repo, not by deleting tests
- `KeyedObject::id` returned `usize` while the sibling `Object::id` returns `ObjectId`. That was a
  genuine SIBLING-API DIVERGENCE (exactly the trap in `olympus-system-level-criterion`). Fixed the
  SOLUTION to return `ObjectId` (added a `pub(crate) ObjectId::new`), documented it in meta, and
  updated the tests. Now repo-consistent and prompt-stated.
- `keys()` pinned a sortable `Vec` without the meta saying so -> meta now states it returns a `Vec`.

### Dockerfile (ERROR)
Removed `cargo test --no-run` (compiling test binaries trips the "no test execution during build"
rubric - the same rule gpython hit). `cargo build --features rt_tokio_1` + `cargo fetch` alone are
enough: the 4-cell re-ran fully OFFLINE and green, proving the dev-dependency sources are cached.
Also added `cargo generate-lockfile` so the offline run uses a fixed lock (the repo commits none).

### Coverage added (all advisory suggestions addressed)
`close_returns_closed_even_for_a_saturated_key`, `resize_shrink_then_grow_does_not_over_issue_capacity`
(these two CATCH the bugs above), `cleanup_never_disturbs_checked_out_objects`,
`manager_callbacks_receive_the_right_key` (asserts the exact key handed to create/recycle/detach),
`create_timeout_expires`, `recycle_timeout_discards_the_idle_object`, plus
`object_ids_are_unique_and_increasing`, `close_detaches_idle_objects`,
`resize_shrink_keeps_checked_out_objects`. **21 -> 30 tests.**

### Mutation-verified (no false positives)
Reverting the `close()` fix makes `close_returns_closed_even_for_a_saturated_key` fail (it blocks for
5s until the test's timeout guard fires); reverting the `resize`-grow fix makes
`resize_shrink_then_grow_does_not_over_issue_capacity` fail. Earlier rounds also proved the
permit-accounting guard and the LRU-victim tests discriminate. Implementation restored after each
mutation.

Re-validated: 30/30 pass; LOC 520 eff (>= 430) across 5 files; solution still test-free; 4-cell green
offline/non-root (BASE new -> 30 named failures; BASE base / SOL new / SOL base pass); meta 449 words,
ASCII-clean.

## Revision 3 (quality ERROR + necessary-info request_changes)

### The "managed feature" ERROR was a FALSE POSITIVE (but fixed anyway)
The checker claimed test.sh's `--features rt_tokio_1` leaves the `#![cfg(feature = "managed")]`-gated
suite uncompiled. That is wrong: deadpool declares `default = ["managed", "unmanaged"]`, and cargo's
`--features` ADDS to the defaults (only `--no-default-features` would drop them). The 4-cell proves
it empirically - SOL/new ran and passed all tests, which is impossible if the file were cfg'd out.
Made it explicit anyway (`--features rt_tokio_1,managed`): harmless, and it removes the objection.

### necessary-information HIGH resolved WITHOUT creating a hidden requirement
The HIGH said to delete "`KeyedPool::manager` returns the manager" - but tests were using
`manager()`, so deleting the doc alone would have made it an undocumented API a test depends on (a
hidden requirement, and in Rust a non-compiling one). Satisfied BOTH checks instead: removed
`manager()` from the meta AND from the tests. The recording manager now writes into a shared
`Arc<Mutex<Vec<..>>>` the test also holds, and every other `manager()` assertion was redundant with a
public-state assertion already present (e.g. "exactly one victim evicted" is already pinned by the
`key_size` assertions; reuse is already pinned by `ObjectId` equality). `manager()` stays in the
solution for parity with the sibling `Pool::manager()`. Also applied the MEDIUM/LOW trims, but KEPT
the `Timeouts` type/field naming, because the alignment check explicitly requires it (fairness wins
over brevity). meta.md now 431 words.

### Coverage (advisory) addressed
- `timeout_get_overrides_the_create_timeout` - the override applies to more than `wait`.
- The exported types are now named explicitly in the suite (`KeyedStatus`, `KeyedKeyStatus`,
  `KeyedRetainResult` type annotations), validating the export names.
**30 -> 31 tests**, all passing. LOC 520 eff (>= 430). 4-cell green offline/non-root (BASE new -> 31
named failures; BASE base / SOL new / SOL base pass).

## Revision 4 (Environment Quality FAIL + alignment WARNING + coverage)

### Environment Quality FAIL - REAL, and the most important gotcha for this repo
The gate runs the obvious command from `/app`: `cargo build` then `cargo test`. Both failed with
"could not find `Cargo.toml` in `/app`" because **deadpool ships standalone crates and has NO ROOT
WORKSPACE MANIFEST** (the repo's own `test-build.sh` fails the same way). Everything only works from
`crates/deadpool`. Fix: the Dockerfile now writes a root `Cargo.toml` with
`members = ["crates/deadpool", "crates/deadpool-runtime"]` and EXCLUDES the other crates (they pull
database drivers needing network + system libs, which would themselves fail the gate). Verified by
replaying the gate exactly - vanilla repo, offline, from `/app`: `cargo build` -> Finished,
`cargo test` -> all suites ok. Also switched the feature pre-build to `-p deadpool --features
rt_tokio_1` (a virtual workspace root rejects bare `--features`).

### Alignment WARNING - the description genuinely contradicted the tests
meta said "The total number of objects never exceeds `max_size`", but `resize`-shrink cannot remove
checked-out objects, so it CAN leave `size > max_size` - and `resize_shrink_keeps_checked_out_objects`
asserts exactly that. Rewrote the `resize` sentence to state the exception explicitly (the total may
stay above the new cap until in-flight objects are returned, and no further object is handed out while
it is). Paid for the words with the suggested RAII trim. meta.md now 439 words.

### Coverage
Added `timeout_get_overrides_the_recycle_timeout` (the per-call override applies to `recycle`, not
just `wait`/`create`). **31 -> 32 tests.**

Re-validated: 32/32 pass; 4-cell green offline/non-root on the new image (BASE new -> 32 named
failures; BASE base / SOL new / SOL base pass); env-quality replay green.

## Revision 5 (alignment WARNING - interface details the tests depend on)
Documented three signature details the hidden tests rely on (in Rust these do not merely mislead -
the test does not COMPILE against a different shape, so each was a hidden requirement):
- `get(key: Key)` takes the key BY VALUE, while `key_size(&key)`, `key_status(&key)` and
  `clear_key(&key)` take it BY REFERENCE (the tests call `get("k")` but `key_size(&"k")`).
- `KeyedManager::detach` has a DEFAULT NO-OP body (one test manager omits it entirely).
- `KeyedObject` DEREFS to `Type` (tests assert on `*obj`). Note: the deref mention had been deleted
  in an earlier round on a necessary-information MEDIUM - fairness outranks brevity, so it is back.
Paid for the words by dropping the `Timeouts` field enumeration: the signature already names the
type, and `wait`/`create`/`recycle` are fields of the PRE-EXISTING `Timeouts` type (repo-discoverable),
so nothing the tests need is left unstated. Verified each documented signature against the solution.
meta.md now 437 words, ASCII-clean. Solution and tests UNCHANGED this round.

## Revision 6 (Dockerfile: lockfile warning - now the only non-OK item, and non-blocking)
Upstream deadpool commits NO `Cargo.lock` (normal for a library), and the build context is only the
repo at BASE plus the Dockerfile, so a lockfile cannot be injected - and adding one to
`solution.patch` would be wrong (that patch is the feature). Made it as deterministic as the repo
allows: the lock is resolved ONCE in the image and then treated as authoritative -
`cargo build --locked`, `cargo build --locked -p deadpool --features rt_tokio_1`, `cargo fetch
--locked` - so it can never silently drift during the build, and the baked-in `Cargo.lock` (36 KB)
plus `CARGO_NET_OFFLINE=true` make the image resolve identical versions for its whole lifetime. The
residual warning (reproducibility across image REBUILDS) is inherent to a repo that ships no
lockfile and is not fixable from the Dockerfile. Every other Dockerfile criterion is OK.
Re-verified: env-quality replay green (`cargo build` Finished, 14 test suites ok, vanilla, offline,
from /app) and the 4-cell green (BASE new -> 32 named failures; BASE base / SOL new / SOL base pass).

## Revision 7 (coverage WARNING - the last uncovered clause; no blockers)
The meta says a shrink may leave the pool above the new cap and that "no further object is handed out
while it is", but nothing asserted that directly. Added
`nothing_is_handed_out_while_over_capacity_after_a_shrink`: three checked-out objects, `resize(1)`
removes nothing (no idle), the pool stays at size 3, and a `get` stays PENDING; each returned object
is discarded rather than idled (size 3 -> 2 -> 1) and the waiter is still not served until the last
object comes back and the pool is within the cap.
Mutation-verified (no false positive): adding `semaphore.add_permits(1)` to the over-cap discard path
in `Drop` makes ONLY this test fail. Implementation restored byte-identical (`solution.patch`
unchanged). **32 -> 33 tests**, all passing; 4-cell green (BASE new -> 33 named failures; BASE base /
SOL new / SOL base pass).

## Attempt history (this authoring session)
- gpython string-format -> DERIVATIVE. gpython super/MRO/PEP487 -> DERIVATIVE.
- convert-units dimensional analysis (TS, pint oracle, fully built) -> RECENCY FAIL (last commit
  2025-07-07; I had wrongly trusted the API's `pushed_at`). Preserved under problems/.
- doublestar extended-glob (Go, 502 eff, fully validated) -> plagiarism flip-flopped between
  `similar_idea` (passed) and `derivative`; extglob AND brace-expansion both have corpus prior art.
  Preserved under problems/doublestar-extended-glob/.
- gocron misfire recovery (Go, fully built + regression-green) -> only **90 eff LOC**: gocron's
  generic `next()` collapses per-schedule enumeration to one method, so the idiomatic implementation
  is far under the floor. Preserved under problems/gocron-misfire-recovery/.
- deadpool keyed pool (this submission): chosen for LOC-DENSITY verified up front (the irreducible
  concurrency logic is genuinely 400+), a niche engineering surface, and git-verified recency.

## Revision 8 (eval de-trap: undocumented constructor signature was compile-wiping every run)
Two eval runs (Nova solver / Nova eval) both came back `FAIL_INTEGRATION_ERROR` with 33/33 hidden
tests failing to COMPILE - not one behavioral assertion was ever reached, so both runs carry zero
difficulty signal and the solvability floor was at risk. Both agents independently made the same two
guesses: `KeyedPool::new -> Result<Self, BuildError>` (the hidden tests call `.get()` on the value)
and, in run 2, an extra object-wrapper generic on `KeyedPool`/`KeyedPoolBuilder` that Rust cannot
infer at `builder(mgr)` call sites. Both guesses were reasonable: the meta pinned only that `build`
fails without a runtime, and deadpool's own `Pool<M, W = Object<M>>` HAS a wrapper generic and NO
`new`, so the sibling convention actively misled them. That is a hidden requirement on my side and a
textbook deterministic universal miss.

Fix (meta-only; solution.patch and test.patch untouched, `new`/`builder`/`build` in the reference
already had these exact signatures): pinned the constructor shapes explicitly - `new` returns
`KeyedPool<M>` directly and cannot fail, `builder` returns `KeyedPoolBuilder<M>` whose `build`
returns `Result<KeyedPool<M>, BuildError>`, and neither type takes an object-wrapper generic. Paid
for the ~18 added words by trimming two redundant phrases; meta is 445/450 words, ASCII-clean.
Symmetry re-checked in both directions: the new clause describes only API shape the hidden tests
already exercise (no new behavior described, none untested). Reference solution re-run: 33/33 green,
`solution.patch` byte-identical.

## Revision 9 (HARDENING: the 10-run eval proved the task was too easy, not too hard)
The full 10-run eval read: 3 PASS_LEGITIMATE, 7 FAIL_INTEGRATION_ERROR - and all 7 fails had the SAME
cause, the undocumented `KeyedPool::new` return type (3 also added a wrapper generic). ZERO behavioral
failures. So of the agents that got the signature right, 3 of 3 passed all 33 tests: the concurrency
core was cleared by every agent that reached it. The headline 30% rate was measuring a coin flip on an
API signature, not engineering difficulty - textbook fake difficulty (`olympus-fake-difficulty-unfair-
errorclass`). Keeping the ambiguity = Test Fairness hard reject (a hidden requirement: an exact
signature the visible `Pool<M, W = Object<M>>` convention contradicts). Removing it = pass rate heads
to ~10/10. The task as it stood was not shippable either way.

Fix: keep the signature de-trap AND add a genuinely orthogonal engineering surface - **cancellation
safety of `get`**. Found by probing my own reference: `timeout_get` reserved the slot
(`slots.inc_counts`) and then awaited `create`/`recycle`, with cleanup only on the `Err` path
(`inspect_err`). Dropping the future mid-create leaked the reservation permanently; after 3 cancels on
a `max_size=2` pool `status().size` was **3** - the accounting drifts PAST the cap forever. Fixed with
the repo's own `managed::dropguard::DropGuard` idiom (already used by `pool.rs`): the reservation is
guarded and disarmed only once a usable object is in hand, so cancel, error, and stale/failed-recycle
paths all unwind identically.

Why this is the right surface: it is an engineering surface, not another documented spec bullet; it
intersects EVERY existing path (wait, create, recycle, evict, per-key); and it is the exact trap a
competent agent falls into - I fell into it myself, and the naive form passes the old suite perfectly.
**Mutation-verified**: restoring the naive `inspect_err` implementation passes all 33 original tests
and fails 4 of the 6 new ones (`cancelling_a_get_while_it_creates_gives_the_slot_back`,
`...while_it_recycles...`, `cancelling_a_get_frees_the_per_key_slot_too`,
`repeated_cancellation_never_erodes_the_capacity`). That is direct evidence the 3 agents who passed
would now fail. The other 2 new tests cover the cancel-while-waiting path (no reservation held, so
they pass naive too) - kept as coverage, not claimed as discriminators.

Deliverable state: 33 -> **39 tests** (no test function renamed or deleted - the F2P set only grew).
meta.md documents cancellation in one clause and is at **450/450** words, ASCII-clean (paid for by
compressing redundant phrasing; no described behavior dropped). solution.patch = **520 effective LOC**,
5 files, no tests. 4-cell green from a fresh BASE export, non-root + offline: BASE/new -> exit 1 with
39 named failing nodes and real compiler errors; BASE/base, SOL/new (39/39), SOL/base all pass.
