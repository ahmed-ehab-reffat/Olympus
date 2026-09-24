# REPO-HUNT 2026-09-21-B

Unattended `olympus-factory` hunt worker (hunter #11). `CONSECUTIVE_MISSES=0`, so the softening
threshold (n >= 2) was NOT reached and the standard 2026-09-09-B gates were applied unrelaxed. No
star window, issue window or activity window was widened; no relaxation was taken. The AI-marker
root probe was kept as a HARD KILL, per the orchestrator's instruction, because the human has not
ruled on it. Scratch: `worktrees/_hunt/q_0921h11/`.

**RESULT: CANDIDATE — `Stremio/stremio-core` (Rust 99.8%, MIT, 2411 stars).** The lane rests on a
struct the repo parses and then throws away, plus three latent kernel bugs that no current caller can
reach. All four were verified by me, in this session, by reading the source at `b3062f7f`; the
baseline determinism was measured by me with a real `cargo test` run.

---

## Budget spent

| Stage | Spend | Outcome |
|---|---|---|
| Stage 0-bis proven pool | ~2 min, mechanical | EXHAUSTED for the **7th** consecutive session |
| Residual triage: `p_0921/live.tsv` minus the ~350 rows hunt #10's agents screened | ~5 min | **291** gate-cleared rows, split by language |
| Four screening agents over that residual (C++/Java, Go/Rust, Python, JS/TS) | ~50 min | **2 survivors** (piscsi, stremio-core), ~20 near-misses with named gates |
| One fresh sweep (two un-mined bands, see below) | ~22 min, 1 script, background | 6,588 rows -> 3,506 -> 773 engine-shaped |
| GraphQL pre-gate + rank over those 773 | ~8 min | **201 live**, a brand-new pool for hunt #12 |
| Two more screening agents over the fresh pool | ~50 min | 3 further survivors — `vermin` (RANK 3), then `u-root` and `gauge`, which arrived after the result block had been handed back and are recorded below as RANK 4 and RANK 5 with the ranking re-argued |
| My own verification of the RANK 1 (source read + 3x suite run + exclusivity + PR archaeology) | ~25 min | 4 traps confirmed, 282+18 tests deterministic 3x |

`D_pick.tsv` (the 25 hand-picked rows hunt #10 left) turned out to be **fully consumed** — every row
already carries a named kill in hunt #10's log or is its own RANK 3/4. Budget it at zero from now on.

---

## Stage 0-bis — proven-repo pool (EXHAUSTED, 7th session)

The mechanical pool diff returns 60 repos at <=2 subs. Every single one is our own shipped work, our
own in-flight work, or an older kill whose reason has not changed. Nothing un-mined. This stage has
now produced zero leads in seven consecutive sessions; it stays at zero budget until an approval adds
a genuinely new repo to the pool.

---

## Where the ground was, part 1: hunt #10's own residual

`p_0921/live.tsv` holds 382 repos that already cleared a batched GraphQL pre-gate (permissive SPDX
licence, in-scope primary language, a `.github/workflows` dir exists, >=5 default-branch commits in
90 days, >=3 merged PRs in 90 days, PR-queue ratio, and the AI-marker root probe). Subtracting the
four slices hunt #10's agents actually screened leaves **291 rows**. Those became slices
`S_cppjava.tsv` (81), `S_gorust.tsv` (83), `S_py.tsv` (71), `S_jsts.tsv` (56).

Result: **2 survivors out of 291.** The composition census is worth recording because it is the
reason:

| Slice | Dominant kill classes |
|---|---|
| C++/Java (81) | game/graphics/rendering engines + Godot/UE modules (10), ROS/Gazebo/robot sims (9), needs a real DB/broker/cluster/browser/network at test time (20), famous spec or household-name domain (9), ESP32/Pi hardware (8), GPU/ML runtimes (5) |
| Go/Rust (83) | cloud-native infrastructure — k8s operators, object-storage gateways, service meshes, databases (28), faithful named-spec/RFC protocol implementations (12), Gate-5 kernel/GPU/cgo/`-sys` (19) |
| Python (71) | burned classes before any API call (30), test path needs system libs / a live server / an external app / conda / ffmpeg / a GPU (21), network or cloud API at test time (8) |
| JS/TS (56) | named-spec implementation (13), self-hosted web app or data-only repo (12), real browser or GL at test time (8), sibling-package hollowing (5) |

---

## Where the ground was, part 2: the fresh sweep — TWO never-fetched bands

Hunt #10's carry-forward said the productive axis is `language x creation-year x size`, and it is.
Both sweeps that exist in this workspace share two accidental boundaries nobody had ever crossed:

1. **`size:>4000`** (i.e. >4 MB of repo). Hunter #4's `yrsweep` used `size:>5000`; hunt #10's
   `cjsweep` used `size:>4000`. **No sweep has ever fetched repos in the 1-4 MB band**, which is
   where a large fraction of focused single-purpose engines live.
2. **`stars:500..3000`** for Go / Rust / Python / TypeScript. Hunter #4's sweep capped at 3000;
   hunt #10 only widened to 6000 for C++ / Java / JavaScript. **The 3000-6000 band for the other
   four languages had never been fetched.**

`q_0921h11/sweep11.sh` closes both holes: S1 = `size:1000..4000 stars:500..3000` for all seven
languages x 14 creation years; S2 = `size:>4000 stars:3000..6000` for Go/Rust/Python/TypeScript x 14
years. 6,588 rows in ~22 minutes on one background script.

Triage: 3,506 survive an 11,960-slug dead list + permissive licence + in-scope language + AI/list
noise; **773 survive the engine-shape filter** (Python 253, TS 161, Go 94, Rust 92, JS 82, C++ 55,
Java 36). The GraphQL pre-gate then ran over all 773:

| Gate | Killed |
|---|---|
| Dormant: < 5 commits on the default branch in 90 days | 454 |
| No `.github/workflows` directory at all | 226 |
| **AI-authored-plan marker at repo root** | **152** |
| < 3 merged PRs in 90 days | 75 |
| Dormant with a filling PR queue | 25 |
| **LIVE** | **201** |

⭐ **AI-marker rate datapoint for the pending user decision.** Hunt #10 measured **23%** of the
500-6000-star, >4 MB mid-band carrying an agent-instruction file at the root. In THIS band (1-4 MB,
500-3000 stars, plus the 3000-6000 tail) the rate is **12.2%** (152 of 1,246 gated). So the marker
correlates with repo SIZE and RECENCY, not with quality per se. It did **not** starve this pool — two
survivors came out of a 291-row residual and the fresh pool still holds 201 unscreened rows — so
keeping it as a hard kill cost this hunt nothing measurable. The kill counts are recorded here so the
human can rule on it with two independent measurements rather than one.

---

## ⭐ Three method findings the screeners paid for

**Finding 1 — `merged-PRs-90d >= 3` is BROKEN in the npm ecosystem, and weak everywhere.**
Hunt #10 replaced `pushed_at` with merged-PR counts. That is better, but in the JS/TS mid-band the
merged PRs are almost entirely dependabot/renovate/kodiakhq. Measured author histograms over 90 days
on the default branch: `macbre/analyze-css` m90=30, c90=133, **zero human code commits**;
`Belphemur/node-json-db` m90=13, one README typo; `microsoft/vscode-textmate` m90=6, all dependabot,
last real code commit 2026-06-13; `prettier-plugin-solidity` 82 dependabot vs 8 human;
`pubkey/broadcast-channel` renovate for 12 months except one commit.

> **The rule that works: `human-authored default-branch commits in 90d >= 5`, excluding `*[bot]`,
> `renovate`, `dependabot`, `kodiakhq`, `github-actions`.** It is one extra field in `gate.py`'s
> commit query and it would have killed 5 of 6 deep-dive heads in the JS/TS slice before any API
> spend. **Add it to `gate.py` before the next hunt.**

**Finding 2 — the root-manifest AI probe misses an in-lane agent sweep.** `pubkey/broadcast-channel`
has a clean root, yet its ONLY real code commit in six months is
`fix: prevent dead elector from becoming leader or posting after die() (#1416)`,
`Co-authored-by: copilot-swe-agent[bot]` — and that commit fixes four `isDead` guards across
`LeaderElection` + `LeaderElectionWebLock`, makes `die()` idempotent in both, and adds a regression
test. That is the repo's entire authorable kernel, swept. Same class on `CppMicroServices` (recent
merges carry `Co-Authored-By: Claude Opus 4.6` closing `any_value_to_json`/`AnyMap` gaps).
**Extend the probe to the 90-day commit-message stream**, grepping for
`Co-authored-by: copilot|Co-Authored-By: Claude|codex/|Checkpoint before|swe-agent`. The root file is
the cheap half of the signal; the commit bodies are the decisive half.

**Finding 3 — for Python, read the SCRIPT the workflow CALLS, not the `.yml`.** Requirement 7 killed
only 2 of 71 Python rows; **Gate 5 killed 21**. `CERT-Polska/Artemis`, `mosaico`, `Slurm-web` and
`KivyMD` each have a green, correctly-named test job whose first step is a `docker compose up` of
live service containers or an `apt-get` of C headers. Reading only the `.yml` passes all four.
Two related probe extensions: a `proposals/`, `heps/` or `rfcs/` directory is the maintainer's
numbered-plan kill in disguise (`argoproj-labs/hera` has accepted HEPs 0001 and 0002 claiming two of
its three plausible lanes), and a lowercase `skills/` directory is an agent-tooling marker the
current regex misses (`awslabs/automated-security-helper`).

---

## RANK 1 — Stremio/stremio-core — ★2411 — MIT — Rust 99.8%

- **URL / stars:** https://github.com/Stremio/stremio-core — ★2411 (well under the 5000 penalty band)
- **Language:** `Rust 1,660,590 / JavaScript 2,864 / Shell 424` = **Rust 99.8%**. Pure Rust. Zero
  `-sys` crates in `[dependencies]` or `[dev-dependencies]` (dev = tokio, serde_test, assert_matches,
  pretty_assertions, tokio-current-thread). No system libs, no codegen, no build script needing a
  compiler.
- **Domain:** the state-machine core of a media client — addon protocol, catalog/meta/stream resource
  loading, library and notification models, over a hand-rolled `Effects`/`Env` reactive runtime.
- **Licence:** **MIT**, verified by reading `LICENSE.md:1-4` ("The MIT License (MIT) … Copyright ©
  2019 SmartCode OOD"). Recursive scan for `GNU General Public` / `LGPL` / `NCSA` over the whole
  tree: zero hits. No vendored or `external/` directory at all.
- **Default branch:** `development`. **Proposed base commit:** `b3062f7f` (2026-09-20). Archived:
  false. All five newest forks are ★0, so this is unambiguously where development happens.
- **Open issues:** 68 total, **60 without a linked PR**. Open PRs: 13.
- **Root-manifest AI probe:** CLEAN at HEAD — root is `.cargo Cargo.lock Cargo.toml clippy.toml
  CONTRIBUTING.md .github .gitignore LICENSE.md README.md rustfmt.toml src stremio-core-web
  stremio-derive stremio-watched-bitfield`. See the honest-risk section for the 2026-07 planning-doc
  commit that was added and then removed.
- **Dedup / saturation:** no hit for `stremio` in `SATURATED-REPOS.md`, `TOO-EASY.md`, `CLAUDE.md`,
  `approved-problems/`, `problems/`, `rejected/` or `diamond-problems/`. **Quota 0 of 6.**

### Requirement 7 (the workflow FILE was opened, not a run histogram)

- **File:** `.github/workflows/build.yml`, `name: Build`, job `build-core`
  ("stremio-core-*: Lint, test and build"). **Quoted suite step:** `- name: Test` / `run: cargo test`.
- **Matching successful rows on the default branch `development`:** `Build success 2026-09-20` at
  `db5a3578`, `1d2f7bf6`, `2acac637`; `success 2026-09-18` at `09061282`.
- ⚠️ At HEAD (`b3062f7f`) the overall Build row reads `failure`. **Drilling into that run's JOBS**
  (the hunt #10 correction, applied): `success  stremio-core-*: Lint, test and build` /
  `failure  stremio-core-web: test (wasm) and build`. **The native test job is green; only the
  chromedriver/wasm-pack job is red**, and that job is not in the Olympus test path. A base commit
  must still be chosen on a run whose `build-core` job is green.
- **The suite CAN go red.** Rust's built-in harness plus `pretty_assertions`, `assert_matches`,
  `serde_test`. Cited assertions: `src/unit_tests/catalog_with_filters/load_action.rs:223`
  `assert_eq!(states[1].discover.selected, Some(selected));` and `:124`
  `assert_eq!(requests.len(), 1);`.
- **Deps pinned:** `Cargo.lock` is committed. The single git dependency is rev-pinned in the lock:
  `localsearch` -> `git+https://github.com/Stremio/local-search?branch=main#74fefe1da2fa17d2b4ef7e3e629da00f3946ee72`.

### Baseline determinism (Gate 9) — MEASURED BY ME, not estimated

`cargo test -p stremio-core --lib` at `b3062f7f`, three consecutive runs:
**282 passed / 0 failed, identical all three times, 0.12-0.13s.** Plus **18 doc-tests passed** in
5.62s. `target/` measured **1.4G** and was deleted immediately after the measurement; `/` returned to
15G free.

⭐ **The harness is close to ideal for this specific lane.** `src/unit_tests/env.rs` is a fully
mocked `TestEnv`: a `FETCH_HANDLER` hook (no network), `STORAGE` as an in-memory map, an `ENV_MUTEX`
serialising tests, and — decisively — **a settable clock**:
`pub static NOW: Lazy<RwLock<DateTime<Utc>>>` with `fn now() -> DateTime<Utc> { *NOW.read().unwrap() }`.
A TTL / freshness feature normally collides head-on with the mandatory flakiness gate; here the
elapsed time is a variable the test writes. Very few repos offer this.

- **JUnit:** `cargo2junit` is already installed in this workspace's `CARGO_HOME/bin`. Standard Rust
  Pattern A wiring, no adapter work owed.
- **Docker:** Pattern A, `olympus-base-rust`. `cargo fetch --locked` at build time (network is
  available during `docker build`) pulls both crates.io and the rev-pinned git dep into `CARGO_HOME`;
  then `ENV CARGO_NET_OFFLINE=true` for the test run, exactly as
  `approved-problems/calamine-defined-names/Dockerfile` does. Remember the
  `chmod -R a+rwX /opt/cargo /app` step and NOT to chmod `/opt/rustup` (memory: rustup chmod stalls).

### Dormancy / liveness

**>=100 commits on `development` in 90 days; 38 merged PRs in 90d, 87 in 12mo; 13 open PRs.**
Passes `merged-90d >= 3` and `open < 2x merged-90d` (13 < 76) with an enormous margin, and is the
opposite of the dormant-with-a-filling-queue magnet.

### Exclusivity — every open PR's file list enumerated

| PR | Core files touched |
|---|---|
| #1064 | `models/player.rs`, new `models/skip_segments.rs`, `types/skip_segments.rs` |
| #1048 | `addon_transport/*.rs`, `models/addon_details.rs`, `models/common/descriptor_loadable.rs`, `runtime/env.rs` |
| #1045 | `types/resource/subtitles.rs` |
| #1034 | `models/player.rs`, `types/api/request.rs` |
| #1006 | `models/player.rs` |
| #954 (draft) | `models/ctx/update_profile.rs` |
| #877 | `models/streaming_server.rs`, `runtime/runtime.rs` |
| #853 (draft) | `types/api/response.rs` |
| #821 | `models/ctx/ctx.rs`, `models/ctx/update_profile.rs`, new `runtime/msg/action_user_profiles.rs` |
| #785 | `models/ctx/update_library.rs` |
| #775 (draft) | `types/addon/response.rs`, `types/resource/stream.rs` |
| #641 | `addon_transport/http_transport/http_transport.rs`, `types/addon/response.rs`, `types/resource/stream.rs` |

**`src/models/common/resource_loadable.rs` — the lane's kernel — is touched by ZERO open PRs.**

**Lane coldness inside a very live repo (verified by me via the commits API, path-filtered):**

- `src/models/common/resource_loadable.rs`: last SEMANTIC change **2023-07-31**; everything since is
  `chore: bump derive_more` (2025-02-26) and `fix: clippy warnings` (2024-05-02). Nothing in 12 months.
- `src/addon_transport/addon_transport.rs` (the trait the lane re-shapes): last touched
  **2021-01-14** (`TryEnvFuture introduced`). Five years cold.

**Tracker + PR sweep on the lane's nouns, ALL states** (run by me):
`cacheMaxAge`, `cache_max_age`, `staleRevalidate`, `stale-while-revalidate`, `revalidate`, `ttl`,
`freshness`, `ResourceResponseCache` -> **zero hits** in issues and PRs. A generic `cache` search
returns only streaming-server *disk cache folder* work (#982, #1047) and closed user issues #761
("Cache upcoming episodes" — prefetching video) and #758 ("Caching on http streaming" — video
buffering). Different subsystem, different capability, not a magnet.
No support/conformance matrix in the README (its tables are module descriptions with no "Planned"
rows), no maintainer numbered plan in an issue, no `CHANGELOG` at all and therefore no
capability-removal record.

### ⭐ LANE — honour the addon-declared `ResourceResponseCache` directives inside the `ResourceLoadable` kernel

**The find, and I confirmed it with grep.** `src/types/addon/response.rs:68-79` defines

```rust
pub struct ResourceResponseCache {
    pub cache_max_age: Option<u64>,      // cacheMaxAge
    pub stale_revalidate: Option<u64>,   // staleRevalidate
    pub stale_error: Option<u64>,        // staleError
    #[serde(flatten)] pub resource: ResourceResponse,
}
```

`grep -rn ResourceResponseCache --include=*.rs .` returns **three hits, all inside that one file**
(the struct plus two doc-comment lines). The addon protocol tells the client how long each resource
response stays fresh; stremio-core parses all three windows and **discards them at the transport
boundary** — `AddonTransport::resource(&self, path: &ResourcePath) -> TryEnvFuture<ResourceResponse>`
(`src/addon_transport/addon_transport.rs:5`) has no slot for them. This is the
`probe-convergence: lever is discarded state` pattern verbatim: a field the repo READS and then
WRITES NOWHERE.

**PR archaeology (run by me, because a declared-but-unused field is often a published plan).**
The struct arrived in **PR #658 "feat: Add Cache response fields for addon Response"**, merged
2024-03-25, **+76 / -0, a single file**, with an **empty PR body**. No design sketch, no follow-up
issue, no stated plan; two and a half years later nothing consumes it. So the prior art covers the
TYPE (which the pick reuses rather than re-invents) and not one line of the consumption.

**Phrased in repo-internal nouns only:** `ResourceLoadable`, `ResourceAction` / `ResourcesAction`,
`resource_update`, `resource_update_with_vector_content`, `resources_update`,
`resources_update_with_vector_content`, `resource_content_from_result`,
`resource_vector_content_from_result`, `ResourceResponseCache`, `Loadable::Loading`,
`ResourceError::EmptyContent`, `AggrRequest::plan`, `eq_update`, `Internal::ResourceRequestResult`,
`Effects::none().unchanged()`, `ResourcesAction::force_request`.

**The shared kernel:** `src/models/common/resource_loadable.rs`, 283 lines, four `*_update` entry
points over a 2x2 grid — {single `ResourceLoadable` | `Vec<ResourceLoadable>`} x {scalar `T` |
`Vec<T>` content} — all funnelling into two private converters.

**The surfaces it feeds (11 non-test consumers, by `grep -rln`):** `models/catalog_with_filters.rs`
(Discover), `models/catalogs_with_extra.rs` (Board), `models/meta_details.rs` (**both** the scalar
meta path and the vector streams path), `models/calendar.rs`, `models/live_tv_guide.rs`,
`models/live_tv_continue_watching.rs`, `models/player.rs`, `models/ctx/update_notifications.rs`,
`models/ctx/update_streams.rs`, `models/ctx/ctx.rs`, `runtime/msg/internal.rs`.

### ⭐ Traps VERIFIED IN SOURCE by me at `b3062f7f` (not predicted)

1. **The `Loading` guard makes every revalidation response dead on arrival — and it is unreachable
   today.** All four result handlers gate on
   `matches!(resource.content, Some(Loadable::Loading))` (`resource_loadable.rs:120-121`, `:142-143`,
   `:209`, `:231`). Every existing caller sets `content = Some(Loadable::Loading)` *before* firing
   the request — including `force_request`, whose whole effect is to make the dedup `find` miss so a
   fresh `ResourceLoadable{content: Some(Loading)}` is constructed. **So the `_ =>
   Effects::none().unchanged()` arm is dead code in the base tree**, and the first thing the new
   regime does is reach it: a stale-while-revalidate response arriving while content is `Ready` is
   silently dropped. This is the F-39 / F-20 shape (an inherited path every current caller keeps
   unreachable), and it is MISDIRECTING: the agent adds the revalidation request, the assertion still
   shows stale content, and the failure points at the freshness policy rather than at a `matches!`
   four functions away.
2. **`resources_update`'s dedup short-circuits any freshness check placed in the obvious place.**
   `resource_loadable.rs:174-177`:
   `.find(|resource| resource.request == request && resource.content.is_some() && !force)` returns
   the cached entry before anything can compare timestamps. A TTL test written into the request path
   therefore works on the single-resource surfaces (Discover, MetaDetails) and **never fires** on the
   multi-resource ones (Board, Calendar, notifications). Interdependent with trap 1: fixing the guard
   does not fix this, and fixing this exposes the guard.
3. **The scalar and vector converters disagree about "empty".**
   `resource_vector_content_from_result` (`:267-272`) maps `Ok(content)` with `content.is_empty()` to
   `Loadable::Err(ResourceError::EmptyContent)`; `resource_content_from_result` (`:248-256`) has no
   such branch. So a `staleError` policy that revalidates on `Loadable::Err` **resurrects a
   legitimately-empty catalog** on every vector surface while behaving correctly on the scalar ones.
   Fix one arm, regress the other — a textbook F-10 cross-product cell, and it costs zero description
   words.
4. **F-9 at the trait boundary, with a compile wall attached.** `AddonTransport::resource` returns
   `TryEnvFuture<ResourceResponse>` and there are three implementors (`http_transport`, the legacy
   JSON-RPC adapter beneath it which has no directives at all and must synthesise a default, and
   `unsupported_transport`). The directives are resolved by serde at the HTTP layer and dropped one
   function later; the models re-derive freshness at a third point.
5. **`force_request` must bypass freshness while still arming the stale-if-error window**, and
   `eq_update` + `Effects::none().unchanged()` dirty accounting means a revalidation producing
   identical content must not mark the model dirty — otherwise the existing suite's `states.len()`
   assertions flip. That is an existing-test tripwire, which is the good kind.

### TRAP SEAMS (failure-patterns.md)

| Pattern | Present | Evidence |
|---|---|---|
| F-9 cross-stage resolution drop | **yes** | serde resolves `ResourceResponseCache` at `http_transport`; `AddonTransport::resource:5` drops it; the models re-derive freshness at a third point. One root cause breaks every capability at once |
| F-39 inherited path no caller reaches | **yes** | the `matches!(.., Loading)` guard, dead in the base tree because every caller sets `Loading` first; the new regime is the first to arrive on `Ready` |
| F-10 capability cross-product | **yes** | multiplicity axis = single `ResourceLoadable` vs `Vec<ResourceLoadable>`; content axis = scalar `T` vs `Vec<T>`. Four kernel functions, and the `EmptyContent` rule exists on only one arm |
| F-15 arming-vs-firing | **yes** | `resources_update`'s `content.is_some() && !force` arms a reuse decision that no freshness condition can fire against |
| F-20 sibling-API contamination | **yes** | `resource_update` vs `resource_update_with_vector_content` and `resources_update` vs `resources_update_with_vector_content`: siblings differing on one rule, with the vector arms delegating to the scalar ones via `_ =>` |
| F-14 declared-vs-derived terminal state | **yes** | `Loadable::{Loading, Ready, Err}` gains "stale but usable"; `ResourceError::EmptyContent` vs `Env` must be classified differently for the stale-if-error window |
| F-16 unparameterised setter | partial | `ResourcesAction::request` / `force_request` are a two-constructor boolean pair, and Rust makes getting them backwards a behavioural, not compile, error |
| F-19 shared-helper output channel | no | — |
| F-13 two-tier format | no | — |

### Missing machinery (the LOC carry)

The repo has **no cache of any kind** over addon resources: no timestamp on `ResourceLoadable`, no
freshness classifier, no revalidation effect, no eviction, and no slot in the transport trait to
carry a policy. What exists is a per-model, per-session, TTL-free, eviction-free `find` that reuses
any content-bearing entry forever. The `ResourceResponseCache` struct is provably dead code. This is
**not** "add the missing X arm to a thing that already handles A, B and C".

### eff-LOC sketch (decision points, chokepoints collapsed)

| # | Decision point | eff |
|---|---|---|
| 1 | `ResourceResponseCache` -> a freshness policy: three windows, resolution when a field is absent / zero / larger than the next window | 35 |
| 2 | `AddonTransport::resource` carries the directives; `http_transport` reads the `#[serde(flatten)]` wrapper; the legacy JSON-RPC adapter synthesises a default; `unsupported_transport` | 50 |
| 3 | `Internal::ResourceRequestResult` payload widened + every match arm in `runtime/msg/internal.rs` and the consumers | 25 |
| 4 | `ResourceLoadable` gains `cached_at` + policy; `Serialize` impact on the `stremio-core-web` model serialisation | 30 |
| 5 | Freshness classifier against `E::now()`: fresh / stale-revalidate / stale-if-error / expired | 45 |
| 6 | `resource_update`: freshness short-circuit, revalidation effect, and repairing the `Loading` guard so a revalidation result lands on `Ready` content | 55 |
| 7 | `resources_update`: the dedup `find` becomes a freshness-aware partition; per-request revalidation effects joined with `eq_update` dirty accounting | 60 |
| 8 | Vector variants: classify `EmptyContent` vs `Err(Env)` for the stale-if-error window | 35 |
| 9 | `force` interaction + `AggrRequest::plan` ordering stability under partial revalidation | 25 |
| 10 | Ctx-level invalidation on addon uninstall / reorder | 30 |
| | **sketched total** | **~390** |

Rows 6/7/8 share the two private converters, so they amortise (the dinit 315 -> 105 lesson).
**Underwrite this at 300-340**, which still clears the ">250 proceeds" threshold with margin. Row 10
can be dropped if it collides with open PRs #821/#954 and the lane still sketches ~360.
**The named coupled second lever**, if the core caves: rows 2+8 together — the legacy JSON-RPC
transport that has no directives and must synthesise them, plus the vector arm's `EmptyContent`
classification. Genuinely separate semantics, not more of the same surface.

### Absorption / sibling-library / previous-major

- **The algorithm the repo does not contain:** a three-window freshness policy
  (fresh / stale-revalidate / stale-if-error) keyed by `ResourceRequest`, driven by `E::now()`, shared
  across four kernel entry points and eleven surfaces, with revalidation results landing on already-
  `Ready` content without disturbing `eq_update` dirty accounting.
- **Sibling library:** no public Rust crate implements an addon-protocol resource cache for Stremio.
  The only bindings repo, `stremio-core-kotlin`, is archived and CONSUMES this crate.
  `stremio-core-web` is a WASM bridge over the same kernel, not a competing implementation.
- **Previous major:** stremio-core is at 0.63.x with no prior major version. The legacy JS
  `stremio-addon-client` is a different language with a different architecture (no `Loadable` /
  `Effects` model), so nothing here is a port of the repo's own earlier self.
- **Self-collision:** the nearest thing in our corpus is `approved-problems/petl-incremental-refresh`
  (incremental materialization of a table expression). Different capability entirely — that one
  propagates row deltas through a plan; this one classifies response age against three windows. No
  subsystem, kernel or trap overlap.

### Stage 6 death-class guard — PASSED

1. **One shared kernel feeding several surfaces where a local fix REGRESSES another?** YES, and it is
   the strongest part of the pick. `resource_loadable.rs`'s two private converters are reached by
   four public entry points over eleven consumers; the `EmptyContent` rule lives on one arm only, so
   any freshness-on-error policy that is correct for Discover is wrong for Board.
2. **Interdependent, not merely several?** YES. Repairing the `Loading` guard (trap 1) is a
   precondition for trap 2's revalidation being observable at all; fixing trap 2's dedup exposes
   trap 1 on the multi-resource surfaces; both then surface trap 3's empty-content divergence.
3. **Could a standalone new file with minimal wiring solve it?** NO. It re-shapes a trait with three
   implementors, widens an `Internal` message consumed across the model tree, and mutates the kernel
   every model loads through. Three subsystems: `types/` -> `addon_transport/` -> `models/`.
4. **`TOO-EASY.md` Pre-Pick Guard 1-5:** (1) not one rule at many sites — window resolution,
   revalidation plumbing, dirty accounting and the scalar/vector empty divergence are distinct
   mechanisms; (2) not a single-subsystem fully-specified transform; (3) the hardness does NOT depend
   on the spec hiding anything — stating "responses carry cacheMaxAge / staleRevalidate / staleError
   and the loader must honour them" reveals neither the `Loading` guard, nor the dedup short-circuit,
   nor the `EmptyContent` asymmetry; (4) not a port of a spec the model knows (see risk 1); (5) the
   difficulty survives full specification.

### Risks, honestly

1. **Named-spec adjacency — the one real risk.** `stale-while-revalidate` / `stale-if-error` are
   RFC 5861 Cache-Control extensions, so an outsider can partly name the capability. Under the
   softened 2026-09-09-B rule that is a MEDIUM risk to mitigate, not a reject, and **both reject
   conditions are absent**: there is no long-open uncommented issue asking for it (zero tracker hits,
   verified), and it is not a faithful port (RFC 5861 governs HTTP response headers; this governs the
   addon manifest's own `cacheMaxAge`/`staleRevalidate`/`staleError` fields applied to an in-memory
   `ResourceLoadable` tree). **Mitigation, to be carried into `meta.md`:** phrase everything on
   `ResourceResponseCache` + the kernel's own nouns, never name the RFC or `Cache-Control`; build the
   F-10 cell table as {single, vec} x {scalar, vector} x {fresh, stale-revalidate, stale-if-error,
   expired}; re-run the canonical-org PR-DIFF check at submit.
2. **New trait signature = compile-wipe risk.** Changing `AddonTransport::resource` is exactly the
   `new-api-signature-compile-wipe` memory lesson (8/8 Nova wiped on `files()`). `meta.md` MUST state
   the new return shape and which implementors change, or agents will fail on the signature rather
   than the semantics.
3. **An AI-assisted workstream exists in the repo, in a DIFFERENT lane — but it touches two of the
   eleven surfaces.** On 2026-07-02 a contributor committed `LIVE_TV_EPG.md`, `PROGRESS.md`,
   `TODO.md` and `PURE_TV_ADDON_ALIGNMENT.md` (506 lines of design docs + a progress tracker), then
   removed them (`6382f48f docs: remove planning docs from PR`) — so the root probe is clean at HEAD
   but the marker is real in the history. The maintainer's 90-day direct pushes confirm the lane:
   `Refresh live guide models on demand`, `Preserve live channel IDs in Continue Watching`,
   `Fix live channel identity and EPG schedule lifecycle`, `Keep live channel details current`, plus
   player / streaming-server / deep-link work. **None of it touches `resource_loadable.rs` or the
   transport trait** (verified by path-filtered history), so under the 2026-09-09-B softening this is
   a LANE note, not a repo verdict. **Instruction for the builder: keep the centre of gravity in
   `resource_loadable.rs` + `addon_transport/` + Discover / MetaDetails / Board, and do NOT let
   `live_tv_guide.rs` or `live_tv_continue_watching.rs` carry any tested behaviour.**
4. **Two open PRs touch `models/ctx/ctx.rs` and `update_profile.rs`** (#821 Trakt profiles, #954
   addon upgrade). Wire decision-point 10 (invalidation) through a new `Internal::` variant consumed
   at the surfaces rather than editing those two files, or drop row 10.
5. **`models/common/descriptor_loadable.rs`**, a sibling of the kernel in the same directory, is
   being edited by open PR #1048. Do not extend the lane into manifest/descriptor loading.
6. **The maintainer moves fast** (38 merged PRs / 90d, >=100 commits / 90d, solo-heavy). The lane
   files are 19 months and 5 years cold respectively, but re-run the full six-check at submit.
7. **`ENV_MUTEX` serialises the whole suite** and `NOW` is global mutable state. New tests must go
   through the existing `TestEnv::reset()` fixture, and must never assume parallel isolation.

---

## RANK 2 (fallback) — PiSCSI/piscsi — ★608 — BSD-3-Clause — C++ 91.6%

Clone kept at `worktrees/_hunt/q_0921h11/piscsi` (6.6M, `--depth 50`), HEAD `4f800ba`.

**Licence** verified by reading `LICENSE:1-8`; `grep -rlniE 'GNU General Public|GPL-2|LGPL'` over
`cpp/` and `python/` is empty; no vendored third-party dir (protobuf sources are generated at build).
**Root AI probe clean; zero AI co-author trailers in 90 days.** Liveness measured by me: **85 human
commits by `rdmark` + 14 dependabot + 1 other in 90 days**, 30 merged PRs / 90d, 3 open PRs.
**Requirement 7:** `.github/workflows/cpp.yml`, `name: C++ Tests; Full Static Analysis`, job
`unit_tests`, steps `DEBUG=1 make -j $(nproc) test` then
`GTEST_SHUFFLE=1 bin/piscsi_test | tee piscsi_test_log.txt`. GoogleTest + GoogleMock,
**318 `TEST`/`TEST_F` cases**, cited assertion
`cpp/test/storage_device_test.cpp:46 EXPECT_THROW(device.ValidateFile(), io_exception);`.
The fork `uweseimet/scsi2pi` has 24 stars, so this is the live upstream.

⚠️ **Re-verified by me, and this repo is another textbook case for the workflow-name rule.**
`gh run list --branch develop --limit 12` returns **only dependabot rows** (including two
`go_modules in /go` **failures**) — the test workflow does not appear at all. `gh run list
--workflow cpp.yml --branch develop` returns **eight consecutive `success` rows**,
`4f800bae` 2026-09-06 through `247c2816` 2026-09-01. Reading the histogram instead of the workflow
would have produced a false reject here, exactly as it did for mapproxy in hunt #10.

**LANE — identity-based image-file reservation ledger.** Shared kernel:
`static inline unordered_map<string, id_set, StringHash, equal_to<>> reserved_files`
(`cpp/devices/storage_device.h:103`) plus `GetIdsForReservedFile` returning `{-1,-1}` as "free".
**I confirmed the three different spellings of "resolve an image name" by reading the source:**

- `PiscsiExecutor::ValidateImageFile` (`piscsi_executor.cpp:398-420`) reserves under the **raw**
  filename, and only if the file does not exist retries with `default_folder + "/" + filename`.
- `PiscsiImage::GetFullName` (`piscsi_image.h:47`) is
  `return default_folder + "/" + filename;` **unconditionally** — so an absolute path becomes
  `/default//abs/path`. This is the key `DeleteImage`, `SetImagePermissions` and `ValidateParams`
  (rename + copy) look up through `IsReservedFile`.
- `PiscsiResponse::GetImageFile` (`piscsi_response.cpp:114`) uses a **third** rule,
  `filename[0] == '/' ? filename : default_folder + "/" + filename`.

So an image attached by absolute path is reserved under one key and looked up under another: the
delete-while-in-use guard silently misses. Further seams: `ReserveFile()` is `const` and `assert`s
uniqueness (`storage_device.cpp:80-82`), so under `NDEBUG` a second holder overwrites the first and
the first device's `UnreserveFile` erases the second's reservation (F-15); `id_set` is a
`pair<int,int>` so one read-only ISO on two LUNs is unrepresentable; `ValidateParams` shares
`IsReservedFile` between rename (must re-key) and copy (must keep refusing).
~325 eff sketched, honest floor ~260. Maps to F-18 + F-9 + F-15 + F-41.

⚠️ **Lane-coldness correction (measured by me, path-filtered commits API).** The screener reported
2 / 2 / 2 / 4 commits in 12 months on the four lane files, which is true but hides the RECENCY:
`piscsi_response.cpp` was touched 2026-08-23 and twice on 2026-08-02, `piscsi_executor.cpp`
2026-08-23, `piscsi_image.cpp` 2026-08-02. Reading the subjects applies the corrected Gate 5 —
`restore support for SASI disk drive device`, `parprouted bridge for SCDP adapter`,
`Make Meson unit tests portable to macOS` — i.e. device-restoration and build-portability work, not
reservation-ledger work. The CAPABILITY lane is still open; the FILES are not cold. Anyone taking
this fallback must re-run the exclusivity check against `rdmark`'s stream at scope-lock, not trust
the 12-month count.

**Why RANK 2 and not RANK 1, recorded so the decision is auditable:**
(a) **shape adjacency to work in flight** — this is an accounting-ledger-across-mutation-paths pick,
the same family as `pyfakefs-block-inode-accounting`, which a parallel session is building RIGHT NOW,
and `approved-problems/afero-overlay-deletions`. The capabilities differ, but shipping two
ledger-accounting picks in one batch window is a needless derivative bet;
(b) **C++ cold-build cost** — L62 measured 704s for cwerg's first Dockerfile against the platform's
600s environment-start budget, and this one adds `protoc` codegen plus apt-pinned
spdlog/protobuf/gtest;
(c) **a real flakiness hazard** — `reserved_files` is `static inline` global state and CI runs with
`GTEST_SHUFFLE=1`; merged PR #1137 exists *because* reserved-file cleanup between tests was missing.
A submission must pin `GTEST_SHUFFLE=0` and route every new test through the existing
`UnreserveAll()` fixture.
Secondary constraint: the device layer (MODE SENSE pages, INQUIRY, READ TOC) is a faithful external
spec and a burned class — the lane must never drift there. Residual: the "return false instead of
assert" micro-fix IS visible in the 24-star fork, so it must be one line of the pick, never its core.

---

## RANK 3 (fallback) — netromdk/vermin — ★531 — MIT — Python 99.5%

Clone at `worktrees/_hunt/q_0921h11/vermin` (2.4M, `--depth 50`). From the FRESH pool, not the
residual. Licence read in-tree (`LICENSE.txt`, "MIT License / Copyright (c) 2018 Morten
Kristensen"); **`dependencies = []` in `pyproject.toml`** — zero runtime deps, nothing to pin.
Root probe clean; no `proposals/`/`heps/`/`skills/`.

**Requirement 7, with Finding 3 applied:** `.github/workflows/test.yml`, `name: Test`, step
"Test and coverage" -> `${{ matrix.test_script_name }}` -> **`./misc/actions/test.sh`** ->
`make test-coverage` -> `./runtests.py`. No apt-get, no docker-compose, no network in the test path.
`gh run list --branch master --workflow test.yml`: `success 2026-09-19` (x2), `success 2026-09-01`,
**zero `failure` rows on master**. stdlib `unittest`; cited assertion `tests/lang.py:10`
`self.assertOnlyIn((2, 0), self.detect("print 'hello'"))`.
**Run locally by the screener, twice:** `Ran 4437 tests (28 suites)` in 17.7s / 20.0s, `exit=0`,
identical. Liveness: 39 commits/90d, 13 merged PRs/90d (41/12mo), **32 human code commits/90d**
(`netromdk` 30), zero AI-sweep marks in 90 days of commit messages.

**LANE — project-level version provenance across the `Processor` pool.** Shared kernel:
`SourceVisitor.__add_versions_entity()` -> `SourceState.info_versions` ->
`utility.combine_versions(list1, list2, config, version_refs)`. Today `info_versions` is populated
**only when `show = self.__show_analysis(violation)` is true** (so provenance depends on verbosity)
and **dies at the `mp.Pool` boundary** — `ProcessResult` carries `mins`, `novermin`, `bps`,
`maybe_annotations` but not `info_versions`, so the project-level `combine_versions` runs with
`version_refs=None`. Six surfaces; the best misdirection is that `Processor` has **two** paths,
`pool.imap(...)` and a `processes == 1` list-comprehension bypass, so a fix on the pickle path passes
under `-p 1`, fails under the default, and surfaces as a format assertion in `parsable_format`.

**~250 eff sketched**, with a real chokepoint-collapse risk (`combine_versions` and
`__add_versions_entity` are single chokepoints; ~30 detection call sites amortise to ~1). Treat it as
**150-250 plus a named coupled lever**, the lever being the `novermin`/backport suppression path that
must REMOVE an attributing detection and therefore change the computed verdict, not only the message.

**Why RANK 3:** (a) the eff-LOC sketch is the thinnest of the three and needs its lever to clear the
floor; (b) draft PR **#342 "Python 3.15 support"** (open since 2026-05-17, +1319/-201) touches
`rules.py`, `source_visitor.py`, `source_state.py`, `parser.py` — it implements 3.15 detection ARMS
rather than a provenance kernel, so it is survivable, but it must be re-diffed at scope-lock;
(c) a provenance lane is attribution-flavoured and brushes the bookkeeping death class.
**Lanes to avoid in this repo:** f-strings and kwargs/chained receivers (the maintainer's hot 90-day
workstream), plus issues #251 and #245, which are long-open outsider-nameable picks.
**Authoring footgun:** `make test` also runs `test-self` = `./vermin.py --violations -q -t=3 vermin
vermin.py`, so vermin's own source must stay Python-3.0-syntax compatible (no f-strings, no
annotations, `.format()`); `test.sh` should invoke `runtests.py` directly, not `make test`.

---

## RANK 4 (fallback, BLOCKED on two checks) — u-root/u-root — ★3075 — BSD-3-Clause — Go 99.2%

Arrived after the result block was handed back. It is the best-SHAPED repo of the five and I
re-argued RANK 1 against it; **it stays at RANK 4 because I verified two independent risks that
`stremio-core` does not carry.** Both are checks, not opinions, and both must be cleared before
anyone authors it.

**⛔ Risk 1 — vendored MPL-2.0, verified by me by reading the files.** The top-level licence is a
clean BSD-3-Clause (`LICENSE:1-3`), but `vendor/` carries two **MPL-2.0** dependencies:
`vendor/github.com/hashicorp/golang-lru/v2/LICENSE` and
`vendor/github.com/cyphar/filepath-securejoin/LICENSE.MPL-2.0` (+ `COPYING.md`). The licence gate is
an **ALLOWLIST** — "if the repo carries multiple licenses (including vendored subdirs), **every one**
must be in the allowlist" — and MPL-2.0 (weak copyleft) is not on it. This is the G-JVM2 / synthea
precedent exactly: a correct permissive top-level label hiding a non-allowlisted licence in a
directory the build compiles in. Since u-root vendors, those files ship in the image.
**Resolve before authoring, do not assume "not GPL" means "permitted".**

**⛔ Risk 2 — the sibling-library textbook-algorithm row, verified by me with a code search.**
The lane's hard part is a coalescing, type-aware free-space allocator over a memory map. `gh search
code "locate_hole"` returns **`horms/kexec-tools :: kexec/kexec.c` and `kexec/kexec.h`** (plus two
mirrors), i.e. the canonical C kexec userspace ships `locate_hole` / `add_segment` — find a hole in a
typed memory map under alignment and minimum-address constraints, then place a segment in it. That is
the `sfepy` arc-length death verbatim: the repo's wiring becomes "integration and policy work" around
a core the gate rules publicly solved. The concept is also outsider-nameable for the same reason.

Everything else about the repo is excellent and worth keeping on file: Go 99.2% with the only
`import "C"` hits behind `//go:build tinygo` (outside the test path), **fully vendored so the build
is offline**, `.github/workflows/tests.yml` `name: Tests` running
`runvmtest -- go test -v -timeout=20m ... ./pkg/...` with `Tests success` on `main` 2026-09-20,
Go `testing` + `slices.Equal`/`go-cmp` (cited: `pkg/boot/kexec/memory_linux_test.go:51-52`),
**77 merged PRs / 90d and only 2 open PRs**, ~85 human commits / 90d, **zero AI-sweep hits in 90 days
of commit bodies**, and `pkg/boot/kexec/memory_linux.go` + `memory_map_linux.go` with **zero
non-test changes in 90 days** (the 47-commit `binjip978` burst is a repo-wide mechanical
`reflect.DeepEqual -> slices.Equal` chore). The screener ran `go test ./pkg/boot/...` three times:
24 ok packages, identical each run, no VM needed.

**LANE (recorded so it is not re-derived): reservation-typed, coalescing physical placement in
`kexec.Memory`.** Kernel: `pkg/boot/kexec/memory_linux.go` (699 LOC) + `memory_map_linux.go` (510).
Five base-reproducible traps, coupled through one chokepoint: `MemoryMap.Insert` does
`Minus`+`append`+`sort` and **never calls the `mergeAdjacent` that sits one function above it**, so a
reserve/release cycle permanently fragments same-type RAM and a later large `FindSpace` returns
`ErrNotEnoughSpace` while contiguous free RAM exists; `Memory.AvailableRAM` subtracts only
`m.Segments` and never the non-RAM `TypedRange`s; `WithMinimumAddr` mutates `o.limit.Size` while
`WithinRange` replaces `o.limit` wholesale, so **option order changes the result**;
`AddKexecSegmentExplicit` does `r.Start += offset` without shrinking `r.Size`; and `AlignPhysStart`
rounds a segment start *downwards* into a reservation, after which `mergeDisjoint`'s
`realBufPad`/`realBufTruncate` asymmetry makes a later `GetPhys` read back zeros. ~290 eff sketched,
floor 230-290. ⚠️ **`pkg/uroot/` has been hollowed into the org's own `u-root/gobusybox` and
`u-root/mkuimage`** (447 LOC left), so the initramfs/busybox-builder lane is dead; `pkg/boot/**` is
unaffected. Also: alanhc is actively adding riscv64/arm64 kexec **loaders**, so a pick must stay in
the range/segment algebra and out of `pkg/boot/linux/load_linux_*`; and base mode must be scoped to
`./pkg/boot/...`, never `./...` (the VM-based `integration/` legs flake, which is the one `failure
Tests` row on main on 2026-09-14 beside successes the same day).

## RANK 5 (fallback) — getgauge/gauge — ★3189 — Apache-2.0 — Go 97.8%

Clone at `worktrees/_hunt/q_0921h11/gauge` (3.7M). Apache-2.0 read at `LICENSE:1-3`; no vendor dir,
so module licences are UNSCANNED — do that first, given what u-root's vendor dir turned up.
Requirement 7: `.github/workflows/tests.yml`, `name: build`, job `tests`, step `Test`:
`go run build/make.go --test --verbose`; `build success` on `master` 2026-09-16. gocheck
(`gopkg.in/check.v1`); cited `parser/processor_test.go:19`
`c.Assert(t.Args[0], Equals, "first second third")`. 30 merged PRs/90d, 7 open PRs, zero AI-sweep
hits. All 7 open PRs enumerated: `gauge/concept.go`, `gauge/step.go`, `gauge/arg.go` and `refactor/`
are untouched, but **the data-table / scenario-expansion sub-lane is crowded (#2880, #2879, #2792)
— avoid it.**

**LANE:** nested-concept lookup propagation and parameter reordering across the `ConceptDictionary`
(`ReplaceNestedConceptSteps`, `UpdateLookupForNestedConcepts`, `ArgLookup`,
`Step.getArgsInOrder(orderMap)`), feeding the concept parser, `refactor/`, `formatter/`,
`validation/` and `protoConverters`. Misdirecting because line text is regenerated from fragments, so
a wrong arg order surfaces as a *formatting* diff rather than a rename error.
**~215 eff — inside the 150-250 band, so it needs its named coupled lever** (row 4, the refactor
rewriting concept files *and* spec files, a separate algorithm from lookup propagation).
Ranks last because it is a FRAMEWORK rather than a domain, and human liveness is thin
(12 human commits/90d, 5 of them one maintainer's maintenance).

---

## Closed-out rows and near-misses (the evidence, so nobody re-derives it)

| Repo | Gate failed | Note |
|---|---|---|
| `ealush/vest` (TS 2722*) | Exclusivity | The MAINTAINER holds six open PRs blanketing the suite-state isolate kernel: #1326 inline `dependsOn` graph with selective `changed()` runs, #1290 cross-field `dependsOn` propagation, #1296 + #1262 success severity with hooks/selectors, #1261 async rules in eager `enforce()` chains, #1250 `getData` resolver. Each is a public solution diff. Also `scripts/score-ai-eval.js` + `yarn ai:eval` + `build:llms` — AI tooling the root probe misses |
| `pubkey/broadcast-channel` (JS 2001*) | AI sweep closed the gap class IN the lane | Requirement 7 passes cleanly (`main.yml`, `name: CI`, `npm run test:node` -> `mocha ./test/index.test.js -b --timeout 6000 --exit`, `CI success` on `master` 2026-09-19, mocha + `assert`). Dies because the only real code commit in six months is `#1416`, `Co-authored-by: copilot-swe-agent[bot]`, which fixes four `isDead` guards across `LeaderElection` + `LeaderElectionWebLock` and makes `die()` idempotent — the entire authorable kernel. Twelve months of renovate otherwise |
| `microsoft/vscode-textmate` (TS 678*) | Requirement 3 corpse + named spec | Genuinely engine-shaped (`ScopeStack`/`StateStack` feeding `tokenizeLine`, binary `tokenizeLine2`, injections, embedded grammars, theme scope-selector resolution) and clean to build (`vitest run`, prebuilt `vscode-oniguruma` wasm). Zero real-code commits in 90 days; last one 2026-06-13. TextMate scope selectors are an external spec; Microsoft-owned |
| `Belphemur/node-json-db` (TS 830*) | Requirement 3 corpse + red default branch | Cleanest mechanics in its slice (zero runtime deps, `jest --coverage`) but the default branch `develop` is 90 days of dependabot + kodiakhq auto-merges and one README typo, and `NodeJs` shows `failure` on `master` on every run back to 2025-10-30 (`codecov-action` with `fail_ci_if_error: true` and no token) |
| `sitespeedio/browsertime` (JS 652*) | Gate 5 | The only row in its slice with strong HUMAN liveness (70 of 76 90-day commits by `soulgalore`) and a real domain, but the suite drives Selenium against real Chrome/Firefox |
| `ehmicky/wild-wild-path` (JS 729*) | Sibling-package hollowing | The path grammar lives in `wild-wild-parser` and the operations in `wild-wild-utils`, both the same author's; this package is a thin dispatch layer. Also `"test": "gulp test"` through `@ehmicky/dev-tasks` |
| `argoproj-labs/hera` (Py 938*) | Maintainer numbered plan + absorption | The ONLY Python row that cleared Requirement 7 (`cicd.yaml` job `test` -> `make ci` -> `pytest -m "not on_cluster" -k "not typehints" -k "not cli"`, `CICD success` on `main` 2026-09-08, bounded deps, clean root). Dies on `proposals/heps/0001-decorators.md` + `0002-YAML-converter.md` (accepted plans claiming two of three lanes), open PR #1613 owning `workflows/script.py` + `_runner/util.py` (the third lane's exact two files), a 90-day maintainer sweep of the remaining seams (#1603, #1595, #1609, #1593), and an absorption verdict: every capability in `construct_io_from_annotation` is "add the missing arm to a thing that already handles Parameter, Artifact, Input and Output". Clone left at `q_0921h11/hera` (11M) |
| `scanapi/scanapi` (Py 1582*) | Burned class + LOC floor + fake activity | HTTP request-spec runner; **2,784 total source LOC** in the whole package (largest file 322 lines); 16 of 17 commits in 90 days are `docs:`/`ci:`/`chore:` |
| `awslabs/automated-security-helper` (Py 695*) | Kill-on-sight support matrix | README:69-80 is a scanner x language/framework matrix. Root also carries `skills/` and `.ash` (markers the current regex misses). Only the `unit-test` job is offline |
| `CERT-Polska/Artemis` (Py 1223*) | Gate 5 | `test-unit.yml` -> `bash ./scripts/test-unit` -> `docker compose up` of **eleven** live service containers seeded with SQL dumps, then `docker compose run test` |
| `GafferHQ/gaffer` (Py 1097*) | Gate 5 | Best domain in its slice (node-graph lookdev/compute engine, 473 commits and 30 merged PRs in 90d). `main.yml:210-215` downloads a prebuilt dependency archive, a Mesa 7z and RenderMan 26.3 at build time; C++ primary tree |
| `mosaico-labs/mosaico` (Py 1048*) | Gate 5 + wrong half of the repo | `py-ci.yml` -> `./scripts/tests --sdk-python` boots a docker postgres and a compiled `mosaicod` binary. The Python half is a thin client SDK; the engine is the Rust daemon |
| `poseidon/matchbox` (Go 1427*) | eff-LOC < 150 | Cleared everything else (`make test` = `go test ./... -cover` with `CGO_ENABLED=0`, green on `main` 2026-09-18, 37 merged PRs/90d vs 6 open, Apache-2.0). ~3.5k hand-written Go once the 2.4k generated `*.pb.go` lines are removed; largest non-generated file 216 lines, the group matcher 170. Secondary: `matchbox/sign` is GPG, and 0 open issues is a ranking penalty |
| `superfly/corrosion` (Rust 1850*) | Gate 5 | R7 fine (`cargo nextest run --profile ci --workspace`, green on `main` 2026-09-16). `Cargo.toml:70` pins `rusqlite` with `"bundled"` -> compiles a vendored C SQLite, and `crsqlite.yaml` fetches a prebuilt native extension |
| `bee-san/Ares` (Rust 881*) | Requirement 7b | `quickstart.yml` (`name: Test`) does run `cargo test`, but **every one of the last 15 runs is `failure`** and none is on the default branch — the only `main` runs are dependabot. The m90=30 figure is entirely dependabot auto-merge. Also `checkout` with `lfs: true` |
| `spinel-coop/rv` (Rust 1797*) | Absorption / sibling-library + lane density | `[workspace.dependencies]` pins `pubgrub = "0.4.0"` (the version-resolution algorithm is a published crate) and `rv-gem-specification-yaml` is a faithful port of the gemspec format. 504 merged PRs in 12 months, open queue already on `doctor`/`doctest`/`gem`/`sync`. Secondary: `proptest` in the suite |
| `ozontech/file.d` (Go 504*) | Liveness ratio + exclusivity blanket | 40 open PRs vs 17 merged in 90d (40 >= 2x17), and the open queue blankets every seam: #1003/#1002 transform-plugin functions and constant folding, #882 antispam, #722/#719/#677 insane-json node pooling, #960 split/join, #976 EOF buffer flush |
| `habitat-sh/habitat` (Rust 2753*) | Requirement 7a | **No GitHub Actions workflow runs `cargo test`** (only a PR stub, codeql, labler, cargo-audit); real CI is Chef's off-GitHub Buildkite/Expeditor |
| `anyproto/any-sync` (Go 1716*) | Gate 5 | Its reusable workflow starts MongoDB and Redis service containers and runs `git config url.https://${ANYTYPE_PAT}@github.com/.insteadOf` to fetch private modules |
| `OpenMind/OM1` (Go 2926*) | Gate 5 | `apt-get install portaudio19-dev` plus `make download-zenohc` (Zenoh C library fetched at build time) |
| `Unpackerr/unpackerr` (Go 1481*) | Sibling-package hollowing | Extraction lives in `golift.io/xtractr`, the Starr APIs in `golift.io/starr`, config binding in `golift.io/cnfg` — all the same org. Plus `go generate ./...` builds an embedded Svelte frontend |
| `guacsec/guac` (Go 1541*) | Burned class + flakiness | Ingestion of SPDX / CycloneDX / in-toto / purl (all named specs); `make test` = `gotestsum -- -race -timeout=30s ./...` |
| `CppMicroServices/CppMicroServices` (C++ 879*) | Exclusivity + AI sweep | Gate 5 and Requirement 7 both pass (vendored `third_party/`, `BuildAndTestNix` green on `development` 2026-09-16, GTest). The 18-PR open queue blankets every core seam: #1281 bundle lifecycle (`BundlePrivate.cpp` -578, a new `states/` dir), #521 manifest into `BundleRegistry`, #1252 `symbolicName`/`bundleId` persistence, #1241 miniz race, #694 AnyMap nulls, #917 + #1087 DeclarativeServices. Compounded by `Co-Authored-By: Claude Opus 4.6` merges closing `any_value_to_json`/`AnyMap` gaps. **Best C++ fallback if both ranked picks die, but only with a lane proven outside every diff above** |
| `Xiangyu-Hu/SPHinXsys` (C++ 591*) | Gate 5 | `ci.yml` bootstraps **vcpkg** (`VCPKG_VERSION: "2026.04.27"`) and installs Intel oneAPI from an apt repo. Painful, because physics is a preferred domain |
| `JOML-CI/JOML` (Java 845*) | Maintainer-owned lane + eff-LOC | The `Matrix4f.properties` bitfield is a textbook shared kernel, but the maintainer's own 12-month stream IS that lane one method at a time (`Fix: Matrix4x3.normal() when orthonormal`, `Fix: Matrix4x3.rotateAroundAffine() aliasing`, `Fix: Matrix4.pick()`, ~25 more), each <20 LOC. Also the published-formula burned class; 90d commits are dependabot-only |
| `gradle/gradle-profiler` (Java 1532*) | Requirement 7a | `.github/workflows/` holds only build-scan-commit-status, enforce-labels, feedback, 3 dependency-review workflows, release-drafter, triage-label, update-jdks. **No workflow invokes a test suite** — CI lives in external Develocity/TeamCity |
| `0vercl0k/wtf` (C++ 1797*) | Sibling-package hollowing | Crash-dump parsing and symbolisation live in `kdmp-parser`, `udmp-parser` and `symbolizer`, separate repos by the same author; `wtf` is the orchestration shell. Backends need bochscpu binaries / KVM / WHV. Liveness thin (8 merged PRs, 7 commits / 90d) |
| `diffplug/spotless` (Java 5657*) | Gate 5 + catalogue shape | The test path provisions external formatter jars from Maven at runtime |
| `onnx/optimizer` (C++ 835*) | Gate 5 + burned class | `protobuf_FORCE_FETCH_DEPENDENCIES ON` plus the onnx submodule; ONNX is a named spec |
| `gaul/s3proxy` (Java 2390*), `craftablescience/VPKEdit` (C++ 747*), `apache/geaflow` (Java 809*) | Named spec / hollowed into `sourcepp` / filling queue (88 open vs 14 merged) | |
| `macbre/analyze-css`, `prettier-plugin-solidity`, `vega/ts-json-schema-generator` | Bot-only liveness (Finding 1) | m90 of 30 / 30 / 13 against 0 / 8 / 2 human code commits in 90 days |
| `thingsboard/thingsboard-gateway`, `feature-engine/feature_engine` | Requirement 7a | No GH Actions workflow runs a test suite |
| `expressive-code/expressive-code` (TS 966*) | Absorption | The lane (annotation `inlineRange` remapping across plugin line edits) is ALREADY implemented in `packages/@expressive-code/core/src/common/line.ts :: editText()` — shift, contained, fully-covered-delete and partial-intersection cut all present. The commented-out `getAnnotations(startColumn?, endColumn?)` signature shows the range-query extension was deliberately dropped. Secondary: exactly 5 human commits/90d, one Claude-co-authored (docs-only, #468), last CI on `main` 2026-08-31 |
| `pytest-dev/pytest-xdist` (Py 1905*) | PR-queue ratio + flakiness | `opr=41` vs `m90=15` (41 > 2x15); 280 open issues; `radoering`'s loadgroup-hang PRs #1324/#1328 sit exactly on the `loadscope`/`loadgroup` kernel. Requirement 7 passes (`test.yml` -> `tox run -e py31x-pytestlatest` -> `pytest`, green on master 2026-09-04) but the suite spawns real worker subprocesses, an automatic fail on the mandatory flakiness gate. Only 8 human commits/90d |
| `taskiq-python/taskiq` (Py 2334*) | Requirement 7b | Three `failure` conclusions for workflow `Testing taskiq` on the default branch `master` (2026-09-15/16/17). Otherwise strong: 26 human commits/90d, 0 AI marks, `uv run pytest -vv -n auto --cov=taskiq .` |
| `malmeloo/FindMy.py` (Py 3268*) | Test surface + sibling library | The entire suite is `tests/test_keygen.py` (387 B) and `tests/test_tls.py` (5.9 kB); everything else needs `bleak` (BLE hardware) or Apple's servers. The offline-testable part is the key derivation, which OpenHaystack / macless-haystack already ship |
| `benjamn/ast-types` (TS 1175*) | Absorption + burned class | The 17 human commits in 90d are one single-day burst (2026-08-30) on `syntax-backlog-discovery`, content `Add modern syntax fields missing from node type definitions` — the capability space is an ESTree/Babel node-definition catalogue, a faithful named-spec implementation |
| `preactjs/preact-render-to-string` (JS 727*) | **Finding 2** — AI sweep in the maintainer's own stream | `codex/preserve-client-stream-content` branch merged by the maintainer. The root probe is clean; only the commit bodies show it |
| `google/glazier` (Py 1261*) | Requirement 6 + platform | Clean CI (`Python Tests` / `Go Tests` green on master 2026-09-16) but it is an export of a Google-internal repo (`Internal change.`, `Automated Code Change`), and the code is Windows-only (WMI, registry, `Win32_NetworkAdapterConfiguration`) so it cannot run in a Linux image |
| `theRealCarneiro/pulsemeeter` (Py 769*) | **Finding 3** — Gate 5 in the called script | Its green "Tests" job first runs `sudo apt install -y pulseaudio libgirepository-2.0-dev python3-gi gobject-introspection gir1.2-gtk-3.0 libcairo2-dev` then `pulseaudio --start` |
| `rerun-io/egui_tiles` (Rust 589*) | **Finding 2** — AI sweep IN the intended lane | ⭐ The single best-shaped repo in the fresh Go/Rust/C++/Java slice and it would otherwise have been that slice's RANK 1: Apache-2.0, pure Rust, 26 human commits/90d, a real tiling-layout kernel. Killed by **12 Claude-Code commits in 90 days closing exactly the layout-correctness gap class** — `Fix visibility layouting (#156)`, `Clear the root when garbage collection had to drop it (#150)`, `Fix tile accessibility parent hierarchy (#163)`. **The root-manifest probe is clean; only the commit bodies show it.** This is the strongest single datapoint for Finding 2 |
| `microsoft/avml` (Rust 1121*) | Requirement 6 — chore-only real-code stream | Gate A passes on count (demoray 10+2) but every 90-day subject is chore: `Pin GitHub Actions to full-length SHAs`, `Restrict GitHub Actions token permissions`, `update dependencies`, `Cache armv6b build chain`, `prep 0.19.0 release`. Zero `src/` feature work. Secondary Gate 5: default features pull `native-tls` with `vendored` -> an OpenSSL C build in the test path. A shame — 21 real `assert_eq!`/insta tests over `/proc/iomem` fixtures |
| `mstange/samply` (Rust 4424*) | Burned class + maximum maintainer collision | Every subsystem is spec-shaped or privileged: `fxprof-processed-profile`/`gecko_profile` = the Firefox Profiler JSON format, `samply-symbols`/`wholesym` = DWARF/PDB/Breakpad + a symbol server, `samply-quota-manager` = SQLite, `samply/src/linux` = `perf_event_open`. mstange alone pushed 69 of 71 commits in 90d |
| `microsoft/DirectXMesh` (C++ 860*) | Requirement 7 — the suite is not in this repo | `.github/workflows/test.yml` is `name: 'CTest (Windows)'` and does `actions/checkout` of **`repository: walbourn/directxmeshtest`**; MSVC/Windows-only, so no red base mode is constructible in a Linux container |
| `anchore/quill` (Go 519*) | **Finding 1** — human-commit histogram | m90=30 is almost entirely dependabot. Humans in 90d: wagoodman 2, arpitjain099 1 = **3 < 5** |
| `dalance/amber` (Rust 953*) | **Finding 1** — human-commit histogram | c90=40 with **zero** human commits: the histogram is `20 github-actions[bot]`, `20 dependabot[bot]`. A corpse that every metadata filter reads as alive |
| `making/yavi` (Java 855*) | **Finding 2** — AI sweep | 13 hits in 90 days, all from the solo maintainer, including `Claude-Session: https://claude.ai/code/session_...` trailers on the FEATURE commits |

Python rows killed on Gate 5 with the workflow's CALLED SCRIPT read (Finding 3): KivyMD, unrealcv,
GitSavvy, sublimelsp/LSP, ceph-ansible, Artemis, mosaico, gaffer, torchcodec, turbinia, Slurm-web,
hydrogym, qgis-earthengine-plugin, netv, model_analyzer, huggingface/kernels, linorobot2,
open_manipulator, ietf-tools/datatracker, Montreal-Forced-Aligner, streamlit-folium.

---

## Requirement 0

**OWED.** The platform repository picker cannot be reached from this session. The human must try
selecting `Stremio/stremio-core` in the picker at the precheck touchpoint and record any refusal in
`SATURATED-REPOS.md § A0`. Rust is the primary language at 99.8%, so the language gate that killed
`tyfkda/xcc` is not a concern here; the risk is only the data-contamination reservation list, which
nothing on GitHub predicts.

---

## Late addendum — the result block was handed back before the fifth screener returned

The `RESULT: CANDIDATE Stremio/stremio-core` block went to the orchestrator while the
Go/Rust/C++/Java fresh-pool screener was still running. It then returned `u-root/u-root` and
`getgauge/gauge`. **I re-argued RANK 1 against `u-root` and it did not displace `stremio-core`**,
for two reasons I verified myself rather than took on report: two **MPL-2.0** packages in u-root's
`vendor/` tree against an allowlist that does not include MPL, and `horms/kexec-tools ::
kexec/kexec.c` shipping `locate_hole` / `add_segment`, which is the sibling-library
textbook-algorithm row that killed sfepy's arc-length pick. `stremio-core` carries neither: its
licence is MIT with no vendored tree at all, and no public library implements an addon-protocol
resource cache. The handed-back result stands; RANK 4 and RANK 5 are recorded above so the next
hunter inherits the evidence rather than the conclusion.

---

## Disk discipline

`/` stayed between 14G and 15G free throughout, against the 8G floor. Builds run: exactly one —
`cargo test -p stremio-core` inside `worktrees/_hunt/q_0921h11/stremio-core`, whose `target/` measured
**1.4G and was deleted immediately** after the third determinism run (`/` went 14G -> 15G). No other
cargo, go, cmake, gradle, maven or docker build was run by me or by any screening agent; `piscsi`,
`hera` and `uroot` are source-only clones. All clones are `--depth 50` under
`worktrees/_hunt/q_0921h11/`. Scratch total is ~150M, dominated by the `uroot` clone (119M), which the
next hunter may delete.

---

## Scratch left for the next hunt

- `worktrees/_hunt/q_0921h11/sweep11.sh` + `sweep11.jsonl` — the two-band sweep (6,588 rows). The
  query shapes are the un-mined bands; do not re-run them, they are consumed.
- `worktrees/_hunt/q_0921h11/live_s11u.tsv` — **201 fresh gate-cleared repos**, of which only the
  heads were screened. **This is hunt #12's starting pool**, alongside whatever remains of
  `p_0921/live.tsv`.
- `worktrees/_hunt/q_0921h11/gate11.py` / `rank11.py` / `tri11.py` / `eng11.py` — the pipeline, with
  `rank11.py` now taking the gate file as `argv[1]`. **Add the human-commit gate (Finding 1) to
  `gate11.py` before reusing it.**
- `worktrees/_hunt/q_0921h11/dead11.txt` — an 11,960-slug dead list built from
  `SATURATED-REPOS.md` + `TOO-EASY.md` + every hunt log + every `meta.md` + hunt #10's three pools.
- `worktrees/_hunt/q_0921h11/BRIEF.md` — the screening brief with the three new gates folded in.
- `worktrees/_hunt/q_0921h11/S_*.tsv` — the four residual slices, now screened.
- Clones: `stremio-core` (8.8M, clean, `b3062f7f`, `target/` deleted), `piscsi` (6.6M, `4f800ba`),
  `vermin` (2.4M), `gauge` (3.7M), `hera` (11M). The 336M `uroot` clone was deleted after its
  licence and sibling-library checks were recorded above; re-clone with `--depth 50` if RANK 4 is
  ever taken. Scratch total is now **38M**.

---

## What the next hunt should change

1. **Add the HUMAN-COMMIT gate to `gate.py`** (Finding 1): `human-authored default-branch commits in
   90d >= 5`, excluding `*[bot]`, `renovate`, `dependabot`, `kodiakhq`, `github-actions`. One extra
   field, and it kills the largest remaining false-positive class.
2. **Extend the AI probe to the 90-day COMMIT STREAM** (Finding 2). The root manifest is the cheap
   half; `Co-authored-by: copilot|Co-Authored-By: Claude|codex/|Checkpoint before|swe-agent|Claude-Session`
   in the commit bodies is the half that catches a repo whose kernel has already been swept. Also add
   `^skills$` and `^proposals$`/`^heps$`/`^rfcs$` to the root regex.
   **Measured cost of NOT having it this session: 4 of the 10 deep-dive heads in the fresh
   Go/Rust/C++/Java slice, including `rerun-io/egui_tiles`, which would have been that slice's RANK 1.**
   Across the whole hunt the commit-stream probe killed 5 repos the root probe passed
   (egui_tiles, yavi, preact-render-to-string, broadcast-channel, CppMicroServices) — it is now a
   bigger killer than the root file it supplements.
3. **For Python and C++, read the SCRIPT the workflow calls** (Finding 3). Gate 5 outkills
   Requirement 7 ten to one in those languages, and the decisive line is never in the `.yml`.
4. **The AI-marker rate is 12% in the 1-4 MB band vs 23% in the >4 MB mid-band.** Two independent
   measurements now exist. It did not starve this hunt. The kill-vs-ranking-penalty choice remains a
   user decision and was NOT relaxed here.
5. **Start from `q_0921h11/live_s11u.tsv` (201 rows, heads only screened).** Do not fire a new sweep
   until it is exhausted. If a new sweep is needed, the remaining un-mined boundary is
   `size:<1000` (sub-1 MB repos) and `stars:>6000` — both lower-yield than what was just mined.
6. **Deprioritise the JS/TS mid-band** relative to Go/Rust/C++. Measured twice now: it is bot-driven,
   browser-bound, or hollowed into sibling npm packages, and it produced zero survivors from 56 rows.
7. **The profile worth screening FOR is not a star band: it is a pure-logic engine with a
   hand-built, dependency-free, deterministic test harness.** All three survivors have exactly that
   (stremio-core's `TestEnv` with a settable clock; piscsi's GoogleTest suite over a pure command
   layer; vermin's `runtests.py` with `dependencies = []`). Every repo with a real domain that died,
   died because the domain needs a kernel, a GPU, a C library or a live service.
8. **Scan the VENDOR DIR's licences, not just the top-level LICENSE.** `u-root/u-root` carries a
   clean BSD-3-Clause at the root and two **MPL-2.0** packages under `vendor/` that the build
   compiles in. The gate is an allowlist, so "not GPL" is not the test. This is the third repo in two
   months caught this way (synthea's LGPL jar, mapproxy's Zope Public License, now u-root) and it is
   one `find vendor -iname 'LICENSE*'` away from being mechanical. Fold it into `gate.py` as a root-
   and vendor-tree licence scan.
9. **Cheap high-yield pre-filter nobody has tried: an EMPTY runtime dependency list.** In the
   Python/TS/JS fresh slice, exactly one repo of 124 had zero runtime deps and a self-contained
   deterministic suite — and it was the survivor. `dependencies == []` in `pyproject.toml`, an empty
   `[dependencies]` in `Cargo.toml`, or a `package.json` with no `dependencies` key is one field in
   the GraphQL pre-gate and it ranks straight at the thing Gate 5 spends most of its budget
   discovering one repo at a time.
