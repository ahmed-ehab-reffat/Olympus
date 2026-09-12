---
Repository: https://github.com/deadpool-rs/deadpool
Issue: N/A
Commit: 8feed310a6f69b4b51c4963604ea1bc5f5a586c3
Language: Rust
Title: Add a keyed managed pool with a shared global capacity
---
# Add a keyed managed pool with a shared global capacity

Add a keyed variant of the managed pool, exported from `deadpool::managed`: `KeyedManager`, `KeyedPool`, `KeyedPoolBuilder`, `KeyedPoolConfig`, `KeyedObject`, `KeyedStatus`, `KeyedKeyStatus`, and `KeyedRetainResult`.

`KeyedManager` has `Key`, `Type`, and `Error` associated types: `async create(&self, key: &Key) -> Result<Type, Error>`, `async recycle(&self, key: &Key, obj: &mut Type, metrics: &Metrics) -> RecycleResult<Error>`, and `detach(&self, key: &Key, obj: &mut Type)`, defaulting to a no-op.

`KeyedPoolConfig::new(max_size, max_per_key)` sets the total across all keys and the per-key limit; `0` means unlimited. `KeyedPool::new(manager, config)` returns a `KeyedPool<M>` directly. `KeyedPool::builder(manager)` returns a `KeyedPoolBuilder<M>` offering `max_size`, `max_per_key`, `wait_timeout`, `create_timeout`, `recycle_timeout`, `runtime`, and `max_idle_lifetime`; its `build` returns `Result<KeyedPool<M>, BuildError>`, failing when a timeout is configured without a runtime. Neither type takes an object-wrapper generic parameter.

`get(key: Key)` returns a `KeyedObject` that derefs to `Type`. The total never exceeds `max_size` and a key never holds more than `max_per_key` checked-out objects; a caller that would exceed either waits. An idle object of the requested key is reused (recycled); when the pool is at `max_size` and the key has no idle object, the least-recently-returned idle object of a *different* key is detached to make room. `timeout_get(key, &Timeouts)` overrides the configured timeouts; an exhausted wait timeout yields `PoolError::Timeout` and a zero wait timeout makes the call non-blocking. A `get` future dropped before it resolves frees what it held: its reserved slot is released and any object it was recycling discarded, so `size` and `key_size` never count an abandoned caller and the pool still hands out `max_size` objects. `KeyedObject::take(obj)` removes an object permanently and frees its slot; `KeyedObject::id(&obj)` returns its `ObjectId`, which is unique and increasing. An idle object that fails to recycle, including a recycle timeout, is discarded and replaced by a fresh one; an expired create timeout yields `PoolError::Timeout`.

`resize` changes the global capacity: shrinking detaches idle objects until the total fits the new cap but never removes checked-out ones, so the total may stay above the cap until they return; nothing is handed out while it is. `close` detaches idle objects, makes later `get` calls return `PoolError::Closed` while in-flight objects still return cleanly; `is_closed` reports the state. `clear_key(&key)` detaches every idle object of one key, leaving other keys and in-flight objects untouched. `retain`'s predicate receives `(&Key, &Type, Metrics)`; it keeps only the idle objects it accepts and reports the `retained` and `removed` counts. `reap_idle` detaches idle objects whose idle time exceeds `max_idle_lifetime` and returns how many were reaped; such a stale object is discarded rather than reused when `get` finds it.

`status` reports `max_size`, `size`, `available` idle objects, and how many `keys` hold objects; `key_status(&key)` gives that key's `size`, `available`, and `max_per_key`; `key_size(&key)` its object count; `keys()` a `Vec` of every key holding objects.
