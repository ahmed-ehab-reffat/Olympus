# stremio-core-resource-freshness — SHELVED at scope-lock 2026-09-21 (UNAUTHORABLE-HARNESS, no code written)

Repo: `Stremio/stremio-core` (MIT, Rust 99.8%, 2411 stars), base `b3062f7fa790223540022f9a62c12067b646c179`.
Lane from `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-21-B.md` RANK 1: honour the addon protocol's
per-response freshness directives (`ResourceResponseCache { cache_max_age, stale_revalidate, stale_error }`)
inside the `ResourceLoadable` kernel.

## What the hunt got right (re-verified by me at base)

- `grep -rn ResourceResponseCache --include=*.rs .` returns three hits, all inside
  `src/types/addon/response.rs` (the struct plus two doc lines). The struct is provably dead state.
- `AddonTransport::resource` (`src/addon_transport/addon_transport.rs:5`) returns
  `TryEnvFuture<ResourceResponse>` and has no slot for the directives.
- All four kernel result handlers gate on `matches!(resource.content, Some(Loadable::Loading))`
  (`src/models/common/resource_loadable.rs:123, :143, :212, :236`), and every current caller sets
  `Loading` before firing, so the `_ => Effects::none().unchanged()` arm is dead code today.
- `resources_update`'s dedup `find(|r| r.request == request && r.content.is_some() && !force)`
  (`resource_loadable.rs:176-178`) returns before any timestamp comparison.
- `resource_vector_content_from_result` maps empty to `Err(EmptyContent)` (`:273-277`); the scalar
  twin `resource_content_from_result` (`:255-261`) has no such branch.
- `src/unit_tests/env.rs:27` does ship a settable clock (`NOW`), and the baseline suite is small
  and fast.

## Why the lane is dead anyway — the harness, measured

The directives only exist on the wire. To reach the kernel they must change what the addon
transport deserializes, i.e. the `OUT` type of `Env::fetch`.

`TestEnv::fetch` (`src/unit_tests/env.rs:112-124`) is:

```rust
FETCH_HANDLER.read().unwrap()(request)
    .map_ok(|resp| {
        *resp.downcast::<OUT>()
            .unwrap_or_else(|_| panic!("Failed to downcast to {}", type_name::<OUT>()))
    })
```

The handlers return `Box<dyn Any + Send>` holding a **pre-built** value; no deserialization ever
runs in tests. `Box<dyn Any>::downcast::<T>` matches on exact `TypeId`, so the moment the transport
asks for `ResourceResponseCache` every existing handler that boxes a `ResourceResponse` panics.
Measured: **30 `Box::new(ResourceResponse…)` sites across 15 test files**
(`grep -rn "Box::new(ResourceResponse" src/unit_tests | wc -l` = 30).

Every repair is blocked:

- **solution.patch cannot repair them** — they are test files, and a source-only patch may not touch
  `src/unit_tests/`.
- **test.patch cannot repair them either** — the repair has to differ between the base tree
  (`OUT = ResourceResponse`) and the solution tree (`OUT = ResourceResponseCache`), and one patch
  applies to both. A tolerant `TestEnv::fetch` adapter *would* compile and pass in both trees, but
  `env.rs` lives under `src/`, is outside test.patch's remit, and (decisively) the solver never sees
  it: every agent that changes the transport type watches 30 repo tests panic and either edits repo
  tests (graded `PASS_CHEATED`, L31/L78) or edits `env.rs` itself and makes test.patch conflict.
  That contaminates ~100% of runs and measures nothing.
- **Scoping base mode around the 15 files** is not a flakiness exclusion, it is gaming, and it does
  not stop the agent-side contamination.

Because the harness bypasses deserialization entirely, a new test also cannot *inject* wire metadata
without changing the fetched type. There is no version of "per-response freshness" that survives.

## Why the obvious re-sources of the freshness windows are also blocked

| Alternative source | Blocker |
|---|---|
| a field on `Manifest` | 36 exhaustive `Manifest { … }` literals in `src/unit_tests/` (no `..Default::default()`), all break at compile time |
| a field on `ManifestBehaviorHints` | `src/unit_tests/serde/manifest_behavior_hints.rs` pins the exact serde token stream including `len: 5` |
| a field on `ResourceLoadable` | one exhaustive literal at `src/unit_tests/meta_details/live_tv.rs:58-61`; nothing can add the field and keep that literal compiling in both trees |
| an 8th argument to `Ctx::new` | ~20 call sites in existing tests |
| repo constants only | no directives, no protocol tie, and the pick collapses to a nameable "TTL cache" |

## Repo-level finding (why a second lane was not attempted here)

`Stremio/stremio-core` is mechanically excellent (MIT, pure Rust, `Cargo.lock` committed, one
rev-pinned git dep, 282 lib + 18 doc tests, settable clock, zero submissions against a 6-quota) and
structurally hostile to an Olympus-sized pick:

1. **`src/unit_tests/serde/` token-pins ~48 of the types in `src/types/`.** Adding a field to almost
   any public type reds an existing test that only the agent can repair.
2. **The fetch harness pre-builds typed values and downcasts by `TypeId`**, so no change to any
   wire type is expressible.
3. **The runtime is a generic `Effects`/`Env`/`Loadable` engine**, so new cases are absorbed
   (`TOO-EASY.md § MISSING-ARM-OF-A-DISPATCH` and the `ytt` GENERIC-INTERNALS entry). Two probes
   confirmed it: chunking `AggrRequest::CatalogsFiltered`'s id batches past the addon's
   `options_limit` is ~30 effective LOC because `ResourceRequest` equality already lets the kernel
   hold N entries per addon and `update_notification_items` already scans all catalogs.

The three latent kernel bugs are real and stay on file for anyone who finds a lane that does not
cross the transport boundary.

## Status

No code was written, no batch was run, no Docker image was built. Cost: one session of source
reading. Recorded in `Instructions/TOO-EASY.md`.

NEXT (human): none. Do not re-pick the addon-response freshness lane in stremio-core.
