# RustPBX redesign audit

Date: 2026-07-25

Pinned revision:
`ac15e936ee0c8f7bd1eaedc83609d05096ccaf58`

Outcome: reject the investigated RWI idempotency and atomic reload seeds. Do
not create a replacement problem folder for either.

## Starting point

After the SipFlow seed failed upstream prior-art review, two materially
different directions were investigated:

1. make RWI call-control commands idempotent across reconnects; and
2. make hot reload atomic across trunks, routes, ACLs, addons, and cluster
   peers.

The pinned source, focused tests, documentation, and history were searched for
the proposed public vocabulary and concrete type names. No hidden tests,
reference solution, or calibration artifacts were created.

## RWI command idempotency

### Existing upstream behavior

RWI already has substantially more of this feature than the initial screen
recognized:

- every command requires a client-generated `action_id`;
- responses echo the `action_id`;
- `RwiCommandProcessor` owns a `CommandDeduplicationCache`;
- the cache has a 60-second TTL and bounded opportunistic cleanup;
- `handler.rs` checks the cache before executing a command and records the
  action after execution;
- the gateway retains sequenced events;
- `session.resume` and `call.resume` replay events after reconnect; and
- unit, WebSocket, integration, and end-to-end tests cover response
  correlation, reconnection, event replay, and incremental sequence resume.

The existing implementation leaves a real narrow defect: each WebSocket
connection constructs a new processor/cache, so a repeated `action_id` after
reconnect can execute again. The separate check and record also allow
concurrent duplicates to race, while a detected duplicate is silently dropped
instead of receiving the original result.

### Cheapest legitimate fix

The narrow correct shape is conventional:

1. move the dedup registry to gateway/application scope;
2. atomically reserve an identity-scoped `action_id` before execution;
3. retain an in-flight/completed state and the serialized result;
4. make concurrent duplicates wait for or receive that result;
5. reject reuse of one key for a conflicting command fingerprint; and
6. retain TTL/bounded cleanup.

This coordinates a small cache and the existing handler. It does not require
changes to call, SIP, media, conference, transfer, queue, or recording
semantics. Adding durable exactly-once execution across process restart would
be a different distributed-storage policy not promised by RWI.

### Verdict

Reject for task shape and scope. The defect is credible, but the solution is a
familiar idempotency-key cache repair around an already implemented mechanism.
It is likely a small handler/gateway/cache change and would be solved by a
standard reserve/complete/wait recipe with little RustPBX-specific
investigation. Combining many commands or requiring durable process-restart
semantics would pad or materially change the task.

## Atomic hot reload

### Existing upstream behavior

Reload is also an established, rapidly developed subsystem:

- application reload parses the proposed config, runs
  `preflight::validate_reload`, supports check/dry-run mode, then requests a
  controlled restart;
- trunks, routes, and ACLs have individual runtime reloaders;
- queue and IVR addons implement an export/reload registry whose handlers are
  documented as idempotent;
- generated database-backed config supports queues, routes, trunks, ACL, and
  IVR;
- cluster endpoints reload the local node and peers, stream progress, and
  aggregate per-peer results;
- trunk reload coordinates registration removal/cancellation and rate-limit
  reset;
- platform, recording, SipFlow, TLS, and certificate settings have additional
  live reload paths; and
- source history contains repeated recent reload, cluster, database-store, and
  detailed-status work.

### Cheapest legitimate behavior and policy boundary

A local multi-target endpoint could validate one config snapshot and call the
existing reloaders in sequence. Without new rollback APIs, it would still be a
thin coordinator. Requiring all live runtime side effects to roll back would
need snapshots or compensating operations for registrations, routes, ACLs,
addons, TLS, and other services.

Extending that guarantee across cluster peers is a distributed transaction:
the task would need to invent prepare/commit, failure recovery, node
membership, timeout, retry, and reconciliation policy that RustPBX does not
currently expose. Black-box tests would either accept partial per-peer results,
which already exist, or enforce a new private/protocol architecture.

### Verdict

Reject for prior-art adjacency, similarity, and task-policy risk. A local
coordinator is too small and derivative; a full rollback transaction repeats
the workspace's failure-atomic problem neighborhood; and cluster-wide
atomicity invents distributed semantics rather than completing a
repository-supported contract.

## Repository-level conclusion

RustPBX is healthy and unusually well tested, but its active public surface is
feature-dense and moving quickly. The exact SipFlow name, RWI resume/dedup
mechanisms, and reload infrastructure all existed before their candidate
screens. Public issues enumerate the most visible remaining SIP/media gaps.

Do not continue generating neighboring RWI, reload, SipFlow, media-routing,
DTMF, trunk-registration, call-quality, or loose-routing tasks in this
repository. Reconsider RustPBX only after a fresh subsystem-level discovery
finds a non-enumerated operation whose exact nouns and concrete seams are absent
from source/history and whose cheapest legitimate implementation is both
repository-specific and sufficiently deep.
